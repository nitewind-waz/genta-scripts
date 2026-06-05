World_Name = "pcqzm" --# Ganti Dengan Nama World Yang Ingin Di Splice
World_Save = "pcqzm" --# Ganti Dengan Nama World Tempat Seed Berada
Door_ID = "spliss" --# Ganti Dengan ID Door Yang Ada Di World, "ID Door Harus Sama Di Kedua World"

Seed_ID1 = 171 --# Ganti Dengan ID Seed Pertama
Seed_ID2 = 193 --# Ganti Dengan ID Seed Kedua

Delay_Plant = 250
Delay_Warp = 5000
Delay_Find_Path = 10000

function getAmount(id)
    for _, x in pairs(getInventory()) do
        if x.id == id then
            return x.amount
        end
    end
    return 0
end

function send(txt)
    local var = {}
    var[0] = "OnTextOverlay"
    var[1] = txt
    sendVariant(var)
end

function join(wn, di)
    sleep(1000)
    sendPacket(2, "action|join_request\nname|" .. wn)
    sendPacket(3, "action|join_request\nname|" .. wn .. "|" .. di .. "\ninvitedWorld|0")
end

function takeSeed(seedID)
    for _, obj in pairs(getWorldObject()) do
        if obj.id == seedID then
            local targetX = math.floor(obj.pos.x / 32)
            local targetY = math.floor(obj.pos.y / 32)
            findPath(targetX, targetY)
            
            local reached = false
            while not reached do
                local playerX = math.floor(getLocal().pos.x / 32)
                local playerY = math.floor(getLocal().pos.y / 32)
                if playerX == targetX and playerY == targetY then
                    reached = true
                else
                    findPath(targetX, targetY)
                    sleep(1000)
                end
            end

            sleep(Delay_Find_Path)
            join(World_Name, Door_ID)
            sleep(Delay_Warp)
            plant(seedID, Delay_Plant)
        end
    end
end

function plant(id1, id2, delay)
    for y = 1, 52 do
        for x = 0, 98 do
            if getAmount(id1) == 0 or getAmount(id2) == 0 then
                join(World_Save, Door_ID)
                sleep(Delay_Warp)
                sleep(500)
            elseif getAmount(id1) > 0 and checkTile(x, y).fg == 0 and checkTile(x, y + 1).fg % 2 == 0 and checkTile(x, y + 1).fg ~= 0 then
                findPath(x, y, 200)
                sleep(delay)
                sendPacketRaw(false, {value = id1, type = 3, x = getLocal().pos.x, y = getLocal().pos.y, punchx = getLocal().pos.x / 32, punchy = getLocal().pos.y / 32})
                sleep(delay)
                sendPacketRaw(false, {value = id2, type = 3, x = getLocal().pos.x, y = getLocal().pos.y, punchx = getLocal().pos.x / 32, punchy = getLocal().pos.y / 32})
                sleep(delay)
            end
        end
    end
end

function isSpliced()
    for y = 1, 52 do
        for x = 0, 98 do
            if checkTile(x, y).fg == 0 and checkTile(x, y + 1).fg % 2 == 0 and checkTile(x, y + 1).fg ~= 0 then
                return false
            end
        end
    end
    return true
end

function Main()
    send("This Script made by Beelzebub or known as Mrhuwy")
    sleep(2000)
    
    send("`9Warping to `2" .. World_Name)
    sleep(500)
    join(World_Name, Door_ID)
    sleep(Delay_Warp)
    send("`9Starting to Splice: `#" .. getItemByID(Seed_ID1).name .. " and " .. getItemByID(Seed_ID2).name)
    sleep(500)

    while not isSpliced() do
        plant(Seed_ID1, Seed_ID2, Delay_Plant)
        sleep(1000)
    end
    
    send("`2All tiles spliced successfully!")
end

Main()
