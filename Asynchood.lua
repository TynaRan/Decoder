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
-- Bone ESP Implementation (Full Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local BONE_ESP_SETTINGS = {
    Enabled = true,
    TeamCheck = true,
    EnemyColor = Color3.fromRGB(255, 50, 50),
    TeamColor = Color3.fromRGB(50, 255, 50),
    BoneThickness = 1,
    BoneTransparency = 0.5,
    BoneNames = {
        "Head", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot"
    },
    BoneConnections = {
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
}

-- Storage
local BoneESP = {
    Drawings = {},
    Connections = {}
}

-- Create a bone drawing
local function CreateBoneDrawing()
    local drawing = Drawing.new("Line")
    drawing.Thickness = BONE_ESP_SETTINGS.BoneThickness
    drawing.Transparency = BONE_ESP_SETTINGS.BoneTransparency
    drawing.Visible = false
    return drawing
end

-- Initialize player bones
local function InitPlayerBones(player)
    if player == LocalPlayer then return end
    
    BoneESP.Drawings[player] = {
        Bones = {},
        Connections = {}
    }
    
    -- Create bone drawings
    for _, boneName in pairs(BONE_ESP_SETTINGS.BoneNames) do
        BoneESP.Drawings[player].Bones[boneName] = CreateBoneDrawing()
    end
    
    -- Create connection drawings
    for _, connection in pairs(BONE_ESP_SETTINGS.BoneConnections) do
        table.insert(BoneESP.Drawings[player].Connections, {
            Drawing = CreateBoneDrawing(),
            From = connection[1],
            To = connection[2]
        })
    end
    
    -- Character added event
    BoneESP.Drawings[player].CharacterAdded = player.CharacterAdded:Connect(function(character)
        UpdatePlayerBones(player, character)
    end)
    
    -- Character removal
    BoneESP.Drawings[player].CharacterRemoving = player.CharacterRemoving:Connect(function()
        CleanupPlayerBones(player)
    end)
    
    -- Initial setup if character exists
    if player.Character then
        UpdatePlayerBones(player, player.Character)
    end
end

-- Update bone positions
local function UpdatePlayerBones(player, character)
    if not BoneESP.Drawings[player] then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        CleanupPlayerBones(player)
        return
    end
    
    -- Update bone positions
    for boneName, drawing in pairs(BoneESP.Drawings[player].Bones) do
        local part = character:FindFirstChild(boneName)
        if part then
            local position, visible = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
            if visible then
                drawing.Visible = true
                drawing.From = Vector2.new(position.X, position.Y)
                drawing.To = Vector2.new(position.X, position.Y)
                drawing.Color = BONE_ESP_SETTINGS.TeamCheck and player.Team == LocalPlayer.Team 
                    and BONE_ESP_SETTINGS.TeamColor or BONE_ESP_SETTINGS.EnemyColor
            else
                drawing.Visible = false
            end
        else
            drawing.Visible = false
        end
    end
    
    -- Update bone connections
    for _, connection in pairs(BoneESP.Drawings[player].Connections) do
        local fromPart = character:FindFirstChild(connection.From)
        local toPart = character:FindFirstChild(connection.To)
        
        if fromPart and toPart then
            local fromPos, fromVisible = workspace.CurrentCamera:WorldToViewportPoint(fromPart.Position)
            local toPos, toVisible = workspace.CurrentCamera:WorldToViewportPoint(toPart.Position)
            
            if fromVisible and toVisible then
                connection.Drawing.Visible = true
                connection.Drawing.From = Vector2.new(fromPos.X, fromPos.Y)
                connection.Drawing.To = Vector2.new(toPos.X, toPos.Y)
                connection.Drawing.Color = BONE_ESP_SETTINGS.TeamCheck and player.Team == LocalPlayer.Team 
                    and BONE_ESP_SETTINGS.TeamColor or BONE_ESP_SETTINGS.EnemyColor
            else
                connection.Drawing.Visible = false
            end
        else
            connection.Drawing.Visible = false
        end
    end
end

--- Cleanup player bones
local function CleanupPlayerBones(player)
    if not BoneESP.Drawings[player] then return end
    
    -- Disconnect events
    if BoneESP.Drawings[player].CharacterAdded then
        BoneESP.Drawings[player].CharacterAdded:Disconnect()
    end
    if BoneESP.Drawings[player].CharacterRemoving then
        BoneESP.Drawings[player].CharacterRemoving:Disconnect()
    end
    
    -- Remove drawings
    for _, drawing in pairs(BoneESP.Drawings[player].Bones) do
        drawing:Remove()
    end
    for _, connection in pairs(BoneESP.Drawings[player].Connections) do
        connection.Drawing:Remove()
    end
    
    BoneESP.Drawings[player] = nil
end

-- Main update loop
local function BoneESPUpdate()
    for player, data in pairs(BoneESP.Drawings) do
        if player and player.Character then
            UpdatePlayerBones(player, player.Character)
        else
            CleanupPlayerBones(player)
        end
    end
end

-- Initialize all players
local function InitAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        InitPlayerBones(player)
    end
    
    -- Player added event
    table.insert(BoneESP.Connections, Players.PlayerAdded:Connect(InitPlayerBones))
    
    -- Player leaving event
    table.insert(BoneESP.Connections, Players.PlayerRemoving:Connect(function(player)
        CleanupPlayerBones(player)
    end))
end

-- Toggle function
local function ToggleBoneESP(state)
    BONE_ESP_SETTINGS.Enabled = state
    
    if state then
        -- Initialize
        InitAllPlayers()
        table.insert(BoneESP.Connections, RunService.Heartbeat:Connect(BoneESPUpdate))
    else
        -- Cleanup
        for _, connection in ipairs(BoneESP.Connections) do
            connection:Disconnect()
        end
        BoneESP.Connections = {}
        
        for player in pairs(BoneESP.Drawings) do
            CleanupPlayerBones(player)
        end
        BoneESP.Drawings = {}
    end
end

-- Create toggle in your UI
MiscSection:AddToggle("Bone ESP", BONE_ESP_SETTINGS.Enabled, function(state)
    ToggleBoneESP(state)
end)

-- Initial setup if enabled
if BONE_ESP_SETTINGS.Enabled then
    ToggleBoneESP(true)
end
