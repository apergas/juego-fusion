class_name Scoring extends RefCounted
## Points, combos and the record. Pure: no nodes; Game owns the combo's clock (GameState
## .since_merge) and asks here. A merge less than COMBO_WINDOW seconds after the one before
## raises the combo; any other starts it again at 1. The points of a merge (Chain.merge_points())
## are multiplied by 1 + COMBO_STEP × (combo − 1), up to COMBO_MAX.

const COMBO_WINDOW := 1.0
const COMBO_STEP := 0.25
const COMBO_MAX := 3.0


## The combo after a merge that comes since seconds after the one before.
static func next_combo(combo: int, since: float) -> int:
	return combo + 1 if since < COMBO_WINDOW else 1


static func multiplier(combo: int) -> float:
	return minf(1.0 + COMBO_STEP * (combo - 1), COMBO_MAX)


static func points(base: int, combo: int) -> int:
	return roundi(base * multiplier(combo))


## The end of a round: true (and the profile's record raised) if score beats it.
static func record(profile: Profile, score: int) -> bool:
	if score <= profile.best_score:
		return false
	profile.best_score = score
	return true
