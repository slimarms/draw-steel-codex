local mod = dmhub.GetModLoading()

--The EotW hero sheet's data layer: everything the sheet shows, read from one
--Hero into one plain table by EotwHeroSheet.Data(token). The sheet's UI (C2-C5
--of docs/eotw-hero-sheet/brief.md) renders this table and never reaches into
--the creature itself, so what the sheet shows can be dumped, diffed against the
--mock and tested in one place.
--
--Each section is read inside its own pcall: a section that fails is left out
--and its error is listed in data.errors, so one broken rule never blanks the
--whole sheet. Values are plain (strings, numbers, booleans, arrays); the only
--non-plain fields are the `ability` / `trigger` / `feature` / `item`
--references the UI hands to the codex's own tooltips, all named so a dump can
--skip them.

local CHARACTERISTIC_IDS = { "mgt", "agl", "rea", "inu", "prs" }

--Skill groups in the order the sheet lists them (S1).
local SKILL_GROUPS = {
    { id = "crafting", name = "Crafting" },
    { id = "exploration", name = "Exploration" },
    { id = "interpersonal", name = "Interpersonal" },
    { id = "intrigue", name = "Intrigue" },
    { id = "lore", name = "Lore" },
}

--Ability groups in display order (A2). Free strikes and Standard actions are
--every Hero's global abilities; the rest are the Hero's own.
local ABILITY_GROUPS = {
    { id = "main", name = "Main actions" },
    { id = "maneuver", name = "Maneuvers" },
    { id = "triggered", name = "Triggered actions" },
    { id = "other", name = "Other" },
    { id = "freestrike", name = "Free strikes" },
    { id = "standard", name = "Standard actions" },
}

--Feature sections in display order (F4). "core" holds the class's Core
--Feature pins, wherever they came from.
local FEATURE_SECTIONS = {
    { id = "core", name = "Core feature" },
    { id = "class", name = "Class" },
    { id = "ancestry", name = "Ancestry" },
    { id = "complication", name = "Complication" },
    { id = "kit", name = "Kit" },
    { id = "title", name = "Titles" },
    { id = "perk", name = "Perks" },
    { id = "career", name = "Career" },
    { id = "culture", name = "Culture" },
    { id = "treasure", name = "Treasures" },
}

--Index buckets the Features list never shows: skills and languages have the
--stats band; conditions and ongoing effects live on the character panel; custom
--features are director-side additions EotW does not allow.
local FEATURE_SKIP_BUCKETS = {
    skill = true, language = true, condition = true, effect = true, custom = true, other = true,
}

local PILLARS = { Combat = true, Exploration = true, Montage = true, Negotiation = true, Respite = true }

--Whether an index entry is a choice slot (a perk, domain or ward pick...).
---@param e table
---@return boolean
local function IsChoice(e)
    if e.chosen ~= nil and #e.chosen > 0 then
        return true
    end
    local tn = nil
    pcall(function() tn = e.feature.typeName end)
    return type(tn) == "string" and string.find(tn, "Choice", 1, true) ~= nil
end

--A class's kit-equivalent choices, matched on the choice feature's name, and the
--rules name the sheet uses as the header (K1).
local KIT_EQUIVALENTS = {
    { pattern = "Prayer", header = "Prayer" },
    { pattern = "Enchantment", header = "Enchantment" },
    { pattern = "Augmentation", header = "Augmentation" },
    { pattern = "Ward", header = "Ward" },
    { pattern = "Summoner's Kit", header = "Kit" },
}

--Weapon treasure keywords and the kit weapon types they need. A kit lists its
--weapons as Light / Medium / Heavy / Bow / Polearm / Whip / Net / Unarmed.
local WEAPON_KEYWORDS = {
    ["Light Weapon"] = { "Light" },
    ["Medium Weapon"] = { "Medium" },
    ["Heavy Weapon"] = { "Heavy" },
    ["Bow"] = { "Bow" },
    ["Polearm"] = { "Polearm" },
    ["Whip"] = { "Whip" },
    ["Ensnaring"] = { "Net", "Whip" },
    ["Unarmed"] = { "Unarmed" },
}

local ARMOR_KEYWORDS = {
    ["Light Armor"] = "Light",
    ["Medium Armor"] = "Medium",
    ["Heavy Armor"] = "Heavy",
}

--Keywords that describe what an item is made of rather than where it is worn.
local NON_SLOT_KEYWORDS = { Magic = true, Psionic = true, Consumable = true }

--- text helpers -------------------------------------------------------------

--Codex text carries markup the sheet draws itself: <tags> and **bold**.
---@param s any
---@return string|nil
local function Clean(s)
    if s == nil then
        return nil
    end
    s = tostring(s)
    s = string.gsub(s, "<[^>]*>", "")
    s = string.gsub(s, "%*%*(.-)%*%*", "%1")
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

---@param n number
---@return string
local function Signed(n)
    if n >= 0 then
        return string.format("+%d", n)
    end
    return string.format("%d", n)
end

---@param t table
---@return string[]
local function SortedKeys(t)
    local result = {}
    for k,v in pairs(t or {}) do
        if v then
            result[#result+1] = k
        end
    end
    table.sort(result)
    return result
end

--A creature's tags as a sorted list, without the display-kind tags.
---@param feature any
---@return string[]
local function FeatureTags(feature)
    local tags = {}
    pcall(function()
        for t,on in pairs(feature:try_get("tags") or {}) do
            if on and t ~= "Hidden" and t ~= "Ability" and t ~= "Trigger" then
                tags[#tags+1] = t
            end
        end
    end)
    table.sort(tags)
    return tags
end

--- the stat sources (DescribeModifications) -----------------------------------

--One stat's base value and the sources that change it, for the stat hovers.
---@param base number|nil
---@param mods table|nil DescribeModifications entries
---@return table { base, sources = { {name, value} } }
local function Sources(base, mods)
    local result = { base = base, sources = {} }
    for _,m in ipairs(mods or {}) do
        if m.key ~= nil and not m.unchanged then
            result.sources[#result.sources+1] = { name = Clean(m.key), value = Clean(m.value) }
        end
    end
    return result
end

--- sections -----------------------------------------------------------------

local Sections = {}

function Sections.identity(d, tok, p)
    d.name = EotwHeroCard.HeroDisplayName(tok)
    d.portrait = nil
    pcall(function() d.portrait = tok.offTokenPortrait end)
    d.ownerId = tok.ownerId
    d.mine = tok.ownerId ~= nil and tok.ownerId == dmhub.loginUserid
    d.ownerName = nil
    if tok.ownerId ~= nil and tok.ownerId ~= "" and tok.ownerId ~= "PARTY" then
        pcall(function() d.ownerName = dmhub.GetDisplayName(tok.ownerId) end)
    end
    d.level = p:CharacterLevel()
    d.ancestry = p:RaceOrMonsterType()

    local classNames = {}
    local classesTable = dmhub.GetTable("classes") or {}
    for _,entry in ipairs(p:get_or_add("classes", {})) do
        local classInfo = classesTable[entry.classid]
        if classInfo ~= nil then
            classNames[#classNames+1] = classInfo.name
        end
    end
    d.className = table.concat(classNames, " / ")

    local subclassNames = {}
    for _,subclass in ipairs(p:GetSubclasses()) do
        subclassNames[#subclassNames+1] = subclass.name
    end
    d.subclass = table.concat(subclassNames, " / ")

    local career = p:Background()
    d.career = career ~= nil and career.name or nil

    d.culture = {}
    local culture = p:GetCulture()
    if culture ~= nil then
        local aspects = dmhub.GetTable(CultureAspect.tableName) or {}
        for _,cat in ipairs({ "environment", "organization", "upbringing" }) do
            local aspect = aspects[culture.aspects[cat] or ""]
            if aspect ~= nil then
                d.culture[#d.culture+1] = aspect.name
            end
        end
    end

    d.complications = {}
    for _,c in ipairs(p:Complications()) do
        d.complications[#d.complications+1] = c.name
    end
end

--Titles, with the benefit each one's choice picked (C14/C15: name, echelon,
--flavour, the deed, the benefit).
function Sections.titles(d, tok, p, ctx)
    --benefits come from the feature index: a title's chosen benefit is an
    --entry in the "title" bucket whose origin is the title.
    local benefits = {}
    for _,e in ipairs(ctx.index.features) do
        if e.bucket == "title" and e.originName ~= nil then
            local list = benefits[e.originName] or {}
            benefits[e.originName] = list
            local chosen = e.chosen
            if chosen ~= nil and #chosen > 0 then
                for _,c in ipairs(chosen) do
                    local text = nil
                    pcall(function() text = Clean(c:GetDescription()) end)
                    list[#list+1] = { name = c.name, text = text }
                end
            elseif e.displayKind == "normal" and not IsChoice(e) then
                local text = nil
                pcall(function() text = Clean(e.feature:GetDescription()) end)
                list[#list+1] = { name = e.name, text = text }
            end
        end
    end

    d.titles = {}
    for _,title in ipairs(p:Titles()) do
        d.titles[#d.titles+1] = {
            id = title.id,
            name = title.name,
            echelon = tonumber(title.echelon) or 1,
            flavor = Clean(title.description),
            deed = Clean(title.prerequisite),
            benefits = benefits[title.name] or {},
        }
    end
    table.sort(d.titles, function(a, b) return a.name < b.name end)
end

--Level, XP and banked Victories (C2-C6). XP per Level comes from the game's
--xpperlevel setting (16 by default; Draw Steel also has half and double pace).
function Sections.progress(d, tok, p)
    local level = p:CharacterLevel()
    local per = tonumber(dmhub.GetSettingValue("xpperlevel") or 16) or 16
    if per <= 0 then
        per = 16
    end
    local xp = tonumber(p:try_get("xp", 0)) or 0
    local into = xp - (level - 1) * per
    local victories = p:GetVictories() or 0
    local max = level >= 10

    local progress = {
        level = level,
        nextLevel = cond(max, nil, level + 1),
        xp = xp,
        xpIntoLevel = into,
        xpPerLevel = per,
        victories = victories,
        --a respite turns every banked Victory into 1 XP
        xpAtRespite = victories,
        maxLevel = max,
        readyToLevel = (not max) and into >= per,
        respiteWouldLevel = (not max) and into < per and into + victories >= per,
        epic = nil,
    }

    --Level 10: the bar becomes the class's epic resource, which each respite
    --grows by the XP gained.
    if max then
        local epicid = CharacterResource.epicResourceId
        local resources = dmhub.GetTable(CharacterResource.tableName) or {}
        local info = resources[epicid]
        local value = 0
        pcall(function()
            local total = p:GetResources()[epicid] or 0
            local used = p:GetResourceUsage(epicid, info and info.usageLimit) or 0
            value = math.max(0, total - used)
        end)
        progress.epic = {
            name = p:GetEpicResourceName(),
            value = value,
            gainAtRespite = victories,
            iconid = info ~= nil and info:try_get("iconid") or nil,
        }
    end

    d.progress = progress
end

--Stamina and Recoveries. Dead is at the negative of the Winded value.
function Sections.vitals(d, tok, p)
    local max = p:MaxHitpoints()
    local cur = p:CurrentHitpoints()
    local winded = math.floor(max / 2)
    local state = "healthy"
    local dead = false
    pcall(function() dead = p:IsDead() end)
    if dead then
        state = "dead"
    elseif cur <= 0 then
        state = "dying"
    elseif cur <= winded then
        state = "winded"
    end
    d.stamina = {
        current = cur,
        max = max,
        temp = p:TemporaryHitpoints() or 0,
        winded = winded,
        deadAt = -winded,
        state = state,
    }

    local recoveryid = CharacterResource.recoveryResourceId
    local info = (dmhub.GetTable(CharacterResource.tableName) or {})[recoveryid]
    local maxRecoveries = p:GetResources()[recoveryid] or 0
    local used = p:GetResourceUsage(recoveryid, info and info.usageLimit) or 0
    d.recoveries = {
        current = math.max(0, maxRecoveries - used),
        max = maxRecoveries,
        value = p:RecoveryAmount(),
    }
end

--The heroic resource (the class's own icon, name on hover) and surges.
function Sections.resource(d, tok, p)
    local iconid = nil
    pcall(function()
        local classInfo = p:GetClass()
        if classInfo ~= nil then
            iconid = classInfo:try_get("heroicResourceIcon")
        end
    end)
    d.resource = {
        name = p:GetHeroicResourceName(),
        value = p:GetHeroicOrMaliceResources() or 0,
        iconid = iconid,
    }
    d.surges = p:GetAvailableSurges() or 0
end

--The five characteristics, each with its base and sources.
function Sections.characteristics(d, tok, p)
    d.characteristics = {}
    for _,attrid in ipairs(CHARACTERISTIC_IDS) do
        local info = creature.attributesInfo[attrid]
        local base = p:GetBaseAttribute(attrid).baseValue
        local entry = Sources(base, p:DescribeModifications(attrid, base))
        entry.id = attrid
        entry.name = info and info.description or attrid
        entry.value = p:GetAttribute(attrid):Modifier()
        --modifiers can add up past the hero cap; say why the score is lower
        local capped = false
        pcall(function() capped = p:HeroCharacteristicIsCapped(attrid, p:CalculateAttribute(attrid, base)) end)
        if capped then
            entry.cappedAt = creature.heroCharacteristicMax
        end
        d.characteristics[#d.characteristics+1] = entry
    end
end

--Size, Speed, Disengage, Stability and the Stamina/Recovery numbers, as the
--effective values with their sources (the stat hovers, C4).
function Sections.stats(d, tok, p)
    local stats = {}

    --from the properties: a character that is not on a map reports a default
    --size on its token
    local sizeBase = p:GetBaseCreatureSizeNumber()
    local sizeMods = p:DescribeModifications("creatureSize", sizeBase)
    stats.size = Sources(sizeBase, sizeMods)
    local sizeNumber = sizeBase
    if #sizeMods > 0 and sizeMods[#sizeMods].current ~= nil then
        sizeNumber = sizeMods[#sizeMods].current
    end
    stats.size.value = creature.sizes[sizeNumber] or p:GetBaseCreatureSize() or tok.creatureSize

    local speedBase = p:GetBaseSpeed("speed")
    stats.speed = Sources(speedBase, p:DescribeSpeedModifications())
    stats.speed.value = p:WalkingSpeed()

    local disengageAttr = CustomAttribute.attributeInfoByLookupSymbol["disengagespeed"]
    stats.disengage = Sources(nil, nil)
    if disengageAttr ~= nil then
        stats.disengage = Sources(disengageAttr:CalculateBaseValue(p), p:DescribeModificationsToNamedCustomAttribute("disengagespeed"))
        stats.disengage.value = p:GetCustomAttribute(disengageAttr)
    end

    local stabilityBase = p:BaseForcedMoveResistance()
    stats.stability = Sources(stabilityBase, p:DescribeModifications("forcedmoveresistance", stabilityBase))
    stats.stability.value = p:Stability()

    local staminaBase = p:BaseHitpoints()
    stats.maxStamina = Sources(staminaBase, p:DescribeModifications("hitpoints", staminaBase))
    stats.maxStamina.value = p:MaxHitpoints()

    stats.recoveries = Sources(nil, p:DescribeResourceModifications(CharacterResource.recoveryResourceId))
    stats.recoveries.value = p:GetResources()[CharacterResource.recoveryResourceId] or 0

    local recoveryBase = math.floor(p:MaxHitpoints() / 3)
    stats.recoveryValue = Sources(recoveryBase, p:DescribeModifications("recoveryvalue", recoveryBase))
    stats.recoveryValue.value = p:RecoveryAmount()

    d.stats = stats

    --movement types in the book's form "Speed 6 (fly)": the non-walk modes
    --the Hero has at walking speed or better (everyone climbs at half speed).
    local walking = p:WalkingSpeed()
    local movement = {}
    for _,info in ipairs(creature.movementTypeInfo) do
        if info.id ~= "walk" then
            local speed = 0
            pcall(function() speed = p:GetSpeed(info.id) end)
            if speed > 0 and speed >= walking then
                movement[#movement+1] = string.lower(info.name)
            end
        end
    end
    table.sort(movement)
    d.movement = movement

    d.potency = {
        weak = p:CalculatePotencyValue("Weak"),
        average = p:CalculatePotencyValue("Average"),
        strong = p:CalculatePotencyValue("Strong"),
    }
    d.wealth = p:CalculateNamedCustomAttribute("Wealth")
    d.renown = p:CalculateNamedCustomAttribute("Renown")
end

--Skills by group, languages, immunities and weaknesses: the words row.
function Sections.words(d, tok, p)
    local byGroup = {}
    for _,skill in ipairs(Skill.SkillsInfo) do
        if p:ProficientInSkill(skill) then
            --8 of the 10 crafting skills carry no category in the data
            local cat = skill:try_get("category") or "crafting"
            local list = byGroup[cat] or {}
            byGroup[cat] = list
            list[#list+1] = skill.name
        end
    end
    d.skills = {}
    for _,g in ipairs(SKILL_GROUPS) do
        local list = byGroup[g.id]
        if list ~= nil then
            table.sort(list)
            d.skills[#d.skills+1] = { id = g.id, name = g.name, skills = list }
        end
    end

    d.languages = {}
    local languagesTable = dmhub.GetTable("languages") or {}
    for langid,_ in pairs(p:LanguagesKnown()) do
        local lang = languagesTable[langid]
        if lang ~= nil then
            d.languages[#d.languages+1] = lang.name
        end
    end
    table.sort(d.languages)

    d.immunities = {}
    d.weaknesses = {}
    for _,e in ipairs(p:ResistanceEntries()) do
        local dr = e.entry:try_get("dr", 0)
        local text = TacPanel.CleanResistanceText(e.text) .. " " .. math.abs(dr)
        if dr < 0 then
            d.weaknesses[#d.weaknesses+1] = text
        else
            d.immunities[#d.immunities+1] = text
        end
    end
    local conditionText = p:ConditionImmunityDescription()
    if conditionText ~= nil and conditionText ~= "" then
        d.immunities[#d.immunities+1] = TacPanel.CleanResistanceText(conditionText)
    end
end

--Kit bonuses always list in this order, one kit or two.
local KIT_BONUS_ORDER = { "Stamina", "Speed", "Stability", "Disengage", "Melee distance", "Ranged distance", "Area", "Melee damage", "Ranged damage" }

--One kit's bonuses for the Hero's echelon (Stamina scales with echelon).
---@param kit Kit
---@param echelon number
---@return table[] { {label, value} }
local function KitBonuses(kit, echelon)
    local result = {}
    local function Add(label, value)
        if value ~= nil and value ~= 0 then
            result[#result+1] = { label = label, value = Signed(value) }
        end
    end
    Add("Stamina", (kit:try_get("health", 0) or 0) * echelon)
    Add("Speed", kit:try_get("speed", 0))
    Add("Stability", kit:try_get("stability", 0))
    Add("Disengage", kit:try_get("disengage", 0))
    Add("Melee distance", kit:try_get("reach", 0))
    Add("Ranged distance", kit:try_get("range", 0))
    Add("Area", kit:try_get("area", 0))
    for _,dtype in ipairs({ "melee", "ranged" }) do
        local tiers = kit:DamageBonuses()[dtype]
        if tiers ~= nil then
            local parts = {}
            local any = false
            for i = 1,3 do
                local v = tiers[i] or 0
                any = any or v ~= 0
                parts[#parts+1] = Signed(v)
            end
            if any then
                result[#result+1] = { label = cond(dtype == "melee", "Melee damage", "Ranged damage"), value = table.concat(parts, "/") }
            end
        end
    end
    return result
end

---@param kit Kit
---@return table { armor = string[], weapons = string[] }
local function KitGear(kit)
    local armor = {}
    local a = kit:try_get("armor")
    if type(a) == "string" and a ~= "" and string.lower(a) ~= "none" then
        armor[#armor+1] = a
    end
    return { armor = armor, weapons = SortedKeys(kit:try_get("weapons", {})) }
end

--The kit, or the class's kit-equivalent (K1-K5). A Tactician's two kits read
--as one: each bonus is the better of the two with its source, and the melee
--damage choice (a respite activity) only says which kit it comes from.
function Sections.kit(d, tok, p, ctx)
    local echelon = p:Echelon()
    local kitTable = dmhub.GetTable(Kit.tableName) or {}
    local result = { kind = "none", entries = {} }

    if p:CanHaveKits() then
        local kit1 = kitTable[p:try_get("kitid") or ""]
        local kit2 = nil
        if p:GetNumberOfKits() > 1 then
            kit2 = kitTable[p:try_get("kitid2") or ""]
        end

        if kit1 ~= nil and kit2 ~= nil then
            local b1 = KitBonuses(kit1, echelon)
            local b2 = KitBonuses(kit2, echelon)
            local function Find(list, label)
                for _,b in ipairs(list) do
                    if b.label == label then
                        return b.value
                    end
                end
                return nil
            end
            local labels = {}
            local seen = {}
            for _,label in ipairs(KIT_BONUS_ORDER) do
                if Find(b1, label) ~= nil or Find(b2, label) ~= nil then
                    seen[label] = true
                    labels[#labels+1] = label
                end
            end
            for _,list in ipairs({ b1, b2 }) do
                for _,b in ipairs(list) do
                    if not seen[b.label] then
                        seen[b.label] = true
                        labels[#labels+1] = b.label
                    end
                end
            end
            local bonuses = {}
            local meleeFrom = nil
            for _,label in ipairs(labels) do
                local v1, v2 = Find(b1, label), Find(b2, label)
                local useFirst
                if label == "Melee damage" or label == "Ranged damage" then
                    local dtype = cond(label == "Melee damage", "melee", "ranged")
                    useFirst = v2 == nil or (v1 ~= nil and Kit.DamageBonusSelected(p, dtype, kit1, kit2))
                    if v1 ~= nil and v2 ~= nil and dtype == "melee" then
                        meleeFrom = cond(useFirst, kit1.name, kit2.name)
                    end
                else
                    useFirst = v2 == nil or (v1 ~= nil and (tonumber(v1) or 0) >= (tonumber(v2) or 0))
                end
                bonuses[#bonuses+1] = {
                    label = label,
                    value = cond(useFirst, v1, v2),
                    from = cond(useFirst, kit1.name, kit2.name),
                    other = cond(useFirst, v2, v1),
                    otherFrom = cond(useFirst, kit2.name, kit1.name),
                }
            end
            local g1, g2 = KitGear(kit1), KitGear(kit2)
            local armor, weapons = {}, {}
            for _,list in ipairs({ g1.armor, g2.armor }) do for _,x in ipairs(list) do armor[#armor+1] = x end end
            for _,list in ipairs({ g1.weapons, g2.weapons }) do for _,x in ipairs(list) do weapons[#weapons+1] = x end end
            result.kind = "kit"
            result.combined = true
            result.meleeFrom = meleeFrom
            result.entries[1] = {
                header = "Kit",
                name = kit1.name .. " + " .. kit2.name,
                gear = { armor = armor, weapons = weapons },
                bonuses = bonuses,
            }
        elseif kit1 ~= nil or kit2 ~= nil then
            local kit = kit1 or kit2
            ---@cast kit -nil
            result.kind = "kit"
            result.entries[1] = {
                header = "Kit",
                name = kit.name,
                gear = KitGear(kit),
                bonuses = KitBonuses(kit, echelon),
            }
        end
    end

    --classes without a kit: their kit-equivalent choices, by rules name
    if result.kind == "none" then
        for _,e in ipairs(ctx.index.features) do
            if e.bucket == "class" and IsChoice(e) and e.name ~= nil then
                for _,eq in ipairs(KIT_EQUIVALENTS) do
                    if string.find(e.name, eq.pattern, 1, true) then
                        local chosen = (e.chosen or {})[1]
                        local text = nil
                        if chosen ~= nil then
                            pcall(function() text = Clean(chosen:GetDescription()) end)
                        end
                        result.kind = "equivalent"
                        result.entries[#result.entries+1] = {
                            header = eq.header,
                            name = chosen ~= nil and chosen.name or nil,
                            text = text,
                            choice = e.name,
                        }
                        break
                    end
                end
            end
        end
    end

    d.kit = result
    ctx.kitGear = nil
    if result.kind == "kit" then
        ctx.kitGear = result.entries[1].gear
    end
    --the Conduit's Prayer of Soldier's Skill lets a Hero without a kit use
    --light armor and light weapons (its name carries a curly apostrophe)
    for _,e in ipairs(result.entries) do
        if result.kind == "equivalent" and type(e.name) == "string" and string.find(e.name, "Soldier", 1, true) then
            ctx.kitGear = { armor = { "Light" }, weapons = { "Light" } }
        end
    end
end

--Why a weapon or armor treasure gives no benefit, or nil when it does (R5, N8).
---@param keywords table
---@param gear table|nil the kit's gear, nil without a kit
---@return string|nil reason "nokit", "armor" or "weapon"
local function NoBenefitReason(keywords, gear)
    local weaponNeeds = nil
    local armorNeeds = nil
    for kw,_ in pairs(keywords) do
        if WEAPON_KEYWORDS[kw] ~= nil then
            weaponNeeds = weaponNeeds or {}
            for _,w in ipairs(WEAPON_KEYWORDS[kw]) do
                weaponNeeds[#weaponNeeds+1] = w
            end
        end
        if ARMOR_KEYWORDS[kw] ~= nil then
            armorNeeds = armorNeeds or {}
            armorNeeds[#armorNeeds+1] = ARMOR_KEYWORDS[kw]
        end
    end
    if weaponNeeds == nil and armorNeeds == nil then
        return nil
    end
    if gear == nil then
        return "nokit"
    end
    local function Has(list, x)
        for _,v in ipairs(list) do
            if v == x then
                return true
            end
        end
        return false
    end
    if armorNeeds ~= nil then
        for _,a in ipairs(armorNeeds) do
            if Has(gear.armor, a) then
                return nil
            end
        end
        return "armor"
    end
    ---@cast weaponNeeds -nil
    for _,w in ipairs(weaponNeeds) do
        if Has(gear.weapons, w) then
            return nil
        end
    end
    return "weapon"
end

--Treasures grouped Leveled / Trinkets / Consumables, each with its slot,
--equip state and any No benefit reason (R1-R7).
function Sections.treasures(d, tok, p, ctx)
    local gearTable = dmhub.GetTable("tbl_Gear") or {}
    local groups = { leveled = {}, trinket = {}, consumable = {}, other = {} }

    local function Add(itemid, equipped, slot, quantity)
        local item = gearTable[itemid]
        if item == nil then
            return
        end
        local kind = "other"
        if EquipmentCategory.IsLeveledTreasure(item) then
            kind = "leveled"
        elseif EquipmentCategory.IsTrinket(item) or EquipmentCategory.IsArtifact(item) then
            kind = "trinket"
        elseif EquipmentCategory.IsConsumable(item) then
            kind = "consumable"
        end
        local keywords = item:try_get("keywords", {})
        local body = nil
        for _,kw in ipairs(SortedKeys(keywords)) do
            if not NON_SLOT_KEYWORDS[kw] then
                body = kw
                break
            end
        end
        local echelon = nil
        pcall(function() echelon = tonumber(item:try_get("echelon")) end)
        local entry = {
            itemid = itemid,
            name = item.name,
            kind = kind,
            keywords = SortedKeys(keywords),
            body = body,
            slot = slot,
            equipped = equipped,
            equippable = EquipmentCategory.IsEquippable(item),
            quantity = quantity or 1,
            echelon = echelon,
            description = Clean(item:try_get("description")),
            noBenefit = NoBenefitReason(keywords, ctx.kitGear),
            item = item,
        }
        local list = groups[kind]
        list[#list+1] = entry
    end

    local seen = {}
    for slot,itemid in pairs(p:Equipment()) do
        if type(itemid) == "string" and not seen[itemid] then
            seen[itemid] = true
            Add(itemid, true, slot, 1)
        end
    end
    for itemid,entry in pairs(p:try_get("inventory", {})) do
        if (entry.quantity or 0) > 0 then
            Add(itemid, false, nil, entry.quantity)
        end
    end
    for _,list in pairs(groups) do
        table.sort(list, function(a, b) return a.name < b.name end)
    end

    local toEquip = 0
    for _,list in pairs(groups) do
        for _,it in ipairs(list) do
            if it.equippable and not it.equipped and it.kind ~= "consumable" then
                toEquip = toEquip + 1
            end
        end
    end

    --items that are none of the three (an ancestry item such as a Dwarf's
    --Runic Carving) list with the trinkets; their kind stays "other"
    for _,it in ipairs(groups.other) do
        groups.trinket[#groups.trinket+1] = it
    end
    table.sort(groups.trinket, function(a, b) return a.name < b.name end)

    d.treasures = {
        leveled = groups.leveled,
        trinkets = groups.trinket,
        consumables = groups.consumable,
        leveledCarried = #groups.leveled,
        --equippable treasure not yet worn; C3 narrows this to items won in
        --EotW once the City's provenance is wired in
        toEquip = toEquip,
    }
end

--- abilities ------------------------------------------------------------------

--The row tags for an ability (A4: the action type, with "No action" in place
--of "Free"; the cost: Signature, or "{n} {Resource}").
---@param ability ActivatedAbility
---@param resourceName string
---@return string actionTag
---@return string|nil costTag
local function AbilityTags(ability, resourceName)
    local resTable = dmhub.GetTable(CharacterResource.tableName) or {}
    local actionName = nil
    pcall(function()
        local rid = ability:ActionResource()
        if rid ~= nil and resTable[rid] ~= nil then
            actionName = resTable[rid].name
        end
    end)
    local cat = ability:try_get("categorization")
    local actionTag
    if cat == "Trigger" then
        actionTag = "Triggered action"
    elseif actionName == nil or actionName == "" or actionName == "Free" then
        actionTag = "No action"
    else
        actionTag = string.upper(string.sub(actionName, 1, 1)) .. string.lower(string.sub(actionName, 2))
    end

    local costTag = nil
    pcall(function()
        if ability:has_key("resourceCost") and resTable[ability.resourceCost] ~= nil then
            local n = tonumber(ability:try_get("resourceNumber", 1)) or 1
            if n > 0 then
                costTag = string.format("%d %s", n, resourceName)
            end
        end
    end)
    if costTag == nil and cat == "Signature Ability" then
        costTag = "Signature"
    end
    return actionTag, costTag
end

---@param actionTag string
---@return string groupid
local function AbilityGroup(actionTag)
    local t = string.lower(actionTag)
    if string.find(t, "trigger", 1, true) then
        return "triggered"
    end
    if string.find(t, "main action", 1, true) then
        return "main"
    end
    if string.find(t, "maneuver", 1, true) then
        return "maneuver"
    end
    return "other"
end

--Abilities per the tagging plan (docs/feature-metadata-incremental/
--hero-tagging-plan.md): an ability whose source feature is tagged Ability or
--Trigger is an ability card; one whose source is a visible prose feature or a
--Hidden one stays out (the feature shows instead, or nothing); Core Feature
--actions (Judgment, Mark) and kit signature abilities, which have no source
--feature, show. Every Hero's global abilities are grouped as Free strikes and
--Standard actions.
function Sections.abilities(d, tok, p, ctx)
    --ability -> the feature that grants it, from every indexed feature's modifiers
    local byGuid, byName, byMod = {}, {}, {}
    local function Scan(feature)
        if feature == nil then
            return
        end
        pcall(function()
            for _,m in ipairs(feature:try_get("modifiers", {})) do
                byMod[m] = feature
                local guid = m:try_get("guid")
                if guid ~= nil then
                    byMod[guid] = feature
                end
                local a = m:try_get("activatedAbility")
                if a ~= nil then
                    byGuid[a.guid] = feature
                    byName[a.name] = feature
                end
            end
        end)
    end
    for _,e in ipairs(ctx.index.features) do
        Scan(e.feature)
        for _,c in ipairs(e.chosen or {}) do
            Scan(c)
        end
    end

    local resourceName = (d.resource and d.resource.name) or p:GetHeroicResourceName()
    local groups = {}
    for _,g in ipairs(ABILITY_GROUPS) do
        groups[g.id] = { id = g.id, name = g.name, items = {} }
    end
    local seenNames = {}

    local function Hidden(ability)
        return ability:try_get("hidden") == true or ability:try_get("categorization") == "Hidden"
    end

    --whether something granted by `source` shows as an ability card
    local function Shows(source)
        if source == nil then
            return true
        end
        local kind = "normal"
        pcall(function() kind = source:DisplayKind() end)
        local core = false
        pcall(function() core = (source:try_get("tags") or {})["Core Feature"] == true end)
        return kind == "ability" or kind == "trigger" or (kind == "normal" and core)
    end

    local own = p:GetActivatedAbilities{ bindCaster = true, characterSheet = true, excludeGlobal = true }
    for _,ability in ipairs(own) do
        local source = byGuid[ability.guid] or byName[ability.name]
        local show = (not Hidden(ability)) and Shows(source)
        if show and not seenNames[ability.name] then
            seenNames[ability.name] = true
            local actionTag, costTag = AbilityTags(ability, resourceName)
            local groupid = AbilityGroup(actionTag)
            if ability:try_get("categorization") == "Basic Attack" then
                groupid = "freestrike"
            end
            local list = groups[groupid].items
            list[#list+1] = {
                name = ability.name,
                actionTag = actionTag,
                costTag = costTag,
                category = ability:try_get("categorization"),
                source = source ~= nil and source.name or nil,
                ability = ability,
            }
        end
    end

    --triggered actions shown in the trigger drawer, from the Hero's own
    --modifiers (the global Opportunity Attack is every Hero's)
    local triggers = {}
    for _,entry in ipairs(p:GetActiveModifiers()) do
        if not entry._global then
            local before = #triggers
            pcall(function() entry.mod:AccumulateTriggeredActionDisplay(entry, p, triggers) end)
            local source = byMod[entry.mod]
            if source == nil then
                pcall(function() source = byMod[entry.mod.guid] end)
            end
            for i = before + 1, #triggers do
                --a trigger card from a visible feature still shows (the drawer is
                --where the codex puts it); only Hidden plumbing stays out
                local kind = "normal"
                if source ~= nil then
                    pcall(function() kind = source:DisplayKind() end)
                end
                triggers[i] = { display = triggers[i], show = kind ~= "hidden", source = source }
            end
        end
    end
    for _,tt in ipairs(triggers) do
        local t = tt.display
        if t.name ~= nil and tt.show and not seenNames[t.name] then
            seenNames[t.name] = true
            local list = groups.triggered.items
            list[#list+1] = {
                name = t.name,
                actionTag = cond(t.type == "free", "Free triggered action", "Triggered action"),
                costTag = cond(t.cost ~= nil and t.cost ~= "", t.cost, nil),
                category = "Triggered Action",
                source = tt.source ~= nil and tt.source.name or nil,
                trigger = t,
            }
        end
    end

    --every Hero's abilities: whatever is in the full list and not the Hero's own
    local ownNames = {}
    for _,ability in ipairs(own) do
        ownNames[ability.name] = true
    end
    for _,ability in ipairs(p:GetActivatedAbilities{ bindCaster = true, characterSheet = true }) do
        if not ownNames[ability.name] and not Hidden(ability) and not seenNames[ability.name] then
            seenNames[ability.name] = true
            local actionTag, costTag = AbilityTags(ability, resourceName)
            local groupid = cond(ability:try_get("categorization") == "Basic Attack", "freestrike", "standard")
            local list = groups[groupid].items
            list[#list+1] = {
                name = ability.name,
                actionTag = actionTag,
                costTag = costTag,
                category = ability:try_get("categorization"),
                ability = ability,
            }
        end
    end

    d.abilities = {}
    for _,g in ipairs(ABILITY_GROUPS) do
        if #groups[g.id].items > 0 then
            d.abilities[#d.abilities+1] = groups[g.id]
        end
    end
end

--- features -------------------------------------------------------------------

--Text that only restates a skill or language grant, which the stats band shows.
---@param text string
---@return boolean
local function IsGrantText(text)
    local t = string.lower(text)
    for _,prefix in ipairs({ "you are proficient with", "you know how to speak", "you can speak", "choose one", "choose two", "choose 1", "choose 2", "choose a skill", "choose a language" }) do
        if string.sub(t, 1, #prefix) == prefix then
            return true
        end
    end
    return string.match(t, "^you have the .- skill") ~= nil or string.match(t, "^you gain the .- skill") ~= nil
end

--Whether a feature only grants skills/languages, raises characteristics, or
--defines a resource with no text: things the stats band and vitals already
--show, so the Features list leaves them out.
---@param feature any
---@return boolean
local function ShownElsewhere(feature)
    local mods = {}
    pcall(function() mods = feature:try_get("modifiers", {}) end)
    if #mods == 0 then
        return false
    end
    local allGrants = true
    local allCharacteristics = true
    local allResources = true
    for _,m in ipairs(mods) do
        local behavior = m:try_get("behavior")
        local subtype = m:try_get("subtype")
        local skills = m:try_get("skills")
        local grants = subtype == "skill" or subtype == "language"
            or (behavior ~= "power" and type(skills) == "table" and #skills > 0)
        allGrants = allGrants and grants
        local attr = m:try_get("attribute")
        allCharacteristics = allCharacteristics and behavior == "attribute"
            and (attr == "mgt" or attr == "agl" or attr == "rea" or attr == "inu" or attr == "prs")
        allResources = allResources and behavior == "resource"
    end
    if allCharacteristics then
        return true
    end
    if allGrants then
        local text = ""
        pcall(function() text = Clean(feature:GetDescription()) or "" end)
        return text == "" or IsGrantText(text)
    end
    if allResources then
        local text = nil
        pcall(function() text = Clean(feature:GetDescription()) end)
        return text == nil or text == ""
    end
    return false
end

--Features by section (F1-F7): visible features only (tagged Ability, Trigger
--or Hidden ones show as ability cards or not at all); a choice shows the
--option the Hero picked, "Chosen for {choice}".
function Sections.features(d, tok, p, ctx)
    local sections = {}
    for _,s in ipairs(FEATURE_SECTIONS) do
        sections[s.id] = { id = s.id, name = s.name, items = {} }
    end
    local seen = {}
    local total = 0

    local function Add(sectionid, feature, name, chosenFor, fallbackText)
        if feature == nil or name == nil then
            return
        end
        local kind = "normal"
        pcall(function() kind = feature:DisplayKind() end)
        if kind ~= "normal" or ShownElsewhere(feature) then
            return
        end
        --level-table placeholders ("1st-Level Domain Feature") point at a pick
        --that shows on its own
        if string.match(name, "^%d+%a%a%-%s?Level .-Feature$") or string.match(name, "^%d+%a%a%-%s?Level .-Abilit") then
            return
        end
        local text = nil
        pcall(function() text = Clean(feature:GetDescription()) end)
        if text == nil or text == "" then
            text = fallbackText
        end
        local key = name .. "|" .. (text or "")
        if seen[key] then
            return
        end
        seen[key] = true
        local tags = FeatureTags(feature)
        local pillars = {}
        local core = false
        for _,t in ipairs(tags) do
            if PILLARS[t] then
                pillars[#pillars+1] = t
            elseif t == "Core Feature" then
                core = true
            end
        end
        local section = sections[cond(core, "core", sectionid)] or sections.class
        section.items[#section.items+1] = {
            guid = feature:try_get("guid"),
            name = name,
            text = text,
            pillars = pillars,
            chosenFor = chosenFor,
            feature = feature,
        }
        total = total + 1
    end

    for _,e in ipairs(ctx.index.features) do
        local kitStats = e.bucket == "kit" and type(e.name) == "string" and string.find(e.name, " Kit Stats$") ~= nil
        if not FEATURE_SKIP_BUCKETS[e.bucket or "other"] and not kitStats then
            if IsChoice(e) then
                for _,c in ipairs(e.chosen or {}) do
                    Add(e.bucket, c, c.name, e.name)
                end
            else
                Add(e.bucket, e.feature, e.name, nil, nil)
            end
        end
    end

    d.features = { sections = {}, total = total }
    for _,s in ipairs(FEATURE_SECTIONS) do
        if #sections[s.id].items > 0 then
            d.features.sections[#d.features.sections+1] = sections[s.id]
        end
    end
end

--Sections in the order they run: kit before treasures (No benefit reads the
--kit's gear), resource before abilities (cost tags name the resource).
local SECTION_ORDER = {
    "identity", "titles", "progress", "vitals", "resource", "characteristics",
    "stats", "words", "kit", "treasures", "abilities", "features",
}

--- Reads everything the EotW hero sheet shows for one Hero into one table.
--- Pass the Hero's token (a map token in game or a lobby character in town).
--- Returns nil when the Hero has no properties yet (still loading). Sections
--- that fail are left out and named in data.errors as "{section}: {error}".
--- @param tok CharacterToken
--- @return table|nil
function EotwHeroSheet.Data(tok)
    if tok == nil then
        return nil
    end
    local p = nil
    pcall(function() p = tok.properties end)
    if p == nil then
        return nil
    end

    local d = { charid = tok.charid, errors = {} }
    local ctx = { index = { features = {} } }
    local ok, err = pcall(function() ctx.index = FeatureCategoriser.BuildIndex(p) end)
    if not ok then
        d.errors[#d.errors+1] = "index: " .. tostring(err)
    end

    for _,name in ipairs(SECTION_ORDER) do
        local okSection, errSection = pcall(Sections[name], d, tok, p, ctx)
        if not okSection then
            d.errors[#d.errors+1] = name .. ": " .. tostring(errSection)
        end
    end
    return d
end

--- The Data table with every object reference removed, for dumps and diffs.
--- @param data table
--- @return table
function EotwHeroSheet.PlainData(data)
    local skip = { ability = true, trigger = true, feature = true, item = true }
    local function Copy(v)
        if type(v) ~= "table" then
            return v
        end
        local out = {}
        for k,x in pairs(v) do
            if not skip[k] then
                local t = type(x)
                if t == "table" then
                    if getmetatable(x) == nil then
                        out[k] = Copy(x)
                    end
                elseif t ~= "function" and t ~= "userdata" then
                    out[k] = x
                end
            end
        end
        return out
    end
    return Copy(data)
end
