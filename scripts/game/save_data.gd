class_name SaveData extends RefCounted
## Turns the profile and the options into the Dictionary SaveStore writes as JSON, and back.
## Pure: no nodes, no files. VERSION 2: {"version", "best_score", "discovered", "options",
## "round"}; "round" is the round in progress the player left (RoundSnapshot), {} for none. A
## version 1 save (0.1.0's, without "round") is read as a 2 without a round (migrated()). A save
## of another version, or one a played game can't reach (a negative or broken record, an unknown
## or repeated id, no options), is not valid, and nothing of it is applied: the
## game starts from scratch. A broken round never refuses the file: apply() drops it (with a
## warning) and the record, the bestiary and the options still load; a version 1 save's "round" is
## ignored. JSON reads every number as a float, so apply() converts them.

const VERSION := 2
## The oldest version still read: 0.1.0's.
const OLDEST := 1


static func from(profile: Profile, options: GameOptions) -> Dictionary:
	return {"version": VERSION, "best_score": profile.best_score,
		"discovered": profile.discovered.duplicate(), "options": options.to_dict(),
		"round": profile.saved_round.duplicate(true)}


static func is_valid(data: Dictionary) -> bool:
	if not whole(data.get("version")):
		return false
	var version := int(data.version)
	if version < OLDEST or version > VERSION:
		return false
	var best: Variant = data.get("best_score")
	if not whole(best) or int(best) < 0:
		return false
	var ids: Variant = data.get("discovered")
	if not ids is Array:
		return false
	var seen := {}
	for id: Variant in ids:
		if not id is String or not Chain.IDS.has(id) or seen.has(id):
			return false
		seen[id] = true
	return data.get("options") is Dictionary


## Puts a valid save into profile and options; false (and nothing changed) if it is not valid.
static func apply(data: Dictionary, profile: Profile, options: GameOptions) -> bool:
	if not is_valid(data):
		return false
	var current := migrated(data)
	profile.best_score = int(current.best_score)
	profile.discovered.assign(current.discovered)
	profile.saved_round = _kept_round(current)
	var loaded := GameOptions.from_dict(current.options)
	options.music_volume = loaded.music_volume
	options.sfx_volume = loaded.sfx_volume
	options.vibration = loaded.vibration
	options.high_contrast = loaded.high_contrast
	return true


## The round of a valid save if it is one a played game could keep; otherwise {} (and a warning
## when there was something). migrated() has already emptied a version 1 save's.
static func _kept_round(data: Dictionary) -> Dictionary:
	var kept: Variant = data.get("round")
	if kept == null or (kept is Dictionary and (kept as Dictionary).is_empty()):
		return {}
	if not kept is Dictionary or not RoundSnapshot.is_valid(kept):
		push_warning("SaveData: the kept round is not valid, it is dropped")
		return {}
	return (kept as Dictionary).duplicate(true)


## A valid save in VERSION's shape: a version 1 save gets an empty round.
static func migrated(data: Dictionary) -> Dictionary:
	var current := data.duplicate(true)
	if int(current.version) == 1:
		current["round"] = {}
	current.version = VERSION
	return current


## A whole number, as JSON gives it back (a finite float with nothing after the point) or as an
## int.
static func whole(value: Variant) -> bool:
	if value is int:
		return true
	return value is float and is_finite(value) and is_equal_approx(value, roundf(value))
