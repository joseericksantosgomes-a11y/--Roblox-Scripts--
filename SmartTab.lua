--[[
    Smart Tab Library v12
    Versão limpa e estável
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PendingTabs = {}
local PendingElements = {}
local Tabs = {} -- [name] = {button, panel, content}
local ActiveTab = nil

local function clearList(t)
    for i = #t, 1, -1 do
        t[i] = nil
    end
end

-- ====================== FIND HUB ======================
local function findHubBarContainer()
    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if not robloxGui then return nil end
    local shield = robloxGui:FindFirstChild("SettingsClippingShield")
    if not shield then return nil end
    local settings = shield:FindFirstChild("SettingsShield")
    if not settings then return nil end
    local menu = settings:FindFirstChild("MenuContainer")
    if not menu then return nil end
    local page = menu:FindFirstChild("Page")
    if not page then return nil end
    local hubBar = page:FindFirstChild("HubBar")
    if not hubBar then return nil end
    local header = hubBar:FindFirstChild("TabHeaderContainer")
    if not header then return nil end
    return header:FindFirstChild("HubBarContainer"), menu
end

-- ====================== CREATE TAB BUTTON ======================
local function ensureScroll(hub)
    local scroll = hub:FindFirstChild("SmartTabScroll")
    if scroll then return scroll end

    scroll = Instance.new("ScrollingFrame")
    scroll.Name = "SmartTabScroll"
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(160, 160, 160)
    scroll.ScrollingDirection = Enum.ScrollingDirection.X
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.ClipsDescendants = true
    scroll.ZIndex = 4
    scroll.Parent = hub

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 0)
    layout.Parent = scroll

    -- move tabs nativos
    for _, child in ipairs(hub:GetChildren()) do
        if child:IsA("TextButton") and not child:GetAttribute("SmartTab") then
            child.Parent = scroll
        end
    end

    local old = hub:FindFirstChildOfClass("UIListLayout")
    if old then old:Destroy() end

    return scroll
end

local function createTabButton(hub, config)
    if Tabs[config.Name] and Tabs[config.Name].button and Tabs[config.Name].button.Parent then
        return Tabs[config.Name]
    end

    local scroll = ensureScroll(hub)
    local tabName = "Smart_" .. config.Name:gsub("%s+", "")

    if scroll:FindFirstChild(tabName) then
        return Tabs[config.Name]
    end

    local btn = Instance.new("TextButton")
    btn.Name = tabName
    btn:SetAttribute("SmartTab", true)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.LayoutOrder = 999
    btn.ZIndex = 5
    btn.Parent = scroll

    local sel = Instance.new("Frame")
    sel.Name = "TabSelection"
    sel.Visible = false
    sel.BackgroundColor3 = Color3.new(1, 1, 1)
    sel.BorderSizePixel = 0
    sel.Position = UDim2.new(0, 8, 1, -2)
    sel.Size = UDim2.new(1, -16, 0, 2)
    sel.ZIndex = 5
    sel.Parent = btn

    local label = Instance.new("Frame")
    label.Name = "TabLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.ZIndex = 5
    label.Parent = btn

    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay.VerticalAlignment = Enum.VerticalAlignment.Center
    lay.Padding = UDim.new(0, 5)
    lay.Parent = label

    local icon
    local iconStr = tostring(config.Icon or "star")
    if string.find(iconStr, "rbxassetid://") or tonumber(iconStr) then
        icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Image = string.find(iconStr, "rbxassetid://") and iconStr or ("rbxassetid://" .. iconStr)
        icon.ImageTransparency = 0.5
        icon.ZIndex = 5
        icon.Parent = label
    else
        icon = Instance.new("TextLabel")
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Text = iconStr
        icon.TextColor3 = Color3.new(1, 1, 1)
        icon.TextTransparency = 0.5
        icon.TextScaled = true
        icon.ZIndex = 5
        icon.Parent = label
    end

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Text = config.Name
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextTransparency = 0.5
    title.TextSize = 12
    title.Font = Enum.Font.GothamMedium
    title.AutomaticSize = Enum.AutomaticSize.XY
    title.ZIndex = 5
    title.Parent = label

    local function setActive(on)
        sel.Visible = on
        if icon:IsA("ImageLabel") then
            icon.ImageTransparency = on and 0 or 0.5
        else
            icon.TextTransparency = on and 0 or 0.5
        end
        title.TextTransparency = on and 0 or 0.5
    end

    -- painel de conteúdo (ScreenGui separado, estável)
    local gui = Instance.new("ScreenGui")
    gui.Name = "SmartPanel_" .. config.Name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100
    gui.Enabled = false
    gui.Parent = CoreGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0.5, 1)
    panel.Position = UDim2.new(0.5, 0, 1, -20)
    panel.Size = UDim2.new(0, 500, 0, 420)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    panel.BackgroundTransparency = 0.15
    panel.BorderSizePixel = 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Content"
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
    scroll.Parent = panel

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 16)
    pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)
    pad.Parent = scroll

    local data = {
        button = btn,
        setActive = setActive,
        gui = gui,
        panel = panel,
        content = scroll,
        rows = {},
        name = config.Name
    }
    Tabs[config.Name] = data

    btn.MouseButton1Click:Connect(function()
        -- desativa todas
        for _, t in pairs(Tabs) do
            t.setActive(false)
            t.gui.Enabled = false
        end
        setActive(true)
        gui.Enabled = true
        ActiveTab = config.Name
    end)

    -- quando clicar em tab nativa, fecha painel custom
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") and not child:GetAttribute("SmartTab") and not child:GetAttribute("SmartHook") then
            child:SetAttribute("SmartHook", true)
            child.MouseButton1Click:Connect(function()
                for _, t in pairs(Tabs) do
                    t.setActive(false)
                    t.gui.Enabled = false
                end
                ActiveTab = nil
            end)
        end
    end

    return data
end

-- ====================== COMPONENTS ======================
local function getRow(tabData, pos)
    if pos ~= "Left" and pos ~= "Right" then
        return tabData.content
    end
    local last = tabData.rows[#tabData.rows]
    if last and last.count < 2 then
        last.count = last.count + 1
        return last.frame
    end
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 40)
    row.Parent = tabData.content
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = row
    local info = {frame = row, count = 1}
    table.insert(tabData.rows, info)
    return row
end

local function addButton(tabData, data)
    local pos = data.ButtonPosition or data.Position or "None"
    local parent = getRow(tabData, pos)

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = (pos == "Left" or pos == "Right") and UDim2.new(0.5, -4, 1, 0) or UDim2.new(1, 0, 0, 40)
    frame.LayoutOrder = pos == "Right" and 2 or 1
    frame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0.5, -18)
    btn.BackgroundColor3 = Color3.fromRGB(208, 217, 251)
    btn.BackgroundTransparency = 0.85
    btn.Text = data.Text or "Botão"
    btn.TextColor3 = Color3.fromRGB(247, 247, 248)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        if data.Callback then task.spawn(data.Callback) end
    end)
end

local function addBlueButton(tabData, data)
    local pos = data.ButtonPosition or data.Position or "None"
    local parent = getRow(tabData, pos)

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = (pos == "Left" or pos == "Right") and UDim2.new(0.5, -4, 1, 0) or UDim2.new(1, 0, 0, 40)
    frame.LayoutOrder = pos == "Right" and 2 or 1
    frame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0.5, -18)
    btn.BackgroundColor3 = Color3.fromRGB(51, 95, 255)
    btn.BackgroundTransparency = 0.5
    btn.Text = data.Text or "Continuar"
    btn.TextColor3 = Color3.fromRGB(235, 241, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        if data.Callback then task.spawn(data.Callback) end
    end)
end

local function addLabel(tabData, data)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, data.Description and 46 or 26)
    frame.Parent = tabData.content

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Text = data.Text or "Seção"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.Parent = frame

    if data.Description then
        local desc = Instance.new("TextLabel")
        desc.BackgroundTransparency = 1
        desc.Position = UDim2.new(0, 0, 0, 22)
        desc.Size = UDim2.new(1, 0, 0, 20)
        desc.Text = data.Description
        desc.TextColor3 = Color3.fromRGB(160, 160, 170)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.Parent = frame
    end
end

local function addToggle(tabData, data)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.Parent = tabData.content

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Text = data.Text or "Toggle"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.AnchorPoint = Vector2.new(1, 0.5)
    toggle.Position = UDim2.new(1, 0, 0.5, 0)
    toggle.Size = UDim2.new(0, 48, 0, 26)
    toggle.BackgroundColor3 = Color3.fromRGB(56, 57, 59)
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = frame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = UDim2.new(0, 3, 0.5, -10)
    circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    circle.BorderSizePixel = 0
    circle.Parent = toggle
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local state = data.Default or false
    local function update()
        TweenService:Create(circle, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
            BackgroundColor3 = state and Color3.new(1,1,1) or Color3.fromRGB(200,200,200)
        }):Play()
        TweenService:Create(toggle, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(51, 95, 255) or Color3.fromRGB(56, 57, 59)
        }):Play()
    end
    update()

    toggle.MouseButton1Click:Connect(function()
        state = not state
        update()
        if data.Callback then task.spawn(data.Callback, state) end
    end)
end

local function addDropdown(tabData, data)
    local options = data.Options or {"Opção 1", "Opção 2"}
    local isOpen = false

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.ClipsDescendants = false
    frame.Parent = tabData.content

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Text = data.Text or "Opção"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = frame

    local drop = Instance.new("TextButton")
    drop.AnchorPoint = Vector2.new(1, 0.5)
    drop.Position = UDim2.new(1, 0, 0.5, 0)
    drop.Size = UDim2.new(0.55, 0, 0, 34)
    drop.BackgroundColor3 = Color3.fromRGB(45, 46, 48)
    drop.Text = ""
    drop.AutoButtonColor = false
    drop.Parent = frame
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0, 6)

    local cur = Instance.new("TextLabel")
    cur.BackgroundTransparency = 1
    cur.Position = UDim2.new(0, 12, 0, 0)
    cur.Size = UDim2.new(1, -36, 1, 0)
    cur.Text = options[1]
    cur.TextColor3 = Color3.new(1, 1, 1)
    cur.TextXAlignment = Enum.TextXAlignment.Left
    cur.Font = Enum.Font.Gotham
    cur.TextSize = 13
    cur.Parent = drop

    local arrow = Instance.new("TextLabel")
    arrow.BackgroundTransparency = 1
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -8, 0.5, 0)
    arrow.Size = UDim2.new(0, 16, 0, 16)
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
    arrow.TextSize = 10
    arrow.Parent = drop

    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.fromRGB(35, 36, 38)
    listFrame.Position = UDim2.new(0.45, 0, 0, 42)
    listFrame.Size = UDim2.new(0.55, 0, 0, 0)
    listFrame.ClipsDescendants = true
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.Parent = frame
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", listFrame).SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 32)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.new(1, 1, 1)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 13
        optBtn.ZIndex = 11
        optBtn.Parent = listFrame
        optBtn.MouseButton1Click:Connect(function()
            cur.Text = opt
            isOpen = false
            listFrame.Visible = false
            listFrame.Size = UDim2.new(0.55, 0, 0, 0)
            frame.Size = UDim2.new(1, 0, 0, 44)
            arrow.Text = "▼"
            if data.Callback then task.spawn(data.Callback, opt, i) end
        end)
    end

    drop.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local h = #options * 32
            listFrame.Visible = true
            listFrame.Size = UDim2.new(0.55, 0, 0, h)
            frame.Size = UDim2.new(1, 0, 0, 44 + h + 4)
            arrow.Text = "▲"
        else
            listFrame.Visible = false
            listFrame.Size = UDim2.new(0.55, 0, 0, 0)
            frame.Size = UDim2.new(1, 0, 0, 44)
            arrow.Text = "▼"
        end
    end)
end

-- ====================== API ======================
function Tab(data)
    if type(data) ~= "table" then return end
    table.insert(PendingTabs, {
        Name = data.Name or "Tab",
        Icon = data.Icon or "star"
    })
end

function Button(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Button", Tab = data.Tab, Text = data.Text or "Botão",
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        Callback = data.Callback
    })
end

function BlueButton(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "BlueButton", Tab = data.Tab, Text = data.Text or "Continuar",
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        Callback = data.Callback
    })
end

function Label(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Label", Tab = data.Tab, Text = data.Text or "Seção",
        Description = data.Description
    })
end

function Toggle(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Toggle", Tab = data.Tab, Text = data.Text or "Toggle",
        Default = data.Default or false, Callback = data.Callback
    })
end

function Dropdown(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Dropdown", Tab = data.Tab, Text = data.Text or "Opção",
        Options = data.Options or {"Opção 1", "Opção 2"}, Callback = data.Callback
    })
end

function Selector(data)
    -- alias simples para dropdown por enquanto
    Dropdown(data)
end

-- ====================== PROCESS ======================
local function process()
    local hub = findHubBarContainer()
    if not hub then return false end

    for _, cfg in ipairs(PendingTabs) do
        local ok, err = pcall(createTabButton, hub, cfg)
        if not ok then warn("[SmartTab] Tab error:", err) end
    end
    clearList(PendingTabs)

    for _, el in ipairs(PendingElements) do
        local tabData = Tabs[el.Tab]
        if tabData and tabData.content then
            local ok, err = pcall(function()
                if el.Type == "Button" then addButton(tabData, el)
                elseif el.Type == "BlueButton" then addBlueButton(tabData, el)
                elseif el.Type == "Label" then addLabel(tabData, el)
                elseif el.Type == "Toggle" then addToggle(tabData, el)
                elseif el.Type == "Dropdown" then addDropdown(tabData, el)
                end
            end)
            if not ok then warn("[SmartTab] Element error:", err) end
        end
    end
    clearList(PendingElements)
    return true
end

-- tenta várias vezes
task.spawn(function()
    for i = 1, 15 do
        task.wait(1)
        if process() and next(Tabs) then
            break
        end
    end
end)

-- quando o menu abrir
CoreGui.DescendantAdded:Connect(function(desc)
    if desc.Name == "HubBarContainer" or desc.Name == "SettingsShield" then
        task.wait(0.7)
        -- limpa tabs mortas
        for name, data in pairs(Tabs) do
            if not data.button or not data.button.Parent then
                if data.gui then data.gui:Destroy() end
                Tabs[name] = nil
            end
        end
        process()
    end
end)
