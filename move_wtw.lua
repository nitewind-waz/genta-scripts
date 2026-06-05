-- =========================================
-- AUTO TAKE & DROP
-- SMART OFFSET VERSION
-- =========================================

local ITEM_ID = 4585
local TARGET_AMOUNT = 200

local TAKE_WORLD = "ambarpepper"
local TAKE_DOOR  = "dekatnye"

local DROP_WORLD = "enampepper"
local DROP_DOOR  = "peppernibos"

local running = false

local takeOffset = 0
local dropOffset = 0

local lastAction = 0

-- =========================================
-- INVENTORY
-- =========================================

function inv(id)

    local inventory = getInventory()

    if not inventory then
        return 0
    end

    for _, item in pairs(inventory) do

        if tonumber(item.id) == tonumber(id) then

            return tonumber(item.amount)
                or tonumber(item.count)
                or 0
        end
    end

    return 0
end

-- =========================================
-- PLAYER TILE
-- =========================================

function getPlayerTile()

    local p = getLocal()

    return math.floor(p.pos.x / 32),
           math.floor(p.pos.y / 32)
end

-- =========================================
-- MOVE RIGHT
-- =========================================

function moveRight(offset)

    local px, py = getPlayerTile()

    findPath(
        px + offset,
        py
    )

    sleep(500)
end

-- =========================================
-- WARP
-- =========================================

function warp(world, door)

    sendPacket(
        3,
        "action|join_request\nname|" ..
        world ..
        "|" ..
        door ..
        "\ninvitedWorld|0"
    )
end

-- =========================================
-- DROP
-- =========================================

function dropAll()

    local amount = inv(ITEM_ID)

    if amount <= 0 then
        return
    end

    sendPacket(
        2,
        "action|drop\n|itemID|" ..
        ITEM_ID
    )

    sleep(300)

    sendPacket(
        2,
        "action|dialog_return\n" ..
        "dialog_name|drop_item\n" ..
        "itemID|" .. ITEM_ID .. "|\n" ..
        "count|" .. amount
    )
end

-- =========================================
-- MAIN
-- =========================================

function processBot()

    local world = getWorld()

    if not world then
        return
    end

    local amount = inv(ITEM_ID)

    ------------------------------------------------
    -- TAKE MODE
    ------------------------------------------------

    if amount < TARGET_AMOUNT then

        if world.name ~= string.upper(TAKE_WORLD) then

            warp(
                TAKE_WORLD,
                TAKE_DOOR
            )

            return
        end

        local before = amount

        sleep(300)

        local after = inv(ITEM_ID)

        -- stock habis
        if after <= before then

            takeOffset = takeOffset + 1

            logToConsole(
                "`3NEXT TAKE TILE -> " ..
                takeOffset
            )

            moveRight(1)
        end

    ------------------------------------------------
    -- DROP MODE
    ------------------------------------------------

    else

        if world.name ~= string.upper(DROP_WORLD) then

            warp(
                DROP_WORLD,
                DROP_DOOR
            )

            return
        end

        dropAll()

        sleep(1000)

        if inv(ITEM_ID) > 0 then

            dropOffset = dropOffset + 1

            logToConsole(
                "`4DROP FULL -> MOVE " ..
                dropOffset
            )

            moveRight(1)
        end
    end
end

-- =========================================
-- HIDE DROP DIALOG
-- =========================================

AddHook(
    "OnVarlist",
    "HideDropDialog",
    function(var)

        if var[0] == "OnDialogRequest" then

            if var[1]:find("drop_item") then
                return true
            end
        end
    end
)

-- =========================================
-- GUI
-- =========================================

AddHook(
    "OnRender",
    "AutoTakeDropGUI",
    function()

        ImGui.SetNextWindowSize(
            ImVec2(350,250),
            ImGui.Cond.FirstUseEver
        )

        local visible =
            ImGui.Begin("Auto Take Drop")

        if visible then

            ImGui.Text(
                "Item ID : " ..
                ITEM_ID
            )

            ImGui.Text(
                "Inventory : " ..
                inv(ITEM_ID)
            )

            ImGui.Text(
                "Target : " ..
                TARGET_AMOUNT
            )

            ImGui.Separator()

            ImGui.Text(
                "Take Offset : " ..
                takeOffset
            )

            ImGui.Text(
                "Drop Offset : " ..
                dropOffset
            )

            ImGui.Separator()

            ImGui.Text(
                running and
                "Status : RUNNING"
                or
                "Status : STOPPED"
            )

            if ImGui.Button(
                "START",
                ImVec2(-1,40)
            ) then

                running = true

                logToConsole(
                    "`2AUTO STARTED"
                )
            end

            if ImGui.Button(
                "STOP",
                ImVec2(-1,40)
            ) then

                running = false

                logToConsole(
                    "`4AUTO STOPPED"
                )
            end
        end

        ImGui.End()

        ------------------------------------
        -- LOOP
        ------------------------------------

        if running then

            local now = os.clock()

            if now - lastAction >= 2 then

                lastAction = now

                processBot()
            end
        end
    end
)

logToConsole("`2Auto Take Drop Loaded")
