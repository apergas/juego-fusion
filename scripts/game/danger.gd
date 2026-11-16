class_name Danger extends RefCounted
## When the jar overflows. Pure: no nodes; Game keeps the count (GameState.danger_time). A settled
## creature (JarSpec.SETTLE_TIME in the jar) whose top is over JarSpec.LINE_Y starts the count;
## LOSE_TIME seconds in a row lose the round, and the count goes back to 0 the moment none is
## over (a merge, or one that rolls down). While it counts the line blinks, from BLINK_SLOW to
## BLINK_FAST times a second as the time runs out.

const LOSE_TIME := 3.0
const BLINK_SLOW := 2.0
const BLINK_FAST := 8.0


## top: the highest top of the settled creatures (-INF for none).
static func is_over(top: float) -> bool:
	return top > JarSpec.LINE_Y


static func step(count: float, over: bool, delta: float) -> float:
	return count + delta if over else 0.0


## How much of LOSE_TIME has gone, 0..1.
static func fraction(count: float) -> float:
	return clampf(count / LOSE_TIME, 0.0, 1.0)


static func lost(count: float) -> bool:
	return count >= LOSE_TIME


## Blinks a second at fraction of the count.
static func blink_hz(at_fraction: float) -> float:
	return lerpf(BLINK_SLOW, BLINK_FAST, at_fraction)
