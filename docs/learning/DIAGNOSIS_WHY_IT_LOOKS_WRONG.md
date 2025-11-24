# Why Our Game Doesn't Look Like Persona/Guilty Gear
## Analysis Based on GDC 2015 Presentation

---

## WHAT WE SEE IN THE SCREENSHOT

| Element | Expected | Actual |
|---------|----------|--------|
| Ground (grass) | Bright green | Pure black |
| Character | Cel-shaded anime | Blown-out white silhouette |
| Buildings | Cel-shaded | Acceptable (has outlines) |
| Trees | Stylized | Acceptable |
| Path | Gray stone | Visible |

**Observation:** StandardMaterial3D objects work. Our custom shaders don't.

---

## THE FUNDAMENTAL PROBLEM

From Guilty Gear GDC talk:
> "To get a convincing 2D look, everything on screen has to be an intentional choice, not just a result of a calculation."

### What Guilty Gear Did:
1. **Artists paint vertex colors** → Control which areas get darker
2. **Per-character lights** → No global lighting on characters
3. **Custom vertex normals** → Hand-crafted on every face
4. **Two-texture system** → Separate lit color and shadow tint
5. **Instant feedback** → Preview matches final game exactly
6. **Limited animation** → No interpolation, every frame posed

### What We Did:
1. **Hardcoded shader values** → No artist control
2. **Global sun light** → Same light for everything
3. **Auto-calculated normals** → Whatever the mesh has
4. **Single computed shadow** → Math decides shadow color
5. **No feedback loop** → Change values, hope it works
6. **Standard animation** → Smooth interpolation

**We're trying to achieve art through math. They achieved art through artist control.**

---

## SPECIFIC TECHNICAL ISSUES

### Issue 1: Ground is Black

The shader has `EMISSION = color * 0.8` with color being green.
This should produce visible green emission.

**Possible causes:**
1. Shader compilation error (check Godot console)
2. world_pos varying not passing correctly
3. Pattern calculation producing zeros
4. Environment settings overriding

**Quick test:** Replace entire fragment() with:
```glsl
void fragment() {
    ALBEDO = vec3(0.5, 0.8, 0.4);
    EMISSION = vec3(0.5, 0.8, 0.4);
}
```
If this still shows black, the shader isn't being applied at all.

### Issue 2: Character is White

The character receives:
- EMISSION = base_color * shadow_color * ambient = ~0.5
- DIFFUSE_LIGHT from sun (energy 2.5)
- DIFFUSE_LIGHT from fill light (energy 1.2)
- Rim lighting
- HDR bloom

**Total light is way too high.**

The Guilty Gear approach:
- Characters have their OWN light (not global sun)
- No ambient emission on characters
- Light is precisely positioned for each pose

**Our approach:**
- Sun + fill light + emission + rim = overexposed

---

## THE DEEPER PROBLEM: WORKFLOW

From the GDC talk:
> "A workflow which let the Artist's intention carry through, right to the Final Result, was the core of our accomplishment."

### Their Workflow:
```
Artist paints vertex colors
  → Shader uses those colors
    → Preview shows exact result
      → Artist adjusts
        → Repeat until perfect
```

### Our Workflow:
```
Programmer writes shader
  → Set uniform values
    → Run game
      → See broken result
        → Adjust random values
          → Still broken
```

**We have no artist feedback loop. We're guessing.**

---

## WHAT PERSONA 5 DOES DIFFERENTLY

Persona 5's visual style characteristics:
- **High contrast** - Bold blacks, pure whites, saturated reds
- **Flat colors** - Minimal gradients, clear color blocks
- **Strong outlines** - Thick black lines on everything
- **Limited palette** - Red, black, white dominate
- **UI integration** - Interface and gameplay blend together
- **Motion graphics** - Everything has dynamic movement

Our current state:
- Low contrast (washed out or pure black)
- Broken gradients (emission blowing out)
- Inconsistent outlines (some visible, some not)
- No color palette (everything random)
- No UI style (default Godot)
- Static presentation

---

## WHAT WE SHOULD DO

### Phase 1: Fix Immediate Bugs
1. Debug why grass shader outputs black
2. Remove excessive lighting on character
3. Get baseline working before adding features

### Phase 2: Simplify
1. Remove complex lighting calculations
2. Use simple flat colors first
3. Get consistent look across all objects

### Phase 3: Add Artist Control
1. Implement vertex color support in shaders
2. Create per-character lighting rigs
3. Build tools for artists to adjust look

### Phase 4: Establish Style Guide
1. Define color palette (Persona: red/black/white)
2. Define outline thickness and color
3. Define shadow color relationships
4. Document the visual rules

---

## KEY QUOTES TO REMEMBER

> "Kill everything 3D. If you find something that looks 3D, you just have to find a way to avoid it."

> "In Cel-shading, every little noise on the surface will become extremely distracting."

> "Nature is imperfect, the artist is imperfect, therefore perfection looks 'too artificial'."

> "Photo realism is great but it's not the only route. You could be the pioneer."

---

## IMMEDIATE NEXT STEPS

1. **Check Godot console for shader errors**
2. **Simplify grass shader to solid color test**
3. **Remove character fill light temporarily**
4. **Reduce sun energy**
5. **Test each element in isolation**

Once we have a working baseline, then we can build up the style.

---

*Don't try to achieve Guilty Gear quality through code alone. Their success came from giving artists control.*
