## What the Google Play and App Store apps share: real vibration, the
## notch-aware safe area, and links shared through the system.
extends "res://game/platform/platform.gd"


func is_native_app() -> bool:
	return true


func can_vibrate() -> bool:
	return true


func _buzz(ms: int, strength: float) -> void:
	Input.vibrate_handheld(ms, strength)


func safe_insets(viewport: Viewport) -> Dictionary:
	var canvas := viewport.get_visible_rect().size if viewport != null else Vector2.ZERO
	return insets_from(DisplayServer.get_display_safe_area(), DisplayServer.screen_get_size(), canvas)
