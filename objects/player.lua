OBJECT.Name = "Player"
OBJECT.Creator = "Bart Bes"
OBJECT.Version = 0.1
OBJECT.Resources = { texture = "snakeface/player" }
OBJECT.TextureScale = { x = 1 }

OBJECT.Static = false
OBJECT.Polygon = { {-0.35, -0.45, -0.35, 0.45, 0.35, 0.45, 0.35, -0.45} } --a 10x10 square from the center

function OBJECT:collision(a)
	--we don't do anything on collision, note this probably will be called from the map, instead of from the engine itself
end
