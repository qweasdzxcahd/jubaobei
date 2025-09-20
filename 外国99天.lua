local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Window = WindUI:CreateWindow({
    Folder = " Scripts",
    Title = "猫羽雫脚本",
    Icon = "star",
    Author = "猫羽雫",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 350),
    HasOutline = true,
})

Window:EditOpenButton({
    Title = "打开猫羽雫脚本",
    Icon = "pointer",
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromRGB(200, 0, 255), Color3.fromRGB(0, 200, 255)),
    Draggable = true,
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "star" }),
    Teleport = Window:Tab({ Title = "Teleport", Icon = "rocket" }),
    Bring = Window:Tab({ Title = "Bring Items", Icon = "package" }),
    Hitbox = Window:Tab({ Title = "Hitbox", Icon = "target" }),
    AutoDays = Window:Tab({ Title = "Auto days", Icon = "sun" }),
    KillAll = Window:Tab({ Title = "Kill All Mobs", Icon = "skull" }),
    Misc = Window:Tab({ Title = "Misc", Icon = "tool" }),
    Esp = Window:Tab({ Title = "Esp", Icon = "eye" }),
    Credits = Window:Tab({ Title = "Credits", Icon = "award" })
}



local itemsToCompress = {
    "Bolt",
    "Sheet Metal",
    "UFO Junk",
    "UFO Component",
    "Broken Fan",
    "Log",
    "Broken Radio",
    "Broken Microwave",
    "Tyre",
    "Metal Chair",
    "Old Car Engine",
    "Washing Machine",
    "Cultist Experiment",
    "Cultist Prototype",
    "UFO Scrap"
}

getgenv().AutoWoodCompressList = {}
getgenv().AutoWoodCompressOn = false

local woodCutterPos = Vector3.new(21.15, 19, -6.12)

Tabs.Main:Dropdown({
    Title = "Choose Items To Auto Compress",
    Values = itemsToCompress,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selected)
        getgenv().AutoWoodCompressList = {}
        for _, item in ipairs(selected) do
            getgenv().AutoWoodCompressList[item] = true
        end
    end
})

Tabs.Main:Toggle({
    Title = "Auto Wood Compress",
    Default = false,
    Callback = function(state)
        getgenv().AutoWoodCompressOn = state
    end
})

local itemsFolder = Workspace:WaitForChild("Items")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local function moveItemToWoodCutter(item)
    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("Handle")
    if not part then return end
    if not item.PrimaryPart then pcall(function() item.PrimaryPart = part end) end
    pcall(function()
        remoteEvents.RequestStartDraggingItem:FireServer(item)
        task.wait(0.05)
        item:SetPrimaryPartCFrame(CFrame.new(woodCutterPos))
        task.wait(0.05)
        remoteEvents.StopDraggingItem:FireServer(item)
    end)
end

coroutine.wrap(function()
    while true do
        if getgenv().AutoWoodCompressOn then
            for itemName, enabled in pairs(getgenv().AutoWoodCompressList) do
                if enabled then
                    for _, item in ipairs(itemsFolder:GetChildren()) do
                        if item.Name == itemName then
                            moveItemToWoodCutter(item)
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
end)()




local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

getgenv().KillAuraActive = false
getgenv().KillAuraRadius = 100

local toolsDamageIDs = {
    ["Old Axe"] = "1_8982038982",
    ["Good Axe"] = "112_8982038982",
    ["Strong Axe"] = "116_8982038982",
    ["Chainsaw"] = "647_8992824875",
    ["Spear"] = "196_8999010016"
}

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ToolDamageObject = RemoteEvents:WaitForChild("ToolDamageObject")
local EquipItemHandle = RemoteEvents:WaitForChild("EquipItemHandle")
local UnequipItemHandle = RemoteEvents:WaitForChild("UnequipItemHandle")

local function getAnyToolWithDamageID()
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    if not inventory then return nil, nil end
    for toolName, damageID in pairs(toolsDamageIDs) do
        local tool = inventory:FindFirstChild(toolName)
        if tool then
            return tool, damageID
        end
    end
    return nil, nil
end

local function equipTool(tool)
    if tool then
        EquipItemHandle:FireServer("FireAllClients", tool)
    end
end

Tabs.KillAll:Toggle({
    Title = "Kill Aura",
    Default = false,
    Callback = function(state)
        getgenv().KillAuraActive = state
    end
})



Tabs.KillAll:Slider({
    Title = "Kill Aura Radius",
    Step = 1,
    Value = {Min = 10, Max = 150, Default = 100},
    Callback = function(val)
        getgenv().KillAuraRadius = tonumber(val)
    end
})

task.spawn(function()
    while true do
        if getgenv().KillAuraActive then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local tool, damageID = getAnyToolWithDamageID()
                if tool and damageID then
                    equipTool(tool)
                    for _, mob in ipairs(Workspace:WaitForChild("Characters"):GetChildren()) do
                        if mob:IsA("Model") then
                            local part = mob:FindFirstChildWhichIsA("BasePart")
                            if part and (part.Position - hrp.Position).Magnitude <= tonumber(getgenv().KillAuraRadius) then
                                pcall(function()
                                    ToolDamageObject:InvokeServer(
                                        mob,
                                        tool,
                                        damageID,
                                        CFrame.new(part.Position)
                                    )
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)