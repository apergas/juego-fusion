extends GutTest
## Chain: the order and the data of the eight links, what a merge makes, its points and its
## vibration.


func test_the_chain_has_eight_links_in_order() -> void:
	assert_eq(Chain.IDS.size(), Chain.MAX_LEVEL)
	assert_eq(Chain.IDS[0], "gota")
	assert_eq(Chain.IDS[Chain.MAX_LEVEL - 1], "dragon")


func test_levels_and_radii_grow_along_the_chain() -> void:
	for level in range(2, Chain.MAX_LEVEL + 1):
		assert_eq(Chain.data(level).level, level)
		assert_gt(Chain.data(level).radius, Chain.data(level - 1).radius)


func test_by_id_finds_every_link_and_nothing_else() -> void:
	for i in Chain.IDS.size():
		assert_eq(Chain.by_id(Chain.IDS[i]), Chain.data(i + 1))
	assert_null(Chain.by_id("quimera"))
	assert_push_error("unknown creature id")


func test_two_equal_creatures_make_the_next_and_the_last_vanish() -> void:
	for level in range(1, Chain.MAX_LEVEL):
		assert_eq(Chain.next_level(level), level + 1)
	assert_eq(Chain.next_level(Chain.MAX_LEVEL), 0)


func test_merge_points_follow_the_table() -> void:
	var expected := [10, 30, 60, 100, 150, 210, 280]
	for level in range(1, Chain.MAX_LEVEL):
		assert_eq(Chain.merge_points(level), expected[level - 1])
	assert_eq(Chain.merge_points(Chain.MAX_LEVEL), 500)
	assert_eq(Chain.TOP_PAIR_POINTS, 500)


func test_vibration_grows_with_the_level_made() -> void:
	for level in range(2, Chain.MAX_LEVEL + 1):
		assert_gt(Chain.vibration_ms(level), Chain.vibration_ms(level - 1))
	assert_eq(Chain.vibration_ms(0), Chain.VIBRATION_BASE_MS)
