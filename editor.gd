extends Node2D

var on_menu = false
var rainbow_shader = preload("res://rainbow.gdshader")

var settings_open = false

func _ready():
	$timeline.sfx_volume = (GL.settings.sfx + GL.settings.master)/2 - 50
	if GL.editor_load:
		$settings/song.text = GL.song
		_on_load_pressed()
	if OS.get_name() == "Android":
		$touch.show()
	$AudioStreamPlayer.volume_db = (GL.settings.song + GL.settings.master)/2 - 50
	
	if GL.settings.master == 0 or GL.settings.song == 0: $AudioStreamPlayer.volume_db = -99999999999
	setup_touch()
	$timeline.update_subs()

func setup_touch():
	for i in $touch.get_children():
		if i is TouchScreenButton:
			i.connect("pressed",GL.vibrate)
		else:
			for u in i.get_children():
				if u is TouchScreenButton:
					u.connect("pressed",GL.vibrate)
				else:
					for j in u.get_children():
						if j is TouchScreenButton:
							j.connect("pressed",GL.vibrate)
						else:
							pass

func _on_Button_pressed():
	on_menu = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property($Camera2D,"position",Vector2(0,-540),0.6)

func _on_Button2_pressed():
	on_menu = false
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property($Camera2D,"position",Vector2(0,0),0.6)

func _process(delta):
	$timeline.wait_time = float($settings/wait_time.text)
	$timeline.bpm = float($settings/bpm.text)
	$timeline.beats = int($settings/beats.text)
	$timeline.division = int($settings/division.text)
	if !$timeline.playing:
		$touch/edit_touch.show()
		$touch/play_touch.hide()
	else:
		$touch/edit_touch.hide()
		$touch/play_touch.show()

func update_settings():
	pass

func load_audio(audio):
	return AudioStreamOggVorbis.load_from_file(audio)

func load_song():
	var audio = load_audio(GL.systemdir+"songs/"+$settings/song.text+"/music.ogg")
	$AudioStreamPlayer.stream = audio
	$timeline.song_length = audio.get_length()

func _on_load_song_pressed():
	load_song()

func sort_key(a:String,b:String):
	return int(a.split("p")[0]) < int(b.split("p")[0])

func _on_save_pressed():
	$timeline.update_bpm()
	var level = []
	var total = 0
	var keys = $timeline.level.keys()
	keys.sort_custom(sort_key)
	for u in keys:
		var i = $timeline.level[u]
		var dict = {}
		dict.key = u
		dict.ninths = i.ninths
		dict.time = i.time
		dict.button = i.button
		dict.flick = i.flick
		dict.double = i.double
		dict.hold = i.hold
		dict.duration = i.duration
		dict.final = i.final
		dict.chance = i.chance
		dict.tech = i.tech
		dict.second_voice = i.second_voice
		total += 1
		if i.hold: total += 1
		level.append(dict)
	#level.sort_custom(Callable(self, "sort_custom"))
	
	var info = {}
	info.wait_time = float($settings/wait_time.text)
	info.bpm = float($settings/bpm.text)
	info.beats = int($settings/beats.text)
	info.division = int($settings/division.text)
	info.name = $settings/name.text
	info.song = $settings/song.text
	info.producer = $settings/producer.text
	info.difficulty = float($settings/difficulty.text)
	info.speed = float($settings/speed.text)
	info.completed = $settings/completed.button_pressed
	info.interval = $timeline.playing_interval
	info.level = level
	info.total = total
	var special = []
	for i in $timeline/special.get_children():
		var dict = {}
		dict.time = i.time
		dict.chance = i.chance
		dict.ninths = i.ninths
		special.append(dict)
	special.sort_custom(Callable(self, "sort_custom"))
	info.special = special
	var subs = []
	for i in $timeline/subtitles.get_children(): 
		subs.append({"time":i.get_meta("time"),"clear":i.get_meta("clear"),"ninths":i.get_meta("ninths")})
	subs.sort_custom(Callable(self, "sort_custom"))
	info.subtitles = subs
	var bpm_changes = []
	for i in $timeline/time_changes.get_children():
		bpm_changes.append({"time":i.get_meta("time"),"ninths":i.get_meta("ninths"),"bpm":float(i.text)})
	var speed_changes = []
	for i in $timeline/speed_changes.get_children():
		speed_changes.append({"time":i.get_meta("time"),"ninths":i.get_meta("ninths"),"speed":float(i.text)})
	bpm_changes.sort_custom(Callable(self, "sort_custom"))
	speed_changes.sort_custom(Callable(self, "sort_custom"))
	info.bpm_changes = bpm_changes
	info.speed_changes = speed_changes
	if $AudioStreamPlayer.stream is AudioStreamOggVorbis:
		info.duration = $AudioStreamPlayer.stream.get_length()
	if has_node("timeline/checkpoint"):
		info.checkpoint = [$timeline/checkpoint.get_meta("time"),$timeline.b2s2($timeline/checkpoint.get_meta("time")/64),$timeline/checkpoint.get_meta("ninths"),$timeline.b2s2($timeline/checkpoint.get_meta("ninths")/9)]
	info.bpm_list = $timeline.bpm_list
	GL.cached_levels[info.song] = info
	var q = FileAccess.open(GL.systemdir+"songs/"+info.song+"/level.lvl",2)
	q.store_string(JSON.new().stringify(info))
	q.close()


func _on_load_pressed():
	var q = FileAccess.open(GL.systemdir+"songs/"+$settings/song.text+"/level.lvl",1)
	var test_json_conv = JSON.new()
	test_json_conv.parse(q.get_as_text())
	var info = test_json_conv.get_data()
	q.close()
	
	for i in $timeline/notes.get_children():
		i.queue_free()
	$timeline.level = {}
	if $timeline.has_node("checkpoint"): $timeline/checkpoint.queue_free()
	
	$timeline.create_bars()
	#print(info.level)
	for i in info.level:
		var a = {}
		#print(i)
		#var a = preload("res://editor_note.tscn").instantiate()
		if i.has("ninths"): a.ninths = i.ninths
		else: a.ninths = snappedf(9*i.time/64,0.0625)
		a.time = i.time
		a.button = i.button
		a.flick = i.flick
		a.double = i.double
		a.hold = i.hold
		a.duration = i.duration
		a.final = i.final
		a.chance = i.chance
		a.tech = i.tech
		a.second_voice = i.second_voice
		var key
		if i.has("key"): key = i.key
		else: key = str(a.ninths).replace(".","p")+("a" if !a.second_voice else "b")
		
		$timeline.level[key] = a
		var note_node = $timeline.spawn_note(key,true)
		
		if a.chance:
			note_node.material = ShaderMaterial.new()
			note_node.material.shader = rainbow_shader
		#a.position.x = fmod(a.time,512)
		#a.position.y = floor(a.time/512.0)*128 + int(a.second_voice)*32
		#a.position.x = i.time*64
		#a.position.x += 256
		#a.pos = Vector2(i.posx,i.posy)
		#a.dir = i.dir
		#a.button = i.button
		#a.type = i.type
		#a.duration = i.duration
		#$timeline/notes.add_child(a)
	#print($timeline/notes.get_child_count())
	for i in info.special:
		var a = preload("res://special.tscn").instantiate()
		a.time = i.time
		if !i.has("ninths"): i.ninths = i.time/64*9
		a.ninths = i.ninths
		a.chance = i.chance
		a.position.x = fmod(a.ninths,72)/9*64
		a.position.y = floor(a.ninths/72.0)*128+64
		$timeline/special.add_child(a)
	if info.has("subtitles"):
		for i in info.subtitles:
			var a = Sprite2D.new()
			a.set_meta("time",i.time)
			if !i.has("ninths"): i.ninths = i.time/64*9
			a.set_meta("ninths",i.ninths)
			a.set_meta("clear",i.clear)
			a.position.x = fmod(i.ninths,72)/9*64
			a.position.y = floor(i.ninths/72.0)*128+64
			a.scale = Vector2(2,2)
			a.centered = false
			if !i.clear: a.texture = preload("res://gfx/subtitle.png")
			else: a.texture = preload("res://gfx/subclear.png")
			$timeline/subtitles.add_child(a)
	if info.has("bpm_changes"):
		for i in info.bpm_changes:
			var a = LineEdit.new()
			a.set_meta("time",i.time)
			if !i.has("ninths"): i.ninths = i.time/64*9
			a.set_meta("ninths",i.ninths)
			a.position.x = fmod(i.ninths,72)/9*64
			a.position.y = floor(i.ninths/72.0)*128-32
			a.scale = Vector2(0.75,0.75)
			a.text = str(i.bpm)
			$timeline/time_changes.add_child(a)
	if info.has("checkpoint"):
		if info.checkpoint.size() == 2: info.checkpoint.append(info.checkpoint[0]/64*9)
		var time = info.checkpoint[0]
		var ninths = info.checkpoint[2]
		var a = Sprite2D.new()
		print("!!!!!!",ninths)
		a.position.x = fmod(ninths,72)/9*64
		a.position.y = floor(ninths/72.0)*128+64
		a.scale = Vector2(0.125,0.125)
		a.centered = false
		a.texture = preload("res://gfx/receiver.png")
		a.set_meta("time",time)
		a.set_meta("ninths",ninths)
		a.name = "checkpoint"
		$timeline.add_child(a)
	$settings/wait_time.text = str(info.wait_time)
	$settings/bpm.text = str(info.bpm)
	$settings/beats.text = str(info.beats)
	$settings/division.text = str(info.division)
	$settings/name.text = info.name
	$settings/song.text = info.song
	if info.has("producer"): $settings/producer.text = info.producer
	if info.has("difficulty"): $settings/difficulty.text = str(info.difficulty)
	if info.has("completed"): $settings/completed.button_pressed = info.completed
	if info.has("speed"): $settings/speed.text = str(info.speed)
	#if info.has("interval"):
	$timeline.playing_interval = info.interval
	$LineEdit.text = str(info.interval)
	$timeline.bpm_list = [[info.bpm,0]]
	load_song()
	
func sort_custom(a, b):
	if a.ninths < b.ninths:
		return true
	return false



func _on_play_pressed():
	_on_save_pressed()
	GL.song = $settings/song.text
	GL.enter_level()


func _on_menu_pressed():
	_on_save_pressed()
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_menu2_button_up():
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_Button5_pressed():
	if $timeline.overlap == null:
		return
	var time_base = $timeline.overlap.position.x
	var time_end = time_base+255
	var note_arr = []
	for i in $timeline/notes.get_children():
		if i.position.x >= time_base && i.position.x <= time_end:
			note_arr.append(i)
	
	for i in range(4):
		note_arr[i].dir = -i*22.5-90-90-90-90-90-90-90-90
