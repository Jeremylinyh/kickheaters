extends Node3D

@export var MovementSpeed : float = 50
var movementSpeed = MovementSpeed
@export var currentTerrain : TankTerrain

func _process(delta: float) -> void:
	var zoomScale : float = (1+(position.y/512))
	movementSpeed = zoomScale * MovementSpeed 
	
	var moveDirection : Vector2 = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var movingInDirec : Vector2 = moveDirection*delta * movementSpeed
	var moveUpDown : float = Input.get_axis("move_camera_down","move_camera_up") * MovementSpeed * zoomScale * 0.02
	#var rotateCamera : float = Input.get_axis("rotate_camera_left","rotate_camera_right")
	if (Input.is_action_pressed("speed_up_camera")):
		position += 2 * Vector3(movingInDirec.x,moveUpDown,movingInDirec.y)
		#rotation += Vector3(0,rotateCamera/45,0)
	else:	
		position += Vector3(movingInDirec.x,moveUpDown,movingInDirec.y)
		#rotation += Vector3(0,rotateCamera/90,0)
	#print(currentTerrain.getHeightBilinear(Vector2(position.x,position.z)))
	position.y = max(position.y,currentTerrain.getHeightBilinear(Vector2(position.x,position.z)) - 60.0)
	
	# move the terrain with us
	if Engine.is_editor_hint() :
		return
	if not get_viewport().get_camera_3d():
		return
	var current_camera3d : Vector3 = global_position
	
	var scaleFactor : float = (floor(current_camera3d.y/128.0) + 1.0)
	var offset : float = 0.0#-tilesNeededEachDir * tileSize * scaleFactor * 0.5
	scaleFactor = max(scaleFactor,1.0) * 2.0
	
	var griddedPosition : Vector2 = Vector2(current_camera3d.x,current_camera3d.z).snappedf(2)
	griddedPosition -= Vector2(offset,offset) #+ Vector2(0.5,0.5)
	$"../TerrainCombiner".global_position = Vector3(griddedPosition.x,0,griddedPosition.y)
	
	$"../TerrainCombiner".scale = Vector3(scaleFactor,1.0,scaleFactor)
	get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
