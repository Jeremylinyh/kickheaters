extends Panel

var on : bool = true
var startingPosition : Vector2 = Vector2(0.0,0.0)
var newPosition : Vector2 = startingPosition

func getRegion() :
	self.visible = true
	startingPosition = get_global_mouse_position()
	self.position = startingPosition
	while Input.is_action_pressed("Click") :
		await get_tree().create_timer(0.1).timeout
		
	self.visible = false

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

func _input(event: InputEvent) -> void:
	if not on :
		return
	if event.is_action_pressed("Click") :
		getRegion()
