extends Object
class_name SoundLib

enum music_files {
	BATTLE_DAWN, #https://youfulca.com/en/2022/08/14/boss_queen-of-the-white-dawn/
	BATTLE_KANNAGI, #https://youfulca.com/en/2022/08/14/boss_kannagi/ #victory theme practically
	MYTHICAL_TOWN,
	TOWER_OF_THE_ARCHMAGE,
	NIGHTTIME, #tutorial
	NIGHTTIMENOPERC, #title screen and ambient
}

#https://ateliermagicae.itch.io/monster-sound-effects-vol1
#https://denissetakes.itch.io/crystalcaves # NOTICE needs credit

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
}

static func get_file(key) -> String:
	match key:
		#Music
		music_files.BATTLE_DAWN: return "res://Assets/Music/Battle-Dawn_loop.ogg"
		music_files.BATTLE_KANNAGI: return "res://Assets/Music/Battle-kannagi_loop.ogg"
		music_files.MYTHICAL_TOWN: return "res://Assets/Music/Mystical Town (Loop).wav"
		music_files.TOWER_OF_THE_ARCHMAGE: return "res://Assets/Music/Tower of the Archmage.wav"
		music_files.NIGHTTIME: return "res://Assets/Music/NightTime_Short(loop)(78).wav"
		music_files.NIGHTTIMENOPERC: return "res://Assets/Music/NightTime_ShortNoPerc(loop)(78).wav"
	
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
		sound_files.ATTACK_ACID_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Acid_Impact_01.wav"
		sound_files.ATTACK_ACID_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Acid_Impact_02.wav"
		sound_files.ATTACK_ICE_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Ice_Impact_01.wav"
		sound_files.ATTACK_ICE_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Ice_Impact_02.wav"
		sound_files.ATTACK_LIGHTNING_A: return "res://Assets/SFX/MMO_Game_Magic_Designed_Lightning_Impact_01.wav"
		sound_files.ATTACK_LIGHTNING_B: return "res://Assets/SFX/MMO_Game_Magic_Designed_Lightning_Impact_02.wav"
	
	printerr(key, "NOT FOUND in sound lib")
	return ""
