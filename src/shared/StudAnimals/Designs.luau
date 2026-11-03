--[[
	Designs
	Every animal is plain data: a list of bricks on the stud grid.

	Conventions
	  * Units are studs. Y = 0 is the ground, animals face -Z (forward).
	  * Widths/depths snap to whole studs, heights to plates (0.4) where possible.
	  * Each brick: { name, size = {x,y,z}, pos = {x,y,z}, color = <Palette key> }
	    optional: rot = {x,y,z} (degrees), shape = "Wedge" | "Ball",
	              studs = true/false (default: on for bricks >= 1x1),
	              root = true (the body; everything joins to it),
	              parent = "<brick name>" (weld to that brick instead of the body),
	              anim = { mode, axis, amp, speed, phase, pivot = {x,y,z} }
	  * idle = { mode, axis, amp, speed } moves the whole animal (Bob/Hop/Swing).

	This file is intentionally plain Lua (no Luau-only syntax) so tools can
	load it outside Roblox for previews.
]]

local Designs = {}

-- Helpers ---------------------------------------------------------------

local function copy(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end

local function P(name, size, pos, color, opts)
	local d = opts and copy(opts) or {}
	d.name, d.size, d.pos, d.color = name, size, pos, color
	return d
end

local function add(list, ...)
	for _, d in ipairs({ ... }) do
		list[#list + 1] = d
	end
end

-- Mirror a brick across the X = 0 plane (rotations about Y/Z flip sign).
local function mirrored(d, prefix)
	local m = copy(d)
	m.name = prefix .. d.name
	m.pos = { -d.pos[1], d.pos[2], d.pos[3] }
	if d.rot then
		m.rot = { d.rot[1], -d.rot[2], -d.rot[3] }
	end
	if d.parent and d.sided then
		m.parent = prefix .. d.parent
	end
	if d.anim then
		local a = copy(d.anim)
		a.pivot = { -a.pivot[1], a.pivot[2], a.pivot[3] }
		if a.axis ~= "X" then
			a.amp = -a.amp
		end
		m.anim = a
	end
	return m
end

-- Add a right-hand (+X) group and its mirrored left-hand twin.
-- Set `sided = true` on a brick whose parent is part of the same pair.
local function pair(list, defs)
	for _, d in ipairs(defs) do
		local r = copy(d)
		r.name = "Right" .. d.name
		if d.parent and d.sided then
			r.parent = "Right" .. d.parent
		end
		list[#list + 1] = r
		list[#list + 1] = mirrored(d, "Left")
	end
end

local function swing(pivot, axis, amp, speed, phase)
	return { mode = "Swing", pivot = pivot, axis = axis, amp = amp, speed = speed, phase = phase or 0 }
end

local function twitch(pivot, axis, amp, speed, phase)
	return { mode = "Twitch", pivot = pivot, axis = axis, amp = amp, speed = speed, phase = phase or 0 }
end

-- Glossy brick eyes. `front` is the face the eyes sit on (Z).
local function eyes(list, x, y, front, size, parent, sclera)
	size = size or 0.6
	if sclera then
		pair(list, { P("EyeWhite", { size + 0.3, size + 0.3, 0.2 }, { x, y, front - 0.1 }, "white", { parent = parent }) })
		front = front - 0.2
	end
	pair(list, { P("Eye", { size, size, 0.2 }, { x, y, front - 0.1 }, "eye", { parent = parent }) })
	-- Glints sit on the same side of both eyes, like a single light source.
	local g = size * 0.35
	local gz = front - 0.2 - 0.025
	add(list,
		P("RightEyeGlint", { g, g, 0.05 }, { x + size * 0.2, y + size * 0.2, gz }, "white", { parent = parent }),
		P("LeftEyeGlint", { g, g, 0.05 }, { -x + size * 0.2, y + size * 0.2, gz }, "white", { parent = parent })
	)
end

-- Animals ---------------------------------------------------------------

Designs.Dog = (function()
	local p = {}
	add(p, P("Body", { 3, 1.6, 4 }, { 0, 2.0, 0 }, "tan", { root = true }))
	pair(p, {
		P("FrontPaw", { 1, 0.4, 1 }, { 1, 0.2, -1.5 }, "white"),
		P("FrontLeg", { 1, 0.8, 1 }, { 1, 0.8, -1.5 }, "tan"),
		P("BackPaw", { 1, 0.4, 1 }, { 1, 0.2, 1.5 }, "white"),
		P("BackLeg", { 1, 0.8, 1 }, { 1, 0.8, 1.5 }, "tan"),
	})
	add(p,
		P("Chest", { 2, 1.2, 0.4 }, { 0, 1.8, -2.2 }, "cream"),
		P("Saddle", { 2, 0.4, 2 }, { 0, 3.0, 0.8 }, "brown"),
		P("Head", { 3, 2, 2 }, { 0, 3.8, -1.6 }, "tan", { anim = swing({ 0, 2.8, -1.6 }, "Z", 6, 1.5) }),
		P("Snout", { 2, 1.2, 1.2 }, { 0, 3.4, -3.2 }, "cream", { parent = "Head" }),
		P("Nose", { 1, 0.4, 0.6 }, { 0, 4.2, -3.5 }, "eye", { parent = "Head", studs = true }),
		P("Tongue", { 0.6, 0.4, 0.2 }, { 0, 2.6, -3.6 }, "pinkDark", { parent = "Head" })
	)
	eyes(p, 0.7, 4.3, -2.6, 0.6, "Head")
	pair(p, {
		P("Ear", { 0.6, 1.6, 1.2 }, { 1.8, 4.0, -1.6 }, "brown",
			{ parent = "Head", anim = swing({ 1.5, 4.8, -1.6 }, "Z", 8, 3) }),
	})
	add(p, P("Tail", { 0.6, 0.6, 1.6 }, { 0, 3.06, 2.66 }, "brown",
		{ rot = { -35, 0, 0 }, anim = swing({ 0, 2.6, 2.0 }, "Y", 25, 8) }))
	return { displayName = "Dog", parts = p }
end)()

Designs.Cat = (function()
	local p = {}
	add(p, P("Body", { 2, 1.2, 4 }, { 0, 1.8, 0 }, "grey", { root = true }))
	pair(p, {
		P("FrontPaw", { 1, 0.4, 1 }, { 0.5, 0.2, -1.5 }, "white"),
		P("FrontLeg", { 1, 0.8, 1 }, { 0.5, 0.8, -1.5 }, "grey"),
		P("BackPaw", { 1, 0.4, 1 }, { 0.5, 0.2, 1.5 }, "white"),
		P("BackLeg", { 1, 0.8, 1 }, { 0.5, 0.8, 1.5 }, "grey"),
	})
	add(p,
		P("Stripe1", { 2, 0.4, 1 }, { 0, 2.6, 0 }, "darkGrey"),
		P("Stripe2", { 2, 0.4, 1 }, { 0, 2.6, 1.5 }, "darkGrey"),
		P("Chest", { 1.6, 0.8, 0.2 }, { 0, 1.8, -2.1 }, "white"),
		P("Head", { 3, 2, 2 }, { 0, 3.4, -2 }, "grey", { anim = swing({ 0, 2.4, -2 }, "Z", 5, 1.2) }),
		P("HeadStripe", { 1, 0.4, 1 }, { 0, 4.6, -1.8 }, "darkGrey", { parent = "Head" }),
		P("Muzzle", { 1.6, 0.8, 0.4 }, { 0, 2.9, -3.2 }, "white", { parent = "Head" }),
		P("Nose", { 0.4, 0.4, 0.2 }, { 0, 3.5, -3.1 }, "pinkDark", { parent = "Head" })
	)
	eyes(p, 0.75, 3.9, -3.0, 0.6, "Head")
	pair(p, {
		P("Ear", { 0.4, 1, 1 }, { 1.0, 4.9, -2.2 }, "grey",
			{ shape = "Wedge", rot = { 0, 90, 0 }, parent = "Head", anim = twitch({ 1.0, 4.4, -2.2 }, "Z", 15, 2) }),
	})
	add(p,
		P("Tail", { 0.6, 2.4, 0.6 }, { 0, 2.8, 2.3 }, "grey", { anim = swing({ 0, 1.8, 2.3 }, "Z", 15, 2) }),
		P("TailTip", { 0.6, 0.4, 0.6 }, { 0, 4.2, 2.3 }, "darkGrey", { parent = "Tail" })
	)
	return { displayName = "Cat", parts = p }
end)()

Designs.Pig = (function()
	local p = {}
	add(p, P("Body", { 3, 2, 4 }, { 0, 2.2, 0 }, "pink", { root = true }))
	pair(p, {
		P("FrontHoof", { 1, 0.4, 1 }, { 1, 0.2, -1.5 }, "pinkDark"),
		P("FrontLeg", { 1, 0.8, 1 }, { 1, 0.8, -1.5 }, "pink"),
		P("BackHoof", { 1, 0.4, 1 }, { 1, 0.2, 1.5 }, "pinkDark"),
		P("BackLeg", { 1, 0.8, 1 }, { 1, 0.8, 1.5 }, "pink"),
	})
	add(p,
		P("Mud1", { 2, 0.4, 1 }, { 0.5, 3.4, 0.5 }, "brown"),
		P("Mud2", { 1, 0.4, 1 }, { 1, 3.4, 1.5 }, "brown"),
		P("Head", { 3, 2, 1.2 }, { 0, 2.6, -2.6 }, "pink", { anim = swing({ 0, 2.6, -2.0 }, "X", 4, 2) }),
		P("Snout", { 1.6, 1.2, 0.4 }, { 0, 2.4, -3.4 }, "pinkDark", { parent = "Head" })
	)
	pair(p, { P("Nostril", { 0.2, 0.4, 0.1 }, { 0.35, 2.4, -3.65 }, "eye", { parent = "Head" }) })
	eyes(p, 0.8, 3.3, -3.2, 0.5, "Head")
	pair(p, {
		P("Ear", { 0.4, 0.8, 1 }, { 1, 4.0, -2.6 }, "pinkDark",
			{ shape = "Wedge", rot = { 0, 90, 0 }, parent = "Head", anim = twitch({ 1, 3.6, -2.6 }, "Z", 12, 1.6) }),
	})
	add(p,
		P("Tail", { 0.4, 0.4, 0.8 }, { 0, 2.8, 2.4 }, "pink", { anim = swing({ 0, 2.8, 2.0 }, "Y", 30, 10) }),
		P("TailCurl", { 0.4, 0.4, 0.4 }, { 0, 3.2, 2.6 }, "pink", { parent = "Tail" })
	)
	return { displayName = "Pig", parts = p }
end)()

Designs.Cow = (function()
	local p = {}
	add(p, P("Body", { 3, 2, 5 }, { 0, 2.8, 0 }, "white", { root = true }))
	pair(p, {
		P("FrontHoof", { 1, 0.4, 1 }, { 1, 0.2, -2 }, "darkGrey"),
		P("FrontLeg", { 1, 1.4, 1 }, { 1, 1.1, -2 }, "white"),
		P("BackHoof", { 1, 0.4, 1 }, { 1, 0.2, 2 }, "darkGrey"),
		P("BackLeg", { 1, 1.4, 1 }, { 1, 1.1, 2 }, "white"),
	})
	add(p,
		P("Spot1", { 2, 0.4, 2 }, { -0.5, 4.0, 0.5 }, "black"),
		P("Spot2", { 1, 0.4, 1 }, { 1, 4.0, -1.5 }, "black"),
		P("SideSpot1", { 0.2, 1.2, 1.6 }, { 1.6, 3.0, 1.0 }, "black"),
		P("SideSpot2", { 0.2, 0.8, 1.2 }, { -1.6, 2.6, -1.0 }, "black"),
		P("Udder", { 1, 0.4, 1 }, { 0, 1.6, 1.0 }, "pink", { studs = false }),
		P("Head", { 2, 2, 2 }, { 0, 3.8, -3.5 }, "white", { anim = swing({ 0, 3.2, -2.5 }, "X", 4, 1) }),
		P("Muzzle", { 2, 1, 0.6 }, { 0, 3.2, -4.8 }, "pink", { parent = "Head" }),
		P("EyePatch", { 1, 1, 0.1 }, { -0.6, 4.2, -4.55 }, "black", { parent = "Head" }),
		P("Collar", { 2.2, 0.4, 2.2 }, { 0, 3.0, -3.5 }, "red", { parent = "Head" }),
		P("Bell", { 0.6, 0.6, 0.6 }, { 0, 2.5, -4.2 }, "yellow", { parent = "Head", shape = "Ball" })
	)
	pair(p, {
		P("Nostril", { 0.2, 0.4, 0.1 }, { 0.5, 3.3, -5.15 }, "eye", { parent = "Head" }),
		P("Horn", { 0.4, 0.8, 0.4 }, { 0.8, 5.2, -3.5 }, "cream", { parent = "Head" }),
		P("Ear", { 0.8, 0.4, 0.4 }, { 1.4, 4.4, -3.3 }, "black",
			{ parent = "Head", anim = twitch({ 1.0, 4.4, -3.3 }, "Z", 20, 1.8) }),
	})
	eyes(p, 0.6, 4.2, -4.6, 0.5, "Head")
	add(p,
		P("Tail", { 0.4, 1.6, 0.4 }, { 0, 3.0, 2.8 }, "white", { anim = swing({ 0, 3.8, 2.8 }, "Z", 15, 2) }),
		P("Tuft", { 0.6, 0.6, 0.6 }, { 0, 1.9, 2.8 }, "black", { parent = "Tail" })
	)
	return { displayName = "Cow", parts = p }
end)()

Designs.Chicken = (function()
	local p = {}
	add(p, P("Body", { 2, 1.6, 2.4 }, { 0, 2.0, 0.2 }, "white", { root = true }))
	pair(p, {
		P("Foot", { 1, 0.4, 1.2 }, { 0.5, 0.2, -0.2 }, "yellow", { studs = true }),
		P("Leg", { 0.4, 0.8, 0.4 }, { 0.5, 0.8, 0.2 }, "yellow"),
		P("Wing", { 0.4, 1.2, 1.6 }, { 1.2, 2.0, 0.2 }, "white",
			{ anim = twitch({ 1.0, 2.6, 0.2 }, "Z", 35, 2.2) }),
	})
	add(p,
		P("Head", { 1.6, 1.6, 1.6 }, { 0, 3.6, -0.8 }, "white", { anim = swing({ 0, 2.8, -0.4 }, "X", 10, 3) }),
		P("Beak", { 0.8, 0.4, 0.6 }, { 0, 3.6, -1.9 }, "orange", { parent = "Head" }),
		P("Wattle", { 0.4, 0.6, 0.2 }, { 0, 3.1, -1.7 }, "red", { parent = "Head" }),
		P("Comb", { 0.4, 0.4, 1.2 }, { 0, 4.6, -0.8 }, "red", { parent = "Head" }),
		P("CombTipFront", { 0.4, 0.4, 0.4 }, { 0, 5.0, -1.2 }, "red", { parent = "Head" }),
		P("CombTipBack", { 0.4, 0.4, 0.4 }, { 0, 5.0, -0.4 }, "red", { parent = "Head" })
	)
	eyes(p, 0.5, 4.0, -1.6, 0.4, "Head")
	add(p, P("TailFeathers", { 1.2, 1.2, 1.0 }, { 0, 3.4, 1.0 }, "white",
		{ shape = "Wedge", anim = swing({ 0, 2.8, 1.0 }, "Y", 10, 4) }))
	return { displayName = "Chicken", parts = p }
end)()

Designs.Frog = (function()
	local p = {}
	add(p,
		P("Body", { 3, 1.2, 3 }, { 0, 1.0, 0 }, "green", { root = true }),
		P("Base", { 3, 0.4, 3 }, { 0, 0.2, 0 }, "lime"),
		P("Belly", { 2.4, 0.8, 0.2 }, { 0, 1.0, -1.6 }, "lime"),
		P("Head", { 3, 0.8, 2.4 }, { 0, 2.0, -0.4 }, "green"),
		P("HeadSpot", { 1, 0.4, 1 }, { 0, 2.6, 0.3 }, "darkGreen"),
		P("Mouth", { 2, 0.2, 0.1 }, { 0, 1.85, -1.65 }, "darkGreen")
	)
	pair(p, {
		P("BackLeg", { 1, 1.2, 2 }, { 2.0, 0.6, 0.6 }, "green"),
		P("BackSpot", { 1, 0.4, 1 }, { 2.0, 1.4, 1.1 }, "darkGreen"),
		P("BackFoot", { 1, 0.4, 1 }, { 2.0, 0.2, -0.9 }, "lime"),
		P("FrontFoot", { 1, 0.4, 1 }, { 1.0, 0.2, -2.0 }, "lime"),
		P("EyeBump", { 1, 1, 1 }, { 1, 2.9, -1.0 }, "green"),
		P("Cheek", { 0.4, 0.2, 0.1 }, { 1.2, 1.95, -1.65 }, "pink"),
	})
	eyes(p, 1, 2.9, -1.5, 0.4, nil, true)
	return { displayName = "Frog", idle = { mode = "Hop", amp = 0.6, speed = 3 }, parts = p }
end)()

Designs.Penguin = (function()
	local p = {}
	add(p,
		P("Body", { 2.4, 2.8, 2 }, { 0, 1.8, 0 }, "black", { root = true }),
		P("Belly", { 1.6, 2, 0.4 }, { 0, 1.6, -1.2 }, "white"),
		P("Head", { 2, 1.6, 1.8 }, { 0, 4.0, 0 }, "black"),
		P("Face", { 1.6, 1, 0.4 }, { 0, 3.9, -1.1 }, "white"),
		P("Beak", { 0.6, 0.4, 0.6 }, { 0, 3.8, -1.6 }, "orange"),
		P("Scarf", { 2.6, 0.4, 2.2 }, { 0, 3.2, 0 }, "red"),
		P("ScarfTail", { 0.6, 1.2, 0.2 }, { 0.7, 2.6, -1.5 }, "red")
	)
	pair(p, {
		P("Foot", { 1, 0.4, 1.2 }, { 0.6, 0.2, -0.4 }, "orange", { studs = true }),
		P("Flipper", { 0.4, 1.8, 1.2 }, { 1.4, 2.1, 0 }, "black", { anim = swing({ 1.2, 2.9, 0 }, "Z", 15, 4) }),
		P("Blush", { 0.4, 0.2, 0.1 }, { 0.6, 3.7, -1.35 }, "pink"),
	})
	eyes(p, 0.45, 4.2, -1.3, 0.4)
	return { displayName = "Penguin", idle = { mode = "Swing", axis = "Z", amp = 6, speed = 3 }, parts = p }
end)()

Designs.Bunny = (function()
	local p = {}
	add(p, P("Body", { 2.4, 2, 2.8 }, { 0, 1.4, 0.4 }, "white", { root = true }))
	pair(p, {
		P("BackFoot", { 1, 0.4, 1.6 }, { 0.9, 0.2, 0.6 }, "white", { studs = true }),
		P("FrontPaw", { 0.8, 0.4, 0.8 }, { 0.5, 0.2, -1.0 }, "white"),
	})
	add(p,
		P("Head", { 2, 1.6, 1.8 }, { 0, 3.2, -0.6 }, "white", { anim = swing({ 0, 2.4, -0.6 }, "Z", 5, 1.3) }),
		P("Nose", { 0.4, 0.4, 0.2 }, { 0, 3.0, -1.6 }, "pinkDark", { parent = "Head" }),
		P("Tail", { 1, 1, 1 }, { 0, 1.4, 2.1 }, "white", { shape = "Ball" })
	)
	eyes(p, 0.55, 3.5, -1.5, 0.4, "Head")
	pair(p, {
		P("Cheek", { 0.4, 0.2, 0.1 }, { 0.75, 3.0, -1.55 }, "pink", { parent = "Head" }),
		P("Ear", { 0.6, 2, 0.4 }, { 0.5, 5.0, -0.4 }, "white",
			{ parent = "Head", anim = twitch({ 0.5, 4.0, -0.4 }, "Z", 12, 1.5) }),
		P("InnerEar", { 0.4, 1.6, 0.1 }, { 0.5, 5.0, -0.65 }, "pink", { parent = "Ear", sided = true }),
	})
	return { displayName = "Bunny", idle = { mode = "Hop", amp = 0.35, speed = 4 }, parts = p }
end)()

Designs.Fox = (function()
	local p = {}
	add(p, P("Body", { 2, 1.2, 4 }, { 0, 1.8, 0 }, "orange", { root = true }))
	pair(p, {
		P("FrontLeg", { 1, 1.2, 1 }, { 0.5, 0.6, -1.5 }, "black"),
		P("BackLeg", { 1, 1.2, 1 }, { 0.5, 0.6, 1.5 }, "black"),
	})
	add(p,
		P("Chest", { 1.6, 1.2, 0.4 }, { 0, 1.8, -2.2 }, "white"),
		P("Head", { 3, 0.8, 2 }, { 0, 3.6, -2.0 }, "orange", { anim = swing({ 0, 2.4, -2.0 }, "Z", 6, 1.4) }),
		P("Cheeks", { 3, 0.8, 2 }, { 0, 2.8, -2.0 }, "white", { parent = "Head" }),
		P("Snout", { 1.2, 0.8, 1 }, { 0, 2.8, -3.5 }, "white", { parent = "Head" }),
		P("Nose", { 0.6, 0.4, 0.4 }, { 0, 3.4, -3.8 }, "eye", { parent = "Head" })
	)
	eyes(p, 0.8, 3.6, -3.0, 0.5, "Head")
	pair(p, {
		P("Ear", { 0.4, 1.2, 1 }, { 1.0, 4.6, -1.8 }, "orange",
			{ shape = "Wedge", rot = { 0, 90, 0 }, parent = "Head", anim = twitch({ 1.0, 4.0, -1.8 }, "Z", 12, 1.7) }),
	})
	add(p,
		P("Tail", { 1.2, 1.2, 2 }, { 0, 2.54, 2.94 }, "orange",
			{ rot = { -20, 0, 0 }, anim = swing({ 0, 2.2, 2.0 }, "Y", 18, 3) }),
		P("TailTip", { 1.2, 1.2, 0.8 }, { 0, 3.02, 4.26 }, "white", { rot = { -20, 0, 0 }, parent = "Tail" })
	)
	return { displayName = "Fox", parts = p }
end)()

-- Display order for showcases.
Designs.Order = { "Dog", "Cat", "Fox", "Pig", "Cow", "Chicken", "Bunny", "Frog", "Penguin" }

return Designs
