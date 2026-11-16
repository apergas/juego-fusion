class_name AudioDirector extends Node
## Plays the sound effects (there is no music or ambient yet). Copied from Villaclaro's
## scripts/audio/audio_director.gd, trimmed to the effects. Not an autoload: TitleScreen creates
## the only one and passes it on (Game, the windows). SFX_PLAYERS players take turns. With
## --autoplay everything plays the same but muted; on a headless run or while recording frames
## (--write-movie) the streams are built and set but never started: those audio drivers keep the
## playbacks alive at exit and Godot reports them as leaked. Keeps running while the tree is
## paused (the pause window's buttons sound).

const SFX_PLAYERS := 6

var sfx_volume := GameOptions.DEFAULT_SFX

var _sfx: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _muted := false
## Headless or --write-movie: never start a player.
var _no_playback := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_no_playback = DisplayServer.get_name() == "headless" \
		or Engine.get_write_movie_path() != ""
	_muted = RunFlags.autoplay() or _no_playback
	for i in SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx.append(player)


## Empties the stream cache, so no stream is left at exit.
func _exit_tree() -> void:
	SfxLibrary.clear_cache()


func play_sfx(id: String) -> void:
	var player := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_PLAYERS
	player.stream = SfxLibrary.build(id)
	player.volume_linear = 0.0 if _muted else sfx_volume
	if not _no_playback:
		player.play()


## Volume 0..1 of the next effects.
func set_volume(sfx: float) -> void:
	sfx_volume = sfx
