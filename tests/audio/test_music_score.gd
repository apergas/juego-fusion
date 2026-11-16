extends GutTest
## MusicScore: every bar of the two tunes adds up, every note can be read, the voices' loops line
## up, and each tune stays calm and short enough for the web to render it quickly.

const VOICES := ["lead", "bass", "drums"]


func test_a4_is_440_hz_and_each_semitone_is_a_twelfth_of_an_octave() -> void:
	assert_almost_eq(MusicScore.frequency("A4"), 440.0, 0.001)
	assert_almost_eq(MusicScore.frequency("A5"), 880.0, 0.001)
	assert_almost_eq(MusicScore.frequency("C4"), 261.626, 0.01)
	assert_almost_eq(MusicScore.frequency("F#4") / MusicScore.frequency("F4"),
		pow(2.0, 1.0 / 12.0), 0.0001)
	assert_eq(MusicScore.frequency("H4"), 0.0, "no such note")
	assert_eq(MusicScore.frequency("C"), 0.0, "no octave")


func test_every_bar_of_every_voice_lasts_a_bar() -> void:
	for id in MusicScore.IDS:
		for voice: String in VOICES:
			for bar: String in MusicScore.TRACKS[id][voice]:
				assert_eq(MusicScore.steps(MusicScore.parse([bar])), MusicScore.BAR,
					"%s %s: %s" % [id, voice, bar])


func test_every_note_can_be_read_and_the_drums_only_hit_the_hat() -> void:
	for id in MusicScore.IDS:
		for voice: String in VOICES:
			for bar: String in MusicScore.TRACKS[id][voice]:
				for token in bar.split(" ", false):
					var note := token.split("/")[0]
					if note == MusicScore.REST:
						continue
					if voice == "drums":
						assert_eq(note, MusicScore.HAT, "%s: %s" % [id, token])
					else:
						assert_gt(MusicScore.frequency(note), 0.0, "%s %s: %s" % [id, voice, token])


func test_the_voices_loops_line_up() -> void:
	for id in MusicScore.IDS:
		var track: Dictionary = MusicScore.TRACKS[id]
		var lead := MusicScore.steps(MusicScore.parse(track.lead))
		assert_gt(lead, 0, id)
		for voice: String in ["bass", "drums"]:
			var other := MusicScore.steps(MusicScore.parse(track[voice]))
			if other > 0:
				assert_eq(lead % other, 0, "%s %s" % [id, voice])


func test_each_tune_is_calm_and_short() -> void:
	for id in MusicScore.IDS:
		assert_between(int(MusicScore.TRACKS[id].bpm), 60, 110, id)
		assert_between(MusicScore.seconds(id), 10.0, 40.0, id)


func test_parse_reads_notes_rests_and_hits_with_their_lengths() -> void:
	var notes := MusicScore.parse(["A4/4 r/4 h/8"])
	assert_eq(notes.size(), 3)
	assert_almost_eq(float(notes[0][0]), 440.0, 0.001)
	assert_eq(notes[0][1], 4)
	assert_eq(notes[1][0], 0.0, "a rest is 0.0")
	assert_eq(notes[1][1], 4)
	assert_eq(notes[2][0], MusicScore.HAT, "a hit is the HAT string")
	assert_true(notes[2][0] is String)
	assert_eq(notes[2][1], 8)


func test_a_sixteenth_and_a_tune_last_what_the_bpm_says() -> void:
	assert_almost_eq(MusicScore.step_seconds(120), 0.125, 0.0001)
	for id in MusicScore.IDS:
		var track: Dictionary = MusicScore.TRACKS[id]
		var expected: float = track.lead.size() * MusicScore.BAR * 60.0 / int(track.bpm) / 4.0
		assert_almost_eq(MusicScore.seconds(id), expected, 0.0001, id)
