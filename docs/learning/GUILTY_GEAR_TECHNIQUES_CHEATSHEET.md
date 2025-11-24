# Guilty Gear Xrd Cel-Shading Techniques
## Extracted from GDC 2015 by Junya Motomura (Arc System Works)

---

## THE CORE PRINCIPLE

> **"The X Factor is the Artist's Intention"**
>
> Everything on screen must be an intentional choice, not just a result of calculation.
> "Correct" math is not good enough - you need artistic control.

---

## CEL-SHADING FORMULA

```glsl
// The core calculation is simple:
float lit = step(threshold, dot(light_vector, normal_vector));
```

**Only 3 things matter:**
1. **Threshold** - the cutoff angle
2. **Light Vector** - direction of light
3. **Normal Vector** - surface direction

**Control ALL THREE for full artistic control.**

---

## TECHNIQUE 1: Threshold Control via Vertex Colors

**Problem:** Cel-shading creates harsh transitions. Need control over which areas shade.

**Solution:** Use a vertex color channel as an offset to the threshold.

```glsl
// In your shader:
float occlusion = vertex_color.r;  // 0.0 = always shaded, 1.0 = normal
float adjusted_threshold = threshold - occlusion;
float lit = step(adjusted_threshold, NdotL);
```

**How to use:**
- Paint vertex colors on your mesh
- Dark values = more likely to be shaded (occluded areas)
- Value of 0 = always shaded no matter what
- Linear interpolation between vertices = clean results, no pixelation

**Why vertex colors over textures?**
- Resolution independent (no jaggies at close-ups)
- Instant feedback while adjusting
- Cleaner results due to linear interpolation

---

## TECHNIQUE 2: Per-Character Lighting

**Problem:** Global lighting doesn't look good on every character pose.

**Solution:** Each character has their own dedicated light vector.

**Implementation:**
```gdscript
# Each character has its own light
var character_light_direction: Vector3

# In cutscenes, animate the light each frame
# to get the best shading for each pose
```

**Key insight:** In cutscenes, the light direction is ANIMATED along with the character to achieve the best result every frame.

---

## TECHNIQUE 3: Custom Vertex Normals

**Problem:** Auto-calculated normals create ugly artifacts under cel-shading. The slightest difference becomes a huge blotch.

**Solution:** Manually edit vertex normals on every major feature.

**For faces especially:**
- Transfer normals from a simple sphere to get smooth shading
- Hand-adjust normals to control exactly where shadows fall
- This is why their faces look clean while most cel-shaded faces look bad

**In Godot/Blender:**
- Use "Data Transfer" modifier to copy normals from simple shapes
- Manually adjust normals in edit mode
- Export with custom normals preserved

---

## TECHNIQUE 4: Two-Texture Color System

**Problem:** Shaded color in anime isn't just "darker" - it expresses material properties.

**Solution:** Use two textures:

1. **Base Texture** - Color when lit
2. **Tint Texture** - How dark/tinted when shaded

```glsl
// Shaded color = Base * Tint
vec3 lit_color = base_texture.rgb;
vec3 shaded_color = base_texture.rgb * tint_texture.rgb;
vec3 final_color = mix(shaded_color, lit_color, lit);
```

**Color theory from anime:**
- Less solid materials = lighter shades (light passes through)
- Skin gets red tint in shadow (from flesh underneath)
- Metal gets cool/blue tint in shadow
- The combination expresses material AND character atmosphere

**Their textures are just solid color blocks** - no drawn details, because all detail is in the mesh geometry.

---

## TECHNIQUE 5: Inverted Hull Outlines

**Why not post-process outlines?**
- Harder to preview in modeling software
- Less control over individual line thickness
- Can't vary width per-vertex

**Their method:**
```glsl
// Vertex shader for outline pass
vec3 outline_position = vertex + normal * outline_width;
// Render with front-face culling (shows back faces only)
```

**Vertex color controls:**
- Line width (thicker in important areas)
- Depth offset (prevents z-fighting)
- Can erase lines completely where needed

---

## TECHNIQUE 6: Inner Lines via UV Trick

**Problem:** Lines drawn on textures get jaggy at close-ups.

**Solution:** Axis-aligned beams + clever UV mapping

**How it works:**
1. Draw all lines as perfectly horizontal/vertical stripes on texture
2. Map UVs so mesh edges align with these stripes
3. UV overlap amount = line thickness

**Benefits:**
- Perfectly crisp lines at ANY zoom level
- No jaggies ever (axis-aligned pixels don't alias)
- Controllable thickness via UV adjustment

**Downside:** UV gets distorted, but they don't use textures for surface detail anyway.

---

## TECHNIQUE 7: Limited Animation

**"Do it like 2D to make it look 2D"**

**The rule:** No interpolation between keyframes.

```gdscript
# Instead of smooth interpolation:
# animation.interpolation = CUBIC

# Use stepped/constant:
# animation.interpolation = NEAREST
# Every frame is a hand-posed keyframe
```

**Why this works:**
- Smooth interpolation = looks 3D
- Stepped animation = looks like hand-drawn frames
- It's basically stop-motion animation with 3D models

**Their rig:**
- ~500 bones per character (!)
- Every feature must be independently animatable
- No physics simulation (doesn't look 2D)
- Heavy use of SCALE animation for:
  - Exaggeration
  - Squash and stretch
  - Making things appear/disappear

---

## TECHNIQUE 8: Breaking Perfection

**The secret to 2D animation in 3D:**

> "If a 3D object moves perfectly maintaining its shape, the human brain instantly recognizes it as a rigid 3D object."

**Solution:** Deform the mesh every keyframe to add imperfection.

**What they do:**
- Every bone adjusted every keyframe
- Light direction adjusted every frame
- Facial features don't maintain natural positions
- Limbs get scale animation to exaggerate perspective

**The mantra:** "Expressiveness over accuracy"

---

## MODEL SPECIFICATIONS

- **Poly count:** ~40,000 triangles per character
- **Bone count:** ~400-600 per character
- **Textures:** Minimal - mostly solid color lookups
- **Normal maps:** NOT USED (vertex normals instead)
- **Data storage:** Vertex properties (colors, normals, UVs) over textures

---

## APPLYING THIS TO YOUR GODOT PROJECT

### Immediate improvements you can make:

1. **Add vertex color support to your toon shader**
   ```glsl
   // Add to fragment():
   float occlusion = COLOR.r;  // Vertex color red channel
   ```

2. **Use per-character lights**
   ```gdscript
   # Add OmniLight3D as child of each character
   # Animate light position/direction for cutscenes
   ```

3. **Edit vertex normals in Blender before export**
   - Select face → Mesh → Normals → Set from Faces
   - Or use Data Transfer modifier from sphere

4. **Consider separate lit/shadow colors**
   ```glsl
   uniform vec4 lit_color : source_color;
   uniform vec4 shadow_tint : source_color;
   vec3 shaded = lit_color.rgb * shadow_tint.rgb;
   ```

5. **For outlines, use inverted hull method**
   - More control than post-process
   - Can preview in editor

---

## KEY QUOTES

> "Kill everything 3D. If you find something that looks 3D, you just have to find a way to avoid it."

> "In Cel-shading, every little noise on the surface will become extremely distracting."

> "To get a convincing 2D look, everything on screen has to be an intentional choice, not just a result of a calculation."

> "Nature is imperfect, the artist is imperfect, therefore perfection looks 'too artificial'."

> "You need to think in 2D."

---

## VIDEO LINK

Watch the full GDC presentation:
https://gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The

---

*Extracted from GuiltyGearXrd_CelShading_GDC2015.pdf*
