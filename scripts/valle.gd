## El valle. Construye el mundo por código y lo puebla con lo que dice el
## servidor — la misma API que usa la web.
##
## Todo procedural a propósito: sin assets todavía, el look sale de la
## iluminación (ver ambiente.gd) y de la geometría teniendo volumen y
## variación. Un plano liso con cubos es "3D choto"; terreno con relieve,
## sombras largas y niebla volumétrica no.
extends Node3D

## Los lugares del valle, y cuánto hay entre uno y otro.
##
## Estaban todos encima: de la aldea a la fragua había veinte metros y el valle
## entero se veía de un vistazo. Un mundo así no tiene lugares, tiene zonas de
## un mapa. **Si viajar no cuesta nada, un pueblo deja de ser un pueblo.**
##
## Ahora hay minuto y pico de caminata entre puntas. Es a propósito: que la
## fragua quede lejos es lo que hace que ir hasta ahí sea una decisión, que el
## Sotobosque dé cosa de noche, y que valga tener una casa cerca de algo.
##
## El `color` de cada lugar sale de `paleta.gd` y es **el peldaño de valor con
## el que ese lugar se separa del suelo**, no el material del que está hecho:
## la aldea es una mancha clara (V6) y el Sotobosque una oscura (V2) contra un
## suelo V4. Hoy sólo lo consume el camino —los otros cuatro lo tienen como
## identidad declarada y nadie lo lee todavía—, y así y todo tiene que salir de
## la paleta: el día que alguien lo use, ya está en el escalón correcto.
const LUGARES := {
	"aldea":  {"pos": Vector3(0, 0, 0),      "color": Paleta.MURO_ALDEA,  "casas": 7, "nombre": "Vado Bajo"},
	"fragua": {"pos": Vector3(62, 0, -18),   "color": Paleta.MURO_FRAGUA, "casas": 2, "nombre": "La Fragua de Ilde"},
	"bosque": {"pos": Vector3(-58, 0, -54),  "color": Paleta.COPA,        "casas": 0, "nombre": "El Sotobosque"},
	"ruina":  {"pos": Vector3(-26, 0, -108), "color": Paleta.MURO_RUINA,  "casas": 3, "nombre": "La Casa Quemada"},
	"camino": {"pos": Vector3(11, 0, 74),    "color": Paleta.LOSA_CAMINO, "casas": 0, "nombre": "El Camino del Norte"},
}

## Lo más común que se junta en cada lugar. Espeja la tabla del servidor —
## sólo para poder NOMBRARLO en la pista: "[B] buscar" no significa nada,
## "[B] juntar raíz del Sotobosque" sí. Lo que salga de verdad lo decide el
## servidor, que es el que tiene los pesos.
const LO_QUE_SE_JUNTA := {
	"bosque": "raíz del Sotobosque",
	"ruina": "carbón",
	"camino": "piedra de afilar",
	"aldea": "caña de la orilla",
	"fragua": "",
}

const RADIO_VALLE := 165.0

## El color de la gente de carne y hueso: vos y los otros jugadores. Estaba
## suelto como literal en el cuerpo del jugador; ahora tiene nombre porque lo
## comparten dos lados y esa coincidencia **es la señal**, no una casualidad.
## Un habitante del valle es gris (ver los NPC más abajo); alguien que está del
## otro lado de una pantalla tiene tu color y tu altura.
##
## Es `Paleta.JADE`, la excepción 2 de la paleta: el único color frío y saturado
## de un valle cálido y apagado, y le pertenece a la gente de carne y hueso. No
## se lo presta a nada más.
const COLOR_JUGADOR := Paleta.JADE
const ALTURA_JUGADOR := 1.85

## Distancias para decidir en qué lugar estás. SALIR es más grande que ENTRAR
## a propósito — ver la histéresis en _avisar_donde_estoy().
## Cuántos segundos pasan antes de que la misma persona te vuelva a saludar.
## Noventa: lo suficiente para cruzar la aldea entera sin que nadie te repita.
const ESPERA_SALUDO := 90.0

const ENTRAR := 30.0
const SALIR := 44.0

var api: Api
var jugador: Jugador
var interfaz: CanvasLayer

var _ruido := FastNoiseLite.new()
var _npcs: Dictionary = {}
## Dónde quedó cada casa de cada lugar, en coordenadas del mundo: slug ->
## Array[Vector2]. Lo llena `_armar_lugar()` mientras las construye, y lo lee la
## ronda de la gente para no meterse adentro de ninguna. Se anota acá en vez de
## recorrer el árbol buscando colisionadores porque el dato ya lo tenemos en la
## mano en el momento exacto en que existe.
var _casas: Dictionary = {}
## A qué distancia del centro se para la gente de cada lugar: slug -> float.
## Ver `_anillo_de()`.
var _anillos: Dictionary = {}
## La ronda de cada persona, cacheada por nombre. Se calcula una sola vez: sale
## del hash del nombre, así que recalcularla daría siempre lo mismo.
var _rondas: Dictionary = {}
## El reloj con el que anda la gente. Ver `_reloj_del_valle()`.
var _reloj_ronda := -1.0
## Los otros jugadores que están en el valle ahora mismo: nombre -> Node3D.
## Va aparte de `_npcs` a propósito — con un NPC se habla (E manda /hablar) y
## con una persona todavía no hay nada que el servidor sepa resolver. Meterlos
## en la misma bolsa te dejaría apretando E contra alguien y mandando un
## /hablar que vuelve vacío.
var _jugadores: Dictionary = {}
## Cómo te llama el servidor a vos. Sólo para no dibujarte dos veces.
var _mi_nombre := ""
var _monstruos: Array[Monstruo] = []
var ciclo: Ciclo
var vegetacion: Vegetacion
## Los hitos: la Puerta del Norte, la lastra caída y el mojón del camino. Es lo
## único del valle que no está a escala de casa, y por eso es lo que le da
## tamaño al resto. Ver `hitos.gd`.
var hitos: Hitos
var sonido: Sonido
var dibujado: Dibujado
var _lugar_actual := ""
var _monstruos_por_id: Dictionary = {}
## Cómo te trata cada uno al pasar. Lo manda el servidor con /mundo.
var _actitudes: Dictionary = {}
var _ya_saludo: Dictionary = {}
var mapa: Mapa
## Lo que hay adentro de las casas. Ver `interiores.gd`: las casas se abren, la
## gente que el servidor manda a dormir a su casa está de verdad adentro, y el
## cuarto en el que estás parado se recorta para que la cámara pueda mirarlo.
var interiores: Interiores
## La cámara del jugador, guardada para no buscarla en cada cuadro. La necesita
## el recorte: qué muro tapa depende de dónde está mirando, no de dónde estás.
var _camara: Camera3D
var _ya_pedimos_cronica := false
## La magia: el ritual de la mañana, el trazo, el grimorio y las marcas que
## quedan en el suelo. Todo el sistema vivía en el servidor y no había forma de
## trazar una runa desde acá.
var runas: Runas
## Nombre -> uuid de cada persona. Hace falta para apuntarle a alguien con un
## hechizo: `/lanzar` acepta el nombre, pero el uuid no se equivoca cuando dos
## personas se llaman parecido.
var _ids_gente: Dictionary = {}

## La vida del jugador NO se decide acá. Esto es el espejo de lo último que
## dijo el servidor, nada más.
##
## Antes había una `vida_jugador` local que los monstruos bajaban en tiempo
## real y que un temporizador de 2,4 segundos reseteaba sola. O sea: vos les
## pegabas en el mundo compartido y ellos te pegaban en tu máquina. Nadie se
## enteraba de que te habían tumbado, no quedaba registrado, y volvías a estar
## entero como si nada. Era el invariante roto justo en el tramo que existe
## para sostenerlo.
var _vida := 100
var _vida_maxima := 100
var _caido := false
## Cuándo volvió la última levantada. Un /mundo pedido ANTES de levantarte
## puede llegar DESPUÉS y todavía verte tirado; sin esta ventana el panel de
## caída reaparece solo dos segundos después de haberte parado.
var _levantado_en := 0


func _ready() -> void:
	_ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ruido.frequency = 0.028
	_ruido.fractal_octaves = 3

	_armar_ambiente()
	_armar_terreno()
	_armar_cordillera()
	_armar_rio()
	# Va ANTES de las casas y en un miembro, no en una variable local: cada casa
	# se registra al construirse, que es el único momento en que su geometría
	# está en la mano sin tener que ir a buscarla al árbol.
	interiores = Interiores.new()
	add_child(interiores)
	for slug: String in LUGARES:
		_armar_lugar(slug, LUGARES[slug])

	# La vegetación de verdad, a la escala del valle. Antes eran 46 árboles
	# apretados en 13 metros de un mapa de 360: el problema nunca fue que
	# faltaran árboles, fue que nunca escalaron cuando el mapa creció 2,7×.
	vegetacion = Vegetacion.new()
	add_child(vegetacion)
	vegetacion.poblar(altura_en, LUGARES)
	# Después de la vegetación y no antes: `Vegetacion` consulta
	# `Hitos.despeje()`, que es estática, así que no hay dependencia de orden —
	# pero plantar la roca después deja el árbol en el orden en que se lee.
	hitos = Hitos.new()
	add_child(hitos)
	hitos.plantar(altura_en)

	Detalles.pasto(self, altura_en, 26000, 130.0)
	Detalles.piedras(self, altura_en, 320, 145.0)
	var bichos: Array[GPUParticles3D] = [
		Detalles.luciernagas(self, Vector3(0, 2.5, 0), 40, 16.0),
		Detalles.luciernagas(self, LUGARES['bosque']['pos'] + Vector3(0, 2.0, 0), 55, 13.0),
		Detalles.luciernagas(self, LUGARES['ruina']['pos'] + Vector3(0, 2.0, 0), 35, 11.0),
	]
	ciclo.bichos_de_luz = bichos

	api = Api.new()
	add_child(api)
	api.mundo_recibido.connect(_al_recibir_mundo)
	api.peleado.connect(_al_resultado_de_pelea)
	api.danio_recibido.connect(_al_resultado_de_danio)
	api.levantado.connect(_al_levantarse)

	jugador = _armar_jugador()
	add_child(jugador)
	jugador.quiere_interactuar.connect(_al_interactuar)
	jugador.quiere_golpear.connect(_al_golpear)


	interfaz = preload("res://escenas/interfaz.tscn").instantiate()
	add_child(interfaz)
	interfaz.conectar_api(api)
	# Va acá y no arriba: la interfaz recién existe en esta línea.
	jugador.tecleando = _jugador_sin_control

	mapa = Mapa.new()
	mapa.lugares = LUGARES
	mapa.jugador = jugador
	interfaz.add_child(mapa)

	# El valle suena. Va acá y no antes porque necesita el ciclo para saber la
	# hora: el lecho de ambiente cambia con el lugar Y con el momento del día.
	#
	# Va al final de `_ready()` a propósito: un error acá no puede llevarse
	# puesto nada de lo de arriba, y en este archivo ya pasó una vez que un
	# error en `_ready()` abortó la función entera y el juego arrancó sin HUD
	# y sin API. Se sintetiza al arrancar —cero bytes en disco y cero en la
	# descarga— y los buses se crean en tiempo de ejecución, así que no hay
	# nada que registrar en `project.godot`.
	#
	# Y va en el miembro `sonido`, no en una variable local: instanciado sin
	# guardar la referencia queda colgado. Estuvo duplicado unas horas —dos
	# lechos sonando juntos y uno sin dueño— porque el cableado se hizo dos
	# veces, desde dos ramas que no se veían entre sí.
	sonido = Sonido.new()
	sonido.ciclo = ciclo
	add_child(sonido)
	sonido.preparar(LUGARES)
	if jugador != null:
		sonido.oyente = jugador

	_refrescar_cada_tanto()
	# El contorno. Va después de la interfaz para quedar debajo de ella en el
	# orden de capas, y encima del mundo.
	dibujado = Dibujado.new()
	var cam := jugador.get_node_or_null("Camara") as Camera3D
	if cam == null:
		for n in jugador.find_children("*", "Camera3D", true, false):
			cam = n as Camera3D
			break
	if cam != null:
		cam.add_child(dibujado)
	else:
		add_child(dibujado)
	# Guardada para el recorte de los interiores: buscarla en cada cuadro sería
	# recorrer el árbol del jugador sesenta veces por segundo para nada.
	_camara = cam

	# La magia. Va al final y en un miembro, nunca en una variable local: es la
	# trampa que ya costó una tarde en este archivo —un módulo instanciado sin
	# guardar la referencia queda colgado— y de paso un error acá no se lleva
	# puesto nada de lo de arriba.
	#
	# Se le pasan cuatro cosas y ninguna es la escena entera: si sabe demasiado
	# de `valle.gd`, el día que cambie el HUD hay que tocar los dos.
	runas = Runas.new()
	runas.api = api
	runas.jugador = jugador
	runas.camara = cam
	# Envueltas en lambdas y no pasadas como `interfaz.avisar` a secas: `interfaz`
	# está tipada como `CanvasLayer` y esos métodos son del script, así que
	# tomarlos como valor se resuelve en tiempo de ejecución igual que las
	# llamadas que ya hay en este archivo.
	runas.escribiendo = func() -> bool: return interfaz.escribiendo()
	runas.avisar = func(t: String) -> void: interfaz.avisar(t)
	runas.blancos = _blancos_de_magia
	add_child(runas)

	_captura_si_corresponde()

	if api.token == "":
		interfaz.pedir_token()
	else:
		api.pedir_mundo()


## Altura del terreno en un punto. Se usa para apoyar todo sobre el relieve.
func altura_en(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var cuenco := -pow(d / RADIO_VALLE, 2.2) * 5.0   # el valle es un cuenco
	return _ruido.get_noise_2d(x, z) * 2.4 + cuenco


func _armar_ambiente() -> void:
	var amb := Ambiente.new()
	amb.set_script(preload("res://scripts/ambiente.gd"))
	add_child(amb)

	# El sol ya no está fijo en el atardecer: lo mueve el reloj del valle. Una
	# hora real es un día del valle, así que en una sesión ves amanecer y
	# anochecer, y los ves a la misma hora que cualquier otro conectado.
	var sol := DirectionalLight3D.new()
	# El valor de arranque, nada más: `ciclo.gd` lo pisa en el primer cuadro con
	# `Paleta.luz_solar()` según la hora que manda el servidor. Va en LUZ_ALBA
	# porque un cuadro de sol cálido bajo es lo menos falso que se puede mostrar
	# antes de saber la hora.
	sol.light_color = Paleta.LUZ_ALBA
	sol.light_energy = 2.0
	sol.shadow_enabled = true
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sol.directional_shadow_max_distance = 260.0
	sol.directional_shadow_blend_splits = true
	sol.light_angular_distance = 1.2   # sombras que se ablandan con la distancia
	sol.shadow_blur = 1.3
	sol.add_to_group("sol")   # rendimiento.gd lo busca por acá
	add_child(sol)

	# Relleno frío desde el cielo, para que las sombras no sean negras.
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-58, -40, 0)
	relleno.light_color = Paleta.LUZ_CIELO
	relleno.light_energy = 0.14
	relleno.shadow_enabled = false
	add_child(relleno)

	ciclo = Ciclo.new()
	ciclo.set_script(preload("res://scripts/ciclo.gd"))
	ciclo.sol = sol
	ciclo.relleno = relleno
	ciclo.entorno = amb.environment
	add_child(ciclo)


func _armar_terreno() -> void:
	# Se arma vértice por vértice con SurfaceTool. Intenté la vía corta
	# (crear un PlaneMesh y deformarlo con commit_to_arrays) y los colores de
	# vértice no entraban: el terreno salía color arena. Confiable le gana a
	# ingenioso.
	var lado := 360.0
	# 120 y no 180: el ruido del terreno tiene longitud de onda de ~36 m, así
	# que a 3 m de paso ya está sobremuestreado doce veces. Bajar de 180 a 120
	# saca 36.000 triángulos de la malla Y otros tantos del árbol de colisión,
	# que sale de la misma malla. No bajar de 120: a 4 m aliasean las manchas
	# de color, que tienen longitud de onda de ~13 m.
	var pasos := 120
	var paso := lado / pasos

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for iz in pasos:
		for ix in pasos:
			var x0 := -lado / 2.0 + ix * paso
			var z0 := -lado / 2.0 + iz * paso
			var esquinas := [
				Vector2(x0, z0), Vector2(x0 + paso, z0),
				Vector2(x0 + paso, z0 + paso), Vector2(x0, z0 + paso),
			]
			var p: Array[Vector3] = []
			for e: Vector2 in esquinas:
				p.append(Vector3(e.x, altura_en(e.x, e.y), e.y))
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				var n := (p[tri[1]] - p[tri[0]]).cross(p[tri[2]] - p[tri[0]]).normalized()
				if n.y < 0.0:
					n = -n
				for k: int in tri:
					st.set_color(_color_terreno(p[k], n))
					st.add_vertex(p[k])

	# EL TINTE DEL TERRENO IBA EN Color(0.42, 0.46, 0.30) Y ESO ERA UN BUG, NO
	# UNA DECISIÓN. Con `vertex_color_use_as_albedo` prendido Godot **multiplica**
	# el albedo por el color de vértice, así que ese tinte le comía dos tercios
	# del valor a todo lo que calcula `_color_terreno()` y le metía verde encima:
	# el pasto salía en v0.33 con saturación 0.60 en vez de los v0.30 s0.34 que
	# dice el código, y los cuatro colores del suelo terminaban apretados entre
	# v0.30 y v0.36 — un solo peldaño, o sea el 40% de la pantalla convertido en
	# una papilla gris. `Paleta.terreno()` va casi blanco a propósito: acá el
	# albedo no es un color, es un multiplicador que tiene que dejar pasar el de
	# los vértices.
	var mat := Paleta.terreno()
	st.generate_normals()
	st.set_material(mat)

	var malla := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	add_child(mi)

	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	forma.shape = malla.create_trimesh_shape()
	cuerpo.add_child(forma)
	add_child(cuerpo)


## El color del suelo sale de la altura y la pendiente. Sin texturas, esta
## variación es lo único que separa un prado de una alfombra de plástico.
##
## **Los cuatro salen de la paleta y están en cuatro peldaños seguidos** —pasto
## V3, tierra V4, pasto seco V5, roca V6, contra un suelo que promedia V4—, y
## ésa es la mitad del arreglo de "parece Playmobil". Antes los cuatro vivían
## entre v0.72 y v0.86: en blanco y negro el suelo entero era una sola mancha y
## toda la diferencia estaba en el matiz, que a 27 metros no existe. Si alguna
## vez hay que retocar uno, se retoca en `paleta.gd` y se elige primero el
## escalón.
func _color_terreno(p: Vector3, n: Vector3) -> Color:
	var pasto := Paleta.PASTO
	var pasto_seco := Paleta.PASTO_SECO
	var tierra := Paleta.TIERRA
	var roca := Paleta.ROCA

	var t := clampf((p.y + 4.5) / 6.5, 0.0, 1.0)
	var c := pasto.lerp(pasto_seco, t)

	# Las pendientes fuertes muestran tierra y piedra, como en la realidad.
	var pendiente := 1.0 - clampf(n.dot(Vector3.UP), 0.0, 1.0)
	c = c.lerp(tierra, clampf(pendiente * 3.4, 0.0, 0.85))
	if pendiente > 0.34:
		c = c.lerp(roca, clampf((pendiente - 0.34) * 3.0, 0.0, 0.6))

	# Manchas grandes para romper la uniformidad.
	var v := _ruido.get_noise_2d(p.x * 2.7, p.z * 2.7) * 0.5 + 0.5
	return c.lerp(c.darkened(0.30), v * 0.6)


func _armar_rio() -> void:
	var agua := PlaneMesh.new()
	agua.size = Vector2(430, 15.0)
	# Un río se lee porque es OSCURO, no porque es azul: `Paleta.AGUA` está en V2
	# contra un suelo V4, y una cinta oscura cruzando el valle es la línea más
	# fuerte del encuadre. La saturación baja de 0.58 a 0.34 — el azul de antes
	# competía con el jade del jugador, que es el único frío saturado del juego.
	var mat := Paleta.agua()
	agua.material = mat

	var mi := MeshInstance3D.new()
	mi.mesh = agua
	mi.position = Vector3(0, -1.7, 26)
	mi.rotation_degrees = Vector3(0, 9, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _armar_lugar(slug: String, def: Dictionary) -> void:
	var g := Node3D.new()
	var base: Vector3 = def["pos"]
	base.y = altura_en(base.x, base.z)
	g.position = base
	g.name = slug
	add_child(g)

	var color: Color = def["color"]

	# El Sotobosque no planta nada acá: los árboles del valle entero los pone
	# `vegetacion.gd`, que los reparte por densidad y no por lugar. Hasta hace
	# un rato esto llamaba a `_armar_bosque()` y quedaban los dos bosques
	# encimados en el mismo sitio.
	if slug == "bosque":
		return
	if slug == "camino":
		_armar_camino(g, color)
		return

	# LAS CASAS SON DEL KIT, NO CAJAS. Ver `Detalles.casa()`.
	#
	# El sorteo va con un RNG propio sembrado con el slug del lugar, y eso
	# arregla de paso algo que estaba anotado como defecto en
	# `_afuera_de_casas()`: las casas se sorteaban con el `randf()` global, así
	# que salían distintas en cada máquina y el empujón contra las paredes daba
	# distinto para cada jugador. Ahora Vado Bajo es el mismo Vado Bajo en la
	# pantalla de todos, que es el mismo criterio que ya cumplían las figuras.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(slug)

	var n: int = def["casas"]
	var huellas: Array[Vector3] = []
	_casas[slug] = huellas
	for i in n:
		# Dónde se apoya de verdad. Antes era el punto del círculo y la altura
		# del centro de la casa; ahora es el rellano más parejo cerca de ahí, y
		# la altura es la del punto MÁS ALTO de la planta. Ver `_sitio_de_casa()`.
		var sitio := _sitio_de_casa(base, i, n, huellas)
		var pos: Vector3 = sitio["pos"]
		var giro: float = sitio["giro"]

		# La familia de muro es del LUGAR, no de la casa: las siete de Vado
		# Bajo son de tabla y las dos de la fragua de piedra. Un caserío donde
		# cada casa es de otro material se lee como muestrario.
		var quemada := slug == "ruina"
		var casa := Detalles.casa(g, sitio, rng, slug == "fragua", quemada)
		var alero: float = casa["alero"]

		# Para la ronda de la gente: dónde hay una casa y cómo está girada. Se
		# anota acá, que es el único momento en que el dato existe sin tener que
		# ir a buscarlo al árbol.
		huellas.append(Vector3(base.x + pos.x, base.z + pos.z, giro))

		# LA COLISIÓN YA NO ES UNA CAJA MACIZA, y ése era el bug entero: la
		# puerta estaba dibujada y una pared invisible pasaba por delante. Ahora
		# la pone `Detalles.casa()`, tabique por tabique y con el hueco de la
		# puerta abierto. Acá no queda nada que hacer.
		var clave := "%s/%d" % [slug, i]
		interiores.amueblar(clave, casa, quemada, rng)

		if not quemada:
			interiores.anotar_chimenea(clave, Detalles.chimenea(g,
				Vector3(pos.x + 0.85, pos.y + alero + 1.25, pos.z - 0.65), 2.7))

		_enseres(g, base, pos, giro, slug, rng)

	_anillos[slug] = _anillo_de(Vector2(base.x, base.z), huellas)

	if slug == "fragua":
		_armar_fuego(g)
	if slug == "aldea":
		_armar_faroles(g)


# ---------------------------------------------------------------------------
# DÓNDE SE APOYA UNA CASA
# ---------------------------------------------------------------------------
#
# Esto no existía y hacía falta desde el día que la casa creció a 5,4 m de
# planta. **Medido sobre las doce casas del valle**: bajo la planta de una casa
# el terreno sube y baja hasta 1,53 m, y la casa se apoyaba en la altura de su
# CENTRO. O sea que a media docena de casas les entraba medio metro de loma
# adentro, y a las otras les quedaba medio metro de aire bajo la pared. Con la
# casa cerrada casi no se veía; con la puerta abierta es un cuarto con una
# colina adentro, y eso es peor que no tener interiores.
#
# Se ataca por los tres lados, y el orden importa porque cada paso le deja
# menos trabajo al siguiente:
#
#   1. **Buscarle el rellano.** El ángulo y el radio se dejan mover un poco y
#      se elige el punto más parejo. Sale gratis y es lo que más rinde: el
#      desnivel peor pasa de 1,53 a 1,03 m.
#   2. **Apoyarla en el punto más alto** y tapar lo que quede en el aire con el
#      zócalo de piedra de `Detalles`.
#   3. **Elegir la puerta por el lado del acceso más bajo.** Las dos celdas del
#      frente sirven igual, así que esto es gratis y le saca hasta medio metro
#      al escalón: el umbral peor queda en 0,94 m.
#
# El costo es de arranque y se midió: 35 candidatos × 49 muestras × 12 casas son
# unas 20.000 evaluaciones de ruido, que es menos de lo que cuesta una baldosa
# de pasto.

## Cuánto se le deja mover a una casa la posición que le tocó, buscando rellano.
## Media casa de radio y un cuarto de radián de ángulo: alcanza para esquivar
## una loma y no alcanza para deshacer el círculo alrededor de la plaza.
const SITIO_ANGULO := 0.44
const SITIO_RADIO := 5.0
const SITIO_ANGULOS := 7
const SITIO_RADIOS := 5
## Con cuántos puntos se mide la planta. 7×7 sobre 5,4 m son muestras cada 90
## cm, y el ruido del terreno tiene 36 m de longitud de onda: sobra.
const SITIO_MUESTRAS := 7

## Cuánto tiene que haber entre los centros de dos casas.
##
## **Esto no estaba y la búsqueda del rellano metió dos casas de Vado Bajo a 6,3
## m una de otra**, o sea con las plantas de 5,4 m superpuestas: se entraba a una
## y el juego decía que estabas en la otra. Se descubrió con el andamio que
## camina hasta la puerta —dos de nueve casas no se podían entrar— y no mirando,
## porque desde arriba dos casas encimadas parecen una casa grande.
##
## 5,4 de planta más 2,6 de calle. Nunca es una prohibición sino una multa muy
## cara: un candidato siempre tiene que quedar, aunque el terreno sea horrible.
const SITIO_SEPARACION := 9.0
const SITIO_MULTA := 6.0


## `puestas` son las casas que ya se colocaron en este lugar, como
## `Vector3(x, z, giro)` en coordenadas del mundo. Ver `SITIO_SEPARACION`.
func _sitio_de_casa(base: Vector3, i: int, n: int, puestas: Array[Vector3]) -> Dictionary:
	var a0 := TAU * i / float(n) + 0.4
	# El radio tiene que crecer con la cantidad, o las casas se encaraman unas
	# sobre otras — que es exactamente lo que pasaba con siete en un círculo de
	# 5 metros. La cuerda entre dos vecinas tiene que superar los 5,4 m de la
	# planta con aire.
	var r0: float = maxf(8.0, 4.4 * n / TAU + 7.0)
	var mejor := INF
	var salida := {}

	for ka in SITIO_ANGULOS:
		for kr in SITIO_RADIOS:
			# Miran hacia afuera del círculo, como un caserío alrededor de una
			# plaza: el giro ES el ángulo, sin azar encima. Antes llevaba un
			# ±0,2 sorteado y las casas quedaban cruzadas entre sí; ahora la
			# variedad la da la búsqueda del rellano, que además significa algo.
			var a := a0 + (ka / float(SITIO_ANGULOS - 1) - 0.5) * SITIO_ANGULO
			var r := r0 + (kr / float(SITIO_RADIOS - 1) - 0.5) * SITIO_RADIO
			var px := base.x + cos(a) * r
			var pz := base.z + sin(a) * r

			var lo := INF
			var hi := -INF
			for u in SITIO_MUESTRAS:
				for v in SITIO_MUESTRAS:
					var d := Vector3(
						(u / float(SITIO_MUESTRAS - 1) - 0.5) * Detalles.CASA_LADO, 0.0,
						(v / float(SITIO_MUESTRAS - 1) - 0.5) * Detalles.CASA_LADO
					).rotated(Vector3.UP, a)
					var h := altura_en(px + d.x, pz + d.z)
					lo = minf(lo, h)
					hi = maxf(hi, h)

			# Cuál de las dos celdas del frente tiene el acceso más bajo. Se
			# mide dos metros afuera de la pared, que es donde de verdad pisás
			# antes de subir.
			var lado := 0
			var umbral := INF
			for k in Detalles.CASA_FRENTE.size():
				var celda: Vector2 = Detalles.CASA_CARAS[Detalles.CASA_FRENTE[k]][0]
				var d2 := Vector3(celda.x * Detalles.CASA_CELDA, 0.0,
					Detalles.CASA_LADO / 2.0 + 2.0).rotated(Vector3.UP, a)
				var u2 := hi - altura_en(px + d2.x, pz + d2.z)
				if u2 < umbral:
					umbral = u2
					lado = k

			var costo := (hi - lo) + maxf(0.0, umbral)
			for otra: Vector3 in puestas:
				var sep := Vector2(px, pz).distance_to(Vector2(otra.x, otra.y))
				costo += maxf(0.0, SITIO_SEPARACION - sep) * SITIO_MULTA
			if costo < mejor:
				mejor = costo
				salida = {
					"pos": Vector3(px - base.x, hi - base.y, pz - base.z),
					"giro": a,
					"zocalo": hi - lo,
					"umbral": maxf(0.0, umbral),
					"puerta": lado,
				}
	return salida


# ---------------------------------------------------------------------------
# LOS ENSERES: lo que hace que un lugar parezca habitado
# ---------------------------------------------------------------------------
#
# Una casa vacía es arquitectura; una casa con un barril al lado y la leña
# apilada contra la pared es la casa de alguien. Es lo mismo que ya hacían las
# ventanas encendidas y el humo, pero de día.
#
# **Van pegados a las casas, no repartidos por la plaza.** Un barril en el
# medio del descampado se lee como un objeto que quedó ahí; el mismo barril
# contra una pared se lee como el barril de esa casa. Y de paso no le estorba
# la ronda a la gente, que camina por el medio.

## Qué tiene cada lugar al lado de sus casas. Sale de qué se hace ahí: en la
## fragua hay piedra, tablones y un yunque; en Vado Bajo, leña, agua y grano.
const ENSERES := {
	"aldea": ["utiles/barrel", "utiles/box", "utiles/box-large",
		"utiles/bucket", "utiles/chest", "naturaleza/log_stack",
		"naturaleza/pot_large", "utiles/resource-wood"],
	"fragua": ["utiles/barrel", "utiles/box", "utiles/resource-stone",
		"utiles/resource-planks", "naturaleza/log_stack", "utiles/bucket"],
	# La Casa Quemada tiene dos cosas y están volcadas. Un páramo con la misma
	# cantidad de trastos que la aldea deja de ser un páramo.
	"ruina": ["utiles/box", "utiles/barrel"],
}

## Los cuatro lugares donde puede haber algo, en el marco de la casa.
##
## **Estaban a 1,7 m del centro y eso era estar ADENTRO.** El número venía de
## cuando la celda medía 1,3 y la casa 2,6 de lado; con la celda en 2,7 la casa
## mide 5,4 y su zócalo llega a 2,82, así que los barriles del valle entero
## estaban plantados dentro de las paredes, hundidos en el terreno. No se veía
## porque no se podía entrar. Ahora sí, y por eso salen a 3,3 — al pie de la
## pared, del lado de afuera, que es donde el comentario decía que estaban.
##
## Ninguno da al frente: la cara +Z es la de la puerta y sus escalones, y un
## barril en la escalera es un barril en la escalera.
const ENSERES_SITIOS: Array[Vector3] = [
	Vector3( 3.30, 0.0,  0.80),
	Vector3(-3.30, 0.0, -0.80),
	Vector3( 3.20, 0.0, -1.90),
	Vector3(-2.20, 0.0, -3.30),
]

## Las tres escalas del kit. Los packs de Kenney NO comparten unidad: la celda
## del Fantasy Town Kit es 1 unidad (y en el valle vale `CASA_CELDA` metros),
## pero un barril del Survival Kit mide 0,24 de ancho y una cerca del Nature
## Kit mide 1,0. Sin esto los barriles salen del tamaño de un dedal — que es
## exactamente el tipo de error que hace que un juego con buenos assets se vea
## mal armado.
const ESCALA_KIT := {"pueblo": 1.3, "utiles": 2.5, "naturaleza": 2.0}


func _enseres(g: Node3D, base: Vector3, local: Vector3, giro: float,
		slug: String, rng: RandomNumberGenerator) -> void:
	var lista: Array = ENSERES.get(slug, [])
	if lista.is_empty():
		return

	# Una o dos cosas por casa, y a veces ninguna. Que todas las casas tengan
	# la misma cantidad de trastos se nota tanto como que no tengan ninguno.
	var cuantos := rng.randi_range(0, 2 if slug == "ruina" else 3)
	var sitios := ENSERES_SITIOS.duplicate()
	for k in cuantos:
		if sitios.is_empty():
			break
		var sitio: Vector3 = sitios.pop_at(rng.randi() % sitios.size())
		var ruta: String = lista[rng.randi() % lista.size()]
		# Del marco de la casa al del lugar: girar y correr al pie de la casa.
		var d := Vector3(sitio.x, 0.0, sitio.z).rotated(Vector3.UP, giro)
		var px := local.x + d.x
		var pz := local.z + d.z
		var py := altura_en(base.x + px, base.z + pz) - base.y
		var e := ESCALA_KIT.get(ruta.get_slice("/", 0), 2.0) as float
		Kit.poner(g, ruta, Vector3(px, py, pz),
			giro + rng.randf_range(-PI, PI), e * rng.randf_range(0.9, 1.1))


func _armar_fuego(g: Node3D) -> void:
	# La fragua es el punto cálido del valle. La luz parpadeante contra la
	# niebla volumétrica es, sola, la mejor postal que tiene el juego.
	var luz := OmniLight3D.new()
	luz.light_color = Paleta.LUZ_FRAGUA
	luz.light_energy = 9.0
	luz.omni_range = 26.0
	luz.shadow_enabled = true
	luz.position = Vector3(0, 2.0, 0)
	luz.set_script(preload("res://scripts/parpadeo.gd"))
	g.add_child(luz)

	var brasa := SphereMesh.new()
	brasa.radius = 0.55
	brasa.height = 1.1
	# Excepción 1 de la paleta: el fuego. Es donde se gasta todo el presupuesto
	# de saturación del juego, y por eso el resto del valle puede estar apagado.
	brasa.material = Paleta.brasa()
	var mi := MeshInstance3D.new()
	mi.mesh = brasa
	mi.position = Vector3(0, 1.1, 0)
	g.add_child(mi)

	# EL YUNQUE. La fragua se llamaba "La Fragua de Ilde" y era una luz naranja
	# flotando sobre el pasto: el nombre decía que ahí alguien trabajaba y la
	# pantalla no mostraba con qué. Ahora el fuego tiene un pozo, un yunque y
	# un banco alrededor, que es lo que vuelve la luz una explicación en vez de
	# un efecto.
	Kit.poner(g, "utiles/campfire-pit", Vector3(0, 0, 0), 0.0, 4.0)
	Kit.poner(g, "utiles/workbench-anvil", Vector3(2.1, 0, 0.9), -0.6, 2.6)
	Kit.poner(g, "utiles/workbench", Vector3(-1.4, 0, 2.0), 2.3, 2.6)
	Kit.poner(g, "utiles/resource-stone", Vector3(-2.2, 0, -1.1), 0.9, 2.6)


func _armar_faroles(g: Node3D) -> void:
	for i in 4:
		var a := TAU * i / 4.0 + 0.8
		var px := cos(a) * 8.0
		var pz := sin(a) * 8.0
		var py := altura_en(g.position.x + px, g.position.z + pz) - g.position.y

		# El farol de verdad, abajo de la luz. Estaban las cuatro luces y no
		# estaba el poste: de día Vado Bajo tenía cuatro focos invisibles, y de
		# noche cuatro manchas colgadas del aire. La pieza mide 1,56 de alto y
		# va a escala de pueblo, así que el fuego le queda a unos dos metros.
		Kit.poner(g, "pueblo/lantern", Vector3(px, py, pz), a, Detalles.CASA_CELDA)

		var luz := OmniLight3D.new()
		luz.light_color = Paleta.LUZ_FAROL
		luz.light_energy = 3.2
		luz.omni_range = 12.0
		luz.position = Vector3(px, py + 1.9, pz)
		luz.set_script(preload("res://scripts/parpadeo.gd"))
		g.add_child(luz)



func _armar_camino(g: Node3D, color: Color) -> void:
	# `Paleta.LOSA_CAMINO` está un peldaño arriba del suelo (V5 contra V4): la
	# línea del camino se ve y no grita. La rugosidad y el especular los pone la
	# fábrica y no esta función, que es el punto de tener fábricas: si cada
	# script elige su brillo a ojo, todo termina con el mismo reflejo de
	# plástico.
	var mat := Paleta.piedra(color)
	for i in 26:
		var t := i / 26.0
		var pz := -16.0 + t * 34.0
		var px := sin(t * 3.4) * 2.2
		var py := altura_en(g.position.x + px, g.position.z + pz) - g.position.y
		var losa := BoxMesh.new()
		losa.size = Vector3(3.6, 0.12, 1.5)
		losa.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = losa
		mi.position = Vector3(px, py + 0.06, pz)
		mi.rotation.y = randf_range(-0.1, 0.1)
		g.add_child(mi)


func _armar_jugador() -> Jugador:
	var j := Jugador.new()
	j.set_script(preload("res://scripts/jugador.gd"))
	j.position = Vector3(0, altura_en(0, 8) + 2.0, 8)

	var forma := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.85
	forma.shape = cap
	forma.position.y = 0.93
	j.add_child(forma)

	var malla := Node3D.new()
	malla.name = "Malla"
	j.add_child(malla)
	var fig := _figura(COLOR_JUGADOR, ALTURA_JUGADOR, true)
	malla.add_child(fig)
	j.figura = fig

	var pivote := Node3D.new()
	pivote.name = "Pivote"
	j.add_child(pivote)
	var cam := Camera3D.new()
	cam.name = "Camara"
	cam.fov = 42.0
	pivote.add_child(cam)
	return j


func _figura(color: Color, altura: float, es_jugador: bool) -> Figura:
	var f := Figura.new()
	f.set_script(preload('res://scripts/figura.gd'))
	f.altura = altura
	f.color = color
	f.brilla = es_jugador
	f.construir()
	return f


## Los monstruos viven en el Sotobosque. Fuera de la aldea el valle muerde:
## esa es la razón de que la gente se quede junta y de que salir cueste algo.
## Los monstruos del valle son las amenazas de la base. No se inventan acá.
##
## Antes se creaban cinco locales al arrancar y era mentira: los matabas y el
## mundo no se enteraba, no los veía nadie más, y los bichos que de verdad te
## mordían —los del servidor— eran otros. Esa brecha era la razón de que te
## atacaran y no pudieras hacer nada.
##
## La posición sí es local: la base guarda EN QUÉ LUGAR está el bicho, no sus
## coordenadas. Se derivan del id para que sea el mismo punto en la pantalla de
## todos los que estén conectados.
func _sincronizar_amenazas(amenazas: Array) -> void:
	var vistos := {}
	for a in amenazas:
		var d: Dictionary = a
		var id: String = str(d.get("id", ""))
		vistos[id] = true
		if _monstruos_por_id.has(id):
			# Ya está en la escena: sólo se le actualiza la vida, que puede
			# haber bajado porque le pegó otro jugador.
			var existente: Monstruo = _monstruos_por_id[id]
			if is_instance_valid(existente):
				existente.vida = int(d.get("health", existente.vida))
			continue

		var slug: String = str(d.get("place_slug", "bosque"))
		var centro: Vector3 = LUGARES.get(slug, LUGARES['bosque'])['pos']
		# Del id sale siempre el mismo desvío: mismo bicho, mismo lugar, para
		# todos. Si fuera al azar cada uno lo vería en otro lado.
		var h := id.hash()
		var ang := float(h % 1000) / 1000.0 * TAU
		var rad := 4.0 + float((h / 1000) % 800) / 100.0
		var px := centro.x + cos(ang) * rad
		var pz := centro.z + sin(ang) * rad

		var m := Monstruo.new()
		m.set_script(preload('res://scripts/monstruo.gd'))
		add_child(m)
		m.preparar(Vector3(px, altura_en(px, pz) + 0.6, pz), altura_en)
		m.id_servidor = id
		m.nombre_servidor = str(d.get("nombre", "")) if d.get("nombre") != null else str(d.get("kind", ""))
		m.vida = int(d.get("health", 40))
		m.objetivo = jugador
		# El id va atado en el connect porque la señal no lo trae, y el servidor
		# necesita saber QUIÉN te pegó: sin eso agarra la primera amenaza viva
		# del lugar y el evento sale con el bicho equivocado.
		m.pego.connect(_al_recibir_danio.bind(id))
		m.murio.connect(_al_morir_monstruo)
		_monstruos.append(m)
		_monstruos_por_id[id] = m

	# Lo que ya no está en la base, se fue del mundo: lo mató otro.
	for id: String in _monstruos_por_id.keys():
		if vistos.has(id):
			continue
		var viejo_m: Monstruo = _monstruos_por_id[id]
		_monstruos_por_id.erase(id)
		if is_instance_valid(viejo_m) and viejo_m.vida > 0:
			viejo_m.recibir(9999)   # que caiga en pantalla, no que desaparezca


## La otra gente. No los NPC: **las otras personas conectadas al mismo valle.**
##
## Hasta acá dos jugadores en el mismo lugar no se veían: no era multijugador,
## era gente compartiendo una base de datos. El servidor manda en /mundo una
## lista `jugadores` con `name`, `place_slug`, `health` y `caido`, ya sin vos y
## ya filtrada por presencia (90 segundos con reloj de pared, del lado del
## servidor). Acá no se vuelve a filtrar nada: si está en la lista, está.
##
## Lo que NO se hace, y es la mitad del trabajo:
##  - **No hay interpolación ni predicción.** El servidor da LUGARES, no
##    coordenadas: alguien está "en la fragua", no en un punto. Deslizarlo de
##    la fragua a la ruina sería dibujar un viaje que el mundo no conoce.
##    Aparece en el lugar nuevo, que es lo honesto con el dato que hay.
##  - **No quedan fantasmas.** El que no vino en la lista se fue del valle o
##    dejó de dar señales; se lo saca de la escena aunque quedara lindo.
func _sincronizar_jugadores(jugadores: Array) -> void:
	var vistos := {}
	for j in jugadores:
		var d: Dictionary = j
		var nombre := str(d.get("name", ""))
		if nombre == "" or nombre == _mi_nombre:
			# El servidor ya te saca de la lista. El corte igual va: si algún
			# día cambiara, verte a vos mismo parado en la aldea mientras
			# caminás es mucho peor que una rama de más.
			continue
		var slug := str(d.get("place_slug", ""))
		if not LUGARES.has(slug):
			# Puede venir "" cuando el servidor no pudo resolver el lugar. Sin
			# lugar no hay dónde pararlo, y elegir uno sería inventarlo.
			continue
		vistos[nombre] = true

		var nodo: Node3D = _jugadores.get(nombre)
		var recien := nodo == null or not is_instance_valid(nodo)
		if recien:
			nodo = _armar_otro_jugador(nombre)
			add_child(nodo)
			_jugadores[nombre] = nodo

		# Se reescribe la posición en cada poll y no sólo al crearlo: es el
		# único momento en que nos enteramos de que se mudó de lugar.
		nodo.position = _punto_de(nombre, slug)
		nodo.set_meta("vida", int(d.get("health", 100)))
		_tumbar_a(nodo, bool(d.get("caido", false)), recien)

	for nombre: String in _jugadores.keys():
		if vistos.has(nombre):
			continue
		var viejo: Node3D = _jugadores[nombre]
		_jugadores.erase(nombre)
		if is_instance_valid(viejo):
			viejo.queue_free()


## Dónde se para alguien dentro de su lugar.
##
## Sale del NOMBRE, nunca de `randf()`, por el mismo motivo que la posición de
## las amenazas sale del id: es lo que hace que la misma persona esté en el
## mismo punto en la pantalla de todos. Si cada máquina tirara sus dados,
## señalar "está ahí" no querría decir nada y dejó de ser el mismo mundo.
##
## El hash es el de `Figura` —FNV-1a a mano— y no `String.hash()`: el de Godot
## no promete el mismo número entre versiones del motor, y acá "el mismo número
## siempre" ES el requisito. De paso es el mismo hash del que ya salen la
## altura, la piel y la ropa de esa persona: una sola identidad, no dos.
##
## El anillo va de 7,5 a 12 m del centro: afuera de los NPC (6,5 m) y de las
## casas, adentro del radio con el que el lugar se considera "acá" (30 m).
func _punto_de(nombre: String, slug: String) -> Vector3:
	var centro: Vector3 = LUGARES[slug]['pos']
	var h := Figura._hash32(nombre)
	var ang := float(h % 997) / 997.0 * TAU
	var rad := 7.5 + float((h / 997) % 450) / 100.0
	var px := centro.x + cos(ang) * rad
	var pz := centro.z + sin(ang) * rad
	return Vector3(px, altura_en(px, pz), pz)


## El cuerpo de otro jugador.
##
## Que se lea que **no es un habitante del valle** se resuelve con tres cosas
## que ya existen y que se leen desde 27 m, que es donde está la cámara:
##  1. Tu color y tu altura (1,85 contra 1,72 de los NPC). Es literalmente el
##     mismo cuerpo que estás manejando vos.
##  2. `brilla`: la ropa emite apenas, como la tuya. De noche, un jugador
##     lejano es una lucecita y un NPC no. No pisa la firma del monstruo, que
##     son los ojos naranjas, no la ropa.
##  3. Sin oficio. Los oficios de `figura.gd` visten a los que viven acá
##     —delantal de herrera, capucha de cazadora, hombreras de guardia— y el
##     servidor no le da oficio a un jugador. Ponerle uno sería inventarlo, así
##     que se queda con el cinturón, que es el default. Nadie de afuera lleva
##     el uniforme de un oficio del valle.
func _armar_otro_jugador(nombre: String) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = "jugador_" + nombre.validate_node_name()
	# Van ANTES de colgar la figura: su `_ready()` las lee del padre para
	# sacarse el cuerpo del hash del nombre, y ya corrió si la agregamos antes.
	nodo.set_meta("nombre", nombre)
	nodo.set_meta("oficio", "")

	var fig := _figura(COLOR_JUGADOR, ALTURA_JUGADOR, true)
	fig.name = "Cuerpo"
	nodo.add_child(fig)
	# El nombre en el color de la gente: dos carteles distintos a la misma
	# distancia dicen "esa es una persona y ese es un vecino" sin leerlos.
	nodo.add_child(_cartel(nombre, COLOR_JUGADOR.lightened(0.45)))
	return nodo


## Alguien con la vida en cero se dibuja **tumbado, no invisible**. Que haya un
## cuerpo en el piso de la ruina es información sobre la ruina: ahí pasó algo,
## y probablemente sigue pasando. Esconderlo borraría un hecho del mundo.
##
## Se inclina el cuerpo y NO se llama a `figura.caer()`, igual que con tu
## propia caída: ese apaga la animación para siempre y de esta caída se vuelve
## —el otro aprieta levantarse y el /mundo siguiente lo trae de pie—. Sigue
## respirando y parpadeando tirado, que es lo correcto: está caído, no muerto.
##
## El cartel no se inclina, se baja: queda flotando sobre el cuerpo en vez de
## dos metros y medio arriba de un bulto anónimo.
func _tumbar_a(nodo: Node3D, si: bool, instantaneo: bool) -> void:
	if not instantaneo and bool(nodo.get_meta("caido", false)) == si:
		return          # ya está como corresponde; no re-tweenear cada 12 s
	nodo.set_meta("caido", si)
	var cuerpo := nodo.get_node_or_null("Cuerpo") as Node3D
	var cartel := nodo.get_node_or_null("Cartel") as Node3D
	if cuerpo == null:
		return
	var giro := (-PI / 2.0 + 0.15) if si else 0.0
	var hundir := -0.3 if si else 0.0
	var alto_cartel := ALTO_CARTEL_CAIDO if si else ALTO_CARTEL
	if instantaneo:
		# Recién aparece: si ya estaba en el piso, ya estaba. Tweenearlo sería
		# contar una caída que pasó cuando no estábamos mirando.
		cuerpo.rotation.x = giro
		cuerpo.position.y = hundir
		if cartel != null:
			cartel.position.y = alto_cartel
		return
	# El tween se crea desde el nodo del jugador para que muera con él: si se
	# va del valle mientras cae, no queda un tween apuntando a un nodo liberado.
	var t := nodo.create_tween().set_parallel(true)
	t.tween_property(cuerpo, "rotation:x", giro, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN if si else Tween.EASE_OUT)
	t.tween_property(cuerpo, "position:y", hundir, 0.45)
	if cartel != null:
		t.tween_property(cartel, "position:y", alto_cartel, 0.45)


# ---------------------------------------------------------------------------
# La gente del valle, y su ronda
# ---------------------------------------------------------------------------
#
# **Esto es animación de presencia, no estado.** Para el mundo, Ilde está EN LA
# FRAGUA: el servidor manda lugares, no coordenadas, y eso no se toca acá. Lo
# único que cambia es que adentro de su lugar no está congelada. Nadie camina
# de un lugar a otro por su cuenta —eso sería inventar un viaje que el mundo no
# conoce, que es exactamente el error que ya se cometió con los monstruos— y
# esta pasada entera no manda un solo request nuevo.
#
# Cuando el /mundo dice que alguien se mudó, se mueve de lugar y se acabó: la
# ronda se vuelve a plantar alrededor del anclaje nuevo, sin deslizarse.

## El anillo donde se para la gente, cuando el lugar la deja pararse ahí. Los
## otros jugadores van de 7,5 a 12 m (ver `_punto_de`): 6,5 es el hueco que
## queda por dentro. Ver `_anillo_de()` para cuándo no alcanza.
const ANILLO_GENTE := 6.5
## Media casa, con el cuerpo de la persona adentro del número: la caja mide
## 2,7 × 2,5 (o sea 1,35 × 1,25 de medio lado) y los 30 cm que sobran son para
## que nadie termine rozando la pared.
##
## Es una CAJA ORIENTADA y no un círculo, y la diferencia importa: las siete
## casas de la aldea están a 5 m del centro y a 4,34 m una de otra, así que
## círculos que las cubran enteras se solapan entre sí y dejan a la gente
## atrapada contra ellos —medido con el andamio: dos de los tres vecinos de la
## aldea quedaban clavados—. Con la caja de verdad hay calle entre casa y casa.
## Media planta de la casa más holgura, para empujar a la gente antes de que
## roce la pared. Sigue a `Detalles.CASA_CELDA`: si la casa crece y esto no,
## la gente camina por adentro de las paredes.
const CASA_MEDIA := Vector2(3.15, 3.05)
## Hasta dónde puede llegar alguien haciendo su ronda, medido desde el centro
## del lugar. Es el límite duro y tiene la última palabra: nadie se va de su
## lugar, y **nadie se le sube a los otros jugadores**, que empiezan a pararse a
## 7,5 m. Si alguna vez pelea con el empujón de una casa, gana éste — quedar
## rozando una pared es feo, quedar adentro de otra persona es peor.
const RONDA_LIMITE := 7.3

## La forma de una ronda. Todo esto sale del nombre y NADA de la máquina.
const RONDA_TANGENTE := 1.9    ## cuánto se corre a lo largo del anillo
const RONDA_ADENTRO := 1.6     ## cuánto se mete hacia el centro del lugar
const RONDA_AFUERA := 0.45     ## y cuánto se aleja (poco: ahí está el límite)
const RONDA_MIRADA := 1.0      ## desvío máximo, en radianes, de mirar al centro
const RONDA_PASO := 0.95       ## m/s. Paso de andar por su lugar, no de ir a algún lado.
const RONDA_QUIETO_MIN := 1.8  ## segundos parado en una parada
const RONDA_QUIETO_MAX := 7.0
## Cuánto se le exagera el paso.
##
## `Figura.animar()` está calibrada para el jugador, que corre a 7,5 m/s. Si se
## le pasan los 0,95 m/s de andar por el patio tal cual, sale un balanceo de
## pierna de SEIS grados y una zancada cada siete segundos. Medido, no estimado:
## con el andamio puesto la intensidad de la caminata daba 0,17 y el pie se
## movía seis centímetros. **A la distancia a la que se juega eso son dos
## píxeles, o sea que la persona se desliza en vez de caminar.**
##
## Así que se le miente la velocidad. No es un parche: es la decisión de arte
## del proyecto aplicada al movimiento. **Un caminar estilizado y claro es lo
## correcto; uno "más realista" y blando es el error.** Con este factor la
## pierna queda en 25° para cada lado, la cadencia en 1,2 pasos por segundo y la
## zancada en 80 cm — una zancada larga para andar por el patio, y a propósito:
## pocos pasos grandes se leen de lejos y un trotecito rápido no.
##
## La cuenta, con la cámara donde está (40 m de default, 68 m del todo afuera,
## FOV 42°, 1080 de alto): un metro son 35 px a 40 m y 21 px a 68 m. La pierna
## mide 55 cm y el pie recorre 46, o sea 16 px de default y 9,5 con el zoom
## afuera del todo. Se ve. Lo de antes, no.
const RONDA_ZANCADA := 4.0

## Un salto más grande que esto no es caminar, es cambiarse de lugar: no se le
## anima una zancada ni se le gira el cuerpo, se lo planta y listo.
const RONDA_SALTO := 1.5

## Los períodos posibles de una ronda, en segundos.
##
## **Todos dividen a `Ciclo.DIA_REAL` (21600 s).** No es cosmético: la posición
## sale de `fposmod(hora_del_valle, período)`, y si el período divide al día
## entonces ese resto no depende de en qué día del valle estemos. O sea que
## cuando el día cambia no hay ningún salto, y tampoco importa que el número de
## día llegue con doce segundos de atraso respecto de la hora.
const RONDA_PERIODOS: Array[int] = [18, 20, 24, 27, 30, 32, 36, 40, 45, 48, 54, 60, 72, 75, 80, 90]

## A cuánto empieza a importarle a alguien que llegaste.
const RECELO := 9.0
## Y cuánto se corre el que te tiene miedo. Medio paso: es un respingo, no una
## huida — huir sería irse del lugar, y de eso decide el servidor.
const RECELO_PASO := 0.9


## A qué distancia del centro se para la gente de este lugar.
##
## No puede ser un número fijo porque **el caserío se mueve**: `_armar_lugar()`
## saca el radio del círculo de casas de CUÁNTAS son, así que hoy la aldea de
## siete las tiene a 6,45 m y la fragua de dos a 4,70, y mañana otra cosa. Con
## un 6,5 escrito a mano, la gente de la aldea aparecía adentro de las paredes.
##
## La regla: **cuatro casas o más son un caserío alrededor de una plaza, y la
## gente vive en la plaza.** Con menos el círculo no cierra, se sale por los
## huecos, y conviene el anillo de siempre — que además deja a la herrera del
## lado de afuera de la fragua y no encima del fuego.
func _anillo_de(centro: Vector2, huellas: Array[Vector3]) -> float:
	if huellas.size() < 4:
		return ANILLO_GENTE
	var r := centro.distance_to(Vector2(huellas[0].x, huellas[0].y))
	# Media casa hacia adentro más medio metro de vereda.
	return minf(ANILLO_GENTE, r - CASA_MEDIA.y - 0.5)


## Los NPC.
##
## Antes se borraban y se rehacían enteros en cada /mundo: siete cuerpos
## articulados de quince mallas cada uno, cada doce segundos. Mientras estaban
## parados no se notaba. Con la ronda sí — rehacerlos les borra la fase de la
## caminata, el desfase del parpadeo y el de la respiración, y cada refresco se
## veía como un tirón colectivo. Ahora se sincronizan como los otros jugadores
## y como las amenazas: se crea el que llegó, se re-ancla el que se mudó, se
## saca el que ya no está. De paso el /mundo pasa a costar casi nada.
func _sincronizar_gente(gente: Array, lugares: Array) -> void:
	var slug_por_id := {}
	for p in lugares:
		var lp: Dictionary = p
		slug_por_id[str(lp.get("id", ""))] = str(lp.get("slug", ""))

	var por_lugar := {}
	for p in gente:
		var d: Dictionary = p
		var slug: String = slug_por_id.get(str(d.get("place_id", "")), "")
		if not LUGARES.has(slug):
			continue          # un lugar que este cliente todavía no dibuja
		if not por_lugar.has(slug):
			por_lugar[slug] = []
		por_lugar[slug].append(d)

	var yo := Vector2.ZERO
	if jugador != null:
		yo = Vector2(jugador.global_position.x, jugador.global_position.z)

	var adentro := _repartir_casas(gente, slug_por_id)

	var vistos := {}
	for slug: String in por_lugar:
		var lista: Array = por_lugar[slug]
		var centro: Vector3 = LUGARES[slug]["pos"]
		var anillo: float = _anillos.get(slug, ANILLO_GENTE)
		for i in lista.size():
			var persona: Dictionary = lista[i]
			var nombre := str(persona.get("name", "?"))
			vistos[nombre] = true

			# El anclaje sale del ÍNDICE dentro del lugar y no del nombre, igual
			# que antes: es lo que reparte a la gente en el anillo sin que dos
			# caigan encima. El orden lo manda el servidor, así que el anillo
			# sale igual en todas las pantallas.
			var a := TAU * i / maxf(lista.size(), 3.0) + 0.7

			var nodo: Node3D = _npcs.get(nombre)
			var recien: bool = nodo == null or not is_instance_valid(nodo)
			if recien:
				nodo = _armar_vecino(nombre, str(persona.get("trade", "")))
				add_child(nodo)
				_npcs[nombre] = nodo
			nodo.set_meta("lugar", slug)
			nodo.set_meta("angulo", a)
			nodo.set_meta("ancla", Vector2(
				centro.x + cos(a) * anillo, centro.z + sin(a) * anillo))
			# ¿Está en su casa a esta hora? Lo decide el servidor con
			# `rutinaDe()`, no este archivo. Con el metadato puesto, la ronda de
			# más abajo lo planta adentro y no la toca ni el límite del lugar.
			var casa: Array = adentro.get(nombre, [])
			if casa.is_empty():
				if nodo.has_meta("adentro"):
					nodo.remove_meta("adentro")
					nodo.remove_meta("casa")
			else:
				nodo.set_meta("adentro", casa[1])
				nodo.set_meta("casa", casa[0])
			if recien:
				# Que aparezca ya en el punto que le toca de su ronda, sin la
				# zancada de llegar desde el origen del mundo.
				_ubicar_vecino(nombre, nodo, _reloj_del_valle(), 0.0, yo)

	for nombre: String in _npcs.keys():
		if vistos.has(nombre):
			continue
		var viejo: Node3D = _npcs[nombre]
		_npcs.erase(nombre)
		_rondas.erase(nombre)
		if is_instance_valid(viejo):
			viejo.queue_free()


## Quién vive en qué casa, y quién está adentro AHORA.
##
## Las dos cosas salen de datos que `/mundo` ya manda y que este cliente venía
## tirando a la basura:
##
##   · `home_place_id` — de qué lugar es su casa. Existe en la base desde la
##     migración de la rutina y acá no lo leía nadie.
##   · `durmiendo` y `durmiendo_afuera` — los calcula `rutinaDe()` en el
##     servidor con la hora del valle. `durmiendo` sin `durmiendo_afuera`
##     significa "está en su casa"; con las dos, se quedó en el monte y de ahí
##     no se vuelve al oscurecer. **No se inventa nada acá.**
##
## Qué casa le toca a cada uno sale del ORDEN ALFABÉTICO dentro de su lugar, y
## eso no es capricho: tiene que dar lo mismo en todas las pantallas, y el
## orden en que el servidor devuelve las filas no está garantizado. Con más
## gente que casas, se comparte techo — que es lo que pasa en un pueblo.
##
## Devuelve nombre -> `[clave de la casa, punto del mundo]`, sólo para los que
## están adentro. A los demás igual se les registra la casa: **el yunque del
## cuarto de Ilde tiene que estar ahí también de día**, cuando ella está afuera
## martillando. Una fragua que sólo existe de noche no es una fragua.
func _repartir_casas(gente: Array, slug_por_id: Dictionary) -> Dictionary:
	interiores.olvidar_gente()

	var por_lugar := {}
	for p in gente:
		var d: Dictionary = p
		var slug: String = slug_por_id.get(str(d.get("home_place_id", "")), "")
		var huellas: Array = _casas.get(slug, [])
		if huellas.is_empty():
			continue          # su lugar no tiene casas dibujadas (el bosque, el camino)
		if not por_lugar.has(slug):
			por_lugar[slug] = []
		por_lugar[slug].append(d)

	var salida := {}
	for slug: String in por_lugar:
		var lista: Array = por_lugar[slug]
		lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("name", "")) < str(b.get("name", "")))
		var cuantas: int = (_casas[slug] as Array).size()
		for i in lista.size():
			var d: Dictionary = lista[i]
			var nombre := str(d.get("name", "?"))
			var clave := "%s/%d" % [slug, i % cuantas]
			var punto := interiores.habitar(clave, nombre, str(d.get("trade", "")))
			if bool(d.get("durmiendo", false)) and not bool(d.get("durmiendo_afuera", false)):
				salida[nombre] = [clave, punto]
	return salida


func _armar_vecino(nombre: String, oficio: String) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = "vecino_" + nombre.validate_node_name()
	# Van ANTES de colgar la figura: su `_ready()` las lee del padre para
	# sacarse el cuerpo del hash del nombre.
	nodo.set_meta("nombre", nombre)
	nodo.set_meta("oficio", oficio)
	# `Paleta.ROPA_NPC` es V6, y ese peldaño no es decorativo: `figura.gd` deriva
	# la ropa multiplicando el VALOR de acá por 0.42–1.40, así que un V6 produce
	# el abanico V3–V8 que hace que siete vecinos no parezcan la misma persona.
	# Bajarlo vuelve al pueblo entero una fila de sombras iguales.
	var fig := _figura(Paleta.ROPA_NPC, 1.72, false)
	fig.name = "Cuerpo"
	nodo.add_child(fig)
	nodo.add_child(_cartel(nombre))
	return nodo


## El reloj con el que anda la gente.
##
## Arranca del reloj del VALLE —el que manda el servidor, el mismo que mueve el
## sol— y no del de esta máquina: si cada uno usara el suyo, Ilde estaría en un
## punto distinto de su ronda en cada pantalla y "está martillando" dejaría de
## ser un hecho del mundo.
##
## De ahí en más avanza solo, sumando el tiempo de cada cuadro. No se re-lee el
## del servidor en cada /mundo a propósito: la corrección sería de unas décimas
## —lo que tardó el pedido en volver— pero se vería como un tirón de medio
## metro en toda la gente del valle cada doce segundos. Un reloj que arranca
## bien y corre solo se aparta unos milisegundos por hora, que es exactamente
## nada al lado de eso.
func _reloj_del_valle() -> float:
	if _reloj_ronda < 0.0:
		_reloj_ronda = (ciclo.fraccion() * Ciclo.DIA_REAL) if ciclo != null else 0.0
	return _reloj_ronda


## Mueve a toda la gente del valle. Se llama una vez por cuadro.
##
## Cuesta lo que cuesta recorrer siete nodos: una consulta a la tabla de la
## ronda (cinco tramos como mucho), un empujón fuera de las casas y las diez
## rotaciones que ya escribía `Figura.animar()` para el jugador y los bichos.
## Sin asignar memoria: la ronda está cacheada y la consulta devuelve un
## Vector3, no un diccionario.
func _mover_gente(dt: float) -> void:
	if _npcs.is_empty() or jugador == null:
		return
	_reloj_ronda = _reloj_del_valle() + dt
	var yo := Vector2(jugador.global_position.x, jugador.global_position.z)
	for nombre: String in _npcs:
		var nodo: Node3D = _npcs[nombre]
		if is_instance_valid(nodo):
			_ubicar_vecino(nombre, nodo, _reloj_ronda, dt, yo)


## Dónde va una persona en este cuadro. `dt <= 0` la planta sin animarla.
func _ubicar_vecino(nombre: String, nodo: Node3D, t: float, dt: float, yo: Vector2) -> void:
	var slug := str(nodo.get_meta("lugar", ""))
	if not LUGARES.has(slug):
		return

	# EN SU CASA. Es la mitad de para qué existen los interiores: hasta hoy el
	# servidor mandaba a la gente a dormir a su casa —`rutinaDe()`— y el cliente
	# la plantaba en la plaza igual, a la intemperie, con la ventana encendida
	# mintiendo. Ahora está adentro.
	#
	# No hace ronda, no la empuja ninguna pared y **no la clava el límite del
	# lugar**: las casas están a doce metros del centro y `RONDA_LIMITE` son
	# 7,3, así que pasar por los clamps de abajo la sacaría de su propia casa.
	# Sigue respirando y parpadeando, que es lo que la distingue de un mueble.
	if nodo.has_meta("adentro"):
		var p3: Vector3 = nodo.get_meta("adentro")
		nodo.position = p3
		var quieto := nodo.get_node_or_null(^"Cuerpo") as Figura
		if quieto == null:
			return
		quieto.rotation.y = interiores.mirando_al_fuego(
			str(nodo.get_meta("casa", "")), p3)
		if dt > 0.0 and Vector2(p3.x, p3.z).distance_squared_to(yo) \
				< _ANIMAR_HASTA[Rendimiento.nivel]:
			quieto.animar(dt, 0.0, true)
		return
	var centro3: Vector3 = LUGARES[slug]["pos"]
	var centro := Vector2(centro3.x, centro3.z)
	var ancla: Vector2 = nodo.get_meta("ancla", centro)
	var angulo: float = nodo.get_meta("angulo", 0.0)

	# El marco de la ronda: "afuera" apunta del centro del lugar hacia el
	# anclaje, "tangente" corre a lo largo del anillo. Que la ronda se mida así
	# y no en X/Z del mundo es lo que hace que andar de un lado a otro mantenga
	# la distancia al centro — o sea, que se pasee POR su lugar, alrededor de la
	# fragua, y no en diagonal hacia adentro del fuego.
	var afuera := Vector2(cos(angulo), sin(angulo))
	var tangente := Vector2(-afuera.y, afuera.x)
	var r := _ronda_punto(nombre, t)
	var p := ancla + tangente * r.x + afuera * r.y
	# Parado, mira hacia el centro de su lugar con el desvío que le tocó. Es lo
	# que hace que un corro de gente se lea como gente ocupada en algo y no como
	# figuras mirando al vacío cada una para su lado.
	var rumbo := atan2(centro.x - p.x, centro.y - p.y) + r.z

	# Cómo te trata al llegar. Sale del `animo` que YA viaja en /mundo con el
	# saludo, no de un dato nuevo: el que te teme se corre medio paso y te da la
	# espalda, el que te aprecia se da vuelta a mirarte. Es lo único de acá que
	# depende de dónde estás vos, y tiene que serlo — es una reacción a vos.
	var animo := str((_actitudes.get(nombre, {}) as Dictionary).get("animo", "neutral"))
	if animo == "hostil" or animo == "calido":
		var hacia_vos := yo - p
		var d := hacia_vos.length()
		if d > 0.05 and d < RECELO:
			var cerca := 1.0 - d / RECELO
			hacia_vos /= d
			if animo == "hostil":
				p -= hacia_vos * cerca * RECELO_PASO
				if cerca > 0.15:
					rumbo = atan2(-hacia_vos.x, -hacia_vos.y)
			elif cerca > 0.15:
				rumbo = atan2(hacia_vos.x, hacia_vos.y)

	# Los dos límites. El de la casa va en el medio para que sea él quien
	# resuelva el caso normal —el empujón contra una pared— y el del lugar va a
	# los dos lados para que sea él quien tenga la última palabra, que es lo que
	# corresponde: rozar una pared es feo, meterse adentro de otro jugador es
	# peor, y la geometría del caserío la decide otro archivo y cambia.
	p = _afuera_de_casas(slug, _dentro_del_lugar(centro, p))
	p = _dentro_del_lugar(centro, p)

	var antes := Vector2(nodo.position.x, nodo.position.z)
	var tramo := p.distance_to(antes)
	var planta: bool = dt <= 0.0 or tramo > RONDA_SALTO
	nodo.position = Vector3(p.x, altura_en(p.x, p.y), p.y)

	var cuerpo := nodo.get_node_or_null(^"Cuerpo") as Figura
	if cuerpo == null:
		return
	# La velocidad sale del desplazamiento REAL y no de la fórmula: así los
	# rodeos que le hace dar una casa mueven las piernas igual que el tramo
	# recto, y frenar contra el límite del lugar frena también la caminata.
	var vel := 0.0 if planta else tramo / dt
	if vel > 0.15:
		rumbo = atan2(p.x - antes.x, p.y - antes.y)
	if planta:
		cuerpo.rotation.y = rumbo
	else:
		# Girar lleva su tiempo. Es la mitad de que se lea como una persona
		# decidiendo y no como un cartel rotando: 3,5 rad/s son unos 200 ms para
		# darse vuelta del todo. El `wrapf` es higiene: `lerp_angle` siempre va
		# por el lado corto pero devuelve el ángulo sin plegar, y en una sesión
		# larga eso se aleja del cero y se come la precisión del float.
		cuerpo.rotation.y = wrapf(
			lerp_angle(cuerpo.rotation.y, rumbo, minf(1.0, 3.5 * dt)), -PI, PI)
		# El único lugar donde el nivel de calidad puede meterse, y conviene
		# decir por qué: la ronda misma NO puede depender de él —es la identidad
		# de la persona, tiene que dar igual en las tres máquinas, y `nivel` es
		# justamente lo que cambia de máquina a máquina—. Lo que sí es opcional
		# es DIBUJARLE la zancada a alguien que está a cien metros: ahí el paso
		# entero mide seis píxeles y ya está detrás del desenfoque de lejanía y
		# de la niebla. La persona igual se sigue moviendo; lo que se congela es
		# la pierna.
		if p.distance_squared_to(yo) < _ANIMAR_HASTA[Rendimiento.nivel]:
			cuerpo.animar(dt, vel * RONDA_ZANCADA, true)


## Hasta dónde se le anima la caminata a alguien, al cuadrado (bajo/medio/alto).
const _ANIMAR_HASTA: Array[float] = [3600.0, 6400.0, 12100.0]


## Que nadie se vaya de su lugar. Ver `RONDA_LIMITE`.
func _dentro_del_lugar(centro: Vector2, p: Vector2) -> Vector2:
	var fuera := p - centro
	var l := fuera.length()
	return (centro + fuera / l * RONDA_LIMITE) if l > RONDA_LIMITE else p


## Empuja un punto fuera de las casas del lugar, por la pared que tenga más
## cerca.
##
## Es lo que deja calcular la ronda libre y sin caminos: la trayectoria pasa por
## donde quiera y acá se la desvía, así que rodear una casa o caminar pegado a
## una pared salen solos. Y como la velocidad se mide del desplazamiento REAL,
## el rodeo se camina en vez de deslizarse.
##
## Esto es lo único de la ronda que puede dar distinto en dos máquinas, y es
## porque **las casas ya dan distinto**: `_armar_lugar()` les sortea el giro con
## `randf()`. Son centímetros contra una pared, y la alternativa —sembrar el
## sorteo de las casas— es otra tarea.
func _afuera_de_casas(slug: String, p: Vector2) -> Vector2:
	for c: Vector3 in _casas.get(slug, []):
		var centro := Vector2(c.x, c.y)
		# Al marco de la casa. Un giro de θ en Y lleva lo local al mundo con
		# `rotated(-θ)`, así que del mundo a lo local se va con `rotated(θ)`.
		var d := (p - centro).rotated(c.z)
		var mx := CASA_MEDIA.x - absf(d.x)
		var my := CASA_MEDIA.y - absf(d.y)
		if mx <= 0.0 or my <= 0.0:
			continue                     # afuera de esta casa, no hay nada que hacer
		if mx < my:
			d.x = CASA_MEDIA.x if d.x >= 0.0 else -CASA_MEDIA.x
		else:
			d.y = CASA_MEDIA.y if d.y >= 0.0 else -CASA_MEDIA.y
		p = centro + d.rotated(-c.z)
	return p


# ---------------------------------------------------------------------------
# La ronda: una vuelta de paradas, sacada del nombre
# ---------------------------------------------------------------------------
#
# Lo que separa esto de "los maniquíes ahora vibran" es una sola idea: **el
# tiempo quieto es parte del movimiento.** Alguien que camina en círculos sin
# parar se lee peor que alguien clavado — se lee como un objeto en un carrusel.
# Alguien que va a un punto, se queda ahí un rato largo dando media vuelta, y
# después va a otro, se lee como alguien haciendo algo. Por eso la ronda son
# PARADAS con su tiempo de estar quieto, y la caminata es el rato corto que hay
# entre dos: unas tres cuartas partes de la vuelta las pasa parada.
#
# Y todo sale del nombre, con el mismo hash del que ya salen su altura, su piel
# y su ropa: cuántas paradas tiene, dónde están, cuánto se queda en cada una,
# hacia dónde mira, y cuánto dura la vuelta entera. Una sola identidad, no dos.

## La ronda de una persona, cacheada. Devuelve las paradas en el marco de la
## ronda (tangente, radial), el desvío de la mirada en cada una, y la tabla de
## cortes: el tramo par 2k es el camino hasta la parada k y el impar 2k+1 es el
## rato que se queda ahí.
func _ronda(nombre: String) -> Dictionary:
	if _rondas.has(nombre):
		return _rondas[nombre]

	var cuantas := 3 + int(_dado(nombre, "ronda_n") * 3.0)   # 3, 4 o 5 paradas
	var paradas := PackedVector2Array()
	var mirada := PackedFloat32Array()
	var quieto := PackedFloat32Array()
	for k in cuantas:
		var c := "ronda%d" % k
		paradas.append(Vector2(
			(_dado(nombre, c + "t") - 0.5) * 2.0 * RONDA_TANGENTE,
			_dado(nombre, c + "r") * (RONDA_ADENTRO + RONDA_AFUERA) - RONDA_ADENTRO))
		mirada.append((_dado(nombre, c + "m") - 0.5) * 2.0 * RONDA_MIRADA)
		quieto.append(RONDA_QUIETO_MIN
			+ _dado(nombre, c + "q") * (RONDA_QUIETO_MAX - RONDA_QUIETO_MIN))

	# Cuánto duraría la vuelta caminando a paso de andar por su lugar.
	var andar := PackedFloat32Array()
	var crudo := 0.0
	for k in cuantas:
		var largo := paradas[k].distance_to(paradas[(k + cuantas - 1) % cuantas])
		var s: float = maxf(largo / RONDA_PASO, 0.5)
		andar.append(s)
		crudo += s + quieto[k]

	# Y ahora se la estira o se la encoge hasta el período válido más cercano
	# (ver RONDA_PERIODOS). El ajuste es de menos del 10%, así que lo único que
	# cambia es que cada uno camina a su ritmo, que es lo que queríamos igual.
	var periodo: float = RONDA_PERIODOS[0]
	for candidato: int in RONDA_PERIODOS:
		if absf(candidato - crudo) < absf(periodo - crudo):
			periodo = candidato
	var escala := periodo / crudo

	var cortes := PackedFloat32Array()
	var acum := 0.0
	for k in cuantas:
		acum += andar[k] * escala
		cortes.append(acum)
		acum += quieto[k] * escala
		cortes.append(acum)

	var r := {
		"periodo": periodo,
		# El desfase es lo que evita que los siete arranquen a caminar juntos.
		"desfase": _dado(nombre, "ronda_f") * periodo,
		"paradas": paradas, "mirada": mirada, "cortes": cortes,
	}
	_rondas[nombre] = r
	return r


## Dónde está y hacia dónde mira, dentro de su ronda, en el segundo `t` del
## valle. Devuelve (tangente, radial, desvío de la mirada).
##
## Un Vector3 y no un diccionario porque esto se llama una vez por persona y por
## cuadro: un diccionario por llamada es basura que después alguien junta.
func _ronda_punto(nombre: String, t: float) -> Vector3:
	var r := _ronda(nombre)
	var paradas: PackedVector2Array = r["paradas"]
	var mirada: PackedFloat32Array = r["mirada"]
	var cortes: PackedFloat32Array = r["cortes"]
	var n := paradas.size()
	var tt: float = fposmod(t + float(r["desfase"]), float(r["periodo"]))

	var i := 0
	while i < cortes.size() - 1 and tt >= cortes[i]:
		i += 1
	var k := i / 2
	if i % 2 == 1:
		return Vector3(paradas[k].x, paradas[k].y, mirada[k])   # quieto en la parada

	var inicio: float = cortes[i - 1] if i > 0 else 0.0
	var u: float = clampf((tt - inicio) / maxf(cortes[i] - inicio, 0.001), 0.0, 1.0)
	# Arranca y frena. Un tramo a velocidad constante entre dos paradas se lee
	# como una figura deslizándose; con el arranque y el freno se lee como
	# alguien que se decidió a ir hasta ahí. Y `Figura.animar()` ya suaviza la
	# intensidad de la caminata encima de esto, así que el paso también entra y
	# sale de a poco.
	var p: Vector2 = paradas[(k + n - 1) % n].lerp(paradas[k], smoothstep(0.0, 1.0, u))
	return Vector3(p.x, p.y, mirada[k])


## Un número 0..1 estable por persona y por rasgo, con el mismo FNV-1a que usa
## `Figura` para la altura, la piel y la ropa. No es `String.hash()` ni un
## `randf()` sembrado: ninguno de los dos promete el mismo número entre
## versiones del motor, y acá "el mismo número siempre" ES el requisito.
static func _dado(nombre: String, canal: String) -> float:
	return float(Figura._hash32(nombre + "/" + canal) % 100003) / 100003.0


## Mientras devuelva true, el teclado no es del personaje. Dos motivos, y los
## dos son estados en los que caminar sería raro: le estás escribiendo a
## alguien, o estás tirado en el piso. Pegar se corta aparte (en _al_golpear)
## porque es un clic, y el clic no pasa por este filtro.
func _jugador_sin_control() -> bool:
	# Tres estados, y el tercero es nuevo: con el radial de runas abierto o con
	# el grimorio encima, el teclado tampoco es del personaje — las iniciales de
	# las runas son B, Q, A y V, y dos de ésas ya son teclas del juego.
	return _caido or interfaz.escribiendo() \
		or (runas != null and is_instance_valid(runas) and runas.captura_teclado())


## Un bicho te pegó.
##
## Mismo patrón que cuando pegás vos (_al_golpear): el efecto se pinta YA y el
## aviso al servidor sale en paralelo. Esperar la respuesta para reaccionar
## mete 200 ms entre el impacto y el tirón, y eso alcanza para que se sienta
## roto.
##
## Lo que no se adivina es el NÚMERO: cuánto duele lo decide el mundo, igual
## que el daño que hacés vos. La barra se corrige cuando vuelve la respuesta.
## El daño que manda `pego` queda sin usar a propósito — es la constante local
## del monstruo y ya no manda nada.
func _al_recibir_danio(_danio_local: int, id_amenaza: String) -> void:
	# Al caído no se le pega: el servidor tampoco lo permite, y sin esto cada
	# mordida de un bicho que sigue encima manda un POST que ya sabemos que va
	# a volver con ok=false.
	if _caido:
		return
	jugador.doler()
	# Que se sepa quién te está pegando. Sin esto la vida baja sola y el
	# jugador no entiende de dónde vino: "me ataca el monstruo sin decirme
	# nada" fue exactamente el reclamo.
	var quien := ""
	for m in _monstruos:
		if is_instance_valid(m) and m.id_servidor == id_amenaza:
			quien = m.nombre_servidor
			break
	interfaz.golpe_recibido(quien)
	api.danio(id_amenaza)


## Lo que dijo el servidor del golpe que te dieron. La vida que vale es la de él.
func _al_resultado_de_danio(d: Dictionary) -> void:
	if not d.has("health"):
		return          # "no existe": no hay nada que sincronizar
	# Sólo baja. Hay varios golpes en vuelo a la vez —dos bichos encima pegan
	# cada 1,25 s— y las respuestas no vuelven en orden: sin este mini la barra
	# sube y baja sola. Curarse nunca llega por acá, llega por /mundo o por
	# levantarse.
	_mostrar_vida(mini(_vida, int(d.get("health", _vida))))
	if bool(d.get("caido", false)):
		_caer_jugador()


func _al_morir_monstruo(_quien: Monstruo) -> void:
	_monstruos = _monstruos.filter(func(m: Monstruo) -> bool: return is_instance_valid(m))
	interfaz.avisar('Cayó uno.')


## La barra dibuja el último número del servidor, y nada más.
func _mostrar_vida(v: int) -> void:
	_vida = clampi(v, 0, _vida_maxima)
	interfaz.mostrar_vida(_vida, _vida_maxima)


## Te tumbaron.
##
## No hay temporizador. Antes te levantabas solo a los 2,4 segundos, que es lo
## mismo que no haber caído nunca; y la salida fácil —un reloj más largo— está
## prohibida por las bases: nada puede cobrarte tiempo de juego. Caer termina
## cuando el jugador decide levantarse y el servidor lo escribe.
##
## Lo que cuesta caer son las dos cosas que se pueden cobrar sin romper nada:
## la posición (te levantás en la aldea) y la cara (los que te vieron caer te
## temen un poco menos, y eso lo cobra el servidor). No cuesta saber.
func _caer_jugador() -> void:
	if _caido:
		return          # se cae una sola vez; de ahí se sale levantándose
	_caido = true
	_tumbar(true)
	interfaz.mostrar_caida(api.levantarse)


## Que se vea desde afuera que estás en el piso.
##
## Se inclina la malla entera y no se usa `figura.caer()`: ese apaga la
## animación para siempre y no hay cómo revivirla, y de esta caída se vuelve.
func _tumbar(si: bool) -> void:
	var malla := jugador.get_node_or_null("Malla") as Node3D
	if malla == null:
		return
	var giro := (-PI / 2.0 + 0.15) if si else 0.0
	var hundir := -0.3 if si else 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(malla, "rotation:x", giro, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN if si else Tween.EASE_OUT)
	t.tween_property(malla, "position:y", hundir, 0.45)


## Volvió la respuesta de levantarse. Recién ACÁ se mueve el personaje: si lo
## moviéramos al apretar el botón y el servidor fallara, estarías caminando por
## la aldea mientras la base te tiene tirado en la ruina.
func _al_levantarse(d: Dictionary) -> void:
	var slug: String = str(d.get("lugar", ""))
	if bool(d.get("ok", false)) and LUGARES.has(slug):
		var p: Vector3 = LUGARES[slug]['pos']
		jugador.position = Vector3(p.x, altura_en(p.x, p.z) + 2.0, p.z)
		jugador.velocity = Vector3.ZERO
		# El servidor ya te tiene ahí. Sin anotarlo, _avisar_donde_estoy le
		# mandaría una llegada que no pasó y el director leería un viaje.
		_lugar_actual = slug
		# La caminata de vuelta es el costo y es a propósito: mientras volvés
		# seguís adentro del juego. No se compensa ni se disimula.
		interfaz.avisar("Te levantaste en %s. Hasta donde caíste hay que caminar."
			% LUGARES[slug].get("nombre", slug))
	_levantado_en = Time.get_ticks_msec()
	_caido = false
	_tumbar(false)
	interfaz.ocultar_caida()
	_mostrar_vida(int(d.get("health", _vida)))
	# El mundo pudo haber cambiado mientras estabas en el piso.
	api.pedir_mundo()


func _al_recibir_mundo(datos: Dictionary) -> void:
	var region: Dictionary = datos.get("region", {})
	var yo: Dictionary = datos.get("player", {})
	_mi_nombre = str(yo.get("name", _mi_nombre))
	interfaz.mostrar_region(region, yo)
	_sincronizar_mi_estado(yo)

	# El reloj del valle. Viene del servidor, no de esta máquina: es lo que
	# hace que el atardecer sea el mismo para todos los que estén conectados.
	if ciclo != null:
		ciclo.sincronizar(int(region.get("tick", 0)), float(region.get("momento_del_dia", 0.0)))

	for q in datos.get("people", []):
		var d: Dictionary = q
		_actitudes[str(d.get("name", ""))] = {
			"saludo": str(d.get("saludo", "")),
			"animo": str(d.get("animo", "neutral")),
			"ensena": bool(d.get("ensena", false)),
		}
		_ids_gente[str(d.get("name", ""))] = str(d.get("id", ""))

	_sincronizar_amenazas(datos.get("amenazas", []))
	_sincronizar_jugadores(datos.get("jugadores", []))
	var bolsa: Array = datos.get("objetos", [])
	interfaz.mostrar_inventario(bolsa)
	# La misma bolsa la mira la magia: el frasco de raíz es lo único que hace
	# aparecer la cuarta ranura del ritual de la mañana, y no se pide dos veces.
	if runas != null and is_instance_valid(runas):
		runas.tick = int(region.get("tick", 0))
		runas.mirar_la_bolsa(bolsa)
		# El día en curso es `tick + 1`, que es el que le pasa la web a la
		# simulación: `marcasDe()` devuelve las que llegan hasta ahí o más allá.
		_ubicar_marcas(datos.get("marcas", []), datos.get("places", []),
			int(region.get("tick", 0)) + 1)
	# Lo mejor que llevás va a la mano. Un arma le gana a cualquier otra cosa:
	# es lo que cambia el resultado de una pelea y lo que conviene que se vea.
	var enMano := ""
	var mejor := -1
	for o in bolsa:
		var d: Dictionary = o
		var k: String = str(d.get("kind", ""))
		var puntos: int = int(d.get("quality", 0)) + (1000 if k in ARMAS else 0)
		if puntos > mejor:
			mejor = puntos
			enMano = k
	if jugador != null and jugador.figura != null:
		jugador.figura.empunar(enMano)
	interfaz.mostrar_pasos(datos.get("primeros_pasos", []))
	interfaz.mostrar_ficha(datos.get("vos", {}))
	if mapa != null:
		var marcas: Array = []
		for m in _monstruos:
			if is_instance_valid(m):
				marcas.append({"pos": m.global_position, "nombre": m.nombre_servidor})
		mapa.amenazas = marcas
		var quienes: Array = []
		for nombre: String in _npcs:
			var n2: Node3D = _npcs[nombre]
			if is_instance_valid(n2):
				quienes.append({"pos": n2.global_position, "nombre": nombre})
		mapa.vecinos = quienes
	# La bienvenida necesita la crónica: se pide una sola vez, al entrar.
	if not _ya_pedimos_cronica:
		_ya_pedimos_cronica = true
		api.pedir_cronica()

	_sincronizar_gente(datos.get("people", []), datos.get("places", []))


## A qué le puede apuntar un hechizo ahora mismo.
##
## Este archivo es el único que sabe qué hay en la escena, así que es el que
## arma la lista; `runas.gd` sólo la proyecta a la pantalla y elige lo que quedó
## más cerca del cursor al soltar. Tres cauces salen de acá y el cuarto —el
## suelo— no está en la lista a propósito: es lo que queda cuando no hay nada
## más, y por eso nunca te quedás sin adónde tirar.
##
## **Los otros jugadores no entran, y no es un olvido.** `/mundo` manda a los
## jugadores por nombre y sin uuid, y `/lanzar` con `blanco=jugador` sólo
## resuelve por uuid; sin ese dato, apuntarle a otro sería mandar un POST que
## vuelve "no hay ningún jugador ahí". El cauce `jugador` existe igual y es el
## que te apunta A VOS, que es el que cura.
func _blancos_de_magia() -> Array:
	var lista: Array = []
	for m in _monstruos:
		if not is_instance_valid(m) or m.vida <= 0:
			continue
		lista.append({
			"tipo": "amenaza", "id": m.id_servidor,
			"nombre": m.nombre_servidor, "nodo": m,
		})
	for nombre: String in _npcs:
		var n: Node3D = _npcs[nombre]
		if not is_instance_valid(n):
			continue
		lista.append({
			"tipo": "persona", "id": str(_ids_gente.get(nombre, nombre)),
			"nombre": nombre, "nodo": n,
		})
	if jugador != null and is_instance_valid(jugador) and not _caido:
		lista.append({"tipo": "jugador", "id": "", "nombre": "vos", "nodo": jugador})
	return lista


## Dónde cae cada cicatriz que dejó la magia.
##
## El servidor manda la marca con el `place_id`; el que sabe en qué punto del
## mundo está ese lugar es este archivo, así que la ubicación se resuelve acá y
## `runas.gd` recibe la posición ya hecha. Las marcas sobre un cuerpo —una
## quemadura que alguien se lleva puesta— no se dibujan en el suelo: viajan con
## la persona y el servidor ya las cuenta.
func _ubicar_marcas(marcas: Array, lugares: Array, hoy: int) -> void:
	var slug_por_id := {}
	for p in lugares:
		var lp: Dictionary = p
		slug_por_id[str(lp.get("id", ""))] = str(lp.get("slug", ""))

	var lista: Array = []
	for m in marcas:
		var d: Dictionary = m
		if str(d.get("sobre_kind", "")) != "place":
			continue
		var slug: String = slug_por_id.get(str(d.get("place_id", "")), "")
		if not LUGARES.has(slug):
			continue
		var centro: Vector3 = LUGARES[slug]["pos"]
		lista.append({
			"id": str(d.get("id", "")),
			"kind": str(d.get("kind", "ardor")),
			"por": str(d.get("por", "")),
			"dias": maxi(0, int(d.get("hasta_tick", 0)) - hoy),
			"lugar": str(LUGARES[slug].get("nombre", slug)),
			"pos": Vector3(centro.x, altura_en(centro.x, centro.z), centro.z),
		})
	runas.mostrar_marcas(lista)


## Cómo estás, según el mundo. Esta es la fuente de verdad de la vida: si te
## bajaron desde otra sesión tuya, o si un golpe se perdió en el camino, acá te
## enterás y la barra se acomoda sola.
func _sincronizar_mi_estado(yo: Dictionary) -> void:
	if yo.is_empty():
		return
	# Un /mundo pedido antes de levantarte puede llegar después y todavía verte
	# tirado. Sin esta ventana el panel de caída reaparece solo, ya de pie.
	if Time.get_ticks_msec() - _levantado_en < 4000:
		return
	_vida_maxima = maxi(1, int(yo.get("max_health", _vida_maxima)))
	_mostrar_vida(int(yo.get("health", _vida)))
	if bool(yo.get("caido", false)):
		_caer_jugador()
	elif _caido:
		# Estabas caído y el mundo dice que no: te levantaron por otro lado.
		_caido = false
		_tumbar(false)
		interfaz.ocultar_caida()


const ALTO_CARTEL := 2.35
## Dónde queda el nombre cuando el cuerpo está en el piso. No se apaga: el
## cartel es lo único que a 27 m dice de quién es ese bulto.
const ALTO_CARTEL_CAIDO := 1.05

func _cartel(texto: String, color := Paleta.UI_TEXTO) -> Node3D:
	var l := Label3D.new()
	l.name = "Cartel"
	l.text = texto
	l.font_size = 44
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = ALTO_CARTEL
	l.modulate = color
	l.outline_size = 14
	l.outline_modulate = Paleta.CARTEL_BORDE
	l.no_depth_test = false
	return l


func _process(dt: float) -> void:
	if jugador == null:
		return
	# La gente anda por su lugar. Va en `_process()` y no en `animar()` porque a
	# los NPC nadie les llamaba `animar()` nunca: el sistema de caminata de
	# `figura.gd` estaba entero y sin usar, y por eso eran maniquíes.
	_mover_gente(dt)

	# ¿Estás adentro de una casa? Si sí, a esa casa se le sacan el techo, la
	# planta alta y los muros que la cámara tiene delante. Necesita la cámara y
	# no sólo tu posición: qué muro tapa depende de desde dónde se mira.
	if interiores != null:
		interiores.actualizar(jugador.global_position,
			_camara.global_position if _camara != null else jugador.global_position)

	# ¿A quién tengo al lado? Es lo que habilita hablar con E.
	var mas_cerca := ""
	var d_min := 4.5
	for nombre: String in _npcs:
		var n: Node3D = _npcs[nombre]
		var d := n.global_position.distance_to(jugador.global_position)
		if d < d_min:
			d_min = d
			mas_cerca = nombre
	interfaz.mostrar_cercano(mas_cerca, _npcs.get(mas_cerca, null))

	# Y qué bicho. En la base las amenazas tienen nombre propio y pueblo
	# —"Kerrak el que quedó", de "Los del Sotobosque"— y en pantalla eran bultos
	# genéricos: el dato ya viajaba en `/mundo` y moría en `nombre_servidor`.
	# Diez metros y no los 4,5 de la gente: al bicho no te le acercás a hablar,
	# lo ves venir. `interfaz.mostrar_amenaza()` ya estaba escrito y sin llamar.
	var bicho := ""
	var nodo_bicho: Node3D = null
	var d_bicho := ALCANCE_CARTEL_AMENAZA
	for m in _monstruos:
		if not is_instance_valid(m) or m.vida <= 0:
			continue
		var d := m.global_position.distance_to(jugador.global_position)
		if d < d_bicho:
			d_bicho = d
			bicho = m.nombre_servidor
			nodo_bicho = m
	interfaz.mostrar_amenaza(bicho, nodo_bicho)

	# Que te reconozcan al pasar. Una sola vez por acercamiento: si se
	# disparara cada cuadro sería un cartel, y si no se reseteara al alejarte
	# nunca te volverían a saludar. Por eso se limpia cuando te vas.
	# Una espera antes de volver a saludarte. Antes alcanzaba con alejarse y
	# volver, así que caminando por la aldea te saludaban en bucle: el mismo
	# recurso que hace que el valle parezca habitado lo volvía insoportable.
	# La gente que ya te vio hace un rato no te vuelve a levantar la vista.
	var ahora := Time.get_ticks_msec() / 1000.0
	if mas_cerca != "" and ahora - float(_ya_saludo.get(mas_cerca, -999.0)) > ESPERA_SALUDO:
		_ya_saludo[mas_cerca] = ahora
		var a: Dictionary = _actitudes.get(mas_cerca, {})
		var linea: String = str(a.get("saludo", ""))
		if linea != "":
			interfaz.reconocer(linea, str(a.get("animo", "neutral")))

	_avisar_donde_estoy()


## En qué lugar estás parado, según a cuál estés más cerca.
##
## Se manda al servidor SÓLO cuando cambia. Sin esto el mundo no se entera de
## que caminaste: aprender y enseñar exigen que el otro esté en tu lugar, los
## bichos muerden a quien está ahí, y los testigos de lo que hacés son los que
## están ahí. Caminar sin reportar es caminar en una postal.
func _avisar_donde_estoy() -> void:
	var yo := Vector2(jugador.global_position.x, jugador.global_position.z)
	var cerca := ""
	var d_min := ENTRAR
	for slug: String in LUGARES:
		var d: float = yo.distance_to(
			Vector2(LUGARES[slug]['pos'].x, LUGARES[slug]['pos'].z))
		if d < d_min:
			d_min = d
			cerca = slug

	# Histéresis: para ENTRAR hay que acercarse, para SALIR hay que alejarse
	# bastante más. Sin esto, parado en el borde entre dos lugares el juego
	# oscila y le manda una llegada al servidor por cuadro. Ya pasó: siete
	# eventos "llegó a" en un solo tick, y esos eventos los lee el director,
	# que es lo único que este proyecto está midiendo.
	if _lugar_actual != "":
		var d_viejo: float = yo.distance_to(Vector2(
			LUGARES[_lugar_actual]['pos'].x, LUGARES[_lugar_actual]['pos'].z))
		if d_viejo < SALIR:
			return          # seguís donde estabas hasta salir de verdad

	if cerca != "" and cerca != _lugar_actual:
		_lugar_actual = cerca
		api.estoy_en(cerca)
		interfaz.lugar_da = LO_QUE_SE_JUNTA.get(cerca, "")
		interfaz.avisar("Llegaste a %s." % LUGARES[cerca].get("nombre", cerca))


## Apretaste E. Se abre la conversación EN EL ACTO con lo que ya sabemos que
## esa persona diría, y la respuesta del modelo la reemplaza cuando llega.
##
## Sin esto hay un segundo largo de nada entre el botón y la pantalla, y ese
## silencio es lo que hace sentir que el juego colgó. Los saludos guardados
## existen justo para esto: están escritos en la voz de cada uno, así que lo
## que ves mientras esperás no es un cartel de carga, es la persona mirándote.
func _al_interactuar() -> void:
	if _caido:
		return          # desde el piso no se conversa
	var quien: String = interfaz.npc_cercano
	if quien == "":
		return
	var a: Dictionary = _actitudes.get(quien, {})
	interfaz.abrir_charla(quien, str(a.get("saludo", "")), str(a.get("animo", "neutral")))
	api.hablar(quien)


## El alcance del golpe. Estaba en 3,2 m y era imposible: con la cámara a 40
## metros no ves la diferencia entre 3 y 5, así que el jugador aprieta y no
## pasa nada, que es el peor resultado posible. Un juego que se ve de lejos
## necesita un alcance generoso o se siente roto.
## Lo que cuenta como arma. Espeja la lista del servidor, que es quien decide
## el daño; acá sólo sirve para elegir qué se te ve en la mano.
const ARMAS := ["hoja templada", "filo de agua"]

## Hasta dónde se le pone el cartel a una amenaza. Más que el alcance del golpe
## a propósito: el cartel tiene que aparecer ANTES de que puedas pegarle, o te
## enterás de a quién estás matando después de haberlo matado.
const ALCANCE_CARTEL_AMENAZA := 10.0

const ALCANCE_JUGADOR := 6.5
const DANIO_JUGADOR := 14

func _al_golpear() -> void:
	# Caído no se pega. El clic no pasa por el filtro de _jugador_sin_control
	# —ese sólo corta el teclado—, así que el corte va acá.
	if _caido:
		return
	jugador.amagar_golpe()

	# Al MÁS CERCA de los que están en alcance, no al primero de la lista. El
	# orden del array no tiene nada que ver con lo que el jugador está mirando,
	# y pegarle a uno que está detrás tuyo se siente un bug aunque no lo sea.
	var elegido: Monstruo = null
	var mejor := ALCANCE_JUGADOR
	for m in _monstruos:
		if not is_instance_valid(m) or m.vida <= 0:
			continue
		var d := m.global_position.distance_to(jugador.global_position)
		if d < mejor:
			mejor = d
			elegido = m

	if elegido == null:
		# Decirle que no llegó. El silencio es lo que hace que parezca roto:
		# el jugador no sabe si falló, si el botón no anda, o si el bicho es
		# decorado.
		var lejos: Monstruo = null
		var d_lejos := 40.0
		for m in _monstruos:
			if is_instance_valid(m) and m.vida > 0:
				var d := m.global_position.distance_to(jugador.global_position)
				if d < d_lejos:
					d_lejos = d
					lejos = m
		if lejos != null:
			interfaz.avisar("Estás lejos de %s." % lejos.nombre_servidor)
		return

	# Se muestra el golpe YA y se le avisa al servidor en paralelo. Esperar la
	# respuesta para reaccionar mete 200 ms entre el clic y el efecto, y eso
	# alcanza para que se sienta roto. Cuando llega la respuesta se corrige la
	# vida con la del servidor, que es la que vale.
	elegido.doler_ahora()
	if elegido.id_servidor != "":
		api.pelear(elegido.id_servidor)


## Captura de verificación: `--captura` guarda un PNG y sale. Sirve para
## chequear el look sin abrir el editor.
func _captura_si_corresponde() -> void:
	if not OS.get_cmdline_user_args().has("--captura"):
		return
	await get_tree().create_timer(3.5).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://captura.png")
	print("captura guardada")
	get_tree().quit()


## La cordillera del horizonte, con una abertura al norte.
##
## No es adorno: es lo que contesta "¿y más allá qué hay?". Un valle que se
## termina en niebla se siente un nivel; un valle cercado por montañas con UNA
## salida se siente un lugar, y esa salida es El Camino del Norte, que ya
## existe en el servidor. Cuando el mundo crezca, crece por ahí.
func _armar_cordillera() -> void:
	var cresta := FastNoiseLite.new()
	cresta.noise_type = FastNoiseLite.TYPE_SIMPLEX
	cresta.frequency = 0.9
	cresta.fractal_octaves = 4

	var vueltas := 190
	var anillos := 7
	var r0 := 300.0
	var r1 := 620.0

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Devuelve el punto de la montaña para un ángulo y un anillo.
	var punto := func(i: int, j: int) -> Vector3:
		var a := float(i) / vueltas * TAU
		var t := float(j) / anillos
		var r: float = lerp(r0, r1, t)
		# La abertura: al norte (+Z) la montaña se hunde hasta el suelo.
		var hacia_norte := (Vector2(sin(a), cos(a)).dot(Vector2(0.12, 1.0).normalized()) + 1.0) * 0.5
		var portal: float = smoothstep(0.86, 0.995, hacia_norte)
		# Cresta: valor absoluto del ruido invertido, que es lo que hace filos
		# en vez de lomas. Una montaña con lomas parece un almohadón.
		var n: float = 1.0 - absf(cresta.get_noise_2d(cos(a) * 24.0, sin(a) * 24.0))
		var n2: float = 1.0 - absf(cresta.get_noise_2d(cos(a) * 61.0 + 90.0, sin(a) * 61.0))
		var alto: float = (n * 46.0 + n2 * 17.0) * (0.35 + t * 1.25) * (1.0 - portal * 0.97)
		return Vector3(sin(a) * r, alto - 6.0, cos(a) * r)

	for j in anillos:
		for i in vueltas:
			var i2 := (i + 1) % vueltas
			var p := [punto.call(i, j), punto.call(i2, j),
				punto.call(i2, j + 1), punto.call(i, j + 1)]
			for tri: Array in [[0, 1, 2], [0, 2, 3]]:
				for k: int in tri:
					var v: Vector3 = p[k]
					# Más alto = más pelado y más frío. Abajo, bosque oscuro.
					var h: float = clampf(v.y / 48.0, 0.0, 1.0)
					# Del bosque oscuro de la base (V2) a la roca pelada de
					# arriba (V6), y todo lerpeado 0.45 hacia MONTE_AIRE: la
					# distancia lava el color y lo enfría. La cordillera es el
					# marco del cuadro, así que abarca la escalera entera menos
					# las puntas.
					var c := Paleta.MONTE_BAJO.lerp(Paleta.MONTE_ALTO, h * h)
					st.set_color(c.lerp(Paleta.MONTE_AIRE, 0.45))
					st.add_vertex(v)

	st.generate_normals()
	var mat := Paleta.monte()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	# Sin colisión y sin sombras: está detrás de la niebla, nadie la pisa y
	# proyectar sombras desde 300 metros sólo cuesta.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Lo que dijo el servidor del golpe. La vida que vale es la de él.
func _al_resultado_de_pelea(d: Dictionary) -> void:
	if not d.get("ok", false):
		return
	if d.get("muerta", false):
		interfaz.avisar("Cayó uno.")
	# Volvemos a pedir el mundo: puede haber cambiado más de lo que sabemos —
	# otro jugador pudo haber matado algo mientras tanto.
	api.pedir_mundo()


## El mundo se refresca solo cada tanto: es multijugador, pasan cosas que no
## hiciste vos. Cada 12 segundos alcanza y no castiga al servidor.
func _refrescar_cada_tanto() -> void:
	while true:
		await get_tree().create_timer(12.0).timeout
		if api != null and api.token != "":
			api.pedir_mundo()


## M abre el mapa. Hizo falta apenas el valle dejó de verse de un vistazo.
func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo:
		var k := (evento as InputEventKey).keycode
		if k == KEY_M and not interfaz.escribiendo():
			mapa.alternar()
			get_viewport().set_input_as_handled()



