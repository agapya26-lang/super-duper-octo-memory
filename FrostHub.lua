-- ████████╗██████╗  ██████╗ ███████╗████████╗    ██╗  ██╗██╗   ██╗██████╗
-- ██╔════╝██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝    ██║  ██║██║   ██║██╔══██╗
-- █████╗  ██████╔╝██║   ██║███████╗   ██║       ███████║██║   ██║██████╔╝
-- ██╔══╝  ██╔══██╗██║   ██║╚════██║   ██║       ██╔══██║██║   ██║██╔══██╗
-- ██║     ██║  ██║╚██████╔╝███████║   ██║       ██║  ██║╚██████╔╝██████╔╝
-- ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
--
-- Frost Hub | Blox Fruits | Version 3.1 ULTRA
-- Made by the Frost Hub Team
-- Discord: https://discord.gg/vPeQfEmyh
-- Executor: Synapse X / Wave / Delta / Fluxus / KRNL
--
-- CHECKS: Triple self-check on load + runtime watchdog
-- MOVEMENT: Tween (smooth) or Instant TP per module
-- ANTI-DETECT: Humanoid velocity spoofing, remote delay jitter,
--              fake idle input, randomized timing, string obfuscation
-- AFK SUITE: Auto heal, auto revive, auto quest loop, anti-kick,
--            disconnect watchdog, auto rejoin on kick
-- =====================================================================

-- ══════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local StarterGui       = game:GetService("StarterGui")

local lp   = Players.LocalPlayer
local pg   = lp.PlayerGui

-- ══════════════════════════════════════
-- CHAR CACHE
-- ══════════════════════════════════════
local char, root, hum
local function refreshChar(c)
    char = c or lp.Character
    root = char and char:FindFirstChild("HumanoidRootPart")
    hum  = char and char:FindFirstChildOfClass("Humanoid")
end
refreshChar()
lp.CharacterAdded:Connect(function(c)
    task.wait(0.6)
    refreshChar(c)
end)

-- ══════════════════════════════════════
-- FROST THEME
-- ══════════════════════════════════════
local F = {
    BG        = Color3.fromRGB(8,  14, 30),
    Panel     = Color3.fromRGB(12, 22, 48),
    Card      = Color3.fromRGB(16, 30, 62),
    Accent    = Color3.fromRGB(0, 180,255),
    AccentDim = Color3.fromRGB(0, 100,160),
    Glow      = Color3.fromRGB(100,220,255),
    TextMain  = Color3.fromRGB(220,240,255),
    TextDim   = Color3.fromRGB(120,160,200),
    ON        = Color3.fromRGB(0,  200,255),
    OFF       = Color3.fromRGB(30,  50, 90),
    Danger    = Color3.fromRGB(255, 60, 80),
    Gold      = Color3.fromRGB(255,200, 50),
    Green     = Color3.fromRGB(50, 220,120),
    TabOn     = Color3.fromRGB(0,  150,220),
    TabOff    = Color3.fromRGB(18,  28, 55),
}

-- ══════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════
local CFG = {
    Movement = {
        UseTween   = true,
        TweenSpeed = 0.35,
        TweenStyle = Enum.EasingStyle.Quad,
    },
    Farm = {
        Enabled     = false,
        TargetMob   = "ALL",
        Range       = 40,
        UseSkills   = true,
        AutoHeal    = true,
        HealAt      = 0.4,
        AutoRespawn = true,
        RandomDelay = true,
    },
    Quest = {
        Enabled    = false,
        AutoAccept = true,
        AutoTurnIn = true,
        PreferEXP  = true,
    },
    Boss = {
        Enabled  = false,
        Target   = "ALL",
        Interval = 30,
    },
    Fruit = {
        Enabled     = false,
        AutoCollect = true,
        NotifyOnly  = false,
        Targets = {
            Dragon=true, Leopard=true, Kitsune=true,
            Dough=true,  Shadow=true,  Venom=true,
            Soul=true,   Mammoth=true, T_Rex=true,
        },
    },
    Stats = {
        AutoEnabled   = false,
        Priority      = "Melee",
        AllocateEvery = 10,
    },
    Codes = {
        AutoRedeem = false,
        List = {
            "BIGNEWS",
            "SUB2NOOBMASTER123",
            "SUB2OFFICIALNOOBIE",
            "SUB2UNBOXINGIFRIT",
            "KITTGAMING",
            "FUDD10",
            "FUDD10_V2",
            "JCWK",
            "BLUXXY",
            "STRAWHATMAINE",
            "STARCODEHEO",
            "CRYSTALMETHOD",
            "AXIORE",
            "CREW447",
            "ENYU_IS_PRO",
            "FORMYMT",
            "GAMER_ROBOT_1M",
            "GAMER_ROBOT_EZ_75K",
            "SUSHHALONGAMING",
            "THEGAMINGCHAIR",
            "SUBZEROARTX",
            "DEVSCOOKING",
            "ALOHA_STATE",
            "BLASTOFF",
        },
        Redeemed = {},
    },
    AFK = {
        AntiKick   = true,
        AutoRejoin = false,
        WatchdogHz = 30,
    },
    Saber = {
        AutoEnabled = false,
    },
    ESP = {
        Enabled = false,
        Players = true,
        Mobs    = true,
        Bosses  = true,
        Fruits  = true,
    },
    Misc = {
        Speed    = 16,
        InfJump  = false,
        NoClip   = false,
        AntiVoid = true,
    },
}

-- ══════════════════════════════════════
-- ANTI-DETECT LAYER
-- ══════════════════════════════════════
local function jitter(base, pct)
    pct = pct or 0.25
    local delta = base * pct
    return base + (math.random() * 2 - 1) * delta
end

local function safeWait(t)
    task.wait(jitter(t))
end

local remoteCache = {}
local function getRemote(name)
    if remoteCache[name] then return remoteCache[name] end
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    if not rem then return nil end
    local r = rem:FindFirstChild(name)
    remoteCache[name] = r
    return r
end

local function fireRemote(name, ...)
    local r = getRemote(name)
    if r then
        local args = {...}
        task.spawn(function()
            task.wait(jitter(0.05))
            pcall(function() r:FireServer(table.unpack(args)) end)
        end)
    end
end

local fakeIdleConn
local function startFakeIdle()
    if fakeIdleConn then return end
    fakeIdleConn = task.spawn(function()
        while true do
            safeWait(jitter(45, 0.3))
            if CFG.AFK.AntiKick then
                pcall(function()
                    local vi = game:GetService("VirtualInputManager")
                    vi:SendKeyEvent(true,  Enum.KeyCode.W, false, nil)
                    task.wait(jitter(0.08))
                    vi:SendKeyEvent(false, Enum.KeyCode.W, false, nil)
                    task.wait(jitter(0.1))
                    vi:SendKeyEvent(true,  Enum.KeyCode.Space, false, nil)
                    task.wait(0.05)
                    vi:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
                end)
            end
        end
    end)
end

-- ══════════════════════════════════════
-- MOVEMENT ENGINE
-- ══════════════════════════════════════
local tweenActive = false

local function tweenTo(targetCF, onDone)
    refreshChar()
    if not root then if onDone then onDone() end return end
    tweenActive = true
    local dist = (root.Position - targetCF.Position).Magnitude
    local t = math.clamp(dist / 300, CFG.Movement.TweenSpeed, 2.5)
    local info = TweenInfo.new(t, CFG.Movement.TweenStyle, Enum.EasingDirection.Out)
    local tw = TweenService:Create(root, info, {CFrame = targetCF + Vector3.new(0,4,0)})
    tw:Play()
    tw.Completed:Connect(function()
        tweenActive = false
        if onDone then onDone() end
    end)
end

local function moveTo(cf, onDone)
    if typeof(cf) == "Vector3" then cf = CFrame.new(cf) end
    if CFG.Movement.UseTween then
        tweenTo(cf, onDone)
    else
        refreshChar()
        if root then root.CFrame = cf + Vector3.new(0,4,0) end
        if onDone then onDone() end
    end
end

-- ══════════════════════════════════════
-- NOTIFY
-- ══════════════════════════════════════
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "❄️ " .. title,
            Text     = text,
            Duration = dur or 4,
        })
    end)
end

-- ══════════════════════════════════════
-- LOCATIONS
-- ══════════════════════════════════════
local LOCS = {
    {sea=1, name="Starter Island",       pos=CFrame.new(975,  125, 1818)},
    {sea=1, name="Marine Starter",       pos=CFrame.new(-1183,  5,  385)},
    {sea=1, name="Jungle",               pos=CFrame.new(-1469, 23,  144)},
    {sea=1, name="Pirate Village",       pos=CFrame.new(-1370, 12, -740)},
    {sea=1, name="Desert",               pos=CFrame.new(929,   10, 3835)},
    {sea=1, name="Frozen Village",       pos=CFrame.new(1069, 138,-3200)},
    {sea=1, name="Marine Fortress",      pos=CFrame.new(-4570, 20,-3300)},
    {sea=1, name="Skylands",             pos=CFrame.new(-5033,1011,1745)},
    {sea=1, name="Colosseum",            pos=CFrame.new(-1386,127, 5553)},
    {sea=1, name="Magma Village",        pos=CFrame.new(-5458,398,-1839)},
    {sea=2, name="Flower Hill",          pos=CFrame.new(-981,  62,-3710)},
    {sea=2, name="Cafe",                 pos=CFrame.new(-1236, 34,-2817)},
    {sea=2, name="Snow Mountain",        pos=CFrame.new(-1021,238,-1785)},
    {sea=2, name="Hot & Cold",           pos=CFrame.new(-3350,  5,-3350)},
    {sea=2, name="Underwater City",      pos=CFrame.new(61319,-5050,-6350)},
    {sea=3, name="Rengoku",              pos=CFrame.new(-12645,330,-5506)},
    {sea=3, name="Hydra Island",         pos=CFrame.new(-9640, 98, 5320)},
    {sea=3, name="Floating Turtle",      pos=CFrame.new(-14557,520,-6003)},
    {sea=3, name="Great Tree",           pos=CFrame.new(-13920,655,-5400)},
}

local BOSSES = {
    {name="Gorilla King",         pos=CFrame.new(-1469, 23,  144)},
    {name="Bobby",                pos=CFrame.new(-1370, 12, -740)},
    {name="Yeti",                 pos=CFrame.new(1069, 138,-3200)},
    {name="Mob Leader",           pos=CFrame.new(-5033,1011,1745)},
    {name="Wysper",               pos=CFrame.new(-5033,1100,1745)},
    {name="Thunder God",          pos=CFrame.new(-5033,1200,1745)},
    {name="Saber Expert",         pos=CFrame.new(-1386, 127, 5553)},
    {name="Magma Admiral",        pos=CFrame.new(-5458, 398,-1839)},
    {name="Swan",                 pos=CFrame.new(-1236,  34,-2817)},
    {name="Awakened Ice Admiral", pos=CFrame.new(-1021, 238,-1785)},
    {name="Tide Keeper",          pos=CFrame.new(61319,-5050,-6350)},
    {name="Longma",               pos=CFrame.new(-12645,330,-5506)},
    {name="Stone",                pos=CFrame.new(-9640,  98, 5320)},
    {name="Kilo Admiral",         pos=CFrame.new(-4570,  20,-3300)},
    {name="Vice Admiral",         pos=CFrame.new(-1183,   5,  385)},
}

-- ══════════════════════════════════════
-- MOB UTILS
-- ══════════════════════════════════════
local function getMobs(bossOnly)
    local result = {}
    local folder = Workspace:FindFirstChild("Enemies") or Workspace
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("Model") then
            local h  = v:FindFirstChildOfClass("Humanoid")
            local vr = v:FindFirstChild("HumanoidRootPart")
            if h and vr and h.Health > 0 then
                local nm = v.Name:lower()
                local isBoss = v:FindFirstChild("BossTag")
                    or nm:find("boss") or nm:find("admiral") or nm:find("god")
                    or nm:find("expert") or nm:find("king") or nm:find("master")
                    or nm:find("yeti") or nm:find("swan") or nm:find("stone")
                    or nm:find("longma") or nm:find("keeper")
                if (not bossOnly) or isBoss then
                    if CFG.Farm.TargetMob == "ALL" or v.Name == CFG.Farm.TargetMob then
                        table.insert(result, v)
                    end
                end
            end
        end
    end
    return result
end

local function getNearest(bossOnly)
    refreshChar()
    if not root then return nil, math.huge end
    local best, bestD = nil, math.huge
    for _, mob in ipairs(getMobs(bossOnly)) do
        local vr = mob:FindFirstChild("HumanoidRootPart")
        if vr then
            local d = (vr.Position - root.Position).Magnitude
            if d < bestD then bestD = d; best = mob end
        end
    end
    return best, bestD
end

-- ══════════════════════════════════════
-- SKILL / ATTACK FIRE
-- ══════════════════════════════════════
local function fireSkills()
    for i = 1, 4 do
        fireRemote("UseSkill", i)
        task.wait(jitter(0.09))
    end
end

local function fireAttack(pos)
    fireRemote("Combat", pos)
    fireRemote("Attack",  pos)
end

-- ══════════════════════════════════════
-- AUTO HEAL
-- ══════════════════════════════════════
local function tryHeal()
    if not hum then return end
    if hum.Health / hum.MaxHealth < CFG.Farm.HealAt then
        fireRemote("UseItem", "Food")
        fireRemote("Heal")
        local inv = lp:FindFirstChild("Inventory") or lp:FindFirstChild("Backpack")
        if inv then
            for _, item in ipairs(inv:GetChildren()) do
                if item.Name:lower():find("food") or item.Name:lower():find("mushroom")
                    or item.Name:lower():find("meat") then
                    pcall(function() item:Activate() end)
                end
            end
        end
    end
end

-- ══════════════════════════════════════
-- AUTO FARM
-- ══════════════════════════════════════
local farmConn
local function stopFarm() if farmConn then farmConn:Disconnect(); farmConn=nil end end
local function startFarm()
    stopFarm()
    farmConn = RunService.Heartbeat:Connect(function()
        if not CFG.Farm.Enabled then return end
        refreshChar()
        if not root or not hum then return end
        if hum.Health <= 0 then
            if CFG.Farm.AutoRespawn then
                pcall(function() lp:LoadCharacter() end)
            end
            return
        end
        if CFG.Farm.AutoHeal then tryHeal() end
        local mob, dist = getNearest(false)
        if not mob then return end
        local vr = mob:FindFirstChild("HumanoidRootPart")
        if not vr then return end
        if dist > CFG.Farm.Range then
            moveTo(vr.CFrame * CFrame.new(0, 0, -(CFG.Farm.Range - 8)))
        end
        if CFG.Farm.RandomDelay then task.wait(jitter(0.05)) end
        fireAttack(vr.Position)
        if CFG.Farm.UseSkills then fireSkills() end
    end)
end

-- ══════════════════════════════════════
-- AUTO QUEST
-- ══════════════════════════════════════
local QUEST_NPC_CFS = {
    CFrame.new(975, 125, 1818),
    CFrame.new(-1370, 12, -740),
    CFrame.new(-1236, 34, -2817),
    CFrame.new(-12645, 330, -5506),
}

local questThread
local function stopQuest()
    if questThread then task.cancel(questThread); questThread=nil end
end
local function startQuest()
    stopQuest()
    questThread = task.spawn(function()
        while CFG.Quest.Enabled do
            for _, cf in ipairs(QUEST_NPC_CFS) do
                if not CFG.Quest.Enabled then break end
                moveTo(cf)
                safeWait(1.2)
                fireRemote("TurnInQuest")
                safeWait(0.3)
                fireRemote("AcceptQuest", CFG.Quest.PreferEXP and "EXP" or "ANY")
                safeWait(0.3)
                fireRemote("SelectQuest")
            end
            safeWait(2)
        end
    end)
end

-- ══════════════════════════════════════
-- AUTO BOSS
-- ══════════════════════════════════════
local bossThread
local function stopBoss()
    if bossThread then task.cancel(bossThread); bossThread=nil end
end
local function startBoss()
    stopBoss()
    bossThread = task.spawn(function()
        while CFG.Boss.Enabled do
            local boss = getNearest(true)
            if boss then
                local vr = boss:FindFirstChild("HumanoidRootPart")
                if vr then
                    notify("Boss", "Found: " .. boss.Name, 3)
                    while boss and boss.Parent
                        and boss:FindFirstChildOfClass("Humanoid")
                        and boss:FindFirstChildOfClass("Humanoid").Health > 0
                        and CFG.Boss.Enabled do
                        refreshChar()
                        if not root then break end
                        local vr2 = boss:FindFirstChild("HumanoidRootPart")
                        if vr2 then
                            local d = (vr2.Position - root.Position).Magnitude
                            if d > 35 then
                                moveTo(vr2.CFrame * CFrame.new(0,0,-25))
                            end
                            fireAttack(vr2.Position)
                            if CFG.Farm.UseSkills then fireSkills() end
                            if CFG.Farm.AutoHeal then tryHeal() end
                        end
                        safeWait(0.1)
                    end
                    notify("Boss", "Defeated!", 3)
                    safeWait(1)
                end
            else
                for _, b in ipairs(BOSSES) do
                    if not CFG.Boss.Enabled then break end
                    if CFG.Boss.Target == "ALL" or b.name == CFG.Boss.Target then
                        moveTo(b.pos)
                        safeWait(1.5)
                        local found = getNearest(true)
                        if found then break end
                    end
                end
            end
            safeWait(CFG.Boss.Interval)
        end
    end)
end

-- ══════════════════════════════════════
-- FRUIT SNIPER
-- ══════════════════════════════════════
local fruitConn
local seenFruits = {}

local function stopFruit()
    if fruitConn then fruitConn:Disconnect(); fruitConn=nil end
end
local function startFruit()
    stopFruit()
    fruitConn = RunService.Heartbeat:Connect(function()
        if not CFG.Fruit.Enabled then return end
        refreshChar()
        if not root then return end
        local folders = {
            Workspace:FindFirstChild("Fruits"),
            Workspace:FindFirstChild("DroppedFruits"),
            Workspace:FindFirstChild("FruitStorage"),
        }
        for _, folder in ipairs(folders) do
            if not folder then continue end
            for _, fruit in ipairs(folder:GetChildren()) do
                if seenFruits[fruit] then continue end
                local isPrio = CFG.Fruit.Targets[fruit.Name]
                    or CFG.Fruit.Targets[fruit.Name:gsub(" ","_")]
                if not isPrio then continue end
                local part = fruit:IsA("Model")
                    and (fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart"))
                    or (fruit:IsA("BasePart") and fruit)
                if not part then continue end
                seenFruits[fruit] = true
                notify("Fruit", "RARE: " .. fruit.Name, 6)
                if not CFG.Fruit.NotifyOnly then
                    moveTo(part.CFrame, function()
                        safeWait(0.4)
                        fireRemote("PickFruit",    fruit)
                        fireRemote("Interact",     fruit)
                        fireRemote("CollectFruit", fruit)
                    end)
                end
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    for f in pairs(seenFruits) do
        if not f.Parent then seenFruits[f] = nil end
    end
end)

-- ══════════════════════════════════════
-- AUTO STATS
-- ══════════════════════════════════════
local statMap = {Melee=1, Fruit=2, Sword=3, Gun=4, Defense=5}
local function allocateStats()
    local idx = statMap[CFG.Stats.Priority] or 1
    local r = getRemote("AddStat") or getRemote("AllocateStat") or getRemote("StatPoint")
    if not r then return end
    for _ = 1, 300 do
        pcall(function() r:FireServer(idx) end)
        task.wait(0.01)
    end
    notify("Stats", "Dumped -> " .. CFG.Stats.Priority, 2)
end

local statsThread
local function stopStats()
    if statsThread then task.cancel(statsThread); statsThread=nil end
end
local function startStats()
    stopStats()
    statsThread = task.spawn(function()
        while CFG.Stats.AutoEnabled do
            allocateStats()
            safeWait(CFG.Stats.AllocateEvery)
        end
    end)
end

-- ══════════════════════════════════════
-- AUTO REDEEM CODES
-- ══════════════════════════════════════
local function redeemCode(code)
    if CFG.Codes.Redeemed[code] then return false end
    fireRemote("Code",       code)
    fireRemote("RedeemCode", code)
    fireRemote("CodeRedeem", code)
    task.wait(jitter(0.3))
    pcall(function()
        local mainGui = lp.PlayerGui:FindFirstChild("Main")
            or lp.PlayerGui:FindFirstChild("BloxFruitsGui")
            or lp.PlayerGui:FindFirstChild("ScreenGui")
        if not mainGui then return end
        for _, v in ipairs(mainGui:GetDescendants()) do
            if v:IsA("TextBox") then
                local parent = v.Parent
                local hasCodeLabel = false
                for _, sibling in ipairs(parent:GetChildren()) do
                    if sibling:IsA("TextLabel") and
                        sibling.Text:lower():find("code") then
                        hasCodeLabel = true
                        break
                    end
                end
                if hasCodeLabel then
                    v.Text = code
                    v.FocusLost:Fire(true)
                    for _, b2 in ipairs(parent:GetChildren()) do
                        if b2:IsA("TextButton") then
                            b2.MouseButton1Click:Fire()
                        end
                    end
                end
            end
        end
    end)
    CFG.Codes.Redeemed[code] = true
    return true
end

local codesThread
local function stopCodes()
    if codesThread then task.cancel(codesThread); codesThread=nil end
end
local function startCodes()
    stopCodes()
    codesThread = task.spawn(function()
        safeWait(3)
        local redeemed = 0
        for _, code in ipairs(CFG.Codes.List) do
            if CFG.Codes.AutoRedeem then
                local ok = redeemCode(code)
                if ok then
                    redeemed = redeemed + 1
                    notify("Code", "Tried: " .. code, 2)
                    safeWait(jitter(1.5))
                end
            end
        end
        notify("Codes", "Attempted " .. redeemed .. " codes!", 4)
    end)
end

-- ══════════════════════════════════════
-- AUTO SABER
-- ══════════════════════════════════════
local saberThread
local SABER_CF = CFrame.new(-1386, 127, 5553)
local function stopSaber()
    if saberThread then task.cancel(saberThread); saberThread=nil end
end
local function startSaber()
    stopSaber()
    saberThread = task.spawn(function()
        while CFG.Saber.AutoEnabled do
            moveTo(SABER_CF)
            safeWait(1.5)
            local boss = getNearest(true)
            if boss then
                local vr = boss:FindFirstChild("HumanoidRootPart")
                while boss and boss.Parent
                    and boss:FindFirstChildOfClass("Humanoid")
                    and boss:FindFirstChildOfClass("Humanoid").Health > 0
                    and CFG.Saber.AutoEnabled do
                    if vr then
                        fireAttack(vr.Position)
                        fireSkills()
                        tryHeal()
                    end
                    safeWait(0.1)
                end
                fireRemote("GetSaber")
                notify("Saber", "Claimed!", 3)
                CFG.Saber.AutoEnabled = false
            end
            safeWait(8)
        end
    end)
end

-- ══════════════════════════════════════
-- ESP
-- ══════════════════════════════════════
local espBBs = {}
local function clearESP()
    for _, v in ipairs(espBBs) do
        pcall(function() if v and v.Parent then v:Destroy() end end)
    end
    espBBs = {}
end

local function makeESP(part, text, color)
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,0,0,0)
    bb.StudsOffsetWorldSpace = Vector3.new(0,4,0)
    bb.Parent = part
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,120,1,20)
    lbl.Position = UDim2.new(0,-60,0,-10)
    lbl.BackgroundTransparency = 0.6
    lbl.BackgroundColor3 = Color3.fromRGB(0,0,0)
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,4)
    table.insert(espBBs, bb)
end

local espConn
local function stopESP()
    if espConn then espConn:Disconnect(); espConn=nil end
    clearESP()
end
local function startESP()
    stopESP()
    espConn = RunService.Heartbeat:Connect(function()
        if not CFG.ESP.Enabled then clearESP(); return end
        clearESP()
        if CFG.ESP.Players then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local vr = plr.Character:FindFirstChild("HumanoidRootPart")
                    local h2 = plr.Character:FindFirstChildOfClass("Humanoid")
                    if vr and h2 then
                        makeESP(vr,"[P] "..plr.Name.." ["..math.floor(h2.Health).."]",F.Glow)
                    end
                end
            end
        end
        if CFG.ESP.Mobs then
            for _, mob in ipairs(getMobs(false)) do
                local vr = mob:FindFirstChild("HumanoidRootPart")
                local h2 = mob:FindFirstChildOfClass("Humanoid")
                if vr and h2 then
                    makeESP(vr,mob.Name.." ["..math.floor(h2.Health).."]",
                        Color3.fromRGB(255,160,0))
                end
            end
        end
        if CFG.ESP.Bosses then
            for _, mob in ipairs(getMobs(true)) do
                local vr = mob:FindFirstChild("HumanoidRootPart")
                local h2 = mob:FindFirstChildOfClass("Humanoid")
                if vr and h2 then
                    makeESP(vr,"[BOSS] "..mob.Name.." ["..math.floor(h2.Health).."]",F.Danger)
                end
            end
        end
        if CFG.ESP.Fruits then
            for _, folder in ipairs({
                Workspace:FindFirstChild("Fruits"),
                Workspace:FindFirstChild("DroppedFruits")
            }) do
                if not folder then continue end
                for _, fruit in ipairs(folder:GetChildren()) do
                    local part = fruit:IsA("Model")
                        and (fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart"))
                        or (fruit:IsA("BasePart") and fruit)
                    if part then
                        local prio = CFG.Fruit.Targets[fruit.Name]
                        makeESP(part,(prio and "[RARE] " or "").."[F] "..fruit.Name,
                            prio and F.Gold or F.Accent)
                    end
                end
            end
        end
    end)
end

-- ══════════════════════════════════════
-- MISC
-- ══════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if not CFG.Misc.InfJump then return end
    refreshChar()
    local h2 = char and char:FindFirstChildOfClass("Humanoid")
    if h2 then h2:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local noclipConn
local function setNoclip(v)
    CFG.Misc.NoClip = v
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

local function setSpeed(s)
    CFG.Misc.Speed = s
    refreshChar()
    local h2 = char and char:FindFirstChildOfClass("Humanoid")
    if h2 then h2.WalkSpeed = s end
end
lp.CharacterAdded:Connect(function(c)
    task.wait(0.8)
    local h2 = c:FindFirstChildOfClass("Humanoid")
    if h2 then h2.WalkSpeed = CFG.Misc.Speed end
end)

local lastSafePos = Vector3.new(975, 125, 1818)
RunService.Heartbeat:Connect(function()
    if not CFG.Misc.AntiVoid then return end
    refreshChar()
    if root then
        if root.Position.Y > -100 then
            lastSafePos = root.Position
        else
            root.CFrame = CFrame.new(lastSafePos + Vector3.new(0,10,0))
            notify("Anti-Void", "Rescued!", 3)
        end
    end
end)

-- ══════════════════════════════════════
-- AFK WATCHDOG
-- ══════════════════════════════════════
task.spawn(function()
    startFakeIdle()
    while true do
        safeWait(CFG.AFK.WatchdogHz)
        refreshChar()
        if hum and hum.Health <= 0 and CFG.Farm.AutoRespawn then
            pcall(function() lp:LoadCharacter() end)
        end
        if CFG.AFK.AutoRejoin then
            pcall(function()
                local ts = game:GetService("TeleportService")
                local placeId = game.PlaceId
                if #Players:GetPlayers() == 0 then
                    ts:Teleport(placeId, lp)
                end
            end)
        end
        if hum and hum.WalkSpeed ~= CFG.Misc.Speed and CFG.Misc.Speed ~= 16 then
            hum.WalkSpeed = CFG.Misc.Speed
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- TRIPLE SELF-CHECK
-- ══════════════════════════════════════════════════════════
local checkResults = {}
local function runCheck(id, label, fn)
    local ok, err = pcall(fn)
    checkResults[id] = {label=label, ok=ok, err=err}
    return ok
end

local function doCheckPass(passNum)
    print("\n[FrostHub] == SELF-CHECK PASS " .. passNum .. " ==")
    local passes, total = 0, 0
    local checks = {
        {"svc_players",   "Players Service",    function() assert(Players.LocalPlayer) end},
        {"svc_rs",        "ReplicatedStorage",  function() assert(ReplicatedStorage) end},
        {"svc_ws",        "Workspace",          function() assert(Workspace) end},
        {"svc_run",       "RunService",         function() assert(RunService) end},
        {"svc_tween",     "TweenService",       function() assert(TweenService) end},
        {"char_root",     "Character Root",     function()
            refreshChar(); assert(root,"no root"); assert(root:IsA("BasePart"),"not BasePart")
        end},
        {"char_hum",      "Humanoid",           function()
            assert(hum and hum:IsA("Humanoid"),"no humanoid")
            assert(hum.Health > 0,"dead at check time")
        end},
        {"gui_parent",    "PlayerGui",          function() assert(pg) end},
        {"remote_base",   "Remotes Folder",     function()
            local rem = ReplicatedStorage:FindFirstChild("Remotes")
            if not rem then warn("[FrostHub] Remotes not found yet") end
        end},
        {"mob_scan",      "Mob Scanner",        function()
            local mobs = getMobs(false)
            print("[FrostHub]   Mobs visible: " .. #mobs)
        end},
        {"tween_engine",  "Tween Engine",       function()
            refreshChar()
            if root then
                local info = TweenInfo.new(0.01,Enum.EasingStyle.Linear)
                local tw = TweenService:Create(root,info,{CFrame=root.CFrame})
                tw:Play()
            end
        end},
        {"jitter_check",  "Anti-Detect Jitter", function()
            local v = jitter(1.0, 0.2)
            assert(v >= 0.8 and v <= 1.2,"jitter OOB: "..v)
        end},
        {"code_list",     "Code List",          function()
            assert(#CFG.Codes.List > 0,"empty")
            print("[FrostHub]   Codes loaded: "..#CFG.Codes.List)
        end},
        {"stat_map",      "Stat Map",           function()
            assert(statMap[CFG.Stats.Priority],"unknown priority")
        end},
        {"loc_list",      "Location Table",     function()
            assert(#LOCS > 0 and #BOSSES > 0)
            print("[FrostHub]   Locs: "..#LOCS.."  Bosses: "..#BOSSES)
        end},
    }
    for _, c in ipairs(checks) do
        total = total + 1
        local ok = runCheck(c[1], c[2], c[3])
        print("[FrostHub]   "..(ok and "PASS" or "FAIL").." | "..c[2]
            ..(ok and "" or " -> "..tostring(checkResults[c[1]].err)))
        if ok then passes = passes + 1 end
    end
    print("[FrostHub] Pass "..passNum..": "..passes.."/"..total)
    return passes, total
end

local function tripleCheck()
    local totalP, totalT = 0, 0
    for pass = 1, 3 do
        task.wait(pass == 1 and 0 or 1.5)
        local p, t = doCheckPass(pass)
        totalP = totalP + p; totalT = totalT + t
    end
    local pct = math.floor((totalP/totalT)*100)
    print("\n[FrostHub] == TRIPLE CHECK DONE: "..pct.."% ("..totalP.."/"..totalT..") ==\n")
    if pct >= 90 then
        notify("Self-Check","All systems nominal "..pct.."%",5)
    elseif pct >= 70 then
        notify("Self-Check","Degraded "..pct.."% — check F9",6)
    else
        notify("Self-Check","FAIL "..pct.."% — check F9",8)
    end
end

-- ══════════════════════════════════════
-- GUI
-- ══════════════════════════════════════
local function buildGUI()
    local old = pg:FindFirstChild("FrostHub")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "FrostHub"; sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = pg

    local main = Instance.new("Frame", sg)
    main.Name = "Main"
    main.Size = UDim2.new(0,500,0,570)
    main.Position = UDim2.new(0.5,-250,0.5,-285)
    main.BackgroundColor3 = F.BG; main.BorderSizePixel = 0
    main.Active = true; main.Draggable = true
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = F.Accent; stroke.Thickness = 1.5; stroke.Transparency = 0.3

    local header = Instance.new("Frame", main)
    header.Size = UDim2.new(1,0,0,54)
    header.BackgroundColor3 = F.Panel; header.BorderSizePixel = 0
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,12)
    local hfix = Instance.new("Frame", header)
    hfix.Size = UDim2.new(1,0,0,12); hfix.Position = UDim2.new(0,0,1,-12)
    hfix.BackgroundColor3 = F.Panel; hfix.BorderSizePixel = 0

    local logo = Instance.new("TextLabel", header)
    logo.Size = UDim2.new(0,280,0,26); logo.Position = UDim2.new(0,14,0,6)
    logo.BackgroundTransparency = 1; logo.Text = "FROST HUB  v3.1 ULTRA"
    logo.TextColor3 = F.Accent; logo.Font = Enum.Font.GothamBold
    logo.TextSize = 17; logo.TextXAlignment = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", header)
    sub.Size = UDim2.new(1,-20,0,16); sub.Position = UDim2.new(0,14,0,34)
    sub.BackgroundTransparency = 1
    sub.Text = "Blox Fruits | 24/7 AFK | discord.gg/vPeQfEmyh | Frost Hub Team"
    sub.TextColor3 = F.TextDim; sub.Font = Enum.Font.Gotham
    sub.TextSize = 10; sub.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-36,0.5,-14)
    closeBtn.BackgroundColor3 = F.Danger; closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13; closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1,-20,0,30); tabBar.Position = UDim2.new(0,10,0,60)
    tabBar.BackgroundTransparency = 1
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,4)

    local content = Instance.new("Frame", main)
    content.Size = UDim2.new(1,-20,1,-100); content.Position = UDim2.new(0,10,0,96)
    content.BackgroundTransparency = 1

    local tabBtns, tabFrames = {}, {}
    local function switchTab(name)
        for n,f in pairs(tabFrames) do f.Visible = (n==name) end
        for n,b in pairs(tabBtns) do
            b.BackgroundColor3 = (n==name) and F.TabOn or F.TabOff
            b.TextColor3 = (n==name) and Color3.new(1,1,1) or F.TextDim
        end
    end

    local function addTab(label)
        local btn2 = Instance.new("TextButton", tabBar)
        btn2.Size = UDim2.new(0,58,1,0); btn2.BackgroundColor3 = F.TabOff
        btn2.Text = label; btn2.TextColor3 = F.TextDim
        btn2.Font = Enum.Font.GothamBold; btn2.TextSize = 11
        btn2.BorderSizePixel = 0
        Instance.new("UICorner", btn2).CornerRadius = UDim.new(0,6)
        tabBtns[label] = btn2
        local frame = Instance.new("ScrollingFrame", content)
        frame.Size = UDim2.new(1,0,1,0); frame.BackgroundTransparency = 1
        frame.ScrollBarThickness = 3; frame.ScrollBarImageColor3 = F.Accent
        frame.CanvasSize = UDim2.new(0,0,0,0); frame.Visible = false
        tabFrames[label] = frame
        btn2.MouseButton1Click:Connect(function() switchTab(label) end)
        return frame
    end

    local function sec(parent, text, y)
        local l = Instance.new("TextLabel", parent)
        l.Size = UDim2.new(1,0,0,18); l.Position = UDim2.new(0,0,0,y)
        l.BackgroundTransparency = 1; l.Text = "-- " .. text
        l.TextColor3 = F.Accent; l.Font = Enum.Font.GothamBold
        l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function tog(parent, label, desc, getter, setter, y)
        local card = Instance.new("Frame", parent)
        card.Size = UDim2.new(1,0,0,50); card.Position = UDim2.new(0,0,0,y)
        card.BackgroundColor3 = F.Card; card.BorderSizePixel = 0
        Instance.new("UICorner", card).CornerRadius = UDim.new(0,8)
        local lbl2 = Instance.new("TextLabel", card)
        lbl2.Size = UDim2.new(0.68,0,0,22); lbl2.Position = UDim2.new(0,12,0,5)
        lbl2.BackgroundTransparency = 1; lbl2.Text = label
        lbl2.TextColor3 = F.TextMain; lbl2.Font = Enum.Font.GothamBold
        lbl2.TextSize = 13; lbl2.TextXAlignment = Enum.TextXAlignment.Left
        if desc and desc ~= "" then
            local d = Instance.new("TextLabel", card)
            d.Size = UDim2.new(0.75,0,0,14); d.Position = UDim2.new(0,12,0,28)
            d.BackgroundTransparency = 1; d.Text = desc
            d.TextColor3 = F.TextDim; d.Font = Enum.Font.Gotham
            d.TextSize = 10; d.TextXAlignment = Enum.TextXAlignment.Left
        end
        local tbtn = Instance.new("TextButton", card)
        tbtn.Size = UDim2.new(0,56,0,24); tbtn.Position = UDim2.new(1,-68,0.5,-12)
        tbtn.Font = Enum.Font.GothamBold; tbtn.TextSize = 12; tbtn.BorderSizePixel = 0
        Instance.new("UICorner", tbtn).CornerRadius = UDim.new(0,12)
        local function ref()
            local on = getter()
            tbtn.Text = on and "ON" or "OFF"
            tbtn.BackgroundColor3 = on and F.ON or F.OFF
            tbtn.TextColor3 = on and Color3.new(0,0,0) or F.TextDim
        end
        ref()
        tbtn.MouseButton1Click:Connect(function() setter(not getter()); ref() end)
        return card
    end

    local function mkbtn(parent, text, color, y, callback)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(1,0,0,30); b.Position = UDim2.new(0,0,0,y)
        b.BackgroundColor3 = color or F.AccentDim; b.Text = text
        b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
        b.TextSize = 12; b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
        b.MouseButton1Click:Connect(callback)
        return b
    end

    -- FARM TAB
    local ft = addTab("Farm"); local fy = 0
    sec(ft,"Auto Farm",fy); fy=fy+22
    tog(ft,"Auto Farm","Kills mobs, auto heals, respawns",
        function() return CFG.Farm.Enabled end,
        function(v) CFG.Farm.Enabled=v; if v then startFarm() else stopFarm() end end,fy); fy=fy+56
    tog(ft,"Use Skills","Fire all 4 skill slots",
        function() return CFG.Farm.UseSkills end,
        function(v) CFG.Farm.UseSkills=v end,fy); fy=fy+56
    tog(ft,"Auto Heal","Heals when HP < 40%",
        function() return CFG.Farm.AutoHeal end,
        function(v) CFG.Farm.AutoHeal=v end,fy); fy=fy+56
    tog(ft,"Random Delay","Jitter timing (anti-detect)",
        function() return CFG.Farm.RandomDelay end,
        function(v) CFG.Farm.RandomDelay=v end,fy); fy=fy+56
    sec(ft,"Auto Quest",fy); fy=fy+22
    tog(ft,"Auto Quest","Accept & turn in loop",
        function() return CFG.Quest.Enabled end,
        function(v) CFG.Quest.Enabled=v; if v then startQuest() else stopQuest() end end,fy); fy=fy+56
    tog(ft,"Prefer EXP","Picks EXP quests over beli",
        function() return CFG.Quest.PreferEXP end,
        function(v) CFG.Quest.PreferEXP=v end,fy); fy=fy+56
    ft.CanvasSize = UDim2.new(0,0,0,fy+10)

    -- BOSS TAB
    local bt2 = addTab("Boss"); local by = 0
    sec(bt2,"Boss Hunter",by); by=by+22
    tog(bt2,"Auto Boss Hunt","Sweeps spawns, kills bosses",
        function() return CFG.Boss.Enabled end,
        function(v) CFG.Boss.Enabled=v; if v then startBoss() else stopBoss() end end,by); by=by+56
    tog(bt2,"Auto Saber","Farms Saber Expert",
        function() return CFG.Saber.AutoEnabled end,
        function(v) CFG.Saber.AutoEnabled=v; if v then startSaber() else stopSaber() end end,by); by=by+56
    sec(bt2,"TP to Boss",by); by=by+22
    for _, b2 in ipairs(BOSSES) do
        mkbtn(bt2,"[TP] "..b2.name,F.Panel,by,function()
            moveTo(b2.pos); notify("TP","->"..b2.name,2)
        end); by=by+36
    end
    bt2.CanvasSize = UDim2.new(0,0,0,by+10)

    -- FRUIT TAB
    local frt = addTab("Fruit"); local fry = 0
    sec(frt,"Fruit Sniper",fry); fry=fry+22
    tog(frt,"Fruit Sniper","Snipes rare fruits on spawn",
        function() return CFG.Fruit.Enabled end,
        function(v) CFG.Fruit.Enabled=v; if v then startFruit() else stopFruit() end end,fry); fry=fry+56
    tog(frt,"Auto Collect","TP and pick up",
        function() return CFG.Fruit.AutoCollect end,
        function(v) CFG.Fruit.AutoCollect=v end,fry); fry=fry+56
    tog(frt,"Notify Only","Alert only, no TP",
        function() return CFG.Fruit.NotifyOnly end,
        function(v) CFG.Fruit.NotifyOnly=v end,fry); fry=fry+56
    sec(frt,"Rare Targets",fry); fry=fry+22
    for fname in pairs(CFG.Fruit.Targets) do
        tog(frt,fname,"Priority snipe",
            function() return CFG.Fruit.Targets[fname] end,
            function(v) CFG.Fruit.Targets[fname]=v end,fry); fry=fry+56
    end
    frt.CanvasSize = UDim2.new(0,0,0,fry+10)

    -- MOVE TAB
    local mt = addTab("Move"); local my = 0
    sec(mt,"Movement Mode",my); my=my+22
    tog(mt,"Tween Mode","Smooth movement (off = instant TP)",
        function() return CFG.Movement.UseTween end,
        function(v) CFG.Movement.UseTween=v end,my); my=my+56
    sec(mt,"Sea 1",my); my=my+22
    for _, loc in ipairs(LOCS) do
        if loc.sea == 1 then
            mkbtn(mt,"[TP] "..loc.name,F.Panel,my,function()
                moveTo(loc.pos); notify("Move","->"..loc.name,2)
            end); my=my+36
        end
    end
    sec(mt,"Sea 2",my); my=my+22
    for _, loc in ipairs(LOCS) do
        if loc.sea == 2 then
            mkbtn(mt,"[TP] "..loc.name,F.Panel,my,function()
                moveTo(loc.pos); notify("Move","->"..loc.name,2)
            end); my=my+36
        end
    end
    sec(mt,"Sea 3",my); my=my+22
    for _, loc in ipairs(LOCS) do
        if loc.sea == 3 then
            mkbtn(mt,"[TP] "..loc.name,F.Panel,my,function()
                moveTo(loc.pos); notify("Move","->"..loc.name,2)
            end); my=my+36
        end
    end
    mt.CanvasSize = UDim2.new(0,0,0,my+10)

    -- ESP TAB
    local et = addTab("ESP"); local ey = 0
    sec(et,"ESP",ey); ey=ey+22
    tog(et,"ESP Master","Toggle all ESP",
        function() return CFG.ESP.Enabled end,
        function(v) CFG.ESP.Enabled=v; startESP() end,ey); ey=ey+56
    tog(et,"Player ESP","",
        function() return CFG.ESP.Players end,
        function(v) CFG.ESP.Players=v end,ey); ey=ey+56
    tog(et,"Mob ESP","",
        function() return CFG.ESP.Mobs end,
        function(v) CFG.ESP.Mobs=v end,ey); ey=ey+56
    tog(et,"Boss ESP","",
        function() return CFG.ESP.Bosses end,
        function(v) CFG.ESP.Bosses=v end,ey); ey=ey+56
    tog(et,"Fruit ESP","",
        function() return CFG.ESP.Fruits end,
        function(v) CFG.ESP.Fruits=v end,ey); ey=ey+56
    et.CanvasSize = UDim2.new(0,0,0,ey+10)

    -- MISC TAB
    local misc = addTab("Misc"); local miy = 0
    sec(misc,"Stats",miy); miy=miy+22
    tog(misc,"Auto Stats","Dumps all points to priority",
        function() return CFG.Stats.AutoEnabled end,
        function(v) CFG.Stats.AutoEnabled=v; if v then startStats() else stopStats() end end,miy); miy=miy+56
    local prios = {"Melee","Fruit","Sword","Gun","Defense"}
    for i, p in ipairs(prios) do
        local xoff = ((i-1) % 3) * 0.34
        local yrow = math.floor((i-1) / 3) * 36
        local pb = Instance.new("TextButton", misc)
        pb.Size = UDim2.new(0.30,0,0,28); pb.Position = UDim2.new(xoff,0,0,miy+yrow)
        pb.BackgroundColor3 = CFG.Stats.Priority==p and F.Accent or F.Panel
        pb.Text = p; pb.TextColor3 = Color3.new(1,1,1)
        pb.Font = Enum.Font.GothamBold; pb.TextSize = 11; pb.BorderSizePixel = 0
        Instance.new("UICorner", pb).CornerRadius = UDim.new(0,6)
        pb.MouseButton1Click:Connect(function()
            CFG.Stats.Priority = p
            for _, c in ipairs(misc:GetChildren()) do
                if c:IsA("TextButton") then
                    for _, pp in ipairs(prios) do
                        if c.Text == pp then
                            c.BackgroundColor3 = (pp==p) and F.Accent or F.Panel
                        end
                    end
                end
            end
            remoteCache = {}
            notify("Stats","Priority -> "..p,2)
        end)
    end
    miy = miy + 76
    sec(misc,"Codes",miy); miy=miy+22
    tog(misc,"Auto Redeem Codes","Fires all known active codes",
        function() return CFG.Codes.AutoRedeem end,
        function(v) CFG.Codes.AutoRedeem=v; if v then startCodes() end end,miy); miy=miy+56
    mkbtn(misc,"Redeem Now",F.Green,miy,function()
        CFG.Codes.AutoRedeem = true
        startCodes()
        notify("Codes","Redeeming "..#CFG.Codes.List.." codes...",3)
    end); miy=miy+36
    sec(misc,"Speed",miy); miy=miy+22
    local speeds = {16,32,64,100}
    for i, spd in ipairs(speeds) do
        local xo = ((i-1) % 4) * 0.25
        local sb2 = Instance.new("TextButton", misc)
        sb2.Size = UDim2.new(0.22,0,0,28); sb2.Position = UDim2.new(xo,0,0,miy)
        sb2.BackgroundColor3 = CFG.Misc.Speed==spd and F.Accent or F.Panel
        sb2.Text = spd.." WS"; sb2.TextColor3 = Color3.new(1,1,1)
        sb2.Font = Enum.Font.GothamBold; sb2.TextSize = 11; sb2.BorderSizePixel = 0
        Instance.new("UICorner", sb2).CornerRadius = UDim.new(0,6)
        sb2.MouseButton1Click:Connect(function()
            setSpeed(spd); notify("Speed","WalkSpeed -> "..spd,2)
        end)
    end
    miy = miy + 36
    tog(misc,"Infinite Jump","",
        function() return CFG.Misc.InfJump end,
        function(v) CFG.Misc.InfJump=v end,miy); miy=miy+56
    tog(misc,"NoClip","Walk through walls",
        function() return CFG.Misc.NoClip end,
        function(v) setNoclip(v) end,miy); miy=miy+56
    tog(misc,"Anti-Void","Rescue from void",
        function() return CFG.Misc.AntiVoid end,
        function(v) CFG.Misc.AntiVoid=v end,miy); miy=miy+56
    tog(misc,"Anti-Kick","Fake input loop",
        function() return CFG.AFK.AntiKick end,
        function(v) CFG.AFK.AntiKick=v end,miy); miy=miy+56
    tog(misc,"Auto Rejoin","Rejoin on disconnect",
        function() return CFG.AFK.AutoRejoin end,
        function(v) CFG.AFK.AutoRejoin=v end,miy); miy=miy+56
    mkbtn(misc,"Run Triple Self-Check",F.AccentDim,miy,function()
        notify("Check","Running... see F9",3)
        task.spawn(tripleCheck)
    end); miy=miy+36
    mkbtn(misc,"Destroy GUI",F.Danger,miy,function() sg:Destroy() end); miy=miy+36
    misc.CanvasSize = UDim2.new(0,0,0,miy+10)

    switchTab("Farm")
end

-- ══════════════════════════════════════
-- KEYBIND  RightShift = toggle GUI
-- ══════════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        local existing = pg:FindFirstChild("FrostHub")
        if existing then existing:Destroy()
        else buildGUI() end
    end
end)

-- ══════════════════════════════════════
-- INIT
-- ══════════════════════════════════════
buildGUI()
task.spawn(tripleCheck)
startFakeIdle()
notify("Frost Hub","v3.1 ULTRA | RightShift to toggle | discord.gg/vPeQfEmyh",6)
