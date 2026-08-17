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

	if OS.get_cmdline_user_args().has("--medir"):
		_medir_enseres()
		return
	if OS.get_cmdline_user_args().has("--interior"):
		_interiores(rng)
		return
	if OS.get_cmdline_user_args().has("--plaza"):
		_plaza()
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


# ===========================================================================
# LA PLAZA  (`-- --plaza`)
#
# Lo mismo que el banco de las casas y por lo mismo: **el fogón de Vado Bajo es
# imposible de juzgar en una captura del valle**, porque el jugador aparece
# adentro de la casa que lo tapa y la cámara del juego no se puede mover desde
# acá. Acá está lo que `Detalles.labranza()` pone en la plaza —huertas, pilón y
# fogón— sobre suelo plano y con una vara del tamaño del jugador sentada al
# lado, que es la única forma de discutir si un tronco es un asiento.
#
#   godot escenas/prueba_casas.tscn -- --plaza --captura
# ===========================================================================

func _plaza() -> void:
	# Suelo plano: la altura la pide `labranza()` y acá vale cero en todas
	# partes. El valle tiene lomas y eso ya lo resuelve la búsqueda de rellano
	# que esa función hace; lo que se mira acá es la composición.
	Detalles.labranza(self, func(_x: float, _z: float) -> float: return 0.0,
		{"aldea": {"pos": Vector3.ZERO}})

	# La vara, parada donde se sentaría alguien. `asiento_cerca()` no se puede
	# usar acá —vive en `Interiores` y no hay casas— así que se lee el grupo
	# directo, que es de dónde lo saca ella también.
	for n in get_tree().get_nodes_in_group("asientos"):
		var nodo := n as MeshInstance3D
		_vara(nodo.global_position + Vector3(0, float(nodo.get_meta("asiento_alto", 0.45)), 0))
		# El bulto se dice, y no es prolijidad: la colisión del asiento sale de
		# acá, y con un tamaño fijo el tocón se llevaba la caja del tronco, o sea
		# casi dos metros de pared invisible en el medio de la plaza.
		var b := nodo.get_aabb().size * nodo.scale
		print("  asiento %s: %.2f × %.2f × %.2f m, se apoya a %.2f" % [
			nodo.name, b.x, b.y, b.z, float(nodo.get_meta("asiento_alto", 0.0))])
	print("plaza: %d asientos marcados" % get_tree().get_nodes_in_group("asientos").size())

	var cam := get_node_or_null(^"Camara") as Camera3D
	if cam != null:
		cam.position = Vector3(-3.2, 6.5, 7.0)
		cam.look_at(Vector3(-3.2, 0.6, -2.5))
	var sol := get_node_or_null(^"Sol") as DirectionalLight3D
	if sol != null:
		sol.position = Vector3(34, 26, 30)
		sol.look_at(Vector3(-8, 0, -10))
		sol.light_color = Paleta.LUZ_ALBA
	_captura()


# ===========================================================================
# LA REGLA DE ORO DEL PROYECTO, HECHA UN COMANDO  (`-- --medir`)
#
# *Medí la malla, no la estimes.* Así se desarmó el bloqueo de la mudanza al
# MegaKit —el revoque tiene 0,200 de espesor leído del `.gltf`— y así se
# descubrió que las cuatro piedras del Nature Kit no tienen ni una superficie de
# piedra. La alternativa es lo que ya pasó y costó una tarde: **el tronco de los
# escombros de la Casa Quemada se rotaba 90° sobre Z "para acostarlo", y el
# tronco ya venía acostado**, así que el giro lo paraba de punta. Nadie lo vio
# porque nadie midió el bulto: 2,00 × 0,45 × 0,45 es una cosa acostada en X y se
# lee de un vistazo si alguien la imprime.
#
# Esto imprime, de cada enser que este archivo pone en un cuarto: el bulto en
# metros, sobre qué eje es largo, dónde tiene el origen y cuántos triángulos
# cuesta. Sin abrir Blender y sin creerle al nombre del archivo.
# ===========================================================================

const ENSERES_MEDIDOS: Array[String] = [
	"naturaleza/log_large", "naturaleza/log_stack", "naturaleza/stump_round",
	"naturaleza/pot_large",
	"utiles/bedroll", "utiles/chest", "utiles/workbench", "utiles/workbench-anvil",
	"utiles/barrel", "utiles/barrel-open", "utiles/box", "utiles/box-large",
	"utiles/bucket", "utiles/bottle", "utiles/tool-hammer", "utiles/tool-axe",
	"utiles/resource-planks", "utiles/resource-wood", "utiles/resource-stone",
	"utiles/campfire-pit", "utiles/campfire-stand",
]


func _medir_enseres() -> void:
	print("%-30s %18s  %-6s %18s %7s" % [
		"pieza", "bulto (x·y·z m)", "largo", "origen", "tri"])
	for ruta in ENSERES_MEDIDOS:
		var m := Kit.malla(ruta)
		if m == null:
			print("  %-28s NO ESTÁ" % ruta)
			continue
		var b := m.get_aabb()
		# Sobre qué eje es larga la cosa. Es el dato que decide si hay que
		# girarla para acostarla o si ya viene acostada.
		var eje := "X" if b.size.x >= maxf(b.size.y, b.size.z) else (
			"Y" if b.size.y >= b.size.z else "Z")
		print("  %-28s %5.2f %5.2f %5.2f  %-6s %5.2f %5.2f %5.2f %7d" % [
			ruta, b.size.x, b.size.y, b.size.z, eje,
			b.get_center().x, b.get_center().y, b.get_center().z,
			Kit.triangulos(m)])
	get_tree().quit()


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
	var hojas: Array[MeshInstance3D] = []
	var cuartos: Array[Node3D] = []
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
		var cuarto := (casa["nodo"] as Node3D).get_node_or_null(^"Cuarto") as Node3D
		if cuarto != null:
			cuartos.append(cuarto)
		var hoja: MeshInstance3D = casa.get("hoja")
		if hoja != null:
			hojas.append(hoja)
		_vara(Vector3(x + pd.x, 0, Detalles.CASA_LADO / 2.0 + 1.6))
		_cartel(OFICIOS_MUESTRA[i] if not quemada else "quemada",
			Vector3(x, 7.4, 0))
		x += 14.0

	_medir_hojas(hojas)
	await _medir_puertas(puertas)
	_medir_apertura(casas, puertas)
	_medir_empuje(casas, cuartos, puertas)

	# El recorte, forzado en las tres: la cámara mira desde +Z, así que se
	# apagan el techo, la planta alta y los muros del frente. En el valle se
	# abre una sola —ver `Interiores.abrir_todas()`—; acá se abren todas porque
	# de eso se trata la captura. Con `--cerradas` se ven como las ve el que
	# pasa por la calle, que es la otra mitad de lo que hay que revisar.
	#
	# Y las tres formas de mirar una puerta, que son las tres que hay que poder
	# comparar: `--cerradas` la ve desde la calle con la hoja puesta,
	# `--abiertas` la ve desde la calle con la hoja girada —o sea que ahí se
	# prueba que la hoja SE MUEVE y adónde va a parar— y sin nada se ve el
	# cuarto, que es para lo que existía el banco.
	var args := OS.get_cmdline_user_args()
	if args.has("--abiertas"):
		casas.abrir_todas(Vector3(0, 14, 34), false)
	elif not args.has("--cerradas"):
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


## LA HOJA DE LA PUERTA, medida y no supuesta.
##
## Dos cosas, y las dos se pueden equivocar en silencio:
##
##  · **Cuánto mide puesta en el valle.** La hoja se construye en unidades de
##    panel y la escala se la pone el muro (1,35 en planta, el estirado de esa
##    casa en alto). Un error ahí no da error de script: da una puerta más chica
##    que su hueco, y eso se ve como una raja de luz y como un decorado.
##  · **Que la ruina NO tenga.** Una casa quemada sin techo con la puerta
##    flamante puesta es peor que no tener puertas.
##
## Lo que esto NO prueba es si se entra: eso lo prueba `_medir_puertas()` con la
## cápsula, y **tiene que seguir dando cinco de cinco con la hoja puesta**. Si
## alguna vez baja, alguien le puso colisión a la puerta — ver el bloque
## `LA PUERTA` en `detalles.gd`.
func _medir_hojas(hojas: Array[MeshInstance3D]) -> void:
	print("puertas: %d hojas en 3 casas (la quemada no lleva)" % hojas.size())
	for k in hojas.size():
		var h: MeshInstance3D = hojas[k]
		var caja := h.get_aabb()
		var s: Vector3 = h.global_transform.basis.get_scale()
		# El conteo vuelve a `Kit.triangulos()`. Acá había una copia a mano con
		# una nota al lado —*"queda anotado: `Kit.triangulos()` se rompe con
		# mallas sueltas"*— y ésa es la forma más cara que hay de tener un bug:
		# documentado, vivo, y con el que lo encontró trabajando alrededor. La
		# causa era que una malla sin indexar devuelve `null` en `ARRAY_INDEX` y
		# no un array vacío; está arreglada en `kit.gd`.
		print("  hoja %d: %.2f × %.2f m de tabla, %d triángulos" % [
			k, absf(caja.size.x * s.x), absf(caja.size.y * s.y),
			Kit.triangulos(h.mesh)])


## ¿SE ABRE? Y no mirando una captura: **una captura es un instante y lo que hay
## que probar es que la hoja se mueve cuando alguien camina hasta la puerta.**
##
## Camina un punto —el jugador, sin cuerpo— desde tres metros afuera hasta el
## umbral, un paso por cuadro, llamando a `Interiores.actualizar()` igual que lo
## llama `valle.gd`, y después lo saca y espera a que la puerta se cierre sola.
## Lo que se mide es el ángulo de la hoja en los dos extremos.
##
## Esta prueba es la que hay que mirar si algún día una puerta deja de abrirse:
## si acá abre y en el valle no, el que está mal es el punto del umbral y no la
## mecánica; si acá tampoco, es la mecánica.
##
## El reloj es de mentira —un sesentavo de segundo por vuelta, pasado a mano— y
## eso es a propósito: en headless un cuadro dura un milisegundo, así que esperar
## los cinco segundos que la puerta se queda abierta serían cinco mil cuadros y
## la corrida se muere en el `--quit-after` mucho antes.
func _medir_apertura(casas: Interiores, puertas: Array[Vector3]) -> void:
	if puertas.is_empty():
		return
	var dt := 1.0 / 60.0
	var p: Vector3 = puertas[0]
	var camara := Vector3(p.x, 11.0, p.z + 27.0)
	var afuera := Vector3(p.x, p.y, p.z + 8.0)

	# Ir hasta la puerta: dos segundos y medio, de sobra para el medio segundo
	# largo que tarda el recorrido de la hoja.
	for k in 150:
		casas.actualizar(afuera.lerp(p, minf(float(k) / 60.0, 1.0)), camara, dt)
	var abierta := casas.puerta("prueba/0")

	# Y volverse. `PUERTA_QUEDA` son cinco segundos de espera antes de cerrarse.
	for _k in 420:
		casas.actualizar(afuera, camara, dt)
	var cerrada := casas.puerta("prueba/0")

	print("apertura: al llegar %.2f rad (%.0f°), al irse %.2f rad — abre a %.2f"
		% [abierta, rad_to_deg(absf(abierta)), cerrada, Interiores.PUERTA_GIRO])


## ¿SE MUEVE ALGO CUANDO ENTRÁS? El reclamo era literal —*"en las casas no se
## puede mover nada"*— y la respuesta no se puede verificar con una captura,
## porque una captura es un instante y lo que hay que probar es que la banqueta
## está en otro lado DESPUÉS de que le pasaste por encima.
##
## Camina un punto por el cuarto —el jugador sin cuerpo, igual que
## `_medir_apertura()`— y compara la posición de cada mueble antes y después.
## Lo que tiene que dar:
##
##   · **algo se movió** (si no, `LIVIANOS` no engancha con ninguna ruta de las
##     tablas y el cuarto volvió a ser una vitrina sin que nadie se entere);
##   · **nada se movió más que `EMPUJE_CORREA`** (si no, el cuarto termina
##     apilado en un rincón);
##   · **nada se fue afuera de los 2,43 m del cuarto** (si no, hay un balde
##     adentro del revoque, y eso desde afuera se ve).
##
## Y lo pesado tiene que seguir donde estaba: si el yunque se corre, se rompió la
## mitad del argumento, que es que un cuarto tiene peso porque algunas cosas no
## se mueven.
func _medir_empuje(casas: Interiores, cuartos: Array[Node3D],
		puertas: Array[Vector3]) -> void:
	if cuartos.is_empty() or puertas.is_empty():
		print("empuje: no hay cuarto que probar")
		return
	var cuarto: Node3D = cuartos[0]
	var antes := {}
	for h in _muebles_de(cuarto):
		antes[h.get_instance_id()] = h.global_position

	# Una vuelta por el cuarto: entrar por la puerta, cruzar hasta el rincón del
	# fondo del otro lado, y volver. Es el recorrido que hace cualquiera.
	var p: Vector3 = puertas[0]
	var camara := Vector3(p.x, 11.0, p.z + 27.0)
	var y := Detalles.CASA_PISO
	var cx := cuarto.global_position.x
	var ruta: Array[Vector3] = [
		Vector3(p.x, y, Detalles.CASA_LADO / 2.0),
		Vector3(cx - 1.2, y, -1.2), Vector3(cx + 1.3, y, -1.4),
		Vector3(cx + 1.2, y,  1.3), Vector3(cx - 1.3, y,  1.4),
		Vector3(p.x, y, Detalles.CASA_LADO / 2.0),
	]
	var dt := 1.0 / 60.0
	for k in ruta.size() - 1:
		for s in 40:
			casas.actualizar(ruta[k].lerp(ruta[k + 1], s / 39.0), camara, dt)

	var movidos := 0
	var mayor := 0.0
	var afuera := 0
	for h in _muebles_de(cuarto):
		var origen: Vector3 = antes[h.get_instance_id()]
		var d := origen.distance_to(h.global_position)
		if d < 0.01:
			continue
		movidos += 1
		mayor = maxf(mayor, d)
		var loc := cuarto.to_local(h.global_position)
		if absf(loc.x) > Detalles.CASA_ADENTRO or absf(loc.z) > Detalles.CASA_ADENTRO:
			afuera += 1
		print("  se corrió %.2f m: %s" % [d, h.name])
	print("empuje: %d de %d muebles se corrieron, el que más %.2f m (correa %.2f), %d afuera del cuarto"
		% [movidos, _muebles_de(cuarto).size(), mayor, Interiores.EMPUJE_CORREA, afuera])


## Los muebles de un cuarto, incluidos los del puesto del oficio, que cuelgan de
## un nodo aparte para poder rehacerse solos cuando cambia el que vive ahí.
func _muebles_de(cuarto: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for h in cuarto.get_children():
		if h is MeshInstance3D:
			out.append(h)
		elif h is Node3D:
			for n in (h as Node3D).get_children():
				if n is MeshInstance3D:
					out.append(n)
	return out


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
