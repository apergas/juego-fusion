class_name GameOptions extends RefCounted
## The player's options, saved with the record and the bestiary (SaveData): the effects volume
## (0..1), vibration and high contrast. Pure: converts to and from a Dictionary; anything
## missing or wrong keeps its default.

const DEFAULT_SFX := 0.8

var sfx_volume := DEFAULT_SFX
var vibration := true
## High contrast palette of the windows (UiTokens.ALTO_CONTRASTE).
var high_contrast := false


func to_dict() -> Dictionary:
	return {"sfx": sfx_volume, "vibration": vibration, "high_contrast": high_contrast}


## Options from a Dictionary read from disk; missing or wrong values keep the default.
static func from_dict(data: Dictionary) -> GameOptions:
	var options := GameOptions.new()
	var sfx: Variant = data.get("sfx")
	if sfx is float or sfx is int:
		options.sfx_volume = clampf(float(sfx), 0.0, 1.0)
	if data.get("vibration") is bool:
		options.vibration = data.vibration
	if data.get("high_contrast") is bool:
		options.high_contrast = data.high_contrast
	return options
