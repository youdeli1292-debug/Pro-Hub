--[[
	██████╗ ██╗   ██╗ █████╗ ██╗     ███████╗
	██╔══██╗██║   ██║██╔══██╗██║     ██╔════╝
	██████╔╝██║   ██║███████║██║     ███████╗
	██╔══██╗██║   ██║██╔══██║██║     ╚════██║
	██║  ██║╚██████╔╝██║  ██║███████╗███████╗
	╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝

	RIVALS HUB v3.0.0 — модуль для RIVALS (PlaceId 17625359962, Nosniy Games)
	UI: Fluent (dawid-scripts)

	Функции:
	• Aimbot: Legit / Blatant / Silent (хук Modules.Utility.Raycast)
	  — Head/Torso, FOV, Smoothness, проверка видимости (НЕ бьёт сквозь
	    стены; Wallbang — отдельный тумблер), TeamCheck off (игра в осн. FFA)
	• No Recoil / No Spread (сканирование gc-таблиц: ShootSpread/Recoil/Cooldown)
	• ESP: Box / Tracer / Name&Distance / HealthBar / Chams, MaxDistance
	• Movement: WalkSpeed / JumpPower / Infinite Jump / Fly / Noclip / Fling
	• Unload с полной очисткой
]]

-- ============================================================
-- 1. КОНФИГУРАЦИЯ И ПРОВЕРКА ИГРЫ
-- ============================================================
local CONFIG = {
	PlaceId       = 17625359962,
	GameName      = "RIVALS",
	Version       = "3.0.0",
	SafeWalkSpeed = 250,
	SafeJumpPower = 400,
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
local Workspace        = game:GetService("Workspace")
local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera
local Mouse            = LocalPlayer:GetMouse()

local EXPLOIT = { Drawing = Drawing ~= nil }
if not EXPLOIT.Drawing then
	warn("[RIVALS Hub] Drawing API недоступен — ESP будет отключён.")
end

-- ============================================================
-- 3. СОСТОЯНИЕ, КОННЕКТЫ
-- ============================================================
local State = { Loaded = true }
local Connections = {}
local RestoreHooks = {}

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

local function IsVisible(origin, targetPos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	local result = Workspace:Raycast(origin, (targetPos - origin), params)
	if not result then return true end
	local hit = result.Instance
	if hit then
		return Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model")) ~= nil
	end
	return false
end

-- ============================================================
-- 5. АИМБОТ
-- ============================================================
local Aimbot = {
	Enabled    = false,
	Mode       = "Legit", -- Legit / Blatant / Silent
	AimPart    = "Head",
	FOV        = 90,
	Smoothness = 10,
	TeamCheck  = false, -- RIVALS в основном FFA — выключено по умолчанию
	Wallbang   = false,
	Target     = nil,
}

local function IsEnemy(plr)
	if not plr or plr == LocalPlayer then return false end
	local char = GetCharacter(plr)
	if not char then return false end
	if Aimbot.TeamCheck then
		return plr.Team ~= LocalPlayer.Team
	end
	return true
end

local function FindTarget()
	if not Aimbot.Enabled then return nil end
	local cam = Camera
	if not cam then return nil end
	local myRoot = GetRoot(LocalPlayer)
	if not myRoot then return nil end

	local best, bestScore = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if not IsEnemy(plr) then continue end
		local char = GetCharacter(plr)
		if not char then continue end
		local part = Aimbot.AimPart == "Head" and char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
		if not part then continue end

		local screenPos, onScreen = cam:WorldToScreenPoint(part.Position)
		if not onScreen then continue end

		local center = cam.ViewportSize / 2
		local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
		local fovPx = (Aimbot.FOV / 90) * cam.ViewportSize.Y / 2
		if dist > fovPx then continue end

		if not Aimbot.Wallbang then
			if not IsVisible(cam.CFrame.Position, part.Position) then continue end
		end

		if dist < bestScore then
			best, bestScore = plr, dist
		end
	end
	return best
end

local function GetTargetPart(plr)
	local char = GetCharacter(plr)
	if not char then return nil end
	if Aimbot.AimPart == "Head" then
		return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	end
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function SmoothLook(targetPos)
	local cam = Camera
	if not cam then return end
	local current = cam.CFrame
	local look = CFrame.lookAt(cam.CFrame.Position, targetPos)
	local alpha = Clamp(1 / Aimbot.Smoothness, 0.05, 1)
	cam.CFrame = current:Lerp(look, alpha)
end

BindLoop(function()
	if not Aimbot.Enabled then return end
	if Aimbot.Mode == "Silent" then return end
	local target = FindTarget()
	if not target then return end
	local part = GetTargetPart(target)
	if not part then return end
	SmoothLook(part.Position)
end)

-- ============================================================
-- 6. SILENT AIM (RIVALS): хук Modules.Utility.Raycast
-- ============================================================
-- RIVALS стреляет через функцию Raycast в таблице Modules.Utility.
-- Механика маркера: мы вызываем Raycast с 4-м аргументом 999 — это
-- наш сигнал. Хук перехватывает такой вызов и возвращает попадание
-- по цели (часть тела + позиция), даже если реальный луч никуда не
-- попал. Сервер считает, что игрок попал.
local function SetupSilentAim()
	local hookWorks = hookfunction and iscclosure or (newcclosure ~= nil)
	if not hookWorks then
		warn("[RIVALS Hub] hookfunction недоступен — silent aim отключён.")
		return
	end

	local hooked = false
	for _, obj in pairs(getgc(true)) do
		if type(obj) == "table" then
			local ray = rawget(obj, "Raycast")
			if type(ray) == "function" then
				local oldRay = ray
				obj.Raycast = newcclosure(function(...)
					local args = {...}
					-- 4-й аргумент 999 = маркер «мой» вызов
					if Aimbot.Enabled and Aimbot.Mode == "Silent" and args[4] == 999 then
						local target = FindTarget()
						if target then
							local part = GetTargetPart(target)
							if part then
								-- возвращаем вид «попадания»: (часть, позиция, нормаль, материал)
								return part, part.Position, Vector3.new(0, 1, 0), part.Material
							end
						end
					end
					return oldRay(unpack(args))
				end)
				table.insert(RestoreHooks, function()
					pcall(function() obj.Raycast = oldRay end)
				end)
				hooked = true
				break
			end
		end
	end
	if hooked then
		print("[RIVALS Hub] Silent aim хук установлен")
	else
		warn("[RIVALS Hub] Таблица Modules.Utility.Raycast не найдена — silent aim может не работать.")
	end
end

-- ============================================================
-- 7. NO RECOIL / NO SPREAD
-- ============================================================
-- Сканируем gc-таблицы на ключи разброса/отдачи и зануляем их.
-- Ключи в RIVALS: ShootSpread, ShootRecoil, ShootCooldown.
local NoRecoil = { Enabled = false }

local RECOIL_KEYS = { "ShootSpread", "Spread", "ShootRecoil", "Recoil", "ShootCooldown", "Cooldown" }

local function ApplyNoRecoil()
	if not NoRecoil.Enabled then return end
	for _, obj in pairs(getgc(true)) do
		if type(obj) == "table" then
			for _, key in ipairs(RECOIL_KEYS) do
				local v = rawget(obj, key)
				if v ~= nil and type(v) == "number" then
					pcall(function() rawset(obj, key, 0) end)
				end
			end
		end
	end
end

-- принудительное применение раз в 3 секунды (игра может перезаписывать)
task.spawn(function()
	while true do
		task.wait(3)
		if NoRecoil.Enabled and State.Loaded then
			pcall(ApplyNoRecoil)
		end
	end
end)

-- ============================================================
-- 8. ESP (устойчивая версия)
-- ============================================================
local ESP = {
	Enabled     = false,
	Boxes       = true,
	Tracers     = true,
	Names       = true,
	HealthBar   = true,
	Chams       = true,
	MaxDistance = 400,
	Data        = {},
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

	d.Health = MakeDrawing("Text")
	if d.Health then
		SafeSet(d.Health, "Size", 11)
		SafeSet(d.Health, "Center", true)
		SafeSet(d.Health, "Outline", true)
		SafeSet(d.Health, "Transparency", 1)
		SafeSet(d.Health, "Visible", false)
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
	hl.Name = "RivalsCham"
	hl.FillColor = Color3.fromRGB(255, 60, 60)
	hl.FillTransparency = 0.5
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
	Camera = Camera or Workspace.CurrentCamera
	if not Camera then return end
	local myRoot = GetRoot(LocalPlayer)
	for plr, d in pairs(ESP.Data) do
		local show = ESP.Enabled and plr ~= LocalPlayer
		local char = GetCharacter(plr)
		if not show or not char then
			if d.Box then SafeSet(d.Box, "Visible", false) end
			if d.Tracer then SafeSet(d.Tracer, "Visible", false) end
			if d.Name then SafeSet(d.Name, "Visible", false) end
			if d.Health then SafeSet(d.Health, "Visible", false) end
			continue
		end
		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
		local head = char:FindFirstChild("Head")
		if not root or not head then continue end

		local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
		if dist > ESP.MaxDistance then
			if d.Box then SafeSet(d.Box, "Visible", false) end
			if d.Tracer then SafeSet(d.Tracer, "Visible", false) end
			if d.Name then SafeSet(d.Name, "Visible", false) end
			if d.Health then SafeSet(d.Health, "Visible", false) end
			continue
		end

		local headPos = Camera:WorldToScreenPoint(head.Position + Vector3.new(0, 0.5, 0))
		local rootPos = Camera:WorldToScreenPoint(root.Position - Vector3.new(0, 1, 0))
		if headPos.Z < 0 and rootPos.Z < 0 then continue end

		local color = Color3.fromRGB(255, 80, 80)
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
			SafeSet(d.Name, "Text", ("%s  [%dm]"):format(plr.Name, math.floor(dist)))
			SafeSet(d.Name, "Color", Color3.new(1, 1, 1))
		elseif d.Name then
			SafeSet(d.Name, "Visible", false)
		end

		if ESP.HealthBar and d.Health then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				local hp = math.max(0, math.floor(hum.Health))
				local hpColor = hp > 50 and Color3.fromRGB(80, 255, 80) or (hp > 25 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 60, 60))
				SafeSet(d.Health, "Visible", true)
				SafeSet(d.Health, "Position", Vector2.new(headPos.X, headPos.Y - 8))
				SafeSet(d.Health, "Text", tostring(hp))
				SafeSet(d.Health, "Color", hpColor)
			end
		elseif d.Health then
			SafeSet(d.Health, "Visible", false)
		end
	end
end)

-- ============================================================
-- 9. ПЕРЕДВИЖЕНИЕ
-- ============================================================
local Movement = {
	WalkSpeedEnabled = false,
	WalkSpeed        = 16,
	JumpPowerEnabled = false,
	JumpPower        = 50,
	InfiniteJump     = false,
	Fly              = false,
	Noclip           = false,
	Fling            = false,
	FlyBody          = nil,
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

BindLoop(function()
	local char = LocalPlayer.Character
	local root = GetRoot(LocalPlayer)
	if not char or not root then return end

	if Movement.Fly then
		local bv = Movement.FlyBody
		if not bv then
			bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			bv.Parent = root
			Movement.FlyBody = bv
		end
		local cam = Camera
		if cam then
			local dir = cam.CFrame.LookVector
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				bv.Velocity = Vector3.new(0, 50, 0)
			elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				bv.Velocity = Vector3.new(0, -50, 0)
			else
				bv.Velocity = dir * 50
			end
		end
	elseif Movement.FlyBody then
		pcall(function() Movement.FlyBody:Destroy() end)
		Movement.FlyBody = nil
	end
end)

BindLoop(function()
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not Movement.Noclip
		end
	end
end)

BindLoop(function()
	local char = LocalPlayer.Character
	local root = GetRoot(LocalPlayer)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	if Movement.Fling then
		hum.AutoRotate = false
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(360) * 5, 0)
	else
		hum.AutoRotate = true
	end
end)

-- ============================================================
-- 10. UI — FLUENT
-- ============================================================
local Fluent = getgenv and getgenv().Fluent
if not Fluent then
	Fluent = loadstring(game:HttpGet(https://raw.githubusercontent.com/dawid-scripts/Fluent/refs/heads/master/Example.lua"))()
	if getgenv then getgenv().Fluent = Fluent end
end
if not Fluent then error("[RIVALS Hub] Fluent UI не загрузился") end

local Window = Fluent:CreateWindow({
	Title    = "RIVALS Hub v" .. CONFIG.Version,
	SubTitle = "RIVALS • PlaceId " .. CONFIG.PlaceId,
	TabWidth = 160,
	Size     = UDim2.fromOffset(580, 460),
	Acrylic  = true,
	Theme    = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})

Notify = function(text)
	pcall(function() Fluent:Notify({ Title = "RIVALS Hub", Content = text, Duration = 4 }) end)
	print("[RIVALS Hub] " .. text)
end

local Tabs = {
	Combat   = Window:AddTab({ Title = "Combat",   Icon = "swords" }),
	Visuals  = Window:AddTab({ Title = "Visuals",  Icon = "eye" }),
	Movement = Window:AddTab({ Title = "Movement", Icon = "bolt" }),
	Main     = Window:AddTab({ Title = "Главная",  Icon = "home" }),
}

-- --- Combat ---
Tabs.Combat:AddToggle("Riv_Aim_Enable", {
	Title = "Aimbot",
	Default = false,
	Callback = function(Value)
		Aimbot.Enabled = Value
		Notify(Value and "Aimbot ВКЛ" or "Aimbot ВЫКЛ")
	end,
})

Tabs.Combat:AddDropdown("Riv_Aim_Mode", {
	Title = "Режим аимбота",
	Values = { "Legit", "Blatant", "Silent" },
	Default = 1,
	Callback = function(Value) Aimbot.Mode = Value end,
})

Tabs.Combat:AddDropdown("Riv_Aim_Part", {
	Title = "Часть тела",
	Values = { "Head", "Torso" },
	Default = 1,
	Callback = function(Value) Aimbot.AimPart = Value end,
})

Tabs.Combat:AddSlider("Riv_Aim_FOV", {
	Title = "FOV",
	Default = 90,
	Min = 5,
	Max = 180,
	Rounding = 1,
	Callback = function(Value) Aimbot.FOV = Value end,
})

Tabs.Combat:AddSlider("Riv_Aim_Smooth", {
	Title = "Smoothness (плавность)",
	Default = 10,
	Min = 1,
	Max = 30,
	Rounding = 1,
	Callback = function(Value) Aimbot.Smoothness = Value end,
})

Tabs.Combat:AddToggle("Riv_Aim_TeamCheck", {
	Title = "TeamCheck (не бить тиммейтов)",
	Default = false, -- RIVALS в основном FFA
	Callback = function(Value) Aimbot.TeamCheck = Value end,
})

Tabs.Combat:AddToggle("Riv_Aim_Wallbang", {
	Title = "Wallbang (бить сквозь стены)",
	Default = false,
	Callback = function(Value) Aimbot.Wallbang = Value end,
})

Tabs.Combat:AddSection("Оружие")

Tabs.Combat:AddToggle("Riv_NoRecoil", {
	Title = "No Recoil / No Spread",
	Default = false,
	Callback = function(Value)
		NoRecoil.Enabled = Value
		Notify(Value and "No Recoil ВКЛ" or "No Recoil ВЫКЛ")
	end,
})

-- --- Visuals ---
Tabs.Visuals:AddToggle("Riv_Esp_Master", {
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

Tabs.Visuals:AddToggle("Riv_Esp_Boxes", {
	Title = "Box ESP",
	Default = true,
	Callback = function(Value) ESP.Boxes = Value end,
})

Tabs.Visuals:AddToggle("Riv_Esp_Tracers", {
	Title = "Tracer ESP",
	Default = true,
	Callback = function(Value) ESP.Tracers = Value end,
})

Tabs.Visuals:AddToggle("Riv_Esp_Names", {
	Title = "Имя и дистанция",
	Default = true,
	Callback = function(Value) ESP.Names = Value end,
})

Tabs.Visuals:AddToggle("Riv_Esp_Health", {
	Title = "HealthBar (здоровье)",
	Default = true,
	Callback = function(Value) ESP.HealthBar = Value end,
})

Tabs.Visuals:AddToggle("Riv_Esp_Chams", {
	Title = "Wallhack (Chams)",
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

Tabs.Visuals:AddSlider("Riv_Esp_MaxDist", {
	Title = "MaxDistance (дистанция ESP)",
	Default = 400,
	Min = 50,
	Max = 1000,
	Rounding = 10,
	Callback = function(Value) ESP.MaxDistance = Value end,
})

-- --- Movement ---
Tabs.Movement:AddToggle("Riv_Move_WS", {
	Title = "WalkSpeed (скорость)",
	Default = false,
	Callback = function(Value) Movement.WalkSpeedEnabled = Value end,
})
Tabs.Movement:AddSlider("Riv_Move_WSVal", {
	Title = "Скорость",
	Default = 16,
	Min = 16,
	Max = 250,
	Rounding = 1,
	Callback = function(Value) Movement.WalkSpeed = Value end,
})

Tabs.Movement:AddToggle("Riv_Move_JP", {
	Title = "JumpPower (прыжок)",
	Default = false,
	Callback = function(Value) Movement.JumpPowerEnabled = Value end,
})
Tabs.Movement:AddSlider("Riv_Move_JPVal", {
	Title = "Высота прыжка",
	Default = 50,
	Min = 50,
	Max = 400,
	Rounding = 5,
	Callback = function(Value) Movement.JumpPower = Value end,
})

Tabs.Movement:AddToggle("Riv_Move_InfJump", {
	Title = "Бесконечный прыжок",
	Default = false,
	Callback = function(Value) Movement.InfiniteJump = Value end,
})

Tabs.Movement:AddToggle("Riv_Move_Fly", {
	Title = "Fly (полёт)",
	Default = false,
	Callback = function(Value)
		Movement.Fly = Value
		Notify(Value and "Fly ВКЛ (SPACE вверх, LShift вниз)" or "Fly ВЫКЛ")
	end,
})

Tabs.Movement:AddToggle("Riv_Move_Noclip", {
	Title = "Noclip (проход сквозь стены)",
	Default = false,
	Callback = function(Value) Movement.Noclip = Value end,
})

Tabs.Movement:AddToggle("Riv_Move_Fling", {
	Title = "Fling (раскрутка)",
	Default = false,
	Callback = function(Value) Movement.Fling = Value end,
})

-- --- Главная ---
Tabs.Main:AddParagraph({
	Title = "RIVALS Hub v" .. CONFIG.Version,
	Content = "Модуль для RIVALS (PlaceId " .. CONFIG.PlaceId .. ")\n" ..
		"• Aimbot: Legit / Blatant / Silent (хук Modules.Utility.Raycast)\n" ..
		"• No Recoil / No Spread (сканирование gc)\n" ..
		"• ESP: Box / Tracer / Name&Distance / HealthBar / Chams\n" ..
		"• Movement: WalkSpeed / JumpPower / Fly / Noclip / Fling\n" ..
		"• UI: Fluent",
})

Tabs.Main:AddButton({
	Title = "Выгрузить скрипт (Unload)",
	Callback = function() Unload() end,
})

-- ============================================================
-- 11. УСТАНОВКА ХУКОВ
-- ============================================================
SetupSilentAim()

-- ============================================================
-- 12. ВЫГРУЗКА
-- ============================================================
Unload = function()
	Notify("Выгрузка...")

	-- 1. соединения
	for _, con in ipairs(Connections) do
		pcall(function() con:Disconnect() end)
	end
	table.clear(Connections)

	-- 2. восстановить хуки
	for _, restore in ipairs(RestoreHooks) do
		pcall(restore)
	end
	table.clear(RestoreHooks)

	-- 3. Drawing и Highlight
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

	-- 4. тело движения
	if Movement.FlyBody then pcall(function() Movement.FlyBody:Destroy() end) end
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16
		hum.JumpPower = 50
		hum.AutoRotate = true
	end

	-- 5. UI
	pcall(function() Window:Destroy() end)

	State.Loaded = false
end

-- экспорт для хаба
pcall(function()
	getgenv().RivalsHub = { Unload = Unload, State = State }
end)
