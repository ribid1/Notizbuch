--[[
	----------------------------------------------------------------------------
	App um Notizen zu dem Modellen anzuzeigen und abzuspeichern, in max. 10 Zeilen und 10 Spalten
	----------------------------------------------------------------------------
	
	MIT License

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
   
	Hiermit wird unentgeltlich jeder Person, die eine Kopie der Software und der
	zugehörigen Dokumentationen (die "Software") erhält, die Erlaubnis erteilt,
	sie uneingeschränkt zu nutzen, inklusive und ohne Ausnahme mit dem Recht, sie
	zu verwenden, zu kopieren, zu verändern, zusammenzufügen, zu veröffentlichen,
	zu verbreiten, zu unterlizenzieren und/oder zu verkaufen, und Personen, denen
	diese Software überlassen wird, diese Rechte zu verschaffen, unter den
	folgenden Bedingungen: 
	Der obige Urheberrechtsvermerk und dieser Erlaubnisvermerk sind in allen Kopien
	oder Teilkopien der Software beizulegen. 
	DIE SOFTWARE WIRD OHNE JEDE AUSDRÜCKLICHE ODER IMPLIZIERTE GARANTIE BEREITGESTELLT,
	EINSCHLIEßLICH DER GARANTIE ZUR BENUTZUNG FÜR DEN VORGESEHENEN ODER EINEM
	BESTIMMTEN ZWECK SOWIE JEGLICHER RECHTSVERLETZUNG, JEDOCH NICHT DARAUF BESCHRÄNKT.
	IN KEINEM FALL SIND DIE AUTOREN ODER COPYRIGHTINHABER FÜR JEGLICHEN SCHADEN ODER
	SONSTIGE ANSPRÜCHE HAFTBAR ZU MACHEN, OB INFOLGE DER ERFÜLLUNG EINES VERTRAGES,
	EINES DELIKTES ODER ANDERS IM ZUSAMMENHANG MIT DER SOFTWARE ODER SONSTIGER
	VERWENDUNG DER SOFTWARE ENTSTANDEN. 
	
	Ursprüngliche Idee und Programmierung von Thorsten Tiedge 
	
	Version 1.2: Aufteilung der Eingabefelder auf mehrere Spalten und Anpassung der Spaltenbreite auf das breiteste Feld
	Version 1.3: Speichern und Laden vereinfacht
	Version 1.4: MIT Lizenz ergänzt, Speicherordner von "Apps/Modelle/" auf "Apps/Notizbuch/" geändert.
	
	https://github.com/ribid1/Notizbuch

--]]--------------------------------------------------------------------------------


local model, config, pages, rows, columns, fonts, frames, aligns, texts, formID, timeB4, timeB5, Eingabespalten, neuerName
local windows = 2
local fontOptions = {"Mini", "Normal", "Bold", "Maxi"}
local fontConstants = {FONT_MINI, FONT_NORMAL, FONT_BOLD, FONT_MAXI}
local frameForms = {}
local alignForms = {}
local defaultNumber = 0
local defaultText = ""
local folder = "Apps/Notizbuch/"
local Ordner = "Apps/Notizbuch"
local extension = ".txt"
local version = "1.4"

--------------------------------------------------------------------------------
local function showPage(window)
	local r,g,b   = lcd.getBgColor()
	local startX  = 0
	local startY  = 1
	local offset  = 0
	local border  = 2
	local font    = fontConstants[fonts[window]]
	local height  = lcd.getTextHeight(font, "|") + border*2
	local rows    = rows[window]
	local columns = columns[window]
	local texts   = texts[window]
	

	if (r+g+b)/3 > 128 then
	    r,g,b = 0,0,0
	else
	    r,g,b = 255,255,255
	end

	lcd.setColor(r,g,b)

	for j=1, columns do
		local width = 0

		for i=1, rows do
			local currentWidth = lcd.getTextWidth(font, texts[i][j]) + border*2
			if (width < currentWidth) then
				width = currentWidth
			end
		end

		if (j > 1) then
			local x = startX+offset
			if (frames[window]) then
				lcd.drawLine(x, startY, x, startY+height*rows)
			end
		end

		for i=1, rows do
			local text  = texts[i][j]
			local shift = 0
			if (aligns[window] and tonumber(text)) then
				shift = width - lcd.getTextWidth(font, text) - 3
			end
			lcd.drawText(startX+offset+border+shift, startY+height*(i-1)+border, text, font)
		end

		offset = offset + width
	end

	for i=1, rows do
		if (i > 1) then
			local y = startY+height*(i-1)
			if (frames[window]) then
				lcd.drawLine(startX, y, startX+offset, y)
			end
		end
	end

	if (frames[window]) then
		lcd.drawRectangle(startX, startY, offset+1, height*rows+1)
	end
end

---------------------------------------------------------------------------------
local function showPage1()
	return showPage(1)
end

---------------------------------------------------------------------------------
local function showPage2()
	return showPage(2)
end

---------------------------------------------------------------------------------
local function setupForm1()
	for w=1, windows do
		form.addRow(1)
		form.addLabel({label = "Fenster "..w, font=FONT_BOLD})

		form.addRow(2)
		form.addLabel({label = "Zeilen", width=200})
		form.addIntbox(rows[w], 1, 10, 2, 0, 1, function(value)
			if (rows[w] < value) then
				for i=rows[w]+1, value do
					texts[w][i] = {}
					for j=1, columns[w] do
						texts[w][i][j] = defaultText
						system.pSave("text."..w.."."..i.."."..j, defaultText)
					end
				end
			else
				for i=value+1, rows[w] do
					texts[w][i] = nil
					for j=1, columns[w] do
						system.pSave("text."..w.."."..i.."."..j, nil)
					end
				end
			end

			rows[w] = value
			system.pSave("row."..w, value)
		end)

		form.addRow(2)
		form.addLabel({label = "Spalten", width=200})
		form.addIntbox(columns[w], 1, 10, 2, 0, 1, function(value)
			if (columns[w] < value) then
				for i=1, rows[w] do
					for j=columns[w]+1, value do
						texts[w][i][j] = defaultText
						system.pSave("text."..w.."."..i.."."..j, defaultText)
					end
				end
			else
				for i=1, rows[w] do
					for j=value+1, columns[w] do
						texts[w][i][j] = nil
						system.pSave("text."..w.."."..i.."."..j, nil)
					end
				end
			end

			columns[w] = value
			system.pSave("column."..w, value)
			if value < Eingabespalten[w] then  
				Eingabespalten[w] = value
				system.pSave("Eingabespalte."..w, value)
			end
			
		end)
		
		form.addRow(2)
		form.addLabel({label = "Eingabespalten:", width=200})
		
		form.addIntbox(Eingabespalten[w],1,8,1,0,1, function(value)
			if value > columns[w] then  value = columns[w] end
			Eingabespalten[w] = value
			system.pSave("Eingabespalte."..w, value)
		end)
		
		form.addRow(2)
		form.addLabel({label = "Schriftart", width=200})
		form.addSelectbox(fontOptions, fonts[w], false, function(value)
			fonts[w] = value
			system.pSave("font."..w, value)
		end)

		form.addRow(2)
		form.addLabel({label = "Umrandung", width=275})
		frameForms[w] = form.addCheckbox(frames[w], function(value)
			 frames[w] = not value
			 system.pSave("frame."..w, not value and 1 or 0)
			 form.setValue(frameForms[w], not value)
		end)

		form.addRow(2)
		form.addLabel({label = "Rechtsbündige Zahlen", width=275})
		alignForms[w] = form.addCheckbox(aligns[w], function(value)
			 aligns[w] = not value
			 system.pSave("align."..w, not value and 1 or 0)
			 form.setValue(alignForms[w], not value)
		end)

		form.addSpacer(1, 7)
	end

	form.addRow(1)
	form.addLabel({label = "Speichern / Laden", font=FONT_BOLD})
	local dateinamen = {}
	dateinamen[1]=""
	for name, filetype, size in dir(Ordner) do
		if filetype == "file" then table.insert(dateinamen, name) end
	end

	form.addRow(2)
	form.addLabel({label = "Name", width=200})
	form.addSelectbox(dateinamen,1,false, function(value)
		config = dateinamen[value]
		system.pSave("config", value)
		form.setButton(4, "S", config:len() > 0 and ENABLED or DISABLED)
		form.setButton(5, "L", config:len() > 0 and ENABLED or DISABLED)
	end)
	neuerName=""
	form.addRow(2)
	form.addLabel({label = "Neuer Name", width=200})
	form.addTextbox(neuerName, 63, function(value)
		neuerName = value..extension
		system.pSave("neuerName", value)
		form.setButton(4, "S", value:len() > 0 and ENABLED or DISABLED)
		form.setButton(5, "L", value:len() > 0 and ENABLED or DISABLED)
	end)
	form.addRow(1)
	form.addLabel({label="Um von Zahl auf Text zu wechseln -10000 eingeben!", font=FONT_MINI, alignRight=true})
	form.addRow(1)
	form.addLabel({label="Powered by Thorn, edit by dit71 - v."..version, font=FONT_MINI, alignRight=true})
end

---------------------------------------------------------------------------------
local function setupFormTable(window)
	local rows = rows[window]
	local columns = columns[window]
	local texts = texts[window]
	local types = {"Text", "Zahl"}
	local Eingabespalten = Eingabespalten[window]
	local font    = fontConstants[fonts[window]]
	local maxBreite = {}
	local maxBreiteEingabe = {}
	local sortmaxBreite = {}
	local maxBreiteRest = {}
	local Breite
	local minBreiteEingabe = 39.5+5*(8-Eingabespalten)
	local offsetText = 22
	-- local offsetInt = 27
	local fontEingabe = FONT_NORMAL
	local BSchirm = 316
	local number
  local AnzGanzeZeilen
  local Rest
	local k, temp
	
	-- maximal Breite pro Spalte
	for j=1, columns do
		maxBreite[j] = 0
		for i=1, rows do
			Breite = lcd.getTextWidth(fontEingabe, texts[i][j])
			if Breite > maxBreite[j] then maxBreite[j] = Breite end
		end
		if maxBreite[j] < 1 then maxBreite[j] = 1 end
		maxBreite[j] = maxBreite[j] + offsetText
	end
	-- maximal Breite pro Eingabespalte		
	for i = 1, Eingabespalten do
		maxBreiteEingabe[i] = 0
		AnzGanzeZeilen = math.floor(columns/Eingabespalten)
		for j = 1, AnzGanzeZeilen do
			if (maxBreite[i+(j-1)*Eingabespalten] > maxBreiteEingabe[i]) then maxBreiteEingabe[i] = maxBreite[i+(j-1)*Eingabespalten] end
		end
		if maxBreiteEingabe[i] < 1 then maxBreiteEingabe[i] = 1 end
		maxBreiteEingabe[i] = maxBreiteEingabe[i] + offsetText
	end
	
	-- Hier nun die Breiten aufteilen, Breite = 320 Höhe = 240:
	
	local gesamtBreite = 0
	for _,wert in pairs(maxBreiteEingabe) do
		gesamtBreite = gesamtBreite + wert
	end
	
	local sortmaxBreiteEingabe = {}
	
	for key in pairs(maxBreiteEingabe) do
		table.insert(sortmaxBreiteEingabe, key)
	end

	table.sort(sortmaxBreiteEingabe, function(a,b)
		return maxBreiteEingabe[a] < maxBreiteEingabe[b] end)
		
	BSchirm = 316
	for  _, key in pairs(sortmaxBreiteEingabe) do
		temp = maxBreiteEingabe[key]
		maxBreiteEingabe[key]= temp/gesamtBreite*BSchirm
		if maxBreiteEingabe[key] < minBreiteEingabe then maxBreiteEingabe[key] = minBreiteEingabe end
		gesamtBreite = gesamtBreite-temp
		BSchirm = BSchirm - maxBreiteEingabe[key]
	end
	
	Rest= columns-AnzGanzeZeilen*Eingabespalten
	if Rest > 0 then 
		gesamtBreite = 0
		
		k=0
		for j=AnzGanzeZeilen*Eingabespalten+1, columns do
			k=k+1
			gesamtBreite = gesamtBreite + maxBreite[j]
			table.insert(sortmaxBreite, k)
			table.insert(maxBreiteRest, maxBreite[j])
		end


		table.sort(sortmaxBreite, function(a,b)
			return maxBreiteRest[a] < maxBreiteRest[b] end)
			
		BSchirm = 316
		for  _, key in pairs(sortmaxBreite) do
			temp = maxBreiteRest[key]
			maxBreiteRest[key]= temp/gesamtBreite*BSchirm
			if maxBreiteRest[key] < minBreiteEingabe then maxBreiteRest[key] = minBreiteEingabe end
			gesamtBreite = gesamtBreite-temp
			BSchirm = BSchirm - maxBreiteRest[key]
		end
	end
	
			
	-- Eingabefelder anzeigen:
	for i=1, rows do
		-- if (i > 1) then
			-- form.addSpacer(1, 7)
		-- end

		form.addRow(1)
		form.addLabel({label = "Zeile "..i, font=FONT_BOLD, enabled=false})
		local row = texts[i]
		
		for l=1, AnzGanzeZeilen do
		--print ("Eingabezeite="..l)
			form.addRow(Eingabespalten)
			for k=1,Eingabespalten do
				local j=((l-1)*Eingabespalten)+k
				local stellen
				local isText = true
				number = tonumber(row[j])
				if number then
					stellen = row[j]:len()-((string.find(row[j],".",1,true)) or row[j]:len())
					number=number*10^stellen
					if number > -10000 and number < 10000 then
						isText = false
						-- if stellen>3then stellen=3 end
						form.addIntbox(number, -10000, 9999, 0,stellen, 1, function(value)
							value  = tostring(string.format("%."..stellen.."f",value/10^stellen))
							row[j] = value
							system.pSave("text."..window.."."..i.."."..j, value)
						end, {font=fontEingabe, width=maxBreiteEingabe[k]})
					end
				end
				if isText then
					form.addTextbox(row[j], 40, function(value)
						row[j] = value
						--print ("i="..i.."k="..k.."j="..j)
						system.pSave("text."..window.."."..i.."."..j, value)
					end,{font=fontEingabe, width=maxBreiteEingabe[k]})
				end 
			end
		end
		
		-- restliche Spalten
		if Rest > 0 then
			form.addRow(Rest)
			for  k=1, #maxBreiteRest do
				local j=(AnzGanzeZeilen*Eingabespalten)+k
				local stellen
				local isText = true
				number = tonumber(row[j])
				if number then
					stellen = row[j]:len()-((string.find(row[j],".",1,true)) or row[j]:len())
					number=number*10^stellen
					if number > -10000 and number < 10000 then
						isText = false
						-- if stellen>3then stellen=3 end
						form.addIntbox(number, -10000, 9999, 0,stellen, 1, function(value)
							value  = tostring(string.format("%."..stellen.."f",value/10^stellen))
							row[j] = value
							system.pSave("text."..window.."."..i.."."..j, value)
						end, {font=fontEingabe, width=maxBreiteEingabe[k]})
					end
				end
				if isText then
					form.addTextbox(row[j], 40, function(value)
						row[j] = value
						--print ("i="..i.."k="..k.."j="..j)
						system.pSave("text."..window.."."..i.."."..j, value)
					end,{font=fontEingabe, width=maxBreiteEingabe[k]})
				end 
			end
		end
			

	end
end

---------------------------------------------------------------------------------
local function setupForm2()
	setupFormTable(1)
end

---------------------------------------------------------------------------------
local function setupForm3()
	setupFormTable(2)
end

---------------------------------------------------------------------------------
local function setupForm(id)
	formID = id

	if (formID == 1) then
		setupForm1()
	elseif (formID == 2) then
		setupForm2()
	elseif (formID == 3) then
		setupForm3()
	end

	form.setButton(1, "O", formID == 1 and HIGHLIGHTED or ENABLED)
	form.setButton(2, "1", formID == 2 and HIGHLIGHTED or ENABLED)
	form.setButton(3, "2", formID == 3 and HIGHLIGHTED or ENABLED)

	if (formID == 1) then
		form.setButton(4, "S", timeB4 and HIGHLIGHTED or config:len() > 0 and ENABLED or DISABLED)
		form.setButton(5, "L", timeB5 and HIGHLIGHTED or config:len() > 0 and ENABLED or DISABLED)
	else
		form.setButton(4, ":up",   timeB4 and HIGHLIGHTED or ENABLED)
		form.setButton(5, ":down", timeB5 and HIGHLIGHTED or ENABLED)
	end
end

---------------------------------------------------------------------------------
local function toBytes(text)
	local result = ""
	local sign, id
	for i=1, text:len() do
		sign = text:sub(i, i)
		id   = sign:byte()
		if (id < 32 or id > 126) then
			sign = "["..id.."]"
		end
		result = result..sign
	end
	return result
end

---------------------------------------------------------------------------------
local function toString(bytes)
	local result = ""
	local offset = 0
	local limit  = bytes:len()
	local index, sign
	for i=1, limit do
		index = i + offset
		if (index > limit) then
			break
		end

		sign = bytes:sub(index, index)
		if (sign == "[") then
			sign   = bytes:sub(index):match("%[(%d+)%]")
			offset = offset + sign:len() + 1
			sign   = string.char(tonumber(sign))
		end
		result = result..sign
	end
	return result
end

---------------------------------------------------------------------------------
local function saveConfig()
  local saved
  
	if (neuerName:len() > 0) then config = neuerName  end
	if (config:len() > 0) then
		local file = io.open(folder..config, "w+")
		if (file) then
			local row = ""
			local column = ""
			local font = ""
			local frame = ""
			local align = ""
			local text = ""
			local space = " "
			local line = "\n"

			for w=1, windows do
				if (w > 1) then
					row    = row..space
					column = column..space
					font   = font..space
					frame  = frame..space
					align  = align..space
					text   = text..space
				end

				row    = row..rows[w]
				column = column..columns[w]
				font   = font..fonts[w]
				frame  = frame..(frames[w] and 1 or 0)
				align  = align..(aligns[w] and 1 or 0)

				for i=1, rows[w] do
					if (i > 1) then
						text = text..space
					end
					for j=1, columns[w] do
						if (j > 1) then
							text = text..space
						end
						text = text.."\""..toBytes(texts[w][i][j]).."\""
					end
				end
			end

			io.write(file, row..line)
			io.write(file, column..line)
			io.write(file, text..line)
			io.write(file, font..line)
			io.write(file, frame..line)
			io.write(file, align..line)
			io.close(file)

			config = ""
			system.pSave("config", config)

			saved = system.getTimeCounter()
		end
	end
end

---------------------------------------------------------------------------------
local function loadConfig()
  local loaded
  
	if (config:len() > 4) then
		local file = io.open(folder..config, "r")
		if (file) then
			local row = {}
			local column = {}
			local font = {}
			local frame = {}
			local align = {}
			local text = {}
			local count = 0
			local line, index

			repeat
				line = io.readline(file, true)
				if (not line) then
					break
				end

				count = count + 1
				index = 0

				if (count == 1) then
					for value in line:gmatch("%d+") do
						index = index + 1
						row[index] = tonumber(value)
					end
				elseif (count == 2) then
					for value in line:gmatch("%d+") do
						index = index + 1
						column[index] = tonumber(value)
					end
				elseif (count == 3) then
					index = index + 1
					local i,j = 1,1
					for value in line:gmatch("\"([^\"]*)\"") do
						if (not text[index]) then
							text[index] = {}
						end

						if (not text[index][i]) then
							text[index][i] = {}
						end

						text[index][i][j] = toString(value)

						j = j + 1
						if (j > column[index]) then
							j = 1
							i = i + 1

							if (i > row[index]) then
								i = 1
								index = index + 1
							end
						end
					end
					index = index - 1
				elseif (count == 4) then
					for value in line:gmatch("%d+") do
						index = index + 1
						font[index] = tonumber(value)

						if (font[index] == 5) then
							font[index] = 4
						end
					end
				elseif (count == 5) then
					for value in line:gmatch("%d+") do
						index = index + 1
						frame[index] = tonumber(value) == 1 and true or false
					end
				elseif (count == 6) then
					for value in line:gmatch("%d+") do
						index = index + 1
						align[index] = tonumber(value) == 1 and true or false
					end
				end

				if (index ~= windows) then
					io.close(file)
					return
				end
			until (count >= 6)

			if (count < 1) then
				for w=1, windows do
					row[w] = 2
				end
			end

			if (count < 2) then
				for w=1, windows do
					column[w] = 2
				end
			end

			if (count < 3) then
				for w=1, windows do
					text[w] = {}
					for i=1, row[w] do
						text[w][i] = {}
						for j=1, column[w] do
							text[w][i][j] = defaultText
						end
					end
				end
			end

			if (count < 4) then
				for w=1, windows do
					font[w] = 1
				end
			end

			if (count < 5) then
				for w=1, windows do
					frame[w] = true
				end
			end

			if (count < 6) then
				for w=1, windows do
					align[w] = false
				end
			end

			for w=1, windows do
				system.pSave("row."..w, row[w])
				system.pSave("column."..w, column[w])
				system.pSave("font."..w, font[w])
				system.pSave("frame."..w, frame[w] and 1 or 0)
				system.pSave("align."..w, align[w] and 1 or 0)

				for i=1, row[w] do
					for j=1, column[w] do
						system.pSave("text."..w.."."..i.."."..j, text[w][i][j])
					end
				end
			end

			rows = row
			columns = column
			fonts = font
			frames = frame
			aligns = align
			texts = text

			config = ""
			system.pSave("config", config)

			io.close(file)
			loaded = system.getTimeCounter()
		end
	end
end

---------------------------------------------------------------------------------
local function getFocusedEntry(window)
	local line    = form.getFocusedRow()
	local rows    = rows[window]
	local columns = columns[window]
	local row     = math.ceil(line / (columns + 2))
	local column  = line % (columns + 2) - 1

	return row, column
end

---------------------------------------------------------------------------------
local function setFocusedEntry(window, row, column)
	local columns = columns[window]
	local line    = (row - 1) * (columns + 2) + (column > 0 and column + 1 or 0)

	form.setFocusedRow(line)
end

---------------------------------------------------------------------------------
local function getNextIndex(size, index, back)
	return (back and index - 2 or index) % size + 1
end

---------------------------------------------------------------------------------
local function moveLine(window, back)
	local row, column = getFocusedEntry(window)
	local rows        = rows[window]
	local columns     = columns[window]
	local texts       = texts[window]
	local index

	if (column < 1) then
		index = getNextIndex(rows, row, back)
		texts[index], texts[row] = texts[row], texts[index]
		setFocusedEntry(window, index, column)
	else
		index = getNextIndex(columns, column, back)
		for i=1, rows do
			texts[i][index], texts[i][column] = texts[i][column], texts[i][index]
		end
		setFocusedEntry(window, row, index)
	end
end

---------------------------------------------------------------------------------
local function keyForm(key)
	if (key == KEY_1 and formID ~= 1) then
		form.reinit(1)
	elseif (key == KEY_2 and formID ~= 2) then
		form.reinit(2)
	elseif (key == KEY_3 and formID ~= 3) then
		form.reinit(3)
	elseif (key == KEY_4) then
		if (formID == 1) then
			saveConfig()
		else
			moveLine(formID - 1, true)
		end

		form.reinit(formID)
	elseif (key == KEY_5) then
		form.preventDefault()

		if (formID == 1) then
			loadConfig()
		else
			moveLine(formID - 1)
		end

		form.reinit(formID)
	end
end

---------------------------------------------------------------------------------
local function loop()
	if (timeB4 or timeB5) then
		local time  = system.getTimeCounter()
		local limit = 1000
		if (timeB4 and time - timeB4 > limit) then
			timeB4 = nil
			form.setButton(4, formID == 1 and "S" or ":up", formID ~= 1 and ENABLED or config:len() > 0 and ENABLED or DISABLED)
		end

		if (timeB5 and time - timeB5 > limit) then
			timeB5 = nil
			form.setButton(5, formID == 1 and "L" or ":down", formID ~= 1 and ENABLED or config:len() > 0 and ENABLED or DISABLED)
		end
	end
end

---------------------------------------------------------------------------------
local function init()
	pages = {showPage1, showPage2}
	model = system.getProperty("Model") or ""
	config = system.pLoad("config", "")
	rows = {}
	columns = {}
	fonts = {}
	frames = {}
	aligns = {}
	texts = {}
	Eingabespalten = {}

	for w=1, windows do
		local r = system.pLoad("row."..w, 2)
		local c = system.pLoad("column."..w, 2)

		local win = {}
		for i=1, r do
			local row = {}
			for j=1, c do
					row[j] = system.pLoad("text."..w.."."..i.."."..j, defaultText)
			end
			win[i] = row
		end
		texts[w] = win
		rows[w] = r
		columns[w] = c
		Eingabespalten[w] = system.pLoad("Eingabespalte."..w, 1)
		fonts[w] = system.pLoad("font."..w, 1)
		frames[w] = system.pLoad("frame."..w, 1) == 1 and true or false
		aligns[w] = system.pLoad("align."..w, 1) == 1 and true or false
	end

	system.registerForm(1, MENU_APPS, "Notizbuch 1", setupForm, keyForm)
	for w=1, windows do
		system.registerTelemetry(w, "Notizbuch 1 "..w.." - "..model, 4, pages[w])   -- full size Window
	end
end
--------------------------------------------------------------------------------

return {init=init, loop=loop, author="Thorn, edit by dit71", version=version, name="Notizbuch 1"}