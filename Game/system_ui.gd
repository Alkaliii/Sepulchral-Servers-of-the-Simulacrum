extends Node


var system_messages : Array = []
#[Message,Duration]
#Negative means it's duration will elapse when sharing screen time
@onready var system_msg = $cl/Top/Panel/HBoxContainer/system_msg

func _ready():
	set_title(false)

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

@onready var titlecont = $cl/Top/TITLECONT
@onready var titletext = $cl/Top/TITLECONT/TITLE/pc/TITLETEXT
var ttw : Tween #title tween
func set_title(state : bool = true, shake : int = 2, title : String = "", subtitle : String = "", s_colr : Color = Color("#e34262")):
	if ttw: ttw.kill()
	ttw = create_tween()
	
	match state:
		false: #hide
			ttw.tween_property(titlecont,"modulate:a",0,0.25).set_ease(Tween.EASE_IN_OUT)
			await ttw.finished
			titlecont.hide()
		true:
			titlecont.show()
			titletext.clear()
			if subtitle != "":
				titletext.append_text(str("[center][code][color=",s_colr.to_html(),"]",subtitle,"[/color][/code]"))
				titletext.newline()
			var wve = "[wave]" if shake >= 1 else ""
			titletext.append_text(str(wve,title))
			if shake >= 2: titletext.material.set_shader_parameter("normal_offset",1.5)
			else: titletext.material.set_shader_parameter("normal_offset",0.0)
			
			if subtitle != "": titletext.visible_characters = subtitle.length()
			
			ttw.tween_property(titlecont,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await ttw.finished
			await App.time_delay(0.5)
			ttw = create_tween()
			ttw.tween_property(titletext,"visible_ratio",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
			await ttw.finished

@onready var roar_sl = $effects/RoarSL
var rtw : Tween #roar tween
func roar_effect(state : bool):
	if rtw: rtw.kill()
	rtw = create_tween()
	if Plyrm.connected and Plyrm.Playroom.isHost(): 
		Plyrm.Playroom.RPC.call("game_state_update",var_to_str([7,state]),Plyrm.Playroom.RPC.Mode.OTHERS)
	match state:
		true: #Show roar
			rtw.tween_property(roar_sl,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			rtw.parallel().tween_method(srslmev,1.0,0.5,0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		false: #Hide roar
			rtw.tween_property(roar_sl,"modulate:a",0.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			rtw.parallel().tween_method(srslmev,0.5,1.0,0.125).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)

func srslmev(nv : float): #set roar speed lines mask edge value
	roar_sl.material.set_shader_parameter("mask_edge",nv)
