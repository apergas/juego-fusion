class_name SaveStore extends RefCounted
## Reads and writes the one save file, user://save.json: the record, the bestiary and the
## options (SaveData). On the web Godot keeps user:// in the browser (IndexedDB), and a file is
## stored when it is closed. Runs with --autoplay use their own file, save_autoplay.json, so they
## never touch the player's. Copied from Villaclaro's scripts/game/save_store.gd, without its
## slots and its separate options file.

const PATH := "user://save.json"
const AUTOPLAY_PATH := "user://save_autoplay.json"


static func path() -> String:
	return AUTOPLAY_PATH if RunFlags.autoplay() else PATH


## Writes the profile and the options; returns what was written, or {} if the file could not be.
static func save(profile: Profile, options: GameOptions) -> Dictionary:
	var data := SaveData.from(profile, options)
	return data if _write(path(), data) else {}


## Reads the save into profile and options; false (and nothing changed) if there is none or it is
## damaged or of an unknown version.
static func load_into(profile: Profile, options: GameOptions) -> bool:
	return SaveData.apply(_read(path()), profile, options)


static func _write(file_path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar %s (error %d)" % [file_path, FileAccess.get_open_error()])
		return false
	var ok := file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return ok


static func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	return json.data if json.data is Dictionary else {}
