# sqlentities
creating sql tables with annotations

## Usage
1. Add `@sqlentities/server/sv-parser.lua` to your fxmanifest.lua
2. Create annotations for your sql tables anywhere you want in your script, e.g.:
```lua
--- @entity players
--- @column id number NOT NULL AUTO_INCREMENT
--- @column nick string NOT NULL
--- @primaryKey id
local function createUsersTable()
end
```
3. Call `make('<path>', GetCurrentResourceName())` function, where `path` is path to folder with files where are annotations in files (e.g. `example`) or specific lua file (e.g. `example/players.lua`)
4. MySQL table will be created if not exists :)

## Column data types
- **string** - varchar(255)
- **number** - int
