class_name ConfirmWindow extends ModalWindow
## Node: a question with two answers over a scrim: its title, one line and two big buttons, the
## first answer (confirmed) above the second (closed). The scrim and Esc are the second. The first
## press wins (both buttons go off). The title asks it before Jugar throws a kept round away.

signal confirmed
signal closed


func _init(title_text: String, line: String, yes_text: String, no_text: String) -> void:
	super(title_text)
	add_line(line, &"")
	var yes := add_button(yes_text)
	var no := add_button(no_text)
	yes.pressed.connect(_choose.bind(confirmed, [yes, no]))
	no.pressed.connect(_choose.bind(closed, [yes, no]))
	back_requested.connect(closed.emit)


func _choose(requested: Signal, buttons: Array) -> void:
	for button: Button in buttons:
		button.disabled = true
	requested.emit()
