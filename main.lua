-- libraries
ROT=require 'libs/rotLove/rotLove/rotLove'
astray=require 'libs/astray/astray'
require 'libs/slam/slam'
shack=require 'libs/shack/shack'
flux=require 'libs/flux/flux'
require 'libs/svglover/svglover'
tweens={}

-- game portions
require 'npcs'
require 'areas'
require 'world'
require 'tilemap'
require 'sounds'

-- utilities
require 'libs/utils/pairsbykeys'
require 'libs/utils/tableshow'
require 'libs/utils/split'
require 'libs/utils/deepcopy'

-- random
--rng = ROT.RNG.LCG:new()
--rng = ROT.RNG.MWC:new()
rng = ROT.RNG.Twister:new()
rng:randomseed()

-- keyboard
love.keyboard.setKeyRepeat(true)
keyboard_input_disabled = false

-- basics
turns = 0
fov = 15    -- de-facto distance of vision
defaultOutsideFOV = 20
initial_health=25
player = {name="you",health=initial_health,max_health=initial_health,weapons={},sounds={},location={x=1,y=1}}
player.sounds.attack=sounds.impact.hit
inventory = {dagger={qty=1,attacks={{verbs={'slice','carve','skewer','poke','impale','disembowl','bleed'},damage={dice_qty=1,dice_sides=3,plus=1}}},name="Needle the dissector"},['edible moss']={qty=5},['dry mushrooms']={qty=30},['door spikes']={qty=10}}
table.insert(player.weapons,inventory.dagger)
equipment = {left_hand='sword'}
beautify=true
simpleAreaShade=false
--beautify=false
characterX=player.location.x
characterY=player.location.y
tilePixelsX=16
tilePixelsY=16
characterSmallness=4
tilemap = {}
visibleTiles = {}
seenTiles = {}
logMessages = {}
centralMessages = {}
modal_dialog = ''
modal_data = {}
npcs_overlay_start_x = 30
npcs_overlay_start_y = 200
npcs_overlay_row_height = 110
npcs_overlay_width = 80
npcs_overlay_height = 90

-- colors
modalSelectedColor = {255,0,0,255}
healthyColor = {255,0,0,150}
unhealthyColor = {85,0,0,120}
footprintColor={50,50,50,100}
mossColor={41,113,13,150}
happyMessageColor={0,255,0}
notifyMessageColor={128,128,128}
failMessageColor={195,50,50}
vegetableMessageColor={50,115,50}
waterMessageColor={50,50,195}
rockColor={0,0,0}
bloodColor={255,0,0,100}
bloodMessageColor={bloodColor[1],bloodColor[2],bloodColor[3],255}
npcsOverlayColor = {40,40,40,255}
groundColor={25,25,25}
waterColor={0,10,95}
treeColor={80,185,50}
puddleColor={0,10,65,155}
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

-- graphics
fade_factor = {}
fade_factor['black'] = 0

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

function love.load()

	-- load font
	print('Loading fonts')
        heavy_2xfont = love.graphics.newFont("fonts/pf_tempesta_five_extended_bold.ttf",16)
        medium_2xfont = love.graphics.newFont("fonts/pf_tempesta_five_bold.ttf",16)
        light_2xfont = love.graphics.newFont("fonts/pf_tempesta_five.ttf",16)
        heavy_font = love.graphics.newFont("fonts/pf_tempesta_five_extended_bold.ttf",8)
        medium_font = love.graphics.newFont("fonts/pf_tempesta_five_bold.ttf",8)
        light_font = love.graphics.newFont("fonts/pf_tempesta_five.ttf",8)
	love.graphics.setFont(light_font)

	-- hide mouse
	print('Hiding mouse')
	love.mouse.setVisible(false)

	-- set up graphics mode
	print('Attempting to switch to fullscreen resolution.')
	love.window.setMode(resolutionPixelsX, resolutionPixelsY, screenModeFlags)
	resolutionPixelsX = love.graphics.getWidth()
	resolutionPixelsY = love.graphics.getHeight()
	print(' - Resolution obtained: ' .. resolutionPixelsX .. ' x ' .. resolutionPixelsY .. ' pixels')

	-- now determine tile resolution
	print('     - Tile size: ' .. tilePixelsX .. ' x ' .. tilePixelsY .. ' pixels')
	resolutionTilesX=math.floor(resolutionPixelsX/tilePixelsX)
	resolutionTilesY=math.floor(resolutionPixelsY/tilePixelsY)
	print('     - Displayable tilemap size: ' .. resolutionTilesX .. ' x ' .. resolutionTilesY .. ' tiles')

	-- record with shack library for shaking
	shack:setDimensions(love.graphics.getDimensions())

	-- generate world
	print('Generating world.')
	generate_world()

	-- load initial world location
	print('Entering world.')
	world_load_area(world_location.z,world_location.x,world_location.y,true)

        -- play downstairs sound
        sound = sounds.stairs.stone.down:play()
        sound:setVolume(1.5)

	-- fade the screen in for 2 seconds
	fade_factor.black=1
        table.insert(tweens,flux.to(fade_factor,2,{black=0}))
	
	-- update visibility
	if fov > 0 then
		update_draw_visibility_new()
		--update_draw_visibility()
	end

	print('--------------------------- OK! Here we go! ---------------------------------')
end

function love.keypressed(key)
	if keyboard_input_disabled then return end
	-- if we are in a modal
	if modal_dialog ~= '' then
		-- escape to exit
		if key == "escape" then modal_dialog = '' end
		-- if standard modal selection has been enabled, allow the user to move it with arrows
		if modal_data.selected ~= nil then
			if key == "down" then
				modal_data.selected = modal_data.selected+1 
				if modal_data.max_selected ~= nil then
					if modal_data.selected > modal_data.max_selected then
						modal_data.selected=modal_data.max_selected
					end
				end
			elseif key == "up" then
				modal_data.selected = modal_data.selected-1
				if modal_data.selected < 1 then
					modal_data.selected = 1
				end
			end
		end
		-- otherwise press the same key to exit
		if modal_dialog == 'help' and key == 'h' then modal_dialog = '' end
		if modal_dialog == 'inventory' and key == 'i' then modal_dialog = '' end
		return
	end
	modal_data = {selected=1}
	-- we are not in a modal
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
        elseif key == "q" and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
		love.event.quit()
	-- '>'
	elseif key == "." and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
		descend()
	-- '<'
	elseif key == "," and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
		ascend()
	elseif key == 'i' then
		modal_dialog = 'inventory'
	elseif key == 'h' then
		modal_dialog = 'help'
        end
	-- redetermine visibility of all squares
	if fov > 0 then
		update_draw_visibility_new()
		--update_draw_visibility()
	end
end

function love.draw()
	shack:apply()
	--local start_time = love.timer.getTime()
	if fov > 0 then
		--draw_tilemap()
		draw_tilemap_visibilitylimited()
	else
		draw_tilemap()			-- rare changes (~4-5ms or so)
	end
        --draw_tilemap_beautification()           -- rare changes (costs ~1ms or so)
	--local draw_tilemap_time = love.timer.getTime()-start_time
	--print( string.format( "Time to draw tilemap: %.3f ms", draw_tilemap_time*1000))

	-- currently these are all redrawn every frame... could optimize this later
	--local start_time = love.timer.getTime()
	if fov > 0 then
		draw_footprints_visibilitylimited()
		draw_groundfeatures_visibilitylimited()
		draw_doors_visibilitylimited()
		draw_stairs_visibilitylimited()
		draw_character()
		draw_poorvisibility_overlay()
		draw_npcs_visibilitylimited()
	else
		draw_footprints()			-- frequent changes
		draw_groundfeatures()			-- occasional changes
		draw_doors()				-- occasional changes
		draw_stairs()				-- never changes
		draw_character()			-- frequent changes
		draw_npcs()				-- frequent changes
	end
	--local draw_dynamics_time = love.timer.getTime()-start_time
	--print( string.format( "Time to draw dynamics: %.3f ms", draw_dynamics_time*1000))

	-- shade if appropriate
	if simpleAreaShade then
		draw_simpleareashade()
	end

	-- highly dynamic, usually no drawing at all
	draw_logmessages()
	draw_popups()

	if fov > 0 then
		-- draw_visibility_overlay()
	end
	draw_player_status_overlay()
	draw_coordinates_overlay()
	--draw_areaname_overlay()	-- dungeon levels are unnamed (re-enable after 2016 ARRP release)
	draw_depth_overlay()		-- dungeon levels are unnamed (re-enable after 2016 ARRP release)
        svglover_draw()
	draw_npcs_overlay()
	
	-- now fade screen if required
	if fade_factor.black ~= 0 then
		draw_fade()
	end

	-- finally, draw central messages
	draw_centralmessages()
end

function love.update(dt)
	shack:update(dt)
	flux.update(dt)
	update_npcs_overlay()
end

function draw_fade()
	local alpha = 255*fade_factor.black
	love.graphics.setColor(0,0,0,alpha)
	love.graphics.rectangle('fill',0,0,resolutionPixelsX,resolutionPixelsY)
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
                        elseif tilemap[x][y] == '=' then
                                love.graphics.setColor(doorColor)
                                love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
				love.graphics.setColor(0,0,0,100)
				for i=1,tilePixelsX,4 do
					love.graphics.line((x-1)*tilePixelsX+i, (y-1)*tilePixelsY+2, (x-1)*tilePixelsX+i+1, (y-1)*tilePixelsY+tilePixelsY-2)
				end
                        elseif tilemap[x][y] == 'T' then
				love.graphics.setColor(groundColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
                                --love.graphics.setColor(treeColor)
				--treerandomsource=ROT.RNG.MWC.new()
				--treerandomsource:randomseed(x*y)
				--greenfactor = treerandomsource:random(70,100)/100
				greenfactor=math.abs(x/y)/3 --rng:random(70,100)/100
				love.graphics.setColor(treeColor[1]*greenfactor,treeColor[2]*1.25*greenfactor,treeColor[3]*greenfactor)
                                love.graphics.rectangle("fill", (x-1)*tilePixelsX+1, (y-1)*tilePixelsY+1, tilePixelsX-2, tilePixelsY-2)
				love.graphics.setColor(groundColor)
				love.graphics.line((x-1)*tilePixelsX, (y-1)*tilePixelsY+tilePixelsY/2, (x-1)*tilePixelsX+tilePixelsX, (y-1)*tilePixelsY+tilePixelsY/2)
				love.graphics.line((x-1)*tilePixelsX+tilePixelsX/2, (y-1)*tilePixelsY, (x-1)*tilePixelsX+tilePixelsX/2, (y-1)*tilePixelsY+tilePixelsY)
				love.graphics.line((x-1)*tilePixelsX, (y-1)*tilePixelsY, (x-1)*tilePixelsX+tilePixelsX, (y-1)*tilePixelsY+tilePixelsY)
				love.graphics.line((x-1)*tilePixelsX+tilePixelsX, (y-1)*tilePixelsY, (x-1)*tilePixelsX, (y-1)*tilePixelsY+tilePixelsY)
                        elseif tilemap[x][y] == 'W' then
				bluefactor=rng:random(70,100)/100
                                love.graphics.setColor(waterColor[1]*bluefactor,waterColor[2]*bluefactor*1.25,waterColor[3]*bluefactor)
                                love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			end
		end
	end
end

function draw_footprints()
	-- draw footprints
	for i,footprint in ipairs(footprints) do
		alpha = 100 - footprint.x*footprint.y % 80
		love.graphics.setColor(footprint.c) -- footprintColor[1],footprintColor[2],footprintColor[3],alpha)
		love.graphics.rectangle('line',(footprint['x']-1)*tilePixelsX+2,(footprint['y']-1)*tilePixelsY+2,3,3)
		love.graphics.rectangle('line',(footprint['x']-1)*tilePixelsX+8,(footprint['y']-1)*tilePixelsY+8,3,3)
	end
end

function draw_footprints_visibilitylimited()
	-- draw footprints
        for i=1,#visibleTiles,1 do
                local tile = visibleTiles[i]
                x=tile.x
                y=tile.y
		for j,footprint in ipairs(footprints) do
			-- semi-randomize alpha levels
			alpha = 100 - footprint.x*footprint.y % 80
			love.graphics.setColor(footprint.c[1], footprint.c[2], footprint.c[3], alpha)
			if footprint['x']==x and footprint['y']==y then
				love.graphics.rectangle('line',(footprint['x']-1)*tilePixelsX+2,(footprint['y']-1)*tilePixelsY+2,3,3)
				love.graphics.rectangle('line',(footprint['x']-1)*tilePixelsX+8,(footprint['y']-1)*tilePixelsY+8,3,3)
			end
		end
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
			love.graphics.setColor(puddleColor)
			love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2, (feature['y']-1)*tilePixelsY+tilePixelsY/2, (tilePixelsX/2)-5)
			current_footprint_color = deepcopy(puddleColor)
		elseif feature['type'] == 'blood' then
			love.graphics.setColor(bloodColor)
			love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2, (feature['y']-1)*tilePixelsY+tilePixelsY/2, (tilePixelsX/2)-5)
			love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2-3, (feature['y']-1)*tilePixelsY+tilePixelsY/2-5+(feature['x']*feature['y']%10), (tilePixelsX/2)-5)
			current_footprint_color = deepcopy(bloodColor)
		elseif feature['type'] == 'stone' then
			love.graphics.setColor(rockColor,120)
			love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2+3, (feature['y']-1)*tilePixelsY+tilePixelsY/2+6, (tilePixelsX/4)-3)
		elseif feature['type'] == 'moss' then
			love.graphics.setColor(mossColor)
			local bx=(feature['x']-1)*tilePixelsX
			local by=(feature['y']-1)*tilePixelsY
			love.graphics.points({bx+3,by+3,bx+7,by+2,bx+6,by+4,bx+9,by+5})
		end
	end
end

function draw_groundfeatures_visibilitylimited()
	-- draw groundfeatures
        for i=1,#visibleTiles,1 do
                local tile = visibleTiles[i]
                x=tile.x
                y=tile.y
		for i,feature in ipairs(groundfeatures) do
			if feature['x'] == x and feature['y'] == y then
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
					current_footprint_color = deepcopy(puddleColor)
				elseif feature['type'] == 'blood' then
					love.graphics.setColor(bloodColor)
					love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2, (feature['y']-1)*tilePixelsY+tilePixelsY/2, (tilePixelsX/2)-5)
					love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2-3, (feature['y']-1)*tilePixelsY+tilePixelsY/2-5+(feature['x']*feature['y']%10), (tilePixelsX/2)-5)
					current_footprint_color = deepcopy(bloodColor)
				elseif feature['type'] == 'stone' then
					love.graphics.setColor(rockColor,120)
					love.graphics.circle('fill',(feature['x']-1)*tilePixelsX+tilePixelsX/2+3, (feature['y']-1)*tilePixelsY+tilePixelsY/2+6, (tilePixelsX/4)-3)
				elseif feature['type'] == 'moss' then
					love.graphics.setColor(mossColor)
					local bx=(feature['x']-1)*tilePixelsX
					local by=(feature['y']-1)*tilePixelsY
					love.graphics.points({bx+3,by+3,bx+7,by+2,bx+6,by+4,bx+9,by+5})
				end
			end
		end
	end
end

function draw_stairs_visibilitylimited()
        -- draw doors (on top of the map tilemap)
        for i,p in pairs(seenTiles) do
                local tile = split(i,',')
                x=tile[1]+0
                y=tile[2]+0
		if tilemap[x] ~= nil and tilemap[x][y] ~= nil and (tilemap[x][y] == '>' or tilemap[x][y] == '<') then
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

function draw_poorvisibility_overlay()
	-- draw shadedness over poorly visible tiles
        for i=1,#visibleTiles,1 do
                local tile = visibleTiles[i]
                x=tile.x
                y=tile.y
		v=tile.v
		local alpha
		if v ~= 1 then
			alpha = 50*v
			love.graphics.setColor(0,0,0,alpha)
			--print("@" .. x .. "/" .. y .. ", visibility = " .. v)
			love.graphics.rectangle("fill", (x-1)*tilePixelsX,(y-1)*tilePixelsY,tilePixelsX,tilePixelsY)
			love.graphics.setColor(0,0,0,100)
			love.graphics.rectangle("fill", (x-1)*tilePixelsX,(y-1)*tilePixelsY,tilePixelsX,tilePixelsY)
		end
	end
end

function draw_doors_visibilitylimited()
	-- draw doors (on top of the map tilemap)
        for i,p in pairs(seenTiles) do
                local tile = split(i,',')
                x=tile[1]+0
                y=tile[2]+0
		if tilemap[x] ~= nil and tilemap[x][y] ~= nil then
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
		--print("name: " .. npcs[i]['name'] .. " (" .. npcs[i]['type'] .. ")")
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

function draw_npcs_visibilitylimited()
	-- draw npcs
	for i=1,#npcs,1 do
		local l=npcs[i]['location']

		-- DEBUG/TEST AID: cheat and display a dot on each unseen NPC
		--[[
		love.graphics.setColor(255,255,255,255)
		love.graphics.rectangle('fill',(l['x']-1)*tilePixelsX+(characterSmallness+3),(l['y']-1)*tilePixelsY+(characterSmallness+3),tilePixelsX-(characterSmallness+3)*2,tilePixelsY-(characterSmallness+3)*2)
		--]]

		-- check if it's in the list of visible tiles
		local found=false
		for j=1,#visibleTiles,1 do
                	local tile = visibleTiles[j]
                	if tile.x == l['x'] and tile.y == l['y'] then
				found = true
			end
		end
		-- yes, it's visible
		if found==true then
			-- first, 'wake up' the NPC and allow it to notice the player, if appropriate
			if npcs[i].seen_player == nil or (npcs[i].seen_player ~= nil and npcs[i].seen_player ~= true) then
				-- 'wake up'
				npcs[i].seen_player = true
				-- play a sound
                                if npcs[i].sounds.target ~= nil then
                                	npcs[i].sounds.target:play()
                                	npcs[i].sounds.target:setVolume(2)
                                elseif npcs[i].sounds.attack ~= nil then
                                	npcs[i].sounds.attack:play()
                                	npcs[i].sounds.attack:setVolume(2)
                                end
			end
			-- now draw it
			if npcs[i]['color'] ~= nil then
				love.graphics.setColor(npcs[i]['color'])
			else
				love.graphics.setColor(defaultNpcColor)
			end
			-- first calculate the top-left and top-right of the tile
			local base_x = (l['x']-1)*tilePixelsX		-- we use -1 because the first row is 1, not 0
			local base_y = (l['y']-1)*tilePixelsY
			if l.tween ~= nil and l.tween.x ~= nil then
				base_x = base_x + l.tween.x		-- if the NPC is currently moving between cells
			end
			if l.tween ~= nil and l.tween.y ~= nil then
				base_y = base_y + l.tween.y
			end
			love.graphics.rectangle('fill',base_x+characterSmallness,base_y+characterSmallness,tilePixelsX-characterSmallness*2,tilePixelsY-characterSmallness*2)
			if npcs[i]['tail'] ~= nil then
				love.graphics.rectangle('fill',base_x+characterSmallness,base_y+tilePixelsY-characterSmallness-2,-2,2)
				love.graphics.rectangle('fill',base_y+characterSmallness-2,base_y+tilePixelsY-characterSmallness-4,1,2)
				love.graphics.setColor(0,0,0,255)
				love.graphics.points({
					(base_x+characterSmallness+2),
					(base_y+characterSmallness+2),
					(base_x+tilePixelsX-characterSmallness-3),
					(base_y+characterSmallness+2),
						    })
			end
		        love.graphics.setColor(npcLabelShadowColor)
			-- NB. The following line is useful for debugging UTF-8 issues which Lua has in buckets
			--print("name: " .. npcs[i]['name'] .. " (" .. npcs[i]['type'] .. ")")
			love.graphics.setFont(light_font)
       		         love.graphics.print(npcs[i]['name'],base_x+math.floor(tilePixelsX/2)+7, base_y+2)
			if npcs[i]['color'] ~= nil then
				love.graphics.setColor(npcs[i]['color'])
			else
				love.graphics.setColor(defaultNpcLabelColor)
			end
			love.graphics.setFont(light_font)
        	        love.graphics.print(npcs[i]['name'],base_x+math.floor(tilePixelsX/2)+6, base_y+1)
		end
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
				love.graphics.setFont(light_2xfont)
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

function draw_centralmessages()
	-- draw central messages
	local a = 0
	if #centralMessages > 0 then
		for i,message in ipairs(centralMessages) do
			local difference = os.clock() - message['time']
			a = 535 - (255*string.format("%.2f",difference))
			if a > 0 then
				local myColor = r,g,b,a
				love.graphics.setColor(a,a,a,a)
				love.graphics.setFont(heavy_2xfont)
				love.graphics.printf(message['message'],0,math.floor(resolutionPixelsY/2)-20,resolutionPixelsX,"center")
			else
				message['delete'] = true
			end
		end
		for i,message in ipairs(centralMessages) do
			if message['delete'] == true then
				table.remove(centralMessages,i)
			end
		end
	end
end

function draw_popups()
	-- draw popups
	local border=100
	local pad=10
	-- help
	if modal_dialog == 'help' then
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
		love.graphics.setFont(heavy_2xfont)
		love.graphics.printf("Help",0,border*1.3,resolutionPixelsX,"center")
		-- ideas: could combine many potential keys in to a single overlay. simplicity of interface is good to aim for.
		--        (in particular, probably we should kill 'e' for equipment)... for example...
		--
		--   tab: shows equipment         \
		--   tab: quest log                |
		--   tab: permanent message log     > could potentially show all of these on one overlay?
		--   tab: player statistics        |
		--   tab: player conditions       /
		--     m: world map               
		keys = {
			c='Close doors',
			h='Help Menu',
			i='Inventory / Equipment Menu',
			o='Open doors',
			s='Spike doors shut',
			arrows='Movement',
			['shift+Q']='Quit',
			['<']='Up stairs / ladder',
			['>']='Down stairs / ladder',
			['*']='Throw or fire (missile weapon / object)'
		       }
		local i=0
		for key,description in pairsByKeys(keys) do
			output = {}
			table.insert(output, popupBrightTextColor)
			table.insert(output, key)
			local width=180
			love.graphics.setFont(light_2xfont)
			love.graphics.printf(output, border+pad*4, border*1.3+pad+pad+i*20-1, pad*4+resolutionPixelsX/2*0.1-pad, "right")
			output = {}
			table.insert(output, popupNormalTextColor)
			table.insert(output, description)
			love.graphics.setFont(light_2xfont)
			love.graphics.print(output,	math.floor(border+pad*5+resolutionPixelsX/2*0.1+pad*3),	border*1.3+pad+pad+i*20)
			i=i+1
		end
	-- inventory
	elseif modal_dialog == 'inventory' then
		-- status
		if modal_data['selected'] == nil then
			modal_data['selected'] = 1
		end
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
		love.graphics.setFont(heavy_2xfont)
		love.graphics.printf("Inventory",0,border*1.3,resolutionPixelsX,"center")
		-- draw inventory contents
		local i=1
		for index,item in pairs(inventory) do
			local selected = false
			if i == modal_data['selected'] then
				selected = modalSelectedColor
			end
			love.graphics.setColor(selected or popupBrightTextColor)
			love.graphics.setFont(light_2xfont)
			love.graphics.printf(item.qty, border+pad, border*1.3+pad+pad+i*20-1, pad+resolutionPixelsX/2*0.1-pad, "right")
			love.graphics.setColor(popupDarkTextColor)
			love.graphics.setFont(light_2xfont)
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
			if item['attacks'] ~= nil then
				-- TODO: fix this for multi-attack weapons
				if item['attacks'][1]['damage']['dice_qty'] ~= nil and
				   item['attacks'][1]['damage']['dice_sides'] ~= nil then
					table.insert(item_description, popupDarkTextColor)
					table.insert(item_description, ' <')
					table.insert(item_description, popupBrightTextColor)
					table.insert(item_description, item['attacks'][1]['damage']['dice_qty'] .. 'd' .. item['attacks'][1]['damage']['dice_sides'])
					if item['attacks'][1]['damage']['plus'] ~= nil then
						table.insert(item_description, popupNormalTextColor)
						table.insert(item_description, '+')
						table.insert(item_description, popupBrightTextColor)
						table.insert(item_description, item['attacks'][1]['damage']['plus'])
					end
					table.insert(item_description, popupDarkTextColor)
					table.insert(item_description, '>')
				end
			end
			love.graphics.setFont(light_2xfont)
			love.graphics.print(item_description,	math.floor(border+pad+resolutionPixelsX/2*0.1+pad*3),	border*1.3+pad+pad+i*20)
			i = i + 1
		end
		if i==0 then
			love.graphics.setFont(medium_2xfont)
			love.graphics.printf("You have no items.",0,math.floor(resolutionPixelsY/2)-10,resolutionPixelsX,"center")
		end
		if modal_data['max_selected'] == nil then
			modal_data['max_selected'] = i-1 
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
	-- if the space is off the map...
	if newX > resolutionTilesX or newY > resolutionTilesY or newX < 1 or newY < 1 then
		-- trying to change areas... handle this here.
		-- NOTE that we should pre-generate the subsequent area if not already generated
		--      so that we can test whether the diagonal or other movement is actually
		--	allowed, and/or fudge it, ie. if blocked cross with +1 or -1 on some axis
		--  first, diagonals
		if newX > resolutionTilesX and newY > resolutionTilesY then
			-- down right
			world_location.y = world_location.y + 1
			world_location.x = world_location.x + 1
			characterX=1
			characterY=1
		elseif newX > resolutionTilesX and newY < 1 then
			-- up right
			world_location.y = world_location.y - 1
			world_location.x = world_location.x + 1
			characterX=1
			characterY=resolutionTilesY
		elseif newX < 1 and newY > resolutionTilesY then
			-- down left
			world_location.y = world_location.y + 1
			world_location.x = world_location.x - 1
			characterX=resolutionTilesX
			characterY=1
		elseif newX < 1 and newY < 1 then
			-- up left
			world_location.y = world_location.y - 1
			world_location.x = world_location.x - 1
			characterX=resolutionTilesX
			characterY=resolutionTilesY
		--  next, straight
		elseif newX > resolutionTilesX then
			-- right
			world_location.x = world_location.x + 1
			characterX=1
		elseif newY > resolutionTilesY then
			-- down
			world_location.y = world_location.y + 1
			characterY=1
		elseif newX < 1 then
			-- left
			world_location.x = world_location.x - 1
			characterX=resolutionTilesX
		elseif newY < 1 then
			-- up
			world_location.y = world_location.y - 1
			characterY=resolutionTilesY
		end
		world_load_area(world_location.z,world_location.x,world_location.y)
		return true
	end
	-- if the map space is potentially standable (1 = floor, 3 = open door, '<' = down stairs, '>' = up stairs, '=' = left-right wooden bridge)
	if tilemap[newX][newY] == 1 or tilemap[newX][newY] == 2 or tilemap[newX][newY] == 3 or tilemap[newX][newY] == '<' or tilemap[newX][newY] == '>' or tilemap[newX][newY] == '=' then
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
				footfallNoise(groundtype(newX,newY))
				if current_footprint_color == nil then current_footprint_color = footprintColor end
				table.insert(footprints,{x=characterX,y=characterY,r=rng:random(-90,90),c=current_footprint_color})
				if #footprints > max_footprints then
					table.remove(footprints,1)
				end
				-- if we are not current leaving footprints in the default color
				if current_footprint_color ~= footprintColor then
					local min_shift = 20
					-- slowly shift the color back toward the normal, on a per-element basis
					rshift = math.min(min_shift,((current_footprint_color[1] + footprintColor[1])/2))
					gshift = math.min(min_shift,((current_footprint_color[2] + footprintColor[2])/2))
					bshift = math.min(min_shift,((current_footprint_color[3] + footprintColor[3])/2))
					-- shift red
					if current_footprint_color[1] < footprintColor[1] then
						current_footprint_color[1] = current_footprint_color[1] + rshift
					elseif current_footprint_color[1] > footprintColor[1] then
						current_footprint_color[1] = current_footprint_color[1] - rshift
						if current_footprint_color[1] < footprintColor[1] then
							current_footprint_color[1] = footprintColor[1]
						end
					end
					-- shift green
					if current_footprint_color[2] < footprintColor[2] then
						current_footprint_color[2] = current_footprint_color[2] + rshift
					elseif current_footprint_color[2] > footprintColor[2] then
						current_footprint_color[2] = current_footprint_color[2] - rshift
						if current_footprint_color[2] < footprintColor[2] then
							current_footprint_color[2] = footprintColor[2]
						end
					end
					-- shift blue
					if current_footprint_color[3] < footprintColor[3] then
						current_footprint_color[3] = current_footprint_color[3] + rshift
					elseif current_footprint_color[3] > footprintColor[3] then
						current_footprint_color[3] = current_footprint_color[3] - rshift
						if current_footprint_color[3] < footprintColor[3] then
							current_footprint_color[3] = footprintColor[3]
						end
					end
				end
				characterX = newX
				characterY = newY
				autoPickup()
				endTurn()
			end
		else
			shack:setShake(20)
			shack:setRotation(.2)
			shack:zoom(1.25)
		end
	else
		shack:setShake(20)
		shack:setRotation(.1)
		shack:zoom(1.05)
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

function randomStandingLocationWithoutNPCsOrPlayer(thetilemap)
	local failed = 1
	local x,y = 0
	while not(failed == 0) do
		failed = 1
		x,y = randomStandingLocation(thetilemap)
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
			-- search character coordinates
			if characterX == x and characterY == y then
				failed = failed + 1
			end
			failed = failed - 1
		end
	end
	return x, y
end

function randomStandingLocation(thetilemap,size)
	size = size or 1     -- ie. 1 is default
	local found_x,found_y = 0
	local placed=false
	while placed == false do
		x = rng:random(1,resolutionTilesX-1-size)
		y = rng:random(1,resolutionTilesY-1-size)
		if size == 1 then
			if thetilemap[x][y] == 1 or thetilemap[x][y] == '1' then
				found_x = x
				found_y = y
				placed = true
			end
		else
			-- check the whole square
			placed = true
			for tx=1,size,1 do
				for ty=1,size,1 do
					if thetilemap[x+tx][y+ty] ~= 1 then
						placed = false
					end
				end
			end
		end
	end
	return x,y
end

function centralMessage(color,string)
	table.insert(centralMessages,{time=os.clock(),message={color,string}})
end

function logMessage(color,string)
	table.insert(logMessages,{time=os.clock(),message={color,string}})
end

function footfallNoise(groundtype)
	local groundtype = groundtype or 'gravel'
	instance = sounds.footfalls[groundtype]:play()
	if groundtype == 'bridge' or groundtype == 'water' then
		instance:setVolume(0.35)
	else
		instance:setVolume(.05)
	end
	instance:setPitch(.5 + rng:random(0,1) * .5)
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
			elseif gf.type == 'blood' then
				logMessage(bloodMessageColor,'You tread in a pool of blood.')
				footfallNoise('water')
			elseif gf.type == 'puddle' then
				logMessage(waterMessageColor,'You tread in a puddle.')
				footfallNoise('water')
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
		instance:setVolume(0.8)
		logMessage(notifyMessageColor,"You opened the door.")
		tilemap[x][y] = 3
		endTurn()
	end
end

function closedoor(x,y)
	if tilemap[x][y] == 3 then
		-- first, check there are no NPCs standing in the way
		local failed = false
        	for i,npc in ipairs(npcs) do
			local l=npc.location
			if l.x == x and l.y == y then
				failed=true
				break
			end
		end
		if not failed then
			local instance = sounds['door_close']:play()
			instance:setVolume(0.8)
			logMessage(notifyMessageColor,"You closed the door.")
			tilemap[x][y] = 2
			endTurn()
		end
	end
end

function inventory_add(thing)
	if thing == 'vegetable matter' then
		local instance = sounds['pickups']['generic']:play()
	elseif thing == 'pebble' then
		local instance = sounds['pickups']['rock']:play()
	end
	instance:setVolume(0.25)
	if inventory[thing] == nil then
		inventory[thing] = {qty=0}
	end
	inventory[thing]['qty'] = inventory[thing]['qty'] + 1
end

function endTurn()
	-- allow NPCs to move
	for i,npc in ipairs(npcs) do
		-- each one has a 0.5% chance of making a noise
		if npc.vocal ~= nil and npc.vocal==true and math.floor(rng:random(1,200)) == 1 then
			-- as an improvement on just playing the noise, we should vary the volume versus the 
			-- (simple, crow flies) distance to the NPC from the player.
			--
			--  this attempt runs and does have some effect, but i'm not sure how correct it is 
			--  or whether our samples' volume normalization is adequate to make it work correctly.
			--
			--  the pythagorean distance formula is: SQRT( (x2-x1)^2 + (y2-y1)^2 )
			--
			--  in lua this seems to be:
			--   math.sqrt(
			--    math.abs(characterX-npc.location.x)^2
			--      +
			--    math.abs(characterY-npc.location.y)^2
			--   )
			--
			-- let's say we get 0.01 volume @ max distance, and 0.5ish volume @ close distance
			minimum_volume=0.01
			maximum_volume=0.2
 			-- if we define max distance as the distance between two corners of the map, then...
			largest_possible_distance = math.sqrt(math.abs(resolutionTilesX,1)^2 + math.abs(resolutionTilesY-1)^2)
			-- and our sound's distance is...
			sound_distance = math.sqrt(math.abs(characterX-npc.location.x)^2 + math.abs(characterY-npc.location.y)^2)
			-- now we determine the ratio of maximum (assume linear dropoff over distance)
			volume_ratio = sound_distance/largest_possible_distance
			-- finally we calculate our desired volume
			volume = minimum_volume + volume_ratio*(maximum_volume-minimum_volume)
        		npc.sounds.attack:play():setVolume(volume)
		end

		-- if they have seen the player and are hostile
		if npc.seen_player == true and npc.hostile==true then
			--[[
			-- if they have line of sight to the player...
			local visible = false
			for i=1,#visibleTiles,1 do
                		local tile = visibleTiles[i]
				if npc.location.x == tile.x and npc.location.y == tile.y then
					visible=true
					break
				end
			end
			--]]
			if true then	-- disabled logic here ;)
				-- move toward or attack the player
				x_distance = characterX-npc.location.x
				y_distance = characterY-npc.location.y
				-- if the distance is no more than 1 in either direction, they are adjacent...
				if math.abs(x_distance) <= 1 and math.abs(y_distance) <= 1 then
					-- attack the player!
					npc_attack(npc)


				else
					-- move toward the player using a dijkstra map for routing
					--  note: right now we just use one callback that says no monster can open doors.
					player_dijkstra_map = ROT.DijkstraMap:new(characterX, characterY, #tilemap, #tilemap[1], tile_is_passable_assuming_open_doors_no_npcs)
					player_dijkstra_map:compute()
					direction_to_move_x,direction_to_move_y = player_dijkstra_map:dirTowardsGoal(npc.location.x,npc.location.y)
					if direction_to_move_x == nil then direction_to_move_x = 0 end
					if direction_to_move_y == nil then direction_to_move_y = 0 end
					local new_x = npc.location.x + direction_to_move_x
					local new_y = npc.location.y + direction_to_move_y
					-- a few checks
					local occupied = false
					-- check the space is not a closed door
					if tilemap[new_x][new_y] == 2 then
						occupied = true
					else
						-- check no other NPCs have occupied the space
						for _,other_npc in pairs(npcs) do
							if other_npc.location.x == new_x and other_npc.location.y == new_y then
								occupied = true
								break
							end
						end
					end
					-- if the target location was occupied, recalculate the entire dijkstra map for this monster,
					-- who we will denote a 'special snowflake'. this should not fail, so we do no success checks.
					-- note that a common use of this is a monster who has been routed assuming an open door, but reaches
					-- it closed and then has to think otherwise. this has the effect of at least bunching monsters at
					-- the door they cannot pass where they last saw the player, if the player closed it.
					if occupied == true then
						local special_snowflake_dijkstra_map = ROT.DijkstraMap:new(characterX, characterY, #tilemap, #tilemap[1], tile_is_passable_no_npcs)
						special_snowflake_dijkstra_map:compute()
						direction_to_move_x,direction_to_move_y = player_dijkstra_map:dirTowardsGoal(npc.location.x,npc.location.y)
						if direction_to_move_x == nil then direction_to_move_x = 0 end
						if direction_to_move_y == nil then direction_to_move_y = 0 end
                                        	new_x = npc.location.x + direction_to_move_x
                                        	new_y = npc.location.y + direction_to_move_y
					end
					-- check we have movement scheduled
					if (direction_to_move_x ~= 0 or direction_to_move_y ~= 0) and tile_is_passable_no_npcs(new_x,new_y) then
						-- move
						npc.location.x = new_x
						npc.location.y = new_y
						-- play a sound
						if npc.sounds.move ~= nil then
							npc.sounds.move:play()
						        npc.sounds.move:setVolume(2)
						elseif npc.sounds.distance ~= nil then
							if rng:random(1,10) == 1 then
								npc.sounds.distance:play()
						        	npc.sounds.distance:setVolume(2)
							end
						end
					else
						-- npc is stuck, express anger
						--logMessage(notifyMessageColor,npc.name .. " is stuck and angry!")
						if npc.sounds.attack ~= nil then
							-- make a noise 10% of the time
							-- FIXTHIS: audio levels should adjust vs. distance
							if rng:random(1,10) == 1 then
                                                		npc.sounds.attack:play()
                                                		npc.sounds.attack:setVolume(0.5)
							end
						end
					end
				end
			end
	
		-- if they are set to move randomly, then do so with a 10% chance
		elseif npc.move=='random' and math.floor(rng:random(0,10)) == 9 then
			-- attempt to move: pick a direction, then try all directions clockwise until success
			local direction = math.ceil(rng:random(0,9))
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
				if tilemap[tryx] ~= nil and tilemap[tryx][tryy] ~= nil and tilemap[tryx][tryy] == 1 then
					-- double-check there are no NPCs already there
					local blocked=false
					-- loop here
        				for n,npc in ipairs(npcs) do
						if npc.location.x == tryx and npc.location.y == tryy then
							blocked=true	
						end
					end
					if blocked == false then
						-- actually move the NPC
						l.x=tryx
						l.y=tryy
						success=true
					end
				end
				attempts = attempts + 1
			end
		end
	end
	turns = turns + 1
	if turns % 10 == 0 then
		player.health = player.health + 1
		if player.health > player.max_health then player.health = player.max_health end
	end
end

function descend()
	if tilemap[characterX][characterY] == ">" then
		logMessage(notifyMessageColor,'Descending...')
		sound = sounds.stairs.stone.down:play()
                sound:setVolume(0.9)
		keyboard_input_disabled = true
		table.insert(tweens,flux.to(fade_factor,2,{black=1}):oncomplete(function() 
				world_load_area(world_location.z-1,world_location.x,world_location.y)
				table.insert(tweens,flux.to(fade_factor,1,{black=0}))
				keyboard_input_disabled = false
				end))
	else
		logMessage(failMessageColor,'There is no way down here!')
	end
end

function ascend()
	if tilemap[characterX][characterY] == "<" then
		logMessage(notifyMessageColor,'Ascending...')
		sound = sounds.stairs.stone.up:play()
                sound:setVolume(0.9)
		keyboard_input_disabled = true
		table.insert(tweens,flux.to(fade_factor,2,{black=1}):oncomplete(function() 
				world_load_area(world_location.z+1,world_location.x,world_location.y)
				table.insert(tweens,flux.to(fade_factor,1,{black=0}))
				keyboard_input_disabled = false
				end))
	else
		logMessage(failMessageColor,'There is no way up here!')
	end
end

-- have the player attack an NPC
function attack_npc(i)
	attack(npcs[i],player)
	endTurn()
end

-- calculate the set of visible tilemap squares
function update_draw_visibility()
	visibleTiles={}
	-- our algorithm is as follows:
	--  starting at the player's own location, spiral outward in a clockwise direction.
	--   - if a given tile blocks vision, mark its adjacent blocks as not visible (stop searching)
	local directions = {}
	-- note that 'next' can be determined by a modulo calculation instead... slower though
	directions[1] = {offset={-1,-1}, next={8,1,2}}
	directions[2] = {offset={0,-1},  next={1,2,3}}
	directions[3] = {offset={1,-1},  next={2,3,4}}
	directions[4] = {offset={1,0},   next={3,4,5}}
	directions[5] = {offset={1,1},   next={4,5,6}}
	directions[6] = {offset={0,1},   next={5,6,7}}
	directions[7] = {offset={-1,1},  next={6,7,8}}
	directions[8] = {offset={-1,0},  next={7,8,1}}
	-- we begin at the character's current location, and spiral out from there
	local x = characterX
	local y = characterY
	local direction = {1,2,3,4,5,6,7,8}
	-- we store branches for future lookup here
	local options={}
	local options_calculated={}
	-- we continue exploring until we have exhausted all options
	local done=false
	local last=''
	print("==============================================")
	while done==false do
		-- if we are on ground or an open door
		print(x .. "/" .. y .. ': ' .. table.concat(direction,','))
		if tilemap[x][y] == 1 or tilemap[x][y] == 3 then
			-- this tile is visible
			table.insert(visibleTiles,{['x']=x,['y']=y,['last']=#direction})
			-- use direction to inform subsequent options
			for crap,dir in pairs(direction) do
				local cx = 0
				local cy = 0
				-- calculate the next tile location
				cx,cy = update_draw_visibility_helper(x,y,directions[dir]['offset'])
				-- hang the next directions and last direction on that tile location option
				local newoption = {}
				local c = {cx, cy}
				if #direction == 3 then
					newoption = {coordinates=c,next={dir},last=direction}
				else
					newoption = {coordinates=c,next=directions[dir]['next'],last=direction}
				end
				-- insert only if the tile hasnt already been staged
				existing_index = 0
				max = #options
				for i=1, max, 1 do
					if options[i]['coordinates'][1] == cx and options[i]['coordinates'][2] == cy then
						existing_index = i+0
					end
				end
				if existing_index == 0 then
					table.insert(options,newoption)
					for i=1,#direction,1 do
						-- record each cell + direction (x/y/direction) combination as pre-scheduled
						local option_key = cx .. ',' .. cy .. ',' .. direction[i]
						options_calculated[option_key] = true
					end
				else
					for i,d in pairs(newoption.next) do
						local option_key = cx .. ',' .. cy .. ',' .. d
						if options_calculated[option_key] ~= nil then
							-- check the existing entry for the direction
							local found_it = false
							for _,v in pairs(options[existing_index]['next']) do
							  --print("v = " .. v)
							  if v == d then
							    found_it = true
							    break
							  end
							end
							-- if it wasn't found, insert it
							if found_it == false then
								print("added direction '" .. d .. "' to existing index @ " .. cx .. "/" .. cy)
								table.insert(options[existing_index]['next'],d)
							end
						end
					end
				end
			end
			-- debug summary
			--[[
			local output = "@" .. x .. "/" .. y .. " directions("
			for crap,dir in pairs(direction) do
				output = output .. dir .. " "
			end
			output = output .. ")"
			print(output)
			--]]
		end
		-- now we pick one of the existing options in the list, and allow the loop to repeat.
		-- if there are no options in the list, we are done
		if #options ~= 0 then
			if options[1] ~= nil and options[1]['coordinates'] ~= nil then
				local tmpc=options[1]['coordinates']
				x = tmpc[1]
				y = tmpc[2]
				--[[
				if x ~= nil then
					print(" x = " .. x)
				end
				if y ~= nil then
					print(" y = " .. y)
				end
				--]]
				direction = options[1]['next']
				last = options[1]['last']
			end
			table.remove(options,1)
		end
		if #options == 0 then
			done=true
		end
	end
end

-- compute relative coordinate
function update_draw_visibility_helper(x,y,offset)
	local offset_x = offset[1]
	local offset_y = offset[2]
	local newx = 0
	local newy = 0
	local newx = x + offset_x
	local newy = y + offset_y
	return newx,newy
end

function draw_visibility_overlay()
	local coordinate
	local x = 0
	local y = 0
	for i=1,#visibleTiles,1 do
		local tile = visibleTiles[i]
		x=tile.x
		y=tile.y
		love.graphics.setColor(255,255,0,30)
		love.graphics.rectangle("line",(x-1)*tilePixelsX,(y-1)*tilePixelsY,tilePixelsX,tilePixelsY)
		love.graphics.setFont(heavy_font)
		love.graphics.print(tile.last,(x-1)*tilePixelsX+tilePixelsX/2*0.7,(y-1)*tilePixelsY+1)
	end
end

function draw_areaname_overlay()
		local name = world[world_location.z][world_location.x][world_location.y].name
		local prefix = nil
		if world[world_location.z][world_location.x][world_location.y].prefix ~= nil then
			prefix = world[world_location.z][world_location.x][world_location.y].prefix
		end
		love.graphics.setColor(255,255,255)
		love.graphics.setFont(heavy_2xfont)
		if name ~= nil then
			love.graphics.print(name,math.floor(resolutionTilesX/2)*tilePixelsX,tilePixelsY)
		end
		if prefix ~= nil then
			love.graphics.setFont(light_2xfont)
			love.graphics.printf(prefix,math.floor(resolutionTilesX/2-10)*tilePixelsX-tilePixelsX/2,tilePixelsY,tilePixelsX*10,'right')
		end
end

function draw_player_status_overlay()
		draw_health_bar(resolutionPixelsX*0.3,2,resolutionPixelsX*0.05,tilePixelsY,player.health,player.max_health)
end

function draw_health_bar(start_x,start_y,width,height,current_value,max_value)
		percentage = current_value/max_value
		love.graphics.setColor(unhealthyColor)
		love.graphics.rectangle('fill',start_x,start_y,width,height)
		love.graphics.setColor(healthyColor)
		love.graphics.rectangle('fill',start_x,start_y,width*percentage,height)
		percentage = math.floor(percentage * 100) .. '%'
		love.graphics.setColor(0,0,0,100)
		love.graphics.setFont(light_2xfont)
		love.graphics.printf(percentage,start_x+5,start_y-4,width,'center')
		love.graphics.setColor(255,255,255)
		love.graphics.setFont(light_2xfont)
		love.graphics.printf(percentage,start_x+4,start_y-5,width,'center')
end

function draw_coordinates_overlay()
		love.graphics.setColor(105,105,105)
		love.graphics.setFont(heavy_2xfont)
		love.graphics.print(characterX .. '/' .. characterY .. ' @ ' .. world_location.z .. '/' .. world_location.x .. '/' .. world_location.y .. ' (' .. love.timer.getFPS() .. 'fps)',(resolutionTilesX-20)*tilePixelsX,-2)
end

function draw_npcs_overlay()
	-- the SVGs have already been drawn, so now we just add text and health bars
        --  - handle multiple npcs
        local offset = 0
        -- first we must determine visibility
        for i=1,#npcs,1 do
                local l=npcs[i]['location']

                -- check if it's in the list of visible tiles
                local found=false
                for j=1,#visibleTiles,1 do
                        local tile = visibleTiles[j]
                        if tile.x == l['x'] and tile.y == l['y'] then
                                found = true
                        end
                end
                -- yes, it's visible
                if found==true then
			x = npcs_overlay_start_x
			y = npcs_overlay_start_y+(offset*npcs_overlay_row_height)
			w = npcs_overlay_width
			h = npcs_overlay_height
			draw_health_bar(x,y+h-tilePixelsY,w,tilePixelsY,npcs[i].health,npcs[i].max_health)
			offset = offset + 1
		end
	end
end

function update_npcs_overlay()
	-- reset
	svglover_onscreen_svgs = {}
	-- handle multiple npcs
	local offset = 0
	-- first we must determine visibility
        for i=1,#npcs,1 do
                local l=npcs[i]['location']

                -- check if it's in the list of visible tiles
                local found=false
                for j=1,#visibleTiles,1 do
                        local tile = visibleTiles[j]
                        if tile.x == l['x'] and tile.y == l['y'] then
                                found = true
                        end
                end
                -- yes, it's visible
                if found==true then
			if npcs[i]['image'] ~= nil then
				-- we have an image to display
				svglover_display(npcs[i]['image'],npcs_overlay_start_x,npcs_overlay_start_y+(offset*npcs_overlay_row_height),npcs_overlay_width,npcs_overlay_height,true,npcsOverlayColor)
				offset = offset + 1
			end
		end
	end
end

function draw_depth_overlay()
		if world_location.z < 0 then
			love.graphics.setColor(155,155,155)
			love.graphics.setFont(light_2xfont)
			love.graphics.printf('Depth: ', math.floor(resolutionTilesX/2-10)*tilePixelsX-tilePixelsX/2,-2,tilePixelsX*10,'right')
			love.graphics.setFont(light_2xfont)
                	love.graphics.print((world_location.z*-1*20) .. ' meters',math.floor(resolutionTilesX/2)*tilePixelsX,-2)
		else
			draw_areaname_overlay()
		end
end

function draw_tilemap_visibilitylimited()
	-- draw tilemap
	-- first, a sanity check
	if #tilemap < 10 then
		print("draw_tilemap_visibilitylimited() called, but tilemap is under 10 columns wide!")
		print(" (Hint: Did you forget to initialize the tilemap?)")
		os.exit()
	end
	for i,p in pairs(seenTiles) do
		local tile = split(i,',')
		x=tile[1]+0
		y=tile[2]+0
		if tilemap[x] ~= nil and tilemap[x][y] ~= nil then
			-- 1 = floor, 2 = closed door, 3 = open door, '<' = upward stairs, '>' = downward stairs
			if tilemap[x][y] == 1 or tilemap[x][y] == 2 or tilemap[x][y] == 3 or tilemap[x][y] == '<' or tilemap[x][y] == '>' then
				love.graphics.setColor(groundColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
				love.graphics.setColor(0,0,0,100)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			elseif tilemap[x][y] == '=' then
				love.graphics.setColor(doorColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
                                love.graphics.setColor(0,0,0,100)
                                for i=1,tilePixelsX,4 do
                                        love.graphics.line((x-1)*tilePixelsX+i, (y-1)*tilePixelsY+2, (x-1)*tilePixelsX+i+1, (y-1)*tilePixelsY+tilePixelsY-2)
                                end
				love.graphics.setColor(0,0,0,100)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			elseif tilemap[x][y] == 'W' then
				love.graphics.setColor(waterColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
				love.graphics.setColor(0,0,0,100)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			end
		end
	end
	for i=1,#visibleTiles,1 do
		local tile = visibleTiles[i]
		x=tile.x
		y=tile.y
		if tilemap[x] ~= nil and tilemap[x][y] ~= nil then
			-- 1 = floor, 2 = closed door, 3 = open door, '<' = upward stairs, '>' = downward stairs
			if tilemap[x][y] == 1 or tilemap[x][y] == 2 or tilemap[x][y] == 3 or tilemap[x][y] == '<' or tilemap[x][y] == '>' then
				love.graphics.setColor(groundColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			elseif tilemap[x][y] == '=' then
				love.graphics.setColor(doorColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			elseif tilemap[x][y] == 'W' then
				love.graphics.setColor(waterColor)
				love.graphics.rectangle("fill", (x-1)*tilePixelsX, (y-1)*tilePixelsX, tilePixelsX, tilePixelsY)
			end
		end
	end
end

function draw_simpleareashade()
	local myfov = fov
	if myfov == 0 then 
		myfov = defaultOutsideFOV
	end
	-- top
	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle('fill',0,0,resolutionPixelsX,(characterY-myfov)*tilePixelsY)
	love.graphics.setColor(0,0,0,135)
	love.graphics.rectangle('fill',0,0,resolutionPixelsX,(characterY-myfov+1)*tilePixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,0,resolutionPixelsX,(characterY-myfov+2)*tilePixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,0,resolutionPixelsX,(characterY-myfov+3)*tilePixelsY)

	-- left
	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle('fill',0,0,(characterX-myfov)*tilePixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,135)
	love.graphics.rectangle('fill',0,0,(characterX-myfov+1)*tilePixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,0,(characterX-myfov+2)*tilePixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,0,(characterX-myfov+3)*tilePixelsX,resolutionPixelsY)

	-- right
	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle('fill',(characterX+myfov)*tilePixelsX,0,resolutionPixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,135)
	love.graphics.rectangle('fill',(characterX+myfov-1)*tilePixelsX,0,resolutionPixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',(characterX+myfov-2)*tilePixelsX,0,resolutionPixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',(characterX+myfov-3)*tilePixelsX,0,resolutionPixelsX,resolutionPixelsY)

	-- bottom
	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle('fill',0,(characterY+myfov)*tilePixelsY,resolutionPixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,135)
	love.graphics.rectangle('fill',0,(characterY+myfov-1)*tilePixelsY,resolutionPixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,(characterY+myfov-2)*tilePixelsY,resolutionPixelsX,resolutionPixelsY)
	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle('fill',0,(characterY+myfov-3)*tilePixelsY,resolutionPixelsX,resolutionPixelsY)

end

-- working FOV
function update_draw_visibility_new()
	visibleTiles={}
	-- mark all seen tiles as not currently seen
	for i,v in ipairs(seenTiles) do
		seenTiles['i'] = 0
	end
	local thefov = nil
	thefov=ROT.FOV.Precise:new(lightPassesCallback,{topology=8})
	results = thefov:compute(characterX,characterY,fov,isVisibleCallback)
end

-- for FOV calculation
function lightPassesCallback(coords,qx,qy)
	-- required as otherwise moving near the edge crashes
	if tilemap[qx] ~= nil and tilemap[qx][qy] ~= nil then
		-- actual check
		if tilemap[qx][qy] == 1 or tilemap[qx][qy] == 3 or tilemap[qx][qy] == '<' or tilemap[qx][qy] == '>' or tilemap[qx][qy] == 'W' or tilemap[qx][qy] == '=' then
			return true
		end
	end
	return false
end

-- for FOV calculation
function isVisibleCallback(x,y,r,v)
	-- first mark as visible
	table.insert(visibleTiles,{x=x,y=y,r=r,last=r,v=v})
	-- also mark in seen tiles as currently seen
	seenTiles[x..','..y] = 1
end

function groundtype(x,y)
	local t=tilemap[x][y]
	if t == '=' then
		return 'bridge'
	else
		return 'gravel'
	end
end

-- check if a given tile is passable for a monster
function tile_is_passable_without_closed_doors(x,y)
	-- only return true for open doors and floor
	if tilemap[x][y] == 1 or tilemap[x][y] == 3 then
		return true
	end
	return false
end

-- check if a given tile is passable for a monster, assuming doors are open/passable, and is not occupied by other monsters
function tile_is_passable_assuming_open_doors_no_npcs(x,y)
        -- only return true for open or closed doors and floor
        if tilemap[x][y] == 1 or tilemap[x][y] == 2 or tilemap[x][y] == 3 then
		-- but only if the tile also has no NPCs
		for _,npc in pairs(npcs) do
			if npc.location.x == x and npc.location.y == y then
				return false
			end
		end
                return true
        end
        return false
end

-- check if a given tile is passable for a monster, WITHOUT assuming doors are open/passable, and is not occupied by other monsters
function tile_is_passable_no_npcs(x,y)
	if x == nil or y == nil then
		print("FATAL: tile_is_passable_no_npcs() passed invalid coordinates.")
		print(table.show(x))
		print(table.show(y))
		os.exit()
	end
        -- only return true for open doors and floor
        if tilemap[x][y] == 1 or tilemap[x][y] == 3 then
		-- but only if the tile also has no NPCs
		for _,npc in pairs(npcs) do
			if npc.location.x == x and npc.location.y == y then
				return false
			end
		end
		-- and is not where the character is standing
		if x ~= characterX and y ~= characterY then
               		return true
		end
	end
        return false
end


-- attack the player with a given NPC
function npc_attack(npc)
	attack(player,npc)
end

-- one being attacks another
function attack(target,attacker)

	if attacker.weapons == nil then return end

	-- first, select a random weapon based upon weighted likelihoods (if present)
	local weapon_selection = {}
	for weapon_index,weapon in ipairs(attacker.weapons) do
		local chances=1
		if weapon.likelihood ~= nil then
			chances=weapon.likelihood
		end
		for i=1,chances,1 do
			table.insert(weapon_selection,weapon_index)
		end
	end
	local weapon = attacker.weapons[weapon_selection[rng:random(1,#weapon_selection)]]

	-- next, select a random attack based upon weighted likelihoods (if present)
	local attack_selection = {}
	for attack_index,attack in ipairs(weapon.attacks) do
		local chances=1
		if attack.likelihood ~= nil then
			chances=attack.likelihood
		end
		for i=1,chances,1 do
			table.insert(attack_selection,attack_index)
		end
	end
	local attack = weapon.attacks[attack_selection[rng:random(1,#attack_selection)]]
	local attack_verb = attack.verbs[rng:random(1,#attack.verbs)]

	-- now to business! calculate success and damage
	local attack_successful = false
	local attack_damage = 0
	-- for now, all attacks succed 75% of the time
	if rng:random(1,20) <= 15 then
		attack_successful = true
		-- calculate damage
		attack_damage = (attack.damage.dice_qty * attack.damage.dice_sides) + attack.damage.plus
		-- add blood at the appropriate location
		add_blood(target.location.x,target.location.y)
	end

	-- notify the player
	local attacker_name = attacker.name
	local target_name = target.name
	local pronoun = "it's "
	local messageColor = notifyMessageColor
	-- if the receipient of damage is you, then...
	if target_name == "you" then
		messageColor=bloodMessageColor
		-- play a sound
		sounds.ouches.male:play()
		sounds.ouches.male:setVolume(2)
	-- if the receipient of damage is not you, then...
	elseif target_name ~= "you" then
		-- it's "the goblin"
		target_name = "the " .. target_name
	end
	-- if the attacker is you, then ...
	if attacker == player then
		messageColor=happyMessageColor
		if weapon.name ~= nil then
			-- '... with Blahzee the Wotsit Weapon'
			pronoun = ""
		else
			-- '... with your sword'
			pronoun = "your "
		end
	else
		attacker_name = "The " .. attacker_name
	end
	
	if attack_successful then
		logMessage(messageColor,attacker_name .. " " .. attack_verb .. " " .. target_name .. " with " .. pronoun .. weapon.name .. " for " .. attack_damage .. "!")
	else
		logMessage(notifyMessageColor,attacker_name .. " " .. attack_verb .. " " .. target_name .. " with " .. pronoun .. weapon.name .. ", but misses!)")
		sounds.misses.swing:play()
		sounds.misses.swing:setVolume(2)
	end
	
	-- effects
	if attack_successful then
		-- reduce target health
		local attack_damage = (attack.damage.dice_qty * attack.damage.dice_sides) + attack.damage.plus
		target.health = target.health - attack_damage

		-- criticals (TODO)

		-- check for death
		if target.health <= 0 then
			target.health=0		-- prevent graphical issues
			if target == player then
				player_is_dead()
			else
				logMessage(notifyMessageColor,"The " .. target.name .. " is dead!")
				remove_npc(target)
			end
		end

		-- play a sound
       		if attacker.sounds.attack ~= nil then
        		attacker.sounds.attack:play()
        	        attacker.sounds.attack:setVolume(2)
        	end
		-- if the target is the player, then
		-- shake the screen for effect
		--  (note: make this based on damage)
		if target == player then
			-- shake the screen for effect
			local amount = rng:random(20)+5
        		shack:setShake(20)
			local amount = rng:random(1,3)*0.1
        		shack:setRotation(amount)
			local amount = rng:random(30)+10
        		shack:zoom(1.25)
		end
	end
end


-- do some death stuff
function player_is_dead()

	-- first, keep the sequence uninterrupted
	keyboard_input_disabled=true

	-- play death scream
	sounds.deaths.male:play()
	sounds.deaths.male:setVolume(2)

	-- next, show the death message
	death_messages = {
				"You are overcome.",
				"The energy saps from your body as you collapse,\nlifelessly.",
				"Death washes over you\nlike relief from a great horror.",
				"Perhaps in death you shall find peace.",
				"Ye shall rise again,\nvictorious,\nin now-eternal dreams."
			 }
	centralMessage(death_messages[rng:random(1,#death_messages)])
	
	-- begin to fade the screen
        table.insert(tweens,flux.to(fade_factor,10,{black=1}):oncomplete(function()
				-- after fading, quit
				os.exit()
        end))
end

function remove_npc(npc_to_remove)
	for index,npc in ipairs(npcs) do
		if npc == npc_to_remove then
			table.remove(npcs,index)
			break
		end
	end
end

function add_blood(x,y)
	-- first check there isn't already blood there
	local already_exists = false
	for index,feature in ipairs(groundfeatures) do
		if feature.type=='blood' and feature.x == x and feature.y == y then
			already_exists=true
			break
		end
	end
	if not already_exists then
		table.insert(groundfeatures,{x=x,y=y,type='blood'})
	end
end

