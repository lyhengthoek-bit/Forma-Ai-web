-- Paste into Roblox Studio's Command Bar while NOT in Play mode.
-- Installs normal LocalScript and server Script sources; does not enable loadstring.
assert(not game:GetService("RunService"):IsRunning(),"Stop Play mode before installing Forma.")
local HttpService=game:GetService("HttpService")
local base="https://raw.githubusercontent.com/lyhengthoek-bit/Forma-Ai-web/main/roblox/forma/"
local clientSource=HttpService:GetAsync(base.."Client.luau",true)
local serverSource=HttpService:GetAsync(base.."Server.server.luau",true)
assert(#clientSource>1000 and #serverSource>1000,"The downloaded package is incomplete.")
local clientParent=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local serverParent=game:GetService("ServerScriptService")
assert(not clientParent:FindFirstChild("FormaClient") and not serverParent:FindFirstChild("FormaServer"),"Forma is already installed. Remove FormaClient and FormaServer before reinstalling.")
local client=Instance.new("LocalScript");client.Name="FormaClient";client.Source=clientSource
local server=Instance.new("Script");server.Name="FormaServer";server.Source=serverSource
server:SetAttribute("AdminUserIds","")
-- Keep the real AccessKey attribute private on this server Script.
-- Studio accepts FORMA-TEST. Published games require your private AccessKey.
server:SetAttribute("AccessKey","")
server.Parent=serverParent;client.Parent=clientParent
print("Forma installed. Press Play, then enter FORMA-TEST. Right Ctrl toggles the panel.")
