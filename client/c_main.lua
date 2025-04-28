lib.locale()
local config = require "config.shared"
local hasLobby = false
local currentLobby = nil
local currentProps = {}
local hasPassed = false

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    TriggerEvent("speedway:client:destroyprops")
end)

RegisterNetEvent('speedway:client:destroyprops')
AddEventHandler('speedway:client:destroyprops', function()
    for _, obj in ipairs(currentProps) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end

    currentProps = {}
    
end)


RegisterNetEvent('speedway:setLobbyState', function(state)
    hasLobby = state
end)

RegisterNetEvent("speedway:updateLobbyInfo", function(data)
    currentLobby = data
end)

CreateThread(function()
    local cfg = config.LobbyPed
    local model = cfg.model
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(0, model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.coords.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'create_lobby',
            label = locale('create_lobby'),
            icon = 'fa-solid fa-flag-checkered',
            onSelect = function()
                local infolobby = lib.inputDialog(locale("create_lobby"), {
                    {
                        type = "number",
                        label = locale("number_of_laps"),
                        description = locale("number_of_laps_desc"),
                        min = 1,
                        max = 10,
                        default = 3,
                        required = true
                    },
                    {
                        type = "select",
                        label = locale("type_race"),
                        options = {
                            { label = locale('Short_Track'), value = "Short_Track" },
                            { label = locale('Drift_Track'), value = "Drift_Track" },
                            { label = locale('Speed_Track'), value = "Speed_Track" },
                            { label = locale('Long_Track'),  value = "Long_Track" }
                        },
                        required = true,
                        default = "Short_Track"
                    }
                })
            
                if infolobby and infolobby[1] and infolobby[2] then
                    local trackType = infolobby[2]
                    local lapCount = tonumber(infolobby[1])
                    local playerName = GetPlayerName(PlayerId())
                    local lobbyName = playerName .. "_" .. math.random(1000, 9999)
            
                    TriggerServerEvent("speedway:createLobby", lobbyName, trackType, lapCount)
                else
                    lib.notify({
                        title = "Speedway",
                        description = locale("error_input"),
                        type = "error"
                    })
                end
            end,
            canInteract = function()
                return currentLobby == nil
            end
            
        },
        {
            name = 'join_lobby',
            label = locale('join_lobby'),
            icon = 'fa-solid fa-users',
            onSelect = function()
                lib.callback("speedway:getLobbies", false, function(lobbies)
                    if #lobbies == 0 then
                        lib.notify({
                            title = "Speedway",
                            description = locale("no_lobby"),
                            type = "error"
                        })
                        return
                    end
        
                    local selected = lib.inputDialog(locale("join_lobby"), {
                        {
                            type = "select",
                            label = locale("select_lobby"),
                            options = lobbies,
                            required = true
                        }
                    })
        
                    if selected and selected[1] then
                        TriggerServerEvent("speedway:joinLobby", selected[1])
                    end
                end)
            end,
            canInteract = function()
                return hasLobby and not currentLobby
            end
        },
        {
            label = "Lancer la course",
            icon = "fa-solid fa-flag-checkered",
            onSelect = function()
                if not currentLobby then return end
        
                local playersList = ""
                for _, id in ipairs(currentLobby.players) do
                    local name = GetPlayerName(GetPlayerFromServerId(id)) or ("ID: " .. id)
                    playersList = playersList .. "\n- " .. name
                end
        
                local confirm = lib.alertDialog({
                    header = "Démarrer la course ?",
                    content = "Participants : " .. playersList,
                    centered = true,
                    cancel = true
                })
        
                if confirm == "confirm" then
                    -- Lancer la course (event serveur à créer)
                    TriggerServerEvent("speedway:startRace", currentLobby.name)
                end
            end,
            canInteract = function()
                return currentLobby and GetPlayerServerId(PlayerId()) == currentLobby.owner
            end
        },
        {
            name = "leave_lobby",
            label = "Quitter le lobby",
            icon = "fa-solid fa-door-open",
            onSelect = function()
                TriggerServerEvent("speedway:leaveLobby")
                currentLobby = nil
                lib.notify({
                    title = "Speedway",
                    description = "Tu as quitté le lobby.",
                    type = "inform"
                })
            end,
            canInteract = function()
                return currentLobby ~= nil
            end
        }        
    })
end)

lib.callback.register("speedway:getVehicleChoice", function()
    local options = {}
    for _, v in ipairs(config.RaceVehicles) do
        table.insert(options, { label = v.label, value = v.model })
    end

    local selection = lib.inputDialog(locale("choose_vehicle_title"), {
        {
            type = "select",
            label = locale("choose_vehicle_label"),
            options = options,
            required = true,
            default = config.RaceVehicles[1].model
        }
    },{allowCancel = false})

    return selection and selection[1] or nil
end)


RegisterNetEvent("speedway:prepareStart", function(data)
    local trackType = data.track

    -- Spawn des props (ok à garder client side)
    local props = config.TrackProps[trackType]
    if props then
        for _, propData in ipairs(props) do
            local model = propData.prop
            for _, coord in ipairs(propData.cords) do
                local obj = CreateObject(model, coord.x, coord.y, coord.z - 1.0, false, false, false)
                PlaceObjectOnGroundProperly(obj)
                SetEntityHeading(obj, coord.w)
                FreezeEntityPosition(obj, true)
                table.insert(currentProps, obj)
            end
        end
    end

    -- On récupère le véhicule déjà spawn par le serveur
    local veh = NetworkGetEntityFromNetworkId(data.netId)
    local ped = PlayerPedId()
    while not DoesEntityExist(veh) do Wait(0) end

    SetEntityAsMissionEntity(veh, true, true)
    FreezeEntityPosition(veh, true)
    SetPedIntoVehicle(ped, veh, -1)



    for i = 3, 1, -1 do
        PlaySoundFrontend(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", true)
        ShowCountdownText(tostring(i), 1000)
    end
    
    FreezeEntityPosition(veh, false)
    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    ShowCountdownText("GO", 1000)
end)

RegisterNetEvent("speedway:updateLap", function(current, total)
    lib.notify({
        title = "🏁 Speedway",
        description = ("Tour %s/%s"):format(current, total),
        type = "inform"
    })
end)

RegisterNetEvent("speedway:youFinished", function()
    lib.notify({
        title = "🏁 Speedway",
        description = "Tu as terminé la course !",
        type = "success"
    })
end)

RegisterNetEvent("speedway:finalRanking", function(data)
    local text = "🏆 Classement final :\n"
    for i, res in ipairs(data.allResults) do
        local name = GetPlayerName(GetPlayerFromServerId(res.id)) or ("ID " .. res.id)
        local seconds = math.floor(res.time / 1000)
        text = text .. ("%d. %s - %ds\n"):format(i, name, seconds)
    end

    lib.alertDialog({
        header = "Résultats",
        content = text,
        centered = true
    })
end)


-- 🏁 Zone de la ligne de départ (compteur de tours)

local startLineZone = lib.zones.poly({
	name = "start_line",
	points = {
		vec3(-2760.0, 8064.0, 44.0),
		vec3(-2757.5500488281, 8103.0, 44.0),
		vec3(-2941.6000976562, 8129.25, 44.0),
		vec3(-2948.9499511719, 8074.5498046875, 44.0),
		vec3(-2905.0, 8084.0, 44.0),
	},
	thickness = 3.0,
	debug = config.debug,

	onExit = function()
		if currentLobby and currentLobby.name and not hasPassed then
			hasPassed = true
			TriggerServerEvent("speedway:lapPassed", currentLobby.name)

			CreateThread(function()
				Wait(3000)
				hasPassed = false
			end)
		end
	end
})
