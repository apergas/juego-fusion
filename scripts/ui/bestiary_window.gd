class_name BestiaryWindow extends ModalWindow
## Node: the bestiary, opened from the title, filling the screen: a grid of the 8 links of the
## chain in a scroll. A discovered one shows its creature turning, its name, its level and its
## line; one not yet discovered, its silhouette and «???». Volver, the scrim or Esc close it
## (closed).

signal closed

const TITLE_TEXT := "Bestiario"
const LEVEL_TEXT := "Nivel %d"
const BACK_TEXT := "Volver"
const COLUMNS := 2

## Public for the autoplay's tour (it scrolls to the end).
var scroll: ScrollContainer


func _init(profile: Profile) -> void:
	super(TITLE_TEXT, true)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override(&"h_separation", UiTokens.SPACE_4)
	grid.add_theme_constant_override(&"v_separation", UiTokens.SPACE_4)
	scroll.add_child(grid)
	for level in range(1, Chain.MAX_LEVEL + 1):
		var data := Chain.data(level)
		grid.add_child(_card(data, Bestiary.is_discovered(profile, data.id)))
	add_button(BACK_TEXT).pressed.connect(closed.emit)
	back_requested.connect(closed.emit)


func _card(data: CreatureData, known: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = UiTheme.CARD
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_1)
	card.add_child(column)
	var view := CreatureView.new(UiTokens.BESTIARY_VIEW)
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view.spin = known
	view.show_creature(data, not known)
	column.add_child(view)
	_card_line(column, data.display_name if known else Bestiary.UNKNOWN, &"")
	if known:
		_card_line(column, LEVEL_TEXT % data.level, UiTheme.CAPTION)
		_card_line(column, data.lore, UiTheme.CAPTION)
	return card


func _card_line(parent: Control, text: String, variation: StringName) -> void:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
