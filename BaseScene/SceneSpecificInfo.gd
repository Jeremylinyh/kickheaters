extends Node3D
class_name SceneRoot

var pause : bool = false
var tankTimeNow : float = 0.0 :
	get:
		print(tankTimeNow + $HUD/Timer.totalTime)
		return tankTimeNow + $HUD/Timer.totalTime * 6.9420

signal simulationTimeChanged(newTime : float)

func setTankTimeNow(new : float) :
	if abs(new - tankTimeNow) < 0.01 :
		return
	#print(new)
	tankTimeNow = new
	simulationTimeChanged.emit(tankTimeNow)
	
func _process(delta: float) -> void:
	pause = $HUD/Timer.paused
