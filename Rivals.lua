--[[
	RIVALS HUB v3.0.0 — модуль для RIVALS (PlaceId 17625359962)
	UI: Nolin-UI v2.0
	Функции: Aimbot, NoRecoil, ESP, Movement
]]

-- ============================================================
-- 1. КОНФИГУРАЦИЯ
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

local HasDrawing = Drawing ~= nil
if not HasDrawing then warn("[RIVALS Hub] Drawing API недоступен — ESP отключён.") end

-- ============================================================
-- 3. СОСТОЯНИЕ
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
	return Players:GetPlayerFromCharacter(result.Instance:FindFirstAncestorOfClass("Model")) ~= nil
end

-- ============================================================
-- 5. АИМБОТ
-- ============================================================
local Aimbot = {
	Enabled    = false,
	Mode       = "Legit",
	AimPart    = "Head",
	FOV        = 90,
	Smoothness = 10,
	TeamCheck  = false, -- FFA
	Wallbang   = false,
}

local function IsEnemy(plr)
	if not plr or plr == LocalPlayer then return false end
	if not GetCharacter(plr) then return false end
	if Aimbot.TeamCheck then return plr.Team ~= LocalPlayer.Team end
	return true
end

local function FindTarget()
	if not Aimbot.Enabled then return nil end
	local cam = Camera
	if not cam then return nil end
	if not GetRoot(LocalPlayer) then return nil end

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
		if not Aimbot.Wallbang and not IsVisible(cam.CFrame.Position, part.Position) then continue end
		if dist < bestScore then best, bestScore = plr, dist end
	end
	return best
end

local function GetTargetPart(plr)
	local char = GetCharacter(plr)
	if not char then return nil end
	if Aimbot.AimPart == "Head" then return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") end
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

-- Silent Aim через хук Modules.Utility.Raycast
local function SetupSilentAim()
	if not (hookfunction or newcclosure) then
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
					if Aimbot.Enabled and Aimbot.Mode == "Silent" and args[4] == 999 then
						local target = FindTarget()
						if target then
							local part = GetTargetPart(target)
							if part then return part, part.Position, Vector3.new(0,1,0), part.Material end
						end
					end
					return oldRay(unpack(args))
				end)
				table.insert(RestoreHooks, function() pcall(function() obj.Raycast = oldRay end) end)
				hooked = true
				break
			end
		end
	end
	if not hooked then warn("[RIVALS Hub] Modules.Utility.Raycast не найден — silent aim может не работать.") end
end

-- ============================================================
-- 6. NO RECOIL
-- ============================================================
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

task.spawn(function()
	while true do
		task.wait(3)
		if NoRecoil.Enabled and State.Loaded then pcall(ApplyNoRecoil) end
	end
end)

-- ============================================================
-- 7. ESP
-- ============================================================
local ESP = {
	Enabled = false, Boxes = true, Tracers = true,
	Names = true, HealthBar = true, Chams = true,
	MaxDistance = 400, Data = {},
}

local function MakeDrawing(kind)
	local ok, obj = pcall(Drawing.new, kind)
	return ok and obj or nil
end

local function SafeSet(obj, prop, val)
	if obj then pcall(function() obj[prop] = val end) end
end

local function EnsureESP(plr)
	if ESP.Data[plr] then return ESP.Data[plr] end
	local d = {}
	d.Box = MakeDrawing("Square")
	if d.Box then SafeSet(d.Box,"Thickness",1) SafeSet(d.Box,"Filled",false) SafeSet(d.Box,"Transparency",1) SafeSet(d.Box,"Visible",false) end
	d.Tracer = MakeDrawing("Line")
	if d.Tracer then SafeSet(d.Tracer,"Thickness",1) SafeSet(d.Tracer,"Transparency",1) SafeSet(d.Tracer,"Visible",false) end
	d.Name = MakeDrawing("Text")
	if d.Name then SafeSet(d.Name,"Size",13) SafeSet(d.Name,"Center",true) SafeSet(d.Name,"Outline",true) SafeSet(d.Name,"Transparency",1) SafeSet(d.Name,"Visible",false) end
	d.Health = MakeDrawing("Text")
	if d.Health then SafeSet(d.Health,"Size",11) SafeSet(d.Health,"Center",true) SafeSet(d.Health,"Outline",true) SafeSet(d.Health,"Transparency",1) SafeSet(d.Health,"Visible",false) end
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
	hl.OutlineColor = Color3.new(1,1,1)
	hl.OutlineTransparency = 0.2
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = char
	d.Highlight = hl
end

local function ClearAllChams()
	for _, d in pairs(ESP.Data) do
		if d.Highlight then pcall(function() d.Highlight:Destroy() end) d.Highlight = nil end
	end
end

local function CleanupESP(plr)
	local d = ESP.Data[plr]
	if not d then return end
	for _, drawing in pairs(d) do if type(drawing) == "userdata" then pcall(function() drawing:Remove() end) end end
	if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
	ESP.Data[plr] = nil
end

Connect(Players.PlayerAdded, function(plr)
	EnsureESP(plr)
	Connect(plr.CharacterAdded, function() if ESP.Enabled and ESP.Chams then ApplyCham(plr) end end)
	Connect(plr.CharacterRemoving, function()
		local d = ESP.Data[plr]
		if d and d.Highlight then pcall(function() d.Highlight:Destroy() end) d.Highlight = nil end
	end)
end)
Connect(Players.PlayerRemoving, function(plr) CleanupESP(plr) end)
for _, plr in ipairs(Players:GetPlayers()) do EnsureESP(plr) if plr.Character then ApplyCham(plr) end end

BindLoop(function()
	Camera = Camera or Workspace.CurrentCamera
	if not Camera then return end
	local myRoot = GetRoot(LocalPlayer)
	for plr, d in pairs(ESP.Data) do
		local show = ESP.Enabled and plr ~= LocalPlayer
		local char = GetCharacter(plr)
		if not show or not char then
			if d.Box then SafeSet(d.Box,"Visible",false) end
			if d.Tracer then SafeSet(d.Tracer,"Visible",false) end
			if d.Name then SafeSet(d.Name,"Visible",false) end
			if d.Health then SafeSet(d.Health,"Visible",false) end
			continue
		end
		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
		local head = char:FindFirstChild("Head")
		if not root or not head then continue end
		local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
		if dist > ESP.MaxDistance then
			if d.Box then SafeSet(d.Box,"Visible",false) end
			if d.Tracer then SafeSet(d.Tracer,"Visible",false) end
			if d.Name then SafeSet(d.Name,"Visible",false) end
			if d.Health then SafeSet(d.Health,"Visible",false) end
			continue
		end
		local headPos = Camera:WorldToScreenPoint(head.Position + Vector3.new(0,0.5,0))
		local rootPos = Camera:WorldToScreenPoint(root.Position - Vector3.new(0,1,0))
		if headPos.Z < 0 and rootPos.Z < 0 then continue end
		local color = Color3.fromRGB(255,80,80)
		local height = math.abs(rootPos.Y - headPos.Y)
		local width = math.max(30, height * 0.6)
		local pos = Vector2.new(headPos.X - width/2, headPos.Y)

		if ESP.Boxes and d.Box then SafeSet(d.Box,"Visible",true) SafeSet(d.Box,"Position",pos) SafeSet(d.Box,"Size",Vector2.new(width,height)) SafeSet(d.Box,"Color",color)
		elseif d.Box then SafeSet(d.Box,"Visible",false) end
		if ESP.Tracers and d.Tracer then SafeSet(d.Tracer,"Visible",true) SafeSet(d.Tracer,"From",Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)) SafeSet(d.Tracer,"To",Vector2.new(rootPos.X,rootPos.Y)) SafeSet(d.Tracer,"Color",color)
		elseif d.Tracer then SafeSet(d.Tracer,"Visible",false) end
		if ESP.Names and d.Name then SafeSet(d.Name,"Visible",true) SafeSet(d.Name,"Position",Vector2.new(headPos.X,headPos.Y-24)) SafeSet(d.Name,"Text",plr.Name.." ["..math.floor(dist).."m]") SafeSet(d.Name,"Color",Color3.new(1,1,1))
		elseif d.Name then SafeSet(d.Name,"Visible",false) end
		if ESP.HealthBar and d.Health then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				local hp = math.max(0, math.floor(hum.Health))
				local hpColor = hp > 50 and Color3.fromRGB(80,255,80) or (hp > 25 and Color3.fromRGB(255,200,50) or Color3.fromRGB(255,60,60))
				SafeSet(d.Health,"Visible",true) SafeSet(d.Health,"Position",Vector2.new(headPos.X,headPos.Y-8)) SafeSet(d.Health,"Text",tostring(hp)) SafeSet(d.Health,"Color",hpColor)
			end
		elseif d.Health then SafeSet(d.Health,"Visible",false) end
	end
end)

-- ============================================================
-- 8. ПЕРЕДВИЖЕНИЕ
-- ============================================================
local Movement = {
	WalkSpeedEnabled=false, WalkSpeed=16,
	JumpPowerEnabled=false, JumpPower=50,
	InfiniteJump=false,
	Fly=false, FlyBody=nil,
	Noclip=false, Fling=false,
}

BindLoop(function()
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if Movement.WalkSpeedEnabled then hum.WalkSpeed = Clamp(Movement.WalkSpeed,1,CONFIG.SafeWalkSpeed) end
	if Movement.JumpPowerEnabled then hum.JumpPower = Clamp(Movement.JumpPower,0,CONFIG.SafeJumpPower) end
end)

Connect(UserInputService.JumpRequest, function()
	if Movement.InfiniteJump then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

BindLoop(function()
	local root = GetRoot(LocalPlayer)
	if not root then return end
	if Movement.Fly then
		local bv = Movement.FlyBody
		if not bv then bv=Instance.new("BodyVelocity") bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.Parent=root Movement.FlyBody=bv end
		local cam = Camera
		if cam then
			local dir = cam.CFrame.LookVector
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then bv.Velocity=Vector3.new(0,50,0)
			elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then bv.Velocity=Vector3.new(0,-50,0)
			else bv.Velocity=dir*50 end
		end
	elseif Movement.FlyBody then pcall(function() Movement.FlyBody:Destroy() end) Movement.FlyBody=nil end
end)

BindLoop(function()
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = not Movement.Noclip end end
end)

BindLoop(function()
	local root = GetRoot(LocalPlayer)
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end
	if Movement.Fling then hum.AutoRotate=false root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(360)*5,0)
	else hum.AutoRotate=true end
end)

-- ============================================================
-- 9. NOLIN-UI
-- ============================================================
local IsStandalone = false
local NolinUI = _G.NolinUI
local Window = _G.NolinWindow

if not NolinUI or not Window then
	IsStandalone = true
	NolinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/youdeli1292-debug/Nolin-UI/refs/heads/main/NolinUI.lua"))()
	if not NolinUI then error("[RIVALS Hub] Nolin-UI не загрузился") end
	Window = NolinUI:CreateWindow({
		Name = "RIVALS Hub v" .. CONFIG.Version,
		LoadingText = "Загрузка RIVALS Hub...",
		LoadingDuration = 2.0,
		KeybindToToggle = Enum.KeyCode.RightShift,
		SizeX = 600, SizeY = 440,
		IncludeSettings = false,
	})
	_G.NolinUI = NolinUI
	_G.NolinWindow = Window
end

Notify = function(text, ty)
	pcall(function() Window:Notify({ Title = "RIVALS Hub", Content = text, Duration = 4, Type = ty or "Info" }) end)
	print("[RIVALS Hub] " .. text)
end

if IsStandalone then
	Window:Notify({ Title = "RIVALS Hub v"..CONFIG.Version, Content = "Модуль загружен!", Duration = 5, Type = "Success" })
end

local Tabs = {
	Combat   = Window:CreateTab({ Name = "Combat" }),
	Visuals  = Window:CreateTab({ Name = "Visuals" }),
	Movement = Window:CreateTab({ Name = "Movement" }),
	Main     = Window:CreateTab({ Name = "Главная" }),
}
local Window = NolinUI:CreateWindow({
    Name = "Nolin-UI v2.1 | interface settings",
    DiscordInvite = "https://discord.gg/gHx8RAb9c8",
    KeybindToToggle = Enum.KeyCode.RightShift,
    SizeX = 580,
    SizeY = 420,
    IncludeSettings = true, -- Добавляет автоматическую вкладку настроек
})
-- Combat
Tabs.Combat:CreateSection({ Name = "Aimbot" })

Tabs.Combat:CreateToggle({
	Name = "Aimbot",
	Default = false,
	Callback = function(v) Aimbot.Enabled = v Notify(v and "Aimbot ВКЛ" or "Aimbot ВЫКЛ") end,
})
Tabs.Combat:CreateDropdown({
	Name = "Режим аимбота",
	Options = { "Legit", "Blatant", "Silent" },
	Default = "Legit",
	Callback = function(v) Aimbot.Mode = v end,
})
Tabs.Combat:CreateDropdown({
	Name = "Часть тела",
	Options = { "Head", "Torso" },
	Default = "Head",
	Callback = function(v) Aimbot.AimPart = v end,
})
Tabs.Combat:CreateSlider({ Name = "FOV", Min=5, Max=180, Default=90, Increment=1, Suffix="°", Callback = function(v) Aimbot.FOV = v end })
Tabs.Combat:CreateSlider({ Name = "Smoothness", Min=1, Max=30, Default=10, Increment=1, Callback = function(v) Aimbot.Smoothness = v end })
Tabs.Combat:CreateToggle({ Name = "TeamCheck", Default = false, Callback = function(v) Aimbot.TeamCheck = v end })
Tabs.Combat:CreateToggle({ Name = "Wallbang", Default = false, Callback = function(v) Aimbot.Wallbang = v end })

Tabs.Combat:CreateSection({ Name = "Оружие" })
Tabs.Combat:CreateToggle({
	Name = "No Recoil / No Spread",
	Default = false,
	Callback = function(v) NoRecoil.Enabled = v Notify(v and "No Recoil ВКЛ" or "No Recoil ВЫКЛ") end,
})

-- Visuals
Tabs.Visuals:CreateSection({ Name = "ESP" })

Tabs.Visuals:CreateToggle({
	Name = "ESP (общий выключатель)",
	Default = false,
	Callback = function(v)
		ESP.Enabled = v
		if v and ESP.Chams then for _, p in ipairs(Players:GetPlayers()) do if p.Character then ApplyCham(p) end end
		elseif not v then ClearAllChams() end
	end,
})
Tabs.Visuals:CreateToggle({ Name = "Box ESP", Default=true, Callback=function(v) ESP.Boxes=v end })
Tabs.Visuals:CreateToggle({ Name = "Tracer ESP", Default=true, Callback=function(v) ESP.Tracers=v end })
Tabs.Visuals:CreateToggle({ Name = "Имя и дистанция", Default=true, Callback=function(v) ESP.Names=v end })
Tabs.Visuals:CreateToggle({ Name = "HealthBar", Default=true, Callback=function(v) ESP.HealthBar=v end })
Tabs.Visuals:CreateToggle({
	Name = "Wallhack (Chams)", Default=true,
	Callback = function(v)
		ESP.Chams = v
		if v and ESP.Enabled then for _, p in ipairs(Players:GetPlayers()) do if p.Character then ApplyCham(p) end end
		else ClearAllChams() end
	end,
})
Tabs.Visuals:CreateSlider({ Name = "MaxDistance", Min=50, Max=1000, Default=400, Increment=10, Suffix="m", Callback=function(v) ESP.MaxDistance=v end })

-- Movement
Tabs.Movement:CreateSection({ Name = "Скорость" })
Tabs.Movement:CreateToggle({ Name = "WalkSpeed", Default=false, Callback=function(v) Movement.WalkSpeedEnabled=v end })
Tabs.Movement:CreateSlider({ Name = "Скорость", Min=16, Max=250, Default=16, Increment=1, Callback=function(v) Movement.WalkSpeed=v end })
Tabs.Movement:CreateToggle({ Name = "JumpPower", Default=false, Callback=function(v) Movement.JumpPowerEnabled=v end })
Tabs.Movement:CreateSlider({ Name = "Высота прыжка", Min=50, Max=400, Default=50, Increment=5, Callback=function(v) Movement.JumpPower=v end })
Tabs.Movement:CreateToggle({ Name = "Бесконечный прыжок", Default=false, Callback=function(v) Movement.InfiniteJump=v end })
Tabs.Movement:CreateSection({ Name = "Продвинутое" })
Tabs.Movement:CreateToggle({ Name = "Fly", Default=false, Callback=function(v) Movement.Fly=v Notify(v and "Fly ВКЛ" or "Fly ВЫКЛ") end })
Tabs.Movement:CreateToggle({ Name = "Noclip", Default=false, Callback=function(v) Movement.Noclip=v end })
Tabs.Movement:CreateToggle({ Name = "Fling", Default=false, Callback=function(v) Movement.Fling=v end })

-- Главная
Tabs.Main:CreateSection({ Name = "Информация" })
Tabs.Main:CreateParagraph({
	Title = "RIVALS Hub v" .. CONFIG.Version,
	Content = "Модуль для RIVALS (PlaceId "..CONFIG.PlaceId..")\n"..
		"• Aimbot: Legit / Blatant / Silent\n"..
		"• No Recoil / No Spread\n"..
		"• ESP: Box / Tracer / Name / HealthBar / Chams\n"..
		"• Movement: WalkSpeed / JumpPower / Fly / Noclip / Fling\n"..
		"• UI: Nolin-UI v2.0",
})
Tabs.Main:CreateSection({ Name = "Управление" })
Tabs.Main:CreateButton({
	Name = "Выгрузить RIVALS Hub",
	Description = "Полностью выгрузить модуль",
	Callback = function() if Unload then Unload() end end,
})

-- ============================================================
-- 10. ХУКИ И ВЫГРУЗКА
-- ============================================================
SetupSilentAim()

Unload = function()
	Notify("Выгрузка...", "Warning")
	for _, con in ipairs(Connections) do pcall(function() con:Disconnect() end) end
	table.clear(Connections)
	for _, restore in ipairs(RestoreHooks) do pcall(restore) end
	table.clear(RestoreHooks)
	if HasDrawing then
		for _, d in pairs(ESP.Data) do
			for _, drawing in pairs(d) do if type(drawing)=="userdata" then pcall(function() drawing:Remove() end) end end
			if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
		end
		table.clear(ESP.Data)
	end
	if Movement.FlyBody then pcall(function() Movement.FlyBody:Destroy() end) end
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed=16 hum.JumpPower=50 hum.AutoRotate=true end
	if IsStandalone then pcall(function() Window:Destroy() end) end
	State.Loaded = false
end

pcall(function() if getgenv then getgenv().RivalsHub = { Unload = Unload, State = State } end end)
