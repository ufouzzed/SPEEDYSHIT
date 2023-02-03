local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer


--- Returns the global environment.
--- @return table
local getgenv = assert(type(getgenv) == 'function' and getgenv, 'Incompatible exploit. (getgenv is not a function)')

--- The VehicleMod library.
--- @class VehicleMod
local VehicleMod = getgenv().VehicleMod

if type(VehicleMod) == 'table' and type(rawget(VehicleMod, 'Disconnect')) == 'function' then
    VehicleMod:Disconnect()
else
    VehicleMod = {}
    getgenv().VehicleMod = VehicleMod
end

assert(type(typeof) == 'function', 'Missing Luau typecheck. (typeof is not a function)')

local Signal = {} do
    Signal.__index = Signal

    --- Creates a new Signal that mimics the Roblox RBXScriptSignal.
    function Signal.new()
        return setmetatable({
            _bindable = Instance.new("BindableEvent");
            _connections = {};
        }, Signal)
    end

    --- Connects a callback to the signal.
    --- @param callback function The callback to connect to the signal.
    function Signal:Connect(callback)
        local connection = self._bindable.Event:Connect(callback)
        table.insert(self._connections, connection)
        return connection
    end

    --- Fires the signal with the given arguments.
    --- @vararg any Arguments to pass to the signal's callbacks.
    function Signal:Fire(...)
        self._bindable:Fire(...)
    end

    --- Yields the current thread until the signal is fired.
    function Signal:Wait()
        return self._bindable.Event:Wait()
    end

    --- Connects a callback to the signal and disconnects it after it is fired once.
    --- @param callback function
    function Signal:Once(callback)
        local connection
        connection = self:Connect(function(...)
            connection:Disconnect()
            callback(...)
        end)
        return connection
    end

    --- Disconnects all connections to the signal and destroys the signal.
    function Signal:Destroy()
        for _, v in pairs(self._connections) do
            v:Disconnect()
        end
        self._bindable:Destroy()
        for i in pairs(self) do
            self[i] = nil
        end
    end
end

local Instance, Connect do
    local instances = {}
    local connections = {}

    local instance = Instance
    Instance = {
        --- Creates a new instance of the given class and stores it in a table.
        --- @param class string The class of the instance to create.
        --- @param parent Instance The parent of the instance to create.
        --- @return Instance
        new = function(class, parent)
            local object = instance.new(class, parent)
            table.insert(instances, object)
            return object
        end
    }

    --- Connects a callback to a signal and stores the connection in a table.
    --- @param signal RBXScriptSignal The signal to connect to.
    --- @param callback function The callback to connect to the signal.
    --- @return RBXScriptConnection connection The connection to the signal.
    function Connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end

    --- Disconnects all connections and destroys all instances created by the library.
    function VehicleMod:Disconnect()
        for _, v in pairs(connections) do
            v:Disconnect()
        end
        for _, v in pairs(instances) do
            v:Destroy()
        end
        for i, v in pairs(self) do
            if type(v) == 'table' and type(v.Destroy) == 'function' then
                v:Destroy()
            end
            self[i] = nil
        end
    end
end

--- If playing Jailbreak; this would be an array containing functions to get the local vehicle.
--- @type table
local Jailbreak
if type(getgc) == 'function' then
    for _, v in pairs(getgc(true)) do
        if type(v) == 'table' and type(rawget(v, 'GetLocalVehiclePacket')) == 'function' then
            Jailbreak = v
        end
    end
end

--- The current drive seat of the vehicle.
--- @type VehicleSeat
VehicleMod.CurrentDriveSeat = nil

--- Fires when the player enters a vehicle.
--- @type RBXScriptSignal
VehicleMod.VehicleEntered = Signal.new()

--- Fires when the player exits a vehicle.
--- @type RBXScriptSignal
VehicleMod.VehicleExited = Signal.new()

--- Get the drive seat of the vehicle.
--- @return VehicleSeat
function VehicleMod:GetDriveSeat()
    if Jailbreak then
        local packet = Jailbreak:GetLocalVehiclePacket()
        if packet then
            local model = packet.Model
            if typeof(model) == 'Instance' and typeof(model.PrimaryPart) == 'Instance' then
                return model.PrimaryPart
            end
        end
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    local seatpart = humanoid and humanoid.SeatPart
    if typeof(seatpart) == 'Instance' and seatpart:IsA("VehicleSeat") then
        return seatpart
    end
end

function VehicleMod:GetVehicle()
    if Jailbreak then
        return Jailbreak:GetLocalVehiclePacket()
    end
    local DriveSeat = self:GetDriveSeat()
    return DriveSeat and DriveSeat:FindFirstAncestorWhichIsA("Model")
end

--- Set the velocity of the vehicle.
--- @param assemblyLinearVelocity Vector3 Linearly applied velocity
--- @param assemblyAngularVelocity Vector3 Angularly applied velocity
function VehicleMod:SetVelocity(assemblyLinearVelocity, assemblyAngularVelocity)
    local DriveSeat = self:GetDriveSeat()
    if DriveSeat then
        DriveSeat.AssemblyLinearVelocity = assemblyLinearVelocity
        DriveSeat.AssemblyAngularVelocity = assemblyAngularVelocity
    end
end

--- Get the velocity of the vehicle in the form of linear velocity, angular velocity.
--- This also provides the forward vector of the vehicle. This is useful for calculating the dot product of the velocity and the forward vector.
--- @return Vector3, Vector3, Vector3
function VehicleMod:GetVelocity()
    local DriveSeat = self:GetDriveSeat()
    if DriveSeat then
        return DriveSeat.AssemblyLinearVelocity, DriveSeat.AssemblyAngularVelocity, DriveSeat.CFrame.LookVector
    end
end

--- Set the velocity of the vehicle by multiplying the current velocity.
--- @param linearMultiplier number Multiplier for linear velocity
--- @param angularMultiplier number Multiplier for angular velocity
function VehicleMod:SetVelocityMult(linearMultiplier, angularMultiplier)
    local DriveSeat = self:GetDriveSeat()
    if DriveSeat then
        DriveSeat.AssemblyLinearVelocity = DriveSeat.AssemblyLinearVelocity * (linearMultiplier and linearMultiplier or 1)
        DriveSeat.AssemblyAngularVelocity = DriveSeat.AssemblyAngularVelocity * (angularMultiplier and angularMultiplier or 1)
    end
end

--- Set the velocity of the vehicle by multiplying the current velocity by the forward vector.
--- @param linearMultiplier number Multiplier for linear velocity
--- @param angularMultiplier number Multiplier for angular velocity
function VehicleMod:SetVelocityMultFwd(linearMultiplier, angularMultiplier)
    local velocity, angularvelocity, forward = self:GetVelocity()
    if velocity and angularvelocity and forward then
        local dot = forward:Dot(velocity)
        local newvelocity = forward * dot * linearMultiplier
        self:SetVelocity(newvelocity, angularvelocity * angularMultiplier)
    end
end

--- The current velocity of the vehicle.
--- @type Vector3
VehicleMod.CurrentVelocity = Vector3.zero

--- Compare the velocity between the last frame and the current frame's velocity.
--- @param operator '>' | '<' If nothing is passed, '>' is used by default.
--- @return boolean
function VehicleMod:CompareVelocityByFrames(operator)
    local Operation = operator or '>'
    local DriveSeat = self:GetDriveSeat()
    local NextVelocity = DriveSeat.AssemblyLinearVelocity

    local m0 = self.CurrentVelocity.Magnitude
    local m1 = NextVelocity.Magnitude

    if Operation == '>' then
        return m0 > m1
    elseif Operation == '<' then
        return m0 < m1
    end
end

--- Returns true if the vehicle is braking.
--- @return boolean
function VehicleMod:IsBraking()
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        return self:CompareVelocityByFrames('>')
    end
end

--- Returns true if the vehicle is accelerating.
--- @return boolean
function VehicleMod:IsAccelerating()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
        return self:CompareVelocityByFrames('<')
    end
end

--- Returns true if the vehicle is reversing.
--- @return boolean

function VehicleMod:IsReversing()
    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
        return self:CompareVelocityByFrames('<')
    end
end

--- The maximum speed at which the player can travel in studs per second.
---
--- 750 (or 300~ approx. in miles per hour) is the original value for this.
--- @type number
VehicleMod.MaxStudsPerSecond = getgenv().Speed

--- Intended to be used in a RenderStepped loop. This will update the vehicle's velocity.
--- @param deltaTime number The time between each frame.
function VehicleMod:Update(deltaTime)
    local DriveSeat = self:GetDriveSeat()
    if DriveSeat then
        self.CurrentDriveSeat = DriveSeat
        if self:IsAccelerating() then
            self:SetVelocityMult(1 + (0.1 - 0.1 * DriveSeat.AssemblyLinearVelocity.Magnitude / self.MaxStudsPerSecond))
        elseif self:IsBraking() then
            self:SetVelocityMult(0.9)
        end
        self.CurrentVelocity = DriveSeat.AssemblyLinearVelocity
    end
end

Connect(RunService.RenderStepped, function(deltaTime)
    VehicleMod:Update(deltaTime)
end)
