--[[
	StudAnimals
	Builds clean, blocky animals out of classic studded bricks.

	    local StudAnimals = require(ReplicatedStorage.StudAnimals)
	    local dog = StudAnimals.Build("Dog", {
	        cframe = CFrame.new(0, 0, 0),   -- ground position (feet), facing LookVector
	        scale = 1,                      -- optional, uses Model:ScaleTo
	        parent = workspace,             -- optional
	    })

	Every animal gets an invisible, anchored "Root" hitbox. The body hangs off it
	with a Motor6D ("Idle") and moving parts (heads, tails, ears...) hang off the
	body with their own Motor6Ds, so the AnimalAnimator client script can animate
	them without ever fighting the server over position.
]]

local CollectionService = game:GetService("CollectionService")

local Designs = require(script.Designs)
local Palette = require(script.Palette)

local StudAnimals = {}

StudAnimals.TAG = "StudAnimal"
StudAnimals.Designs = Designs
StudAnimals.Palette = Palette

local SIDES = { "Front", "Back", "Left", "Right" }

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function color(key: string): Color3
	local c = Palette[key]
	assert(c, `StudAnimals: unknown palette colour "{key}"`)
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function placement(def): CFrame
	local cf = CFrame.new(vec(def.pos))
	if def.rot then
		cf *= CFrame.Angles(math.rad(def.rot[1]), math.rad(def.rot[2]), math.rad(def.rot[3]))
	end
	return cf
end

local function makeBrick(def): BasePart
	local part: BasePart
	if def.shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		if def.shape == "Ball" then
			p.Shape = Enum.PartType.Ball
		end
		part = p
	end

	part.Name = def.name
	part.Size = vec(def.size)
	part.CFrame = placement(def)
	part.Color = color(def.color)
	part.Material = Enum.Material.Plastic

	-- Classic look: studs on top, inlets underneath, smooth everywhere else.
	local studs = def.studs
	if studs == nil then
		studs = def.shape == nil and def.size[1] >= 1 and def.size[3] >= 1
	end
	for _, side in SIDES do
		(part :: any)[side .. "Surface"] = Enum.SurfaceType.Smooth
	end
	part.TopSurface = if studs then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	part.BottomSurface = if studs then Enum.SurfaceType.Inlet else Enum.SurfaceType.Smooth

	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	return part
end

local function joint(part0: BasePart, part1: BasePart, pivot: CFrame, anim): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = part1.Name .. "Joint"
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = part0.CFrame:Inverse() * pivot
	motor.C1 = part1.CFrame:Inverse() * pivot
	motor:SetAttribute("Mode", anim.mode or "Swing")
	motor:SetAttribute("Axis", anim.axis or "Y")
	motor:SetAttribute("Amplitude", anim.amp or 0)
	motor:SetAttribute("Speed", anim.speed or 1)
	motor:SetAttribute("Phase", anim.phase or 0)
	motor.Parent = part1
	return motor
end

local function weld(part0: BasePart, part1: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = part1
end

--- Names of every available animal, in showcase order.
function StudAnimals.List(): { string }
	return table.clone(Designs.Order)
end

export type BuildOptions = {
	cframe: CFrame?,
	scale: number?,
	parent: Instance?,
	name: string?,
	animate: boolean?, -- set false to skip idle/part animation
}

--- Build an animal model. It is anchored at its invisible Root.
function StudAnimals.Build(animal: string, options: BuildOptions?): Model
	local opts = options or {}
	local design = Designs[animal]
	assert(type(design) == "table" and design.parts, `StudAnimals: unknown animal "{animal}"`)

	local model = Instance.new("Model")
	model.Name = opts.name or design.displayName or animal
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	-- 1. Bricks, built at the origin facing -Z.
	local bricks: { [string]: BasePart } = {}
	local body: BasePart? = nil
	for _, def in design.parts do
		local part = makeBrick(def)
		bricks[def.name] = part
		part.Parent = model
		if def.root then
			body = part
		end
	end
	assert(body, `StudAnimals: "{animal}" has no root brick`)

	-- 2. Invisible root hitbox around the whole animal.
	local boxCFrame, boxSize = model:GetBoundingBox()
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = boxSize
	root.CFrame = CFrame.new(boxCFrame.Position)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true
	root.CanTouch = false
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Parent = model
	model.PrimaryPart = root
	-- Pivot at ground level, centre of the animal, so PivotTo plants its feet.
	root.PivotOffset = root.CFrame:Inverse()

	-- 3. Joints: Root -> Body (idle motion) -> everything else.
	joint(root, body, CFrame.new(), design.idle or { mode = "None" })
	for _, def in design.parts do
		local part = bricks[def.name]
		if part ~= body then
			local parent = if def.parent then bricks[def.parent] else body
			assert(parent, `StudAnimals: "{def.name}" has unknown parent "{def.parent}"`)
			if def.anim then
				joint(parent, part, CFrame.new(vec(def.anim.pivot)), def.anim)
			else
				weld(parent, part)
			end
		end
	end

	-- 4. Size, place, tag.
	if opts.scale and opts.scale ~= 1 then
		model:ScaleTo(opts.scale)
	end
	model:PivotTo(opts.cframe or CFrame.new())
	model:SetAttribute("Animal", animal)
	if opts.animate ~= false then
		CollectionService:AddTag(model, StudAnimals.TAG)
	end
	if opts.parent then
		model.Parent = opts.parent
	end
	return model
end

return StudAnimals
