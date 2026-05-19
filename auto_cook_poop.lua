
-- ==========================================
-- DYNAMIC TIMELINE COOKING SCHEDULER
-- ==========================================

-- ==========================================
-- ITEM CONFIG
-- ==========================================
local ITEMS = {
    poop   = 8394,
    gruel  = 4410,
    sea    = 8392,
    urchin = 8252
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

    for xOffset = -2, -1 do
        for yOffset = -2, 2 do
            table.insert(ovenGroups.left, {
                x = px + xOffset,
                y = py + yOffset
            })
        end
    end

    for xOffset = 1, 2 do
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

    -- ======================================
    -- RIGHT OVEN
    -- ======================================
    {
        time = 0,
        side = "right",
        action = "cook",
        item = ITEMS.poop,
        label = "RIGHT : POOP"
    },

    -- ======================================
    -- LEFT OVEN
    -- ======================================
    {
        time = 28,
        side = "left",
        action = "cook",
        item = ITEMS.poop,
        label = "LEFT : POOP"
    },

    -- ======================================
    -- RIGHT INGREDIENTS
    -- ======================================
    {
        time = 53,
        side = "right",
        action = "place",
        item = ITEMS.gruel,
        label = "RIGHT : GRUEL"
    },

    {
        time = 61,
        side = "right",
        action = "place",
        item = ITEMS.sea,
        label = "RIGHT : SEA"
    },

    {
        time = 69,
        side = "right",
        action = "place",
        item = ITEMS.urchin,
        label = "RIGHT : URCHIN"
    },

    -- ======================================
    -- LEFT INGREDIENTS
    -- ======================================
    {
        time = 80,
        side = "left",
        action = "place",
        item = ITEMS.gruel,
        label = "LEFT : GRUEL"
    },

    {
        time = 87,
        side = "left",
        action = "place",
        item = ITEMS.sea,
        label = "LEFT : SEA"
    },

    {
        time = 96,
        side = "left",
        action = "place",
        item = ITEMS.urchin,
        label = "LEFT : URCHIN"
    },

    -- ======================================
    -- PUNCH
    -- ======================================
    {
        time = 104,
        side = "right",
        action = "punch",
        label = "RIGHT : PUNCH"
    },

    {
        time = 133,
        side = "left",
        action = "punch",
        label = "LEFT : PUNCH"
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
local function executeEvent(event)

    local ovens = ovenGroups[event.side]

    if not ovens then
        return
    end

    currentEvent = event.label

    logToConsole("`9[EVENT] `w" .. event.label)

    for _, oven in ipairs(ovens) do

        if not isCooking then
            return
        end

        -- ==================================
        -- COOK
        -- ==================================
        if event.action == "cook" then

            sendRaw(3, 32, oven.x, oven.y)
            sleep(180)
            sendCookPacket(oven.x, oven.y, event.item)

        -- ==================================
        -- PLACE
        -- ==================================
        elseif event.action == "place" then

            sendRaw(3, event.item, oven.x, oven.y)

        -- ==================================
        -- PUNCH
        -- ==================================
        elseif event.action == "punch" then

            sendRaw(3, 18, oven.x, oven.y)

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

    logToConsole("`9[START] Dynamic Timeline Cooking")

    local executed = {}

    local cycleStart = os.time()

    local maxTimeline = timeline[#timeline].time

    while isCooking do

        local elapsed = os.time() - cycleStart

        timerDisplay = elapsed

        for index, event in ipairs(timeline) do

            if not executed[index] and elapsed >= event.time then

                executed[index] = true

                executeEvent(event)
            end
        end

        -- ==================================
        -- FINISH
        -- ==================================
        if elapsed >= maxTimeline + 3 then

            isCooking = false
            currentEvent = "FINISHED"

            logToConsole("`9[FINISH] `wCooking Finished")

            break
        end

        sleep(100)
    end
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




