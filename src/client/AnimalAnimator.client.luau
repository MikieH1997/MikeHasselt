--[[
	AnimalAnimator
	Procedural idle animation for every model tagged "StudAnimal".

	Each Motor6D built by StudAnimals carries attributes:
	  Mode       "Swing"  smooth back-and-forth rotation
	             "Twitch" mostly still, with a quick flick now and then
	             "Bob"    smooth up/down movement
	             "Hop"    little jumps with a pause between them
	             "None"   no motion
	  Axis       "X" | "Y" | "Z"
	  Amplitude  degrees (Swing/Twitch) or studs (Bob/Hop)
	  Speed      radians per second
	  Phase      offset in radians

	Runs on the client only, so it costs the server nothing and stays smooth.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TAG = "StudAnimal"
local MAX_DISTANCE = 200 -- skip animals further than this from the camera

type Track = {
	motor: Motor6D,
	base: CFrame,
	mode: string,
	axis: Vector3,
	amp: number,
	speed: number,
	phase: number,
}

type Animal = {
	model: Model,
	tracks: { Track },
	offset: number, -- desync animals so they don't move in lockstep
}

local AXES = { X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis }

local animals: { [Model]: Animal } = {}

local function readTrack(motor: Motor6D): Track?
	local mode = motor:GetAttribute("Mode")
	if type(mode) ~= "string" or mode == "None" then
		return nil
	end
	return {
		motor = motor,
		base = motor.C0,
		mode = mode,
		axis = AXES[motor:GetAttribute("Axis") or "Y"] or Vector3.yAxis,
		amp = motor:GetAttribute("Amplitude") or 0,
		speed = motor:GetAttribute("Speed") or 1,
		phase = motor:GetAttribute("Phase") or 0,
	}
end

local function track(model: Instance)
	if not model:IsA("Model") or animals[model] then
		return
	end
	local tracks = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			local t = readTrack(d)
			if t then
				table.insert(tracks, t)
			end
		end
	end
	animals[model] = { model = model, tracks = tracks, offset = math.random() * 10 }
end

local function untrack(model: Instance)
	local animal = animals[model :: Model]
	if not animal then
		return
	end
	for _, t in animal.tracks do
		if t.motor.Parent then
			t.motor.C0 = t.base
		end
	end
	animals[model :: Model] = nil
end

local function pose(t: Track, time: number, scale: number): CFrame
	local x = time * t.speed + t.phase
	if t.mode == "Swing" then
		return CFrame.fromAxisAngle(t.axis, math.rad(t.amp * math.sin(x)))
	elseif t.mode == "Twitch" then
		-- A sharp peak once per cycle: still most of the time, then a flick.
		local s = math.max(0, math.sin(x)) ^ 12
		return CFrame.fromAxisAngle(t.axis, math.rad(t.amp * s))
	elseif t.mode == "Bob" then
		return CFrame.new(t.axis * t.amp * scale * math.sin(x))
	elseif t.mode == "Hop" then
		local s = math.max(0, math.sin(x))
		return CFrame.new(t.axis * t.amp * scale * s)
	end
	return CFrame.identity
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(untrack)
for _, model in CollectionService:GetTagged(TAG) do
	track(model)
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local camPos = camera.CFrame.Position
	local now = os.clock()

	for model, animal in animals do
		if not model.Parent then
			continue
		end
		local root = model.PrimaryPart
		if not root or (root.Position - camPos).Magnitude > MAX_DISTANCE then
			continue
		end
		local scale = model:GetScale()
		local time = now + animal.offset
		for _, t in animal.tracks do
			t.motor.C0 = t.base * pose(t, time, scale)
		end
	end
end)
