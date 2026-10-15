## Economy pacing report: plays simulated casual, regular and heavy players
## through meta/economy.gd and prints, as Markdown, the day each pacing
## milestone arrives (median, with the 25th-75th percentile) against the
## targets in design/pve.md section 6.
## Usage: godot --headless --script res://tools/economy_sim.gd -- [--players=200] [--days=90] [--wishlist] [--as-built]
##   --players=N  players per archetype
##   --days=N     days to simulate
##   --wishlist   players wishlist their three most-collected Rare+ critters
##   --as-built   also report the numbers before the economy check, for comparison
extends SceneTree

const Economy := preload("res://meta/economy.gd")
const Model := preload("res://meta/economy_model.gd")

const LABELS := {
	"first_fusion": "First fusion (T2)",
	"t2_uncommon": "First Uncommon at T2",
	"t3_common": "First T3 Common",
	"t2_rare": "First Rare+ at T2",
	"legendary": "First Legendary copy",
	"t4": "First T4",
	"t5_common": "First T5 Common",
}


func _init() -> void:
	var players := 200
	var days := 90
	var wishlist := false
	var configs := [Economy.tuned()]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--players="):
			players = int(arg.split("=")[1])
		elif arg.begins_with("--days="):
			days = int(arg.split("=")[1])
		elif arg == "--wishlist":
			wishlist = true
		elif arg == "--as-built":
			configs.push_front(Economy.as_built())
	var lines: Array[String] = []
	for cfg in configs:
		lines.append_array(_table(cfg, players, days, wishlist))
		lines.append("")
	print("\n".join(lines))
	quit(0)


func _table(cfg: Dictionary, players: int, days: int, wishlist: bool) -> Array[String]:
	var r := Model.report(cfg, players, days, 1, wishlist)
	var lines: Array[String] = []
	lines.append("### Economy: %s (%d players each, %d days%s)" % [cfg.name, players, days, ", wishlist on" if wishlist else ""])
	lines.append("")
	lines.append("Day reached: median (25th-75th percentile). `>N` = not reached in N days.")
	lines.append("")
	lines.append("| Milestone | Target (regular) | Casual | Regular | Heavy |")
	lines.append("|---|---|---|---|---|")
	for m in Model.MILESTONES:
		var t: Array = Economy.TARGETS[m]
		var row := "| %s | day %s |" % [LABELS[m], str(t[0]) if t[0] == t[1] else "%d-%d" % t]
		for a in Model.ARCHETYPES:
			row += " %s |" % _cell(r[a][m], days)
		lines.append(row)
	lines.append("")
	lines.append("| Per day played (average) | Casual | Regular | Heavy |")
	lines.append("|---|---|---|---|")
	for k in ["energy", "wins", "copies", "summons", "orbs"]:
		var row := "| %s |" % k.capitalize()
		for a in Model.ARCHETYPES:
			row += " %.1f |" % r[a].per_day[k]
		lines.append(row)
	var zrow := "| Zone reached (end, average; 0 = Glow Garden) |"
	for a in Model.ARCHETYPES:
		zrow += " %.1f |" % r[a].per_day.zone
	lines.append(zrow)
	lines.append("")
	lines.append("Regular players' first fusion comes in session %s (median)." % _fmt(Model.median(r.regular.first_fusion_session), 998))
	return lines


func _cell(sorted: Array, days: int) -> String:
	return "%s (%s-%s)" % [_fmt(Model.median(sorted), days), _fmt(Model.percentile(sorted, .25), days), _fmt(Model.percentile(sorted, .75), days)]


func _fmt(v: float, days: int) -> String:
	if v > days:
		return ">%d" % days
	return str(int(v)) if v == floorf(v) else "%.1f" % v
