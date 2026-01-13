extends Node3D

@export var movementSpeed : float = 100

@export var zoomSpeed : float = 3.0

func _process(delta: float) -> void:
	var moveDirection : Vector2 = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var movingInDirec : Vector2 = moveDirection*delta * (movementSpeed + position.y)
	var deltaH : float = Input.get_axis("zoom_in","zoom_out") * zoomSpeed * delta * 60.0
	
	position += Vector3(movingInDirec.x,deltaH,movingInDirec.y)
