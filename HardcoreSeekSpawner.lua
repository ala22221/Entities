local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local SPEED, OFFSET, ROOMS = 20, 1, 10
local Rooms = workspace:WaitForChild("CurrentRooms")
local LatestRoom = RS.GameData.LatestRoom

local Entity = game:GetObjects("rbxassetid://11664451634")[1]
Entity.Parent = workspace

local Root = Entity.PrimaryPart or Entity:FindFirstChildWhichIsA("BasePart", true)
if not Root then Entity:Destroy() return end
Entity.PrimaryPart = Root

for _, v in ipairs(Entity:GetDescendants()) do
    if v:IsA("BasePart") then
        v.CanCollide, v.CanTouch, v.CanQuery, v.Massless, v.Anchored = false, false, false, true, false
    end
end
Root.Anchored = true

local Rig, Figure = Entity:WaitForChild("SeekRig"), Entity:WaitForChild("Figure")
local Controller = Rig:FindFirstChildWhichIsA("Humanoid", true) or Rig:FindFirstChildWhichIsA("AnimationController", true)
if not Controller then Entity:Destroy() return end

local Animator = Controller:FindFirstChildOfClass("Animator") or Instance.new("Animator", Controller)
local Raise = Animator:LoadAnimation(Rig:WaitForChild("AnimRaise"))
local RunTrack = Animator:LoadAnimation(Rig:WaitForChild("AnimRun"))
RunTrack.Looped = true

local Sounds = {
    Figure:WaitForChild("FootseptsFar"),
    Figure:WaitForChild("Footsteps")
}

local Volumes = {}
for i, sound in ipairs(Sounds) do
    Volumes[i] = sound.Volume
    sound.Volume = 0
end

local Cam1, Cam2 = Figure:WaitForChild("CamPos1"), Figure:WaitForChild("CamPos2")
local function WorldCF(v)
    return v:IsA("Attachment") and v.WorldCFrame or v.CFrame
end

local function Cutscene()
    local oldCF, oldFOV = Camera.CFrame, Camera.FieldOfView
    local oldType, oldSubject = Camera.CameraType, Camera.CameraSubject
    Camera.CameraType = Enum.CameraType.Scriptable

    local function Move(a, b, f1, f2, duration, style)
        local start = os.clock()
        while os.clock() - start < duration do
            local alpha = math.clamp((os.clock() - start) / duration, 0, 1)
            local eased = TS:GetValue(alpha, style, Enum.EasingDirection.InOut)
            Camera.CFrame = a:Lerp(b, eased)
            Camera.FieldOfView = f1 + (f2 - f1) * eased
            Run.RenderStepped:Wait()
        end
        Camera.CFrame, Camera.FieldOfView = b, f2
    end

    local a, b = WorldCF(Cam1), WorldCF(Cam2)
    Move(oldCF, a, oldFOV, 30, 1, Enum.EasingStyle.Quad)
    Move(a, b, 30, 60, 6.25, Enum.EasingStyle.Exponential)
    Move(b, oldCF, 60, oldFOV, 1, Enum.EasingStyle.Quad)

    Camera.CameraType, Camera.CameraSubject = oldType, oldSubject
    Camera.CFrame, Camera.FieldOfView = oldCF, oldFOV
end

local function Adjust(cf)
    return cf + Vector3.new(0, OFFSET, 0)
end

local function GetNodes(room)
    local nodes, folder = {}, room:FindFirstChild("PathfindNodes")
    if folder then
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("BasePart") then table.insert(nodes, v) end
        end
    end

    table.sort(nodes, function(a, b)
        return (tonumber(a.Name) or math.huge) < (tonumber(b.Name) or math.huge)
    end)

    if #nodes == 0 then
        for _, name in ipairs({"RoomEntrance", "RoomExit"}) do
            local v = room:FindFirstChild(name)
            if v and v:IsA("BasePart") then table.insert(nodes, v) end
        end
    end
    return nodes
end

local function MoveTo(node)
    local target = Adjust(node.CFrame)
    local start, finish = Entity:GetPivot().Position, target.Position
    local duration = (finish - start).Magnitude / SPEED
    local began = os.clock()

    while Entity.Parent do
        local alpha = math.clamp((os.clock() - began) / math.max(duration, 0.001), 0, 1)
        local pos, dir = start:Lerp(finish, alpha), finish - start
        if dir.Magnitude > 0.01 then
            Entity:PivotTo(CFrame.lookAt(pos, pos + dir.Unit))
        end
        if alpha >= 1 then break end
        Run.Heartbeat:Wait()
    end
    Entity:PivotTo(target)
end

local startRoom = LatestRoom.Value
local first = Rooms:WaitForChild(tostring(startRoom), 30)
if not first then Entity:Destroy() return end

local entrance = first:WaitForChild("RoomEntrance", 10)
if not entrance then Entity:Destroy() return end
Entity:PivotTo(Adjust(entrance.CFrame))

Raise:Play()
task.spawn(function() pcall(Cutscene) end)
Raise.Stopped:Wait()

if not Entity.Parent then return end
for i, sound in ipairs(Sounds) do sound.Volume = Volumes[i] end
RunTrack:Play()


local Roar = Figure:WaitForChild("Roar")
Roar.Volume = 3

task.spawn(function()
    while Entity.Parent do
        Roar:Play()
        task.wait(math.random(2, 4))
    end
end)
Figure:WaitForChild("Knock").PlayOnRemove = true

if not Entity.Parent then return end

for number = startRoom, startRoom + ROOMS - 1 do
    if not Entity.Parent then return end
    local room = Rooms:FindFirstChild(tostring(number)) or Rooms:WaitForChild(tostring(number), 60)
    if not room then break end

    for _, node in ipairs(GetNodes(room)) do
        if not Entity.Parent then return end
        MoveTo(node)
    end
end

RunTrack:Stop()
Entity:Destroy()
