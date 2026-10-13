-- <w> : by wleo : yoruka.id
-- LocalScript → StarterPlayer > StarterPlayerScripts
-- Panel analisis untuk game asimetris ala VD buatan sendiri. Buka/tutup: RightShift atau tombol "VD".
-- Sesuaikan CFG dengan nama/tag/team di game kamu.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local CFG = {
	GeneratorTag = "Generator", GeneratorNames = {"generator"},
	GateTag = "Gate", GateNames = {"gate"},
	HookTag = "Hook", HookNames = {"hook"},
	KillerTeamName = "Killer",            -- nama Team killer
	RoleAttribute = "Role",               -- atau Attribute di Player: Role = "Killer"
	RoleKillerValue = "Killer",
	ProgressAttribute = "Progress",       -- Attribute progress generator (0-100)
	TerrorRadius = 48,                    -- studs
	ToggleKey = Enum.KeyCode.RightShift,
}

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() cam = workspace.CurrentCamera end)

local old = player:WaitForChild("PlayerGui"):FindFirstChild("VDLocal")
if old then old:Destroy() end

local BG, CARD, CARD2 = Color3.fromRGB(16, 15, 20), Color3.fromRGB(28, 26, 34), Color3.fromRGB(44, 40, 52)
local ACC, TXT, SUB = Color3.fromRGB(225, 60, 70), Color3.fromRGB(240, 238, 244), Color3.fromRGB(150, 145, 165)

local function mk(class, props)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	return o
end
local function round(o, r) mk("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = o}) end

local gui = mk("ScreenGui", {Name = "VDLocal", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 900, Parent = player.PlayerGui})

-- ================= DATA OBJEK =================
local lists = {gen = {}, gate = {}, hook = {}}
local function matches(inst, names)
	local n = inst.Name:lower()
	for _, p in ipairs(names) do
		if n:find(p, 1, true) then return true end
	end
	return false
end
local function collect(tag, names)
	local out = CollectionService:GetTagged(tag)
	if #out > 0 then return out end
	out = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if (d:IsA("Model") or d:IsA("BasePart")) and matches(d, names) then
			local par = d.Parent
			if not (par and par:IsA("Model") and matches(par, names)) then table.insert(out, d) end
		end
	end
	return out
end
local function refreshLists()
	lists.gen = collect(CFG.GeneratorTag, CFG.GeneratorNames)
	lists.gate = collect(CFG.GateTag, CFG.GateNames)
	lists.hook = collect(CFG.HookTag, CFG.HookNames)
end
local function anchorPart(inst)
	if inst:IsA("BasePart") then return inst end
	if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true) end
end
local function posOf(inst)
	if inst:IsA("Model") then return inst:GetPivot().Position end
	return inst.Position
end
local function getRoot() local c = player.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function isKiller(p)
	if p.Team and p.Team.Name == CFG.KillerTeamName then return true end
	if p:GetAttribute(CFG.RoleAttribute) == CFG.RoleKillerValue then return true end
	local c = p.Character
	return c ~= nil and c:GetAttribute(CFG.RoleAttribute) == CFG.RoleKillerValue
end

-- ================= PANEL =================
local panel = mk("Frame", {Size = UDim2.fromOffset(300, 400), Position = UDim2.new(0.5, -150, 0.5, -200), BackgroundColor3 = BG, Parent = gui})
round(panel, 12)
mk("UIStroke", {Color = ACC, Thickness = 1.5, Transparency = 0.2, Parent = panel})
mk("UIScale", {Scale = math.clamp(gui.AbsoluteSize.X / 460, 0.7, 1), Parent = panel})

local header = mk("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = CARD, Parent = panel})
round(header, 12)
mk("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = "VD LOCAL • analisis",
	TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
})

local scroll = mk("ScrollingFrame", {
	Size = UDim2.new(1, -12, 1, -44), Position = UDim2.fromOffset(6, 40), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 3, ScrollBarImageColor3 = ACC, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = panel,
})
mk("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll})

-- drag
do
	local dragging, startM, startP = false, Vector2.zero, panel.Position
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startM, startP = true, Vector2.new(i.Position.X, i.Position.Y), panel.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = Vector2.new(i.Position.X, i.Position.Y) - startM
			panel.Position = UDim2.new(startP.X.Scale, startP.X.Offset + d.X, startP.Y.Scale, startP.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

-- komponen
local function section(parent, text)
	mk("TextLabel", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = text:upper(), TextColor3 = SUB,
		Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent})
end
local function button(parent, text, cb)
	local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = CARD, Text = text, TextColor3 = TXT,
		Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, Parent = parent})
	round(b, 8)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = CARD2}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = CARD}):Play() end)
	b.MouseButton1Click:Connect(function() cb(b) end)
	return b
end
local function toggle(parent, text, cb)
	local on = false
	local b = button(parent, text, function() end)
	local function paint() b.TextColor3 = on and ACC or TXT b.Text = (on and "● " or "○ ") .. text end
	paint()
	b.MouseButton1Click:Connect(function()
		on = not on
		paint()
		cb(on)
	end)
	return b
end
local function slider(parent, text, min, max, def, cb)
	local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = CARD, Parent = parent})
	round(f, 8)
	local lbl = mk("TextLabel", {Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 2), BackgroundTransparency = 1,
		Text = text .. ": " .. def, TextColor3 = TXT, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = f})
	local bar = mk("TextButton", {Size = UDim2.new(1, -16, 0, 8), Position = UDim2.new(0, 8, 1, -16), BackgroundColor3 = CARD2, Text = "", AutoButtonColor = false, Parent = f})
	round(bar, 4)
	local fill = mk("Frame", {Size = UDim2.new((def - min) / (max - min), 0, 1, 0), BackgroundColor3 = ACC, Parent = bar})
	round(fill, 4)
	local dragging = false
	local function upd(x)
		local r = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local v = math.floor(min + (max - min) * r + 0.5)
		fill.Size = UDim2.new(r, 0, 1, 0)
		lbl.Text = text .. ": " .. v
		cb(v)
	end
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true upd(i.Position.X) end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

-- ================= OVERLAY OBJEKTIF =================
local tags, espOn = {}, false
local function clearTags()
	for _, t in ipairs(tags) do t.bb:Destroy() end
	tags = {}
end
local function makeTags()
	clearTags()
	if not espOn then return end
	local sets = {{lists.gen, "GEN", Color3.fromRGB(255, 200, 70)}, {lists.gate, "GATE", Color3.fromRGB(90, 220, 255)}, {lists.hook, "HOOK", Color3.fromRGB(255, 90, 90)}}
	for _, s in ipairs(sets) do
		for i, inst in ipairs(s[1]) do
			local a = anchorPart(inst)
			if a then
				local bb = mk("BillboardGui", {Size = UDim2.fromOffset(110, 34), AlwaysOnTop = true, StudsOffset = Vector3.new(0, 3, 0), Adornee = a, Parent = gui})
				local l = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextColor3 = s[3], Font = Enum.Font.GothamBold,
					TextSize = 12, TextStrokeTransparency = 0.4, Text = s[2], Parent = bb})
				table.insert(tags, {inst = inst, kind = s[2] .. " " .. i, label = l, bb = bb})
			end
		end
	end
end

-- ================= RADAR KILLER =================
local radarOn = false
local warn = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 20, 30), BackgroundTransparency = 1, ZIndex = 0, Visible = false, Parent = gui})
local warnLbl = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0.12, 0), BackgroundTransparency = 1, Text = "",
	TextColor3 = Color3.fromRGB(255, 90, 90), Font = Enum.Font.GothamBlack, TextSize = 20, TextStrokeTransparency = 0.3, Visible = false, Parent = gui})

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	local root = getRoot()
	if not root then return end
	local now = tick()

	if radarOn and not isKiller(player) then
		local best
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and isKiller(p) and p.Character then
				local r = p.Character:FindFirstChild("HumanoidRootPart")
				if r then
					local d = (r.Position - root.Position).Magnitude
					if not best or d < best then best = d end
				end
			end
		end
		if best and best <= CFG.TerrorRadius then
			local k = 1 - best / CFG.TerrorRadius
			warn.Visible, warnLbl.Visible = true, true
			warn.BackgroundTransparency = 1 - (0.08 + 0.22 * k) * (0.6 + 0.4 * math.sin(now * (4 + 8 * k)))
			warnLbl.Text = string.format("KILLER %dm", best)
		else
			warn.Visible, warnLbl.Visible = false, false
		end
	else
		warn.Visible, warnLbl.Visible = false, false
	end

	acc += dt
	if acc >= 0.25 and espOn then
		acc = 0
		for _, t in ipairs(tags) do
			if t.inst.Parent then
				local d = (posOf(t.inst) - root.Position).Magnitude
				local prog = t.inst:GetAttribute(CFG.ProgressAttribute)
				t.label.Text = t.kind .. (prog and (" " .. math.floor(prog) .. "%") or "") .. "\n" .. math.floor(d) .. "m"
			end
		end
	end
end)

-- ================= TELEPORT =================
local tpHolder
local function tpTo(pos)
	local r = getRoot()
	if r then r.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end
end
local function rebuildTP()
	for _, c in ipairs(tpHolder:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	refreshLists()
	for i, inst in ipairs(lists.gen) do button(tpHolder, "Generator " .. i, function() tpTo(posOf(inst)) end) end
	for i, inst in ipairs(lists.gate) do button(tpHolder, "Gate " .. i, function() tpTo(posOf(inst)) end) end
	for i, inst in ipairs(lists.hook) do button(tpHolder, "Hook " .. i, function() tpTo(posOf(inst)) end) end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			button(tpHolder, "Player: " .. p.DisplayName .. (isKiller(p) and " (killer)" or ""), function()
				local c = p.Character
				local r = c and c:FindFirstChild("HumanoidRootPart")
				if r then tpTo(r.Position) end
			end)
		end
	end
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then button(tpHolder, "Spawn", function() tpTo(spawn.Position) end) end
end

-- ================= GRAFIK =================
local function fx(class, name)
	local e = Lighting:FindFirstChild("VD_" .. name)
	if not e then e = Instance.new(class) e.Name = "VD_" .. name e.Parent = Lighting end
	return e
end
local function offFx()
	for _, n in ipairs({"Bloom", "Rays", "Color", "DoF", "Atmos"}) do
		local e = Lighting:FindFirstChild("VD_" .. n)
		if e then e:Destroy() end
	end
end
local presets = {
	Low = function()
		offFx()
		Lighting.GlobalShadows = false
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level02 end)
	end,
	Medium = function()
		offFx()
		Lighting.GlobalShadows = true
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level08 end)
		local c = fx("ColorCorrectionEffect", "Color")
		c.Contrast, c.Saturation = 0.05, 0.08
	end,
	High = function()
		offFx()
		Lighting.GlobalShadows = true
		Lighting.Brightness = 2
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level14 end)
		local b = fx("BloomEffect", "Bloom") b.Intensity, b.Size, b.Threshold = 0.5, 24, 1.8
		local r = fx("SunRaysEffect", "Rays") r.Intensity, r.Spread = 0.06, 0.6
		local c = fx("ColorCorrectionEffect", "Color") c.Contrast, c.Saturation = 0.1, 0.15
	end,
	Ultra = function()
		offFx()
		Lighting.GlobalShadows = true
		Lighting.Brightness = 2.4
		Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 1, 1
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level21 end)
		local b = fx("BloomEffect", "Bloom") b.Intensity, b.Size, b.Threshold = 0.7, 36, 1.6
		local r = fx("SunRaysEffect", "Rays") r.Intensity, r.Spread = 0.1, 0.8
		local c = fx("ColorCorrectionEffect", "Color") c.Contrast, c.Saturation, c.TintColor = 0.15, 0.2, Color3.fromRGB(255, 248, 240)
		local d = fx("DepthOfFieldEffect", "DoF") d.FarIntensity, d.FocusDistance, d.InFocusRadius, d.NearIntensity = 0.15, 60, 40, 0
		local a = fx("Atmosphere", "Atmos") a.Density, a.Haze, a.Color = 0.25, 1, Color3.fromRGB(190, 200, 215)
	end,
	Horror = function()
		offFx()
		Lighting.GlobalShadows = true
		Lighting.Brightness = 0.6
		Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(18, 18, 26), Color3.fromRGB(24, 24, 34)
		Lighting.ClockTime = 0
		local c = fx("ColorCorrectionEffect", "Color") c.Contrast, c.Saturation, c.Brightness, c.TintColor = 0.25, -0.25, -0.05, Color3.fromRGB(200, 210, 255)
		local a = fx("Atmosphere", "Atmos") a.Density, a.Haze, a.Color, a.Offset = 0.45, 2, Color3.fromRGB(70, 75, 95), 0.2
		local b = fx("BloomEffect", "Bloom") b.Intensity, b.Size, b.Threshold = 0.4, 20, 2
	end,
}

-- ================= SUSUN MENU =================
section(scroll, "Overlay analisis")
toggle(scroll, "Label Generator / Gate / Hook", function(on) espOn = on makeTags() end)
button(scroll, "Scan Ulang Objek", function()
	refreshLists()
	makeTags()
end)
toggle(scroll, "Radar Killer (peringatan jarak)", function(on) radarOn = on end)
slider(scroll, "Radius Terror (studs)", 15, 120, CFG.TerrorRadius, function(v) CFG.TerrorRadius = v end)

section(scroll, "Teleport")
button(scroll, "Muat / Refresh Daftar", rebuildTP)
tpHolder = mk("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = scroll})
mk("UIListLayout", {Padding = UDim.new(0, 4), Parent = tpHolder})

section(scroll, "Grafik")
for _, n in ipairs({"Low", "Medium", "High", "Ultra", "Horror"}) do
	button(scroll, "Preset " .. n, function() presets[n]() end)
end
toggle(scroll, "Bayangan (Shadows)", function(on) Lighting.GlobalShadows = on end)
slider(scroll, "Kecerahan", 0, 6, math.floor(Lighting.Brightness), function(v) Lighting.Brightness = v end)
slider(scroll, "Jam Dunia", 0, 24, math.floor(Lighting.ClockTime), function(v) Lighting.ClockTime = v end)
slider(scroll, "FOV", 40, 110, math.floor(cam.FieldOfView), function(v) cam.FieldOfView = v end)
button(scroll, "Matikan Semua Efek Grafik", offFx)

-- ================= BUKA / TUTUP =================
local bubble = mk("TextButton", {Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 10, 0.4, 0), BackgroundColor3 = CARD, Text = "VD",
	TextColor3 = ACC, Font = Enum.Font.GothamBlack, TextSize = 16, Parent = gui})
round(bubble, 22)
mk("UIStroke", {Color = ACC, Thickness = 1.5, Parent = bubble})
local function setOpen(o) panel.Visible = o end
bubble.MouseButton1Click:Connect(function() setOpen(not panel.Visible) end)
UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == CFG.ToggleKey then setOpen(not panel.Visible) end
end)

refreshLists()
rebuildTP()
