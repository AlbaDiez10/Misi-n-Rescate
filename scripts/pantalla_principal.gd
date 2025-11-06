extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var nivel1 = $Nivel_1
	Global.cargar_datos()
	if Global.nivel1 == "desactivado":
		nivel1.disabled = true
	for boton in get_children():
		if boton is TextureButton and boton.texture_normal:
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(boton.texture_normal.get_image(), 0.5)
			boton.texture_click_mask = bitmap

func _on_texture_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Refugio.tscn")

func _on_texture_button_2_pressed():
	get_tree().change_scene_to_file("res://scenes/refugios.tscn")


func _on_texture_button_3_pressed():
	get_tree().change_scene_to_file("res://scenes/clinica.tscn")


func _on_texture_button_4_pressed():
	get_tree().change_scene_to_file("res://scenes/configuracion.tscn")


func _on_nivel_1_pressed():
	get_tree().change_scene_to_file("res://scenes/nivel_1.tscn")


func _on_nivel_2_pressed():
	get_tree().change_scene_to_file("res://scenes/nivel_2.tscn")


func _on_nivel_3_pressed():
	get_tree().change_scene_to_file("res://scenes/nivel_3.tscn")
