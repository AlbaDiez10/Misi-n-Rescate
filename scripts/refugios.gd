extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	aplicar_mascaras(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func aplicar_mascaras(node):
	for child in node.get_children():
		if child is TextureButton and child.texture_normal:
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(child.texture_normal.get_image(), 0.5)
			child.texture_click_mask = bitmap
			aplicar_mascaras(child) # recursivo → revisa todo el árbol

# Enlace 1: El Campito Refugio
# Conecta tu botón (ej. $BotonCampito) a esta función
func _on_texture_button_pressed():
	OS.shell_open("https://elcampitorefugio.org/")


# Enlace 2: Huellitas Adopciones
# Conecta tu botón (ej. $BotonHuellitas) a esta función
func _on_texture_button_2_pressed():
	OS.shell_open("https://www.instagram.com/huellitas.adopciones/?hl=es")


# Enlace 3: Rescataditos La Plata
# Conecta tu botón (ej. $BotonRescataditos) a esta función
func _on_texture_button_3_pressed():
	OS.shell_open("https://www.instagram.com/rescataditoslaplata/?hl=es")


# Enlace 4: Rescatistas LP
# Conecta tu botón (ej. $BotonRescatistas) a esta función
func _on_texture_button_4_pressed():
	OS.shell_open("https://www.instagram.com/rescatistaslp/")
	



func _on_menu_princil_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu_niveles.tscn")


func _on_pichichos_al_rescate_pressed():
	OS.shell_open("https://www.facebook.com/pichichos.alrescate/?locale=es_LA")


func _on_el_campito_refugio_pressed():
	OS.shell_open("https://elcampitorefugio.org/")


func _on_huellitas_pressed():
	OS.shell_open("https://www.instagram.com/huellitas.adopciones/?hl=es")


func _on_rescatistas_la_plata_pressed():
	OS.shell_open("https://www.instagram.com/rescatistaslp/")


func _on_gapra_refugio_pressed():
	OS.shell_open("https://www.instagram.com/gapra.refugio/?hl=es")

