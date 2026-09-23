--[[
    Smart Tab Library v3
    Versão estável - não quebra o layout original
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

    return tabHeader:FindFirstChild("HubBarContainer") or tabHeader:WaitForChild("HubBarContainer", 5)
end

local function createTab(hubBarContainer, config)
    if not hubBarContainer or not config then return end

    -- Procura se já existe um ScrollingFrame nativo ou cria um leve
    local scroll = hubBarContainer:FindFirstChild("SmartTabScroll")
    if not scroll then
        -- Tenta usar o UIListLayout original se existir
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

        -- Move os tabs nativos com cuidado (só se ainda estiverem no HubBarContainer)
        for _, child in ipairs(hubBarContainer:GetChildren()) do
            if child:IsA("TextButton") and child.Name:find("Tab") and not child:GetAttribute("SmartTab") then
                child.Parent = scroll
            end
        end

        -- Remove o layout antigo pra não conflitar
        if originalList then
            originalList:Destroy()
        end
    end

    local tabName = "SmartTab_" .. (config.Name or "Custom"):gsub("%s+", "")
    if scroll:FindFirstChild(tabName) then return end

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

    -- Linha de seleção
    local tabSelection = Instance.new("ImageLabel")
    tabSelection.Name = "TabSelection"
    tabSelection.Visible = false
    tabSelection.Position = UDim2.new(0, 4, 1, -2)
    tabSelection.Size = UDim2.new(1, -8, 0, 2)
    tabSelection.ZIndex = 5
    tabSelection.BorderSizePixel = 0
    tabSelection.BackgroundColor3 = Color3.new(1, 1, 1)
    tabSelection.Parent = myTab

    -- Container do label
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

    -- Ícone
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

    -- Título
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
        for _, tab in ipairs(scroll:GetChildren()) do
            if tab:IsA("TextButton") then
                local sel = tab:FindFirstChild("TabSelection")
                if sel then sel.Visible = false end
            end
        end
        setActive(true)

        if config.Content and config.Content ~= "default" and config.Content ~= "" then
            local customFrame = nil
            for _, gui in ipairs({LocalPlayer:FindFirstChild("PlayerGui"), CoreGui}) do
                if gui then
                    customFrame = gui:FindFirstChild(config.Content, true)
                    if customFrame then break end
                end
            end

            if customFrame then
                customFrame.Visible = true
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
        Icon = data.Icon or "star",
        Content = data.Content or "default"
    }

    table.insert(Pending, config)

    task.spawn(function()
        local hub = waitForHubBar()
        if hub then
            for _, cfg in ipairs(Pending) do
                createTab(hub, cfg)
            end
            table.clear(Pending)
        end
    end)
end

CoreGui.DescendantAdded:Connect(function(desc)
    if desc.Name == "HubBarContainer" and #Pending > 0 then
        task.wait(0.4)
        for _, cfg in ipairs(Pending) do
            createTab(desc, cfg)
        end
        table.clear(Pending)
    end
end)
