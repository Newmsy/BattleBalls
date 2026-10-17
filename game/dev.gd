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


## The live-fight server (server/, design/live-quick-fight.md). Empty until
## it's hosted; ?live=wss://... (or ws://127.0.0.1:8080 for a local
## LIVE_DEV=1 server) points one visit at a server and turns live fights on.
const LIVE_SERVER := ""

static var live_url_override := ""
static var _live := false
static var _live_loaded := false


## Quick fight's FIGHT! finds a live foe (Settings > Testing). Needs a server.
static func live_fights() -> bool:
	if live_url_override != "":
		return true
	if not TOOLS_ENABLED or LIVE_SERVER == "":
		return false
	if not _live_loaded:
		_live_loaded = true
		var cfg := ConfigFile.new()
		if cfg.load(SETTINGS_PATH) == OK:
			_live = cfg.get_value("dev", "live_fights", false)
	return _live


static func set_live_fights(on: bool) -> void:
	_live_loaded = true
	_live = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("dev", "live_fights", on)
	cfg.save(SETTINGS_PATH)


static func live_url() -> String:
	return live_url_override if live_url_override != "" else LIVE_SERVER
