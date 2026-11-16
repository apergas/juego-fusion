class_name UiTheme extends DsTheme
## Constructor: static; the game's theme: the design system core's DsTheme plus the game's own
## part (the points, the combo and the logo labels) and its big buttons. Its only state is
## DsTheme's: the fonts and the theme applied, and DsTheme.touch, which it writes. The screens
## call everything through UiTheme (UiTheme.big_button(), UiTheme.CAPTION...): the generic
## part comes from DsTheme. apply(), ensure() and build() keep DsTheme's signatures (GDScript
## checks a redefined static function against its parent's) and hand it _extend(). Pattern
## taken from Villaclaro's scripts/ui/ui_theme.gd.

## The points in the HUD and in the end window: display-m, text-accent, outline-m.
const SCORE := &"ScoreLabel"
## «¡Combo ×n!»: title-l, text-accent, outline-l.
const COMBO := &"ComboLabel"
## The game's name on the title, display-xl, and its second line, title-l.
const LOGO := &"LogoLabel"
const LOGO_SUB := &"LogoSubLabel"


## Puts the theme on (again only if high_contrast changed). DisplaySettings.apply() calls it.
static func apply(window: Window, high_contrast := false, extend := Callable()) -> void:
	DsTheme.touch = Device.is_touch()
	DsTheme.apply(window, high_contrast, _extend if extend.is_null() else extend)


## The scenes that run on their own (no title before them) put the theme on once.
static func ensure(window: Window, extend := Callable()) -> void:
	DsTheme.touch = Device.is_touch()
	DsTheme.ensure(window, _extend if extend.is_null() else extend)


## DsTheme's Theme with the game's part.
static func build(extend := Callable()) -> Theme:
	return DsTheme.build(_extend if extend.is_null() else extend)


## A big pill (the core's ACTION_BUTTON) of at least button-big-w × button-big-h, more than a
## finger: every button of the title and of the windows. The finger never leaves a focus mark.
static func big_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = ACTION_BUTTON
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(UiTokens.BUTTON_BIG_W, UiTokens.BUTTON_BIG_H)
	return button


## The game's version ("v0.1.0") in caption, text-primary with the outline, added to parent (a
## full-screen Control) in its bottom right corner, SPACE_3 in. A Label never takes the mouse.
static func version_label(parent: Control) -> Label:
	var label := Label.new()
	label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	style_label(label, &"caption", &"text-primary", UiTokens.OUTLINE_S)
	parent.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT,
		Control.PRESET_MODE_MINSIZE, UiTokens.SPACE_3)
	return label


## The game's part of the Theme; DsTheme.build() calls it with the Theme it builds.
static func _extend(theme: Theme) -> void:
	_label(theme, SCORE, &"display-m", &"text-accent", UiTokens.OUTLINE_M)
	_label(theme, COMBO, &"title-l", &"text-accent", UiTokens.OUTLINE_L)
	_label(theme, LOGO, &"display-xl", &"text-accent", UiTokens.OUTLINE_XL)
	_label(theme, LOGO_SUB, &"title-l", &"text-primary", UiTokens.OUTLINE_L)
