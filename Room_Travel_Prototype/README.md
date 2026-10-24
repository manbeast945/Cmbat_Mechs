# Dungeon Game — Foundation Project

This new Godot project will grow into the full dungeon game. The current route is Floor 1 starter room → blank boss placeholder → stairs → blank Floor 2 entry. A separate, unconnected Floor 3 placeholder establishes the same scene interface for later development. Each floor is isolated in its own scene and folder.

## Run

Open this folder's `project.godot` in Godot 4.x and press **F5**. The player starts in Floor 1's starter room.

## Controls

- **WASD** or **Arrow keys**: move.
- **1**: unlock room doorways after entering a new room or floor. The initial spawn begins unlocked.

## Structure

- `scripts/floor_manager.gd` and `scripts/floor_base.gd`: persistent player, room camera, iris effect, room locking, and the shared floor-scene interface.
- `scenes/floors/floor_1/` and `scenes/floors/floor_2/`: the playable starter-to-boss-to-stairs route and replaceable Floor 2 entry.
- `scenes/floors/floor_3/`: an unconnected placeholder using the same floor interface.
- `scripts/room.gd`: room floor, flush black doorway openings, and colliding wall segments.
- `scripts/player_movement.gd`: temporary standalone movement controller, intended to be replaced when the team's combat movement is integrated.
- `scripts/iris_transition.gdshader`: full-screen iris close and open effect.
- `scenes/`: the main, room, and temporary player scenes.


