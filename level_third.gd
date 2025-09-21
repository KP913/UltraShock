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

const RECEIVER_Y = 280
const LEFT_SIDE = 480
const RIGHT_SIDE = 480
const NOTE_DIRECTION = -1 #1: up to down; -1: down to up

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

var level = []
var level_not_hit = []
var special = []

var level_raw = []
var techs = []
var chances = []

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
	$Label6.text = song_name
	
	for i in info.level:
		var dict = {}
		#dict.time = float(i.time)
		#dict.pos = Vector2(i.posx,i.posy)
		#dict.dir = int(i.dir)
		#dict.button = int(i.button)
		#dict.type = int(i.type)
		#dict.duration = float(i.duration)
		dict.time = float(i.time)
		dict.button = int(i.button)
		dict.flick = int(i.flick)
		dict.double = bool(i.double)
		dict.hold = int(i.hold)
		dict.duration = float(i.duration)
		dict.final = bool(i.final)
		dict.chance = bool(i.chance)
		dict.tech = bool(i.tech)
		dict.second_voice = bool(i.second_voice)
		level.append(dict)
	level_raw = level.duplicate()
	for i in info.special:
		var dict = {}
		dict.time = float(i.time)
		dict.chance = bool(i.chance)
		special.append(dict)
	if info.has("bpm_list"):
		bpm_list = info.bpm_list
	else:
		bpm_list = [[bpm,0]]
	bpm_list_raw = bpm_list.duplicate()
	if info.has("speed_changes"):
		for i in info.speed_changes:
			speed_changes.append([i.speed,i.time/64])
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
	
	
	level.reverse()
	note_count = level.size()-1
	total_notes = level.size()
	var temp = false
	for i in level:
		if i.final:
			temp = true
		if i.chance: 
			total_extra += 5
		if i.tech: 
			total_extra += 3
		if i.hold:
			total_notes += 1
		if i.final: final_total += 1
	if temp: total_extra += 3
	GL.final[0] = 0
	GL.final[1] = final_total
	GL.total_notes = total_notes
	
	time_factor = bpm2s(bpm)
	$Timer.wait_time = 1000 + wait_time
	starting_time = 1000
	
	level_not_hit = level.duplicate()
	
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
	
	if (level[-1].time/64-4/speed_mult) + s2b(wait_time) + s2b(GL.settings.sync) < 0:
		needs_sync = true
		sync_amount = -((level[-1].time/64-4/speed_mult) + s2b(wait_time) + s2b(GL.settings.sync))
	
	$syncer.wait_time = b2s(1)
	$syncer.start(b2s(1))
	
	var tween = get_tree().create_tween()
	#tween.tween_property($notes,"position:y",-128,b2s(1))
	move_tween = tween

func _notification(what):
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT && OS.get_name() == "Android" && !get_tree().paused:
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
	if !$subs_all.visible:
		$subs_en.visible = GL.settings.subs_en
		$subs_ro.visible = GL.settings.subs_ro
		$subs_jp.visible = GL.settings.subs_jp
	
	
	if loading:
		return
	
	$Sprite2D4.rotation = PI/2+lerp(-PI/2,-PI/4,sin(beat*PI/8))
	$Sprite2D5.rotation = PI/2+lerp(PI/2,3*PI/4,sin(beat*PI/8))
	
	
	if !syncing:
		beat = s2b2($AudioStreamPlayer.get_playback_position())#starting_time - $Timer.time_left)
	else:
		beat = s2b(-$sync.time_left - wait_time - GL.settings.sync)
	
	#$notes.position.y = -128*beat
	
	$Label5.text = "FINALS: "+str(finals_have)+"/"+str(final_total)
	#temp2 = temp1
	#temp1 = beat
	#if temp2 > fmod(temp1,1) && beat >= 0: hit_sound("hit")
	#if beat >= 0 && !temp3:
		#temp3 = true
		#hit_sound("hit")
	if $AudioStreamPlayer.get_playback_position() >= song_length or ($AudioStreamPlayer.get_playback_position() == 0 && !loading && !syncing):
		get_tree().change_scene_to_file("res://results.tscn")
	
	frame_hit = false
	frame_hit1 = false
	frame_hit2 = false
	
	if level != []:
		next_time = (level[note_count].time/64)-4/speed_mult
		if beat >= next_time:
			spawn_note(level[note_count])
			level.remove_at(note_count)
			note_count -= 1
	
	
	if special != []:
		if beat >= special[0].time/64:
			spawn_special(2*int(special[0].chance),special[0].time)
			special.remove_at(0)
	
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
			else:
				$subs_all.hide()
				$subs_en.show()
				$subs_ro.show()
				$subs_jp.show()
	
	if speed_changes != []:
		if beat >= speed_changes[0][1]:
			speed_mult = speed_changes[0][0]
			speed_changes.remove_at(0)
			_on_syncer_timeout()
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
			_on_syncer_timeout()
			$syncer.stop()
			$syncer.wait_time = b2s(1)
			$syncer.start(b2s(1))

func _input(event):
	if event.is_action_pressed("circle") or event.is_action_pressed("circle2") or event.is_action_pressed("cross") or event.is_action_pressed("cross2") or event.is_action_pressed("square") or event.is_action_pressed("square2") or event.is_action_pressed("triangle") or event.is_action_pressed("triangle2"):
		hit_sound("hit")

func hit_sound(sound,volume_add=0):
	var a = AudioStreamPlayer.new()
	a.stream = load("res://sfx/"+sound+".wav")
	a.volume_db = sfx_volume+volume_add
	if sfx_volume == -50: a.volume_db = -99999999999999
	$sfx.add_child(a)
	a.play()

func spawn_note(info):
	#if info.button == 5:
		#spawn_special(int(info.type))
		#return
	
	var note = preload("res://target_third.tscn").instantiate()
	
	if info.second_voice:
		if GL.settings.gamemode == 3: note.angle = beat*PI/4
		if GL.settings.gamemode == 4: note.angle = lerp(PI/2,3*PI/4,sin(beat*PI/8))#lerp(-PI/2,-PI/4,sin(beat*PI/8))
		if GL.settings.gamemode == 5: note.angle = randf_range(PI/4,3*PI/4)#randf_range(-3*PI/4,-PI/4)
		print(beat,",",note.angle)
		note.position.x = RIGHT_SIDE# + snapped(randf_range(0,200),16)
	else:
		if GL.settings.gamemode == 3: note.angle = beat*PI/4+PI
		if GL.settings.gamemode == 4: note.angle = lerp(-PI/2,-PI/4,sin(beat*PI/8))#lerp(PI/2,3*PI/4,sin(beat*PI/8))
		if GL.settings.gamemode == 5: note.angle = randf_range(-3*PI/4,-PI/4)#randf_range(PI/4,3*PI/4)
		print(beat,",",note.angle)
		note.position.x = LEFT_SIDE# - snapped(randf_range(0,200),16)
	note.position = Vector2(LEFT_SIDE,RECEIVER_Y) + Vector2(0,NOTE_DIRECTION*512 + NOTE_DIRECTION*(beat-((info.time/64)-4/speed_mult))*128*speed_mult).rotated(note.angle) #160+512
	note.start_time -= beat-((info.time/64)-4/speed_mult)
	#print(note.global_position,$notes.position,beat)
	#note.button = info.button
	#note.type = info.type
	note.time = info.time
	note.button = info.button
	note.flick = info.flick
	note.double = info.double
	note.hold = info.hold
	note.duration = info.duration
	note.final = info.final
	note.chance = info.chance
	note.tech = info.tech
	note.second_voice = info.second_voice
	if info.hold:
		note.duration = info.duration
	
	$notes.add_child(note)
	note_array.append(note)
	if note.second_voice: note_array2.append(note)
	else: note_array1.append(note)

func spawn_special(type,time):
	match type:
		0: #tech
			var c = 0
			var a = level_raw.duplicate()
			var start = false
			for i in a:
				if i.time >= time: start = true
				if start:
					c += 1
					if i.hold: c += 1
					if i.tech: break
			tech_rest = c
			$Label3.text = "REST: "+str(tech_rest)
			GL.tech[1] += 1
			technical = true
			$Label3.show()
		2: #chance
			var c = 0
			var a = level_raw.duplicate()
			var start = false
			for i in a:
				if i.time >= time: start = true
				if start:
					c += 1
					if i.hold: c += 1
					if i.chance: break
			chance_need = floori(c*0.8)
			chance_have = 0
			$Label4.text = "CHANCE: 0/"+str(chance_need)
			#$Label5.text = str(chance_need)
			chance = true
			$Label4.show()
			#$Label5.show()

func note_hit(note, text, hold = false, chance_note = false, holded = false):
	#print(note.final)
	#print(note,hold,holded)
	if chance_note && !holded:
		if chance_have >= chance_need and (text == "COOL" or text == "GOOD"):
			extra_points += 5
			GL.chance[0] += 1
		GL.chance[1] += 1
		$Label4.hide()
		#$Label5.hide()
		chance = false
	
	if !hold:
		note_array.remove_at(0)
		if note.second_voice: note_array2.remove_at(0)
		else: note_array1.remove_at(0)
	#print(note.final)
	
	if text != "MISS":
		if note.double or note.hold:
			for i in $sfx.get_children():
				if i.get_playback_position() < 0.2 && i.stream == preload("res://sfx/hit.wav"):
					i.queue_free()
		if chance_note && !holded && (text == "GOOD" or text == "COOL"):
			hit_sound("chance",7)
			Input.start_joy_vibration(0,0.8,0.8,0.6)
		elif note.final && !hold:
			hit_sound("final",-2)
			Input.start_joy_vibration(0,0.6,0.5,0.5)
		elif hold:
			hit_sound("hold_start")
			var a = AudioStreamPlayer.new()
			a.stream = load("res://sfx/hold_mid.wav")
			a.volume_db = sfx_volume
			if sfx_volume == -50: a.volume_db = -99999999999999
			$sfx.add_child(a)
			if note.second_voice: 
				if hold2_sfx != null: hold2_sfx.kill()
				hold2_sfx = a
			else:
				if hold1_sfx != null: hold1_sfx.kill()
				hold1_sfx = a
			await get_tree().create_timer(0.2)
			a.play()
		elif note.double:
			hit_sound("double",2)
			Input.start_joy_vibration(0,0.3,0.3,0.2)
		elif note.flick: hit_sound("flick")
		elif holded:
			if note.double: hit_sound("double")
			elif note.flick: hit_sound("flick")
			else: hit_sound("hold_end")
			Input.start_joy_vibration(0,0.3,0.3,0.2)
	#else:
		#if note.second_voice: if hold2_sfx != null: hold2_sfx.kill()
		#else: if hold1_sfx != null: hold1_sfx.kill()
	#if note.holding: 
		#if note.second_voice: hold2_sfx.stop()
		#else: hold1_sfx.stop()
	
	
	#print(note.final)
	var arr = ["COOL","GOOD","SAFE","BAD","MISS"]
	GL.note_scores[arr.find(text)] += 1
	if text == "MISS" && hold == false && holded == false && note.hold == 1: GL.note_scores[4] += 1
	#GL.total_notes += 1
	
	if text == "COOL" or text == "GOOD":
		
		#print(note.final)
		notes_hit += 1
		combo += 1
		if combo > GL.combo:
			GL.combo = combo
		#if $Timer2.is_stopped():
		tech_rest -= 1
		chance_have += 1
		$Label3.text = "REST: " + str(tech_rest)
		$Label4.text = "CHANCE: "+str(chance_have)+"/"+str(chance_need)
		if technical && tech_rest == 0:
			extra_points += 3
			$Label3.hide()
			technical = false
			GL.tech[0] += 1
		if note.final && !hold:
			finals_have += 1
			extra_points += 3/float(final_total)
			GL.final[0] += 1
		update_score()
	else:
		combo = 0
		for i in 8:
			if note_array.size() >= i+1:
				if is_instance_valid(note_array[i]):
					note_array[i].final = false
		if technical:
			technical = false
			$Label3.hide()
	
	var a = preload("res://score_popup.tscn").instantiate()
	a.text = text
	if combo >= 2:
		a.text += " " + str(combo)
	a.position.x = note.position.x - 16
	a.position.y = RECEIVER_Y - 40 * NOTE_DIRECTION
	a.scale = Vector2(0.8,0.8)
	a.second_voice = note.second_voice
	$scores.add_child(a)
	
	if level_not_hit.size() != 0:
		level_not_hit.remove_at(level_not_hit.size()-1)
	
	
	var style2 = StyleBoxTexture.new()
	style2.texture = GradientTexture2D.new()
	style2.texture.gradient = Gradient.new()
	var color = Color.WHITE
	if score >= 80:
		if score >= 90:
			if score >= 95:
				if score >= 98:
					if score >= 100:
						color = Color.YELLOW
					else:
						color = Color.MAGENTA
				else:
					color = Color.CYAN
			else:
				color = Color.GREEN
		else:
			color = Color.BLUE
	else:
		color = Color.RED
	var color2 = color
	var color3 = color
	color.s *= 0.6
	color.v *= 0.6
	color2 = color2.blend(Color(0.3,0.3,0.3,0.3))
	color2.v *= 1.3
	color2.s *= 0.7
	color3 = color2
	color3.v *= 0.7
	color3.s *= 0.6
	style2.texture.gradient.colors = [color,color2,color3]
	style2.texture.gradient.offsets = [0,0.8,1]
	style2.texture.fill_from.y = 0.5
	#style2.bg_color.s *= 0.4
	$ProgressBar.add_theme_stylebox_override("fill",style2)

func resync():
	pass
	#beat = s2b($AudioStreamPlayer.get_playback_position())


func update_score():
	score = (notes_hit / float(total_notes) * 100)
	score *= ((100-total_extra)/100.0)
	score += extra_points
	$ProgressBar.value = score
	$Label2.text = str(snapped(score,0.01))
	#if score < 100:
		#$Label2.text = str(snapped(score,0.01))
		#match $Label2.text.length():
			#1: $Label2.text = "0"+$Label2.text+".00%"
			#2: $Label2.text = $Label2.text+".00%"
			#4: $Label2.text = $Label2.text+"0%"
			#5: $Label2.text = $Label2.text+"%"
	#else:
		#$Label2.text = "100.00%"
	GL.score = score


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


func _on_syncer_timeout():
	#print($notes.position.y)
	move_tween.stop()
	#ISTO É ESSENCIAL vvvv
	#var tween = get_tree().create_tween()
	#tween.tween_property($notes,"position:y",$notes.position.y+128*speed_mult,b2s(1))
	#move_tween = tween
