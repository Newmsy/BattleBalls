## Google Play Billing through the GodotGooglePlayBilling plugin 3.x
## (addons/GodotGooglePlayBilling, Play Billing Library 9) in Android builds.
## Product ids are the catalog ids (game/glow/catalog.gd); set them up in the
## Play Console as one-time products with the same ids. Gems and the season
## pass are consumed after they're granted; unlocks (the Founder Pack) are only
## acknowledged, so Play keeps them for restore. Unfinished purchases come
## back from query_purchases on the next connection.
extends "res://game/glow/store.gd"

const CLIENT := "res://addons/GodotGooglePlayBilling/BillingClient.gd"
const INAPP := 0 ## BillingClient.ProductType.INAPP
const PURCHASED := 1 ## BillingClient.PurchaseState.PURCHASED
const USER_CANCELED := 1 ## BillingClient.BillingResponseCode.USER_CANCELED
const ALREADY_OWNED := 7

var backend
var _play
var _prices := {} ## product id -> localized price
var _tokens := {} ## order id -> purchase token, waiting for finish()
var _buying := "" ## The product the open purchase sheet is for.


func _init(backend_ = null) -> void:
	backend = backend_
	_play = load(CLIENT).new()
	_play.connected.connect(_on_connected)
	_play.disconnected.connect(func(): _play.start_connection.call_deferred())
	_play.query_product_details_response.connect(_on_details)
	_play.query_purchases_response.connect(_on_query_purchases)
	_play.on_purchase_updated.connect(_on_purchase_updated)
	_play.start_connection()


func is_test() -> bool:
	return false


func price(product_id: String) -> String:
	return _prices.get(product_id, super.price(product_id))


func purchase(product_id: String) -> void:
	if Catalog.product(product_id).is_empty():
		failed.emit(product_id, "Unknown product.")
		return
	if not _play.is_ready():
		_play.start_connection()
		failed.emit(product_id, "Google Play isn't available right now.")
		return
	_buying = product_id
	var res: Dictionary = _play.purchase(product_id)
	if int(res.get("response_code", OK)) != OK:
		_buying = ""
		failed.emit(product_id, "Google Play isn't available right now.")


func restore() -> void:
	_play.query_purchases(INAPP)


func finish(product_id: String, txn: String) -> void:
	if not _tokens.has(txn):
		return
	var token: String = _tokens[txn]
	_tokens.erase(txn)
	if Catalog.product(product_id).kind == "unlock":
		_play.acknowledge_purchase(token)
	else:
		_play.consume_purchase(token)


func _on_connected() -> void:
	_play.query_product_details(PackedStringArray(Catalog.PRODUCTS.map(func(p): return p.id)), INAPP)
	_play.query_purchases(INAPP)


func _on_details(r: Dictionary) -> void:
	for d in r.get("product_details", []):
		var offers: Array = d.get("one_time_purchase_offer_details_list", [])
		if not offers.is_empty():
			_prices[str(d.get("product_id", ""))] = str(offers[0].get("formatted_price", ""))


func _on_query_purchases(r: Dictionary) -> void:
	if int(r.get("response_code", -1)) == OK:
		_on_purchases(r.get("purchases", []))


func _on_purchase_updated(r: Dictionary) -> void:
	var code := int(r.get("response_code", -1))
	var id := _buying
	_buying = ""
	if code == OK or code == ALREADY_OWNED:
		_on_purchases(r.get("purchases", []))
		if code == ALREADY_OWNED:
			restore()
	elif code == USER_CANCELED:
		failed.emit(id, "Purchase cancelled.")
	else:
		failed.emit(id, "The purchase didn't go through.")


func _on_purchases(purchases: Array) -> void:
	for p in purchases:
		if int(p.get("purchase_state", 0)) != PURCHASED: # Pending ones arrive again when paid.
			continue
		var ids: Array = p.get("product_ids", [])
		var id := str(ids[0]) if not ids.is_empty() else ""
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
