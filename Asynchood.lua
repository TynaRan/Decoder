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
local WorldRightSector = VisualsTab:CreateSector("ESP", "right")

local PlayerEsp = {
    Box = {Enabled = false, Instances = {}},
    Skeleton = {Enabled = false, Connections = {}},
    Health = {Enabled = false, Bars = {}},
    Distance = {Enabled = false, Tags = {}}
}

WorldRightSector:AddToggle("3D Box", false, function(state)
    PlayerEsp.Box.Enabled = state
    if state then
        game:GetService("RunService").Heartbeat:Connect(function()
            for _, target in pairs(Players:GetPlayers()) do
                if target ~= LocalPlayer then
                    if not PlayerEsp.Box.Instances[target] then
                        PlayerEsp.Box.Instances[target] = {
                            FrontQuad = CreateQuadrilateral(),
                            BackQuad = CreateQuadrilateral(),
                            Connectors = CreateConnectionLines()
                        }
                    end
                    UpdateBoxVisuals(target)
                end
            end
        end)
    else
        for _, box in pairs(PlayerEsp.Box.Instances) do
            DestroyDrawingObjects(box)
        end
        PlayerEsp.Box.Instances = {}
    end
end)

WorldRightSector:AddToggle("Dynamic Health", false, function(state)
    PlayerEsp.Health.Enabled = state
    if state then
        game:GetService("RunService").Heartbeat:Connect(function()
            for _, target in pairs(Players:GetPlayers()) do
                if ValidTarget(target) then
                    if not PlayerEsp.Health.Bars[target] then
                        PlayerEsp.Health.Bars[target] = {
                            Background = CreateHealthBarBase(),
                            Foreground = CreateHealthBarFill(),
                            Text = CreateHealthText()
                        }
                    end
                    UpdateHealthDisplay(target)
                end
            end
        end)
    else
        ClearHealthComponents()
    end
end)

local function UpdateBoxVisuals(plr)
    local character = plr.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local boxData = character:GetBoundingBox()
        local corners = CalculateBoundingCorners(boxData)
        
        for i, corner in pairs(corners) do
            local screenPos = Camera:WorldToViewportPoint(corner)
            if screenPos.Z > 0 then
                local drawingIndex = "Line"..i
                PlayerEsp.Box.Instances[plr][drawingIndex].From = Vector2.new(screenPos.X, screenPos.Y)
                PlayerEsp.Box.Instances[plr][drawingIndex].To = Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    end
end

local function UpdateHealthDisplay(plr)
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    if humanoid then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local position = CalculateHealthBarPosition(plr)
        
        PlayerEsp.Health.Bars[plr].Foreground.Size = Vector2.new(
            healthPercent * PlayerEsp.Health.Settings.Width, 
            PlayerEsp.Health.Settings.Height
        )
        PlayerEsp.Health.Bars[plr].Text.Text = math.floor(humanoid.Health)
        ApplyPositionJitter(PlayerEsp.Health.Bars[plr])
    end
end

game:GetService("RunService").Heartbeat:Connect(function()
    if PlayerEsp.Box.Enabled then
        ApplyRandomOffset(PlayerEsp.Box.Instances)
    end
    if PlayerEsp.Health.Enabled then
        ApplyColorVariation(PlayerEsp.Health.Bars)
    end
end)
