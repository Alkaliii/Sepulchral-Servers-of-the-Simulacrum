extends PanelContainer
class_name LateralNotification

var assign : Control

var follow := false
var liftime := 4.0
@onready var notitext = $notitext

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if follow:
		global_position = lerp(global_position,assign.global_position,0.5)
		liftime -= delta
	if liftime <= 0.0:
		liftime = 999 
		remove()

enum nt { #Notification Types
	BASIC, #white, will not replace speaker name (use if you want custom colors also, pass bbcode with speaker or message
	SELF, #cyan ish 88ffcc, will replace speaker with YOU
	CHAT, #green b4ba47, will not replace speaker name, use for mp messages
	SYSTEM, #grey 777, replace speaker with (!)
	WARN, #orange, replace speaker with (!)
	DANGER, #e34262, replace speaker with (!)
	SPECIAL, #rainbow tag, will not replace speaker
}

const basicfs = "%s: %s" #% [Spkr,Msg]
const selffs = "[wave][color=88ffcc]%s[/color][/wave]: %s"
const chatfs = "[wave][color=b4ba46]%s[/color][/wave]: %s"
const systemfs = "[wave][color=777777]%s[/color][/wave]: %s"
const warnfs = "[wave][color=orange]%s[/color][/wave]: %s"
const dangerfs = "[wave][color=e34262]%s[/color][/wave]: %s"
const specialfs = "[wave][rainbow]%s[/rainbow][/wave]: %s"

func set_noti(data : Dictionary = {
	"speaker":"nme",
	"message":"this is a test msg!",
	"type":nt.BASIC,
	"duration":4.0
}):
	if data.has("duration"): liftime = data["duration"]
	
	var spkr : String = "err"
	if data.has("speaker"): spkr = data["speaker"]
	
	var msg : String = "missing data"
	if data.has("message"): msg = data["message"]
	
	var type : nt = nt.BASIC
	if data.has("type"): type = data["type"]
	match type:
		nt.BASIC:
			notitext.text = basicfs % [spkr,msg]
		nt.SELF: 
			spkr = "YOU"
			notitext.text = selffs % [spkr,msg]
		nt.CHAT:
			notitext.text = chatfs % [spkr,msg]
		nt.SYSTEM: 
			spkr = "(!)"
			notitext.text = systemfs % [spkr,msg]
		nt.WARN: 
			spkr = "(!)"
			notitext.text = warnfs % [spkr,msg]
		nt.DANGER: 
			spkr = "(!)"
			notitext.text = dangerfs % [spkr,msg]
		nt.SPECIAL:
			notitext.text = specialfs % [spkr,msg]
	
	size = Vector2.ZERO
	follow = true

func remove():
	follow = false
	assign.get_parent().remove_child(assign)
	assign.queue_free()
	await create_tween().tween_property(self,"modulate:a",0.0,0.125).set_ease(Tween.EASE_IN_OUT).finished
	get_parent().remove_child(self)
	queue_free()
