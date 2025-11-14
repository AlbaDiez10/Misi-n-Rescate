extends Control
# Refugio.gd - UI + máscaras + botones. No reduce stats; usa Global.modify_stat()

# NODOS
@onready var panel_menu = $Menu
@onready var boton_dana = $Dana
@onready var dana_sprite_menu = $Menu/Dana2
@onready var historia = $Historia
@onready var boton_menu = $"Menu_princiál"

# BARRAS
@onready var barra_comida = $"Menu/BarraComida"
@onready var barra_banarse = $"Menu/BarraBanarse"
@onready var barra_salud = $"Menu/BarraSalud"

# Duraciones de animaciones (en segundos)
const TIEMPO_COMER := 2.5
const TIEMPO_BANARSE := 3.0

# Referencias a botones de acción
@onready var boton_comida = $"Menu/Boton_Comida"
@onready var boton_banarse = $"Menu/Boton_Bañarse"
@onready var sonido_comer = $"Menu/SonidoComer"
@onready var sonido_banarse = $Menu/SonidoBanarse

var animals : Dictionary = {}

func _ready():
	Global.cargar_datos()
	print("🔎 Global.nivel1 =", Global.nivel1)
	Global._load() if Engine.is_editor_hint() else null
	_aplicar_click_masks(self)

	# registrar mapping local (solo referencias UI)
	register_animal(
		"Dana",
		{
			"comida": barra_comida,
			"banarse": barra_banarse,
			"salud": barra_salud
		},
		{
			"comida": Global.max_values.get("comida", 100.0),
			"banarse": Global.max_values.get("banarse", 100.0),
			"salud": Global.max_values.get("salud", 100.0)
		},
		{
			"comida": Global.rates.get("comida", 0.1),
			"banarse": Global.rates.get("banarse", 0.1),
			"salud": 0.0
		}
	)

	# Aplicar valores guardados en Global a las barras
	_actualizar_ui_desde_global()

	# refresco visual (no modifica stats)
	var refresco = Timer.new()
	refresco.wait_time = 1.0
	refresco.one_shot = false
	refresco.autostart = true
	refresco.timeout.connect(_actualizar_ui_desde_global)
	add_child(refresco)
	
	# --- NUEVO TIMER PARA EL ESTADO DE DANA (ej. 3.0s) ---
	var timer_dana_mood = Timer.new()
	timer_dana_mood.wait_time = 25.0
	timer_dana_mood.one_shot = false
	timer_dana_mood.autostart = true
	# Conectamos directamente a la función que cambia la imagen
	timer_dana_mood.timeout.connect(actualizar_imagen_dana) 
	add_child(timer_dana_mood)
	
	actualizar_imagen_dana()


# Click masks recursivo
func _aplicar_click_masks(nodo: Node) -> void:
	for child in nodo.get_children():
		if child is TextureButton and child.texture_normal:
			var bmp := BitMap.new()
			bmp.create_from_image_alpha(child.texture_normal.get_image(), 0.5)
			child.texture_click_mask = bmp
		if child.get_child_count() > 0:
			_aplicar_click_masks(child)

# Sincroniza UI desde Global (no altera valores)
func _actualizar_ui_desde_global():
	if not Global.stats_animales.has("Dana"):
		return
	var s = Global.stats_animales["Dana"]
	actualizar_barra_visual(barra_comida, float(s.get("comida", 0.0)), Global.max_values.get("comida", 100.0))
	actualizar_barra_visual(barra_banarse, float(s.get("banarse", 0.0)), Global.max_values.get("banarse", 100.0))
	actualizar_barra_visual(barra_salud, float(s.get("salud", 0.0)), Global.max_values.get("salud", 100.0))


func _bloquear_botones(estado: bool) -> void:
	if boton_comida:
		boton_comida.disabled = estado
	if boton_banarse:
		boton_banarse.disabled = estado

# Visual style
func actualizar_barra_visual(bar: ProgressBar, current: float, max_value: float) -> void:
	if bar == null or max_value <= 0:
		return
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = clamp(current, 0.0, max_value)
	var pct = bar.value / max_value
	var color = Color.GREEN
	if pct < 0.5:
		color = Color.YELLOW
	if pct < 0.25:
		color = Color.RED
	var sb = bar.get_theme_stylebox("fill")
	if sb and sb is StyleBoxFlat:
		var dup = sb.duplicate() as StyleBoxFlat
		dup.bg_color = color
		bar.add_theme_stylebox_override("fill", dup)

# Registro local (solo para referencias UI)
func register_animal(id: String, bars: Dictionary, max_values: Dictionary, rates: Dictionary) -> void:
	animals[id] = {
		"bars": bars.duplicate(true),
		"max": max_values.duplicate(true),
		"rates": rates.duplicate(true),
		"current": {} # no usado para lógica centralizada
	}

# BOTONES: usan Global.modify_stat()
func _on_comida_pressed():
	Global.modify_stat("Dana", "comida", 25.0)
	_actualizar_ui_desde_global()
	_bloquear_botones(true)
	actualizar_imagen_dana("comiendo")

	# 🔊 Lugar reservado para sonido de comer
	sonido_comer.play()

	await get_tree().create_timer(TIEMPO_COMER).timeout
	_bloquear_botones(false)
	actualizar_imagen_dana()  # vuelve a estado normal

func _on_agua_pressed():
	Global.modify_stat("Dana", "banarse", 30.0)
	_actualizar_ui_desde_global()
	_bloquear_botones(true)
	actualizar_imagen_dana("banandose")

	# 🔊 Lugar para sonido de baño
	sonido_banarse.play()
	await get_tree().create_timer(TIEMPO_COMER).timeout # Espera 2.5 segundos
	_bloquear_botones(false)
	actualizar_imagen_dana()

func _on_jugar_pressed():
	# opcional: mejorar salud si quieres
	Global.modify_stat("Dana", "salud", 10.0)
	_actualizar_ui_desde_global()

# Menú / UI
func _on_texture_button_pressed():
	if historia:
		historia.visible = true

func _on_cerrar_pressed():
	if panel_menu:
		panel_menu.visible = false
	if boton_dana:
		boton_menu.visible = true
		boton_dana.visible = true

func _on_cerrar_historiadana_pressed():
	if historia:
		historia.visible = false

func _on_dana_pressed():
	if panel_menu:
		panel_menu.visible = true
		boton_menu.visible = false
	if boton_dana:
		boton_dana.visible = false

func _on_menu_princil_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu_niveles.tscn")

# -------------------------
# SISTEMA DE IMÁGENES DE DANA
# -------------------------

var rng := RandomNumberGenerator.new()

func actualizar_imagen_dana(estado_forzado: String = ""):
	var dana_textura: Texture
	var ruta_base = "res://assets/sprites/Dana/"

	# --- 1. Animaciones Forzadas (Comiendo, Bañandose) ---
	if estado_forzado != "":
		match estado_forzado:
			"comiendo":
				dana_textura = load(ruta_base + "Dana_comiendo.png")
			"banandose":
				dana_textura = load(ruta_base + "dana_bañada.png")
		
		# APLICAR TEXTURA CON CORRECCIÓN
		if boton_dana:
			# Si es un TextureButton (como lo es $Dana), usa texture_normal
			if boton_dana is TextureButton:
				boton_dana.texture_normal = dana_textura
			else: # Si no lo es (por si acaso), usa .texture
				boton_dana.texture = dana_textura
				
		if dana_sprite_menu:
			# Asumiendo que dana_sprite_menu ($Menu/Dana2) es un TextureRect o similar
			# Si no es un TextureButton, simplemente asigna .texture
			if dana_sprite_menu is TextureButton:
				dana_sprite_menu.texture_normal = dana_textura
			else:
				dana_sprite_menu.texture = dana_textura
		return

	# --- 2. Estados Normales Automáticos ---
	if not Global.stats_animales.has("Dana"):
		return

	var stats = Global.stats_animales["Dana"]
	var comida = stats.get("comida", 100.0)
	var banarse = stats.get("banarse", 100.0)
	var salud = stats.get("salud", 100.0)

	# 🔸 Prioridad de estados: Enfermo > Sucio > Triste > Feliz/Descanso
	if salud < 40:
		dana_textura = load(ruta_base + "Dana_Enfermo.png")
	elif banarse < 40 and comida < 40:
		dana_textura = load(ruta_base + "Diana_sucio.png")
	elif comida < 40:
		dana_textura = load(ruta_base + "Dana_Tiste.png")
	elif banarse < 40:
		dana_textura = load(ruta_base + "Dana_agua.png")
	else:
		# Alternar aleatoriamente entre estados normales (Sentada, Feliz, Zzz)
		var opciones = [
			"Dana_sentada.png",
			"Dana_zzz .png"
		]
		rng.randomize() # Asegura la aleatoriedad, aunque ya lo haces en _ready
		var random_idx = rng.randi_range(0, opciones.size() - 1)
		dana_textura = load(ruta_base + opciones[random_idx])

	# APLICAR TEXTURA CON CORRECCIÓN
	if boton_dana:
		if boton_dana is TextureButton:
			boton_dana.texture_normal = dana_textura
		else:
			boton_dana.texture = dana_textura
			
	if dana_sprite_menu:
		if dana_sprite_menu is TextureButton:
			dana_sprite_menu.texture_normal = dana_textura
		else:
			dana_sprite_menu.texture = dana_textura



func _cambiar_textura_dana(ruta: String):
	var tex = load(ruta)
	if tex:
		if boton_dana:
			boton_dana.texture_normal = tex
		if has_node("Menu/Dana2"):
			$"Menu/Dana2".texture_normal = tex

