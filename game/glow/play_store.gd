## Google Play Billing through the GodotGooglePlayBilling plugin (Android
## builds). Product ids are the catalog ids (game/glow/catalog.gd); set them up
## in the Play Console with the same ids. Gems and the season pass are
## consumed after they're granted; unlocks (the Founder Pack) are only
## acknowledged, so Play keeps them for restore. Unfinished purchases come
## back from queryPurchases on the next connection.
extends "res://game/glow/store.gd"

var backend
var _play
var _prices := {} ## product id -> localized price
var _tokens := {} ## order id -> purchase token, waiting for finish()


func _init(backend_ = null) -> void:
	backend = backend_
	_play = Engine.get_singleton("GodotGooglePlayBilling")
	_play.connected.connect(_on_connected)
	_play.purchases_updated.connect(_on_purchases)
	_play.purchase_error.connect(func(_code, _msg): failed.emit("", "The purchase didn't go through."))
	_play.sku_details_query_completed.connect(_on_details)
	_play.query_purchases_response.connect(func(r): if int(r.get("status", 1)) == OK: _on_purchases(r.get("purchases", [])))
	_play.startConnection()


func is_test() -> bool:
	return false


func price(product_id: String) -> String:
	return _prices.get(product_id, super.price(product_id))


func purchase(product_id: String) -> void:
	if Catalog.product(product_id).is_empty():
		failed.emit(product_id, "Unknown product.")
		return
	var res = _play.purchase(product_id)
	if res is Dictionary and int(res.get("status", OK)) != OK:
		failed.emit(product_id, "Google Play isn't available right now.")


func restore() -> void:
	_play.queryPurchases("inapp")


func finish(product_id: String, txn: String) -> void:
	if not _tokens.has(txn):
		return
	var token: String = _tokens[txn]
	_tokens.erase(txn)
	if Catalog.product(product_id).kind == "unlock":
		_play.acknowledgePurchase(token)
	else:
		_play.consumePurchase(token)


func _on_connected() -> void:
	_play.querySkuDetails(Catalog.PRODUCTS.map(func(p): return p.id), "inapp")
	_play.queryPurchases("inapp")


func _on_details(details: Array) -> void:
	for d in details:
		_prices[str(d.get("sku", d.get("product_id", "")))] = str(d.get("price", ""))


func _on_purchases(purchases: Array) -> void:
	for p in purchases:
		if int(p.get("purchase_state", 1)) != 1: # 1 = purchased; pending ones arrive again when paid.
			continue
		var skus: Array = p.get("skus", p.get("products", []))
		var id := str(p.get("sku", skus[0] if not skus.is_empty() else ""))
		var unlock: bool = Catalog.product(id).get("kind", "") == "unlock"
		if unlock and bool(p.get("is_acknowledged", false)):
			# Already granted once; restore re-grants it (GlowState skips a known txn).
			purchased.emit(id, str(p.get("order_id", "")))
			continue
		_deliver(id, str(p.get("order_id", "")), str(p.get("purchase_token", "")))


func _deliver(product_id: String, txn: String, token: String) -> void:
	if txn == "" or Catalog.product(product_id).is_empty():
		return
	if not await record(backend, "google", product_id, txn, token):
		failed.emit(product_id, "Couldn't reach the server. Your purchase will arrive next time you open the game.")
		return
	_tokens[txn] = token
	purchased.emit(product_id, txn)
