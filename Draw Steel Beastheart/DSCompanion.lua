local mod = dmhub.GetModLoading()

RegisterGameType("AnimalCompanion", "monster")

creature.companionid = false

function creature:IsCompanion()
    return false
end

function creature:GetCompanionToken()
    local companionid = self.companionid
    if not companionid then
        return nil
    end

    local token = dmhub.GetTokenById(companionid)
    if token and token.valid then
        return token
    end

    return nil
end

--- Soft-release the beastheart's currently-summoned companion (if any) and
--- clear the companionid link so the next Call summons a fresh one. The
--- companion token is despawned (token.despawned = true), not destroyed --
--- the underlying bestiary entry and any per-token state survive.
--- @param beastheartToken CharacterToken
function creature:ReleaseCompanion(beastheartToken)
    local companionToken = self:GetCompanionToken()
    if companionToken ~= nil then
        companionToken.despawned = true
    end

    if beastheartToken ~= nil and beastheartToken.valid then
        beastheartToken:ModifyProperties{
            description = "Released companion",
            execute = function()
                beastheartToken.properties.companionid = false
            end,
        }
    end
end

function AnimalCompanion:IsCompanion()
    return true
end

function AnimalCompanion:IsMonster()
    return false
end

-- Skill sharing: per Beastheart "Shared Skills" rule, the companion has any
-- skill its summoner has and vice versa. We override SkillProficiencyLevel on
-- both sides; the recursion guard breaks the cycle when each side delegates
-- to the partner. SkillProficiencyLevel is the right hook because the
-- character sheet, the skill-check roller, and the expertise UI all read it
-- (whereas HasSkillProficiency is used by the SkillsDialog to edit the
-- explicit override table -- "own skills only" semantics are correct there).
local g_skillshareRecursion = 0

local function PickHigherProficiency(a, b)
    if a == nil or a.multiplier == nil then return b end
    if b == nil or b.multiplier == nil then return a end
    if b.multiplier > a.multiplier then return b end
    return a
end

function AnimalCompanion:SkillProficiencyLevel(skillInfo)
    local own = monster.SkillProficiencyLevel(self, skillInfo)
    if g_skillshareRecursion > 0 then return own end

    local summoner = self:SummonerToken()
    if summoner == nil then return own end

    g_skillshareRecursion = g_skillshareRecursion + 1
    local shared = summoner.properties:SkillProficiencyLevel(skillInfo)
    g_skillshareRecursion = g_skillshareRecursion - 1

    return PickHigherProficiency(own, shared)
end

local g_originalCharacterSkillProficiencyLevel = character.SkillProficiencyLevel
function character.SkillProficiencyLevel(self, skillInfo)
    local own = g_originalCharacterSkillProficiencyLevel(self, skillInfo)
    if g_skillshareRecursion > 0 then return own end

    local companionToken = self:GetCompanionToken()
    if companionToken == nil then return own end

    g_skillshareRecursion = g_skillshareRecursion + 1
    local shared = companionToken.properties:SkillProficiencyLevel(skillInfo)
    g_skillshareRecursion = g_skillshareRecursion - 1

    return PickHigherProficiency(own, shared)
end

function AnimalCompanion:RefreshToken(token)
    monster.RefreshToken(self, token)

    local summonerid = token.summonerid
    self._tmp_summonerid = summonerid

    local summonerToken = summonerid and dmhub.GetTokenById(self._tmp_summonerid)
    if summonerToken and summonerToken.valid then
        self._tmp_summonerToken = summonerToken

        -- If the summoner has switched companion species (or this companion was
        -- spawned before the bestiary stamp existed), soft-release it so the
        -- next Call spawns the correct type. Only the controlling client runs
        -- the action to avoid duplicate despawns.
        if (not token.despawned) and summonerToken.canControl then
            local expectedType = summonerToken.properties:GetCompanionType()
            local actualType = self:try_get("companionBestiaryId")
            if expectedType ~= nil and actualType ~= expectedType then
                local capturedSummoner = summonerToken
                dmhub.Schedule(0, function()
                    if mod.unloaded then return end
                    if not capturedSummoner.valid then return end
                    capturedSummoner.properties:ReleaseCompanion(capturedSummoner)
                end)
            end
        end
    else
        self._tmp_summonerToken = nil
    end
end

function AnimalCompanion:SummonerToken()
    if self:try_get("_tmp_summonerToken") and self._tmp_summonerToken.valid then
        return self._tmp_summonerToken
    end

    return nil
end

function AnimalCompanion:MaxHitpoints(modifiers)
    local summoner = self:SummonerToken()
    if not summoner then
        return 1
    end

    return summoner.properties:MaxHitpoints()
end

local g_companionSharedResources = {
    "5bd90f9b-46be-4cf2-8ca6-a96430d62949", --recovery
    "d19658a2-4d7b-4504-af9e-1a5410fb17fd", --main action
    "a513b9a6-f311-4b0f-88b8-4e9c7bf92d0b", --maneuver
    "8b0ae5fe-0eb3-45fa-9e6d-b9de68f5cc6d", --surges
    "2d3d5511-4b80-46d1-a8c6-4705b9aa45ca", --heroic resources
    "2166c5fe-260e-4691-9743-06cf097a59f3", --hero tokens
}

local g_companionSharedResourcesKeyed = {}
for _,key in ipairs(g_companionSharedResources) do
    g_companionSharedResourcesKeyed[key] = true
end

function AnimalCompanion:GetResources()

    local cached = self:try_get("_tmp_companionresources")
    if cached ~= nil and self:try_get("_tmp_companionresourcesUpdate") == dmhub.ngameupdate then
        return cached
    end

    local result = table.shallow_copy(monster.GetResources(self))

    local summoner = self:SummonerToken()
    if summoner then
        local summonerResources = summoner.properties:GetResources()
        for _,key in ipairs(g_companionSharedResources) do
            result[key] = summonerResources[key]
        end
    end

    self._tmp_companionresources = result
    self._tmp_companionresourcesUpdate = dmhub.ngameupdate

    return result
end

function AnimalCompanion:GetHeroicOrMaliceResources()
    local summoner = self:SummonerToken()
    if summoner then
        return summoner.properties:GetHeroicOrMaliceResources()
    end

    return 0
end


function AnimalCompanion:ConsumeResource(key, refreshType, quantity, note)
    if g_companionSharedResourcesKeyed[key] then
        local summoner = self:SummonerToken()
        if summoner then
            print("RESOURCE:: CONSUME ON SUMMONER", quantity)
            summoner:ModifyProperties {
                description = "Consume Resource from Animal Companion",
                execute = function()
                    summoner.properties:ConsumeResource(key, refreshType, quantity, note)
                end,
            }
        end

        return
    end

    return monster.ConsumeResource(self, key, refreshType, quantity, note)
end


function AnimalCompanion:RefreshResource(key, refreshType, quantity, note)
            print("RESOURCE:: REFRESH...", quantity)
    if g_companionSharedResourcesKeyed[key] then
        local summoner = self:SummonerToken()
        if summoner then
            print("RESOURCE:: REFRESH ON SUMMONER", quantity)
            summoner:ModifyProperties {
                description = "Refresh Resource from Animal Companion",
                execute = function()
                    summoner.properties:RefreshResource(key, refreshType, quantity, note)
                end,
            }
        end

        return
    end

    monster.RefreshResource(self, key, refreshType, quantity, note)
end

function AnimalCompanion:AddUnboundedResource(key, quantity, note)
    if g_companionSharedResourcesKeyed[key] then
        local summoner = self:SummonerToken()
        if summoner then
            summoner:ModifyProperties {
                description = "Add Resource from Animal Companion",
                execute = function()
                    summoner.properties:AddUnboundedResource(key, quantity, note)
                end,
            }
        end

        return
    end

    return monster.AddUnboundedResource(self, key, quantity, note)
end

function AnimalCompanion:GetUnboundedResourceQuantity(resourceid)
    if g_companionSharedResourcesKeyed[resourceid] then
        local summoner = self:SummonerToken()
        if summoner then
            return summoner.properties:GetUnboundedResourceQuantity(resourceid)
        end

        return 0
    end

    return monster.GetUnboundedResourceQuantity(self, resourceid)
end

function AnimalCompanion:GetHeroicResourceName()
    local summoner = self:SummonerToken()
    if summoner then
        return summoner.properties:GetHeroicResourceName()
    end

    return "Ferocity"
end


function AnimalCompanion:GetHeroTokens()
    return character.GetHeroTokens(self)
end

function AnimalCompanion:GetActivatedAbilities(options)
	options = table.shallow_copy(options or {})
    options.excludeKeywords = {"Beastheart"}

    local result = {}

    local summoner = self:SummonerToken()
    if summoner then
        result = summoner.properties:GetActivatedAbilities(options)
    end

    local numDerivedAbilities = #result

    local ourAbilities = monster.GetActivatedAbilities(self, options)
    for i,ability in ipairs(ourAbilities) do
        local alreadyExists = false
        for j=1,numDerivedAbilities do
            if result[j].name == ability.name then
                alreadyExists = true
                break
            end
        end

        if not alreadyExists then
            result[#result+1] = ability
        end
    end

    return result
end

local g_rampageResourceId = "9f418676-96be-402b-92da-0f50294146b3"

local function CreateCharacterDisplayPanel(element)
    local m_token = nil


    element.data.resourcePanel = gui.Panel {
        width = "100%",
        height = "auto",
        flow = "horizontal",

        hover = function(element)
            local desc = "Rampage"
            local text = nil
            element.tooltip = gui.StatsHistoryTooltip{ text = text, description = desc, entries = m_token.properties:GetStatHistory(g_rampageResourceId):GetHistory() }
        end,


        gui.Label {
            width = "auto",
            height = "auto",
            halign = "left",
            fontSize = 16,
            color = Styles.textColor,
            text = "<b>Rampage</b>:",
        },
        gui.Label {
            editable = true,
            numeric = true,
            lmargin = 8,
            width = 40,
            characterLimit = 3,
            fontSize = 16,
            height = "auto",
            change = function(element)
                local quantity = tonumber(element.text) or 0
                if quantity < 0 then
                    quantity = 0
                end

                local currentQuantity = m_token.properties:GetUnboundedResourceQuantity(g_rampageResourceId)

                m_token:ModifyProperties {
                    description = "Set Rampage",
                    execute = function()
                        m_token.properties:AddUnboundedResource(g_rampageResourceId, quantity - currentQuantity, "Rampage")
                    end,
                }

                element:FireEvent("refreshCompanion", m_token)
            end,

            refreshCompanion = function(element, token)
                m_token = token

                local quantity = token.properties:GetUnboundedResourceQuantity(g_rampageResourceId)
                element.text = tostring(quantity)
            end,
        }
    }

    element:AddChild(element.data.resourcePanel)

end

local g_refreshGuid = dmhub.GenerateGuid()

function AnimalCompanion:DisplayCharacterPanel(token, element)
    local summoner = self:SummonerToken()
    if not summoner then
        element:SetClass("collapsed", true)
        return
    end

    print("DISPLAY:: CREATING")
    element:SetClass("collapsed", false)

    if element.data.init ~= g_refreshGuid then
        element.data.init = g_refreshGuid
        CreateCharacterDisplayPanel(element)
    end

    element:FireEventTree("refreshCompanion", token)

    return true
end

function creature:GetProgressionResource()
    return self:GetHeroicOrMaliceResources()
end

function creature:GetProgressionResourceHighWaterMark()
    return self:HeroicResourceHighWaterMarkForTurn()
end

function AnimalCompanion:GetProgressionResource()
    return self:GetUnboundedResourceQuantity(g_rampageResourceId)
end

function AnimalCompanion:GetProgressionResourceHighWaterMark()
    return self:GetProgressionResource()
end