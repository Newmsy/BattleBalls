## The browser build. Sharing stays with the page's own share sheet
## (main.gd's SHARE_JS); Safari keeps the page clear of the notch itself, so
## there are no insets. No haptics: iPhone Safari can't vibrate, and Android
## players get them in the Google Play app.
extends "res://game/platform/platform.gd"


func kind() -> String:
	return "web"
