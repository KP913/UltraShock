extends Node2D

var time_factor : float
var starting_time : float
var beat : float

var next_time : float
var next_time1 : float
var next_time2 : float

var needs_sync = false
var sync_amount = 0
var syncing = false

var bpm = 0.0
var wait_time = 0.0
var speed_mult = 1.0

var temp = 1

var note_array = []
var note_array1 = []
var note_array2 = []
var note_count
var note_count1
var note_count2

var score = 0.0
var total_notes = 0
var notes_hit = 0
var combo = 0
var extra_points = 0 #pontos ganhos por techs ou chances
var total_extra = 0

var tech_prep = false
var technical = false
var tech_rest = 0

var chance_prep = false
var chance = false
var chance_need = 0
var chance_have = 0

var finals_have = 0
var final_total = 0

var frame_hit = false
var frame_hit1 = false
var frame_hit2 = false

var song_name = ""
var song_length = 0

var loading = true

var sfx_volume = 0

var subtitles = []
var subs_jp = []
var subs_ro = []
var subs_en = []

var bpm_list = []
var bpm_list_raw = []
var speed_changes = []

var hold1_sfx : AudioStreamPlayer
var hold2_sfx : AudioStreamPlayer

var move_tween : Tween

var key_locks = [false,false,false,false,false,false,false,false]

var rainbow_shader = preload("res://rainbow.gdshader")

func _ready():
	load_song()
	song_length = $AudioStreamPlayer.stream.get_length()
	
	var q = FileAccess.open(GL.systemdir+"songs/"+GL.song+"/level.lvl",1)
	var test_json_conv = JSON.new()
	test_json_conv.parse(q.get_as_text())
	var info = test_json_conv.get_data()
	q.close()
	bpm = float(info.bpm)
	wait_time = float(info.wait_time)
	if info.has("speed"): speed_mult = float(info.speed)
	song_name = info.name
	
	if info.has("bpm_list"):
		bpm_list = info.bpm_list
	else:
		bpm_list = [[bpm,0]]
	bpm_list_raw = bpm_list.duplicate()
	if info.has("speed_changes"):
		for i in info.speed_changes:
			speed_changes.append([i.speed,i.time/64])
	print(speed_changes)
	subtitles = info.subtitles
	GL.bpm = bpm
	GL.note_scores = [0,0,0,0,0]
	GL.combo = 0
	GL.total_notes = 0
	GL.tech = [0,0]
	GL.chance = [0,0]
	GL.score = 0.0
	GL.song_name = song_name
	GL.time = song_length
	
	
	time_factor = bpm2s(bpm)
	$Timer.wait_time = 1000 + wait_time
	starting_time = 1000
	
	
	if OS.get_name() == "Android":
		$touch.show()
	$Settings.update_from_gl()
	setup_touch()
	
	for i in ["subs_jp","subs_ro","subs_en"]:
		if FileAccess.file_exists(GL.systemdir+"songs/"+GL.song+"/"+i+".txt"):
			var w = FileAccess.open(GL.systemdir+"songs/"+GL.song+"/"+i+".txt",FileAccess.READ)
			var z = w.get_as_text().split("\n")
			
			if i == "subs_jp": subs_jp = z
			if i == "subs_ro": subs_ro = z
			if i == "subs_en": subs_en = z
			#print(z)
	
	$syncer.wait_time = b2s(1)
	$syncer.start(b2s(1))
	
	var tween = get_tree().create_tween()
	tween.tween_property($notes,"position:y",-128,b2s(1))
	move_tween = tween

func _notification(what):
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT: if OS.get_name() == "Android":
		$pause._on_Button_pressed()

func setup_touch():
	for i in $touch.get_children():
		if i is Node2D:
			for u in i.get_children():
				for j in u.get_children():
					j.connect("pressed",GL.vibrate)
		else:
			i.connect("pressed",GL.vibrate)

var temp1 = 0
var temp2 = 0
var temp3 = false

func _process(delta):
	key_locks.fill(false)
	#print(bpm)
	$Label8.visible = GL.settings.fps
	$Label8.text = "FPS: "+str(Engine.get_frames_per_second())
	$subs_en.visible = GL.settings.subs_en
	$subs_ro.visible = GL.settings.subs_ro
	$subs_jp.visible = GL.settings.subs_jp
	
	
	if loading:
		return
	
	if !syncing:
		beat = s2b2($AudioStreamPlayer.get_playback_position())#starting_time - $Timer.time_left)
	else:
		beat = s2b(-$sync.time_left - wait_time - GL.settings.sync)
	
	#$notes.position.y = -128*beat
	
	#temp2 = temp1
	#temp1 = beat
	#if temp2 > fmod(temp1,1) && beat >= 0: hit_sound("hit")
	#if beat >= 0 && !temp3:
		#temp3 = true
		#hit_sound("hit")
	if $AudioStreamPlayer.get_playback_position() >= song_length or ($AudioStreamPlayer.get_playback_position() == 0 && !loading && !syncing):
		get_tree().change_scene_to_file("res://menu.tscn")
	
	frame_hit = false
	frame_hit1 = false
	frame_hit2 = false
	
	if subtitles != []:
		if beat >= subtitles[0].time/64:
			if !subtitles[0].clear:
				if !subs_jp.is_empty():
					while subs_jp[0] == "": subs_jp.remove_at(0)
					$subs_jp.text = subs_jp[0]
					subs_jp.remove_at(0)
				if !subs_ro.is_empty():
					while subs_ro[0] == "": subs_ro.remove_at(0)
					$subs_ro.text = subs_ro[0]
					subs_ro.remove_at(0)
				if !subs_en.is_empty():
					while subs_en[0] == "": subs_en.remove_at(0)
					$subs_en.text = subs_en[0]
					subs_en.remove_at(0)
			else:
				$subs_jp.text = ""
				$subs_ro.text = ""
				$subs_en.text = ""
			subtitles.remove_at(0)
			
			if ($subs_en.text == $subs_ro.text && $subs_en.text == $subs_jp.text) or ($subs_en.text == "" && $subs_jp.text == $subs_ro.text):
				$subs_all.text = $subs_ro.text
				$subs_all.show()
				$subs_en.hide()
				$subs_ro.hide()
				$subs_jp.hide()
			else: $subs_all.hide()
	
	if speed_changes != []:
		if beat >= speed_changes[0][1]:
			speed_mult = speed_changes[0][0]
			speed_changes.remove_at(0)
			$syncer.stop()
			$syncer.wait_time = b2s(1)
			$syncer.start(b2s(1))
	
	#if bpm_list != []: #URGENTE
		#if bpm_list[0][1] <= beat:
			#var bpm_old = bpm
			#bpm = bpm_list[0][0]
			#GL.bpm = bpm
			#bpm_list.remove_at(0)
			#for i in $notes.get_children():
				#i.note_tween.set_speed_scale(bpm/bpm_old)
				#if i.hold:
					#i.hold_tween.set_speed_scale(bpm/bpm_old)
				#i.get_node("Timer").wait_time = i.get_node("Timer").time_left / (bpm/bpm_old)
				#i.get_node("Timer").start()
			
	#if beat >= temp:
		#$Sprite2D.modulate.a = 1
		#var a = int($Label.text)
		#a += 1
		#$Label.text = str(a)
		#temp += 1
##		$AudioStreamPlayer2.play()
	#$Sprite2D.modulate.a -= 0.05
	
	if bpm_list != []:
		if bpm_list[0][1] <= beat:
			bpm = bpm_list[0][0]
			GL.bpm = bpm
			bpm_list.remove_at(0)
			$syncer.stop()
			$syncer.wait_time = b2s(1)
			$syncer.start(b2s(1))

func resync():
	pass
	#beat = s2b($AudioStreamPlayer.get_playback_position())


func load_audio(audio):
	return AudioStreamOggVorbis.load_from_file(audio)
#	var file = FileAccess.open(audio,FileAccess.READ)
#	var buffer = file.get_buffer(file.get_length())
#	var stream = AudioStreamOggVorbis.new()
#	var a = OggPacketSequence.new()
#	a.packet_data = buffer
#	stream.packet_sequence = a
##	stream.data = buffer
#	file.close()
#	return stream

func load_song():
	var audio = load_audio(GL.systemdir+"songs/"+GL.song+"/music.ogg")
	var video = load(GL.systemdir+"songs/"+GL.song+"/video.ogv")
	$AudioStreamPlayer.stream = audio
	$Control/VideoStreamPlayer.stream = video



func s2bpm(s):
	return 60/float(s)

func bpm2s(b):
	return 60/float(b)

func s2b(s,bpm_temp = bpm):
	return bpm_temp*s/60.0

func b2s(b,bpm_temp = bpm):
	return 60*b/float(bpm_temp)
	
func s2b2(s2):
	var s = s2 - wait_time - GL.settings.sync
	var a = bpm_list_raw.duplicate()
	var beats = 0
	var seconds = 0
	for i in a.size():
		var temp = 0
		if a.size()-1 >= i+1:
			temp = 60*(a[i+1][1]-a[i][1])/a[i][0]
		else:
			temp = 999999999999
		if s > seconds + temp:
			seconds += temp
		else:
			beats = a[i][1] + a[i][0]/60*(s-seconds)
			break
	return beats
	#return bpm/60*s

func b2s2(b):
	var a = bpm_list_raw.duplicate()
	var seconds = 0
	for i in a.size():
		if a.size()-1 >= i+1:
			if a[i+1][1] <= b:
				seconds += 60*(a[i+1][1]-a[i][1])/float(a[i][0])
			else:
				seconds += 60*(b-a[i][1])/float(a[i][0])
				break
		else:
			seconds += 60*(b-a[i][1])/float(a[i][0])
			break
	return seconds + wait_time


func _on_Timer3_timeout():
	loading = false
	if needs_sync:
		syncing = true
		$sync.wait_time = b2s(sync_amount)
		$sync.start()
		beat = -sync_amount
	else:
		#$Timer.start()
		$AudioStreamPlayer.play()
		$Control/VideoStreamPlayer.play()
		#print($Control/VideoStreamPlayer.get_video_texture().get_size())
		if $Control/VideoStreamPlayer.get_video_texture() != null: $Control/VideoStreamPlayer.scale = Vector2(960,540) / $Control/VideoStreamPlayer.get_video_texture().get_size()


func _on_Button3_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_Button4_pressed():
	get_tree().paused = false
	GL.editor_load = true
	get_tree().change_scene_to_file("res://editor.tscn")


func _on_resync_timeout():
	resync()


func _on_button_5_pressed():
	$Settings.show()
	$pause.hide()
	$Settings.start()


func _on_sync_timeout():
	syncing = false
	$AudioStreamPlayer.play()
	if $Control/VideoStreamPlayer.get_video_texture() != null:
		$Control/VideoStreamPlayer.play()
		#print($Control/VideoStreamPlayer.get_video_texture().get_size())
		$Control/VideoStreamPlayer.scale = Vector2(960,540) / $Control/VideoStreamPlayer.get_video_texture().get_size()
