## La magia, del lado del jugador.
##
## El sistema entero vive en el servidor (`../saber-escaso/lib/world/magia.ts`):
## cuatro runas, una gramática, cuarenta hechizos que se calculan y ninguno
## escrito a mano. Estaba construido, probado y desplegado, y **no había forma
## de trazar una runa desde el juego**. Este archivo es esa forma.
##
## Lo que NO hace, y es la mitad del trabajo:
##
##  · **No decide nada.** Ni el nombre del hechizo (lo arma el servidor y vuelve
##    en la respuesta), ni el daño, ni si la mezcla es nueva, ni cuántas runas
##    te quedan. Acá se dibuja y se manda. El invariante del cliente es que lo
##    que pasa acá llega al servidor o no pasó, y la magia es justo el sistema
##    donde más tentador sería hacer trampa: un fogonazo lindo sin POST es una
##    demo.
##  · **No hay ninguna lista de lo que falta.** No hay grilla de las 40 mezclas,
##    no hay "4/40", no hay hechizos en gris esperando ser desbloqueados. El
##    diseño lo dice con todas las letras (§6): *el menú completo convierte el
##    saber en información y mata el sistema entero*. Si algún día este archivo
##    dibuja una combinación que el jugador no probó, se rompió el juego.
##
## Toda la descubribilidad pasa por UNA cosa: **la frase que crece mientras
## trazás.** Ponés el primer sigilo y dice "el calor…"; ponés el segundo y dice
## "el calor repartido…". El jugador ve que el segundo trazo cambia al primero
## antes de soltar, y eso le enseña que hay una gramática sin que nadie se lo
## explique ni le muestre un catálogo.
##
## Las tres teclas: **R** traza (mantenida), **P** es el ritual de la mañana,
## **G** abre el grimorio. Ninguna pisa las que ya estaban (E, clic, Q, B, I, M,
## C, F1, F2, F3, +/−, Escape).
class_name Runas
extends Node3D

# ─────────────────────────────────────────────────────────────
# Lo que le cablea valle.gd
# ─────────────────────────────────────────────────────────────

var api: Api
var jugador: Node3D
var camara: Camera3D
## `interfaz.escribiendo` — un LineEdit con foco se come el teclado, y este
## módulo se queda con R, P, G y las cuatro iniciales.
var escribiendo := Callable()
## `interfaz.avisar` — el renglón de aviso que ya existe. No se duplica.
var avisar := Callable()
## Devuelve a qué se le puede apuntar ahora mismo: un Array de
## `{tipo, id, nombre, nodo}` con `tipo` en amenaza/persona/jugador. El suelo no
## está en la lista: es lo que queda cuando no hay nada más cerca del cursor.
var blancos := Callable()
## El día del valle. Lo empuja `valle.gd` desde /mundo, y sirve para saber si lo
## que este cliente recuerda de esta mañana sigue siendo de hoy.
var tick := 0

# ─────────────────────────────────────────────────────────────
# El vocabulario
# ─────────────────────────────────────────────────────────────
#
# **Esto es un espejo del servidor, y el espejo es a propósito.** El nombre del
# hechizo que vale es el que devuelve `/lanzar`; lo de acá existe sólo para
# armar la frase MIENTRAS trazás, que es cuando no hay a quién preguntarle: una
# ida y vuelta de 200 ms por sigilo mataría el gesto entero.
#
# La regla, entonces: si algún día no coinciden, gana el servidor y esto se
# corrige. Nunca al revés, y nunca se agrega acá una runa que allá no está.
const MATERIA := {
	"runa-de-brasa": "el calor",
	"runa-de-quietud": "la quietud",
	"runa-de-aliento": "el aliento",
	"runa-de-vena": "la vena",
}

## El género de la materia. Manda en la concordancia porque manda en el nombre.
const GENERO := {
	"runa-de-brasa": "m",
	"runa-de-quietud": "f",
	"runa-de-aliento": "m",
	"runa-de-vena": "f",
}

## Cómo se la nombra cuando va DETRÁS de otra. Ahí la runa deja de ser materia y
## pasa a ser operador, y por eso `brasa aliento` y `aliento brasa` son dos
## hechizos distintos y no dos maneras de decir lo mismo.
const ADJETIVO := {
	"runa-de-brasa": {"m": "encendido", "f": "encendida"},
	"runa-de-quietud": {"m": "que queda", "f": "que queda"},
	"runa-de-aliento": {"m": "repartido", "f": "repartida"},
	"runa-de-vena": {"m": "metido en el cuerpo", "f": "metida en el cuerpo"},
}

## La inicial que se tipea. Es la de la materia —brasa, quietud, aliento,
## vena— y las cuatro caen distinto, que era la condición para que el camino de
## teclado exista.
##
## B y Q están tomadas por el juego (buscar y esquivar), y no hay conflicto
## porque mientras el radial está abierto este módulo consume el evento en
## `_input()`, que corre antes que el `_unhandled_input()` de todos los demás.
const INICIAL := {
	KEY_B: "runa-de-brasa",
	KEY_Q: "runa-de-quietud",
	KEY_A: "runa-de-aliento",
	KEY_V: "runa-de-vena",
}

## El color de cada runa, y sale de la paleta como todo lo demás.
##
## La condición es dura y se midió en pantalla: un sigilo mide 40 píxeles y hay
## un quinto estado que compite con los cuatro —**apagado**—, así que los cuatro
## tienen que separarse entre sí Y del gris de una runa gastada. La primera
## repartija tenía el aliento en HUMO_TELA y se leía exactamente igual que una
## runa ya usada; la vena en HERRUMBRE_CLARA quedaba en la misma familia naranja
## que la brasa. Las dos se cambiaron mirando la captura.
##
##  · brasa   → el fuego. Excepción 1 de la paleta, y es la única saturada.
##  · quietud → el azul frío de la luna: el eje del tiempo no es de este valle.
##  · aliento → lo más claro que hay. El aire no tiene color, tiene valor.
##  · vena    → el verde de la barra de vida, que el jugador ya asocia con su
##              propio cuerpo. Es el jade APAGADO, no el `JADE` reservado a la
##              gente de carne y hueso.
const TINTE := {
	"runa-de-brasa": Paleta.BRASA,
	"runa-de-quietud": Paleta.LUZ_LUNAR,
	"runa-de-aliento": Paleta.UI_TEXTO,
	"runa-de-vena": Paleta.VIDA_BIEN,
}

## Una runa gastada. No es invisible —el dibujo sigue ahí, si no no habría nada
## que contar— pero tiene que leerse apagada de un vistazo contra las cuatro de
## arriba, y por eso está tan abajo.
const APAGADO := Color(0.42, 0.46, 0.45, 0.28)

## Cómo se dibuja cada runa, en un cuadrado de −1 a 1 con la Y para abajo.
##
## **Los trazos salen de la descripción que ya está en la base**, no de un gusto
## de acá: "Tres trazos" la brasa, "Cinco trazos" la quietud, "Dos trazos y un
## corte" el aliento, "Cuatro trazos cerrados" la vena. Ese texto es lo que el
## jugador lee en el grimorio, así que el dibujo tiene que poder contarse y dar
## el mismo número — si no, la descripción miente.
const TRAZOS := {
	# Tres trazos. Tres cabrios que suben, uno adentro del otro: el más chico y
	# el más alto es la punta de la llama.
	"runa-de-brasa": [
		[Vector2(-0.62, 0.72), Vector2(0.0, 0.02), Vector2(0.62, 0.72)],
		[Vector2(-0.38, 0.18), Vector2(0.0, -0.44), Vector2(0.38, 0.18)],
		[Vector2(-0.17, -0.34), Vector2(0.0, -0.86), Vector2(0.17, -0.34)],
	],
	# Cinco trazos. Cinco barras que se van acortando hacia abajo: algo que se
	# posa y se queda. Es el único eje que escribe en el futuro.
	"runa-de-quietud": [
		[Vector2(-0.78, -0.72), Vector2(0.78, -0.72)],
		[Vector2(-0.62, -0.36), Vector2(0.62, -0.36)],
		[Vector2(-0.46, 0.0), Vector2(0.46, 0.0)],
		[Vector2(-0.30, 0.36), Vector2(0.30, 0.36)],
		[Vector2(-0.14, 0.72), Vector2(0.14, 0.72)],
	],
	# Dos trazos y un corte. Dos rachas paralelas que salen hacia la derecha, y
	# el corte que las cruza: eso saca de lugar lo que agarra.
	"runa-de-aliento": [
		[Vector2(-0.82, -0.30), Vector2(0.10, -0.48), Vector2(0.80, -0.16)],
		[Vector2(-0.82, 0.38), Vector2(0.10, 0.20), Vector2(0.80, 0.52)],
		[Vector2(0.14, -0.80), Vector2(0.46, 0.80)],
	],
	# Cuatro trazos cerrados. Es la única que cierra, y cerrar es lo que hace:
	# mete lo que venía adentro de un cuerpo y no lo deja salir al suelo.
	"runa-de-vena": [
		[Vector2(0.0, -0.82), Vector2(0.68, 0.0)],
		[Vector2(0.68, 0.0), Vector2(0.0, 0.82)],
		[Vector2(0.0, 0.82), Vector2(-0.68, 0.0)],
		[Vector2(-0.68, 0.0), Vector2(0.0, -0.82)],
	],
}

## La versión de los sigilos que se lleva encima del cuerpo, en 3D.
##
## **Menos trazos, y a propósito.** Medido en una captura a la distancia de
## juego: un sigilo sobre la cabeza mide unos veinte píxeles, y los cinco trazos
## de la quietud o los tres cabrios de la brasa se funden en una mancha de
## color. Es la regla de arte de este proyecto aplicada donde toca —*la silueta
## hace el trabajo pesado*, *menos geometría, no más*— y no una versión pobre de
## la de la interfaz: son dos distancias distintas y piden dos dibujos.
##
## El detalle completo vive donde se puede mirar de cerca: el radial, el ritual
## y el grimorio. Encima del cuerpo lo que informa es **cuántos y de qué color**.
const SILUETA := {
	"runa-de-brasa": [
		[Vector2(-0.72, 0.78), Vector2(0.0, -0.16), Vector2(0.72, 0.78)],
		[Vector2(-0.24, -0.34), Vector2(0.0, -0.92), Vector2(0.24, -0.34)],
	],
	"runa-de-quietud": [
		[Vector2(-0.86, -0.60), Vector2(0.86, -0.60)],
		[Vector2(-0.52, 0.06), Vector2(0.52, 0.06)],
		[Vector2(-0.20, 0.72), Vector2(0.20, 0.72)],
	],
	"runa-de-aliento": [
		[Vector2(-0.88, -0.34), Vector2(0.10, -0.56), Vector2(0.88, -0.20)],
		[Vector2(-0.88, 0.44), Vector2(0.10, 0.22), Vector2(0.88, 0.58)],
	],
	"runa-de-vena": [
		[Vector2(0.0, -0.88), Vector2(0.74, 0.0)],
		[Vector2(0.74, 0.0), Vector2(0.0, 0.88)],
		[Vector2(0.0, 0.88), Vector2(-0.74, 0.0)],
		[Vector2(-0.74, 0.0), Vector2(0.0, -0.88)],
	],
}

const FRASCO := "frasco de raíz"
## Entran tres. La cuarta sólo con un frasco, que lo fabrica otro.
const CUANTAS_ENTRAN := 3

const RADIO_RADIAL := 104.0
const SIGILO_RADIAL := 44.0
const SIGILO_HUD := 40.0
## A cuántos píxeles del cursor todavía cuenta que le apuntaste a algo. Con la
## cámara a 40 metros un bicho mide poco: pedir precisión de píxel sería pedir
## que el gesto falle.
const AGARRE := 90.0

# ─────────────────────────────────────────────────────────────
# Estado
# ─────────────────────────────────────────────────────────────

## Las runas que te enseñaron: `{slug, nombre, descripcion, destreza, de}`.
var _sabidas: Array = []
## Las mezclas que te salieron A VOS. Nunca las posibles.
var _paginas: Array = []
## Lo que te colgaste esta mañana, en orden. Ver `_recordar_la_manana()`: el
## servidor borra la fila al gastarla, así que sin esta memoria una runa gastada
## no se apagaría, desaparecería.
var _colgadas: Array = []
## Cuáles de ésas todavía te quedan. Lo manda el servidor en `quedan`.
var _quedan: Dictionary = {}
## El frasco que llevás encima, si llevás: `{kind, made_by}`. Es lo único que
## hace aparecer la cuarta ranura.
var _frasco: Dictionary = {}
## De qué día del valle es lo que recuerda `_colgadas`. Ver `_guardar_la_manana()`.
var _tick_memoria := -1
## La mezcla que el servidor acaba de declarar nueva y que todavía no está en el
## grimorio que tenemos en la mano. Ver `_al_lanzar()`.
var _por_estrenar: Array = []

var _radial := false
var _trazo: Array = []
var _centro_radial := Vector2.ZERO
var _cursor := Vector2.ZERO
var _blanco_actual: Dictionary = {}

var _ritual_abierto := false
var _eleccion: Array = []

var _libro_abierto := false
var _hoja := 0
## De 0 a 1 mientras una página nueva se escribe sola delante tuyo. Es el
## momento del sistema: el servidor contesta `nueva: true` y la hoja se dibuja.
var _escribiendose := 0.0
var _tw_escribir: Tween

var _capa: CanvasLayer
var _lienzo: Control
var _fuente: Font = ThemeDB.fallback_font

## Los sigilos que se te ven encima. Es lo que llevás hoy, y se te nota.
var _sobre_el_cuerpo: Node3D

## Las cicatrices del valle: id de encantamiento -> Node3D.
var _marcas: Dictionary = {}

const MEMORIA := "user://runas.json"


func _ready() -> void:
	_capa = CanvasLayer.new()
	# Encima del HUD, que es la capa 1. Los dos paneles de este módulo tapan lo
	# que haya abajo mientras están abiertos, y eso es lo correcto: el ritual de
	# la mañana y el grimorio son momentos, no widgets.
	_capa.layer = 2
	add_child(_capa)

	_lienzo = Control.new()
	_lienzo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Todo el mouse lo maneja `_input()`: el radial no es un widget, es un gesto
	# encima del mundo, y tiene que dejar ver lo que hay abajo.
	_lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lienzo.draw.connect(_pintar)
	_capa.add_child(_lienzo)

	_sobre_el_cuerpo = Node3D.new()
	_sobre_el_cuerpo.name = "SigilosEncima"
	add_child(_sobre_el_cuerpo)

	_recordar_la_manana()

	if api != null:
		api.grimorio_recibido.connect(_al_grimorio)
		api.preparado.connect(_al_preparar)
		api.lanzado.connect(_al_lanzar)
		# Sin token no hay a quién preguntarle: la primera vuelta la dispara
		# `/mundo` cuando el jugador escribe el suyo.
		if api.token != "":
			api.pedir_grimorio()


# ─────────────────────────────────────────────────────────────
# Lo que llega del servidor
# ─────────────────────────────────────────────────────────────

func _al_grimorio(d: Dictionary) -> void:
	_sabidas = d.get("runas", [])
	_paginas = d.get("paginas", [])
	var lleva: Array = d.get("lleva", [])

	# `lleva` es lo que te QUEDA, no lo que te colgaste: el servidor borra la
	# fila de `preparadas` al trazarla. Si esta sesión ya vio la mañana de hoy,
	# el conjunto completo lo tenemos nosotros y las que faltan están gastadas.
	# Si no —recién abrís el juego, o es otro día— lo que hay es lo que hay.
	var slugs: Array = []
	for r in lleva:
		slugs.append(str((r as Dictionary).get("slug", "")))
	# Lo que se recordó es de un día concreto del valle. Sin esta comparación,
	# entrar al día siguiente sin haberte colgado nada mostraba las de AYER,
	# las tres apagadas, en vez de decirte que no llevás nada.
	if _tick_memoria != tick:
		_colgadas = []
		_tick_memoria = tick
	if _colgadas.is_empty() or not _colgadas_de_hoy(slugs):
		_colgadas = slugs.duplicate()
	_quedan = {}
	for s: String in slugs:
		_quedan[s] = true
	_guardar_la_manana()
	_rehacer_sigilos_encima()
	_lienzo.queue_redraw()

	# Y si veníamos esperando una hoja nueva, ya llegó: el libro se abre solo y
	# la página se escribe delante del jugador.
	if not _por_estrenar.is_empty():
		var recien: Array = _por_estrenar
		_por_estrenar = []
		_abrir_libro_en_lo_nuevo(recien)


## ¿Lo que recordamos de esta mañana sigue siendo compatible con lo que dice el
## servidor? Lo es si todo lo que él dice que llevás está en nuestra lista: las
## que faltan son las gastadas. Si aparece una que no teníamos, nuestra memoria
## es de otro día o de otra sesión y se descarta.
func _colgadas_de_hoy(slugs: Array) -> bool:
	for s: String in slugs:
		if not _colgadas.has(s):
			return false
	return true


func _al_preparar(d: Dictionary) -> void:
	if not bool(d.get("ok", false)):
		_decir(str(d.get("porque", "no salió")))
		return
	_colgadas = []
	_quedan = {}
	for r in d.get("runas", []):
		var slug := str((r as Dictionary).get("slug", ""))
		_colgadas.append(slug)
		_quedan[slug] = true
	_guardar_la_manana()
	_ritual_abierto = false
	_eleccion = []
	_rehacer_sigilos_encima()
	_lienzo.queue_redraw()
	_decir(str(d.get("cuenta", "")))
	if api != null:
		api.pedir_grimorio()


func _al_lanzar(d: Dictionary) -> void:
	if not bool(d.get("ok", false)):
		# El "no" del servidor está escrito para leerse: "el trazo no agarra la
		# piedra: eso va en un cuerpo" enseña la gramática mejor que cualquier
		# tutorial. No se reescribe ni se resume.
		_decir(str(d.get("porque", "no salió")))
		return

	# Lo que queda colgado lo dice el servidor, siempre. Acá no se descuenta
	# nada de memoria: si el trazo no agarró nada, las runas no se gastaron, y
	# eso lo sabe él y no nosotros.
	_quedan = {}
	for s in d.get("quedan", []):
		_quedan[str(s)] = true
	_rehacer_sigilos_encima()

	_decir(str(d.get("cuenta", "")))
	if bool(d.get("nueva", false)):
		# El momento. Una mezcla que nunca te había salido se anota sola en el
		# grimorio, delante tuyo, y por eso el libro se abre en esa hoja.
		#
		# Se ANOTA la mezcla y se espera al grimorio en vez de dormir medio
		# segundo y abrir: la hoja no existe hasta que el servidor la manda, y
		# una espera fija se pierde el estreno justo cuando la red anda lenta,
		# que es cuando más se nota. Ver el final de `_al_grimorio()`.
		_por_estrenar = (d.get("runas", []) as Array).duplicate()
		if api != null:
			api.pedir_grimorio()
	_lienzo.queue_redraw()


## Lo que llevás en la bolsa, para saber si hay frasco. Lo empuja `valle.gd` con
## la misma lista que ya recibe de /mundo — no se pide dos veces.
func mirar_la_bolsa(objetos: Array) -> void:
	_frasco = {}
	for o in objetos:
		var d: Dictionary = o
		if str(d.get("kind", "")) == FRASCO:
			_frasco = d
			break
	if _ritual_abierto:
		_lienzo.queue_redraw()


# ─────────────────────────────────────────────────────────────
# La memoria de la mañana
# ─────────────────────────────────────────────────────────────
#
# Un archivo de dos campos y no una tabla nueva en el servidor, y la razón es
# que **no es estado del mundo**: qué te colgaste hoy ya está en `preparadas`, y
# lo que se gastó ya no está ahí porque gastarse es dejar de estar. Lo único que
# esto recuerda es cuáles había a la mañana, para poder dibujar el sigilo
# APAGADO en vez de no dibujarlo.
#
# Esa diferencia es todo el punto de la regla 3 del diseño: se ven tres
# encendidos y quedan dos. Si el gastado desapareciera, no habría cuenta que
# hacer, habría una fila más corta.

func _guardar_la_manana() -> void:
	_tick_memoria = tick
	var f := FileAccess.open(MEMORIA, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"tick": tick, "colgadas": _colgadas}))


func _recordar_la_manana() -> void:
	if not FileAccess.file_exists(MEMORIA):
		return
	var f := FileAccess.open(MEMORIA, FileAccess.READ)
	if f == null:
		return
	var j: Variant = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		_colgadas = (j as Dictionary).get("colgadas", [])
		_tick_memoria = int((j as Dictionary).get("tick", -1))


# ─────────────────────────────────────────────────────────────
# La gramática, sólo para la frase que crece
# ─────────────────────────────────────────────────────────────

## Cómo se llama lo que va saliendo. Se ARMA, igual que en el servidor: cuarenta
## nombres escritos a mano serían un catálogo, y un catálogo se publica en una
## wiki. "el calor repartido y que queda" se lee como una descripción de lo que
## viste, no como el nombre de un ítem.
##
## Devuelve los pedazos por separado —`[{texto, slug}]`— porque cada pedazo se
## pinta del color de su runa: así se VE que el segundo trazo le cambió algo al
## primero, que es exactamente lo que hay que enseñar.
func _frase(secuencia: Array) -> Array:
	if secuencia.is_empty():
		return []
	var materia := str(secuencia[0])
	var g: String = GENERO.get(materia, "m")
	var partes: Array = [{"texto": MATERIA.get(materia, materia), "slug": materia}]
	for i in range(1, secuencia.size()):
		var slug := str(secuencia[i])
		var adj: Dictionary = ADJETIVO.get(slug, {})
		partes.append({
			"texto": (" y " if i > 1 else " ") + str(adj.get(g, slug)),
			"slug": slug,
		})
	return partes


func _nombre_corto(slug: String) -> String:
	return str(MATERIA.get(slug, slug))


## Quién te enseñó esa runa, o "" si la trajiste puesta.
##
## `learned_from` viaja como `null` cuando nadie te la enseñó, y `str(null)` en
## GDScript devuelve la cadena "<null>": sin este filtro la pantalla decía
## literalmente "te la enseñó <null>". Es un caso normal del mundo —hay saber
## que se trae puesto— y tiene que leerse como tal.
func _de_quien(r: Dictionary) -> String:
	var v: Variant = r.get("de")
	if v == null:
		return ""
	return str(v)


func _decir(texto: String) -> void:
	if texto != "" and avisar.is_valid():
		avisar.call(texto)


# ─────────────────────────────────────────────────────────────
# Teclado y mouse
# ─────────────────────────────────────────────────────────────

## ¿Este módulo se está quedando con el teclado? `valle.gd` lo suma a
## `_jugador_sin_control()`: con el radial abierto o un panel encima, WASD no es
## del personaje.
func captura_teclado() -> bool:
	return _radial or _ritual_abierto or _libro_abierto


func _tecleando() -> bool:
	return escribiendo.is_valid() and bool(escribiendo.call())


## Va en `_input()` y no en `_unhandled_input()` a propósito.
##
## Las iniciales del radial son B, Q, A y V, y B y Q ya son del juego (buscar y
## esquivar). `_input()` corre antes que todos los `_unhandled_input()`, así que
## alcanza con marcar el evento como manejado para que el radial se quede con la
## tecla mientras está abierto y no la vea nadie más. El clic izquierdo es el
## mismo caso: golpear sale de `jugador.gd` por `_unhandled_input()`, y tocar un
## sigilo no puede además pegarle a un bicho.
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_cursor = (evento as InputEventMouseMotion).position
		if _radial:
			_blanco_actual = _blanco_bajo(_cursor)
			_lienzo.queue_redraw()
		return

	if evento is InputEventMouseButton:
		var mb := evento as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_cursor = mb.position
		if _radial and mb.pressed:
			_tocar_sigilo(mb.position)
			get_viewport().set_input_as_handled()
		elif _ritual_abierto and mb.pressed:
			_clic_ritual(mb.position)
			get_viewport().set_input_as_handled()
		elif _libro_abierto and mb.pressed:
			_clic_libro(mb.position)
			get_viewport().set_input_as_handled()
		return

	if not (evento is InputEventKey):
		return
	var k := evento as InputEventKey
	if k.echo:
		return

	# Soltar R cierra el trazo, y hay que atenderlo aunque haya un campo de
	# texto con foco: si no, una tecla que quedó apretada deja el radial abierto
	# para siempre.
	if not k.pressed and k.keycode == KEY_R and _radial:
		_soltar_trazo()
		get_viewport().set_input_as_handled()
		return
	if not k.pressed:
		return
	if _tecleando():
		return

	if _radial:
		if INICIAL.has(k.keycode):
			_sumar_al_trazo(str(INICIAL[k.keycode]))
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_ESCAPE:
			_radial = false
			_trazo = []
			_lienzo.queue_redraw()
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_BACKSPACE and not _trazo.is_empty():
			_trazo.pop_back()
			_lienzo.queue_redraw()
			get_viewport().set_input_as_handled()
		return

	if _ritual_abierto or _libro_abierto:
		if k.keycode == KEY_ESCAPE or k.keycode == KEY_P or k.keycode == KEY_G:
			_ritual_abierto = false
			_libro_abierto = false
			_lienzo.queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if _libro_abierto and (k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT):
			_pasar_hoja(1 if k.keycode == KEY_RIGHT else -1)
			get_viewport().set_input_as_handled()
			return
		if _ritual_abierto and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER):
			_colgarse()
			get_viewport().set_input_as_handled()
			return
		if _ritual_abierto and INICIAL.has(k.keycode):
			_elegir_para_hoy(str(INICIAL[k.keycode]))
			get_viewport().set_input_as_handled()
			return
		return

	match k.keycode:
		KEY_R:
			_abrir_radial()
			get_viewport().set_input_as_handled()
		KEY_P:
			_abrir_ritual()
			get_viewport().set_input_as_handled()
		KEY_G:
			_libro_abierto = true
			_hoja = 0
			_escribiendose = 1.0
			_lienzo.queue_redraw()
			get_viewport().set_input_as_handled()


func _process(_dt: float) -> void:
	if _sobre_el_cuerpo != null and jugador != null and is_instance_valid(jugador):
		_sobre_el_cuerpo.global_position = jugador.global_position + Vector3(0, 2.85, 0)
	if _radial:
		# El blanco puede moverse aunque el mouse esté quieto: un bicho que
		# camina hacia vos mientras trazás cambia el cauce solo.
		var nuevo := _blanco_bajo(_cursor)
		if str(nuevo.get("id", "")) != str(_blanco_actual.get("id", "")):
			_blanco_actual = nuevo
			_lienzo.queue_redraw()


# ─────────────────────────────────────────────────────────────
# Trazar
# ─────────────────────────────────────────────────────────────

func _mano() -> Array:
	## Los sigilos que se pueden trazar ahora: los de hoy que todavía no gastaste.
	var vivos: Array = []
	for s in _colgadas:
		if _quedan.has(str(s)):
			vivos.append(str(s))
	return vivos


func _abrir_radial() -> void:
	if _sabidas.is_empty():
		_decir("Todavía no sabes ninguna runa. Se aprenden de alguien.")
		return
	if _colgadas.is_empty():
		_decir("No te colgaste ninguna runa hoy. P para hacerlo.")
		return
	if _mano().is_empty():
		_decir("Ya gastaste todo lo que llevabas. Mañana se cuelgan otras.")
		return
	_radial = true
	_trazo = []
	_cursor = _lienzo.get_global_mouse_position()
	# El radial florece DONDE ESTÁ EL CURSOR y se queda ahí: después te vas con
	# el mouse hasta el blanco y soltás. Si siguiera al mouse no habría gesto,
	# habría un menú pegado a la punta del puntero.
	_centro_radial = _cursor
	_blanco_actual = _blanco_bajo(_cursor)
	_lienzo.queue_redraw()


func _tocar_sigilo(donde: Vector2) -> void:
	var mano := _mano()
	for i in mano.size():
		if _lugar_radial(i, mano.size()).distance_to(donde) <= SIGILO_RADIAL * 0.72:
			_sumar_al_trazo(str(mano[i]))
			return


func _sumar_al_trazo(slug: String) -> void:
	if not _mano().has(slug):
		return
	# Una runa se traza una vez. No es una restricción de sistema: llevás la
	# runa, no cargas de la runa, y repetirla no significa nada.
	if _trazo.has(slug):
		return
	_trazo.append(slug)
	_lienzo.queue_redraw()


func _lugar_radial(i: int, cuantos: int) -> Vector2:
	# Arranca arriba y va en sentido horario. Con tres o cuatro sigilos el
	# reparto es siempre el mismo, así que la mano se acostumbra.
	var a := -PI * 0.5 + TAU * float(i) / float(maxi(1, cuantos))
	return _centro_radial + Vector2(cos(a), sin(a)) * RADIO_RADIAL


func _soltar_trazo() -> void:
	_radial = false
	var secuencia := _trazo.duplicate()
	_trazo = []
	_lienzo.queue_redraw()
	if secuencia.is_empty():
		return
	if api == null:
		return
	var b := _blanco_bajo(_cursor)
	var tipo := str(b.get("tipo", "lugar"))
	var id := str(b.get("id", ""))
	api.lanzar(PackedStringArray(secuencia), tipo, id)


## A qué le apuntás. El cauce sale del GESTO y no de una runa: si el blanco
## fuera una pieza más, cada hechizo te costaría una de las tres que llevás sólo
## para decir "a ése", y el vocabulario chico se comería a sí mismo.
##
## Cuatro cauces y se eligen por lo que haya cerca del cursor al soltar: un
## bicho, una persona, vos, o el suelo. El suelo no compite — es lo que queda
## cuando no hay nada más, y por eso siempre hay adónde tirar.
func _blanco_bajo(donde: Vector2) -> Dictionary:
	var suelo := {"tipo": "lugar", "id": "", "nombre": "el suelo de acá"}
	if camara == null or not is_instance_valid(camara) or not blancos.is_valid():
		return suelo
	var lista: Array = blancos.call()
	var mejor: Dictionary = {}
	var d_min := AGARRE
	for c in lista:
		var d: Dictionary = c
		var nodo: Node3D = d.get("nodo")
		if nodo == null or not is_instance_valid(nodo):
			continue
		var p: Vector3 = nodo.global_position + Vector3(0, 1.0, 0)
		if camara.is_position_behind(p):
			continue
		var dist := camara.unproject_position(p).distance_to(donde)
		if dist < d_min:
			d_min = dist
			mejor = d
	if mejor.is_empty():
		return suelo
	return mejor


# ─────────────────────────────────────────────────────────────
# El ritual de la mañana
# ─────────────────────────────────────────────────────────────
#
# No es una grilla de casilleros y la diferencia importa (§8.3): "no podés
# llevar todo encima" tiene que sentirse como salir de tu casa a la mañana. Por
# eso lo que se ve son los sigilos que sabés, y elegís tres.
#
# **La cuarta ranura no está apagada: NO ESTÁ.** Aparece sólo si llevás un
# frasco de raíz, y se dibuja como el frasco, con el nombre de quien lo hizo. Es
# la única forma de exceder tu capacidad y la fabrica otro — eso le da al que
# destila poder real sobre el que pelea sin que nadie farmee nada.

func _abrir_ritual() -> void:
	if _sabidas.is_empty():
		_decir("Todavía no sabes ninguna runa. Se aprenden de alguien.")
		return
	_ritual_abierto = true
	_eleccion = _colgadas.duplicate()
	_lienzo.queue_redraw()
	if api != null:
		api.pedir_grimorio()


func _cuantas_entran_hoy() -> int:
	return CUANTAS_ENTRAN + (1 if not _frasco.is_empty() else 0)


func _elegir_para_hoy(slug: String) -> void:
	var sabe := false
	for r in _sabidas:
		if str((r as Dictionary).get("slug", "")) == slug:
			sabe = true
			break
	if not sabe:
		return
	if _eleccion.has(slug):
		_eleccion.erase(slug)
	elif _eleccion.size() < _cuantas_entran_hoy():
		_eleccion.append(slug)
	_lienzo.queue_redraw()


func _clic_ritual(donde: Vector2) -> void:
	var d := _disposicion_ritual()
	if (d["cerrar"] as Rect2).has_point(donde):
		_ritual_abierto = false
		_lienzo.queue_redraw()
		return
	if (d["colgar"] as Rect2).has_point(donde) and not _eleccion.is_empty():
		_colgarse()
		return
	var ranuras: Array = d["ranuras"]
	for i in ranuras.size():
		if (ranuras[i] as Rect2).has_point(donde) and i < _eleccion.size():
			_eleccion.remove_at(i)
			_lienzo.queue_redraw()
			return
	var cajas: Array = d["sabidas"]
	for i in cajas.size():
		if (cajas[i] as Rect2).has_point(donde):
			_elegir_para_hoy(str((_sabidas[i] as Dictionary).get("slug", "")))
			return


func _colgarse() -> void:
	if api == null or _eleccion.is_empty():
		return
	api.preparar(PackedStringArray(_eleccion))


# ─────────────────────────────────────────────────────────────
# El grimorio
# ─────────────────────────────────────────────────────────────
#
# Un libro, no un menú. La primera hoja son las runas que sabés **con el nombre
# de quien te la enseñó** —esa es la mitad del valor de una runa en este juego,
# y el nombre tiene que sobrevivir a que esa persona no esté—. Después, una hoja
# por mezcla que TE SALIÓ.
#
# Lo que no hay, y no se agrega nunca: la lista de lo que falta, el contador de
# "4 de 40", las combinaciones en gris esperando. El que entra hoy tiene una
# hoja en blanco y las mismas cuatro runas que el que lleva cuarenta horas.

func _hojas() -> int:
	return 1 + _paginas.size()


func _pasar_hoja(cuanto: int) -> void:
	_hoja = clampi(_hoja + cuanto, 0, maxi(0, _hojas() - 1))
	_escribiendose = 1.0
	_lienzo.queue_redraw()


func _clic_libro(donde: Vector2) -> void:
	var d := _disposicion_libro()
	if (d["cerrar"] as Rect2).has_point(donde):
		_libro_abierto = false
		_lienzo.queue_redraw()
		return
	if (d["antes"] as Rect2).has_point(donde):
		_pasar_hoja(-1)
	elif (d["despues"] as Rect2).has_point(donde):
		_pasar_hoja(1)


## Abrir el libro en la hoja que se acaba de escribir, y verla escribirse.
##
## Es el único momento en que este módulo abre algo solo, y se lo gana: es la
## primera vez que esa mezcla te sale, y el juego no tiene otra forma de decirte
## que descubriste algo. La página se dibuja trazo por trazo delante tuyo.
func _abrir_libro_en_lo_nuevo(secuencia: Array) -> void:
	var i := _indice_de(secuencia)
	if i < 0:
		return
	_libro_abierto = true
	_hoja = 1 + i
	_escribiendose = 0.0
	if _tw_escribir != null and _tw_escribir.is_valid():
		_tw_escribir.kill()
	_tw_escribir = create_tween()
	_tw_escribir.tween_method(
		func(v: float) -> void:
			_escribiendose = v
			_lienzo.queue_redraw(),
		0.0, 1.0, 1.6)


func _indice_de(secuencia: Array) -> int:
	for i in _paginas.size():
		var p: Dictionary = _paginas[i]
		var rs: Array = p.get("runas", [])
		if rs.size() != secuencia.size():
			continue
		var igual := true
		for j in rs.size():
			if str(rs[j]) != str(secuencia[j]):
				igual = false
				break
		if igual:
			return i
	return -1


# ─────────────────────────────────────────────────────────────
# Dibujo
# ─────────────────────────────────────────────────────────────

func _pintar() -> void:
	_pintar_mano()
	if _radial:
		_pintar_radial()
	if _ritual_abierto:
		_pintar_ritual()
	if _libro_abierto:
		_pintar_libro()


## Los sigilos que llevás, abajo a la izquierda. Ninguna barra: se ven tres
## encendidos y quedan dos, y cuando no queda ninguno la mano está vacía hasta
## mañana. No hay maná que se recargue solo — hay lo que trajiste.
func _pintar_mano() -> void:
	var alto := _lienzo.size.y
	var x := 30.0
	var y := alto - 118.0

	if _sabidas.is_empty():
		return

	if _colgadas.is_empty():
		_texto(Vector2(x, y + 26.0), "P — colgarte las runas de hoy",
			14, Paleta.UI_TEXTO_DEBIL)
		return

	var vivas := _mano().size()
	_texto(Vector2(x, y - 10.0),
		"hoy llevas" if vivas > 0 else "la mano vacía hasta mañana",
		13, Paleta.UI_TEXTO_TENUE if vivas > 0 else Paleta.UI_TEXTO_DEBIL)

	for i in _colgadas.size():
		var slug := str(_colgadas[i])
		var c := Vector2(x + SIGILO_HUD * 0.5 + float(i) * (SIGILO_HUD + 14.0),
			y + SIGILO_HUD * 0.5 + 8.0)
		var encendido: bool = _quedan.has(slug)
		_sigilo(c, SIGILO_HUD * 0.5, slug, encendido, 1.0)

	var pie := "R trazar · G grimorio" if vivas > 0 else "G grimorio"
	_texto(Vector2(x, y + SIGILO_HUD + 40.0), pie, 12, Paleta.UI_TEXTO_DEBIL)


## El radial y la frase. Esto es la descubribilidad entera del sistema: el
## jugador ve que el segundo trazo le cambia el nombre al primero ANTES de
## soltar, y de ahí saca solo que hay una gramática.
func _pintar_radial() -> void:
	var mano := _mano()

	# Un disco apenas oscuro debajo, para que los sigilos se lean encima del
	# pasto sin taparle el mundo. La cámara está a 40 metros: sin esto, un
	# sigilo gris sobre hierba gris no existe.
	_lienzo.draw_circle(_centro_radial, RADIO_RADIAL + SIGILO_RADIAL * 0.85,
		Color(Paleta.UI_FONDO, 0.78))
	_lienzo.draw_arc(_centro_radial, RADIO_RADIAL, 0.0, TAU, 48,
		Color(Paleta.UI_TEXTO_DEBIL, 0.45), 1.5, true)

	for i in mano.size():
		var slug := str(mano[i])
		var c := _lugar_radial(i, mano.size())
		var puesto := _trazo.has(slug)
		var orden := _trazo.find(slug)
		var cerca: bool = c.distance_to(_cursor) <= SIGILO_RADIAL * 0.72
		var r := SIGILO_RADIAL * 0.5 * (1.12 if cerca and not puesto else 1.0)
		_lienzo.draw_circle(c, r + 8.0, Color(Paleta.UI_PANEL, 0.88))
		# Una runa YA PUESTA no se dibuja como una gastada. Son dos estados
		# distintos y confundirlos costaba lo único que este radial tiene que
		# dejar claro: **cuál** pusiste primero. Se atenúa, pero conserva su
		# color, así que la secuencia se lee de un vistazo.
		_sigilo(c, r, slug, true, 1.0,
			Color(TINTE.get(slug, Paleta.UI_TEXTO), 0.55) if puesto else Color(0, 0, 0, 0))
		if puesto:
			# El número de orden. El orden ES la mezcla, así que tiene que
			# verse: `brasa aliento` no es `aliento brasa`.
			var t: Color = TINTE.get(slug, Paleta.UI_TEXTO)
			_lienzo.draw_circle(c + Vector2(r * 0.85, -r * 0.85), 9.0, Color(t, 0.95))
			_texto(c + Vector2(r * 0.85 - 3.5, -r * 0.85 + 5.0),
				str(orden + 1), 13, Paleta.UI_FONDO)
		else:
			_texto(c + Vector2(-4.0, r + 20.0),
				_letra_de(slug), 13, Color(Paleta.UI_TEXTO_TENUE, 0.9))

	# La frase, creciendo, cada pieza del color de su runa.
	var base := _centro_radial + Vector2(0, RADIO_RADIAL + SIGILO_RADIAL * 0.9 + 34.0)
	if _trazo.is_empty():
		_centrado(base, "tocá un sigilo, o tipeá su inicial", 15,
			Color(Paleta.UI_TEXTO_DEBIL, 0.95))
	else:
		var partes := _frase(_trazo)
		var ancho := 0.0
		for p in partes:
			ancho += _fuente.get_string_size(str((p as Dictionary)["texto"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var puntos := _fuente.get_string_size("…", HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var x := base.x - (ancho + puntos) * 0.5
		for p in partes:
			var d: Dictionary = p
			var t := str(d["texto"])
			var col: Color = TINTE.get(str(d["slug"]), Paleta.UI_TEXTO)
			_texto(Vector2(x, base.y), t, 22, col)
			x += _fuente.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		_texto(Vector2(x, base.y), "…", 22, Paleta.UI_TEXTO_DEBIL)

	# Y adónde va. El cauce se lee al lado del cursor porque el cursor es el que
	# lo elige: soltás sobre el bicho, sobre alguien, sobre vos o sobre el suelo.
	var hacia := str(_blanco_actual.get("nombre", "el suelo de acá"))
	_texto(_cursor + Vector2(20.0, -14.0), "sobre " + hacia, 15, Paleta.UI_ACENTO)
	_lienzo.draw_arc(_cursor, 13.0, 0.0, TAU, 20, Color(Paleta.UI_ACENTO, 0.8), 1.5, true)


func _letra_de(slug: String) -> String:
	for k: int in INICIAL:
		if str(INICIAL[k]) == slug:
			return OS.get_keycode_string(k)
	return ""


func _disposicion_ritual() -> Dictionary:
	var v := _lienzo.size
	# 480 y no 440: el renglón de "de quién la aprendiste" se metía debajo del
	# botón. El panel lo manda el contenido, no un número redondo.
	var caja := Rect2(v.x * 0.5 - 430.0, v.y * 0.5 - 240.0, 860.0, 480.0)
	var entran := _cuantas_entran_hoy()
	var ranuras: Array = []
	var ancho := 96.0
	var sep := 26.0
	var total := float(entran) * ancho + float(entran - 1) * sep
	var x0 := caja.position.x + (caja.size.x - total) * 0.5
	for i in entran:
		ranuras.append(Rect2(x0 + float(i) * (ancho + sep),
			caja.position.y + 118.0, ancho, ancho))
	var sabidas: Array = []
	var n := _sabidas.size()
	var aw := 74.0
	# Ancho, y no por gusto: debajo de cada sigilo va el nombre de quien te la
	# enseñó, y con la separación de 30 los cuatro nombres se pisaban entre sí
	# hasta ser ilegibles. El renglón que hay abajo manda el paso, no el dibujo.
	var asep := 124.0
	var atotal := float(n) * aw + float(maxi(0, n - 1)) * asep
	var ax := caja.position.x + (caja.size.x - atotal) * 0.5
	for i in n:
		sabidas.append(Rect2(ax + float(i) * (aw + asep),
			caja.position.y + 272.0, aw, aw))
	return {
		"caja": caja,
		"ranuras": ranuras,
		"sabidas": sabidas,
		"colgar": Rect2(caja.position.x + caja.size.x - 214.0,
			caja.position.y + caja.size.y - 54.0, 190.0, 34.0),
		"cerrar": Rect2(caja.position.x + caja.size.x - 44.0,
			caja.position.y + 14.0, 30.0, 30.0),
	}


func _pintar_ritual() -> void:
	var d := _disposicion_ritual()
	var caja: Rect2 = d["caja"]
	_panel(caja)

	_texto(caja.position + Vector2(34, 46), "La mañana", 27, Paleta.UI_TEXTO)
	_texto(caja.position + Vector2(34, 74),
		"Lo que te colgás ahora es lo de todo el día. Mañana se cambian.",
		14, Paleta.UI_TEXTO_TENUE)

	var ranuras: Array = d["ranuras"]
	for i in ranuras.size():
		var r: Rect2 = ranuras[i]
		var c := r.position + r.size * 0.5
		var cuarta := i >= CUANTAS_ENTRAN
		# La cuarta ranura ES el frasco. No es una ranura con un candado: no
		# existe si no lo llevás, y cuando existe se dibuja como lo que la
		# sostiene, con el nombre de quien lo hizo.
		_lienzo.draw_rect(r, Color(Paleta.UI_FONDO, 0.75), true)
		_lienzo.draw_rect(r, Color(
			Paleta.UI_ACENTO if cuarta else Paleta.UI_TEXTO_DEBIL, 0.65), false, 1.5)
		if i < _eleccion.size():
			_sigilo(c, r.size.x * 0.34, str(_eleccion[i]), true, 1.0)
			_centrado(Vector2(c.x, r.position.y + r.size.y + 20.0),
				str(i + 1), 13, Paleta.UI_TEXTO_DEBIL)
		elif cuarta:
			_frasquito(c, r.size.x * 0.30)
			var quien := str(_frasco.get("made_by", ""))
			_centrado(Vector2(c.x, r.position.y + r.size.y + 20.0),
				("lo hizo " + quien) if quien != "" else FRASCO,
				12, Paleta.UI_ACENTO)
		else:
			_centrado(Vector2(c.x, c.y + 6.0), str(i + 1), 22,
				Color(Paleta.UI_TEXTO_DEBIL, 0.55))

	_texto(caja.position + Vector2(34, 240), "Lo que sabes", 15, Paleta.UI_TEXTO_TENUE)
	var cajas: Array = d["sabidas"]
	for i in cajas.size():
		var r: Rect2 = cajas[i]
		var s: Dictionary = _sabidas[i]
		var slug := str(s.get("slug", ""))
		var puesta := _eleccion.has(slug)
		_sigilo(r.position + r.size * 0.5, r.size.x * 0.5, slug, not puesta, 1.0)
		# De quién la aprendiste. Es la mitad del valor de una runa: un hechizo
		# vale por de quién lo recibiste, y ese nombre tiene que seguir estando
		# cuando esa persona ya no esté. Acá va corto —sólo el nombre— porque el
		# renglón entero es de la primera hoja del grimorio.
		var de := _de_quien(s)
		_centrado(Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y + 18.0),
			_nombre_corto(slug), 13,
			Color(Paleta.UI_TEXTO_DEBIL if puesta else Paleta.UI_TEXTO, 1.0))
		_centrado(Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y + 36.0),
			("de " + de) if de != "" else "sin maestro", 11, Paleta.UI_ACENTO)

	if _colgadas.size() > 0:
		_texto(caja.position + Vector2(34, caja.size.y - 28.0),
			"Ya te colgaste las de hoy; mañana se cambian.", 13, Paleta.UI_TEXTO_DEBIL)
	else:
		_texto(caja.position + Vector2(34, caja.size.y - 28.0),
			"Tocá los sigilos, o tipeá sus iniciales.", 13, Paleta.UI_TEXTO_DEBIL)

	var b: Rect2 = d["colgar"]
	var listo := not _eleccion.is_empty()
	_lienzo.draw_rect(b, Color(Paleta.UI_ACENTO if listo else Paleta.UI_TEXTO_DEBIL, 0.16), true)
	_lienzo.draw_rect(b, Color(Paleta.UI_ACENTO if listo else Paleta.UI_TEXTO_DEBIL, 0.7), false, 1.5)
	_centrado(b.position + Vector2(b.size.x * 0.5, 23.0), "Colgármelas  ⏎", 15,
		Paleta.UI_ACENTO if listo else Paleta.UI_TEXTO_DEBIL)
	_cruz(d["cerrar"])


func _disposicion_libro() -> Dictionary:
	var v := _lienzo.size
	var caja := Rect2(v.x * 0.5 - 400.0, v.y * 0.5 - 260.0, 800.0, 520.0)
	return {
		"caja": caja,
		"antes": Rect2(caja.position.x + 20.0, caja.position.y + caja.size.y - 48.0, 34.0, 30.0),
		"despues": Rect2(caja.position.x + 62.0, caja.position.y + caja.size.y - 48.0, 34.0, 30.0),
		"cerrar": Rect2(caja.position.x + caja.size.x - 44.0, caja.position.y + 14.0, 30.0, 30.0),
	}


func _pintar_libro() -> void:
	var d := _disposicion_libro()
	var caja: Rect2 = d["caja"]
	_panel(caja)
	_hoja = clampi(_hoja, 0, maxi(0, _hojas() - 1))

	if _hoja == 0:
		_pintar_hoja_de_runas(caja)
	else:
		_pintar_hoja_de_mezcla(caja, _paginas[_hoja - 1])

	# "hoja 3 de 7" es cuánto tenés, no cuánto te falta. La diferencia no es
	# semántica: un "3 de 40" convertiría el grimorio en una barra de progreso.
	_centrado(Vector2(caja.position.x + caja.size.x * 0.5,
		caja.position.y + caja.size.y - 26.0),
		"hoja %d de %d" % [_hoja + 1, _hojas()], 12, Paleta.UI_TEXTO_DEBIL)
	_flecha(d["antes"], -1, _hoja > 0)
	_flecha(d["despues"], 1, _hoja < _hojas() - 1)
	_cruz(d["cerrar"])


func _pintar_hoja_de_runas(caja: Rect2) -> void:
	_texto(caja.position + Vector2(38, 50), "Lo que sabes", 27, Paleta.UI_TEXTO)
	if _sabidas.is_empty():
		_texto(caja.position + Vector2(38, 96),
			"Una hoja en blanco.", 18, Paleta.UI_TEXTO_TENUE)
		_texto(caja.position + Vector2(38, 126),
			"Las runas se aprenden de alguien que las sepa. Preguntá por ahí.",
			14, Paleta.UI_TEXTO_DEBIL)
		return
	var y := caja.position.y + 96.0
	for s in _sabidas:
		var r: Dictionary = s
		var slug := str(r.get("slug", ""))
		_sigilo(Vector2(caja.position.x + 74.0, y + 30.0), 26.0, slug, true, 1.0)
		_texto(Vector2(caja.position.x + 122.0, y + 22.0),
			str(r.get("nombre", slug)), 18, TINTE.get(slug, Paleta.UI_TEXTO))
		_texto(Vector2(caja.position.x + 122.0, y + 44.0),
			str(r.get("descripcion", "")), 13, Paleta.UI_TEXTO_TENUE)
		var de := _de_quien(r)
		_texto(Vector2(caja.position.x + 122.0, y + 64.0),
			("te la enseñó " + de) if de != "" else "la trajiste puesta",
			13, Paleta.UI_ACENTO)
		y += 96.0


func _pintar_hoja_de_mezcla(caja: Rect2, pagina: Dictionary) -> void:
	var secuencia: Array = pagina.get("runas", [])
	# Mientras se escribe, los trazos aparecen de a uno. `p` es cuánto de la
	# página ya está en la hoja.
	var p := clampf(_escribiendose, 0.0, 1.0)

	var cx := caja.position.x + caja.size.x * 0.5
	var y := caja.position.y + 168.0
	var paso := 108.0
	var total := float(secuencia.size()) * paso
	var x := cx - total * 0.5 + paso * 0.5
	for i in secuencia.size():
		var slug := str(secuencia[i])
		# Cada sigilo entra en su turno, en orden: se ve escribir la secuencia.
		var mio := clampf((p * float(secuencia.size()) - float(i)), 0.0, 1.0)
		if mio <= 0.0:
			break
		_sigilo(Vector2(x, y), 38.0, slug, true, mio)
		_centrado(Vector2(x, y + 60.0), str(i + 1), 12, Paleta.UI_TEXTO_DEBIL)
		if i < secuencia.size() - 1:
			_texto(Vector2(x + paso * 0.5 - 5.0, y + 6.0), "›", 22,
				Color(Paleta.UI_TEXTO_DEBIL, mio))
		x += paso

	if p >= 0.72:
		var partes := _frase(secuencia)
		var ancho := 0.0
		for q in partes:
			ancho += _fuente.get_string_size(str((q as Dictionary)["texto"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var tx := cx - ancho * 0.5
		for q in partes:
			var dd: Dictionary = q
			var t := str(dd["texto"])
			_texto(Vector2(tx, y + 132.0), t, 26,
				Color(TINTE.get(str(dd["slug"]), Paleta.UI_TEXTO), (p - 0.72) / 0.28))
			tx += _fuente.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x

	if p >= 0.98:
		var veces := int(pagina.get("veces", 1))
		_centrado(Vector2(cx, y + 176.0),
			"te salió una vez" if veces <= 1 else "te salió %d veces" % veces,
			14, Paleta.UI_TEXTO_TENUE)
		_centrado(Vector2(cx, y + 200.0),
			"la primera, el día %d del valle" % int(pagina.get("descubierta_tick", 0)),
			13, Paleta.UI_TEXTO_DEBIL)
	elif p > 0.0:
		_centrado(Vector2(cx, y + 176.0), "se está escribiendo…", 14,
			Color(Paleta.UI_ACENTO, 0.8))


# ── piezas de dibujo ──────────────────────────────────────────

func _sigilo(centro: Vector2, radio: float, slug: String, encendido: bool,
		progreso: float, tono := Color(0, 0, 0, 0)) -> void:
	var trazos: Array = TRAZOS.get(slug, [])
	var c: Color = TINTE.get(slug, Paleta.UI_TEXTO)
	# Apagado no es invisible: es el mismo dibujo sin luz. Eso es lo que hace
	# que se pueda contar "quedan dos" de un vistazo.
	var col := c if encendido else APAGADO
	if tono.a > 0.0:
		col = tono
	col.a *= clampf(progreso, 0.0, 1.0)
	var grosor := maxf(1.6, radio * 0.11)
	for t in trazos:
		var pts := PackedVector2Array()
		for v: Vector2 in t:
			pts.append(centro + v * radio * 0.86)
		_lienzo.draw_polyline(pts, col, grosor, true)


## El frasco de raíz. Se dibuja y no se escribe porque la cuarta ranura ES el
## frasco: el objeto que otro fabricó, ocupando el lugar de la runa que no te
## entraba.
func _frasquito(centro: Vector2, radio: float) -> void:
	var c := Color(Paleta.UI_ACENTO, 0.95)
	var cuerpo := PackedVector2Array([
		centro + Vector2(-0.22, -1.0) * radio,
		centro + Vector2(-0.22, -0.45) * radio,
		centro + Vector2(-0.62, 0.25) * radio,
		centro + Vector2(-0.5, 0.95) * radio,
		centro + Vector2(0.5, 0.95) * radio,
		centro + Vector2(0.62, 0.25) * radio,
		centro + Vector2(0.22, -0.45) * radio,
		centro + Vector2(0.22, -1.0) * radio,
		centro + Vector2(-0.22, -1.0) * radio,
	])
	_lienzo.draw_polyline(cuerpo, c, maxf(1.6, radio * 0.1), true)
	_lienzo.draw_line(centro + Vector2(-0.55, 0.42) * radio,
		centro + Vector2(0.57, 0.42) * radio, Color(c, 0.55), 1.5, true)


func _panel(caja: Rect2) -> void:
	_lienzo.draw_rect(Rect2(Vector2.ZERO, _lienzo.size), Color(0.0, 0.0, 0.0, 0.42), true)
	_lienzo.draw_rect(caja, Paleta.UI_PANEL, true)
	_lienzo.draw_rect(caja, Color(Paleta.UI_ACENTO, 0.35), false, 1.5)


func _cruz(r: Rect2) -> void:
	var c := r.position + r.size * 0.5
	var k := r.size.x * 0.26
	_lienzo.draw_line(c + Vector2(-k, -k), c + Vector2(k, k), Paleta.UI_TEXTO_DEBIL, 1.5, true)
	_lienzo.draw_line(c + Vector2(k, -k), c + Vector2(-k, k), Paleta.UI_TEXTO_DEBIL, 1.5, true)


func _flecha(r: Rect2, hacia: int, vale: bool) -> void:
	var c := r.position + r.size * 0.5
	var col := Color(Paleta.UI_TEXTO if vale else Paleta.UI_TEXTO_DEBIL, 0.9 if vale else 0.35)
	# La punta va del lado al que se pasa la hoja. Estaba al revés —las alas del
	# lado de `hacia`— y el libro mostraba "›" en el botón de volver atrás.
	var k := 8.0
	_lienzo.draw_polyline(PackedVector2Array([
		c + Vector2(-k * hacia, -k), c + Vector2(k * hacia * 0.4, 0.0),
		c + Vector2(-k * hacia, k),
	]), col, 2.0, true)


func _texto(pos: Vector2, s: String, tam: int, color: Color) -> void:
	if s == "":
		return
	# Contorno, igual que el HUD de al lado: sin él, texto claro sobre pasto
	# claro no se lee, y a esta cámara la mitad de la pantalla es pasto.
	_lienzo.draw_string_outline(_fuente, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam,
		5, Color(Paleta.CARTEL_BORDE, color.a * 0.9))
	_lienzo.draw_string(_fuente, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


func _centrado(pos: Vector2, s: String, tam: int, color: Color) -> void:
	if s == "":
		return
	var a := _fuente.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	_texto(pos - Vector2(a * 0.5, 0.0), s, tam, color)


# ─────────────────────────────────────────────────────────────
# Los sigilos encima del personaje
# ─────────────────────────────────────────────────────────────
#
# Al confirmar el ritual, lo que llevás queda a la vista sobre el cuerpo. Es lo
# que hace visible lo único que el sistema mantenía oculto —qué está cargando
# cada uno— y es lo que convierte "se te nota encima" (§8.6) en algo que se ve
# a 27 metros en vez de en una ficha.

func _rehacer_sigilos_encima() -> void:
	for n in _sobre_el_cuerpo.get_children():
		n.queue_free()
	var n_total := _colgadas.size()
	if n_total == 0:
		return
	# Medido en una captura a la distancia de juego: con la separación de 0,38 y
	# la escala chica, los tres sigilos sumaban cuatro píxeles y no existían.
	var sep := 0.80
	for i in n_total:
		var slug := str(_colgadas[i])
		var mi := MeshInstance3D.new()
		mi.mesh = _malla_sigilo(slug, _quedan.has(slug))
		mi.material_override = _material_sigilo(slug, _quedan.has(slug))
		mi.position = Vector3((float(i) - float(n_total - 1) * 0.5) * sep, 0, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sobre_el_cuerpo.add_child(mi)


## El material de un sigilo colgado.
##
## **No usa `Paleta.chispa()` y eso se midió, no se supuso.** Con esa fábrica los
## tres sigilos no aparecían en pantalla: es alfa transparente con el color
## viajando por COLOR de vértice y `vertex_color_is_srgb`, que es el camino de
## una partícula y no el de una malla. Se probó el mismo mesh con un material
## desnudo y aparecieron en el mismo cuadro.
##
## El color va en `albedo_color` y no en los vértices porque cada runa es su
## propia malla: no hay nada que mezclar dentro de una sola.
func _material_sigilo(slug: String, encendido: bool) -> StandardMaterial3D:
	var col: Color = TINTE.get(slug, Paleta.UI_TEXTO) if encendido else APAGADO
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	# Sin sombra propia: un sigilo es luz, no un cartel de madera colgado.
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# Sin esto se ve la mitad de cada sigilo y nada más. Las cintas de un trazo
	# salen con el giro que les toque según hacia dónde va el segmento, así que
	# a la mitad le queda la cara para atrás; y como el material es billboard,
	# "para atrás" es siempre el lado contrario a la cámara.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if col.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## Un sigilo en 3D. Los trazos se engordan a cintas de triángulos en vez de
## dibujarse con líneas: una línea de Godot mide un píxel a cualquier distancia,
## y a 40 metros de cámara eso es un sigilo que desaparece cuando te alejás.
##
## La escala se ajustó midiendo sobre una captura a la distancia de juego: con
## 0,21 los tres juntos eran una mancha de ocho píxeles.
func _malla_sigilo(slug: String, _encendido: bool) -> ArrayMesh:
	var trazos: Array = SILUETA.get(slug, TRAZOS.get(slug, []))
	var esc := 0.34
	var w := 0.022
	var col := Color.WHITE
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t: Array in trazos:
		for i in range(t.size() - 1):
			var a: Vector2 = t[i]
			var b: Vector2 = t[i + 1]
			# La Y de los trazos apunta para abajo (es dato de dibujo 2D); acá
			# se invierte para que el sigilo no salga cabeza abajo.
			var pa := Vector3(a.x * esc, -a.y * esc, 0.0)
			var pb := Vector3(b.x * esc, -b.y * esc, 0.0)
			var dir := (pb - pa).normalized()
			var lado := Vector3(-dir.y, dir.x, 0.0) * w
			var v := [pa - lado, pb - lado, pb + lado, pa + lado]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for k: int in tri:
					st.set_color(col)
					st.set_normal(Vector3.BACK)
					st.add_vertex(v[k])
	return st.commit()


# ─────────────────────────────────────────────────────────────
# Las marcas: lo que la magia dejó en el valle
# ─────────────────────────────────────────────────────────────
#
# Una marca no es un efecto que se ve un segundo: es una cicatriz con fecha de
# vencimiento que dura días, la ve todo el mundo y **lleva el nombre del que la
# dejó**. Tenés que poder pasar por un claro que sigue ardiendo y que el juego
# te diga quién lo prendió, aunque esa persona ya no esté en el valle ni viva.
#
# Es el mismo principio que `objects.made_by`, y es lo más Frieren que este
# mundo escribe: el que dejó la marca sigue matando cosas después de haberse
# ido.

## `lista` viene de /mundo ya ubicada por `valle.gd`, que es el que sabe dónde
## cae cada lugar: `{id, kind, por, runas, hasta_tick, pos, lugar}`.
func mostrar_marcas(lista: Array) -> void:
	var vistas := {}
	for m in lista:
		var d: Dictionary = m
		var id := str(d.get("id", ""))
		if id == "":
			continue
		vistas[id] = true
		if _marcas.has(id):
			continue
		var nodo := _armar_marca(d)
		if nodo != null:
			add_child(nodo)
			_marcas[id] = nodo
	for id: String in _marcas.keys():
		if vistas.has(id):
			continue
		var vieja: Node3D = _marcas[id]
		_marcas.erase(id)
		if is_instance_valid(vieja):
			vieja.queue_free()


func _armar_marca(d: Dictionary) -> Node3D:
	var tipo := str(d.get("kind", "ardor"))
	var pos: Vector3 = d.get("pos", Vector3.ZERO)
	var por := str(d.get("por", ""))
	var dias := int(d.get("dias", 0))

	var g := Node3D.new()
	g.name = "marca_" + tipo
	g.position = pos

	var arde := tipo == "ardor"
	var tono: Color = Paleta.BRASA if arde else Paleta.VIDA_BIEN
	var emision: Color = Paleta.BRASA_EMISION if arde else Paleta.VIDA_BIEN
	# Un claro que arde, no una región que arde: apretadas se leen como brasas,
	# repartidas sobre diecisiete metros se leen como nada.
	var radio := 5.0 if arde else 6.5

	var p := GPUParticles3D.new()
	p.amount = 150 if arde else 60
	p.lifetime = 2.6 if arde else 6.5
	p.randomness = 1.0
	p.preprocess = 2.0
	p.visibility_aabb = AABB(Vector3(-radio - 3.0, -1.0, -radio - 3.0),
		Vector3((radio + 3.0) * 2.0, 14.0, (radio + 3.0) * 2.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(radio, 0.3, radio)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 22.0 if arde else 45.0
	pm.initial_velocity_min = 0.8 if arde else 0.12
	pm.initial_velocity_max = 2.4 if arde else 0.5
	pm.gravity = Vector3(0, 0.9 if arde else 0.05, 0)
	pm.damping_min = 0.4
	pm.damping_max = 1.4
	pm.scale_min = 0.5
	pm.scale_max = 1.4 if arde else 1.0
	var gr := Gradient.new()
	# Los offsets se declaran, no se numeran: ya costó una vez que el último
	# punto de la rampa se quedara con el blanco de fábrica y las partículas
	# terminaran blancas y opacas.
	gr.offsets = PackedFloat32Array([0.0, 0.22, 0.72, 1.0])
	gr.colors = PackedColorArray([
		Color(tono, 0.0), tono,
		Color(tono, 0.55) if arde else Color(tono, 0.35),
		Color(tono, 0.0),
	])
	var gt := GradientTexture1D.new()
	gt.gradient = gr
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.34, 0.34) if arde else Vector2(0.26, 0.26)
	q.material = Paleta.chispa(emision, 6.0 if arde else 3.0)
	p.draw_pass_1 = q
	g.add_child(p)

	# La luz. Es lo que hace que la marca se vea de lejos y de noche: un claro
	# que arde tiene que verse ardiendo desde el camino.
	var luz := OmniLight3D.new()
	luz.light_color = tono
	luz.light_energy = 2.6 if arde else 1.1
	luz.omni_range = radio * 2.2
	luz.position = Vector3(0, 1.6 if arde else 2.6, 0)
	luz.shadow_enabled = false
	g.add_child(luz)

	# Y el nombre. Sin esto la marca es un efecto de partículas; con esto es
	# alguien que pasó por acá.
	var l := Label3D.new()
	l.text = _texto_de_marca(arde, por, dias)
	# Más grande que el cartel de una persona (44 a 0,006 en `valle.gd`): un
	# nombre se lee cuando te acercás, y una marca tiene que leerse desde el
	# camino — es lo que hace que pasar por un claro que arde te diga quién lo
	# prendió sin tener que ir hasta ahí.
	l.font_size = 48
	l.pixel_size = 0.016
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(0, 3.1, 0)
	l.modulate = Color(tono if arde else Paleta.UI_TEXTO, 0.95)
	l.outline_size = 14
	l.outline_modulate = Paleta.CARTEL_BORDE
	g.add_child(l)
	return g


func _texto_de_marca(arde: bool, por: String, dias: int) -> String:
	var quien := por if por != "" else "alguien"
	var cabeza := ("sigue ardiendo — lo prendió " if arde else "está en pie — lo dejó ") + quien
	if dias <= 0:
		return cabeza
	return cabeza + "\n" + ("un día más" if dias == 1 else "%d días más" % dias)
