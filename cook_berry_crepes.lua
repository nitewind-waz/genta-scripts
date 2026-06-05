
-- ==========================================
-- DYNAMIC TIMELINE COOKING SCHEDULER
-- ==========================================

-- ==========================================
-- ITEM CONFIG
-- ==========================================
local ITEMS = {
    flour   = 4562,
    egg  =874 ,
	milk = 868,
    blueberry    = 196,
}

-- ==========================================
-- SETTINGS
-- ==========================================
local MIN_DELAY = 250
local MAX_DELAY = 350

local isCooking = false
local currentEvent = "IDLE"
local timerDisplay = 0

-- ==========================================
-- OVEN LAYOUT
-- ==========================================


local ovenGroups = {
    left = {},
    right = {}
}

-- ==========================================
-- BUILD OVEN POSITION
-- ==========================================
local function buildOvenGroups()
    ovenGroups.left = {}
    ovenGroups.right = {}

    local p = getLocal()
    if not p or not p.pos then
        return false
    end

    local px = math.floor(p.pos.x / 32)
    local py = math.floor(p.pos.y / 32)

    for xOffset = -3, -1 do
        for yOffset = -2, 2 do
            table.insert(ovenGroups.left, {
                x = px + xOffset,
                y = py + yOffset
            })
        end
    end

    for xOffset = 1, 3 do
        for yOffset = -2, 2 do
            table.insert(ovenGroups.right, {
                x = px + xOffset,
                y = py + yOffset
            })
        end
    end

    return true
end

-- ==========================================
-- TIMELINE RECIPE
-- ==========================================
-- FORMAT:
-- time = detik
-- side = left/right
-- action = cook/place/punch
-- item = item id
-- ==========================================

local timeline = {

    -- STEP 1
    -- Flour (timer belum mulai)
    {
        time = 0,
        side = "all",
        action = "cook",
        item = ITEMS.flour,
        label = "FLOUR"
    },

    -- STEP 2
    -- Egg (timer mulai setelah flour selesai)
    {
        time = 10,
        side = "all",
        action = "place",
        item = ITEMS.egg,
        label = "EGG"
    },

    -- STEP 3
    {
        time = 36,
        side = "all",
        action = "place",
        item = ITEMS.milk,
        label = "MILK"
    },

    -- STEP 4
    {
        time = 50,
        side = "all",
        action = "place",
        item = ITEMS.blueberry,
        label = "BLUEBERRY"
    },

    -- STEP 5
    {
        time = 70,
        side = "all",
        action = "punch",
        label = "HARVEST"
    }
}

-- ==========================================
-- UTIL
-- ==========================================
local function randDelay()
    return math.random(MIN_DELAY, MAX_DELAY)
end

local function sendRaw(type, value, x, y)
    local p = getLocal()
    if not p or not p.pos then
        return
    end

    sendPacketRaw(false, {
        type = type,
        value = value,
        punchx = x,
        punchy = y,
        x = p.pos.x,
        y = p.pos.y
    })
end

local function sendCookPacket(x, y, itemID)
    local pkt = string.format(
        "action|dialog_return\ndialog_name|oven\ntilex|%d|\ntiley|%d|\ncookthis|%d|\nbuttonClicked|low",
        x,
        y,
        itemID
    )

    sendPacket(2, pkt)
end

-- ==========================================
-- EXECUTE EVENT
-- ==========================================
local function getAllOvens()
    local ovens = {}

    for _, oven in ipairs(ovenGroups.left) do
        table.insert(ovens, oven)
    end

    for _, oven in ipairs(ovenGroups.right) do
        table.insert(ovens, oven)
    end

    return ovens
end

local function executeEvent(event)

    local ovens

    if event.side == "all" then
        ovens = getAllOvens()
    else
        ovens = ovenGroups[event.side]
    end

    if not ovens then
        return
    end

    currentEvent = event.label

    logToConsole("`9[EVENT] `w" .. event.label)

    for _, oven in ipairs(ovens) do

        if not isCooking then
            return
        end

        if event.action == "cook" then

            sendRaw(3, 32, oven.x, oven.y)
            sleep(180)

            sendCookPacket(
                oven.x,
                oven.y,
                event.item
            )

        elseif event.action == "place" then

            sendRaw(
                3,
                event.item,
                oven.x,
                oven.y
            )

        elseif event.action == "punch" then

            sendRaw(
                3,
                18,
                oven.x,
                oven.y
            )

        end

        sleep(randDelay())
    end
end

-- ==========================================
-- MAIN ENGINE
-- ==========================================
function startCooking()

    if not buildOvenGroups() then
        logToConsole("`4FAILED BUILD OVEN POSITION")
        return
    end

    logToConsole("`9[START] Auto Cooking Loop")

    local maxTimeline = timeline[#timeline].time
    local cycle = 1

    while isCooking do

        logToConsole("`2[CYCLE " .. cycle .. "] Started")

        currentEvent = "CYCLE " .. cycle

        local executed = {}
        local cycleStart = os.time()

        while isCooking do

            local elapsed = os.time() - cycleStart

            timerDisplay = elapsed

            for index, event in ipairs(timeline) do

                if not executed[index]
                and elapsed >= event.time then

                    executed[index] = true

                    executeEvent(event)
                end
            end

            if elapsed >= maxTimeline then
                break
            end

            sleep(100)
        end

        if not isCooking then
            break
        end

        cycle = cycle + 1

        logToConsole("`2[CYCLE COMPLETE] Starting next cycle...")

        sleep(1000)
    end

    currentEvent = "STOPPED"
    logToConsole("`4[STOPPED]")
end

-- ==========================================
-- UI
-- ==========================================
AddHook("OnRender", "DynamicCookUI", function()

    ImGui.SetNextWindowSize(ImVec2(420, 260), ImGui.Cond.FirstUseEver)

    local visible = ImGui.Begin("Dynamic Timeline Cook")

    if visible then

        ImGui.Text("Status : " .. (isCooking and "RUNNING" or "STOPPED"))
        ImGui.Text("Current Event : " .. currentEvent)
        ImGui.Text("Timer : " .. timerDisplay .. "s")

        local progress = math.min(timerDisplay / 133, 1.0)

        ImGui.ProgressBar(progress, ImVec2(-1, 20))

        ImGui.Separator()

        MIN_DELAY = select(2,
            ImGui.SliderInt("Min Delay", MIN_DELAY, 100, 1000)
        )

        MAX_DELAY = select(2,
            ImGui.SliderInt("Max Delay", MAX_DELAY, 100, 1000)
        )

        ImGui.Separator()

        if not isCooking then

            if ImGui.Button("START", ImVec2(-1, 45)) then

                isCooking = true
                timerDisplay = 0
                currentEvent = "STARTING"

                runThread(startCooking)
            end

        else

            if ImGui.Button("STOP", ImVec2(-1, 45)) then

                isCooking = false
                currentEvent = "STOPPED BY USER"

            end
        end
    end

    ImGui.End()
end)

-- ==========================================
-- BLOCK OVEN DIALOG
-- ==========================================
AddHook("OnVarlist", "HideOvenDialog", function(v)

    if isCooking
    and v[0] == "OnDialogRequest"
    and v[1]:find("oven") then

        return true
    end
end)


