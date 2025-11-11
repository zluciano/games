# Duel Academy Island - Top-Down Map Design

## Reference (from Yu-Gi-Oh! GX lore)
- Island is organic/irregular shaped (not rectangular)
- Volcano in the center-back area
- Main Academy Building in the central area
- Gym building beyond the beach (separated from main building)
- Harbor/Dock at the front (south) of the island
- 5 Dormitories:
  - Slifer Red: Western point of island (lowest rank, worst conditions)
  - Ra Yellow: Between Slifer and main building
  - Obelisk Blue Boys: Eastern/upper area (high rank)
  - Obelisk Blue Girls: Near boys dorm
  - Abandoned Dorm: Secluded area (forest)

## Top-Down ASCII Map

```
                    NORTH
                      |
           +----------+----------+
          /                       \
         /      [VOLCANO]          \
        /        /^^^^^\            \
       |        /       \            |
       |    [OBELISK     [OBELISK    |
       |     BLUE         BLUE       |
       |     BOYS]        GIRLS]     |
  W    |                             |    E
  E    |      [MAIN ACADEMY]         |    A
  S ---+        [=========]          +--- S
  T    |        [  DOOR   ]          |    T
       |            |                |
       |    [RA     |    [GYM]       |
       |   YELLOW]  |                |
       |            |                |
[SLIFER]---path----[COURTYARD]       |
 [RED]              |          [LAKE]|
       |            |                |
        \       [HARBOR]            /
         \        [===]            /
          \      [DOCK]           /
           +------------------+--+
                      |
                    SOUTH
                  (Ocean)
```

## Location Connections (for navigation)

### Outdoor Areas (connected by paths)
1. **COURTYARD** (central hub)
   - North: MAIN ACADEMY entrance
   - West path: RA YELLOW area
   - Far West path: SLIFER RED area
   - East: LAKE area
   - South: HARBOR

2. **SLIFER RED AREA**
   - East: path to RA YELLOW / COURTYARD
   - Contains: Slifer Red Dorm building

3. **RA YELLOW AREA**
   - West: path to SLIFER RED
   - East: path to COURTYARD
   - Contains: Ra Yellow Dorm building

4. **OBELISK AREA** (upper/north)
   - South: path from MAIN ACADEMY
   - Contains: Obelisk Blue Boys Dorm, Obelisk Blue Girls Dorm

5. **HARBOR**
   - North: COURTYARD
   - Contains: Lighthouse, Warehouse, Dock

6. **LAKE AREA**
   - West: COURTYARD
   - Contains: Lake, Beach access

7. **GYM AREA**
   - Accessible from COURTYARD (beyond beach)
   - Contains: Gym building

### Indoor Areas
1. **MAIN ACADEMY (HALLWAY)**
   - Entrance from: COURTYARD
   - Contains doors to: CLASSROOM, CARD SHOP, CAFETERIA, LIBRARY
   - Stairs to: CHANCELLOR'S OFFICE, OBELISK AREA path

2. **SLIFER RED DORM** (interior)
   - Entrance from: SLIFER RED AREA
   - Contains: Jaden's room, common room

3. **RA YELLOW DORM** (interior)
   - Entrance from: RA YELLOW AREA

4. **OBELISK BLUE DORM** (interior)
   - Entrance from: OBELISK AREA

## Location Select Menu - Regions

For the Persona 5-style location select, group locations into regions:

### CAMPUS
- Courtyard
- Main Academy
  - Hallway
  - Classroom
  - Card Shop
  - Cafeteria
  - Library
  - Chancellor's Office

### DORMITORIES
- Slifer Red Dorm
- Ra Yellow Dorm
- Obelisk Blue Boys Dorm
- Obelisk Blue Girls Dorm

### ISLAND
- Harbor
- Lake/Beach
- Gym
- Forest (Abandoned Dorm area)

## Implementation Notes

1. **Fast Travel**: Player can open map (Tab/M key) and select any unlocked location
2. **Walking**: Within each "area", player walks in 3D. Triggers at edges connect areas.
3. **Some areas are small**: Card Shop, Classroom = small indoor rooms
4. **Some areas are larger**: Courtyard, Harbor = outdoor exploration zones
5. **Story progression unlocks areas**: Some locations locked until certain story points
