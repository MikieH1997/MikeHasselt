--[[
	AnimalShowcase
	Lays out every StudAnimal on its own studded pedestal in a ring around the
	spawn, each one facing the middle, with a floating name tag.

	Tweak the settings below, or delete this script and call
	StudAnimals.Build yourself wherever you need an animal.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StudAnimals = require(ReplicatedStorage:WaitForChild("StudAnimals"))

local SETTINGS = {
	center = Vector3.new(0, 0, 0), -- ring centre (ground level)
	radius = 28,
	scale = 1.5,
	padSize = 10, -- studs (pads are 10x10 studded plates)
	padHeight = 1.2, -- one classic brick tall
	padColor = Color3.fromRGB(64, 66, 74),
	trimColor = Color3.fromRGB(242, 243, 243),
}

local function studs(part: BasePart)
	part.Material = Enum.Material.Plastic
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Inlet
	part.Anchored = true
end

local function makePedestal(cframe: CFrame, parent: Instance): CFrame
	local s = SETTINGS
	local trim = Instance.new("Part")
	trim.Name = "Trim"
	trim.Size = Vector3.new(s.padSize + 1, 0.4, s.padSize + 1)
	trim.CFrame = cframe * CFrame.new(0, 0.2, 0)
	trim.Color = s.trimColor
	studs(trim)
	trim.Parent = parent

	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Size = Vector3.new(s.padSize, s.padHeight, s.padSize)
	pad.CFrame = cframe * CFrame.new(0, 0.4 + s.padHeight / 2, 0)
	pad.Color = s.padColor
	studs(pad)
	pad.Parent = parent

	-- Animals stand on top of the pad.
	return cframe * CFrame.new(0, 0.4 + s.padHeight, 0)
end

local function makeNameTag(model: Model, text: string)
	local _, size = model:GetBoundingBox()

	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(140, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(0, size.Y / 2 + 1.5, 0)
	gui.MaxDistance = 80
	gui.AlwaysOnTop = false
	gui.Adornee = model.PrimaryPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(27, 42, 53)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = label

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = label

	gui.Parent = model.PrimaryPart
end

local folder = Instance.new("Folder")
folder.Name = "AnimalShowcase"
folder.Parent = workspace

local names = StudAnimals.List()
for i, name in names do
	local angle = (i - 1) / #names * math.pi * 2
	local position = SETTINGS.center + Vector3.new(math.sin(angle), 0, math.cos(angle)) * SETTINGS.radius
	-- Animals face -Z (LookVector), so look toward the centre.
	local base = CFrame.lookAt(position, Vector3.new(SETTINGS.center.X, position.Y, SETTINGS.center.Z))

	local stand = Instance.new("Model")
	stand.Name = name
	stand.Parent = folder

	local top = makePedestal(base, stand)
	local animal = StudAnimals.Build(name, { cframe = top, scale = SETTINGS.scale })
	animal.Parent = stand
	makeNameTag(animal, animal.Name)
end
