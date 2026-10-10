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
local KIT_HEIGHT = 110
local MAIN_GAP = 16
local TOPBAR_HEIGHT = 60
local STATS_HEIGHT = 218

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
    local noteLeft = Text("", { "eotwsPlateText", "eotwsNote" })
    local noteRight = Text("", { "eotwsPlateText", "eotwsNote" }, { halign = "right" })
    local staminaBlock = gui.Panel{
        width = "100%",
        height = "auto",
        tmargin = 9,
        flow = "vertical",
        gui.Panel{
            width = "100%",
            height = "auto",
            flow = "none",
            bar,
            statusIcon,
        },
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

        local r = d.recoveries
        if r ~= nil then
            ringLabel.text = tostring(r.current)
            ring:SetClass("empty", r.current <= 0)
            local tip = string.format("Each Recovery regains %d Stamina.", r.value)
            ring.data.tip = tip
            recoveriesCell.data.tip = tip
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
            surges.data.tip = string.format("%d %s. Spend them for extra damage or potency.",
                d.surges, cond(d.surges == 1, "surge", "surges"))
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
                Paint(d)
            end
        end,

        plate,
    }
    return card
end

--- kit and treasures (left column) ---------------------------------------------

---@param ctx table
---@return Panel
local function KitRegion(ctx)
    return Block(ctx, {
        width = LEFT_WIDTH,
        height = KIT_HEIGHT,
        tmargin = LEFT_GAP,
        flow = "vertical",
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
            flow = "horizontal",
            Skel(130, 12),
            Skel(16, 12, { lmargin = 12 }),
            Skel(128, 12, { lmargin = 12 }),
            Skel(56, 12, { halign = "right" }),
        },
    })
end

---@param ctx table
---@return Panel
local function TreasuresRegion(ctx)
    local Section = function(label, rows)
        local children = {
            Text(label, { "eotwsLabel" }, { tmargin = 8 }),
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

    return Block(ctx, {
        width = LEFT_WIDTH,
        height = string.format("100%%-%d", CARD_HEIGHT + KIT_HEIGHT + 2 * LEFT_GAP),
        tmargin = LEFT_GAP,
        flow = "vertical",
        Text("Treasures", { "eotwsHeader" }),
        Section("Leveled treasures", 1),
        Section("Trinkets", 2),
        Section("Consumables", 1),
    })
end

--- top bar (main column) ---------------------------------------------------------

---@param ctx table
---@return Panel
local function TopBarRegion(ctx)
    local thumbs = {}
    for i = 1, 6 do
        thumbs[#thumbs+1] = Skel(40, 56, { lmargin = cond(i == 1, 10, 8), cornerRadius = 6 })
    end

    local closeButton = gui.Panel{
        classes = { "eotwsButton" },
        width = "auto",
        height = 38,
        hpad = 14,
        borderBox = true,
        halign = "right",
        valign = "center",
        flow = "horizontal",
        click = function()
            ctx.Close()
        end,
        Text("Close", nil, { valign = "center" }),
        gui.Panel{
            width = "auto",
            height = "auto",
            lmargin = 8,
            hpad = 5,
            borderBox = true,
            valign = "center",
            borderWidth = 1,
            borderColor = C.BORDER,
            cornerRadius = 4,
            Text("Esc", { "muted" }, { fontSize = 11 }),
        },
    }

    return gui.Panel{
        width = "100%",
        height = TOPBAR_HEIGHT,
        hpad = 12,
        borderBox = true,
        flow = "horizontal",
        bgimage = "panels/square.png",
        bgcolor = C.TOPBAR,
        cornerRadius = 10,
        --the switcher's label names whose Heroes it cycles: the player's
        --roster in town, the Heroes in this encounter in a game.
        Text(cond(ctx.inGame, "This encounter", "Your roster"), { "muted" }, {
            fontSize = 11,
            bold = true,
            uppercase = true,
            valign = "center",
        }),
        gui.Panel{
            width = "auto",
            height = "100%",
            flow = "horizontal",
            valign = "center",
            children = thumbs,
        },
        closeButton,
    }
end

--- stats band (main column) ------------------------------------------------------

---@param ctx table
---@return Panel
local function StatsRegion(ctx)
    local tiles = {}
    for i,name in ipairs(CHARACTERISTICS) do
        tiles[#tiles+1] = gui.Panel{
            width = 145,
            height = 58,
            lmargin = cond(i == 1, 0, 8),
            vpad = 6,
            borderBox = true,
            flow = "vertical",
            bgimage = "panels/square.png",
            bgcolor = "#00000038",
            borderWidth = 1,
            borderColor = C.BORDER,
            cornerRadius = 8,
            Text(name, { "eotwsLabel" }, { halign = "center" }),
            Skel(136, 30, { halign = "center", tmargin = 4 }),
        }
    end

    --one "Label [value]" pair on a centred line.
    local Pair = function(label, first)
        return gui.Panel{
            width = "auto",
            height = 24,
            lmargin = cond(first, 0, 24),
            flow = "horizontal",
            Text(label, { "eotwsLabel" }, { valign = "center", fontSize = 12 }),
            Skel(14, 22, { lmargin = 8, valign = "center" }),
        }
    end
    local Line = function(children, args)
        local fields = {
            width = "auto",
            height = "auto",
            halign = "center",
            tmargin = 12,
            flow = "horizontal",
            children = children,
        }
        for k,v in pairs(args or {}) do
            fields[k] = v
        end
        return gui.Panel(fields)
    end

    local potency = Line({
        Text("Potency", { "eotwsLabel" }, { valign = "center", fontSize = 12 }),
        Text("Weak", { "muted" }, { valign = "center", lmargin = 20 }),
        Skel(10, 22, { lmargin = 6, valign = "center" }),
        Text("Average", { "muted" }, { valign = "center", lmargin = 20 }),
        Skel(10, 22, { lmargin = 6, valign = "center" }),
        Text("Strong", { "muted" }, { valign = "center", lmargin = 20 }),
        Skel(10, 22, { lmargin = 6, valign = "center" }),
    }, {
        hpad = 14,
        vpad = 5,
        borderBox = true,
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 18,
    })

    --a words column: Skills, Languages, Immunities or Weaknesses.
    local Words = function(label, width, bars, first)
        local children = { Text(label, { "eotwsHeader" }) }
        local row = {}
        for _,w in ipairs(bars) do
            row[#row+1] = Skel(w, 20, { rmargin = 18, bmargin = 4 })
        end
        children[#children+1] = gui.Panel{
            width = "100%",
            height = "auto",
            tmargin = 6,
            flow = "horizontal",
            wrap = true,
            children = row,
        }
        return gui.Panel{
            width = width,
            height = "100%",
            flow = "vertical",
            lpad = cond(first, 0, 16),
            borderBox = true,
            children = children,
        }
    end

    return Block(ctx, {
        width = "100%",
        height = STATS_HEIGHT,
        tmargin = MAIN_GAP,
        flow = "vertical",
        gui.Panel{
            width = "100%",
            height = 96,
            flow = "horizontal",
            gui.Panel{
                width = "auto",
                height = "100%",
                flow = "vertical",
                Text("Characteristics", { "eotwsHeader" }),
                gui.Panel{
                    width = "auto",
                    height = "auto",
                    tmargin = 8,
                    flow = "horizontal",
                    children = tiles,
                },
            },
            gui.Panel{
                width = "100%-790",
                height = "100%",
                flow = "vertical",
                Line({ Pair("Size", true), Pair("Speed"), Pair("Disengage"), Pair("Stability") }, { tmargin = 2 }),
                potency,
                Line({ Pair("Wealth", true), Pair("Renown") }, { tmargin = 8 }),
            },
        },
        Hairline(),
        gui.Panel{
            width = "100%",
            height = "100%-116",
            flow = "horizontal",
            Words("Skills", "48%", { 160, 200, 140, 170, 84 }, true),
            Words("Languages", "18%", { 160 }),
            Words("Immunities", "18%", { 36 }),
            Words("Weaknesses", "16%", { 36 }),
        },
    })
end

--- abilities and features (main column) ------------------------------------------

---@param ctx table
---@return Panel
local function ListsRegion(ctx)
    local Underlined = function(children)
        return gui.Panel{
            width = "100%",
            height = 44,
            flow = "horizontal",
            borderColor = "#bc9b7b66",
            border = { x1 = 0, x2 = 0, y1 = 1, y2 = 0 },
            children = children,
        }
    end

    local abilityGroups = {}
    for _,rows in ipairs({ 3, 2, 4 }) do
        abilityGroups[#abilityGroups+1] = Skel(116, 12, { tmargin = 14 })
        for r = 1, rows do
            abilityGroups[#abilityGroups+1] = gui.Panel{
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

    local featureCards = {}
    for _ = 1, 3 do
        featureCards[#featureCards+1] = gui.Panel{
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

    local chips = {}
    for _,pillar in ipairs(PILLARS) do
        chips[#chips+1] = gui.Panel{
            classes = { "eotwsChip" },
            width = "auto",
            height = 28,
            hpad = 10,
            lmargin = 10,
            borderBox = true,
            valign = "center",
            Text(pillar, nil, { fontSize = 12.5, valign = "center" }),
        }
    end
    --the filter box; C5 makes it a real input.
    chips[#chips+1] = gui.Panel{
        width = "100%-560",
        height = 28,
        lmargin = 10,
        hpad = 10,
        borderBox = true,
        valign = "center",
        bgimage = "panels/square.png",
        bgcolor = "#00000040",
        borderWidth = 1,
        borderColor = C.BORDER,
        cornerRadius = 6,
        Text("Filter features", { "muted" }, { fontSize = 13, valign = "center" }),
    }

    local featureHead = { Text("Features", { "eotwsHeader" }, { valign = "center" }) }
    for _,chip in ipairs(chips) do
        featureHead[#featureHead+1] = chip
    end

    return Block(ctx, {
        width = "100%",
        height = string.format("100%%-%d", TOPBAR_HEIGHT + STATS_HEIGHT + 2 * MAIN_GAP),
        tmargin = MAIN_GAP,
        hpad = 14,
        vpad = 12,
        flow = "horizontal",
        gui.Panel{
            width = "48%",
            height = "100%",
            flow = "vertical",
            Underlined({ Text("Abilities", { "eotwsHeader" }, { valign = "center" }) }),
            gui.Panel{
                width = "100%",
                height = "100%-44",
                flow = "vertical",
                children = abilityGroups,
            },
        },
        gui.Panel{
            width = "52%-20",
            height = "100%",
            lmargin = 20,
            flow = "vertical",
            Underlined(featureHead),
            gui.Panel{
                width = "100%",
                height = "100%-44",
                flow = "vertical",
                children = featureCards,
            },
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
            ctx.data = EotwHeroSheet.Data(ctx.Token())
        end
        if root ~= nil and root.valid then
            if state ~= "loading" then
                root:FireEventTree("eotwsShimmer", false)
            end
            root:FireEventTree("eotwsState", state)
        end
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
