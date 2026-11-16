class_name RunFlags extends RefCounted
## The flags given after `--` on the command line (`godot --path . -- --autoplay ...`), read
## once from OS.get_cmdline_user_args() and kept in a static var. The only script of the game
## that reads the command line (the offline tools of scripts/tools/ read their own). The web
## build gets none, so every flag is off there. The autoplay sub-flags (games, save, menu) only
## count with --autoplay. Copied from Villaclaro's scripts/game/run_flags.gd, with this game's
## flags.

const AUTOPLAY := "--autoplay"
const AUTOPLAY_GAMES := "--autoplay-games="
const AUTOPLAY_SAVE := "--autoplay-save"
const AUTOPLAY_MENU := "--autoplay-menu"
const SEED := "--seed="
const TOUCH := "--touch"

static var _args := PackedStringArray()
static var _read := false


## --autoplay: rounds that play by themselves (no title menu, their own save file).
static func autoplay() -> bool:
	return _has(AUTOPLAY)


## --autoplay-games=N (with --autoplay): how many rounds to play before quitting (at least 1).
static func autoplay_games() -> int:
	if not autoplay():
		return 1
	return maxi(1, _value(AUTOPLAY_GAMES).to_int())


## --autoplay-save (with --autoplay): after each round, prints the save written and read back.
static func autoplay_save() -> bool:
	return autoplay() and _has(AUTOPLAY_SAVE)


## --autoplay-menu (with --autoplay): tours the title, the bestiary, the options and the pause.
static func autoplay_menu() -> bool:
	return autoplay() and _has(AUTOPLAY_MENU)


## --seed=<n>: the seed of the first round's Spawner (each next round adds 1); -1 when absent.
static func seed() -> int:
	var text := _value(SEED)
	return text.to_int() if text.is_valid_int() else -1


## --touch: the desktop fakes a phone (Device.is_touch()), the mouse acting as a finger.
static func touch() -> bool:
	return _has(TOUCH)


static func _all() -> PackedStringArray:
	if not _read:
		_args = OS.get_cmdline_user_args()
		_read = true
	return _args


static func _has(flag: String) -> bool:
	return _all().has(flag)


## The text after prefix of the first argument that starts with it, or "".
static func _value(prefix: String) -> String:
	for arg in _all():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""
