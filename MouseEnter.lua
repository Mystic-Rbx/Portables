-- https://github.com/Vyon/Signal
local signal = {}
signal.__index = signal

function signal.New()
	local self = setmetatable({}, signal)
	self._Callbacks = {}
	self._Args = nil

	return self
end

function signal:Connect(callback: any)
	local index = #self._Callbacks + 1
	table.insert(self._Callbacks, callback)

	return {
		Disconnect = function()
			self._Callbacks[index] = nil
		end
	}
end

function signal:Fire(...)
	for _, callback in pairs(self._Callbacks) do
		task.spawn(callback, ...)
	end

	self._Args = {...}

	task.wait()

	self._Args = nil
end

function signal:Wait()
	local _Args = nil

	repeat _Args = self._Args task.wait() until _Args
	return _Args
end

return signal


-- https://devforum.roblox.com/t/fed-up-with-mouseenter-and-mouseleave-not-working-heres-a-module-for-you/155011

local Player = game.Players.LocalPlayer or game.Players:GetPropertyChangedSignal("LocalPlayer")

local Mouse = Player:GetMouse()

local CurrentItems = {}

--Private functions
local function IsInFrame(v)

    local X = Mouse.X
    local Y = Mouse.Y

    if X>v.AbsolutePosition.X and Y>v.AbsolutePosition.Y and X<v.AbsolutePosition.X+v.AbsoluteSize.X and Y<v.AbsolutePosition.Y+v.AbsoluteSize.Y then
        return true
    else 
        return false
    end
end

local function CheckMouseExited(Object)

    if not Object.MouseIsInFrame and Object.MouseWasIn then --Mouse was previously over object, fire leave event
        Object.MouseWasIn = false
        Object.LeaveEvent:Fire()
    end
end


local function CheckMouseEntered(Object)
    if Object.MouseIsInFrame and not Object.MouseWasIn then
        Object.MouseWasIn = true
        Object.EnteredEvent:Fire()
    end
end

game:GetService("RunService").Heartbeat:Connect(function()
    --Check each UI object
    --All exit events fire before all enter events for ease of use, so check for mouse exit events here
    for _, Object in pairs(CurrentItems) do
        Object.MouseIsInFrame = IsInFrame(Object.UIObj)
        CheckMouseExited(Object)
    end

    --Now check if the mouse entered any frames
    for _, Object in pairs(CurrentItems) do
        CheckMouseEntered(Object)
    end
end)

--Public functions

local module = {}

function module.MouseEnterLeaveEvent(UIObj)
        if CurrentItems[UIObj] then
            return CurrentItems[UIObj].EnteredEvent.Event,CurrentItems[UIObj].LeaveEvent.Event
        end     

        local newObj = {}

        newObj.UIObj = UIObj

        local EnterEvent = signal.New()
        local LeaveEvent = signal.New()
        
        newObj.EnteredEvent = EnterEvent
        newObj.LeaveEvent = LeaveEvent
        newObj.MouseWasIn = false
        CurrentItems[UIObj] = newObj

        UIObj.AncestryChanged:Connect(function()
            if not UIObj.Parent then
                --Assuming the object has been destroyed as we still dont have a .Destroyed event
                --If for some reason you parent your UI elements to nil after calling this, then parent it back again, mouse over will still have been disconnected.
                EnterEvent:Destroy()    
                LeaveEvent:Destroy()    
                CurrentItems[UIObj] = nil
            end
        end)

       return EnterEvent,LeaveEvent
 end

return module
