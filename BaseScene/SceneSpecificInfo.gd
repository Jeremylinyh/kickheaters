extends Node3D
class_name SceneRoot

#var pause : bool = false
var tankTimePassed : float = 0.0
var tankSpeed : float = 10
var allTanks : Array 
var selectedTankIndex : int
var tankTimeNow : float = 0.0 :
	get:
		#print(tankTimeNow + $HUD/Timer.totalTime)
		return tankTimeNow + $HUD/Timer.totalTime * tankSpeed

signal simulationTimeChanged(newTime : float)

func setTankTimeNow(new : float) :
	if abs(new - tankTimeNow) < 0.01 :
		return
	#print(new)
	tankTimeNow = new
	simulationTimeChanged.emit(tankTimeNow)
	
#func _process(delta: float) -> void:
	#pause = $HUD/Timer.paused

func _ready() -> void:
	allTanks = find_children("t72*","Tank",true,true)
	if allTanks:
		selectedTankIndex = 0
	print(allTanks)

func _input(event):
	if event.is_action_pressed("next_tank"):
		if selectedTankIndex <= allTanks.size():
			selectedTankIndex += 1
		else:
			selectedTankIndex = 0
		print(selectedTankIndex)
	
