class_name JarSpec extends RefCounted
## The jar's measures and the physics numbers of its creatures, in metres of the world. Pure: no
## nodes. The floor is at y 0 and the walls at x ±WIDTH/2. The camera looks at x 0, y
## VIEW_CENTER_Y and always shows at least VIEW_WIDTH × VIEW_HEIGHT (camera_size()): the jar
## and its frame, with room for the HUD above it, fit any phone held upright.

## The inside of the jar.
const WIDTH := 6.0
const HEIGHT := 8.4
## The danger line, measured from the floor.
const LINE_Y := 7.4
## Where the creature waiting to fall hangs.
const WAIT_Y := 8.0
## A creature counts as settled once it has been this long in the jar (dropped or made by a merge).
const SETTLE_TIME := 1.0
## What the camera always shows: the jar and its frame across, and 3.2 m of HUD room over the
## waiting creature plus 1.35 m under the floor.
const VIEW_WIDTH := 7.6
const VIEW_HEIGHT := 13.5
const VIEW_CENTER_Y := 5.1
## Physics: friction and bounce of the creatures and the jar (the spec's starting values),
## the creatures' angular damping (they roll a little and settle soon).
const FRICTION := 0.4
const BOUNCE := 0.1
const ANGULAR_DAMP := 1.0
## A creature of this radius (the Gota de rocío) weighs 1; the mass grows with the square of the
## radius (the area in the plane).
const MASS_RADIUS := 0.3
## A merged creature's collider grows from GROW_FROM times its radius to the whole of it in
## GROW_TIME seconds: it pushes its neighbours aside instead of kicking them.
const GROW_FROM := 0.6
const GROW_TIME := 0.2


## x kept inside the jar for a creature of radius.
static func clamp_x(x: float, radius: float) -> float:
	return clampf(x, -WIDTH / 2.0 + radius, WIDTH / 2.0 - radius)


## The orthographic camera's height (KEEP_HEIGHT) for a screen of aspect (width / height).
static func camera_size(aspect: float) -> float:
	return maxf(VIEW_HEIGHT, VIEW_WIDTH / aspect)


static func mass(radius: float) -> float:
	return pow(radius / MASS_RADIUS, 2.0)
