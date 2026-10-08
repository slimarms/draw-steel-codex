# EotW Hero Sheet - Working Brief

> Status: WORKING - D1 frame/scope DECIDED; D2 surface + layering DECIDED; D3 layout converging
> through mock rounds 3-10 (current = round 10); handoff refreshed 2026-10-08 session 2.

## NEXT SESSION STARTS HERE (handoff 2026-10-08, session 2)

Read the ledger (bottom) first: it is the record of every decision, newest last. Then open the
CURRENT MOCK: https://claude.ai/artifact/UkGYCopdu4DAiuh2P7xUb2 - version 8 = round 10 (versions
1-7 = rounds 3-9). Source docs/eotw-hero-sheet/mock/layouts.html + data.js (pregens) + std.js
(standard actions + free strikes, tools/probe_std.py) + vet.js (veteran inventory, real tbl-gear
records) + art/. Older round sources kept as mock/layouts-r3..r9.html. The round 2 form mock
(A page / B1 hero art / B2 where-you-are) is a different artifact: BjjVgkj3vYRcGynndsQgRG
(mock/eotw-hero-sheet.html). Republish by file path to keep the URL.

Where the design stands (round 8; details in the ledger):
- LEFT COLUMN (never scrolls as a whole): the hero card at sheet size (art, name, subtitle,
  compact level row "1 [bar] 2  Victories 0" with XP on hover, S1 stamina bar + "Winded at /
  Dead at", recoveries ring + label, heroic resource icon + value, one surge icon per surge);
  then a KIT card (header = Kit, or the class's Prayer | Ward, Enchantment | Ward, Augmentation;
  the Tactician's two kits read as one kit with an inline melee choice "in town"); then a
  TREASURES card that scrolls inside itself (Leveled treasures "N of 3 carried", Trinkets,
  Consumables; equip CTA on its header; "No benefit" on armor the kit cannot use).
- MAIN: top bar (roster switcher thumbnails, Change Appearance, Edit in Builder, Close with the P3
  signal); STATS BAND = numbers row (Characteristics as big tiles; size/speed/disengage/stability
  each self-labelled; Potency with weak/average/strong) over a words row (Skills grouped by skill
  group inline, groups never split; Languages; Immunities; Weaknesses); then ABILITIES | FEATURES,
  each scrolling. Abilities follow the tagging plan; rows show action type + cost; hover shows the
  card, click pins it; free strikes + standard actions in compact two-column groups. Features:
  pillar chips + filter on the header row, collapsible sections, Show more on long text.
- TYPE SYSTEM: section headers white + larger (16px caps); stat headers gold small caps.

Open next (in rough order):
1. James's pick for size-to-potency (two groups / centred lines / grid) from round 10; the
   backdrop is decided ("where you are" + frosted translucent panels).
2. (form question settled: B2 backdrop, B1's art lives on as the card)
3. D4 skin (motion, sound, final palette - accent theme-dependence is open), D9 states (draft,
   away in a party, dead, video portraits, missing art), D7 equip interaction details
   (Equip/Unequip rules, kit-match gating, kit-less treasure rules), D8 EotW-native content
   (victory record, treasure provenance, level-up flow), copy sign-off for every [COPY] string.
4. David conversation: see "Discussion points for David" below (stamina bar, carry-three,
   panel bugs, route closing, Edit-in-Builder window, banner suppression, temp flaw, layering).
5. Then the critique round (Phase 6) and lock.

Tooling notes: headless Edge screenshots of the mock - the first run on a NEW --user-data-dir
often writes nothing; rerun on the same profile. The mock reads hash tokens for screenshots:
#<herokey>.vet.imm.prog.twokit.res.sig.pin-own-0 (load several in iframes in one page to
capture states in one shot). The DMHub bridge (localhost:19876/execute) was up this session.

David's direction (Discord, received 2026-10-08 via James; paraphrased):
- James is in charge of the EotW character sheet.
- EotW should support players keeping the SAME hero over time - "a big part of it". Target:
  1-2 VP per week, so a hero clears echelon 1 (levels 1-4) in about six months. A sense of
  progression is "super important" for EotW to be a mode people stick with.
- EotW has a different goal from the main game: it should ENFORCE EVERYTHING. The player must
  not manipulate numbers in ways the rules don't allow (no healing or damaging themselves etc.)
  - "just looking at their stats like a video game". They SHOULD be able to move items around
  and equip items.
- Implication: near-term heroes are levels 1-4 (design for that), with headroom to 10.

Still-true facts from the session-1 handoff:
- Q6: the character panel stays the in-encounter companion; its Summoner/Elementalist blocks
  are existing bugs - DO NOT TOUCH them in this project (flagged to David).
- The C key opens the full EDITABLE sheet for the selected token (InputController.cs:1360 ->
  commands.txt:249 Commands.sheet -> ShowSheet(), no access check); route closing is in scope
  (D1-Q4) and on David's list.

> Driver: James. Loop: feature-design-personal. Started 2026-10-08.
> Predecessor (the LATEST sheet work, used as the base): docs/features-tab-design/brief.md
> (Merge v6.2, DESIGN LOCKED 2026-08-20 for the main-game sheet; then backlogged) +
> docs/features-tab-design/sheet-concepts.html (artifact f0f7adfd-182a-408b-a17c-dfa6079ae8cc)
> + top-zone design canvas (artifact 005d978a-3cbe-4e85-99b7-6c4d1696a330).
> NOT used: the July work on branch codex/character-sheet-redesign (earlier lot; superseded).
> EotW source of truth: EncounterOfTheWeek/EncounterOfTheWeek.md (David's design doc) + code.

## Frame (PROPOSED 2026-10-08 - awaiting James)

- Problem: Encounter of the Week needs its own hero sheet: in David's EotW visual language,
  strict (shows the hero exactly as the build and the rules decide; no custom modifications,
  no custom features), keeping the Merge's feature tagging and space discipline but dropping
  per-class colour coding, with the inventory visible and reachable.
- Personas (proposed):
  - EotW player at the table: often newer to Draw Steel, gamified/guided context (the builder
    is guided, the encounter is scripted). Wants "what can my hero do / what do I have".
  - Roster keeper in town: up to 12 heroes, 4 active; compares heroes, picks a party.
  - Teammate: reads another player's hero (read-only, detached-character path).
  - Dropped vs the main game: the Director persona (directorless) and the power-user EDITOR
    persona (strict mode). That removes most of the Merge's gap ledger (edit paths, authoring).
- Why now: EotW is landing well internally; David trialled custom UI in its builder; David's
  own doc already plans a read-only EotwHeroSheet (build step 5, unbuilt); the main-game sheet
  redesign is backlogged, so EotW is a contained place to land and test the design.
- Done = a decided brief + mocks James reacts to, aligned with David (EotW owner) before build.
- Inherited constraints (from the Merge ledger + app direction): labels above values; numerals
  in Inter, never the display font; minimum legible size = the "Wealth"/"Main Action" label
  scale; rounded corners only; feature tag vocabulary (Combat/Exploration/Montage/Negotiation/
  Respite chips; Hidden/Ability/Trigger display kinds; Core Feature pin); ASCII-only Lua copy.
- Standing-principle tension to note: "inform, don't enforce" is a MAIN-GAME principle. EotW is
  a deliberately strict mode, so enforcement is the point here (strict:* settings are forced).

## Evidence appendix

### E1. Prior work alignment (2026-10-08)

- Merge v6.2 shape (main game, level-10 Tactician data): left identity column (round class-
  coloured portrait medallion, name, class line, victories notch bar, level/XP/wealth/renown,
  languages +N more, Titles/Customize Appearance/Player buttons, follower chips, 5-slot
  inventory preview); instrument-bar top zone (stamina + gauge w/ winded tick, temp,
  recoveries, class-tinted Focus/Command/Surges/Hero Tokens); row 2 (characteristics with
  potencies footer | kit card w/ two-kit toggle | movement 2x2 | immunities & weaknesses);
  skills right column; Abilities and Features scroll panels below, level by grid construction;
  pillar chips + text filter + Show All eye + "N to choose" badge; cursor-only editing.
- Screenshot of the locked mock: session scratchpad shots/merge-v62.png (headless Edge, 1920w).
- Open at lock (main game): gap ledger of ~12 edit/authoring gaps, Manage Titles + Follower
  modals, monster sheet concept, ability style pick, Notes home. Most are EDIT/AUTHORING
  items that a strict EotW sheet does not need.

### E2. EotW mode facts (design doc, verified against code where marked)

- Directorless: host is a player; Monster AI runs monsters; strict settings forced every host
  tick (doc 1900-1912): strictmovementrules, strict:movement/targeting/resources/inventory/
  rolls; enemy stamina as bars; monster info auto-learn.
- Heroes: town roster (Blackbottom; up to 12, 4 active), forced to exactly level 1 on arrival
  (NormalizeHeroLevel); progression is OPEN (doc 1079-1101: levels vs treasure/titles/renown).
- What comes home today: a Victory per won encounter (once per encounter, "Already
  Completed"); non-consumable treasure gained beyond the arrival snapshot (montage haul,
  delve chests); death -> graveyard (burial write-back still open).
- In-game HUD (doc 2314-2345): no rails/panels/compendium; right-edge roster of hero cards
  (portrait, name, player, stamina bar w/ temp, heroic resource, surge icons, condition chips,
  trigger badge); clicking a card opens the character panel beside it, read-only for everyone.
- Montage stage (doc 2870-2916): Opportunities left / Threats right; hero cards bottom row
  with the acting hero in gold and the characteristic + skill in use highlighted; scene stage
  with portraits that fade at top and sides, speaker grows; haul strip of item icons.

### E3. David's own sheet spec (doc 1684-1714, UNBUILT; no code on any branch 2026-10-08)

- EotwHeroSheet.Show(token): read-only full-screen panel, rebuilt each open, NO edit controls.
- Header (portrait, name, "Level 1 Ancestry Class (subclass)", culture, career, complication);
  stats (characteristics, Stamina/Recoveries/Recovery Value, Speed, Size, Stability,
  Disengage, Potencies, heroic resource name); skills + languages flat list; kit name +
  bonuses; abilities as ActivatedAbility:Render cards by action type; features by source
  (complication benefit/drawback via CharacterComplication:Render); inventory list only.
- Opens from the Guild row and town strip card; later the in-game hero card and other
  players' heroes. Actions: Close, and Edit in Builder (own hero, before its first encounter).
- Hardening (later): token radial menu, "sheet" keybind, character-panel context menu can
  still reach the full editable sheet in an EotW game.
- Builder look note (doc 1485-1488): the EotW builder reuses CBStyles' cream-on-near-black
  palette + EotwHeroCard rules; "same styling as today" was David's sheet intent.

### E4. Live screenshots (2026-10-08, Dev Game, Void scheme)

- EotwHeroCard rendered for 6 pregens (temporary overlay, removed): shots/eotw-cards.png,
  shots/eotw-cards-zoom.png. Trading-card hero: full-bleed cover-cropped art in a tall rounded
  card (132x188 base), name in a bold serif over a dark bottom gradient, subtitle line, trained
  skills in small text, characteristic letter chips (M A R I P with signed values) down the
  right edge, condition chips top-right (dark, red-bordered), stamina bar (green; orange when
  winded) with value text, recoveries in a ringed circle, heroic resource icon + value.

### E5. Level-1 density probe (2026-10-08, live, 7 pregens)

- Abilities: 22-25 per hero, of which 14 are Common Abilities (standard actions), 2 Move,
  1 Hidden, 2-3 basic attacks (free strikes); the hero's OWN abilities = 2-4 signature +
  1-2 heroic (+0-1 ancestry/kit "Ability").
- Features (BuildIndex): 26-35 rows; 22-31 display-normal; buckets per hero ~ class 4-9,
  culture 5, skill 5-7, career 2-4, ancestry 2, language 2, kit 0-1, perk 1, effect 0-2.
  After folding skills/languages/culture aspects into lists, ~12-18 substantive features.
- Implication (revised after James 2026-10-08): level 1 is only the launch state. EotW is
  planned to go up to level 10, so the level-10 density the Merge was sized for is the stress
  case again; the sheet must scale L1 -> L10 without a different layout per level.

### E6. Portraits (agent report 2026-10-08; engine source read-only at D:\dmhubclient)

- The EotW card IS the art: the card panel's own bgimage = tok.offTokenPortrait, cropped with
  tok:GetPortraitRectForAspect(cardW/cardH, portrait) (EotwHeroCard.lua:1289-1343). The engine
  builds that rect from the token's own framing (portraitZoom -> appearance.tokenZoom,
  portraitOffset) and stretches the square crop to the aspect (CharacterToken.cs:4283-4353,
  22786-22797), so whatever the player framed in the builder frames every card. Returns
  (0,0,1,1) until the image record/sprite loads -> re-run until loaded.
- Default art = the class's full-length illustration (data/images: ancestry art all 1000x1500;
  classes mostly 1000x1500, Conduit 3400x4450; Shadow/Summoner/Talent/Troubadour report 8x8 =
  placeholder metadata, real size unverified). EotwBuild.SetPortrait clears offTokenPortrait so
  token and card share one image (EotwBuild.lua:1935-1954); SyncDefaultPortrait follows
  ancestry art until a class is picked, then class art (1992-2030).
- Card recipe: base radius 8, border 1 #000000cc, art untinted (selfStyle bgcolor white),
  #151515 before load; floating bottom plate #000000c0 (own hero #0d1e31d0) radius 8 with name
  12pt bold, player line 9pt #c6d0da, recoveries circle + state-tinted stamina bar, resource row;
  characteristic chips 36x15 #000000b0 down the right edge from y=34; condition chips top-right
  26px #000000cc border 2 #cc2222; pulsing "!" trigger badge top-left; surge pips bottom-right.
  States: hover brightness 1.15; own hero border 2 #6fa8ff; active border 3 #ffd66b + scale
  1.06; hurt/heal full-card washes fading 0.45s; stage-acted = desaturated + dimmed.
- Other EotW portrait forms: party/picker card 176x235 (3:4) with identity plate; Guild row
  72x96 with gold border + stripe when active; builder Appearance preview = the ROUND TOKEN look
  (240x240, bgimageTokenMask frame) with drag/zoom; builder detail pane = class/ancestry art
  cover-cropped to fill the 500px pane under a #10110Fe6 text band; montage scene stage =
  frameless standing figures (230x300) with edgeFade 0.15 (a UV fraction, not pixels), speaker
  brightens + scales 1.06 from the feet, gold 21pt name.
- Main game today: live sheet = 256x256 round token image (gui.CreateTokenImage) with frame
  mask (DrawSteelChararcterSheet.lua:1339-1415); Appearance tab = round avatar editor + separate
  offTokenPortrait editor; in-game character panel tile 90x120 (MCDMCharacterPanel.lua); app's
  standard portrait shape is 3:4 (Styles.portraitWidthPercentOfHeight = 75).
- Reuse: EotwHeroCard.CreateHeroCard is a global (loads at titlescreen and in game) but fixed
  132px wide (uiscale to enlarge). For a large standalone portrait, copy the core recipe
  (offTokenPortrait + GetPortraitRectForAspect with the panel's real W/H, retry until loaded);
  CoverCrop (EotwBuilder.lua:511-529) for non-token art; never rebuild the portrait panel on
  refresh (video portraits restart). Gotcha: when offTokenPortrait differs from portrait, EotW
  applies the token's zoom/offset to that other image (main game shows it uncropped).
- Unverified: video portrait crop behaviour; pregens' separate offTokenPortrait.
- LARGE-PORTRAIT ADDENDUM (refocused report, same day):
  - Class art for SHADOW, TALENT and TROUBADOUR is MP4 VIDEO (824-826x1080 frames; the repo's
    8x8 records are the video placeholders - confirmed from the local cache). Animated portraits
    already exist; a big sheet portrait would show them moving. Video has no bgsprite, so
    CoverCrop-style measuring fails (use gui.GetImageDimensionsCallback); GetPortraitRectForAspect
    likely works once a preview frame exists (unverified).
  - Aspect choice for a big standalone portrait: 0.70 (e.g. 280x400) = exactly the card crop
    (trims ~2.5% top/bottom of 2:3 art); 3:4 (app standard) trims ~5.6%; 2:3 shows the whole
    illustration. Crop centre = the player's token framing; there is no separate focus field.
  - Resolution: stills give ~1000 source px across at 400 units wide (crisp at 4K); videos
    ~755-810 px (about 1:1 at 4K). Soft: uploads under ~500px wide, zoom <= ~0.6 on high-DPI,
    safe-mode low-def. Crops badly: square/round token uploads lose their sides at 0.70; zoom
    above ~1.4 may smear past the image edge (inference).
  - The frame itself has NO gradient or vignette; all darkening on the card comes from the
    stat plates/chips (no text ever sits directly on art). Without plates, precedents are the
    town's black scrim gradient (alpha 0.78 -> 0.45 -> 0) and the stage's offset shadow label.
  - Recipe: plain gui.Panel whose own bgimage = tok.offTokenPortrait, selfStyle bgcolor white,
    selfStyle.imageRect = tok:GetPortraitRectForAspect(W/H, art) with the panel's REAL numeric
    W/H, refreshed until loaded; class rules for border/state; a dark backing panel behind
    (transparent/cutout art). Recommendation: lift the card's crop lines (EotwHeroCard.lua:
    1332-1342) into an exported EotwHeroCard function so card and sheet share one crop path.
    Do not use CoverCrop for the hero portrait (it ignores the player's framing).
  - Overlays on a 400px portrait: either uiscale ~3 (also scales border/radius) or re-sized
    fonts/chips/band keeping the card's colours and alphas.

### E7. David's EotW visual language (agent report 2026-10-08)

- THREE PALETTES, ONE GRAMMAR. (a) Town/Guild: warm umber grounds (#0b0907, #14110d, #221b13),
  antique gold #d9b56a (overline, rule, section heads, active stripe), bronze #8c7a55 frames,
  parchment text #f6ead0/#efe4cc, dim #c9bfa9. (b) Stage/HUD/hero card: cool slate-black
  translucent plates (#0b0e12e0, #0f1318e6, #000000c0), bright gold #ffd66b = active/landed/
  speaking, blue #9cc4ff = rolls/assist/Intelligence, violet = knack/unlocked, green = applied
  rules, red = locked/hurt; opportunity gold #d4a83a vs threat red #c0392b borders. (c) Builder:
  a frozen literal copy of the old builder's cream-on-near-black (CREAM #DFCFC0, TAN #BC9B7B).
- Shared grammar: hard-coded hex (only the stamina bar uses theme tokens @success/@warning/
  @danger/@accent); rounded everywhere (6-12 surfaces, 3-6 chips); dark translucent panels over
  full-bleed art; STATE BY BORDER WIDTH LADDER 1 -> 2 (selected/mine) -> 3 (active/droppable)
  -> 4px (flashing), glow = brightness 1.15-1.5, no drop shadows; lots of motion (staggered
  fade/scale entrances, pulses, drop-ins, washes, a sound on every press).
- Typography: Berlingske Slab throughout (themed @label = Berling, or engine default), weight
  via bold; italic = flavour; MCDM Display only for big place names (68pt). NUMBERS = the same
  slab face, bold, always signed (%+d) - NOT Inter. Victory screen uses MCDM Book.
- Signature move = the LOCATION SCENE (EncounterOfTheWeek.lua:4294-4412): full-bleed cover-fit
  art (CreatorCredit.Backdrop), a left shade gradient, top-left header (gold letter-spaced
  overline "BLACKBOTTOM", display-face place name over a 340x2 gold rule fading right, italic
  flavour line), translucent card on the right holding the controls, creator badge bottom-right.
- Stats grammar: icon + bold number, signed values, colour = state, numbers centred on bars.
  Characteristics as "M +2" chips (card), 18-bold value over a 12pt letter (Guild), 34pt boxes
  (builder). Pools (Malice / Hero Tokens / Intelligence) = icon + number cells, explain on hover.
- Theming: effectively FIXED DARK. Builder/stage re-merge on OnThemeChanged but their own colours
  are literals, so only stock controls follow the scheme. Town uses legacy Styles (not themed).
- Buttons: no EotW button class (stock gui.Button; legacy square buttons in town); the only
  bespoke control is the gold-edged back pill. Destructive = two-click confirm.
- In flux: the accent hue (David swapped gold -> cream 2026-10-06 in eff354c5; commit dcc848b0 by
  "Verisim" reverted to gold 2026-10-07); two golds coexist (#d9b56a town vs #ffd66b stage/card).
- Reusable today: EotwHeroCard.*, CreatorCredit.{Backdrop, Badge, ReplayFade},
  EotwBuilder.Confirm/ItemDetail, EotwRoster.FormatDetails. Would need lifting out: SceneHeader/
  BackButton/LocationScene (closures in the town screen), ModalFrame/GUILD_STYLES (roster
  locals), builder RULES/CoverCrop, stage StageRules.
- Conflicts with standing directions to resolve: STYLE_GUIDE "tokens only / no inverse selected
  fills" (EotW uses literals and an inverse cream selected card); David's main-sheet directive
  "numerals never in the MCDM font" vs EotW's slab-bold numbers; theme-scheme support (EotW is
  fixed dark; the main sheet follows the colour scheme).

### E8. Inventory model, treasure data + rules, sheet drift, tag status (agent 2026-10-08)

INVENTORY MODEL (code)
- creature.inventory = {[itemid] = {quantity, slots}}; creature.equipment = {[slotid] = itemid}
  (Character.lua:84-90; Creature.lua:4519). Draw Steel uses slots leveled1-5 + trinket1-10
  (DrawSteelInventory.lua:3722-3731) and mainhand1 as the light source; the engine's armor/hand/
  belt/attune slots are unused 5e leftovers (Creature.lua:4408-4440).
- EQUIPPED MEANS ACTIVE: item features apply only from slots in use (FillEquipmentModifiers,
  Creature.lua:5382-5408); consumables apply while merely carried (:5410-5425). An unequipped
  trinket or leveled treasure does nothing.
- Inventory tab today: 6x8 paged grid + "Equipped Treasures" panel (5 leveled slots, 10 trinket
  slots), equip by drag, unequip by right-click/drag; no weight, no currency; 5e rarity frames.
- strict:inventory (forced on in EotW, EncounterOfTheWeek.lua:3151) ONLY hides Add Items /
  Party Inventory / Regenerate for non-Directors (DrawSteelInventory.lua:1550-1554). It does
  NOT gate the item right-click menu: Give To, Split/Merge, Make Unique, Edit Item, Duplicate
  Item, SET QUANTITY, Drop, Destroy - a cheat path wherever an EotW player can reach that tab.
- EotW flow: montage/narrative/delve chests GrantItem into the inventory and log a haul;
  arrival snapshot -> TreasureGained (non-consumables beyond the snapshot) -> victory card ->
  outcome.treasures -> EotwRoster.ApplyOutcome GiveItem (EotwRoster.lua:429-522). GAP: WON
  TREASURE ARRIVES UNEQUIPPED, SO IT IS INACTIVE, AND NOTHING IN TOWN CAN EQUIP IT. The sheet
  needs an equip action, or treasure must auto-equip on the way home. Items also gate montage
  options ("you carry X" reads inventory AND equipment, TestRiders.lua:1135-1148).
- Level-1 starting treasure only via gold-tier Grant Treasure complications (Amnesia, Secret
  Twin -> a 1st-echelon trinket via a Claim button on the Features tab).

TREASURE DATA (data/objectTables/tbl-gear, 401 rows; 114 are treasure proper)
- Consumables 38 (19/9/7/3 by echelon), trinkets 33 (16/9/6/2), leveled 40 (armor 11, implement
  6, weapon 18, other 5), artifacts 3. No leveled-subtype field: armor/implement/weapon is
  implied by keywords only.
- Body keywords on 29 treasures: Neck 12, Ring 4, Head 4, Hands 3, Arms 3, Feet 2, Waist 1.
  Keywordless trinkets: Deadweight, Divine Vine, Gravekeeper's Lantern, Key of Inquiry, Quantum
  Satchel, Scannerstone, Stop-'n-Go Coin. Data gaps: Mirage Band and Mask of the Many lack Head;
  Gravekeeper's Lantern lacks its 4th echelon.

TREASURE RULES (Heroes; extract at docs/feature-metadata-incremental/refs/heroes_pages.txt)
- Worn (p.313): body keywords Arms/Feet/Hands/Head/Neck/Waist + Ring are a GUIDE to where an
  item is worn; no numeric cap - "as long as the Director deems it reasonable", and if too many,
  none work. Sets must be worn whole.
- Wielded (p.314): weapons, implements, armor, shields; wield as many as feasible but an
  ability benefits from ONE weapon or implement at a time. Weapon/armor treasures only give
  benefits when their keyword matches the KIT's equipment (else improvised). Stamina/damage
  bonuses from two treasures do not stack (higher applies) unless the item says so.
- Leveled (p.327): benefits at 1st/5th/9th level, cumulative. "Carry three safely": more than
  three leveled treasures carried -> a Presence test at every respite with real penalties.
- Consumables and trinkets: carry any number. Gear (p.18): Draw Steel does not track mundane
  gear; no attunement, no encumbrance. Pacing (p.397): about one trinket per hero per echelon,
  two leveled treasures per hero by 10th level; a level-1 hero starts with nothing.
- Assessment: a rules-faithful slot display = a WORN doll (7 body keywords) + a WIELDED block
  derived from the kit (armor/shield, weapon/implement; mark "fits your kit") + a leveled
  counter "N of 3 carried". Never slotted: consumables (list + quantity), keywordless trinkets
  (carried), mundane gear. Diablo-style fixed one-per-slot caps are ARTISTIC LICENCE - but in
  a directorless mode a codified cap is a reasonable stand-in for "Director deems reasonable".

SHEET DRIFT SINCE 2026-08-20 (the August audit's anchors drifted 2-120 lines; table in report)
- New since the audit: Grant Treasure picker + Claim button on Features rows (modifier
  CreateSheetPanel hook; the only treasure control on the Character tab); characteristic cap
  row in the stat popup; template traits list (monster-facing); modifier-granted keywords;
  Inventory tab lost the Director loot roller; Appearance gained Footprints + Blood dropdowns.
- Already there but missing from the audit: a "Treasures" bucket on the Features tab (inventory
  + equipped minus light/projectiles/ingredients; no equipped-vs-carried distinction).

TAG STATUS
- Shipped to main (2026-08-13/14): GameSystem.RegisterFeatureTag, DisplayKind, display-kind
  suppression + Show All toggle. NOT built: pillar chips and the Core Feature pin (mock-only).
- Hero data tagged (b72fa387): races 12/12 files, subclasses 45/45, all 11 live class files.
  CORRECTION (verified 2026-10-08 after James queried it): the 14 untagged files in
  objectTables/classes (Exorcist, Oracle, Paragon, Reaver + 10 domains) are hidden: true
  soft-deleted legacy copies; the live versions sit in objectTables/subclasses and ARE tagged
  (Exorcist 11, Oracle 12, Paragon 12, Reaver 17, every domain 1-2). No tagging gap.
  Totals: Ability 503, Combat 391, Hidden 242, Exploration 135, Respite 66, Trigger 62,
  Negotiation 28, Montage 6, Core Feature 3. Montage is nearly unused - matters for EotW.

### E9. Strictness and every route to a sheet (agent report 2026-10-08)

- NO STRICT SETTING TOUCHES THE SHEET OR PANEL. strict:movement/targeting/resources/rolls gate
  the map, action bar and roll dialogs; strict:inventory only hides Add Items / party / loot
  buttons (DrawSteelInventory.lua:1552). Stamina edits, custom modifications, features,
  abilities, characteristics, Victories, XP, titles and level are all ungated on the full
  sheet. Enforcement is client-side (PERMISSIONS_MODEL_REFERENCE.md:237-242).
- The full EDITABLE sheet is still reachable for EotW heroes:
  - Town: the strip card ALWAYS opens it (EncounterOfTheWeek.lua:4448-4473); the Guild pencil
    opens it once the hero has a recorded victory (EotwRoster.lua:927-949); heroes away in a
    party are still editable (no away check in EditHero/PushHero).
  - In game: "c" key (core Commands.sheet, no access check) and "i" key (full inventory);
    token radial "Character Sheet" + "Inventory"; global search "Show on Character Sheet"
    (only the compendium bucket is suppressed); chat macros /opensheet, /createcharacter,
    /giveitem, /granttitle, /applyongoingeffect (none gated); the Character dock panel via
    /togglepanel character (its row right-click opens the sheet); Journal-shared characters.
  - Closed already: the HUD card (opens the character panel read-only), stage cards, the token
    corner launcher, the panel's own sheet button in view mode.
- Read-only today exists ONLY for the character panel: the custom interface's
  characterPanelAccess returns "view" for player-controlled tokens (EncounterOfTheWeekHud.lua:
  977-988 -> CharacterPanel.TokenAccessLevel) and ~30 mutating handlers early-return on
  TacPanel.IsReadOnly. The main sheet has NO read-only mode, and its engine harness diffs
  properties every frame and uploads any change (CharacterSheetHarness.cs:356-388).
- Redirect chokepoint: every ShowSheet goes through the sheet framework's single
  show(info, tabid) handler (CharacterSheetFramework.lua:1433-1442) - the place to route EotW
  heroes to an EotW sheet. The custom-interface hook has no sheet hook today; the hero card
  takes opts.click to replace its default.
- Treasure-inflation paths: TreasureGained is additive vs the arrival snapshot and the town
  never subtracts losses, so Give To (starting items), Set Quantity, Make Unique and Duplicate
  all create "gained" treasure. The stage's own give is safe (moves only this game's gains).
- Rules-relevant editing feeds montages: knacks gate on Wealth/Renown/Level/Victories, titles,
  perks, items, movement types, immunities, characteristics etc. (TestRiders.lua CreatureFacts
  955-1170); no EotW source grants Wealth/Renown/titles, so town edits are the only way they
  change today - an exploit path into montage secrets.
- Lifecycle facts: CanRebuildHero = no recorded VICTORY and not away (a hero who lost or died
  stays rebuildable); placed copies are detached from lobby sync and clamped to level 1; dead
  heroes get no Victory and no outcome (no burial write-back yet) and come home unchanged.
- Values that change during play: stamina/temp/recoveries/max stamina/recovery value (combat +
  montage effects), heroic resource and surges (rules + casts), conditions, hero tokens (party
  pool), inventory (montage grants, lose-a-consumable, stage give, consumable use). Victories
  are host-only.

### E10. Mock v2 layout audit (2026-10-08 session 2; headless Edge at 1920x1080)

Shots: docs/eotw-hero-sheet/shots/round2/{A,B1,B2}-{town-fury,town-conduit,game-shadow}.png
(Fury L1 mine, Conduit L6 mine, Shadow L1 teammate in game). Render recipe:
tools/mockshot_template.html.txt (mock with page chrome hidden; hash = form,ctx,hero).

- CLIPPING (B1, B2 only; A fits): the main column runs past the right edge - Close button,
  heroic resource + surges, Skills, the Features "Show all" toggle and the feature tag chips
  are cut. Cause: the top bar asks for roster tabs (6 x ~150px) + Change Appearance + Edit in
  Builder + Close on one row (~1500px) inside a ~1300px column (mock CSS lets it push the
  column wider instead of wrapping). Design cause: the top bar carries too much.
- EMPTY NEXT TO CRAMPED: the vitals bar leaves a 600-700px gap between Recoveries and the
  heroic resource, while the stats row under it squeezes five boxes (characteristics, kit,
  movement, immunities/weaknesses, skills) so skills wrap to 2-3 lines and kit bonuses drive
  the row height (Shadow: 6 bonus lines -> characteristics and immunities boxes half empty).
- COLUMN BALANCE BY LEVEL: at L1 the Abilities column holds 3-5 own abilities and is half
  empty (Fury: empty from ~y880), while Features is long and dense; at L6 both fill. The
  1 : 1.15 split is fixed regardless of content.
- IDENTITY COLUMN: in A, empty below Inventory at L1 (~200px); in B1 the art spends 560px of
  width on one image and crowds the identity plate into the bottom corner.
- READABILITY: feature text runs ~110 characters per line in the ~780px Features column; long
  lore features (Conduit "Grole the One-Handed") dominate even clamped to 152px. Pillar tag
  chips sit far right, away from the feature name.
- SMALL: roster tab subtitles fade into the mask ("Level 6 Condu..."); the teammate owner chip
  wraps "read-only" onto a second line; the heroic resource reads as a separate widget at the
  far right of the vitals bar.
- NOT YET SHOWN: free strikes and the 14 common abilities (not in the export); equip CTA.

### E11. Where in-game prompts mount, and what that means for the sheet (agent 2026-10-08)

Code-verified (runtime not run); spot-checked GameHud.lua:1734-1812 + CharacterSheetMain.lua:14-39.
- HUD z-order = sibling order of one panel tree (GameHud.lua:1734-1807; no z-index). Bottom to
  top: initiative bar (L2) ... documents layer L8 (rails incl. EotW roster/pools/corner
  buttons, every panel window, presented dialogs incl. the montage/narrative STAGE) -> action
  bar L9 (TRIGGER PROMPT CARDS, save prompts and countdown dice are its children) -> reaction
  bar -> ability display L11 (ability card + embedded ROLL DIALOG, shared AI rolls) ->
  standalone roll host -> mainDialogPanel L13 -> shop -> modal layer L15 (jumps to top once
  used) -> popups -> legacy roll dialog -> victory screen L22 -> tip banner L23 ("Waiting
  for..." AI banner). Tooltips, context menus and 3D dice draw above the whole HUD.
- TODAY'S FULL SHEET mounts on mainDialogPanel (L13), so it COVERS trigger cards, save prompts,
  roll dialogs, the stage and the initiative bar; it also hides the "Waiting for..." banner
  (dmhub.inCharacterSheet). So "prompts above the sheet" is NOT how things work today.
- No existing layer sits between HUD furniture and prompts. Candidates: (C) a new layer
  between L8 and L9 - prompts, rolls, banners, victory above; initiative bar, roster, stage,
  windows below; the action bar STRIP comes above too (trigger cards are its children).
  (E) a new layer just above L1 - the sheet sits under the WHOLE HUD like a scene: every
  prompt plus initiative bar, roster, pools, action bar, open windows draw over it, so the
  sheet layout must keep clear of them. (A) mainDialogPanel = today's problem. (B) modal =
  reject (covers everything, kills hotkeys, defers the EotW victory award). (D) sibling on
  L8 raised on open = fragile (L8 reshuffles on window clicks/rail rebuilds) but is the only
  one where a sheet opened DURING a stage lands above it.
- Stages: the stage is a presented dialog on L8. With C a stage that starts while the sheet is
  open is hidden under it; with E a sheet opened during a stage is hidden under the stage.
  Either needs a rule (stage starts -> stage covers; opened during a stage -> sheet on top).
- Escape: one global priority list, ignores z-order (InputController.cs:476-503; ranks in
  input.txt). Sheet should take Escape at <= 14 (EXIT_DIALOG) so roll dialogs (15), modals
  (16), popups (17) win.
- A full-screen sheet with a background blocks map clicks: map-targeting prompts (retarget,
  forced movement) cannot be answered under it.
- Side finding (David): the "Waiting for..." banner also hides while ANY panel window is open
  (journalViewer class, GameHud.lua:2887-2908) - including the hero-card character panel and
  Chat in EotW.
- Build notes: do not open via ShowSheet and do not use the journalViewer class (both hide
  the banner); do not borrow the stage's hideactionbar trick (hides trigger cards too); C/E
  need a core GameHud change or a runtime insert re-done on HUD rebuild.

### E12. Precedent scan: where sheets put skills, vitals, abilities, gear (agent 2026-10-08)

Session-scratchpad files (not kept): official sheet renders render/standard-p1..p5.png +
expanded-p1..p6.png (from the codex's own data/pdfDocuments/ds-charactersheet-standard.yaml),
Forge Steel / Draw Steel Plus / Compact Beyond screenshots.
- RULES: a test = the Director names a characteristic, the player proposes a skill, +2 if it
  applies (Heroes p.249; heroes_pages.txt ~20694); a skill can apply to ANY characteristic that
  makes sense (p.254, ~21150-21153); skill tables carry no characteristic. => skills sit BESIDE
  the characteristics as one test block; nesting under one characteristic (D&D) misstates DS.
- DRAW STEEL SHEETS BURY SKILLS: official PDF = p1 one-row vitals band (characteristics + size/
  speed/disengage/stability, stamina, recoveries, resource, surges - the paper ancestor of our
  instrument bar), kit box, conditions, potency rail, "Your Turn" standard-action list; SKILLS ON
  PAGE 2 with the backstory (all 57 as a diamond checklist by group). Foundry DS: skills one line
  at the bottom of the Stats tab. Forge Steel: skills last in the right sidebar, below the fold.
- DRAW STEEL PLUS (community Foundry re-skin) = the closest precedent to our fix: header =
  portrait card + name + origin chips + characteristic badges; PERSISTENT LEFT COLUMN = stamina,
  recoveries, surges/resource, 2x2 movement, immunities/weaknesses, TRAINED SKILLS AS CHIPS;
  content beside a vertical icon tab rail.
- PATTERNS: (1) persistent stat rail + tabs/pages by job (D&D Beyond, Compact Beyond - "No more
  digging around through multiple tabs to ... find the skill list" - Forge Steel rail, DS Plus,
  Diablo IV, Owlcat) - praised; hated failure = hopping tabs for something checked constantly.
  (2) skills beside what you roll; trained-only list is short (5-11 at L1, ~10 at L10 Tactician).
  (3) vitals ride with identity (DnDB header, Darkest Dungeon, DS Plus column, EotW hero card).
  (4) abilities by action economy; own abilities as cards, standard actions compressed/opt-in
  (official "Your Turn" list; Forge Steel opt-in; DnDB beginners want them listed but hideable).
  (5) gear: paper doll in games vs category lists in TTRPG tools; DS has no body slots, so a doll
  invents structure (official p5 = titles, trinkets, leveled treasure w/ carry-three counter,
  consumables). (6) glance/detail split by click depth, not scrolling; roster screens want key
  status visible without opening each hero (relevant to the 12-hero roster).
- Owlcat lesson: fixed blocks overflow as content grows (attack block built for 4 values needed
  6); avoid spreadsheet feel.

### E13. Kits, the Tactician's two kits, and kit-equivalents (agent 2026-10-08)

- TACTICIAN (Field Arsenal, Heroes p.177; extract 14880-14910): uses TWO kits incl. both signature
  abilities; where both kits grant the same benefit you pick one and cannot change it until you
  finish a respite; changing a kit is itself a respite activity. Codex: numKits 2
  (tactician.yaml:4257); kitid + kitid2 (CharacterKitChoice.lua:123-140); character:Kit() returns
  Kit.CombineKits (MCDMKit.lua:347-458): name "A/B", stamina/speed/disengage/stability/range/
  reach/area take the MAX automatically; only the DAMAGE bonus is choosable, per type (melee/
  ranged/supernatural), stored in levelChoices.kitBonusChoices[type] = kitId (Kit.
  DamageBonusSelected 317-340; unset = higher tier-sum, tie -> kit 2). The toggle exists only in
  the new builder (KitDetail.lua:136-200); the live sheet has none; the EotW builder has none, so
  EotW tacticians get the default. (Divergence: the rules let you choose ANY overlapping benefit.)
- Other switchable kit bonuses: Beastheart companion melee bonus (kit vs +0/+0/+4, chosen with the
  kit; levelChoices.companionBonusChoices); Stormwight Menagerie (8th level) kit swap at respite
  (text only in the codex).
- KIT USERS: censor, fury (berserker/reaver martial; stormwight kits), shadow, tactician (2),
  troubadour, beastheart. KIT-EQUIVALENTS (1-pick feature choices with ordinary modifiers):
  Conduit = Prayer + Conduit Ward; Elementalist = Enchantment + Ward; Null = Psionic Augmentation
  (no ward); Talent = Psionic Augmentation + Ward; Summoner = Summoner's Kit (an implement; from
  3rd level) + 1-3 wards. Bonus types overlap kits (stamina, stability, speed/disengage, damage,
  distance) plus saves, immunity, surges and triggers. No codex helper returns "kit or
  equivalent"; values are stored inconsistently, so a sheet should read EVALUATED stats.
- TREASURE GATING: a hero without a kit cannot benefit from weapon/armor treasures unless a
  feature allows it (Heroes p.314; extract 26151-26159) - e.g. the light-armor "Battle"/"Soldier's
  Skill" options. Relevant to the equip rules (D7).

### E14. Ability preview, filtering, and action/cost labels (agent 2026-10-08)

- PREVIEW CONVENTION = HOVER, everywhere: the EotW builder shows the card on hover in a fixed side
  pane (EotwBuilder.lua:1218-1220, AbilityCard :532-534 = ability:Render, no token); the live
  sheet's ability rows set a hover tooltip CreateAbilityTooltip(ability, {token, width=500})
  (DrawSteelChararcterSheet.lua:479-487; click only collapses headers); the action bar's hover
  feeds a HUD sidebar (AbilitySidebar.lua:1745-1812, HUD-only). ONE reusable card: global
  CreateAbilityTooltip(ability, options) (ActivatedAbilityEditor.lua:4) -> ActivatedAbility:Render
  (MCDMActivatedAbility.lua:1408); options token/width/pad/maxHeight/hideTabs/quietTitleBand/
  cardScale; returns nil for notooltip clones; works for global standard actions and free strikes.
  Triggered actions from GetTriggeredActions() render via TriggeredAbilityDisplay:Render.
- FILTERING: tags and DisplayKind apply to FEATURES only; no ability list reads them. Action bar
  drops categorization "Hidden"; the live sheet filters nothing (Life Domain Effect lands in
  "Other Abilities"). Recommended: GetActivatedAbilities{bindCaster=true, characterSheet=true}
  WITHOUT excludeGlobal (free strikes + standard actions are global rule mods), drop
  categorization "Hidden", triggered actions from GetTriggeredActions(), features where
  DisplayKind() == "normal".
- DOMAIN EFFECTS (Conduit): real rules effects, but only used when the Prayer roll is a 3 (or as
  a maneuver at 10th level); categorization Trigger, tag Combat, no Hidden anything
  (subclasses/life-domain.yaml:169-255). 11 of 12 share one ability guid (do not de-dupe by guid).
- LABELS: the DS card shows the cost in the title ("Name (3 Piety)"), the kind on the type line
  ("Signature Ability" / "Heroic Ability" / action name), and the action type on the keyword row
  ("Main Action", else "Free") (MCDMActivatedAbility.lua:2467, 2656, 2817-2847, 991-1012).
  Fields: categorization, ActionResource() (nil when "none"), resourceCost + resourceNumber.

## Synthesis (2026-10-08)

1. The EotW sheet is where strictness is actually missing: the mode enforces rules on the map
   but leaves the full editable sheet open on ~10 routes. A strict EotW sheet only works if it
   is the ONLY sheet an EotW hero can open (redirect at the framework chokepoint + gate the
   in-game keys/radial/search/macros + replace the town routes).
2. Removing editing removes the Merge's hardest open problems (edit cues, characteristics edit
   path, authoring affordances, custom-mod modals). What is left is presentation + a few
   rules-gated actions.
3. Inventory is FUNCTIONAL, not decorative: won treasure is inactive until equipped and nothing
   in town can equip it, so the sheet (or an auto-equip) must own equipping. The item context
   menu must not come with it.
4. The Merge's IA survives (identity left, vitals/stats zone, abilities + features columns,
   tags), re-skinned in EotW's grammar: slab serif incl. numbers, builder cream/tan accents, dark
   translucent plates, rounded, border-width state ladder, card-frame portrait, motion + sound.
5. EotW-native content the main sheet never had: Victories as an encounter record, treasure
   provenance (haul/chest), and the hero facts knacks read (movement types, items, perks).

## Open options raised (not decided)

- 2026-10-08 (James): STAT OVERLAYS ON THE SHEET PORTRAIT. The Merge kept stats in their own
  regions partly because they were click targets for editing and quick reference. In EotW
  nothing is editable, so overlaying stats on the portrait (card style) is a candidate. Weigh
  under D3/D4: legibility over arbitrary art, which stats earn a place on the art, and what
  that frees up elsewhere.

- 2026-10-08 (James): ACCENT HUE THEME-DEPENDENCE - open. Mocks use the builder's cream/tan
  for now. Context: EotW currently mixes antique gold #d9b56a (town), bright gold #ffd66b
  (stage/card) and cream/tan (builder), and gold-vs-cream flipped twice in commits this week.

- 2026-10-08 (verify before D2 locks): CLASS PLAY CONTROLS IN EotW. The character panel is
  read-only in EotW, and in the main game some class operations live only there (Beastheart
  companion call/rampage, Summoner sacrifice/squads, Elementalist persistent abilities). Routines
  are fine (picked by casting an ability, AbilityRoutineCast.lua). If the others are panel-only,
  EotW players may be blocked from them today. The sheet is a reference surface, so the fix
  belongs on the action bar or hero card, not the sheet.

## Decision map (Phase 3 - revised after evidence 2026-10-08; walk one category at a time)

- D1 FRAME & SCOPE (round 1): relationship to David's EotwHeroSheet spec and who builds;
  EotW-only vs pilot for the main sheet; strictness posture (zero controls / rules-gated item
  actions / cosmetic appearance edits); which entry points it owns (town, in-game, teammates,
  the ~10 routes to the full sheet).
- D2 Surface & form: full-screen vs overlay vs panel, in town and in game (over the map);
  relationship to the read-only character panel the HUD card opens today; escape priorities.
- D3 Layout & IA, level 1 to 10: which Merge regions survive; portrait placement and size
  (card-frame aspect 0.70 / 3:4 / 2:3); stat overlays on the art (open option); density.
- D4 Skin: EotW grammar applied (slab serif, builder cream/tan, translucent plates, border-
  width state ladder, location-scene header pattern?), motion and sound.
- D5 Abilities: statblock cards vs rows; the 14 common abilities; free strikes; trigger lines;
  implementation status badges.
- D6 Features & tags: pillar chips (never built in Lua), auto-selection from the live EotW beat,
  Core Feature pin, complication benefit/drawback, the Grant Treasure claim control, untagged
  newer classes, the near-unused Montage tag.
- D7 Inventory & equipment: equip action vs auto-equip; slot model (worn doll by body keyword /
  wielded-from-kit / leveled "N of 3" / plain list); consumables; provenance; NO context menu.
- D8 EotW-native content: Victories as an encounter record, treasure provenance, knack-relevant
  hero facts (movement types etc.), anthem, death, LEVEL-UP (where levelling happens: builder
  vs a sheet-launched flow; David wants progression central).
- D9 States: draft, away in a party, dead, other player's hero, live in-encounter values,
  video portraits, missing/small art.
- D10 Hardening & regression: closing the routes and cheat paths; parity with David's spec list
  and with what the read-only character panel shows today.
- D11 Phasing & coordination: David (EotW owner), Lisa (builder language), art lead polish,
  possible back-port to the main sheet.

## Decision ledger

| Date | Decision | Rationale |
|---|---|---|
| 2026-10-08 | Level range = 1 to 10. EotW progression is planned to reach level 10; design must scale from the level-1 launch state to the level-10 stress case. | James. |
| 2026-10-08 | Purpose split: the EotW hero CARD is a mini quick-reference for encounters and montages; the SHEET is the full reference of everything the hero can do. Different jobs - do not collapse one into the other. | James. |
| 2026-10-08 | "New portrait style" = the portrait art inside the hero-card frame (tall, full-bleed, cover-cropped, rounded) WITHOUT the stat overlays. On the sheet it gets its own dedicated place in that style (replaces the Merge's round class-coloured medallion). | James. |
| 2026-10-08 | FONTS = align with EotW for now: Berlingske Slab throughout (themed @label / engine default), weight via bold, italic = flavour; numbers in the same slab face, bold, signed; MCDM Display only for large headers. Supersedes the Merge's Inter-numerals decision FOR THE EotW SHEET (main-game decision untouched). | James. |
| 2026-10-08 | ACCENTS in mocks = align with the EotW BUILDER palette (cream-on-near-black: CREAM #DFCFC0, CREAM_LIGHT #F3EDE7, TAN #BC9B7B on #0b0c0b / #121311 / #1a1b18, border #3a3833). Whether accents become theme-dependent is an OPEN QUESTION. | James; gold-vs-cream is unsettled in code this week. |
| 2026-10-08 | D1-Q1 OWNERSHIP: James owns the EotW character sheet; David is a stakeholder who has given direction (direction to be captured). The sheet must get real benefit from the feature tagging work. | James. |
| 2026-10-08 | D1-Q2: EotW ONLY for now. If it lands well and comes to the main game, it will need tweaks to become an editing surface. | James. |
| 2026-10-08 | D1-Q3 STRICTNESS = option (c): stats and build read-only; rules-gated equipping of treasure (kit match for weapon/armor treasure, carry-three leveled); rules-neutral appearance changes (portrait framing, frame, anthem) still allowed after creation. No quantity/edit/duplicate/give. | James. |
| 2026-10-08 | D1-Q4: the EotW sheet owns EVERY route for EotW heroes (town Guild row + strip card, in game, teammates' heroes read-only), and closing the other routes to the full sheet is part of this project (needs David's agreement since it touches core keys/commands). | James agreed. |
| 2026-10-08 | TREASURE UX (James): if treasure is not auto-equipped, it must be OBVIOUS the hero has things to equip, with a clear call to action. The item right-click menu is stripped down for EotW; a custom EotW inventory look is on the table depending where the design lands. | James. |
| 2026-10-08 | D2-Q8: appearance changes after creation open the builder's Appearance page from a "Change Appearance" action on the sheet (the sheet itself stays read-only by construction). | James. |
| 2026-10-08 | D2 defaults ACCEPTED in principle, James wants them understood better (mock demonstrates them): in game, prompts/turn notice/victory screen layer ABOVE the sheet; the sheet never auto-closes; Escape closes. Town: Guild row + strip card open the sheet; pencil = Edit in Builder until the hero's first win; a teammate's party card opens their sheet read-only. | James. |
| 2026-10-08 | D2-Q5 (form) and D2-Q7 (several heroes) go to a MOCK before deciding: A full-screen page vs B scene (built as two variants: B1 hero art as the left column, B2 "where you are" location/battle backdrop) and party switcher vs one hero at a time. Round 2 mock = artifact https://claude.ai/artifact/BjjVgkj3vYRcGynndsQgRG (source docs/eotw-hero-sheet/mock/). | James asked to compare. |
| 2026-10-08 | DAVID'S DIRECTION recorded (see NEXT SESSION STARTS HERE): same hero over time; 1-2 VP/week, echelon 1 in ~6 months; enforce everything - no number manipulation, stats viewed "like a video game"; players CAN move and equip items. Near-term design range = levels 1-4, headroom to 10. | David via James. |
| 2026-10-08 | D2-Q6 RESOLVED for now: the character panel stays the in-encounter companion. Panel class-control blocks (Summoner, Elementalist) are existing bugs, out of scope here. | James. |
| 2026-10-08 | D2 "Your turn" banner default WITHDRAWN: turns are claimed, so the player closes the sheet to claim. Prompts-above-sheet stands as a z-order rule for EXISTING prompts (mounts unverified). | James. |
| 2026-10-08 | D2-Q5 LEANING B (scene); B1 hero-art vs B2 where-you-are still being explored. D2-Q7: switching within your own roster liked; whole-party switching = open discussion. | James. |
| 2026-10-08 | D2-Q6 (what the hero card opens) REOPENED by James: the character panel is still used as an in-combat reference, and he believed the class controls still work there. Code check: Beastheart Call/Select work (no read-only gate, DSBeastheart.lua:134); Summoner Sacrifice Minions + Edit Squads are hidden (editOnly) and bail on IsReadOnly (MCDMCharacterPanel.lua:7778, 7874) and the sacrifice is a Hidden standard ability with no other route; Elementalist cannot end a persistent ability (10434). Root cause: EotW returns "view" for EVERY player-controlled token, own heroes included, so play operations are blocked with edits. | Code verified 2026-10-08. |
| 2026-10-08 | PLAY vs EDIT = option A, ALLOWED BY CONSTRUCTION: no access-level system. The EotW sheet builds only rules-legal controls (equip/unequip treasure with kit-match gate, rearrange inventory, Change Appearance, Edit in Builder pre-first-victory, Grant Treasure claim); nothing that changes numbers (stamina/resources, Give/Split/Set Quantity/Duplicate/Make Unique/Drop/Destroy, custom mods, Victories/XP/level/titles/wealth/renown). Strictness rests on closing the other routes (D1-Q4). Option B (a shared "play" level in CharacterPanel.TokenAccessLevel) is recorded as the panel's path IF David fixes the Summoner/Elementalist blocks; the sheet would need no rework. | James picked A. |
| 2026-10-08 | CARRY-THREE (leveled treasure) = DISCUSSION POINT WITH DAVID: hard cap of three vs allow-and-warn vs automate the respite Presence test. Not decided by us. | James. |
| 2026-10-08 | LEVEL-UP flow named as a D8 item (where levelling happens: builder vs a sheet-launched level-up flow); not solved yet. | James agreed. |
| 2026-10-08 | TEAMMATES (Q1a): a player can open a teammate's full EotW sheet, read-only, in town AND in game. Under A this is the same sheet with the owner-only controls not built. Opening it is always deliberate (never auto-opens); Escape closes. | James. David's doc lists "another player's hero" as a LATER entry point without saying town or game (EncounterOfTheWeek.md:1700-1705, 830-834, 998-999); locked as stands. |
| 2026-10-08 | IN-GAME LAYERING = (i) + P3, SUPERSEDING the "prompts/turn notice/victory layer ABOVE the sheet" default. The sheet mounts where today's sheet does (above HUD furniture: initiative bar, roster, pools, windows, action bar, trigger cards, roll dialogs; below modals, victory/defeat, story screens, the "Waiting for..." banner, tooltips, dice). No core GameHud layer. Instead a "you're needed" SIGNAL: when a trigger, save or roll waits on one of the viewer's heroes (or a stage starts), the sheet's close control turns gold and says so [COPY]; close is one click (top-right X) or Escape; reopening restores scroll, expanded rows and filters. Must NOT open via ShowSheet or carry the journalViewer class (both hide the banner). | James. EotW never times prompts out (EmbeddedRollDialog.lua:6465-6476 paused trigger dice; MonsterAIPanel.lua:170-177 save wait), so the extra click loses nothing once the player knows. P1 (prompts above via a new layer) = upgrade path if playtests show players resent closing to answer. |
| 2026-10-08 | LAYERING RULES (accepted at face value; may be interrogated later): (1) a stage that starts while the sheet is open -> the signal fires (with this mount the stage would sit under the sheet); (2) a sheet opened during a stage opens above it; (3) Escape closes the sheet only after anything above it that wants Escape (roll dialogs 15, modals 16, popups 17; sheet at <= 14); (4) map-targeting prompts under an open sheet -> D9 states item. | James. |
| 2026-10-08 | LEARNED SURFACE: the sheet shows the SAME layout and the SAME representations in town, montage and encounter; only the values change. (Withdraws my "vitals as plain numbers in town, current values only in game" idea.) | James: context-dependent display breaks Hodent consistency/learnability. |
| 2026-10-08 | STAMINA keeps a visual full-vs-not representation (a bar, not just numbers), and stamina must look the same across surfaces (today the character panel, the hero card portrait and the mock sheet all differ). Representation choice pending (see round). | James. |
| 2026-10-08 | STAMINA = S1: the sheet reuses the hero card's stamina bar (EotwHeroCard.CreateStaminaBar, exported; the card calls it "the character panel's health bar in miniature"), winded threshold as a label. ALSO mock S2 (a better shared bar) for comparison: a bar study at full / full+temp / hurt+temp / winded / dying. Working rule for mocks: anything on the hero card looks the same on the sheet (stamina bar, recoveries ring, resource icon+value, surge pips, characteristic chips). | James (S1 + mock S2). TEMP FLAW found: the card sizes temp as min(1 - fill, temp/max) (EotwHeroCard.lua:597-601), so temp is INVISIBLE at full stamina (only "+N" text) and clipped near full - the common case. |
| 2026-10-08 | ROUND 3 WIREFRAMES published for reaction: https://claude.ai/artifact/UkGYCopdu4DAiuh2P7xUb2 (source docs/eotw-hero-sheet/mock/layouts.html, reuses mock/data.js + art/). Concept 1 STAT SPINE (identity col | one stats column: stamina, tests, combat, gear | abilities + features); 2 BIG CARD (the hero card enlarged as the left column, characteristics + skills + vitals on the art | abilities | features | details col); 3 RAIL AND PAGES (rail: portrait, stamina, tests, combat | one page at a time: Abilities, Features, Gear, Story). All vertical, skills beside characteristics. Plus the stamina bar study: S1 card bar as built vs S2a temp strip / S2b stretched bar / S2c temp overlay, at sheet and card size. Structural reason: a row of unequal blocks is as tall as its tallest, so short blocks sit half empty and narrow ones get squeezed; columns let each block take its own height. | Awaiting James. |
| 2026-10-08 | ROUND 3 VERDICTS. REJECTED Concept 3 Rail and pages: clicking across to different sections is a failure mode of the current sheets. REJECTED Concept 1 Stat spine: abilities column felt empty, the spine felt cramped, block contents had inconsistent spacing with empty right-hand sides. BIG CARD is the direction ("cool"), but movement and gear felt tacked onto the side, not considered. | James. |
| 2026-10-08 | CHARACTERISTICS on the sheet use FULL NAMES (Might, Agility, Reason, Intuition, Presence), not letters - which strains putting them on the card art. (The hero card itself may keep letters for space; the card-to-sheet rule bends for labels, not values.) SKILLS GROUPED by skill group = decided. JOB COLOURS dropped. Show PROGRESS TOWARD THE NEXT LEVEL. | James. |
| 2026-10-08 | STAMINA BAR must also show the DEAD threshold (a hero dies at the negative of their winded value; Heroes p.~674 of extract) - "a fairly important number". S2c (temp overlay) liked as the basis, but temp is drained FIRST, and S2c's "Hurt, 10 temp" did not read that way; next round must show drained-first. | James. |
| 2026-10-08 | QUALITY BAR for round 4 blocks: consistent internal spacing; blocks fill their width (no empty right-hand sides); label/value pairs on a shared grid. | From James's spine critique. |
| 2026-10-08 | ROUND 4 ARRANGEMENT = "TESTS ACROSS THE TOP": left = the big card (art, name, stamina) then level progress and gear; main = one tests block across the top (full-name characteristics + skills by group + languages), then Abilities (combat stats at its head) | Features. No side column. | James picked option 1 of 3 (others: tests under the card + Gear list; characteristics on the card art). |
| 2026-10-08 | STANDARD ACTIONS + FREE STRIKES are listed in Abilities as COMPACT groups after the hero's own abilities (names only, click to read). | James. A real L1 hero has 22-25 abilities (E5); round 3 showed only own abilities, hence the empty column. |
| 2026-10-08 | LEVEL PROGRESS = XP to next level (DS default: Victories convert to XP at a respite, 16 XP per level; Heroes Heroic Advancement table), shown as a bar with Victories beside it. EotW's own progression rules stay open with David. | James. |
| 2026-10-08 | ROUND 4 MOCK published as version 2 of the same artifact (https://claude.ai/artifact/UkGYCopdu4DAiuh2P7xUb2; source mock/layouts.html + std.js; round 3 source kept as mock/layouts-r3.html). Big card plate = name, subtitle, recoveries ring + stamina bar, "Winded at 16 / Dead at -16" line, Recovery value / resource / surges row; left = card, Level + XP bar (16 per level) + Victories, Gear (kit + bonuses grid, treasure, leveled N of 3, equip CTA); main = topbar, tests block (full-name characteristic tiles + "A test is 2d10 plus a characteristic, +2 when one of your skills applies" [COPY], five fixed skill-group columns, languages), Abilities (combat strip: size/speed/disengage/stability/potency + immunities/weaknesses; own abilities; Free strikes + 17 Standard actions as compact two-column groups, real data from the live app via tools/probe_std.py) | Features. Bar study: S1 vs T1 leading band (temp right after current stamina, slides back over the fill with an overflow arrow when it does not fit) / T2 T1 + fixed dying zone (0 line, red fills toward death, not to scale) / T3 temp past the bar (frame = max, cap runs out past it), 7 states incl. winded + temp, dying, near death. | Awaiting James. |
| 2026-10-08 | ROUND 4 VERDICTS (James): KEEP level + gear where they are (left column under the card). DROP the characteristics explainer line. Size/speed/disengage/stability/potency/immunities/weaknesses must NOT sit under the Abilities header ("makes no sense"); James floats stretching them horizontally like characteristics + skills - OPTIONS TO DISCUSS. Skills and languages take too much space for what they are. Potency label sat over Weak only and pushed values down - confusing which values are potency. Recoveries COUNT not shown (ring only) - must be explicit. Standard-action inline expand in the two-column grid "isn't great"; James wonders about hover preview cards instead of click-to-expand - ASKED what the EotW builder uses. Feature filter input goes beside the pillar chips; every feature SECTION header collapsible; long features need click to expand/collapse. Rows must show BOTH the action type (main action, maneuver...) and the cost (Signature, N Piety) - one label is not enough. Gear: "Kit" as the header (not "<name> kit"). | James. |
| 2026-10-08 | STAMINA BAR = S1 (as built) FOR NOW; the representation is UNDECIDED and goes to David (temp invisible at full, drained-first semantics, dead threshold). T1-T3 stay in the study for that conversation. | James. |
| 2026-10-08 | OPEN from round 4: (a) the Conduit's "Life Domain Effect" / "War Domain Effect" show as triggered actions - does Abilities honour the tagging (Hidden display kind)? (b) Tacticians can change their kit damage bonus - Gear must account for it. (c) Non-kit classes: show their ward (or equivalent) with its bonuses in the Kit slot? (d) Show multiple immunities/weaknesses and a veteran inventory (trinkets, consumables, leveled treasure). | James; research before proposing. |
| 2026-10-08 | ABILITY CARD = HOVER SHOWS, CLICK PINS: hovering any ability row (own, free strike, standard action) shows the same card the live sheet and action bar use (CreateAbilityTooltip); click pins it until you click elsewhere or press Escape. Replaces click-to-expand. | James (recommended option). Codex convention is hover (E14); pinning gives keyboard/touch a path and keeps the card while reading. |
| 2026-10-08 | KIT SLOT for kit-less classes = the EQUIVALENT under its rules name (Conduit: Prayer + Ward; Elementalist: Enchantment + Ward; Null: Augmentation; Talent: Augmentation + Ward; Summoner: Summoner's Kit + Wards) with the bonuses it grants; they also stay in Features. | James (recommended option). |
| 2026-10-08 | TACTICIAN: Gear shows BOTH kits; where both have a damage bonus, both values show with the active one marked; the player can switch it IN TOWN (a respite - rules-legal, so allowed under option A); in an encounter it shows but cannot switch. Note the EotW builder has no toggle today (E13). | James (recommended option). |
| 2026-10-08 | STATS BAND: James asked to SEE all three options in the mock before choosing - (1) numbers row + words row, (2) tests half + combat half, (3) statblock lines. | James. |
| 2026-10-08 | ROUND 5 MOCK published as version 3 (same URL; source mock/layouts.html + vet.js; round 4 kept as mock/layouts-r4.html). Stats band toggle (1 numbers row/words row, 2 tests half/combat half, 3 statblock lines); skills + languages inline, grouped; explainer dropped; card plate spells out "Recoveries 10/10 +11 each" (ring dropped on the sheet - a deviation from the card rule, flagged); ability rows show action + cost; hover card + click pin (Escape/click-away closes) on abilities AND items; Conduit domain effects in their own "Domain effects" group ("Used when your prayer roll is a 3" [COPY]) - MY DEFAULT, flagged; jump chips over Abilities; feature sections collapsible, filter beside the chips, long features Show more/less; Gear: "Kit" header with armor/weapon line from kit data; kit-equivalents by rules name (Conduit Prayer + Ward, Elementalist Enchantment + Ward, Talent Augmentation, Null "None chosen" - the pregen has no augmentation); Tactician both kits, lower duplicates struck, melee bonus chooser "Change at a respite" when both kits give melee (simulated with Panther); treasure split Worn and wielded / Carried / Consumables with Equip/Unequip, "No benefit" flag on armor the kit cannot use (Panther has no armor); simulate toggles: veteran inventory (real tbl-gear records), many immunities, some progress, two melee kits. | Awaiting James. |
| 2026-10-08 | ROUND 5 VERDICTS (James): STATS BAND leaning option 1 (numbers row + words row) but a skill group must never break across lines, and movement + potency should be LESS prominent than characteristics yet more than statblock lines. LEFT COLUMN MUST NOT SCROLL. Tactician kits: find a more elegant combined view than stacking. JUMP CHIPS rejected. Recoveries text OK but he misses the card's ring - make it more in line with the card. | James. |
| 2026-10-08 | ABILITIES FOLLOW THE TAGGING PLAN (docs/feature-metadata-incremental/hero-tagging-plan.md, James's 2026-08-15 rulings): a feature tagged Ability/Trigger IS an ability card (row hidden in Features, card shown in Abilities); prose features the codex implements as abilities stay VISIBLE FEATURES (domain effects = visible Combat). So the Abilities list = abilities from Ability/Trigger-tagged features + kit signature abilities + core-feature actions (Mark, Judgment) + free strikes + standard actions; it drops abilities whose source is a visible or Hidden feature. BUILD NOTE: no codex ability list reads tags today (E14) - the sheet needs an ability-to-source-feature lookup. Triggered actions come from GetTriggeredActions() (the round 2-5 export missed them). OPEN for James: the same rule would also move Light (Dwarf Runic Carving) and the respite rituals out of Abilities into Features - confirm. | James's recollection, confirmed against the plan. |
| 2026-10-08 | ROUND 6 MOCK published as version 4 (same URL; round 5 kept as mock/layouts-r5.html): level + XP + Victories moved onto the card plate (no separate level block); card 400x520; gear compact with "+N more" caps (worn 5, carried 3, consumables 6) and NEVER scrolls (veteran inventory fits); stats band = option 1 only, characteristics as big tiles, movement + potency as LABELLED LINES (default) or SMALL TILES (toggle); skill groups nowrap; recoveries = the card's ring + "Recoveries / of 10 - +11 each"; Tactician = ONE combined kit (two kit names with filled/hollow markers, each bonus shows the better value + its marker, the other kit's value on hover, inline melee chooser "pick one in town (a respite)" when both kits give melee); abilities per the tagging plan (Conduit domain effects -> Features as Combat, Word of Guidance + Elementalist's Explosive Assistance added as Triggered actions; Censor's two custom test abilities left off); global abilities always grouped as free strikes / standard actions; jump chips removed; feature chips + filter on the header row. | Awaiting James. |
| 2026-10-08 | ROUND 6 VERDICTS (James): movement + potency treatment (labelled lines vs small tiles) NOT YET DECIDED - keep both. APPLY the tagging rule to Light (Dwarf Runic Carving) and the respite rituals too. Tactician filled-dot markers rejected (and they made the bonuses wrap differently). The gear card's header is not "Gear": split it into KIT (or Ward / Prayer / Enchantment / Augmentation - whatever the class uses) and TREASURES, with Leveled treasures / Trinkets / Consumables as sub-headers. REVERT the card plate's heroic resource and surges to the current hero-card frame, keeping the other plate changes. The capped gear card rendered some content off screen - must never clip. | James. |
| 2026-10-08 | ROUND 7 MOCK published as version 5 (same URL; round 6 kept as mock/layouts-r6.html): card plate resource = the card's icon + value (name on hover), surges = one icon per surge, none at 0 (EotwHeroCard CreateResourceRow / CreateSurgeCorner), recoveries ring + label kept; the gear card = KIT section (single kit; Tactician as ONE kit "Shining Armor + Rapid-Fire" laid out exactly like a single kit, source on hover, inline melee chooser when both kits give melee; kit-less classes show their equivalent's rules name as the header, two-up when there are two: Prayer | Ward, Enchantment | Ward) + a split + TREASURES (Leveled treasures "N of 3 carried", Trinkets, Consumables chips; equip CTA on the Treasures header); lists cap behind "+N more" and the caps shrink automatically until the card fits (never clips); Light, Revitalizing Ritual and the Ritualist perk's blessing ritual moved from Abilities to Features (Ancestry/Exploration, Class/Respite, Perks/Exploration+Montage). | Awaiting James. |
| 2026-10-08 | ROUND 7 VERDICTS (James): "+N more" hides items you cannot act on - TREASURES SCROLL inside their own card like Abilities and Features. KIT and TREASURES become SEPARATE stacked cards. LEVEL ROW smaller: progress bar not full width, current level and next level at the bar's ends, Victories on the same line, the "X of X XP" text moves to a hover tooltip on the bar. "Movement" is the wrong header (size and stability are not movement): each stat gets its own label next to its number. ONE HEADER SYSTEM: section headers (white, larger - Skills must outrank the skill-group labels) vs stat headers (gold), used the same way everywhere. Movement + potency = LABELLED LINES (decided). | James. Surge check: the current hero card draws ONE SURGE ICON PER AVAILABLE SURGE, no number, nothing at 0, capped at 9 icons (EotwHeroCard.lua:860-893 CreateSurgeCorner). |
| 2026-10-08 | ROUND 8 MOCK published as version 6 (same URL; round 7 kept as mock/layouts-r7.html): Kit card + Treasures card (scrolling body, no caps); level row "1 [bar] 2  Victories 0" with XP on hover; header system (section = 16px white caps: Characteristics, Skills, Languages, Immunities, Weaknesses, Abilities, Features, Kit/Prayer/Ward..., Treasures; stat = gold small caps: characteristic names, skill groups, size/speed/disengage/stability, Potency, list groups, treasure types, kit bonus names); size/speed/disengage/stability self-labelled, Potency + weak/average/strong; the movement/potency toggle removed. Brief handoff section rewritten for the next session. | Awaiting James. |
| 2026-10-08 | ROUND 8 VERDICTS (James): "looks better". The size/speed/potency block looked too empty on its right - spread or centre it to fit. The scene behind the sheet had gone; bring it back to compare: the layout is starting to work, but it reads as a splash of colour around the portrait and then a lot of bland black and grey boxes - the translucent scene may fix that, otherwise rethink. Brief and mock committed to design/eotw-hero-sheet (a563ebe5). | James. |
| 2026-10-08 | ROUND 9 MOCK published as version 7 (same URL; round 8 kept as mock/layouts-r8.html): BACKDROP toggle - Where you are (default: the Hero's Guild for your heroes in town, the blurred battle map for a teammate's hero in an encounter, i.e. round 2's B2), Hero art (a blurred, saturated wash of the hero's own illustration), None (round 8); over a backdrop every panel is a translucent dark plate (66%) with a blur, and Abilities + Features share one plate (62%). The body stats + potency became one aligned 4-column grid filling their block (row 1 Size, Speed, Disengage, Stability; row 2 Potency, Weak, Average, Strong). Build note: the codex tooltip styling already has a blurBackground option. | Awaiting James. |
| 2026-10-08 | BACKDROP = "WHERE YOU ARE" (decided): the Hero's Guild in town, the blurred battle map in an encounter, with FROSTED TRANSLUCENT PANELS over it (liked). Settles round 2's form question in favour of B2; the hero-art column (B1) lives on as the card. Round 9 verdict also: Potency's header sat too far from its values in the 4-column grid - try centring or another option that keeps the group together; the battle-map case needed an explicit way to compare. | James. |
| 2026-10-08 | ROUND 10 MOCK published as version 8 (same URL; round 9 kept as mock/layouts-r9.html): backdrop toggle removed (always where you are); new WHERE toggle (Town / In an encounter) drives the backdrop and the switcher (town = your roster; encounter = the heroes in this encounter, yours first and marked); SIZE-TO-POTENCY toggle: Two groups (default: 2x2 size/speed/disengage/stability, hairline, Potency captioned over weak/average/strong), Centred lines (body stats line + potency in an outlined pill), Round 9 grid. | Awaiting James. |
| 2026-10-08 | PRECEDENT IS CONTEXT, NOT AUTHORITY: nobody has done a Draw Steel character sheet well; solving that is the aim. Layout reasoning rests on the DS rules (a test = characteristic + skill) and EotW's own surfaces, not on other sheets. | James. |
| 2026-10-08 | SWITCHER (Q2c) = BY CONTEXT: in town it cycles your roster; in game it cycles the heroes in this encounter, yours first, others marked by the card's border ladder (own = 2px blue), never colour alone. Ours, not in David's doc. | James. Mirrors the surrounding roster (Guild vs HUD), so ownership stays legible. |

## Discussion points for David

- Carry-three leveled treasure in a directorless mode: hard cap / allow + warn / automated respite test.
- Panel class-control blocks (Summoner Sacrifice/Edit Squads, Elementalist end persistent) are bugs under EotW's blanket "view" access; a "play" access level is one fix path.
- Closing the core routes to the full sheet (c/i keys, radial, search, macros) touches core code - needs his OK (D1-Q4).
- Edit in Builder window: his doc says "only before its first encounter" (EncounterOfTheWeek.md:1707-1709); the code (CanRebuildHero) allows it until the first recorded VICTORY, so a hero who lost or died stays rebuildable. Which does he intend?
- Teammates' sheets: we locked read-only in town AND in game (his doc lists "another player's hero" as a later entry point without saying where). Confirm.
- Hero card stamina bar hides temp stamina at full stamina and clips it near full (EotwHeroCard.lua:597-601: temp width = min(1 - fill, temp/max)); only the "+N" text shows it. The sheet reuses this bar (S1), so a fix would land on both.
- Side finding (E11): the AI "Waiting for..." banner hides whenever ANY panel window is open (journalViewer class, GameHud.lua:2887-2908), including the hero-card character panel and Chat. Intended?
- FYI (E11): today's full sheet (ShowSheet, mainDialogPanel) covers trigger prompts and roll dialogs and hides the "Waiting for..." banner - relevant while the c/i keys still open it in EotW. Our sheet avoids a core layer change (P3) but will want his eyes on the signal.

## Out of scope / rejected

- Main-game sheet changes (this is an EotW-only surface; back-port is a later question).
