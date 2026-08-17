# Saber Escaso — cliente de Godot

El cliente 3D del valle. El mundo NO vive acá: vive en el servidor
(`../saber-escaso`, desplegado en https://saber-escaso.vercel.app). Esto es una
ventana a ese mundo.

**Las bases del juego están en `../saber-escaso/DISENO.md`.** Nadie toca la
escena sin leerlas: lo que se ve tiene que salir de lo que el juego es.

## El invariante. No se negocia.

**Lo que pasa en el cliente tiene que llegar al servidor, o no pasó.**

Ya lo rompimos una vez, entero: monstruos con IA, combate, vida y muerte que
vivían sólo en la máquina de cada jugador. Se veía como un juego y no lo era.
Matabas algo y el mundo no se enteraba, no lo veía nadie más, no quedaba nada.
Toda mecánica nueva escribe en la base o es una demo.

## Cómo está armado

```
escenas/valle.tscn      la escena; todo lo demás lo arma valle.gd por código
scripts/valle.gd        terreno, lugares, NPCs, monstruos, el pegamento
scripts/jugador.gd      CharacterBody3D, cámara en órbita acotada
scripts/figura.gd       cuerpo articulado animado con senos, sin archivos de animación
scripts/monstruo.gd     máquina de tres estados con un momento de duda
scripts/detalles.gd     ventanas, humo, pasto y piedras en MultiMesh, luciérnagas
scripts/cielo.gd        shader propio: estrellas, vía láctea, dos lunas, gigante gaseoso
scripts/ciclo.gd        el sol y la luna; la hora la manda el SERVIDOR (ver abajo)
scripts/parpadeo.gd     titileo de fuegos y ventanas
scripts/ambiente.gd     WorldEnvironment: SDFGI, niebla volumétrica, AgX, DOF
scripts/rendimiento.gd  alto/medio/bajo: qué efectos se prenden en qué máquina (F1)
scripts/api.gd          habla con el servidor; el token sale de token.txt o --token=
scripts/interfaz.gd     HUD, diálogo, campo para escribirle a los NPCs
desplegar.sh            probar → exportar → cerrar el juego → instalar. UNA carpeta.
```

## El sol es el reloj del mundo. No lo toques sin leer esto.

`ciclo.gd` **no** simula un día bonito: muestra la hora real del servidor.

- Un tick del mundo es un día y el cron corre uno cada seis horas, así que **seis
  horas reales son un día del valle y una vuelta entera del sol**.
- La hora **la manda el servidor**, no la máquina de cada uno. Por eso dos
  personas conectadas ven el mismo atardecer, y por eso una sesión de una hora
  tiene forma sola: entrás de mañana y se hace de noche mientras charlás.
- **La fase de la luna es el día del valle** — ocho días por vuelta. Mirás para
  arriba y sabés cuánto hace que no entrás, sin abrir ningún menú.

Si algún día ves un ciclo de día y noche con un temporizador local, alguien
rompió esto y el valle dejó de ser compartido.

Dos cosas más del entorno que son decisiones, no adornos:

- **La cordillera tiene una sola abertura, al norte**, por donde entra El
  Camino del Norte, que ya existía en el servidor. Un valle que se termina en
  niebla es un nivel; cercado con una salida es un lugar. **Cuando el mundo
  crezca, crece por ahí.**
- **Al caer el sol se encienden las ventanas y salen las luciérnagas.** Una
  ventana encendida dice "adentro hay alguien" más fuerte que todo el cielo
  junto.

## Cómo se despliega

`./desplegar.sh`. Nada de copiar el `.exe` a mano: Windows lo bloquea mientras
corre y ahí es donde nacen las carpetas `SaberEscaso2`. El script corre el juego
headless primero y **aborta si hay `SCRIPT ERROR`** — un `--import` limpio no
prueba nada, los errores de orden de inicialización sólo aparecen en `_ready()`.

## Trampas ya pisadas. No las repitas.

- **`SurfaceTool.set_material()` no aplica.** Usá `material_override`.
- **Winding invertido = normales para abajo = el piso no recibe sol.** Usá
  `[0,1,2]/[0,2,3]` y `st.generate_normals()`.
- **Sol a -26° dejaba una banda negra** cruzando el valle (el borde del cuenco
  sombreaba todo). Está en -44°.
- **Bajo WSL no hay GPU** — Vulkan por software (llvmpipe). SDFGI y SSR salen
  basura acá y bien en el `.exe`. No los apagues por una captura hecha en WSL.
- **`Object._get()` ya existe.** No le pongas `_get` a un método propio.
- **Un `LineEdit` visible se come el WASD.** Todo campo de texto avisa con
  `Interfaz.escribiendo()`.
- **Un error en `_ready()` aborta la función entera** y el juego arranca sin
  HUD, sin API, sin nada. Fue exactamente el bug de `interfaz` usada seis
  líneas antes de existir.

## El criterio visual

Tres reglas que ya se aplicaron y conviene no perder:

- **Todo tiene vida o tiene algún sentido. No hacemos por hacer.** El cielo iba
  camino a ser un fondo lindo y se salvó porque se le encontró un para qué: el
  sol es el reloj. Antes de agregar algo a la escena, decí qué significa.
- **La luz hace el trabajo, no los polígonos.** Es un blockout con buena luz,
  no un asset store. La iluminación global es justo lo que separa una cosa de
  la otra.
- **Cámara lejana por defecto.** Es lo que hace legible el mundo, y de paso lo
  que mantiene viable mobile alguna vez. Los primeros planos son un modo
  aparte, no una posición libre.

Y una pendiente que bloquea arte: **el piso de zoom no está decidido**
(`DISENO.md` §16). Define si hacen falta caras modeladas. Hasta que se decida,
no hagas nada que dependa de leer una expresión.

## Lo que falta (al 17 de agosto de 2026)

- Los ojos: las figuras no tienen cara. Los monstruos sí (dos esferas emisivas).
- Inventario en pantalla: los objetos existen en el servidor y no se ven acá —
  y tiene que decir **quién hizo cada cosa**, que es la mitad del punto.
- Las amenazas del servidor no se dibujan; los monstruos de la escena todavía
  son locales y no están atados a la tabla `threats`.
- No hay otros jugadores visibles en la escena de Godot.
- No hay lugares para frenar: el valle es todo tránsito, no hay dónde sentarse
  ni esperar a alguien.
