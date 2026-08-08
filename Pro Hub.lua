--[[
	██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗
	██╔══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
	██████╔╝██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
	██═══╝ ██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔═══╝
	██║     ██║  ██║╚██████╝    ██║  ██║╚██████╔╝██║
	╚═╝     ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝

	PRO HUB v3.0.0 — универсальный хаб RIVALS / Arsenal / MM2
	UI: Nolin-UI v2.0 (собственная библиотека)
	Модули: Arsenal.lua / Rivals.lua / MM2.lua
]]

-- ============================================================
-- 1. КОНФИГУРАЦИЯ
-- ============================================================
local CONFIG = {
	Urls = {
		Arsenal = "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/refs/heads/main/Arsenal.lua",
		Rivals  = "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/refs/heads/main/Rivals.lua",
		MM2     = "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/refs/heads/main/MM2.lua",
	},
	PlaceIds = {
		Arsenal = 286090429,
		Rivals  = 17625359962,
		MM2     = 142823291,
	},
	Version      = "3.0.0",
	AutoLoad     = false,
	AutoLoadGame = "RIVALS",
}

-- ============================================================
-- 2. СЕРВИСЫ
-- ============================================================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 3. NOLIN-UI
-- ============================================================

-- Очищаем старый UI если был
if _G.NolinUILoaded then
	pcall(function() _G.NolinUILoaded:Destroy() end)
end
if _G.NolinConns then
	for _, c in pairs(_G.NolinConns) do pcall(function() c:Disconnect() end) end
end
_G.NolinConns = {}

-- Загружаем библиотеку Nolin-UI
local NolinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/refs/heads/main/Nolin-UI.lua"))()
if not NolinUI then
	error("[PRO HUB] Nolin-UI не загрузился")
end

-- Создаём окно
local Window = NolinUI:CreateWindow({
	Name = "PRO HUB v" .. CONFIG.Version,
	LoadingText = "Загрузка PRO HUB...",
	LoadingDuration = 2.0,
	KeybindToToggle = Enum.KeyCode.RightShift,
	SizeX = 600,
	SizeY = 440,
	IncludeSettings = false, -- своя вкладка настроек
})

-- Сохраняем в getgenv для модулей
_G.NolinUI = NolinUI
_G.NolinWindow = Window

-- Вспомогательная функция уведомлений
local function Notify(title, content, duration, ty)
	pcall(function()
		Window:Notify({ Title = title, Content = content, Duration = duration or 4, Type = ty or "Info" })
	end)
end

-- ============================================================
-- 4. ОПРЕДЕЛЕНИЕ ИГРЫ И ЗАГРУЗКА МОДУЛЕЙ
-- ============================================================
local function DetectGame()
	local id = game.PlaceId
	if id == CONFIG.PlaceIds.Arsenal then return "Arsenal" end
	if id == CONFIG.PlaceIds.Rivals  then return "RIVALS"  end
	if id == CONFIG.PlaceIds.MM2     then return "MM2"     end
	return "Неизвестная игра"
end

local Loading = false

local function LoadModule(url, gameName)
	if Loading then
		Notify("PRO HUB", "Подождите, идёт загрузка...", 3, "Warning")
		return
	end
	if not url or url == "" then
		Notify("Ошибка", "Ссылка на модуль " .. gameName .. " не настроена", 6, "Error")
		return
	end
	Loading = true
	task.spawn(function()
		local ok, result = pcall(function()
			return loadstring(game:HttpGet(url))
		end)
		if ok and type(result) == "function" then
			local runOk, runErr = pcall(result)
			if runOk then
				Notify(gameName, "Модуль загружен и запущен!", 5, "Success")
			else
				Notify("Ошибка", "Ошибка выполнения " .. gameName .. ":\n" .. tostring(runErr), 8, "Error")
			end
		else
			Notify("Ошибка", "Не удалось получить " .. gameName .. ":\n" .. tostring(result), 8, "Error")
		end
		Loading = false
	end)
end

local function TeleportTo(placeId)
	pcall(function() TeleportService:Teleport(placeId) end)
end

-- ============================================================
-- 5. ВКЛАДКИ И ИНТЕРФЕЙС
-- ============================================================
local Tabs = {
	Main     = Window:CreateTab({ Name = "Главная" }),
	Settings = Window:CreateTab({ Name = "Настройки" }),
}

-- --- Главная ---
Tabs.Main:CreateSection({ Name = "Информация" })
Tabs.Main:CreateParagraph({
	Title = "PRO HUB v" .. CONFIG.Version,
	Content = "Поддерживаемые игры:\n" ..
		"• Arsenal (PlaceId 286090429)\n" ..
		"• RIVALS (PlaceId 17625359962)\n" ..
		"• Murder Mystery 2 (PlaceId 142823291)\n\n" ..
		"Текущая игра: " .. DetectGame() .. "\n" ..
		"RightShift — скрыть/показать интерфейс",
})

Tabs.Main:CreateSection({ Name = "Загрузка модулей" })

Tabs.Main:CreateButton({
	Name = "Загрузить Arsenal",
	Description = "Aimbot / ESP / Movement",
	Callback = function() LoadModule(CONFIG.Urls.Arsenal, "Arsenal") end,
})

Tabs.Main:CreateButton({
	Name = "Загрузить RIVALS",
	Description = "Aimbot / NoRecoil / ESP / Movement",
	Callback = function() LoadModule(CONFIG.Urls.Rivals, "RIVALS") end,
})

Tabs.Main:CreateButton({
	Name = "Загрузить MM2",
	Description = "Role ESP / Coin Farm / Auto-Knife",
	Callback = function() LoadModule(CONFIG.Urls.MM2, "MM2") end,
})

Tabs.Main:CreateSection({ Name = "Переходы в игры" })

Tabs.Main:CreateButton({
	Name = "Перейти в Arsenal",
	Callback = function() TeleportTo(CONFIG.PlaceIds.Arsenal) end,
})
Tabs.Main:CreateButton({
	Name = "Перейти в RIVALS",
	Callback = function() TeleportTo(CONFIG.PlaceIds.Rivals) end,
})
Tabs.Main:CreateButton({
	Name = "Перейти в MM2",
	Callback = function() TeleportTo(CONFIG.PlaceIds.MM2) end,
})

Tabs.Main:CreateSection({ Name = "Управление" })

Tabs.Main:CreateButton({
	Name = "Выгрузить хаб (Unload)",
	Description = "Полностью закрыть PRO HUB",
	Callback = function()
		Notify("PRO HUB", "Закрытие через 1.5 сек...", 1.5, "Warning")
		task.delay(1.5, function() Window:Destroy() end)
	end,
})

-- --- Настройки ---
Tabs.Settings:CreateSection({ Name = "Автозагрузка" })

Tabs.Settings:CreateToggle({
	Name = "Автозагрузка модуля при входе",
	Description = "Автоматически грузить модуль при старте",
	Default = CONFIG.AutoLoad,
	Callback = function(Value) CONFIG.AutoLoad = Value end,
})

Tabs.Settings:CreateDropdown({
	Name = "Модуль для автозагрузки",
	Options = { "Arsenal", "RIVALS", "MM2" },
	Default = "RIVALS",
	Callback = function(Value) CONFIG.AutoLoadGame = Value end,
})

Tabs.Settings:CreateSection({ Name = "О хабе" })
Tabs.Settings:CreateParagraph({
	Title = "PRO HUB",
	Content = "Универсальный хаб для нескольких игр.\nИспользует Nolin-UI v2.0.",
})

-- ============================================================
-- 6. АВТОЗАГРУЗКА
-- ============================================================
task.spawn(function()
	task.wait(2)
	if CONFIG.AutoLoad then
		local gameName = DetectGame()
		local url
		if gameName == "Arsenal" then url = CONFIG.Urls.Arsenal
		elseif gameName == "RIVALS"  then url = CONFIG.Urls.Rivals
		elseif gameName == "MM2"     then url = CONFIG.Urls.MM2
		end
		if url then
			LoadModule(url, gameName)
		else
			Notify("PRO HUB", "Не в игре. Автозагрузка пропущена.", 6, "Warning")
		end
	end
end)
