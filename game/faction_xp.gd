## Faction XP for the fight scenes that run outside the shell (the Spire,
## Ghost Arena, Bounce Run): pays it straight into the game save, as Bounce
## Run's chest does, and hands back the gains for the result popup's rings
## (FactionRing). Every other mode gives it through the shell's profile.
extends RefCounted

const SaveGame := preload("res://game/online/save_game.gd")
const Profile := preload("res://meta/profile.gd")


## `fighters`: your critter ids that fought; `winner`: 0 you, 1 them, -1 a draw.
static func award(fighters: Array, winner: int, path := SaveGame.PATH) -> Array:
	if fighters.is_empty():
		return []
	var save := SaveGame.new(path)
	save.load_local()
	var d = save.data.get("profile", {})
	if not (d is Dictionary) or d.is_empty():
		return []
	var p = Profile.from_dict(d, int(Time.get_unix_time_from_system()))
	p.fight_faction_xp(fighters, winner)
	save.data.profile = p.to_dict()
	save.commit()
	return p.take_faction_gains()
