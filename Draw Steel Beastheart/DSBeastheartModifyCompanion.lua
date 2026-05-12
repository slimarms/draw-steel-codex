local mod = dmhub.GetModLoading()

-- A "Modify Companion" CharacterModifier sits on the beastheart and contributes
-- modifiers onto their summoned companion. Symmetric to "Modify Mount Riders"
-- (DSModifyMounts.lua / modrider) -- the dispatch is via FillCompanionModifiers
-- on CharacterModifier and is invoked from AnimalCompanion's
-- FillTemporalActiveModifiers override in DSCompanion.lua.

CharacterModifier.RegisterType("modcompanion", "Modify Companion")

CharacterModifier.TypeInfo.modcompanion = {
    init = function(modifier)
        modifier.feature = CharacterFeature.Create{
            name = "Companion",
            description = "Modify the beastheart's companion",
            source = "Beastheart",
        }
    end,

    modifyCompanion = function(modifier, creature, companion, targetModifiers)
        for _,childMod in ipairs(modifier.feature.modifiers) do
            targetModifiers[#targetModifiers+1] = {
                mod = childMod,
            }
        end
    end,

    createEditor = function(modifier, element)
        local children = {}

        children[#children+1] = modifier:FilterConditionEditor()

        children[#children+1] = gui.Button{
            classes = {"sizeM"},
            text = "Edit Modifiers",
            click = function(element)
                element.root:AddChild(modifier.feature:PopupEditor())
            end,
        }

        element.children = children
    end,
}

--- Dispatcher invoked from AnimalCompanion:FillTemporalActiveModifiers. Each
--- of the beastheart's active modifiers is asked, in turn, whether it
--- contributes anything to the companion's modifier list. Modifiers whose
--- behavior has no `modifyCompanion` callback are silent.
--- @param context table Modifier context (the entry from GetActiveModifiers).
--- @param creature creature The beastheart's properties.
--- @param companion creature The companion's properties.
--- @param modifiers table The companion's accumulating modifier list.
function CharacterModifier:FillCompanionModifiers(context, creature, companion, modifiers)
    local typeInfo = CharacterModifier.TypeInfo[self.behavior] or {}
    if typeInfo.modifyCompanion ~= nil then
        self:InstallSymbolsFromContext(context)
        typeInfo.modifyCompanion(self, creature, companion, modifiers)
    end
end

-- Mirror of "Modify Companion" in the companion -> summoner direction. A
-- "Modify Summoner" CharacterModifier sits on a companion stat block (e.g.,
-- the bear's Strong Like Bear trait) and contributes modifiers back to the
-- beastheart. Per the Companion rules, "you" inside a companion stat block
-- refers to the beastheart, so traits worded that way need a way to reach
-- the partner. Dispatch is via FillSummonerModifiers on CharacterModifier
-- and is invoked from character:FillTemporalActiveModifiers in
-- DSCompanion.lua.

CharacterModifier.RegisterType("modsummoner", "Modify Summoner")

CharacterModifier.TypeInfo.modsummoner = {
    init = function(modifier)
        modifier.feature = CharacterFeature.Create{
            name = "Summoner",
            description = "Modify the companion's beastheart",
            source = "Beastheart",
        }
    end,

    modifySummoner = function(modifier, creature, summoner, targetModifiers)
        for _,childMod in ipairs(modifier.feature.modifiers) do
            targetModifiers[#targetModifiers+1] = {
                mod = childMod,
            }
        end
    end,

    createEditor = function(modifier, element)
        local children = {}

        children[#children+1] = modifier:FilterConditionEditor()

        children[#children+1] = gui.Button{
            classes = {"sizeM"},
            text = "Edit Modifiers",
            click = function(element)
                element.root:AddChild(modifier.feature:PopupEditor())
            end,
        }

        element.children = children
    end,
}

--- Dispatcher invoked from character:FillTemporalActiveModifiers (override
--- in DSCompanion.lua). Each of the companion's active modifiers is asked,
--- in turn, whether it contributes anything to the summoner's modifier list.
--- @param context table Modifier context (the entry from GetActiveModifiers).
--- @param creature creature The companion's properties.
--- @param summoner creature The beastheart's properties.
--- @param modifiers table The summoner's accumulating modifier list.
function CharacterModifier:FillSummonerModifiers(context, creature, summoner, modifiers)
    local typeInfo = CharacterModifier.TypeInfo[self.behavior] or {}
    if typeInfo.modifySummoner ~= nil then
        self:InstallSymbolsFromContext(context)
        typeInfo.modifySummoner(self, creature, summoner, modifiers)
    end
end
