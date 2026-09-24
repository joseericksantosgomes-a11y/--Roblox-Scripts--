--[[
    Smart Tab Library v9
    - Menu open/close estável
    - Tabs limpas (não vazam nome)
    - Conteúdo isolado por tab
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PendingTabs = {}
local PendingElements = {}
local CreatedTabs = {} -- [name] = data
local ActiveCustomTab = nil
local IsProcessed = false

local function waitForHubBar()
    local robloxGui = CoreGui:WaitForChild("RobloxGui", 15)
    if not robloxGui then return nil end
    local settingsShield = robloxGui:FindFirstChild("SettingsClippingShield") or robloxGui:WaitForChild("SettingsClippingShield", 8)
    if not settingsShield then return nil end
    local settingsShield2 = settingsShield:FindFirstChild("SettingsShield") or settingsShield:WaitForChild("SettingsShield", 5)
    if not settingsShield2 then return nil end
    local menuContainer = settingsShield2:FindFirstChild("MenuContainer") or settingsShield2:WaitForChild("MenuContainer", 5)
    if not menuContainer then return nil end
    local page = menuContainer:FindFirstChild("Page") or menuContainer:WaitForChild("Page", 5)
    if not page then return nil end
    local hubBar = page:FindFirstChild("HubBar") or page:WaitForChild("HubBar", 5)
    if not hubBar then return nil end
    local tabHeader = hubBar:FindFirstChild("TabHeaderContainer") or hubBar:WaitForChild("TabHeaderContainer", 5)
    if not tabHeader then return nil end
    return tabHeader:FindFirstChild("HubBarContainer") or tabHeader:WaitForChild("HubBarContainer", 5), page, hubBar
end

local function getPageViewInnerFrame(page)
    local clipper = page:FindFirstChild("PageViewClipper")
    if not clipper then return nil end
    local pageView = clipper:FindFirstChild("PageView")
    if not pageView then return nil end
    return pageView:FindFirstChild("PageViewInnerFrame")
end

local function clearCustomSelections(scroll)
    for _, tab in ipairs(scroll:GetChildren()) do
        if tab:IsA("TextButton") and tab:GetAttribute("SmartTab") then
            local sel = tab:FindFirstChild("TabSelection")
            if sel then sel.Visible = false end
            local label = tab:FindFirstChild("TabLabel")
            if label then
                local icon = label:FindFirstChild("Icon")
                local title = label:FindFirstChild("Title")
                if icon then
                    if icon:IsA("TextLabel") then icon.TextTransparency = 0.5 else icon.ImageTransparency = 0.5 end
                end
                if title then title.TextTransparency = 0.5 end
            end
        end
    end
end

local function hideAllCustomPages()
    for _, data in pairs(CreatedTabs) do
        if data.pageView then
            data.pageView.Visible = false
        end
    end
    ActiveCustomTab = nil
end

local function createTab(hubBarContainer, page, config)
    if not hubBarContainer or not config then return end
    if CreatedTabs[config.Name] and CreatedTabs[config.Name].tabButton and CreatedTabs[config.Name].tabButton.Parent then
        return -- já existe
    end

    local scroll = hubBarContainer:FindFirstChild("SmartTabScroll")
    if not scroll then
        local originalList = hubBarContainer:FindFirstChildOfClass("UIListLayout")

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
        scroll.ZIndex = 4
        scroll.ClipsDescendants = true
        scroll.Parent = hubBarContainer

        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Horizontal
        list.HorizontalAlignment = Enum.HorizontalAlignment.Left
        list.VerticalAlignment = Enum.VerticalAlignment.Center
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 0)
        list.Parent = scroll

        for _, child in ipairs(hubBarContainer:GetChildren()) do
            if child:IsA("TextButton") and (child.Name:find("Tab") or child.Name:find("tab")) and not child:GetAttribute("SmartTab") then
                child.Parent = scroll
            end
        end
        if originalList then originalList:Destroy() end
    end

    local tabName = "SmartTab_" .. (config.Name or "Custom"):gsub("%s+", "")
    if scroll:FindFirstChild(tabName) then return end

    -- PAGEVIEW ISOLADO
    local pageViewInner = getPageViewInnerFrame(page)
    local myPageView, contentParent

    if pageViewInner then
        myPageView = Instance.new("Frame")
        myPageView.Name = tabName .. "_Page"
        myPageView.BackgroundTransparency = 1
        myPageView.Size = UDim2.new(1, 0, 1, 0)
        myPageView.Visible = false
        myPageView.ZIndex = 10
        myPageView.Parent = pageViewInner

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "PageScroll"
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.Size = UDim2.new(1, 0, 1, 0)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
        scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        scrollFrame.ElasticBehavior = Enum.ElasticBehavior.Never
        scrollFrame.Parent = myPageView

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 6)
        list.Parent = scrollFrame

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 12)
        pad.PaddingBottom = UDim.new(0, 20)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = scrollFrame

        contentParent = scrollFrame
    end

    -- BOTÃO DA TAB (tamanho mais compacto)
    local myTab = Instance.new("TextButton")
    myTab.Name = tabName
    myTab:SetAttribute("SmartTab", true)
    myTab.BackgroundTransparency = 1
    myTab.Selectable = false
    myTab.ZIndex = 5
    myTab.Text = ""
    myTab.Size = UDim2.new(0, 110, 1, 0)
    myTab.LayoutOrder = 999
    myTab.Parent = scroll

    local tabSelection = Instance.new("ImageLabel")
    tabSelection.Name = "TabSelection"
    tabSelection.Visible = false
    tabSelection.Position = UDim2.new(0, 6, 1, -2)
    tabSelection.Size = UDim2.new(1, -12, 0, 2)
    tabSelection.ZIndex = 5
    tabSelection.BorderSizePixel = 0
    tabSelection.BackgroundColor3 = Color3.new(1, 1, 1)
    tabSelection.Parent = myTab

    local tabLabel = Instance.new("Frame")
    tabLabel.Name = "TabLabel"
    tabLabel.BackgroundTransparency = 1
    tabLabel.ZIndex = 5
    tabLabel.Size = UDim2.new(1, 0, 1, 0)
    tabLabel.Parent = myTab

    local labelLayout = Instance.new("UIListLayout")
    labelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    labelLayout.FillDirection = Enum.FillDirection.Horizontal
    labelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    labelLayout.Padding = UDim.new(0, 5)
    labelLayout.Parent = tabLabel

    local icon
    local isAssetId = typeof(config.Icon) == "string" and (string.find(config.Icon, "rbxassetid://") or tonumber(config.Icon))
    if isAssetId then
        icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.ZIndex = 5
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Image = (string.find(config.Icon, "rbxassetid://") and config.Icon) or ("rbxassetid://" .. config.Icon)
        icon.ImageTransparency = 0.5
        icon.Parent = tabLabel
    else
        icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.ZIndex = 5
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.TextScaled = true
        icon.TextColor3 = Color3.new(1, 1, 1)
        icon.TextTransparency = 0.5
        icon.FontFace = Font.new("rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        icon.Text = config.Icon or "star"
        icon.Parent = tabLabel
    end
    Instance.new("UIAspectRatioConstraint", icon)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextTransparency = 0.5
    title.Text = config.Name or "Tab"
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5
    title.AutomaticSize = Enum.AutomaticSize.XY
    title.TextSize = 12
    title.Parent = tabLabel
    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MaxTextSize = 12
    constraint.Parent = title

    local function setActive(active)
        tabSelection.Visible = active
        if icon:IsA("TextLabel") then
            icon.TextTransparency = active and 0 or 0.5
        else
            icon.ImageTransparency = active and 0 or 0.5
        end
        title.TextTransparency = active and 0 or 0.5
    end

    myTab.MouseButton1Click:Connect(function()
        clearCustomSelections(scroll)
        setActive(true)
        ActiveCustomTab = config.Name

        -- Esconde todas as páginas nativas + custom e mostra só a nossa
        if pageViewInner then
            for _, child in ipairs(pageViewInner:GetChildren()) do
                if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                    child.Visible = false
                end
            end
            if myPageView then
                myPageView.Visible = true
            end
        end
    end)

    -- Quando clicar em tab nativa → esconde páginas custom
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") and not child:GetAttribute("SmartTab") then
            if not child:GetAttribute("SmartHooked") then
                child:SetAttribute("SmartHooked", true)
                child.MouseButton1Click:Connect(function()
                    clearCustomSelections(scroll)
                    hideAllCustomPages()
                end)
            end
        end
    end

    myTab.MouseEnter:Connect(function()
        if ActiveCustomTab ~= config.Name then
            if icon:IsA("TextLabel") then icon.TextTransparency = 0.25 else icon.ImageTransparency = 0.25 end
            title.TextTransparency = 0.25
        end
    end)
    myTab.MouseLeave:Connect(function()
        if ActiveCustomTab ~= config.Name then
            if icon:IsA("TextLabel") then icon.TextTransparency = 0.5 else icon.ImageTransparency = 0.5 end
            title.TextTransparency = 0.5
        end
    end)

    CreatedTabs[config.Name] = {
        tabButton = myTab,
        pageView = myPageView,
        contentParent = contentParent,
        name = config.Name
    }
end

-- ====================== HELPERS ======================
local function applyPosition(frame, position)
    position = position or "None"
    if position == "Left" then
        frame.Size = UDim2.new(0.5, -4, frame.Size.Y.Scale, frame.Size.Y.Offset)
    elseif position == "Right" then
        frame.Size = UDim2.new(0.5, -4, frame.Size.Y.Scale, frame.Size.Y.Offset)
    end
end

-- ====================== COMPONENTES ======================
local function createButton(parent, data)
    local pos = data.ButtonPosition or data.Position or "None"
    local frame = Instance.new("Frame")
    frame.Name = "ButtonFrame"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.Parent = parent
    applyPosition(frame, pos)

    local btn = Instance.new("ImageButton")
    btn.AutoButtonColor = false
    btn.BackgroundTransparency = 0.88
    btn.BackgroundColor3 = Color3.fromRGB(208, 217, 251)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0.5, -18)
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = data.Text or "Botão"
    text.TextColor3 = Color3.fromRGB(247, 247, 248)
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 14
    text.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if data.Callback then task.spawn(data.Callback) end
    end)
    return frame
end

local function createBlueButton(parent, data)
    local pos = data.ButtonPosition or data.Position or "None"
    local frame = Instance.new("Frame")
    frame.Name = "BlueButtonFrame"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.Parent = parent
    applyPosition(frame, pos)

    local btn = Instance.new("ImageButton")
    btn.AutoButtonColor = false
    btn.BackgroundTransparency = 0.6
    btn.BackgroundColor3 = Color3.fromRGB(51, 95, 255)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0.5, -18)
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = data.Text or "Continuar"
    text.TextColor3 = Color3.fromRGB(235, 241, 255)
    text.Font = Enum.Font.GothamMedium
    text.TextSize = 14
    text.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if data.Callback then task.spawn(data.Callback) end
    end)
    return frame
end

local function createLabel(parent, data)
    local pos = data.Position or "None"
    local frame = Instance.new("Frame")
    frame.Name = "LabelFrame"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, data.Description and 48 or 28)
    frame.Parent = parent
    applyPosition(frame, pos)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 4, 0, 0)
    title.Size = UDim2.new(1, -8, 0, 22)
    title.Text = data.Text or "Seção"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.Parent = frame

    if data.Description then
        local desc = Instance.new("TextLabel")
        desc.BackgroundTransparency = 1
        desc.Position = UDim2.new(0, 4, 0, 22)
        desc.Size = UDim2.new(1, -8, 0, 20)
        desc.Text = data.Description
        desc.TextColor3 = Color3.fromRGB(160, 160, 170)
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextWrapped = true
        desc.Parent = frame
    end
    return frame
end

local function createDropdown(parent, data)
    local options = data.Options or {"Opção 1", "Opção 2"}
    local isOpen = false

    local frame = Instance.new("Frame")
    frame.Name = (data.Text or "Dropdown") .. "Frame"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.ClipsDescendants = false
    frame.Parent = parent

    local mainBtn = Instance.new("ImageButton")
    mainBtn.BackgroundTransparency = 1
    mainBtn.Size = UDim2.new(1, 0, 0, 50)
    mainBtn.AutoButtonColor = false
    mainBtn.Parent = frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.4, -20, 1, 0)
    label.Text = data.Text or "Opção"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    label.TextSize = 12
    label.Parent = mainBtn

    local dropBtn = Instance.new("ImageButton")
    dropBtn.AnchorPoint = Vector2.new(1, 0.5)
    dropBtn.Position = UDim2.new(1, 0, 0.5, 0)
    dropBtn.Size = UDim2.new(0.6, 0, 0, 40)
    dropBtn.BackgroundColor3 = Color3.fromRGB(56, 57, 59)
    dropBtn.AutoButtonColor = false
    dropBtn.Parent = mainBtn
    Instance.new("UICorner", dropBtn)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = 0.8
    stroke.Parent = dropBtn

    local currentText = Instance.new("TextLabel")
    currentText.BackgroundTransparency = 1
    currentText.Position = UDim2.new(0, 15, 0, 0)
    currentText.Size = UDim2.new(1, -50, 1, 0)
    currentText.Text = options[1]
    currentText.TextColor3 = Color3.new(1, 1, 1)
    currentText.TextTransparency = 0.3
    currentText.TextXAlignment = Enum.TextXAlignment.Left
    currentText.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    currentText.TextSize = 14
    currentText.ClipsDescendants = true
    currentText.Parent = dropBtn

    local arrow = Instance.new("ImageLabel")
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -12, 0.5, 0)
    arrow.Size = UDim2.new(0, 15, 0, 10)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxasset://textures/ui/Settings/DropDown/DropDown.png"
    arrow.Parent = dropBtn

    local listFrame = Instance.new("Frame")
    listFrame.BackgroundColor3 = Color3.fromRGB(40, 41, 43)
    listFrame.BorderSizePixel = 0
    listFrame.Position = UDim2.new(0.4, 0, 0, 48)
    listFrame.Size = UDim2.new(0.6, 0, 0, 0)
    listFrame.ClipsDescendants = true
    listFrame.ZIndex = 20
    listFrame.Visible = false
    listFrame.Parent = frame
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)
    local listStroke = Instance.new("UIStroke")
    listStroke.Color = Color3.new(1, 1, 1)
    listStroke.Transparency = 0.85
    listStroke.Parent = listFrame
    Instance.new("UIListLayout", listFrame).SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.BackgroundTransparency = 1
        optBtn.Size = UDim2.new(1, 0, 0, 36)
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.new(1, 1, 1)
        optBtn.TextSize = 14
        optBtn.Font = Enum.Font.Gotham
        optBtn.ZIndex = 21
        optBtn.Parent = listFrame
        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0.9
            optBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 1
        end)
        optBtn.MouseButton1Click:Connect(function()
            currentText.Text = opt
            closeList()
            if data.Callback then task.spawn(data.Callback, opt, i) end
        end)
    end

    local function openList()
        isOpen = true
        listFrame.Visible = true
        local h = #options * 36
        TweenService:Create(listFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.6, 0, 0, h)}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.2), {Rotation = 180}):Play()
        frame.Size = UDim2.new(1, 0, 0, 50 + h + 4)
    end
    local function closeList()
        isOpen = false
        TweenService:Create(listFrame, TweenInfo.new(0.15), {Size = UDim2.new(0.6, 0, 0, 0)}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
        task.delay(0.16, function()
            if not isOpen then
                listFrame.Visible = false
                frame.Size = UDim2.new(1, 0, 0, 50)
            end
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        if isOpen then closeList() else openList() end
    end)
    return frame
end

local function createToggle(parent, data)
    local frame = Instance.new("ImageButton")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.AutoButtonColor = false
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.6, -20, 1, 0)
    label.Text = data.Text or "Toggle"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    label.TextSize = 12
    label.Parent = frame

    local toggleBtn = Instance.new("ImageButton")
    toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
    toggleBtn.Position = UDim2.new(1, -10, 0.5, 0)
    toggleBtn.Size = UDim2.new(0, 50, 0, 28)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(56, 57, 59)
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = frame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 22, 0, 22)
    circle.Position = UDim2.new(0, 3, 0.5, -11)
    circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    circle.BorderSizePixel = 0
    circle.Parent = toggleBtn
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local state = data.Default or false
    local function updateVisual()
        local goalPos = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
        local goalColor = state and Color3.fromRGB(51, 95, 255) or Color3.fromRGB(56, 57, 59)
        local goalCircle = state and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200)
        TweenService:Create(circle, TweenInfo.new(0.15), {Position = goalPos}):Play()
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = goalColor}):Play()
        TweenService:Create(circle, TweenInfo.new(0.15), {BackgroundColor3 = goalCircle}):Play()
    end
    updateVisual()

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        if data.Callback then task.spawn(data.Callback, state) end
    end)
    return frame
end

local function createSelector(parent, data)
    local options = data.Options or {"1", "2", "3"}
    local currentIndex = 1

    local frame = Instance.new("ImageButton")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.AutoButtonColor = false
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.4, -20, 1, 0)
    label.Text = data.Text or "Seletor"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    label.TextSize = 12
    label.Parent = frame

    local selector = Instance.new("ImageButton")
    selector.AnchorPoint = Vector2.new(1, 0.5)
    selector.Position = UDim2.new(1, 0, 0.5, 0)
    selector.Size = UDim2.new(0.6, 0, 0, 50)
    selector.BackgroundTransparency = 1
    selector.AutoButtonColor = false
    selector.Parent = frame

    local leftBtn = Instance.new("ImageButton")
    leftBtn.AnchorPoint = Vector2.new(0, 0.5)
    leftBtn.Position = UDim2.new(0, 0, 0.5, 0)
    leftBtn.Size = UDim2.new(0, 32, 0, 50)
    leftBtn.BackgroundTransparency = 1
    leftBtn.Parent = selector
    local leftImg = Instance.new("ImageLabel")
    leftImg.Image = "rbxasset://textures/ui/Settings/Slider/Left.png"
    leftImg.ImageColor3 = Color3.fromRGB(204, 204, 204)
    leftImg.BackgroundTransparency = 1
    leftImg.AnchorPoint = Vector2.new(0.5, 0.5)
    leftImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    leftImg.Size = UDim2.new(0, 18, 0, 30)
    leftImg.Parent = leftBtn

    local rightBtn = Instance.new("ImageButton")
    rightBtn.AnchorPoint = Vector2.new(1, 0.5)
    rightBtn.Position = UDim2.new(1, 0, 0.5, 0)
    rightBtn.Size = UDim2.new(0, 32, 0, 50)
    rightBtn.BackgroundTransparency = 1
    rightBtn.Parent = selector
    local rightImg = Instance.new("ImageLabel")
    rightImg.Image = "rbxasset://textures/ui/Settings/Slider/Right.png"
    rightImg.ImageColor3 = Color3.fromRGB(204, 204, 204)
    rightImg.BackgroundTransparency = 1
    rightImg.AnchorPoint = Vector2.new(0.5, 0.5)
    rightImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    rightImg.Size = UDim2.new(0, 18, 0, 30)
    rightImg.Parent = rightBtn

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(0, 32, 0, 0)
    valueLabel.Size = UDim2.new(1, -64, 1, 0)
    valueLabel.Text = options[1]
    valueLabel.TextColor3 = Color3.new(1, 1, 1)
    valueLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    valueLabel.TextSize = 12
    valueLabel.Parent = selector

    local function update()
        TweenService:Create(valueLabel, TweenInfo.new(0.08), {TextTransparency = 1}):Play()
        task.delay(0.08, function()
            valueLabel.Text = options[currentIndex]
            TweenService:Create(valueLabel, TweenInfo.new(0.08), {TextTransparency = 0}):Play()
        end)
        if data.Callback then task.spawn(data.Callback, options[currentIndex], currentIndex) end
    end

    leftBtn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #options end
        update()
    end)
    rightBtn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        update()
    end)
    return frame
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
        ButtonPosition = data.ButtonPosition or data.Position or "None", Callback = data.Callback
    })
end

function BlueButton(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "BlueButton", Tab = data.Tab, Text = data.Text or "Continuar",
        ButtonPosition = data.ButtonPosition or data.Position or "None", Callback = data.Callback
    })
end

function Label(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Label", Tab = data.Tab, Text = data.Text or "Seção",
        Description = data.Description, Position = data.Position or "None"
    })
end

function Dropdown(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Dropdown", Tab = data.Tab, Text = data.Text or "Opção",
        Options = data.Options or {"Opção 1", "Opção 2"}, Callback = data.Callback
    })
end

function Toggle(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Toggle", Tab = data.Tab, Text = data.Text or "Toggle",
        Default = data.Default or false, Callback = data.Callback
    })
end

function Selector(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Selector", Tab = data.Tab, Text = data.Text or "Seletor",
        Options = data.Options or {"1", "2", "3"}, Callback = data.Callback
    })
end

local function processEverything()
    local hub, page = waitForHubBar()
    if not hub then return end

    for _, cfg in ipairs(PendingTabs) do
        createTab(hub, page, cfg)
    end
    table.clear(PendingTabs)

    for _, el in ipairs(PendingElements) do
        local tabData = CreatedTabs[el.Tab]
        if tabData and tabData.contentParent then
            -- evita duplicar elementos se já processou
            if not tabData.contentParent:FindFirstChild(el.Type .. "_" .. (el.Text or ""):gsub("%s+", ""), true) then
                if el.Type == "Button" then createButton(tabData.contentParent, el)
                elseif el.Type == "BlueButton" then createBlueButton(tabData.contentParent, el)
                elseif el.Type == "Label" then createLabel(tabData.contentParent, el)
                elseif el.Type == "Dropdown" then createDropdown(tabData.contentParent, el)
                elseif el.Type == "Toggle" then createToggle(tabData.contentParent, el)
                elseif el.Type == "Selector" then createSelector(tabData.contentParent, el)
                end
            end
        end
    end
    table.clear(PendingElements)
    IsProcessed = true
end

task.spawn(function()
    task.wait(1.2)
    processEverything()
end)

-- Reage quando o menu reabre
CoreGui.DescendantAdded:Connect(function(desc)
    if desc.Name == "HubBarContainer" then
        task.wait(0.6)
        -- limpa referências mortas
        for name, data in pairs(CreatedTabs) do
            if not data.tabButton or not data.tabButton.Parent then
                CreatedTabs[name] = nil
            end
        end
        processEverything()
    end
end)
