extends Node3D

@export var movementSpeed : float = 100

func _process(delta: float) -> void:
	var moveDirection : Vector2 = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var movingInDirec : Vector2 = moveDirection*delta * movementSpeed
	var moveUpDown : float = Input.get_axis("move_camera_down","move_camera_up")
	if (Input.is_action_pressed("speed_up_camera")):
		position += 2 * Vector3(movingInDirec.x,moveUpDown,movingInDirec.y)
	else:	
		position += Vector3(movingInDirec.x,moveUpDown,movingInDirec.y)
