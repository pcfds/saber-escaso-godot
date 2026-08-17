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
scripts/runas.gd        la magia: ritual de la mañana (P), trazo radial (R),
                        grimorio (G) y las marcas que quedan en el suelo
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
- **Dos archivos escribiendo la MISMA propiedad, y gana el que corre último.**
  `ambiente.gd` apagaba `dof_blur_near_enabled` con su motivo al lado —con la
  cámara a cuarenta metros no hay nada entre ella y el jugador que valga la
  pena desenfocar— y `rendimiento.gd` lo volvía a prender por un argumento
  estético, sin ponerle distancia. Resultado: **el juego entero salía borroso**,
  casas a cuarenta metros incluidas, y así estuvo hasta el 17 de agosto.

  Lo que lo hace peligroso es que no parece un bug sino una decisión de arte:
  se lee como "está muy suave" y se va a discutir el estilo en vez de buscar la
  línea. Se aisló con **dos capturas y una sola variable** —prendido, mancha;
  apagado, nítido— y antes se habían descartado con el mismo método el nivel de
  calidad y el desenfoque de lejos, que empieza a 95 m cuando la cámara llega a
  68 y por lo tanto no podía ser. **Empezá por el experimento, no por el
  razonamiento: mi razonamiento sobre los números decía que el DOF estaba
  descartado, y estaba mal.**

  La regla: **`rendimiento.gd` decide CÓMO se calcula un efecto, no si existe.**
  El qué es de `ambiente.gd`. Y un efecto que se prende sin decir dónde empieza
  usa el default del motor, que no es de nadie.

## SÍ se puede ver el juego. Dejá de pedir capturas.

Durante días este archivo dijo que nadie del equipo podía ver la escena, y **es
falso**: hay display bajo WSLg y Godot renderiza por software. Cada tarea de
arte terminaba con "pedí una captura" y esperaba a una persona. No hace falta.

```bash
cd /home/pedro/proyectos/saber-escaso-godot
export PATH="$HOME/.local/bin:$PATH"
godot --display-driver x11 --rendering-driver vulkan --audio-driver Dummy \
      --quit-after 900 -- --token=$(cat /tmp/tok3d) --captura
# deja captura.png en la raíz. --calidad=alto|medio|bajo también sirve.
```

**Qué vale y qué no de esa captura.** Es software: SDFGI y SSR salen basura y no
se juzgan acá. **Pero el valor, la silueta, la saturación y la composición sí se
miden**, y son justamente las decisiones de esta rama. Convertí a gris y sacá
números — no mires "si se ve lindo", medí la separación.

No hay PIL ni ImageMagick en esta máquina, sí `numpy`. Hay un decodificador PNG
de treinta líneas en el scratchpad de la sesión; si no está, se reescribe con
`zlib` + `struct`.

**Y borrá `captura.png` al terminar**: no va al repo.
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
- **La paleta existe y todavía no la usa nadie.** `paleta.gd` está escrito con
  los 95 literales mapeados, y los nueve scripts siguen con sus colores a mano.
  Hasta que se migren, de a un archivo por vez, el valle se ve igual.
- **Nadie camina de un lugar a otro.** La gente se mueve dentro de su lugar,
  pero cuando el servidor dice que alguien se mudó, se planta en el lugar
  nuevo. Que el viaje se vea es de la tarea del servidor, no de acá.
- **No hay lugares para frenar:** el valle es todo tránsito, no hay dónde
  sentarse ni esperar a alguien.
- **El bicho no dice quién es.** En la base hay amenazas con nombre propio y
  pueblo —"Kerrak el que quedó", de "Los del Sotobosque"— y en pantalla son
  bichos genéricos. El dato ya viaja en `/mundo`.

**Ya está hecho, no lo rehagas:** los ojos y la ropa por oficio en las figuras;
el inventario en pantalla con quién hizo cada cosa; las amenazas dibujadas
desde la tabla `threats`; los otros jugadores visibles; la vida del jugador
mandada por el servidor; **la gente moviéndose en su lugar** (rondas de 3 a 5
paradas derivadas del nombre, ~3/4 del tiempo quietas); **el lecho de ambiente**
y **la vegetación del valle entero**, los dos cableados en `_ready()`.

## Cablear un módulo nuevo: una trampa que ya costó

Los módulos grandes se escriben en archivos nuevos —`paleta.gd`, `sonido.gd`,
`vegetacion.gd`— para que dos ramas no se pisen. **El precio es que el cableado
en `valle.gd` queda pendiente, y ahí es donde se rompe.** Lo que pasó de verdad:

- **`Sonido` terminó instanciado dos veces**, desde dos ramas que no se veían
  entre sí: dos lechos de ambiente sonando juntos, y uno de ellos en una
  variable local, o sea colgado.

  **CORRECCIÓN — esto decía que ésa era la causa de la fuga de veinte objetos
  al cerrar, y es falso.** Se midió con un control: con el duplicado ya sacado,
  revertir el arreglo del módulo devuelve las 22 fugas, y ponerlo las lleva a
  cero. Y la aritmética nunca cerró — la escena de prueba tiene UN solo
  `Sonido` (es el nodo raíz, no hay dónde duplicarlo) y filtraba las mismas 20.
  La causa real es del motor: hacen falta dos cuadros de proceso entre parar el
  audio y cerrar, y en `_exit_tree()` ya no queda ninguno. Un
  `AudioStreamPlayer` pelado sin una línea nuestra deja dos.

  El duplicado era un bug real y sacarlo estuvo bien. **Lo que estuvo mal fue
  dar por probada una causa que no se probó**, y dejarlo escrito acá como
  hecho: eso manda al próximo a cazar lo que no es.
- **La vegetación quedó cableada y `_armar_bosque()` seguía llamándose**, así
  que el Sotobosque tenía dos bosques encimados en el mismo sitio.

Las dos reglas que salen de eso:
1. **Antes de cablear, `grep` del `class_name` en `valle.gd`.** Si ya está, no
   lo agregues: alguien llegó primero.
2. **Guardá la instancia en un miembro, nunca en una variable local**, y si el
   módulo reemplaza algo viejo, **borrá lo viejo en el mismo cambio.**

Y una del entorno: **un `class_name` nuevo que ningún otro script referencia no
entra al cache de clases globales** sólo con `--quit-after`. Da
`Identifier "X" not declared`. Se arregla corriendo `godot --headless --import`
una vez — verificá con md5 que eso no te modificó `project.godot`.
