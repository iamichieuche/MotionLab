# MotionLab – Experiment 10
## Business Card Animation Study
**SwiftUI Prototype PRD for Claude Code**

---

## Overview

A focused animation study of a single Monzo Business debit card. No flow, no navigation, no state management beyond triggering the animation. The entire experiment is one screen, one card, one button to replay.

**MotionLab goal:** Perfect the card as an animated physical object. Every detail of its entrance, material depth, lighting, and idle behaviour should feel indistinguishable from a native Apple UI component.

---

## The Single Screen

A clean `#F2F2F7` background (`systemGroupedBackground`). The card sits centred, vertically slightly above mid-screen to give the shadow and float room. A small `"Replay"` pill button sits at the bottom to re-trigger the full animation sequence on demand.

---

## Animation Sequence (in order)

### 1. Origin — Dynamic Island Pill
- On appear (or replay tap), a dark navy pill shape renders at the Dynamic Island position — top centre, `~126 × 37pt`, `cornerRadius` ~18pt
- Colour: `#1A1F36` — matches the card face, so the expansion feels continuous
- Duration before expansion begins: 0.15s pause — let the pill register before it moves

### 2. Expansion — Pill to Card
- Pill expands outward from its centre to full card dimensions `340 × 215pt`
- `cornerRadius` interpolates from 18pt → 16pt as it grows
- Motion: spring `dampingFraction: 0.72, response: 0.6` — weighted, no hard bounce
- Card content (text, chip, Mastercard logo) fades in at 80% of the expansion — not before, so the card face reveals as it arrives rather than appearing mid-flight
- The expansion should feel like the card is being exhaled from the island — not launched

### 3. Entrance Tilt — 3D Rotation
- Card enters with `rotation3DEffect` on the X axis at ~8° (tilted away from user, top edge further back)
- Resolves to 0° as the spring settles — gives the impression of the card flipping into a flat resting position
- Runs concurrently with the expansion, resolves at the same time

### 4. Haptic
- `.medium` impact fires at the exact moment the spring settles (approximately at `response` time + slight overshoot resolution)

### 5. Shimmer Sweep
- Begins 0.1s after card settles
- A `LinearGradient` of `white.opacity(0.0) → white.opacity(0.35) → white.opacity(0.0)` sweeps across the card face diagonally (~30° angle), left to right
- Implemented as a masked overlay with an animated `offset` — not opacity pulsing on the card itself
- Duration: 0.9s, `easeInOut`
- Plays once only — never loops

### 6. Idle Float
- Begins after shimmer completes
- Subtle Y offset animation: `±3pt` over `3.5s`, `easeInOut`, `repeatForever(autoreverses: true)`
- Barely perceptible — the card feels alive, not animated
- Accompanied by a very slight shadow offset change in sync: shadow Y shifts `16pt → 19pt` and opacity `0.3 → 0.22` as card rises, reverses as it falls — grounds the float physically

---

## Card Visual Spec

| Property | Value |
|---|---|
| Card face | Dark navy `#1A1F36` |
| Card size | `340 × 215pt` |
| Card corner radius | `16pt` |
| Border | None |
| Shadow | `radius: 24, y: 16, opacity: 0.3` — animates with idle float |

### Layered depth (ZStack, back to front)

1. **Base layer** — `RoundedRectangle` fill `#1A1F36`
2. **Gradient layer** — `RadialGradient` from `#2A3050` (top-left) to `#1A1F36` (bottom-right), `opacity: 0.8` — gives the card dimensionality, simulates ambient light hitting the top-left corner
3. **Edge highlight layer** — `RoundedRectangle` stroke, `white.opacity(0.1)`, `lineWidth: 1pt` inset — simulates light catching the card edge. Not a border — purely a lighting effect
4. **Content layer** — card text, chip icon, Mastercard logo
5. **Shimmer layer** — gradient mask overlay, animated offset, sits above content

### Card content

- Top right: `"monzo"` wordmark, SF Pro Rounded bold, coral `#FF5733`, 18pt + `"BUSINESS"` caption below in white, SF Pro Text medium, 9pt, `0.6` opacity
- Middle left: chip icon — use SF Symbol `creditcard.fill` cropped, or a `RoundedRectangle` grid of small squares in grey `#8A8A9A`
- Bottom right: Mastercard logo — two overlapping circles, left `#EB001B`, right `#F79E1B`, `opacity: 0.9`
- Bottom left: masked card number `"•••• •••• •••• 4821"` in white, SF Pro Mono, 13pt

---

## Replay Button

- Grey capsule pill, `#E5E5EA` fill, `"Replay"` label, SF Pro Text medium 15pt, dark primary text
- On tap: resets all animation state, re-runs full sequence from pill origin
- Press state: scale `0.96x`, `easeInOut`, 0.1s
- Haptic: `.light` on tap

---

## File Structure

```
MotionLab/
└── Experiments/
    └── CardAnimationStudy/
        ├── CardAnimationView.swift        // Root view, replay state trigger
        ├── BusinessCardView.swift         // Card with all layered depth
        ├── ShimmerModifier.swift          // Reusable ViewModifier
        ├── CardExpansionState.swift       // Enum: .pill / .expanding / .settled / .floating
        └── HapticManager.swift            // Shared from Exp 09 or duplicated
```

---

## Animation Parameters

| Animation | Type | Duration | Notes |
|---|---|---|---|
| Pill pause before expand | Delay | 0.15s | Let pill register |
| Pill → card expansion | Spring (dampingFraction: 0.72, response: 0.6) | ~0.6s | Size + cornerRadius |
| Entrance tilt | `rotation3DEffect` X | Resolves over 0.6s | 8° → 0°, concurrent with expansion |
| Card content fade-in | `easeOut` opacity | 0.2s | Starts at 80% of expansion |
| Haptic | — | On spring settle | `.medium` impact |
| Shimmer sweep | Linear offset, `easeInOut` | 0.9s | One-shot, 0.1s after settle |
| Idle float Y | `easeInOut` repeat | 3.5s loop | ±3pt |
| Idle shadow sync | `easeInOut` repeat | 3.5s loop | Mirrors float Y |
| Replay button press | Scale `easeInOut` | 0.1s | 1.0 → 0.96 |

---

## Prompt for Claude Code

> Build a SwiftUI view called **CardAnimationView** for MotionLab Experiment 10. This is a focused animation study — one screen, one card, one replay button. No navigation. Follow the PRD exactly.
>
> The card must originate as a dark navy pill (`~126 × 37pt`) at the Dynamic Island position, then expand via animated `frame` and `cornerRadius` on a single `RoundedRectangle` using a spring (`dampingFraction: 0.72, response: 0.6`). Do not use `matchedGeometryEffect` across views. Concurrent with expansion, apply a `rotation3DEffect` on the X axis that resolves from 8° to 0° as the spring settles.
>
> Card depth must use a layered `ZStack`: base fill, `RadialGradient` overlay for dimensionality, thin `white.opacity(0.1)` stroke for edge lighting, content layer, then shimmer layer on top. The shimmer is a `LinearGradient` mask with an animated offset — not an opacity pulse.
>
> After the card settles: fire a `.medium` haptic, then run the shimmer sweep once (0.9s, `easeInOut`). After shimmer completes, begin the idle float — Y offset `±3pt` over 3.5s with a synced shadow offset change to ground it physically.
>
> The replay button resets all state and reruns the full sequence. Use a `CardExpansionState` enum to manage stages: `.pill`, `.expanding`, `.settled`, `.floating`. iOS 17 deployment target, Xcode 15+. Include a `#Preview`.
