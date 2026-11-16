class_name EndWindow extends ModalWindow
## Node: the window at the end of a round: the points, the biggest creature of the round and
## «¡Nuevo récord!» when it is one, with Otra vez and Salir. Game creates it; it only reports.
## The scrim does nothing: the player picks one of the two.

signal again_requested
signal quit_requested

const TITLE_TEXT := "Fin de la partida"
const POINTS_TEXT := "%d puntos"
const BIGGEST_TEXT := "La más grande: %s"
const RECORD_TEXT := "¡Nuevo récord!"
const AGAIN_TEXT := "Otra vez"
const QUIT_TEXT := "Salir"


func _init(score: int, biggest: String, new_record: bool) -> void:
	super(TITLE_TEXT)
	add_line(POINTS_TEXT % score, UiTheme.SCORE)
	add_line(BIGGEST_TEXT % biggest, &"")
	if new_record:
		add_line(RECORD_TEXT, UiTheme.POSITIVE)
	add_button(AGAIN_TEXT).pressed.connect(again_requested.emit)
	add_button(QUIT_TEXT).pressed.connect(quit_requested.emit)
