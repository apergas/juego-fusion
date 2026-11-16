class_name PowerUps extends RefCounted
## The two helps of a round. Romper takes one creature the player taps out of the jar; Cambiar
## swaps the waiting creature with «Siguiente». Pure: works on a GameState (breaks, swaps). A round
## starts with START of each (start()); Cambiar earns one every SWAP_EVERY points and Romper one
## each time the round's biggest reaches a new level from BREAK_FROM_LEVEL on (earn(), after each
## merge); neither holds more than MAX. hit() tells which creature is under the finger.

const START := 1
const MAX := 3
const SWAP_EVERY := 1000
const BREAK_FROM_LEVEL := 6


static func start(state: GameState) -> void:
	state.breaks = START
	state.swaps = START


## After a merge that raised the score from old_score and the biggest from old_max: the helps
## earned are added (capped at MAX). Returns what was really earned: {"breaks", "swaps"}.
static func earn(state: GameState, old_score: int, old_max: int) -> Dictionary:
	var swaps := floori(state.score / float(SWAP_EVERY)) - floori(old_score / float(SWAP_EVERY))
	var breaks := maxi(0, state.max_level - maxi(old_max, BREAK_FROM_LEVEL - 1))
	var had_breaks := state.breaks
	var had_swaps := state.swaps
	state.breaks = mini(MAX, state.breaks + breaks)
	state.swaps = mini(MAX, state.swaps + maxi(0, swaps))
	return {"breaks": state.breaks - had_breaks, "swaps": state.swaps - had_swaps}


## Cambiar needs a charge, «Siguiente» different from the waiting creature and a round on. It works
## during the wait after a drop too: the waiting creature is then the swapped one when it appears.
static func can_swap(state: GameState) -> bool:
	return state.swaps > 0 and not state.over and state.current != state.next


## The waiting creature and «Siguiente» change places and a charge goes; false (nothing changed)
## if Cambiar can't be used.
static func swap(state: GameState) -> bool:
	if not can_swap(state):
		return false
	var waiting := state.current
	state.current = state.next
	state.next = waiting
	state.swaps -= 1
	return true


## Romper needs a charge, a creature in the jar (creatures: how many) and a round on.
static func can_break(state: GameState, creatures: int) -> bool:
	return state.breaks > 0 and not state.over and creatures > 0


## A charge of Romper goes; false (nothing changed) without one or with the round over.
static func use_break(state: GameState) -> bool:
	if state.breaks <= 0 or state.over:
		return false
	state.breaks -= 1
	return true


## The index of the creature under point, among circles of centres and radii: of the ones point
## is inside, the one whose centre is nearest; -1 for none.
static func hit(point: Vector2, centres: Array[Vector2], radii: Array[float]) -> int:
	var best := -1
	var best_distance := INF
	for i in centres.size():
		var distance := point.distance_to(centres[i])
		if distance <= radii[i] and distance < best_distance:
			best = i
			best_distance = distance
	return best
