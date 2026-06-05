-- ==============================
-- CONFIG
-- ==============================

local BLOCK_ID = 124
local SEED_ID = BLOCK_ID + 1
local WORLD_NAME = "pcqzm"

local HARVEST_DELAY = 100
local MOVE_DELAY = 150

-- ==============================
-- UTIL FUNCTION
-- ==============================

function getPlayerTile()
    return getLocal().pos.x // 32, getLocal().pos.y // 32
end

function moveToTile(x, y)
    local px, py = getPlayerTile()

    if px ~= x or py ~= y then
        findPath(x, y)
        sleep(MOVE_DELAY)
    end
end

function punchTile(x, y)
    sendPacketRaw(false, {
        type = 3,
        value = 18,
        punchx = x,
        punchy = y,
        x = getLocal().pos.x,
        y = getLocal().pos.y
    })
end

function collectDrops(limit)
    local count = 0

    for _, obj in pairs(getWorldObject()) do
        sendPacketRaw(false, {
            type = 11,
            value = obj.oid,
            x = obj.pos.x,
            y = obj.pos.y
        })

        sleep(5)
        count = count + 1

        if limit and count >= limit then
            break
        end
    end
end

-- ==============================
-- FIND READY TREES
-- ==============================

function findReadyTrees()
    local trees = {}

    for y = 0, 53 do
        for x = 0, 99 do

            local tile = checkTile(x, y)

            if tile.fg == SEED_ID then
                local extra = getExtraTile(x, y)

                if extra and extra.ready then
                    table.insert(trees, {x = x, y = y})
                end
            end

        end
    end

    return trees
end

-- ==============================
-- HARVEST TREE
-- ==============================

function harvestTree(x, y)

    moveToTile(x, y)

    sleep(HARVEST_DELAY)

    punchTile(x, y)

    sleep(HARVEST_DELAY)

    collectDrops(50)

end

-- ==============================
-- AUTO HARVEST LOOP
-- ==============================

function autoHarvest()

    while true do

        local trees = findReadyTrees()

        if #trees == 0 then
            logToConsole("No ready trees found")
            sleep(5000)
        else

            for _, tree in pairs(trees) do
                harvestTree(tree.x, tree.y)
            end

        end

    end

end

-- ==============================
-- START SCRIPT
-- ==============================

sendPacket(3, "action|join_request\nname|" .. WORLD_NAME)
sleep(4000)

autoHarvest()
