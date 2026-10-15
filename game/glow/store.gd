## The one door real money comes through. Screens and GlowState only talk to
## this interface, so swapping in StoreKit 2 (iOS) or Google Play Billing
## later means a new subclass, not a new shop.
##
## This base class is the fake store used by the web build, tests and
## playtests: every purchase succeeds at once and costs nothing, and the shop
## labels it "Test store". It never runs in a store build: a real store
## subclass overrides every method below.
##
## Contract for a real store:
## - purchase(id) eventually emits purchased(id, txn) or failed(id, reason).
## - txn is unique per purchase; GlowState ignores a txn it has already granted,
##   so redelivery after a crash is safe.
## - restore() re-emits purchased() for every non-consumable ("unlock") the
##   account owns (Apple requires a Restore button).
extends RefCounted

const Catalog := preload("res://game/glow/catalog.gd")

signal purchased(product_id: String, txn: String)
signal failed(product_id: String, reason: String)

var _counter := 0
var _owned: Array[String] = [] ## Unlocks bought this session, for restore().


## True while this is the fake store: no money changes hands.
func is_test() -> bool:
	return true


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
