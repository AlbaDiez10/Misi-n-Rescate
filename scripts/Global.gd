extends Node

# 🐾 DATOS GLOBALES
var nivel1: String = "activado"

# Diccionario con estadísticas de animales
var stats_animales: Dictionary = {}

# Tasas de reducción (por segundo)
var rates: Dictionary = {
	"comida": 0.0023148,
	"banarse": 0.0011574,
	"salud": 0.0 # la salud no baja sola, depende de las otras
}

# Valores máximos
var max_values: Dictionary = {
	"comida": 100.0,
	"banarse": 100.0,
	"salud": 100.0
}

# Último guardado (timestamp UNIX)
var ultima_actualizacion: int = 0

# Timer global que sigue activo entre escenas
var stat_timer: Timer

# Controla cada cuántos segundos guardar
var tiempo_acumulado := 0.0

var clinica_flags: Dictionary = {
	"dana_atendida_primera_vez": false, # Controla la secuencia de Suero/Antídoto
	"suero_aplicado": false,
	"antidoto_aplicado": false,
}

# Tiempo en segundos (3600s = 1 hora) para el cooldown del botón de salud
const COOLDOWN_SALUD_SECS := 3600 
# Guarda el tiempo Unix (segundos) del último uso
var ultimo_uso_salud: int = 0

# 📁 Archivo de guardado
const SAVE_PATH = "user://savegame.json"

# ==================================
# 🔹 Inicialización (en Global.gd)
# ==================================
func _ready():
	cargar_datos()
	_inicializar_animales() 
	_simular_tiempo_pasado()
	_iniciar_timer_global()
	#resetear_clinica_para_prueba()
	print("🌍 Global cargado y corriendo.")

# ------------------------------
# 🔹 Inicializa los animales (si no existen)
func _inicializar_animales():
	if not stats_animales.has("Dana") and nivel1 == "desactivado":
		stats_animales["Dana"] = {
			"comida": 50.0,  # 50%
			"banarse": 70.0, # 70%
			"salud": 10.0    # 10%
		}

# ------------------------------
# 🔹 Timer global
# ------------------------------
func _iniciar_timer_global():
	if stat_timer and is_instance_valid(stat_timer):
		return
	stat_timer = Timer.new()
	stat_timer.name = "GlobalStatTimer"
	stat_timer.wait_time = 1.0
	stat_timer.one_shot = false
	stat_timer.autostart = true
	add_child(stat_timer)
	stat_timer.timeout.connect(_on_stat_timer_timeout)
	stat_timer.start()


# ------------------------------
# 🔹 Lógica de reducción automática y salud dependiente
# ------------------------------
func _on_stat_timer_timeout():
	tiempo_acumulado += stat_timer.wait_time

	for animal_id in stats_animales.keys():
		var s = stats_animales[animal_id]

		# Reducción natural de comida y baño
		s["comida"] = maxf(s["comida"] - rates.get("comida", 0.0), 0.0)
		s["banarse"] = maxf(s["banarse"] - rates.get("banarse", 0.0), 0.0)
		# -------------------------------------------------------
		# 2) 🔸 CÁLCULO DEL DÉFICIT TOTAL DE SALUD (SIMPLE)
		# -------------------------------------------------------
		var deficit = 0.0

		# A — Si comida baja, afecta salud
		if s["comida"] < 50.0:
			deficit += (50.0 - s["comida"]) * 0.03

		# B — Si baño bajo, también afecta salud
		if s["banarse"] < 50.0:
			deficit += (50.0 - s["banarse"]) * 0.02

		# C — Penalidad extra por emergencia (suero/antídoto no aplicados)
		if not clinica_flags.get("suero_aplicado", false) and not clinica_flags.get("antidoto_aplicado", false):
			deficit += 0.5  # penalidad fuerte

		# 3) Aplicar disminución de salud
		s["salud"] = clampf(s["salud"] - deficit, 0.0, max_values["salud"])

		stats_animales[animal_id] = s

	# Guardado periódico
	if tiempo_acumulado >= 10.0:
		guardar_datos()
		tiempo_acumulado = 0.0



# ------------------------------
# 🔹 Simula tiempo pasado desde el último guardado
# ------------------------------
func _simular_tiempo_pasado():
	if ultima_actualizacion == 0:
		return

	var ahora = Time.get_unix_time_from_system()
	var diferencia = ahora - ultima_actualizacion
	if diferencia <= 0:
		return

	print("⏳ Pasaron", diferencia, "segundos desde la última sesión.")

	for animal_id in stats_animales.keys():
		var s = stats_animales[animal_id]

		# Reducción natural
		s["comida"] = clampf(s["comida"] - rates.get("comida", 0.0) * diferencia, 0.0, max_values["comida"])
		s["banarse"] = clampf(s["banarse"] - rates.get("banarse", 0.0) * diferencia, 0.0, max_values["banarse"])

		# Reducción proporcional de salud
		var deficit = 0.0
		if s["comida"] < 50.0:
			deficit += (50.0 - s["comida"]) * 0.03
		if s["banarse"] < 50.0:
			deficit += (50.0 - s["banarse"]) * 0.02
		s["salud"] = clampf(s["salud"] - deficit * (float(diferencia) / 60.0), 0.0, max_values["salud"])

		stats_animales[animal_id] = s


# ------------------------------
# 💾 Guardar y cargar datos
# ------------------------------
func guardar_datos():
	var data = {
		"nivel1": nivel1,
		"stats_animales": stats_animales,
		"ultima_actualizacion": Time.get_unix_time_from_system(),
		"clinica_flags": clinica_flags
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	ultima_actualizacion = data["ultima_actualizacion"]
	print("💾 Datos guardados.")


func cargar_datos():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		return
	nivel1 = data.get("nivel1", "desactivado")
	stats_animales = data.get("stats_animales", {})
	ultima_actualizacion = data.get("ultima_actualizacion", 0)
	clinica_flags = data.get("clinica_flags", clinica_flags)


# ------------------------------
# 📴 Guardar automáticamente al cerrar o pausar la app
# ------------------------------
func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			print("📱 Aplicación cerrándose, guardando datos...")
			guardar_datos()
		NOTIFICATION_APPLICATION_PAUSED:
			print("📱 Aplicación pausada, guardando datos...")
			guardar_datos()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			print("📱 Aplicación perdió el foco, guardando datos...")
			guardar_datos()


# ------------------------------
# ⚙️ API pública para modificar stats (desde botones)
# ------------------------------
func modify_stat(animal_id: String, stat_name: String, delta: float):
	if not stats_animales.has(animal_id):
		push_warning("modify_stat: animal no existe: %s" % animal_id)
		return
	var cur = float(stats_animales[animal_id].get(stat_name, 0.0))
	var mx = float(max_values.get(stat_name, 100.0))
	cur = clampf(cur + delta, 0.0, mx)
	stats_animales[animal_id][stat_name] = cur
	guardar_datos()


# Global.gd


