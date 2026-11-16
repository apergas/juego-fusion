extends GutTest
## Danger: when a creature is over the line, how the count goes up and back to zero, when the
## round is lost and how fast the line blinks.


func test_over_means_strictly_above_the_line() -> void:
	assert_true(Danger.is_over(JarSpec.LINE_Y + 0.01))
	assert_false(Danger.is_over(JarSpec.LINE_Y))
	assert_false(Danger.is_over(-INF))


func test_the_count_adds_while_over_and_goes_back_to_zero_when_not() -> void:
	var count := Danger.step(0.0, true, 0.5)
	count = Danger.step(count, true, 0.5)
	assert_eq(count, 1.0)
	assert_eq(Danger.step(count, false, 0.5), 0.0)


func test_the_round_is_lost_after_lose_time_in_a_row() -> void:
	assert_false(Danger.lost(Danger.LOSE_TIME - 0.01))
	assert_true(Danger.lost(Danger.LOSE_TIME))
	assert_true(Danger.lost(Danger.LOSE_TIME + 1.0))


func test_fraction_goes_from_zero_to_one_and_stays() -> void:
	assert_eq(Danger.fraction(0.0), 0.0)
	assert_eq(Danger.fraction(Danger.LOSE_TIME / 2.0), 0.5)
	assert_eq(Danger.fraction(Danger.LOSE_TIME), 1.0)
	assert_eq(Danger.fraction(99.0), 1.0)
	assert_eq(Danger.fraction(-1.0), 0.0)


func test_the_line_blinks_faster_as_time_runs_out() -> void:
	assert_eq(Danger.blink_hz(0.0), Danger.BLINK_SLOW)
	assert_eq(Danger.blink_hz(1.0), Danger.BLINK_FAST)
	assert_gt(Danger.blink_hz(0.6), Danger.blink_hz(0.3))
	assert_between(Danger.blink_hz(0.5), Danger.BLINK_SLOW, Danger.BLINK_FAST)
