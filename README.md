# Global Module

## Overview

This module allows you to create variables and functions that can be shared across multiple scripts of the same type, helping to keep your code organized, modular, and easier to maintain.

---

## Global Methods (Containers)

### `Global.newServer(name, path)`

Creates a new server/client (`Global.newClient`) container, optionally nested.

```lua
local main = Global.newServer("Main")
local sub = Global.newServer("Sub", "Main")
```

### `Global.getServer(name, path, timeout)`

Retrieves a container by name/path, optionally waiting for it.

Client (`Global.getClient`)

```lua
local sub = Global.getServer("Sub", "Main", 5)
if sub then
    print("Found Sub container")
end
```

### `Global:newVariable(name, value, constant, path)`

Creates a new variable inside the container. Can be marked as constant.

```lua
local myServer = Global.newServer("Main")
local score = myServer:newVariable("Score", 0)
```

### `Global:getVariable(name, timeout)`

Retrieves a variable by name, optionally waiting for it.

```lua
local score = myServer:getVariable("Score", 3)
if score then
    print("Score is:", score:Value())
end
```

### `Global:newFunction(name, callback, path)`

Creates a new function inside the container.

```lua
local greet = myServer:newFunction("Greet", function(player)
    return "Hello " .. player.Name
end)
```

### `Global:getFunction(name, timeout)`

Retrieves a function by name, optionally waiting for it.

```lua
local greet = myServer:getFunction("Greet", 2)
if greet then
    greet:Fire(somePlayer, "Hi")
end
```

---

## Variable

Represents a value that can be updated and fires events on change.

### `Variable:Update(value)`

Updates the variable’s value and fires the `Updated` signal.
If the variable is not constant, stores the new value.

```lua
local score = myServer:newVariable("Score", 0)
score.Updated:Connect(function(newValue)
    print("Score updated to:", newValue)
end)
score:Update(10) -- prints "Score updated to: 10"
```

### `Variable:Value()`

Retrieves the current stored value.

```lua
local health = myServer:newVariable("Health", 100)
print(health:Value()) -- 100
```

### `Variable:Delete()`

Deletes the variable, cleans up its trove, disconnects signals, and removes it from its parent.

```lua
local coins = myServer:newVariable("Coins", 50)
coins:Delete()
```

---

## Function

Represents a callable object with signals for updates and execution.

### `Function:Update(callback)`

Updates the function’s callback and fires the `Updated` signal.

```lua
local greet = myServer:newFunction("Greet", function(player)
    return "Hello " .. player.Name
end)

greet:Update(function(player)
    return "Welcome " .. player.Name
end)
```

### `Function:Fire(player, ...)`

Executes the function’s callback and fires the `Fired` signal.
Warns if no callback exists.

```lua
local greet = myServer:newFunction("Greet", function(player, msg)
    return player.Name .. " says " .. msg
end)

local result = greet:Fire(somePlayer, "Hi!")
print(result)
```

### `Function:Delete()`

Deletes the function, cleans up its trove, disconnects signals, and removes it from parent.

```lua
local shout = myServer:newFunction("Shout", function(player, msg)
    return string.upper(msg)
end)
shout:Delete()
```
