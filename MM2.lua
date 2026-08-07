--[[
	MM2 HUB v3.0.0 — Murder Mystery 2 (PlaceId 142823291)
	UI: Fluent (dawid-scripts) вместо Rayfield
	Функции: Role Revealer ESP, авто-фарм монет,
	авто-подбор пистолета, авто-удар ножом, передвижение.
	Требования: Drawing API, Fluent UI, стандартные функции экзекутора.
]]

-- ============================================================
-- 1. КОНФИГУРАЦИЯ
-- ============================================================
local CONFIG = {
	PlaceId       = 142823291,
	GameName      = "MM2",
	Version       = "3.0.0",
	SafeWalkSpeed = 150,
	SafeJumpPower = 300,
}

if game.PlaceId ~= CONFIG.PlaceId then
	warn(("[%s] Внимание: модуль запущен не в %s (PlaceId: %d)"):format(CONFIG.GameName, CONFIG.GameName, game.PlaceId))
end

-- ============================================================
-- 2. СЕРВИСЫ
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local EXPLOIT = { Drawing = Drawing ~= nil }
if not EXPLOIT.Drawing then
	warn("[MM2 Hub] Drawing API недоступен — ESP будет отключён.")
end

-- ============================================================
-- 3. СОСТОЯНИЕ, КОННЕКТЫ (и вперёд-объявления)
-- ============================================================
local State = { Loaded = true }
local Connections = {}

local function Connect(signal, func)
	local con = signal:Connect(func)
	table.insert(Connections, con)
	return con
end

local function BindLoop(func)
	local con = RunService.RenderStepped:Connect(func)
	table.insert(Connections, con)
	return con
end

-- ВПЕРЁД-ОБЪЯВЛЕНИЯ: Notify и Unload заполняются позже (после Fluent),
-- но ссылаться на них должны функции, определённые раньше.
local Notify
local Unload

-- ============================================================
-- 4. УТИЛИТЫ
-- ============================================================
local function Clamp(v, min, max)
	return math.max(min, math.min(max, v))
end

local function GetCharacter(plr)
	if not plr then return nil end
	local char = plr.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	return char
end

local function GetRoot(plr)
	local char = GetCharacter(plr)
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
end

-- ============================================================
-- 5. РАСКРЫТИЕ РОЛЕЙ
-- ============================================================
local ROLE = {
	MURDERER = "Убийца",
	SHERIFF  = "Шериф",
	INNOCENT = "Мирный",
}
local ROLE_COLOR = {
	[ROLE.MURDERER] = Color3.fromRGB(255, 40, 40),
	[ROLE.SHERIFF]  = Color3.fromRGB(40, 120, 255),
	[ROLE.INNOCENT] = Color3.fromRGB(40, 255, 100),
}

local function GetPlayerRole(plr)
	local function scan(container)
		if not container then return nil end
		if container:FindFirstChild("Knife") then return ROLE.MURDERER end
		if container:FindFirstChild("Gun")   then return ROLE.SHERIFF end
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") then
				local n = tool.Name:lower()
				if n:find("knife") or n:find("blade") then return ROLE.MURDERER end
				if n:find("gun") or n:find("pistol") or n:find("revolver") then return ROLE.SHERIFF end
			end
		end
		return nil
	end
	local role = scan(plr.Character)
	if role then return role end
	role = scan(plr.Backpack)
	if role then return role end
	return ROLE.INNOCENT
end

local function IsMurderer(plr) return GetPlayerRole(plr) == ROLE.MURDERER end

-- ============================================================
-- 6. ESP (устойчивая версия — без Drawing.Fonts, всё в pcall)
-- ============================================================
local ESP = {
	Enabled = false,
	Boxes   = true,
	Tracers = true,
	Names   = true,
	Roles   = true,
	Chams   = true,
	Data    = {},
}

local function MakeDrawing(kind)
	local ok, obj = pcall(Drawing.new, kind)
	if ok and obj then return obj end
	return nil
end

local function SafeSet(obj, prop, val)
	if not obj then return end
	pcall(function() obj[prop] = val end)
end

local function EnsureESP(plr)
	if ESP.Data[plr] then return ESP.Data[plr] end
	local d = {}

	d.Box = MakeDrawing("Square")
	if d.Box then
		SafeSet(d.Box, "Thickness", 1)
		SafeSet(d.Box, "Filled", false)
		SafeSet(d.Box, "Transparency", 1)
		SafeSet(d.Box, "Visible", false)
	end

	d.Tracer = MakeDrawing("Line")
	if d.Tracer then
		SafeSet(d.Tracer, "Thickness", 1)
		SafeSet(d.Tracer, "Transparency", 1)
		SafeSet(d.Tracer, "Visible", false)
	end

	d.Name = MakeDrawing("Text")
	if d.Name then
		SafeSet(d.Name, "Size", 13)
		SafeSet(d.Name, "Center", true)
		SafeSet(d.Name, "Outline", true)
		SafeSet(d.Name, "Transparency", 1)
		SafeSet(d.Name, "Visible", false)
	end

	d.Role = MakeDrawing("Text")
	if d.Role then
		SafeSet(d.Role, "Size", 15)
		SafeSet(d.Role, "Center", true)
		SafeSet(d.Role, "Outline", true)
		SafeSet(d.Role, "Transparency", 1)
		SafeSet(d.Role, "Visible", false)
	end

	d.Highlight = nil
	ESP.Data[plr] = d
	return d
end

local function ApplyCham(plr)
	local char = GetCharacter(plr)
	if not char then return end
	local d = EnsureESP(plr)
	if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
	local hl = Instance.new("Highlight")
	hl.Name = "MM2Cham"
	hl.FillColor = ROLE_COLOR[GetPlayerRole(plr)] or Color3.new(1, 1, 1)
	hl.FillTransparency = 0.45
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.OutlineTransparency = 0.2
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = char
	d.Highlight = hl
end

local function ClearAllChams()
	for plr, d in pairs(ESP.Data) do
		if d.Highlight then
			pcall(function() d.Highlight:Destroy() end)
			d.Highlight = nil
		end
	end
end

local function CleanupESP(plr)
	local d = ESP.Data[plr]
	if not d then return end
	for _, drawing in pairs(d) do
		if type(drawing) == "userdata" then
			pcall(function() drawing:Remove() end)
		end
	end
	if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
	ESP.Data[plr] = nil
end

Connect(Players.PlayerAdded, function(plr)
	EnsureESP(plr)
	Connect(plr.CharacterAdded, function()
		if ESP.Enabled and ESP.Chams then ApplyCham(plr) end
	end)
	Connect(plr.CharacterRemoving, function()
		local d = ESP.Data[plr]
		if d and d.Highlight then
			pcall(function() d.Highlight:Destroy() end)
			d.Highlight = nil
		end
	end)
end)
Connect(Players.PlayerRemoving, function(plr) CleanupESP(plr) end)

for _, plr in ipairs(Players:GetPlayers()) do
	EnsureESP(plr)
	if plr.Character then ApplyCham(plr) end
end

BindLoop(function()
	Camera = Camera or workspace.CurrentCamera
	if not Camera then return end
	for plr, d in pairs(ESP.Data) do
		local show = ESP.Enabled and plr ~= LocalPlayer
		local char = GetCharacter(plr)
		if not show or not char then
			if d.Box then SafeSet(d.Box, "Visible", false) end
			if d.Tracer then SafeSet(d.Tracer, "Visible", false) end
			if d.Name then SafeSet(d.Name, "Visible", false) end
			if d.Role then SafeSet(d.Role, "Visible", false) end
			continue
		end
		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
		local head = char:FindFirstChild("Head")
		if not root or not head then continue end

		local headPos = Camera:WorldToScreenPoint(head.Position + Vector3.new(0, 0.5, 0))
		local rootPos = Camera:WorldToScreenPoint(root.Position - Vector3.new(0, 1, 0))
		if headPos.Z < 0 and rootPos.Z < 0 then continue end

		local role = GetPlayerRole(plr)
		local color = ROLE_COLOR[role] or Color3.new(1, 1, 1)
		local height = math.abs(rootPos.Y - headPos.Y)
		local width = math.max(30, height * 0.6)
		local pos = Vector2.new(headPos.X - width / 2, headPos.Y)

		if ESP.Boxes and d.Box then
			SafeSet(d.Box, "Visible", true)
			SafeSet(d.Box, "Position", pos)
			SafeSet(d.Box, "Size", Vector2.new(width, height))
			SafeSet(d.Box, "Color", color)
		elseif d.Box then
			SafeSet(d.Box, "Visible", false)
		end

		if ESP.Tracers and d.Tracer then
			SafeSet(d.Tracer, "Visible", true)
			SafeSet(d.Tracer, "From", Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y))
			SafeSet(d.Tracer, "To", Vector2.new(rootPos.X, rootPos.Y))
			SafeSet(d.Tracer, "Color", color)
		elseif d.Tracer then
			SafeSet(d.Tracer, "Visible", false)
		end

		if ESP.Names and d.Name then
			SafeSet(d.Name, "Visible", true)
			SafeSet(d.Name, "Position", Vector2.new(headPos.X, headPos.Y - 24))
			SafeSet(d.Name, "Text", plr.Name)
			SafeSet(d.Name, "Color", Color3.new(1, 1, 1))
		elseif d.Name then
			SafeSet(d.Name, "Visible", false)
		end

		if ESP.Roles and d.Role then
			SafeSet(d.Role, "Visible", true)
			SafeSet(d.Role, "Position", Vector2.new(headPos.X, headPos.Y - 4))
			SafeSet(d.Role, "Text", role)
			SafeSet(d.Role, "Color", color)
		elseif d.Role then
			SafeSet(d.Role, "Visible", false)
		end
	end
end)

-- ============================================================
-- 7. АВТО-ФАРМ МОНЕТ
-- ============================================================
local CoinFarm = {
	Enabled      = false,
	OnlyInnocent = true,
	PickupRange  = 12,
	TeleportGap  = 0.35,
}

local coinCache = {}
local lastCoinScan = 0

local function GetCoins()
	local now = os.clock()
	if now - lastCoinScan < 0.5 then return coinCache end
	lastCoinScan = now
	table.clear(coinCache)
	local function scan(folder)
		if not folder then return end
		for _, v in ipairs(folder:GetChildren()) do
			if v:IsA("BasePart") and v.Name:lower():find("coin") then
				table.insert(coinCache, v)
			elseif v:IsA("Folder") or v:IsA("Model") then
				scan(v)
			end
		end
	end
	scan(workspace)
	return coinCache
end

local function GetNearestCoin()
	local root = GetRoot(LocalPlayer)
	if not root then return nil end
	local best, bestDist = nil, math.huge
	for _, coin in ipairs(GetCoins()) do
		local dist = (coin.Position - root.Position).Magnitude
		if dist < bestDist then
			best, bestDist = coin, dist
		end
	end
	return best
end

BindLoop(function()
	if not CoinFarm.Enabled then return end
	local root = GetRoot(LocalPlayer)
	if not root then return end
	if CoinFarm.OnlyInnocent and GetPlayerRole(LocalPlayer) ~= ROLE.INNOCENT then return end
	local coin = GetNearestCoin()
	if not coin then return end
	if (coin.Position - root.Position).Magnitude > CoinFarm.PickupRange then
		root.CFrame = coin.CFrame * CFrame.new(0, 2, 0)
		task.wait(CoinFarm.TeleportGap)
	end
end)

-- ============================================================
-- 8. АВТО-ПОДБОР ПИСТОЛЕТА ШЕРИФА
-- ============================================================
local GunPickup = { Enabled = false, Interval = 1.0 }

local function GetDroppedGun()
	for _, tool in ipairs(workspace:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("gun") then return tool end
	end
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("Tool") and desc.Name:lower():find("gun") and desc.Parent and desc.Parent:IsA("BasePart") then
			return desc
		end
	end
	return nil
end

local function TryPickupGun()
	local root = GetRoot(LocalPlayer)
	if not root then return end
	local gun = GetDroppedGun()
	if not gun then return end
	local gunPart = gun:IsA("BasePart") and gun or (gun.PrimaryPart or gun:FindFirstChildOfClass("BasePart"))
	if not gunPart then return end
	if (gunPart.Position - root.Position).Magnitude > 15 then
		root.CFrame = gunPart.CFrame * CFrame.new(0, 2, 0)
		task.wait(0.25)
	end
	if gun.Parent == LocalPlayer.Character or gun.Parent == LocalPlayer.Backpack then
		Notify("Пистолет шерифа подобран!")
	end
end

local lastGunCheck = 0
BindLoop(function()
	if not GunPickup.Enabled then return end
	local now = os.clock()
	if now - lastGunCheck < GunPickup.Interval then return end
	lastGunCheck = now
	pcall(TryPickupGun)
end)

-- ============================================================
-- 9. АВТО-АТАКА НОЖОМ
-- ============================================================
local AutoKnife = {
	Enabled  = false,
	Range    = 10,
	Teleport = true,
}

local function GetKnifeTool()
	local char = LocalPlayer.Character
	if char then
		local tool = char:FindFirstChild("Knife")
		if tool then return tool end
	end
	return LocalPlayer.Backpack:FindFirstChild("Knife")
end

local function GetNearestVictim()
	if GetPlayerRole(LocalPlayer) ~= ROLE.MURDERER then return nil end
	local root = GetRoot(LocalPlayer)
	if not root then return nil end
	local best, bestDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == LocalPlayer then continue end
		local char = GetCharacter(plr)
		if not char then continue end
		if IsMurderer(plr) then continue end
		local tRoot = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
		if not tRoot then continue end
		local dist = (tRoot.Position - root.Position).Magnitude
		if dist < bestDist then
			best, bestDist = plr, dist
		end
	end
	return best, bestDist
end

BindLoop(function()
	if not AutoKnife.Enabled then return end
	local target, dist = GetNearestVictim()
	if not target then return end
	local knife = GetKnifeTool()
	if not knife then return end
	local root = GetRoot(LocalPlayer)
	local tRoot = GetRoot(target)
	if not root or not tRoot then return end

	if dist > AutoKnife.Range then
		if AutoKnife.Teleport then
			root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2)
		end
	else
		pcall(function()
			if knife.Parent ~= LocalPlayer.Character then
				knife.Parent = LocalPlayer.Character
			end
			knife:Activate()
		end)
		task.wait(0.35)
	end
end)

-- ============================================================
-- 10. ПЕРЕДВИЖЕНИЕ
-- ============================================================
local Movement = {
	WalkSpeedEnabled = false,
	WalkSpeed        = 16,
	JumpPowerEnabled = false,
	JumpPower        = 50,
	InfiniteJump     = false,
}

BindLoop(function()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if Movement.WalkSpeedEnabled then
		hum.WalkSpeed = Clamp(Movement.WalkSpeed, 1, CONFIG.SafeWalkSpeed)
	end
	if Movement.JumpPowerEnabled then
		hum.JumpPower = Clamp(Movement.JumpPower, 0, CONFIG.SafeJumpPower)
	end
end)

Connect(UserInputService.JumpRequest, function()
	if Movement.InfiniteJump then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- ============================================================
-- 11. UI — FLUENT
-- ============================================================
local Fluent = getgenv and getgenv().Fluent
if not Fluent then
	Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
	if getgenv then getgenv().Fluent = Fluent end
end
if not Fluent then error("[MM2 Hub] Fluent UI не загрузился") end

local Window = Fluent:CreateWindow({
	Title    = "MM2 Hub v" .. CONFIG.Version,
	SubTitle = "Murder Mystery 2 • PlaceId " .. CONFIG.PlaceId,
	TabWidth = 160,
	Size     = UDim2.fromOffset(560, 480),
	Acrylic  = true,
	Theme    = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})

Notify = function(text)
	pcall(function() Fluent:Notify({ Title = "MM2 Hub", Content = text, Duration = 4 }) end)
	print("[MM2 Hub] " .. text)
end

local Tabs = {
	Main = Window:AddTab({ Title = "Главная",   Icon = "home" }),
	Esp  = Window:AddTab({ Title = "ESP / Роли", Icon = "eye" }),
	Farm = Window:AddTab({ Title = "Фарм",      Icon = "coins" }),
	Atk  = Window:AddTab({ Title = "Атака",     Icon = "swords" }),
	Move = Window:AddTab({ Title = "Передвижение", Icon = "bolt" }),
}

-- Главная
Tabs.Main:AddParagraph({
	Title = "MM2 Hub v" .. CONFIG.Version,
	Content = "Модуль для Murder Mystery 2 (PlaceId " .. CONFIG.PlaceId .. ")\n" ..
		"• ESP ролей: Убийца (красный), Шериф (синий), Мирный (зелёный)\n" ..
		"• Авто-фарм монет • авто-подбор пистолета • авто-удар ножом\n" ..
		"• UI: Fluent",
})

Tabs.Main:AddButton({
	Title = "Выгрузить скрипт (Unload)",
	Callback = function() Unload() end,
})

-- ESP
Tabs.Esp:AddToggle("MM2_ESP_Master", {
	Title = "ESP (общий выключатель)",
	Default = false,
	Callback = function(Value)
		ESP.Enabled = Value
		if Value and ESP.Chams then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Character then ApplyCham(plr) end
			end
		elseif not Value then
			ClearAllChams()
		end
	end,
})

Tabs.Esp:AddToggle("MM2_ESP_Roles", {
	Title = "Роли над головами",
	Default = true,
	Callback = function(Value) ESP.Roles = Value end,
})

Tabs.Esp:AddToggle("MM2_ESP_Boxes", {
	Title = "Box ESP (рамки цветом роли)",
	Default = true,
	Callback = function(Value) ESP.Boxes = Value end,
})

Tabs.Esp:AddToggle("MM2_ESP_Tracers", {
	Title = "Tracer ESP (линии)",
	Default = true,
	Callback = function(Value) ESP.Tracers = Value end,
})

Tabs.Esp:AddToggle("MM2_ESP_Names", {
	Title = "Имена игроков",
	Default = true,
	Callback = function(Value) ESP.Names = Value end,
})

Tabs.Esp:AddToggle("MM2_ESP_Chams", {
	Title = "Wallhack (Chams цветом роли)",
	Default = true,
	Callback = function(Value)
		ESP.Chams = Value
		if Value and ESP.Enabled then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Character then ApplyCham(plr) end
			end
		else
			ClearAllChams()
		end
	end,
})

-- Фарм
Tabs.Farm:AddToggle("MM2_Farm_Coins", {
	Title = "Авто-фарм монет",
	Default = false,
	Callback = function(Value)
		CoinFarm.Enabled = Value
		Notify(Value and "Фарм монет ВКЛ" or "Фарм монет ВЫКЛ")
	end,
})

Tabs.Farm:AddToggle("MM2_Farm_OnlyInnocent", {
	Title = "Только когда я Мирный",
	Default = true,
	Callback = function(Value) CoinFarm.OnlyInnocent = Value end,
})

Tabs.Farm:AddSlider("MM2_Farm_Range", {
	Title = "Дистанция подбора",
	Default = 12,
	Min = 5,
	Max = 25,
	Rounding = 0,
	Callback = function(Value) CoinFarm.PickupRange = Value end,
})

Tabs.Farm:AddSlider("MM2_Farm_Gap", {
	Title = "Задержка телепорта (мс)",
	Default = 35,
	Min = 10,
	Max = 100,
	Rounding = 0,
	Callback = function(Value) CoinFarm.TeleportGap = Value / 100 end,
})

Tabs.Farm:AddSection("Оружие")

Tabs.Farm:AddToggle("MM2_Farm_GunPickup", {
	Title = "Авто-подбор пистолета шерифа",
	Default = false,
	Callback = function(Value) GunPickup.Enabled = Value end,
})

-- Атака
Tabs.Atk:AddToggle("MM2_Atk_Knife", {
	Title = "Авто-удар ножом (если я Убийца)",
	Default = false,
	Callback = function(Value) AutoKnife.Enabled = Value end,
})

Tabs.Atk:AddToggle("MM2_Atk_Teleport", {
	Title = "Телепорт к цели (иначе бег)",
	Default = true,
	Callback = function(Value) AutoKnife.Teleport = Value end,
})

Tabs.Atk:AddSlider("MM2_Atk_Range", {
	Title = "Дистанция удара",
	Default = 10,
	Min = 4,
	Max = 20,
	Rounding = 0,
	Callback = function(Value) AutoKnife.Range = Value end,
})

-- Передвижение
Tabs.Move:AddToggle("MM2_Move_WS", {
	Title = "WalkSpeed (скорость)",
	Default = false,
	Callback = function(Value) Movement.WalkSpeedEnabled = Value end,
})

Tabs.Move:AddSlider("MM2_Move_WSVal", {
	Title = "Скорость",
	Default = 16,
	Min = 16,
	Max = 150,
	Rounding = 0,
	Callback = function(Value) Movement.WalkSpeed = Value end,
})

Tabs.Move:AddToggle("MM2_Move_JP", {
	Title = "JumpPower (прыжок)",
	Default = false,
	Callback = function(Value) Movement.JumpPowerEnabled = Value end,
})

Tabs.Move:AddSlider("MM2_Move_JPVal", {
	Title = "Высота прыжка",
	Default = 50,
	Min = 50,
	Max = 300,
	Rounding = 0,
	Callback = function(Value) Movement.JumpPower = Value end,
})

Tabs.Move:AddToggle("MM2_Move_InfJump", {
	Title = "Бесконечный прыжок",
	Default = false,
	Callback = function(Value) Movement.InfiniteJump = Value end,
})

-- ============================================================
-- 12. ВЫГРУЗКА
-- ============================================================
Unload = function()
	Notify("Выгрузка...")

	-- 1. все соединения
	for _, con in ipairs(Connections) do
		pcall(function() con:Disconnect() end)
	end
	table.clear(Connections)

	-- 2. все Drawing и Highlight
	if EXPLOIT.Drawing then
		for plr, d in pairs(ESP.Data) do
			for _, drawing in pairs(d) do
				if type(drawing) == "userdata" then
					pcall(function() drawing:Remove() end)
				end
			end
			if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
		end
		table.clear(ESP.Data)
	end

	-- 3. восстановить персонажа
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16
		hum.JumpPower = 50
	end

	-- 4. UI
	pcall(function() Window:Destroy() end)

	State.Loaded = false
end

-- экспорт для хаба
pcall(function()
	getgenv().MM2Hub = { Unload = Unload, State = State }
end)
