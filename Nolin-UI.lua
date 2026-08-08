--[[  
    NOLIN-UI v2.0 - Полная переработка на основе логики Rayfield  
    Совместимость: Xeno, Synapse X, Fluxus, Delta, KRNL, Wave  
--]]  

if _G.NolinUILoaded then  
    pcall(function() _G.NolinUILoaded:Destroy() end)  
end  
if _G.NolinConns then  
    for _, c in pairs(_G.NolinConns) do pcall(function() c:Disconnect() end) end  
end  
_G.NolinConns = {}  

local TweenService = game:GetService("TweenService")  
local UserInputService = game:GetService("UserInputService")  
local RunService = game:GetService("RunService")  
local Players = game:GetService("Players")  
local CoreGui = game:GetService("CoreGui")  

local LP = Players.LocalPlayer  

-- ============================================================================  
-- ТЕМА  
-- ============================================================================  

local T = {  
    Bg = Color3.fromRGB(18, 18, 26),  
    BgAlt = Color3.fromRGB(24, 24, 34),  
    Sidebar = Color3.fromRGB(14, 14, 20),  
    Elem = Color3.fromRGB(28, 28, 40),  
    ElemHov = Color3.fromRGB(38, 38, 52),  
    ElemPress = Color3.fromRGB(48, 48, 66),  
    Accent = Color3.fromRGB(96, 110, 245),  
    AccentDim = Color3.fromRGB(70, 82, 200),  
    Text = Color3.fromRGB(240, 240, 250),  
    TextDim = Color3.fromRGB(160, 160, 180),  
    TextMut = Color3.fromRGB(100, 100, 120),  
    Border = Color3.fromRGB(50, 50, 70),  
    Track = Color3.fromRGB(40, 40, 55),  
    Off = Color3.fromRGB(55, 55, 75),  
    Ok = Color3.fromRGB(80, 190, 130),  
    Warn = Color3.fromRGB(250, 170, 40),  
    Err = Color3.fromRGB(240, 80, 90),  
}  

-- ============================================================================  
-- HELPERS  
-- ============================================================================  

local function tween(obj, t, props, style, dir)  
    if not obj then return end  
    local info = TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)  
    local tw = TweenService:Create(obj, info, props)  
    tw:Play()  
    return tw  
end  

local function new(class, props)  
    local i = Instance.new(class)  
    for k, v in pairs(props or {}) do  
        i[k] = v  
    end  
    return i  
end  

local function corner(p, r)  
    local c = Instance.new("UICorner")  
    c.CornerRadius = UDim.new(0, r or 8)  
    c.Parent = p  
end  

local function stroke(p, col, th, tr)  
    local s = Instance.new("UIStroke")  
    s.Color = col or T.Border  
    s.Thickness = th or 1  
    s.Transparency = tr or 0.5  
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border  
    s.Parent = p  
    return s  
end  

local function padding(p, t, b, l, r)  
    local pd = Instance.new("UIPadding")  
    pd.PaddingTop = UDim.new(0, t or 0)  
    pd.PaddingBottom = UDim.new(0, b or 0)  
    pd.PaddingLeft = UDim.new(0, l or 0)  
    pd.PaddingRight = UDim.new(0, r or 0)  
    pd.Parent = p  
end  

local function listLayout(p, spc)  
    local l = Instance.new("UIListLayout")  
    l.FillDirection = Enum.FillDirection.Vertical  
    l.Padding = UDim.new(0, spc or 6)  
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center  
    l.VerticalAlignment = Enum.VerticalAlignment.Top  
    l.SortOrder = Enum.SortOrder.LayoutOrder  
    l.Parent = p  
    return l  
end  

local function protectGui(g)  
    local ok = false  
    pcall(function()  
        if gethui then g.Parent = gethui() ok = true end  
    end)  
    if ok then return end  
    pcall(function()  
        if syn and syn.protect_gui then syn.protect_gui(g) g.Parent = CoreGui ok = true end  
    end)  
    if ok then return end  
    pcall(function() g.Parent = CoreGui ok = true end)  
    if ok then return end  
    pcall(function() g.Parent = LP:WaitForChild("PlayerGui") end)  
end  

local function addConn(c)  
    table.insert(_G.NolinConns, c)  
    return c  
end  

-- ============================================================================  
-- NOLIN-UI  
-- ============================================================================  

local NolinUI = {}  

function NolinUI:CreateWindow(config)  
    config = config or {}  
    local WinName = config.Name or "Nolin-UI"  
    local LoadText = config.LoadingText or "Загрузка..."  
    local LoadDur = config.LoadingDuration or 2.5  
    local ToggleKey = config.KeybindToToggle or Enum.KeyCode.RightShift  
    local Discord = config.DiscordInvite or "discord.gg/nolin"  
    local SX = config.SizeX or 580  
    local SY = config.SizeY or 420  

    -- ScreenGui  
    local Gui = new("ScreenGui", {  
        Name = "NolinUI",  
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,  
        ResetOnSpawn = false,  
        DisplayOrder = 999999,  
    })  
    protectGui(Gui)  
    _G.NolinUILoaded = Gui  

    -- ============================================================================  
    -- LOADING SCREEN  
    -- ============================================================================  

    local LoadFrame = new("Frame", {  
        Name = "Loading",  
        Size = UDim2.new(0, SX, 0, SY),  
        Position = UDim2.new(0.5, 0, 0.5, 0),  
        AnchorPoint = Vector2.new(0.5, 0.5),  
        BackgroundColor3 = T.Bg,  
        BorderSizePixel = 0,  
        Parent = Gui,  
    })  
    corner(LoadFrame, 12)  
    stroke(LoadFrame, T.Accent, 1, 0.4)  

    local logo = new("TextLabel", {  
        Size = UDim2.new(1, 0, 0, 40),  
        Position = UDim2.new(0, 0, 0.38, 0),  
        BackgroundTransparency = 1,  
        Font = Enum.Font.GothamBold,  
        Text = "NOLIN-UI",  
        TextColor3 = T.Accent,  
        TextSize = 32,  
        TextTransparency = 1,  
        Parent = LoadFrame,  
    })  

    local ver = new("TextLabel", {  
        Size = UDim2.new(1, 0, 0, 16),  
        Position = UDim2.new(0, 0, 0.52, 0),  
        BackgroundTransparency = 1,  
        Font = Enum.Font.Gotham,  
        Text = "v2.0",  
        TextColor3 = T.TextMut,  
        TextSize = 11,  
        TextTransparency = 1,  
        Parent = LoadFrame,  
    })  

    local ltxt = new("TextLabel", {  
        Size = UDim2.new(1, 0, 0, 16),  
        Position = UDim2.new(0, 0, 0.62, 0),  
        BackgroundTransparency = 1,  
        Font = Enum.Font.GothamMedium,  
        Text = LoadText,  
        TextColor3 = T.TextDim,  
        TextSize = 12,  
        TextTransparency = 1,  
        Parent = LoadFrame,  
    })  

    local barBg = new("Frame", {  
        Size = UDim2.new(0, 280, 0, 4),  
        Position = UDim2.new(0.5, 0, 0.72, 0),  
        AnchorPoint = Vector2.new(0.5, 0),  
        BackgroundColor3 = T.Track,  
        BackgroundTransparency = 1,  
        BorderSizePixel = 0,  
        Parent = LoadFrame,  
    })  
    corner(barBg, 2)  

    local barFill = new("Frame", {  
        Size = UDim2.new(0, 0, 1, 0),  
        BackgroundColor3 = T.Accent,  
        BackgroundTransparency = 1,  
        BorderSizePixel = 0,  
        Parent = barBg,  
    })  
    corner(barFill, 2)  

    tween(logo, 0.5, {TextTransparency = 0})  
    task.delay(0.2, function() tween(ver, 0.4, {TextTransparency = 0}) end)  
    task.delay(0.4, function() tween(ltxt, 0.4, {TextTransparency = 0}) end)  
    task.delay(0.5, function()  
        tween(barBg, 0.3, {BackgroundTransparency = 0})  
        tween(barFill, 0.3, {BackgroundTransparency = 0})  
        tween(barFill, LoadDur - 0.7, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Quad)  
    end)  

    -- ============================================================================  
    -- MAIN WINDOW  
    -- ============================================================================  

    local Main = new("Frame", {  
        Name = "Main",  
        Size = UDim2.new(0, SX, 0, SY),  
        Position = UDim2.new(0.5, 0, 0.5, 0),  
        AnchorPoint = Vector2.new(0.5, 0.5),  
        BackgroundColor3 = T.Bg,  
        BorderSizePixel = 0,  
        Visible = false,  
        BackgroundTransparency = 1,  
        Parent = Gui,  
    })  
    corner(Main, 12)  
    stroke(Main, T.Border, 1, 0.5)  

    -- ============================================================================  
    -- TITLEBAR  
    -- ============================================================================  

    local TitleBar = new("Frame", {  
        Name = "TitleBar",  
        Size = UDim2.new(1, 0, 0, 40),  
        BackgroundColor3 = T.Sidebar,  
        BorderSizePixel = 0,  
        Parent = Main,  
    })  
    corner(TitleBar, 12)  

    local tbFill = new("Frame", {  
        Size = UDim2.new(1, 0, 0, 14),  
        Position = UDim2.new(0, 0, 1, -14),  
        BackgroundColor3 = T.Sidebar,  
        BorderSizePixel = 0,  
        Parent = TitleBar,  
    })  

    local tbDiv = new("Frame", {  
        Size = UDim2.new(1, 0, 0, 1),  
        Position = UDim2.new(0, 0, 1, -1),  
        BackgroundColor3 = T.Border,  
        BackgroundTransparency = 0.4,  
        BorderSizePixel = 0,  
        Parent = TitleBar,  
    })  

    local logoDot = new("Frame", {  
        Size = UDim2.new(0, 10, 0, 10),  
        Position = UDim2.new(0, 14, 0.5, 0),  
        AnchorPoint = Vector2.new(0, 0.5),  
        BackgroundColor3 = T.Accent,  
        BorderSizePixel = 0,  
        Parent = TitleBar,  
    })  
    corner(logoDot, 5)  

    local titleLbl = new("TextLabel", {  
        Size = UDim2.new(1, -120, 1, 0),  
        Position = UDim2.new(0, 30, 0, 0),  
        BackgroundTransparency = 1,  
        Font = Enum.Font.GothamBold,  
        Text = WinName,  
        TextColor3 = T.Text,  
        TextSize = 14,  
        TextXAlignment = Enum.TextXAlignment.Left,  
        Parent = TitleBar,  
    })  

    -- Кнопка минимизации  
    local minBtn = new("TextButton", {  
        Size = UDim2.new(0, 28, 0, 28),  
        Position = UDim2.new(1, -70, 0.5, 0),  
        AnchorPoint = Vector2.new(0, 0.5),  
        BackgroundColor3 = T.Elem,  
        BackgroundTransparency = 0.4,  
        Text = "—",  
        Font = Enum.Font.GothamBold,  
        TextSize = 14,  
        TextColor3 = T.TextDim,  
        AutoButtonColor = false,  
        Parent = TitleBar,  
    })  
    corner(minBtn, 6)  

    minBtn.MouseEnter:Connect(function()  
        tween(minBtn, 0.15, {BackgroundTransparency = 0.1, TextColor3 = T.Text})  
    end)  
    minBtn.MouseLeave:Connect(function()  
        tween(minBtn, 0.15, {BackgroundTransparency = 0.4, TextColor3 = T.TextDim})  
    end)  

    -- Кнопка закрытия  
    local closeBtn = new("TextButton", {  
        Size = UDim2.new(0, 28, 0, 28),  
        Position = UDim2.new(1, -36, 0.5, 0),  
        AnchorPoint = Vector2.new(0, 0.5),  
        BackgroundColor3 = T.Err,  
        BackgroundTransparency = 0.5,  
        Text = "×",  
        Font = Enum.Font.GothamBold,  
        TextSize = 16,  
        TextColor3 = T.Text,  
        AutoButtonColor = false,  
        Parent = TitleBar,  
    })  
    corner(closeBtn, 6)  

    closeBtn.MouseEnter:Connect(function()  
        tween(closeBtn, 0.15, {BackgroundTransparency = 0.1})  
    end)  
    closeBtn.MouseLeave:Connect(function()  
        tween(closeBtn, 0.15, {BackgroundTransparency = 0.5})  
    end)  

    -- ============================================================================  
    -- BODY  
    -- ============================================================================  

    local Body = new("Frame", {  
        Size = UDim2.new(1, 0, 1, -40),  
        Position = UDim2.new(0, 0, 0, 40),  
        BackgroundTransparency = 1,  
        Parent = Main,  
    })  

    local Sidebar = new("Frame", {  
        Size = UDim2.new(0, 150, 1, 0),  
        BackgroundColor3 = T.Sidebar,  
        BorderSizePixel = 0,  
        Parent = Body,  
    })  

    local sbDiv = new("Frame", {  
        Size = UDim2.new(0, 1, 1, 0),  
        Position = UDim2.new(1, 0, 0, 0),  
        BackgroundColor3 = T.Border,  
        BackgroundTransparency = 0.4,  
        BorderSizePixel = 0,  
        Parent = Sidebar,  
    })  

    local TabList = new("ScrollingFrame", {  
        Size = UDim2.new(1, 0, 1, -40),  
        Position = UDim2.new(0, 0, 0, 6),  
        BackgroundTransparency = 1,  
        BorderSizePixel = 0,  
        ScrollBarThickness = 2,  
        ScrollBarImageColor3 = T.Accent,  
        ScrollBarImageTransparency = 0.5,  
        CanvasSize = UDim2.new(0, 0, 0, 0),  
        AutomaticCanvasSize = Enum.AutomaticSize.Y,  
        ScrollingDirection = Enum.ScrollingDirection.Y,  
        Parent = Sidebar,  
    })  
    padding(TabList, 4, 4, 8, 8)  
    listLayout(TabList, 4)  

    local sbBottom = new("Frame", {  
        Size = UDim2.new(1, 0, 0, 34),  
        Position = UDim2.new(0, 0, 1, -34),  
        BackgroundTransparency = 1,  
        Parent = Sidebar,  
    })  

    new("Frame", {  
        Size = UDim2.new(1, -14, 0, 1),  
        Position = UDim2.new(0, 7, 0, 0),  
        BackgroundColor3 = T.Border,  
        BackgroundTransparency = 0.5,  
        BorderSizePixel = 0,  
        Parent = sbBottom,  
    })  

    new("TextLabel", {  
        Size = UDim2.new(1, 0, 1, -1),  
        Position = UDim2.new(0, 0, 0, 1),  
        BackgroundTransparency = 1,  
        Font = Enum.Font.Gotham,  
        Text = "Nolin-UI v2.0",  
        TextColor3 = T.TextMut,  
        TextSize = 10,  
        Parent = sbBottom,  
    })  

    local ContentArea = new("Frame", {  
        Size = UDim2.new(1, -150, 1, 0),  
        Position = UDim2.new(0, 150, 0, 0),  
        BackgroundColor3 = T.Bg,  
        BackgroundTransparency = 0.4,  
        BorderSizePixel = 0,  
        Parent = Body,  
    })  

    local Header = new("Frame", {  
        Size = UDim2.new(1, 0, 0, 36),  
        BackgroundTransparency = 1,  
        Parent = ContentArea,  
    })  

    local HeaderLbl = new("TextLabel", {  
        Size = UDim2.new(1, -24, 1, 0),  
        Position = UDim2.new(0, 14, 0, 0),  
        BackgroundTransparency = 1,  
        Font = Enum.Font.GothamBold,  
        Text = "",  
        TextColor3 = T.Text,  
        TextSize = 15,  
        TextXAlignment = Enum.TextXAlignment.Left,  
        Parent = Header,  
    })  

    new("Frame", {  
        Size = UDim2.new(1, -28, 0, 1),  
        Position = UDim2.new(0, 14, 1, -1),  
        BackgroundColor3 = T.Border,  
        BackgroundTransparency = 0.5,  
        BorderSizePixel = 0,  
        Parent = Header,  
    })  

    local Pages = new("Frame", {  
        Size = UDim2.new(1, 0, 1, -36),  
        Position = UDim2.new(0, 0, 0, 36),  
        BackgroundTransparency = 1,  
        ClipsDescendants = true,  
        Parent = ContentArea,  
    })  

    -- ============================================================================  
    -- DRAG (Rayfield-style)  
    -- ============================================================================  

    local dragging, dragStart, startPos = false, nil, nil  

    TitleBar.InputBegan:Connect(function(inp)  
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then  
            dragging = true  
            dragStart = inp.Position  
            startPos = Main.Position  
        end  
    end)  

    TitleBar.InputEnded:Connect(function(inp)  
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then  
            dragging = false  
        end  
    end)  

    addConn(UserInputService.InputChanged:Connect(function(inp)  
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then  
            local delta = inp.Position - dragStart  
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)  
        end  
    end))  

    -- ============================================================================  
    -- WINDOW OBJECT  
    -- ============================================================================  

    local Window = {}  
    Window.Tabs = {}  
    Window.CurTab = nil  
    Window.Visible = true  
    Window.ToggleKey = ToggleKey  
    Window._destroyed = false  

    -- Уведомления  
    local NotifBox = new("Frame", {  
        Name = "Notifs",  
        Size = UDim2.new(0, 300, 1, -20),  
        Position = UDim2.new(1, -310, 0, 10),  
        BackgroundTransparency = 1,  
        Parent = Gui,  
    })  
    local nfLay = listLayout(NotifBox, 8)  
    nfLay.HorizontalAlignment = Enum.HorizontalAlignment.Right  
    nfLay.VerticalAlignment = Enum.VerticalAlignment.Bottom  

    function Window:Notify(cfg)  
        cfg = cfg or {}  
        local title = cfg.Title or "Уведомление"  
        local content = cfg.Content or ""  
        local dur = cfg.Duration or 4  
        local ty = cfg.Type or "Info"  

        local ac = T.Accent  
        if ty == "Success" then ac = T.Ok  
        elseif ty == "Warning" then ac = T.Warn  
        elseif ty == "Error" then ac = T.Err end  

        local fr = new("Frame", {  
            Size = UDim2.new(1, 0, 0, 0),  
            AutomaticSize = Enum.AutomaticSize.Y,  
            BackgroundColor3 = T.BgAlt,  
            ClipsDescendants = true,  
            Parent = NotifBox,  
        })  
        corner(fr, 10)  
        stroke(fr, T.Border, 1, 0.5)  

        new("Frame", {  
            Size = UDim2.new(0, 3, 1, 0),  
            BackgroundColor3 = ac,  
            BorderSizePixel = 0,  
            Parent = fr,  
        })  

        local inner = new("Frame", {  
            Size = UDim2.new(1, -18, 0, 0),  
            Position = UDim2.new(0, 14, 0, 0),  
            AutomaticSize = Enum.AutomaticSize.Y,  
            BackgroundTransparency = 1,  
            Parent = fr,  
        })  
        padding(inner, 10, 10, 4, 4)  
        listLayout(inner, 3).HorizontalAlignment = Enum.HorizontalAlignment.Left  

        new("TextLabel", {  
            Size = UDim2.new(1, 0, 0, 0),  
            AutomaticSize = Enum.AutomaticSize.Y,  
            BackgroundTransparency = 1,  
            Font = Enum.Font.GothamBold,  
            Text = title,  
            TextColor3 = T.Text,  
            TextSize = 13,  
            TextXAlignment = Enum.TextXAlignment.Left,  
            TextWrapped = true,  
            Parent = inner,  
        })  

        if content ~= "" then  
            new("TextLabel", {  
                Size = UDim2.new(1, 0, 0, 0),  
                AutomaticSize = Enum.AutomaticSize.Y,  
                BackgroundTransparency = 1,  
                Font = Enum.Font.Gotham,  
                Text = content,  
                TextColor3 = T.TextDim,  
                TextSize = 11,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                TextWrapped = true,  
                Parent = inner,  
            })  
        end  

        local pbg = new("Frame", {  
            Size = UDim2.new(1, 0, 0, 2),  
            Position = UDim2.new(0, 0, 1, -2),  
            BackgroundColor3 = T.Track,  
            BorderSizePixel = 0,  
            Parent = fr,  
        })  
        local pf = new("Frame", {  
            Size = UDim2.new(1, 0, 1, 0),  
            BackgroundColor3 = ac,  
            BorderSizePixel = 0,  
            Parent = pbg,  
        })  

        fr.Position = UDim2.new(1, 40, 0, 0)  
        tween(fr, 0.4, {Position = UDim2.new(0, 0, 0, 0)})  

        tween(pf, dur, {Size = UDim2.new(0, 0, 1, 0)}, Enum.EasingStyle.Linear)  
        task.delay(dur, function()  
            tween(fr, 0.35, {Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1})  
            task.delay(0.4, function()  
                if fr and fr.Parent then fr:Destroy() end  
            end)  
        end)  
    end  

    -- Переключение видимости  
    function Window:Toggle()  
        if self._destroyed then return end  
        self.Visible = not self.Visible  
        if self.Visible then  
            Main.Visible = true  
            tween(Main, 0.3, {BackgroundTransparency = 0, Size = UDim2.new(0, SX, 0, SY)})  
        else  
            tween(Main, 0.25, {BackgroundTransparency = 1, Size = UDim2.new(0, SX * 0.95, 0, SY * 0.95)})  
            task.delay(0.28, function()  
                if not self.Visible and Main then Main.Visible = false end  
            end)  
        end  
    end  

    -- Уничтожение  
    function Window:Destroy()  
        if self._destroyed then return end  
        self._destroyed = true  
        tween(Main, 0.3, {BackgroundTransparency = 1, Size = UDim2.new(0, SX * 0.9, 0, SY * 0.9)})  
        task.delay(0.35, function()  
            for _, c in pairs(_G.NolinConns) do pcall(function() c:Disconnect() end) end  
            _G.NolinConns = {}  
            _G.NolinUILoaded = nil  
            pcall(function() Gui:Destroy() end)  
        end)  
    end  

    -- Клики на кнопки заголовка  
    minBtn.MouseButton1Click:Connect(function() Window:Toggle() end)  
    closeBtn.MouseButton1Click:Connect(function() Window:Destroy() end)  

    -- Переключение вкладок  
    function Window:_SwitchTab(tab)  
        if self.CurTab == tab then return end  
        if self.CurTab then  
            self.CurTab.Page.Visible = false  
            tween(self.CurTab.Btn, 0.2, {BackgroundColor3 = T.Elem, BackgroundTransparency = 0.5})  
            tween(self.CurTab.Lbl, 0.2, {TextColor3 = T.TextDim})  
            tween(self.CurTab.Indicator, 0.2, {Size = UDim2.new(0, 3, 0, 0)})  
        end  
        self.CurTab = tab  
        tab.Page.Visible = true  
        tween(tab.Btn, 0.2, {BackgroundColor3 = T.Accent, BackgroundTransparency = 0.85})  
        tween(tab.Lbl, 0.2, {TextColor3 = T.Text})  
        tween(tab.Indicator, 0.2, {Size = UDim2.new(0, 3, 0, 18)})  
        HeaderLbl.Text = tab.Name  
    end  

    -- ============================================================================  
    -- CREATE TAB  
    -- ============================================================================  

    function Window:CreateTab(tabCfg)  
        tabCfg = tabCfg or {}  
        local tabName = tabCfg.Name or "Tab"  

        local Tab = {}  
        Tab.Name = tabName  

        Tab.Btn = new("TextButton", {  
            Size = UDim2.new(1, -16, 0, 34),  
            BackgroundColor3 = T.Elem,  
            BackgroundTransparency = 0.5,  
            Text = "",  
            AutoButtonColor = false,  
            LayoutOrder = #Window.Tabs + 1,  
            Parent = TabList,  
        })  
        corner(Tab.Btn, 6)  

        Tab.Indicator = new("Frame", {  
            Size = UDim2.new(0, 3, 0, 0),  
            Position = UDim2.new(0, 0, 0.5, 0),  
            AnchorPoint = Vector2.new(0, 0.5),  
            BackgroundColor3 = T.Text,  
            BorderSizePixel = 0,  
            Parent = Tab.Btn,  
        })  
        corner(Tab.Indicator, 2)  

        Tab.Lbl = new("TextLabel", {  
            Size = UDim2.new(1, -20, 1, 0),  
            Position = UDim2.new(0, 12, 0, 0),  
            BackgroundTransparency = 1,  
            Font = Enum.Font.GothamMedium,  
            Text = tabName,  
            TextColor3 = T.TextDim,  
            TextSize = 13,  
            TextXAlignment = Enum.TextXAlignment.Left,  
            Parent = Tab.Btn,  
        })  

        Tab.Page = new("ScrollingFrame", {  
            Size = UDim2.new(1, 0, 1, 0),  
            BackgroundTransparency = 1,  
            BorderSizePixel = 0,  
            Visible = false,  
            ScrollBarThickness = 3,  
            ScrollBarImageColor3 = T.Accent,  
            ScrollBarImageTransparency = 0.5,  
            CanvasSize = UDim2.new(0, 0, 0, 0),  
            AutomaticCanvasSize = Enum.AutomaticSize.Y,  
            ScrollingDirection = Enum.ScrollingDirection.Y,  
            Parent = Pages,  
        })  
        padding(Tab.Page, 12, 12, 14, 14)  
        listLayout(Tab.Page, 8)  

        Tab.Btn.MouseEnter:Connect(function()  
            if Window.CurTab ~= Tab then  
                tween(Tab.Btn, 0.15, {BackgroundColor3 = T.ElemHov, BackgroundTransparency = 0.2})  
                tween(Tab.Lbl, 0.15, {TextColor3 = T.Text})  
            end  
        end)  
        Tab.Btn.MouseLeave:Connect(function()  
            if Window.CurTab ~= Tab then  
                tween(Tab.Btn, 0.15, {BackgroundColor3 = T.Elem, BackgroundTransparency = 0.5})  
                tween(Tab.Lbl, 0.15, {TextColor3 = T.TextDim})  
            end  
        end)  

        Tab.Btn.MouseButton1Click:Connect(function()  
            Window:_SwitchTab(Tab)  
        end)  

        table.insert(Window.Tabs, Tab)  

        -- ============================================================================  
        -- CREATE SECTION  
        -- ============================================================================  

        function Tab:CreateSection(secCfg)  
            local nm = (secCfg and secCfg.Name) or "Section"  
            local fr = new("Frame", {  
                Size = UDim2.new(1, 0, 0, 28),  
                BackgroundTransparency = 1,  
                Parent = Tab.Page,  
            })  
            new("Frame", {  
                Size = UDim2.new(1, 0, 0, 1),  
                BackgroundColor3 = T.Border,  
                BackgroundTransparency = 0.5,  
                BorderSizePixel = 0,  
                Parent = fr,  
            })  
            new("TextLabel", {  
                Size = UDim2.new(1, 0, 0, 18),  
                Position = UDim2.new(0, 0, 0, 8),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamSemibold,  
                Text = string.upper(nm),  
                TextColor3 = T.TextMut,  
                TextSize = 10,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  
            return fr  
        end  

        -- ============================================================================  
        -- CREATE LABEL  
        -- ============================================================================  

        function Tab:CreateLabel(lblCfg)  
            local nm = (lblCfg and lblCfg.Name) or "Label"  
            local fr = new("Frame", {  
                Size = UDim2.new(1, 0, 0, 34),  
                BackgroundColor3 = T.Elem,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            stroke(fr, T.Border, 1, 0.6)  
            local lb = new("TextLabel", {  
                Size = UDim2.new(1, -20, 1, 0),  
                Position = UDim2.new(0, 12, 0, 0),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamMedium,  
                Text = nm,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  
            local o = {}  
            function o:Set(t) lb.Text = t end  
            return o  
        end  

        -- ============================================================================  
        -- CREATE PARAGRAPH  
        -- ============================================================================  

        function Tab:CreateParagraph(pCfg)  
            local tt = (pCfg and pCfg.Title) or "Title"  
            local ct = (pCfg and pCfg.Content) or ""  
            local fr = new("Frame", {  
                Size = UDim2.new(1, 0, 0, 0),  
                AutomaticSize = Enum.AutomaticSize.Y,  
                BackgroundColor3 = T.Elem,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            stroke(fr, T.Border, 1, 0.6)  
            padding(fr, 10, 10, 12, 12)  
            listLayout(fr, 4).HorizontalAlignment = Enum.HorizontalAlignment.Left  

            local ttl = new("TextLabel", {  
                Size = UDim2.new(1, 0, 0, 0),  
                AutomaticSize = Enum.AutomaticSize.Y,  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamBold,  
                Text = tt,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                TextWrapped = true,  
                Parent = fr,  
            })  
            local cnt = new("TextLabel", {  
                Size = UDim2.new(1, 0, 0, 0),  
                AutomaticSize = Enum.AutomaticSize.Y,  
                BackgroundTransparency = 1,  
                Font = Enum.Font.Gotham,  
                Text = ct,  
                TextColor3 = T.TextDim,  
                TextSize = 12,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                TextWrapped = true,  
                Parent = fr,  
            })  
            local o = {}  
            function o:Set(nc)  
                if nc.Title then ttl.Text = nc.Title end  
                if nc.Content then cnt.Text = nc.Content end  
            end  
            return o  
        end  

        -- ============================================================================  
        -- CREATE BUTTON  
        -- ============================================================================  

        function Tab:CreateButton(btnCfg)  
            btnCfg = btnCfg or {}  
            local nm = btnCfg.Name or "Button"  
            local desc = btnCfg.Description  
            local cb = btnCfg.Callback or function() end  
            local h = desc and 48 or 36  

            local fr = new("TextButton", {  
                Size = UDim2.new(1, 0, 0, h),  
                BackgroundColor3 = T.Elem,  
                Text = "",  
                AutoButtonColor = false,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            local st = stroke(fr, T.Border, 1, 0.6)  

            local lb = new("TextLabel", {  
                Size = UDim2.new(1, -50, 0, 16),  
                Position = UDim2.new(0, 12, 0, desc and 6 or 10),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamSemibold,  
                Text = nm,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  

            if desc then  
                new("TextLabel", {  
                    Size = UDim2.new(1, -50, 0, 14),  
                    Position = UDim2.new(0, 12, 0, 26),  
                    BackgroundTransparency = 1,  
                    Font = Enum.Font.Gotham,  
                    Text = desc,  
                    TextColor3 = T.TextMut,  
                    TextSize = 11,  
                    TextXAlignment = Enum.TextXAlignment.Left,  
                    Parent = fr,  
                })  
            end  

            local ar = new("TextLabel", {  
                Size = UDim2.new(0, 16, 0, 16),  
                Position = UDim2.new(1, -26, 0.5, 0),  
                AnchorPoint = Vector2.new(0, 0.5),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamBold,  
                Text = "›",  
                TextColor3 = T.TextMut,  
                TextSize = 18,  
                Parent = fr,  
            })  

            fr.MouseEnter:Connect(function()  
                tween(fr, 0.15, {BackgroundColor3 = T.ElemHov})  
                tween(st, 0.15, {Color = T.Accent, Transparency = 0.3})  
                tween(ar, 0.15, {TextColor3 = T.Accent, Position = UDim2.new(1, -22, 0.5, 0)})  
            end)  
            fr.MouseLeave:Connect(function()  
                tween(fr, 0.15, {BackgroundColor3 = T.Elem})  
                tween(st, 0.15, {Color = T.Border, Transparency = 0.6})  
                tween(ar, 0.15, {TextColor3 = T.TextMut, Position = UDim2.new(1, -26, 0.5, 0)})  
            end)  

            fr.MouseButton1Click:Connect(function()  
                tween(fr, 0.08, {BackgroundColor3 = T.AccentDim})  
                task.delay(0.1, function()  
                    tween(fr, 0.15, {BackgroundColor3 = T.ElemHov})  
                end)  
                task.spawn(cb)  
            end)  

            local o = {}  
            function o:SetText(t) lb.Text = t end  
            return o  
        end  

        -- ============================================================================  
        -- CREATE TOGGLE  
        -- ============================================================================  

        function Tab:CreateToggle(tCfg)  
            tCfg = tCfg or {}  
            local nm = tCfg.Name or "Toggle"  
            local desc = tCfg.Description  
            local def = tCfg.Default or false  
            local cb = tCfg.Callback or function() end  
            local state = def  
            local h = desc and 48 or 36  

            local fr = new("TextButton", {  
                Size = UDim2.new(1, 0, 0, h),  
                BackgroundColor3 = T.Elem,  
                Text = "",  
                AutoButtonColor = false,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            stroke(fr, T.Border, 1, 0.6)  

            new("TextLabel", {  
                Size = UDim2.new(1, -60, 0, 16),  
                Position = UDim2.new(0, 12, 0, desc and 6 or 10),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamSemibold,  
                Text = nm,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  

            if desc then  
                new("TextLabel", {  
                    Size = UDim2.new(1, -60, 0, 14),  
                    Position = UDim2.new(0, 12, 0, 26),  
                    BackgroundTransparency = 1,  
                    Font = Enum.Font.Gotham,  
                    Text = desc,  
                    TextColor3 = T.TextMut,  
                    TextSize = 11,  
                    TextXAlignment = Enum.TextXAlignment.Left,  
                    Parent = fr,  
                })  
            end  

            local track = new("Frame", {  
                Size = UDim2.new(0, 40, 0, 20),  
                Position = UDim2.new(1, -50, 0.5, 0),  
                AnchorPoint = Vector2.new(0, 0.5),  
                BackgroundColor3 = state and T.Accent or T.Off,  
                Parent = fr,  
            })  
            corner(track, 10)  

            local knob = new("Frame", {  
                Size = UDim2.new(0, 14, 0, 14),  
                Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),  
                AnchorPoint = Vector2.new(0, 0.5),  
                BackgroundColor3 = T.Text,  
                Parent = track,  
            })  
            corner(knob, 7)  

            local function upd()  
                if state then  
                    tween(track, 0.2, {BackgroundColor3 = T.Accent})  
                    tween(knob, 0.2, {Position = UDim2.new(1, -17, 0.5, 0)})  
                else  
                    tween(track, 0.2, {BackgroundColor3 = T.Off})  
                    tween(knob, 0.2, {Position = UDim2.new(0, 3, 0.5, 0)})  
                end  
            end  

            fr.MouseEnter:Connect(function() tween(fr, 0.15, {BackgroundColor3 = T.ElemHov}) end)  
            fr.MouseLeave:Connect(function() tween(fr, 0.15, {BackgroundColor3 = T.Elem}) end)  
            fr.MouseButton1Click:Connect(function()  
                state = not state  
                upd()  
                task.spawn(function() cb(state) end)  
            end)  

            if def then task.spawn(function() cb(true) end) end  

            local o = {}  
            function o:Set(v) state = v upd() task.spawn(function() cb(state) end) end  
            function o:Get() return state end  
            return o  
        end  

        -- ============================================================================  
        -- CREATE SLIDER  
        -- ============================================================================  

        function Tab:CreateSlider(sCfg)  
            sCfg = sCfg or {}  
            local nm = sCfg.Name or "Slider"  
            local desc = sCfg.Description  
            local mn = sCfg.Min or 0  
            local mx = sCfg.Max or 100  
            local def = sCfg.Default or mn  
            local inc = sCfg.Increment or 1  
            local suf = sCfg.Suffix or ""  
            local cb = sCfg.Callback or function() end  

            local cur = math.clamp(def, mn, mx)  
            local h = desc and 66 or 54  

            local fr = new("Frame", {  
                Size = UDim2.new(1, 0, 0, h),  
                BackgroundColor3 = T.Elem,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            stroke(fr, T.Border, 1, 0.6)  

            new("TextLabel", {  
                Size = UDim2.new(0.6, -12, 0, 16),  
                Position = UDim2.new(0, 12, 0, desc and 6 or 6),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamSemibold,  
                Text = nm,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  

            local valLbl = new("TextLabel", {  
                Size = UDim2.new(0.4, -12, 0, 16),  
                Position = UDim2.new(0.6, 0, 0, desc and 6 or 6),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamMedium,  
                Text = tostring(cur) .. suf,  
                TextColor3 = T.Accent,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Right,  
                Parent = fr,  
            })  

            if desc then  
                new("TextLabel", {  
                    Size = UDim2.new(1, -24, 0, 14),  
                    Position = UDim2.new(0, 12, 0, 24),  
                    BackgroundTransparency = 1,  
                    Font = Enum.Font.Gotham,  
                    Text = desc,  
                    TextColor3 = T.TextMut,  
                    TextSize = 11,  
                    TextXAlignment = Enum.TextXAlignment.Left,  
                    Parent = fr,  
                })  
            end  

            local trY = desc and 46 or 32  

            local track = new("Frame", {  
                Size = UDim2.new(1, -24, 0, 6),  
                Position = UDim2.new(0, 12, 0, trY),  
                BackgroundColor3 = T.Track,  
                BorderSizePixel = 0,  
                Parent = fr,  
            })  
            corner(track, 3)  

            local pctInit = (cur - mn) / math.max(mx - mn, 0.001)  

            local fill = new("Frame", {  
                Size = UDim2.new(pctInit, 0, 1, 0),  
                BackgroundColor3 = T.Accent,  
                BorderSizePixel = 0,  
                Parent = track,  
            })  
            corner(fill, 3)  

            local hitbox = new("TextButton", {  
                Size = UDim2.new(1, 20, 0, 24),  
                Position = UDim2.new(0, -10, 0.5, 0),  
                AnchorPoint = Vector2.new(0, 0.5),  
                BackgroundTransparency = 1,  
                Text = "",  
                AutoButtonColor = false,  
                Parent = track,  
            })  

            local knob = new("Frame", {  
                Size = UDim2.new(0, 14, 0, 14),  
                Position = UDim2.new(pctInit, 0, 0.5, 0),  
                AnchorPoint = Vector2.new(0.5, 0.5),  
                BackgroundColor3 = T.Text,  
                BorderSizePixel = 0,  
                ZIndex = 5,  
                Parent = track,  
            })  
            corner(knob, 7)  

            local dragging = false  

            local function updateFromMouse(mouseX)  
                local trkPos = track.AbsolutePosition.X  
                local trkSize = track.AbsoluteSize.X  
                if trkSize <= 0 then return end  

                local rel = math.clamp((mouseX - trkPos) / trkSize, 0, 1)  
                local rawVal = mn + (mx - mn) * rel  
                local stepped = math.floor(rawVal / inc + 0.5) * inc  
                stepped = math.clamp(stepped, mn, mx)  

                if stepped ~= cur then  
                    cur = stepped  
                    local newPct = (cur - mn) / math.max(mx - mn, 0.001)  
                    fill.Size = UDim2.new(newPct, 0, 1, 0)  
                    knob.Position = UDim2.new(newPct, 0, 0.5, 0)  
                    valLbl.Text = tostring(cur) .. suf  
                    task.spawn(function() cb(cur) end)  
                end  
            end  

            hitbox.MouseButton1Down:Connect(function()  
                dragging = true  
                tween(knob, 0.1, {Size = UDim2.new(0, 18, 0, 18)})  
                updateFromMouse(UserInputService:GetMouseLocation().X)  
            end)  

            addConn(UserInputService.InputChanged:Connect(function(inp)  
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then  
                    updateFromMouse(inp.Position.X)  
                elseif dragging and inp.UserInputType == Enum.UserInputType.Touch then  
                    updateFromMouse(inp.Position.X)  
                end  
            end))  

            addConn(UserInputService.InputEnded:Connect(function(inp)  
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then  
                    dragging = false  
                    tween(knob, 0.15, {Size = UDim2.new(0, 14, 0, 14)})  
                end  
            end))  

            fr.MouseEnter:Connect(function() tween(fr, 0.15, {BackgroundColor3 = T.ElemHov}) end)  
            fr.MouseLeave:Connect(function()  
                if not dragging then tween(fr, 0.15, {BackgroundColor3 = T.Elem}) end  
            end)  

            task.spawn(function() cb(cur) end)  

            local o = {}  
            function o:Set(v)  
                cur = math.clamp(v, mn, mx)  
                local p = (cur - mn) / math.max(mx - mn, 0.001)  
                tween(fill, 0.2, {Size = UDim2.new(p, 0, 1, 0)})  
                tween(knob, 0.2, {Position = UDim2.new(p, 0, 0.5, 0)})  
                valLbl.Text = tostring(cur) .. suf  
                task.spawn(function() cb(cur) end)  
            end  
            function o:Get() return cur end  
            return o  
        end  

        -- ============================================================================  
        -- CREATE DROPDOWN  
        -- ============================================================================  

        function Tab:CreateDropdown(dCfg)  
            dCfg = dCfg or {}  
            local nm = dCfg.Name or "Dropdown"  
            local desc = dCfg.Description  
            local opts = dCfg.Options or {}  
            local def = dCfg.Default  
            local multi = dCfg.MultiSelect or false  
            local cb = dCfg.Callback or function() end  

            local open = false  
            local sel = {}  
            local curSel = def  
            local hH = desc and 48 or 36  
            local oBtns = {}  

            if multi and type(def) == "table" then  
                for _, v in ipairs(def) do sel[v] = true end  
            end  

            local fr = new("Frame", {  
                Size = UDim2.new(1, 0, 0, hH),  
                BackgroundColor3 = T.Elem,  
                ClipsDescendants = true,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            local strk = stroke(fr, T.Border, 1, 0.6)  

            new("TextLabel", {  
                Size = UDim2.new(0.5, -12, 0, 16),  
                Position = UDim2.new(0, 12, 0, desc and 6 or 10),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamSemibold,  
                Text = nm,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  

            if desc then  
                new("TextLabel", {  
                    Size = UDim2.new(1, -65, 0, 14),  
                    Position = UDim2.new(0, 12, 0, 26),  
                    BackgroundTransparency = 1,  
                    Font = Enum.Font.Gotham,  
                    Text = desc,  
                    TextColor3 = T.TextMut,  
                    TextSize = 11,  
                    TextXAlignment = Enum.TextXAlignment.Left,  
                    Parent = fr,  
                })  
            end  

            local function getSelText()  
                if multi then  
                    local r = {}  
                    for k, v in pairs(sel) do if v then table.insert(r, k) end end  
                    return #r > 0 and table.concat(r, ", ") or "Выбрать..."  
                end  
                return curSel or "Выбрать..."  
            end  

            local selLbl = new("TextLabel", {  
                Size = UDim2.new(0.5, -30, 0, 16),  
                Position = UDim2.new(0.5, 0, 0, desc and 6 or 10),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamMedium,  
                Text = getSelText(),  
                TextColor3 = T.TextDim,  
                TextSize = 12,  
                TextXAlignment = Enum.TextXAlignment.Right,  
                TextTruncate = Enum.TextTruncate.AtEnd,  
                Parent = fr,  
            })  

            local arw = new("TextLabel", {  
                Size = UDim2.new(0, 14, 0, 14),  
                Position = UDim2.new(1, -22, 0, desc and 8 or 12),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamBold,  
                Text = "▾",  
                TextColor3 = T.TextMut,  
                TextSize = 12,  
                Rotation = 0,  
                Parent = fr,  
            })  

            local optBox = new("Frame", {  
                Size = UDim2.new(1, -16, 0, 0),  
                AutomaticSize = Enum.AutomaticSize.Y,  
                Position = UDim2.new(0, 8, 0, hH + 4),  
                BackgroundColor3 = T.BgAlt,  
                Parent = fr,  
            })  
            corner(optBox, 5)  
            padding(optBox, 4, 4, 4, 4)  
            listLayout(optBox, 2)  

            local function mkOpt(txt)  
                local isS = multi and sel[txt] or (not multi and curSel == txt)  

                local ob = new("TextButton", {  
                    Name = "Op" .. txt,  
                    Size = UDim2.new(1, 0, 0, 26),  
                    BackgroundColor3 = isS and T.Accent or Color3.new(0, 0, 0),  
                    BackgroundTransparency = isS and 0.75 or 1,  
                    Font = Enum.Font.GothamMedium,  
                    Text = txt,  
                    TextColor3 = isS and T.Text or T.TextDim,  
                    TextSize = 12,  
                    AutoButtonColor = false,  
                    Parent = optBox,  
                })  
                corner(ob, 4)  

                ob.MouseEnter:Connect(function()  
                    local s2 = multi and sel[txt] or (not multi and curSel == txt)  
                    if not s2 then tween(ob, 0.1, {BackgroundColor3 = T.ElemHov, BackgroundTransparency = 0.3, TextColor3 = T.Text}) end  
                end)  
                ob.MouseLeave:Connect(function()  
                    local s2 = multi and sel[txt] or (not multi and curSel == txt)  
                    if not s2 then tween(ob, 0.1, {BackgroundTransparency = 1, TextColor3 = T.TextDim}) end  
                end)  

                ob.MouseButton1Click:Connect(function()  
                    if multi then  
                        sel[txt] = not sel[txt]  
                        if sel[txt] then  
                            tween(ob, 0.1, {BackgroundColor3 = T.Accent, BackgroundTransparency = 0.75, TextColor3 = T.Text})  
                        else  
                            tween(ob, 0.1, {BackgroundTransparency = 1, TextColor3 = T.TextDim})  
                        end  
                        selLbl.Text = getSelText()  
                        local r = {}  
                        for k, v in pairs(sel) do if v then table.insert(r, k) end end  
                        task.spawn(function() cb(r) end)  
                    else  
                        curSel = txt  
                        for _, b in ipairs(oBtns) do  
                            local bn = string.gsub(b.Name, "Op", "")  
                            if bn == txt then  
                                tween(b, 0.1, {BackgroundColor3 = T.Accent, BackgroundTransparency = 0.75, TextColor3 = T.Text})  
                            else  
                                tween(b, 0.1, {BackgroundTransparency = 1, TextColor3 = T.TextDim})  
                            end  
                        end  
                        selLbl.Text = txt  
                        task.spawn(function() cb(txt) end)  
                        task.delay(0.15, function()  
                            open = false  
                            tween(fr, 0.25, {Size = UDim2.new(1, 0, 0, hH)})  
                            tween(arw, 0.25, {Rotation = 0})  
                            tween(strk, 0.25, {Color = T.Border, Transparency = 0.6})  
                        end)  
                    end  
                end)  

                table.insert(oBtns, ob)  
            end  

            for _, o in ipairs(opts) do mkOpt(o) end  

            local hdrBtn = new("TextButton", {  
                Size = UDim2.new(1, 0, 0, hH),  
                BackgroundTransparency = 1,  
                Text = "",  
                AutoButtonColor = false,  
                ZIndex = 3,  
                Parent = fr,  
            })  

            hdrBtn.MouseEnter:Connect(function() tween(fr, 0.15, {BackgroundColor3 = T.ElemHov}) end)  
            hdrBtn.MouseLeave:Connect(function() tween(fr, 0.15, {BackgroundColor3 = T.Elem}) end)  
            hdrBtn.MouseButton1Click:Connect(function()  
                open = not open  
                if open then  
                    local totalH = #opts * 28 + 12  
                    tween(fr, 0.25, {Size = UDim2.new(1, 0, 0, hH + totalH + 12)})  
                    tween(arw, 0.25, {Rotation = 180})  
                    tween(strk, 0.25, {Color = T.Accent, Transparency = 0.3})  
                else  
                    tween(fr, 0.25, {Size = UDim2.new(1, 0, 0, hH)})  
                    tween(arw, 0.25, {Rotation = 0})  
                    tween(strk, 0.25, {Color = T.Border, Transparency = 0.6})  
                end  
            end)  

            local o = {}  
            function o:Set(v)  
                if multi and type(v) == "table" then  
                    sel = {}  
                    for _, val in ipairs(v) do sel[val] = true end  
                    selLbl.Text = getSelText()  
                elseif not multi then  
                    curSel = v  
                    selLbl.Text = v  
                end  
            end  
            function o:Get()  
                if multi then  
                    local r = {}  
                    for k, v in pairs(sel) do if v then table.insert(r, k) end end  
                    return r  
                end  
                return curSel  
            end  
            return o  
        end  

        -- ============================================================================  
        -- CREATE TEXTBOX  
        -- ============================================================================  

        function Tab:CreateTextBox(tbCfg)  
            tbCfg = tbCfg or {}  
            local nm = tbCfg.Name or "Input"  
            local ph = tbCfg.PlaceholderText or "Введите..."  
            local def = tbCfg.Default or ""  
            local clr = tbCfg.ClearOnFocus or false  
            local cb = tbCfg.Callback or function() end  

            local fr = new("Frame", {  
                Size = UDim2.new(1, 0, 0, 40),  
                BackgroundColor3 = T.Elem,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            stroke(fr, T.Border, 1, 0.6)  

            new("TextLabel", {  
                Size = UDim2.new(0.45, -12, 1, 0),  
                Position = UDim2.new(0, 12, 0, 0),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamSemibold,  
                Text = nm,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  

            local ibg = new("Frame", {  
                Size = UDim2.new(0.5, -12, 0, 26),  
                Position = UDim2.new(0.5, 0, 0.5, 0),  
                AnchorPoint = Vector2.new(0, 0.5),  
                BackgroundColor3 = T.BgAlt,  
                Parent = fr,  
            })  
            corner(ibg, 4)  
            local ist = stroke(ibg, T.Border, 1, 0.5)  

            local tb = new("TextBox", {  
                Size = UDim2.new(1, -12, 1, 0),  
                Position = UDim2.new(0, 6, 0, 0),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.Gotham,  
                Text = def,  
                PlaceholderText = ph,  
                PlaceholderColor3 = T.TextMut,  
                TextColor3 = T.Text,  
                TextSize = 12,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                ClearTextOnFocus = clr,  
                ClipsDescendants = true,  
                Parent = ibg,  
            })  

            tb.Focused:Connect(function() tween(ist, 0.15, {Color = T.Accent, Transparency = 0.2}) end)  
            tb.FocusLost:Connect(function(enter)  
                tween(ist, 0.15, {Color = T.Border, Transparency = 0.5})  
                if enter then task.spawn(function() cb(tb.Text) end) end  
            end)  

            local o = {}  
            function o:Set(t) tb.Text = t end  
            function o:Get() return tb.Text end  
            return o  
        end  

        -- ============================================================================  
        -- CREATE KEYBIND  
        -- ============================================================================  

        function Tab:CreateKeybind(kCfg)  
            kCfg = kCfg or {}  
            local nm = kCfg.Name or "Keybind"  
            local def = kCfg.Default or Enum.KeyCode.Unknown  
            local cb = kCfg.Callback or function() end  
            local chg = kCfg.ChangedCallback or function() end  

            local curK = def  
            local listen = false  

            local fr = new("Frame", {  
                Size = UDim2.new(1, 0, 0, 36),  
                BackgroundColor3 = T.Elem,  
                Parent = Tab.Page,  
            })  
            corner(fr, 6)  
            stroke(fr, T.Border, 1, 0.6)  

            new("TextLabel", {  
                Size = UDim2.new(0.6, -12, 1, 0),  
                Position = UDim2.new(0, 12, 0, 0),  
                BackgroundTransparency = 1,  
                Font = Enum.Font.GothamSemibold,  
                Text = nm,  
                TextColor3 = T.Text,  
                TextSize = 13,  
                TextXAlignment = Enum.TextXAlignment.Left,  
                Parent = fr,  
            })  

            local kbtn = new("TextButton", {  
                Size = UDim2.new(0, 70, 0, 24),  
                Position = UDim2.new(1, -82, 0.5, 0),  
                AnchorPoint = Vector2.new(0, 0.5),  
                BackgroundColor3 = T.BgAlt,  
                Font = Enum.Font.GothamMedium,  
                Text = (curK == Enum.KeyCode.Unknown) and "None" or curK.Name,  
                TextColor3 = T.TextDim,  
                TextSize = 12,  
                AutoButtonColor = false,  
                Parent = fr,  
            })  
            corner(kbtn, 4)  
            local ks = stroke(kbtn, T.Border, 1, 0.4)  

            kbtn.MouseButton1Click:Connect(function()  
                if listen then return end  
                listen = true  
                kbtn.Text = "..."  
                tween(ks, 0.15, {Color = T.Accent, Transparency = 0.2})  
                tween(kbtn, 0.15, {TextColor3 = T.Accent})  

                local c  
                c = UserInputService.InputBegan:Connect(function(inp)  
                    if inp.UserInputType == Enum.UserInputType.Keyboard then  
                        if inp.KeyCode == Enum.KeyCode.Escape then  
                            curK = Enum.KeyCode.Unknown  
                            kbtn.Text = "None"  
                        else  
                            curK = inp.KeyCode  
                            kbtn.Text = curK.Name  
                        end  
                        tween(ks, 0.15, {Color = T.Border, Transparency = 0.4})  
                        tween(kbtn, 0.15, {TextColor3 = T.TextDim})  
                        listen = false  
                        c:Disconnect()  
                        task.spawn(function() chg(curK) end)  
                    end  
                end)  
            end)  

            addConn(UserInputService.InputBegan:Connect(function(inp, gp)  
                if gp or listen then return end  
                if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == curK and curK ~= Enum.KeyCode.Unknown then  
                    task.spawn(function() cb(curK) end)  
                end  
            end))  

            local o = {}  
            function o:Set(k) curK = k kbtn.Text = k == Enum.KeyCode.Unknown and "None" or k.Name task.spawn(function() chg(curK) end) end  
            function o:Get() return curK end  
            return o  
        end  

        return Tab  
    end  

    -- ============================================================================  
    -- ЗАВЕРШЕНИЕ ЗАГРУЗКИ  
    -- ============================================================================  

    task.delay(LoadDur, function()  
        for _, ch in ipairs(LoadFrame:GetDescendants()) do  
            pcall(function()  
                if ch:IsA("TextLabel") then tween(ch, 0.3, {TextTransparency = 1}) end  
                if ch:IsA("Frame") then tween(ch, 0.3, {BackgroundTransparency = 1}) end  
            end)  
        end  
        tween(LoadFrame, 0.4, {BackgroundTransparency = 1})  

        task.delay(0.45, function()  
            if LoadFrame then LoadFrame:Destroy() end  

            Main.Visible = true  
            Main.Size = UDim2.new(0, SX * 0.95, 0, SY * 0.95)  
            tween(Main, 0.4, {BackgroundTransparency = 0, Size = UDim2.new(0, SX, 0, SY)}, Enum.EasingStyle.Back)  

            if #Window.Tabs > 0 then  
                Window:_SwitchTab(Window.Tabs[1])  
            end  

            Window:Notify({  
                Title = WinName,  
                Content = "Загрузка завершена! " .. ToggleKey.Name .. " для скрытия.",  
                Duration = 4,  
                Type = "Success",  
            })  
        end)  
    end)  

    -- Toggle клавиша  
    addConn(UserInputService.InputBegan:Connect(function(inp, gp)  
        if gp then return end  
        if inp.KeyCode == Window.ToggleKey then  
            Window:Toggle()  
        end  
    end))  

    -- Встроенная вкладка настроек  
    if config.IncludeSettings ~= false then  
        task.delay(0.05, function()  
            local st = Window:CreateTab({Name = "Настройки"})  

            st:CreateSection({Name = "О программе"})  
            st:CreateParagraph({  
                Title = "Nolin-UI v2.0",  
                Content = "Профессиональная UI-библиотека для Roblox.\nПереработана на основе Rayfield UI.",  
            })  

            st:CreateSection({Name = "Управление"})  
            st:CreateKeybind({  
                Name = "Клавиша скрытия",  
                Default = Window.ToggleKey,  
                ChangedCallback = function(k)  
                    Window.ToggleKey = k  
                    Window:Notify({Title = "Настройки", Content = "Клавиша: " .. k.Name, Duration = 3, Type = "Info"})  
                end,  
            })  

            st:CreateSection({Name = "Ссылки"})  
            st:CreateButton({  
                Name = "Скопировать Discord",  
                Description = Discord,  
                Callback = function()  
                    local ok = pcall(function()  
                        if setclipboard then setclipboard(Discord)  
                        elseif toclipboard then toclipboard(Discord) end  
                    end)  
                    Window:Notify({  
                        Title = "Discord",  
                        Content = ok and "Скопировано!" or "Ошибка копирования",  
                        Duration = 3,  
                        Type = ok and "Success" or "Warning",  
                    })  
                end,  
            })  

            st:CreateSection({Name = "Выход"})  
            st:CreateButton({  
                Name = "Закрыть интерфейс",  
                Description = "Полностью удалить UI",  
                Callback = function()  
                    Window:Notify({Title = "До свидания", Content = "Закрытие через 1.5 сек...", Duration = 1.5, Type = "Warning"})  
                    task.delay(1.5, function() Window:Destroy() end)  
                end,  
            })  
        end)  
    end  

    return Window  
end  

return NolinUI
