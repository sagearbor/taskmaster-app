# Multiplayer / Social Games — Roadmap

Captures the 20 social/multiplayer game concepts so none are lost. This is a
**spec/roadmap, not implemented features** — games get built incrementally
(starting with AR Cornhole). Companion to `AR_ROADMAP.md` (solo AR mini-games).

## Stack reality
- **Firestore real-time + Auth** (web + mobile).
- **AR** via `ar_flutter_plugin_2`: plane detection, place objects, tap/raycast,
  device-local motion. **No physics engine, no shared/cloud anchors** → two
  phones can't see the same virtual object in the same spot. AR is mobile-only.
- So all "AR multiplayer" below (except the shared-space track) is
  **parallel-but-separate AR on each device, reconciled through Firestore.**

## Interaction modes
`TBS` Turn-Based-Synced · `RTS` Realtime-Synced · `AV` Async-Versus/Coop ·
`NON-AR` Flutter+Firestore · `SSA` Shared-Space-AR (needs anchors — see track below)

## Foundational plumbing (build once, unlocks all)
Additive — no rewrite of the solo model:
- **`mode` tag** on game/task metadata: `solo | versus | coop | party`. Drives
  lobby/task-picker filtering and tells scoring whether to compare / sum /
  team-aggregate.
- **`session` sub-document** for live games: `currentPlayer` (uid), append-only
  `turns[]` (each move = writer uid + server time), optional
  `boardState` / `liveScores{uid:int}`, a `phase` (`waiting|active|resolving|done`),
  and a `turnDeadline` server timestamp.
- Append-only `turns[]` + uid lets **Firestore security rules enforce "only
  `currentPlayer` may write on their turn"** → cheating-resistance for free.

---

## The 20 concepts

| # | Game | Mode · players | Scoring (int) | Firebase state | AR | Verdict · effort | tag |
|---|------|----------------|---------------|----------------|----|--------------------|-----|
| 1 | **AR Cornhole** — flick a bag at your board; knock rivals' off | TBS · 2–4 | 3 in-hole / 1 on-board | `boardState{bags[]}`, `turns[]`, `currentPlayer`, `scores` | place+tap+motion | ✅ M | versus |
| 2 | **Balloon Blitz** — pop most balloons in 30s | RTS · 2–4 | balloonsPopped | per-player `liveScore`, server `endsAt` | place+tap | ✅ S | versus |
| 3 | **Target Toss Duel** — knock targets in 60s, take turns | TBS · 2–4 | targetsHit | `rounds[]`, `currentPlayer`, `scores` | place+motion | ✅ M | versus |
| 4 | **Tower Trials** — tallest tower; "wobble" sabotage to next | TBS · 2–4 | maxStableHeight | `turns[]`, `sabotageTokens`, `scores` | place+motion | ⚠️ M | versus |
| 5 | **Floor-Is-Lava Relay** — hop safe-tiles; beat ghost trails | TBS · 2–4 | tilesCrossed | `runs[]`, best-distance `scores` | plane+motion | ⚠️ M | versus |
| 6 | **Scavenger Race** — find 5 AR items in your room fastest | RTS · party | seconds (inverted) | `progress{uid:found}`, `finishedAt` | place+tap | ✅ M | versus |
| 7 | **Speed Tap Showdown** — tap the lit target faster, best of 10 | RTS · 2–4 | reactionScore | `round{goAt}`, each writes `reactionMs` | — | ✅ S | versus |
| 8 | **Trivia Buzzer Royale** — live quiz, first correct buzz scores | RTS · party | correctAnswers | `currentQuestion`, server-ordered `buzzes[]`, `scores` | — | ✅ S | party |
| 9 | **Drawing Telephone** — draw→describe→draw chain | AV · party | votes | `chains[]`, `roundPhase`, `submittedBy[]` | — | ✅ M | party |
| 10 | **Prediction Poker** — bet points on a rival beating a task | TBS · party | net points | `wagers[]{bettor,target,stake,prediction}` | — (wraps tasks) | ✅ S | party |
| 11 | **Caption Battle** — caption a clip, everyone votes | AV · party | votesReceived | `submissions[]`, `votes`, no-self-vote | — | ✅ S | party |
| 12 | **Reaction Roulette** — release exactly at a random buzz | RTS · 2–4 | closeness (ms) | `triggerAt`, each writes `releaseDelta` | — | ✅ S | versus |
| 13 | **Co-op Heist Timer** — team solves puzzles before a shared clock | RTS coop · party | puzzlesSolved | shared `clock.endsAt`, `stages[]{solvedBy}` | — | ✅ M | coop |
| 14 | **AR Hot Potato** — pass a ticking virtual bomb | TBS · party | roundsSurvived | `bomb{holderUid,explodesAt}`, `turns[]` | place+tap | ⚠️ M | party |
| 15 | **Ghost Race** — AR course vs a rival's recorded ghost | AV · 2–4 | finishTime (inv) | `pathSamples[]` per run, replayed locally | plane+motion | ✅ M | versus |
| 16 | **Aim & Sabotage** — shooting gallery; hits charge a sabotage | TBS · 2–4 | netHits | `turns[]`, `sabotageQueue[]`, `scores` | place+tap+motion | ⚠️ M | versus |
| 17 | **Synchronized Dance-Off** — motion-prompt rhythm via accelerometer | RTS · party | rhythmAccuracy | `track.startAt`, stream `liveAccuracy` | — (motion sensor) | ⚠️ M | party |
| 18 | **Bluff Tasks (Werewolf-lite)** — secret saboteur on a coop task | AV · party | survival/votes | private `roles`, `votes`, `taskResult` | — | ✅ M | party |
| 19 | **Shared-Anchor Paintball** — two phones, same room, splat each other | SSA · 2 | hits | needs anchors + local netcode (see track) | shared anchors+physics | 🔶 L | versus |
| 20 | **Co-Build Sculpture** — two phones build ONE shared sculpture | SSA coop · 2–4 | judge/vote | needs persistent shared anchor (see track) | shared anchors | 🔶 L | coop |

### Concept clarifications
- **#10 Prediction Poker** — wagering/trash-talk layer over *existing* solo tasks; no new gameplay.
- **#12 Reaction Roulette** — hold finger, release on a hidden random buzz; early release penalized.
- **#15 Ghost Race** — race a translucent replay of a friend's recorded run (Mario-Kart-ghost style); async but competitive.
- **#17 Dance-Off** — phone **motion sensors** vs timed prompts (NOT a 3D dancing avatar); no camera.
- **#18 Bluff Tasks** — Among Us / Werewolf social deduction: secret saboteur on a co-op task, then vote.
- **#4 Tower Trials vs #20 Co-Build** — Tower = each builds their **own** tower separately, scores compared (feasible). Co-Build = everyone adds to **one shared** sculpture in the same physical AR space (needs shared anchors → SSA track).

---

## Recommended build order (fun × feasibility)
1. **AR Cornhole** (#1) — builds the TBS/versus plumbing every other head-to-head game reuses. **Build first.**
2. **Trivia Buzzer Royale** (#8) — non-AR, web+mobile, lowest risk; proves realtime buzzer/lock.
3. **Balloon Blitz** (#2) — simplest AR realtime; live-streaming scores + round windows.
4. **Drawing Telephone** (#9) — non-AR, huge replay value; multi-phase async-versus flow.
5. **Prediction Poker** (#10) — cheap wrapper that makes existing solo tasks feel multiplayer.

Everything #1–#18 is greenlit (user loves the list). Build behind the `mode`/`session` foundation above.

---

## Shared-Space AR track (#19, #20) — cross-platform via anchors
**Goal (user):** make shared-room AR work across **Android + iPhone**.

Two problems, solved separately:
1. **Co-localization (shared spatial frame)** — both phones must agree where the
   virtual world's origin is. Cross-platform options:
   - **ARCore Cloud Anchors** — has **both Android and iOS SDKs** → the cross-platform
     path. Cloud-hosted anchor; both phones scan the same area and resolve it.
   - **Marker / QR alignment** — both phones point at one printed marker to set a
     common origin, then track locally. DIY, cross-platform, no cloud.
   - (ARKit collaborative + MultipeerConnectivity is **iOS-only** — NOT cross-platform; excluded.)
2. **Live transport (latency)** — stream state during play. Firestore (~100–300ms)
   is fine for turn-based; for *freaky* realtime use **local P2P**: Nearby
   Connections (Android) / MultipeerConnectivity (iOS) ≈ tens of ms. Optional
   layer on top of the chosen co-localization.

**Caveats:** `ar_flutter_plugin_2` exposes neither Cloud Anchors nor world-map
sharing → this needs a **deeper custom AR integration via platform channels**
(or a different AR layer). It's a Large R&D effort — schedule **after** the
feasible TBS/RTS games prove the multiplayer plumbing. Not every social-AR moment
needs co-localization (e.g. #14 Hot Potato passes only *state* between phones).

**Plan:** prototype **marker/QR alignment first** (cheapest cross-platform
co-localization, no cloud cost), with **Cloud Anchors as the fallback** if marker
drift is too rough; layer **Nearby/Multipeer** for low-latency once a shared frame works.
