import json, sys, time, urllib.request
SP = sys.argv[1]
heroes = [
 ("fury","91de7c9d-f2d1-45e9-baf6-04ea81b1b188"),
 ("tactician","80569cde-4e1a-42bd-9b70-7ee1af59326b"),
 ("censor","47d0d587-c809-447c-817e-1d308c7dafa5"),
 ("null","1fb171bd-371d-4a19-a7ba-648b5ee0e5ad"),
 ("talent","b1f01693-23ec-460b-a2d9-283ae16a0835"),
 ("shadow","dac98309-fb00-4ddf-b903-a95db8e7b126"),
 ("troubadour","3949a38d-1b74-4eef-9e19-39eb1bf79fdc"),
 ("elementalist","60ca5052-830b-4c1a-ad4c-72d896e49756"),
 ("conduit","f980e094-03e2-466b-8d02-fee07803e5ee"),
]
def lua(code):
    req = urllib.request.Request('http://localhost:19876/execute', data=json.dumps({'code': code}).encode(), headers={'Content-Type': 'application/json'})
    return json.loads(urllib.request.urlopen(req, timeout=30).read().decode())
mount = '''
local old = rawget(_G, "__claudeArt")
if old ~= nil and old.valid then old:DestroySelf() end
local p = gui.Panel{ floating = true, halign = "center", valign = "center", width = 640, height = 960,
  bgimage = "panels/square.png", bgcolor = "black" }
local root = gui.Panel{ floating = true, width = "100%", height = "100%", bgimage = "panels/square.png", bgcolor = "black", p }
gamehud.mainDialogPanel:AddChild(root)
rawset(_G, "__claudeArt", root)
rawset(_G, "__claudeArtImg", p)
'''
print(lua(mount))
for name, imgid in heroes:
    r = lua('local p = rawget(_G, "__claudeArtImg"); p.bgimage = "%s"; p.selfStyle.bgcolor = "white"' % imgid)
    time.sleep(2.5)
    data = urllib.request.urlopen('http://localhost:19876/screenshot', timeout=30).read()
    open(f"{SP}/art/{name}_full.png", "wb").write(data)
    print(name, r.get('success'), len(data))
print(lua('local r = rawget(_G, "__claudeArt"); if r and r.valid then r:DestroySelf() end; rawset(_G,"__claudeArt",nil); rawset(_G,"__claudeArtImg",nil); print("removed")'))
