extends Node3D

class_name Fauna

# ===========================================================================
# LOS BICHOS DEL VALLE
#
# Hasta acá el valle no tenía un solo animal. Se llenó de árboles, de humo, de
# luciérnagas y de gente, y seguía habiendo algo que no cerraba: **un valle sin
# un bicho vivo se lee como una maqueta.** Un ciervo parado en el borde del
# bosque hace más por que el lugar exista que veinte árboles más.
#
# QUÉ SIGNIFICA CADA UNO. La regla de la casa es que nada entra por lindo (ver
# `CLAUDE.md`, "todo tiene vida o tiene algún sentido"), así que cada especie
# dice algo del valle y está puesta donde eso se lee:
#
#   · **Vaca, caballo, burro** — al lado de los lugares donde hay gente. Son la
#     prueba de que alguien vive de esto: nadie tiene una vaca de adorno.
#   · **Ciervo y venado** — en el bosque y en el claro, lejos de las casas.
#     Son el otro lado de la misma línea: donde no llega el oficio, empieza lo
#     que estaba antes.
#   · **Lobo y zorro** — pocos, en el borde, nunca adentro de un lugar. No
#     atacan a nadie (eso vive en el servidor y acá sería mentira): lo que
#     hacen es marcar que el bosque tiene dueño y no sos vos.
#
# LO QUE ESTO NO ES, Y NO HAY QUE DEJAR QUE SE VUELVA. **Esto es decoración,
# como el pasto y las luciérnagas.** No hay IA, no hay combate, no hay muerte,
# no hay nada que se pueda cazar. Si algún día un bicho de acá tiene que poder
# morirse, el que decide eso es el servidor y el bicho pasa a ser una amenaza de
# la tabla `threats`, como Kerrak. Un lobo que se muere sólo en tu máquina es
# exactamente el error que `CLAUDE.md` cuenta en el invariante.
#
# DE DÓNDE SALEN. Quaternius, CC0 (ver `assets/PROCEDENCIA.md`). Es el segundo
# autor del repo y el porqué está escrito en `kit.gd`: **Kenney no tiene
# animales.** Vienen sin textura, con `albedo_color` y nada más, así que pasan
# por la misma aduana de `paleta.gd` que el resto del kit y salen en la misma
# escalera de valores. Rondan los 2.000 triángulos cada uno.
# ===========================================================================

## Las especies. `alzada` es la altura en metros hasta el lomo, y es lo único
## que decide la escala: los `.glb` vienen en unidades de Blender y miden
## cuatro veces de más. Se normaliza contra el AABB de la malla, igual que
## `vegetacion.gd:_normalizada()`.
const ESPECIES := {
	"Cow":    {"alzada": 1.45, "peso": 796},
	"Horse":  {"alzada": 1.65, "peso": 690},
	"Donkey": {"alzada": 1.25, "peso": 662},
	"Deer":   {"alzada": 1.15, "peso": 690},
	"Stag":   {"alzada": 1.40, "peso": 690},
	"Wolf":   {"alzada": 0.85, "peso": 662},
	"Fox":    {"alzada": 0.50, "peso": 662},
}

## Los rebaños: qué especie, cuántos, alrededor de qué lugar y en qué radio.
##
## **Los números son chicos a propósito.** Veintiséis bichos en 34 hectáreas es
## un valle habitado; sesenta es un zoológico, y a la distancia a la que se
## juega la diferencia entre "hay animales" y "hay demasiados" se nota antes
## que cualquier otra cosa. Si alguna vez hay que subirlos, se sube el número
## de rebaños, no el de cabezas por rebaño: tres grupos de cuatro se leen mejor
## que uno de doce.
const REBANOS: Array = [
	# lugar,      especie,  cabezas, radio interior, radio exterior
	["aldea",     "Cow",     4,  14.0, 26.0],
	["aldea",     "Donkey",  2,  10.0, 18.0],
	["fragua",    "Horse",   3,   9.0, 17.0],
	["camino",    "Horse",   2,   8.0, 15.0],
	["camino",    "Cow",     3,  12.0, 24.0],
	["bosque",    "Deer",    4,  16.0, 34.0],
	["bosque",    "Stag",    1,  20.0, 30.0],
	["ruina",     "Deer",    2,  18.0, 32.0],
	["ruina",     "Wolf",    2,  22.0, 34.0],
	["bosque",    "Fox",     2,  24.0, 38.0],
	["bosque",    "Wolf",    1,  30.0, 40.0],
]

## Las poses de quedarse. **Ningún bicho camina**, y no es una limitación del
## pack —trae `Walk` y `Gallop`— sino la misma regla que la gente: se mueven
## dentro de su lugar y ~3/4 del tiempo están quietos. Un animal que camina
## hacia ningún lado en línea recta se lee como bug antes que como vida.
const POSES: Array[String] = ["Idle", "Idle_2", "Eating", "Eating"]

## Hasta dónde se dibujan. La cámara vive entre 40 y 68 m: a 130 un ciervo son
## tres píxeles y su esqueleto sigue costando.
const ALCANCE := 130.0

## Los lugares de respaldo, para poder correr este módulo suelto. Los de verdad
## llegan por `poblar()`. Son los mismos de `vegetacion.gd`.
const LUGARES_DEFECTO := {
	"aldea": Vector3(0, 0, 0),
	"fragua": Vector3(62, 0, -18),
	"bosque": Vector3(-58, 0, -54),
	"ruina": Vector3(-26, 0, -108),
	"camino": Vector3(11, 0, 74),
}

@export var semilla := 20260817

var _alturas: Callable
var _lugares := LUGARES_DEFECTO.duplicate()
var _cabezas := 0
var _triangulos := 0
var _por_especie := {}


## La puerta de entrada, igual que `Vegetacion.poblar()`: `alturas` es la
## función de terreno del valle y `lugares` es su diccionario `LUGARES`.
func poblar(alturas: Callable, lugares: Dictionary = {}) -> void:
	_alturas = alturas
	for slug: String in lugares:
		var def: Variant = lugares[slug]
		if def is Dictionary and (def as Dictionary).has("pos"):
			_lugares[slug] = (def as Dictionary)["pos"]
		elif def is Vector3:
			_lugares[slug] = def

	var rng := RandomNumberGenerator.new()
	rng.seed = semilla + 7717

	for r: Array in REBANOS:
		var slug: String = r[0]
		if not _lugares.has(slug):
			continue
		_rebano(_lugares[slug], r[1], r[2], r[3], r[4], rng)


## Un grupo de la misma especie repartido en un anillo alrededor de un lugar.
##
## El anillo —y no un círculo lleno— es lo que los mantiene fuera de las casas
## sin tener que saber dónde están las casas: `radio_min` es más grande que
## cualquier planta de lugar.
func _rebano(centro: Vector3, especie: String, cabezas: int,
		radio_min: float, radio_max: float, rng: RandomNumberGenerator) -> void:
	var base := Kit.escena("quaternius/animales/" + especie, Paleta.SATURACION_GENTE)
	if base == null:
		return
	base.queue_free()

	# El primero del grupo elige el rumbo; los demás se le parecen. Un rebaño
	# mirando todo para el mismo lado se lee como rebaño; uno con siete rumbos
	# al azar se lee como siete bichos sueltos que se cruzaron.
	var rumbo := rng.randf() * TAU
	var puesto := 0
	var intentos := 0

	while puesto < cabezas and intentos < cabezas * 12:
		intentos += 1
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * (radio_max - radio_min) + radio_min
		var p := Vector3(centro.x + cos(a) * r, 0.0, centro.z + sin(a) * r)
		var y := _altura(p)
		# Nada de bichos flotando sobre el río ni trepados a la cordillera.
		if y < -0.6 or Vector2(p.x, p.z).length() > 168.0:
			continue
		p.y = y
		if _poner(especie, p, rumbo + rng.randf_range(-0.9, 0.9), rng):
			puesto += 1


## Un bicho, ya colocado, escalado y con su pose andando.
func _poner(especie: String, pos: Vector3, giro: float,
		rng: RandomNumberGenerator) -> bool:
	var n := Kit.escena("quaternius/animales/" + especie, Paleta.SATURACION_GENTE)
	if n == null:
		return false

	n.position = pos
	n.rotation.y = giro
	n.scale = Vector3.ONE * _escala(n, especie)
	add_child(n)

	# El pelaje de cada cabeza, un poco más claro o más oscuro que el de al
	# lado. **Es lo único que separa un rebaño de cuatro copias del mismo
	# archivo**, y a cuarenta metros la copia se nota antes que cualquier otra
	# cosa: es el mismo truco que usa `vegetacion.gd` con las copas.
	#
	# Se mueve el VALOR y nada más. El matiz sale de la paleta y no se toca:
	# una vaca violeta sería variedad, pero de la que rompe la escalera.
	var pelo := rng.randf_range(0.86, 1.16)
	for m in _mallas(n):
		m.visibility_range_end = ALCANCE
		m.visibility_range_end_margin = 12.0
		_triangulos += Kit.triangulos(m.mesh)
		Kit.tinte(m, Color(pelo, pelo, pelo))

	var ap := _reproductor(n)
	if ap != null:
		var pose: String = POSES[rng.randi() % POSES.size()]
		if ap.has_animation(pose):
			ap.play(pose)
			# El desfasaje es lo que evita el peor efecto posible: cuatro vacas
			# masticando en el mismo cuadro exacto, que se lee como copia y
			# pega y arruina las cuatro de una.
			ap.advance(rng.randf() * ap.get_animation(pose).length)
			ap.speed_scale = rng.randf_range(0.72, 1.05)

	_cabezas += 1
	_por_especie[especie] = int(_por_especie.get(especie, 0)) + 1
	return true


## La escala que lleva la malla a la alzada de la especie. El AABB de una malla
## con esqueleto es el de la pose de reposo, que para estos modelos es el bicho
## parado: sirve.
func _escala(n: Node3D, especie: String) -> float:
	var alto := 0.0
	for m in _mallas(n):
		if m.mesh != null:
			alto = maxf(alto, m.mesh.get_aabb().size.y)
	if alto <= 0.01:
		return 1.0
	return float(ESPECIES[especie]["alzada"]) / alto


func _mallas(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for h in n.get_children():
		out.append_array(_mallas(h))
	return out


func _reproductor(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for h in n.get_children():
		var a := _reproductor(h)
		if a != null:
			return a
	return null


func _altura(p: Vector3) -> float:
	if _alturas.is_valid():
		return _alturas.call(p.x, p.z)
	return 0.0


## Para el censo. Devuelve `[cabezas, triángulos, {especie: cuántos}]`.
func censo() -> Array:
	return [_cabezas, _triangulos, _por_especie]
