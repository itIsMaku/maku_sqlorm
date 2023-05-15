--- @entity players
--- @column id number NOT NULL AUTO_INCREMENT
--- @column nick string NOT NULL
--- @primaryKey id
local function createPlayersRepository()
    --return exports.maku_sqlorm:createRepository('example/players.lua')
    return createRepository('example/players.lua', GetCurrentResourceName())
end

PlayerRepository = createPlayersRepository()

Citizen.CreateThread(function()
    local player = PlayerRepository:find('id', 1)
    player.nick = 'adam'
    local status, result = player.save()
end)

Citizen.CreateThread(function()
    local player = PlayerRepository:createEntity({
        nick = 'test'
    })
    player.save()
end)

Citizen.CreateThread(function()
    local players = PlayerRepository:findAll()
    for _, player in pairs(players) do
        print(player.id, player.nick)
    end
end)

Citizen.CreateThread(function()
    PlayerRepository:findAllAsync(function(players)
        for _, player in pairs(players) do
            print(player.id, player.nick)
        end
    end)
end)
