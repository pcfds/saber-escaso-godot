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

## Cada cuánto se mira si hay algo nuevo que dibujar, y cuánto se tiene que
## haber movido el jugador para que valga rehacer el mapa.
##
## El mapa se redibujaba en cada cuadro mientras estaba abierto: sesenta veces
## por segundo, quince círculos y cinco etiquetas que cambian cuando caminás.
## Un píxel del mapa son casi dos metros de valle, así que por debajo de medio
## metro de caminata el dibujo sale idéntico. Parado y con el mapa abierto,
## ahora no se redibuja nunca.
const CADA := 0.1
const SE_MOVIO := 0.5
## Y cuánto tiene que haber GIRADO. Sin esto, la cuña de dirección que se
## agregó abajo quedaba congelada apuntando a donde mirabas cuando llegaste:
## parado y girando, `distance_to` da cero y no se redibuja nunca. Ocho grados
## es cuando la punta de la cuña se corre un píxel a este tamaño.
const SE_GIRO := 0.14

var lugares: Dictionary = {}         ## slug → {pos, nombre}
## Tipado como `Jugador` y no como `Node3D` a propósito: la cuña de dirección
## necesita `mira_hacia()`, y con el tipo puesto un cambio de nombre de ese
## método rompe al compilar en vez de en pantalla.
var jugador: Jugador
## Las marcas de amenazas las reescribe el valle cada vez que contesta el
## servidor. El setter está para que asignarlas alcance para pedir el redibujo:
## así el que las escribe no tiene que acordarse de avisar.
var amenazas: Array = []: set = _poner_amenazas
## La gente del valle: [{pos, nombre}]. Lo pone `valle.gd` cada cuadro.
##
## Es lo que hacía que el mapa no sirviera para nada: mostraba lugares vacíos.
## Lo único que uno quiere saber mirando el mapa de este juego es dónde está la
## gente, porque la gente es el contenido.
var vecinos: Array = []

var _fuente: Font
var _reloj := 0.0
var _ultimo_yo := Vector3(1e9, 0, 0)
var _ultimo_giro := 1e9


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuente = ThemeDB.fallback_font
	# El tamaño se fija a mano y se sigue el redimensionado. `set_anchors_preset`
	# NO alcanza colgando de un CanvasLayer: el Control queda con tamaño cero,
	# y como todo se dibuja relativo a `size / 2`, el mapa entero se apilaba en
	# la esquina superior izquierda. Se veía como que la tecla no andaba.
	_medir()
	get_tree().root.size_changed.connect(_medir)


func _medir() -> void:
	size = get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	set_process(false)


func alternar() -> void:
	visible = not visible
	# Cerrado no cuesta nada: ni se procesa ni se dibuja.
	set_process(visible)
	if visible:
		_ultimo_yo = Vector3(1e9, 0, 0)
		_ultimo_giro = 1e9
		queue_redraw()


func _poner_amenazas(nuevas: Array) -> void:
	amenazas = nuevas
	if visible:
		queue_redraw()


func _process(dt: float) -> void:
	_reloj += dt
	if _reloj < CADA:
		return
	_reloj = 0.0
	if jugador == null or not is_instance_valid(jugador):
		return
	var yo := jugador.global_position
	var giro := jugador.mira_hacia()
	if yo.distance_to(_ultimo_yo) < SE_MOVIO \
			and absf(angle_difference(giro, _ultimo_giro)) < SE_GIRO:
		return
	_ultimo_yo = yo
	_ultimo_giro = giro
	queue_redraw()


## Del mundo a la pantalla. El norte del valle queda arriba.
func _a_pantalla(p: Vector3, centro: Vector2, radio: float) -> Vector2:
	return centro + Vector2(p.x, -p.z) / RADIO_MUNDO * radio


func _draw() -> void:
	var centro := size / 2.0
	var radio: float = minf(size.x, size.y) * 0.44

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

	# La gente. Es lo que hacía que el mapa no sirviera para nada: mostraba
	# lugares vacíos. Lo único que uno quiere saber mirando un mapa de este
	# juego es DÓNDE ESTÁ LA GENTE, porque la gente es el contenido.
	for g in vecinos:
		var d3: Dictionary = g
		var p3 := _a_pantalla(d3['pos'], centro, radio)
		var duerme: bool = bool(d3.get('duerme', false))
		draw_circle(p3, 4.5, Color(0.42, 0.52, 0.44) if duerme else Color(0.86, 0.82, 0.62))
		draw_string(_fuente, p3 + Vector2(8, 4), str(d3.get('nombre', '')),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(0.55, 0.60, 0.55) if duerme else Color(0.86, 0.82, 0.62))

	if jugador != null and is_instance_valid(jugador):
		var yo := _a_pantalla(jugador.global_position, centro, radio)

		# HACIA DÓNDE ESTÁS MIRANDO. Es lo que faltaba para que el mapa sirva
		# para caminar y no sólo para mirar.
		#
		# Un punto en un mapa te dice dónde estás; sin la dirección no te dice
		# hacia dónde arrancar, y hay que salir a probar y volver. En un valle
		# de 360 metros con cinco lugares eso es la diferencia entre orientarse
		# y adivinar — y era el reclamo: *"el mapa es tan chico y sin vida que
		# no sirve de nada"*. Mostraba dónde estaban las cosas y no cómo llegar.
		#
		# La dirección se le PREGUNTA al jugador (`frente()`) en vez de deducirla
		# de su transform, y eso es el arreglo de un bug que casi entra: **el
		# que gira no es el `CharacterBody3D` sino su malla**, así que
		# `global_rotation.y` da siempre lo mismo y la cuña habría quedado
		# clavada apuntando al norte. Encima este proyecto usa `+Z` como frente
		# y no el `−Z` de Godot, así que la cuenta "obvia" salía dada vuelta dos
		# veces. Un mapa que miente es peor que no tener mapa: se descubre
		# después de caminar cien metros.
		var f := jugador.frente()
		var dir := Vector2(f.x, -f.z)
		if dir.length_squared() > 0.0001:
			dir = dir.normalized()
			var lado := Vector2(-dir.y, dir.x)
			# Una cuña corta y ancha, no una flecha larga: a este tamaño una
			# flecha se lee como un palito y no se distingue su punta.
			draw_colored_polygon(PackedVector2Array([
				yo + dir * 20.0,
				yo + lado * 7.0,
				yo - lado * 7.0,
			]), Color(0.35, 0.82, 0.70, 0.45))

		draw_circle(yo, 7.0, Color(0.35, 0.82, 0.70))
		draw_arc(yo, 12.0, 0, TAU, 24, Color(0.35, 0.82, 0.70, 0.55), 1.5, true)
		draw_string(_fuente, yo + Vector2(-8, -17), "tú",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.90, 0.78))

	draw_string(_fuente, Vector2(centro.x - 60, size.y - 40), "[M] cerrar el mapa",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.60, 0.57))
