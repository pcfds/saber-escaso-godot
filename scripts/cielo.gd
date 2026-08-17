## El cielo. Shader propio, cero texturas, cero assets.
##
## Un ProceduralSkyMaterial da un degradé y nada más: de noche es una pantalla
## azul oscuro y el mundo se siente adentro de una caja. Todo lo que hace que
## un cielo se lea como cielo —que haya ALGO allá arriba— hay que escribirlo:
##
##  · ESTRELLAS con magnitudes distintas y centelleo. Todas iguales se leen
##    como ruido; con brillos distintos el ojo arma constelaciones solo.
##  · VÍA LÁCTEA. Una banda de más densidad. Es lo que hace que el cielo tenga
##    una orientación y no sea uniforme en todas las direcciones.
##  · DOS LUNAS, una grande en fase y una chica lejana. Dos lunas dicen
##    "no es la Tierra" más rápido que cualquier otra cosa que se pueda dibujar.
##  · UN GIGANTE GASEOSO con bandas, bajo sobre el horizonte. Es la imagen que
##    se queda: mirás para arriba y hay un planeta ahí.
##
## Todo esto se calcula por píxel en el fondo, sin geometría y sin costo de
## memoria. La rotación del cielo entera es una uniform que mueve `ciclo.gd`.
class_name Cielo
extends RefCounted


const CODIGO := "
shader_type sky;
render_mode use_debanding;

uniform vec3  sol_dir       = vec3(0.4, 0.3, -0.6);
uniform float altura_sol    = 0.3;    // -1 medianoche, 1 mediodía
uniform vec3  cenit_dia     = vec3(0.16, 0.36, 0.72);
uniform vec3  horiz_dia     = vec3(0.66, 0.78, 0.88);
uniform vec3  cenit_noche   = vec3(0.010, 0.020, 0.055);
uniform vec3  horiz_noche   = vec3(0.045, 0.065, 0.125);
uniform vec3  color_ocaso   = vec3(1.00, 0.42, 0.16);
uniform vec3  luna_dir      = vec3(-0.35, 0.55, 0.75);
uniform vec3  luna2_dir     = vec3(0.72, 0.30, 0.62);
uniform vec3  planeta_dir   = vec3(-0.80, 0.16, -0.58);
uniform float estrellas_giro = 0.0;
// 0 luna nueva, 0.5 llena, 1 nueva otra vez. La manda el servidor: es el día
// del valle, así que dos jugadores conectados ven la MISMA fase.
uniform float fase_luna = 0.5;

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

// Estrellas: una por celda del cubo, con posición y brillo aleatorios. El
// brillo se reparte en una curva para que haya muchas tenues y pocas
// intensas — un cielo con todas las estrellas iguales se lee como ruido.
vec3 estrellas(vec3 d, float densidad) {
	vec3 p = d * 190.0;
	vec3 celda = floor(p);
	float h = hash13(celda);
	float umbral = mix(0.9955, 0.978, densidad);
	if (h < umbral) return vec3(0.0);

	vec3 off = vec3(hash13(celda + 11.0), hash13(celda + 23.0), hash13(celda + 37.0)) - 0.5;
	float dist = length(fract(p) - 0.5 - off * 0.66);
	float mag = (h - umbral) / max(1.0 - umbral, 0.0001);
	mag = mag * mag;                       // pocas brillantes, muchas tenues

	float centelleo = 0.72 + 0.28 * sin(TIME * (1.1 + mag * 5.0) + h * 120.0);
	float punto = smoothstep(0.085 + mag * 0.05, 0.0, dist);

	// Las estrellas no son blancas: unas tiran a azul, otras a naranja.
	vec3 tinte = mix(vec3(0.72, 0.82, 1.0), vec3(1.0, 0.84, 0.66), hash13(celda + 5.0));
	return tinte * punto * (0.25 + mag * 2.6) * centelleo;
}

// Un disco en el cielo. `tam` en coseno del ángulo: más chico = más lejos.
float disco(vec3 d, vec3 dir, float tam, float borde) {
	return smoothstep(1.0 - tam, 1.0 - tam * borde, dot(d, normalize(dir)));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float arriba = clamp(d.y, -1.0, 1.0);

	// ── el degradé base, según dónde está el sol ────────────
	float dia   = smoothstep(-0.12, 0.22, altura_sol);
	float ocaso = 1.0 - abs(smoothstep(-0.28, 0.30, altura_sol) * 2.0 - 1.0);

	vec3 cenit   = mix(cenit_noche, cenit_dia, dia);
	vec3 horiz   = mix(horiz_noche, horiz_dia, dia);
	vec3 color   = mix(horiz, cenit, pow(clamp(arriba, 0.0, 1.0), 0.42));

	// El naranja del ocaso se concentra alrededor del sol, no en toda la
	// vuelta: un anillo uniforme se ve a calcomanía.
	float hacia_sol = max(dot(d, normalize(sol_dir)), 0.0);
	color = mix(color, color_ocaso,
		ocaso * pow(hacia_sol, 2.2) * (1.0 - smoothstep(0.0, 0.55, arriba)) * 0.85);
	color += color_ocaso * ocaso * pow(1.0 - abs(arriba), 9.0) * 0.30;

	// ── noche: estrellas, vía láctea, lunas, planeta ────────
	float noche = 1.0 - smoothstep(-0.16, 0.10, altura_sol);
	if (noche > 0.001) {
		// El cielo gira despacio, como el de verdad.
		float g = estrellas_giro;
		vec3 dg = vec3(d.x * cos(g) - d.z * sin(g), d.y, d.x * sin(g) + d.z * cos(g));

		// La vía láctea: banda de más densidad con un eje inclinado.
		float banda = 1.0 - abs(dot(dg, normalize(vec3(0.42, 0.44, 0.79))));
		float via = smoothstep(0.80, 1.0, banda);
		float sobre_horizonte = smoothstep(-0.06, 0.14, arriba);

		color += estrellas(dg, 0.35 + via * 0.65) * noche * sobre_horizonte;
		color += mix(vec3(0.05, 0.06, 0.11), vec3(0.11, 0.10, 0.16), via)
			* via * noche * sobre_horizonte * 0.55;

		// Luna grande, en fase. La sombra es otro disco corrido: cuánto se
		// corre es la fase, y la fase es el día del valle.
		float l = disco(dg, luna_dir, 0.0016, 0.55);
		float corrida = (fase_luna - 0.5) * 0.13;
		vec3 tapa = normalize(luna_dir + vec3(corrida, corrida * 0.42, 0.0));
		float sombra = disco(dg, tapa, 0.0016, 0.55);
		float luna = clamp(l - sombra * 0.94, 0.0, 1.0);
		// Craterío: manchas suaves, si no parece una pastilla.
		float manchas = 0.86 + 0.14 * hash13(floor(dg * 620.0));
		color += vec3(0.94, 0.93, 0.88) * luna * manchas * noche * 2.1;
		color += vec3(0.55, 0.60, 0.72) * disco(dg, luna_dir, 0.020, 0.02) * noche * 0.10;

		// Luna chica, más lejos y más fría.
		color += vec3(0.72, 0.78, 0.86) * disco(dg, luna2_dir, 0.00035, 0.4) * noche * 1.5;

		// El gigante gaseoso. Bandas horizontales sobre el disco, y un
		// terminador para que tenga volumen y no sea un sticker.
		vec3 pd = normalize(planeta_dir);
		float c = dot(dg, pd);
		float tam = 0.0060;
		if (c > 1.0 - tam) {
			vec3 tang = normalize(dg - pd * c);
			float lat = dot(tang, normalize(vec3(0.0, 1.0, 0.0) - pd * pd.y));
			float r = sqrt(max(1.0 - c * c, 0.0)) / sqrt(2.0 * tam);
			float bandas = 0.5 + 0.5 * sin(lat * r * 7.0 + 1.3)
				* (0.55 + 0.45 * sin(lat * r * 17.0));
			vec3 cuerpo = mix(vec3(0.52, 0.40, 0.31), vec3(0.78, 0.68, 0.52), bandas);
			// Iluminado desde donde está el sol.
			float fase = clamp(dot(tang, normalize(sol_dir)) * 0.9 + 0.45, 0.06, 1.0);
			float filo = smoothstep(1.0, 0.86, r);
			color = mix(color, cuerpo * fase, filo * noche);
		}
	}

	// ── el sol ──────────────────────────────────────────────
	float disco_sol = disco(d, sol_dir, 0.0011, 0.25);
	float halo = pow(hacia_sol, 220.0) * 0.6 + pow(hacia_sol, 12.0) * 0.10;
	vec3 color_sol = mix(vec3(1.0, 0.52, 0.24), vec3(1.0, 0.96, 0.88),
		smoothstep(-0.05, 0.35, altura_sol));
	color += color_sol * (disco_sol * 8.0 + halo) * smoothstep(-0.14, 0.02, altura_sol);

	// Bajo el horizonte no hay cielo: hay tierra, y la tapa el terreno. Que
	// se oscurezca evita el borde duro donde el mundo se termina.
	color *= mix(0.38, 1.0, smoothstep(-0.30, -0.02, arriba));

	COLOR = color;
}
"


static func material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = CODIGO
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
