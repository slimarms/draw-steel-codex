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
}

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
}

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

--The hero card at sheet size. In C0 only the name line is live: the loading
--line, the Hero's name once loaded, or the failure line with Try again.
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

    local plate = gui.Panel{
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
        bgimage = "panels/square.png",
        bgcolor = "#000000c4",
        cornerRadius = 8,
        eotwsState = function(element, state)
            if state == "failed" then
                nameLabel.text = ctx.FailedText()
            elseif state == "ready" then
                nameLabel.text = ctx.HeroName()
            else
                nameLabel.text = ctx.LoadingText()
            end
            retryButton:SetClass("collapsed", state ~= "failed")
        end,

        nameLabel,
        retryButton,
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

    return gui.Panel{
        width = LEFT_WIDTH,
        height = CARD_HEIGHT,
        flow = "none",
        bgimage = "panels/square.png",
        bgcolor = "#151515ff",
        borderWidth = 1,
        borderColor = "#000000cc",
        cornerRadius = 10,
        plate,
    }
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
        styles =ThemeEngine.MergeStyles(RULES),

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
