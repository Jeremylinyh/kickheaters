extends Control

@export var tankRadius : float = 10 ## in pixels

func isCloseEnough(A : Vector2, B : Vector2) :
	return (A - B).length() < tankRadius

func findTanksInRegion(startingPosition : Vector2) :
	var playerTanks = get_tree().get_nodes_in_group("PlayerTanks")
	
	for tank in playerTanks :
		var tankScreenPoint : Vector2 = get_viewport().get_camera_3d().unproject_position(tank.global_position)
		#prints(tankScreenPoint,startingPosition)
		if isCloseEnough(tankScreenPoint,startingPosition) :
			return tank
	
	#print()
	#for tonk in tanksWithinRadius :
		#print(tonk.name)
	
	return null

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Click") :
		var selectedTank = (findTanksInRegion(get_global_mouse_position()))
		print(selectedTank)
