ROT=require 'libs/rotLove/rotLove/rotLove'
astray=require 'libs/astray/astray'
require 'libs/slam/slam'
require 'npcs'
require 'areas'

-- keyboard
love.keyboard.setKeyRepeat(true)

-- sound
music = 0
sounds={}

-- basics
inventory = {sword={qty=1,attack={qty=1,faces=6,bonus=3},name="A'Long the deathbringer"},['edible moss']={qty=5},['dry mushrooms']={qty=30}}
equipment = {left_hand='sword'}
beautify=true
--beautify=false
characterX=1
characterY=1
tilePixelsX=16
tilePixelsY=16
tilemap = {}
logMessages = {}

-- colors
characterSmallness=4
notifyMessageColor={128,128,128}
failMessageColor={195,50,50}
vegetableMessageColor={50,115,50}
waterMessageColor={50,50,195}
rockColor={0,0,0}
groundColor={25,25,25}
doorColor={88,6,8}
circleColor={0,128,128}
characterColor={205,205,0}
defaultNpcColor={255,255,255}
defaultNpcLabelColor={255,255,255}
npcLabelShadowColor={0,0,0,128}
logMessageColor={200,200,200,255}
popupShadeColor={0,0,0,70}
popupBorderColor={128,128,128}
popupBackgroundColor={28,28,28}
popupTitleColor={255,255,255}
popupBlingTextColor={255,255,255}
popupBrightTextColor={188,188,188}
popupNormalTextColor={128,128,128}
popupDarkTextColor={75,75,75}

-- footprints
footprints = {}
max_footprints=130

-- ground features
groundfeatures = {}

-- determine available fullscreen modes
print('Querying available fullscreen modes...')
modes = love.window.getFullscreenModes()
-- sort from smallest to largest
table.sort(modes, function(a, b) return a.width*a.height < b.width*b.height end)
-- get largest
v = modes[#modes]
-- report
print(' - Reported maximum full screen resolution: ' .. v.width .. ' x ' .. v.height .. ' pixels')
resolutionPixelsX=v.width
resolutionPixelsY=v.height
screenModeFlags = {fullscreen=true, fullscreentype='desktop', vsync=true, msaa=0}
-- screenModeFlags = {fullscreen=true}

function love.load()

	-- load font
        heavy_font = love.graphics.newFont("fonts/pf_tempesta_five_extended_bold.ttf",8)
        medium_font = love.graphics.newFont("fonts/pf_tempesta_five_bold.ttf",8)
        light_font = love.graphics.newFont("fonts/pf_tempesta_five.ttf",8)
	love.graphics.setFont(light_font)

	-- hide mouse
	love.mouse.setVisible(false)

	-- set up graphics mode
	print(' - Attempting to switch to fullscreen resolution.')
	love.window.setMode(resolutionPixelsX, resolutionPixelsY, screenModeFlags)
	resolutionPixelsX = love.graphics.getWidth()
	resolutionPixelsY = love.graphics.getHeight()
	print(' - Resolution obtained: ' .. resolutionPixelsX .. ' x ' .. resolutionPixelsY .. ' pixels')

	-- now determine tile resolution
	print('Tile size: ' .. tilePixelsX .. ' x ' .. tilePixelsY .. ' pixels')
	resolutionTilesX=math.floor(resolutionPixelsX/tilePixelsX)
	resolutionTilesY=math.floor(resolutionPixelsY/tilePixelsY)
	print('Displayable tilemap size: ' .. resolutionTilesX .. ' x ' .. resolutionTilesY .. ' tiles')

	-- now pre-initialize tilemap table row tables
	for i=1,resolutionTilesX,1 do
		tilemap[i]={}
	end

	-- OLD generate tilemap
--[[
        cl=ROT.Map.Cellular:new(resolutionTilesX, resolutionTilesY) -- , {connected=true})
        cl:randomize(.50)  -- .50 is the probability any given tile is a floor
        cl=ROT.Map.Rogue:new(resolutionTilesX, resolutionTilesY)
        cl:create(tile_callback)
--]]
--[[
	-- NEW generate tilemap
	--  width,
	--  height,
	--  changeDirectionModifier,    (10 = super straight, 90 = wiggly as hell)   = "wiggliness"
	--  sparsenessModifier,         (10 = full of corridors, 90 = full of rock)  = "rockiness"
	--  deadEndRemovalModifier,     (10 = lots of dead ends, 100 = no dead ends) = "connectedness"
	--  roomGenerator
]]--
	local symbols = {Wall=0, Empty=1, DoorN=2, DoorS=2, DoorE=2, DoorW=2}
	--local generator = astray.Astray:new( math.floor(resolutionTilesX/2), math.floor(resolutionTilesY/2), 30, 20, 90, astray.RoomGenerator:new(10,1,5,1,5) )
	--local generator = astray.Astray:new( resolutionTilesY-1, math.floor(resolutionTilesY/2)-1, 30, 20, 90, astray.RoomGenerator:new(10,1,5,1,5) )
	--local generator = astray.Astray:new( resolutionTilesX/2-1, resolutionTilesY/2-1, 30, 20, 90, astray.RoomGenerator:new(10,1,5,1,5) )
	local generator = astray.Astray:new( resolutionTilesX/2-1, resolutionTilesY/2-1, 80, 70, 100, astray.RoomGenerator:new(10,1,5,1,5) )
	local dungeon = generator:Generate()
	local tmp_tilemap = generator:CellToTiles(dungeon, symbols )

	-- sanity check
	--print("width of tilemap is " .. #tilemap)
	--print("width of tmp_tilemap is " .. #tmp_tilemap)

	for y = 1, #tmp_tilemap[1] do
        	local line = ''
                for x = 1, #tmp_tilemap do
			local nx=x-1
			local ny=y-1
			if tmp_tilemap[nx] ~= nil and tmp_tilemap[nx][ny] ~= nil then
				-- print("tilemap x=" .. x .. "/y=" .. y .. " so nx=" .. nx .. "/ny=" .. ny)
				tilemap[x][y] = tmp_tilemap[nx][ny]
                        	line = line .. tmp_tilemap[nx][ny]
			end
                end
                --print(line)
        end

	-- randomly place character
	print "Randomly placing character..."
	characterX, characterY = randomStandingLocation()
	--rl:setLight(characterX,characterY,{255,255,255,255})

	-- npc characters
	print "Generating NPCs..."

	-- add npcs
	add_npcs('akha_villager',2)
	add_npcs('hmong_villager',2)
	add_npcs('tai_villager_male',2)
	add_npcs('tai_villager_female',2)
	add_npcs('tibetan_villager',2)
	add_npcs('yi_villager',2)
	add_npcs('goblin',1)
	add_npcs('dog',1)
	add_npcs('mouse',1)

	-- place npcs
	print "Randomly placing NPCs..."
	for i=1,#npcs,1 do
		npcs[i]['location'] = {}
		npcs[i]['location']['x'],npcs[i]['location']['y'] = randomStandingLocationWithoutNPCsOrPlayer()
	end

	-- place ground features
	for i=1,120,1 do
		groundfeatures[i] = {}
		groundfeatures[i]['x'],groundfeatures[i]['y'] = randomStandingLocation()
		if i < 3 then
			groundfeatures[i]['type'] = 'shrub'
		elseif i < 10 then
			groundfeatures[i]['type'] = 'puddle'
		else
			groundfeatures[i]['type'] = 'stone'
		end
	end

	-- place stairs
	print "Randomly placing stairs..."
	stairsX, stairsY = randomStandingLocation()
	tilemap[stairsX][stairsY] = '>'
	stairsX, stairsY = randomStandingLocation()
	tilemap[stairsX][stairsY] = '<'

	-- beautify tiles
	if beautify then
		print "Beautifying tiles..."
		beautifyTiles()
	end

	-- load sounds
	print("Loading sounds...")
	sounds['pickup'] = love.audio.newSource("sounds/8-bit/pickup.wav")
	sounds['door_open'] = love.audio.newSource("sounds/8-bit/door-open.wav")
	sounds['door_close'] = love.audio.newSource("sounds/8-bit/door-close.wav")
	sounds['footfall_water'] = love.audio.newSource("sounds/8-bit/footfall-water-1.wav")
	sounds['footfalls'] = {}
	table.insert(sounds['footfalls'],love.audio.newSource("sounds/8-bit/footfall-1.wav"))
	table.insert(sounds['footfalls'],love.audio.newSource("sounds/8-bit/footfall-2.wav"))
	table.insert(sounds['footfalls'],love.audio.newSource("sounds/8-bit/footfall-3.wav"))
	table.insert(sounds['footfalls'],love.audio.newSource("sounds/8-bit/footfall-4.wav"))
	table.insert(sounds['footfalls'],love.audio.newSource("sounds/8-bit/footfall-5.wav"))

	-- start music
	print("Starting music...")
	music = love.audio.newSource({
					"music/Greg_Reinfeld_-_02_-_Canon_in_D_ni_nonaC_Pachelbels_Canon.mp3",
					"music/Kevin MacLeod - Sardana.mp3",
					"music/Kevin MacLeod - Suonatore di Liuto.mp3",
					"music/Kevin MacLeod - Teller of the Tales.mp3",
					"music/Komiku_-_03_-_Champ_de_tournesol.mp3",
					"music/Komiku_-_05_-_La_Citadelle.mp3",
					"music/Komiku_-_06_-_La_ville_aux_ponts_suspendus.mp3"
				   })
	music:setLooping(true)
	music:play()
	music:setVolume(0.05)
	ambience = love.audio.newSource({
						"sounds/ambient/cave-drips.mp3"
					})
	ambience:setLooping(true)
	music:setVolume(2)
	ambience:play()

	print('--------------------------- OK! Here we go! ---------------------------------')
end

function love.keypressed(key)
        if key == "left" or key == "4" then
                moveCharacterRelatively(-1,0)
        elseif key == "right" or key == "6" then
                moveCharacterRelatively(1,0)
        elseif key == "up" or key == "8" then
                moveCharacterRelatively(0,-1)
        elseif key == "down" or key == "2" then
                moveCharacterRelatively(0,1)
	elseif key == "1" then
		moveCharacterRelatively(-1,1)
	elseif key == "3" then
		moveCharacterRelatively(1,1)
	elseif key == "7" then
		moveCharacterRelatively(-1,-1)
	elseif key == "9" then
		moveCharacterRelatively(1,-1)
        elseif key == "c" then
		-- attempt to close nearby doors
		closedoors()
        elseif key == "o" then
		-- attempt to open nearby doors
		opendoors()
        elseif key == "escape" then
		love.event.quit()
	-- '>'
	elseif key == "." and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
		descend()
	-- '<'
	elseif key == "," and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
		ascend()
        end
end

function love.draw()
	-- the most important part
	--local start_time = love.timer.getTime()
	draw_tilemap()				-- rare changes (~4-5ms or so)
        draw_tilemap_beautification()           -- rare changes (costs ~1ms or so)
	--local draw_tilemap_time = love.timer.getTime()-start_time
	--print( string.format( "Time to draw tilemap: %.3f ms", draw_tilemap_time*1000))

	-- currently these are all redrawn every frame... could optimize this later
	--local start_time = love.timer.getTime()
	draw_footprints()			-- frequent changes
	draw_groundfeatures()			-- occasional changes
	draw_doors()				-- occasional changes
	draw_stairs()				-- never changes
	draw_character()			-- frequent changes
	draw_npcs()				-- frequent changes
	--local draw_dynamics_time = love.timer.getTime()-start_time
	--print( string.format( "Time to draw dynamics: %.3f ms", draw_dynamics_time*1000))

	-- highly dynamic, usually no drawing at all
	draw_logmessages()
	draw_popups()
end

function draw_tilemap()
	-- draw tilemap
	local x, y = 1
	for x=1,resolutionTilesX,1 do
		for y=1,resolutionTilesY,1 do
			-- 1 = floor, 2 = closed door, 3 = open door, '<' = upward stairs, '>' = downward stairs
			if tilemap[x][y] == 1 or tilemap[x][y] == 2 or tilemap[x][y] == 3 or tilemap[x][y] == '<' or tilemap[x][y] == '>' then
				love.graphics.setColor(groundColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			end
		end
	end
end

function draw_footprints()
	-- draw footprints
	love.graphics.setColor(50,50,50,50)
	for i,footprint in ipairs(footprints) do
		love.graphics.rectangle('line',(footprint['x']-1)*tilePixelsX+2,(footprint['y']-1)*tilePixelsY+2,3,3)
		love.graphics.rectangle('line',(footprint['x']-1)*tilePixelsX+8,(footprint['y']-1)*tilePixelsY+8,3,3)
	end
end

function draw_groundfeatures()
	-- draw groundfeatures
	for i,feature in ipairs(groundfeatures) do
		if feature['type'] == 'shrub' then
			love.graphics.setColor(20,85,30,90)
			love.graphics.line(
						(feature['x']-1)*tilePixelsX+4, (feature['y']-1)*tilePixelsY+2,
						(feature['x']-1)*tilePixelsX+6, (feature['y']-1)*tilePixelsY+13,
						(feature['x']-1)*tilePixelsX+12, (feature['y']-1)*tilePixelsY+4
					  )
			love.graphics.line(
						(feature['x']-1)*tilePixelsX+6, (feature['y']-1)*tilePixelsY+13,
						(feature['x']-1)*tilePixelsX+8, (feature['y']-1)*tilePixelsY+5
					  )
		elseif feature['type'] == 'puddle' then
			love.graphics.setColor(0,10,65,155)
			love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2, (feature['y']-1)*tilePixelsY+tilePixelsY/2, (tilePixelsX/2)-5)
		elseif feature['type'] == 'stone' then
			love.graphics.setColor(rockColor,120)
			love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2+3, (feature['y']-1)*tilePixelsY+tilePixelsY/2+6, (tilePixelsX/4)-3)
		end
	end
end

function draw_stairs()
	local x, y = 1
	for x=1,resolutionTilesX,1 do
		for y=1,resolutionTilesY,1 do
			if tilemap[x][y] == '>' or tilemap[x][y] == '<' then
				love.graphics.setColor(0,0,0,255)
				love.graphics.rectangle('fill',(x-1)*tilePixelsX,(y-1)*tilePixelsY+2,tilePixelsX-3,tilePixelsY-3)
				love.graphics.setColor(255,255,255,255)
				local total_lines = math.floor(tilePixelsX*0.7/2.5)
				local colorstep = 130/total_lines
				for i=1,total_lines,1 do
					love.graphics.setColor(255-(i*colorstep),255-(i*colorstep),255-(i*colorstep),255-(i*colorstep))
					if true or tilemap[x][y] == '>' then
						love.graphics.line(
									(x-1)*tilePixelsX+(i-1)*3+2,
									(y-1)*tilePixelsY+4,
									(x-1)*tilePixelsX+(i-1)*3+2,
									(y-1)*tilePixelsY+tilePixelsY-3
						)
					else
						love.graphics.line(
									(x-1)*tilePixelsX+tilePixelsX-(i-1)*3+2,
									(y-1)*tilePixelsY+4,
									(x-1)*tilePixelsX+tilePixelsX-(i-1)*3+2,
									(y-1)*tilePixelsY+tilePixelsY-3
						)
					end
				end
				love.graphics.setColor(155,155,155,255)
				love.graphics.setFont(heavy_font)
				love.graphics.print(tilemap[x][y],(x-1)*tilePixelsX+tilePixelsX/2*0.7,(y-1)*tilePixelsY+1)
			end
		end
	end
end

function draw_doors()
	-- draw doors (on top of the map tilemap)
	local x, y = 1
	for x=1,resolutionTilesX,1 do
		for y=1,resolutionTilesY,1 do
			-- if horizontal door
			if (x>1 and tilemap[x-1][y] == 0) or (x<resolutionTilesX and tilemap[x+1][y] == 0) then
				-- 2 = closed door
				if tilemap[x][y] == 2 then
					love.graphics.setColor(doorColor)
					love.graphics.rectangle("fill", (x-1)*tilePixelsX,(y-1)*tilePixelsY+(math.floor(tilePixelsY/2)),tilePixelsX,3)
				-- 3 = open door
				elseif tilemap[x][y] == 3 then
					love.graphics.setColor(doorColor)
					love.graphics.rectangle("fill", (x-1)*tilePixelsX,(y-1)*tilePixelsY+(math.floor(tilePixelsY/2)),3,tilePixelsY)
				end
			-- vertical door
			else
				-- 2 = closed door
				if tilemap[x][y] == 2 then
					love.graphics.setColor(doorColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+(math.floor(tilePixelsX/2)),(y-1)*tilePixelsX,3,tilePixelsY)
				-- 3 = open door
				elseif tilemap[x][y] == 3 then
					love.graphics.setColor(doorColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+(math.floor(tilePixelsX/2)),(y-1)*tilePixelsX,tilePixelsX,3)
				end
			end
		end
	end
end

function draw_tilemap_beautification()
	if beautify then
		for x=1,resolutionTilesX,1 do
			for y=1,resolutionTilesY,1 do
				if tilemap[x][y] == 'o' then
					love.graphics.setColor(rockColor)
					love.graphics.circle("fill",(x-1)*tilePixelsX+(0.5*tilePixelsX),(y-1)*tilePixelsY+(0.5*tilePixelsX),math.floor(tilePixelsX/2)-1,10)
				elseif tilemap[x][y] == '^' then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX,(y-1)*tilePixelsY,2,2)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+tilePixelsX-2,(y-1)*tilePixelsY,2,2)
				elseif tilemap[x][y] == 4 then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX,(y-1)*tilePixelsY+tilePixelsY-2,2,2)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+tilePixelsX-2,(y-1)*tilePixelsY+tilePixelsY-2,2,2)
				elseif tilemap[x][y] == 5 then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX,(y-1)*tilePixelsY,2,2)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX,(y-1)*tilePixelsY+tilePixelsY-2,2,2)
				elseif tilemap[x][y] == 6 then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+tilePixelsX-2,(y-1)*tilePixelsY,2,2)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+tilePixelsX-2,(y-1)*tilePixelsY+tilePixelsY-2,2,2)
				elseif tilemap[x][y] == 7 then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+tilePixelsX-2,(y-1)*tilePixelsY+tilePixelsY-2,2,2)
				elseif tilemap[x][y] == 8 then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX,(y-1)*tilePixelsY+tilePixelsY-2,2,2)
				elseif tilemap[x][y] == 9 then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX,(y-1)*tilePixelsY,2,2)
				elseif tilemap[x][y] == 'R' then
					love.graphics.setColor(groundColor)
					love.graphics.rectangle("fill",(x-1)*tilePixelsX+tilePixelsX-2,(y-1)*tilePixelsY,2,2)
				end
			end
		end
	end
end

function draw_character()
	-- draw character
	love.graphics.setColor(characterColor)
	love.graphics.rectangle('fill',(characterX-1)*tilePixelsX+characterSmallness,(characterY-1)*tilePixelsY+characterSmallness,tilePixelsX-characterSmallness*2,tilePixelsY-characterSmallness*2)
end

function draw_npcs()
	-- draw npcs
	for i=1,#npcs,1 do
		local l=npcs[i]['location']
		if npcs[i]['color'] ~= nil then
			love.graphics.setColor(npcs[i]['color'])
		else
			love.graphics.setColor(defaultNpcColor)
		end
		love.graphics.rectangle('fill',(l['x']-1)*tilePixelsX+characterSmallness,(l['y']-1)*tilePixelsY+characterSmallness,tilePixelsX-characterSmallness*2,tilePixelsY-characterSmallness*2)
		if npcs[i]['tail'] ~= nil then
			love.graphics.rectangle('fill',(l['x']-1)*tilePixelsX+characterSmallness,(l['y']-1)*tilePixelsY+tilePixelsY-characterSmallness-2,-2,2)
			love.graphics.rectangle('fill',(l['x']-1)*tilePixelsX+characterSmallness-2,(l['y']-1)*tilePixelsY+tilePixelsY-characterSmallness-4,1,2)
			love.graphics.setColor(0,0,0,255)
			love.graphics.points({
				(l['x']-1)*tilePixelsX+characterSmallness+2,
				(l['y']-1)*tilePixelsY+characterSmallness+2,
				(l['x']-1)*tilePixelsX+tilePixelsX-characterSmallness-3,
				(l['y']-1)*tilePixelsY+characterSmallness+2,
					    })
		end
	        love.graphics.setColor(npcLabelShadowColor)
		-- NB. The following line is useful for debugging UTF-8 issues which Lua has in buckets
		-- print("name: " .. npcs[i]['name'] .. " (" .. npcs[i]['type'] .. ")")
		love.graphics.setFont(light_font)
                love.graphics.print(npcs[i]['name'],(l['x']-1)*tilePixelsX+math.floor(tilePixelsX/2)+7, (l['y']-1)*tilePixelsY+2)
		if npcs[i]['color'] ~= nil then
			love.graphics.setColor(npcs[i]['color'])
		else
			love.graphics.setColor(defaultNpcLabelColor)
		end
		love.graphics.setFont(light_font)
                love.graphics.print(npcs[i]['name'],(l['x']-1)*tilePixelsX+math.floor(tilePixelsX/2)+6, (l['y']-1)*tilePixelsY+1)
	end
end

function draw_logmessages()
	-- draw log messages
	local a = 0
	if #logMessages > 0 then
		for i,message in ipairs(logMessages) do
			local difference = os.clock() - message['time']
			a = 355 - (255*string.format("%.2f",difference))
			if a > 0 then
				local myColor = r,g,b,a
				love.graphics.setColor(a,a,a,a)
				love.graphics.setFont(light_font)
				love.graphics.print(message['message'],20,15*i)
			else
				message['delete'] = true
			end
		end
		for i,message in ipairs(logMessages) do
			if message['delete'] == true then
				table.remove(logMessages,i)
			end
		end
	end
end

function draw_popups()
	-- draw popups
	local border=100
	local pad=10
	-- help
	if love.keyboard.isDown('h') then
		-- shade others
		love.graphics.setColor(popupShadeColor)
		love.graphics.rectangle('fill',0,0,resolutionPixelsX,resolutionPixelsY)
		-- draw popup
		love.graphics.setColor(popupBorderColor)
		love.graphics.rectangle('fill',border,border,resolutionPixelsX-(border*2),resolutionPixelsY-(border*2))
		-- draw popup content box
		love.graphics.setColor(popupBackgroundColor)
		love.graphics.rectangle('fill',border+pad,border+pad,resolutionPixelsX-(border*2)-(pad*2),resolutionPixelsY-(border*2)-(pad*2))
		-- draw title
		love.graphics.setColor(popupTitleColor)
		love.graphics.setFont(heavy_font)
		love.graphics.printf("Help",0,border*1.3,resolutionPixelsX,"center")
		keys = {
			c='Close doors',
			e='Equipment',
			h='Help',
			i='Inventory',
			o='Open doors',
			arrows='Movement',
			escape='Quit',
			['<']='Up stairs / ladder',
			['>']='Down stairs / ladder'
		       }
		local i=0
		for key,description in pairs(keys) do
			output = {}
			table.insert(output, popupBrightTextColor)
			table.insert(output, key)
			local width=80
			love.graphics.setFont(light_font)
			love.graphics.printf(output, border+pad, border*1.3+pad+pad+i*20-1, pad+resolutionPixelsX/2*0.1-pad, "right")
			output = {}
			table.insert(output, popupNormalTextColor)
			table.insert(output, description)
			love.graphics.setFont(light_font)
			love.graphics.print(output,	math.floor(border+pad+resolutionPixelsX/2*0.1+pad*3),	border*1.3+pad+pad+i*20)
			i=i+1
		end
	-- equipment
	elseif love.keyboard.isDown('e') then
		-- shade others
		love.graphics.setColor(popupShadeColor)
		love.graphics.rectangle('fill',0,0,resolutionPixelsX,resolutionPixelsY)
		-- draw popup
		love.graphics.setColor(popupBorderColor)
		love.graphics.rectangle('fill',border,border,resolutionPixelsX-(border*2),resolutionPixelsY-(border*2))
		-- draw popup content box
		love.graphics.setColor(popupBackgroundColor)
		love.graphics.rectangle('fill',border+pad,border+pad,resolutionPixelsX-(border*2)-(pad*2),resolutionPixelsY-(border*2)-(pad*2))
		-- draw title
		love.graphics.setColor(popupTitleColor)
		love.graphics.setFont(heavy_font)
		love.graphics.printf("Equipment",0,border*1.3,resolutionPixelsX,"center")
	-- inventory
	elseif love.keyboard.isDown('i') then
		-- shade others
		love.graphics.setColor(popupShadeColor)
		love.graphics.rectangle('fill',0,0,resolutionPixelsX,resolutionPixelsY)
		-- draw popup
		love.graphics.setColor(popupBorderColor)
		love.graphics.rectangle('fill',border,border,resolutionPixelsX-(border*2),resolutionPixelsY-(border*2))
		-- draw popup content box
		love.graphics.setColor(popupBackgroundColor)
		love.graphics.rectangle('fill',border+pad,border+pad,resolutionPixelsX-(border*2)-(pad*2),resolutionPixelsY-(border*2)-(pad*2))
		-- draw title
		love.graphics.setColor(popupTitleColor)
		love.graphics.setFont(heavy_font)
		love.graphics.printf("Inventory",0,border*1.3,resolutionPixelsX,"center")
		-- draw inventory contents
		local i=0
		for index,item in pairs(inventory) do
			love.graphics.setColor(popupBrightTextColor)
			love.graphics.setFont(light_font)
			love.graphics.printf(item.qty, border+pad, border*1.3+pad+pad+i*20-1, pad+resolutionPixelsX/2*0.1-pad, "right")
			love.graphics.setColor(popupDarkTextColor)
			love.graphics.setFont(light_font)
			love.graphics.print('x',	math.floor(border+pad+resolutionPixelsX/2*0.1+pad),    	border*1.3+pad+pad+i*20)
			love.graphics.setColor(255,255,255,255)
			local item_description = { popupBrightTextColor, index }
			-- extend this if appropriate
			if item['name'] ~= nil then
					table.insert(item_description,popupNormalTextColor)
					table.insert(item_description,' "')
					table.insert(item_description,popupBlingTextColor)
					table.insert(item_description, item['name'])
					table.insert(item_description,popupNormalTextColor)
					table.insert(item_description,'" ')
			end
			if item['attack'] ~= nil then
				if item['attack']['qty'] ~= nil and
				   item['attack']['faces'] ~= nil then
					table.insert(item_description, popupDarkTextColor)
					table.insert(item_description, ' <')
					table.insert(item_description, popupBrightTextColor)
					table.insert(item_description, item['attack']['qty'] .. 'd' .. item['attack']['faces'])
					if item['attack']['bonus'] ~= nil then
						table.insert(item_description, popupNormalTextColor)
						table.insert(item_description, '+')
						table.insert(item_description, popupBrightTextColor)
						table.insert(item_description, item['attack']['bonus'])
					end
					table.insert(item_description, popupDarkTextColor)
					table.insert(item_description, '>')
				end
			end
			love.graphics.setFont(light_font)
			love.graphics.print(item_description,	math.floor(border+pad+resolutionPixelsX/2*0.1+pad*3),	border*1.3+pad+pad+i*20)
			i = i + 1
		end
		if i==0 then
			love.graphics.setFont(medium_font)
			love.graphics.printf("You have no items.",0,math.floor(resolutionPixelsY/2)-10,resolutionPixelsX,"center")
		end
	end
end

-- tiletype 0 = floor, 1 = wall
function tile_callback(tilex,tiley,tiletype)
	if tiletype == 0 then
		tiletype = 1
	elseif tiletype == 1 then
		tiletype = 0
	end
	tilemap[tilex][tiley] = tiletype
end

-- move the character relatively to a new location, but only if the desination is walkable
function moveCharacterRelatively(x,y)
	newX = characterX + x
	newY = characterY + y
	-- if the map space is potentially standable (1 = floor, 3 = open door, '<' = down stairs, '>' = up stairs)
	if tilemap[newX][newY] == 1 or tilemap[newX][newY] == 2 or tilemap[newX][newY] == 3 or tilemap[newX][newY] == '<' or tilemap[newX][newY] == '>' then
		local blocked=false
		-- if it's a closed door, open it
		if tilemap[newX][newY] == 2 then
			opendoor(newX,newY)
		else
			-- if there is no NPC there
			for i=1,#npcs,1 do
				-- for some reason this is required occasionally... seems an off by one end-of-table bug
				if npcs[i] ~= nil then
					-- actual check
					if npcs[i]['location']['x'] == newX and
					   npcs[i]['location']['y'] == newY then
						-- there is an npc there
						if npcs[i]['hostile'] == true then
							-- hostile npc: fight
							attack_npc(i)
						else
							-- non-hostile npc: whinge
							npcs[i]['sounds']['attack']:play()
							logMessage(failMessageColor,npcs[i]['name'] .. ' is in the way.')
						end
						blocked=true
					end
				end
			end
		end
		if blocked == false then
			-- if the new location is not beyond the map
			if newX > 0 and newY > 0 and newX <= resolutionTilesX and newY <= resolutionTilesY then
				-- ACTUALLY MOVE!
				footfallNoise()
				table.insert(footprints,{x=characterX,y=characterY,r=math.random(-90,90)})
				if #footprints > max_footprints then
					table.remove(footprints,1)
				end
				characterX = newX
				characterY = newY
				autoPickup()
				endTurn()
			end
		end
	else
		if tilemap[newX][newY] == 0 then
			logMessage(failMessageColor,"You can't move that way (there is a wall in the way).")
		else
			logMessage(failMessageColor,"You can't move that way (there is something in the way).")
		end
	end
end

-- make the tiles more beautiful
function beautifyTiles()
	for x=2,resolutionTilesX-1,1 do
		for y=2,resolutionTilesY-1,1 do
			-- if the tile is 0 (ie. floor) AND ... 
			if tilemap[x][y] == 0 then
				-- .... is fully surrounded by floor (1), then mark it as 2
				if tilemap[x-1][y] == 1 and
				   tilemap[x+1][y] == 1 and
				   tilemap[x][y-1] == 1 and
				   tilemap[x][y+1] == 1 then
					tilemap[x][y] = 'o'
				-- .... is fully surrounded by floor (1), except on the bottom, then mark it as 3
				elseif tilemap[x-1][y] == 1 and
				       tilemap[x+1][y] == 1 and
				       tilemap[x][y-1] == 1 then
						tilemap[x][y] = '^'
				-- .... is fully surrounded by floor (1), except on the top, then mark it as 4
				elseif tilemap[x-1][y] == 1 and
				       tilemap[x+1][y] == 1 and
				       tilemap[x][y+1] == 1 then
						tilemap[x][y] = 4
				-- .... is fully surrounded by floor (1), except on the right, then mark it as 5
				elseif tilemap[x-1][y] == 1 and
				       tilemap[x][y-1] == 1 and
				       tilemap[x][y+1] == 1 then
						tilemap[x][y] = 5
				-- .... is fully surrounded by floor (1), except on the left, then mark it as 6
				elseif tilemap[x+1][y] == 1 and
				       tilemap[x][y-1] == 1 and
				       tilemap[x][y+1] == 1 then
						tilemap[x][y] = 6
				-- .... is surrounded by floor (1) only on the right and bottom, then mark it as 7
				elseif tilemap[x+1][y] == 1 and
				       tilemap[x][y+1] == 1 then
						tilemap[x][y] = 7
				-- .... is surrounded by floor (1) only on the left and bottom, then mark it as 8
				elseif tilemap[x-1][y] == 1 and
				       tilemap[x][y+1] == 1 then
						tilemap[x][y] = 8
				-- .... is surrounded by floor (1) only on the left and top, then mark it as 9
				elseif tilemap[x-1][y] == 1 and
				       tilemap[x][y-1] == 1 then
						tilemap[x][y] = 9
				-- .... is surrounded by floor (1) only on the right and top, then mark it as R
				elseif tilemap[x+1][y] == 1 and
				       tilemap[x][y-1] == 1 then
						tilemap[x][y] = 'R'
				end
			end
		end
	end
end

function randomStandingLocationWithoutNPCsOrPlayer()
	local failed = 1
	local x,y = 0
	while not(failed == 0) do
		failed = 1
		x,y = randomStandingLocation()
		if x == characterX and y == characterY then
			failed = true
		else
			-- search all NPCs for same coordinates
			for i,npc in ipairs(npcs) do
				local l = npc['location']
				if l ~= nil then
					if l['x'] == x and l['y'] == y then
						failed = failed + 1
						break
					end
				end
			end
			failed = failed - 1
		end
	end
	return x, y
end

function randomStandingLocation()
	local found_x,found_y = 0
	local placed=false
	while placed == false do
		x = math.random(1,resolutionTilesX)
		y = math.random(1,resolutionTilesY)
		if tilemap[x][y] == 1 or tilemap[x][y] == '1' then
			found_x = x
			found_y = y
			placed = true
		end
		--print("randomStandingLocation failed @ " .. x .. "/" .. y .. " (wanted 1 found '" .. tilemap[x][y] .. "')")
	end
	return x,y
end

function logMessage(color,string)
	table.insert(logMessages,{time=os.clock(),message={color,string}})
end

function footfallNoise()
	local id = math.floor(math.random(1,#sounds['footfalls']))
	local instance = sounds['footfalls'][id]:play()
	instance:setVolume(1.5)
        instance:setPitch(.5 + math.random() * .5)          -- set pitch for this instance only
end

function autoPickup()
	for i,gf in ipairs(groundfeatures) do
		if gf.x == characterX and gf.y == characterY then
			-- auto pickup
			if gf.type == 'shrub' then
				logMessage(vegetableMessageColor,'You collect vegetable matter from a shrub.')
				table.remove(groundfeatures,i)
				inventory_add('vegetable matter')
			elseif gf.type == 'stone' then
				logMessage(notifyMessageColor,'You collect a small pebble.')
				table.remove(groundfeatures,i)
				inventory_add('pebble')
			elseif gf.type == 'puddle' then
				logMessage(waterMessageColor,'You tread in a puddle.')
				sounds['footfall_water']:play()
			end
		end
	end
end

function opendoors()
	for x=-1,1,1 do
		if tilemap[characterX+x][characterY-1] == 2 then
			opendoor(characterX+x,characterY-1)
		end
		if tilemap[characterX+x][characterY+1] == 2 then
			opendoor(characterX+x,characterY+1)
		end
	end
	if tilemap[characterX-1][characterY] == 2 then
		opendoor(characterX-1,characterY)
	end
	if tilemap[characterX+1][characterY] == 2 then
		opendoor(characterX+1,characterY)
	end
end

function closedoors()
	for x=-1,1,1 do
		if tilemap[characterX+x][characterY-1] == 3 then
			closedoor(characterX+x,characterY-1)
		end
		if tilemap[characterX+x][characterY+1] == 3 then
			closedoor(characterX+x,characterY+1)
		end
	end
	if tilemap[characterX-1][characterY] == 3 then
		closedoor(characterX-1,characterY)
	end
	if tilemap[characterX+1][characterY] == 3 then
		closedoor(characterX+1,characterY)
	end
end

function opendoor(x,y)
	if tilemap[x][y] == 2 then
		local instance=sounds['door_open']:play()
		instance:setVolume(1)
		logMessage(notifyMessageColor,"You opened the door.")
		tilemap[x][y] = 3
	end
end

function closedoor(x,y)
	if tilemap[x][y] == 3 then
		local instance = sounds['door_close']:play()
		instance:setVolume(1)
		logMessage(notifyMessageColor,"You closed the door.")
		tilemap[x][y] = 2
	end
end

function inventory_add(thing)
	local instance = sounds['pickup']:play()
	instance:setVolume(1)
	if inventory[thing] == nil then
		inventory[thing] = {qty=0}
	end
	inventory[thing]['qty'] = inventory[thing]['qty'] + 1
end

function endTurn()
	-- allow NPCs to move
	for i,npc in ipairs(npcs) do
		-- each one has a 10% chance of moving
		local movementchance = math.floor(math.random(0,10))
		if movementchance == 9 then
			-- attempt to move: pick a direction, then try all directions clockwise until success
			local direction = math.ceil(math.random(0,9))
			local success=false
			local attempts=0
			local l=npc.location
			while success==false and attempts<8 do
				-- sw
				if direction == 1 then
					tryx = l.x-1
					tryy = l.y+1
				-- s
				elseif direction == 2 then
					tryx = l.x
					tryy = l.y+1
				-- se
				elseif direction == 3 then
					tryx = l.x+1
					tryy = l.y+1
				-- w
				elseif direction == 4 then
					tryx = l.x-1
					tryy = l.y
				-- e
				elseif direction == 6 then
					tryx = l.x+1
					tryy = l.y
				-- nw
				elseif direction == 7 then
					tryx = l.x-1
					tryy = l.y-1
				-- n
				elseif direction == 8 then
					tryx = l.x
					tryy = l.y-1
				-- ne
				elseif direction == 7 then
					tryx = l.x+1
					tryy = l.y-1
				end
				-- moment of truth
				success=true			
				attempts = attempts + 1
			end
		end
	end
end

function descend()
	if tilemap[characterX][characterY] == ">" then
		logMessage(notifyMessageColor,'Descending...')
		music:stop()
		music:play()
	else
		logMessage(failMessageColor,'There is no way down here!')
	end
end

function ascend()
	if tilemap[characterX][characterY] == "<" then
		logMessage(notifyMessageColor,'Ascending...')
		music:stop()
		music:play()
	else
		logMessage(failMessageColor,'There is no way up here!')
	end
end

function attack_npc(i)
	npcs[i]['sounds']['attack']:setVolume(3)
	npcs[i]['sounds']['attack']:play()
	logMessage(notifyMessageColor,'You smash it!')
	--table.remove(npcs,i)
end