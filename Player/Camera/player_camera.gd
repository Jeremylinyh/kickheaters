extends Node3D

@export var MovementSpeed : float = 100
var movementSpeed = MovementSpeed
@export var currentTerrain : TankTerrain

func _ready():
	moveToPlayer()
	
func _process(delta: float) -> void:
	var zoomScale : float = (1+(position.y/512))
	movementSpeed = zoomScale * MovementSpeed 
	
	var moveDirection : Vector2 = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var movingInDirec : Vector2 = moveDirection*delta * movementSpeed
	var moveUpDown : float = Input.get_axis("move_camera_down","move_camera_up")
	#var rotateCamera : float = Input.get_axis("rotate_camera_left","rotate_camera_right")
	if (Input.is_action_pressed("speed_up_camera")):
		position += 2 * Vector3(movingInDirec.x,moveUpDown * zoomScale,movingInDirec.y)
		#rotation += Vector3(0,rotateCamera/45,0)
	else:	
		position += Vector3(movingInDirec.x,moveUpDown * zoomScale,movingInDirec.y)
		#rotation += Vector3(0,rotateCamera/90,0)
	#print(currentTerrain.getHeightBilinear(Vector2(position.x,position.z)))
	position.y = max(position.y,currentTerrain.getHeightBilinear(Vector2(position.x,position.z)))

func moveToPlayer():
	position.x = $"../t72v2".position.x
	position.z = $"../t72v2".position.z
