class_name Hud extends CanvasLayer
## Node, a piece of Game: the round's HUD on layer-hud. Top left the points (SCORE) and the
## record; top right «Siguiente» with the creature after the waiting one (a CreatureView) and
## the pause button; «¡Combo ×n!» centred over the mouth of the jar from a combo of 2, for as
## long as the combo can go on (Scoring.COMBO_WINDOW). Game calls it; it reports pause_requested.
## Everything but the buttons lets the finger through to the jar.

signal pause_requested

const NEXT_TEXT := "Siguiente"
const RECORD_TEXT := "Récord: %d"
const COMBO_TEXT := "¡Combo ×%d!"
const FADE := 0.2
const COMBO_POP := 1.2
const COMBO_POP_TIME := 0.15

var _score: Label
var _record: Label
var _next: CreatureView
var _row: HBoxContainer
var _combo: Label
var _combo_tween: Tween


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
