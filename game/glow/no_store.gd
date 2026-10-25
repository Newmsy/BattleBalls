## The store for builds that can't take money (the web build players use):
## it sells nothing. Real-money buttons hide (available() is false), and a
## purchase that gets through anyway fails without granting anything.
extends "res://game/glow/store.gd"


func is_test() -> bool:
	return false


func available() -> bool:
	return false


func price(_product_id: String) -> String:
	return ""


func purchase(product_id: String) -> void:
	failed.emit(product_id, "Buy it in the iPhone or Android app.")


func restore() -> void:
	pass
