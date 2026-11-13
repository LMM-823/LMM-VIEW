-- 创建 UI 界面
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- 防止重复创建
if playerGui:FindFirstChild("LMMViewGui") then
    playerGui.LMMViewGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LMMViewGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999 -- 提高最高渲染优先级，盖过所有其他 UI
screenGui.Parent = playerGui

-- 主面板 (纯正方形/直角风格，稍微加宽一点以容纳三个按钮)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 220)
mainFrame.Position = UDim2.new(0.5, -180, 0.4, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui

-- 标题: LMM View (超大字体)
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -45, 0, 65)
titleLabel.Position = UDim2.new(0, 15, 0, 12)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "LMM View"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 36
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 2
titleLabel.Parent = mainFrame

-- 右上角 X 关闭按钮
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -45, 0, 15)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.SourceSansBold
closeButton.ZIndex = 2
closeButton.Parent = mainFrame

-- 下拉菜单的主按钮
local dropdownButton = Instance.new("TextButton")
dropdownButton.Size = UDim2.new(0.88, 0, 0, 40)
dropdownButton.Position = UDim2.new(0.06, 0, 0, 90)
dropdownButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
dropdownButton.BorderSizePixel = 1
dropdownButton.BorderColor3 = Color3.fromRGB(70, 70, 70)
dropdownButton.Text = " Viewing: Self (自己) ▼"
dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownButton.TextSize = 16
dropdownButton.Font = Enum.Font.SourceSansBold
dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
dropdownButton.ZIndex = 2
dropdownButton.Parent = mainFrame

-- 弹出的选项列表框（悬浮在按钮上方）
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(0.88, 0, 0, 120)
listFrame.Position = UDim2.new(0.06, 0, 0, 131)
listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
listFrame.BorderSizePixel = 1
listFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
listFrame.Visible = false
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.ScrollBarThickness = 6
listFrame.ZIndex = 10
listFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = listFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 倒回上一个人按钮 (Prev)
local prevButton = Instance.new("TextButton")
prevButton.Size = UDim2.new(0.28, 0, 0, 45)
prevButton.Position = UDim2.new(0.06, 0, 0, 145)
prevButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- 蓝色
prevButton.BorderSizePixel = 0
prevButton.Text = "Prev"
prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
prevButton.TextSize = 16
prevButton.Font = Enum.Font.SourceSansBold
prevButton.ZIndex = 2
prevButton.Parent = mainFrame

-- 切换下一个玩家按钮 (Next)
local nextButton = Instance.new("TextButton")
nextButton.Size = UDim2.new(0.28, 0, 0, 45)
nextButton.Position = UDim2.new(0.36, 0, 0, 145)
nextButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- 绿色
nextButton.BorderSizePixel = 0
nextButton.Text = "Next"
nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
nextButton.TextSize = 16
nextButton.Font = Enum.Font.SourceSansBold
nextButton.ZIndex = 2
nextButton.Parent = mainFrame

-- 恢复自己视角按钮 (Reset)
local selfButton = Instance.new("TextButton")
selfButton.Size = UDim2.new(0.28, 0, 0, 45)
selfButton.Position = UDim2.new(0.66, 0, 0, 145)
selfButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- 红色
selfButton.BorderSizePixel = 0
selfButton.Text = "Reset"
selfButton.TextColor3 = Color3.fromRGB(255, 255, 255)
selfButton.TextSize = 16
selfButton.Font = Enum.Font.SourceSansBold
selfButton.ZIndex = 2
selfButton.Parent = mainFrame

-- 获取有效玩家列表
local function getValidPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            table.insert(list, p)
        end
    end
    return list
end

-- 刷新下拉菜单列表
local function updateDropdownList()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local validList = getValidPlayers()
    
    -- 添加 "自己" 选项
    local selfOption = Instance.new("TextButton")
    selfOption.Size = UDim2.new(1, 0, 0, 35)
    selfOption.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    selfOption.BorderSizePixel = 0
    selfOption.Text = "  Self (自己)"
    selfOption.TextColor3 = Color3.fromRGB(255, 255, 255)
    selfOption.TextSize = 15
    selfOption.Font = Enum.Font.SourceSans
    selfOption.TextXAlignment = Enum.TextXAlignment.Left
    selfOption.ZIndex = 11
    selfOption.Parent = listFrame
    
    selfOption.MouseButton1Click:Connect(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
            dropdownButton.Text = " Viewing: Self (自己) ▼"
        end
        listFrame.Visible = false
    end)
    
    -- 添加其他玩家名字
    for _, p in ipairs(validList) do
        local opt = Instance.new("TextButton")
        opt.Size = UDim2.new(1, 0, 0, 35)
        opt.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        opt.BorderSizePixel = 0
        opt.Text = "  " .. p.Name
        opt.TextColor3 = Color3.fromRGB(255, 255, 255)
        opt.TextSize = 15
        opt.Font = Enum.Font.SourceSans
        opt.TextXAlignment = Enum.TextXAlignment.Left
        opt.ZIndex = 11
        opt.Parent = listFrame
        
        opt.MouseButton1Click:Connect(function()
            if p.Character and p.Character:FindFirstChild("Humanoid") then
                camera.CameraSubject = p.Character.Humanoid
                dropdownButton.Text = " Viewing: " .. p.Name .. " ▼"
            end
            listFrame.Visible = false
        end)
    end
    
    listFrame.CanvasSize = UDim2.new(0, 0, 0, (#validList + 1) * 35)
end

-- 点击状态栏展开/收起下拉菜单
dropdownButton.MouseButton1Click:Connect(function()
    if listFrame.Visible then
        listFrame.Visible = false
    else
        updateDropdownList()
        listFrame.Visible = true
    end
end)

-- 循环切换下一个玩家
local currentIndex = 0
nextButton.MouseButton1Click:Connect(function()
    local validList = getValidPlayers()
    if #validList == 0 then
        dropdownButton.Text = " No players available!"
        return
    end
    
    currentIndex = currentIndex + 1
    if currentIndex > #validList then
        currentIndex = 1
    end
    
    local target = validList[currentIndex]
    if target and target.Character and target.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = target.Character.Humanoid
        dropdownButton.Text = " Viewing: " .. target.Name .. " ▼"
    end
    listFrame.Visible = false
end)

-- 倒回上一个人
prevButton.MouseButton1Click:Connect(function()
    local validList = getValidPlayers()
    if #validList == 0 then
        dropdownButton.Text = " No players available!"
        return
    end
    
    currentIndex = currentIndex - 1
    if currentIndex < 1 then
        currentIndex = #validList
    end
    
    local target = validList[currentIndex]
    if target and target.Character and target.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = target.Character.Humanoid
        dropdownButton.Text = " Viewing: " .. target.Name .. " ▼"
    end
    listFrame.Visible = false
end)

-- 恢复自己视角
selfButton.MouseButton1Click:Connect(function()
    currentIndex = 0
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = player.Character.Humanoid
        dropdownButton.Text = " Viewing: Self (自己) ▼"
    end
    listFrame.Visible = false
end)

-- 关闭按钮
closeButton.MouseButton1Click:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = player.Character.Humanoid
    end
    screenGui:Destroy()
end)
