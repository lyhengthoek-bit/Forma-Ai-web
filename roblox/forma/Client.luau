-- Forma: native Roblox Studio UI. Lucide icons are embedded below as vector strokes.
-- Put this source in a LocalScript, or run it in your existing client loader.
-- Standalone GUI preview key: FORMA-TEST. Admin permissions belong to Server.server.luau.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local localPlayer = Players.LocalPlayer
assert(localPlayer, "Forma requires a client context / LocalScript.")
local playerGui = localPlayer:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("Forma")
if previous then previous:Destroy() end
local C = {white=Color3.fromRGB(255,255,255),ink=Color3.fromRGB(32,32,32),muted=Color3.fromRGB(119,119,119),border=Color3.fromRGB(230,230,230),soft=Color3.fromRGB(246,246,246),red=Color3.fromRGB(176,59,59)}
local connections, temporary, ownedHighlights, ownedLabels = {}, {}, {}, {}
local alive, verified, busy, minimized = true, false, false, false
local state = {speed=16,jump=50,fly=false,flySpeed=50,aim=false,silent=false,smoothing=0.35,fov=120,visibleOnly=true,teamCheck=true,showFov=false,targetMode="Test dummies",targetPart="Torso",esp=false,espTargets="Players",teamOnly=false,names=true,health=true,distance=true,throughWalls=false,glow="Solid",opacity=0.45}
local defaults = table.clone(state)
local remote, selectedPlayer, selectedPreset, aimTarget
local previewOriginal
local presets = {}
local api = {}
local function connect(signal, fn)
 local c=signal:Connect(fn);table.insert(connections,c);return c
end
local function create(kind, props, parent)
 local obj=Instance.new(kind)
 for k,v in pairs(props or {}) do obj[k]=v end
 obj.Parent=parent
 return obj
end
local function round(obj,r) create("UICorner",{CornerRadius=UDim.new(0,r)},obj) end
local function stroke(obj,color) return create("UIStroke",{Color=color or C.border,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},obj) end
local function frame(parent,x,y,w,h,color,r)
 local f=create("Frame",{BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color or C.white},parent)
 if r then round(f,r) end
 return f
end
local function label(parent,text,x,y,w,h,size,color,bold)
 return create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Text=text,Font=bold and Enum.Font.ArialBold or Enum.Font.Arial,TextSize=size or 14,TextColor3=color or C.ink,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd},parent)
end
local function tween(obj,props,duration)
 local t=TweenService:Create(obj,TweenInfo.new(duration or 0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props);t:Play();return t
end
-- Lucide ISC-licensed SVG geometry, converted to native Roblox GUI strokes.
local ICON_PATHS = {
 ["user"] = {{{19.000,21.000},{19.000,19.000},{18.963,18.457},{18.857,17.937},{18.686,17.443},{18.454,16.981},{18.167,16.556},{17.828,16.172},{17.444,15.833},{17.019,15.546},{16.557,15.314},{16.063,15.143},{15.543,15.037},{15.000,15.000},{9.000,15.000},{8.457,15.037},{7.937,15.143},{7.443,15.314},{6.981,15.546},{6.556,15.833},{6.172,16.172},{5.833,16.556},{5.546,16.981},{5.314,17.443},{5.143,17.937},{5.037,18.457},{5.000,19.000},{5.000,21.000}},{{16.000,7.000},{15.966,7.522},{15.864,8.035},{15.696,8.531},{15.464,9.000},{15.173,9.435},{14.828,9.828},{14.435,10.173},{14.000,10.464},{13.531,10.696},{13.035,10.864},{12.522,10.966},{12.000,11.000},{11.478,10.966},{10.965,10.864},{10.469,10.696},{10.000,10.464},{9.565,10.173},{9.172,9.828},{8.827,9.435},{8.536,9.000},{8.304,8.531},{8.136,8.035},{8.034,7.522},{8.000,7.000},{8.034,6.478},{8.136,5.965},{8.304,5.469},{8.536,5.000},{8.827,4.565},{9.172,4.172},{9.565,3.827},{10.000,3.536},{10.469,3.304},{10.965,3.136},{11.478,3.034},{12.000,3.000},{12.522,3.034},{13.035,3.136},{13.531,3.304},{14.000,3.536},{14.435,3.827},{14.828,4.172},{15.173,4.565},{15.464,5.000},{15.696,5.469},{15.864,5.965},{15.966,6.478},{16.000,7.000}}},
 ["crosshair"] = {{{22.000,12.000},{21.914,13.305},{21.659,14.588},{21.239,15.827},{20.660,17.000},{19.934,18.088},{19.071,19.071},{18.088,19.934},{17.000,20.660},{15.827,21.239},{14.588,21.659},{13.305,21.914},{12.000,22.000},{10.695,21.914},{9.412,21.659},{8.173,21.239},{7.000,20.660},{5.912,19.934},{4.929,19.071},{4.066,18.088},{3.340,17.000},{2.761,15.827},{2.341,14.588},{2.086,13.305},{2.000,12.000},{2.086,10.695},{2.341,9.412},{2.761,8.173},{3.340,7.000},{4.066,5.912},{4.929,4.929},{5.912,4.066},{7.000,3.340},{8.173,2.761},{9.412,2.341},{10.695,2.086},{12.000,2.000},{13.305,2.086},{14.588,2.341},{15.827,2.761},{17.000,3.340},{18.088,4.066},{19.071,4.929},{19.934,5.912},{20.660,7.000},{21.239,8.173},{21.659,9.412},{21.914,10.695},{22.000,12.000}},{{22.000,12.000},{18.000,12.000}},{{6.000,12.000},{2.000,12.000}},{{12.000,6.000},{12.000,2.000}},{{12.000,22.000},{12.000,18.000}}},
 ["map-pin"] = {{{20.000,10.000},{19.890,11.250},{19.581,12.496},{19.105,13.724},{18.495,14.921},{17.782,16.074},{16.998,17.170},{16.175,18.195},{15.346,19.136},{14.542,19.980},{13.795,20.714},{13.137,21.325},{12.601,21.799},{12.509,21.860},{12.413,21.911},{12.313,21.950},{12.210,21.977},{12.106,21.994},{12.000,22.000},{11.894,21.994},{11.790,21.977},{11.687,21.950},{11.587,21.911},{11.491,21.860},{11.399,21.799},{10.863,21.325},{10.205,20.714},{9.458,19.980},{8.654,19.136},{7.825,18.195},{7.002,17.170},{6.218,16.074},{5.505,14.921},{4.895,13.724},{4.419,12.496},{4.110,11.250},{4.000,10.000},{4.073,8.914},{4.286,7.873},{4.629,6.886},{5.092,5.962},{5.667,5.111},{6.343,4.343},{7.111,3.667},{7.962,3.092},{8.886,2.629},{9.873,2.286},{10.914,2.073},{12.000,2.000},{13.086,2.073},{14.127,2.286},{15.114,2.629},{16.038,3.092},{16.889,3.667},{17.657,4.343},{18.333,5.111},{18.908,5.962},{19.371,6.886},{19.714,7.873},{19.927,8.914},{20.000,10.000}},{{15.000,10.000},{14.974,10.392},{14.898,10.776},{14.772,11.148},{14.598,11.500},{14.380,11.826},{14.121,12.121},{13.826,12.380},{13.500,12.598},{13.148,12.772},{12.776,12.898},{12.392,12.974},{12.000,13.000},{11.608,12.974},{11.224,12.898},{10.852,12.772},{10.500,12.598},{10.174,12.380},{9.879,12.121},{9.620,11.826},{9.402,11.500},{9.228,11.148},{9.102,10.776},{9.026,10.392},{9.000,10.000},{9.026,9.608},{9.102,9.224},{9.228,8.852},{9.402,8.500},{9.620,8.174},{9.879,7.879},{10.174,7.620},{10.500,7.402},{10.852,7.228},{11.224,7.102},{11.608,7.026},{12.000,7.000},{12.392,7.026},{12.776,7.102},{13.148,7.228},{13.500,7.402},{13.826,7.620},{14.121,7.879},{14.380,8.174},{14.598,8.500},{14.772,8.852},{14.898,9.224},{14.974,9.608},{15.000,10.000}}},
 ["users"] = {{{16.000,21.000},{16.000,19.000},{15.963,18.457},{15.857,17.937},{15.686,17.443},{15.454,16.981},{15.167,16.556},{14.828,16.172},{14.444,15.833},{14.019,15.546},{13.557,15.314},{13.063,15.143},{12.543,15.037},{12.000,15.000},{6.000,15.000},{5.457,15.037},{4.937,15.143},{4.443,15.314},{3.981,15.546},{3.556,15.833},{3.172,16.172},{2.833,16.556},{2.546,16.981},{2.314,17.443},{2.143,17.937},{2.037,18.457},{2.000,19.000},{2.000,21.000}},{{16.000,3.128},{16.430,3.265},{16.835,3.447},{17.212,3.670},{17.561,3.930},{17.877,4.225},{18.160,4.552},{18.405,4.907},{18.611,5.288},{18.776,5.690},{18.897,6.112},{18.971,6.550},{18.996,7.000},{18.971,7.450},{18.897,7.888},{18.776,8.310},{18.611,8.712},{18.405,9.093},{18.160,9.448},{17.877,9.775},{17.561,10.070},{17.212,10.330},{16.835,10.553},{16.430,10.735},{16.000,10.872}},{{22.000,21.000},{22.000,19.000},{21.974,18.550},{21.900,18.112},{21.779,17.690},{21.614,17.288},{21.407,16.907},{21.161,16.552},{20.879,16.226},{20.562,15.931},{20.213,15.671},{19.835,15.448},{19.430,15.267},{19.000,15.130}},{{13.000,7.000},{12.966,7.522},{12.864,8.035},{12.696,8.531},{12.464,9.000},{12.173,9.435},{11.828,9.828},{11.435,10.173},{11.000,10.464},{10.531,10.696},{10.035,10.864},{9.522,10.966},{9.000,11.000},{8.478,10.966},{7.965,10.864},{7.469,10.696},{7.000,10.464},{6.565,10.173},{6.172,9.828},{5.827,9.435},{5.536,9.000},{5.304,8.531},{5.136,8.035},{5.034,7.522},{5.000,7.000},{5.034,6.478},{5.136,5.965},{5.304,5.469},{5.536,5.000},{5.827,4.565},{6.172,4.172},{6.565,3.827},{7.000,3.536},{7.469,3.304},{7.965,3.136},{8.478,3.034},{9.000,3.000},{9.522,3.034},{10.035,3.136},{10.531,3.304},{11.000,3.536},{11.435,3.827},{11.828,4.172},{12.173,4.565},{12.464,5.000},{12.696,5.469},{12.864,5.965},{12.966,6.478},{13.000,7.000}}},
 ["eye"] = {{{2.062,12.348},{2.043,12.291},{2.027,12.234},{2.015,12.176},{2.006,12.118},{2.001,12.059},{1.999,12.000},{2.001,11.941},{2.006,11.882},{2.015,11.824},{2.027,11.766},{2.043,11.709},{2.062,11.652},{2.523,10.676},{3.072,9.762},{3.703,8.915},{4.409,8.139},{5.184,7.438},{6.021,6.817},{6.914,6.280},{7.857,5.831},{8.844,5.474},{9.867,5.214},{10.922,5.055},{12.000,5.001},{13.078,5.055},{14.133,5.214},{15.156,5.474},{16.143,5.831},{17.086,6.280},{17.979,6.817},{18.816,7.438},{19.591,8.139},{20.297,8.915},{20.928,9.762},{21.477,10.676},{21.938,11.652},{21.957,11.709},{21.973,11.766},{21.985,11.824},{21.994,11.882},{21.999,11.941},{22.001,12.000},{21.999,12.059},{21.994,12.118},{21.985,12.176},{21.973,12.234},{21.957,12.291},{21.938,12.348},{21.477,13.324},{20.928,14.238},{20.297,15.085},{19.591,15.861},{18.816,16.562},{17.979,17.183},{17.086,17.720},{16.143,18.169},{15.156,18.526},{14.133,18.786},{13.078,18.945},{12.000,18.999},{10.922,18.945},{9.867,18.786},{8.844,18.526},{7.857,18.169},{6.914,17.720},{6.021,17.183},{5.184,16.562},{4.409,15.861},{3.703,15.085},{3.072,14.238},{2.523,13.324},{2.062,12.348}},{{15.000,12.000},{14.974,12.392},{14.898,12.776},{14.772,13.148},{14.598,13.500},{14.380,13.826},{14.121,14.121},{13.826,14.380},{13.500,14.598},{13.148,14.772},{12.776,14.898},{12.392,14.974},{12.000,15.000},{11.608,14.974},{11.224,14.898},{10.852,14.772},{10.500,14.598},{10.174,14.380},{9.879,14.121},{9.620,13.826},{9.402,13.500},{9.228,13.148},{9.102,12.776},{9.026,12.392},{9.000,12.000},{9.026,11.608},{9.102,11.224},{9.228,10.852},{9.402,10.500},{9.620,10.174},{9.879,9.879},{10.174,9.620},{10.500,9.402},{10.852,9.228},{11.224,9.102},{11.608,9.026},{12.000,9.000},{12.392,9.026},{12.776,9.102},{13.148,9.228},{13.500,9.402},{13.826,9.620},{14.121,9.879},{14.380,10.174},{14.598,10.500},{14.772,10.852},{14.898,11.224},{14.974,11.608},{15.000,12.000}}},
 ["settings"] = {{{9.671,4.136},{9.718,3.842},{9.799,3.562},{9.913,3.298},{10.058,3.053},{10.229,2.828},{10.426,2.626},{10.646,2.449},{10.886,2.300},{11.144,2.180},{11.417,2.091},{11.703,2.036},{12.000,2.017},{12.298,2.036},{12.584,2.091},{12.857,2.180},{13.115,2.300},{13.355,2.449},{13.575,2.626},{13.772,2.828},{13.943,3.053},{14.088,3.298},{14.202,3.562},{14.283,3.842},{14.330,4.136},{14.354,4.324},{14.393,4.508},{14.447,4.687},{14.514,4.861},{14.595,5.028},{14.688,5.188},{14.794,5.341},{14.912,5.484},{15.041,5.618},{15.181,5.742},{15.331,5.855},{15.491,5.957},{15.660,6.045},{15.833,6.118},{16.010,6.178},{16.191,6.222},{16.374,6.252},{16.559,6.268},{16.744,6.268},{16.929,6.254},{17.113,6.226},{17.295,6.182},{17.474,6.124},{17.649,6.051},{17.927,5.945},{18.210,5.877},{18.495,5.844},{18.778,5.847},{19.058,5.884},{19.331,5.953},{19.593,6.055},{19.842,6.188},{20.075,6.351},{20.288,6.543},{20.478,6.764},{20.643,7.011},{20.775,7.277},{20.870,7.552},{20.931,7.832},{20.956,8.115},{20.946,8.397},{20.904,8.676},{20.828,8.947},{20.720,9.207},{20.580,9.455},{20.410,9.685},{20.209,9.896},{19.979,10.084},{19.828,10.199},{19.688,10.325},{19.560,10.461},{19.443,10.606},{19.339,10.759},{19.247,10.920},{19.168,11.088},{19.103,11.261},{19.051,11.440},{19.013,11.623},{18.991,11.810},{18.983,11.999},{18.991,12.189},{19.013,12.376},{19.051,12.559},{19.103,12.738},{19.168,12.911},{19.247,13.079},{19.339,13.240},{19.443,13.393},{19.560,13.538},{19.688,13.674},{19.828,13.800},{19.979,13.915},{20.209,14.103},{20.410,14.314},{20.580,14.544},{20.720,14.792},{20.828,15.052},{20.904,15.323},{20.946,15.602},{20.956,15.884},{20.931,16.167},{20.870,16.447},{20.775,16.722},{20.643,16.988},{20.478,17.235},{20.288,17.456},{20.075,17.648},{19.842,17.811},{19.593,17.944},{19.331,18.046},{19.058,18.115},{18.778,18.152},{18.495,18.155},{18.210,18.122},{17.927,18.054},{17.649,17.948},{17.474,17.875},{17.295,17.817},{17.113,17.773},{16.929,17.745},{16.744,17.731},{16.559,17.731},{16.374,17.747},{16.191,17.777},{16.010,17.821},{15.833,17.881},{15.660,17.954},{15.491,18.042},{15.331,18.144},{15.181,18.257},{15.041,18.381},{14.912,18.515},{14.794,18.658},{14.688,18.811},{14.595,18.971},{14.514,19.138},{14.447,19.312},{14.393,19.491},{14.354,19.675},{14.330,19.863},{14.283,20.157},{14.202,20.437},{14.088,20.701},{13.943,20.946},{13.772,21.171},{13.575,21.373},{13.355,21.550},{13.115,21.699},{12.857,21.819},{12.584,21.908},{12.298,21.963},{12.001,21.982},{11.703,21.963},{11.417,21.908},{11.144,21.819},{10.886,21.699},{10.646,21.550},{10.426,21.373},{10.229,21.171},{10.058,20.946},{9.913,20.701},{9.799,20.437},{9.718,20.157},{9.671,19.863},{9.647,19.675},{9.608,19.491},{9.554,19.311},{9.487,19.138},{9.406,18.970},{9.313,18.810},{9.207,18.658},{9.089,18.514},{8.960,18.380},{8.820,18.256},{8.670,18.143},{8.509,18.042},{8.341,17.954},{8.168,17.880},{7.990,17.821},{7.810,17.776},{7.626,17.746},{7.442,17.731},{7.256,17.730},{7.071,17.744},{6.887,17.773},{6.705,17.816},{6.526,17.875},{6.351,17.948},{6.073,18.054},{5.790,18.122},{5.505,18.155},{5.222,18.152},{4.942,18.115},{4.669,18.046},{4.407,17.944},{4.158,17.811},{3.925,17.648},{3.712,17.456},{3.522,17.235},{3.357,16.988},{3.225,16.722},{3.130,16.447},{3.069,16.167},{3.044,15.884},{3.054,15.602},{3.096,15.323},{3.172,15.052},{3.280,14.792},{3.420,14.544},{3.590,14.314},{3.791,14.103},{4.021,13.915},{4.172,13.800},{4.312,13.674},{4.440,13.538},{4.557,13.393},{4.661,13.240},{4.753,13.079},{4.832,12.911},{4.897,12.738},{4.949,12.559},{4.987,12.376},{5.009,12.189},{5.017,11.999},{5.009,11.810},{4.987,11.623},{4.949,11.440},{4.897,11.261},{4.832,11.088},{4.753,10.920},{4.661,10.759},{4.557,10.606},{4.440,10.461},{4.312,10.325},{4.172,10.199},{4.021,10.084},{3.791,9.896},{3.591,9.685},{3.421,9.455},{3.281,9.208},{3.174,8.947},{3.098,8.676},{3.055,8.398},{3.046,8.116},{3.071,7.833},{3.131,7.553},{3.227,7.279},{3.359,7.013},{3.523,6.765},{3.713,6.545},{3.926,6.353},{4.158,6.190},{4.407,6.057},{4.669,5.955},{4.942,5.885},{5.221,5.848},{5.505,5.846},{5.790,5.878},{6.072,5.946},{6.350,6.051},{6.525,6.124},{6.704,6.182},{6.886,6.226},{7.070,6.254},{7.255,6.268},{7.440,6.268},{7.625,6.252},{7.808,6.222},{7.989,6.178},{8.166,6.118},{8.339,6.045},{8.508,5.957},{8.668,5.855},{8.818,5.742},{8.958,5.618},{9.087,5.484},{9.205,5.341},{9.311,5.188},{9.404,5.028},{9.485,4.861},{9.552,4.687},{9.606,4.508},{9.645,4.324},{9.669,4.136}},{{15.000,12.000},{14.974,12.392},{14.898,12.776},{14.772,13.148},{14.598,13.500},{14.380,13.826},{14.121,14.121},{13.826,14.380},{13.500,14.598},{13.148,14.772},{12.776,14.898},{12.392,14.974},{12.000,15.000},{11.608,14.974},{11.224,14.898},{10.852,14.772},{10.500,14.598},{10.174,14.380},{9.879,14.121},{9.620,13.826},{9.402,13.500},{9.228,13.148},{9.102,12.776},{9.026,12.392},{9.000,12.000},{9.026,11.608},{9.102,11.224},{9.228,10.852},{9.402,10.500},{9.620,10.174},{9.879,9.879},{10.174,9.620},{10.500,9.402},{10.852,9.228},{11.224,9.102},{11.608,9.026},{12.000,9.000},{12.392,9.026},{12.776,9.102},{13.148,9.228},{13.500,9.402},{13.826,9.620},{14.121,9.879},{14.380,10.174},{14.598,10.500},{14.772,10.852},{14.898,11.224},{14.974,11.608},{15.000,12.000}}},
 ["x"] = {{{18.000,6.000},{6.000,18.000}},{{6.000,6.000},{18.000,18.000}}},
 ["minus"] = {{{5.000,12.000},{19.000,12.000}}},
 ["chevron-down"] = {{{6.000,9.000},{12.000,15.000},{18.000,9.000}}},
 ["arrow-right"] = {{{5.000,12.000},{19.000,12.000}},{{12.000,5.000},{19.000,12.000},{12.000,19.000}}},
 ["check"] = {{{20.000,6.000},{9.000,17.000},{4.000,12.000}}},
 ["shield-check"] = {{{20.000,13.000},{19.929,14.199},{19.721,15.298},{19.388,16.304},{18.939,17.220},{18.383,18.053},{17.730,18.806},{16.991,19.486},{16.175,20.096},{15.292,20.643},{14.352,21.131},{13.365,21.565},{12.340,21.950},{12.285,21.967},{12.230,21.980},{12.174,21.991},{12.117,21.998},{12.061,22.002},{12.004,22.003},{11.948,22.000},{11.891,21.995},{11.835,21.986},{11.779,21.974},{11.724,21.958},{11.670,21.940},{10.643,21.557},{9.654,21.125},{8.712,20.639},{7.828,20.093},{7.011,19.484},{6.271,18.805},{5.618,18.052},{5.062,17.220},{4.612,16.304},{4.279,15.298},{4.071,14.199},{4.000,13.000},{4.000,6.000},{4.009,5.864},{4.036,5.734},{4.079,5.611},{4.137,5.495},{4.208,5.389},{4.293,5.293},{4.389,5.208},{4.495,5.137},{4.611,5.079},{4.734,5.036},{4.864,5.009},{5.000,5.000},{5.510,4.976},{6.036,4.904},{6.574,4.789},{7.120,4.633},{7.669,4.439},{8.217,4.210},{8.760,3.950},{9.293,3.661},{9.812,3.346},{10.312,3.009},{10.790,2.653},{11.240,2.280},{11.353,2.194},{11.474,2.124},{11.601,2.070},{11.731,2.031},{11.865,2.007},{12.000,2.000},{12.135,2.007},{12.269,2.031},{12.399,2.070},{12.526,2.124},{12.647,2.194},{12.760,2.280},{13.212,2.655},{13.691,3.013},{14.192,3.350},{14.711,3.665},{15.244,3.954},{15.786,4.214},{16.334,4.442},{16.882,4.635},{17.427,4.790},{17.965,4.905},{18.491,4.976},{19.000,5.000},{19.136,5.009},{19.266,5.036},{19.389,5.079},{19.505,5.137},{19.611,5.208},{19.707,5.293},{19.792,5.389},{19.863,5.495},{19.921,5.611},{19.964,5.734},{19.991,5.864},{20.000,6.000},{20.000,13.000},{20.000,13.000}},{{9.000,12.000},{11.000,14.000},{15.000,10.000}}},
 ["external-link"] = {{{15.000,3.000},{21.000,3.000},{21.000,9.000}},{{10.000,14.000},{21.000,3.000}},{{18.000,13.000},{18.000,19.000},{17.982,19.271},{17.929,19.532},{17.843,19.778},{17.727,20.009},{17.583,20.222},{17.414,20.414},{17.222,20.583},{17.009,20.727},{16.778,20.843},{16.532,20.929},{16.271,20.982},{16.000,21.000},{5.000,21.000},{4.729,20.982},{4.468,20.929},{4.222,20.843},{3.991,20.727},{3.778,20.583},{3.586,20.414},{3.417,20.222},{3.273,20.009},{3.157,19.778},{3.071,19.532},{3.018,19.271},{3.000,19.000},{3.000,8.000},{3.018,7.729},{3.071,7.468},{3.157,7.222},{3.273,6.991},{3.417,6.778},{3.586,6.586},{3.778,6.417},{3.991,6.273},{4.222,6.157},{4.468,6.071},{4.729,6.018},{5.000,6.000},{11.000,6.000}}},
 ["rotate-ccw"] = {{{3.000,12.000},{3.082,13.221},{3.321,14.393},{3.707,15.503},{4.229,16.542},{4.875,17.500},{5.636,18.364},{6.500,19.125},{7.458,19.771},{8.497,20.293},{9.607,20.679},{10.779,20.918},{12.000,21.000},{13.221,20.918},{14.393,20.679},{15.503,20.293},{16.542,19.771},{17.500,19.125},{18.364,18.364},{19.125,17.500},{19.771,16.542},{20.293,15.503},{20.679,14.393},{20.918,13.221},{21.000,12.000},{20.918,10.779},{20.679,9.607},{20.293,8.497},{19.771,7.458},{19.125,6.500},{18.364,5.636},{17.500,4.875},{16.542,4.229},{15.503,3.707},{14.393,3.321},{13.221,3.082},{12.000,3.000},{11.373,3.023},{10.753,3.085},{10.140,3.186},{9.536,3.326},{8.944,3.503},{8.365,3.718},{7.800,3.968},{7.252,4.254},{6.722,4.575},{6.213,4.930},{5.725,5.319},{5.260,5.740},{3.000,8.000}},{{3.000,3.000},{3.000,8.000},{8.000,8.000}}},
}

local function icon(parent,name,x,y,size,color)
 local container=frame(parent,x,y,size,size);container.BackgroundTransparency=1
 container.Name="Lucide_"..name
 local thickness=size/24*1.8
 for _,path in ipairs(ICON_PATHS[name] or {}) do
  for i=2,#path do
   local a,b=path[i-1],path[i];local dx,dy=(b[1]-a[1])*size/24,(b[2]-a[2])*size/24
   local length=math.sqrt(dx*dx+dy*dy)
   if length>0.01 then
    local line=frame(container,(a[1]+b[1])*size/48,(a[2]+b[2])*size/48,length+0.6,thickness,color or C.muted,thickness/2)
    line.AnchorPoint=Vector2.new(0.5,0.5);line.Rotation=math.deg(math.atan2(dy,dx))
   end
  end
 end
 return container
end
local function button(parent,text,x,y,w,h,primary,iconName)
 local b=create("TextButton",{AutoButtonColor=false,BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=primary and C.ink or C.soft,Text=text,Font=Enum.Font.ArialBold,TextSize=14,TextColor3=primary and C.white or C.ink},parent);round(b,6)
 if iconName then icon(b,iconName,w-30,(h-16)/2,16,primary and C.white or C.muted) end
 connect(b.MouseEnter,function() if alive then tween(b,{BackgroundColor3=primary and Color3.fromRGB(50,50,50) or Color3.fromRGB(237,237,237)}) end end)
 connect(b.MouseLeave,function() if alive then tween(b,{BackgroundColor3=primary and C.ink or C.soft}) end end)
 return b
end
local function iconButton(parent,name,x,y,fn)
 local b=button(parent,"",x,y,28,28,false);b.BackgroundTransparency=1
 icon(b,name,6,6,16,C.muted)
 connect(b.Activated,fn)
 return b
end
local function input(parent,placeholder,x,y,w,h)
 local box=create("TextBox",{BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h or 38),BackgroundColor3=C.white,Text="",PlaceholderText=placeholder,PlaceholderColor3=Color3.fromRGB(153,153,153),TextColor3=C.ink,TextSize=14,Font=Enum.Font.Arial,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},parent)
 round(box,6);local s=stroke(box)
 create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},box)
 connect(box.Focused,function() tween(s,{Color=Color3.fromRGB(150,150,150)}) end)
 connect(box.FocusLost,function() tween(s,{Color=C.border}) end)
 return box
end
local gui=create("ScreenGui",{Name="Forma",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=30,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
local root=frame(gui,0,0,1000,560);root.Name="Workspace";root.AnchorPoint=Vector2.new(0.5,0.5);root.Position=UDim2.fromScale(0.5,0.5);round(root,12);stroke(root);root.Visible=false
local rootScale=create("UIScale",{Scale=1},root)
local access=frame(gui,0,0,440,340);access.Name="Access";access.AnchorPoint=Vector2.new(0.5,0.5);access.Position=UDim2.fromScale(0.5,0.5);round(access,12);stroke(access)
local accessScale=create("UIScale",{Scale=1},access)
label(access,"Forma",28,22,200,24,13,C.ink,true)
label(access,"Enter your key",28,70,384,30,24,C.ink,true)
label(access,"Use your access key to continue.",28,105,384,24,14,C.muted)
label(access,"Access key",28,144,384,22,13)
local key=input(access,"Enter key",28,170,384,44);key.Name="KeyInput"
local continueButton=button(access,"Continue",28,230,384,44,true);continueButton.Name="Continue"
local keyStatus=label(access,"",28,215,384,14,11,C.red)
local getKey=button(access,"Get a key",160,294,120,24,false);getKey.BackgroundTransparency=1;getKey.TextColor3=C.muted;getKey.Font=Enum.Font.Arial;getKey.TextSize=13
local loading=frame(gui,0,0,440,176);loading.Name="Loading";loading.AnchorPoint=Vector2.new(0.5,0.5);loading.Position=UDim2.fromScale(0.5,0.5);round(loading,12);stroke(loading);loading.Visible=false
local loadingScale=create("UIScale",{Scale=1},loading)
label(loading,"Forma",28,22,300,22,13,C.ink,true)
label(loading,"Preparing your workspace",28, 60,384,28,22,C.ink,true)
local loadingText=label(loading,"Access verified. Loading controls…",28,93,384,22,13,C.muted)
local track=frame(loading,28,135,384,3,C.border,2)
local progress=frame(track,0,0,0,3,C.ink,2)
local header=frame(root,0,0,1000,56);header.BackgroundTransparency=1
label(header,"Forma",24,17,130,22,14,C.ink,true)
local sessionLabel=label(header,"test mode",772,17,132,22,12,C.muted);sessionLabel.TextXAlignment=Enum.TextXAlignment.Right
frame(root,0,56,1000,1,C.border)
local sidebar=frame(root,0,57,166,502);sidebar.BackgroundTransparency=1
frame(root,166,57,1,502,C.border)
label(sidebar,"Private test session",20,460,132,22,11,C.muted)
local footer=frame(root,167,516,833,44);footer.BackgroundTransparency=1
frame(footer,24,0,785,1,C.border)
local status=label(footer,"Ready",24,11,590,22,12,C.muted)
local resetButton=button(footer,"Reset defaults",676,8,133,28,false);resetButton.BackgroundTransparency=1;resetButton.TextSize=12;resetButton.Font=Enum.Font.Arial
local pages, navButtons = {}, {}
local function notify(text,isError)
 status.Text=text;status.TextColor3=isError and C.red or C.muted
end
local function page(name,subtitle,height)
 local p=create("ScrollingFrame",{Name=name,Position=UDim2.fromOffset(191,78),Size=UDim2.fromOffset(785,426),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.fromOffset(0,height or 424),Visible=false},root)
 label(p,name,0,0,730,30,24,C.ink,true);label(p,subtitle,0,36,780,24,13,C.muted);pages[name]=p;return p
end
local function card(parent,title,x,y,w,h)
 local f=frame(parent,x,y,w,h,C.white,7);stroke(f,Color3.fromRGB(237,237,237));label(f,title,18,12,w-36,24,14,C.ink,true);return f
end
local function rule(parent,y,w) frame(parent,18,y,w-36,1,Color3.fromRGB(240,240,240)) end
local refreshers={}
local function toggle(parent,text,x,y,width,stateKey,fn)
 label(parent,text,x,y,width-64,26,13)
 local b=button(parent,"",x+width-38,y+3,34,20,false);round(b,10)
 local dot=frame(b,3,3,14,14,C.white,7)
 local function refresh() b.BackgroundColor3=state[stateKey] and C.ink or Color3.fromRGB(227,227,227);dot.Position=UDim2.fromOffset(state[stateKey] and 17 or 3,3) end
 table.insert(refreshers,refresh);refresh()
 connect(b.Activated,function()
  local old=state[stateKey];state[stateKey]=not old;refresh()
  if fn then fn(state[stateKey],function() state[stateKey]=old;refresh() end) end
 end)
 return b
end
local function check(parent,text,x,y,w,stateKey)
 local b=button(parent,"",x,y,16,16,false);round(b,3);local mark=icon(b,"check",2,2,12,C.white)
 label(parent,text,x+23,y-4,w-23,24,12)
 local function refresh() b.BackgroundColor3=state[stateKey] and C.ink or C.border;mark.Visible=state[stateKey] end
 table.insert(refreshers,refresh);refresh();connect(b.Activated,function() state[stateKey]=not state[stateKey];refresh() end)
end
local activeMenu
local dropdownCount=0
local function closeMenu()
 if activeMenu then activeMenu:Destroy();activeMenu=nil end
end
local function dropdown(parent,x,y,w,choices,value,changed)
 local selected=value or choices[1]
 dropdownCount+=1
 local b=button(parent,selected or "None",x,y,w,30,false,"chevron-down");b.Name="Select"..dropdownCount;b.Font=Enum.Font.Arial;b.TextSize=12
 create("UIPadding",{PaddingRight=UDim.new(0,22),PaddingLeft=UDim.new(0,7)},b)
 connect(b.Activated,function()
  if activeMenu and activeMenu.Name=="Menu_"..b:GetFullName() then closeMenu();return end
  closeMenu()
  local shade=create("TextButton",{Name="Menu_"..b:GetFullName(),Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=50},gui)
  activeMenu=shade;connect(shade.Activated,closeMenu)
  local scale=b.AbsoluteSize.X/w
  local height=math.min(#choices*32+8,232)
  local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1440,900)
  local py=b.AbsolutePosition.Y+b.AbsoluteSize.Y+4
  if py+height*scale>viewport.Y-12 then py=b.AbsolutePosition.Y-height*scale-4 end
  local popup=frame(shade,b.AbsolutePosition.X,py,w,height,C.white,6);popup.ZIndex=51;stroke(popup)
  create("UIScale",{Scale=scale},popup)
  local scroller=create("ScrollingFrame",{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(w-8,height-8),CanvasSize=UDim2.fromOffset(0,#choices*32),ScrollBarThickness=2,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=52},popup)
  for i,choice in ipairs(choices)do
   local option=button(scroller,choice,0,(i-1)*32,w-8,30,false);option.ZIndex=53;option.BackgroundTransparency=choice==selected and 0 or 1;option.TextXAlignment=Enum.TextXAlignment.Left;option.TextSize=12;option.Font=Enum.Font.Arial
   create("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},option)
   connect(option.Activated,function()selected=choice;b.Text=choice;closeMenu();changed(choice)end)
  end
 end)
 return b,function(newChoices,newValue)
  choices=newChoices;selected=newValue or choices[1];b.Text=selected or "None"
 end
end
local function numberField(parent,text,x,y,w,stateKey,min,max,changed)
 label(parent,text,x,y,w-88,30,13)
 local box=input(parent,"",x+w-68,y,68,30);box.Text=tostring(state[stateKey]);box.TextSize=13
 local function refresh() box.Text=tostring(state[stateKey]) end;table.insert(refreshers,refresh)
 connect(box.FocusLost,function()
  local n=tonumber(box.Text)
  if not n or n~=n or math.abs(n)==math.huge then refresh();notify("Enter a valid number.",true);return end
  local old=state[stateKey];state[stateKey]=math.clamp(n,min,max);refresh()
  if changed then changed(state[stateKey],function() state[stateKey]=old;refresh() end) end
 end)
 return box
end
local function slider(parent,text,x,y,w,stateKey,min,max,format)
 label(parent,text,x,y,w,24,13)
 local value=label(parent,"",x+w-55,y,55,24,12,C.muted);value.TextXAlignment=Enum.TextXAlignment.Right
 local rail=button(parent,"",x,y+35,w,4,false);rail.BackgroundColor3=C.border
 local fill=frame(rail,0,0,1,4,C.ink,2)
 local dot=frame(rail,0,-3,10,10,C.ink,5);dot.AnchorPoint=Vector2.new(0.5,0)
 local dragging=false
 local function refresh() local f=(state[stateKey]-min)/(max-min);fill.Size=UDim2.new(f,0,1,0);dot.Position=UDim2.new(f,0,0,-3);value.Text=format and format(state[stateKey]) or tostring(math.round(state[stateKey])) end
 local function update(position)
  local f=math.clamp((position.X-rail.AbsolutePosition.X)/math.max(rail.AbsoluteSize.X,1),0,1);state[stateKey]=min+f*(max-min);refresh()
 end
 local hit=button(parent,"",x,y+24,w,26,false);hit.BackgroundTransparency=1
 connect(hit.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;update(i.Position) end end)
 connect(UserInputService.InputChanged,function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i.Position) end end)
 connect(UserInputService.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
 table.insert(refreshers,refresh);refresh()
end
local function characterParts()
 local char=localPlayer.Character;if not char then return end
 return char,char:FindFirstChildOfClass("Humanoid"),char:FindFirstChild("HumanoidRootPart")
end
local function resolveRemote()
 local folder=ReplicatedStorage:FindFirstChild("FormaAdmin")
 local candidate=folder and folder:FindFirstChild("Request")
 remote=candidate and candidate:IsA("RemoteFunction") and candidate or nil
end
local function request(action,data)
 resolveRemote()
 if remote then
  local ok,result=pcall(function() return remote:InvokeServer(action,data or {}) end)
  if ok and type(result)=="table" then return result end
  return {ok=false,message="Server unavailable. Try again."}
 end
 -- The demo key unlocks the frontend flow, not server admin permissions.
 -- When a server adapter exists, its verification result above remains authoritative.
 if action=="verify" then return {ok=data.key=="FORMA-TEST",message="Invalid key. Preview key: FORMA-TEST",presets={"Spawn"},mode="GUI preview"} end
 if not RunService:IsStudio() then return {ok=false,message="GUI preview: admin commands need the server adapter."} end
 if not verified then return {ok=false,message="Verify your key first."} end
 local char,hum,hrp=characterParts()
 if action=="movement" then
  if not hum then return {ok=false,message="Character not ready."} end
  if not previewOriginal or previewOriginal.hum~=hum then previewOriginal={hum=hum,speed=hum.WalkSpeed,jump=hum.JumpPower,useJumpPower=hum.UseJumpPower} end
  hum.WalkSpeed=data.speed;hum.UseJumpPower=true;hum.JumpPower=data.jump
 elseif action=="reset" then
  if previewOriginal and previewOriginal.hum.Parent then local old=previewOriginal;old.hum.WalkSpeed=old.speed;old.hum.JumpPower=old.jump;old.hum.UseJumpPower=old.useJumpPower end
  previewOriginal=nil
 elseif action=="teleport" then
  if not hrp or not char then return {ok=false,message="Character not ready."} end
  local dest
  if data.preset then local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation",true);dest=spawn and spawn.Position+Vector3.new(0,4,0)
  elseif data.playerId then local p=Players:GetPlayerByUserId(data.playerId);local r=p and p.Character and p.Character:FindFirstChild("HumanoidRootPart");dest=r and r.Position+Vector3.new(3,0,0)
  elseif data.x then dest=Vector3.new(data.x,data.y,data.z) end
  if not dest then return {ok=false,message="Destination unavailable."} end
  char:PivotTo(CFrame.new(dest));hrp.AssemblyLinearVelocity=Vector3.zero
 end
 return {ok=true,message="Updated"}
end
local flightAttachment,flightVelocity,flightOrientation
local function stopFlight()
 for _,obj in ipairs({flightVelocity,flightOrientation,flightAttachment}) do if obj then obj:Destroy() end end
 flightVelocity=nil;flightOrientation=nil;flightAttachment=nil
 local _,hum=characterParts();if hum then hum.AutoRotate=true end
end
local function startFlight()
 stopFlight();local _,hum,hrp=characterParts();if not hum or not hrp then return false end
 flightAttachment=create("Attachment",{Name="FormaFlight"},hrp)
 flightVelocity=create("LinearVelocity",{Name="FormaFlightVelocity",Attachment0=flightAttachment,MaxForce=math.huge,VectorVelocity=Vector3.zero,RelativeTo=Enum.ActuatorRelativeTo.World},hrp)
 flightOrientation=create("AlignOrientation",{Name="FormaFlightOrientation",Attachment0=flightAttachment,Mode=Enum.OrientationAlignmentMode.OneAttachment,MaxTorque=math.huge,Responsiveness=18},hrp)
 hum.AutoRotate=false;return true
end
local function movementChanged(_,revert)
 task.spawn(function() local result=request("movement",{speed=state.speed,jump=state.jump});if not alive then return end;if not result.ok then revert() end;notify(result.ok and "Movement updated" or result.message,not result.ok) end)
end
local function flightChanged(enabled,revert)
 task.spawn(function()
  local result=request("flight",{enabled=enabled})
  if not alive then return end
  if not result.ok then revert();notify(result.message,true);return end
  if enabled then if not startFlight() then revert();notify("Character not ready.",true);return end else stopFlight() end
  notify(enabled and "Flight enabled · WASD / Space / Ctrl" or "Flight disabled")
 end)
end
local playerPage=page("Player","Movement controls for your test session.")
local movementCard=card(playerPage,"Movement",0,78,384,162)
numberField(movementCard,"Walk speed",18, 50,348,"speed",0,200,movementChanged);rule(movementCard,91,384)
numberField(movementCard,"Jump power",18,106,348,"jump",0,200,movementChanged)
local flightCard=card(playerPage,"Flight",400,78,384,162)
toggle(flightCard,"Enable fly",18,50,348,"fly",flightChanged);rule(flightCard,91,384)
numberField(flightCard,"Fly speed",18,106,348,"flySpeed",1,200)
local quick=card(playerPage,"Quick teleport",0,256,784,134)
label(quick,"Choose a saved destination or enter coordinates.",18,37,748,22,12,C.muted)
local _,updatePreset=dropdown(quick,18,68,182,{"Spawn"},"Spawn",function(value)selectedPreset=value end);selectedPreset="Spawn"
local go=button(quick,"Go",212,68,76,30,true)
local coords=label(quick,"Current location: waiting for character",18,104,748,20,12,C.muted)
connect(go.Activated,function() task.spawn(function() local r=request("teleport",{preset=selectedPreset});if alive then notify(r.ok and "Teleported to "..selectedPreset or r.message,not r.ok) end end) end)
label(quick,"Use Teleport for coordinates and player destinations.",308,68,450,30,12,C.muted)
local aimPage=page("Aim","Configure targeting for your game's test session.")
local aimCard=card(aimPage,"Aim assist / aimbot",0,78,384,218)
toggle(aimCard,"Enable aim assist",18, 50,348,"aim")
rule(aimCard,89,384);label(aimCard,"Activation",18,101,150,30,13)
dropdown(aimCard,188,101,178,{"Hold right mouse","Always"},"Hold right mouse",function(v)state.activation=v end);state.activation="Hold right mouse"
slider(aimCard,"Smoothing",18,149,348,"smoothing",0,1,function(v)return string.format("%.2f",v)end)
local silentCard=card(aimPage,"Silent aim",400,78,384,218)
toggle(silentCard,"Enable silent aim",18,50,348,"silent");rule(silentCard,89,384)
label(silentCard,"Target part",18,101,150,30,13)
dropdown(silentCard,188,101,178,{"Torso","Head","Root"},"Torso",function(v)state.targetPart=v end)
label(silentCard,"Returns a target to your own weapon script.",18,151,348,22,12,C.muted)
label(silentCard,"Camera direction stays unchanged.",18,174,348,22,12,C.muted)
local targeting=card(aimPage,"Targeting",0,312,784,92)
label(targeting,"Targets",18,50,52,26,12,C.muted)
local _,updateTargets=dropdown(targeting,72,48,128,{"Test dummies","Players"},"Test dummies",function(v)state.targetMode=v end)
numberField(targeting,"FOV",215,48,133,"fov",20,500)
check(targeting,"Visible only",370,55,116,"visibleOnly");check(targeting,"Team check",493,55,113,"teamCheck");check(targeting,"Show FOV",625,55,119,"showFov")
local teleportPage=page("Teleport","Choose a destination in your own game.",468)
local destinations=card(teleportPage,"Saved destinations",0,78,784,100)
local _,updateTeleportPreset=dropdown(destinations,18, 50,580,{"Spawn"},"Spawn",function(v) selectedPreset=v;updatePreset(presets,v) end)
local presetGo=button(destinations,"Teleport",614,50,152,30,true)
connect(presetGo.Activated,function() task.spawn(function()local r=request("teleport",{preset=selectedPreset});if alive then notify(r.ok and "Destination reached" or r.message,not r.ok)end end)end)
local custom=card(teleportPage,"Coordinates",0,194,784,138)
label(custom,"X",18,48,20,26,12,C.muted);local xInput=input(custom,"0",40,46,180,32)
label(custom,"Y",238,48,20,26,12,C.muted);local yInput=input(custom,"10",260,46,180,32)
label(custom,"Z",458,48,20,26,12,C.muted);local zInput=input(custom,"0",480,46,180,32)
local coordGo=button(custom,"Go",678,46,88,32,true)
local currentLocation=label(custom,"Current location: waiting for character",18,94,610,22,12,C.muted)
local useCurrent=button(custom,"Use current",642,92,124,26,false);useCurrent.TextSize=12
connect(useCurrent.Activated,function()local _,_,hrp=characterParts();if hrp then xInput.Text=tostring(math.round(hrp.Position.X));yInput.Text=tostring(math.round(hrp.Position.Y));zInput.Text=tostring(math.round(hrp.Position.Z))end end)
connect(coordGo.Activated,function()
 local x,y,z=tonumber(xInput.Text),tonumber(yInput.Text),tonumber(zInput.Text)
 for _,n in ipairs({x or math.huge,y or math.huge,z or math.huge}) do if n~=n or math.abs(n)>100000 then notify("Coordinates must be numbers between -100000 and 100000.",true);return end end
 task.spawn(function()local r=request("teleport",{x=x,y=y,z=z});if alive then notify(r.ok and "Coordinates reached" or r.message,not r.ok)end end)
end)
local targetPlayerCard=card(teleportPage,"Player destination",0,348,784,92)
local playerNames,playerByName={},{}
local _,updatePlayerDropdown=dropdown(targetPlayerCard,18,48,580,{"Select a player"},nil,function(v)selectedPlayer=playerByName[v]end)
local playerGo=button(targetPlayerCard,"Teleport",614,48,152,30,true)
connect(playerGo.Activated,function() if not selectedPlayer then notify("Select another player first.",true);return end;task.spawn(function()local r=request("teleport",{playerId=selectedPlayer.UserId});if alive then notify(r.ok and "Player destination reached" or r.message,not r.ok)end end)end)
local playersPage=page("Players","Names, teams, and current locations.",480)
local listSearch=input(playersPage,"Search name…",0,78,784,36)
local list=frame(playersPage,0,130,784,300);list.BackgroundTransparency=1
local playerRows={}
local function refreshPlayers()
 if not alive then return end
 table.clear(playerNames);table.clear(playerByName)
 local all=Players:GetPlayers();table.sort(all,function(a,b)return a.Name:lower()<b.Name:lower()end)
 for _,obj in ipairs(playerRows)do obj:Destroy()end;table.clear(playerRows)
 local y=0;local query=listSearch.Text:lower()
 for _,p in ipairs(all)do
  if p~=localPlayer then local display=p.DisplayName.." (@"..p.Name..")";table.insert(playerNames,display);playerByName[display]=p end
  if p.Name:lower():find(query,1,true) or p.DisplayName:lower():find(query,1,true) then
   local row=frame(list,0,y,784,62,C.white,6);stroke(row);table.insert(playerRows,row)
   label(row,p.DisplayName.."  @"..p.Name,16,7,365,23,13,C.ink,true)
   label(row,p.Team and p.Team.Name or "No team",16,31,300,20,12,C.muted)
   local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   label(row,hrp and string.format("x %.1f   y %.1f   z %.1f",hrp.Position.X,hrp.Position.Y,hrp.Position.Z) or "Character unavailable",350,15,416,30,12,C.muted)
   y+=72
  end
 end
 playersPage.CanvasSize=UDim2.fromOffset(0,math.max(426,138+y));list.Size=UDim2.fromOffset(784,math.max(300,y))
 if #playerNames==0 then table.insert(playerNames,"No other players")end
 if selectedPlayer and not selectedPlayer.Parent then selectedPlayer=nil end
 updatePlayerDropdown(playerNames,selectedPlayer and selectedPlayer.DisplayName.." (@"..selectedPlayer.Name..")" or nil)
end
connect(listSearch:GetPropertyChangedSignal("Text"),refreshPlayers)
connect(Players.PlayerAdded,refreshPlayers);connect(Players.PlayerRemoving,function()task.defer(refreshPlayers)end)
local espPage=page("ESP","Inspect players and test dummies in your game.")
local espCard=card(espPage,"Visibility",0,78,384,218)
toggle(espCard,"Enable ESP",18,50,348,"esp");rule(espCard,90,384)
toggle(espCard,"Team ESP only",18,101,348,"teamOnly")
toggle(espCard,"Show through walls",18,139,348,"throughWalls")
check(espCard,"Names",18,185,95,"names");check(espCard,"Health",130,185,95,"health");check(espCard,"Distance",240,185,112,"distance")
local glowCard=card(espPage,"Glow",400,78,384,218)
label(glowCard,"Style",18, 50,130,30,13)
local _,updateGlow=dropdown(glowCard,166,50,200,{"Solid","Lava","Black lava","Rainbow"},"Solid",function(v)state.glow=v end)
slider(glowCard,"Fill opacity",18,101,348,"opacity",0,1,function(v)return string.format("%d%%",math.round(v*100))end)
label(glowCard,"Animated color palettes, subtle outlines.",18,174,348,22,12,C.muted)
local espInfo=card(espPage,"Display",0,312,784,92)
label(espInfo,"Targets",18,48,56,30,12,C.muted)
local _,updateEspTargets=dropdown(espInfo,80,48,180,{"Players","Test dummies"},"Players",function(v)state.espTargets=v end)
label(espInfo,"Highlights follow characters after respawn.",278,48,480,30,12,C.muted)
local settingsPage=page("Settings","Simple controls for your workspace.")
local settingsCard=card(settingsPage,"Interface",0,78,784,168)
label(settingsCard,"Toggle panel",18,51,340,30,13);label(settingsCard,"Right Ctrl",600,51,166,30,13,C.muted)
label(settingsCard,"Flight controls",18,95,340,30,13);label(settingsCard,"WASD · Space · Ctrl",540,95,226,30,13,C.muted)
local about=card(settingsPage,"About",0,262,784,100)
label(about,"Forma 1.0 · Roblox Studio test tools",18, 40,746,22,13,C.muted)
label(about,"Lucide icons · ISC license",18,64,746,20,12,C.muted)
local currentPage="Player"
local function showPage(name)
 currentPage=name;closeMenu()
 for n,p in pairs(pages)do p.Visible=n==name end
 for n,b in pairs(navButtons)do b.BackgroundTransparency=n==name and 0 or 1;b.TextColor3=n==name and C.ink or C.muted end
 if name=="Players"then refreshPlayers()end
 notify(name=="Aim" and "No target selected" or "Ready")
end
local nav={{"Player","user"},{"Aim","crosshair"},{"Teleport","map-pin"},{"Players","users"},{"ESP","eye"},{"Settings","settings"}}
for i,item in ipairs(nav)do
 local name=item[1];local b=button(sidebar,name,12,16+(i-1)*42,142,34,false);b.Name="Nav"..name;b.Font=Enum.Font.Arial;b.TextSize=13;b.TextXAlignment=Enum.TextXAlignment.Left
 create("UIPadding",{PaddingLeft=UDim.new(0,39)},b);icon(b,item[2],12,9,16,C.muted);navButtons[name]=b
 connect(b.Activated,function()showPage(name)end)
end
showPage("Player")
local fovRing=frame(gui,0,0,state.fov*2,state.fov*2);fovRing.Name="FovRing";fovRing.BackgroundTransparency=1;fovRing.AnchorPoint=Vector2.new(0.5,0.5);fovRing.Position=UDim2.fromScale(0.5,0.5);round(fovRing,999);stroke(fovRing,Color3.fromRGB(160,160,160));fovRing.Visible=false
local reopen=button(gui,"Forma",16,16,96,34,false);reopen.Name="Reopen";stroke(reopen);reopen.Visible=false
local function setMinimized(value)closeMenu();minimized=value;root.Visible=verified and not value;reopen.Visible=verified and value end
connect(reopen.Activated,function()setMinimized(false)end)
local function clearEsp()
 for _,h in pairs(ownedHighlights)do h:Destroy()end;table.clear(ownedHighlights)
 for _,b in pairs(ownedLabels)do b:Destroy()end;table.clear(ownedLabels)
end
function api.Destroy()
 if not alive then return end;closeMenu();alive=false;state.fly=false;stopFlight();clearEsp();if verified then task.spawn(function()request("reset",{})end)end
 for _,c in ipairs(connections)do c:Disconnect()end;table.clear(connections)
 for _,obj in ipairs(temporary)do obj:Destroy()end;gui:Destroy()
end
connect(gui.Destroying,api.Destroy)
iconButton(access,"x",382,18,api.Destroy);iconButton(header,"x",948,14,api.Destroy);iconButton(header,"minus",912,14,function()setMinimized(true)end)
local dragging,dragInput,dragStart,startPosition
connect(header.InputBegan,function(i)
 if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;dragStart=i.Position;startPosition=root.Position;dragInput=i end
end)
connect(UserInputService.InputChanged,function(i)
 if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i==dragInput) then
  local d=i.Position-dragStart;root.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,startPosition.Y.Scale,startPosition.Y.Offset+d.Y)
 end
end)
connect(UserInputService.InputEnded,function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i==dragInput then dragging=false end end)
connect(UserInputService.InputBegan,function(i,processed)
 if processed or UserInputService:GetFocusedTextBox()then return end
 if i.KeyCode==Enum.KeyCode.RightControl and verified then setMinimized(not minimized)end
end)
local function fit()
 local camera=workspace.CurrentCamera;if not camera then return end;local v=camera.ViewportSize
 rootScale.Scale=math.max(0.1,math.min(1,(v.X-32)/1000,(v.Y-40)/560))
 local s=math.min(1,(v.X-32)/440,(v.Y-40)/340);accessScale.Scale=math.max(0.25,s);loadingScale.Scale=accessScale.Scale
end
local function targetModels(mode)
 mode=mode or state.targetMode
 local result={}
 if mode=="Players"then
  for _,p in ipairs(Players:GetPlayers())do if p~=localPlayer and p.Character then table.insert(result,{model=p.Character,player=p})end end
 else
  local folder=workspace:FindFirstChild("TestDummies")
  if folder then for _,m in ipairs(folder:GetChildren())do if m:IsA("Model")then table.insert(result,{model=m})end end end
  for _,m in ipairs(CollectionService:GetTagged("FormaTarget"))do if m:IsA("Model") and (not folder or m.Parent~=folder)then table.insert(result,{model=m})end end
 end
 return result
end
local function targetPart(model)
 if state.targetPart=="Head"then return model:FindFirstChild("Head")end
 if state.targetPart=="Root"then return model:FindFirstChild("HumanoidRootPart")end
 return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
end
local function chooseTarget(camera)
 local closest,closestDistance=nil,state.fov
 local center=camera.ViewportSize/2
 for _,entry in ipairs(targetModels())do
  local model,p=entry.model,entry.player;local hum=model:FindFirstChildOfClass("Humanoid");local part=targetPart(model)
  local sameTeam=p and p.Team~=nil and p.Team==localPlayer.Team
  if part and part:IsA("BasePart") and hum and hum.Health>0 and not(state.teamCheck and sameTeam)then
   local point,onScreen=camera:WorldToViewportPoint(part.Position)
   if onScreen and point.Z>0 then
    local dist=(Vector2.new(point.X,point.Y)-center).Magnitude
    if dist<closestDistance then
     local visible=true
     if state.visibleOnly then
      local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=localPlayer.Character and {localPlayer.Character} or {}
      local hit=workspace:Raycast(camera.CFrame.Position,part.Position-camera.CFrame.Position,params)
      visible=not hit or hit.Instance:IsDescendantOf(model)
     end
     if visible then closestDistance=dist;closest=part end
    end
   end
  end
 end
 return closest
end
function api.GetAimTarget() return verified and state.silent and aimTarget or nil end
local aimBridge=create("BindableFunction",{Name="GetAimTarget"},gui)
aimBridge.OnInvoke=function()return api.GetAimTarget()end
function api.GetState() return table.clone(state) end
function api.SetVisible(value) if verified then setMinimized(not value)end end
local function glowColor(t,p)
 if state.glow=="Rainbow"then return Color3.fromHSV((t*0.12)%1,0.72,1)end
 if state.glow=="Lava"then return Color3.fromRGB(237,70,22):Lerp(Color3.fromRGB(255,168,36),(math.sin(t*2)+1)/2)end
 if state.glow=="Black lava"then return Color3.fromRGB(35,28,28):Lerp(Color3.fromRGB(194,61,26),(math.sin(t*1.8)+1)/2)end
 return p and p.TeamColor.Color or Color3.fromRGB(125,145,164)
end
local function refreshEsp()
 if not verified or not state.esp then if next(ownedHighlights)then clearEsp()end;return end
 local seen={};local _,_,ownRoot=characterParts()
 for _,entry in ipairs(targetModels(state.espTargets))do
  local model,p=entry.model,entry.player;local hum=model:FindFirstChildOfClass("Humanoid");local part=model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
  local sameTeam=p and p.Team~=nil and p.Team==localPlayer.Team
  if hum and hum.Health>0 and part and (not state.teamOnly or sameTeam)then
   seen[model]=true
   local h=ownedHighlights[model]
   if not h then h=create("Highlight",{Name="FormaHighlight",Adornee=model},gui);ownedHighlights[model]=h end
   local color=glowColor(os.clock(),p);h.FillColor=color;h.OutlineColor=color;h.FillTransparency=1-state.opacity;h.OutlineTransparency=0.15;h.DepthMode=state.throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
   local b=ownedLabels[model]
   if not b then b=create("BillboardGui",{Name="FormaEspLabel",Adornee=part,Size=UDim2.fromOffset(240,44),StudsOffset=Vector3.new(0,2,0)},gui);label(b,"",0,0,240,44,12,C.white,true).TextXAlignment=Enum.TextXAlignment.Center;ownedLabels[model]=b end
   local parts={};if state.names then table.insert(parts,p and p.DisplayName or model.Name)end;if state.health then table.insert(parts,tostring(math.round(hum.Health)).." HP")end
   if state.distance and ownRoot then table.insert(parts,tostring(math.round((part.Position-ownRoot.Position).Magnitude)).." studs")end
   b.Adornee=part;b.AlwaysOnTop=state.throughWalls;b.Enabled=#parts>0;b:FindFirstChildOfClass("TextLabel").Text=table.concat(parts," · ")
  end
 end
 for model,h in pairs(ownedHighlights)do if not seen[model]then h:Destroy();ownedHighlights[model]=nil;if ownedLabels[model]then ownedLabels[model]:Destroy();ownedLabels[model]=nil end end end
end
connect(localPlayer.CharacterAdded,function()
 state.fly=false;previewOriginal=nil;stopFlight();for _,f in ipairs(refreshers)do f()end
end)
connect(resetButton.Activated,function()
 for k,v in pairs(defaults)do state[k]=v end;state.activation="Hold right mouse";stopFlight();clearEsp();updateGlow({"Solid","Lava","Black lava","Rainbow"},"Solid");updateTargets({"Test dummies","Players"},"Test dummies");updateEspTargets({"Players","Test dummies"},"Players")
 for _,f in ipairs(refreshers)do f()end
 task.spawn(function()local r=request("reset",{});if alive then notify(r.ok and "Defaults restored" or r.message,not r.ok)end end)
end)
connect(getKey.Activated,function()resolveRemote();keyStatus.Text=remote and "Ask the game owner for your access key." or "GUI preview key: FORMA-TEST";keyStatus.TextColor3=C.muted end)
local function verify()
 if busy then return end
 local entered=key.Text:match("^%s*(.-)%s*$")
 if entered==""then keyStatus.Text="Enter your access key.";keyStatus.TextColor3=C.red;key:CaptureFocus();return end
 busy=true;continueButton.Text="Checking…";keyStatus.Text=""
 task.spawn(function()
  local r=request("verify",{key=entered})
  if not alive then return end
  if not r.ok then busy=false;continueButton.Text="Continue";keyStatus.Text=r.message or "Invalid key.";keyStatus.TextColor3=C.red;return end
  verified=true;local _,hum=characterParts();if hum then state.speed=hum.WalkSpeed;state.jump=hum.JumpPower;defaults.speed=state.speed;defaults.jump=state.jump end;for _,f in ipairs(refreshers)do f()end;key.Text="";access.Visible=false;loading.Visible=true;sessionLabel.Text=r.mode or "admin session"
  presets=r.presets or {"Spawn"};if #presets==0 then presets={"Spawn"}end;selectedPreset=presets[1];updatePreset(presets,selectedPreset);updateTeleportPreset(presets,selectedPreset)
  tween(progress,{Size=UDim2.fromOffset(242,3)},0.7);task.wait(0.75);if not alive then return end
  refreshPlayers();loadingText.Text="Almost ready…";tween(progress,{Size=UDim2.fromOffset(384,3)},0.35);task.wait(0.4);if not alive then return end
  loading.Visible=false;root.Visible=true;busy=false;showPage("Player")
 end)
end
connect(continueButton.Activated,verify);connect(key.FocusLost,function(enter)if enter then verify()end end)
local espElapsed,infoElapsed=0,0
connect(RunService.RenderStepped,function(dt)
 fit();if not verified then return end
 local camera=workspace.CurrentCamera;if not camera then return end
 fovRing.Visible=state.showFov and (state.aim or state.silent);fovRing.Size=UDim2.fromOffset(state.fov*2,state.fov*2)
 if state.aim or state.silent then aimTarget=chooseTarget(camera)else aimTarget=nil end
 if state.aim and aimTarget and not UserInputService:GetFocusedTextBox() and (state.activation=="Always" or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))then
  local desired=CFrame.lookAt(camera.CFrame.Position,aimTarget.Position)
  local alpha=1-math.exp(-dt*(35-30*state.smoothing));camera.CFrame=camera.CFrame:Lerp(desired,alpha)
 end
 if state.fly and flightVelocity and flightOrientation then
  local direction=Vector3.zero
  if not UserInputService:GetFocusedTextBox()then
   if UserInputService:IsKeyDown(Enum.KeyCode.W)then direction+=camera.CFrame.LookVector end
   if UserInputService:IsKeyDown(Enum.KeyCode.S)then direction-=camera.CFrame.LookVector end
   if UserInputService:IsKeyDown(Enum.KeyCode.D)then direction+=camera.CFrame.RightVector end
   if UserInputService:IsKeyDown(Enum.KeyCode.A)then direction-=camera.CFrame.RightVector end
   if UserInputService:IsKeyDown(Enum.KeyCode.Space)then direction+=Vector3.yAxis end
   if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)then direction-=Vector3.yAxis end
  end
  flightVelocity.VectorVelocity=direction.Magnitude>0 and direction.Unit*state.flySpeed or Vector3.zero
  flightOrientation.CFrame=camera.CFrame.Rotation
 end
 espElapsed+=dt;infoElapsed+=dt
 if espElapsed>=0.1 then espElapsed=0;refreshEsp()end
 if infoElapsed>=1 then
  infoElapsed=0;local _,_,hrp=characterParts();local text=hrp and string.format("Current location:  x %.1f   y %.1f   z %.1f",hrp.Position.X,hrp.Position.Y,hrp.Position.Z)or "Current location: character unavailable";coords.Text=text;currentLocation.Text=text
  if currentPage=="Players"then refreshPlayers()elseif currentPage=="Aim"then notify(aimTarget and "Target: "..aimTarget.Parent.Name or "No target selected")end
 end
end)
fit()
return api
