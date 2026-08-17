## El mapa del valle. Se abre con M.
##
## Hizo falta apenas el valle se agrandó: con todo a veinte metros no lo
## necesitabas, y con distancias reales te perdés. Dibuja los lugares, dónde
## estás, y dónde anda lo que te puede matar.
##
## Se dibuja con _draw() y no con nodos: son quince círculos y cinco etiquetas,
## y armar una escena para eso es más código y más cosas que se pueden romper.
class_name Mapa
extends Control

const RADIO_MUNDO := 190.0

var lugares: Dictionary = {}         ## slug → {pos, nombre}
var jugador: Node3D
var amenazas: Array = []             ## [{pos: Vector3, nombre: String}]

var _fuente: Font


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_fuente = ThemeDB.fallback_font


func alternar() -> void:
	visible = not visible
	if visible:
		queue_redraw()


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


## Del mundo a la pantalla. El norte del valle queda arriba.
func _a_pantalla(p: Vector3, centro: Vector2, radio: float) -> Vector2:
	return centro + Vector2(p.x, -p.z) / RADIO_MUNDO * radio


func _draw() -> void:
	var centro := size / 2.0
	var radio: float = minf(size.x, size.y) * 0.40

	# El fondo del mapa. Oscuro y translúcido: seguís viendo que hay un juego
	# atrás, y no se siente que saliste a un menú.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.07, 0.86))
	draw_circle(centro, radio + 26.0, Color(0.10, 0.13, 0.12, 0.95))
	draw_arc(centro, radio + 26.0, 0, TAU, 96, Color(0.35, 0.42, 0.38, 0.7), 1.5, true)

	# La abertura al norte: es por donde crece el mundo, tiene que verse.
	draw_arc(centro, radio + 26.0, -PI / 2.0 - 0.30, -PI / 2.0 + 0.30, 24,
		Color(0.85, 0.62, 0.30, 0.95), 4.0, true)
	draw_string(_fuente, centro + Vector2(-30, -radio - 38), "al norte",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.80, 0.66, 0.40))

	for slug: String in lugares:
		var d: Dictionary = lugares[slug]
		var p := _a_pantalla(d['pos'], centro, radio)
		draw_circle(p, 6.0, Color(0.62, 0.68, 0.58))
		draw_string(_fuente, p + Vector2(11, 5), str(d.get('nombre', slug)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.86, 0.89, 0.84))

	for a in amenazas:
		var d2: Dictionary = a
		var p2 := _a_pantalla(d2['pos'], centro, radio)
		draw_circle(p2, 5.0, Color(0.86, 0.35, 0.18))
		draw_string(_fuente, p2 + Vector2(9, 4), str(d2.get('nombre', '')),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.90, 0.55, 0.38))

	if jugador != null and is_instance_valid(jugador):
		var yo := _a_pantalla(jugador.global_position, centro, radio)
		draw_circle(yo, 7.0, Color(0.35, 0.82, 0.70))
		draw_arc(yo, 12.0, 0, TAU, 24, Color(0.35, 0.82, 0.70, 0.55), 1.5, true)
		draw_string(_fuente, yo + Vector2(-8, -17), "vos",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.90, 0.78))

	draw_string(_fuente, Vector2(centro.x - 60, size.y - 40), "[M] cerrar el mapa",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.60, 0.57))
