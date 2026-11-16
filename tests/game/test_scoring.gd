extends GutTest
## Scoring: the combo's window, its multiplier and its cap, the points of a merge and the record.


func test_a_merge_inside_the_window_raises_the_combo() -> void:
	assert_eq(Scoring.next_combo(1, 0.4), 2)
	assert_eq(Scoring.next_combo(4, Scoring.COMBO_WINDOW - 0.01), 5)


func test_a_merge_outside_the_window_starts_again_at_one() -> void:
	assert_eq(Scoring.next_combo(5, Scoring.COMBO_WINDOW), 1)
	assert_eq(Scoring.next_combo(5, 3.0), 1)
	assert_eq(Scoring.next_combo(0, INF), 1)


func test_the_multiplier_grows_a_quarter_per_merge_up_to_three() -> void:
	assert_eq(Scoring.multiplier(1), 1.0)
	assert_eq(Scoring.multiplier(2), 1.25)
	assert_eq(Scoring.multiplier(5), 2.0)
	assert_eq(Scoring.multiplier(9), 3.0)
	assert_eq(Scoring.multiplier(50), 3.0)


func test_points_are_the_base_times_the_multiplier_rounded() -> void:
	assert_eq(Scoring.points(10, 1), 10)
	assert_eq(Scoring.points(10, 2), 13)
	assert_eq(Scoring.points(30, 3), 45)
	assert_eq(Scoring.points(500, 99), 1500)


func test_record_is_true_only_when_beaten_and_raises_the_profile() -> void:
	var profile := Profile.new()
	profile.best_score = 100
	assert_false(Scoring.record(profile, 100))
	assert_false(Scoring.record(profile, 40))
	assert_eq(profile.best_score, 100)
	assert_true(Scoring.record(profile, 101))
	assert_eq(profile.best_score, 101)
