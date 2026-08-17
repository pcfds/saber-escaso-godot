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
scripts/valle.gd        terreno, lugares, NPCs, amenazas, otros jugadores, el pegamento
scripts/paleta.gd       LA PALETA. Ningún script inventa un color: salen de acá
scripts/sonido.gd       el lecho de ambiente, sintetizado al arrancar (0 bytes en disco)
scripts/vegetacion.gd   lo que crece
scripts/mapa.gd         el mapa de la tecla M
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

### Las dos decisiones de arte. Están cerradas — no las reabras.

Estuvieron abiertas meses y tenían la rama de arte parada. Se cerraron el 17 de
agosto y están en `DISENO.md` §6.

- **Piso de zoom: silueta, postura y ropa. Nunca la expresión.** O sea que **no
  hacen falta caras modeladas ni animación facial.** Un ojo humano a 27 metros
  mide dos píxeles: modelarlo es gastar en ruido. Todo el presupuesto va a
  silueta, valor y color.
- **El look es estilizado, y comprometido con serlo.** No es una concesión al
  rendimiento ni un paso hacia algo más realista.

  > **Hoy el juego no es realista ni estilizado: es indeciso, y eso es
  > exactamente lo que se lee como Playmobil.** Playmobil no se ve mal por ser
  > estilizado. Se ve mal por ser plástico de color plano bajo una luz que
  > pretende ser real. Minecraft y Stardew son mucho más simples que esto y no
  > se ven baratos, porque están comprometidos con una decisión. Lo que se lee
  > como barato no es la simpleza: es la indecisión.

  Tres consecuencias, y son las que se usan al trabajar:
  1. **El color decide separación, no imita materiales.** Un techo no es marrón
     porque la teja sea marrona: es el valor que necesita para separarse del
     pasto a veinte metros. Si el color "correcto" no separa, el correcto está
     mal. **Por eso `paleta.gd` tiene autoridad sobre el resto.**
  2. **La silueta hace el trabajo pesado.** Es lo único que se lee a la
     distancia a la que se juega.
  3. **Menos geometría, no más.** Subir detalle para que se vea menos rústico
     es el camino equivocado.

  Vale para las cuatro ramas de arte —paleta, vegetación, arquitectura,
  cuerpos— y **las cuatro usan el mismo criterio o se rompe.**

## Lo que falta (al 17 de agosto de 2026, tarde)

> Este bloque estuvo desactualizado varios días y mandó a más de un agente a
> rehacer algo que ya existía. **Si arreglás algo de acá, borralo de acá.**

- **Interiores.** Las casas tienen una puerta dibujada y no se abre ninguna:
  *"no hay puertas para entrar"*.
- **Los NPCs están clavados en un punto.** Es el pedido más repetido después de
  "le falta la vida". Que caminen dentro de su lugar es barato y no depende del
  servidor — ojo: eso es animación de presencia, no estado. El NPC sigue estando
  *en la fragua* para el mundo.
- **La paleta existe y todavía no la usa nadie.** `paleta.gd` está escrito con
  los 95 literales mapeados, y los nueve scripts siguen con sus colores a mano.
  Hasta que se migren, de a un archivo por vez, el valle se ve igual.
- **No hay lugares para frenar:** el valle es todo tránsito, no hay dónde
  sentarse ni esperar a alguien.
- **El bicho no dice quién es.** En la base hay amenazas con nombre propio y
  pueblo —"Kerrak el que quedó", de "Los del Sotobosque"— y en pantalla son
  bichos genéricos. El dato ya viaja en `/mundo`.

**Ya está hecho, no lo rehagas:** los ojos y la ropa por oficio en las figuras;
el inventario en pantalla con quién hizo cada cosa; las amenazas dibujadas
desde la tabla `threats`; los otros jugadores visibles; la vida del jugador
mandada por el servidor.
