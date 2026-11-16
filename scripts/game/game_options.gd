class_name GameOptions extends RefCounted
## The player's options, saved with the record and the bestiary (SaveData): the music and the
## effects volumes (0..1), vibration and high contrast. Pure: converts to and from a Dictionary;
## anything missing or wrong keeps its default (a save from before the music gets DEFAULT_MUSIC).

const DEFAULT_MUSIC := 0.6
const DEFAULT_SFX := 0.8

var music_volume := DEFAULT_MUSIC
var sfx_volume := DEFAULT_SFX
var vibration := true
## High contrast palette of the windows (UiTokens.ALTO_CONTRASTE).
var high_contrast := false


func to_dict() -> Dictionary:
	return {"music": music_volume, "sfx": sfx_volume, "vibration": vibration,
		"high_contrast": high_contrast}


## Options from a Dictionary read from disk; missing or wrong values keep the default.
static func from_dict(data: Dictionary) -> GameOptions:
	var options := GameOptions.new()
	options.music_volume = _volume(data.get("music"), DEFAULT_MUSIC)
	options.sfx_volume = _volume(data.get("sfx"), DEFAULT_SFX)
	if data.get("vibration") is bool:
		options.vibration = data.vibration
	if data.get("high_contrast") is bool:
		options.high_contrast = data.high_contrast
	return options


## A volume read from disk, brought into 0..1; fallback if it is not a number.
static func _volume(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return clampf(float(value), 0.0, 1.0)
	return fallback
