class_name DisplaySettings extends RefCounted
## Puts into effect the options that live outside the rules: the theme (high contrast), the
## size of the whole interface and, with --touch, the mouse acting as a finger. TitleScreen calls
## it at the start and at each options change; a Game run on its own calls it once. Pattern
## taken from Villaclaro's scripts/ui/display_settings.gd.

## The interface is drawn this many times bigger than its tokens on every device: the canvas is
## 720 wide and a phone held upright shows it about 360 points wide.
const UI_SCALE := 1.25


static func apply(window: Window, options: GameOptions) -> void:
	UiTheme.apply(window, options.high_contrast)
	window.title = ProjectSettings.get_setting("application/config/name")
	window.content_scale_factor = UI_SCALE
	if RunFlags.touch():
		Input.emulate_touch_from_mouse = true
