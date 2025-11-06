extends Control

@onready var fondo1 = $Fondo
@onready var fondo2 = $Fondo_text
@onready var rescatedana = $Rescate_dana
@onready var rescatedana2 = $Rescate_dana2
@onready var label = $Label
@onready var label2 = $Label2
@onready var boton = $BotonContinuar   # Asegurate que tu botón se llame así

# Texto principal
var texto_completo = "Hace algunos años, en un pequeño pueblo, muchas mascotas corrían peligro por personas que no entendían el valor de la vida animal."
var paso = 1

func _ready():
	# Configuración inicial
	fondo2.modulate.a = 0.0
	rescatedana.modulate.a = 0.0
	rescatedana2.modulate.a = 0.0
	label.text = ""
	label2.text = ""
	label.visible = false
	label2.visible = false


# 🔹 PRIMERA TRANSICIÓN: fondo1 → fondo2 + texto1
func transicion_fondo():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# transición entre fondos
	tween.tween_property(fondo2, "modulate:a", 1.0, 3.0)
	tween.tween_property(fondo1, "modulate:a", 0.0, 3.0)
	paso = 5
	await tween.finished

	# Mostrar el texto luego del cambio
	label.visible = true
	await mostrar_texto_progresivo(label, texto_completo)

	paso = 2


# 🔹 SEGUNDA TRANSICIÓN: fondo2 → rescate_dana
func transicion_fondo2():
	label.visible = false

	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rescatedana, "modulate:a", 1.0, 3.0)
	tween.tween_property(fondo2, "modulate:a", 0.0, 3.0)
	paso = 5
	# 🔸 ocultar el botón después de la segunda transición
	boton.visible = false
	await tween.finished


	paso = 3

	# 🔸 iniciar secuencia automática (sin botón)
	await get_tree().create_timer(3.0).timeout  # espera unos segundos
	await transicion_fondo3()


# 🔹 TERCERA TRANSICIÓN: rescate_dana → rescate_dana2 + texto2
func transicion_fondo3():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rescatedana2, "modulate:a", 1.0, 4.0)
	tween.tween_property(rescatedana, "modulate:a", 0.0, 4.0)
	await tween.finished

	label2.visible = true
	await mostrar_texto_progresivo(label2, "Dana, una perrita curiosa y juguetona, encontró comida en la calle... pero estaba envenenada.\nSe sintió muy mal, perdió fuerzas y necesitó ayuda urgente.\nTu misión comienza aquí: aprender a cuidar, salvar animales y darles una segunda oportunidad.")

	paso = 4  # final de la secuencia


# 🔹 Efecto de texto tipo máquina de escribir
func mostrar_texto_progresivo(etiqueta: Label, texto: String) -> void:
	etiqueta.text = ""
	for i in range(texto.length()):
		etiqueta.text = texto.substr(0, i + 1)
		await get_tree().create_timer(0.05).timeout


# 🔹 Botón que avanza solo las dos primeras fases
func _on_button_pressed():
	print("✅ BOTÓN PRESIONADO, paso =", paso)
	match paso:
		1: transicion_fondo()
		2: transicion_fondo2()


func _on_texture_button_2_pressed():
	get_tree().change_scene_to_file("res://scenes/Refugio.tscn")
