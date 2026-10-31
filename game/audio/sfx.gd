## The game's sound: fight effects from sim events, music, UI clicks and the
## mute toggle. Only reads the sim, never changes it, and uses its own random
## generator so replays stay identical. Sounds are rendered by
## tools/sfx/make_sfx.py; see /design/sound.md for the plan.
extends Node

const AUDIO_DIR := "res://game/audio/"
const Kit := preload("res://game/ui/ui_kit.gd")
const SETTINGS_PATH := "user://settings.cfg"
const VOICES := 16
## Sound modes the toggle cycles through.
const MODES := ["all", "sfx", "off"]
const MODE_LABELS := {"all": "Sound: On", "sfx": "Music: Off", "off": "Sound: Off"}
const FightLayout := preload("res://game/fight_layout.gd")
const TOGGLE_SIZE := FightLayout.PILL
## Per sound: [max playing at once, min seconds between starts, volume dB].
## Lower caps on frequent sounds keep the chaos readable.
## Pitch of the hit_big thud per pulse kind (sim pulse events), so each
## critter's pulse has its own voice.
const PULSE_PITCH := {"drum": 0.7, "wind": 1.6, "ink": 1.3, "stink": 0.9}
const RULES := {
	"hit": [3, 0.05, -2.0],
	"hit_big": [1, 0.25, 0.0],
	"wall": [2, 0.07, -15.0],
	# Family voices: each critter's file picks its family's and a pitch.
	"ouch_nature": [1, 0.18, -8.0],
	"ouch_sea": [1, 0.18, -8.5],
	"ouch_tech": [1, 0.18, -10.0],
	"ouch_sweet": [1, 0.18, -8.0],
	"ouch_frost": [1, 0.18, -9.0],
	"ouch_toybox": [1, 0.18, -11.5],
	"ouch_spooky": [1, 0.18, -11.0],
	"ouch_fire": [1, 0.18, -5.0],
	"ouch_cosmic": [1, 0.18, -9.0],
	"flip": [1, 0.3, -14.0],
	"snap": [1, 0.2, -4.0],
	"crit": [1, 0.15, -5.0],
	"backstab": [1, 0.2, -4.0],
	"ko": [1, 0.5, 0.0],
	"heal": [1, 0.3, -10.0],
	"slurp": [1, 0.25, -8.0],
	"zap": [2, 0.08, -9.0],
	"sizzle": [2, 0.12, -10.0],
	"overtime": [1, 1.0, -6.0],
	"heartbeat": [1, 0.5, -6.0],
	"win": [1, 0.5, -3.0],
	"lose": [1, 0.5, -3.0],
	"draw": [1, 0.5, -3.0],
	"go": [1, 0.3, -5.0],
	"launch": [1, 0.1, -4.0],
	"stretch": [1, 0.07, -14.0],
	"click": [2, 0.04, -8.0],
	"summon_pop": [3, 0.05, -7.0],
	"summon_land": [3, 0.04, -9.0],
	"summon_charge": [1, 0.3, -8.0],
	"summon_legend": [1, 0.5, -3.0],
	"chomp": [1, 0.15, -3.0],
	"thwomp": [1, 0.2, -1.0],
	"pew": [2, 0.06, -6.0],
	"crackle": [2, 0.08, -6.0],
	"rustle": [1, 0.15, -5.0],
	"fizzpop": [1, 0.3, -4.0],
	"drum": [2, 0.08, -4.0],
	"rain": [1, 0.85, -12.0],
	"hum": [1, 0.5, -4.0],
	"ticktock": [1, 0.2, -4.0],
	"splash": [1, 0.3, -2.0],
	"shatter": [1, 0.2, -3.0],
	"clunk": [1, 0.12, -5.0],
	"glug": [1, 0.3, -5.0],
	"whoosh": [1, 0.3, -3.0],
	"buzz": [2, 0.12, -9.0],
	"puff": [1, 0.3, -5.0],
	"roar": [1, 0.5, -2.0],
	"cannon": [1, 0.2, -3.0],
	"splat": [2, 0.1, -6.0],
	"sonar": [1, 0.3, -8.0],
	"twinkle": [1, 0.3, -8.0],
	"zing": [2, 0.08, -7.0],
	# Family knocks: each family's material, tapped under every bump.
	"knock_nature": [2, 0.06, -6.0],
	"knock_sea": [2, 0.06, -10.0],
	"knock_tech": [2, 0.06, -8.0],
	"knock_sweet": [2, 0.06, -10.0],
	"knock_frost": [2, 0.06, -9.0],
	"knock_toybox": [2, 0.06, -10.0],
	"knock_spooky": [2, 0.06, -5.0],
	"knock_fire": [2, 0.06, -3.0],
	"knock_cosmic": [2, 0.06, -12.0],
	# Wall hits: one material per arena theme (game/arena_art.gd families).
	"wallhit_classics": [2, 0.06, -6.0],
	"wallhit_ice": [2, 0.06, -6.0],
	"wallhit_candy": [2, 0.06, -5.0],
	"wallhit_temple": [2, 0.06, -4.0],
	"wallhit_space": [2, 0.06, -7.0],
	"wallhit_ocean": [2, 0.06, -5.0],
	"wallhit_sky": [2, 0.06, -3.0],
	"wallhit_volcano": [2, 0.06, -4.0],
	"wallhit_synth": [2, 0.06, -7.0],
	"wallhit_desert": [2, 0.06, -3.0],
	"wallhit_haunted": [2, 0.06, -5.0],
	"wallhit_toybox": [2, 0.06, -6.0],
	# Critter signatures (CRITTER_CUES) and shared battle moments.
	"zoom": [1, 0.1, -6.0],
	"kaboom": [2, 0.12, -2.0],
	"mine_drop": [1, 0.15, -4.0],
	"frost_crunch": [1, 0.22, -4.0],
	"frost_breath": [1, 0.5, -6.0],
	"thorn_snap": [1, 0.12, -1.0],
	"moon_bonk": [1, 0.15, -5.0],
	"warble": [1, 0.6, -12.0],
	"void_suck": [1, 1.0, -3.0],
	"nova_boom": [1, 0.6, -1.0],
	"coal_hiss": [1, 0.5, -5.0],
	"squirt": [1, 0.3, -4.0],
	"lava_blorp": [1, 0.25, -5.0],
	"ghost_wooo": [1, 0.5, -9.0],
	"spook_hit": [1, 0.3, -3.0],
	"chrome_ching": [1, 0.5, -6.0],
	"pinball_ding": [2, 0.08, -8.0],
	"flipper": [1, 0.15, -5.0],
	"crunch": [1, 0.15, -6.0],
	"bubble_blow": [1, 0.4, -10.0],
	"bubble_pop": [2, 0.08, -9.0],
	"gum_stretch": [1, 0.3, -7.0],
	"gum_snap": [1, 0.2, -7.0],
	"inflate": [1, 0.3, -9.0],
	"spines": [1, 0.3, -3.0],
	"shell_clack": [1, 0.4, -4.0],
	"dart": [1, 0.4, -6.0],
	"spore": [1, 0.35, -12.0],
	"snuff": [1, 0.3, -7.0],
	"fwoomp": [1, 0.3, -5.0],
	"spring_boing": [1, 0.3, -8.0],
	"ratchet": [1, 0.15, -10.0],
	"sour": [1, 0.15, -9.0],
	"pucker_pop": [1, 0.3, -4.0],
	"seed_puff": [1, 0.4, -8.0],
	"candy_clack": [2, 0.08, -7.0],
	"reel": [1, 0.2, -6.0],
	"disco_laser": [1, 0.3, -7.0],
	"stoke": [1, 0.15, -4.0],
	"trumpet": [1, 0.5, -10.0],
	"ice_lock": [1, 0.25, -5.0],
	"nom": [1, 0.12, -6.0],
	"gulp": [1, 0.3, -6.0],
	"ptoo": [1, 0.3, -4.0],
	"burp": [1, 0.5, -6.0],
	"wreck_clang": [1, 0.2, -5.0],
	"totem_knock": [1, 0.2, -6.0],
	"yoyo_whirr": [1, 0.4, -7.0],
	"snow_burst": [1, 0.2, -4.0],
	"snowflake": [1, 0.3, -10.0],
	"foghorn": [1, 3.0, -8.0],
	"hiss": [1, 0.4, -9.0],
	"swipe": [1, 0.2, -5.0],
	"warp_8bit": [1, 0.2, -10.0],
	"boom_8bit": [1, 0.2, -6.0],
	"kaleido_click": [1, 0.3, -8.0],
	"puppet_string": [1, 0.2, -6.0],
	"tada": [1, 0.5, -8.0],
	"rocket": [2, 0.08, -8.0],
	"lockon": [1, 0.4, -8.0],
	"shield_up": [1, 0.4, -10.0],
	"shield_tink": [1, 0.15, -10.0],
	"scoop": [1, 0.12, -6.0],
	"swell": [1, 0.3, -9.0],
	"slot_spin": [1, 0.8, -6.0],
	"coins": [1, 0.3, -7.0],
	"tentacle_slap": [1, 0.3, -5.0],
	"squelch": [1, 0.3, -6.0],
	"thunder": [1, 0.6, -2.0],
	"fox_whisper": [1, 0.6, -6.0],
	"howl": [1, 1.0, -10.0],
	"whale_call": [1, 0.6, -9.0],
	"eclipse_flip": [1, 0.6, -8.0],
	"ribbon": [1, 0.3, -6.0],
	"confetti_pop": [1, 0.3, -1.0],
	"prism_ray": [1, 0.15, -8.0],
	"ripple_wash": [1, 0.3, -9.0],
	"spine": [2, 0.06, -12.0],
	"shing": [1, 0.12, -8.0],
	"honey_squelch": [1, 0.3, -5.0],
	"honey_drip": [1, 0.2, -10.0],
	"dizzy": [1, 0.5, -10.0],
	"dig": [1, 0.3, -6.0],
	"ot_tick": [1, 0.2, -10.0],
	"t5_shine": [1, 2.0, -9.0],
	"ko_final": [1, 0.5, -1.0],
}
## Each critter's own sounds, by sim event: "type:kind" (tried first) or
## "type", for events whose owner (the beam's owner, the damage's source, the
## ball) is that critter. Each cue is [sound, volume dB, pitch], plus optionally
## [..., key, step]: the pitch rises by `step` per unit of the event's `key`
## ("speed" reads the ball's speed share instead). An empty list keeps the
## event quiet where the shared sound would be wrong (Bubbles' little bubbles
## used to zap like a laser). "zone:<kind>" plays when the critter puts down a
## floor zone (a mine, a puddle). Damage cues replace only the hit's body:
## crits, family edges and the target's voice still play. Events not listed
## fall back on the shared sounds in consume_events.
const CRITTER_CUES := {
	"vampire": {"damage:contact": [["chomp", 0.0, 1.0]]},
	"juggernaut": {"damage:contact": [["thwomp", 0.0, 1.0]], "damage:slam": [["thwomp", 0.0, 0.85]]},
	"spiker": {"spike": [["shing", 0.0, 0.9, "spikes", 0.05]], "shot:spike": [["spine", 0.0, 1.0]], "shot_pop:spike": []},
	"speedster": {"bounce": [["zoom", 0.0, 0.8, "speed", 0.5]], "damage:afterimage": [["zoom", -10.0, 1.6]]},
	"bomber": {"zone:mine": [["mine_drop", 0.0, 1.0]], "boom": [["kaboom", 0.0, 1.0]]},
	"frost": {"damage:ice": [["frost_crunch", 0.0, 1.0]], "pulse:frost": [["frost_breath", 0.0, 1.0]]},
	"thorns": {"reflect": [["thorn_snap", 0.0, 1.0]], "damage:reflect": [], "damage:burn": []},
	"gravity": {"damage:moon": [["moon_bonk", 0.0, 1.0]], "pulse:flare": [["warble", 0.0, 1.0]]},
	"mirror": {"copy": [["chrome_ching", 0.0, 1.0]], "reflect": [["chrome_ching", -6.0, 1.5]]},
	"blackhole": {"pulse:nova": [["void_suck", 0.0, 1.0]], "damage:ring": [["nova_boom", 0.0, 0.85]]},
	"prism": {"beam": [["prism_ray", 0.0, 1.0]], "reflect": [["prism_ray", -4.0, 1.3]]},
	"pinball": {"ding": [["pinball_ding", 0.0, 1.0, "lit", 0.12]], "tilt": [["flipper", 0.0, 1.0]], "charge": [["flipper", -3.0, 1.2]]},
	"crumb": {"beam": [], "grow": [["crunch", 0.0, 1.0]], "damage:beam": [["crunch", -6.0, 1.4]], "heal": [["crunch", -4.0, 0.9]]},
	"sooty": {"pulse:fire": [["coal_hiss", 0.0, 1.0]], "damage:ember": [["knock_fire", -2.0, 1.0]]},
	"bubbles": {"bubble": [["bubble_blow", 0.0, 1.0]], "bubble_pop": [["bubble_pop", 0.0, 0.8], ["splash", -6.0, 1.4]],
		"beam": [], "pulse:wave": [], "damage:beam": [["bubble_pop", -3.0, 1.3]]},
	"gumdrop": {"tether": [["gum_stretch", 0.0, 1.0]], "tether_end": [["gum_snap", 0.0, 1.0]], "damage:burn": []},
	"puff": {"grow": [["inflate", 0.0, 1.0]], "pulse:pulse": [["spines", 0.0, 1.0]], "beam": [], "damage:beam": []},
	"shelly": {"pulse:pulse": [["shell_clack", 0.0, 1.0]], "heal": []},
	"minnow": {"pulse:pulse": [["dart", 0.0, 1.0]], "heal": []},
	"mossy": {"heal": [], "damage:burn": [], "damage:spore": [["spore", 0.0, 1.0]]},
	"glowbug": {"damage:moon": [["crackle", -4.0, 1.5]], "damage:bugflare": [["crackle", -4.0, 1.5]], "pulse:bugflare": [["twinkle", -8.0, 1.3]]},
	"flicker": {"phase": [["snuff", 0.0, 1.0]], "pulse:flame": [["fwoomp", 0.0, 1.0]], "relight": [], "damage:burn": []},
	"cogs": {"unwind": [["spring_boing", 0.0, 1.0]]},
	"fizz": {"pop": [["fizzpop", 0.0, 1.0]]},
	"honey": {"zone:honey": [["honey_drip", 0.0, 1.0]], "honey_stuck": [["honey_squelch", 0.0, 1.0]], "stun": [], "charge": []},
	"bolt": {"teleport": [["warp_8bit", 0.0, 0.7], ["crackle", -6.0, 1.3]], "beam": []},
	"ink": {"pulse:ink": [["squirt", 0.0, 1.0]]},
	"pucker": {"sour": [["sour", 0.0, 1.0]], "pucker": [["pucker_pop", 0.0, 1.0]], "stun": [], "pulse:sour": []},
	"pollen": {"shot:seed": [], "shot_pop:seed": [], "pulse:pulse": [["seed_puff", 0.0, 1.0]]},
	"magmo": {"damage:contact": [["lava_blorp", 0.0, 1.0]], "damage:lava": [], "damage:burn": []},
	"clam": {"shot:pearl": [["pew", 0.0, 0.7], ["bubble_pop", -6.0, 0.9]]},
	"jawbreaker": {"orb_lost": [["candy_clack", 0.0, 0.8]], "damage:candy": [["candy_clack", 0.0, 1.2]]},
	"ripple": {"beam": [["ripple_wash", 0.0, 1.0]]},
	"comet": {"beam": [["twinkle", 0.0, 1.0]]},
	"mortar": {"shot:shell": [["cannon", 0.0, 1.0]], "pulse:shell": [["kaboom", -6.0, 1.3]]},
	"mole": {"dig": [["dig", 0.0, 1.0]], "charge": [], "boom": [["thwomp", -4.0, 1.3]]},
	"zigzag": {"beam": [["crackle", -3.0, 1.2]]},
	"sprout": {"piece_break:seed": [["crunch", 0.0, 0.8]], "rays:seed": [["rustle", -3.0, 1.4]]},
	"hook": {"yank": [["reel", 0.0, 1.0]]},
	"zapper": {"damage:zap": [["crackle", 0.0, 1.0]], "beam": [], "stun": [["dizzy", -4.0, 1.3]]},
	"disco": {"rays:disco": [["disco_laser", 0.0, 1.0]]},
	"drako": {"stack": [["stoke", 0.0, 0.9, "stacks", 0.08]], "beam": [], "breath": [["whoosh", 0.0, 1.0], ["roar", -6.0, 1.6]]},
	"mammoth": {"damage:contact": [["thwomp", -3.0, 1.15]], "damage:slam": [["trumpet", 0.0, 1.0]], "stun": [["ice_lock", 0.0, 1.0]]},
	"munch": {"damage:contact": [["chomp", 0.0, 0.85]], "grow": [["nom", 0.0, 1.0]], "stack": [], "swallow": [["gulp", 0.0, 1.0]],
		"spit": [["ptoo", 0.0, 1.0]], "burp": [["burp", 0.0, 1.0]], "stun": [], "charge": []},
	"wrecker": {"damage:wreck": [["wreck_clang", 0.0, 1.0]], "beam": [], "damage:beam": []},
	"totem": {"stack": [["totem_knock", 0.0, 0.9, "stacks", 0.12]]},
	"yoyo": {"yoyo": [["yoyo_whirr", 0.0, 1.0]], "beam": [], "walkies": [["yoyo_whirr", 0.0, 0.8], ["tada", -6.0, 1.2]]},
	"swarm": {"damage:bee": [["buzz", 0.0, 1.1]], "launch": [["buzz", 0.0, 1.5]]},
	"blizz": {"zone:mine": [["snowflake", 0.0, 1.0]], "boom": [["snow_burst", 0.0, 1.0]]},
	"beacon": {"beam": [["foghorn", 0.0, 1.0]]},
	"brewster": {"shot:blob": [["glug", 0.0, 1.0]]},
	"pounce": {"mark": [["hiss", 0.0, 1.0]], "charge": [["swipe", 0.0, 1.0]], "pounce": [["thwomp", -4.0, 1.4], ["crit", -6.0, 1.2]]},
	"pixel": {"teleport": [["warp_8bit", 0.0, 1.0]], "pulse:glitch": [], "boom": [["boom_8bit", 0.0, 1.0]]},
	"kaleido": {"mode": [["kaleido_click", 0.0, 1.0]], "pulse:pulse": []},
	"puppeteer": {"tether": [["puppet_string", 0.0, 1.0]], "tug": [["puppet_string", -8.0, 1.5]], "charge": [],
		"fling": [["whoosh", -2.0, 1.5]], "bow": [["tada", 0.0, 1.0]], "stun": [], "tether_end": []},
	"leviathan": {"dive": [["splash", -4.0, 1.4], ["whale_call", -6.0, 0.6]]},
	"megabot": {"salvo_lock": [["lockon", 0.0, 1.0]], "shot:rocket": [["rocket", 0.0, 1.0]], "shot_pop:rocket": [["kaboom", -8.0, 1.5]],
		"salvo": [["shield_up", 0.0, 0.8]], "mega": [["shield_up", 0.0, 0.7]]},
	"sundae": {"grow": [], "stack": [["scoop", 0.0, 0.9, "stacks", 0.1]], "damage:splat": [["splat", -3.0, 1.2]]},
	"supernova": {"grow": [], "stack": [["swell", 0.0, 0.8, "stacks", 0.06]], "pulse:nova": [["nova_boom", 0.0, 1.0]]},
	"jackpot": {"spin": [["slot_spin", 0.0, 1.0]], "rays:coin": [["coins", 0.0, 1.0]], "beam": [["zap", -2.0, 1.3]]},
	"kraken": {"pulse:inkslam": [["tentacle_slap", 0.0, 1.0]], "hug": [["squelch", 0.0, 1.0]], "damage:inkpool": []},
	"stormwing": {"storm": [["thunder", 0.0, 1.0]], "beam": [], "stun": []},
	"foxfire": {"illusions": [["fox_whisper", 0.0, 1.0]], "pulse:fire": [["fwoomp", 0.0, 1.2]], "swap": [["fox_whisper", -4.0, 1.3]]},
	"frostfang": {"charge": [["howl", 0.0, 1.0]], "stun": [["ice_lock", 0.0, 1.0]], "pulse:shards": [["shatter", -2.0, 1.2]]},
	"narwhal": {"charge": [["whale_call", 0.0, 1.0]], "beam": [["twinkle", -4.0, 0.9]], "lance": [["snap", 0.0, 1.1], ["shing", -4.0, 1.0]]},
	"eclipse": {"mode": [["eclipse_flip", 0.0, 1.0]], "pulse:flare": [], "heal": [], "damage:burn": []},
	"bonbon": {"wrap": [["ribbon", 0.0, 1.0]], "wrap_pop": [["confetti_pop", 0.0, 1.0]], "stun": [], "pulse:confetti": []},
	# Round 2 critters (2026-10-31), from the existing sound kit.
	"boing": {"spring": [["spring_boing", 0.0, 1.0]], "zone:spring": [["click", -6.0, 1.3]], "stun": [["dizzy", -4.0, 1.4]]},
	"snowbo": {"snow": [["frost_crunch", -3.0, 1.2, "stacks", 0.1]], "snowball": [["snow_burst", 0.0, 1.0]], "bowl": [["thwomp", -2.0, 1.2]], "stun": [], "charge": []},
	"zorp": {"abduct": [["warble", 0.0, 1.3]], "drop": [["thwomp", -3.0, 1.1]], "stun": [], "pulse:thud": [], "charge": [["whoosh", -4.0, 1.4]]},
	"snooze": {"wake": [["ticktock", -2.0, 1.4], ["tada", -4.0, 1.2]], "doze": [["hum", -10.0, 0.7]], "pulse:roar": [["roar", -3.0, 1.3]], "grow": []},
	"kernel": {"pop": [["fizzpop", 0.0, 1.3], ["crackle", -4.0, 1.4]], "shot:kernel": [], "shot_pop:kernel": [], "damage:shot": [["crunch", -6.0, 1.5]]},
	"gourdo": {"scare": [["ghost_wooo", 0.0, 1.2], ["spook_hit", -4.0, 1.0]], "stun": [["dizzy", -4.0, 1.2]]},
	"boomer": {"throw": [["whoosh", -2.0, 1.3]], "catch": [["candy_clack", -2.0, 0.8]], "damage:boomerang": [["knock_toybox", 0.0, 1.2]], "grow": []},
	"beans": {"bean:bean_hot": [["nom", 0.0, 1.2], ["hiss", -6.0, 1.1]], "bean:bean_sour": [["nom", 0.0, 1.2], ["sour", -4.0, 1.0]], "bean:bean_fizz": [["nom", 0.0, 1.2], ["fizzpop", -2.0, 1.1]], "bean:bean_rainbow": [["nom", 0.0, 1.0], ["tada", -4.0, 1.2]], "zone": [["squelch", -8.0, 1.4]]},
	"shade": {"shadow_hit": [["fox_whisper", -2.0, 0.9], ["whoosh", -6.0, 0.8]], "shadow_swap": [["eclipse_flip", -2.0, 1.0]]},
	"astra": {"star": [["twinkle", -4.0, 1.3]], "constellation": [["prism_ray", -2.0, 0.9], ["twinkle", -2.0, 0.8]]},
	"blaze": {"ignite": [["whoosh", -2.0, 0.8], ["stoke", -4.0, 1.0]], "firestorm": [["kaboom", -2.0, 1.1], ["crackle", -2.0, 0.9]]},
	"rift": {"rift": [["hum", -6.0, 0.7]], "warp": [["warble", -2.0, 0.6], ["zoom", -6.0, 0.7]]},
}
## The voice and knock family per critter (see sim/families.gd).
const Families := preload("res://sim/families.gd")
const FightHaptics := preload("res://game/platform/fight_haptics.gd")
## Pitch of the edge-hit zing per attacking family, so each family's edge
## sounds its own; a very good hit goes a step higher still.
const ZING_PITCH := {"nature": 0.85, "sea": 0.8, "tech": 1.2, "sweet": 1.3, "frost": 1.35, "toybox": 1.1, "spooky": 0.7, "fire": 0.95, "cosmic": 1.05}
## Seconds between rain patters while one of Drizzle's showers is falling.
const RAIN_EVERY := 0.9
## Applied to every sound and the music so busy moments don't clip.
const MASTER_DB := -7.0
## Music per track: [file, volume dB, loops]. Menu: "Nocturnal Menu"; fight and
## overtime: "Neon Pulse" at 120 and 140 BPM (both FreeMusic AI, looped by
## tools/music/loop_track.py); victory: remixed from "Crypto" by Kevin MacLeod
## (CC-BY 4.0, credited in CREDITS.md and Settings) by tools/music/remix_crypto.py.
## All render at the same loudness, so these set the mix.
## The menu loop plays across every screen outside fights and picks up where it
## left off; overtime is the fight theme faster; victory loops
## past its one-bar hit (VICTORY_LOOP_FROM) while the win screen is up.
const MUSIC := {
	"menu": ["music_menu", -11.0, true],
	"fight": ["music_fight", -11.0, true],
	"overtime": ["music_overtime", -10.0, true],
	"victory": ["music_victory", -9.0, true],
}
const VICTORY_LOOP_FROM := 3.0 / 1.1 ## Crypto's 3 s bar, sped up 1.1x.
## Seconds a track change fades over, so music never cuts with a click.
const MUSIC_FADE := 0.3
## After a win, how long the victory tune waits for a results popup to hold
## it (hold_victory) before the menu music takes over.
const VICTORY_GRACE := 1.6
## Contact damage at or above this share of the target's max HP is a "big hit".
const BIG_HIT_SHARE := 0.18
const LOW_HP_SHARE := 0.35
const HEARTBEAT_EVERY := 0.85
const SIM_DT := 1.0 / 60.0 ## consume_events runs once per sim step.

var mode := "all"
## Set while a fight is on screen, for the overtime cue and low-HP pulse.
var fight_sim
## The sim side the player is on (live matches put you on side 1 half the time).
var you_side := 0

var _variants := {} ## sound name -> Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _last_start := {} ## sound name -> seconds
var _ends := {} ## sound name -> end times of the copies started
var _music: AudioStreamPlayer ## The current track.
var _music_out: AudioStreamPlayer ## The previous track while it fades out.
var _music_track := ""
var _fade: Tween
## Web: browsers start audio on the first tap, so the first track waits for it.
static var _audio_unlocked := false
## Where the menu loop was when it last stopped, so it carries on rather than
## restarting. Fight screens are their own scenes, each with a new Sfx, so this
## has to outlive the node. _menu_left_at is when a scene change cut it off
## (the music keeps "playing" through the load); -1 once a fight paused it.
static var _menu_pos := 0.0
static var _menu_left_at := -1.0
var _victory_hold: WeakRef ## The results popup the victory tune plays under.
var _victory_at := 0.0
var _menu_pending := false
var _was_overtime := false
var _heartbeat_in := 0.0
var _rain_in := 0.0
var _drum_beat := 0 ## Alternates Drum's wall taps between two pitches.
var _wall_sound := "wallhit_classics" ## This fight's wall material (see wall_sound()).
var _tick_in := 0.0 ## Seconds to the next overtime clock tick.
var _zones_heard := {} ## Instance ids of the floor zones already sounded.
var _rng := RandomNumberGenerator.new() ## Render-side only: never the sim's.
var _clock := 0.0
var _toggle: Button
## Hide the corner toggle, e.g. on the home screens, where the settings sheet
## has the same switch and the corner would sit on top of screen buttons.
var toggle_hidden := false:
	set(v):
		toggle_hidden = v
		if _toggle:
			_toggle.visible = not toggle_hidden
var _board: Control
## When set, play() appends [name, file, dB, pitch, time] here instead of
## playing (tools/sfx/sound_audit.gd, tools/sfx/fight_clip.gd).
var record = null


func _init() -> void:
	_rng.randomize()
	for name in RULES:
		_variants[name] = _load_variants(name)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music_out = AudioStreamPlayer.new()
	add_child(_music_out)
	for p in [_music, _music_out]:
		# The web build plays sounds as browser samples by default, which
		# decodes a whole track up front: the 3 min menu loop cost ~230 MB
		# (engine heap that never shrinks, plus a copy per play) and crashed
		# iPhone Safari. Streamed music is mixed a little at a time instead;
		# project.godot's audio/driver/output_latency.web gives the mix enough
		# buffer to ride out a slow frame.
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	if not OS.has_feature("web"):
		_audio_unlocked = true
	_load_settings()


func _ready() -> void:
	_build_toggle()
	get_tree().node_added.connect(_on_node_added)
	if OS.has_feature("web") and "sounds=1" in str(JavaScriptBridge.eval("window.location.search", true)):
		show_board.call_deferred()


## Native apps: no sound while the app is in the background (the web build
## suspends its audio from game/web/shell.html when the page is hidden).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_RESUMED:
		AudioServer.set_bus_mute(0, what == NOTIFICATION_APPLICATION_PAUSED)


func _exit_tree() -> void:
	_save_menu_pos(true) # A scene change: the next screen's Sfx carries on from here.


func _input(event: InputEvent) -> void:
	if _audio_unlocked or not (event is InputEventMouseButton or event is InputEventScreenTouch) or not event.pressed:
		return
	_audio_unlocked = true
	if _music_track != "" and mode == "all" and not _music.playing:
		_start_music(_music_track)


func _process(delta: float) -> void:
	_clock += delta
	if _music_track == "victory" and (_menu_pending or _victory_hold != null):
		var hold: Control = _victory_hold.get_ref() if _victory_hold else null
		var held := hold != null and _shown(hold)
		if not held and (_victory_hold != null or _clock - _victory_at > VICTORY_GRACE):
			_menu_pending = false
			_victory_hold = null
			play_music("menu")
	if fight_sim == null or fight_sim.finished:
		return
	_rain_in -= delta
	if _rain_in <= 0.0:
		for z in fight_sim.zones:
			if z.kind == "rain" and z.armed():
				play("rain")
				_rain_in = RAIN_EVERY
				break
	var you = fight_sim.balls[you_side]
	if you.alive() and you.hp < you.max_hp * LOW_HP_SHARE:
		_heartbeat_in -= delta
		if _heartbeat_in <= 0.0:
			play("heartbeat")
			_heartbeat_in = HEARTBEAT_EVERY
	else:
		_heartbeat_in = 0.0


# --- Public hooks (called by main.gd) ----------------------------------------

func on_menu() -> void:
	fight_sim = null
	if _music_track == "victory": # Hand over once the win screen is gone (_process).
		_menu_pending = true
		return
	play_music("menu")


## Whether a popup is still up: attached and not hidden by its parents.
static func _shown(node: Node) -> bool:
	if node.get_parent() == null:
		return false
	while node is CanvasItem:
		if not node.visible:
			return false
		node = node.get_parent()
	return true


## Keeps the victory tune playing while this popup (a win's results) is up;
## the menu music takes over once it closes.
func hold_victory(popup: Control) -> void:
	if _music_track == "victory":
		_victory_hold = weakref(popup)


func on_aim_drag(pull: float) -> void:
	play("stretch", 0.0, 0.8 + clampf(pull, 0.0, 1.0) * 0.8)


func on_fight_start(sim) -> void:
	fight_sim = sim
	_wall_sound = wall_sound(sim.arena_id)
	_was_overtime = false
	_heartbeat_in = 0.0
	_menu_pending = false
	_zones_heard = {}
	play("go")
	play_music("fight")


func on_result(winner: int) -> void:
	fight_sim = null
	_menu_pending = false
	_victory_hold = null
	if winner == 0 and mode == "all": # The victory fanfare is the win jingle.
		_victory_at = _clock
		play_music("victory")
		return
	var jingle := "draw" if winner < 0 else ("win" if winner == 0 else "lose")
	if is_inside_tree():
		get_tree().create_timer(0.45).timeout.connect(func(): play(jingle))
	play_music("menu")


## Turns one sim step's events into sound.
func consume_events(events: Array[Dictionary], sim) -> void:
	FightHaptics.consume(events, sim)
	_zone_cues(sim)
	for e in events:
		if e.type == "bounce":
			_wall_hit(e, sim)
		var owner = _owner(e, sim)
		var cues = _critter_cues(e, owner)
		if cues != null:
			for c in cues:
				var pitch: float = c[2]
				if c.size() > 3:
					var amount: float = _speed_share(owner) if c[3] == "speed" else float(e.get(c[3], 0))
					pitch += c[4] * amount
				play(c[0], c[1], pitch)
			if not cues.is_empty() and owner.def.get("tier", 1) >= 5 and not e.type in ["damage", "bounce", "collide", "heal"]:
				play("t5_shine") # A T5 ability rings with a little gold on top.
			if e.type != "damage":
				continue
		match e.type:
			"collide":
				var a = sim.balls[e.a]
				var b = sim.balls[e.b]
				var avg_radius: float = (a.radius + b.radius) / 2.0
				# Harder bumps ring louder: closing speed against a typical bump.
				var force := clampf((a.vel - b.vel).length() / 900.0, 0.0, 1.0)
				play("hit", lerpf(-6.0, 1.0, force), clampf(64.0 / avg_radius, 0.7, 1.4))
				for ball in [a, b]: # Each side's family material under the bonk.
					var fam := Families.of(ball.type_id)
					if fam != "":
						play("knock_" + fam, lerpf(-4.0, 0.0, force), clampf(64.0 / ball.radius, 0.75, 1.3))
			"damage":
				var target = sim.balls[e.target]
				if e.get("backstab", false):
					play("backstab")
				if e.get("crit", false):
					play("crit", 0.0, 1.0 if e.kind == "contact" else 1.25)
				var edge: int = e.get("edge", 0)
				if edge > 0 and owner != null: # The family edge rings over the hit.
					play("zing", 0.0 if edge == 2 else -3.0, ZING_PITCH.get(Families.of(owner.type_id), 1.0) * (1.26 if edge == 2 else 1.0))
				if cues != null:
					pass # The critter's own sound is the hit's body.
				elif e.kind == "beam":
					play("sizzle")
				elif e.amount >= target.max_hp * BIG_HIT_SHARE:
					play("hit_big")
				# Each critter file names its ouch voice (its family's) and pitch.
				if target.alive() and target.def.ouch != "":
					play(target.def.ouch, 0.0, target.def.voice_pitch)
			"heal":
				play("slurp")
				play("heal", 0.0, 1.0 + clampf(e.amount / 20.0, 0.0, 0.3))
			"bounce":
				var ball = sim.balls[e.ball] if e.ball < sim.balls.size() else null
				if ball != null and ball.type_id == "drum": # A little beat off the walls.
					_drum_beat += 1
					play("drum", -6.0, 1.5 if _drum_beat % 2 else 1.2)
			"beam":
				play("zap")
			"flip":
				play("flip", 0.0, 1.0 if e.pulling else 0.85)
			"snap":
				play("snap")
			"boom", "pulse":
				var kind: String = e.get("kind", "")
				if e.type == "boom": # A mine or bomb going off.
					play("kaboom", 0.0, 1.0)
				elif kind in ["zap", "bigzap"]:
					play("crackle", 0.0, 1.15 if kind == "zap" else 0.8)
				elif kind == "drum":
					play("drum", 0.0, 0.9)
				elif kind == "dirt": # Mole bursting up.
					play("thwomp", 0.0, 1.2)
				elif kind == "flame": # Flicker relighting.
					play("sizzle", 0.0, 0.8)
				elif kind == "sour":
					play("slurp", 0.0, 1.4)
				elif kind == "tick": # Clockwork's tick ring.
					play("ticktock")
				elif kind == "wave": # Leviathan bursting up.
					play("splash")
				elif kind == "tide": # Ripple's T5 wave.
					play("splash", -2.0, 1.2)
				elif kind == "sunfire": # Phoenix T5 sunfire.
					play("whoosh", 0.0, 0.8)
					play("sizzle", -2.0, 1.2)
				elif kind == "honey": # Honey's T5 sting.
					play("buzz", 0.0, 1.3)
				elif kind == "ping": # Sonar's ping.
					play("sonar")
				elif kind == "paint": # Painter's paint drying.
					play("splat", 0.0, 0.9 + _rng.randf() * 0.2)
				elif kind == "wind": # Gust's huff.
					play("whoosh", 0.0, 1.4)
				elif kind == "stink": # Whiff's cloud blooming.
					play("puff", 0.0, 0.9)
				elif kind == "candy": # Jawbreaker's sugar blast.
					play("crit", -3.0, 1.4)
					play("hit_big", -4.0, 1.2)
				elif kind == "quasar":
					play("hum")
				elif kind == "core_nova": # A power core's shockwave.
					play("nova_boom", -2.0, 1.25)
				elif kind in ["nova", "thunder"]:
					play("nova_boom", 0.0, 1.0 if kind == "nova" else 1.3)
				elif kind == "frost": # Yeti's avalanche (the roar plays too).
					play("snow_burst", -2.0, 0.8)
				elif kind == "fire":
					play("fwoomp")
				elif kind == "land": # Touching down from a launch pad.
					play("thwomp", 0.0, 1.1)
				elif kind == "ink":
					play("squirt")
				else:
					play("hit_big", 0.0, PULSE_PITCH.get(kind, 1.1))
			"reflect":
				play("hit", -4.0, 1.5)
			"ricochet": # A Ricochet Core's boosted bump.
				play("snap", -3.0, 1.3)
			"spike": # Spike Yard: a sharp, high snap.
				play("snap", -2.0, 1.7)
			"lava":
				play("sizzle", -6.0, 0.8)
			"portal":
				play("flip", 0.0, 1.6)
			"core": # A power core taken: a bright shine and a charge-up.
				play("t5_shine", 0.0, 1.1)
				play("shield_up", -4.0, 1.2)
			"pickup": # A heal / shield pickup: a shine (its heal or shield event adds the rest).
				play("t5_shine", -4.0, 1.4)
			"crystal_crack":
				play("shield_tink", -4.0, 1.3 + _rng.randf() * 0.2)
			"crystal_break":
				play("shatter", 0.0, 0.9)
			"crystal_grow":
				play("snowflake", -8.0, 1.4)
			"jump": # Off a launch pad.
				play("spring_boing", -2.0, 1.0)
			"bumper": # An arena bumper: a pinball 'ding'.
				play("pinball_ding", -2.0, 0.8)
			"sling": # Sprout slung off its own pillar: a springy, leafy ding.
				play("pinball_ding", -4.0, 1.25)
				play("rustle", -6.0, 1.4)
			"shot":
				if e.kind == "pea":
					play("pew")
				elif e.kind == "pearl":
					play("pew", 0.0, 0.7)
				elif e.kind == "stinger":
					play("buzz", -2.0, 1.5)
				else:
					play("launch", -6.0, 1.8 if e.kind != "shell" and e.kind != "blob" else 0.9)
			"shot_pop":
				play("bubble_pop", -4.0, 0.8)
			"shut": # Clam clamping shut.
				play("clunk", 0.0, 1.3)
			"salvo", "mega":
				play("snap", 0.0, 0.7)
			"phase":
				play("flip", 0.0, 1.4)
			"ambush":
				play("spook_hit")
			"copy":
				play("snap", 0.0, 1.25)
			"revive":
				play("heal", 0.0, 0.8)
				play("fwoomp", 0.0, 0.8)
			"honey_lob": # Honey T5 lobbing a glob.
				play("glug", 0.0, 1.3)
			"honey_crush":
				play("honey_squelch", 0.0, 0.8)
				play("thwomp", -4.0, 1.2)
			"heard": # Sonar T5 locking on.
				play("sonar", 0.0, 1.3)
			"split": # Splitter tearing in two: a gooey stretch and a pop.
				play("stretch", 0.0, 0.7)
				play("slurp", -3.0, 1.3)
			"grow": # Grow and shrink (Puff, Crumb, Tumble): higher when shrinking.
				if e.ball < sim.balls.size() and sim.balls[e.ball].type_id == "tumble" and e.bigger:
					play("rustle", 0.0, 0.9 + 0.05 * int(sim.balls[e.ball].state.get("twigs", 0)))
				else:
					play("flip", -3.0, 0.75 if e.bigger else 1.6)
			"chomp": # Fin's big bite.
				play("chomp", 0.0, 0.8)
				play("hit_big", -3.0, 0.9)
			"unwind":
				play("snap", 0.0, 0.8)
			"pop":
				play("flip", 0.0, 1.8)
			"stun": # Cartoon birdies round a stunned head.
				play("dizzy")
			"shield":
				play("shield_up")
			"shield_hit", "shielded":
				play("shield_tink")
			"wrap":
				play("stretch", 0.0, 1.3)
			"spike_burst":
				play("pew", 0.0, 0.8)
				play("pew", -4.0, 1.1)
			"relight":
				play("hit_big", -4.0, 0.7)
			"wrap_pop":
				play("snap", 0.0, 1.4)
			"shatter": # Frostfang breaking the ice.
				play("shatter")
				play("hit_big", -4.0, 0.9)
			"storm": # Thunderbird's storm: a big electric crack.
				play("thunder")
			"stack": # Stacks and forms: a rising tick per stack.
				if e.up:
					play("flip", -6.0, 1.1 + 0.08 * e.stacks)
			"burp":
				play("burp")
			"roar":
				play("roar")
				play("hit_big", -4.0, 0.7)
			"breath": # Drako's fire.
				play("whoosh")
			"shout":
				play("snap", 0.0, 0.75)
			"mode":
				play("flip", -2.0, 1.3)
			"bubble", "bubble_pop":
				play("flip", -4.0 if e.type == "bubble" else 0.0, 2.0)
			"launch":
				play("zap", -4.0, 1.6)
			"yoyo", "fling":
				play("stretch", 0.0, 1.3 if e.type == "yoyo" else 1.6)
			"hug":
				play("flip", 0.0, 0.9)
			"dive": # Leviathan plunging under.
				play("splash", -4.0, 1.4)
			"orb_lost":
				play("click", 0.0, 1.4)
			# Movement critters (batch F) reuse the existing sounds at new pitches.
			"teleport":
				play("zap", 0.0, 1.5)
			"charge":
				play("launch", -3.0, 1.2)
			"tether", "yank", "tug":
				play("stretch", 0.0, 0.8 if e.type == "tether" else (0.9 if e.get("big", false) else 1.2))
			"tether_end", "bow":
				play("click", 0.0, 0.7)
			"mark":
				play("click", 0.0, 1.6)
			"pounce", "lance", "ping_crit", "gear_slam", "tilt":
				play("snap", 0.0, 1.1)
				if e.type == "gear_slam":
					play("clunk", 0.0, 0.7)
			"ding":
				play("click", 0.0, 1.3 + 0.1 * e.lit)
			"gear": # Gearbox shifting up, a little higher each gear.
				play("clunk", -3.0, 0.8 + 0.15 * e.gear)
			"dig":
				play("dig")
			"clod":
				play("hit", -6.0, 0.7)
			# Batch H set pieces reuse existing sounds at their own pitch.
			"piece":
				if e.kind == "vine": # Ivy's vine sprouting: grassy.
					play("rustle", -2.0, 1.3)
				elif e.kind == "seed": # Sprout's sapling popping up.
					play("rustle", -3.0, 1.6)
				elif e.kind == "root":
					pass # Old Oak's root already creaks.
				elif e.kind == "ice": # Glacia's pillars rising.
					play("snowflake", -2.0, 0.8)
				elif e.kind != "illusion":
					play("wall", -3.0, 0.7)
			"piece_break":
				play("crunch", -2.0, 0.7)
			"rays":
				if e.kind == "shard": # Glacia's ice shards.
					play("shatter", -3.0, 1.3)
				else:
					play("zap", -2.0, 1.4 if e.kind == "disco" else 1.15)
			"lash": # Ivy's vine: a leafy rustle and a whip.
				play("rustle", 0.0, 1.1)
				play("snap", -6.0, 0.9)
			"root": # Old Oak taking root: creaking wood and a heavy thud.
				play("rustle", 0.0, 0.6)
				play("thwomp", -3.0, 0.8)
			"rewind":
				play("ticktock", 0.0, 1.3)
				play("flip", -4.0, 0.7)
			"illusions", "swap":
				play("flip", 0.0, 1.3)
			"spin":
				play("crit", 0.0, 1.3 if e.prizes.size() > 1 else 1.1)
			"boon": # A Bounce Run boon going off.
				match e.id:
					"pinball":
						play("thwomp", -2.0, 1.3)
					"payback":
						play("snap", -2.0, 0.9)
					"zap_collar":
						play("crackle", -2.0, 1.5)
					"second_wind":
						play("shield_up", 0.0, 1.1)
					"fever":
						play("t5_shine", -2.0, 0.8)
			"overcharge": # An Overcharge charm's boosted hit.
				play("crackle", -3.0, 1.3)
			"spawn": # A boss's minion joining in.
				play("summon_pop", -4.0, 0.8)
			# Boss set pieces.
			"boss_windup": # A boss winding up a big move: a rising suck.
				play("void_suck", -4.0, 1.2)
			"glitch_warp", "glitch_phase":
				play("warp_8bit", 0.0, 0.8 if e.type == "glitch_phase" else 1.0)
			"egg_lay":
				play("summon_land", 0.0, 0.8)
			"egg_crack":
				play("candy_clack", 0.0, 0.7)
			"egg_hatch":
				play("summon_pop", 0.0, 0.7)
			"wyrm_shine":
				play("twinkle", -4.0, 0.8)
			"boss_fizzle":
				play("snuff")
			"end":
				if e.reason != "time_limit":
					play("ko")
					play("ko_final")
					for ball in sim.balls: # The loser's voice, long and low, as it pops.
						if not ball.alive() and ball.def.get("ouch", "") != "":
							play(ball.def.ouch, 2.0, ball.def.voice_pitch * 0.7)
							break
	if not _was_overtime and sim.in_overtime():
		_was_overtime = true
		_tick_in = 0.0
		play("overtime")
		play_music("overtime")
	if _was_overtime and not sim.finished:
		# A clock ticking faster and faster the longer overtime runs.
		_tick_in -= SIM_DT
		if _tick_in <= 0.0:
			play("ot_tick", 0.0, 1.0 + minf(0.4, (sim.time() - sim.overtime_start) * 0.02))
			_tick_in = maxf(0.3, 1.0 - (sim.time() - sim.overtime_start) * 0.03)


## The ball an event belongs to: a beam's owner, a hit's source, the ball it
## names, or (heals and shields) its target. Null when there is none.
func _owner(e: Dictionary, sim):
	for key in ["owner", "source", "ball", "target"]:
		var i: int = e.get(key, -1)
		if i >= 0 and i < sim.balls.size():
			return sim.balls[i]
	return null


## The owner critter's own cues for this event (CRITTER_CUES), or null.
func _critter_cues(e: Dictionary, owner):
	if owner == null or not CRITTER_CUES.has(owner.type_id):
		return null
	var table: Dictionary = CRITTER_CUES[owner.type_id]
	if e.has("kind") and table.has("%s:%s" % [e.type, e.kind]):
		return table["%s:%s" % [e.type, e.kind]]
	return table.get(e.type, null)


## A ball's speed over its base speed, 0 at base up to 1 at double.
## The wall sound for arena `id`: its themed art's material, plain neon glass
## for maps without one (boss maps). Loaded here, not preloaded, so the art
## painters don't load with this autoload.
static func wall_sound(id: String) -> String:
	var fam: String = load("res://game/arena_art.gd").family(id)
	return "wallhit_" + fam if RULES.has("wallhit_" + fam) else "wallhit_classics"


## A ball bouncing off the arena's edge or a pillar: the arena's wall material,
## louder and brighter the more head-on and fast it hit, lower for big balls.
## Bumpers ding on their own; critter-made pieces keep the plain glass ting.
func _wall_hit(e: Dictionary, sim) -> void:
	if e.ball >= sim.balls.size():
		return
	var ball = sim.balls[e.ball]
	for o in sim.obstacles():
		if e.pos.distance_to(o.pos) <= float(o.radius) + 4.0:
			if o.has("piece"):
				play("wall", 0.0, 0.85 + _rng.randf() * 0.15)
			if o.has("piece") or o.kind == "bumper":
				return
	var n: Vector2 = (ball.pos - e.pos).normalized()
	var hit: float = absf(ball.vel.dot(n)) / maxf(1.0, float(ball.def.get("speed", 300.0)))
	var k := clampf((hit - 0.3) / 1.4, 0.0, 1.0)
	play(_wall_sound, lerpf(-7.0, 0.0, k), clampf(64.0 / ball.radius, 0.8, 1.25) * (0.92 + 0.16 * k))


func _speed_share(ball) -> float:
	if ball == null or ball.def.get("speed", 0.0) <= 0.0:
		return 0.0
	return clampf(ball.vel.length() / ball.def.speed - 1.0, 0.0, 1.0)


## Floor zones that just appeared (Fuse's mines, Honey's drips): their
## critter's "zone:<kind>" cue, once each.
func _zone_cues(sim) -> void:
	var seen := {}
	for z in sim.zones:
		var id: int = z.get_instance_id()
		seen[id] = true
		if _zones_heard.has(id) or z.owner < 0 or z.owner >= sim.balls.size():
			continue
		var cues = _critter_cues({"type": "zone:" + z.kind}, sim.balls[z.owner])
		if cues != null:
			for c in cues:
				play(c[0], c[1], c[2])
	_zones_heard = seen


## Plays a sound (any variant) unless its cap or min gap says to skip it.
func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if mode == "off" or not RULES.has(name) or _variants[name].is_empty():
		return
	var rule: Array = RULES[name]
	if _clock - float(_last_start.get(name, -1000.0)) < rule[1]:
		return
	var ends: Array = _ends.get(name, []).filter(func(t): return t > _clock)
	if ends.size() >= rule[0]:
		return
	var options: Array = _variants[name]
	var stream: AudioStream = options[_rng.randi() % options.size()]
	pitch *= _rng.randf_range(0.95, 1.05)
	ends.append(_clock + stream.get_length() / pitch)
	_ends[name] = ends
	_last_start[name] = _clock
	var db: float = rule[2] + volume_db + _rng.randf_range(-1.5, 1.5)
	if record != null:
		record.append([name, stream.resource_path, db + MASTER_DB, pitch, _clock])
		return
	_start(stream, db, pitch)


## How many copies of a sound are playing now, by our own bookkeeping.
func playing_count(name: String) -> int:
	return _ends.get(name, []).filter(func(t): return t > _clock).size()


func play_music(track: String) -> void:
	if _music_track == track and (_music.playing or mode != "all"):
		return
	if track != "menu":
		_save_menu_pos(false)
	_music_track = track
	if mode != "all":
		_stop_music()
		return
	if not _audio_unlocked:
		return # Starts on the first tap (_input).
	_start_music(track)


## Remembers where the menu loop is before it stops. running: the music should
## count on through a scene load; otherwise (a fight) it waits where it was.
func _save_menu_pos(running: bool) -> void:
	if _music_track == "menu" and _music != null and _music.playing:
		_menu_pos = _music.get_playback_position()
		_menu_left_at = Time.get_ticks_msec() / 1000.0 if running else -1.0
	elif not running and _menu_left_at >= 0.0: # A fight scene opened straight after a scene change.
		_menu_pos += Time.get_ticks_msec() / 1000.0 - _menu_left_at
		_menu_left_at = -1.0


## Where the menu loop picks up, in seconds into a loop `length` long.
static func _menu_resume(now: float, length: float) -> float:
	var at := _menu_pos + (now - _menu_left_at if _menu_left_at >= 0.0 else 0.0)
	return fmod(at, length) if length > 0.0 else 0.0


func _start_music(track: String) -> void:
	var info: Array = MUSIC[track]
	var stream = load(AUDIO_DIR + info[0] + ".ogg")
	if stream == null or not is_inside_tree():
		return
	stream.loop = info[2]
	stream.loop_offset = VICTORY_LOOP_FROM if track == "victory" else 0.0
	if _fade:
		_fade.kill()
	_music_out.stop()
	if _music.playing: # Fade the old track out on the spare player.
		var old := _music
		_music = _music_out
		_music_out = old
		_fade = create_tween()
		_fade.tween_property(old, "volume_db", old.volume_db - 40.0, MUSIC_FADE)
		_fade.tween_callback(old.stop)
	_music.stream = stream
	_music.volume_db = info[1] + MASTER_DB
	_music.play(_menu_resume(Time.get_ticks_msec() / 1000.0, stream.get_length()) if track == "menu" else 0.0)


func _stop_music() -> void:
	if _fade:
		_fade.kill()
	_music.stop()
	_music_out.stop()


func sound_names() -> Array:
	return RULES.keys()


# --- Internals ----------------------------------------------------------------

func _start(stream: AudioStream, volume_db: float, pitch: float) -> void:
	if not is_inside_tree():
		return
	var player := _free_player()
	player.stream = stream
	player.volume_db = volume_db + MASTER_DB
	player.pitch_scale = pitch
	player.play()


func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	# All busy: steal the one that has played longest.
	var oldest := _players[0]
	for p in _players:
		if p.get_playback_position() > oldest.get_playback_position():
			oldest = p
	oldest.stop()
	return oldest


func _load_variants(name: String) -> Array:
	var out := []
	var single := AUDIO_DIR + name + ".wav"
	if ResourceLoader.exists(single):
		out.append(load(single))
	var i := 0
	while ResourceLoader.exists("%s%s_%d.wav" % [AUDIO_DIR, name, i]):
		out.append(load("%s%s_%d.wav" % [AUDIO_DIR, name, i]))
		i += 1
	return out


func _apply_mode() -> void:
	# Everything plays on the Master bus: Godot 4.3's web build loses the route
	# to the speakers when buses are added at runtime, so the game goes silent.
	# Muting is done by not starting sounds instead.
	if mode == "off":
		for p in _players:
			p.stop()
	if mode == "all" and _music_track != "" and not _music.playing:
		var track := _music_track
		_music_track = ""
		play_music(track)
	elif mode != "all":
		_stop_music()
	if _toggle:
		_toggle.text = MODE_LABELS[mode]


## Next sound mode: all, effects only, off. Saved for next time.
func cycle_mode() -> void:
	mode = MODES[(MODES.find(mode) + 1) % MODES.size()]
	_apply_mode()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "mode", mode)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved: String = cfg.get_value("audio", "mode", "all")
		if saved in MODES:
			mode = saved
	_apply_mode()


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("silent"):
		node.pressed.connect(func(): play("click"))


# --- UI: mute toggle and sound board -------------------------------------------

func _build_toggle() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	# A small ghost pill in the kit's style, in the bottom-right corner.
	_toggle = Kit.button(MODE_LABELS[mode], func(): cycle_mode(); play("click"), "ghost", 20, TOGGLE_SIZE.y)
	_toggle.text = MODE_LABELS[mode]
	_toggle.set_meta("silent", true)
	_toggle.clip_text = true
	_toggle.add_theme_font_override("font", Kit.FONT)
	layer.add_child(_toggle)
	get_viewport().size_changed.connect(_place_toggle)
	_place_toggle()


func _place_toggle() -> void:
	var size := get_viewport().get_visible_rect().size
	_toggle.size = TOGGLE_SIZE
	_toggle.position = FightLayout.pill_position(size, 1) # Right of a fight's Speed and Skip pills.
	if _board:
		_board.size = size


## A page of every sound with a play button, for judging sounds on a phone.
## Opened with ?sounds=1 on the web build.
func show_board() -> void:
	if _board:
		_board.visible = true
		return
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_board = Panel.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.06, 0.1, 0.97)
	_board.add_theme_stylebox_override("panel", bg)
	layer.add_child(_board)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20
	scroll.offset_top = 20
	scroll.offset_right = -20
	scroll.offset_bottom = -90
	_board.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	var title := Label.new()
	title.text = "Sound board"
	title.add_theme_font_size_override("font_size", 34)
	grid.add_child(title)
	grid.add_child(Control.new())
	for track in MUSIC:
		grid.add_child(_board_button("Music: " + track, func(): _music_track = track; _start_music(track)))
	for name in RULES:
		for i in _variants[name].size():
			var label: String = name if _variants[name].size() == 1 else "%s %d" % [name, i + 1]
			grid.add_child(_board_button(label, _play_exact.bind(name, i)))
	var close := _board_button("Close", func(): _board.visible = false)
	close.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	close.offset_top = -80
	close.offset_bottom = -12
	close.offset_left = 20
	close.offset_right = -200
	_board.add_child(close)
	_place_toggle()


func _board_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.set_meta("silent", true)
	b.text = text
	b.custom_minimum_size = Vector2(0, 72)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(on_press)
	return b


func _play_exact(name: String, index: int) -> void:
	if mode == "off":
		mode = "sfx"
		_apply_mode()
	_start(_variants[name][index], RULES[name][2], 1.0)
