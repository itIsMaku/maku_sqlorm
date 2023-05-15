# FiveM SQL ORM
Simple lua sql ORM for FiveM

## Usage
First of all, you have to choose if you want to create a repository by export, or if you want to have the file added in the manifest of your script. 
If you choose adding to manifest file, add `@maku_sqlorm/server/sv-parser.lua` file to server scripts

### Creating repository
Each repository is created using a function and annotation. For annotations, you choose a table name for @entity type and then columns with data type, name, and additional sql lang data for the @column types.
If we chosed export way before, we use `exports.maku_sqlorm:createRepository`, if adding to the manifest, we skip the export call for orm script.
The first argument for `createRepository` must be the path to the repository file so that the parser can retrieve the data from annotations.
```lua
--- @entity players
--- @column id number NOT NULL AUTO_INCREMENT
--- @column nick string NOT NULL
--- @column money number NOT NULL DEFAULT '0'
--- @primaryKey id
local function createPlayersRepository()
    return exports.maku_sqlorm:createRepository('example/players.lua') -- Using export case
    return createRepository('example/players.lua', GetCurrentResourceName()) -- Including file in manifest case
end
```
Then we call function and define a variable.
```lua
PlayersRepository = createPlayersRepository()
```
Now we have created a repository object and can use its functions. A list of all functions can be found [below](https://github.com/itIsMaku/sql_orm#repository-functions)
### Repository functions
#### Main
```lua
local object = Repository:find(column, value)
Repository:findAsync(column, value, callback)

object.save()
```
```lua
local objects = Repository:findAll()
Repository:findAllAsync(callback)
```
```lua
local object = Repository:createEntity(data)
object.save()
```
When the `save` or `saveAsync` function is called on object, the object in the database is updated or, if it does not have a defined primary key, it is created.

#### Other
```lua
Repository:insert(data)
Repository:insertAsync(data, callback)

Repository:update(data)
Repository:updateAsync(data, callback)

Repository:delete(id)
Repository:deleteAsync(id, callback)
```

Great example can be found [there](https://github.com/itIsMaku/sql_orm/blob/main/example/players.lua).

## Dependencies
- [mysql-async](https://github.com/brouznouf/fivem-mysql-async) or [oxmysql](https://github.com/overextended/oxmysql)
