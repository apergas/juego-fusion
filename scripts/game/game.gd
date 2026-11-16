class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child); run on its own
## (res://scenes/game/game.tscn) it loads the save and makes its own AudioDirector. A
## coordinator: it owns the round's GameState, the current Jar (a new one each round) and the
## game's clock (the round's time and the wait after a drop, on the physics frame). The Jar only
## reports (released); the rules (Chain, Spawner) decide; Game plays it back through the Jar.
## Its piece GameAutoplay plays by itself, only with --autoplay. Esc goes back to the title
## (quit_to_title).

signal quit_to_title

var state: GameState
var _audio: AudioDirector
var _options: GameOptions
var _profile: Profile
var _jar: Jar
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
	if RunFlags.autoplay():
		_autopilot = GameAutoplay.new()
		_autopilot.setup(func() -> GameState: return state, func() -> Jar: return _jar)
		_autopilot.drop = drop_at
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


## One physics frame of the round: its clocks, then the jar.
func _tick(delta: float) -> void:
	state.elapsed += delta
	if not state.can_drop:
		state.wait_left -= delta
		if state.wait_left <= 0.0:
			_present()
	_jar.step(delta)


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
	add_child(_jar)
	_present()


## The waiting creature appears at the top of the jar.
func _present() -> void:
	state.can_drop = true
	state.wait_left = 0.0
	_jar.show_waiting(Chain.data(state.current))


## A creature has come into the jar (dropped or made by a merge).
func _note_creature(data: CreatureData) -> void:
	state.max_level = maxi(state.max_level, data.level)


## Back to the title; a Game run on its own (nothing above it) quits instead.
func _quit() -> void:
	if get_parent() == get_tree().root:
		get_tree().quit()
		return
	quit_to_title.emit()
