lib.locale()
local config = require "config.shared"
local hasLobby = false
local currentLobby = nil

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
                    },
                })
            
                if infolobby and infolobby[1] then
                    local trackType = infolobby[1]
                    local playerName = GetPlayerName(PlayerId())
                    local lobbyName = playerName .. "_" .. math.random(1000, 9999)
            
                    TriggerServerEvent("speedway:createLobby", lobbyName, trackType)
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
                return hasLobby -- bool mis à jour par l'event `speedway:setLobbyState`
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