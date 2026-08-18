## Lo que hay adentro de las casas, y lo que hace falta para poder entrar.
##
## ===========================================================================
## PARA QUÉ EXISTE UN INTERIOR
##
## `CLAUDE.md` manda: *todo tiene vida o tiene algún sentido; antes de agregar
## algo a la escena, decí qué significa.* Un cuarto que sólo se puede mirar no
## pasa esa prueba. Éstas son las tres cosas que un interior deja hacer y afuera
## no se podían, y las tres son verificables:
##
##  1. **Adentro está la persona que el servidor dice que está.** La rutina del
##     valle ya manda a la gente a su casa al anochecer —`rutinaDe()` en el
##     servidor, `home_place_id` en la base— y hasta hoy eso era invisible: se
##     plantaban afuera igual, a la intemperie, con la ventana encendida
##     mintiendo. Ahora la ventana encendida **es cierta**: entrás y está.
##  2. **El oficio tiene un lugar donde pasa.** El cuarto de la herrera tiene el
##     yunque, el martillo y la piedra; el de la destiladora, el fuego, la olla
##     y los frascos. No es decoración: es el `trade` que ya viaja en `/mundo`,
##     dibujado. Un oficio que no tiene dónde no es un oficio, es un renglón.
##  3. **Es el único sitio del valle donde parar no es perder el tiempo.** Hay
##     un fuego, una banqueta y techo. El resto del valle es tránsito.
##
## Y una cosa que NO hace falta y conviene dejar escrita para que nadie la
## agregue: **entrar no es un verbo.** El interior está en el mismo `place` que
## la casa, `/estoy` ya reporta el lugar y las casas caen a doce metros del
## centro, muy adentro del radio de `ENTRAR`. No hay endpoint nuevo, no hay
## estado nuevo, y el invariante 4 se cumple sin escribir una línea de red.
##
## ===========================================================================
## UNA SOLA ESCENA, PARAMETRIZADA
##
## No hay —y no puede haber— una escena por casa. El valle crece por el norte y
## va a haber más casas; doce escenas hoy son cuarenta mañana y ninguna se
## actualiza cuando cambie el kit. Acá hay **un solo cuarto** y lo que lo
## distingue sale de los datos del servidor: quién vive ahí y de qué trabaja.
##
## El amoblado se parte en dos por eso mismo:
##
##   · `amueblar()` corre al construir el valle y pone lo que tiene toda casa
##     —hogar, leña, banqueta, cama, arcón, mesa—, que no depende de nadie.
##   · `habitar()` corre cuando llega `/mundo` y cuelga las herramientas del
##     oficio. Es lo único que se rehace si el que vive ahí cambia, y se rehace
##     entero: un nodo que se libera y se vuelve a armar, no un diff.
##
## ===========================================================================
## EL RECORTE
##
## La cámara vive a doce metros como mínimo (`Jugador.DIST_MIN`) y a 38° de
## inclinación. Un cuarto de 4,86 m con techo es, desde ahí, una caja cerrada:
## sin recorte, entrar a una casa es mirar tejas.
##
## Así que cuando estás adentro se le sacan a ESA casa el techo, la planta alta,
## la chimenea y los muros de abajo que la cámara tiene delante. No se ocultan:
## pasan a `SHADOWS_ONLY`, o sea que **siguen proyectando sombra**. La diferencia
## no es un detalle: apagarlos del todo llenaría el cuarto de sol y el interior
## dejaría de leerse como interior. Con la sombra puesta, lo único que ilumina
## adentro es el fuego — que es exactamente el argumento de esta rama y la regla
## de la casa (*la luz hace el trabajo, no los polígonos*).
##
## Es un recorte LOCAL: nadie más ve tu casa abierta, igual que en cualquier
## juego con esta cámara. No toca el servidor y no toca a los otros jugadores.
class_name Interiores
extends Node

## Hasta dónde se enciende el hogar de una casa, y cuántos a la vez.
##
## Son luces con sombra —sin sombra, un omni adentro de una caja de muros de 27
## cm se filtra y la casa entera queda con un halo de luciérnaga gigante— y una
## luz con sombra cuesta seis caras de mapa. Doce prendidas todo el tiempo no,
## las dos más cercanas sí: el resto está adentro de una caja cerrada y no se ve.
const LUZ_CERCA := 17.0
const LUZ_CUANTAS := 2

## Cuánta luz da un hogar. Es un fuego chico en un cuarto de cinco metros: con
## más, el cuarto se lava y deja de tener rincones, que es la mitad de lo que
## hace que un interior se sienta interior.
const LUZ_HOGAR := 5.2
const LUZ_ALCANCE := 8.0

## Cuánto tiene que estar la cámara del lado de afuera de un muro para que ese
## muro se apague. No es cero: con el umbral en cero, un muro que queda de
## costado entra y sale del recorte con el temblor de la cámara.
const RECORTE_MARGEN := 0.18


# ---------------------------------------------------------------------------
# LAS PUERTAS
# ---------------------------------------------------------------------------
#
# La hoja la construye `Detalles.casa()` —ver el bloque `LA PUERTA` de ese
# archivo, que es donde está el porqué— y quien la mueve es esto. Acá vive nada
# más que la regla: **cuándo se abre.**
#
# Y la regla es una sola con dos números: *una puerta se abre cuando vas hacia
# ella; de noche hay que llegar hasta la puerta.* De día se abre desde los
# escalones, o sea que la ves abrirse mientras subís; de noche no, y entonces
# hay que ir hasta el umbral y empujarla, más despacio. **No se traba nunca** —
# una puerta con llave es estado del mundo y el estado del mundo es del
# servidor (invariante 4). Lo que cambia de noche no es si podés entrar: es
# cuánto tenés que acercarte para que ceda.
#
# El radio de día es corto a propósito y por el mismo motivo por el que
# `puesto_cerca()` usa 2,2 m: con un radio grande, cruzar la plaza abre cuatro
# puertas de una y la aldea se lee como un supermercado. A 2,6 m del hueco ya
# estás en los escalones de ESA casa.

## Cuánto gira la hoja al abrirse, en radianes. 92°: pasado el ángulo recto, que
## es donde una puerta abierta de verdad se queda —contra la pared y no en el
## medio del paso.
const PUERTA_GIRO := 1.60
## A qué velocidad, en radianes por segundo. Da poco más de medio segundo de
## recorrido. **Una puerta tarda**: instantánea deja de ser una puerta y pasa a
## ser un cambio de estado.
const PUERTA_VEL := 2.8
## De día: desde dónde se abre sola. Ver arriba.
const PUERTA_CERCA := 2.6
## De noche: hasta dónde hay que llegar para empujarla.
const PUERTA_EMPUJE := 1.20
## Y cuánto se queda abierta después de que te fuiste. **Una puerta se queda
## abierta**: si se cerrara al instante sería una cortina de aire.
const PUERTA_QUEDA := 5.0
## Cuánto más lenta es de noche. La misma puerta, con el mismo gozne, pesa lo
## mismo — lo que cambia es que nadie la está esperando.
const PUERTA_NOCHE_VEL := 0.55


# ---------------------------------------------------------------------------
# EL CUARTO
# ---------------------------------------------------------------------------
#
# Todas las posiciones están en el marco de la casa, con la puerta en el frente
# (+Z) y del lado +X. Cuando a una casa le tocó la puerta del otro lado, el
# cuarto entero **se refleja en X** (`espejo` vale −1) y con eso solo la cama
# queda siempre en el rincón lejos de la puerta y el fuego siempre en el que da
# a la chimenea. Es una multiplicación y evita escribir dos plantas.
#
# El cuarto va de −2,43 a +2,43 en las dos direcciones (`Detalles.CASA_ADENTRO`)
# y de 2,56 a 3,10 de alto según qué altura de planta le tocó a esa casa.

## Dónde va el hogar. En el rincón del fondo, en diagonal a la puerta: es el
## punto más lejos de la corriente de aire y el que deja el cuarto entero entre
## el fuego y vos cuando entrás.
const HOGAR := Vector3(-1.45, 0.0, -1.45)

# ---------------------------------------------------------------------------
# QUÉ LE PASÓ A CADA PIEZA
#
# La quinta columna de las tablas de abajo. `DISENO.md` §6, regla 2: *lo que
# tiene historia la muestra — la Casa Quemada se quema de verdad. Un mundo nuevo
# se lee como maqueta.*
#
# **Y romper NO es geometría nueva**, que es la regla 4 de la misma ficha
# (*menos geometría, no más*): un arcón volcado, hundido y tiznado es la misma
# malla, cuesta cero triángulos y se lee a veinte metros. Lo hace `Kit.tumbar()`,
# que elige el eje del vuelco MIDIENDO el bulto y después apoya la pieza — ver
# el bloque de `kit.gd`, que es donde vivía el bug de los escombros parados.
# ---------------------------------------------------------------------------

const ENTERO := 0
const VOLCADO := 1   ## tirada de costado, media vuelta al azar y hundida
const TIZNADO := 2   ## le pasó el fuego por encima


## Los sitios fijos del cuarto. Lo que tiene toda casa, viva quien viva.
const MUEBLES: Array = [
	# ruta                         pos                        giro   escala  qué le pasó
	["naturaleza/log_stack",       Vector3(-2.00, 0, -0.30),  0.00,  1.70],
	["naturaleza/stump_round",     Vector3(-0.30, 0, -1.10),  0.60,  2.10],
	["utiles/bedroll",             Vector3(-1.80, 0,  1.30),  0.00,  3.10],
	["utiles/chest",               Vector3(-1.90, 0,  2.05),  0.00,  2.50],
	["utiles/workbench",           Vector3( 1.60, 0,  0.20), -0.45,  2.60],
]

## Y lo que queda de una casa que se quemó. La Casa Quemada ya es una mazmorra y
## no lo sabía: acá vivía Ren y con ella se fueron dos runas. Adentro no hay
## fuego, no hay cama y no hay luz — hay lo que nadie se llevó.
##
## **Y hasta hoy lo que nadie se llevó estaba impecable**: un arcón nuevo y un
## barril cerrado parados en un cuarto sin techo, cuyo muro está tiznado a
## carbón. Ése es el detalle que delata que la ruina es decorado, y es el mismo
## que ya se había corregido en el basamento (`Detalles._zocalo()`, *"sin esto la
## Casa Quemada queda parada sobre un basamento nuevo y reluciente"*) y que
## faltaba adentro.
##
## El barril es `barril-open` y no `barrel`: el kit trae los dos y el abierto es
## el mismo barril con las duelas de arriba abiertas — 380 triángulos contra 412,
## o sea que romperlo sale **32 triángulos más barato** que dejarlo entero.
## Medido con `prueba_casas.tscn -- --medir`.
##
## Las tablas son el piso de arriba, que es lo que el fuego se llevó y tenía que
## caer en algún lado: la ruina es la única casa del valle sin planta alta y
## hasta ahora eso no dejaba rastro adentro.
##
## Y el hogar queda **de pie pero tiznado**, que es la mitad de una corrección
## que salió de mirar la captura de cerca: la piedra no se quema y es lo único
## que se puede reconocer de un cuarto que se quemó, así que en pie se queda —
## pero **el pozo de fuego de Kenney trae los leños pintados de naranja en el
## atlas**, y sin tiznar la ruina tenía un anillo naranja encendido en el
## rincón. Medido sobre la captura del banco: S 1,00 a V 0,45, el píxel más
## saturado de las tres casas, en la única que no tiene fuego. O sea que la Casa
## Quemada tenía las brasas prendidas — y `interiores.gd` dice tres renglones
## más arriba, desde el día que se escribió, que *adentro no hay fuego*.
const MUEBLES_RUINA: Array = [
	["utiles/campfire-pit",        Vector3(-1.45, 0, -1.45),  0.00,  2.70, TIZNADO],
	["utiles/chest",               Vector3( 1.70, 0, -1.60),  0.80,  2.50, VOLCADO | TIZNADO],
	["utiles/barrel-open",         Vector3(-1.95, 0,  0.90),  1.20,  2.40, VOLCADO | TIZNADO],
	["naturaleza/rock_smallB",     Vector3( 0.40, 0,  1.30),  2.10,  2.20, ENTERO],
	["utiles/resource-planks",     Vector3( 0.55, 0, -0.35), -0.30,  2.20, VOLCADO | TIZNADO],
	["utiles/resource-planks",     Vector3(-0.75, 0,  1.85),  1.05,  1.90, VOLCADO | TIZNADO],
]

## Qué se ve en el cuarto de cada oficio, en el mismo formato que `MUEBLES`.
##
## Se busca **por trozo de palabra y no por lista cerrada**, que es la misma
## lectura que hace `figura.gd` para vestirlos, y por el mismo motivo: el
## servidor manda `trade` en castellano y con género —"herrera", "cazadora",
## "chico del camino"—, así que el día que aparezca un "herrero" tiene que
## reconocerlo sin migrar nada.
##
## El rincón del oficio es el que da al fondo por el lado de la puerta: el que
## entra lo tiene de frente. Las tres piezas ocupan el banco (x 1,6 · z 0,2, con
## la tapa en 0,62), el rincón del fondo (x 1,7 · z −1,5) y el hueco entre los
## dos (x 0,45 · z −2,0).
const OFICIOS := {
	"herr": [
		["utiles/workbench-anvil",   Vector3( 1.70, 0.00, -1.50),  0.35, 2.40],
		["utiles/tool-hammer",       Vector3( 1.62, 0.72, -1.42),  0.90, 2.60],
		["utiles/resource-stone",    Vector3( 0.45, 0.00, -2.00), -0.60, 2.40]],
	"forj": [
		["utiles/workbench-anvil",   Vector3( 1.70, 0.00, -1.50),  0.35, 2.40],
		["utiles/tool-hammer",       Vector3( 1.62, 0.72, -1.42),  0.90, 2.60],
		["utiles/resource-stone",    Vector3( 0.45, 0.00, -2.00), -0.60, 2.40]],
	"aprendiz": [
		["utiles/workbench-grind",   Vector3( 1.72, 0.00, -1.45),  0.20, 2.40],
		["utiles/tool-hammer",       Vector3( 1.50, 0.62,  0.10),  1.30, 2.60],
		["utiles/resource-stone",    Vector3( 0.45, 0.00, -2.00), -0.60, 2.40]],
	"caz": [
		["utiles/tool-axe",          Vector3( 2.00, 0.00, -0.45),  0.30, 2.40],
		["naturaleza/crops_wheatStageB", Vector3( 0.45, 0.00, -2.00), 0.90, 1.20],
		["utiles/resource-wood",     Vector3( 1.55, 0.62,  0.25), -0.30, 2.40]],
	"dest": [
		["naturaleza/pot_large",     Vector3( 1.72, 0.00, -1.50),  0.40, 1.10],
		["utiles/bottle",            Vector3( 1.45, 0.62,  0.05),  0.00, 2.60],
		["utiles/barrel",            Vector3( 2.00, 0.00, -0.45),  0.70, 2.40]],
	"cocin": [
		["naturaleza/pot_large",     Vector3( 1.72, 0.00, -1.50),  0.40, 1.10],
		["utiles/bucket",            Vector3( 1.60, 0.62,  0.30),  0.00, 2.20],
		["utiles/barrel",            Vector3( 2.00, 0.00, -0.45),  0.70, 2.40]],
	"curan": [
		["utiles/bottle",            Vector3( 1.45, 0.62,  0.05),  0.00, 2.60],
		["naturaleza/mushroom_tan",  Vector3( 0.45, 0.00, -2.00),  1.40, 2.00],
		["utiles/box",               Vector3( 1.80, 0.00, -1.50),  0.25, 2.20]],
	"guard": [
		["utiles/box-large",         Vector3( 1.75, 0.00, -1.45),  0.20, 2.20],
		["utiles/tool-axe",          Vector3( 2.05, 0.00, -0.40),  0.30, 2.40],
		["utiles/box",               Vector3( 0.45, 0.00, -2.00), -0.40, 2.20]],
	"solda": [
		["utiles/box-large",         Vector3( 1.75, 0.00, -1.45),  0.20, 2.20],
		["utiles/tool-axe",          Vector3( 2.05, 0.00, -0.40),  0.30, 2.40],
		["utiles/box",               Vector3( 0.45, 0.00, -2.00), -0.40, 2.20]],
}

## El oficio que no está en la tabla igual tiene cosas. Una casa sin nada
## adentro es peor que una casa cerrada: dice que el juego se olvidó de ella.
const OFICIO_CUALQUIERA: Array = [
	["utiles/box",                   Vector3( 1.75, 0.00, -1.50),  0.25, 2.20],
	["utiles/barrel",                Vector3( 2.00, 0.00, -0.45),  0.70, 2.40],
	["utiles/bucket",                Vector3( 0.45, 0.00, -2.00),  0.00, 2.20]]

# ---------------------------------------------------------------------------
# LO QUE SE CORRE CUANDO LO EMPUJÁS
#
# El reclamo de la dirección del proyecto, textual, después de jugar:
# *"en las casas no se puede mover nada"*. Y era literal — un cuarto amueblado
# donde nada se entera de que entraste no es un cuarto, es una vitrina.
#
# **Esto vive en el cliente y es correcto que viva acá.** El invariante 4 dice
# que lo que pasa en el cliente llega al servidor o no pasó, y el corte está
# dicho: que un mueble se pueda empujar es PRESENTACIÓN; que te lo lleves, que
# quede roto para siempre o que construyas es ESTADO DEL MUNDO y va a la base.
# Dónde quedó la banqueta después de que la pateaste no lo tiene que ver nadie
# más y se puede olvidar al recargar: es exactamente igual que la hoja de la
# puerta, que también se mueve y tampoco viaja.
#
# No hay física: no hay `RigidBody3D`, no hay impulso y no se toca `jugador.gd`
# —que además es de otra rama—. La pieza se corre lo justo para quedar afuera
# de tu cápsula y se queda donde quedó. A la distancia a la que se juega eso se
# lee como haberla empujado, y no puede trabar a nadie contra una pared, que es
# lo que sí pasa con un barril con cuerpo rígido en un cuarto de 4,86 m.
#
# Qué se corre: lo que un cristiano corre de una patada, y sólo si está EN EL
# PISO. La cama, el arcón, el yunque y el banco no — un yunque que se desliza
# deja de pesar, y lo que hace que un cuarto tenga peso es justamente que
# algunas cosas no se muevan.

## Los enseres livianos. El radio de empuje NO está acá: sale del bulto de cada
## malla por su escala, medido al construirla. Un balde y un barril no se
## corren desde la misma distancia.
const LIVIANOS := {
	"naturaleza/stump_round": true, "naturaleza/pot_large": true,
	"utiles/bucket": true, "utiles/barrel": true, "utiles/barrel-open": true,
	"utiles/box": true, "utiles/box-large": true,
	"utiles/resource-stone": true, "utiles/resource-wood": true,
	"utiles/resource-planks": true,
}

## Cuánto se puede alejar una pieza de donde la pusieron. Un cuarto de 4,86 m
## donde todo termina apilado en un rincón es peor que uno donde nada se mueve:
## con metro y medio de correa la banqueta se corre, se nota, y el cuarto sigue
## siendo el cuarto.
const EMPUJE_CORREA := 1.5
## Y cuánto margen se le deja al muro, para que nada termine metido adentro del
## revoque. `CASA_ADENTRO` es 2,43 y el radio del bulto se suma aparte.
const EMPUJE_MURO := 0.12


## Dónde se para el que está en su casa. Tres, por si comparten techo.
const ADENTRO_SITIOS: Array[Vector3] = [
	Vector3(-0.45, 0, -0.55),   # junto al fuego
	Vector3( 1.05, 0,  0.75),   # junto a la mesa
	Vector3(-1.55, 0,  0.55),   # a los pies de la cama
]


## Las casas del valle: clave -> lo que hay que saber de ella. La clave es
## `"<slug>/<índice>"`, que es como las nombra `valle.gd` al construirlas.
var _casas: Dictionary = {}
## En cuál estás parado ahora mismo. "" es afuera.
var _adentro := ""
## Qué muros de la planta baja están apagados, para no reescribir la propiedad
## de los ocho paneles en cada cuadro.
var _muros_fuera: Dictionary = {}
## El reloj del valle, para saber si es de noche. Es un HERMANO de este nodo
## —`valle.gd` cuelga los dos de la escena— y se busca una sola vez. Se busca en
## vez de recibirlo porque el cableado vive en `valle.gd`, que es de otra rama:
## esto anda hoy y sigue andando el día que alguien pase el ciclo por parámetro.
var _ciclo: Ciclo = null
var _ciclo_buscado := false


## Registra una casa recién construida y le pone el amoblado que no depende de
## nadie. `casa` es lo que devolvió `Detalles.casa()`.
func amueblar(clave: String, casa: Dictionary, quemada: bool,
		rng: RandomNumberGenerator) -> void:
	var g: Node3D = casa["nodo"]
	var puerta: Vector3 = casa["puerta"]
	# La puerta cae en x = +1,35 o en −1,35. El cuarto se escribe una vez, para
	# la primera, y para la otra se refleja.
	var espejo := 1.0 if puerta.x >= 0.0 else -1.0

	var cuarto := Node3D.new()
	cuarto.name = "Cuarto"
	cuarto.position.y = Detalles.CASA_PISO
	g.add_child(cuarto)

	var livianos: Array = []
	for m: Array in (MUEBLES_RUINA if quemada else MUEBLES):
		var mueble := _poner(cuarto, m[0], m[1], m[2], m[3], espejo, rng,
			int(m[4]) if m.size() > 4 else ENTERO, livianos)
		# LA BANQUETA. Ya estaba puesta y no era nada: un tocón junto al fuego
		# que el juego no sabía que era un asiento. Marcarlo no agrega
		# geometría, agrega que se lo pueda encontrar — ver `asiento_cerca()`.
		# En la ruina no hay fuego al que mirar y no se marca.
		if not quemada and str(m[0]) == "naturaleza/stump_round":
			var hacia: Vector3 = HOGAR - (m[1] as Vector3)
			Detalles.asiento(mueble, 0.44,
				atan2(hacia.x * espejo, hacia.z))

	var luz: OmniLight3D = null
	if not quemada:
		luz = _hogar(cuarto, espejo, rng)

	var oficio := Node3D.new()
	oficio.name = "Oficio"
	cuarto.add_child(oficio)

	var centro := Vector2(g.global_position.x, g.global_position.z)
	# La hoja: su transformación de partida se guarda tal cual quedó al
	# construirla, porque abrir es exactamente eso girado sobre su gozne. La
	# malla se hizo con el origen EN el gozne justamente para que esto sea un
	# `rotated_local` y no una recomposición.
	var hoja: MeshInstance3D = casa.get("hoja")
	_casas[clave] = {
		"nodo": g, "cuarto": cuarto, "oficio": oficio, "luz": luz,
		"alta": casa["alta"], "baja": casa["baja"], "chimenea": null,
		"centro": centro, "piso": g.global_position.y, "alto": float(casa["alto"]),
		# HASTA DÓNDE ESTORBA ESTA CASA, medido desde su propio piso. Y ojo con
		# `alto`, que ya estaba y NO es esto: `alto` es la altura de UNA planta
		# (~3,05 m) y la casa tiene dos más el techo. Se usó `alto` para la prueba
		# de oclusión y salió que no tapaba ninguna casa nunca, porque la visual
		# pasa por encima de los tres metros casi siempre. Del techo se cuenta
		# poco más de la mitad: la cumbrera es una línea y no tapa a nadie.
		"cumbre": float(casa["alero"]) + Detalles.TECHO_ALTO * 0.55,
		"giro": g.global_rotation.y, "espejo": espejo,
		"quemada": quemada, "quien": "", "gente": 0, "recortada": false,
		"hoja": hoja, "hoja_base": (hoja.transform if hoja != null else Transform3D()),
		"hoja_angulo": 0.0, "hoja_espera": 0.0,
		# Lo que se corre de una patada. Se guarda por casa y no en un grupo
		# global: sólo se empuja lo de la casa que estás pisando, y sin eso
		# pasar por la calle correría los muebles del vecino a través del muro.
		"livianos": livianos,
		# El punto del hueco de la puerta, en el mundo. Es contra esto que se
		# mide si estás yendo a esa puerta, y no contra el centro de la casa:
		# desde el centro, las dos casas vecinas quedan a la misma distancia.
		"umbral": g.to_global(puerta),
	}


## La chimenea la pone `valle.gd` en el marco del LUGAR y no en el de la casa,
## así que llega por separado. Se anota para poder apagarla con el techo: una
## chimenea flotando sobre un cuarto abierto es peor que el techo entero.
func anotar_chimenea(clave: String, mi: MeshInstance3D) -> void:
	if mi != null and _casas.has(clave):
		_casas[clave]["chimenea"] = mi


## Quién vive acá y de qué trabaja. Se llama con lo que dice `/mundo`, y se
## rehace entero el nodo del oficio: es un puñado de mallas y la alternativa es
## llevar la cuenta de qué había antes.
##
## Devuelve el punto del mundo donde se para esa persona cuando está en su casa.
func habitar(clave: String, nombre: String, oficio: String) -> Vector3:
	var c: Dictionary = _casas.get(clave, {})
	if c.is_empty():
		return Vector3.ZERO
	var sitio: int = int(c["gente"])
	c["gente"] = sitio + 1

	# El oficio que se ve es el del PRIMERO que la reclama. Si dos comparten
	# techo, el cuarto es de uno solo — dos yunques y una olla en cinco metros
	# no es una casa, es un depósito.
	if sitio == 0 and str(c["quien"]) != nombre:
		c["quien"] = nombre
		if not bool(c["quemada"]):
			_puesto(c, oficio)
			# De quién es el puesto que quedó armado. Lo usa `puesto_cerca()`
			# para poder decir "el yunque de Ilde" y no "un puesto de trabajo":
			# un objeto sin dueño no significa nada en este juego.
			c["oficio_de"] = nombre

	var g: Node3D = c["nodo"]
	var p: Vector3 = ADENTRO_SITIOS[sitio % ADENTRO_SITIOS.size()]
	p.x *= float(c["espejo"])
	return g.to_global(p + Vector3(0, Detalles.CASA_PISO, 0))


## Se llama antes de repartir la gente de un `/mundo`: vuelve a cero la cuenta
## de quién vive dónde, para que un vecino que se mudó no deje su sitio ocupado.
func olvidar_gente() -> void:
	for clave: String in _casas:
		_casas[clave]["gente"] = 0


## Hacia dónde mira el que está adentro: al fuego. Es lo que hace que entrar y
## encontrarla sea encontrar a alguien haciendo algo y no un maniquí de espaldas.
func mirando_al_fuego(clave: String, desde: Vector3) -> float:
	var c: Dictionary = _casas.get(clave, {})
	if c.is_empty():
		return 0.0
	var g: Node3D = c["nodo"]
	var f := g.to_global(Vector3(HOGAR.x * float(c["espejo"]), Detalles.CASA_PISO, HOGAR.z))
	return atan2(f.x - desde.x, f.z - desde.z)


## ¿En qué casa está este punto? "" si está a la intemperie.
##
## Se resuelve por caja orientada y no por distancia al centro: las casas están
## giradas y un círculo que cubra la planta entera se come el metro de calle que
## hay entre dos, así que caminando por el medio de la aldea el recorte se
## prendería solo.
func donde_esta(p: Vector3) -> String:
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		if p.y < float(c["piso"]) - 1.2 or p.y > float(c["piso"]) + float(c["alto"]):
			continue
		var d := (Vector2(p.x, p.z) - (c["centro"] as Vector2)).rotated(float(c["giro"]))
		if absf(d.x) < Detalles.CASA_ADENTRO and absf(d.y) < Detalles.CASA_ADENTRO:
			return clave
	return ""


## Una vez por cuadro. Decide en qué casa estás, recorta la que corresponda y
## enciende los hogares que se ven.
##
## `dt` en negativo —lo normal— significa "el tiempo de este cuadro". Se puede
## pasar a mano y eso es sólo para el banco: **una puerta que tarda medio segundo
## no se puede probar con el reloj real en una corrida headless**, donde un
## cuadro dura un milisegundo y esperar cinco segundos son cinco mil cuadros.
func actualizar(jugador: Vector3, camara: Vector3, dt := -1.0) -> void:
	var ahora := donde_esta(jugador)
	if ahora != _adentro:
		if _casas.has(_adentro):
			_recortar(_casas[_adentro], false, camara)
		_adentro = ahora
		_muros_fuera.clear()
	# ORDEN. `_tapando` va ANTES que `_recortar`, y no es indistinto: las dos
	# escriben `transparency` sobre las mismas mallas. En el cuadro en que entrás
	# a una casa que te venía tapando, `_tapando` le devuelve el cero a la casa
	# entera y recién después `_recortar` vuelve fantasmas los muros de adelante.
	# Al revés, el fantasma duraría un cuadro y lo borraría el otro.
	_tapando(jugador, camara)
	if _casas.has(_adentro):
		_recortar(_casas[_adentro], true, camara)
		_empujar(_casas[_adentro], jugador)

	_encender(jugador)
	# El delta sale del nodo y no del llamador: `valle.gd` llama a `actualizar()`
	# sin dt y esa firma es su cableado, no el mío. Esto es un `Node` colgado de
	# la escena, así que el tiempo del cuadro lo tiene a mano.
	_puertas(get_process_delta_time() if dt < 0.0 else dt, jugador)


## DÓNDE HAY FUEGO, en coordenadas del mundo.
##
## Existe para la antorcha (`antorcha.gd`): se prende en un fuego que existe y
## no desde cualquier lado, y el que sabe dónde están los hogares es esto. Se
## devuelven todos, incluso los de las casas en las que no estás parado — te
## acercás a la puerta de cualquiera y el hogar está a metro y medio del umbral.
##
## Las quemadas no tienen fuego, que es de lo que se trata la Casa Quemada.
func fuegos() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		if bool(c["quemada"]):
			continue
		var n: Node3D = c["nodo"]
		if is_instance_valid(n):
			out.append(n.to_global(HOGAR + Vector3(0.0, Detalles.CASA_PISO, 0.0)))
	return out


## En qué casa estás. Lo lee `valle.gd` para decidir si tenés un puesto de
## trabajo al lado.
func adentro() -> String:
	return _adentro


## Cuánto está abierta la puerta de una casa, en radianes y con signo. Cero es
## cerrada. Existe para el banco: **una puerta que se abre no se puede verificar
## mirando una captura**, porque una captura es un instante y lo que hay que
## probar es que la hoja se mueve cuando alguien se acerca.
func puerta(clave: String) -> float:
	return float((_casas.get(clave, {}) as Dictionary).get("hoja_angulo", 0.0))


## Si estás parado junto al puesto de trabajo de la casa en la que estás, de
## quién es. Cadena vacía si no.
##
## Existe porque el oficio ya tenía DÓNDE pasar —el yunque, la piedra, la olla,
## puestos desde `trade`— y seguía sin poder invocarse: `trabajar` sólo aparecía
## como opción de una charla. O sea que había un yunque, sabías forjar, estabas
## parado al lado, y la única forma de trabajar era buscar a alguien y hablarle.
##
## El radio es corto a propósito. Un puesto que se ofrece desde la puerta hace
## que el cuarto entero sea un botón; a 2,2 m hay que ir hasta él, y esa
## caminata de dos metros es lo que hace que el yunque sea un lugar.
func puesto_cerca(p: Vector3, radio := 2.2) -> Dictionary:
	if _adentro == "":
		return {}
	var c: Dictionary = _casas.get(_adentro, {})
	if c.is_empty():
		return {}
	var nodo: Node3D = c.get("oficio")
	# Sin hijos no hay puesto: la casa no la reclamó nadie con oficio, o está
	# quemada. No se ofrece trabajar en un cuarto vacío.
	if nodo == null or not is_instance_valid(nodo) or nodo.get_child_count() == 0:
		return {}
	if p.distance_to(nodo.global_position) > radio:
		return {}
	return {"nodo": nodo, "de": str(c.get("oficio_de", ""))}


# ---------------------------------------------------------------------------
# DÓNDE VAN LAS COSAS DE UNO
#
# Éstas son las dos funciones que le faltan al cliente para que se pueda AGARRAR
# algo de adentro de una casa, y no hacen falta más: el verbo ya existe
# (`api.levantar()`), el dibujo de lo que hay en el suelo ya existe
# (`valle.gd::_sincronizar_suelo()`) y la E ya lo levanta.
#
# **Lo único que falta es del servidor, y es chico**: hoy `objects` no sabe de
# quién es una cosa —sabe quién la HIZO (`made_by`) y quién la dejó tirada
# (`left_by`), que no es lo mismo—, así que el martillo de Ilde no existe como
# fila y no hay nada que levantar. Está pedido en el informe con la columna y el
# verbo exactos.
#
# Y el día que exista, el punto donde se dibuja NO puede ser el que
# `_sincronizar_suelo()` calcula hoy: ése reparte las cosas entre 3 y 11 m del
# centro del lugar, y las casas están a doce. O sea que el martillo de Ilde
# aparecería tirado en el medio de la plaza. Estas dos funciones dan el punto de
# adentro, y **sin que ninguna coordenada viaje**, que es la regla que sostiene
# todo el sistema: la casa que le toca a cada uno ya sale del orden alfabético
# de su lugar (`valle.gd::_repartir_casas()`) y es la misma en todas las
# pantallas, y el rincón de adentro sale del `id` del objeto, igual que afuera.
#
# Del lado de `valle.gd` es un `if` de tres líneas adentro del bucle que ya
# existe; está escrito en el informe.
# ---------------------------------------------------------------------------

## Los tres rincones donde puede estar algo de uno, en el marco de la casa. El
## banco de trabajo, el pie del arcón y el suelo junto al hogar: los tres sitios
## donde una persona deja lo suyo, y ninguno en el paso de la puerta.
const GUARDADO: Array[Vector3] = [
	Vector3( 1.60, 0.62,  0.20),   # arriba del banco
	Vector3(-1.55, 0.00,  1.95),   # al pie del arcón
	Vector3(-0.85, 0.00, -1.60),   # en el piso, junto al fuego
]


## Dónde va una cosa que está adentro de esta casa. `Vector3.ZERO` si esa casa
## no existe.
##
## `semilla` es lo que reparte varias cosas en rincones distintos, y tiene que
## salir del `id` del objeto —no de un contador— para que dos jugadores vean el
## martillo en el mismo rincón. Es la misma regla y el mismo truco que usa
## `_sincronizar_suelo()` afuera.
func punto_en_casa(clave: String, semilla: int = 0) -> Vector3:
	var c: Dictionary = _casas.get(clave, {})
	if c.is_empty():
		return Vector3.ZERO
	var g: Node3D = c["nodo"]
	var p: Vector3 = GUARDADO[absi(semilla) % GUARDADO.size()]
	p.x *= float(c["espejo"])
	# Un dedo de dispersión, del mismo hash: dos cosas en el mismo rincón no se
	# pisan, y siguen siendo el mismo punto en todas las pantallas.
	var h := absi(semilla / GUARDADO.size())
	p.x += float(h % 21) / 100.0 - 0.10
	p.z += float((h / 21) % 21) / 100.0 - 0.10
	return g.to_global(p + Vector3(0, Detalles.CASA_PISO, 0))


## Dónde van las cosas de esta persona. `Vector3.ZERO` si no vive en ninguna
## casa dibujada —el que duerme en el monte no tiene dónde guardar nada—.
##
## Va por NOMBRE porque es lo único que el servidor manda de una persona en el
## suelo y en los objetos: `made_by` es un nombre, no un id, y a propósito —el
## que lo hizo se muere y la cosa tiene que seguir diciendo quién fue—.
func punto_de(nombre: String, semilla: int = 0) -> Vector3:
	if nombre == "":
		return Vector3.ZERO
	for clave: String in _casas:
		if str(_casas[clave].get("quien", "")) == nombre:
			return punto_en_casa(clave, semilla)
	return Vector3.ZERO


## ¿Hay dónde sentarse acá al lado? Devuelve `{"pos", "mirando", "nodo"}` o `{}`.
##
## Es el gemelo de `puesto_cerca()` y existe por el mismo motivo: el lugar ya
## estaba —la banqueta junto al hogar, los troncos del fogón de la plaza— y el
## juego no sabía que era un lugar. Un tocón que nadie puede usar es una malla.
##
## **Lo que falta para que esto sirva no es de esta rama.** Sentarse le toca a
## `jugador.gd` (parar el cuerpo, clavarlo en `pos`, mirar a `mirando`, soltarlo
## al primer WASD) y la postura a `figura.gd`. Del otro lado esto es un `if`.
##
## Sale del grupo `asientos` y no de un registro propio a propósito: los
## asientos de adentro los pone esta clase y los del fogón los pone
## `Detalles.labranza()`, que corre desde `vegetacion.gd` y no me ve. El grupo es
## el mismo mecanismo con el que `ciclo.gd` encuentra las ventanas.
##
## El radio es corto por lo mismo que el del yunque: un asiento que se ofrece a
## tres metros hace que la plaza entera sea un botón. A 1,5 hay que ir hasta él.
func asiento_cerca(p: Vector3, radio := 1.5) -> Dictionary:
	var mejor: Node3D = null
	var d_min := radio
	for n in get_tree().get_nodes_in_group("asientos"):
		var nodo := n as Node3D
		if nodo == null or not is_instance_valid(nodo):
			continue
		var d := p.distance_to(nodo.global_position)
		if d < d_min:
			d_min = d
			mejor = nodo
	if mejor == null:
		return {}
	return {
		"nodo": mejor,
		"pos": mejor.global_position
			+ Vector3(0.0, float(mejor.get_meta("asiento_alto", 0.45)), 0.0),
		# El giro guardado es relativo al padre; el del mundo se arma sumando el
		# propio del nodo. Ver `Detalles.asiento()`.
		"mirando": mejor.global_rotation.y + float(mejor.get_meta("asiento_mira", 0.0)),
	}


## Las puertas del valle, una vez por cuadro. Ver el bloque `LAS PUERTAS`.
##
## Cuesta doce distancias y, en el caso normal —ninguna puerta moviéndose—, cero
## asignaciones y cero escrituras de transformación.
func _puertas(dt: float, jugador: Vector3) -> void:
	var noche := _es_de_noche()
	var alcance := PUERTA_EMPUJE if noche else PUERTA_CERCA
	var vel := PUERTA_VEL * (PUERTA_NOCHE_VEL if noche else 1.0)
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		var hoja: MeshInstance3D = c["hoja"]
		if hoja == null or not is_instance_valid(hoja):
			continue

		var espera := float(c["hoja_espera"])
		if jugador.distance_to(c["umbral"] as Vector3) < alcance:
			espera = PUERTA_QUEDA
		elif espera > 0.0:
			espera = maxf(espera - dt, 0.0)
		c["hoja_espera"] = espera

		# Hacia dónde abre: siempre para adentro, y el gozne está del lado de la
		# celda en que cayó la puerta —el mismo signo que el espejo del cuarto—,
		# así que el giro es el opuesto. Ver `Detalles._hoja()`.
		var quiero := (-float(c["espejo"]) * PUERTA_GIRO) if espera > 0.0 else 0.0
		var a := float(c["hoja_angulo"])
		if absf(a - quiero) < 0.0005:
			continue
		a = move_toward(a, quiero, vel * dt)
		c["hoja_angulo"] = a
		hoja.transform = (c["hoja_base"] as Transform3D).rotated_local(Vector3.UP, a)


## ¿Es de noche en el valle? La hora la manda el SERVIDOR y la tiene `ciclo.gd`;
## acá no se simula ninguna. Sin ciclo —el banco de prueba no tiene— es de día,
## que es el caso en que las puertas se portan bien.
func _es_de_noche() -> bool:
	if not _ciclo_buscado:
		_ciclo_buscado = true
		var p := get_parent()
		if p != null:
			for h in p.get_children():
				if h is Ciclo:
					_ciclo = h
					break
	return _ciclo != null and is_instance_valid(_ciclo) and _ciclo.es_de_noche()


## Abre TODAS las casas y les prende el fuego.
##
## Es para el banco de prueba —`escenas/prueba_casas.tscn -- --interior`— y para
## nada más. En el valle se abre **una sola**, la que estás pisando: abrirlas
## todas convierte un caserío en una maqueta seccionada, que es exactamente lo
## que un mundo curado no puede parecer. Está acá y no en el banco porque el
## registro de casas es privado y no vale la pena abrirlo por una captura.
## `recorte` en `false` deja los muros puestos y abre nada más que las puertas:
## es el A/B que hace falta para juzgar la hoja, porque con el frente recortado
## la puerta no se ve ni abierta ni cerrada.
func abrir_todas(camara: Vector3, recorte := true) -> void:
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		if recorte:
			_recortar(c, true, camara)
		var luz: OmniLight3D = c["luz"]
		if luz != null:
			luz.visible = true
		# Y las puertas abiertas de par en par. En el banco no hay jugador que
		# las abra y lo que hay que poder mirar es la hoja donde queda.
		var hoja: MeshInstance3D = c["hoja"]
		if hoja != null and is_instance_valid(hoja):
			c["hoja_angulo"] = -float(c["espejo"]) * PUERTA_GIRO
			c["hoja_espera"] = PUERTA_QUEDA
			hoja.transform = (c["hoja_base"] as Transform3D).rotated_local(
				Vector3.UP, float(c["hoja_angulo"]))


# ---------------------------------------------------------------------------
# Lo de adentro
# ---------------------------------------------------------------------------

## Pone una pieza en el cuarto.
##
## `roto` es la quinta columna de las tablas —`VOLCADO`, `TIZNADO`— y `livianos`
## es la lista donde se anota lo que después se va a poder empujar; los dos
## llegan siempre desde el llamador y no por defecto, que en GDScript un `Array`
## por defecto lo comparten todas las llamadas.
##
## `rng` no es opcional y es la mitad de por qué esta función existe: **doce
## cuartos idénticos son una maqueta**. La ficha de identidad (`DISENO.md` §6,
## regla 2) pide variación POR INSTANCIA en todo lo que se repite, y acá se
## repite doce veces cada mueble. La variación es de POSE y de VALOR, nunca de
## matiz ni de silueta: un dedo de corrimiento, un poco de vuelta, y el valor
## multiplicado entre 0,92 y 1,08 — que a veinte metros es la diferencia entre
## cinco muebles y cinco copias del mismo mueble.
##
## La semilla sale del `rng` del LUGAR (`valle.gd` lo siembra con `hash(slug)`),
## así que Vado Bajo tiene los mismos cuartos en la pantalla de todos.
func _poner(cuarto: Node3D, ruta: String, pos: Vector3, giro: float,
		escala: float, espejo: float, rng: RandomNumberGenerator,
		roto := ENTERO, livianos: Array = []) -> MeshInstance3D:
	var mi := Kit.nodo(ruta)
	if mi == null:
		return null
	mi.position = Vector3(pos.x * espejo, pos.y, pos.z)
	# Reflejar el cuarto refleja también los giros, o el mueble apoyado contra
	# la pared izquierda termina mirando a la pared.
	mi.rotation.y = giro * espejo
	mi.scale = Vector3.ONE * escala
	if rng != null:
		mi.position.x += rng.randf_range(-0.07, 0.07)
		mi.position.z += rng.randf_range(-0.07, 0.07)
		mi.rotation.y += rng.randf_range(-0.14, 0.14)
		mi.scale *= rng.randf_range(0.95, 1.05)

	if (roto & VOLCADO) != 0 and rng != null:
		Kit.tumbar(mi, rng, pos.y, 0.035)
	if (roto & TIZNADO) != 0:
		# El mismo hollín que el muro, y con el mismo desparejo: un incendio no
		# quema parejo y cuatro cosas del mismo negro vuelven a ser un estampado.
		# Ver `Paleta.HOLLIN_ALTO`.
		#
		# Y va SIN TEXTURA (`plano`) y con `CARBON`, que es un COLOR y no el
		# multiplicador del muro. Las dos mitades salieron de mirar la captura de
		# cerca y cada una arregló lo que rompía la otra:
		#
		#   · Con textura, el barril tiznado seguía teniendo la boca naranja a
		#     **S 1,00** —brasas en la única casa sin fuego— porque un
		#     multiplicador baja el valor y no desatura. Ver `Kit.tinte()`.
		#   · Sin textura pero con `HOLLIN_ALTO`, la pieza salía en V 0,46: ese
		#     número es un multiplicador sobre un revoque V6, no un albedo, y
		#     usado como albedo **aclara**. El barril quedó más claro quemado
		#     que entero.
		#
		# Medido después de las dos: la ruina pasa de S 1,00 a S 0,82, y lo que
		# queda arriba de todo es el jade de la vara del banco, que es una de las
		# tres excepciones con nombre de la regla 3.
		var v := rng.randf_range(0.86, 1.14) if rng != null else 1.0
		var h := Paleta.CARBON
		Kit.tinte(mi, Color(h.r * v, h.g * v, h.b * v), true)
	elif rng != null:
		var v := rng.randf_range(0.92, 1.08)
		Kit.tinte(mi, Color(v, v, v))

	cuarto.add_child(mi)

	# ¿Se puede empujar? Sólo lo liviano, y sólo lo que está en el piso: un
	# frasco arriba del banco no se corre de una patada. El radio sale del BULTO
	# de la malla por su escala y no de un número escrito — es la misma cuenta
	# que hace `Detalles._tope()` con la colisión de los troncos, y por el mismo
	# motivo: con un radio fijo, el balde se corre desde tan lejos como el barril.
	if LIVIANOS.has(ruta) and pos.y <= 0.001 and mi.mesh != null:
		var b := mi.mesh.get_aabb().size * mi.scale
		var bulto := maxf(b.x, b.z) * 0.5
		# 0,45 es el radio de la cápsula del jugador (`jugador.gd`).
		mi.set_meta("empuje", 0.45 + bulto + 0.06)
		mi.set_meta("empuje_bulto", bulto)
		mi.set_meta("empuje_casa", mi.position)
		livianos.append(mi)
	return mi


## El hogar: el pozo, el trípode, la brasa y la luz.
##
## La brasa y la luz salen de la excepción 1 de la paleta —el fuego, el único
## lugar donde se gasta saturación—. La luz lleva `parpadeo.gd`, el mismo que
## el fuego de la fragua y los faroles: dos senos que no encajan entre sí. Un
## fuego que no titila es una lámpara.
func _hogar(cuarto: Node3D, espejo: float, rng: RandomNumberGenerator) -> OmniLight3D:
	# Sin `rng`: el pozo y el trípode van CLAVADOS donde dice `HOGAR`, porque la
	# brasa, la luz y el punto al que mira el que vive acá se calculan de esa
	# constante. Un fuego corrido siete centímetros deja la luz adentro de la
	# piedra. Es la única pieza del cuarto que no lleva variación.
	_poner(cuarto, "utiles/campfire-pit", HOGAR, rng.randf() * TAU, 2.70, espejo, null)
	_poner(cuarto, "utiles/campfire-stand", HOGAR, 1.20, 2.40, espejo, null)

	var brasa := SphereMesh.new()
	brasa.radius = 0.19
	brasa.height = 0.26
	brasa.radial_segments = 8
	brasa.rings = 4
	brasa.material = Paleta.brasa()
	var mi := MeshInstance3D.new()
	mi.mesh = brasa
	mi.position = Vector3(HOGAR.x * espejo, 0.13, HOGAR.z)
	cuarto.add_child(mi)

	var luz := OmniLight3D.new()
	luz.light_color = Paleta.LUZ_FAROL
	luz.light_energy = LUZ_HOGAR
	luz.omni_range = LUZ_ALCANCE
	# Con sombra, y no es opcional: un omni adentro de una caja de muros de 27
	# cm se filtra por las paredes y la casa se ve desde afuera como un farol
	# de cinco metros. Con sombra, lo único que sale es lo que sale por la
	# puerta, que es justo lo que hay que ver desde la calle.
	luz.shadow_enabled = true
	luz.position = Vector3(HOGAR.x * espejo, 0.85, HOGAR.z)
	luz.visible = false
	luz.set_script(preload("res://scripts/parpadeo.gd"))
	cuarto.add_child(luz)
	return luz


## Las herramientas del oficio del que vive acá.
##
## El `rng` es propio y sembrado con el nombre del que vive acá, no el del lugar:
## esto corre cuando llega `/mundo` y se rehace si el vecino cambia, así que
## tomar del `rng` del lugar movería los muebles de las otras once casas. Con el
## nombre de semilla, **el cuarto de Ilde es el mismo cuarto en todas las
## pantallas y sigue siéndolo después de un `/mundo`.**
func _puesto(c: Dictionary, oficio: String) -> void:
	var nodo: Node3D = c["oficio"]
	for h in nodo.get_children():
		h.queue_free()
	var livianos: Array = c["livianos"]
	# Lo del oficio anterior ya no está: se saca de la lista de empujables o
	# quedan nodos liberados adentro.
	livianos.assign(livianos.filter(func(n: Node) -> bool:
		return is_instance_valid(n) and not n.is_queued_for_deletion()))

	var o := oficio.to_lower()
	var lista: Array = OFICIO_CUALQUIERA
	for clave: String in OFICIOS:
		if o.contains(clave):
			lista = OFICIOS[clave]
			break

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(c.get("quien", "")) + oficio)
	var espejo := float(c["espejo"])
	for d: Array in lista:
		_poner(nodo, str(d[0]), d[1], float(d[2]), float(d[3]), espejo, rng,
			ENTERO, livianos)


# ---------------------------------------------------------------------------
# El recorte y las luces
# ---------------------------------------------------------------------------

func _recortar(c: Dictionary, si: bool, camara: Vector3) -> void:
	# El techo y la planta alta SÍ se pueden ocultar del todo: nadie camina
	# contra un techo. El fantasma es sólo para los muros de abajo, que son los
	# que te frenan sin que los veas — ver el comentario largo abajo.
	var modo := (GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if si
		else GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	if bool(c["recortada"]) != si:
		c["recortada"] = si
		for h in (c["alta"] as Node3D).get_children():
			if h is GeometryInstance3D:
				(h as GeometryInstance3D).cast_shadow = modo
		var chim: MeshInstance3D = c["chimenea"]
		if chim != null and is_instance_valid(chim):
			chim.cast_shadow = modo
		if not si:
			for h in (c["baja"] as Node3D).get_children():
				if h is GeometryInstance3D:
					(h as GeometryInstance3D).cast_shadow = \
						GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			return

	if not si:
		return

	# Los muros de abajo que la cámara tiene delante. Se recalcula por cuadro
	# porque la cámara orbita, pero sólo se ESCRIBE cuando algo cambia: son
	# ocho productos escalares y ninguna asignación en el caso normal.
	var hacia := (Vector2(camara.x, camara.z) - (c["centro"] as Vector2)).normalized()
	for h in (c["baja"] as Node3D).get_children():
		var gi := h as GeometryInstance3D
		if gi == null or not gi.has_meta("afuera"):
			continue
		var a: Vector3 = gi.get_meta("afuera")
		var tapa := Vector2(a.x, a.z).dot(hacia) > RECORTE_MARGEN
		if bool(_muros_fuera.get(gi.get_instance_id(), false)) == tapa:
			continue
		_muros_fuera[gi.get_instance_id()] = tapa
		# ── FANTASMA, NO INVISIBLE. Esto es el arreglo de un bug de verdad ──
		#
		# Estos muros se hacían invisibles (`SHADOWS_ONLY`) **y seguían
		# sólidos**, porque el descarte es de dibujo y no de física. Resultado,
		# dicho por quien lo jugó: *"se traba cuando pasás paredes"*. Veías la
		# casa abierta de frente, caminabas hacia ahí, y te frenaba una pared
		# que no estaba dibujada. **Un obstáculo que no se ve es lo peor que
		# puede tener un juego**: no parece una pared, parece que el juego está
		# roto.
		#
		# Ahora se desvanecen en vez de desaparecer. `GeometryInstance3D
		# .transparency` es por instancia, así que no hay que duplicar un solo
		# material — la casa entera comparte el suyo con las otras once.
		#
		# El 0,86 no es libre: con menos no se ve el interior, y con 1,0
		# volvemos al bug. Lo que queda es un vidrio sucio: ves lo de adentro y
		# ves que hay algo entre vos y eso.
		gi.transparency = 0.86 if tapa else 0.0
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Radio con el que una casa cuenta como estorbo. La planta mide 5,4 × 5,4, o
## sea 3,82 de centro a esquina; 3,4 es un poco menos a propósito, porque rozar
## una esquina no tapa a nadie y desvanecer una casa entera por eso se lee como
## un parpadeo.
const TAPON_RADIO := 3.4
## Cuánto se desvanece la casa que se te pone delante. Menos que el 0,86 de un
## muro suelto: acá se atraviesan techo, dos muros y los muebles del medio, y
## multiplicado eso se vuelve opaco igual. Con 0,72 por capa se ve el jugador y
## se sigue viendo que hay una casa.
const TAPON_ALFA := 0.72


## LA CASA QUE SE TE PONE DELANTE.
##
## Dicho jugando: *"en el medio la cámara hace cosas raras"*. No era la cámara.
## **No había ninguna prueba de oclusión en todo el cliente**: `_recortar` abre
## la casa que estás pisando y nada más, así que una casa AJENA parada entre la
## cámara y vos quedaba maciza y te tapaba entero. Con siete casas en un anillo
## de doce metros y la cámara a veintisiete, eso pasa cada pocos pasos —
## caminás, desaparecés detrás de un techo, salís del otro lado. Se siente como
## que la cámara se volvió loca porque lo único que se mueve raro en pantalla es
## el encuadre; la causa está quieta.
##
## La alternativa clásica es un `SpringArm3D` que acerca la cámara hasta el
## obstáculo. **Acá sería peor**: en un caserío la cámara saltaría de 27 m a 5 m
## y volvería varias veces por travesía, y eso sí es la cámara haciendo cosas
## raras. La cámara lejana es una decisión cerrada (`DISENO.md` §6). Así que la
## cámara no se mueve: se corre la casa.
##
## La cuenta es una distancia de punto a segmento por casa, doce por cuadro, y
## sólo ESCRIBE cuando una casa entra o sale de estorbar. La prueba de altura no
## es un lujo: la cámara está casi doce metros por encima del jugador y las
## casas miden siete, así que la mitad de las que caen sobre la línea en planta
## quedan por debajo de ella y no tapan nada. Sin esa prueba se desvanecería
## medio pueblo a la vez.
func _tapando(jugador: Vector3, camara: Vector3) -> void:
	var ojo := Vector2(camara.x, camara.z)
	var yo := Vector2(jugador.x, jugador.z)
	var tramo := ojo - yo
	var largo2 := tramo.length_squared()

	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		# La que estás pisando ya la maneja `_recortar`, y las dos escriben la
		# misma propiedad: si pisaran juntas, la de afuera le devolvería el 0 a
		# los muros que la de adentro acaba de volver fantasma.
		var tapa := clave != _adentro and largo2 > 0.01
		if tapa:
			var centro: Vector2 = c["centro"]
			var t := clampf((centro - yo).dot(tramo) / largo2, 0.0, 1.0)
			tapa = yo.lerp(ojo, t).distance_to(centro) < TAPON_RADIO
			if tapa:
				# Dónde pasa la visual a la altura de esta casa. El techo se mide
				# desde el piso de la casa, que no es el del jugador: el caserío
				# está en una loma.
				var vista := lerpf(jugador.y + 1.1, camara.y, t)
				tapa = vista < float(c["piso"]) + float(c["cumbre"])

		if bool(c.get("tapando", false)) == tapa:
			continue
		c["tapando"] = tapa
		_desvanecer(c["nodo"] as Node3D, TAPON_ALFA if tapa else 0.0)


## Le pone la misma transparencia a todo lo que cuelga de un nodo. Recursivo
## porque una casa son el techo, los tabiques, la chimenea y los muebles del
## cuarto, cada cosa en su rama. Corre sólo cuando una casa cambia de estado, no
## por cuadro.
func _desvanecer(n: Node3D, alfa: float) -> void:
	for h in n.get_children():
		if h is GeometryInstance3D:
			(h as GeometryInstance3D).transparency = alfa
		if h is Node3D:
			_desvanecer(h as Node3D, alfa)


## Corre lo liviano que tengas encima. Ver el bloque `LO QUE SE CORRE CUANDO LO
## EMPUJÁS`.
##
## Cuesta tres distancias por cuadro —sólo las piezas de la casa que estás
## pisando— y cero cuando estás afuera, que es casi siempre. No escribe nada si
## no tocaste nada.
##
## La cuenta es la mínima que se porta bien: la pieza se corre lo justo para
## quedar afuera de tu cápsula, en la dirección que la aleja de vos. No hay
## inercia, no hay masa y no hay `RigidBody3D`, y eso NO es una simplificación
## barata: un cuerpo rígido en un cuarto de 4,86 m con una `CharacterBody3D` de
## 0,45 de radio termina, tarde o temprano, con un barril trabando al jugador
## contra la pared de su propia casa.
func _empujar(c: Dictionary, jugador: Vector3) -> void:
	var livianos: Array = c["livianos"]
	if livianos.is_empty():
		return
	var g: Node3D = c["nodo"]
	var yo := Vector2(jugador.x, jugador.z)
	for n in livianos:
		var mi := n as MeshInstance3D
		if mi == null or not is_instance_valid(mi):
			continue
		var r := float(mi.get_meta("empuje", 0.0))
		var p := mi.global_position
		var d := Vector2(p.x, p.z) - yo
		var l := d.length()
		# Fuera de alcance, o justo encima (que sólo pasa el primer cuadro
		# después de un teletransporte y no tiene dirección hacia dónde salir).
		if l >= r or l < 0.001:
			continue

		# Adónde iría, en el marco de la casa: es ahí donde el muro es un
		# rectángulo y no cuatro planos girados.
		var mundo := p + Vector3(d.x, 0.0, d.y).normalized() * (r - l)
		var loc := g.to_local(mundo)
		var casa: Vector3 = mi.get_meta("empuje_casa", loc)
		# Ni afuera del cuarto ni más lejos de su sitio que la correa. Las dos
		# cotas son duras: sin la primera la banqueta termina adentro del
		# revoque, sin la segunda todo el cuarto se apila en un rincón.
		var borde := Detalles.CASA_ADENTRO \
			- float(mi.get_meta("empuje_bulto", 0.2)) - EMPUJE_MURO
		loc.x = clampf(loc.x, -borde, borde)
		loc.z = clampf(loc.z, -borde, borde)
		var corrida := Vector2(loc.x - casa.x, loc.z - casa.z)
		if corrida.length() > EMPUJE_CORREA:
			corrida = corrida.normalized() * EMPUJE_CORREA
			loc.x = casa.x + corrida.x
			loc.z = casa.z + corrida.y
		loc.y = mi.position.y

		# Y da un cuarto de vuelta por metro corrido. Una cosa que se desliza
		# sin girar se lee como arrastrada por un imán; girando se lee como
		# pateada, que es lo que acaba de pasar.
		var paso := Vector2(loc.x - mi.position.x, loc.z - mi.position.z).length()
		mi.position = loc
		mi.rotation.y += paso * 1.6


## Enciende los hogares que se pueden ver y apaga el resto. Ver `LUZ_CERCA`.
func _encender(jugador: Vector3) -> void:
	var yo := Vector2(jugador.x, jugador.z)
	var cerca: Array = []
	for clave: String in _casas:
		var c: Dictionary = _casas[clave]
		var luz: OmniLight3D = c["luz"]
		if luz == null:
			continue
		var d := yo.distance_to(c["centro"] as Vector2)
		if d < LUZ_CERCA:
			cerca.append([d, luz])
		elif luz.visible:
			luz.visible = false
	cerca.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in cerca.size():
		var luz: OmniLight3D = cerca[i][1]
		var quiero := i < LUZ_CUANTAS
		if luz.visible != quiero:
			luz.visible = quiero
