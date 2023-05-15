--- @entity players
--- @column id number NOT NULL AUTO_INCREMENT
--- @column nick string NOT NULL
--- @primaryKey id
local function createUsersTable()
end

make('example/players.lua', GetCurrentResourceName())
