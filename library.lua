-- Modern Roblox UI Library - Rayfield-inspired API (2026 edition)
-- Features: Window + Tabs + Toggle + Slider + Dropdown + Keybind + Button + Paragraph + Label + Notification + Configuration Saving
-- Clean, smooth animations, mobile-friendly-ish, easy to extend

local Library = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ────────────────────────────────────────────────────────────────
-- Theme & Constants
-- ────────────────────────────────────────────────────────────────

local Theme = {
    Accent      = Color3.fromRGB(80, 160, 255),
    Background  = Color3.fromRGB(18, 18, 22),
    Secondary   = Color3.fromRGB(30, 30, 38),
    Tertiary    = Color3.fromRGB(45, 45, 55),
    Text        = Color3.fromRGB(240, 240, 245),
    TextDim     = Color3.fromRGB(150, 150, 170),
    Border      = Color3.fromRGB(60, 60, 75),
    Corner      = 8,
    Stroke      = 1.2,
}

local TweenQuick   = TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TweenMedium  = TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local function Tween(obj, props, ti) TweenService:Create(obj, ti or TweenQuick, props):Play() end

local function Create(class, props, parent)
    local inst = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function Round(inst, r) Create("UICorner", {CornerRadius = UDim.new(0, r or Theme.Corner)}, inst) end
local function Stroke(inst, col, thick) Create("UIStroke", {Color = col or Theme.Border, Thickness = thick or Theme.Stroke, Transparency = 0.35}, inst) end
local function Pad(inst, l,r,t,b) Create("UIPadding", {PaddingLeft=UDim.new(0,l or 8), PaddingRight=UDim.new(0,r or 8), PaddingTop=UDim.new(0,t or 6), PaddingBottom=UDim.new(0,b or 6)}, inst) end

-- ────────────────────────────────────────────────────────────────
-- Core Library
-- ────────────────────────────────────────────────────────────────

local Windows = {}

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local win = {}
    setmetatable(win, {__index = Library})

    win.Name = cfg.Name or "Window"
    win.Icon = cfg.Icon or 0
    win.LoadingTitle = cfg.LoadingTitle or "Loading"
    win.LoadingSubtitle = cfg.LoadingSubtitle or "Please wait..."
    win.Theme = cfg.Theme or "Default"
    win.ConfigSaving = cfg.ConfigurationSaving or {Enabled = false}
    win.Discord = cfg.Discord or {Enabled = false}
    win.KeySystem = cfg.KeySystem or false
    -- ... (key system stub - expand later if needed)

    win.Tabs = {}
    win.CurrentTab = nil
    win.Flags = {}           -- for config saving
    win.Connections = {}

    win:Build()

    table.insert(Windows, win)
    return win
end

function Library:Build()
    local sg = Create("ScreenGui", {
        Name = "RayfieldLikeUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = PlayerGui
    })
    self.Gui = sg

    local main = Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 620, 0, 380),
        Position = UDim2.new(0.5, -310, 0.5, -190),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = sg
    })
    Round(main)
    Stroke(main, Color3.new(1,1,1), 1.4)

    self.Main = main

    -- Header / Title bar
    local header = Create("Frame", {
        Size = UDim2.new(1,0,0,42),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = main
    })
    Round(header)

    Create("Frame", {Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = header})

    Create("TextLabel", {
        Size = UDim2.new(1,-50,1,0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
        TextSize = 19,
        TextColor3 = Color3.new(1,1,1),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = self.Name,
        Parent = header
    })

    -- Close button (simple X)
    local close = Create("TextButton", {
        Size = UDim2.new(0,32,0,32),
        Position = UDim2.new(1,-38,0,5),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Color3.new(1,0.3,0.3),
        TextSize = 28,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
        Parent = header
    })

    close.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    -- Tab bar (left sidebar)
    local tabBar = Create("ScrollingFrame", {
        Size = UDim2.new(0, 140, 1, -50),
        Position = UDim2.new(0,0,0,50),
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 3,
        BackgroundTransparency = 1,
        Parent = main
    })

    local tabList = Create("UIListLayout", {
        Padding = UDim.new(0,6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabBar
    })

    Pad(tabBar, 8,8,8,8)

    self.TabBar = tabBar
    self.TabList = tabList

    -- Content holder
    local content = Create("Frame", {
        Size = UDim2.new(1, -148, 1, -50),
        Position = UDim2.new(0,148,0,50),
        BackgroundTransparency = 1,
        Parent = main
    })
    self.Content = content

    self:MakeDraggable(main)
end

function Library:MakeDraggable(frame)
    local drag, dragIn, startPos, dragStart
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragStart = inp.Position
            startPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            dragIn = inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp == dragIn then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ────────────────────────────────────────────────────────────────
-- Tabs
-- ────────────────────────────────────────────────────────────────

function Library:CreateTab(name, icon)
    local tab = {}
    setmetatable(tab, {__index = self})

    tab.Name = name
    tab.Icon = icon or 0
    tab.Elements = {}

    local btn = Create("TextButton", {
        Size = UDim2.new(1,0,0,42),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = self.TabBar
    })
    Round(btn)

    local iconLbl = Create("ImageLabel", {
        Size = UDim2.new(0,28,0,28),
        Position = UDim2.new(0,12,0.5,0),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundTransparency = 1,
        Image = type(icon) == "number" and "rbxassetid://" .. icon or icon or "",
        ImageColor3 = Theme.TextDim,
        Parent = btn
    })

    Create("TextLabel", {
        Size = UDim2.new(1,-50,1,0),
        Position = UDim2.new(0,48,0,0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.TextDim,
        TextSize = 15,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn
    })

    local page = Create("ScrollingFrame", {
        Name = "Page_"..name,
        Size = UDim2.new(1,0,1,0),
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 4,
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Content
    })

    local list = Create("UIListLayout", {
        Padding = UDim.new(0,10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })
    Pad(page, 12,12,12,20)

    tab.Button = btn
    tab.Page = page
    tab.List = list

    btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    btn.MouseEnter:Connect(function() if self.CurrentTab ~= tab then Tween(btn, {BackgroundColor3 = Theme.Tertiary}) end end)
    btn.MouseLeave:Connect(function() if self.CurrentTab ~= tab then Tween(btn, {BackgroundColor3 = Theme.Secondary}) end end)

    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 then self:SelectTab(tab) end

    return tab
end

function Library:SelectTab(tab)
    if self.CurrentTab == tab then return end

    if self.CurrentTab then
        Tween(self.CurrentTab.Button, {BackgroundColor3 = Theme.Secondary})
        self.CurrentTab.Page.Visible = false
    end

    Tween(tab.Button, {BackgroundColor3 = Theme.Accent})
    tab.Page.Visible = true

    self.CurrentTab = tab
end

-- ────────────────────────────────────────────────────────────────
-- Elements (Rayfield-style)
-- ────────────────────────────────────────────────────────────────

local function GetSection(parent, secName)
    if not secName then return parent end
    -- simple section label (expand later)
    local sec = Create("TextLabel", {
        Size = UDim2.new(1,0,0,26),
        BackgroundTransparency = 1,
        Text = secName,
        TextColor3 = Theme.Accent,
        TextSize = 16,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    return parent
end

function Library:CreateToggle(cfg)
    local tab = self
    local sec = GetSection(tab.Page, cfg.Section)

    local frame = Create("Frame", {Size = UDim2.new(1,0,0,36), BackgroundColor3 = Theme.Secondary, Parent = sec})
    Round(frame)

    Create("TextLabel", {
        Size = UDim2.new(1,-50,1,0),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Toggle",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    }) Pad(frame:FindFirstChildOfClass("TextLabel"), 12)

    local ind = Create("Frame", {
        Size = UDim2.new(0,28,0,16),
        Position = UDim2.new(1,-40,0.5,0),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundColor3 = cfg.CurrentValue and Theme.Accent or Theme.Tertiary,
        Parent = frame
    })
    Round(ind, 8)

    local circle = Create("Frame", {
        Size = UDim2.new(0,12,0,12),
        Position = UDim2.new(cfg.CurrentValue and 1 or 0, cfg.CurrentValue and -2 or 2, 0.5,0),
        AnchorPoint = Vector2.new(cfg.CurrentValue and 1 or 0, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = ind
    })
    Round(circle, 6)

    local value = cfg.CurrentValue or false

    local function Update(v)
        value = v
        Tween(ind, {BackgroundColor3 = v and Theme.Accent or Theme.Tertiary})
        Tween(circle, {
            Position = UDim2.new(v and 1 or 0, v and -2 or 2, 0.5,0),
            AnchorPoint = Vector2.new(v and 1 or 0, 0.5)
        }, TweenMedium)
        if cfg.Callback then cfg.Callback(v) end
        if cfg.Flag then tab.Flags[cfg.Flag] = v end
    end

    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            value = not value
            Update(value)
        end
    end)

    Update(value)

    return {Toggle = function() value = not value Update(value) end, Set = Update, Get = function() return value end}
end

function Library:CreateSlider(cfg)
    local tab = self
    local sec = GetSection(tab.Page, cfg.Section)

    local frame = Create("Frame", {Size = UDim2.new(1,0,0,44), BackgroundColor3 = Theme.Secondary, Parent = sec})
    Round(frame)

    Create("TextLabel", {
        Size = UDim2.new(1,-90,0,22),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Slider",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    }) Pad(frame:FindFirstChildOfClass("TextLabel"), 12)

    local valLbl = Create("TextLabel", {
        Size = UDim2.new(0,80,0,22),
        Position = UDim2.new(1,-88,0,8),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Accent,
        TextSize = 14,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(cfg.CurrentValue or cfg.Min or 0),
        Parent = frame
    })

    local bar = Create("Frame", {
        Size = UDim2.new(1,-24,0,8),
        Position = UDim2.new(0,12,0,28),
        BackgroundColor3 = Theme.Tertiary,
        Parent = frame
    })
    Round(bar, 4)

    local fill = Create("Frame", {Size = UDim2.new(0,0,1,0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = bar})
    Round(fill, 4)

    local knob = Create("Frame", {
        Size = UDim2.new(0,16,0,16),
        Position = UDim2.new(0,0,0.5,0),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = bar
    })
    Round(knob, 8)
    Stroke(knob, Theme.Accent, 1.8)

    local min, max = cfg.Min or 0, cfg.Max or 100
    local val = math.clamp(cfg.CurrentValue or min, min, max)
    local dec = cfg.Decimals or 0
    local dragging = false

    local function Update(v, fire)
        val = math.clamp(v, min, max)
        local p = (val - min) / (max - min)
        Tween(fill, {Size = UDim2.new(p,0,1,0)})
        Tween(knob, {Position = UDim2.new(p,0,0.5,0)})
        valLbl.Text = string.format("%."..dec.."f", val)
        if fire and cfg.Callback then cfg.Callback(val) end
        if cfg.Flag then self.Flags[cfg.Flag] = val end
    end

    local function OnMove(inp)
        if dragging then
            local rel = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            Update(min + (max - min) * rel, true)
        end
    end

    knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true OnMove(i) end end)
    knob.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true OnMove(i) end end)

    RunService.RenderStepped:Connect(function()
        if dragging then
            local mouse = UserInputService:GetMouseLocation()
            OnMove({Position = Vector3.new(mouse.X, mouse.Y)})
        end
    end)

    Update(val, true)

    return {Set = function(v) Update(v, true) end, Get = function() return val end}
end

function Library:CreateDropdown(cfg)
    local tab = self
    local sec = GetSection(tab.Page, cfg.Section)

    local frame = Create("Frame", {Size = UDim2.new(1,0,0,38), BackgroundColor3 = Theme.Secondary, Parent = sec})
    Round(frame)

    Create("TextLabel", {
        Size = UDim2.new(0.48,0,1,0),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Dropdown",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    }) Pad(frame:FindFirstChildOfClass("TextLabel"), 12)

    local sel = Create("TextLabel", {
        Size = UDim2.new(0.52,-12,1,0),
        Position = UDim2.new(0.48,0,0,0),
        BackgroundTransparency = 1,
        TextColor3 = Theme.Accent,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = cfg.CurrentOption or (cfg.Options and cfg.Options[1] or "None"),
        Parent = frame
    }) Pad(sel, 12, 28)

    local arrow = Create("TextLabel", {Size = UDim2.new(0,16,1,0), Position = UDim2.new(1,-24,0,0), BackgroundTransparency = 1, Text = "▼", TextColor3 = Theme.TextDim, TextSize = 14, Parent = frame})

    local list = Create("Frame", {
        Size = UDim2.new(1,0,0,0),
        Position = UDim2.new(0,0,1,6),
        BackgroundColor3 = Theme.Secondary,
        Visible = false,
        ZIndex = 5,
        Parent = frame
    })
    Round(list)
    Stroke(list, Theme.Accent)

    local llist = Create("UIListLayout", {Padding = UDim.new(0,3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})

    local opts = cfg.Options or {}
    local current = cfg.CurrentOption or opts[1]

    local function Rebuild()
        for _,c in list:GetChildren() do if c:IsA("GuiButton") then c:Destroy() end end
        for _,opt in opts do
            local b = Create("TextButton", {
                Size = UDim2.new(1,0,0,30),
                BackgroundTransparency = 1,
                Text = opt,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Parent = list
            })
            b.MouseEnter:Connect(function() Tween(b, {BackgroundTransparency = 0.8, BackgroundColor3 = Theme.Accent}) end)
            b.MouseLeave:Connect(function() Tween(b, {BackgroundTransparency = 1}) end)
            b.MouseButton1Click:Connect(function()
                current = opt
                sel.Text = opt
                list.Visible = false
                Tween(arrow, {Rotation = 0})
                if cfg.Callback then cfg.Callback(opt) end
                if cfg.Flag then self.Flags[cfg.Flag] = opt end
            end)
        end
        list.Size = UDim2.new(1,0,0, llist.AbsoluteContentSize.Y + 8)
    end
    Rebuild()

    local open = false
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            open = not open
            list.Visible = open
            Tween(arrow, {Rotation = open and 180 or 0})
        end
    end)

    return {
        Set = function(v)
            if table.find(opts, v) then
                current = v
                sel.Text = v
                if cfg.Callback then cfg.Callback(v) end
            end
        end,
        Refresh = function(new) opts = new Rebuild() end,
        Get = function() return current end
    }
end

function Library:CreateKeybind(cfg)
    local tab = self
    local sec = GetSection(tab.Page, cfg.Section)

    local frame = Create("Frame", {Size = UDim2.new(1,0,0,36), BackgroundColor3 = Theme.Secondary, Parent = sec})
    Round(frame)

    Create("TextLabel", {
        Size = UDim2.new(1,-100,1,0),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Keybind",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    }) Pad(frame:FindFirstChildOfClass("TextLabel"), 12)

    local box = Create("TextLabel", {
        Size = UDim2.new(0,86,0,26),
        Position = UDim2.new(1,-94,0.5,0),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundColor3 = Theme.Tertiary,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Text = cfg.CurrentKeybind and cfg.CurrentKeybind.Name or "None",
        Parent = frame
    })
    Round(box, 6)

    local listening = false
    local key = cfg.CurrentKeybind or Enum.KeyCode.Unknown

    box.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            listening = true
            box.Text = "..."
            Tween(box, {BackgroundColor3 = Theme.Accent})
        end
    end)

    local conn = UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe or not listening then return end
        if i.KeyCode ~= Enum.KeyCode.Unknown then
            key = i.KeyCode
            box.Text = key.Name
            if cfg.Callback then cfg.Callback(key) end
            if cfg.Flag then self.Flags[cfg.Flag] = key.Name end
        end
        listening = false
        Tween(box, {BackgroundColor3 = Theme.Tertiary})
    end)

    table.insert(self.Connections, conn)

    return {Set = function(k) key = k box.Text = k.Name end, Get = function() return key end}
end

function Library:CreateButton(cfg)
    local tab = self
    local sec = GetSection(tab.Page, cfg.Section)

    local btn = Create("TextButton", {
        Size = UDim2.new(1,0,0,36),
        BackgroundColor3 = Theme.Accent,
        TextColor3 = Color3.new(1,1,1),
        TextSize = 15,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
        Text = cfg.Name or "Button",
        Parent = sec
    })
    Round(btn)

    btn.MouseButton1Click:Connect(function()
        if cfg.Callback then cfg.Callback() end
    end)

    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Color3.fromRGB(100,180,255)}) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Theme.Accent}) end)

    return {Fire = function() if cfg.Callback then cfg.Callback() end end}
end

function Library:CreateParagraph(cfg)
    local tab = self
    local sec = GetSection(tab.Page, cfg.Section)

    local frame = Create("Frame", {Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = sec})

    Create("TextLabel", {
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = cfg.Title or "Title",
        TextColor3 = Theme.Accent,
        TextSize = 16,
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = frame
    })

    Create("TextLabel", {
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = cfg.Content or "Description text here...",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = frame
    })

    Create("UIListLayout", {Padding = UDim.new(0,4), Parent = frame})
end

function Library:CreateLabel(text)
    local tab = self
    Create("TextLabel", {
        Size = UDim2.new(1,0,0,22),
        BackgroundTransparency = 1,
        Text = text or "Label",
        TextColor3 = Theme.TextDim,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab.Page
    })
end

-- Simple notification (global)
function Library:Notify(title, content, duration)
    duration = duration or 4

    local notif = Create("Frame", {
        Size = UDim2.new(0,280,0,80),
        Position = UDim2.new(1,-290,1,-90),
        BackgroundColor3 = Theme.Secondary,
        Parent = PlayerGui:FindFirstChild("RayfieldLikeUI") or self.Gui
    })
    Round(notif)
    Stroke(notif)

    Create("TextLabel", {Size = UDim2.new(1,0,0,24), BackgroundTransparency = 1, Text = title, TextColor3 = Theme.Accent, TextSize = 16, Parent = notif}) Pad(notif:FindFirstChildOfClass("TextLabel"), 12)
    Create("TextLabel", {Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,26), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = content, TextColor3 = Theme.Text, TextSize = 13, TextWrapped = true, Parent = notif}) Pad(notif:FindFirstChildOfClass("TextLabel", true), 12)

    task.delay(duration, function()
        Tween(notif, {Position = UDim2.new(1,-290,1,20), BackgroundTransparency = 1}, TweenMedium)
        task.delay(0.3, notif.Destroy, notif)
    end)
end

-- Config saving stub (expand with Http or DataStore if needed)
function Library:LoadConfig() -- stub end
function Library:SaveConfig() -- stub end

-- Cleanup
function Library:Destroy()
    if self.Gui then self.Gui:Destroy() end
    for _,c in self.Connections do c:Disconnect() end
end

-- Global loadstring style
return Library