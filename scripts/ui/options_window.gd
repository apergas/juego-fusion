class_name OptionsWindow extends ModalWindow
## Node: Opciones, from the title or over the pause (the core's OptionRow): the music and the
## effects volumes (two sliders in steps of 10 %, each with its value beside it), vibration and
## high contrast (two selectors, Sí / No). Each change is applied at once: it changes the
## GameOptions it was given and emits changed; its owner puts it into effect and saves. There is
## no Aceptar: Volver, the scrim or Esc close it (closed).

signal changed
signal closed

const TITLE_TEXT := "Opciones"
const MUSIC_TEXT := "Música"
const SFX_TEXT := "Efectos"
const VIBRATION_TEXT := "Vibración"
const CONTRAST_TEXT := "Alto contraste"
const YES_TEXT := "Sí"
const NO_TEXT := "No"
const PERCENT_TEXT := "%d %%"
const BACK_TEXT := "Volver"
const STEP := 0.1

var _options: GameOptions


func _init(options: GameOptions) -> void:
	super(TITLE_TEXT)
	_options = options
	_slider(_row(MUSIC_TEXT), options.music_volume, func(value: float) -> void:
		_options.music_volume = value)
	_slider(_row(SFX_TEXT), options.sfx_volume, func(value: float) -> void:
		_options.sfx_volume = value)
	_selector(_row(VIBRATION_TEXT), options.vibration, func(on: bool) -> void:
		_options.vibration = on
		changed.emit())
	_selector(_row(CONTRAST_TEXT), options.high_contrast, func(on: bool) -> void:
		_options.high_contrast = on
		changed.emit())
	add_button(BACK_TEXT).pressed.connect(closed.emit)
	back_requested.connect(closed.emit)


## A row at least a finger tall: the option's name on the left, its control to be added on the
## right.
func _row(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = UiTokens.TOUCH_TARGET
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	body.add_child(row)
	return row


## A volume slider of 0..1 in STEP steps with its percent beside it; on_change gets each new
## value, then changed is emitted.
func _slider(row: HBoxContainer, value: float, on_change: Callable) -> void:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = STEP
	slider.value = value
	slider.custom_minimum_size = Vector2(UiTokens.SLIDER_W, UiTokens.TOUCH_TARGET)
	row.add_child(slider)
	var percent := Label.new()
	percent.theme_type_variation = UiTheme.CAPTION
	percent.text = PERCENT_TEXT % roundi(value * 100.0)
	row.add_child(percent)
	slider.value_changed.connect(func(new_value: float) -> void:
		on_change.call(new_value)
		percent.text = PERCENT_TEXT % roundi(new_value * 100.0)
		changed.emit())


## Sí / No, the active one filled; on_change gets the new value.
func _selector(row: HBoxContainer, value: bool, on_change: Callable) -> void:
	var group := ButtonGroup.new()
	for choice: bool in [true, false]:
		var button := Button.new()
		button.text = YES_TEXT if choice else NO_TEXT
		button.theme_type_variation = UiTheme.SELECTOR
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = choice == value
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(UiTokens.TOUCH_TARGET, UiTokens.TOUCH_TARGET)
		button.pressed.connect(func() -> void: on_change.call(choice))
		row.add_child(button)
