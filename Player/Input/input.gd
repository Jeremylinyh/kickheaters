extends Node3D

func getRegion() :
	while Input.is_action_pressed("Click") :
		await get_tree().create_timer(0.1).timeout
	print("released")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Click") :
		print("pressed")
		getRegion()
