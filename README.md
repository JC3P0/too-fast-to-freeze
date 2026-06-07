# Too Fast to Freeze

---

## What It Is

A 3D endless skiing game where you race downhill through trees, boulders, and snow while a freeze timer counts down. Grab coffee to add time. Don't crash.

The core loop: ski fast, survive obstacles, beat your distance.

---

## The Transformation

The jam version was a vertical slice made under a deadline. The goal now is to rebuild it as a proper roguelike with:

- **Physics-based tracks** — real slopes you slide down using Godot's physics engine, replacing the current "obstacles move toward you" illusion
- **Checkpoint upgrade system** — each checkpoint pauses the run and presents upgrade choices before you continue
- **Procedural level generation** — reworked spawner tied to a proper level system with increasing difficulty
- **Snow trail shader** — a GLSL/Godot shader that deforms a snow mesh as you move, leaving visible tracks
- **Bot opponents** — AI skiers that race alongside you and try to bump you into trees, navigating via A\*

---

## Upgrade System (Rogue-like Loop)

Each checkpoint offers upgrades across three weapon/ability tracks:

| Upgrade | Level 1 | Max Level |
|---|---|---|
| **Axe** | 1 ability charge — swing to cut a tree (slight slow + swing animation, keeps speed) | More charges; faster swing recovery |
| **Jump** | Low base jump height | Progressively higher jumps |
| **Saw Blade** | Shoot one blade forward, cuts one tree | Multiple blades, wider spread, longer range |

---

## Architecture & Design Patterns

| System | Pattern | Why |
|---|---|---|
| Game events (hit, checkpoint, upgrade) | **Observer / EventBus** | Decouples spawner, UI, audio, bots from each other |
| Player movement | **State Machine** (existing, extended) | Already in place; will be extended for new states (Axe Swing, Airborne, Stunned) |
| Weapon/ability behavior | **Strategy** | Axe and saw blade share an `IWeapon` interface; behavior is swappable at runtime |
| Obstacle/bot creation | **Factory** | `ObstacleFactory` and `BotFactory` centralize instantiation and make spawner logic clean |
| Upgrade data | **Flyweight / Data Resource** | Godot `Resource` objects hold upgrade stats; shared across instances |
| Object reuse (obstacles, projectiles) | **Object Pool** | Avoids GC pressure from constant instantiate/free during gameplay |
| Global game data | **Singleton** (existing `GlobalState`, improved) | Cleaned up to hold only true global state; split off per-system state |
| Bot pathfinding | **A*** | NavigationAgent3D or custom grid-based A\* for bot obstacle avoidance |


---

## Current Tech Stack

- **Engine**: Godot 4
- **Language**: GDScript
- **3D Models**: Blender
- **Audio**: Custom music loop

---

## Project Structure

```
too-fast-to-freeze/
├── Assets/          # Audio, Blender source files, textures, PNGs
├── Game/
│   ├── Level/       # Main scene, spawner, UI, camera, GlobalState
│   │   ├── Spawner/ # Obstacle spawning (to be reworked)
│   │   └── UI/      # HUD, title screen, game over, pause, settings
│   ├── Obstacles/   # Trees, boulders, snow barriers, coffee pickups
│   └── Player/
│       ├── States/  # Player state machine (Idle, Soft, Hard, Jump, Vuln…)
│       └── Trails/  # Particle trail effects
```

---

## Roadmap

Track progress via [GitHub Issues](../../issues).

- [ ] **Phase 1** — Architecture refactor (EventBus, Factory, clean GlobalState)
- [ ] **Phase 2** — Physics tracks + proper camera follow
- [ ] **Phase 3** — Checkpoint + upgrade system
- [ ] **Phase 4** — Axe ability + Saw blade weapon
- [ ] **Phase 5** — Snow trail shader
- [ ] **Phase 6** — Bot opponents (A\* navigation)
- [ ] **Phase 7** — Polish, audio, VFX, itch.io release

---
