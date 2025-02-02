extends Object
class_name SoundLib

enum music_files {
	BATTLE_DAWN, #https://youfulca.com/en/2022/08/14/boss_queen-of-the-white-dawn/
	BATTLE_KANNAGI, #https://youfulca.com/en/2022/08/14/boss_kannagi/ #victory theme practically
	BATTLE_KANNAGI_INTRO,
	BATTLE_MASYOU, #https://youfulca.com/en/2022/08/14/boss_masyou/ #very grandious feeling good for battle start
	BATTLE_MASYOU_INTRO,
	BATTLE_FATALBLOOD, #https://youfulca.com/en/2022/08/14/boss_fatal-blood/ #high energy, second phase for sure
	BATTLE_ARIADNE, #https://youfulca.com/en/2022/08/14/boss_the-song-of-the-end/
	BATTLE_ARIADNE_INTRO,
	BATTLE_TRUTH, #https://youfulca.com/en/2022/08/14/boss_two-sides-of-the-truth/
	BATTLE_TRUTH_INTRO,
	MYTHICAL_TOWN, #(HB) Chris Logsdon https://chrislsound.com/
	TOWER_OF_THE_ARCHMAGE, #(HB) Ryan Smith https://audiojungle.net/user/blinnaudio?ref=Blinn
	NIGHTTIME, #(HB) Andrea Baroni https://andreabaroni.com/ - tutorial 
	NIGHTTIMENOPERC, #(HB) Andrea Baroni https://andreabaroni.com/ - title screen and ambient
	BEYOND_SCORCHED_SKIES, #credits
	BEYOND_SCORCHED_SKIES_NO_VOCAL #end cutscene
}

static var has_intro : Array[music_files] = [
	music_files.BATTLE_KANNAGI,
	music_files.BATTLE_KANNAGI_INTRO,
	music_files.BATTLE_MASYOU,
	music_files.BATTLE_MASYOU_INTRO,
	music_files.BATTLE_ARIADNE,
	music_files.BATTLE_ARIADNE_INTRO,
	music_files.BATTLE_TRUTH,
	music_files.BATTLE_TRUTH_INTRO
]

#https://ateliermagicae.itch.io/monster-sound-effects-vol1
#https://ateliermagicae.itch.io/fantasy-ui-sound-effects
#https://denissetakes.itch.io/crystalcaves # NOTICE needs credit
#https://kenney.nl/assets/interface-sounds
#Noam Guterman / Epic Stock Media https://noamguterman.dev/


enum sound_files {
	MONSTER_GROWL_A,
	MONSTER_GROWL_B,
	MONSTER_HISS,
	MONSTER_ROAR,
	MONSTER_SCIFI,
	LEVEL_CREVASS,
	LEVEL_SKYLIGHT,
	LEVEL_THIS_WAY,
	NOTIFICATION_A,
	NOTIFICATION_B,
	ATTACK_ACID_A,
	ATTACK_ACID_B,
	ATTACK_ICE_A,
	ATTACK_ICE_B,
	ATTACK_LIGHTNING_A,
	ATTACK_LIGHTNING_B,
	NOTIFICATION_C, #neutral
	NOTIFICATION_D, #complete/good job
	NOTIFICATION_E, #mystical
	NOTIFICATION_F, #mystical 2
	NOTIFICATION_G, #hummmm
	IMPACT_A, #chop stone
	IMPACT_B, #chop wood
	DOOR,
	ATTACK_FIRE_A,
	ATTACK_FIRE_B,
	DOOR_SHUT,
	BEEP_A,
	NOTIFICATION_H, #not really notif but idk what else to call it lol
	WHOOSH,
	ERROR_A, #finally an error sound
}

static func get_file(key) -> String:
	match key:
		#Music
		music_files.BATTLE_DAWN: return "res://Assets/Music/Battle-Dawn_loop.ogg"
		music_files.BATTLE_KANNAGI: return "res://Assets/Music/Battle-kannagi_loop.ogg"
		music_files.BATTLE_KANNAGI_INTRO: return "res://Assets/Music/Battle-kannagi_intro.ogg"
		music_files.BATTLE_MASYOU: return "res://Assets/Music/Battle-masyou_loop.ogg"
		music_files.BATTLE_MASYOU_INTRO: return "res://Assets/Music/Battle-masyou_intro.ogg"
		music_files.BATTLE_FATALBLOOD: return "res://Assets/Music/Battle-FatalBlood_loop.ogg"
		music_files.BATTLE_ARIADNE: return "res://Assets/Music/Ariadne-LastBoss_loop.ogg"
		music_files.BATTLE_ARIADNE_INTRO: return "res://Assets/Music/Ariadne-LastBoss_intro.ogg"
		music_files.BATTLE_TRUTH: return "res://Assets/Music/Two-Sides-of-the-Truth_loop.ogg"
		music_files.BATTLE_TRUTH_INTRO: return "res://Assets/Music/Two-Sides-of-the-Truth_intro.ogg"
		music_files.MYTHICAL_TOWN: return "res://Assets/Music/Mystical Town (Loop).wav"
		music_files.TOWER_OF_THE_ARCHMAGE: return "res://Assets/Music/Tower of the Archmage.wav"
		music_files.NIGHTTIME: return "res://Assets/Music/NightTime_Short(loop)(78).wav"
		music_files.NIGHTTIMENOPERC: return "res://Assets/Music/NightTime_ShortNoPerc(loop)(78).wav"
		music_files.BEYOND_SCORCHED_SKIES: return "res://Assets/Music/Beyond_Scorched_Skies.ogg"
		music_files.BEYOND_SCORCHED_SKIES_NO_VOCAL: return "res://Assets/Music/Beyond_Scorched_Skies-inst.ogg"
		music_files:return""
	
	printerr(key, "NOT FOUND in sound lib")
	return ""

static func get_file_sfx(key) -> String:
	match key:
		#SFX
		sound_files.MONSTER_GROWL_A: return "res://Assets/SFX/Monster_Growl8.wav"
		sound_files.MONSTER_GROWL_B: return "res://Assets/SFX/Monster_Growl11.wav"
		sound_files.MONSTER_HISS: return "res://Assets/SFX/Monster_Hiss1.wav"
		sound_files.MONSTER_ROAR: return "res://Assets/SFX/Monster_Roar12.wav"
		sound_files.MONSTER_SCIFI: return "res://Assets/SFX/SciFi_Monster4.wav"
		sound_files.LEVEL_CREVASS: return "res://Assets/SFX/Crevass.wav"
		sound_files.LEVEL_SKYLIGHT: return "res://Assets/SFX/Skylight.wav"
		sound_files.LEVEL_THIS_WAY: return "res://Assets/SFX/This Way.wav"
		sound_files.NOTIFICATION_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Holy_Cast_06.wav"
		sound_files.NOTIFICATION_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Holy_Cast_10.wav"
		sound_files.NOTIFICATION_C: return "res://Assets/SFX/Fantasy_UI (15).wav"
		sound_files.NOTIFICATION_D: return "res://Assets/SFX/Fantasy_UI (21).wav"
		sound_files.NOTIFICATION_E: return "res://Assets/SFX/Fantasy_UI (40).wav"
		sound_files.NOTIFICATION_F: return "res://Assets/SFX/Fantasy_UI (41).wav"
		sound_files.NOTIFICATION_G: return "res://Assets/SFX/Fantasy_UI (42).wav"
		sound_files.NOTIFICATION_H: return "res://Assets/SFX/Piano_Ui (4).wav"
		sound_files.ATTACK_ACID_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Acid_Impact_01.wav"
		sound_files.ATTACK_ACID_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Acid_Impact_02.wav"
		sound_files.ATTACK_ICE_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Ice_Impact_01.wav"
		sound_files.ATTACK_ICE_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Ice_Impact_02.wav"
		sound_files.ATTACK_LIGHTNING_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Lightning_Impact_01.wav"
		sound_files.ATTACK_LIGHTNING_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Lightning_Impact_02.wav"
		sound_files.ATTACK_FIRE_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Fire_Impact_03.wav"
		sound_files.ATTACK_FIRE_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Fire_Impact_09.wav"
		sound_files.IMPACT_A: return "res://Assets/SFX/Chop Stone.wav"
		sound_files.IMPACT_B: return "res://Assets/SFX/Chop Wood.wav"
		sound_files.DOOR: return "res://Assets/SFX/Dungeon Door 3 - Metal Handle.wav"
		sound_files.DOOR_SHUT: return "res://Assets/SFX/Dungeon Door - Shut.wav"
		sound_files.BEEP_A: return "res://Assets/SFX/Fantasy_UI (10).wav"
		sound_files.WHOOSH: return "res://Assets/SFX/SFX_swordSwing.wav" #cyberleaf
		sound_files.ERROR_A: return "res://Assets/SFX/error_006.ogg" #kenny
		sound_files:return""
	
	printerr(key, "NOT FOUND in sound lib")
	return ""
