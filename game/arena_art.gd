## Themed arena art (the arena art pass Newms approved on 2026-10-22, design
## in /mnt/project-files/design/arenas.md §8): every map belongs to a family
## with its own floor material, wall band, pillars and props. ArenaView
## paints all of it once into a texture (see _bake in game/arena_view.gd), so
## however detailed the art is, a frame costs a single textured quad, plus
## one quad per pillar or bumper sprite. Maps with no family keep the plain
## neon look. Render-only: the sim never reads any of this.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Candy := preload("res://game/arena_art/candy.gd")
const Temple := preload("res://game/arena_art/temple.gd")
const Space := preload("res://game/arena_art/space.gd")
const Ocean := preload("res://game/arena_art/ocean.gd")
const SkyArt := preload("res://game/arena_art/sky.gd")
const Ice := preload("res://game/arena_art/ice.gd")
const Volcano := preload("res://game/arena_art/volcano.gd")
const Synth := preload("res://game/arena_art/synth.gd")
const Desert := preload("res://game/arena_art/desert.gd")
const Haunted := preload("res://game/arena_art/haunted.gd")
const Toybox := preload("res://game/arena_art/toybox.gd")
const Classics := preload("res://game/arena_art/classics.gd")

## Map id -> family.
const FAMILIES := {
	"candy": "candy", "syrup": "candy", "hive": "candy",
	"temple": "temple", "ruins": "temple", "thorn": "temple",
	"nebula": "space", "asteroid": "space", "wells": "space", "horizon": "space", "orbit": "space", "starfall": "space",
	"kelp": "ocean", "trench": "ocean", "reef": "ocean",
	"cloud": "sky", "storm": "sky", "windmill": "sky",
	"frost": "ice", "prism": "ice",
	"magma": "volcano", "inferno": "volcano",
	"sunset": "synth", "alley": "synth", "glitch": "synth",
	"dunes": "desert", "oasis": "desert",
	"graveyard": "haunted", "manor": "haunted", "arcane": "haunted",
	"toybox": "toybox", "speedway": "toybox", "cogs": "toybox", "pinball": "toybox", "bumpers": "toybox", "arcade": "toybox",
	"square": "classics", "rink": "classics", "pillars": "classics", "spikes": "classics", "factory": "classics", "pistons": "classics",
}

## Sprites stand this many radii out from their centre (shadows, leaves).
const SPRITE_EXTENT := 1.7
const WALL := 30.0 ## Wall band thickness in arena units.


## Families with their own bumper look.
const BUMPER_FAMILIES := ["candy", "toybox"]


static func has_bumper(id: String) -> bool:
	return family(id) in BUMPER_FAMILIES


static func family(id: String) -> String:
	return FAMILIES.get(id, "")


## The painter's view of map `id` at `s` pixels per arena unit, with a
## frame `margin` pixels wide round the square.
static func make_ctx(id: String, s: float, margin: float) -> Kit.Ctx:
	var shape := MatchSim.new({"arena": id})
	var ctx := Kit.Ctx.new()
	ctx.id = id
	ctx.s = s
	ctx.full = Rect2(Vector2.ZERO, Vector2.ONE * MatchSim.ARENA_SIZE * s)
	ctx.canvas = ctx.full.grow(margin)
	ctx.centre = shape.centre * s
	ctx.wall = minf(WALL * s, margin * 0.85)
	ctx.rng.seed = hash("arena art " + id)
	for p in shape.arena_outline():
		ctx.outline.append(p * s)
	for o in shape.obstacles():
		if o.has("vel"):
			continue # Moving parts aren't painted into the static floor.
		ctx.obstacles.append({"pos": o.pos * s, "radius": o.radius * s, "kind": o.kind})
	for f in shape.floors():
		var g: Dictionary = {"kind": f.kind}
		if f.has("rect"):
			g.rect = Rect2(f.rect.position * s, f.rect.size * s)
		else:
			g.pos = f.pos * s
			g.radius = f.radius * s
		ctx.floors.append(g)
	return ctx


## How much each bright floor is dimmed so balls, aim dots and effects stay
## readable (Newms 2026-10-22: effects and the aim line got lost on light
## floors). Tuned so every floor's middle sits near the same mid-dark level;
## maps not listed are dark already.
const DIM := {
	"rink": 0.57, "bumpers": 0.56, "square": 0.55, "frost": 0.53, "candy": 0.52, "syrup": 0.52,
	"prism": 0.51, "kelp": 0.5, "cloud": 0.49, "reef": 0.49, "hive": 0.48, "oasis": 0.48,
	"dunes": 0.46, "toybox": 0.46, "ruins": 0.39, "thorn": 0.39, "temple": 0.39, "trench": 0.33,
	"pillars": 0.29, "spikes": 0.29, "factory": 0.1,
}
const DIM_COLOR := Color("0d0b1e")


## Floor, walls and props for the whole canvas.
static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	_paint_family(cv, ctx)
	var dim: float = DIM.get(ctx.id, 0.0)
	if dim > 0.0: # Over the floor only: the wall band sits outside the outline.
		Kit.poly(cv, ctx.outline, Color(DIM_COLOR, dim))


static func _paint_family(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	match family(ctx.id):
		"candy":
			Candy.paint(cv, ctx)
		"temple":
			Temple.paint(cv, ctx)
		"space":
			Space.paint(cv, ctx)
		"ocean":
			Ocean.paint(cv, ctx)
		"sky":
			SkyArt.paint(cv, ctx)
		"ice":
			Ice.paint(cv, ctx)
		"volcano":
			Volcano.paint(cv, ctx)
		"synth":
			Synth.paint(cv, ctx)
		"desert":
			Desert.paint(cv, ctx)
		"haunted":
			Haunted.paint(cv, ctx)
		"toybox":
			Toybox.paint(cv, ctx)
		"classics":
			Classics.paint(cv, ctx)


## A pillar of radius r at c, in the family's look. False: draw the default.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> bool:
	match family(ctx.id):
		"candy":
			Candy.pillar(cv, ctx, c, r)
		"temple":
			Temple.pillar(cv, ctx, c, r)
		"space":
			Space.pillar(cv, ctx, c, r)
		"ocean":
			Ocean.pillar(cv, ctx, c, r)
		"sky":
			SkyArt.pillar(cv, ctx, c, r)
		"ice":
			Ice.pillar(cv, ctx, c, r)
		"volcano":
			Volcano.pillar(cv, ctx, c, r)
		"synth":
			Synth.pillar(cv, ctx, c, r)
		"desert":
			Desert.pillar(cv, ctx, c, r)
		"haunted":
			Haunted.pillar(cv, ctx, c, r)
		"toybox":
			Toybox.pillar(cv, ctx, c, r)
		"classics":
			Classics.pillar(cv, ctx, c, r)
		_:
			return false
	return true


## A bumper in the family's look; bumpers stay pink so they still read as
## bumpers. False: draw the default.
static func bumper(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> bool:
	match family(ctx.id):
		"candy":
			Candy.bumper(cv, ctx, c, r)
		"toybox":
			Toybox.bumper(cv, ctx, c, r)
		_:
			return false
	return true
