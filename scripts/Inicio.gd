extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	for boton in get_children():
		if boton is TextureButton and boton.texture_normal:
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(boton.texture_normal.get_image(), 0.5)
			boton.texture_click_mask = bitmap





func _on_texture_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu_niveles.tscn")
