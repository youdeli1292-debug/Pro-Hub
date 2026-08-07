--[[
██████╗ ██████╗  ██████╗     ██╗  ██╗██╗   ██╗██████╗
██╔══██╗██╔══██╗██╔═══██╗    ██║  ██║██║   ██║██╔══██╗
██████╔╝██████╔╝██║   ██║    ███████║██║   ██║██████╔╝
██╔═══╝ ██╔══██╗██║   ██║    ██╔══██║██║   ██║██╔═══╝
██║     ██║  ██║╚██████╔╝    ██║  ██║╚██████╔╝██║
╚═╝     ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝

PRO HUB v3.0.0
Fluent UI Edition
RIVALS / Arsenal / MM2
]]

--============================================================
-- 1. ЗАЩИТА ОТ ДВОЙНОГО ЗАПУСКА
--============================================================

if getgenv and getgenv().PRO_HUB_LOADED then
    warn("[PRO HUB] Already loaded")
    return
end

if getgenv then
    getgenv().PRO_HUB_LOADED = true
end


--============================================================
-- 2. CONFIG
--============================================================

local CONFIG = {

    Version = "3.0.0",

    Urls = {

        Arsenal =
        "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/main/Arsenal.lua",

        Rivals =
        "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/main/Rivals.lua",

        MM2 =
        "https://raw.githubusercontent.com/youdeli1292-debug/Pro-Hub/main/MM2.lua"

    },


    PlaceIds = {

        Arsenal = 286090429,

        Rivals = 17625359962,

        MM2 = 142823291

    },


    Settings = {

        AutoLoad = false,

        AutoLoadGame = "Rivals"

    }

}


--============================================================
-- 3. SERVICES
--============================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer



--============================================================
-- 4. FLUENT UI LOAD
--============================================================

local Fluent = nil


if getgenv then
    Fluent = getgenv().Fluent
end


if not Fluent then

    local success, result = pcall(function()

        return loadstring(
            game:HttpGet(
                "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"
            )
        )()

    end)


    if success then
        Fluent = result
    end

end


if not Fluent then

    error(
        "[PRO HUB] Fluent не загрузился. Проверь ссылку библиотеки."
    )

end



if getgenv then
    getgenv().Fluent = Fluent
end



--============================================================
-- 5. WINDOW
--============================================================

local Window = Fluent:CreateWindow({

    Title = "PRO HUB v"..CONFIG.Version,

    SubTitle = "RIVALS / Arsenal / MM2",

    TabWidth = 160,

    Size = UDim2.fromOffset(600,500),

    Acrylic = true,

    Theme = "Dark",

    MinimizeKey = Enum.KeyCode.LeftControl

})



--============================================================
-- 6. NOTIFY
--============================================================

local function Notify(title,text,time)

    pcall(function()

        Fluent:Notify({

            Title = title,

            Content = text,

            Duration = time or 5

        })

    end)

end



--============================================================
-- 7. GAME DETECT
--============================================================


local function DetectGame()

    local id = game.PlaceId


    if id == CONFIG.PlaceIds.Arsenal then

        return "Arsenal"

    elseif id == CONFIG.PlaceIds.Rivals then

        return "Rivals"

    elseif id == CONFIG.PlaceIds.MM2 then

        return "MM2"

    end


    return "Unknown"

end




local function GetGameURL(name)


    if name == "Arsenal" then

        return CONFIG.Urls.Arsenal


    elseif name == "Rivals" then

        return CONFIG.Urls.Rivals


    elseif name == "MM2" then

        return CONFIG.Urls.MM2


    end


end




--============================================================
-- 8. MODULE LOADER
--============================================================


local LoadingModule = false



local function LoadModule(name)


    if LoadingModule then

        Notify(
            "PRO HUB",
            "Модуль уже загружается...",
            3
        )

        return

    end



    local url = GetGameURL(name)



    if not url then

        Notify(
            "Ошибка",
            "URL не найден",
            5
        )

        return

    end



    LoadingModule = true



    task.spawn(function()


        local success, result = pcall(function()


            local code = game:HttpGet(url)


            local func = loadstring(code)


            if func then

                func()

            else

                error("loadstring failed")

            end


        end)



        if success then


            Notify(

                name,

                "Модуль успешно загружен",

                5

            )


        else


            Notify(

                "Ошибка "..name,

                tostring(result),

                10

            )


        end



        LoadingModule = false


    end)

end



--============================================================
-- 9. TELEPORT
--============================================================


local function Teleport(place)


    pcall(function()

        TeleportService:Teleport(place)

    end)


end
--============================================================
-- 10. TABS
--============================================================


local Tabs = {}


Tabs.Main = Window:AddTab({

    Title = "Главная",

    Icon = "home"

})


Tabs.Arsenal = Window:AddTab({

    Title = "Arsenal",

    Icon = "crosshair"

})


Tabs.Rivals = Window:AddTab({

    Title = "Rivals",

    Icon = "swords"

})


Tabs.MM2 = Window:AddTab({

    Title = "MM2",

    Icon = "skull"

})


Tabs.Settings = Window:AddTab({

    Title = "Настройки",

    Icon = "settings"

})



--============================================================
-- 11. MAIN TAB
--============================================================


Tabs.Main:AddParagraph({

    Title = "PRO HUB v"..CONFIG.Version,

    Content =

    "Универсальный хаб\n\n" ..

    "Поддержка:\n" ..

    "• Arsenal\n" ..

    "• RIVALS\n" ..

    "• Murder Mystery 2\n\n" ..

    "Текущая игра: "..DetectGame()

})



Tabs.Main:AddButton({

    Title = "Авто-загрузить текущую игру",

    Callback = function()


        local gameName = DetectGame()


        if gameName == "Unknown" then


            Notify(

                "PRO HUB",

                "Игра не определена",

                5

            )


            return

        end



        LoadModule(gameName)


    end

})



Tabs.Main:AddSection("Телепорт")



Tabs.Main:AddButton({

    Title = "Перейти Arsenal",

    Callback = function()

        Teleport(CONFIG.PlaceIds.Arsenal)

    end

})



Tabs.Main:AddButton({

    Title = "Перейти Rivals",

    Callback = function()

        Teleport(CONFIG.PlaceIds.Rivals)

    end

})


Tabs.Main:AddButton({

    Title = "Перейти MM2",

    Callback = function()

        Teleport(CONFIG.PlaceIds.MM2)

    end

})




--============================================================
-- 12. ARSENAL TAB
--============================================================


Tabs.Arsenal:AddParagraph({

    Title = "Arsenal",

    Content =

    "Модуль Arsenal.lua\n" ..

    "Загрузка через PRO HUB"

})



Tabs.Arsenal:AddButton({

    Title = "Запустить Arsenal",

    Callback = function()

        LoadModule("Arsenal")

    end

})




--============================================================
-- 13. RIVALS TAB
--============================================================


Tabs.Rivals:AddParagraph({

    Title = "RIVALS",

    Content =

    "Модуль Rivals.lua\n" ..

    "Загрузка через PRO HUB"

})



Tabs.Rivals:AddButton({

    Title = "Запустить RIVALS",

    Callback = function()

        LoadModule("Rivals")

    end

})




--============================================================
-- 14. MM2 TAB
--============================================================


Tabs.MM2:AddParagraph({

    Title = "Murder Mystery 2",

    Content =

    "Модуль MM2.lua\n" ..

    "Загрузка через PRO HUB"

})



Tabs.MM2:AddButton({

    Title = "Запустить MM2",

    Callback = function()

        LoadModule("MM2")

    end

})




--============================================================
-- 15. SETTINGS
--============================================================


Tabs.Settings:AddToggle(
"AutoLoad",
{

    Title = "Автозагрузка модуля",

    Default = CONFIG.Settings.AutoLoad,


    Callback = function(Value)

        CONFIG.Settings.AutoLoad = Value

    end

})



Tabs.Settings:AddDropdown(

"AutoGame",

{

    Title = "Игра для автозагрузки",

    Values = {

        "Arsenal",

        "Rivals",

        "MM2"

    },


    Default = 2,


    Callback = function(Value)

        CONFIG.Settings.AutoLoadGame = Value

    end

})




Tabs.Settings:AddButton({

    Title = "Выгрузить PRO HUB",

    Callback = function()


        Notify(

            "PRO HUB",

            "Выгрузка...",

            3

        )


        task.wait(1)



        pcall(function()

            Window:Destroy()

        end)



        if getgenv then

            getgenv().PRO_HUB_LOADED = nil

        end


    end

})




--============================================================
-- 16. AUTO LOAD
--============================================================


task.spawn(function()


    task.wait(3)



    if CONFIG.Settings.AutoLoad then


        local current = DetectGame()



        if current ~= "Unknown" then


            LoadModule(current)


        end


    end


end)



--============================================================
-- 17. START MESSAGE
--============================================================


Notify(

    "PRO HUB",

    "Запущен успешно v"..CONFIG.Version,

    5

)
