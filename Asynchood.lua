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
-- Ultra-Compact Billboard ESP (Feature-Packed)
local plrs,ws,rs,cp = game:GetService("Players"),workspace,game:GetService("RunService"),game:GetService("CorePackages")
local lp,cc = plrs.LocalPlayer,ws.CurrentCamera
local espCache,conns = {},{}

-- Config (Edit these!)
local cfg = {
    TeamColor = true,          -- Use team colors
    HealthColor = true,        -- Health-based coloring
    ShowName = true,           -- Display player name
    ShowHealth = true,         -- Show health bar
    ShowDistance = true,       -- Display distance
    MaxDist = 1000,            -- Max render distance
    UpdateRate = 0.1,          -- Update interval
    HealthGradient = {         -- Health color gradient
        {1,Color3.new(0,1,0)},    -- 100% Green
        {0.5,Color3.new(1,1,0)},  -- 50% Yellow
        {0.2,Color3.new(1,0,0)}   -- 20% Red
    }
}

-- Main Functions
local function lerpColor(t) for i=1,#cfg.HealthGradient-1 do local l,u=cfg.HealthGradient[i+1],cfg.HealthGradient[i]
    if t>=l[1]then return l[2]:Lerp(u[2],(t-l[1])/(u[1]-l[1])end end return cfg.HealthGradient[#cfg.HealthGradient][2] end

local function updateESP()
    for p,esp in pairs(espCache) do
        if p and p.Character and esp.billboard then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health>0 then
                local dist = (hrp.Position-cc.CFrame.Position).Magnitude
                if dist < cfg.MaxDist then
                    local isTeam = cfg.TeamColor and p.Team==lp.Team
                    local color = isTeam and Color3.new(0,1,0) or cfg.HealthColor and lerpColor(hum.Health/hum.MaxHealth) or Color3.new(1,0,0)
                    
                    -- Update billboard
                    esp.billboard.Enabled = true
                    esp.billboard.Adornee = hrp
                    esp.billboard.TextLabel.Text = (cfg.ShowName and p.Name.."\n" or "")..
                                                  (cfg.ShowHealth and "HP: "..math.floor(hum.Health).."/"..math.floor(hum.MaxHealth).."\n" or "")..
                                                  (cfg.ShowDistance and string.format("Dist: %.1fm",dist) or "")
                    esp.billboard.TextLabel.TextColor3 = color
                    
                    -- Health bar visualization
                    if esp.healthBar then
                        local perc = hum.Health/hum.MaxHealth
                        esp.healthBar.Size = UDim2.new(0.1,0,perc*2,0)
                        esp.healthBar.Position = UDim2.new(0.5,0,1-perc,0)
                        esp.healthBar.BackgroundColor3 = color
                    end
                else esp.billboard.Enabled = false end
            else esp.billboard.Enabled = false end
        end
    end
end

local function setupPlayer(p)
    if p==lp then return end
    espCache[p] = {
        billboard = Instance.new("BillboardGui"),
        healthBar = Instance.new("Frame")
    }
    local esp = espCache[p]
    
    -- Configure billboard
    esp.billboard.Name = p.Name.."_ESP"
    esp.billboard.Size = UDim2.new(0,200,0,50)
    esp.billboard.StudsOffset = Vector3.new(0,3,0)
    esp.billboard.AlwaysOnTop = true
    esp.billboard.Adornee = nil
    esp.billboard.Parent = cp
    
    -- Text label
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.TextStrokeTransparency = 0.5
    txt.TextStrokeColor3 = Color3.new(0,0,0)
    txt.Font = Enum.Font.SourceSansBold
    txt.TextSize = 18
    txt.Parent = esp.billboard
    
    -- Health bar
    esp.healthBar.Name = "HealthBar"
    esp.healthBar.AnchorPoint = Vector2.new(0.5,1)
    esp.healthBar.Size = UDim2.new(0.1,0,2,0)
    esp.healthBar.Position = UDim2.new(0.5,0,1,0)
    esp.healthBar.BorderSizePixel = 0
    esp.healthBar.BackgroundColor3 = Color3.new(1,0,0)
    esp.healthBar.Parent = esp.billboard
    
    -- Character tracking
    p.CharacterAdded:Connect(function(c)
        if esp.billboard then esp.billboard.Adornee = c:WaitForChild("HumanoidRootPart",3) end
    end)
    if p.Character then esp.billboard.Adornee = p.Character:FindFirstChild("HumanoidRootPart") end
end

-- Init/cleanup
local function toggleESP(b)
    if b then
        for _,p in ipairs(plrs:GetPlayers()) do setupPlayer(p) end
        table.insert(conns,plrs.PlayerAdded:Connect(setupPlayer))
        table.insert(conns,plrs.PlayerRemoving:Connect(function(p) if espCache[p] then espCache[p].billboard:Destroy() espCache[p]=nil end end))
        table.insert(conns,rs.Heartbeat:Connect(updateESP))
    else
        for _,c in ipairs(conns) do c:Disconnect() end
        for p,esp in pairs(espCache) do if esp.billboard then esp.billboard:Destroy() end end
        conns,espCache = {},{}
    end
end

-- Create UI Toggle
MiscSection:AddToggle("Billboard ESP", false, toggleESP)
