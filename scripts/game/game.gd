class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child); run on its own
## (res://scenes/game/game.tscn) it loads the save and makes its own AudioDirector. A
## coordinator: it owns the round's GameState, the current Jar (a new one each round), the game's
## clock (the round's time, the wait after a drop, the combo's clock and the danger's count, all
## on the physics frame) and the profile's record, which it saves at the end of each round. The
## Jar only reports (released, merge_found); the rules (Chain, Spawner, Scoring, Danger) decide;
## Game plays it back through the Jar, the Hud and the windows. Its pieces: the Hud, the EndWindow (created at the
## end of a round) and GameAutoplay (only with --autoplay). Esc goes back to the title
## (quit_to_title).

signal quit_to_title

var state: GameState
var _audio: AudioDirector
var _options: GameOptions
var _profile: Profile
var _jar: Jar
var _hud: Hud
var _end: EndWindow
var _autopilot: GameAutoplay
## How many rounds this session has started: the seed of each is --seed=<n> plus it.
var _round := 0


## audio, options and profile come from the title screen.
func setup(audio: AudioDirector, options: GameOptions, profile: Profile) -> void:
	_audio = audio
	_options = options
	_profile = profile


func _ready() -> void:
	if _options == null:
		_options = GameOptions.new()
		_profile = Profile.new()
		SaveStore.load_into(_profile, _options)
		DisplaySettings.apply(get_window(), _options)
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volume(_options.sfx_volume)
	_hud = Hud.new()
	add_child(_hud)
	if RunFlags.autoplay():
		_autopilot = GameAutoplay.new()
		_autopilot.setup(func() -> GameState: return state, func() -> Jar: return _jar,
			RunFlags.autoplay_games(), RunFlags.autoplay_save())
		_autopilot.drop = drop_at
		_autopilot.restart = _restart
		_autopilot.quit_requested.connect(_quit)
		add_child(_autopilot)
	_start_round()


func _physics_process(delta: float) -> void:
	if not state.over:
		_tick(delta)
	if _autopilot:
		_autopilot.step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_quit()


## Drops the waiting creature at x (kept inside the jar). The Jar's released and the autoplay
## call it; it does nothing while nothing waits.
func drop_at(x: float) -> void:
	if state.over or not state.can_drop:
		return
	var data := Chain.data(state.current)
	var body := _jar.drop(data, x)
	state.can_drop = false
	state.wait_left = Spawner.DROP_WAIT
	_audio.play_sfx(SfxLibrary.DROP)
	if _autopilot:
		_autopilot.on_dropped(data.id, body.position.x)
	_note_creature(data)
	Spawner.advance(state)
	_hud.set_next(Chain.data(state.next))


## One physics frame of the round: its clocks, the jar, then the danger's count.
func _tick(delta: float) -> void:
	state.elapsed += delta
	state.since_merge += delta
	if not state.can_drop:
		state.wait_left -= delta
		if state.wait_left <= 0.0:
			_present()
	_jar.step(delta)
	var over := Danger.is_over(_jar.highest_top(JarSpec.SETTLE_TIME))
	state.danger_time = Danger.step(state.danger_time, over, delta)
	_jar.show_danger(Danger.fraction(state.danger_time))
	if Danger.lost(state.danger_time):
		_lose()


## A new round: a new GameState, its first creatures and a new Jar in place of the old one.
func _start_round() -> void:
	if _jar:
		remove_child(_jar)
		_jar.queue_free()
	var seed_flag := RunFlags.seed()
	state = GameState.new(seed_flag + _round if seed_flag >= 0 else -1)
	_round += 1
	Spawner.start(state)
	_jar = Jar.new()
	_jar.released.connect(drop_at)
	_jar.merge_found.connect(_on_merge_found)
	add_child(_jar)
	_hud.set_score(0)
	_hud.set_record(_profile.best_score)
	_hud.set_next(Chain.data(state.next))
	_present()


## The waiting creature appears at the top of the jar.
func _present() -> void:
	state.can_drop = true
	state.wait_left = 0.0
	_jar.show_waiting(Chain.data(state.current))


## Two equal creatures touch (the Jar's merge_found): the combo and the points (Scoring), then the
## creature they make (Chain), or nothing for two of the last level.
func _on_merge_found(a: CreatureBody, b: CreatureBody) -> void:
	if state.over:
		return
	var level := a.data.level
	state.combo = Scoring.next_combo(state.combo, state.since_merge)
	state.since_merge = 0.0
	var points := Scoring.points(Chain.merge_points(level), state.combo)
	state.score += points
	var made := Chain.next_level(level)
	if made == 0:
		_jar.vanish(a, b)
		_audio.play_sfx(SfxLibrary.PRIZE)
	else:
		var data := Chain.data(made)
		_jar.merge(a, b, data)
		_audio.play_sfx(SfxLibrary.plop_id(made))
		_note_creature(data)
	_hud.set_score(state.score)
	_hud.show_combo(state.combo)
	if _autopilot:
		_autopilot.on_merged(Chain.IDS[made - 1] if made > 0 else "", state.combo)


## A creature has come into the jar (dropped or made by a merge).
func _note_creature(data: CreatureData) -> void:
	state.max_level = maxi(state.max_level, data.level)


## The jar overflowed: everything stops, the record is checked and saved, the end window opens.
func _lose() -> void:
	state.over = true
	state.can_drop = false
	_jar.freeze_all()
	_jar.show_danger(0.0)
	_audio.play_sfx(SfxLibrary.LOSE)
	var new_record := Scoring.record(_profile, state.score)
	_hud.set_record(_profile.best_score)
	var saved := SaveStore.save(_profile, _options)
	_end = EndWindow.new(state.score, Chain.data(state.max_level).display_name, new_record)
	_end.set_audio(_audio)
	_end.again_requested.connect(_restart)
	_end.quit_requested.connect(_quit)
	add_child(_end)
	if _autopilot:
		_autopilot.on_round_over({"score": state.score, "max_level": state.max_level,
			"seconds": state.elapsed, "new_record": new_record}, saved)


## Otra vez: the end window goes and a new round starts.
func _restart() -> void:
	if _end:
		_end.queue_free()
		_end = null
	_start_round()


## Back to the title; a Game run on its own (nothing above it) quits instead.
func _quit() -> void:
	if get_parent() == get_tree().root:
		get_tree().quit()
		return
	quit_to_title.emit()
