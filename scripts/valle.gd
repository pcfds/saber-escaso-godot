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
const LUGARES := {
	"aldea":  {"pos": Vector3(0, 0, 0),      "color": Color(0.55, 0.48, 0.37), "casas": 7, "nombre": "Vado Bajo"},
	"fragua": {"pos": Vector3(62, 0, -18),   "color": Color(0.49, 0.33, 0.26), "casas": 2, "nombre": "La Fragua de Ilde"},
	"bosque": {"pos": Vector3(-58, 0, -54),  "color": Color(0.18, 0.29, 0.20), "casas": 0, "nombre": "El Sotobosque"},
	"ruina":  {"pos": Vector3(-26, 0, -108), "color": Color(0.29, 0.28, 0.25), "casas": 3, "nombre": "La Casa Quemada"},
	"camino": {"pos": Vector3(11, 0, 74),    "color": Color(0.42, 0.38, 0.32), "casas": 0, "nombre": "El Camino del Norte"},
}

const RADIO_VALLE := 165.0

## El color de la gente de carne y hueso: vos y los otros jugadores. Estaba
## suelto como literal en el cuerpo del jugador; ahora tiene nombre porque lo
## comparten dos lados y esa coincidencia **es la señal**, no una casualidad.
## Un habitante del valle es gris (ver los NPC más abajo); alguien que está del
## otro lado de una pantalla tiene tu color y tu altura.
const COLOR_JUGADOR := Color(0.30, 0.72, 0.62)
const ALTURA_JUGADOR := 1.85

## Distancias para decidir en qué lugar estás. SALIR es más grande que ENTRAR
## a propósito — ver la histéresis en _avisar_donde_estoy().
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
var sonido: Sonido
var _lugar_actual := ""
var _monstruos_por_id: Dictionary = {}
## Cómo te trata cada uno al pasar. Lo manda el servidor con /mundo.
var _actitudes: Dictionary = {}
var _ya_saludo: Dictionary = {}
var mapa: Mapa
var _ya_pedimos_cronica := false

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
	for slug: String in LUGARES:
		_armar_lugar(slug, LUGARES[slug])

	# La vegetación de verdad, a la escala del valle. Antes eran 46 árboles
	# apretados en 13 metros de un mapa de 360: el problema nunca fue que
	# faltaran árboles, fue que nunca escalaron cuando el mapa creció 2,7×.
	vegetacion = Vegetacion.new()
	add_child(vegetacion)
	vegetacion.poblar(altura_en, LUGARES)

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

	# El lecho de ambiente. Va último a propósito: un error acá no puede
	# llevarse puesto nada de lo de arriba, y en este archivo ya pasó una vez
	# que un error en `_ready()` abortó la función entera y el juego arrancó
	# sin HUD y sin API.
	#
	# Se sintetiza al arrancar: cero bytes en disco y cero en la descarga. Los
	# buses de audio se crean en tiempo de ejecución, así que no hay nada que
	# registrar en `project.godot`.
	var sonido := Sonido.new()
	add_child(sonido)
	sonido.ciclo = ciclo
	sonido.oyente = jugador
	sonido.preparar(LUGARES)

	# El valle suena. Va acá y no antes porque necesita el ciclo para saber la
	# hora: el lecho de ambiente cambia con el lugar Y con el momento del día.
	sonido = Sonido.new()
	sonido.ciclo = ciclo
	add_child(sonido)
	sonido.preparar(LUGARES)
	if jugador != null:
		sonido.oyente = jugador

	_refrescar_cada_tanto()
	_captura_si_corresponde()
	_ANDAMIO_ronda()

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
	sol.light_color = Color(1.0, 0.82, 0.62)
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
	relleno.light_color = Color(0.55, 0.68, 0.88)
	relleno.light_energy = 0.22
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

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.46, 0.30)
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.97
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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
func _color_terreno(p: Vector3, n: Vector3) -> Color:
	var pasto := Color(0.52, 0.72, 0.44)
	var pasto_seco := Color(0.86, 0.78, 0.52)
	var tierra := Color(0.72, 0.55, 0.38)
	var roca := Color(0.78, 0.78, 0.76)

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
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.20, 0.24, 0.86)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.06
	mat.metallic = 0.35
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.11, 0.14)
	mat.emission_energy_multiplier = 0.25
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

	if slug == "bosque":
		_armar_bosque(g, color)
		return
	if slug == "camino":
		_armar_camino(g, color)
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92

	var techo_mat := StandardMaterial3D.new()
	techo_mat.albedo_color = Color(0.19, 0.11, 0.09)
	techo_mat.roughness = 0.95

	var n: int = def["casas"]
	var huellas: Array[Vector2] = []
	_casas[slug] = huellas
	for i in n:
		var a := TAU * i / float(n) + 0.4
		var r := 5.0 if n > 3 else 2.6
		var h := randf_range(2.4, 3.6)
		var px := cos(a) * r
		var pz := sin(a) * r
		var py := altura_en(base.x + px, base.z + pz) - base.y
		# Para la ronda de la gente: acá hay una casa y no se atraviesa.
		huellas.append(Vector2(base.x + px, base.z + pz))

		var caja := BoxMesh.new()
		caja.size = Vector3(2.7, h, 2.5)
		caja.material = mat
		var casa := MeshInstance3D.new()
		casa.mesh = caja
		casa.position = Vector3(px, py + h / 2.0, pz)
		casa.rotation.y = a + randf_range(-0.2, 0.2)
		Detalles.ventanas_y_puerta(casa, 2.7, h)
		g.add_child(casa)

		var col := StaticBody3D.new()
		var cf := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = caja.size
		cf.shape = bs
		col.add_child(cf)
		col.position = casa.position
		col.rotation.y = casa.rotation.y
		g.add_child(col)

		if slug != "ruina":
			Detalles.chimenea(g, Vector3(px + 0.85, py + h + 1.25, pz - 0.65), 2.7)
			var cono := CylinderMesh.new()
			cono.top_radius = 0.0
			cono.bottom_radius = 2.35
			cono.height = 1.7
			cono.radial_segments = 4
			cono.material = techo_mat
			var techo := MeshInstance3D.new()
			techo.mesh = cono
			techo.position = Vector3(px, py + h + 0.82, pz)
			techo.rotation.y = casa.rotation.y + PI / 4.0
			g.add_child(techo)

	if slug == "fragua":
		_armar_fuego(g)
	if slug == "aldea":
		_armar_faroles(g)


func _armar_fuego(g: Node3D) -> void:
	# La fragua es el punto cálido del valle. La luz parpadeante contra la
	# niebla volumétrica es, sola, la mejor postal que tiene el juego.
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.52, 0.18)
	luz.light_energy = 9.0
	luz.omni_range = 26.0
	luz.shadow_enabled = true
	luz.position = Vector3(0, 2.0, 0)
	luz.set_script(preload("res://scripts/parpadeo.gd"))
	g.add_child(luz)

	var brasa := SphereMesh.new()
	brasa.radius = 0.55
	brasa.height = 1.1
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(1.0, 0.42, 0.10)
	bm.emission_enabled = true
	bm.emission = Color(1.0, 0.45, 0.12)
	bm.emission_energy_multiplier = 7.0
	brasa.material = bm
	var mi := MeshInstance3D.new()
	mi.mesh = brasa
	mi.position = Vector3(0, 1.1, 0)
	g.add_child(mi)


func _armar_faroles(g: Node3D) -> void:
	for i in 4:
		var a := TAU * i / 4.0 + 0.8
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.75, 0.45)
		luz.light_energy = 3.2
		luz.omni_range = 12.0
		luz.position = Vector3(cos(a) * 8.0, 3.0, sin(a) * 8.0)
		luz.set_script(preload("res://scripts/parpadeo.gd"))
		g.add_child(luz)


func _armar_bosque(g: Node3D, color: Color) -> void:
	var tronco_mat := StandardMaterial3D.new()
	tronco_mat.albedo_color = Color(0.20, 0.14, 0.10)
	tronco_mat.roughness = 1.0
	var copa_mat := StandardMaterial3D.new()
	copa_mat.albedo_color = color
	copa_mat.roughness = 0.98

	for i in 46:
		var a := randf() * TAU
		var r := randf_range(2.0, 13.0)
		var px := cos(a) * r
		var pz := sin(a) * r
		var py := altura_en(g.position.x + px, g.position.z + pz) - g.position.y
		var h := randf_range(4.5, 9.0)

		var cil := CylinderMesh.new()
		cil.top_radius = 0.16
		cil.bottom_radius = 0.30
		cil.height = h * 0.42
		cil.radial_segments = 6
		cil.material = tronco_mat
		var tronco := MeshInstance3D.new()
		tronco.mesh = cil
		tronco.position = Vector3(px, py + h * 0.21, pz)
		g.add_child(tronco)

		var cono := CylinderMesh.new()
		cono.top_radius = 0.0
		cono.bottom_radius = randf_range(1.3, 2.1)
		cono.height = h * 0.78
		cono.radial_segments = 7
		cono.material = copa_mat
		var copa := MeshInstance3D.new()
		copa.mesh = cono
		copa.position = Vector3(px, py + h * 0.42 + h * 0.39, pz)
		g.add_child(copa)


func _armar_camino(g: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
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

## El anillo donde se para la gente del lugar. Los otros jugadores van de 7,5 a
## 12 m (ver `_punto_de`) y las casas de la aldea están a 5 m: 6,5 es el hueco.
const ANILLO_GENTE := 6.5
## Cuánto ocupa una casa. La caja mide 2,7 × 2,5, o sea 1,84 m de semidiagonal;
## el resto es el cuerpo de la persona más un margen para no rozar la pared.
const CASA_RADIO := 2.3
## Hasta dónde puede llegar alguien haciendo su ronda, medido desde el centro
## del lugar. **Los dos números de arriba están elegidos para que este límite
## alcance:** una casa de la aldea está a 5,0 m y empuja hasta 5,0 + 2,3 = 7,3,
## que es justo esto, y esto es justo lo que queda por debajo del 7,5 donde
## empiezan a pararse los otros jugadores. Nadie se mete en una casa, nadie se
## va de su lugar y nadie se le sube a nadie.
const RONDA_LIMITE := 7.3

## La forma de una ronda. Todo esto sale del nombre y NADA de la máquina.
const RONDA_TANGENTE := 1.9    ## cuánto se corre a lo largo del anillo
const RONDA_ADENTRO := 1.6     ## cuánto se mete hacia el centro del lugar
const RONDA_AFUERA := 0.85     ## y cuánto se aleja (poco: ahí está el límite)
const RONDA_MIRADA := 1.0      ## desvío máximo, en radianes, de mirar al centro
const RONDA_PASO := 0.95       ## m/s. Paso de andar por su lugar, no de ir a algún lado.
const RONDA_QUIETO_MIN := 1.8  ## segundos parado en una parada
const RONDA_QUIETO_MAX := 7.0
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

	var vistos := {}
	for slug: String in por_lugar:
		var lista: Array = por_lugar[slug]
		var centro: Vector3 = LUGARES[slug]["pos"]
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
				centro.x + cos(a) * ANILLO_GENTE, centro.z + sin(a) * ANILLO_GENTE))
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


func _armar_vecino(nombre: String, oficio: String) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = "vecino_" + nombre.validate_node_name()
	# Van ANTES de colgar la figura: su `_ready()` las lee del padre para
	# sacarse el cuerpo del hash del nombre.
	nodo.set_meta("nombre", nombre)
	nodo.set_meta("oficio", oficio)
	var fig := _figura(Color(0.56, 0.60, 0.64), 1.72, false)
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

	# Los dos límites, en este orden: primero no salirse del lugar, después no
	# estar adentro de una casa. Al revés, el recorte por el lugar podría volver
	# a meter a alguien contra una pared.
	var fuera := p - centro
	if fuera.length() > RONDA_LIMITE:
		p = centro + fuera.normalized() * RONDA_LIMITE
	p = _afuera_de_casas(slug, p)

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
		# darse vuelta del todo.
		cuerpo.rotation.y = lerp_angle(cuerpo.rotation.y, rumbo, minf(1.0, 3.5 * dt))
		# El único lugar donde el nivel de calidad puede meterse: la ronda misma
		# NO puede depender de él —es la identidad de la persona y tiene que dar
		# igual en las tres máquinas— pero dibujar la zancada de alguien que está
		# a cien metros sí es opcional. A 90 m un paso mide cinco píxeles, y ahí
		# ya está detrás del desenfoque de lejanía y de la niebla.
		if p.distance_squared_to(yo) < _ANIMAR_HASTA[Rendimiento.nivel]:
			cuerpo.animar(dt, vel, true)


## Hasta dónde se le anima la caminata a alguien, al cuadrado (bajo/medio/alto).
const _ANIMAR_HASTA: Array[float] = [3600.0, 6400.0, 12100.0]


## Empuja un punto fuera de la huella de las casas del lugar.
##
## Es lo que deja calcular la ronda libre y sin caminos: la trayectoria pasa
## por donde quiera y acá se la desvía, así que rodear una casa sale solo. Y
## como la velocidad se mide del desplazamiento real, el rodeo se camina.
func _afuera_de_casas(slug: String, p: Vector2) -> Vector2:
	for c: Vector2 in _casas.get(slug, []):
		var d := p - c
		var l := d.length()
		if l < CASA_RADIO:
			# Justo en el centro de la casa no hay hacia dónde empujar; cualquier
			# dirección sirve y esto no pasa nunca, pero dividir por cero sí.
			d = Vector2(0.0, 1.0) if l < 0.001 else d / l
			p = c + d * CASA_RADIO
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


## ANDAMIO TEMPORAL — se borra.
func _ANDAMIO_ronda() -> void:
	if not OS.get_cmdline_user_args().has("--ronda"):
		return
	await get_tree().create_timer(4.0).timeout
	print("=== TABLA (misma persona, mismo t del valle -> mismo punto) ===")
	for nombre: String in _npcs:
		var linea := "%-22s" % nombre
		for t in [0, 7, 14, 21, 28, 35, 42, 49]:
			var r := _ronda_punto(nombre, float(t))
			linea += " (%+.3f,%+.3f,%+.2f)" % [r.x, r.y, r.z]
		print(linea)
		var ro := _ronda(nombre)
		print("    periodo %.0fs  desfase %.2f  paradas %d  cortes %s"
			% [ro["periodo"], ro["desfase"], (ro["paradas"] as PackedVector2Array).size(),
			str(ro["cortes"])])
	print("=== EN VIVO (pos del mundo, dist al centro del lugar, a la casa mas cerca) ===")
	for paso in 14:
		var s := "t=%5.1f " % (Time.get_ticks_msec() / 1000.0)
		for nombre: String in _npcs:
			var n: Node3D = _npcs[nombre]
			var slug := str(n.get_meta("lugar", ""))
			var c: Vector3 = LUGARES[slug]["pos"]
			var p := Vector2(n.position.x, n.position.z)
			var dcasa := 99.0
			for casa: Vector2 in _casas.get(slug, []):
				dcasa = minf(dcasa, p.distance_to(casa))
			s += "| %s %s x%+8.3f z%+8.3f r%5.2f casa%5.2f giro%+.2f " % [
				nombre.substr(0, 10), slug, p.x, p.y,
				p.distance_to(Vector2(c.x, c.z)), dcasa,
				(n.get_node(^"Cuerpo") as Node3D).rotation.y]
		print(s)
		await get_tree().create_timer(2.0).timeout
	print("=== FIN ANDAMIO ===")
	get_tree().quit()


## Mientras devuelva true, el teclado no es del personaje. Dos motivos, y los
## dos son estados en los que caminar sería raro: le estás escribiendo a
## alguien, o estás tirado en el piso. Pegar se corta aparte (en _al_golpear)
## porque es un clic, y el clic no pasa por este filtro.
func _jugador_sin_control() -> bool:
	return _caido or interfaz.escribiendo()


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

	_sincronizar_amenazas(datos.get("amenazas", []))
	_sincronizar_jugadores(datos.get("jugadores", []))
	interfaz.mostrar_inventario(datos.get("objetos", []))
	interfaz.mostrar_pasos(datos.get("primeros_pasos", []))
	if mapa != null:
		var marcas: Array = []
		for m in _monstruos:
			if is_instance_valid(m):
				marcas.append({"pos": m.global_position, "nombre": m.nombre_servidor})
		mapa.amenazas = marcas
	# La bienvenida necesita la crónica: se pide una sola vez, al entrar.
	if not _ya_pedimos_cronica:
		_ya_pedimos_cronica = true
		api.pedir_cronica()

	_sincronizar_gente(datos.get("people", []), datos.get("places", []))


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

func _cartel(texto: String, color := Color(0.88, 0.92, 0.89)) -> Node3D:
	var l := Label3D.new()
	l.name = "Cartel"
	l.text = texto
	l.font_size = 44
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = ALTO_CARTEL
	l.modulate = color
	l.outline_size = 14
	l.outline_modulate = Color(0.04, 0.06, 0.06, 0.85)
	l.no_depth_test = false
	return l


func _process(dt: float) -> void:
	if jugador == null:
		return
	# La gente anda por su lugar. Va en `_process()` y no en `animar()` porque a
	# los NPC nadie les llamaba `animar()` nunca: el sistema de caminata de
	# `figura.gd` estaba entero y sin usar, y por eso eran maniquíes.
	_mover_gente(dt)

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

	# Que te reconozcan al pasar. Una sola vez por acercamiento: si se
	# disparara cada cuadro sería un cartel, y si no se reseteara al alejarte
	# nunca te volverían a saludar. Por eso se limpia cuando te vas.
	if mas_cerca != "" and not _ya_saludo.has(mas_cerca):
		_ya_saludo[mas_cerca] = true
		var a: Dictionary = _actitudes.get(mas_cerca, {})
		var linea: String = str(a.get("saludo", ""))
		if linea != "":
			interfaz.reconocer(linea, str(a.get("animo", "neutral")))
	for quien: String in _ya_saludo.keys():
		if quien != mas_cerca:
			_ya_saludo.erase(quien)

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
		interfaz.avisar("Llegaste a %s." % LUGARES[cerca].get("nombre", cerca))


func _al_interactuar() -> void:
	if _caido:
		return          # desde el piso no se conversa
	var quien: String = interfaz.npc_cercano
	if quien != "":
		api.hablar(quien)


const ALCANCE_JUGADOR := 3.2
const DANIO_JUGADOR := 14

func _al_golpear() -> void:
	# Caído no se pega. El clic no pasa por el filtro de _jugador_sin_control
	# —ese sólo corta el teclado—, así que el corte va acá.
	if _caido:
		return
	jugador.amagar_golpe()
	for m in _monstruos:
		if not is_instance_valid(m):
			continue
		if m.global_position.distance_to(jugador.global_position) >= ALCANCE_JUGADOR:
			continue
		# Se muestra el golpe YA y se le avisa al servidor en paralelo. Esperar
		# la respuesta para reaccionar mete 200 ms entre el clic y el efecto, y
		# eso alcanza para que se sienta roto. Cuando llega la respuesta se
		# corrige la vida con la del servidor, que es la que vale.
		m.doler_ahora()
		if m.id_servidor != "":
			api.pelear(m.id_servidor)
		return


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
					var c := Color(0.13, 0.17, 0.17).lerp(Color(0.62, 0.66, 0.74), h * h)
					st.set_color(c.lerp(Color(0.36, 0.44, 0.56), 0.45))
					st.add_vertex(v)

	st.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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
