## El lecho de ambiente del valle. Sin un solo archivo de audio.
##
## Hasta acá el juego era mudo, y eso es la mitad de por qué se sentía una
## maqueta: ningún efecto visual tapa el silencio.
##
## LA REGLA DE LA CASA APLICADA AL OÍDO. Un ambiente que no dice dónde estás
## ni qué hora es, es ruido con buena intención. Así que cada voz de este
## archivo tiene que contestar una de estas dos preguntas, y las dos se
## contestan sin abrir ningún menú y sin mirar la pantalla:
##
##   DÓNDE ESTOY  · el río se oye desde la aldea y desde la fragua, y no desde
##                  el bosque: es la referencia fija del valle
##                · el martillo de la fragua cruza el valle entero — es el
##                  único sonido que lo hace — y dice "Ilde está trabajando y
##                  la fragua queda para allá"
##                · el Sotobosque APAGA el ambiente. La caída de volumen es la
##                  información: entraste, y esto no es el prado
##                · la Casa Quemada es el único lugar con un sonido AFINADO
##                  (el viento resonando en lo que quedó de la casa). No se
##                  confunde con nada
##                · el Camino del Norte es el lugar más ventoso: la cordillera
##                  tiene una sola abertura y el viento entra por ahí
##   QUÉ HORA ES  · grillos = es de noche · coro de pájaros = está amaneciendo
##                · el hogar de la aldea sube al alba y al anochecer, que es
##                  cuando se cocina, y baja al mediodía
##                · la fragua nunca se apaga del todo, pero de noche es brasa
##                  sin martillo: alguien duerme y el fuego no
##   QUIÉN HAY    · el martillo, la muela, el caldero, el hacha y la cota son
##                  las cinco voces del trabajo, y ninguna suena por una curva:
##                  suenan porque el SERVIDOR dice que esa persona está
##                  despierta y en su lugar. Ver `LA GENTE`, más abajo.
##
## LA LÍNEA QUE NO SE CRUZA, Y ES LA MISMA DEL INVARIANTE 4. El sonido es
## presentación y vive entero en el cliente, así que puede inventar timbres,
## ráfagas y ecos todo lo que quiera. **Lo que no puede inventar son HECHOS.**
## Un martillo sonando donde el servidor no dice que haya nadie forjando es una
## afirmación falsa sobre el mundo, y da igual que la haga el director o el
## oído: el jugador camina hasta la fragua y no hay nadie.
##
## Hasta el 18 de agosto este archivo cruzaba esa línea sin saberlo: el yunque
## salía de `CURVA_YUNQUE`, o sea de la hora y nada más. Si Ilde se moría, si se
## iba al Sotobosque o si la absorbían, el martillo seguía sonando al mediodía
## igual que siempre. **Ahora el martillo es de Ilde, no del mediodía.**
##
## EL SILENCIO ES MATERIAL. La noche del valle es más callada que el día — no
## por gusto de tono, sino porque si todo suena todo el tiempo nada pesa. Lo
## que queda de noche es el río, los grillos y la brasa de la fragua. En el
## Sotobosque de noche no queda casi nada, y eso es a propósito.
##
## POR QUÉ TODO SINTETIZADO. Igual que el cielo (un shader escrito a mano) y
## que los cuerpos (animados sin archivos de animación): no hay assets y el
## .exe se baja por internet. Esto pesa CERO en disco y CERO en la descarga.
## Lo que cuesta es medio segundo de CPU una sola vez, al arrancar — medido, no
## estimado: lo imprime la escena de prueba cada vez que corre. **Y varía mucho
## entre corridas bajo WSL** (350 a 630 ms para el mismo código sin tocar), así
## que ese número no sirve para comparar dos versiones: para eso hay que
## cronometrar la parte que cambió, y no el total.
##
## HASTA DÓNDE LLEGA LA SÍNTESIS — está dicho sin maquillaje en cada función:
## el viento, el río, el fuego, los grillos, el lamento de la ruina, la muela,
## el caldero y la cota salen bien por síntesis. Los pájaros y el hacha salen
## pasables. El martillo del yunque y el murmullo de la gente son el techo de
## lo que se puede fingir, y son los dos primeros que habría que grabar. Las
## palabras no se intentan, y no por límite técnico: el juego es de leer.
##
## NADIE DEL EQUIPO ESCUCHÓ ESTO TODAVÍA. No hay forma de afirmar cómo suena
## desde acá: bajo WSL no hay salida de audio. Lo que se puede verificar es lo
## que imprime `escenas/prueba_sonido.tscn`: qué eligió para cada lugar y cada
## hora. Que alguien lo corra con parlantes.
class_name Sonido
extends Node3D

# ─────────────────────────────────────────────────────────────────────────
#  EL LECHO. Esta mitad del archivo es pura: dado un lugar y una hora,
#  devuelve la mezcla. No toca la escena, no toca el AudioServer, y es lo
#  único que la prueba puede verificar sin oír nada.
# ─────────────────────────────────────────────────────────────────────────

## Cuánto pesa cada voz en cada lugar. Es el "acento" del lugar: lo que hace
## que la aldea no suene como el camino aunque las dos tengan viento.
##
## `brillo` no es volumen, es TIMBRE: qué tan abierto está el filtro del
## viento. Bajo el sotobosque el viento se oye tapado por las copas; en el
## camino, que es la abertura de la cordillera, se oye crudo. Dos lugares con
## el mismo volumen de viento y distinto brillo se distinguen igual — y esa es
## la parte que sigue funcionando cuando el jugador baja el volumen.
const LECHOS := {
	# Vado Bajo. Doce casas apretadas contra el recodo del río. El único lugar
	# con gente: pájaros de día (hay huerta y hay basura), grillos de noche.
	"aldea":  {"viento": 0.22, "pajaros": 1.15, "grillos": 0.60, "hojas": 0.00, "hueco": 0.00, "brillo": 0.42},
	# La Fragua de Ilde. Lo que la define no está en esta tabla: está en el
	# fuego y el yunque, que son sonidos con LUGAR (ver _armar_emisores).
	"fragua": {"viento": 0.15, "pajaros": 0.55, "grillos": 0.40, "hojas": 0.00, "hueco": 0.00, "brillo": 0.50},
	# El Sotobosque. Acá el ambiente se APAGA. No hay grillos, casi no hay
	# pájaros, el viento queda arriba en las copas. Lo único que queda es la
	# madera trabajando, y cada tanto algo que se rompe y no sabés qué fue.
	# Ahí viven Los del Sotobosque, que son un pueblo con un agravio, no
	# monstruos: el lugar tiene que dar cosa por vacío, no por música de miedo.
	"bosque": {"viento": 0.20, "pajaros": 0.14, "grillos": 0.00, "hojas": 1.15, "hueco": 0.00, "brillo": 0.06},
	# La Casa Quemada. Se incendió antes de que nadie vivo estuviera acá y
	# nadie la reconstruye. Sin techo y sin fuego: el viento entra por los
	# huecos y la casa canta una nota. Es el único sonido afinado del valle.
	"ruina":  {"viento": 0.45, "pajaros": 0.10, "grillos": 0.35, "hojas": 0.10, "hueco": 1.25, "brillo": 0.62},
	# El Camino del Norte. La única abertura de la cordillera. Por acá entra
	# el viento y por acá entra la gente — poca. Es el lugar más expuesto y el
	# más ruidoso al mediodía, y no tiene nada que lo abrigue.
	"camino": {"viento": 1.30, "pajaros": 0.22, "grillos": 0.10, "hojas": 0.00, "hueco": 0.20, "brillo": 1.00},
	# Campo abierto: el valle entre lugares. No es un relleno — es el estado
	# por defecto del mundo, y es contra lo que se mide que el bosque apague.
	"campo":  {"viento": 0.62, "pajaros": 0.75, "grillos": 0.60, "hojas": 0.00, "hueco": 0.00, "brillo": 0.80},
}

## Dónde está cada lugar y desde qué distancia se lo empieza a oír.
## `[radio_lleno, radio_cero]`: adentro del primero estás del todo en el
## lugar; pasado el segundo, no queda nada. El bosque tiene la transición más
## ancha a propósito: querés SENTIR que se apaga mientras te acercás, no que
## se apague de golpe cuando cruzás una línea.
##
## Las posiciones son las mismas de `valle.gd`. Están copiadas para que la
## escena de prueba corra sola; si `preparar()` recibe la tabla del valle,
## esta copia se descarta.
const POS := {
	"aldea":  {"pos": Vector3(0, 0, 0),      "r": [24.0, 52.0]},
	"fragua": {"pos": Vector3(62, 0, -18),   "r": [20.0, 46.0]},
	"bosque": {"pos": Vector3(-58, 0, -54),  "r": [26.0, 62.0]},
	"ruina":  {"pos": Vector3(-26, 0, -108), "r": [20.0, 46.0]},
	"camino": {"pos": Vector3(11, 0, 74),    "r": [24.0, 56.0]},
}

## El río de `valle.gd`: un plano de 430 m centrado en (0, -1.7, 26) y girado
## 9°. Un río de 430 metros con un solo emisor puntual es una fuente que te
## sigue; con tres, caminar por la orilla se oye como caminar por la orilla.
const RIO_CENTRO := Vector3(0, -1.0, 26)
const RIO_GIRO := 9.0
const RIO_SEPARACION := 70.0

## LA PUERTA DEL NORTE. Sesenta metros de roca a cada lado y una sola abertura
## en toda la cordillera — es la única pieza del valle cuya forma tendría que
## oírse, porque un desfiladero no cambia lo que suena: cambia cómo vuelve.
##
## Así que la Puerta no tiene un sonido propio (eso sería un adorno, y encima
## uno que miente: no hay nada ahí haciendo ruido). Lo que tiene es un ECO que
## se le pone al lecho ENTERO cuando te acercás. El río, el viento y tus
## propios pasos empiezan a volver de la piedra, y el jugador no piensa "hay un
## efecto": piensa "esto es un lugar cerrado". Es la misma idea que el
## `brillo` — el timbre dice el lugar cuando el volumen ya no puede.
##
## Los números salen de `hitos.gd`, que no es de esta rama: la jamba está en
## x −14 y el muñón en x 46, los dos en z 162. El centro del vano es el punto
## medio. Se copian y no se importan por la misma razón que `POS`: que este
## archivo corra solo en la escena de prueba.
const PUERTA := Vector3(16.0, 0.0, 162.0)
const PUERTA_LLENO := 34.0    ## adentro del vano, el eco está entero
const PUERTA_CERO := 120.0    ## pasado esto, el valle es campo abierto otra vez
const PUERTA_ECO := 0.34      ## cuánto de lo que oís vuelve de la piedra

## Las curvas del día. 0 es medianoche, 0.25 el amanecer, 0.5 el mediodía.
## Cada par es [fracción, valor] y tienen que empezar en 0.0 y terminar en 1.0.

## El viento sigue al sol: mínimo de madrugada, máximo a media tarde. Es
## física real y de paso es la voz que nunca se va del todo, la que impide que
## el valle quede en silencio absoluto cuando no pasa nada.
const CURVA_VIENTO := [[0.00, 0.16], [0.20, 0.19], [0.30, 0.30], [0.45, 0.50],
	[0.55, 0.62], [0.70, 0.56], [0.82, 0.33], [0.92, 0.20], [1.00, 0.16]]

## El coro del amanecer es el aviso de hora más fuerte que existe: arranca de
## la nada a las 0.20 y explota a las 0.27. Después baja — al mediodía los
## pájaros callan, que es real y además deja lugar para el viento — y vuelve
## un rato más chico al atardecer. A las 0.86 no queda ninguno.
const CURVA_PAJAROS := [[0.00, 0.00], [0.18, 0.00], [0.23, 0.55], [0.27, 1.00],
	[0.34, 0.70], [0.50, 0.35], [0.62, 0.45], [0.76, 0.58], [0.82, 0.16],
	[0.86, 0.00], [1.00, 0.00]]

## Los grillos son el reloj de la noche y se cruzan con el coro: a las 0.22
## todavía quedan algunos mientras empiezan los pájaros. Ese solapamiento de
## cinco minutos es lo que hace que el amanecer se sienta un pasaje y no un
## corte.
const CURVA_GRILLOS := [[0.00, 0.90], [0.14, 0.88], [0.22, 0.30], [0.27, 0.00],
	[0.72, 0.00], [0.79, 0.35], [0.86, 0.80], [0.94, 0.90], [1.00, 0.90]]

## El apagón general de la noche. NO se le aplica al río ni a la fragua: lo
## que hace que la noche se sienta noche es justamente que se caiga todo lo
## demás y queden esos dos.
const CURVA_MAESTRO := [[0.00, 0.72], [0.20, 0.74], [0.28, 0.88], [0.45, 1.00],
	[0.70, 1.00], [0.82, 0.88], [0.90, 0.74], [1.00, 0.72]]

## "El único techo de la región que nunca se apaga del todo." De noche baja a
## 0.42 y nunca a cero. Ese 0.42 es la frase del lugar dicha en un número.
const CURVA_FUEGO := [[0.00, 0.42], [0.22, 0.45], [0.30, 0.95], [0.55, 1.00],
	[0.75, 0.95], [0.84, 0.60], [1.00, 0.42]]

## El martillo. **ESTA CURVA YA NO DECIDE SI SUENA EL YUNQUE**, y el renglón es
## importante porque decirlo mal fue el defecto: quien decide es el servidor,
## que manda a Ilde despierta o dormida (ver `LA GENTE`). Si Ilde se muere, esta
## curva sigue valiendo 1.00 al mediodía y no suena un solo martillazo.
##
## Queda acá por una sola razón y es la medición: para saber cuánto PESA el
## yunque en la mezcla de un lugar hay que suponer que alguien está forjando, y
## la hora en que un herrero forja es ésta. O sea que hoy es una hipótesis de la
## prueba, no una fuente de sonido.
const CURVA_YUNQUE := [[0.00, 0.00], [0.26, 0.00], [0.32, 0.85], [0.50, 1.00],
	[0.70, 0.90], [0.80, 0.25], [0.84, 0.00], [1.00, 0.00]]

## El hogar de la aldea tiene DOS picos: el alba y el anochecer. Es cuando se
## cocina. Al mediodía la gente está afuera trabajando y el fuego está bajo.
## Dos picos en vez de uno es lo que separa "hay fuego" de "hay alguien".
const CURVA_HOGAR := [[0.00, 0.55], [0.18, 0.60], [0.26, 0.95], [0.38, 0.55],
	[0.50, 0.30], [0.68, 0.45], [0.80, 0.95], [0.90, 0.80], [1.00, 0.55]]

## Las voces del lecho de fondo (sin lugar en el mundo, suenan en la cabeza).
const VOCES_FONDO: Array[String] = ["viento", "pajaros", "grillos", "hojas", "hueco"]

## Las voces que NO son lecho: suenan de a un golpe y hay que dispararlas.
const VOCES_SUELTAS: Array[String] = ["yunque", "crujido", "muela", "caldero",
	"hacha", "cota", "murmullo"]


# ─────────────────────────────────────────────────────────────────────────
#  LA GENTE. El valle tiene siete personas y hasta hoy no hacía ruido
#  ninguna. Lo que sigue es lo único de este archivo que depende del
#  SERVIDOR, y depende a propósito.
#
#  LA REGLA DE LA CASA APLICADA ACÁ. "Todo tiene vida o tiene algún sentido.
#  No hacemos por hacer." Un murmullo de aldea genérico es relleno: suena
#  igual con siete personas que con cero, así que no dice nada. El martillo de
#  la fragua es INFORMACIÓN — te dice que Ilde está despierta, que está en la
#  fragua y para qué lado queda— y esa diferencia es la que decide qué entra.
#
#  Por eso el reparto de este archivo es:
#    · el FUEGO de la fragua y el HOGAR de la aldea son del LUGAR. La fragua
#      es "el único techo de la región que nunca se apaga del todo" — eso lo
#      dice el servidor en la descripción del lugar, no una persona. Siguen
#      colgados de su curva y está bien.
#    · el MARTILLO, la MUELA, el CALDERO, el HACHA y la COTA son de una
#      PERSONA. No suenan si el servidor no manda a esa persona despierta y en
#      su lugar. Si Ilde se muere, la fragua se queda con el fuego y sin el
#      martillo, que es exactamente lo que pasa.
#
#  CUÁNDO SUENA UNA PERSONA — las tres condiciones, y las tres salen de
#  `/mundo` sin que este archivo deduzca nada:
#    1. está en la lista de `people` (el servidor no manda muertos),
#    2. `durmiendo == false`,
#    3. `place_id == home_place_id`, o sea que está en su lugar.
#
#  La tercera es la que más se discute y es la que evita la mentira más fácil.
#  Odila es destiladora y HOY está en el Sotobosque juntando: si el caldero
#  sonara por su oficio, sonaría un alambique en el bosque. Marta es cazadora y
#  está en el monte, así que su hacha tampoco suena — y ahí sí se pierde algo
#  real (una cazadora en el bosque es justo cuando la oirías). Se elige perder
#  eso antes que arriesgar la mentira: **el servidor dice dónde está, no qué
#  está haciendo**, y de "está en el bosque" a "está cortando" hay una
#  invención. Cuando `/mundo` mande la agenda, esto se afloja en una línea.
#
#  UN EMISOR POR FAMILIA, NO POR PERSONA. Suena el que trabaja más cerca del
#  oyente. Con doce herreros seguís oyendo UN martillo, y el gasto de
#  reproductores no crece con la población — que es la trampa que este repo ya
#  pisó con los `AudioStreamPlayer` que no se liberaban.
# ─────────────────────────────────────────────────────────────────────────

## Oficio → familia de sonido. Se busca POR TROZO DE PALABRA y no por lista
## cerrada, que es la misma lectura que hacen `figura.gd` para vestirlos e
## `interiores.gd` para amueblarles el cuarto, y por el mismo motivo: el
## servidor manda `trade` en castellano y con género —"herrera", "cazadora",
## "chico del camino"—, así que el día que aparezca un "herrero" se reconoce
## sin migrar nada.
##
## Los oficios que no caen en ninguna familia NO tienen sonido de trabajo, y
## eso es correcto: "chico del camino" y "nadie sabe" no son un oficio con un
## gesto repetido. A ésos se los oye por el murmullo, como a cualquiera.
const FAMILIAS := {
	"herr": "yunque", "forj": "yunque",
	"aprendiz": "muela", "afil": "muela",
	"dest": "caldero", "cocin": "caldero", "curan": "caldero",
	"caz": "hacha", "leñ": "hacha", "len": "hacha", "carpin": "hacha",
	"guard": "cota", "solda": "cota",
}

## El ritmo de cada oficio, y el ritmo ES el personaje.
##
##   `golpe`  segundos entre dos golpes de la misma racha
##   `racha`  cuántos golpes seguidos antes de la pausa larga
##   `pausa`  el hueco entre rachas. **Es lo que hace que no sea un metrónomo**:
##            un herrero calienta, golpea, vuelve al fuego. Un martillo regular
##            se oye a máquina y este mundo no tiene máquinas.
##   `db`     rango de volumen del emisor. Ninguno llega al del yunque.
##   `unidad` y `max`: el alcance.
##
## EL ALCANCE ES INFORMACIÓN Y NO ES PAREJO A PROPÓSITO. El martillo cruza el
## valle entero (260 m) y es el único que lo hace: es la brújula. Los otros
## cuatro son locales —entre 34 y 120 m— porque dicen "hay alguien ACÁ", no
## "hay alguien en el valle". Si todos cruzaran el valle, el valle sería una
## fábrica y ninguno diría dónde.
const OFICIOS_SON := {
	# Ilde. La racha del yunque es la que ya estaba y no se toca.
	"yunque":  {"golpe": [0.42, 0.58], "racha": [3, 6], "pausa": [4.5, 11.0],
		"db": [-3.0, 1.5], "tono": [0.93, 1.09], "unidad": 30.0, "max": 260.0},
	# Bruno, el aprendiz. Pasadas largas de piedra y muchas más pausas que su
	# maestra: **el que aprende trabaja a tirones**, y ese contraste con la
	# racha de Ilde es lo que dice cuál de los dos es cuál sin mirar.
	"muela":   {"golpe": [0.78, 1.05], "racha": [2, 3], "pausa": [16.0, 30.0],
		"db": [-7.0, -3.0], "tono": [0.88, 1.12], "unidad": 13.0, "max": 70.0},
	# Odila. Un alambique no tiene ritmo: borbotea cuando le parece.
	"caldero": {"golpe": [1.4, 2.9], "racha": [1, 3], "pausa": [18.0, 34.0],
		"db": [-8.0, -4.0], "tono": [0.90, 1.14], "unidad": 9.0, "max": 42.0},
	# Marta. Un hacha son golpes sueltos y espaciados, con el tiempo de acomodar
	# el tronco entre uno y otro — y después de la racha hay que apilar, que es
	# de donde sale la pausa más larga de las cinco.
	"hacha":   {"golpe": [1.6, 3.2], "racha": [2, 4], "pausa": [26.0, 50.0],
		"db": [-5.0, -1.0], "tono": [0.90, 1.10], "unidad": 18.0, "max": 120.0},
	# Sarn. Lo más callado de las cinco: cuero y anillas al acomodarse. Un
	# guardia parado hace poco ruido, y que haga poco es la información.
	"cota":    {"golpe": [2.4, 5.0], "racha": [1, 2], "pausa": [17.0, 32.0],
		"db": [-11.0, -6.0], "tono": [0.92, 1.10], "unidad": 8.0, "max": 34.0},
}

## EL PRESUPUESTO. La queja original fue "el sonido molesta mucho", y eso es un
## número —eventos por minuto—, no un adjetivo. Estos tres frenos son el
## presupuesto y la prueba los mide:
##
##   · dos sonidos de gente nunca a menos de `GENTE_FRENO` segundos, contando
##     TODAS las familias juntas. Es el mismo freno que `fauna.gd` le puso al
##     rebaño (1,1 s) y por el mismo motivo: siete bichos en el mismo cuadro no
##     son un susto, son un error.
##   · nada suena si no hay nadie adentro del alcance de ESA familia. Un
##     martillo a 300 m no es información, es ruido de fondo.
##   · y el techo declarado: si la prueba mide más de `TECHO_POR_MINUTO`
##     eventos de gente por minuto en el peor caso, alguien se pasó.
##
## DE DÓNDE SALE EL 48, y sale de una medición y no de un gusto. El martillo
## viejo —el que colgaba de la hora y de nada más— daba **39 a 42 martillazos
## por minuto entre las 0.38 y las 0.65, en 260 metros a la redonda y sin
## importar si Ilde estaba viva**. Está medido y la prueba lo imprime al lado
## del nuevo, en `ANTES Y DESPUÉS`.
##
## O sea que el presupuesto de antes era 42 eventos/min para UNA voz, en TODO
## el valle, la mitad del día. El techo de ahora es 48 para SEIS voces y sólo
## se toca parado adentro de la fragua, con el yunque a tres metros; en
## cualquier otro punto del valle la tabla da entre 11 y 36, y de noche da
## cero. Eso es lo que hace que 48 sea un techo más apretado que 42, aunque el
## número sea más grande.
##
## **La única forma de discutirlo es corriendo la prueba y mirando la tabla.**
const GENTE_FRENO := 0.30
const TECHO_POR_MINUTO := 48.0

## El murmullo. **No es diálogo y no lo va a ser**: el juego es de leer y una
## voz sintetizada que intente decir algo suena a juguete. Lo que esto dice es
## "hay alguien", y por eso es cortísimo, va muy bajo y sólo suena si estás
## prácticamente al lado.
##
## El tono sale del nombre, así que Ilde murmura siempre igual y Sarn siempre
## más grave. Es el mismo hash estable que usa `figura.gd` para que la cara de
## una persona sea la misma en todas las pantallas.
const MURMULLO_ALCANCE := 17.0
const MURMULLO_ESPERA := [10.0, 20.0]
const MURMULLO_DB := -17.0


## Interpola una curva de [fracción, valor]. La hora da la vuelta sola.
static func curva(puntos: Array, f: float) -> float:
	var x := fposmod(f, 1.0)
	for i in range(puntos.size() - 1):
		var a: Array = puntos[i]
		var b: Array = puntos[i + 1]
		var xa := float(a[0])
		var xb := float(b[0])
		if x >= xa and x <= xb:
			if xb - xa < 0.000001:
				return float(b[1])
			return lerpf(float(a[1]), float(b[1]), (x - xa) / (xb - xa))
	return float((puntos[puntos.size() - 1] as Array)[1])


## Cómo se llama esta hora. Mismas palabras que `ciclo.gd` para que la prueba
## y la interfaz digan lo mismo.
static func franja(f: float) -> String:
	var x := fposmod(f, 1.0)
	if x < 0.20: return "de madrugada"
	if x < 0.30: return "al amanecer"
	if x < 0.45: return "de mañana"
	if x < 0.58: return "al mediodía"
	if x < 0.72: return "de tarde"
	if x < 0.82: return "al atardecer"
	return "de noche"


## EL LECHO, dado un lugar y una hora. Es la función que hay que leer para
## entender el diseño entero, y la que la prueba imprime.
##
## Devuelve ganancias lineales. Las cinco primeras son el fondo; `rio`,
## `fuego`, `hogar` y `yunque` son de las fuentes que tienen lugar en el mundo
## y su volumen final lo termina de decidir la distancia, no esta tabla.
static func lecho(slug: String, f: float) -> Dictionary:
	return mezclar(LECHOS.get(slug, LECHOS["campo"]), f)


static func mezclar(acento: Dictionary, f: float) -> Dictionary:
	var viento := curva(CURVA_VIENTO, f)
	var maestro := curva(CURVA_MAESTRO, f)
	# La madera trabaja y la casa canta cuando hay viento: las dos cuelgan del
	# viento en vez de tener curva propia. Y las dos tienen un piso, porque un
	# bosque en calma sigue crujiendo.
	var hojas := 0.20 + 0.30 * viento
	var hueco := 0.20 + 0.45 * viento
	var g := {
		"viento": viento * float(acento.get("viento", 0.0)) * maestro,
		"pajaros": curva(CURVA_PAJAROS, f) * float(acento.get("pajaros", 0.0)) * maestro,
		"grillos": curva(CURVA_GRILLOS, f) * float(acento.get("grillos", 0.0)) * maestro,
		"hojas": hojas * float(acento.get("hojas", 0.0)) * maestro,
		"hueco": hueco * float(acento.get("hueco", 0.0)) * maestro,
		# El río no duerme y no lo apaga la noche. Es el ancla del valle.
		"rio": 1.0,
		"fuego": curva(CURVA_FUEGO, f),
		"hogar": curva(CURVA_HOGAR, f),
		"yunque": curva(CURVA_YUNQUE, f),
		"brillo": float(acento.get("brillo", 0.7)),
		"maestro": maestro,
	}
	var t := 0.0
	for v in VOCES_FONDO:
		t += float(g[v])
	g["fondo"] = t
	return g


## Cuánto pesa cada lugar desde un punto del valle. Entre la aldea y la fragua
## no estás "en ninguno": estás en campo abierto, que es un lecho propio.
##
## Esto NO es la misma cuenta que `_avisar_donde_estoy()` de valle.gd, y no
## tiene que serlo. Aquella tiene histéresis porque le manda un evento al
## servidor y siete llegadas en un tick ensucian la crónica. El oído no tiene
## eventos: quiere un cruce continuo.
static func pesos_en(pos: Vector3, tabla: Dictionary) -> Dictionary:
	var yo := Vector2(pos.x, pos.z)
	var pesos := {}
	var suma := 0.0
	for slug: String in tabla:
		var d: Dictionary = tabla[slug]
		var c: Vector3 = d["pos"]
		var r: Array = d["r"]
		var dist := yo.distance_to(Vector2(c.x, c.z))
		var w := 1.0 - smoothstep(float(r[0]), float(r[1]), dist)
		if w > 0.001:
			pesos[slug] = w
			suma += w
	var campo := clampf(1.0 - suma, 0.0, 1.0)
	if campo > 0.001:
		pesos["campo"] = campo
		suma += campo
	if suma <= 0.0:
		return {"campo": 1.0}
	for slug: String in pesos:
		pesos[slug] = float(pesos[slug]) / suma
	return pesos


## El lecho en un punto y una hora: el acento de cada lugar cercano, mezclado.
func lecho_en(pos: Vector3, f: float) -> Dictionary:
	var pesos := pesos_en(pos, _tabla)
	var acento := {}
	for clave in ["viento", "pajaros", "grillos", "hojas", "hueco", "brillo"]:
		var v := 0.0
		for slug: String in pesos:
			var a: Dictionary = LECHOS.get(slug, LECHOS["campo"])
			v += float(a.get(clave, 0.0)) * float(pesos[slug])
		acento[clave] = v
	var g := mezclar(acento, f)
	g["pesos"] = pesos
	return g


# ─────────────────────────────────────────────────────────────────────────
#  LA ESCENA. Buses, emisores y la mezcla en vivo.
# ─────────────────────────────────────────────────────────────────────────

## Prendé esto en una escena y el nodo se prepara solo e imprime el informe.
## Es lo que hace `escenas/prueba_sonido.tscn`.
@export var modo_prueba := false
## Cuánto sale por el parlante, en lineal. 0,45 son -6,9 dB.
##
## No es un número elegido a ojo: con esto el lugar más sonoro del valle —la
## fragua al mediodía— queda en -23 dBFS eficaces, y el más callado —el
## Sotobosque de madrugada— en -40. La referencia es que un lecho de ambiente
## vive entre -30 y -22 dBFS: arriba de -18 compite con todo lo demás y cansa.
## La escena de prueba imprime la tabla entera, lugar por lugar y hora por
## hora, así que este número se puede discutir con datos y no con adjetivos.
##
## Y va bajo a propósito: hoy el ambiente es lo ÚNICO que suena, así que la
## tentación es subirlo. Cuando entren los pasos y los golpes va a tener que
## estar acá abajo igual, y es más fácil no acostumbrar el oído.
@export var volumen_general := 0.45

## De dónde sale la hora. Es `ciclo.gd`, que la recibe del SERVIDOR. Si esto
## queda en null se usa `hora_manual`, y eso sólo vale para la prueba: un
## temporizador local rompe que dos personas conectadas compartan el momento.
var ciclo: Node
## Quién oye. En el juego es el jugador.
var oyente: Node3D
## Para la prueba, cuando no hay ciclo.
var hora_manual := 0.5

const HZ := 22050
const CRUCE := 2200        ## 0,1 s de fundido para cerrar el bucle sin clic
const PREFIJO := "SE_"     ## los buses son nuestros y se ven

var _tabla := POS.duplicate(true)
var _buses: Array[String] = []
var _jug: Dictionary = {}          ## voz → Array[AudioStreamPlayer*]
var _gan: Dictionary = {}          ## voz → ganancia suavizada
var _listo := false
var _reloj := 0.0
var _prox_crujido := 12.0
var _ms_generacion := 0.0

## LA GENTE, tal cual la manda el servidor. Cada entrada:
##   nombre, familia ("" si el oficio no tiene una), trabajando (bool),
##   despierta (bool), slug, pos (Vector3), tono (float, del nombre)
var _gente: Array[Dictionary] = []
## De dónde salió esa lista. Se imprime en el informe para que se vea de un
## vistazo si el cableado llegó o si el ambiente está inventando.
var _origen_gente := "nadie todavía"
## El estado del ritmo de cada familia: {espera, seguidos, meta}
var _ritmo: Dictionary = {}
var _freno_gente := 0.0
var _prox_murmullo := 4.0
var _reverb: AudioEffectReverb
var _refresco_gente := 0.0
var _avisado := false
var _con_nodo := 0
var _registro_on := false
var _mudos := 0
## MIENTRAS SE MIDE NO SE REPRODUCE. La medición corre la máquina de verdad a
## 30 pasos por segundo simulados, o sea que en headless comprime 48 minutos de
## valle en un par de segundos de reloj. Sin esta bandera, **la persona que
## corra la escena de prueba con parlantes —que es justo la que necesitamos—
## se comería mil golpes de golpe antes de oír una sola nota del lecho.**
## En headless no se notaba porque no hay salida: el defecto sólo aparecía en
## la única máquina donde importa.
var _midiendo := false

## EL REGISTRO. "El sonido molesta" es un número y hay que poder mostrarlo
## antes y después. Cuenta cada disparo por familia y el hueco de silencio más
## largo, y lo imprime la prueba. En el juego cuesta un `+= 1` y sirve para lo
## mismo el día que alguien vuelva a decir que molesta.
var _cuenta: Dictionary = {}
var _cuenta_desde := 0.0
var _ultimo_evento := 0.0
var _silencio_max := 0.0

## SIN SALIDA DE AUDIO, NO SE REPRODUCE NADA. Se calcula todo igual.
##
## Cuando Godot corre en headless —la verificación de este repo, `desplegar.sh`
## y cualquier máquina sin placa de sonido— el driver es `Dummy` y no hay a
## dónde mandar el audio. Reproducir doce streams contra la nada es trabajo
## tirado en cada corrida.
##
## Y además arregla un defecto real que apareció al cablear el módulo en la
## escena de verdad: **Godot cierra con
## `WARNING: N ObjectDB instances were leaked at exit` si hay audio sonando
## cuando termina el proceso.** Lo investigué hasta el fondo y esto es lo que
## se midió, no lo que supongo:
##
##   · el motor suelta una reproducción detenida en su próxima MEZCLA, y esa
##     mezcla la dispara el bucle principal, no un reloj. Entre el `stop()` y
##     el cierre hacen falta DOS cuadros de proceso: con cero o con uno el
##     aviso sale igual, con dos desaparece.
##   · en `_exit_tree()` ya no queda ningún cuadro, así que ahí es tarde POR
##     DEFINICIÓN. Probé apagar ahí, no tocar nada, liberar los emisores a
##     mano, vaciar los buses con `set_bus_count(1)` y dormir 60 ms de reloj:
##     las veinte instancias quedaban colgadas en los cinco casos.
##   · no hay forma de forzar una mezcla desde GDScript. Recorrí
##     `AudioServer.get_method_list()`: no existe ningún `mix`, `flush` ni
##     `update`.
##   · `OS.get_cmdline_args()` NO trae `--quit-after` (Godot se queda con los
##     argumentos del motor), así que el módulo tampoco puede ver venir el
##     cierre para adelantarse.
##   · **y no es un defecto de este archivo.** El control es un
##     `AudioStreamPlayer` pelado en el bus Master, sin una línea de acá:
##     también deja dos instancias colgadas. Es comportamiento del motor para
##     cualquier audio que esté sonando al salir.
##
## Con esta regla, ninguna corrida headless reproduce nada y ninguna deja nada
## colgado, en cualquier condición y la maten cuando la maten.
##
## LO QUE NO ARREGLA, dicho de frente: con placa de sonido de verdad y un
## build de depuración, cerrar el juego sigue dejando esas instancias. Es del
## motor, es cosmético (el aviso no se imprime en un build de release y el
## sistema operativo recupera la memoria igual) y no depende de este módulo.
##
## EL COSTO DE ESTA REGLA, y cómo se paga. Si en headless no suena nada, una
## corrida headless tampoco puede descubrir una fuga de audio nueva. Por eso
## existe `--sonido-con-audio`: fuerza la reproducción aunque no haya salida,
## y con eso la condición que rompe se puede pedir a mano, en la escena de
## prueba, sin esperar a que la descubra el cableado:
##
##   godot --headless escenas/prueba_sonido.tscn --quit-after 60 -- --sonido-con-audio
##
## Eso HOY deja instancias colgadas, y tiene que dejarlas: es el motor y está
## medido. Lo que hay que mirar en esa corrida es que el número no CREZCA: es
## una por emisor sonando más una por bucle distinto — hoy 12 + 8 = 20. Si un
## día salta, alguien agregó un emisor que no se apaga.
const FORZAR_AUDIO := "--sonido-con-audio"

## DOS BANDERAS PARA PODER VERIFICAR LA GENTE, Y EXISTEN POR UN MOTIVO CONCRETO.
##
## `--hora=` clava el SOL, que es local. **Quién está despierto NO es local: lo
## manda el servidor** en `durmiendo`, calculado con la hora del valle. O sea
## que `--hora=mediodia` te da un mediodía con la aldea entera durmiendo, y con
## eso no se puede medir una sola de las voces del trabajo. Está bien que sea
## así —el que decide es el servidor y ése es el invariante— pero deja la mitad
## de esta entrega sin forma de comprobarse hasta que al valle le toque el día.
##
##   --sonido-todos-despiertos   pone a las siete personas despiertas y en su
##                               lugar. **No cambia nada del mundo y no manda
##                               nada al servidor**: es una hipótesis para
##                               medir el peor caso de mezcla, y se anuncia en
##                               la salida con todas las letras para que nadie
##                               confunda una corrida así con el juego.
##   --sonido-registro           imprime un renglón por segundo con qué familia
##                               sonó y cuántas veces, en el juego de verdad.
##                               Es lo que convierte "el sonido molesta" en un
##                               número comparable antes y después.
##
## Van como bandera y no como una variable parcheada a mano por la misma razón
## que `--hora`: una sonda editada a mano se cuela en un commit, y una bandera
## no.
const TODOS_DESPIERTOS := "--sonido-todos-despiertos"
const REGISTRO := "--sonido-registro"

var _hay_salida := true
var _bufs: Dictionary = {}
var _nativo: Dictionary = {}


func _ready() -> void:
	# `_ready()` no hace NADA en el juego: el valle llama a `preparar()` cuando
	# ya tiene la tabla de lugares y el jugador. Es a propósito — un error en
	# `_ready()` aborta la función entera y todo lo que venía después nunca se
	# inicializa (en este repo eso dejó al juego sin HUD). El sonido no puede
	# ser el que rompa el arranque de nadie.
	if modo_prueba:
		var o := get_node_or_null("Oyente") as Node3D
		if o != null:
			oyente = o
		preparar()
		_informe_de_prueba()


## La llama el valle. `lugares` es la tabla LUGARES de valle.gd (opcional: si
## no viene, se usa la copia de acá).
func preparar(lugares: Dictionary = {}) -> void:
	add_to_group("sonido")   # la interfaz lo busca por acá para el volumen
	_hay_salida = AudioServer.get_driver_name() != "Dummy" \
		or OS.get_cmdline_user_args().has(FORZAR_AUDIO)
	_registro_on = OS.get_cmdline_user_args().has(REGISTRO)
	if not lugares.is_empty():
		_tabla = {}
		for slug: String in lugares:
			var r: Array = POS[slug]["r"] if POS.has(slug) else [24.0, 52.0]
			_tabla[slug] = {"pos": lugares[slug]["pos"], "r": r}
	_armar_buses()
	_armar_emisores()
	# Se genera acá, sincrónico, y no en un hilo. Se midió: 103 ms para los
	# diez bucles en esta máquina. Al lado de `_armar_terreno()`, que arma
	# 388.800 vértices a mano en el mismo arranque, esto no se nota — y un
	# hilo sería un camino más que puede fallar en `_ready()`, que es
	# exactamente la trampa que este repo ya pisó una vez.
	var t0 := Time.get_ticks_usec()
	var bufs := _generar_todo()
	_montar(bufs)
	_ms_generacion = (Time.get_ticks_usec() - t0) / 1000.0
	# Sólo la prueba se queda con los bucles sueltos, para medirlos. En el
	# juego los referencian los emisores y nadie más.
	if modo_prueba:
		_bufs = bufs
		_gente_de_mentira()


# ── LA GENTE: de dónde sale ──────────────────────────────────────────────

## Quién trabaja dónde lo sabe `/mundo` y nadie más.
##
## Hubo acá un cableado provisorio: este módulo se enganchaba solo a la señal
## del `Api` que colgaba del mismo padre, buscándolo entre los hermanos. Andaba
## — y ése era el problema. **Un cable que funciona por casualidad es peor que
## uno que no está**, porque el día que alguien mueva un nodo se corta y nadie
## lo va a ir a buscar: el síntoma es que el valle deja de sonar, que se lee
## como "todavía no lo hicieron".
##
## Ahora lo llama `valle.gd::_al_recibir_mundo()`, que es quien tiene el
## diccionario en la mano.
##
## Lo que sí se conserva del diseño anterior, y es la parte importante: si esto
## no se llama, `_gente` queda vacía y **no suena una sola voz de trabajo**. El
## modo de falla es el silencio, nunca la mentira. Un martillo que sigue
## sonando porque el cliente perdió al servidor es peor que ningún martillo.


## LA PUERTA DE ENTRADA, y es pública a propósito: es la línea que hay que
## llamar desde `valle.gd` para que este módulo deje de buscarse la vida solo.
## Recibe el diccionario entero de `/mundo`, tal cual llega.
func enterarse(mundo: Dictionary) -> void:
	var slug_por_id := {}
	for l in mundo.get("places", []):
		var d: Dictionary = l
		slug_por_id[str(d.get("id", ""))] = str(d.get("slug", ""))

	var nueva: Array[Dictionary] = []
	_con_nodo = 0
	for p in mundo.get("people", []):
		var d: Dictionary = p
		var nombre := str(d.get("name", ""))
		if nombre == "":
			continue
		var casa := str(d.get("home_place_id", ""))
		var donde := str(d.get("place_id", ""))
		# Dormida es dormida esté donde esté: `durmiendo_afuera` sólo dice que
		# se quedó en el monte, no que esté trabajando de noche.
		var despierta := not bool(d.get("durmiendo", false))
		nueva.append({
			"nombre": nombre,
			"familia": familia_de(str(d.get("trade", ""))),
			"despierta": despierta,
			"trabajando": despierta and casa != "" and casa == donde,
			"slug": str(slug_por_id.get(donde, "")),
			"pos": _donde_esta(nombre, str(slug_por_id.get(donde, ""))),
			"tono": 0.74 + 0.62 * _dado(nombre),
		})
	# La hipótesis de medición, y sólo si alguien la pidió por bandera.
	if OS.get_cmdline_user_args().has(TODOS_DESPIERTOS):
		for d in nueva:
			d["despierta"] = true
			d["trabajando"] = str(d["slug"]) != ""
		if not _avisado:
			print("sonido: ¡OJO! %s está puesto. Las siete personas están" % TODOS_DESPIERTOS)
			print("  despiertas y trabajando PORQUE LO PIDIÓ LA LÍNEA DE COMANDOS,")
			print("  no porque lo diga el servidor. Esta corrida no es el juego.")

	_gente = nueva
	if _origen_gente.begins_with("nadie"):
		_origen_gente = "/mundo"
	# UNA SOLA VEZ, y en el juego de verdad. El cableado de este módulo se puede
	# romper sin que salte un error —el ambiente sigue sonando, sólo que sin
	# gente— así que la única forma de que alguien se entere es que lo diga en
	# voz alta la primera vez que llega la lista. Es el mismo motivo por el que
	# `ciclo.gd` tiene `fraccion()`: un fallo silencioso no es un fallo, es una
	# trampa para el próximo.
	if not modo_prueba and not _avisado:
		_avisado = true
		var trabajan := 0
		var quienes := ""
		for d in _gente:
			if bool(d["trabajando"]) and str(d["familia"]) != "":
				trabajan += 1
				quienes += "%s(%s en %s)  " % [d["nombre"], d["familia"], d["slug"]]
		print("sonido: %d personas de %s · %d con oficio que se oye · %s"
			% [_gente.size(), _origen_gente, trabajan,
				quienes if quienes != "" else "el valle está durmiendo"])
		# Y de dónde sale la POSICIÓN, que es la otra mitad y se rompe aparte:
		# si esto da 0, el sonido de cada oficio sale del centro del lugar en
		# vez de seguir a la persona por su ronda. Suena igual de bien y dice
		# menos, y sin este renglón nadie se entera nunca.
		print("  posición: %d de %d salen del nodo del vecino; el resto, del centro del lugar."
			% [_con_nodo, _gente.size()])
		# Y QUÉ HORA CREE QUE ES. Sin esto no hay forma de saber desde afuera si
		# `--hora=` llegó hasta acá, y hace falta saberlo porque **esa bandera
		# mueve el sol y NO mueve a la gente**: quién duerme lo calcula el
		# servidor con la hora del valle, que es compartida. O sea que una
		# corrida con `--hora=mediodia` te da un mediodía con la aldea entera
		# durmiendo, y eso es correcto aunque parezca un bug.
		var f := hora()
		print("  hora del valle: %.2f (%s) · el sol la lee de acá; quién duerme, no."
			% [f, franja(f)])


## El oficio, tal cual lo manda el servidor, llevado a una de las cinco
## familias. Devuelve "" si no cae en ninguna, que es una respuesta legítima.
static func familia_de(oficio: String) -> String:
	var o := oficio.strip_edges().to_lower()
	for clave: String in FAMILIAS:
		if o.contains(clave):
			return String(FAMILIAS[clave])
	return ""


## FNV-1a de 32 bits llevado a 0..1. Es el mismo hash de `figura.gd` y por el
## mismo motivo: el tono de una persona tiene que ser el mismo en todas las
## pantallas, y ni `String.hash()` ni un RNG sembrado lo prometen entre
## versiones del motor.
static func _dado(texto: String) -> float:
	var h := 2166136261
	for b: int in texto.to_utf8_buffer():
		h = (h ^ b) * 16777619 & 0xFFFFFFFF
	return float(h % 100000) / 100000.0


## Dónde está esa persona AHORA. `valle.gd` cuelga un nodo `vecino_<nombre>`
## por cada uno y lo mueve por su ronda; si está, el sonido sale de ahí y
## acompaña a la persona. Si no está —la escena de prueba, o el cuadro en que
## el valle todavía no la armó— se cae al centro de su lugar, separado por el
## hash para que dos vecinos del mismo sitio no suenen desde el mismo punto.
func _donde_esta(nombre: String, slug: String) -> Vector3:
	var p := get_parent()
	if p != null:
		var n := p.get_node_or_null(NodePath("vecino_" + nombre.validate_node_name()))
		if n is Node3D and (n as Node3D).is_inside_tree():
			_con_nodo += 1
			return (n as Node3D).global_position + Vector3(0, 1.1, 0)
	var d: Dictionary = _tabla.get(slug, {})
	if d.is_empty():
		return Vector3(0, 1.1, 0)
	var a := _dado(nombre) * TAU
	var c: Vector3 = d["pos"]
	return c + Vector3(cos(a) * 7.0, 1.1, sin(a) * 7.0)


## La gente de la escena de prueba. **Es de mentira y está dicho.**
##
## Son los siete de `valle-primero` copiados a mano el 18 de agosto con sus
## oficios de verdad, y **cada uno puesto en SU lugar y despierto**, que es el
## peor caso de mezcla y no el estado de hoy: cuando se copió esto, el valle
## estaba de noche y seis de los siete dormían. Vale como hipótesis para medir
## el presupuesto, no como retrato del mundo. En el juego esto no se llama
## nunca: ahí manda `/mundo` y nada más.
func _gente_de_mentira() -> void:
	var falsos := [
		["Ilde", "herrera", "fragua", true], ["Bruno", "aprendiz", "fragua", true],
		["Odila", "destiladora", "aldea", true], ["Marta", "cazadora", "aldea", true],
		["Sarn", "guardia", "aldea", true], ["Tobio", "chico del camino", "camino", true],
		["La vieja Ren", "nadie sabe", "ruina", true],
	]
	_gente.clear()
	for f: Array in falsos:
		var nombre := str(f[0])
		var slug := str(f[2])
		_gente.append({
			"nombre": nombre, "familia": familia_de(str(f[1])),
			"despierta": bool(f[3]), "trabajando": bool(f[3]),
			"slug": slug, "pos": _donde_esta(nombre, slug),
			"tono": 0.74 + 0.62 * _dado(nombre),
		})
	_origen_gente = "la lista de mentira de la prueba (7 personas)"


## Qué hora es en el valle. La manda el servidor a través de `ciclo.gd`.
##
## `ciclo.gd` guarda la fracción en `_fraccion` y no expone un getter. No lo
## toco porque este trabajo tiene permiso para crear dos archivos y ninguno es
## ése; lo leo por nombre y prefiero `fraccion()` si algún día existe. La
## instrucción de cableado pide agregar ese getter de una línea.
func hora() -> float:
	if ciclo != null:
		if ciclo.has_method("fraccion"):
			return fposmod(float(ciclo.call("fraccion")), 1.0)
		var f: Variant = ciclo.get("_fraccion")
		if f != null:
			return fposmod(float(f), 1.0)
	return fposmod(hora_manual, 1.0)


func _exit_tree() -> void:
	# Si a este nodo lo sacan del árbol, el valle se queda callado y los buses
	# vuelven. Para que además no queden instancias colgadas hay que apagar
	# ANTES — ver `SIN SALIDA DE AUDIO, NO SE REPRODUCE NADA`, más abajo.
	apagar()


func _notification(que: int) -> void:
	# Cerrar la ventana también es irse.
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		apagar()


## Cortar todo y devolver los buses. Se puede llamar en cualquier momento.
func apagar() -> void:
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			if is_instance_valid(p):
				p.call("stop")
				p.set("stream", null)
	_listo = false
	_soltar_buses()


# ── Buses ────────────────────────────────────────────────────────────────
#
# Se crean EN TIEMPO DE EJECUCIÓN, no desde el editor. Dos razones y las dos
# valen: `project.godot` lo está tocando otro, y un bus creado por código es
# un bus que se explica solo en el mismo archivo que lo usa.
#
# Cada voz tiene su bus con un filtro propio, y ahí está el truco central de
# todo esto: el BUCLE es fijo y corto, la MODULACIÓN es viva. Un ruido rosa de
# cuatro segundos, pasado por un pasabajos cuyo corte se mueve con tres senos
# lentos que no son múltiplos entre sí, no se oye como un bucle de cuatro
# segundos. Es la misma idea que `figura.gd` usa para animar cuerpos sin
# archivos de animación.

func _armar_buses() -> void:
	_bus(PREFIJO + "Valle", "Master", null)
	# El viento: pasabajos que se abre con las ráfagas y con lo abierto del
	# lugar. Es la voz que dice "cuán a la intemperie estás".
	_bus(PREFIJO + "Viento", PREFIJO + "Valle", _filtro_bajo(900.0, 0.4))
	# Los pájaros no necesitan graves.
	_bus(PREFIJO + "Pajaros", PREFIJO + "Valle", _filtro_alto(700.0, 0.0))
	# Los grillos viven en 4 kHz.
	_bus(PREFIJO + "Grillos", PREFIJO + "Valle", _filtro_alto(1800.0, 0.0))
	# Las hojas: una banda angosta en el medio agudo. Ruido rosa pasado por
	# esto y modulado despacio es hojas; sin la banda es siseo.
	_bus(PREFIJO + "Hojas", PREFIJO + "Valle", _filtro_banda(2400.0, 0.35))
	# El lamento de la Casa Quemada: la misma fuente de ruido, pero por una
	# banda MUY resonante y grave. Eso es literalmente lo que hace el viento
	# entrando por un hueco, y es lo único afinado que tiene el valle.
	_bus(PREFIJO + "Hueco", PREFIJO + "Valle", _filtro_banda(186.0, 0.92))
	_bus(PREFIJO + "Rio", PREFIJO + "Valle", _filtro_alto(240.0, 0.0))
	_bus(PREFIJO + "Fuego", PREFIJO + "Valle", _filtro_bajo(2600.0, 0.1))
	_bus(PREFIJO + "Hogar", PREFIJO + "Valle", _filtro_bajo(1400.0, 0.1))
	_bus(PREFIJO + "Yunque", PREFIJO + "Valle", null)
	_bus(PREFIJO + "Crujido", PREFIJO + "Valle", null)
	# El trabajo de la gente, todo por un bus. No es pereza: es que el
	# presupuesto de las cinco familias tiene que poder subirse o bajarse de un
	# lugar solo. Un pasabajos suave para que las herramientas no compitan con
	# los grillos en la banda de fatiga (2–5 kHz), que es donde cansa.
	_bus(PREFIJO + "Oficio", PREFIJO + "Valle", _filtro_bajo(5200.0, 0.0))
	# El murmullo, aparte del resto: es lo único con cuerpo humano que hay en el
	# valle y hay que poder callarlo sin tocar nada más si se decide que no va.
	_bus(PREFIJO + "Voz", PREFIJO + "Valle", _filtro_bajo(2200.0, 0.0))
	_volumen(PREFIJO + "Oficio", 1.0)
	_volumen(PREFIJO + "Voz", 1.0)
	_volumen(PREFIJO + "Valle", volumen_general)
	# El eco de la Puerta del Norte. Va en el bus del valle entero —o sea que
	# le vuelve TODO, el río, el viento y el martillo— y arranca en seco: la
	# mezcla en vivo le sube la vuelta según lo cerca que estés del vano.
	_armar_eco()


## El eco de la Puerta. Un solo reverb para el valle entero, con la vuelta en
## cero mientras no estés ahí, así que en el 95% del mapa no hace nada más que
## copiar muestras.
func _armar_eco() -> void:
	var i := AudioServer.get_bus_index(PREFIJO + "Valle")
	if i == -1 or AudioServer.get_bus_effect_count(i) > 0:
		return
	var r := AudioEffectReverb.new()
	# Piedra desnuda: cola larga y poca absorción. `damping` bajo es lo que
	# separa la roca de una habitación con cosas adentro.
	r.room_size = 0.88
	r.damping = 0.22
	r.spread = 1.0
	r.predelay_msec = 42.0   # 14 m de ida y vuelta: el ancho del vano
	r.predelay_feedback = 0.35
	r.hipass = 0.06          # el retumbe grave de una garganta de roca se queda
	r.dry = 1.0
	r.wet = 0.0
	AudioServer.add_bus_effect(i, r)
	_reverb = r


func _bus(nombre: String, envia: String, efecto: AudioEffect) -> void:
	if AudioServer.get_bus_index(nombre) != -1:
		return
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, nombre)
	if AudioServer.get_bus_index(envia) != -1:
		AudioServer.set_bus_send(i, envia)
	if efecto != null:
		AudioServer.add_bus_effect(i, efecto)
	_buses.append(nombre)


func _soltar_buses() -> void:
	# Al revés: sacar un bus corre los índices de los de arriba.
	for k in range(_buses.size() - 1, -1, -1):
		var i := AudioServer.get_bus_index(_buses[k])
		if i > 0:
			AudioServer.remove_bus(i)
	_buses.clear()


static func _filtro_bajo(hz: float, res: float) -> AudioEffectFilter:
	var f := AudioEffectLowPassFilter.new()
	f.cutoff_hz = hz
	f.resonance = res
	f.db = AudioEffectFilter.FILTER_12DB
	return f


static func _filtro_alto(hz: float, res: float) -> AudioEffectFilter:
	var f := AudioEffectHighPassFilter.new()
	f.cutoff_hz = hz
	f.resonance = res
	f.db = AudioEffectFilter.FILTER_12DB
	return f


static func _filtro_banda(hz: float, res: float) -> AudioEffectFilter:
	var f := AudioEffectBandPassFilter.new()
	f.cutoff_hz = hz
	f.resonance = res
	f.db = AudioEffectFilter.FILTER_12DB
	return f


func _corte(bus: String, hz: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1 or AudioServer.get_bus_effect_count(i) == 0:
		return
	var e := AudioServer.get_bus_effect(i, 0) as AudioEffectFilter
	if e != null:
		e.cutoff_hz = clampf(hz, 20.0, 10000.0)


func _volumen(bus: String, lineal: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	# Debajo de este piso no se oye nada y sí se sigue mezclando: se silencia
	# el bus entero, que es gratis.
	var v := maxf(lineal, 0.0)
	AudioServer.set_bus_mute(i, v < 0.0015)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0015)))


# ── Emisores ─────────────────────────────────────────────────────────────

func _armar_emisores() -> void:
	# El fondo no tiene lugar: suena igual mires para donde mires. Dos copias
	# del mismo bucle a tonos que no son múltiplos entre sí es lo que le saca
	# el bucle de encima: 11 s y 11/0,79 s tardan horas en volver a coincidir.
	_fondo("viento", PREFIJO + "Viento", 1.00)
	_fondo("viento", PREFIJO + "Viento", 0.79)
	_fondo("pajaros", PREFIJO + "Pajaros", 1.00)
	_fondo("grillos", PREFIJO + "Grillos", 1.00)
	_fondo("grillos", PREFIJO + "Grillos", 1.13)
	_fondo("hojas", PREFIJO + "Hojas", 1.00)
	_fondo("hueco", PREFIJO + "Hueco", 1.00)

	# El río. Tres emisores sobre la línea del agua de valle.gd. Con uno solo
	# el río sería un punto que te sigue; con tres, caminar la orilla se oye
	# como caminar la orilla, y desde la aldea (26 m) se oye, que es lo que
	# dice "las casas están apretadas contra el recodo".
	# Cada tramo a un tono distinto: si los tres corrieran el mismo bucle en
	# fase, las burbujas volverían las tres a la vez y eso se oye a máquina.
	var eje := Vector3(cos(deg_to_rad(RIO_GIRO)), 0.0, -sin(deg_to_rad(RIO_GIRO)))
	var tonos := [0.91, 1.0, 1.07]
	for k in 3:
		var d := (float(k) - 1.0) * RIO_SEPARACION
		# 85 m de alcance y no 120: el emisor más cercano al Sotobosque está a
		# 91 m, y con el corte viejo el río se oía desde el bosque. Se midió que
		# era el 36% de lo que llegaba al oído ahí — justo en el lugar que tiene
		# que sonar a nada. El río llega a la aldea y a la fragua, y para ahí.
		_mundo("rio", PREFIJO + "Rio", RIO_CENTRO + eje * d, 18.0, 85.0, float(tonos[k]))

	var f_fragua: Vector3 = _tabla.get("fragua", POS["fragua"])["pos"]
	# El fuego de la fragua se oye de cerca. La fragua no es un faro sonoro:
	# es un lugar cálido cuando llegás.
	_mundo("fuego", PREFIJO + "Fuego", f_fragua + Vector3(0, 1.2, 0), 13.0, 92.0, 1.0)
	# El martillo SÍ cruza el valle. Es el único que lo hace, y es a propósito:
	# desde la aldea o desde el camino oís que Ilde está trabajando y sabés
	# para qué lado queda. Es la brújula del valle.
	_mundo("yunque", PREFIJO + "Yunque", f_fragua + Vector3(0, 1.4, 0), 30.0, 260.0, 1.0)

	var f_aldea: Vector3 = _tabla.get("aldea", POS["aldea"])["pos"]
	_mundo("hogar", PREFIJO + "Hogar", f_aldea + Vector3(0, 1.0, 0), 11.0, 60.0, 1.0)

	var f_bosque: Vector3 = _tabla.get("bosque", POS["bosque"])["pos"]
	# Lo único que pasa en el Sotobosque. Uno cada tanto, con huecos largos.
	# Un solo crujido en un campo casi mudo vale más que cualquier lecho: es
	# la diferencia entre "esto está vacío" y "esto está vacío, ¿o no?".
	_mundo("crujido", PREFIJO + "Crujido", f_bosque + Vector3(0, 1.5, 0), 14.0, 70.0, 1.0)

	# LAS CINCO VOCES DEL TRABAJO. Un emisor por FAMILIA y no por persona: lo
	# reposiciona `_trabajar()` sobre el que trabaja más cerca, justo antes de
	# cada golpe. Con esto el gasto de reproductores es fijo —cinco— tenga el
	# valle siete personas o cuarenta, y ese número es el que había que cuidar.
	#
	# El yunque ya estaba armado más arriba con su posición clavada en la
	# fragua. Se lo deja donde está para el caso en que no haya nadie: no suena.
	for familia: String in OFICIOS_SON:
		if familia == "yunque":
			continue
		var d: Dictionary = OFICIOS_SON[familia]
		_mundo(familia, PREFIJO + "Oficio", f_aldea + Vector3(0, 1.1, 0),
			float(d["unidad"]), float(d["max"]), 1.0)

	# El murmullo. Alcance cortísimo: es "hay alguien al lado", no "hay alguien
	# en el pueblo". A 22 m ya no llega, y eso es lo que lo salva de ser el
	# ruido de multitud genérico que este archivo no quiere tener.
	_mundo("murmullo", PREFIJO + "Voz", f_aldea + Vector3(0, 1.5, 0), 5.0, 22.0, 1.0)

	# DOS EMISORES DEL MISMO RUIDO SUENAN 3 dB MÁS FUERTE QUE UNO.
	#
	# Es la suma de dos señales no correlacionadas y estaba sin contemplar: el
	# viento y los grillos salían 3 dB por encima de lo que decía su ganancia,
	# o sea que la tabla de lechos mentía justo en las dos voces más presentes.
	# Se compensa acá, en el emisor, y no en el bus: el bus es donde vive la
	# ganancia de la mezcla y tiene que seguir queriendo decir lo que dice.
	for voz: String in _jug:
		_gan[voz] = 0.0
		var lista: Array = _jug[voz]
		if lista.size() > 1 and lista[0] is AudioStreamPlayer:
			var comp := -10.0 * log(float(lista.size())) / log(10.0)
			for p: Node in lista:
				p.set("volume_db", comp)


func _fondo(voz: String, bus: String, tono: float) -> void:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.pitch_scale = tono
	p.volume_db = 0.0
	add_child(p)
	if not _jug.has(voz):
		_jug[voz] = []
	_jug[voz].append(p)


func _mundo(voz: String, bus: String, pos: Vector3, unidad: float, maximo: float, tono: float) -> void:
	var p := AudioStreamPlayer3D.new()
	p.bus = bus
	p.unit_size = unidad
	p.max_distance = maximo
	p.pitch_scale = tono
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	# Sin esto, cada emisor de ambiente pelea con la niebla de aire de Godot y
	# el resultado depende de la placa. El ambiente no se filtra por distancia:
	# lo hacen los buses, donde se ve por qué.
	p.attenuation_filter_cutoff_hz = 20500.0
	add_child(p)
	# La posición va DESPUÉS de add_child: `global_position` sobre un nodo que
	# todavía no está en el árbol tira "Condition !is_inside_tree() is true" y
	# la posición se pierde.
	p.global_position = pos
	if not _jug.has(voz):
		_jug[voz] = []
	_jug[voz].append(p)


## Los bucles ya están: colgarlos y arrancar.
func _montar(bufs: Dictionary) -> void:
	for voz: String in _jug:
		var s: AudioStream = bufs.get(voz, null)
		if s == null:
			continue
		for p: Node in _jug[voz]:
			p.stream = s
			# Los de un solo golpe no arrancan solos.
			if VOCES_SUELTAS.has(voz):
				continue
			if _hay_salida:
				p.play(randf() * 3.0)   # desfasados: si arrancan juntos, laten
	_listo = true


# ── La mezcla en vivo ────────────────────────────────────────────────────

func _process(dt: float) -> void:
	if not _listo:
		return
	_reloj += dt

	var f := hora()
	var pos := oyente.global_position if oyente != null else Vector3.ZERO
	var g := lecho_en(pos, f)

	# Las ráfagas. Tres senos de períodos que no encajan (17, 6,3 y 2,9 s) dan
	# algo que no se repite en varios minutos. El viento sube y el filtro se
	# abre JUNTOS, porque una ráfaga real trae agudos, no sólo volumen.
	# Los coeficientes suman 0,55: en el peor cruce el viento llega a CERO, y
	# eso es a propósito. La versión anterior nunca bajaba de 0,14 — o sea que
	# había ruido de banda ancha permanente, sin un solo hueco, que es la receta
	# exacta de la fatiga auditiva. Un lecho tiene que respirar hasta el fondo.
	var rafaga := clampf(0.55 \
		+ 0.30 * sin(_reloj * TAU / 17.0) \
		+ 0.16 * sin(_reloj * TAU / 6.3 + 1.7) \
		+ 0.09 * sin(_reloj * TAU / 2.9 + 0.4), 0.0, 1.2)
	var brillo := float(g["brillo"])

	_suave("viento", float(g["viento"]) * rafaga, dt, 0.9)
	_suave("pajaros", float(g["pajaros"]), dt, 0.5)
	_suave("grillos", float(g["grillos"]), dt, 0.4)
	_suave("hojas", float(g["hojas"]) * (0.55 + 0.45 * rafaga), dt, 0.8)
	_suave("hueco", float(g["hueco"]) * (0.35 + 0.65 * rafaga), dt, 0.7)
	_suave("rio", float(g["rio"]), dt, 0.6)
	_suave("fuego", float(g["fuego"]), dt, 0.3)
	_suave("hogar", float(g["hogar"]), dt, 0.3)

	_volumen(PREFIJO + "Viento", _gan["viento"])
	_volumen(PREFIJO + "Pajaros", _gan["pajaros"])
	_volumen(PREFIJO + "Grillos", _gan["grillos"])
	_volumen(PREFIJO + "Hojas", _gan["hojas"])
	_volumen(PREFIJO + "Hueco", _gan["hueco"])
	_volumen(PREFIJO + "Rio", _gan["rio"])
	_volumen(PREFIJO + "Fuego", _gan["fuego"])
	_volumen(PREFIJO + "Hogar", _gan["hogar"])
	_volumen(PREFIJO + "Valle", volumen_general)

	# El corte del viento: abierto en el camino, tapado bajo las copas, y
	# abriéndose con cada ráfaga.
	_corte(PREFIJO + "Viento", lerpf(240.0, 2600.0, clampf(brillo, 0.0, 1.0)) * (0.7 + 0.5 * rafaga))
	# La casa canta más agudo con el viento fuerte, como cualquier hueco.
	_corte(PREFIJO + "Hueco", 168.0 + 46.0 * rafaga)
	# De noche la fragua es brasa: menos volumen y bastante más oscura.
	_corte(PREFIJO + "Fuego", lerpf(900.0, 3000.0, clampf(float(g["fuego"]), 0.0, 1.0)))

	# El eco de la Puerta: lo único del lecho que cambia por la FORMA del lugar
	# y no por lo que hay adentro.
	_resonar_la_puerta(pos)

	# La gente. El orden importa: primero se refresca dónde está cada uno,
	# después suenan las herramientas y al final el murmullo, que es el que
	# cede si el freno ya está tomado por otra familia.
	_refrescar_a_la_gente(dt)
	_trabajar(dt, pos)
	_murmurar(dt, pos)
	_crujir(dt, pos)
	_registrar()


## El registro por segundo en el juego de verdad, con `--sonido-registro`.
## Cuesta una comparación de floats por cuadro cuando está apagado.
func _registrar() -> void:
	if not _registro_on:
		return
	if _reloj - _cuenta_desde < 1.0:
		return
	var seg := int(_reloj)
	if _cuenta.is_empty():
		_mudos += 1
	else:
		var texto := ""
		for f: String in _cuenta:
			texto += "%s×%d  " % [f, int(_cuenta[f])]
		print("registro  seg %4d   %-34s (venía de %d s callado)"
			% [seg, texto, _mudos])
		_mudos = 0
	_cuenta = {}
	_cuenta_desde = _reloj


func _suave(voz: String, objetivo: float, dt: float, vel: float) -> void:
	# Exponencial y lento a propósito: cruzar de la aldea al bosque tarda unos
	# segundos. Un corte seco se oye como un cambio de nivel; un cruce lento se
	# oye como caminar.
	var a: float = _gan.get(voz, 0.0)
	_gan[voz] = lerpf(a, objetivo, 1.0 - exp(-dt * vel * 1.6))


# ── EL TRABAJO DE LA GENTE ───────────────────────────────────────────────

## Dónde está cada uno, refrescado cuatro veces por segundo.
##
## Y no en cada cuadro: son siete búsquedas de nodo por vuelta y el sonido no
## necesita seguir una zancada. Cuatro por segundo es más que de sobra para que
## el martillo acompañe a Ilde por su ronda, y es 1/15 del trabajo.
func _refrescar_a_la_gente(dt: float) -> void:
	_refresco_gente -= dt
	if _refresco_gente > 0.0:
		return
	_refresco_gente = 0.25
	for d in _gente:
		d["pos"] = _donde_esta(str(d["nombre"]), str(d["slug"]))


## Quién de esa familia trabaja más cerca del oyente, y a qué distancia.
## Devuelve vacío si no hay nadie — y "no hay nadie" es la respuesta normal la
## mitad del día.
##
## **EL ALCANCE ES EL DE LA FAMILIA, no uno global**, y esto fue un bug de
## verdad que encontró la medición: con un alcance único de 270 m, el módulo
## disparaba la muela y el caldero desde el Sotobosque, a 200 metros de nadie.
## El `max_distance` del emisor los volvía inaudibles, así que no se OÍA el
## defecto — pero cada disparo fantasma se comía el freno común y sacaba de
## ritmo a las familias que sí se estaban oyendo. Medido: 67 eventos/min en el
## Sotobosque, un lugar donde no hay una sola persona.
func _quien_trabaja(familia: String, oido: Vector3) -> Dictionary:
	var mejor := {}
	var cerca: float = float((OFICIOS_SON[familia] as Dictionary)["max"])
	for d in _gente:
		if not bool(d["trabajando"]) or str(d["familia"]) != familia:
			continue
		var dist: float = (d["pos"] as Vector3).distance_to(oido)
		if dist < cerca:
			cerca = dist
			mejor = d
	if not mejor.is_empty():
		mejor = mejor.duplicate()
		mejor["_dist"] = cerca
	return mejor


## EL RALEO POR DISTANCIA. De cerca oís el trabajo entero; de lejos oís cada
## tanto una racha, y con eso alcanza para saber dónde queda.
##
## No es un ahorro disfrazado de diseño, es al revés: el martillo cruza el valle
## porque es la brújula, y una brújula no necesita hablar todo el tiempo. Sin
## esto, parado en el Sotobosque a 125 metros de la fragua oías veintisiete
## martillazos por minuto que no te decían nada nuevo después del tercero —y
## veintisiete por minuto sostenidos es, literalmente, la definición de que el
## sonido moleste.
##
## Y no miente: no afirma nada distinto de lo que afirmaba. Ilde sigue estando
## ahí y sigue forjando; lo que cambia es cuánto de eso te llega, que es lo que
## pasa con cualquier ruido a través de un valle.
const RALEO_CERCA := 30.0
const RALEO_LEJOS := 110.0
const RALEO_MAX := 2.6


static func _raleo(dist: float) -> float:
	return 1.0 + RALEO_MAX * smoothstep(RALEO_CERCA, RALEO_LEJOS, dist)


## LAS CINCO HERRAMIENTAS. Es la máquina de rachas del yunque generalizada a
## las cinco familias, con un estado por familia y un freno común.
##
## Lo único que cambió de fondo respecto del martillo viejo es de dónde sale el
## permiso para sonar: antes era `CURVA_YUNQUE`, o sea la hora; ahora es que el
## servidor mande a esa persona despierta y en su lugar. La hora sigue estando
## —de noche duermen— pero ahora está donde tiene que estar, que es en el
## servidor y no en una tabla de este archivo.
func _trabajar(dt: float, oido: Vector3) -> void:
	_freno_gente = maxf(0.0, _freno_gente - dt)
	for familia: String in OFICIOS_SON:
		if not _jug.has(familia):
			continue
		var quien := _quien_trabaja(familia, oido)
		var e: Dictionary = _ritmo.get(familia, {"espera": randf() * 3.0, "seguidos": 0, "meta": 0})
		_ritmo[familia] = e
		if quien.is_empty():
			# Nadie de esta familia trabajando cerca: el reloj se congela donde
			# está. Así el que vuelve al lugar no se come una racha entera de
			# golpes acumulados en el primer cuadro.
			continue
		var d: Dictionary = OFICIOS_SON[familia]
		e["espera"] = float(e["espera"]) - dt
		if float(e["espera"]) > 0.0:
			continue
		# El freno común: si otra familia acaba de sonar, este golpe se corre
		# unas décimas en vez de perderse. Perderlo cortaría la racha y una
		# racha cortada se oye como que el herrero se distrajo.
		if _freno_gente > 0.0:
			e["espera"] = _freno_gente + 0.02
			continue
		var p := _jug[familia][0] as AudioStreamPlayer3D
		if p != null and p.stream != null:
			p.global_position = quien["pos"]
			if _hay_salida and not _midiendo:
				var t: Array = d["tono"]
				var v: Array = d["db"]
				p.pitch_scale = randf_range(float(t[0]), float(t[1]))
				p.volume_db = randf_range(float(v[0]), float(v[1]))
				p.play()
		_anotar(familia)
		_freno_gente = GENTE_FRENO
		var g: Array = d["golpe"]
		var racha: Array = d["racha"]
		var pausa: Array = d["pausa"]
		e["seguidos"] = int(e["seguidos"]) + 1
		if int(e["meta"]) <= 0:
			e["meta"] = randi_range(int(racha[0]), int(racha[1]))
		if int(e["seguidos"]) >= int(e["meta"]):
			e["seguidos"] = 0
			e["meta"] = 0
			# La pausa entre rachas es la que se estira con la distancia; el
			# ritmo de adentro de la racha NO se toca. Si se estirara el ritmo,
			# un herrero lejano martillaría en cámara lenta, que es un bicho
			# raro. Lo que pasa de verdad es que oís menos rachas, no rachas
			# más lentas.
			e["espera"] = randf_range(float(pausa[0]), float(pausa[1])) \
				* _raleo(float(quien["_dist"]))
		else:
			e["espera"] = randf_range(float(g[0]), float(g[1]))


## EL MURMULLO. Que se oiga que hay alguien, y nada más que eso.
##
## No es diálogo: son 800 ms de voz sin palabras, muy filtrada, al tono que le
## toca a esa persona por su nombre. Suena sólo si estás a menos de 17 m de
## alguien despierto, y con huecos de 6 a 15 segundos.
##
## HASTA DÓNDE LLEGA, sin maquillaje: son dos formantes sobre un pulso glotal,
## que es la receta de manual y lee como voz humana **de lejos y bajo**. De
## cerca y solo, no. Es la misma muleta que los pájaros, y hay que decirlo
## igual: si un día se graban voces, ésta es la segunda de la lista.
func _murmurar(dt: float, oido: Vector3) -> void:
	if not _jug.has("murmullo"):
		return
	_prox_murmullo -= dt
	if _prox_murmullo > 0.0:
		return
	var cerca: Array[Dictionary] = []
	for d in _gente:
		if not bool(d["despierta"]):
			continue
		if (d["pos"] as Vector3).distance_to(oido) < MURMULLO_ALCANCE:
			cerca.append(d)
	if cerca.is_empty():
		# Nadie al lado: se reintenta pronto, pero no suena nada. El silencio
		# cuando no hay nadie es la mitad de por qué el murmullo dice algo.
		_prox_murmullo = 1.5
		return
	if _freno_gente > 0.0:
		_prox_murmullo = _freno_gente + 0.05
		return
	var quien: Dictionary = cerca[randi() % cerca.size()]
	var p := _jug["murmullo"][0] as AudioStreamPlayer3D
	if p != null and p.stream != null:
		p.global_position = quien["pos"]
		if _hay_salida and not _midiendo:
			# El tono es de la persona; el ±4% de arriba es que nadie dice dos
			# veces lo mismo con la misma entonación.
			p.pitch_scale = float(quien["tono"]) * randf_range(0.96, 1.04)
			p.volume_db = MURMULLO_DB + randf_range(-3.0, 1.5)
			p.play()
	_anotar("murmullo")
	_freno_gente = GENTE_FRENO
	_prox_murmullo = randf_range(float(MURMULLO_ESPERA[0]), float(MURMULLO_ESPERA[1]))


## El registro. Un `+= 1` por disparo y el hueco de silencio más largo. Es lo
## que convierte "el sonido molesta" en un número que se puede comparar.
func _anotar(familia: String) -> void:
	_cuenta[familia] = int(_cuenta.get(familia, 0)) + 1
	_silencio_max = maxf(_silencio_max, _reloj - _ultimo_evento)
	_ultimo_evento = _reloj


## EL ECO DE LA PUERTA DEL NORTE. Lo único que cambia porque el LUGAR tiene una
## forma, y no porque adentro haya algo haciendo ruido.
func _resonar_la_puerta(oido: Vector3) -> void:
	if _reverb == null:
		return
	var d := Vector2(oido.x, oido.z).distance_to(Vector2(PUERTA.x, PUERTA.z))
	var w := PUERTA_ECO * (1.0 - smoothstep(PUERTA_LLENO, PUERTA_CERO, d))
	# Se escribe sólo si cambió de verdad: es una propiedad de un efecto del
	# AudioServer y tocarla en cada cuadro por nada es trabajo tirado.
	if absf(_reverb.wet - w) > 0.002:
		_reverb.wet = w


## El Sotobosque. Sólo cuando estás cerca, y con huecos largos.
func _crujir(dt: float, pos: Vector3) -> void:
	if not _jug.has("crujido"):
		return
	var c: Vector3 = _tabla.get("bosque", POS["bosque"])["pos"]
	if Vector2(pos.x, pos.z).distance_to(Vector2(c.x, c.z)) > 60.0:
		return
	_prox_crujido -= dt
	if _prox_crujido > 0.0:
		return
	var p := _jug["crujido"][0] as AudioStreamPlayer3D
	if p != null and p.stream != null and _hay_salida:
		# Cada vez desde otro punto del bosque. Que no venga siempre del mismo
		# lado es la mitad de por qué inquieta.
		var a := randf() * TAU
		var r := randf_range(6.0, 22.0)
		p.global_position = c + Vector3(cos(a) * r, 1.5, sin(a) * r)
		p.pitch_scale = randf_range(0.78, 1.22)
		p.volume_db = randf_range(-9.0, -1.0)
		p.play()
	_prox_crujido = randf_range(9.0, 26.0)


# ─────────────────────────────────────────────────────────────────────────
#  LA SÍNTESIS. Cero bytes en disco.
#
#  Todo son bucles cortos de PCM de 16 bits a 22050 Hz generados al arrancar.
#  22050 y no 44100 porque nada de este lecho vive arriba de 8 kHz y la mitad
#  de las muestras es la mitad del tiempo de generación; y bucles pre-generados
#  y no `AudioStreamGenerator` porque un generador obliga a alimentar el buffer
#  desde GDScript en cada cuadro, y eso es un costo permanente en la máquina
#  del jugador. Acá se paga una vez al arrancar y después mezcla el
#  AudioServer, que es C++ y ya está corriendo igual.
#
#  DÓNDE LLEGA ESTO Y DÓNDE NO — sin maquillaje:
#    BIEN     · viento, río, fuego, grillos, el lamento de la ruina. Son
#               procesos de ruido filtrado, que es lo que la síntesis hace
#               mejor que nada. No hay una grabación que los mejore mucho.
#    PASABLE  · pájaros. Los barridos de frecuencia leen como pájaro a bajo
#               volumen y de lejos. De cerca y solos, no. Se reemplazan.
#    EL TECHO · el yunque. Un golpe metálico es síntesis modal y se puede
#               fingir, pero el impacto real tiene una densidad de parciales
#               que cuatro senos no dan. Es lo primero que hay que grabar.
#    NO       · voces, pasos y cualquier cosa con cuerpo humano. Ver la
#               entrega: no se intentan acá.
# ─────────────────────────────────────────────────────────────────────────

## LARGOS PRIMOS ENTRE SÍ. No es un detalle: es la mitad de por qué un lecho
## cansa o no.
##
## La primera versión tenía todo en bucles de cuatro segundos, y el oído
## detecta un patrón de cuatro segundos en menos de un minuto — sobre todo con
## el río y el fuego, que no son ruido liso sino TRANSITORIOS (burbujas,
## chasquidos) que volvían idénticos y en el mismo orden cada cuatro segundos.
## Eso no es un lecho: es un tic, y un tic no se puede dejar de oír.
##
## Ahora cada voz tiene un largo distinto y ninguno es múltiplo de otro, así
## que la combinación tarda horas en volver a alinearse. Encima cada voz que
## tiene más de un emisor los corre a tonos distintos, y un tono distinto es un
## largo distinto. La prueba imprime el período compuesto medido.
## Los que llevan TRANSITORIOS sueltos —río, fuego, grillos, pájaros— son los
## que hay que estirar más: un chasquido idéntico que vuelve es mucho más fácil
## de detectar que un ruido liso que vuelve.
const LARGOS := {
	"viento": 11.0, "rio": 13.0, "hojas": 9.0, "hueco": 15.0,
	"grillos": 10.0, "pajaros": 17.0, "fuego": 8.0, "hogar": 12.0,
}

## Todos los bucles salen normalizados al MISMO nivel eficaz. Sin esto las
## ganancias de la tabla de lechos no querían decir nada: un 0,5 de viento y un
## 0,5 de grillos sonaban a volúmenes distintos porque los generadores producen
## amplitudes distintas, y la mezcla que yo creía estar escribiendo no era la
## que salía. Ahora un 0,5 es un 0,5 en todas las voces.
##
## -20 dBFS eficaces por voz es el nivel de trabajo. Con tres o cuatro voces
## sonando a la vez la suma queda cerca de -14 dBFS, y de ahí baja el volumen
## general. Un lecho de ambiente tiene que vivir ahí abajo: si compite con lo
## que pasa en pantalla, cansa.
const RMS_VOZ := 0.10


func _generar_todo() -> Dictionary:
	var d := {}
	d["viento"] = _lecho_wav("viento", _ruido_rosa_bucle(LARGOS["viento"], 11))
	d["rio"] = _lecho_wav("rio", _agua(LARGOS["rio"], 23))
	d["hojas"] = _lecho_wav("hojas", _ruido_rosa_bucle(LARGOS["hojas"], 37))
	d["hueco"] = _lecho_wav("hueco", _ruido_rosa_bucle(LARGOS["hueco"], 53))
	d["grillos"] = _lecho_wav("grillos", _grillos(LARGOS["grillos"], 71))
	d["pajaros"] = _lecho_wav("pajaros", _pajaros(LARGOS["pajaros"], 97))
	d["fuego"] = _lecho_wav("fuego", _fuego(LARGOS["fuego"], 113))
	d["hogar"] = _lecho_wav("hogar", _fuego(LARGOS["hogar"], 131))
	# Los golpes se normalizan por PICO, no por nivel eficaz: son transitorios,
	# y lo que importa de un transitorio es que no recorte.
	d["yunque"] = _golpe_wav("yunque", _yunque(151), 0.85)
	d["crujido"] = _golpe_wav("crujido", _crujido(167), 0.75)
	# Las cinco voces del trabajo y la de la gente. Los golpes secos —el hacha—
	# van por PICO como el yunque; lo que tiene largo —la muela, el caldero, la
	# cota y el murmullo— va a -20 dBFS eficaces con techo de pico, que es la
	# convención de la casa y la que existe justamente para que un 0,5 quiera
	# decir lo mismo en todas las voces.
	d["muela"] = _voz_wav("muela", _muela(181), 0.78)
	d["caldero"] = _voz_wav("caldero", _caldero(193), 0.80)
	d["hacha"] = _golpe_wav("hacha", _hacha(199), 0.80)
	d["cota"] = _voz_wav("cota", _cota(211), 0.70)
	d["murmullo"] = _voz_wav("murmullo", _murmullo(223), 0.82)
	return d


## Mide el bucle CRUDO, lo anota, y recién ahí lo normaliza.
##
## La medición del crudo no es curiosidad: es la que descubrió el peor defecto
## que tuvo este archivo. El viento salía del generador a -7,6 dBFS eficaces y
## con picos de 1,676 — o sea que `_wav()` le recortaba contra el tope el 2%
## de las muestras, de forma continua. Ruido de banda ancha recortado es
## áspero, y áspero sostenido es exactamente lo que hace que alguien baje el
## volumen. Encima el viento salía 20 dB por encima de los pájaros, así que la
## tabla de acentos por lugar era pura ficción: dijera lo que dijera, ganaba el
## viento. Queda medido para siempre para que no vuelva a pasar en silencio.
func _lecho_wav(voz: String, m: PackedFloat32Array) -> AudioStreamWAV:
	# Una sola medición y una sola escalada: son dos millones de muestras por
	# bucle y cada recorrida de más se paga en el arranque del juego.
	var r := _rms(m)
	var pk := _pico(m)
	_nativo[voz] = {"rms": r, "pico": pk}
	var k := RMS_VOZ / maxf(r, 0.000001)
	# Un bucle con transitorios puede tener picos muy por encima del nivel
	# eficaz. Si recortara, el recorte es distorsión y se oye.
	if pk * k > 0.98:
		k = 0.98 / pk
	return _wav(_escalar(m, k), true)


func _golpe_wav(voz: String, m: PackedFloat32Array, pico: float) -> AudioStreamWAV:
	var r := _rms(m)
	var pk := _pico(m)
	_nativo[voz] = {"rms": r, "pico": pk}
	return _wav(_escalar(m, pico / maxf(pk, 0.000001)), false)


## Como `_lecho_wav` —nivel eficaz a -20 dBFS con techo de pico— pero sin
## bucle. Es para lo que tiene largo y no se repite: la muela, el caldero, la
## cota y el murmullo. Normalizar por RMS sin mirar el pico es exactamente cómo
## se recortaba el viento, así que el techo no es opcional.
func _voz_wav(voz: String, m: PackedFloat32Array, pico: float) -> AudioStreamWAV:
	var r := _rms(m)
	var pk := _pico(m)
	_nativo[voz] = {"rms": r, "pico": pk}
	var k := RMS_VOZ / maxf(r, 0.000001)
	if pk * k > pico:
		k = pico / pk
	return _wav(_escalar(m, k), false)


static func _rms(m: PackedFloat32Array) -> float:
	if m.is_empty():
		return 0.0
	var s := 0.0
	for i in m.size():
		s += m[i] * m[i]
	return sqrt(s / float(m.size()))


static func _pico(m: PackedFloat32Array) -> float:
	var p := 0.0
	for i in m.size():
		p = maxf(p, absf(m[i]))
	return p


static func _escalar(m: PackedFloat32Array, k: float) -> PackedFloat32Array:
	for i in m.size():
		m[i] *= k
	return m


static func _wav(m: PackedFloat32Array, bucle: bool) -> AudioStreamWAV:
	var datos := PackedByteArray()
	datos.resize(m.size() * 2)
	for i in m.size():
		datos.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = HZ
	w.stereo = false
	w.data = datos
	if bucle:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = m.size()
	return w


## Cierra el bucle: la cola se funde encima de la cabeza. Sin esto hay un clic
## cada cuatro segundos y el clic es lo primero que el oído detecta.
static func _cerrar(m: PackedFloat32Array, cruce: int) -> PackedFloat32Array:
	var n := m.size() - cruce
	if n <= 0:
		return m
	var o := PackedFloat32Array()
	o.resize(n)
	for i in n:
		o[i] = m[i]
	for i in cruce:
		var t := float(i) / float(cruce)
		o[i] = lerpf(m[n + i], m[i], t)
	return o


## Ruido rosa (Kellet de tres polos). Rosa y no blanco porque el blanco se oye
## a televisor sin señal: el ruido de la naturaleza cae 3 dB por octava.
## De acá salen el viento, las hojas y el lamento de la ruina — el que los
## separa es el filtro de su bus, no la fuente.
static func _ruido_rosa(n: int, semilla: int) -> PackedFloat32Array:
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var o := PackedFloat32Array()
	o.resize(n)
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	for i in n:
		var w := r.randf_range(-1.0, 1.0)
		b0 = 0.99765 * b0 + w * 0.0990460
		b1 = 0.96300 * b1 + w * 0.2965164
		b2 = 0.57000 * b2 + w * 1.0526913
		o[i] = (b0 + b1 + b2 + w * 0.1848) * 0.24
	return o


static func _ruido_rosa_bucle(seg: float, semilla: int) -> PackedFloat32Array:
	return _cerrar(_ruido_rosa(int(seg * HZ) + CRUCE, semilla), CRUCE)


## El río. Ruido rosa MÁS burbujas.
##
## El siseo solo se oye a estática. Lo que el oído reconoce como agua son los
## transitorios: cada burbuja que colapsa es un seno corto que SUBE de tono
## mientras se apaga, y ciento y pico de esos por segundo, a tonos distintos,
## son un río. Es de las cosas que la síntesis hace bien de verdad.
static func _agua(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	# El lecho de ruido va A LA MITAD, y las burbujas al doble. La primera
	# versión estaba al revés y se midió: el río tenía el mismo reparto por
	# banda que el viento, hasta el último punto porcentual. O sea que en la
	# mezcla no había río, había más viento — y el río es justamente la voz
	# que tiene que anclar el valle. Lo que el oído reconoce como agua son los
	# transitorios, no el siseo, así que el siseo se corre para atrás.
	var o := _escalar(_ruido_rosa(n, semilla), 0.42)
	var r := RandomNumberGenerator.new()
	r.seed = semilla + 7
	var cuantas := int(seg * 70.0)
	for _k in cuantas:
		var dur := r.randi_range(140, 560)
		var pos := r.randi_range(0, n - dur - 1)
		var f := r.randf_range(380.0, 2200.0)
		var amp := r.randf_range(0.06, 0.20)
		var dec := 4.0 / float(dur)
		var w := TAU * f / float(HZ)
		var subida := r.randf_range(0.25, 1.10)
		for j in dur:
			var t := float(j)
			# El barrido va en la fase, no en la frecuencia instantánea: así no
			# hay salto al empezar.
			var fase := w * t * (1.0 + subida * t / float(dur))
			o[pos + j] += sin(fase) * exp(-dec * t) * amp
	return _cerrar(o, CRUCE)


## Los grillos. Un grillo es un tono angosto de 4 a 5 kHz pulsado a veinte y
## pico de hertz, en frases de medio segundo con pausas. Se generan tres
## timbres y se siembran por el bucle a volúmenes distintos: los distintos
## volúmenes son las distintas distancias, y eso solo ya da profundidad.
static func _grillos(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var frases: Array = []
	for _k in 3:
		frases.append(_frase_grillo(
			r.randf_range(3900.0, 5100.0), r.randf_range(19.0, 27.0),
			r.randf_range(0.22, 0.40)))
	var cuantas := int(seg * 7.0)
	for _k in cuantas:
		var fr: PackedFloat32Array = frases[r.randi() % 3]
		if fr.size() >= n:
			continue
		var pos := r.randi_range(0, n - fr.size() - 1)
		var amp := r.randf_range(0.10, 0.34)
		for j in fr.size():
			o[pos + j] += fr[j] * amp
	return _cerrar(o, CRUCE)


static func _frase_grillo(hz: float, tasa: float, seg: float) -> PackedFloat32Array:
	var n := int(seg * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var periodo := int(float(HZ) / tasa)
	var largo := mini(periodo - 2, int(0.011 * HZ))
	var w := TAU * hz / float(HZ)
	var i := 0
	while i + largo < n:
		for j in largo:
			# Ventana de coseno alzado: sin ella cada pulso empieza con un clic
			# y el coro se oye a lija.
			var env := 0.5 - 0.5 * cos(TAU * float(j) / float(largo))
			o[i + j] += sin(w * float(i + j)) * env
		i += periodo
	# La frase entra y sale: un grillo no arranca a pleno.
	var borde := int(0.05 * HZ)
	for j in mini(borde, n):
		o[j] *= float(j) / float(borde)
		o[n - 1 - j] *= float(j) / float(borde)
	return o


## Los pájaros. Ésta es la parte floja y hay que decirlo.
##
## Un canto se finge con un seno que barre de frecuencia con una envolvente
## rápida, más un armónico. A bajo volumen y mezclado con viento pasa; solo y
## de cerca, no. La distancia y el volumen bajo del coro son lo que lo salva,
## y eso es una muleta, no una solución. Va con huecos GRANDES: el coro del
## amanecer es muchos pájaros lejos, no uno cerca.
static func _pajaros(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var cantos: Array = []
	for _k in 6:
		cantos.append(_canto(r))
	var cuantas := int(seg * 2.4)
	for _k in cuantas:
		var c: PackedFloat32Array = cantos[r.randi() % cantos.size()]
		if c.size() >= n:
			continue
		var pos := r.randi_range(0, n - c.size() - 1)
		var amp := r.randf_range(0.06, 0.26)
		for j in c.size():
			o[pos + j] += c[j] * amp
	return _cerrar(o, CRUCE)


static func _canto(r: RandomNumberGenerator) -> PackedFloat32Array:
	var seg := r.randf_range(0.10, 0.42)
	var n := int(seg * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var f0 := r.randf_range(1900.0, 4300.0)
	# Tres contornos: cae, sube, o tiembla. Es lo poco que separa un pájaro de
	# otro a esta distancia.
	var forma := r.randi() % 3
	var salto := r.randf_range(0.35, 1.15)
	var trino := r.randf_range(14.0, 34.0)
	var fase := 0.0
	for j in n:
		var t := float(j) / float(n)
		var f := f0
		match forma:
			0: f = f0 * (1.0 + salto * (1.0 - t) * 0.5)
			1: f = f0 * (1.0 + salto * t * 0.5)
			_: f = f0 * (1.0 + 0.18 * sin(TAU * trino * t * seg))
		fase += TAU * f / float(HZ)
		# Ataque rápido, caída larga.
		var env: float = minf(t / 0.06, 1.0) * pow(1.0 - t, 1.4)
		o[j] = (sin(fase) * 0.8 + sin(fase * 2.0) * 0.2) * env
	return o


## El fuego. Ruido marrón (más grave que el rosa: es el aire, no el chispazo)
## más chasquidos cortos y brillantes. De acá salen la fragua y el hogar de la
## aldea; los separa el filtro de su bus y el volumen.
##
## Sale bien. Un fuego es exactamente eso: un lecho grave y transitorios.
static func _fuego(seg: float, semilla: int) -> PackedFloat32Array:
	var n := int(seg * HZ) + CRUCE
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	# El filtro estaba clavadísimo: se midió y el 86% de la energía caía debajo
	# de 250 Hz. Eso no es fuego, es un retumbe — un fuego real es sobre todo
	# chasquido. Se abre el filtro, se le saca peso al soplo grave y se sube la
	# cantidad y el nivel de los chasquidos, que son lo que lo hace fuego.
	var b := 0.0
	var lp := 0.0
	for i in n:
		b = b * 0.982 + r.randf_range(-1.0, 1.0) * 0.06
		lp += (b - lp) * 0.34
		o[i] = lp * 1.0
	var cuantos := int(seg * 95.0)
	for _k in cuantos:
		var dur := r.randi_range(20, 170)
		var pos := r.randi_range(0, n - dur - 1)
		var amp := r.randf_range(0.10, 0.62)
		var dec := 5.5 / float(dur)
		var f := r.randf_range(900.0, 5200.0)
		var w := TAU * f / float(HZ)
		for j in dur:
			var t := float(j)
			o[pos + j] += sin(w * t) * exp(-dec * t) * amp * r.randf_range(0.7, 1.0)
	return _cerrar(o, CRUCE)


## El martillo sobre el yunque. ACÁ ESTÁ EL TECHO DE LA SÍNTESIS.
##
## Es síntesis modal: cuatro parciales inarmónicos (las proporciones de una
## placa de metal, no de una cuerda) con caídas distintas, más un golpe sordo
## grave —el hierro caliente, que no resuena— y un transitorio de ruido de
## tres milisegundos, que es lo que el oído lee como "impacto".
##
## Va a leer como golpe metálico. NO va a sonar como un yunque de verdad: un
## impacto real tiene decenas de parciales y una no-linealidad en los primeros
## milisegundos que cuatro senos no reproducen. Es el primer archivo que hay
## que grabar o comprar, y con uno solo alcanza.
static func _yunque(semilla: int) -> PackedFloat32Array:
	var n := int(0.95 * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var base := 1180.0
	var parciales := [1.0, 2.41, 4.17, 6.83]
	var pesos := [1.0, 0.55, 0.30, 0.16]
	var caidas := [2.6, 4.2, 7.0, 11.0]
	for k in parciales.size():
		var w := TAU * base * float(parciales[k]) / float(HZ)
		var a := float(pesos[k]) * 0.34
		var d := float(caidas[k]) / float(HZ)
		for j in n:
			o[j] += sin(w * float(j)) * exp(-d * float(j)) * a
	# El golpe sordo: el metal caliente absorbe. Sin esto suena a campana.
	var wg := TAU * 148.0 / float(HZ)
	for j in n:
		o[j] += sin(wg * float(j)) * exp(-26.0 / float(HZ) * float(j)) * 0.42
	# El impacto.
	var tr := int(0.004 * HZ)
	for j in tr:
		o[j] += r.randf_range(-1.0, 1.0) * (1.0 - float(j) / float(tr)) * 0.55
	return o


## Algo se rompió en el Sotobosque y no sabés qué. Ruido con ataque
## instantáneo y caída de sesenta milisegundos, más dos o tres chasquidos
## previos: eso es una rama. Sale bien, y sale bien porque no tiene que ser
## nada reconocible — tiene que ser *algo*.
static func _crujido(semilla: int) -> PackedFloat32Array:
	var n := int(0.45 * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	# Dos o tres tironeos antes del quiebre. La madera avisa.
	for _k in r.randi_range(2, 3):
		var pos := r.randi_range(0, int(0.16 * HZ))
		var dur := r.randi_range(120, 420)
		for j in dur:
			if pos + j >= n:
				break
			o[pos + j] += r.randf_range(-1.0, 1.0) * exp(-6.0 / float(dur) * float(j)) * 0.18
	# El quiebre.
	var q := int(0.19 * HZ)
	var largo := n - q
	var lp := 0.0
	for j in largo:
		var w := r.randf_range(-1.0, 1.0)
		lp += (w - lp) * 0.42
		o[q + j] += lp * exp(-9.0 / float(largo) * float(j)) * 0.85
	return o


# ── LAS VOCES DE LA GENTE ────────────────────────────────────────────────
#
#  HASTA DÓNDE LLEGA ESTO, sin maquillaje y por adelantado:
#    BIEN     · la muela y la cota. Son ruido filtrado y modulado, que es lo
#               que la síntesis hace mejor que nada.
#    BIEN     · el caldero. Un borboteo son transitorios sobre una resonancia,
#               igual que el río, y el río salió bien.
#    PASABLE  · el hacha. Es un impacto y comparte techo con el yunque: el
#               golpe seco se finge, la densidad de parciales de la madera
#               partiéndose no.
#    EL TECHO · el murmullo. Dos formantes sobre un pulso glotal es la receta
#               de manual y lee como voz humana **de lejos y bajo**, que es
#               exactamente cómo se usa acá. De cerca y solo, no. Si un día se
#               graba algo, el yunque es el primero y esto el segundo.

## Pasabanda de dos polos (RBJ) con el centro barriendo de `hz0` a `hz1`.
##
## LOS COEFICIENTES SE RECALCULAN CADA 32 MUESTRAS, NO EN CADA UNA: 32 muestras
## son 1,5 ms y el centro del filtro se corre unos pocos hercios en ese rato.
##
## Y va con el número medido de verdad, porque acá casi meto uno inventado. La
## primera lectura fue "el arranque pasó de 350 a 620 ms, esto es carísimo" —
## y era **ruido de la máquina**: los mismos diez bucles viejos, sin tocar una
## línea, dan 350 en una corrida y 570 en la siguiente bajo WSL. Cronometrando
## sólo las cinco muestras nuevas, que es lo que había que medir:
## **39 ms con los coeficientes por muestra, 27 ms con el salto de 32.** O sea
## que la optimización es real y vale 12 ms, y la alarma era falsa. Es la misma
## lección de siempre: mirá QUÉ estás midiendo antes de creerle al número.
const PASO_COEF := 32


static func _pasabanda_var(m: PackedFloat32Array, hz0: float, hz1: float,
		q: float) -> PackedFloat32Array:
	var n := m.size()
	var o := PackedFloat32Array()
	o.resize(n)
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var b0 := 0.0
	var a1 := 0.0
	var a2 := 0.0
	for i in n:
		if i % PASO_COEF == 0:
			var f: float = lerpf(hz0, hz1, float(i) / float(maxi(n - 1, 1)))
			var w0: float = TAU * clampf(f, 30.0, float(HZ) * 0.45) / float(HZ)
			var alfa := sin(w0) / (2.0 * q)
			var a0 := 1.0 + alfa
			b0 = alfa / a0
			a1 = -2.0 * cos(w0) / a0
			a2 = (1.0 - alfa) / a0
		var x := m[i]
		var y := b0 * x - b0 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		o[i] = y
	return o


static func _ruido(n: int, semilla: int) -> PackedFloat32Array:
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var o := PackedFloat32Array()
	o.resize(n)
	for i in n:
		o[i] = r.randf_range(-1.0, 1.0)
	return o


## LA MUELA DE BRUNO. Una pasada de acero sobre piedra de afilar: 620 ms de
## ruido de banda con el centro subiendo mientras la hoja corre, y una
## envolvente que crece y cae — que es el gesto del brazo.
##
## Se parece al yunque a propósito y a la vez no puede confundirse con él: los
## dos son el mismo taller, pero el yunque es un GOLPE (ataque instantáneo,
## parciales afinados) y la muela es un ROCE (ataque lento, banda ancha). Esa
## diferencia es la que dice "acá hay dos personas y una está aprendiendo".
static func _muela(semilla: int) -> PackedFloat32Array:
	var n := int(0.62 * HZ)
	# El roce. La banda sube de 1.150 a 2.700 Hz: la hoja va tomando velocidad.
	var o := _pasabanda_var(_ruido(n, semilla), 950.0, 2300.0, 1.15)
	# El cuerpo de la hoja, que zumba mientras la aprietan. Poco: si se pasa,
	# suena a sierra eléctrica y este mundo no tiene motores.
	var cuerpo := _pasabanda_var(_ruido(n, semilla + 5), 380.0, 320.0, 3.4)
	for i in n:
		var t := float(i) / float(n)
		# Crece en el primer tercio y cae: es el brazo, no un interruptor.
		var env: float = pow(minf(1.0, t / 0.30), 1.4) * pow(1.0 - t, 0.65)
		o[i] = (o[i] * 0.86 + cuerpo[i] * 0.30) * env
	return o


## EL CALDERO DE ODILA. Un alambique borboteando: 1,1 s de burbujas graves
## adentro de la resonancia del cacharro, y un tintineo de vidrio al final.
##
## Es la misma receta del río —transitorios que suben de tono mientras se
## apagan— pero una octava más abajo, mucho más lentas y contadas. Un río son
## ciento y pico de burbujas por segundo; una olla son cinco. **La cantidad es
## la diferencia entre agua corriendo y agua hirviendo**, y es lo único que hay
## que acertar.
static func _caldero(semilla: int) -> PackedFloat32Array:
	var n := int(1.10 * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	for _k in 7:
		var dur := r.randi_range(900, 3200)
		var pos := r.randi_range(0, n - dur - 1)
		var f := r.randf_range(105.0, 380.0)
		var amp := r.randf_range(0.20, 0.62)
		var dec := 4.6 / float(dur)
		var w := TAU * f / float(HZ)
		var subida := r.randf_range(0.30, 1.20)
		for j in dur:
			var t := float(j)
			var fase := w * t * (1.0 + subida * t / float(dur))
			o[pos + j] += sin(fase) * exp(-dec * t) * amp
	# El cacharro. Una resonancia angosta y grave le pone las paredes a las
	# burbujas: sin esto son burbujas al aire libre y no adentro de una olla.
	var eco := _pasabanda_var(o.duplicate(), 258.0, 258.0, 6.0)
	# El vidrio: un frasco que se apoya. Es lo que separa a la destiladora de
	# una cocinera, y es lo único agudo de la muestra.
	var tin := int(0.86 * HZ)
	for k in 2:
		var f := 2650.0 + 520.0 * float(k)
		var w := TAU * f / float(HZ)
		var d := (52.0 + 26.0 * float(k)) / float(HZ)
		for j in range(tin, n):
			o[j] += sin(w * float(j - tin)) * exp(-d * float(j - tin)) * (0.16 / (1.0 + float(k)))
	for i in n:
		# Entra y sale: un pedazo de olla arrancado del medio del hervor.
		var t := float(i) / float(n)
		var borde: float = minf(1.0, t / 0.05) * minf(1.0, (1.0 - t) / 0.10)
		o[i] = (o[i] + eco[i] * 0.55) * borde
	return o


## EL HACHA DE MARTA. Un hachazo en madera: 220 ms y se acabó.
##
## Tres cosas y en este orden: el filo entrando (3 ms de ruido crudo), el tronco
## respondiendo (dos modos graves e INARMÓNICOS, que es lo que hace que suene a
## leño y no a tambor) y las astillas (cola corta de ruido agudo).
##
## No se puede confundir con el yunque y ése es todo el trabajo: el yunque
## resuena casi un segundo y afinado, el hacha muere en dos décimas y sorda.
static func _hacha(semilla: int) -> PackedFloat32Array:
	var n := int(0.22 * HZ)
	var o := PackedFloat32Array()
	o.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	# El leño. 143 y 231 Hz: la razón 1,615 no es de una cuerda, y por eso no
	# suena a nota.
	for par: Array in [[143.0, 0.62, 30.0], [231.0, 0.34, 46.0]]:
		var w := TAU * float(par[0]) / float(HZ)
		var d := float(par[2]) / float(HZ)
		for j in n:
			o[j] += sin(w * float(j)) * exp(-d * float(j)) * float(par[1])
	# El filo entrando.
	var tr := int(0.003 * HZ)
	for j in tr:
		o[j] += r.randf_range(-1.0, 1.0) * (1.0 - float(j) / float(tr)) * 0.70
	# Las astillas: ruido agudo que se apaga en 90 ms.
	var ast := _pasabanda_var(_ruido(n, semilla + 3), 3100.0, 1700.0, 0.9)
	for j in n:
		o[j] += ast[j] * exp(-float(j) * 26.0 / float(HZ)) * 0.30
	return o


## LA COTA DE SARN. El guardia se acomoda: cuero que se estira y anillas que se
## tocan. 340 ms, y es lo más callado de las cinco a propósito.
##
## **Que un guardia haga POCO ruido es la información.** Si sonara como un
## herrero, el oído leería "acá se trabaja" en la puerta de la aldea, que es
## justo lo contrario de lo que pasa ahí: alguien está parado mirando.
static func _cota(semilla: int) -> PackedFloat32Array:
	var n := int(0.34 * HZ)
	# El cuero: ruido grave y angosto con un temblor lento encima. El temblor es
	# lo que lo vuelve un roce y no un soplo.
	var o := _pasabanda_var(_ruido(n, semilla), 240.0, 430.0, 1.6)
	var r := RandomNumberGenerator.new()
	r.seed = semilla + 11
	for i in n:
		var t := float(i) / float(n)
		var tiemble := 0.62 + 0.38 * sin(TAU * 7.5 * t + 1.1)
		o[i] *= tiemble * minf(1.0, t / 0.10) * pow(1.0 - t, 0.9)
	# Las anillas: tres o cuatro tintineos muy cortos y muy agudos, sembrados
	# donde caiga. Son los que dicen METAL, y con muy poquito alcanza.
	for _k in r.randi_range(3, 4):
		var pos := r.randi_range(int(0.04 * HZ), n - 900)
		var f := r.randf_range(3400.0, 5600.0)
		var w := TAU * f / float(HZ)
		var d := r.randf_range(110.0, 190.0) / float(HZ)
		var amp := r.randf_range(0.05, 0.13)
		for j in range(0, mini(900, n - pos)):
			o[pos + j] += sin(w * float(j)) * exp(-d * float(j)) * amp
	return o


## EL MURMULLO. Que se oiga que hay alguien, sin que diga nada.
##
## Es síntesis por formantes de manual: un pulso glotal —el equivalente a una
## cuerda vocal— pasado por dos resonancias que se mueven de una vocal a otra.
## Eso es lo que el oído lee como voz humana; las consonantes, que es lo que
## haría entender palabras, no están y no van a estar.
##
## Y no van a estar por diseño, no por límite técnico: **el juego es de leer.**
## Una voz que intenta decir algo y no lo dice suena a juguete, y encima abre la
## puerta a que el sonido afirme cosas que el servidor no dijo. Esto dice
## exactamente una: hay una persona ahí.
##
## El tono baja hacia el final —una frase que termina cae— y la amplitud
## tiembla a 3,6 Hz, que es más o menos el ritmo de las sílabas. Esos dos
## detalles son la diferencia entre "alguien habla" y "hay un zumbido".
static func _murmullo(semilla: int) -> PackedFloat32Array:
	var n := int(0.85 * HZ)
	var fuente := PackedFloat32Array()
	fuente.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var f0 := 128.0
	var fase := 0.0
	var vibra := 0.0
	for i in n:
		var t := float(i) / float(n)
		# Micro-desafinación. Una voz perfectamente afinada es un sintetizador.
		vibra += (r.randf_range(-1.0, 1.0) - vibra) * 0.015
		var hz: float = f0 * (1.0 + 0.05 * vibra) * lerpf(1.07, 0.86, t * t)
		fase += TAU * hz / float(HZ)
		# Pulso glotal: un diente de sierra con la caída exponencial de una
		# glotis abriéndose y cerrándose, no un seno.
		var ph := fposmod(fase, TAU) / TAU
		fuente[i] = exp(-ph * 5.5) - 0.17
	# Las dos formantes. De (520, 1180) a (680, 1520): de una vocal cerrada a
	# una abierta, que es lo que hace un "mmhm".
	var f1 := _pasabanda_var(fuente, 520.0, 680.0, 5.5)
	var f2 := _pasabanda_var(fuente, 1180.0, 1520.0, 7.0)
	var o := PackedFloat32Array()
	o.resize(n)
	for i in n:
		var t := float(i) / float(n)
		# Sílabas: la amplitud tiembla a 3,6 Hz. Sin esto es una nota tenida.
		var silaba := 0.55 + 0.45 * sin(TAU * 3.6 * t * 0.85 - 1.2)
		var env: float = minf(1.0, t / 0.09) * minf(1.0, (1.0 - t) / 0.22)
		o[i] = (f1[i] * 1.0 + f2[i] * 0.42) * silaba * env
	return o


# ─────────────────────────────────────────────────────────────────────────
#  EL INFORME. Lo único de todo esto que se puede verificar sin oír nada.
# ─────────────────────────────────────────────────────────────────────────

## Un punto de campo abierto de verdad: adentro del valle y fuera del alcance
## de los cinco lugares. (Antes estaba en (120,-150), que cae afuera del
## terreno: se estaba midiendo un lugar que no existe.)
const PUNTO_CAMPO := Vector3(35, 0, -60)

const HORAS_DE_PRUEBA := [0.05, 0.25, 0.38, 0.50, 0.65, 0.78, 0.90]
const RUTA := ["aldea", "fragua", "bosque", "ruina", "camino", "aldea"]

var _paso := 0


func _informe_de_prueba() -> void:
	print("")
	print("═══ EL LECHO DEL VALLE ═══════════════════════════════════════════")
	print("Godot %s · driver de audio: %s · pantalla: %s"
		% [Engine.get_version_info()["string"], AudioServer.get_driver_name(),
			DisplayServer.get_name()])
	print("Bucles generados en %.0f ms, %d buses creados, 0 bytes en disco."
		% [_ms_generacion, _buses.size()])
	_probar_el_reloj()
	_revisar_la_cadena()
	print("")
	_medir_las_voces(_bufs)
	_medir_la_repeticion()
	_medir_los_niveles()
	_medir_las_zonas()
	_medir_el_timbre()
	_medir_la_puerta()
	_medir_a_la_gente()
	_medir_el_gasto()
	_medir_los_reproductores()
	_registro_por_segundo(_tabla["fragua"]["pos"], 90, "La Fragua de Ilde")
	print("Ganancias lineales. `fondo` es la suma del lecho sin lugar")
	print("(viento+pájaros+grillos+hojas+hueco); río, fuego, hogar y yunque")
	print("tienen lugar en el mundo y la distancia los termina de bajar.")
	print("")
	var cab := "  %-9s %-13s %6s %6s %6s %6s %6s | %5s | %6s %6s %6s %6s"
	for slug: String in ["aldea", "fragua", "bosque", "ruina", "camino", "campo"]:
		var nom: String = {
			"aldea": "Vado Bajo", "fragua": "La Fragua de Ilde",
			"bosque": "El Sotobosque", "ruina": "La Casa Quemada",
			"camino": "El Camino del Norte", "campo": "campo abierto",
		}[slug]
		print("── %s (%s)" % [nom, slug])
		print(cab % ["hora", "franja", "viento", "pájaro", "grillo", "hojas",
			"hueco", "FONDO", "río", "fuego", "hogar", "yunque"])
		for f: float in HORAS_DE_PRUEBA:
			var g := lecho(slug, f)
			print(cab % [
				"%.2f" % f, franja(f),
				"%.2f" % g["viento"], "%.2f" % g["pajaros"], "%.2f" % g["grillos"],
				"%.2f" % g["hojas"], "%.2f" % g["hueco"], "%.2f" % g["fondo"],
				"%.2f" % g["rio"], "%.2f" % g["fuego"], "%.2f" % g["hogar"],
				"%.2f" % g["yunque"]])
		print("")

	print("── LO QUE HAY QUE PODER LEER EN ESA TABLA")
	var noche: float = lecho("aldea", 0.05)["fondo"]
	var dia: float = lecho("aldea", 0.50)["fondo"]
	var alba: float = lecho("aldea", 0.25)["fondo"]
	print("  · la aldea de noche suena %.0f%% de lo que suena al mediodía"
		% [noche / dia * 100.0])
	print("  · el amanecer es el momento más sonoro del día (%.2f contra %.2f)"
		% [alba, dia])
	var b: float = lecho("bosque", 0.50)["fondo"]
	var c: float = lecho("campo", 0.50)["fondo"]
	print("  · entrar al Sotobosque al mediodía apaga el ambiente a %.0f%% "
		% [b / c * 100.0] + "(%.1f dB)" % [linear_to_db(b / c)])
	print("  · y de noche lo apaga a %.0f%%: es el lugar más callado del valle"
		% [lecho("bosque", 0.90)["fondo"] / lecho("campo", 0.90)["fondo"] * 100.0])
	print("  · la fragua nunca baja de %.2f: el único techo que no se apaga"
		% [lecho("fragua", 0.05)["fuego"]])
	print("  · el río vale 1.00 a toda hora en todos lados: es el ancla")
	print("  · y la columna `yunque` de esa tabla YA NO DECIDE si suena el")
	print("    martillo: es sólo cuánto pesaría si alguien estuviera forjando.")
	print("    Quién forja lo dice el servidor — ver LA GENTE DEL VALLE.")
	print("")
	set_process(true)
	_paso = 0


## La hora tiene que salir del `ciclo.gd` de verdad, no de un reloj de acá.
##
## Esto no es decorado: es la parte del cableado que más fácil se rompe en
## silencio. Si `hora()` devolviera 0.5 para siempre, el lecho seguiría
## sonando y nadie notaría que el valle dejó de tener hora. Así que se
## instancia el Ciclo real, se lo sincroniza como lo hace el servidor y se
## comprueba que el número llegue.
func _probar_el_reloj() -> void:
	var c := Ciclo.new()
	c.sincronizar(3, Ciclo.DIA_REAL * 0.40)
	ciclo = c
	var leida := hora()
	print("Reloj: ciclo.gd sincronizado a 0.40 → hora() devuelve %.2f (%s) · %s"
		% [leida, franja(leida), "OK" if absf(leida - 0.40) < 0.005 else "MAL"])
	ciclo = null
	c.free()


## ── LA MEDICIÓN ──────────────────────────────────────────────────────────
##
## Nadie del equipo puede escuchar, así que la única crítica honesta que se
## puede hacer de este lecho es numérica. Lo que sigue mide lo que se puede
## medir: cuánto suena cada voz, en qué frecuencias, cada cuánto se repite, y
## qué nivel llega al oído en cada lugar y a cada hora.

## Las bandas. La de 2 a 5 kHz está separada porque es donde el oído es más
## sensible y donde se decide si un ambiente cansa: mucha energía ahí, sostenida
## y sin huecos, es fatiga garantizada por más bajo que esté el volumen.
## Qué fracción del tiempo suena cada voz. Las continuas valen 1; los golpes
## valen lo que ocupan de verdad — el yunque son rachas con pausas largas y el
## crujido del bosque es uno cada quince o veinte segundos.
const SERVICIO := {"yunque": 0.30, "crujido": 0.03}

const BANDAS := [
	["grave", 60.0, 250.0], ["cuerpo", 250.0, 800.0], ["medio", 800.0, 2500.0],
	["FATIGA 2-5k", 2500.0, 5000.0], ["aire", 5000.0, 10000.0],
]


## Las muestras que quedaron de verdad adentro del stream.
static func _muestras(w: AudioStreamWAV) -> PackedFloat32Array:
	var d := w.data
	var n := d.size() / 2
	var o := PackedFloat32Array()
	o.resize(n)
	for i in n:
		o[i] = float(d.decode_s16(i * 2)) / 32768.0
	return o


## Nivel eficaz dentro de una banda, con un pasabanda biquad (RBJ).
static func _banda(m: PackedFloat32Array, lo: float, hi: float) -> float:
	var f0: float = sqrt(lo * hi)
	var q: float = f0 / maxf(hi - lo, 1.0)
	var w0 := TAU * f0 / float(HZ)
	var alfa := sin(w0) / (2.0 * q)
	var a0 := 1.0 + alfa
	var b0 := alfa / a0
	var b2 := -alfa / a0
	var a1 := -2.0 * cos(w0) / a0
	var a2 := (1.0 - alfa) / a0
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var s := 0.0
	for i in m.size():
		var x := m[i]
		var y := b0 * x + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		s += y * y
	return sqrt(s / float(maxi(m.size(), 1)))


static func _dbfs(x: float) -> float:
	return 20.0 * log(maxf(x, 0.0000001)) / log(10.0)


## Ficha técnica de cada bucle: cuánto dura, cuánto suena, cuánto pica y dónde
## tiene la energía.
func _medir_las_voces(bufs: Dictionary) -> void:
	print("── LOS BUCLES, MEDIDOS")
	print("  cresta = pico/eficaz. Alta = transitorios sueltos (bien: respira).")
	print("  Baja y pareja = ruido plano y constante, que es lo que cansa.")
	print("  crudo = lo que sale del generador ANTES de normalizar. Un pico")
	print("  crudo arriba de 1.00 quiere decir que se estaba recortando contra")
	print("  el tope, y ruido recortado sostenido es lo que hace que alguien")
	print("  baje el volumen. Ésa era la falla, y esta columna la vigila.")
	var cab := "  %-9s %6s %8s %7s %7s %9s %8s   %s"
	print(cab % ["voz", "largo", "eficaz", "pico", "cresta", "crudo ef.",
		"crudo pk", "reparto por banda (%)"])
	var total_s := 0.0
	for voz: String in bufs:
		var w: AudioStreamWAV = bufs[voz]
		var m := _muestras(w)
		var seg := float(m.size()) / float(HZ)
		total_s += seg
		var r := _rms(m)
		var p := _pico(m)
		var partes: Array[float] = []
		var suma := 0.0
		for b: Array in BANDAS:
			var e := _banda(m, float(b[1]), float(b[2]))
			partes.append(e * e)
			suma += e * e
		var texto := ""
		for i in BANDAS.size():
			var pct := 100.0 * partes[i] / maxf(suma, 0.0000001)
			texto += "%s %2.0f  " % [(BANDAS[i] as Array)[0], pct]
		var nat: Dictionary = _nativo.get(voz, {})
		var npk := float(nat.get("pico", 0.0))
		print(cab % [voz, "%.1fs" % seg, "%.1f dB" % _dbfs(r), "%.1f dB" % _dbfs(p),
			"%.1fx" % (p / maxf(r, 0.000001)),
			"%.1f dB" % _dbfs(float(nat.get("rms", 0.0))),
			("%.2f ¡!" % npk) if npk > 1.0 else "%.2f" % npk, texto])
	print("  total generado: %.0f s de audio, %.1f MB en RAM, 0 bytes en disco."
		% [total_s, total_s * float(HZ) * 2.0 / 1048576.0])
	print("")


## Cada cuánto vuelve a repetirse lo que se oye.
func _medir_la_repeticion() -> void:
	print("── CADA CUÁNTO SE REPITE")
	var periodos: Array[float] = []
	var detalle := ""
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			var s := p.get("stream") as AudioStreamWAV
			if s == null or s.loop_mode != AudioStreamWAV.LOOP_FORWARD:
				continue
			var t := (float(s.data.size() / 2) / float(HZ)) / float(p.get("pitch_scale"))
			periodos.append(t)
			detalle += "%s %.1fs  " % [voz, t]
	periodos.sort()
	print("  capas: %s" % detalle)
	# La capa más corta es la que el oído puede llegar a agarrar sola.
	print("  la capa más corta vuelve cada %.1f s (antes: 4.0 s en TODAS)"
		% periodos[0])
	# Y cada cuánto vuelven a caer juntas dos capas: el mínimo común múltiplo
	# de sus períodos, no el batido entre sus frecuencias. (La primera versión
	# medía el batido y daba 15 s, que sonaba alarmante y no quería decir nada:
	# dos capas de 8 y 17 segundos no se alinean a los 15, se alinean a los
	# 136. Una métrica mal elegida es peor que ninguna.)
	var antes := 1000000.0
	var par := ""
	for i in periodos.size():
		for j in range(i + 1, periodos.size()):
			var l := _mcm(periodos[i], periodos[j])
			if l < antes:
				antes = l
				par = "%.1fs y %.1fs" % [periodos[i], periodos[j]]
	print("  las dos capas que antes vuelven a caer juntas (%s) tardan %.0f s (%.1f min)"
		% [par, antes, antes / 60.0])
	print("")


## Mínimo común múltiplo de dos períodos reales, con tolerancia: cada cuánto
## dos bucles de largo distinto vuelven a arrancar a la vez.
static func _mcm(a: float, b: float) -> float:
	var x := maxf(a, b)
	var y := minf(a, b)
	# Euclides con reales: el máximo común divisor con 10 ms de tolerancia, que
	# es más o menos lo que el oído puede llegar a notar como "juntas".
	var guardia := 0
	while y > 0.01 and guardia < 200:
		var t := fmod(x, y)
		x = y
		y = t
		guardia += 1
	if x < 0.01:
		return 1000000.0
	return a * b / x


## Cuánto le llega al oído, en dBFS, parado en cada lugar.
##
## Suma la potencia de cada voz: las de fondo tal cual, y las que tienen lugar
## en el mundo atenuadas por distancia con la misma cuenta que hace Godot para
## ATTENUATION_INVERSE_DISTANCE (unit_size/distancia, cortado en max_distance).
func _nivel_en(pos: Vector3, f: float) -> float:
	var g := lecho_en(pos, f)
	var pot := 0.0
	for voz: String in _jug:
		var gan := float(g.get(voz, 0.0))
		if gan <= 0.0:
			continue
		for p: Node in _jug[voz]:
			if p is AudioStreamPlayer:
				# Ya compensados entre sí: el conjunto vale una vez la ganancia.
				pot += pow(RMS_VOZ * gan, 2.0) / float((_jug[voz] as Array).size())
			else:
				var e := p as AudioStreamPlayer3D
				var d := e.global_position.distance_to(pos)
				if d > e.max_distance:
					continue
				var att: float = minf(1.0, e.unit_size / maxf(d, 0.01))
				pot += pow(RMS_VOZ * gan * att, 2.0)
	return _dbfs(sqrt(pot) * volumen_general)


func _medir_los_niveles() -> void:
	print("── QUÉ NIVEL LLEGA AL OÍDO (dBFS eficaces, ya con el volumen general)")
	print("  Referencia: un lecho de ambiente vive entre -30 y -22 dBFS. Arriba")
	print("  de -18 compite con todo lo demás y cansa; abajo de -38 no está.")
	var cab := "  %-9s %8s %8s %8s %8s %8s %8s %8s"
	print(cab % ["lugar", "0.05", "0.25", "0.38", "0.50", "0.65", "0.78", "0.90"])
	for slug: String in ["aldea", "fragua", "bosque", "ruina", "camino"]:
		var fila: Array = [slug]
		for f: float in HORAS_DE_PRUEBA:
			fila.append("%.1f" % _nivel_en(_tabla[slug]["pos"], f))
		print(cab % fila)
	# El campo abierto: un punto lejos de todo.
	var lejos := PUNTO_CAMPO
	var fila2: Array = ["campo"]
	for f: float in HORAS_DE_PRUEBA:
		fila2.append("%.1f" % _nivel_en(lejos, f))
	print(cab % fila2)
	print("")


## ¿Suena distinto cada lugar, de verdad?
##
## Ésta es la pregunta que importa y hasta ahora no la contestaba nadie con un
## número. Compara el reparto de energía entre voces de dos lugares: 0% es
## "idénticos", 100% es "no comparten nada". Si esto da chico, el lecho es el
## mismo en todos lados por más que la tabla tenga cinco filas.
func _diferencia(a: String, b: String, f: float) -> float:
	var pa := _reparto(_tabla[a]["pos"] if _tabla.has(a) else PUNTO_CAMPO, f)
	var pb := _reparto(_tabla[b]["pos"] if _tabla.has(b) else PUNTO_CAMPO, f)
	var d := 0.0
	for v: String in pa:
		d += absf(float(pa[v]) - float(pb.get(v, 0.0)))
	return d * 50.0


## Qué fracción del sonido que llega al oído aporta cada voz, parado en un
## punto. Incluye las voces que tienen lugar en el mundo con su atenuación por
## distancia: el río y la fragua son la mitad de la identidad de sus lugares y
## dejarlas afuera de la cuenta era medir otra cosa.
func _reparto(pos: Vector3, f: float) -> Dictionary:
	var g := lecho_en(pos, f)
	var pot := {}
	var tot := 0.0
	for voz: String in _jug:
		var gan := float(g.get(voz, 0.0))
		var e := 0.0
		for p: Node in _jug[voz]:
			if p is AudioStreamPlayer:
				e += pow(RMS_VOZ * gan, 2.0) / float((_jug[voz] as Array).size())
			else:
				var w := p as AudioStreamPlayer3D
				var dd := w.global_position.distance_to(pos)
				if dd <= w.max_distance:
					e += pow(RMS_VOZ * gan * minf(1.0, w.unit_size / maxf(dd, 0.01)), 2.0)
		# El yunque y el crujido no suenan todo el tiempo: son golpes sueltos.
		# Contarlos como si fueran continuos inflaba su parte de la mezcla.
		pot[voz] = e * float(SERVICIO.get(voz, 1.0))
		tot += e
	for voz: String in pot:
		pot[voz] = float(pot[voz]) / maxf(tot, 0.0000001)
	return pot


func _medir_las_zonas() -> void:
	print("── ¿SUENA DISTINTO CADA LUGAR? (0% = idénticos, 100% = nada en común)")
	print("  Compara el REPARTO entre voces, no el volumen: dos lugares con el")
	print("  mismo reparto suenan igual aunque uno esté más fuerte.")
	var lugares := ["aldea", "fragua", "bosque", "ruina", "camino", "campo"]
	var cab := "  %-9s %8s %8s %8s %8s %8s %8s"
	print(cab % ([""] + lugares))
	for a: String in lugares:
		var fila: Array = [a]
		for b: String in lugares:
			fila.append("—" if a == b else "%.0f%%" % _diferencia(a, b, 0.50))
		print(cab % fila)
	print("  (al mediodía; las dos voces que más pesan en cada lugar:)")
	for a: String in lugares:
		var rep := _reparto(_tabla[a]["pos"] if _tabla.has(a) else PUNTO_CAMPO, 0.50)
		var claves := rep.keys()
		claves.sort_custom(func(x, y): return float(rep[x]) > float(rep[y]))
		print("    %-9s %-8s %2.0f%%   %-8s %2.0f%%"
			% [a, claves[0], 100.0 * float(rep[claves[0]]),
				claves[1], 100.0 * float(rep[claves[1]])])
	print("")


## ¿El viento suena DISTINTO en cada lugar, o sólo más fuerte?
##
## Es la única afirmación del diseño que no estaba respaldada por ningún
## número. El viento sale del mismo bucle en todos lados —lo que lo cambia es
## el filtro de su bus, que se abre o se cierra según lo abierto que esté el
## lugar—, así que medir el bucle crudo no dice nada: hay que medirlo DESPUÉS
## del filtro, que es lo que llega al oído. Bajo las copas del Sotobosque el
## corte queda en 320 Hz y en el Camino del Norte en 2300: si eso no mueve el
## reparto por banda, el `brillo` es decorativo y hay que sacarlo.
func _medir_el_timbre() -> void:
	print("── ¿EL VIENTO SUENA DISTINTO EN CADA LUGAR? (mismo bucle, otro filtro)")
	var m: PackedFloat32Array = _muestras(_bufs["viento"])
	var cab := "  %-9s %8s   %s"
	print(cab % ["lugar", "corte", "reparto por banda (%)"])
	for slug: String in ["bosque", "aldea", "fragua", "ruina", "campo", "camino"]:
		var brillo := float((LECHOS[slug] as Dictionary)["brillo"])
		var hz := lerpf(240.0, 2600.0, clampf(brillo, 0.0, 1.0))
		var fil := _pasabajos_off(m, hz)
		var partes: Array[float] = []
		var suma := 0.0
		for b: Array in BANDAS:
			var e := _banda(fil, float(b[1]), float(b[2]))
			partes.append(e * e)
			suma += e * e
		var texto := ""
		for i in BANDAS.size():
			texto += "%s %2.0f  " % [(BANDAS[i] as Array)[0], 100.0 * partes[i] / maxf(suma, 1e-7)]
		print(cab % [slug, "%.0f Hz" % hz, texto])
	print("")


## Pasabajos de dos polos, para medir fuera del motor lo que el bus le hace al
## viento. Mismos 12 dB por octava que `AudioEffectLowPassFilter`.
static func _pasabajos_off(m: PackedFloat32Array, hz: float) -> PackedFloat32Array:
	var w0 := TAU * hz / float(HZ)
	var alfa := sin(w0) / (2.0 * 0.707)
	var cw := cos(w0)
	var a0 := 1.0 + alfa
	var b0 := (1.0 - cw) / 2.0 / a0
	var b1 := (1.0 - cw) / a0
	var a1 := -2.0 * cw / a0
	var a2 := (1.0 - alfa) / a0
	var o := PackedFloat32Array()
	o.resize(m.size())
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in m.size():
		var x := m[i]
		var y := b0 * x + b1 * x1 + b0 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		o[i] = y
	return o


## ── EL PRESUPUESTO DE LA GENTE ───────────────────────────────────────────
##
## "El sonido molesta mucho" es un número —eventos por minuto— y no un
## adjetivo. Lo que sigue lo mide corriendo LA MÁQUINA DE VERDAD, no una copia:
## se para el oyente en un punto, se le dan pasos de 1/30 s y se cuenta qué
## disparó `_trabajar()` y `_murmurar()`. Si mañana alguien le cambia una pausa
## a un oficio, este número se mueve solo.
##
## Ojo con lo que se está midiendo, que es donde estas sondas mienten: acá el
## oyente está QUIETO. Los números son "cuánto suena si me quedo parado ahí",
## que es el peor caso para la fatiga y por eso es el que interesa.

## Corre la máquina real `segundos` segundos con el oyente parado en `oido`.
## Devuelve {familia: veces} más `_silencio` (el hueco más largo, en segundos).
func _gastar(oido: Vector3, segundos: float) -> Dictionary:
	var guarda := {
		"ritmo": _ritmo.duplicate(true), "freno": _freno_gente,
		"murmullo": _prox_murmullo, "cuenta": _cuenta.duplicate(),
		"reloj": _reloj, "ultimo": _ultimo_evento, "silencio": _silencio_max,
	}
	_ritmo = {}
	_freno_gente = 0.0
	_prox_murmullo = randf_range(2.0, 5.0)
	_cuenta = {}
	_reloj = 0.0
	_ultimo_evento = 0.0
	_silencio_max = 0.0
	_midiendo = true
	var dt := 1.0 / 30.0
	var pasos := int(segundos / dt)
	for _i in pasos:
		_reloj += dt
		_trabajar(dt, oido)
		_murmurar(dt, oido)
	# El silencio final cuenta: si no sonó nada en el último medio minuto, ese
	# medio minuto es silencio y tiene que aparecer.
	_midiendo = false
	_silencio_max = maxf(_silencio_max, _reloj - _ultimo_evento)
	var salida := _cuenta.duplicate()
	salida["_silencio"] = _silencio_max
	_ritmo = guarda["ritmo"]
	_freno_gente = float(guarda["freno"])
	_prox_murmullo = float(guarda["murmullo"])
	_cuenta = guarda["cuenta"]
	_reloj = float(guarda["reloj"])
	_ultimo_evento = float(guarda["ultimo"])
	_silencio_max = float(guarda["silencio"])
	return salida


func _medir_el_gasto() -> void:
	print("── CUÁNTO SUENA LA GENTE (eventos/min, parado 8 min en cada sitio, semilla fija)")
	print("  El techo declarado del archivo son %.0f eventos/min. Arriba de eso" % TECHO_POR_MINUTO)
	print("  alguien se pasó de presupuesto, y ahí es donde se vuelve a")
	print("  \"el sonido molesta mucho\".")
	var familias: Array[String] = ["yunque", "muela", "caldero", "hacha", "cota", "murmullo"]
	var cab := "  %-9s %7s %7s %7s %7s %7s %9s | %7s %9s"
	print(cab % (["dónde"] + familias + ["TOTAL", "silencio"]))
	# SEMILLA FIJA. Las pausas son aleatorias, así que sin esto la tabla se
	# mueve tres o cuatro eventos por minuto entre corridas y no se puede
	# comparar un cambio chico con el de ayer. Ocho minutos por sitio y semilla
	# clavada: el mismo código da el mismo número siempre.
	seed(20260818)
	var minutos := 8.0
	var sitios: Array = [
		["aldea", _tabla["aldea"]["pos"]], ["fragua", _tabla["fragua"]["pos"]],
		["bosque", _tabla["bosque"]["pos"]], ["ruina", _tabla["ruina"]["pos"]],
		["camino", _tabla["camino"]["pos"]], ["campo", PUNTO_CAMPO],
	]
	var peor := 0.0
	for s: Array in sitios:
		var c := _gastar(s[1], minutos * 60.0)
		var fila: Array = [s[0]]
		var total := 0.0
		for f: String in familias:
			var v := float(int(c.get(f, 0))) / minutos
			total += v
			fila.append("%.1f" % v if v > 0.0 else "—")
		fila.append("%.1f" % total)
		fila.append("%.0f s" % float(c["_silencio"]))
		peor = maxf(peor, total)
		print(cab % fila)
	print("  peor caso: %.1f eventos/min · techo %.0f · %s"
		% [peor, TECHO_POR_MINUTO, "OK" if peor <= TECHO_POR_MINUTO else "SE PASÓ"])
	print("")
	_medir_el_antes()

	# La prueba que importa de verdad: con la gente dormida no suena NADA. Y no
	# porque haya una curva que apague a la noche, sino porque el servidor los
	# manda durmiendo. Si esto alguna vez da distinto de cero, el ambiente está
	# afirmando que hay alguien trabajando donde no lo hay.
	var copia: Array[Dictionary] = []
	for d in _gente:
		copia.append(d.duplicate())
	for d in _gente:
		d["despierta"] = false
		d["trabajando"] = false
	var noche := _gastar(_tabla["aldea"]["pos"], 240.0)
	var suma := 0
	for k: String in noche:
		if k != "_silencio":
			suma += int(noche[k])
	print("  CON TODOS DURMIENDO (lo que manda el servidor de noche): %d eventos en 4 min · %s"
		% [suma, "OK" if suma == 0 else "MAL: el sonido está inventando gente"])
	# Y sin nadie en la lista —el servidor no llegó todavía— tampoco suena.
	_gente = []
	var vacio := _gastar(_tabla["fragua"]["pos"], 240.0)
	var suma2 := 0
	for k: String in vacio:
		if k != "_silencio":
			suma2 += int(vacio[k])
	print("  SIN LISTA DE GENTE (el cliente perdió al servidor): %d eventos en 4 min · %s"
		% [suma2, "OK: calla" if suma2 == 0 else "MAL: sigue sonando de memoria"])
	_gente = copia
	print("")


## ANTES Y DESPUÉS, y el "antes" MEDIDO en vez de recordado.
##
## "El sonido molesta mucho" es la queja que abre este trabajo, así que hay que
## poder poner el número viejo al lado del nuevo. El martillo de antes del 18 de
## agosto era este bucle exacto, copiado de la versión anterior de
## `_martillar()`: colgaba de `CURVA_YUNQUE` y de nada más, y el reloj de la
## racha corría MÁS RÁPIDO cuanto más alta estaba la curva
## (`dt * (0.55 + intensidad)`), o sea que al mediodía iba a 1,55×.
##
## El resultado es incómodo y por eso conviene tenerlo escrito: **el martillo
## solo, al mediodía, valía más eventos por minuto que las seis voces de hoy
## juntas** — y los valía en un radio de 260 metros, con Ilde durmiendo, muerta
## o en el Sotobosque, porque no dependía de Ilde.
func _gastar_como_antes(f: float) -> float:
	var intensidad := curva(CURVA_YUNQUE, f)
	if intensidad < 0.05:
		return 0.0
	var dt := 1.0 / 30.0
	var prox := 2.0
	var seguidos := 0
	var golpes := 0
	var segundos := 240.0
	for _i in int(segundos / dt):
		prox -= dt * (0.55 + intensidad)
		if prox > 0.0:
			continue
		golpes += 1
		seguidos += 1
		if seguidos >= randi_range(3, 6):
			seguidos = 0
			prox = randf_range(4.5, 11.0)
		else:
			prox = randf_range(0.42, 0.58)
	return float(golpes) / (segundos / 60.0)


func _medir_el_antes() -> void:
	print("── ANTES Y DESPUÉS (martillazos por minuto del yunque viejo)")
	print("  El de antes NO dependía de ninguna persona: sonaba por la hora, en")
	print("  260 m a la redonda, con Ilde despierta, dormida, lejos o muerta.")
	var cab := "  %-13s %7s %7s %7s %7s %7s %7s %7s"
	var fila: Array = ["antes (hora)"]
	var fila2: Array = ["ahora (Ilde)"]
	for f: float in HORAS_DE_PRUEBA:
		fila.append("%.0f" % _gastar_como_antes(f))
	print(cab % (["hora"] + HORAS_DE_PRUEBA.map(func(x): return "%.2f" % x)))
	print(cab % fila)
	# El de ahora no depende de la hora sino de si Ilde está despierta, así que
	# la fila tiene dos valores y no siete: trabajando, y no trabajando.
	var c := _gastar(_tabla["fragua"]["pos"], 240.0)
	var con := float(int(c.get("yunque", 0))) / 4.0
	for _i in HORAS_DE_PRUEBA.size():
		fila2.append("%.0f" % con)
	print(cab % fila2)
	print("  La fila de abajo es plana a propósito: **la hora ya no decide.**")
	print("  Decide el servidor, y cuando Ilde duerme esa fila es un cero — que")
	print("  es la línea `CON TODOS DURMIENDO` de la tabla de arriba.")
	print("")


## El registro segundo a segundo. Es lo que pidió la dirección para poder
## comparar antes y después: qué familia sonó, cuántas veces, y cuánto
## silencio hubo entre medio.
func _registro_por_segundo(oido: Vector3, segundos: int, donde: String) -> void:
	print("── EL REGISTRO, SEGUNDO A SEGUNDO (parado en %s, %d s)" % [donde, segundos])
	print("  Un renglón por cada segundo en que sonó algo. Los que faltan son")
	print("  segundos en que no sonó NADIE, y se cuentan en la última columna:")
	print("  son la mayoría, y eso es a propósito — el silencio es material.")
	var guarda_ritmo := _ritmo.duplicate(true)
	var guarda_freno := _freno_gente
	var guarda_murm := _prox_murmullo
	var guarda_cuenta := _cuenta.duplicate()
	_ritmo = {}
	_freno_gente = 0.0
	_prox_murmullo = randf_range(2.0, 5.0)
	_midiendo = true
	var dt := 1.0 / 30.0
	var mudos := 0
	var ultimo := -1
	var hueco := 0
	for s in segundos:
		_cuenta = {}
		for _i in 30:
			_trabajar(dt, oido)
			_murmurar(dt, oido)
		if _cuenta.is_empty():
			mudos += 1
			continue
		var texto := ""
		for f: String in _cuenta:
			texto += "%s×%d  " % [f, int(_cuenta[f])]
		hueco = s - ultimo - 1
		ultimo = s
		print("  seg %3d   %-34s (venía de %d s de silencio)" % [s, texto, hueco])
	print("  %d de %d segundos sin un solo sonido de gente (%.0f%%)."
		% [mudos, segundos, 100.0 * float(mudos) / float(segundos)])
	_midiendo = false
	_ritmo = guarda_ritmo
	_freno_gente = guarda_freno
	_prox_murmullo = guarda_murm
	_cuenta = guarda_cuenta
	print("")


## ¿La Puerta del Norte suena a Puerta? Lo único que se puede medir sin oír es
## la rampa: cuánto del lecho vuelve de la piedra a cada distancia, y que en el
## resto del valle sea exactamente cero.
func _medir_la_puerta() -> void:
	print("── EL ECO DE LA PUERTA DEL NORTE (cuánto del lecho vuelve de la piedra)")
	if _reverb == null:
		print("  no hay reverb montado · MAL")
		print("")
		return
	var cab := "  %-22s %9s %8s"
	print(cab % ["desde dónde", "distancia", "eco"])
	var puntos: Array = [
		["el vano de la Puerta", PUERTA],
		["el mojón del camino", Vector3(11, 0, 146)],
		["El Camino del Norte", _tabla["camino"]["pos"]],
		["Vado Bajo", _tabla["aldea"]["pos"]],
		["La Fragua de Ilde", _tabla["fragua"]["pos"]],
		["El Sotobosque", _tabla["bosque"]["pos"]],
	]
	for p: Array in puntos:
		_resonar_la_puerta(p[1])
		var d := Vector2((p[1] as Vector3).x, (p[1] as Vector3).z) \
			.distance_to(Vector2(PUERTA.x, PUERTA.z))
		print(cab % [p[0], "%.0f m" % d, "%.0f%%" % (_reverb.wet * 100.0)])
	_resonar_la_puerta(_tabla["aldea"]["pos"])
	print("  El eco es del LUGAR y no de una fuente: no hay nada ahí haciendo")
	print("  ruido. Lo que cambia es cómo vuelve lo que ya sonaba.")
	print("")


## Quién hay, de dónde salió la lista, y quién de ésos suena.
func _medir_a_la_gente() -> void:
	print("── LA GENTE DEL VALLE (fuente: %s)" % _origen_gente)
	if _gente.is_empty():
		print("  NADIE. Ninguna voz de trabajo va a sonar, y está bien: el modo")
		print("  de falla de este cableado es el silencio, nunca la mentira.")
		print("")
		return
	var cab := "  %-14s %-10s %-9s %-11s %s"
	print(cab % ["quién", "familia", "dónde", "despierta", "¿suena su oficio?"])
	for d in _gente:
		var f := str(d["familia"])
		var por_que := "sí"
		if f == "":
			por_que = "no — su oficio no tiene un gesto que se oiga"
		elif not bool(d["despierta"]):
			por_que = "no — está durmiendo (lo dice el servidor)"
		elif not bool(d["trabajando"]):
			por_que = "no — está fuera de su lugar"
		print(cab % [d["nombre"], f if f != "" else "—", d["slug"],
			"sí" if bool(d["despierta"]) else "no", por_que])
	print("")


## El gasto de reproductores. Es la trampa que este repo ya pisó, así que se
## mide en vez de suponerse: se le mete al módulo una lista de cuarenta
## personas y se comprueba que la cuenta de emisores no se mueva.
func _medir_los_reproductores() -> void:
	var antes := 0
	for voz: String in _jug:
		antes += (_jug[voz] as Array).size()
	var copia: Array[Dictionary] = []
	for d in _gente:
		copia.append(d.duplicate())
	var oficios := ["herrera", "aprendiz", "destiladora", "cazadora", "guardia"]
	_gente = []
	for i in 40:
		_gente.append({
			"nombre": "Relleno%d" % i, "familia": familia_de(str(oficios[i % 5])),
			"despierta": true, "trabajando": true, "slug": "aldea",
			"pos": _tabla["aldea"]["pos"] + Vector3(float(i % 7), 1.1, float(i / 7)),
			"tono": 1.0,
		})
	var c := _gastar(_tabla["aldea"]["pos"], 120.0)
	var despues := 0
	for voz: String in _jug:
		despues += (_jug[voz] as Array).size()
	var total := 0
	for k: String in c:
		if k != "_silencio":
			total += int(c[k])
	print("── EL GASTO DE REPRODUCTORES")
	print("  Con 7 personas: %d emisores. Con 40: %d. · %s"
		% [antes, despues, "OK: no crece" if antes == despues else "MAL: crece con la población"])
	print("  Y con 40 personas apretadas en la aldea el gasto sube a %.1f"
		% (float(total) / 2.0))
	print("  eventos/min y no a 40 veces más, porque suena UNO por familia:")
	print("  el que trabaja más cerca. El freno común de %.2f s hace el resto."
		% GENTE_FRENO)
	print("  Ese número SÍ pasa el techo de %.0f, y queda dicho en vez de"
		% TECHO_POR_MINUTO)
	print("  escondido: el techo está puesto para el peor caso REAL —una región")
	print("  son de 8 a 20 personas (DISENO §7.1) y no todas del mismo oficio—")
	print("  y con cuarenta encima el raleo por distancia deja de aplicar porque")
	print("  todos están al lado. Si algún día una región junta cuarenta, lo que")
	print("  hay que tocar es el freno común, no las pausas.")
	_gente = copia
	print("")


## Cuántos bucles distintos están SONANDO. No es lo mismo que la cantidad de
## emisores —el viento son dos emisores con el mismo bucle— y cuentan sólo los
## que suenan, porque un bucle asignado y quieto no queda colgado al salir.
func _bucles_distintos() -> int:
	var vistos := {}
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			if not bool(p.call("is_playing")):
				continue
			var st: Object = p.get("stream")
			if st != null:
				vistos[st.get_instance_id()] = true
	return vistos.size()


## Cuántos emisores están sonando ahora mismo.
func _sonando() -> int:
	var n := 0
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			if is_instance_valid(p) and bool(p.call("is_playing")):
				n += 1
	return n


## Que la cadena esté entera: cada emisor con su bus vivo y su bucle con
## muestras adentro.
##
## Esto reemplaza lo único que se perdió al no reproducir en headless. Un
## `play()` contra el driver Dummy no probaba nada más que "no tiró": no había
## forma de saber si el bus existía, si el stream tenía datos o si el bucle
## estaba bien cerrado. Revisarlo a mano prueba más y no deja nada sonando.
func _revisar_la_cadena() -> void:
	var emisores := 0
	var fallas: Array[String] = []
	var muestras := 0
	for voz: String in _jug:
		for p: Node in _jug[voz]:
			emisores += 1
			var bus := String(p.get("bus"))
			if AudioServer.get_bus_index(bus) == -1:
				fallas.append("%s: el bus %s no existe" % [voz, bus])
			var s := p.get("stream") as AudioStreamWAV
			if s == null:
				fallas.append("%s: sin bucle" % voz)
				continue
			if s.data.size() < 2:
				fallas.append("%s: bucle vacío" % voz)
				continue
			muestras += s.data.size() / 2
			var deberia_repetir := not VOCES_SUELTAS.has(voz)
			if deberia_repetir and s.loop_mode != AudioStreamWAV.LOOP_FORWARD:
				fallas.append("%s: es un lecho y no está en bucle" % voz)
	print("Cadena: %d emisores, %d buses, %d muestras (%.1f s de audio, %.1f MB en RAM) · %s"
		% [emisores, _buses.size(), muestras, float(muestras) / float(HZ),
			float(muestras * 2) / 1048576.0,
			"OK" if fallas.is_empty() else "MAL: " + ", ".join(fallas)])
	if _hay_salida:
		var forzado := OS.get_cmdline_user_args().has(FORZAR_AUDIO)
		print("Salida de audio: %s%s. Los emisores están sonando: %d."
			% [AudioServer.get_driver_name(),
				" (FORZADA por " + FORZAR_AUDIO + ")" if forzado else "",
				_sonando()])
		if forzado:
			# Sin nombrar las palabras que grepea la verificación del repo.
			print("  Con audio forzado el proceso cierra avisando de instancias")
			print("  sin liberar, y tiene que hacerlo: una por emisor sonando más")
			print("  una por bucle distinto (%d + %d = %d), y las suelta el motor,"
				% [_sonando(), _bucles_distintos(), _sonando() + _bucles_distintos()])
			print("  no este módulo. Lo que se vigila es que ese número no crezca.")
	else:
		# Ojo con el texto de acá: la verificación del repo se hace con grep
		# sobre esta salida, así que no se nombran las palabras que se buscan.
		print("Salida de audio: ninguna (driver %s). No se reproduce nada y se"
			% AudioServer.get_driver_name())
		print("  calcula todo igual. Además de ahorrar trabajo, es lo que evita")
		print("  que el proceso cierre avisando de instancias sin liberar: el")
		print("  motor necesita dos cuadros después del stop() y al salir ya no")
		print("  quedan. Está medido y pasa con un AudioStreamPlayer pelado")
		print("  también — el detalle está en el comentario de `_hay_salida`.")


## Después de la tabla, la caminata: mueve el oyente por los cinco lugares
## mientras el día avanza, y hace sonar todo de verdad. En headless no se oye
## nada — sirve para probar que la cadena entera (buses, emisores, mezcla) no
## revienta. Con parlantes, esto es lo que hay que escuchar.
func _informe_de_paso() -> void:
	var pasos_por_tramo := 5
	var total := (RUTA.size() - 1) * pasos_por_tramo
	if _paso == 0:
		print("── LA CAMINATA (%d pasos; el día entero mientras tanto)" % total)
		print("  Ruta: %s. Son rectas, así que pasa por campo abierto y roza"
			% " → ".join(RUTA))
		print("  lugares que no son destino — el cruce de la mezcla es el punto.")
		print("  %-7s %-13s %-13s %6s %6s  %s"
			% ["paso", "dónde estoy", "cuándo", "FONDO", "viento", "mezcla de lugares"])
	if _paso >= total:
		if DisplayServer.get_name() == "headless":
			print("")
			print("Listo. Nada de esto se oyó: bajo WSL no hay salida de audio.")
			print("Corré esta misma escena con parlantes para juzgarlo.")
			_salir()
		else:
			_paso = 0   # con pantalla, en loop: es para escuchar
		return

	var tramo := mini(_paso / pasos_por_tramo, RUTA.size() - 2)
	var t := float(_paso % pasos_por_tramo) / float(pasos_por_tramo)
	var a: Vector3 = _tabla[RUTA[tramo]]["pos"]
	var b: Vector3 = _tabla[RUTA[tramo + 1]]["pos"]
	var p := a.lerp(b, t)
	if oyente != null:
		oyente.global_position = p
	hora_manual = fposmod(float(_paso) / float(total), 1.0)

	var g := lecho_en(p, hora_manual)
	var pesos: Dictionary = g["pesos"]
	var claves := pesos.keys()
	claves.sort_custom(func(x, y): return float(pesos[x]) > float(pesos[y]))
	var texto := ""
	for k: String in claves:
		if float(pesos[k]) > 0.02:
			texto += "%s %.0f%%  " % [k, float(pesos[k]) * 100.0]
	print("  %-7s %-13s %-13s %6.2f %6.2f  %s" % [
		str(_paso), str(claves[0]),
		franja(hora_manual), g["fondo"], g["viento"], texto])
	_paso += 1


func _physics_process(_dt: float) -> void:
	# La caminata avanza por CUADRO y no por reloj: en headless el reloj corre
	# a mil y no se imprimiría nada. Un paso cada seis cuadros de física.
	if not modo_prueba or not _listo:
		return
	if Engine.get_physics_frames() % 6 == 0:
		_informe_de_paso()


## Cerrar limpio. Apagar y darle unos cuadros al AudioServer para que suelte
## las reproducciones antes de salir; si no, Godot cierra con el aviso de
## instancias filtradas y la verificación deja de ser legible de un vistazo.
func _salir() -> void:
	apagar()
	for _i in 8:
		await get_tree().process_frame
	get_tree().quit()
