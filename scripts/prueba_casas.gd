extends Node3D

# ===========================================================================
# EL A/B DE LAS CASAS. Ver `escenas/prueba_casas.tscn`.
#
# A la izquierda, la casa que hay hoy: módulos del Fantasy Town Kit de Kenney,
# armada por `Detalles.casa()`. A la derecha, la misma idea con los módulos del
# Medieval Village MegaKit de Quaternius (CC0, ver `assets/PROCEDENCIA.md`).
#
# **Esta escena existe para que una decisión de arte se tome mirando, no
# leyendo.** La dirección del proyecto rechazó el kit de Kenney con estas
# palabras —*"parece un mundo de Disney para mujeres"*— y la pregunta que sigue
# es si hay algo libre que no se lea así. Acá están las dos, con la misma luz,
# la misma paleta, el mismo suelo y la misma distancia.
#
# LO QUE NO ESTÁ RESUELTO Y HAY QUE MIRAR AL DECIDIR:
#
#   · **La planta cambia de tamaño.** El muro de Kenney es una celda de 1 y el
#     valle lo escala a 1,3 m; el de Quaternius mide 2 × 3,12 fijos. Una casa de
#     dos paneles por lado son 4 × 4 m contra los 2,6 × 2,6 de hoy. Eso toca
#     `CASA_MEDIA` en `valle.gd` —es lo que empuja a la gente fuera de las
#     paredes— y por eso el cambio no es sólo de `detalles.gd`.
#   · **El techo cuesta.** El de Kenney es una pirámide de ~50 triángulos; el
#     `Roof_RoundTiles_4x4` son 1.996. Con cuarenta casas eso es +78 mil.
#   · Las texturas ya vienen domadas EN DISCO, no en tiempo de ejecución.
# ===========================================================================

## Kenney: la celda del kit en metros. Es la de `Detalles.CASA_CELDA`.
const CELDA_K := 1.3

## Quaternius: el panel mide 2 de ancho por 3,12 de alto, y no se escala. La
## casa es de DOS paneles por lado.
const PANEL := 2.0
const ALTO_PANEL := 3.12

const CERCA := 26.0
const LEJOS := 55.0


func _ready() -> void:
	_ambiente()
	_suelo()

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260817

	# Kenney, tres casas: piedra, madera y quemada. Es la variedad que el valle
	# tiene hoy.
	Detalles.casa(self, Vector3(-13.0, 0, 0), 0.0, rng, true, false)
	Detalles.casa(self, Vector3(-8.0, 0, -4.0), 0.6, rng, false, false)
	Detalles.casa(self, Vector3(-17.0, 0, -4.5), -0.4, rng, true, true)
	_cartel("KENNEY · hoy", Vector3(-13.0, 4.6, 0))

	# Quaternius, las mismas tres.
	_casa_q(Vector3(8.0, 0, 0), 0.0, rng, false)
	_casa_q(Vector3(15.0, 0, -5.0), 0.7, rng, true)
	_cartel("QUATERNIUS · propuesta", Vector3(11.0, 8.2, 0))

	_encuadrar()
	_captura()


## Una casa con los módulos de Quaternius.
##
## Ocho paneles por planta —dos por lado de un cuadrado de 4 × 4— y dos plantas.
## No hacen falta esquinas: igual que con Kenney, dos paneles perpendiculares se
## superponen en el cuadradito de la esquina y cierran solos.
##
## Lo que esta casa tiene y la de hoy NO puede tener, que es de lo que se trata
## la comparación: **entramado de madera** (`Wall_Plaster_WoodGrid`),
## **puntales** (`Prop_Support`), **enredadera** (`Prop_Vine1`) y un techo con
## teja de verdad en vez de una pirámide.
func _casa_q(pos: Vector3, giro: float, rng: RandomNumberGenerator,
		ladrillo: bool) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = giro
	add_child(g)

	var fam := "quaternius/pueblo/Wall_UnevenBrick" if ladrillo else "quaternius/pueblo/Wall_Plaster"
	# Los cuatro lados de un cuadrado de 4 × 4: centro del panel y giro que
	# lleva su cara de afuera hacia afuera.
	var caras: Array = [
		[Vector2(-1.0,  2.0), 0.0],
		[Vector2( 1.0,  2.0), 0.0],
		[Vector2(-1.0, -2.0), PI],
		[Vector2( 1.0, -2.0), PI],
		[Vector2( 2.0, -1.0), PI / 2.0],
		[Vector2( 2.0,  1.0), PI / 2.0],
		[Vector2(-2.0, -1.0), -PI / 2.0],
		[Vector2(-2.0,  1.0), -PI / 2.0],
	]
	var i_puerta := 0 if rng.randf() < 0.5 else 1

	for nivel in 2:
		for i in caras.size():
			var celda: Vector2 = caras[i][0]
			var pieza := fam + "_Straight"
			if nivel == 0 and i == i_puerta:
				pieza = fam + "_Door_Round"
			elif rng.randf() < 0.45:
				pieza = fam + "_Window_Wide_Round"
			elif nivel == 1 and not ladrillo and rng.randf() < 0.5:
				# El entramado sólo en la planta alta, que es donde va en una
				# casa de verdad: abajo la piedra aguanta el peso.
				pieza = "quaternius/pueblo/Wall_Plaster_WoodGrid"
			var mi := Kit.nodo(pieza)
			if mi == null:
				continue
			mi.position = Vector3(celda.x, nivel * ALTO_PANEL, celda.y)
			mi.rotation.y = caras[i][1]
			g.add_child(mi)

	var alero := 2.0 * ALTO_PANEL

	# El alero y el techo.
	for celda: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		Kit.poner(g, "quaternius/pueblo/Overhang_Roof_Plaster",
			Vector3(celda.x, alero, celda.y))
	Kit.poner(g, "quaternius/pueblo/Roof_RoundTiles_4x4", Vector3(0, alero + 0.3, 0))

	# Lo que hace que una casa se lea como casa vieja y no como pieza de kit:
	# el puntal, la chimenea y la enredadera.
	Kit.poner(g, "quaternius/pueblo/Prop_Support", Vector3(2.02, 0, 0.6), PI / 2.0)
	Kit.poner(g, "quaternius/pueblo/Prop_Support", Vector3(-2.02, 0, -0.6), -PI / 2.0)
	Kit.poner(g, "quaternius/pueblo/Prop_Chimney2", Vector3(1.3, alero + 0.6, -1.3))
	Kit.poner(g, "quaternius/pueblo/Prop_Vine1", Vector3(-1.2, 0.2, 2.1), 0.0)
	Kit.poner(g, "quaternius/pueblo/Prop_Vine4", Vector3(0.9, 3.2, 2.1), 0.0)
	Kit.poner(g, "quaternius/pueblo/Prop_WoodenFence_Single", Vector3(0.0, 0, 4.4))
	Kit.poner(g, "quaternius/pueblo/Prop_Wagon", Vector3(4.6, 0, 2.6), 1.1)


func _cartel(texto: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = texto
	l.position = pos
	l.pixel_size = 0.012
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	add_child(l)


func _ambiente() -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Paleta.NIEBLA_DIA
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Paleta.LUZ_CIELO
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)


func _suelo() -> void:
	var p := PlaneMesh.new()
	p.size = Vector2(200, 200)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Paleta.PASTO
	mat.roughness = 1.0
	p.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = p
	add_child(mi)


func _encuadrar() -> void:
	var d := LEJOS if OS.get_cmdline_user_args().has("--lejos") else CERCA
	var cam := get_node_or_null(^"Camara") as Camera3D
	if cam != null:
		cam.position = Vector3(-2.0, d * 0.42, d)
		cam.look_at(Vector3(-2.0, 2.4, -1.0))
	var sol := get_node_or_null(^"Sol") as DirectionalLight3D
	if sol != null:
		sol.position = Vector3(34, 26, 30)
		sol.look_at(Vector3(-8, 0, -10))
		sol.light_color = Paleta.LUZ_ALBA
	var relleno := get_node_or_null(^"Relleno") as DirectionalLight3D
	if relleno != null:
		relleno.position = Vector3(-34, 28, -30)
		relleno.look_at(Vector3(8, 0, 10))
		relleno.light_color = Paleta.LUZ_CIELO


func _captura() -> void:
	if not OS.get_cmdline_user_args().has("--captura"):
		return
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://captura.png")
	print("captura guardada")
	get_tree().quit()
