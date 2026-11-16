class_name CreatureView extends SubViewportContainer
## Node: one creature drawn in its own little 3D world, for the interface: the HUD's «Siguiente»
## and the bestiary's cards. Orthographic and head on, lit like the jar (JarBuilder.light()) over a
## transparent background; with spin it turns slowly around its vertical axis. A silhouette is
## unlit, in creature-silhouette (CreatureLooks).

const SPIN_SPEED := 0.9
## The camera shows this many radii: room for the ears, the wings and the horns.
const FRAME := 3.6
## The camera looks a little above the centre (the Gota's tip, the ears).
const LOOK_UP := 0.1

var spin := false
var _view: SubViewport
var _camera: Camera3D
var _model: Node3D


func _init(side: int) -> void:
	stretch = true
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.transparent_bg = true
	_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_view)
	JarBuilder.light(_view, true)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.position = Vector3(0.0, 0.0, 10.0)
	_view.add_child(_camera)
	_camera.current = true


func _process(delta: float) -> void:
	if spin and _model:
		_model.rotation.y += SPIN_SPEED * delta


func show_creature(data: CreatureData, silhouette := false) -> void:
	if _model:
		_model.queue_free()
	_model = CreatureLooks.build(data, silhouette)
	_view.add_child(_model)
	_camera.size = data.radius * FRAME
	_camera.position.y = data.radius * LOOK_UP
