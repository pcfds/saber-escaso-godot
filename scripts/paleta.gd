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
const PASTO_SECO := Color(0.530, 0.488, 0.371)      ## h44  s0.30 v0.53 (V5)
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
const MADERA := Color(0.130, 0.103, 0.086)          ## h24 s0.34 v0.13 (V1) — una puerta tiene que leerse como un agujero
const LADRILLO := Color(0.300, 0.241, 0.216)        ## h18 s0.28 v0.30 (V3)
const TRONCO := Color(0.210, 0.172, 0.147)          ## h24 s0.30 v0.21 (V2)
const COPA := Color(0.172, 0.210, 0.147)            ## h96 s0.30 v0.21 (V2) — el Sotobosque es UNA mancha oscura


# ---------------------------------------------------------------------------
# EXCEPCIÓN 1 — EL FUEGO. Alta saturación, siempre emisivo, siempre chico.
# Es donde se gasta todo el presupuesto de color del juego.
# ---------------------------------------------------------------------------

const BRASA := Color(1.000, 0.413, 0.120)           ## h20 s0.88
const BRASA_EMISION := Color(1.000, 0.484, 0.140)   ## h24 s0.86
const VENTANA := Color(1.000, 0.780, 0.450)         ## h36 s0.55 — más amarilla que la brasa: es una vela, no una forja
const VENTANA_EMISION := Color(1.000, 0.701, 0.360) ## h32 s0.64
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

## El terreno. Sin especular: el pasto y la tierra no reflejan nada, y un
## reflejo parejo en 360 metros de suelo es exactamente el brillo del plástico.
static func terreno() -> StandardMaterial3D:
	var m := _base(TERRENO_TINTE, 0.97)
	m.vertex_color_use_as_albedo = true
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## La cordillera: todo el color viene de los vértices, el albedo no tiñe.
static func monte() -> StandardMaterial3D:
	var m := _base(Color.WHITE, 1.0)
	m.vertex_color_use_as_albedo = true
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Follaje: copas, arbustos, cualquier verde vertical.
static func follaje(c: Color = COPA) -> StandardMaterial3D:
	var m := _base(c, 0.98)
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## La hoja del pasto en MultiMesh.
##
## `vertex_color_use_as_albedo` va prendido y NO es opcional: sin ese flag el
## color por instancia que calcula detalles.gd se descarta en el shader y las
## 26.000 matas salen todas del mismo color. O sea, el estampado que se quería
## evitar. Y por eso el albedo va en blanco: el color lo pone la instancia.
static func pasto_hoja() -> StandardMaterial3D:
	var m := _base(Color.WHITE, 1.0)
	m.vertex_color_use_as_albedo = true
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Tela y ropa: lana, lino, lona. Sin especular — a esta distancia la tela es
## una mancha de valor y nada más, y cualquier reflejo la vuelve satén.
static func tela(c: Color = ROPA_LINO) -> StandardMaterial3D:
	var m := _base(c, 0.96)
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
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


## Una ventana encendida. Dice "adentro hay alguien" más fuerte que todo el
## cielo junto. La energía la mueve `ciclo.gd` de noche (0.15 → 4.2), así que
## acá se entrega apagada: de día una ventana encendida se ve a error.
static func ventana() -> StandardMaterial3D:
	return emisivo(VENTANA, VENTANA_EMISION, 0.15)


## Los ojos del bicho. Es lo único que emite en él y es lo que lo hace visible
## entre los árboles antes de que lo veas del todo.
static func ojo_de_bicho() -> StandardMaterial3D:
	return emisivo(OJO_BICHO, OJO_BICHO_EMISION, 9.0)


## El cartel de humo. Recibe color de la partícula, no proyecta ni recibe
## sombra: está sobre el techo, nunca hay nada que se la tire, y recibirla
## cuesta una búsqueda en el atlas por píxel de humo.
static func humo() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = HUMO_TELA
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.disable_receive_shadows = true
	return m


## Una chispa: luciérnagas y cualquier partícula que sea luz y no materia.
## Sin sombreado — una luciérnaga sombreada es un punto gris.
static func chispa(emision: Color = LUCIERNAGA_EMISION, energia: float = 6.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
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
