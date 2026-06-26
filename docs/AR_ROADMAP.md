# AR Tasks — Roadmap (Batch 5, not yet built)

Status: **concept only.** A 420-line data model exists (`lib/core/models/ar_task.dart`)
but nothing renders — the `ar_flutter_plugin` dependency is commented out in
`pubspec.yaml`, and `ARTask` is referenced by no screen/bloc. AR is **mobile-only**
(doesn't run on web). Build only after the core loop + "me" layer are solid.

## Design principle (from testing)

AR's superpower here is **measurable mini-games with an objective win condition** the
engine can auto-score instantly — no human judge, leaderboard-friendly. Subjective,
creative challenges are already well served by the existing **video-submission + judge**
flow, so AR should NOT duplicate that.

> **AR = timed skill challenges with a score. Video tasks = creative & judged.**

This is why, of the 7 stubbed templates, only **Treasure Hunt** and **Obstacle Course**
felt "real" — they have a countable/finishable success criterion. The others
(cake decorator, pet care, party planner, puppet show) are subjective → keep those as
normal judged video tasks instead.

## Target AR mini-games (all objective / auto-scored)

| Mini-game | Win condition (auto-scored) | AR capability needed |
|-----------|-----------------------------|----------------------|
| **Treasure Hunt** | items found; fastest time | plane detection, world anchors |
| **Obstacle Course** | reach the end; time; fewest collisions | plane detection, motion tracking, collision |
| **Target Toss** (the "throw" one) | targets knocked down in 60s | placement + simple throw physics |
| **Balloon Pop** | balloons popped in 60s | spawn anchors, tap/hit detection |
| **Block Stacker** | tallest *stable* virtual tower | placement + physics/stability check |
| **Floor-is-Lava** | furthest hop across virtual safe-tiles | plane detection, position tracking |

Each yields a number → feeds the existing scoreboard directly (could even skip judging
for AR tasks and auto-award points by rank).

## What "make it real" requires (large effort)

1. Add an AR plugin (`ar_flutter_plugin` for ARCore/ARKit, or platform channels).
2. An `ARTaskScreen`: camera + plane detection + object placement + the per-game
   interaction loop + a live score HUD + a "done → submit score" path.
3. Device-capability + permission gating (camera; ARCore/ARKit availability) with a
   graceful fallback for unsupported devices (and web).
4. Wire `ARTask` into the task flow (a third `taskType` alongside video/puzzle) and
   into scoring (auto-score by result instead of judge).
5. 3D assets for the props (treasures, targets, blocks, etc.).

## Quick win available now (optional, cheap)

Add the objective mini-games above to `ARTaskLibrary` as data stubs (incl. **Target Toss**
with a clear "targets hit in 60s" criterion) so the good ideas are captured — without any
of the engine work. Say the word and I'll add them.
