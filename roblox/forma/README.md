# Forma — Roblox Studio GUI

A self-contained native Luau interface based on the Forma tldraw designs: white backgrounds, thin neutral borders, Arial typography, small corners, and separate pages. No emoji icons or third-party UI library. Real Lucide SVG geometry is embedded as native GUI strokes, so no icon asset upload or runtime web fetch is needed.

## Files

- `Client.luau`: complete client GUI and local test tools, one file; returns a handle.
- `Server.server.luau`: normal Roblox server adapter for admin access, movement, flight grants, and teleport.
- `Install-Studio.luau`: Command Bar installer that downloads and creates both normal Roblox scripts.
- `icons/`: original Lucide SVGs used to build the embedded icons.
- `LUCIDE-LICENSE.txt`: upstream attribution/license.
- `tests/`: standalone mocked behavioral checks; these do not replace a Roblox Studio playtest.

## Quick Studio install

Stop Play mode, open **View → Command Bar**, enable **Allow HTTP Requests** in Game Settings → Security, and paste this. It fetches source and creates scripts without requiring runtime `loadstring`:

```lua
local Http = game:GetService("HttpService")
local base = "https://raw.githubusercontent.com/lyhengthoek-bit/Forma-Ai-web/main/roblox/forma/"
assert(not game:GetService("RunService"):IsRunning(), "Stop Play mode first")
local clientSource = Http:GetAsync(base .. "Client.luau", true)
local serverSource = Http:GetAsync(base .. "Server.server.luau", true)
local scripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local serverScripts = game:GetService("ServerScriptService")
assert(not scripts:FindFirstChild("FormaClient") and not serverScripts:FindFirstChild("FormaServer"), "Forma is already installed")
local client = Instance.new("LocalScript")
client.Name, client.Source = "FormaClient", clientSource
local server = Instance.new("Script")
server.Name, server.Source = "FormaServer", serverSource
server:SetAttribute("AdminUserIds", "")
server:SetAttribute("AccessKey", "")
server.Parent, client.Parent = serverScripts, scripts
print("Press Play. Studio preview key: FORMA-TEST")
```

Press Play and enter **`FORMA-TEST`**. Studio preview is available only when `RunService:IsStudio()` is true. This demo key does not grant admin access in a published game.

Alternatively, paste the contents of `Client.luau` into one LocalScript in StarterPlayerScripts. In Studio it supports the GUI preview and local movement without the server adapter. For a published game install the server adapter.

## Your custom client loader

If your existing client loader supplies `game:HttpGet` and `loadstring`, the one-line entry is:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/lyhengthoek-bit/Forma-Ai-web/main/roblox/forma/Client.luau"))()
```

Those methods are not provided to ordinary Studio LocalScripts. The source itself uses standard Roblox client APIs. It must run in client context, not in a server Script. A source fetch/compile does not itself provide a client execution context. The Studio installer above does.

## Pages and behavior

**Access → Loading → Workspace** preserves the tldraw flow. The loading view uses a restrained animated progress bar and is skipped only when the interface is destroyed.

- **Player:** bounded walk speed and jump power; fly toggle and speed; saved destination quick teleport; live coordinates.
- **Aim:** hold right mouse or always-on camera aim assist; smoothing; FOV radius; line-of-sight and team checks; target part; separate silent-aim toggle. Defaults to test dummies.
- **Teleport:** saved destinations, numeric coordinates, and another player's position. Server checks every request.
- **Players:** searchable names, display names, teams, and live coordinates.
- **ESP:** independent target selection, team-only mode, names/health/distance, through-wall toggle, opacity, and Solid/Lava/Black lava/Rainbow color palettes. Lava themes animate colors on normal Highlights; they are not lava textures.
- **Settings:** shortcuts and version information.

Right Ctrl hides/reopens the workspace. The header is draggable. Buttons and toggles support normal Roblox input. The interface scales down to the viewport; flight movement currently uses a keyboard (WASD, Space up, Left Ctrl down). Closing/reloading removes its own GUI, connections, highlights, labels, and flight constraints, and requests a movement reset.

## Admin configuration in your published game

On **ServerScriptService → FormaServer**, set the **AccessKey** attribute to a private string of at least eight characters. Do not commit that value to GitHub or put it in the client. Set **AdminUserIds** to a comma-separated list of authorized Roblox numeric user IDs. The creator of a user-owned game is also allowed. Group-owned games need explicit admin user IDs. Both an authorized user and the correct key are required. Every movement and teleport request rechecks admin authorization and the verified session.

The public UI/demo key is not a security boundary. The server adapter is. It checks finite numeric values, bounds movement to 0–200, coordinates to ±100000 studs, and applies a short request rate limit. Reset restores the game's original character movement values.

## Destinations and targets

Create a **Workspace → FormaLocations** folder with named BaseParts or Models. Their names appear as teleport choices. A SpawnLocation is automatically exposed as `Spawn`. With no destinations, the displayed Spawn choice reports unavailable until a spawn is added.

Create a **Workspace → TestDummies** folder containing Humanoid Models, or tag those Models **`FormaTarget`** using CollectionService. Aim defaults to those dummies. Aim and ESP each have their own targets dropdown; ESP defaults to players. Team-only ESP shows only teammates with an actual Team assigned.

## Silent aim integration for your own weapon

Silent aim exposes a selected target; it does not hook Roblox, intercept networking, or automatically rewrite another weapon's shots. Your own weapon can use this client-side accessor while keeping hit validation on its server:

```lua
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local gui = playerGui:FindFirstChild("Forma")
local getter = gui and gui:FindFirstChild("GetAimTarget")
local target = getter and getter:Invoke()
-- If target is non-nil, your own weapon can aim its test ray toward target.Position.
-- Validate damage, line of sight, range, and authorization in your weapon's server.
```

If you execute/require the source and retain its returned handle, `handle.GetAimTarget()`, `handle.GetState()`, `handle.SetVisible(true/false)`, and `handle.Destroy()` are also available.

## Validation

Compiled with the official Luau 0.742 compiler. Mocked client checks cover initial/invalid/valid key flow, loading completion, all six pages, minimize/reopen, aim toggle state, and cleanup. Mocked server checks cover non-admin denial, verified-session gate, invalid key, NaN/infinity/range validation, teleport application, flight grants, reset to original movement, throttling, and Studio-only preview access.

Run `LUAU_BIN=/path/to/luau python3 tests/run.py` to repeat the behavioral checks. Real Roblox Studio rendering, network latency, mobile gameplay, and character physics still need a playtest. The implementation follows the tldraw layout and style; no claim of pixel-identical Roblox rendering is made without that playtest.

Icons: [Lucide](https://lucide.dev), ISC license. Upstream SVG source and license are included.
