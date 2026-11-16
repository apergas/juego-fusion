extends GutTest
## GameOptions: the options through a Dictionary and back, and what a file that lacks or breaks
## a value brings back. No file is read or written here.


func test_the_options_go_to_a_dictionary_and_back() -> void:
	var options := GameOptions.new()
	options.music_volume = 0.4
	options.sfx_volume = 0.3
	options.vibration = false
	options.high_contrast = true
	var back := GameOptions.from_dict(JSON.parse_string(JSON.stringify(options.to_dict())))
	assert_eq_deep(back.to_dict(), options.to_dict())


func test_what_is_missing_keeps_its_default() -> void:
	assert_eq_deep(GameOptions.from_dict({}).to_dict(), GameOptions.new().to_dict())


func test_values_of_the_wrong_type_keep_their_default() -> void:
	var options := GameOptions.from_dict({"music": [1], "sfx": "alto", "vibration": 1, "high_contrast": "si"})
	assert_eq_deep(options.to_dict(), GameOptions.new().to_dict())


func test_the_volume_is_brought_back_into_range() -> void:
	assert_eq(GameOptions.from_dict({"sfx": 5.0}).sfx_volume, 1.0)
	assert_eq(GameOptions.from_dict({"sfx": -1}).sfx_volume, 0.0)
	assert_eq(GameOptions.from_dict({"sfx": 0.5}).sfx_volume, 0.5)


func test_a_save_from_before_the_music_gets_its_default() -> void:
	var options := GameOptions.from_dict({"sfx": 0.5, "vibration": false, "high_contrast": true})
	assert_eq(options.music_volume, GameOptions.DEFAULT_MUSIC)
	assert_eq(options.sfx_volume, 0.5)


func test_the_music_volume_is_brought_back_into_range() -> void:
	assert_eq(GameOptions.from_dict({"music": 3.0}).music_volume, 1.0)
	assert_eq(GameOptions.from_dict({"music": -2}).music_volume, 0.0)
	assert_eq(GameOptions.from_dict({"music": 0.3}).music_volume, 0.3)
