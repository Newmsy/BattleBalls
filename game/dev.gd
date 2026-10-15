## Developer switches. TOOLS_ENABLED shows the Testing section in Settings
## (refill energy, extra orbs, free summons). Set it to false before soft launch.
extends RefCounted

const TOOLS_ENABLED := true
const SETTINGS_PATH := "user://settings.cfg"

static var _loaded := false
static var _free_summons := false


## Summons cost no orbs (Settings > Testing). Always off without TOOLS_ENABLED.
static func free_summons() -> bool:
	if not TOOLS_ENABLED:
		return false
	if not _loaded:
		_loaded = true
		var cfg := ConfigFile.new()
		if cfg.load(SETTINGS_PATH) == OK:
			_free_summons = cfg.get_value("dev", "free_summons", false)
	return _free_summons


static func set_free_summons(on: bool) -> void:
	_loaded = true
	_free_summons = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("dev", "free_summons", on)
	cfg.save(SETTINGS_PATH)
