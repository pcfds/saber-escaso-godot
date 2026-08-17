class_name Tarjeta
extends Node3D

## UNA TARJETA es un dibujo plano parado en el mundo 3D.
##
## Este archivo es dos cosas a la vez y a propósito: **una biblioteca** (las
## funciones `static` de arriba, que es lo único que se copiaría al valle si
## esto se adopta) y **un banco de pruebas** (`_ready()` para abajo, que se
## tira). No hay una tercera cosa: la ronda pedía dos archivos.
##
## ─────────────────────────────────────────────────────────────────────────
## LOS CINCO PROBLEMAS DE LA TÉCNICA, Y CÓMO LOS RESUELVE ESTE ARCHIVO
## ─────────────────────────────────────────────────────────────────────────
##
## **1. La orientación.** Hay cuatro maneras y tres están mal para esta cámara:
##
##  · `SIN`         — el plano no gira. Desaparece de canto. Sirve para cosas
##                    pegadas al piso (charcos, manchas), no para lo parado.
##  · `ESFERICO`    — `BILLBOARD_ENABLED`. Gira en los tres ejes. Mirado desde
##                    arriba **el sprite se acuesta**: el árbol deja de ser un
##                    árbol y pasa a ser una calcomanía sobre el pasto. Con la
##                    cámara de este juego (28° a 64° de inclinación) esto se
##                    rompe en todo el rango. **No usar.**
##  · `EJE_Y`       — `BILLBOARD_FIXED_Y`. Gira sólo alrededor del eje
##                    vertical. El árbol sigue parado siempre. El precio es
##                    que a 64° lo ves escorzado: el sprite mide en pantalla
##                    `cos(inclinación)` de su alto, o sea **44 % a 64°**.
##  · `EJE_Y_CORR`  — eje Y con corrección de inclinación (`_SHADER`, uniforme
##                    `correccion`). Inclina la tarjeta hacia atrás una
##                    fracción del pitch de la cámara, **pivoteando en los
##                    pies**. Con `correccion = 1` es el esférico; con `0` es
##                    el eje Y puro. El valor útil está en el medio.
##
## La cuenta que decide el valor: con corrección `c` y cámara a inclinación
## `p`, el alto aparente es `cos(p * (1 - c))`. Para que el rango 28°–64° no
## cambie el tamaño del árbol más de un 15 %:
##
##     c = 0.00 → 88 % a 28°, 44 % a 64°   (se achica a la mitad: se nota)
##     c = 0.35 → 95 % a 28°, 75 % a 64°
##     c = 0.55 → 98 % a 28°, 88 % a 64°   ← el que recomienda este archivo
##     c = 1.00 → 100 % siempre, y se acuesta
##
## `0.55` es el punto donde la silueta se mantiene legible desde arriba sin
## que la base del árbol se despegue del piso. **La base no se despega nunca
## porque el pivote está en los pies** (`center_offset`, ver `malla()`): ése
## es el truco que hace que la corrección sea usable.
##
## **2. Luz y sombra.** Una tarjeta sin sombreado se ve pegoteada encima del
## mundo. Dos cosas la anclan y son distintas:
##
##  · **Que reciba el sol.** El problema es la normal: un plano tiene una sola
##    normal y si apunta a la cámara, el sprite se prende y se apaga cuando
##    girás. El uniforme `normal_arriba` mezcla la normal entre "de frente" y
##    "para arriba". En `0.6` el árbol se sombrea **como el pasto de al lado**,
##    que es lo que hace que pertenezca a la escena.
##  · **Que tire sombra al piso.** Y acá está la trampa: **una sombra de
##    material con alfa mezclada sale rectangular.** El mapa de sombras no
##    mezcla, escribe profundidad; si el material no descarta el fondo
##    transparente, el motor sombrea el cuadrado entero. Con recorte por alfa
##    el `discard` corre también en el paso de sombra y la sombra sale con la
##    forma del dibujo. **Es la razón número uno para usar recorte.**
##
## Segunda trampa, medida acá: **en el paso de sombra, `INV_VIEW_MATRIX` es la
## del sol, no la de la cámara.** O sea que la tarjeta se orienta hacia el sol
## para tirar la sombra. Eso no es un error: es lo que hace que la sombra sea
## la silueta completa del dibujo en vez de una línea. Pero significa que
## **sombra y sprite no son el mismo plano** y hay que saberlo.
##
## **3. El corte del alfa.** Cuatro modos, y la diferencia se ve cuando dos
## tarjetas se cruzan:
##
##  · `MEZCLA`  — pasa transparente. Se ordena **por objeto**, no por píxel:
##                dos árboles que se cruzan se dibujan uno entero antes que el
##                otro y **al girar la cámara se intercambian de golpe**. En
##                MultiMesh es peor todavía: el motor ordena la caja entera,
##                así que un bosque de 4000 instancias tiene UN orden para
##                todas. **Inservible para vegetación.**
##  · `RECORTE` — alfa scissor. Pasa opaco, escribe profundidad, se ordena por
##                píxel con el z-buffer. **Es el correcto.** El precio es el
##                borde duro (que con pixel art es lo que querés igual).
##  · `HASH`    — dithering. Ordena bien y da borde suave, pero necesita TAA
##                para no verse granulado, y este proyecto no la tiene puesta.
##  · `PREPASO` — mezclada con paso previo de profundidad. Borde suave y orden
##                correcto, pero **cuesta un paso de geometría extra** y sigue
##                sin resolver el orden entre transparentes.
##
## **4. El borroso, y el número que importa.** La cámara es FOV 42° vertical y
## va de 12 a 68 m (`jugador.gd`). A 1080 de alto eso da:
##
##     distancia   metros de alto en pantalla   píxeles por metro
##       12 m               9,2                     117
##       27 m              20,7                      52
##       68 m              52,2                      21
##
## Un sprite de 32 px que mide 2 m de alto tiene 16 téxeles por metro. O sea:
##
##     a 12 m → 7,3 píxeles de pantalla por téxel  (ampliado 7×)
##     a 27 m → 3,3
##     a 68 m → 1,3                                (ya casi 1:1)
##
## **El punto 1:1 de un sprite de 32 px cae a 88 m, o sea afuera del rango.**
## Traducido: el arte de 32 px de Crawl es correcto en el extremo lejano y
## está ampliado 7 veces en el extremo cercano. Si el pixel art tiene que
## verse nítido a 12 m, **el arte final necesita 4× esa resolución** — figuras
## de 128 px de alto, árboles de 128–192. Eso no invalida la técnica; es el
## presupuesto de arte que la técnica pide, y hay que decirlo antes.
##
## El filtro va en `NEAREST_WITH_MIPMAPS`: sin interpolar (el píxel es duro) y
## con mipmaps (sin ellos, a 68 m el sprite chispea al moverse la cámara).
## El ajuste a grilla de píxel (`ajuste_pixel`) redondea el vértice al píxel
## de pantalla; **es honesto decir que sirve poco acá**: con zoom libre de 12 a
## 68 m la escala del sprite en pantalla es continua y no hay una grilla a la
## que alinearse. Alinear de verdad exige escala fija, y escala fija exige
## sacar el zoom. Queda el uniforme para que se pueda ver la diferencia.
##
## **5. Cuánto cuesta.** Una tarjeta son 2 triángulos. Un árbol de Kenney son
## 54 a 62. `campo()` arma un MultiMesh con `Texture2DArray`, y ahí está la
## parte buena: **como todos los sprites miden lo mismo (32×32), entran en un
## arreglo de texturas y el índice del sprite viaja en los datos por
## instancia.** Un solo MultiMesh, una sola llamada de dibujo, y adentro puede
## haber nueve árboles distintos, arbustos y gente mezclados.
##
## Eso es mejor que un atlas: **un atlas con mipmaps sangra entre celdas** (el
## nivel 4 de un atlas de 32 px ya mezcla vecinos) y el arreglo no, porque
## cada capa tiene sus propios mipmaps.
##
## Con las mallas de hoy la vegetación necesita **tres MultiMesh por baldosa**
## porque hay tres mallas distintas. Con tarjetas necesita **uno**, y no por
## baldosa de tipo sino por baldosa a secas.
##
## ─────────────────────────────────────────────────────────────────────────
## LO QUE SE MIDIÓ DE VERDAD, Y LO QUE NO
## ─────────────────────────────────────────────────────────────────────────
##
## Acá no hay GPU: Vulkan corre por software (llvmpipe) sobre WSLg. Sí hay
## pantalla, así que el banco **se renderiza de verdad** y las capturas de
## `--capturas` son imágenes reales, no una promesa. Lo que NO vale de acá son
## los milisegundos como número absoluto.
##
## Medido, 640×360, `-- --medir`:
##
##     qué             cuántas   armar ms   cuadro ms   primitivas   llamadas
##     tarjeta            1000        0.6       15.94        22 760         23
##     tarjeta            4000        2.3       19.36        34 760         23
##     tarjeta           16000        9.0       40.00        82 760         23
##     tarjeta           64000       34.0      101.62       274 760         23
##     malla Kenney       4000        2.7       63.28       930 760         25
##
##  · **Las llamadas de dibujo no se mueven**: 64 000 tarjetas son UNA llamada,
##    igual que 1000. Eso es el MultiMesh, y ya lo hace la vegetación de hoy.
##  · **La misma cantidad cuesta 3,3× menos en tarjetas que en mallas** (19,4
##    contra 63,3 ms) con **27× menos primitivas** (34 760 contra 930 760).
##    Las primitivas son un número exacto y no dependen del hardware.
##  · **Escala lineal**: cada tarjeta cuesta ~1,3 µs; cada árbol de Kenney,
##    ~12 µs. 16 000 tarjetas todavía salen más baratas que 4000 mallas.
##  · El valle de hoy tiene 4945 plantas y 235 594 triángulos
##    (`prueba_vegetacion.tscn`). Las mismas 4945 en tarjetas son 9890.
##
## Verificado mirando las capturas:
##
##  · La sombra de `RECORTE` **tiene la forma del árbol**; la de `MEZCLA` es
##    **un rectángulo**. Se ve en el preset 6, comparando las dos columnas.
##  · Un MultiMesh de 4000 tarjetas mezcladas (`-- --mezcla`) pierde las
##    sombras enteras **y se ordena mal**: arbustos y gente que están detrás se
##    pintan encima de las copas. Con recorte, no.
##  · El giro `EJE_Y` a 64° se achata a la mitad, y `EJE_Y_CORR 0.55` no.
##    Coincide con la cuenta de arriba.
##
## **NO verificado, y hace falta una persona con pantalla:**
##
##  · **El chispeo.** Mipmaps sí o no sólo se juzga en movimiento, y las
##    capturas son fijas. En una foto a 55 m `NEAREST` y `LINEAR` casi no se
##    distinguen.
##  · **El parpadeo de `MEZCLA` al girar la cámara.** Se demostró el problema
##    en MultiMesh, no el intercambio entre dos tarjetas sueltas.
##  · **Si el resultado gusta.** Es una decisión de dirección y necesita ojos.
##  · Cualquier número de rendimiento en una máquina con GPU.
##
## ─────────────────────────────────────────────────────────────────────────
## SI ESTO SE ADOPTA
## ─────────────────────────────────────────────────────────────────────────
##
## Lo que se copia de acá al valle son cuatro funciones: `malla()`,
## `material()`, `una()` y `campo()`, más `CODIGO`. Nada más. Y lo que hay que
## saber antes de empezar:
##
##  · **`vegetacion.gd` se conserva casi entero.** El campo de densidad, las
##    zonas, las baldosas y el raleo por `visible_instance_count` no dependen
##    de la malla. Cambia `_baldosa()`: en vez de tres MultiMesh por baldosa,
##    uno, y el tipo de planta pasa a ser un índice de capa. **Es la parte
##    barata.**
##  · **`figura.gd` se tira entero.** Son 622 líneas de cuerpo articulado
##    animado con senos, y una tarjeta no tiene articulaciones. Lo que hoy
##    hace la animación procedural pasa a hacerlo el arte: cuadros de sprite.
##    **Y ahí está el costo real de esta decisión** — hoy la variedad de gente
##    sale gratis de un algoritmo, y después hay que dibujarla.
##  · **El arte de 32 px no alcanza.** A 12 m está ampliado 7 veces. Ver el
##    punto 4. Crawl sirve para probar la técnica, no para envolver el juego.
##
## ─────────────────────────────────────────────────────────────────────────
## CÓMO CORRER EL BANCO
## ─────────────────────────────────────────────────────────────────────────
##
##     godot escenas/prueba_2d.tscn                 mirarlo (hace falta pantalla)
##     godot --headless --quit-after 300 …          que no explote
##     godot --headless --quit-after 900 … -- --medir     la tabla de costos
##     godot escenas/prueba_2d.tscn -- --capturas   guarda PNG por preset
##     godot escenas/prueba_2d.tscn -- --mezcla     el campo con alfa mezclada,
##                                                  que es el control de por qué
##                                                  hay que usar recorte
##
## Con pantalla: arrastrar con el botón izquierdo gira, la rueda acerca, las
## teclas 1 a 6 saltan a los presets de cámara, `F` imprime el informe,
## `B` cicla la corrección de inclinación, `A` cicla el modo de alfa.

# ══════════════════════════════════════════════════════════════════════════
#  BIBLIOTECA. Esto es lo único que se copiaría al valle.
# ══════════════════════════════════════════════════════════════════════════

## Cómo se orienta la tarjeta.
enum Giro {
	SIN,        ## no gira. Para cosas tiradas en el piso.
	ESFERICO,   ## los tres ejes. Se acuesta desde arriba. No usar para lo parado.
	EJE_Y,      ## sólo el eje vertical. Correcto pero escorzado desde arriba.
	EJE_Y_CORR, ## eje vertical + corrección de inclinación. El recomendado.
}

## Cómo se corta el alfa.
enum Alfa {
	MEZCLA,   ## transparencia mezclada. Se ordena por objeto: parpadea.
	RECORTE,  ## alfa scissor. Se ordena por profundidad. El recomendado.
	HASH,     ## dithering. Necesita TAA.
	PREPASO,  ## mezclada con paso previo de profundidad. Cuesta un paso más.
}

## Las tarjetas del valle miden todas 32 px porque el arte de Crawl mide 32 px.
## Si algún día el arte sube de resolución, esto sube con él y nada más cambia.
const LADO_TEXEL := 32

## Valor recomendado de corrección de inclinación. Ver el comentario de arriba.
const CORRECCION := 0.55

## Cuánto se mezcla la normal hacia arriba para que el sprite se sombree como
## el terreno en vez de prenderse y apagarse al girar la cámara.
const NORMAL_ARRIBA := 0.6

## El umbral del recorte. 0.5 sobre arte con borde limpio; más bajo si el arte
## trae antialias en el borde y no querés comértelo.
const UMBRAL := 0.4


## El shader de la tarjeta. Hace las cuatro cosas que un `StandardMaterial3D`
## no puede hacer juntas: corrección de inclinación, arreglo de texturas por
## instancia, normal mezclada hacia arriba y ajuste a grilla de píxel.
const CODIGO := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled, shadows_disabled_off;

uniform sampler2DArray hojas : source_color, filter_nearest_mipmap, repeat_disable;
uniform float correccion : hint_range(0.0, 1.0) = 0.55;
uniform float normal_arriba : hint_range(0.0, 1.0) = 0.6;
uniform float umbral : hint_range(0.0, 1.0) = 0.4;
uniform float ajuste_pixel : hint_range(0.0, 1.0) = 0.0;
uniform float capa_fija = 0.0;
uniform bool por_instancia = false;
uniform vec4 tinte : source_color = vec4(1.0);

varying float capa;

void vertex() {
	capa = por_instancia ? round(INSTANCE_CUSTOM.x * 255.0) : capa_fija;

	// El eje que mira a la cámara. En el paso de sombra esto es el eje del
	// SOL, no el de la cámara: por eso la sombra sale con la silueta entera
	// del dibujo. Es a propósito.
	vec3 hacia = normalize(INV_VIEW_MATRIX[2].xyz);
	vec3 arriba_cam = normalize(INV_VIEW_MATRIX[1].xyz);
	vec3 arriba = normalize(mix(vec3(0.0, 1.0, 0.0), arriba_cam, correccion));

	// Cuando la cámara mira casi a plomo, `arriba` y `hacia` se alinean y el
	// producto vectorial se degenera. A 64° todavía falta mucho, pero el
	// respaldo evita el NaN si alguien sube el tope de inclinación.
	vec3 der = cross(arriba, hacia);
	float largo = length(der);
	der = largo > 0.001 ? der / largo : vec3(1.0, 0.0, 0.0);
	vec3 frente = normalize(cross(der, arriba));

	// La escala viene en la transformación de la instancia y hay que
	// rescatarla a mano, porque acá se reemplaza la matriz entera.
	vec3 esc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz),
			length(MODEL_MATRIX[2].xyz));
	mat4 m = mat4(vec4(der * esc.x, 0.0), vec4(arriba * esc.y, 0.0),
			vec4(frente * esc.z, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * m;

	// La normal no es la del plano: se mezcla hacia arriba para que el sprite
	// tome el sol igual que el pasto sobre el que está parado.
	vec3 n = normalize(mix(frente, vec3(0.0, 1.0, 0.0), normal_arriba));
	MODELVIEW_NORMAL_MATRIX = mat3(VIEW_MATRIX);
	NORMAL = n;
}

void fragment() {
	vec4 c = texture(hojas, vec3(UV, capa));
	ALBEDO = c.rgb * tinte.rgb;
	ALPHA = c.a * tinte.a;
	ALPHA_SCISSOR_THRESHOLD = umbral;
}
"""

static var _shader: Shader = null
static var _shader_mezcla: Shader = null


## El shader, una sola vez para todo el juego.
static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CODIGO
	return _shader


## El mismo shader **sin la línea del recorte**, o sea con transparencia
## mezclada. Existe sólo para poder mostrar el problema al lado de la
## solución: sacando `ALPHA_SCISSOR_THRESHOLD` el material se va al paso
## transparente y un MultiMesh entero pasa a ordenarse como un solo objeto.
static func shader_mezcla() -> Shader:
	if _shader_mezcla == null:
		_shader_mezcla = Shader.new()
		_shader_mezcla.code = CODIGO.replace(
			"\tALPHA_SCISSOR_THRESHOLD = umbral;", "")
	return _shader_mezcla


## La malla de una tarjeta. **El origen va en los pies, no en el centro.**
##
## Es la línea más importante del archivo: con el origen abajo, el billboard
## y la corrección de inclinación pivotean sobre el piso y la base del árbol
## no se despega nunca. Con el origen en el centro (que es lo que hace
## `QuadMesh` por defecto) el árbol flota al inclinarse.
static func malla(ancho: float, alto: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(ancho, alto)
	q.center_offset = Vector3(0.0, alto * 0.5, 0.0)
	return q


## Material de tarjeta con `StandardMaterial3D`, que es lo que hay sin escribir
## shader. Sirve para los giros `SIN`, `ESFERICO` y `EJE_Y`; **no puede hacer
## la corrección de inclinación** ni leer un arreglo de texturas.
static func material_simple(tex: Texture2D, giro: Giro, alfa: Alfa,
		nitido := true, mipmaps := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.roughness = 1.0

	if nitido:
		m.texture_filter = (BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			if mipmaps else BaseMaterial3D.TEXTURE_FILTER_NEAREST)
	else:
		m.texture_filter = (BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			if mipmaps else BaseMaterial3D.TEXTURE_FILTER_LINEAR)

	match alfa:
		Alfa.MEZCLA:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		Alfa.RECORTE:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = UMBRAL
		Alfa.HASH:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
			m.alpha_hash_scale = 1.0
		Alfa.PREPASO:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS

	match giro:
		Giro.SIN:
			m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		Giro.ESFERICO:
			m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			m.billboard_keep_scale = true
		_:
			m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
			m.billboard_keep_scale = true
	return m


## Material de tarjeta con shader propio. `hojas` es el arreglo de texturas;
## `capa` elige cuál, salvo que se prenda `por_instancia` (MultiMesh).
static func material(hojas: Texture2DArray, capa := 0, correccion := CORRECCION,
		por_instancia := false, mezclado := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader_mezcla() if mezclado else shader()
	m.set_shader_parameter("hojas", hojas)
	m.set_shader_parameter("capa_fija", float(capa))
	m.set_shader_parameter("por_instancia", por_instancia)
	m.set_shader_parameter("correccion", correccion)
	m.set_shader_parameter("normal_arriba", NORMAL_ARRIBA)
	m.set_shader_parameter("umbral", UMBRAL)
	m.set_shader_parameter("ajuste_pixel", 0.0)
	m.set_shader_parameter("tinte", Color.WHITE)
	return m


## Una tarjeta suelta.
static func una(hojas: Texture2DArray, capa: int, ancho: float, alto: float,
		correccion := CORRECCION) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla(ancho, alto)
	mi.material_override = material(hojas, capa, correccion)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


## Un campo de tarjetas en un solo MultiMesh y una sola llamada de dibujo.
##
## `puestas` es un arreglo de `Transform3D` (la escala del transform decide el
## tamaño de cada una) y `capas` el índice de sprite de cada instancia. Las dos
## listas van en paralelo.
static func campo(hojas: Texture2DArray, puestas: Array[Transform3D],
		capas: PackedInt32Array, ancho := 1.0, alto := 1.0,
		mezclado := false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	# EL MATERIAL VA EN LA MALLA, NO EN EL NODO — `MultiMeshInstance3D` ignora
	# `material_override` en algunos caminos de render. Es la misma trampa que
	# ya está anotada en `vegetacion.gd:853`.
	var q := malla(ancho, alto)
	q.material = material(hojas, 0, CORRECCION, true, mezclado)
	mm.mesh = q
	mm.instance_count = puestas.size()
	for i in puestas.size():
		mm.set_instance_transform(i, puestas[i])
		# El índice de sprite viaja en el rojo de los datos por instancia,
		# normalizado a 0–1 porque no todos los caminos de MultiMesh guardan
		# el dato como float de 32 bits.
		mm.set_instance_custom_data(i, Color(float(capas[i]) / 255.0, 0.0, 0.0, 0.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mmi


## Junta una lista de PNG de 32×32 en un `Texture2DArray` con mipmaps propios
## por capa. Devuelve `[arreglo, nombres]`.
##
## Un arreglo y no un atlas: **el atlas sangra entre celdas al mipmapear** y
## el arreglo no. Con sprites de 32 px eso importa desde el nivel 3.
static func hojas_de(rutas: PackedStringArray) -> Texture2DArray:
	var imgs: Array[Image] = []
	for r in rutas:
		var t: Texture2D = load(r)
		if t == null:
			continue
		var img := t.get_image()
		if img == null:
			continue
		img = img.duplicate()
		img.clear_mipmaps()
		img.convert(Image.FORMAT_RGBA8)
		if img.get_width() != LADO_TEXEL or img.get_height() != LADO_TEXEL:
			img.resize(LADO_TEXEL, LADO_TEXEL, Image.INTERPOLATE_NEAREST)
		img.generate_mipmaps()
		imgs.append(img)
	var arr := Texture2DArray.new()
	if not imgs.is_empty():
		arr.create_from_images(imgs)
	return arr


## Todos los PNG que hay debajo de una carpeta, ordenados. Aguanta tanto el
## proyecto abierto (`.png`) como el exportado (`.png.import`).
static func pngs_de(carpeta: String) -> PackedStringArray:
	var salida := PackedStringArray()
	var d := DirAccess.open(carpeta)
	if d == null:
		return salida
	d.list_dir_begin()
	var vistos := {}
	var n := d.get_next()
	while n != "":
		if d.current_is_dir():
			if not n.begins_with("."):
				salida.append_array(pngs_de(carpeta.path_join(n)))
		elif n.ends_with(".png") or n.ends_with(".png.import"):
			# En el proyecto abierto están los dos, el `.png` y su `.import`.
			# En el exportado sólo el `.import`. Se cuenta una vez.
			vistos[carpeta.path_join(n.trim_suffix(".import"))] = true
		n = d.get_next()
	d.list_dir_end()
	var v := vistos.keys()
	v.sort()
	salida.append_array(PackedStringArray(v))
	return salida


# ══════════════════════════════════════════════════════════════════════════
#  BANCO DE PRUEBAS. Esto se tira.
# ══════════════════════════════════════════════════════════════════════════

const CARPETA := "res://assets/2d/dcss"

# Los mismos límites de cámara que `jugador.gd`. Si allá cambian, acá también
# o el banco deja de probar el rango real.
const PITCH_MIN := 28.0
const PITCH_MAX := 64.0
const DIST_MIN := 12.0
const DIST_MAX := 68.0
const FOV := 42.0

# Terreno del banco: chico, con relieve de verdad, porque una tarjeta sobre un
# piso plano no prueba nada — la mitad de los problemas aparecen en pendiente.
const LADO := 170.0
const PASO := 2.5

# El campo de esfuerzo va en la mitad de atrás, para no tapar las filas de
# prueba. Sin esto, 4000 tarjetas se comen el banco entero.
const CAMPO_Z0 := 34.0
const CAMPO_Z1 := 84.0
const CAMPO_X := 62.0

## Los presets de cámara del banco: nombre, distancia, inclinación, giro y a
## qué está mirando. Cubren las dos esquinas del rango real (12 m a 28°, 68 m
## a 64°) y las tres vistas que hacen falta para juzgar cada fila.
const PRESETS := [
	["cerca y bajo (12 m, 28°)", 12.0, 28.0, 0.12, Vector3(7.5, 2.5, -24.0)],
	["cerca y alto (12 m, 64°)", 12.0, 64.0, 0.12, Vector3(7.5, 2.5, -24.0)],
	["los cuatro giros a 28°", 50.0, 28.0, 0.10, Vector3(0.0, 3.0, -24.0)],
	["los cuatro giros a 64°", 50.0, 64.0, 0.10, Vector3(0.0, 3.0, -24.0)],
	["alfa, filtro y Kenney", 55.0, 45.0, 0.10, Vector3(0.0, 3.0, 6.0)],
	["la sombra: mezcla vs recorte", 22.0, 30.0, 0.10, Vector3(-15.0, 2.0, -8.0)],
	["el campo, 68 m a 56°", 68.0, 56.0, 0.10, Vector3(0.0, 3.0, 56.0)],
]

## Los ensayos de costo: qué se dibuja y cuántos. El escalón de 64 000 es a
## propósito absurdo, y el último es el control — **la misma cantidad con la
## malla de Kenney que se usa hoy**, que es contra lo que hay que comparar.
const ENSAYOS := [
	["tarjeta", 1000],
	["tarjeta", 4000],
	["tarjeta", 16000],
	["tarjeta", 64000],
	["malla Kenney", 4000],
]

var _hojas: Texture2DArray
var _rutas := PackedStringArray()
var _indice := {}          ## nombre de archivo → capa

var _camara: Camera3D
var _yaw := 0.6
var _pitch := deg_to_rad(56.0)
var _dist := 27.0
var _foco := Vector3(0.0, 2.0, -4.0)
var _girando := false

var _campo: MultiMeshInstance3D
var _sueltas: Array[MeshInstance3D] = []
var _materiales_shader: Array[ShaderMaterial] = []

var _ms_hojas := 0.0
var _ms_campo := 0.0
var _sprites := 4000

var _medir := false
var _mezcla := false
var _capturar := false
var _cuadro := 0
var _paso := 0
var _t_paso := 0.0
var _cuadros_paso := 0
var _tabla: Array = []


func _ready() -> void:
	_leer_argumentos()

	var t0 := Time.get_ticks_usec()
	_rutas = pngs_de(CARPETA)
	for i in _rutas.size():
		_indice[_rutas[i].get_file()] = i
	_hojas = hojas_de(_rutas)
	_ms_hojas = (Time.get_ticks_usec() - t0) / 1000.0

	if _rutas.is_empty():
		push_error("No hay sprites en %s. ¿Corriste `godot --headless --import`?"
			% CARPETA)
		return

	_armar_mundo()
	_armar_fila_giro()
	_armar_fila_alfa()
	_armar_fila_filtro()
	_armar_comparacion()
	_rehacer_campo(_sprites)

	if not _medir:
		informe()


func _leer_argumentos() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--medir":
			_medir = true
		elif a == "--capturas":
			_capturar = true
		elif a == "--mezcla":
			_mezcla = true
		elif a.begins_with("--sprites="):
			_sprites = maxi(0, int(a.split("=")[1]))


# ── el mundo ──────────────────────────────────────────────────────────────

## Altura del terreno del banco. Ondas cruzadas y nada más: sólo hace falta
## que haya pendiente, no que sea un valle.
func _alto(x: float, z: float) -> float:
	return (sin(x * 0.07) * 1.6 + cos(z * 0.055) * 1.9
		+ sin((x + z) * 0.021) * 3.2)


func _armar_mundo() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.52, 0.60)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.46, 0.52, 0.62)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	we.environment = env
	add_child(we)

	# El mismo ángulo de sol que el valle: -44°, que es el que no deja la
	# banda negra (ver CLAUDE.md).
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	sol.rotation_degrees = Vector3(-44.0, 32.0, 0.0)
	sol.light_energy = 1.15
	sol.light_color = Color(1.0, 0.94, 0.84)
	sol.shadow_enabled = true
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sol.directional_shadow_max_distance = 120.0
	sol.shadow_normal_bias = 0.6
	add_child(sol)

	add_child(_terreno())

	_camara = Camera3D.new()
	_camara.name = "Camara"
	_camara.fov = FOV
	_camara.near = 0.2
	_camara.far = 900.0
	add_child(_camara)
	_camara.current = true
	_mover_camara()


## Terreno con `SurfaceTool`. Devanado `[0,1,2]/[0,2,3]` y normales generadas,
## que es la trampa ya anotada en CLAUDE.md: al revés el piso no recibe sol.
func _terreno() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(LADO / PASO)
	for i in n:
		for j in n:
			var x0 := -LADO * 0.5 + i * PASO
			var z0 := -LADO * 0.5 + j * PASO
			var x1 := x0 + PASO
			var z1 := z0 + PASO
			# El orden de las esquinas es el de `valle.gd:262` y no otro: al
			# revés el devanado se invierte, las normales apuntan para abajo
			# y el piso no se dibuja. Ya me lo comí una vez en esta ronda.
			var v := [
				Vector3(x0, _alto(x0, z0), z0),
				Vector3(x1, _alto(x1, z0), z0),
				Vector3(x1, _alto(x1, z1), z1),
				Vector3(x0, _alto(x0, z1), z1),
			]
			for k: int in [0, 1, 2, 0, 2, 3]:
				st.add_vertex(v[k])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Terreno"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.31, 0.38, 0.25)
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# `SurfaceTool.set_material()` no aplica: va en el nodo (CLAUDE.md).
	mi.material_override = m
	return mi


func _capa(archivo: String) -> int:
	return _indice.get(archivo, 0)


func _poner(nodo: Node3D, x: float, z: float) -> void:
	nodo.position = Vector3(x, _alto(x, z), z)


func _cartel(texto: String, x: float, z: float, y := 0.2) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = 96
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.no_depth_test = false
	l.modulate = Color(0.95, 0.95, 0.85)
	l.outline_size = 24
	add_child(l)
	l.position = Vector3(x, _alto(x, z) + y, z)


# ── fila 1: los cuatro giros ──────────────────────────────────────────────

func _armar_fila_giro() -> void:
	var z := -24.0
	var arbol := _capa("tree_2_red.png")
	var gente := _capa("human_new.png")
	var casos := [
		["SIN", Giro.SIN, 0.0],
		["ESFERICO", Giro.ESFERICO, 1.0],
		["EJE_Y", Giro.EJE_Y, 0.0],
		["EJE_Y_CORR 0.55", Giro.EJE_Y_CORR, CORRECCION],
	]
	for i in casos.size():
		var x := -22.5 + i * 15.0
		var etiqueta: String = casos[i][0]
		var giro: Giro = casos[i][1]
		var corr: float = casos[i][2]

		# El árbol va con shader en los cuatro casos para que la comparación
		# sea del giro y de nada más. `SIN` y `ESFERICO` se piden al shader
		# con la corrección en los extremos, salvo `SIN`, que no billboardea.
		var a := (_tarjeta_fija(arbol, 4.2, 6.4) if giro == Giro.SIN
			else una(_hojas, arbol, 4.2, 6.4, corr))
		add_child(a)
		_poner(a, x, z)
		_sueltas.append(a)
		_anotar(a)

		var p := (_tarjeta_fija(gente, 1.5, 2.1) if giro == Giro.SIN
			else una(_hojas, gente, 1.5, 2.1, corr))
		add_child(p)
		_poner(p, x + 3.0, z + 1.5)
		_sueltas.append(p)
		_anotar(p)

		_cartel(etiqueta, x + 1.5, z - 3.0, 7.2)


## Una tarjeta que no gira: mismo shader con la matriz sin tocar. Se arma con
## `StandardMaterial3D` porque es el caso donde el shader no aporta nada.
func _tarjeta_fija(capa: int, ancho: float, alto: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla(ancho, alto)
	var t: Texture2D = load(_rutas[capa])
	mi.material_override = material_simple(t, Giro.SIN, Alfa.RECORTE)
	return mi


func _anotar(mi: MeshInstance3D) -> void:
	var sm := mi.material_override as ShaderMaterial
	if sm != null:
		_materiales_shader.append(sm)


# ── fila 2: los cuatro modos de alfa ──────────────────────────────────────

## Tres tarjetas encimadas y cruzadas a propósito. Es la única forma de ver el
## problema de orden: separadas, los cuatro modos se ven igual.
func _armar_fila_alfa() -> void:
	var z := -8.0
	var caras := [_capa("tree_1_yellow.png"), _capa("tree_2_lightred.png"),
		_capa("mangrove_2.png")]
	var casos := [
		["MEZCLA", Alfa.MEZCLA],
		["RECORTE", Alfa.RECORTE],
		["HASH", Alfa.HASH],
		["PREPASO", Alfa.PREPASO],
	]
	for i in casos.size():
		var x := -22.5 + i * 15.0
		for k in 3:
			var mi := MeshInstance3D.new()
			mi.mesh = malla(4.2, 6.4)
			var t: Texture2D = load(_rutas[caras[k]])
			mi.material_override = material_simple(t, Giro.EJE_Y, casos[i][1])
			add_child(mi)
			_poner(mi, x + k * 1.1, z + k * 0.9)
			_sueltas.append(mi)
		_cartel(casos[i][0], x + 1.1, z - 3.0, 7.2)


# ── fila 3: filtro y mipmaps ──────────────────────────────────────────────

func _armar_fila_filtro() -> void:
	var z := 6.0
	var casos := [
		["NEAREST", true, false],
		["NEAREST+mip", true, true],
		["LINEAR", false, false],
		["LINEAR+mip", false, true],
	]
	# Un árbol y no una fachada: para juzgar el filtro hace falta detalle fino,
	# y `shop_general` a 45° de inclinación es un cajón rojo.
	var quien := _capa("tree_2_yellow.png")
	for i in casos.size():
		var x := -22.5 + i * 15.0
		var mi := MeshInstance3D.new()
		mi.mesh = malla(4.2, 6.4)
		var t: Texture2D = load(_rutas[quien])
		mi.material_override = material_simple(t, Giro.EJE_Y, Alfa.RECORTE,
			casos[i][1], casos[i][2])
		add_child(mi)
		_poner(mi, x, z)
		_sueltas.append(mi)
		_cartel(casos[i][0], x, z - 3.0, 6.8)


# ── comparación con las mallas de Kenney ──────────────────────────────────

const KENNEY := "res://assets/kenney/naturaleza/tree_default.glb"

var _tri_kenney := 0


## Un árbol de Kenney al lado de un árbol tarjeta, a la misma altura. Es la
## comparación que pide la ronda y también la única forma de ver de un vistazo
## si el cambio de estilo es lo que se quería.
func _armar_comparacion() -> void:
	var z := 20.0
	var arbol := _capa("tree_1_red.png")
	var a := una(_hojas, arbol, 4.2, 6.4)
	add_child(a)
	_poner(a, -4.0, z)
	_sueltas.append(a)
	_anotar(a)
	_cartel("tarjeta · 2 tri", -4.0, z - 3.0, 7.0)

	var esc := load(KENNEY) as PackedScene
	if esc == null:
		_cartel("(no está %s)" % KENNEY.get_file(), 6.0, z - 3.0, 7.0)
		return
	var k := esc.instantiate()
	add_child(k)
	if k is Node3D:
		var kn := k as Node3D
		kn.position = Vector3(8.0, _alto(8.0, z), z)
		# A la MISMA altura que la tarjeta. Comparar un árbol de 2 m con uno
		# de 6,4 m no compara nada.
		var m := _kenney_malla()
		var h: float = maxf(m.get_aabb().size.y, 0.001)
		kn.scale = Vector3.ONE * (6.4 / h)
	_tri_kenney = _triangulos(k)
	_cartel("Kenney · %d tri" % _tri_kenney, 8.0, z - 3.0, 7.0)


## El control del ensayo: el mismo campo con la malla de Kenney que se usa
## hoy. Mismo MultiMesh, misma cantidad, misma cámara — cambia la malla y el
## material y nada más.
func _campo_kenney(puestas: Array[Transform3D]) -> MultiMeshInstance3D:
	var malla_k := _kenney_malla()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla_k
	mm.instance_count = puestas.size()
	for i in puestas.size():
		# La malla de Kenney mide ~2 m: se escala al alto que le tocaba a la
		# tarjeta para que el campo tape la misma cantidad de pantalla.
		var t := puestas[i]
		var alto := t.basis.get_scale().y
		mm.set_instance_transform(i, Transform3D(
			Basis().scaled(Vector3.ONE * alto * 0.5), t.origin))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mmi


var _malla_kenney: Mesh = null


## La malla de Kenney sola, sin el nodo. **El nodo se libera en el acto**: una
## escena instanciada y nunca agregada al árbol no la limpia nadie, y aparece
## como RID filtrado al cerrar. Es la misma clase de fuga que ya está anotada
## en CLAUDE.md, y ésta sí es nuestra.
func _kenney_malla() -> Mesh:
	if _malla_kenney == null:
		var esc := load(KENNEY) as PackedScene
		if esc != null:
			var raiz := esc.instantiate()
			_malla_kenney = _primera_malla(raiz)
			raiz.free()
		if _malla_kenney == null:
			_malla_kenney = QuadMesh.new()
	return _malla_kenney


func _primera_malla(n: Node) -> Mesh:
	if n == null:
		return QuadMesh.new()
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return (n as MeshInstance3D).mesh
	for h in n.get_children():
		var m := _primera_malla(h)
		if not (m is QuadMesh):
			return m
	return QuadMesh.new()


func _triangulos(n: Node) -> int:
	var t := 0
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m != null:
			for s in m.get_surface_count():
				var ar := m.surface_get_arrays(s)
				var idx: PackedInt32Array = ar[Mesh.ARRAY_INDEX]
				if idx.size() > 0:
					t += idx.size() / 3
				else:
					t += (ar[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	for h in n.get_children():
		t += _triangulos(h)
	return t


# ── el campo: el ensayo de costo ──────────────────────────────────────────

## Reparte `n` tarjetas por el terreno, mezclando árboles, arbustos y gente en
## **un solo MultiMesh**. Que se pueda mezclar es la mitad de la ventaja: con
## mallas harían falta tres MultiMesh.
func _rehacer_campo(n: int, con_malla := false) -> void:
	if _campo != null:
		_campo.queue_free()
		_campo = null
	if n <= 0:
		_ms_campo = 0.0
		return

	var t0 := Time.get_ticks_usec()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260817

	# Un reparto plausible: mucho arbusto, bastante árbol, poca gente. Los
	# nombres se resuelven contra el índice y si falta alguno, cae en 0.
	var repertorio := PackedInt32Array()
	for nombre: String in ["tree_1_red.png", "tree_1_yellow.png",
			"tree_2_red.png", "tree_2_lightred.png", "mangrove_1.png",
			"mangrove_2.png", "mangrove_3.png"]:
		for _r in 4:
			repertorio.append(_capa(nombre))
	for nombre: String in ["bush_2.png", "bush_3.png", "bush_4.png",
			"briar_patch.png", "plant.png", "deathcap.png"]:
		for _r in 6:
			repertorio.append(_capa(nombre))
	for nombre: String in ["human_new.png", "orc_new.png", "dwarf_new.png",
			"halfling_new.png", "wizard.png"]:
		repertorio.append(_capa(nombre))

	var puestas: Array[Transform3D] = []
	puestas.resize(n)
	var capas := PackedInt32Array()
	capas.resize(n)
	for i in n:
		var x := rng.randf_range(-CAMPO_X, CAMPO_X)
		var z := rng.randf_range(CAMPO_Z0, CAMPO_Z1)
		var c: int = repertorio[rng.randi() % repertorio.size()]
		# El alto sale del tipo: los primeros 28 del repertorio son árboles.
		var alto := (rng.randf_range(4.4, 7.2) if c in repertorio.slice(0, 28)
			else rng.randf_range(0.8, 1.9))
		var tr := Transform3D(Basis().scaled(Vector3(alto * 0.75, alto, 1.0)),
			Vector3(x, _alto(x, z), z))
		puestas[i] = tr
		capas[i] = c

	if con_malla:
		_campo = _campo_kenney(puestas)
		_campo.name = "Campo"
		add_child(_campo)
		_ms_campo = (Time.get_ticks_usec() - t0) / 1000.0
		return

	# La malla base mide 1×1 y la escala la pone la instancia. Así una sola
	# malla sirve para árboles y arbustos.
	_campo = campo(_hojas, puestas, capas, 1.0, 1.0, _mezcla)
	_campo.name = "Campo"
	add_child(_campo)
	_ms_campo = (Time.get_ticks_usec() - t0) / 1000.0


# ── cámara ────────────────────────────────────────────────────────────────

func _mover_camara() -> void:
	if _camara == null:
		return
	var d := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	_camara.position = _foco + d * _dist
	_camara.look_at(_foco, Vector3.UP)


func _preset(i: int) -> void:
	var p: Array = PRESETS[i % PRESETS.size()]
	_dist = p[1]
	_pitch = deg_to_rad(p[2])
	_yaw = p[3]
	_foco = p[4]
	_mover_camara()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var b := e as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT:
			_girando = b.pressed
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = clampf(_dist - _dist * 0.12, DIST_MIN, DIST_MAX)
			_mover_camara()
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = clampf(_dist + _dist * 0.12, DIST_MIN, DIST_MAX)
			_mover_camara()
	elif e is InputEventMouseMotion and _girando:
		var m := e as InputEventMouseMotion
		_yaw -= m.relative.x * 0.006
		_pitch = clampf(_pitch + m.relative.y * 0.004,
			deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))
		_mover_camara()
	elif e is InputEventKey and (e as InputEventKey).pressed:
		var k := (e as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_7:
			_preset(k - KEY_1)
		elif k == KEY_F:
			informe()
		elif k == KEY_B:
			_ciclar_correccion()
		elif k == KEY_ESCAPE:
			get_tree().quit()


var _corr_i := 2
const CORRS := [0.0, 0.35, 0.55, 1.0]


func _ciclar_correccion() -> void:
	_corr_i = (_corr_i + 1) % CORRS.size()
	for m in _materiales_shader:
		m.set_shader_parameter("correccion", CORRS[_corr_i])
	var sm := _malla_campo()
	if sm != null:
		sm.set_shader_parameter("correccion", CORRS[_corr_i])
	print("corrección de inclinación = %.2f" % CORRS[_corr_i])


func _malla_campo() -> ShaderMaterial:
	if _campo == null or _campo.multimesh == null or _campo.multimesh.mesh == null:
		return null
	return _campo.multimesh.mesh.surface_get_material(0) as ShaderMaterial


# ── medición ──────────────────────────────────────────────────────────────

func _process(dt: float) -> void:
	_cuadro += 1
	if _medir:
		_medir_paso(dt)
	elif _capturar:
		_capturar_paso()


## El ensayo de costo. Un escalón por vez: rehace el campo, deja pasar unos
## cuadros para que el motor se acomode, promedia el resto.
func _medir_paso(dt: float) -> void:
	const CALENTAR := 12
	const CONTAR := 30
	if _cuadros_paso == 0:
		if _paso >= ENSAYOS.size():
			_tabla_costos()
			get_tree().quit()
			return
		_rehacer_campo(ENSAYOS[_paso][1], ENSAYOS[_paso][0] == "malla Kenney")
		# El preset del campo, que es el único desde donde el campo se ve: si
		# la cámara mira para otro lado el motor lo descarta entero y la
		# medición da lo mismo para 1000 que para 64 000. Ya me pasó.
		_preset(6)
		_t_paso = 0.0
	_cuadros_paso += 1
	if _cuadros_paso > CALENTAR:
		_t_paso += dt
	if _cuadros_paso >= CALENTAR + CONTAR:
		_tabla.append({
			"que": ENSAYOS[_paso][0],
			"n": ENSAYOS[_paso][1],
			"ms_armar": _ms_campo,
			"ms_cuadro": _t_paso / CONTAR * 1000.0,
			"objetos": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"llamadas": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitivas": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"mem_video": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		})
		_paso += 1
		_cuadros_paso = 0
	return


## Una captura por preset de cámara, para que alguien pueda mirarlas sin abrir
## el proyecto. En headless no hay imagen y se saltea.
func _capturar_paso() -> void:
	const CADA := 25
	if _cuadro % CADA != 0:
		return
	var i := _cuadro / CADA - 1
	if i < 0:
		return
	if i >= PRESETS.size():
		get_tree().quit()
		return
	_preset(i)
	await RenderingServer.frame_post_draw
	var vp := get_viewport()
	if vp == null:
		return
	var tex := vp.get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	var ruta := "user://prueba_2d%s_%d_%s.png" % ["_mezcla" if _mezcla else "",
		i, String(PRESETS[i][0]).replace(" ", "_")]
	img.save_png(ruta)
	print("captura %s  (%s)" % [ProjectSettings.globalize_path(ruta), PRESETS[i][0]])


func _tabla_costos() -> void:
	print("")
	print("=== COSTO: un MultiMesh de tarjetas, una llamada de dibujo ===")
	print("  %-14s %8s %10s %11s %9s %12s %11s"
		% ["qué", "cuántas", "armar ms", "cuadro ms", "objetos", "primitivas",
			"llamadas"])
	for f: Dictionary in _tabla:
		print("  %-14s %8d %10.1f %11.2f %9d %12d %11d"
			% [f["que"], f["n"], f["ms_armar"], f["ms_cuadro"], f["objetos"],
				f["primitivas"], f["llamadas"]])
	print("")
	print("  El tiempo de cuadro es de llvmpipe (Vulkan por software, sin GPU):")
	print("  sirve para comparar escalones entre sí, NO como número absoluto.")
	print("  En headless todos los contadores de render dan 0: no hay render.")


func informe() -> void:
	var tri_tarjeta := 2
	print("")
	print("=== TARJETAS 2D EN MUNDO 3D — banco de pruebas ===")
	print("pantalla               %s   render %s"
		% [DisplayServer.get_name(), RenderingServer.get_video_adapter_name()])
	print("sprites cargados       %d  (%d×%d px, un Texture2DArray de %d capas)"
		% [_rutas.size(), LADO_TEXEL, LADO_TEXEL, _hojas.get_layers()])
	print("armar el arreglo       %.1f ms" % _ms_hojas)
	print("memoria del arreglo    %.0f KB  (RGBA8 + mipmaps, sin comprimir)"
		% (_rutas.size() * LADO_TEXEL * LADO_TEXEL * 4 * 4.0 / 3.0 / 1024.0))
	print("campo                  %d tarjetas en 1 MultiMesh, armado en %.1f ms"
		% [(_campo.multimesh.instance_count if _campo != null else 0), _ms_campo])
	print("triángulos del campo   %d"
		% ((_campo.multimesh.instance_count if _campo != null else 0) * tri_tarjeta))
	if _tri_kenney > 0:
		print("mismo campo en Kenney  %d triángulos (árbol de %d tri)"
			% [(_campo.multimesh.instance_count if _campo != null else 0)
				* _tri_kenney, _tri_kenney])
	print("")
	print("--- el rango real de la cámara (FOV %.0f° vertical, 1080 de alto) ---" % FOV)
	print("  %9s %14s %13s %16s"
		% ["distancia", "alto visible", "px por metro", "px por téxel*"])
	for d: float in [12.0, 20.0, 27.0, 40.0, 68.0]:
		var alto := 2.0 * d * tan(deg_to_rad(FOV * 0.5))
		var ppm := 1080.0 / alto
		print("  %8.0f m %12.1f m %13.0f %16.1f"
			% [d, alto, ppm, ppm / (LADO_TEXEL / 2.0)])
	print("  * un sprite de %d px que mide 2 m: %d téxeles por metro."
		% [LADO_TEXEL, LADO_TEXEL / 2])
	print("    1:1 (nítido de verdad) cae a 88 m: AFUERA del rango. A 12 m está")
	print("    ampliado 7×. Con arte de 128 px el 1:1 cae a 22 m, adentro.")
	print("")
	print("--- alto aparente según la corrección de inclinación ---")
	print("  %12s %12s %12s" % ["corrección", "a 28°", "a 64°"])
	for c: float in CORRS:
		print("  %12.2f %11.0f%% %11.0f%%"
			% [c, cos(deg_to_rad(PITCH_MIN) * (1.0 - c)) * 100.0,
				cos(deg_to_rad(PITCH_MAX) * (1.0 - c)) * 100.0])
	print("")
	print("=== FIN ===")
