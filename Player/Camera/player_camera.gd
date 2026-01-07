extends Node3D

@export var movementSpeed : float = 100

func _process(delta: float) -> void:
	var moveDirection : Vector2 = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var movingInDirec : Vector2 = moveDirection*delta * movementSpeed
	position += Vector3(movingInDirec.x,0.0,movingInDirec.y)
