class_name GameState extends RefCounted
## Everything one round keeps; Game makes a new one for each round. Pure: no nodes. rng is
## Spawner's, seeded (--seed=<n>) or at random. current is the level of the creature waiting at
## the top, next the one after it («Siguiente»); can_drop is true while one waits, and wait_left
## counts Spawner.DROP_WAIT after a drop. since_merge is the combo's clock (Scoring),
## danger_time Danger's count. Game advances every clock on the physics frame.

var rng := RandomNumberGenerator.new()
var current := 1
var next := 1
var can_drop := false
var wait_left := 0.0
var score := 0
var combo := 0
var since_merge := INF
var danger_time := 0.0
## The biggest level that has been in the jar this round.
var max_level := 0
## Seconds of this round.
var elapsed := 0.0
var over := false


## A seed of 0 or more makes the round repeatable (--seed=<n>); -1 picks one at random.
func _init(seed_value := -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


## "3 min 10 s".
static func time_text(seconds: float) -> String:
	var total := floori(seconds)
	return "%d min %d s" % [floori(total / 60.0), total % 60]
