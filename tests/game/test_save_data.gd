extends GutTest
## SaveData: the profile and the options through JSON and back, what it refuses and that a
## refused save changes nothing. No file is touched here.

## A save edited by hand, or broken: [what changes, its new value]. Each is refused.
const BROKEN := [
	["version", 2.0], ["version", 0.0], ["version", "1"], ["best_score", -1.0],
	["best_score", 12.5], ["best_score", "mucho"], ["discovered", "gota"],
	["discovered", ["quimera"]], ["discovered", ["gota", "gota"]], ["discovered", [3.0]],
	["options", []], ["options", "alto"]]


func _profile() -> Profile:
	var profile := Profile.new()
	profile.best_score = 1234
	profile.discovered.assign(["gota", "slime_verde", "seta"])
	return profile


func _options() -> GameOptions:
	var options := GameOptions.new()
	options.sfx_volume = 0.25
	options.vibration = false
	options.high_contrast = true
	return options


## What the file gives back: JSON reads every number as a float.
func _saved() -> Dictionary:
	return JSON.parse_string(JSON.stringify(SaveData.from(_profile(), _options())))


func test_a_played_game_goes_through_json_and_back() -> void:
	var data := _saved()
	assert_true(SaveData.is_valid(data))
	var profile := Profile.new()
	var options := GameOptions.new()
	assert_true(SaveData.apply(data, profile, options))
	assert_eq(profile.best_score, 1234)
	assert_eq(Array(profile.discovered), ["gota", "slime_verde", "seta"])
	assert_eq_deep(options.to_dict(), _options().to_dict())


func test_a_new_game_is_a_valid_save() -> void:
	assert_true(SaveData.is_valid(SaveData.from(Profile.new(), GameOptions.new())))


func test_what_a_played_game_cannot_reach_is_refused() -> void:
	for change: Array in BROKEN:
		var data := _saved()
		data[change[0]] = change[1]
		assert_false(SaveData.is_valid(data), "%s = %s" % [change[0], change[1]])


func test_a_save_missing_a_field_is_refused() -> void:
	for key in ["version", "best_score", "discovered", "options"]:
		var data := _saved()
		data.erase(key)
		assert_false(SaveData.is_valid(data), "without %s" % key)


func test_a_refused_save_changes_nothing() -> void:
	var data := _saved()
	data.discovered = ["quimera"]
	var profile := _profile()
	var options := _options()
	assert_false(SaveData.apply(data, profile, options))
	assert_eq(profile.best_score, 1234)
	assert_eq(profile.discovered.size(), 3)
	assert_eq_deep(options.to_dict(), _options().to_dict())
