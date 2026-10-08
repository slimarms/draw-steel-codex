import sys

src, body_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(src, encoding="utf-8").read()


def rep(a, b):
    global s
    assert a in s, "missing: " + a[:90]
    s = s.replace(a, b, 1)


# title, and the page body (intro, controls, stage, notes for David)
rep("<title>EotW Sheet Layouts</title>", "<title>EotW Hero Sheet Proposal</title>")
a = s.index('<div class="page">')
b = s.index('<script src="data.js"></script>')
s = s[:a] + open(body_path, encoding="utf-8").read() + "\n" + s[b:]

# a little more room for the two text sections
rep("  .note h2 { font-size: 16px; margin: 0 0 6px; color: #f1ece2; }",
    "  .note h2 { font-size: 16px; margin: 0 0 6px; color: #f1ece2; }\n"
    "  .share { grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); margin-top: 24px; }\n"
    "  .share .note { padding: 18px 20px; }\n"
    "  .share .note h2 { font-size: 19px; margin-bottom: 10px; }\n"
    "  .share li { font-size: 14.5px; line-height: 1.6; }\n"
    "  .share li + li { margin-top: 8px; }\n"
    "  .share li b { color: #f1ece2; }")

# the decided look: centred lines for size to potency
rep("""const state = { hero: "fury", bd: "place", where: "town", sp: "groups",""",
    """const state = { hero: "fury", bd: "place", where: "town", sp: "centred",""")
rep("""  try { const b = localStorage.getItem("eotw-r10-sp"); if (b === "groups" || b === "centred" || b === "grid") state.sp = b; } catch (e) {}""", "")

# the comparison: the level 6 Conduit has been playing a while; both show resource and surges
rep("""  const immOf = h => state.imm ? MANY_IMM : (h.immunities || []);
  const weakOf = h => state.imm ? MANY_WEAK : (h.weaknesses || []);""",
    """  const VETERAN_KEY = "conduit";
  const immOf = h => h.key === VETERAN_KEY ? MANY_IMM : (h.immunities || []);
  const weakOf = h => h.key === VETERAN_KEY ? MANY_WEAK : (h.weaknesses || []);""")
rep("""  function progressOf(h) {""",
    """  function progressOf(h) {
    if (h.key === VETERAN_KEY) return { vic: 2, into: 9, need: XP_PER_LEVEL, next: h.level + 1 };""")
rep("""    if (!(state.vet && isMine(h))) return base;""", """    if (h.key !== VETERAN_KEY) return base;""")
rep("""  const resOf = h => state.res ? { v: 3, s: 2 } : { v: h.resource.value, s: h.surges };""",
    """  const resOf = h => h.key === VETERAN_KEY ? { v: 4, s: 2 } : { v: 2, s: 1 };""")

# only the controls this page has
rep("""    document.getElementById("ctl-stam").value = state.stam;\n""", "")
rep("""    [["ctl-vet", "vet"], ["ctl-imm", "imm"], ["ctl-prog", "prog"], ["ctl-twokit", "twokit"], ["ctl-res", "res"], ["ctl-sig", "sig"]].forEach(([id, k]) => document.getElementById(id).setAttribute("aria-pressed", String(state[k])));""",
    """    [["ctl-sig", "sig"]].forEach(([id, k]) => { const el = document.getElementById(id); if (el) el.setAttribute("aria-pressed", String(state[k])); });""")
rep("""  const stamSel = document.getElementById("ctl-stam");
  stamSel.innerHTML = STAM_STATES.map(s => '<option value="' + s[0] + '">' + esc(s[1]) + "</option>").join("");
  stamSel.addEventListener("change", () => { state.stam = stamSel.value; render(); });""", "")
rep("""  heroSel.innerHTML = HEROES.map(h =>""", """  heroSel.innerHTML = HEROES.filter(h => h.key === "fury" || h.key === VETERAN_KEY).map(h =>""")
# the stamina study is not part of this page
a = s.index("  /* ---------- stamina study ---------- */")
b = s.index("  render(); fit();")
s = s[:a] + s[b:]

open(out, "w", encoding="utf-8").write(s)
print("ok")
