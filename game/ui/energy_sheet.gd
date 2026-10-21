## The one "out of energy" sheet every Fight button opens when energy is short:
## the bolt, when the next one lands, and an Energy Pack button if you hold one.
## Callers: const EnergySheet := preload("res://game/ui/energy_sheet.gd").

const Kit := preload("res://game/ui/ui_kit.gd")


## Whether `cost` energy is there right now (regen brought up to date first).
static func has(profile, cost: int) -> bool:
	profile.update_energy(int(Time.get_unix_time_from_system()))
	return profile.energy >= cost


static func open(shell) -> void:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var wait: int = p.seconds_to_next_energy(now)
	var title: HBoxContainer = Kit.hbox(10, [Kit.label("Out of", 36), Kit.glyph("energy", 40, Kit.FG)])
	var v: VBoxContainer = Kit.vbox(18, [title])
	if wait > 0:
		v.add_child(Kit.label("+1 in %d:%02d" % [wait / 60, wait % 60], 26, Kit.MUTED))
	var packs: int = p.item_count("Energy Pack")
	if packs > 0:
		var use: Button = Kit.button("Use Energy Pack (%d)" % packs, func():
			shell.close_overlay()
			if p.use_energy_pack():
				shell.toast("+%d energy" % p.ENERGY_PACK)
				shell.refresh(), "primary", 28, 90)
		shell.mark("energy_pack", use)
		v.add_child(use)
	var ok: Button = Kit.button("Close", shell.close_overlay, "ghost", 26, 80)
	shell.mark("energy_close", ok)
	v.add_child(ok)
	shell.sheet(v)
