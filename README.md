# FUTUREWAR

FPS futurista 3D para Android construido con Godot 4.

## Estado actual — Prototype 0.01

La rama `development` ya contiene un primer prototipo jugable sin assets externos:

- Movimiento FPS con WASD
- Cámara con mouse
- Sprint con Shift
- Salto con Space
- Arma VX-7 con disparo hitscan
- Munición y recarga
- Daño, vida y muerte del jugador
- Soldados HELIX con IA básica
- Enemigos que persiguen, detectan línea de visión y disparan
- Mapa greybox `City Zero`
- Coberturas, ruinas, luces y pilares futuristas
- HUD con vida, munición, objetivo y hitmarker
- Controles táctiles básicos para Android
- Reinicio automático al morir
- Victoria al eliminar la patrulla

## Abrir el proyecto

1. Instala Godot 4.7 o una versión compatible.
2. Clona el repositorio.
3. Cambia a la rama de desarrollo:

```bash
git checkout development
```

4. Importa la carpeta del repositorio desde Godot.
5. Ejecuta el proyecto con F6/F5.

La escena principal es:

```text
res://scenes/main.tscn
```

## Controles PC

```text
WASD        Movimiento
Shift       Sprint
Space       Salto
Mouse       Mirar
Click izq.  Disparar
R           Recargar
Esc         Liberar/capturar mouse
```

## Controles Android

- Lado izquierdo de la pantalla: movimiento tipo joystick virtual
- Lado derecho: mover la cámara
- FIRE: disparar
- JUMP: saltar
- RELOAD: recargar

## Estructura

```text
FUTUREWAR/
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── main.gd
│   ├── player.gd
│   ├── weapon.gd
│   └── enemy.gd
├── project.godot
└── icon.svg
```

## Próximos pasos

- Menú principal
- Modelo real del soldado y arma
- Animaciones
- Efectos de disparo e impactos
- Audio
- Drones enemigos
- Heavy enemy / mini boss
- Objetivos por misión
- Sistema de checkpoints
- Ajustes gráficos para Android
- Exportación APK
- Más adelante: inventario, progresión y multijugador

## Seguridad

No subir al repositorio:

- keystores
- archivos `.jks`
- claves API
- contraseñas
- credenciales de firma

Esos archivos están excluidos por `.gitignore`.
