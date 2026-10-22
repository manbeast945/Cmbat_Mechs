#Combat Sandbox

A small, standalone 2.5D-style combat room for Godot 4.7.2. Its room, characters, and weapons use drawn 2D placeholder shapes, so it needs no imported art or add-ons.

## Run it

1. Open Godot 4.7.2.
2. Choose **Import** and select this folder's `project.godot` file.
3. Open the project and press **F5** to run the configured arena scene.

## Controls

- **WASD**: move.
- **Mouse**: aim; the player faces the cursor.
- **Left mouse button**: swing or fire once per click.
- **1**: equip melee.
- **2**: equip gun.
- **R**: restart after defeat.

Knife clicks form a light, light, heavy combo. Swings have wind-up and recovery; a click near recovery's end is buffered. The cursor shows the equipped weapon's range, and a separate outer marker appears only when a hit registers.

## Structure

- `scenes/arena.tscn` and `scripts/arena.gd`: scene setup and combat test actors.
- `scenes/test_room.tscn`, `scripts/test_room.gd`, `scripts/room_visuals.gd`, and `scripts/front_wall_visual.gd`: reusable room shell, wall collisions, floor, wall faces, and foreground depth sorting.
- `scenes/player.tscn`, `scripts/player.gd`, and `scripts/player_visual.gd`: movement, aiming, health, weapon selection, and separate 2.5D-style placeholder drawing.
- `scripts/weapon.gd`, `scripts/melee_weapon.gd`, and `scripts/gun_weapon.gd`: shared weapon entry point and separate weapon behavior.
- `scenes/projectile.tscn` and `scripts/projectile.gd`: ranged projectile movement and collision.
- `scenes/enemy.tscn`, `scripts/enemy.gd`, and `scripts/enemy_visual.gd`: simple pursuit, health, cooldown-limited contact damage, and separate placeholder drawing.
- `scenes/hud.tscn`, `scripts/hud.gd`, and `scripts/aim_feedback.gd`: player health, equipped weapon, range crosshair, registered-hit marker, controls, and defeat screen.
- `scripts/hit_effect.gd` and `scripts/combat_sounds.gd`: short impact visuals and generated placeholder swing and impact sounds.

Health, damage, movement speed, attack range, and cooldowns are temporary exported values in the scripts and can be tuned in the Inspector.

## Current limits

This remains a 2D combat feel test with flat placeholder visuals. Enemies use simple direct pursuit. The room has no decorations, furniture, puzzles, or detailed dungeon art. There is no dungeon integration, inventory, progression, animation artwork, or persistent save state.
