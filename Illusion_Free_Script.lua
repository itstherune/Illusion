local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Illusion Free Script",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "by rune",
   Theme = "Default",
   ToggleUIKeybind = "K", -- Press K to open/close UI (ESC no longer breaks it)
   ConfigurationSaving = {
      Enabled = false
   },
   KeySystem = false
})

local Tab = Window:CreateTab("Main", 4483362458)

getgenv().GainMuscle = false
getgenv().SellMuscle = false

Tab:CreateToggle({
   Name = "Auto Gain Muscle",
   CurrentValue = false,
   Flag = "GainMuscle",
   Callback = function(Value)
      getgenv().GainMuscle = Value
      if Value then
         task.spawn(function()
            while getgenv().GainMuscle do
               pcall(function()
                  local args = {
                     {
                        "GainMuscle"
                     }
                  }
                  game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
               end)
               task.wait(0.1)
            end
         end)
      end
   end,
})

Tab:CreateToggle({
   Name = "Auto Sell Muscle",
   CurrentValue = false,
   Flag = "SellMuscle",
   Callback = function(Value)
      getgenv().SellMuscle = Value
      if Value then
         task.spawn(function()
            while getgenv().SellMuscle do
               pcall(function()
                  local args = {
                     {
                        "SellMuscle"
                     }
                  }
                  game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
               end)
               task.wait(0.1)
            end
         end)
      end
   end,
})
