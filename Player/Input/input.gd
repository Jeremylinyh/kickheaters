extends Panel

enum Actions {
	SELECT,
	MOVE,
}

var currentMode : Actions = Actions.SELECT
var startingPosition : Vector2 = Vector2(0.0,0.0)
var newPosition : Vector2 = startingPosition

var mainInputListenerOn : bool = true

func isLooselyWithin(num : float,boundA : float,boundB : float,radius : float) :
	#prints(num,boundA,boundB,radius)
	if boundA > boundB :
		var holder = boundA
		boundA = boundB
		boundB = holder
	var result : bool = (num + radius) > boundA
	result = result and (num - radius) < boundB
	return result
	

func findTanksInRegion() :
	var playerTanks = get_tree().get_nodes_in_group("PlayerTanks")
	var tanksWithinRadius : Array[Node3D] = []
	for tank in playerTanks :
		var tankRadius : float = tank.selectableRadius
		var tankScreenPoint : Vector2 = get_viewport().get_camera_3d().unproject_position(tank.global_position)
		if (isLooselyWithin(tankScreenPoint.x,startingPosition.x,newPosition.x,tankRadius) 
			and isLooselyWithin(tankScreenPoint.y,startingPosition.y,newPosition.y,tankRadius)) :
			tanksWithinRadius.append(tank)
	
	#print()
	#for tonk in tanksWithinRadius :
		#print(tonk.name)
	
	return tanksWithinRadius
	

func getRegion() :
	self.visible = true
	startingPosition = get_global_mouse_position()
	self.position = startingPosition
	while Input.is_action_pressed("Click") :
		await get_tree().create_timer(0.1).timeout
		
	self.visible = false
	
	var tankList : Array[Node3D] = findTanksInRegion()
	if tankList.size() > 0 :
		currentMode = Actions.MOVE
	return tankList

func _process(_delta: float) -> void:
	if not self.visible :
		return
	newPosition = get_global_mouse_position()
	var relativePosition : Vector2 = newPosition-startingPosition
	
	if relativePosition.x < 0 :
		position.x = newPosition.x
		relativePosition.x *= -1
	else :
		position.x = startingPosition.x
	if relativePosition.y < 0 :
		position.y = newPosition.y
		relativePosition.y *= -1
	else :
		position.y = startingPosition.y
	
	self.size = Vector2(relativePosition)

func addWaypoints() :
	pass

func _input(event: InputEvent) -> void:
	if not mainInputListenerOn :
		return
	
	var whatToDo = {}
	whatToDo[Actions.SELECT] = Callable(self,"getRegion")
	whatToDo[Actions.MOVE] = Callable(self,"addWaypoints")
	
	if event.is_action_pressed("Click") :
		whatToDo[currentMode].call()
