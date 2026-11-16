extends GutTest
## JarSpec: a creature stays inside the walls, the camera fits any phone and heavier means bigger.


func test_a_creature_never_leaves_the_jar() -> void:
	for level in range(1, Chain.MAX_LEVEL + 1):
		var radius := Chain.data(level).radius
		var limit := JarSpec.WIDTH / 2.0 - radius
		assert_eq(JarSpec.clamp_x(-99.0, radius), -limit)
		assert_eq(JarSpec.clamp_x(99.0, radius), limit)
		assert_eq(JarSpec.clamp_x(0.0, radius), 0.0)


func test_a_creature_already_inside_does_not_move() -> void:
	assert_eq(JarSpec.clamp_x(1.0, 0.3), 1.0)


func test_the_camera_shows_at_least_the_minimum_and_grows_for_narrow_screens() -> void:
	assert_eq(JarSpec.camera_size(0.5), JarSpec.VIEW_WIDTH / 0.5)
	assert_eq(JarSpec.camera_size(2.0), JarSpec.VIEW_HEIGHT)
	assert_gt(JarSpec.camera_size(0.4), JarSpec.camera_size(0.5))
	for aspect in [0.3, 0.45, 0.56, 1.0, 1.78]:
		assert_gte(JarSpec.camera_size(aspect), JarSpec.VIEW_HEIGHT)
		assert_gte(JarSpec.camera_size(aspect) * aspect, JarSpec.VIEW_WIDTH - 0.0001)


func test_the_mass_grows_with_the_radius_and_the_gota_weighs_one() -> void:
	assert_almost_eq(JarSpec.mass(JarSpec.MASS_RADIUS), 1.0, 0.0001)
	for level in range(2, Chain.MAX_LEVEL + 1):
		assert_gt(JarSpec.mass(Chain.data(level).radius), JarSpec.mass(Chain.data(level - 1).radius))
