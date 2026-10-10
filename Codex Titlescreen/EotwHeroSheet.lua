local mod = dmhub.GetModLoading()

--The Encounter of the Week hero sheet: a full-screen, read-only reference
--for one EotW Hero, drawn over where the player is (the Hero's Guild in
--town, the blurred battle map in a game). It lives in this core mod, like
--EotwHeroCard.lua, because it opens at the titlescreen as well as in game.
--Design brief and build plan: docs/eotw-hero-sheet/brief.md; the mock in
--docs/eotw-hero-sheet/mock/layouts.html is the reference for every state.
--
--It must NOT open through ShowSheet and must never carry the journalViewer
--class: both hide the AI's "Waiting for..." banner, which EotW players rely on.

---@class EotwHeroSheet
---@field debugNeededLine string|nil test switch: shows this line on the gold you're-needed bar in a game
EotwHeroSheet = {}

--The fixed dark skin (EotW does not follow colour schemes yet): the
--builder's cream/tan on near-black frosted plates.
local C = {
    CREAM = "#DFCFC0ff",
    CREAM_LIGHT = "#F3EDE7ff",
    TAN = "#BC9B7Bff",
    MUTED = "#A6A096ff",
    BORDER = "#3a3833ff",
    INK = "#10110Fff",
    CARD = "#1a1b18ff",
    CARD_HOVER = "#262722ff",
    --a plate over a scene: lighter over the Guild, near-opaque over a map
    --so the map's detail does not fight the text.
    BLOCK_TOWN = "#11100ea8",
    BLOCK_GAME = "#0e0d0bdb",
    BLOCK_OPAQUE = "#14130fff",
    BLOCK_EDGE = "#ffffff1a",
    TOPBAR = "#0a0a09b8",
    HAIRLINE = "#ffffff14",
    SKEL = "#ffffff0f",
    SKEL_LIT = "#ffffff24",
    --the one gold: act on this / it landed (ready to Level, surges)
    GOLD = "#ffd66bff",
    --text on the card's dark plate, a cool grey that reads over any art
    PLATE_TEXT = "#c6d0daff",
    PLATE = "#000000c4",
    WARN = "#e9b86fff",
    --the hatched stretch of the XP bar: cream stripes on a faint cream ground
    HATCH = "#dfcfc0e6",
    HATCH_GROUND = "#dfcfc040",
}

--The card's sections a live refresh re-reads (any character change): cheap,
--with no feature index. Titles and the rest are read once when the Hero loads.
local LIVE_SECTIONS = { "identity", "progress", "vitals", "resource" }

--Layout at the 1920x1080 design size (see the mock): a 400px left column
--that never scrolls, and the main column taking the rest.
local PAD = 24
local COLUMN_GAP = 20
local LEFT_WIDTH = 400
local LEFT_GAP = 14
local CARD_HEIGHT = 520
local MAIN_GAP = 16
local TOPBAR_HEIGHT = 60

--The plate's inner width: the plate is 10px in from the card on each side and
--pads 14px inside. The XP bar's hatch and notch are placed in pixels from it.
local PLATE_INNER = LEFT_WIDTH - 20 - 28
--The level numbers either side of the XP bar, and the gaps around the bar.
local LEVEL_NUMBER_WIDTH = 22
local XP_BAR_WIDTH = PLATE_INNER - 2 * LEVEL_NUMBER_WIDTH - 16
local XP_BAR_HEIGHT = 10
--One hatch stripe every HATCH_STEP pixels, for the XP the next respite adds.
local HATCH_STEP = 4
--Surges show one icon each, nine at most (they would outgrow the corner).
local MAX_SURGE_ICONS = 9
--Titles listed under the name, at most (locked design).
local MAX_TITLES = 5

--How long a Hero may take to arrive before the sheet gives up and offers
--Try again. Lobby characters in town can take a few seconds to sync.
local LOAD_TIMEOUT = 15
--One half-cycle of the skeleton's shimmer.
local SHIMMER_SECONDS = 0.7
--How long a stat equipping just changed stays gold before it settles.
local PREVIEW_HOLD_SECONDS = 1.5
--A feature description longer than this starts folded behind Show more (F6).
local FEATURE_FOLD_CHARS = 300
--About 75 characters a line at the description's font size (locked design).
local FEATURE_TEXT_MAX_WIDTH = 600

--Frost blur radii in pixels (engine panel `frost`): the plates over the Guild,
--and the in-game backdrop, which blurs the map and HUD harder so nothing reads.
local FROST_RADIUS = 12
local FROST_RADIUS_BACKDROP = 18

--Whether this engine has the panel `frost` option (nil until first checked).
---@type boolean|nil
local m_frostSupported = nil

--The panel's `frost` field, untyped: Definitions/Panel.lua gains it when the
--stubs are regenerated from an engine build that has it.
---@param panel Panel
---@return any
local function FrostField(panel)
    return panel --[[@as any]]
end

--Reading `frost` gives a number on engines that have it and nil on older ones
--(setting it there only logs an error), so check once on a throwaway panel.
---@return boolean
local function FrostSupported()
    if m_frostSupported == nil then
        local probe = gui.Panel{ width = 1, height = 1 }
        local value = nil
        pcall(function() value = FrostField(probe).frost end)
        probe:DestroySelf()
        m_frostSupported = type(value) == "number"
    end
    return m_frostSupported == true
end

local CHARACTERISTICS = { "Might", "Agility", "Reason", "Intuition", "Presence" }
local PILLARS = { "Combat", "Exploration", "Montage", "Negotiation", "Respite" }

local RULES = {
    {
        selectors = { "eotwsText" },
        fontFace = "Berling",
        color = C.CREAM,
        fontSize = 14,
        width = "auto",
        height = "auto",
    },
    {
        selectors = { "eotwsText", "muted" },
        color = C.MUTED,
    },
    --section headers: Kit, Treasures, Characteristics, Abilities...
    {
        selectors = { "eotwsHeader" },
        color = C.CREAM_LIGHT,
        fontSize = 16,
        bold = true,
        uppercase = true,
    },
    --small gold-tan labels: characteristic names, treasure sub-headers.
    {
        selectors = { "eotwsLabel" },
        color = C.TAN,
        fontSize = 11.5,
        bold = true,
        uppercase = true,
    },
    {
        selectors = { "eotwsName" },
        color = "white",
        fontSize = 28,
        bold = true,
        width = "100%",
    },
    {
        selectors = { "eotwsBlock" },
        bgimage = "panels/square.png",
        bgcolor = C.BLOCK_TOWN,
        borderWidth = 1,
        borderColor = C.BLOCK_EDGE,
        cornerRadius = 10,
    },
    {
        selectors = { "eotwsBlock", "ingame" },
        bgcolor = C.BLOCK_GAME,
    },
    --the Transparent UI setting is off: solid plates, nothing shows through
    {
        selectors = { "eotwsBlock", "opaque" },
        bgcolor = C.BLOCK_OPAQUE,
    },
    {
        selectors = { "eotwsSkel" },
        bgimage = "panels/square.png",
        bgcolor = C.SKEL,
        cornerRadius = 5,
        transitionTime = SHIMMER_SECONDS,
    },
    {
        selectors = { "eotwsSkel", "lit" },
        bgcolor = C.SKEL_LIT,
    },
    --an outlined row the real content will fill: ability rows, items.
    {
        selectors = { "eotwsRow" },
        bgimage = "panels/square.png",
        bgcolor = "#1c1b18c2",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 8,
    },
    {
        selectors = { "eotwsChip" },
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 14,
    },
    {
        selectors = { "eotwsButton" },
        bgimage = "panels/square.png",
        bgcolor = C.CARD,
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 6,
    },
    {
        selectors = { "eotwsButton", "hover" },
        bgcolor = C.CARD_HOVER,
        borderColor = C.TAN,
    },
    {
        selectors = { "eotwsButton", "press" },
        brightness = 0.85,
    },

    --the card: art full-bleed (or the dark ground when there is none), greyed
    --for a Hero who is dead or fallen
    {
        selectors = { "eotwsCard" },
        bgimage = "panels/square.png",
        bgcolor = "#151515ff",
        borderWidth = 1,
        borderColor = "#000000cc",
        cornerRadius = 10,
    },
    {
        selectors = { "eotwsCard", "dead" },
        saturation = 0,
        brightness = 0.7,
    },
    {
        selectors = { "eotwsPlate" },
        bgimage = "panels/square.png",
        bgcolor = C.PLATE,
        cornerRadius = 8,
    },
    {
        selectors = { "eotwsPlateText" },
        color = C.PLATE_TEXT,
        fontSize = 12.5,
    },
    {
        selectors = { "eotwsPlateStrong" },
        color = "white",
        fontSize = 14,
        bold = true,
    },
    {
        selectors = { "eotwsSubtitle" },
        color = C.PLATE_TEXT,
        fontSize = 14,
        tmargin = 2,
        width = "100%",
    },
    {
        selectors = { "eotwsTitle" },
        color = C.CREAM,
        fontSize = 14,
        italics = true,
    },
    {
        selectors = { "eotwsTitle", "hover" },
        color = C.CREAM_LIGHT,
    },
    {
        selectors = { "eotwsMedal" },
        width = 15,
        height = 15,
        valign = "center",
        bgimage = "phosphor/medal-fill.png",
        bgcolor = C.TAN,
    },
    {
        selectors = { "eotwsLevelNumber" },
        color = "white",
        fontSize = 14,
        bold = true,
        width = LEVEL_NUMBER_WIDTH,
        textAlignment = "center",
        valign = "center",
    },
    {
        selectors = { "eotwsLevelNumber", "next" },
        color = C.PLATE_TEXT,
    },
    {
        selectors = { "eotwsLevelNumber", "next", "reach" },
        color = C.CREAM_LIGHT,
    },
    {
        selectors = { "eotwsLevelNumber", "next", "ready" },
        color = C.GOLD,
    },
    {
        selectors = { "eotwsXpBar" },
        bgimage = "panels/square.png",
        bgcolor = "#ffffff1f",
        cornerRadius = 5,
    },
    {
        selectors = { "eotwsXpFill" },
        bgimage = "panels/square.png",
        bgcolor = "white",
        cornerRadius = 5,
        gradient = gui.Gradient{
            point_a = { x = 0, y = 0 },
            point_b = { x = 1, y = 0 },
            stops = {
                { position = 0, color = C.TAN },
                { position = 1, color = C.CREAM },
            },
        },
    },
    {
        selectors = { "eotwsXpFill", "ready" },
        gradient = gui.Gradient{
            point_a = { x = 0, y = 0 },
            point_b = { x = 1, y = 0 },
            stops = {
                { position = 0, color = C.GOLD },
                { position = 1, color = C.GOLD },
            },
        },
    },
    {
        selectors = { "eotwsReadyLine" },
        color = C.GOLD,
        fontSize = 14,
        bold = true,
        width = "100%",
    },
    {
        selectors = { "eotwsRespiteLine" },
        color = C.CREAM_LIGHT,
        fontSize = 13.5,
        bold = true,
        width = "100%",
    },
    {
        selectors = { "eotwsEpic" },
        fontSize = 13,
        valign = "center",
    },
    {
        selectors = { "eotwsEpicIcon" },
        width = 14,
        height = 14,
        valign = "center",
        bgcolor = C.CREAM_LIGHT,
    },
    {
        selectors = { "eotwsNote" },
        fontSize = 13,
    },
    {
        selectors = { "eotwsStatusIcon" },
        width = 14,
        height = 14,
        bgcolor = "white",
    },
    --the Recoveries ring: Recoveries left in a dark disc
    {
        selectors = { "eotwsRing" },
        width = 42,
        height = 42,
        valign = "center",
        bgimage = "panels/square.png",
        bgcolor = "#000000a0",
        cornerRadius = 21,
        borderWidth = 2,
        borderColor = "#dfcfc099",
    },
    {
        selectors = { "eotwsRing", "empty" },
        borderColor = "#c94040cc",
    },
    {
        selectors = { "eotwsRingNumber" },
        color = C.CREAM_LIGHT,
        fontSize = 18,
        bold = true,
        halign = "center",
        valign = "center",
    },
    {
        selectors = { "eotwsVitalNumber" },
        color = "white",
        fontSize = 20,
        bold = true,
        valign = "center",
    },
    {
        selectors = { "eotwsResourceIcon" },
        width = 17,
        height = 17,
        valign = "center",
        bgcolor = "white",
    },
    {
        selectors = { "eotwsEpitaph" },
        color = C.PLATE_TEXT,
        fontSize = 14,
        width = "100%",
    },
    {
        selectors = { "eotwsSurges" },
        width = "auto",
        height = "auto",
        flow = "horizontal",
        hpad = 7,
        vpad = 5,
        borderBox = true,
        bgimage = "panels/square.png",
        bgcolor = C.PLATE,
        cornerRadius = 8,
    },
    {
        selectors = { "eotwsSurgeIcon" },
        width = 15,
        height = 15,
        lmargin = 1,
        rmargin = 1,
        bgimage = "game-icons/surge.png",
        bgcolor = C.GOLD,
    },
    --abilities and features
    {
        selectors = { "eotwsListHead" },
        width = "100%",
        height = 44,
        flow = "horizontal",
        borderColor = "#bc9b7b66",
        border = { x1 = 0, x2 = 0, y1 = 1, y2 = 0 },
    },
    {
        selectors = { "eotwsListCount" },
        color = C.MUTED,
        fontSize = 13,
    },
    {
        selectors = { "eotwsChip", "on" },
        bgcolor = C.CREAM,
        borderColor = C.CREAM,
    },
    {
        selectors = { "eotwsChip", "hover" },
        borderColor = C.TAN,
    },
    {
        selectors = { "eotwsChipText" },
        color = C.CREAM,
        fontSize = 12.5,
    },
    {
        selectors = { "eotwsChipText", "parent:on" },
        color = C.INK,
        bold = true,
    },
    {
        selectors = { "eotwsFilter" },
        width = "100% available",
        height = 28,
        lmargin = 10,
        hpad = 10,
        borderBox = true,
        valign = "center",
        fontSize = 13,
        color = C.CREAM,
        bgimage = "panels/square.png",
        bgcolor = "#00000040",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 6,
    },
    {
        selectors = { "eotwsGroupHead" },
        width = "100%",
        height = "auto",
        vpad = 3,
        borderBox = true,
        flow = "horizontal",
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
    },
    {
        selectors = { "eotwsCaret" },
        width = 10,
        height = 10,
        rmargin = 6,
        valign = "center",
        bgimage = "phosphor/caret-down-fill.png",
        bgcolor = C.MUTED,
    },
    {
        selectors = { "eotwsCaret", "closed" },
        rotate = -90,
    },
    {
        selectors = { "eotwsGroupLabel" },
        color = C.TAN,
        fontSize = 12,
        bold = true,
        uppercase = true,
    },
    {
        selectors = { "eotwsGroupCount" },
        color = C.MUTED,
        fontSize = 13,
    },
    {
        selectors = { "eotwsGroupNote" },
        color = C.MUTED,
        fontSize = 12,
        italics = true,
    },
    {
        selectors = { "eotwsAbilityRow" },
        width = "100%",
        height = "auto",
        tmargin = 6,
        hpad = 12,
        vpad = 8,
        borderBox = true,
        flow = "horizontal",
        bgimage = "panels/square.png",
        bgcolor = "#1a1b18d9",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 8,
    },
    {
        selectors = { "eotwsAbilityRow", "compact" },
        width = "50%-3",
        tmargin = 0,
        hpad = 10,
        vpad = 6,
        rmargin = 6,
    },
    {
        selectors = { "eotwsAbilityRow", "hover" },
        bgcolor = "#262722e6",
        borderColor = "#6a6459ff",
    },
    {
        selectors = { "eotwsAbilityName" },
        color = C.CREAM_LIGHT,
        fontSize = 16,
        bold = true,
    },
    {
        selectors = { "eotwsAbilityName", "compact" },
        fontSize = 14.5,
    },
    {
        selectors = { "eotwsAbilityKeywords" },
        color = C.MUTED,
        fontSize = 12,
        width = "100% available",
        textWrap = false,
        textOverflow = "ellipsis",
    },
    {
        selectors = { "eotwsAbilityTag" },
        color = C.MUTED,
        fontSize = 12.5,
    },
    {
        selectors = { "eotwsAbilityTag", "cost" },
        color = C.TAN,
        bold = true,
    },
    {
        selectors = { "eotwsFeatureCard" },
        width = "100%",
        height = "auto",
        tmargin = 7,
        hpad = 14,
        vpad = 10,
        borderBox = true,
        flow = "vertical",
        bgimage = "panels/square.png",
        bgcolor = "#1a1b18d9",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 8,
    },
    {
        selectors = { "eotwsFeatureName" },
        color = C.CREAM_LIGHT,
        fontSize = 16,
        bold = true,
    },
    {
        selectors = { "eotwsPillTag" },
        width = "auto",
        height = "auto",
        lmargin = 5,
        hpad = 7,
        borderBox = true,
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 9,
    },
    {
        selectors = { "eotwsPillTagText" },
        color = C.MUTED,
        fontSize = 12,
    },
    {
        selectors = { "eotwsFeatureChosen" },
        color = C.MUTED,
        fontSize = 13,
        italics = true,
        tmargin = 1,
    },
    {
        selectors = { "eotwsFeatureText" },
        color = C.CREAM,
        fontSize = 14,
        tmargin = 6,
        width = "100%",
        maxWidth = FEATURE_TEXT_MAX_WIDTH,
    },
    {
        selectors = { "eotwsShowMore" },
        color = C.TAN,
        fontSize = 13,
        tmargin = 4,
        underline = true,
    },
    {
        selectors = { "eotwsShowMore", "hover" },
        color = C.CREAM_LIGHT,
    },
    {
        selectors = { "eotwsEmpty" },
        color = C.MUTED,
        fontSize = 14,
        italics = true,
        tmargin = 20,
        width = "100%",
    },
    --top bar
    {
        selectors = { "eotwsTopBar" },
        bgimage = "panels/square.png",
        bgcolor = C.TOPBAR,
        cornerRadius = 10,
    },
    --you're needed: the bar itself turns gold, so nothing below it moves
    {
        selectors = { "eotwsTopBar", "needed" },
        bgcolor = "#ffd66bf2",
    },
    {
        selectors = { "eotwsNeededText" },
        color = C.INK,
        fontSize = 17,
        bold = true,
    },
    {
        selectors = { "eotwsSwitchLabel" },
        color = C.MUTED,
        fontSize = 11,
        bold = true,
        uppercase = true,
    },
    {
        selectors = { "eotwsSwitchSep" },
        width = 1,
        height = 44,
        hmargin = 6,
        valign = "center",
        bgimage = "panels/square.png",
        bgcolor = C.BORDER,
    },
    {
        selectors = { "eotwsThumb" },
        width = 40,
        height = 56,
        lmargin = 8,
        valign = "center",
        bgimage = "panels/square.png",
        bgcolor = "#151515ff",
        borderWidth = 1,
        borderColor = "#000000ff",
        cornerRadius = 6,
    },
    {
        selectors = { "eotwsThumb", "mine" },
        borderWidth = 2,
        borderColor = "#6fa8ffcc",
    },
    {
        selectors = { "eotwsThumb", "current" },
        borderWidth = 2,
        borderColor = C.CREAM_LIGHT,
    },
    {
        selectors = { "eotwsThumb", "hover" },
        brightness = 1.15,
    },
    {
        selectors = { "eotwsButtonText" },
        color = C.CREAM,
        fontSize = 14,
    },
    {
        selectors = { "eotwsButton", "off" },
        opacity = 0.45,
    },
    {
        selectors = { "eotwsLock" },
        width = 10,
        height = 12,
        rmargin = 7,
        valign = "center",
        bgimage = "phosphor/lock-fill.png",
        bgcolor = C.CREAM,
    },
    {
        selectors = { "eotwsCloseText" },
        color = C.CREAM,
        fontSize = 14,
    },
    {
        selectors = { "eotwsCloseText", "onGold" },
        color = C.GOLD,
    },
    {
        selectors = { "eotwsClose", "onGold" },
        bgcolor = C.INK,
        borderColor = C.INK,
    },
    {
        selectors = { "eotwsKbd" },
        width = "auto",
        height = "auto",
        lmargin = 8,
        hpad = 5,
        borderBox = true,
        valign = "center",
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 4,
    },
    {
        selectors = { "eotwsKbd", "onGold" },
        borderColor = "#ffd66b66",
    },
    {
        selectors = { "eotwsKbdText" },
        color = C.MUTED,
        fontSize = 11,
    },
    {
        selectors = { "eotwsKbdText", "onGold" },
        color = C.GOLD,
    },
    {
        selectors = { "eotwsStateChip" },
        width = "auto",
        height = "auto",
        lmargin = 10,
        hpad = 14,
        vpad = 5,
        borderBox = true,
        valign = "center",
        bgimage = "panels/square.png",
        bgcolor = "#bc9b7b24",
        borderWidth = 1,
        borderColor = "#bc9b7b99",
        cornerRadius = 12,
    },
    {
        selectors = { "eotwsStateChipText" },
        color = C.CREAM_LIGHT,
        fontSize = 14,
    },
    {
        selectors = { "eotwsStateChipSmall" },
        color = C.MUTED,
        fontSize = 11.5,
    },
    {
        selectors = { "eotwsOwnerChip" },
        width = "auto",
        height = "auto",
        lmargin = 10,
        hpad = 10,
        vpad = 4,
        borderBox = true,
        valign = "center",
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        borderWidth = 1,
        borderColor = "#ffffff24",
        cornerRadius = 6,
    },
    {
        selectors = { "eotwsOwnerChipText" },
        color = C.CREAM,
        fontSize = 13.5,
    },
    --stats band
    {
        selectors = { "eotwsTile" },
        width = "20%-6",
        height = "auto",
        vpad = 6,
        borderBox = true,
        flow = "vertical",
        bgimage = "panels/square.png",
        bgcolor = "#00000038",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 8,
    },
    {
        selectors = { "eotwsTileLabel" },
        color = C.TAN,
        fontSize = 11.5,
        bold = true,
        uppercase = true,
        halign = "center",
    },
    {
        selectors = { "eotwsTileValue" },
        color = C.CREAM_LIGHT,
        fontSize = 30,
        bold = true,
        halign = "center",
    },
    {
        selectors = { "eotwsLines" },
        width = "45%-26",
        height = "auto",
        lmargin = 26,
        lpad = 24,
        borderBox = true,
        valign = "center",
        flow = "vertical",
        borderColor = "#ffffff14",
        border = { x1 = 1, x2 = 0, y1 = 0, y2 = 0 },
    },
    {
        selectors = { "eotwsStatLabel" },
        color = C.TAN,
        fontSize = 11.5,
        bold = true,
        uppercase = true,
    },
    {
        selectors = { "eotwsStatValue" },
        color = C.CREAM_LIGHT,
        fontSize = 21,
        bold = true,
        lmargin = 8,
        valign = "center",
    },
    {
        selectors = { "eotwsStatValue", "small" },
        fontSize = 18,
    },
    --a stat an Equip / Unequip hover (or a change just made) is about to move
    {
        selectors = { "eotwsStatValue", "preview" },
        color = C.GOLD,
    },
    {
        selectors = { "eotwsTileValue", "preview" },
        color = C.GOLD,
    },
    {
        selectors = { "eotwsTierLabel" },
        color = C.MUTED,
        fontSize = 14,
    },
    {
        selectors = { "eotwsMovement" },
        color = C.CREAM,
        fontSize = 14,
    },
    {
        selectors = { "eotwsPotency" },
        hpad = 14,
        vpad = 3,
        borderBox = true,
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        borderWidth = 1,
        borderColor = "#bc9b7b59",
        cornerRadius = 18,
    },
    {
        selectors = { "eotwsWordsCol" },
        height = "auto",
        flow = "vertical",
    },
    {
        selectors = { "eotwsWordsCol", "rest" },
        lpad = 16,
        lmargin = 2,
        borderBox = true,
        borderColor = "#ffffff14",
        border = { x1 = 1, x2 = 0, y1 = 0, y2 = 0 },
    },
    {
        selectors = { "eotwsWords" },
        color = C.CREAM,
        fontSize = 14,
    },
    {
        selectors = { "eotwsSkillGroup" },
        color = C.TAN,
        fontSize = 11.5,
        bold = true,
        uppercase = true,
    },
    --kit card
    {
        selectors = { "eotwsKitName" },
        color = C.CREAM_LIGHT,
        fontSize = 16.5,
        bold = true,
    },
    {
        selectors = { "eotwsKitGear" },
        color = C.MUTED,
        fontSize = 12.5,
    },
    {
        selectors = { "eotwsKitDesc" },
        color = C.CREAM,
        fontSize = 13,
    },
    {
        selectors = { "eotwsKvLabel" },
        color = C.TAN,
        fontSize = 11,
        bold = true,
        uppercase = true,
        valign = "center",
    },
    {
        selectors = { "eotwsKvValue" },
        color = C.CREAM_LIGHT,
        fontSize = 13.5,
        bold = true,
        valign = "center",
    },
    {
        selectors = { "eotwsNone" },
        color = C.MUTED,
        fontSize = 13.5,
    },
    --treasures card
    {
        selectors = { "eotwsSub" },
        color = C.TAN,
        fontSize = 11.5,
        bold = true,
        uppercase = true,
    },
    {
        selectors = { "eotwsSubCount" },
        color = C.TAN,
        fontSize = 11.5,
    },
    {
        selectors = { "eotwsItem" },
        bgimage = "panels/square.png",
        bgcolor = "#00000033",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 6,
        hpad = 10,
        vpad = 5,
        borderBox = true,
        minHeight = 31,
    },
    {
        selectors = { "eotwsItem", "hover" },
        borderColor = "#6a6459ff",
    },
    {
        selectors = { "eotwsItem", "todo" },
        borderColor = C.GOLD,
    },
    {
        selectors = { "eotwsItem", "chip" },
        hpad = 9,
        vpad = 4,
        minHeight = 28,
    },
    {
        selectors = { "eotwsItem", "glow" },
        bgcolor = "#ffd66b55",
        transitionTime = 1.1,
    },
    {
        selectors = { "eotwsItemName" },
        color = C.CREAM,
        fontSize = 13.5,
        valign = "center",
    },
    {
        selectors = { "eotwsItemName", "row" },
        width = "100% available",
        textWrap = false,
        textOverflow = "ellipsis",
    },
    {
        selectors = { "eotwsItemSlot" },
        color = C.MUTED,
        fontSize = 13.5,
        valign = "center",
    },
    {
        selectors = { "eotwsQty" },
        color = C.CREAM_LIGHT,
        fontSize = 13,
        bold = true,
        valign = "center",
    },
    {
        selectors = { "eotwsTag" },
        color = C.MUTED,
        fontSize = 12,
        rmargin = 4,
    },
    {
        selectors = { "eotwsWarnChip" },
        width = "auto",
        height = "auto",
        hpad = 6,
        vpad = 1,
        borderBox = true,
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        borderWidth = 1,
        borderColor = "#e9b86f80",
        cornerRadius = 9,
    },
    {
        selectors = { "eotwsWarnText" },
        color = C.WARN,
        fontSize = 11,
    },
    {
        selectors = { "eotwsSmallButton" },
        width = "auto",
        height = 24,
        hpad = 9,
        borderBox = true,
        bgimage = "panels/square.png",
        bgcolor = C.CARD,
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 5,
    },
    {
        selectors = { "eotwsSmallButton", "hover" },
        bgcolor = C.CARD_HOVER,
        borderColor = C.TAN,
    },
    {
        selectors = { "eotwsSmallButton", "primary" },
        bgcolor = C.GOLD,
        borderColor = C.GOLD,
    },
    {
        selectors = { "eotwsSmallButton", "primary", "hover" },
        brightness = 1.1,
    },
    {
        selectors = { "eotwsSmallButton", "off" },
        opacity = 0.45,
    },
    {
        selectors = { "eotwsSmallButtonText" },
        color = C.CREAM_LIGHT,
        fontSize = 12.5,
        bold = true,
        valign = "center",
    },
    {
        selectors = { "eotwsSmallButtonText", "parent:primary" },
        color = C.INK,
    },
    {
        selectors = { "eotwsCta" },
        width = "auto",
        height = "auto",
        hpad = 8,
        vpad = 1,
        borderBox = true,
        bgimage = "panels/square.png",
        bgcolor = C.GOLD,
        borderWidth = 1,
        borderColor = C.GOLD,
        cornerRadius = 9,
    },
    {
        selectors = { "eotwsCta", "off" },
        bgcolor = "#00000000",
        borderColor = C.BORDER,
    },
    {
        selectors = { "eotwsCtaText" },
        color = C.INK,
        fontSize = 12,
        bold = true,
    },
    {
        selectors = { "eotwsCtaText", "parent:off" },
        color = C.MUTED,
    },
    --the bottom of the treasures list fades out under the last rows
    {
        selectors = { "eotwsFade" },
        bgimage = "panels/square.png",
        bgcolor = "white",
        gradient = gui.Gradient{
            point_a = { x = 0, y = 1 },
            point_b = { x = 0, y = 0 },
            stops = {
                { position = 0, color = "#0e0d0b00" },
                { position = 1, color = "#0e0d0bcc" },
            },
        },
    },
}

--The sheet's rules after the hero card's, whose stamina bar the card reuses.
--Built once so the theme's merge cache (keyed by table) is hit every open.
local SHEET_RULES = {}
for _,list in ipairs({ EotwHeroCard.rules, RULES }) do
    for _,rule in ipairs(list) do
        SHEET_RULES[#SHEET_RULES+1] = rule
    end
end

--The sheet that is open, if any. Only one at a time: opening another Hero
--replaces it.
---@type Panel|nil
local m_sheet = nil

--- shared pieces ------------------------------------------------------------

---@param text string
---@param classes? string[]
---@param args? table extra panel fields
---@return Panel
local function Text(text, classes, args)
    local all = { "eotwsText" }
    for _,c in ipairs(classes or {}) do
        all[#all+1] = c
    end
    local fields = { classes = all, text = text }
    for k,v in pairs(args or {}) do
        fields[k] = v
    end
    return gui.Label(fields)
end

--A shimmering placeholder where a value will land. The sheet's think flips
--"lit" on every placeholder to make the shimmer.
---@param width number|string
---@param height number
---@param args? table extra panel fields
---@return Panel
local function Skel(width, height, args)
    local fields = {
        classes = { "eotwsSkel" },
        width = width,
        height = height,
        interactable = false,
        eotwsShimmer = function(element, lit)
            element:SetClass("lit", lit)
        end,
    }
    for k,v in pairs(args or {}) do
        fields[k] = v
    end
    return gui.Panel(fields)
end

--A plate holding one region of the sheet. In town it frosts the Guild art
--behind it (engine `frost`); in a game the frosted backdrop already blurs what
--is behind, so the plates stay plain. Solid while Transparent UI is off.
---@param ctx table the sheet's context (see EotwHeroSheet.Show)
---@param args table panel fields
---@return Panel
local function Block(ctx, args)
    args.classes = { "eotwsBlock", cond(ctx.inGame, "ingame", "town"), cond(ctx.transparent, "see", "opaque") }
    --an engine without frost: the map blur under the plate, as before
    args.blurBackground = ctx.transparent and not ctx.frost
    if args.pad == nil and args.hpad == nil then
        args.hpad = 16
        args.vpad = 12
    end
    args.borderBox = true
    local panel = gui.Panel(args)
    if ctx.frost and not ctx.inGame then
        FrostField(panel).frost = FROST_RADIUS
    end
    return panel
end

---@param height? number
---@return Panel
local function Hairline(height)
    return gui.Panel{
        width = "100%",
        height = height or 1,
        bgimage = "panels/square.png",
        bgcolor = C.HAIRLINE,
        vmargin = 9,
    }
end

--The hover on a stat: its base, then one line per source (signed 2026-10-10:
--"Base 5" / "Panther kit +1"). Nothing when the stat has neither.
---@param s table|nil a Sources table { base, sources = { {name, value} } }
---@return string
local function SourcesTip(s)
    if s == nil then
        return ""
    end
    local lines = {}
    if s.base ~= nil then
        lines[#lines+1] = string.format("Base %s", tostring(s.base))
    end
    for _,src in ipairs(s.sources or {}) do
        lines[#lines+1] = string.format("%s %s", src.name or "", src.value or "")
    end
    return table.concat(lines, "\n")
end

---@param n number|nil
---@return string
local function SignedText(n)
    n = tonumber(n) or 0
    if n >= 0 then
        return string.format("+%d", n)
    end
    return string.format("%d", n)
end

--- the card (left column, top) -------------------------------------------------

local MIDDOT = "\u{00B7}"

---@param n number
---@return string
local function Ordinal(n)
    if n == 1 then
        return "1st"
    elseif n == 2 then
        return "2nd"
    elseif n == 3 then
        return "3rd"
    end
    return string.format("%dth", n)
end

--Builds a hover that shows whatever text the panel's data.tip holds right
--now, so a panel can change its tooltip without being rebuilt.
---@param element Panel
local function HoverTip(element)
    local tip = element.data.tip
    if tip ~= nil and tip ~= "" then
        gui.Tooltip(tip)(element)
    end
end

--- pinned cards (every tooltip pins) ---------------------------------------------

--The element whose card is pinned open (its popup), if any. Escape closes a
--pinned card before it closes the sheet.
---@type Panel|nil
local m_pinned = nil

--A hover card or a pinned one: the content plus the hint underneath (A5).
--Set directly, not by class: tooltips and popups draw outside the sheet.
---@param content Panel
---@param pinned boolean
---@return Panel
local function CardFrame(content, pinned)
    return gui.TooltipFrame(gui.Panel{
        width = "auto",
        height = "auto",
        flow = "vertical",
        content,
        gui.Label{
            text = cond(pinned, "Click elsewhere or press Esc to close.", "Click to keep it open."),
            width = "auto",
            height = "auto",
            tmargin = 8,
            fontSize = 12,
            italics = true,
            color = C.MUTED,
        },
    }, { halign = "right", valign = "center" })
end

--Pins `popup` open beside `element` until the player clicks elsewhere or
--presses Escape.
---@param element Panel
---@param popup Panel
local function PinPanel(element, popup)
    audio.FireSoundEvent("Mouse.Click")
    element.tooltip = nil
    element.popupPositioning = "panel"
    element.popup = popup
    m_pinned = element
end

--Click handler for a text tooltip (data.tip): keep it open.
---@param element Panel
local function PinTip(element)
    local tip = element.data.tip
    if tip == nil or tip == "" then
        return
    end
    PinPanel(element, gui.TooltipFrame(gui.Label{
        text = tip,
        width = "auto",
        height = "auto",
        maxWidth = 460,
        textWrap = true,
        fontSize = 15,
        color = "white",
    }, { halign = "right", valign = "center" }))
end

--Closes a pinned card; true if there was one.
---@return boolean
local function ClosePin()
    local pinned = m_pinned
    m_pinned = nil
    if pinned ~= nil and pinned.valid and pinned.popup ~= nil then
        pinned.popup = nil
        return true
    end
    return false
end


--A thin vertical rule between the vitals cells.
---@return Panel
local function VRule()
    return gui.Panel{
        width = 1,
        height = 30,
        valign = "center",
        hmargin = 10,
        bgimage = "panels/square.png",
        bgcolor = C.HAIRLINE,
    }
end

--A run of diagonal stripes clipped to a box: the hatched stretch of the XP
--bar, and the swatch beside the Level 10 epic resource.
---@param width number
---@param height number
---@param args? table extra panel fields
---@return Panel
local function Hatch(width, height, args)
    local stripes = {}
    for i = 0, math.ceil((width + height) / HATCH_STEP) do
        stripes[#stripes+1] = gui.Panel{
            floating = true,
            halign = "left",
            valign = "center",
            x = i * HATCH_STEP - height,
            width = 2,
            height = height * 3,
            rotate = 45,
            bgimage = "panels/square.png",
            bgcolor = C.HATCH,
            interactable = false,
        }
    end
    local fields = {
        width = width,
        height = height,
        flow = "none",
        clip = true,
        bgimage = "panels/square.png",
        bgcolor = C.HATCH_GROUND,
        children = stripes,
    }
    for k,v in pairs(args or {}) do
        fields[k] = v
    end
    return gui.Panel(fields)
end

--The level row under the subtitle: Level, the XP bar (the XP banked
--Victories will add at the next respite hatched after the fill, a notch where
--it starts) and the next Level; at Level 10, the class's epic resource
--instead. Then the owner's own lines: ready to Level, or a respite would Level.
---@param d table EotwHeroSheet.Data
---@param fallen boolean
---@return Panel[]
local function LevelRow(d, fallen)
    local p = d.progress
    if p == nil then
        return {}
    end
    --a fallen Hero's progress is frozen: no respite and no Level up are coming
    local victories = cond(fallen, 0, p.victories)
    local ready = p.readyToLevel and not fallen
    local reach = p.respiteWouldLevel and not fallen

    local rows = {}
    if p.maxLevel then
        local epic = p.epic or { name = "", value = 0, gainAtRespite = 0 }
        local cells = {
            Text("10", { "eotwsLevelNumber" }),
            gui.Panel{
                classes = { cond(epic.iconid ~= nil, "eotwsEpicIcon", "collapsed") },
                bgimage = epic.iconid or "panels/square.png",
                lmargin = 8,
            },
            Text(string.format("%s <b>%d</b>", epic.name, epic.value), { "eotwsPlateText", "eotwsEpic" }, { lmargin = 7 }),
        }
        if victories > 0 then
            cells[#cells+1] = gui.Panel{
                width = "auto",
                height = "auto",
                halign = "right",
                valign = "center",
                flow = "horizontal",
                data = { tip = string.format("%d %s %d XP and %d %s at the next respite.",
                    victories, cond(victories == 1, "Victory becomes", "Victories become"), victories, victories, epic.name) },
                hover = HoverTip,
                click = PinTip,
                Hatch(18, 7, { valign = "center", cornerRadius = 3 }),
                Text(string.format("+%d at the next respite", victories), { "eotwsPlateText" }, { lmargin = 6, valign = "center" }),
            }
        end
        rows[#rows+1] = gui.Panel{
            width = "100%",
            height = "auto",
            tmargin = 9,
            flow = "horizontal",
            children = cells,
        }
        return rows
    end

    local per = math.max(1, p.xpPerLevel)
    local into = math.max(0, p.xpIntoLevel)
    local fill = cond(ready, 1, math.min(1, into / per))
    local tip
    if ready then
        tip = string.format("%d XP: enough for Level %d.", into, p.nextLevel)
    else
        tip = string.format("%d of %d XP to Level %d.", into, per, p.nextLevel)
    end

    local barChildren = {
        gui.Panel{
            classes = { "eotwsXpFill", cond(ready, "ready", "normal") },
            floating = true,
            halign = "left",
            width = math.max(0, XP_BAR_WIDTH * fill),
            height = "100%",
        },
    }
    if victories > 0 and not ready then
        local hatchEnd = math.min(1, (into + victories) / per)
        local hatchWidth = math.floor(XP_BAR_WIDTH * (hatchEnd - fill))
        if hatchWidth > 0 then
            barChildren[#barChildren+1] = Hatch(hatchWidth, XP_BAR_HEIGHT, {
                floating = true,
                halign = "left",
                x = XP_BAR_WIDTH * fill,
            })
        end
        barChildren[#barChildren+1] = gui.Panel{
            floating = true,
            halign = "left",
            x = XP_BAR_WIDTH * fill - 1,
            width = 2,
            height = "100%",
            bgimage = "panels/square.png",
            bgcolor = "black",
        }
        tip = string.format("%s %d %s %d XP at the next respite.", tip, victories,
            cond(victories == 1, "Victory becomes", "Victories become"), victories)
        if reach then
            tip = string.format("%s Enough for Level %d.", tip, p.nextLevel)
        end
    end

    rows[#rows+1] = gui.Panel{
        width = "100%",
        height = "auto",
        tmargin = 9,
        flow = "horizontal",
        Text(tostring(p.level), { "eotwsLevelNumber" }),
        gui.Panel{
            classes = { "eotwsXpBar" },
            width = XP_BAR_WIDTH,
            height = XP_BAR_HEIGHT,
            hmargin = 8,
            valign = "center",
            flow = "none",
            clip = true,
            data = { tip = tip },
            hover = HoverTip,
            click = PinTip,
            children = barChildren,
        },
        Text(tostring(p.nextLevel), { "eotwsLevelNumber", "next", cond(ready, "ready", cond(reach, "reach", "normal")) }),
    }

    --only the owner sees these: they speak to the player ("your Hero")
    if d.mine and not fallen then
        if ready then
            rows[#rows+1] = Text("Head to the Training Grounds to Level your Hero.", { "eotwsReadyLine" }, { tmargin = 6 })
        elseif reach then
            rows[#rows+1] = Text("A respite would Level this Hero.", { "eotwsRespiteLine" }, { tmargin = 6 })
        end
    end
    return rows
end

--The line under the stamina bar: where Winded starts (or that the Hero is
--Winded, Dying or Dead) on the left, where Dead starts on the right.
---@param s table d.stamina
---@return string left, string right
local function StaminaNote(s)
    local left
    if s.state == "dead" then
        left = "<b>Dead</b>"
    elseif s.state == "dying" then
        left = "<b>Dying</b>"
    elseif s.state == "winded" then
        left = string.format("<b>Winded</b> at %d", s.winded)
    else
        left = string.format("Winded at <b>%d</b>", s.winded)
    end
    return left, string.format("Dead at <b>%d</b>", s.deadAt)
end

--The status shape the character panel pairs with the stamina colour, for the
--Status Icons accessibility setting.
local STATUS_ICONS = {
    healthy = "drawsteel/Icon_STA_Healthy.png",
    winded = "drawsteel/Icon_STA_Winded.png",
    dying = "drawsteel/Icon_STA_Dying.png",
    dead = "drawsteel/Icon_STA_Dying.png",
}

--The hero card at sheet size: the Hero's art full-bleed, with a plate at the
--bottom holding the name, titles, subtitle, level row, stamina and vitals.
--Until the Hero loads the plate shows a skeleton and "Loading {Hero}...".
--ctx.fallen (from the Graveyard) swaps the vitals for the epitaph.
---@param ctx table
---@return Panel
local function CardRegion(ctx)
    local nameLabel = Text(ctx.LoadingText(), { "eotwsName" })
    local retryButton = gui.Panel{
        classes = { "eotwsButton", "collapsed" },
        width = "auto",
        height = 26,
        hpad = 10,
        borderBox = true,
        tmargin = 6,
        click = function()
            audio.FireSoundEvent("Mouse.Click")
            ctx.Retry()
        end,
        Text("Try again", nil, { fontSize = 13, bold = true, valign = "center" }),
    }

    local skeleton = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        --subtitle, then the level row and its numbers
        Skel(190, 16, { tmargin = 6 }),
        gui.Panel{
            width = "100%",
            height = 14,
            tmargin = 12,
            flow = "horizontal",
            Skel(8, 14),
            Skel("100%-36", 10, { hmargin = 10, valign = "center" }),
            Skel(8, 14),
        },
        --stamina bar and its Winded / Dead line
        Skel("100%", 20, { tmargin = 12 }),
        gui.Panel{
            width = "100%",
            height = 12,
            tmargin = 8,
            flow = "horizontal",
            Skel(80, 12),
            Skel(70, 12, { halign = "right" }),
        },
        Hairline(),
        --vitals: Recoveries ring and label, Victories, heroic resource
        gui.Panel{
            width = "100%",
            height = 38,
            flow = "horizontal",
            Skel(42, 38),
            Skel(172, 32, { lmargin = 10, valign = "center" }),
            Skel(80, 24, { lmargin = 10, valign = "center" }),
            Skel(12, 24, { halign = "right", valign = "center" }),
        },
    }

    --the live plate, filled from the Hero's data once loaded. Each part below
    --is rebuilt only when what it shows changes (see Paint).
    local titlesLine = gui.Panel{
        classes = { "collapsed" },
        width = "100%",
        height = "auto",
        tmargin = 3,
        flow = "horizontal",
        wrap = true,
    }
    local subtitle = Text("", { "eotwsSubtitle" })
    local levelRow = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
    }

    --the stamina bar is the hero card's own (S1), drawn larger; the status
    --shape sits inside its left end when Status Icons is on.
    local statusIcon = gui.Panel{
        classes = { "eotwsStatusIcon", "collapsed" },
        floating = true,
        halign = "left",
        valign = "center",
        x = 6,
        interactable = false,
    }
    local bar = EotwHeroCard.CreateStaminaBar(ctx.charid, { height = 22, fontSize = 13 })
    --hovering the bar shows max Stamina's base and sources
    local staminaHover = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "none",
        --a clear background so the mouse finds it (the bar itself ignores it)
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        data = { tip = "" },
        hover = HoverTip,
        click = PinTip,
        bar,
        statusIcon,
    }
    local noteLeft = Text("", { "eotwsPlateText", "eotwsNote" })
    local noteRight = Text("", { "eotwsPlateText", "eotwsNote" }, { halign = "right" })
    local staminaBlock = gui.Panel{
        width = "100%",
        height = "auto",
        tmargin = 9,
        flow = "vertical",
        staminaHover,
        gui.Panel{
            width = "100%",
            height = "auto",
            tmargin = 5,
            flow = "horizontal",
            noteLeft,
            noteRight,
        },
    }

    --vitals: Recoveries ring + label, Victories, the heroic resource
    local ringLabel = Text("", { "eotwsRingNumber" })
    local ring = gui.Panel{
        classes = { "eotwsRing" },
        data = { tip = "" },
        hover = HoverTip,
        click = PinTip,
        ringLabel,
    }
    local recoveriesSub = Text("", { "eotwsPlateText" })
    local recoveriesCell = gui.Panel{
        width = "auto",
        height = "auto",
        lmargin = 10,
        valign = "center",
        flow = "vertical",
        data = { tip = "" },
        hover = HoverTip,
        click = PinTip,
        Text("Recoveries", { "eotwsPlateStrong" }),
        recoveriesSub,
    }
    local victoriesNumber = Text("", { "eotwsVitalNumber" })
    local victoriesWord = Text("", { "eotwsPlateText" }, { lmargin = 6, valign = "bottom", bmargin = 3 })
    local victoriesCell = gui.Panel{
        width = "auto",
        height = "auto",
        valign = "center",
        flow = "horizontal",
        data = { tip = "" },
        hover = HoverTip,
        click = PinTip,
        victoriesNumber,
        victoriesWord,
    }
    local resourceIcon = gui.Panel{
        classes = { "eotwsResourceIcon" },
        bgimage = "panels/square.png",
        interactable = false,
    }
    local resourceNumber = Text("", { "eotwsVitalNumber" }, { lmargin = 7 })
    local resourceCell = gui.Panel{
        width = "auto",
        height = "auto",
        valign = "center",
        flow = "horizontal",
        data = { tip = "" },
        hover = HoverTip,
        click = PinTip,
        resourceIcon,
        resourceNumber,
    }
    local vitals = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        Hairline(),
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            ring,
            recoveriesCell,
            gui.Panel{
                width = "auto",
                height = "auto",
                halign = "right",
                valign = "center",
                flow = "horizontal",
                VRule(),
                victoriesCell,
                VRule(),
                resourceCell,
            },
        },
    }

    --a fallen Hero (from the Graveyard): where they fell and who played them
    local epitaphLabel = Text("", { "eotwsEpitaph" })
    local epitaph = gui.Panel{
        classes = { "collapsed" },
        width = "100%",
        height = "auto",
        flow = "vertical",
        Hairline(),
        epitaphLabel,
    }

    --one surge icon per surge in a corner of the art just above the plate
    local surges = gui.Panel{
        classes = { "eotwsSurges", "collapsed" },
        floating = true,
        halign = "right",
        valign = "top",
        x = -4,
        y = -(15 + 10 + 8),
        data = { tip = "", count = nil },
        hover = HoverTip,
        click = PinTip,
    }

    local live = gui.Panel{
        classes = { "collapsed" },
        width = "100%",
        height = "auto",
        flow = "vertical",
        titlesLine,
        subtitle,
        levelRow,
        staminaBlock,
        vitals,
        epitaph,
    }

    local card

    --what each part last showed, so a live refresh rebuilds only what changed
    local seen = {}

    ---@param d table EotwHeroSheet.Data (all of it, or the live sections)
    local function Paint(d)
        local fallen = ctx.fallen ~= nil
        local dead = fallen or (d.stamina ~= nil and d.stamina.state == "dead")
        card:SetClass("dead", dead)

        if d.titles ~= nil then
            local names = {}
            for i,t in ipairs(d.titles) do
                if i <= MAX_TITLES then
                    names[#names+1] = t.name
                end
            end
            local sig = table.concat(names, "|")
            if sig ~= seen.titles then
                seen.titles = sig
                local children = {}
                if #names > 0 then
                    children[1] = gui.Panel{ classes = { "eotwsMedal" }, rmargin = 5 }
                end
                for i = 1, #names do
                    local t = d.titles[i]
                    local lines = {
                        string.format("<b>%s</b>", t.name),
                        string.format("Title %s %s echelon", MIDDOT, Ordinal(t.echelon)),
                    }
                    if t.flavor ~= nil and t.flavor ~= "" then
                        lines[#lines+1] = string.format("<i>%s</i>", t.flavor)
                    end
                    if t.deed ~= nil and t.deed ~= "" then
                        lines[#lines+1] = string.format("<b>Earned:</b> %s", t.deed)
                    end
                    for _,b in ipairs(t.benefits or {}) do
                        if b.name ~= nil and b.text ~= nil then
                            lines[#lines+1] = string.format("<b>%s</b> %s", b.name, b.text)
                        elseif b.text ~= nil then
                            lines[#lines+1] = b.text
                        end
                    end
                    --a title keeps its comma, so a long line wraps after one
                    children[#children+1] = gui.Panel{
                        width = "auto",
                        height = "auto",
                        flow = "horizontal",
                        rmargin = 5,
                        Text(t.name, { "eotwsTitle" }, {
                            data = { tip = table.concat(lines, "\n\n") },
                            hover = HoverTip,
                            click = PinTip,
                        }),
                        Text(cond(i < #names, ",", ""), { "eotwsTitle", "sep" }),
                    }
                end
                titlesLine.children = children
                titlesLine:SetClass("collapsed", #names == 0)
            end
        end

        if d.level ~= nil then
            local line = string.format("Level %d %s %s", d.level, d.ancestry or "", d.className or "")
            if d.subclass ~= nil and d.subclass ~= "" then
                line = string.format("%s %s %s", line, MIDDOT, d.subclass)
            end
            subtitle.text = line
        end

        local p = d.progress
        if p ~= nil then
            local sig = string.format("%d|%d|%d|%d|%s|%s|%s|%s", p.level, p.xpIntoLevel, p.victories,
                cond(p.epic ~= nil, p.epic and p.epic.value or 0, 0), tostring(p.readyToLevel),
                tostring(p.respiteWouldLevel), tostring(d.mine), tostring(fallen))
            if sig ~= seen.level then
                seen.level = sig
                levelRow.children = LevelRow(d, fallen)
            end
        end

        local s = d.stamina
        if s ~= nil then
            local left, right = StaminaNote(s)
            noteLeft.text = left
            noteRight.text = right
            local icons = ThemeEngine.GetAccessibility().statusIcons
            statusIcon:SetClass("collapsed", not icons)
            statusIcon.bgimage = STATUS_ICONS[s.state] or STATUS_ICONS.healthy
        end

        --the stat hovers (base + sources) come from the full read, which the
        --live refresh does not repeat
        local stats = (ctx.data ~= nil and ctx.data.stats) or {}
        staminaHover.data.tip = SourcesTip(stats.maxStamina)
        local r = d.recoveries
        if r ~= nil then
            ringLabel.text = tostring(r.current)
            ring:SetClass("empty", r.current <= 0)
            local tip = string.format("Each Recovery regains %d Stamina.", r.value)
            local function WithSources(s)
                local more = SourcesTip(s)
                if more == "" then
                    return tip
                end
                return tip .. "\n\n" .. more
            end
            ring.data.tip = WithSources(stats.recoveries)
            recoveriesCell.data.tip = WithSources(stats.recoveryValue)
            recoveriesSub.text = string.format("of %d %s +%d each", r.max, MIDDOT, r.value)
        end

        if p ~= nil then
            local resourceName = (d.resource ~= nil and d.resource.name) or "Heroic Resource"
            victoriesNumber.text = tostring(p.victories)
            victoriesWord.text = cond(p.victories == 1, "Victory", "Victories")
            victoriesCell.data.tip = string.format(
                "Starts each combat with %d extra %s. Victories become XP at the next respite.",
                p.victories, resourceName)
        end

        if d.resource ~= nil then
            local res = d.resource
            resourceIcon:SetClass("collapsed", res.iconid == nil)
            if res.iconid ~= nil then
                resourceIcon.bgimage = res.iconid
            end
            resourceNumber.text = tostring(cond(dead, 0, res.value))
            resourceCell.data.tip = res.name or "Heroic Resource"
        end

        if d.surges ~= nil then
            local count = cond(dead, 0, math.min(MAX_SURGE_ICONS, d.surges))
            if count ~= surges.data.count then
                surges.data.count = count
                local icons = {}
                for _ = 1, count do
                    icons[#icons+1] = gui.Panel{ classes = { "eotwsSurgeIcon" }, interactable = false }
                end
                surges.children = icons
            end
            surges:SetClass("collapsed", count == 0)
            surges.data.tip = string.format("%d %s. Each adds %d damage, up to 3 per roll. 2 raise a potency by 1.",
                d.surges, cond(d.surges == 1, "surge", "surges"), d.surgeDamage or 0)
        end

        vitals:SetClass("collapsed", fallen)
        staminaBlock:SetClass("collapsed", fallen)
        epitaph:SetClass("collapsed", not fallen)
        if fallen then
            local f = ctx.fallen
            local who = cond(d.mine, "you", f.playedBy or d.ownerName or "")
            epitaphLabel.text = string.format("Fell in <b>%s</b>, week %s\nPlayed by %s",
                f.encounter or "", tostring(f.week or ""), who)
        end
    end

    local plate = gui.Panel{
        classes = { "eotwsPlate" },
        floating = true,
        halign = "center",
        valign = "bottom",
        width = LEFT_WIDTH - 20,
        height = "auto",
        bmargin = 10,
        hpad = 14,
        vpad = 12,
        borderBox = true,
        flow = "vertical",

        surges,
        nameLabel,
        retryButton,
        skeleton,
        live,
    }

    card = gui.Panel{
        classes = { "eotwsCard" },
        width = LEFT_WIDTH,
        height = CARD_HEIGHT,
        flow = "none",

        --the sheet read the Hero (ctx.data) and moved to "ready": show it
        eotwsState = function(element, state)
            if state == "failed" then
                nameLabel.text = ctx.FailedText()
            elseif state == "ready" then
                nameLabel.text = ctx.HeroName()
            else
                nameLabel.text = ctx.LoadingText()
            end
            retryButton:SetClass("collapsed", state ~= "failed")
            local ready = state == "ready" and ctx.data ~= nil
            skeleton:SetClass("collapsed", ready)
            live:SetClass("collapsed", not ready)
            if ready then
                local tok = ctx.Token()
                if tok ~= nil then
                    EotwHeroCard.ApplyPortrait(element, tok, LEFT_WIDTH / CARD_HEIGHT)
                end
                Paint(ctx.data)
                bar:FireEvent("refreshCard")
            end
        end,

        --any character change: re-read the cheap live sections and repaint
        --what changed (the stamina bar watches for itself).
        monitorGame = "/characters",
        refreshGame = function(element)
            if ctx.state ~= "ready" then
                return
            end
            local d = EotwHeroSheet.Data(ctx.Token(), LIVE_SECTIONS)
            if d ~= nil then
                --whose Hero it is was settled by the full read (see ReadData)
                if ctx.data ~= nil then
                    d.mine = ctx.data.mine
                end
                Paint(d)
            end
        end,

        plate,
    }
    return card
end

--- kit and treasures (left column) ---------------------------------------------

--A label longer than this would wrap in the two-up kit grid, so the grid
--drops to one bonus per row (the locked design's rule).
local KIT_LABEL_TWO_UP_MAX = 13

--The kit's gear in the book's words (K2): "No armor, heavy weapon",
--"Heavy armor, medium weapon, shield".
---@param gear table|nil { armor = string[], weapons = string[] }
---@return string
local function GearLine(gear)
    if gear == nil then
        return ""
    end
    local function Unique(list)
        local seen, out = {}, {}
        for _,x in ipairs(list or {}) do
            if not seen[x] then
                seen[x] = true
                out[#out+1] = x
            end
        end
        return out
    end
    local armor = Unique(gear.armor)
    local parts = {}
    if #armor > 0 then
        parts[1] = table.concat(armor, " or ") .. " armor"
    else
        parts[1] = "No armor"
    end
    for _,w in ipairs(Unique(gear.weapons)) do
        if w == "Shield" then
            parts[#parts+1] = "shield"
        else
            parts[#parts+1] = string.lower(w) .. " weapon"
        end
    end
    return table.concat(parts, ", ")
end

--The kit's bonuses as label / value pairs, two to a row unless a label is
--long enough to wrap. Each pair may carry a hover (the combined kit's source).
---@param entries table[] { {label, value, tip} }
---@return Panel
local function KitGrid(entries)
    local one = false
    for _,b in ipairs(entries) do
        if #b.label > KIT_LABEL_TWO_UP_MAX then
            one = true
        end
    end
    local function Cell(b, halign)
        return gui.Panel{
            width = cond(one, "100%", "50%-8"),
            halign = halign,
            height = "auto",
            flow = "horizontal",
            data = { tip = b.tip },
            hover = HoverTip,
            click = PinTip,
            Text(b.label, { "eotwsKvLabel" }),
            Text(b.value, { "eotwsKvValue" }, { halign = "right" }),
        }
    end
    local rows = {}
    local perRow = cond(one, 1, 2)
    for i = 1, #entries, perRow do
        local cells = { Cell(entries[i], "left") }
        if perRow == 2 and entries[i + 1] ~= nil then
            cells[2] = Cell(entries[i + 1], "right")
        end
        rows[#rows+1] = gui.Panel{
            width = "100%",
            height = "auto",
            tmargin = 1,
            flow = "horizontal",
            children = cells,
        }
    end
    return gui.Panel{
        width = "100%",
        height = "auto",
        tmargin = 4,
        flow = "vertical",
        children = rows,
    }
end

--The kit card's content (K1-K5): the kit, the Tactician's two kits read as
--one, the class's kit-equivalents side by side, or "No kit".
---@param d table EotwHeroSheet.Data
---@return Panel[]
local function KitContent(d)
    local kit = d.kit
    if kit == nil or kit.kind == "none" or #kit.entries == 0 then
        return {
            Text("Kit", { "eotwsHeader" }),
            Text("No kit", { "eotwsNone" }, { tmargin = 6 }),
        }
    end

    if kit.kind == "kit" then
        local e = kit.entries[1]
        local bonuses = {}
        for _,b in ipairs(e.bonuses or {}) do
            local tip = nil
            if b.from ~= nil then
                tip = string.format("From %s.", b.from)
                if b.other ~= nil then
                    tip = string.format("%s %s gives %s.", tip, b.otherFrom, b.other)
                end
            end
            bonuses[#bonuses+1] = { label = b.label, value = b.value, tip = tip }
        end
        local children = { Text("Kit", { "eotwsHeader" }) }
        if kit.combined then
            children[#children+1] = Text(e.name, { "eotwsKitName" }, { tmargin = 6, width = "100%" })
            children[#children+1] = Text(GearLine(e.gear), { "eotwsKitGear" }, { width = "100%" })
        else
            children[#children+1] = gui.Panel{
                width = "100%",
                height = "auto",
                tmargin = 6,
                flow = "horizontal",
                wrap = true,
                Text(e.name, { "eotwsKitName" }, { rmargin = 10 }),
                Text(GearLine(e.gear), { "eotwsKitGear" }, { valign = "bottom", bmargin = 2 }),
            }
        end
        children[#children+1] = KitGrid(bonuses)
        if kit.meleeFrom ~= nil then
            children[#children+1] = Text(string.format("Melee damage from %s. Change it during a respite.", kit.meleeFrom),
                { "eotwsKitDesc" }, { tmargin = 3, width = "100%" })
        end
        return children
    end

    --kit-equivalents: one section per feature, two-up when there are two
    local function Body(e)
        local body = { Text(e.header, { "eotwsHeader" }) }
        if e.name ~= nil then
            body[#body+1] = Text(e.name, { "eotwsKitName" }, { tmargin = 6, width = "100%" })
            if e.text ~= nil and e.text ~= "" then
                body[#body+1] = Text(e.text, { "eotwsKitDesc" }, { tmargin = 3, width = "100%" })
            end
        else
            body[#body+1] = Text("None chosen", { "eotwsNone" }, { tmargin = 6 })
        end
        return body
    end
    if #kit.entries == 1 then
        return Body(kit.entries[1])
    end
    local sections = {}
    for i,e in ipairs(kit.entries) do
        sections[#sections+1] = gui.Panel{
            width = string.format("%d%%-7", math.floor(100 / #kit.entries)),
            height = "auto",
            lmargin = cond(i > 1, 14, 0),
            flow = "vertical",
            children = Body(e),
        }
    end
    return {
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            children = sections,
        },
    }
end

---@param ctx table
---@return Panel
local function KitRegion(ctx)
    local skeleton = {
        Text("Kit", { "eotwsHeader" }),
        gui.Panel{
            width = "100%",
            height = 16,
            tmargin = 8,
            flow = "horizontal",
            Skel(64, 16),
            Skel(144, 14, { lmargin = 10, valign = "center" }),
        },
        gui.Panel{
            width = "100%",
            height = 14,
            tmargin = 6,
            bmargin = 6,
            flow = "horizontal",
            Skel(130, 12),
            Skel(16, 12, { lmargin = 12 }),
            Skel(128, 12, { lmargin = 12 }),
            Skel(56, 12, { halign = "right" }),
        },
    }
    local function Fill(element)
        if ctx.state == "ready" and ctx.data ~= nil then
            element.children = KitContent(ctx.data)
        end
    end
    return Block(ctx, {
        width = LEFT_WIDTH,
        height = "auto",
        tmargin = LEFT_GAP,
        flow = "vertical",
        children = skeleton,
        eotwsState = Fill,
        eotwsData = Fill,
    })
end

--What a "No benefit" chip says (R5, N8): the kit cannot use this gear.
---@param reason string "nokit", "armor" or "weapon"
---@param gear table|nil the kit's gear
---@return string
local function NoBenefitText(reason, gear)
    if reason == "nokit" or gear == nil then
        return "Without a kit, this gives no benefit."
    elseif reason == "weapon" then
        return "The kit does not use this weapon, so this gives no benefit."
    end
    if #(gear.armor or {}) == 0 then
        return "The kit uses no armor, so this gives no benefit."
    end
    return string.format("The kit uses %s armor, so this gives no benefit.", string.lower(table.concat(gear.armor, " or ")))
end

--The codex's own item card (CreateItemTooltip), plus the R6 warning on a
--weapon or armor treasure the kit cannot use.
---@param it table a d.treasures entry
---@param tok CharacterToken|nil
---@return Panel content for CardFrame
local function ItemCard(it, tok)
    local options = { noninteractive = true, maxHeight = "50%", vscroll = true }
    local children = { it.item:Render(options, tok) }
    if it.noBenefit ~= nil then
        --set directly: a tooltip draws outside the sheet, so its classes do not apply
        children[#children+1] = gui.Label{
            text = "Weapon and armor treasures only help when the kit uses that kind of gear.",
            width = "100%",
            height = "auto",
            tmargin = 8,
            fontSize = 14,
            color = C.WARN,
            textWrap = true,
        }
    end
    return gui.Panel{
        width = 400,
        height = "auto",
        flow = "vertical",
        textWrap = true,
        children = children,
    }
end

---@param ctx table
---@return Panel
local function TreasuresRegion(ctx)
    local Section = function(label, rows)
        local children = {
            Text(label, { "eotwsSub" }, { tmargin = 8 }),
        }
        for _ = 1, rows do
            children[#children+1] = gui.Panel{
                classes = { "eotwsRow" },
                width = "100%",
                height = 31,
                tmargin = 4,
                cornerRadius = 6,
                hpad = 10,
                borderBox = true,
                Skel(140, 14, { valign = "center" }),
            }
        end
        return gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            children = children,
        }
    end

    --narrower than the list by the scrollbar's width, so nothing sits under it
    local content = gui.Panel{
        width = "100%-10",
        height = "auto",
        flow = "vertical",
        Section("Leveled treasures", 1),
        Section("Trinkets", 2),
        Section("Consumables", 1),
    }

    local body = gui.Panel{
        width = "100%",
        height = "100% available",
        tmargin = 4,
        flow = "vertical",
        vscroll = true,
        content,
    }

    --the list scrolls inside the card; this fades its last rows into the
    --plate so a cut-off row reads as "more below"
    local fade = gui.Panel{
        classes = { "eotwsFade", "collapsed" },
        floating = true,
        halign = "center",
        valign = "bottom",
        width = "100%",
        height = 22,
        interactable = false,
    }

    --the first row that wants equipping, for the call to action
    local todoRow = nil

    --"{n} to equip": scrolls the list to the first treasure to equip
    local ctaLabel = Text("", { "eotwsCtaText" })
    local cta = gui.Panel{
        classes = { "eotwsCta", "collapsed" },
        halign = "right",
        valign = "center",
        data = { tip = "" },
        hover = HoverTip,
        click = function(element)
            if ctx.AwayParty() ~= nil then
                audio.FireSoundEvent("UI.Error_Generic")
                return
            end
            if todoRow == nil or not todoRow.valid then
                return
            end
            audio.FireSoundEvent("Mouse.Click")
            --scroll so the row sits near the top: vscrollPosition runs 1 (top) to 0
            local offset = 0
            for _,child in ipairs(content.children) do
                if child == todoRow then
                    break
                end
                offset = offset + child.renderedHeight + 4
            end
            local range = content.renderedHeight - body.renderedHeight
            if range > 0 then
                body.vscrollPosition = 1 - math.max(0, math.min(1, (offset - 30) / range))
            end
            todoRow:PulseClass("glow")
        end,
        ctaLabel,
    }

    local function Rebuild()
        local d = ctx.data
        if ctx.state ~= "ready" or d == nil or d.treasures == nil then
            return
        end
        local t = d.treasures
        local tok = ctx.Token()
        local dead = d.stamina ~= nil and d.stamina.state == "dead"
        --equipping happens in town only (James 2026-10-10): a change in a game
        --would land on the game's copy of the Hero, not the roster's
        local ownerActs = d.mine and not dead and ctx.fallen == nil and not ctx.inGame
        local away = ctx.AwayParty()
        local awayTip = "Not while away with a party."
        todoRow = nil

        local function Row(it)
            local right = {}
            if it.noBenefit ~= nil then
                right[#right+1] = gui.Panel{
                    classes = { "eotwsWarnChip" },
                    valign = "center",
                    data = { tip = NoBenefitText(it.noBenefit, d.kitGear) },
                    hover = HoverTip,
                    click = PinTip,
                    Text("No benefit", { "eotwsWarnText" }),
                }
            end

            local todo = false
            if ownerActs and it.kind ~= "other" and it.equippable and it.kind ~= "consumable" then
                todo = not it.equipped
                --off while away, and Equip past the leveled cap: the button
                --stays, says why, and does nothing (UI.Error_Generic)
                local offTip = nil
                if away ~= nil then
                    offTip = awayTip
                elseif not it.equipped and tok ~= nil then
                    local _, reason = EotwHeroSheet.EquipSlot(tok, it.itemid)
                    if reason == "cap" then
                        offTip = string.format("%d leveled treasures are equipped. Unequip one first.", EotwHeroSheet.LEVELED_EQUIP_CAP)
                    elseif reason == "full" then
                        offTip = "No free slot for this treasure."
                    end
                end
                right[#right+1] = gui.Panel{
                    classes = { "eotwsSmallButton", cond(todo, "primary", "plain"), cond(offTip ~= nil, "off", "on") },
                    valign = "center",
                    lmargin = 6,
                    hover = function(element)
                        if offTip ~= nil then
                            gui.Tooltip(offTip)(element)
                            return
                        end
                        if tok == nil then
                            return
                        end
                        local changes = EotwHeroSheet.EquipPreview(tok, it.itemid, cond(it.equipped, it.slot, nil))
                        element.data.changes = changes
                        local lines = {}
                        for _,c in ipairs(changes) do
                            lines[#lines+1] = string.format("%s changes %s %d -> %d.",
                                cond(it.equipped, "Unequipping", "Equipping"), c.label, c.from, c.to)
                        end
                        if #lines > 0 then
                            gui.Tooltip(table.concat(lines, "\n"))(element)
                        end
                        --the stats band shows the new values in gold meanwhile
                        ctx.Preview(changes)
                    end,
                    dehover = function(element)
                        ctx.Preview(nil)
                    end,
                    data = { changes = nil },
                    click = function(element)
                        if offTip ~= nil or tok == nil then
                            audio.FireSoundEvent("UI.Error_Generic")
                            return
                        end
                        --the changed values stay gold a moment after they land
                        ctx.HoldPreview(element.data.changes)
                        if it.equipped then
                            audio.FireSoundEvent("UI.Inv_Grab")
                            EotwHeroSheet.Unequip(tok, it.slot)
                        else
                            audio.FireSoundEvent("UI.Inv_Place")
                            EotwHeroSheet.Equip(tok, it.itemid)
                        end
                        ctx.Reread()
                    end,
                    Text(cond(it.equipped, "Unequip", "Equip"), { "eotwsSmallButtonText" }),
                }
            else
                --ancestry items and anything the sheet cannot move: a plain tag
                right[#right+1] = Text(cond(it.equipped, "Equipped", "Carried"), { "eotwsTag" }, {
                    valign = "center",
                    data = { tip = cond(it.kind == "other", "Part of the Hero's ancestry.", "") },
                    hover = HoverTip,
                    click = PinTip,
                })
            end

            --name and slot in one label, so a long name ends in "..." before
            --it can push the buttons out of the row
            local nameText = it.name
            if it.body ~= nil then
                nameText = string.format("%s  <color=%s>(%s)</color>", it.name, C.MUTED, it.body)
            end
            local row = gui.Panel{
                classes = { "eotwsItem", cond(todo, "todo", "done") },
                width = "100%",
                height = "auto",
                tmargin = 4,
                flow = "horizontal",
                --the item card hangs off the name, so the buttons and the
                --No benefit chip keep their own tooltips
                Text(nameText, { "eotwsItemName", "row" }, {
                    hover = function(element)
                        element.tooltip = CardFrame(ItemCard(it, tok), false)
                    end,
                    click = function(element)
                        PinPanel(element, CardFrame(ItemCard(it, tok), true))
                    end,
                }),
                gui.Panel{
                    width = "auto",
                    height = "auto",
                    halign = "right",
                    valign = "center",
                    flow = "horizontal",
                    children = right,
                },
            }
            if todo and todoRow == nil then
                todoRow = row
            end
            return row
        end

        local function Sub(label, count)
            return gui.Panel{
                width = "100%",
                height = "auto",
                tmargin = 9,
                flow = "horizontal",
                Text(label, { "eotwsSub" }),
                Text(count, { "eotwsSubCount" }, { halign = "right" }),
            }
        end

        local children = {}
        children[#children+1] = Sub("Leveled treasures", string.format("%d of 3 carried", t.leveledCarried))
        for _,it in ipairs(t.leveled) do
            children[#children+1] = Row(it)
        end
        if #t.leveled == 0 then
            children[#children+1] = Text("None", { "eotwsNone" }, { tmargin = 4 })
        end

        children[#children+1] = Sub("Trinkets", tostring(#t.trinkets))
        for _,it in ipairs(t.trinkets) do
            children[#children+1] = Row(it)
        end
        if #t.trinkets == 0 then
            children[#children+1] = Text("None", { "eotwsNone" }, { tmargin = 4 })
        end

        local total = 0
        local chips = {}
        for _,it in ipairs(t.consumables) do
            total = total + (it.quantity or 1)
            local parts = { Text(it.name, { "eotwsItemName" }) }
            if (it.quantity or 1) > 1 then
                parts[2] = Text(string.format("x%d", it.quantity), { "eotwsQty" }, { lmargin = 4 })
            end
            chips[#chips+1] = gui.Panel{
                classes = { "eotwsItem", "chip" },
                width = "auto",
                height = "auto",
                rmargin = 5,
                tmargin = 5,
                flow = "horizontal",
                hover = function(element)
                    element.tooltip = CardFrame(ItemCard(it, tok), false)
                end,
                click = function(element)
                    PinPanel(element, CardFrame(ItemCard(it, tok), true))
                end,
                children = parts,
            }
        end
        children[#children+1] = Sub("Consumables", tostring(total))
        if #chips > 0 then
            children[#children+1] = gui.Panel{
                width = "100%",
                height = "auto",
                flow = "horizontal",
                wrap = true,
                children = chips,
            }
        else
            children[#children+1] = Text("None", { "eotwsNone" }, { tmargin = 4 })
        end
        --room under the last row so the fade does not cover it at the bottom
        children[#children+1] = gui.Panel{ width = 1, height = 18 }
        content.children = children

        --"{n} to equip": your own Hero's unequipped treasure; jumps to it
        local n = 0
        if ownerActs then
            n = t.toEquip or 0
        end
        cta:SetClass("collapsed", n == 0)
        cta:SetClass("off", away ~= nil)
        ctaLabel.text = string.format("%d to equip", n)
        cta.data.tip = cond(away ~= nil, awayTip, "")

        --the fade only belongs when the list runs past the bottom; check once
        --the new rows have been laid out
        fade:SetClass("collapsed", true)
        dmhub.Schedule(0.05, function()
            if mod.unloaded or not body.valid then
                return
            end
            fade:SetClass("collapsed", content.renderedHeight <= body.renderedHeight + 1)
        end)
    end

    return Block(ctx, {
        width = LEFT_WIDTH,
        height = "100% available",
        tmargin = LEFT_GAP,
        flow = "vertical",
        eotwsState = Rebuild,
        eotwsData = Rebuild,
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            Text("Treasures", { "eotwsHeader" }),
            cta,
        },
        gui.Panel{
            width = "100%",
            height = "100% available",
            flow = "none",
            body,
            fade,
        },
    })
end

--- top bar (main column) ---------------------------------------------------------

--How often the top bar re-asks whether the player is needed (in a game).
--Triggers expire by time without any write, so this is a poll.
local SIGNAL_POLL_SECONDS = 0.5

--Has this Hero a trigger waiting to be used (non-hostile, not dismissed)?
--The hero card's test, plus the dismissed check GetAvailableTriggers can skip.
---@param p creature
---@return boolean
local function HasTrigger(p)
    for _,t in pairs(p:GetAvailableTriggers(true) or {}) do
        if not t.hostile and not t.dismissed and not t.triggered then
            return true
        end
    end
    return false
end

--Has this Hero an end-of-turn saving throw waiting (the card is up, or it was
--accepted and is still rolling)?
---@param p creature
---@return boolean
local function HasSave(p)
    for _,t in pairs(p:GetAvailableTriggers(true) or {}) do
        local inv = t.invocation
        if not t.dismissed and inv ~= nil and inv ~= false and inv:try_get("standardAbility") == "End Turn Saving Throw" then
            return true
        end
    end
    for _,e in pairs(p:try_get("pendingAIActivityReactions", {})) do
        if type(e) == "table" and e.activityId == "end-turn-save" and e.state ~= "completed" then
            return true
        end
    end
    return false
end

--Is the game waiting on this Hero for a roll: a roll request not yet done,
--or the montage stage's test in this Hero's hands?
---@param charid string
---@return boolean
local function HasRoll(charid)
    for _,req in pairs(dmhub.GetPlayerActionRequests() or {}) do
        local info = req.info
        if info ~= nil and info.typeName == "RollRequest" and info.tokens ~= nil then
            local entry = info.tokens[charid]
            if entry ~= nil and entry.status ~= "complete" then
                return true
            end
        end
    end
    local montage = rawget(_G, "EncounterMontage")
    if montage ~= nil then
        local turn = nil
        pcall(function() turn = montage.GetState().turn end)
        if type(turn) == "table" then
            if turn.status == "rolling" and turn.heroid == charid then
                return true
            elseif turn.status == "assisting" and turn.assist ~= nil and turn.assist.heroid == charid then
                return true
            elseif turn.status == "pardon" and turn.pardon ~= nil and turn.pardon.heroid == charid then
                return true
            end
        end
    end
    return false
end

--Where the encounter's story is (beat, montage round, narrative section): a
--change while the sheet is open means the story moved on.
---@return string
local function StorySignature()
    local sig = ""
    pcall(function()
        local doc = EncounterMontage.GetDoc().data
        local m = EncounterMontage.GetState()
        local n = rawget(_G, "EncounterNarrative") ~= nil and EncounterNarrative.GetState() or nil
        sig = string.format("%s|%s:%s|%s:%s", tostring(doc.beat),
            tostring(m and m.beatIndex), tostring(m and m.round),
            tostring(n and n.beatIndex), tostring(n and n.sectionIndex))
    end)
    return sig
end

--Can the Heroes' side claim the next turn, with one of this player's Heroes
--able to take it?
---@param charid string
---@return boolean
local function CanAct(charid)
    local result = false
    pcall(function()
        local q = dmhub.initiativeQueue
        if q == nil or q.hidden or not q:ChoosingTurn() or not q:IsPlayersTurn() then
            return
        end
        local tok = dmhub.GetCharacterById(charid)
        local id = tok ~= nil and InitiativeQueue.GetInitiativeId(tok) or nil
        result = id ~= nil and InitiativeQueue.CanClaimTurn(id, { canControlInitiative = false })
    end)
    return result
end

--Why the player is needed right now, as the top bar's line (T9-T12, N7), or
--nil. Checked across this player's Heroes in the encounter, the shown Hero
--first; the story only counts once it moved since the sheet opened.
---@param ctx table
---@return string|nil
local function NeededLine(ctx)
    if not ctx.inGame or ctx.fallen ~= nil then
        return nil
    end
    --for testing the bar's look: set EotwHeroSheet.debugNeededLine to a line
    if type(EotwHeroSheet.debugNeededLine) == "string" then
        return EotwHeroSheet.debugNeededLine
    end
    local mine = {}
    for _,entry in ipairs(EotwHeroCard.CollectHeroes()) do
        if entry.mine then
            if entry.charid == ctx.charid then
                table.insert(mine, 1, entry)
            else
                mine[#mine+1] = entry
            end
        end
    end
    for _,entry in ipairs(mine) do
        local tok = dmhub.GetCharacterById(entry.charid)
        local p = tok ~= nil and tok.properties or nil
        if p ~= nil then
            local trigger, save = false, false
            pcall(function() trigger = HasTrigger(p) end)
            pcall(function() save = HasSave(p) end)
            if trigger then
                return string.format("%s has a trigger waiting", entry.name)
            elseif save then
                return string.format("%s has a save to make", entry.name)
            elseif HasRoll(entry.charid) then
                return string.format("%s has a roll to make", entry.name)
            end
        end
    end
    if ctx.storySignature ~= nil and StorySignature() ~= ctx.storySignature then
        return "The story continues"
    end
    for _,entry in ipairs(mine) do
        if CanAct(entry.charid) then
            return "The Heroes can act"
        end
    end
    return nil
end

--The Close button: Close [Esc]; ink on gold on the you're-needed bar.
---@param ctx table
---@param onGold? boolean
---@return Panel
local function CloseButton(ctx, onGold)
    local gold = cond(onGold, "onGold", "plain")
    return gui.Panel{
        classes = { "eotwsButton", "eotwsClose", gold },
        lmargin = 10,
        width = "auto",
        height = 38,
        hpad = 14,
        borderBox = true,
        halign = "right",
        valign = "center",
        flow = "horizontal",
        click = function()
            audio.FireSoundEvent("UI.WindowClose")
            ctx.Close()
        end,
        Text("Close", { "eotwsCloseText", gold }, { valign = "center" }),
        gui.Panel{
            classes = { "eotwsKbd", gold },
            Text("Esc", { "eotwsKbdText", gold }),
        },
    }
end

--One Hero's thumbnail in the switcher: their art, blue edge for your own in
--a shared list, cream outline for the Hero on show; click to switch.
---@param ctx table
---@param charid string
---@param mineEdge boolean
---@param own boolean the player's own Hero (tooltip "{Hero}, Level {n}")
---@return Panel|nil
local function Thumb(ctx, charid, mineEdge, own)
    local tok = dmhub.GetCharacterById(charid)
    if tok == nil then
        return nil
    end
    local name = EotwHeroCard.HeroDisplayName(tok)
    local tip = name
    local owner = nil
    pcall(function() owner = tok.ownerId end)
    if own then
        local level = nil
        pcall(function() level = tok.properties:CharacterLevel() end)
        tip = string.format("%s, Level %s", name, tostring(level or 1))
    elseif owner ~= nil and owner ~= "" then
        local player = nil
        pcall(function() player = dmhub.GetDisplayName(owner) end)
        if player ~= nil and player ~= "" then
            tip = string.format("%s, %s's Hero", name, player)
        end
    end
    local thumb = gui.Panel{
        classes = { "eotwsThumb", cond(mineEdge, "mine", "theirs"), cond(charid == ctx.charid, "current", "other") },
        data = { tip = tip },
        hover = HoverTip,
        click = function()
            if charid == ctx.charid then
                return
            end
            audio.FireSoundEvent("Mouse.Click")
            EotwHeroSheet.Show{ charid = charid, context = ctx.context }
        end,
    }
    EotwHeroCard.ApplyPortrait(thumb, tok, 40 / 56)
    return thumb
end

--A button in the owner controls; off (with a lock and the reason) while the
--Hero is away with a party.
---@param label string
---@param tip string|nil
---@param offTip string|nil
---@param action function
---@return Panel
local function OwnerButton(label, tip, offTip, action)
    local children = {}
    if offTip ~= nil then
        children[1] = gui.Panel{ classes = { "eotwsLock" } }
    end
    children[#children+1] = Text(label, { "eotwsButtonText" }, { valign = "center" })
    return gui.Panel{
        classes = { "eotwsButton", cond(offTip ~= nil, "off", "on") },
        width = "auto",
        height = 38,
        hpad = 14,
        lmargin = 10,
        borderBox = true,
        valign = "center",
        flow = "horizontal",
        data = { tip = offTip or tip },
        hover = HoverTip,
        click = function()
            if offTip ~= nil then
                audio.FireSoundEvent("UI.Error_Generic")
                return
            end
            audio.FireSoundEvent("Mouse.Click")
            action()
        end,
        children = children,
    }
end

--The top bar's normal content: the switcher, state chips, owner controls or
--the owner chip, and Close. A fallen Hero gets only "The Graveyard" + Close.
---@param ctx table
---@return Panel[]
local function TopBarContent(ctx)
    if ctx.fallen ~= nil then
        return {
            Text("The Graveyard", { "eotwsSwitchLabel" }, { valign = "center" }),
            CloseButton(ctx),
        }
    end

    local d = ctx.data or {}
    local mine = d.mine == true
    local children = {}

    --the switcher: your roster in town, this encounter's Heroes in a game
    --(yours first); a teammate's Hero in town shows "Your party"
    local label
    local ours, theirs = {}, {}
    if ctx.inGame then
        label = "This encounter"
        for _,entry in ipairs(EotwHeroCard.CollectHeroes()) do
            if entry.mine then
                ours[#ours+1] = Thumb(ctx, entry.charid, true, true)
            else
                theirs[#theirs+1] = Thumb(ctx, entry.charid, false, false)
            end
        end
    elseif mine and rawget(_G, "EotwRoster") ~= nil then
        label = "Your roster"
        for _,hero in ipairs(EotwRoster.GetHeroes() or {}) do
            ours[#ours+1] = Thumb(ctx, hero.heroid, false, true)
        end
    else
        label = "Your party"
        theirs[1] = Thumb(ctx, ctx.charid, false, false)
    end
    children[#children+1] = Text(label, { "eotwsSwitchLabel" }, { valign = "center", rmargin = 4 })
    for _,t in ipairs(ours) do
        children[#children+1] = t
    end
    if #ours > 0 and #theirs > 0 then
        children[#children+1] = gui.Panel{ classes = { "eotwsSwitchSep" } }
    end
    for _,t in ipairs(theirs) do
        children[#children+1] = t
    end

    --right-hand side, packed against Close
    local right = {}
    local away = ctx.AwayParty()
    if away ~= nil then
        right[#right+1] = gui.Panel{
            classes = { "eotwsStateChip" },
            flow = "vertical",
            Text(string.format("Away: %s", away), { "eotwsStateChipText" }),
            Text("Changes are off until the party ends.", { "eotwsStateChipSmall" }),
        }
    end
    local practice = false
    if ctx.inGame and rawget(_G, "EncounterOfTheWeekGame") ~= nil then
        pcall(function() practice = EncounterOfTheWeekGame.IsPracticeGame() end)
    end
    if practice then
        right[#right+1] = gui.Panel{
            classes = { "eotwsStateChip" },
            Text("Danger Rooms: practice only", { "eotwsStateChipText" }),
        }
    end

    local dead = d.stamina ~= nil and d.stamina.state == "dead"
    if mine and not dead and not ctx.inGame and ctx.state == "ready" then
        --the town is where the Hero changes: appearance always, the full
        --builder only until the Hero's first encounter is won
        local offTip = cond(away ~= nil, "Not while away with a party.", nil)
        local heroid = ctx.charid
        right[#right+1] = OwnerButton("Change Appearance", nil, offTip, function()
            local host = ctx.host
            local tok = ctx.Token()
            ctx.Close()
            if tok ~= nil and host ~= nil and host.valid then
                local function Save()
                    if rawget(_G, "EotwRoster") ~= nil then
                        EotwRoster.PushHero(heroid)
                    end
                end
                EotwBuilder.Open{
                    host = host,
                    token = tok,
                    title = "Change Appearance",
                    step = "appearance",
                    only = "appearance",
                    onFinish = Save,
                    onClose = Save,
                }
            end
        end)
        local hero = rawget(_G, "EotwRoster") ~= nil and EotwRoster.FindHero(heroid) or nil
        if hero ~= nil and #(hero.completed or {}) == 0 then
            right[#right+1] = OwnerButton("Edit in Builder", "Change any choice until this Hero wins an encounter.", offTip, function()
                local host = ctx.host
                ctx.Close()
                EotwRoster.EditHero(heroid, host)
            end)
        end
    elseif not mine and ctx.state == "ready" and d.ownerName ~= nil then
        right[#right+1] = gui.Panel{
            classes = { "eotwsOwnerChip" },
            Text(string.format("%s's Hero", d.ownerName), { "eotwsOwnerChipText" }),
        }
    end
    right[#right+1] = CloseButton(ctx)

    children[#children+1] = gui.Panel{
        width = "auto",
        height = "100%",
        halign = "right",
        flow = "horizontal",
        children = right,
    }
    return children
end

---@param ctx table
---@return Panel
local function TopBarRegion(ctx)
    local thumbs = {}
    for i = 1, 6 do
        thumbs[#thumbs+1] = Skel(40, 56, { lmargin = cond(i == 1, 10, 8), cornerRadius = 6, valign = "center" })
    end

    --what the bar shows now, so it is rebuilt only when that changes
    local shownSignature = nil

    local function Rebuild(element)
        if ctx.state ~= "ready" then
            return
        end
        local needed = NeededLine(ctx)
        local away = ctx.AwayParty()
        local sig = string.format("%s|%s|%s", tostring(needed), tostring(away), tostring(ctx.data ~= nil and ctx.data.mine))
        if sig == shownSignature then
            return
        end
        shownSignature = sig
        element:SetClass("needed", needed ~= nil)
        if needed ~= nil then
            --the bar turns gold in place: nothing below it moves
            element.children = {
                Text(needed, { "eotwsNeededText" }, { valign = "center", width = "100% available" }),
                CloseButton(ctx, true),
            }
        else
            element.children = TopBarContent(ctx)
        end
    end

    return gui.Panel{
        classes = { "eotwsTopBar" },
        width = "100%",
        height = TOPBAR_HEIGHT,
        hpad = 12,
        borderBox = true,
        flow = "horizontal",
        Text(cond(ctx.inGame, "This encounter", "Your roster"), { "eotwsSwitchLabel" }, { valign = "center" }),
        gui.Panel{
            width = "auto",
            height = "100%",
            flow = "horizontal",
            valign = "center",
            children = thumbs,
        },
        CloseButton(ctx),

        eotwsState = function(element, state)
            if state == "ready" then
                --the story as it stands when the sheet opens; a change after
                --this is "The story continues"
                if ctx.inGame and ctx.storySignature == nil then
                    ctx.storySignature = StorySignature()
                end
                shownSignature = nil
                Rebuild(element)
            end
        end,
        eotwsData = function(element)
            shownSignature = nil
            Rebuild(element)
        end,
        thinkTime = SIGNAL_POLL_SECONDS,
        think = function(element)
            Rebuild(element)
        end,
    }
end

--- stats band (main column) ------------------------------------------------------

--A stat's number, which turns gold while hovering an Equip / Unequip button
--previews a new value for it (`key` matches EquipPreview's labels), and holds
--gold for a moment after the change lands.
---@param key string
---@param text string
---@param classes string[]
---@param format? fun(n: number): string how a previewed number reads
---@return Panel
local function StatValue(key, text, classes, format)
    return Text(text, classes, {
        data = { key = key, text = text },
        eotwsPreview = function(element, changes)
            for _,c in ipairs(changes or {}) do
                if c.label == element.data.key then
                    element.text = (format or tostring)(c.to)
                    element:SetClass("preview", true)
                    return
                end
            end
            element.text = element.data.text
            element:SetClass("preview", false)
        end,
    })
end

--The skeleton the band shows while the Hero loads.
---@return Panel[]
local function StatsSkeleton()
    local tiles = {}
    for i,name in ipairs(CHARACTERISTICS) do
        tiles[#tiles+1] = gui.Panel{
            classes = { "eotwsTile" },
            lmargin = cond(i == 1, 0, 7),
            Text(name, { "eotwsTileLabel" }),
            Skel(100, 30, { halign = "center", tmargin = 4 }),
        }
    end
    local function Pair(label, first)
        return gui.Panel{
            width = "auto",
            height = 24,
            lmargin = cond(first, 0, 26),
            flow = "horizontal",
            Text(label, { "eotwsStatLabel" }, { valign = "center" }),
            Skel(14, 22, { lmargin = 8, valign = "center" }),
        }
    end
    local function Line(children, tmargin)
        return gui.Panel{
            width = "auto",
            height = "auto",
            halign = "center",
            tmargin = tmargin,
            flow = "horizontal",
            children = children,
        }
    end
    local function Words(label, width, bars, first)
        local row = {}
        for _,w in ipairs(bars) do
            row[#row+1] = Skel(w, 20, { rmargin = 18, bmargin = 4 })
        end
        return gui.Panel{
            classes = { "eotwsWordsCol", cond(first, "first", "rest") },
            width = width,
            Text(label, { "eotwsHeader" }),
            gui.Panel{
                width = "100%",
                height = "auto",
                tmargin = 6,
                flow = "horizontal",
                wrap = true,
                children = row,
            },
        }
    end
    return {
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            gui.Panel{
                width = "55%",
                height = "auto",
                flow = "vertical",
                Text("Characteristics", { "eotwsHeader" }),
                gui.Panel{
                    width = "100%",
                    height = "auto",
                    tmargin = 8,
                    flow = "horizontal",
                    children = tiles,
                },
            },
            gui.Panel{
                classes = { "eotwsLines" },
                Line({ Pair("Size", true), Pair("Speed"), Pair("Disengage"), Pair("Stability") }, 0),
                Line({ Pair("Potency", true), Pair("Weak"), Pair("Average"), Pair("Strong") }, 7),
                Line({ Pair("Wealth", true), Pair("Renown") }, 7),
            },
        },
        Hairline(),
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            Words("Skills", "46%", { 160, 200, 140, 170, 84 }, true),
            Words("Languages", "17%", { 120 }),
            Words("Immunities", "21%", { 36 }),
            Words("Weaknesses", "16%", { 36 }),
        },
    }
end

--The band filled from the Hero's data: characteristic tiles; centred lines
--for Size, Speed (with movement types, "Speed 6 (fly)"), Disengage,
--Stability, the Potency pill, Wealth and Renown; then the words row.
---@param d table EotwHeroSheet.Data
---@return Panel[]
local function StatsContent(d)
    local tiles = {}
    for i,c in ipairs(d.characteristics or {}) do
        tiles[#tiles+1] = gui.Panel{
            classes = { "eotwsTile" },
            lmargin = cond(i == 1, 0, 7),
            data = { tip = SourcesTip(c) },
            hover = HoverTip,
            click = PinTip,
            Text(c.name, { "eotwsTileLabel" }),
            StatValue(c.name, SignedText(c.value), { "eotwsTileValue" }, SignedText),
        }
    end

    local stats = d.stats or {}
    --one "LABEL value" pair on a centred line; hover shows its sources
    local function Pair(label, key, value, sources, first, extra)
        local children = {
            Text(label, { "eotwsStatLabel" }, { valign = "center" }),
            StatValue(key, tostring(value), { "eotwsStatValue" }),
        }
        if extra ~= nil then
            children[#children+1] = extra
        end
        return gui.Panel{
            width = "auto",
            height = "auto",
            lmargin = cond(first, 0, 26),
            flow = "horizontal",
            data = { tip = SourcesTip(sources) },
            hover = HoverTip,
            click = PinTip,
            children = children,
        }
    end
    local function Line(children, args)
        local fields = {
            width = "auto",
            height = "auto",
            halign = "center",
            flow = "horizontal",
            children = children,
        }
        for k,v in pairs(args or {}) do
            fields[k] = v
        end
        return gui.Panel(fields)
    end

    local speedExtra = nil
    if #(d.movement or {}) > 0 then
        speedExtra = Text(string.format("(%s)", table.concat(d.movement, ", ")), { "eotwsMovement" }, { valign = "center", lmargin = 5 })
    end
    local function Value(s)
        return s ~= nil and s.value or ""
    end
    local body = Line({
        Pair("Size", "Size", Value(stats.size), stats.size, true),
        Pair("Speed", "Speed", Value(stats.speed), stats.speed, false, speedExtra),
        Pair("Disengage", "Disengage", Value(stats.disengage), stats.disengage),
        Pair("Stability", "Stability", Value(stats.stability), stats.stability),
    })

    local potency = d.potency or {}
    local function Tier(label, value)
        return gui.Panel{
            width = "auto",
            height = "auto",
            lmargin = 20,
            flow = "horizontal",
            Text(label, { "eotwsTierLabel" }, { valign = "center" }),
            Text(tostring(value or ""), { "eotwsStatValue" }, { lmargin = 8 }),
        }
    end
    local potencyLine = Line({
        Text("Potency", { "eotwsStatLabel" }, { valign = "center" }),
        Tier("Weak", potency.weak),
        Tier("Average", potency.average),
        Tier("Strong", potency.strong),
    }, { classes = { "eotwsPotency" }, tmargin = 7 })

    --Wealth and Renown: labels only, no tooltip (round 13)
    local standing = Line({
        Text("Wealth", { "eotwsStatLabel" }, { valign = "center" }),
        Text(tostring(d.wealth or 0), { "eotwsStatValue", "small" }, { lmargin = 8 }),
        Text("Renown", { "eotwsStatLabel" }, { valign = "center", lmargin = 26 }),
        Text(tostring(d.renown or 0), { "eotwsStatValue", "small" }, { lmargin = 8 }),
    }, { tmargin = 7 })

    --the words row: skills by group, then plain lists ("None" when empty)
    local function List(items)
        if items == nil or #items == 0 then
            return Text("None", { "eotwsNone" })
        end
        return Text(table.concat(items, ", "), { "eotwsWords" }, { width = "100%" })
    end
    local skillUnits = {}
    for _,g in ipairs(d.skills or {}) do
        --a group and its skills stay together; the row wraps between groups
        skillUnits[#skillUnits+1] = gui.Panel{
            width = "auto",
            height = "auto",
            rmargin = 18,
            flow = "horizontal",
            Text(g.name, { "eotwsSkillGroup" }, { valign = "center" }),
            Text(table.concat(g.skills, ", "), { "eotwsWords" }, { lmargin = 5 }),
        }
    end
    local skills
    if #skillUnits == 0 then
        skills = Text("None", { "eotwsNone" })
    else
        skills = gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            wrap = true,
            children = skillUnits,
        }
    end
    local function Words(label, width, content, first)
        return gui.Panel{
            classes = { "eotwsWordsCol", cond(first, "first", "rest") },
            width = width,
            Text(label, { "eotwsHeader" }, { bmargin = 5 }),
            content,
        }
    end

    return {
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            gui.Panel{
                width = "55%",
                height = "auto",
                flow = "vertical",
                Text("Characteristics", { "eotwsHeader" }),
                gui.Panel{
                    width = "100%",
                    height = "auto",
                    tmargin = 8,
                    flow = "horizontal",
                    children = tiles,
                },
            },
            gui.Panel{
                classes = { "eotwsLines" },
                body,
                potencyLine,
                standing,
            },
        },
        Hairline(),
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            Words("Skills", "46%", skills, true),
            Words("Languages", "17%", List(d.languages)),
            Words("Immunities", "21%", List(d.immunities)),
            Words("Weaknesses", "16%", List(d.weaknesses)),
        },
    }
end

---@param ctx table
---@return Panel
local function StatsRegion(ctx)
    local function Fill(element)
        if ctx.state == "ready" and ctx.data ~= nil then
            element.children = StatsContent(ctx.data)
            local held = ctx.HeldPreview()
            if held ~= nil then
                element:FireEventTree("eotwsPreview", held)
            end
        end
    end
    return Block(ctx, {
        width = "100%",
        height = "auto",
        tmargin = MAIN_GAP,
        hpad = 18,
        vpad = 12,
        flow = "vertical",
        children = StatsSkeleton(),
        eotwsState = Fill,
        eotwsData = Fill,
    })
end

--- abilities and features (main column) ------------------------------------------

--Which groups and sections the player has folded, remembered on this machine
--for every sheet ("ab:standard" = the Standard actions group, folded to start).
local g_collapsedSetting = setting{
    id = "eotwsheet.collapsed",
    description = "EotW hero sheet folded groups",
    storage = "preference",
    default = "ab:standard",
}

---@param key string
---@return boolean
local function IsCollapsed(key)
    local value = g_collapsedSetting:Get() or ""
    for part in string.gmatch(value, "[^,]+") do
        if part == key then
            return true
        end
    end
    return false
end

---@param key string
---@param collapsed boolean
local function SetCollapsed(key, collapsed)
    local parts = {}
    for part in string.gmatch(g_collapsedSetting:Get() or "", "[^,]+") do
        if part ~= key then
            parts[#parts+1] = part
        end
    end
    if collapsed then
        parts[#parts+1] = key
    end
    g_collapsedSetting:Set(table.concat(parts, ","))
end

--A collapsible group: a header row (caret, name, count, optional note) over
--a body. The header click folds it and remembers that.
---@param key string the remembered id ("ab:main", "ft:class")
---@param label string
---@param count number
---@param note string|nil
---@param body Panel
---@return Panel
local function Group(key, label, count, note, body)
    local collapsed = IsCollapsed(key)
    body:SetClass("collapsed", collapsed)
    local caret = gui.Panel{ classes = { "eotwsCaret", cond(collapsed, "closed", "open") } }
    local header = gui.Panel{
        classes = { "eotwsGroupHead" },
        click = function(element)
            audio.FireSoundEvent("Mouse.Click")
            collapsed = not collapsed
            SetCollapsed(key, collapsed)
            body:SetClass("collapsed", collapsed)
            caret:SetClass("closed", collapsed)
            caret:SetClass("open", not collapsed)
        end,
        caret,
        Text(label, { "eotwsGroupLabel" }, { valign = "center" }),
        Text(tostring(count), { "eotwsGroupCount" }, { valign = "center", lmargin = 8 }),
    }
    if note ~= nil then
        header:AddChild(Text(note, { "eotwsGroupNote" }, { valign = "center", halign = "right" }))
    end
    return gui.Panel{
        width = "100%",
        height = "auto",
        tmargin = 10,
        flow = "vertical",
        header,
        body,
    }
end

--An ability's keywords as a comma list (the row's grey middle).
---@param ability any
---@return string
local function KeywordText(ability)
    local list = {}
    pcall(function()
        for kw,on in pairs(ability:try_get("keywords", {})) do
            if on then
                list[#list+1] = kw
            end
        end
    end)
    table.sort(list)
    return table.concat(list, ", ")
end

--The codex's own card for an ability row: the ability card, or the trigger
--drawer's card for a triggered action.
---@param item table a d.abilities item
---@param tok CharacterToken|nil
---@return Panel|nil
local function AbilityCardContent(item, tok)
    local card = nil
    if item.ability ~= nil then
        pcall(function() card = CreateAbilityTooltip(item.ability, { token = tok, width = 480 }) end)
    elseif item.trigger ~= nil then
        pcall(function() card = item.trigger:Render{ token = tok } end)
    end
    return card
end

--One ability row (A4): name, keywords, then the action and cost tags. Hover
--shows the codex card; a click keeps it open.
---@param item table
---@param tok CharacterToken|nil
---@param compact boolean free strikes and standard actions: two to a row, no keywords
---@return Panel
local function AbilityRow(item, tok, compact)
    local children = { Text(item.name, { "eotwsAbilityName", cond(compact, "compact", "full") }, { valign = "center" }) }
    if not compact and item.ability ~= nil then
        children[#children+1] = Text(KeywordText(item.ability), { "eotwsAbilityKeywords" }, { valign = "center", lmargin = 10 })
    end
    local tags = { Text(item.actionTag or "", { "eotwsAbilityTag" }, { valign = "center" }) }
    if item.costTag ~= nil then
        tags[#tags+1] = Text(string.format("%s %s", MIDDOT, item.costTag), { "eotwsAbilityTag", "cost" }, { valign = "center", lmargin = 6 })
    end
    children[#children+1] = gui.Panel{
        width = "auto",
        height = "auto",
        halign = "right",
        valign = "center",
        flow = "horizontal",
        children = tags,
    }
    return gui.Panel{
        classes = { "eotwsAbilityRow", cond(compact, "compact", "full") },
        hover = function(element)
            local card = AbilityCardContent(item, tok)
            if card ~= nil then
                element.tooltip = CardFrame(card, false)
            end
        end,
        click = function(element)
            local card = AbilityCardContent(item, tok)
            if card ~= nil then
                PinPanel(element, CardFrame(card, true))
            end
        end,
        children = children,
    }
end

--The Abilities column's content: one group per kind of action (A2), the
--Standard actions noted as every Hero's (A3).
---@param d table EotwHeroSheet.Data
---@param tok CharacterToken|nil
---@return Panel[]
local function AbilitiesContent(d, tok)
    local groups = {}
    for _,g in ipairs(d.abilities or {}) do
        local compact = g.id == "freestrike" or g.id == "standard"
        local rows = {}
        if compact then
            --two to a row
            for i = 1, #g.items, 2 do
                local pair = { AbilityRow(g.items[i], tok, true) }
                if g.items[i + 1] ~= nil then
                    pair[2] = AbilityRow(g.items[i + 1], tok, true)
                end
                rows[#rows+1] = gui.Panel{
                    width = "100%",
                    height = "auto",
                    tmargin = 6,
                    flow = "horizontal",
                    children = pair,
                }
            end
        else
            for _,item in ipairs(g.items) do
                rows[#rows+1] = AbilityRow(item, tok, false)
            end
        end
        local body = gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            children = rows,
        }
        groups[#groups+1] = Group("ab:" .. g.id, g.name, #g.items,
            cond(g.id == "standard", "Every Hero can do these", nil), body)
    end
    return groups
end

--One feature card (F5, F6): name and pillar tags, "Chosen for {choice}", the
--text folded behind Show more when long.
---@param item table a d.features item
---@return Panel
local function FeatureCard(item)
    local head = { Text(item.name or "", { "eotwsFeatureName" }, { valign = "center" }) }
    local tagPanels = {}
    for _,p in ipairs(item.pillars or {}) do
        tagPanels[#tagPanels+1] = gui.Panel{
            classes = { "eotwsPillTag" },
            Text(p, { "eotwsPillTagText" }),
        }
    end
    if #tagPanels > 0 then
        head[#head+1] = gui.Panel{
            width = "auto",
            height = "auto",
            halign = "right",
            valign = "center",
            flow = "horizontal",
            children = tagPanels,
        }
    end
    local children = {
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "horizontal",
            children = head,
        },
    }
    if item.chosenFor ~= nil then
        children[#children+1] = Text(string.format("Chosen for %s", item.chosenFor), { "eotwsFeatureChosen" })
    end
    local text = item.text or ""
    if text ~= "" then
        local long = #text > FEATURE_FOLD_CHARS
        local folded = long
        local function Short()
            local cut = string.sub(text, 1, FEATURE_FOLD_CHARS)
            cut = string.match(cut, "^(.*)%s") or cut
            return cut .. "..."
        end
        local desc = Text(cond(long, Short(), text), { "eotwsFeatureText" })
        children[#children+1] = desc
        if long then
            local toggle
            toggle = Text("Show more", { "eotwsShowMore" }, {
                click = function()
                    audio.FireSoundEvent("Mouse.Click")
                    folded = not folded
                    desc.text = cond(folded, Short(), text)
                    toggle.text = cond(folded, "Show more", "Show less")
                end,
            })
            children[#children+1] = toggle
        end
    end
    return gui.Panel{
        classes = { "eotwsFeatureCard" },
        children = children,
    }
end

---@param ctx table
---@return Panel
local function ListsRegion(ctx)
    local Underlined = function(children)
        return gui.Panel{
            classes = { "eotwsListHead" },
            children = children,
        }
    end

    local abilitySkeleton = {}
    for _,rows in ipairs({ 3, 2, 4 }) do
        abilitySkeleton[#abilitySkeleton+1] = Skel(116, 12, { tmargin = 14 })
        for r = 1, rows do
            abilitySkeleton[#abilitySkeleton+1] = gui.Panel{
                classes = { "eotwsRow" },
                width = "100%-6",
                height = 36,
                tmargin = 6,
                hpad = 12,
                borderBox = true,
                Skel(({ 186, 128, 214, 157 })[r], 18, { valign = "center" }),
            }
        end
    end

    local featureSkeleton = {}
    for _ = 1, 3 do
        featureSkeleton[#featureSkeleton+1] = gui.Panel{
            classes = { "eotwsRow" },
            width = "100%-6",
            height = 86,
            tmargin = 8,
            hpad = 14,
            vpad = 10,
            borderBox = true,
            flow = "vertical",
            Skel(126, 18),
            Skel("100%", 12, { tmargin = 10 }),
            Skel("70%", 12, { tmargin = 8 }),
        }
    end

    --the features' filters: pillar chips (any one matches) and the text box
    local filters = { pillars = {}, text = "" }
    local featureCount = Text("", { "eotwsListCount" }, { valign = "center", lmargin = 8 })

    local abilityBody = gui.Panel{
        width = "100%",
        height = "100% available",
        tmargin = 2,
        flow = "vertical",
        vscroll = true,
        gui.Panel{
            width = "100%-10",
            height = "auto",
            flow = "vertical",
            children = abilitySkeleton,
        },
    }
    local featureList = gui.Panel{
        width = "100%-10",
        height = "auto",
        flow = "vertical",
        children = featureSkeleton,
    }
    local featureBody = gui.Panel{
        width = "100%",
        height = "100% available",
        tmargin = 2,
        flow = "vertical",
        vscroll = true,
        featureList,
    }

    local function FillFeatures()
        local d = ctx.data
        if ctx.state ~= "ready" or d == nil or d.features == nil then
            return
        end
        local query = string.lower(filters.text or "")
        local anyPillar = next(filters.pillars) ~= nil
        local shown = 0
        local sections = {}
        for _,s in ipairs(d.features.sections) do
            local cards = {}
            for _,item in ipairs(s.items) do
                local ok = true
                if anyPillar then
                    ok = false
                    for _,p in ipairs(item.pillars or {}) do
                        if filters.pillars[p] then
                            ok = true
                        end
                    end
                end
                if ok and query ~= "" then
                    local hay = string.lower((item.name or "") .. " " .. (item.text or ""))
                    ok = string.find(hay, query, 1, true) ~= nil
                end
                if ok then
                    cards[#cards+1] = FeatureCard(item)
                end
            end
            if #cards > 0 then
                shown = shown + #cards
                sections[#sections+1] = Group("ft:" .. s.id, s.name, #cards, nil, gui.Panel{
                    width = "100%",
                    height = "auto",
                    flow = "vertical",
                    children = cards,
                })
            end
        end
        if #sections == 0 then
            sections[1] = Text("No features match. Clear the filters to see them all.", { "eotwsEmpty" })
        end
        featureList.children = sections
        local total = d.features.total or 0
        featureCount.text = cond(shown == total, tostring(total), string.format("%d of %d", shown, total))
    end

    local chips = {}
    for _,pillar in ipairs(PILLARS) do
        chips[#chips+1] = gui.Panel{
            classes = { "eotwsChip", "off" },
            width = "auto",
            height = 28,
            hpad = 10,
            lmargin = 8,
            borderBox = true,
            valign = "center",
            click = function(element)
                audio.FireSoundEvent("Mouse.Click")
                local on = not filters.pillars[pillar]
                filters.pillars[pillar] = on or nil
                element:SetClass("on", on)
                element:SetClass("off", not on)
                FillFeatures()
            end,
            Text(pillar, { "eotwsChipText" }, { valign = "center" }),
        }
    end
    chips[#chips+1] = gui.Input{
        classes = { "eotwsFilter" },
        placeholderText = "Filter features",
        text = "",
        editlag = 0.2,
        edit = function(element)
            filters.text = element.text or ""
            FillFeatures()
        end,
        change = function(element)
            filters.text = element.text or ""
            FillFeatures()
        end,
    }

    local featureHead = { Text("Features", { "eotwsHeader" }, { valign = "center" }), featureCount }
    for _,chip in ipairs(chips) do
        featureHead[#featureHead+1] = chip
    end

    local function Fill()
        if ctx.state ~= "ready" or ctx.data == nil then
            return
        end
        abilityBody.children = {
            gui.Panel{
                width = "100%-10",
                height = "auto",
                flow = "vertical",
                children = AbilitiesContent(ctx.data, ctx.Token()),
            },
        }
        FillFeatures()
    end

    return Block(ctx, {
        width = "100%",
        height = "100% available",
        tmargin = MAIN_GAP,
        hpad = 14,
        vpad = 12,
        flow = "horizontal",
        eotwsState = Fill,
        eotwsData = Fill,
        gui.Panel{
            width = "48%",
            height = "100%",
            flow = "vertical",
            Underlined({ Text("Abilities", { "eotwsHeader" }, { valign = "center" }) }),
            abilityBody,
        },
        gui.Panel{
            width = "52%-20",
            height = "100%",
            lmargin = 20,
            flow = "vertical",
            Underlined(featureHead),
            featureBody,
        },
    })
end

--- backdrop ----------------------------------------------------------------------

--What sits behind the sheet: the Guild's art in town; in a game the live
--battle map, blurred and darkened by the engine's background blur.
---@param ctx table
---@return Panel
local function Backdrop(ctx)
    --darker at the left edge, where the card's plate reads over it.
    local shade = gui.Panel{
        floating = true,
        width = "100%",
        height = "100%",
        interactable = false,
        bgimage = "panels/square.png",
        bgcolor = "black",
        gradient = gui.Gradient{
            point_a = { x = 0, y = 0.5 },
            point_b = { x = 1, y = 0.5 },
            stops = {
                { position = 0, color = core.Color{ r = 1, g = 1, b = 1, a = 0.5 } },
                { position = 0.45, color = core.Color{ r = 1, g = 1, b = 1, a = 0.3 } },
                { position = 1, color = core.Color{ r = 1, g = 1, b = 1, a = 0.42 } },
            },
        },
    }

    if ctx.inGame then
        --frosted: everything behind (map and HUD) blurred, lightly darkened.
        --Without frost: the engine's map blur at 60%, the HUD faintly showing.
        --Transparent UI off: near-solid, as the setting asks.
        local color = "#00000099"
        if not ctx.transparent then
            color = "#0b0b0af2"
        elseif ctx.frost then
            color = "#00000059"
        end
        local backdrop = gui.Panel{
            floating = true,
            width = "100%",
            height = "100%",
            bgimage = "panels/square.png",
            bgcolor = color,
            blurBackground = ctx.transparent and not ctx.frost,
            shade,
        }
        if ctx.frost then
            FrostField(backdrop).frost = FROST_RADIUS_BACKDROP
        end
        return backdrop
    end

    --no credit badge: the sheet covers the corner it would sit in, and the
    --Guild scene under the sheet carries the art's credit already.
    return CreatorCredit.Backdrop{
        width = ctx.stageWidth,
        height = ctx.stageHeight,
        image = EncounterOfTheWeek.GUILD_ART,
        aspect = 16 / 9,
        badge = false,
        children = { shade },
    }
end

--- the sheet -----------------------------------------------------------------------

--Where the sheet mounts and how big that space is, by context. In a game it
--is the HUD's main dialog layer -- the same layer the full character sheet
--uses, above trigger cards and roll dialogs but below modals, story screens
--and the "Waiting for..." banner. In town it is the town screen itself.
---@param ctx table
---@return Panel|nil host
local function FindHost(ctx)
    if ctx.inGame then
        local hud = rawget(_G, "gamehud")
        if hud == nil then
            return nil
        end
        local host = hud:try_get("mainDialogPanel")
        if host == nil or not host.valid then
            return nil
        end
        return host
    end
    local host = EncounterOfTheWeek.TownScreen()
    if host ~= nil then
        ctx.stageWidth = host.data.stageWidth or 1920
        ctx.stageHeight = host.data.stageHeight or 1080
    end
    return host
end

--- Opens the hero sheet full screen for one EotW Hero, replacing any sheet
--- already open. Escape or Close closes it.
---
--- args:
---   token    the Hero's token (a map token in game, a lobby character in
---            town). Or pass charid instead.
---   charid   the Hero's character id, for a Hero that may not have loaded
---            yet; the sheet shows its loading skeleton until it arrives,
---            and "{Hero} could not load." + Try again if it never does.
---   name     the Hero's name while it is still loading (e.g. the roster
---            summary's name). Defaults to the token's name.
---   context  "town" or "game"; defaults to where the player is now. Picks
---            the backdrop, the mount point and the switcher's label.
---   fallen   for a fallen Hero opened from the Graveyard: { encounter =
---            where they fell, week = n, playedBy = player name }. Greys the
---            art and shows the epitaph in place of the vitals.
--- @param args table
--- @return Panel|nil sheet the open sheet, or nil if there was nowhere to mount it
function EotwHeroSheet.Show(args)
    EotwHeroSheet.Close()

    local charid = args.charid
    if charid == nil and args.token ~= nil then
        pcall(function() charid = args.token.charid end)
    end

    local context = args.context
    if context == nil then
        context = cond(dmhub.inGame and not dmhub.isLobbyGame, "game", "town")
    end

    ---@type Panel|nil
    local root = nil

    local ctx = {
        charid = charid,
        context = context,
        inGame = context == "game",
        stageWidth = 1920,
        stageHeight = 1080,
        --"loading", "ready" or "failed"
        state = "loading",
        loadStarted = dmhub.Time(),
        shimmerLit = false,
        --the Transparent UI setting; off means solid plates and backdrop
        transparent = dmhub.GetSettingValue("graphics:uiblur") ~= false,
        frost = false,
        --set once a Transparent UI flip has scheduled the rebuild
        rebuilding = false,
        --EotwHeroSheet.Data for the Hero, read when it loads
        data = nil,
        --a fallen Hero opened from the Graveyard: {encounter, week, playedBy}
        fallen = args.fallen,
    }

    function ctx.Token()
        if ctx.charid == nil then
            return nil
        end
        return dmhub.GetCharacterById(ctx.charid)
    end

    function ctx.HeroName()
        local tok = ctx.Token()
        if tok ~= nil then
            return EotwHeroCard.HeroDisplayName(tok)
        end
        if type(args.name) == "string" and args.name ~= "" then
            return args.name
        end
        return "Hero"
    end

    function ctx.LoadingText()
        return string.format("Loading %s...", ctx.HeroName())
    end

    function ctx.FailedText()
        return string.format("%s could not load.", ctx.HeroName())
    end

    --A Hero counts as loaded once its token and properties both resolve.
    local function IsLoaded()
        local tok = ctx.Token()
        if tok == nil then
            return false
        end
        local props = nil
        pcall(function() props = tok.properties end)
        return props ~= nil
    end

    local function SetState(state)
        ctx.state = state
        --read the Hero once on arrival; the regions render from this table
        if state == "ready" then
            ctx.data = ctx.ReadData()
        end
        if root ~= nil and root.valid then
            if state ~= "loading" then
                root:FireEventTree("eotwsShimmer", false)
            end
            root:FireEventTree("eotwsState", state)
        end
    end

    --Read the Hero. In town a lobby character's ownerId is not the player's
    --account, so a Hero on the player's own roster counts as theirs.
    function ctx.ReadData()
        local d = EotwHeroSheet.Data(ctx.Token())
        if d ~= nil and not ctx.inGame and not d.mine and rawget(_G, "EotwRoster") ~= nil then
            local onRoster = false
            pcall(function() onRoster = EotwRoster.FindHero(ctx.charid) ~= nil end)
            d.mine = onRoster
        end
        return d
    end

    --The party this Hero is away with (town only), or nil. Owner controls
    --stay visible but off while away (T14).
    function ctx.AwayParty()
        if ctx.inGame or rawget(_G, "EotwRoster") == nil or ctx.charid == nil then
            return nil
        end
        local away = nil
        pcall(function() away = EotwRoster.AwayHeroes()[ctx.charid] end)
        return away
    end

    --Read the Hero again after the sheet changed it (equip), a moment later
    --so the change has landed, and let every region repaint from it.
    function ctx.Reread()
        dmhub.Schedule(0.1, function()
            if mod.unloaded or root == nil or not root.valid or ctx.state ~= "ready" then
                return
            end
            ctx.data = ctx.ReadData()
            if ctx.data ~= nil then
                root:FireEventTree("eotwsData")
            end
        end)
    end

    --Gold previews in the stats band (C4): what hovering Equip / Unequip
    --would change. HoldPreview keeps them gold for a moment after the change.
    local previewHeldUntil = 0
    local previewHeld = nil
    function ctx.Preview(changes)
        if root == nil or not root.valid then
            return
        end
        if changes == nil and dmhub.Time() < previewHeldUntil then
            return
        end
        root:FireEventTree("eotwsPreview", changes)
    end

    function ctx.HoldPreview(changes)
        if changes == nil or #changes == 0 then
            return
        end
        previewHeldUntil = dmhub.Time() + PREVIEW_HOLD_SECONDS
        previewHeld = changes
        dmhub.Schedule(PREVIEW_HOLD_SECONDS + 0.05, function()
            if mod.unloaded or root == nil or not root.valid then
                return
            end
            previewHeld = nil
            root:FireEventTree("eotwsPreview", nil)
        end)
    end

    --The changes being held gold right now, so a region rebuilt meanwhile
    --(the stats band after an equip) can put the gold back.
    function ctx.HeldPreview()
        if dmhub.Time() < previewHeldUntil then
            return previewHeld
        end
        return nil
    end

    function ctx.Retry()
        ctx.loadStarted = dmhub.Time()
        SetState("loading")
    end

    function ctx.Close()
        if root ~= nil and root.valid then
            root:DestroySelf()
        end
    end

    ctx.frost = ctx.transparent and FrostSupported()

    local host = FindHost(ctx)
    --the builder opens on the same host when the sheet hands over to it
    ctx.host = host
    if host == nil then
        printf("EotW hero sheet: nowhere to mount (%s)", context)
        return nil
    end

    local leftColumn = gui.Panel{
        width = LEFT_WIDTH,
        height = "100%",
        flow = "vertical",
        CardRegion(ctx),
        KitRegion(ctx),
        TreasuresRegion(ctx),
    }

    local mainColumn = gui.Panel{
        width = string.format("100%%-%d", LEFT_WIDTH + COLUMN_GAP),
        height = "100%",
        lmargin = COLUMN_GAP,
        flow = "vertical",
        TopBarRegion(ctx),
        StatsRegion(ctx),
        ListsRegion(ctx),
    }

    root = gui.Panel{
        id = "eotwHeroSheet",
        floating = true,
        width = "100%",
        height = "100%",
        halign = "center",
        valign = "center",
        flow = "none",
        --catches clicks so nothing under the sheet (the map, the town)
        --reacts while it is open.
        bgimage = "panels/square.png",
        bgcolor = "#00000000",
        styles = ThemeEngine.MergeStyles(SHEET_RULES),

        captureEscape = true,
        --EXIT_DIALOG: roll dialogs, modals, popups and dropdowns above it
        --take Escape first; the town, the full sheet and the action bar's
        --targeting sit below it and wait until the sheet is closed.
        escapePriority = EscapePriority.EXIT_DIALOG,
        escape = function()
            --a pinned card closes first; the next Escape closes the sheet
            if ClosePin() then
                return
            end
            ctx.Close()
        end,

        --while loading: watch for the Hero, shimmer the placeholders, and
        --give up after LOAD_TIMEOUT. Always: rebuild when Transparent UI flips,
        --since the plates and backdrop are built see-through or solid.
        thinkTime = SHIMMER_SECONDS,
        think = function(element)
            if mod.unloaded then
                element:DestroySelf()
                return
            end
            if (dmhub.GetSettingValue("graphics:uiblur") ~= false) ~= ctx.transparent and not ctx.rebuilding then
                ctx.rebuilding = true
                dmhub.Schedule(0.01, function()
                    if mod.unloaded or m_sheet ~= element or not element.valid then
                        return
                    end
                    EotwHeroSheet.Show(args)
                end)
                return
            end
            if ctx.state ~= "loading" then
                return
            end
            if IsLoaded() then
                SetState("ready")
                return
            end
            if dmhub.Time() - ctx.loadStarted > LOAD_TIMEOUT then
                SetState("failed")
                return
            end
            if not ThemeEngine.GetAccessibility().reduceMotion then
                ctx.shimmerLit = not ctx.shimmerLit
                element:FireEventTree("eotwsShimmer", ctx.shimmerLit)
            end
        end,

        destroy = function(element)
            if m_sheet == element then
                m_sheet = nil
            end
        end,

        Backdrop(ctx),
        gui.Panel{
            floating = true,
            width = "100%",
            height = "100%",
            pad = PAD,
            borderBox = true,
            flow = "horizontal",
            leftColumn,
            mainColumn,
        },
    }

    host:AddChild(root)
    m_sheet = root

    if IsLoaded() then
        SetState("ready")
    end
    return root
end

--- Closes the open hero sheet, if any.
function EotwHeroSheet.Close()
    if m_sheet ~= nil and m_sheet.valid then
        m_sheet:DestroySelf()
    end
    m_sheet = nil
end

--- True while a hero sheet is open.
--- @return boolean
function EotwHeroSheet.IsOpen()
    return m_sheet ~= nil and m_sheet.valid
end
