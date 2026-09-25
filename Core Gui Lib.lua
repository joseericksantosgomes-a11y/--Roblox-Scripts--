--[[
    Smart Tab Library v24
    + PutOn / DeleteNativeTab for IN-GAME Esc menu tabs:
      Pessoas, Config, Help, Report (ConfigurationsTabRoblox, etc.)
    + SizeType, Side, Lucide, SetOption in Callback
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Lucide Icons (Footagesus Icons v2)
local IconsLib = nil
task.spawn(function()
    pcall(function()
        local http = game:GetService("HttpService")
        local src
        local ok = pcall(function()
            src = game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua")
        end)
        if not ok or not src then
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
    -- rbxassetid or number
    if string.find(s, "rbxassetid://") then
        return "image", s
    end
    if tonumber(s) then
        return "image", "rbxassetid://" .. s
    end
    -- Lucide name
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
    -- fallback: texto (BuilderIcons / emoji / nome)
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
local NativeTabs = {} -- inject into Roblox native tabs by name
local ActiveName = nil
local LastActiveName = nil
local HubScroll = nil
local PageViewInner = nil
-- registro de elementos para SetOption por nome (Text)
local ElementRegistry = {} -- [key] = { frame, stateRef, onLock, onUnlock }

-- Aliases das tabs NATIVAS DO MENU IN-GAME (Esc)
-- Pessoas | Config | Help | Report (e variações PT/EN)
local NativeTabAliases = {
    -- Config / Settings (in-game)
    ConfigurationsTabRoblox = {"config", "settings", "configurações", "configuracoes", "configuration", "game settings", "settingspage", "opções", "opcoes"},
    ConfigTabRoblox = {"config", "settings", "configurações", "configuracoes", "configuration"},
    Config = {"config", "settings", "configurações", "configuracoes"},
    SettingsTabRoblox = {"settings", "config", "configurações", "configuracoes", "game settings"},
    Settings = {"settings", "config", "configurações", "configuracoes"},
    Configurações = {"configurações", "configuracoes", "config", "settings"},
    Configuracoes = {"configuracoes", "configurações", "config", "settings"},

    -- People / Players / Pessoas (in-game)
    PeopleTabRoblox = {"people", "players", "pessoas", "jogadores", "player list"},
    PessoasTabRoblox = {"pessoas", "people", "players", "jogadores"},
    Pessoas = {"pessoas", "people", "players", "jogadores"},
    PlayersTabRoblox = {"players", "people", "pessoas", "jogadores"},
    Players = {"players", "people", "pessoas", "jogadores"},
    People = {"people", "players", "pessoas", "jogadores"},

    -- Help / Ajuda (in-game)
    HelpTabRoblox = {"help", "ajuda", "help & support", "help and support"},
    Help = {"help", "ajuda"},
    Ajuda = {"ajuda", "help"},

    -- Report / Denunciar (in-game)
    ReportTabRoblox = {"report", "report abuse", "denunciar", "abuse", "report a user"},
    ReportAbuse = {"report abuse", "report", "denunciar", "abuse"},
    Report = {"report", "report abuse", "denunciar"},
    Denunciar = {"denunciar", "report", "report abuse"},

    -- Outros comuns in-game
    HomeTabRoblox = {"home", "início", "inicio"},
    Home = {"home", "início", "inicio"},
    AvatarTabRoblox = {"avatar", "character", "personagem"},
    Avatar = {"avatar", "character", "personagem"},
    RecordTabRoblox = {"record", "gravar", "recording"},
    Record = {"record", "gravar"},
    PrivacyTabRoblox = {"privacy", "privacidade"},
    Privacy = {"privacy", "privacidade"},
}

local function resolveNativeNames(key)
    if not key then return {} end
    local s = tostring(key)
    local aliases = NativeTabAliases[s]
    if aliases then
        local out = { string.lower(s) }
        for _, a in ipairs(aliases) do
            table.insert(out, string.lower(a))
        end
        return out
    end
    return { string.lower(s) }
end

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

-- Encontra botão nativo do HubBar IN-GAME pelo texto (Pessoas/Config/Help/Report)
local function findNativeTabButton(hub, tabName)
    if not hub then return nil end
    local targets = resolveNativeNames(tabName)
    local containers = { hub }
    local scroll = hub:FindFirstChild("SmartTabScroll")
    if scroll then table.insert(containers, scroll) end

    local function collectTexts(obj, into)
        if obj:IsA("TextButton") or obj:IsA("TextLabel") then
            local t = obj.Text
            if type(t) == "string" and t ~= "" then
                table.insert(into, t)
            end
        end
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local t = d.Text
                if type(t) == "string" and t ~= "" then
                    table.insert(into, t)
                end
            end
        end
    end

    local function matches(texts)
        for _, t in ipairs(texts) do
            local low = string.lower(t):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
            for _, target in ipairs(targets) do
                if low == target then return true end
                if #target >= 3 and (string.find(low, target, 1, true) or string.find(target, low, 1, true)) then
                    return true
                end
            end
        end
        return false
    end

    for _, parent in ipairs(containers) do
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("GuiObject") and not child:GetAttribute("SmartTab") then
                -- TextButton direto ou frame que contém o tab
                if child:IsA("TextButton") then
                    local texts = {}
                    collectTexts(child, texts)
                    if matches(texts) then
                        return child, texts[1]
                    end
                else
                    -- às vezes o botão está dentro de um frame
                    local btn = child:FindFirstChildWhichIsA("TextButton", true)
                    if btn and not btn:GetAttribute("SmartTab") then
                        local texts = {}
                        collectTexts(child, texts)
                        if matches(texts) then
                            return btn, texts[1]
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Cria/obtém área de conteúdo injetada numa tab nativa do Roblox
local function ensureNativeTab(tabName)
    if NativeTabs[tabName] and NativeTabs[tabName].content and NativeTabs[tabName].content.Parent then
        return NativeTabs[tabName]
    end

    local hub, page, inner = findHubAndPage()
    if not hub or not inner then return nil end
    PageViewInner = inner

    local nativeBtn = findNativeTabButton(hub, tabName)

    -- Procura frame de página nativa pelo nome
    local nativePage = nil
    local targets = resolveNativeNames(tabName)
    for _, child in ipairs(inner:GetChildren()) do
        if child:IsA("GuiObject") and not child:GetAttribute("SmartPage") and not child:GetAttribute("SmartNative") then
            local n = string.lower(child.Name)
            for _, target in ipairs(targets) do
                if n == target or string.find(n, target, 1, true) or string.find(target, n, 1, true) then
                    nativePage = child
                    break
                end
            end
            if nativePage then break end
        end
    end

    -- Se não achou página pelo nome, usa a página visível quando a tab nativa for clicada
    -- Por enquanto cria um container SmartNative no PageViewInnerFrame
    local injectParent = nativePage or inner
    local injectName = "SmartNative_" .. tostring(tabName):gsub("%s+", "_")

    local existing = injectParent:FindFirstChild(injectName)
    local pageView = existing
    local content = existing and existing:FindFirstChild("Content")

    if not pageView then
        pageView = Instance.new("Frame")
        pageView.Name = injectName
        pageView:SetAttribute("SmartNative", true)
        pageView:SetAttribute("SmartNativeTab", tabName)
        pageView.BackgroundTransparency = 1
        pageView.Size = UDim2.new(1, 0, 0, 0)
        pageView.AutomaticSize = Enum.AutomaticSize.Y
        pageView.LayoutOrder = -100 -- no topo quando possível
        pageView.ZIndex = 5
        pageView.Visible = true
        pageView.Parent = injectParent

        local sf = Instance.new("Frame")
        sf.Name = "Content"
        sf.BackgroundTransparency = 1
        sf.Size = UDim2.new(1, 0, 0, 0)
        sf.AutomaticSize = Enum.AutomaticSize.Y
        sf.Parent = pageView

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 6)
        list.Parent = sf

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = sf
        content = sf
    end

    if not content then
        content = pageView:FindFirstChild("Content")
    end

    local data = {
        button = nativeBtn,
        setActive = function() end,
        pageView = pageView,
        content = content,
        rows = {},
        name = tabName,
        isNative = true
    }
    NativeTabs[tabName] = data

    -- Quando clicar na tab nativa, garante visibilidade do inject
    if nativeBtn and not nativeBtn:GetAttribute("SmartNativeHook") then
        nativeBtn:SetAttribute("SmartNativeHook", true)
        nativeBtn.MouseButton1Click:Connect(function()
            deselectAllCustom()
            LastActiveName = nil
            if pageView then pageView.Visible = true end
        end)
    end

    return data
end


local function resolveElementTab(el)
    -- PutOn tem prioridade para tabs nativas
    if el.PutOn and el.PutOn ~= "" then
        return tostring(el.PutOn), true
    end
    return el.Tab, false
end

local function getTabData(tabName)
    if not tabName then return nil end
    if Tabs[tabName] and Tabs[tabName].content then
        return Tabs[tabName]
    end
    if NativeTabs[tabName] and NativeTabs[tabName].content then
        return NativeTabs[tabName]
    end
    -- tenta criar inject na tab nativa
    return ensureNativeTab(tabName)
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
    else
        -- Fallback se PageViewInnerFrame ainda não existe
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
        Instance.new("UIListLayout", sf).Padding = UDim.new(0, 6)
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 12)
        pad.PaddingBottom = UDim.new(0, 16)
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

-- SizeType Full = 100% width, Default = compact (~160px)
-- Side Left/Right = half row when paired
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
        Type = "Button", Tab = data.Tab, PutOn = data.PutOn, Text = data.Text or "Botão", Icon = data.Icon,
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        Side = data.Side, SizeType = data.SizeType or "Full",
        SetOption = data.SetOption, Callback = data.Callback, Default = data.Default
    })
end

function BlueButton(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "BlueButton", Tab = data.Tab, PutOn = data.PutOn, Text = data.Text or "Continuar", Icon = data.Icon,
        ButtonPosition = data.ButtonPosition or data.Position or "None",
        Side = data.Side, SizeType = data.SizeType or "Full",
        SetOption = data.SetOption, Callback = data.Callback, Default = data.Default
    })
end

function Label(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Label", Tab = data.Tab, PutOn = data.PutOn, Text = data.Text or "Seção", Icon = data.Icon,
        Description = data.Description, SetOption = data.SetOption
    })
end


function Toggle(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Toggle", Tab = data.Tab, PutOn = data.PutOn, Text = data.Text or "Toggle", Icon = data.Icon,
        Side = data.Side, SizeType = data.SizeType or "Full",
        Default = data.Default or false, SetOption = data.SetOption, Callback = data.Callback
    })
end

function Dropdown(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Dropdown", Tab = data.Tab, PutOn = data.PutOn, Text = data.Text or "Opção", Icon = data.Icon,
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
        Type = "Slider", Tab = data.Tab, PutOn = data.PutOn, Text = data.Text or "Slider", Icon = data.Icon,
        Min = data.Min or 0, Max = data.Max or 100, Default = data.Default,
        SetOption = data.SetOption, Callback = data.Callback
    })
end

function Input(data)
    if type(data) ~= "table" then return end
    table.insert(PendingElements, {
        Type = "Input", Tab = data.Tab, PutOn = data.PutOn, Text = data.Text or "Input", Icon = data.Icon,
        Side = data.Side, SizeType = data.SizeType or "Full",
        Default = data.Default, Placeholder = data.Placeholder,
        SetOption = data.SetOption, Callback = data.Callback
    })
end

function Textbox(data)
    Input(data)
end

-- Deleta tab CUSTOM
-- DeleteTab("Painel")
-- DeleteTab({ Name = "Painel" })
function DeleteTab(data)
    local name, hideOnly
    if type(data) == "string" then
        name = data
        hideOnly = false
    elseif type(data) == "table" then
        -- se veio DeleteNativeTab, redireciona
        if data.DeleteNativeTab then
            DeleteNativeTab(data.DeleteNativeTab)
            return
        end
        name = data.Name or data.Tab or data[1]
        hideOnly = data.HideOnly == true
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

    -- se o nome também for nativo, limpa inject
    if NativeTabs[name] then
        pcall(function()
            if NativeTabs[name].pageView then NativeTabs[name].pageView:Destroy() end
        end)
        NativeTabs[name] = nil
    end

    local leftTabs = {}
    for _, cfg in ipairs(PendingTabs) do
        if cfg.Name ~= name then table.insert(leftTabs, cfg) end
    end
    PendingTabs = leftTabs

    local leftEls = {}
    for _, el in ipairs(PendingElements) do
        local target = el.PutOn or el.Tab
        if target ~= name then table.insert(leftEls, el) end
    end
    PendingElements = leftEls
end

function RemoveTab(data)
    DeleteTab(data)
end

-- Deleta tab NATIVA do Roblox (HubBar)
-- DeleteNativeTab("ConfigurationsTabRoblox")
-- DeleteNativeTab("HelpTabRoblox")
-- DeleteNativeTab("ReportAbuse")
-- DeleteNativeTab({ Name = "ConfigurationsTabRoblox", HideOnly = true })
function DeleteNativeTab(data)
    local name, hideOnly
    if type(data) == "string" then
        name = data
        hideOnly = false
    elseif type(data) == "table" then
        name = data.Name or data.DeleteNativeTab or data.Tab or data[1]
        hideOnly = data.HideOnly == true
    else
        return
    end
    if not name then return end

    -- limpa inject Smart nessa tab nativa
    if NativeTabs[name] then
        pcall(function()
            if NativeTabs[name].pageView then NativeTabs[name].pageView:Destroy() end
        end)
        NativeTabs[name] = nil
    end
    -- também tenta aliases como key
    for key, _ in pairs(NativeTabs) do
        local names = resolveNativeNames(name)
        for _, n in ipairs(names) do
            if string.lower(tostring(key)) == n then
                pcall(function()
                    if NativeTabs[key].pageView then NativeTabs[key].pageView:Destroy() end
                end)
                NativeTabs[key] = nil
            end
        end
    end

    local hub = select(1, findHubAndPage())
    if hub then
        local btn = findNativeTabButton(hub, name)
        if btn then
            pcall(function()
                if hideOnly then
                    btn.Visible = false
                else
                    btn:Destroy()
                end
            end)
        end
    end

    local leftEls = {}
    for _, el in ipairs(PendingElements) do
        local target = el.PutOn or el.Tab
        if target ~= name then table.insert(leftEls, el) end
    end
    PendingElements = leftEls
end

-- ====================== PROCESS ======================
local function process()
    local hub, page, inner = findHubAndPage()
    if not hub then return false end

    -- Tabs: só remove da fila as que foram criadas
    local leftTabs = {}
    for _, cfg in ipairs(PendingTabs) do
        local before = Tabs[cfg.Name]
        pcall(createTab, hub, page, inner, cfg)
        if Tabs[cfg.Name] and Tabs[cfg.Name].content then
            -- ok
        elseif Tabs[cfg.Name] and not Tabs[cfg.Name].content then
            -- tab button existe mas sem content (inner nil) - tenta de novo depois
            table.insert(leftTabs, cfg)
        else
            table.insert(leftTabs, cfg)
        end
    end
    PendingTabs = leftTabs

    -- Elements: custom tabs OU tabs nativas do Roblox
    local leftEls = {}
    for _, el in ipairs(PendingElements) do
        local targetName = el.PutOn and el.PutOn ~= "" and el.PutOn or el.Tab
        local tabData = getTabData(targetName)
        if tabData and tabData.content then
            if el._done then
                -- already created
            else
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
            end
        else
            table.insert(leftEls, el)
        end
    end
    PendingElements = leftEls

    if LastActiveName and Tabs[LastActiveName] then
        task.defer(function()
            task.wait(0.15)
            selectCustomTab(LastActiveName)
        end)
    end
    return next(Tabs) ~= nil
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
