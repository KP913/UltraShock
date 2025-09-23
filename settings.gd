extends Panel

@onready var u = $".."

func _ready():
	if OS.get_name() == "Android": $Vibration.show()

func start():
	$Master.value = GL.settings.master
	$Song.value = GL.settings.song
	$SFX.value = GL.settings.sfx
	$Sync.text = str(GL.settings.sync)
	$Vibration.value = GL.settings.vibration
	$Brightness.value = GL.settings.brightness
	$jp.button_pressed = GL.settings.subs_jp
	$ro.button_pressed = GL.settings.subs_ro
	$en.button_pressed = GL.settings.subs_en
	$fps.button_pressed = GL.settings.fps
	$Pitch.text = str(GL.settings.pitch)
	$Funny.selected = GL.settings.gamemode

func save():
	GL.settings.master = $Master.value
	GL.settings.song = $Song.value
	GL.settings.sfx = $SFX.value
	GL.settings.sync = float($Sync.text)
	GL.settings.vibration = $Vibration.value
	GL.settings.brightness = $Brightness.value
	GL.settings.subs_jp = $jp.button_pressed
	GL.settings.subs_ro = $ro.button_pressed
	GL.settings.subs_en = $en.button_pressed
	GL.settings.fps = $fps.button_pressed
	GL.settings.pitch = float($Pitch.text)
	GL.settings.gamemode = $Funny.selected

func _on_button_pressed():
	save()
	get_tree().current_scene.update_settings()
	GL.save()
	hide()
	if get_tree().current_scene.is_in_group("level"): $"../pause".show()
	else:
		get_tree().paused = false
		#get_tree().current_scene.settings_open = false

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("pause"):
		#_on_button_pressed()
