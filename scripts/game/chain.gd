class_name Chain extends RefCounted
## The chain of creatures, from the Gota de rocío (level 1) to the Dragón pequeño (level 8):
## their ids in order, their data (data/creatures/<id>.tres, loaded once and never changed),
## what a merge makes and the points it gives, and how long it vibrates. Pure: no nodes. Two of
## the last level merge into nothing: next_level() is 0 and they give TOP_PAIR_POINTS.

const IDS: Array[String] = ["gota", "slime_verde", "slime_azul", "seta", "murcielago", "lobo",
	"golem", "dragon"]
const MAX_LEVEL := 8
const PATH := "res://data/creatures/%s.tres"
## Merging into level n gives POINTS[n]: triangular numbers times ten.
const POINTS := {2: 10, 3: 30, 4: 60, 5: 100, 6: 150, 7: 210, 8: 280}
## Two of the last level together.
const TOP_PAIR_POINTS := 500
## A merge vibrates VIBRATION_BASE_MS plus VIBRATION_STEP_MS per level made.
const VIBRATION_BASE_MS := 20
const VIBRATION_STEP_MS := 5

static var _cache := {}


static func data(level: int) -> CreatureData:
	if not _cache.has(level):
		_cache[level] = load(PATH % IDS[level - 1]) as CreatureData
	return _cache[level]


## The creature with that id; null (and an error) for one the chain does not have.
static func by_id(id: String) -> CreatureData:
	var index := IDS.find(id)
	if index < 0:
		push_error("Chain: unknown creature id '%s'" % id)
		return null
	return data(index + 1)


## The level two creatures of level make; 0 for the last one (they vanish).
static func next_level(level: int) -> int:
	return level + 1 if level < MAX_LEVEL else 0


## The points (before the combo) of merging two creatures of level.
static func merge_points(level: int) -> int:
	return POINTS[level + 1] if level < MAX_LEVEL else TOP_PAIR_POINTS


## How long a merge that makes level (MAX_LEVEL for the two that vanish) vibrates.
static func vibration_ms(level: int) -> int:
	return VIBRATION_BASE_MS + VIBRATION_STEP_MS * level
