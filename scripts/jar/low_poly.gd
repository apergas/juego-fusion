class_name LowPoly extends RefCounted
## Constructor: static; builds faceted low-poly meshes for its caller and keeps no state. A blob
## is a lathe of rings taken from a side profile, every other ring turned half a segment, with
## one normal per face (flat shading), so it reads as a cut gem instead of a smooth sphere: the
## creatures' balls, the seta's cap and the golem's moss are blobs. The primitives (sphere, cone,
## cylinder) are their eyes, ears, horns and wings. Copied from Villaclaro's
## scripts/battle/low_poly.gd, trimmed to what the creatures use.


## Lathe of profile (x = radius, y = height, bottom to top) around +Y with segments sides and
## flat normals.
static func blob(profile: Array[Vector2], segments: int) -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for i in profile.size():
		var ring := PackedVector3Array()
		var offset := 0.5 * (i % 2)
		for s in segments:
			var angle := TAU * (s + offset) / segments
			ring.append(Vector3(sin(angle) * profile[i].x, profile[i].y,
				cos(angle) * profile[i].x))
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Smooth group 0xFFFFFFFF: no vertex is shared, every face keeps its own normal.
	st.set_smooth_group(0xFFFFFFFF)
	for i in rings.size() - 1:
		var lo := rings[i]
		var hi := rings[i + 1]
		for s in segments:
			var n := (s + 1) % segments
			_triangle(st, lo[s], hi[s], lo[n])
			_triangle(st, lo[n], hi[s], hi[n])
	st.generate_normals()
	return st.commit()


## A sphere of radius with 10 sides and 5 rings.
static func sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	return mesh


## A cylinder of radius and height with 8 sides, centred on its middle.
static func cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	return mesh


## A cone pointing up +Y: a cylinder whose top radius is 0.
static func cone(radius: float, height: float) -> CylinderMesh:
	var mesh := cylinder(radius, height)
	mesh.top_radius = 0.0
	return mesh


## Skips triangles that collapse at the profile's tips (radius 0).
static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if a.is_equal_approx(b) or b.is_equal_approx(c) or a.is_equal_approx(c):
		return
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
