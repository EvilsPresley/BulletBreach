# Bullet Breach — architecture guide

## How a turn flows
```
click ─► Player._input ─► TurnManager.play_player_turn(ability, tile)
            │                  │ 1. snapshot (undo)
            │                  │ 2. Rules.play_turn(board, …) → event log   (instant, pure data)
            │                  │ 3. Presenter.play(log)                      (animations)
            ▼                  ▼
        Board (Map.board)    Views (MapObject nodes, one per Unit id)
```
* **Simulation** — `scripts/sim/`: `Board` (ground, units, poison, RNG; `clone()`),
  `Unit` (plain data), `Rules` (all game rules), `EnemyBehaviour` + `behaviours/`.
  No nodes, no `await`. All randomness goes through `board.rng`; threat queries
  (`is_tile_safe`, `threats_at`) never consume it, so previews can't change the future.
* **Presentation** — `scripts/presenter.gd` plays events (`"parallel_begin"`…
  `"parallel_end"` blocks start together) and applies run-level effects (XP, lives,
  cooldowns) when their animation plays. `Player`, `Ennemy`, `Building`… are views.
* **Run state** — `RunState` autoload (seed, night, turn, lives, level, XP, cooldowns),
  `PlayerRewards` (owned rewards). UI widgets only display them.
* **Events** autoload — signal bus between gameplay and UI/tutorials.

## Adding content
| You want… | Do this | Code touched |
|---|---|---|
| A new **skill** | Script extending `MoveAbility` (`can_target`, `simulate` ending with `Rules.move_end`), a `.tres` in `data/abilities/`, a SKILL `Reward` pointing to it | none |
| A new **triggered upgrade** | Script extending `RewardEffect` (`on_walk_after_special` / `on_move_end`), `.tres` in `data/effects/`, Reward(s) with `effect` + `stack_group` | none |
| A **stat upgrade** (range, XP…) | Reward with a `stack_group`, read it with `PlayerRewards.stacks(&"group")` where the stat is computed | one line |
| A new **enemy** | Behaviour script (`plan`, `threatened_tiles`, `execute`/`shoot`, optional `move`), view scene extending `Ennemy` (plan display), `EnemyDefinition` `.tres`, add it to `data/spawn/default_spawn_table.tres` | none |
| New **animation** for an event | Handle the event type in `Presenter._play_event` | presenter only |

Rules for new rules code: mutate the `Board`, append events to `log`, never touch nodes,
never `await`, use `board.rng` / `board.shuffled()` for randomness.

## Tests & tools
* `godot --headless --path . res://tests/smoke_test.tscn` — plays ~53 turns with every
  skill and checks: determinism (replay on a clone), previews don't touch the board,
  board ↔ view consistency every turn, cooldowns, coffin rest + night 2, undo, death.
  Expect `SMOKE TEST DONE errors=0`.
* `godot --path . res://tests/screenshot.tscn -- --out=/tmp/shots --seed=11 --turns=16`
  — renders PNGs (works under `xvfb-run`). Add `--no-atmosphere` to disable lighting.
* `-- --seed=N` on any run reproduces a run exactly. Undo in game: **U** or **Ctrl+Z**.

## Known follow-ups
* Deep fog is one node per tile (thousands): replace with a shader or a TileMapLayer
  (also the main cost of 2D lighting).
* World views are still `Control`s (Y-sorted inside `Node2D` containers); converting
  `MapObject` to `Node2D`/`Sprite2D` is optional cleanup.
* The map is hand-placed in `main.tscn`; `TurnManager.build_board()` is the single place
  a procedural generator would plug into (fill `Board.walkable` + units).
* Tutorials/dialogue are still hard-coded in `main.gd`.
