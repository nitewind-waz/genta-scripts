--  CONFIGURATION

local items = {
    sprig = {id = 7000, name = "Sprig of Mint"},
    water   = {id = 822, name = "Water"},
    orange = {id = 4984, name = "Orange Juice"},
    lemon  = {id = 4666, name = "Onion"},
    sugar   = {id = 4572, name = "Sugar"},
    fist   = {id = 18, name = "Fist"},
    wrench   = {id = 32, name = "Wrench"},
}

local isCooking = false
local isSugar = false

-- UTILITY

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
        [items.sprig.id] = 15,
        [items.water.id] = 15,
        [items.lemon.id] = 15,
        [items.sugar.id] = 15,
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
        
        statusText = "Pre-cook: Putting Water"
        for xRow = 0, 4 do
            if xRow ~= 3 do
                for row = 0, 5 do
                    if not isCooking then return end
                    local targetX, targetY = startX + xRow, startY + row
                    sendRaw(3, items.wrench.id, targetX, targetY) -- Wrenching to the oven
                    sleep(200)
                    sendCookPacket(targetX, targetY, items.water.id)
                    sleep(getRandomDelay())
                end
            end
        end

        local startTime = os.time()

        -- PHASE 1: Orange Juice
        statusText = "PHASE 1: Putting Orange Juice"
        -- Bagian 3 atas
        for xRow = 0, 4 do
            if xRow ~= 3 then
                for row = 0, 2 do
                    if not isCooking then return end
                    sendRaw(3, items.orange.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
                sleep(5000)
            end
        end

        -- Bagian 3 bawah
        for xRow = 0, 4 do
            if xRow ~= 3 then
                for row = 3, 5 do
                    if not isCooking then return end
                    sendRaw(3, items.orange.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
                sleep(5000)
            end
        end

        statusText = "PHASE 2 Lemon & Sprig of Mint"
        -- Bagian Atas
        for xRow = 0, 4 do
            if xRow ~= 3 then
                for row = 0, 2 do
                    if not isCooking then return end
                    sendRaw(3, items.lemon.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
                for row = 0, 2 do
                    if not isCooking then return end
                    sendRaw(3, items.sprig.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
                for row = 0, 2 do
                    if not isCooking then return end
                    sendRaw(3, items.fist.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
            end
        end

        -- Bagian Bawah
        for xRow = 0, 4 do
            if xRow ~= 3 do     
                for row = 3, 5 do
                    if not isCooking then return end
                    sendRaw(3, items.lemon.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
                for row = 3, 5 do
                    if not isCooking then return end
                    sendRaw(3, items.sprig.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
                for row = 3, 5 do
                    if not isCooking then return end
                    sendRaw(3, items.fist.id, startX + xRow, startY + row)
                    sleep(getRandomDelay())
                end
            end
        end


        -- PHASE 3: Onion
        statusText = "PHASE 3: Putting Onion"
        local onionWait = 56
        for xRow = 0, 2 do
            if not waitTime(onionWait, startTime) then return end
            for row = 0, 4 do
                if not isCooking then return end
                sendRaw(3, items.onion.id, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            onionWait = onionWait + 6
        end

        -- PHASE 4: Milk & Tomato
        statusText = "PHASE 4: Milk & Tomato"
        local milkWait = 89
        for xRow = 0, 2 do
            if not waitTime(milkWait, startTime) then return end
            for row = 0, 4 do
                if not isCooking then return end
                sendRaw(3, items.milk.id, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            if not waitTime(milkWait + 3, startTime) then return end
            for row = 0, 4 do
                if not isCooking then return end
                sendRaw(3, items.tomato.id, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            milkWait = milkWait + 6
        end

        -- PHASE 5: Punching
        statusText = "PHASE 5: Punching"
        local punchWait = 122
        for xRow = 0, 2 do
            if not waitTime(punchWait, startTime) then return end
            for row = 0, 4 do
                if not isCooking then return end
                sendRaw(3, 18, startX + xRow, startY + row)
                sleep(getRandomDelay())
            end
            punchWait = punchWait + 6
        end
        
        logToConsole("`9[CYCLE] `wSiklus " .. currentCycle .. " selesai.")
        sleep(500) 
    end
end
