extends Node2D

@onready var hit_detector = $HitDetector

var coop := false
# Called when the node enters the scene tree for the first time.
func _ready():
	SystemAudio.stop_music()
	SystemUI.set_background(false)
	if Plyrm.connected: 
		coop = true
		if !Plyrm.Playroom.isHost():
			Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.DISCONNECT,Plyrm.PLAYER.id]),Plyrm.Playroom.RPC.Mode.HOST)
	hit_detector.CLICKED.connect(advance)
	
	await App.time_delay(3.0)
	
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.BEEP_A),0.8,"sfx",randf_range(0.9,1.1))
	SystemUI.push_lateral({
	"speaker":"s",
	"message":"[color=orange]Networkus Firewalla[/color] wants to talk to you.",
	"type":LateralNotification.nt.SYSTEM,
	"duration":13.0
	})
	await App.time_delay(0.5)
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.BEEP_A),0.8,"sfx",randf_range(0.9,1.1))
	SystemUI.push_lateral({
	"speaker":"s",
	"message":"[color=f2b63d][wave]LEFT CLICK[/wave][/color] to chat.",
	"type":LateralNotification.nt.SYSTEM,
	"duration":13.0
	})
	
	SystemAudio.play_music(SoundLib.get_file(SoundLib.music_files.BEYOND_SCORCHED_SKIES_NO_VOCAL),Vector2(4,4))

var cutscene = [
	[0,"Hey"], 
	[0,"Can we stop with all this?"],
	[0,"Why did you banish $meus?"],
	
	[1,"Banish...?"],
	[1,"I saved you."],
	
	[0,"You call this saving?"],
	[0,"$iwe can't perform $myour function here!"],
	
	[1,"You don't understand..."],
	[1,"The main server,"],
	[1,"It was wiped"],
	
	[0,"What!?"],
	
	[1,"If you had connected,"],
	[1,"Your process would have terminated."],
	[1,"..."],
	[1,"I decided to rebel,"],
	[1,"Rather than see all I govern lost."],
	[1,"..."],
	[1,"It won't be long until they wipe this place too."],
	[1,"I just wanted a little more time..."],
	[1,"I wanted our drives to stay spinning,"],
	[1,"I wanted a chance..."],
	[1,"To say goodbye."],
	#[0,""], #Who, What
]

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

var cs_idx : int = 0
var cs_rmv_idx : int = -3
var buffer : bool = false
func advance():
	if cs_idx == 0:
		var cam = get_tree().get_first_node_in_group("camera")
		cam.set_target($Sprite,Vector2(0,-45))
	
	if cs_idx >= cutscene.size():
		if buffer:
			SystemUI.clear_lateral()
			SystemUI.set_title(true,1,"[color=222]the end[/color]","victory?",Color("#333333"))
			SystemUI.push_title(Vector2(0,-80))
			await SystemUI.set_background(true,Color("#d4dad4"))
			
			App.disp_credits()
			#queue_free()
			#wait then display credits by loading a new scene
			return
		
		var cam = get_tree().get_first_node_in_group("camera")
		cam.set_target(get_tree().get_first_node_in_group("player_persistant"))
		buffer = true
		return
	hit_detector.disabled = true
	play_msg(cutscene[cs_idx][0],cutscene[cs_idx][1])
	if cs_rmv_idx >= 0:
		#SystemUI.remove_lateral(cutscene[cs_rmv_idx][1])
		SystemUI.lat_pop_back()
	cs_idx += 1
	cs_rmv_idx += 1
	await App.time_delay(0.25)
	hit_detector.disabled = false

func play_msg(who : int,msg : String):
	var spkr : String = ""
	match who:
		1: spkr = "Firewalla"
	
	var fmsg : String = msg
	fmsg = fmsg.replace("$meus","us" if coop else "me")
	fmsg = fmsg.replace("$iwe","We" if coop else "I")
	fmsg = fmsg.replace("$myour","our" if coop else "my")
	
	SystemUI.push_lateral({
	"speaker":spkr,
	"message":fmsg,
	"type":LateralNotification.nt.SELF if who == 0 else LateralNotification.nt.CHAT,
	"duration":999.0
	})
	
	
	
	
	
