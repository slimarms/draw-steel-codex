import json, sys, urllib.request
code = r'''
local resTable = dmhub.GetTable(CharacterResource.tableName)
local function clean(s)
  if s == nil then return nil end
  s = tostring(s)
  s = string.gsub(s, "<[^>]*>", "")
  s = string.gsub(s, "%*%*(.-)%*%*", "%1")
  return s
end
local out = {}
for _, tok in ipairs(dmhub.allTokens) do
  if tok.name == "Dwarf Fury" then
    local p = tok.properties
    local own = {}
    for _, a in ipairs(p:GetActivatedAbilities{ bindCaster = true, characterSheet = true, excludeGlobal = true }) do own[a.name] = true end
    for _, ability in ipairs(p:GetActivatedAbilities{ bindCaster = true, characterSheet = true }) do
      if not own[ability.name] then
        local a = { name = ability.name, cat = ability:try_get("categorization"), hidden = ability:try_get("hidden") }
        pcall(function() local rid = ability:ActionResource(); a.action = rid and resTable[rid] and resTable[rid].name or "Free" end)
        local eff = {}
        for _, k in ipairs({"preDescription", "description"}) do
          local text = ability:try_get(k)
          if text ~= nil and text ~= "" then
            local s = text
            pcall(function() s = StringInterpolateGoblinScript(text, p) end)
            eff[#eff+1] = clean(s)
          end
        end
        a.effect = table.concat(eff, "\n")
        pcall(function() a.distance = clean(ability:DescribeRange(p)) end)
        pcall(function() a.target = clean(ability:DescribeTarget(tok)) end)
        out[#out+1] = a
      end
    end
  end
end
return json(out)
'''
req = urllib.request.Request('http://localhost:19876/execute', data=json.dumps({'code': code}).encode(), headers={'Content-Type': 'application/json'})
r = json.loads(urllib.request.urlopen(req, timeout=60).read().decode())
print(json.dumps(r)[:200])
res = r.get('result') if isinstance(r, dict) else r
if isinstance(res, str):
    try: res = json.loads(res)
    except Exception: pass
json.dump(res, open(sys.argv[1], 'w', encoding='utf-8'), indent=1)
