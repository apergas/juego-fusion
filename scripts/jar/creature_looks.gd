class_name CreatureLooks extends RefCounted
## Constructor: static; builds the figure of a creature from its CreatureData for its caller
## (CreatureBody, DropAim, CreatureView, the PWA icon tool) and keeps no state but a cache of
## materials. Every creature is a faceted ball (LowPoly.blob) facing the camera (+Z) with two
## eyes, plus the one or two features of its look (data.look), in data.accent:
## - gota: a drop, its tip up;
## - slime: a squashed ball with a mouth; slime_mejillas: the same with pink cheeks;
## - seta: a cream ball (accent) under a red cap (color) with cream dots;
## - murcielago: two small wings and two pointed ears;
## - lobo: two ears and a light snout with a dark nose;
## - golem: a rougher stone ball with moss on top;
## - dragon: two horns and two small wings.
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

static var _materials := {}


static func build(data: CreatureData, silhouette := false) -> Node3D:
	var root := Node3D.new()
	var r := data.radius
	var main := _paint(data.color, silhouette)
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
			_wings(root, r, 0.34, 1.0, 0.5, 0.62, second)
			_ears(root, r, 0.17, 0.55, 0.28, 6.0, main)
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
			_ears(root, r, 0.16, 0.6, 0.28, 8.0, second)
			_wings(root, r, 0.3, 0.85, 0.5, 0.55, second)
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


## Two flat cones for wings, folded up and back behind the body: none reaches past the radius
## sideways, so nothing pokes through the jar's wall.
static func _wings(root: Node3D, r: float, radius: float, length: float, x: float,
		y: float, material: Material) -> void:
	for side: float in [-1.0, 1.0]:
		_add(root, LowPoly.cone(radius * r, length * r), material,
			Vector3(side * x * r, y * r, -0.1 * r), Vector3(0.0, 0.0, -side * 75.0),
			Vector3(1.0, 1.0, 0.35))


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
