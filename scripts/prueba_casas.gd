extends Node3D

# ===========================================================================
# EL BANCO DE LAS CASAS. Ver `escenas/prueba_casas.tscn`.
#
# **Esta escena existió para que una decisión de arte se tomara mirando, no
# leyendo, y esa decisión ya se tomó.** La dirección del proyecto rechazó las
# casas del Fantasy Town Kit de Kenney con estas palabras —*"parece un mundo de
# Disney para mujeres"*— y el A/B contra el Medieval Village MegaKit de
# Quaternius se corrió acá, con la misma luz, la misma paleta, el mismo suelo y
# la misma distancia. Ganó Quaternius y por un motivo que no era el color: **el
# muro de Kenney tiene la ventana PINTADA sobre una cara plana.** Ninguna
# cantidad de paleta arregla un agujero dibujado.
#
# Los tres bloqueos que estaban anotados acá se desarmaron con números y están
# contados en el encabezado de `detalles.gd`:
#
#   · la planta NO cambia de tamaño (el panel a 1,35 da 5,40 m de lado y 0,27 de
#     muro, que son `CASA_LADO` y `CASA_MURO` clavados);
#   · el techo cuesta +23,4 mil triángulos y no +78 mil, porque el valle tiene
#     doce casas y no cuarenta;
#   · y las texturas ya vienen horneadas en disco, con el tinte de peldaño en
#     `Paleta.KIT_QUATERNIUS`.
#
# Lo que el banco sigue haciendo, y por eso no se borra: mostrar las tres casas
# del valle —revoque, ladrillo y quemada— juntas y a la distancia de juego, y
# **probar que se entra** (`-- --interior`).
#
#   godot escenas/prueba_casas.tscn -- --captura
#   godot escenas/prueba_casas.tscn -- --captura --lejos
#   godot escenas/prueba_casas.tscn -- --captura --interior
# ===========================================================================

const CERCA := 26.0
const LEJOS := 55.0


func _ready() -> void:
	_ambiente()
	_suelo()

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260817

	if OS.get_cmdline_user_args().has("--interior"):
		_interiores(rng)
		return

	# Las tres casas del valle: revoque (Vado Bajo), ladrillo desparejo (la
	# Fragua) y quemada (la ruina). Es la variedad que el valle tiene.
	Detalles.casa(self, {"pos": Vector3(-9.0, 0, 0), "giro": 0.0}, rng, false, false)
	_cartel("revoque · Vado Bajo", Vector3(-9.0, 10.4, 0))
	Detalles.casa(self, {"pos": Vector3(0.0, 0, -3.0), "giro": 0.5}, rng, true, false)
	_cartel("ladrillo · la Fragua", Vector3(0.0, 10.8, -3.0))
	Detalles.casa(self, {"pos": Vector3(9.5, 0, 0.5), "giro": -0.35}, rng, false, true)
	_cartel("quemada", Vector3(9.5, 8.4, 0.5))

	_encuadrar()
	_censo()
	_captura()


## El costo, en triángulos, dicho y no estimado. La regla de la casa: *el costo
## del arte nuevo hay que poder decirlo*.
func _censo() -> void:
	var piezas := {
		"Wall_Plaster_Straight": 0, "Wall_Plaster_Straight_Base": 0,
		"Wall_Plaster_Door_Round": 0, "Wall_Plaster_Window_Wide_Round": 0,
		"Wall_Plaster_WoodGrid": 0, "Corner_Exterior_Wood": 0,
		"Roof_RoundTiles_4x4": 0,
	}
	var total := 0
	for p: String in piezas:
		var t := Kit.triangulos(Kit.malla("quaternius/pueblo/" + p))
		piezas[p] = t
		print("  %-34s %5d" % [p, t])
		total += t
	print("censo: una casa de revoque ronda los %d triángulos" % (
		piezas["Wall_Plaster_Straight"] * 6 + piezas["Wall_Plaster_Door_Round"]
		+ piezas["Wall_Plaster_Window_Wide_Round"] * 5
		+ piezas["Wall_Plaster_WoodGrid"] * 2 + piezas["Wall_Plaster_Straight_Base"] * 2
		+ piezas["Corner_Exterior_Wood"] * 8 + piezas["Roof_RoundTiles_4x4"]))


# ===========================================================================
# EL BANCO DE PRUEBA DE LOS INTERIORES  (`-- --interior`)
#
# Existe por una sola razón, y es la que el encargo puso primero: **un interior
# que no entra en su exterior es peor que no tenerlo.** Acá están las tres casas
# con el cuarto puesto, el recorte forzado, y —lo que no se puede discutir sin
# tenerlo delante— **una vara de 1,85 m parada en la puerta**, que es cuánto
# mide el jugador. Si la vara no pasa por el hueco, no hay interior.
#
# Con `--umbral` se les pone medio metro de zócalo y de escalón, para ver la
# casa en pendiente sin tener que ir a buscar la ladera correcta del valle.
# ===========================================================================

const OFICIOS_MUESTRA := ["herrera", "destiladora", "guardia"]


func _interiores(rng: RandomNumberGenerator) -> void:
	var inclinada := OS.get_cmdline_user_args().has("--umbral")
	var zocalo := 0.55 if inclinada else 0.0
	var umbral := 0.62 if inclinada else 0.0
	# El suelo del banco es un plano, así que hay que bajarlo: la casa apoya en
	# lo más alto de su planta y lo que se quiere ver es justamente lo que queda
	# entre el piso y la calle. Sin esto el zócalo y los escalones quedan
	# enteros DEBAJO del plano y la captura no muestra nada — que es lo que pasó
	# la primera vez y por poco se da por bueno.
	var suelo := get_child(get_child_count() - 1) as MeshInstance3D
	if inclinada and suelo != null:
		suelo.position.y = -umbral

	var casas := Interiores.new()
	add_child(casas)

	var x := -14.0
	var puertas: Array[Vector3] = []
	for i in 3:
		var sitio := {
			"pos": Vector3(x, 0, 0), "giro": 0.0,
			"zocalo": zocalo, "umbral": umbral, "puerta": i % 2,
		}
		var quemada := i == 2
		var casa := Detalles.casa(self, sitio, rng, i == 0, quemada)
		var clave := "prueba/%d" % i
		casas.amueblar(clave, casa, quemada, rng)
		casas.habitar(clave, "Alguien", OFICIOS_MUESTRA[i])
		var pd: Vector3 = casa["puerta"]
		puertas.append(Vector3(x + pd.x, pd.y, pd.z))
		_vara(Vector3(x + pd.x, 0, Detalles.CASA_LADO / 2.0 + 1.6))
		_cartel(OFICIOS_MUESTRA[i] if not quemada else "quemada",
			Vector3(x, 7.4, 0))
		x += 14.0

	await _medir_puertas(puertas)

	# El recorte, forzado en las tres: la cámara mira desde +Z, así que se
	# apagan el techo, la planta alta y los muros del frente. En el valle se
	# abre una sola —ver `Interiores.abrir_todas()`—; acá se abren todas porque
	# de eso se trata la captura. Con `--cerradas` se ven como las ve el que
	# pasa por la calle, que es la otra mitad de lo que hay que revisar.
	if not OS.get_cmdline_user_args().has("--cerradas"):
		casas.abrir_todas(Vector3(0, 14, 34))

	var cam := get_node_or_null(^"Camara") as Camera3D
	if cam != null:
		cam.position = Vector3(0.0, 11.0, 27.0)
		cam.look_at(Vector3(0.0, 1.4, 0.0))
	var sol := get_node_or_null(^"Sol") as DirectionalLight3D
	if sol != null:
		sol.position = Vector3(34, 26, 30)
		sol.look_at(Vector3(-8, 0, -10))
		sol.light_color = Paleta.LUZ_ALBA
	_captura()


## ¿PASA EL JUGADOR? Y no medido con una regla: con SU CÁPSULA, contra la
## colisión que la casa acaba de construir.
##
## Es la regla más cara que pagó este proyecto —*se verificó caminando hasta cada
## puerta, no mirando capturas*— traída al banco, porque una captura de un
## interior abierto no prueba absolutamente nada sobre si se puede entrar: los
## muros del frente están apagados justamente en esa captura.
##
## Barre la cápsula de `jugador.gd` (0,45 de radio, 1,85 de alto) por el eje de
## la puerta, de la calle al centro del cuarto, y avisa en qué paso choca. Si
## los cinco pasos están libres, se entra.
func _medir_puertas(puertas: Array[Vector3]) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var forma := CapsuleShape3D.new()
	forma.radius = 0.45
	forma.height = 1.85
	var espacio := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = forma
	for k in puertas.size():
		var p: Vector3 = puertas[k]
		var libre := 0
		var pasos := 5
		for s in pasos:
			# De 1,2 m afuera del zócalo hasta el centro del cuarto.
			var z: float = lerp(Detalles.CASA_LADO / 2.0 + 1.2, 0.0, s / float(pasos - 1))
			q.transform = Transform3D(Basis(), Vector3(p.x, Detalles.CASA_PISO + 0.95, z))
			if espacio.intersect_shape(q, 1).is_empty():
				libre += 1
			else:
				print("  casa %d: la cápsula choca en z = %.2f" % [k, z])
		print("puerta %d: %d de %d pasos libres — hueco %.2f m de ancho" % [
			k, libre, pasos, Detalles.PUERTA_ANCHO])


## Una vara de la altura del jugador, para que la escala se discuta mirando.
func _vara(pos: Vector3) -> void:
	var c := CapsuleMesh.new()
	c.radius = 0.45
	c.height = 1.85
	c.radial_segments = 10
	c.rings = 4
	c.material = Paleta.tela(Paleta.JADE)
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = pos + Vector3(0, 0.93, 0)
	add_child(mi)


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
