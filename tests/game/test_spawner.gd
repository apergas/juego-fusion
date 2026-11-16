extends GutTest
## Spawner: what falls is a level from 1 to 4, the small ones more often, and the same seed gives
## the same round.


func test_pick_stays_in_bounds_and_every_level_appears() -> void:
	var seen := {}
	for seed_value in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var level := Spawner.pick(rng)
		assert_between(level, 1, Spawner.WEIGHTS.size())
		seen[level] = true
	for level in range(1, Spawner.WEIGHTS.size() + 1):
		assert_true(seen.has(level), "level %d never picked" % level)


func test_smaller_creatures_fall_more_often() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var counts := {1: 0, 2: 0, 3: 0, 4: 0}
	for i in 4000:
		counts[Spawner.pick(rng)] += 1
	assert_gt(counts[1], counts[2])
	assert_gt(counts[2], counts[3])
	assert_gt(counts[3], counts[4])


func test_start_fills_current_and_next() -> void:
	var state := GameState.new(3)
	state.current = 0
	state.next = 0
	Spawner.start(state)
	assert_between(state.current, 1, Spawner.WEIGHTS.size())
	assert_between(state.next, 1, Spawner.WEIGHTS.size())


func test_advance_moves_next_to_current() -> void:
	var state := GameState.new(5)
	Spawner.start(state)
	var waiting := state.next
	Spawner.advance(state)
	assert_eq(state.current, waiting)
	assert_between(state.next, 1, Spawner.WEIGHTS.size())


func test_the_same_seed_gives_the_same_sequence() -> void:
	var a := GameState.new(42)
	var b := GameState.new(42)
	Spawner.start(a)
	Spawner.start(b)
	for i in 20:
		assert_eq(a.current, b.current)
		assert_eq(a.next, b.next)
		Spawner.advance(a)
		Spawner.advance(b)
