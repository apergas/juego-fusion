class_name GameState extends RefCounted
## Everything one round keeps; Game makes a new one for each round. Pure: no nodes.

var rng := RandomNumberGenerator.new()
## Seconds of this round (Game counts them on the physics frame).
var elapsed := 0.0


## A seed of 0 or more makes the round repeatable (--seed=<n>); -1 picks one at random.
func _init(seed_value := -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
