-- =====================================================
-- ADAPTIVE CRYSTAL HARMONIZER
-- PERFECT WATER DETECTION + GUI VERSION
-- =====================================================

local harmonized = false
local latestDialog = ""

local ACTION_DELAY = 500
local LOOP_DELAY   = 500
local BREAK_DELAY  = 300

local botRunning = false
local statusText = "Idle"

-- =====================================================
-- CONFIG
-- =====================================================

local CHI = {

    earth = {
        fg = 2804,
        bg = 2788
    },

    fire = {
        fg = 1500,
        bg = 888
    },

    air = {
        fg = 8272,
        bg = 2796
    },

    water = {

        -- vastly more water
        fg = 1498,

        -- water bucket
        bucket = 822
    }
}

-- =====================================================
-- NEIGHBOR PRIORITY
-- =====================================================

local neighbors = {

    {-1,-1},
    { 0,-1},
    { 1,-1},

    {-1, 0},
    { 1, 0},

    {-1, 1},
    { 0, 1},
    { 1, 1}
}

-- =====================================================
-- POSITION
-- =====================================================

function getCrystalPosition()

    local px = math.floor(getLocal().pos.x / 32)
    local py = math.floor(getLocal().pos.y / 32)

    return px, py - 2
end

function getNeighborPosition(index)

    local cx, cy = getCrystalPosition()

    local dx = neighbors[index][1]
    local dy = neighbors[index][2]

    return cx + dx, cy + dy
end

-- =====================================================
-- HOOK
-- =====================================================

AddHook("OnVarlist", "crystal_hook", function(var)

    if var[0] == "OnDialogRequest" then

        latestDialog = var[1]

        local lower = latestDialog:lower()

        if lower:find("perfect harmonic resonance") or
           lower:find("true essence") then

            harmonized = true
            botRunning = false
            statusText = "Harmonized"

            logToConsole("`2Crystal Harmonized!")
        end

        return true
    end
end)

-- =====================================================
-- UNIVERSAL ACTION
-- =====================================================

function sendTileAction(itemid, x, y)

    sendPacketRaw(false, {

        type = 3,
        value = itemid,

        punchx = x,
        punchy = y,

        x = getLocal().pos.x,
        y = getLocal().pos.y
    })

    sleep(ACTION_DELAY)
end

-- =====================================================
-- BASIC ACTIONS
-- =====================================================

function wrenchCrystal()

    latestDialog = ""

    local cx, cy = getCrystalPosition()

    sendTileAction(32, cx, cy)
end

function placeFG(x, y, itemid)
    sendTileAction(itemid, x, y)
end

function placeBG(x, y, itemid)
    sendTileAction(itemid, x, y)
end

function useWaterBucket(x, y)
    sendTileAction(CHI.water.bucket, x, y)
end

-- =====================================================
-- BREAK BLOCK
-- =====================================================

function breakBlock(x, y)

    local oldfg = checkTile(x, y).fg

    if oldfg == 0 then
        return
    end

    local tries = 0

    while tries < 12 and botRunning do

        sendPacketRaw(false, {

            type = 3,
            value = 18,

            punchx = x,
            punchy = y,

            x = getLocal().pos.x,
            y = getLocal().pos.y
        })

        sleep(BREAK_DELAY)

        local newfg = checkTile(x, y).fg

        if newfg ~= oldfg then
            break
        end

        tries = tries + 1
    end
end

-- =====================================================
-- BREAK BG
-- =====================================================

function breakBG(x, y)

    local oldbg = checkTile(x, y).bg

    if oldbg == 0 then
        return
    end

    local tries = 0

    while tries < 12 and botRunning do

        sendPacketRaw(false, {

            type = 3,
            value = 18,

            punchx = x,
            punchy = y,

            x = getLocal().pos.x,
            y = getLocal().pos.y
        })

        sleep(BREAK_DELAY)

        local newbg = checkTile(x, y).bg

        if newbg ~= oldbg then
            break
        end

        tries = tries + 1
    end
end

-- =====================================================
-- WATER DETECTION
-- =====================================================

function hasWater(x, y)

    local tile = checkTile(x, y)

    return tile.flags == 1024
end

function findEmptyWaterSpot()

    for i = 1, #neighbors do

        local x, y = getNeighborPosition(i)

        if not hasWater(x, y) then
            return x, y
        end
    end

    return nil, nil
end

function findExistingWater()

    for i = 1, #neighbors do

        local x, y = getNeighborPosition(i)

        if hasWater(x, y) then
            return x, y
        end
    end

    return nil, nil
end

-- =====================================================
-- FIND FG POSITION
-- =====================================================

function findFGSpot()

    for i = 1, #neighbors do

        local x, y = getNeighborPosition(i)

        local tile = checkTile(x, y)

        if tile.fg == 0 then
            return x, y
        end
    end

    return nil, nil
end

-- =====================================================
-- FIND BG POSITION
-- =====================================================

function findBGSpot()

    for i = 1, #neighbors do

        local x, y = getNeighborPosition(i)

        local tile = checkTile(x, y)

        if tile.bg == 0 then
            return x, y
        end
    end

    return nil, nil
end

-- =====================================================
-- FIND FG BLOCK
-- =====================================================

function findChiFG(itemid)

    for i = 1, #neighbors do

        local x, y = getNeighborPosition(i)

        local tile = checkTile(x, y)

        if tile.fg == itemid then
            return x, y
        end
    end

    return nil, nil
end

-- =====================================================
-- FIND BG BLOCK
-- =====================================================

function findChiBG(itemid)

    for i = 1, #neighbors do

        local x, y = getNeighborPosition(i)

        local tile = checkTile(x, y)

        if tile.bg == itemid then
            return x, y
        end
    end

    return nil, nil
end

-- =====================================================
-- PARSER
-- =====================================================

function getState(chi)

    local lower = latestDialog:lower()

    -- MORE
    if lower:find("vastly more " .. chi) then
        return "vast"
    end

    if lower:find("far more " .. chi) then
        return "far"
    end

    if lower:find("slightly more " .. chi) then
        return "slight"
    end

    if lower:find("more " .. chi) then
        return "more"
    end

    -- LESS
    if lower:find("vastly less " .. chi) then
        return "less_vast"
    end

    if lower:find("far less " .. chi) then
        return "less_far"
    end

    if lower:find("slightly less " .. chi) then
        return "less_slight"
    end

    if lower:find("less " .. chi) then
        return "less"
    end

    return nil
end

-- =====================================================
-- DOWNGRADE
-- =====================================================

function downgrade(chi, state)

    if chi == "water" then
        return
    end

    -- slightly less = break BG
    if state == "less_slight" then

        local bgID = CHI[chi].bg

        local x, y = findChiBG(bgID)

        if x then
            breakBG(x, y)
        end

        return
    end

    -- normal less = break FG
    local fgID = CHI[chi].fg

    local x, y = findChiFG(fgID)

    if x then
        breakBlock(x, y)
    end
end

-- =====================================================
-- PROCESS
-- =====================================================

function processChi(chi)

    local tries = 0

    while botRunning do

        tries = tries + 1

        if tries > 100 then

            logToConsole("`4Too many attempts on "..chi)
            return
        end

        wrenchCrystal()

        if harmonized or not botRunning then
            return
        end

        local state = getState(chi)

        -- =================================================
        -- FINISHED
        -- =================================================

        if not state then

            logToConsole("`2"..chi.." harmonized.")
            return
        end

        logToConsole("`9Processing "..chi.." -> "..state)

        -- =================================================
        -- WATER
        -- =================================================

        if chi == "water" then

            if state == "vast" then

                local x, y = findFGSpot()

                if x then
                    placeFG(x, y, CHI.water.fg)
                end
            end

            if state == "less_vast" then

                local x, y = findChiFG(CHI.water.fg)

                if x then
                    breakBlock(x, y)
                end
            end

            if state == "far" or
               state == "more" or
               state == "slight" then

                local x, y = findEmptyWaterSpot()

                if x then
                    useWaterBucket(x, y)
                end
            end

            if state == "less_far" or
               state == "less" or
               state == "less_slight" then

                local x, y = findExistingWater()

                if x then
                    useWaterBucket(x, y)
                end
            end

            sleep(LOOP_DELAY)

            goto continue
        end

        -- =================================================
        -- NORMAL FG
        -- =================================================

        if state == "vast" or
           state == "far" or
           state == "more" then

            local x, y = findFGSpot()

            if x then
                placeFG(x, y, CHI[chi].fg)
            end
        end

        -- =================================================
        -- NORMAL BG
        -- =================================================

        if state == "slight" then

            local x, y = findBGSpot()

            if x then
                placeBG(x, y, CHI[chi].bg)
            end
        end

        -- =================================================
        -- LESS
        -- =================================================

        if state:find("less") then
            downgrade(chi, state)
        end

        ::continue::

        sleep(LOOP_DELAY)
    end
end

-- =====================================================
-- START BOT
-- =====================================================

function startHarmonizer()

    if botRunning then
        return
    end

    botRunning = true
    harmonized = false

    statusText = "Starting"

    runThread(function()

        logToConsole("`2Starting Crystal Harmonizer...")

        wrenchCrystal()

        statusText = "Earth"
        processChi("earth")

        if not harmonized and botRunning then
            statusText = "Fire"
            processChi("fire")
        end

        if not harmonized and botRunning then
            statusText = "Air"
            processChi("air")
        end

        if not harmonized and botRunning then
            statusText = "Water"
            processChi("water")
        end

        if harmonized then

            statusText = "DONE"
            logToConsole("`2DONE!")

        else

            statusText = "Stopped"
            logToConsole("`4Stopped.")
        end

        botRunning = false
    end)
end

-- =====================================================
-- STOP BOT
-- =====================================================

function stopHarmonizer()

    botRunning = false
    statusText = "Stopped"

    logToConsole("`4Harmonizer stopped.")
end

-- =====================================================
-- GUI
-- =====================================================

function renderGUI()

    ImGui.SetNextWindowPos({x = 20, y = 120}, 2)
    ImGui.SetNextWindowSize({x = 300, y = 180}, 2)

    ImGui.Begin("Crystal Harmonizer", true, 66)

    if ImGui.Button(
        botRunning and "STOP HARMONIZER" or "START HARMONIZER",
        {x = 270, y = 40}
    ) then

        if botRunning then
            stopHarmonizer()
        else
            startHarmonizer()
        end
    end

    ImGui.Separator()

    ImGui.Text("Status : " .. statusText)

    if harmonized then
        ImGui.Text("Crystal : Harmonized")
    else
        ImGui.Text("Crystal : Processing")
    end

    ImGui.Separator()

    ImGui.TextDisabled("ambarcir ni bos")

    ImGui.End()
end

AddHook("OnRender", "harmonizer_gui", renderGUI)
