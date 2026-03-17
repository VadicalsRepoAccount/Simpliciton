--[[
╔══════════════════════════════════════════════════════════════════════╗
║           Simpliciton  v6.0  "Crystal"                              ║
║           Premium glass-morphism UI library for Roblox              ║
╠══════════════════════════════════════════════════════════════════════╣
║  COMPLETE REWRITE from v5 — all bugs fixed, everything improved     ║
║                                                                      ║
║  CHANGES:                                                            ║
║  • Lucide icon support throughout (pass icon name as string)        ║
║  • Fixed minimize/maximize — correctly collapses to topbar only     ║
║  • Color picker completely rebuilt — real HSV, working hex+RGB      ║
║  • Notifications reworked — proper strip, spacing, Lucide X        ║
║  • All element padding normalised — consistent 16px gutters         ║
║  • All tweens tuned — no lag, correct easing curves                ║
║  • Tab icon system upgraded — Lucide or rbxassetid                 ║
║  • Window control buttons use Lucide X / Minus icons               ║
║  • Dropdown list panel redesigned                                   ║
║  • Input clear button improved                                      ║
║  • ProgressBar layout fixed                                         ║
║  • Slider drag feel improved                                        ║
║  • New element: CreateAlert (inline banner)                         ║
║  • New element: CreateSeparator (spacer with optional label)        ║
║  • Config save/load improved with merge                             ║
╠══════════════════════════════════════════════════════════════════════╣
║  ICON SYSTEM                                                         ║
║  Icons accept:                                                       ║
║    • number  → rbxassetid (e.g. 12345678)                          ║
║    • string  → Lucide icon name (e.g. "house", "settings",         ║
║                "shield", "zap", "user", "sword", "eye", etc.)      ║
║  Full Lucide catalogue: https://lucide.dev/icons/                   ║
║  Requires executor with HTTP image support for Lucide icons         ║
╠══════════════════════════════════════════════════════════════════════╣
║  API QUICK REFERENCE                                                 ║
║                                                                      ║
║  local Lib = loadstring(game:HttpGet("URL"))()                      ║
║  local Win = Lib:CreateWindow({                                      ║
║      Name     = "My Script",                                        ║
║      Subtitle = "v1.0",                                             ║
║      Theme    = "Dark",   -- Dark | Light | Midnight | Neon        ║
║      Icon     = "shield", -- Lucide name or rbxassetid             ║
║      ToggleUIKeybind    = Enum.KeyCode.RightShift,                  ║
║      ConfigurationSaving = {                                         ║
║          Enabled    = false,                                        ║
║          FolderName = "Simpliciton",                                ║
║          FileName   = "config",                                     ║
║      },                                                             ║
║  })                                                                  ║
║  local Tab = Win:CreateTab("Home", "house")                        ║
║                                                                      ║
║  Tab:CreateButton({ Name=, Description=, Style=, Callback= })      ║
║  Tab:CreateToggle({ Name=, Description=, CurrentValue=,            ║
║                     Flag=, Callback= })                             ║
║  Tab:CreateSlider({ Name=, Range={0,100}, Increment=1,             ║
║                     Suffix="", CurrentValue=0, Decimals=0,         ║
║                     Flag=, Callback= })                             ║
║  Tab:CreateDropdown({ Name=, Options={}, CurrentOption={},         ║
║                        MultipleOptions=false, Searchable=false,     ║
║                        Flag=, Callback= })                          ║
║  Tab:CreateInput({ Name=, CurrentValue="",                         ║
║                    PlaceholderText="", MaxLength=0,                 ║
║                    NumbersOnly=false, LiveCallback=false,           ║
║                    RemoveTextAfterFocusLost=false, Flag=,           ║
║                    Callback= })                                      ║
║  Tab:CreateKeybind({ Name=, CurrentKeybind="", Flag=,              ║
║                       Callback= })                                   ║
║  Tab:CreateColorPicker({ Name=, Color=Color3.new(1,1,1),           ║
║                           Alpha=1, Flag=, Callback= })              ║
║  Tab:CreateProgressBar({ Name=, Value=0, Max=100,                  ║
║                           Suffix="%", Color=nil })                  ║
║  Tab:CreateAlert({ Title=, Message=, Type="info" })                ║
║  Tab:CreateSection("Title", "icon-name")                           ║
║  Tab:CreateSeparator(labelText)                                     ║
║  Tab:CreateDivider()                                                ║
║  Tab:CreateLabel("Text", badgeText, badgeColor)                    ║
║  Tab:CreateParagraph({ Title=, Content= })                         ║
║                                                                      ║
║  Win:Notify({ Title=, Content=, Duration=4,                        ║
║               Image="check", Type="" })                             ║
║    Type: "success" | "error" | "warning" | "info"                  ║
║  Win:SaveConfiguration() / Win:LoadConfiguration()                  ║
║  Win:Destroy() / Win:SetTitle(t) / Win:SetTheme(name)              ║
║  Win:SetVisibility(bool) / Win:IsVisible()                         ║
║  Win:Minimise() / Win:Maximise()                                    ║
╚══════════════════════════════════════════════════════════════════════╝
]]

-- ── Services ──────────────────────────────────────────────────────────────────
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

-- ── Tween helper (non-laggy, always Quint unless specified) ───────────────────
local function Tween(obj, props, t, style, dir)
	if not obj or not obj.Parent then return end
	local ti = TweenInfo.new(
		t     or 0.18,
		style or Enum.EasingStyle.Quint,
		dir   or Enum.EasingDirection.Out
	)
	local ok, tw = pcall(TweenService.Create, TweenService, obj, ti, props)
	if ok and tw then tw:Play() end
end

-- ── Instance helpers ──────────────────────────────────────────────────────────
local function New(class, props)
	local ok, inst = pcall(Instance.new, class)
	if not ok then return nil end
	for k, v in pairs(props or {}) do pcall(function() inst[k] = v end) end
	return inst
end

local function Corner(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = f
	return c
end

local function Stroke(f, col, t, trans)
	local s = Instance.new("UIStroke")
	s.Color        = col   or Color3.new(1,1,1)
	s.Thickness    = t     or 1
	s.Transparency = trans or 0
	s.Parent       = f
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

local function VList(f, pad, halign)
	local l = Instance.new("UIListLayout")
	l.Padding            = UDim.new(0, pad or 6)
	l.FillDirection      = Enum.FillDirection.Vertical
	l.SortOrder          = Enum.SortOrder.LayoutOrder
	if halign then l.HorizontalAlignment = halign end
	l.Parent = f
	return l
end

local function HList(f, pad, valign)
	local l = Instance.new("UIListLayout")
	l.Padding           = UDim.new(0, pad or 6)
	l.FillDirection     = Enum.FillDirection.Horizontal
	l.SortOrder         = Enum.SortOrder.LayoutOrder
	if valign then l.VerticalAlignment = valign end
	l.Parent = f
	return l
end

local function AutoCanvas(scroll, list)
	pcall(function() scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
	local function update()
		if scroll and scroll.Parent then
			scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
		end
	end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
end

local function lerpColor(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function brighten(c, amt)
	return Color3.fromRGB(
		math.clamp(math.floor(c.R * 255) + amt, 0, 255),
		math.clamp(math.floor(c.G * 255) + amt, 0, 255),
		math.clamp(math.floor(c.B * 255) + amt, 0, 255)
	)
end

local function colorToHex(c)
	return string.format("%02X%02X%02X",
		math.floor(c.R * 255),
		math.floor(c.G * 255),
		math.floor(c.B * 255))
end

local function callSafely(fn, ...)
	if not fn then return nil end
	local ok, r = pcall(fn, ...)
	if not ok then warn("[Simpliciton] " .. tostring(r)) end
	return r
end

local function ensureFolder(path)
	if isfolder and not callSafely(isfolder, path) then
		callSafely(makefolder, path)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  LUCIDE ICON SYSTEM
--  Fetches SVGs from api.iconify.design — requires executor HTTP image support
--  Falls back silently if HTTP images are unsupported
-- ═══════════════════════════════════════════════════════════════════════════════
local ICONIFY_BASE = "https://api.iconify.design/lucide:%s.svg?color=%%23%s&width=%d&height=%d"

-- Creates an ImageLabel parented to `parent` showing a Lucide icon.
-- iconSpec: string icon name ("house"), or number rbxassetid.
-- size: pixel size (square). color: Color3. Returns the ImageLabel.
local function makeIcon(parent, iconSpec, size, color, position, anchorPoint, zi)
	size        = size        or 18
	color       = color       or Color3.new(1, 1, 1)
	position    = position    or UDim2.new(0, 0, 0.5, 0)
	anchorPoint = anchorPoint or Vector2.new(0, 0.5)
	zi          = zi          or 5

	local img = New("ImageLabel", {
		Size                 = UDim2.new(0, size, 0, size),
		Position             = position,
		AnchorPoint          = anchorPoint,
		BackgroundTransparency = 1,
		ImageColor3          = color,
		ZIndex               = zi,
		Parent               = parent,
	})

	if not iconSpec or iconSpec == 0 or iconSpec == "" then
		return img
	end

	if type(iconSpec) == "number" then
		img.Image = "rbxassetid://" .. tostring(iconSpec)
	elseif type(iconSpec) == "string" then
		if iconSpec:match("^rbxasset") or iconSpec:match("^http") then
			img.Image = iconSpec
		else
			-- Lucide icon name — try Iconify CDN
			local name = iconSpec:lower():gsub("[^%w%-]", "")
			local hex  = colorToHex(color)
			task.spawn(function()
				local url = string.format(ICONIFY_BASE, name, hex, size, size)
				pcall(function() img.Image = url end)
				-- Alternate fallback
				if img.Image == "" or img.Image == "rbxassetid://0" then
					pcall(function()
						img.Image = "https://cdn.jsdelivr.net/npm/lucide-static@latest/icons/" .. name .. ".svg"
					end)
				end
			end)
		end
	end

	return img
end

-- ── Themes ────────────────────────────────────────────────────────────────────
local Themes = {
	Dark = {
		BG        = Color3.fromRGB(12,  13,  20 ),
		Surface   = Color3.fromRGB(18,  20,  30 ),
		Element   = Color3.fromRGB(26,  28,  42 ),
		ElementHv = Color3.fromRGB(34,  36,  54 ),
		Accent    = Color3.fromRGB(108, 164, 255),
		AccentDim = Color3.fromRGB(62,  102, 196),
		Text      = Color3.fromRGB(232, 234, 248),
		TextDim   = Color3.fromRGB(110, 115, 150),
		Border    = Color3.fromRGB(44,  46,  68 ),
		Success   = Color3.fromRGB(72,  214, 132),
		Warning   = Color3.fromRGB(255, 192, 48 ),
		Error     = Color3.fromRGB(255, 72,  72 ),
		Info      = Color3.fromRGB(80,  180, 255),
		BGAlpha   = 0.18,
		BarAlpha  = 0.06,
	},
	Light = {
		BG        = Color3.fromRGB(238, 240, 252),
		Surface   = Color3.fromRGB(255, 255, 255),
		Element   = Color3.fromRGB(228, 230, 246),
		ElementHv = Color3.fromRGB(214, 216, 236),
		Accent    = Color3.fromRGB(72,  128, 228),
		AccentDim = Color3.fromRGB(48,  92,  180),
		Text      = Color3.fromRGB(20,  22,  38 ),
		TextDim   = Color3.fromRGB(118, 120, 155),
		Border    = Color3.fromRGB(196, 198, 220),
		Success   = Color3.fromRGB(32,  168, 92 ),
		Warning   = Color3.fromRGB(210, 148, 24 ),
		Error     = Color3.fromRGB(208, 48,  48 ),
		Info      = Color3.fromRGB(48,  140, 220),
		BGAlpha   = 0.05,
		BarAlpha  = 0.02,
	},
	Midnight = {
		BG        = Color3.fromRGB(8,    6,   18),
		Surface   = Color3.fromRGB(13,  10,   26),
		Element   = Color3.fromRGB(20,  16,   38),
		ElementHv = Color3.fromRGB(28,  22,   52),
		Accent    = Color3.fromRGB(162, 106, 255),
		AccentDim = Color3.fromRGB(108,  60, 198),
		Text      = Color3.fromRGB(228, 218, 255),
		TextDim   = Color3.fromRGB(118, 102, 162),
		Border    = Color3.fromRGB(42,  34,  72),
		Success   = Color3.fromRGB(72,  214, 152),
		Warning   = Color3.fromRGB(255, 196,  52),
		Error     = Color3.fromRGB(255,  72,  96),
		Info      = Color3.fromRGB(100, 172, 255),
		BGAlpha   = 0.20,
		BarAlpha  = 0.08,
	},
	Neon = {
		BG        = Color3.fromRGB(5,   11,  15),
		Surface   = Color3.fromRGB(9,   18,  24),
		Element   = Color3.fromRGB(12,  26,  34),
		ElementHv = Color3.fromRGB(16,  34,  44),
		Accent    = Color3.fromRGB(0,   228, 168),
		AccentDim = Color3.fromRGB(0,   155, 115),
		Text      = Color3.fromRGB(210, 254, 242),
		TextDim   = Color3.fromRGB(82,  152, 134),
		Border    = Color3.fromRGB(24,  62,  54),
		Success   = Color3.fromRGB(0,   228, 168),
		Warning   = Color3.fromRGB(255, 206,  52),
		Error     = Color3.fromRGB(255,  72,  72),
		Info      = Color3.fromRGB(52,  188, 255),
		BGAlpha   = 0.16,
		BarAlpha  = 0.07,
	},
	Rose = {
		BG        = Color3.fromRGB(14,   8,  10),
		Surface   = Color3.fromRGB(22,  12,  16),
		Element   = Color3.fromRGB(32,  18,  24),
		ElementHv = Color3.fromRGB(42,  24,  32),
		Accent    = Color3.fromRGB(255, 102, 140),
		AccentDim = Color3.fromRGB(196,  60,  96),
		Text      = Color3.fromRGB(255, 232, 238),
		TextDim   = Color3.fromRGB(160, 110, 128),
		Border    = Color3.fromRGB(68,  36,  48),
		Success   = Color3.fromRGB(80,  210, 140),
		Warning   = Color3.fromRGB(255, 192,  48),
		Error     = Color3.fromRGB(255,  72,  72),
		Info      = Color3.fromRGB(100, 172, 255),
		BGAlpha   = 0.22,
		BarAlpha  = 0.10,
	},
}

-- ═══════════════════════════════════════════════════════════════════════════════
--  LIBRARY OBJECT
-- ═══════════════════════════════════════════════════════════════════════════════
local Simpliciton = {}
Simpliciton.__index = Simpliciton
Simpliciton.Flags   = {}
Simpliciton.Version = "6.0"

-- ── GUI parent ────────────────────────────────────────────────────────────────
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

-- ── Draggable (Heartbeat-based, accurate, no jitter) ─────────────────────────
local function makeDraggable(frame, handle)
	local dragging  = false
	local relative  = Vector2.new()

	handle.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
		   input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true
		relative = frame.AbsolutePosition + frame.AbsoluteSize * frame.AnchorPoint
			- UserInputService:GetMouseLocation()
	end)

	local iEndConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local hbConn = RunService.Heartbeat:Connect(function()
		if not dragging then return end
		local mp  = UserInputService:GetMouseLocation()
		local pos = mp + relative
		-- Clamp inside screen
		local ss = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
			or Vector2.new(1920, 1080)
		local sx = math.clamp(pos.X, 0, ss.X - frame.AbsoluteSize.X)
		local sy = math.clamp(pos.Y, 0, ss.Y - frame.AbsoluteSize.Y)
		frame.Position = UDim2.fromOffset(sx, sy)
	end)

	frame.Destroying:Connect(function()
		pcall(function() iEndConn:Disconnect() end)
		pcall(function() hbConn:Disconnect() end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateWindow(opts)
	opts = opts or {}
	local win          = setmetatable({}, Simpliciton)
	win.Name           = opts.Name or "Simpliciton"
	win.Flags          = {}
	win._conns         = {}
	win._tabs          = {}
	win._currentTab    = nil
	win._minimised     = false
	win._visible       = true

	-- Theme
	local themeName = opts.Theme or "Dark"
	local th = (type(opts.Theme) == "table") and opts.Theme
	       or Themes[themeName]
	       or Themes.Dark
	win.Theme = th

	-- Config
	local cfg         = opts.ConfigurationSaving or {}
	win._cfgEnabled   = cfg.Enabled == true
	win._cfgFolder    = cfg.FolderName or "Simpliciton"
	win._cfgFile      = (cfg.FileName or tostring(game.PlaceId)) .. ".json"

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
			if c ~= sg and c.Name == sg.Name then pcall(c.Destroy, c) end
		end
	end
	win.ScreenGui = sg

	-- ── Main frame ─────────────────────────────────────────────────────────────
	local WINDOW_W, WINDOW_H = 700, 490
	local TOPBAR_H, BOTBAR_H = 52, 54

	local main = New("Frame", {
		Name                   = "Main",
		Size                   = UDim2.new(0, WINDOW_W, 0, WINDOW_H),
		Position               = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2),
		BackgroundColor3       = th.BG,
		BackgroundTransparency = th.BGAlpha,
		BorderSizePixel        = 0,
		ClipsDescendants       = true,
		Parent                 = sg,
	})
	Corner(main, 14)
	-- Outer border
	Stroke(main, th.Border, 1, 0.3)
	win.Main = main

	-- ── Top bar ────────────────────────────────────────────────────────────────
	local topbar = New("Frame", {
		Name                   = "Topbar",
		Size                   = UDim2.new(1, 0, 0, TOPBAR_H),
		Position               = UDim2.new(0, 0, 0, 0),
		BackgroundColor3       = th.Surface,
		BackgroundTransparency = th.BarAlpha,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		Parent                 = main,
	})
	-- Bottom divider line
	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.15,
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Parent           = topbar,
	})

	-- Window icon (left side of topbar)
	local titleLeftPad = 16
	if opts.Icon and opts.Icon ~= 0 and opts.Icon ~= "" then
		local iconBg = New("Frame", {
			Size             = UDim2.new(0, 30, 0, 30),
			Position         = UDim2.new(0, 14, 0.5, 0),
			AnchorPoint      = Vector2.new(0, 0.5),
			BackgroundColor3 = th.Accent,
			BackgroundTransparency = 0.78,
			BorderSizePixel  = 0,
			ZIndex           = 6,
			Parent           = topbar,
		})
		Corner(iconBg, 8)
		makeIcon(iconBg, opts.Icon, 16, th.Accent, UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5), 7)
		titleLeftPad = 52
	end

	-- Title + subtitle
	local titleHolder = New("Frame", {
		Size                 = UDim2.new(0, 300, 1, 0),
		Position             = UDim2.new(0, titleLeftPad, 0, 0),
		BackgroundTransparency = 1,
		ZIndex               = 6,
		Parent               = topbar,
	})
	VList(titleHolder, 1)
	Pad(titleHolder, 0, 0, 12, 8)

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

	-- ── Right-side control buttons ─────────────────────────────────────────────
	-- Helper: round icon button for topbar
	local function topBtn(posX, bgCol, bgColHv, iconName, iconColor)
		local btn = New("TextButton", {
			Size             = UDim2.new(0, 28, 0, 28),
			Position         = UDim2.new(1, posX, 0.5, 0),
			AnchorPoint      = Vector2.new(1, 0.5),
			BackgroundColor3 = bgCol,
			Text             = "",
			ZIndex           = 7,
			Parent           = topbar,
		})
		Corner(btn, 14)
		makeIcon(btn, iconName, 14, iconColor or Color3.new(1,1,1),
			UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5), 8)
		btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = bgColHv}) end)
		btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = bgCol}) end)
		return btn
	end

	-- Close button (red circle, X icon)
	local closeBtn = topBtn(-14, Color3.fromRGB(255,60,60), Color3.fromRGB(255,100,100), "x")
	closeBtn.MouseButton1Click:Connect(function() win:Destroy() end)

	-- Minimize button (amber circle, minus icon)
	local minBtn = topBtn(-50, Color3.fromRGB(255,182,30), Color3.fromRGB(255,212,80), "minus",
		Color3.fromRGB(140,88,0))
	minBtn.MouseButton1Click:Connect(function()
		if win._minimised then win:Maximise() else win:Minimise() end
	end)

	-- Config save button (only if config enabled)
	local cfgBtnX = -86
	if win._cfgEnabled then
		local saveBtn = New("TextButton", {
			Size             = UDim2.new(0, 28, 0, 28),
			Position         = UDim2.new(1, cfgBtnX, 0.5, 0),
			AnchorPoint      = Vector2.new(1, 0.5),
			BackgroundColor3 = th.Element,
			Text             = "",
			ZIndex           = 7,
			Parent           = topbar,
		})
		Corner(saveBtn, 8)
		Stroke(saveBtn, th.Border, 1, 0.35)
		makeIcon(saveBtn, "save", 14, th.TextDim, UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5), 8)
		saveBtn.MouseEnter:Connect(function()
			Tween(saveBtn, {BackgroundColor3 = th.ElementHv})
		end)
		saveBtn.MouseLeave:Connect(function()
			Tween(saveBtn, {BackgroundColor3 = th.Element})
		end)
		saveBtn.MouseButton1Click:Connect(function() win:SaveConfiguration() end)
	end

	makeDraggable(main, topbar)

	-- ── Content area ───────────────────────────────────────────────────────────
	local content = New("Frame", {
		Name                 = "Content",
		Size                 = UDim2.new(1, 0, 1, -(TOPBAR_H + BOTBAR_H)),
		Position             = UDim2.new(0, 0, 0, TOPBAR_H),
		BackgroundTransparency = 1,
		ClipsDescendants     = false,
		Parent               = main,
	})
	win._content  = content
	win._topbarH  = TOPBAR_H
	win._botbarH  = BOTBAR_H
	win._windowH  = WINDOW_H
	win._windowW  = WINDOW_W

	-- ── Bottom tab bar ──────────────────────────────────────────────────────────
	local bottomBar = New("Frame", {
		Name                   = "BottomBar",
		Size                   = UDim2.new(1, 0, 0, BOTBAR_H),
		Position               = UDim2.new(0, 0, 1, -BOTBAR_H),
		BackgroundColor3       = th.Surface,
		BackgroundTransparency = th.BarAlpha,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		Parent                 = main,
	})
	-- Top divider
	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.15,
		BorderSizePixel  = 0,
		ZIndex           = 5,
		Parent           = bottomBar,
	})
	win._bottomBar = bottomBar

	local tabBarInner = New("Frame", {
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex               = 5,
		Parent               = bottomBar,
	})
	HList(tabBarInner, 0)
	win._tabBarInner = tabBarInner

	-- ── Notification container (screen-level, bottom-right) ────────────────────
	local notifStack = New("Frame", {
		Size                 = UDim2.new(0, 340, 1, 0),
		Position             = UDim2.new(1, -356, 0, 0),
		BackgroundTransparency = 1,
		ZIndex               = 200,
		Parent               = sg,
	})
	local notifList = VList(notifStack, 8)
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	Pad(notifStack, 0, 0, 0, 20)
	win._notifStack = notifStack

	-- ── Global keybind ──────────────────────────────────────────────────────────
	if opts.ToggleUIKeybind then
		local key = opts.ToggleUIKeybind
		if typeof(key) == "EnumItem" then key = key.Name end
		local conn = UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if tostring(input.KeyCode):find(key, 1, true) then
				main.Visible  = not main.Visible
				win._visible  = main.Visible
			end
		end)
		table.insert(win._conns, conn)
	end

	-- Auto-load config
	if win._cfgEnabled then
		task.spawn(function() task.wait(1); win:LoadConfiguration() end)
	end

	return win
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  WINDOW METHODS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Minimise: collapse to topbar height only — hide content & bottom bar first
function Simpliciton:Minimise()
	if self._minimised then return end
	self._minimised = true
	-- Hide content & bottom bar so they don't peek through
	self._content.Visible   = false
	self._bottomBar.Visible = false
	Tween(self.Main, {Size = UDim2.new(0, self._windowW, 0, self._topbarH)},
		0.3, Enum.EasingStyle.Quint)
end

-- Maximise: restore full size — show content & bottom bar after tween
function Simpliciton:Maximise()
	if not self._minimised then return end
	self._minimised = false
	Tween(self.Main, {Size = UDim2.new(0, self._windowW, 0, self._windowH)},
		0.35, Enum.EasingStyle.Back)
	task.delay(0.28, function()
		self._content.Visible   = true
		self._bottomBar.Visible = true
	end)
end

function Simpliciton:SetTitle(text)
	if self._titleLabel then self._titleLabel.Text = text end
end

function Simpliciton:SetTheme(name)
	-- Basic live theme switch — updates stored theme reference
	local t = (type(name) == "table") and name or Themes[name]
	if t then self.Theme = t end
end

function Simpliciton:Destroy()
	for _, c in ipairs(self._conns or {}) do pcall(c.Disconnect, c) end
	if self.ScreenGui then pcall(self.ScreenGui.Destroy, self.ScreenGui) end
end

function Simpliciton:SetVisibility(v)
	self._visible = v
	if self.Main then self.Main.Visible = v end
end

function Simpliciton:IsVisible() return self._visible ~= false end

-- ── Tab selection ─────────────────────────────────────────────────────────────
function Simpliciton:_SelectTab(tab)
	self._currentTab = tab
	for _, t in ipairs(self._tabs) do
		local sel = (t == tab)
		t._page.Visible = sel
		Tween(t._btnIcon,  {ImageColor3  = sel and self.Theme.Accent or self.Theme.TextDim}, 0.18)
		Tween(t._btnLabel, {TextColor3   = sel and self.Theme.Accent or self.Theme.TextDim}, 0.18)
		Tween(t._btnIndicator, {
			BackgroundTransparency = sel and 0 or 1,
			Size = sel and UDim2.new(0.6, 0, 0, 3) or UDim2.new(0.2, 0, 0, 3),
		}, sel and 0.28 or 0.15, sel and Enum.EasingStyle.Back or Enum.EasingStyle.Quint)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  NOTIFICATIONS  (completely rewritten)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:Notify(titleOrData, content, duration, notifType)
	local title, imageVal
	if type(titleOrData) == "table" then
		local d  = titleOrData
		title     = d.Title    or "Notice"
		content   = d.Content  or ""
		duration  = d.Duration or 4
		notifType = d.Type
		imageVal  = d.Image
	else
		title    = titleOrData or "Notice"
		content  = content     or ""
		duration = duration    or 4
	end

	local th = self.Theme
	local accentColor =
		(notifType == "success" and th.Success) or
		(notifType == "error"   and th.Error)   or
		(notifType == "warning" and th.Warning)  or
		(notifType == "info"    and th.Info)     or
		th.Accent

	task.spawn(function()
		-- Outer card
		local notif = New("Frame", {
			Size                   = UDim2.new(1, 0, 0, 76),
			Position               = UDim2.new(1.05, 0, 0, 0),
			BackgroundColor3       = th.Surface,
			BackgroundTransparency = 0.05,
			ClipsDescendants       = true,
			ZIndex                 = 201,
			Parent                 = self._notifStack,
		})
		Corner(notif, 12)
		Stroke(notif, accentColor, 1, 0.5)

		-- Left accent strip (4px wide, full height, clipped by parent corner)
		local strip = New("Frame", {
			Size             = UDim2.new(0, 4, 1, 0),
			Position         = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel  = 0,
			ZIndex           = 202,
			Parent           = notif,
		})
		-- Square the right side corners by overlapping a wider rect behind
		New("Frame", {
			Size             = UDim2.new(0, 4, 1, 0),
			Position         = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel  = 0,
			ZIndex           = 201,
			Parent           = notif,
		})
		Corner(strip, 12)

		-- Icon chip (if provided) — positioned right after the strip
		local bodyLeft = 18  -- left offset for title/body text
		if imageVal and imageVal ~= 0 and imageVal ~= "" then
			local iconBg = New("Frame", {
				Size                   = UDim2.new(0, 36, 0, 36),
				Position               = UDim2.new(0, 14, 0.5, 0),
				AnchorPoint            = Vector2.new(0, 0.5),
				BackgroundColor3       = accentColor,
				BackgroundTransparency = 0.7,
				BorderSizePixel        = 0,
				ZIndex                 = 203,
				Parent                 = notif,
			})
			Corner(iconBg, 9)

			if type(imageVal) == "number" then
				New("ImageLabel", {
					Size                 = UDim2.new(0, 20, 0, 20),
					Position             = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint          = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image                = "rbxassetid://" .. tostring(imageVal),
					ZIndex               = 204,
					Parent               = iconBg,
				})
			else
				-- String = Lucide icon name
				makeIcon(iconBg, tostring(imageVal), 18, Color3.new(1,1,1),
					UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5), 204)
			end
			bodyLeft = 60
		end

		-- Title
		New("TextLabel", {
			Size                 = UDim2.new(1, -(bodyLeft + 36), 0, 20),
			Position             = UDim2.new(0, bodyLeft, 0, 12),
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

		-- Body
		New("TextLabel", {
			Size                 = UDim2.new(1, -(bodyLeft + 36), 0, 28),
			Position             = UDim2.new(0, bodyLeft, 0, 34),
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

		-- Close (X) button — top-right, uses Lucide x icon
		local dismissed = false
		local closeXBtn = New("TextButton", {
			Size                 = UDim2.new(0, 28, 0, 28),
			Position             = UDim2.new(1, -8, 0, 6),
			AnchorPoint          = Vector2.new(1, 0),
			BackgroundColor3     = th.ElementHv,
			BackgroundTransparency = 1,
			Text                 = "",
			ZIndex               = 205,
			Parent               = notif,
		})
		Corner(closeXBtn, 7)
		makeIcon(closeXBtn, "x", 14, th.TextDim, UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5), 206)
		closeXBtn.MouseEnter:Connect(function()
			Tween(closeXBtn, {BackgroundTransparency = 0.4})
		end)
		closeXBtn.MouseLeave:Connect(function()
			Tween(closeXBtn, {BackgroundTransparency = 1})
		end)
		closeXBtn.MouseButton1Click:Connect(function() dismissed = true end)

		-- Progress bar (inset inside the card, at the very bottom)
		-- Bg track
		local progBg = New("Frame", {
			Size             = UDim2.new(1, -4, 0, 3),
			Position         = UDim2.new(0, 4, 1, -3),
			BackgroundColor3 = th.Border,
			BackgroundTransparency = 0.3,
			BorderSizePixel  = 0,
			ZIndex           = 202,
			Parent           = notif,
		})
		-- Fill
		local progFill = New("Frame", {
			Size             = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel  = 0,
			ZIndex           = 203,
			Parent           = progBg,
		})
		Corner(progBg, 2)
		Corner(progFill, 2)

		-- Slide IN from right
		task.wait()
		Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.35, Enum.EasingStyle.Back)

		-- Shrink progress bar over duration (linear)
		Tween(progFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

		-- Wait
		local elapsed, step = 0, 0.05
		while elapsed < duration and not dismissed do
			task.wait(step)
			elapsed = elapsed + step
		end

		-- Slide OUT to right
		Tween(notif, {Position = UDim2.new(1.05, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quint)
		task.wait(0.28)
		pcall(notif.Destroy, notif)
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  CREATE TAB
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateTab(name, icon)
	local th  = self.Theme
	local tab = { _win = self, _elements = {} }

	-- Bottom bar button (equal width slots)
	local btn = New("TextButton", {
		Size                 = UDim2.new(0.25, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                 = "",
		ZIndex               = 6,
		Parent               = self._tabBarInner,
	})

	-- Top accent indicator bar
	local indicator = New("Frame", {
		Size             = UDim2.new(0.25, 0, 0, 3),
		Position         = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint      = Vector2.new(0.5, 0),
		BackgroundColor3 = th.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel  = 0,
		ZIndex           = 7,
		Parent           = btn,
	})
	Corner(indicator, 2)

	-- Icon (Lucide or emoji fallback)
	local iconImg = makeIcon(btn, icon, 20, th.TextDim,
		UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0), 7)

	-- Tab name label
	local nameLbl = New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 11),
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
	tab._btnIcon      = iconImg
	tab._btnLabel     = nameLbl
	tab._btnIndicator = indicator

	-- Tab page (scrollable)
	local page = New("ScrollingFrame", {
		Name                   = "Page_" .. name,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness     = 3,
		ScrollBarImageColor3   = th.Accent,
		ScrollBarImageTransparency = 0.5,
		BackgroundTransparency = 1,
		ClipsDescendants       = false,
		Visible                = false,
		BorderSizePixel        = 0,
		Parent                 = self._content,
	})
	local pageList = VList(page, 6)
	Pad(page, 12, 12, 10, 10)
	AutoCanvas(page, pageList)

	tab._page     = page
	tab._pageList = pageList

	btn.MouseButton1Click:Connect(function() self:_SelectTab(tab) end)
	table.insert(self._tabs, tab)
	setmetatable(tab, { __index = self })

	-- Resize all tab buttons equally
	task.spawn(function()
		task.wait()
		local count = #self._tabs
		for _, t in ipairs(self._tabs) do
			t._btn.Size = UDim2.new(1 / count, 0, 1, 0)
		end
	end)

	-- Auto-select first tab
	if #self._tabs == 1 then self:_SelectTab(tab) end

	return tab
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SHARED ELEMENT HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════
local function getPage(self)
	return rawget(self, "_page")
		or (rawget(self, "_win") and self._win._currentTab and self._win._currentTab._page)
end

local function getWin(self)  return rawget(self, "_win") or self end
local function getTheme(self) return (getWin(self)).Theme or Themes.Dark end

-- Standard card frame with consistent sizing
local function makeCard(page, th, height, alpha)
	local f = New("Frame", {
		Size                   = UDim2.new(1, 0, 0, height or 46),
		BackgroundColor3       = th.Element,
		BackgroundTransparency = alpha or 0,
		BorderSizePixel        = 0,
		Parent                 = page,
	})
	Corner(f, 10)
	return f
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SECTION
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateSection(title, icon)
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local f = New("Frame", {
		Size                 = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent               = page,
	})

	local textX = 0
	if icon and icon ~= "" then
		makeIcon(f, icon, 14, th.Accent, UDim2.new(0, 2, 0.5, 0), Vector2.new(0, 0.5), 2)
		textX = 20
	end

	local lbl = New("TextLabel", {
		Size                 = UDim2.new(1, -textX, 1, -12),
		Position             = UDim2.new(0, textX, 0, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 11,
		TextColor3           = th.Accent,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = string.upper(title or "Section"),
		Parent               = f,
	})

	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.2,
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
		BackgroundTransparency = 0.25,
		BorderSizePixel  = 0,
		Parent           = page,
	})
	return { SetVisible = function(_, v) f.Visible = v end }
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SEPARATOR  (divider with optional centred label)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateSeparator(labelText)
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	if not labelText or labelText == "" then
		return self:CreateDivider()
	end

	local f = New("Frame", {
		Size                 = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Parent               = page,
	})

	-- Left line
	New("Frame", {
		Size             = UDim2.new(0.38, -6, 0, 1),
		Position         = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.25,
		BorderSizePixel  = 0,
		Parent           = f,
	})
	-- Right line
	New("Frame", {
		Size             = UDim2.new(0.38, -6, 0, 1),
		Position         = UDim2.new(0.62, 6, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.25,
		BorderSizePixel  = 0,
		Parent           = f,
	})
	-- Label
	local lbl = New("TextLabel", {
		Size                 = UDim2.new(0.24, 0, 1, 0),
		Position             = UDim2.new(0.38, 0, 0, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 10,
		TextColor3           = th.TextDim,
		Text                 = labelText,
		Parent               = f,
	})

	return {
		Set        = function(_, t) lbl.Text = t end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  LABEL
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateLabel(text, badgeText, badgeColor)
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local f = makeCard(page, th, 40)
	f.BackgroundColor3 = th.Surface
	Stroke(f, th.Border, 1, 0.6)
	Pad(f, 16, 16, 0, 0)

	local lbl = New("TextLabel", {
		Size                 = UDim2.new(1, badgeText and -58 or 0, 1, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 13,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = text or "",
		Parent               = f,
	})

	if badgeText then
		local chip = New("Frame", {
			Size             = UDim2.new(0, 52, 0, 22),
			Position         = UDim2.new(1, -52, 0.5, 0),
			AnchorPoint      = Vector2.new(0, 0.5),
			BackgroundColor3 = badgeColor or th.Accent,
			BackgroundTransparency = 0.72,
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
	Pad(f, 16, 16, 12, 12)
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
		RichText             = true,
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
--  ALERT  (inline coloured banner)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateAlert(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local alertType = opts.Type or "info"
	local accentCol =
		(alertType == "success" and th.Success) or
		(alertType == "error"   and th.Error)   or
		(alertType == "warning" and th.Warning)  or
		th.Info

	local f = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = accentCol,
		BackgroundTransparency = 0.84,
		BorderSizePixel  = 0,
		Parent           = page,
	})
	Corner(f, 10)
	Stroke(f, accentCol, 1, 0.55)

	-- Left strip
	New("Frame", {
		Size             = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = accentCol,
		BorderSizePixel  = 0,
		ZIndex           = 2,
		Parent           = f,
	})
	-- (also with corner to match parent)
	local strip2 = New("Frame", {
		Size             = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = accentCol,
		BorderSizePixel  = 0,
		ZIndex           = 1,
		Parent           = f,
	})
	Corner(strip2, 10)

	local inner = New("Frame", {
		Size             = UDim2.new(1, -22, 0, 0),
		Position         = UDim2.new(0, 18, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent           = f,
	})
	VList(inner, 3)
	Pad(inner, 0, 0, 10, 10)

	if opts.Title and opts.Title ~= "" then
		New("TextLabel", {
			Size                 = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 12,
			TextColor3           = accentCol,
			TextXAlignment       = Enum.TextXAlignment.Left,
			Text                 = opts.Title,
			Parent               = inner,
		})
	end

	local msgLbl = New("TextLabel", {
		Size                 = UDim2.new(1, 0, 0, 0),
		AutomaticSize        = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 12,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		TextWrapped          = true,
		Text                 = opts.Message or "",
		Parent               = inner,
	})

	return {
		Set = function(_, t) msgLbl.Text = t end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  BUTTON
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateButton(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local style = opts.Style or "Accent"
	local bgColor, fgColor, strokeCol, strokeTrans

	if style == "Accent" then
		bgColor = th.Accent;    fgColor = Color3.new(1,1,1)
	elseif style == "Secondary" then
		bgColor = th.Element;   fgColor = th.Text;
		strokeCol = th.Border;  strokeTrans = 0.2
	elseif style == "Danger" then
		bgColor = th.Error;     fgColor = Color3.new(1,1,1)
	elseif style == "Ghost" then
		bgColor = th.Element;   fgColor = th.Accent;
		strokeCol = th.Accent;  strokeTrans = 0.55
	else
		bgColor = th.Accent;    fgColor = Color3.new(1,1,1)
	end

	local hasDesc = opts.Description and opts.Description ~= ""
	local height  = hasDesc and 60 or 44

	local f = New("Frame", {
		Size             = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = bgColor,
		BorderSizePixel  = 0,
		Parent           = page,
	})
	Corner(f, 10)
	if strokeCol then Stroke(f, strokeCol, 1, strokeTrans or 0) end

	-- Left icon (optional)
	local nameOffX = 0
	if opts.Icon then
		makeIcon(f, opts.Icon, 16, fgColor,
			UDim2.new(0, 14, 0.5, hasDesc and -8 or 0), Vector2.new(0, 0.5), 3)
		nameOffX = 36
	end

	-- Name label (centred vertically if no description, else pushed up)
	local nameLbl = New("TextLabel", {
		Size                 = UDim2.new(1, -(14 + nameOffX), 0, hasDesc and 22 or height),
		Position             = UDim2.new(0, nameOffX, 0, hasDesc and 10 or 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamSemibold,
		TextSize             = 13,
		TextColor3           = fgColor,
		TextXAlignment       = nameOffX > 0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
		Text                 = opts.Name or "Button",
		ZIndex               = 3,
		Parent               = f,
	})
	Pad(nameLbl, 14 + nameOffX, 14, 0, 0)
	nameLbl.Size = UDim2.new(1, 0, 0, hasDesc and 22 or height)
	nameLbl.Position = UDim2.new(0, 0, 0, hasDesc and 10 or 0)

	if hasDesc then
		New("TextLabel", {
			Size                 = UDim2.new(1, 0, 0, 16),
			Position             = UDim2.new(0, 0, 0, 34),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.Gotham,
			TextSize             = 11,
			TextColor3           = (style == "Accent")
				and Color3.fromRGB(195, 218, 255) or th.TextDim,
			TextXAlignment       = Enum.TextXAlignment.Center,
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

	local _loading = false
	local _enabled = true
	local bgHover  = brighten(bgColor, 20)

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
		Tween(f, {BackgroundTransparency = 0.2}, 0.07)
	end)
	interact.MouseButton1Up:Connect(function()
		Tween(f, {BackgroundTransparency = 0}, 0.1)
	end)
	interact.MouseButton1Click:Connect(function()
		if not _enabled or _loading then return end
		if opts.Callback then pcall(opts.Callback) end
	end)

	return {
		Set = function(_, t) nameLbl.Text = t end,
		SetEnabled = function(_, v)
			_enabled = v
			interact.Active = v
			Tween(f, {BackgroundTransparency = v and 0 or 0.55})
		end,
		SetLoading = function(_, v)
			_loading = v
			nameLbl.Text = v and "Loading…" or (opts.Name or "Button")
			Tween(f, {BackgroundTransparency = v and 0.3 or 0})
		end,
		SetVisible = function(_, v) f.Visible = v end,
		Fire = function(_) if opts.Callback then pcall(opts.Callback) end end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  TOGGLE
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateToggle(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local val     = opts.CurrentValue == true
	local hasDesc = opts.Description and opts.Description ~= ""
	local height  = hasDesc and 60 or 46
	if opts.Flag then Simpliciton.Flags[opts.Flag] = val; win.Flags[opts.Flag] = val end

	local f = makeCard(page, th, height)
	Pad(f, 16, 16, 0, 0)

	New("TextLabel", {
		Size                 = UDim2.new(1, -64, 0, hasDesc and 22 or height),
		Position             = UDim2.new(0, 0, 0, hasDesc and 10 or 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Toggle",
		Parent               = f,
	})

	if hasDesc then
		New("TextLabel", {
			Size                 = UDim2.new(1, -64, 0, 16),
			Position             = UDim2.new(0, 0, 0, 34),
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
			win.Flags[opts.Flag]         = v
		end
		Tween(track, {BackgroundColor3 = v and th.Accent or th.Border}, 0.2)
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
--  SLIDER  (drag knob OR click value box to type exact number)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateSlider(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local mn  = (opts.Range and opts.Range[1]) or opts.Min or 0
	local mx  = (opts.Range and opts.Range[2]) or opts.Max or 100
	local inc = opts.Increment
	local val = math.clamp(opts.CurrentValue or mn, mn, mx)
	local dp  = opts.Decimals or 0
	if opts.Flag then Simpliciton.Flags[opts.Flag] = val; win.Flags[opts.Flag] = val end

	local f = makeCard(page, th, 70)
	Pad(f, 16, 16, 0, 0)

	-- Name label (upper-left)
	New("TextLabel", {
		Size                 = UDim2.new(1, -96, 0, 22),
		Position             = UDim2.new(0, 0, 0, 12),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Slider",
		Parent               = f,
	})

	-- Value TextBox — click to type an exact number
	local valBox = New("TextBox", {
		Size                   = UDim2.new(0, 80, 0, 26),
		Position               = UDim2.new(1, -80, 0, 10),
		BackgroundColor3       = th.BG,
		BackgroundTransparency = 0.4,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 12,
		TextColor3             = th.Accent,
		TextXAlignment         = Enum.TextXAlignment.Center,
		ClearTextOnFocus       = true,
		Text                   = "",
		BorderSizePixel        = 0,
		ZIndex                 = 5,
		Parent                 = f,
	})
	Corner(valBox, 8)
	local valStroke = Stroke(valBox, th.Border, 1, 0.4)

	-- Min / max hint labels (below track)
	New("TextLabel", {
		Size                 = UDim2.new(0.5, 0, 0, 13),
		Position             = UDim2.new(0, 0, 1, -16),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 10,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = tostring(mn) .. (opts.Suffix and (" " .. opts.Suffix) or ""),
		Parent               = f,
	})
	New("TextLabel", {
		Size                 = UDim2.new(0.5, 0, 0, 13),
		Position             = UDim2.new(0.5, 0, 1, -16),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 10,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Right,
		Text                 = tostring(mx) .. (opts.Suffix and (" " .. opts.Suffix) or ""),
		Parent               = f,
	})

	-- Track background
	local track = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 6),
		Position         = UDim2.new(0, 0, 1, -32),
		AnchorPoint      = Vector2.new(0, 1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.15,
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		Parent           = f,
	})
	Corner(track, 3)

	-- Filled portion
	local fill = New("Frame", {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = th.Accent,
		BorderSizePixel  = 0,
		Parent           = track,
	})
	Corner(fill, 3)
	New("UIGradient", {
		Color  = ColorSequence.new(th.AccentDim or th.Accent, brighten(th.Accent, 15)),
		Parent = fill,
	})

	-- Knob
	local knob = New("Frame", {
		Size             = UDim2.new(0, 18, 0, 18),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 4,
		Parent           = track,
	})
	Corner(knob, 9)
	Stroke(knob, th.Accent, 2.5, 0)

	local function update(v, fire)
		if inc and inc > 0 then
			v = math.floor(v / inc + 0.5) * inc
		end
		v   = math.clamp(v, mn, mx)
		v   = tonumber(string.format("%." .. dp .. "f", v)) or v
		val = v
		local pct = (mx == mn) and 0 or ((v - mn) / (mx - mn))
		fill.Size     = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		valBox.Text   = tostring(v) .. (opts.Suffix and (" " .. opts.Suffix) or "")
		if fire then
			if opts.Flag then Simpliciton.Flags[opts.Flag] = v; win.Flags[opts.Flag] = v end
			if opts.Callback then pcall(opts.Callback, v) end
		end
	end
	update(val, false)

	-- Type-in value
	valBox.Focused:Connect(function()
		valBox.Text = tostring(val)
		valStroke.Color        = th.Accent
		valStroke.Transparency = 0
		Tween(valBox, {BackgroundTransparency = 0.2})
	end)
	valBox.FocusLost:Connect(function()
		local num = tonumber(valBox.Text)
		if num then
			update(num, true)
		else
			valBox.Text = tostring(val) .. (opts.Suffix and (" " .. opts.Suffix) or "")
		end
		valStroke.Color        = th.Border
		valStroke.Transparency = 0.4
		Tween(valBox, {BackgroundTransparency = 0.4})
	end)

	-- Drag interaction
	local dragging = false
	local interactArea = New("TextButton", {
		Size                 = UDim2.new(1, 0, 0, 28),
		Position             = UDim2.new(0, 0, 1, -34),
		AnchorPoint          = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Text                 = "",
		ZIndex               = 6,
		Parent               = f,
	})
	interactArea.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
		   input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true
	end)
	local sliderEndConn = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or
		   i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	local sliderHBConn = RunService.Heartbeat:Connect(function()
		if not dragging then return end
		local x   = UserInputService:GetMouseLocation().X
		local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		update(mn + (mx - mn) * pct, true)
	end)
	table.insert(win._conns, sliderEndConn)
	table.insert(win._conns, sliderHBConn)

	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set        = function(_, v) update(v, true) end,
		Get        = function() return val end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  INPUT
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateInput(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local maxLen = opts.MaxLength or 0
	local f = makeCard(page, th, 68)
	Pad(f, 16, 16, 0, 0)

	-- Name label + optional char counter (same row)
	New("TextLabel", {
		Size                 = UDim2.new(1, maxLen > 0 and -60 or 0, 0, 22),
		Position             = UDim2.new(0, 0, 0, 8),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Input",
		Parent               = f,
	})

	local counterLbl
	if maxLen > 0 then
		counterLbl = New("TextLabel", {
			Size                 = UDim2.new(0, 56, 0, 22),
			Position             = UDim2.new(1, -56, 0, 8),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.Gotham,
			TextSize             = 11,
			TextColor3           = th.TextDim,
			TextXAlignment       = Enum.TextXAlignment.Right,
			Text                 = "0 / " .. maxLen,
			Parent               = f,
		})
	end

	-- Text field
	local box = New("TextBox", {
		Size                 = UDim2.new(1, 0, 0, 32),
		Position             = UDim2.new(0, 0, 1, -38),
		AnchorPoint          = Vector2.new(0, 1),
		BackgroundColor3     = th.BG,
		BackgroundTransparency = 0.3,
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
	local boxStroke = Stroke(box, th.Border, 1, 0.35)
	Pad(box, 12, 36, 0, 0)

	-- Clear button inside right side of box
	local clearBtn = New("TextButton", {
		Size                 = UDim2.new(0, 30, 0, 30),
		Position             = UDim2.new(1, -32, 0.5, 0),
		AnchorPoint          = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Text                 = "",
		ZIndex               = 4,
		Parent               = box,
	})
	makeIcon(clearBtn, "x-circle", 14, th.TextDim,
		UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5), 5)
	clearBtn.Visible = (box.Text ~= "")
	clearBtn.MouseButton1Click:Connect(function()
		box.Text = ""
		clearBtn.Visible = false
		if counterLbl then counterLbl.Text = "0 / " .. maxLen end
	end)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local t = box.Text
		if maxLen > 0 and #t > maxLen then
			box.Text = t:sub(1, maxLen)
			return
		end
		if opts.NumbersOnly then
			local clean = t:gsub("[^%d%.-]", "")
			if clean ~= t then box.Text = clean; return end
		end
		if counterLbl then
			local cnt = #box.Text
			counterLbl.Text  = cnt .. " / " .. maxLen
			counterLbl.TextColor3 = (maxLen > 0 and cnt >= maxLen) and th.Error or th.TextDim
		end
		clearBtn.Visible = (#box.Text > 0)
		if opts.LiveCallback and opts.Callback then pcall(opts.Callback, box.Text) end
	end)

	box.Focused:Connect(function()
		boxStroke.Color        = th.Accent
		boxStroke.Transparency = 0
		Tween(box, {BackgroundTransparency = 0.15})
	end)
	box.FocusLost:Connect(function()
		boxStroke.Color        = th.Border
		boxStroke.Transparency = 0.35
		Tween(box, {BackgroundTransparency = 0.3})
		local text = box.Text
		if opts.RemoveTextAfterFocusLost then
			box.Text = ""; clearBtn.Visible = false
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
--  DROPDOWN
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateDropdown(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local multi = opts.MultipleOptions == true
	local selected = {}
	if type(opts.CurrentOption) == "string" then
		selected = {opts.CurrentOption}
	elseif type(opts.CurrentOption) == "table" then
		selected = {table.unpack(opts.CurrentOption)}
	end
	if not multi and #selected > 1 then selected = {selected[1]} end
	if opts.Flag then Simpliciton.Flags[opts.Flag] = selected; win.Flags[opts.Flag] = selected end

	local isOpen = false

	-- Header card
	local header = makeCard(page, th, 46)
	Pad(header, 16, 16, 0, 0)

	New("TextLabel", {
		Size                 = UDim2.new(1, -145, 1, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Dropdown",
		Parent               = header,
	})

	local selLbl = New("TextLabel", {
		Size                 = UDim2.new(0, 106, 1, 0),
		Position             = UDim2.new(1, -122, 0, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.Gotham,
		TextSize             = 12,
		TextColor3           = th.TextDim,
		TextXAlignment       = Enum.TextXAlignment.Right,
		TextTruncate         = Enum.TextTruncate.AtEnd,
		Text                 = "",
		Parent               = header,
	})

	-- Arrow icon (using makeIcon)
	local arrowImg = makeIcon(header, "chevron-down", 14, th.TextDim,
		UDim2.new(1, -16, 0.5, 0), Vector2.new(0.5, 0.5), 5)

	-- Floating list panel (parented to ScreenGui to avoid clip)
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
	Stroke(listFrame, th.Border, 1, 0.2)

	-- Search box (optional)
	local searchOffY = 0
	if opts.Searchable then
		searchOffY = 42
		local sbWrap = New("Frame", {
			Size             = UDim2.new(1, 0, 0, searchOffY),
			BackgroundTransparency = 1,
			ZIndex           = 53,
			Parent           = listFrame,
		})
		Pad(sbWrap, 6, 6, 6, 0)
		local sb = New("TextBox", {
			Size                 = UDim2.new(1, 0, 0, 30),
			BackgroundColor3     = th.Element,
			Font                 = Enum.Font.Gotham,
			TextSize             = 12,
			TextColor3           = th.Text,
			PlaceholderText      = "Search…",
			PlaceholderColor3    = th.TextDim,
			ClearTextOnFocus     = false,
			BorderSizePixel      = 0,
			ZIndex               = 54,
			Parent               = sbWrap,
		})
		Corner(sb, 7)
		Pad(sb, 10, 10, 0, 0)
		Stroke(sb, th.Border, 1, 0.4)
		makeIcon(sb, "search", 12, th.TextDim, UDim2.new(1, -24, 0.5, 0), Vector2.new(0.5, 0.5), 55)
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
		ScrollBarImageTransparency = 0.5,
		BackgroundTransparency = 1,
		BorderSizePixel      = 0,
		ZIndex               = 51,
		Parent               = listFrame,
	})
	local listLayout = VList(listScroll, 3)
	Pad(listScroll, 5, 5, 5, 5)
	AutoCanvas(listScroll, listLayout)

	local posConn
	local function positionList()
		if not header.Parent then return end
		local ap, as = header.AbsolutePosition, header.AbsoluteSize
		local itemH  = math.min(#(opts.Options or {}), 6) * 37 + searchOffY + 10
		listFrame.Size     = UDim2.new(0, as.X, 0, itemH)
		listFrame.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 4)
	end

	local function updateSelLabel()
		if #selected == 0 then
			selLbl.Text = "None"
		elseif #selected == 1 then
			selLbl.Text = selected[1]
		else
			selLbl.Text = #selected .. " selected"
		end
	end

	local function buildOptions()
		for _, c in ipairs(listScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, opt in ipairs(opts.Options or {}) do
			local isSel = table.find(selected, opt) ~= nil
			local row = New("TextButton", {
				Size             = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = isSel and th.Accent or th.Element,
				Font             = Enum.Font.Gotham,
				TextSize         = 13,
				TextColor3       = isSel and Color3.new(1,1,1) or th.Text,
				TextXAlignment   = Enum.TextXAlignment.Left,
				Text             = "  " .. opt,
				BorderSizePixel  = 0,
				ZIndex           = 52,
				Parent           = listScroll,
			})
			Corner(row, 7)
			if isSel then
				makeIcon(row, "check", 14, Color3.new(1,1,1),
					UDim2.new(1, -24, 0.5, 0), Vector2.new(0.5, 0.5), 53)
			end
			row.MouseButton1Click:Connect(function()
				if multi then
					local idx = table.find(selected, opt)
					if idx then table.remove(selected, idx)
					else table.insert(selected, opt) end
				else
					selected = {opt}
					isOpen   = false
					Tween(listFrame, {Size = UDim2.new(0, listFrame.Size.X.Offset, 0, 0)}, 0.18)
					task.delay(0.2, function() listFrame.Visible = false end)
					if posConn then posConn:Disconnect(); posConn = nil end
				end
				updateSelLabel()
				buildOptions()
				if opts.Flag then
					Simpliciton.Flags[opts.Flag] = selected
					win.Flags[opts.Flag]         = selected
				end
				if opts.Callback then pcall(opts.Callback, selected) end
			end)
			row.MouseEnter:Connect(function()
				if not isSel then Tween(row, {BackgroundColor3 = th.ElementHv}) end
			end)
			row.MouseLeave:Connect(function()
				Tween(row, {BackgroundColor3 = isSel and th.Accent or th.Element})
			end)
		end
	end
	updateSelLabel()
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
			posConn = RunService.Heartbeat:Connect(positionList)
		else
			Tween(listFrame, {Size = UDim2.new(0, listFrame.AbsoluteSize.X, 0, 0)}, 0.18)
			task.delay(0.2, function() listFrame.Visible = false end)
			if posConn then posConn:Disconnect(); posConn = nil end
		end
	end)
	header.MouseEnter:Connect(function() Tween(header, {BackgroundColor3 = th.ElementHv}) end)
	header.MouseLeave:Connect(function() Tween(header, {BackgroundColor3 = th.Element}) end)

	-- Outside-click dismissal
	local outsideConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not isOpen then return end
		local mp = UserInputService:GetMouseLocation()
		local lp, ls = listFrame.AbsolutePosition, listFrame.AbsoluteSize
		local hp, hs = header.AbsolutePosition, header.AbsoluteSize
		local inL = mp.X>=lp.X and mp.X<=lp.X+ls.X and mp.Y>=lp.Y and mp.Y<=lp.Y+ls.Y
		local inH = mp.X>=hp.X and mp.X<=hp.X+hs.X and mp.Y>=hp.Y and mp.Y<=hp.Y+hs.Y
		if not inL and not inH then
			isOpen = false
			Tween(listFrame, {Size = UDim2.new(0, listFrame.AbsoluteSize.X, 0, 0)}, 0.18)
			task.delay(0.2, function() listFrame.Visible = false end)
			if posConn then posConn:Disconnect(); posConn = nil end
		end
	end)
	table.insert(win._conns, outsideConn)

	return {
		Set = function(_, newOpt)
			selected = type(newOpt) == "string" and {newOpt} or newOpt
			updateSelLabel(); buildOptions()
			if opts.Flag then Simpliciton.Flags[opts.Flag] = selected; win.Flags[opts.Flag] = selected end
		end,
		GetSelected = function() return selected end,
		Refresh     = function(_, newOpts) opts.Options = newOpts; buildOptions() end,
		SetVisible  = function(_, v) header.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  KEYBIND
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateKeybind(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local currentKey = (opts.CurrentKeybind ~= "" and opts.CurrentKeybind) or "None"
	local listening  = false
	if opts.Flag then Simpliciton.Flags[opts.Flag] = currentKey; win.Flags[opts.Flag] = currentKey end

	local f = makeCard(page, th, 46)
	Pad(f, 16, 16, 0, 0)

	New("TextLabel", {
		Size                 = UDim2.new(1, -115, 1, 0),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Keybind",
		Parent               = f,
	})

	local keyBtn = New("TextButton", {
		Size             = UDim2.new(0, 96, 0, 30),
		Position         = UDim2.new(1, -96, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = th.BG,
		BackgroundTransparency = 0.3,
		Font             = Enum.Font.GothamBold,
		TextSize         = 11,
		TextColor3       = th.Accent,
		Text             = currentKey,
		BorderSizePixel  = 0,
		ZIndex           = 4,
		Parent           = f,
	})
	Corner(keyBtn, 8)
	local keyStroke = Stroke(keyBtn, th.Border, 1, 0.35)

	-- Keyboard icon (left side of key button)
	makeIcon(keyBtn, "keyboard", 12, th.TextDim,
		UDim2.new(0, 8, 0.5, 0), Vector2.new(0, 0.5), 5)

	local function setListening(v)
		listening = v
		if v then
			keyBtn.Text       = "…"
			keyBtn.TextColor3 = th.Warning
			keyStroke.Color   = th.Warning
			keyStroke.Transparency = 0
			Tween(keyBtn, {BackgroundTransparency = 0.1})
		else
			keyBtn.TextColor3 = th.Accent
			keyStroke.Color   = th.Border
			keyStroke.Transparency = 0.35
			Tween(keyBtn, {BackgroundTransparency = 0.3})
		end
	end

	keyBtn.MouseButton1Click:Connect(function()
		if listening then return end
		setListening(true)
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gp)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if gp then return end
			conn:Disconnect()
			local name = tostring(input.KeyCode):gsub("Enum%.KeyCode%.", "")
			currentKey    = (name == "Escape") and "None" or name
			keyBtn.Text   = currentKey
			setListening(false)
			if opts.Flag then Simpliciton.Flags[opts.Flag] = currentKey; win.Flags[opts.Flag] = currentKey end
			if opts.Callback then pcall(opts.Callback, currentKey) end
		end)
	end)

	keyBtn.MouseEnter:Connect(function()
		if not listening then Tween(keyBtn, {BackgroundTransparency = 0.15}) end
	end)
	keyBtn.MouseLeave:Connect(function()
		if not listening then Tween(keyBtn, {BackgroundTransparency = 0.3}) end
	end)
	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set = function(_, k)
			currentKey    = k or "None"
			keyBtn.Text   = currentKey
			if opts.Flag then Simpliciton.Flags[opts.Flag] = currentKey; win.Flags[opts.Flag] = currentKey end
		end,
		Get        = function() return currentKey end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  COLOR PICKER  (completely rewritten — real HSV, working hex+RGB inputs)
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateColorPicker(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local startColor = opts.Color or opts.CurrentValue or Color3.fromRGB(255, 80, 80)
	local hue, sat, val = Color3.toHSV(startColor)
	local alpha = math.clamp(opts.Alpha or 1, 0, 1)

	-- Collapsed header card
	local header = makeCard(page, th, 46)
	Pad(header, 16, 16, 0, 0)

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

	-- Color preview swatch (right side of header)
	local preview = New("Frame", {
		Size             = UDim2.new(0, 38, 0, 26),
		Position         = UDim2.new(1, -56, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = startColor,
		BorderSizePixel  = 0,
		Parent           = header,
	})
	Corner(preview, 7)
	Stroke(preview, th.Border, 1, 0.15)

	makeIcon(header, "chevron-down", 14, th.TextDim,
		UDim2.new(1, -16, 0.5, 0), Vector2.new(0.5, 0.5), 5)

	-- ── Picker panel ─────────────────────────────────────────────────────────
	local pW, pH = 330, 258
	local panel = New("Frame", {
		Size             = UDim2.new(0, pW, 0, pH),
		BackgroundColor3 = th.Surface,
		BorderSizePixel  = 0,
		Visible          = false,
		ZIndex           = 60,
		Parent           = win.ScreenGui,
	})
	Corner(panel, 12)
	Stroke(panel, th.Border, 1, 0.15)

	local MARGIN = 12

	-- ── SV (Saturation-Value) square ─────────────────────────────────────────
	-- The SV square works via 3 stacked layers:
	--   1. Hue base: solid hue-colored background
	--   2. White desaturation layer: white, transparent on right → opaque on left
	--   3. Black darkening layer: black, transparent on top → opaque on bottom

	local svW, svH = 190, 138
	local svBox = New("Frame", {
		Size             = UDim2.new(0, svW, 0, svH),
		Position         = UDim2.new(0, MARGIN, 0, MARGIN),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),  -- hue base
		BorderSizePixel  = 0,
		ClipsDescendants = true,
		ZIndex           = 61,
		Parent           = panel,
	})
	Corner(svBox, 8)

	-- Layer 2: White → transparent (L to R) — shows desaturation axis
	local svWhite = New("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 62,
		Parent           = svBox,
	})
	New("UIGradient", {
		Color        = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),   -- left = fully white
			NumberSequenceKeypoint.new(1, 1),   -- right = transparent
		}),
		Parent = svWhite,
	})

	-- Layer 3: Transparent → black (top to bottom) — shows value axis
	local svDark = New("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel  = 0,
		ZIndex           = 63,
		Parent           = svBox,
	})
	New("UIGradient", {
		Color        = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),   -- top = transparent
			NumberSequenceKeypoint.new(1, 0),   -- bottom = fully black
		}),
		Rotation = 90,  -- top-to-bottom
		Parent   = svDark,
	})

	-- SV knob (above the dark layer so it's always visible)
	local svKnob = New("Frame", {
		Size             = UDim2.new(0, 14, 0, 14),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(sat, 0, 1 - val, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 66,
		Parent           = svBox,
	})
	Corner(svKnob, 7)
	Stroke(svKnob, Color3.new(0, 0, 0), 2, 0)

	-- ── Hue bar ──────────────────────────────────────────────────────────────
	local hueBarY = MARGIN + svH + 10
	local hueBar = New("Frame", {
		Size             = UDim2.new(0, svW, 0, 12),
		Position         = UDim2.new(0, MARGIN, 0, hueBarY),
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		ZIndex           = 61,
		Parent           = panel,
	})
	Corner(hueBar, 6)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,      1, 1)),
			ColorSequenceKeypoint.new(0.167,Color3.fromHSV(0.167,  1, 1)),
			ColorSequenceKeypoint.new(0.333,Color3.fromHSV(0.333,  1, 1)),
			ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5,    1, 1)),
			ColorSequenceKeypoint.new(0.667,Color3.fromHSV(0.667,  1, 1)),
			ColorSequenceKeypoint.new(0.833,Color3.fromHSV(0.833,  1, 1)),
			ColorSequenceKeypoint.new(1,    Color3.fromHSV(0.9999, 1, 1)),
		}),
		Parent = hueBar,
	})
	local hueKnob = New("Frame", {
		Size             = UDim2.new(0, 10, 0, 18),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(hue, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 63,
		Parent           = hueBar,
	})
	Corner(hueKnob, 5)
	Stroke(hueKnob, Color3.new(0.15, 0.15, 0.15), 1.5, 0)

	-- ── Alpha bar ─────────────────────────────────────────────────────────────
	local alphaBarY = hueBarY + 22
	-- Checkerboard background (so transparent shows obviously)
	local alphaCheckBg = New("Frame", {
		Size             = UDim2.new(0, svW, 0, 12),
		Position         = UDim2.new(0, MARGIN, 0, alphaBarY),
		BackgroundColor3 = Color3.fromRGB(180, 180, 180),
		BorderSizePixel  = 0,
		ZIndex           = 60,
		Parent           = panel,
	})
	Corner(alphaCheckBg, 6)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromRGB(180, 180, 180)),
			ColorSequenceKeypoint.new(0.125,Color3.fromRGB(220, 220, 220)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(180, 180, 180)),
			ColorSequenceKeypoint.new(0.375,Color3.fromRGB(220, 220, 220)),
			ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(180, 180, 180)),
			ColorSequenceKeypoint.new(0.625,Color3.fromRGB(220, 220, 220)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(180, 180, 180)),
			ColorSequenceKeypoint.new(0.875,Color3.fromRGB(220, 220, 220)),
			ColorSequenceKeypoint.new(1,    Color3.fromRGB(180, 180, 180)),
		}),
		Parent = alphaCheckBg,
	})

	local alphaBar = New("Frame", {
		Size             = UDim2.new(0, svW, 0, 12),
		Position         = UDim2.new(0, MARGIN, 0, alphaBarY),
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		ZIndex           = 61,
		Parent           = panel,
	})
	Corner(alphaBar, 6)
	-- This gradient is rebuilt in rebuild() with the current color
	local alphaGrad = New("UIGradient", {
		Color = ColorSequence.new(
			Color3.fromHSV(hue, sat, val), Color3.fromHSV(hue, sat, val)
		),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),   -- left = fully transparent
			NumberSequenceKeypoint.new(1, 0),   -- right = fully opaque (current color)
		}),
		Parent = alphaBar,
	})
	local alphaKnob = New("Frame", {
		Size             = UDim2.new(0, 10, 0, 18),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.new(alpha, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel  = 0,
		ZIndex           = 63,
		Parent           = alphaBar,
	})
	Corner(alphaKnob, 5)
	Stroke(alphaKnob, Color3.new(0.15, 0.15, 0.15), 1.5, 0)

	-- ── Right column ─────────────────────────────────────────────────────────
	local rightX = MARGIN + svW + 10
	local rightW = pW - rightX - MARGIN  -- = 330 - 12 - 190 - 10 - 12 = 106

	-- Big color preview
	local bigPreview = New("Frame", {
		Size             = UDim2.new(0, rightW, 0, 58),
		Position         = UDim2.new(0, rightX, 0, MARGIN),
		BackgroundColor3 = startColor,
		BorderSizePixel  = 0,
		ZIndex           = 62,
		Parent           = panel,
	})
	Corner(bigPreview, 8)
	Stroke(bigPreview, th.Border, 1, 0.2)

	-- Hex input
	local hexBox = New("TextBox", {
		Size                 = UDim2.new(0, rightW, 0, 28),
		Position             = UDim2.new(0, rightX, 0, MARGIN + 64),
		BackgroundColor3     = th.Element,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 11,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Center,
		ClearTextOnFocus     = false,
		Text                 = "#" .. colorToHex(startColor),
		PlaceholderText      = "#RRGGBB",
		PlaceholderColor3    = th.TextDim,
		BorderSizePixel      = 0,
		ZIndex               = 62,
		Parent               = panel,
	})
	Corner(hexBox, 7)
	Stroke(hexBox, th.Border, 1, 0.35)

	-- R / G / B inputs  (each ~30px wide, 3 across rightW)
	local rgbW   = math.floor((rightW - 4) / 3)
	local rgbBoxes = {}
	local rgbNames = {"R", "G", "B"}
	for i = 1, 3 do
		local xo = rightX + (i-1) * (rgbW + 2)
		-- Label
		New("TextLabel", {
			Size                 = UDim2.new(0, rgbW, 0, 13),
			Position             = UDim2.new(0, xo, 0, MARGIN + 98),
			BackgroundTransparency = 1,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 9,
			TextColor3           = th.TextDim,
			Text                 = rgbNames[i],
			ZIndex               = 62,
			Parent               = panel,
		})
		-- Input box
		local curVal = (i == 1 and startColor.R) or (i == 2 and startColor.G) or startColor.B
		local rb = New("TextBox", {
			Size                 = UDim2.new(0, rgbW, 0, 26),
			Position             = UDim2.new(0, xo, 0, MARGIN + 113),
			BackgroundColor3     = th.Element,
			Font                 = Enum.Font.GothamBold,
			TextSize             = 11,
			TextColor3           = th.Text,
			TextXAlignment       = Enum.TextXAlignment.Center,
			ClearTextOnFocus     = true,
			Text                 = tostring(math.floor(curVal * 255)),
			BorderSizePixel      = 0,
			ZIndex               = 62,
			Parent               = panel,
		})
		Corner(rb, 6)
		Stroke(rb, th.Border, 1, 0.35)
		table.insert(rgbBoxes, rb)
	end

	-- Alpha percentage label
	local alphaLbl = New("TextLabel", {
		Size                 = UDim2.new(0, rightW, 0, 13),
		Position             = UDim2.new(0, rightX, 0, MARGIN + 145),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 9,
		TextColor3           = th.TextDim,
		Text                 = "A",
		ZIndex               = 62,
		Parent               = panel,
	})
	local alphaBox = New("TextBox", {
		Size                 = UDim2.new(0, rightW, 0, 26),
		Position             = UDim2.new(0, rightX, 0, MARGIN + 160),
		BackgroundColor3     = th.Element,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 11,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Center,
		ClearTextOnFocus     = true,
		Text                 = tostring(math.floor(alpha * 100)),
		BorderSizePixel      = 0,
		ZIndex               = 62,
		Parent               = panel,
	})
	Corner(alphaBox, 6)
	Stroke(alphaBox, th.Border, 1, 0.35)

	-- ── Rebuild function (updates all widgets from hue/sat/val/alpha) ─────────
	local function rebuild()
		local col = Color3.fromHSV(hue, sat, val)
		-- Visuals
		preview.BackgroundColor3    = col
		bigPreview.BackgroundColor3 = col
		svBox.BackgroundColor3      = Color3.fromHSV(hue, 1, 1)
		svKnob.Position             = UDim2.new(sat, 0, 1 - val, 0)
		hueKnob.Position            = UDim2.new(hue, 0, 0.5, 0)
		alphaKnob.Position          = UDim2.new(alpha, 0, 0.5, 0)
		-- Update alpha bar gradient to show current hue→transparent
		alphaGrad.Color = ColorSequence.new(col, col)
		-- Text fields
		hexBox.Text = "#" .. colorToHex(col)
		for i, rb in ipairs(rgbBoxes) do
			local ch = (i == 1 and col.R) or (i == 2 and col.G) or col.B
			rb.Text = tostring(math.floor(ch * 255))
		end
		alphaBox.Text = tostring(math.floor(alpha * 100))
		-- Knob border color matches current hue brightness
		local bright = (col.R * 0.299 + col.G * 0.587 + col.B * 0.114)
		local knobBorder = bright > 0.6 and Color3.new(0,0,0) or Color3.new(1,1,1)
		Stroke(svKnob, knobBorder, 2, 0)
		-- Flag + callback
		if opts.Flag then Simpliciton.Flags[opts.Flag] = col; win.Flags[opts.Flag] = col end
		if opts.Callback then pcall(opts.Callback, col, alpha) end
	end

	-- ── Panel positioning ─────────────────────────────────────────────────────
	local panelConn
	local function posPanel()
		if not header.Parent then return end
		local ap, as = header.AbsolutePosition, header.AbsoluteSize
		-- Prefer below; if not enough room below, show above
		local screenH = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 900
		local belowY  = ap.Y + as.Y + 4
		if belowY + pH > screenH then
			panel.Position = UDim2.fromOffset(ap.X, ap.Y - pH - 4)
		else
			panel.Position = UDim2.fromOffset(ap.X, belowY)
		end
	end

	-- ── SV drag (Heartbeat) ───────────────────────────────────────────────────
	local svDrag = false
	svBox.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
	end)
	local svEndC = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
	end)
	local svHBC = RunService.Heartbeat:Connect(function()
		if not svDrag then return end
		local ap, as = svBox.AbsolutePosition, svBox.AbsoluteSize
		local mp = UserInputService:GetMouseLocation()
		sat = math.clamp((mp.X - ap.X) / as.X, 0, 1)
		val = 1 - math.clamp((mp.Y - ap.Y) / as.Y, 0, 1)
		rebuild()
	end)
	table.insert(win._conns, svEndC)
	table.insert(win._conns, svHBC)

	-- ── Hue drag ──────────────────────────────────────────────────────────────
	local hueDrag = false
	hueBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
	end)
	local hueEndC = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
	end)
	local hueHBC = RunService.Heartbeat:Connect(function()
		if not hueDrag then return end
		local ap, as = hueBar.AbsolutePosition, hueBar.AbsoluteSize
		hue = math.clamp((UserInputService:GetMouseLocation().X - ap.X) / as.X, 0, 0.9999)
		rebuild()
	end)
	table.insert(win._conns, hueEndC)
	table.insert(win._conns, hueHBC)

	-- ── Alpha drag ────────────────────────────────────────────────────────────
	local alphaDrag = false
	alphaBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then alphaDrag = true end
	end)
	local alphaEndC = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then alphaDrag = false end
	end)
	local alphaHBC = RunService.Heartbeat:Connect(function()
		if not alphaDrag then return end
		local ap, as = alphaBar.AbsolutePosition, alphaBar.AbsoluteSize
		alpha = math.clamp((UserInputService:GetMouseLocation().X - ap.X) / as.X, 0, 1)
		rebuild()
	end)
	table.insert(win._conns, alphaEndC)
	table.insert(win._conns, alphaHBC)

	-- ── Hex input ─────────────────────────────────────────────────────────────
	hexBox.FocusLost:Connect(function()
		local text = hexBox.Text:gsub("[^%x]", ""):upper()
		if #text == 6 then
			local col = Color3.fromRGB(
				tonumber(text:sub(1,2), 16),
				tonumber(text:sub(3,4), 16),
				tonumber(text:sub(5,6), 16)
			)
			hue, sat, val = Color3.toHSV(col)
			rebuild()
		else
			-- Revert to current
			hexBox.Text = "#" .. colorToHex(Color3.fromHSV(hue, sat, val))
		end
	end)

	-- ── RGB inputs ────────────────────────────────────────────────────────────
	for _, rb in ipairs(rgbBoxes) do
		rb.FocusLost:Connect(function()
			local nums = {}
			for _, b in ipairs(rgbBoxes) do
				nums[#nums+1] = math.clamp(tonumber(b.Text) or 0, 0, 255)
			end
			local col = Color3.fromRGB(nums[1], nums[2], nums[3])
			hue, sat, val = Color3.toHSV(col)
			rebuild()
		end)
	end

	-- ── Alpha box input ───────────────────────────────────────────────────────
	alphaBox.FocusLost:Connect(function()
		local pct = tonumber(alphaBox.Text)
		if pct then
			alpha = math.clamp(pct / 100, 0, 1)
			rebuild()
		else
			alphaBox.Text = tostring(math.floor(alpha * 100))
		end
	end)

	-- ── Open/close toggle ─────────────────────────────────────────────────────
	local isOpen  = false
	local interact = New("TextButton", {
		Size                 = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "",
		ZIndex = 5, Parent = header,
	})
	interact.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		panel.Visible = isOpen
		if isOpen then
			posPanel()
			panelConn = RunService.Heartbeat:Connect(posPanel)
		else
			if panelConn then panelConn:Disconnect(); panelConn = nil end
		end
	end)
	header.MouseEnter:Connect(function() Tween(header, {BackgroundColor3 = th.ElementHv}) end)
	header.MouseLeave:Connect(function() Tween(header, {BackgroundColor3 = th.Element}) end)

	rebuild()

	return {
		Set      = function(_, col)
			hue, sat, val = Color3.toHSV(col); rebuild()
		end,
		SetAlpha = function(_, a) alpha = math.clamp(a, 0, 1); rebuild() end,
		Get      = function() return Color3.fromHSV(hue, sat, val) end,
		GetAlpha = function() return alpha end,
		SetVisible = function(_, v) header.Visible = v end,
	}
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  PROGRESS BAR
-- ═══════════════════════════════════════════════════════════════════════════════
function Simpliciton:CreateProgressBar(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th   = getTheme(self)

	local maxVal   = opts.Max    or 100
	local curVal   = math.clamp(opts.Value or 0, 0, maxVal)
	local suffix   = opts.Suffix or "%"
	local barColor = opts.Color  or th.Accent

	local f = makeCard(page, th, 58)
	Pad(f, 16, 16, 0, 0)

	-- Name label (left) + value label (right), same row
	New("TextLabel", {
		Size                 = UDim2.new(1, -80, 0, 22),
		Position             = UDim2.new(0, 0, 0, 10),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamMedium,
		TextSize             = 13,
		TextColor3           = th.Text,
		TextXAlignment       = Enum.TextXAlignment.Left,
		Text                 = opts.Name or "Progress",
		Parent               = f,
	})

	local pctLbl = New("TextLabel", {
		Size                 = UDim2.new(0, 72, 0, 22),
		Position             = UDim2.new(1, -72, 0, 10),
		BackgroundTransparency = 1,
		Font                 = Enum.Font.GothamBold,
		TextSize             = 12,
		TextColor3           = barColor,
		TextXAlignment       = Enum.TextXAlignment.Right,
		Text                 = "0" .. suffix,
		Parent               = f,
	})

	-- Track
	local track = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 8),
		Position         = UDim2.new(0, 0, 1, -18),
		AnchorPoint      = Vector2.new(0, 1),
		BackgroundColor3 = th.Border,
		BackgroundTransparency = 0.2,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
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
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   barColor),
			ColorSequenceKeypoint.new(0.5, brighten(barColor, 25)),
			ColorSequenceKeypoint.new(1,   barColor),
		}),
		Parent = fill,
	})

	local function updatePB(v)
		v       = math.clamp(v, 0, maxVal)
		curVal  = v
		local pct = (maxVal == 0) and 0 or (v / maxVal)
		Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.4, Enum.EasingStyle.Quint)
		local display = maxVal == 100
			and tostring(math.floor(pct * 100)) .. suffix
			or  string.format("%.0f / %.0f", v, maxVal)
		pctLbl.Text = display
	end
	updatePB(curVal)

	return {
		Set        = function(_, v) updatePB(v) end,
		Get        = function() return curVal end,
		SetMax     = function(_, m) maxVal = m; updatePB(curVal) end,
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
			Image    = "save",
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
	-- Merge (preserving keys not in file)
	for k, v in pairs(data) do
		self.Flags[k]      = v
		Simpliciton.Flags[k] = v
	end
	self:Notify({
		Title    = "Config Loaded",
		Content  = "Settings restored from " .. self._cfgFile,
		Duration = 2.5,
		Image    = "folder-open",
		Type     = "success",
	})
end

-- Aliases
Simpliciton.SaveConfig = Simpliciton.SaveConfiguration
Simpliciton.LoadConfig = Simpliciton.LoadConfiguration

return Simpliciton
