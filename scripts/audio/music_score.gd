class_name MusicScore extends RefCounted
## The game's two tunes, written as note tables, and how to read them. Pure: no nodes and no sound
## (MusicLibrary renders them). The pattern of Villaclaro's MusicLibrary, with this game's own
## tunes: TITLE, calm, for the title, and JAR, a little livelier, for the jar; both loop. Each
## voice is a list of bars of BAR sixteenths; a bar is tokens separated by spaces: a note with its
## octave ("C5", "F#4", sharps only) or REST, then "/" and its length in sixteenths ("A5/4" is a
## quarter note). The drums' only hit is HAT (a soft hi-hat). The lead sets the tune's length; the
## bass and the drums repeat from the start until they fill it.

const TITLE := "title"
const JAR := "jar"
const IDS: Array[String] = [TITLE, JAR]
## Sixteenths in a bar (4/4).
const BAR := 16
const REST := "r"
const HAT := "h"
const SEMITONES := {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7,
	"G#": 8, "A": 9, "A#": 10, "B": 11}
## bpm, the duty of the lead's square wave and the three voices of each tune.
const TRACKS := {
	# Calm, in C major, no drums.
	TITLE: {
		"bpm": 84, "duty": 0.25,
		"lead": [
			"E5/4 G5/4 A5/4 G5/4", "E5/6 D5/2 C5/8", "D5/4 E5/4 G5/4 E5/4", "D5/12 r/4",
			"E5/4 G5/4 C6/4 B5/4", "A5/6 G5/2 E5/8", "F5/4 E5/4 D5/4 B4/4", "C5/12 r/4",
		],
		"bass": [
			"C3/8 G2/8", "A2/8 E2/8", "F2/8 C3/8", "G2/8 D3/8",
			"C3/8 G2/8", "F2/8 A2/8", "D2/8 G2/8", "C3/12 r/4",
		],
		"drums": [],
	},
	# A little livelier, in G major, a hi-hat on the off-beats.
	JAR: {
		"bpm": 100, "duty": 0.25,
		"lead": [
			"G4/2 B4/2 D5/4 B4/4 D5/4", "E5/4 D5/4 B4/8", "C5/2 E5/2 G5/4 E5/4 C5/4",
			"D5/12 r/4", "B4/2 D5/2 G5/4 F#5/4 E5/4", "D5/4 B4/4 A4/8",
			"C5/4 A4/4 F#4/4 A4/4", "G4/12 r/4",
		],
		"bass": [
			"G2/4 D3/4 G2/4 D3/4", "E2/4 B2/4 E2/4 B2/4", "C2/4 G2/4 C2/4 G2/4",
			"D2/4 A2/4 D2/4 A2/4", "G2/4 D3/4 G2/4 D3/4", "B1/4 F#2/4 B1/4 F#2/4",
			"A1/4 E2/4 D2/4 A2/4", "G2/8 D2/8",
		],
		"drums": ["r/4 h/4 r/4 h/4"],
	},
}


## Bars -> [[pitch in Hz (0.0 a rest) or HAT, length in sixteenths], ...]. A token without its
## length lasts 0 (and its bar comes out short).
static func parse(bars: Array) -> Array:
	var notes := []
	for bar: String in bars:
		for token in bar.split(" ", false):
			var parts := token.split("/")
			var length := parts[1].to_int() if parts.size() == 2 else 0
			var name := parts[0]
			if name == REST:
				notes.append([0.0, length])
			elif name == HAT:
				notes.append([HAT, length])
			else:
				notes.append([frequency(name), length])
	return notes


## The frequency in Hz of a note with its octave ("A4" is 440); 0.0 for one it can't read.
static func frequency(name: String) -> float:
	var note := name.left(-1)
	var octave := name.right(1)
	if not SEMITONES.has(note) or not octave.is_valid_int():
		return 0.0
	var midi := 12 * (octave.to_int() + 1) + int(SEMITONES[note])
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## The sixteenths parsed notes last.
static func steps(notes: Array) -> int:
	var total := 0
	for note: Array in notes:
		total += int(note[1])
	return total


## Seconds of one sixteenth at bpm.
static func step_seconds(bpm: int) -> float:
	return 60.0 / bpm / 4.0


## Seconds one loop of the tune id lasts (its lead).
static func seconds(id: String) -> float:
	var track: Dictionary = TRACKS[id]
	return steps(parse(track.lead)) * step_seconds(track.bpm)
