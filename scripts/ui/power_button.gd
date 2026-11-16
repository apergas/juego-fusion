class_name PowerButton extends Button
## Node: a help's button at the bottom of the HUD (Romper, Cambiar): the core's MENU_BUTTON,
## power-button-w × hud-button, more than a finger, with its name and how many are left
## («Romper ×1»). It keeps working while the tree is paused (Romper's choosing pauses it); with
## toggle it stays pressed while its help is being used (the Hud sets it without a signal).


func _init(toggle := false) -> void:
	theme_type_variation = UiTheme.MENU_BUTTON
	focus_mode = Control.FOCUS_NONE
	toggle_mode = toggle
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(UiTokens.POWER_BUTTON_W, UiTokens.HUD_BUTTON)
