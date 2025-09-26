# Global Module

A module for creating shared variables and functions across multiple scripts, keeping your code organized, modular, and easier to maintain.

---

## Installation

### Wally

Add to your `wally.toml`:

```toml
[dependencies]
GlobalModule = "yourusername/globalmodule@1.0.1"
```

Then run:

```bash
wally install
```

### GitHub

Install the Packages folder and set up with Rojo.
Parent it to `src/shared` or update `default.project.json`:

```json
"ReplicatedStorage": {
    "Shared": {
        "$path": "src/shared"
    },
    "Packages": {
        "$path": "Packages"
    },
}
```

### Roblox

You can download the module on [Roblox](https://create.roblox.com/store/asset/118102939012715).

---

## Quick Start

```lua
local Global = require(Packages.GlobalModule)

-- Create a server container
local main = Global.newServer("Main")
local sub = Global.newServer("Sub", "Main")

-- Create a variable
local score = main:newVariable("Score", 0)

-- Listen for updates
score.Updated:Connect(function(newValue)
    print("Score updated to:", newValue)
end)
score:Update(10)

-- Create a function
local greet = main:newFunction("Greet", function(player)
    return "Hello " .. player.Name
end)

-- Call the function
local message = greet:Fire(somePlayer)
print(message)
```

---

## API Reference

### Global Methods (Containers)

#### `Global.newServer(name, path)`

Creates a new server container, optionally nested.

```lua
local main = Global.newServer("Main")
local sub = Global.newServer("Sub", "Main")
```

#### `Global.getServer(name, path, timeout)`

Retrieves a server container by name/path, optionally waiting for it.

```lua
local sub = Global.getServer("Sub", "Main", 5)
if sub then
    print("Found Sub container")
end
```

#### `Global:newVariable(name, value, constant, path)`

Creates a variable inside a container. Can be marked constant.

```lua
local score = main:newVariable("Score", 0)
```

#### `Global:getVariable(name, timeout)`

Retrieves a variable by name, optionally waiting for it.

```lua
local score = main:getVariable("Score", 3)
if score then
    print("Score is:", score:Value())
end
```

#### `Global:newFunction(name, callback, path)`

Creates a new function inside a container.

```lua
local greet = main:newFunction("Greet", function(player)
    return "Hello " .. player.Name
end)
```

#### `Global:getFunction(name, timeout)`

Retrieves a function by name, optionally waiting for it.

```lua
local greet = main:getFunction("Greet", 2)
if greet then
    greet:Fire(somePlayer)
end
```

---

## Variable

Represents a value that can be updated and fires events on change.

### `Variable:Update(value)`

Updates the value and fires the `Updated` signal.

```lua
score:Update(10) -- fires Updated signal
```

### `Variable:Value()`

Returns the current value.

```lua
print(score:Value()) -- 10
```

### `Variable:Delete()`

Deletes the variable and cleans up its signals and trove.

```lua
score:Delete()
```

---

## Function

Represents a callable object with signals for updates and execution.

### `Function:Update(callback)`

Updates the function’s callback and fires the `Updated` signal.

```lua
greet:Update(function(player)
    return "Welcome " .. player.Name
end)
```

### `Function:Fire(player, ...)`

Executes the function’s callback and fires the `Fired` signal.

```lua
local result = greet:Fire(somePlayer)
print(result)
```

### `Function:Delete()`

Deletes the function and cleans up its signals and trove.

```lua
greet:Delete()
```

---

## Examples

```lua
-- Create a server and variables
local main = Global.newServer("Main")
local score = main:newVariable("Score", 0)

-- Update variable
score:Update(5)

-- Create and call function
local greet = main:newFunction("Greet", function(player)
    return "Hello " .. player.Name
end)
print(greet:Fire(somePlayer))
```

---

## Dependencies

* [Signal and Trove](https://github.com/Sleitnick/RbxUtil) — event handling and automatic cleanup
* [Wally](https://wally.run/) — Roblox package manager

---

## License

MIT License. Free to use, modify, and distribute.
