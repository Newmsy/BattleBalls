## The App Store app. Purchases: game/glow/apple_store.gd (the InAppStore
## plugin from godot-ios-plugins). Haptics use Core Haptics through
## Input.vibrate_handheld; the notch and home bar come from the safe area.
## Still to plug in: Sign in with Apple (id_token), the share sheet and local
## notifications.
extends "res://game/platform/native_platform.gd"


func kind() -> String:
	return "ios"
