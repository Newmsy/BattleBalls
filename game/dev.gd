## Developer switches. The Testing section in Settings (refill energy, extra
## eggs, free summons) is hidden from players. It shows in debug builds (F5 in
## the editor), after a visit with ?dev=1, or after tapping the version line
## at the foot of Settings TAP_TO_UNLOCK times; the last two stick on the device.
extends RefCounted

const SETTINGS_PATH := "user://settings.cfg"
const TAP_TO_UNLOCK := 7

static var _loaded := false
static var _free_summons := false
static var _tools_loaded := false
static var _tools := false
static var _taps := 0


## True when the Testing section and its shortcuts are on for this device.
static func tools_enabled() -> bool:
	if OS.is_debug_build():
		return true
	if not _tools_loaded:
		_tools_loaded = true
		var cfg := ConfigFile.new()
		if cfg.load(SETTINGS_PATH) == OK:
			_tools = cfg.get_value("dev", "tools", false)
	return _tools


static func set_tools(on: bool) -> void:
	_tools_loaded = true
	_tools = on
	_taps = 0
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("dev", "tools", on)
	cfg.save(SETTINGS_PATH)


## One tap on the version line. Returns true on the tap that flips the tools.
static func tap_version() -> bool:
	_taps += 1
	if _taps < TAP_TO_UNLOCK:
		return false
	set_tools(not tools_enabled())
	return true


## Summons cost no orbs (Settings > Testing). Always off without the tools.
static func free_summons() -> bool:
	if not tools_enabled():
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


## The live-fight server (server/, design/live-quick-fight.md): the Azure
## Container App battleballs-live, deployed from main by CI. ?live=wss://...
## (or ws://127.0.0.1:8080 for a local LIVE_DEV=1 server) points one visit
## at another server and turns live fights on.
const LIVE_SERVER := "wss://battleballs-live.jollysky-cd3623b2.westeurope.azurecontainerapps.io"

static var live_url_override := ""
static var _live := false
static var _live_loaded := false


## Quick fight's FIGHT! finds a live foe (Settings > Testing). Needs a server.
static func live_fights() -> bool:
	if live_url_override != "":
		return true
	if not tools_enabled() or LIVE_SERVER == "":
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
