extends Control

@export var tankRadius : float = 10 ## in pixels

func isCloseEnough(A : Vector2, B : Vector2) -> float :
	return (A - B).length()

func findTanksInRegion(startingPosition : Vector2) :
	var playerTanks = get_tree().get_nodes_in_group("PlayerTanks")
	var closestIndex = -1
	var closestDist = 100
	
	var currIndex = 0
	for tank in playerTanks :
		var tankScreenPoint : Vector2 = get_viewport().get_camera_3d().unproject_position(tank.global_position)
		#prints(tankScreenPoint,startingPosition)
		var newClosestDist = isCloseEnough(tankScreenPoint,startingPosition)
		if newClosestDist < closestDist :
			closestDist = newClosestDist
			closestIndex = currIndex
		currIndex += 1
	
	#print()
	#for tonk in tanksWithinRadius :
		#print(tonk.name)
	#print(closestDist)
	if closestDist < tankRadius :
		return playerTanks[closestIndex]
	return null

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Click") :
		var selectedTank = (findTanksInRegion(get_global_mouse_position())) ## This takes priority over path node
		print(selectedTank)
