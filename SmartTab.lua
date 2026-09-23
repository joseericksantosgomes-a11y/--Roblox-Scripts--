--[[
    Smart Tab Library v4
    Cada Tab cria seu próprio PageView integrado
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Pending = {}

local function waitForHubBar()
    local robloxGui = CoreGui:WaitForChild("RobloxGui", 15)
    if not robloxGui then return nil end

    local settingsShield = robloxGui:FindFirstChild("SettingsClippingShield")
        or robloxGui:WaitForChild("SettingsClippingShield", 8)
    if not settingsShield then return nil end

    local settingsShield2 = settingsShield:FindFirstChild("SettingsShield")
        or settingsShield:WaitForChild("SettingsShield", 5)
    if not settingsShield2 then return nil end

    local menuContainer = settingsShield2:FindFirstChild("MenuContainer")
        or settingsShield2:WaitForChild("MenuContainer", 5)
    if not menuContainer then return nil end

    local page = menuContainer:FindFirstChild("Page")
        or menuContainer:WaitForChild("Page", 5)
    if not page then return nil end

    local hubBar = page:FindFirstChild("HubBar")
        or page:WaitForChild("HubBar", 5)
    if not hubBar then return nil end

    local tabHeader = hubBar:FindFirstChild("TabHeaderContainer")
        or hubBar:WaitForChild("TabHeaderContainer", 5)
    if not tabHeader then return nil end

    return tabHeader:FindFirstChild("HubBarContainer") or tabHeader:WaitForChild("HubBarContainer", 5), page
end

local function getPageViewInnerFrame(page)
    local clipper = page:FindFirstChild("PageViewClipper")
    if not clipper then return nil end
    local pageView = clipper:FindFirstChild("PageView")
    if not pageView then return nil end
    return pageView:FindFirstChild("PageViewInnerFrame")
end

local function createTab(hubBarContainer, page, config)
    if not hubBarContainer or not config then return end

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
        scroll.ClipsDescendants = false
        scroll.Parent = hubBarContainer

        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Horizontal
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.VerticalAlignment = Enum.VerticalAlignment.Center
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 4)
        list.Parent = scroll

        for _, child in ipairs(hubBarContainer:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("Tab") and not child:GetAttribute("SmartTab") then
                child.Parent = scroll
            end
        end

        if originalList then
            originalList:Destroy()
        end
    end

    local tabName = "SmartTab_" .. (config.Name or "Custom"):gsub("%s+", "")
    if scroll:FindFirstChild(tabName) then return end

    -- ========== CRIA O PAGEVIEW DA TAB ==========
    local pageViewInner = getPageViewInnerFrame(page)
    local myPageView = nil

    if pageViewInner then
        myPageView = Instance.new("Frame")
        myPageView.Name = tabName .. "_Page"
        myPageView.BackgroundTransparency = 1
        myPageView.Size = UDim2.new(1, 0, 1, 0)
        myPageView.Visible = false
        myPageView.Parent = pageViewInner

        -- Conteúdo padrão do PageView (pode ser personalizado depois)
        local contentFrame = Instance.new("Frame")
        contentFrame.Name = "Content"
        contentFrame.Size = UDim2.new(1, -40, 1, -40)
        contentFrame.Position = UDim2.new(0, 20, 0, 20)
        contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        contentFrame.BorderSizePixel = 0
        contentFrame.Parent = myPageView

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = contentFrame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 50)
        title.BackgroundTransparency = 1
        title.Text = config.Name or "Tab"
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 22
        title.Parent = contentFrame

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -40, 0, 80)
        info.Position = UDim2.new(0, 20, 0, 60)
        info.BackgroundTransparency = 1
        info.Text = "PageView da tab \"" .. (config.Name or "Tab") .. "\"\n\nVocê pode editar esse Frame depois."
        info.TextColor3 = Color3.fromRGB(180, 180, 180)
        info.Font = Enum.Font.Gotham
        info.TextSize = 15
        info.TextWrapped = true
        info.Parent = contentFrame
    end

    -- ========== CRIA O BOTÃO DA TAB ==========
    local myTab = Instance.new("TextButton")
    myTab.Name = tabName
    myTab:SetAttribute("SmartTab", true)
    myTab.BackgroundTransparency = 1
    myTab.Selectable = false
    myTab.ZIndex = 5
    myTab.Text = ""
    myTab.Size = UDim2.new(0, 130, 1, 0)
    myTab.LayoutOrder = 999
    myTab.Parent = scroll

    local tabSelection = Instance.new("ImageLabel")
    tabSelection.Name = "TabSelection"
    tabSelection.Visible = false
    tabSelection.Position = UDim2.new(0, 4, 1, -2)
    tabSelection.Size = UDim2.new(1, -8, 0, 2)
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
    labelLayout.Padding = UDim.new(0, 6)
    labelLayout.Parent = tabLabel

    local icon
    local isAssetId = typeof(config.Icon) == "string" and (string.find(config.Icon, "rbxassetid://") or tonumber(config.Icon))

    if isAssetId then
        icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.ZIndex = 5
        icon.Size = UDim2.new(0, 18, 0, 18)
        icon.Image = (string.find(config.Icon, "rbxassetid://") and config.Icon) or ("rbxassetid://" .. config.Icon)
        icon.ImageTransparency = 0.5
        icon.Parent = tabLabel
    else
        icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.ZIndex = 5
        icon.Size = UDim2.new(0, 18, 0, 18)
        icon.TextScaled = true
        icon.TextColor3 = Color3.new(1, 1, 1)
        icon.TextTransparency = 0.5
        icon.FontFace = Font.new("rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        icon.Text = config.Icon or "star"
        icon.Parent = tabLabel
    end

    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.Parent = icon

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
    title.TextSize = 13
    title.Parent = tabLabel

    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 13
    textConstraint.Parent = title

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
        -- Desativa outros tabs
        for _, tab in ipairs(scroll:GetChildren()) do
            if tab:IsA("TextButton") then
                local sel = tab:FindFirstChild("TabSelection")
                if sel then sel.Visible = false end
            end
        end
        setActive(true)

        -- Mostra o PageView dessa tab e esconde os outros
        if pageViewInner and myPageView then
            for _, child in ipairs(pageViewInner:GetChildren()) do
                if child:IsA("Frame") then
                    child.Visible = (child == myPageView)
                end
            end
        end
    end)

    myTab.MouseEnter:Connect(function()
        if not tabSelection.Visible then
            if icon:IsA("TextLabel") then icon.TextTransparency = 0.25 else icon.ImageTransparency = 0.25 end
            title.TextTransparency = 0.25
        end
    end)

    myTab.MouseLeave:Connect(function()
        if not tabSelection.Visible then
            if icon:IsA("TextLabel") then icon.TextTransparency = 0.5 else icon.ImageTransparency = 0.5 end
            title.TextTransparency = 0.5
        end
    end)
end

function Tab(data)
    if type(data) ~= "table" then return end

    local config = {
        Name = data.Name or "Tab",
        Icon = data.Icon or "star"
    }

    table.insert(Pending, config)

    task.spawn(function()
        local hub, page = waitForHubBar()
        if hub then
            for _, cfg in ipairs(Pending) do
                createTab(hub, page, cfg)
            end
            table.clear(Pending)
        end
    end)
end

CoreGui.DescendantAdded:Connect(function(desc)
    if desc.Name == "HubBarContainer" and #Pending > 0 then
        task.wait(0.4)
        local page = desc.Parent and desc.Parent.Parent
        for _, cfg in ipairs(Pending) do
            createTab(desc, page, cfg)
        end
        table.clear(Pending)
    end
end)
