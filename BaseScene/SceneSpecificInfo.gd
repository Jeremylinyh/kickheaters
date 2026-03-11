extends Node3D
class_name SceneRoot

var tankTimeNow : float = 0.0

signal simulationTimeChanged(newTime : float)

func setTankTimeNow(new : float) :
	if abs(new - tankTimeNow) < 0.01 :
		return
	#print(new)
	tankTimeNow = new
	simulationTimeChanged.emit(tankTimeNow)
