wait(3)

local UIS = game:GetService("UserInputService")
local debounce = false

local player = game:GetService("Players").LocalPlayer

UIS.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.Q and debounce == false and player.Val.Value > 0 then
		game.ReplicatedStorage.Dash:FireServer("Default")
		debounce = true
		wait(1.5)
		debounce = false
	end
end)

local function checkMoveDirection()
	if player.Character.Humanoid.MoveDirection.Magnitude > 0.1 then
		if player.Active.Value == true and not player:FindFirstChild("Flag") then
			game.ReplicatedStorage.Dash:FireServer("Check")
		end
	else
		if player.Active.Value == true and player:FindFirstChild("Flag") then
			game.ReplicatedStorage.Dash:FireServer("CheckVar")
		end
	end
end

player.Character.Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(checkMoveDirection)
