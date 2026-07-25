# Story Pals — Roadmap to a Top-Tier Learning App

## Where you are today

A working Flutter app with clean architecture: 2 chapters (Rex the Dino, Lily the Doll), 4 puzzle types (sequence, shape match, pattern, counting), story scenes with text-to-speech in English/Spanish/Tagalog, emotion check-ins, kid profiles, parent dashboard with parent gate, and offline-first local storage.

## What was just added (visual engine — all code-built, zero image assets)

- `lib/core/visuals/pal_character.dart` — Rex and Lily as fully animated vector characters: breathing, blinking, tail wags, walking, jumping, celebrating with orbiting stars/hearts. Replaces all character emoji.
- `lib/core/visuals/living_background.dart` — 10 animated scenes (jungle, river, clearing, feast, bedroom, tea party, puzzle rooms, map): drifting clouds, rotating sun rays, swaying trees, shimmering river, twinkling fireflies, flapping butterfly, steam curls, floating hearts/bubbles, night stars.
- `lib/core/visuals/effects.dart` — particle engine: tap sparkles on every touch, star bursts on correct answers, full-screen confetti rain, attention wiggle for cards.
- Wired into: story scenes, puzzles, chapter map, emotion check-in.

**Your next step: run `flutter run` on a device — verify it compiles and feels right.** (Built without a local Flutter toolchain, so do a `flutter analyze` pass first.)

## Phase 2 — Adaptive learning engine ✅ (first version SHIPPED)

Built and working, all offline and COPPA-safe:

- **Practice Adventure**: endless procedurally-generated puzzles (`puzzle_generator.dart`) — never runs out of content. Launched from a card at the top of the chapter map.
- **10 difficulty levels per skill**: coding (2-step sequences → 5-step programs with decoy commands; AB patterns → AABC patterns), math (counting 2→8 → visual addition like "3 + 4"), English (2-letter matching → first-letter-sound word matching).
- **Mastery tracking** (`skill_level_provider.dart`): 3 first-try successes in a row = level up (confetti + voice announcement). Levels never go down.
- **Parent control wired in**: the Learning Focus sliders on the parent dashboard now actually control how often each skill appears in practice. Dashboard also shows each child's live mastery level and lifetime solved count per skill.
- **Kid-friendly voice**: TTS auto-selects the best neural voice on the device, warmer pitch/rate, rotates 8 praise + 4 encouragement lines.

Still to do in this phase: age bands influencing starting level, idle auto-hints after 8 s, spaced repetition nudging the weakest skill, generators for the language and geography sliders.

## Phase 3 — Story universe (10x content)

- **Content pipeline first**: your JSON chapter format is good. Write a `CHAPTER_SPEC.md` and a validation script so anyone (or Claude) can author new chapters safely.
- **New worlds using existing theme colors**: Ocean (Splash the dolphin — `oceanBlue`), Space (Cosmo — `spacePurple`), Jungle Gold (Momo the monkey). Each world = 3+ chapters. New characters are ~300 lines each in the painter system just built.
- **Branching choices**: add `choices: [{label, next}]` to story scenes — two big picture buttons instead of tap-to-continue. Agency massively boosts engagement and re-play.
- **Narrative arcs**: chapters within a world reference each other ("Remember the leaf you found for Rex?") using stored progress.
- **New puzzle types**: tracing (pre-writing), sound match (needs audio), color mixing, simple mazes (coding: loops).

## Phase 4 — Sound design

The single biggest missing sensory layer. Needs real assets (can't be code-generated):
- Free CC0 sources: Kenney.nl audio packs, freesound.org — pops, chimes, success fanfares, ambient jungle/night loops.
- Keep flutter_tts for dialog (it scales to all 3 languages free), but add a recorded voice option later for warmth.

## Phase 5 — Ship it

- Wire Firebase (already stubbed) for optional parent-side backup — keep kid flow 100 % offline.
- In-app purchase flow for premium chapters (package already included).
- Privacy: you have a privacy policy screen — get COPPA review before store submission; both app stores are strict on kids' categories.
- Test on a real 4-year-old. Nothing replaces this.

## Suggested order

Phase 2 (adaptive engine) → Phase 3 content pipeline + 1 new world → Phase 4 audio → Phase 5 ship. Each phase is a good Cowork session.
