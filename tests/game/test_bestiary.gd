extends GutTest
## Bestiary: a creature is discovered once, and the profile remembers it.


func test_a_creature_is_discovered_the_first_time_only() -> void:
	var profile := Profile.new()
	assert_false(Bestiary.is_discovered(profile, "gota"))
	assert_true(Bestiary.discover(profile, "gota"))
	assert_false(Bestiary.discover(profile, "gota"))
	assert_true(Bestiary.is_discovered(profile, "gota"))
	assert_eq(profile.discovered.size(), 1)


func test_the_ones_not_found_stay_unknown_in_the_order_found() -> void:
	var profile := Profile.new()
	Bestiary.discover(profile, "seta")
	Bestiary.discover(profile, "gota")
	assert_false(Bestiary.is_discovered(profile, "lobo"))
	assert_eq(Array(profile.discovered), ["seta", "gota"])
