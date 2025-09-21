extends Node

var bpm = 0.0

var note_scores = [0,0,0,0,0]
var combo = 0
var total_notes = 0
var tech = [0,0] #current max
var chance = [0,0]
var final = [0,0]
var score = 0.0
var song_name = ""
var time = 0

var settings = {}
var sorted = ""

var song = "pet_me"
var editor_load = true

var systemdir = "user://"

var cached_levels = {}

func _init():
	OS.request_permissions()
	if OS.get_name() == "Android":
		systemdir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/a v4/"
		print(systemdir)
	
	if FileAccess.file_exists(systemdir+"settings.json"):
		var q = FileAccess.open(systemdir+"settings.json",1)
		settings = JSON.parse_string(q.get_as_text())
		q.close()
	else:
		var q = FileAccess.open(systemdir+"settings.json",2)
		settings = {"master":50,"song":50,"sfx":50,"vibration":40,"brightness":50,"subs_jp":true,"subs_ro":true,"subs_en":true,"lposx":150,"lposy":500,"rposx":1050,"rposy":500,"lscale":13,"rscale":13,"ldist":80,"rdist":80,"last_song":"","sorting":"score","sync":0.0,"fps":false,"pitch":1,"gamemode":0}
		q.store_string(JSON.stringify(settings))
		q.close()

func enter_level():
	if GL.settings.gamemode == 0:
		get_tree().change_scene_to_file("res://level.tscn")
	elif GL.settings.gamemode == 1:
		get_tree().change_scene_to_file("res://cinema.tscn")
	elif GL.settings.gamemode == 2:
		get_tree().change_scene_to_file("res://level_second.tscn")
	else:
		get_tree().change_scene_to_file("res://level_third.tscn")

func save():
	var q = FileAccess.open(GL.systemdir+"settings.json",2)
	q.store_string(JSON.stringify(GL.settings))
	q.close()

func vibrate():
	if settings.has("vibration"): Input.vibrate_handheld(settings.vibration)
	else: Input.vibrate_handheld(40)

func secs2mins(s):
	var secs = s
	var mins = 0
	while secs >= 60:
		secs -= 60
		mins += 1
	var secs_str = str(secs)
	var mins_str = str(mins)
	if secs < 10:
		secs_str = secs_str.insert(0,"0")
	if mins < 10:
		mins_str = mins_str.insert(0,"0")
	return mins_str+":"+secs_str

#func _process(delta):
	#if has_node("/root/main/touch"):
		#for i in get_node("/root/main/touch").get_children():
			#if i.
