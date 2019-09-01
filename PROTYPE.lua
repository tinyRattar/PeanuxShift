-- Unfinished
-- predefine
function set end
MAP_COLLIDE=set() -- set for map tile can collide

-- class
entity = {}
function entity:init(x,y)
  ety = {
    x = x
    y = y
    hp = 100
  }
  setmetatable(ety,entity)
  return ety
end
function entity:move(dx,dy)
  -- check collision
  -- move
end

player = {x=5,y=1}
function player:update()
  player:move()
  player:attack()
  player:collision()
end
function player:move()
end

-- tools
function collision()

end

function loadLevel(levelId)
  initMob()
  initNpc()
  initPlayer()
  curLevel = levelId
end

-- main
curLevel = 1

ui:init()
player:init(pos)
loadLevel(1)

function TIC()
  -- update
   -- player.control
   -- player:move()
   -- if btn(4) then player:attack() end --mob->onhit player->onattack
  mainManager = {player,mobManager,npcManager,mapManager}
  drawManager = {mapManager,player,mobManager,npcManager}

  for i=1,#mainManager do
    for j=1,#mainManager[i] do
      mainManager[i][j]:update()

  -- draw
  cls(13)
  for i=1,#drawManager do
    for j=1,#drawManager[i] do
      drawManager[i][j]:draw()

end
