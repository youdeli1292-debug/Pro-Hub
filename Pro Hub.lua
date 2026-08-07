--[[
	██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗
	██╔══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
	██████╔╝██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
	██╔═══╝ ██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔═══╝
	██║     ██║  ██║╚██████╔╝    ██║  ██║╚██████╔╝██║
	╚═╝     ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝

	PRO HUB v3.0.0 — универсальный хаб RIVALS / Arsenal / MM2
	UI: Fluent (dawid-scripts) вместо Rayfield.

	Механика: хаб определяет игру и через loadstring подгружает модуль
	(Arsenal.lua / Rivals.lua / MM2.lua). Модули работают и автономно.

	⚠ ССЫЛКИ В CONFIG.Urls — ПЛЕЙСХОЛДЕРЫ: замени на свой новый хостинг
	  (GitHub-аккаунт снесли, старые raw-ссылки мертвы).
]]

-- ============================================================
-- 1. КОНФИГУРАЦИЯ
-- ============================================================
local CONFIG = {
	Urls = {
		Arsenal = "https://YOUR_NEW_HOST/Arsenal.lua", -- ← заменить
		Rivals  = "https://YOUR_NEW_HOST/Rivals.lua",  -- ← заменить
		MM2     = "https://YOUR_NEW_HOST/MM2.lua",     -- ← заменить
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
-- 3. FLUENT UI (защита от двойной загрузки)
-- ============================================================
local Fluent = getgenv and getgenv().Fluent
if not Fluent then
	Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/refs/heads/master/Example.lua"))()
	if getgenv then getgenv().Fluent = Fluent end
end
if not Fluent then
	error("[PRO HUB] Fluent UI не загрузился.")
end

local Window = Fluent:CreateWindow({
	Title    = "PRO HUB v" .. CONFIG.Version,
	SubTitle = "RIVALS / Arsenal / MM2",
	TabWidth = 160,
	Size     = UDim2.fromOffset(580, 460),
	Acrylic  = true,
	Theme    = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})

local function Notify(title, content, duration)
	pcall(function()
		Fluent:Notify({ Title = title, Content = content, Duration = duration or 5 })
	end)
end

local Tabs = {
	Main     = Window:AddTab({ Title = "Главная",   Icon = "home" }),
	Settings = Window:AddTab({ Title = "Настройки", Icon = "settings" }),
}

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

local function GetUrlForGame(gameName)
	if gameName == "Arsenal" then return CONFIG.Urls.Arsenal end
	if gameName == "RIVALS"  then return CONFIG.Urls.Rivals  end
	if gameName == "MM2"     then return CONFIG.Urls.MM2     end
	return nil
end

local Loading = false

local function LoadModule(url, gameName)
	if Loading then
		Notify("PRO HUB", "Подождите, идёт загрузка...", 3)
		return
	end
	if not url or url == "" or url:find("YOUR_NEW_HOST") then
		Notify("Ошибка", "Ссылка на модуль " .. gameName .. " не настроена. Замени YOUR_NEW_HOST в CONFIG.Urls.", 8)
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
				Notify(gameName, "Модуль загружен и запущен!", 5)
			else
				Notify("Ошибка", "Ошибка выполнения модуля " .. gameName .. ":\n" .. tostring(runErr), 8)
			end
		else
			Notify("Ошибка", "Не удалось получить модуль " .. gameName .. ":\n" .. tostring(result), 8)
		end
		Loading = false
	end)
end

local function TeleportTo(placeId)
	pcall(function() TeleportService:Teleport(placeId) end)
end

-- ============================================================
-- 5. ИНТЕРФЕЙС
-- ============================================================
Tabs.Main:AddParagraph({
	Title = "PRO HUB — RIVALS / Arsenal / MM2",
	Content = "Версия " .. CONFIG.Version .. "\n" ..
		"Поддерживаемые игры:\n" ..
		"• Arsenal (PlaceId 286090429)\n" ..
		"• RIVALS (PlaceId 17625359962)\n" ..
		"• Murder Mystery 2 (PlaceId 142823291)\n\n" ..
		"Текущая игра: " .. DetectGame(),
})

Tabs.Main:AddButton({
	Title = "Загрузить модуль ARSENAL",
	Callback = function() LoadModule(CONFIG.Urls.Arsenal, "Arsenal") end,
})

Tabs.Main:AddButton({
	Title = "Загрузить модуль RIVALS",
	Callback = function() LoadModule(CONFIG.Urls.Rivals, "RIVALS") end,
})

Tabs.Main:AddButton({
	Title = "Загрузить модуль MM2 (Murder Mystery 2)",
	Callback = function() LoadModule(CONFIG.Urls.MM2, "MM2") end,
})

Tabs.Main:AddSection("Переходы в игры")

Tabs.Main:AddButton({
	Title = "Перейти в Arsenal",
	Callback = function() TeleportTo(CONFIG.PlaceIds.Arsenal) end,
})
Tabs.Main:AddButton({
	Title = "Перейти в RIVALS",
	Callback = function() TeleportTo(CONFIG.PlaceIds.Rivals) end,
})
Tabs.Main:AddButton({
	Title = "Перейти в MM2",
	Callback = function() TeleportTo(CONFIG.PlaceIds.MM2) end,
})

Tabs.Main:AddSection("Управление")

Tabs.Main:AddButton({
	Title = "Выгрузить хаб (Unload)",
	Callback = function()
		Notify("PRO HUB", "Хаб выгружается...", 3)
		task.wait(0.5)
		pcall(function() Window:Destroy() end)
	end,
})

-- --- Настройки ---
Tabs.Settings:AddToggle("ProHub_AutoLoad", {
	Title = "Автозагрузка модуля при входе в игру",
	Default = CONFIG.AutoLoad,
	Callback = function(Value) CONFIG.AutoLoad = Value end,
})

Tabs.Settings:AddDropdown("ProHub_AutoLoadGame", {
	Title = "Модуль для автозагрузки",
	Values = { "Arsenal", "RIVALS", "MM2" },
	Default = 2, -- индекс: 1=Arsenal, 2=RIVALS, 3=MM2
	Callback = function(Value) CONFIG.AutoLoadGame = Value end,
})

Tabs.Settings:AddParagraph({
	Title = "Как настроить ссылки",
	Content = "Ссылки на модули лежат в CONFIG.Urls в начале файла.\n" ..
		"Нужен чистый raw-текст кода (не страница).\n" ..
		"Файлы модулей: Arsenal.lua, Rivals.lua, MM2.lua.\n\n" ..
		"Сейчас ссылки — заглушки YOUR_NEW_HOST. Замени их на свой\n" ..
		"новый хостинг (новый GitHub / rentry / pastebin).",
})

-- ============================================================
-- 6. АВТОЗАГРУЗКА И АНТИ-АФК
-- ============================================================
task.spawn(function()
	task.wait(2)
	if CONFIG.AutoLoad then
		local gameName = DetectGame()
		local url = GetUrlForGame(gameName)
		if url then
			LoadModule(url, gameName)
		else
			Notify("PRO HUB", "Не в игре. Автозагрузка пропущена.", 6)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(60 * 10)
		pcall(function()
			game:GetService("VirtualUser"):CaptureController()
			game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0))
			task.wait(1)
			game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0))
		end)
	end
end)
