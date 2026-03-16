--[[
	Simpliciton  v4.0  "Rebuilt"
	A clean UI library built on Rayfield's proven patterns.
	Visually distinct: top-tab pill navigation, flat dark design.

	API (matches Rayfield where possible):
	  local Lib    = loadstring(...)()
	  local Window = Lib:CreateWindow({ Name=, Theme=, ConfigurationSaving={} })
	  local Tab    = Window:CreateTab("Name", iconId)
	  Tab:CreateButton({ Name=, Callback= })
	  Tab:CreateToggle({ Name=, CurrentValue=, Flag=, Callback= })
	  Tab:CreateSlider({ Name=, Range={min,max}, Increment=, CurrentValue=, Flag=, Callback= })
	  Tab:CreateDropdown({ Name=, Options={}, CurrentOption={}, MultipleOptions=, Flag=, Callback= })
	  Tab:CreateInput({ Name=, CurrentValue=, PlaceholderText=, Flag=, Callback= })
	  Tab:CreateKeybind({ Name=, CurrentKeybind=, HoldToInteract=, Flag=, Callback= })
	  Tab:CreateColorPicker({ Name=, Color=, Flag=, Callback= })
	  Tab:CreateSection("Name")
	  Tab:CreateDivider()
	  Tab:CreateLabel("text")
	  Tab:CreateParagraph({Title=, Content=})
	  Window:Notify({ Title=, Content=, Duration=, Image= })
	  Window:LoadConfiguration()  /  Window:SaveConfiguration()
	  Window:Destroy()
]]

-- ── Rayfield-proven service getter ──────────────────────────
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

-- ── Rayfield-proven callSafely ───────────────────────────────
local function callSafely(fn, ...)
	if not fn then return nil end
	local ok, r = pcall(fn, ...)
	if not ok then warn("[Simpliciton] " .. tostring(r)) return nil end
	return r
end

local function ensureFolder(path)
	if isfolder and not callSafely(isfolder, path) then
		callSafely(makefolder, path)
	end
end

-- ── Tween helper ─────────────────────────────────────────────
local function Tween(obj, props, t, style, dir)
	if not obj or not obj.Parent then return end
	pcall(function()
		TweenService:Create(obj,
			TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
			props):Play()
	end)
end

-- ── Corner / Stroke helpers ───────────────────────────────────
local function Corner(f, r)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = f; return c
end
local function Stroke(f, col, t, trans)
	local s = Instance.new("UIStroke")
	s.Color = col or Color3.new(1,1,1); s.Thickness = t or 1
	s.Transparency = trans or 0; s.Parent = f; return s
end
local function Pad(f, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, l or 0); p.PaddingRight = UDim.new(0, r or 0)
	p.PaddingTop  = UDim.new(0, t or 0); p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent = f; return p
end
local function VList(f, pad)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, pad or 6)
	l.FillDirection = Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = f; return l
end
local function HList(f, pad)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, pad or 6)
	l.FillDirection = Enum.FillDirection.Horizontal
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = f; return l
end

-- ── Auto canvas size ─────────────────────────────────────────
local function AutoCanvas(scroll, list)
	local function update()
		if scroll and scroll.Parent then
			scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 16)
		end
	end
	pcall(function() scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
end

-- ── New instance helper ───────────────────────────────────────
local function New(class, props)
	local ok, inst = pcall(Instance.new, class)
	if not ok then return nil end
	for k, v in pairs(props or {}) do
		pcall(function() inst[k] = v end)
	end
	return inst
end

-- ── Theme ─────────────────────────────────────────────────────
local Themes = {
	Dark = {
		BG        = Color3.fromRGB(14,  14,  18 ),
		Surface   = Color3.fromRGB(22,  22,  28 ),
		Element   = Color3.fromRGB(30,  30,  38 ),
		ElementHv = Color3.fromRGB(38,  38,  48 ),
		Accent    = Color3.fromRGB(99,  160, 255),
		Text      = Color3.fromRGB(230, 230, 240),
		TextDim   = Color3.fromRGB(110, 110, 135),
		Border    = Color3.fromRGB(45,  45,  58 ),
		Success   = Color3.fromRGB(72,  210, 130),
		Warning   = Color3.fromRGB(255, 185, 55 ),
		Error     = Color3.fromRGB(255, 75,  75 ),
	},
	Light = {
		BG        = Color3.fromRGB(242, 242, 250),
		Surface   = Color3.fromRGB(255, 255, 255),
		Element   = Color3.fromRGB(235, 235, 242),
		ElementHv = Color3.fromRGB(220, 220, 232),
		Accent    = Color3.fromRGB(80,  130, 220),
		Text      = Color3.fromRGB(25,  25,  40 ),
		TextDim   = Color3.fromRGB(130, 130, 155),
		Border    = Color3.fromRGB(200, 200, 215),
		Success   = Color3.fromRGB(40,  175, 100),
		Warning   = Color3.fromRGB(215, 150, 30 ),
		Error     = Color3.fromRGB(215, 50,  50 ),
	},
}

-- ════════════════════════════════════════════════════════════
--  LIBRARY
-- ════════════════════════════════════════════════════════════
local Simpliciton = {}
Simpliciton.__index = Simpliciton
Simpliciton.Flags   = {}
Simpliciton.Version = "4.0"

-- ── GUI parent (Rayfield-proven priority chain) ───────────────
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

-- ── Draggable (Rayfield RenderStepped pattern) ────────────────
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

-- ════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateWindow(opts)
	opts = opts or {}
	local win    = setmetatable({}, Simpliciton)
	win.Name     = opts.Name or "Simpliciton"
	win.Flags    = {}
	win._conns   = {}
	win._tabs    = {}
	win._currentTab = nil

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

	-- ── ScreenGui ─────────────────────────────────────────────
	local sg = New("ScreenGui", {
		Name            = "SimplicitonUI_" .. win.Name,
		ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn    = false,
		DisplayOrder    = 150,
	})

	-- Rayfield-pattern parenting
	local guiParent = getGuiParent()
	if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
	sg.Parent = guiParent

	-- Kill any old duplicate
	if guiParent then
		for _, c in ipairs(guiParent:GetChildren()) do
			if c.Name == sg.Name and c ~= sg then
				pcall(function() c:Destroy() end)
			end
		end
	end
	win.ScreenGui = sg

	-- ── Shadow ───────────────────────────────────────────────
	New("ImageLabel", {
		Size = UDim2.new(0, 750, 0, 530),
		Position = UDim2.new(0.5, -375, 0.5, -265),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49,49,450,450),
		ZIndex = 0,
		Parent = sg,
	})

	-- ── Main frame ───────────────────────────────────────────
	local main = New("Frame", {
		Name             = "Main",
		Size             = UDim2.new(0, 680, 0, 440),
		Position         = UDim2.new(0.5, -340, 0.5, -220),
		BackgroundColor3 = th.BG,
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		Parent           = sg,
	})
	Corner(main, 12)
	Stroke(main, th.Border, 1, 0)
	win.Main = main

	-- ── Top bar ──────────────────────────────────────────────
	local topbar = New("Frame", {
		Name             = "Topbar",
		Size             = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = th.Surface,
		BorderSizePixel  = 0,
		ZIndex           = 4,
		Parent           = main,
	})
	-- round just the top corners
	Corner(topbar, 12)
	-- fill bottom so it's flat on the bottom edge
	New("Frame", {
		Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = th.Surface, BorderSizePixel = 0, ZIndex = 3, Parent = topbar,
	})
	-- thin bottom border
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = th.Border, BorderSizePixel = 0, ZIndex = 5, Parent = topbar,
	})

	-- Title
	local titleLbl = New("TextLabel", {
		Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1, ZIndex = 6,
		Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = th.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = win.Name,
	})
	titleLbl.Parent = topbar
	win._titleLabel = titleLbl

	-- Close button
	local closeBtn = New("TextButton", {
		Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -36, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5), ZIndex = 7,
		BackgroundColor3 = Color3.fromRGB(255, 75, 75),
		Text = "✕", TextColor3 = Color3.new(1,1,1),
		Font = Enum.Font.GothamBold, TextSize = 11,
		Parent = topbar,
	})
	Corner(closeBtn, 11)
	closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 120, 120)}) end)
	closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 75, 75)}) end)
	closeBtn.MouseButton1Click:Connect(function() win:Destroy() end)

	-- Min button
	local minBtn = New("TextButton", {
		Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -62, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5), ZIndex = 7,
		BackgroundColor3 = Color3.fromRGB(255, 185, 40),
		Text = "–", TextColor3 = Color3.fromRGB(140, 90, 0),
		Font = Enum.Font.GothamBold, TextSize = 13,
		Parent = topbar,
	})
	Corner(minBtn, 11)
	minBtn.MouseEnter:Connect(function() Tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 215, 80)}) end)
	minBtn.MouseLeave:Connect(function() Tween(minBtn, {BackgroundColor3 = Color3.fromRGB(255, 185, 40)}) end)
	minBtn.MouseButton1Click:Connect(function()
		if win._minimised then win:Maximise() else win:Minimise() end
	end)

	makeDraggable(main, topbar)

	-- ── Tab bar (scrollable horizontal pills) ─────────────────
	local tabBar = New("ScrollingFrame", {
		Name = "TabBar",
		Size = UDim2.new(1, -200, 0, 32),
		Position = UDim2.new(0, 100, 0, 8),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = topbar,
	})
	HList(tabBar, 6)
	Pad(tabBar, 4, 4, 0, 0)
	win._tabBar = tabBar

	-- ── Content ───────────────────────────────────────────────
	local content = New("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -48),
		Position = UDim2.new(0, 0, 0, 48),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Parent = main,
	})
	win._content = content

	-- ── Notification stack ────────────────────────────────────
	local notifStack = New("Frame", {
		Size = UDim2.new(0, 300, 0, 600),
		Position = UDim2.new(1, -(300+20), 1, -(600+20)),
		BackgroundTransparency = 1, ZIndex = 100, Parent = sg,
	})
	local notifList = VList(notifStack, 8)
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	win._notifStack = notifStack

	-- ── Keybind toggle ────────────────────────────────────────
	if opts.ToggleUIKeybind then
		local key = opts.ToggleUIKeybind
		if typeof(key) == "EnumItem" then key = key.Name end
		local conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if tostring(input.KeyCode):find(key) then
				win.Main.Visible = not win.Main.Visible
			end
		end)
		table.insert(win._conns, conn)
	end

	win._minimised = false
	win._visible   = true

	-- Load config after 1s to let elements register
	if win._cfgEnabled then
		task.spawn(function()
			task.wait(1)
			win:LoadConfiguration()
		end)
	end

	return win
end

-- ════════════════════════════════════════════════════════════
--  WINDOW METHODS
-- ════════════════════════════════════════════════════════════
function Simpliciton:Minimise()
	self._minimised = true
	Tween(self.Main, {Size = UDim2.new(0, 680, 0, 48)}, 0.35, Enum.EasingStyle.Quint)
end

function Simpliciton:Maximise()
	self._minimised = false
	Tween(self.Main, {Size = UDim2.new(0, 680, 0, 440)}, 0.35, Enum.EasingStyle.Back)
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

-- ── Select a tab ─────────────────────────────────────────────
function Simpliciton:_SelectTab(tab)
	self._currentTab = tab
	for _, t in ipairs(self._tabs) do
		local selected = (t == tab)
		t._page.Visible = selected
		Tween(t._btn, {
			BackgroundColor3 = selected and self.Theme.Accent or self.Theme.Element,
		}, 0.18)
		t._btnLabel.TextColor3 = selected and Color3.new(1,1,1) or self.Theme.TextDim
	end
end

-- ════════════════════════════════════════════════════════════
--  NOTIFICATIONS  (Rayfield-style task.spawn pattern)
-- ════════════════════════════════════════════════════════════
function Simpliciton:Notify(titleOrData, content, duration, notifType)
	local title = titleOrData
	if type(titleOrData) == "table" then
		local d = titleOrData
		title     = d.Title    or "Notice"
		content   = d.Content  or ""
		duration  = d.Duration or 4
		notifType = d.Type
	end
	title    = title    or "Notice"
	content  = content  or ""
	duration = duration or 4

	local th = self.Theme
	local accentColor = (notifType == "success" and th.Success)
		or (notifType == "error"   and th.Error)
		or (notifType == "warning" and th.Warning)
		or th.Accent

	task.spawn(function()
		local notif = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = th.Surface,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = 101,
			Parent = self._notifStack,
		})
		Corner(notif, 10)
		Stroke(notif, accentColor, 1.5, 0)

		-- Accent left strip
		New("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			ZIndex = 102,
			Parent = notif,
		})
		Corner(New("Frame", {
			Size = UDim2.new(0, 8, 1, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			ZIndex = 101,
			Parent = notif,
		}), 0)

		local titleLbl = New("TextLabel", {
			Size = UDim2.new(1, -18, 0, 20),
			Position = UDim2.new(0, 14, 0, 10),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 13, TextColor3 = th.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = title, ZIndex = 103, Parent = notif,
		})
		local bodyLbl = New("TextLabel", {
			Size = UDim2.new(1, -18, 0, 0),
			Position = UDim2.new(0, 14, 0, 32),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12, TextColor3 = th.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Text = content, ZIndex = 103, Parent = notif,
		})

		task.wait()
		local textH = bodyLbl.TextBounds.Y
		local totalH = 32 + textH + 14
		Tween(notif, {Size = UDim2.new(1, 0, 0, totalH), BackgroundTransparency = 0}, 0.3)

		task.wait(duration)

		Tween(notif, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.25)
		task.wait(0.3)
		pcall(function() notif:Destroy() end)
	end)
end

-- ════════════════════════════════════════════════════════════
--  CREATE TAB
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateTab(name, _icon)
	local th = self.Theme
	local tab = { _win = self, _elements = {}, _elementList = {} }

	-- Tab button (pill)
	local btn = New("TextButton", {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = th.Element,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13, Text = "",
		ZIndex = 6,
		Parent = self._tabBar,
	})
	Corner(btn, 8)
	Pad(btn, 14, 14, 0, 0)

	local btnLabel = New("TextLabel", {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = th.TextDim,
		Text = name,
		ZIndex = 7,
		Parent = btn,
	})
	tab._btn = btn
	tab._btnLabel = btnLabel

	-- Tab page (scrolling frame for elements)
	local page = New("ScrollingFrame", {
		Name = "Page_" .. name,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = th.Accent,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Visible = false,
		BorderSizePixel = 0,
		Parent = self._content,
	})
	local pageList = VList(page, 6)
	Pad(page, 14, 14, 12, 12)
	AutoCanvas(page, pageList)
	tab._page = page
	tab._pageList = pageList

	btn.MouseButton1Click:Connect(function()
		self:_SelectTab(tab)
	end)
	btn.MouseEnter:Connect(function()
		if self._currentTab ~= tab then
			Tween(btn, {BackgroundColor3 = th.ElementHv}, 0.15)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self._currentTab ~= tab then
			Tween(btn, {BackgroundColor3 = th.Element}, 0.15)
		end
	end)

	table.insert(self._tabs, tab)
	setmetatable(tab, { __index = self })

	-- First tab auto-selected
	if #self._tabs == 1 then
		self:_SelectTab(tab)
	end

	-- Update tab bar canvas
	task.spawn(function()
		task.wait()
		local w = 0
		for _, t in ipairs(self._tabs) do
			w = w + t._btn.AbsoluteSize.X + 6
		end
		self._tabBar.CanvasSize = UDim2.new(0, w, 0, 0)
	end)

	return tab
end

-- ════════════════════════════════════════════════════════════
--  SHARED ELEMENT BUILDER HELPERS
-- ════════════════════════════════════════════════════════════
local function getPage(self)
	return rawget(self, "_page") or (rawget(self, "_win") and rawget(self._win, "_currentTab") and rawget(self._win._currentTab, "_page"))
end
local function getWin(self)
	return rawget(self, "_win") or self
end
local function getTheme(self)
	local w = getWin(self)
	return rawget(w, "Theme") or Themes.Dark
end

-- Base element frame (card)
local function makeCard(page, th, height)
	local f = New("Frame", {
		Size = UDim2.new(1, 0, 0, height or 44),
		BackgroundColor3 = th.Element,
		BorderSizePixel = 0,
		Parent = page,
	})
	Corner(f, 8)
	return f
end

-- ════════════════════════════════════════════════════════════
--  SECTION
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateSection(title)
	local page = getPage(self); if not page then return {} end
	local th = getTheme(self)

	local f = New("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Parent = page,
	})
	local lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11, TextColor3 = getTheme(self).TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(title or "Section"),
		Parent = f,
	})
	-- divider line
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = th.Border,
		BorderSizePixel = 0,
		Parent = f,
	})

	return {
		Set = function(_, t) lbl.Text = string.upper(t or "") end,
	}
end

-- ════════════════════════════════════════════════════════════
--  DIVIDER
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateDivider()
	local page = getPage(self); if not page then return {} end
	local th = getTheme(self)
	local f = New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = th.Border,
		BorderSizePixel = 0,
		Parent = page,
	})
	return { Set = function(_, v) f.Visible = v end }
end

-- ════════════════════════════════════════════════════════════
--  LABEL
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateLabel(text, _tooltip)
	local page = getPage(self); if not page then return {} end
	local th = getTheme(self)
	local f = makeCard(page, th, 36)
	f.BackgroundColor3 = th.Surface
	Pad(f, 14, 14, 0, 0)
	local lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13, TextColor3 = th.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text or "",
		Parent = f,
	})
	return { Set = function(_, t) lbl.Text = t end,
	         SetVisible = function(_, v) f.Visible = v end }
end

-- ════════════════════════════════════════════════════════════
--  PARAGRAPH
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateParagraph(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th = getTheme(self)
	local f = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = th.Surface,
		BorderSizePixel = 0,
		Parent = page,
	})
	Corner(f, 8)
	Pad(f, 14, 14, 10, 10)
	VList(f, 4)
	local titleLbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13, TextColor3 = th.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Title or "",
		Parent = f,
	})
	local bodyLbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12, TextColor3 = th.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = opts.Content or "",
		Parent = f,
	})
	return {
		Set = function(_, o)
			titleLbl.Text = o.Title or ""
			bodyLbl.Text  = o.Content or ""
		end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ════════════════════════════════════════════════════════════
--  BUTTON
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateButton(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local th = getTheme(self)

	local f = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = th.Accent,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13, TextColor3 = Color3.new(1,1,1),
		Text = opts.Name or "Button",
		BorderSizePixel = 0,
		Parent = page,
	})
	Corner(f, 8)

	f.MouseEnter:Connect(function()
		Tween(f, {BackgroundColor3 = Color3.fromRGB(
			math.min(255, th.Accent.R*255 + 20),
			math.min(255, th.Accent.G*255 + 20),
			math.min(255, th.Accent.B*255 + 20))})
	end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Accent}) end)
	f.MouseButton1Click:Connect(function()
		if opts.Callback then pcall(opts.Callback) end
	end)

	return {
		Set        = function(_, t) f.Text = t end,
		SetEnabled = function(_, v) f.Active = v; f.BackgroundTransparency = v and 0 or 0.4 end,
		SetVisible = function(_, v) f.Visible = v end,
		Fire       = function(_) if opts.Callback then pcall(opts.Callback) end end,
	}
end

-- ════════════════════════════════════════════════════════════
--  TOGGLE
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateToggle(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local val = opts.CurrentValue == true
	if opts.Flag then Simpliciton.Flags[opts.Flag] = val end

	local f = makeCard(page, th, 44)
	Pad(f, 14, 14, 0, 0)

	-- Label
	New("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = th.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Toggle",
		Parent = f,
	})

	-- Switch track
	local track = New("Frame", {
		Size = UDim2.new(0, 44, 0, 24),
		Position = UDim2.new(1, -44, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = val and th.Accent or th.Border,
		BorderSizePixel = 0,
		Parent = f,
	})
	Corner(track, 12)

	-- Switch knob
	local knob = New("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0, val and 22 or 4, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.new(1,1,1),
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(knob, 9)

	local function setState(v, silent)
		val = v
		if opts.Flag then
			Simpliciton.Flags[opts.Flag] = v
			win.Flags[opts.Flag] = v
		end
		Tween(track, {BackgroundColor3 = v and th.Accent or th.Border})
		Tween(knob,  {Position = UDim2.new(0, v and 22 or 4, 0.5, 0)})
		if not silent and opts.Callback then pcall(opts.Callback, v) end
	end

	-- Click anywhere on card
	local interact = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
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

-- ════════════════════════════════════════════════════════════
--  SLIDER  (Rayfield Stepped loop pattern)
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateSlider(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	-- Accept Range={min,max}/Increment OR Min/Max
	local mn = (opts.Range and opts.Range[1]) or opts.Min or 0
	local mx = (opts.Range and opts.Range[2]) or opts.Max or 100
	local inc = opts.Increment
	local val = math.clamp(opts.CurrentValue or mn, mn, mx)
	if opts.Flag then Simpliciton.Flags[opts.Flag] = val end

	local f = makeCard(page, th, 58)
	Pad(f, 14, 14, 0, 0)

	-- Name + value row
	New("TextLabel", {
		Size = UDim2.new(1, -70, 0, 26),
		Position = UDim2.new(0, 0, 0, 9),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = th.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Slider",
		Parent = f,
	})
	local valLbl = New("TextLabel", {
		Size = UDim2.new(0, 64, 0, 26),
		Position = UDim2.new(1, -64, 0, 9),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(val) .. (opts.Suffix and " " .. opts.Suffix or ""),
		Parent = f,
	})

	-- Track
	local track = New("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 1, -12),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = th.Border,
		BorderSizePixel = 0,
		Parent = f,
	})
	Corner(track, 3)

	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = th.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(fill, 3)

	local knob = New("Frame", {
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1,1,1),
		BorderSizePixel = 0,
		Parent = track,
	})
	Corner(knob, 7)

	local function update(v, fire)
		if inc and inc > 0 then v = math.floor(v / inc + 0.5) * inc end
		v = math.clamp(v, mn, mx)
		-- round for display
		local dp = (opts.Decimals or 0)
		local fmt = "%." .. dp .. "f"
		v = tonumber(string.format(fmt, v)) or v
		val = v
		local pct = (v - mn) / (mx - mn)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, 0, 0.5, 0)
		valLbl.Text = tostring(v) .. (opts.Suffix and " " .. opts.Suffix or "")
		if fire then
			if opts.Flag then Simpliciton.Flags[opts.Flag] = v; win.Flags[opts.Flag] = v end
			if opts.Callback then pcall(opts.Callback, v) end
		end
	end
	update(val, false)

	local dragging = false

	-- Rayfield slider: InputBegan on interact → Stepped loop
	local interact = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -14),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1, Text = "",
		ZIndex = 6, Parent = f,
	})
	interact.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
		   input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true
		local loop; loop = RunService.Stepped:Connect(function()
			if not dragging then loop:Disconnect(); return end
			local x = UserInputService:GetMouseLocation().X
			local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
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

-- ════════════════════════════════════════════════════════════
--  INPUT
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateInput(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local f = makeCard(page, th, 60)
	Pad(f, 14, 14, 0, 0)

	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 6),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = th.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Input",
		Parent = f,
	})

	local box = New("TextBox", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0, 0, 1, -33),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = th.BG,
		Font = Enum.Font.Gotham,
		TextSize = 12, TextColor3 = th.Text,
		PlaceholderColor3 = th.TextDim,
		PlaceholderText = opts.PlaceholderText or "Type here…",
		ClearTextOnFocus = false,
		Text = opts.CurrentValue or "",
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = f,
	})
	Corner(box, 6)
	Stroke(box, th.Border, 1, 0)
	Pad(box, 8, 8, 0, 0)

	box.Focused:Connect(function() Tween(box, {}, 0.15) end)
	box.FocusLost:Connect(function(enter)
		local text = box.Text
		if opts.RemoveTextAfterFocusLost then box.Text = "" end
		if opts.Flag then Simpliciton.Flags[opts.Flag] = text; win.Flags[opts.Flag] = text end
		if opts.Callback then pcall(opts.Callback, text) end
	end)
	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set        = function(_, t) box.Text = t end,
		Get        = function() return box.Text end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ════════════════════════════════════════════════════════════
--  KEYBIND  (Rayfield connection-table pattern)
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateKeybind(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local currentKey = opts.CurrentKeybind or "None"
	local listening  = false

	local f = makeCard(page, th, 44)
	Pad(f, 14, 14, 0, 0)

	New("TextLabel", {
		Size = UDim2.new(1, -100, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = th.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Keybind",
		Parent = f,
	})

	local keyBtn = New("TextButton", {
		Size = UDim2.new(0, 90, 0, 28),
		Position = UDim2.new(1, -90, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = th.BG,
		Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.Text,
		Text = currentKey,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = f,
	})
	Corner(keyBtn, 6)
	Stroke(keyBtn, th.Border, 1, 0)

	keyBtn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		keyBtn.Text = "…"
	end)

	local kConn = UserInputService.InputBegan:Connect(function(input, processed)
		if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
			local keyName = tostring(input.KeyCode):gsub("Enum%.KeyCode%.", "")
			currentKey = keyName
			keyBtn.Text = keyName
			listening = false
			if opts.Flag then Simpliciton.Flags[opts.Flag] = keyName; win.Flags[opts.Flag] = keyName end
			if opts.CallOnChange and opts.Callback then pcall(opts.Callback, keyName) end
		elseif not listening and not processed then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				local keyName = tostring(input.KeyCode):gsub("Enum%.KeyCode%.", "")
				if keyName == currentKey then
					if not opts.HoldToInteract then
						if opts.Callback then pcall(opts.Callback) end
					end
				end
			end
		end
	end)
	table.insert(win._conns, kConn)

	f.MouseEnter:Connect(function() Tween(f, {BackgroundColor3 = th.ElementHv}) end)
	f.MouseLeave:Connect(function() Tween(f, {BackgroundColor3 = th.Element}) end)

	return {
		Set        = function(_, k) currentKey = tostring(k); keyBtn.Text = tostring(k) end,
		Get        = function() return currentKey end,
		SetVisible = function(_, v) f.Visible = v end,
	}
end

-- ════════════════════════════════════════════════════════════
--  DROPDOWN  (Rayfield open/close pattern)
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateDropdown(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)
	local multi    = opts.MultipleOptions == true
	local selected = {}
	if opts.CurrentOption then
		if type(opts.CurrentOption) == "string" then
			selected = {opts.CurrentOption}
		else
			selected = opts.CurrentOption
		end
	end
	if not multi and #selected > 1 then selected = {selected[1]} end
	if opts.Flag then Simpliciton.Flags[opts.Flag] = selected end

	local isOpen = false

	-- Header card
	local header = makeCard(page, th, 44)
	Pad(header, 14, 14, 0, 0)

	New("TextLabel", {
		Size = UDim2.new(1, -120, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = th.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Dropdown",
		Parent = header,
	})

	local selLbl = New("TextLabel", {
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(1, -114, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12, TextColor3 = th.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = #selected > 0 and (#selected == 1 and selected[1] or "Multiple") or "None",
		Parent = header,
	})

	local arrow = New("TextLabel", {
		Size = UDim2.new(0, 14, 1, 0),
		Position = UDim2.new(1, -14, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.TextDim,
		Text = "▾",
		Parent = header,
	})

	-- Dropdown list (sits OUTSIDE the scroll frame to avoid clipping)
	local listFrame = New("Frame", {
		Size = UDim2.new(0, header.AbsoluteSize.X, 0, 0),
		BackgroundColor3 = th.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Visible = false,
		ZIndex = 50,
		Parent = win.ScreenGui,
	})
	Corner(listFrame, 8)
	Stroke(listFrame, th.Border, 1, 0)
	local listScroll = New("ScrollingFrame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = th.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 51,
		Parent = listFrame,
	})
	local listLayout = VList(listScroll, 2)
	Pad(listScroll, 4, 4, 4, 4)
	AutoCanvas(listScroll, listLayout)

	-- Position dropdown below header each frame it's open
	local posConn
	local function positionList()
		local absPos = header.AbsolutePosition
		local absSize = header.AbsoluteSize
		local itemH = math.min(#(opts.Options or {}), 6) * 36 + 8
		listFrame.Size = UDim2.new(0, absSize.X, 0, itemH)
		listFrame.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
	end

	local function updateLabel()
		if #selected == 0 then selLbl.Text = "None"
		elseif #selected == 1 then selLbl.Text = selected[1]
		else selLbl.Text = "Multiple (" .. #selected .. ")" end
	end

	local function buildOptions()
		for _, c in ipairs(listScroll:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		for _, opt in ipairs(opts.Options or {}) do
			local isSelected = table.find(selected, opt) ~= nil
			local row = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = isSelected and th.Accent or th.Element,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				TextColor3 = isSelected and Color3.new(1,1,1) or th.Text,
				Text = opt,
				BorderSizePixel = 0,
				ZIndex = 52,
				Parent = listScroll,
			})
			Corner(row, 6)
			row.MouseButton1Click:Connect(function()
				if multi then
					local idx = table.find(selected, opt)
					if idx then table.remove(selected, idx)
					else table.insert(selected, opt) end
				else
					selected = {opt}
					-- close after single pick
					isOpen = false
					listFrame.Visible = false
					arrow.Text = "▾"
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

	local interact = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "",
		ZIndex = 5, Parent = header,
	})
	interact.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			positionList()
			listFrame.Visible = true
			arrow.Text = "▴"
			posConn = RunService.RenderStepped:Connect(positionList)
		else
			listFrame.Visible = false
			arrow.Text = "▾"
			if posConn then posConn:Disconnect(); posConn = nil end
		end
	end)
	header.MouseEnter:Connect(function() Tween(header, {BackgroundColor3 = th.ElementHv}) end)
	header.MouseLeave:Connect(function() Tween(header, {BackgroundColor3 = th.Element}) end)

	-- Close when clicking outside
	local outsideConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if isOpen then
			local mpos = UserInputService:GetMouseLocation()
			local lp = listFrame.AbsolutePosition
			local ls = listFrame.AbsoluteSize
			if mpos.X < lp.X or mpos.X > lp.X+ls.X or mpos.Y < lp.Y or mpos.Y > lp.Y+ls.Y then
				local hp = header.AbsolutePosition
				local hs = header.AbsoluteSize
				if not (mpos.X >= hp.X and mpos.X <= hp.X+hs.X and mpos.Y >= hp.Y and mpos.Y <= hp.Y+hs.Y) then
					isOpen = false
					listFrame.Visible = false
					arrow.Text = "▾"
					if posConn then posConn:Disconnect(); posConn = nil end
				end
			end
		end
	end)
	table.insert(win._conns, outsideConn)

	return {
		Set = function(_, newOpt)
			if type(newOpt) == "string" then selected = {newOpt}
			else selected = newOpt end
			updateLabel(); buildOptions()
			if opts.Flag then Simpliciton.Flags[opts.Flag] = selected; win.Flags[opts.Flag] = selected end
			if opts.Callback then pcall(opts.Callback, selected) end
		end,
		GetSelected = function() return selected end,
		Refresh = function(_, newOpts) opts.Options = newOpts; buildOptions() end,
		SetVisible = function(_, v) header.Visible = v end,
	}
end

-- ════════════════════════════════════════════════════════════
--  COLOR PICKER  (Rayfield RenderStepped + GetMouse pattern)
-- ════════════════════════════════════════════════════════════
function Simpliciton:CreateColorPicker(opts)
	opts = opts or {}
	local page = getPage(self); if not page then return {} end
	local win  = getWin(self);  local th = getTheme(self)

	local startColor = opts.Color or opts.CurrentValue or Color3.fromRGB(255, 80, 80)
	local h0, s0, v0 = Color3.toHSV(startColor)
	local hue, sat, bri = h0, s0, v0

	-- Collapsed header
	local header = makeCard(page, th, 44)
	Pad(header, 14, 14, 0, 0)

	New("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = th.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Color",
		Parent = header,
	})

	local preview = New("Frame", {
		Size = UDim2.new(0, 32, 0, 22),
		Position = UDim2.new(1, -46, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = startColor,
		BorderSizePixel = 0,
		Parent = header,
	})
	Corner(preview, 5)
	Stroke(preview, th.Border, 1, 0)

	New("TextLabel", {
		Size = UDim2.new(0, 12, 1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.TextDim,
		Text = "▾",
		Parent = header,
	})

	-- Picker panel (floats above, attached to ScreenGui)
	local panel = New("Frame", {
		Size = UDim2.new(0, header.AbsoluteSize.X > 0 and header.AbsoluteSize.X or 320, 0, 200),
		BackgroundColor3 = th.Surface,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 60,
		Parent = win.ScreenGui,
	})
	Corner(panel, 10)
	Stroke(panel, th.Border, 1, 0)

	-- SV square (165×130)
	local svSize = 165
	local svBox = New("Frame", {
		Size = UDim2.new(0, svSize, 0, 130),
		Position = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 61,
		Parent = panel,
	})
	Corner(svBox, 6)
	-- White→transparent (left→right)
	New("UIGradient", {
		Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = svBox,
	})
	-- Transparent→black (top→bottom)
	local darkLayer = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		BorderSizePixel = 0, ZIndex = 62, Parent = svBox,
	})
	Corner(darkLayer, 6)
	New("UIGradient", {
		Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rotation = 90,
		Parent = darkLayer,
	})
	-- SV knob
	local svKnob = New("Frame", {
		Size = UDim2.new(0, 12, 0, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(s0, 0, 1 - v0, 0),
		BackgroundColor3 = Color3.new(1,1,1),
		BorderSizePixel = 0, ZIndex = 64, Parent = svBox,
	})
	Corner(svKnob, 6)
	Stroke(svKnob, Color3.new(0,0,0), 1.5, 0)

	-- Hue bar
	local hueBar = New("Frame", {
		Size = UDim2.new(0, svSize, 0, 14),
		Position = UDim2.new(0, 12, 0, 148),
		BorderSizePixel = 0, ZIndex = 61, Parent = panel,
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
		Size = UDim2.new(0, 10, 1, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(h0, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1,1,1),
		BorderSizePixel = 0, ZIndex = 62, Parent = hueBar,
	})
	Corner(hueKnob, 4)
	Stroke(hueKnob, Color3.new(0,0,0), 1.5, 0)

	-- Hex input (right side)
	local hexBox = New("TextBox", {
		Size = UDim2.new(0, 90, 0, 28),
		Position = UDim2.new(0, svSize + 22, 0, 12),
		BackgroundColor3 = th.Element,
		Font = Enum.Font.GothamBold,
		TextSize = 11, TextColor3 = th.Text,
		ClearTextOnFocus = false,
		Text = string.format("#%02X%02X%02X",
			math.floor(startColor.R*255), math.floor(startColor.G*255), math.floor(startColor.B*255)),
		PlaceholderText = "#RRGGBB",
		PlaceholderColor3 = th.TextDim,
		BorderSizePixel = 0, ZIndex = 62, Parent = panel,
	})
	Corner(hexBox, 6)
	Pad(hexBox, 8, 8, 0, 0)

	-- Large color preview (right side)
	local bigPreview = New("Frame", {
		Size = UDim2.new(0, 90, 0, 60),
		Position = UDim2.new(0, svSize + 22, 0, 46),
		BackgroundColor3 = startColor,
		BorderSizePixel = 0, ZIndex = 62, Parent = panel,
	})
	Corner(bigPreview, 8)
	Stroke(bigPreview, th.Border, 1, 0)

	local function rebuild()
		local col = Color3.fromHSV(hue, sat, bri)
		preview.BackgroundColor3   = col
		bigPreview.BackgroundColor3 = col
		svBox.BackgroundColor3     = Color3.fromHSV(hue, 1, 1)
		svKnob.Position            = UDim2.new(sat, 0, 1 - bri, 0)
		hueKnob.Position           = UDim2.new(hue, 0, 0.5, 0)
		hexBox.Text = string.format("#%02X%02X%02X",
			math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255))
		if opts.Flag then Simpliciton.Flags[opts.Flag] = col; win.Flags[opts.Flag] = col end
		if opts.Callback then pcall(opts.Callback, col) end
	end

	-- Panel positioning
	local panelConn
	local function posPanel()
		local absPos  = header.AbsolutePosition
		local absSize = header.AbsoluteSize
		local pw = panel.AbsoluteSize.X
		panel.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
		panel.Size = UDim2.new(0, math.max(pw, svSize + 22 + 90 + 18), 0, 200)
	end

	-- SV dragging (Rayfield RenderStepped + GetMouse)
	local svDragging = false
	svBox.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		svDragging = true
	end)
	local svEnd = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
	end)
	local svStep = RunService.RenderStepped:Connect(function()
		if not svDragging or not Mouse then return end
		local mx, my = Mouse.X, Mouse.Y
		sat = math.clamp((mx - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
		bri = 1 - math.clamp((my - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
		rebuild()
	end)
	table.insert(win._conns, svEnd)
	table.insert(win._conns, svStep)

	-- Hue dragging
	local hueDragging = false
	hueBar.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		hueDragging = true
	end)
	local hueEnd = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
	end)
	local hueStep = RunService.RenderStepped:Connect(function()
		if not hueDragging or not Mouse then return end
		hue = math.clamp((Mouse.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.9999)
		rebuild()
	end)
	table.insert(win._conns, hueEnd)
	table.insert(win._conns, hueStep)

	-- Hex input
	hexBox.FocusLost:Connect(function()
		local text = hexBox.Text:gsub("#", "")
		local r, g, b = text:match("^(%x%x)(%x%x)(%x%x)$")
		if r then
			local col = Color3.fromRGB(tonumber(r,16), tonumber(g,16), tonumber(b,16))
			hue, sat, bri = Color3.toHSV(col)
			rebuild()
		end
	end)

	-- Toggle panel
	local isOpen = false
	local interact = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "",
		ZIndex = 5, Parent = header,
	})
	interact.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		panel.Visible = isOpen
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
		Get        = function() return Color3.fromHSV(hue, sat, bri) end,
		SetVisible = function(_, v) header.Visible = v end,
	}
end

-- ════════════════════════════════════════════════════════════
--  CONFIG SAVE / LOAD  (Rayfield filesystem pattern)
-- ════════════════════════════════════════════════════════════
function Simpliciton:SaveConfiguration()
	if not self._cfgEnabled then return end
	local ok, data = pcall(HttpService.JSONEncode, HttpService, self.Flags)
	if not ok then return end
	if writefile then
		ensureFolder(self._cfgFolder)
		callSafely(writefile, self._cfgFolder .. "/" .. self._cfgFile, data)
		self:Notify({Title = "Saved", Content = "Config written.", Duration = 2})
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
	self:Notify({Title = "Loaded", Content = "Config restored.", Duration = 2})
end

-- Alias
Simpliciton.SaveConfig = Simpliciton.SaveConfiguration
Simpliciton.LoadConfig = Simpliciton.LoadConfiguration

return Simpliciton
