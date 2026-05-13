extends Control

## The plan:
## The player will click on the screen, if it is near a tank it is selected, else null is selected
## The selecting priority is as follows: Already selected tank + path > tank/node > path
## While the player held mouse, if a tank is selected we draw line.

@export var tankRadius : float = 30 ## in pixels
@onready var tankCircle = $TankCircle
var tankVisuals : Dictionary[Tank,Panel]

func isCloseEnough(A : Vector2, B : Vector2) -> float :
	return (A - B).length()

func findTanksInRegion(startingPosition : Vector2) :
	var playerTanks = get_tree().get_nodes_in_group("PlayerTanks")
	var closestIndex = -1
	var closestDist = 100
	
	var currIndex = 0
	for tank : Tank in playerTanks :
		var tankScreenPoint : Vector2 = get_viewport().get_camera_3d().unproject_position(tank.global_position)
		#prints(tankScreenPoint,startingPosition)
		var newClosestDist = isCloseEnough(tankScreenPoint,startingPosition)
		if newClosestDist < closestDist :
			closestDist = newClosestDist
			closestIndex = currIndex
		
		if not Input.is_action_pressed("shift") :
			tank.selected = false
		
		currIndex += 1
	
	#print()
	#for tonk in tanksWithinRadius :
		#print(tonk.name)
	#print(closestDist)
	if closestDist < tankRadius :
		return playerTanks[closestIndex]
	return null

func _process(_delta: float) -> void:
	var playerTanks = get_tree().get_nodes_in_group("PlayerTanks")
	for tank : Tank in playerTanks :
		if not tankVisuals.get(tank) :
			tankVisuals[tank] = tankCircle.duplicate() 
			tankVisuals[tank].visible = true
			add_child(tankVisuals[tank])
	for key : Tank in tankVisuals :
		if not key :
			tankVisuals.erase(key)
		var visualizer : Panel = tankVisuals[key]
		var tankScreenPoint : Vector2 = get_viewport().get_camera_3d().unproject_position(key.global_position)
		tankScreenPoint -= Vector2(tankRadius/2,tankRadius/2)
		visualizer.position = tankScreenPoint

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Click") :
		var selectedTank : Tank = (findTanksInRegion(get_global_mouse_position())) ## This takes priority over path node
		#dragTank(selectedTank)
		if selectedTank : # and not Input.is_action_pressed("shift") :
			selectedTank.selected = true
		#print(selectedTank)
