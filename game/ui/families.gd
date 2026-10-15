## The theme family of every critter (design/roster.md: Nature, Sea, Tech,
## Sweet, Frost, Toybox, Spooky, Fire, Cosmic), shown in the Critterpedia.
## A critter missing here shows no family chip, so a new critter file never breaks a screen.
extends RefCounted

const NAMES := ["Nature", "Sea", "Tech", "Sweet", "Frost", "Toybox", "Spooky", "Fire", "Cosmic"]
const COLORS := {"Nature": Color("6ee06a"), "Sea": Color("3fc8ff"), "Tech": Color("9fb4d8"), "Sweet": Color("ff8fd0"), "Frost": Color("aee9ff"), "Toybox": Color("ffd23f"), "Spooky": Color("b48cff"), "Fire": Color("ff7a3d"), "Cosmic": Color("8f7bff")}
const OF := {
	"juggernaut": "Nature", "spiker": "Nature", "pip": "Nature", "tumble": "Nature", "mossy": "Nature", "glowbug": "Nature", "thorns": "Nature", "pollen": "Nature", "whiff": "Nature", "zing": "Nature", "mole": "Nature", "sprout": "Nature", "swarm": "Nature", "old_oak": "Nature", "ivy": "Nature",
	"bubbles": "Sea", "puff": "Sea", "shelly": "Sea", "fin": "Sea", "minnow": "Sea", "ink": "Sea", "clam": "Sea", "ripple": "Sea", "hook": "Sea", "beacon": "Sea", "leviathan": "Sea", "kraken": "Sea",
	"static": "Tech", "cogs": "Tech", "bolt": "Tech", "laser": "Tech", "zigzag": "Tech", "zapper": "Tech", "wrecker": "Tech", "gearbox": "Tech", "mirror": "Tech", "magnet": "Tech", "megabot": "Tech", "clockwork": "Tech",
	"crumb": "Sweet", "gumdrop": "Sweet", "honey": "Sweet", "fizz": "Sweet", "pucker": "Sweet", "jawbreaker": "Sweet", "munch": "Sweet", "splitter": "Sweet", "sundae": "Sweet", "bonbon": "Sweet",
	"frost": "Frost", "drizzle": "Frost", "yeti": "Frost", "gust": "Frost", "mammoth": "Frost", "blizz": "Frost", "pounce": "Frost", "frostfang": "Frost", "narwhal": "Frost", "glacia": "Frost",
	"pinball": "Toybox", "drum": "Toybox", "painter": "Toybox", "mortar": "Toybox", "disco": "Toybox", "yoyo": "Toybox", "pixel": "Toybox", "kaleido": "Toybox", "jackpot": "Toybox",
	"vampire": "Spooky", "flicker": "Spooky", "sonar": "Spooky", "totem": "Spooky", "brewster": "Spooky", "ghost": "Spooky", "puppeteer": "Spooky", "foxfire": "Spooky",
	"speedster": "Fire", "sooty": "Fire", "magmo": "Fire", "bomber": "Fire", "drako": "Fire", "phoenix": "Fire", "supernova": "Fire",
	"comet": "Cosmic", "gravity": "Cosmic", "prism": "Cosmic", "quasar": "Cosmic", "stormwing": "Cosmic", "blackhole": "Cosmic", "eclipse": "Cosmic",
}


static func of(id: String) -> String:
	return OF.get(id, "")
