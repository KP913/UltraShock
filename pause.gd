extends Node2D

func _ready():
	if OS.get_name() == "Android": $touchconfig.show()

func _input(event):
	if event.is_action_pressed("pause") && !$"../Settings".visible:
		get_tree().paused = !get_tree().paused
		visible = get_tree().paused
		$"../Control/VideoStreamPlayer".paused = visible
	elif event.is_action_pressed("pause") && $"../Settings".visible:
		$"../Settings"._on_button_pressed()
	
	var c = false
	for i in $touchconfig.get_children(): if i is Button: if i.button_pressed: c = true
	if c && OS.get_name() == "Android" && event is InputEventScreenTouch && event.pressed:
		if $touchconfig/Button.button_pressed: GL.settings.lposx += 8
		if $touchconfig/Button2.button_pressed: GL.settings.lposx -= 8
		if $touchconfig/Button3.button_pressed: GL.settings.lposy += 8
		if $touchconfig/Button4.button_pressed: GL.settings.lposy -= 8
		if $touchconfig/Button5.button_pressed: GL.settings.lscale += 1
		if $touchconfig/Button6.button_pressed: GL.settings.lscale -= 1
		if $touchconfig/Button7.button_pressed: GL.settings.ldist += 2
		if $touchconfig/Button8.button_pressed: GL.settings.ldist -= 2
		if $touchconfig/Button9.button_pressed: GL.settings.rposx += 8
		if $touchconfig/Button10.button_pressed: GL.settings.rposx -= 8
		if $touchconfig/Button11.button_pressed: GL.settings.rposy += 8
		if $touchconfig/Button12.button_pressed: GL.settings.rposy -= 8
		if $touchconfig/Button13.button_pressed: GL.settings.rscale += 1
		if $touchconfig/Button14.button_pressed: GL.settings.rscale -= 1
		if $touchconfig/Button15.button_pressed: GL.settings.rdist += 2
		if $touchconfig/Button16.button_pressed: GL.settings.rdist -= 2
		for i in $touchconfig.get_children():
			if i is Button: i.button_pressed = false
		GL.save()
	#$touchconfig/Label3.text = GL.settings.lposx
	if event.is_action_pressed("retry"): _on_Button2_pressed()


func _on_Button_pressed():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused
	$"../Control/VideoStreamPlayer".paused = visible


func _on_Button2_pressed():
	get_tree().paused = false
	GL.enter_level()
	#get_tree().reload_current_scene()
