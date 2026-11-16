class_name AudioDirector extends Node
## Plays the music and the sound effects. Copied from Villaclaro's scripts/audio/audio_director.gd,
## trimmed to the music and the effects (no ambient). Not an autoload: TitleScreen creates the only
## one and passes it on (Game, the windows). Three music players cross-fade over CROSSFADE seconds
## (MusicLibrary's tunes: the title's and the jar's; the third one is free when a tune is
## switched mid-fade, so the one still fading out is never cut); SFX_PLAYERS players take turns
## for the effects. With --autoplay everything plays the same but muted, and each tune started is printed
## with how long it took to render (`Música: jar (120 ms)`); on a headless run or while recording
## frames (--write-movie) the streams are built and set but never started: those audio drivers
## keep the playbacks alive at exit and Godot reports them as leaked. Keeps running while the tree
## is paused: the music goes on under the pause, and its buttons sound.

const CROSSFADE := 0.5
const MUSIC_PLAYERS := 3
const SFX_PLAYERS := 6

var music_volume := GameOptions.DEFAULT_MUSIC
var sfx_volume := GameOptions.DEFAULT_SFX

var _music: Array[AudioStreamPlayer] = []
var _current := 0
var _music_id := ""
var _fade: Tween
var _sfx: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _muted := false
## Headless or --write-movie: never start a player.
var _no_playback := false
var _autoplay := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_autoplay = RunFlags.autoplay()
	_no_playback = DisplayServer.get_name() == "headless" \
		or Engine.get_write_movie_path() != ""
	_muted = _autoplay or _no_playback
	for i in MUSIC_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.volume_linear = 0.0
		add_child(player)
		_music.append(player)
	for i in SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx.append(player)


## Empties the stream caches, so no stream is left at exit.
func _exit_tree() -> void:
	MusicLibrary.clear_cache()
	SfxLibrary.clear_cache()


## Cross-fades to the tune (a MusicScore id); does nothing if it already plays.
func play_music(id: String) -> void:
	if id == _music_id:
		return
	_music_id = id
	var started := Time.get_ticks_msec()
	var stream := MusicLibrary.build(id)
	if _autoplay:
		print("Música: %s (%d ms)" % [id, Time.get_ticks_msec() - started])
	var next := _quietest_other()
	_current = next
	var new := _music[_current]
	new.stream = stream
	new.volume_linear = 0.0
	_start(new)
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel()
	_fade.tween_property(new, "volume_linear", _music_level(), CROSSFADE)
	for player in _music:
		if player != new:
			_fade.tween_property(player, "volume_linear", 0.0, CROSSFADE)
	_fade.chain().tween_callback(_stop_others.bind(new))


func play_sfx(id: String) -> void:
	var player := _sfx[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_PLAYERS
	player.stream = SfxLibrary.build(id)
	player.volume_linear = 0.0 if _muted else sfx_volume
	_start(player)


## Volumes 0..1. The music changes at once (a cross-fade ends where it is); the effects from the
## next one.
func set_volumes(music: float, sfx: float) -> void:
	music_volume = music
	sfx_volume = sfx
	if _fade:
		_fade.kill()
	for i in MUSIC_PLAYERS:
		var player := _music[i]
		if i == _current and _music_id != "":
			player.volume_linear = _music_level()
		else:
			player.volume_linear = 0.0
			player.stop()


## The player (not the current one) that is the least audible: free to take the next tune.
func _quietest_other() -> int:
	var best := -1
	for i in MUSIC_PLAYERS:
		if i != _current and (best < 0 or _music[i].volume_linear < _music[best].volume_linear):
			best = i
	return best


func _stop_others(keep: AudioStreamPlayer) -> void:
	for player in _music:
		if player != keep:
			player.stop()


func _start(player: AudioStreamPlayer) -> void:
	if not _no_playback:
		player.play()


func _music_level() -> float:
	return 0.0 if _muted else music_volume
