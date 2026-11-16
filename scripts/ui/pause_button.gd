class_name PauseButton extends Button
## Node: the HUD's pause button, a small window (the core's MENU_BUTTON) hud-button wide and tall,
## more than a finger, with two bars drawn in text-primary (drawn, not a glyph: the web shows it
## the same).


func _init() -> void:
	theme_type_variation = UiTheme.MENU_BUTTON
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(UiTokens.HUD_BUTTON, UiTokens.HUD_BUTTON)


func _draw() -> void:
	var bar := Vector2(UiTokens.SPACE_2, UiTokens.ICON_M)
	var gap := float(UiTokens.SPACE_2)
	var left := (size.x - 2.0 * bar.x - gap) / 2.0
	var top := (size.y - bar.y) / 2.0
	var color := UiTokens.color(&"text-primary")
	draw_rect(Rect2(Vector2(left, top), bar), color)
	draw_rect(Rect2(Vector2(left + bar.x + gap, top), bar), color)
