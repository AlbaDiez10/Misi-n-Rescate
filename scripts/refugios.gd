extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


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
