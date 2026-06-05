-- =========================================
-- AUTO BUY + DROP + PUTVEND SYSTEM
-- =========================================

-- =========================================
-- SETTINGS
-- =========================================
local BUY_AMOUNT = 200

local AUTO_DROP_AFTER_BUY = false
local AUTO_PUTVEND_AFTER_BUY = false

-- =========================================
-- GLOBAL STATE
-- =========================================
local lastBoughtItem = 0
local lastBoughtName = "NONE"
local lastBoughtCount = 0

local lastVendX = 0
local lastVendY = 0

-- =========================================
-- GET INVENTORY COUNT
-- =========================================
local function getItemCount(itemID)

    local inv = getInventory()

    if not inv then
        return 0
    end

    for _, item in pairs(inv) do

        if item.id == itemID then
            return item.amount
        end
    end

    return 0
end

-- =========================================
-- DROP ITEM
-- =========================================
local function dropItem(itemID)

    local count = getItemCount(itemID)

    if count <= 0 then
        logToConsole("`4No item to drop")
        return
    end

    -- STEP 1
    sendPacket(2,
        "action|drop\n" ..
        "|itemID|" .. itemID
    )

    sleep(250)

    -- STEP 2
    local packet =
        "action|dialog_return\n" ..
        "dialog_name|drop_item\n" ..
        "itemID|" .. itemID .. "\n" ..
        "count|" .. count

    sendPacket(2, packet)

    sleep(250)

    -- STEP 3
    sendPacket(2, packet)

    logToConsole(
        "`9[DROPPED] `wItem : " ..
        itemID ..
        " Count : " ..
        count
    )
end

-- =========================================
-- PUTVEND
-- =========================================
local function putVend(itemID)

    if lastVendX == 0 and lastVendY == 0 then
        logToConsole("`4No vending position saved")
        return
    end

    sendPacket(2,
        "action|dialog_return\n" ..
        "dialog_name|vending\n" ..
        "tilex|" .. lastVendX .. "\n" ..
        "tiley|" .. lastVendY .. "\n" ..
        "buttonClicked|addstock\n" ..
        "setprice|5\n" ..
        "chk_peritem|0\n" ..
        "chk_perlock|1"
    )

    logToConsole("`9[PUTVEND] `wAdded stock")
end

-- =========================================
-- AUTO VENDING SYSTEM
-- =========================================
function autoVend(var)

    if var[0] ~= "OnDialogRequest" then
        return
    end

    local dialog = var[1]

    -- =====================================
    -- DIGIVEND OWNER MODE
    -- =====================================
    if dialog:find("addstock") then

        local tilex = dialog:match("embed_data|tilex|(%d+)")
        local tiley = dialog:match("embed_data|tiley|(%d+)")
        local setprice = dialog:match("setprice|[%w%s]+|(%d+)")

        if not tilex or not tiley then
            logToConsole("`4Failed parse DigiVend")
            return
        end

        lastVendX = tonumber(tilex)
        lastVendY = tonumber(tiley)

        sendPacket(2,
            "action|dialog_return\n" ..
            "dialog_name|vending\n" ..
            "tilex|" .. tilex .. "\n" ..
            "tiley|" .. tiley .. "\n" ..
            "buttonClicked|addstock\n" ..
            "setprice|" .. (setprice or "5") .. "\n" ..
            "chk_peritem|0\n" ..
            "chk_perlock|1"
        )

        logToConsole("`9[DIGIVEND] `wAdded stock")

        return true
    end

    -- =====================================
    -- NORMAL BUY VENDING
    -- =====================================
    if dialog:find("end_dialog|vending") then

        local tilex = dialog:match("embed_data|tilex|(%d+)")
        local tiley = dialog:match("embed_data|tiley|(%d+)")
        local expectprice = dialog:match("embed_data|expectprice|([%-%d]+)")
        local expectitem = dialog:match("embed_data|expectitem|(%d+)")

        local itemName = dialog:match("add_label_with_icon|small|`w(.-)|left|")

        if not tilex or not tiley then
            logToConsole("`4Failed parse vending")
            return
        end

        -- SAVE LAST ITEM
        lastBoughtItem = tonumber(expectitem) or 0
        lastBoughtName = itemName or "UNKNOWN"

        -- BUY
        sendPacket(2,
            "action|dialog_return\n" ..
            "dialog_name|vending\n" ..
            "tilex|" .. tilex .. "\n" ..
            "tiley|" .. tiley .. "\n" ..
            "expectprice|" .. expectprice .. "\n" ..
            "expectitem|" .. expectitem .. "\n" ..
            "buycount|" .. BUY_AMOUNT
        )

        sleep(200)

        -- VERIFY
        sendPacket(2,
            "action|dialog_return\n" ..
            "dialog_name|vending\n" ..
            "tilex|" .. tilex .. "\n" ..
            "tiley|" .. tiley .. "\n" ..
            "verify|1\n" ..
            "buycount|" .. BUY_AMOUNT .. "\n" ..
            "expectprice|" .. expectprice .. "\n" ..
            "expectitem|" .. expectitem
        )

        sleep(200)

        -- UPDATE INVENTORY COUNT
        lastBoughtCount = getItemCount(lastBoughtItem)

        logToConsole(
            "`9[BOUGHT] `w" ..
            lastBoughtName ..
            " x" ..
            lastBoughtCount
        )

        -- AUTO DROP
        if AUTO_DROP_AFTER_BUY then

            sleep(300)

            dropItem(lastBoughtItem)
        end

        -- AUTO PUTVEND
        if AUTO_PUTVEND_AFTER_BUY then

            sleep(300)

            putVend(lastBoughtItem)
        end

        return true
    end

    -- =====================================
    -- HIDE DROP DIALOG
    -- =====================================
    if dialog:find("drop_item") then
        return true
    end
end

AddHook("OnVarlist", "auto_vending_system", autoVend)

-- =========================================
-- GUI
-- =========================================
AddHook("OnRender", "AutoVendGUI", function()

    ImGui.SetNextWindowSize(ImVec2(420, 320), ImGui.Cond.FirstUseEver)

    local visible = ImGui.Begin("Auto Vend System")

    if visible then

        ImGui.Text("Last Bought Item ID : " .. tostring(lastBoughtItem))
        ImGui.Text("Last Bought Name : " .. lastBoughtName)
        ImGui.Text("Inventory Count : " .. tostring(lastBoughtCount))

        ImGui.Separator()

        BUY_AMOUNT = select(2,
            ImGui.SliderInt("Buy Amount", BUY_AMOUNT, 1, 200)
        )

        AUTO_DROP_AFTER_BUY = select(2,
            ImGui.Checkbox(
                "Auto Drop After Buy",
                AUTO_DROP_AFTER_BUY
            )
        )

        AUTO_PUTVEND_AFTER_BUY = select(2,
            ImGui.Checkbox(
                "Auto PutVend After Buy",
                AUTO_PUTVEND_AFTER_BUY
            )
        )

        ImGui.Separator()

        if ImGui.Button("REFRESH COUNT", ImVec2(-1, 40)) then

            if lastBoughtItem ~= 0 then
                lastBoughtCount = getItemCount(lastBoughtItem)
            end
        end

        if ImGui.Button("DROP ALL", ImVec2(-1, 45)) then

            if lastBoughtItem ~= 0 then
                dropItem(lastBoughtItem)
            end
        end

        if ImGui.Button("PUTVEND", ImVec2(-1, 45)) then

            if lastBoughtItem ~= 0 then
                putVend(lastBoughtItem)
            end
        end
    end

    ImGui.End()
end)
