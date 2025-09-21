extends Node2D

func _process(delta):
	if OS.get_name() != "Android": return
	$left.position = Vector2(GL.settings.lposx,GL.settings.lposy)
	$right.position = Vector2(GL.settings.rposx,GL.settings.rposy)
	$left/TouchScreenButton5.shape.radius = GL.settings.lscale
	$left/TouchScreenButton8.shape.radius = GL.settings.lscale
	$right/TouchScreenButton9.shape.radius = GL.settings.rscale
	$right/TouchScreenButton10.shape.radius = GL.settings.rscale
	$right/TouchScreenButton11.shape.radius = GL.settings.rscale
	$right/TouchScreenButton12.shape.radius = GL.settings.rscale
	$left/TouchScreenButton5.position = Vector2(0,-GL.settings.ldist)
	$left/TouchScreenButton6.position = Vector2(-GL.settings.ldist,0)
	$left/TouchScreenButton7.position = Vector2(GL.settings.ldist,0)
	$left/TouchScreenButton8.position = Vector2(0,GL.settings.ldist)
	$right/TouchScreenButton9.position = Vector2(0,-GL.settings.rdist)
	$right/TouchScreenButton10.position = Vector2(-GL.settings.rdist,0)
	$right/TouchScreenButton11.position = Vector2(GL.settings.rdist,0)
	$right/TouchScreenButton12.position = Vector2(0,GL.settings.rdist)
	
