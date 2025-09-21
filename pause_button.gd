extends Button

func _on_pressed() -> void:
	get_tree().current_scene.settings_open = !get_tree().current_scene.settings_open
	get_tree().paused = get_tree().current_scene.settings_open
	if get_tree().current_scene.settings_open:
		$"../Settings".show()
		$"../Settings".start()
	else:
		$"../Settings".save()
		get_tree().current_scene.update_settings()
		GL.save()
		$"../Settings".hide()
