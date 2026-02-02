@tool
extends Node3D

@export var trackSpacing : float = 0.75
@export var trackLength : float = 5.0
@export var trackWidth : float = 0.1

func _ready() -> void:
	# do not keep visuals in final product
	if not Engine.is_editor_hint() :
		var children = get_children()
		for child in children:
			child.queue_free()
	else :
		pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint() :
		$Left.position = Vector3(0.0,0.0,trackSpacing)
		$Right.position = Vector3(0.0,0.0,-trackSpacing)
	pass
