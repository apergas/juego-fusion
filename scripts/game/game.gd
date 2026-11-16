class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child); run on its own
## (res://scenes/game/game.tscn) it loads the save and makes its own AudioDirector. A
## coordinator: it owns the round's GameState, the current Jar (a new one each round) and the
## game's clock (on the physics frame). Esc goes back to the title (quit_to_title).

signal quit_to_title

var state: GameState
var _audio: AudioDirector
var _options: GameOptions
var _profile: Profile
var _jar: Jar


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
	_start_round()


func _physics_process(delta: float) -> void:
	state.elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_quit()


## A new round: a new GameState and a new Jar in place of the old one.
func _start_round() -> void:
	if _jar:
		remove_child(_jar)
		_jar.queue_free()
	state = GameState.new()
	_jar = Jar.new()
	add_child(_jar)


## Back to the title; a Game run on its own (nothing above it) quits instead.
func _quit() -> void:
	if get_parent() == get_tree().root:
		get_tree().quit()
		return
	quit_to_title.emit()
