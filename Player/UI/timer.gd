extends Label

var startTime : float
var pausedStartTime : float = 0
var totalPausedTime : float = 0
var currTime : float = 0
var paused : bool = false

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func _ready():
	currTime = 0
	totalPausedTime = 0
	pausedStartTime = 0
	startTime = Time.get_unix_time_from_system()

func _process(delta : float):
	print(totalPausedTime)
	
	if paused == true:
		totalPausedTime = Time.get_unix_time_from_system() - pausedStartTime
		return
	currTime= Time.get_unix_time_from_system() - startTime 
	$".".text = str(round_to_dec(currTime, 2))

func pause():
	if $".".paused == false:
		$".".paused = true
		pausedStartTime = Time.get_unix_time_from_system()
	else:
		$".".paused = false
		startTime += totalPausedTime
