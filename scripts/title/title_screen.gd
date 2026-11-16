class_name TitleScreen extends Node
## Main scene. Shows the game's name over the empty jar and its backdrop, with its big buttons in
## the lower half: Seguir (only while a round is kept), Jugar, Bestiario and Opciones. Owns the
## only AudioDirector, the options and the profile (the record, the bestiary and the kept round),
## loaded from the save (SaveStore) at the start, and creates a Game for each session; when the
## Game emits quit_to_title it frees it and shows the title again. Pattern taken from
## Villaclaro's scripts/title/title_screen.gd. Seguir resumes the kept round; Jugar with one kept
## asks first (a ConfirmWindow: Empezar forgets it). Bestiario and Opciones open a BestiaryWindow
## or an OptionsWindow over the title; an options change is put into effect at once
## (DisplaySettings, the volume) and saved. With --autoplay the Game starts at once (a new round)
## and the run quits when it goes back to the title; with --autoplay-menu too, the title first
## shows itself, the bestiary, the options and, with a round kept, the question of Jugar
## (_tour()), then starts the Game (resuming the kept round, if there is one).

const GAME_SCENE := preload("res://scenes/game/game.tscn")
const TITLE_TEXT := "¡Plop!"
const SUBTITLE_TEXT := "junta dos iguales"
const PLAY_TEXT := "Jugar"
const BESTIARY_TEXT := "Bestiario"
const OPTIONS_TEXT := "Opciones"
const RESUME_TEXT := "Seguir"
const NEW_ROUND_TITLE := "¿Tarro nuevo?"
const NEW_ROUND_TEXT := "El tarro a medias se perderá."
const NEW_ROUND_YES := "Empezar"
const NEW_ROUND_NO := "Volver"

var _audio: AudioDirector
var _options: GameOptions
var _profile: Profile
var _backdrop: Node3D
var _camera: Camera3D
var _ui: CanvasLayer
var _buttons: VBoxContainer
var _window: ModalWindow
## The spacer under the buttons: as tall as it takes to lift them over the jar's floor.
var _bottom: Control
var _game: Game
var _autoplay := false

#region Autoplay
## --autoplay-menu: seconds each screen of the title's tour stays.
const TOUR_STEP := 2.0
#endregion


func _ready() -> void:
	_autoplay = RunFlags.autoplay()
	_options = GameOptions.new()
	_profile = Profile.new()
	SaveStore.load_into(_profile, _options)
	DisplaySettings.apply(get_window(), _options)
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.set_volume(_options.sfx_volume)
	get_viewport().size_changed.connect(_fit)
	if _autoplay and not RunFlags.autoplay_menu():
		_start_game()
		return
	_open_title()
	if _autoplay:
		_tour()


## The backdrop, the empty jar, the camera and the menu.
func _open_title() -> void:
	_backdrop = Node3D.new()
	add_child(_backdrop)
	JarBuilder.backdrop(_backdrop)
	JarBuilder.jar(_backdrop)
	_camera = JarBuilder.camera(_backdrop)
	_fit()
	_build_menu()


## Taken out of the tree at once, so its camera never competes with the Jar's.
func _close_title() -> void:
	if _backdrop:
		remove_child(_backdrop)
		_backdrop.queue_free()
		_backdrop = null
		_camera = null
	if _ui:
		remove_child(_ui)
		_ui.queue_free()
		_ui = null
		_buttons = null
		_bottom = null


func _fit() -> void:
	if _camera:
		JarBuilder.fit_camera(_camera)
		_lift_buttons()


## The button block ends SPACE_4 above the jar's floor frame, wherever the camera puts it.
func _lift_buttons() -> void:
	if _bottom == null:
		return
	var floor_y := _camera.unproject_position(Vector3(0.0, -JarBuilder.FRAME, 0.0)).y
	var view_height := get_viewport().get_visible_rect().size.y
	_bottom.custom_minimum_size.y = maxf(UiTokens.SPACE_12,
		view_height - floor_y + UiTokens.SPACE_4)


func _build_menu() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = UiTokens.LAYER_HUD
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE,
		UiTokens.SPACE_6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 0)
	root.add_child(column)
	_centered(column, TITLE_TEXT, UiTheme.LOGO)
	_centered(column, SUBTITLE_TEXT, UiTheme.LOGO_SUB)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)
	_buttons = VBoxContainer.new()
	_buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_buttons.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	column.add_child(_buttons)
	if _has_kept_round():
		_add_button(RESUME_TEXT, _start_game.bind(true))
	_add_button(PLAY_TEXT, _on_play)
	_add_button(BESTIARY_TEXT, _open_bestiary)
	_add_button(OPTIONS_TEXT, _open_options)
	_bottom = Control.new()
	_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_bottom)
	UiTheme.version_label(root)
	_lift_buttons()


func _centered(parent: Control, text: String, variation: StringName) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)


func _add_button(text: String, action: Callable) -> Button:
	var button := UiTheme.big_button(text)
	button.pressed.connect(func() -> void:
		_audio.play_sfx(SfxLibrary.ACCEPT)
		action.call())
	_buttons.add_child(button)
	return button


func _has_kept_round() -> bool:
	return not _profile.saved_round.is_empty()


## Jugar: a new round; with a round kept, it asks first.
func _on_play() -> void:
	if not _has_kept_round():
		_start_game()
		return
	if _window:
		return
	var window := ConfirmWindow.new(NEW_ROUND_TITLE, NEW_ROUND_TEXT, NEW_ROUND_YES, NEW_ROUND_NO)
	window.confirmed.connect(_start_new_round)
	window.closed.connect(_close_window)
	_show_window(window)


## Empezar: the kept round is forgotten (and the save says so at once), and a new one starts.
func _start_new_round() -> void:
	_profile.saved_round = {}
	SaveStore.save(_profile, _options)
	_start_game()


func _open_bestiary() -> void:
	if _window:
		return
	var window := BestiaryWindow.new(_profile)
	window.closed.connect(_close_window)
	_show_window(window)


func _open_options() -> void:
	if _window:
		return
	var window := OptionsWindow.new(_options)
	window.changed.connect(_on_options_changed)
	window.closed.connect(_close_window)
	_show_window(window)


## Every change at once: the volume (with a tick to hear it), the theme, and the save.
func _on_options_changed() -> void:
	_audio.set_volume(_options.sfx_volume)
	_audio.play_sfx(SfxLibrary.CURSOR)
	DisplaySettings.apply(get_window(), _options)
	SaveStore.save(_profile, _options)


func _show_window(window: ModalWindow) -> void:
	window.set_audio(_audio)
	_window = window
	add_child(window)


func _close_window() -> void:
	if _window:
		_window.queue_free()
		_window = null


## A Game for a session: with resume it starts from the kept round (Seguir).
func _start_game(resume := false) -> void:
	if _game:
		return
	_close_window()
	_close_title()
	_game = GAME_SCENE.instantiate() as Game
	_game.setup(_audio, _options, _profile, resume)
	_game.quit_to_title.connect(_on_quit_to_title)
	add_child(_game)


func _on_quit_to_title() -> void:
	if _game == null:
		return
	remove_child(_game)
	_game.queue_free()
	_game = null
	if _autoplay:
		get_tree().quit()
		return
	_open_title()


#region Autoplay
## --autoplay-menu: the title, the bestiary (and its end), the options and, with a round kept, the
## question of Jugar (closed with Volver), then the game, resuming the kept round if there is one.
## A window is looked up again after each wait: it may have gone.
func _tour() -> void:
	await get_tree().create_timer(TOUR_STEP).timeout
	_open_bestiary()
	await get_tree().create_timer(TOUR_STEP).timeout
	var bestiary := _window as BestiaryWindow
	if is_instance_valid(bestiary):
		bestiary.scroll.scroll_vertical = int(bestiary.scroll.get_v_scroll_bar().max_value)
	await get_tree().create_timer(TOUR_STEP).timeout
	_close_window()
	_open_options()
	await get_tree().create_timer(TOUR_STEP).timeout
	_close_window()
	if _has_kept_round():
		_on_play()
		await get_tree().create_timer(TOUR_STEP).timeout
		_close_window()
	_start_game(_has_kept_round())
#endregion
