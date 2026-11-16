extends GutTest
## SaveData: the profile and the options through JSON and back, what it refuses and that a
## refused save changes nothing. No file is touched here.

const Fixtures := preload("res://tests/fixtures.gd")

## A save edited by hand, or broken: [what changes, its new value]. Each is refused.
const BROKEN := [
	["version", 3.0], ["version", 0.0], ["version", "1"], ["best_score", -1.0],
	["best_score", 12.5], ["best_score", "mucho"], ["discovered", "gota"],
	["discovered", ["quimera"]], ["discovered", ["gota", "gota"]], ["discovered", [3.0]],
	["round", []], ["round", "tarro"], ["options", []], ["options", "alto"]]


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
	for key in ["version", "best_score", "discovered", "options", "round"]:
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


## A save as 0.1.0 wrote it: version 1, no round.
func _version_1() -> Dictionary:
	var data := _saved()
	data.erase("round")
	data.version = 1.0
	return data


func test_a_version_1_save_loads_without_a_round() -> void:
	var data := _version_1()
	assert_true(SaveData.is_valid(data))
	var profile := Profile.new()
	profile.saved_round = Fixtures.kept_round()
	var options := GameOptions.new()
	assert_true(SaveData.apply(data, profile, options))
	assert_eq(profile.best_score, 1234)
	assert_eq(Array(profile.discovered), ["gota", "slime_verde", "seta"])
	assert_true(profile.saved_round.is_empty())
	assert_eq(int(SaveData.migrated(data).version), SaveData.VERSION)


func test_a_version_1_save_with_a_round_is_refused() -> void:
	var data := _version_1()
	data["round"] = Fixtures.kept_round()
	assert_false(SaveData.is_valid(data))


func test_a_kept_round_goes_through_json_and_back() -> void:
	var profile := _profile()
	profile.saved_round = Fixtures.kept_round()
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveData.from(profile, _options())))
	assert_true(SaveData.is_valid(data))
	var back := Profile.new()
	assert_true(SaveData.apply(data, back, GameOptions.new()))
	assert_eq(JSON.stringify(RoundSnapshot.normalized(back.saved_round)),
		JSON.stringify(RoundSnapshot.normalized(profile.saved_round)))


func test_a_broken_round_refuses_the_whole_save_and_changes_nothing() -> void:
	var source := _profile()
	var broken := Fixtures.kept_round()
	broken.score = -5.0
	source.saved_round = broken
	var data: Dictionary = JSON.parse_string(JSON.stringify(SaveData.from(source, _options())))
	assert_false(SaveData.is_valid(data))
	var profile := _profile()
	var options := _options()
	assert_false(SaveData.apply(data, profile, options))
	assert_eq(profile.best_score, 1234)
	assert_true(profile.saved_round.is_empty())
	assert_eq_deep(options.to_dict(), _options().to_dict())
