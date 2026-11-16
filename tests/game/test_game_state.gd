extends GutTest
## GameState: the time a round shows and how a round starts. Profile: what a new player has.


func test_time_text_shows_minutes_and_seconds() -> void:
	assert_eq(GameState.time_text(0.0), "0 min 0 s")
	assert_eq(GameState.time_text(59.9), "0 min 59 s")
	assert_eq(GameState.time_text(60.0), "1 min 0 s")
	assert_eq(GameState.time_text(190.4), "3 min 10 s")


func test_a_new_round_starts_empty() -> void:
	var state := GameState.new(1)
	assert_eq(state.score, 0)
	assert_eq(state.combo, 0)
	assert_false(state.over)
	assert_false(state.can_drop)


func test_a_new_profile_has_no_record_and_no_creatures() -> void:
	var profile := Profile.new()
	assert_eq(profile.best_score, 0)
	assert_eq(profile.discovered.size(), 0)
