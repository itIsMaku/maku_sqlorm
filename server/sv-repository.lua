local function formatInsertQuery(tableName, tableColumns, data)
    local columns = ''
    local values = ''
    for _, column in pairs(tableColumns) do
        if data[column.name] ~= nil then
            columns = columns .. column.name .. ','
            values = values .. '@' .. column.name .. ','
        end
    end
    columns = columns:sub(1, -2)
    values = values:sub(1, -2)
    local query = 'INSERT INTO ' .. tableName .. ' (' .. columns .. ') VALUES (' .. values .. ')'
    return query
end

local function formatUpdateQuery(tableName, tableColumns, primaryKey, data)
    local columns = ''
    for _, column in pairs(tableColumns) do
        if data[column.name] ~= nil then
            columns = columns .. column.name .. ' = @' .. column.name .. ','
        end
    end
    columns = columns:sub(1, -2)
    local query = 'UPDATE ' ..
        tableName .. ' SET ' .. columns .. ' WHERE ' .. primaryKey .. ' = @' .. primaryKey
    return query
end

function createRepositoryObject(entity)
    local repository = {
        entity = entity
    }

    function repository:createEntity(result)
        local object = result

        function object:saveAsync(callback)
            if object[repository.entity.primaryKey] ~= nil then
                repository:updateAsync(object, function(result)
                    local status = nil
                    if result > 0 then
                        status = 'updated'
                    end
                    callback(status, result)
                end)
            else
                repository:insertAsync(object, function(result)
                    local status = nil
                    if result > 0 then
                        status = 'inserted'
                    end
                    callback(status, result)
                end)
            end
        end

        function object.save()
            local status = nil
            local result = nil
            if object[repository.entity.primaryKey] ~= nil then
                result = repository:update(object)
                if result > 0 then
                    status = 'updated'
                end
            else
                result = repository:insert(object)
                if result > 0 then
                    status = 'inserted'
                end
            end
            return status, result
        end

        return object
    end

    function repository:findAsync(column, value, callback)
        local query = 'SELECT * FROM ' .. self.entity.name .. ' WHERE ' .. column .. ' = @value'
        MySQL.Async.fetchAll(query, {
            ['@value'] = value
        }, function(result)
            if callback then
                if result[1] ~= nil then
                    callback(repository:createEntity(result[1]))
                else
                    callback(nil)
                end
            end
        end)
    end

    function repository:find(column, value)
        local query = 'SELECT * FROM ' .. repository.entity.name .. ' WHERE ' .. column .. ' = @value'
        local result = MySQL.Sync.fetchAll(query, {
            ['@value'] = value
        })
        if result[1] ~= nil then
            return repository:createEntity(result[1])
        end
        return nil
    end

    function repository:findAllAsync(callback)
        local query = 'SELECT * FROM ' .. self.entity.name
        MySQL.Async.fetchAll(query, {}, function(result)
            if callback then
                local objects = {}
                for _, row in pairs(result) do
                    table.insert(objects, repository:createEntity(row))
                end
                callback(objects)
            end
        end)
    end

    function repository:findAll()
        local query = 'SELECT * FROM ' .. self.entity.name
        local result = MySQL.Sync.fetchAll(query, {})
        local objects = {}
        for _, row in pairs(result) do
            table.insert(objects, repository:createEntity(row))
        end
        return objects
    end

    function repository:insertAsync(data, callback)
        MySQL.Async.execute(formatInsertQuery(self.entity.name, self.entity.columns, data), data, function(result)
            if callback then
                callback(result)
            end
        end)
    end

    function repository:insert(data)
        local result = MySQL.Sync.execute(formatInsertQuery(self.entity.name, self.entity.columns, data), data)
        return result
    end

    function repository:updateAsync(data, callback)
        MySQL.Async.execute(formatUpdateQuery(self.entity.name, self.entity.columns, self.entity.primaryKey, data), data,
            function(result)
                if callback then
                    callback(result)
                end
            end)
    end

    function repository:update(data)
        local result = MySQL.Sync.execute(
            formatUpdateQuery(self.entity.name, self.entity.columns, self.entity.primaryKey, data), data)
        return result
    end

    function repository:deleteAsync(id, callback)
        local query = 'DELETE FROM ' .. self.entity.name .. ' WHERE ' .. self.entity.primaryKey .. ' = @id'
        MySQL.Async.execute(query, {
            ['@id'] = id
        }, function(result)
            if callback then
                callback(result)
            end
        end)
    end

    function repository:delete(id)
        local query = 'DELETE FROM ' .. self.entity.name .. ' WHERE ' .. self.entity.primaryKey .. ' = @id'
        local result = MySQL.Sync.execute(query, {
            ['@id'] = id
        })
        return result
    end

    return repository
end

exports('createRepositoryObject', createRepositoryObject)
