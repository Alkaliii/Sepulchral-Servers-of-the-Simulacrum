extends PanelContainer
class_name ObjectiveNotification

var obj : String = "Find the scarecrow"
var help : String = "Use WASD to move around."

@onready var helpbtn = $Control/help
@onready var objective_text = $objectiveText
@onready var oprogress = $objectiveText/conp/progress

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate.a = 0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


var otw : Tween
func set_objective(data:Dictionary):
	obj = data.obj
	help = data.help
	if otw: otw.kill()
	otw = create_tween()
	
	otw.tween_property(self,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN_OUT)
	await otw.finished
	#set_objective_progress(0.0)
	oprogress.value = 0.0
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_G))
	objective_text.text = str("[color=b4ba46][b]OBJ:[/b][/color] [wave]",obj)
	objective_text.visible_ratio = 0.0
	otw = create_tween()
	otw.tween_property(self,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	otw.tween_property(objective_text,"visible_ratio",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	await otw.finished

func hide_obj():
	if otw: otw.kill()
	otw = create_tween()
	otw.tween_property(objective_text,"visible_ratio",0.0,0.25).set_ease(Tween.EASE_IN_OUT)
	otw.parallel().tween_property(self,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN_OUT)
	await otw.finished

var ptw : Tween
func set_objective_progress(ratio : float):
	if ptw: ptw.kill()
	ptw = create_tween()
	
	ptw.tween_property(oprogress,"value",oprogress.max_value * ratio,0.125).set_ease(Tween.EASE_IN_OUT)

func _on_help_pressed():
	helpbtn.release_focus()
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_C))
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":str(help),
	"type":LateralNotification.nt.SYSTEM,
	"duration":6.0
	})
