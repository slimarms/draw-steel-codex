// Standard actions and free strikes from the live app (Dwarf Fury), via tools/probe_std.py.
window.STD = [
{
"name": "Disengage",
"cat": "Move",
"action": "Free",
"distance": "1",
"target": "1 unoccupied space",
"effect": "When a creature takes the Disengage move action, they can shift 1 square. Certain class features, kits, and other rules allow a creature to shift more than 1 square when they disengage. A creature who does so can break up their shift with their maneuver and action however they wish."
},
{
"name": "Jump",
"cat": "Move",
"action": "Free",
"distance": "4",
"target": "1 unoccupied space",
"effect": ""
},
{
"name": "Aid Attack",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "1",
"target": "1 creature",
"effect": "Choose an enemy adjacent to you.\nThe next ability power roll an ally who makes against that creature before the start of your next turn has an edge. \n"
},
{
"name": "Hide",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "Self",
"target": "None/self",
"effect": "You become hidden. You must have cover or concealment from a creature to become hidden, and that creature cannot be observing you."
},
{
"name": "Knockback",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "Melee 1",
"target": "1 creature",
"effect": "You attempt to shove an adjacent creature using a power roll.\nYou can normally only target creatures and objects up to your size category. If your Might score is 2 or higher, you can target creatures and objects with a size equal to your Might score or lower. \n"
},
{
"name": "Search for Hidden Creatures",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "10 burst",
"target": "Each creature",
"effect": "You can search for creatures who are hidden from you as long as those creatures are within 10 squares and you have line of effect to them. To do so, you use a maneuver to make an Intuition test using the Search skill, and any hidden creatures within 10 squares of you each make an opposed Agility test using the Hide skill. At the Director's discretion, different characteristics and skills can be used in this opposed test. For example, your foe might make a Presence test using the Handle Animals skill to hide among a flock of sheep without disturbing them, or you could make a Reason test using the Eavesdrop skill to pick out the breathing of a creature hidden in the dark.\nIf the total of your test is higher than that of a hidden creature, they are no longer hidden from you. Otherwise, they remain hidden from you.\nAs part of the maneuver used to search for hidden creatures, you can point out any creatures you notice to allies within 10 squares of you, making those creatures no longer hidden from those allies.\nIf a creature is hidden from your allies but not from you, you can use a maneuver without making a test to point that creature out to your allies.\n"
},
{
"name": "Stand Up",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "1",
"target": "1 creature",
"effect": "You can use this maneuver to stand up if you are prone, ending that condition. Alternatively, you can use this maneuver to make a willing adjacent prone creature stand up. "
},
{
"name": "Claw Dirt",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "Self",
"target": "None/self",
"effect": "If a creature who can't burrow wants to dig into the ground, they can use the following ability provided their speed is 2 or more."
},
{
"name": "Dig",
"cat": "Heroic Ability",
"action": "Maneuver",
"distance": "Self",
"target": "None/self",
"effect": "A creature with a burrow speed can use the Dig maneuver to move up to their size vertically, straight up or down through the ground."
},
{
"name": "Catch Breath",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "Self",
"target": "None/self",
"effect": "You regain stamina equal to your Recovery Value."
},
{
"name": "Defend",
"cat": "Common Ability",
"action": "Main Action",
"distance": "Self",
"target": "None/self",
"effect": "When you take the Defend action, all attacks against you suffer 2 banes until the start of your next turn."
},
{
"name": "Heal",
"cat": "Common Ability",
"action": "Main Action",
"distance": "1",
"target": "1 creature",
"effect": "The target creature can spend a Recovery to regain Stamina, or can make a saving throw against one effect they are suffering that can be ended by a saving throw. "
},
{
"name": "Use Maneuver",
"cat": "Common Ability",
"action": "Main Action",
"distance": "Self",
"target": "None/self",
"effect": "Convert your Main Action into a Maneuver"
},
{
"name": "Use Move Action",
"cat": "Common Ability",
"action": "Main Action",
"distance": "Self",
"target": "None/self",
"effect": "Convert your Main Action into a Move Action"
},
{
"name": "Grab",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "Melee 1",
"target": "1 creature",
"effect": ""
},
{
"name": "Climb Creature",
"cat": "Common Ability",
"action": "Maneuver",
"distance": "Melee 1",
"target": "1 creature",
"effect": "You can attempt to climb a creature whose size is greater than yours. If the creature is willing, you can climb them without any trouble. If the creature is unwilling, you make the test.\nWhile you climb or ride a creature, you gain an edge on melee abilities used against them.\n"
},
{
"name": "Charge",
"cat": "Common Ability",
"action": "Main Action",
"distance": "6",
"target": "1 unoccupied space",
"effect": "When you take the Charge action, you move up to your speed in a straight line without shifting, and can then make a melee free strike (see Free Strikes) or use an  ability with the Charge keyword against a creature when you end your move. You can\u2019t move through difficult terrain as part of your movement with this action. You  can\u2019t climb, fly, or swim as part of this action unless you have that type of movement as a keyword in your speed."
},
{
"name": "Melee Free Strike",
"cat": "Basic Attack",
"action": "Main Action",
"distance": "Melee 1",
"target": "1 creature or object",
"effect": ""
},
{
"name": "Ranged Free Strike",
"cat": "Basic Attack",
"action": "Main Action",
"distance": "Ranged 5",
"target": "1 creature or object",
"effect": ""
}
];
