class_name SaveData extends RefCounted
## Turns the profile and the options into the Dictionary SaveStore writes as JSON, and back.
## Pure: no nodes, no files. VERSION 1: {"version", "best_score", "discovered", "options"}. A save
## of another version, or one a played game can't reach (a negative or broken record, an unknown
## or repeated id, no options), is not valid, and nothing of it is applied: the game starts from
## scratch. JSON reads every number as a float, so apply() converts them.

const VERSION := 1


static func from(profile: Profile, options: GameOptions) -> Dictionary:
	return {"version": VERSION, "best_score": profile.best_score,
		"discovered": profile.discovered.duplicate(), "options": options.to_dict()}


static func is_valid(data: Dictionary) -> bool:
	if not _whole(data.get("version")) or int(data.version) != VERSION:
		return false
	var best: Variant = data.get("best_score")
	if not _whole(best) or int(best) < 0:
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
	profile.best_score = int(data.best_score)
	profile.discovered.assign(data.discovered)
	var loaded := GameOptions.from_dict(data.options)
	options.sfx_volume = loaded.sfx_volume
	options.vibration = loaded.vibration
	options.high_contrast = loaded.high_contrast
	return true


## A whole number, as JSON gives it back (a float with nothing after the point) or as an int.
static func _whole(value: Variant) -> bool:
	if value is int:
		return true
	return value is float and is_equal_approx(value, roundf(value))
