# De dónde salió cada malla, y con qué permiso

Este archivo es la **evidencia de licencia**. Los dos repos son públicos y el
juego se distribuye como `.exe`, así que acá no entra nada sin licencia clara
que permita uso comercial y redistribución. Si algún día se agrega un asset,
se agrega también su fila acá con la URL donde lo dice. **Ante la duda, no
entra.**

## Resumen

Todo el arte 3D importado es de **Kenney** (kenney.nl) y de **Quaternius**
(quaternius.com), y **los dos están bajo CC0 1.0 Universal** — dominio
público. Ninguno exige atribución. Por eso **no hace falta `CREDITOS.md`**;
los créditos de abajo son voluntarios y los dejamos porque corresponde.

> Kenney · https://kenney.nl · CC0 1.0
> Quaternius · https://quaternius.com · CC0 1.0

### Por qué ahora son DOS autores, y por qué eso no rompe la regla

Este archivo decía "un solo autor a propósito" y la regla sigue en pie: mezclar
packs se lee como error y un solo autor se lee como decisión. Lo que cambió es
que se midió el costo de sostenerla y en dos casos era más alto que el de
romperla.

1. **Kenney no tiene animales.** Ninguno. Se pidieron explícitamente y el valle
   llevaba meses sin un bicho vivo. Acá no hay empate que discutir: o entra
   otro autor o no hay fauna.
2. **Y Kenney no se puede reemplazar en la vegetación**, que es donde más se
   lo ve. Medido, en triángulos por malla:

   | | Kenney | Quaternius (el más barato) |
   |---|---|---|
   | conífera | 54 | 1.576 (`PineTree_5`) |
   | fronda | 62 | 944 (`CommonTree_Dead_3`) |
   | arbusto | 32 | 268 (`Bush_2`) |

   Con ~2.500 árboles sembrados eso es la diferencia entre 135 mil triángulos y
   cuatro millones. **El bosque se queda en Kenney y no es una preferencia: es
   aritmética.**

Lo que cierra la costura es la **aduana de `paleta.gd`**: las mallas de los dos
autores salen con la misma escalera de valores y el mismo techo de saturación,
así que en pantalla no conviven dos paletas. Ver `Paleta.domar_material()` y
`Kit._domar_color()`.

**La regla nueva, entonces, es ésta:** un tercer autor no entra. Y adentro de
cada autor, un solo kit por categoría — si falta una pieza se resuelve con
geometría primitiva o no se hace.

## Los packs

### Kenney

| Pack | Versión | Página (dice la licencia) | Zip descargado | md5 del zip |
|---|---|---|---|---|
| Nature Kit | 2.1 | https://kenney.nl/assets/nature-kit | `kenney_nature-kit.zip` | `76777290568bf80e1ba928a23c73a441` |
| Fantasy Town Kit | 2.0 | https://kenney.nl/assets/fantasy-town-kit | `kenney_fantasy-town-kit_2.0.zip` | `d151edd416f769b77cc9f4eba29afafe` |
| Survival Kit | 2.0 | https://kenney.nl/assets/survival-kit | `kenney_survival-kit.zip` | `74cd74157b58339340085802ff9c8c0a` |

### Quaternius

| Pack | Página (dice la licencia) | De dónde se bajó | md5 |
|---|---|---|---|
| Ultimate Animated Animals | https://quaternius.com/packs/ultimateanimatedanimals.html | Google Drive, carpeta `1uJ3N5HfB7jKTseJUNQr3N4YaN0UuEtHk`, subcarpeta `glTF` | por archivo, abajo |
| Medieval Village MegaKit \[Standard] | https://quaternius.com/packs/medievalvillagemegakit.html | https://quaternius.itch.io/medieval-village-megakit → `Medieval Village MegaKit[Standard].zip` | `0b0cd23b4a25998ca427dd92b710caf1` |

**md5 de los `.gltf` originales de los animales, como salieron de Drive** (los
`.glb` del repo NO son estos archivos: están podados, ver más abajo):

```
de9e486c625c754a7e3acd5344541f8b  Alpaca.gltf     84063cf55ddd78b8dde83dcb93afb6c0  Donkey.gltf
77490c795be493309222b11ae64d88b0  Bull.gltf       499ec8e91fc141f0f5d4650c3f6d56f6  Fox.gltf
899ccfe6c8d18d7055d25619d716abca  Cow.gltf        d71b24891f2329cb36ae3550115c77ff  Horse.gltf
4b0d1805fec92a72f8428d93a6a29194  Deer.gltf       246a57f17d3d8dfaba4dc1849c131f0c  Stag.gltf
                                                  431e861aedd965ff0975f5fa3f61deea  Wolf.gltf
```

**md5 de lo que está en el repo:**

```
3ad5206aa8c4db07f4a1497655ad3efc  animales/Cow.glb      b2af32f3deaa370c1d6c5f735e1873f2  animales/Horse.glb
109729001f6ebefa78b3f1e1e76c3349  animales/Deer.glb     dbbbed59a9bbeccde59f4a7d40e691a0  animales/Stag.glb
985cfa99aee95aae47c191cf8e1fecd7  animales/Donkey.glb   77270b1c6f0ea599029e96823f226cf7  animales/Wolf.glb
7cf0d548cc5fffcd76e6c005ba3c9799  animales/Fox.glb
```

### Dónde dice CC0, textualmente

1. **En la página de cada pack** (`kenney.nl/assets/<pack>`), fila "License":

   ```html
   <td class='title text-muted'>License</td>
   <a href='https://creativecommons.org/publicdomain/zero/1.0/'>Creative Commons CC0</a>
   ```

2. **En `kenney.nl/support`**:

   > […] are public domain licensed (CC0). You're free to use them, even in
   > commercial projects.

3. **Adentro de cada zip**, en `License.txt` — copiado a este repo como
   `assets/kenney/LICENSE-<pack>.txt`:

   > License: (Creative Commons Zero, CC0)
   > http://creativecommons.org/publicdomain/zero/1.0/
   > You can use this content for personal, educational, and commercial purposes.
   > Support by crediting 'Kenney' or 'www.kenney.nl' (this is not a requirement)

El texto de licencia viaja **en el repo**, no de memoria: los tres
`LICENSE-*.txt` son los archivos originales de Kenney sin tocar.

### Dónde dice CC0 lo de Quaternius, textualmente

1. **En la página de cada pack** (`quaternius.com/packs/<slug>.html`), fila
   "License", con el link a la licencia:

   ```html
   <img src="/assets/svg/license.svg" class="iconBig"> License
   CC0
   <a href="https://creativecommons.org/publicdomain/zero/1.0/">
   ```

2. **En un `License.txt` que viaja con los modelos** — el del zip del Medieval
   Village y el de la carpeta de Drive de los animales. Los dos están copiados
   a este repo sin tocar, como `assets/quaternius/LICENSE-*.txt`:

   > License:
   > CC0 1.0 Universal (CC0 1.0)
   > Public Domain Dedication
   > https://creativecommons.org/publicdomain/zero/1.0/

**Ojo con las versiones PRO y SOURCE.** El `License_Standard.txt` aclara que lo
CC0 es la versión **Standard**, que es la gratuita y la que está acá; las otras
dos se pagan. **No traigas una PRO al repo**: la licencia de esas no está
verificada y este archivo no las cubre.

## Qué se bajó y cómo

Bajado por consola con `curl` directo desde `kenney.nl`, sin intermediarios ni
espejos. El link del zip **no está en un `href`** de la página —por eso "no
aparece en el HTML plano"—, pero sí está en el HTML, en texto plano, con esta
forma:

```
https://kenney.nl/media/pages/assets/<slug>/<hash>-<epoch>/<archivo>.zip
```

Se saca con:

```sh
curl -s -A "Mozilla/5.0" "https://kenney.nl/assets/nature-kit" \
  | grep -oE "media/pages/assets/nature-kit/[^\"' )]*\.zip"
```

El `<hash>` cambia cuando Kenney republica el pack, así que **no lo hardcodees**:
sacalo de la página cada vez.

### Quaternius: los dos caminos, y los dos andan por consola

Este archivo decía que Quaternius **no se podía bajar** porque sus links van a
Google Drive. **Es falso, y costó una ronda entera de arte.** Los dos caminos
funcionan con `curl` y están abajo para que nadie los redescubra.

**Camino 1 — itch.io.** Los packs nuevos ya no linkean a Drive: linkean a
`quaternius.itch.io`. Se baja gratis, sin cuenta, en tres pasos:

```sh
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
BASE=https://quaternius.itch.io/medieval-village-megakit

# 1. la página trae el csrf_token y la url que genera la descarga
curl -s -A "$UA" -c cook.txt "$BASE" -o page.html
CSRF=$(grep -oE 'csrf_token" value="[^"]*"' page.html | head -1 | sed 's/.*value="//;s/"$//')

# 2. POST a download_url → {"url": ".../download/<token>"} (dura ~60 s)
DL=$(curl -s -A "$UA" -b cook.txt -c cook.txt -X POST "$BASE/download_url" \
     --data-urlencode "csrf_token=$CSRF" -H "X-Requested-With: XMLHttpRequest" \
     | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])")
curl -s -A "$UA" -b cook.txt -c cook.txt "$DL" -o dl.html
C2=$(grep -oE 'csrf_token" (value|content)="[^"]*"' dl.html | head -1 | sed 's/.*="\([^"]*\)"$/\1/')

# 3. POST al archivo → {"url": "<url firmada de R2>"}
#    OJO: el endpoint cuelga de $BASE, NO de la url del paso 2. Pegarlo del
#    otro lado devuelve una página de error en HTML y parece un 200.
ID=$(grep -oE 'data-upload_id="[0-9]+"' dl.html | head -1 | grep -oE '[0-9]+')
curl -s -A "$UA" -b cook.txt -X POST "$BASE/file/$ID?source=view_game&as_props=1" \
     --data-urlencode "csrf_token=$C2" -H "X-Requested-With: XMLHttpRequest"
```

**Camino 2 — carpeta pública de Drive.** Los packs viejos (los animales, entre
ellos) siguen en Drive, y una carpeta pública **sí se lista**: el HTML trae un
`window['_DRIVE_ivd']` con el índice completo.

```python
h = curl("https://drive.google.com/drive/folders/<id>")
d = json.loads(re.search(r"window\['_DRIVE_ivd'\]\s*=\s*'(.*?)'\s*;", h, re.S)
               .group(1).encode().decode('unicode_escape'))
for it in d[0]:
    print(it[0], it[2], it[3])   # id, nombre, mime  (las carpetas se recorren igual)
```

y cada archivo se baja con
`https://drive.usercontent.google.com/download?id=<id>&export=download&confirm=t`.

## Qué se importó, exactamente

Sólo las mallas que se usan — no los packs enteros. 652 modelos disponibles,
**80 importados**, 1,4 MB en disco.

- `assets/kenney/naturaleza/` — Nature Kit. Árboles, arbustos, tocones, rocas,
  flores, hongos, cercas, cultivos. **Sin texturas**: el color va en el
  material, que es justo lo que hace falta para un look estilizado plano.
- `assets/kenney/pueblo/` — Fantasy Town Kit. Muros y techos modulares (las
  casas se arman con estas piezas), carro, puesto, farol, molino, fuente.
- `assets/kenney/utiles/` — Survival Kit. Barriles, cajones, cofre, balde,
  herramientas, yunque, banco de trabajo, fogón, carteles, carpa.

`pueblo/` y `utiles/` comparten un atlas de color (`Textures/colormap.png`,
11 KB y 7 KB). Es **una textura por carpeta**, referenciada por todos los `.glb`
de esa carpeta — por eso la carpeta `Textures/` tiene que quedar al lado de los
`.glb` o Godot importa las mallas sin color.

Formato **glTF binario (`.glb`)** en los tres casos. Los packs también traen FBX,
OBJ, DAE y STL; se descartaron: FBX es problemático en Godot y glTF entra sin
configurar nada.

### Quaternius

- `assets/quaternius/animales/` — Ultimate Animated Animals. **Siete de las
  doce especies**: vaca, caballo, burro, ciervo, venado, lobo y zorro. Quedaron
  afuera alpaca, husky, shiba inu y los dos caballos repetidos: no son de este
  valle. Rondan los 2.000 triángulos cada uno y **vienen sin textura**, sólo
  con `albedo_color`, así que pasan por la aduana como cualquier malla del kit.
- `assets/quaternius/pueblo/` — Medieval Village MegaKit \[Standard]. **22
  piezas de las 176**: muros de revoque y de ladrillo (recto, puerta, ventana,
  entramado), techos, alero, puntal, chimenea, enredadera, carro, cerca y
  escalera. Hoy las usa **sólo `escenas/prueba_casas.tscn`**, que es el A/B
  contra las casas de Kenney; no están cableadas al valle.

#### Los `.glb` de los animales están PODADOS, y hay que saberlo

Los originales traen **trece animaciones** cada uno (`Gallop`, `Attack_Kick`,
`Death`…) y pesan ~3 MB de `.gltf` por bicho. En el repo quedaron cuatro
—`Idle`, `Idle_2`, `Walk`, `Eating`— y el archivo pasó a `.glb`. Son 7,6 MB en
vez de 25, y **1,23 MB en el `.exe`** una vez que Godot los importa.

La poda se hizo con un script que recorre los `accessors` vivos desde las
animaciones que quedan y reescribe el buffer. **No es reversible desde el
repo**: si mañana hace falta `Gallop`, se vuelve a bajar el `.gltf` de Drive
(los md5 originales están más arriba) y se poda de nuevo con la lista nueva.

#### Las texturas del Medieval Village se HORNEAN, no se doman en runtime

Las piezas del pueblo sí traen textura: cuatro trim sheets PBR de 2048
(base color + normal + roughness/ORM), 40 MB en total. Lo que entró al repo son
**siete base colors a 512, ya pasados por la aduana en disco**, 1,5 MB. Los
normal maps y los ORM **se tiraron** y los materiales quedaron en
`metallic 0 / roughness 1`: el juego es estilizado plano y un normal map de
piedra es exactamente el detalle que `DISENO.md` §6 manda no comprar.

Dos motivos para hornear en vez de domar al vuelo, los dos medidos:

1. `Paleta.atlas_domado()` traduce **píxel por píxel en GDScript**. Sobre el
   atlas de Kenney son 24 colores únicos y el resto es cache; sobre un trim
   sheet fotográfico son decenas de miles, y el valle tardaría segundos en
   abrir.
2. La aduana de runtime **clava** el valor a uno de los nueve peldaños, y
   `paleta.gd` avisa textual que eso no se le hace a una textura fotográfica:
   posteriza. El horneado hace lo otro que pide la regla — satura al techo y
   **comprime** el valor adentro del rango de la escalera.

Por eso `Paleta.domar_material()` saltea `atlas_domado()` para todo lo que
cuelgue de `/quaternius/`. **El filtro es por ruta y no por tamaño**: se probó
con `<= 128 px` y apagó la aduana del pueblo de Kenney entero —su atlas también
es de 512— y las casas volvieron al menta y coral de fábrica.

## Lo que se miró y NO entró

Está acá para que la próxima búsqueda no repita el trabajo. Todo esto es CC0 y
todo esto se bajó y se midió; lo que falló fue el encaje, no la licencia.

| Pack | md5 del zip | Por qué no |
|---|---|---|
| Quaternius · Stylized Nature MegaKit | `a49a8b80d12f72b2d7f3082fba566c8d` | El mejor follaje libre que se encontró —`TwistedTree`, `DeadTree`, helechos— y **no entra por triángulos**: el pino más barato son 1.646 y el `TwistedTree_5` son 10.104, contra 54 de Kenney. Con 2.500 árboles es un valle de cuatro millones de triángulos. Si algún día hay impostores o LOD, **volver acá primero.** |
| Quaternius · Ultimate Nature Pack (150 modelos) | `8b851e8cf228b5a3da74a541f69a1e5f` | Lo mismo, un escalón más barato y sigue sin alcanzar: 944 el árbol muerto más chico, 1.576 el pino. Además **no trae glTF**, sólo FBX/OBJ/Blend. |
| Quaternius · Fantasy Props MegaKit | `3e16e219e30be2e1ff82a21854776d96` | 94 props buenísimos —yunque, barril, carreta, banco de trabajo, jaula, cadena—, pero a 40–68 m un barril son ocho píxeles y los de Kenney ya están puestos. **Es la próxima categoría a mirar si alguna vez hay primeros planos.** |
| Quaternius · Modular Dungeon | `74c71abaf4f7039f6dea5f3789a1d6f9` | Interiores de mazmorra; el valle no tiene ninguno todavía. |
| Quaternius · Farm Buildings | `b7e0bc1a47351c973f9747e6481b9395` | Granero y molino americanos, no medievales. |
| Quaternius · Farm Animals (el pack viejo) | `51bc406d98a1e722e712a532d93acdd1` | Lo reemplaza Ultimate Animated Animals, que es mejor en todo: trae ciervo, lobo y zorro, y **trae glTF** (éste sólo FBX/OBJ/Blend). |
| Quaternius · Ultimate Modular Ruins | — | Ruinas modulares, que el valle sí necesita (hay un lugar "ruina"). **No trae glTF**: FBX, OBJ y Blends. Está en Drive, carpeta `1ETp2ldaHaP0BkS4FBmkT-g9Yf88T_cIX`. Queda pendiente. |
