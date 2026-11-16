class_name ModalWindow extends CanvasLayer
## Node: a window of the design system core (a PanelContainer) over a scrim, on layer-window:
## its title (TITLE: title-s, text-accent), then what its subclass adds to body (lines, rows, a
## grid) and its big buttons (add_button(): UiTheme.big_button(), never smaller than a finger).
## Centred and as small as its content or, with full, filling the screen but a space-6 margin
## (the bestiary). Tapping the scrim, or Esc, emits back_requested; the subclass decides what that
## means (nothing, for the end of a round). Keeps processing while the tree is paused (the pause).
## With set_audio() its buttons sound.

signal back_requested

var body: VBoxContainer
var _audio: AudioDirector


func _init(title_text: String, full := false) -> void:
	layer = UiTokens.LAYER_WINDOW
	process_mode = Node.PROCESS_MODE_ALWAYS
	var scrim := ColorRect.new()
	scrim.color = UiTokens.color(&"surface-scrim")
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.gui_input.connect(_on_scrim_input)
	add_child(scrim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTokens.SPACE_6)
	add_child(margin)
	var panel := PanelContainer.new()
	if not full:
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	panel.add_child(body)
	add_line(title_text, UiTheme.TITLE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func set_audio(audio: AudioDirector) -> void:
	_audio = audio


## A centred line that wraps, in variation (&"" for the plain body text).
func add_line(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)
	return label


func add_button(text: String) -> Button:
	var button := UiTheme.big_button(text)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void:
		if _audio:
			_audio.play_sfx(SfxLibrary.ACCEPT))
	body.add_child(button)
	return button


func _on_scrim_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		back_requested.emit()
