--[[
    Smart Tab Library v18
    + Slider, Input
    + SetOption no Callback (Locked/Unlocked) com registro global
    + Dropdown com scroll e opção selecionada destacada
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local PendingTabs = {}
local PendingElements = {}
local Tabs = {}
local ActiveName = nil
local LastActiveName = nil
local HubScroll = nil
local PageViewInner = nil
-- registro de elementos para SetOption por nome (Text)
local ElementRegistry = {} -- [key] = { frame, stateRef, onLock, onUnlock }

local function clearList(t)
    for i = #t, 1, -1 do t[i] = nil end
end

local function findHubAndPage()
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
    local hub = header:FindFirstChild("HubBarContainer")
    if not hub then return nil end
    local clipper = page:FindFirstChild("PageViewClipper")
    local pageView = clipper and clipper:FindFirstChild("PageView")
    local inner = pageView and pageView:FindFirstChild("PageViewInnerFrame")
    return hub, page, inner, settings
end

local function deselectAllCustom()
    for _, t in pairs(Tabs) do
        if t.setActive then t.setActive(false) end
        if t.pageView then t.pageView.Visible = false end
    end
    ActiveName = nil
end

local function hideNativePages()
    if not PageViewInner then return end
    for _, child in ipairs(PageViewInner:GetChildren()) do
        if child:IsA("GuiObject") and not child:GetAttribute("SmartPage") then
            child.Visible = false
        end
    end
end

local function selectCustomTab(name)
    deselectAllCustom()
    hideNativePages()
    local t = Tabs[name]
    if not t then return end
    t.setActive(true)
    if t.pageView then t.pageView.Visible = true end
    ActiveName = name
    LastActiveName = name
end

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
    layout.Parent = scroll
    for _, child in ipairs(hub:GetChildren()) do
        if child:IsA("TextButton") and not child:GetAttribute("SmartTab") then
            child.Parent = scroll
        end
    end
    local old = hub:FindFirstChildOfClass("UIListLayout")
    if old then old:Destroy() end
    return scroll
end

local function hookNativeTabs(scroll)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") and not child:GetAttribute("SmartTab") and not child:GetAttribute("SmartHook") then
            child:SetAttribute("SmartHook", true)
            child.MouseButton1Click:Connect(function()
                deselectAllCustom()
                LastActiveName = nil
            end)
        end
    end
end

-- Overlay Locked
-- SetOption DENTRO do Callback via ctrl.SetOption("Locked"|"Unlocked")
local function applyLocked(frame)
    if not frame or frame:FindFirstChild("LockedOverlay") then return end
    local overlay = Instance.new("Frame")
    overlay.Name = "LockedOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.35
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 20
    overlay.Parent = frame
    Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 8)

    local txt = Instance.new("TextLabel")
    txt.BackgroundTransparency = 1
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.Text = "Locked"
    txt.TextColor3 = Color3.fromRGB(220, 220, 220)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
    txt.ZIndex = 21
    txt.Parent = overlay
end

local function removeLocked(frame)
    if not frame then return end
    local o = frame:FindFirstChild("LockedOverlay")
    if o then o:Destroy() end
end

local function registryKey(tab, text)
    return tostring(tab or "") .. "::" .. tostring(text or "")
end

local function registerElement(tab, text, frame, stateRef, extra)
    local key = registryKey(tab, text)
    ElementRegistry[key] = {
        frame = frame,
        stateRef = stateRef,
        onLock = extra and extra.onLock,
        onUnlock = extra and extra.onUnlock
    }
end

local function applyOptionToRef(entry, opt)
    if not entry or type(opt) ~= "string" then return end
    local lower = opt:lower()
    if lower == "locked" then
        entry.stateRef.locked = true
        applyLocked(entry.frame)
        if entry.onLock then pcall(entry.onLock) end
    elseif lower == "unlocked" then
        entry.stateRef.locked = false
        removeLocked(entry.frame)
        if entry.onUnlock then pcall(entry.onUnlock) end
    end
end

-- Global: SetOption("NomeDoElemento", "Locked"|"Unlocked")
-- ou SetOption("NomeDoElemento", "Locked", "NomeDaTab")
function SetOption(nameOrOpt, optOrNil, tabOrNil)
    -- Formas:
    -- SetOption("Locked")  -> não faz nada sozinho (precisa nome)
    -- SetOption("Continuar", "Unlocked")
    -- SetOption("Continuar", "Unlocked", "Painel")
    if type(nameOrOpt) == "string" and optOrNil == nil then
        return -- precisa do nome do elemento
    end
    local name, opt, tab = nameOrOpt, optOrNil, tabOrNil
    if type(opt) ~= "string" then return end

    if tab then
        local key = registryKey(tab, name)
        if ElementRegistry[key] then
            applyOptionToRef(ElementRegistry[key], opt)
        end
        return
    end

    -- procura por Text em qualquer tab
    local suffix = "::" .. tostring(name)
    for key, entry in pairs(ElementRegistry) do
        if key:sub(-#suffix) == suffix or key == tostring(name) then
            applyOptionToRef(entry, opt)
        end
    end
end

-- Cria o objeto ctrl passado para o Callback
local function makeCtrl(frame, stateRef, tab, text, extra)
    registerElement(tab, text, frame, stateRef, extra)
    return {
        SetOption = function(opt, targetName)
            -- ctrl.SetOption("Locked")  -> neste elemento
            -- ctrl.SetOption("Unlocked", "Continuar") -> em outro pelo nome
            if type(opt) ~= "string" then return end
            if type(targetName) == "string" then
                SetOption(targetName, opt, tab)
                return
            end
            local lower = opt:lower()
            if lower == "locked" then
                stateRef.locked = true
                applyLocked(frame)
                if extra and extra.onLock then pcall(extra.onLock) end
            elseif lower == "unlocked" then
                stateRef.locked = false
                removeLocked(frame)
                if extra and extra.onUnlock then pcall(extra.onUnlock) end
            end
        end,
        IsLocked = function()
            return stateRef.locked == true
        end
    }
end

local function createTab(hub, page, inner, config)
    if Tabs[config.Name] and Tabs[config.Name].button and Tabs[config.Name].button.Parent then
        return
    end
    local scroll = ensureScroll(hub)
    HubScroll = scroll
    PageViewInner = inner
    local tabName = "Smart_" .. config.Name:gsub("%s+", "")
    if scroll:FindFirstChild(tabName) then return end

    local pageView, content = nil, nil
    if inner then
        pageView = Instance.new("Frame")
        pageView.Name = tabName .. "_Page"
        pageView:SetAttribute("SmartPage", true)
        pageView.BackgroundTransparency = 1
        pageView.Size = UDim2.new(1, 0, 1, 0)
        pageView.Visible = false
        pageView.ZIndex = 5
        pageView.Parent = inner

        local sf = Instance.new("ScrollingFrame")
        sf.Name = "Content"
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.Size = UDim2.new(1, 0, 1, 0)
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.ScrollBarThickness = 4
        sf.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
        sf.ScrollingDirection = Enum.ScrollingDirection.Y
        sf.ElasticBehavior = Enum.ElasticBehavior.Never
        sf.Parent = pageView

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 6)
        list.Parent = sf

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 12)
        pad.PaddingBottom = UDim.new(0, 20)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = sf
        content = sf
    end

    local btn = Instance.new("TextButton")
    btn.Name = tabName
    btn:SetAttribute("SmartTab", true)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Size = UDim2.new(0, 105, 1, 0)
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

    btn.MouseButton1Click:Connect(function()
        selectCustomTab(config.Name)
    end)

    hookNativeTabs(scroll)

    Tabs[config.Name] = {
        button = btn,
        setActive = setActive,
        pageView = pageView,
        content = content,
        rows = {},
        name = config.Name
    }
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
    local stateRef = { locked = false }
    local ctrl = makeCtrl(frame, stateRef, data.Tab, data.Text)

    toggle.MouseButton1Click:Connect(function()
        if stateRef.locked then return end
        state = not state
        update()
        if data.Callback then task.spawn(data.Callback, state, ctrl) end
    end)
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

    local stateRef = { locked = false }
    local ctrl = makeCtrl(frame, stateRef, data.Tab, data.Text)

    btn.MouseButton1Click:Connect(function()
        if stateRef.locked then return end
        if data.Callback then task.spawn(data.Callback, ctrl) end
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

    local stateRef = { locked = false }
    local ctrl = makeCtrl(frame, stateRef, data.Tab, data.Text)

    btn.MouseButton1Click:Connect(function()
        if stateRef.locked then return end
        if data.Callback then task.spawn(data.Callback, ctrl) end
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

local function addDropdown(tabData, data)
    local options = data.Options or {"Opção 1", "Opção 2"}
    local isOpen = false
    local selectedIndex = 1
    local maxVisible = 5
    local optHeight = 32

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.ClipsDescendants = false
    frame.Parent = tabData.content

    local stateRef = { locked = false }
    local ctrl = makeCtrl(frame, stateRef, data.Tab, data.Text)

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

    -- Lista com scroll
    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.fromRGB(35, 36, 38)
    listFrame.Position = UDim2.new(0.45, 0, 0, 42)
    listFrame.Size = UDim2.new(0.55, 0, 0, 0)
    listFrame.ClipsDescendants = true
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.Parent = frame
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)

    local listScroll = Instance.new("ScrollingFrame")
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.Size = UDim2.new(1, 0, 1, 0)
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.ScrollBarThickness = 4
    listScroll.ScrollBarImageColor3 = Color3.fromRGB(160, 160, 160)
    listScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    listScroll.ZIndex = 11
    listScroll.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listScroll

    local optionButtons = {}

    local function refreshHighlight()
        for i, optBtn in ipairs(optionButtons) do
            if i == selectedIndex then
                optBtn.BackgroundTransparency = 0.7
                optBtn.BackgroundColor3 = Color3.fromRGB(51, 95, 255)
                optBtn.Text = "✓  " .. options[i]
            else
                optBtn.BackgroundTransparency = 1
                optBtn.Text = options[i]
            end
        end
    end

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, optHeight)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.new(1, 1, 1)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 13
        optBtn.ZIndex = 12
        optBtn.AutoButtonColor = false
        optBtn.Parent = listScroll
        optionButtons[i] = optBtn

        optBtn.MouseButton1Click:Connect(function()
            if stateRef.locked then return end
            selectedIndex = i
            cur.Text = opt
            refreshHighlight()
            isOpen = false
            listFrame.Visible = false
            listFrame.Size = UDim2.new(0.55, 0, 0, 0)
            frame.Size = UDim2.new(1, 0, 0, 44)
            arrow.Text = "▼"
            if data.Callback then task.spawn(data.Callback, opt, i, ctrl) end
        end)
    end
    refreshHighlight()

    drop.MouseButton1Click:Connect(function()
        if stateRef.locked then return end
        isOpen = not isOpen
        if isOpen then
            local visibleCount = math.min(#options, maxVisible)
            local h = visibleCount * optHeight
            listFrame.Visible = true
            listFrame.Size = UDim2.new(0.55, 0, 0, h)
            frame.Size = UDim2.new(1, 0, 0, 44 + h + 4)
            arrow.Text = "▲"
            refreshHighlight()
            -- scroll até a selecionada
            task.defer(function()
                local y = (selectedIndex - 1) * optHeight
                listScroll.CanvasPosition = Vector2.new(0, math.max(0, y - optHeight))
            end)
        else
            listFrame.Visible = false
            listFrame.Size = UDim2.new(0.55, 0, 0, 0)
            frame.Size = UDim2.new(1, 0, 0, 44)
            arrow.Text = "▼"
        end
    end)
end

local function addSlider(tabData, data)
    local min = data.Min or 0
    local max = data.Max or 100
    local value = data.Default or min
    value = math.clamp(value, min, max)

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.Parent = tabData.content

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.45, 0, 0, 20)
    label.Text = data.Text or "Slider"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, 0, 0, 0)
    valueLabel.Size = UDim2.new(0.3, 0, 0, 20)
    valueLabel.Text = tostring(math.floor(value))
    valueLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 13
    valueLabel.Parent = frame

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Position = UDim2.new(0, 0, 0, 28)
    track.Size = UDim2.new(1, 0, 0, 6)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(51, 95, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local stateRef = { locked = false }
    local ctrl = makeCtrl(frame, stateRef, data.Tab, data.Text)

    local function setValue(v)
        if stateRef.locked then return end
        v = math.clamp(v, min, max)
        value = v
        local pct = (v - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(v + 0.5))
        if data.Callback then task.spawn(data.Callback, v, ctrl) end
    end

    local function updateFromInput(input)
        local absPos = track.AbsolutePosition.X
        local absSize = track.AbsoluteSize.X
        local rel = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
        setValue(min + rel * (max - min))
    end

    track.InputBegan:Connect(function(input)
        if stateRef.locked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- INPUT (TextBox)
local function addInput(tabData, data)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.Parent = tabData.content

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Text = data.Text or "Input"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = frame

    local boxBg = Instance.new("Frame")
    boxBg.AnchorPoint = Vector2.new(1, 0.5)
    boxBg.Position = UDim2.new(1, 0, 0.5, 0)
    boxBg.Size = UDim2.new(0.55, 0, 0, 34)
    boxBg.BackgroundColor3 = Color3.fromRGB(45, 46, 48)
    boxBg.BorderSizePixel = 0
    boxBg.Parent = frame
    Instance.new("UICorner", boxBg).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.85
    stroke.Parent = boxBg

    local box = Instance.new("TextBox")
    box.BackgroundTransparency = 1
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.new(0, 8, 0, 0)
    box.Text = data.Default or ""
    box.PlaceholderText = data.Placeholder or "Digite aqui..."
    box.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = boxBg

    local stateRef = { locked = false }
    local ctrl = makeCtrl(frame, stateRef, data.Tab, data.Text, {
        onLock = function() box.TextEditable = false end,
        onUnlock = function() box.TextEditable = true end
    })

    box.FocusLost:Connect(function(enter)
        if stateRef.locked then return end
        if data.Callback then
            task.spawn(data.Callback, box.Text, enter, ctrl)
        end
    end)
end

-- ====================== API ======================
function Tab(data)
    if type(data) ~= "table" then return end
    table.insert(PendingTabs, {Name = data.Name or "Tab", Icon = data.Icon or "star"})
end

function Button(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Button", Tab = data.Tab, Text = data.Text or "Botão",
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        SetOption = data.SetOption, Callback = data.Callback, Default = data.Default
    })
end

function BlueButton(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "BlueButton", Tab = data.Tab, Text = data.Text or "Continuar",
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        SetOption = data.SetOption, Callback = data.Callback, Default = data.Default
    })
end

function Label(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Label", Tab = data.Tab, Text = data.Text or "Seção",
        Description = data.Description, SetOption = data.SetOption
    })
end

function Toggle(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Toggle", Tab = data.Tab, Text = data.Text or "Toggle",
        Default = data.Default or false, SetOption = data.SetOption, Callback = data.Callback
    })
end

function Dropdown(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Dropdown", Tab = data.Tab, Text = data.Text or "Opção",
        Options = data.Options or {"Opção 1", "Opção 2"},
        SetOption = data.SetOption, Callback = data.Callback
    })
end

function Selector(data)
    Dropdown(data)
end

function Slider(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Slider", Tab = data.Tab, Text = data.Text or "Slider",
        Min = data.Min or 0, Max = data.Max or 100, Default = data.Default,
        SetOption = data.SetOption, Callback = data.Callback
    })
end

function Input(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Input", Tab = data.Tab, Text = data.Text or "Input",
        Default = data.Default, Placeholder = data.Placeholder,
        SetOption = data.SetOption, Callback = data.Callback
    })
end

-- ====================== PROCESS ======================
local function process()
    local hub, page, inner = findHubAndPage()
    if not hub then return false end

    for _, cfg in ipairs(PendingTabs) do
        pcall(createTab, hub, page, inner, cfg)
    end
    clearList(PendingTabs)

    for _, el in ipairs(PendingElements) do
        local tabData = Tabs[el.Tab]
        if tabData and tabData.content then
            pcall(function()
                if el.Type == "Button" then addButton(tabData, el)
                elseif el.Type == "BlueButton" then addBlueButton(tabData, el)
                elseif el.Type == "Label" then addLabel(tabData, el)
                elseif el.Type == "Toggle" then addToggle(tabData, el)
                elseif el.Type == "Dropdown" then addDropdown(tabData, el)
                elseif el.Type == "Slider" then addSlider(tabData, el)
                elseif el.Type == "Input" then addInput(tabData, el)
                end
            end)
        end
    end
    clearList(PendingElements)

    if LastActiveName and Tabs[LastActiveName] then
        task.defer(function()
            task.wait(0.15)
            selectCustomTab(LastActiveName)
        end)
    end
    return true
end

task.spawn(function()
    local lastVisible = false
    while true do
        task.wait(0.35)
        local ok, visible = pcall(function()
            local robloxGui = CoreGui:FindFirstChild("RobloxGui")
            if not robloxGui then return false end
            local shield = robloxGui:FindFirstChild("SettingsClippingShield")
            if not shield then return false end
            local settings = shield:FindFirstChild("SettingsShield")
            if not settings then return false end
            return settings.Visible == true
        end)
        if ok and visible and not lastVisible then
            task.wait(0.4)
            process()
            if LastActiveName and Tabs[LastActiveName] then
                selectCustomTab(LastActiveName)
            end
        end
        lastVisible = visible or false
    end
end)

task.spawn(function()
    for i = 1, 12 do
        task.wait(1)
        if process() and next(Tabs) then break end
    end
end)

CoreGui.DescendantAdded:Connect(function(desc)
    if desc.Name == "HubBarContainer" or desc.Name == "PageViewInnerFrame" then
        task.wait(0.5)
        for name, data in pairs(Tabs) do
            if not data.button or not data.button.Parent then
                Tabs[name] = nil
            end
        end
        process()
    end
end)
