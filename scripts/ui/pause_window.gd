class_name PauseWindow extends ModalWindow
## Node: the pause, from the HUD's button (or Esc): Seguir, Opciones, Empezar de nuevo and Salir
## al título. Game pauses the tree while it is open (a ModalWindow keeps processing); the scrim and
## Esc are Seguir. It only reports: Opciones asks Game to open the OptionsWindow over it, and the
## pause stays open underneath. Seguir, Empezar de nuevo and Salir al título: the first press wins
## (all three go off).

signal resume_requested
signal options_requested
signal restart_requested
signal quit_requested

const TITLE_TEXT := "Pausa"
const RESUME_TEXT := "Seguir"
const OPTIONS_TEXT := "Opciones"
const RESTART_TEXT := "Empezar de nuevo"
const QUIT_TEXT := "Salir al título"


func _init() -> void:
	super(TITLE_TEXT)
	var resume := add_button(RESUME_TEXT)
	add_button(OPTIONS_TEXT).pressed.connect(options_requested.emit)
	var restart := add_button(RESTART_TEXT)
	var quit := add_button(QUIT_TEXT)
	var leaving: Array = [resume, restart, quit]
	resume.pressed.connect(_choose.bind(resume_requested, leaving))
	restart.pressed.connect(_choose.bind(restart_requested, leaving))
	quit.pressed.connect(_choose.bind(quit_requested, leaving))
	back_requested.connect(resume_requested.emit)


func _choose(requested: Signal, buttons: Array) -> void:
	for button: Button in buttons:
		button.disabled = true
	requested.emit()
