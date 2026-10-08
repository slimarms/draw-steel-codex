# EotW Hero Sheet - Working Brief

> Status: WORKING - D1 (frame/scope) DECIDED; D2 (screen & form) partly decided, mock round 2
> published; handed off to a fresh session 2026-10-08 (see NEXT SESSION STARTS HERE).

## NEXT SESSION STARTS HERE (handoff 2026-10-08)

Read this brief top to bottom first (ledger + evidence). Mock round 2:
https://claude.ai/artifact/BjjVgkj3vYRcGynndsQgRG (source docs/eotw-hero-sheet/mock/; republish
from that file path or pass the URL). Data regeneration: docs/eotw-hero-sheet/tools/ (Lua probes
saved as .lua.txt, run over the bridge at localhost:19876/execute; build_data.py rebuilds
mock/data.js; portraits were captured by rendering each portrait in-app and screenshotting).

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

James's latest round (2026-10-08, not yet discussed through):
1. Q6: KEEP the character panel as the in-encounter companion for now. The Summoner
   (Sacrifice Minions / Edit Squads) and Elementalist (end persistent ability) blocks are
   existing bugs that should work - DO NOT TOUCH them in this project (flag to David only).
2. PLAY vs EDIT: James is unsure about the access-level idea - DISCUSS FIRST next session.
   Framing prepared: David's rule gives the line (rules-legal player actions allowed - move
   and equip items, appearance, builder before first win; number manipulation blocked). The
   new sheet is new code, so it simply builds only the allowed actions (no access-level system
   needed there). The panel stays untouched; a "play" level would only matter if the panel bugs
   are fixed later.
3. C key: confirmed in code that it opens the full EDITABLE sheet for the selected token
   (InputController.cs:1360 Bind("c","sheet") -> CoreAssets/Lua/commands.txt:249 Commands.sheet
   -> dmhub.currentToken:ShowSheet(), no access check). Not tried live in an EotW game.
4. PROMPTS: the mock's prompt was a STAND-IN for the existing in-game prompts (trigger prompts,
   save prompts, roll dialogs, the AI "Waiting for" banner, the victory screen) - not a new
   design. The proposal is z-order only: existing prompts draw above the EotW sheet. Where each
   prompt mounts is NOT yet verified - check before designing around it. The "Your turn"
   banner is WITHDRAWN: heroes claim turns in Draw Steel, so a player closes the sheet to claim.
   Open: should the initiative/claim bar stay visible above an open sheet?
5. TEAMMATES' SHEETS: James on the fence. David's spec intends it (doc 1700-1705: "another
   player's hero"), and his HUD already opens teammates' character panels read-only. Discuss
   pros/cons.
6. MOCK: James LEANS B; keep exploring B1 (hero art column) vs B2 (where you are). Switching
   between YOUR roster is liked; switching across the WHOLE PARTY is a pros/cons discussion.
7. LAYOUT needs work (round 3): clipping, poor use of space, cramped areas next to empty ones.

Suggested order next session: play/edit discussion -> teammates + party switcher pros/cons ->
verify prompt mounts -> round 3 layout (levels 1-4 primary, 10 as stress) -> mock v3 exploring
B1 vs B2 with the layout fixed.
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
  hero facts (movement types etc.), anthem, death.
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

## Out of scope / rejected

- Main-game sheet changes (this is an EotW-only surface; back-port is a later question).
