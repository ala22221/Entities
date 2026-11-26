
---====== Load spawner ======---

local Spawner = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"
))()

local Players = game:GetService("Players")

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
        Delay = 4,
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
        Amount = 0
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
        Hints = {
            "You have died to an entity designated as A-60",
            "It can Apear at any moment",
            "When it appears there will be a loud scream",
            "It is like Ambush"
        },
        Cause = "A-60"
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

---====== Stop and teleport A-60 ======---

local function ChasePlayer()
    if caught then return end
    caught = true

    print("A-60 caught the player!")

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        warn("Victim not found")
        return
    end

    -- Find spawned A-60
    local model = workspace:FindFirstChild("A-60", true)

    if not model then
        warn("A-60 model not found")
        return
    end

    local part = model:IsA("BasePart") and model
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)

    if not part then
        warn("A-60 has no BasePart")
        return
    end

    -- Remove movement controllers
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("BodyVelocity")
        or object:IsA("BodyPosition")
        or object:IsA("BodyGyro")
        or object:IsA("BodyAngularVelocity")
        or object:IsA("LinearVelocity")
        or object:IsA("AngularVelocity")
        or object:IsA("AlignPosition")
        or object:IsA("AlignOrientation")
        or object:IsA("VectorForce") then
            object:Destroy()
        end
    end

    -- Stop and anchor every part
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("BasePart") then
            object.AssemblyLinearVelocity = Vector3.zero
            object.AssemblyAngularVelocity = Vector3.zero
            object.Anchored = true
        end
    end

    -- Teleport in front of player
    local targetPosition = root.Position
    local teleportPosition = targetPosition + root.CFrame.LookVector * 3

    local destination = CFrame.lookAt(
        teleportPosition,
        targetPosition
    )

    if model:IsA("Model") then
        model:PivotTo(destination)
    else
        part.CFrame = destination
    end

    print("A-60 stopped and teleported to victim!")
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
    scare.Volume = 1
    scare.RollOffMinDistance = 0
    scare.RollOffMaxDistance = 100000
    scare.SoundId = "rbxassetid://132942725846535"
    scare.Parent = workspace
    scare:Play()

    -- Stop and teleport A-60
    task.spawn(ChasePlayer)

    -- Wait before jumpscare and damage
    task.wait(1)

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health > 0 then
        -- Custom A-60 jumpscare
        local success, err = pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/ala22221/entityjumpscares/refs/heads/main/Rnda60scare.lua"
            ))()
        end)

        if not success then
            warn("A-60 jumpscare error: " .. tostring(err))
        end

        humanoid:TakeDamage(100)
    end
end)

---====== Run entity ======---

entity:Run(true)
