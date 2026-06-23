extends Node

## Global event bus (Observer pattern).
##
## Decouples systems that need to react to game events — UI, audio, bots,
## VFX, etc. — from the systems that trigger them. Nothing should reach
## directly into another system; instead, emit a signal here and let
## interested systems `connect()` to it in their own `_ready()`.
##
## Registered as an autoload singleton named "EventBus" in project.godot,
## so any script can call `EventBus.player_hit.emit(obstacle)` or
## `EventBus.player_hit.connect(_on_player_hit)` from anywhere.
##
## No persistence between runs — EventBus only relays in-memory signals 
## for the current session and stores no state of its own.

# -- Player / run lifecycle -------------------------------------------------

## Fired when the player collides with an obstacle. UI flashes, bots react,
## audio plays a hit sound.
signal player_hit(obstacle: Node)

## Fired when the player reaches a checkpoint zone. Pauses the run and
## brings up the upgrade screen.
signal checkpoint_reached(index: int)

## Fired when the player picks an upgrade from the checkpoint screen.
## Applied to the PlayerStats resource.
signal upgrade_selected(upgrade: Resource)

## Fired when a fresh run begins. All systems reset to their starting state.
signal run_started

## Fired when the run ends (player dies / freezes out). Carries the final
## distance so the game-over screen and HUD can display it.
signal run_ended(distance: float)

# -- World / spawn events ----------------------------------------------------

## Fired when a bot skier is spawned into the level. Lets the camera and
## audio systems register it without the spawner knowing about them.
signal bot_spawned(bot_node: Node)

## Fired when the player's axe cuts down a tree. Drives VFX and audio.
signal tree_cut(position: Vector3)

## Fired when the player picks up an axe. HUD listens to refresh icon count.
signal axe_picked_up(count: int)

## Fired when an axe charge is consumed on a tree hit. HUD listens to grey out an icon.
signal axe_used(count: int)
