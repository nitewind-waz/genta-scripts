-- ==========================================
-- CONFIGURATION & ITEMS
-- ==========================================
local items = {
    recipe = {id = 7014, name = "Cosmic Spice"},
    rice   = {id = 3472, name = "Rice"},
    onion  = {id = 4602, name = "Onion"},
    milk   = {id = 868, name = "Milk"},
    tomato = {id = 962, name = "Tomato"}
}

local minDelay = 350
local maxDelay = 450
local targetCycles = 0
local currentCycle = 0

local isCooking = false
local statusText = "IDLE"
local timerDisplay = 0

-- UI Data
local sizeWindow, sizeBar, sizeButton 

local fmtStatus = "Status: %s"
local fmtInfo   = "Info: %s"
local fmtCycle  = "Cycle: %d / %s"
local fmtTimer  = "Timer: %ds / 156s"

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================
local function getRandomDelay()
    if minDelay > maxDelay then return maxDelay end
    return math.random(minDelay, maxDelay)
end

local function sendRaw(type, val, x, y)
    local p = getLocal()
    if p and p.pos then
        sendPacketRaw(false, {
            type = type,
            value = val,
            punchx = x,
            punchy = y,
            x = p.pos.x,
            y = p.pos.y
        })
    end
end

local function sendCookPacket(x, y, itemID)
    local pkt = string.format("action|dialog_return\ndialog_name|oven\ntilex|%d|\ntiley|%d|\ncookthis|%d|\nbuttonClicked|low", x, y, itemID)
    sendPacket(2, pkt)
end

local function waitTime(targetDuration, startTime)
    while (os.time() - startTime) < targetDuration do
        if not isCooking then return false end
        timerDisplay = os.time() - startTime
        sleep(100)
    end
    return true
end

local function checkIngredients()
    local inv = getInventory()
    if not inv then return false end

    local requiredItems = {
        [items.recipe.id] = 15,
        [items.rice.id] = 15,
        [items.onion.id] = 15,
        [items.milk.id] = 15,
        [items.tomato.id] = 15
    }

    local foundItems = {}
    for _, item in ipairs(inv) do
        if requiredItems[item.id] then
            foundItems[item.id] = item.amount
        end
    end

    for id, minLimit in pairs(requiredItems) do
        if not foundItems[id] or foundItems[id] <= minLimit then
            return false
        end
    end
    return true
end

-- ==========================================
-- Cook
-- ==========================================
function cook()
    local p = getLocal()
    if not p or not p.pos then isCooking = false return end

    local playerX = math.floor(p.pos.x / 32)
    local playerY = math.floor(p.pos.y / 32)
    local startX = playerX - 3
    local startY = playerY - 3

    currentCycle = 0
    logToConsole("`9[START] Posisi Oven: ("..startX..","..startY..")")

    while isCooking do
        if not checkIngredients() then
            isCooking = false
            statusText = "OUT OF INGREDIENTS"
            logToConsole("[STOP] Bahan habis. Auto dihentikan.")
            break
        end

        if targetCycles > 0 and currentCycle >= targetCycles then
            isCooking = false
            statusText = "FINISHED"
            logToConsole("[FINISH] selesai.")
            break
        end

        currentCycle = currentCycle + 1
        local startTime = os.time()

        statusText = "PHASE 1: Cosmic Spice"
        for xRow = 0, 2 do
            for row = 0, 5 do
                if not isCooking then return end
                local targetX, targetY = startX + xRow, startY + row
                sendRaw(3, 32, targetX, targetY)
                sleep(375)
                sendCookPacket(targetX, targetY, items.recipe.id)
                sleep(getRandomDelay())
            end
        end

        -- PHASE 2: Rice
        statusText = "PHASE 2: Putting Rice"
        if not waitTime(24, startTime) then return end
        for xRow = 0, 2 do
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.rice.id, startX + xRow, startY + row)
                sleep(math.random(400,450))
            end
        end
        
        statusText = "PHASE 1 Side 2: Cosmic Spice"
        if not waitTime(32, startTime) then return end
        for xRow = 4, 5 do
            for row = 0, 5 do
                if not isCooking then return end
                local targetX, targetY = startX + xRow, startY + row
                sendRaw(3, 32, targetX, targetY)
                sleep(200)
                sendCookPacket(targetX, targetY, items.recipe.id)
                sleep(getRandomDelay())
            end
        end
        

        statusText = "PHASE 2 Side 2: Putting Rice"
        if not waitTime(48, startTime) then return end
        for xRow = 4, 5 do
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.rice.id, startX + xRow, startY + row)
                sleep(math.random(250,450))
            end
        end

        -- PHASE 3: Onion
        statusText = "PHASE 3: Putting Onion"
        local onionWait = 56
        for xRow = 0, 2 do
            if not waitTime(onionWait, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.onion.id, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            onionWait = onionWait + 6
        end

        statusText = "PHASE 3: Putting Onion"
        local onionWait = 82
        for xRow = 4, 5 do
            if not waitTime(onionWait, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.onion.id, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            onionWait = onionWait + 4
        end
        
        sleep(500)
        -- PHASE 4: Milk & Tomato
        statusText = "PHASE 4: Milk & Tomato"
        local milkWait = 89
        for xRow = 0, 2 do
            if not waitTime(milkWait, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.milk.id, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            if not waitTime(milkWait + 3, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.tomato.id, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            milkWait = milkWait + 5
        end

        statusText = "PHASE 4 v2: Milk & Tomato"
        local milkWait = 113
        for xRow = 4, 5 do
            if not waitTime(milkWait, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.milk.id, startX + xRow, startY + row)
                sleep(math.random(250,350))
            end
            if not waitTime(milkWait + 3, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, items.tomato.id, startX + xRow, startY + row)
                sleep(math.random(250,350))
            end
            milkWait = milkWait + 1
        end

        -- PHASE 5: Punching
        statusText = "PHASE 5: Punching"
        local punchWait = 122
        for xRow = 0, 2 do
            if not waitTime(punchWait, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, 18, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            punchWait = punchWait + 6
        end

        statusText = "PHASE 5 v2: Punching"
        local punchWait = 148
        for xRow = 4, 5 do
            if not waitTime(punchWait, startTime) then return end
            for row = 0, 5 do
                if not isCooking then return end
                sendRaw(3, 18, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            punchWait = punchWait + 4
        end
        
        logToConsole("`9[CYCLE] `wSiklus " .. currentCycle .. " selesai.")
        sleep(500) 
    end
end

-- ==========================================
-- UI & HOOKS
-- ==========================================
local cachedDisplayTimer = -1
local cachedCycle = -1
local cachedTargetCycles = -1
local cachedIsCooking = nil
local cachedStatusText = ""

local textStatusFinal = ""
local textInfoFinal = ""
local textCycleFinal = ""
local textTimerFinal = ""

AddHook("OnRender", "CookMenu", function()
    -- FIX FORCE CLOSE: Inisialisasi ImVec2 cuma saat OnRender udah dipanggil
    if not sizeWindow then
        sizeWindow = ImVec2(350, 300)
        sizeBar    = ImVec2(-1, 20)
        sizeButton = ImVec2(-1, 50)
    end

    ImGui.SetNextWindowSize(sizeWindow, ImGui.Cond.FirstUseEver)
    
    local isWindowOpen = ImGui.Begin("Skill Spice Auto Cook - By Nitewindz")
    
    if isWindowOpen then
        if cachedIsCooking ~= isCooking then
            cachedIsCooking = isCooking
            textStatusFinal = string.format(fmtStatus, isCooking and "RUNNING" or "STOPPED")
        end
        
        if cachedStatusText ~= statusText then
            cachedStatusText = statusText
            textInfoFinal = string.format(fmtInfo, statusText)
        end

        if cachedCycle ~= currentCycle or cachedTargetCycles ~= targetCycles then
            cachedCycle = currentCycle
            cachedTargetCycles = targetCycles
            local cycleLimit = targetCycles == 0 and "Infinite" or tostring(targetCycles)
            textCycleFinal = string.format(fmtCycle, currentCycle, cycleLimit)
        end

        ImGui.Text(textStatusFinal)
        ImGui.Text(textInfoFinal)
        ImGui.Text(textCycleFinal)

        ImGui.Separator()
        if isCooking then
            if cachedDisplayTimer ~= timerDisplay then
                cachedDisplayTimer = timerDisplay
                textTimerFinal = string.format(fmtTimer, timerDisplay)
            end
            ImGui.Text(textTimerFinal)
            
            local prog = math.min(timerDisplay / 156, 1.0)
            ImGui.ProgressBar(prog, sizeBar)
        else
            ImGui.ProgressBar(0, sizeBar)
        end
        ImGui.Separator()

        minDelay = select(2, ImGui.SliderInt("Min Delay", minDelay, 200, 1500))
        maxDelay = select(2, ImGui.SliderInt("Max Delay", maxDelay, 200, 1500))
        targetCycles = select(2, ImGui.SliderInt("Cycles (0=Inf)", targetCycles, 0, 100))

        local btnLabel = isCooking and "STOP" or "START"
        if ImGui.Button(btnLabel, sizeButton) then
            if not isCooking then
                if checkIngredients() then
                    isCooking = true
                    runThread(cook)
                else
                    statusText = "CHECK INVENTORY!"
                end
            else
                isCooking = false
                statusText = "STOPPED"
            end
        end
    end
    ImGui.End()
end)

AddHook("OnVarlist", "NoOvenDialog", function(v)
    if isCooking and v[0] == "OnDialogRequest" and v[1]:find("oven") then
        return true
    end
end)
