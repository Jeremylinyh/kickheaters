extends Node3D

@export var movementSpeed : float = 100


func _process(delta: float) -> void:
	var moveDirection : Vector2 = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var movingInDirec : Vector2 = moveDirection*delta * movementSpeed
	var moveUpDown : float = Input.get_axis("move_camera_down","move_camera_up")
	var rotateCamera : float = Input.get_axis("rotate_camera_left","rotate_camera_right")
	if (Input.is_action_pressed("speed_up_camera")):
		position += 2 * Vector3(movingInDirec.x,moveUpDown,movingInDirec.y)
		rotation += Vector3(0,rotateCamera/45,0)
	else:	
		position += Vector3(movingInDirec.x,moveUpDown,movingInDirec.y)
		rotation += Vector3(0,rotateCamera/90,0)
