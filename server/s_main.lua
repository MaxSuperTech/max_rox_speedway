lib.locale()

local lobbies = {}
--#region registeevent
RegisterNetEvent("speedway:createLobby", function(lobbyName, trackType)
    local src = source

    -- Empêche les doublons
    if lobbies[lobbyName] then
        TriggerClientEvent('ox_lib:notify', src, {
            description = locale("lobby_exists"),
            type = "error"
        })

        return
    end

    lobbies[lobbyName] = {
        owner = src,
        track = trackType,
        players = { src },
        isStarted = false
    }

    for _, id in ipairs(lobbies[lobbyName].players) do
        TriggerClientEvent("speedway:updateLobbyInfo", id, {
            name = lobbyName,
            track = lobbies[lobbyName].track,
            players = lobbies[lobbyName].players,
            owner = lobbies[lobbyName].owner
        })
    end

    -- Confirmation côté client
    TriggerClientEvent('ox_lib:notify', src, {
        description = locale("lobby_created", { lobby = lobbyName }),
        type = "success"
    })


    -- Mets à jour l’état de disponibilité côté client (pour afficher "rejoindre un lobby")
    TriggerClientEvent('speedway:setLobbyState', -1, next(lobbies) ~= nil)

    print("[SPEEDWAY] Lobby créé:", lobbyName, "par", GetPlayerName(src), "- Type:", trackType)
end)

RegisterNetEvent("speedway:joinLobby", function(lobbyName)
    local src = source
    local lobby = lobbies[lobbyName]

    if not lobby then
        TriggerClientEvent('ox_lib:notify', src, {
            title = "Speedway",
            description = locale("lobby_not_found"),
            type = "error"
        })
        return
    end

    -- Si le joueur n’est pas déjà dans le lobby, on l’ajoute
    if not table.contains(lobby.players, src) then
        table.insert(lobby.players, src)
    end

    -- Envoie la mise à jour à tous les joueurs du lobby
    for _, id in ipairs(lobby.players) do
        TriggerClientEvent("speedway:updateLobbyInfo", id, {
            name = lobbyName,
            track = lobby.track,
            players = lobby.players
        })
    end

    -- Notification de confirmation
    TriggerClientEvent('ox_lib:notify', src, {
        title = "Speedway",
        description = locale("joined_lobby", { lobby = lobbyName }),
        type = "success"
    })
end)

RegisterNetEvent("speedway:leaveLobby", function()
    local src = source

    for name, lobby in pairs(lobbies) do
        for i, id in ipairs(lobby.players) do
            if id == src then
                table.remove(lobby.players, i)

                -- Si le lobby est vide, on le supprime
                if #lobby.players == 0 then
                    lobbies[name] = nil
                end

                -- Mise à jour des joueurs restants
                for _, player in ipairs(lobby.players) do
                    TriggerClientEvent("speedway:updateLobbyInfo", player, {
                        name = name,
                        track = lobby.track,
                        players = lobby.players,
                        owner = lobby.owner
                    })
                end

                -- Notifie tous les clients si plus de lobby
                TriggerClientEvent("speedway:setLobbyState", -1, next(lobbies) ~= nil)

                break
            end
        end
    end
end)

RegisterNetEvent("speedway:startRace", function(lobbyName)
    local src = source
    local lobby = lobbies[lobbyName]

    -- Vérifie que le lobby existe
    if not lobby then
        TriggerClientEvent('ox_lib:notify', src, {
            description = locale("lobby_not_found"),
            type = "error"
        })
        return
    end

    -- Vérifie que le joueur est bien le créateur du lobby
    if lobby.owner ~= src then
        TriggerClientEvent('ox_lib:notify', src, {
            description = "Tu n'es pas autorisé à démarrer cette course.",
            type = "error"
        })
        return
    end

    -- 🔒 Vérifie qu'aucune autre course n'est en cours
    for name, data in pairs(lobbies) do
        if data.isStarted and name ~= lobbyName then
            TriggerClientEvent('ox_lib:notify', src, {
                description = locale("race_in_progress"),
                type = "error"
            })
            return
        end
    end

    -- ✅ Marque la course comme démarrée
    lobby.isStarted = true

    -- 🚀 Envoie l'event de départ à tous les joueurs
    for _, playerId in ipairs(lobby.players) do
        TriggerClientEvent("speedway:prepareStart", playerId, {
            track = lobby.track,
            lobby = lobbyName
        })
    end
end)


--#endregion registeevent

--#region callback
lib.callback.register("speedway:getLobbies", function()
    local result = {}

    for name, data in pairs(lobbies) do
        result[#result + 1] = {
            label = name .. " | " .. data.track,
            value = name
        }
    end

    return result
end)
--#endregion callback

--#region function
function table.contains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end
--#endregion function