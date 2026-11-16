extends GutTest
## data/creatures: the eight files agree with the chain (ids, levels, radii) and each has its
## name and its line of the bestiary. Nothing loaded is changed.


func _files() -> Array:
	var names := []
	for file in DirAccess.get_files_at("res://data/creatures"):
		if file.ends_with(".tres"):
			names.append(file.get_basename())
	names.sort()
	return names


func test_there_is_one_file_per_link_of_the_chain() -> void:
	var expected := Chain.IDS.duplicate()
	expected.sort()
	assert_eq(_files().size(), 8)
	assert_eq(_files(), expected)


func test_each_file_matches_its_place_in_the_chain() -> void:
	for i in Chain.IDS.size():
		var data := Chain.data(i + 1)
		assert_not_null(data)
		assert_eq(data.id, Chain.IDS[i])
		assert_eq(data.level, i + 1)


func test_the_radii_strictly_increase() -> void:
	for level in range(2, Chain.MAX_LEVEL + 1):
		assert_gt(Chain.data(level).radius, Chain.data(level - 1).radius)
	assert_gt(Chain.data(1).radius, 0.0)


func test_every_creature_has_a_name_a_look_and_its_lore() -> void:
	for level in range(1, Chain.MAX_LEVEL + 1):
		var data := Chain.data(level)
		assert_ne(data.display_name.strip_edges(), "", data.id)
		assert_ne(data.lore.strip_edges(), "", data.id)
		assert_ne(data.look, "", data.id)
		assert_ne(data.lore, data.display_name, data.id)
