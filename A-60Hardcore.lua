
---====== Load spawner ======---

local Spawner = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"
))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

---====== Create entity ======---

local entity = Spawner:Create({
    Entity = {
        Name = "A-60",
        Asset = "15455640886",
        HeightOffset = 0
    },

    Lights = {
        Flicker = {
            Enabled = false,
            Duration = 1
        },
        Shatter = true,
        Repair = false
    },

    Earthquake = {
        Enabled = true
    },

    CameraShake = {
        Enabled = true,
        Range = 100,
        Values = {1.5, 20, 0.1, 1}
    },

    Movement = {
        Speed = 300,
        Delay = 2,
        Reversed = false
    },

    Rebounding = {
        Enabled = true,
        Type = "Ambush",
        Min = 4,
        Max = 6,
        Delay = 2
    },

    Damage = {
        Enabled = true,
        IgnoreHiding = false,
        Range = 40,
        Amount = 0.00001
    },

    Crucifixion = {
        Type = "Guiding",
        Enabled = true,
        Range = 40,
        Resist = false,
        Break = true
    },

    Death = {
        Type = "Guiding",
        Hints = {"Death", "Hints", "Go", "Here"},
        Cause = ""
    }
})

---====== Chase variables ======---

local caught = false

---====== Entity callbacks ======---

entity:SetCallback("OnSpawned", function()
    print("Entity has spawned")
end)

entity:SetCallback("OnStartMoving", function()
    print("Entity has started moving")
end)

entity:SetCallback("OnEnterRoom", function(room: Model, firstTime: boolean)
    if firstTime then
        print("Entity has entered room: " .. room.Name .. " for the first time")
    else
        print("Entity has entered room: " .. room.Name .. " again")
    end
end)

entity:SetCallback("OnLookAt", function(lineOfSight: boolean)
    if lineOfSight then
        print("Player is looking at entity")
    else
        print("Player view is obstructed")
    end
end)

entity:SetCallback("OnRebounding", function(startOfRebound: boolean)
    if startOfRebound then
        print("Entity has started rebounding")
    else
        print("Entity has finished rebounding")
    end
end)

entity:SetCallback("OnDespawning", function()
    print("Entity is despawning")
end)

entity:SetCallback("OnDespawned", function()
    print("Entity has despawned")
end)

---====== Chase function ======---

local function ChasePlayer()
    if caught then return end
    caught = true

    print("A-60 is chasing the player!")

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        return
    end

    -- Find spawned A-60 model
    local model = workspace:FindFirstChild("A-60", true)

    if not model then
        warn("Could not find A-60 model!")
        return
    end

    local part = model:IsA("BasePart") and model
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)

    if not part then
        warn("A-60 has no BasePart!")
        return
    end

    -- Stop existing movement forces
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("BodyVelocity")
        or object:IsA("LinearVelocity")
        or object:IsA("BodyPosition")
        or object:IsA("AlignPosition") then
            object:Destroy()
        end
    end

    -- Stop normal entity movement as much as possible
    part.AssemblyLinearVelocity = Vector3.zero

    -- Chase loop
    while model.Parent and humanoid.Health > 0 and root.Parent do
        local currentPosition = part.Position
        local targetPosition = root.Position

        local offset = targetPosition - currentPosition

        if offset.Magnitude > 0.1 then
            local direction = offset.Unit

            -- Face the player
            part.CFrame = CFrame.lookAt(
                currentPosition,
                Vector3.new(
                    targetPosition.X,
                    currentPosition.Y,
                    targetPosition.Z
                )
            )

            -- Move toward player
            part.AssemblyLinearVelocity = direction * 300
        end

        RunService.Heartbeat:Wait()
    end

    print("A-60 chase ended")
end

---====== Damage callback ======---

entity:SetCallback("OnDamagePlayer", function(newHealth: number)
    if newHealth <= 0 then
        print("Entity has killed the player")
        return
    end

    print("Entity has caught the player")

    -- Play scare sound
    local scare = Instance.new("Sound")
    scare.Volume = 10
    scare.RollOffMinDistance = 0
    scare.RollOffMaxDistance = 100000
    scare.SoundId = "rbxassetid://132942725846535"
    scare.Parent = workspace
    scare:Play()

    -- Start chasing
    task.spawn(ChasePlayer)

    -- Kill player after 1 second
    task.wait(1)

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health > 0 then
        humanoid:TakeDamage(100)
    end
end)

---====== Run entity ======---

entity:Run(true)
