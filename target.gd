extends Node2D

var time = 0.0
var end_time = 0.0

var button = 0
var flick = 0 #none up down
var double = false
var hold = 0 #none normal spin
var duration = 0.0
var final = false
var chance = false
var tech = false
var second_voice = false
var hold_changes = [] #{"time":32,"button":0}

var start_time = 4
var stopped = false

var fail_time_before = 0.09 #TAVA A 0.11
var fail_time_after = 0.11 #TAVA A 0.11

var flick_timing = 110.3
var flick_threshold = 5
var flick_start_pos = 0.0
var flick_frame = false

#var button : int #cross circle square triangle
#var dir = 0
#var type : int #normal double hold
#var duration = 0.0

@onready var main = $"../.."

var holding = false
var holding_second = false

var flicking = 0
var flicking_second = false
var flick_hold = 0

var timing = 0
var start_beat = 0
var unhold_time = 0

var starting_position_x = 0

var note_tween : Tween
var hold_tween : Tween

func _ready():
	#physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	$Timer2.wait_time = flick_timing
	#$note.position = Vector2(0,512)#.rotated(deg_to_rad(dir))
	#$note2.position = Vector2(0,512+128*duration)#.rotated(deg_to_rad(dir))
	$note2.position = Vector2(0,128*duration*main.speed_mult)
	
	
	#if OS.get_name() != "Android": flick = 0
	
	var tween = get_tree().create_tween()
	#print(position.y)
	tween.tween_property(self,"position:y",160-512,b2s(8/main.speed_mult))
	#tween.finished.connect(_on_Tween_tween_all_completed)
	note_tween = tween
	#if hold:
		#var tween2 = get_tree().create_tween()
		#tween2.tween_property($note2,"position:y",160-512+128*main.speed_mult*duration,b2s(2*(4+128*main.speed_mult*duration)))
		#tween2.bind_node($note2)
		#hold_tween = tween2
	
	#$Sprite2D.frame_coords.x = 2*flick+int(double)
	#$Sprite2D.frame_coords.y = button
	$note.frame_coords.x = 2*flick+int(double)
	$note.frame_coords.y = button
	$note2.frame_coords.x = 2*flick+int(double)
	$note2.frame_coords.y = button
	
	#if !hold: start_time = 4
	if hold: start_time += duration
	
	#$Timer.wait_time = b2s(start_time+4)
	#$Timer.start()
	
	if !hold:
		$note2.queue_free()
		$Line2D.queue_free()
		#tween.stop()

	if chance:
		$note.material = ShaderMaterial.new()
		$note.material.shader = main.rainbow_shader
		#$note/Sprite2D.scale = Vector2(1.3,1.3)
	
	start_beat = main.beat
	
	starting_position_x = position.x

func restart_tweens():
	if note_tween != null && note_tween.is_valid():
		note_tween.kill()
		var tween = get_tree().create_tween()
		#print("a ",main.beat-start_beat)
		tween.tween_property(self,"position:y",160-512,b2s((8/main.speed_mult-(main.beat-start_beat))))
		#tween.tween_property(self,"position:y",160,b2s((8-(main.beat-start_beat))/main.speed_mult))
		note_tween = tween
	if hold_tween != null && hold_tween.is_valid():
		hold_tween.kill()
		var tween2 = get_tree().create_tween()
		
		tween2.tween_property($note2,"position:y",0,b2s(duration-(main.beat-unhold_time)))
		tween2.bind_node($note2)
		hold_tween = tween2

func _physics_process(delta: float) -> void:
	var off = 0.05
	#if !stopped: position.y = 672 - ((main.beat+off)-((time/64)-4/main.speed_mult))*128*main.speed_mult
	#else: $note2.global_position.y = 128*main.speed_mult*duration+ ( 672 - ((main.beat+off)-((time/64)-4/main.speed_mult))*128*main.speed_mult )

var c = 0
func _process(delta):
	c += 1
	if c == 15:
		restart_tweens()
		c = 0
	#print($note.position.y)
	#if hold: print(note_tween != null && note_tween.is_valid(),",",hold_tween != null && hold_tween.is_valid())
	#if stopped != -1: $note.position.y = stopped - get_parent().position.y
	timing = b2s(start_time+4/main.speed_mult) - (main.beat - start_beat)*60/main.bpm
	#if timing == 0: hit()
	#if time == 512: debug(str(timing))
	#print($Timer.time_left,",",timing)
	
	if GL.godmode:
		if !hold && b2s(start_time)-timing >= 0:
			print("Start time: ",start_time)
			print("Speed mult: ",main.speed_mult)
			print("Beat: ",main.beat)
			print("Start beat: ",start_beat)
			print("BPM: ",main.bpm)
			print("Position: ",position.y)
			print()
			print()
			main.hit_sound("hit")
			hit()
		if hold:
			if !holding && b2s(start_time)-timing >= 0:
				hit(false,true)
				holding = true
				stopped = true#get_parent().position.y
				#reparent($"../../notes_still")
				unhold_time = main.beat
				if note_tween != null:
					note_tween.kill()
					var tween2 = get_tree().create_tween()
					tween2.tween_property($note2,"position:y",0,b2s(duration))
					tween2.bind_node($note2)
					hold_tween = tween2
			if holding && b2s(start_time-duration)-timing >= 0:
				main.hit_sound("hit")
				hit()
	
	#if time == 512:
		#debug(str(s2b($Timer.time_left))+","+str(time))
	
	#o funny:
	#if !holding: position.x = starting_position_x + sin((main.beat-(start_beat+4/main.speed_mult))*PI/2)*10
	if final:
		modulate = Color(randf(),randf(),randf(),1)
	else:
		modulate = Color.WHITE
	if hold:
		$Line2D.points[0] = $note.position
		$Line2D.points[1] = $note2.position
	
	if b2s(start_time)-timing >= fail_time_after && !holding:
		hit(true)
	
	if holding && b2s(start_time)-timing-b2s(duration) >= fail_time_after:
		hit(true)
	
	var a = ["cross","circle","square","triangle"]
#		if $note in get_overlapping_areas() && main.note_array[0] == self:
	if !holding && !flicking && (get_value(main.note_array1,0) == self or get_value(main.note_array2,0) == self) && timing - b2s(start_time) <= fail_time_before:
		#$"../..".modulate = Color(randf(),randf(),randf(),1)
		
		var press1 = Input.is_action_just_pressed(a[button]) && !main.key_locks[button]
		var press2 = Input.is_action_just_pressed(a[button]+"2") && !main.key_locks[button+4]
		var held1 = Input.is_action_pressed(a[button])
		var held2 = Input.is_action_pressed(a[button]+"2")
		if (double && ((held1 && press2) or (press1 && held2))) or (!double && (press1 or press2)) && !((second_voice && main.frame_hit2) or (!second_voice && main.frame_hit1)):
			if press1 && press2:
				if double:
					main.key_locks[button] = true
					main.key_locks[button+4] = true
				else:
					if main.key_locks[button] == true: main.key_locks[button+4] = true
					main.key_locks[button] = true
			else:
				if press1: main.key_locks[button] = true
				if press2: main.key_locks[button+4] = true
			if hold:
				#debug("asd")
				var q = hit(false, true)
				if q != "womp womp":
					holding = true
					holding_second = press2
					stopped = true#get_parent().position.y
					#reparent($"../../notes_still")
					unhold_time = main.beat
					if note_tween != null:
						note_tween.kill()
						var tween2 = get_tree().create_tween()
						tween2.tween_property($note2,"position:y",0,b2s(duration))
						tween2.bind_node($note2)
						hold_tween = tween2
					if OS.get_name() == "Android" && !main.controller: flick_hold = flick
			elif flick:
				if OS.get_name() == "Android" && !main.controller:
					#debug("fgh")
					flicking = flick
					flicking_second = Input.is_action_just_pressed(a[button]+"2")
					flick_frame = true
					debug("Started flicking!")
					$Timer2.start()
				else:
					hit()
			else:
				hit()
		#if !flick && !double && !hold && (press1 or press2):
			#hit()
		#elif !flick && double && !hold && ((held1 && press2) or (press1 && held2)):
			#hit()
		#elif !flick && hold && !double && (press1 or press2):
			#hit(false, true)
			#holding = true
			#holding_second = press2
			#if note_tween != null:
				#note_tween.kill()
		#elif !flick && double && hold && ((held1 && press2) or (press1 && held2)):
			#hit(false, true)
			#holding = true
			#if note_tween != null:
				#note_tween.kill()
		#elif flick && !double && !hold && (press1 or press2):
			#flicking = flick
			#flicking_second = Input.is_action_just_pressed(a[button]+"2")
			#$Timer2.start()
		#elif flick && double && !hold && ((held1 && press2) or (press1 && held2)):
			#flicking = flick
			#$Timer2.start()
			
	
	
	if holding:
		if (get_value(main.note_array1,0) == self or get_value(main.note_array2,0) == self) && timing - b2s(4) <= fail_time_before: #MUDEI ISTO, ANTES: $Timer.time_left - b2s(duration) - b2s(start_time)
			if !flick_hold:
				#debug(str($Timer.time_left) +","+ str(b2s(duration)) +","+ str(b2s(start_time)))
				if double && (Input.is_action_just_released(a[button]) or Input.is_action_just_released(a[button]+"2")):
					hit(false,false,true)
				if !double && ((Input.is_action_just_released(a[button]) && !holding_second) or (Input.is_action_just_released(a[button]+"2") && holding_second)):
					hit(false,false,true)
			elif flicking == 0:
				#debug(str($Timer.time_left) +","+ str(b2s(duration)) +","+ str(b2s(start_time)))
				flicking = flick
				flicking_second = holding_second
				flick_frame = true
				debug("Started flicking!")
				$Timer2.start()
		else:
			if ((Input.is_action_just_released(a[button]) && !holding_second) or (Input.is_action_just_released(a[button]+"2") && holding_second)):
				hit(true,false,true)

func _input(event: InputEvent) -> void:
	if flick_frame && (event is InputEventScreenTouch or event is InputEventScreenDrag):
		if (event.position.x < 480 && !flicking_second) or (event.position.x > 480 && flicking_second):
			flick_start_pos = event.position.y
			flick_frame = false
			debug("Flick pos determined: "+str(event.position.y))
	
	if flicking && !flick_frame && (event is InputEventScreenTouch or event is InputEventScreenDrag):
		debug("Step 1")
		if !double:
			if (event.position.x < 480 && !flicking_second) or (event.position.x > 480 && flicking_second):
				debug("Step 2 - flick_start_pos: "+str(flick_start_pos)+"; position.y: "+str(event.position.y)+"; delta: "+str(event.position.y-flick_start_pos))
				if (flicking == 1 && event.position.y-flick_start_pos <= -flick_threshold) or (flicking == 2 && event.position.y-flick_start_pos >= flick_threshold):
					debug("Flicked!")
					hit(false,false,hold)
		else:
			if (flicking == 1 && event.position.y-flick_start_pos <= -flick_threshold) or (flicking == 2 && event.position.y-flick_start_pos >= flick_threshold):
				debug("Flicked!")
				hit(false,false,hold)
		#if !double:
			#if (flicking == 1 && ((!flicking_second && Input.is_action_just_pressed(a[button]+"_up")) or (flicking_second && Input.is_action_just_pressed(a[button]+"2_up")))) or (flicking == 2 && ((!flicking_second && Input.is_action_just_pressed(a[button]+"_down")) or (flicking_second && Input.is_action_just_pressed(a[button]+"2_down")))):
				#hit(false,false,hold)
		#else:
			#if (flicking == 1 && (Input.is_action_just_pressed(a[button]+"_up") or Input.is_action_just_pressed(a[button]+"2_up"))) or (flicking == 2 && (Input.is_action_just_pressed(a[button]+"_down") or Input.is_action_just_pressed(a[button]+"2_down"))):
				#hit(false,false,hold)

func debug(text):
	$"../../Label7".text += text+"\n"

func hit(miss = false, start_hold = false, holded = false):
	if ((second_voice && main.frame_hit2) or (!second_voice && main.frame_hit1)):
		return "womp womp"
	#if hold: print(time,",",start_hold)
	main.frame_hit = true
	if second_voice: main.frame_hit2 = true
	else: main.frame_hit1 = true
	
	if holding:
		if second_voice && $"../..".hold2_sfx != null:
			$"../..".hold2_sfx.stop()
			$"../..".hold2_sfx = null
		if !second_voice && $"../..".hold1_sfx != null:
			$"../..".hold1_sfx.stop()
			$"../..".hold1_sfx = null
	#if hold:
		#print(start_time,",",$Timer.time_left,",",b2s(start_time))
	var offset = abs(b2s(start_time)-timing)
	if holding:
		offset = abs(b2s(start_time-duration)-timing)
	#if holding: print(offset,",",$Timer.time_left,",",duration,",",b2s(start_time-duration))
	
	var score = ""
	
	#if offset <= 0.03:
		#score = "COOL"
	#elif offset <= 0.06:
		#score = "GOOD"
	#elif offset <= 0.08:
		#score = "SAFE"
	#elif offset <= 0.11:
		#score = "BAD"
	#else:
		#score = "MISS"
	var hitted = false
	if offset <= 0.05:
		score = "COOL"
		hitted = true
	elif offset <= 0.08:
		score = "GOOD"
		hitted = true
	elif offset <= 0.11:
		score = "SAFE"
	elif offset <= 0.14 :
		score = "BAD"
	else:
		score = "MISS"
	
	if miss:
		score = "MISS"
	#score = str(snappedf(start_time-s2b(timing),0.01))
	#if !hold: print(start_time-s2b(timing),",",position.y-160,",",(start_time-s2b(timing))/(position.y-160))
	#print("asd",",",time,",",score,",",hold,",",holded)
	main.note_hit(self, score, hitted, miss, start_hold, chance, holded)
	if !start_hold:
		queue_free()


func s2b(s):
	return GL.bpm*s/60

func b2s(b):
	return 60*b/GL.bpm


func _on_Tween_tween_all_completed():
	hit()

func get_value(arr:Array,n:int):
	if arr.size() > n:
		return arr[n]


func _on_timer_2_timeout():
	if flicking:
		hit(true)
