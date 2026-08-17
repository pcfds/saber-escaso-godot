## Que el 3D se vea dibujado.
##
## Es renderizado no fotorrealista, y es lo que hacen Wind Waker, Guilty Gear,
## Sable y Hi-Fi Rush: la geometría sigue siendo 3D —la cámara gira, hay
## profundidad, hay sombras— pero se DIBUJA como una ilustración. Para este
## proyecto tiene una ventaja que ninguna otra opción tiene: **no se tira nada.**
## Los mismos modelos, la misma cámara, el mismo mundo.
##
## De todo lo que se puede hacer, dos cosas hacen el 90% del efecto:
##
##  1. **EL CONTORNO.** Es la que más pesa, lejos. Un dibujo tiene línea; el 3D
##     no. Sin contorno, cualquier otra cosa que se haga sigue leyéndose como
##     render. Se hace acá en espacio de pantalla —una sola pasada sobre todo—
##     y no con la técnica del casco invertido, que exige duplicar cada malla y
##     falla justo en las siluetas finas como los troncos.
##
##  2. **LA LUZ EN ESCALONES.** Un degradé suave dice "superficie curva
##     iluminada"; dos o tres escalones planos dicen "alguien pintó esto".
##     Va en el mismo shader, sobre la imagen ya iluminada, para no tener que
##     tocar el material de cada cosa del valle.
##
## Se detecta el borde por PROFUNDIDAD y por NORMAL, y hacen falta las dos:
## sólo por profundidad se pierde el filo entre dos caras del mismo objeto (el
## techo contra la pared de una casa, que están pegadas); sólo por normal se
## pierde la silueta contra el cielo, donde no hay nada con que comparar.
## Va como un quad pegado a la cámara y no como una capa 2D: en Godot 4 un
## shader `canvas_item` **no puede leer la profundidad** —lo dice el motor con
## todas las letras— y sin profundidad no hay detección de bordes.
class_name Dibujado
extends MeshInstance3D

const CODIGO := "
shader_type spatial;
// `blend_mix` no es cosmético: en Godot las texturas de pantalla, profundidad
// y normales **sólo existen en la pasada transparente**. Dibujado como opaco,
// el quad se pintaba antes de que se resolvieran y las leía constantes — se
// midió sacándolas por color: profundidad y normal daban cero en toda la
// pantalla, así que no había un solo borde que detectar.
render_mode unshaded, blend_mix, cull_disabled, depth_test_disabled, depth_draw_never;

uniform sampler2D pantalla : hint_screen_texture, filter_linear;
uniform sampler2D profundidad : hint_depth_texture;
uniform sampler2D normales : hint_normal_roughness_texture;

uniform vec3 color_linea : source_color = vec3(0.06, 0.05, 0.07);
uniform float grosor = 1.4;
uniform float corte_profundidad = 0.012;
uniform float corte_normal = 0.42;
uniform float escalones = 4.0;
uniform float fuerza_escalones = 0.5;
uniform float distancia_maxima = 220.0;

// La profundidad del buffer no es lineal: cerca tiene muchísima más precisión
// que lejos. Sin linealizar, el umbral que funciona a cinco metros dibuja el
// mundo entero de negro a cincuenta.
float lineal(float cruda, mat4 inv_proj) {
	vec3 ndc = vec3(0.0, 0.0, cruda);
	vec4 vista = inv_proj * vec4(ndc, 1.0);
	return -(vista.z / vista.w);
}

void vertex() {
	// El quad se pega a la pantalla: se saltea la transformación y se escriben
	// las coordenadas de recorte a mano.
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

void fragment() {
	vec2 px = grosor / vec2(textureSize(pantalla, 0));
	vec3 col = texture(pantalla, SCREEN_UV).rgb;

	float z = lineal(texture(profundidad, SCREEN_UV).r, INV_PROJECTION_MATRIX);
	vec3 n = texture(normales, SCREEN_UV).rgb * 2.0 - 1.0;

	// Cuatro vecinos en cruz. Con ocho el contorno engorda y se empasta en la
	// vegetación densa, que es justo donde más líneas hay.
	float dz = 0.0;
	float dn = 0.0;
	vec2 lados[4] = {vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y)};
	for (int i = 0; i < 4; i++) {
		vec2 uv = SCREEN_UV + lados[i];
		dz = max(dz, abs(z - lineal(texture(profundidad, uv).r, INV_PROJECTION_MATRIX)));
		vec3 nv = texture(normales, uv).rgb * 2.0 - 1.0;
		dn = max(dn, 1.0 - dot(n, nv));
	}

	// El umbral de profundidad crece con la distancia: si no, a cuarenta metros
	// cualquier pendiente del terreno cuenta como borde y el pasto se vuelve
	// una maraña de líneas.
	float borde = step(corte_profundidad * (1.0 + z * 0.35), dz)
		+ step(corte_normal, dn);
	borde = clamp(borde, 0.0, 1.0);

	// Y se apaga con la distancia. Una línea de un píxel sobre algo que ocupa
	// tres es ruido, no dibujo.
	borde *= 1.0 - smoothstep(distancia_maxima * 0.55, distancia_maxima, z);

	// Luz en escalones, sobre el brillo ya calculado. Se hace en luminancia y
	// no por canal para no correr el matiz — ya nos pasó con el tinte de la
	// vegetación, donde dividir canal por canal volvió cian a todo el bosque.
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float paso = floor(lum * escalones + 0.5) / escalones;
	col *= mix(1.0, paso / max(lum, 0.001), fuerza_escalones);

	ALBEDO = mix(col, color_linea, borde);
	ALPHA = 1.0;
}
"


var material_linea: ShaderMaterial


func _ready() -> void:
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	mesh = q
	# Que no lo descarte el frustum: el quad vive en coordenadas de recorte y
	# su caja calculada no tiene nada que ver con dónde se dibuja.
	extra_cull_margin = 1e5
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Se dibuja al final, sobre todo lo demás.
	sorting_offset = 1e5
	var sh := Shader.new()
	sh.code = CODIGO
	material_linea = ShaderMaterial.new()
	material_linea.shader = sh
	material_override = material_linea


## Para el ajuste de calidad: en la más baja el contorno se apaga entero.
func prender(si: bool) -> void:
	visible = si
