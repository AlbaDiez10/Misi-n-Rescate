extends Node

var nivel1: String = "activado"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.


# 📁 Ruta del archivo de guardado
const SAVE_PATH = "user://savegame.json"

# 🔹 Guardar el valor actual
func guardar_datos():
	var data = {"nivel1": nivel1}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("💾 Guardado:", data)

# 🔹 Cargar el valor guardado
func cargar_datos():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var contenido = file.get_as_text()
		file.close()
		var data = JSON.parse_string(contenido)
		if typeof(data) == TYPE_DICTIONARY:
			nivel1 = data.get("nivel1", "desactivado")
			print("✅ Cargado:", data)
		else:
			print("⚠️ Error al leer JSON.")
	else:
		print("⚠️ No hay archivo guardado todavía.")

