-- [[
-- 	██████╗ ██╗   ██╗██╗     ███████╗███████╗██╗  ██╗██╗   ██╗██████╗ 
-- 	██╔══██╗██║   ██║██║     ██╔════╝██╔════╝██║  ██║██║   ██║██╔══██╗
-- 	██████╔╝██║   ██║██║     ███████╗█████╗  ███████║██║   ██║██████╔╝
-- 	██╔═══╝ ██║   ██║██║     ╚════██║██╔══╝  ██╔══██║██║   ██║██╔═══╝ 
-- 	██║     ╚██████╔╝███████╗███████║███████╗██║  ██║╚██████╔╝██║     
-- 	╚═╝      ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     
-- 
-- 	PulseHub v3.0.0 — универсальный хаб RIVALS / Arsenal / MM2
-- 	UI: Nolin-UI v2.0
-- ]]

-- ============================================================
-- 1. КОНФИГУРАЦИЯ
-- ============================================================
local CONFIG = {
	Urls = {
		NolinUI = "https://raw.githubusercontent.com/youdeli1292-debug/Nolin-UI/main/NolinUI.lua",
		Arsenal = "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/main/Arsenal.lua",
		Rivals  = "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/main/Rivals.lua",
		MM2     = "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/main/MM2.lua",
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
-- 3. БЕЗОПАСНАЯ ЗАГРУЗКА NOLIN-UI
-- ============================================================

-- Очищаем предыдущие соединения и интерфейс, если они есть
if _G.NolinUILoaded then
	pcall(function() _G.NolinUILoaded:Destroy() end)
end
if _G.NolinConns then
	for _, c in pairs(_G.NolinConns) do 
		pcall(function() c:Disconnect() end) 
	end
end
_G.NolinConns = {}

-- Скачивание и инициализация библиотеки UI
local uiFetchSuccess, uiSource = pcall(function()
	return game:HttpGet(CONFIG.Urls.NolinUI)
end)

if not uiFetchSuccess or not uiSource or uiSource == "" then
	warn("[PulseHub] Ошибка: Не удалось скачать Nolin-UI. Проверьте доступность URL.")
	return
end

local uiLoadSuccess, NolinUIModule = pcall(loadstring(uiSource))
if not uiLoadSuccess or not NolinUIModule then
	warn("[PulseHub] Ошибка: Nolin-UI не смог скомпилироваться или запуститься: " .. tostring(NolinUIModule))
	return
end

local NolinUI = NolinUIModule

-- Создаём главное окно хаба
local Window
local winSuccess, winErr = pcall(function()
	return NolinUI:CreateWindow({
		Name = "PulseHub v" .. CONFIG.Version,
		LoadingText = "Загрузка PulseHub...",
		LoadingDuration = 1.5,
		KeybindToToggle = Enum.KeyCode.RightShift,
		SizeX = 600,
		SizeY = 440,
		IncludeSettings = false,
	})
end)

if not winSuccess or not Window then
	Window = winErr -- В случае если CreateWindow возвращает объект напрямую
end

-- Глобальные переменные
_G.NolinUI = NolinUI
_G.NolinWindow = Window
_G.PulseUI = NolinUI
_G.PulseWindow = Window

-- Вспомогательная функция уведомлений
local function Notify(title, content, duration, ty)
	pcall(function()
		if Window and Window.Notify then
			Window:Notify({ Title = title, Content = content, Duration = duration or 4, Type = ty or "Info" })
		end
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
		-- 1. Скачиваем скрипт ДО удаления интерфейса (чтобы убедиться, что он доступен)
		local fetchOk, scriptSource = pcall(function()
			return game:HttpGet(url)
		end)

		if not fetchOk or not scriptSource or scriptSource == "" then
			Notify("Ошибка", "Не удалось скачать " .. gameName .. " (404/ошибка сети)", 6, "Error")
			Loading = false
			return
		end

		local parseOk, executableFunc = pcall(loadstring, scriptSource)
		if not parseOk or type(executableFunc) ~= "function" then
			Notify("Ошибка", "Ошибка в коде " .. gameName .. ":\n" .. tostring(executableFunc), 6, "Error")
			Loading = false
			return
		end

		-- 2. ПОЛНАЯ ОЧИСТКА ХАБА
		-- Отключаем все бинды и коннекты самого хаба
		if _G.NolinConns then
			for _, conn in pairs(_G.NolinConns) do
				pcall(function() conn:Disconnect() end)
			end
			_G.NolinConns = nil
		end

		-- Уничтожаем само окно
		if Window and Window.Destroy then
			pcall(function() Window:Destroy() end)
		end

		-- СБРАСЫВАЕМ глобальные переменные, чтобы MM2 создал всё с чистого листа
		_G.NolinUILoaded = nil
		_G.NolinUI = nil
		_G.NolinWindow = nil
		_G.PulseUI = nil
		_G.PulseWindow = nil

		-- Даем движку Roblox время (0.5 сек) на отключение KeyCode-событий в UserInputService
		task.wait(0.5)

		-- 3. Запускаем MM2
		local runOk, runErr = pcall(executableFunc)
		if not runOk then
			warn("[PulseHub Error]: Ошибка при исполнении модуля: " .. tostring(runErr))
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
		"• Arsenal (PlaceId " .. CONFIG.PlaceIds.Arsenal .. ")\n" ..
		"• RIVALS (PlaceId " .. CONFIG.PlaceIds.Rivals .. ")\n" ..
		"• Murder Mystery 2 (PlaceId " .. CONFIG.PlaceIds.MM2 .. ")\n\n" ..
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
		Notify("PulseHub", "Закрытие через 1 сек...", 1, "Warning")
		task.delay(1, function() 
			if Window and Window.Destroy then
				Window:Destroy() 
			end
		end)
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
	Content = "Универсальный хаб.\nИспользует библиотеку Nolin-UI.",
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
