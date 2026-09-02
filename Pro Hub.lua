-- [[
	██████╗ ██╗   ██╗██╗     ███████╗███████╗██╗  ██╗██╗   ██╗██████╗ 
	██╔══██╗██║   ██║██║     ██╔════╝██╔════╝██║  ██║██║   ██║██╔══██╗
	██████╔╝██║   ██║██║     ███████╗█████╗  ███████║██║   ██║██████╔╝
	██╔═══╝ ██║   ██║██║     ╚════██║██╔══╝  ██╔══██║██║   ██║██╔═══╝ 
	██║     ╚██████╔╝███████╗███████║███████╗██║  ██║╚██████╔╝██║     
	╚═╝      ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     

	PulseHub v3.0.0 — универсальный хаб RIVALS / Arsenal / MM2
	UI: Nolin-UI v2.0 (собственная библиотека)
	Модули: Arsenal.lua / Rivals.lua / MM2.lua
]]

-- ============================================================
-- 1. КОНФИГУРАЦИЯ
-- ============================================================
local CONFIG = {
	-- ВНИМАНИЕ: Если вы переименуете репозиторий на GitHub, измените "Pro-Hub" в ссылках ниже на новое название!
	Urls = {
		NolinUI = "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/refs/heads/main/Nolin-UI.lua",
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
-- 3. NOLIN-UI ЗАГРУЗКА
-- ============================================================

-- Очищаем старый UI если он был запущен ранее
if _G.NolinUILoaded then
	pcall(function() _G.NolinUILoaded:Destroy() end)
end
if _G.NolinConns then
	for _, c in pairs(_G.NolinConns) do pcall(function() c:Disconnect() end) end
end
_G.NolinConns = {}

-- Загружаем библиотеку Nolin-UI
local NolinUI = loadstring(game:HttpGet(CONFIG.Urls.NolinUI))()
if not NolinUI then
	error("[PulseHub] Ошибка: Nolin-UI не загрузился!")
end

-- Создаём главное окно хаба
local Window = NolinUI:CreateWindow({
	Name = "PulseHub v" .. CONFIG.Version,
	LoadingText = "Загрузка PulseHub...",
	LoadingDuration = 2.0,
	KeybindToToggle = Enum.KeyCode.RightShift,
	SizeX = 600,
	SizeY = 440,
	IncludeSettings = false, -- Используем собственную вкладку настроек ниже
})

-- Экспортируем глобальные переменные для совместимости с модулями
_G.NolinUI = NolinUI
_G.NolinWindow = Window
_G.PulseUI = NolinUI
_G.PulseWindow = Window

-- Вспомогательная функция уведомлений
local function Notify(title, content, duration, ty)
	pcall(function()
		Window:Notify({ Title = title, Content = content, Duration = duration or 4, Type = ty or "Info" })
	end)
end

-- ============================================================
-- 4. ОПРЕДЕЛЕНИЕ ИГРЫ И УМНАЯ ЗАГРУЗКА МОДУЛЕЙ
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
		Notify("PulseHub", "Подождите, идёт загрузка...", 3, "Warning")
		return
	end
	if not url or url == "" then
		Notify("Ошибка", "Ссылка на модуль " .. gameName .. " не настроена", 6, "Error")
		return
	end
	
	Loading = true
	Notify("PulseHub", "Загрузка скрипта " .. gameName .. "...", 2, "Info")

	task.spawn(function()
		-- Загружаем исходный код скрипта из интернета
		local ok, result = pcall(function()
			return loadstring(game:HttpGet(url))
		end)
		
		if ok and type(result) == "function" then
			-- [ВАЖНО]: Полностью закрываем и уничтожаем окно PulseHub перед запуском скрипта игры!
			if Window then
				pcall(function() 
					Window:Destroy() 
				end)
			end
			
			-- Небольшая задержка, чтобы UI хаба успел красиво исчезнуть и очиститься из памяти
			task.wait(0.3)
			
			-- Запускаем скрипт игры (он создаст своё новое чистое окно)
			local runOk, runErr = pcall(result)
			if not runOk then
				warn("[PulseHub Error]: Ошибка при запуске модуля: " .. tostring(runErr))
			end
		else
			Notify("Ошибка", "Не удалось скачать " .. gameName .. ":\n" .. tostring(result), 8, "Error")
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
	Title = "PulseHub v" .. CONFIG.Version,
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
	Description = "Закроет PulseHub и запустит Arsenal Script",
	Callback = function() LoadModule(CONFIG.Urls.Arsenal, "Arsenal") end,
})

Tabs.Main:CreateButton({
	Name = "Загрузить RIVALS",
	Description = "Закроет PulseHub и запустит RIVALS Script",
	Callback = function() LoadModule(CONFIG.Urls.Rivals, "RIVALS") end,
})

Tabs.Main:CreateButton({
	Name = "Загрузить MM2",
	Description = "Закроет PulseHub и запустит MM2 Script",
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
	Description = "Полностью закрыть PulseHub",
	Callback = function()
		Notify("PulseHub", "Закрытие через 1.5 сек...", 1.5, "Warning")
		task.delay(1.5, function() Window:Destroy() end)
	end,
})

-- --- Настройки ---
Tabs.Settings:CreateSection({ Name = "Автозагрузка" })

Tabs.Settings:CreateToggle({
	Name = "Автозагрузка модуля при входе",
	Description = "Автоматически загружать модуль игры при старте",
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
	Title = "PulseHub",
	Content = "Универсальный хаб нового поколения.\nИспользует кастомную библиотеку Nolin-UI v2.0.",
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
			Notify("PulseHub", "Не в игре. Автозагрузка пропущена.", 6, "Warning")
		end
	end
end)
