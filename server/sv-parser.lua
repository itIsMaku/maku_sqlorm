local function isDirectory(path)
    local file = io.open(path, "r")
    if file then
        local isDirectory = (file:read("*line") == nil)
        file:close()
        return isDirectory
    end
    return true
end

local function getFilesInDirectory(directory)
    local files = {}
    local cmd = io.popen('dir "' .. directory .. '" /b /a')
    if cmd then
        local output = cmd:read('*a')
        for fileName in output:gmatch("[^\r\n]+") do
            table.insert(files, fileName)
        end
        cmd:close()
    end
    return files
end

local function processFile(filePath)
    local file = io.open(filePath, 'r')
    if file then
        local content = file:read('*all')
        file:close()
        return filePath, content
    end
end

local function processDirectory(directory)
    local retval = { w }
    local files = getFilesInDirectory(directory)
    for _, file in ipairs(files) do
        local path = directory .. '/' .. file
        if isDirectory(path) then
            processDirectory(path)
        else
            local proccesedPath, content = processFile(path)
            if proccesedPath then
                retval[proccesedPath] = content
            end
        end
    end
    return retval
end

local function parseContent(content)
    local annotations = {}
    local currentFunction = nil
    local currentAnnotations = {}
    for line in content:gmatch("[^\r\n]+") do
        local functionAnnotations = line:match("---%s*(.+)")
        if functionAnnotations then
            currentAnnotations[#currentAnnotations + 1] = functionAnnotations
        end

        local functionName = line:match("([%w_]+)%s*=%s*function%s*%(")
        if functionName then
            currentFunction = functionName
            annotations[currentFunction] = currentAnnotations
            currentAnnotations = {}
        end

        local functionName2 = line:match("function%s+([%w_]+)%s*%(")
        if functionName2 then
            currentFunction = functionName2
            annotations[currentFunction] = currentAnnotations
            currentAnnotations = {}
        end
    end
    return annotations
end

local function parseAnnotationDetailed(annot)
    local annotationType, name, dataType, description = annot:match("---%s*@(%w+)%s*(%w+)%s*([%w_]+)%s*(.+)")
    return annotationType, name, dataType, description
end

local function parseAnnotation(annot)
    local annotationType, name = annot:match("---%s*@(%w+)%s*(%w+)")
    return annotationType, name
end

local function getEntities(content)
    local entities = {}
    local retval = parseContent(content)
    for fun, annotations in pairs(retval) do
        local entity = {}
        for _, annotation in pairs(annotations) do
            local annotationType, name = parseAnnotation(annotation)
            if annotationType == 'entity' then
                entity.name = name
            elseif annotationType == 'column' then
                local annotationType, name, dataType, description = parseAnnotationDetailed(annotation)
                if not entity.columns then
                    entity.columns = {}
                end
                entity.columns[#entity.columns + 1] = {
                    name = name,
                    dataType = dataType,
                    addon = description
                }
            elseif annotationType == 'primaryKey' then
                entity.primaryKey = name
            end
        end
        if entity.name ~= nil then
            if entity.columns == nil then
                entity.columns = {}
            end
            entities[entity.name] = entity
        end
    end
    return entities
end

function createRepository(filePath, res)
    if res == nil then
        res = GetCurrentResourceName()
    end
    local path = GetResourcePath(res) .. '/' .. filePath
    local retval = nil
    if isDirectory(path) then
        retval = processDirectory(path)
    else
        local _, content = processFile(path)
        retval = content
    end
    local entities = {}
    if type(retval) == 'table' then
        for file, content in pairs(retval) do
            local entitiesInFile = getEntities(content)
            for entityName, entity in pairs(entitiesInFile) do
                entities[entityName] = entity
            end
        end
    else
        entities = getEntities(retval)
    end
    for entityName, entity in pairs(entities) do
        local query = 'CREATE TABLE IF NOT EXISTS ' .. entityName .. ' ('
        for _, column in pairs(entity.columns) do
            local dataType = column.dataType
            if dataType == 'string' then
                dataType = 'varchar(255)'
            elseif dataType == 'number' then
                dataType = 'int'
            end
            if #column.addon > 1 then
                dataType = dataType .. ' ' .. column.addon
            end
            query = query .. column.name .. ' ' .. dataType .. ', '
        end
        if entity.primaryKey then
            query = query .. 'PRIMARY KEY (' .. entity.primaryKey .. ')'
        else
            query = query:sub(1, -3)
        end
        query = query .. ')'
        MySQL.Async.execute(query, {}, function(rowsChanged)
            print('Created table:', entityName)
        end)
    end
    local _createRepositoryObject = createRepositoryObject
    if _createRepositoryObject == nil then
        _createRepositoryObject = exports.maku_sqlorm.createRepositoryObject
    end
    if #entities > 1 then
        local repositories = {}
        for entityName, entity in pairs(entities) do
            repositories[entityName] = _createRepositoryObject(entity)
        end
        return repositories
    else
        return _createRepositoryObject(entities[next(entities)])
    end
end

exports('createRepository', function(filePath)
    return createRepository(filePath, GetInvokingResource())
end)
