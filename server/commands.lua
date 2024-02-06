local config = require 'config.server'
local logger = require 'modules.logger'

GlobalState.PVPEnabled = config.server.pvp

-- Teleport
lib.addCommand('tp', {
    help = locale("command.tp.help"),
    params = {
        { name = locale("command.tp.params.x.name"), help = locale("command.tp.params.x.help"), optional = false},
        { name = locale("command.tp.params.y.name"), help = locale("command.tp.params.y.help"), optional = true },
        { name = locale("command.tp.params.z.name"), help = locale("command.tp.params.z.help"), optional = true }
    },
    restricted = "group.admin"
}, function(source, args)
    if args[locale("command.tp.params.x.name")] and not args[locale("command.tp.params.y.name")] and not args[locale("command.tp.params.z.name")] then
        local target = GetPlayerPed(tonumber(args[locale("command.tp.params.x.name")]) --[[@as number]])
        if target ~= 0 then
            local coords = GetEntityCoords(target)
            TriggerClientEvent('QBCore:Command:TeleportToPlayer', source, coords)
        else
            Notify(source, locale('error.not_online'), 'error')
        end
    else
        if args[locale("command.tp.params.x.name")] and args[locale("command.tp.params.y.name")] and args[locale("command.tp.params.z.name")] then
            local x = tonumber((args[locale("command.tp.params.x.name")]:gsub(",",""))) + .0
            local y = tonumber((args[locale("command.tp.params.y.name")]:gsub(",",""))) + .0
            local z = tonumber((args[locale("command.tp.params.z.name")]:gsub(",",""))) + .0
            if x ~= 0 and y ~= 0 and z ~= 0 then
                TriggerClientEvent('QBCore:Command:TeleportToCoords', source, x, y, z)
            else
                Notify(source, locale('error.wrong_format'), 'error')
            end
        else
            Notify(source, locale('error.missing_args'), 'error')
        end
    end
end)

lib.addCommand('tpm', {
    help = locale("command.tpm.help"),
    restricted = "group.admin"
}, function(source)
    TriggerClientEvent('QBCore:Command:GoToMarker', source)
end)

lib.addCommand('togglepvp', {
    help = locale("command.togglepvp.help"),
    restricted = "group.admin"
}, function()
    config.server.pvp = not config.server.pvp
    GlobalState.PVPEnabled = config.server.pvp
end)

-- Permissions

lib.addCommand('addpermission', {
    help = locale("command.addpermission.help"),
    params = {
        {name = locale("command.addpermission.params.id.name"), help = locale("command.addpermission.params.id.help")},
        {name = locale("command.addpermission.params.permission.name"), help = locale("command.addpermission.params.permission.help")}
    },
    restricted = "group.admin"
}, function(source, args)
    local player = GetPlayer(tonumber(args[locale("command.addpermission.params.id.name")]) --[[@as number]])
    local permission = tostring(args[locale("command.addpermission.params.permission.name")])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end
    AddPermission(player.PlayerData.source, permission)
end)

lib.addCommand('removepermission', {
    help = locale("command.removepermission.help"),
    params = {
        { name = locale("command.removepermission.params.id.name"), help = locale("command.removepermission.params.id.help") },
        { name = locale("command.removepermission.params.permission.name"), help = locale("command.removepermission.params.permission.help") }
    },
    restricted = "group.admin"
}, function(source, args)
    local player = GetPlayer(tonumber(args[locale("command.removepermission.params.id.name")]) --[[@as number]])
    local permission = tostring(args[locale("command.removepermission.params.permission.name")])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end
    RemovePermission(player.PlayerData.source, permission)
end)

-- Open & Close Server

lib.addCommand('openserver', {
    help = locale("command.openserver.help"),
    restricted = "group.admin"
}, function(source)
    if not config.server.closed then
        Notify(source, locale('error.server_already_open'), 'error')
        return
    end
    if HasPermission(source, 'admin') then
        config.server.closed = false
        Notify(source, locale('success.server_opened'), 'success')
    else
        DropPlayer(source, locale("error.no_permission"))
    end
end)

lib.addCommand('closeserver', {
    help = locale("command.openserver.help"),
    params = {
        { name = locale("command.closeserver.params.reason.name"), help = locale("command.closeserver.params.reason.help")}
    },
    restricted = "group.admin"
}, function(source, args)
    if config.server.closed then
        Notify(source, locale('error.server_already_closed'), 'error')
        return
    end
    if HasPermission(source, 'admin') then
        local reason = args[locale("command.closeserver.params.reason.name")] or 'No reason specified'
        config.server.closed = true
        config.server.closedReason = reason
        for k in pairs(QBX.Players) do
            if not HasPermission(k, config.server.whitelistPermission) then
                DropPlayer(k, reason)
            end
        end
        Notify(source, locale('success.server_closed'), 'success')
    else
        DropPlayer(source, locale("error.no_permission"))
    end
end)

-- Vehicle

lib.addCommand('car', {
    help = locale("command.car.help"),
    params = {
        { name = locale("command.car.params.model.name"), help = locale("command.car.params.model.help") },
        { name = locale("command.car.params.keepCurrentVehicle.name"), help = locale("command.car.params.keepCurrentVehicle.help"), optional = true },
    },
    restricted = "group.admin"
}, function(source, args)
    if not args then return end

    local ped = GetPlayerPed(source)
    local keepCurrentVehicle = args[locale("command.car.params.keepCurrentVehicle.name")]
    local currentVehicle = not keepCurrentVehicle and GetVehiclePedIsIn(ped, false)
    if currentVehicle and currentVehicle ~= 0 then
        DeleteEntity(currentVehicle)
    end

    local netId = qbx.spawnVehicle({
        model = args[locale("command.car.params.model.name")],
        spawnSource = ped,
        warp = true,
    })

    local plate = qbx.getVehiclePlate(NetworkGetEntityFromNetworkId(netId))
    config.giveVehicleKeys(source, plate)
end)

lib.addCommand('dv', {
    help = locale('command.dv.help'),
    params = {
        { name = locale('command.dv.params.radius.name'), type = 'number', help = locale('command.dv.params.radius.help'), optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    local ped = GetPlayerPed(source)
    local pedCars = {GetVehiclePedIsIn(ped, false)}
    local radius = args[locale('command.dv.params.radius.name')]

    if pedCars[1] == 0 or radius then -- Only execute when player is not in a vehicle or radius is explicitly defined
        pedCars = lib.callback.await('qbx_core:client:getVehiclesInRadius', source, radius)
    else
        pedCars[1] = NetworkGetNetworkIdFromEntity(pedCars[1])
    end

    if #pedCars ~= 0 then
        for i = 1, #pedCars do
            local pedCar = NetworkGetEntityFromNetworkId(pedCars[i])
            if pedCar and DoesEntityExist(pedCar) then
                DeleteEntity(pedCar)
            end
        end
    end
end)

-- Out of Character Chat

lib.addCommand('ooc', {
    help = locale("command.ooc.help")
}, function(source, args)
    local message = table.concat(args, ' ')
    local players = GetPlayers()
    local player = GetPlayer(source)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    for _, v in pairs(players) do
        if v == source then
            TriggerClientEvent('chat:addMessage', v --[[@as Source]], {
                color = { 0, 0, 255},
                multiline = true,
                args = {('OOC | %s'):format(GetPlayerName(source)), message}
            })
        elseif #(playerCoords - GetEntityCoords(GetPlayerPed(v))) < 20.0 then
            TriggerClientEvent('chat:addMessage', v --[[@as Source]], {
                color = { 0, 0, 255},
                multiline = true,
                args = {('OOC | %s'):format(GetPlayerName(source)), message}
            })
        elseif HasPermission(v --[[@as Source]], 'admin') then
            if IsOptin(v --[[@as Source]]) then
                TriggerClientEvent('chat:addMessage', v --[[@as Source]], {
                    color = { 0, 0, 255},
                    multiline = true,
                    args = {('Proximity OOC | %s'):format(GetPlayerName(source)), message}
                })
                logger.log({
                    source = 'qbx_core',
                    webhook  = 'ooc',
                    event = 'OOC',
                    color = 'white',
                    tags = config.logging.role,
                    message = '**' .. GetPlayerName(source) .. '** (CitizenID: ' .. player.PlayerData.citizenid .. ' | ID: ' .. source .. ') **Message:** ' .. message
                })
            end
        end
    end
end)

-- Me command

lib.addCommand('me', {
    help = locale("command.me.help"),
    params = {
        { name = locale("command.me.params.message.name"), help = locale("command.me.params.message.help") }
    }
}, function(source, args)
    args[1] = args[locale("command.me.params.message.name")]
    args[locale("command.me.params.message.name")] = nil
    if #args < 1 then Notify(source, locale('error.missing_args2'), 'error') return end
    local msg = table.concat(args, ' '):gsub('[~<].-[>~]', '')
    local playerState = Player(source).state
    playerState:set('me', msg, true)

    -- We have to reset the playerState since the state does not get replicated on StateBagHandler if the value is the same as the previous one --
    playerState:set('me', nil, true)
end)

-- ID command

lib.addCommand('id', {help = locale('info.check_id')}, function(source)
    Notify(source, 'ID: ' .. source)
end)

-- Character commands

lib.addCommand('logout', {
    help = locale('info.logout_command_help'),
    restricted = 'group.admin',
}, Logout)

lib.addCommand('deletechar', {
    help = locale('info.deletechar_command_help'),
    restricted = 'group.admin',
    params = {
        { name = 'id', help = locale('info.deletechar_command_arg_player_id'), type = 'number' },
    }
}, function(source, args)
    local player = GetPlayer(args.id)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    ForceDeleteCharacter(citizenId)
    Notify(source, locale('success.character_deleted_citizenid', {citizenid = citizenId}))
end)
