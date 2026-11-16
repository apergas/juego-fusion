class_name JarBuilder extends RefCounted
## Constructor: static; builds the scene of the jar for its caller and keeps no state but the
## shared physics material: the light, the backdrop (the purple gradient and its slow motes of
## light), the jar (its invisible walls and floor, its glass frame and back), the orthographic
## camera, thin lines (the danger line, the aim line) and their materials. The colours are tokens
## of the game's layer (scene-*, jar-*...), read with UiTokens.color().

## The jar's glass back, behind every creature (the biggest is 1.48 m round).
const BACK_Z := -1.8
## Lines and effects drawn in front of every creature.
const FRONT_Z := 1.7
const BACKDROP_Z := -6.0
const BACKDROP_SIZE := Vector2(40.0, 26.0)
## The glass frame seen around the jar, and its depth.
const FRAME := 0.18
const FRAME_DEPTH := 0.5
## The invisible walls and floor: thick, and tall enough that nothing jumps out.
const COLLIDER := 1.0
const COLLIDER_HEIGHT := 16.0
const COLLIDER_DEPTH := 2.0
const CAMERA_Z := 20.0
const LIGHT_ROTATION := Vector3(-40.0, -25.0, 0.0)
const LIGHT_ENERGY := 1.1
const AMBIENT_ENERGY := 0.55
const MOTES := 24
const MOTE_LIFETIME := 12.0
const MOTE_AREA := Vector3(6.0, 7.0, 0.0)
const GRADIENT_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 top_color : source_color;
uniform vec4 bottom_color : source_color;
void fragment() {
	ALBEDO = mix(top_color.rgb, bottom_color.rgb, UV.y);
}
"""

static var _physics: PhysicsMaterial


## The light, the gradient behind everything and (with motes) the floating motes of light.
static func backdrop(root: Node3D, motes := true) -> void:
	light(root)
	var quad := QuadMesh.new()
	quad.size = BACKDROP_SIZE
	var shader := Shader.new()
	shader.code = GRADIENT_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("top_color", UiTokens.color(&"scene-top"))
	material.set_shader_parameter("bottom_color", UiTokens.color(&"scene-bottom"))
	var back := MeshInstance3D.new()
	back.mesh = quad
	back.material_override = material
	back.position = Vector3(0.0, JarSpec.VIEW_CENTER_Y, BACKDROP_Z)
	root.add_child(back)
	if motes:
		root.add_child(_motes())


## The sun and the ambient light the creatures are seen with; clear leaves the background
## transparent (a CreatureView's own world).
static func light(root: Node, clear := false) -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR if clear else Environment.BG_COLOR
	environment.background_color = UiTokens.color(&"scene-bottom")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = AMBIENT_ENERGY
	var world := WorldEnvironment.new()
	world.environment = environment
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = LIGHT_ROTATION
	sun.light_energy = LIGHT_ENERGY
	root.add_child(sun)


## The jar: invisible static walls and floor with the creatures' physics material, the dark
## glass back and the light frame.
static func jar(root: Node3D) -> void:
	var half := JarSpec.WIDTH / 2.0
	root.add_child(_wall(Vector3(JarSpec.WIDTH + 2.0 * COLLIDER, COLLIDER, COLLIDER_DEPTH),
		Vector3(0.0, -COLLIDER / 2.0, 0.0)))
	for side: float in [-1.0, 1.0]:
		root.add_child(_wall(Vector3(COLLIDER, COLLIDER_HEIGHT, COLLIDER_DEPTH),
			Vector3(side * (half + COLLIDER / 2.0), COLLIDER_HEIGHT / 2.0, 0.0)))
	root.add_child(_box(Vector3(JarSpec.WIDTH, JarSpec.HEIGHT, 0.02),
		Vector3(0.0, JarSpec.HEIGHT / 2.0, BACK_Z), unshaded(UiTokens.color(&"jar-back"))))
	var frame := StandardMaterial3D.new()
	frame.albedo_color = UiTokens.color(&"jar-frame")
	frame.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	frame.roughness = 0.3
	root.add_child(_box(Vector3(JarSpec.WIDTH + 2.0 * FRAME, FRAME, FRAME_DEPTH),
		Vector3(0.0, -FRAME / 2.0, 0.0), frame))
	for side: float in [-1.0, 1.0]:
		root.add_child(_box(Vector3(FRAME, JarSpec.HEIGHT + FRAME, FRAME_DEPTH),
			Vector3(side * (half + FRAME / 2.0), (JarSpec.HEIGHT - FRAME) / 2.0, 0.0), frame))


## The orthographic camera, head on, made current. The owner calls fit_camera() now and on
## every change of the window's size.
static func camera(root: Node3D) -> Camera3D:
	var result := Camera3D.new()
	result.projection = Camera3D.PROJECTION_ORTHOGONAL
	result.keep_aspect = Camera3D.KEEP_HEIGHT
	result.size = JarSpec.VIEW_HEIGHT
	result.near = 0.1
	result.far = 50.0
	result.position = Vector3(0.0, JarSpec.VIEW_CENTER_Y, CAMERA_Z)
	root.add_child(result)
	result.current = true
	return result


static func fit_camera(view_camera: Camera3D) -> void:
	var view := view_camera.get_viewport().get_visible_rect().size
	view_camera.size = JarSpec.camera_size(view.x / view.y)


## A thin flat bar facing the camera (the danger line, the aim line), unlit, in color.
static func line(width: float, height: float, color: Color) -> MeshInstance3D:
	return _box(Vector3(width, height, 0.02), Vector3.ZERO, unshaded(color))


static func unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Friction and bounce of JarSpec, shared by the creatures and the jar.
static func physics_material() -> PhysicsMaterial:
	if _physics == null:
		_physics = PhysicsMaterial.new()
		_physics.friction = JarSpec.FRICTION
		_physics.bounce = JarSpec.BOUNCE
	return _physics


static func _box(size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	return node


static func _wall(size: Vector3, at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.physics_material_override = physics_material()
	body.position = at
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	body.add_child(shape)
	return body


## Motes of light that rise slowly behind the jar, fading in and out.
static func _motes() -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.amount = MOTES
	particles.lifetime = MOTE_LIFETIME
	particles.preprocess = MOTE_LIFETIME
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = MOTE_AREA
	particles.direction = Vector3.UP
	particles.spread = 25.0
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.08
	particles.initial_velocity_max = 0.22
	particles.scale_amount_min = 0.04
	particles.scale_amount_max = 0.1
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	fade.colors = PackedColorArray([Color.TRANSPARENT, Color.WHITE, Color.WHITE,
		Color.TRANSPARENT])
	particles.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var material := unshaded(UiTokens.color(&"scene-mote"))
	material.vertex_color_use_as_albedo = true
	quad.material = material
	particles.mesh = quad
	particles.position = Vector3(0.0, JarSpec.VIEW_CENTER_Y, BACKDROP_Z + 1.0)
	return particles
