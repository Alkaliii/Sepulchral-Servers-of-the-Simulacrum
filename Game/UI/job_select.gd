extends PanelContainer


var idx : int = 0

@onready var upbtn = $main/Selector/UP
@onready var downbtn = $main/Selector/DOWN

@onready var header = $main/info/words/Header
@onready var subtitle = $main/info/words/Subtitle
@onready var stats = $main/info/words/Stats

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if visible:
		if Input.is_action_just_pressed("MUP"): _on_up_pressed()
		if Input.is_action_just_pressed("MDOWN"): _on_down_pressed()

var atw : Tween
func appear(state:bool):
	if atw: atw.kill()
	atw = create_tween()
	
	match state:
		true:
			var player = get_tree().get_first_node_in_group("player_persistant")
			idx = App.job_inventory.find(player.job.JOB)
			focus_idx(false)
			show()
			atw.tween_property(self,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
		false:
			atw.tween_property(self,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
			hide()

const hit_sounds = [SoundLib.sound_files.IMPACT_A,SoundLib.sound_files.IMPACT_B]
func sfx():
	var sounds = hit_sounds
	var pitch = randf_range(0.9,1.1)
	
	SystemAudio.play(SoundLib.get_file_sfx(sounds.pick_random()),0.5,"sfx",pitch)

const stat_format = "[right]bHP: %d / bDMG: %d / malloc: %d / cache: %d"
func focus_idx(with_sfx := true):
	#change UI
	var j := App.job_inventory[idx]
	var info : Dictionary = system_job.get_info(j)
	if with_sfx: sfx()
	header.text = str("[wave]",info.name)
	subtitle.text = info.desc
	stats.text = stat_format % [info.bhealth,info.bdamage,info.malloc,info.cache]
	#set job
	var player = get_tree().get_first_node_in_group("player_persistant")
	if player:
		player.job.JOB = j
		player.set_job()
	else:
		#put in App for pass over
		pass
	pass

func _on_up_pressed():
	upbtn.release_focus()
	idx = (idx + 1) % App.job_inventory.size()
	focus_idx()


func _on_down_pressed():
	downbtn.release_focus()
	if idx == 0: idx = App.job_inventory.size() - 1
	else:
		idx = (idx - 1) % App.job_inventory.size()
	focus_idx()
