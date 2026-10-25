## StoreKit through the godot-ios-plugins InAppStore plugin (iOS builds).
## Product ids are the catalog ids (game/glow/catalog.gd); set them up in App
## Store Connect with the same ids. Transactions stay unfinished until the
## server has recorded them and GlowState has granted them, so a crash or a
## lost connection only means StoreKit delivers them again.
extends "res://game/glow/store.gd"

var backend
var _iap
var _prices := {} ## product id -> localized price ("£4.99")
var _txns := {} ## transaction id -> product id, waiting for finish()


func _init(backend_ = null) -> void:
	backend = backend_
	_iap = Engine.get_singleton("InAppStore")
	_iap.set_auto_finish_transaction(false)
	_iap.request_product_info({"product_ids": Catalog.PRODUCTS.map(func(p): return p.id)})


func is_test() -> bool:
	return false


func price(product_id: String) -> String:
	return _prices.get(product_id, super.price(product_id))


func purchase(product_id: String) -> void:
	if Catalog.product(product_id).is_empty():
		failed.emit(product_id, "Unknown product.")
		return
	if _iap.purchase({"product_id": product_id}) != OK:
		failed.emit(product_id, "The App Store isn't available right now.")


func restore() -> void:
	_iap.restore_purchases()


func finish(product_id: String, txn: String) -> void:
	if _txns.erase(txn):
		_iap.finish_transaction(product_id)


func poll() -> void:
	while _iap.get_pending_event_count() > 0:
		_on_event(_iap.pop_pending_event())


func _on_event(e: Dictionary) -> void:
	match e.get("type", ""):
		"product_info":
			var ids: Array = e.get("ids", [])
			var shown: Array = e.get("localized_prices", [])
			for i in mini(ids.size(), shown.size()):
				_prices[ids[i]] = shown[i]
		"purchase", "restore":
			var id := str(e.get("product_id", ""))
			if e.get("result", "") != "ok":
				if e.type == "purchase":
					failed.emit(id, "Purchase cancelled." if "cancel" in str(e.get("error", "")).to_lower() else "The purchase didn't go through.")
				return
			_deliver(id, str(e.get("transaction_id", "")), str(e.get("receipt", "")))


func _deliver(product_id: String, txn: String, receipt: String) -> void:
	if txn == "" or Catalog.product(product_id).is_empty():
		return
	if not await record(backend, "apple", product_id, txn, receipt):
		failed.emit(product_id, "Couldn't reach the server. Your purchase will arrive next time you open the game.")
		return
	_txns[txn] = product_id
	purchased.emit(product_id, txn)
