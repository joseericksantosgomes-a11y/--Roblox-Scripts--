--[[
    Smart Tab Library v2
    Auto-fix UI + ScrollingFrame inteligente
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Pending = {}
local Fixed = false

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

    return tabHeader:FindFirstChild("HubBarContainer") or tabHeader:WaitForChild("HubBarContainer", 5)
end

local function getContentContainer()
    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if not robloxGui then return nil end

    local settingsShield = robloxGui:FindFirstChild("SettingsClippingShield")
    if not settingsShield then return nil end

    local settingsShield2 = settingsShield:FindFirstChild("SettingsShield")
    if not settingsShield2 then return nil end

    local menuContainer = settingsShield2:FindFirstChild("MenuContainer")
    if not menuContainer then return nil end

    return menuContainer:FindFirstChild("Page")
end

local function fixHubBar(hubBarContainer)
    if not hubBarContainer or Fixed then return end

    -- Cria ou pega o ScrollingFrame
    local scroll = hubBarContainer:FindFirstChild("SmartTabScroll")
    if not scroll then
        scroll = Instance.new("ScrollingFrame")
        scroll.Name = "SmartTabScroll"
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.Position = UDim2.new(0, 0, 0, 0)
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
        scroll.ScrollBarThickness = 4
        scroll.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
        scroll.ScrollingDirection = Enum.ScrollingDirection.X
        scroll.ElasticBehavior = Enum.ElasticBehavior.Never
        scroll.ZIndex = 5
        scroll.ClipsDescendants = true
        scroll.Parent = hubBarContainer
    end

    -- UIListLayout limpo
    local list = scroll:FindFirstChildOfClass("UIListLayout")
    if not list then
        list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Horizontal
        list.HorizontalAlignment = Enum.HorizontalAlignment.Left
        list.VerticalAlignment = Enum.VerticalAlignment.Center
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 6)
        list.Parent = scroll
    end

    -- Remove layout antigo do HubBarContainer
    for _, child in ipairs(hubBarContainer:GetChildren()) do
        if child:IsA("UIListLayout") and child.Parent == hubBarContainer then
            child:Destroy()
        end
    end

    -- Move TODOS os tabs nativos pro ScrollingFrame e ajusta tamanho
    for _, child in ipairs(hubBarContainer:GetChildren()) do
        if child:IsA("TextButton") and (child.Name:find("Tab") or child.Name:find("tab")) and not child:GetAttribute("SmartTab") then
            child.Parent = scroll
            child.Size = UDim2.new(0, 140, 1, 0)
            child.AutomaticSize = Enum.AutomaticSize.None
        end
    end

    -- Também pega qualquer ScrollingFrame antigo do Roblox e move o conteúdo
    for _, child in ipairs(hubBarContainer:GetChildren()) do
        if child:IsA("ScrollingFrame") and child.Name ~= "SmartTabScroll" then
            for _, tab in ipairs(child:GetChildren()) do
                if tab:IsA("TextButton") then
                    tab.Parent = scroll
                    tab.Size = UDim2.new(0, 140, 1, 0)
                end
            end
            child:Destroy()
        end
    end

    Fixed = true
end

local function createTab(hubBarContainer, config)
    if not hubBarContainer or not config then return end

    fixHubBar(hubBarContainer)

    local scroll = hubBarContainer:FindFirstChild("SmartTabScroll")
    if not scroll then return end

    local tabName = "SmartTab_" .. (config.Name or "Custom"):gsub("%s+", "")
    if scroll:FindFirstChild(tabName) then return end

    local myTab = Instance.new("TextButton")
    myTab.Name = tabName
    myTab:SetAttribute("SmartTab", true)
    myTab.BackgroundTransparency = 1
    myTab.Selectable = false
    myTab.ZIndex = 6
    myTab.Text = ""
    myTab.Size = UDim2.new(0, 140, 1, 0)
    myTab.LayoutOrder = 999
    myTab.Parent = scroll

    -- Selection bar
    local tabSelection = Instance.new("ImageLabel")
    tabSelection.Name = "TabSelection"
    tabSelection.Visible = false
    tabSelection.Position = UDim2.new(0, 4, 1, -3)
    tabSelection.Size = UDim2.new(1, -8, 0, 2)
    tabSelection.ZIndex = 6
    tabSelection.BorderSizePixel = 0
    tabSelection.BackgroundColor3 = Color3.new(1, 1, 1)
    tabSelection.Parent = myTab

    -- Label container
    local tabLabel = Instance.new("Frame")
    tabLabel.Name = "TabLabel"
    tabLabel.BackgroundTransparency = 1
    tabLabel.ZIndex = 6
    tabLabel.Size = UDim2.new(1, 0, 1, 0)
    tabLabel.Parent = myTab

    local labelLayout = Instance.new("UIListLayout")
    labelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    labelLayout.FillDirection = Enum.FillDirection.Horizontal
    labelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    labelLayout.Padding = UDim.new(0, 8)
    labelLayout.Parent = tabLabel

    -- Ícone
    local icon
    local isAssetId = typeof(config.Icon) == "string" and (string.find(config.Icon, "rbxassetid://") or tonumber(config.Icon))

    if isAssetId then
        icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.ZIndex = 6
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Image = (string.find(config.Icon, "rbxassetid://") and config.Icon) or ("rbxassetid://" .. config.Icon)
        icon.ImageTransparency = 0.5
        icon.Parent = tabLabel
    else
        icon = Instance.new("TextLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.ZIndex = 6
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.TextScaled = true
        icon.TextWrapped = true
        icon.TextColor3 = Color3.new(1, 1, 1)
        icon.TextTransparency = 0.5
        icon.FontFace = Font.new("rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        icon.Text = config.Icon or "star"
        icon.Parent = tabLabel
    end

    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.Parent = icon

    -- Título
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextTransparency = 0.5
    title.Text = config.Name or "Tab"
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 6
    title.AutomaticSize = Enum.AutomaticSize.XY
    title.TextSize = 14
    title.Parent = tabLabel

    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MaxTextSize = 14
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
        -- Desativa todos os outros
        for _, tab in ipairs(scroll:GetChildren()) do
            if tab:IsA("TextButton") then
                local sel = tab:FindFirstChild("TabSelection")
                if sel then sel.Visible = false end
            end
        end
        setActive(true)

        -- Content
        if config.Content and config.Content ~= "default" and config.Content ~= "" then
            local contentContainer = getContentContainer()
            local customFrame = nil

            for _, gui in ipairs({LocalPlayer:FindFirstChild("PlayerGui"), CoreGui}) do
                if gui then
                    customFrame = gui:FindFirstChild(config.Content, true)
                    if customFrame then break end
                end
            end

            if customFrame and (customFrame:IsA("Frame") or customFrame:IsA("ScrollingFrame") or customFrame:IsA("CanvasGroup")) then
                -- Esconde conteúdos nativos se possível
                if contentContainer then
                    for _, child in ipairs(contentContainer:GetChildren()) do
                        if (child:IsA("Frame") or child:IsA("ScrollingFrame")) and child.Name ~= "HubBar" and child.Name ~= "TabHeaderContainer" then
                            child.Visible = false
                        end
                    end
                end
                customFrame.Visible = true
            end
        end
    end)

    myTab.MouseEnter:Connect(function()
        if not tabSelection.Visible then
            if icon:IsA("TextLabel") then icon.TextTransparency = 0.2 else icon.ImageTransparency = 0.2 end
            title.TextTransparency = 0.2
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
        Icon = data.Icon or "star",
        Content = data.Content or "default"
    }

    table.insert(Pending, config)

    task.spawn(function()
        local hub = waitForHubBar()
        if hub then
            fixHubBar(hub)
            for _, cfg in ipairs(Pending) do
                createTab(hub, cfg)
            end
            table.clear(Pending)
        end
    end)
end

-- Auto-fix quando o menu abrir
CoreGui.DescendantAdded:Connect(function(desc)
    if desc.Name == "HubBarContainer" then
        task.wait(0.3)
        fixHubBar(desc)
        if #Pending > 0 then
            for _, cfg in ipairs(Pending) do
                createTab(desc, cfg)
            end
            table.clear(Pending)
        end
    end
end)
