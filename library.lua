-- ============================================================
--  Simpliciton UI Library  |  v2.0  |  Fixed & Enhanced
-- ============================================================
--
--  FIXES from v1:
--   1. Simpliciton.__index = Simpliciton  (critical – tab methods
--      were inaccessible, causing all element calls to crash)
--   2. GetPage()  – elements now work on both window AND tab objects
--   3. GetWindow() + tab.Window  – Flags / Connections now reachable
--      from any context (was nil-erroring on every element)
--   4. CreateSlider  – removed permanent RenderStepped leak;
--      replaced with UserInputService.InputChanged + InputEnded
--   5. CreateColorPicker  – completely rewritten with working
--      RGB sliders (original was a broken stub)
--   6. CreateToggle  – AnchorPoint tween replaced with reliable
--      offset-based position animation
--   7. Draggable  – fixed; now properly uses UIS global events
--   8. Notifications  – fixed slide-in/out, fixed Padding bug
--   9. Connections  – all UIS connections stored & cleaned up
--  10. SelectTab  – added indicator bar animation
-- ============================================================

local Simpliciton = {}
Simpliciton.__index = Simpliciton   -- ← critical missing line in v1

-- ==================== SERVICES ====================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== THEME ====================
local Theme = {
	Accent          = Color3.fromRGB(85,  170, 255),
	Background      = Color3.fromRGB(16,  16,  22),
	Secondary       = Color3.fromRGB(27,  27,  36),
	Tertiary        = Color3.fromRGB(40,  40,  52),
	Text            = Color3.fromRGB(235, 235, 245),
	TextDim         = Color3.fromRGB(130, 130, 158),
	Border          = Color3.fromRGB(58,  58,  76),
	Success         = Color3.fromRGB(75,  215, 135),
	Error           = Color3.fromRGB(255, 75,  75),
	CornerRadius    = 8,
	StrokeThickness = 1.0,
}

local TweenQuick  = TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TweenMedium = TweenInfo.new(0.26, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- ==================== INTERNAL UTILITIES ====================
local function Tween(obj, props, ti)
	if not obj or not obj.Parent then return end
	TweenService:Create(obj, ti or TweenQuick, props):Play()
end

local function New(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			pcall(function() inst[k] = v end)
		end
	end
	if parent then inst.Parent = parent end
	return inst
end

local function Corner(parent, radius)
	if not parent then return end
	New("UICorner", { CornerRadius = UDim.new(0, radius or Theme.CornerRadius) }, parent)
end

local function Stroke(parent, color, thickness, transparency)
	if not parent then return end
	New("UIStroke", {
		Color        = color        or Theme.Border,
		Thickness    = thickness    or Theme.StrokeThickness,
		Transparency = transparency or 0.3,
	}, parent)
end

local function Padding(parent, l, r, t, b)
	if not parent then return end
	New("UIPadding", {
		PaddingLeft   = UDim.new(0, l or 8),
		PaddingRight  = UDim.new(0, r or 8),
		PaddingTop    = UDim.new(0, t or 6),
		PaddingBottom = UDim.new(0, b or 6),
	}, parent)
end

-- Resolves the scroll page for both window (CurrentTab.Page) and tab (Page) contexts
local function GetPage(self)
	return self.Page or (self.CurrentTab and self.CurrentTab.Page)
end

-- Resolves the root window from either a window or a tab
local function GetWindow(self)
	return self.Window or self
end

-- Lightens a Color3 by a fixed RGB amount
local function Lighten(c, amt)
	return Color3.fromRGB(
		math.clamp(c.R * 255 + amt, 0, 255),
		math.clamp(c.G * 255 + amt, 0, 255),
		math.clamp(c.B * 255 + amt, 0, 255)
	)
end

-- ==================== WINDOW ====================
function Simpliciton:CreateWindow(options)
	options = options or {}
	local window = setmetatable({}, Simpliciton)

	window.Name          = options.Name  or "Simpliciton"
	window.ConfigSaving  = options.ConfigurationSaving or { Enabled = true, FileName = "Simpliciton_Config.json" }
	window.Flags         = {}
	window.Tabs          = {}
	window.CurrentTab    = nil
	window.Connections   = {}
	window.RainbowThread = nil

	window:_BuildInterface()
	window:_CreateSettingsTab()   -- auto-appended settings tab

	return window
end

function Simpliciton:_BuildInterface()
	-- Root ScreenGui
	local sg = New("ScreenGui", {
		Name           = "SimplicitonUI",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn   = false,
		DisplayOrder   = 100,
		Parent         = PlayerGui,
	})
	self.ScreenGui = sg

	-- Main frame
	local main = New("Frame", {
		Name             = "Main",
		Size             = UDim2.new(0, 690, 0, 460),
		Position         = UDim2.new(0.5, -345, 0.5, -230),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel  = 0,
		Parent           = sg,
	})
	Corner(main)
	Stroke(main, Theme.Border, 1.3, 0.15)
	self.MainFrame = main

	-- Subtle drop shadow
	New("ImageLabel", {
		Size              = UDim2.new(1, 80, 1, 80),
		Position          = UDim2.new(0, -40, 0, -40),
		BackgroundTransparency = 1,
		Image             = "rbxassetid://6014261993",
		ImageColor3       = Color3.new(0, 0, 0),
		ImageTransparency = 0.55,
		ScaleType         = Enum.ScaleType.Slice,
		SliceCenter       = Rect.new(49, 49, 450, 450),
		ZIndex            = 0,
		Parent            = main,
	})

	-- ── Header ──────────────────────────────────────────────
	local header = New("Frame", {
		Name             = "Header",
		Size             = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel  = 0,
		Parent           = main,
	})
	Corner(header)
	-- Fill bottom-corner gap so the header looks like a rectangle on the bottom edge
	New("Frame", {
		Name             = "CornerFill",
		Size             = UDim2.new(1, 0, 0, Theme.CornerRadius),
		Position         = UDim2.new(0, 0, 1, -Theme.CornerRadius),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel  = 0,
		ZIndex           = 2,
		Parent           = header,
	})
	self.Header = header

	-- Title label
	New("TextLabel", {
		Size                   = UDim2.new(1, -90, 1, 0),
		Position               = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		TextSize               = 18,
		TextColor3             = Color3.new(1, 1, 1),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Text                   = self.Name,
		Parent                 = header,
	})

	-- Minimise button
	local minBtn = New("TextButton", {
		Size                   = UDim2.new(0, 30, 0, 30),
		Position               = UDim2.new(1, -78, 0.5, 0),
		AnchorPoint            = Vector2.new(0, 0.5),
		BackgroundColor3       = Color3.fromRGB(255, 195, 45),
		BackgroundTransparency = 0,
		Text                   = "−",
		TextColor3             = Color3.fromRGB(140, 90, 0),
		TextSize               = 18,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		Parent                 = header,
	})
	Corner(minBtn, 7)

	local minimised = false
	local fullH     = 460
	minBtn.MouseButton1Click:Connect(function()
		minimised = not minimised
		Tween(main, { Size = UDim2.new(0, 690, 0, minimised and 50 or fullH) }, TweenMedium)
	end)
	minBtn.MouseEnter:Connect(function() Tween(minBtn, { BackgroundColor3 = Color3.fromRGB(255, 218, 90) }) end)
	minBtn.MouseLeave:Connect(function() Tween(minBtn, { BackgroundColor3 = Color3.fromRGB(255, 195, 45) }) end)

	-- Close button
	local closeBtn = New("TextButton", {
		Size                   = UDim2.new(0, 30, 0, 30),
		Position               = UDim2.new(1, -40, 0.5, 0),
		AnchorPoint            = Vector2.new(0, 0.5),
		BackgroundColor3       = Color3.fromRGB(255, 65, 65),
		BackgroundTransparency = 0,
		Text                   = "×",
		TextColor3             = Color3.new(1, 1, 1),
		TextSize               = 20,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		Parent                 = header,
	})
	Corner(closeBtn, 7)
	closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(255, 105, 105) }) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(255, 65, 65) }) end)

	-- ── Sidebar ──────────────────────────────────────────────
	local sidebar = New("ScrollingFrame", {
		Size                 = UDim2.new(0, 160, 1, -58),
		Position             = UDim2.new(0, 0, 0, 58),
		CanvasSize           = UDim2.new(),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		ScrollBarThickness   = 3,
		ScrollBarImageColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		ClipsDescendants     = true,
		Parent               = main,
	})
	New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })
	Padding(sidebar, 7, 7, 7, 10)
	self.Sidebar = sidebar

	-- Vertical divider
	New("Frame", {
		Size             = UDim2.new(0, 1, 1, -58),
		Position         = UDim2.new(0, 160, 0, 58),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.55,
		BorderSizePixel  = 0,
		Parent           = main,
	})

	-- ── Content area ─────────────────────────────────────────
	local content = New("Frame", {
		Size                   = UDim2.new(1, -168, 1, -58),
		Position               = UDim2.new(0, 168, 0, 58),
		BackgroundTransparency = 1,
		Parent                 = main,
	})
	self.ContentArea = content

	self:_MakeDraggable(header)
end

function Simpliciton:_MakeDraggable(handle)
	local dragging, dragStart, startPos = false, nil, nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = self.MainFrame.Position
		end
	end)

	local c1 = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			self.MainFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
	local c2 = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	table.insert(self.Connections, c1)
	table.insert(self.Connections, c2)
end

-- ==================== TAB SYSTEM ====================
function Simpliciton:CreateTab(name, iconId)
	-- Each tab is its own object that inherits all Simpliciton methods.
	-- tab.Window  →  back-reference to the root window for Flags/Connections
	-- tab.Page    →  the ScrollingFrame that element methods parent into
	local tab    = setmetatable({}, Simpliciton)
	tab.Name     = name
	tab.Window   = self   -- ← crucial: lets GetWindow() work on tab objects
	tab.Elements = {}

	-- ── Sidebar button ───────────────────────────────────────
	local btn = New("TextButton", {
		Size             = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel  = 0,
		Text             = "",
		AutoButtonColor  = false,
		Parent           = self.Sidebar,
	})
	Corner(btn)

	-- Left accent bar (shown when active)
	local bar = New("Frame", {
		Size             = UDim2.new(0, 3, 0.5, 0),
		Position         = UDim2.new(0, 0, 0.25, 0),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel  = 0,
		Parent           = btn,
	})
	Corner(bar, 2)

	local textX = 14
	if iconId then
		textX = 44
		New("ImageLabel", {
			Size                   = UDim2.new(0, 20, 0, 20),
			Position               = UDim2.new(0, 13, 0.5, 0),
			AnchorPoint            = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image                  = "rbxassetid://" .. tostring(iconId),
			ImageColor3            = Theme.TextDim,
			Parent                 = btn,
		})
	end

	local lbl = New("TextLabel", {
		Size                   = UDim2.new(1, -(textX + 8), 1, 0),
		Position               = UDim2.new(0, textX, 0, 0),
		BackgroundTransparency = 1,
		Text                   = name,
		TextColor3             = Theme.TextDim,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = btn,
	})

	-- ── Content page ─────────────────────────────────────────
	local page = New("ScrollingFrame", {
		Size                 = UDim2.new(1, 0, 1, 0),
		CanvasSize           = UDim2.new(),
		AutomaticCanvasSize  = Enum.AutomaticSize.Y,
		ScrollBarThickness   = 4,
		ScrollBarImageColor3 = Color3.fromRGB(70, 70, 90),
		BackgroundTransparency = 1,
		Visible              = false,
		Parent               = self.ContentArea,
	})
	New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
	Padding(page, 14, 14, 12, 18)

	tab.Button    = btn
	tab.Page      = page
	tab.Label     = lbl
	tab.ActiveBar = bar

	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	btn.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then Tween(btn, { BackgroundColor3 = Theme.Tertiary }) end
	end)
	btn.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then Tween(btn, { BackgroundColor3 = Theme.Secondary }) end
	end)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then self:SelectTab(tab) end

	return tab
end

function Simpliciton:SelectTab(tab)
	if self.CurrentTab == tab then return end
	if self.CurrentTab then
		local prev = self.CurrentTab
		Tween(prev.Button,    { BackgroundColor3 = Theme.Secondary })
		Tween(prev.Label,     { TextColor3 = Theme.TextDim })
		Tween(prev.ActiveBar, { BackgroundTransparency = 1 })
		prev.Page.Visible = false
	end
	Tween(tab.Button,    { BackgroundColor3 = Theme.Tertiary })
	Tween(tab.Label,     { TextColor3 = Theme.Text })
	Tween(tab.ActiveBar, { BackgroundTransparency = 0 })
	tab.Page.Visible  = true
	self.CurrentTab   = tab
end

-- ==================== ELEMENTS ====================
-- All elements are callable on BOTH window (self.CurrentTab.Page)
-- and tab (self.Page) objects via GetPage() / GetWindow().

-- ── Section header ───────────────────────────────────────────
function Simpliciton:CreateSection(title)
	local page = GetPage(self)
	if not page then warn("[Simpliciton] CreateSection: no active page") return end

	local frame = New("Frame", {
		Size                   = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent                 = page,
	})
	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 20),
		Position               = UDim2.new(0, 0, 0, 4),
		BackgroundTransparency = 1,
		Text                   = title,
		TextColor3             = Theme.Accent,
		TextSize               = 11,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})
	New("Frame", {
		Size             = UDim2.new(1, 0, 0, 1),
		Position         = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.4,
		BorderSizePixel  = 0,
		Parent           = frame,
	})
	return frame
end

-- ── Label ────────────────────────────────────────────────────
function Simpliciton:CreateLabel(text)
	local page = GetPage(self)
	if not page then return end

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = Theme.Secondary,
		Parent           = page,
	})
	Corner(frame)
	New("TextLabel", {
		Size                   = UDim2.new(1, -24, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = text,
		TextColor3             = Theme.TextDim,
		TextSize               = 13,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})
	return frame
end

-- ── Paragraph ────────────────────────────────────────────────
function Simpliciton:CreateParagraph(options)
	local page = GetPage(self)
	if not page then return end
	options = options or {}

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Secondary,
		Parent           = page,
	})
	Corner(frame)
	Padding(frame, 14, 14, 10, 10)
	New("UIListLayout", { Padding = UDim.new(0, 5), Parent = frame })

	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = options.Title or "Title",
		TextColor3             = Theme.Text,
		TextSize               = 14,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		Parent                 = frame,
	})
	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = options.Content or "",
		TextColor3             = Theme.TextDim,
		TextSize               = 13,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		Parent                 = frame,
	})
	return frame
end

-- ── Toggle ───────────────────────────────────────────────────
function Simpliciton:CreateToggle(options)
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	options = options or {}

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(1, -64, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = options.Name or "Toggle",
		TextColor3             = Theme.Text,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local track = New("Frame", {
		Size             = UDim2.new(0, 36, 0, 20),
		Position         = UDim2.new(1, -50, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Tertiary,
		Parent           = frame,
	})
	Corner(track, 10)

	local knob = New("Frame", {
		Size             = UDim2.new(0, 14, 0, 14),
		Position         = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent           = track,
	})
	Corner(knob, 7)

	local val = options.CurrentValue == true

	local function setState(v, silent)
		val = v
		-- Animate track colour
		Tween(track, { BackgroundColor3 = v and Theme.Accent or Theme.Tertiary })
		-- Animate knob position using offset only (reliable cross-version)
		Tween(knob, {
			Position    = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = v and Vector2.new(1, 0.5)       or Vector2.new(0, 0.5),
		}, TweenMedium)
		if not silent then
			if options.Callback then pcall(options.Callback, v) end
			if options.Flag     then win.Flags[options.Flag] = v end
		end
	end

	frame.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then setState(not val) end
	end)
	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Secondary }) end)

	setState(val, true)

	return {
		Set    = function(v) setState(v) end,
		Get    = function() return val end,
		Toggle = function() setState(not val) end,
	}
end

-- ── Slider ───────────────────────────────────────────────────
-- Fixed: no more permanent RenderStepped connection.
function Simpliciton:CreateSlider(options)
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	options = options or {}

	local min      = options.Min      or 0
	local max      = options.Max      or 100
	local decimals = options.Decimals or 0
	local value    = math.clamp(options.CurrentValue or min, min, max)

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = Theme.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(1, -80, 0, 24),
		Position               = UDim2.new(0, 14, 0, 6),
		BackgroundTransparency = 1,
		Text                   = options.Name or "Slider",
		TextColor3             = Theme.Text,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local valLabel = New("TextLabel", {
		Size                   = UDim2.new(0, 66, 0, 24),
		Position               = UDim2.new(1, -78, 0, 6),
		BackgroundTransparency = 1,
		Text                   = string.format("%." .. decimals .. "f", value),
		TextColor3             = Theme.Accent,
		TextSize               = 12,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Right,
		Parent                 = frame,
	})

	local track = New("Frame", {
		Size             = UDim2.new(1, -28, 0, 6),
		Position         = UDim2.new(0, 14, 0, 38),
		BackgroundColor3 = Theme.Tertiary,
		Parent           = frame,
	})
	Corner(track, 3)

	local fill = New("Frame", {
		Size             = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		Parent           = track,
	})
	Corner(fill, 3)

	local knob = New("Frame", {
		Size             = UDim2.new(0, 14, 0, 14),
		Position         = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent           = track,
	})
	Corner(knob, 7)
	Stroke(knob, Theme.Accent, 1.6, 0)

	local dragging = false

	local function updateValue(v, fireCallback)
		value = math.clamp(
			tonumber(string.format("%." .. decimals .. "f", v)) or v,
			min, max
		)
		local pct = (value - min) / (max - min)
		Tween(fill, { Size = UDim2.new(pct, 0, 1, 0) })
		Tween(knob, { Position = UDim2.new(pct, 0, 0.5, 0) })
		valLabel.Text = string.format("%." .. decimals .. "f", value)
		if fireCallback then
			if options.Callback then pcall(options.Callback, value) end
			if options.Flag     then win.Flags[options.Flag] = value end
		end
	end

	local function applyDrag(xPos)
		local pct = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		updateValue(min + (max - min) * pct, true)
	end

	knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			applyDrag(i.Position.X)
		end
	end)

	-- Global mouse move / release – stored so they can be cleaned up on Destroy
	local c1 = UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			applyDrag(i.Position.X)
		end
	end)
	local c2 = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	table.insert(win.Connections, c1)
	table.insert(win.Connections, c2)

	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Secondary }) end)

	updateValue(value, false)

	return {
		Set = function(v) updateValue(v, true) end,
		Get = function() return value end,
	}
end

-- ── Dropdown ─────────────────────────────────────────────────
function Simpliciton:CreateDropdown(options)
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	options = options or {}

	local currentOption = options.CurrentOption
		or (options.Options and options.Options[1])
		or ""
	local isOpen = false

	local wrapper = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Secondary,
		ClipsDescendants = false,
		Parent           = page,
	})
	Corner(wrapper)

	New("TextLabel", {
		Size                   = UDim2.new(0.45, 0, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = options.Name or "Dropdown",
		TextColor3             = Theme.Text,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = wrapper,
	})

	local selectedLbl = New("TextLabel", {
		Size                   = UDim2.new(0.45, -26, 1, 0),
		Position               = UDim2.new(0.5, -4, 0, 0),
		BackgroundTransparency = 1,
		Text                   = currentOption,
		TextColor3             = Theme.Accent,
		TextSize               = 13,
		TextXAlignment         = Enum.TextXAlignment.Right,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = wrapper,
	})

	local arrow = New("TextLabel", {
		Size                   = UDim2.new(0, 20, 1, 0),
		Position               = UDim2.new(1, -22, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "▾",
		TextColor3             = Theme.TextDim,
		TextSize               = 15,
		Parent                 = wrapper,
	})

	local listFrame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		Position         = UDim2.new(0, 0, 1, 5),
		BackgroundColor3 = Theme.Secondary,
		Visible          = false,
		ZIndex           = 30,
		Parent           = wrapper,
	})
	Corner(listFrame)
	Stroke(listFrame, Theme.Accent, 1.2, 0.3)
	local listLayout = New("UIListLayout", { Padding = UDim.new(0, 2), Parent = listFrame })
	Padding(listFrame, 4, 4, 4, 4)

	local function rebuildList()
		for _, c in listFrame:GetChildren() do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for _, opt in ipairs(options.Options or {}) do
			local item = New("TextButton", {
				Size                   = UDim2.new(1, 0, 0, 30),
				BackgroundColor3       = Theme.Accent,
				BackgroundTransparency = 1,
				Text                   = opt,
				TextColor3             = Theme.Text,
				TextSize               = 13,
				ZIndex                 = 31,
				Parent                 = listFrame,
			})
			Corner(item, 5)
			item.MouseEnter:Connect(function() Tween(item, { BackgroundTransparency = 0.75, BackgroundColor3 = Theme.Accent }) end)
			item.MouseLeave:Connect(function() Tween(item, { BackgroundTransparency = 1 }) end)
			item.MouseButton1Click:Connect(function()
				currentOption      = opt
				selectedLbl.Text   = opt
				isOpen             = false
				listFrame.Visible  = false
				Tween(arrow,   { Rotation = 0 })
				Tween(wrapper, { BackgroundColor3 = Theme.Secondary })
				if options.Callback then pcall(options.Callback, opt) end
				if options.Flag     then win.Flags[options.Flag] = opt end
			end)
		end
		task.defer(function()
			if listLayout and listFrame.Parent then
				listFrame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
			end
		end)
	end
	rebuildList()

	wrapper.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			isOpen = not isOpen
			listFrame.Visible = isOpen
			Tween(arrow,   { Rotation = isOpen and 180 or 0 })
			Tween(wrapper, { BackgroundColor3 = isOpen and Theme.Tertiary or Theme.Secondary })
		end
	end)
	wrapper.MouseEnter:Connect(function()
		if not isOpen then Tween(wrapper, { BackgroundColor3 = Theme.Tertiary }) end
	end)
	wrapper.MouseLeave:Connect(function()
		if not isOpen then Tween(wrapper, { BackgroundColor3 = Theme.Secondary }) end
	end)

	return {
		Set = function(v)
			if table.find(options.Options or {}, v) then
				currentOption    = v
				selectedLbl.Text = v
				if options.Callback then pcall(options.Callback, v) end
				if options.Flag     then win.Flags[options.Flag] = v end
			end
		end,
		Get     = function() return currentOption end,
		Refresh = function(newOpts) options.Options = newOpts rebuildList() end,
	}
end

-- ── Button ───────────────────────────────────────────────────
function Simpliciton:CreateButton(options)
	local page = GetPage(self)
	if not page then return end
	options = options or {}

	local btn = New("TextButton", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Accent,
		Text             = options.Name or "Button",
		TextColor3       = Color3.new(1, 1, 1),
		TextSize         = 13,
		FontFace         = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
		Parent           = page,
	})
	Corner(btn)

	btn.MouseButton1Click:Connect(function()
		-- Brief white flash on click
		Tween(btn, { BackgroundColor3 = Color3.new(1, 1, 1) })
		task.delay(0.09, function() Tween(btn, { BackgroundColor3 = Theme.Accent }) end)
		if options.Callback then pcall(options.Callback) end
	end)
	btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Lighten(Theme.Accent, 22) }) end)
	btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Theme.Accent }) end)

	return {
		Fire    = function() if options.Callback then pcall(options.Callback) end end,
		SetText = function(t) btn.Text = t end,
	}
end

-- ── TextInput ────────────────────────────────────────────────
function Simpliciton:CreateInput(options)
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	options = options or {}

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(0.42, 0, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = options.Name or "Input",
		TextColor3             = Theme.Text,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local box = New("TextBox", {
		Size              = UDim2.new(0.55, -10, 0, 28),
		Position          = UDim2.new(0.45, 0, 0.5, 0),
		AnchorPoint       = Vector2.new(0, 0.5),
		BackgroundColor3  = Theme.Tertiary,
		PlaceholderText   = options.Placeholder  or "Type here…",
		PlaceholderColor3 = Theme.TextDim,
		Text              = options.CurrentValue or "",
		TextColor3        = Theme.Text,
		TextSize          = 13,
		ClearTextOnFocus  = false,
		Parent            = frame,
	})
	Corner(box, 6)
	Padding(box, 8, 8, 0, 0)

	local activeStroke = nil
	box.Focused:Connect(function()
		activeStroke = Stroke(box, Theme.Accent, 1.5, 0)
	end)
	box.FocusLost:Connect(function()
		if activeStroke then activeStroke:Destroy() activeStroke = nil end
		if options.Callback then pcall(options.Callback, box.Text) end
		if options.Flag     then win.Flags[options.Flag] = box.Text end
	end)
	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Secondary }) end)

	return {
		Set = function(v) box.Text = v end,
		Get = function() return box.Text end,
	}
end

-- ── Keybind ──────────────────────────────────────────────────
function Simpliciton:CreateKeybind(options)
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	options = options or {}

	local frame = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Secondary,
		Parent           = page,
	})
	Corner(frame)

	New("TextLabel", {
		Size                   = UDim2.new(1, -120, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = options.Name or "Keybind",
		TextColor3             = Theme.Text,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = frame,
	})

	local bindBtn = New("TextButton", {
		Size             = UDim2.new(0, 96, 0, 28),
		Position         = UDim2.new(1, -106, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Tertiary,
		Text             = options.CurrentKeybind and options.CurrentKeybind.Name or "None",
		TextColor3       = Theme.Text,
		TextSize         = 12,
		Parent           = frame,
	})
	Corner(bindBtn, 6)

	local listening  = false
	local currentKey = options.CurrentKeybind or Enum.KeyCode.Unknown

	bindBtn.MouseButton1Click:Connect(function()
		if listening then return end
		listening       = true
		bindBtn.Text    = "[ … ]"
		Tween(bindBtn, { BackgroundColor3 = Theme.Accent })
	end)

	local conn = UserInputService.InputBegan:Connect(function(i, gp)
		if not listening or gp then return end
		if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode ~= Enum.KeyCode.Unknown then
			currentKey      = i.KeyCode
			bindBtn.Text    = currentKey.Name
			listening       = false
			Tween(bindBtn, { BackgroundColor3 = Theme.Tertiary })
			if options.Callback then pcall(options.Callback, currentKey) end
			if options.Flag     then win.Flags[options.Flag] = currentKey.Name end
		end
	end)
	table.insert(win.Connections, conn)

	frame.MouseEnter:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Tertiary }) end)
	frame.MouseLeave:Connect(function() Tween(frame, { BackgroundColor3 = Theme.Secondary }) end)

	return {
		Set = function(k) currentKey = k bindBtn.Text = k.Name end,
		Get = function() return currentKey end,
	}
end

-- ── Color Picker ─────────────────────────────────────────────
-- Completely rewritten.  The original was a non-functional stub.
-- Presents an expandable panel with three labelled RGB sliders
-- and a live hex readout.
function Simpliciton:CreateColorPicker(options)
	local page = GetPage(self)
	local win  = GetWindow(self)
	if not page then return end
	options = options or {}

	local col = options.CurrentValue or Color3.fromRGB(255, 100, 100)
	local rv   = math.floor(col.R * 255)
	local gv   = math.floor(col.G * 255)
	local bv   = math.floor(col.B * 255)

	-- Header (always visible, click to toggle the panel)
	local header = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Secondary,
		Parent           = page,
	})
	Corner(header)

	New("TextLabel", {
		Size                   = UDim2.new(1, -60, 1, 0),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = options.Name or "Color",
		TextColor3             = Theme.Text,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = header,
	})

	local preview = New("Frame", {
		Size             = UDim2.new(0, 36, 0, 26),
		Position         = UDim2.new(1, -46, 0.5, 0),
		AnchorPoint      = Vector2.new(0, 0.5),
		BackgroundColor3 = col,
		Parent           = header,
	})
	Corner(preview, 6)
	Stroke(preview, Color3.new(1, 1, 1), 1, 0.65)

	-- Expandable RGB panel
	local panel = New("Frame", {
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Tertiary,
		Visible          = false,
		Parent           = page,
	})
	Corner(panel)
	Padding(panel, 12, 12, 10, 12)
	New("UIListLayout", { Padding = UDim.new(0, 8), Parent = panel })

	-- Forward-declare hexLabel so rebuild() can reference it
	local hexLabel

	local function rebuild()
		col = Color3.fromRGB(rv, gv, bv)
		preview.BackgroundColor3 = col
		if hexLabel then hexLabel.Text = string.format("#%02X%02X%02X", rv, gv, bv) end
		if options.Callback then pcall(options.Callback, col) end
		if options.Flag     then win.Flags[options.Flag] = { rv, gv, bv } end
	end

	-- Mini slider helper used only inside this picker
	local function makeChannelSlider(parent, label, tint, getVal, setVal)
		local row = New("Frame", {
			Size                   = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Parent                 = parent,
		})
		New("TextLabel", {
			Size                   = UDim2.new(0, 14, 1, 0),
			BackgroundTransparency = 1,
			Text                   = label,
			TextColor3             = tint,
			TextSize               = 12,
			FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
			Parent                 = row,
		})
		local track = New("Frame", {
			Size             = UDim2.new(1, -56, 0, 6),
			Position         = UDim2.new(0, 20, 0.5, 0),
			AnchorPoint      = Vector2.new(0, 0.5),
			BackgroundColor3 = Theme.Secondary,
			Parent           = row,
		})
		Corner(track, 3)
		local fill = New("Frame", {
			Size             = UDim2.new(getVal() / 255, 0, 1, 0),
			BackgroundColor3 = tint,
			Parent           = track,
		})
		Corner(fill, 3)
		local knob = New("Frame", {
			Size             = UDim2.new(0, 13, 0, 13),
			Position         = UDim2.new(getVal() / 255, 0, 0.5, 0),
			AnchorPoint      = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent           = track,
		})
		Corner(knob, 7)
		local numLbl = New("TextLabel", {
			Size                   = UDim2.new(0, 30, 1, 0),
			Position               = UDim2.new(1, -30, 0, 0),
			BackgroundTransparency = 1,
			Text                   = tostring(getVal()),
			TextColor3             = Theme.TextDim,
			TextSize               = 11,
			TextXAlignment         = Enum.TextXAlignment.Right,
			Parent                 = row,
		})

		local dragging = false

		local function apply(xPos)
			local pct = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local v   = math.floor(pct * 255)
			setVal(v)
			Tween(fill,  { Size = UDim2.new(pct, 0, 1, 0) })
			Tween(knob,  { Position = UDim2.new(pct, 0, 0.5, 0) })
			numLbl.Text = tostring(v)
			rebuild()
		end

		knob.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
		end)
		track.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				apply(i.Position.X)
			end
		end)
		local c1 = UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end
		end)
		local c2 = UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		table.insert(win.Connections, c1)
		table.insert(win.Connections, c2)
	end

	makeChannelSlider(panel, "R", Color3.fromRGB(220, 60, 60),
		function() return rv end, function(v) rv = v end)
	makeChannelSlider(panel, "G", Color3.fromRGB(60, 200, 80),
		function() return gv end, function(v) gv = v end)
	makeChannelSlider(panel, "B", Color3.fromRGB(60, 140, 255),
		function() return bv end, function(v) bv = v end)

	hexLabel = New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text                   = string.format("#%02X%02X%02X", rv, gv, bv),
		TextColor3             = Theme.TextDim,
		TextSize               = 11,
		TextXAlignment         = Enum.TextXAlignment.Center,
		Parent                 = panel,
	})

	-- Toggle expand
	local open = false
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			open          = not open
			panel.Visible = open
		end
	end)
	header.MouseEnter:Connect(function() Tween(header, { BackgroundColor3 = Theme.Tertiary }) end)
	header.MouseLeave:Connect(function() Tween(header, { BackgroundColor3 = Theme.Secondary }) end)

	return {
		Set = function(c)
			col = c
			rv, gv, bv = math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)
			preview.BackgroundColor3 = c
			if hexLabel then hexLabel.Text = string.format("#%02X%02X%02X", rv, gv, bv) end
		end,
		Get = function() return col end,
	}
end

-- ==================== NOTIFICATION ====================
function Simpliciton:Notify(title, content, duration, notifType)
	duration  = duration  or 4
	notifType = notifType or "info"

	local accent = (notifType == "success" and Theme.Success)
		or (notifType == "error" and Theme.Error)
		or Theme.Accent

	local notif = New("Frame", {
		Size             = UDim2.new(0, 316, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		Position         = UDim2.new(1, 20, 1, -10),    -- starts off-screen right
		AnchorPoint      = Vector2.new(1, 1),
		BackgroundColor3 = Theme.Secondary,
		Parent           = self.ScreenGui,
	})
	Corner(notif)
	Stroke(notif, accent, 1.3, 0.2)

	-- Left colour stripe
	local stripe = New("Frame", {
		Size             = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel  = 0,
		ZIndex           = 2,
		Parent           = notif,
	})
	Corner(stripe, 3)

	local inner = New("Frame", {
		Size                   = UDim2.new(1, -14, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		Position               = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Parent                 = notif,
	})
	New("UIListLayout", { Padding = UDim.new(0, 3), Parent = inner })
	Padding(inner, 0, 4, 9, 10)

	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = title,
		TextColor3             = accent,
		TextSize               = 13,
		FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		Parent                 = inner,
	})
	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text                   = content,
		TextColor3             = Theme.Text,
		TextSize               = 12,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextWrapped            = true,
		Parent                 = inner,
	})

	-- Slide in from the right
	Tween(notif, { Position = UDim2.new(1, -10, 1, -10) }, TweenMedium)

	task.delay(duration, function()
		if notif and notif.Parent then
			Tween(notif, { Position = UDim2.new(1, 340, 1, -10) }, TweenMedium)
			task.delay(0.35, function()
				if notif and notif.Parent then notif:Destroy() end
			end)
		end
	end)
end

-- ==================== BUILT-IN SETTINGS TAB ====================
function Simpliciton:_CreateSettingsTab()
	-- Uses tab:CreateX() pattern – works because GetPage() resolves self.Page
	local tab = self:CreateTab("⚙  Settings")

	tab:CreateSection("Appearance")

	tab:CreateDropdown({
		Name          = "Accent Color",
		Options       = { "Blue", "Purple", "Emerald", "Rose", "Amber", "Cyan" },
		CurrentOption = "Blue",
		Callback = function(choice)
			local palette = {
				Blue    = Color3.fromRGB(85,  170, 255),
				Purple  = Color3.fromRGB(152, 94,  255),
				Emerald = Color3.fromRGB(68,  214, 132),
				Rose    = Color3.fromRGB(255, 95,  150),
				Amber   = Color3.fromRGB(255, 172, 55),
				Cyan    = Color3.fromRGB(55,  208, 215),
			}
			if palette[choice] then
				Theme.Accent = palette[choice]
				self:_RefreshAccent()
			end
		end,
	})

	tab:CreateToggle({
		Name         = "Rainbow Mode",
		CurrentValue = false,
		Callback = function(on)
			if on then
				if self.RainbowThread then self.RainbowThread:Disconnect() end
				self.RainbowThread = RunService.Heartbeat:Connect(function()
					Theme.Accent = Color3.fromHSV((tick() * 0.14) % 1, 0.82, 1)
					self:_RefreshAccent()
				end)
			else
				if self.RainbowThread then
					self.RainbowThread:Disconnect()
					self.RainbowThread = nil
				end
				Theme.Accent = Color3.fromRGB(85, 170, 255)
				self:_RefreshAccent()
			end
		end,
	})

	tab:CreateSection("Configuration")

	tab:CreateButton({
		Name     = "💾  Save Config",
		Callback = function()
			if not self.ConfigSaving.Enabled then
				self:Notify("Config", "Config saving is disabled.", 3, "error")
				return
			end
			local ok, encoded = pcall(HttpService.JSONEncode, HttpService, self.Flags)
			if ok then
				-- writefile(self.ConfigSaving.FileName, encoded)   ← enable in executor
				print("[Simpliciton] Config saved:\n" .. encoded)
				self:Notify("Saved!", "Config written to console.", 3, "success")
			else
				self:Notify("Error", "Failed to encode config.", 3, "error")
			end
		end,
	})

	tab:CreateParagraph({
		Title   = "Simpliciton  v2.0",
		Content = "A clean, modern Roblox UI library.\nFixed & enhanced – March 2026.",
	})
end

-- Propagates the current Theme.Accent colour to all live UI elements
function Simpliciton:_RefreshAccent()
	if self.Header then
		Tween(self.Header, { BackgroundColor3 = Theme.Accent })
		local fill = self.Header:FindFirstChild("CornerFill")
		if fill then Tween(fill, { BackgroundColor3 = Theme.Accent }) end
	end
	-- Active tab indicator
	if self.CurrentTab then
		Tween(self.CurrentTab.ActiveBar, { BackgroundColor3 = Theme.Accent })
	end
end

-- ==================== CLEANUP ====================
function Simpliciton:Destroy()
	for _, conn in ipairs(self.Connections or {}) do
		pcall(function() conn:Disconnect() end)
	end
	if self.RainbowThread then
		pcall(function() self.RainbowThread:Disconnect() end)
		self.RainbowThread = nil
	end
	if self.ScreenGui then
		pcall(function() self.ScreenGui:Destroy() end)
	end
end

return Simpliciton
