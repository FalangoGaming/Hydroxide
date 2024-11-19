local RemoteSpy = {}
local Remote = import("objects/Remote")

local requiredMethods = {
    ["checkCaller"] = true,
    ["newCClosure"] = true,
    ["hookFunction"] = true,
    ["isReadOnly"] = true,
    ["setReadOnly"] = true,
    ["getInfo"] = true,
    ["getMetatable"] = true,
    ["setClipboard"] = true,
    ["getNamecallMethod"] = true,
    ["getCallingScript"] = true,
}

local remoteMethods = {
    FireServer = true,
    InvokeServer = true,
    Fire = true,
    Invoke = true
}

local remotesViewing = {
    RemoteEvent = true,
    RemoteFunction = false,
    BindableEvent = false,
    BindableFunction = false
}

local methodHooks = {
    RemoteEvent = Instance.new("RemoteEvent").FireServer,
    RemoteFunction = Instance.new("RemoteFunction").InvokeServer,
    BindableEvent = Instance.new("BindableEvent").Fire,
    BindableFunction = Instance.new("BindableFunction").Invoke
}

local currentRemotes = {}

local remoteDataEvent = Instance.new("BindableEvent")
local eventSet = false

local function connectEvent(callback)
    remoteDataEvent.Event:Connect(callback)

    if not eventSet then
        eventSet = true
    end
end

local nmcTrampoline
nmcTrampoline = hookMetaMethod(game, "__namecall", function(...)
    local instance = ...
    
    if typeof(instance) ~= "Instance" then
        return nmcTrampoline(...)
    end

    local method = getNamecallMethod()

    if method == "fireServer" then
        method = "FireServer"
    elseif method == "invokeServer" then
        method = "InvokeServer"
    end
        
    if remotesViewing[instance.ClassName] and instance ~= remoteDataEvent and remoteMethods[method] then
        local remote = currentRemotes[instance]
        local vargs = {select(2, ...)}
            
        if not remote then
            remote = Remote.new(instance)
            currentRemotes[instance] = remote
        end

        local remoteIgnored = remote.Ignored
        local remoteBlocked = remote.Blocked
        local argsIgnored = remote.AreArgsIgnored(remote, vargs)
        local argsBlocked = remote.AreArgsBlocked(remote, vargs)

        if eventSet and (not remoteIgnored and not argsIgnored) then
            local call = {
                script = getCallingScript((PROTOSMASHER_LOADED ~= nil and 2) or nil),
                args = vargs,
                func = getInfo(3).func
            }

            remote.IncrementCalls(remote, call)
            remoteDataEvent.Fire(remoteDataEvent, instance, call)
        end

        if remoteBlocked or argsBlocked then
            return
        end
    end

    return nmcTrampoline(...)
end)

-- vuln fix

local pcall = pcall

local function checkPermission(instance)
    if (instance.ClassName) then end
end

for _name, hook in pairs(methodHooks) do
    local originalMethod
    originalMethod = hookFunction(hook, newCClosure(function(...)
        local instance = ...

        if typeof(instance) ~= "Instance" then
            return originalMethod(...)
        end
                
        do
            local success = pcall(checkPermission, instance)
            if (not success) then return originalMethod(...) end
        end

        if instance.ClassName == _name and remotesViewing[instance.ClassName] and instance ~= remoteDataEvent then
            local remote = currentRemotes[instance]
            local vargs = {select(2, ...)}

            if not remote then
                remote = Remote.new(instance)
                currentRemotes[instance] = remote
            end

            local remoteIgnored = remote.Ignored 
            local argsIgnored = remote:AreArgsIgnored(vargs)
            
            if eventSet and (not remoteIgnored and not argsIgnored) then
                local call = {
                    script = getCallingScript((PROTOSMASHER_LOADED ~= nil and 2) or nil),
                    args = vargs,
                    func = getInfo(3).func
                }
    
                remote:IncrementCalls(call)
                remoteDataEvent:Fire(instance, call)
            end

            if remote.Blocked or remote:AreArgsBlocked(vargs) then
                return
            end
        end
        
        return originalMethod(...)
    end))

    oh.Hooks[originalMethod] = hook
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteSpyUI"
screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
mainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)

local titleLabel = Instance.new("TextLabel")
titleLabel.Parent = mainFrame
titleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.Size = UDim2.new(0, 100, 0, 20)
titleLabel.Font = Enum.Font.SourceSans
titleLabel.Text = "Remote Spy"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18

local remoteList = Instance.new("ScrollingFrame")
remoteList.Parent = mainFrame
remoteList.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
remoteList.BorderColor3 = Color3.fromRGB(0, 0, 0)
remoteList.Position = UDim2.new(0, 10, 0, 40)
remoteList.Size = UDim2.new(0, 280, 0, 300)
remoteList.CanvasSize = UDim2.new(0, 0, 0, 0)

local remoteListLayout = Instance.new("UIListLayout")
remoteListLayout.Parent = remoteList
remoteListLayout.SortOrder = Enum.SortOrder.Name

-- Function to update the UI with remote call data
local function updateRemoteList(remoteInstance, callData)
    local remoteName = remoteInstance.Name
    local remoteFrame = remoteList:FindFirstChild(remoteName)
    if not remoteFrame then
        remoteFrame = Instance.new("Frame")
        remoteFrame.Name = remoteName
        remoteFrame.Parent = remoteList
        remoteFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        remoteFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        remoteFrame.Size = UDim2.new(1, -20, 0, 20)

        local remoteLabel = Instance.new("TextLabel")
        remoteLabel.Parent = remoteFrame
        remoteLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        remoteLabel.BackgroundTransparency = 1
        remoteLabel.Size = UDim2.new(1, 0, 1, 0)
        remoteLabel.Font = Enum.Font.SourceSans
        remoteLabel.Text = remoteName
        remoteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        remoteLabel.TextSize = 14
    end

    -- Update the remote's label with the latest call information
    local remoteLabel = remoteFrame:FindFirstChildOfClass("TextLabel")
    remoteLabel.Text = string.format("%s (%s)", remoteName, callData.player) 

    -- Update canvas size
    local listLayout = remoteList.UIListLayout
    remoteList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

-- Connect the event to update the UI
RemoteSpy.ConnectEvent(updateRemoteList)



RemoteSpy.RemotesViewing = remotesViewing
RemoteSpy.CurrentRemotes = currentRemotes
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.RequiredMethods = requiredMethods
return RemoteSpy
