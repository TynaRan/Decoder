local Features = {}

-- Load the cattoware library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/cat"))()
local Window = Library:CreateWindow("AsyncHood", Vector2.new(492, 598), Enum.KeyCode.RightControl)

-- Tabs
local AimbotTab = Window:CreateTab("Aimbot")
local VisualsTab = Window:CreateTab("Visuals")
local MiscTab = Window:CreateTab("Misc")

-- Sections
local AimbotSection = AimbotTab:CreateSector("Aimbot Settings", "left")
local WorldSection = VisualsTab:CreateSector("World", "left")
local MiscSection = MiscTab:CreateSector("Miscellaneous", "left")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Features.Settings = {
    -- Aimbot
    AimbotEnabled = false,
    SmoothingEnabled = true,  -- New smoothing toggle
    AimbotFOV = 100,
    AimbotSmoothness = 0.15,
    TeamCheck = true,
    Prediction = 0.1,
    AimPart = "Head",
    AutoShoot = false,
    AutoShootDelay = 0.1,
    
    -- World
    FullBright = false,
    AmbientLighting = false,
    AmbientColor = Color3.fromRGB(255, 255, 255),
    
    -- Misc
    AntiAFK = false,
    SpinBot = false,
    SpinSpeed = 10
}

-- Timing variables
local lastShotTime = 0

-- Get nearest enemy
function Features:GetNearestEnemy()
    local closestPlayer, closestDistance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Features.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health <= 0 then continue end
            
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local distance = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- Smooth aim function
local function SmoothAim(targetPosition)
    local cameraPosition = Camera.CFrame.Position
    if not Features.Settings.SmoothingEnabled then
        return CFrame.new(cameraPosition, targetPosition)
    end
    
    local delta = (targetPosition - cameraPosition).Unit
    local currentLook = Camera.CFrame.LookVector
    local smooth = Features.Settings.AimbotSmoothness
    
    local smoothedLook = currentLook:Lerp(delta, smooth)
    return CFrame.new(cameraPosition, cameraPosition + smoothedLook)
end

-- Auto-shoot handler with loop
local function HandleAutoShoot()
    while Features.Settings.AutoShoot do
        local character = LocalPlayer.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Handle") then
                tool:Activate()
            end
        end
        wait(Features.Settings.AutoShootDelay)
    end
end

-- Main loop
RunService.RenderStepped:Connect(function()
    -- Visual effects
    if Features.Settings.FullBright then
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").Brightness = 2
    end
    
    if Features.Settings.AmbientLighting then
        game:GetService("Lighting").Ambient = Features.Settings.AmbientColor
    end

    -- Anti-AFK
    if Features.Settings.AntiAFK then
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown("0x65")
        VirtualUser:SetKeyUp("0x65")
    end

    -- Spinbot
    if Features.Settings.SpinBot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Features.Settings.SpinSpeed), 0)
    end

    -- Aimbot core
    if Features.Settings.AimbotEnabled then
        local targetEnemy = Features:GetNearestEnemy()
        if targetEnemy and targetEnemy.Character then
            local targetPart = targetEnemy.Character:FindFirstChild(Features.Settings.AimPart)
            if targetPart then
                local predictedPosition = targetPart.Position + (targetPart.Velocity * Features.Settings.Prediction)
                Camera.CFrame = SmoothAim(predictedPosition)
            end
        end
    end
end)

-- UI Controls
-- Aimbot Section
AimbotSection:AddToggle("Enable Aimbot", false, function(state) 
    Features.Settings.AimbotEnabled = state
end)

AimbotSection:AddToggle("Enable Smoothing", Features.Settings.SmoothingEnabled, function(state)
    Features.Settings.SmoothingEnabled = state
end)

AimbotSection:AddSlider("Smoothness", 0.1, 1, 100, Features.Settings.AimbotSmoothness, function(value)
    Features.Settings.AimbotSmoothness = value
end)

AimbotSection:AddSlider("Aimbot FOV", 1, 500, 100, Features.Settings.AimbotFOV, function(value)
    Features.Settings.AimbotFOV = value
end)

AimbotSection:AddToggle("Team Check", Features.Settings.TeamCheck, function(state)
    Features.Settings.TeamCheck = state
end)

AimbotSection:AddSlider("Prediction", 0, 1, 100, Features.Settings.Prediction, function(value)
    Features.Settings.Prediction = value
end)

AimbotSection:AddDropdown("Aim Part", {"Head", "Torso", "HumanoidRootPart"}, false, function(part)
    Features.Settings.AimPart = part
end)

AimbotSection:AddToggle("Auto Shoot", Features.Settings.AutoShoot, function(state)
    Features.Settings.AutoShoot = state
    if state then
        coroutine.wrap(HandleAutoShoot)()
    end
end)

AimbotSection:AddSlider("Shoot Delay", 0, 1, 100, Features.Settings.AutoShootDelay, function(value)
    Features.Settings.AutoShootDelay = value
end)

-- Visuals Section
WorldSection:AddToggle("Full Bright", Features.Settings.FullBright, function(state)
    Features.Settings.FullBright = state
    if not state then
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").Brightness = 1
    end
end)

WorldSection:AddToggle("Ambient Lighting", Features.Settings.AmbientLighting, function(state)
    Features.Settings.AmbientLighting = state
    if not state then
        game:GetService("Lighting").Ambient = Color3.fromRGB(127, 127, 127)
    end
end)

WorldSection:AddColorpicker("Ambient Color", Features.Settings.AmbientColor, function(color)
    Features.Settings.AmbientColor = color
end)

-- Misc Section
MiscSection:AddToggle("Anti AFK", Features.Settings.AntiAFK, function(state)
    Features.Settings.AntiAFK = state
end)

MiscSection:AddToggle("Spin Bot", Features.Settings.SpinBot, function(state)
    Features.Settings.SpinBot = state
end)

MiscSection:AddSlider("Spin Speed", 1, 50, 100, Features.Settings.SpinSpeed, function(value)
    Features.Settings.SpinSpeed = value
end)

-- Restore default lighting when script ends
game:GetService("Lighting").Changed:Connect(function()
    if not Features.Settings.FullBright then
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").Brightness = 1
    end
    if not Features.Settings.AmbientLighting then
        game:GetService("Lighting").Ambient = Color3.fromRGB(127, 127, 127)
    end
end)
-- ===== CONFIGURATION =====
local ESP_SETTINGS = {
    TextSize = 14,
    TextOffset = Vector2.new(0, -20),
    LineThickness = 1,
    RainbowSpeed = 1, -- Higher = faster color change
    MaxDistance = 1000 -- Only show ESP within this distance (studs)
}

-- Bone connections for humanoid (adjust for different rigs)
local BONE_CONNECTIONS = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

-- ===== CORE FUNCTIONS =====
local function HealthToColor(health, maxHealth)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    return Color3.new(1 - ratio, ratio, 0) -- Red (low) to Green (full)
end

local function RainbowColor(time)
    local r = math.sin(time * ESP_SETTINGS.RainbowSpeed) * 0.5 + 0.5
    local g = math.sin(time * ESP_SETTINGS.RainbowSpeed + 2) * 0.5 + 0.5
    local b = math.sin(time * ESP_SETTINGS.RainbowSpeed + 4) * 0.5 + 0.5
    return Color3.new(r, g, b)
end

local function CreateBoneESP(player)
    local drawings = {}
    
    -- Create lines for bone connections
    for _, connection in ipairs(BONE_CONNECTIONS) do
        local line = Drawing.new("Line")
        line.Thickness = ESP_SETTINGS.LineThickness
        line.Visible = false
        table.insert(drawings, line)
    end
    
    -- Create health text
    local healthText = Drawing.new("Text")
    healthText.Size = ESP_SETTINGS.TextSize
    healthText.Visible = false
    table.insert(drawings, healthText)
    
    return {
        Drawings = drawings,
        Player = player,
        LastUpdate = 0
    }
end

-- ===== UPDATE LOGIC =====
local function UpdateBoneESP()
    local currentTime = os.clock()
    
    for player, data in pairs(ESPCache) do
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("Head") then
            local humanoid = character.Humanoid
            local headPos, headVisible = workspace.CurrentCamera:WorldToViewportPoint(character.Head.Position)
            local distance = (workspace.CurrentCamera.CFrame.Position - character.Head.Position).Magnitude
            
            if headVisible and distance <= ESP_SETTINGS.MaxDistance then
                -- Update bone lines
                local boneIndex = 1
                for _, connection in ipairs(BONE_CONNECTIONS) do
                    local part1 = character:FindFirstChild(connection[1])
                    local part2 = character:FindFirstChild(connection[2])
                    
                    if part1 and part2 then
                        local pos1, vis1 = workspace.CurrentCamera:WorldToViewportPoint(part1.Position)
                        local pos2, vis2 = workspace.CurrentCamera:WorldToViewportPoint(part2.Position)
                        
                        if vis1 and vis2 then
                            local line = data.Drawings[boneIndex]
                            line.From = Vector2.new(pos1.X, pos1.Y)
                            line.To = Vector2.new(pos2.X, pos2.Y)
                            
                            -- Apply color based on health or rainbow effect
                            if Features.Settings.HealthColor then
                                line.Color = HealthToColor(humanoid.Health, humanoid.MaxHealth)
                            elseif Features.Settings.RainbowColor then
                                line.Color = RainbowColor(currentTime)
                            else
                                line.Color = Color3.new(1, 1, 1) -- Default white
                            end
                            
                            line.Visible = true
                            boneIndex = boneIndex + 1
                        end
                    end
                end
                
                -- Update health text
                local healthText = data.Drawings[#data.Drawings]
                healthText.Position = Vector2.new(headPos.X, headPos.Y) + ESP_SETTINGS.TextOffset
                healthText.Text = string.format("%s (%d/%d)", player.Name, humanoid.Health, humanoid.MaxHealth)
                
                if Features.Settings.HealthColor then
                    healthText.Color = HealthToColor(humanoid.Health, humanoid.MaxHealth)
                elseif Features.Settings.RainbowColor then
                    healthText.Color = RainbowColor(currentTime)
                else
                    healthText.Color = Color3.new(1, 1, 1)
                end
                
                healthText.Visible = true
            else
                -- Hide if not visible or too far
                for _, drawing in ipairs(data.Drawings) do
                    drawing.Visible = false
                end
            end
        else
            -- Cleanup invalid entries
            for _, drawing in ipairs(data.Drawings) do
                drawing:Remove()
            end
            ESPCache[player] = nil
        end
    end
end

-- ===== PLAYER MANAGEMENT =====
local function TrackPlayers()
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            ESPCache[player] = CreateBoneESP(player)
        end
    end
    
    game:GetService("Players").PlayerAdded:Connect(function(player)
        ESPCache[player] = CreateBoneESP(player)
    end)
    
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        if ESPCache[player] then
            for _, drawing in ipairs(ESPCache[player].Drawings) do
                drawing:Remove()
            end
            ESPCache[player] = nil
        end
    end)
end

-- ===== UI TOGGLES =====
MiscSection:AddToggle("Bone ESP", Features.Settings.BoneESP, function(state)
    Features.Settings.BoneESP = state
    if state then
        TrackPlayers()
        Features.ESPConnection = game:GetService("RunService").RenderStepped:Connect(UpdateBoneESP)
    else
        if Features.ESPConnection then
            Features.ESPConnection:Disconnect()
        end
        for _, data in pairs(ESPCache) do
            for _, drawing in ipairs(data.Drawings) do
                drawing:Remove()
            end
        end
        ESPCache = {}
    end
end)

MiscSection:AddToggle("Health Color", Features.Settings.HealthColor, function(state)
    Features.Settings.HealthColor = state
    if state then Features.Settings.RainbowColor = false end
end)

MiscSection:AddToggle("Rainbow Color", Features.Settings.RainbowColor, function(state)
    Features.Settings.RainbowColor = state
    if state then Features.Settings.HealthColor = false end
end)
