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

## Distancias para decidir en qué lugar estás. SALIR es más grande que ENTRAR
## a propósito — ver la histéresis en _avisar_donde_estoy().
const ENTRAR := 30.0
const SALIR := 44.0

var api: Api
var jugador: Jugador
var interfaz: CanvasLayer

var _ruido := FastNoiseLite.new()
var _npcs: Dictionary = {}
var _monstruos: Array[Monstruo] = []
var ciclo: Ciclo
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

	_refrescar_cada_tanto()
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
	for i in n:
		var a := TAU * i / float(n) + 0.4
		var r := 5.0 if n > 3 else 2.6
		var h := randf_range(2.4, 3.6)
		var px := cos(a) * r
		var pz := sin(a) * r
		var py := altura_en(base.x + px, base.z + pz) - base.y

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
	var fig := _figura(Color(0.30, 0.72, 0.62), 1.85, true)
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

	var lugares_por_id := {}
	for p: Dictionary in datos.get("places", []):
		lugares_por_id[p["id"]] = p

	# Rehacer los NPCs. Son pocos; no vale la pena diferenciar.
	for n: Node3D in _npcs.values():
		n.queue_free()
	_npcs.clear()

	var por_lugar := {}
	for p: Dictionary in datos.get("people", []):
		var pid: String = p.get("place_id", "")
		if not por_lugar.has(pid):
			por_lugar[pid] = []
		por_lugar[pid].append(p)

	for pid: String in por_lugar:
		var lug: Dictionary = lugares_por_id.get(pid, {})
		var slug: String = lug.get("slug", "")
		if not LUGARES.has(slug):
			continue
		var centro: Vector3 = LUGARES[slug]["pos"]
		var lista: Array = por_lugar[pid]
		for i in lista.size():
			var persona: Dictionary = lista[i]
			var a := TAU * i / maxf(lista.size(), 3.0) + 0.7
			var px := centro.x + cos(a) * 6.5
			var pz := centro.z + sin(a) * 6.5
			var nodo := Node3D.new()
			nodo.position = Vector3(px, altura_en(px, pz), pz)
			nodo.add_child(_figura(Color(0.56, 0.60, 0.64), 1.72, false))
			nodo.add_child(_cartel(persona.get("name", "?")))
			nodo.set_meta("nombre", persona.get("name", "?"))
			nodo.set_meta("oficio", persona.get("trade", ""))
			add_child(nodo)
			_npcs[persona.get("name", "?")] = nodo


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


func _cartel(texto: String) -> Node3D:
	var l := Label3D.new()
	l.text = texto
	l.font_size = 44
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position.y = 2.35
	l.modulate = Color(0.88, 0.92, 0.89)
	l.outline_size = 14
	l.outline_modulate = Color(0.04, 0.06, 0.06, 0.85)
	l.no_depth_test = false
	return l


func _process(_dt: float) -> void:
	if jugador == null:
		return
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
