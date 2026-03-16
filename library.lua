local DEBUG = true   -- ← flip to true to enable debug logging

local function DBG(tag, msg)
	if not DEBUG then return end
	print(string.format("[Simpliciton][%s] %s", tag, tostring(msg)))
end
local function WARN(tag, msg)
	-- Always warn on errors regardless of DEBUG flag
	warn(string.format("[Simpliciton][%s] %s", tag, tostring(msg)))
end
local function SAFE(tag, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then WARN(tag, err) end
	return ok
end

local Simpliciton   = {}
Simpliciton.__index = Simpliciton

DBG("LOAD", "Simpliciton v3.3 loading…")

-- ── Services  (Rayfield-style: cloneref support + pcall) ─────
local function GetSvc(name)
	local ok, svc = pcall(game.GetService, game, name)
	if not ok then
		WARN("SERVICE", "Failed to get " .. name)
		return nil
	end
	-- cloneref isolates the service from game metatable hooks
	-- (common anti-cheat technique; safe no-op if unavailable)
	return (cloneref and cloneref(svc)) or svc
end

local Players          = GetSvc("Players")
local TweenService     = GetSvc("TweenService")
local UserInputService = GetSvc("UserInputService")
local RunService       = GetSvc("RunService")
local HttpService      = GetSvc("HttpService")

DBG("LOAD", "Services resolved")

local LocalPlayer = Players and Players.LocalPlayer
local PlayerGui   = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")

if not PlayerGui then
	WARN("LOAD", "PlayerGui not found – UI cannot be created")
end

DBG("LOAD", "PlayerGui ready")

-- ── Default Theme  (copied per-window; never mutate this) ──
Simpliciton.DefaultTheme = {
	Accent       = Color3.fromRGB(85,  170, 255),
	Background   = Color3.fromRGB(16,  16,  22 ),
	Secondary    = Color3.fromRGB(27,  27,  36 ),
	Tertiary     = Color3.fromRGB(40,  40,  52 ),
	Text         = Color3.fromRGB(235, 235, 245),
	TextDim      = Color3.fromRGB(128, 128, 155),
	Border       = Color3.fromRGB(55,  55,  72 ),
	Success      = Color3.fromRGB(72,  210, 130),
	Warning      = Color3.fromRGB(255, 185, 55 ),
	Error        = Color3.fromRGB(255, 72,  72 ),
	CornerRadius = 8,
}

-- ── Tween presets ─────────────────────────────────────────
local TI_FAST   = TweenInfo.new(0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TI_MID    = TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.38, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TI_SPRING = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ── Element registry ──────────────────────────────────────
Simpliciton.Elements = {}

-- ============================================================
--  INTERNAL UTILITIES
-- ============================================================

local function Tween(obj, props, ti)
	if not obj or not obj.Parent then return end
	if not TweenService then return end
	pcall(function()
		TweenService:Create(obj, ti or TI_FAST, props):Play()
	end)
end

local function New(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then pcall(function() inst[k] = v end) end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function Corner(inst, r)
	New("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
end

local function Stroke(inst, color, thick, transp)
	return New("UIStroke", {
		Color        = color or Color3.fromRGB(55,55,72),
		Thickness    = thick or 1,
		Transparency = transp or 0.3,
	}, inst)
end

local function Pad(inst, l, r, t, b)
	New("UIPadding", {
		PaddingLeft   = UDim.new(0, l or 8),
		PaddingRight  = UDim.new(0, r or 8),
		PaddingTop    = UDim.new(0, t or 6),
		PaddingBottom = UDim.new(0, b or 6),
	}, inst)
end

local function VList(inst, gap)
	New("UIListLayout", {
		Padding       = UDim.new(0, gap or 6),
		SortOrder     = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
	}, inst)
end

-- ScrollVList: creates a UIListLayout AND auto-sizes the scrollframe canvas.
-- Uses AutomaticCanvasSize (new API) and falls back to AbsoluteContentSize
-- watcher (old-API compatible). Always works regardless of executor version.
local function ScrollVList(scrollFrame, gap, extraPad)
	local layout = New("UIListLayout", {
		Padding       = UDim.new(0, gap or 6),
		SortOrder     = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
	}, scrollFrame)

	-- Try the new AutomaticCanvasSize property (2021+)
	pcall(function()
		scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	end)

	-- Fallback: always resize via AbsoluteContentSize
	-- (harmless double-resize on new clients; essential on old ones)
	local pad = extraPad or 0
	local function resize()
		if scrollFrame and scrollFrame.Parent then
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + pad)
		end
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
	resize()
	return layout
end

-- SafeAutoSize: sets AutomaticSize (post-2019 API) with silent fallback.
local function SafeAuto(inst, axis)
	pcall(function() inst.AutomaticSize = axis end)
end

local function GetWindow(self)
	return self.Window or self
end

local function GetPage(self)
	-- Groups have their own .Page; tabs have .Page; windows use CurrentTab.Page
	return self.Page or (self.CurrentTab and self.CurrentTab.Page)
end

local function GetTheme(self)
	return GetWindow(self).Theme or Simpliciton.DefaultTheme
end

local function BindTheme(win, inst, prop, key)
	if win and win.ThemedInstances then
		table.insert(win.ThemedInstances, { inst, prop, key })
	end
end

local function T(self) return GetTheme(self) end

local function Lighten(c, a)
	return Color3.fromRGB(
		math.clamp(math.floor(c.R*255)+a, 0, 255),
		math.clamp(math.floor(c.G*255)+a, 0, 255),
		math.clamp(math.floor(c.B*255)+a, 0, 255)
	)
end

-- Shared tooltip frame (one per ScreenGui)
local function MakeTooltip(sg)
	local tt = New("Frame", {
		Size                   = UDim2.new(0, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.XY,
		BackgroundColor3       = Color3.fromRGB(22, 22, 30),
		BackgroundTransparency = 0,
		ZIndex                 = 200,
		Visible                = false,
		Parent                 = sg,
	})
	Corner(tt, 5)
	Stroke(tt, Color3.fromRGB(60, 60, 80), 1, 0.2)
	Pad(tt, 8, 8, 4, 4)
	local lbl = New("TextLabel", {
		Size                   = UDim2.new(0, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text                   = "",
		TextColor3             = Color3.fromRGB(200, 200, 220),
		TextSize               = 12,
		ZIndex                 = 201,
		Parent                 = tt,
	})
	return tt, lbl
end

local function AttachTooltip(win, inst, text)
	if not text or text == "" then return end
	local tt, lbl = win._tooltipFrame, win._tooltipLabel
	if not tt then return end

	local shown = false
	local con   = {}

	local function show()
		lbl.Text = text
		tt.Visible = true
		shown = true
	end
	local function hide()
		tt.Visible = false
		shown = false
	end

	table.insert(con, inst.MouseEnter:Connect(function() show() end))
	table.insert(con, inst.MouseLeave:Connect(function() hide() end))

	local mouseConn = UserInputService.InputChanged:Connect(function(i)
		if shown and i.UserInputType == Enum.UserInputType.MouseMovement then
			tt.Position = UDim2.new(0, i.Position.X + 14, 0, i.Position.Y + 14)
		end
	end)
	table.insert(con, mouseConn)
	for _, c in con do table.insert(GetWindow(win).Connections, c) end
end

-- ============================================================
--  WINDOW
-- ============================================================

function Simpliciton:CreateWindow(opts)
	opts = opts or {}
	DBG("CreateWindow", "Name=" .. tostring(opts.Name or "Simpliciton"))
	local win = setmetatable({}, Simpliciton)

	-- Deep-copy DefaultTheme so each window has its own mutable theme
	win.Theme = {}
	for k, v in pairs(Simpliciton.DefaultTheme) do win.Theme[k] = v end

	win.Name             = opts.Name  or "Simpliciton"
	win.ConfigSaving     = opts.ConfigurationSaving or { Enabled = true, FileName = "Simpliciton_Config.json" }
	win.Flags            = {}
	win.Tabs             = {}
	win.CurrentTab       = nil
	win.Connections      = {}
	win.ThemedInstances  = {}
	win.RainbowThread    = nil
	win._minimised       = false
	win._visible         = true
	win._fullHeight      = 480
	win._notifOrder      = 0

	DBG("CreateWindow", "Building interface…")
	local ok, err = pcall(function() win:_Build() end)
	if not ok then WARN("_Build", err) return win end
	DBG("CreateWindow", "_Build done")

	local ok2, err2 = pcall(function() win:_BuildSettingsTab() end)
	if not ok2 then WARN("_BuildSettingsTab", err2) end
	DBG("CreateWindow", "Ready")

	return win
end

function Simpliciton:_Build()
	DBG("_Build", "start")
	local th = self.Theme

	-- ── ScreenGui (Rayfield-style GUI protection) ───────────
	local sg = New("ScreenGui", {
		Name           = "SimplicitonUI",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn   = false,
		DisplayOrder   = 120,
	})
	-- Parent safely: prefer protected containers so anti-cheat can't see it
	local CoreGui = GetSvc("CoreGui")
	local guiParented = false
	if gethui then
		pcall(function() sg.Parent = gethui(); guiParented = true end)
	end
	if not guiParented and syn and syn.protect_gui then
		pcall(function() syn.protect_gui(sg); sg.Parent = CoreGui; guiParented = true end)
	end
	if not guiParented and CoreGui then
		pcall(function()
			local RobloxGui = CoreGui:FindFirstChild("RobloxGui")
			sg.Parent = RobloxGui or CoreGui
			guiParented = true
		end)
	end
	if not guiParented then
		sg.Parent = PlayerGui
	end
	-- Kill duplicate instances from previous runs
	local sgName = sg.Name
	local container = sg.Parent
	if container then
		for _, child in ipairs(container:GetChildren()) do
			if child.Name == sgName and child ~= sg then
				pcall(function() child:Destroy() end)
			end
		end
	end
	self.ScreenGui = sg
	DBG("_Build", "ScreenGui created, parent=" .. tostring(sg.Parent))

	-- ── Shadow ──────────────────────────────────────────
	local shadow = New("ImageLabel", {
		Size              = UDim2.new(0, 770, 0, 570),
		Position          = UDim2.new(0.5, -385, 0.5, -285),
		BackgroundTransparency = 1,
		Image             = "rbxassetid://6014261993",
		ImageColor3       = Color3.new(0,0,0),
		ImageTransparency = 0.50,
		ScaleType         = Enum.ScaleType.Slice,
		SliceCenter       = Rect.new(49,49,450,450),
		ZIndex            = 0,
		Parent            = sg,
	})
	self._shadow = shadow

	-- ── Main frame ──────────────────────────────────────
	local main = New("Frame", {
		Name             = "Main",
		Size             = UDim2.new(0, 710, 0, self._fullHeight),
		Position         = UDim2.new(0.5, -355, 0.5, -240),
		BackgroundColor3 = th.Background,
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		Parent           = sg,
	})
	Corner(main)
	Stroke(main, th.Border, 1.2, 0.15)
	self.MainFrame = main
	BindTheme(self, main, "BackgroundColor3", "Background")

	-- ── Header ──────────────────────────────────────────
	local header = New("Frame", {
		Name             = "Header",
		Size             = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = th.Accent,
		BorderSizePixel  = 0,
		ZIndex           = 3,
		Parent           = main,
	})
	Corner(header)
	-- Fill bottom gap so header looks rectangular on the bottom edge
	local headerFiller = New("Frame", {
		Size             = UDim2.new(1, 0, 0.5, 0),
		Position         = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = th.Accent,
		BorderSizePixel  = 0,
		ZIndex           = 2,
		Parent           = header,
	})
	self.Header = header
	BindTheme(self, header,       "BackgroundColor3", "Accent")
	BindTheme(self, headerFiller, "BackgroundColor3", "Accent")

	-- Subtle header gradient
	New("UIGradient", {
		Color       = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.7,0.7,0.7)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90,
		Parent   = header,
	})

	-- Title
	local titleLbl = New("TextLabel", {
		Size                   = UDim2.new(1, -120, 1, 0),
		Position               = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 17,
		TextColor3             = Color3.new(1,1,1),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Text                   = self.Name,
		ZIndex                 = 4,
		Parent                 = header,
	})
	self._titleLabel = titleLbl

	-- Minimise button
	local minBtn = New("TextButton", {
		Size             = UDim2.new(0, 28, 0, 28),
		Position         = UDim2.new(1, -78, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 198, 40),
		Text             = "–",
		TextColor3       = Color3.fromRGB(120, 80, 0),
		TextSize         = 16,
		Font             = Enum.Font.GothamBold,
		ZIndex           = 5,
		Parent           = header,
	})
	Corner(minBtn, 7)
	minBtn.MouseEnter:Connect(function() Tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 220, 90)}) end)
	minBtn.MouseLeave:Connect(function() Tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 198, 40)}) end)
	minBtn.MouseButton1Click:Connect(function()
		if self._minimised then self:Maximize() else self:Minimize() end
	end)

	-- Close button
	local closeBtn = New("TextButton", {
		Size             = UDim2.new(0, 28, 0, 28),
		Position         = UDim2.new(1, -42, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 65, 65),
		Text             = "×",
		TextColor3       = Color3.new(1,1,1),
		TextSize         = 19,
		Font             = Enum.Font.GothamBold,
		ZIndex           = 5,
		Parent           = header,
	})
	Corner(closeBtn, 7)
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 105, 105)}) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 65, 65)}) end)
	closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

	-- ── Sidebar ──────────────────────────────────────────
	local sidebar = New("ScrollingFrame", {
		Size                 = UDim2.new(0, 162, 1, -60),
		Position             = UDim2.new(0, 0, 0, 60),
		CanvasSize           = UDim2.new(),
		ScrollBarThickness   = 3,
		ScrollBarImageColor3 = th.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		Parent               = main,
	})
	ScrollVList(sidebar, 4, 10+8)  -- 10 bottom + 8 top padding
	Pad(sidebar, 6, 6, 8, 10)
	self.Sidebar = sidebar

	-- Divider between sidebar and content
	New("Frame", {
		Size             = UDim2.new(0, 1, 1, -60),
		Position         = UDim2.new(0, 162, 0, 60),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.5,
		BorderSizePixel  = 0,
		Parent           = main,
	})

	-- ── Content area ─────────────────────────────────────
	local content = New("Frame", {
		Size                   = UDim2.new(1, -170, 1, -60),
		Position               = UDim2.new(0, 170, 0, 60),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ClipsDescendants       = false,  -- dropdowns/pickers must overflow
		Parent                 = main,
	})
	self.ContentArea = content

	-- ── Notification container ───────────────────────────
	local notifContainer = New("Frame", {
		Size             = UDim2.new(0, 320, 0, 600),
		Position         = UDim2.new(1, -332, 1, -610),
		BackgroundTransparency = 1,
		ZIndex           = 80,
		Parent           = sg,
	})
	New("UIListLayout", {
		Padding           = UDim.new(0, 7),
		SortOrder         = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		FillDirection     = Enum.FillDirection.Vertical,
		Parent            = notifContainer,
	})
	self._notifContainer = notifContainer

	-- ── Tooltip frame (singleton per window) ─────────────
	local ttFrame, ttLabel = MakeTooltip(sg)
	self._tooltipFrame = ttFrame
	self._tooltipLabel = ttLabel

	self:_MakeDraggable(header)
	DBG("_Build", "complete")
end

function Simpliciton:_MakeDraggable(handle)
	local dragging, startOffset = false, Vector2.new()

	local c1 = handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local ap = self.MainFrame.AbsolutePosition
			startOffset = Vector2.new(
				input.Position.X - ap.X,
				input.Position.Y - ap.Y
			)
		end
	end)

	local c2 = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local nx = input.Position.X - startOffset.X
			local ny = input.Position.Y - startOffset.Y
			self.MainFrame.Position = UDim2.new(0, nx, 0, ny)
			if self._shadow then
				self._shadow.Position = UDim2.new(0, nx - 30, 0, ny - 30)
			end
		end
	end)

	local c3 = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	table.insert(self.Connections, c1)
	table.insert(self.Connections, c2)
	table.insert(self.Connections, c3)
end

-- ============================================================
--  WINDOW MANAGEMENT
-- ============================================================

function Simpliciton:Minimize()
	self._minimised = true
	Tween(self.MainFrame, { Size = UDim2.new(0, 710, 0, 52) }, TI_MID)
end

function Simpliciton:Maximize()
	self._minimised = false
	Tween(self.MainFrame, { Size = UDim2.new(0, 710, 0, self._fullHeight) }, TI_MID)
end

function Simpliciton:Toggle()
	self._visible = not self._visible
	self.MainFrame.Visible  = self._visible
	if self._shadow then self._shadow.Visible = self._visible end
end

function Simpliciton:SetTitle(text)
	self.Name = text
	if self._titleLabel then self._titleLabel.Text = text end
end

--- Bind a global keycode to toggle window visibility
function Simpliciton:SetKeybind(keyCode)
	local conn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == keyCode then self:Toggle() end
	end)
	table.insert(self.Connections, conn)
end

--- Floating watermark HUD in the top-right corner
function Simpliciton:SetWatermark(text, subtext)
	if self._watermark then self._watermark:Destroy() end

	local wm = New("Frame", {
		Size             = UDim2.new(0, 0, 0, 34),
		AutomaticSize    = Enum.AutomaticSize.X,
		Position         = UDim2.new(1, -10, 0, 10),
		AnchorPoint      = Vector2.new(1, 0),
		BackgroundColor3 = self.Theme.Background,
		BackgroundTransparency = 0.15,
		ZIndex           = 50,
		Parent           = self.ScreenGui,
	})
	Corner(wm, 7)
	Stroke(wm, self.Theme.Accent, 1.2, 0.35)
	Pad(wm, 12, 12, 6, 6)

	local inner = New("Frame", {
		Size                   = UDim2.new(0, 0, 1, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex                 = 51,
		Parent                 = wm,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding       = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent        = inner,
	})

	New("TextLabel", {
		Size                   = UDim2.new(0, 0, 1, 0),
		AutomaticSize          = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text                   = text,
		TextColor3             = Color3.new(1,1,1),
		TextSize               = 13,
		Font                   = Enum.Font.GothamBold,
		ZIndex                 = 51,
		Parent                 = inner,
	})

	if subtext then
		New("TextLabel", {
			Size                   = UDim2.new(0, 0, 1, 0),
			AutomaticSize          = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text                   = subtext,
			TextColor3             = self.Theme.TextDim,
			TextSize               = 12,
			ZIndex                 = 51,
			Parent                 = inner,
		})
	end

	self._watermark = wm
	self:_MakeDraggable(wm)
end

-- ============================================================
--  THEME
-- ============================================================

function Simpliciton:SetTheme(newTheme)
	for k, v in pairs(newTheme) do
		self.Theme[k] = v
	end
	-- Update all registered theme-bound instances
	for _, binding in ipairs(self.ThemedInstances) do
		local inst, prop, key = binding[1], binding[2], binding[3]
		if inst and inst.Parent and self.Theme[key] then
			pcall(function() Tween(inst, { [prop] = self.Theme[key] }) end)
		end
	end
	-- Refresh accent on active tab
	if self.CurrentTab and self.CurrentTab.ActiveBar then
		Tween(self.CurrentTab.ActiveBar, { BackgroundColor3 = self.Theme.Accent })
	end
	-- Refresh watermark stroke
	if self._watermark then
		local stroke = self._watermark:FindFirstChildWhichIsA("UIStroke")
		if stroke then Tween(stroke, { Color = self.Theme.Accent }) end
	end
	-- Refresh sidebar scroll bar
	if self.Sidebar then
		Tween(self.Sidebar, { ScrollBarImageColor3 = self.Theme.Accent })
	end
end

function Simpliciton:_RefreshAccent()
	self:SetTheme({ Accent = self.Theme.Accent })
end

-- ============================================================
--  TABS
-- ============================================================

function Simpliciton:CreateTab(name, iconId)
	DBG("CreateTab", name)
	local tab    = setmetatable({}, Simpliciton)
	tab.Window   = self
	tab.Name     = name
	tab.Elements = {}         -- { {name, frame, visible} }

	local th = self.Theme

	-- ── Sidebar button ───────────────────────────────────
	local btn = New("TextButton", {
		Size             = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = th.Secondary,
		BorderSizePixel  = 0,
		Text             = "",
		AutoButtonColor  = false,
		ZIndex           = 3,
		Parent           = self.Sidebar,
	})
	Corner(btn)

	local activeBar = New("Frame", {
		Size             = UDim2.new(0, 3, 0.6, 0),
		Position         = UDim2.new(0, 0, 0.2, 0),
		BackgroundColor3 = th.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel  = 0,
		ZIndex           = 4,
		Parent           = btn,
	})
	Corner(activeBar, 2)

	local xOff = 12
	if iconId then
		xOff = 38
		New("ImageLabel", {
			Size                   = UDim2.new(0, 18, 0, 18),
			Position               = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint            = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image                  = "rbxassetid://" .. tostring(iconId),
			ImageColor3            = th.TextDim,
			ZIndex                 = 4,
			Parent                 = btn,
		})
	end

	local btnLabel = New("TextLabel", {
		Size                   = UDim2.new(1, -(xOff + 6), 1, 0),
		Position               = UDim2.new(0, xOff, 0, 0),
		BackgroundTransparency = 1,
		Text                   = name,
		TextColor3             = th.TextDim,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 4,
		Parent                 = btn,
	})

	-- ── Content page ─────────────────────────────────────
	local page = New("ScrollingFrame", {
		Size                 = UDim2.new(1, 0, 1, 0),
		CanvasSize           = UDim2.new(),
		ScrollBarThickness   = 4,
		ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80),
		BackgroundTransparency = 1,
		ClipsDescendants     = false,  -- allow dropdown/picker overflow
		Visible              = false,
		BorderSizePixel      = 0,
		Parent               = self.ContentArea,
	})
	ScrollVList(page, 7, 12+20)  -- 12 top + 20 bottom padding
	Pad(page, 14, 14, 12, 20)

	tab.Button    = btn
	tab.Page      = page
	tab.BtnLabel  = btnLabel
	tab.ActiveBar = activeBar

	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	btn.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then Tween(btn, { BackgroundColor3 = th.Tertiary }) end
	end)
	btn.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then Tween(btn, { BackgroundColor3 = th.Secondary }) end
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then self:SelectTab(tab) end

	return tab
end

function Simpliciton:SelectTab(tab)
	if self.CurrentTab == tab then return end
	if self.CurrentTab then
		local prev = self.CurrentTab
		Tween(prev.Button,    { BackgroundColor3 = self.Theme.Secondary }, TI_MID)
		Tween(prev.BtnLabel,  { TextColor3 = self.Theme.TextDim }, TI_MID)
		Tween(prev.ActiveBar, { BackgroundTransparency = 1 }, TI_MID)
		prev.Page.Visible = false
	end
	Tween(tab.Button,    { BackgroundColor3 = self.Theme.Tertiary }, TI_MID)
	Tween(tab.BtnLabel,  { TextColor3 = self.Theme.Text }, TI_MID)
	Tween(tab.ActiveBar, { BackgroundTransparency = 0, BackgroundColor3 = self.Theme.Accent }, TI_MID)
	tab.Page.Visible = true
	self.CurrentTab  = tab
end

-- ============================================================
--  SEARCH
-- ============================================================

--- Adds a live search box to the top of the tab's page.
--- Filters element containers by their registered name.
function Simpliciton:EnableSearch()
	DBG("EnableSearch", "called")
	local page = GetPage(self)
	if not page then return end
	local th = GetTheme(self)

	-- Override UIListLayout Padding so searchbox is at the very top
	local searchWrap = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = th.Tertiary,
		LayoutOrder      = -9999,
		Parent           = page,
	})
	Corner(searchWrap)

	New("TextLabel", {
		Size                   = UDim2.new(0, 22, 1, 0),
		Position               = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "🔍",
		TextSize               = 13,
		Parent                 = searchWrap,
	})

	local box = New("TextBox", {
		Size              = UDim2.new(1, -30, 0, 26),
		Position          = UDim2.new(0, 26, 0.5, 0),
		AnchorPoint       = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		PlaceholderText   = "Search elements…",
		PlaceholderColor3 = th.TextDim,
		Text              = "",
		TextColor3        = th.Text,
		TextSize          = 13,
		ClearTextOnFocus  = false,
		Parent            = searchWrap,
	})

	local tab = self  -- 'self' here is the tab object

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local query = box.Text:lower()
		for _, entry in ipairs(tab.Elements or {}) do
			local name  = (entry.name or ""):lower()
			local frame = entry.frame
			if frame and frame.Parent then
				frame.Visible = query == "" or name:find(query, 1, true) ~= nil
			end
		end
	end)
end

-- ============================================================
--  GROUPS (collapsible containers)
-- ============================================================

function Simpliciton:CreateGroup(title, startCollapsed)
	DBG("CreateGroup", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)

	local collapsed = startCollapsed == true

	-- Outer wrapper (auto-sizes to content)
	local outer = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(outer)
	Stroke(outer, th.Border, 1, 0.4)

	-- Header row
	local headerRow = New("TextButton", {
		Size             = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text             = "",
		AutoButtonColor  = false,
		ZIndex           = 2,
		Parent           = outer,
	})

	-- Arrow indicator
	local arrow = New("TextLabel", {
		Size                   = UDim2.new(0, 20, 1, 0),
		Position               = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text                   = collapsed and "▶" or "▼",
		TextColor3             = th.TextDim,
		TextSize               = 11,
		ZIndex                 = 3,
		Parent                 = headerRow,
	})

	New("TextLabel", {
		Size                   = UDim2.new(1, -36, 1, 0),
		Position               = UDim2.new(0, 28, 0, 0),
		BackgroundTransparency = 1,
		Text                   = title,
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamSemibold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 3,
		Parent                 = headerRow,
	})

	-- Inner content frame (elements go here)
	local inner = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		Position         = UDim2.new(0, 0, 0, 36),
		AutomaticSize    = collapsed and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible          = not collapsed,
		Parent           = outer,
	})
	VList(inner, 6)
	Pad(inner, 8, 8, 4, 8)

	-- Collapse / expand toggle
	headerRow.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		arrow.Text   = collapsed and "▶" or "▼"
		inner.Visible = not collapsed
		inner.AutomaticSize = collapsed and Enum.AutomaticSize.None or Enum.AutomaticSize.Y
		if collapsed then inner.Size = UDim2.new(1,0,0,0) end
	end)
	headerRow.MouseEnter:Connect(function() Tween(headerRow, {BackgroundTransparency = 0.9, BackgroundColor3 = th.Accent}) end)
	headerRow.MouseLeave:Connect(function() Tween(headerRow, {BackgroundTransparency = 1}) end)

	-- Make a group object that inherits Simpliciton methods and uses inner as its page
	local group    = setmetatable({}, Simpliciton)
	group.Window   = win
	group.Page     = inner
	group.Elements = (self.Elements or {})  -- share parent element list for search

	return group
end

-- ============================================================
--  ELEMENTS  (all callable on Window, Tab, or Group objects)
-- ============================================================

-- Internal: register element for search
local function RegElement(self, name, frame)
	local tab = self
	-- Walk up to the tab object (which has its own .Elements list)
	if tab.Window then
		-- self is a tab or group; groups share Elements with parent tab
	end
	if tab.Elements then
		table.insert(tab.Elements, { name = name, frame = frame })
	end
end

-- ── Section ──────────────────────────────────────────────────
function Simpliciton:CreateSection(title)
	DBG("CreateSection", "called")
	local page = GetPage(self)
	if not page then return end
	local th = GetTheme(self)

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Parent           = page,
	})
	New("TextLabel", {
		Size                   = UDim2.new(1, -4, 0, 18),
		Position               = UDim2.new(0, 2, 0, 3),
		BackgroundTransparency = 1,
		Text                   = title:upper(),
		TextColor3             = th.Accent,
		TextSize               = 10,
		Font                   = Enum.Font.GothamBold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})
	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = th.Accent,
		BackgroundTransparency = 0.7,
		BorderSizePixel  = 0,
		Parent           = frame,
	})
	return frame
end

-- ── Label ────────────────────────────────────────────────────
function Simpliciton:CreateLabel(text, tooltip)
	DBG("CreateLabel", "called")
	local page = GetPage(self)
	if not page then return end
	local th = GetTheme(self)

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(frame)
	local lbl = New("TextLabel", {
		Size                   = UDim2.new(1, -24, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = text,
		TextColor3             = th.TextDim,
		TextSize               = 13,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})
	AttachTooltip(GetWindow(self), frame, tooltip)
	RegElement(self, text, frame)

	return {
		SetText    = function(t) lbl.Text = t end,
		SetVisible = function(v) frame.Visible = v end,
		Destroy    = function() frame:Destroy() end,
	}
end

-- ── Divider ──────────────────────────────────────────────────
function Simpliciton:CreateDivider()
	DBG("CreateDivider", "called")
	local page = GetPage(self)
	if not page then return end
	local th = GetTheme(self)

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Parent           = page,
	})
	New("Frame", {
		Size             = UDim2.new(1, -20, 0, 1),
		Position         = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.4,
		BorderSizePixel  = 0,
		Parent           = frame,
	})
	return { Destroy = function() frame:Destroy() end }
end

-- ── Paragraph ────────────────────────────────────────────────
function Simpliciton:CreateParagraph(opts)
	DBG("CreateParagraph", "called")
	local page = GetPage(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(frame)
	Pad(frame, 14, 14, 10, 12)
	VList(frame, 5)

	local titleLbl = New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = opts.Title   or "Title",
		TextColor3             = th.Text,
		TextSize               = 14,
		Font                   = Enum.Font.GothamSemibold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		Parent                 = frame,
	})
	local contentLbl = New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = opts.Content or "",
		TextColor3             = th.TextDim,
		TextSize               = 12,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		Parent                 = frame,
	})
	RegElement(self, opts.Title or "Paragraph", frame)

	return {
		SetTitle   = function(t) titleLbl.Text   = t end,
		SetContent = function(t) contentLbl.Text = t end,
		SetVisible = function(v) frame.Visible   = v end,
		Destroy    = function()  frame:Destroy() end,
	}
end

-- ── Toggle ───────────────────────────────────────────────────
function Simpliciton:CreateToggle(opts)
	DBG("CreateToggle", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(1, -66, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Toggle",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local track = New("Frame", {
		Size             = UDim2.new(0, 38, 0, 21),
		Position         = UDim2.new(1, -50, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = th.Tertiary,
		Parent           = frame,
	})
	Corner(track, 11)

	local knob = New("Frame", {
		Size             = UDim2.new(0, 15, 0, 15),
		Position         = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent           = track,
	})
	Corner(knob, 8)

	local val = opts.CurrentValue == true

	local function setState(v, silent)
		val = v
		Tween(track, { BackgroundColor3 = v and th.Accent or th.Tertiary }, TI_MID)
		Tween(knob,  {
			Position    = v and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = v and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
		}, TI_MID)
		if not silent then
			if opts.Callback then pcall(opts.Callback, v) end
			if opts.Flag     then win.Flags[opts.Flag] = v end
		end
	end

	frame.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then setState(not val) end
	end)
	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = th.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = th.Secondary }) end)
	AttachTooltip(win, frame, opts.Tooltip)
	setState(val, true)
	RegElement(self, opts.Name or "Toggle", frame)

	return {
		Set        = function(v) setState(v) end,
		Get        = function() return val end,
		Toggle     = function() setState(not val) end,
		SetVisible = function(v) frame.Visible = v end,
		Destroy    = function() frame:Destroy() end,
	}
end

-- ── Slider ───────────────────────────────────────────────────
function Simpliciton:CreateSlider(opts)
	DBG("CreateSlider", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	-- Accept Rayfield-style Range={min,max}/Increment OR Min/Max/Decimals
	local min, max
	if opts.Range and type(opts.Range) == "table" then
		min = opts.Range[1] or 0
		max = opts.Range[2] or 100
	else
		min = opts.Min or 0
		max = opts.Max or 100
	end
	local inc = opts.Increment  -- Rayfield uses Increment for step
	local dec = opts.Decimals or (inc and 0) or 0
	local value    = math.clamp(opts.CurrentValue or min, min, max)

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(1, -80, 0, 24),
		Position               = UDim2.new(0, 14, 0, 5),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Slider",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local valLbl = New("TextLabel", {
		Size                   = UDim2.new(0, 64, 0, 24),
		Position               = UDim2.new(1, -74, 0, 5),
		BackgroundTransparency = 1,
		Text                   = string.format("%." .. dec .. "f", value),
		TextColor3             = th.Accent,
		TextSize               = 12,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Right,
		Parent                 = frame,
	})
	BindTheme(win, valLbl, "TextColor3", "Accent")

	local track = New("Frame", {
		Size             = UDim2.new(1, -28, 0, 5),
		Position         = UDim2.new(0, 14, 0, 40),
		BackgroundColor3 = th.Tertiary,
		Parent           = frame,
	})
	Corner(track, 3)

	local fill = New("Frame", {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = th.Accent,
		Parent           = track,
	})
	Corner(fill, 3)
	BindTheme(win, fill, "BackgroundColor3", "Accent")

	local knob = New("Frame", {
		Size             = UDim2.new(0, 15, 0, 15),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent           = track,
	})
	Corner(knob, 8)
	Stroke(knob, th.Accent, 1.8, 0)

	local dragging = false

	local function update(v, fire)
		value = math.clamp(tonumber(string.format("%." .. dec .. "f", v)) or v, min, max)
		local pct = (value - min) / (max - min)
		fill.Size     = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		valLbl.Text   = string.format("%." .. dec .. "f", value)
		if fire then
			if opts.Callback then pcall(opts.Callback, value) end
			if opts.Flag     then win.Flags[opts.Flag] = value end
		end
	end

	local function applyDrag(xPos)
		local pct = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = min + (max - min) * pct
		if inc and inc > 0 then
			raw = math.floor(raw / inc + 0.5) * inc
		end
		update(raw, true)
	end

	-- Rayfield-style: Stepped loop inside MouseButton1Down avoids
	-- global UIS connections that accumulate per-element.
	track.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dragging = true
		applyDrag(i.Position.X)
		local loop; loop = RunService and RunService.Stepped:Connect(function()
			if not dragging then
				loop:Disconnect()
				return
			end
			if UserInputService then
				applyDrag(UserInputService:GetMouseLocation().X)
			end
		end)
		if loop then table.insert(win.Connections, loop) end
	end)
	local c2 = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	table.insert(win.Connections, c2)

	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = th.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = th.Secondary }) end)
	AttachTooltip(win, frame, opts.Tooltip)
	update(value, false)
	RegElement(self, opts.Name or "Slider", frame)

	return {
		Set        = function(v) update(v, true) end,
		Get        = function() return value end,
		SetVisible = function(v) frame.Visible = v end,
		Destroy    = function() frame:Destroy() end,
	}
end

-- ── Dropdown ─────────────────────────────────────────────────
function Simpliciton:CreateDropdown(opts)
	DBG("CreateDropdown", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local current = opts.CurrentOption
		or (opts.Options and opts.Options[1]) or ""
	local isOpen  = false

	local wrapper = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Secondary,
		ClipsDescendants = false,
		ZIndex           = 5,
		Parent           = page,
	})
	Corner(wrapper)

	New("TextLabel", {
		Size                   = UDim2.new(0.45, 0, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Dropdown",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 6,
		Parent                 = wrapper,
	})

	local selLbl = New("TextLabel", {
		Size                   = UDim2.new(0.5, -26, 1, 0),
		Position               = UDim2.new(0.48, 0, 0, 0),
		BackgroundTransparency = 1,
		Text                   = current,
		TextColor3             = th.Accent,
		TextSize               = 13,
		TextXAlignment         = Enum.TextXAlignment.Right,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 6,
		Parent                 = wrapper,
	})
	BindTheme(win, selLbl, "TextColor3", "Accent")

	local arrow = New("TextLabel", {
		Size                   = UDim2.new(0, 18, 1, 0),
		Position               = UDim2.new(1, -20, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "▾",
		TextColor3             = th.TextDim,
		TextSize               = 14,
		ZIndex                 = 6,
		Parent                 = wrapper,
	})

	local listFrame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		Position         = UDim2.new(0, 0, 1, 5),
		BackgroundColor3 = th.Secondary,
		Visible          = false,
		ZIndex           = 20,
		Parent           = wrapper,
	})
	Corner(listFrame)
	Stroke(listFrame, th.Accent, 1.2, 0.25)
	local listLayout = New("UIListLayout", { Padding = UDim.new(0, 2), Parent = listFrame })
	Pad(listFrame, 4, 4, 4, 4)

	local function rebuild()
		for _, c in listFrame:GetChildren() do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, opt in ipairs(opts.Options or {}) do
			local item = New("TextButton", {
				Size                   = UDim2.new(1, 0, 0, 30),
				BackgroundColor3       = th.Accent,
				BackgroundTransparency = opt == current and 0.75 or 1,
				Text                   = opt,
				TextColor3             = th.Text,
				TextSize               = 13,
				ZIndex                 = 21,
				Parent                 = listFrame,
			})
			Corner(item, 5)
			item.MouseEnter:Connect(function() Tween(item, { BackgroundTransparency = 0.75, BackgroundColor3 = th.Accent }) end)
			item.MouseLeave:Connect(function()
				Tween(item, { BackgroundTransparency = opt == current and 0.75 or 1 })
			end)
			item.MouseButton1Click:Connect(function()
				current          = opt
				selLbl.Text      = opt
				isOpen           = false
				listFrame.Visible = false
				Tween(arrow, { Rotation = 0 })
				-- Highlight selected
				for _, c2 in listFrame:GetChildren() do
					if c2:IsA("TextButton") then
						Tween(c2, { BackgroundTransparency = c2.Text == opt and 0.75 or 1 })
					end
				end
				if opts.Callback then pcall(opts.Callback, opt) end
				if opts.Flag     then win.Flags[opts.Flag] = opt end
			end)
		end
		coroutine.wrap(function()
			if RunService then RunService.Heartbeat:Wait() end
			if listLayout and listFrame and listFrame.Parent then
				listFrame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
			end
		end)()
	end
	rebuild()

	wrapper.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			isOpen            = not isOpen
			listFrame.Visible = isOpen
			Tween(arrow, { Rotation = isOpen and 180 or 0 })
		end
	end)
	wrapper.MouseEnter:Connect(function() Tween(wrapper, { BackgroundColor3 = th.Tertiary }) end)
	wrapper.MouseLeave:Connect(function()
		if not isOpen then Tween(wrapper, { BackgroundColor3 = th.Secondary }) end
	end)
	AttachTooltip(win, wrapper, opts.Tooltip)
	RegElement(self, opts.Name or "Dropdown", wrapper)

	return {
		Set     = function(v)
			if table.find(opts.Options or {}, v) then
				current = v; selLbl.Text = v
				if opts.Callback then pcall(opts.Callback, v) end
				if opts.Flag     then win.Flags[opts.Flag] = v end
			end
		end,
		Get     = function() return current end,
		Refresh = function(newOpts) opts.Options = newOpts; rebuild() end,
		SetVisible = function(v) wrapper.Visible = v end,
		Destroy = function() wrapper:Destroy() end,
	}
end

-- ── MultiDropdown ────────────────────────────────────────────
function Simpliciton:CreateMultiDropdown(opts)
	DBG("CreateMultiDropdown", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local selected = {}
	if opts.CurrentOptions then
		for _, v in ipairs(opts.CurrentOptions) do selected[v] = true end
	end
	local isOpen = false

	local wrapper = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Secondary,
		ClipsDescendants = false,
		ZIndex           = 5,
		Parent           = page,
	})
	Corner(wrapper)

	New("TextLabel", {
		Size                   = UDim2.new(0.42, 0, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Multi-Select",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 6,
		Parent                 = wrapper,
	})

	local function countStr()
		local n = 0
		for _ in pairs(selected) do n += 1 end
		return n == 0 and "None" or (n .. " selected")
	end

	local selLbl = New("TextLabel", {
		Size                   = UDim2.new(0.52, -24, 1, 0),
		Position               = UDim2.new(0.44, 0, 0, 0),
		BackgroundTransparency = 1,
		Text                   = countStr(),
		TextColor3             = th.Accent,
		TextSize               = 12,
		TextXAlignment         = Enum.TextXAlignment.Right,
		ZIndex                 = 6,
		Parent                 = wrapper,
	})
	BindTheme(win, selLbl, "TextColor3", "Accent")

	local arrow = New("TextLabel", {
		Size                   = UDim2.new(0, 18, 1, 0),
		Position               = UDim2.new(1, -20, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "▾",
		TextColor3             = th.TextDim,
		TextSize               = 14,
		ZIndex                 = 6,
		Parent                 = wrapper,
	})

	local listFrame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		Position         = UDim2.new(0, 0, 1, 5),
		BackgroundColor3 = th.Secondary,
		Visible          = false,
		ZIndex           = 20,
		Parent           = wrapper,
	})
	Corner(listFrame)
	Stroke(listFrame, th.Accent, 1.2, 0.25)
	local listLayout = New("UIListLayout", { Padding = UDim.new(0, 2), Parent = listFrame })
	Pad(listFrame, 4, 4, 4, 4)

	local function fireCallback()
		local result = {}
		for v, on in pairs(selected) do if on then table.insert(result, v) end end
		if opts.Callback then pcall(opts.Callback, result) end
		if opts.Flag     then win.Flags[opts.Flag] = result end
		selLbl.Text = countStr()
	end

	local function rebuildList()
		for _, c in listFrame:GetChildren() do
			if c:IsA("Frame") then c:Destroy() end
		end
		for _, opt in ipairs(opts.Options or {}) do
			local row = New("Frame", {
				Size             = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				ZIndex           = 21,
				Parent           = listFrame,
			})
			local checkBg = New("Frame", {
				Size             = UDim2.new(0, 16, 0, 16),
				Position         = UDim2.new(0, 6, 0.5, 0),
				AnchorPoint      = Vector2.new(0, 0.5),
				BackgroundColor3 = selected[opt] and th.Accent or th.Tertiary,
				ZIndex           = 22,
				Parent           = row,
			})
			Corner(checkBg, 4)
			Stroke(checkBg, th.Border, 1, 0.2)
			New("TextLabel", {
				Size                   = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text                   = selected[opt] and "✓" or "",
				TextColor3             = Color3.new(1,1,1),
				TextSize               = 10,
				ZIndex                 = 23,
				Parent                 = checkBg,
			})

			local optLbl = New("TextButton", {
				Size                   = UDim2.new(1, -30, 1, 0),
				Position               = UDim2.new(0, 28, 0, 0),
				BackgroundTransparency = 1,
				Text                   = opt,
				TextColor3             = th.Text,
				TextSize               = 13,
				TextXAlignment         = Enum.TextXAlignment.Left,
				ZIndex                 = 22,
				Parent                 = row,
			})
			local function toggle()
				selected[opt] = not selected[opt]
				Tween(checkBg, { BackgroundColor3 = selected[opt] and th.Accent or th.Tertiary })
				local checkmark = checkBg:FindFirstChildWhichIsA("TextLabel")
				if checkmark then checkmark.Text = selected[opt] and "✓" or "" end
				fireCallback()
			end
			optLbl.MouseButton1Click:Connect(toggle)
			row.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
			end)
			row.MouseEnter:Connect(function() Tween(row, { BackgroundTransparency = 0, BackgroundColor3 = th.Tertiary }) end)
			row.MouseLeave:Connect(function() Tween(row, { BackgroundTransparency = 1 }) end)
		end
		coroutine.wrap(function()
			if RunService then RunService.Heartbeat:Wait() end
			if listLayout and listFrame and listFrame.Parent then
				listFrame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
			end
		end)()
	end
	rebuildList()

	wrapper.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			isOpen            = not isOpen
			listFrame.Visible = isOpen
			Tween(arrow, { Rotation = isOpen and 180 or 0 })
		end
	end)
	wrapper.MouseEnter:Connect(function() Tween(wrapper, { BackgroundColor3 = th.Tertiary }) end)
	wrapper.MouseLeave:Connect(function()
		if not isOpen then Tween(wrapper, { BackgroundColor3 = th.Secondary }) end
	end)
	AttachTooltip(win, wrapper, opts.Tooltip)
	RegElement(self, opts.Name or "MultiDropdown", wrapper)

	return {
		GetSelected = function()
			local r = {}
			for v, on in pairs(selected) do if on then table.insert(r, v) end end
			return r
		end,
		SetSelected = function(list)
			selected = {}
			for _, v in ipairs(list) do selected[v] = true end
			rebuildList(); selLbl.Text = countStr()
		end,
		Refresh    = function(newOpts) opts.Options = newOpts; rebuildList() end,
		SetVisible = function(v) wrapper.Visible = v end,
		Destroy    = function() wrapper:Destroy() end,
	}
end

-- ── Button ───────────────────────────────────────────────────
function Simpliciton:CreateButton(opts)
	DBG("CreateButton", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local btn = New("TextButton", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Accent,
		Text             = opts.Name or "Button",
		TextColor3       = Color3.new(1,1,1),
		TextSize         = 13,
		Font             = Enum.Font.GothamSemibold,
		Parent           = page,
	})
	Corner(btn)
	BindTheme(win, btn, "BackgroundColor3", "Accent")

	local enabled = true
	btn.MouseButton1Click:Connect(function()
		if not enabled then return end
		Tween(btn, { BackgroundColor3 = Color3.new(1,1,1) }, TI_FAST)
		task.spawn(function()
			task.wait(0.08)
			Tween(btn, { BackgroundColor3 = th.Accent }, TI_MID)
		end)
		if opts.Callback then pcall(opts.Callback) end
	end)
	btn.MouseEnter:Connect(function()
		if enabled then Tween(btn, { BackgroundColor3 = Lighten(th.Accent, 24) }) end
	end)
	btn.MouseLeave:Connect(function()
		if enabled then Tween(btn, { BackgroundColor3 = th.Accent }) end
	end)
	AttachTooltip(win, btn, opts.Tooltip)
	RegElement(self, opts.Name or "Button", btn)

	return {
		Fire       = function() if opts.Callback then pcall(opts.Callback) end end,
		SetText    = function(t) btn.Text = t end,
		SetEnabled = function(v)
			enabled = v
			Tween(btn, { BackgroundTransparency = v and 0 or 0.5 })
		end,
		SetVisible = function(v) btn.Visible = v end,
		Destroy    = function() btn:Destroy() end,
	}
end

-- ── TextInput ────────────────────────────────────────────────
function Simpliciton:CreateInput(opts)
	DBG("CreateInput", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(0.4, 0, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Input",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local box = New("TextBox", {
		Size              = UDim2.new(0.58, -10, 0, 28),
		Position          = UDim2.new(0.42, 0, 0.5, 0),
		AnchorPoint       = Vector2.new(0, 0.5),
		BackgroundColor3  = th.Tertiary,
		PlaceholderText   = opts.Placeholder  or "Type here…",
		PlaceholderColor3 = th.TextDim,
		Text              = opts.CurrentValue or "",
		TextColor3        = th.Text,
		TextSize          = 13,
		ClearTextOnFocus  = false,
		Parent            = frame,
	})
	Corner(box, 6)
	Pad(box, 8, 8, 0, 0)

	local activeStroke
	box.Focused:Connect(function()
		activeStroke = Stroke(box, th.Accent, 1.4, 0)
	end)
	box.FocusLost:Connect(function()
		if activeStroke then activeStroke:Destroy(); activeStroke = nil end
		if opts.Callback then pcall(opts.Callback, box.Text) end
		if opts.Flag     then win.Flags[opts.Flag] = box.Text end
	end)

	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = th.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = th.Secondary }) end)
	AttachTooltip(win, frame, opts.Tooltip)
	RegElement(self, opts.Name or "Input", frame)

	return {
		Set        = function(v) box.Text = v end,
		Get        = function() return box.Text end,
		SetVisible = function(v) frame.Visible = v end,
		Destroy    = function() frame:Destroy() end,
	}
end

-- ── Keybind ──────────────────────────────────────────────────
-- Modes: "Toggle" (default) – fires callback once per press
--        "Hold"   – fires onHold(true) on press, onHold(false) on release
function Simpliciton:CreateKeybind(opts)
	DBG("CreateKeybind", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local mode       = opts.Mode or "Toggle"   -- "Toggle" | "Hold"
	local currentKey = opts.CurrentKeybind or Enum.KeyCode.Unknown
	local listening  = false
	local heldDown   = false

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(1, -130, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Keybind",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	-- Mode badge
	local modeLbl = New("TextLabel", {
		Size                   = UDim2.new(0, 44, 0, 20),
		Position               = UDim2.new(1, -148, 0.5, 0),
		AnchorPoint            = Vector2.new(0, 0.5),
		BackgroundColor3       = th.Tertiary,
		Text                   = mode,
		TextColor3             = th.TextDim,
		TextSize               = 10,
		Font                   = Enum.Font.GothamBold,
		Parent                 = frame,
	})
	Corner(modeLbl, 4)

	local bindBtn = New("TextButton", {
		Size             = UDim2.new(0, 92, 0, 28),
		Position         = UDim2.new(1, -102, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = th.Tertiary,
		Text             = currentKey ~= Enum.KeyCode.Unknown and currentKey.Name or "None",
		TextColor3       = th.Text,
		TextSize         = 12,
		Parent           = frame,
	})
	Corner(bindBtn, 6)

	bindBtn.MouseButton1Click:Connect(function()
		if listening then return end
		listening     = true
		bindBtn.Text  = "[ … ]"
		Tween(bindBtn, { BackgroundColor3 = th.Accent })
	end)
	bindBtn.MouseEnter:Connect(function()
		if not listening then Tween(bindBtn, { BackgroundColor3 = Lighten(th.Tertiary, 12) }) end
	end)
	bindBtn.MouseLeave:Connect(function()
		if not listening then Tween(bindBtn, { BackgroundColor3 = th.Tertiary }) end
	end)

	local cBind = UserInputService.InputBegan:Connect(function(i, gp)
		if gp then return end
		if listening and i.UserInputType == Enum.UserInputType.Keyboard
			and i.KeyCode ~= Enum.KeyCode.Unknown then
			currentKey    = i.KeyCode
			bindBtn.Text  = currentKey.Name
			listening     = false
			Tween(bindBtn, { BackgroundColor3 = th.Tertiary })
			if opts.Callback then pcall(opts.Callback, currentKey) end
			if opts.Flag     then win.Flags[opts.Flag] = currentKey.Name end
			return
		end
		-- Hold / Toggle
		if not listening and currentKey ~= Enum.KeyCode.Unknown and i.KeyCode == currentKey then
			if mode == "Hold" then
				heldDown = true
				if opts.OnHold then pcall(opts.OnHold, true) end
			elseif mode == "Toggle" then
				if opts.Callback then pcall(opts.Callback, currentKey) end
			end
		end
	end)
	local cRelease = UserInputService.InputEnded:Connect(function(i)
		if mode == "Hold" and i.KeyCode == currentKey and heldDown then
			heldDown = false
			if opts.OnHold then pcall(opts.OnHold, false) end
		end
	end)
	table.insert(win.Connections, cBind)
	table.insert(win.Connections, cRelease)

	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = th.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = th.Secondary }) end)
	AttachTooltip(win, frame, opts.Tooltip)
	RegElement(self, opts.Name or "Keybind", frame)

	return {
		Set        = function(k) currentKey = k; bindBtn.Text = k.Name end,
		Get        = function() return currentKey end,
		SetMode    = function(m) mode = m; modeLbl.Text = m end,
		SetVisible = function(v) frame.Visible = v end,
		Destroy    = function() frame:Destroy() end,
	}
end

-- ── Progress Bar ─────────────────────────────────────────────
function Simpliciton:CreateProgress(opts)
	DBG("CreateProgress", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local min   = opts.Min   or 0
	local max   = opts.Max   or 100
	local value = math.clamp(opts.CurrentValue or 0, min, max)

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(1, -70, 0, 22),
		Position               = UDim2.new(0, 14, 0, 4),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Progress",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local pctLbl = New("TextLabel", {
		Size                   = UDim2.new(0, 54, 0, 22),
		Position               = UDim2.new(1, -62, 0, 4),
		BackgroundTransparency = 1,
		Text                   = "0%",
		TextColor3             = th.Accent,
		TextSize               = 12,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Right,
		Parent                 = frame,
	})
	BindTheme(win, pctLbl, "TextColor3", "Accent")

	local track = New("Frame", {
		Size             = UDim2.new(1, -28, 0, 6),
		Position         = UDim2.new(0, 14, 0, 34),
		BackgroundColor3 = th.Tertiary,
		Parent           = frame,
	})
	Corner(track, 3)

	local fill = New("Frame", {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = th.Accent,
		Parent           = track,
	})
	Corner(fill, 3)
	BindTheme(win, fill, "BackgroundColor3", "Accent")

	local function update(v, animate)
		value = math.clamp(v, min, max)
		local pct = (value - min) / (max - min)
		if animate then
			Tween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, TI_MID)
		else
			fill.Size = UDim2.new(pct, 0, 1, 0)
		end
		pctLbl.Text = math.floor(pct * 100) .. "%"
	end
	update(value, false)
	RegElement(self, opts.Name or "Progress", frame)

	return {
		Set        = function(v) update(v, true) end,
		Get        = function() return value end,
		SetVisible = function(v) frame.Visible = v end,
		Destroy    = function() frame:Destroy() end,
	}
end

-- ── Color Picker (full HSV) ───────────────────────────────────
-- • Hue bar       – pick the colour family
-- • SV square     – pick saturation (X) and value/brightness (Y)
-- • Hex input     – read or type a hex code
-- • Live preview  – updates in real-time
function Simpliciton:CreateColorPicker(opts)
	DBG("CreateColorPicker", "called")
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	local th = GetTheme(self)
	opts = opts or {}

	local startColor = opts.Color or opts.CurrentValue or Color3.fromRGB(230, 80, 80)
	local h0, s0, v0 = Color3.toHSV(startColor)
	local hue, sat, val = h0, s0, v0

	-- Header row (always visible, click to open picker)
	local header = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Secondary,
		Parent           = page,
	})
	Corner(header)

	New("TextLabel", {
		Size                   = UDim2.new(1, -70, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = opts.Name or "Color",
		TextColor3             = th.Text,
		TextSize               = 13,
		Font                   = Enum.Font.GothamMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = header,
	})

	local preview = New("Frame", {
		Size             = UDim2.new(0, 36, 0, 26),
		Position         = UDim2.new(1, -50, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = startColor,
		Parent           = header,
	})
	Corner(preview, 6)
	Stroke(preview, Color3.new(1,1,1), 1, 0.6)

	local arrowLbl = New("TextLabel", {
		Size                   = UDim2.new(0, 14, 1, 0),
		Position               = UDim2.new(1, -14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "▾",
		TextColor3             = th.TextDim,
		TextSize               = 14,
		Parent                 = header,
	})

	-- Picker panel (expandable)
	local panel = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = th.Secondary,
		Visible          = false,
		Parent           = page,
	})
	Corner(panel)
	Pad(panel, 12, 12, 10, 14)
	VList(panel, 10)

	-- ── SV square ────────────────────────────────────────
	local svBox = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 150),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		ClipsDescendants = false,
		Parent           = panel,
	})
	Corner(svBox, 6)

	-- White → transparent overlay (horizontal: left=white, right=hue)
	local satLayer = New("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1,1,1),
		ClipsDescendants = false,
		ZIndex           = 2,
		Parent           = svBox,
	})
	Corner(satLayer, 6)
	New("UIGradient", {
		Color        = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(1,1,1)) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Rotation     = 0,
		Parent       = satLayer,
	})

	-- Transparent → black overlay (vertical: top=transparent, bottom=black)
	local valLayer = New("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		ZIndex           = 3,
		Parent           = svBox,
	})
	Corner(valLayer, 6)
	New("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
		Rotation     = 90,
		Parent       = valLayer,
	})

	-- SV knob
	local svKnob = New("Frame", {
		Size             = UDim2.new(0, 14, 0, 14),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(sat, 0, 1 - val, 0),
		BackgroundColor3 = Color3.new(1,1,1),
		ZIndex           = 10,
		Parent           = svBox,
	})
	Corner(svKnob, 7)
	New("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1.5, Transparency = 0.3, Parent = svKnob })

	-- ── Hue bar ──────────────────────────────────────────
	local hueBar = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 16),
		BackgroundColor3 = Color3.new(1,0,0),
		Parent           = panel,
	})
	Corner(hueBar, 4)

	-- Full spectrum gradient
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,     Color3.fromHSV(0,      1, 1)),
			ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167,  1, 1)),
			ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333,  1, 1)),
			ColorSequenceKeypoint.new(0.500, Color3.fromHSV(0.500,  1, 1)),
			ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667,  1, 1)),
			ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833,  1, 1)),
			ColorSequenceKeypoint.new(1,     Color3.fromHSV(0.9999, 1, 1)),
		}),
		Parent = hueBar,
	})

	local hueKnob = New("Frame", {
		Size             = UDim2.new(0, 8, 1, 4),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(hue, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1,1,1),
		ZIndex           = 5,
		Parent           = hueBar,
	})
	Corner(hueKnob, 3)
	New("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1.2, Transparency = 0.4, Parent = hueKnob })

	-- ── Hex input ────────────────────────────────────────
	local hexRow = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Parent           = panel,
	})
	New("TextLabel", {
		Size                   = UDim2.new(0, 30, 1, 0),
		BackgroundTransparency = 1,
		Text                   = "HEX",
		TextColor3             = th.TextDim,
		TextSize               = 11,
		Font                   = Enum.Font.GothamBold,
		Parent                 = hexRow,
	})
	local hexBox = New("TextBox", {
		Size              = UDim2.new(0, 90, 1, -6),
		Position          = UDim2.new(0, 32, 0, 3),
		BackgroundColor3  = th.Tertiary,
		Text              = string.format("#%02X%02X%02X",
			math.floor(startColor.R*255),
			math.floor(startColor.G*255),
			math.floor(startColor.B*255)),
		TextColor3        = th.Text,
		TextSize          = 12,
		ClearTextOnFocus  = false,
		PlaceholderText   = "#RRGGBB",
		PlaceholderColor3 = th.TextDim,
		Parent            = hexRow,
	})
	Corner(hexBox, 5)
	Pad(hexBox, 8, 8, 0, 0)

	local finalColorPreview = New("Frame", {
		Size             = UDim2.new(0, 32, 1, -6),
		Position         = UDim2.new(0, 130, 0, 3),
		BackgroundColor3 = startColor,
		Parent           = hexRow,
	})
	Corner(finalColorPreview, 5)
	Stroke(finalColorPreview, Color3.new(1,1,1), 1, 0.6)

	-- ── Central rebuild function ──────────────────────────
	local function rebuild()
		local color = Color3.fromHSV(hue, sat, val)
		preview.BackgroundColor3      = color
		finalColorPreview.BackgroundColor3 = color
		svBox.BackgroundColor3        = Color3.fromHSV(hue, 1, 1)
		svKnob.Position               = UDim2.new(sat, 0, 1 - val, 0)
		hueKnob.Position              = UDim2.new(hue, 0, 0.5, 0)
		hexBox.Text = string.format("#%02X%02X%02X",
			math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
		if opts.Callback then pcall(opts.Callback, color) end
		if opts.Flag     then win.Flags[opts.Flag] = color end
	end

	-- ── SV drag (Rayfield-style: Stepped loop + GetMouse) ──────
	local svDragging = false
	local cpMouse = LocalPlayer and LocalPlayer:GetMouse()
	local function applySV(x, y)
		sat = math.clamp((x - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
		val = 1 - math.clamp((y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
		rebuild()
	end
	svBox.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		svDragging = true
		applySV(i.Position.X, i.Position.Y)
		local loop; loop = RunService and RunService.Stepped:Connect(function()
			if not svDragging then loop:Disconnect() return end
			if cpMouse then applySV(cpMouse.X, cpMouse.Y) end
		end)
		if loop then table.insert(win.Connections, loop) end
	end)
	local cSV2 = UserInputService and UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
	end)
	if cSV2 then table.insert(win.Connections, cSV2) end

	-- ── Hue drag (Stepped loop) ─────────────────────────────────
	local hueDragging = false
	local function applyHue(x)
		hue = math.clamp((x - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.9999)
		rebuild()
	end
	hueBar.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		hueDragging = true
		applyHue(i.Position.X)
		local loop; loop = RunService and RunService.Stepped:Connect(function()
			if not hueDragging then loop:Disconnect() return end
			if cpMouse then applyHue(cpMouse.X) end
		end)
		if loop then table.insert(win.Connections, loop) end
	end)
	local cH2 = UserInputService and UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
	end)
	if cH2 then table.insert(win.Connections, cH2) end

	-- ── Hex input ─────────────────────────────────────────
	hexBox.FocusLost:Connect(function()
		local text = hexBox.Text:gsub("#",""):upper()
		if #text == 6 then
			local r = tonumber(text:sub(1,2), 16)
			local g = tonumber(text:sub(3,4), 16)
			local b = tonumber(text:sub(5,6), 16)
			if r and g and b then
				local c = Color3.fromRGB(r, g, b)
				hue, sat, val = Color3.toHSV(c)
				rebuild()
			end
		end
	end)

	-- ── Toggle open/close ─────────────────────────────────
	local open = false
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			open          = not open
			panel.Visible = open
			arrowLbl.Text = open and "▴" or "▾"
		end
	end)
	header.MouseEnter:Connect(function() Tween(header, { BackgroundColor3 = th.Tertiary }) end)
	header.MouseLeave:Connect(function() Tween(header, { BackgroundColor3 = th.Secondary }) end)
	AttachTooltip(win, header, opts.Tooltip)
	RegElement(self, opts.Name or "Color", header)

	return {
		Set = function(c)
			hue, sat, val = Color3.toHSV(c)
			preview.BackgroundColor3 = c
			rebuild()
		end,
		Get        = function() return Color3.fromHSV(hue, sat, val) end,
		SetVisible = function(v) header.Visible = v; if not v then panel.Visible = false; open = false end end,
		Destroy    = function() header:Destroy(); panel:Destroy() end,
	}
end

-- ============================================================
--  NOTIFICATIONS (auto-stacking)
-- ============================================================

function Simpliciton:Notify(titleOrData, content, duration, notifType)
	-- Accept Rayfield table-style: Notify({Title=, Content=, Duration=}) OR positional
	local title = titleOrData
	if type(titleOrData) == "table" then
		title     = titleOrData.Title    or titleOrData.title    or "Notice"
		content   = titleOrData.Content  or titleOrData.content  or ""
		duration  = titleOrData.Duration or titleOrData.duration or 4
		notifType = titleOrData.Type     or notifType
	end
	DBG("Notify", tostring(title))
	duration  = duration  or 4
	notifType = notifType or "info"
	local th  = self.Theme

	local accent = (notifType == "success" and th.Success)
		or (notifType == "warning" and th.Warning)
		or (notifType == "error"   and th.Error)
		or th.Accent

	self._notifOrder = (self._notifOrder or 0) + 1

	local notif = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = th.Secondary,
		LayoutOrder      = self._notifOrder,
		BackgroundTransparency = 1,   -- start transparent, fade in
		Parent           = self._notifContainer,
	})
	Corner(notif)

	-- Coloured left stripe
	local stripe = New("Frame", {
		Size             = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel  = 0,
		ZIndex           = 2,
		Parent           = notif,
	})
	Corner(stripe, 3)

	-- Progress timer bar
	local timerBar = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 2),
		Position         = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.4,
		BorderSizePixel  = 0,
		ZIndex           = 3,
		Parent           = notif,
	})

	local inner = New("Frame", {
		Size                   = UDim2.new(1, -12, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		Position               = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		ZIndex                 = 2,
		Parent                 = notif,
	})
	VList(inner, 2)
	Pad(inner, 0, 6, 8, 10)

	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = title,
		TextColor3             = accent,
		TextSize               = 13,
		Font                   = Enum.Font.GothamBold,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		ZIndex                 = 3,
		Parent                 = inner,
	})
	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = content,
		TextColor3             = th.Text,
		TextSize               = 12,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		ZIndex                 = 3,
		Parent                 = inner,
	})

	-- Fade in
	Tween(notif, { BackgroundTransparency = 0 }, TI_MID)

	-- Timer shrinks the progress bar
	Tween(timerBar, { Size = UDim2.new(0, 0, 0, 2) },
		TweenInfo.new(duration, Enum.EasingStyle.Linear))

	-- Dismiss after duration
	task.spawn(function()
		task.wait(duration)
		if notif and notif.Parent then
			Tween(notif, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }, TI_MID)
			task.wait(0.3)
			if notif and notif.Parent then notif:Destroy() end
		end
	end)

	-- Allow clicking to dismiss early
	notif.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			Tween(notif, { BackgroundTransparency = 1 }, TI_FAST)
			task.spawn(function()
				task.wait(0.15)
				if notif and notif.Parent then notif:Destroy() end
			end)
		end
	end)
end

-- ============================================================
--  CONFIG SYSTEM
-- ============================================================

-- ── Filesystem helpers (Rayfield pattern: callSafely wrappers) ─
local function _fsCall(fn, ...)
	if not fn then return nil end
	local ok, r = pcall(fn, ...)
	if not ok then WARN("Filesystem", tostring(r)) return nil end
	return r
end

function Simpliciton:SaveConfig(fileName)
	if not self.ConfigSaving.Enabled then
		self:Notify("Config", "Config saving is disabled.", 3, "error")
		return
	end
	fileName = fileName or self.ConfigSaving.FileName
	local ok, data = pcall(HttpService.JSONEncode, HttpService, self.Flags)
	if not ok then
		self:Notify("Config Error", "Failed to encode flags.", 3, "error")
		return
	end
	if writefile and isfile then
		-- Executor environment: write to disk
		local folder = self.ConfigSaving.FolderName or "SimplicitonConfigs"
		if isfolder and not _fsCall(isfolder, folder) then
			_fsCall(makefolder, folder)
		end
		_fsCall(writefile, folder .. "/" .. fileName .. ".json", data)
		self:Notify("Saved!", "Config written to " .. folder .. "/" .. fileName .. ".json", 3, "success")
	else
		-- Fallback: print to console
		print("[Simpliciton] Config (no filesystem):\n" .. data)
		self:Notify("Saved!", "No filesystem available - flags printed to console.", 3, "info")
	end
end

function Simpliciton:LoadConfig(fileName)
	if not self.ConfigSaving.Enabled then return end
	fileName = fileName or self.ConfigSaving.FileName
	local folder = self.ConfigSaving.FolderName or "SimplicitonConfigs"
	local path   = folder .. "/" .. fileName .. ".json"

	if not (isfile and _fsCall(isfile, path)) then
		self:Notify("Config", "No saved config found for: " .. fileName, 3, "info")
		return
	end

	local raw = _fsCall(readfile, path)
	if not raw then
		self:Notify("Config Error", "Failed to read config file.", 3, "error")
		return
	end

	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok then
		self:Notify("Config Error", "Corrupt config file.", 3, "error")
		return
	end

	-- Apply all flag values
	for flagName, flagValue in pairs(data) do
		self.Flags[flagName] = flagValue
	end
	self:Notify("Loaded", "Config loaded from: " .. path, 3, "success")
end

-- ============================================================
--  BUILT-IN SETTINGS TAB
-- ============================================================

local ACCENT_PRESETS = {
	{ name = "Blue",    color = Color3.fromRGB(85,  170, 255) },
	{ name = "Purple",  color = Color3.fromRGB(148, 90,  255) },
	{ name = "Emerald", color = Color3.fromRGB(65,  210, 130) },
	{ name = "Rose",    color = Color3.fromRGB(255, 90,  145) },
	{ name = "Amber",   color = Color3.fromRGB(255, 175, 50 ) },
	{ name = "Cyan",    color = Color3.fromRGB(50,  205, 215) },
	{ name = "Coral",   color = Color3.fromRGB(255, 110, 85 ) },
}

local BG_PRESETS = {
	{ name = "Dark (Default)", bg = Color3.fromRGB(16,16,22),  sec = Color3.fromRGB(27,27,36),  ter = Color3.fromRGB(40,40,52)  },
	{ name = "Darker",         bg = Color3.fromRGB(10,10,14),  sec = Color3.fromRGB(18,18,24),  ter = Color3.fromRGB(28,28,36)  },
	{ name = "Slate",          bg = Color3.fromRGB(15,20,28),  sec = Color3.fromRGB(22,28,38),  ter = Color3.fromRGB(32,38,52)  },
	{ name = "Warm Dark",      bg = Color3.fromRGB(20,16,14),  sec = Color3.fromRGB(30,24,20),  ter = Color3.fromRGB(44,36,30)  },
}

function Simpliciton:_BuildSettingsTab()
	local tab = self:CreateTab("⚙  Settings")

	-- ── Appearance ───────────────────────────────────────
	tab:CreateSection("Accent Color")

	-- Accent colour swatches
	local swatchRow = New("Frame", {
		Size                   = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent                 = tab.Page,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding       = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent        = swatchRow,
	})

	for _, preset in ipairs(ACCENT_PRESETS) do
		local sw = New("TextButton", {
			Size             = UDim2.new(0, 30, 0, 30),
			BackgroundColor3 = preset.color,
			Text             = "",
			AutoButtonColor  = false,
			Parent           = swatchRow,
		})
		Corner(sw, 8)
		sw.MouseButton1Click:Connect(function()
			self.Theme.Accent = preset.color
			self:SetTheme({ Accent = preset.color })
			self:Notify("Theme", "Accent: " .. preset.name, 2, "success")
		end)
		sw.MouseEnter:Connect(function()
			Tween(sw, { Size = UDim2.new(0, 34, 0, 34) }, TI_MID)
		end)
		sw.MouseLeave:Connect(function()
			Tween(sw, { Size = UDim2.new(0, 30, 0, 30) }, TI_MID)
		end)
	end

	tab:CreateToggle({
		Name         = "Rainbow Mode",
		CurrentValue = false,
		Tooltip      = "Cycles accent color through the full spectrum",
		Callback = function(on)
			if on then
				if self.RainbowThread then self.RainbowThread:Disconnect() end
				self.RainbowThread = RunService.Heartbeat:Connect(function()
					local c = Color3.fromHSV((tick() * 0.12) % 1, 0.85, 1)
					self.Theme.Accent = c
					-- Directly update accent-bound instances without full SetTheme (performance)
					for _, binding in ipairs(self.ThemedInstances) do
						local inst, prop, key = binding[1], binding[2], binding[3]
						if key == "Accent" and inst and inst.Parent then
							pcall(function() inst[prop] = c end)
						end
					end
					if self.CurrentTab and self.CurrentTab.ActiveBar then
						self.CurrentTab.ActiveBar.BackgroundColor3 = c
					end
					if self.Header then self.Header.BackgroundColor3 = c end
				end)
			else
				if self.RainbowThread then
					self.RainbowThread:Disconnect()
					self.RainbowThread = nil
				end
				self:SetTheme({ Accent = Color3.fromRGB(85, 170, 255) })
			end
		end,
	})

	tab:CreateSection("Background")

	local bgNames = {}
	for _, p in ipairs(BG_PRESETS) do table.insert(bgNames, p.name) end

	tab:CreateDropdown({
		Name    = "Background Style",
		Options = bgNames,
		CurrentOption = bgNames[1],
		Tooltip = "Choose a background color palette",
		Callback = function(choice)
			for _, p in ipairs(BG_PRESETS) do
				if p.name == choice then
					self:SetTheme({
						Background = p.bg,
						Secondary  = p.sec,
						Tertiary   = p.ter,
					})
					break
				end
			end
		end,
	})

	-- ── Configuration ────────────────────────────────────
	tab:CreateSection("Configuration")

	local cfgGroup = tab:CreateGroup("File Settings", false)

	cfgGroup:CreateInput({
		Name         = "Config Name",
		Placeholder  = "Simpliciton_Config.json",
		CurrentValue = self.ConfigSaving.FileName,
		Tooltip      = "Filename used for save/load",
		Callback = function(v)
			if v ~= "" then self.ConfigSaving.FileName = v end
		end,
	})

	cfgGroup:CreateButton({
		Name     = "💾  Save Config",
		Tooltip  = "Serialise all Flags to JSON",
		Callback = function() self:SaveConfig() end,
	})

	cfgGroup:CreateButton({
		Name     = "📂  Load Config",
		Tooltip  = "Load Flags from saved file",
		Callback = function() self:LoadConfig() end,
	})

	-- ── Visibility ───────────────────────────────────────
	tab:CreateSection("Window")

	tab:CreateKeybind({
		Name           = "Toggle UI Keybind",
		CurrentKeybind = Enum.KeyCode.RightShift,
		Mode           = "Toggle",
		Tooltip        = "Press this key to show/hide the window",
		Callback = function(key)
			self:SetKeybind(key)
			self:Notify("Keybind", "UI toggle set to: " .. key.Name, 2)
		end,
	})

	tab:CreateButton({
		Name     = "Set Watermark",
		Tooltip  = "Adds a floating info label to the screen",
		Callback = function()
			self:SetWatermark(self.Name, "v3.0")
			self:Notify("Watermark", "Watermark added. Drag to reposition.", 3, "success")
		end,
	})

	-- ── Info ─────────────────────────────────────────────
	tab:CreateSection("About")

	tab:CreateParagraph({
		Title   = "Simpliciton  v3.3",
		Content = "Full-featured Roblox UI framework.\n"
			.. "Rayfield-patterned: cloneref services, Stepped-loop dragging, "
			.. "task.spawn notifications, filesystem config, live theming, "
			.. "HSV color picker, multi-dropdown, group containers, tooltips.",
	})
end

-- ============================================================
--  CLEANUP + ALIASES (matching Rayfield API surface)
-- ============================================================

-- Rayfield-compatible aliases
function Simpliciton:LoadConfiguration()
	self:LoadConfig()
end

function Simpliciton:SetVisibility(v)
	self._visible = v
	if self.MainFrame then self.MainFrame.Visible = v end
	if self._shadow   then self._shadow.Visible   = v end
end

function Simpliciton:IsVisible()
	return self._visible ~= false
end

function Simpliciton:Destroy()
	-- Stop rainbow
	if self.RainbowThread then
		pcall(function() self.RainbowThread:Disconnect() end)
		self.RainbowThread = nil
	end
	-- Disconnect all tracked connections
	for _, c in ipairs(self.Connections or {}) do
		pcall(function() c:Disconnect() end)
	end
	-- Destroy GUI
	if self.ScreenGui and self.ScreenGui.Parent then
		pcall(function() self.ScreenGui:Destroy() end)
	end
end

-- ============================================================
--  ELEMENT REGISTRY  (for external modules to extend the lib)
-- ============================================================

--- Register a new element type callable as  tab:CreateX(opts)
---   name        : PascalCase method name, e.g. "CreateGraph"
---   constructor : function(self, opts) → handle
function Simpliciton.Elements.Register(name, constructor)
	assert(type(name) == "string",   "Element name must be a string")
	assert(type(constructor) == "function", "Constructor must be a function")
	Simpliciton[name] = constructor
end

-- ============================================================
--  EXAMPLE USAGE  (uncomment in executor)
-- ============================================================
--[[

local UI = loadstring(game:HttpGet("URL"))()  -- or require()

-- Create window
local Window = UI:CreateWindow({
    Name = "My Script",
    ConfigurationSaving = { Enabled = true, FileName = "MyScript.json" },
})

-- Add toggle keybind
Window:SetKeybind(Enum.KeyCode.RightShift)

-- Add a tab
local Main = Window:CreateTab("Main", 4483362458)
Main:EnableSearch()

-- Section + elements
Main:CreateSection("Player")

local speedToggle = Main:CreateToggle({
    Name         = "Infinite Speed",
    CurrentValue = false,
    Flag         = "Speed_Enabled",
    Tooltip      = "Multiplies walkspeed",
    Callback     = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v and 100 or 16
    end,
})

local speedSlider = Main:CreateSlider({
    Name         = "WalkSpeed",
    Min          = 16,
    Max          = 250,
    Decimals     = 0,
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Tooltip      = "Character movement speed",
    Callback     = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end,
})

-- Group example
local combatGroup = Main:CreateGroup("Combat Options")
combatGroup:CreateToggle({ Name = "Auto-Aim", Flag = "AutoAim" })
combatGroup:CreateSlider({ Name = "FOV", Min = 10, Max = 150, CurrentValue = 70, Flag = "FOV" })

-- Multi-select dropdown
Main:CreateMultiDropdown({
    Name    = "Target Filters",
    Options = { "Players", "NPCs", "Bosses", "Allies" },
    Tooltip = "Select which entities to target",
    Flag    = "TargetFilters",
    Callback = function(selected)
        print("Selected:", table.concat(selected, ", "))
    end,
})

-- Progress bar
local progressBar = Main:CreateProgress({
    Name         = "Quest Progress",
    CurrentValue = 64,
    Min          = 0,
    Max          = 100,
})
progressBar.Set(85)   -- animate to 85%

-- Color picker
Main:CreateColorPicker({
    Name         = "ESP Color",
    CurrentValue = Color3.fromRGB(255, 100, 100),
    Flag         = "ESP_Color",
    Callback     = function(c) print("Color:", c) end,
})

-- Keybind with hold mode
Main:CreateKeybind({
    Name   = "Boost",
    Mode   = "Hold",
    OnHold = function(held)
        local hum = game.Players.LocalPlayer.Character.Humanoid
        hum.WalkSpeed = held and 60 or 16
    end,
})

-- Custom element via registry
UI.Elements.Register("CreateCoolButton", function(self, opts)
    -- your custom element logic
    return self:CreateButton(opts)
end)
local tab2 = Window:CreateTab("Visuals")
tab2:CreateCoolButton({ Name = "Flash!", Callback = function() print("Flash!") end })

-- Notification
Window:Notify("Ready", "Script loaded successfully.", 4, "success")

--]]

return Simpliciton
