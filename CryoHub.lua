local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

Player.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Performance optimization: Reduce update frequency
local UPDATE_INTERVAL = 0.1

local xClickOffset = 43
local AimbotEnabled = false
local ShotDelay = 0.3
local ArcType = "Low Arc"
local DeviceSpooferEnabled = false
local DeviceType = "PC"
local PredictionMultiplier = 6

-- Korblox & Headless Variables
local KorbloxEnabled = false
local ShowNoLegEnabled = false
local HeadlessEnabled = false
local originalLegs = {}

-- WalkSpeed Variables (Anti-Kick Bypass)
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local originalWalkSpeed = 16

-- Fake Shot Variables
local FakeShotEnabled = false

-- Walk Fling Variables
local WalkFlingEnabled = false
local WalkFlingPower = 100

-- Performance Variables
local FPSBoosterEnabled = false
local AntiLagEnabled = false

-- Anti Travel Variables
local AntiTravelEnabled = false
local antiTravelConnection
local inAir = false

-- Auto Dunk Variables
local AutoDunkEnabled = false

-- Auto Guard Variables
local autoGuardUI
local autoGuardState = {enabled = false, running = false}
local dragInput, dragging, dragStart, startPos

-- Ball Magnet Variables (Optimized)
local MagsEnabled = false
local MagsAmount = 100
local BallReach = { Distance = MagsAmount }
local BallMags = { Distance = MagsAmount }

local function GetClosestPart(Ball)
    if Player.Character then
        local ClosestDistance = math.huge
        local ClosestPart
        for _, v in pairs(Player.Character:GetChildren()) do
            if v:IsA("BasePart") then
                local Distance = (v.Position - Ball.Position).Magnitude
                if Distance < ClosestDistance then
                    ClosestDistance = Distance
                    ClosestPart = v
                end
            end
        end
        return ClosestPart
    end
end

function BallMags:GetClosestBall()
    local ClosestBall
    local ClosestDistance = math.huge
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Basketball" and obj:FindFirstChild("Ball") then
            local Ball = obj.Ball
            local RootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if Ball and RootPart then
                local Distance = (Ball.Position - RootPart.Position).Magnitude
                if Distance < self.Distance and Distance < ClosestDistance then
                    ClosestBall = Ball
                    ClosestDistance = Distance
                end
            end
        end
    end
    return ClosestBall
end

function BallReach:GetClosestBall()
    local ClosestBall
    local ClosestDistance = math.huge
    for _, OtherPlayer in ipairs(Players:GetPlayers()) do
        local Ball = OtherPlayer.Character and OtherPlayer.Character:FindFirstChild("Basketball") and OtherPlayer.Character.Basketball:FindFirstChild("Ball")
        local RootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if Ball and RootPart then
            local Distance = (Ball.Position - RootPart.Position).Magnitude
            if Distance < self.Distance and Distance < ClosestDistance then
                ClosestBall = Ball
                ClosestDistance = Distance
            end
        end
    end
    return ClosestBall
end

-- Optimized Mags: Reduced frequency to prevent lag
local function applyMags()
    if MagsEnabled then
        task.spawn(function()
            while MagsEnabled do
                pcall(function()
                    BallReach.Distance = MagsAmount
                    BallMags.Distance = MagsAmount

                    local MagsBall = BallMags:GetClosestBall()
                    local ReachBall = BallReach:GetClosestBall()
                    local Root1, Root2 = MagsBall and GetClosestPart(MagsBall), ReachBall and GetClosestPart(ReachBall)

                    if MagsBall and Root1 then
                        firetouchinterest(Root1, MagsBall, 0)
                        task.wait(0.001)
                        firetouchinterest(Root1, MagsBall, 1)
                    end

                    if ReachBall and Root2 then
                        firetouchinterest(Root2, ReachBall, 0)
                        task.wait(0.001)
                        firetouchinterest(Root2, ReachBall, 1)
                    end
                end)
                task.wait(UPDATE_INTERVAL)
            end
        end)
    end
end

local function FireDeviceEvent()
    if ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("deviceEvent") then
        local args = {[1] = DeviceType}
        ReplicatedStorage.Remotes.deviceEvent:FireServer(unpack(args))
    end
end

-- Korblox Functions
local function applyKorblox()
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local rightLeg = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")
        if rightLeg then
            if not originalLegs.RightLeg then
                originalLegs.RightLeg = rightLeg:Clone()
            end
            
            rightLeg.Transparency = 1
            
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshId = "rbxassetid://139607718"
            mesh.TextureId = "rbxassetid://139607729"
            mesh.Scale = Vector3.new(1, 1, 1)
            mesh.Parent = rightLeg
        end
    end)
end

local function removeKorblox()
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local rightLeg = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")
        if rightLeg then
            rightLeg.Transparency = 0
            for _, v in pairs(rightLeg:GetChildren()) do
                if v:IsA("SpecialMesh") then
                    v:Destroy()
                end
            end
        end
    end)
end

-- Show No Leg Functions
local function applyShowNoLeg()
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local rightLeg = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")
        local leftLeg = char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")
        
        if rightLeg then rightLeg.Transparency = 1 end
        if leftLeg then leftLeg.Transparency = 1 end
    end)
end

local function removeShowNoLeg()
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local rightLeg = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")
        local leftLeg = char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")
        
        if rightLeg then rightLeg.Transparency = 0 end
        if leftLeg then leftLeg.Transparency = 0 end
    end)
end

-- Headless Function
local function applyHeadless()
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        if head then
            head.Transparency = 1
            local face = head:FindFirstChild("face")
            if face then
                face.Transparency = 1
            end
        end
    end)
end

local function removeHeadless()
    pcall(function()
        local char = Player.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        if head then
            head.Transparency = 0
            local face = head:FindFirstChild("face")
            if face then
                face.Transparency = 0
            end
        end
    end)
end

-- WalkSpeed Functions (Optimized)
local walkSpeedConnection
local lastWalkSpeedUpdate = 0
local function applyWalkSpeed()
    if walkSpeedConnection then
        walkSpeedConnection:Disconnect()
    end
    
    if WalkSpeedEnabled then
        walkSpeedConnection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - lastWalkSpeedUpdate < 0.5 then return end
            lastWalkSpeedUpdate = currentTime
            
            pcall(function()
                local char = Player.Character
                if not char then return end
                
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = WalkSpeedValue
                end
            end)
        end)
    else
        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
            walkSpeedConnection = nil
        end
        
        pcall(function()
            local char = Player.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = originalWalkSpeed
                end
            end
        end)
    end
end

-- Mobile-compatible input handling
local function performClick()
    local size = Camera.ViewportSize
    local clickX = size.X / 2 + xClickOffset
    local clickY = size.Y / 2
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
    task.wait()
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
end

-- Fake Shot Function
local function performFakeShot()
    pcall(function()
        if not IsHoldingBasketball() then return end
        
        local oldCFrame = Camera.CFrame
        Camera.CFrame = CFrame.new(Character.Head.Position, Character.Head.Position + Vector3.new(0, 100, 0))
        task.wait(0.01)
        performClick()
        task.wait(0.01)
        Camera.CFrame = oldCFrame
    end)
end

-- Optimized Walk Fling
local walkFlingConnection
local function startWalkFling()
    if walkFlingConnection then
        walkFlingConnection:Disconnect()
    end
    
    walkFlingConnection = RunService.Heartbeat:Connect(function()
        if WalkFlingEnabled then
            pcall(function()
                local char = Player.Character
                if not char then return end
                
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Velocity = rootPart.CFrame.LookVector * WalkFlingPower
                end
            end)
        end
    end)
end

-- Performance Functions
local function applyFPSBooster()
    if FPSBoosterEnabled then
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            end
        end
        
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end

local function applyAntiLag()
    if AntiLagEnabled then
        workspace:FindFirstChildOfClass("Terrain").WaterWaveSize = 0
        workspace:FindFirstChildOfClass("Terrain").WaterWaveSpeed = 0
        workspace:FindFirstChildOfClass("Terrain").WaterReflectance = 0
        workspace:FindFirstChildOfClass("Terrain").WaterTransparency = 0
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    end
end

-- Anti Travel Functions
local function renameToZ()
    pcall(function()
        local char = Player.Character
        if char then
            local b = char:FindFirstChild("Basketball")
            if b then
                b.Name = "z"
            end
        end
    end)
end

local function renameToBasketball()
    pcall(function()
        local char = Player.Character
        if char then
            local z = char:FindFirstChild("z")
            if z then
                z.Name = "Basketball"
            end
        end
    end)
end

local function monitorAntiTravelStates()
    if antiTravelConnection then
        antiTravelConnection:Disconnect()
        antiTravelConnection = nil
    end

    local char = Player.Character
    if not char then return end

    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    antiTravelConnection = humanoid.StateChanged:Connect(function(_, new)
        if not AntiTravelEnabled then return end

        if new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
            inAir = true
            renameToZ()
        elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
            inAir = false
            task.wait(0.3)
            if not inAir and AntiTravelEnabled then
                renameToBasketball()
            end
        end
    end)
end

-- Optimized Auto Dunk
local function toggleAutoDunk()
    if AutoDunkEnabled then
        task.spawn(function()
            while AutoDunkEnabled do
                pcall(function()
                    local char = Player.Character
                    if char and char:FindFirstChild("Basketball") and char:FindFirstChild("HumanoidRootPart") then
                        if workspace:FindFirstChild("Courts") then
                            for _, court in pairs(workspace.Courts:GetChildren()) do
                                local dunkPart = court:FindFirstChild("DunkPart")
                                if dunkPart then
                                    local distance = (char.HumanoidRootPart.Position - dunkPart.Position).Magnitude
                                    if distance < 50 then
                                        char.HumanoidRootPart.CFrame = dunkPart.CFrame
                                        task.wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
end

-- Auto Guard Functions (Mobile Compatible)
local function createAutoGuardUI()
    if autoGuardUI and autoGuardUI.Parent then
        autoGuardUI:Destroy()
    end

    autoGuardUI = Instance.new("ScreenGui")
    autoGuardUI.Name = "AutoGuardUI"
    autoGuardUI.Parent = Player:WaitForChild("PlayerGui")

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 80, 0, 80)
    Button.Position = UDim2.new(0.85, 0, 0.7, 0)
    Button.AnchorPoint = Vector2.new(0.5, 0.5)
    Button.Text = "Enable AutoGuard"
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.FredokaOne
    Button.TextSize = 14
    Button.TextScaled = true
    Button.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Selectable = false
    Button.Parent = autoGuardUI

    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 255))
    })
    UIGradient.Rotation = 45
    UIGradient.Parent = Button

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0.3, 0)
    UICorner.Parent = Button

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Thickness = 3
    UIStroke.Color = Color3.fromRGB(0, 200, 255)
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Button

    local function updateInput(input)
        local delta = input.Position - dragStart
        Button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    Button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Button.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)

    local function getCharacter(p) return p and p.Character end
    local function getBall(p) local c = getCharacter(p) return c and c:FindFirstChild("Basketball") end
    local function hasBallFunc(p) return (getBall(p) ~= nil) end
    local function getRootPart(p) local c = getCharacter(p) return c and c:FindFirstChild("HumanoidRootPart") end
    local function getRootPosition(p) local rp = getRootPart(p) return rp and rp.Position end
    local function getHumanoid(p) local c = getCharacter(p) return c and c:FindFirstChild("Humanoid") end

    local function walkTo(target)
        local hum = getHumanoid(Player)
        if not hum then return end
        if not target then
            hum:Move(Vector3.zero, false)
            return
        end
        hum:MoveTo(target)
    end

    local function getNearestBallHandler()
        local dist = math.huge
        local targetPlayer = nil
        local myRootPos = getRootPosition(Player)
        if not myRootPos then return nil, dist end

        for _, candidate in ipairs(Players:GetPlayers()) do
            if candidate ~= Player and hasBallFunc(candidate) then
                local candidateRootPos = getRootPosition(candidate)
                if candidateRootPos then
                    local mag = (myRootPos - candidateRootPos).Magnitude
                    if mag < dist then
                        dist = mag
                        targetPlayer = candidate
                    end
                end
            end
        end

        if dist <= 80 then
            return targetPlayer, dist
        else
            return nil, dist
        end
    end

    local function autoGuardLoop()
        while autoGuardState.enabled do
            if hasBallFunc(Player) then
                walkTo(nil)
            else
                local target, distance = getNearestBallHandler()
                if target then
                    local targetPos = getRootPosition(target)
                    local targetHum = getHumanoid(target)
                    if targetPos and targetHum then
                        local dir = targetHum.MoveDirection
                        local predictedPos = targetPos + (dir * PredictionMultiplier)
                        walkTo(predictedPos)
                    end
                else
                    walkTo(nil)
                end
            end
            task.wait(UPDATE_INTERVAL)
        end
        walkTo(nil)
    end

    Button.MouseButton1Click:Connect(function()
        autoGuardState.enabled = not autoGuardState.enabled
        Button.Text = autoGuardState.enabled and "Disable AutoGuard" or "Enable AutoGuard"
        
        if autoGuardState.enabled then
            UIGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 100))
            })
            UIStroke.Color = Color3.fromRGB(255, 100, 0)
        else
            UIGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 255))
            })
            UIStroke.Color = Color3.fromRGB(0, 200, 255)
        end
        
        if autoGuardState.enabled and not autoGuardState.running then
            autoGuardState.running = true
            task.spawn(function()
                autoGuardLoop()
                autoGuardState.running = false
            end)
        end
    end)

    return autoGuardUI
end

local function setAutoGuard(enabled)
    if enabled then
        createAutoGuardUI()
    else
        if autoGuardUI then
            autoGuardUI:Destroy()
            autoGuardUI = nil
        end
        autoGuardState.enabled = false
        autoGuardState.running = false
    end
end

-- Arc Functions
local function LowArc(distance)
    if distance >= 58 and distance < 59 then return 23 end
    if distance >= 59 and distance < 60 then return 27 end
    if distance >= 60 and distance < 61 then return 35 end
    if distance >= 61 and distance < 62 then return 37 end
    if distance >= 62 and distance < 63 then return 22 end
    if distance >= 63 and distance < 64 then return 26 end
    if distance >= 64 and distance < 65 then return 28 end
    if distance >= 65 and distance < 66 then return 32 end
    if distance >= 66 and distance < 67 then return 35 end
    if distance >= 67 and distance < 67.6 then return 24 end
    if distance >= 67.6 and distance < 68 then return 25 end
    if distance >= 68 and distance < 68.6 then return 26 end
    if distance >= 68.6 and distance < 69 then return 27 end
    if distance >= 69 and distance < 70 then return 30 end
    if distance >= 70 and distance < 70.6 then return 31 end
    if distance >= 70.6 and distance < 71 then return 32 end
    if distance >= 71 and distance < 72 then return 35 end
    if distance >= 72 and distance < 72.6 then return 38 end
    if distance >= 72.6 and distance <= 73 then return 39 end
    if distance < 58 then return 20 end
    if distance > 73 then return 45 end
end

local function HighArc(dist)
    return ({
        [15] = 160, [16] = 157, [17] = 155, [18] = 152, [19] = 149, [20] = 147,
        [21] = 144, [22] = 141, [23] = 139, [24] = 137, [25] = 135, [26] = 132,
        [27] = 130, [28] = 127, [29] = 124, [30] = 121, [31] = 119, [32] = 117,
        [33] = 115, [34] = 112, [35] = 109, [36] = 109, [37] = 108, [38] = 108,
        [39] = 108, [40] = 108, [41] = 107, [42] = 106, [43] = 105, [44] = 104,
        [45] = 103, [46] = 102, [47] = 101, [48] = 103, [49] = 103, [50] = 102,
        [51] = 102, [52] = 100, [53] = 100, [54] = 101, [55] = 98, [56] = 96,
        [57] = 94, [58] = 94, [59] = 89, [60] = 89, [61] = 89, [62] = 89,
        [63] = 85, [64] = 83, [65] = 83, [66] = 78, [67] = 78, [68] = 72,
        [69] = 72, [70] = 66, [71] = 63, [72] = 62
    })[dist] or 0
end

local function IsHoldingBasketball()
    local Ball = Character:FindFirstChild("Basketball")
    return Ball and Ball:FindFirstChild("Ball")
end

local function GetGoal()
    local Distance = math.huge
    local Goal
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, Distance end
    local pos = hrp.Position
    
    for _, container in pairs({workspace:FindFirstChild("Courts"), workspace:FindFirstChild("PracticeArea")}) do
        if container then
            for _, court in pairs(container:GetChildren()) do
                for _, obj in pairs(court:GetDescendants()) do
                    if obj.Name == "Swish" and obj.Parent:FindFirstChildOfClass("TouchTransmitter") then
                        local mag = (hrp.Position - obj.Parent.Position).Magnitude
                        if mag < Distance then
                            Distance = mag
                            Goal = obj.Parent
                        end
                    end
                end
            end
        end
    end
    return Goal, Distance
end

local function AdjustPower(distance)
    Player:SetAttribute("Power", 85)
end

local function Velocity()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Velocity or Vector3.zero
end

-- Fixed Silent Aim - Less Accurate (No Auto Greens)
local function AdjustCameraForJump()
    if not AimbotEnabled or not IsHoldingBasketball() then return end
    
    local Goal, Distance = GetGoal()
    if not Goal or Distance > 73 or Distance < 15 then return end

    local oldCFrame = Camera.CFrame
    
    local currentVelocity = Velocity()
    local velocityAdjustment = currentVelocity * 0.08
    
    local arcValue = ArcType == "High Arc" and HighArc(math.floor(Distance)) or LowArc(Distance)
    
    local BasketPosition = Goal.Position + Vector3.new(0, arcValue, 0) + velocityAdjustment

    AdjustPower(Distance)
    
    Camera.CFrame = CFrame.new(Character.Head.Position, BasketPosition)
    task.wait(0.015)
    performClick()
    task.wait(0.015)
    Camera.CFrame = oldCFrame
end

-- Mobile-compatible input detection
UserInputService.JumpRequest:Connect(function()
    if not AimbotEnabled then return end
    task.wait(ShotDelay)
    AdjustCameraForJump()
end)

-- Mobile & PC compatible Fake Shot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F and FakeShotEnabled then
        performFakeShot()
    end
end)

Player.CharacterAdded:Connect(function(char)
    Character = char
    task.wait(1)

    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        originalWalkSpeed = humanoid.WalkSpeed
    end

    if AntiTravelEnabled then
        monitorAntiTravelStates()
    end
    
    if KorbloxEnabled then
        applyKorblox()
    end
    
    if ShowNoLegEnabled then
        applyShowNoLeg()
    end
    
    if HeadlessEnabled then
        applyHeadless()
    end
    
    if WalkSpeedEnabled then
        applyWalkSpeed()
    end
end)

-- Initialize Walk Fling
startWalkFling()

-- Loading Screen Function
local function createLoadingScreen()
    local LoadingGui = Instance.new("ScreenGui")
    LoadingGui.Name = "CyroLoadingScreen"
    LoadingGui.Parent = Player:WaitForChild("PlayerGui")
    LoadingGui.ResetOnSpawn = false
    LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local Background = Instance.new("Frame")
    Background.Name = "Background"
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Background.BackgroundTransparency = 0.85
    Background.BorderSizePixel = 0
    Background.Parent = LoadingGui
    
    local BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Size = 24
    BlurEffect.Parent = Lighting
    
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 15)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 25, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
    })
    UIGradient.Rotation = 45
    UIGradient.Transparency = NumberSequence.new(0.85)
    UIGradient.Parent = Background
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Name = "CyroText"
    TextLabel.Size = UDim2.new(0, 600, 0, 100)
    TextLabel.Position = UDim2.new(0.5, 0, 0.45, 0)
    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = ""
    TextLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    TextLabel.Font = Enum.Font.FredokaOne
    TextLabel.TextSize = 80
    TextLabel.TextTransparency = 0
    TextLabel.Parent = Background
    
    local TextStroke = Instance.new("UIStroke")
    TextStroke.Color = Color3.fromRGB(0, 150, 255)
    TextStroke.Thickness = 3
    TextStroke.Parent = TextLabel
    
    local LogoImage = Instance.new("ImageLabel")
    LogoImage.Name = "Logo"
    LogoImage.Size = UDim2.new(0, 200, 0, 200)
    LogoImage.Position = UDim2.new(0.5, 0, 0.35, 0)
    LogoImage.AnchorPoint = Vector2.new(0.5, 0.5)
    LogoImage.BackgroundTransparency = 1
    LogoImage.Image = "http://www.roblox.com/asset/?id=117829546586449"
    LogoImage.ImageTransparency = 1
    LogoImage.ScaleType = Enum.ScaleType.Fit
    LogoImage.Parent = Background
    
    local LogoCorner = Instance.new("UICorner")
    LogoCorner.CornerRadius = UDim.new(0.2, 0)
    LogoCorner.Parent = LogoImage
    
    task.spawn(function()
        task.wait(0.3)
        
        local cyroText = "CYRO HUB"
        for i = 1, #cyroText do
            TextLabel.Text = string.sub(cyroText, 1, i)
            
            local scaleUp = TweenService:Create(TextLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                TextSize = 90
            })
            local scaleDown = TweenService:Create(TextLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                TextSize = 80
            })
            
            scaleUp:Play()
            scaleUp.Completed:Wait()
            scaleDown:Play()
            scaleDown.Completed:Wait()
            
            task.wait(0.2)
        end
        
        task.wait(0.5)
        
        local textFade = TweenService:Create(TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            Position = UDim2.new(0.5, 0, 0.65, 0),
            TextSize = 50
        })
        textFade:Play()
        textFade.Completed:Wait()
        
        local logoFadeIn = TweenService:Create(LogoImage, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 0
        })
        
        local logoScale = TweenService:Create(LogoImage, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 200, 0, 200)
        })
        
        LogoImage.Size = UDim2.new(0, 50, 0, 50)
        logoFadeIn:Play()
        logoScale:Play()
        
        task.wait(1.5)
        
        local fadeOut = TweenService:Create(Background, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 1
        })
        
        local logoFadeOut = TweenService:Create(LogoImage, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            ImageTransparency = 1
        })
        
        local textFadeOut = TweenService:Create(TextLabel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            TextTransparency = 1
        })
        
        fadeOut:Play()
        logoFadeOut:Play()
        textFadeOut:Play()
        
        local blurFadeOut = TweenService:Create(BlurEffect, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            Size = 0
        })
        blurFadeOut:Play()
        
        fadeOut.Completed:Wait()
        
        BlurEffect:Destroy()
        LoadingGui:Destroy()
    end)
    
    return LoadingGui
end

createLoadingScreen()

task.wait(4.5)

-- Nothing UI Library
local NothingLibrary = loadstring(game:HttpGet('https://raw.githubusercontent.com/Snxdfer/Nothing-UI-Library/refs/heads/main/source.lua'))()

local Windows = NothingLibrary.new({
    Title = "Cyro Hub",
    Description = "Optimized & Mobile Compatible",
    Keybind = Enum.KeyCode.LeftControl,
    Logo = 'http://www.roblox.com/asset/?id=117829546586449'
})

-- MAIN TAB (Previously Aimbot Tab)
local MainTab = Windows:NewTab({Title = "Main", Description = "Main Features", Icon = "rbxassetid://7733960981"})
local AimbotSection = MainTab:NewSection({Title = "Aimbot Settings", Icon = "rbxassetid://7743869054", Position = "Left"})
local CharacterSection = MainTab:NewSection({Title = "Character", Icon = "rbxassetid://7733964719", Position = "Right"})

-- EX TAB
local EXTab = Windows:NewTab({Title = "EX", Description = "Extended Features", Icon = "rbxassetid://7733964719"})
local MovementSection = EXTab:NewSection({Title = "Movement", Icon = "rbxassetid://7743869054", Position = "Left"})
local MagnetSection = EXTab:NewSection({Title = "Ball Magnet", Icon = "rbxassetid://7733964719", Position = "Right"})

-- SOCIAL TAB
local SocialTab = Windows:NewTab({Title = "Social", Description = "Social Features", Icon = "rbxassetid://7733964719"})
local SocialSection = SocialTab:NewSection({Title = "Utility Features", Icon = "rbxassetid://7733964719", Position = "Left"})
local DeviceSection = SocialTab:NewSection({Title = "Device Spoofer", Icon = "rbxassetid://7743869054", Position = "Right"})

-- EXTRAS TAB
local ExtrasTab = Windows:NewTab({Title = "Extras", Description = "Extra Features", Icon = "rbxassetid://7733964719"})
local ExtrasSection = ExtrasTab:NewSection({Title = "Utility", Icon = "rbxassetid://7743869054", Position = "Left"})

-- PERFORMANCE TAB
local PerformanceTab = Windows:NewTab({Title = "Performance", Description = "Performance Settings", Icon = "rbxassetid://7733964719"})
local PerformanceSection = PerformanceTab:NewSection({Title = "Optimization", Icon = "rbxassetid://7743869054", Position = "Left"})

-- ========== MAIN TAB ==========
-- Aimbot Settings
AimbotSection:NewToggle({
    Title = "Enable Aimbot",
    Default = false,
    Callback = function(Enabled)
        AimbotEnabled = Enabled
    end
})

AimbotSection:NewDropdown({
    Title = "Arc Type",
    Data = {"Low Arc", "High Arc"},
    Default = "Low Arc",
    Callback = function(SelectedArc)
        ArcType = SelectedArc
    end
})

AimbotSection:NewSlider({
    Title = "X Offset",
    Min = 0,
    Max = 100,
    Default = 43,
    Callback = function(Value)
        xClickOffset = Value
    end
})

-- Character Section (Moved from EX)
CharacterSection:NewToggle({
    Title = "Korblox",
    Default = false,
    Callback = function(Enabled)
        KorbloxEnabled = Enabled
        if Enabled then
            applyKorblox()
        else
            removeKorblox()
        end
    end
})

CharacterSection:NewToggle({
    Title = "Show No Leg",
    Default = false,
    Callback = function(Enabled)
        ShowNoLegEnabled = Enabled
        if Enabled then
            applyShowNoLeg()
        else
            removeShowNoLeg()
        end
    end
})

CharacterSection:NewToggle({
    Title = "Headless",
    Default = false,
    Callback = function(Enabled)
        HeadlessEnabled = Enabled
        if Enabled then
            applyHeadless()
        else
            removeHeadless()
        end
    end
})

-- ========== EX TAB ==========
-- WalkSpeed
MovementSection:NewToggle({
    Title = "WalkSpeed",
    Default = false,
    Callback = function(Enabled)
        WalkSpeedEnabled = Enabled
        applyWalkSpeed()
    end
})

MovementSection:NewSlider({
    Title = "WalkSpeed Value",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(Value)
        WalkSpeedValue = Value
    end
})

-- Ball Magnet (Moved from Main)
MagnetSection:NewToggle({
    Title = "Enable Mags",
    Default = false,
    Callback = function(Enabled)
        MagsEnabled = Enabled
        if Enabled then
            applyMags()
        end
    end
})

MagnetSection:NewSlider({
    Title = "Mags Amount",
    Min = 1,
    Max = 200,
    Default = 100,
    Callback = function(Value)
        MagsAmount = Value
    end
})

-- ========== SOCIAL TAB ==========
SocialSection:NewToggle({
    Title = "Auto Guard",
    Default = false,
    Callback = function(Enabled)
        setAutoGuard(Enabled)
    end
})

SocialSection:NewSlider({
    Title = "Guard Prediction",
    Min = 1,
    Max = 20,
    Default = 6,
    Callback = function(Value)
        PredictionMultiplier = Value
    end
})

SocialSection:NewToggle({
    Title = "Anti Travel",
    Default = false,
    Callback = function(Enabled)
        AntiTravelEnabled = Enabled
        if Enabled then
            monitorAntiTravelStates()
        else
            if antiTravelConnection then
                antiTravelConnection:Disconnect()
                antiTravelConnection = nil
            end
            renameToBasketball()
        end
    end
})

SocialSection:NewToggle({
    Title = "Auto Dunk",
    Default = false,
    Callback = function(Enabled)
        AutoDunkEnabled = Enabled
        toggleAutoDunk()
    end
})

-- Device Spoofer
DeviceSection:NewToggle({
    Title = "Enable Device Spoofer",
    Default = false,
    Callback = function(Enabled)
        DeviceSpooferEnabled = Enabled
        if DeviceSpooferEnabled then
            FireDeviceEvent()
        end
    end
})

DeviceSection:NewDropdown({
    Title = "Device Type",
    Data = {"PC", "Mobile", "Console"},
    Default = "PC",
    Callback = function(SelectedDevice)
        DeviceType = SelectedDevice
        if DeviceSpooferEnabled then
            FireDeviceEvent()
        end
    end
})

-- ========== EXTRAS TAB ==========
ExtrasSection:NewToggle({
    Title = "Fake Shot (Press F)",
    Default = false,
    Callback = function(Enabled)
        FakeShotEnabled = Enabled
    end
})

ExtrasSection:NewToggle({
    Title = "Walk Fling",
    Default = false,
    Callback = function(Enabled)
        WalkFlingEnabled = Enabled
    end
})

ExtrasSection:NewSlider({
    Title = "Walk Fling Power",
    Min = 1,
    Max = 500,
    Default = 100,
    Callback = function(Value)
        WalkFlingPower = Value
    end
})

-- ========== PERFORMANCE TAB ==========
PerformanceSection:NewToggle({
    Title = "FPS Booster",
    Default = false,
    Callback = function(Enabled)
        FPSBoosterEnabled = Enabled
        applyFPSBooster()
    end
})

PerformanceSection:NewToggle({
    Title = "Anti Lag",
    Default = false,
    Callback = function(Enabled)
        AntiLagEnabled = Enabled
        applyAntiLag()
    end
})
