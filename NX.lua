local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local MAX_ENTRIES = 120
local TOGGLE_KEY = Enum.KeyCode.RightControl
local BG_TRANSPARENCY = 0.7
local SPAM_COOLDOWN = 0.25
local parent = (gethui and gethui()) or CoreGui
local old = parent:FindFirstChild("NX_Log")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "NX_Log"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
pcall(function()
	if syn and syn.protect_gui then syn.protect_gui(gui) end
end)
gui.Parent = parent
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local W, H = 500, 340
local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(W, H)
main.Position = UDim2.new(1, -W - 20, 0.5, -H / 2)
main.BackgroundColor3 = BLACK
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", main)
stroke.Color = WHITE
stroke.Thickness = 1
stroke.Transparency = 1
local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 30)
top.BackgroundTransparency = 1
top.Parent = main
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -190, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "NX_ LOG"
title.TextColor3 = WHITE
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextTransparency = 1
title.Parent = top
local function makeBtn(text, w, h, parentObj)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = WHITE
	b.BackgroundTransparency = 1
	b.Text = text
	b.TextColor3 = WHITE
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 11
	b.AutoButtonColor = false
	b.Parent = parentObj
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
	local s = Instance.new("UIStroke", b)
	s.Color = WHITE
	s.Transparency = 0.6
	b.MouseEnter:Connect(function() tween(b, 0.15, { BackgroundTransparency = 0.75 }) end)
	b.MouseLeave:Connect(function() tween(b, 0.15, { BackgroundTransparency = 1 }) end)
	return b
end
local closeBtn = makeBtn("X", 24, 20, top)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
local clearBtn = makeBtn("CLR", 38, 20, top)
clearBtn.Position = UDim2.new(1, -72, 0, 5)
local paused = false
local pauseBtn = makeBtn("PAUSE", 54, 20, top)
pauseBtn.Position = UDim2.new(1, -132, 0, 5)
pauseBtn.MouseButton1Click:Connect(function()
	paused = not paused
	pauseBtn.Text = paused and "RESUME" or "PAUSE"
end)
local filterBar = Instance.new("Frame")
filterBar.Size = UDim2.new(1, -20, 0, 24)
filterBar.Position = UDim2.fromOffset(10, 34)
filterBar.BackgroundTransparency = 1
filterBar.Parent = main
local fl = Instance.new("UIListLayout", filterBar)
fl.FillDirection = Enum.FillDirection.Horizontal
fl.Padding = UDim.new(0, 6)
local filter = "All"
local filterButtons = {}
local entries = {}
local searchText = ""
local function matches(e)
	if searchText ~= "" and not e.search:find(searchText, 1, true) then return false end
	if filter == "All" then return true end
	if filter == "Local" then return e.isLocal end
	return not e.isLocal
end
local function applyFilter()
	for _, e in ipairs(entries) do e.row.Visible = matches(e) end
	for name, b in pairs(filterButtons) do
		local active = name == filter
		b.BackgroundTransparency = active and 0.1 or 1
		b.TextColor3 = active and BLACK or WHITE
	end
end
local function addFilter(name, text, w)
	local b = makeBtn(text, w, 24, filterBar)
	b.MouseButton1Click:Connect(function()
		filter = name
		applyFilter()
	end)
	b.MouseLeave:Connect(function()
		if filter == name then b.BackgroundTransparency = 0.1 end
	end)
	filterButtons[name] = b
end
addFilter("All", "ALL", 50)
addFilter("Local", "ONLY LOCAL", 90)
addFilter("Others", "EXCEPT LOCAL", 110)
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.fromOffset(150, 24)
searchBox.BackgroundColor3 = WHITE
searchBox.BackgroundTransparency = 0.9
searchBox.Text = ""
searchBox.PlaceholderText = "search..."
searchBox.PlaceholderColor3 = Color3.fromRGB(190, 190, 190)
searchBox.TextColor3 = WHITE
searchBox.Font = Enum.Font.GothamMedium
searchBox.TextSize = 12
searchBox.ClearTextOnFocus = false
searchBox.Parent = filterBar
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchText = searchBox.Text:lower()
	applyFilter()
end)
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.fromOffset(10, 62)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = WHITE
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main
local ll = Instance.new("UIListLayout", scroll)
ll.Padding = UDim.new(0, 3)
ll.SortOrder = Enum.SortOrder.LayoutOrder
local function notify(btn, text)
	local orig = btn.Text
	btn.Text = text
	task.delay(0.8, function()
		if btn.Parent then btn.Text = orig end
	end)
end
local function getLocalAnimator()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local an = hum:FindFirstChildOfClass("Animator")
	if not an then
		an = Instance.new("Animator")
		an.Parent = hum
	end
	return an
end
local order = 0
local byKey = {}
local function fmtLine(time, owner, name)
	if name == "" then
		return ("[%s] %s"):format(time, owner)
	end
	return ("[%s] %s  •  %s"):format(time, owner, name)
end
local function refreshText(entry)
	local i = entry.info
	entry.line1.Text = fmtLine(entry.time, i.owner, i.animName)
	entry.badge.Text = "x" .. entry.count
end
local function addLog(info)
	local existing = byKey[info.key]
	if existing and existing.row.Parent then
		existing.count += 1
		existing.time = os.date("%H:%M:%S")
		existing.info.track = info.track
		refreshText(existing)
		existing.row.BackgroundTransparency = 0.6
		tween(existing.row, 0.4, { BackgroundTransparency = 0.92 })
		return
	end
	order += 1
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 54)
	row.BackgroundColor3 = WHITE
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
	local line1 = Instance.new("TextLabel")
	line1.Size = UDim2.new(1, -255, 0, 18)
	line1.Position = UDim2.fromOffset(6, 2)
	line1.BackgroundTransparency = 1
	line1.Text = fmtLine(os.date("%H:%M:%S"), info.owner, info.animName)
	line1.TextColor3 = WHITE
	line1.TextXAlignment = Enum.TextXAlignment.Left
	line1.TextTruncate = Enum.TextTruncate.AtEnd
	line1.Font = Enum.Font.GothamMedium
	line1.TextSize = 12
	line1.TextTransparency = 1
	line1.Parent = row
	local line2 = line1:Clone()
	line2.Position = UDim2.fromOffset(6, 19)
	line2.Text = info.animId
	line2.Font = Enum.Font.Code
	line2.TextSize = 11
	line2.Size = UDim2.new(1, -205, 0, 18)
	line2.Parent = row
	local line3 = line2:Clone()
	line3.Position = UDim2.fromOffset(6, 35)
	line3.Text = info.extra or ""
	line3.Parent = row
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(46, 18)
	badge.Position = UDim2.new(1, -249, 0, 2)
	badge.BackgroundColor3 = WHITE
	badge.BackgroundTransparency = 0.85
	badge.Text = "x1"
	badge.TextColor3 = WHITE
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 12
	badge.TextTransparency = 1
	badge.Parent = row
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)
	local btnHolder = Instance.new("Frame")
	btnHolder.Size = UDim2.fromOffset(190, 24)
	btnHolder.Position = UDim2.new(1, -194, 0.5, -12)
	btnHolder.BackgroundTransparency = 1
	btnHolder.Parent = row
	local bl = Instance.new("UIListLayout", btnHolder)
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.Padding = UDim.new(0, 4)
	local copyB = makeBtn("COPY", 44, 24, btnHolder)
	local playB = makeBtn("PLAY", 44, 24, btnHolder)
	local stopB = makeBtn("STOP", 44, 24, btnHolder)
	local luaB = makeBtn("LUA", 44, 24, btnHolder)
	luaB.MouseButton1Click:Connect(function()
		local snippet = ("local a = Instance.new(\"Animation\")\na.AnimationId = \"%s\"\nlocal t = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(a)\nt:Play()"):format(info.animId)
		local ok = pcall(function()
			(setclipboard or toclipboard or set_clipboard)(snippet)
		end)
		notify(luaB, ok and "OK" or "ERR")
	end)
	local entry = {
		row = row, isLocal = info.isLocal, replay = nil,
		key = info.key, count = 1, line1 = line1, badge = badge, info = info,
		search = (info.owner .. " " .. info.animName .. " " .. info.animId):lower(),
		time = os.date("%H:%M:%S"),
	}
	byKey[info.key] = entry
	copyB.MouseButton1Click:Connect(function()
		local ok = pcall(function()
			(setclipboard or toclipboard or set_clipboard)(info.animId)
		end)
		notify(copyB, ok and "OK" or "ERR")
	end)
	playB.MouseButton1Click:Connect(function()
		local an = getLocalAnimator()
		if not an then return notify(playB, "NO HUM") end
		if entry.replay then pcall(function() entry.replay:Stop(0) end) end
		local anim = Instance.new("Animation")
		anim.AnimationId = info.animId
		local ok, track = pcall(function() return an:LoadAnimation(anim) end)
		if ok and track then
			entry.replay = track
			track:Play()
		else
			notify(playB, "ERR")
		end
	end)
	stopB.MouseButton1Click:Connect(function()
		if entry.replay then pcall(function() entry.replay:Stop(0.1) end) end
		if info.track then pcall(function() info.track:Stop(0.1) end) end
	end)
	row.Visible = matches(entry)
	row.Parent = scroll
	table.insert(entries, entry)
	if #entries > MAX_ENTRIES then
		local first = table.remove(entries, 1)
		if first.replay then pcall(function() first.replay:Stop(0) end) end
		byKey[first.key] = nil
		first.row:Destroy()
	end
	tween(row, 0.25, { BackgroundTransparency = 0.92 })
	tween(line1, 0.25, { TextTransparency = 0 })
	tween(line2, 0.25, { TextTransparency = 0.25 })
	tween(line3, 0.25, { TextTransparency = 0.25 })
	tween(badge, 0.25, { TextTransparency = 0 })
	local atBottom = scroll.CanvasPosition.Y >= scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y - 50
	if atBottom then
		task.defer(function()
			scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
		end)
	end
end
local hooked = {}
local lastSeen = {}
local function hookAnimator(an)
	if hooked[an] then return end
	hooked[an] = true
	an.AnimationPlayed:Connect(function(track)
		if paused then return end
		local anim = track.Animation
		local id = anim and anim.AnimationId or "?"
		local model = an:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		local owner = plr and plr.Name or (model and model.Name) or "Unknown"
		local isLocal = model ~= nil and model == LocalPlayer.Character
		local animName = (track.Name ~= "" and track.Name) or (anim and anim.Name) or ""
		if animName == "Animation" then animName = "" end
		addLog({
			key = owner .. "|" .. id,
			owner = isLocal and "you" or owner,
			animName = animName,
			animId = id,
			isLocal = isLocal,
			track = track,
			extra = ("%.2fs  %s  %s"):format(track.Length, track.Priority.Name, track.Looped and "loop" or "once"),
		})
	end)
	an.Destroying:Connect(function() hooked[an] = nil end)
end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Animator") then hookAnimator(d) end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("Animator") then hookAnimator(d) end
end)
clearBtn.MouseButton1Click:Connect(function()
	for _, e in ipairs(entries) do
		if e.replay then pcall(function() e.replay:Stop(0) end) end
		e.row:Destroy()
	end
	table.clear(entries)
	table.clear(byKey)
end)
local visible = false
local function setVisible(v)
	visible = v
	if v then
		main.Visible = true
		main.Size = UDim2.fromOffset(W, 0)
		tween(main, 0.35, { Size = UDim2.fromOffset(W, H), BackgroundTransparency = BG_TRANSPARENCY }, Enum.EasingStyle.Back)
		tween(stroke, 0.35, { Transparency = 0.4 })
		tween(title, 0.35, { TextTransparency = 0 })
		applyFilter()
	else
		tween(stroke, 0.25, { Transparency = 1 })
		tween(title, 0.25, { TextTransparency = 1 })
		local tw = tween(main, 0.25, { Size = UDim2.fromOffset(W, 0), BackgroundTransparency = 1 })
		tw.Completed:Once(function()
			if not visible then main.Visible = false end
		end)
	end
end
closeBtn.MouseButton1Click:Connect(function() setVisible(false) end)
UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == TOGGLE_KEY then setVisible(not visible) end
end)
do
	local dragging, startPos, startInput
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, i.Position, main.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startInput
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end
setVisible(true)
