class_name CreatureLooks extends RefCounted
## Constructor: static; builds the figure of a creature from its CreatureData for its caller
## (CreatureBody, DropAim) and keeps no state but a cache of materials. Every creature is a
## faceted ball (LowPoly.blob) facing the camera (+Z) with its eyes. silhouette paints every part
## in creature-silhouette, unlit.

const SEGMENTS := 10
const RINGS := 6
const EYE_COLOR := Color("#1a1020")
const SHINE_COLOR := Color.WHITE
const ROUGHNESS := 0.85

static var _materials := {}


static func build(data: CreatureData, silhouette := false) -> Node3D:
	var root := Node3D.new()
	var r := data.radius
	_add(root, LowPoly.blob(_ball(r), SEGMENTS), _paint(data.color, silhouette))
	_eyes(root, r, 0.12, silhouette)
	return root


## A ball's side profile, bottom to top, RINGS + 1 rings.
static func _ball(radius: float) -> Array[Vector2]:
	var profile: Array[Vector2] = []
	for i in RINGS + 1:
		var angle := PI * i / RINGS
		profile.append(Vector2(radius * sin(angle), -radius * cos(angle)))
	return profile


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
