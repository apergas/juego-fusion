class_name CreatureLooks extends RefCounted
## Constructor: static; builds the figure of a creature from its CreatureData for its caller
## (CreatureBody, DropAim, CreatureView, the PWA icon tool) and keeps no state but a cache of
## materials. Every creature is a faceted ball (LowPoly.blob) facing the camera (+Z) with two
## eyes, plus the one or two features of its look (data.look), in data.accent:
## - gota: a drop, its tip up;
## - slime: a squashed ball with a mouth; slime_mejillas: the same with pink cheeks;
## - seta: a cream ball (accent) under a red cap (color) with cream dots;
## - murcielago: two big dark wings rising in a V from the shoulders;
## - lobo: two ears and a light snout with a dark nose;
## - golem: a rougher stone ball with moss on top;
## - dragon: two small horns between two big darker wings rising in a V from the shoulders.
## Sizes are fractions of the radius, so a figure reads the same at any size. Seen head on, from
## far and on a small screen. silhouette paints every part in creature-silhouette, unlit (the
## bestiary's undiscovered card).

const SEGMENTS := 10
## The golem's stone has fewer sides: it looks rougher.
const ROCK_SEGMENTS := 7
const RINGS := 6
const EYE_COLOR := Color("#1a1020")
const SHINE_COLOR := Color.WHITE
const ROUGHNESS := 0.85
## A wing's outline, from the shoulder round to its tip and down its scalloped edge.
const WING_EDGE: Array[Vector2] = [Vector2(0.0, 0.95), Vector2(0.9, 1.85), Vector2(0.9, 1.4),
		Vector2(0.75, 1.5), Vector2(0.72, 1.2), Vector2(0.52, 1.3), Vector2(0.4, 1.0)]

static var _materials := {}


static func build(data: CreatureData, silhouette := false) -> Node3D:
	var root := Node3D.new()
	var r := data.radius
	var main := _paint(data.color, silhouette)
	var main_color := data.color
	var second := _paint(data.accent, silhouette)
	var eye_y := 0.12
	match data.look:
		"gota":
			_add(root, LowPoly.blob(_drop(r), SEGMENTS), main)
		"slime", "slime_mejillas":
			_add(root, LowPoly.blob(_slime(r), SEGMENTS), main)
			_add(root, LowPoly.sphere(0.12 * r), _paint(EYE_COLOR, silhouette),
				Vector3(0.0, -0.3 * r, 0.9 * r), Vector3.ZERO, Vector3(1.6, 0.6, 0.5))
			if data.look == "slime_mejillas":
				for side: float in [-1.0, 1.0]:
					_add(root, LowPoly.sphere(0.13 * r), second,
						Vector3(side * 0.58 * r, -0.12 * r, 0.78 * r), Vector3.ZERO,
						Vector3(1.3, 0.7, 0.4))
		"seta":
			eye_y = -0.05
			_add(root, LowPoly.blob(_ball(r), SEGMENTS), second)
			_add(root, LowPoly.blob(_dome(1.0 * r, 0.75 * r), SEGMENTS), main,
				Vector3(0.0, 0.2 * r, 0.0))
			for dot: Vector3 in [Vector3(0.0, 0.82, 0.66), Vector3(-0.55, 0.52, 0.78),
					Vector3(0.55, 0.52, 0.78), Vector3(-0.84, 0.3, 0.45),
					Vector3(0.84, 0.3, 0.45)]:
				_add(root, LowPoly.sphere(0.12 * r), second, dot * r, Vector3.ZERO,
					Vector3(1.0, 0.8, 0.5))
		"murcielago":
			_add(root, LowPoly.blob(_ball(r), SEGMENTS), main)
			_wings(root, r, _paint(main_color.darkened(0.2), silhouette))
		"lobo":
			eye_y = 0.22
			_add(root, LowPoly.blob(_ball(r), SEGMENTS), main)
			_ears(root, r, 0.24, 0.6, 0.4, 8.0, main)
			_add(root, LowPoly.sphere(0.34 * r), second, Vector3(0.0, -0.18 * r, 0.82 * r),
				Vector3.ZERO, Vector3(1.2, 0.85, 1.0))
			_add(root, LowPoly.sphere(0.1 * r), _paint(EYE_COLOR, silhouette),
				Vector3(0.0, -0.08 * r, 1.13 * r))
		"golem":
			eye_y = 0.1
			_add(root, LowPoly.blob(_ball(r), ROCK_SEGMENTS), main)
			_add(root, LowPoly.blob(_dome(0.85 * r, 0.4 * r), SEGMENTS), second,
				Vector3(0.0, 0.62 * r, 0.0))
		"dragon":
			_add(root, LowPoly.blob(_ball(r), SEGMENTS), main)
			_ears(root, r, 0.18, 0.95, 0.17, 6.0, second)
			_wings(root, r, _paint(main_color.darkened(0.25), silhouette))
		_:
			_add(root, LowPoly.blob(_ball(r), SEGMENTS), main)
	_eyes(root, r, eye_y, silhouette)
	return root


## A ball's side profile, bottom to top, RINGS + 1 rings.
static func _ball(radius: float) -> Array[Vector2]:
	var profile: Array[Vector2] = []
	for i in RINGS + 1:
		var angle := PI * i / RINGS
		profile.append(Vector2(radius * sin(angle), -radius * cos(angle)))
	return profile


## A drop: the bottom half of a ball, then narrowing to a tip 1.4 radii up.
static func _drop(r: float) -> Array[Vector2]:
	return [Vector2(0.0, -r), Vector2(0.5 * r, -0.866 * r), Vector2(0.866 * r, -0.5 * r),
		Vector2(r, 0.0), Vector2(0.8 * r, 0.55 * r), Vector2(0.45 * r, 0.95 * r),
		Vector2(0.0, 1.4 * r)]


## A slime: wide and almost flat at the bottom, lower on top.
static func _slime(r: float) -> Array[Vector2]:
	return [Vector2(0.0, -r), Vector2(0.8 * r, -0.95 * r), Vector2(r, -0.5 * r),
		Vector2(0.98 * r, 0.05 * r), Vector2(0.8 * r, 0.55 * r), Vector2(0.45 * r, 0.88 * r),
		Vector2(0.0, 0.95 * r)]


## A dome of radius and height over a flat underside (the seta's cap, the golem's moss).
static func _dome(radius: float, height: float) -> Array[Vector2]:
	return [Vector2(0.0, 0.0), Vector2(radius, 0.0), Vector2(0.9 * radius, 0.4 * height),
		Vector2(0.62 * radius, 0.8 * height), Vector2(0.0, height)]


## Two cones for ears (or horns) on top, base radius and height in radii, at ±x, leaning up and slightly in.
static func _ears(root: Node3D, r: float, radius: float, height: float, x: float,
		lean: float, material: Material) -> void:
	for side: float in [-1.0, 1.0]:
		_add(root, LowPoly.cone(radius * r, height * r), material,
			Vector3(side * x * r, 0.92 * r, 0.0), Vector3(0.0, 0.0, side * lean))


## Two flat scalloped membranes for wings, behind the head: each rises from the upper shoulder to a
## tip up and out, with three scallops along its lower edge. WING_EDGE is the right wing's outline
## in radii (x out, y up), no point past 0.9 sideways (CreatureBody keeps the figure upright), so
## nothing pokes through the jar's wall.
static func _wings(root: Node3D, r: float, material: Material) -> void:
	for side: float in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(1, WING_EDGE.size() - 1):
			for corner: Vector2 in [WING_EDGE[0], WING_EDGE[i], WING_EDGE[i + 1]]:
				st.add_vertex(Vector3(side * corner.x * r, corner.y * r, -0.15 * r))
			for corner: Vector2 in [WING_EDGE[0], WING_EDGE[i + 1], WING_EDGE[i]]:
				st.add_vertex(Vector3(side * corner.x * r, corner.y * r, -0.15 * r))
		st.generate_normals()
		_add(root, st.commit(), material)


## Two eyes on the front of a ball of radius r, at height y (times r), each with its shine.
static func _eyes(root: Node3D, r: float, y: float, silhouette: bool) -> void:
	for side: float in [-1.0, 1.0]:
		_add(root, LowPoly.sphere(0.14 * r), _paint(EYE_COLOR, silhouette),
			Vector3(side * 0.33 * r, y * r, 0.86 * r), Vector3.ZERO, Vector3(1.0, 1.15, 0.6))
		_add(root, LowPoly.sphere(0.05 * r), _paint(SHINE_COLOR, silhouette),
			Vector3(side * 0.33 * r + 0.04 * r, y * r + 0.06 * r, 0.95 * r))


static func _add(root: Node3D, mesh: Mesh, material: Material, at := Vector3.ZERO,
		degrees := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.rotation_degrees = degrees
	node.scale = scale
	root.add_child(node)
	return node


## The lit material of color (cached), or the silhouette's.
static func _paint(color: Color, silhouette: bool) -> Material:
	if silhouette:
		return _material(UiTokens.color(&"creature-silhouette"), true)
	return _material(color, false)


static func _material(color: Color, flat: bool) -> Material:
	var key := "%s:%s" % [color.to_html(), flat]
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = ROUGHNESS
		if flat:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials[key] = material
	return _materials[key]
