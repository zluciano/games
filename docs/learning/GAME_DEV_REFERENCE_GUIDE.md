# Game Development Reference Guide
## For Persona-Style Yu-Gi-Oh! GX in Godot

This guide contains essential learning resources for developing a stylized 3D anime RPG.

---

## DOWNLOADED RESOURCES (In This Folder)

### 1. GUILTY_GEAR_TECHNIQUES_CHEATSHEET.md ⭐ START HERE
**Practical extraction of all key techniques from the GDC talk**
- Ready-to-implement code snippets for Godot
- Core formulas explained simply
- Direct quotes and principles

### 2. GuiltyGearXrd_CelShading_GDC2015.pdf
**"Guilty Gear Xrd's Art Style: The X Factor Between 2D and 3D"**
- By Junya C. Motomura (Arc System Works)
- The definitive guide to making 3D look like 2D anime
- **Key techniques:**
  - Each character has their own set of lights (no global lighting)
  - Lights are animated to get the right shadows and highlights
  - Models don't follow standard depth/perspective rules
  - Each character has its own vanishing point
  - 2 months modeling + 2 months animation per character
  - Same person did model, textures, and rigging

**Watch the video:** https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The

### 3. GameFeel_Chapter1_Sample.pdf
**Free sample chapter from Steve Swink's "Game Feel"**
- Defines what "game feel" actually means
- The building blocks of interactive sensation
- Foundation for understanding player feedback

---

## FREE ONLINE RESOURCES

### The Book of Shaders (Essential)
**URL:** https://thebookofshaders.com
**Authors:** Patricio Gonzalez Vivo & Jen Lowe

**Topics Covered:**
1. **Algorithmic Drawing** - shaping functions, color theory, geometric shapes, matrices, patterns
2. **Generative Design** - randomness, noise generation, cellular noise, fractional Brownian motion
3. **Image Processing** - texture mapping, convolution kernels, filters
4. **Simulation** - Game of Life, ripples, reaction-diffusion
5. **3D Graphics** - lighting, normal mapping, ray marching, environment mapping

### Inigo Quilez Articles
**URL:** https://iquilezles.org/articles/
- Co-creator of Shadertoy
- All code snippets are MIT licensed
- Essential for raymarching, SDFs, and creative shader techniques

### GDC Vault Free Section
**URL:** https://gdcvault.com/free
- Hundreds of free game development talks
- Requires free registration

### Hi-Fi Rush Toon Rendering Talk
**URL:** https://gdcvault.com/play/1034330/3D-Toon-Rendering-in-Hi
- Tango Gameworks' approach to 60fps toon rendering
- Deferred toon renderer techniques
- Comic shaders, toon lights, face shadow implementation

---

## BOOKS TO PURCHASE (Priority Order)

### Tier 1: Essential Theory

#### 1. The Art of Game Design: A Book of Lenses - Jesse Schell
- **Why:** Called the "bible" of game design
- **Key Concept:** 100+ "lenses" to examine your design from different angles
- **Buy:** https://www.amazon.com/Art-Game-Design-Book-Lenses/dp/0123694965
- **Price:** ~$45

#### 2. A Theory of Fun for Game Design - Raph Koster
- **Why:** Understand what makes games engaging
- **Key Concept:** Fun = learning in disguise
- **Buy:** https://www.amazon.com/Theory-Game-Design-Raph-Koster/dp/1449363210
- **Price:** ~$25

#### 3. Game Feel - Steve Swink
- **Why:** Master the tactile sensation of gameplay
- **Key Concepts:**
  - Feedback loop between player input and game response
  - Visual, auditory, and haptic feedback
  - Controls and responsiveness as building blocks
  - Physics and player perception
- **Buy:** https://www.amazon.com/Game-Feel-Designers-Sensation-Kaufmann/dp/0123743281
- **Price:** ~$50

### Tier 2: Art & Visual Design

#### 4. Anime Architecture - Stefan Riekeles
- **Why:** Understand Japanese animation visual language
- **Contains:** Case studies from Akira, Ghost in the Shell, Patlabor
- **Price:** ~$40

#### 5. The Art of Overwatch
- **Why:** Masterclass in stylized character design
- **Key Concepts:** Exaggerated proportions, dynamic poses, clean silhouettes
- **Price:** ~$35

### Tier 3: Technical

#### 6. Practical Shader Development - Kyle Halladay
- **Why:** Hands-on shader programming for game developers
- **Buy:** https://www.amazon.com/Practical-Shader-Development-Fragment-Developers/dp/1484244567
- **Price:** ~$45

#### 7. GDScript 2.0 (2024)
- **Why:** Godot 4.2 specific, includes 3D RPG projects
- **Pages:** 497
- **Price:** ~$40

### Tier 4: Production & Narrative

#### 8. Narrative Design for Indies - Edwin McRae
- **Why:** Story design for small teams and budgets

#### 9. A Playful Production Process - Richard Lemarchand
- **Why:** Complete game production workflow
- **Publisher:** MIT Press

---

## KEY CONCEPTS CHEAT SHEET

### From Jesse Schell's "Lenses"
- **Lens of Essential Experience:** What experience do I want the player to have?
- **Lens of Surprise:** What will surprise players?
- **Lens of Fun:** What makes my game fun?
- **Lens of Flow:** Is there a clear goal? Is feedback immediate?

### From "Game Feel"
- **Input → Response latency** should be < 100ms
- **Consistent physics** creates trust
- **Screen shake, particles, sound** = "juice"
- **Weight and momentum** make movement feel real

### From Guilty Gear Xrd Techniques
- **Per-character lighting** (not global)
- **Animated lights** for dynamic shadows
- **Break perspective rules** for 2D appeal
- **Hand-adjusted vertices** for specific poses
- **Inner lines** drawn as inverted geometry

### From Hi-Fi Rush Techniques
- **Deferred toon renderer**
- **Custom shadow maps** for stylization
- **Light probes** for global illumination
- **Special face shadow** implementation

---

## GAMES TO STUDY

### For Cel-Shading Excellence
1. **Guilty Gear Xrd/Strive** - Industry-leading 3D-to-2D
2. **Hi-Fi Rush** - Stylized world rendering
3. **Dragon Ball FighterZ** - Arc System's anime techniques
4. **Okami** - Timeless ink brush aesthetic

### For Persona-Style UI/Feel
1. **Persona 5** - Bold red/black/white, dynamic menus
2. **Metaphor ReFantazio** - Modern Atlus anime style
3. **13 Sentinels** - Vanillaware's 2D mastery

### For Card Game UI
1. **Slay the Spire** - Clean card readability
2. **Inscryption** - Atmospheric card presentation
3. **Yu-Gi-Oh! Master Duel** - Modern YGO reference

---

## LEARNING PATH RECOMMENDATION

### Week 1-2: Theory Foundation
- Read Jesse Schell chapters 1-10
- Watch Guilty Gear Xrd GDC talk
- Study the PDF in this folder

### Week 3-4: Shader Fundamentals
- Complete Book of Shaders chapters 1-7
- Experiment in Shadertoy
- Apply learnings to your Godot shaders

### Week 5-6: Visual Style
- Study Anime Architecture
- Analyze Persona 5 screenshots/videos
- Create mood boards for your game

### Week 7-8: Implementation
- Watch Hi-Fi Rush GDC talk
- Apply techniques to your project
- Iterate based on feedback

---

## QUICK LINKS

| Resource | URL |
|----------|-----|
| Book of Shaders | https://thebookofshaders.com |
| Shadertoy | https://www.shadertoy.com |
| GDC Vault Free | https://gdcvault.com/free |
| Inigo Quilez | https://iquilezles.org |
| Godot Docs | https://docs.godotengine.org |
| Godot Shaders | https://godotshaders.com |

---

*Last updated: February 2026*
