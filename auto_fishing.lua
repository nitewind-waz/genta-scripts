-- ===================================================
-- AUTO FISHING V19 - FIXED BUTCHER ACTION (TYPE 3)
-- ===================================================

local fishing_active = false
local catch_count = 0
local last_status = "Waiting..."
local current_water_type = "normal" 
local waiting_respawn = false

local ID = {
    URANIUM_SOLID = 4658,
    ICE_SOLID = 5602,
    DETONATOR = 5524,
    DRILL = 5522,
    BAIT_URANIUM = 5526,
    BAIT_ICE = 5528,
    BAIT_NORMAL = 3016,
--ezrod 3008, tgrod 10262, rainbowrod 5740
    EZ_ROD = 5740,
    SUSHI_KNIFE_ID = 3466 -- ID Item Pisau
}

function sendAction(type_packet, val, tx, ty)
    sendPacketRaw(false, {
        type = type_packet,
        value = val,
        punchx = tx,
        punchy = ty,
        x = getLocal().pos.x,
        y = getLocal().pos.y
    })
end

-- FUNGSI BUTCHER YANG DIPERBAIKI
-- ===================================================
-- FIX: STABLE WEAR & BUTCHER ACTION
-- ===================================================

function useSushiKnife()
    last_status = "Switching to Knife..."
    
    -- Ambil koordinat tile kaki
    local px = math.floor(getLocal().pos.x / 32)
    local py = math.floor(getLocal().pos.y / 32)

    runThread(function()
        -- STEP 1: Paksa pakai pisau (Gunakan format ID murni)
        -- Kita kirim dua kali untuk memastikan server menerima perubahan item
        sendPacketRaw(false, {
                type = 10, -- Type 10 sesuai foto sniffing kamu
                value = 3466,
                punchx = px,
                punchy = py,
                x = getLocal().pos.x,
                y = getLocal().pos.y
            })
        sleep(800) -- Naikkan delay agar server sinkron

        last_status = "Butchering (15x)..."
        -- STEP 2: Loop Punch (Aksi memotong)
        for i = 1, 20 do
            if not fishing_active then break end
            
            -- Kirim paket Punch (Value 18)
            sendPacketRaw(false, {
                type = 3,
                value = 18, 
                punchx = px,
                punchy = py,
                x = getLocal().pos.x,
                y = getLocal().pos.y
            })
            
            sleep(180) -- Kecepatan potong (jangan terlalu cepat agar tidak lag)
        end
        
        last_status = "Switching back to Rod..."
        sendPacketRaw(false, {
                type = 10, -- Type 10 sesuai foto sniffing kamu
                value = ID.EZ_ROD,
                punchx = px,
                punchy = py,
                x = getLocal().pos.x,
                y = getLocal().pos.y
            })
        sleep(800)
        
        last_status = "Cleaning done, restarting..."
        start_bot_process() 
    end)
end

function get_target()
    local px, py = getLocal().pos.x, getLocal().pos.y
    local x_grid = math.floor((px + 16) / 32)
    local y_grid = math.floor((py + 16) / 32)
    local dir = getLocal().facing_left and -1 or 1
    return x_grid + dir, y_grid + 1
end

function start_bot_process()
    if not fishing_active then return end
    local tx, ty = get_target()
    local tile = checkTile(tx, ty)
    
    runThread(function()
        if tile.fg == ID.URANIUM_SOLID then
            current_water_type = "uranium"
            sendAction(3, ID.DETONATOR, tx, ty)
            sleep(1000)
        elseif tile.fg == ID.ICE_SOLID then
            current_water_type = "ice"
            sendAction(3, ID.DRILL, tx, ty)
            sleep(1000)
        else
            current_water_type = "normal"
        end
        cast_rod_logic(tx, ty)
    end)
end

function cast_rod_logic(tx, ty)
    if not fishing_active then return end
    sendPacket(2, "action|set_item\nitemID|" .. ID.EZ_ROD)
    sleep(500)
    
    local bait_val = ID.BAIT_NORMAL
    if current_water_type == "uranium" then bait_val = ID.BAIT_URANIUM 
    elseif current_water_type == "ice" then bait_val = ID.BAIT_ICE end
    
    last_status = "Casting: " .. current_water_type:upper()
    sendAction(3, bait_val, tx, ty)
end

-- GUI & HOOKS (Tetap Sama)
local function onRender()
    ImGui.SetNextWindowPos({x=10, y=50}, 2)
    ImGui.SetNextWindowSize({x=260, y=160}, 2)
    ImGui.Begin("AutoFishing Butcher V19", true, 66)
    if ImGui.Button(fishing_active and "STOP BOT" or "START BOT", {x=240, y=35}) then
        fishing_active = not fishing_active
        if fishing_active then start_bot_process() end
    end
    ImGui.Separator()
    ImGui.Text("Status: " .. last_status)
    ImGui.Text("Caught: " .. catch_count)
    ImGui.Separator()
    ImGui.TextDisabled("ambarcir - Fixed Packet")
    ImGui.End()
end
AddHook("OnRender", "fishing_ui", onRender)

function onFishingMain(var)
    if not fishing_active then return end
    if var[0] == "OnTalkBubble" and var[2]:find("emptier spot") then
        useSushiKnife()
        return 
    end
    if var[0] == "OnPlayPositioned" and var[1]:find("audio/splash.wav") then
        last_status = "!!! STRIKE !!!"
        local tx, ty = get_target()
        sendAction(3, ID.BAIT_NORMAL, tx, ty) 
        runThread(function()
            sleep(300) 
            if current_water_type == "uranium" then sendAction(3, ID.DETONATOR, tx, ty)
            elseif current_water_type == "ice" then sendAction(3, ID.DRILL, tx, ty) end
            sleep(1700) 
            if fishing_active then cast_rod_logic(tx, ty) end
        end)
    end
    if var[0] == "OnConsoleMessage" and var[1]:find("caught a") then
        catch_count = catch_count + 1
    end
-- PLAYER MATI
if var[0] == "OnKilled" then
    waiting_respawn = true
    last_status = "Killed! Waiting respawn..."
    return
end

-- RESPAWN SELESAI
if var[0] == "OnSetFreezeState" and tonumber(var[1]) == 0 then
    
    if waiting_respawn then
        
        waiting_respawn = false
        
        runThread(function()
            last_status = "Respawn detected..."
            
            sleep(5000)

            if fishing_active then
                last_status = "Restart fishing..."
                start_bot_process()
            end
        end)
    end

    return
end
end
AddHook("onvarlist", "universal_fishing", onFishingMain)
