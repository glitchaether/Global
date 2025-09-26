type Container = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(script.Parent.Parent.Parent:WaitForChild("trove"))
local Signal = require(script.Parent.Parent.Parent:WaitForChild("signal"))

local Global = {}
Global.__index = Global

local Variable = {}
Variable.__index = Variable

local Function = {}
Function.__index = Function

local Server: { [string]: Container } = {}

local function waitForLookup(getterFn: () -> any, timeout: number?): any
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
    If not constant, stores the new value.
    Returns the current value.

    ```lua
    local score = myServer:newVariable("Score", 0)
    score.Updated:Connect(function(newValue)
        print("Score updated to:", newValue)
    end)
    score:Update(10) -- prints "Score updated to: 10"
    ```
]]
function Variable:Update(value: any?): any
    self.Updated:Fire(value)
    if not self.constant then
        self.value = value
    end
    return self.value
end

--[[
    Retrieves the current stored value of the variable.

    ```lua
    local health = myServer:newVariable("Health", 100)
    print(health:Value()) -- 100
    ```
]]
function Variable:Value(): any
    return self.value
end

--[[
    Cleans up the variable.
    Destroys the trove, disconnects signals, and removes from parent container.

    ```lua
    local coins = myServer:newVariable("Coins", 5)
    coins:Delete() -- completely removes the variable
    ```
]]
function Variable:Delete(): ()
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
    Fires the Updated signal with the new callback.
    Returns the stored callback.

    ```lua
    local greet = myServer:newFunction("Greet", function(player)
        return "Hello, " .. player.Name
    end)
    greet:Update(function(player)
        return "Welcome, " .. player.Name
    end)
    ```
]]
function Function:Update(callback: (...any) -> any): (...any) -> any
    self.Updated:Fire(callback)
    self.callback = callback
    return self.callback
end

--[[
    Executes the function’s callback.
    Fires the Fired signal with the player and arguments.
    Warns if no callback is set.

    ```lua
    local greet = myServer:newFunction("Greet", function(player, msg)
        return player.Name .. " says: " .. msg
    end)

    local result = greet:Fire(somePlayer, "Hi!") 
    print(result) -- "PlayerName says: Hi!"
    ```
]]
function Function:Fire(player: Player?, ...): any
    if self.callback then
        self.Fired:Fire(player, ...)
        return self.callback(player, ...)
    else
        warn("Function has no callback")
    end
end

--[[
    Cleans up the function.
    Destroys the trove, disconnects signals, and removes from parent container.

    ```lua
    local shout = myServer:newFunction("Shout", function(player, msg)
        return string.upper(msg)
    end)
    shout:Delete() -- removes the function
    ```
]]
function Function:Delete(): ()
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
    Accepts an optional constant flag to prevent future updates.

    ```lua
    local myServer = Global.newServer("Main")
    local score = myServer:newVariable("Score", 0)
    print(score:Value()) -- 0
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
    Retrieves a variable by name, with optional timeout.

    ```lua
    local score = myServer:getVariable("Score", 3)
    if score then
        print(score:Value())
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
    Stores a callback and connects Updated and Fired signals.

    ```lua
    local greet = myServer:newFunction("Greet", function(player)
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
    Retrieves a function by name, with optional timeout.

    ```lua
    local greet = myServer:getFunction("Greet", 2)
    if greet then
        greet:Fire(somePlayer, "Hey!")
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
    Creates a new server container.
    If a name and path are provided, nests the container within the hierarchy.
    If only a name is provided, adds to the root.

    ```lua
    local mainServer = Global.newServer("Main")
    local subServer = Global.newServer("Sub", "Main")
    ```
]]
function Global.newServer(name: string?, path: string?): Container
    local newMeta: Container = setmetatable({}, Global)
    if name then
        if path then
            local decoded = string.split(path, "/")
            local located = Server
            for _, part in ipairs(decoded) do
                located[part] = located[part] or {}
                located = located[part]
            end
            located[name] = newMeta
            return located[name]
        else
            Server[name] = newMeta
            return Server[name]
        end
    else
        Server = newMeta
        return Server
    end
end

--[[
    Retrieves a server container by name and optional path.

    ```lua
    local sub = Global.getServer("Sub", "Main", 5)
    if sub then
        print("Sub server found")
    end
    ```
]]
function Global.getServer(name: string?, path: string?, timeout: number?): Container?
    local function locate()
        if name then
            if path then
                local decoded = string.split(path, "/")
                local located = Server
                for _, part in ipairs(decoded) do
                    located = located[part]
                    if not located then return nil end
                end
                return located[name]
            else
                return Server[name]
            end
        else
            return Server
        end
    end
    return waitForLookup(locate, timeout)
end

return Global
