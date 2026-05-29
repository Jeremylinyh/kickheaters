extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for enemy : Tank in get_tree().get_nodes_in_group("EnemyTank") :
		# If at least one visible
		var canSeePlayer : bool = atLeastOneVisible(enemy.getRealPos())
		enemy.visible = canSeePlayer
		
func atLeastOneVisible(selfpos : Vector3) -> bool :
	for friendly : Tank in get_tree().get_nodes_in_group("PlayerTanks") :
		var height = Vector3(0,0,0)
		prints($"../TerrainCombiner".traceRay(selfpos + height,friendly.getRealPos() + height)
		,(selfpos-friendly.getRealPos()).length())
		
		if $"../TerrainCombiner".traceRay(selfpos + height,friendly.getRealPos() + height) > (selfpos-friendly.getRealPos()).length() - 1 :
			print("not blocked")
			#print(friendly.get_node("LookAt"))
			friendly.get_node("LookAt").global_position = selfpos
			#print(selfpos)
			
			if $"../HUD/Timer".paused :
				return true
			
			if not friendly.fire() :
				for potentialFire : Tank in get_tree().get_nodes_in_group("PlayerTanks") :
					if $"../TerrainCombiner".traceRay(selfpos + height,friendly.getRealPos() + height) > (selfpos-friendly.getRealPos()).length() - 1 :
						if potentialFire.fire() :
							break
			return true
		else :
			print("blocked")
	return false
