--[[
	╔══════════════════════════════════════════════════════════════╗
	║          Simpliciton  v5.0  "Glass"                         ║
	║          Premium glass-morphism UI library for Roblox       ║
	╠══════════════════════════════════════════════════════════════╣
	║  CHANGES FROM v4:                                           ║
	║  • Shadow frame completely removed                          ║
	║  • Tabs moved to bottom navigation bar with icons           ║
	║  • Semi-transparent glass aesthetic (configurable)          ║
	║  • Slider: click value label to type exact number           ║
	║  • Notifications: image IDs, emoji icons, progress bar      ║
	║  • Button: styles (Accent/Secondary/Danger/Ghost), loading  ║
	║  • Toggle: optional description text, springy animation     ║
	║  • Dropdown: optional search/filter bar                     ║
	║  • Input: live callback, MaxLength counter, clear button    ║
	║  • ColorPicker: R/G/B inputs, alpha slider, better layout   ║
	║  • New themes: Midnight (purple), Neon (teal)               ║
	║  • New element: CreateProgressBar                           ║
	║  • New element: CreateBadge (inline stat chips)             ║
	║  • Keybind: full rework, Escape to clear                    ║
	║  • Config save button in topbar                             ║
	║  • Window subtitle support                                  ║
	╠══════════════════════════════════════════════════════════════╣
	║  API QUICK REFERENCE:                                       ║
	║                                                             ║
	║  local Lib = loadstring(...)()                              ║
	║  local Win = Lib:CreateWindow({                             ║
	║      Name     = "My Script",                                ║
	║      Subtitle = "v1.0",                                     ║
	║      Theme    = "Dark",  -- Dark/Light/Midnight/Neon        ║
	║      Icon     = 0,       -- rbxassetid or 0                 ║
	║      ToggleUIKeybind    = Enum.KeyCode.RightShift,          ║
	║      ConfigurationSaving = {                                ║
	║          Enabled    = false,                                ║
	║          FolderName = "Simpliciton",                        ║
	║          FileName   = "config",                             ║
	║      },                                                     ║
	║  })                                                         ║
	║                                                             ║
	║  local Tab = Win:CreateTab("Home", "🏠")                    ║
	║                                                             ║
	║  Tab:CreateButton({ Name=, Description=, Style=,            ║
	║                     Callback= })                            ║
	║  Tab:CreateToggle({ Name=, Description=, CurrentValue=,     ║
	║                     Flag=, Callback= })                     ║
	║  Tab:CreateSlider({ Name=, Range={0,100}, Increment=1,      ║
	║                     Suffix="", CurrentValue=0,              ║
	║                     Decimals=0, Flag=, Callback= })         ║
	║  Tab:CreateDropdown({ Name=, Options={}, CurrentOption={},  ║
	║                       MultipleOptions=false,                ║
	║                       Searchable=false, Flag=, Callback= }) ║
	║  Tab:CreateInput({ Name=, CurrentValue="",                  ║
	║                    PlaceholderText="", MaxLength=0,         ║
	║                    NumbersOnly=false, LiveCallback=false,   ║
	║                    RemoveTextAfterFocusLost=false,          ║
	║                    Flag=, Callback= })                      ║
	║  Tab:CreateKeybind({ Name=, CurrentKeybind="",              ║
	║                      Flag=, Callback= })                    ║
	║  Tab:CreateColorPicker({ Name=, Color=Color3.new(1,1,1),    ║
	║                          Flag=, Callback= })                ║
	║  Tab:CreateProgressBar({ Name=, Value=0, Max=100,           ║
	║                          Suffix="%", Color= })              ║
	║  Tab:CreateSection("Title")                                 ║
	║  Tab:CreateDivider()                                        ║
	║  Tab:CreateLabel("Text")                                    ║
	║  Tab:CreateParagraph({ Title=, Content= })                  ║
	║                                                             ║
	║  Win:Notify({ Title=, Content=, Duration=4,                 ║
	║               Image=0, Type="" })  -- Type: success/error/  ║
	║                                        warning              ║
	║  Win:SaveConfiguration() / Win:LoadConfiguration()          ║
	║  Win:Destroy()                                              ║
	╚══════════════════════════════════════════════════════════════╝
]]

-- ── Services ─────────────────────────────────────────────────────────────────
local function getService(name)
	local ok, svc = pcall(game.GetService, game, name)
	if not ok then return nil end
	return (cloneref and cloneref(svc)) or svc
end

local TweenService     = getService("TweenService")
local UserInputService = getService("UserInputService")
local RunService       = getService("RunService")
local Players          = getService("Players")
local HttpService      = getService("HttpService")
local CoreGui          = getService("CoreGui")

local LocalPlayer = Players and Players.LocalPlayer
local Mouse       = LocalPlayer and LocalPlayer:GetMouse()

-- ── Utility helpers ───────────────────────────────────────────────────────────
local function callSafely(fn, ...)
	if not fn then return nil end
	local ok, r = pcall(fn, ...)
	if not ok then warn("[Simpliciton] " .. tostring(r)); return nil end
	return r
end

local function ensureFolder(path)
	if isfolder and not callSafely(isfolder, path) then
		callSafely(makefolder, path)
	end
end

local function Tween(obj, props, t, style, dir)
	if not obj or not obj.Parent then return end
	pcall(function()
		TweenService:Create(obj,
			TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
			props):Play()
	end)
end

local function Corner(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = f
	return c
end

local function Stroke(f, col, t, trans)
	local s = Instance.new("UIStroke")
	s.Color        = col   or Color3.new(1, 1, 1)
	s.Thickness    = t     or 1
	s.Transparency = trans or 0
	s.Parent = f
	return s
end

local function Pad(f, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft   = UDim.new(0, l or 0)
	p.PaddingRight  = UDim.new(0, r or 0)
	p.PaddingTop    = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = f
	return p
end

local function VList(f, pad, align)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, pad or 6)
	l.FillDirection = Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	if align then l.HorizontalAlignment = align end
	l.Parent = f
	return l
end

local function HList(f, pad, valign)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, pad or 6)
	l.FillDirection = Enum.FillDirection.Horizontal
	l.SortOrder = Enum.SortOrder.LayoutOrder
	if valign then l.VerticalAlignment = valign end
	l.Parent = f
	return l
end

local function AutoCanvas(scroll, list)
	pcall(function() scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
	local function update()
		if scroll and scroll.Parent then
			scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 18)
		end
	end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
end

local function New(class, props)
	local ok, inst = pcall(Instance.new, class)
	if not ok then return nil end
	for k, v in pairs(props or {}) do
		pcall(function() inst[k] = v end)
	end
	return inst
end

local function lerpColor(c1, c2, t)
	return Color3.new(
		c1.R + (c2.R - c1.R) * t,
		c1.G + (c2.G - c1.G) * t,
		c1.B + (c2.B - c1.B) * t
	)
end

local function brighten(c, amt)
	amt = amt or 20
	return Color3.fromRGB(
		math.clamp(math.floor(c.R * 255) + amt, 0, 255),
		math.clamp(math.floor(c.G * 255) + amt, 0, 255),
		math.clamp(math.floor(c.B * 255) + amt, 0, 255)
	)
end

-- ── Themes ────────────────────────────────────────────────────────────────────
local Themes = {
	Dark = {
		BG        = Color3.fromRGB(13,  13,  20 ),
		Surface   = Color3.fromRGB(20,  20,  30 ),
		Element   = Color3.fromRGB(28,  28,  40 ),
		ElementHv = Color3.fromRGB(36,  36,  52 ),
		Accent    = Color3.fromRGB(110, 165, 255),
		AccentDim = Color3.fromRGB(65,  105, 200),
		Text      = Color3.fromRGB(235, 235, 248),
		TextDim   = Color3.fromRGB(115, 115, 148),
		Border    = Color3.fromRGB(48,  48,  70 ),
		Success   = Color3.fromRGB(80,  220, 140),
		Warning   = Color3.fromRGB(255, 195, 55 ),
		Error     = Color3.fromRGB(255, 80,  80 ),
		BGAlpha   = 0.2,
		BarAlpha  = 0.08,
	},
	Light = {
		BG        = Color3.fromRGB(240, 240, 252),
		Surface   = Color3.fromRGB(255, 255, 255),
		Element   = Color3.fromRGB(232, 232, 246),
		ElementHv = Color3.fromRGB(218, 218, 236),
		Accent    = Color3.fromRGB(80,  130, 230),
		AccentDim = Color3.fromRGB(55,  95,  185),
		Text      = Color3.fromRGB(22,  22,  40 ),
		TextDim   = Color3.fromRGB(125, 125, 158),
		Border    = Color3.fromRGB(200, 200, 220),
		Success   = Color3.fromRGB(38,  175, 100),
		Warning   = Color3.fromRGB(215, 150, 30 ),
		Error     = Color3.fromRGB(215, 55,  55 ),
		BGAlpha   = 0.08,
		BarAlpha  = 0.03,
	},
	Midnight = {
		BG        = Color3.fromRGB(8,   6,   18 ),
		Surface   = Color3.fromRGB(14,  10,  28 ),
		Element   = Color3.fromRGB(22,  16,  40 ),
		ElementHv = Color3.fromRGB(30,  22,  56 ),
		Accent    = Color3.fromRGB(165, 110, 255),
		AccentDim = Color3.fromRGB(110, 65,  200),
		Text      = Color3.fromRGB(230, 220, 255),
		TextDim   = Color3.fromRGB(120, 105, 165),
		Border    = Color3.fromRGB(45,  35,  75 ),
		Success   = Color3.fromRGB(80,  220, 160),
		Warning   = Color3.fromRGB(255, 200, 60 ),
		Error     = Color3.fromRGB(255, 80,  100),
		BGAlpha   = 0.22,
		BarAlpha  = 0.10,
	},
	Neon = {
		BG        = Color3.fromRGB(6,   12,  16 ),
		Surface   = Color3.fromRGB(10,  20,  26 ),
		Element   = Color3.fromRGB(14,  28,  36 ),
		ElementHv = Color3.fromRGB(18,  36,  46 ),
		Accent    = Color3.fromRGB(0,   235, 175),
		AccentDim = Color3.fromRGB(0,   160, 120),
		Text      = Color3.fromRGB(215, 255, 245),
		TextDim   = Color3.fromRGB(90,  155, 138),
		Border    = Color3.fromRGB(28,  65,  58 ),
		Success   = Color3.fromRGB(0,   235, 175),
		Warning   = Color3.fromRGB(255, 210, 60 ),
		Error     = Color3.fromRGB(255, 80,  80 ),
		BGAlpha   = 0.18,
		BarAlpha  = 0.08,
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
--  LIBRARY
-- ═══════════════════════════════════════════════════════════════════════════════
local Simpliciton = {}
Simpliciton.__index = Simpliciton
Simpliciton.Flags   = {}
Simpliciton.Version = "5.0"

-- ── GUI parent (proven priority chain) ────────────────────────────────────────
local function getGuiParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	if syn and syn.protect_gui then return CoreGui end
	local ok, rg = pcall(function() return CoreGui:FindFirstChild("RobloxGui") end)
	if ok and rg then return rg end
	if CoreGui then return CoreGui end
	return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

-- ── Draggable (RenderStepped pattern) ─────────────────────────────────────────
local function makeDraggable(frame, handle)
	local dragging = false
	local relative = Vector2.new()

	handle.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
		   input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true
		relative = frame.AbsolutePosition + frame.AbsoluteSize * frame.AnchorPoint
			- UserInputService:GetMouseLocation()
	end)

	local iEnd = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local rStep = RunService.RenderStepped:Connect(function()
		if dragging then
			local pos = UserInputService:GetMouseLocation() + relative
			frame.Position = UDim2.fromOffset(pos.X, pos.Y)
		end
	end)

	frame.Destroying:Connect(function()
		pcall(function() iEnd:Disconnect() end)
		pcall(function() rStep:Disconnect() end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateWindow(opts)
	opts = opts or {}
	local win           = setmetatable({}, Simpliciton)
	win.Name            = opts.Name or "Simpliciton"
	win.Flags           = {}
	win._conns          = {}
	win._tabs           = {}
	win._currentTab     = nil
	win._minimised      = false
	win._visible        = true

	-- Theme
	local themeName = opts.Theme or "Dark"
	local th = Themes[themeName] or Themes.Dark
	if type(opts.Theme) == "table" then th = opts.Theme end
	win.Theme = th

	-- Config
	local cfg = opts.ConfigurationSaving or {}
	win._cfgEnabled = cfg.Enabled == true
	win._cfgFolder  = cfg.FolderName or "Simpliciton"
	win._cfgFile    = (cfg.FileName or tostring(game.PlaceId)) .. ".json"

	-- ── ScreenGui ──────────────────────────────────────────────────────────────
	local sg = New("ScreenGui", {
		Name           = "SimplicitonUI_" .. win.Name,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn   = false,
		DisplayOrder   = 150,
	})
	local guiParent = getGuiParent()
	if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
	sg.Parent = guiParent

	-- Kill old duplicates
	if guiParent then
		for _, c in ipairs(guiParent:GetChildren()) do
			if c.Name == sg.Name and c ~= sg then
				pcall(function() c:Destroy() end)
			end
		end
	end
	win.ScreenGui = sg

	-- ── Main frame (glass) ─────────────────────────────────────────────────────
	-- NO shadow — removed entirely
	local main = New("Frame", {
		Name                   = "Main",
		Size                   = UDim2.new(0, 680, 0, 480),
		Position               = UDim2.new(0.5, -340, 0.5, -240),
		BackgroundColor3       = th.BG,
		BackgroundTransparency = th.BGAlpha or 0.2,
		BorderSizePixel        = 0,
		ClipsDescendants       = true,
		Parent                 = sg,
	})
	Corner(main, 14)
	Stroke(main, th.Border, 1, 0.35)
	win.Main = main

	-- Subtle accent glow stroke
	Stroke(main, th.Accent, 1.5, 0.82)

	-- ── Top bar ────────────────────────────────────────────────────────────────
	local topbar = New("Frame", {
		Name                   = "Topbar",
		Size                   = UDim2.new(1, 0, 0, 52),
		BackgroundColor3       = th.Surface,
		BackgroundTransparency = th.BarAlpha or 0.08,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		Parent                 = main,
	})
	-- Subtle top gradient shimmer
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1,   Color3.new(1, 1, 1)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,   0.96),
			NumberSequenceKeypoint.new(0.5, 0.99),
			NumberSequenceKeypoint.new(1,   0.97),
		}),
		Rotation = 90,
		Parent = topbar,
	})
	-- Bottom divider
	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.2,
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Parent           = topbar,
	})

	-- Window icon
	local titleOffX = 16
	if opts.Icon and opts.Icon ~= 0 then
		local iconBg = New("Frame", {
			Size             = UDim2.new(0, 30, 0, 30),
			Position         = UDim2.new(0, 14, 0.5, 0),
			AnchorPoint      = Vector2.new(0, 0.5),
			BackgroundColor3 = th.Accent,
			BackgroundTransparency = 0.8,
			BorderSizePixel  = 0,
			ZIndex           = 6,
			Parent           = topbar,
		})
		Corner(iconBg, 8)
		New("ImageLabel", {
			Size                 = UDim2.new(0, 20, 0, 20),
			Position             = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint          = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image                = "rbxassetid://" .. tostring(opts.Icon),
			ZIndex               = 7,
			Parent               = iconBg,
		})
		titleOffX = 52
	end

	-- Title + subtitle stack
	local titleHolder = New("Frame", {
		Size                 = UDim2.new(0, 260, 1, 0),
		Position             = UDim2.new(0, titleOffX, 0, 0),
		BackgroundTransparency = 1,
		ZIndex               = 6,
		Parent               = topbar,
	})
	VList(titleHolder, 2)
	Pad(titleHolder, 0, 0, 11, 8)

	local titleLbl = New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 15,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = win.Name,
		ZIndex               = 7,
		Parent               = titleHolder,
	})
	win._titleLabel = titleLbl

	if opts.Subtitle and opts.Subtitle ~= "" then
		New("TextLabel", {
			Size                 = UDim2.new(1, 0, 0, 13),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.Gotham,
			TextSize             = 11,
			TextColor3           = th.TextDim,
			TextXAlignment       = Enum.TextXAlignment.Left,
			Text                 = opts.Subtitle,
			ZIndex               = 7,
			Parent               = titleHolder,
		})
	end

	-- Right-side control buttons
	-- Close
	local closeBtn = New("TextButton", {
		Size             = UDim2.new(0, 26, 0, 26),
		Position         = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint      = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 68, 68),
		Text             = "✕",
		TextColor3       = Color3.new(1, 1, 1),
		Font             = Enum.Font.GothamBold,
		TextSize         = 11,
		ZIndex           = 7,
		Parent           = topbar,
	})
	Corner(closeBtn, 13)
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 110, 110)}) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 68, 68)}) end)
	closeBtn.MouseButton1Click:Connect(function() win:Destroy() end)

	-- Minimize
	local minBtn = New("TextButton", {
		Size             = UDim2.new(0, 26, 0, 26),
		Position         = UDim2.new(1, -48, 0.5, 0),
		AnchorPoint      = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 185, 40),
		Text             = "–",
		TextColor3       = Color3.fromRGB(140, 90, 0),
		Font             = Enum.Font.GothamBold,
		TextSize         = 14,
		ZIndex           = 7,
		Parent           = topbar,
	})
	Corner(minBtn, 13)
	minBtn.MouseEnter:Connect(function() Tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 215, 80)}) end)
	minBtn.MouseLeave:Connect(function() Tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 185, 40)}) end)
	minBtn.MouseButton1Click:Connect(function()
		if win._minimised then win:Maximise() else win:Minimise() end
	end)

	-- Config save button (only if config enabled)
	if win._cfgEnabled then
		local saveBtn = New("TextButton", {
			Size             = UDim2.new(0, 26, 0, 26),
			Position         = UDim2.new(1, -80, 0.5, 0),
			AnchorPoint      = Vector2.new(1, 0.5),
			BackgroundColor3 = th.Element,
			Text             = "",
			TextColor3       = th.TextDim,
			Font             = Enum.Font.Gotham,
			TextSize         = 13,
			ZIndex           = 7,
			Parent           = topbar,
		})
		Corner(saveBtn, 7)
		Stroke(saveBtn, th.Border, 1, 0.4)
		saveBtn.MouseEnter:Connect(function() Tween(saveBtn, {BackgroundColor3 = th.ElementHv}) end)
		saveBtn.MouseLeave:Connect(function() Tween(saveBtn, {BackgroundColor3 = th.Element}) end)
		saveBtn.MouseButton1Click:Connect(function() win:SaveConfiguration() end)
	end

	makeDraggable(main, topbar)

	-- ── Content area (between topbar and bottom tab bar) ───────────────────────
	local content = New("Frame", {
		Name                 = "Content",
		Size                 = UDim2.new(1, 0, 1, -104), -- 52 top + 52 bottom
		Position             = UDim2.new(0, 0, 0, 52),
		BackgroundTransparency = 1,
		ClipsDescendants     = true,
		Parent               = main,
	})
	win._content = content

	-- ── Bottom tab bar ──────────────────────────────────────────────────────────
	local bottomBar = New("Frame", {
		Name                   = "BottomBar",
		Size                   = UDim2.new(1, 0, 0, 52),
		Position               = UDim2.new(0, 0, 1, -52),
		BackgroundColor3       = th.Surface,
		BackgroundTransparency = th.BarAlpha or 0.08,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		Parent                 = main,
	})
	-- Top divider
	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.2,
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Parent           = bottomBar,
	})
	-- Gradient shimmer
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1,   Color3.new(1, 1, 1)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,   0.97),
			NumberSequenceKeypoint.new(0.5, 0.99),
			NumberSequenceKeypoint.new(1,   0.96),
		}),
		Rotation = 90,
		Parent = bottomBar,
	})

	local tabBarInner = New("Frame", {
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex               = 5,
		Parent               = bottomBar,
	})
	local tabBarList = HList(tabBarInner, 0)
	tabBarList.FillDirection = Enum.FillDirection.Horizontal
	tabBarList.VerticalAlignment = Enum.VerticalAlignment.Center
	win._tabBarInner = tabBarInner

	-- ── Notification stack (screen-level, bottom-right) ────────────────────────
	local notifStack = New("Frame", {
		Size                 = UDim2.new(0, 330, 1, 0),
		Position             = UDim2.new(1, -350, 0, 0),
		BackgroundTransparency = 1,
		ZIndex               = 200,
		Parent               = sg,
	})
	local notifList = VList(notifStack, 10)
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	Pad(notifStack, 0, 0, 0, 24)
	win._notifStack = notifStack

	-- ── Global keybind toggle ──────────────────────────────────────────────────
	if opts.ToggleUIKeybind then
		local key = opts.ToggleUIKeybind
		if typeof(key) == "EnumItem" then key = key.Name end
		local conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if tostring(input.KeyCode):find(key) then
				main.Visible = not main.Visible
				win._visible = main.Visible
			end
		end)
		table.insert(win._conns, conn)
	end

	-- Auto-load config after 1s
	if win._cfgEnabled then
		task.spawn(function()
			task.wait(1)
			win:LoadConfiguration()
		end)
	end

	return win
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  WINDOW METHODS
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:Minimise()
	self._minimised = true
	Tween(self.Main, {Size = UDim2.new(0, 680, 0, 52)}, 0.35, Enum.EasingStyle.Quint)
end

function Simpliciton:Maximise()
	self._minimised = false
	Tween(self.Main, {Size = UDim2.new(0, 680, 0, 480)}, 0.38, Enum.EasingStyle.Back)
end

function Simpliciton:SetTitle(text)
	if self._titleLabel then self._titleLabel.Text = text end
end

function Simpliciton:Destroy()
	for _, c in ipairs(self._conns or {}) do pcall(function() c:Disconnect() end) end
	if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
end

function Simpliciton:SetVisibility(v)
	self._visible = v
	if self.Main then self.Main.Visible = v end
end

function Simpliciton:IsVisible()
	return self._visible ~= false
end

-- ── Select a tab (bottom-bar style) ───────────────────────────────────────────
function Simpliciton:_SelectTab(tab)
	self._currentTab = tab
	for _, t in ipairs(self._tabs) do
		local selected = (t == tab)
		t._page.Visible = selected

		Tween(t._btnIcon, {
			TextColor3 = selected and self.Theme.Accent or self.Theme.TextDim,
		}, 0.2)
		Tween(t._btnLabel, {
			TextColor3 = selected and self.Theme.Accent or self.Theme.TextDim,
		}, 0.2)
		Tween(t._btnIndicator, {
			BackgroundTransparency = selected and 0 or 1,
			Size = selected
				and UDim2.new(0.55, 0, 0, 2)
				or  UDim2.new(0.3,  0, 0, 2),
		}, selected and 0.35 or 0.2)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  NOTIFICATIONS  (slide-in from right, image support, progress bar)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:Notify(titleOrData, content, duration, notifType)
	local title    = titleOrData
	local imageVal = nil
	if type(titleOrData) == "table" then
		local d   = titleOrData
		title     = d.Title    or "Notice"
		content   = d.Content  or ""
		duration  = d.Duration or 4
		notifType = d.Type
		imageVal  = d.Image
	end
	title    = title    or "Notice"
	content  = content  or ""
	duration = duration or 4

	local th = self.Theme
	local accentColor =
		(notifType == "success" and th.Success) or
		(notifType == "error"   and th.Error)   or
		(notifType == "warning" and th.Warning)  or
		th.Accent

	task.spawn(function()
		-- Container
		local notif = New("Frame", {
			Size                   = UDim2.new(1, 0, 0, 78),
			Position               = UDim2.new(1.1, 0, 0, 0),
			BackgroundColor3       = th.Surface,
			BackgroundTransparency = 0.04,
			ClipsDescendants       = true,
			ZIndex                 = 201,
			Parent                 = self._notifStack,
		})
		Corner(notif, 12)
		Stroke(notif, accentColor, 1, 0.55)

		-- Left accent strip
		local strip = New("Frame", {
			Size             = UDim2.new(0, 3, 1, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel  = 0,
			ZIndex           = 202,
			Parent           = notif,
		})
		Corner(strip, 12)
		-- Extend right to fill corner
		New("Frame", {
			Size             = UDim2.new(0, 6, 1, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel  = 0,
			ZIndex           = 201,
			Parent           = notif,
		})

		-- Icon (image or emoji)
		local contentOffX = 14
		if imageVal and imageVal ~= 0 and imageVal ~= "" then
			local iconBg = New("Frame", {
				Size                   = UDim2.new(0, 38, 0, 38),
				Position               = UDim2.new(0, 12, 0.5, 0),
				AnchorPoint            = Vector2.new(0, 0.5),
				BackgroundColor3       = accentColor,
				BackgroundTransparency = 0.72,
				BorderSizePixel        = 0,
				ZIndex                 = 202,
				Parent                 = notif,
			})
			Corner(iconBg, 9)

			if type(imageVal) == "number" then
				New("ImageLabel", {
					Size                 = UDim2.new(0, 22, 0, 22),
					Position             = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint          = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image                = "rbxassetid://" .. tostring(imageVal),
					ZIndex               = 203,
					Parent               = iconBg,
				})
			else
				New("TextLabel", {
					Size                 = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Font                 = Enum.Font.GothamBold,
					TextSize             = 18,
					Text                 = tostring(imageVal),
					ZIndex               = 203,
					Parent               = iconBg,
				})
			end
			contentOffX = 60
		end

		-- Title text
		New("TextLabel", {
			Size                 = UDim2.new(1, -(contentOffX + 28), 0, 22),
			Position             = UDim2.new(0, contentOffX, 0, 12),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 13,
			TextColor3           = th.Text,
			TextXAlignment       = Enum.TextXAlignment.Left,
			TextTruncate         = Enum.TextTruncate.AtEnd,
			Text                 = title,
			ZIndex               = 203,
			Parent               = notif,
		})

		-- Body text
		New("TextLabel", {
			Size                 = UDim2.new(1, -(contentOffX + 28), 0, 30),
			Position             = UDim2.new(0, contentOffX, 0, 36),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.Gotham,
			TextSize             = 12,
			TextColor3           = th.TextDim,
			TextXAlignment       = Enum.TextXAlignment.Left,
			TextWrapped          = true,
			Text                 = content,
			ZIndex               = 203,
			Parent               = notif,
		})

		-- Dismiss button
		local dismissed = false
		local closeX = New("TextButton", {
			Size                 = UDim2.new(0, 22, 0, 22),
			Position             = UDim2.new(1, -10, 0, 8),
			AnchorPoint          = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Text                 = "✕",
			TextColor3           = th.TextDim,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 11,
			ZIndex               = 204,
			Parent               = notif,
		})
		closeX.MouseButton1Click:Connect(function() dismissed = true end)
		closeX.MouseEnter:Connect(function() Tween(closeX, {TextColor3 = th.Text}) end)
		closeX.MouseLeave:Connect(function() Tween(closeX, {TextColor3 = th.TextDim}) end)

		-- Progress bar (at bottom)
		local progBg = New("Frame", {
			Size             = UDim2.new(1, 0, 0, 3),
			Position         = UDim2.new(0, 0, 1, -3),
			BackgroundColor3 = th.Border,
			BackgroundTransparency = 0.4,
			BorderSizePixel  = 0,
			ZIndex           = 202,
			Parent           = notif,
		})
		local progFill = New("Frame", {
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel  = 0,
			ZIndex           = 203,
			Parent           = progBg,
		})

		-- Slide IN from right with back easing
		Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back)

		-- Shrink progress bar over duration
		Tween(progFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

		-- Wait for duration or dismiss
		local elapsed, step = 0, 0.05
		while elapsed < duration and not dismissed do
			task.wait(step)
			elapsed = elapsed + step
		end

		-- Slide OUT to right
		Tween(notif, {
			Position               = UDim2.new(1.1, 0, 0, 0),
			BackgroundTransparency = 1,
		}, 0.3, Enum.EasingStyle.Quint)
		task.wait(0.35)
		pcall(function() notif:Destroy() end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  CREATE TAB  (bottom navigation)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateTab(name, icon)
	local th  = self.Theme
	local tab = { _win = self, _elements = {} }

	-- Bottom bar button (equal-width, takes 1/n of bar)
	local btn = New("TextButton", {
		Size                 = UDim2.new(0.25, 0, 1, 0), -- placeholder, resized below
		BackgroundTransparency = 1,
		Text                 = "",
		ZIndex               = 6,
		Parent               = self._tabBarInner,
	})

	-- Accent top indicator bar
	local indicator = New("Frame", {
		Size             = UDim2.new(0.35, 0, 0, 2),
		Position         = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint      = Vector2.new(0.5, 0),
		BackgroundColor3 = th.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel  = 0,
		ZIndex           = 7,
		Parent           = btn,
	})
	Corner(indicator, 1)

	-- Icon (emoji string or fallback glyph)
	local iconStr = (type(icon) == "string" and icon ~= "") and icon or "◈"
	local iconLbl = New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 24),
		Position             = UDim2.new(0, 0, 0, 5),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 19,
		TextColor3           = th.TextDim,
		Text                 = iconStr,
		ZIndex               = 7,
		Parent               = btn,
	})

	-- Tab name label
	local nameLbl = New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 12),
		Position             = UDim2.new(0, 0, 0, 31),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamSemibold,
		TextSize             = 10,
		TextColor3           = th.TextDim,
		Text                 = string.upper(name),
		ZIndex               = 7,
		Parent               = btn,
	})

	tab._btn          = btn
	tab._btnIcon      = iconLbl
	tab._btnLabel     = nameLbl
	tab._btnIndicator = indicator

	-- Tab page (scrollable content)
	local page = New("ScrollingFrame", {
		Name                   = "Page_" .. name,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness     = 3,
		ScrollBarImageColor3   = th.Accent,
		BackgroundTransparency = 1,
		ClipsDescendants       = false,
		Visible                = false,
		BorderSizePixel        = 0,
		Parent                 = self._content,
	})
	local pageList = VList(page, 7)
	Pad(page, 12, 12, 10, 10)
	AutoCanvas(page, pageList)
	tab._page     = page
	tab._pageList = pageList

	btn.MouseButton1Click:Connect(function()
		self:_SelectTab(tab)
	end)

	table.insert(self._tabs, tab)
	setmetatable(tab, { __index = self })

	-- Resize ALL tab buttons to equal widths
	task.spawn(function()
		task.wait()
		local count = #self._tabs
		for _, t in ipairs(self._tabs) do
			t._btn.Size = UDim2.new(1 / count, 0, 1, 0)
		end
	end)

	-- Auto-select first tab
	if #self._tabs == 1 then
		self:_SelectTab(tab)
	end

	return tab
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SHARED ELEMENT HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════
local function getPage(self)
	return rawget(self, "_page")
		or (rawget(self, "_win") and self._win._currentTab and self._win._currentTab._page)
end

local function getWin(self)
	return rawget(self, "_win") or self
end

local function getTheme(self)
	local w = getWin(self)
	return rawget(w, "Theme") or Themes.Dark
end

-- Base card frame
local function makeCard(page, th, height)
	local f = New("Frame", {
		Size             = UDim2.new(1, 0, 0, height or 44),
		BackgroundColor3 = th.Element,
		BorderSizePixel  = 0,
		Parent           = page,
	})
	Corner(f, 10)
	return f
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SECTION  (header with divider and optional icon)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateSection(title, icon)
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local f = New("Frame", {
		Size                 = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Parent               = page,
	})

	local iconW = 0
	if icon and icon ~= "" then
		iconW = 20
		New("TextLabel", {
			Size                 = UDim2.new(0, 18, 1, 0),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 14,
			TextColor3           = th.Accent,
			Text                 = icon,
			Parent               = f,
		})
	end

	local lbl = New("TextLabel", {
		Size                 = UDim2.new(1, -iconW, 1, 0),
		Position             = UDim2.new(0, iconW, 0, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 11,
		TextColor3           = th.Accent,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = string.upper(title or "Section"),
		Parent               = f,
	})

	-- Divider line
	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.3,
		BorderSizePixel  = 0,
		Parent           = f,
	})

	return {
		Set        = function(_, t) lbl.Text = string.upper(t or "") end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  DIVIDER
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateDivider()
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)
	local f = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.3,
		BorderSizePixel  = 0,
		Parent           = page,
	})
	return { Set = function(_, v) f.Visible = v end }
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  LABEL
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateLabel(text, badgeText, badgeColor)
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local f = makeCard(page, th, 38)
	f.BackgroundColor3 = th.Surface
	Pad(f, 14, 14, 0, 0)

	local lbl = New("TextLabel", {
		Size                 = UDim2.new(1, badgeText and -60 or 0, 1, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 13,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = text or "",
		Parent               = f,
	})

	-- Optional badge chip
	if badgeText then
		local chip = New("Frame", {
			Size             = UDim2.new(0, 50, 0, 22),
			Position         = UDim2.new(1, -50, 0.5, 0),
			AnchorPoint      = Vector2.new(0, 0.5),
			BackgroundColor3 = badgeColor or th.Accent,
			BackgroundTransparency = 0.75,
			BorderSizePixel  = 0,
			Parent           = f,
		})
		Corner(chip, 11)
		New("TextLabel", {
			Size                 = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 10,
			TextColor3           = badgeColor or th.Accent,
			Text                 = badgeText,
			Parent               = chip,
		})
	end

	return {
		Set        = function(_, t) lbl.Text = t end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  PARAGRAPH
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateParagraph(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local f = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = th.Surface,
		BorderSizePixel  = 0,
		Parent           = page,
	})
	Corner(f, 10)
	Stroke(f, th.Border, 1, 0.5)
	Pad(f, 14, 14, 12, 12)
	VList(f, 5)

	local titleLbl = New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Title or "",
		Parent               = f,
	})
	local bodyLbl = New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 0),
		AutomaticSize        = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 12,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Left,
		TextWrapped          = true,
		Text                 = opts.Content or "",
		Parent               = f,
	})

	return {
		Set = function(_, o)
			titleLbl.Text = o.Title   or ""
			bodyLbl.Text  = o.Content or ""
		end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  BUTTON  (supports Style: "Accent" | "Secondary" | "Danger" | "Ghost")
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateButton(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local style = opts.Style or "Accent"
	local bgColor, fgColor, strokeCol, strokeTrans

	if style == "Accent" then
		bgColor = th.Accent;   fgColor = Color3.new(1, 1, 1)
	elseif style == "Secondary" then
		bgColor = th.Element;  fgColor = th.Text;   strokeCol = th.Border; strokeTrans = 0
	elseif style == "Danger" then
		bgColor = th.Error;    fgColor = Color3.new(1, 1, 1)
	elseif style == "Ghost" then
		bgColor = th.Element;  fgColor = th.Accent; strokeCol = th.Accent; strokeTrans = 0.5
	else
		bgColor = th.Accent;   fgColor = Color3.new(1, 1, 1)
	end

	local hasDesc = opts.Description and opts.Description ~= ""
	local height  = hasDesc and 58 or 42

	local f = New("Frame", {
		Size             = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = bgColor,
		BorderSizePixel  = 0,
		Parent           = page,
	})
	Corner(f, 10)
	if strokeCol then Stroke(f, strokeCol, 1, strokeTrans) end

	-- Name label
	local nameLbl = New("TextLabel", {
		Size                 = UDim2.new(1, -16, 0, hasDesc and 22 or height),
		Position             = UDim2.new(0, 0, 0, hasDesc and 9 or 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamSemibold,
		TextSize             = 13,
		TextColor3           = fgColor,
		Text                 = opts.Name or "Button",
		ZIndex               = 3,
		Parent               = f,
	})

	-- Description label
	if hasDesc then
		New("TextLabel", {
			Size                 = UDim2.new(1, -16, 0, 16),
			Position             = UDim2.new(0, 0, 0, 33),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.Gotham,
			TextSize             = 11,
			TextColor3           = style == "Accent"
				and Color3.fromRGB(200, 220, 255)
				or  th.TextDim,
			Text                 = opts.Description,
			ZIndex               = 3,
			Parent               = f,
		})
	end

	local interact = New("TextButton", {
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                 = "",
		ZIndex               = 4,
		Parent               = f,
	})

	local _loading  = false
	local _enabled  = true
	local bgHover   = brighten(bgColor, style == "Ghost" and 5 or 22)

	interact.MouseEnter:Connect(function()
		if not _enabled or _loading then return end
		Tween(f, {BackgroundColor3 = bgHover})
	end)
	interact.MouseLeave:Connect(function()
		if not _enabled or _loading then return end
		Tween(f, {BackgroundColor3 = bgColor})
	end)
	interact.MouseButton1Down:Connect(function()
		if not _enabled or _loading then return end
		Tween(f, {BackgroundTransparency = 0.18}, 0.08)
	end)
	interact.MouseButton1Up:Connect(function()
		Tween(f, {BackgroundTransparency = 0}, 0.1)
	end)
	interact.MouseButton1Click:Connect(function()
		if not _enabled or _loading then return end
		if opts.Callback then pcall(opts.Callback) end
	end)

	return {
		Set = function(_, t)
			nameLbl.Text = t
		end,
		SetEnabled = function(_, v)
			_enabled = v
			interact.Active = v
			Tween(f, {BackgroundTransparency = v and 0 or 0.55})
		end,
		SetLoading = function(_, v)
			_loading = v
			nameLbl.Text = v and "Loading…" or (opts.Name or "Button")
			Tween(f, {BackgroundTransparency = v and 0.35 or 0})
		end,
		SetVisible = function(_, v) f.Visible = v end,
		Fire = function(_) if opts.Callback then pcall(opts.Callback) end end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TOGGLE  (with optional description, springy knob)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateToggle(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local val     = opts.CurrentValue == true
	local hasDesc = opts.Description and opts.Description ~= ""
	local height  = hasDesc and 58 or 44
	if opts.Flag then Simpliciton.Flags[opts.Flag] = val end

	local f = makeCard(page, th, height)
	Pad(f, 14, 14, 0, 0)

	-- Name
	New("TextLabel", {
		Size                 = UDim2.new(1, -64, 0, hasDesc and 22 or height),
		Position             = UDim2.new(0, 0, 0, hasDesc and 9 or 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Toggle",
		Parent               = f,
	})

	-- Description
	if hasDesc then
		New("TextLabel", {
			Size                 = UDim2.new(1, -64, 0, 16),
			Position             = UDim2.new(0, 0, 0, 33),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.Gotham,
			TextSize             = 11,
			TextColor3           = th.TextDim,
			TextXAlignment       = Enum.TextXAlignment.Left,
			Text                 = opts.Description,
			Parent               = f,
		})
	end

	-- Track
	local track = New("Frame", {
		Size             = UDim2.new(0, 48, 0, 27),
		Position         = UDim2.new(1, -48, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = val and th.Accent or th.Border,
		BorderSizePixel  = 0,
		Parent           = f,
	})
	Corner(track, 14)
	-- Subtle inner gradient
	New("UIGradient", {
		Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,   0.82),
			NumberSequenceKeypoint.new(1,   0.97),
		}),
		Rotation = 90,
		Parent   = track,
	})

	-- Knob
	local knob = New("Frame", {
		Size             = UDim2.new(0, 21, 0, 21),
		Position         = UDim2.new(0, val and 24 or 3, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 2,
		Parent           = track,
	})
	Corner(knob, 11)

	local function setState(v, silent)
		val = v
		if opts.Flag then
			Simpliciton.Flags[opts.Flag] = v
			win.Flags[opts.Flag] = v
		end
		Tween(track, {BackgroundColor3 = v and th.Accent or th.Border}, 0.22)
		Tween(knob,  {Position = UDim2.new(0, v and 24 or 3, 0.5, 0)}, 0.22,
			Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		if not silent and opts.Callback then pcall(opts.Callback, v) end
	end

	local interact = New("TextButton", {
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "",
		ZIndex = 5, Parent = f,
	})
	interact.MouseButton1Click:Connect(function() setState(not val) end)
	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set        = function(_, v) setState(v, false) end,
		Get        = function() return val end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SLIDER  (drag OR click value box to type exact number)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateSlider(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local mn  = (opts.Range and opts.Range[1]) or opts.Min or 0
	local mx  = (opts.Range and opts.Range[2]) or opts.Max or 100
	local inc = opts.Increment
	local val = math.clamp(opts.CurrentValue or mn, mn, mx)
	if opts.Flag then Simpliciton.Flags[opts.Flag] = val end

	local f = makeCard(page, th, 68)
	Pad(f, 14, 14, 0, 0)

	-- Name
	New("TextLabel", {
		Size                 = UDim2.new(1, -96, 0, 26),
		Position             = UDim2.new(0, 0, 0, 10),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Slider",
		Parent               = f,
	})

	-- Value TextBox — acts as both display AND input (click to type)
	local valBox = New("TextBox", {
		Size                   = UDim2.new(0, 82, 0, 26),
		Position               = UDim2.new(1, -82, 0, 10),
		BackgroundColor3       = th.BG,
		BackgroundTransparency = 0.45,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 12,
		TextColor3             = th.Accent,
		TextXAlignment         = Enum.TextXAlignment.Center,
		Text                   = tostring(val) .. (opts.Suffix and (" " .. opts.Suffix) or ""),
		ClearTextOnFocus       = true,
		BorderSizePixel        = 0,
		ZIndex                 = 5,
		Parent                 = f,
	})
	Corner(valBox, 7)
	local valStroke = Stroke(valBox, th.Border, 1, 0.45)

	-- Min / max hint labels
	New("TextLabel", {
		Size                 = UDim2.new(0.5, 0, 0, 14),
		Position             = UDim2.new(0, 0, 1, -18),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 10,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = tostring(mn),
		Parent               = f,
	})
	New("TextLabel", {
		Size                 = UDim2.new(0.5, 0, 0, 14),
		Position             = UDim2.new(0.5, 0, 1, -18),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 10,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Right,
		Text                 = tostring(mx),
		Parent               = f,
	})

	-- Track
	local track = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 6),
		Position         = UDim2.new(0, 0, 1, -34),
		AnchorPoint      = Vector2.new(0, 1),
		BackgroundColor3 = th.Border,
		BorderSizePixel  = 0,
		Parent           = f,
	})
	Corner(track, 3)

	-- Fill with gradient
	local fill = New("Frame", {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = th.Accent,
		BorderSizePixel  = 0,
		Parent           = track,
	})
	Corner(fill, 3)
	New("UIGradient", {
		Color = ColorSequence.new(th.AccentDim or th.Accent, th.Accent),
		Parent = fill,
	})

	-- Knob
	local knob = New("Frame", {
		Size             = UDim2.new(0, 16, 0, 16),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 3,
		Parent           = track,
	})
	Corner(knob, 8)
	Stroke(knob, th.Accent, 2, 0)

	local function update(v, fire)
		if inc and inc > 0 then v = math.floor(v / inc + 0.5) * inc end
		v = math.clamp(v, mn, mx)
		local dp  = opts.Decimals or 0
		v = tonumber(string.format("%." .. dp .. "f", v)) or v
		val = v
		local pct = (mx == mn) and 0 or ((v - mn) / (mx - mn))
		fill.Size      = UDim2.new(pct, 0, 1, 0)
		knob.Position  = UDim2.new(pct, 0, 0.5, 0)
		valBox.Text = tostring(v) .. (opts.Suffix and (" " .. opts.Suffix) or "")
		if fire then
			if opts.Flag then Simpliciton.Flags[opts.Flag] = v; win.Flags[opts.Flag] = v end
			if opts.Callback then pcall(opts.Callback, v) end
		end
	end
	update(val, false)

	-- Typing into the value box
	valBox.Focused:Connect(function()
		valBox.Text = tostring(val)
		valStroke.Color       = th.Accent
		valStroke.Transparency = 0
		Tween(valBox, {BackgroundTransparency = 0.25})
	end)
	valBox.FocusLost:Connect(function()
		local num = tonumber(valBox.Text)
		if num then update(num, true)
		else valBox.Text = tostring(val) .. (opts.Suffix and (" " .. opts.Suffix) or "") end
		valStroke.Color        = th.Border
		valStroke.Transparency = 0.45
		Tween(valBox, {BackgroundTransparency = 0.45})
	end)

	-- Drag input
	local dragging = false
	local interactTrack = New("TextButton", {
		Size                 = UDim2.new(1, 0, 0, 26),
		Position             = UDim2.new(0, 0, 1, -36),
		AnchorPoint          = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Text                 = "",
		ZIndex               = 6,
		Parent               = f,
	})
	interactTrack.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
		   input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true
		local loop; loop = RunService.Stepped:Connect(function()
			if not dragging then loop:Disconnect(); return end
			local x = UserInputService:GetMouseLocation().X
			local pct = math.clamp(
				(x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			update(mn + (mx - mn) * pct, true)
		end)
		table.insert(win._conns, loop)
	end)
	local endConn = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or
		   i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	table.insert(win._conns, endConn)

	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set        = function(_, v) update(v, true) end,
		Get        = function() return val end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  INPUT  (live callback, MaxLength counter, clear button, NumbersOnly)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateInput(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local maxLen = opts.MaxLength or 0
	local f = makeCard(page, th, 66)
	Pad(f, 14, 14, 0, 0)

	-- Name row
	New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 22),
		Position             = UDim2.new(0, 0, 0, 6),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Input",
		Parent               = f,
	})

	-- Length counter label (top-right, only if MaxLength set)
	local counterLbl
	if maxLen > 0 then
		counterLbl = New("TextLabel", {
			Size                 = UDim2.new(0, 60, 0, 22),
			Position             = UDim2.new(1, -60, 0, 6),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.Gotham,
			TextSize             = 11,
			TextColor3           = th.TextDim,
			TextXAlignment       = Enum.TextXAlignment.Right,
			Text                 = "0/" .. maxLen,
			Parent               = f,
		})
	end

	-- Text box
	local box = New("TextBox", {
		Size                 = UDim2.new(1, 0, 0, 30),
		Position             = UDim2.new(0, 0, 1, -36),
		AnchorPoint          = Vector2.new(0, 1),
		BackgroundColor3     = th.BG,
		BackgroundTransparency = 0.35,
		Font                 = Enum.Font.Gotham,
		TextSize             = 13,
		TextColor3           = th.Text,
		PlaceholderColor3    = th.TextDim,
		PlaceholderText      = opts.PlaceholderText or "Type here…",
		ClearTextOnFocus     = false,
		Text                 = opts.CurrentValue or "",
		BorderSizePixel      = 0,
		ZIndex               = 3,
		Parent               = f,
	})
	Corner(box, 8)
	local boxStroke = Stroke(box, th.Border, 1, 0.4)
	Pad(box, 10, 34, 0, 0)

	-- Clear button (X inside the box, right side)
	local clearBtn = New("TextButton", {
		Size                 = UDim2.new(0, 28, 0, 28),
		Position             = UDim2.new(1, -30, 0.5, 0),
		AnchorPoint          = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Text                 = "⊗",
		TextColor3           = th.TextDim,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 13,
		ZIndex               = 4,
		Parent               = box,
	})
	clearBtn.Visible = (box.Text ~= "")
	clearBtn.MouseButton1Click:Connect(function()
		box.Text = ""
		clearBtn.Visible = false
		if counterLbl then counterLbl.Text = "0/" .. maxLen end
	end)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local t = box.Text
		-- MaxLength enforcement
		if maxLen > 0 and #t > maxLen then
			box.Text = t:sub(1, maxLen)
			return
		end
		-- NumbersOnly enforcement
		if opts.NumbersOnly then
			local clean = t:gsub("[^%d%.-]", "")
			if clean ~= t then box.Text = clean; return end
		end
		-- Update counter
		if counterLbl then counterLbl.Text = #box.Text .. "/" .. maxLen end
		-- Update clear button visibility
		clearBtn.Visible = (#box.Text > 0)
		-- Live callback
		if opts.LiveCallback and opts.Callback then
			pcall(opts.Callback, box.Text)
		end
	end)

	box.Focused:Connect(function()
		boxStroke.Color       = th.Accent
		boxStroke.Transparency = 0
		Tween(box, {BackgroundTransparency = 0.15})
	end)
	box.FocusLost:Connect(function(enter)
		boxStroke.Color       = th.Border
		boxStroke.Transparency = 0.4
		Tween(box, {BackgroundTransparency = 0.35})
		local text = box.Text
		if opts.RemoveTextAfterFocusLost then
			box.Text = ""
			clearBtn.Visible = false
		end
		if opts.Flag then Simpliciton.Flags[opts.Flag] = text; win.Flags[opts.Flag] = text end
		if not opts.LiveCallback and opts.Callback then pcall(opts.Callback, text) end
	end)

	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set = function(_, t)
			box.Text = t
			clearBtn.Visible = (#t > 0)
		end,
		Get        = function() return box.Text end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  DROPDOWN  (optional search bar, animated open/close)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateDropdown(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local multi    = opts.MultipleOptions == true
	local selected = {}
	if type(opts.CurrentOption) == "string" then
		selected = {opts.CurrentOption}
	elseif type(opts.CurrentOption) == "table" then
		selected = opts.CurrentOption
	end
	if not multi and #selected > 1 then selected = {selected[1]} end
	if opts.Flag then Simpliciton.Flags[opts.Flag] = selected end

	local isOpen  = false

	-- Header card
	local header = makeCard(page, th, 44)
	Pad(header, 14, 14, 0, 0)

	New("TextLabel", {
		Size                 = UDim2.new(1, -130, 1, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Dropdown",
		Parent               = header,
	})

	local selLbl = New("TextLabel", {
		Size                 = UDim2.new(0, 105, 1, 0),
		Position             = UDim2.new(1, -120, 0, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 12,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Right,
		Text                 = #selected > 0 and (#selected == 1 and selected[1] or "Multiple") or "None",
		Parent               = header,
	})

	local arrowLbl = New("TextLabel", {
		Size                 = UDim2.new(0, 14, 1, 0),
		Position             = UDim2.new(1, -14, 0, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 12,
		TextColor3           = th.TextDim,
		Text                 = "▾",
		Parent               = header,
	})

	-- Dropdown list panel (floats on ScreenGui to avoid clipping)
	local listFrame = New("Frame", {
		Size             = UDim2.new(0, 300, 0, 0),
		BackgroundColor3 = th.Surface,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		Visible          = false,
		ZIndex           = 50,
		Parent           = win.ScreenGui,
	})
	Corner(listFrame, 10)
	Stroke(listFrame, th.Border, 1, 0.25)

	-- Search box (only if Searchable = true)
	local searchOffY = 0
	if opts.Searchable then
		searchOffY = 36
		local sb = New("TextBox", {
			Size                 = UDim2.new(1, -12, 0, 28),
			Position             = UDim2.new(0, 6, 0, 5),
			BackgroundColor3     = th.Element,
			Font                 = Enum.Font.Gotham,
			TextSize             = 12,
			TextColor3           = th.Text,
			PlaceholderText      = "Search…",
			PlaceholderColor3    = th.TextDim,
			ClearTextOnFocus     = false,
			BorderSizePixel      = 0,
			ZIndex               = 53,
			Parent               = listFrame,
		})
		Corner(sb, 6)
		Pad(sb, 8, 8, 0, 0)
		sb:GetPropertyChangedSignal("Text"):Connect(function()
			local q = sb.Text:lower()
			for _, child in ipairs(listFrame:GetChildren()) do
				if child:IsA("TextButton") then
					child.Visible = (q == "" or child.Text:lower():find(q, 1, true) ~= nil)
				end
			end
		end)
	end

	local listScroll = New("ScrollingFrame", {
		Size                 = UDim2.new(1, -2, 1, -(searchOffY + 2)),
		Position             = UDim2.new(0, 1, 0, searchOffY + 1),
		CanvasSize           = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness   = 3,
		ScrollBarImageColor3 = th.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ZIndex               = 51,
		Parent               = listFrame,
	})
	local listLayout = VList(listScroll, 3)
	Pad(listScroll, 4, 4, 4, 4)
	AutoCanvas(listScroll, listLayout)

	local posConn
	local function positionList()
		local absPos  = header.AbsolutePosition
		local absSize = header.AbsoluteSize
		local itemH   = math.min(#(opts.Options or {}), 6) * 36 + searchOffY + 10
		listFrame.Size     = UDim2.new(0, absSize.X, 0, itemH)
		listFrame.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
	end

	local function updateLabel()
		if #selected == 0 then
			selLbl.Text = "None"
		elseif #selected == 1 then
			selLbl.Text = selected[1]
		else
			selLbl.Text = "Multiple (" .. #selected .. ")"
		end
	end

	local function buildOptions()
		for _, c in ipairs(listScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, opt in ipairs(opts.Options or {}) do
			local isSel = table.find(selected, opt) ~= nil
			local row = New("TextButton", {
				Size             = UDim2.new(1, 0, 0, 33),
				BackgroundColor3 = isSel and th.Accent or th.Element,
				Font             = Enum.Font.Gotham,
				TextSize         = 13,
				TextColor3       = isSel and Color3.new(1, 1, 1) or th.Text,
				Text             = opt,
				BorderSizePixel  = 0,
				ZIndex           = 52,
				Parent           = listScroll,
			})
			Corner(row, 7)
			-- Check mark for selected
			if isSel then
				New("TextLabel", {
					Size                 = UDim2.new(0, 24, 1, 0),
					Position             = UDim2.new(1, -28, 0, 0),
					BackgroundTransparency = 1,
					Font                 = Enum.Font.GothamBold,
					TextSize             = 13,
					TextColor3           = Color3.new(1, 1, 1),
					Text                 = "✓",
					ZIndex               = 53,
					Parent               = row,
				})
			end
			row.MouseButton1Click:Connect(function()
				if multi then
					local idx = table.find(selected, opt)
					if idx then table.remove(selected, idx)
					else table.insert(selected, opt) end
				else
					selected = {opt}
					isOpen   = false
					Tween(listFrame, {Size = UDim2.new(listFrame.Size.X.Scale, listFrame.Size.X.Offset, 0, 0)}, 0.2)
					task.wait(0.22)
					listFrame.Visible = false
					arrowLbl.Text = "▾"
					if posConn then posConn:Disconnect(); posConn = nil end
				end
				updateLabel()
				buildOptions()
				if opts.Flag then Simpliciton.Flags[opts.Flag] = selected; win.Flags[opts.Flag] = selected end
				if opts.Callback then pcall(opts.Callback, selected) end
			end)
			row.MouseEnter:Connect(function()
				if not table.find(selected, opt) then
					Tween(row, {BackgroundColor3 = th.ElementHv})
				end
			end)
			row.MouseLeave:Connect(function()
				Tween(row, {BackgroundColor3 = table.find(selected, opt) and th.Accent or th.Element})
			end)
		end
	end
	buildOptions()

	-- Toggle open/close
	local interact = New("TextButton", {
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "",
		ZIndex = 5, Parent = header,
	})
	interact.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			positionList()
			listFrame.Visible = true
			arrowLbl.Text = "▴"
			posConn = RunService.RenderStepped:Connect(positionList)
		else
			local lfw = listFrame.Size.X.Offset
			Tween(listFrame, {Size = UDim2.new(0, lfw, 0, 0)}, 0.2)
			task.spawn(function()
				task.wait(0.22)
				listFrame.Visible = false
			end)
			arrowLbl.Text = "▾"
			if posConn then posConn:Disconnect(); posConn = nil end
		end
	end)
	header.MouseEnter:Connect(function() Tween(header, {BackgroundColor3 = th.ElementHv}) end)
	header.MouseLeave:Connect(function() Tween(header, {BackgroundColor3 = th.Element}) end)

	-- Close on outside click
	local outsideConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not isOpen then return end
		local mpos = UserInputService:GetMouseLocation()
		local lp, ls = listFrame.AbsolutePosition, listFrame.AbsoluteSize
		local hp, hs = header.AbsolutePosition, header.AbsoluteSize
		local inList   = mpos.X >= lp.X and mpos.X <= lp.X+ls.X and mpos.Y >= lp.Y and mpos.Y <= lp.Y+ls.Y
		local inHeader = mpos.X >= hp.X and mpos.X <= hp.X+hs.X and mpos.Y >= hp.Y and mpos.Y <= hp.Y+hs.Y
		if not inList and not inHeader then
			isOpen = false
			listFrame.Visible = false
			arrowLbl.Text = "▾"
			if posConn then posConn:Disconnect(); posConn = nil end
		end
	end)
	table.insert(win._conns, outsideConn)

	return {
		Set = function(_, newOpt)
			selected = type(newOpt) == "string" and {newOpt} or newOpt
			updateLabel(); buildOptions()
			if opts.Flag then Simpliciton.Flags[opts.Flag] = selected; win.Flags[opts.Flag] = selected end
		end,
		GetSelected = function() return selected end,
		Refresh = function(_, newOpts)
			opts.Options = newOpts
			buildOptions()
		end,
		SetVisible = function(_, v) header.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  KEYBIND  (click to listen, Escape to clear)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateKeybind(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local currentKey = opts.CurrentKeybind or "None"
	local listening  = false
	if opts.Flag then Simpliciton.Flags[opts.Flag] = currentKey end

	local f = makeCard(page, th, 44)
	Pad(f, 14, 14, 0, 0)

	New("TextLabel", {
		Size                 = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Keybind",
		Parent               = f,
	})

	local keyBtn = New("TextButton", {
		Size             = UDim2.new(0, 92, 0, 28),
		Position         = UDim2.new(1, -92, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = th.BG,
		BackgroundTransparency = 0.35,
		Font             = Enum.Font.GothamBold,
		TextSize         = 11,
		TextColor3       = th.Accent,
		Text             = currentKey == "" and "None" or currentKey,
		BorderSizePixel  = 0,
		ZIndex           = 4,
		Parent           = f,
	})
	Corner(keyBtn, 7)
	local keyStroke = Stroke(keyBtn, th.Border, 1, 0.4)

	-- Hint label (shows "Press any key")
	local hintLbl = New("TextLabel", {
		Size                 = UDim2.new(1, -110, 0, 14),
		Position             = UDim2.new(0, 0, 1, -16),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 10,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = "",
		Visible              = false,
		Parent               = f,
	})
	-- Resize card when hint visible
	local function setListening(v)
		listening = v
		hintLbl.Visible = v
		f.Size = UDim2.new(1, 0, 0, v and 58 or 44)
		if v then
			hintLbl.Text = "Press a key… (Escape to clear)"
			keyBtn.Text = "…"
			keyBtn.TextColor3 = th.Warning
			keyStroke.Color = th.Warning
			keyStroke.Transparency = 0
			Tween(keyBtn, {BackgroundTransparency = 0.15})
		else
			hintLbl.Text = ""
			keyBtn.TextColor3 = th.Accent
			keyStroke.Color = th.Border
			keyStroke.Transparency = 0.4
			Tween(keyBtn, {BackgroundTransparency = 0.35})
		end
	end

	keyBtn.MouseButton1Click:Connect(function()
		if listening then return end
		setListening(true)
		local conn; conn = UserInputService.InputBegan:Connect(function(input, processed)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			conn:Disconnect()
			local name = tostring(input.KeyCode):gsub("Enum%.KeyCode%.", "")
			currentKey = (name == "Escape") and "None" or name
			keyBtn.Text = currentKey
			setListening(false)
			if opts.Flag then Simpliciton.Flags[opts.Flag] = currentKey; win.Flags[opts.Flag] = currentKey end
			if opts.Callback then pcall(opts.Callback, currentKey) end
		end)
	end)

	keyBtn.MouseEnter:Connect(function() if not listening then Tween(keyBtn, {BackgroundTransparency = 0.2}) end end)
	keyBtn.MouseLeave:Connect(function() if not listening then Tween(keyBtn, {BackgroundTransparency = 0.35}) end end)
	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set = function(_, k)
			currentKey  = k or "None"
			keyBtn.Text = currentKey
			if opts.Flag then Simpliciton.Flags[opts.Flag] = currentKey; win.Flags[opts.Flag] = currentKey end
		end,
		Get        = function() return currentKey end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  COLOR PICKER  (SV square + Hue bar + Alpha bar + RGB inputs + Hex input)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateColorPicker(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local startColor = opts.Color or opts.CurrentValue or Color3.fromRGB(255, 80, 80)
	local hue, sat, bri = Color3.toHSV(startColor)
	local alpha = opts.Alpha or 1

	-- Collapsed header card
	local header = makeCard(page, th, 44)
	Pad(header, 14, 14, 0, 0)

	New("TextLabel", {
		Size                 = UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Color",
		Parent               = header,
	})

	local preview = New("Frame", {
		Size             = UDim2.new(0, 36, 0, 24),
		Position         = UDim2.new(1, -52, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = startColor,
		BorderSizePixel  = 0,
		Parent           = header,
	})
	Corner(preview, 6)
	Stroke(preview, th.Border, 1, 0)

	local dropArrow = New("TextLabel", {
		Size                 = UDim2.new(0, 14, 1, 0),
		Position             = UDim2.new(1, -14, 0, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 12,
		TextColor3           = th.TextDim,
		Text                 = "▾",
		Parent               = header,
	})

	-- ── Picker panel (floats on ScreenGui) ─────────────────────────────────────
	local pW, pH = 310, 240
	local panel = New("Frame", {
		Size             = UDim2.new(0, pW, 0, pH),
		BackgroundColor3 = th.Surface,
		BorderSizePixel  = 0,
		Visible          = false,
		ZIndex           = 60,
		Parent           = win.ScreenGui,
	})
	Corner(panel, 12)
	Stroke(panel, th.Border, 1, 0.2)

	-- SV square
	local svW, svH = 170, 130
	local svBox = New("Frame", {
		Size             = UDim2.new(0, svW, 0, svH),
		Position         = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 61,
		Parent           = panel,
	})
	Corner(svBox, 7)
	-- White → transparent (left → right)
	New("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = svBox,
	})
	-- Transparent → black (top → bottom)
	local darkLayer = New("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel  = 0,
		ZIndex           = 62,
		Parent           = svBox,
	})
	Corner(darkLayer, 7)
	New("UIGradient", {
		Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rotation = 90,
		Parent   = darkLayer,
	})
	-- SV knob
	local svKnob = New("Frame", {
		Size             = UDim2.new(0, 13, 0, 13),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(sat, 0, 1 - bri, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 64,
		Parent           = svBox,
	})
	Corner(svKnob, 7)
	Stroke(svKnob, Color3.new(0, 0, 0), 1.5, 0)

	-- Hue bar
	local hueBar = New("Frame", {
		Size             = UDim2.new(0, svW, 0, 13),
		Position         = UDim2.new(0, 12, 0, svH + 18),
		BorderSizePixel  = 0,
		ZIndex           = 61,
		Parent           = panel,
	})
	Corner(hueBar, 5)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,    1, 1)),
			ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
			ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
			ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5,  1, 1)),
			ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
			ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
			ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,    1, 1)),
		}),
		Parent = hueBar,
	})
	local hueKnob = New("Frame", {
		Size             = UDim2.new(0, 10, 1, 4),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(hue, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 62,
		Parent           = hueBar,
	})
	Corner(hueKnob, 4)
	Stroke(hueKnob, Color3.new(0, 0, 0), 1.5, 0)

	-- Alpha bar (white → transparent)
	local alphaBar = New("Frame", {
		Size             = UDim2.new(0, svW, 0, 13),
		Position         = UDim2.new(0, 12, 0, svH + 37),
		BorderSizePixel  = 0,
		ZIndex           = 61,
		Parent           = panel,
	})
	Corner(alphaBar, 5)
	Stroke(alphaBar, th.Border, 1, 0.3)
	New("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = alphaBar,
	})
	local alphaKnob = New("Frame", {
		Size             = UDim2.new(0, 10, 1, 4),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(alpha, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 62,
		Parent           = alphaBar,
	})
	Corner(alphaKnob, 4)
	Stroke(alphaKnob, Color3.new(0, 0, 0), 1.5, 0)

	-- Right column: Hex + big preview + R/G/B inputs
	local rightX = svW + 22
	local hexBox = New("TextBox", {
		Size                 = UDim2.new(0, 96, 0, 26),
		Position             = UDim2.new(0, rightX, 0, 12),
		BackgroundColor3     = th.Element,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 11,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Center,
		ClearTextOnFocus     = false,
		Text                 = string.format("#%02X%02X%02X",
			math.floor(startColor.R * 255),
			math.floor(startColor.G * 255),
			math.floor(startColor.B * 255)),
		PlaceholderText      = "#RRGGBB",
		PlaceholderColor3    = th.TextDim,
		BorderSizePixel      = 0,
		ZIndex               = 62,
		Parent               = panel,
	})
	Corner(hexBox, 6)

	-- Big color preview
	local bigPreview = New("Frame", {
		Size             = UDim2.new(0, 96, 0, 54),
		Position         = UDim2.new(0, rightX, 0, 44),
		BackgroundColor3 = startColor,
		BorderSizePixel  = 0,
		ZIndex           = 62,
		Parent           = panel,
	})
	Corner(bigPreview, 8)
	Stroke(bigPreview, th.Border, 1, 0.3)

	-- R / G / B input boxes
	local rgbLabels = {"R", "G", "B"}
	local rgbBoxes  = {}
	for i, lname in ipairs(rgbLabels) do
		local bx = i == 1 and startColor.R or (i == 2 and startColor.G or startColor.B)
		local xo = rightX + (i - 1) * 33
		New("TextLabel", {
			Size                 = UDim2.new(0, 28, 0, 14),
			Position             = UDim2.new(0, xo, 0, 104),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 9,
			TextColor3           = th.TextDim,
			Text                 = lname,
			ZIndex               = 62,
			Parent               = panel,
		})
		local rb = New("TextBox", {
			Size                 = UDim2.new(0, 28, 0, 22),
			Position             = UDim2.new(0, xo, 0, 120),
			BackgroundColor3     = th.Element,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 11,
			TextColor3           = th.Text,
			TextXAlignment       = Enum.TextXAlignment.Center,
			ClearTextOnFocus     = true,
			Text                 = tostring(math.floor(bx * 255)),
			BorderSizePixel      = 0,
			ZIndex               = 62,
			Parent               = panel,
		})
		Corner(rb, 5)
		table.insert(rgbBoxes, rb)
	end

	local function rebuild()
		local col = Color3.fromHSV(hue, sat, bri)
		preview.BackgroundColor3    = col
		bigPreview.BackgroundColor3 = col
		svBox.BackgroundColor3      = Color3.fromHSV(hue, 1, 1)
		svKnob.Position             = UDim2.new(sat, 0, 1 - bri, 0)
		hueKnob.Position            = UDim2.new(hue, 0, 0.5, 0)
		alphaKnob.Position          = UDim2.new(alpha, 0, 0.5, 0)
		hexBox.Text = string.format("#%02X%02X%02X",
			math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255))
		rgbBoxes[1].Text = tostring(math.floor(col.R * 255))
		rgbBoxes[2].Text = tostring(math.floor(col.G * 255))
		rgbBoxes[3].Text = tostring(math.floor(col.B * 255))
		if opts.Flag then Simpliciton.Flags[opts.Flag] = col; win.Flags[opts.Flag] = col end
		if opts.Callback then pcall(opts.Callback, col, alpha) end
	end

	-- Panel positioning
	local panelConn
	local function posPanel()
		if not header.Parent then return end
		local ap, as = header.AbsolutePosition, header.AbsoluteSize
		panel.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 5)
	end

	-- ── SV drag ─────────────────────────────────────────────────────────────────
	local svDrag = false
	svBox.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
	end)
	local svEnd = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
	end)
	local svStep = RunService.RenderStepped:Connect(function()
		if not svDrag or not Mouse then return end
		sat = math.clamp((Mouse.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
		bri = 1 - math.clamp((Mouse.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
		rebuild()
	end)
	table.insert(win._conns, svEnd)
	table.insert(win._conns, svStep)

	-- ── Hue drag ────────────────────────────────────────────────────────────────
	local hueDrag = false
	hueBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
	end)
	local hueEnd = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
	end)
	local hueStep = RunService.RenderStepped:Connect(function()
		if not hueDrag or not Mouse then return end
		hue = math.clamp((Mouse.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.9999)
		rebuild()
	end)
	table.insert(win._conns, hueEnd)
	table.insert(win._conns, hueStep)

	-- ── Alpha drag ──────────────────────────────────────────────────────────────
	local alphaDrag = false
	alphaBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then alphaDrag = true end
	end)
	local alphaEnd = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then alphaDrag = false end
	end)
	local alphaStep = RunService.RenderStepped:Connect(function()
		if not alphaDrag or not Mouse then return end
		alpha = math.clamp((Mouse.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
		rebuild()
	end)
	table.insert(win._conns, alphaEnd)
	table.insert(win._conns, alphaStep)

	-- ── Hex input ───────────────────────────────────────────────────────────────
	hexBox.FocusLost:Connect(function()
		local text = hexBox.Text:gsub("#", "")
		local r, g, b = text:match("^(%x%x)(%x%x)(%x%x)$")
		if r then
			local col = Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
			hue, sat, bri = Color3.toHSV(col)
			rebuild()
		end
	end)

	-- ── RGB inputs ──────────────────────────────────────────────────────────────
	for i, rb in ipairs(rgbBoxes) do
		rb.FocusLost:Connect(function()
			local nums = {}
			for _, b in ipairs(rgbBoxes) do
				nums[#nums + 1] = math.clamp(tonumber(b.Text) or 0, 0, 255)
			end
			local col = Color3.fromRGB(nums[1], nums[2], nums[3])
			hue, sat, bri = Color3.toHSV(col)
			rebuild()
		end)
	end

	-- ── Open/close ──────────────────────────────────────────────────────────────
	local isOpen = false
	local interact = New("TextButton", {
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "",
		ZIndex = 5, Parent = header,
	})
	interact.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		panel.Visible = isOpen
		dropArrow.Text = isOpen and "▴" or "▾"
		if isOpen then
			posPanel()
			panelConn = RunService.RenderStepped:Connect(posPanel)
		else
			if panelConn then panelConn:Disconnect(); panelConn = nil end
		end
	end)
	header.MouseEnter:Connect(function() Tween(header, {BackgroundColor3 = th.ElementHv}) end)
	header.MouseLeave:Connect(function() Tween(header, {BackgroundColor3 = th.Element}) end)

	rebuild()

	return {
		Set = function(_, col)
			hue, sat, bri = Color3.toHSV(col)
			rebuild()
		end,
		SetAlpha   = function(_, a) alpha = math.clamp(a, 0, 1); rebuild() end,
		Get        = function() return Color3.fromHSV(hue, sat, bri) end,
		GetAlpha   = function() return alpha end,
		SetVisible = function(_, v) header.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  PROGRESS BAR  (new element — animates with Tween)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateProgressBar(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local maxVal   = opts.Max    or 100
	local val      = math.clamp(opts.Value or 0, 0, maxVal)
	local suffix   = opts.Suffix or "%"
	local barColor = opts.Color  or th.Accent

	local f = makeCard(page, th, 54)
	Pad(f, 14, 14, 0, 0)

	-- Name
	New("TextLabel", {
		Size                 = UDim2.new(1, -84, 0, 22),
		Position             = UDim2.new(0, 0, 0, 9),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Progress",
		Parent               = f,
	})

	-- Percentage label
	local pctLbl = New("TextLabel", {
		Size                 = UDim2.new(0, 76, 0, 22),
		Position             = UDim2.new(1, -76, 0, 9),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 12,
		TextColor3           = barColor,
		TextXAlignment       = Enum.TextXAlignment.Right,
		Text                 = tostring(math.floor(val / maxVal * 100)) .. suffix,
		Parent               = f,
	})

	-- Track
	local track = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 7),
		Position         = UDim2.new(0, 0, 1, -16),
		AnchorPoint      = Vector2.new(0, 1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.25,
		BorderSizePixel  = 0,
		Parent           = f,
	})
	Corner(track, 4)

	local fill = New("Frame", {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = barColor,
		BorderSizePixel  = 0,
		Parent           = track,
	})
	Corner(fill, 4)
	-- Subtle shine gradient on fill
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, barColor),
			ColorSequenceKeypoint.new(0.5, brighten(barColor, 30)),
			ColorSequenceKeypoint.new(1, barColor),
		}),
		Parent = fill,
	})

	local function update(v)
		v = math.clamp(v, 0, maxVal)
		val = v
		local pct = (maxVal == 0) and 0 or (v / maxVal)
		Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.45, Enum.EasingStyle.Quint)
		pctLbl.Text = tostring(math.floor(pct * 100)) .. suffix
	end
	update(val)

	return {
		Set        = function(_, v) update(v) end,
		Get        = function() return val end,
		SetMax     = function(_, m) maxVal = m; update(val) end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  CONFIG SAVE / LOAD
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:SaveConfiguration()
	if not self._cfgEnabled then return end
	local ok, data = pcall(HttpService.JSONEncode, HttpService, self.Flags)
	if not ok then return end
	if writefile then
		ensureFolder(self._cfgFolder)
		callSafely(writefile, self._cfgFolder .. "/" .. self._cfgFile, data)
		self:Notify({
			Title    = "Config Saved",
			Content  = "Settings written to " .. self._cfgFile,
			Duration = 2.5,
			Image    = "",
			Type     = "success",
		})
	else
		print("[Simpliciton Config]\n" .. data)
	end
end

function Simpliciton:LoadConfiguration()
	if not self._cfgEnabled then return end
	if not (isfile and readfile) then return end
	local path = self._cfgFolder .. "/" .. self._cfgFile
	if not callSafely(isfile, path) then return end
	local raw = callSafely(readfile, path)
	if not raw then return end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok then return end
	for k, v in pairs(data) do
		self.Flags[k] = v
		Simpliciton.Flags[k] = v
	end
	self:Notify({
		Title    = "Config Loaded",
		Content  = "Settings restored from " .. self._cfgFile,
		Duration = 2.5,
		Image    = "",
		Type     = "success",
	})
end

-- Aliases
Simpliciton.SaveConfig = Simpliciton.SaveConfiguration
Simpliciton.LoadConfig = Simpliciton.LoadConfiguration

return Simpliciton
