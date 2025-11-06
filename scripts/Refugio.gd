extends Control
# Script para manejar barras (comida, higiene, diversión) y un Timer central.
# Reutilizable para varios "animales" (cada animal tiene su propio set de barras).

@onready var panel_menu = $Menu
@onready var boton_dana = $Dana
@onready var historia = $Historia

# Timer central (si no existe en escena se crea en _ready)
var stat_timer : Timer = null

# Estructura para animales:
var animals : Dictionary = {}

func _ready():
	Global.cargar_datos()
	if Global.nivel1 == "desactivado":
		boton_dana.visible = true
	# Recorre todos los nodos dentro de este Control (incluyendo subnodos)
	_aplicar_click_masks(self)

func _aplicar_click_masks(nodo: Node):
	for child in nodo.get_children():
		if child is TextureButton and child.texture_normal:
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(child.texture_normal.get_image(), 0.5)
			child.texture_click_mask = bitmap
		# 🔁 Si el hijo tiene más nodos dentro, seguir recorriendo
		if child.get_child_count() > 0:
			_aplicar_click_masks(child)

	Global.cargar_datos()
	print("Nivel actual:", Global.nivel1)
	# Buscá un Timer llamado "StatTimer", si no existe lo creamos
	if has_node("StatTimer"):
		stat_timer = $StatTimer
	else:
		stat_timer = Timer.new()
		stat_timer.name = "StatTimer"
		add_child(stat_timer)
	# Conectar señal timeout al método que actualiza stats
	if not stat_timer.is_connected("timeout", Callable(self, "_on_stat_timer_timeout")):
		stat_timer.timeout.connect(_on_stat_timer_timeout)

	# EJEMPLO: registrar al animal "Dana" (cambia rutas si tus nodos están en otra parte)
	register_animal(
		"Dana",
		{
			"comida": $"Menu/BarraComida",
			"higiene": $"Menu/BarraHigiene",
			"diversion": $"Menu/BarraDiversion"
		},
		{ "comida": 100.0, "higiene": 100.0, "diversion": 100.0 },
		{ "comida": 1.0, "higiene": 0.2, "diversion": 0.5 }
	)

	# Ejemplo: para arrancar el timer desde código:
	set_stat_timer_interval(1.0)
	start_stat_timer()
	pass


# -------------------------
# Funciones para el menú
# -------------------------
func _on_texture_button_pressed():
	historia.visible = true

func _on_cerrar_pressed():
	if panel_menu:
		panel_menu.visible = false
	if boton_dana:
		boton_dana.visible = true


# -------------------------
# Registro / gestión animales
# -------------------------
# bars: Dictionary de stat->Node (p. ej. "comida": $Menu/BarraComida)
# max_values: Dictionary stat->float
# rates: Dictionary stat->float (unidades por segundo)
func register_animal(id: String, bars: Dictionary, max_values: Dictionary, rates: Dictionary) -> void:
	if animals.has(id):
		push_warning("Animal ya registrado: %s" % id)
		return
	var current := {}
	for stat_name in max_values.keys():
		current[stat_name] = float(max_values[stat_name])
	# convertir rutas de nodos a referencias si es necesario
	for stat_name in bars.keys():
		var n = bars[stat_name]
		if typeof(n) == TYPE_STRING:
			if has_node(n):
				bars[stat_name] = get_node(n)
			else:
				push_warning("Ruta de barra no encontrada: %s" % n)
				bars[stat_name] = null
	# Guardar
	animals[id] = {
		"bars": bars.duplicate(true),
		"current": current,
		"max": max_values.duplicate(true),
		"rates": rates.duplicate(true)
	}
	# Inicializar visualmente las barras
	for stat_name in bars.keys():
		actualizar_barra_visual(bars[stat_name], current.get(stat_name, 0.0), max_values.get(stat_name, 0.0))


# -------------------------
# Timer control (configurable por vos)
# -------------------------
func set_stat_timer_interval(seconds: float) -> void:
	if not stat_timer:
		return
	stat_timer.wait_time = seconds

func start_stat_timer() -> void:
	if not stat_timer:
		return
	stat_timer.one_shot = false
	stat_timer.autostart = true
	stat_timer.start()

func stop_stat_timer() -> void:
	if not stat_timer:
		return
	stat_timer.stop()


# -------------------------
# Lógica que corre en cada tick del Timer
# -------------------------
func _on_stat_timer_timeout() -> void:
	if animals.is_empty():
		return
	var dt = stat_timer.wait_time
	for id in animals.keys():
		var data = animals[id]
		for stat_name in data.rates.keys():
			var rate = float(data.rates[stat_name])
			var cur = float(data.current.get(stat_name, 0.0))
			var mx = float(data.max.get(stat_name, 0.0))
			# reducir
			cur -= rate * dt
			if cur < 0.0:
				cur = 0.0
			data.current[stat_name] = cur
			# actualizar visualmente
			var bar_node = data.bars.get(stat_name, null)
			actualizar_barra_visual(bar_node, cur, mx)


# -------------------------
# Actualización visual de una barra (valor + color)
# -------------------------
func actualizar_barra_visual(bar: ProgressBar, current: float, max_value: float) -> void:
	if bar == null:
		return

	if max_value <= 0:
		return

	# actualizar valores
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = clamp(current, 0.0, max_value)

	# calcular porcentaje y color para ESTA barra
	var porcentaje = 0.0
	if max_value > 0:
		porcentaje = bar.value / max_value

	var color: Color = Color.GREEN
	if porcentaje < 0.5:
		color = Color.YELLOW
	if porcentaje < 0.25:
		color = Color.RED

	# obtener el StyleBox original (puede ser compartido)
	var stylebox: StyleBox = bar.get_theme_stylebox("fill")
	if not stylebox or not (stylebox is StyleBoxFlat):
		return

	# Intentamos reutilizar un override ya creado (guardado en meta)
	var override: StyleBoxFlat = null
	if bar.has_meta("fill_style_override"):
		override = bar.get_meta("fill_style_override")
		if override and (override is StyleBoxFlat):
			override.bg_color = color
			bar.add_theme_stylebox_override("fill", override)
			return

	# Si no existe override, duplicamos el stylebox original y lo aplicamos
	var newbox: StyleBoxFlat = stylebox.duplicate() as StyleBoxFlat
	if newbox:
		newbox.bg_color = color
		bar.add_theme_stylebox_override("fill", newbox)
		bar.set_meta("fill_style_override", newbox)




func _on_texture_button_4_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu_niveles.tscn")


func _on_cerrar_historiadana_pressed():
	historia.visible = false


func _on_dana_pressed():
	if panel_menu:
		panel_menu.visible = true
	if boton_dana:
		boton_dana.visible = false
