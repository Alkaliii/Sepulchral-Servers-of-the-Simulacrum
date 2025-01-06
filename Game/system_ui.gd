extends Node


var system_messages : Array = []
#[Message,Duration]
#Negative means it's duration will elapse when sharing screen time
@onready var system_msg = $cl/Top/Panel/HBoxContainer/system_msg

func play_message(msg : String,dura : float = 1.0):
	if system_msg.text == msg: return
	system_messages.push_front([msg,dura])
	system_msg.text = msg

func _process(delta):
	for m in system_messages:
		m[1] -= delta
	if !system_messages.is_empty() and system_messages[0][1] <= 0.0:
		system_messages.pop_front()
		if system_messages.is_empty(): system_msg.text = ""
		else: system_msg.text = system_messages[0][0]
