class_name Spawner extends RefCounted
## What falls into the jar: creatures 1 to 4 of the chain at random, the bigger ones less often
## (WEIGHTS). Pure: works on a GameState with its seeded generator. After a drop the next
## creature waits DROP_WAIT seconds before it appears at the top (Game counts them).

const WEIGHTS: Array[int] = [4, 3, 2, 1]
const DROP_WAIT := 0.5


## A level from 1 to WEIGHTS.size(), each as likely as its weight.
static func pick(rng: RandomNumberGenerator) -> int:
	var total := 0
	for weight in WEIGHTS:
		total += weight
	var roll := rng.randi_range(1, total)
	for i in WEIGHTS.size():
		roll -= WEIGHTS[i]
		if roll <= 0:
			return i + 1
	return 1


## The first creature of a round and the one after it.
static func start(state: GameState) -> void:
	state.current = pick(state.rng)
	state.next = pick(state.rng)


## After a drop: the next one waits, and a new next is picked.
static func advance(state: GameState) -> void:
	state.current = state.next
	state.next = pick(state.rng)
