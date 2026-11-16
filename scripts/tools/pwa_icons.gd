extends SceneTree
## Renders the web build's icons, assets/pwa/icon_512.png, icon_180.png and icon_144.png: the
## Gota de rocío head on over the game's backdrop (JarBuilder, without the motes), filling
## ICON_FILL of the square's height, so a phone that cuts the icon to a circle keeps it whole.
## Run it not headless (it needs the renderer):
## ./tools/godot.cmd --path . --script res://scripts/tools/pwa_icons.gd
## then ./tools/godot.cmd --headless --path . --import. Excluded from the export (scripts/tools/*).

const SIZES: Array[int] = [512, 180, 144]
const ICON_FILL := 0.6
const OUT := "res://assets/pwa/icon_%d.png"
## The Gota is 2.4 radii tall (its tip is 1.4 up): the camera looks at its middle.
const GOTA_HEIGHT := 2.4
const GOTA_MIDDLE := 0.2


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/pwa"))
	var view := SubViewport.new()
	view.size = Vector2i(SIZES[0], SIZES[0])
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var stage := Node3D.new()
	view.add_child(stage)
	JarBuilder.backdrop(stage, false)
	var gota := Chain.data(1)
	var figure := CreatureLooks.build(gota)
	figure.position = Vector3(0.0, JarSpec.VIEW_CENTER_Y, 0.0)
	stage.add_child(figure)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = gota.radius * GOTA_HEIGHT / ICON_FILL
	camera.position = Vector3(0.0, JarSpec.VIEW_CENTER_Y + gota.radius * GOTA_MIDDLE, 20.0)
	stage.add_child(camera)
	camera.current = true
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	for side in SIZES:
		var copy := image.duplicate() as Image
		if side != SIZES[0]:
			copy.resize(side, side, Image.INTERPOLATE_LANCZOS)
		copy.save_png(OUT % side)
		print("Icono: %s" % (OUT % side))
	quit()
