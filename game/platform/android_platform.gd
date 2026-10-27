## The Google Play app. Purchases: game/glow/play_store.gd (the
## GodotGooglePlayBilling plugin in addons/). The system Back closes the top
## screen (game/ui/touch_input.gd); twice at Home leaves the game.
## Still to plug in: native Google sign-in (Credential Manager plugin handing
## back an id_token), the share sheet and local notifications.
extends "res://game/platform/native_platform.gd"


func kind() -> String:
	return "android"


func has_system_back() -> bool:
	return true
