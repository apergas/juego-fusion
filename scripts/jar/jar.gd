class_name Jar extends Node3D
## Node: the jar of one round, built by JarBuilder, with its backdrop and its camera. Game
## creates a new one for every round.

var camera: Camera3D


func _ready() -> void:
	JarBuilder.backdrop(self)
	JarBuilder.jar(self)
	camera = JarBuilder.camera(self)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	JarBuilder.fit_camera(camera)
