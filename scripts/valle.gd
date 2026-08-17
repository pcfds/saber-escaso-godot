## El valle. Construye el mundo por código y lo puebla con lo que dice el
## servidor — la misma API que usa la web.
##
## Todo procedural a propósito: sin assets todavía, el look sale de la
## iluminación (ver ambiente.gd) y de la geometría teniendo volumen y
## variación. Un plano liso con cubos es "3D choto"; terreno con relieve,
## sombras largas y niebla volumétrica no.
extends Node3D

const LUGARES := {
	"aldea":  {"pos": Vector3(0, 0, 0),     "color": Color(0.55, 0.48, 0.37), "casas": 7},
	"fragua": {"pos": Vector3(17, 0, -5),   "color": Color(0.49, 0.33, 0.26), "casas": 2},
	"bosque": {"pos": Vector3(-16, 0, -15), "color": Color(0.18, 0.29, 0.20), "casas": 0},
	"ruina":  {"pos": Vector3(-7, 0, -30),  "color": Color(0.29, 0.28, 0.25), "casas": 3},
	"camino": {"pos": Vector3(3, 0, 20),    "color": Color(0.42, 0.38, 0.32), "casas": 0},
}

const RADIO_VALLE := 62.0

var api: Api
var jugador: Jugador
var interfaz: CanvasLayer

var _ruido := FastNoiseLite.new()
var _npcs: Dictionary = {}
var _monstruos: Array[Monstruo] = []
var ciclo: Ciclo
var vida_jugador := 100


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

	Detalles.pasto(self, altura_en, 9000, 48.0)
	Detalles.piedras(self, altura_en, 90, 52.0)
	var bichos: Array[GPUParticles3D] = [
		Detalles.luciernagas(self, Vector3(0, 2.5, 0), 40, 16.0),
		Detalles.luciernagas(self, LUGARES['bosque']['pos'] + Vector3(0, 2.0, 0), 55, 13.0),
		Detalles.luciernagas(self, LUGARES['ruina']['pos'] + Vector3(0, 2.0, 0), 35, 11.0),
	]
	ciclo.bichos_de_luz = bichos

	api = Api.new()
	add_child(api)
	api.mundo_recibido.connect(_al_recibir_mundo)

	jugador = _armar_jugador()
	add_child(jugador)
	jugador.quiere_interactuar.connect(_al_interactuar)
	jugador.quiere_golpear.connect(_al_golpear)

	_poblar_sotobosque()

	interfaz = preload("res://escenas/interfaz.tscn").instantiate()
	add_child(interfaz)
	interfaz.conectar_api(api)
	# Va acá y no arriba: la interfaz recién existe en esta línea.
	jugador.tecleando = interfaz.escribiendo

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
	sol.directional_shadow_max_distance = 140.0
	sol.directional_shadow_blend_splits = true
	sol.light_angular_distance = 1.2   # sombras que se ablandan con la distancia
	sol.shadow_blur = 1.3
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
	var lado := 132.0
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
	agua.size = Vector2(190, 7.5)
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
	mi.position = Vector3(0, -1.7, 9)
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
func _poblar_sotobosque() -> void:
	var centro: Vector3 = LUGARES['bosque']['pos']
	for i in 5:
		var a := TAU * i / 5.0 + randf()
		var r := randf_range(5.0, 12.0)
		var px := centro.x + cos(a) * r
		var pz := centro.z + sin(a) * r
		var m := Monstruo.new()
		m.set_script(preload('res://scripts/monstruo.gd'))
		add_child(m)
		m.preparar(Vector3(px, altura_en(px, pz) + 0.6, pz), altura_en)
		m.objetivo = jugador
		m.pego.connect(_al_recibir_danio)
		m.murio.connect(_al_morir_monstruo)
		_monstruos.append(m)


func _al_recibir_danio(danio: int) -> void:
	vida_jugador = maxi(0, vida_jugador - danio)
	jugador.doler()
	interfaz.mostrar_vida(vida_jugador)
	if vida_jugador == 0:
		_caer_jugador()


func _al_morir_monstruo(_quien: Monstruo) -> void:
	_monstruos = _monstruos.filter(func(m: Monstruo) -> bool: return is_instance_valid(m))
	interfaz.avisar('Cayó uno.')


func _caer_jugador() -> void:
	interfaz.avisar('Te tumbaron. No perdiste lo que sabés — eso vive en tu cabeza.')
	await get_tree().create_timer(2.4).timeout
	vida_jugador = 100
	interfaz.mostrar_vida(vida_jugador)
	jugador.position = Vector3(0, altura_en(0, 8) + 2.0, 8)


func _al_recibir_mundo(datos: Dictionary) -> void:
	var region: Dictionary = datos.get("region", {})
	interfaz.mostrar_region(region, datos.get("player", {}))

	# El reloj del valle. Viene del servidor, no de esta máquina: es lo que
	# hace que el atardecer sea el mismo para todos los que estén conectados.
	if ciclo != null:
		ciclo.sincronizar(int(region.get("tick", 0)), float(region.get("momento_del_dia", 0.0)))

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


func _al_interactuar() -> void:
	var quien: String = interfaz.npc_cercano
	if quien != "":
		api.hablar(quien)


const ALCANCE_JUGADOR := 3.2
const DANIO_JUGADOR := 14

func _al_golpear() -> void:
	jugador.amagar_golpe()
	for m in _monstruos:
		if not is_instance_valid(m):
			continue
		if m.global_position.distance_to(jugador.global_position) < ALCANCE_JUGADOR:
			m.recibir(DANIO_JUGADOR)
			break


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
	var r0 := 150.0
	var r1 := 330.0

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
