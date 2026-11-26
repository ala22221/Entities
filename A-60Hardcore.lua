local Spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/DOORS-Entity-Spawner-V2/main/init.luau"))()
local Player = game:GetService("Players").LocalPlayer

local caught = false
local soundConnection
local savedSounds = {}

local entity = Spawner:Create({
    Entity = {
        Name = "A-60",
        Asset = "15455640886",
        HeightOffset = 0
    },

    Lights = {
        Flicker = {Enabled = false, Duration = 1},
        Shatter = true,
        Repair = false
    },

    Earthquake = {Enabled = true},
    CameraShake = {Enabled = true, Range = 100, Values = {1.5, 20, 0.1, 1}},
    Movement = {Speed = 300, Delay = 2, Reversed = false},
    Rebounding = {Enabled = true, Type = "Ambush", Min = 4, Max = 6, Delay = 2},
    Damage = {Enabled = true, IgnoreHiding = false, Range = 40, Amount = 0},
    Crucifixion = {Type = "Guiding", Enabled = true, Range = 40, Resist = false, Break = true},

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

local function stopSounds(model)
    local function stop(obj)
        if obj:IsA("Sound") then
            if savedSounds[obj] == nil then
                savedSounds[obj] = obj.Volume
            end
            obj:Stop()
            obj.Volume = 0
        end
    end

    for _, obj in ipairs(model:GetDescendants()) do
        stop(obj)
    end

    if soundConnection then soundConnection:Disconnect() end
    soundConnection = model.DescendantAdded:Connect(stop)
end

local function resumeSounds()
    if soundConnection then
        soundConnection:Disconnect()
        soundConnection = nil
    end

    for sound, volume in pairs(savedSounds) do
        if sound.Parent then
            sound.Volume = volume
            sound:Play()
        end
    end

    table.clear(savedSounds)
end

entity:SetCallback("OnDespawned", function()
    resumeSounds()
end)

entity:SetCallback("OnDamagePlayer", function()
    if caught then return end
    caught = true

    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local model = entity.Model

    if not humanoid or not root or not model or not model.Parent then return end

    entity:Pause()
    stopSounds(model)

    local target = root.Position
    model:PivotTo(CFrame.lookAt(target + root.CFrame.LookVector * 3, target))

    local scare = Instance.new("Sound")
    scare.SoundId = "rbxassetid://132942725846535"
    scare.Volume = 1
    scare.RollOffMaxDistance = 100000
    scare.Parent = workspace
    scare:Play()

    task.wait(1)

    if humanoid.Health > 0 then
        pcall(function()
            humanoid:TakeDamage(100)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ala22221/entityjumpscares/refs/heads/main/Rnda60scare.lua"))()
        end)
    end

    resumeSounds()
    entity:Resume()
end)

entity:Run(true)
