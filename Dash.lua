local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local playerGroup = "playerGroup"
local cloneGroup = "cloneGroup"
PhysicsService:CreateCollisionGroup(playerGroup)
PhysicsService:CreateCollisionGroup(cloneGroup)
PhysicsService:CollisionGroupSetCollidable(cloneGroup, cloneGroup, false)
PhysicsService:CollisionGroupSetCollidable(cloneGroup, playerGroup, false)

local enabled = false

local SpeedTimePlayers = {}

local function tweenVelocity(part, targetVelocity, duration)
	local tweenInfo = TweenInfo.new(duration)
	local goal = {Velocity = targetVelocity}
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()
end

local function isPlayerInSet(playerID, idSet)
	return idSet[playerID] == true
end

local function Check(player)
	spawn(function()
		if player.Active.Value == true and not player:FindFirstChild("Flag") then
			local Flag = Instance.new("ObjectValue")
			Flag.Name = "Flag"
			Flag.Parent = player

			local Track = Instance.new("Animation")
			Track.Name = "Sprint"
			Track.AnimationId = "rbxassetid://18262070933"
			local Anim = player.Character.Humanoid:LoadAnimation(Track)
			Anim:AdjustSpeed(10)
			Anim:Play()

			while player.Val.Value > 0 and player.Active.Value == true and wait(0.1) and player:FindFirstChild("Flag") do
				player.Character.Archivable = true
				local CharClone = player.Character:Clone()
				CharClone:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame*CFrame.new(0,1.25,0))

				local Highlight = Instance.new("Highlight")
				Highlight.Parent = CharClone
				Highlight.FillColor = Color3.fromHSV(tick() % 5/5, 1, 1)
				Highlight.OutlineColor = Color3.new(0,0,0)
				game.Debris:AddItem(Highlight,1)

				for _, object in ipairs(CharClone:GetDescendants()) do
					if object:IsA("BasePart") and object.Name ~= "HumanoidRootPart" then
						object.Anchored = true
						object.CanCollide = false
						object.Transparency = 0.25
						object.Material = Enum.Material.Glass

						local goal = {}
						goal.Transparency = 1
						local info = TweenInfo.new(1,Enum.EasingStyle.Linear)
						local tween = TweenService:Create(object,info,goal)
						tween:Play()

						local function setCollisionGroupRecursive()
							PhysicsService:SetPartCollisionGroup(object,cloneGroup)
						end
						for _, child in ipairs(object:GetChildren()) do
							setCollisionGroupRecursive(child)
						end
						local npc = game.Workspace.NPC
						setCollisionGroupRecursive(npc)
					elseif object:IsA("Script") then
						game.Debris:AddItem(object,0)
					end
				end
				CharClone.Parent = game.Workspace.NPC
				CharClone.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				game.Debris:AddItem(CharClone,1)
			end

			if player:FindFirstChild("Flag") then
				game.Debris:AddItem(Flag,0)
			end

			local ActiveTracks = player.Character.Humanoid:GetPlayingAnimationTracks()
			for _,v in pairs(ActiveTracks) do
				if v.Name == "Sprint" then
					v:Stop()
				end
			end	
		end
	end)
end

game.Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		if not Player:FindFirstChild("Val") then
			local Val = Instance.new("NumberValue")
			Val.Name = "Val"
			Val.Value = 100
			Val.Parent = Player
			
			local Active = Instance.new("BoolValue")
			Active.Name = "Active"
			Active.Value = false
			Active.Parent = Player
		end
		
		Character:WaitForChild("HumanoidRootPart")
		Character:WaitForChild("Head")
		Character:WaitForChild("Humanoid")
		wait(1)
		for i,v in pairs(Character:GetChildren()) do
			if v:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(v,playerGroup)
			end
		end
		for i,v in pairs(game.Workspace.NPCs:GetDescendants()) do
			if v:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(v,cloneGroup)
			end
		end
	end)
end)

game.Players.PlayerAdded:Connect(function(Player)
	RunService.Stepped:Connect(function(_, deltaTime)
		if Player and Player:FindFirstChild("Val") and Player.Active.Value == false then
			Player.Val.Value = math.min(Player.Val.Value + 15 * deltaTime, 100)
		end
	end)
end)

game:GetService("Players").PlayerRemoving:Connect(function(Player)
	SpeedTimePlayers[Player.UserId] = nil
end)

game.ReplicatedStorage.Dash.OnServerEvent:Connect(function(player, action)
	if action == "Default" then
		local CC = script.ColorCorrection:Clone()
		
		if player.Active.Value == false then
			local SFX = script.SFX:Clone()
			SFX.Parent = game.Workspace
			SFX:Play()
			
			delay(5, function()
				SFX:Destroy()
			end)
			
			wait(1.5)
			
			player.Active.Value = true
			
			player.Character.Humanoid.WalkSpeed = 40
			player.Character.Humanoid.JumpPower = 100
			
			CC.Parent = game.Lighting

			game.Workspace.Gravity = 75

			local slowMotionFactor = 0.75
			local transitionDuration = 0.25

			game.Workspace.TimeScale.Value = slowMotionFactor / 2

			SpeedTimePlayers[player.UserId] = if SpeedTimePlayers[player.UserId] then nil else true
			
			Check(player)
			
			while player.Val.Value > 0 and player.Active.Value == true and wait(0.1) do
				player.Val.Value -= 1
				
				for _, part in pairs(game.Workspace:GetDescendants()) do
					if part and part:IsA("BasePart") and not part.Parent:FindFirstChild("Humanoid") and part.Anchored == false then
						local targetVelocity = part.Velocity * slowMotionFactor
						tweenVelocity(part, targetVelocity, transitionDuration)

						part.RotVelocity = part.RotVelocity * slowMotionFactor

						local bodyAngularVelocity = part:FindFirstChildOfClass("BodyAngularVelocity")
						if bodyAngularVelocity and not part:FindFirstChild("Tag") then
							local Tag = Instance.new("ObjectValue")
							Tag.Name = "Tag"
							Tag.Parent = part

							bodyAngularVelocity.AngularVelocity = bodyAngularVelocity.AngularVelocity * slowMotionFactor*2
						end
					elseif part and part:IsA("BasePart") and part.Parent:FindFirstChild("Humanoid") and part.Anchored == false then
						for _, anim in pairs(game.Players:GetPlayers()) do
							if not isPlayerInSet(anim.UserId, SpeedTimePlayers) and not part.Parent:FindFirstChild("Tag") then
								local Tag = Instance.new("ObjectValue")
								Tag.Name = "Tag"
								Tag.Parent = part.Parent

								anim.Character.Humanoid.WalkSpeed = 1
								anim.Character.Humanoid.JumpPower = 10
							end
						end
						
						if part and part.Parent.Parent.Name == "NPCs" and not part.Parent:FindFirstChild("Tag") then
							local Tag = Instance.new("ObjectValue")
							Tag.Name = "Tag"
							Tag.Parent = part.Parent

							part.Parent.Humanoid.WalkSpeed = 1
							part.Parent.Humanoid.JumpPower = 10
							
							for _, track in pairs(part.Parent.Humanoid:GetPlayingAnimationTracks()) do
								track:AdjustSpeed(slowMotionFactor/5)
							end
						end
					end
				end

				for _, anim in pairs(game.Players:GetPlayers()) do
					if not isPlayerInSet(anim.UserId, SpeedTimePlayers) then
						if anim:FindFirstChild("Humanoid") then
							for _, track in pairs(anim.Humanoid:GetPlayingAnimationTracks()) do
								track:AdjustSpeed(slowMotionFactor)
							end
						end
					end
				end
			end
			
			local SFX2 = script.SFX2:Clone()
			SFX2.Parent = game.Workspace
			SFX2:Play()

			delay(5, function()
				SFX2:Destroy()
			end)
			
			player.Active.Value = false
			
			player.Character.Humanoid.WalkSpeed = 16
			player.Character.Humanoid.JumpPower = 50
			
			game.Debris:AddItem(CC,0)

			game.Workspace.Gravity = 196.2
			
			game.Workspace.TimeScale.Value = 1

			for _, part in pairs(game.Workspace:GetDescendants()) do
				if part and part:IsA("BasePart") and not part.Parent:FindFirstChild("Humanoid") and part.Anchored == false then
					local targetVelocity = part.Velocity / slowMotionFactor
					tweenVelocity(part, targetVelocity, transitionDuration)

					part.RotVelocity = part.RotVelocity / slowMotionFactor

					local bodyAngularVelocity = part:FindFirstChildOfClass("BodyAngularVelocity")
					if bodyAngularVelocity and part:FindFirstChild("Tag") then
						game.Debris:AddItem(part.Tag,0)

						bodyAngularVelocity.AngularVelocity = bodyAngularVelocity.AngularVelocity / slowMotionFactor*2
					end
				elseif part and part:IsA("BasePart") and part.Parent:FindFirstChild("Humanoid") and part.Anchored == false then
					if part.Parent.Parent.Name == "NPCs" and part.Parent:FindFirstChild("Tag") then
						game.Debris:AddItem(part.Parent.Tag,0)
						
						part.Parent.Humanoid.WalkSpeed = 10
						part.Parent.Humanoid.JumpPower = 50
						
						for _, track in pairs(part.Parent.Humanoid:GetPlayingAnimationTracks()) do
							track:AdjustSpeed(1)
						end
					end
				end
			end

			for _, anim in pairs(game.Players:GetPlayers()) do
				if anim:FindFirstChild("Humanoid") then
					for _, track in pairs(anim.Humanoid:GetPlayingAnimationTracks()) do
						track:AdjustSpeed(1)
					end

					if not isPlayerInSet(anim.UserId, SpeedTimePlayers) then
						game.Debris:AddItem(anim.Character.Tag,0)

						anim.Character.Humanoid.WalkSpeed = 16
						anim.Character.Humanoid.JumpPower = 50
					end
				end
			end

			SpeedTimePlayers[player.UserId] = if SpeedTimePlayers[player.UserId] then nil else true
		elseif player.Active.Value == true then
			player.Active.Value = false
		end
	elseif action == "Check" then
		Check(player)
	elseif action == "CheckVar" and player:FindFirstChild("Flag") then
		game.Debris:AddItem(player.Flag,0)
	end
end)
