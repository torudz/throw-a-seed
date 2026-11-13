local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
playerGui:WaitForChild("HudLancer", 30)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRemote = Remotes:WaitForChild("Request")

local okCS, ClientState = pcall(function()
    return require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientState", 10))
end)

-- ══════════════════════════════════════════
-- HỆ THỐNG LƯU / TẢI CẤU HÌNH (AUTO SAVE)
-- ══════════════════════════════════════════
local configFile = "AutoFarmHub_Config.json"
local Settings = {
    AutoThrow = false,
    AutoTrain = false,
    AutoPlaceBest = false,
    AutoX2 = false,
    AutoRewards = false,
    AutoRejoin = false
}

local function loadSettings()
    if isfile and readfile and isfile(configFile) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(configFile))
        end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                if Settings[k] ~= nil and type(v) == "boolean" then
                    Settings[k] = v
                end
            end
        end
    end
end

local function saveSettings()
    if writefile then
        pcall(function()
            writefile(configFile, HttpService:JSONEncode(Settings))
        end)
    end
end

loadSettings()

if Settings.AutoThrow and Settings.AutoTrain then
    Settings.AutoThrow = false
    saveSettings()
end

getgenv().AutoThrow = Settings.AutoThrow
getgenv().AutoTrain = Settings.AutoTrain
getgenv().AutoPlaceBest = Settings.AutoPlaceBest
getgenv().AutoX2 = Settings.AutoX2
getgenv().AutoRewards = Settings.AutoRewards
getgenv().AutoRejoin = Settings.AutoRejoin

-- ══════════════════════════════════════════
-- GIAO DIỆN MENU & QUẢN LÝ NÚT BẤM
-- ══════════════════════════════════════════
local guiParent = (gethui and gethui()) or CoreGui or playerGui
if guiParent:FindFirstChild("AutoFarmHub_Custom") then
    guiParent:FindFirstChild("AutoFarmHub_Custom"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmHub_Custom"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 322)
MainFrame.Position = UDim2.new(0.5, -110, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local ms = Instance.new("UIStroke", MainFrame)
ms.Color = Color3.fromRGB(60, 65, 80); ms.Thickness = 1.5

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1,-60,1,0); Title.Position = UDim2.new(0,12,0,0)
Title.BackgroundTransparency = 1; Title.Text = "Auto Farm Menu"
Title.TextColor3 = Color3.fromRGB(255,255,255); Title.Font = Enum.Font.GothamBold
Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0,26,0,26); MinBtn.Position = UDim2.new(1,-56,0,4)
MinBtn.BackgroundColor3 = Color3.fromRGB(50,54,68); MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255,255,255); MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0,26,0,26); CloseBtn.Position = UDim2.new(1,-28,0,4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,55,55); CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255); CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1,-20,1,-44); Container.Position = UDim2.new(0,10,0,40)
Container.BackgroundTransparency = 1

local ToggleSetters = {}

local function fireGuiButton(btn)
    if not btn then return end
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(btn.Activated)) do
                conn:Fire()
            end
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                conn:Fire()
            end
        end
    end)
end

local function stopTrainingNow()
    local char = LocalPlayer.Character
    if char and char:GetAttribute("Training") then
        local hudTrain = playerGui:FindFirstChild("HudEntrainement")
        local barre = hudTrain and hudTrain:FindFirstChild("Barre")
        local stopBtn = barre and barre:FindFirstChild("Stop")
        if stopBtn then
            fireGuiButton(stopBtn)
        end
        if okCS and ClientState and ClientState.Request then
            pcall(function()
                ClientState.Request("StopTrain")
            end)
        end
    end
end

local function stopThrowingNow()
    local fx = playerGui:FindFirstChild("ThrowFX")
    local st = fx and fx:GetAttribute("State") or "idle"

    if st == "result" then
        local choiceGui = playerGui:FindFirstChild("ChoixApresLancer")
        local boutons = choiceGui and choiceGui:FindFirstChild("Boutons")
        local retourBtn = boutons and boutons:FindFirstChild("Retour")
        if retourBtn then
            fireGuiButton(retourBtn)
        else
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
            end)
        end
    elseif st == "aiming" then
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.S, false, game)
            task.wait(0.08)
            VIM:SendKeyEvent(false, Enum.KeyCode.S, false, game)
        end)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Anchored then
            hrp.Anchored = false
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, 14)
        end
    end
end

local function setToggleState(key, newState, skipCallback)
    if ToggleSetters[key] then
        ToggleSetters[key](newState, skipCallback)
    else
        Settings[key] = newState
        getgenv()[key] = newState
        saveSettings()
    end
end

local function createToggle(text, settingKey, posY, onToggle)
    local Btn = Instance.new("TextButton", Container)
    Btn.Size = UDim2.new(1,0,0,38); Btn.Position = UDim2.new(0,0,0,posY)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 13
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

    local state = Settings[settingKey] or false

    local function updateVisual()
        if state then
            Btn.BackgroundColor3 = Color3.fromRGB(46,160,67)
            Btn.TextColor3 = Color3.fromRGB(255,255,255)
            Btn.Text = text..": ON"
        else
            Btn.BackgroundColor3 = Color3.fromRGB(45,48,60)
            Btn.TextColor3 = Color3.fromRGB(220,220,220)
            Btn.Text = text..": OFF"
        end
    end

    ToggleSetters[settingKey] = function(val, skipCallback)
        if state == val then return end
        state = val
        Settings[settingKey] = state
        getgenv()[settingKey] = state
        updateVisual()
        saveSettings()
        if not skipCallback and onToggle then
            onToggle(state)
        end
    end

    updateVisual()

    Btn.MouseButton1Click:Connect(function()
        ToggleSetters[settingKey](not state, false)
    end)
end

createToggle("Auto Throw", "AutoThrow", 0, function(isOn)
    if isOn then
        if getgenv().AutoTrain then
            setToggleState("AutoTrain", false, true)
        end
        task.spawn(stopTrainingNow)
    else
        task.spawn(stopThrowingNow)
    end
end)

createToggle("Auto Train", "AutoTrain", 46, function(isOn)
    if isOn then
        if getgenv().AutoThrow then
            setToggleState("AutoThrow", false, true)
        end
        task.spawn(stopThrowingNow)
    else
        task.spawn(stopTrainingNow)
    end
end)

createToggle("Auto Place Best", "AutoPlaceBest", 92)
createToggle("Auto X2 XP", "AutoX2", 138)
createToggle("Auto Rewards", "AutoRewards", 184)
createToggle("Auto Rejoin", "AutoRejoin", 230)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Container.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0,220,0,34) or UDim2.new(0,220,0,322)
    MinBtn.Text = minimized and "+" or "-"
end)
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().AutoThrow = false
    getgenv().AutoTrain = false
    getgenv().AutoPlaceBest = false
    getgenv().AutoX2 = false
    getgenv().AutoRewards = false
    getgenv().AutoRejoin = false
    ScreenGui:Destroy()
end)

local function getThrowFX()
    return playerGui:FindFirstChild("ThrowFX")
end

local function getState()
    local fx = getThrowFX()
    return fx and fx:GetAttribute("State") or "idle"
end

local function getCurseur()
    local hud = playerGui:FindFirstChild("HudLancer")
    if not hud then return nil end
    local jauge = hud:FindFirstChild("Jauge")
    if not jauge then return nil end
    local capsule = jauge:FindFirstChild("Capsule")
    if not capsule then return nil end
    return capsule:FindFirstChild("Curseur")
end

local function isOnStrip()
    local Character = LocalPlayer.Character
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local strip = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Canyon")
        and workspace.Map.Canyon:FindFirstChild("LaunchStrip")
    if not strip then return false end

    local rel = strip.CFrame:PointToObjectSpace(hrp.Position)
    local half = strip.Size / 2
    return math.abs(rel.X) < half.X
        and math.abs(rel.Z) < half.Z
        and rel.Y > -2 and rel.Y < 8
end

local function walkToStrip()
    local Character = LocalPlayer.Character
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local strip = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Canyon")
        and workspace.Map.Canyon:FindFirstChild("LaunchStrip")
    if not strip then return end

    local target = strip.Position + Vector3.new(0, 3, 0)
    hum:MoveTo(target)

    local timeout = tick() + 10
    while not isOnStrip() and tick() < timeout and getgenv().AutoThrow do
        task.wait(0.1)
    end
end

-- ══════════════════════════════════════════
-- LUỒNG 1: Auto Throw
-- ══════════════════════════════════════════
task.spawn(function()
    while ScreenGui.Parent do
        if getgenv().AutoThrow then
            local char = LocalPlayer.Character
            if char and char:GetAttribute("Training") then
                stopTrainingNow()
                task.wait(0.4)
            else
                local state = getState()

                if state == "idle" then
                    if not isOnStrip() then
                        walkToStrip()
                    end
                    task.wait(0.1)

                elseif state == "aiming" then
                    local fx = getThrowFX()
                    local curseur = getCurseur()

                    if curseur then
                        local fired = false
                        local timeout = tick() + 4
                        local conn

                        conn = RunService.RenderStepped:Connect(function()
                            if not getgenv().AutoThrow or tick() > timeout then
                                conn:Disconnect()
                                fired = true
                                return
                            end
                            local offset = curseur.Position.Y.Offset
                            local n7 = math.clamp((317 - offset) / 304, 0, 1)
                            if n7 >= 0.98 then
                                conn:Disconnect()
                                fired = true
                                local testTap = fx and fx:FindFirstChild("TestTap")
                                if testTap then testTap:Fire() end
                            end
                        end)

                        while not fired do task.wait() end
                    else
                        local testTap = fx and fx:FindFirstChild("TestTap")
                        if testTap then testTap:Fire() end
                    end

                    task.wait(0.3)

                elseif state == "result" then
                    if getgenv().AutoThrow and not getgenv().AutoTrain then
                        local fx = getThrowFX()
                        local testAgain = fx and fx:FindFirstChild("TestAgain")
                        if testAgain then testAgain:Fire() end
                    end
                    task.wait(0.5)

                else
                    task.wait(0.2)
                end
            end
        else
            task.wait(0.2)
        end
    end
end)

-- ══════════════════════════════════════════
-- LUỒNG 2: Auto Train
-- ══════════════════════════════════════════
task.spawn(function()
    local function findTrainPrompt()
        if okCS and ClientState and ClientState.MyPlot then
            local myPlot = ClientState.MyPlot()
            if myPlot then
                local barStation = myPlot:FindFirstChild("BarStation")
                if barStation then
                    local prompt = barStation:FindFirstChild("TrainPrompt", true) or barStation:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local part = barStation:FindFirstChild("Bar") or barStation:FindFirstChildWhichIsA("BasePart", true)
                    if prompt then
                        return prompt, part
                    end
                end
            end
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local bestPrompt, bestPart, bestDist = nil, nil, math.huge

        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Name == "TrainPrompt" then
                local parent = desc.Parent
                local part = parent:IsA("BasePart") and parent or parent:FindFirstAncestorWhichIsA("BasePart")
                if part and hrp then
                    local d = (part.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestPrompt = desc
                        bestPart = part
                    end
                elseif desc then
                    bestPrompt = desc
                    bestPart = part
                end
            end
        end
        return bestPrompt, bestPart
    end

    while ScreenGui.Parent do
        if getgenv().AutoTrain then
            local throwState = getState()
            if throwState ~= "idle" then
                stopThrowingNow()
                task.wait(0.35)
            else
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if char and hrp and hum and not char:GetAttribute("Training") then
                    local prompt, part = findTrainPrompt()
                    if prompt then
                        local targetPos = part and part.Position or (prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition)
                        if targetPos then
                            local dist = (hrp.Position - targetPos).Magnitude
                            if dist > 8 then
                                hum:MoveTo(targetPos)
                                local timeout = tick() + 8
                                while (hrp.Position - targetPos).Magnitude > 8 and tick() < timeout and getgenv().AutoTrain do
                                    task.wait(0.1)
                                end
                            end
                        end

                        if getgenv().AutoTrain and getState() == "idle" and not char:GetAttribute("Training") then
                            pcall(function()
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                else
                                    prompt:InputHoldBegin()
                                    task.wait((prompt.HoldDuration or 0) + 0.1)
                                    prompt:InputHoldEnd()
                                end
                            end)
                        end
                    end
                end
                task.wait(0.6)
            end
        else
            task.wait(0.3)
        end
    end
end)

-- ══════════════════════════════════════════
-- LUỒNG 3: Auto Place Best
-- ══════════════════════════════════════════
task.spawn(function()
    while ScreenGui.Parent do
        if getgenv().AutoPlaceBest then
            pcall(function() RequestRemote:InvokeServer("PlaceBest", {}) end)
            task.wait(2)
        else
            task.wait(0.3)
        end
    end
end)

-- ══════════════════════════════════════════
-- LUỒNG 4: Auto X2 XP
-- ══════════════════════════════════════════
local function claimX2(child)
    if not getgenv().AutoX2 then return end
    task.wait(0.1)
    fireGuiButton(child)
end

local xpBoostHud = playerGui:WaitForChild("XPBoostHud", 10)
if xpBoostHud then
    xpBoostHud.ChildAdded:Connect(function(child)
        if child.Name == "XPOffer" and child:IsA("ImageButton") then
            claimX2(child)
        end
    end)
    for _, child in ipairs(xpBoostHud:GetChildren()) do
        if child.Name == "XPOffer" and child:IsA("ImageButton") then
            claimX2(child)
        end
    end
end

-- ══════════════════════════════════════════
-- LUỒNG 5: Auto Rewards (Độc lập)
-- ══════════════════════════════════════════
task.spawn(function()
    local ok, Balance = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Balance", 10))
    end)

    while ScreenGui.Parent do
        if getgenv().AutoRewards then
            if LocalPlayer:GetAttribute("DailyReady") == true then
                pcall(function()
                    RequestRemote:InvokeServer("ClaimDaily")
                end)
                task.wait(0.5)
            end

            if ok and Balance and Balance.Gifts then
                local claimed = {}
                for id in tostring(LocalPlayer:GetAttribute("GiftsClaimed") or ""):gmatch("%d+") do
                    claimed[tonumber(id)] = true
                end

                local sessionStart = tonumber(LocalPlayer:GetAttribute("SessionStart")) or workspace:GetServerTimeNow()
                local elapsed = workspace:GetServerTimeNow() - sessionStart

                for i, gift in ipairs(Balance.Gifts) do
                    if not claimed[i] and elapsed >= (gift.at - 1) then
                        pcall(function()
                            RequestRemote:InvokeServer("ClaimGift", { i = i })
                        end)
                        task.wait(0.4)
                    end
                end
            end

            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- ══════════════════════════════════════════
-- LUỒNG 6: Auto Rejoin (Độc lập - Khi nhận đủ mốc cuối)
-- ══════════════════════════════════════════
task.spawn(function()
    local ok, Balance = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Balance", 10))
    end)

    local rejoining = false

    while ScreenGui.Parent do
        if getgenv().AutoRejoin and not rejoining then
            if ok and Balance and Balance.Gifts and #Balance.Gifts > 0 then
                local claimed = {}
                for id in tostring(LocalPlayer:GetAttribute("GiftsClaimed") or ""):gmatch("%d+") do
                    claimed[tonumber(id)] = true
                end

                local allClaimed = true
                for i = 1, #Balance.Gifts do
                    if not claimed[i] then
                        allClaimed = false
                        break
                    end
                end

                if allClaimed then
                    rejoining = true
                    task.wait(2)
                    pcall(function()
                        if #Players:GetPlayers() <= 1 then
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        else
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                        end
                    end)
                    task.delay(6, function()
                        if ScreenGui.Parent then
                            pcall(function()
                                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                            end)
                        end
                    end)
                end
            end

            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)