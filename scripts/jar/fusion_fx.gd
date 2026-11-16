class_name FusionFx extends Node3D
## Node, a piece of Jar: what a merge looks like. pop() gives the new creature its little jump
## (its figure from POP_FROM to POP_OVER to full size in POP_TIME; its collider grows on its own,
## CreatureBody.grow()), burst() throws particles of its colour, flash() is the bigger burst and
## glow of the two biggest vanishing, and points() shows the points won, rising and fading. All
## in front of the creatures; each effect frees itself (and stops while the tree is paused).

const POP_FROM := 0.6
const POP_OVER := 1.1
const POP_TIME := 0.2
const BURST := 14
const BURST_SPEED := 3.0
const FLASH := 40
const FLASH_SPEED := 6.0
const FLASH_TIME := 0.3
const FLASH_GROWTH := 1.6
const PARTICLE_LIFE := 0.5
const PARTICLE_SIZE := 0.07
const PARTICLE_GRAVITY := Vector3(0.0, -6.0, 0.0)
const RISE := 0.8
const RISE_TIME := 0.8
## The Label3D's metres per font pixel: title-m about as big as the HUD's text (UI_SCALE included).
const LABEL_PIXEL := 0.013


func pop(figure: Node3D) -> void:
	figure.scale = Vector3.ONE * POP_FROM
	var tween := figure.create_tween()
	tween.tween_property(figure, "scale", Vector3.ONE * POP_OVER, POP_TIME * 0.6)
	tween.tween_property(figure, "scale", Vector3.ONE, POP_TIME * 0.4)


func burst(at: Vector3, color: Color, amount := BURST, speed := BURST_SPEED) -> void:
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = PARTICLE_LIFE
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.flatness = 0.0
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.gravity = PARTICLE_GRAVITY
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.2
	particles.color = color
	var mesh := LowPoly.sphere(PARTICLE_SIZE)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.mesh = mesh
	particles.position = Vector3(at.x, at.y, JarBuilder.FRONT_Z)
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(PARTICLE_LIFE + 0.2, false).timeout.connect(particles.queue_free)


## Two of the last level (radius) vanish at at: a big burst in the accent and a glow that grows
## and fades.
func flash(at: Vector3, radius: float) -> void:
	burst(at, UiTokens.color(&"text-accent"), FLASH, FLASH_SPEED)
	var glow := MeshInstance3D.new()
	glow.mesh = LowPoly.sphere(radius)
	var material := JarBuilder.unshaded(UiTokens.color(&"text-primary"))
	glow.material_override = material
	glow.position = Vector3(at.x, at.y, JarBuilder.FRONT_Z - radius)
	add_child(glow)
	var tween := glow.create_tween().set_parallel()
	tween.tween_property(glow, "scale", Vector3.ONE * FLASH_GROWTH, FLASH_TIME)
	tween.tween_property(material, "albedo_color:a", 0.0, FLASH_TIME)
	tween.chain().tween_callback(glow.queue_free)


## "+30" over at, rising RISE in RISE_TIME and fading.
func points(at: Vector3, value: int) -> void:
	var label := Label3D.new()
	label.text = "+%d" % value
	UiTheme.style_3d(label, &"title-m", &"text-accent", UiTokens.OUTLINE_M)
	label.pixel_size = LABEL_PIXEL
	label.no_depth_test = true
	label.position = Vector3(at.x, at.y, JarBuilder.FRONT_Z + 0.1)
	add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", at.y + RISE, RISE_TIME)
	tween.tween_property(label, "modulate:a", 0.0, RISE_TIME).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "outline_modulate:a", 0.0, RISE_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
