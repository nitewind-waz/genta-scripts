		-- ===================================================
		-- UNIVERSAL AUTO CRIME - FIXED NIL ERROR (POLBAN)
		-- ===================================================
		
		local CRIME_DATABASE = {
		    ["The Firebug"]       = { c1 = "2316", c2 = "2308", fillers = {"2320", "2322", "2324"} },
		    ["Jimmy Snow"]        = { c1 = "2334", c2 = "2332", fillers = {"2320", "2322", "2324"} },
		    ["Big Bertha"]        = { c1 = "2294", c2 = "2300", fillers = {"2320", "2322", "2324"} },
		    ["Shockinator"]       = { c1 = "2326", c2 = "2324", fillers = {"2292", "2298", "2300"} },
		    ["Generic Thug #17"]  = { c1 = "2294", c2 = "2296", fillers = {"2340", "2336", "2334"} },
		    ["Professor Pummel"]  = { c1 = "2294", c2 = "2296", fillers = {"2320", "2322", "2324"} },
		    ["Dragon Hand"]       = { c1 = "2326", c2 = "2328", fillers = {"2314", "2308", "2312"} },
		    ["Kat 5"]             = { c1 = "2336", c2 = "2332", c3 = "2334", fillers = {"2298", "2292"} },
		    ["Z. Everett Koop"]   = { c1 = "2294", c2 = "2296", fillers = {"2340", "2336", "2334"} },
		    ["Dr. Destructo"]     = { c1 = "2310", c2 = "2316", fillers = {"2320", "2324", "2322"} },
		    ["Almighty Seth"]     = { c1 = "2326", c2 = "2328", fillers = {"2314", "2308", "2312"} },
		    ["Devil Ham"]         = { c1 = "2310", c2 = "2316", fillers = {"2340", "2336", "2334"} },
			["El Peligro"]          = {c1= "2310", c2 = "2316", fillers = {"2324", "2320", "2326"} }
		}
		local current_villain = "None"
		local last_card_index = 1
		local kat5_step_done = false
		
		-- FIX: Fungsi Logger yang aman agar tidak nil
		function safeLog(msg)
		    if logToConsole then
		        logToConsole("`4[DEBUG] `w" .. msg)
		    elseif print then
		        print("[DEBUG] " .. msg)
		    end
		end
		
		-- 1. GUI RENDERER (Updated Size)
		local function onRender()
		    -- Mengatur posisi dan ukuran (x=250, y=150)
		    ImGui.SetNextWindowPos({x=10, y=50}, 2) 
		    ImGui.SetNextWindowSize({x=250, y=150}, 2) 
		    
		    ImGui.Begin("Monitor", true, 66)
		    
		    ImGui.TextColored({x=0, y=1, z=0, w=1}, "VILLAIN: ")
		    ImGui.SameLine()
		    ImGui.Text(current_villain)
		    
		    ImGui.Separator()
		    
		   
		    ImGui.Spacing()
		    ImGui.Separator()
		    
		    -- Identitas kebanggaan anak POLBAN
		    ImGui.TextDisabled("autocrime by ambarcir ni bos")
		    
		    ImGui.End()
		end
		AddHook("OnRender", "crime_ui", onRender)
		
		function auto_select_deck(content, strategy)
		    safeLog("Mengekstrak koordinat...")
		    local tx = content:match("embed_data|tilex|(%d+)")
		    local ty = content:match("embed_data|tiley|(%d+)")
		    
		    if not tx or not ty then
		        safeLog("ERROR: Koordinat Tile tidak ditemukan!")
		        return
		    end
		
		    local selected = { [strategy.c1] = true, [strategy.c2] = true }
		    if strategy.c3 then selected[strategy.c3] = true end
		    for _, fID in ipairs(strategy.fillers) do selected[fID] = true end
		
		    -- Structure sesuai packet client yang kamu kirim
		    local packet = "action|dialog_return\ndialog_name|crime_edit\n"
		    packet = packet .. "tilex|" .. tx .. "|\n"
		    packet = packet .. "tiley|" .. ty .. "|\n"
		    packet = packet .. "state|0||\n"
		    packet = packet .. "buttonClicked|button_ok\n\n"
		    
		    for id in content:gmatch("add_checkicon|c(%d+)") do
		        local val = selected[id] and "1" or "0"
		        packet = packet .. "c" .. id .. "|" .. val .. "\n"
		    end
		
		    safeLog("Mengirim paket deck...")
		    sleep(1000)
		    sendPacket(2, packet)
		end
		
		function send_battle_action(tx, ty, cardID, label)
		    local packet = "action|dialog_return\ndialog_name|crime_edit\n"
		    packet = packet .. "tilex|" .. tx .. "|\n"
		    packet = packet .. "tiley|" .. ty .. "|\n"
		    packet = packet .. "state|1||\n"
		    packet = packet .. "buttonClicked|c" .. cardID .. "\n"
		    
		    safeLog("Battle Action: " .. (label or cardID))
		    sleep(math.random(400, 800))
		    sendPacket(2, packet)
		end
		
		function onCrimeMain(var)
		    if var[0]:find("OnDialogRequest") then
		        local content = var[1]
		
		        if content:find("Select 5 Superpowers") then
		            for name, strat in pairs(CRIME_DATABASE) do
		                if content:find(name) then
		                    safeLog("Villain Terdeteksi: " .. name)
		                    current_villain = name
		                    kat5_step_done = false
		                    auto_select_deck(content, strat)
		                    return true
		                end
		            end
		        end
		
		        if content:find("Fighting Crime") or content:find("Crime in Progress") then
		            local strat = CRIME_DATABASE[current_villain]
		            if not strat then return false end
		
		            local tx = content:match("embed_data|tilex|(%d+)")
		            local ty = content:match("embed_data|tiley|(%d+)")
		            local move = ""
		            local label = ""
		
		            if current_villain == "Kat 5" then
		                if not kat5_step_done and content:find(strat.c1) and not content:find(strat.c1 .. "|disabled") then
		                    move = strat.c1; label = "Kat5 Start"; kat5_step_done = true
		                elseif content:find(strat.c2) and not content:find(strat.c2 .. "|disabled") and last_card_index == 3 then
		                    move = strat.c2; label = "Kat5 Spam (2)"; last_card_index = 2
		                elseif content:find(strat.c3) and not content:find(strat.c3 .. "|disabled") then
		                    move = strat.c3; label = "Kat5 Spam (3)"; last_card_index = 3
		                end
		            else
		                local c1_r = content:find(strat.c1) and not content:find(strat.c1 .. "|disabled")
		                local c2_r = content:find(strat.c2) and not content:find(strat.c2 .. "|disabled")
		                if c1_r and (not c2_r or last_card_index == 2) then
		                    move = strat.c1; last_card_index = 1; label = "Counter 1"
		                elseif c2_r then
		                    move = strat.c2; last_card_index = 2; label = "Counter 2"
		                end
		            end
		
		            if move ~= "" then
		                send_battle_action(tx, ty, move, label)
		            else
		                for _, fID in ipairs(strat.fillers) do
		                    if content:find(fID) and not content:find(fID .. "|disabled") then
		                        send_battle_action(tx, ty, fID, "Filler")
		                        return true
		                    end
		                end
		                send_battle_action(tx, ty, "passturn", "Skip")
		            end
		            return true
		        end
		    end
		end
		
		AddHook("onvarlist", "universal_crime", onCrimeMain)
