class_name CreatureBody extends RigidBody3D
## Node: one creature in the jar, a RigidBody3D with a sphere of its radius and its figure
## (CreatureLooks). Locked on the Z axis (depth) and turning only around it, so it rolls without
## leaving the plane; mass, friction, bounce and damping are JarSpec's. It reports its contacts
## (contact monitor) for MergeWatcher. age counts the seconds it has been in the jar
## (Jar.step()); merged marks it taken by a merge (it is about to go).

const MAX_CONTACTS := 8

var data: CreatureData
var age := 0.0
var merged := false
var figure: Node3D
var _sphere: SphereShape3D


func _init(creature: CreatureData) -> void:
	data = creature
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	mass = JarSpec.mass(data.radius)
	angular_damp = JarSpec.ANGULAR_DAMP
	physics_material_override = JarBuilder.physics_material()
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = MAX_CONTACTS
	_sphere = SphereShape3D.new()
	_sphere.radius = data.radius
	var shape := CollisionShape3D.new()
	shape.shape = _sphere
	add_child(shape)
	figure = CreatureLooks.build(data)
	add_child(figure)


## The height of its top: what Danger compares with the line.
func top() -> float:
	return position.y + data.radius


## A creature just made by a merge grows into its place: its collider from JarSpec.GROW_FROM
## times its radius to the whole of it in JarSpec.GROW_TIME, so it pushes its neighbours aside
## instead of kicking them.
func grow() -> void:
	_sphere.radius = data.radius * JarSpec.GROW_FROM
	create_tween().tween_property(_sphere, "radius", data.radius, JarSpec.GROW_TIME)
