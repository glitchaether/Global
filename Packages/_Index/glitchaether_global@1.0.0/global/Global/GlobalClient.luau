export type Container = table

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(script.Parent.Parent.Parent:WaitForChild("trove"))
local Signal = require(script.Parent.Parent.Parent:WaitForChild("signal"))

local Global = {}
Global.__index = Global

local Variable = {}
Variable.__index = Variable

local Function = {}
Function.__index = Function

local Client = {}

--[[
    Utility: waitForLookup
    Continuously calls the getter function until a value is returned or timeout is reached.

    ```lua
    local found = waitForLookup(function()
        return myServer.SomeVar
    end, 5)
    ```
]]
local function waitForLookup(getterFn, timeout)
    local waitTime = timeout or 5
    local elapsed, interval = 0, 0.1
    local result = getterFn()
    while not result and elapsed < waitTime do
        task.wait(interval)
        elapsed += interval
        result = getterFn()
    end
    return result
end

--[[
    Updates the variable’s value.
    Fires the Updated signal with the new value.
    If not constant, replaces the stored value.

    ```lua
    local health = myClient:newVariable("Health", 100)
    health.Updated:Connect(function(newValue)
        print("Health changed to:", newValue)
    end)
    health:Update(75)
    ```
]]
function Variable:Update(value: any?)
    self.Updated:Fire(value)
    if not self.constant then
        self.value = value
    end
    return self.value
end

--[[
    Retrieves the current stored value.

    ```lua
    local coins = myClient:newVariable("Coins", 10)
    print(coins:Value()) -- 10
    ```
]]
function Variable:Value()
    return self.value
end

--[[
    Deletes the variable.
    Cleans up its trove, disconnects signals, and removes from parent.

    ```lua
    local score = myClient:newVariable("Score", 0)
    score:Delete()
    ```
]]
function Variable:Delete()
    if self._trove then
        self._trove:Destroy()
        self._trove = nil
    end
    if self._parent and self._name then
        self._parent[self._name] = nil
    end
    self._parent, self._name = nil, nil
end

--[[
    Updates the function’s callback.
    Fires the Updated signal.

    ```lua
    local greet = myClient:newFunction("Greet", function(player)
        return "Hello " .. player.Name
    end)

    greet:Update(function(player)
        return "Welcome " .. player.Name
    end)
    ```
]]
function Function:Update(callback: (...any) -> any)
    self.Updated:Fire(callback)
    self.callback = callback
    return self.callback
end

--[[
    Executes the stored callback.
    Fires the Fired signal with arguments.
    Warns if no callback exists.

    ```lua
    local greet = myClient:newFunction("Greet", function(player, msg)
        return player.Name .. " says " .. msg
    end)

    local result = greet:Fire(somePlayer, "Hi!")
    print(result)
    ```
]]
function Function:Fire(player: Player?, ...)
    if self.callback then
        self.Fired:Fire(player, ...)
        return self.callback(player, ...)
    else
        warn("Function has no callback")
    end
end

--[[
    Deletes the function.
    Cleans up its trove, disconnects signals, and removes from parent.

    ```lua
    local shout = myClient:newFunction("Shout", function(player, msg)
        return string.upper(msg)
    end)
    shout:Delete()
    ```
]]
function Function:Delete()
    if self._trove then
        self._trove:Destroy()
        self._trove = nil
    end
    if self._parent and self._name then
        self._parent[self._name] = nil
    end
    self._parent, self._name = nil, nil
end

--[[
    Creates a new variable inside the container.
    Can be constant if flagged.

    ```lua
    local myClient = Global.newClient("Main")
    local score = myServer:newVariable("Score", 0)
    ```
]]
function Global:newVariable(name: string, value: any, constant: boolean?, path: string?)
    local newMeta = {
        value = value,
        constant = constant or false,
        _parent = self,
        _name = name,
        _trove = Trove.new(),
    }
    newMeta.Updated = newMeta._trove:Construct(Signal)

    self[name] = setmetatable(newMeta, Variable)
    return self[name]
end

--[[
    Gets a variable by name.
    Waits up to the timeout.

    ```lua
    local score = myClient:getVariable("Score", 3)
    if score then
        print("Score is:", score:Value())
    end
    ```
]]
function Global:getVariable(name: string, timeout: number?)
    local function getter()
        return self[name]
    end
    return waitForLookup(getter, timeout)
end

--[[
    Creates a new function inside the container.
    Adds Updated and Fired signals.

    ```lua
    local greet = myClient:newFunction("Greet", function(player)
        return "Hello " .. player.Name
    end)
    ```
]]
function Global:newFunction(name: string, callback: (...any) -> any, path: string?)
    local newMeta = {
        callback = callback,
        _parent = self,
        _name = name,
        _trove = Trove.new(),
    }
    newMeta.Updated = newMeta._trove:Construct(Signal)
    newMeta.Fired = newMeta._trove:Construct(Signal)

    self[name] = setmetatable(newMeta, Function)
    return self[name]
end

--[[
    Gets a function by name.
    Waits up to the timeout.

    ```lua
    local greet = myClient:getFunction("Greet", 2)
    if greet then
        greet:Fire(somePlayer, "Hi")
    end
    ```
]]
function Global:getFunction(name: string, timeout: number?)
    local function getter()
        return self[name]
    end
    return waitForLookup(getter, timeout)
end

--[[
    Creates a new client container.
    Can be nested using a path.

    ```lua
    local main = Global.newClient("Main")
    local sub = Global.newClient("Sub", "Main")
    ```
]]
function Global.newClient(name: string?, path: string?): Container
    local newMeta: Container = setmetatable({}, Global)
    if name then
        if path then
            local decoded = string.split(path, "/")
            local located = Client
            for _, part in ipairs(decoded) do
                located[part] = located[part] or {}
                located = located[part]
            end
            located[name] = newMeta
            return located[name]
        else
            Client[name] = newMeta
            return Client[name]
        end
    else
        Client = newMeta
        return Client
    end
end

--[[
    Retrieves a client container by name and path.
    Waits up to the timeout.

    ```lua
    local sub = Global.getClient("Sub", "Main", 5)
    if sub then
        print("Found Sub container")
    end
    ```
]]
function Global.getClient(name: string?, path: string?, timeout: number?): Container
    local function locate()
        if name then
            if path then
                local decoded = string.split(path, "/")
                local located = Client
                for _, part in ipairs(decoded) do
                    located = located[part]
                    if not located then return nil end
                end
                return located[name]
            else
                return Client[name]
            end
        else
            return Client
        end
    end
    return waitForLookup(locate, timeout)
end

return Global
