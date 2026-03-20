extends Label

var startTime : float
var pausedStartTime : float = 0
var totalPausedTime : float = 0
var currSecond : float = 0
var currMinute : int = 0
var currHour : int = 0
var secondString : String
var minuteString : String
var hourString : String
var paused : bool = false
var pauseButton = load("res://Assets/Pictures/pauseButton.png")
var unpauseButton = load("res://Assets/Pictures/unpauseButton.png")

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func _ready():
	currSecond = 0
	currMinute = 0
	currHour = 0
	secondString = "00.000"
	minuteString = "00"
	hourString = "00"
	totalPausedTime = 0
	pausedStartTime = 0
	startTime = Time.get_unix_time_from_system()
	paused = false 

func _process(delta : float):
	
	if paused == true:
		totalPausedTime = Time.get_unix_time_from_system() - pausedStartTime
		return
	currSecond= Time.get_unix_time_from_system() - startTime 
	if currSecond >= 60:
		startTime += 60
		currSecond -= 60
		currMinute += 1
		minuteString = str(currMinute)
		if currMinute < 10:
			minuteString = "0" + minuteString
		if currMinute >= 60:
			currMinute -= 60
			currHour += 1
			hourString = str(currHour)
			if currHour < 10:
				hourString = "0" + hourString
	secondString = String.num(currSecond, 3)
	if currSecond < 10:
		secondString = "0" + secondString
	
	var timeString = "%s:%s:%s" % [hourString, minuteString, secondString]
	$".".text = timeString

func pause():
	if $".".paused == false:
		$".".paused = true
		$"../PauseButton".set_texture_normal(unpauseButton)
		pausedStartTime = Time.get_unix_time_from_system()
	else:
		$".".paused = false
		$"../PauseButton".set_texture_normal(pauseButton)
		startTime += totalPausedTime
