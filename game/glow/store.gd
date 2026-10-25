## The one door real money comes through. Screens and GlowState only talk to
## this interface; Store.make() picks the store for this build:
## - iOS with the InAppStore plugin: game/glow/apple_store.gd (StoreKit)
## - Android with the GodotGooglePlayBilling plugin: game/glow/play_store.gd
## - Settings > Testing on (Dev.tools_enabled): this class, the fake store
## - anything else (the web build players use): game/glow/no_store.gd, which
##   sells nothing, so nobody gets paid items for free.
##
## This base class is the fake store used by tests and playtests: every
## purchase succeeds at once and costs nothing, and the shop labels it
## "Test store". A real store subclass overrides every method below.
##
## Contract for a real store:
## - purchase(id) eventually emits purchased(id, txn) or failed(id, reason).
## - Before emitting purchased it records the purchase on the server
##   (record_purchase); if that fails it leaves the transaction unfinished,
##   so the store delivers it again on the next launch.
## - txn is unique per purchase; GlowState ignores a txn it has already granted,
##   so redelivery after a crash is safe. GlowState calls finish(id, txn) once
##   the purchase is granted (or was already), and only then may the store
##   finish or consume it.
## - restore() re-emits purchased() for every non-consumable ("unlock") the
##   account owns (Apple requires a Restore button).
extends RefCounted

const Catalog := preload("res://game/glow/catalog.gd")

signal purchased(product_id: String, txn: String)
signal failed(product_id: String, reason: String)

var _counter := 0
var _owned: Array[String] = [] ## Unlocks bought this session, for restore().


const Dev := preload("res://game/dev.gd")


## The store for this build (see the top of this file). `backend` is
## game/online/backend.gd, for the purchase record; may be null.
static func make(backend = null):
	if Engine.has_singleton("InAppStore"):
		return load("res://game/glow/apple_store.gd").new(backend)
	if Engine.has_singleton("GodotGooglePlayBilling"):
		return load("res://game/glow/play_store.gd").new(backend)
	if Dev.tools_enabled():
		return load("res://game/glow/store.gd").new()
	return load("res://game/glow/no_store.gd").new()


## True while this is the fake store: no money changes hands.
func is_test() -> bool:
	return true


## False when this build can't take money (the web build): screens hide
## real-money buttons.
func available() -> bool:
	return true


## Called once a purchase is granted (or was already): a real store finishes
## or consumes the transaction here.
func finish(_product_id: String, _txn: String) -> void:
	pass


## Called every frame by main.gd: plugins that queue events are read here.
func poll() -> void:
	pass


## Records a real purchase on the server (supabase record_purchase) before
## it's granted. False when the server couldn't be reached or refused it.
static func record(backend, store_name: String, product_id: String, txn: String, receipt: String) -> bool:
	if backend == null or not backend.enabled():
		return false
	var res: Dictionary = await backend.call_rpc("record_purchase",
		{"p_store": store_name, "p_product": product_id, "p_txn": txn, "p_receipt": receipt})
	return res.ok


## The price players see, in their currency.
func price(product_id: String) -> String:
	var p := Catalog.product(product_id)
	return "$" + str(p.get("usd", "?"))


func purchase(product_id: String) -> void:
	var p := Catalog.product(product_id)
	if p.is_empty():
		failed.emit(product_id, "Unknown product.")
		return
	_counter += 1
	if p.kind == "unlock" and product_id not in _owned:
		_owned.append(product_id)
	purchased.emit(product_id, "test-%d-%d" % [Time.get_ticks_usec(), _counter])


func restore() -> void:
	for id in _owned:
		purchased.emit(id, "restore-" + id)
