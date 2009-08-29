require "libs/LoveUI/LoveUI.lua"
LoveUI.requireall()

editor = { active = false, cursortexture = nil, cursorobject = nil }

local clr = love.graphics.newColor(255,255,255)
local function preparebutton(btn)
	btn.opaque = false
	btn.textColor = clr
end

editor.context=LoveUI.Context:new();
editor.button_settings=LoveUI.Button:new(LoveUI.Rect:new(10, 10, 80, 32));
editor.button_settings.value = "Settings"
editor.button_settings:setAction(function ()
	editor.view_objects.hidden = true
	editor.view_load.hidden = true
	editor.view_settings.hidden = not editor.view_settings.hidden
end)
preparebutton(editor.button_settings)
editor.button_clear=LoveUI.Button:new(LoveUI.Rect:new(100, 10, 80, 32));
editor.button_clear.value = "Clear"
editor.button_clear:setAction(function ()
	game.map.Objects = {}
end)
preparebutton(editor.button_clear)
editor.button_load=LoveUI.Button:new(LoveUI.Rect:new(190, 10, 80, 32));
editor.button_load.value = "Load"
editor.button_load:setAction(function ()
	editor.view_settings.hidden = true
	editor.view_objects.hidden = true
	editor.view_load.hidden = not editor.view_load.hidden
end)
preparebutton(editor.button_load)
editor.button_save=LoveUI.Button:new(LoveUI.Rect:new(280, 10, 80, 32));
editor.button_save.value = "Save"
editor.button_save:setAction(function ()
	if editor.settings_filename.value == "Filename" then
		return
	end
	game.map.Name = editor.settings_title.value
	game.map.Creator = editor.settings_author.value
	game.map.Version = editor.settings_version.value
	generatemap(editor.settings_filename.value)
end)
preparebutton(editor.button_save)
editor.button_objects=LoveUI.Button:new(LoveUI.Rect:new(370, 10, 80, 32));
editor.button_objects.value = "Tools"
editor.button_objects:setAction(function ()
	editor.view_settings.hidden = true
	editor.view_load.hidden = true
	editor.view_objects.hidden = not editor.view_objects.hidden
end)
preparebutton(editor.button_objects)

editor.view_settings = LoveUI.View:new(LoveUI.Rect:new(10, 42, 200, 300), LoveUI.Size:new(400, 400))
editor.view_settings.hidden = true
editor.settings_title = LoveUI.Textfield:new(LoveUI.Rect:new(10, 10, 100, 26))
editor.settings_title.value = "Title"
preparebutton(editor.settings_title)
editor.settings_author = LoveUI.Textfield:new(LoveUI.Rect:new(10, 41, 100, 26))
editor.settings_author.value = "Author"
preparebutton(editor.settings_author)
editor.settings_version = LoveUI.Textfield:new(LoveUI.Rect:new(10, 72, 100, 26))
editor.settings_version.value = "Version"
preparebutton(editor.settings_version)
editor.settings_filename = LoveUI.Textfield:new(LoveUI.Rect:new(10, 103, 100, 26))
editor.settings_filename.value = "Filename"
preparebutton(editor.settings_filename)
editor.view_settings:addSubview(editor.settings_title, editor.settings_author,
	editor.settings_version, editor.settings_filename)


editor.view_objects = LoveUI.View:new(LoveUI.Rect:new(370, 42, 200, 500), LoveUI.Size:new(400, 500))
editor.view_objects.hidden = false
editor.objectbuttons = {}
local objs = love.filesystem.enumerate("objects")
for i, v in ipairs(objs) do
	editor.objectbuttons[i] = LoveUI.Button:new(LoveUI.Rect:new(10, 42*i-32, 100, 32));
	editor.objectbuttons[i].value = string.sub(v, 1, -5)
	editor.objectbuttons[i]:setAction(function (self)
		editor.cursorobject=loadobjectlite(self.value)
		editor.cursortexture=editor.cursorobject.Resources.texture
		editor.view_objects.hidden = true
	end)
	preparebutton(editor.objectbuttons[i])
end
local i = #objs + 1
editor.objectbuttons[i] = LoveUI.Button:new(LoveUI.Rect:new(10, 42*i-32, 100, 32));
editor.objectbuttons[i].value = "Select"
editor.objectbuttons[i]:setAction(function (self)
	editor.cursorobject=nil
	editor.cursortexture=nil
	editor.view_objects.hidden = true
end)
preparebutton(editor.objectbuttons[i])
editor.view_objects:addSubview(unpack(editor.objectbuttons))

editor.view_load = LoveUI.View:new(LoveUI.Rect:new(190, 42, 200, 300), LoveUI.Size:new(400, 400))
editor.view_load.hidden = true
editor.loadbuttons = {}
local maps = love.filesystem.enumerate("maps")
for i, v in ipairs(maps) do
	editor.loadbuttons[i] = LoveUI.Button:new(LoveUI.Rect:new(10, 42*i-32, 100, 32))
	editor.loadbuttons[i].value = string.sub(v, 1, -5)
	editor.loadbuttons[i]:setAction(function (self)
		startgame(self.value, true)
		editor.view_load.hidden = true
	end)
	preparebutton(editor.loadbuttons[i])
end
editor.view_load:addSubview(unpack(editor.loadbuttons))
	
editor.context:addSubview(editor.button_settings, editor.button_clear,
	editor.button_load, editor.button_save, editor.button_objects,
	editor.view_settings, editor.view_objects, editor.view_load)
