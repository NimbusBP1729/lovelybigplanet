LBP = {}
MOD = {}
CustomCommands = {}
local rLBP = {}

local replaceprops = {
	name = "_name",
	internalname = "_internalname",
	shapes = "_shapes",
	body = "_body",
}

local function propertylookup(prop)
	if replaceprops[prop] then
		prop = replaceprops[prop]
	end
	return prop
end

function rLBP.getObject(object, useplayer)
	if not object and useplayer then object = 'player' end
	if type(object) ~= "table" then
		object = game.map.Objects[object]
	end
	if not object then
		return error("No object")
	end
	return object
end

function rLBP.getProperty(object, property)
	object = rLBP.getObject(object)
	for s in property:gmatch("[^%.]+") do
		object = object[propertylookup(s)]
	end
	return object
end

function rLBP.getX(object)
	return rLBP.getObject(object, true)._body:getX()
end
function rLBP.getY(object)
	return rLBP.getObject(object, true)._body:getY()
end
function rLBP.getName(object)
	return rLBP.getObject(object, true)._name
end
function rLBP.getMass(object)
	return rLBP.getObject(object, true)._body:getMass()
end
function rLBP.getLayers(object)
	return table.concat(rLBP.getObject(object, true)._positions, ', ')
end


function rLBP.setProperty(object, property, value)
	object = game.map.Objects
	local lasts
	for s in property:gmatch("[^%.]+") do
		if lasts then
			object = object[lasts]
		end
		lasts = propertylookup(s)
	end
	object[lasts] = value
end

function rLBP.setLayers(object, positions)
	local posses = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	for i, v2 in ipairs(positions) do
		table.remove(posses, v2-i+1)
	end
	for i, v in ipairs(OBJECT._shapes) do
		v:setCategory(unpack(positions))
		v:setMask(unpack(posses))
	end
end

function rLBP.showScore(show) --do we want to show the score?
	hud.score = show
end

function rLBP.setLvl1(f) --set what function to call to retrieve the lvl1 value, if any
	if type(f) ~= "function" then f = false end
	hud.lvl1 = f
end

function rLBP.setLvl2(f) --same goes for lvl2
	if type(f) ~= "function" then f = false end
	hud.lvl2 = f
end

function rLBP.messageBox(msg, cb, userd) --give me a messagebox NOW!
	if type(msg) ~= "string" then return end
	log("Message: ", msg)
	hud.messageBox(msg, cb, userd)
end

function rLBP.draw(object) --the generic draw function, only takes the object, extracts the rest from it, yay!
	--also, scales to 150 px/m (yes, we use meters!)
	if not object then return end
	if object.Resources.texture.hasInternalDraw then
		object.Resources.texture.resource:draw(object._body:getX(), object._body:getY(), object._body:getAngle(), object.TextureScale.x/150, (object.TextureScale.y or object.TextureScale.x)/150)
	else
		love.graphics.draw(object.Resources.texture.resource, object._body:getX(), object._body:getY(), object._body:getAngle(), object.TextureScale.x/150, (object.TextureScale.y or object.TextureScale.x)/150, object.Resources.texture.resource:getWidth()/2, object.Resources.texture.resource:getHeight()/2)
	end
end

function rLBP.play(music, loop)
	if music.resource:isStopped() then
		love.audio.play(music.resource)
	end
end

function rLBP.stop(music)
	love.audio.stop(music.resource)
end

function rLBP.setLooping(music, loop)
	bool = false
	if loop then bool = true end
	music.resource:setLooping(bool)
end

function rLBP.rewind(music)
	love.audio.rewind(music.resource)
end

function rLBP.addScore(pnt) --the function to add points to the score, as suggested by TechnoKat
	game.score = game.score + pnt
end

function rLBP.round(n) --round a number
	return math.floor(n+0.5)
end

function rLBP.finish()
	--is there a map callback, if so, call it
	if (game.map.finished and game.map.finished()) or (not game.map.finished) then
		game.finished = true
		game.score = game.score + 10000
	end
end

function rLBP.kill(obj)
	obj = LBP.getObject(obj, true)
	--killing is not yet implemented, so we'll restart
	rLBP.restartmap()
end

function rLBP.restartmap()
	startgame(game.map._name)
end

function rLBP.speechBox(speaker, text, cb, userd)
	if type(speaker) ~= "string" or type(text) ~= "string" then return end
	log("Speech from " .. speaker .. ": " .. text)
	hud.speechBox(speaker, text, cb, userd)
end

local mt = {}
function mt:__index(i)
	return rLBP[i] or CustomCommands[i]
end

function mt:__newindex(i, v)
	error("[GENERAL PROTECTION ERROR]:\nAPI OVERWRITE DETECTED\nACTION PROHIBITED")
end

local MOD_mt = {}
function MOD_mt:__index(i)
	return CustomCommands[i] or rLBP[i]
end

function MOD_mt:__newindex(i, v)
	error("[GENERAL PROTECTION ERROR]:\nAPI OVERWRITE DETECTED\nACTION PROHIBITED")
end

setmetatable(LBP, mt)
setmetatable(MOD, MOD_mt)
