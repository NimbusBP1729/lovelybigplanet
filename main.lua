if not love._version or love._version < 060 then
	function load()
		love.graphics.setFont(love.default_font, 32)
	end

	function draw()
		love.graphics.draw("You are running an old version of LOVE", 40, 50)
		love.graphics.draw("To run this game you need to run at least 0.6.0", 40, 100)
		love.graphics.draw("You can get it from http://love2d.org/", 40, 150)
		love.graphics.draw("Or get one of the 'nightly' builds at", 40, 200)
		love.graphics.draw("http://love2d.org/builds", 40, 250)
	end
	return
end

require("padding")
require("constants.lua")
require("save.lua")

dbg = false
resources = {}
requireupdate = {}

function log(...)
	if console then console:print(...) end
	print(...)
	return ...
end

function quitgame()
	log("Saving...")
	save.createsave(startgame, "testmap")
	log("Quitting...\nThanks for playing LovelyBigPlanet!")
	return love.event.push("q")
end

function setRes(w, h, fs)
	love.graphics.setMode(w, h, fs, 0)
	local aspectratio = love.graphics.getWidth()/love.graphics.getHeight()
	if cameras then
		cameras.default = camera.new(150,150)
		cameras.default:setScreenOrigin(0, 1)
		cameras.default:scaleBy(1, -1)
	end
end

local function parsearguments(args)
	local m, c
	local map
	for i, v in ipairs(args) do
		m = v:match("--map=(.*)")
		c = v:match("--exec=(.*)")
		if v == "-d" then
			dbg = true
		elseif m then
			map = m
		elseif c then
			console:execute(c)
		elseif v == "--help" then
			print("Usage: " .. args[0] .. " [-d] [--map=<map>] [--exec=<command>]")
			love.event.push("q")
		end
	end
	return map
end

function love.load()
	require("mainmenu.lua")
	love.filesystem.setIdentity("lovelybigplanet")
	log("Starting up LovelyBigPlanet")
	--set it up, mods, colormode, level
	log("Loading mods")
	local mods = love.filesystem.enumerate("mods")
	for i, v in ipairs(mods) do
		if v:sub(-4, -1) == "lua" then
			require('mods/'..v)
			log("Loaded mod " .. v)
		end
	end
	if love.filesystem.exists("savegame.dat") then
		local savedata = save.loadsave()
		setRes(savedata.width, savedata.height, savedata.fullscreen)
		mainmenu.fullscreen = savedata.fullscreen
		campaignmap = savedata.campaignmap
		log("Loaded save game")
	else
		setRes(1280, 720, false)
		campaignmap = 0
	end
	love.graphics.setColorMode(love.color_modulate)

	love.graphics.setCaption("LovelyBigPlanet")
	require("editor.lua")
	require("api.lua")
	require("game.lua")
	require("map.lua")
	require("hud.lua")
	require("menu.lua")
	require("network.lua")
	require("marketplace.lua")
	require("download.lua")
	require("extract.lua")
	require("libs/console.lua")
	require("libs/camera.lua")
	require("libs/anal.lua")
	--create the cameras
	cameras = {
		hud = camera.new(),
		mainmenu = camera.new(),
		default = camera.new(),
		marketplace = camera.new(),
	}
	--in a do-end structure for the local, we do not want to pollute the global environment
	do
		local aspectratio = love.graphics.getWidth()/love.graphics.getHeight()
		cameras.default = camera.new(150,150)
		cameras.default:setScreenOrigin(0, 1)
		cameras.default:scaleBy(1, -1)
	end
	console:load()
	console:setToggleKey(love.key_home)
	console:setOutputFunction(log)
	console:setQuitFunction(quitgame)
	local njoysticks = love.joystick.getNumJoysticks()
	if njoysticks == 1 then
		activejoystick = 0
	elseif njoysticks > 1 then
		--this needs to be replaced, this doesn't work
		--you need to be able to choose the joystick here
		activejoystick = 0
	end
	if activejoystick then
		log("Activated joystick control")
	end
	love.graphics.setFont(love._vera_ttf, 12)
	local m = parsearguments(arg)
	if m then
		startgame(m)
	else
		mainmenu.load()
	end
end

--here it comes, the magic
function loadmap(name, worlds)
	log("Loading map " .. name)
	if not love.filesystem.exists("maps/" .. name .. ".lua") then log("[ERROR]: Map " .. name .. " doesn't exist.") return false, "FILE " .. name .. ".lua doesn't exist" end
	local f = love.filesystem.load("maps/" .. name .. ".lua")
	local env = {}
	--we'll create an environment, sandboxing, remember?
	--default drawing functions
	env.MAP = mapClass.new()
	--API
	env.LBP = LBP
	--constants
	env.Foreground = 1
	env.Background = 2
	--set and run
	setfenv(f, env)
	f()
	--load all needed Objects and Resources
	for i, v in pairs(env.MAP.Objects) do
		env.MAP.Objects[i] = assert(loadobject(i, v[1], game.world, v[2], v[3], v[4], v[5]))
	end
	for i, v in pairs(env.MAP.Resources) do
		env.MAP.Resources[i] = assert(loadresource(v))
	end
	env.MAP._name = name
	log("Loaded map " .. name)
	f = love.filesystem.newFile("maps/" .. name .. ".lua")
	f:open('r')
	local code = f:read()
	f:close()
	code = code:match("----CODE----\n(.*)")
	env.MAP._code = code or ""
	return env.MAP
end


function loadobject(internalname, name, world, x, y, angle, positions)
	if not love.filesystem.exists("objects/" .. name .. ".lua") then log("[ERROR]: Object " .. name .. " doesn't exist.")  return false, "File " .. name .. ".lua doesn't exist" end
	local f = love.filesystem.load("objects/" .. name .. ".lua")
	local env = {print=print}
	env.OBJECT = {}
	env.LBP = LBP
	env.math = math
	--environment is set up, apply and execute
	setfenv(f, env)
	f()
	--load Resources
	for i, v in pairs(env.OBJECT.Resources) do
		env.OBJECT.Resources[i] = assert(loadresource(v))
	end
	--create and set a physics entity
	env.OBJECT._body = love.physics.newBody(world, x, y, 0, 0)--, env.OBJECT.Weight)
	env.OBJECT._body:setAngle(math.rad(angle))
	env.OBJECT._shapes = {}
	env.OBJECT._positions = positions
	env.OBJECT._name = name
	env.OBJECT._internalname = internalname
	--create the shapes, data is set to the internal name (what the map calls them)
	--category is the layers it's in, mask is what it collides with (or what it doesn't
	--collide with actually)
	for i, v in ipairs(env.OBJECT.Polygon or {}) do
		table.insert(env.OBJECT._shapes, love.physics.newPolygonShape(env.OBJECT._body, unpack(v)))
	end
	for i, v in ipairs(env.OBJECT.Circle or {}) do
		table.insert(env.OBJECT._shapes, love.physics.newCircleShape(env.OBJECT._body, unpack(v)))
	end
	for i, v in ipairs(env.OBJECT.Rectangle or {}) do
		table.insert(env.OBJECT._shapes, love.physics.newRectangleShape(env.OBJECT._body, unpack(v)))
	end
	local posses = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	for i, v2 in ipairs(positions) do
		table.remove(posses, v2-i+1) -- oh god, this is awful
	end
	for i, v in ipairs(env.OBJECT._shapes) do
		v:setData(internalname)
		v:setCategory(unpack(positions))
		v:setMask(unpack(posses))
	end
	--if it's not static, calculate mass, set angular damping, we do not want things
	--to roll too much
	if not env.OBJECT.Static then
		env.OBJECT._body:setMassFromShapes()
		env.OBJECT._body:setAngularDamping(35)
	end
	--layers need WAY more angular damping
	if name == "player" then
		env.OBJECT._body:setAngularDamping(150)
	end
	if env.OBJECT.Init then env.OBJECT:Init() end
	log("Loaded object " .. internalname .. " (" .. name .. ")")
	return env.OBJECT
end

function loadobjectlite(name)
	if not love.filesystem.exists("objects/" .. name .. ".lua") then log("[ERROR]: Object " .. name .. " doesn't exist.") return false, "File " .. name .. ".lua doesn't exist" end
	local f = love.filesystem.load("objects/" .. name .. ".lua")
	local env = {print=print}
	env.OBJECT = {}
	env.LBP = LBP
	--environment is set up, apply and execute
	setfenv(f, env)
	f()
	--load Resources
	for i, v in pairs(env.OBJECT.Resources) do
		env.OBJECT.Resources[i] = assert(loadresource(v))
	end
	env.OBJECT._name = name
	env.OBJECT._lite = true
	log("Loaded object lite (" .. name .. ")")
	return env.OBJECT
end


function loadresource(name)
	if resources[name] then return resources[name] end
	local ftype = ""
	local fext = ""
	--Note the order:
	-- - Music
	-- - Animation
	-- - Image
	--So, this means an animation overrrides an image
	--useful because this allows for an animated
	--and unanimated 'resource package'
	if love.filesystem.exists("resources/" .. name .. ".jpg") then ftype = "image"; fext = ".jpg" end
	if love.filesystem.exists("resources/" .. name .. ".png") then ftype = "image"; fext = ".png" end
	if love.filesystem.exists("resources/" .. name:gsub("(.-)/(.-)$", "%1/anim_%2") .. ".jpg") then ftype = "animation"; fext = ".jpg" end
	if love.filesystem.exists("resources/" .. name:gsub("(.-)/(.-)$", "%1/anim_%2") .. ".png") then ftype = "animation"; fext = ".png" end
	if love.filesystem.exists("resources/" .. name .. ".mp3") then ftype = "music"; fext = ".mp3" end
	if love.filesystem.exists("resources/" .. name .. ".ogg") then ftype = "music"; fext = ".ogg" end
	if love.filesystem.exists("resources/" .. name .. ".xm")  then ftype = "music"; fext = ".xm"  end
	--if it's an image, load and return it
	if ftype == "image" then
		resources[name] = {name = name, resource = love.graphics.newImage("resources/" .. name .. fext)}
		log("Loaded resource " .. name .. " (image)")
		return resources[name]
	elseif ftype == "music" then
		resources[name] = {name = name}
		resources[name].resource = love.audio.newSource("resources/" .. name .. fext, "static")
		resources[name].resource:setLooping(true)
		log("Loaded resource " .. name .. " (music)")
		return resources[name]
	elseif ftype == "animation" then
		name = name:gsub("(.-)/(.-)$", "%1/anim_%2")
		local img = love.graphics.newImage("resources/" .. name .. fext)
		local w, h, s = 150, 150, 0.1
		if love.filesystem.exists("resources/" .. name .. ".def") then
			local f = love.filesystem.newFile("resources/" .. name .. ".def")
			f:open(love.file_read)
			local d = f:read()
			f:close()
			for l in d:gmatch("([^\r\n]+)[\r\n]*") do
				w = l:match("^d = ([%d%.]+)$") or w
				h = l:match("^h = ([%d%.]+)$") or h
				s = l:match("^s = ([%d%.]+)$") or s
			end
			w, h, s = tonumber(w), tonumber(h), tonumber(s)
		end
		local anim = newAnimation(img, w, h, s, 0)
		resources[name] = {name = name, resource = anim, image = img, hasInternalDraw = true}
		table.insert(requireupdate, anim)
		log("Loaded resource " .. name .. " (animation)")
		return resources[name]
	end
	--apparently we didn't succeed in finding the resource, error
	log("[ERROR]: Resource " .. name .. " not found.")
	return false, "Resource " .. name .. " not found."
end

function rtos(resources)
	local s = "{\n"
	for i, v in pairs(resources) do
		s = s .. string.format("\t%s = \"%s\", \n", i, v.name)
	end
	s = s .. "}"
	return s
end

function otos(objects)
	local s = "{\n"
	for i, v in pairs(objects) do
		if type(i) == "number" then
			s = s .. "\t[" .. i .. "] = { "
		else
			s = s .. "\t" .. i .. " = { "
		end
		s = s .. string.format("\"%s\", %f, %f, %f, { ", v._name, v._body:getX(), v._body:getY(), math.deg(v._body:getAngle()))
		for j, w in ipairs{v._shapes[1]:getCategory()} do
			s = s .. w .. ", "
		end
		s = s .. "} }, \n"
	end
	s  = s .. "}"
	return s
end

function generatemap(filename)
	if not love.filesystem.exists("PLACEHOLDER") then
		local f = love.filesystem.newFile("PLACEHOLDER")
		f:open(love.file_write)
		f:close()
		love.filesystem.mkdir("maps")
	end
	local f = love.filesystem.newFile("maps/" .. filename .. ".lua")
	f:open(love.file_write)
	local data = string.format(
[[
MAP.Name = "%s"
MAP.Creator = "%s"
MAP.Version = "%s"
MAP.Resources = %s
MAP.BackgroundScale = { x = %f, y = %f }
MAP.Objects = %s
MAP.Finish = { x = %f, y = %f, position = %d }
MAP.Mission = %s

----CODE----
]],
		game.map.Name,
		game.map.Creator,
		game.map.Version,
		rtos(game.map.Resources),
		game.map.BackgroundScale.x or 1,
		game.map.BackgroundScale.y or game.map.BackgroundScale.x or 1,
		otos(game.map.Objects),
		game.map.Finish.x,
		game.map.Finish.y,
		game.map.Finish.position,
		string.format("%q", game.map.Mission or ''))
	f:write(data)
	f:write(game.map._code)
	f:close()
	log("Saved map to " .. filename)
end

function stopallsounds()
	if game.map then
		for i, v in pairs(game.map.Resources) do
			if v.music then
				love.audio.stop(v.music)
				love.audio.stop(v.resource)
			end
		end
	end
end

function love.draw()
	--we should stop overwriting this
	game.draw()
	setCamera(cameras.hud)
	console:draw()
	setCamera(cameras.default)
end

function love.update(dt)
	game.update(dt)
end

function love.keypressed(key, u)
	--check some global keys first, if they're not used, pass it on
	if dbg and console:keypressed(key, u) then return end
	if mainmenu.active then
		mainmenu.keypressed(key)
		return
	end
	if marketplace.active then
		marketplace.keypressed(key)
		return
	end
	if key == love.key_q and (not editor.active or editor.context.firstResponder.cellClass~=LoveUI.TextfieldCell) then
		return quitgame()
	elseif key == love.key_escape then
		if menu.state then
			menu.cleanup()
		else
			menu.load()
		end
	elseif key == love.key_e and (not editor.active or editor.context.firstResponder.cellClass~=LoveUI.TextfieldCell) then
		if editor.allowed then
			editor.active = not editor.active
		end
	else
		if key == love.key_d and love.keyboard.isDown(love.key_lalt) and love.keyboard.isDown(love.key_lshift) then
			dbg = not dbg
		else
			game.keypressed(key, u)
		end
		if editor.active then
			editor.context:keyEvent(key, editor.context.keyDown)
			if editor.context.firstResponder.cellClass~=LoveUI.TextfieldCell then
				if key == love.key_m then
					editor.default_action = editor.popup_move
				elseif key == love.key_r then
					editor.default_action = editor.popup_rot
				elseif key == love.key_l then
					editor.default_action = editor.popup_place
				elseif key == love.key_d then
					editor.default_action = editor.popup_del
				end
			end
		end
	end
end

function love.keyreleased(key)
	if editor.active then
		editor.context:keyEvent(key, editor.context.keyUp)
	end
	if marketplace.active then
		marketplace.context:keyEvent(key, editor.context.keyUp)
	end
end

function love.joystickpressed(j, button)
	game.joystickpressed(j, button)
end

function getobjat(x, y)
	for k, v in pairs(game.map.Objects) do
		for K, V in ipairs(v._shapes) do
			if V:testPoint(x, y) then
				return k
			end
		end
	end
end

function love.mousepressed(x, y, button)
	editor.mousepressed(x, y, button)
	marketplace.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	editor.mousereleased(x, y, button)
	marketplace.mousereleased(x, y, button)
end

function love.errhand(msg)
	if dbg then error_printer(msg) end
	if not love.graphics or not love.event or not cameras then
		return error_printer(msg)
	end
	love.graphics.setScissor()
	love.graphics.setBackgroundColor(89, 157, 220)
	local font = love.graphics.newFont(love._vera_ttf, 18)
	love.graphics.setFont(font)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.clear()
	love.graphics.print("Oops an error occured:\n    " .. msg:match(".-:.-: (.*)") .. "\n\n" .. "By default you should take no action,\n" .. "however, if this occurs a lot and you think\n" .. "the development team doesn't know\n" .. "please inform us.", 30, 30)
	love.graphics.present()
	local e
	while true do
		e = love.event.wait()
		if e == love.event_quit or e == love.event_keypressed or e == love.event_mousepressed then
			return
		end
	end
end

