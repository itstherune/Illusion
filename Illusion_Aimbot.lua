-- Prevent the script from loading more than once
-- made by rune

if getgenv().IllusionAimbotLoaded then
    local existing = game:GetService("CoreGui"):FindFirstChild("GrokCheatMenu")
    if existing then
        existing.Enabled = true
    end
    return
end

getgenv().IllusionAimbotLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local MAX_AIM_DISTANCE = 50
local AIM_SMOOTHNESS = 0.35

-- ESP update rate.
-- 30 = smoother/lighter
-- 20 = even lighter
local ESP_FPS = 30
local ESP_INTERVAL = 1 / ESP_FPS

--==================================================
-- VARIABLES
--==================================================

local aimbotEnabled = false
local aimbotHolding = false
local espEnabled = false

local aimbotConn = nil
local espConn = nil
local playerAddedConn = nil

local espDrawings = {}
local enemyCache = {}

local espTimer = 0

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrokCheatMenu"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

--==================================================
-- TITLE BAR
--==================================================

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Illusion Aimbot Universal"
Title.TextColor3 = Color3.fromRGB(0, 255, 100)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 35, 1, 0)
MinimizeBtn.Position = UDim2.new(1, -80, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 24
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 1, 0)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.TextSize = 24
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -45)
Content.Position = UDim2.new(0, 0, 0, 45)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

--==================================================
-- AIMBOT BUTTON
--==================================================

local AimbotBtn = Instance.new("TextButton")
AimbotBtn.Size = UDim2.new(0.9, 0, 0, 55)
AimbotBtn.Position = UDim2.new(0.05, 0, 0, 15)
AimbotBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
AimbotBtn.Text = "🎯 Aimbot (Hold SHIFT): OFF"
AimbotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotBtn.TextSize = 18
AimbotBtn.Font = Enum.Font.GothamSemibold
AimbotBtn.Parent = Content

local AimCorner = Instance.new("UICorner")
AimCorner.CornerRadius = UDim.new(0, 10)
AimCorner.Parent = AimbotBtn

--==================================================
-- ESP BUTTON
--==================================================

local ESPBtn = Instance.new("TextButton")
ESPBtn.Size = UDim2.new(0.9, 0, 0, 55)
ESPBtn.Position = UDim2.new(0.05, 0, 0, 85)
ESPBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ESPBtn.Text = "👁️ ESP Players: OFF"
ESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPBtn.TextSize = 18
ESPBtn.Font = Enum.Font.GothamSemibold
ESPBtn.Parent = Content

local ESPCorner = Instance.new("UICorner")
ESPCorner.CornerRadius = UDim.new(0, 10)
ESPCorner.Parent = ESPBtn

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.9, 0, 0, 30)
Status.Position = UDim2.new(0.05, 0, 0, 155)
Status.BackgroundTransparency = 1
Status.Text = "✅ Loaded! Hold SHIFT + enemy close = aim | INSERT = toggle menu"
Status.TextColor3 = Color3.fromRGB(0, 255, 100)
Status.TextSize = 14
Status.Font = Enum.Font.Gotham
Status.Parent = Content

--==================================================
-- TEAM CHECK
--==================================================

local function isEnemy(plr)
    if not plr or plr == LocalPlayer then
        return false
    end

    local character = plr.Character

    if not character then
        return false
    end

    if not character:FindFirstChild("Head") then
        return false
    end

    local myTeam = LocalPlayer.Team

    -- FFA
    if not myTeam then
        return true
    end

    -- Team game
    if plr.Team then
        return plr.Team ~= myTeam
    end

    return false
end

--==================================================
-- ENEMY CACHE
--==================================================

local function rebuildEnemyCache()
    table.clear(enemyCache)

    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            enemyCache[#enemyCache + 1] = plr
        end
    end
end

local function addEnemy(plr)
    if plr == LocalPlayer then
        return
    end

    if not isEnemy(plr) then
        return
    end

    for _, existing in ipairs(enemyCache) do
        if existing == plr then
            return
        end
    end

    enemyCache[#enemyCache + 1] = plr
end

local function removeEnemy(plr)
    for i = #enemyCache, 1, -1 do
        if enemyCache[i] == plr then
            table.remove(enemyCache, i)
            break
        end
    end
end

--==================================================
-- AIMBOT
--==================================================

local function isShiftDown()
    return
        UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

local function getClosestEnemy()
    local character = LocalPlayer.Character

    if not character then
        return nil, math.huge
    end

    local myRoot = character:FindFirstChild("HumanoidRootPart")

    if not myRoot then
        return nil, math.huge
    end

    local myPosition = myRoot.Position

    local closest = nil
    local closestDistance = MAX_AIM_DISTANCE

    for i = #enemyCache, 1, -1 do
        local plr = enemyCache[i]

        if not plr.Parent then
            table.remove(enemyCache, i)
            continue
        end

        local enemyCharacter = plr.Character

        if not enemyCharacter then
            continue
        end

        local head = enemyCharacter:FindFirstChild("Head")
        local humanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")

        if head and humanoid and humanoid.Health > 0 then

            local offset = head.Position - myPosition

            -- Faster than calculating square root with Magnitude.
            local distanceSquared = offset.X * offset.X
                + offset.Y * offset.Y
                + offset.Z * offset.Z

            local maxDistanceSquared =
                MAX_AIM_DISTANCE * MAX_AIM_DISTANCE

            if distanceSquared <= maxDistanceSquared
                and distanceSquared < closestDistance * closestDistance then

                closestDistance = math.sqrt(distanceSquared)
                closest = plr
            end
        end
    end

    return closest, closestDistance
end

local function updateAimbot()
    if not aimbotEnabled then
        aimbotHolding = false
        return
    end

    if not isShiftDown() then
        aimbotHolding = false
        return
    end

    local closest = getClosestEnemy()

    if not closest then
        aimbotHolding = false
        return
    end

    local character = closest.Character

    if not character then
        aimbotHolding = false
        return
    end

    local head = character:FindFirstChild("Head")

    if not head then
        aimbotHolding = false
        return
    end

    aimbotHolding = true

    local targetCFrame = CFrame.lookAt(
        Camera.CFrame.Position,
        head.Position
    )

    Camera.CFrame = Camera.CFrame:Lerp(
        targetCFrame,
        AIM_SMOOTHNESS
    )
end

local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled

    AimbotBtn.Text =
        "🎯 Aimbot (Hold SHIFT): "
        .. (aimbotEnabled and "ON" or "OFF")

    AimbotBtn.BackgroundColor3 =
        aimbotEnabled
        and Color3.fromRGB(0, 170, 0)
        or Color3.fromRGB(45, 45, 45)

    if aimbotEnabled then

        if not aimbotConn then
            aimbotConn =
                RunService.RenderStepped:Connect(updateAimbot)
        end

    else

        if aimbotConn then
            aimbotConn:Disconnect()
            aimbotConn = nil
        end

        aimbotHolding = false
    end
end

--==================================================
-- ESP
--==================================================

local function createESP(plr)
    if plr == LocalPlayer then
        return
    end

    if espDrawings[plr] then
        return
    end

    local drawings = {}

    drawings.box = Drawing.new("Square")
    drawings.box.Thickness = 2
    drawings.box.Filled = false
    drawings.box.Color = Color3.fromRGB(255, 0, 255)
    drawings.box.Transparency = 1
    drawings.box.Visible = false

    drawings.name = Drawing.new("Text")
    drawings.name.Size = 18
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.Color = Color3.fromRGB(255, 255, 255)
    drawings.name.Visible = false

    drawings.health = Drawing.new("Line")
    drawings.health.Thickness = 3
    drawings.health.Color = Color3.fromRGB(0, 255, 0)
    drawings.health.Visible = false

    espDrawings[plr] = drawings
end

local function hideESP(drawings)
    drawings.box.Visible = false
    drawings.name.Visible = false
    drawings.health.Visible = false
end

local function removeESP(plr)
    local drawings = espDrawings[plr]

    if not drawings then
        return
    end

    for _, obj in pairs(drawings) do
        pcall(function()
            obj:Remove()
        end)
    end

    espDrawings[plr] = nil
end

local function updateESP()
    if not espEnabled then
        return
    end

    for plr, drawings in pairs(espDrawings) do

        if not plr.Parent then
            removeESP(plr)
            continue
        end

        if not isEnemy(plr) then
            hideESP(drawings)
            continue
        end

        local character = plr.Character

        if not character then
            hideESP(drawings)
            continue
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if not root or not head or not humanoid then
            hideESP(drawings)
            continue
        end

        if humanoid.Health <= 0 then
            hideESP(drawings)
            continue
        end

        -- One visibility projection first.
        local rootPos, onScreen =
            Camera:WorldToViewportPoint(root.Position)

        if not onScreen or rootPos.Z <= 0 then
            hideESP(drawings)
            continue
        end

        local top =
            Camera:WorldToViewportPoint(
                head.Position + Vector3.new(0, 1, 0)
            )

        local bottom =
            Camera:WorldToViewportPoint(
                root.Position - Vector3.new(0, 3, 0)
            )

        local height = math.abs(top.Y - bottom.Y)

        if height < 2 then
            hideESP(drawings)
            continue
        end

        local width = height * 0.6

        -- Box
        drawings.box.Size =
            Vector2.new(width, height)

        drawings.box.Position =
            Vector2.new(
                top.X - width / 2,
                top.Y
            )

        drawings.box.Visible = true

        -- Name
        drawings.name.Text =
            plr.Name
            .. " ["
            .. math.floor(humanoid.Health)
            .. "/"
            .. math.floor(humanoid.MaxHealth)
            .. "]"

        drawings.name.Position =
            Vector2.new(
                top.X,
                top.Y - 25
            )

        drawings.name.Visible = true

        -- Health
        local maxHealth = humanoid.MaxHealth

        local healthPercent = 0

        if maxHealth > 0 then
            healthPercent =
                math.clamp(
                    humanoid.Health / maxHealth,
                    0,
                    1
                )
        end

        local healthX =
            top.X - width / 2 - 8

        drawings.health.From =
            Vector2.new(
                healthX,
                bottom.Y
            )

        drawings.health.To =
            Vector2.new(
                healthX,
                bottom.Y - height * healthPercent
            )

        drawings.health.Visible = true
    end
end

--==================================================
-- OPTIMIZED ESP LOOP
--==================================================

local function startESP()
    if espConn then
        return
    end

    espTimer = 0

    espConn =
        RunService.RenderStepped:Connect(function(deltaTime)

            espTimer += deltaTime

            if espTimer < ESP_INTERVAL then
                return
            end

            espTimer = 0

            updateESP()
        end)
end

local function stopESP()
    if espConn then
        espConn:Disconnect()
        espConn = nil
    end

    for plr, drawings in pairs(espDrawings) do
        for _, obj in pairs(drawings) do
            pcall(function()
                obj:Remove()
            end)
        end
    end

    table.clear(espDrawings)
end

local function toggleESP()
    espEnabled = not espEnabled

    ESPBtn.Text =
        "👁️ ESP Players: "
        .. (espEnabled and "ON" or "OFF")

    ESPBtn.BackgroundColor3 =
        espEnabled
        and Color3.fromRGB(0, 170, 0)
        or Color3.fromRGB(45, 45, 45)

    if espEnabled then

        rebuildEnemyCache()

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                createESP(plr)
            end
        end

        startESP()

    else

        stopESP()

    end
end

--==================================================
-- PLAYER EVENTS
--==================================================

playerAddedConn =
    Players.PlayerAdded:Connect(function(plr)

        task.defer(function()

            addEnemy(plr)

            if espEnabled then
                createESP(plr)
            end

        end)
    end)

Players.PlayerRemoving:Connect(function(plr)

    removeEnemy(plr)
    removeESP(plr)

end)

-- Rebuild cache when local team changes.
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    rebuildEnemyCache()
end)

-- Rebuild cache if another player's team changes.
for _, plr in ipairs(Players:GetPlayers()) do

    plr:GetPropertyChangedSignal("Team"):Connect(function()
        rebuildEnemyCache()
    end)

end

--==================================================
-- BUTTON CONNECTIONS
--==================================================

AimbotBtn.MouseButton1Click:Connect(toggleAimbot)
ESPBtn.MouseButton1Click:Connect(toggleESP)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false
local fullSize = MainFrame.Size

MinimizeBtn.MouseButton1Click:Connect(function()

    minimized = not minimized

    if minimized then

        MainFrame:TweenSize(
            UDim2.new(0, 280, 0, 45),
            "Out",
            "Quad",
            0.25,
            true
        )

        Content.Visible = false
        MinimizeBtn.Text = "+"

    else

        MainFrame:TweenSize(
            fullSize,
            "Out",
            "Quad",
            0.25,
            true
        )

        Content.Visible = true
        MinimizeBtn.Text = "−"

    end
end)

--==================================================
-- CLOSE
--==================================================

CloseBtn.MouseButton1Click:Connect(function()

    getgenv().IllusionAimbotLoaded = nil

    if aimbotConn then
        aimbotConn:Disconnect()
        aimbotConn = nil
    end

    if espConn then
        espConn:Disconnect()
        espConn = nil
    end

    if playerAddedConn then
        playerAddedConn:Disconnect()
        playerAddedConn = nil
    end

    for _, drawings in pairs(espDrawings) do
        for _, obj in pairs(drawings) do
            pcall(function()
                obj:Remove()
            end)
        end
    end

    table.clear(espDrawings)
    table.clear(enemyCache)

    ScreenGui:Destroy()
end)

--==================================================
-- INSERT MENU TOGGLE
--==================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)

    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end

end)

--==================================================
-- INITIALIZE
--==================================================

rebuildEnemyCache()

print("✅ Illusion Aimbot Menu loaded!")
print(
    "🎯 Aimbot activates ONLY when holding SHIFT AND enemy <= "
    .. MAX_AIM_DISTANCE
    .. " studs away"
)
print("ESP update rate: " .. ESP_FPS .. " FPS")
print("Change MAX_AIM_DISTANCE to adjust aim range")
print("Blue → aims Red only | Red → aims Blue only | FFA → aims everyone")
print("Press INSERT to hide/show menu")
