import sys

# Builds the share page for David from the review mock: same script and styles, a short body
# with only the controls he needs, and a veteran Conduit to compare with the Level 1 Fury.
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

# the veteran: the Level 6 Conduit has treasure, immunities, XP and Victories banked
rep("""  const immOf = h => state.imm ? MANY_IMM : (h.immunities || []);
  const weakOf = h => state.imm ? MANY_WEAK : (h.weaknesses || []);""",
    """  const VETERAN_KEY = "conduit";
  const immOf = h => h.key === VETERAN_KEY ? MANY_IMM : (h.immunities || []);
  const weakOf = h => h.key === VETERAN_KEY ? MANY_WEAK : (h.weaknesses || []);""")
rep("""  function progressOf(h) {""",
    """  function progressOf(h) {
    if (h.key === VETERAN_KEY && state.prog === "none") return { into: 9, vic: 2, won: 47, epic: 0, max: false, level: h.level, need: XP_PER_LEVEL, next: h.level + 1, ready: false, reach: false };""")
rep("""    if (!(state.vet && isMine(h))) return base;""", """    if (h.key !== VETERAN_KEY) return base;""")
# heroic resource and surges only exist in combat
rep("""  const resOf = h => state.res ? { v: 3, s: 3 } : { v: h.resource.value, s: h.surges };""",
    """  const resOf = h => state.where !== "game" ? { v: 0, s: 0 } : h.key === VETERAN_KEY ? { v: 4, s: 2 } : { v: 2, s: 1 };""")
# only the two heroes this page compares
rep("""  heroSel.innerHTML = HEROES.map(h =>""", """  heroSel.innerHTML = HEROES.filter(h => h.key === "fury" || h.key === VETERAN_KEY).map(h =>""")
# the stamina study is not part of this page
a = s.index("  /* ---------- stamina study ---------- */")
b = s.index("  render(); fit();")
s = s[:a] + s[b:]

open(out, "w", encoding="utf-8").write(s)
print("ok")
