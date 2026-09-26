--[[
    Smart Tab Library v29
    Custom tabs in Roblox in-game Esc menu
    + SizeType, Side, Lucide Icons, Slider, Input
    + SetOption in Callback (Locked / Unlocked)
    + DeleteTab (custom tabs only)
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Lucide Icons (Footagesus Icons v2)
local IconsLib = nil
task.spawn(function()
    pcall(function()
        local src
        pcall(function()
            src = game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua")
        end)
        if not src then
            pcall(function()
                src = game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua")
            end)
        end
        if src and #src > 0 then
            local fn = loadstring(src)
            if fn then
                IconsLib = fn()
                if IconsLib and IconsLib.SetIconsType then
                    pcall(IconsLib.SetIconsType, "lucide")
                end
            end
        end
    end)
end)

local function resolveIcon(icon)
    if icon == nil or icon == "" then return nil, nil end
    local s = tostring(icon)
    if string.find(s, "rbxassetid://") then
        return "image", s
    end
    if tonumber(s) then
        return "image", "rbxassetid://" .. s
    end
    if IconsLib then
        local ok, result = pcall(function()
            if IconsLib.GetIcon then
                return IconsLib.GetIcon(s)
            end
            return nil
        end)
        if ok and result and result ~= "" then
            return "image", result
        end
    end
    return "text", s
end

local function createIconLabel(parent, icon, size, z)
    size = size or 16
    z = z or 5
    local kind, value = resolveIcon(icon)
    if not kind then return nil end
    if kind == "image" then
        local img = Instance.new("ImageLabel")
        img.Name = "Icon"
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(0, size, 0, size)
        img.Image = value
        img.ImageTransparency = 0
        img.ZIndex = z
        img.Parent = parent
        Instance.new("UIAspectRatioConstraint", img)
        return img
    else
        local txt = Instance.new("TextLabel")
        txt.Name = "Icon"
        txt.BackgroundTransparency = 1
        txt.Size = UDim2.new(0, size, 0, size)
        txt.Text = value
        txt.TextColor3 = Color3.new(1, 1, 1)
        txt.TextScaled = true
        txt.ZIndex = z
        txt.Parent = parent
        pcall(function()
            txt.FontFace = Font.new(
                "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json",
                Enum.FontWeight.Regular,
                Enum.FontStyle.Normal
            )
        end)
        return txt
    end
end

local PendingTabs = {}
local PendingElements = {}
local Tabs = {}
local ActiveName = nil
local LastActiveName = nil
local HubScroll = nil
local PageViewInner = nil
local ElementRegistry = {}

local function clearList(t)
    for i = #t, 1, -1 do t[i] = nil end
end

local function findHubAndPage()
    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if not robloxGui then return nil end

    local shield = robloxGui:FindFirstChild("SettingsClippingShield")
        or robloxGui:FindFirstChild("SettingsShield", true)

    local settings = nil
    if shield then
        if shield.Name == "SettingsShield" then
            settings = shield
        else
            settings = shield:FindFirstChild("SettingsShield") or shield:FindFirstChild("SettingsShield", true)
        end
    end
    if not settings then
        settings = robloxGui:FindFirstChild("SettingsShield", true)
    end
    if not settings then return nil end

    local menu = settings:FindFirstChild("MenuContainer") or settings:FindFirstChild("MenuContainer", true)
    if not menu then return nil end
    local page = menu:FindFirstChild("Page") or menu:FindFirstChild("Page", true)
    if not page then return nil end

    local hubBar = page:FindFirstChild("HubBar") or page:FindFirstChild("HubBar", true)
    if not hubBar then return nil end

    local hub = hubBar:FindFirstChild("HubBarContainer", true)
        or hubBar:FindFirstChild("TabHeaderContainer")
    if hub and hub.Name == "TabHeaderContainer" then
        hub = hub:FindFirstChild("HubBarContainer") or hub
    end
    if not hub then
        hub = hubBar:FindFirstChildWhichIsA("Frame") or hubBar
    end

    local clipper = page:FindFirstChild("PageViewClipper") or page:FindFirstChild("PageViewClipper", true)
    local pageView = clipper and (clipper:FindFirstChild("PageView") or clipper:FindFirstChild("PageView", true))
    local inner = pageView and (pageView:FindFirstChild("PageViewInnerFrame") or pageView:FindFirstChild("PageViewInnerFrame", true))
    if not inner and pageView then inner = pageView end

    return hub, page, inner, settings
end

local function deselectAllCustom()
    for _, t in pairs(Tabs) do
        if t.setActive then t.setActive(false) end
        if t.pageView then
            if t.pageView:IsA("ScreenGui") then
                t.pageView.Enabled = false
            else
                t.pageView.Visible = false
            end
        end
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
    if t.pageView then
        if t.pageView:IsA("ScreenGui") then
            t.pageView.Enabled = true
        else
            t.pageView.Visible = true
        end
    end
    ActiveName = name
    LastActiveName = name
end

-- Tabs nativas do Roblox usam Size em Scale → no ScrollingFrame ficam ENORMES/longe.
-- Força largura compacta em pixels.
local function compactTabButton(btn)
    if not btn or not btn:IsA("GuiObject") then return end
    if btn:GetAttribute("SmartCompact") then return end
    btn:SetAttribute("SmartCompact", true)

    -- Remove constraint de largura em scale
    pcall(function()
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
    end)

    -- Largura mínima baseada no texto
    local textLen = 0
    if btn:IsA("TextButton") and type(btn.Text) == "string" and btn.Text ~= "" then
        textLen = #btn.Text
    end
    for _, d in ipairs(btn:GetDescendants()) do
        if d:IsA("TextLabel") and type(d.Text) == "string" and #d.Text > textLen then
            textLen = #d.Text
        end
    end
    local minW = math.clamp(textLen * 8 + 36, 72, 140)
    pcall(function()
        btn.Size = UDim2.new(0, minW, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.None
    end)
end

local function updateTabScrollCanvas(scroll)
    if not scroll then return end
    local layout = scroll:FindFirstChildOfClass("UIListLayout")
    local w = 0
    if layout and layout.AbsoluteContentSize.X > 1 then
        w = layout.AbsoluteContentSize.X
    else
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                w = w + (child.AbsoluteSize.X > 0 and child.AbsoluteSize.X or child.Size.X.Offset)
            end
        end
        local pad = (layout and layout.Padding and layout.Padding.Offset) or 0
        local count = 0
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                count = count + 1
            end
        end
        if count > 1 then
            w = w + pad * (count - 1)
        end
    end
    scroll.CanvasSize = UDim2.new(0, math.max(w + 4, 0), 0, 0)
    scroll.ScrollingEnabled = w > (scroll.AbsoluteSize.X + 2)
end

local function ensureScroll(hub)
    local scroll = hub:FindFirstChild("SmartTabScroll")
    if scroll then
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") and not child:GetAttribute("SmartTab") then
                compactTabButton(child)
            end
        end
        task.defer(updateTabScrollCanvas, scroll)
        return scroll
    end

    scroll = Instance.new("ScrollingFrame")
    scroll.Name = "SmartTabScroll"
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(160, 160, 160)
    scroll.ScrollingDirection = Enum.ScrollingDirection.X
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.ClipsDescendants = true
    scroll.ScrollingEnabled = false
    scroll.ZIndex = 4
    scroll.Parent = hub

    local layout = Instance.new("UIListLayout")
    layout.Name = "SmartTabLayout"
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2) -- tabs juntas, sem gap grande
    layout.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        updateTabScrollCanvas(scroll)
    end)
    scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateTabScrollCanvas(scroll)
    end)

    -- Move tabs nativas e compacta largura (evita Scale esticar)
    local order = 0
    for _, child in ipairs(hub:GetChildren()) do
        if child:IsA("TextButton") and not child:GetAttribute("SmartTab") then
            order = order + 1
            child.LayoutOrder = order
            compactTabButton(child)
            child.Parent = scroll
        end
    end

    local old = hub:FindFirstChildOfClass("UIListLayout")
    if old then old:Destroy() end
    -- Remove UIListLayout/UIGrid residual no hub que espaça filhos
    for _, c in ipairs(hub:GetChildren()) do
        if c:IsA("UIListLayout") or c:IsA("UIGridLayout") or c:IsA("UIPageLayout") then
            c:Destroy()
        end
    end

    task.defer(function()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") and not child:GetAttribute("SmartTab") then
                compactTabButton(child)
            end
        end
        updateTabScrollCanvas(scroll)
    end)
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

function SetOption(nameOrOpt, optOrNil, tabOrNil)
    if type(nameOrOpt) == "string" and optOrNil == nil then
        return
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

    local suffix = "::" .. tostring(name)
    for key, entry in pairs(ElementRegistry) do
        if key:sub(-#suffix) == suffix or key == tostring(name) then
            applyOptionToRef(entry, opt)
        end
    end
end

local function makeCtrl(frame, stateRef, tab, text, extra)
    registerElement(tab, text, frame, stateRef, extra)
    return {
        SetOption = function(opt, targetName)
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
    if not config or not config.Name then return end
    if Tabs[config.Name] and Tabs[config.Name].button and Tabs[config.Name].button.Parent and Tabs[config.Name].content then
        return
    end
    local scroll = ensureScroll(hub)
    if not scroll then return end
    HubScroll = scroll
    PageViewInner = inner
    local tabName = "Smart_" .. tostring(config.Name):gsub("%s+", "")

    local existingBtn = scroll:FindFirstChild(tabName)
    if existingBtn and Tabs[config.Name] and Tabs[config.Name].content then
        Tabs[config.Name].button = existingBtn
        return
    end
    if existingBtn then
        existingBtn:Destroy()
    end

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
        list.Padding = UDim.new(0, 9)
        list.Parent = sf

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 16)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = sf
        content = sf
    else
        local gui = Instance.new("ScreenGui")
        gui.Name = "SmartFallback_" .. tabName
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 99
        gui.Enabled = false
        gui.Parent = CoreGui
        pageView = gui

        local panel = Instance.new("Frame")
        panel.AnchorPoint = Vector2.new(0.5, 1)
        panel.Position = UDim2.new(0.5, 0, 1, -24)
        panel.Size = UDim2.new(0, 480, 0, 400)
        panel.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
        panel.BackgroundTransparency = 0.1
        panel.BorderSizePixel = 0
        panel.Parent = gui
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

        local sf = Instance.new("ScrollingFrame")
        sf.Name = "Content"
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel = 0
        sf.Size = UDim2.new(1, 0, 1, 0)
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.ScrollBarThickness = 4
        sf.Parent = panel
        local fl = Instance.new("UIListLayout")
        fl.SortOrder = Enum.SortOrder.LayoutOrder
        fl.Padding = UDim.new(0, 9)
        fl.Parent = sf
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 16)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = sf
        content = sf
    end

    local customCount = 0
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") and c:GetAttribute("SmartTab") then
            customCount = customCount + 1
        end
    end

    local btn = Instance.new("TextButton")
    btn.Name = tabName
    btn:SetAttribute("SmartTab", true)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.None
    btn.LayoutOrder = 100 + customCount
    btn.ZIndex = 5
    btn.Parent = scroll
    task.defer(updateTabScrollCanvas, scroll)

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

    local icon = createIconLabel(label, config.Icon or "star", 16, 5)
    if icon then
        if icon:IsA("ImageLabel") then
            icon.ImageTransparency = 0.5
        else
            icon.TextTransparency = 0.5
        end
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
        if icon then
            if icon:IsA("ImageLabel") then
                icon.ImageTransparency = on and 0 or 0.5
            else
                icon.TextTransparency = on and 0 or 0.5
            end
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
    pos = pos or "None"
    if pos ~= "Left" and pos ~= "Right" then
        return tabData.content, false
    end
    local last = tabData.rows[#tabData.rows]
    if last and last.count < 2 then
        last.count = last.count + 1
        return last.frame, true
    end
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 40)
    row.Parent = tabData.content
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = row
    local info = {frame = row, count = 1}
    table.insert(tabData.rows, info)
    return row, true
end

local function resolveSize(sizeType, side, inRow)
    sizeType = (sizeType or "Full")
    side = side or "None"
    if inRow or side == "Left" or side == "Right" then
        return UDim2.new(0.5, -4, 0, 40), (side == "Right") and 2 or 1
    end
    if tostring(sizeType):lower() == "default" then
        return UDim2.new(0, 160, 0, 40), 0
    end
    return UDim2.new(1, 0, 0, 40), 0
end

local function addToggle(tabData, data)
    local side = data.Side or data.ButtonPosition or data.Position or "None"
    local sizeType = data.SizeType or "Full"
    local parent, inRow = getRow(tabData, side)
    local size, order = resolveSize(sizeType, side, inRow)
    size = UDim2.new(size.X.Scale, size.X.Offset, 0, 44)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = size
    frame.LayoutOrder = order
    frame.Parent = parent

    local labelRow = Instance.new("Frame")
    labelRow.BackgroundTransparency = 1
    labelRow.Size = UDim2.new(0.65, 0, 1, 0)
    labelRow.Parent = frame
    local lLay = Instance.new("UIListLayout")
    lLay.FillDirection = Enum.FillDirection.Horizontal
    lLay.VerticalAlignment = Enum.VerticalAlignment.Center
    lLay.Padding = UDim.new(0, 6)
    lLay.Parent = labelRow
    if data.Icon then
        createIconLabel(labelRow, data.Icon, 16, 5)
    end
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.Text = data.Text or "Toggle"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = labelRow

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
    local side = data.Side or data.ButtonPosition or data.Position or "None"
    local sizeType = data.SizeType or "Full"
    local parent, inRow = getRow(tabData, side)
    local size, order = resolveSize(sizeType, side, inRow)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = size
    frame.LayoutOrder = order
    frame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0.5, -18)
    btn.BackgroundColor3 = Color3.fromRGB(208, 217, 251)
    btn.BackgroundTransparency = 0.85
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 1, 0)
    row.Parent = btn
    local rowLay = Instance.new("UIListLayout")
    rowLay.FillDirection = Enum.FillDirection.Horizontal
    rowLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rowLay.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLay.Padding = UDim.new(0, 6)
    rowLay.Parent = row
    if data.Icon then
        createIconLabel(row, data.Icon, 16, 5)
    end
    local btnText = Instance.new("TextLabel")
    btnText.BackgroundTransparency = 1
    btnText.AutomaticSize = Enum.AutomaticSize.XY
    btnText.Text = data.Text or "Botão"
    btnText.TextColor3 = Color3.fromRGB(247, 247, 248)
    btnText.Font = Enum.Font.GothamMedium
    btnText.TextSize = 14
    btnText.Parent = row

    local stateRef = { locked = false }
    local ctrl = makeCtrl(frame, stateRef, data.Tab, data.Text)

    btn.MouseButton1Click:Connect(function()
        if stateRef.locked then return end
        if data.Callback then task.spawn(data.Callback, ctrl) end
    end)
end

local function addBlueButton(tabData, data)
    local side = data.Side or data.ButtonPosition or data.Position or "None"
    local sizeType = data.SizeType or "Full"
    local parent, inRow = getRow(tabData, side)
    local size, order = resolveSize(sizeType, side, inRow)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = size
    frame.LayoutOrder = order
    frame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0.5, -18)
    btn.BackgroundColor3 = Color3.fromRGB(51, 95, 255)
    btn.BackgroundTransparency = 0.5
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 1, 0)
    row.Parent = btn
    local rowLay = Instance.new("UIListLayout")
    rowLay.FillDirection = Enum.FillDirection.Horizontal
    rowLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rowLay.VerticalAlignment = Enum.VerticalAlignment.Center
    rowLay.Padding = UDim.new(0, 6)
    rowLay.Parent = row
    if data.Icon then
        createIconLabel(row, data.Icon, 16, 5)
    end
    local btnText = Instance.new("TextLabel")
    btnText.BackgroundTransparency = 1
    btnText.AutomaticSize = Enum.AutomaticSize.XY
    btnText.Text = data.Text or "Continuar"
    btnText.TextColor3 = Color3.fromRGB(235, 241, 255)
    btnText.Font = Enum.Font.GothamMedium
    btnText.TextSize = 14
    btnText.Parent = row

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

    local titleRow = Instance.new("Frame")
    titleRow.BackgroundTransparency = 1
    titleRow.Size = UDim2.new(1, 0, 0, 22)
    titleRow.Parent = frame
    local tLay = Instance.new("UIListLayout")
    tLay.FillDirection = Enum.FillDirection.Horizontal
    tLay.VerticalAlignment = Enum.VerticalAlignment.Center
    tLay.Padding = UDim.new(0, 6)
    tLay.Parent = titleRow
    if data.Icon then
        createIconLabel(titleRow, data.Icon, 16, 5)
    end
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.AutomaticSize = Enum.AutomaticSize.XY
    title.Text = data.Text or "Seção"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.Parent = titleRow

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

    local labelRow = Instance.new("Frame")
    labelRow.BackgroundTransparency = 1
    labelRow.Size = UDim2.new(0.4, 0, 1, 0)
    labelRow.Parent = frame
    local lLay = Instance.new("UIListLayout")
    lLay.FillDirection = Enum.FillDirection.Horizontal
    lLay.VerticalAlignment = Enum.VerticalAlignment.Center
    lLay.Padding = UDim.new(0, 6)
    lLay.Parent = labelRow
    if data.Icon then
        createIconLabel(labelRow, data.Icon, 16, 5)
    end
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.Text = data.Text or "Opção"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = labelRow

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

    local labelRow = Instance.new("Frame")
    labelRow.BackgroundTransparency = 1
    labelRow.Size = UDim2.new(0.45, 0, 0, 20)
    labelRow.Parent = frame
    local lLay = Instance.new("UIListLayout")
    lLay.FillDirection = Enum.FillDirection.Horizontal
    lLay.VerticalAlignment = Enum.VerticalAlignment.Center
    lLay.Padding = UDim.new(0, 6)
    lLay.Parent = labelRow
    if data.Icon then
        createIconLabel(labelRow, data.Icon, 14, 5)
    end
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.Text = data.Text or "Slider"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = labelRow

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
    fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(51, 95, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((value - min) / math.max(max - min, 1), 0, 0.5, 0)
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
        local pct = (v - min) / math.max(max - min, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLabel.Text = tostring(math.floor(v + 0.5))
        if data.Callback then task.spawn(data.Callback, v, ctrl) end
    end

    local function updateFromInput(input)
        local absPos = track.AbsolutePosition.X
        local absSize = track.AbsoluteSize.X
        if absSize <= 0 then return end
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

local function addInput(tabData, data)
    local side = data.Side or data.ButtonPosition or data.Position or "None"
    local sizeType = data.SizeType or "Full"
    local parent, inRow = getRow(tabData, side)
    local size, order = resolveSize(sizeType, side, inRow)
    size = UDim2.new(size.X.Scale, size.X.Offset, 0, 50)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = size
    frame.LayoutOrder = order
    frame.Parent = parent

    local labelRow = Instance.new("Frame")
    labelRow.BackgroundTransparency = 1
    labelRow.Size = UDim2.new(0.4, 0, 1, 0)
    labelRow.Parent = frame
    local lLay = Instance.new("UIListLayout")
    lLay.FillDirection = Enum.FillDirection.Horizontal
    lLay.VerticalAlignment = Enum.VerticalAlignment.Center
    lLay.Padding = UDim.new(0, 6)
    lLay.Parent = labelRow
    if data.Icon then
        createIconLabel(labelRow, data.Icon, 16, 5)
    end
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.Text = data.Text or "Input"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.Parent = labelRow

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
        Type = "Button", Tab = data.Tab, Text = data.Text or "Botão", Icon = data.Icon,
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        Side = data.Side, SizeType = data.SizeType or "Full",
        Callback = data.Callback, Default = data.Default
    })
end

function BlueButton(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "BlueButton", Tab = data.Tab, Text = data.Text or "Continuar", Icon = data.Icon,
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        Side = data.Side, SizeType = data.SizeType or "Full",
        Callback = data.Callback, Default = data.Default
    })
end

function Label(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Label", Tab = data.Tab, Text = data.Text or "Seção", Icon = data.Icon,
        Description = data.Description
    })
end

function Toggle(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Toggle", Tab = data.Tab, Text = data.Text or "Toggle", Icon = data.Icon,
        Side = data.Side, SizeType = data.SizeType or "Full",
        Default = data.Default or false, Callback = data.Callback
    })
end

function Dropdown(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Dropdown", Tab = data.Tab, Text = data.Text or "Opção", Icon = data.Icon,
        Options = data.Options or {"Opção 1", "Opção 2"},
        Callback = data.Callback
    })
end

function Selector(data)
    Dropdown(data)
end

function Slider(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Slider", Tab = data.Tab, Text = data.Text or "Slider", Icon = data.Icon,
        Min = data.Min or 0, Max = data.Max or 100, Default = data.Default,
        Callback = data.Callback
    })
end

function Input(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Input", Tab = data.Tab, Text = data.Text or "Input", Icon = data.Icon,
        Side = data.Side, SizeType = data.SizeType or "Full",
        Default = data.Default, Placeholder = data.Placeholder,
        Callback = data.Callback
    })
end

function Textbox(data)
    Input(data)
end

function DeleteTab(data)
    local name
    if type(data) == "string" then
        name = data
    elseif type(data) == "table" then
        name = data.Name or data.Tab or data[1]
    else
        return
    end
    if not name then return end

    local t = Tabs[name]
    if t then
        pcall(function()
            if t.pageView then t.pageView:Destroy() end
            if t.button then t.button:Destroy() end
        end)
        Tabs[name] = nil
        if ActiveName == name then ActiveName = nil end
        if LastActiveName == name then LastActiveName = nil end
    end

    local leftTabs = {}
    for _, cfg in ipairs(PendingTabs) do
        if cfg.Name ~= name then table.insert(leftTabs, cfg) end
    end
    PendingTabs = leftTabs

    local leftEls = {}
    for _, el in ipairs(PendingElements) do
        if el.Tab ~= name then table.insert(leftEls, el) end
    end
    PendingElements = leftEls
end

function RemoveTab(data)
    DeleteTab(data)
end

-- ====================== PROCESS ======================
local function process()
    local hub, page, inner = findHubAndPage()
    if not hub then return false end

    local leftTabs = {}
    for _, cfg in ipairs(PendingTabs) do
        pcall(createTab, hub, page, inner, cfg)
        if not (Tabs[cfg.Name] and Tabs[cfg.Name].content) then
            table.insert(leftTabs, cfg)
        end
    end
    PendingTabs = leftTabs

    local leftEls = {}
    for _, el in ipairs(PendingElements) do
        if el._done then
            -- skip
        else
            local tabData = el.Tab and Tabs[el.Tab]
            if tabData and tabData.content then
                local ok = pcall(function()
                    if el.Type == "Button" then addButton(tabData, el)
                    elseif el.Type == "BlueButton" then addBlueButton(tabData, el)
                    elseif el.Type == "Label" then addLabel(tabData, el)
                    elseif el.Type == "Toggle" then addToggle(tabData, el)
                    elseif el.Type == "Dropdown" then addDropdown(tabData, el)
                    elseif el.Type == "Slider" then addSlider(tabData, el)
                    elseif el.Type == "Input" then addInput(tabData, el)
                    end
                end)
                if ok then
                    el._done = true
                else
                    table.insert(leftEls, el)
                end
            else
                table.insert(leftEls, el)
            end
        end
    end
    PendingElements = leftEls

    if LastActiveName and Tabs[LastActiveName] then
        task.defer(function()
            task.wait(0.15)
            pcall(selectCustomTab, LastActiveName)
        end)
    end
    return true
end

task.spawn(function()
    local lastVisible = false
    while true do
        task.wait(0.4)
        local visible = false
        pcall(function()
            local _, _, _, settings = findHubAndPage()
            if settings and settings.Visible then
                visible = true
            end
        end)
        if visible and not lastVisible then
            task.wait(0.35)
            pcall(process)
            if LastActiveName and Tabs[LastActiveName] then
                pcall(selectCustomTab, LastActiveName)
            end
        elseif visible then
            if #PendingTabs > 0 or #PendingElements > 0 then
                pcall(process)
            end
        end
        lastVisible = visible
    end
end)

task.spawn(function()
    for i = 1, 20 do
        task.wait(0.75)
        pcall(process)
        if next(Tabs) and #PendingElements == 0 and #PendingTabs == 0 then
            break
        end
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
        pcall(process)
    end
end)
