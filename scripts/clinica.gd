extends Control

# NODOS
@onready var dana_clinica = $Dana_clinica # TextureButton/TextureRect de Dana en la clínica
@onready var boton_suero = $Boton_suero
@onready var boton_antidoto = $Boton_antidoto
@onready var boton_salud_clinica = $Boton_salud_clinica # Botón permanente (ej. "Dar Atención Médica")
@onready var boton_menu_principal = $Boton_Menu_princiál # Asegúrate de que este nodo exista

# Duraciones de animaciones (en segundos)
const TIEMPO_SUERO := 2.5 # Puedes ajustar este valor
const TIEMPO_ANTIDOTO := 3.0 # Puedes ajustar este valor

# Valor de curación (50% de la barra de 100.0)
const CURACION_50_PCT := 50.0

# Para la lógica de cambio de imagen aleatoria si Dana está bien
var rng := RandomNumberGenerator.new()

# ------------------------------------------------------------
# 🔹 READY
# ------------------------------------------------------------
func _ready():
	# Aplica las máscaras de clic a los botones
	for boton in get_children():
		if boton is TextureButton and boton.texture_normal:
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(boton.texture_normal.get_image(), 0.5)
			boton.texture_click_mask = bitmap

	_inicializar_visibilidad()
	# Asegúrate de que Dana se vea correctamente al entrar
	actualizar_imagen_dana_clinica()

# ------------------------------------------------------------
# 🔹 LÓGICA DE VISIBILIDAD CONDICIONAL
# ------------------------------------------------------------
func _inicializar_visibilidad():
	var dana_rescatada = Global.stats_animales.has("Dana")

	# Ocultamos todo por defecto
	dana_clinica.visible = dana_rescatada
	boton_suero.visible = false
	boton_antidoto.visible = false
	boton_salud_clinica.visible = false

	if not dana_rescatada:
		return

	# Lógica de "Una sola vez"
	if not Global.clinica_flags["dana_atendida_primera_vez"]:
		var suero_pendiente = not Global.clinica_flags["suero_aplicado"]
		var antidoto_pendiente = not Global.clinica_flags["antidoto_aplicado"]

		boton_suero.visible = suero_pendiente
		boton_antidoto.visible = antidoto_pendiente

		if not suero_pendiente and not antidoto_pendiente:
			Global.clinica_flags["dana_atendida_primera_vez"] = true
			Global.guardar_datos()
			boton_salud_clinica.visible = true
	else:
		boton_salud_clinica.visible = true

	actualizar_imagen_dana_clinica()

# ------------------------------------------------------------
# 💊 BOTONES DE TRATAMIENTO (UNA SOLA VEZ)
# ------------------------------------------------------------
func _on_boton_suero_pressed():
	if not Global.clinica_flags["suero_aplicado"]:
		_bloquear_botones_clinica(true)
		Global.modify_stat("Dana", "salud", CURACION_50_PCT)

		actualizar_imagen_dana_clinica("suero")
		await get_tree().create_timer(TIEMPO_SUERO).timeout

		Global.clinica_flags["suero_aplicado"] = true
		Global.guardar_datos()

		_inicializar_visibilidad()
		_bloquear_botones_clinica(false)

func _on_boton_antidoto_pressed():
	if not Global.clinica_flags["antidoto_aplicado"]:
		_bloquear_botones_clinica(true)
		Global.modify_stat("Dana", "salud", CURACION_50_PCT)

		actualizar_imagen_dana_clinica("antidoto")
		await get_tree().create_timer(TIEMPO_ANTIDOTO).timeout

		Global.clinica_flags["antidoto_aplicado"] = true
		Global.guardar_datos()

		_inicializar_visibilidad()
		_bloquear_botones_clinica(false)

# ------------------------------------------------------------
# ❤️ BOTÓN DE SALUD PERMANENTE
# ------------------------------------------------------------
func _on_boton_salud_clinica_pressed():
	Global.modify_stat("Dana", "salud", CURACION_50_PCT)
	actualizar_imagen_dana_clinica()

# ------------------------------------------------------------
# 📸 SISTEMA DE IMÁGENES DE DANA EN CLÍNICA
# ------------------------------------------------------------
func actualizar_imagen_dana_clinica(estado_forzado: String = ""):
	if not Global.stats_animales.has("Dana"):
		dana_clinica.visible = false
		return

	var dana_textura: Texture
	var ruta_base = "res://assets/sprites/Dana/"

	# Acciones forzadas
	if estado_forzado != "":
		match estado_forzado:
			"suero":
				dana_textura = load(ruta_base + "Dana_Suero.png")
			"antidoto":
				dana_textura = load(ruta_base + "Dana_Antidoto.png")
		_aplicar_textura_a_dana_clinica(dana_textura)
		return

	# Estados automáticos
	var stats = Global.stats_animales["Dana"]
	var comida = stats.get("comida", 100.0)
	var banarse = stats.get("banarse", 100.0)
	var salud = stats.get("salud", 100.0)

	if salud < 40:
		dana_textura = load(ruta_base + "Dana_Enfermo.png")
	elif banarse < 40 and comida < 40:
		dana_textura = load(ruta_base + "Diana_sucio.png")
	elif comida < 40:
		dana_textura = load(ruta_base + "Dana_Tiste.png")
	elif banarse < 40:
		dana_textura = load(ruta_base + "Dana_agua.png")
	else:
		var opciones = ["Dana_sentada.png", "Dana_zzz .png"]
		rng.randomize()
		var random_idx = rng.randi_range(0, opciones.size() - 1)
		dana_textura = load(ruta_base + opciones[random_idx])

	_aplicar_textura_a_dana_clinica(dana_textura)

# ------------------------------------------------------------
# 🖼️ APLICAR TEXTURA
# ------------------------------------------------------------
func _aplicar_textura_a_dana_clinica(textura: Texture):
	if dana_clinica:
		if dana_clinica is TextureButton:
			dana_clinica.texture_normal = textura
			dana_clinica.texture_pressed = null
			dana_clinica.texture_hover = null
		elif dana_clinica is TextureRect:
			dana_clinica.texture = textura
		dana_clinica.visible = true

# ------------------------------------------------------------
# 🚫 BLOQUEAR BOTONES
# ------------------------------------------------------------
func _bloquear_botones_clinica(estado: bool) -> void:
	if boton_suero and boton_suero.visible:
		boton_suero.disabled = estado
	if boton_antidoto and boton_antidoto.visible:
		boton_antidoto.disabled = estado
	if boton_salud_clinica and boton_salud_clinica.visible:
		boton_salud_clinica.disabled = estado
	if boton_menu_principal:
		boton_menu_principal.disabled = estado

# ------------------------------------------------------------
# ⏱️ COOLDOWN (opcional)
# ------------------------------------------------------------
func _esta_en_cooldown() -> bool:
	var ahora = Time.get_unix_time_from_system()
	var tiempo_restante = Global.COOLDOWN_SALUD_SECS - (ahora - Global.ultimo_uso_salud)
	return tiempo_restante > 0

# ------------------------------------------------------------
# 🚪 NAVEGACIÓN
# ------------------------------------------------------------
func _on_menu_princil_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu_niveles.tscn")
