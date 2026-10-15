## The owner's stats screen: retention, tutorial drop-off, energy, critter
## picks and win rates, from analytics_dashboard() (supabase/migrations/
## *_analytics.sql). Opened with ?stats#k=<dashboard key>; the key stays in
## the URL fragment so it never reaches a server log. Only aggregates come
## back, never a player's events.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Backend := preload("res://game/online/backend.gd")
const Roster := preload("res://game/ui/roster.gd")

const RANGES := [7, 30, 90]
const COHORT_ROWS := 14

var backend: Backend
var key := ""
var days := 30
var data := {}
## loading, ready, no_key, offline, denied, error
var status := "loading"
var _content: VBoxContainer
var _request := 0 ## Only the latest load_stats() call may fill the screen.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Kit.theme()
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	scroll.add_child(margin)
	_content = Kit.vbox(28)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)
	get_viewport().size_changed.connect(func(): margin.add_theme_constant_override("margin_left", _side_margin()); margin.add_theme_constant_override("margin_right", _side_margin()))
	margin.add_theme_constant_override("margin_left", _side_margin())
	margin.add_theme_constant_override("margin_right", _side_margin())

	backend = Backend.new()
	add_child(backend)
	var search := _js("window.location.search")
	key = key_from(_js("window.location.hash"))
	backend.disabled = "offline=1" in search
	if "demo=1" in search:
		# Sample numbers, for screenshots and UI work without a server.
		data = demo_data()
		status = "ready"
	elif not backend.enabled():
		status = "offline"
	elif key == "":
		status = "no_key"
	_render()
	print("STATS_SCREEN ", status)
	if status == "loading":
		load_stats()


func load_stats() -> void:
	_request += 1
	var mine := _request
	status = "loading"
	_render()
	if "demo=1" in _js("window.location.search"):
		data = demo_data()
		status = "ready"
		_render()
		return
	var res: Dictionary = await backend.call_rpc_public("analytics_dashboard", {"p_key": key, "p_days": days})
	if mine != _request:
		return
	if res.ok and res.data is Dictionary:
		data = res.data
		status = "ready"
	else:
		status = "denied" if res.code in [401, 403] else "error"
	print("STATS_%s code=%d" % [status.to_upper(), res.code])
	_render()


func _render() -> void:
	for c in _content.get_children():
		c.queue_free()
	var head := Kit.vbox(4, [Kit.label("Battle Balls stats", 44)])
	if status == "ready":
		head.add_child(Kit.caption("Last %d days (UTC) · updated %s" % [days, str(data.get("generated_at", "")).left(16).replace("T", " ")]))
	_content.add_child(head)
	var note := {
		"loading": "Loading...",
		"no_key": "This page needs the owner's stats link (it ends in #k=...).",
		"offline": "This build has no online backend, so there are no stats to show.",
		"denied": "That stats link isn't valid any more. Ask for a fresh one.",
		"error": "Couldn't reach the stats server. Check your connection and refresh.",
	}
	if status != "ready":
		_content.add_child(Kit.label(note.get(status, ""), 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		if status in ["error", "denied"]:
			_content.add_child(Kit.button("Try again", load_stats, "primary", 28, 84))
		return
	_content.add_child(_range_row())
	_content.add_child(_kpis())
	_content.add_child(_section("Daily players", _daily()))
	_content.add_child(_section("Retention", _retention()))
	_content.add_child(_section("Tutorial", _funnel()))
	_content.add_child(_section("Critters picked", _critters()))
	_content.add_child(_section("Energy", _energy()))
	_content.add_child(_section("Fight modes", _table(data.get("modes", []), "mode", ["fights", "players"])))
	_content.add_child(_section("Screens", _table(data.get("screens", []).slice(0, 12), "screen", ["views", "players"])))
	_content.add_child(_section("Platforms", _table(data.get("platforms", []), "platform", ["players"])))
	_content.add_child(Kit.label("Anonymous guest ids only. Smoke tests and debug builds are left out.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))


# --- Sections -------------------------------------------------------------------

func _range_row() -> Control:
	var row := Kit.hbox(12)
	for d in RANGES:
		var b := Kit.button("%dd" % d, func(): days = d; load_stats(), "primary" if d == days else "ghost", 24, 64)
		b.custom_minimum_size.x = 100
		row.add_child(b)
	row.add_child(Kit.spacer())
	row.add_child(Kit.button("Refresh", load_stats, "ghost", 24, 64))
	return row


func _kpis() -> Control:
	var t: Dictionary = data.get("totals", {})
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for k in [["players", "Players"], ["new_players", "New"], ["dau", "Today"], ["wau", "7-day active"], ["mau", "30-day active"], ["fights", "Fights"]]:
		var tile := Kit.panel(Kit.vbox(2, [Kit.label(Kit.commas(int(t.get(k[0], 0))), 38, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label(k[1], 19, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)]), Kit.box(Kit.PANEL, Kit.LINE, 24, 2, 14))
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(tile)
	return grid


func _daily() -> Control:
	var rows: Array = data.get("daily", [])
	var chart := BarChart.new()
	chart.values = rows.map(func(r): return int(r.get("active", 0)))
	chart.overlay = rows.map(func(r): return int(r.get("new", 0)))
	chart.custom_minimum_size = Vector2(0, 220)
	var first: String = str(rows.front().get("day", "")) if not rows.is_empty() else ""
	var last: String = str(rows.back().get("day", "")) if not rows.is_empty() else ""
	return Kit.vbox(8, [chart, Kit.hbox(0, [Kit.label(first.substr(5), 18, Kit.MUTED), Kit.spacer(), Kit.label(last.substr(5), 18, Kit.MUTED)]),
		Kit.hbox(18, [Kit.label("■ active", 20, Kit.ACCENT), Kit.label("■ new", 20, Kit.GOOD)])])


func _retention() -> Control:
	var cohorts: Array = data.get("retention", [])
	var rates := retention_rates(cohorts)
	var tiles := Kit.hbox(12)
	for d in ["d1", "d3", "d7"]:
		var r: Dictionary = rates[d]
		var text := "-" if r.base == 0 else "%d%%" % roundi(100.0 * r.back / r.base)
		var tile := Kit.panel(Kit.vbox(2, [Kit.label(text, 40, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label("Day %s (of %d)" % [d.substr(1), r.base], 19, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)]), Kit.box(Kit.PANEL, Kit.LINE, 24, 2, 14))
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tiles.add_child(tile)
	var box := Kit.vbox(10, [tiles, Kit.label("Share of each day's new players who came back exactly 1, 3 and 7 days later.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	if cohorts.is_empty():
		return box
	box.add_child(_row(["Started", "New", "D1", "D3", "D7"], Kit.MUTED))
	for c in cohorts.slice(0, COHORT_ROWS):
		var cells := [str(c.day).substr(5), str(c.size)]
		for d in ["d1", "d3", "d7"]:
			cells.append("" if c.get(d) == null else "%d%%" % roundi(100.0 * float(c[d]) / maxf(1.0, float(c.size))))
		box.add_child(_row(cells, Kit.FG))
	return box


func _funnel() -> Control:
	var rows := funnel_rows(data.get("onboarding", {}))
	if rows.is_empty():
		return Kit.label("No tutorial steps logged yet.", 22, Kit.MUTED)
	var box := Kit.vbox(10)
	for r in rows:
		var secs := "" if r.median_ms < 0 else "  ·  %ds in" % roundi(r.median_ms / 1000.0)
		box.add_child(Kit.vbox(4, [Kit.hbox(0, [Kit.label(r.step, 22), Kit.spacer(), Kit.label("%d  (%d%%)%s" % [r.players, roundi(r.frac * 100.0), secs], 20, Kit.MUTED)]),
			Kit.bar(r.frac, Kit.GOOD, 14)]))
	return box


func _critters() -> Control:
	var rows := critter_rows(data.get("critters", {}))
	if rows.is_empty():
		return Kit.label("No fights yet.", 22, Kit.MUTED)
	var box := Kit.vbox(8, [_row(["Critter", "Picks", "Pick %", "Win %"], Kit.MUTED)])
	for r in rows:
		var win_color := Kit.FG if r.win_frac < 0 or absf(r.win_frac - 0.5) <= 0.1 else Kit.WARN
		var row := _row([_name(r.critter), str(r.picks), "%d%%" % roundi(r.pick_frac * 100.0),
			"-" if r.win_frac < 0 else "%d%%" % roundi(r.win_frac * 100.0)], Kit.FG)
		(row.get_child(3) as Label).add_theme_color_override("font_color", win_color)
		box.add_child(row)
	box.add_child(Kit.label("Pick % counts each team slot. Win % outside 40 to 60 is highlighted.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	return box


func _energy() -> Control:
	var rows: Array = data.get("energy", [])
	if rows.is_empty():
		return Kit.label("No energy gained or spent yet.", 22, Kit.MUTED)
	var box := Kit.vbox(8, [_row(["Source", "Gained", "Spent", "Players"], Kit.MUTED)])
	for r in rows:
		box.add_child(_row([str(r.source), "+" + Kit.commas(int(r.gained)), "-" + Kit.commas(int(r.spent)), str(r.players)], Kit.FG))
	return box


func _table(rows: Array, label_key: String, cols: Array) -> Control:
	if rows.is_empty():
		return Kit.label("Nothing yet.", 22, Kit.MUTED)
	var box := Kit.vbox(8, [_row([label_key.capitalize()] + cols.map(func(c): return c.capitalize()), Kit.MUTED)])
	for r in rows:
		box.add_child(_row([str(r.get(label_key, "?"))] + cols.map(func(c): return Kit.commas(int(r.get(c, 0)))), Kit.FG))
	return box


func _section(title: String, body: Control) -> Control:
	return Kit.panel(Kit.vbox(14, [Kit.label(title, 30), body]), Kit.box(Kit.PANEL2, Color(0, 0, 0, 0), 32, 0, 22))


## A table row: the first cell takes the spare width, the rest are fixed.
func _row(cells: Array, color: Color) -> HBoxContainer:
	var row := Kit.hbox(8)
	for i in cells.size():
		var l := Kit.label(str(cells[i]), 21, color, HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
		if i == 0:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.clip_text = true
		else:
			l.custom_minimum_size.x = 100
		row.add_child(l)
	return row


func _name(id: String) -> String:
	for c in Roster.CRITTERS:
		if c.id == id:
			return str(c.name)
	return id.capitalize()


func _side_margin() -> int:
	return maxi(24, int((get_viewport().get_visible_rect().size.x - 720.0) / 2.0) + 24)


static func _js(expr: String) -> String:
	return str(JavaScriptBridge.eval(expr, true)) if OS.has_feature("web") else ""


# --- Pure helpers (tests/test_analytics.gd) -------------------------------------

## The dashboard key from "#k=<key>". Only the fragment counts: it never
## leaves the browser, so the key stays out of server logs and referrers.
static func key_from(hash: String) -> String:
	for part in hash.trim_prefix("#").split("&", false):
		if part.begins_with("k="):
			return part.substr(2).uri_decode().strip_edges()
	return ""


## Day-N retention over the cohorts old enough to have a day N:
## {d1: {back, base}, d3: ..., d7: ...}.
static func retention_rates(cohorts: Array) -> Dictionary:
	var out := {}
	for d in ["d1", "d3", "d7"]:
		var back := 0
		var base := 0
		for c in cohorts:
			if c.get(d) != null:
				back += int(c[d])
				base += int(c.get("size", 0))
		out[d] = {"back": back, "base": base}
	return out


## Tutorial steps with the share of the window's new players who reached each.
static func funnel_rows(onboarding: Dictionary) -> Array:
	var starters := float(onboarding.get("starters", 0))
	var rows := []
	for s in onboarding.get("steps", []):
		var players := int(s.get("players", 0))
		rows.append({"step": str(s.get("step", "")), "players": players,
			"frac": 0.0 if starters <= 0.0 else minf(1.0, players / starters),
			"median_ms": -1.0 if s.get("median_ms") == null else float(s.median_ms)})
	return rows


## Critter rows with pick share (of fights where the player picked) and win
## rate (-1 with no decided fights).
static func critter_rows(critters: Dictionary) -> Array:
	var fights := float(critters.get("fights", 0))
	var rows := []
	for r in critters.get("rows", []):
		var wins := int(r.get("wins", 0))
		var played := wins + int(r.get("losses", 0)) + int(r.get("draws", 0))
		rows.append({"critter": str(r.get("critter", "")), "picks": int(r.get("picks", 0)),
			"pick_frac": 0.0 if fights <= 0.0 else int(r.get("picks", 0)) / fights,
			"win_frac": -1.0 if played == 0 else float(wins) / played})
	return rows


static func demo_data() -> Dictionary:
	var daily := []
	for i in 30:
		daily.append({"day": "2026-09-%02d" % (i + 1), "active": 40 + i * 3 + (i % 7) * 4, "new": 8 + (i % 5) * 3, "fights": 300 + i * 12})
	return {
		"generated_at": "2026-10-14T23:00:00Z", "days": 30,
		"totals": {"players": 412, "new_players": 268, "dau": 131, "wau": 220, "mau": 395, "fights": 11880},
		"daily": daily,
		"retention": [
			{"day": "2026-10-14", "size": 12, "d1": null, "d3": null, "d7": null},
			{"day": "2026-10-13", "size": 15, "d1": 7, "d3": null, "d7": null},
			{"day": "2026-10-10", "size": 11, "d1": 5, "d3": 3, "d7": null},
			{"day": "2026-10-06", "size": 14, "d1": 6, "d3": 4, "d7": 3},
		],
		"onboarding": {"starters": 268, "steps": [
			{"step": "cold_open", "players": 260, "median_ms": 900}, {"step": "starter", "players": 231, "median_ms": 21000},
			{"step": "fight1", "players": 220, "median_ms": 30000}, {"step": "fight2", "players": 181, "median_ms": 75000},
			{"step": "fusion", "players": 150, "median_ms": 120000}, {"step": "done", "players": 139, "median_ms": 150000}]},
		"energy": [{"source": "fight", "gained": 0, "spent": 5400, "players": 300}, {"source": "regen", "gained": 4100, "spent": 0, "players": 290},
			{"source": "friend_gift", "gained": 380, "spent": 0, "players": 61}, {"source": "pack", "gained": 270, "spent": 0, "players": 9}],
		"critters": {"fights": 9000, "rows": [
			{"critter": "vampire", "picks": 4100, "players": 300, "wins": 2300, "losses": 1700, "draws": 100},
			{"critter": "laser", "picks": 3400, "players": 280, "wins": 1500, "losses": 1850, "draws": 50},
			{"critter": "nibbles", "picks": 1500, "players": 120, "wins": 980, "losses": 500, "draws": 20}]},
		"modes": [{"mode": "normal", "fights": 9000, "players": 380}, {"mode": "fight_of_day", "fights": 1900, "players": 210}, {"mode": "rival", "fights": 980, "players": 77}],
		"screens": [{"screen": "play", "views": 5200, "players": 395}, {"screen": "critters", "views": 2100, "players": 300}, {"screen": "fuse", "views": 900, "players": 210}],
		"platforms": [{"platform": "Web", "players": 360}, {"platform": "iOS", "players": 35}],
	}


## Daily bars: `values` as bars, `overlay` drawn over them in a second colour.
class BarChart extends Control:
	var values: Array = []
	var overlay: Array = []

	func _draw() -> void:
		var n := values.size()
		if n == 0:
			return
		var top := 1
		for v in values:
			top = maxi(top, int(v))
		var w := size.x / n
		var gap := minf(4.0, w * 0.2)
		for i in n:
			var h := size.y * float(values[i]) / top
			draw_rect(Rect2(i * w + gap / 2.0, size.y - h, w - gap, h), Kit.ACCENT)
			if i < overlay.size():
				var oh := size.y * float(overlay[i]) / top
				draw_rect(Rect2(i * w + gap / 2.0, size.y - oh, w - gap, oh), Kit.GOOD)
		draw_string(Kit.FONT, Vector2(4, 22), "peak %d" % top, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.MUTED)
