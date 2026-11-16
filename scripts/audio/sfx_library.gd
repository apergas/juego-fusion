class_name SfxLibrary extends RefCounted
## Sound effects in the style of sfxr, synthesized in code. Copied from Villaclaro's
## scripts/audio/sfx_library.gd, trimmed to this game's effects, with the 16-bit stream writer of
## Villaclaro's MusicLibrary (there is no music yet). Each effect is a Dictionary of parameters:
## wave ("square", "triangle" or "noise"), "from" and "to" (pitch in Hz at the start and at the
## end, slid linearly; for noise, how many new random values per second), "time" (seconds),
## "volume", "decay" (power of the fade-out: 1 is linear, higher fades sooner) and optional
## "notes" (pitches played one after the other, each "time" long, instead of the slide). The
## «¡plop!» of a merge has one effect per level made (plop_id()): the bigger the creature, the
## lower it sounds. build() caches each stream.

const CURSOR := "cursor"
const ACCEPT := "accept"
const CANCEL := "cancel"
const DROP := "drop"
const PRIZE := "prize"
const LOSE := "lose"
const SWAP := "swap"
const BREAK := "break"
const RATE := 22050
const NOISE_SEED := 4321
## Samples of fade-in at the start of every sound (no click).
const FADE_IN := 40
## The plop of level 2 starts here; each level up is PLOP_STEP times lower.
const PLOP_BASE_HZ := 760.0
const PLOP_STEP := 0.84
const PLOP_PREFIX := "plop_"
const SOUNDS := {
	CURSOR: {"wave": "square", "from": 880.0, "to": 880.0, "time": 0.04, "volume": 0.25,
		"decay": 1.0},
	ACCEPT: {"wave": "square", "notes": [660.0, 990.0], "time": 0.06, "volume": 0.3,
		"decay": 1.0},
	CANCEL: {"wave": "square", "from": 440.0, "to": 220.0, "time": 0.09, "volume": 0.3,
		"decay": 1.0},
	# A soft tick: the creature lets go.
	DROP: {"wave": "triangle", "from": 520.0, "to": 380.0, "time": 0.05, "volume": 0.25,
		"decay": 1.0},
	# Two dragons vanish: a bright arpeggio.
	PRIZE: {"wave": "triangle", "notes": [783.99, 987.77, 1174.66, 1567.98, 1975.53],
		"time": 0.06, "volume": 0.5, "decay": 0.5},
	# The jar overflows: a long fall, low.
	LOSE: {"wave": "square", "from": 330.0, "to": 70.0, "time": 0.9, "volume": 0.35,
		"decay": 0.8},
	# Cambiar: two quick notes up.
	SWAP: {"wave": "triangle", "notes": [523.25, 659.25], "time": 0.05, "volume": 0.3,
		"decay": 1.0},
	# Romper: a dry burst of noise, falling.
	BREAK: {"wave": "noise", "from": 3000.0, "to": 600.0, "time": 0.18, "volume": 0.35,
		"decay": 1.5},
}

static var _cache := {}


## The plop of a merge that makes a creature of level.
static func plop_id(level: int) -> String:
	return "%s%d" % [PLOP_PREFIX, level]


## Drops the cached streams, so none is left at exit (AudioDirector._exit_tree()).
static func clear_cache() -> void:
	_cache.clear()


static func build(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	var sound := _sound(id)
	var samples := PackedFloat32Array()
	if sound.has("notes"):
		for pitch: float in sound.notes:
			samples.append_array(_render(sound, pitch, pitch))
	else:
		samples = _render(sound, sound.from, sound.to)
	var stream := to_stream(samples)
	_cache[id] = stream
	return stream


## 16-bit mono stream at RATE from samples in -1..1 (clipped).
static func to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream


## The parameters of id: a plop is made for its level, the rest are in SOUNDS.
static func _sound(id: String) -> Dictionary:
	if id.begins_with(PLOP_PREFIX):
		var level := id.trim_prefix(PLOP_PREFIX).to_int()
		var base := PLOP_BASE_HZ * pow(PLOP_STEP, level - 2)
		return {"wave": "triangle", "from": base * 0.7, "to": base * 1.5,
			"time": 0.08 + 0.012 * level, "volume": 0.5, "decay": 1.6}
	return SOUNDS[id]


## One slide from pitch_from to pitch_to, sound.time long, fading out.
static func _render(sound: Dictionary, pitch_from: float, pitch_to: float) -> PackedFloat32Array:
	var count := int(float(sound.time) * RATE)
	var volume: float = sound.volume
	var decay: float = sound.decay
	var wave: String = sound.wave
	var rng := RandomNumberGenerator.new()
	rng.seed = NOISE_SEED
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase := 0.0
	var held := 0.0
	for i in count:
		var t := float(i) / count
		var pitch := lerpf(pitch_from, pitch_to, t)
		phase += pitch / RATE
		var wrapped := phase >= 1.0
		if wrapped:
			phase -= floorf(phase)
		var value: float
		match wave:
			"noise":
				if wrapped:
					held = rng.randf_range(-1.0, 1.0)
				value = held
			"triangle":
				value = 4.0 * absf(phase - 0.5) - 1.0
			_:
				value = 1.0 if phase < 0.5 else -1.0
		var env := pow(1.0 - t, decay)
		if i < FADE_IN:
			env *= float(i) / FADE_IN
		samples[i] = value * volume * env
	return samples
