class_name TitleScreen extends Node
## Main scene. Shows the game's name over the empty jar and its backdrop, with its big buttons
## in the lower half. Owns the only AudioDirector and the options, and creates a Game for each
## session; when the Game emits quit_to_title it frees it and shows the title again. Pattern
## taken from Villaclaro's scripts/title/title_screen.gd.

const GAME_SCENE := preload("res://scenes/game/game.tscn")
const TITLE_TEXT := "¡Plop!"
const SUBTITLE_TEXT := "junta dos iguales"
const PLAY_TEXT := "Jugar"

var _audio: AudioDirector
var _options: GameOptions
var _backdrop: Node3D
var _camera: Camera3D
var _ui: CanvasLayer
var _buttons: VBoxContainer
## The spacer under the buttons: as tall as it takes to lift them over the jar's floor.
var _bottom: Control
var _game: Game


func _ready() -> void:
	_options = GameOptions.new()
	DisplaySettings.apply(get_window(), _options)
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.set_volume(_options.sfx_volume)
	get_viewport().size_changed.connect(_fit)
	_open_title()


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
	_add_button(PLAY_TEXT, _start_game)
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


func _start_game() -> void:
	if _game:
		return
	_close_title()
	_game = GAME_SCENE.instantiate() as Game
	_game.setup(_audio, _options)
	_game.quit_to_title.connect(_on_quit_to_title)
	add_child(_game)


func _on_quit_to_title() -> void:
	if _game == null:
		return
	remove_child(_game)
	_game.queue_free()
	_game = null
	_open_title()
