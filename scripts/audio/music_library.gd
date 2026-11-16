class_name MusicLibrary extends RefCounted
## Constructor: static; renders MusicScore's tunes into looping AudioStreamWAV (RATE Hz, 16-bit
## mono, through SfxLibrary.to_stream()) for the AudioDirector, and keeps no state but a cache of
## streams and of the hi-hat: the lead in a square wave (the tune's duty), the bass in a triangle,
## the hi-hat in noise. Copied from Villaclaro's scripts/audio/music_library.gd, trimmed to what
## these tunes use; build() renders a tune once, the first time it plays (about 20 s of samples).

## If rendering a tune on the desktop takes more than 0.4 s, this goes down to 11025.
const RATE := 22050
const LEAD_VOLUME := 0.16
const BASS_VOLUME := 0.26
const HAT_VOLUME := 0.08
## Seconds of fade-in and fade-out of every note (no clicks between notes).
const ATTACK := 0.004
const RELEASE := 0.02
## The lead loses this share of its volume over each note, for a plucked sound.
const LEAD_DECAY := 0.45
const HAT_TIME := 0.04
const NOISE_SEED := 1234

static var _cache := {}
static var _hat := PackedFloat32Array()


## The tune id (a MusicScore id) as a looping stream, rendered on the first call.
static func build(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var track: Dictionary = MusicScore.TRACKS[id]
	var step_frames := MusicScore.step_seconds(track.bpm) * RATE
	var lead := MusicScore.parse(track.lead)
	var total := MusicScore.steps(lead)
	var frames := int(total * step_frames)
	var mix := PackedFloat32Array()
	mix.resize(frames)
	mix.fill(0.0)
	_add_voice(mix, lead, total, step_frames, track.duty, LEAD_VOLUME, LEAD_DECAY)
	_add_voice(mix, MusicScore.parse(track.bass), total, step_frames, -1.0, BASS_VOLUME, 0.0)
	_add_hats(mix, MusicScore.parse(track.drums), total, step_frames)
	var stream := SfxLibrary.to_stream(mix, RATE)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	_cache[id] = stream
	return stream


## Drops the cached streams (AudioDirector._exit_tree()), so none is left at exit.
static func clear_cache() -> void:
	_cache.clear()
	_hat = PackedFloat32Array()


## Plays notes from the start, repeating them until total sixteenths. duty < 0 is a triangle wave,
## otherwise a square wave with that duty cycle.
static func _add_voice(mix: PackedFloat32Array, notes: Array, total: int, step_frames: float,
		duty: float, volume: float, decay: float) -> void:
	if notes.is_empty():
		return
	var step := 0
	var index := 0
	while step < total:
		var note: Array = notes[index % notes.size()]
		var length: int = mini(note[1], total - step)
		var freq: float = note[0]
		if freq > 0.0:
			_add_tone(mix, int(step * step_frames), int(length * step_frames), freq, duty,
				volume, decay)
		step += length
		index += 1


static func _add_tone(mix: PackedFloat32Array, start: int, count: int, freq: float,
		duty: float, volume: float, decay: float) -> void:
	var attack := int(ATTACK * RATE)
	var release := int(RELEASE * RATE)
	var inc := freq / RATE
	var phase := 0.0
	count = mini(count, mix.size() - start)
	for i in count:
		var env := 1.0 - decay * i / count
		if i < attack:
			env *= float(i) / attack
		elif i > count - release:
			env *= float(count - i) / release
		var wave: float
		if duty < 0.0:
			wave = 4.0 * absf(phase - 0.5) - 1.0
		else:
			wave = 1.0 if phase < duty else -1.0
		mix[start + i] += wave * volume * env
		phase += inc
		if phase >= 1.0:
			phase -= 1.0


## The hi-hat on every HAT of hits, repeated until total sixteenths.
static func _add_hats(mix: PackedFloat32Array, hits: Array, total: int,
		step_frames: float) -> void:
	if hits.is_empty():
		return
	var hat := _hat_sound()
	var step := 0
	var index := 0
	while step < total:
		var hit: Array = hits[index % hits.size()]
		if hit[0] is String:
			var start := int(step * step_frames)
			for i in mini(hat.size(), mix.size() - start):
				mix[start + i] += hat[i]
		step += int(hit[1])
		index += 1


## One hi-hat hit, computed once: noise that fades out fast.
static func _hat_sound() -> PackedFloat32Array:
	if not _hat.is_empty():
		return _hat
	var rng := RandomNumberGenerator.new()
	rng.seed = NOISE_SEED
	var count := int(HAT_TIME * RATE)
	_hat.resize(count)
	for i in count:
		var fade := 1.0 - float(i) / count
		_hat[i] = rng.randf_range(-1.0, 1.0) * 0.6 * fade * fade * HAT_VOLUME
	return _hat
