-- Paste into Studio's Command Bar while not in Play mode. Installs or upgrades.
assert(not game:GetService("RunService"):IsRunning(),"Stop Play mode before installing Forma.")
local HttpService=game:GetService("HttpService")
local base="https://raw.githubusercontent.com/lyhengthoek-bit/Forma-Ai-web/main/roblox/forma/"
local clientSource=HttpService:GetAsync(base.."Client.luau",true)
local serverSource=HttpService:GetAsync(base.."Server.server.luau",true)
assert(#clientSource>1000 and #serverSource>1000,"The downloaded package is incomplete.")
local clientParent=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local serverParent=game:GetService("ServerScriptService")
local client=clientParent:FindFirstChild("FormaClient")
local server=serverParent:FindFirstChild("FormaServer")
assert(not client or client:IsA("LocalScript"),"FormaClient exists and is not a LocalScript.")
assert(not server or server:IsA("Script"),"FormaServer exists and is not a Script.")
client=client or Instance.new("LocalScript");server=server or Instance.new("Script")
client.Name="FormaClient";client.Source=clientSource
server.Name="FormaServer";server.Source=serverSource
if server:GetAttribute("AdminUserIds")==nil then server:SetAttribute("AdminUserIds","")end
if server:GetAttribute("AccessKey")==nil then server:SetAttribute("AccessKey","")end
if server:GetAttribute("TestDamage")==nil then server:SetAttribute("TestDamage",10)end
if server:GetAttribute("AllowFriendlyFire")==nil then server:SetAttribute("AllowFriendlyFire",false)end
server.Parent=serverParent;client.Parent=clientParent
print("Forma installed/upgraded. Press Play, enter FORMA-TEST, then Aim > Equip test blaster.")
