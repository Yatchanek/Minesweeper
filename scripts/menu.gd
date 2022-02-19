extends Control

onready var time_label = $ColorRect/TimeLabel

var current_time
var start_time

signal time_stopped

func _ready():
	set_process(false)


func _process(_delta):
	current_time = OS.get_unix_time() - start_time
	var minutes = current_time / 60
	var seconds = current_time % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
func start():
	start_time = OS.get_unix_time()
	set_process(true)
	
func stop():
	set_process(false)
	emit_signal("time_stopped", current_time)
