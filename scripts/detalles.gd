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
#
# LA PUERTA SE ABRE. Hasta el 17 de agosto la casa tenía UN colisionador: una
# caja maciza de la planta entera. O sea que la puerta estaba dibujada y la
# pared invisible pasaba por delante — el pedido más viejo del proyecto
# (*"comercios, edificios con cosas adentro"*) chocaba contra una sola línea.
#
# Ahora la colisión **sigue a la geometría que se construyó**: un tabique por
# panel de la planta baja, y en el panel de la puerta dos jambas con el hueco
# real en el medio. Tres cosas salen gratis de eso:
#
#   · Se entra. El hueco de `wall-door` mide 0,4 × 0,75 de celda, o sea
#     **1,08 m de ancho por ~2 m de alto** con `CASA_CELDA` en 2,7. El jugador
#     es una cápsula de 0,90 de diámetro y 1,85 de alto: entra, y entra justo,
#     que es la proporción correcta para una puerta de casa.
#   · La Casa Quemada se camina por dentro. Sus muros son `-broken` y un tercio
#     directamente no está, así que no llevan tabique: se entra por donde se
#     cayó la pared. Es lo que ya era y no se veía.
#   · Adentro hay 4,86 × 4,86 m libres —la cara interna del muro cae en
#     0,40 de celda— con 2,6 a 3,1 m hasta el entrepiso. Es un cuarto, no un
#     hueco: entra una fragua, una cama y alguien parado.
#
# EL TERRENO NO ES PLANO Y ESO NO ERA UN DETALLE. Medido sobre las doce casas
# del valle: bajo la planta de una casa el suelo sube y baja **hasta 1,53 m**, y
# la casa se apoyaba en la altura de su CENTRO. O sea que el terreno entraba más
# de un metro adentro del cuarto. Un interior con una loma adentro es peor que
# no tener interior.
#
# Se arregla en tres pasos y los tres están acá o en `valle.gd`:
#
#   1. `valle.gd` le busca a cada casa el rellano más parejo cerca de donde le
#      tocaba (`_sitio_de_casa()`). El desnivel peor pasa de 1,53 a 1,03 m.
#   2. La casa se apoya en el punto MÁS ALTO de su planta, no en el del centro,
#      y lo que queda en el aire lo tapa un **zócalo de piedra**. Un basamento
#      en pendiente no es un parche: es lo que hace una casa de verdad.
#   3. La puerta tiene **escalones**, con una rampa invisible debajo, porque
#      `CharacterBody3D` no sube un escalón solo. El umbral peor queda en 0,94 m.
# ===========================================================================

## Un módulo del kit, en metros. 2 celdas → planta de 2,6 m, que es la caja de
## antes. Ver `CASA_MEDIA` en `valle.gd`: los dos números están atados.
## El lado de una celda del kit. La casa son 2×2 celdas.
##
## Estaba en 1,3, o sea una casa de 2,6 m de planta con un personaje de 1,85 de
## alto: **la persona era más grande que la casa**, y se veía. Una casa
## medieval de verdad tiene entre seis y ocho metros de frente; con 2,7 la
## planta queda en 5,4 y la puerta le llega a la cabeza a alguien parado
## enfrente, que es la proporción que el ojo espera.
const CASA_CELDA := 2.7

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

## El lado de la planta, en metros: 5,4.
const CASA_LADO := CASA_CELDA * 2.0

## De dónde a dónde llega el cuarto, medido del centro de la casa. El muro del
## kit ocupa de 0,40 a 0,50 de celda, así que la cara de adentro cae en
## `0,40 + 0,5` de celda desde el centro: 2,43 m. El cuarto es de 4,86 × 4,86.
const CASA_ADENTRO := CASA_CELDA * 0.9

## El espesor del muro, en metros. Es el 0,10 de celda que mide la pieza.
const CASA_MURO := CASA_CELDA * 0.10

## El hueco de la puerta, medido sobre la malla `wall-door`: los montantes
## están en ±0,20 de celda y el arco cierra a 0,75 de la altura del panel.
## Con la celda en 2,7 son 1,08 m de ancho, y de alto entre 1,92 y 2,33 según
## cuánto le haya tocado de altura de planta a esa casa.
const PUERTA_ANCHO := CASA_CELDA * 0.40
const PUERTA_ALTO := 0.75

## Cuánto sobresale el zócalo de la línea del muro, por lado. Un basamento al
## ras del muro no se lee como basamento: se lee como que la casa se hundió.
const ZOCALO_VUELO := 0.12

## Lo que sube cada escalón del umbral, como mucho.
const ESCALON := 0.28
## Y lo que mide de fondo.
const ESCALON_HUELLA := 0.5

## A qué altura queda el piso del cuarto, medido del origen de la casa. Son las
## tablas apoyadas sobre el zócalo. Todo lo de adentro se apoya acá, y la rampa
## del umbral llega hasta acá: si este número y el del umbral se separan, se
## entra a la casa y se cae siete centímetros.
const CASA_PISO := 0.07


## Arma una casa y la cuelga de `padre`.
##
## `sitio` es el terreno ya resuelto por `valle.gd` —dónde apoyarla, cuánto
## zócalo hace falta y cuánto hay que subir para entrar—, porque el que sabe de
## alturas es el que tiene el terreno en la mano y no este archivo:
##
##   · `pos`     (Vector3) el piso de la casa, en el marco de `padre`
##   · `giro`    (float)   radianes; el frente (+Z) mira para afuera
##   · `zocalo`  (float)   cuánto baja el terreno bajo la planta
##   · `umbral`  (float)   cuánto hay que subir desde la calle hasta el piso
##   · `puerta`  (int)     0 o 1: en cuál de las dos celdas del frente va la
##                         puerta. −1 la sortea. Se elige la del acceso más bajo.
##
## Devuelve `{"nodo", "alero", "alto", "puerta", "baja", "alta"}`:
## `baja` y `alta` son las dos plantas separadas, y ésa es la mitad de que se
## pueda entrar — el recorte de `interiores.gd` apaga `alta` y los muros de
## `baja` que se le ponen delante a la cámara. Sin las dos plantas en nodos
## distintos habría que adivinarlo recorriendo el árbol en cada cuadro.
##
## `rng` se pasa de afuera a propósito: las casas ya se sorteaban en
## `_armar_lugar()` y el sorteo tiene que seguir saliendo de la misma corriente
## de azar.
##
## `piedra` elige la familia de muro —revoque o tabla—. Es la única variación
## de material: **una sola familia por casa.** Mezclar piedra y madera en la
## misma pared es lo que hace que un kit modular se vea a kit modular.
static func casa(padre: Node3D, sitio: Dictionary,
		rng: RandomNumberGenerator, piedra: bool, quemada: bool) -> Dictionary:
	var giro: float = sitio.get("giro", 0.0)
	var g := Node3D.new()
	g.position = sitio.get("pos", Vector3.ZERO)
	g.rotation.y = giro
	padre.add_child(g)

	# Las dos plantas, en nodos aparte. Ver el encabezado: es lo que hace
	# posible el recorte de la casa cuando estás adentro.
	var baja := Node3D.new()
	baja.name = "Baja"
	g.add_child(baja)
	var alta := Node3D.new()
	alta.name = "Alta"
	g.add_child(alta)

	var fam := "pueblo/wall" if piedra else "pueblo/wall-wood"
	# Las plantas no son todas iguales de altas: entre 0,95 y 1,15 de celda hay
	# la misma variedad que daba el `randf_range(2.4, 3.6)` de la caja, pero
	# sin que se despegue del kit.
	var alto_nivel := CASA_CELDA * rng.randf_range(0.95, 1.15)

	# La puerta va en una de las dos celdas del frente; la otra lleva ventana.
	# Cuál de las dos la decide el terreno: la que tenga el acceso más bajo.
	var lado: int = int(sitio.get("puerta", -1))
	if lado != 0 and lado != 1:
		lado = rng.randi() % CASA_FRENTE.size()
	var i_puerta: int = CASA_FRENTE[lado]
	var luz := _luz_de_ventana()

	for nivel in CASA_NIVELES:
		var capa := baja if nivel == 0 else alta
		for i in CASA_CARAS.size():
			var celda: Vector2 = CASA_CARAS[i][0]
			var rot: float = CASA_CARAS[i][1]
			var pieza := fam
			var ventana := false
			var es_puerta := false

			if quemada:
				# La Casa Quemada: muros rotos, sin puerta y sin luz. Un
				# tercio de las caras directamente no está — un muro faltante
				# dice "esto se cayó" mucho mejor que un muro entero gris.
				if rng.randf() < 0.34:
					continue
				pieza = fam + "-broken"
			elif nivel == 0 and i == i_puerta:
				pieza = fam + "-door"
				es_puerta = true
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
			# Hacia dónde da este muro, ya en coordenadas del mundo. Lo usa el
			# recorte: se apaga el muro que la cámara tiene delante. Se anota
			# ahora porque acá el dato es una suma de dos ángulos y después
			# habría que sacarlo de una matriz.
			var afuera := Vector3.RIGHT.rotated(Vector3.UP, giro + rot)
			mi.set_meta("afuera", afuera)
			capa.add_child(mi)

			if ventana:
				var v := _vidrio(mi, luz)
				v.set_meta("afuera", afuera)
				capa.add_child(v)

			# La colisión SIGUE A LO CONSTRUIDO. Un tabique por panel de planta
			# baja, y en el de la puerta, dos jambas con el hueco en el medio.
			# Los muros rotos de la ruina no llevan: por ahí se entra.
			if nivel == 0 and not quemada:
				_tabique(g, mi.position, rot, alto_nivel, es_puerta)

	var alero := CASA_NIVELES * alto_nivel
	if not quemada:
		_techo(alta, alero, rng)

	# El basamento y los escalones. La ruina también los lleva: una casa
	# quemada sigue teniendo cimientos, y sin ellos su planta baja flota.
	_zocalo(g, float(sitio.get("zocalo", 0.0)), quemada)
	# Los escalones también en la ruina, y no es un descuido: su zócalo llega a
	# un metro y sin ellos la Casa Quemada es tres plataformas a las que no se
	# puede subir. Una casa quemada conserva el umbral — es de piedra y es lo
	# último que se cae.
	var puerta := Vector3(CASA_CARAS[i_puerta][0].x * CASA_CELDA, CASA_PISO, CASA_ADENTRO)
	_umbral(g, puerta.x, float(sitio.get("umbral", 0.0)))

	return {
		"nodo": g, "alero": alero, "alto": alto_nivel,
		"puerta": puerta, "baja": baja, "alta": alta,
	}


## Un tabique de la planta baja, del tamaño del panel que se acaba de poner.
##
## `pos` es la posición del panel en el marco de la casa y `rot` su giro. El
## muro del kit ocupa de 0,40 a 0,50 de celda hacia afuera, así que su eje cae
## en 0,45 — y ahí va la caja, con el espesor real y no con la planta entera.
##
## Con `puerta`, en vez de una caja van dos jambas: el hueco de `wall-door`
## mide 0,4 de celda, o sea 1,08 m, y lo que queda a cada lado son 0,81.
static func _tabique(g: Node3D, pos: Vector3, rot: float, alto: float,
		puerta: bool) -> void:
	var eje := CASA_CELDA * 0.45
	var tramos: Array = [[0.0, CASA_CELDA]]
	if puerta:
		var jamba := (CASA_CELDA - PUERTA_ANCHO) / 2.0
		var centro := (CASA_CELDA + PUERTA_ANCHO) / 4.0
		tramos = [[-centro, jamba], [centro, jamba]]
	for t: Array in tramos:
		var cuerpo := StaticBody3D.new()
		var cf := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(CASA_MURO, alto, t[1])
		cf.shape = bs
		cuerpo.add_child(cf)
		cuerpo.position = pos + Vector3(eje, alto / 2.0, t[0]).rotated(Vector3.UP, rot)
		cuerpo.rotation.y = rot
		g.add_child(cuerpo)


## El zócalo: el basamento de piedra que tapa lo que la pendiente deja en el
## aire, y que además es el piso sobre el que se camina adentro.
##
## Va en `Paleta.LOSA_CAMINO` (V5) y no en `LADRILLO` (V3): contra un suelo V4
## el basamento tiene que leerse como piedra trabajada, un peldaño POR ARRIBA
## del prado. En V3 desaparece y la casa vuelve a parecer clavada en el pasto.
## El piso son tablas y va un peldaño POR DEBAJO del muro (V5 contra V6). Con el
## mismo valor que la pared, el cuarto entero se lee como una sola mancha con la
## luz del hogar encima; un escalón abajo, la luz del fuego tiene dónde caer.
## En la ruina el piso es tierra: ahí no queda tabla que no se haya quemado.
static func _zocalo(g: Node3D, hondo: float, quemada: bool) -> void:
	# Siempre asoma un poco aunque el terreno sea plano —una casa apoyada
	# directamente sobre el pasto se lee como una calcomanía— y siempre se
	# entierra un cuarto de metro, para que el borde no quede al aire.
	var alto := maxf(hondo, 0.16) + 0.3
	var lado := CASA_LADO + ZOCALO_VUELO * 2.0

	var caja := BoxMesh.new()
	caja.size = Vector3(lado, alto, lado)
	caja.material = Paleta.piedra(Paleta.LOSA_CAMINO)
	var mi := MeshInstance3D.new()
	mi.mesh = caja
	mi.position.y = -alto / 2.0
	g.add_child(mi)

	var tablas := BoxMesh.new()
	tablas.size = Vector3(CASA_ADENTRO * 2.0, CASA_PISO, CASA_ADENTRO * 2.0)
	tablas.material = (Paleta.piedra(Paleta.TIERRA) if quemada
		else Paleta.madera(Paleta.MURO_FRAGUA))
	var piso := MeshInstance3D.new()
	piso.mesh = tablas
	piso.position.y = CASA_PISO / 2.0
	g.add_child(piso)

	# Un solo cuerpo para los dos: la cara de arriba es el piso del cuarto y los
	# costados son el basamento, que es contra lo que chocás caminando afuera.
	var cuerpo := StaticBody3D.new()
	var cf := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(lado, alto + CASA_PISO, lado)
	cf.shape = bs
	cuerpo.add_child(cf)
	cuerpo.position.y = CASA_PISO - (alto + CASA_PISO) / 2.0
	g.add_child(cuerpo)


## Los escalones de la puerta, con la rampa que los hace subibles.
##
## **`CharacterBody3D` no sube un escalón solo.** `move_and_slide()` desliza
## contra la caja y el jugador se queda abajo mirando la puerta, que es
## exactamente el bug que esta rama vino a arreglar y sería ridículo
## reintroducirlo doce centímetros más abajo. Así que los escalones son SÓLO
## mallas y quien hace el trabajo es una caja inclinada enterrada debajo.
##
## Es la única pieza del valle donde lo que se ve y lo que se toca no son la
## misma geometría, y por eso está dicho acá y no en un comentario suelto.
static func _umbral(g: Node3D, puerta_x: float, alto: float) -> void:
	# Desde la calle hasta las TABLAS, no hasta el zócalo: los siete
	# centímetros del piso también hay que subirlos.
	var subida := maxf(alto, 0.05) + CASA_PISO
	var n := clampi(int(ceil(subida / ESCALON)), 1, 4)
	var largo := ESCALON_HUELLA * n
	var z0 := CASA_LADO / 2.0 + ZOCALO_VUELO
	var ancho := PUERTA_ANCHO + 0.7
	var mat := Paleta.piedra(Paleta.LOSA_CAMINO)

	for k in n:
		# k = 0 es el de arriba, al ras del piso. Cada uno se entierra 0,3 para
		# que la contrahuella no deje ver el pasto por debajo.
		var caja := BoxMesh.new()
		caja.size = Vector3(ancho, subida / n + 0.3, ESCALON_HUELLA)
		caja.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = caja
		mi.position = Vector3(puerta_x,
			CASA_PISO - subida * k / n - caja.size.y / 2.0,
			z0 + ESCALON_HUELLA * (k + 0.5))
		g.add_child(mi)

	# La rampa NO mide lo que miden los escalones, y ésa fue la corrección que
	# costó el andamio de más abajo.
	#
	# Primero se le dio el largo de la escalera, y **dos de nueve casas seguían
	# sin poder entrarse**: el pie de la rampa caía donde el terreno estaba más
	# alto que ella, así que el jugador nunca la pisaba y terminaba de frente
	# contra la cara del zócalo, treinta y tres centímetros abajo de su propia
	# puerta. Medido con el andamio, no deducido — la posición en que quedaba
	# clavado estaba justo en el hueco de la puerta y no en el muro.
	#
	# Ahora es una pendiente FIJA de 30° y tres metros de largo, siempre igual,
	# que se hunde bajo el pasto. Donde el terreno la cruza, ahí empieza la
	# subida, y ese punto lo elige el terreno solo. Cubre 1,73 m de desnivel,
	# casi el doble del peor umbral del valle (0,94 m).
	var pend := deg_to_rad(30.0)
	var largo_r := 3.0
	var rampa := StaticBody3D.new()
	var cf := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(ancho, 0.18, largo_r / cos(pend))
	cf.shape = bs
	rampa.add_child(cf)
	# El centro se corre media pastilla hacia abajo por la normal inclinada,
	# para que la CARA de arriba —y no el centro de la caja— pase por el borde
	# del zócalo.
	rampa.position = Vector3(puerta_x,
		CASA_PISO - largo_r * tan(pend) / 2.0 - 0.09 * cos(pend),
		z0 + largo_r / 2.0 - 0.09 * sin(pend))
	rampa.rotation.x = pend
	g.add_child(rampa)


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
	# **El empinado se achica a la mitad y no es un capricho.** `roof-point`
	# mide 0,5 de alto por 1,1 de ancho y `roof-high-point` mide 1,0: al mismo
	# factor, el segundo son 5,4 m de techo sobre 5,6 m de pared, o sea un
	# campanario. Medido mirando el banco de prueba: al lado de una casa normal
	# no se leía como "más empinado", se leía como otro edificio. Con 0,55 queda
	# en 3,0 m contra los 2,7 del otro — un peldaño, que es lo que se pedía.
	var alto := s * (0.55 if empinado else 1.0) * rng.randf_range(0.85, 1.15)
	mi.position = Vector3(0.0, alero, 0.0)
	mi.scale = Vector3(s, alto, s)
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
##
## Sale de `Paleta.ventana()`, que es la excepción 1 de la paleta —el fuego, el
## único lugar donde se gasta saturación— y **la entrega apagada, en 0.15**. Eso
## no es un descuido y no hay que "arreglarlo" subiéndolo: la energía la manda
## `ciclo.gd` según la hora del SERVIDOR, de 0.15 a 4.2, y su `_ultima_oscuridad`
## arranca en −1.0, así que la primera pasada siempre escribe. El 3.4 fijo que
## había acá era una ventana encendida a las tres de la tarde durante un cuadro.
static func _luz_de_ventana() -> StandardMaterial3D:
	return Paleta.ventana()


## Ventanas y puerta de la casa-caja de antes.
##
## **Ya no la llama nadie**: las casas se arman con los módulos del kit en
## `casa()`. Queda migrada igual y —esto es lo que importa— **pidiéndole la luz
## a `_luz_de_ventana()` en vez de armar su propio material**: mientras existan
## dos recetas de ventana encendida en el mismo archivo, la próxima que alguien
## copie va a ser la equivocada. Si sigue sin llamarla nadie, se borra.
static func ventanas_y_puerta(casa: MeshInstance3D, ancho: float, alto: float) -> void:
	var luz_mat := _luz_de_ventana()

	# La puerta es `Paleta.MADERA`, que está en V1 a propósito: contra un muro
	# V6 una puerta tiene que leerse como un AGUJERO, no como una tabla marrón.
	# Ese par claro/oscuro es la mitad de lo que hace que una caja sea una casa.
	var madera := Paleta.madera()

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


## Devuelve el bulto de ladrillo, que es lo único de acá que hay que poder
## apagar: cuando el recorte le saca el techo a la casa en la que estás
## parado, una chimenea flotando sola sobre el cuarto es peor que el techo.
## El humo no se toca — sale de un fuego que sigue encendido.
static func chimenea(padre: Node3D, pos: Vector3, ancho: float) -> MeshInstance3D:
	# La chimenea es lo único que sobresale del techo, así que su trabajo entero
	# es silueta. `Paleta.LADRILLO` está en V3 y el techo en V2: un peldaño de
	# separación, que es lo mínimo para que el bulto se vea contra la tapa
	# oscura de la casa. Con el mismo valor que el techo, la chimenea no existe
	# y el humo sale de la nada.
	var ladrillo := Paleta.piedra(Paleta.LADRILLO)
	var c := BoxMesh.new()
	c.size = Vector3(ancho * 0.22, ancho * 0.55, ancho * 0.22)
	c.material = ladrillo
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = pos
	padre.add_child(mi)

	padre.add_child(_humo(pos + Vector3(0, ancho * 0.4, 0)))
	return mi


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

	# El humo nace en V7 y muere en V8: se ACLARA al disolverse, que es lo que
	# hace de verdad una columna de humo cuando se adelgaza y le pasa el cielo
	# por atrás. Y los dos son grises CÁLIDOS, no neutros: el (0.80, 0.80, 0.80)
	# que había acá era gris de niebla, y niebla sobre un techo no dice que
	# alguien está cocinando. Es la única señal de que la casa está habitada de
	# día, cuando las ventanas están apagadas.
	#
	# Dos puntos, así que acá los índices 0 y 1 sí son los extremos de la rampa.
	# En `luciernagas()` eso mismo estaba mal y costó el color de muerte entero.
	var g := Gradient.new()
	g.set_color(0, Paleta.HUMO_NACE)
	g.set_color(1, Paleta.HUMO_MUERE)
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m

	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	# `Paleta.humo()` trae la receta entera —alfa, billboard, color de vértice y
	# el "no recibe sombra"—, porque el humo no recibe sombra por decisión y no
	# por casualidad: está arriba del techo, nunca hay nada que se la proyecte, y
	# recibirla cuesta una búsqueda en el atlas por cada píxel, o sea justo donde
	# más sobredibujado hay. Su albedo `HUMO_TELA` MULTIPLICA la rampa de arriba.
	q.material = Paleta.humo()
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
	# ===================================================================
	# EL BUG QUE ARRASTRABA ESTE ARCHIVO, Y NO ERA UN COLOR MAL ELEGIDO.
	#
	# El MultiMesh de más abajo pone `use_colors = true` y calcula un tinte
	# distinto por mata — ese código existe para una sola cosa, que 26.000
	# matas no sean la misma mata. **El material que había acá no tenía
	# `vertex_color_use_as_albedo`, así que el shader tiraba ese color a la
	# basura** y pintaba las 26.000 con un único `Color(0.40, 0.55, 0.26)`.
	# O sea: se pagaba el cálculo del antiestampado y se veía el estampado.
	#
	# `Paleta.pasto_hoja()` existe exactamente para esto y trae el flag
	# prendido, el albedo en blanco —porque el color lo pone la instancia y
	# el albedo lo MULTIPLICA, no lo reemplaza— y el especular apagado, que
	# es lo que saca el brillo parejo de plástico de los 26.000 prismas.
	#
	# También trae `CULL_BACK`, y eso no se pierde al migrar: sin descarte
	# de caras traseras se rasterizaban las 208.000 caras del pasto DOS
	# veces. Tiene sentido en un pasto de cartelitos planos, que no tienen
	# "adentro"; acá cada mata es un prisma cerrado y la cara de atrás
	# siempre la tapa la de adelante. Era el doble de trabajo por el mismo
	# píxel.
	# ===================================================================
	hoja.material = Paleta.pasto_hoja()

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
			# Variar el color mata la sensación de estampado — y desde el
			# material de arriba, por fin se ve.
			#
			# Las dos puntas son V2 y V4 contra un suelo que promedia V4: el
			# pasto va POR DEBAJO del terreno, no encima. Es la diferencia
			# entre leerse como textura y sombra del prado y leerse como una
			# pelusa clara apoyada arriba, que es lo que hacía el verde
			# (0.40, 0.55, 0.26) —V5 y saturación 0.53— cuando pintaba las
			# 26.000 matas iguales. Baja a s0.34, la misma saturación que la
			# tierra que tiene abajo.
			mm.set_instance_color(i, Paleta.PASTO_MATA_OSCURA.lerp(
				Paleta.PASTO_MATA_CLARA, rng.randf()))

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
		# El respaldo de cuando falta el `.glb`. Va en `Paleta.PIEDRA_SUELTA`,
		# que es V6: **la piedra es lo más claro del paisaje**, y estas 320
		# piedras son la puntuación clara del cuadro contra un suelo V4. El gris
		# (0.35, 0.34, 0.32) de antes estaba en V3 —por DEBAJO del suelo— así
		# que no puntuaba nada: eran manchones oscuros del mismo valor que el
		# pasto húmedo.
		#
		# A la roca del kit, en cambio, **no se le pisa el material**: viene con
		# el suyo del atlas de Kenney y `Kit` lo dice explícito. La paleta manda
		# sobre lo que generamos nosotros, no sobre las mallas del kit — mezclar
		# las dos autoridades sobre el mismo objeto es el "indeciso" que la
		# dirección de arte existe para terminar.
		esfera.material = Paleta.piedra(Paleta.PIEDRA_SUELTA)
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

	# La vida de una luciérnaga: nace apagada, se enciende, se pone más cálida y
	# se apaga. Los dos colores son la excepción 1 de la paleta —el fuego—, y
	# son los únicos de este archivo donde la saturación alta está permitida:
	# ocupan cuatro píxeles y son la mitad de por qué la noche del valle no es
	# sólo oscuridad.
	#
	# **LOS OFFSETS SE DECLARAN, NO SE NUMERAN.** Lo de antes era
	# `set_color(1, ...)` DESPUÉS de dos `add_point()`, y para entonces el
	# índice 1 ya no era el final de la rampa sino el punto de 0,3. Medido:
	# el color cálido de muerte se escribía al principio con alfa 0 —o sea que
	# la luciérnaga era invisible su primer tercio de vida— y el final de la
	# rampa se quedaba con el `Color(1,1,1,1)` que `Gradient` trae de fábrica.
	# Cada bicho terminaba volviéndose BLANCO OPACO y desapareciendo de golpe:
	# blanco puro, que no está en la paleta y no está en ningún lado del valle,
	# y un salto justo donde tenía que haber un desvanecido.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([
		Color(Paleta.LUCIERNAGA, 0.0),
		Paleta.LUCIERNAGA,
		Paleta.LUCIERNAGA_CALIDA,
		Color(Paleta.LUCIERNAGA_CALIDA, 0.0),
	])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m

	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.11)
	# `Paleta.chispa()`: sin sombreado, billboard, y la emisión de la paleta.
	# Una luciérnaga sombreada es un punto gris.
	q.material = Paleta.chispa()
	p.draw_pass_1 = q
	padre.add_child(p)
	return p
