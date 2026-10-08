import json, sys, re
SP = sys.argv[1]
H = json.load(open(f"{SP}/heroes_norm.json"))
C = {x['key']: x for x in json.load(open(f"{SP}/feats_chosen.json"))}
OWNERS = {"fury": "You", "tactician": "You", "censor": "You", "null": "You",
          "talent": "Alex", "shadow": "Sam", "troubadour": "Jordan", "elementalist": "You", "conduit": "You"}
SECTION = {"class": "Class", "ancestry": "Ancestry", "complication": "Complication", "kit": "Kit",
           "title": "Titles", "perk": "Perks", "career": "Career", "culture": "Culture", "treasure": "Treasures"}
GRANT_RX = re.compile(r"^(You are proficient with|You know how to speak|You have the .* skill|Choose (1|one|2|two|a) (skill|language|Language))", re.I)
DROP_NAMES = {"Recoveries", "Kit", "Skills"}
def chars(f):
    return [{"k": n[0], "name": n, "v": f.get(n, "+0")} for n in ["Might", "Agility", "Reason", "Intuition", "Presence"]]
def num(v, d=0):
    try: return int(str(v).replace("+", ""))
    except: return d
out = []
for h in H:
    f = h["fields"]; key = h["key"]
    feats = []
    ABILITY_NAMES = {a.get("name") for a in h["abilities"]}
    for e, c in zip(h["features"], C[key]["features"]):
        bucket = e.get("bucket") or "other"
        if bucket in ("skill", "language", "effect", "condition", "custom", "other"): continue
        name = e.get("name") or ""
        desc = (e.get("desc") or "").strip()
        kind = e.get("kind") or "normal"
        section = SECTION.get(bucket, bucket.title())
        chosen = c.get("chosen")
        if chosen:
            for ch in chosen:
                ck = ch.get("kind")
                if ck is None: continue
                feats.append({"name": ch.get("name"), "sub": name, "section": section, "desc": (ch.get("desc") or "").strip(),
                              "tags": [t for t in (ch.get("tags") or []) if t not in ("Hidden", "Ability", "Trigger")],
                              "kind": ck})
            continue
        if name in DROP_NAMES or name.endswith("Kit Stats") or name == "Characteristic Increase": continue
        if GRANT_RX.search(desc) and kind == "normal": continue
        if kind == "normal" and (desc.startswith("Choose ") or "of your choice" in desc): continue
        if re.match(r"^\d+(st|nd|rd|th)-\s?Level Domain (Feature|Ability)$", name): continue
        if kind == "normal" and desc == "" and name in ABILITY_NAMES: continue
        feats.append({"name": name, "sub": None, "section": section, "desc": desc,
                      "tags": [t for t in (e.get("tags") or []) if t not in ("Hidden", "Ability", "Trigger")], "kind": kind})
    seen = set(); dedup = []
    for ft in feats:
        k2 = (ft["name"], ft["desc"])
        if k2 in seen: continue
        seen.add(k2); dedup.append(ft)
    feats = dedup
    for ft in feats:
        if "Core Feature" in (ft["tags"] or []): ft["section"] = "Core"
    abil = []
    for a in h["abilities"]:
        if not a.get("name"): continue
        abil.append({k: a.get(k) for k in ["name", "cat", "action", "cost", "keywords", "distance", "target", "flavor", "roll", "tiers", "effect", "trigger", "impl"]})
    kitname = f.get("Modifier Name")
    kit = None
    if kitname and kitname != "None":
        bon = []
        for lab, fk in [("Stamina", "Stamina Modifier"), ("Speed", "Speed Modifier"), ("Stability", "Stability Modifier"), ("Disengage", "Disengage Modifier"), ("Ranged distance", "Ranged Modifier")]:
            v = f.get(fk)
            if v and v not in ("+0", "0"): bon.append({"label": lab, "value": v})
        md = [f.get("Melee Weapon Damage T%d" % i, "+0") for i in (1, 2, 3)]
        rd = [f.get("Ranged Weapon Damage T%d" % i, "+0") for i in (1, 2, 3)]
        if any(x not in ("+0", "0") for x in md): bon.append({"label": "Melee damage", "value": "/".join(md)})
        if any(x not in ("+0", "0") for x in rd): bon.append({"label": "Ranged damage", "value": "/".join(rd)})
        kit = {"name": kitname, "gear": f.get("Weapon/Implement"), "bonuses": bon}
    inv = [{"name": i.get("name"), "qty": i.get("qty"), "equipped": False} for i in h.get("inventory") or []]
    inv += [{"name": e.get("name"), "qty": 1, "equipped": True, "slot": e.get("slot")} for e in h.get("equipment") or []]
    mx = num(f.get("stamina max"), 1)
    out.append({
        "key": key, "name": h["name"], "owner": OWNERS.get(key, "You"),
        "level": num(f.get("Level"), 1), "ancestry": f.get("Ancestry"), "className": f.get("Class"), "subclass": f.get("Subclass"),
        "career": f.get("Career Name"), "culture": [f.get("Culture Environment"), f.get("Culture Organization"), f.get("Culture Upbringing")],
        "complication": (h.get("complications") or [None])[0] if isinstance(h.get("complications"), list) and h.get("complications") else None,
        "kit": kit, "chars": chars(f),
        "stamina": {"cur": num(f.get("Current Stamina")), "max": mx, "winded": num(f.get("winded count"), mx // 2)},
        "temp": 0, "recoveries": {"cur": num(f.get("Recoveries")), "max": num(f.get("recov max")), "value": num(f.get("recov stamina"))},
        "speed": f.get("Speed"), "size": f.get("Size"), "stability": f.get("Stability"), "disengage": f.get("Disengage"),
        "potency": {"strong": f.get("Potency Strong"), "average": f.get("Potency Average"), "weak": f.get("Potency Weak")},
        "resource": {"name": f.get("resource name"), "value": h.get("heroic") or 0}, "surges": num(f.get("Surges")),
        "victories": h.get("victories") or 0, "wealth": f.get("Wealth"), "renown": f.get("Renown"), "xp": f.get("XP"),
        "skills": h.get("skills") or [], "languages": [x.strip() for x in (f.get("Languages") or "").split(",") if x.strip()],
        "abilities": abil, "features": feats, "inventory": inv,
    })
json.dump(out, open(f"{SP}/mock/data.json", "w"), indent=0)
open(f"{SP}/mock/data.js", "w").write("window.HEROES = " + json.dumps(out) + ";\n")
for o in out:
    vis = [x for x in o["features"] if x["kind"] == "normal"]
    print(o["key"], "L%d" % o["level"], "abil", len(o["abilities"]), "feat visible", len(vis), "all", len(o["features"]), "skills", len(o["skills"]), "langs", len(o["languages"]), "kit", o["kit"] and o["kit"]["name"])
fury = [o for o in out if o["key"] == "conduit"][0]
for x in fury["features"]:
    print("  ", x["kind"], "|", x["section"], "|", x["name"], "|", x["sub"], "|", x["tags"], "|", x["desc"][:70].replace("\n", " "))
