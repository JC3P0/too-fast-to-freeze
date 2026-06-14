class_name PlayerStatsResource
extends Resource

## Flyweight data resource holding all player movement stats.
##
## Assign a .tres instance of this resource to the Player node's [member stats]
## export. The upgrade system applies per-run deltas by modifying a duplicate
## of this resource, keeping the base asset untouched.

## Acceleration rate (units/sec²) — how quickly speed converges to its target.
@export var acc_rate: float = 0.0

## Top speed while skiing straight (idle state).
@export var idle_max_speed: float = 0.0

## Rotation lerp coefficient applied in all movement states.
@export var rotation_speed: float = 0.0

## Body lean angle (degrees) during a soft carve turn.
@export var soft_rotation_angle: float = 0.0

## Top speed during a soft carve turn.
@export var soft_max_speed: float = 0.0

## Lateral velocity during a soft carve turn.
@export var soft_turn_speed: float = 0.0

## Body lean angle (degrees) during a hard carve turn.
@export var hard_rotation_angle: float = 0.0

## Top speed during a hard carve turn.
@export var hard_max_speed: float = 0.0

## Lateral velocity during a hard carve turn.
@export var hard_turn_speed: float = 0.0

## Body lean angle (degrees) when braking to a stop.
@export var stop_rotation_angle: float = 0.0

## Peak height of the jump arc (units).
@export var jump_height: float = 2.0

## Total duration of the jump arc (seconds).
@export var jump_duration: float = 1.0
