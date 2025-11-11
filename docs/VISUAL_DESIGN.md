# Phoenix - Visual Design Document

## Core Identity

**Game:** Yu-Gi-Oh! GX Persona-style game
**Mood:** Energetic, optimistic, school-life meets card battles
**Reference:** Anime cel-shading like Persona 5, but with GX's warmer, more colorful palette

---

## Color Palette

### Primary Colors (Dorm System)

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Slifer Red** | `#D94545` | (217, 69, 69) | Primary accent, player identity, action buttons |
| **Ra Yellow** | `#F5C542` | (245, 197, 66) | Gold accents, highlights, card frames |
| **Obelisk Blue** | `#3B7BC7` | (59, 123, 199) | Secondary accent, elite areas, night scenes |

### Supporting Colors

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **Card Gold** | `#C9A227` | (201, 162, 39) | Card borders, premium elements |
| **Deep Navy** | `#1A1A2E` | (26, 26, 46) | Outlines, shadows, UI backgrounds |
| **Warm Black** | `#0F0F1A` | (15, 15, 26) | Darkest shadows, text |
| **Cream White** | `#FFF8E7` | (255, 248, 231) | Highlights, UI text on dark |
| **Sky Blue** | `#87CEEB` | (135, 206, 235) | Daytime sky |

### Character Colors (Judai/Jaden)

| Element | Hex | Notes |
|---------|-----|-------|
| Hair (Light) | `#8B5A2B` | Outer layer, lighter brown |
| Hair (Dark) | `#5D3A1A` | Inner layer, darker brown |
| Skin (Lit) | `#F5D6C6` | Anime skin tone |
| Skin (Shadow) | `#D4A088` | Warm shadow |
| Jacket (Red) | `#C43C3C` | Slifer Red uniform |
| Jacket (Shadow) | `#8B2929` | Darker red for shadows |
| Undershirt | `#1A1A1A` | Black |

---

## Shader Style

### Cel-Shading Approach

1. **Two-tone shading** with hard/soft edge control
2. **Warm shadows** - not purple like Persona, but warm red-brown tints
3. **Strong rim lighting** - white/cream colored for daytime, warm orange for sunset
4. **Bold outlines** - Deep navy (#1A1A2E), not pure black

### Shadow Tints by Context

| Scene Type | Shadow Tint | Reasoning |
|------------|-------------|-----------|
| Daytime Outdoor | `#B08060` (warm brown) | Natural sunlight feel |
| Indoor | `#9080A0` (muted purple) | Artificial lighting |
| Sunset/Evening | `#A06040` (orange-brown) | Golden hour warmth |
| Night/Dramatic | `#4040A0` (blue-purple) | Cool, mysterious |

---

## UI Design Principles

### Card Game Theme
- UI elements styled like trading card frames
- Gold borders on important elements
- Card back patterns for backgrounds/loading screens

### Color Usage in UI
- **Red** = Primary action (Confirm, Attack, Select)
- **Blue** = Secondary action (Cancel, Back, Defend)
- **Gold/Yellow** = Highlights, notifications, rewards
- **White on Dark** = Readability

### Typography
- Bold, confident fonts
- Slight angles/italics for energy
- High contrast for readability

---

## Environment Design

### Duel Academy Island

**Courtyard (Main Hub)**
- Bright, welcoming atmosphere
- Green grass with warm yellow-green tint
- Academy building: White/cream with colored domes (Red, Yellow, Blue for each dorm)
- Golden decorative elements (obelisks, emblems)

**Time of Day Lighting**
- Morning: Cool, fresh blues transitioning to warm
- Noon: Bright, high saturation, minimal shadows
- Afternoon: Warm golden hour, long shadows
- Evening: Orange/purple sky gradient
- Night: Deep blue with artificial warm lights

### Building Materials

| Material | Lit Color | Shadow Color |
|----------|-----------|--------------|
| Academy Stone | `#E8E0D0` | `#B8A890` |
| Red Dome | `#D94545` | `#8B2929` |
| Yellow Dome | `#F5C542` | `#B8942F` |
| Blue Dome | `#3B7BC7` | `#2A5A94` |
| Gold Metal | `#C9A227` | `#8B7119` |
| Grass | `#7CB342` | `#4E7A28` |

---

## Post-Processing

### Environment Settings
- **Glow:** Subtle (0.3-0.5), bloom on bright areas
- **Saturation:** Slightly boosted (1.1-1.2)
- **Contrast:** Moderate (1.1-1.15)
- **Vignette:** Very subtle or none (keep it bright/open)

### Anti-aliasing
- MSAA 4x for clean outlines
- TAA optional for smoother motion

---

## Reference Games

1. **Persona 5** - UI excellence, cel-shading quality
2. **Guilty Gear Strive** - Artist-controlled 3D anime rendering
3. **Dragon Ball FighterZ** - Vibrant anime colors
4. **Ni no Kuni** - Studio Ghibli warmth

---

## Implementation Priority

1. ~~Basic cel-shader~~ (Done)
2. **Update color palette** - Replace purple shadows with warm browns
3. **Fix environment colors** - Academy domes, grass, sky
4. **Improve outlines** - Deep navy instead of black
5. **Add time-of-day lighting** - Shader uniforms for different moods
6. **UI overhaul** - Card-themed design
7. **Post-processing polish**
