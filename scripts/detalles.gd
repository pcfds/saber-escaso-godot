## Lo que hace que un blockout parezca un lugar habitado.
##
## Ninguna de estas cosas es "arte" — son primitivas y partículas. Pero son
## las señales que el ojo usa para decidir si mira una maqueta de cajas o un
## pueblo donde vive gente, y cuestan casi nada:
##
##  · VENTANAS QUE BRILLAN. La señal número uno de "acá adentro hay alguien".
##    Una caja con una ventana encendida deja de ser una caja.
##  · HUMO DE CHIMENEA. Movimiento vertical lento = alguien está cocinando.
##  · PASTO Y PIEDRAS. Rompen el plano liso, que es lo que grita "sin terminar".
##  · BICHOS DE LUZ. Movimiento chico y disperso: el cerebro lo lee como vida.
##
## Todo esto es barato POR UNIDAD, y ahí está la trampa: hay 26.000 unidades.
## Lo que sigue está armado para que el motor pueda tirar a la basura lo que no
## se ve, que es la única optimización que no le saca nada al que sí mira. Las
## cantidades y los alcances los ajusta `rendimiento.gd` por los grupos
## "pasto", "piedras", "humo" y "bichos".
class_name Detalles
extends RefCounted

## De cuánto es la baldosa con que se corta el pasto y las piedras. 34 metros
## es más chico que la distancia de dibujado más corta (55 m en calidad baja),
## que es la condición para que ralear por distancia haga algo.
const BALDOSA := 34.0


# ===========================================================================
# LA CASA
#
# Hasta acá una casa era una caja con un cono de cuatro caras encima. Era lo
# primero que se veía al entrar al valle y era lo que más se leía como
# provisorio: nada dice "sin terminar" como una caja con sombrero.
#
# Ahora se arma con los módulos del Fantasy Town Kit de Kenney (CC0, ver
# `assets/PROCEDENCIA.md`). El kit no trae casas enteras: trae muros y techos
# de una celda, que es mejor, porque significa que las casas del valle no son
# siete copias del mismo `.glb` —eso se lee tan rápido como la caja— sino
# combinaciones distintas de las mismas piezas.
#
# LA MEDIDA. Una celda del kit es 1 unidad. La casa es de 2×2 celdas y la
# celda vale `CASA_CELDA` metros, así que la planta es 2,6 × 2,6 m. La caja de
# antes era 2,7 × 2,5, y eso **no es casualidad**: `valle.gd` empuja a la gente
# fuera de las casas con `CASA_MEDIA`, media planta, y si la casa cambia de
# tamaño la gente empieza a caminar por adentro de las paredes. La planta se
# mantiene; lo que cambia es de qué está hecha.
#
# POR QUÉ NO HACEN FALTA PIEZAS DE ESQUINA. Un muro del kit ocupa la cara +X
# de su celda y abarca la celda entera en Z. Dos muros perpendiculares de
# celdas vecinas se superponen en el cuadradito de la esquina, así que cierran
# solos. Las piezas `wall-corner` son para otra cosa (muros de una celda de
# espesor visible) y acá sobran.
# ===========================================================================

## Un módulo del kit, en metros. 2 celdas → planta de 2,6 m, que es la caja de
## antes. Ver `CASA_MEDIA` en `valle.gd`: los dos números están atados.
const CASA_CELDA := 1.3

## Dos plantas. Con una la casa queda de 1,3 m y parece una casilla; con tres
## pasa los 4 m y deja de ser un caserío para ser un pueblo de otra escala.
const CASA_NIVELES := 2

## Las ocho caras del perímetro de una planta de 2×2 celdas: centro de la celda
## en unidades y giro que lleva la cara del muro (+X en local) a la de afuera.
const CASA_CARAS: Array = [
	[Vector2( 0.5, -0.5),  0.0],        # +X
	[Vector2( 0.5,  0.5),  0.0],
	[Vector2(-0.5, -0.5),  PI],         # -X
	[Vector2(-0.5,  0.5),  PI],
	[Vector2(-0.5,  0.5), -PI / 2.0],   # +Z, el frente
	[Vector2( 0.5,  0.5), -PI / 2.0],
	[Vector2(-0.5, -0.5),  PI / 2.0],   # -Z
	[Vector2( 0.5, -0.5),  PI / 2.0],
]

## Los índices de `CASA_CARAS` que dan al frente (+Z). Es donde va la puerta,
## y es la cara que `valle.gd` orienta hacia afuera del círculo de casas —
## igual que hacía `ventanas_y_puerta()` con la caja.
const CASA_FRENTE: Array[int] = [4, 5]


## Arma una casa y la cuelga de `padre`. Devuelve la altura del alero, que es
## lo que `valle.gd` necesita para poner la chimenea y el humo.
##
## `rng` se pasa de afuera a propósito: las casas ya se sorteaban en
## `_armar_lugar()` y el sorteo tiene que seguir saliendo de la misma corriente
## de azar.
##
## `piedra` elige la familia de muro —revoque o tabla—. Es la única variación
## de material: **una sola familia por casa.** Mezclar piedra y madera en la
## misma pared es lo que hace que un kit modular se vea a kit modular.
static func casa(padre: Node3D, pos: Vector3, giro: float,
		rng: RandomNumberGenerator, piedra: bool, quemada: bool) -> float:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = giro
	padre.add_child(g)

	var fam := "pueblo/wall" if piedra else "pueblo/wall-wood"
	# Las plantas no son todas iguales de altas: entre 0,95 y 1,15 de celda hay
	# la misma variedad que daba el `randf_range(2.4, 3.6)` de la caja, pero
	# sin que se despegue del kit.
	var alto_nivel := CASA_CELDA * rng.randf_range(0.95, 1.15)

	# La puerta va en una de las dos celdas del frente; la otra lleva ventana.
	var i_puerta: int = CASA_FRENTE[rng.randi() % CASA_FRENTE.size()]
	var luz := _luz_de_ventana()

	for nivel in CASA_NIVELES:
		for i in CASA_CARAS.size():
			var celda: Vector2 = CASA_CARAS[i][0]
			var rot: float = CASA_CARAS[i][1]
			var pieza := fam
			var ventana := false

			if quemada:
				# La Casa Quemada: muros rotos, sin puerta y sin luz. Un
				# tercio de las caras directamente no está — un muro faltante
				# dice "esto se cayó" mucho mejor que un muro entero gris.
				if rng.randf() < 0.34:
					continue
				pieza = fam + "-broken"
			elif nivel == 0 and i == i_puerta:
				pieza = fam + "-door"
			elif i in CASA_FRENTE or rng.randf() < 0.34:
				# Ventanas: siempre al frente, y a veces en los costados. Con
				# ventana en las ocho caras la casa se vuelve un farol.
				pieza = fam + "-window-shutters"
				ventana = true

			var mi := Kit.nodo(pieza)
			if mi == null:
				continue
			mi.position = Vector3(celda.x * CASA_CELDA, nivel * alto_nivel,
				celda.y * CASA_CELDA)
			mi.rotation.y = rot
			mi.scale = Vector3(CASA_CELDA, alto_nivel, CASA_CELDA)
			g.add_child(mi)

			if ventana:
				g.add_child(_vidrio(mi, luz))

	var alero := CASA_NIVELES * alto_nivel
	if not quemada:
		_techo(g, alero, rng)
	return alero


## El techo: una pirámide de cuatro caras del kit, estirada a la planta entera.
##
## Es la misma silueta que tenía el cono de cuatro caras de antes, y eso es
## deliberado — la familia de techos de cuatro aguas ya es parte del lenguaje
## del valle, tanto que `vegetacion.gd` la nombra al explicar por qué las copas
## tienen facetas duras. Lo que cambia no es la forma: son los aleros, el
## borde y la textura de teja, o sea las tres cosas que un cono no tiene.
static func _techo(g: Node3D, alero: float, rng: RandomNumberGenerator) -> void:
	# Dos alturas de techo. El empinado es el que hace que un caserío se lea
	# como pueblo de montaña y no como galpones.
	var empinado := rng.randf() < 0.45
	var mi := Kit.nodo("pueblo/roof-high-point" if empinado else "pueblo/roof-point")
	if mi == null:
		return
	# La pieza mide 1,1 de ancho por celda, o sea que a escala 2 cubre las dos
	# celdas y sobra 0,1 de alero por lado. Ese sobrante es el punto.
	var s := 2.0 * CASA_CELDA
	mi.position = Vector3(0.0, alero, 0.0)
	mi.scale = Vector3(s, s * rng.randf_range(0.85, 1.15), s)
	g.add_child(mi)


## El vidrio encendido de una ventana del kit.
##
## La pieza `wall-window-shutters` trae el marco y los postigos, pero su color
## sale del atlas y no se enciende. La luz de adentro sigue siendo una placa
## emisiva nuestra, como en la caja: se cuelga del muro —así hereda su
## posición, su giro y su escala sin tener que recalcular nada— y entra al
## grupo "ventanas", que es lo que `ciclo.gd` recorre al caer el sol.
##
## **Esto no es un detalle que se pueda perder al migrar.** Una ventana
## encendida dice "adentro hay alguien" más fuerte que todo el cielo junto, y
## está anotado como decisión del valle.
static func _vidrio(muro: MeshInstance3D, luz: StandardMaterial3D) -> MeshInstance3D:
	var v := BoxMesh.new()
	v.size = Vector3(0.34, 0.34, 0.06)
	v.material = luz
	var mi := MeshInstance3D.new()
	mi.mesh = v
	# En el marco local del muro: la cara de afuera está en x = 0,5 y el hueco
	# de la ventana a media altura. El nodo se coloca en coordenadas del muro y
	# después se le copia la transformación, porque el muro ya viene escalado.
	mi.transform = muro.transform * Transform3D(
		Basis().rotated(Vector3.UP, PI / 2.0), Vector3(0.47, 0.52, 0.0))
	mi.add_to_group("ventanas")
	return mi


## El material de las ventanas encendidas. Uno por casa: `ciclo.gd` le mueve
## `emission_energy_multiplier` a cada ventana del grupo, y si todas
## compartieran un material global le escribiría el mismo número cien veces.
static func _luz_de_ventana() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.78, 0.42)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.72, 0.34)
	m.emission_energy_multiplier = 3.4
	return m


static func ventanas_y_puerta(casa: MeshInstance3D, ancho: float, alto: float) -> void:
	var luz_mat := StandardMaterial3D.new()
	luz_mat.albedo_color = Color(1.0, 0.78, 0.42)
	luz_mat.emission_enabled = true
	luz_mat.emission = Color(1.0, 0.72, 0.34)
	luz_mat.emission_energy_multiplier = 3.4

	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color(0.16, 0.10, 0.07)
	madera.roughness = 0.95

	# Dos ventanas al frente, apenas salidas de la pared para que capten luz.
	for lado: float in [-0.26, 0.26]:
		var v := BoxMesh.new()
		v.size = Vector3(ancho * 0.20, alto * 0.20, 0.06)
		v.material = luz_mat
		var mi := MeshInstance3D.new()
		mi.mesh = v
		mi.position = Vector3(ancho * lado, alto * 0.12, ancho * 0.46)
		# Al grupo: el ciclo del día las enciende de noche y las baja de día.
		mi.add_to_group("ventanas")
		casa.add_child(mi)

	var p := BoxMesh.new()
	p.size = Vector3(ancho * 0.26, alto * 0.46, 0.07)
	p.material = madera
	var puerta := MeshInstance3D.new()
	puerta.mesh = p
	puerta.position = Vector3(0, -alto * 0.27, ancho * 0.46)
	casa.add_child(puerta)


static func chimenea(padre: Node3D, pos: Vector3, ancho: float) -> void:
	var ladrillo := StandardMaterial3D.new()
	ladrillo.albedo_color = Color(0.24, 0.16, 0.13)
	ladrillo.roughness = 0.98
	var c := BoxMesh.new()
	c.size = Vector3(ancho * 0.22, ancho * 0.55, ancho * 0.22)
	c.material = ladrillo
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = pos
	padre.add_child(mi)

	padre.add_child(_humo(pos + Vector3(0, ancho * 0.4, 0)))


static func _humo(pos: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = 22
	p.lifetime = 5.5
	p.explosiveness = 0.0
	p.randomness = 0.55
	# Por vida y no por profundidad de vista. El orden por profundidad obliga a
	# reordenar las partículas contra la cámara en cada cuadro; el humo sube
	# siempre y su rampa de color termina en transparente, así que el orden de
	# nacimiento ya es el orden correcto y se ve igual.
	p.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME
	# La caja de visibilidad por default de las partículas es de 8 metros de
	# lado alrededor del emisor. Este humo sube diez metros y el viento lo
	# corre otros diez, así que con la caja por default el motor lo descartaba
	# justo cuando todavía se veía. Declarada bien, el descarte funciona en los
	# dos sentidos: no parpadea, y una chimenea fuera de cámara deja de
	# simularse.
	p.visibility_aabb = AABB(Vector3(-4, -2, -5), Vector3(16, 16, 12))
	p.add_to_group("humo")

	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0.25, 1, 0.1)
	m.spread = 12.0
	m.initial_velocity_min = 0.5
	m.initial_velocity_max = 1.1
	m.gravity = Vector3(0.35, 0.28, 0)      # el humo sube y lo lleva el viento
	m.scale_min = 0.35
	m.scale_max = 0.8
	# Crece y se disuelve: humo que mantiene el tamaño se ve a pelotas.
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.25))
	curva.add_point(Vector2(0.4, 1.0))
	curva.add_point(Vector2(1, 1.7))
	var ct := CurveTexture.new()
	ct.curve = curva
	m.scale_curve = ct

	var g := Gradient.new()
	g.set_color(0, Color(0.72, 0.70, 0.66, 0.55))
	g.set_color(1, Color(0.80, 0.80, 0.80, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m

	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	var qm := StandardMaterial3D.new()
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	qm.albedo_color = Color(0.75, 0.73, 0.70, 0.5)
	# El humo no recibe sombra. Está arriba del techo, nunca hay nada que se la
	# proyecte, y recibirla cuesta una búsqueda en el atlas por cada píxel de
	# humo — o sea justo donde más sobredibujado hay.
	qm.disable_receive_shadows = true
	q.material = qm
	p.draw_pass_1 = q
	return p


## Pasto en MultiMesh: miles de matas en muy pocas llamadas de dibujo.
##
## Un MultiMesh es una sola caja para el motor: o lo dibuja entero o no lo
## dibuja. Con las 26.000 matas repartidas en 260 metros de diámetro en un solo
## MultiMesh, mirando al norte se dibujaban igual las trece mil que tenías
## atrás. Cortado en baldosas de 34 metros, el descarte por cámara y por
## distancia hace ese trabajo solo — y sesenta y pico de llamadas de dibujo no
## las siente nadie, era mil veces más barato de lo que costaba el problema.
static func pasto(padre: Node3D, alturas: Callable, cantidad: int, radio: float) -> void:
	var hoja := PrismMesh.new()
	hoja.size = Vector3(0.09, 0.42, 0.04)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.55, 0.26)
	mat.roughness = 1.0
	# Sin descarte de caras traseras se rasterizaban las 208.000 caras del
	# pasto DOS veces. Eso tiene sentido en un pasto de cartelitos planos, que
	# no tienen "adentro"; acá cada mata es un prisma cerrado y las caras de
	# atrás siempre las tapa la de adelante. Era el doble de trabajo por
	# exactamente el mismo píxel.
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	hoja.material = mat

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260816
	var por_baldosa := _repartir(rng, cantidad, radio, alturas,
		func(t: Transform3D, r: RandomNumberGenerator) -> Transform3D:
			t.origin.y += 0.18
			return t.rotated_local(Vector3.UP, r.randf() * TAU) \
				.scaled_local(Vector3.ONE * r.randf_range(0.7, 1.9)))

	for celda: Vector2i in por_baldosa:
		var lista: Array = por_baldosa[celda]
		var centro := _centro(celda, alturas)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = hoja
		mm.instance_count = lista.size()
		for i in lista.size():
			var t: Transform3D = lista[i]
			t.origin -= centro
			mm.set_instance_transform(i, t)
			# Variar el color mata la sensación de estampado.
			mm.set_instance_color(i,
				Color(0.34, 0.48, 0.22).lerp(Color(0.62, 0.66, 0.32), rng.randf()))

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.add_to_group("pasto")
		padre.add_child(mmi)


## Las piedras sueltas del valle.
##
## La roca es del kit y **sale más barata que la esfera que había**: una esfera
## de 6 gajos por 3 anillos son 48 triángulos, y `rock_smallA` son 16. O sea
## que acá el arte hecho por alguien no costó nada — descontó. Son 320
## instancias, así que el ahorro es chico en el total, pero vale decirlo porque
## es el contraejemplo de lo que se supone que pasa al meter assets.
##
## **El pasto NO se cambió, y es a propósito.** La mata de pasto de Kenney son
## 132 triángulos y acá hay 26.000 matas: 3,4 millones de triángulos contra los
## ~104.000 de ahora. No hay máquina que lo aguante y no es una decisión de
## arte, es aritmética. El pasto se queda con las hojas generadas, que a la
## distancia a la que se juega son una textura de color y no una silueta.
static func piedras(padre: Node3D, alturas: Callable, cantidad: int, radio: float) -> void:
	var roca := Kit.malla("naturaleza/rock_smallA")
	if roca == null:
		var esfera := SphereMesh.new()
		esfera.radius = 0.5
		esfera.height = 0.7
		esfera.radial_segments = 6
		esfera.rings = 3
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.34, 0.32)
		mat.roughness = 1.0
		esfera.material = mat
		roca = esfera

	# La malla del kit mide 0,36 × 0,19; la esfera de antes medía 1,0 × 0,7.
	# Este factor la lleva a la misma convención para que el sorteo de escalas
	# de abajo —que está afinado -— siga dando piedras del mismo tamaño.
	var caja := roca.get_aabb()
	var norma := Transform3D(Basis().scaled(Vector3(
		1.0 / maxf(caja.size.x, 0.001),
		1.0 / maxf(caja.size.y, 0.001),
		1.0 / maxf(caja.size.z, 0.001))), Vector3.ZERO)

	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	var por_baldosa := _repartir(rng, cantidad, radio, alturas,
		func(t: Transform3D, r: RandomNumberGenerator) -> Transform3D:
			t.origin.y -= 0.1
			return t.rotated_local(Vector3.UP, r.randf() * TAU).scaled_local(Vector3(
				r.randf_range(0.4, 1.5), r.randf_range(0.3, 0.8),
				r.randf_range(0.4, 1.5))) * norma)

	for celda: Vector2i in por_baldosa:
		var lista: Array = por_baldosa[celda]
		var centro := _centro(celda, alturas)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = roca
		mm.instance_count = lista.size()
		for i in lista.size():
			var t: Transform3D = lista[i]
			t.origin -= centro
			mm.set_instance_transform(i, t)

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.add_to_group("piedras")
		padre.add_child(mmi)


## Tira `cantidad` puntos en un disco de `radio` y los agrupa por baldosa.
##
## El orden de generación es aleatorio uniforme y NO se altera. Eso es lo que
## después le permite a `rendimiento.gd` ralear el campo con
## `visible_instance_count`: quedarse con las primeras N instancias de cada
## baldosa es quedarse con una muestra uniforme, o sea un pasto más ralo, y no
## con media baldosa pelada.
static func _repartir(rng: RandomNumberGenerator, cantidad: int, radio: float,
		alturas: Callable, armar: Callable) -> Dictionary:
	var salida := {}
	for i in cantidad:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radio
		var x := cos(a) * r
		var z := sin(a) * r
		var t := Transform3D()
		t.origin = Vector3(x, alturas.call(x, z), z)
		t = armar.call(t, rng)
		var celda := Vector2i(floori(x / BALDOSA), floori(z / BALDOSA))
		if not salida.has(celda):
			salida[celda] = []
		salida[celda].append(t)
	return salida


## El centro de la baldosa, apoyado en el terreno. Que el nodo esté ahí y no en
## el origen del valle es la mitad del asunto: la distancia de dibujado se mide
## contra la posición del nodo, y un nodo en (0,0,0) que abarca 260 metros
## nunca está lejos de la cámara.
static func _centro(celda: Vector2i, alturas: Callable) -> Vector3:
	var x := (float(celda.x) + 0.5) * BALDOSA
	var z := (float(celda.y) + 0.5) * BALDOSA
	return Vector3(x, alturas.call(x, z), z)


## Bichos de luz. Movimiento chico y disperso: es lo que el ojo lee como
## "acá pasa algo" incluso cuando no pasa nada.
static func luciernagas(padre: Node3D, pos: Vector3, cantidad: int, radio: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = cantidad
	p.lifetime = 7.0
	p.randomness = 1.0
	# Cuatro segundos de simulación adelantada al nacer, para que no aparezcan
	# todas juntas en el mismo punto. Se paga una sola vez, al arrancar.
	p.preprocess = 4.0
	# Igual que con el humo: sin declarar la caja, el motor usa 8 metros de
	# lado y estas nubes miden hasta 26. Declarada, una nube en el Sotobosque
	# deja de simularse cuando estás en la aldea.
	p.visibility_aabb = AABB(Vector3.ONE * -(radio + 4.0), Vector3.ONE * (radio + 4.0) * 2.0)
	p.add_to_group("bichos")

	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = radio
	m.direction = Vector3(0, 1, 0)
	m.spread = 180.0
	m.initial_velocity_min = 0.15
	m.initial_velocity_max = 0.55
	m.gravity = Vector3.ZERO
	m.damping_min = 0.2
	m.damping_max = 0.6
	m.scale_min = 0.5
	m.scale_max = 1.3

	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.35, 0.0))
	g.add_point(0.3, Color(1.0, 0.88, 0.45, 1.0))
	g.add_point(0.7, Color(1.0, 0.80, 0.35, 1.0))
	g.set_color(1, Color(1.0, 0.75, 0.30, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m

	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.11)
	var qm := StandardMaterial3D.new()
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	qm.emission_enabled = true
	qm.emission = Color(1.0, 0.82, 0.38)
	qm.emission_energy_multiplier = 6.0
	q.material = qm
	p.draw_pass_1 = q
	padre.add_child(p)
	return p
