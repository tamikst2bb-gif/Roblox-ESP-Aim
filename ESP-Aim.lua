local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("ESPAimOverlay")
if previous then
    previous:Destroy()
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local window = Rayfield:CreateWindow({
    Name = "ESP + Aim",
    ToggleUIKeybind = Enum.KeyCode.F3,
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
})

local S = {
    PlayerESP = true,
    NpcESP = false,
    Boxes = true,
    Labels = true,
    Skeleton = false,
    Outline = false,
    Tracers = false,
    PlayerColor = Color3.fromRGB(255, 98, 112),
    NpcColor = Color3.fromRGB(116, 216, 255),
    PlayerRange = 1500,
    NpcRange = 1500,
    Aimbot_Enabled = false,
    Aimbot_WallCheck = true,
    Aimbot_Target_NPCs = false,
    Aim_Smoothing = 0.25,
    Aim_FOV = 150,
    Show_FOV = false,
    Prediction_Enabled = false,
    Bullet_Speed = 1500,
}

local function toggle(tab, label, key)
    tab:CreateToggle({
        Name = label,
        Flag = key,
        CurrentValue = S[key],
        Callback = function(value) S[key] = value end,
    })
end

local function slider(tab, label, key, min, max, step)
    tab:CreateSlider({
        Name = label,
        Flag = key,
        Range = { min, max },
        Increment = step,
        CurrentValue = S[key],
        Callback = function(value) S[key] = value end,
    })
end

local function colorPicker(tab, label, key)
    tab:CreateColorPicker({
        Name = label,
        Flag = key,
        Color = S[key],
        Callback = function(value) S[key] = value end,
    })
end

local espTab = window:CreateTab("ESP")
toggle(espTab, "Игроки", "PlayerESP")
toggle(espTab, "NPC", "NpcESP")
toggle(espTab, "Рамки", "Boxes")
toggle(espTab, "Имя и дистанция", "Labels")
toggle(espTab, "Скелет", "Skeleton")
toggle(espTab, "Контур сквозь стены", "Outline")
toggle(espTab, "Линии от низа экрана", "Tracers")
colorPicker(espTab, "Цвет игроков", "PlayerColor")
colorPicker(espTab, "Цвет NPC", "NpcColor")
slider(espTab, "Дальность игроков (студы)", "PlayerRange", 50, 5000, 50)
slider(espTab, "Дальность NPC (студы)", "NpcRange", 50, 5000, 50)

local combatTab = window:CreateTab("Аимбот")
toggle(combatTab, "Аимбот (ПКМ)", "Aimbot_Enabled")
toggle(combatTab, "Проверка стен", "Aimbot_WallCheck")
toggle(combatTab, "Целиться в NPC", "Aimbot_Target_NPCs")
toggle(combatTab, "Упреждение", "Prediction_Enabled")
slider(combatTab, "Плавность", "Aim_Smoothing", 0.1, 1, 0.05)
toggle(combatTab, "Показать круг FOV", "Show_FOV")
slider(combatTab, "Радиус FOV (пиксели)", "Aim_FOV", 50, 800, 10)

local gui = Instance.new("ScreenGui")
gui.Name = "ESPAimOverlay"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.None
gui.Parent = playerGui

local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "ESPAimHighlights"
highlightFolder.Parent = Workspace

local function frame(parent)
    local item = Instance.new("Frame")
    item.BackgroundTransparency = 1
    item.BorderSizePixel = 0
    item.Parent = parent
    return item
end

local function stroke(parent, thickness)
    local item = Instance.new("UIStroke")
    item.Thickness = thickness
    item.Parent = parent
    return item
end

local center = Vector2.new(0.5, 0.5)
local circle = frame(gui)
circle.AnchorPoint = center
circle.Visible = false
Instance.new("UICorner", circle).CornerRadius = UDim.new(0.5, 0)
stroke(circle, 1).Color = Color3.new(1, 1, 1)

local r6 = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}
local r15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}

local function makeLine(parent)
    local line = frame(parent)
    line.AnchorPoint = center
    line.BackgroundTransparency = 0
    line.Visible = false
    return line
end

local function setLine(line, ax, ay, bx, by, color)
    local dx, dy = bx - ax, by - ay
    line.Position = UDim2.fromOffset((ax + bx) * 0.5, (ay + by) * 0.5)
    line.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 1.5)
    line.Rotation = math.deg(math.atan2(dy, dx))
    line.BackgroundColor3 = color
    line.Visible = true
end

local overlays = {}
local frameId = 0

local function makeOverlay()
    local layer = frame(gui)
    layer.Size = UDim2.fromScale(1, 1)
    local box = frame(layer)
    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(240, 18)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextStrokeTransparency = 0.25
    label.Parent = layer
    return {
        layer = layer,
        box = box,
        border = stroke(box, 1.5),
        label = label,
        tracer = makeLine(layer),
        bones = {},
    }
end

local function clearOverlay(character)
    local overlay = overlays[character]
    if not overlay then return end
    overlay.layer:Destroy()
    if overlay.highlight then overlay.highlight:Destroy() end
    overlays[character] = nil
end

local function getScreenBounds(character, camera)
    local bounds, size = character:GetBoundingBox()
    local half = size * 0.5
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local corner = bounds:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
                local point = camera:WorldToViewportPoint(corner)
                if point.Z <= 0.05 then return end
                minX, minY = math.min(minX, point.X), math.min(minY, point.Y)
                maxX, maxY = math.max(maxX, point.X), math.max(maxY, point.Y)
            end
        end
    end
    return minX, minY, maxX, maxY
end

local function drawBones(overlay, character, humanoid, camera, color)
    local rig = humanoid.RigType == Enum.HumanoidRigType.R6 and r6 or r15
    for index, joint in ipairs(rig) do
        local line = overlay.bones[index]
        if not line then
            line = makeLine(overlay.layer)
            overlay.bones[index] = line
        end
        local first = character:FindFirstChild(joint[1])
        local second = character:FindFirstChild(joint[2])
        line.Visible = false
        if first and second and first:IsA("BasePart") and second:IsA("BasePart") then
            local a = camera:WorldToViewportPoint(first.Position)
            local b = camera:WorldToViewportPoint(second.Position)
            if a.Z > 0.05 and b.Z > 0.05 then
                setLine(line, a.X, a.Y, b.X, b.Y, color)
            end
        end
    end
end

local function drawESP(character, camera, name, range, color)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart")
        or not character:IsDescendantOf(Workspace) then return end

    local distance = (root.Position - camera.CFrame.Position).Magnitude
    if distance > range then return end

    local overlay = overlays[character]
    local viewport = camera.ViewportSize
    local left, top, right, bottom = getScreenBounds(character, camera)
    local onScreen = left ~= nil and right >= 0 and bottom >= 0 and left <= viewport.X and top <= viewport.Y
    if not onScreen then
        if overlay then
            overlay.frame = frameId
            overlay.layer.Visible = false
            if overlay.highlight then
                if S.Outline then
                    overlay.highlight.Enabled = false
                else
                    overlay.highlight:Destroy()
                    overlay.highlight = nil
                end
            end
        end
        return
    end

    if not overlay then
        overlay = makeOverlay()
        overlays[character] = overlay
    end
    overlay.frame = frameId
    overlay.layer.Visible = true
    overlay.box.Visible = S.Boxes
    overlay.label.Visible = S.Labels
    overlay.tracer.Visible = false

    local mid = (left + right) * 0.5
    if S.Boxes then
        overlay.box.Position = UDim2.fromOffset(left, top)
        overlay.box.Size = UDim2.fromOffset(right - left, bottom - top)
        overlay.border.Color = color
    end
    if S.Labels then
        overlay.label.Position = UDim2.fromOffset(mid, top - 3)
        overlay.label.Text = string.format("%s  [%d st]", name, math.round(distance))
        overlay.label.TextColor3 = color
    end
    if S.Tracers then
        setLine(overlay.tracer, viewport.X * 0.5, viewport.Y - 1, mid, bottom, color)
    end
    for _, line in ipairs(overlay.bones) do line.Visible = false end
    if S.Skeleton then drawBones(overlay, character, humanoid, camera, color) end

    if S.Outline then
        if not overlay.highlight then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 1
            highlight.Parent = highlightFolder
            overlay.highlight = highlight
        end
        overlay.highlight.OutlineColor = color
        overlay.highlight.Enabled = true
    elseif overlay.highlight then
        overlay.highlight:Destroy()
        overlay.highlight = nil
    end
end

local npcs = {}
local function trackHumanoid(instance)
    local model = instance.Parent
    if instance:IsA("Humanoid") and model and model:IsA("Model") then
        npcs[model] = instance
    end
end

local added = Workspace.DescendantAdded:Connect(trackHumanoid)
local removing = Workspace.DescendantRemoving:Connect(function(instance)
    if npcs[instance] then npcs[instance] = nil end
    local model = instance.Parent
    if model and npcs[model] == instance then npcs[model] = nil end
end)

task.spawn(function()
    for index, instance in ipairs(Workspace:GetDescendants()) do
        if not gui.Parent then return end
        if instance:IsDescendantOf(Workspace) then trackHumanoid(instance) end
        if index % 500 == 0 then task.wait() end
    end
end)

local function isNpc(model, humanoid)
    return humanoid.Health > 0 and model:IsDescendantOf(Workspace)
        and model:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(model)
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local visibilityCache = setmetatable({}, { __mode = "k" })

-- The original wall check accepts a visible limb while the aim point stays on the head.
local function isVisible(character, camera)
    local now = os.clock()
    local cached = visibilityCache[character]
    if cached and now - cached.time < 0.1 then return cached.visible end
    local parts = {
        character:FindFirstChild("Head"),
        character:FindFirstChild("HumanoidRootPart"),
        character:FindFirstChild("Right Arm") or character:FindFirstChild("RightUpperArm"),
        character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftUpperArm"),
        character:FindFirstChild("Right Leg") or character:FindFirstChild("RightUpperLeg"),
        character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftUpperLeg"),
    }
    local origin = camera.CFrame.Position
    local visible = false
    for _, part in pairs(parts) do
        if part:IsA("BasePart") then
            local result = Workspace:Raycast(origin, part.Position - origin, rayParams)
            if result and result.Instance:IsDescendantOf(character) then
                visible = true
                break
            end
        end
    end
    visibilityCache[character] = { time = now, visible = visible }
    return visible
end

local function aim(camera, mouse, players)
    if not S.Aimbot_Enabled or type(mousemoverel) ~= "function"
        or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    rayParams.FilterDescendantsInstances = { localPlayer.Character, camera }
    local target
    local bestDistance = S.Aim_FOV

    local function consider(character)
        local part = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
        if not part or not part:IsA("BasePart") then return end
        local point, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then return end
        local distance = (Vector2.new(point.X, point.Y) - mouse).Magnitude
        if distance < bestDistance and (not S.Aimbot_WallCheck or isVisible(character, camera)) then
            target, bestDistance = part, distance
        end
    end

    for _, player in ipairs(players) do
        if player ~= localPlayer and player.Character
            and (player.Team ~= localPlayer.Team or player.Team == nil) then
            consider(player.Character)
        end
    end
    if S.Aimbot_Target_NPCs then
        for model, humanoid in pairs(npcs) do
            if isNpc(model, humanoid) then consider(model) end
        end
    end
    if not target then return end

    local position = target.Position
    if S.Prediction_Enabled then
        local distance = (position - camera.CFrame.Position).Magnitude
        position += target.AssemblyLinearVelocity * (distance / math.max(S.Bullet_Speed, 1))
    end
    local point, onScreen = camera:WorldToViewportPoint(position)
    if onScreen then
        mousemoverel((point.X - mouse.X) * S.Aim_Smoothing, (point.Y - mouse.Y) * S.Aim_Smoothing)
    end
end

local render = RunService.RenderStepped:Connect(function()
    if not gui.Parent then return end
    frameId += 1
    local camera = Workspace.CurrentCamera
    local localCharacter = localPlayer.Character
    local ready = camera and localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    circle.Visible = ready and S.Show_FOV or false

    if ready then
        local mouse = UserInputService:GetMouseLocation()
        if circle.Visible then
            circle.Position = UDim2.fromOffset(mouse.X, mouse.Y)
            circle.Size = UDim2.fromOffset(S.Aim_FOV * 2, S.Aim_FOV * 2)
        end

        local players = Players:GetPlayers()
        if S.Boxes or S.Labels or S.Skeleton or S.Tracers or S.Outline then
            if S.PlayerESP then
                for _, player in ipairs(players) do
                    if player ~= localPlayer and player.Character then
                        drawESP(player.Character, camera, player.Name, S.PlayerRange, S.PlayerColor)
                    end
                end
            end
            if S.NpcESP then
                for model, humanoid in pairs(npcs) do
                    if isNpc(model, humanoid) then
                        drawESP(model, camera, "[NPC] " .. model.Name, S.NpcRange, S.NpcColor)
                    end
                end
            end
        end
        aim(camera, mouse, players)
    end

    for character, overlay in pairs(overlays) do
        if overlay.frame ~= frameId then clearOverlay(character) end
    end
end)

gui.Destroying:Once(function()
    render:Disconnect()
    added:Disconnect()
    removing:Disconnect()
    highlightFolder:Destroy()
    Rayfield:Destroy()
end)
