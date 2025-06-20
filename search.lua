-- CONFIGURATION
local brainrots = {
    "Graipuss Medussi",
    "Odin Din Din Dun",
    "Tralalero Tralala"
}

local checkInterval = 1 -- seconds between re-checks

-- STATE
local foundOnce = false
local checking = true
local firstCheckDone = false

-- GUI SETUP
local function createStatusGUI()
    local player = game.Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "BrainrotStatusGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "StatusFrame"
    frame.Size = UDim2.new(0, 280, 0, 180)
    frame.Position = UDim2.new(1, -290, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Name = "StatusText"
    label.Size = UDim2.new(1, -10, 0.6, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = "🔍 Checking..."
    label.Parent = frame

    local yesButton = Instance.new("TextButton")
    yesButton.Name = "YesButton"
    yesButton.Text = "Yes (Hop)"
    yesButton.Size = UDim2.new(0.5, -5, 0.25, 0)
    yesButton.Position = UDim2.new(0, 5, 0.7, 0)
    yesButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesButton.Font = Enum.Font.SourceSansBold
    yesButton.TextSize = 16
    yesButton.Visible = false
    yesButton.Parent = frame

    local noButton = Instance.new("TextButton")
    noButton.Name = "NoButton"
    noButton.Text = "No (Stay)"
    noButton.Size = UDim2.new(0.5, -5, 0.25, 0)
    noButton.Position = UDim2.new(0.5, 0, 0.7, 0)
    noButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    noButton.Font = Enum.Font.SourceSansBold
    noButton.TextSize = 16
    noButton.Visible = false
    noButton.Parent = frame

    return label, yesButton, noButton
end

-- FUNCTION TO CHECK FOR BRAINROTS
local function isBrainrotName(name)
    for _, brainrot in ipairs(brainrots) do
        if name == brainrot then return true end
    end
    return false
end

local function checkForBrainrots()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then
        warn("❌ Plots folder not found.")
        return 0, {}, 0
    end

    local foundCount = 0
    local foundTypes = {}
    local totalAnimalsChecked = 0

    for _, plot in pairs(plots:GetChildren()) do
        local animalPodiums = plot:FindFirstChild("AnimalPodiums")
        if animalPodiums then
            for _, podium in pairs(animalPodiums:GetChildren()) do
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                local attach = spawn and spawn:FindFirstChild("Attachment")
                local overhead = attach and attach:FindFirstChild("AnimalOverhead")
                local displayName = overhead and overhead:FindFirstChild("DisplayName")

                if displayName and displayName:IsA("TextLabel") then
                    local name = displayName.Text
                    totalAnimalsChecked += 1
                    print("🐾 Found animal: " .. name)
                    if isBrainrotName(name) then
                        foundCount += 1
                        foundTypes[name] = (foundTypes[name] or 0) + 1
                    end
                end
            end
        end
    end

    return foundCount, foundTypes, totalAnimalsChecked
end

-- SERVER HOP FUNCTION (no HTTP needed)
local function serverHop()
    local TeleportService = game:GetService("TeleportService")
    local LocalPlayer = game.Players.LocalPlayer
    print("🔁 Hopping to new server...")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

-- MAIN LOOP
local function runChecker()
    local statusLabel, yesBtn, noBtn = createStatusGUI()

    yesBtn.MouseButton1Click:Connect(function()
        checking = false
        serverHop()
    end)

    noBtn.MouseButton1Click:Connect(function()
        yesBtn.Visible = false
        noBtn.Visible = false
    end)

    while checking do
        local count, types, totalAnimals = checkForBrainrots()

        if totalAnimals == 0 then
            statusLabel.Text = "⌛ No animals detected yet. Waiting..."
            wait(1)
        elseif count > 0 then
            foundOnce = true
            local msg = "✅ Found " .. count .. " brainrot(s):\n"
            for name, amt in pairs(types) do
                msg = msg .. "• " .. name .. " ×" .. amt .. "\n"
            end
            statusLabel.Text = msg
            yesBtn.Visible = false
            noBtn.Visible = false
        else
            statusLabel.Text = "❌ No brainrots found."

            if not firstCheckDone then
                print("🚫 No brainrots on first full check — hopping.")
                wait(1)
                serverHop()
                return
            elseif foundOnce then
                yesBtn.Visible = true
                noBtn.Visible = true
            end
        end

        if totalAnimals > 0 then
            firstCheckDone = true
        end

        wait(checkInterval)
    end
end

-- SAFE START
local success, err = pcall(runChecker)
if not success then
    warn("❌ Script error:", err)
end
