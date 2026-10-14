# Fixed-camera Godot handover

## User requirements

Godot; 3D players against layered still artwork; controller or keyboard primary, optional click movement; walkable areas; animated glitch/code rain on screens; opening normal doors by default; connected room map; mist and lighting effects. Combat and crafting later. Browser mockup was rejected as the implementation platform.

## Architecture

- `scripts/game.gd`: calibrated camera, room loading, floor / boundary collision, navigation regions, layered plates and effects, map, door fades.
- `scripts/player.gd`: camera-relative input and optional NavigationAgent3D click paths, model scene slot, temporary articulated rig.
- `scripts/normal_door.gd`: standard solid leaf, frame, handle, hinge animation, collision removal and transition signal.
- `scripts/area_map.gd`: visited/current room graph and connecting edges.
- `shaders/`: screen rain, low moving mist and fixture flicker.
- `data/rooms.json`: room layout / connection contract. Edit this to calibrate supplied art.
- `assets/foreground`: exact pixel cutouts of near pillars / furniture; transparency masks, no generated replacement art.
- `assets/plates`: nine full backgrounds plus special door reference sheets.

## Remaining visual work

Final rigged 3D player model and animation are not supplied. Fit the footprint / doorway locations in Godot with that model. Paint genuinely different hallway / room angles; crops are not equivalent to those. Add per-object occlusion geometry or additional masks as needed. Broad areas and floor layouts need art approval before detailed combat/crafting implementation.

## Reproduce checks

`godot --headless --path . --editor --import --quit`

`godot --headless --path . --script res://tests/smoke.gd`

Runtime check covers nine plate / foreground pairs, reciprocal links, navigation, movement, floor collision, camera projection and normal-door transition.

## Validation performed

Godot 4.4.1 imports completed successfully. Headless smoke check passed with zero failures across all nine rooms, keyboard movement, click approach, navigation, floor collision, camera projection, reciprocal doors and room transitions. Hardware controller and final visual calibration remain to be checked.
