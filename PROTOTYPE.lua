-- Unfinished
-- predefine
CAMERA_OFF
function set end
MAP_COLLIDE=set() -- set for map tile can collide
MAP_REMAP_BLANK=set()

-- base class
function damage(iValue, iElem)
  value,
  elem
end

function entity(x,y,w,h,nec,nmc)
  x,y,w,h,
  noEntityCollide,
  noMapCollide,
  pullMul,
  pushMul

  move(dx,dy) --try to move
end

function artifact(cd)
  mode,
  inWorking,
  cdTime,
  tiCD,
  durTime,
  onEquip

  shift()
  switchOn()
  switchOff()
end

function buff(lastT)
  lastT
  ti
  
  onFinish()
end
-- region buff
buffSpeedChange=buff(lastT)
{
  speedMul

  update()
  draw()
}
buffFire=buff(lastT)
{
  stack
  attack
  perTic
  blastAttack

  blast()
  update()
  draw()
}
buffIce=buff(lastT)
{
  stack
  speedMul

  freeze()
  update()
  draw()
}

-- endregion

-- region PLAYER
player=entity(x,y,w,h)
{
  buffList,
  fwd,
  hp,
  attack,
  state,
  onbutter,
  butterFwd,
  key

  meleeCalc()
  waveCast()
  onHit(dmg)
  control()
  update()
  draw()
}

wave=entity(x,y,w,h){
  attack,
  elem,
  lifeTime

  hitCalc()
  update()
  draw()
}

-- endregion

-- region ARTIFACT
theGravation=artifact(cd)
{
  range
  force
  forceLast

  use()
  pull()
  push()
  update()
  draw()
}

theTimeMachine=artifact(cd)
{
  range
  speedUpMul
  speedDownMul
  duration

  use()
  speedUp()
  speedDown()
  update()
  draw()
}

theKelvinWand=artifact(cd)
{
  update()
  draw()
}
-- endregion

-- region MOB
mob=entity(x,y,w,h)
{
  hp,
  state,
  sleep,
  alertRange,
  dmgStunTresh,
  stunTime,
  tiStun,
  canHit,
  buffList
  
  onHit()
  death()
  tryAwake()
}

slime=mob(x,y,h,w)
{
  ms, --move speed
  tiA, --timer for attack
  fwd,
  meleeRange,
  attack

  startAttack()
  meleeCalc()
  update()
  draw()
}

bombMan=mob(x,y,h,w,ms)
{
  ms,
  blastRange,
  attack

  startBlast()
  blastCalc()
  update()
  draw()
}

redTentacle=mob(x,y,h,w,ms){
  tiSlow

  override onHit()
  update()
  draw()
}

blueTentacle=mob(x,y,h,w,ms){
  tiShrink
  tiRecover

  override onHit()
  update()
  draw()
}


-- endregion

-- region ITEM
item=entity(x,y,w,h)
{
  remove() --remove from envManager
}

apple=item(x,y,w,h)
{
  onTaken()
  update()
}

key=item(x,y,w,h)
{
  onTaken()
  update()
}

-- tools
sprc(args) spr+camera
cirbc(args) cirb+camera
MDistance(a,b)
EuDistancePow2(a,b)
CenterDisVec(a,b)
CenterPoint(a)
boxOverlapCast(box)
iEntityCollision(src,tar)
mapCollisionFree(ety)
entityCollisionFree(ety)
specTileCalc(ety,lastmv) -- call in ety.update()

-- specTile
butterTile(ety,lastmv)
killingTile(ety) --ety.onHit() if ety.canhit
openDoorTile(ety)
butterOnLit(ety) --for fire wave
FireTile(ety)

tileFireWatcher={} --registry to envManager
{
  tiFire
  update()
  draw()
}

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
