## La paleta del valle. **Acá se deciden los colores, y en ningún otro lado.**
##
## El diagnóstico que la trajo, dicho por quien juega: *"el mundo parece juegos
## de Playmobil"*. No había colores malos: había noventa y tres colores sacados
## de ocho tachos distintos. Cada script inventaba su marrón y su verde, y un
## mundo así no se lee como un lugar, se lee como piezas de plástico.
##
## Lo que hace que un mundo se vea diseñado no es tener buenos colores: es que
## todos salgan de la misma decisión.
##
## ===========================================================================
## LAS TRES REGLAS DE ESTE ARCHIVO
## ===========================================================================
##
## **1. EL VALOR ANTES QUE EL MATIZ.**
##
## La cámara está a 27 metros con FOV 42°. A esa distancia el matiz de dos
## cosas cuesta compararlo; lo que las separa es cuán claras u oscuras son. El
## piso de zoom (DISENO.md §6, decidido el 17 de agosto) confirma el
## presupuesto: **silueta, valor y color, nunca una expresión facial.**
##
## Por eso todo color de este archivo está clavado a un escalón de una escalera
## de valor de nueve peldaños, y el escalón está escrito al lado en el
## comentario (`v0.30` = peldaño V3). Si mañana agregás un color, elegí primero
## el escalón y recién después el matiz.
##
## **Y el peldaño del comentario es el peldaño de la pantalla.** No es una
## aspiración: está medido con un control renderizado, y hubo que arreglar el
## motor para que fuera cierto — ver "LOS DOS CAMINOS DEL COLOR" abajo, arriba
## de las fábricas. Si algún día un color de acá no rinde su número, empezá por
## ahí antes de tocar el número.
##
## **La escalera** (V de HSV, que es lo que se lee en blanco y negro):
##
## | # | nombre  | V    | quién vive ahí                                     |
## |---|---------|------|----------------------------------------------------|
## |V0 | tinta   | 0.06 | ojos, contornos. Agujeros, no cosas.               |
## |V1 | carbón  | 0.13 | puertas, cinturones, pelo negro. Lo que es hueco.  |
## |V2 | turba   | 0.21 | techos, troncos, copas, agua, base de la montaña   |
## |V3 | corteza | 0.30 | **el pasto húmedo**, la ruina, el cuero, el bicho  |
## |V4 | arcilla | 0.41 | **la tierra** — y el promedio del suelo del valle  |
## |V5 | lino    | 0.53 | pasto seco, losas del camino, muros de la fragua   |
## |V6 | trigo   | 0.66 | **los muros de la aldea**, roca, lino, canas       |
## |V7 | ceniza  | 0.78 | la piel, el jade del jugador, casi toda la UI      |
## |V8 | cal     | 0.90 | el texto de la interfaz. Nada del mundo llega acá. |
##
## **La composición que sale de la escalera**, y es la razón de que exista:
##
##   · El suelo del valle promedia **V4**. Es el lienzo; todo se mide contra él.
##   · Lo construido está **arriba**: aldea V6, fragua V5. Un pueblo se ve
##     porque es una mancha clara.
##   · Lo vegetal y los techos están **abajo**: copas V2, techos V2. Un bosque
##     se ve porque es una mancha oscura, y una casa se ve porque es una caja
##     clara con una tapa oscura. Eso es todo lo que hace legible una aldea a
##     27 metros — no el detalle del techo.
##   · **La Casa Quemada está en V3, por debajo del suelo.** Se hunde. Es lo
##     único construido que no levanta la vista, y eso lo cuenta el valor solo,
##     sin un cartel.
##   · **El río está en V2.** Un río se lee porque es oscuro, no porque es
##     azul. Una cinta oscura cruzando un valle V4 es la línea más fuerte del
##     encuadre.
##   · **La piedra es lo más claro del paisaje** (V6). Roca en las pendientes y
##     piedras sueltas en el pasto son la puntuación clara del cuadro.
##   · **La cabeza es el ancla de valor de una persona.** La ropa se reparte
##     por toda la escalera (figura.gd la deriva de `color.v`) y a veces cae en
##     V4, o sea igual que el suelo, y el cuerpo desaparece. Lo que nunca
##     desaparece es la cabeza: pelo oscuro (V1–V3) sobre piel clara (V7) es un
##     par claro/oscuro permanente arriba de la silueta.
##
## **2. MENOS SATURACIÓN DE LA QUE TE PIDE EL CUERPO.**
##
## El plástico se ve plástico porque está saturado y parejo. La tierra, la lana
## teñida en casa y la madera vieja son **colores rotos**: tienen gris adentro.
##
## Techo de este archivo, y son dos porque no todo ocupa lo mismo en pantalla:
##
##   · **Superficies del mundo: S ≤ 0.35.** Terreno, muros, techos, follaje,
##     agua, montaña, camino. Todo lo que se mide en metros cuadrados. Casi
##     todas viven entre 0.05 y 0.30.
##   · **Tintes de gente: S ≤ 0.50.** Pelo, cuero, cinto. Son manchas de
##     centímetros y es donde vive la identidad de una persona; ahí un poco de
##     croma paga. Un valle donde el pelo castaño es gris no se cree.
##
## Y aparte, **tres excepciones nombradas** que están numeradas abajo, cada una
## con un trabajo. Si aparece una cuarta, es un error, no una decisión.
##
## Lo mismo por el lado de los materiales: la mitad del aspecto plástico no es
## el color, es que **todo tenga el mismo brillo especular**. Por eso el
## terreno, el follaje, los techos y la tela salen de fábrica con
## `SPECULAR_DISABLED`: no reflejan nada, como no reflejan nada en la vida.
## Brillan tres cosas: el cuero, el metal y el agua.
##
## **3. EL TONO ES FRIEREN.**
##
## Melancólico y liviano a la vez. Luz cálida y baja, historia vieja que pesa.
## **No sombrío y no saturado.** Se consigue así: el mundo entero es tierra
## apagada y verde oliva —nada grita— y toda la saturación del presupuesto se
## gasta en manchas chiquitas de luz cálida: la fragua, las ventanas, las
## luciérnagas. Un valle apagado con seis puntos naranjas es melancólico. Un
## valle saturado con seis puntos naranjas es una juguetería.
##
## ===========================================================================
## LAS TRES EXCEPCIONES A LA SATURACIÓN, Y PARA QUÉ SIRVE CADA UNA
## ===========================================================================
##
## 1. **El fuego** (`BRASA`, `VENTANA`, `LUCIERNAGA`, los faroles). S alto, V
##    alto, y siempre emisivo. Ocupan poquísimos píxeles y son lo único que
##    dice "acá adentro hay alguien". Es la excepción que hace el tono.
## 2. **El jade** (`JADE`, y su eco en la barra de vida y en el mapa). Frío y
##    saturado en un mundo cálido y apagado: es lo que hace que **vos** se te
##    encuentre de un vistazo. Es el único color frío saturado del juego y le
##    pertenece al jugador. No se lo prestes a nada más.
## 3. **La herrumbre** (`HERRUMBRE`, los ojos del bicho, la vida en rojo). El
##    peligro. Cálido como el fuego pero mucho más oscuro y más rojo, para que
##    no se confunda con una ventana encendida.
##
## ===========================================================================
## LA NOCHE
## ===========================================================================
##
## `ciclo.gd` cambia el color y la energía de la luz según la hora del
## servidor, y **esa es la fuente de verdad de la hora**. Este archivo no le
## pelea: le da los cuatro colores de la luz (`LUZ_ALBA`, `LUZ_MEDIODIA`,
## `LUZ_OCASO`, `LUZ_LUNAR`) y los dos de la niebla (`NIEBLA_DIA`,
## `NIEBLA_NOCHE`), que es exactamente lo que el ciclo interpola. También están
## acá las funciones `luz_solar()` y `niebla()` con la mezcla ya hecha, para
## que el día que se migre `ciclo.gd` no haya que volver a escribirla.
##
## Consecuencia de diseño que conviene tener presente al elegir un albedo: de
## noche la luz solar baja a 0.09 de energía y se vuelve azul. Todo lo que esté
## por debajo de V2 desaparece del todo. Por eso no hay superficies grandes en
## V0/V1: esos peldaños son para cosas chicas que TIENEN que leerse como
## agujeros.
class_name Paleta
extends RefCounted


# ---------------------------------------------------------------------------
# La escalera de valor, como números. Para derivar colores nuevos sin inventar.
# ---------------------------------------------------------------------------

const V0_TINTA := 0.06
const V1_CARBON := 0.13
const V2_TURBA := 0.21
const V3_CORTEZA := 0.30
const V4_ARCILLA := 0.41
const V5_LINO := 0.53
const V6_TRIGO := 0.66
const V7_CENIZA := 0.78
const V8_CAL := 0.90

## Techos de saturación. Las tres excepciones nombradas (fuego, jade,
## herrumbre) están documentadas arriba y son las únicas que los pasan.
const SATURACION_MUNDO := 0.35   ## terreno, muros, techos, follaje, agua, monte
const SATURACION_GENTE := 0.50   ## pelo, cuero, tintes de ropa


# ---------------------------------------------------------------------------
# LA LUZ. No son albedos: son colores de luz, así que viven arriba de la
# escalera (V cerca de 1). Los interpola ciclo.gd a lo largo del día.
# ---------------------------------------------------------------------------

const LUZ_ALBA := Color(1.000, 0.724, 0.540)        ## h24  s0.46
const LUZ_MEDIODIA := Color(1.000, 0.963, 0.900)    ## h38  s0.10 — casi blanca, apenas cálida
const LUZ_OCASO := Color(1.000, 0.594, 0.420)       ## h18  s0.58 — la más saturada del día
const LUZ_LUNAR := Color(0.552, 0.687, 0.920)       ## h218 s0.40 — la noche viene de otro lado y es fría
const LUZ_CIELO := Color(0.581, 0.710, 0.880)       ## h214 s0.34 — el relleno: cielo rebotando en las sombras
const LUZ_FRAGUA := Color(1.000, 0.493, 0.200)      ## h22  s0.80 — excepción 1: el fuego
const LUZ_FAROL := Color(1.000, 0.739, 0.440)       ## h32  s0.56 — excepción 1: el fuego, domesticado

## La luz de rebote: el suelo devolviéndole al mundo lo que el sol le pegó.
## No es una luz de este archivo por prolijidad, es por lo mismo que todo lo
## demás. `ambiente.gd` saca el 55% del ambiente de acá y el 45% del cielo, y
## esa mezcla es lo que decide de qué color son las sombras del valle entero —
## o sea la mitad de la pantalla en cualquier hora que no sea mediodía. Un
## número tan grande no puede vivir suelto en otro archivo.
const LUZ_REBOTE := Color(0.420, 0.380, 0.310)      ## h33 s0.26 v0.42

# ---------------------------------------------------------------------------
# EL CIELO. Vivían adentro del shader de `cielo.gd` como literales, que es la
# misma deuda que tenían los noventa y tres colores de los que salió este
# archivo, sólo que en GLSL.
#
# Y no son un caso menor por estar arriba: `ambiente.gd` pone
# `ambient_light_source = SKY` con contribución 0,45, así que **el cenit y el
# horizonte SON el 45% de la luz de las sombras de todo el valle.** El color
# de acá no pinta un fondo: pinta el lado en sombra de cada casa.
# ---------------------------------------------------------------------------

## El cenit de día. **Le bajó la saturación de 0,78 a 0,62, y es una decisión.**
## 0,78 es azul de afiche: el color más saturado que había en todo el juego,
## por encima de la fragua y del jade, en la superficie más grande que existe.
## La regla 2 de este archivo tiene tres excepciones nombradas y el cielo no era
## ninguna — era un descuido, porque estaba escrito en otro idioma y en otro
## archivo. Sigue siendo cielo y sigue siendo azul; deja de gritar.
const CIELO_CENIT_DIA := Color(0.274, 0.437, 0.720)     ## h219 s0.62 v0.72
## El horizonte de día. Comparte matiz con `NIEBLA_DIA` (h207 contra h204) y eso
## **no es coincidencia y no se puede romper**: la perspectiva aérea funciona
## porque lo lejano se va al color del aire, y el aire tiene que ser del color
## que se ve detrás. Si un día se mueve uno, se mueve el otro.
const CIELO_HORIZ_DIA := Color(0.660, 0.780, 0.880)     ## h207 s0.25 v0.88
const CIELO_CENIT_NOCHE := Color(0.010, 0.020, 0.055)   ## h233 s0.82 v0.06
const CIELO_HORIZ_NOCHE := Color(0.045, 0.065, 0.125)   ## h225 s0.64 v0.13
## El incendio del ocaso, y es la excepción 1 arriba de todo: es fuego, aunque
## sea fuego a cien kilómetros. Más saturado que `LUZ_OCASO` (0,84 contra 0,58)
## a propósito — el cielo es la brasa y la luz que llega es lo que queda de ella.
const CIELO_OCASO := Color(1.000, 0.420, 0.160)         ## h16 s0.84 v1.00

const NIEBLA_DIA := Color(0.521, 0.580, 0.620)      ## h204 s0.16 v0.62
const NIEBLA_NOCHE := Color(0.090, 0.119, 0.200)    ## h224 s0.55 v0.20
const NIEBLA_VOL := Color(0.780, 0.725, 0.663)      ## h32  s0.15 v0.78 — la niebla volumétrica es cálida
const NIEBLA_VOL_EMISION := Color(0.052, 0.060, 0.080)  ## h222 s0.35 v0.08


# ---------------------------------------------------------------------------
# EL TERRENO. Cuatro colores, cuatro peldaños seguidos: V3 pasto, V4 tierra,
# V5 pasto seco, V6 roca.
#
# Antes los cuatro estaban entre V0.72 y V0.86 — o sea, el mismo peldaño. En
# blanco y negro el suelo entero era una sola papilla y toda la diferencia
# estaba en el matiz, que a 27 metros no existe. Ése era el bug, y era el
# 40% de la pantalla.
# ---------------------------------------------------------------------------

## Tinte del material de terreno. Va casi blanco A PROPÓSITO: el color real
## son los colores de vértice, y el albedo los MULTIPLICA. El tinte anterior
## (0.42, 0.46, 0.30) los bajaba a un tercio y les metía verde encima, así que
## la escalera que decía el código no era la que se veía.
## (Único color del archivo fuera de la escalera, y a propósito: no es un
## color, es un multiplicador que tiene que dejar pasar el de los vértices.)
const TERRENO_TINTE := Color(1.000, 0.984, 0.960)

const PASTO := Color(0.246, 0.300, 0.198)           ## h92  s0.34 v0.30 (V3) — oliva, no esmeralda
const TIERRA := Color(0.410, 0.336, 0.279)          ## h26  s0.32 v0.41 (V4)
## **El lienzo del valle, y no lo parece hasta que se mide.** `_color_terreno()`
## en `valle.gd` interpola PASTO→PASTO_SECO con `t = (y + 4,5) / 6,5`, y el piso
## del valle vive entre y = −2,4 y y = +2,4: o sea t entre 0,32 y 1,0, con la
## mayor parte arriba de 0,7. **El verde nunca aparece: el valle entero se pinta
## con este color.** Medido sobre una captura, el suelo abierto da h41–h44 s0,27
## — `PASTO_SECO` clavado, en el 45% de la pantalla.
##
## Estaba en h44, que es arena de playa, y con eso el valle se leía como un
## desierto pálido. Va a h64: paja seca con verde adentro, que es lo que hay
## en un prado de fin de verano. **Mismo peldaño (V5) y misma saturación de
## techo**, o sea que no se toca ni la escalera ni la composición: sólo el
## matiz, que es lo único que quedaba libre.
##
## El arreglo de verdad es de `valle.gd` y está pedido en el informe: el mapeo
## de altura tiene que dejar que el pasto V3 aparezca en el fondo del valle.
## Hasta que eso pase, este matiz es lo que impide que el lienzo sea arena.
const PASTO_SECO := Color(0.519, 0.530, 0.360)      ## h64  s0.32 v0.53 (V5)
const ROCA := Color(0.660, 0.642, 0.620)            ## h32  s0.06 v0.66 (V6) — lo más claro del paisaje

## Las matas del pasto en MultiMesh. Van uno o dos peldaños POR DEBAJO del
## suelo (V2–V4 contra V4): así se leen como textura y sombra, no como una
## pelusa brillante encima del terreno.
const PASTO_MATA_OSCURA := Color(0.167, 0.210, 0.139)   ## h96 s0.34 v0.21 (V2)
const PASTO_MATA_CLARA := Color(0.396, 0.410, 0.271)    ## h66 s0.34 v0.41 (V4)

const PIEDRA_SUELTA := Color(0.660, 0.646, 0.627)   ## h34 s0.05 v0.66 (V6) — puntuación clara

## La cordillera. Del bosque oscuro de la base a la roca pelada de arriba, y
## todo lerpeado 0.45 hacia MONTE_AIRE: la distancia lava el color y lo enfría.
const MONTE_BAJO := Color(0.164, 0.195, 0.210)      ## h200 s0.22 v0.21 (V2)
const MONTE_ALTO := Color(0.568, 0.608, 0.660)      ## h214 s0.14 v0.66 (V6)
const MONTE_AIRE := Color(0.350, 0.428, 0.530)      ## h214 s0.34 v0.53 (V5)

## El río. V2: oscuro contra un suelo V4. Se lee por el valor, no por el azul.
const AGUA := Color(0.139, 0.191, 0.210, 0.86)      ## h196 s0.34 v0.21 (V2)
const AGUA_EMISION := Color(0.086, 0.118, 0.130)    ## h196 s0.34 v0.13 (V1)


# ---------------------------------------------------------------------------
# LO CONSTRUIDO. La escalera de lo que levantó gente:
#   ruina V3  <  fragua V5  <  aldea V6      (contra un suelo V4)
# y todas las tapas —techos, troncos, puertas— abajo de todo, en V1–V2.
# Caja clara + tapa oscura = casa. Es lo único que se lee de una casa a 27 m.
# ---------------------------------------------------------------------------

const MURO_ALDEA := Color(0.660, 0.607, 0.528)      ## h36  s0.20 v0.66 (V6) — revoque de tierra, blanqueado por el sol
const MURO_FRAGUA := Color(0.530, 0.436, 0.382)     ## h22  s0.28 v0.53 (V5) — madera ahumada
const MURO_RUINA := Color(0.279, 0.289, 0.300)      ## h210 s0.07 v0.30 (V3) — piedra quemada, y es el único muro FRÍO
const LOSA_CAMINO := Color(0.530, 0.509, 0.482)     ## h34  s0.09 v0.53 (V5) — un peldaño arriba del suelo: se ve la línea, no grita

const TECHO := Color(0.210, 0.166, 0.147)           ## h18 s0.30 v0.21 (V2)
## El segundo techo. Mismo peldaño que `TECHO` —V2, la tapa oscura— y frío en
## vez de cálido, que es toda la diferencia que puede haber entre dos techos sin
## romper la lectura de "caja clara, tapa oscura". Existe porque el kit trae dos
## familias de techo y colapsarlas en una sola dejaba siete casas idénticas: la
## variedad se paga en MATIZ, nunca en valor.
const TECHO_PIZARRA := Color(0.164, 0.195, 0.210)   ## h200 s0.22 v0.21 (V2)
const MADERA := Color(0.130, 0.103, 0.086)          ## h24 s0.34 v0.13 (V1) — una puerta tiene que leerse como un agujero
const LADRILLO := Color(0.300, 0.241, 0.216)        ## h18 s0.28 v0.30 (V3)
const TRONCO := Color(0.210, 0.172, 0.147)          ## h24 s0.30 v0.21 (V2)
const COPA := Color(0.172, 0.210, 0.147)            ## h96 s0.30 v0.21 (V2) — el Sotobosque es UNA mancha oscura

## El árbol suelto, que NO es el Sotobosque. Dos peldaños arriba de `COPA`.
##
## `COPA` se eligió para una cosa concreta: la mancha oscura del bosque, hecha
## con conos, mirada como un bloque. Puesta en cada árbol del valle —y con el
## kit hay 1.600— deja siluetas negras, y eso se vio en pantalla antes de que
## esto existiera. La copa suelta necesita valor propio: **V4**, o sea el mismo
## peldaño que el suelo, porque lo que separa un árbol del prado no es el valor
## sino la silueta y el matiz, y lo que separa al BOSQUE es que muchos V4 juntos
## con sombra propia leen como una mancha.
##
## Vivían como `COPA_VIVA` y `CORTEZA` adentro de `kit.gd`, con saturación 0,46
## y 0,43 y con el valor entre dos peldaños. Están acá y en la escalera por la
## regla de siempre: un color suelto en otro script es deuda, y el techo de
## saturación no tiene excepciones que no estén nombradas.
const COPA_CLARA := Color(0.324, 0.410, 0.267)      ## h96 s0.35 v0.41 (V4)
const TRONCO_CLARO := Color(0.300, 0.241, 0.195)    ## h26 s0.35 v0.30 (V3) — el tronco del árbol suelto


# ---------------------------------------------------------------------------
# EXCEPCIÓN 1 — EL FUEGO. Alta saturación, siempre emisivo, siempre chico.
# Es donde se gasta todo el presupuesto de color del juego.
# ---------------------------------------------------------------------------

const BRASA := Color(1.000, 0.413, 0.120)           ## h20 s0.88
const BRASA_EMISION := Color(1.000, 0.484, 0.140)   ## h24 s0.86
const VENTANA := Color(1.000, 0.780, 0.450)         ## h36 s0.55 — más amarilla que la brasa: es una vela, no una forja
const VENTANA_EMISION := Color(1.000, 0.701, 0.360) ## h32 s0.64

## EL VIDRIO DE UNA VENTANA, QUE ES UN AGUJERO Y NO UNA LÁMPARA.
##
## `VENTANA` arriba es el color de la LUZ que sale de adentro, y ése era también
## el albedo del panel. Consecuencia, contada en una captura del valle a
## mediodía: **las veinte ventanas de la aldea eran veinte rectángulos color
## crema, saturación 0,55 y valor 1,0, o sea lo más claro y lo más saturado del
## encuadre entero, a plena luz del día.** Un cuadrado amarillo pintado sobre
## una pared es exactamente la señal de juguete que este archivo existe para
## sacar — y encima es falso: de día no se ve luz por una ventana, se ve un
## agujero oscuro, porque afuera hay más luz que adentro.
##
## Así que el albedo baja a **V2, cálido**: la ventana es la tapa oscura de la
## fachada, igual que el techo lo es de la casa. Y de noche sigue encendiéndose
## igual, porque el que enciende es `emission_energy_multiplier` —`ciclo.gd` lo
## lleva de 0,15 a 4,2— y la emisión se SUMA, no depende del albedo. O sea que
## no se pierde nada de lo que la ventana encendida cuenta; se deja de mentir
## de día.
##
## Y se separa de `VENTANA` en vez de cambiarla porque `KIT_ATLAS` usa `VENTANA`
## para la muestra `ffc044`, que es el farol del kit: eso SÍ es una llama y es
## la excepción 1, con su nombre y su motivo.
const VENTANA_VIDRIO := Color(0.210, 0.171, 0.141) ## h26 s0.33 v0.21 (V2)
const LUCIERNAGA := Color(1.000, 0.824, 0.340)      ## h44 s0.66
const LUCIERNAGA_CALIDA := Color(1.000, 0.697, 0.300)   ## h34 s0.70
const LUCIERNAGA_EMISION := Color(1.000, 0.793, 0.380)  ## h40 s0.62

## Excepción 3 — la herrumbre, en su versión emisiva: los ojos del bicho. Más
## rojos y más oscuros que una ventana para que a la distancia digan otra cosa.
const OJO_BICHO := Color(1.000, 0.518, 0.150)       ## h26 s0.85
const OJO_BICHO_EMISION := Color(1.000, 0.430, 0.100)   ## h22 s0.90

## El humo. Gris cálido y translúcido: gris frío sobre un techo cálido se lee
## como niebla, no como que alguien está cocinando.
const HUMO_NACE := Color(0.780, 0.749, 0.718, 0.55)   ## v0.78 (V7)
const HUMO_MUERE := Color(0.900, 0.886, 0.873, 0.00)  ## v0.90 (V8) — se aclara al disolverse
const HUMO_TELA := Color(0.780, 0.757, 0.733, 0.50)   ## v0.78 (V7)


# ---------------------------------------------------------------------------
# LA GENTE. Acá el valor hace TODO el trabajo: no hay caras que leer.
# ---------------------------------------------------------------------------

const PIEL := Color(0.780, 0.664, 0.562)            ## h28 s0.28 v0.78 (V7)
const OJO := Color(0.053, 0.052, 0.060)             ## h250 s0.14 v0.06 (V0) — casi negro y apenas frío

## Excepción 2 — el jade. El jugador, y sólo el jugador.
const JADE := Color(0.328, 0.780, 0.690)            ## h168 s0.58 v0.78 (V7)
const JADE_CLARO := Color(0.450, 0.900, 0.795)      ## h166 s0.50 v0.90 (V8) — el mismo, para texto sobre fondo oscuro

## El color base de un NPC. figura.gd deriva la ropa de acá multiplicando el
## VALOR por 0.42–1.40, así que este V6 es lo que produce el abanico V3–V8 que
## hace que siete vecinos no parezcan la misma persona. Si lo bajás, el pueblo
## entero se vuelve una fila de sombras iguales.
const ROPA_NPC := Color(0.581, 0.620, 0.660)        ## h210 s0.12 v0.66 (V6)

## El bicho. Verde frío en un valle cálido: lee como ajeno antes de que se
## entienda qué es. Y en V3 se hunde en el suelo del bosque, que es el punto —
## lo que lo delata son los ojos.
const CUERPO_BICHO := Color(0.204, 0.300, 0.223)    ## h132 s0.32 v0.30 (V3)
const PIEL_BICHO := Color(0.382, 0.410, 0.303)      ## h76 s0.26 v0.41 (V4)

## El pelo: cinco tonos y cinco peldaños distintos. Cinco pelos parecidos son
## un pelo. El cano además cuenta una edad.
const PELO_NEGRO := Color(0.130, 0.108, 0.099)          ## v0.13 (V1)
const PELO_CASTANO_OSCURO := Color(0.300, 0.214, 0.156) ## v0.30 (V3)
const PELO_CASTANO := Color(0.530, 0.400, 0.286)        ## v0.53 (V5)
const PELO_TRIGO := Color(0.660, 0.558, 0.383)          ## v0.66 (V6)
const PELO_CANO := Color(0.780, 0.760, 0.733)           ## v0.78 (V7)

## La ropa de oficio. Son manchas grandes y de valor bien distinto al cuerpo:
## un bordado no existe a 25 píxeles de alto, un delantal sí.
const ROPA_CUERO := Color(0.300, 0.215, 0.165)      ## h22  s0.45 v0.30 (V3) — el herrero
const ROPA_LONA := Color(0.171, 0.210, 0.151)       ## h100 s0.28 v0.21 (V2) — la cazadora
const ROPA_METAL := Color(0.488, 0.506, 0.530)      ## h214 s0.08 v0.53 (V5) — el guardia
const ROPA_LINO := Color(0.660, 0.616, 0.515)       ## h42  s0.22 v0.66 (V6) — la destiladora
const ROPA_CINTO := Color(0.130, 0.099, 0.078)      ## h24  s0.40 v0.13 (V1) — el default: parte el cuerpo en dos


# ---------------------------------------------------------------------------
# LA INTERFAZ. Sale de los mismos matices que el mundo, porque si no parece
# pegada encima: el texto es cal cálida, el acento es el dorado de los faroles,
# el peligro es la herrumbre, y lo tuyo es el jade.
#
# Los fondos son casi negros y apenas fríos: es lo que hace que el texto cálido
# se despegue sin subirle el brillo.
# ---------------------------------------------------------------------------

const UI_TEXTO := Color(0.891, 0.900, 0.873)        ## v0.90 (V8)
const UI_TEXTO_TENUE := Color(0.614, 0.660, 0.629)  ## v0.66 (V6)
const UI_TEXTO_DEBIL := Color(0.488, 0.530, 0.509)  ## v0.53 (V5)
const UI_ACENTO := Color(0.780, 0.696, 0.499)       ## h42 s0.36 v0.78 (V7) — el dorado del farol

const UI_FONDO := Color(0.056, 0.074, 0.080, 0.85)
const UI_PANEL := Color(0.072, 0.091, 0.100, 0.94)
const UI_PANEL_ALARMA := Color(0.070, 0.060, 0.059, 0.95)   ## el panel de caída: negro cálido, no negro azul
const UI_AVISO := Color(0.900, 0.720, 0.630)        ## h20 s0.30 v0.90 (V8)

const VIDA_BIEN := Color(0.468, 0.780, 0.707)       ## jade apagado
const VIDA_MEDIO := Color(0.780, 0.608, 0.312)      ## dorado
const VIDA_MAL := Color(0.780, 0.527, 0.499)        ## herrumbre lavada

## Excepción 3 — el peligro.
const HERRUMBRE := Color(0.780, 0.314, 0.172)       ## h14 s0.78 v0.78
const HERRUMBRE_CLARA := Color(0.900, 0.517, 0.378) ## h16 s0.58 v0.90 — para texto

const CARTEL_BORDE := Color(0.042, 0.060, 0.060, 0.85)  ## el contorno de los nombres flotantes
const MAPA_DISCO := Color(0.104, 0.130, 0.121, 0.95)
const MAPA_BORDE := Color(0.353, 0.420, 0.386, 0.70)
const MAPA_NORTE := Color(0.850, 0.632, 0.306, 0.95)    ## la abertura: por ahí crece el mundo
const MAPA_LUGAR := Color(0.598, 0.660, 0.568)


# ===========================================================================
# FÁBRICAS DE MATERIAL
#
# Un StandardMaterial3D suelto en otro script es deuda. Estas funciones existen
# para que nadie tenga excusa para crear uno a mano: si te falta una familia,
# agregala ACÁ.
#
# La rugosidad y el especular están en la fábrica y no en el que llama porque
# **son parte de la identidad del material, igual que el color.** La mitad del
# aspecto de plástico no venía de los colores: venía de que ocho scripts
# pusieran roughness a ojo y todo tuviera el mismo reflejo.
# ===========================================================================

# ---------------------------------------------------------------------------
# LOS DOS CAMINOS DEL COLOR
# (o por qué cinco fábricas de acá abajo llevan `vertex_color_is_srgb`)
#
# Un `Color` de este archivo puede llegar a la pantalla por dos caminos, y
# hasta el 17 de agosto NO DABAN LO MISMO:
#
#   · Por `albedo_color`. Godot sabe que eso es sRGB y lo pasa a lineal él.
#   · Por **color de vértice** (`SurfaceTool.set_color`) o por **color de
#     instancia** (`MultiMesh.set_instance_color`) — y por la rampa de una
#     partícula, que viaja por el mismo COLOR. Ahí Godot no convertía nada:
#     se comía el número como si ya fuera lineal.
#
# Medido con un control renderizado en Godot 4.7.1 —tres quads, el mismo
# `Color(0.5, 0.5, 0.5)`, unshaded, tonemap lineal, sin luces:
#
#   A por albedo_color .......... 0.498   ← el número que dice el código
#   B por color de vértice ...... 0.733   ← 0,24 más claro
#   C por color de instancia .... 0.737   ← 0,24 más claro
#
# **La consecuencia era de composición, no de tecnicismo.** El suelo del valle
# va por vértice y los muros van por albedo, así que el suelo entero rendía dos
# peldaños y medio arriba de la escalera (PASTO v0.30 salía 0.57, ROCA v0.66
# salía 0.83) mientras `MURO_ALDEA` rendía su v0.66 honesto. O sea que la
# aldea, que por diseño de esta escalera es LA MANCHA CLARA DEL CUADRO, salía
# al mismo valor que el suelo que la rodea. Un pueblo se ve porque es más claro
# que el prado; éste no lo era.
#
# Ojo con el matiz, que es el que confunde: la amplitud INTERNA del suelo
# estaba bien. Los cuatro colores del terreno viajan por el mismo camino y
# estaban corridos igual, así que pasto/tierra/pasto seco/roca se separaban
# entre sí como corresponde. Lo roto era la relación entre lo que va por
# vértice y lo que va por albedo.
#
# `vertex_color_is_srgb = true` le dice al shader que ese color también es
# sRGB. **Medido: con el flag, B y C dan 0.498, clavado en A.** Se eligió esto
# y no las otras dos salidas posibles:
#
#   · **Convertir los colores antes de mandarlos** (`srgb_to_linear()` en el
#     que llama): hay que hacerlo en cinco lugares de tres scripts, y el día
#     que alguien mande un color nuevo sin acordarse vuelve el bug. Peor
#     todavía: el mismo `Color` de este archivo tendría que salir convertido
#     para un consumidor y crudo para otro, y ahí se termina la idea de que un
#     color signifique una sola cosa.
#   · **Recalibrar los nominales** para el camino por el que viajan: mata el
#     archivo. Todo el valor de la paleta es que `v0.30` en el comentario sea
#     v0.30 en la pantalla. Una escalera con dos juegos de números según por
#     dónde salga el color es exactamente la papilla de la que se venía.
#
# **Y el flag va fábrica por fábrica, NO en `_base()`.** No es prolijidad, es
# obligatorio: `vegetacion.gd` prende `vertex_color_use_as_albedo` sobre sus
# propias copias de `follaje()` y `madera()`, y por ese camino no manda colores
# sino **multiplicadores** (`_tinte()` divide por el color medio y acota a
# 0,45–1,55). Un multiplicador no es un color y no se convierte: pasarlo por
# sRGB lo mandaría a 0,17–2,20 y le reventaría el rango a la arboleda entera.
# Ése es el único camino de color de vértice del juego que tiene que quedarse
# lineal, y se queda lineal solo porque el flag no está en la fábrica base.
#
# Y lo de siempre: **`vertex_color_use_as_albedo` no se apaga nunca** en estas
# cinco. Sin ese flag el color por instancia se calcula y se tira, y es un bug
# que ya se arregló dos veces acá.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# EL GRANO — LA REGLA 4 DE ESTE ARCHIVO, Y ES NUEVA (18 de agosto)
#
# La dirección del proyecto pidió *"más caricaturesco pero tipo real"* y puso
# como referencia Hytale, Light No Fire y Enshrouded. Lo que esos tres tienen en
# común no es que sean complejos: es que **son estilizados con materia**. La
# piedra se lee como piedra y la madera como madera, con variación DENTRO de una
# misma superficie.
#
# Nuestro problema medido nunca fue que sea simple. Es que es **LISO**. Sobre
# una captura del juego real a mediodía, la desviación de luma por bloque en los
# 620 × 100 píxeles de suelo abierto del primer plano:
#
#   | tamaño del bloque | std mediana |
#   |-------------------|-------------|
#   | 4 px              | **0,03**    |
#   | 8 px              | **0,18**    |
#   | 16 px             | 0,42        |
#   | 32 px             | 0,82        |
#   | 64 px             | 8,33        |
#
# O sea: el 45% de la pantalla no tiene NINGUNA variación por debajo de los 32
# píxeles. Las "manchas grandes para romper la uniformidad" de
# `valle.gd::_color_terreno()` existen y se ven en el renglón de 64, pero por
# debajo de eso el suelo es vinilo. Un degradé lento no es un material.
#
# Y se descartó primero la causa obvia, con el método de la casa —una variable,
# el sol clavado—: **no es el posterizado de `dibujado.gd`.** Con el contorno y
# los cuatro escalones apagados, el suelo da 151,7 de luma y 0,17 de std por
# bloque de 8, contra 151,7 y 0,18 con ellos puestos. Es el mismo píxel. Lo
# liso ya estaba en el material, no en el pase de dibujado.
#
# El grano es UNA textura de ruido en escala de grises, triplanar y en
# coordenadas de mundo, que MULTIPLICA el albedo. No es un asset y no rompe la
# regla del autor único: es un material, y los materiales los decide este
# archivo. Lo que compra, y son dos cosas de golpe:
#
#  1. **Materia.** Variación a 0,3–0,9 m, que a la distancia de la cámara son
#     entre 6 y 30 píxeles: el rango donde el ojo lee "superficie" y no "ruido".
#  2. **El peldaño que faltaba.** La rampa arranca en `GRANO_PISO` y no en 1,0,
#     así que el suelo baja de valor en promedio. Estaba medido que el lienzo
#     rendía luma 150 (≈V6) cuando la composición de este archivo lo quiere en
#     **V4**, y que por eso `MURO_ALDEA` —que es V6 y es LA MANCHA CLARA DEL
#     CUADRO— quedaba a dos puntos del prado que lo rodea. La aduana ya lo había
#     anotado y lo había atribuido al terreno: *"el peldaño que falta es del
#     terreno, no del muro"*. Esto es ese peldaño.
#
# **Y no toca `valle.gd`.** El suelo lo dibuja `_color_terreno()` allá, que no
# es de esta rama; el material sí es de acá, y por eso el arreglo entra por acá.
# ---------------------------------------------------------------------------

## Dónde arranca la rampa del grano. 1,0 es "sin grano". Cuanto más bajo, más
## sucio y más oscuro el suelo. En 0,74 el lienzo baja un peldaño largo y la
## amplitud del grano queda en ±13% de luma, que se lee como tierra y no como
## televisor sin señal.
const GRANO_PISO := 0.58

## Cuántos metros de mundo ocupa una repetición de la textura. Siete metros con
## ruido de tres octavas deja la mancha más grande en ~0,8 m: a 27 m de cámara
## son 14 píxeles y a 68 m son 6. Debajo de eso el mipmap se lo come, que es lo
## que tiene que pasar — el grano que no se resuelve es aliasing, no material.
const GRANO_METROS := 7.0

static var _grano: NoiseTexture2D = null


## La textura de grano, generada al arrancar y compartida por todos los
## materiales que la usen. Cero bytes en disco, igual que el lecho de sonido.
static func grano() -> NoiseTexture2D:
	if _grano != null:
		return _grano
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = 20260818
	n.frequency = 0.028
	n.fractal_octaves = 3
	n.fractal_lacunarity = 2.4
	n.fractal_gain = 0.5
	var g := Gradient.new()
	g.set_color(0, Color(GRANO_PISO, GRANO_PISO, GRANO_PISO))
	g.set_color(1, Color.WHITE)
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.generate_mipmaps = true
	t.color_ramp = g
	t.noise = n
	_grano = t
	return _grano


## Le pone el grano a un material, en coordenadas de MUNDO y triplanar.
##
## En mundo y no en UV por dos motivos que no son estéticos: el terreno se
## genera con `SurfaceTool` y no tiene UV que valgan, y dos superficies pegadas
## —el suelo y la ladera de un peñón— tienen que compartir el grano o se ve la
## costura. Triplanar porque una ladera vertical con UV planares estira el
## ruido hasta volverlo rayas.
static func _engranar(m: StandardMaterial3D, metros: float = GRANO_METROS) -> void:
	m.albedo_texture = grano()
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metros
	m.uv1_triplanar_sharpness = 1.0


## Le pone el grano a un material que ya existe. Es `_engranar()` abierto al
## resto del juego, y existe por la regla 2 de la ficha (`DISENO.md` §6): *nada
## es liso*. Cuando una pieza se genera por código —el gablete de una casa, una
## losa— y convive con mallas que SÍ traen textura, el color plano al lado del
## trim sheet se lee como el agujero que es.
##
## No sirve para cualquier cosa: pisa `albedo_texture`, así que sobre una malla
## del kit que ya trae la suya no se usa (para eso está la aduana de abajo).
static func gastar(m: StandardMaterial3D, metros: float = GRANO_METROS) -> StandardMaterial3D:
	if m != null:
		_engranar(m, metros)
	return m


## El terreno. Sin especular: el pasto y la tierra no reflejan nada, y un
## reflejo parejo en 360 metros de suelo es exactamente el brillo del plástico.
##
## `vertex_color_is_srgb` es la razón de ser del arreglo del 17 de agosto: acá
## viven los cuatro colores del suelo y es el 40% de la pantalla. Sin el flag
## el valle entero flotaba dos peldaños y medio arriba de la escalera y la
## aldea perdía su contraste contra él. Medido, con el flag: PASTO 0.294,
## TIERRA 0.408, PASTO_SECO 0.529, ROCA 0.659 — la escalera V3·V4·V5·V6 tal
## cual la dice el comentario, apenas atenuada por `TERRENO_TINTE`.
##
## Y desde el 18 de agosto lleva **grano** (ver el bloque de arriba): es el 45%
## de la pantalla y era la superficie más lisa del juego.
static func terreno() -> StandardMaterial3D:
	var m := _base(TERRENO_TINTE, 0.97)
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	_engranar(m)
	#m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## La cordillera: todo el color viene de los vértices, el albedo no tiñe.
##
## Va con el flag por la misma razón que el terreno, y NO es opcional que vayan
## juntos: el monte es el fondo contra el que se recorta el valle. Si se
## corrigiera el suelo y no la cordillera, el anillo de montañas quedaría medio
## peldaño más claro que la roca del propio valle y el cuenco se daría vuelta.
## Además el lerp 0.45 hacia `MONTE_AIRE` —la distancia que lava el color— está
## pensado en números de la escalera; sólo significa lo que dice si el camino
## respeta la escalera.
static func monte() -> StandardMaterial3D:
	var m := _base(Color.WHITE, 1.0)
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	#m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Follaje: copas, arbustos, cualquier verde vertical.
static func follaje(c: Color = COPA) -> StandardMaterial3D:
	var m := _base(c, 0.98)
	#m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## La hoja del pasto en MultiMesh.
##
## `vertex_color_use_as_albedo` va prendido y NO es opcional: sin ese flag el
## color por instancia que calcula detalles.gd se descarta en el shader y las
## 26.000 matas salen todas del mismo color. O sea, el estampado que se quería
## evitar. Y por eso el albedo va en blanco: el color lo pone la instancia.
##
## `vertex_color_is_srgb` va acá **obligatoriamente junto con el de
## `terreno()`**, y es la trampa de este arreglo. Las matas son V2–V4 CONTRA UN
## SUELO V4 a propósito: van por debajo del suelo para leerse como textura y
## sombra del prado y no como una pelusa clara apoyada encima. Suelo y matas
## viajaban por el mismo camino torcido, así que la relación se salvaba de
## casualidad — corregir una sola de las dos la rompe en cualquiera de los dos
## sentidos: sólo las matas y quedan casi negras sobre un suelo 0,24 más claro;
## sólo el suelo y las 26.000 matas se vuelven justo la pelusa brillante que la
## paleta eligió no tener.
static func pasto_hoja() -> StandardMaterial3D:
	var m := _base(Color.WHITE, 1.0)
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	#m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_BACK
	return m


## Madera vieja: puertas, vigas, troncos, losas. Apenas de brillo — la madera
## sin tratar no espeja, pero tampoco es tiza.
static func madera(c: Color = MADERA) -> StandardMaterial3D:
	var m := _base(c, 0.88)
	m.metallic_specular = 0.15
	return m


## Piedra: piedras sueltas, ladrillo, muros de piedra.
static func piedra(c: Color = LADRILLO) -> StandardMaterial3D:
	var m := _base(c, 0.94)
	m.metallic_specular = 0.20
	return m


## Muro habitado: revoque de tierra, adobe, tabla. La familia de las casas.
static func muro(c: Color = MURO_ALDEA) -> StandardMaterial3D:
	var m := _base(c, 0.92)
	m.metallic_specular = 0.12
	return m


## Techo. Sin especular y bien mate: es la mancha oscura que hace que una caja
## sea una casa, y un techo que brilla deja de ser una mancha.
static func techo(c: Color = TECHO) -> StandardMaterial3D:
	var m := _base(c, 0.98)
	#m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Tela y ropa: lana, lino, lona. Sin especular — a esta distancia la tela es
## una mancha de valor y nada más, y cualquier reflejo la vuelve satén.
static func tela(c: Color = ROPA_LINO) -> StandardMaterial3D:
	var m := _base(c, 0.96)
	#m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Cuero. Es la única prenda que brilla, y por eso el delantal del herrero se
## distingue de una tela oscura cualquiera cuando le pega el fuego.
static func cuero(c: Color = ROPA_CUERO) -> StandardMaterial3D:
	var m := _base(c, 0.72)
	m.metallic_specular = 0.32
	return m


## Metal: hombreras, herramientas, filos.
static func metal(c: Color = ROPA_METAL) -> StandardMaterial3D:
	var m := _base(c, 0.38)
	m.metallic = 0.72
	return m


## Piel. Rugosa, sin brillo: la piel especular a 27 metros se lee como cera.
static func piel(c: Color = PIEL) -> StandardMaterial3D:
	var m := _base(c, 0.88)
	m.metallic_specular = 0.18
	return m


## El ojo. Casi negro y liso: la poca rugosidad le deja agarrar un reflejo
## puntual del sol, y ese destello es lo que hace que un ojo parezca húmedo en
## vez de un agujero. Se consigue sin emisión — la emisión es de los bichos.
static func ojo() -> StandardMaterial3D:
	var m := _base(OJO, 0.16)
	m.metallic_specular = 0.85
	return m


## El agua del río. Lo único del valle que espeja de verdad.
static func agua() -> StandardMaterial3D:
	var m := _base(AGUA, 0.06)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.35
	m.emission_enabled = true
	m.emission = AGUA_EMISION
	m.emission_energy_multiplier = 0.25
	return m


## Cualquier cosa que emita luz propia. Es la puerta única a la excepción 1:
## si algo brilla en este juego, sale de acá.
static func emisivo(albedo: Color, emision: Color, energia: float) -> StandardMaterial3D:
	var m := _base(albedo, 0.6)
	m.emission_enabled = true
	m.emission = emision
	m.emission_energy_multiplier = energia
	return m


## La brasa de la fragua: el punto cálido del valle.
static func brasa() -> StandardMaterial3D:
	return emisivo(BRASA, BRASA_EMISION, 7.0)


## Cuánto emite una ventana de DÍA, o sea el piso de la rampa que mueve
## `ciclo.gd`. **Estaba en 0,15 y eso no era "apagada": era la ventana más clara
## del cuadro a las tres de la tarde.** Medido en el banco de las casas, luma
## 0–255 al alba: el panel de la ventana daba **117** contra 106 del muro de
## revoque y 34 del techo. La emisión de `VENTANA_EMISION` a 0,15 pesa cuatro
## veces más que el albedo V2 iluminado, así que el vidrio se comía su propio
## color y volvía a ser el cuadradito amarillo que este archivo ya sacó una vez.
##
## En 0,03 el mismo panel cae a la banda del techo y de día se lee como lo que
## es: un agujero. De noche no cambia nada — la rampa llega igual a 4,2.
##
## **OJO: `ciclo.gd` línea 248 tiene el 0,15 copiado** (`lerp(0.15, 4.2, ...)`) y
## lo pisa en cada cuadro, así que hasta que esa línea diga `PISO_VENTANA` este
## número sólo vale para el primer cuadro y para los bancos de prueba. Está
## pedido en el informe; ese archivo no es de la rama de arte.
const PISO_VENTANA := 0.03


## Una ventana encendida. Dice "adentro hay alguien" más fuerte que todo el
## cielo junto. La energía la mueve `ciclo.gd` de noche (`PISO_VENTANA` → 4.2),
## así que acá se entrega apagada: de día una ventana encendida se ve a error.
static func ventana() -> StandardMaterial3D:
	return emisivo(VENTANA_VIDRIO, VENTANA_EMISION, PISO_VENTANA)


## Los ojos del bicho. Es lo único que emite en él y es lo que lo hace visible
## entre los árboles antes de que lo veas del todo.
static func ojo_de_bicho() -> StandardMaterial3D:
	return emisivo(OJO_BICHO, OJO_BICHO_EMISION, 9.0)


## El cartel de humo. Recibe color de la partícula, no proyecta ni recibe
## sombra: está sobre el techo, nunca hay nada que se la tire, y recibirla
## cuesta una búsqueda en el atlas por píxel de humo.
##
## `vertex_color_is_srgb`: la rampa de la partícula viaja por COLOR, o sea por
## el mismo camino que un color de vértice. **Acá el flag ATENÚA en vez de
## aclarar**, y por eso hay que decidirlo y no copiarlo: el error del camino
## venía compensado a medias por el tinte `HUMO_TELA`, así que la columna
## rendía 0.698 al nacer contra un nominal de 0.780 y no había un salto
## escandaloso que arreglar. Se le pone igual, por dos razones. Una: 0.604 es
## lo que pide la aritmética de la propia paleta —V7 de la rampa multiplicado
## por V7 del tinte— y el sentido de este archivo es que sus cuentas den. Dos:
## dejar una sola fábrica con otro camino de color reinstala la enfermedad que
## la paleta existe para curar, ahora como dos pipelines en vez de ocho tachos.
## Medido, con el flag: nace 0.604 y muere 0.698. Sigue
## siendo V6–V7 contra un techo V2 —o sea sigue siendo la mancha clara sobre la
## casa— y se conserva lo único que la columna tiene que contar, que es que se
## ACLARA al disolverse.
static func humo() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = HUMO_TELA
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.disable_receive_shadows = true
	return m


## Una chispa: luciérnagas y cualquier partícula que sea luz y no materia.
## Sin sombreado — una luciérnaga sombreada es un punto gris.
##
## `vertex_color_is_srgb`: **acá no es cosmético y no es un caso menor por ser
## chiquito.** El corrimiento del camino de color, en algo que ya vive contra
## el techo de la escalera, no se puede leer como valor porque no le queda para
## dónde aclararse: se lee como PÉRDIDA DE COLOR. Medido sin el flag, la
## luciérnaga salía (1.000, 0.918, 0.616) —saturación 0,38— en vez de la
## (1.000, 0.824, 0.340) que dice `LUCIERNAGA`, saturación 0,66. O sea que el
## camino se comía casi la mitad de la excepción 1. Y la excepción 1 es la que
## hace el tono entero del juego: un valle apagado con seis puntos ÁMBAR es
## melancólico; con seis puntos casi blancos es una guirnalda.
##
## TRAMPA MEDIDA Y TODAVÍA SIN ARREGLAR, no la redescubras: **con
## `SHADING_MODE_UNSHADED` Godot 4.7 descarta la emisión.** Control: un quad de
## albedo negro con emisión y energía 6.0 sale blanco sombreado (1.000) y negro
## unshaded (0.000). O sea que en esta fábrica `emision` y `energia` no hacen
## nada hoy y la luciérnaga es puro albedo, sin HDR y por lo tanto sin glow.
## No se toca en el mismo cambio que el camino de color porque prenderla sube
## la chispa unas seis veces de golpe y eso es una decisión de tono que se mira
## en pantalla, no un arreglo de tubería.
static func chispa(emision: Color = LUCIERNAGA_EMISION, energia: float = 6.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.emission_enabled = true
	m.emission = emision
	m.emission_energy_multiplier = energia
	return m


static func _base(c: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	return m


# ===========================================================================
# LA ADUANA — POR DÓNDE ENTRA EL ARTE QUE NO ESCRIBIMOS NOSOTROS
#
# Hasta el 17 de agosto había DOS direcciones de arte en el mismo cuadro, y está
# medido sobre píxeles de una captura del juego real:
#
#   · Los techos del kit salían a **saturación 0,47 y 0,53** (matiz 3° y 359°:
#     rosa chicle) y **0,35 / 0,37** en cian, contra un techo de 0,35 que este
#     archivo le fija a todo lo que se mide en metros cuadrados.
#   · Los muros del kit, a **saturación 0,46**, naranja h18.
#   · Y peor que la saturación, el VALOR: el techo cian medía **luma 145** y el
#     suelo **122**. O sea que la tapa era más clara que la caja y que el prado.
#     Esa es exactamente la lectura que la escalera de esta paleta existe para
#     producir al revés — "caja clara, tapa oscura" es lo único que hace que una
#     casa se lea como una casa a 27 metros.
#
# No era un bug del motor. Se descartó, midiendo de a una cosa por vez sobre la
# misma escena con el sol congelado: SDFGI a energía 0 (sin cambio), la niebla
# volumétrica a densidad 0 (sin cambio), la niebla de distancia apagada (sin
# cambio: arranca a 210 m y la aldea está a 40), y el tonemapper AgX cambiado
# por Filmic y por Lineal (el rango p5–p95 se movía de 81 a 81 y a 78). **El
# entorno no tenía la culpa: los colores del kit son literalmente ésos.**
#
# La fuente, verificada leyendo los `.glb` y los dos atlas:
#
#   · `naturaleza/` no tiene texturas: cada material trae su color. El material
#     que Kenney llama `leafsGreen` es **h169 s0.80** — o sea turquesa, no
#     verde. `woodBark` es h19 s0.62, salmón.
#   · `pueblo/` y `utiles/` comparten un atlas de 24 muestras planas, todas
#     entre s0.17 y s0.73. Es una paleta de dibujo animado, coherente consigo
#     misma y ajena a ésta.
#
# `kit.gd` decía que "la paleta no manda sobre las mallas del kit, que ya vienen
# con una paleta coherente de fábrica". **Esa frase es el bug.** DISENO.md §6
# dice lo contrario con todas las letras: *el color es una decisión de diseño y
# eso le da a la paleta autoridad sobre todo lo demás*. Dos paletas coherentes
# en un mismo cuadro no son dos aciertos, son la indecisión que se lee como
# Playmobil.
#
# Quién la llama: `Kit._domar_color()`, una vez por malla —los `Mesh` del kit
# están cacheados por ruta— y sobre una COPIA del material, así que el recurso
# importado no se toca. Los dos atlas se traducen una sola vez cada uno y
# cuestan 48 ms entre los dos.
#
# Así que el kit entra, y entra por acá. Lo que NO cambia: las mallas siguen sin
# `material_override` —aplanarlas a un color tira la razón por la que se
# trajeron, que es la geometría—, y el atlas sigue siendo un atlas. Lo único que
# pasa es que cada muestra se cambia por la de esta paleta que ocupa su lugar.
#
# MEDIDO, dos capturas seguidas de la misma escena con el sol congelado, luma
# 0–255 (la única diferencia entre las dos es que la aduana corra o no):
#
#   |                            | antes | después |
#   |----------------------------|-------|---------|
#   | techo rojo, cara al sol    |  122  |    34   |
#   | techo rojo, cara en sombra |  103  |    26   |
#   | techo turquesa             |  145  |    33   |
#   | muro, cara al sol          |  146  |   124   |
#   | suelo abierto              |  122  |   122   |
#   | saturación de los techos   | 0,50 0,56 0,37 0,30 | 0,29 0,23 0,26 0,22 |
#   | saturación de los muros    | 0,46  |  0,35   |
#
# Lo que compra: **ninguna superficie grande pasa el techo de 0,35**, y los
# techos pasan de estar 23 puntos ARRIBA del suelo a estar 92 abajo. Antes la
# tapa era lo más claro de la casa; ahora es lo más oscuro, que es la lectura
# que esta paleta describe desde el primer día.
#
# Lo que NO alcanza a arreglar, y hay que decirlo: **el muro pierde 22 puntos**
# (146 → 124) y queda a dos del suelo. No es la aduana: es que el suelo alrededor
# de la aldea no está en V4 como supone la composición de arriba, está en V5. Se
# midió por los dos lados — el píxel del suelo da h44 s0,28, que es `PASTO_SECO`
# clavado, y `valle.gd::_color_terreno()` satura su interpolación en pasto seco
# a partir de y = 2, que es la altura a la que está el pueblo. Contra un lienzo
# V5, un muro V6 empata: no hay ningún color de esta escalera que separe, porque
# V7 es la piel y V8 no lo pisa nada del mundo. **El peldaño que falta es del
# terreno, no del muro.**
# ===========================================================================

## Las 24 muestras del atlas de Kenney (`pueblo/` y `utiles/` comparten las
## mismas), y a qué color de esta paleta va cada una. La clave es el hex tal
## cual está en `Textures/colormap.png`.
##
## **El criterio es el peldaño, no el parecido.** Una muestra no va al color de
## esta paleta que más se le parece: va al que le corresponde por el trabajo que
## hace en el cuadro. Por eso los dos rojos de techo (`c3495c`, `cf534f`) y el
## turquesa de techo (`51b296`) caen a V2 aunque vengan de V0.76–0.81: un techo
## es la tapa oscura, y si el color "correcto" no separa, el correcto está mal.
##
## Las dos muestras de fuego (`ff7e44`, `ffc044`) son la excepción 1 y se van
## saturadas a propósito: son el farol y la fragua del kit, y son cuatro píxeles.
const KIT_ATLAS := {
	# los techos — todos a V2, la tapa oscura. Cálido y frío, mismo peldaño.
	"c3495c": TECHO,            # rojo teja      h351 s0.63 v0.76
	"cf534f": TECHO,            # rojo claro     h  2 s0.62 v0.81
	"51b296": TECHO_PIZARRA,    # turquesa       h163 s0.54 v0.70
	# los muros — a V6, que es la mancha clara del pueblo
	"c58262": MURO_ALDEA,       # revoque        h 19 s0.50 v0.77
	"eeba88": MURO_ALDEA,       # revoque claro  h 29 s0.43 v0.93
	"f2bf99": ROCA,             # piedra clara   h 26 s0.37 v0.95
	"fde4c7": ROCA,             # cal            h 32 s0.21 v0.99
	"ffffff": ROCA,             # blanco
	"f1976c": MURO_FRAGUA,      # madera clara   h 19 s0.55 v0.95
	# la madera y el ladrillo — abajo del suelo, para que las vigas se lean
	"b06041": LADRILLO,         # madera         h 17 s0.63 v0.69
	"9a5942": TRONCO,           # madera oscura  h 16 s0.57 v0.60
	# lo verde del kit, al mismo lugar que el bosque
	"51b985": PASTO,            # verde claro    h150 s0.56 v0.73
	"61cb8b": COPA,             # verde          h144 s0.52 v0.80
	# lo frío: metal, vidrio, agua
	"6794d9": MONTE_AIRE,       # azul fuerte    h216 s0.53 v0.85
	"a0a8c9": MONTE_ALTO,       # gris azul      h228 s0.20 v0.79
	"d0e8ff": MONTE_ALTO,       # vidrio         h209 s0.18 v1.00
	"868ba1": ROPA_METAL,       # hierro claro   h229 s0.17 v0.63
	"4f5260": MURO_RUINA,       # hierro         h229 s0.18 v0.38
	"38383d": MADERA,           # hierro oscuro  h240 s0.08 v0.24
	"42424a": MADERA,           # hierro oscuro  h240 s0.11 v0.29
	# excepción 1 — el fuego. Se quedan saturadas y por eso están nombradas.
	"ff7e44": BRASA,            # llama          h 19 s0.73 v1.00
	"ffc044": VENTANA,          # farol          h 40 s0.73 v1.00
}

## Los materiales del Nature Kit, que no tienen textura: el color va en el
## material y Kenney los deja nombrados, así que se mapean por NOMBRE, que es
## más firme que por color.
##
## Las flores y los hongos (`color*`) no están acá: son manchas de centímetros y
## caen en el techo de gente (S ≤ 0.50) por la regla general de `domar()`. Es la
## misma decisión que el pelo — un valle donde la flor roja es gris no se cree.
## El follaje va a `COPA_CLARA` y NO a `COPA`, y no es un descuido: es una
## medición ajena que conviene no perder. `COPA` es V2 y está pensado para el
## bloque del Sotobosque; aplicado a los 1.600 árboles del kit deja siluetas
## negras a cuarenta metros. Si alguna vez alguien "corrige" esto a `COPA`, el
## bosque se vuelve un agujero.
const KIT_MATERIAL := {
	"leafsGreen": COPA_CLARA,   # h169 s0.80 v0.79 — turquesa en el original
	"leafsDark": COPA_CLARA,    # h182 s0.75 v0.67
	"grass": COPA_CLARA,        # h169 s0.80 v0.85
	"woodBark": TRONCO_CLARO,   # h 19 s0.62 v0.89
	"woodBarkDark": TRONCO_CLARO,   # h 13 s0.54 v0.80
	"wood": LADRILLO,           # h 17 s0.62 v1.00
	"woodDark": MADERA,         # h 17 s0.62 v0.77
	"woodInner": PASTO_SECO,    # h 29 s0.24 v0.96
	"dirt": TIERRA,             # h 19 s0.62 v0.89
	"dirtDark": LADRILLO,       # h 19 s0.62 v0.71
	"stone": ROCA,              # h188 s0.21 v0.91
	"_defaultMat": PASTO_SECO,  # el trigo: blanco puro en el original, y nada
	                            # del mundo llega a V8
}

## CUANDO EL NOMBRE DEL MATERIAL DEL KIT MIENTE.
##
## `KIT_MATERIAL` mapea por el nombre que le puso Kenney porque un nombre es más
## firme que un color. **Salvo cuando el nombre está mal**, y en el Nature Kit
## hay una familia entera donde lo está.
##
## Se descubrió abriendo los `.glb` con un lector de glTF, no leyendo el código
## — que es la regla de la casa: *abrí el archivo antes de creerle al
## comentario*. Lo que hay adentro de `rock_smallA.glb`:
##
##   | primitiva | material | color de fábrica          | 30 vértices |
##   |-----------|----------|---------------------------|-------------|
##   | 1         | `grass`  | (0.173, 0.847, 0.722) turquesa | sí     |
##   | 2         | `dirt`   | (0.886, 0.514, 0.341) salmón   | sí     |
##
## **No hay ninguna superficie `stone` en ninguna de las cuatro piedras del
## kit.** `rock_smallA`, `rock_smallB` y `rock_smallD` traen `grass` + `dirt`, y
## `rock_tallC` trae además `_defaultMat`. Kenney reusó los materiales de otra
## pieza y quedaron con el nombre equivocado.
##
## La consecuencia era exacta y estaba anotada como deuda: la aduana mandaba
## `grass` a `COPA_CLARA` (V4) y `dirt` a `TIERRA` (V4), o sea **las 320 piedras
## del valle salían al MISMO peldaño que el suelo que las rodea**, cuando el
## comentario de `detalles.gd::piedras()` dice que son *"la puntuación clara del
## cuadro, lo más claro del paisaje"*. Con el suelo en V5 en pantalla, encima
## salían por debajo. No puntuaban nada porque no eran piedras: eran barro.
##
## Acá se corrige por RUTA, no por nombre, que es el único dato confiable que
## queda. Y de paso las dos primitivas dejan de ser un error y pasan a ser una
## decisión: **el cuerpo va a `ROCA` (V6) y la tapa a `PASTO` (V3)**. Una piedra
## con musgo encima es dos peldaños de contraste dentro de un objeto de ocho
## píxeles, y eso es lo que la hace legible a la distancia de la cámara — y es
## exactamente el desgaste que pidió la dirección: *"caricaturesco pero tipo
## real"*. La piedra limpia y monocroma es la que se lee a juguete.
##
## La clave es un pedazo de la ruta y se busca por `contains()`: así una piedra
## nueva del mismo pack entra sola.
const KIT_CONTEXTO := {
	"rock_": {"dirt": ROCA, "grass": PASTO, "_defaultMat": ROCA},
	"campfire_stones": {"stone": ROCA},
}


# ---------------------------------------------------------------------------
# LOS SIETE TRIM SHEETS DE QUATERNIUS — Y POR QUÉ "YA VIENEN DOMADOS" ERA MEDIA
# VERDAD (18 de agosto)
#
# `domar_material()` saltea `atlas_domado()` para todo lo que cuelgue de
# `/quaternius/` y le deja `albedo_color = WHITE`. El salteo está bien —esas
# texturas son fotográficas y el clavado al peldaño las posteriza, ver
# `PROCEDENCIA.md`—. **Lo que estaba mal es el `WHITE`**, y se ve apenas se
# miden los siete PNG del repo (media de los 512², sRGB, sobre el archivo):
#
#   | textura        | V medio | S medio | a qué peldaño cae |
#   |----------------|---------|---------|-------------------|
#   | T_Plaster      |  0.574  |  0.274  | entre V5 y V6     |
#   | T_UnevenBrick  |  0.475  |  0.237  | entre V4 y V5     |
#   | T_Brick        |  0.504  |  0.200  | entre V4 y V5     |
#   | T_RockTrim     |  0.501  |  0.146  | entre V4 y V5     |
#   | **T_RoundTiles**| **0.585**| 0.350  | **V5** ← el techo |
#   | T_WoodTrim     |  0.490  |  0.235  | entre V4 y V5     |
#   | T_VineLeaf     |  0.479  |  0.000  | gris, sin color   |
#
# O sea: **el horneado comprimió el valor de las siete al mismo medio tono.**
# Coherente consigo mismo, y ajeno a esta escalera — que es exactamente el
# diagnóstico que trajo la aduana de Kenney, otra vez y en otro idioma.
#
# Lo grave es el techo. `T_RoundTiles` sale en **V5, el mismo peldaño que un
# muro**, cuando la composición de este archivo pone los techos en **V2**. Con
# eso una casa deja de ser *caja clara con tapa oscura* y pasa a ser una sola
# mancha del color del suelo. Medido en el banco `prueba_casas.tscn` (luma
# 0–255, misma luz para las dos casas):
#
#   |                    | Kenney | Quaternius sin tinte |
#   |--------------------|--------|----------------------|
#   | muro al sol        |  131   |         117          |
#   | techo al sol       |   48   |          75          |
#   | techo / muro       |  0.37  |        **0.64**      |
#
# El tinte de acá abajo cierra esa brecha SIN tocar la textura: `albedo_color`
# MULTIPLICA al trim sheet, así que el grano —que es justamente lo que se vino a
# buscar, la regla 2 de la ficha— se conserva entero y lo único que se mueve es
# el peldaño.
#
# **Cómo se calculó cada número, para que se pueda rehacer:** se promedió el PNG
# en espacio LINEAL, se dividió el color de esta paleta (también en lineal) por
# esa media, y el cociente se devolvió a sRGB — que es el espacio en el que
# Godot recibe `albedo_color`. Con eso el resultado cae en el peldaño exacto:
# verificado en el mismo cálculo, `MI_RoundTiles` da h18 s0.30 v0.21, que es
# `TECHO` clavado, y `MI_WoodTrim` da h26 s0.35 v0.30, que es `TRONCO_CLARO`.
#
# **TRES DE LOS SIETE TIENEN COMPONENTES ARRIBA DE 1,0 Y ES A PROPÓSITO.** El
# horneado dejó el revoque, el ladrillo desparejo y la piedra POR DEBAJO del
# peldaño que les toca, así que para subirlos hay que aclarar. Un `Color` con
# componentes mayores que uno no es un color: es un **multiplicador**, la misma
# distinción que ya hace este archivo con los colores de vértice de
# `vegetacion.gd`. La conversión sRGB→lineal de Godot es una potencia y sigue
# valiendo arriba de 1, y el cálculo de arriba la tiene en cuenta — por eso los
# números son 1,144 y no 1,15 redondo.
#
# **Y que Godot NO lo recorta está medido, no supuesto**, con el método de la
# casa: tres capturas del mismo banco con el sol clavado y una sola variable, el
# tinte del revoque, comparadas píxel a píxel.
#
#   | tinte de `MI_Plaster` | píxeles que cambian | luma del revoque |
#   |-----------------------|---------------------|------------------|
#   | 1,000 (control)       |          0          |       86,4       |
#   | 0,600                 |       70.662        |       48,6       |
#   | **1,144 / 1,161 / 1,248** |    69.721       |     **101,3**    |
#
# Sube 14,9 puntos, o sea +17%, que es justo el peldaño que pide la aritmética
# (V 0,574 → V 0,66 son +15%). El multiplicador llega entero al shader.
#
# Y si algún día se rehornean los PNG a su peldaño, esta tabla se va a WHITE
# sola: los cocientes dan 1. Mientras tanto vive acá, que es donde se decide un
# color y no en un archivo binario.
# ---------------------------------------------------------------------------

## Nombre del material del Medieval Village MegaKit → multiplicador de albedo.
## Ver el bloque de arriba. La clave es el nombre que trae el `.gltf`.
const KIT_QUATERNIUS := {
	"MI_Plaster": Color(1.144, 1.161, 1.248),        # → MURO_ALDEA   h36 s0.20 V6
	"MI_UnevenBrick": Color(1.367, 1.397, 1.417),    # → MURO_ALDEA   h36 s0.20 V6
	"MI_Brick": Color(0.615, 0.553, 0.569),          # → LADRILLO     h18 s0.28 V3
	"MI_RockTrim": Color(1.056, 1.086, 1.120),       # → LOSA_CAMINO  h34 s0.09 V5
	"MI_RoundTiles": Color(0.382, 0.419, 0.435),     # → TECHO        h18 s0.30 V2
	"MI_WoodTrim": Color(0.632, 0.594, 0.558),       # → TRONCO_CLARO h26 s0.35 V3
	"MI_WoodTrim_Wear": Color(0.632, 0.594, 0.558),  # el carro: misma madera, más gastada
	# La hoja de la enredadera viene en GRIS (S 0,000: el verde estaba en el
	# `baseColorFactor` del `.gltf`, que el `WHITE` de antes borraba). Acá vuelve,
	# y vuelve en el verde de la paleta y no en el del autor.
	"MI_Vine": Color(0.694, 0.864, 0.581),           # → COPA_CLARA   h96 s0.35 V4
}


## Los nueve peldaños, como lista, para poder buscar el más cercano.
const ESCALERA: Array[float] = [V0_TINTA, V1_CARBON, V2_TURBA, V3_CORTEZA,
	V4_ARCILLA, V5_LINO, V6_TRIGO, V7_CENIZA, V8_CAL]


## La regla general para un color que viene de afuera y no está en ninguna
## tabla: se le respeta el matiz, se le baja la saturación al techo y **se le
## clava el valor al peldaño más cercano de la escalera.**
##
## El clavado del valor no es cosmético: es lo que impide que entre un color a
## mitad de camino entre dos peldaños, que es justo el que no separa de nada. Un
## kit plano como éste se banca el clavado sin bandearse porque sus colores ya
## son planos; no le hagas esto a una textura fotográfica.
static func domar(c: Color, techo: float = SATURACION_MUNDO) -> Color:
	var v := c.v
	var mejor := v
	var dist := 9.0
	for p in ESCALERA:
		var d := absf(p - v)
		if d < dist:
			dist = d
			mejor = p
	return Color.from_hsv(c.h, minf(c.s, techo), mejor, c.a)


## Cache del atlas ya traducido, por ruta del recurso. Es una pasada de 512×512
## por atlas y hay dos en todo el juego; sin la cache serían 76 pasadas, una por
## malla del kit.
static var _atlas_domado: Dictionary = {}


## Traduce el atlas de Kenney a esta paleta, muestra por muestra, y devuelve una
## textura nueva. La original no se toca.
##
## Lo que no está en `KIT_ATLAS` pasa por `domar()`, así que si Kenney republica
## el pack con una muestra más, esa muestra entra igual acotada y no rompe nada:
## se ve apagada y en un peldaño, que es el peor caso aceptable.
static func atlas_domado(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var clave := tex.resource_path
	if clave != "" and _atlas_domado.has(clave):
		return _atlas_domado[clave]

	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)

	var d := img.get_data()
	var traducidos := {}          # int rgb -> PackedByteArray de 3
	var i := 0
	while i < d.size():
		var llave := (d[i] << 16) | (d[i + 1] << 8) | d[i + 2]
		var nuevo: PackedByteArray = traducidos.get(llave, PackedByteArray())
		if nuevo.is_empty():
			nuevo = _traducir_muestra(d[i], d[i + 1], d[i + 2])
			traducidos[llave] = nuevo
		d[i] = nuevo[0]
		d[i + 1] = nuevo[1]
		d[i + 2] = nuevo[2]
		i += 4

	var salida := Image.create_from_data(img.get_width(), img.get_height(),
		false, Image.FORMAT_RGBA8, d)
	salida.generate_mipmaps()
	var t := ImageTexture.create_from_image(salida)
	if clave != "":
		_atlas_domado[clave] = t
	return t


## Las muestras del atlas como colores, para poder buscar la más cercana.
## Se arma una sola vez: `KIT_ATLAS` está escrito en hexadecimal porque así se
## lee del archivo de Kenney, pero comparar por hexadecimal NO sirve, y ésa es
## la trampa de este arreglo. **Godot importa el atlas comprimido a VRAM**, así
## que los píxeles que devuelve `get_image()` no son los del PNG: `c3495c` sale
## como algo a un par de unidades de distancia. La primera versión comparaba el
## hex exacto, no acertaba ni una muestra, y los techos salían por la regla
## general —saturación 0,36 y **más claros** que antes, medido— en vez de irse
## a V2. Por eso se busca la más cercana y no la igual.
static var _muestras: Array = []


static func _traducir_muestra(r: int, g: int, b: int) -> PackedByteArray:
	if _muestras.is_empty():
		# El fondo del atlas es negro y no es una muestra: se mapea a sí mismo
		# para que ninguna UV que caiga ahí se pinte de un color del pueblo.
		_muestras.append([Color(0, 0, 0), Color(0, 0, 0)])
		for hex in KIT_ATLAS:
			_muestras.append([Color(hex), KIT_ATLAS[hex]])

	var c := Color8(r, g, b)
	var mejor: Color = domar(c, SATURACION_GENTE)
	var dist := 0.045          # radio máximo; más lejos que esto no es la muestra
	for par in _muestras:
		var o: Color = par[0]
		var d: float = (o.r - c.r) * (o.r - c.r) + (o.g - c.g) * (o.g - c.g) \
			+ (o.b - c.b) * (o.b - c.b)
		if d < dist:
			dist = d
			mejor = par[1]
	return PackedByteArray([int(round(mejor.r * 255.0)), int(round(mejor.g * 255.0)),
		int(round(mejor.b * 255.0))])


## Pasa un material del kit por la aduana, en su sitio.
##
## Los tres caminos, en orden: el nombre que le puso Kenney (Nature Kit), la
## textura de atlas (Fantasy Town y Survival), y si no es ninguno de los dos, la
## regla general sobre el albedo.
##
## También le saca el especular, que es la otra mitad del aspecto de plástico:
## el kit viene con `roughness` de fábrica y ocho superficies con el mismo
## reflejo parejo se leen como ocho piezas del mismo juguete.
## `techo` es el tope de saturación. El de fábrica es `SATURACION_MUNDO` —
## terreno, muros, techos, follaje— y es el que corresponde a casi todo. La
## excepción son los **animales**: un pelaje es cuero, no es un muro, y este
## archivo ya tiene ese peldaño escrito en `SATURACION_GENTE` ("pelo, cuero,
## tintes de ropa"). Con 0,35 los siete bichos de `fauna.gd` colapsaban al
## mismo tostado —medido: la vaca y el caballo salían el mismo color— y un
## rebaño de un solo color se lee como un rebaño de copias.
##
## `ruta` es la del `.glb` y sirve para UNA cosa: `KIT_CONTEXTO`, o sea las
## mallas donde Kenney dejó el nombre del material equivocado. Ver ese bloque.
static func domar_material(m: BaseMaterial3D, techo: float = SATURACION_MUNDO,
		ruta: String = "") -> void:
	if m == null:
		return
	if ruta != "":
		for clave in KIT_CONTEXTO:
			if not ruta.contains(clave):
				continue
			var tabla: Dictionary = KIT_CONTEXTO[clave]
			if tabla.has(m.resource_name):
				m.albedo_color = tabla[m.resource_name]
				m.albedo_texture = null
				m.roughness = maxf(m.roughness, 0.95)
				# Y se abre el camino del color por INSTANCIA, que es lo que le
				# permite a `detalles.gd` que mil doscientas piedras no sean la
				# misma piedra. Va SIN `vertex_color_is_srgb`, al revés que las
				# cinco fábricas de arriba, y por el mismo motivo que la
				# vegetación: por ahí no viaja un color, viaja un MULTIPLICADOR
				# de valor, y un multiplicador no se convierte. Sin instancias
				# con color el flag no hace nada (el color por defecto es blanco),
				# así que las piedras sueltas de `Kit.nodo()` no cambian.
				m.vertex_color_use_as_albedo = true
				return
	if m.albedo_texture != null:
		# **Lo de Quaternius ya viene domado de disco y no se vuelve a domar.**
		#
		# `atlas_domado()` traduce píxel por píxel en GDScript. Sobre el atlas
		# de Kenney eso es una pasada de 512² con 24 muestras distintas, o sea
		# 24 traducciones y el resto cache. Sobre un trim sheet fotográfico de
		# Quaternius son decenas de miles de colores únicos, y además el
		# clavado al peldaño lo posteriza — este archivo lo avisa textual en
		# `domar()`: *no le hagas esto a una textura fotográfica*. Por eso ésas
		# se hornean **offline**, con saturación al techo y valor comprimido en
		# vez de clavado, antes de entrar al repo. Ver `assets/PROCEDENCIA.md`.
		#
		# **El filtro es por ruta y NO por tamaño.** Se probó por tamaño
		# (`<= 128`) y fue un error caro de ver: el atlas de Kenney también es
		# de 512, así que la aduana se apagó para el pueblo entero y las casas
		# volvieron al menta y coral de fábrica. En una captura se ve al toque;
		# en el código no se ve nada.
		if m.albedo_texture.resource_path.contains("/quaternius/"):
			# **Y acá el albedo NO va en blanco.** El horneado dejó los siete trim
			# sheets en el mismo medio tono —el techo de teja en V5, o sea el
			# peldaño de un muro— y `albedo_color` es el único lugar donde eso se
			# puede corregir sin volver a tocar el PNG. Ver `KIT_QUATERNIUS`.
			m.albedo_color = KIT_QUATERNIUS.get(m.resource_name, Color.WHITE)
			m.roughness = maxf(m.roughness, 0.95)
			return
		m.albedo_texture = atlas_domado(m.albedo_texture)
		# Con atlas, el albedo es un multiplicador (Kenney lo deja en blanco):
		# domarlo lo bajaría dos veces.
		m.albedo_color = Color.WHITE
	elif KIT_MATERIAL.has(m.resource_name):
		m.albedo_color = KIT_MATERIAL[m.resource_name]
	else:
		m.albedo_color = domar(m.albedo_color, techo)
	# El agua de la fuente es una de las tres cosas que brillan en este juego
	# (cuero, metal, agua): se le doma el color y se le deja la rugosidad baja,
	# que es de donde sale el reflejo.
	if m.resource_name == "Water":
		return
	# La otra mitad del aspecto de plástico no es el color: es que ocho
	# superficies tengan el mismo reflejo parejo. El kit viene con la rugosidad
	# de fábrica; acá se la sube al piso de las familias mates de este archivo.
	m.roughness = maxf(m.roughness, 0.95)

	# **LA ADUANA DECIDE COLOR, NO SOMBREADO. No le pongas `SPECULAR_DISABLED`.**
	#
	# Se probó, porque la regla 2 de este archivo dice que el follaje y los
	# techos van sin especular, y salió mal de una forma que no se ve venir: con
	# rugosidad 1,0 el lóbulo especular de Godot es tan ancho que no hace brillo,
	# hace RELLENO, y apagarlo le saca al kit la mitad de su luz. Medido, una
	# captura contra otra y nada más cambiado:
	#
	#   copa del árbol   46 → 22      techo   41 → 34      muro   127 → 124
	#
	# O sea que el bosque se volvía una silueta negra —justo el problema que
	# `COPA_CLARA` existe para evitar— y encima los techos rendían POR DEBAJO de
	# su peldaño: con el especular puesto el techo da 41 contra un nominal de
	# 44, que es lo que este archivo promete. Apagarlo compraba cuatro puntos de
	# rango p5–p95 aplastando los oscuros, y la regla dice lo contrario: nada
	# grande vive abajo de V2, porque de noche desaparece.
	#
	# La regla del especular sigue valiendo para lo que generamos nosotros —ahí
	# el material es sólo un color plano y apagarlo no le saca luz a nada—, y por
	# eso está en `_base()` y sus fábricas. Sobre una malla ajena, no.


# ===========================================================================
# LA HORA DEL VALLE
#
# La hora la manda el SERVIDOR y la aplica `ciclo.gd`. Lo que hay acá es la
# mezcla de colores ya hecha, para que el día que se migre el ciclo no haya que
# reescribirla y para que nadie invente un quinto color de sol.
# ===========================================================================

## El color del sol para una altura dada (seno del ángulo, −1 a 1).
## `poniente` distingue el ocaso del alba: es el mismo arco, con distinto rojo.
static func luz_solar(altura: float, poniente: bool) -> Color:
	var d := clampf(remap(altura, -0.15, 0.25, 0.0, 1.0), 0.0, 1.0)
	var dorada := 1.0 - absf(clampf(remap(altura, -0.10, 0.45, 0.0, 1.0), 0.0, 1.0) * 2.0 - 1.0)
	var c := LUZ_LUNAR.lerp(LUZ_MEDIODIA, d)
	return c.lerp(LUZ_OCASO if poniente else LUZ_ALBA, dorada * 0.75)


## El color de la niebla de distancia según cuánta luz de día hay (0 = noche).
static func niebla(luz_del_dia: float) -> Color:
	return NIEBLA_NOCHE.lerp(NIEBLA_DIA, clampf(luz_del_dia, 0.0, 1.0))


## Para el BBCode de la interfaz, que pide `#rrggbb` y no un Color. Existe para
## que los hexadecimales sueltos del diálogo (`#ce8b84`, `#7d867f`) también
## salgan de la paleta y no de la memoria de alguien.
static func hex(c: Color) -> String:
	return "#" + c.to_html(false)
