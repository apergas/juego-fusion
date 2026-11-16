class_name DangerLine extends Node3D
## Node, a piece of Jar: the danger line across the jar at JarSpec.LINE_Y, in front of the
## creatures. Calm, it is a faint line (danger-line); while Danger counts (set_alert() with the
## fraction of Danger.LOSE_TIME gone) it blinks in danger-line-alert, faster the less is left
## (Danger.blink_hz()). Jar calls step() every physics frame.

const THICKNESS := 0.05
## The alpha of the blink's dark half.
const DIM := 0.25

var _fraction := 0.0
var _phase := 0.0
var _material: StandardMaterial3D


func _ready() -> void:
	var bar := JarBuilder.line(JarSpec.WIDTH, THICKNESS, UiTokens.color(&"danger-line"))
	_material = bar.material_override as StandardMaterial3D
	position = Vector3(0.0, JarSpec.LINE_Y, JarBuilder.FRONT_Z)
	add_child(bar)


func set_alert(fraction: float) -> void:
	if fraction <= 0.0 and _fraction > 0.0:
		_phase = 0.0
		_material.albedo_color = UiTokens.color(&"danger-line")
	_fraction = fraction


func step(delta: float) -> void:
	if _fraction <= 0.0:
		return
	_phase += delta * Danger.blink_hz(_fraction) * TAU
	var color := UiTokens.color(&"danger-line-alert")
	color.a = lerpf(DIM, 1.0, 0.5 + 0.5 * cos(_phase))
	_material.albedo_color = color
