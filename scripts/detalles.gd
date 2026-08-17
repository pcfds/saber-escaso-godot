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
# Después fueron los módulos del Fantasy Town Kit de Kenney, y **la dirección
# del proyecto las rechazó con una frase que es el reclamo más viejo que tiene
# este juego**: *"parece un mundo de Disney para mujeres"*. No era la paleta —la
# aduana de `paleta.gd` ya les había bajado los techos de luma 145 a 33— era la
# GEOMETRÍA: el muro de Kenney es una cara plana con la ventana **pintada**
# encima. No hay hueco, no hay jamba, no hay espesor. Ninguna cantidad de color
# arregla una ventana dibujada.
#
# ===========================================================================
# LA MUDANZA AL MEDIEVAL VILLAGE MEGAKIT  (18 de agosto de 2026)
# ===========================================================================
#
# Las doce casas se arman ahora con los módulos de Quaternius (CC0, ver
# `assets/PROCEDENCIA.md`), que estaban en el repo y no los usaba nadie más que
# el banco `escenas/prueba_casas.tscn`. Lo que traen y el otro no puede tener:
#
#   · **Huecos de verdad.** La puerta y la ventana están CALADAS en el panel,
#     con 27 cm de jamba que se ven. Es la diferencia entera.
#   · **Materia.** Siete trim sheets —revoque, ladrillo desparejo, ladrillo,
#     piedra, teja curva, madera y hoja de enredadera— contra un atlas de 24
#     colores planos. Es la regla 2 de la ficha de identidad (`DISENO.md` §6):
#     *nada es liso, todo está usado*.
#   · **Entramado de madera** (`Wall_Plaster_WoodGrid`). Vigas oscuras sobre
#     revoque claro es LA silueta de fachada medieval, y se lee a 27 metros
#     porque es un par de valores (V3 sobre V6), no un detalle.
#
# ===========================================================================
# LA MEDIDA, Y POR QUÉ NADA DE AFUERA SE ENTERA
# ===========================================================================
#
# Éste era el bloqueo anotado —*"la planta cambia de tamaño y eso toca
# `CASA_MEDIA` en `valle.gd`"*— y **se desarmó midiendo la malla en vez de
# estimarla**. El panel de Quaternius mide 2,000 de ancho y su revoque tiene
# 0,200 de espesor (leído del `.gltf`: la primitiva `MI_Plaster` va de z = −0,20
# a z = 0). Escalado **1,35×**:
#
#   · dos paneles por lado = 5,40 m de planta → `CASA_LADO` NO se mueve.
#   · 0,200 × 1,35 = **0,270 m de muro** → que es EXACTAMENTE el `CASA_MURO`
#     que tenía la casa de Kenney (0,10 de celda × 2,7).
#   · o sea que la cara de adentro sigue cayendo en **2,43 m** del centro:
#     `CASA_ADENTRO` no se mueve y el cuarto sigue siendo de **4,86 × 4,86**.
#
# Así que `interiores.gd` —que está terminado y verificado caminando hasta las
# doce puertas— no se entera de nada: mismo `CASA_ADENTRO`, mismo `CASA_PISO`,
# mismo `puerta.x` en ±1,35, mismos nodos `baja` y `alta` con la meta `afuera`
# en cada panel. Y `valle.gd` tampoco: mismo `CASA_LADO`, mismas `CASA_CARAS`.
#
# **El precio es 35% de estiramiento horizontal de la textura** (el panel se
# escala 1,35 en X y Z y entre 0,92 y 1,05 en Y). Sobre un revoque es invisible;
# sobre el ladrillo desparejo las hiladas quedan una vez y media más anchas que
# altas, y a 27 metros una hilada mide tres píxeles. Es el precio correcto: la
# alternativa era mover `CASA_LADO` a 6,10 m y con eso `CASA_MEDIA` se queda sin
# holgura y la gente camina rozando la pared.
#
# POR QUÉ NO HACEN FALTA PIEZAS DE ESQUINA PARA CERRAR. Un panel abarca su medio
# lado entero, así que dos paneles perpendiculares se superponen en el
# cuadradito de 0,27 × 0,27 de la esquina y cierran solos — igual que con
# Kenney. Lo que SÍ va en la esquina es `Corner_Exterior_Wood`, doce triángulos,
# y no es para tapar un agujero: es el poste de la estructura, y sin él las
# vigas de dos fachadas se cruzan en el aire.
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

## El hueco de la puerta, **medido rasterizando la malla `Wall_Plaster_Door_Round`
## y no leído de un comentario**: los montantes están en x = ±0,65 del panel y el
## arco cierra a y = 2,48 de sus 3,123. En metros, con el panel a 1,35 × ~1,0:
## **1,76 m de ancho por 2,28 a 2,60 de alto**. El jugador es una cápsula de 0,90
## de diámetro y 1,85 de alto: pasa con aire, que es más de lo que tenía con
## Kenney (1,08 de ancho, entraba justo).
const PUERTA_ANCHO := CASA_CELDA * 0.65
## Qué fracción de la altura del panel ocupa el arco. 2,48 / 3,123.
const PUERTA_ALTO := 0.794

## EL PERFIL EXACTO DEL HUECO, en unidades de panel y sacado del `.gltf`
## vértice por vértice, no de un comentario. Lo que hay ahí no es un
## semicírculo: es un **arco rebajado**. Las jambas están en x = ±0,653, el
## hueco sube recto hasta y = 2,152 y de ahí cierra con un arco de radio 0,811
## centrado en y = 1,671, que llega a 2,482. Comprobado contra tres vértices
## del medio del arco: a x = 0,345 la fórmula da 2,405 y la malla dice 2,401.
##
## Hace falta con este detalle porque la hoja tiene que entrar en el hueco: un
## milímetro de más y la puerta cerrada muestra una raja de luz, uno de menos y
## se ve el canto de la jamba por detrás.
const HUECO_MEDIO := 0.653
const HUECO_SALMER := 2.152
const HUECO_ARCO_R := 0.811
const HUECO_ARCO_Y := 1.671

## El hueco de la ventana, del mismo rasterizado sobre
## `Wall_Plaster_Window_Wide_Round`: x = ±0,61, y de 1,02 a 2,72. Es un hueco
## grande —1,65 × 1,72 m puesto en el valle— y eso tiene dos consecuencias que
## conviene decir en voz alta: de día es una mancha V2 mucho más grande en la
## fachada (que es lo que la paleta quiere, *de día una ventana es un agujero
## oscuro*) y de noche la casa da bastante más luz que antes.
const VENTANA_HUECO := Vector2(1.22, 1.70)
const VENTANA_CENTRO := 1.87

## El panel del Medieval Village MegaKit, tal cual sale del `.gltf`.
##
##   · ancho 2,000 (x de −1 a 1)
##   · alto  3,123 (y de 0 arriba)
##   · el revoque de 0,200 de espesor, con la cara de AFUERA en z = 0 y la de
##     adentro en z = −0,20. Las vigas asoman a +0,092 para afuera y a −0,314
##     para adentro; por eso el panel se coloca con su origen sobre la línea de
##     fachada y no en el centro de la celda, que es lo que hacía Kenney.
##   · y su normal de afuera es **+Z local**, no +X: por eso al giro de
##     `CASA_CARAS` hay que sumarle un cuarto de vuelta.
const PANEL_ANCHO := 2.0
const PANEL_ALTO := 3.123
const PANEL_ESPESOR := 0.20

## El factor horizontal. 2,000 × 1,35 = 2,70 = `CASA_CELDA`, o sea dos paneles
## por lado y la planta de siempre. Ver el encabezado.
const PANEL_ESCALA := CASA_CELDA / PANEL_ANCHO

## El poste de esquina `Corner_Exterior_Wood` mide 3,000 de alto contra los
## 3,123 del panel, así que lleva este factor de más o queda un escalón de once
## centímetros bajo el alero.
const POSTE_ALTO := PANEL_ALTO / 3.0

## Cuánto sube el techo sobre el alero, en metros, y cuánto se escala en planta.
##
## `Roof_RoundTiles_4x4` mide 5,513 de planta por 3,734 de alto (y baja otros
## 0,516 por debajo de su origen, que es el faldón que monta sobre el muro).
## A 1,20 de planta cubre 6,62 m sobre una casa de 5,40 — **0,61 m de alero
## volado por lado**, que es lo que le tira sombra a la fachada y lo que hace
## que una casa se lea como techada y no como tapada. El alto se ajusta para que
## la cumbrera quede en 3,2 m: 44° de pendiente, que es la familia de cuatro
## aguas empinadas que el valle ya habla.
const TECHO_ESCALA := 1.20
const TECHO_ALTO := 3.2

## Cuánto sobresale la chimenea POR ENCIMA del alero. El techo llega a 3,2 m en
## la cumbrera y la chimenea sale a 1,07 m del centro, donde el faldón anda por
## los 2,3: con 3,65 el caño asoma medio metro largo sobre la teja. **Su trabajo
## entero es silueta**; una chimenea que no pasa el techo no existe.
const CHIMENEA_ALTO := 3.65

## A qué altura sobre el alero llama `valle.gd` a `chimenea()`. **No es una
## constante de este archivo**: es el `alero + 1.25` que ese archivo ya usaba, y
## hay que saberla para poder anclar el caño al alero sin pedirle que cambie la
## llamada. Si algún día cambia allá, cambia acá.
const CHIMENEA_OFRECIDA := 1.25

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
## Devuelve `{"nodo", "alero", "alto", "puerta", "baja", "alta", "hoja"}`:
## `hoja` es la HOJA DE LA PUERTA, o `null` si la casa no tiene (la ruina no
## tiene). Quien la hace girar es `interiores.gd`; acá sólo se construye y se
## deja quieta en el marco de la casa. Ver el bloque `LA PUERTA`.
## `baja` y `alta` son las dos plantas separadas, y ésa es la mitad de que se
## pueda entrar — el recorte de `interiores.gd` apaga `alta` y los muros de
## `baja` que se le ponen delante a la cámara. Sin las dos plantas en nodos
## distintos habría que adivinarlo recorriendo el árbol en cada cuadro.
##
## `rng` se pasa de afuera a propósito: las casas ya se sorteaban en
## `_armar_lugar()` y el sorteo tiene que seguir saliendo de la misma corriente
## de azar.
##
## `piedra` elige la familia de muro —revoque o ladrillo desparejo—. Es la única
## variación de material: **una sola familia por casa.** Mezclar dos revoques en
## la misma pared es lo que hace que un kit modular se vea a kit modular. En el
## valle la familia es del LUGAR: Vado Bajo es de revoque, la Fragua de ladrillo.
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

	var fam := "quaternius/pueblo/Wall_UnevenBrick" if piedra else "quaternius/pueblo/Wall_Plaster"
	# Las plantas no son todas iguales de altas, y acá la variedad es MENOS que
	# antes a propósito: el panel mide 3,123 y estirarlo en Y es el único
	# estiramiento que se suma al 35% horizontal. Entre 0,92 y 1,05 la planta va
	# de 2,87 a 3,28 m —la misma franja que daba el `randf_range(0.95, 1.15)` de
	# celda de la casa de Kenney— y la anisotropía de la textura se queda entre
	# 1,29 y 1,47.
	var estira := rng.randf_range(0.92, 1.05)
	var alto_nivel := PANEL_ALTO * estira

	# La puerta va en una de las dos celdas del frente; la otra lleva ventana.
	# Cuál de las dos la decide el terreno: la que tenga el acceso más bajo.
	var lado: int = int(sitio.get("puerta", -1))
	if lado != 0 and lado != 1:
		lado = rng.randi() % CASA_FRENTE.size()
	var i_puerta: int = CASA_FRENTE[lado]
	var luz := _luz_de_ventana()
	var hoja: MeshInstance3D = null

	for nivel in CASA_NIVELES:
		var capa := baja if nivel == 0 else alta
		for i in CASA_CARAS.size():
			var celda: Vector2 = CASA_CARAS[i][0]
			var rot: float = CASA_CARAS[i][1]
			# Hacia dónde da este muro, en el marco de la casa y en el del mundo.
			# El segundo lo usa el recorte de `interiores.gd`: se apaga el muro
			# que la cámara tiene delante. Se anota ahora porque acá el dato es
			# una suma de dos ángulos y después habría que sacarlo de una matriz.
			var normal := Vector3.RIGHT.rotated(Vector3.UP, rot)
			var afuera := Vector3.RIGHT.rotated(Vector3.UP, giro + rot)
			# El panel se apoya sobre la línea de fachada, no en el centro de la
			# celda: su revoque va de z = 0 (afuera) a z = −0,20 (adentro).
			var pos := Vector3(celda.x * CASA_CELDA, nivel * alto_nivel,
				celda.y * CASA_CELDA) + normal * (CASA_CELDA * 0.5)

			var pieza := fam + "_Straight"
			var ventana := false
			var es_puerta := false

			if quemada:
				# LA CASA QUEMADA. El MegaKit \[Standard] no trae piezas rotas
				# —el que las tiene es Ultimate Modular Ruins, que no publica
				# glTF; queda pedido en `PROCEDENCIA.md`—, así que la ruina se
				# cuenta con lo que sí hay, y son dos cosas:
				#
				#  · **LA PLANTA ALTA NO ESTÁ.** El fuego sube: se lleva el
				#    techo y el entrepiso y deja la mampostería de abajo parada.
				#    Una ruina de dos plantas con un tercio de los muros
				#    faltando se leía —medido mirando el banco— como una caja
				#    marrón entera, no como algo que se quemó. **El corte de
				#    silueta a media altura es lo que lo cuenta**, y es la misma
				#    regla de siempre: la silueta hace el trabajo.
				#  · y de la que queda faltan cuatro de cada diez paneles.
				if nivel == 1 or rng.randf() < 0.40:
					continue
			elif nivel == 0 and i == i_puerta:
				pieza = fam + "_Door_Round"
				es_puerta = true
			elif i in CASA_FRENTE or rng.randf() < (0.30 if nivel == 1 else 0.0):
				# Ventanas: siempre al frente, y a veces en los costados de
				# arriba. El hueco de Quaternius es casi el doble de ancho que el
				# de Kenney, así que con la misma cantidad de ventanas la casa se
				# volvía un farol: abajo van sólo al frente.
				pieza = fam + "_Window_Wide_Round"
				ventana = true
			elif nivel == 1 and not piedra and rng.randf() < 0.55:
				# EL ENTRAMADO, y va sólo arriba porque ahí va en una casa de
				# verdad: abajo la mampostería aguanta el peso y arriba se
				# ahorra en piedra. Es la pieza que más hace por la lectura
				# medieval y es un par de valores, V3 sobre V6.
				pieza = "quaternius/pueblo/Wall_Plaster_WoodGrid"
			elif nivel == 0 and not piedra and rng.randf() < 0.5:
				# El zócalo de ladrillo bajo el revoque: la misma casa, con el
				# pie mojado. V3 abajo de V6, otro par de valores gratis.
				pieza = "quaternius/pueblo/Wall_Plaster_Straight_Base"

			var mi := Kit.nodo(pieza)
			if mi == null:
				continue
			mi.position = pos
			# La normal de afuera del panel es +Z local y la de `CASA_CARAS` es
			# +X: de ahí el cuarto de vuelta.
			mi.rotation.y = rot + PI / 2.0
			mi.scale = Vector3(PANEL_ESCALA, estira, PANEL_ESCALA)
			mi.set_meta("afuera", afuera)
			capa.add_child(mi)

			if ventana:
				var v := _vidrio(mi, luz)
				v.set_meta("afuera", afuera)
				capa.add_child(v)

			# LA HOJA. El gozne va contra la pared lateral más cercana —o sea
			# del lado de la celda en que cayó la puerta— y no en el otro: con
			# el gozne del lado de adentro, la hoja abierta queda cruzada en el
			# medio del cuarto de cinco metros en vez de pegada a un rincón.
			if es_puerta:
				hoja = _hoja(capa, mi, signf(celda.x), estira, afuera)

			# La colisión SIGUE A LO CONSTRUIDO. Un tabique por panel de planta
			# baja, y en el de la puerta, dos jambas con el hueco en el medio.
			# Los muros de la ruina no llevan: por ahí se entra.
			if nivel == 0 and not quemada:
				_tabique(g, pos, rot, alto_nivel, es_puerta)

		# Los cuatro postes de esquina de esta planta. Doce triángulos cada uno y
		# son lo que hace que las vigas de dos fachadas se junten en algo en vez
		# de cruzarse en el aire. Llevan la meta `afuera` en diagonal para que el
		# recorte los trate como a los muros: dos de los cuatro le quedan
		# adelante a la cámara cuando entrás.
		if not quemada:
			_postes(capa, nivel * alto_nivel, estira, giro)

	var alero := CASA_NIVELES * alto_nivel
	if not quemada:
		# La cumbrera. Es la variación que le queda al techo —el kit trae una
		# sola cubierta de 4×4— y va en la PENDIENTE, que es lo que se lee contra
		# el cielo: de 2,9 a 3,5 m sobre un alero de 5,7 a 6,6.
		var alto_techo := TECHO_ALTO * rng.randf_range(0.92, 1.09)
		_gablete(alta, alero, alto_techo)
		_techo(alta, alero, alto_techo)
	else:
		_quemar(g, baja, alta, alto_nivel, rng)

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
		"puerta": puerta, "baja": baja, "alta": alta, "hoja": hoja,
	}


## Los cuatro postes de esquina de una planta. Ver `POSTE_ALTO`.
static func _postes(capa: Node3D, y: float, estira: float, giro: float) -> void:
	var r := CASA_LADO / 2.0 - 0.08
	for s: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var mi := Kit.nodo("quaternius/pueblo/Corner_Exterior_Wood")
		if mi == null:
			return
		mi.position = Vector3(s.x * r, y, s.y * r)
		mi.scale = Vector3(PANEL_ESCALA, estira * POSTE_ALTO, PANEL_ESCALA)
		mi.set_meta("afuera",
			Vector3(s.x, 0, s.y).normalized().rotated(Vector3.UP, giro))
		capa.add_child(mi)


## Un tabique de la planta baja, del tamaño del panel que se acaba de poner.
##
## `pos` es la posición del panel en el marco de la casa —o sea, sobre la línea
## de fachada— y `rot` el giro de `CASA_CARAS`, el que lleva la normal de afuera
## a +X local. El revoque va de la fachada hacia ADENTRO, así que su eje cae
## medio espesor por detrás: de ahí el signo menos.
##
## Con `puerta`, en vez de una caja van dos jambas: el hueco de
## `Wall_Plaster_Door_Round` mide 1,76 m y lo que queda a cada lado son 0,47.
static func _tabique(g: Node3D, pos: Vector3, rot: float, alto: float,
		puerta: bool) -> void:
	var eje := -CASA_MURO * 0.5
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


# ===========================================================================
# LA PUERTA — QUÉ SEPARA UN DECORADO DE UN EDIFICIO
#
# Hasta el 18 de agosto **el valle no tenía una sola puerta**. Tenía huecos: se
# entraba caminando a las doce casas y eso ya era mucho más de lo que había
# antes, pero un hueco no es una puerta. Una puerta tarda, se queda abierta,
# hace ruido y **decide si estás adentro o afuera**; un hueco no hace nada de
# eso y por eso una aldea entera de huecos se lee como una maqueta seccionada.
#
# QUÉ SIGNIFICA, que es la pregunta que manda `CLAUDE.md`. Tres cosas, y las
# tres ya existían en el mundo y no se veían:
#
#  1. **De noche la gente se vuelve a su casa.** Lo hace `rutinaDe()` en el
#     servidor desde hace días, y `dialogo.ts` devuelve una línea propia para el
#     que duerme: *"La puerta de Sarn está cerrada y no hay luz"*. Hasta hoy esa
#     frase era una metáfora — no había puerta y no estaba cerrada. Ahora sí.
#  2. **La luz del hogar sale por la puerta o no sale.** El omni del cuarto
#     tiene sombra (ver `Interiores.LUZ_HOGAR`), así que **una hoja cerrada le
#     tapa el paso**: de noche, una casa con la puerta cerrada tiene la ventana
#     encendida y el umbral a oscuras, y cuando la puerta se abre cae una cuña
#     naranja sobre los escalones. Eso es lo que se ve a veinte metros, y es
#     gratis: no hay una línea de código de iluminación acá abajo.
#  3. **Es lo primero del valle que te contesta.** Te acercás y se abre; te vas
#     y se cierra. Es un verbo, aunque sea el más chico posible.
#
# LO QUE **NO** HACE, Y ES DELIBERADO:
#
#  · **La hoja no tiene colisión.** Tres motivos, en orden de peso:
#      – Se entra a las doce casas y eso está verificado con un barrido de la
#        cápsula del jugador contra la colisión de la casa
#        (`prueba_casas.gd::_medir_puertas()`), un barrido en el que no hay
#        jugador y por lo tanto tampoco hay nada que abra la puerta. Una hoja
#        sólida haría fallar la prueba que garantiza que se puede entrar.
#      – Peor que eso: una hoja sólida convierte cualquier falla de la lógica de
#        apertura —una casa sin registrar, un cuadro perdido— en **una casa a la
#        que no se puede entrar**, que es exactamente el bug que esta rama vino a
#        arreglar. Una puerta de presentación no puede poder dejarte afuera.
#      – Y una puerta que te FRENA es una regla del mundo, no una imagen de él.
#        Ver el invariante 4: si algún día una puerta tiene que estar cerrada con
#        llave, eso es estado y es del servidor. Acá no se inventa.
#  · **No hace ruido**, y es lo único que le falta de la lista de arriba. El
#    ruido se sintetiza en `sonido.gd`, que es de otra rama. Está pedido.
#
# LA GEOMETRÍA, contada y no estimada: **36 triángulos la hoja** (la tabla y sus
# dos travesaños) **y 14 el tímpano**, o sea 50 por casa y 600 en las doce,
# contra los 23.400 que ya cuestan los techos. El tímpano no es un adorno: sin
# él, una puerta "cerrada" deja un ojo de buey abierto arriba por donde se ve el
# cuarto de día y sale la luz del hogar de noche.
#
# Y por qué la hoja lleva travesaños si a 27 m no se ve un herraje: porque la
# hoja va en `MADERA` (V1) contra un muro V6, o sea que **una puerta cerrada y un
# agujero negro son la misma mancha**. Los dos travesaños en V3 son lo único que
# distingue una cosa de la otra desde la calle. Son 24 de los 62 triángulos y se
# los gana.
# ===========================================================================

## Cuánto más chica que el hueco es la hoja, por lado. Con cero, la hoja y la
## jamba comparten plano y pelean por el mismo píxel (z-fighting).
const HOJA_HOLGURA := 0.015
## El espesor de la tabla, en unidades de panel: 5,5 cm puestos en el valle.
const HOJA_ESPESOR := 0.055
## A qué profundidad del revoque cuelga. El muro va de z = 0 (calle) a −0,20
## (cuarto): con la hoja en −0,115 queda el canto de la jamba visible desde
## afuera, que es de dónde sale que una puerta parezca metida en un muro y no
## pegada encima.
const HOJA_PLANO := -0.115
## A qué altura de la hoja van los dos travesaños, de 0 (el piso) a 1 (el
## dintel). No están simétricos: una puerta de tablas lleva el de abajo más
## abajo que el de arriba porque es el que aguanta el peso.
const HOJA_TRAVESANOS: Array[float] = [0.26, 0.72]


## Construye la hoja y el tímpano del hueco de la puerta y devuelve la hoja.
##
## `panel` es el muro del kit que se acaba de poner: la hoja se cuelga en el
## mismo nodo (`capa`) **con la transformación del panel aplicada a mano**, que
## es el mismo truco que `_vidrio()` y por el mismo motivo — así hereda la
## escala del panel sin quedar colgada de su visibilidad, y el recorte de
## `interiores.gd` la puede apagar por separado con su propia meta `afuera`.
##
## La malla se construye con el ORIGEN EN EL GOZNE, y eso es lo que hace que
## abrirla sea `transform = base.rotated_local(UP, ángulo)` y nada más: sin eso
## habría que recomponer una traslación y un giro en cada cuadro. La escala del
## panel es `(1.35, estira, 1.35)` —simétrica en X y Z— así que conmuta con un
## giro sobre Y y la hoja no se deforma al abrirse. Si algún día el panel se
## escalara distinto en X que en Z, esto se rompe y hay que componer a mano.
static func _hoja(capa: Node3D, panel: MeshInstance3D, signo: float,
		estira: float, afuera: Vector3) -> MeshInstance3D:
	if signo == 0.0:
		signo = 1.0
	var media := HUECO_MEDIO - HOJA_HOLGURA
	# El pie de la hoja es el PISO DEL CUARTO, no el cero de la casa: los siete
	# centímetros de las tablas también los tapa la puerta. En unidades de
	# panel, o sea dividido por el estirado en Y de esta casa.
	var y0 := CASA_PISO / maxf(estira, 0.1)
	var y1 := HUECO_SALMER - 0.012
	var e := HOJA_ESPESOR * 0.5
	# La hoja va del gozne hasta la otra jamba, o sea siempre hacia el otro lado.
	var libre := -signo * (media * 2.0)

	_timpano(capa, panel, media, y1, afuera)

	var malla := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_caja(st, Vector3(minf(0.0, libre), y0, -e), Vector3(maxf(0.0, libre), y1, e))
	st.generate_normals()
	st.commit(malla)
	# `MADERA` es V1 y la paleta ya dice por qué: *contra un muro V6 una puerta
	# tiene que leerse como un AGUJERO*. Con grano, porque nada es liso.
	malla.surface_set_material(0, Paleta.gastar(Paleta.madera(Paleta.MADERA), 0.7))

	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f: float in HOJA_TRAVESANOS:
		var y := lerpf(y0, y1, f)
		_caja(st,
			Vector3(minf(0.0, libre) + 0.035, y - 0.052, -e - 0.013),
			Vector3(maxf(0.0, libre) - 0.035, y + 0.052, e + 0.013))
	st.generate_normals()
	st.commit(malla)
	malla.surface_set_material(1, Paleta.gastar(Paleta.madera(Paleta.TRONCO_CLARO), 0.5))

	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.transform = panel.transform * Transform3D(Basis(),
		Vector3(HUECO_MEDIO * signo, 0.0, HOJA_PLANO))
	mi.set_meta("afuera", afuera)
	capa.add_child(mi)
	return mi


## El tímpano: el paño fijo que llena el arco por encima del dintel de la hoja.
##
## Es carpintería de verdad —una hoja que siguiera el arco no podría girar, se
## trabaría contra la jamba— y además resuelve un agujero: sin él, la puerta
## cerrada deja el arco abierto y de noche sale por ahí la luz del hogar.
##
## Va doblado (las dos caras) por lo mismo que el gablete: se ve desde la calle
## y desde adentro, y una cara sola desaparece de un lado.
static func _timpano(capa: Node3D, panel: MeshInstance3D, media: float,
		y1: float, afuera: Vector3) -> void:
	var radio := HUECO_ARCO_R - 0.012
	var tramos := 6
	var arco := PackedVector2Array()
	for k in tramos + 1:
		var x := lerpf(-media, media, float(k) / float(tramos))
		arco.append(Vector2(x, HUECO_ARCO_Y + sqrt(maxf(radio * radio - x * x, 0.0))))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pivote := Vector2(-media, y1)
	var borde := PackedVector2Array(arco)
	borde.append(Vector2(media, y1))
	for k in borde.size() - 1:
		for tri: Array in [[0, 1, 2], [0, 2, 1]]:
			for idx: int in tri:
				var p: Vector2 = (pivote if idx == 0
					else (borde[k] if idx == 1 else borde[k + 1]))
				st.add_vertex(Vector3(p.x, p.y, 0.0))
	st.generate_normals()

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Paleta.gastar(Paleta.madera(Paleta.MADERA), 0.7)
	mi.transform = panel.transform * Transform3D(Basis(),
		Vector3(0.0, 0.0, HOJA_PLANO))
	mi.set_meta("afuera", afuera)
	capa.add_child(mi)


## Una caja de caras planas dentro de un `SurfaceTool` que ya está abierto.
##
## Existe para poder meter varias piezas en una sola malla —la hoja y sus dos
## travesaños son tres cajas y un solo nodo— y con el winding que pide
## `CLAUDE.md`: `[0,1,2]/[0,2,3]` y `generate_normals()` después. El winding al
## revés deja las normales para adentro y la pieza no recibe sol.
static func _caja(st: SurfaceTool, a: Vector3, b: Vector3) -> void:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var v: Array[Vector3] = [
		Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z),
		Vector3(hi.x, hi.y, lo.z), Vector3(lo.x, hi.y, lo.z),
		Vector3(lo.x, lo.y, hi.z), Vector3(hi.x, lo.y, hi.z),
		Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z),
	]
	for cara: Array in [[4, 5, 6, 7], [1, 0, 3, 2], [5, 1, 2, 6],
			[0, 4, 7, 3], [3, 7, 6, 2], [0, 1, 5, 4]]:
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for k: int in tri:
				st.add_vertex(v[cara[k]])


# ===========================================================================
# LA CASA QUEMADA — EL INCENDIO SE VE, NO SE CUENTA
#
# El valle tiene un pasado escrito en la base del servidor: **un incendio de
# hace sesenta inviernos con dos versiones irreconciliables de quién lo
# empezó**, y un claro que la aldea taló para las vigas. Es la pieza de historia
# más vieja del juego y hasta el 18 de agosto **el cliente no la mostraba**: la
# Casa Quemada era la misma casa que las otras once, con un tercio de los muros
# faltando y sin techo. Un muro faltante dice "esto se cayó". No dice "esto se
# quemó", que es otra cosa y es la que importa — la aldea entera se acuerda de
# ese fuego y no se pone de acuerdo sobre él.
#
# Lo que hace un incendio, y es lo que se hace acá, en orden de cuánto se lee a
# 27 metros:
#
#  1. **BAJA EL VALOR, Y BAJA MÁS ARRIBA.** El fuego sube. La planta alta queda
#     casi negra y la baja tiznada, y ese GRADIENTE VERTICAL es la firma: una
#     ruina pareja se lee como piedra vieja, una ruina con la parte de arriba
#     más negra que la de abajo se lee como fuego. Va con `Kit.tinte()`, que
#     multiplica el albedo sin tocar la malla compartida por las otras casas.
#     La paleta ya dice dónde tiene que terminar: `MURO_RUINA` es V3, **el único
#     muro FRÍO del archivo**, y está por debajo del suelo a propósito — es lo
#     único construido que no levanta la vista.
#  2. **VIGAS QUEMADAS CONTRA EL CIELO.** Cuatro palos inclinados donde estaba
#     el techo. Es silueta pura, que es lo único que se lee a esta distancia, y
#     es lo que distingue un esqueleto de una caja rota. Doce triángulos cada
#     uno.
#  3. **LO QUE SE CAYÓ ESTÁ EN EL SUELO.** Tres troncos del kit tirados
#     alrededor del zócalo. Una ruina sin escombros es una maqueta de ruina: lo
#     que se derrumbó tiene que estar en algún lado.
#
# Lo que NO se hace y por qué: nada de partículas de humo ni brasas. **Hace
# sesenta inviernos.** Un rescoldo encendido convierte una herida vieja en un
# incendio de anteayer, y el tono del juego es Frieren — historia vieja que
# pesa, no una emergencia.
# ===========================================================================

## Cuánto se le baja el valor a cada planta. La alta casi al carbón (V1–V2), la
## baja tiznada (V3–V4). Son multiplicadores sobre el albedo del kit, así que
## un muro `MURO_ALDEA` (V6, 0.66) sale en 0.46 abajo y en 0.30 arriba: V4 y
## V3, que es exactamente donde la paleta pone `MURO_RUINA`.
##
## **Los dos números se mudaron a `paleta.gd`** el día que los necesitó un
## segundo archivo (`interiores.gd`, para los muebles de la ruina), que es
## exactamente cuándo un color suelto deja de ser una comodidad y pasa a ser dos
## colores que se van a separar. El porqué de los valores —incluido que son
## CÁLIDOS a propósito, medido: neutros salían h176 s0,39, azul verdoso— está
## allá, con el resto de la escalera.
const HOLLIN_BAJO := Paleta.HOLLIN_BAJO
const HOLLIN_ALTO := Paleta.HOLLIN_ALTO


## Le pone al esqueleto de la casa las marcas del fuego. Ver el bloque de arriba.
static func _quemar(g: Node3D, baja: Node3D, alta: Node3D, alto_nivel: float,
		rng: RandomNumberGenerator) -> void:
	# El gradiente vertical, ahora DENTRO de la única planta que queda: la parte
	# de arriba del muro tiznada casi al carbón y el pie apenas ahumado. `alta`
	# viene vacía —el fuego se llevó el piso de arriba entero— pero se recorre
	# igual, que es lo barato y lo que aguanta que mañana quede algo ahí.
	for capa: Array in [[baja, HOLLIN_BAJO], [alta, HOLLIN_ALTO]]:
		var nodo: Node3D = capa[0]
		var tinte: Color = capa[1]
		for h in nodo.get_children():
			if h is MeshInstance3D:
				# Cada panel un poco distinto: un incendio no quema parejo, y
				# ocho paneles del mismo negro vuelven a ser un estampado.
				var v := rng.randf_range(0.82, 1.18)
				Kit.tinte(h as MeshInstance3D, Color(tinte.r * v, tinte.g * v, tinte.b * v))

	# (2) Las vigas. Salen del borde de arriba del muro que quedó parado y se
	# cruzan en el aire, como queda un techo cuando se le va el machimbre y
	# aguantan los pares. **Ahora asoman por encima de una sola planta**, o sea
	# que el corte de silueta a media altura de la casa vecina es lo primero que
	# se lee de la ruina — que es de lo que se trata.
	var viga_mat := Paleta.madera(Paleta.MADERA)
	for k in 5:
		var caja := BoxMesh.new()
		caja.size = Vector3(0.16, rng.randf_range(1.6, 3.0), 0.16)
		caja.material = viga_mat
		var mi := MeshInstance3D.new()
		mi.mesh = caja
		var a := TAU * (float(k) + rng.randf_range(-0.18, 0.18)) / 5.0
		var r := CASA_CELDA * rng.randf_range(0.45, 0.88)
		mi.position = Vector3(cos(a) * r, alto_nivel * 0.82, sin(a) * r)
		mi.rotation = Vector3(rng.randf_range(-0.5, 0.5), a, rng.randf_range(-0.5, 0.5))
		g.add_child(mi)

	# (3) Los escombros. Troncos del kit, tirados de costado, tiznados al mismo
	# carbón que la planta alta. **Van pegados al zócalo y no repartidos por el
	# prado**: acá no se sabe la altura del terreno —eso lo sabe `valle.gd`— y un
	# tronco apoyado en la nada flota. Sobre el basamento no hay ese riesgo.
	#
	# **Y estaban PARADOS DE PUNTA, que es lo contrario de un escombro.** Acá
	# había un `rotation.z = PI/2` con el motivo *"tirados de costado"* al lado, y
	# el tronco de Kenney ya viene acostado: mide 1,00 × 0,42 × 0,55 y es largo en
	# X (medido con `prueba_casas.tscn -- --medir`, no estimado). O sea que el
	# giro que iba a acostarlo lo paraba, y encima le enterraba media pieza. Ahora
	# lo vuelca `Kit.tumbar()`, que elige el eje midiendo el bulto y después
	# **apoya la pieza**, que es la parte que nadie hace a mano y es la que falla.
	#
	# El radio bajó de 0,8 a 0,72 de `CASA_ADENTRO` por lo mismo que se midió: un
	# tronco de un metro con el centro a 1,94 m del medio del cuarto mete media
	# cabeza afuera del muro.
	for k in 4:
		var mi := Kit.nodo("naturaleza/log_large")
		if mi == null:
			break
		var a := TAU * (float(k) + rng.randf_range(-0.3, 0.3)) / 4.0
		mi.scale = Vector3.ONE * rng.randf_range(0.7, 1.2)
		mi.position = Vector3(cos(a) * CASA_ADENTRO * 0.72, CASA_PISO,
			sin(a) * CASA_ADENTRO * 0.72)
		Kit.tumbar(mi, rng, CASA_PISO, 0.04)
		Kit.tinte(mi, HOLLIN_ALTO)
		g.add_child(mi)


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
	# En la ruina el basamento también se tiznó. Baja de V5 a V3 y se enfría:
	# es el mismo peldaño y el mismo criterio que `MURO_RUINA`, que la paleta
	# describe como *"piedra quemada, y es el único muro FRÍO"*. Sin esto la
	# Casa Quemada queda parada sobre un basamento nuevo y reluciente, que es
	# justo el detalle que delata que la ruina es decorado.
	caja.material = Paleta.piedra(Paleta.MURO_RUINA if quemada else Paleta.LOSA_CAMINO)
	var mi := MeshInstance3D.new()
	mi.mesh = caja
	mi.position.y = -alto / 2.0
	g.add_child(mi)

	var tablas := BoxMesh.new()
	tablas.size = Vector3(CASA_ADENTRO * 2.0, CASA_PISO, CASA_ADENTRO * 2.0)
	# Adentro no queda tabla: queda ceniza. V2, un peldaño por debajo del muro
	# tiznado de la planta baja, para que el cuarto se lea como un pozo negro
	# desde arriba — que es de donde lo mira la cámara.
	tablas.material = (Paleta.piedra(Paleta.TECHO) if quemada
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
	# El sobreancho bajó de 0,70 a 0,35 cuando la puerta pasó de 1,08 a 1,76 m:
	# con el de antes, el escalón medía 2,46 sobre un panel de 2,70 y la casa se
	# leía apoyada en una tarima. La proporción es lo que importa, no el número.
	var ancho := PUERTA_ANCHO + 0.35
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


## EL GABLETE — el triángulo que cierra los dos hastiales.
##
## **Y sin esto la casa tiene dos agujeros.** `Roof_RoundTiles_4x4` es un techo a
## DOS aguas, no a cuatro: rasterizado, su silueta contra el eje X es un
## triángulo y contra el eje Z es un rectángulo, o sea que la cumbrera corre
## paralela a Z y las dos caras Z quedan abiertas de par en par. En el banco se
## veía como un hueco negro bajo la cumbrera — se veía el interior de la casa
## desde la calle.
##
## El kit trae `Roof_Front_Brick4` para eso y **no encaja**: su pendiente es de
## 48,7° contra los 57,6° del techo, así que al ponerlos juntos o queda medio
## metro de ranura o la fachada asoma por encima de la teja. Se probó con
## números antes de descartarlo.
##
## Así que el gablete se genera acá, y por construcción sigue EXACTAMENTE la
## línea de abajo del techo: cinco vértices, tres triángulos, doblados para que
## se vea de los dos lados. Doce triángulos por casa.
##
## **Va en madera (`MURO_FRAGUA`, V5) y no en revoque**, y es una decisión de
## valor y no de carpintería: entablar el hastial es lo que se hace de verdad
## —arriba no hay quien sostenga mampostería— y deja un peldaño entre el muro
## (V5,5 medido) y el techo (V2), que es lo que le da espesor a la tapa de la
## casa. Con grano, porque nada es liso.
##
## **La primera versión lo puso en `TRONCO_CLARO` (V3) y midió luma 18 contra
## 106 del muro**: a esa altura el hastial dejaba de ser una tabla y se leía
## como el agujero que vino a tapar. Es el mismo límite que ya está anotado en
## el hollín de la Casa Quemada — *una superficie grande por debajo de V2/V3 deja
## de tener color propio y adopta el del cielo*, y la cara del gablete que ve la
## cámara casi siempre está en sombra.
##
## `PENDIENTE_TECHO` sale de la malla: (3,734 + 0,516) de alto sobre 2,757 de
## medio ancho, corregido por las dos escalas con que se pone el techo.
const PENDIENTE_TECHO := (3.734 + 0.516) / (3.734 * 2.757 * TECHO_ESCALA)


static func _gablete(g: Node3D, alero: float, cumbrera: float) -> void:
	var half := CASA_LADO / 2.0
	# A qué altura pasa la cara de abajo del techo justo sobre la pared. Con el
	# alero volado 0,61 m, el techo todavía está subiendo cuando cruza el muro.
	var ceja := maxf(cumbrera - PENDIENTE_TECHO * cumbrera * half, 0.0)
	var perfil := PackedVector2Array([
		Vector2(-half, 0.0), Vector2(half, 0.0), Vector2(half, ceja),
		Vector2(0.0, cumbrera), Vector2(-half, ceja),
	])
	var mat := Paleta.gastar(Paleta.madera(Paleta.MURO_FRAGUA), 2.4)
	# El gablete se planta en el medio del espesor del muro, para que su canto
	# no asome ni por afuera ni adentro del cuarto.
	var z := half - CASA_MURO * 0.5
	for lado: float in [1.0, -1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for k in 3:
			# Las dos vueltas: una por cara. El hastial se ve desde la calle y
			# desde adentro del desván, y una cara sola desaparece de un lado.
			for tri: Array in [[0, k + 1, k + 2], [0, k + 2, k + 1]]:
				for idx: int in tri:
					var p: Vector2 = perfil[idx]
					st.add_vertex(Vector3(p.x, alero + p.y, z * lado))
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		g.add_child(mi)


## El techo: la tapa oscura de la casa, y a 27 metros es la mitad de lo que hace
## que una caja se lea como casa.
##
## `Roof_RoundTiles_4x4` es una cubierta a cuatro aguas con teja curva, faldón
## que monta sobre el muro y alero volado. Es la misma SILUETA que tenía la
## pirámide de Kenney —y que el cono de cuatro caras antes que ella—, y eso es
## deliberado: la familia de cuatro aguas ya es parte del lenguaje del valle,
## tanto que `vegetacion.gd` la nombra al explicar por qué las copas tienen
## facetas duras. Lo que cambia no es la forma: es que la tapa ahora tiene teja.
##
## **Cuesta 1.996 triángulos contra 44, y ése era el segundo bloqueo anotado.**
## Se desarmó contando bien: el valle tiene DOCE casas, no cuarenta. Son +23,4
## mil triángulos contra los ~135 mil que ya pone el bosque.
##
## **La cumbrera corre paralela a Z**, o sea perpendicular al frente de la casa,
## y no se sortea: el gablete de `_gablete()` está calculado para esa
## orientación, y girar el techo sin girar el gablete es dejar el hueco abierto
## en el otro lado. La variedad ya está en la pendiente y en la altura de planta.
static func _techo(g: Node3D, alero: float, cumbrera: float) -> void:
	var mi := Kit.nodo("quaternius/pueblo/Roof_RoundTiles_4x4")
	if mi == null:
		return
	mi.position = Vector3(0.0, alero, 0.0)
	mi.scale = Vector3(TECHO_ESCALA, cumbrera / 3.734, TECHO_ESCALA)
	g.add_child(mi)


## El vidrio encendido de una ventana del kit.
##
## **Y ahora tapa un agujero de verdad**, que es la diferencia entera con la
## casa anterior: en Kenney la ventana estaba PINTADA sobre una cara plana y
## esta placa era un parche encima; en `Wall_Plaster_Window_Wide_Round` el hueco
## está calado, así que sin la placa se ve el interior desde la calle. La placa
## la cierra por el medio del espesor del revoque, con la jamba asomando a los
## dos lados — que es de dónde sale que una ventana parezca hecha en un muro.
##
## El nodo se cuelga en el marco del PADRE con la transformación del muro
## aplicada a mano, y no como hijo del muro, porque así hereda su escala sin
## quedar sujeto a su visibilidad: el recorte de `interiores.gd` apaga muros y
## vidrios por separado, cada uno con su meta `afuera`.
##
## **Esto no es un detalle que se pueda perder al migrar.** Una ventana
## encendida dice "adentro hay alguien" más fuerte que todo el cielo junto, y
## está anotado como decisión del valle. Lo que sí cambió es el TAMAÑO: el hueco
## de Quaternius mide 1,22 × 1,70 del panel, o sea 1,65 × 1,70 m puestos, contra
## los 0,92 × 0,99 de la placa de Kenney. De noche la aldea da más luz; de día
## es más mancha V2 en la fachada, que es lo que la paleta quiere.
static func _vidrio(muro: MeshInstance3D, luz: StandardMaterial3D) -> MeshInstance3D:
	var v := BoxMesh.new()
	# Un pelo más chico que el hueco, para que se vea el canto de la jamba.
	v.size = Vector3(VENTANA_HUECO.x - 0.08, VENTANA_HUECO.y - 0.10, 0.05)
	v.material = luz
	var mi := MeshInstance3D.new()
	mi.mesh = v
	# En el marco local del panel: el hueco está centrado en x, su centro de
	# altura en `VENTANA_CENTRO` y el revoque va de z = 0 (afuera) a −0,20.
	mi.transform = muro.transform * Transform3D(
		Basis(), Vector3(0.0, VENTANA_CENTRO, -0.10))
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
	#
	# **Y con el techo nuevo hubo que hacerla más alta o dejaba de existir.** El
	# de teja llega a 3,2 m sobre el alero contra los ~2,7 de la pirámide de
	# Kenney, y la chimenea de antes —1,49 m centrada en alero + 1,25— terminaba
	# ENTERA adentro del faldón. Ahora el caño arranca al ras del alero (de ahí
	# `CHIMENEA_OFRECIDA`, que es dónde la llama `valle.gd`), se hunde 0,8 m en
	# el entrepiso porque una chimenea baja hasta el hogar, y sale a
	# `CHIMENEA_ALTO`. Queda un caño flaco y alto en vez de un bulto, que además
	# es lo que es.
	var base := pos.y - CHIMENEA_OFRECIDA - 0.8
	var alto := CHIMENEA_ALTO + 0.8
	var ladrillo := Paleta.piedra(Paleta.LADRILLO)
	var c := BoxMesh.new()
	c.size = Vector3(ancho * 0.22, alto, ancho * 0.22)
	c.material = ladrillo
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = Vector3(pos.x, base + alto / 2.0, pos.z)
	padre.add_child(mi)

	# El humo sale de la boca del caño, no de la mitad. Con el techo viejo daba
	# lo mismo; con éste, medio metro más abajo es humo saliendo de la teja.
	padre.add_child(_humo(Vector3(pos.x, base + alto + 0.15, pos.z)))
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
##
## ===========================================================================
## DOS COSAS QUE CAMBIARON EL 18 DE AGOSTO, Y LAS DOS SON DE ARTE
## ===========================================================================
##
## **1. LAS PIEDRAS NO ERAN PIEDRAS.** El comentario de acá abajo decía que a la
## roca del kit *"no se le pisa el material: viene con el suyo del atlas de
## Kenney"*. Eran dos frases falsas en una. `rock_smallA.glb` **no usa atlas** —
## el Nature Kit no tiene texturas, el color va en el material— y sus dos
## materiales no se llaman `stone`: se llaman **`grass` y `dirt`**, leído
## abriendo el `.glb`. La aduana los mandaba a `COPA_CLARA` y `TIERRA`, los dos
## en V4, o sea al mismo peldaño que el suelo. Las 320 piedras que este archivo
## llama *"la puntuación clara del cuadro"* eran 320 manchas invisibles.
##
## Arreglado en `Paleta.KIT_CONTEXTO`, por ruta: el cuerpo va a `ROCA` (V6) y la
## tapa a `PASTO` (V3). Una piedra con musgo, no un terrón.
##
## **2. EN GRUPOS, NO REPARTIDAS PAREJO.** `cantidad` ya no es la cuenta de
## piedras: es la cuenta de **grupos**, y cada grupo trae de 2 a 6. Las piedras
## no están espolvoreadas por el prado; afloran juntas donde afloran. Es la
## segunda de las tres reglas de `naturaleza.md` —*una distribución uniforme es
## lo que más grita "generado por computadora"*— y de paso multiplica por ~3,6
## la cantidad sin tocar `valle.gd`, que es de otra rama: 320 grupos dan ~1.150
## piedras y siguen siendo 16 triángulos cada una.
##
## Los miembros de un grupo se agregan seguidos a propósito. `rendimiento.gd`
## ralea con `visible_instance_count`, o sea que se queda con las primeras N de
## cada baldosa: con los grupos seguidos, ralear deja grupos ENTEROS de menos, y
## no medio grupo cortado por la mitad.
##
## **Y hay cuatro piedras distintas en el kit, no una.** La malla se sortea por
## baldosa (determinista, sale de la celda) así que un rincón del valle tiene
## sus piedras y otro las suyas, y sigue habiendo un solo MultiMesh por baldosa.
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
		# A la roca del kit se le pisa el color en la aduana, por ruta, porque
		# sus materiales se llaman `grass` y `dirt` y no `stone`. Ver el
		# encabezado de esta función y `Paleta.KIT_CONTEXTO`.
		esfera.material = Paleta.piedra(Paleta.PIEDRA_SUELTA)
		roca = esfera

	# Las cuatro piedras del kit. `rock_tallC` es el peñón —0,78 de alto contra
	# 0,19— y por eso va sola en la lista de las chatas: sale una de cada
	# cuatro baldosas y es la que rompe la línea del horizonte del prado.
	var mallas: Array[Mesh] = []
	for r in ["naturaleza/rock_smallA", "naturaleza/rock_smallB",
			"naturaleza/rock_smallD", "naturaleza/rock_tallC"]:
		var m := Kit.malla(r)
		if m != null:
			mallas.append(m)
	if mallas.is_empty():
		mallas.append(roca)

	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	# `cantidad` son GRUPOS. Cada uno tira de 2 a 6 piedras en un radio de 1,4 m
	# alrededor del punto sorteado, y las escalas de un grupo no son iguales: una
	# grande y las otras el resto, que es como se ve un afloramiento y no un
	# puñado de bolitas.
	var por_baldosa := {}
	for i in cantidad:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radio
		var cx := cos(a) * r
		var cz := sin(a) * r
		var celda := Vector2i(floori(cx / BALDOSA), floori(cz / BALDOSA))
		if not por_baldosa.has(celda):
			por_baldosa[celda] = []
		var cuantas := rng.randi_range(2, 6)
		# La primera del grupo es la grande. Las demás salen de su sombra.
		var escala_madre := rng.randf_range(0.9, 1.7)
		for k in cuantas:
			var ang := rng.randf() * TAU
			var dist := (0.0 if k == 0 else sqrt(rng.randf()) * 1.4)
			var x := cx + cos(ang) * dist
			var z := cz + sin(ang) * dist
			var e := escala_madre if k == 0 else escala_madre * rng.randf_range(0.28, 0.7)
			var t := Transform3D()
			t.origin = Vector3(x, alturas.call(x, z) - 0.1, z)
			t = t.rotated_local(Vector3.UP, rng.randf() * TAU).scaled_local(Vector3(
				e, e * rng.randf_range(0.6, 1.1), e * rng.randf_range(0.8, 1.2)))
			por_baldosa[celda].append(t)

	var total := 0
	for celda: Vector2i in por_baldosa:
		var lista: Array = por_baldosa[celda]
		var centro := _centro(celda, alturas)
		# La malla de esta baldosa sale de la celda, así que es la misma en la
		# pantalla de todos: es multijugador.
		var malla: Mesh = mallas[absi(celda.x * 73856093 ^ celda.y * 19349663) % mallas.size()]
		# Y la malla del kit no viene normalizada: hay que llevarla a 1 metro
		# antes de aplicarle las escalas de arriba, o el peñón sale ocho veces
		# más grande que las chatas.
		var caja := malla.get_aabb()
		var norma := Transform3D(Basis().scaled(Vector3(
			1.0 / maxf(caja.size.x, 0.001),
			1.0 / maxf(caja.size.y, 0.001),
			1.0 / maxf(caja.size.z, 0.001))), Vector3.ZERO)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = malla
		mm.instance_count = lista.size()
		var rc := RandomNumberGenerator.new()
		rc.seed = celda.x * 73856093 ^ celda.y * 19349663
		for i in lista.size():
			var t: Transform3D = lista[i]
			t.origin -= centro
			mm.set_instance_transform(i, t * norma)
			# Un MULTIPLICADOR de valor por piedra, no un color: mil doscientas
			# piedras del mismo gris son una piedra repetida mil doscientas
			# veces. Va de 0,68 a 1,04, o sea de V5 largo a V6 clavado — la
			# escalera no se sale de sus dos peldaños y el campo de piedras deja
			# de ser un estampado. Ver la nota del camino de color en
			# `Paleta.KIT_CONTEXTO`: acá el flag sRGB va apagado a propósito.
			var f := rc.randf_range(0.68, 1.04)
			mm.set_instance_color(i, Color(f, f, f))
		total += lista.size()

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.add_to_group("piedras")
		padre.add_child(mmi)
	print("piedras: %d grupos → %d piedras en %d baldosas" % [cantidad, total, por_baldosa.size()])


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


# ===========================================================================
# LA LABRANZA — LO QUE DICE QUE ACÁ VIVE GENTE QUE TRABAJA
#
# `CLAUDE.md` manda, y es la regla que más caro sale ignorar: *todo tiene vida o
# tiene algún sentido; antes de agregar algo a la escena, decí qué significa.*
# Así que acá va, pieza por pieza, y lo que no pasó la prueba está anotado abajo
# para que nadie lo vuelva a proponer.
#
#  · **LAS HUERTAS.** Tres paños cercados alrededor de Vado Bajo. Significan
#    dos cosas y las dos ya son ciertas en el servidor: **la gente come** —hay
#    una cocinera y una destiladora entre los oficios que manda `/mundo`, y el
#    grano tiene que salir de algún lado— y **el valle tiene ciervos**
#    (`fauna.gd` siembra cuatro ciervos y un venado). Un cerco de 0,7 m no
#    detiene a nadie salvo a un animal que viene a comerse la siembra: **el
#    cerco existe porque existe el ciervo**, y eso es lo que lo salva de ser
#    decorado. Van AFUERA del anillo de casas, que es donde de verdad se siembra
#    —adentro de un caserío está la calle— y a 18–23 m del centro, o sea a la
#    vista desde la plaza.
#
#  · **EL PILÓN DE LA PLAZA.** Las siete casas de Vado Bajo están puestas en
#    círculo mirando hacia adentro y **en el medio no hay nada**: un anillo de
#    casas alrededor de un vacío no es una plaza, es una rotonda. El pilón es de
#    dónde se saca el agua, que es la razón por la que un caserío se junta en
#    círculo y no en fila. Y el pueblo se llama **Vado Bajo**: el agua es su
#    nombre.
#
# LO QUE SE MIRÓ Y NO ENTRÓ, y no es por falta de malla — están las cuatro
# descargadas y sin usar:
#
#  · **Los puestos de mercado** (`stall`, `stall-green`, `stall-red`). **No hay
#    comercio en este juego.** No hay dinero, no hay precios y no hay
#    intercambio entre jugadores; lo que hay es regalo y enseñanza. Un puesto de
#    mercado es exactamente "hacer por hacer", y encima MIENTE sobre lo que el
#    mundo tiene.
#  · **Los estandartes** (`banner-green`, `banner-red`). No hay facciones, no
#    hay casas nobles y no hay bandos. Un estandarte sin nadie detrás es un
#    color colgado.
#  · **El molino de agua y el de viento** (`watermill`, `windmill`). El
#    significado SÍ está —hay siembra y hay río— pero las dos piezas de Kenney
#    son la rueda y las aspas, no el edificio, y el edificio del valle ahora es
#    de Quaternius. Pegarle una rueda de un autor a una pared del otro es
#    justamente la costura que este proyecto decidió no tener. Queda como la
#    primera cosa a hacer si algún día entra una pieza de molino del MegaKit.
#  · **El carro y el cartel** (`cart`, `signpost`). El mojón de `hitos.gd` ya
#    dice "hasta acá llega el valle" al borde del camino, y un cartel al lado
#    repite. El carro se aguanta solo si va a alguna parte, y hoy nadie viaja.
# ===========================================================================

## El paño de una huerta, en metros. Seis por cuatro: tres piezas de cerco por
## el lado largo y dos por el corto, que es como sale sin cortar nada.
const HUERTA_LADO := Vector2(6.0, 4.0)

## Dónde se prueba a ponerlas, medido del centro del lugar. El anillo de casas
## de Vado Bajo cae en ~11,9 m, así que esto está afuera y con calle en el medio.
const HUERTA_RADIOS: Array[float] = [17.0, 19.5, 22.0, 24.5]

## Y en qué tres direcciones. No están repartidas parejo a propósito —dos juntas
## y una del otro lado— porque tres cosas a 120° exactos se leen como un logo.
const HUERTA_ANGULOS: Array[float] = [0.55, 1.45, 3.95]

## La escala del Nature Kit en el valle. Es la misma que usa `valle.gd` en su
## `ESCALA_KIT`, y está repetida porque los dos números tienen que moverse
## juntos: un cerco de un tamaño y un barril de otro se nota.
const ESCALA_NATURALEZA := 2.0

## La del Fantasy Town Kit **no está acá y es a propósito**: la celda de ese kit
## vale `CASA_CELDA` (2,7 m) porque era la del muro de una casa, y ahora la casa
## no es de ese kit. Lo poco que queda de Kenney en el pueblo se escala por
## pieza, con el número al lado y el motivo — ver `_pilon()`.


## Lo que la aldea le hizo a su sitio: sembrar, cercar, sacar agua y prender
## fuego. `alturas` es la función de terreno y `lugares` el `LUGARES` de
## `valle.gd`. Ver el bloque de arriba: cada familia tiene un para qué o no está.
static func labranza(padre: Node3D, alturas: Callable, lugares: Dictionary) -> void:
	var def: Variant = lugares.get("aldea")
	if not (def is Dictionary) or not (def as Dictionary).has("pos"):
		return
	var base: Vector3 = (def as Dictionary)["pos"]

	# Semilla fija: las huertas de Vado Bajo son las mismas en la pantalla de
	# todos, igual que las casas. Es multijugador.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260818

	for i in HUERTA_ANGULOS.size():
		var a: float = HUERTA_ANGULOS[i]
		# El rellano más parejo de los cuatro radios. Es la misma idea que
		# `_sitio_de_casa()` en `valle.gd` y por el mismo motivo: un paño de seis
		# metros en una loma deja el cerco flotando de un lado.
		var mejor := INF
		var centro := Vector3.ZERO
		for r: float in HUERTA_RADIOS:
			var c := Vector3(base.x + cos(a) * r, 0.0, base.z + sin(a) * r)
			var lo := INF
			var hi := -INF
			for dx: float in [-0.5, 0.0, 0.5]:
				for dz: float in [-0.5, 0.0, 0.5]:
					var p := c + Vector3(dx * HUERTA_LADO.x, 0.0, dz * HUERTA_LADO.y) \
						.rotated(Vector3.UP, a)
					var h: float = alturas.call(p.x, p.z)
					lo = minf(lo, h)
					hi = maxf(hi, h)
			if hi - lo < mejor:
				mejor = hi - lo
				centro = c
		# El frente del paño mira a la aldea: ahí va el portillo.
		_huerta(padre, alturas, centro, a + PI, i, rng)

	_pilon(padre, alturas, base)
	_fogon(padre, alturas, base)


## Un paño: el cerco, el portillo, los surcos y lo que crece.
##
## `giro` lleva el frente (+Z local) hacia la aldea. `variedad` decide qué se
## sembró en éste — trigo en dos, maíz en uno. Que las tres huertas tengan lo
## mismo se nota tanto como que no haya ninguna.
static func _huerta(padre: Node3D, alturas: Callable, centro: Vector3,
		giro: float, variedad: int, rng: RandomNumberGenerator) -> void:
	var g := Node3D.new()
	g.name = "Huerta"
	padre.add_child(g)

	var mx := HUERTA_LADO.x / 2.0
	var mz := HUERTA_LADO.y / 2.0
	# Las piezas del cerco miden 1 unidad de ancho y van a escala del Nature
	# Kit, o sea 2 m. Tres por el lado largo, dos por el corto.
	var tramos: Array = []
	for k in 3:
		var u := (k - 1.0) * ESCALA_NATURALEZA
		tramos.append([Vector3(u, 0.0, mz), 0.0, k == 1])     # el frente: acá va el portillo
		tramos.append([Vector3(u, 0.0, -mz), 0.0, false])
	for k in 2:
		var v := (k - 0.5) * ESCALA_NATURALEZA
		tramos.append([Vector3(mx, 0.0, v), PI / 2.0, false])
		tramos.append([Vector3(-mx, 0.0, v), PI / 2.0, false])

	for t: Array in tramos:
		var local: Vector3 = t[0]
		var p := centro + (local as Vector3).rotated(Vector3.UP, giro)
		var y: float = alturas.call(p.x, p.z)
		# Enterrado un poco: en pendiente, un cerco apoyado al ras deja ver el
		# prado por debajo y se lee como una calcomanía.
		Kit.poner(g, "naturaleza/fence_gate" if t[2] else "naturaleza/fence_simple",
			Vector3(p.x, y - 0.12, p.z), giro + float(t[1]), ESCALA_NATURALEZA)

	# Los surcos y lo que crece en ellos. Tres surcos a lo largo, con la tierra
	# volteada abajo y la planta arriba: es la misma pieza de Kenney que ya usa
	# `interiores.gd` para el trigo de la cazadora, o sea que no entra nada nuevo.
	var planta := "naturaleza/crops_cornStageC" if variedad == 2 else "naturaleza/crops_wheatStageB"
	var alto_planta := 1.0 if variedad == 2 else ESCALA_NATURALEZA
	for fila in 3:
		var z := (fila - 1.0) * 1.25
		for k in 3:
			var local := Vector3((k - 1.0) * ESCALA_NATURALEZA, 0.0, z)
			var p := centro + local.rotated(Vector3.UP, giro)
			var y: float = alturas.call(p.x, p.z)
			Kit.poner(g, "naturaleza/crops_dirtRow", Vector3(p.x, y - 0.04, p.z),
				giro, ESCALA_NATURALEZA)
		# Dos matas por surco y no una hilera cerrada: **la mitad de la huerta
		# está cosechada.** Es fin de verano —lo dice la ficha de identidad de
		# `DISENO.md` §6— y un campo lleno y parejo se lee como estampado.
		for k in 2:
			var local := Vector3((k - 0.5) * 1.9 + rng.randf_range(-0.3, 0.3), 0.0,
				z + rng.randf_range(-0.18, 0.18))
			var p := centro + local.rotated(Vector3.UP, giro)
			var y: float = alturas.call(p.x, p.z)
			Kit.poner(g, planta, Vector3(p.x, y - 0.05, p.z),
				rng.randf() * TAU, alto_planta * rng.randf_range(0.85, 1.15))


## El pilón de la plaza. Ver el bloque de arriba: es de dónde se saca el agua, y
## es lo que convierte el anillo de casas en una plaza.
##
## Va corrido del centro exacto y no en (0,0,0), porque ahí es donde aparece el
## jugador al entrar y nadie tiene que nacer adentro de una pileta.
static func _pilon(padre: Node3D, alturas: Callable, base: Vector3) -> void:
	var p := base + Vector3(2.7, 0.0, 2.1)
	var y: float = alturas.call(p.x, p.z)
	# **A 1,6 y no a la celda de la casa.** La del Fantasy Town Kit vale 2,7 m
	# —es la de la casa— y la pieza mide 2 celdas: a esa escala el pilón sale de
	# 5,4 m de diámetro, o sea del ancho de una casa entera, y en la captura se
	# comía la plaza. A 1,6 queda en 3,2 m, que es una pileta a la que se acercan
	# tres personas con baldes.
	var mi := Kit.poner(padre, "pueblo/fountain-round", Vector3(p.x, y - 0.05, p.z),
		0.6, 1.6)
	# **Y baja un peldaño.** La aduana manda las muestras `fde4c7` y `ffffff` del
	# atlas a `ROCA`, que es V6 y es lo correcto para un peñón en la ladera:
	# *la piedra es lo más claro del paisaje*. Pero acá son cinco metros
	# cuadrados de anillo liso en el medio de la plaza, y medido a la tarde salía
	# como **lo más claro del encuadre entero**, por encima de los muros que la
	# escalera reserva para eso. En V5 (`LOSA_CAMINO`) queda al mismo peldaño que
	# el camino y los escalones de las casas, que es lo que es: piedra trabajada,
	# puesta por alguien.
	if mi != null:
		Kit.tinte(mi, Color(0.72, 0.71, 0.70))


# ===========================================================================
# EL FOGÓN DE LA PLAZA — UN LUGAR DONDE ESTAR SIN ESTAR YENDO A OTRO LADO
#
# `CLAUDE.md` lo tiene anotado como carencia desde hace días y con estas
# palabras: *"No hay lugares para frenar: el valle es todo tránsito, no hay
# dónde sentarse ni esperar a alguien."* Es literal. Los cinco lugares del valle
# son destinos y todo lo que hay entre ellos es camino; adentro de una casa hay
# una banqueta junto al fuego, pero **a la intemperie no hay un solo punto del
# mapa que no sea el medio de un viaje.**
#
# QUÉ SIGNIFICA, antes de poner nada:
#
#  · **El agua es por qué se juntaron; el fuego es por qué se quedan.** Vado
#    Bajo es un anillo de casas mirando hacia adentro y en el medio tenía el
#    pilón, que resuelve la primera mitad. Un pueblo se junta alrededor del
#    agua y **se sienta alrededor del fuego**, y son dos cosas distintas.
#  · **Es multijugador y la gente aparece y desaparece.** Ésa es la razón
#    concreta y no una metáfora: si tenés que esperar a alguien que se está
#    conectando, hoy el juego te deja parado en un prado. Sentarse al fuego es
#    cómo se espera a alguien, y no existe el lugar donde hacerlo.
#  · **Y al anochecer la aldea se vacía**: la rutina del servidor manda a todos
#    a su casa. El fogón es entonces lo único encendido al aire libre en el
#    medio de un anillo de puertas cerradas, que es exactamente la postal que
#    el valle quiere a esa hora.
#
# LO QUE FALTA Y NO ES MÍO: **el verbo.** Sentarse le toca a `jugador.gd` y la
# postura a `figura.gd`, y ninguno de los dos es de esta rama. Lo que sí queda
# entregado y andando es la otra mitad: los asientos existen, están en el grupo
# `asientos` con dónde se apoya el cuerpo y hacia dónde se mira, y
# `Interiores.asiento_cerca()` los encuentra igual que `puesto_cerca()`
# encuentra el yunque. Del otro lado es un `if` y una posición.
#
# LA LUZ: un omni **sin sombra**, como los cuatro faroles que la plaza ya tiene
# y no como el hogar de un cuarto. Una omni con sombra es un cubemap —seis
# dibujados de todo lo que haya alrededor— y esto está al aire libre en el medio
# del pueblo, o sea en el peor sitio posible para pagarlo. El fuego se ve igual;
# lo que no proyecta es la sombra de las casas hacia afuera.
# ===========================================================================

## Dónde va, medido del centro del lugar. **No en el centro**: ahí es donde
## aparece el jugador al entrar y donde vuelve al levantarse, y nadie tiene que
## nacer adentro de una hoguera. Queda enfrentado al pilón, con el punto de
## aparición justo entre el agua y el fuego.
const FOGON := Vector3(-3.2, 0.0, -2.5)

## El radio del corro y en qué tres ángulos. Como las huertas: **no a 120°
## exactos**, que se lee como un logo. Dos juntos y uno enfrente, que es como se
## sienta la gente de verdad.
const FOGON_RADIO := 1.45
const FOGON_ASIENTOS: Array = [
	# ángulo   pieza                        escala  a qué altura se apoya el cuerpo
	[0.42,  "naturaleza/log_large",    1.35, 0.50],
	[1.34,  "naturaleza/log_large",    1.35, 0.50],
	[4.05,  "naturaleza/stump_round",  2.10, 0.42],
]

## Cuánta luz da. Los faroles de la plaza dan 3,2 a 12 m; el fogón da algo más
## y llega algo más lejos, porque es el fuego y ellos son la calle.
const FOGON_LUZ := 4.6
const FOGON_ALCANCE := 15.0


static func _fogon(padre: Node3D, alturas: Callable, base: Vector3) -> void:
	var c := base + FOGON
	c.y = alturas.call(c.x, c.z)

	var g := Node3D.new()
	g.name = "Fogon"
	g.position = c
	padre.add_child(g)

	# El pozo, enterrado un dedo: un fogón apoyado al ras del pasto se lee como
	# una calcomanía, igual que el cerco de las huertas.
	#
	# **Una sola pieza y no dos.** La primera versión apiló `campfire_stones`
	# encima de `campfire-pit` —el corro de piedras del Nature Kit más el pozo
	# del de útiles— y en la captura no se leyó como un fogón mejor: se leyó como
	# dos cosas distintas encimadas, con las piedras blancas reventadas por su
	# propia luz. Es el mismo pozo que usa la fragua, a su escala.
	Kit.poner(g, "utiles/campfire-pit", Vector3(0, -0.04, 0), 2.1, 5.0)

	# La brasa. Excepción 1 de la paleta —el fuego es donde se gasta toda la
	# saturación del juego— y es la misma receta que la fragua y que el hogar de
	# un cuarto, para que las tres cosas sean el mismo fuego.
	#
	# **El tamaño salió de mirar, no de elegir, y costó tres vueltas.** Con el
	# pozo chico (3,4) la brasa era una cúpula naranja apoyada arriba de las
	# piedras y se leía como un farol tirado en el pasto; achicando la brasa se
	# leía como un papel prendido. Lo que estaba mal era el POZO: a 5,0 mide 1,39
	# m, o sea la mitad del corro de troncos, y ahí la brasa vuelve a ser una
	# brasa. La proporción entre el fuego y lo que lo rodea es lo que lo cuenta,
	# no el tamaño de ninguno de los dos.
	var brasa := SphereMesh.new()
	brasa.radius = 0.30
	brasa.height = 0.42
	brasa.radial_segments = 8
	brasa.rings = 4
	brasa.material = Paleta.brasa()
	var mi := MeshInstance3D.new()
	mi.mesh = brasa
	mi.position = Vector3(0, 0.26, 0)
	g.add_child(mi)

	var luz := OmniLight3D.new()
	luz.light_color = Paleta.LUZ_FAROL
	luz.light_energy = FOGON_LUZ
	luz.omni_range = FOGON_ALCANCE
	luz.shadow_enabled = false
	luz.position = Vector3(0, 1.05, 0)
	# Dos senos que no encajan entre sí, el mismo que los faroles y la fragua.
	# Un fuego que no titila es una lámpara.
	luz.set_script(preload("res://scripts/parpadeo.gd"))
	g.add_child(luz)

	for d: Array in FOGON_ASIENTOS:
		var a: float = d[0]
		var p := Vector3(cos(a) * FOGON_RADIO, 0.0, sin(a) * FOGON_RADIO)
		p.y = alturas.call(c.x + p.x, c.z + p.z) - c.y - 0.05
		# El tronco se cruza de través al fuego —no apuntando a él—, que es como
		# se pone un tronco para sentarse: a lo largo, no de punta.
		var s := Kit.poner(g, str(d[1]), p, a + PI / 2.0, float(d[2]))
		asiento(s, float(d[3]), atan2(-p.x, -p.z))
		_tope(g, s)


## Marca una malla como un lugar donde parar.
##
## No hace nada visible: le cuelga al nodo dónde se apoya el cuerpo y hacia
## dónde se mira el que se sienta, y lo mete en el grupo `asientos`. Lo lee
## `Interiores.asiento_cerca()`.
##
## `mirando` va en el marco del PADRE del nodo y no en el del mundo, y acá se lo
## guarda restándole el giro propio del nodo. Es a propósito: los asientos se
## marcan al construirlos, cuando la casa todavía puede no estar colgada del
## árbol, y `global_rotation` en ese momento no vale nada. Con la resta hecha
## acá, quien pregunta suma `global_rotation.y` y le da igual cuándo se marcó.
static func asiento(mi: MeshInstance3D, alto: float, mirando: float) -> void:
	if mi == null:
		return
	mi.set_meta("asiento_alto", alto)
	mi.set_meta("asiento_mira", mirando - mi.rotation.y)
	mi.add_to_group("asientos")


## Un tronco con el que te chocás. **Un asiento que se atraviesa caminando es
## peor que no tenerlo**: dice que la cosa está pintada.
##
## La caja sale del BULTO DE LA MALLA y no de un número escrito: el corro tiene
## dos troncos de 1,35 m y un tocón de 0,67, y una caja de tamaño fijo le pone al
## tocón el volumen del tronco —una pared invisible de casi dos metros en el
## medio de la plaza—. Se achica un 8% para que el borde de la colisión quede
## adentro de la madera y no un dedo por fuera.
static func _tope(padre: Node3D, mi: MeshInstance3D) -> void:
	if mi == null:
		return
	var bulto := mi.get_aabb()
	var cuerpo := StaticBody3D.new()
	var cf := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = bulto.size * mi.scale * 0.92
	cf.shape = bs
	cuerpo.add_child(cf)
	cuerpo.position = mi.position \
		+ (bulto.get_center() * mi.scale).rotated(Vector3.UP, mi.rotation.y)
	cuerpo.rotation.y = mi.rotation.y
	padre.add_child(cuerpo)
