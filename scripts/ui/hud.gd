class_name Hud extends CanvasLayer
## Node, a piece of Game: the round's HUD on layer-hud. Top left the points (SCORE) and the
## record; top right «Siguiente» with the creature after the waiting one (a CreatureView) and the
## pause button; «¡Combo ×n!» centred over the mouth of the jar from a combo of 2, for as long as
## the combo can go on (Scoring.COMBO_WINDOW); at the bottom corners the helps' PowerButtons,
## Romper on the left and Cambiar on the right, off when they can't be used; while Romper chooses,
## its button stays pressed and the hint (PICK_TEXT) takes the combo's place. Game calls it; it
## reports pause_requested, break_requested and swap_requested. Everything but the buttons lets
## the finger through to the jar.

signal pause_requested
signal break_requested
signal swap_requested

const NEXT_TEXT := "Siguiente"
const RECORD_TEXT := "Récord: %d"
const COMBO_TEXT := "¡Combo ×%d!"
const BREAK_TEXT := "Romper ×%d"
const SWAP_TEXT := "Cambiar ×%d"
const PICK_TEXT := "Toca la criatura que quieres romper"
const FADE := 0.2
const COMBO_POP := 1.2
const COMBO_POP_TIME := 0.15

var _score: Label
var _record: Label
var _next: CreatureView
var _row: HBoxContainer
var _combo: Label
var _combo_tween: Tween
var _break: PowerButton
var _swap: PowerButton
var _hint: Label
var _can_swap := false
var _picking := false


func _init() -> void:
	layer = UiTokens.LAYER_HUD
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_row = HBoxContainer.new()
	_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE,
		UiTokens.SPACE_6)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	root.add_child(_row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_theme_constant_override(&"separation", 0)
	_row.add_child(left)
	_score = _label(left, UiTheme.SCORE, "0")
	_record = _label(left, UiTheme.OUTLINED, RECORD_TEXT % 0)
	var next_box := VBoxContainer.new()
	next_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_box.add_theme_constant_override(&"separation", 0)
	_row.add_child(next_box)
	_label(next_box, UiTheme.OUTLINED, NEXT_TEXT).horizontal_alignment = \
		HORIZONTAL_ALIGNMENT_CENTER
	_next = CreatureView.new(UiTokens.NEXT_VIEW)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_box.add_child(_next)
	var pause := PauseButton.new()
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pause.pressed.connect(pause_requested.emit)
	_row.add_child(pause)
	_combo = _label(root, UiTheme.COMBO, "")
	_combo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_combo.offset_top = UiTokens.HUD_COMBO_TOP
	_combo.offset_bottom = UiTokens.HUD_COMBO_TOP
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo.hide()
	_hint = _label(root, UiTheme.OUTLINED, PICK_TEXT)
	_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_top = UiTokens.HUD_COMBO_TOP
	_hint.offset_bottom = UiTokens.HUD_COMBO_TOP
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.hide()
	var bottom := HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE,
		Control.PRESET_MODE_MINSIZE, UiTokens.SPACE_4)
	# Its height is not known yet: it grows upwards from the bottom edge, never past it.
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)
	_break = PowerButton.new(true)
	_break.pressed.connect(break_requested.emit)
	bottom.add_child(_break)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(gap)
	_swap = PowerButton.new()
	_swap.pressed.connect(swap_requested.emit)
	bottom.add_child(_swap)
	set_power_ups(0, 0, false, false)


func set_score(score: int) -> void:
	_score.text = str(score)


func set_record(best: int) -> void:
	_record.text = RECORD_TEXT % best


func set_next(data: CreatureData) -> void:
	_next.show_creature(data)


## After a merge: from a combo of 2, «¡Combo ×n!» pops and stays while the combo can go on.
func show_combo(combo: int) -> void:
	if combo < 2:
		return
	_combo.text = COMBO_TEXT % combo
	_combo.show()
	_combo.modulate.a = 1.0
	_combo.pivot_offset = _combo.size / 2.0
	_combo.scale = Vector2.ONE * COMBO_POP
	if _combo_tween:
		_combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_property(_combo, "scale", Vector2.ONE, COMBO_POP_TIME)
	_combo_tween.tween_interval(Scoring.COMBO_WINDOW)
	_combo_tween.tween_property(_combo, "modulate:a", 0.0, FADE)
	_combo_tween.tween_callback(_combo.hide)


## The helps' charges, and whether each can be used now (a button that can't is off).
func set_power_ups(breaks: int, swaps: int, can_break: bool, can_swap: bool) -> void:
	_break.text = BREAK_TEXT % breaks
	_break.disabled = not can_break
	_swap.text = SWAP_TEXT % swaps
	_can_swap = can_swap
	_swap.disabled = _picking or not can_swap


## Romper is choosing (on) or not: its button pressed, the hint shown and Cambiar off (it does
## nothing meanwhile).
func set_picking(on: bool) -> void:
	_picking = on
	_swap.disabled = on or not _can_swap
	_break.set_pressed_no_signal(on)
	_hint.visible = on


func _label(parent: Control, variation: StringName, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	parent.add_child(label)
	return label


## Drops the combo of the round before (a new round starts clean).
func clear() -> void:
	if _combo_tween:
		_combo_tween.kill()
	_combo.hide()
	set_picking(false)
