-- title:  MadPhysicist
-- author: PEANUX Studio
-- desc:   A Zelda-like game.
-- script: lua

CAMERA_OFF={15*8-4,8*8-4}
NEARBY4 = {{-1,0},{1,0},{0,-1},{0,1}}
FAKERANDOM8={4,2,7,5,1,8,3,6}
NEXTLEVEL={2,3,4,nil,8,10,12,9,4,11,4,13,4}
TALKER_DIALOG={3,4,5,9}
TALKER_DIALOG[0]=2
TALKER_DIALOG[7]=6

function set(ls)
local s={}
for _,l in ipairs(ls) do s[l]=true end
function s:contains(e)
	return s[e]==true
end
function s:add(e)
	s[e]=true
end
function s:remove(e)
	s[e]=nil
end
return s
end
local listTmp={}
for i=1,10 do
for j=7,16 do
	table.insert(listTmp,(i-1)*16+j-1)
end
end
local tmpAdd={4,20,68,69,131,132,148,144,17,83,145}
for i=1,#tmpAdd do
table.insert(listTmp,tmpAdd[i])
end
MAP_COLLIDE=set(listTmp)
MAP_ENTER_DANGER=set({3,16,19,32,33,34,35,36,48,49,50,51,52,53,64,65,66,67,178,179,182,166,164,180})
MAP_ENTER_FREE=set({231,238,171,80,238,214})
MAP_REMAP_BLANK=set({208,224,225,226,227,228,240,241,242,243,244,245,144,197,213,176,177})
MAP_TOUCH=set({17,113,128,165,181})
MAP_WATER=set({171})
MAP_BUTTER=set({238})
MAP_LAVA=set({3,16,19,32,33,34,35,36,48,49,50,51,52,53,64,65,66,67})

TEXTS={
{{"Dear Student, ","Welcome to S.H.I.F.T.,","AKA Super Hyper Incredible Fhysical Terrain."},
{"We will teach you, guide you and lead you"," to the truth of the world."}},
{{"Newton:","Gravity always wins.","Now you have my gift, Newton Gravitation."},{"Newton:","Press 'X' to use Newton Gravitation, ","hold 'X' to shift the mode."}},
{{"Hey, Listen!"},{"Watch out these tiny stupid monsters, ","they are believers of the OUTER.","Their attack will reduce your truth value."},
{"You can press 'A' to use your truth sword ","to beat them."},
{"And NEVER forget to use your physicist's Artifact."}},
{{"Galileo:","Iron ball and feather will land at the same time.","I will give you my Galileo Iron-and-Feather."},
{"Galileo:","Press 'Y' to use Galileo Iron-and-Feather, ","hold 'Y' to shift the mode."}},
{{"Kelvin:","It is impossible to stop entropy increase."},
{"Kelvin:","It is impossible for me to not give you ","Kelvin Impossible-Wand."},
{"Kelvin:","It is impossible to ","Press 'B' to NOT use Kelvin Impossible-Wand, ","hold 'B' to NOT shift the mode."}},
{{"Galileo, Newton, Kelvin:","Let us teach you what is truth."}},
{{"Truth is just a dream of Azathoth."}},
{{"The student goes back to school."}},
{{"Hey, Listen!"},{"The truth apples can recover your truth value, ","feel free to eat them."}}
}
TEXTS[0]={{"You lost all your truth value.","Your stupidity shifts you to a believer of ","the OUTER now.","Study hard next time."}}

function damage(iValue, iElem)
dmg={value=iValue,elem=iElem or 0}
return dmg
end

function entity(x,y,w,h)
local ety={
	x=x,y=y,w=w,h=h,noEntityCollide=false,
	noMapCollide=false,pullMul=1,pushMul=1,tmMul=1,tCollided=false,tMoved=false
}
function ety:move(dx,dy,forced)
	self.tCollided=false
	self.tMoved=false
	local ox,oy=self.x,self.y
	self.x=self.x+dx
	local collidedTiles,enteredDangerTiles,enteredFreeTiles=mapCollision(self,forced)
	
	if(#collidedTiles>0)then
		for i=1,#collidedTiles do
			local tile=collidedTiles[i]
			if MAP_TOUCH:contains(tile[1]) then self:touch(tile,forced) end
		end
		self.x=self.x-dx
	elseif(not entityCollisionFree(self))then 
		self.x=self.x-dx
	elseif(#enteredDangerTiles>0)then
		if(forced) then
			for i=1,#enteredDangerTiles do
				local tile=enteredDangerTiles[i]
				self:enter(tile)
			end
		else self.x=self.x-dx end
	elseif(#enteredFreeTiles)then
		for i=1,#enteredFreeTiles do
			local tile=enteredFreeTiles[i]
			self:enter(tile)
		end
	end
	self.y=self.y+dy
	collidedTiles,enteredDangerTiles,enteredFreeTiles=mapCollision(self,forced)
	if(#collidedTiles>0)then
		for i=1,#collidedTiles do
			local tile=collidedTiles[i]
			if MAP_TOUCH:contains(tile[1]) then self:touch(tile,forced) end
		end
		self.y=self.y-dy
	elseif(not entityCollisionFree(self))then 
		self.y=self.y-dy
	elseif(#enteredDangerTiles>0)then
		if(forced) then
			for i=1,#enteredDangerTiles do
				local tile=enteredDangerTiles[i]
				self:enter(tile)
			end
		else
			self.y=self.y-dy
		end
	elseif(#enteredFreeTiles)then
		for i=1,#enteredFreeTiles do
			local tile=enteredFreeTiles[i]
			self:enter(tile)
		end
	end
	if(dx~=0 and ox==self.x)then self.tCollided=true end
	if(dy~=0 and oy==self.y)then self.tCollided=true end
	if(ox~=self.x or oy~=self.y)then self.tMoved=true end
end
function ety:movec(dx,dy,forced) -- continuous move
	local ix,iy=1,1
	local ldx=dx
	local ldy=dy
	if(dx<0)then ix=-1 ldx=-dx end
	if(dy<0)then iy=-1 ldy=-dy end
	while(ldx>0 or ldy>0) do
		if(ldx>=1)then ldx=ldx-1 else ix=ix*ldx ldx=0 end
		if(ldy>=1)then ldy=ldy-1 else iy=iy*ldy ldy=0 end
		self:move(ix,iy,forced)
	end
end
function ety:touch() end
function ety:enter() end
function ety:drawStun()
	sprc(192+t//30%2,self.x+self.w//2-4,self.y-4,0,1,0,0,1,1)
end
return ety
end

function artifact(cd,dur)
atf={
	mode=0,
	inWorking=false,
	cdTime=cd or 0,
	tiCD=0,
	durTime=dur or 0,
	tiDur=0
}
function atf:shift()
	if(self.inWorking)then return false end
	self.mode=1-self.mode
	sfx(4)
	return true
end
function atf:switchOn()
	if(self.tiCD>0)then
		return false
	else
		self.tiCD=self.cdTime
		self.tiDur=0
		self.inWorking=true
		return true
	end
end
function atf:switchOff()
	self.inWorking=false
end
return atf
-- NOTICE: remember calc timer in update()
end

pl=entity(32,60,16,16)
pl.fwd = {1,0}
pl.hp=50
pl.maxHp=100
pl.attack = 5
pl.state = 0
pl.ti1 = 0
pl.key1=0
pl.tiStun=0
pl.lastBtn5=0
pl.lastBtn6=0
pl.lastBtn7=0
pl.onButter=false
pl.lastMove={0,0}
pl.onFireTile=false
pl.onFireTic=0
pl.cleared={}
function pl:atkRect()
local p=self local ar=10
local ox=0 local oy=0
if(p.fwd[1]==1)then res={p.x+p.w,p.y,10,16}
elseif(self.fwd[1]==-1)then res={p.x-ar,p.y,10,16}
elseif(self.fwd[2]==1)then res={p.x,p.y+p.h,16,10}
elseif(self.fwd[2]==-1)then res={p.x,p.y-ar,16,10} end
return res
end
function pl:startAttack()
if(self.state==0) then
	self.state=1
	self.ti1=30
	self.willAtk=true
end
end
function pl:meleeCalc()
sfx(0)
local ar = self:atkRect()
hitList = boxOverlapCast(ar)
for i=1,#hitList do
	local tar=hitList[i]
	if(tar~=self and tar.canHit) then
		local knockback=self.fwd
		if(tar.canHit)then
			tar:onHit(damage(self.attack,0))
			if(tar.tiStun>0 or tar.canKnockBack)then
				for i=1,10 do tar:move(knockback[1],knockback[2],true) end
			end
		end
	end
end
end
function pl:onHit(dmg)
if(self.dead)then return end
if(dmg.value<0)then 
	self:hpUp(-dmg.value)
else
	self.hp=self.hp-dmg.value
	if(self.hp<0)then
		self.hp=0.1
		if(not inbossBattle)then Trinity.active=false pl.dead=true self.td=0 GameOverDialog() end
	end
end
end
function pl:hpUp(value)
if(self.dead)then return end
self.hp=self.hp+value
if(self.hp>self.maxHp)then self.hp=self.maxHp-0.1 if(inbossBattle) then Trinity.active=false pl.dead=true self.td=0 FullScreenDialog(7) end end
starDust(self.x+4,self.y,12,16,6,6,15,5)

end
function pl:getKey()
self.key1=self.key1+1
end
function pl:control()
local dx,dy=0,0
local ms=1
if(self.state~=0) then ms=0.5 end
	if btn(0) then dy=-1 pl.fwd={0,-1} end
	if btn(1) then dy=1 pl.fwd={0,1} end
	if btn(2) then dx=-1 pl.fwd={-1,0} end
	if btn(3) then dx=1 pl.fwd={1,0} end

if(dx==0 and dy==0)then
	pl:move(0,0,true)
else
	pl:movec(dx*self.tmMul*ms,dy*self.tmMul*ms,true)
end

if btnp(4) then pl:startAttack() end

if(btn(5))then
	self.lastBtn5=self.lastBtn5+1
	if(self.lastBtn5==30)then
		atfManager:shiftAtf(3)
	end
else
	if(self.lastBtn5<15 and self.lastBtn5>0)then atfManager:useAtf(3) end
	self.lastBtn5=0
end

if(btn(6))then
	self.lastBtn6=self.lastBtn6+1
	if(self.lastBtn6==30)then
		atfManager:shiftAtf(1)
	end
else
	if(self.lastBtn6<15 and self.lastBtn6>0)then atfManager:useAtf(1) end
	self.lastBtn6=0
end

if(btn(7))then
	self.lastBtn7=self.lastBtn7+1
	if(self.lastBtn7==30)then
		atfManager:shiftAtf(2)
	end
else
	if(self.lastBtn7<15 and self.lastBtn7>0)then atfManager:useAtf(2) end
	self.lastBtn7=0
end
end
function pl:update()
camera.x = self.x-CAMERA_OFF[1]+cameraOffset[1]
camera.y = self.y-CAMERA_OFF[2]+cameraOffset[2]
local ox,oy=self.x,self.y
if(self.onFireTile)then
	if(t%20==0)then
		self:onHit(damage(1,0))
	end
end
self.onFireTile=false
if(self.tiStun>0)then
	self.state=0
	self.tiStun=self.tiStun-self.tmMul
else
	pl:control()
end

if(self.willKnockWithDmg)then
	self:onHit(damage(1))
	self:move(-self.fwd[1],-self.fwd[2],true)
	self.willKnockWithDmg=false
end

if(self.onButter)then
	local mV=1
	local ax,ay=self.lastMove[1],self.lastMove[2]
	if(ax>mV)then ax=mV elseif(ax<-mV)then ax=-mV end
	if(ay>mV)then ay=mV elseif(ay<-mV)then ay=-mV end
	self.onButter=false
	self:movec(ax,ay,true)
end
self.lastMove={self.x-ox,self.y-oy}
if(self.ti1>0) then
	self.ti1=self.ti1-self.tmMul
	if(self.willAtk and self.ti1<=15)then self:meleeCalc() self.willAtk=false end
	if(self.ti1<=0)then self.state=0 end
end
end
function pl:draw()
if(pl.dead)then
	local td=self.td
	self.td=td+1
	local sp=268
	if(td<30)then
	elseif(td<60)then sp=270
	elseif(td<90)then sp=348
	elseif(td<120)then sp=350
	elseif(td<210)then sp=372+td//30-4
	else sp=480+td//30%2 end
	if(td>=120)then sprc(sp,self.x+4,self.y+8,14,1,0,0,1,1) else sprc(sp,self.x,self.y,14,1,0,0,2,2) end
	return 
end
local sprFlip=(1-self.fwd[1])//2
local sprite=260
if(pl.fwd[2]==1) then sprite=256 elseif(pl.fwd[2]==-1) then sprite=264 end
if(self.tiStun>0)then
	sprc(sprite,self.x,self.y,6,1,sprFlip,0,2,2)
	self:drawStun()
elseif(self.state==0) then
	sprc(sprite+t//(20/self.tmMul)%2 * 2,self.x,self.y,6,1,sprFlip,0,2,2)
elseif(self.state==1) then
	sprite=336
	local drawX,drawY=3,2
	local offX,offY=0,0
	if(self.fwd[1]==-1) then offX=-8 end
	if(self.fwd[2]==1) then 
		sprite=288
		drawX=2
		drawY=3
	elseif(self.fwd[2]==-1)then 
		sprite=296 drawX=2 drawY=3 offY=-8
	end
	if self.ti1>=20 then sprc(sprite,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
	elseif self.ti1>=15 then sprc(sprite+drawX,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
	elseif self.ti1>=5 then sprc(sprite+drawX*2,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
	else sprc(sprite+drawX*3,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
	end
end
end
function pl:touch(tile)
local tileId,tx,ty=tile[1],tile[2],tile[3]
if(tileId==181)then
	if(mget(tx,ty)==181 and self.key1>0)then
		mset_4ca(tx,ty,179,181)
		self.key1=self.key1-1
	end
elseif(tileId==165)then 
		if(mget(tx,ty)==165 and self.key1>0)then
			mset_4ca(tx,ty,178,165)
			self.key1=self.key1-1
		end
elseif(tileId==113 or tileId==128)then
	self.tiStun=60
	shockScreen(1,3)
	shockActive((tx-iMapManager.offx)*8,(ty-iMapManager.offy)*8)
end
end
function pl:enter(tile)
local tileId,tx,ty=tile[1],tile[2],tile[3]
if(tileId==178)then mset_4ca(tx,ty,255,178)
elseif(tileId==179)then mset_4ca(tx,ty,255,179)
elseif(MAP_LAVA:contains(tileId))then self:onHit(damage(1))
elseif(tileId==231)then self.cleared[curLevel]=true loadLevel(NEXTLEVEL[curLevel])
elseif(tileId==238)then self.onButter=true
elseif(tileId==80)then self.onFireTile=true
elseif(tileId==182 or tileId==166)then self.willKnockWithDmg=true
elseif(tileId==180 or tileId==164)then self.willKnockWithDmg=true
end
end

theGr=artifact(60,15)
theGr.range=10*8
theGr.rangePow2=theGr.range*theGr.range
theGr.force=5
theGr.sprite=384
function theGr:use()
if(self:switchOn())then end
end
function theGr:pull(isReverse)
if(isReverse)then sfx(6) else sfx(5) end
for i=1,#mobManager do
	local m=mobManager[i]
	if(m and m~=pl)then
		iPull(pl,m,isReverse,self.force,self.rangePow2)
	end
end
for i=1,#envManager do
	local e=envManager[i]
	if(e)then	iPull(pl,e,isReverse,self.force,self.rangePow2) end
end
end
function theGr:push()
self:pull(true)
end
function theGr:update()
if(self.inWorking)then
	local td=self.tiDur
	if(td<self.durTime and td%3==0)then 
		if(self.mode==0) then self:pull() else self:push() end
	end
	self.tiDur=td+1
	if(self.tiDur>=30)then self:switchOff() end
end
if(self.tiCD>0)then self.tiCD=self.tiCD-1 end
end
function theGr:draw()
if(self.inWorking)then
	local rscale=self.tiDur/15
	if(self.mode==0)then rscale=1-rscale end
	if(rscale>1)then rscale=0 end
	local cp=CenterPoint(pl)
	circbc(cp[1],cp[2],self.range*rscale,1)
	circbc(cp[1],cp[2],self.range*rscale-1,15)
end
end

theTM=artifact(240,120)
function theTM:init()
self.range=10*8
self.rangePow2=theTM.range*theTM.range
self.speedUpMul=2 self.speedDownMul=2
self.effectedObject={} self.rClock={} self.hHandPos={} self.mHandPos={}
self.sprite=392

for i=1,48 do
	local cos=math.cos(i*3.14/24)
	local sin=math.sin(i*3.14/24)
	self.hHandPos[i]={sin*3*8,-cos*3*8}
	self.mHandPos[i]={sin*4*8,-cos*4*8}
end
end
theTM:init()
function theTM:use()
if(self:switchOn())then
	if(self.mode==0)then
		sfx(7)
		pl.tmMul=2
		table.insert(self.effectedObject,pl)
	else
		sfx(8)
		for i=1,#mobManager do
			local m=mobManager[i]
			if(m and m~=pl and m.tmMul~=0)then
				local dv=CenterDisVec(pl,m)
				local mdis=dv[1]*dv[1]+dv[2]*dv[2]
				if(mdis<self.rangePow2)then m.tmMul=0.5 table.insert(self.effectedObject,m) end
			end
		end
	end
end
end
function theTM:onTimeOut()
for i=1,#theTM.effectedObject do
	local obj=theTM.effectedObject[i]
	if(obj)then	
		obj.tmMul=1 
		theTM.effectedObject[i]=nil
	end
end
end
function theTM:update()
if(self.inWorking)then
	self.tiDur=self.tiDur+1
	if(self.tiDur>self.durTime)then self:onTimeOut() self:switchOff() end
end
if(self.tiCD>0)then self.tiCD=self.tiCD-1 end
end
function theTM:draw()
if(self.inWorking)then
	local c1=5
	local r1=36
	local r2=120
	local tmul=2
	local sh=self.tiDur/64
	if(self.mode==1)then
		tmul=0.125
		c1=9
		sh=1-sh
	end
	if(self.tiDur<64)then
		local cp=CenterPoint(pl)
		local ht=tmul*self.tiDur//12%48+1
		local mt=tmul*self.tiDur//1%48+1
		local hPos=self.hHandPos[ht]
		local mPos=self.mHandPos[mt]
		
		circbc(cp[1],cp[2],r1,c1)
		circbc(cp[1],cp[2],r1+2,c1)
		circbc(cp[1],cp[2],r1+r2*sh,c1)
		linec(cp[1],cp[2],cp[1]+mPos[1],cp[2]+mPos[2],c1)
		linec(cp[1],cp[2],cp[1]+hPos[1],cp[2]+hPos[2],c1)
		for i=1,#NEARBY4 do
			linec(cp[1]+NEARBY4[i][1],cp[2]+NEARBY4[i][2],cp[1]+hPos[1]+NEARBY4[i][1],cp[2]+hPos[2]+NEARBY4[i][2],c1)
		end
	end
	local dt=self.tiDur//10%8
	for i=1,#self.effectedObject do
		local obj=self.effectedObject[i]
		local l=obj.w+obj.h
		local pt=t%l
		if(self.mode==1)then pt=t//4%l end
		for j=1,5 do
			pt=(pt+1)%l
			if(pt<obj.w)then
				pixc(obj.x+pt,obj.y,c1) pixc(obj.x+obj.w-pt,obj.y+obj.h-1,c1)
			else 
				pixc(obj.x+obj.w-1,obj.y+pt-obj.w,c1) pixc(obj.x,obj.y+obj.h-pt+obj.w,c1) 
			end
		end
	end
end
end

theKW=artifact(60,30)
theKW.sprite=388
function theKW:use()
self:switchOn()
end
function theKW:cast()
sfx(9)
local elem=1
if(self.mode==1)then elem=2 end
local cp=CenterPoint(pl)
table.insert(envManager,KelvinBullet(cp[1],cp[2],pl.fwd,1,elem))
end
function theKW:update()
if(self.inWorking)then
	if(self.tiDur==0) then self:cast() end
	self.tiDur=self.tiDur+1
	if(self.tiDur>self.durTime)then self:switchOff() end
end
if(self.tiCD>0)then self.tiCD=self.tiCD-1 end
end
function theKW:draw()
end

function mob(x,y,w,h,hp,alertR)
local m=entity(x,y,w,h)
m.hp=hp m.maxHp=hp m.state=0 m.sleep=true m.alertRange=alertR or 0 
m.ms=1 m.rawMs=m.ms m.dmgStunTresh=0 m.stunTime=30 m.stunTime_shockTile=120 
m.tiStun=0 m.canHit=true m.isDead=false m.tiFire=0 m.tiIce=0
function m:onHit(dmg,noStun)
	if(self.canHit)then 
		self.sleep=false
		if not noStun then sfx(1) end
		self.hp=self.hp-dmg.value
		if(not noStun and dmg.value>self.dmgStunTresh)then self.tiStun=self.stunTime end
		if(dmg.elem==1)then self.tiFire=150 elseif(dmg.elem==2)then self.tiIce=30 end
		if(self.hp<=0)then self:death() end
		return true
	end
	return false
end
function m:onDeath() end
function m:death()
	self:onDeath()
	if(m.isDead)then return false end
	for i=1,#mobManager do
		if(mobManager[i]==self)then table.remove(mobManager,i) end
	end
	m.isDead=true
	shine(self.x,self.y,self.w//8)
	return true
end
function m:tryAwake()
	local d=MDistance(self,pl)
	if(d<self.alertRange)then self.sleep=false end
end
function m:touch(tile,forced)
	local tileId,tx,ty=tile[1],tile[2],tile[3]
	if(forced)then
		if(tileId==113 or tileId==128)then
			self.tiStun=self.stunTime_shockTile
			shockActive((tx-iMapManager.offx)*8,(ty-iMapManager.offy)*8)
		end
	end
end
function m:enter(tile)
	local tileId,tx,ty=tile[1],tile[2],tile[3]
	if(MAP_LAVA:contains(tileId))then self:death()
	elseif(tileId==80)then self.onFireTile=true
	elseif(tileId==182 or tileId==166)then self:death() end
end
function m:defaultMove(needDis)
	local dv=CenterDisVec(pl,self)
	local dvn=vecNormFake(dv,1)
	local _tmMul=self.tmMul
	local distance=0
	if(self.tmMul<=0)then _tmMul=1 end
	self:movec(dvn[1]*self.ms*_tmMul,dvn[2]*self.ms*_tmMul)
	if(needDis)then distance=(math.max(math.abs(dv[1]),math.abs(dv[2]))) end
	return dv,dvn,distance
end
function m:defaultElem()
	if(self.tiFire>0)then
		if(self.tiFire%30==0) then self:onHit(damage(2,0),true) end
		self.tiFire=self.tiFire-1
	end
	if(self.tiIce>0)then
		self.tiIce=self.tiIce-1
		return false
	end
	return true
end
function m:drawElem()
	for i=1,self.w//8 do
		if(self.tiFire>0)then
			sprc(210+t//30%2,self.x+(i-1)*8,self.y+self.h-8,0,1,0,0,1,1)
		end
		if(self.tiIce>0)then
			sprc(212,self.x+(i-1)*8,self.y+self.h-8,0,1,0,0,1,1)
		end
	end
end
function m:defaultTileCalc()
	self:move(0,0,true)
	if(self.onFireTile)then
		if(t%20==0)then self:onHit(damage(1),true) end
	end
	self.onFireTile=false
end
function m:defaultUpdate()
	self:defaultTileCalc()
	if(not self:defaultElem())then return false end
	if(self.tiStun>0)then
		self.state=0
		local tm_=self.tmMul
		if(tm_==0)then tm_=1 end
		self.tiStun=self.tiStun-tm_
		return false
	end
	if(self.sleep)then
		self:tryAwake()
		return false
	end
	return true
end
function m:drawHp()
	linec(self.x,self.y-1,self.x+self.w,self.y-1,4)
	linec(self.x,self.y-1,self.x+self.w*self.hp/self.maxHp,self.y-1,6)
end
return m
end

function slime(x,y)
local s = mob(x,y,8,8,15,5*8)
s.ms=0.5 s.tiA=0 s.fwd={-1,0} s.meleeRange=(16+8)//2+6 s.attack=2 
s.waitMeleeCalc=false s.tA1=35 s.tA2=90 s.tA3=120  
function s:startAttack()
	self.state=1
	self.tiA=0
	self.waitMeleeCalc=true
end
function s:meleeCalc()
	local atkBox={x=self.x+8*self.fwd[1],y=self.y+8*self.fwd[2],w=8,h=8}
	if(iEntityCollision(pl,atkBox))then pl:onHit(damage(self.attack)) end
end

function s:update()
	if(not self:defaultUpdate())then return end
	if(self.state==0)then
		local dv,dvn=self:defaultMove()
		if((math.max(math.abs(dv[1]),math.abs(dv[2])))<=self.meleeRange)then
			self.fwd=dvn self:startAttack()
		end
	elseif(self.state==1)then
		if(self.waitMeleeCalc and self.tiA>=self.tA1)then self:meleeCalc() self.waitMeleeCalc=false end
		if(self.tmMul<=0)then self.tiA=self.tiA+1 end
		self.tiA=self.tiA+self.tmMul
		if(self.tiA>=self.tA2)then self:defaultMove() end
		if(self.tiA>=self.tA3)then self.state=0 end
	end
end

function s:draw()
	if(self.tiStun>0)then
		sprc(480,self.x,self.y,14,1,0,0,1,1)
		self:drawStun()
	elseif(self.state==0)then
		sprc(480+t//(20/self.tmMul)%2 * 1,self.x,self.y,14,1,0,0,1,1)
	elseif(self.state==1) then
		if(self.tiA<15)then 
			sprc(482,self.x-self.fwd[1]*(self.tiA//5),self.y-self.fwd[2]*(self.tiA//3),14,1,0,0,1,1)
		elseif(self.tiA<35)then
			sprc(482,self.x+self.fwd[1]*(11*(self.tiA-15)/20-3),self.y+self.fwd[2]*(11*(self.tiA-15)/20-3),14,1,0,0,1,1)
		elseif(self.tiA<50)then
			sprc(480,self.x+self.fwd[1]*8,self.y+self.fwd[2]*8,14,1,0,0,1,1)
		else
			sprc(480,self.x,self.y,14,1,0,0,1,1)
		end
	end
	self:drawElem()
end
return s
end

function ranger(x,y)
local rg=mob(x,y,8,8,10,10*8)
rg.ms=0 rg.tiA=0 rg.attack=5 rg.range=10*8 rg.waitShoot=false rg.tA1=30
rg.tA2=60 rg.tA3=90  
function rg:startAttack()
	self.state=1
	self.tiA=0
	self.waitShoot=true
end
function rg:shoot(vecDirection)
	self.waitShoot=false
	local cp=CenterPoint(self)
	local fwd=vecNormFake(vecDirection)
	table.insert(envManager,tinyBullet(cp[1],cp[2],fwd))
end
function rg:update()
	if(not self:defaultUpdate())then return end
	local sx=self.x+self.w//2
	local sy=self.y+self.h//2
	local tx=pl.x+pl.w//2
	local ty=pl.y+pl.h//2
	if(self.state==0)then
		if(MDistance({x=tx,y=ty},{x=sx,y=sy})<=self.range)then
			self:startAttack()
		end
	elseif(self.state==1)then
		if(self.waitShoot and self.tiA>=self.tA1)then self:shoot({tx-sx,ty-sy}) end
		self.tiA=self.tiA+self.tmMul
		if(self.tiA>=self.tA3)then self.state=0 end
	end
end
function rg:draw()
	if(self.tiStun>0)then
		sprc(496,self.x,self.y,0,1,0,0,1,1)
		self:drawStun()
	elseif(self.state==0)then
		sprc(496+t//(20/self.tmMul)%2 * 1,self.x,self.y,0,1,0,0,1,1)
	elseif(self.state==1) then
		if(self.tiA<self.tA1)then 
			sprc(498,self.x,self.y,0,1,0,0,1,1)
		elseif(self.tiA<self.tA2)then 
			sprc(496,self.x,self.y,0,1,0,0,1,1)
		else
			sprc(496+t//(20/self.tmMul)%2*1,self.x,self.y,0,1,0,0,1,1)
		end
	end
	self:drawElem()
end
return rg
end

function staticRanger(x,y,fwd)
local srg=ranger(x,y)
srg.fwd=fwd srg.sleep=false srg.pullMul=0 srg.pushMul=0 srg.tA1=5 srg.tA2=15 
srg.tA3=15 srg.dmgStunTresh=999
function srg:update()
	if(not self:defaultUpdate())then return end
	if(self.state==0)then
		self:startAttack()
	elseif(self.state==1)then
		if(self.waitShoot and self.tiA>=srg.tA1)then self:shoot(self.fwd) end
		self.tiA=self.tiA+self.tmMul
		if(self.tiA>=self.tA3)then self.state=0 end
	end
end
return srg
end

function bombMan(x,y)
local bm=slime(x,y)
bm.hp=5 bm.alertRange=8*8 bm.ms=2 bm.tA1=15 bm.tA2=300 
bm.tA3=300 bm.fwd={-1,0} bm.meleeRange=(16+8)//2+1 bm.attack=5 
bm.stunTime=1 bm.canKnockBack=true

function bm:startAttack()
	self.canKnockBack=false self.state=1 self.tiA=0 self.waitMeleeCalc=true
end
function bm:meleeCalc()
	local atkBox={x=self.x-8,y=self.y-8,w=24,h=24}
	hitList = boxOverlapCast(atkBox)
	for i=1,#hitList do
		local tar=hitList[i]
		if(tar~=self and tar.canHit) then
			tar:onHit(damage(self.attack*5,0))
		elseif(tar==pl)then
			tar:onHit(damage(self.attack,0))
		end
	end
	explode(self.x,self.y)
	shockScreen(2,1,true)
	self:death()
end
function bm:onHit(dmg,noStun)
	if(self.canHit)then 
		self.sleep=false
		if(dmg.elem==1)then 
			self.tiFire=150
			if(self.state==0)then	self:startAttack() end
		elseif(dmg.elem==2)then self.tiIce=30 end
		return true
	end
	return false
end
function bm:draw()
	if(self.tiStun>0)then
		sprc(483,self.x,self.y,14,1,0,0,1,1)
		self:drawStun()
	elseif(self.state==0)then
		sprc(483+t//(20/self.tmMul)%2 * 1,self.x,self.y,14,1,0,0,1,1)
	elseif(self.state==1) then
		if(self.tiA<60)then sprc(485,self.x,self.y,14,1,0,0,1,1)
		else sprc(483,self.x,self.y,14,1,0,0,1,1) end
	end
	self:drawElem()
end
return bm
end

function bomb(x,y)
local bb=bombMan(x,y)
bb.tmMul=0 bb.alertRange=0
function bb:defaultMove()
	return {0,0},{0,0}
end
function bb:update()
	if(self.state==1)then
		if(self.waitMeleeCalc and self.tiA>=self.tA1)then self:meleeCalc() self.waitMeleeCalc=false end
		self.tiA=self.tiA+1
		if(self.tiA>=self.tA3)then self.state=0 end
	end
end
function bb:draw()
	if(self.state==0)then
		sprc(226,self.x,self.y,14,1,0,0,1,1)
	elseif(self.state==1) then
		if(self.tiA<60)then 
			sprc(161,self.x,self.y,14,1,0,0,1,1)
		else
			sprc(161,self.x,self.y,14,1,0,0,1,1)
		end
	end
	self:drawElem()
end
return bb
end

function chargeElite(x,y)
local ce = mob(x,y,16,16,50,10*8)
ce.ms=0.5 ce.chargeMs=3 ce.tiA=0 ce.fwd={-1,0} ce.meleeRange=(16+16)//2+8*4 
ce.attack=10 ce.waitMeleeHit=false ce.dmgStunTresh=10 ce.tA1=20 ce.tA2=20+40 
ce.tA3=20+40+90 ce.tA4=20+40+90+60
function ce:startAttack()
	self.state=1
	self.tiA=0
	self.waitMeleeHit=true
end
function ce:forceStop()
	self.waitMeleeHit=false 
	self.tiA=self.tA2
	shockActive(self.x+self.fwd[1]*4,self.y+self.fwd[2]*4,self.w,self.h,{4,4,5,5,12,12,2,2,15,15},2)
	shockScreen(2,3,true)
end
function ce:meleeCalc()
	local atkBox={x=self.x+2*self.fwd[1],y=self.y+2*self.fwd[2],w=16,h=16}
	if(iEntityCollision(pl,atkBox))then 
		pl:onHit(damage(self.attack))
		self:forceStop()
		pl:movec(self.fwd[1]*4,self.fwd[2]*4,true)
		pl.tiStun=30
	end
end
function ce:update()
	if(not self:defaultUpdate())then return end
	if(self.state==0)then
		local dv,dvn=self:defaultMove()
		if((math.max(math.abs(dv[1]),math.abs(dv[2])))<=self.meleeRange)then
			self.fwd=dvn
			self:startAttack()
		end
	elseif(self.state==1)then
		if(self.tiA>=self.tA1 and self.tiA<self.tA2)then
			local ox,oy=self.x,self.y
			self:movec(self.fwd[1]*ce.chargeMs,self.fwd[2]*ce.chargeMs,true)
			dust(self.x+8,self.y+8)
			if(self.waitMeleeHit)then
				self:meleeCalc()
			end
			if(math.abs(self.x-ox)<=1 and math.abs(self.y-oy)<=1)then 
				self:forceStop()
			end					
		end
		self.tiA=self.tiA+self.tmMul
		if(self.tiA>=self.tA3)then self:defaultMove() end
		if(self.tiA>=self.tA4)then self.state=0 end
	end
end

function ce:draw()
	local sx,sy=self.x+8,self.y+6
	if(self.tiStun>0)then
		sprc(454,self.x,self.y,14,1,0,0,2,2)
		self:drawStun()
	elseif(self.state==0)then
		sprc(454+t//(20/self.tmMul)%2 * 2,self.x,self.y,14,1,0,0,2,2)
	elseif(self.state==1) then
		if(self.tiA<self.tA1)then 
			sprc(458,self.x,self.y,14,1,0,0,2,2)
			rectc(sx-1,sy,3,3,3)
		elseif(self.tiA<self.tA2)then
			sprc(454+t//(10/self.tmMul)%2 * 2,self.x,self.y,14,1,0,0,2,2)
			rectc(sx-1,sy-1,3,3,5)
		elseif(self.tiA<self.tA3)then
			self:drawStun()
			sprc(454,self.x,self.y,14,1,0,0,2,2)
		else
			sprc(454+t//(20/self.tmMul)%2 * 2,self.x,self.y,14,1,0,0,2,2)
		end
	end
	self:drawElem()
	if(self.hp<self.maxHp)then self:drawHp() end
end
return ce
end

function laserElite(x,y)
local le = mob(x,y,16,16,30,10*8)
le.ms=0.5 le.tiA=0 le.fwd={-1,0} le.meleeRange=(16+16)//2+8 
le.laserRange=(16+16)//2+120 le.meleeAttack=5 le.laserAttack=10 
le.waitAttackCalc=false le.pullMul=0.5 le.pushMul=0.5 le.dmgStunTresh=10
le.tA1=40 le.tA2=55 le.tA3=60 le.tA4=90 le.tA5=120 le.tAl1=60 le.tAl2=90 le.tAl3=120  
function le:startMeleeAttack()
	self.state=1
	self.tiA=0
	self.waitAttackCalc=true
end
function le:startLaserAttack()
	sfx(11,"A-5",30)
	self.state=2
	self.tiA=0
	self.waitAttackCalc=true
end
function le:meleeCalc()
	local atkBox={x=self.x-16,y=self.y-16,w=48,h=48}
	hitList = boxOverlapCast(atkBox)
	for i=1,#hitList do
		local tar=hitList[i]
		if(tar==pl) then
			tar:onHit(damage(self.meleeAttack,0))
		end
	end
	for i=1,6 do
		for j=1,6 do
			dust(self.x-16+(i-1)*8+4,self.y-16+(j-1)*8+4)
		end
	end
	shockScreen(2,3)
end
function le:laserCalc()
	local sx,sy=self.x+8,self.y+6
	for i=1,240 do
		local lx,ly=sx+self.fwd[1]*i,sy+self.fwd[2]*i
		if(PointInEntity({lx,ly},pl,2))then
			pl:onHit(damage(self.laserAttack,0))
			break
		end
	end
end
function le:leMove()
	local dv=CenterDisVec(pl,self)
	local dvn=vecNormFake(dv,1)
	local _tmMul=self.tmMul
	if(self.tmMul<=0)then _tmMul=1 end
	local distance=(math.max(math.abs(dv[1]),math.abs(dv[2])))
	if(distance<=(self.meleeRange))then
		self:movec(-dvn[1]*self.ms*_tmMul,-dvn[2]*self.ms*_tmMul)
	elseif(distance>(self.laserRange-6*8))then
		self:movec(dvn[1]*self.ms*_tmMul,dvn[2]*self.ms*_tmMul)
	end
	return dv,dvn,distance
end
function le:update()
	if(not self:defaultUpdate())then return end
	if(self.state==0)then
		local dv,dvn,distance=self:leMove()
		if(distance<=self.meleeRange)then
			self:startMeleeAttack()
		elseif(distance<=self.laserRange)then
			self.fwd=dvn
			self:startLaserAttack()
		end
	elseif(self.state==1)then
		if(self.waitAttackCalc and self.tiA>=self.tA3)then self:meleeCalc() self.waitAttackCalc=false end
		self.tiA=self.tiA+self.tmMul
		if(self.tiA>=self.tA4)then self:leMove() end
		if(self.tiA>=self.tA5)then self.state=0 end
	elseif(self.state==2)then
		if(self.waitAttackCalc and self.tiA>=self.tAl1)then self:laserCalc() self.waitAttackCalc=false end
		self.tiA=self.tiA+self.tmMul
		if(self.tiA>=self.tAl2)then self:leMove() end
		if(self.tiA>=self.tAl3)then self.state=0 end
	end
end

function le:draw()
	if(self.tiStun>0)then
		sprc(422,self.x,self.y,14,1,0,0,2,2)
		self:drawStun()
	elseif(self.state==0)then
		sprc(422+t//(20/self.tmMul)%2 * 2,self.x,self.y,14,1,0,0,2,2)
	elseif(self.state==1) then
		if(self.tiA<self.tA1)then
			sprc(426,self.x,self.y,14,1,0,0,2,2)
		elseif(self.tiA<self.tA2)then
			sprc(426,self.x,self.y-8*((self.tiA-self.tA1)/(self.tA2-self.tA1)),14,1,0,0,2,2)
		elseif(self.tiA<self.tA3)then
			sprc(426,self.x,self.y-8*(1-(self.tiA-self.tA2)/(self.tA3-self.tA2)),14,1,0,0,2,2)
		elseif(self.tiA<self.tA4)then
			sprc(422,self.x,self.y,14,1,0,0,2,2)
		else
			sprc(422+t//(20/self.tmMul)%2 * 2,self.x,self.y,14,1,0,0,2,2)
		end

		if(self.tiA>self.tA1 and self.tiA<self.tA3)then
			rectbc(self.x-16,self.y-16,48,48,3+t//2%3)
		end

	elseif(self.state==2)then
		local sx,sy=self.x+8,self.y+6
		if(self.tiA<self.tAl1)then
			sprc(426,self.x,self.y,14,1,0,0,2,2)
			rectc(sx-1,sy-1,3,3,8)
			if(t%10<4)then linec(sx,sy,sx+self.fwd[1]*240,sy+self.fwd[2]*240,8) end
		elseif(self.tiA<self.tAl2)then
			local size=3*(self.tAl2-self.tiA)//(self.tAl2-self.tAl1)
			local colors={9,8,15}
			rectc(sx-1,sy-1,3,3,8)
			sprc(422,self.x,self.y,14,1,0,0,2,2)
			for i=1,240 do
				circbc(sx+self.fwd[1]*i,sy+self.fwd[2]*i,size,colors[size+1])
			end
				
		else
			sprc(422+t//(20/self.tmMul)%2 * 2,self.x,self.y,14,1,0,0,2,2)
		end
	end
	self:drawElem()
	if(self.hp<self.maxHp)then self:drawHp() end
end
return le
end

Trinity={}
function Trinity:locate(x,y)
self.x=x
self.y=y
end
function Trinity:init()
x,y=self.x,self.y
self.hp=500
self.uiHp=500
self.maxHp=500
self.stackDmg=0
self.tarDmg=100
self.nt=Newton(x-40,y)
self.gl=Galileo(x+40,y)
self.kl=Kelvin(x,y+60)
table.insert(mobManager,self.nt)
table.insert(mobManager,self.gl)
table.insert(mobManager,self.kl)
self.nt.sleep=false
self.gl.sleep=false
self.kl.sleep=false
inbossBattle=true
inRage=false
for i=1,6 do mset(191+i,76,78) end

self.active=true
end
function Trinity:onHit(dmg)
self.hp=self.hp-dmg.value
self.stackDmg=self.stackDmg+dmg.value
if(self.stackDmg>=self.tarDmg)then self.stackDmg=self.stackDmg-self.tarDmg pl:onHit(damage(15)) end
if(self.hp<=200)then inRage=true end
if(self.hp<=0)then self:death() end
end
function Trinity:death()
self.nt:death()
self.gl:death()
self.kl:death()
self.active=false
FullScreenDialog(8)
end
function Trinity:draw()
if(self.active)then
	local tmp_=120
	local tmp_x=72
	rect(7+tmp_x,7+tmp_,150+4,7,15)
	rect(9+tmp_x,9+tmp_,120,3,0)
	if self.uiHp>self.hp then 
		rect(9+tmp_x, 9+tmp_, self.uihp/self.maxHp * 120, 3, 4)
		self.uiHp = self.uiHp-0.5
	else
		self.uihp = self.hp
	end
	rect(9+tmp_x,9+tmp_,self.hp/self.maxHp * 120,3,6)
	local count=self.maxHp/self.tarDmg
	for i=1,count-1 do
		line(8+tmp_x+i*120/count,9+tmp_,8+tmp_x+i*120/count,9+tmp_+3,15)
	end
	print("Trinity",11+tmp_x+120,8+tmp_,0,0,1,true)
	
end
end

function Newton(x,y)
local nt=mob(x,y,16,16,300,0)
nt.maxHp=nt.hp nt.dmgStunTresh=150 nt.stunTime=600 nt.ms=0.75 nt.tiA=0 
nt.fwd={-1,0} nt.leaveRange=5*8 nt.apprRange=6*8 nt.meleeRange=10*8+4 
nt.attack=1 nt.waitAttackCalc=false nt.force=1 nt.pullMul=0 nt.pushMul=0 
nt.mem=0 nt.mem1=0 nt.mem2=0 nt.tA1={60,90,120,120} nt.tA2={60,70,115,165} 
nt.tA3={120,150,195,240}

function nt:onHit(dmg,noStun)
	Trinity:onHit(dmg)
	if(self.canHit)then
		self.sleep=false
		self.hp=self.hp-dmg.value
		if(self.maxHp-self.hp>self.dmgStunTresh)then self.tiStun=self.stunTime end
		if(self.tiStun>0)then self.maxHp=self.hp end
		if(dmg.elem==1)then self.tiFire=150 elseif(dmg.elem==2)then self.tiIce=30 end
			
		return true
	end
	return false
end
function nt:startAttack(index)
	self.state=index
	self.tiA=0
	self.waitAttackCalc=true
	self.mem=index
		
	if(index==2)then 
		self.mem1=self.mem1+1 starDust(self.x,self.y,16,16,10,1,15,5)
	elseif(index==3)then starDust(self.x,self.y,16,16,40,15,15,5)
	else starDust(self.x,self.y,16,16,10,6,15,5)
	end
end
function nt:pull(isReverse)
  local pm=1
  if(inRage)then pm=1.25 end
	iPull(self,pl,isReverse,self.force*0.5*pm)
	for i=1,#envManager do
		local e=envManager[i]
		if(e)then	
			iPull(self,e,isReverse,self.force*pm)
			if(not isReverse)then
				local vec=CenterDisVec(self,e)
				if(math.abs(vec[1])+math.abs(vec[2])<=4)then e:remove() end
			end
		end
	end
end
function nt:emitApple(fwd)
  local cp=CenterPoint(self)
  local lf={{fwd[1],fwd[2]},{-fwd[1],-fwd[2]},{-fwd[2],fwd[1]},{fwd[2],-fwd[1]}}
  local ei=2
  if(inRage)then ei=4 end
  for i=1,ei do
  local ax,ay=cp[1]-4+lf[i][1]*8,cp[2]-4+lf[i][2]*8
    table.insert(envManager,apple(ax,ay)) 
    dust(ax,ay,5,{5,3,3,3},2) 
  end
end
function nt:iMove(noMove)
	local dv=CenterDisVec(pl,self)
	local dvn=vecNormFake(dv,1)
	local _tmMul=self.tmMul
	if(self.tmMul<=0)then _tmMul=1 end
	local distance=(math.max(math.abs(dv[1]),math.abs(dv[2])))
	if(noMove)then return dv,dvn,distance end
	if(distance<=(self.leaveRange))then
		self:movec(-dvn[1]*self.ms*_tmMul,-dvn[2]*self.ms*_tmMul)
	elseif(distance>(self.apprRange))then
		self:movec(dvn[1]*self.ms*_tmMul,dvn[2]*self.ms*_tmMul)
	end
	return dv,dvn,distance
end
function nt:update()
	local _t=self.tmMul
	if(_t==0)then _t=1 end
	if(not self:defaultUpdate())then return end
	if(self.state==0)then
		local dv,dvn,dis=self:iMove()
		if(dis<=self.meleeRange)then
			if(self.mem1>=3 and math.random()*10<self.mem1)then
				self:startAttack(3)
				self.mem1=0 self.mem2=0
			elseif(self.mem==1)then	
				self:startAttack(2)
			else
				self:startAttack(1)
			end
		end
	elseif(self.state==1)then
		if(self.tiA>=self.tA1[1] and self.waitAttackCalc)then
			self.waitAttackCalc=false
			local dv,dvn,dis=self:iMove()
			self:emitApple(dvn)
		end
		self.tiA=self.tiA+_t
		if(self.tiA>=self.tA1[3])then self:iMove() end
		if(self.tiA>=self.tA1[4])then self.state=0 end
	elseif(self.state==2)then
		self.tiA=self.tiA+_t
		if(self.tiA>=self.tA2[2] and self.tiA<self.tA2[3])then self:pull(true) end
		if(self.tiA>=self.tA2[3])then self:iMove() end
		if(self.tiA>=self.tA2[4])then self.state=0 end
	elseif(self.state==3)then
		self.tiA=self.tiA+_t
		if(self.tiA>=self.tA3[2] and self.tiA<self.tA3[3])then self:pull() end
		if(self.tiA>=self.tA3[3])then 
			if(self.mem2<2)then
				self.tiA=self.tA3[1]
				self.mem2=self.mem2+1
				starDust(self.x,self.y,16,16,10,15,15,5)
			else
				self:iMove() 
			end
		end
		if(self.tiA>=self.tA3[4])then self.state=0 end
	end
end
function nt:draw()
	local _t=self.tmMul
	if(_t==0)then _t=1 end
	local sprite=448+t//(20/_t)%2 * 2
	if(self.tiStun>0)then
		sprc(448,self.x,self.y,1,1,0,0,2,2)
		self:drawStun()
	elseif(self.state==0)then
		sprc(sprite,self.x,self.y,1,1,0,0,2,2)
	elseif(self.state==1) then
		if(self.tiA<self.tA1[1])then
			sprc(452,self.x,self.y,1,1,0,0,2,2)
		else
			sprc(sprite,self.x,self.y,1,1,0,0,2,2)
		end
	elseif(self.state==2) then
		local scale=(self.tiA-self.tA2[2])/(self.tA2[3]-self.tA2[2])
		if(self.tiA<self.tA2[1])then
			sprc(452,self.x,self.y-16*((self.tiA)/(self.tA2[1])),1,1,0,0,2,2)
		elseif(self.tiA<self.tA2[2])then
			sprc(452,self.x,self.y-16*(1-scale),1,1,0,0,2,2)
		elseif(self.tiA<self.tA2[3])then
			sprc(448,self.x,self.y,1,1,0,0,2,2)
		else
			sprc(sprite,self.x,self.y,1,1,0,0,2,2)
		end
		if(self.tiA>self.tA2[2] and self.tiA<self.tA2[3])then
			circbc(self.x+8,self.y+8,240*scale,1)
			circbc(self.x+8,self.y+8,240*scale-1,14)
			circbc(self.x+8,self.y+8,240*scale-2,15)
		end
	elseif(self.state==3) then
		local scale=(self.tiA-self.tA3[2])/(self.tA3[3]-self.tA3[2])
		if(self.tiA<self.tA3[1])then
			sprc(452,self.x,self.y,1,1,0,0,2,2)
		elseif(self.tiA<self.tA3[2])then
			sprc(452,self.x,self.y,1,1,0,0,2,2)
		elseif(self.tiA<self.tA3[3])then
			sprc(448,self.x,self.y,1,1,0,0,2,2)
		else
			sprc(sprite,self.x,self.y,1,1,0,0,2,2)
		end
		if(self.tiA>self.tA3[2] and self.tiA<self.tA3[3])then
			circbc(self.x+8,self.y+8,240*(1-scale),1)
			circbc(self.x+8,self.y+8,240*(1-scale)+1,14)
			circbc(self.x+8,self.y+8,240*(1-scale)+2,15)
		end
	end
	self:drawElem()
end

return nt
end

function Galileo(x,y)
local gl=Newton(x,y)
gl.hp=400 gl.maxHp=400 gl.dmgStunTresh=200 gl.stunTime=600 gl.ms=1 
gl.meleeAttack=-10 gl.meleeRange=4*8 gl.pullMul=0.5 gl.pushMul=0.5 gl.tmMul=0
gl.tA1={60,90,150,210}

function gl:startAttack(index)
	self.state=index
	self.tiA=0
	self.waitAttackCalc=true
	self.mem=index
	starDust(self.x,self.y,16,16,15,2,15,5)
end
function gl:ballCalc()
	local atkBox={x=self.x+16*self.fwd[1],y=self.y+16*self.fwd[2],w=24,h=24}
	hitList = boxOverlapCast(atkBox)
	for i=1,#hitList do
		local tar=hitList[i]
		if(tar==pl) then
			tar:onHit(damage(self.meleeAttack,0))
		end
	end
	for i=1,3 do
		for j=1,3 do
			dust(atkBox.x+(i-1)*8+4,atkBox.y+(j-1)*8+4)
		end
	end
	shockScreen(2,3)
end
function gl:update()
  if(inRage)then self.tA1={60,90,100,120} end
	local _t=1
	if(not self:defaultUpdate())then return end
	if(self.state==0)then
		local dv,dvn,dis=self:defaultMove(true)
		if(dis<=self.meleeRange)then
			self:startAttack(1)
			self.fwd=dvn
		end
	elseif(self.state==1)then
		if(self.tiA>=self.tA1[1] and self.waitAttackCalc)then
			self.waitAttackCalc=false
			self:ballCalc()
		end
		self.tiA=self.tiA+_t
		if(self.tiA>=self.tA1[3])then self:defaultMove() end
		if(self.tiA>=self.tA1[4])then self.state=0 end
	end
end
function gl:draw()
	local _t=1
	local sprite=416+t//(20/_t)%2 * 2
	if(self.tiStun>0)then
		sprc(416,self.x,self.y,1,1,0,0,2,2)
		self:drawStun()
	elseif(self.state==0)then
		sprc(sprite,self.x,self.y,1,1,0,0,2,2)
	elseif(self.state==1) then
		if(self.tiA<self.tA1[1])then
			rectbc(self.x+16*self.fwd[1],self.y+16*self.fwd[2],24,24,3+t//2%3)
			sprc(368,self.x+16*self.fwd[1],self.y+16*self.fwd[2]-(1-(self.tiA/self.tA1[1]))*80,0,3,0,0,1,1)
			sprc(420,self.x,self.y,1,1,0,0,2,2)
		else
			sprc(sprite,self.x,self.y,1,1,0,0,2,2)
		end
	end
	self:drawElem()
end
return gl
end

function Kelvin(x,y)
local kl=Newton(x,y)
kl.hp=200 kl.maxHp=200 kl.dmgStunTresh=100 kl.stunTime=600 
kl.leaveRange=3*8 kl.apprRange=6*8 kl.ms=0.5 kl.meleeAttack=10 
kl.pullMul=0.5 kl.pushMul=0.5 kl.tmMul=0 kl.tA1={60,90,150,450}

function kl:startAttack(index)
	self.state=index self.tiA=0 
	self.waitAttackCalc=true self.mem=index
	starDust(self.x,self.y,16,16,10,8,15,5)
end
function kl:castIceBall()
  local ki=KelvinIceBall(self.x,self.y)
  if(inRage)then ki.ms=1.25 ki.hp=2 end
	table.insert(mobManager,ki)
end
function kl:update()
	local _t=1
	self.tiIce=0 self.tiFire=0
	if(not self:defaultUpdate())then return end
	if(self.state==0)then
		local dv,dvn,dis=self:iMove()
		if(dis<=self.apprRange)then self:startAttack(1) end
	elseif(self.state==1)then
		if(self.tiA>=self.tA1[1] and self.waitAttackCalc)then
			self.waitAttackCalc=false
			self:castIceBall()
		end
		self.tiA=self.tiA+_t
		if(self.tiA>=self.tA1[3])then self:iMove() end
		if(self.tiA>=self.tA1[4])then self.state=0 end
	end
end
function kl:draw()
	local _t=1 local sprite=486+t//(20/_t)%2 * 2
	if(self.tiStun>0)then
		sprc(486,self.x,self.y,1,1,0,0,2,2)
		self:drawStun()
	elseif(self.state==0)then sprc(sprite,self.x,self.y,1,1,0,0,2,2)
	elseif(self.state==1)then
		if(self.tiA<self.tA1[1])then sprc(490,self.x,self.y,1,1,0,0,2,2)
		else sprc(sprite,self.x,self.y,1,1,0,0,2,2)
		end
	end
	self:drawElem()
end
return kl
end

function KelvinIceBall(x,y)
local km=bombMan(x,y)
km.hp=1 km.h=16 km.w=16 km.tiLife=300 km.noEntityCollide=true 
km.noMapCollide=true km.ms=0.5 km.meleeRange=12 km.attack=-10
km.pullMul=0.5 km.pushMul=0.5 km.tmMul=0 km.sleep=false

function km:meleeCalc()
	local atkBox={x=self.x-8,y=self.y-8,w=32,h=32}
	hitList = boxOverlapCast(atkBox)
	for i=1,#hitList do
		local tar=hitList[i]
    if(tar==pl)then
      pl.tiStun=60
			tar:onHit(damage(self.attack,0))
		end
	end
	for i=1,2 do
		for j=1,2 do
			dust(self.x+(i-1)*8+4,self.y+(j-1)*8+4,4,{9,8,8,0},4,30)
		end
	end
	shockScreen(2,1,true)
	self:death()
end
function km:death()
	for i=1,#mobManager do
		if(mobManager[i]==self)then table.remove(mobManager,i) end
	end
	return true
end
function km:onHit(dmg,noStun)
	if(dmg.elem==1)then 
		self.hp=self.hp-1
		dust(self.x+8,self.y+8,4,{16,15,14,14},2,30)
		if(self.hp<=0)then self:meleeCalc() end
	end
end
function km:draw()
	if(self.tiLife<=0)then self:meleeCalc() end
	self.tiLife=self.tiLife-1
	sprc(371,self.x,self.y,0,2,0,0,1,1)
	if(self.state==1 and self.tiA<self.tA1)then
		rectbc(self.x-8,self.y-8,32,32,8)
	end
	self:drawElem()
end
return km
end

function fence(x,y)
local fe=mob(x,y,8,8,-1,-1)
fe.pullMul=0 fe.pushMul=0 fe.tmMul=0 fe.canHit=false
function fe:update() end
function fe:draw() end
return fe
end
function weakRock(x,y)
local wr=mob(x,y,8,8,1,-1)
wr.pullMul=0 wr.pushMul=0 wr.tmMul=0

function wr:onDeath()
	mset(iMapManager.offx+self.x//8,iMapManager.offy+self.y//8,255)
end
function wr:update()
end
function wr:draw()
	sprc(144,self.x,self.y,0,1,0,0,1,1)
end
return wr
end

function fireTentacle(x,y,noInit)
local ft=mob(x,y,8,8,1,-1)
ft.noEntityCollide=true ft.pullMul=0 ft.pushMul=0 
ft.tmMul=0 ft.rawChangeTime=1 ft.tiC=0 ft.sprite=182 ft.horSprite=166

function ft:changeOneTile()
	local tmp=1
	if(self.toShort)then tmp=-1 mset(iMapManager.offx+self.tailx,iMapManager.offy+self.taily,255) end
	if(self.fwd[1]<0)then	self.x=self.x-tmp*8	end
	if(self.fwd[1]~=0)then self.w=self.w+tmp*8 end
	if(self.fwd[2]<0)then	self.y=self.y-tmp*8	end
	if(self.fwd[2]~=0)then self.h=self.h+tmp*8 end
	self.curLen=self.curLen+tmp
	self.tailx=self.tailx+tmp*self.fwd[1]
	self.taily=self.taily+tmp*self.fwd[2]
	if(not self.toShort)then mset(iMapManager.offx+self.tailx,iMapManager.offy+self.taily,self.sprite) end
end
function ft:init()
	self.tailx=self.x//8
	self.taily=self.y//8
	for i=1,#NEARBY4 do
		local tfwd=NEARBY4[i]
		local tileId=mget(iMapManager.offx+self.x//8+tfwd[1],iMapManager.offy+self.y//8+tfwd[2])
		if(tileId==self.sprite)then
			self.fwd=tfwd
			break
		elseif(tileId==self.horSprite)then
			self.fwd=tfwd
			self.sprite=self.horSprite
			break
		end
	end
	local tLen=0
	if(self.fwd)then
		while(mget(iMapManager.offx+self.tailx+self.fwd[1],iMapManager.offy+self.taily+self.fwd[2])==self.sprite)do
			tLen=tLen+1
			self.tailx=self.tailx+self.fwd[1]
			self.taily=self.taily+self.fwd[2]
		end
		self.maxLen=tLen
	else
		trace("Tentacle error")
	end
	self.curLen=self.maxLen
	self.toShort=true
	if(self.fwd[1]<0)then
		self.x=self.x-tLen*8
	end
	if(self.fwd[1]~=0)then self.w=self.w+math.abs(tLen)*8 end
	if(self.fwd[2]<0)then
		self.y=self.y-tLen*8
	end
	if(self.fwd[2]~=0)then self.h=self.h+math.abs(tLen)*8 end
end
if(not noInit)then ft:init() end
function ft:onHit(dmg)
	if(dmg.elem==2)then
		self.tiIce=300
	end
end
function ft:update()
	local tScale=1
	if(self.tiIce>0)then tScale=0.05 self.tiIce=self.tiIce-1  end
	if(self.tiC<=0)then
		self:changeOneTile()
		if(self.curLen==0)then self.toShort=false end
		if(self.curLen==self.maxLen)then self.toShort=true end
		self.tiC=self.rawChangeTime
	end
	self.tiC=self.tiC-tScale
end
function ft:draw()
	local color=4
	if(self.tiIce>0)then color=9 end
	rectbc(self.x,self.y,self.w,self.h,color)
end

return ft
end

function iceTentacle(x,y)
local it=fireTentacle(x,y,true)
it.rawChangeTime=10
it.tiC=0 it.sprite=164 it.horSprite=180
it:init()
function it:onHit(dmg)
	if(dmg.elem==1)then
		self.tiFire=300
	end
end
function it:update()
	local tScale=1
	if(self.tiFire>0 and self.curLen>0)then 
		if(self.tiC<=0)then
			self.toShort=true
			self:changeOneTile()
			self.tiC=self.rawChangeTime
		end
		self.tiC=self.tiC-1
		self.tiFire=self.tiFire-1
	elseif(self.tiFire<0 and self.curLen<self.maxLen)then
		if(self.tiC<=0)then
			self.toShort=false
			self:changeOneTile()
			self.tiC=self.rawChangeTime
		end
		self.tiC=self.tiC-1
	end
end
function it:draw()
	local color=9
	if(self.tiFire>0)then color=4 end
	rectbc(self.x,self.y,self.w,self.h,color)
end
return it
end

function item(x,y,w,h)
local it = entity(x,y,w,h)
it.noEntityCollide=true

function it:update()
	if(iEntityTrigger(pl,self))then self:onTaken() end
end
function it:remove()
	for i=1,#envManager do
		if(envManager[i]==self)then table.remove(envManager,i) end
	end
end
return it
end

function apple(x,y)
local app=item(x,y,8,8)

function app:onTaken()
  sfx(3)
  if(inbossBattle)then pl:hpUp(15) else pl:hpUp(5) end
	self:remove()
end
function app:draw()
	sprc(224,self.x,self.y,14,1,0,0,1,1)
end

return app
end

function keyItem(x,y,tx,ty)
local k=item(x,y,8,8)
k.tx=tx
k.ty=ty

function k:onTaken()
	sfx(3)
	pl:getKey()
	mset(self.tx,self.ty,255)
	self:remove()
end
function k:draw()
	sprc(208,self.x,self.y,14,1,0,0,1,1)
end
return k
end

function portal(x,y,code,tx,ty)
local p=item(x,y,16,16)
p.pullMul=0
p.pushMul=0
p.code=code
if(pl.cleared[code+5])then
	p.closed=true
end

function p:onTaken()
	loadLevel(self.code+5)
end
function p:update()
	if(not self.closed and (iEntityTrigger(pl,self)))then self:onTaken() end
end
function p:draw()
	if(self.closed)then 
		sprc(430,self.x,self.y,14,1,0,0,2,2) 
	else
		local s=460+t//10%3 * 2
		if(t//10%3==2)then s=428 end
		sprc(s,self.x,self.y-t//30%2 * 2,14,1,0,0,2,2)
	end
end

return p
end

function talker(x,y,code)
local tk=item(x,y,16,16)
tk.pullMul=0
tk.pushMul=0
tk.code=code
tk.sprite=nil
if(code~=7)then tk.sprite=396 end
if(code==0)then tk.sprite=448 end
if(code==2)then tk.sprite=416 end
if(code==3)then tk.sprite=486 end

function tk:afterTalked()
	local c=self.code
	if(c==7)then
		Trinity:init()
	elseif(c==0)then atfManager[1]=theGr
	elseif(code==2)then atfManager[2]=theTM
	elseif(code==3)then atfManager[3]=theKW
	end
end
function tk:onTaken()
	if(self.code==7)then pl.maxHp=200 end
	dialog(TALKER_DIALOG[tk.code])
	self.talked=true
end
function tk:update()
	if(self.talked)then self:afterTalked() self:remove()
	elseif(iEntityTrigger(pl,self))then self:onTaken() end
end
function tk:draw()
	if(self.sprite) then sprc(self.sprite+t//30%2 * 2,self.x,self.y,1,1,0,0,2,2) end
end

return tk
end
-- endregion

function bullet(x,y,w,h,iDmg,iElem)
local blt=item(x,y,w,h)
blt.dmg=iDmg
blt.elem=iElem or 0
blt.lifetime=nil
blt.iLife=0
blt.hitPlayer=false
blt.pierce=false
blt.hitMobs=set({})
blt.fwd={0,1}
blt.speed=1
function blt:hitCheck()
	if(self.hitPlayer)then
		if(iEntityTrigger(pl,self))then return self:hit(pl) end
	else
		for i=1,#mobManager do
			local m=mobManager[i]
			if(m and m.canHit)then
				if(iEntityTrigger(m,self))then 
					return self:hit(m)
				end
			end
		end
	end
	return false
end
function blt:hit(target)
	if(self.pierce)then
		if(not self.hitMobs:contains(target))then
			target:onHit(damage(self.dmg,self.elem))
			self.hitMobs.add(target)
			return true
		end
	else
		target:onHit(damage(self.dmg,self.elem))
		return true
	end
	return false
end
function blt:defaultTic()
	if(self.lifetime and self.iLife>=self.lifetime)then
		self:remove()
	else
		self:move(self.speed*self.fwd[1],self.speed*self.fwd[2],true)
		self.iLife=self.iLife+1
	end
end

return blt
end

function tinyBullet(x,y,fwd)
local tb=bullet(x,y,1,1,5,0)
tb.hitPlayer=true
tb.lifetime=180
tb.fwd=fwd or {1,0}

function tb:update()
	self:defaultTic()
	if(self.tCollided)then self:remove() end
	if(self:hitCheck())then
		self:remove()
	end
end
function tb:draw()
	circc(self.x,self.y,1,4)
	circbc(self.x,self.y,2,15)
	
end

return tb
end

function KelvinBullet(x,y,fwd,iDmg,iElem)
local kb=bullet(x,y,2,2,iDmg,iElem)
kb.lifetime=60
kb.speed=3
kb.fwd=fwd or {1,0}

function kb:update()
	self:defaultTic()
	if(self.tCollided)then self:remove() end
	if(self:hitCheck())then	self:remove()	end
end
function kb:draw()
	local color=4
	local color2=5
	if(self.elem==2)then color=9 color2=8 end
	circc(self.x,self.y,2,color2)
	circc(self.x,self.y,1,color)
end
function kb:enter(tile)
	local tileId,tx,ty=tile[1],tile[2],tile[3]
	if(self.elem==1)then
		if(MAP_BUTTER:contains(tileId))then
			mset_4ca_set(tx,ty,80,MAP_BUTTER) 
			self:remove()
		end
	elseif(self.elem==2)then
		if(MAP_WATER:contains(tileId))then
			mset_4ca_set(tx,ty,17,MAP_WATER) 
			self:remove()
		elseif(tileId==80)then
			if(inbossBattle)then mset_4ca(tx,ty,255,80) else
			mset_4ca(tx,ty,238,80) end
			self:remove()
		end
	end
end
function kb:touch(tile)
	local tileId,tx,ty=tile[1],tile[2],tile[3]
	if(self.elem==1)then
		if(tileId==17)then
			if(inbossBattle)then mset_4ca(tx,ty,255,17) else
			mset_4ca(tx,ty,171,17) end
		end
	end
end

return kb
end

function effect(x,y,w,h)
local ef = entity(x,y,w,h)
ef.noEntityCollide=true ef.noMapCollide=true ef.pullMul=0 
ef.pushMul=0 ef.after=false

function ef:remove()
	if(self.after)then
		for i=1,#aEnvManager do
			if(aEnvManager[i]==self)then table.remove(aEnvManager,i) end
		end
	else
		for i=1,#envManager do
			if(envManager[i]==self)then table.remove(envManager,i) end
		end
	end
end
return ef
end

function shine(x,y,scale)
local sh = effect(x,y,0,0)
sh.ti=0
sh.scale=scale

function sh:update()
	self.ti=self.ti+1
	if(self.ti>=60)then self:remove()end
end
function sh:draw()
	sprc(194+(self.ti//20),self.x,self.y,0,sh.scale,0,0,1,1)
end

table.insert(envManager,sh)
return sh
end

function shockActive(x,y,w,h,colors,timeInterval)
local sa=effect(x,y,0,0)
sa.ti=0
sa.h=h or 8
sa.w=w or 8
sa.tInter=timeInterval or 10
sa.colors=colors or {15,5,3}
sa.maxTime=sa.tInter*#sa.colors

function sa:update()
	self.ti=self.ti+1
	if(self.ti>=self.maxTime)then self:remove()end
end
function sa:draw()
	local off=self.ti//self.tInter
	rectbc(self.x-off,self.y-off,self.w+off*2,self.h+off*2,self.colors[off+1])
end
table.insert(envManager,sa)
return sa
end

function explode(x,y)
sfx(2)
local ep=effect(x+4,y+4,0,0)
ep.ti=0
ep.fwds={}
for i=1,5 do
	local fx=-1+2*math.random()
	local fy=-1+2*math.random()
	ep.fwds[i]={fx,fy}
end

function ep:update()
	self.ti=self.ti+1
	if(self.ti>=30)then self:remove()end
end
function ep:draw()
	if(self.ti<15)then rectbc(self.x-12,self.y-12,24,24,4) end
	local color=4
	if(self.ti>5)then color=5
	elseif(self.ti>10)then color=12
	elseif(self.ti>15)then color=0 end
	for i=1,#self.fwds do
		local fwd=self.fwds[i]
		circc(self.x+fwd[1]*self.ti,self.y+fwd[2]*self.ti,5*(1-self.ti/30),color)
	end
end
table.insert(envManager,ep)
return ep
end

function dust(x,y,num,colors,size,tLife)
local ds=effect(x,y,0,0)
ds.ti=0
ds.fwds={}
ds.num=num or 2
ds.c=colors or {12,10,2,0}
ds.size=size or 3
ds.tLife=tLife or 30
for i=1,ds.num do
	local fx=-1+2*math.random()
	local fy=-1+2*math.random()
	ds.fwds[i]={fx,fy}
end

function ds:update()
	self.ti=self.ti+1
	if(self.ti>=self.tLife)then self:remove()end
end
function ds:draw()
	local color=self.c[1]
	if(self.ti>5)then color=self.c[2]
	elseif(self.ti>10)then color=self.c[3]
	elseif(self.ti>15)then color=self.c[4] end
	for i=1,#self.fwds do
		local fwd=self.fwds[i]
		circc(self.x+fwd[1]*self.ti,self.y+fwd[2]*self.ti,self.size*(1-self.ti/self.tLife),color)
	end
end
table.insert(envManager,ds)
return ds
end

function star(x,y,color,tLife,maxDis)
local st=effect(x,y,0,0)
st.ti=0 st.color=color st.tLife=tLife st.maxDis=maxDis st.after=true
function st:update()
	self.ti=self.ti+1
	if(self.ti>=self.tLife)then self:remove() end
end
function st:draw()
	local scale=self.ti/self.tLife
	circc(self.x,self.y-self.maxDis*scale,1,color)
end

table.insert(aEnvManager,st)
return st
end
function starDust(x,y,w,h,num,color,tLife,tGenInter)
local ds=effect(x,y,w,h)
ds.ti=0
ds.num=num or 4
ds.color=color or 6
ds.tLife=tLife or h
ds.tGenInter=tGenInter or 1

function ds:update()
	self.ti=self.ti+1
	if(self.ti%self.tGenInter==0)then
		local fx=self.w*math.random()
		local fy=self.h-self.h//4*math.random()
		star(self.x+fx,self.y+fy,self.color,self.tLife,self.h)
		self.num=self.num-1
		if(self.num==0)then self:remove() end
	end
end
function ds:draw()
end
table.insert(envManager,ds)
return ds
end

function torchFire(x,y)
local tf = effect(x,y,0,0)

function tf:update()
end
function tf:draw()
  sprc(381+(t//20)%3,self.x,self.y,0,2,0,0,1,1)
end

table.insert(envManager,tf)
return tf
end

function shockScreen(magnitude,times,changeX)
local ss=effect(0,0,0,0)
ss.ti=0 ss.mag=magnitude ss.times=times ss.maxTime=times*magnitude*4 
ss.increase=true ss.curMag=0
if(changeX)then
	ss.ci=1
else
	ss.ci=2
end

function ss:update()
	self.ti=self.ti+1
	if(self.ti>=self.maxTime)then 
		cameraOffset[1]=0
		cameraOffset[2]=0
		self:remove()
	else
		if(ss.increase)then
			ss.curMag=ss.curMag+1
			if(ss.curMag==ss.mag)then ss.increase=false end
		else
			ss.curMag=ss.curMag-1
			if(ss.curMag==-ss.mag)then ss.increase=true end
		end
		cameraOffset[ss.ci]=ss.curMag
	end
end
function ss:draw()
end
table.insert(envManager,ss)
return ss
end
	
function sprc(id,x,y,alpha_color,scale,flip,rotate,cell_width,cell_height)
spr(id,x-camera.x,y-camera.y,alpha_color,scale,flip,rotate,cell_width,cell_height)
end

function circbc(x,y,radius,color)
circb(x-camera.x,y-camera.y,radius,color)
end

function circc(x,y,radius,color)
circ(x-camera.x,y-camera.y,radius,color)
end

function rectbc(x,y,width,height,color)
rectb(x-camera.x,y-camera.y,width,height,color)
end

function rectc(x,y,width,height,color)
rect(x-camera.x,y-camera.y,width,height,color)
end

function linec(x0,y0,x1,y1,color)
line(x0-camera.x,y0-camera.y,x1-camera.x,y1-camera.y,color)
end

function pixc(x,y,color)
pix(x-camera.x,y-camera.y,color)
end


function mset_4ca(x,y,mid,smid) 
if(smid==nil or mid==smid)then trace("WARNING") end
if(mget(x,y)==smid)then
	mset(x,y,mid)
	for i=1,#NEARBY4 do
		local pos=NEARBY4[i]
		mset_4ca(x+pos[1],y+pos[2],mid,smid)
	end
end
end

function mset_4ca_set(x,y,mid,sset)
if(sset:contains(mget(x,y)))then
	mset(x,y,mid)
	for i=1,#NEARBY4 do
		local pos=NEARBY4[i]
		mset_4ca_set(x+pos[1],y+pos[2],mid,sset)
	end
end
end

function MDistance(a, b)
return math.abs(b.x-a.x)+math.abs(b.y-a.y)
end

function EuDistancePow2(a, b)
return (a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)
end

function CenterDisVec(a, b)
return {a.x+a.w//2-(b.x+b.w//2),a.y+a.h//2-(b.y+b.h//2)}
end

function CenterDisVecWithThresh(a, b, thresh)
local th=thresh or 1
local vec=CenterDisVec(a,b)
for i=1,2 do
	if(math.abs(vec[i])<th)then vec[i]=0 end
end
end

function CenterPoint(a)
return {a.x+a.w//2,a.y+a.h//2}
end

function vecNormFake(v,thresh)
local th=thresh or 0
local vm=math.abs(v[1])
local vmt=math.abs(v[2])
if(vm<vmt)then vm=vmt end
if(vm<=th)then return{0,0} end
return{v[1]/vm,v[2]/vm}
end

function boxOverlapCast(box)
local b=box
if(b.x==nil) then b={x=b[1],y=b[2],w=b[3],h=b[4]} end
finded = {}
for i=1,#mobManager do
	local m=mobManager[i]
	if(m and iEntityCollision(b,m))then finded[#finded+1]=m end
end
return finded
end

function iEntityCollision(src,tar)
if(src.noEntityCollide or tar.noEntityCollide)then
	return false
else
	return iEntityTrigger(src,tar)
end
end

function iEntityTrigger(src,tar)
local l1=tar.x
local r1=tar.x+tar.w-1
local u1=tar.y
local d1=tar.y+tar.h-1
local l2=src.x
local r2=src.x+src.w-1
local u2=src.y
local d2=src.y+src.h-1
if(l2>r1 or l1>r2 or u1>d2 or u2>d1)then
	return false
else
	return true
end
end

function PointInEntity(point,tar,maxDis)
local dis=maxDis or 0
local l1=tar.x
local r1=tar.x+tar.w-1
local u1=tar.y
local d1=tar.y+tar.h-1
local px=point[1]
local py=point[2]
if(px>(r1+dis) or (l1-dis)>px or (u1-dis)>py or py>(d1+dis))then
	return false
else
	return true
end
end

function mapCollision(ety)
local collidedTileList={}
local enteredDangerList={}
local enteredFreeList={}
if(not ety.noMapCollide)then
	local l=ety.x//8
	local r=(ety.x+ety.w-1)//8
	local u=ety.y//8
	local d=(ety.y+ety.h-1)//8
	for i=l,r do
		for j=u,d do
			local tileId = mget(iMapManager.offx+i,iMapManager.offy+j)
			if(MAP_COLLIDE:contains(tileId) or MAP_TOUCH:contains(tileId))then
				table.insert(collidedTileList,{tileId,iMapManager.offx+i,iMapManager.offy+j})
			elseif(MAP_ENTER_DANGER:contains(tileId))then
				table.insert(enteredDangerList,{tileId,iMapManager.offx+i,iMapManager.offy+j})
			elseif(MAP_ENTER_FREE:contains(tileId))then
				table.insert(enteredFreeList,{tileId,iMapManager.offx+i,iMapManager.offy+j})
			end
		end
	end
end
return collidedTileList,enteredDangerList,enteredFreeList
end

function entityCollisionFree(ety)
if(ety.noEntityCollide)then return true end
for i=1,#mobManager do
	local m=mobManager[i]
	if(m and m~=ety)then
		if(iEntityCollision(ety,m))then return false end
	end
end
return true
end

function triggerMapTiles(ety)
if(ety.noMapCollide)then return true end
local l=ety.x//8
local r=(ety.x+ety.w-1)//8
local u=ety.y//8
local d=(ety.y+ety.h-1)//8
for i=l,r do
	for j=u,d do
		local tileId = mget(iMapManager.offx+i,iMapManager.offy+j)
		if(MAP_COLLIDE:contains(tileId))then return false end
	end
end
return true
end

function iPull(src,m,isReverse,force,maxRange)
local scale=m.pullMul
if(isReverse)then scale=m.pushMul end
if(scale<=0)then return end
local ir=1
if(isReverse)then ir=-1 end
local dv=CenterDisVec(src,m)
if(maxRange)then
	local mdis=dv[1]*dv[1]+dv[2]*dv[2]
	if(mdis>=maxRange)then return end
end
dv={dv[1]*ir,dv[2]*ir}
dv=vecNormFake(dv,1)
m:movec(force*dv[1]*scale,force*dv[2]*scale,true)
end

function dialog(index,noAutoActive)
local id=index or 1
local dl={}
dl.cur=1
dl.txtsList=TEXTS[id]
dl.ti=0
dl.maxT=15
for i=1,#dl.txtsList[1] do dl.maxT=dl.maxT+#dl.txtsList[1][i] end

function dl:afterRemove()
end
function dl:remove()
	for i=1,#uiManager do
		if(uiManager[i]==self)then table.remove(uiManager,i) self:afterRemove() end
	end
end
function dl:draw()
  self.ti=self.ti+1
  if(btnp(4))then
    if(self.ti<self.maxT)then self.ti=self.maxT else
      self.cur=self.cur+1
      self.ti=0
      if(self.cur==#self.txtsList+1)then self:remove() return end
      self.maxT=15
      for i=1,#self.txtsList[self.cur] do self.maxT=self.maxT+#self.txtsList[self.cur][i] end
    end
	end
	local txts=self.txtsList[self.cur]
	rectb(2*8-1,12*8-1,26*8+2,4*8+4+2,15)
  rect(2*8,12*8,26*8,4*8+4,0)
  local sumt=0
  for i=1,#txts do
    local iend=self.ti-sumt
    if(iend<0)then iend=0 end
    local tx=string.sub(txts[i],1,iend)
    sumt=sumt+#txts[i]
		print(tx,2*8+4,12*8-4+i*8,15,1,1,true)
	end
end

if(not noAutoActive)then table.insert(uiManager,dl) end
return dl
end

function GameOverDialog()
sfx(10)
local gd=dialog(0,true)

function gd:afterRemove()
	gameOver()
end
table.insert(uiManager,gd)
end

function FullScreenDialog(index)
local sd=dialog(index,true)
sd.id=index
-- sd.txtsList=TEXTS[index]
sd.ti=0
sd.maxT=15
for i=1,#sd.txtsList[1] do
  sd.maxT=sd.maxT+#sd.txtsList[1][i]
end

function sd:afterRemove()
	if(self.id==1)then loadLevel(1) end
	if(self.id==7)then gameOver() end
	if(self.id==8)then curLevel=0 gs=1 inbossBattle=false end
end
function sd:draw()
  if(btnp(4))then
    if(self.ti<self.maxT)then self.ti=self.maxT else
      self.cur=self.cur+1
      self.ti=0
      if(self.cur==#self.txtsList+1)then self:remove() return end
      self.maxT=15
      for i=1,#self.txtsList[self.cur] do self.maxT=self.maxT+#self.txtsList[self.cur][i] end
    end
	end
	self.ti=self.ti+1
	local c=13+(self.ti/self.maxT)*2
  if(c>15)then c=15 end
  if(c<13)then c=13 end
	local txts=self.txtsList[self.cur]
	cls(0)
	local tt=self.ti//4
  if(self.id==7)then spr(492+t//30%2 *2,120-8*tt,68-8*tt,1,tt,0,0,2,2) end
  local sumt=15
  for i=1,#txts do
    local iend=self.ti-sumt
    if(iend<0)then iend=0 end
    local tx=string.sub(txts[i],1,iend)
    sumt=sumt+#txts[i]
		print(tx,15*8-#txts[i]*2,6*8-4+i*8,c,1,1,true)
	end
end
table.insert(uiManager,sd)
end

function LoadMapCode(tx,ty)
local code=0
local is={0,0,0}
if(mget(tx+1,ty)==176)then code=code+4 end
if(mget(tx,ty+1)==176)then code=code+2 end
if(mget(tx+1,ty+1)==176)then code=code+1 end
return code
end

function redraw(tile,x,y)
local outTile,flip,rotate=tile,0,0
if(MAP_REMAP_BLANK:contains(tile))then
	outTile=255
	if(curLevel==4)then outTile=248 end
elseif(tile==80)then
	outTile=80+t//10%3
elseif(tile==171)then
	outTile=171+t//30%2
elseif(tile==113)then
	outTile=113+16*(t//15%2)
elseif(tile==128)then
	outTile=128-16*(t//15%2)
elseif(tile==229)then
	outTile=232
elseif(tile==254)then
	outTile=mget(x,y+1)
end
return outTile,flip,rotate
end

iMapManager={offx=0,offy=0}

function iMapManager:draw()
map(5*30,7*17,31,18,-30*8+(3*t)%(60*8),0,1,1)
map(5*30,7*17,31,18,-30*8+(3*t-30*8)%(60*8),0,1,1)
map(0+self.offx+camera.x//8,0+self.offy+camera.y//8,31,18,8*(camera.x//8)-camera.x,8*(camera.y//8)-camera.y,1,1,redraw)
end

uiStatusBar={hp=pl.hp,maxHp=pl.maxHp}
function uiStatusBar:draw()
local tmp_=0
if(self.maxHp<pl.maxHp)then self.maxHp=self.maxHp+1 end
rect(7,7+tmp_,self.maxHp+4,7,15)
if self.hp>pl.hp then 
	rect(9, 9+tmp_, self.hp, 3, 4)
	self.hp = self.hp-1/60*10  
else
	self.hp=pl.hp
end
rect(9,9+tmp_,pl.hp,3,6)

local key1=pl.key1
for i=1,key1 do
	spr(208,-3+10*i,15,14,1,0,0,1,1)
end

local keyC={"X","Y","B"}
for i=1,3 do
	local atf=atfManager[i]
	if(atf)then
		spr(atf.sprite+2*atf.mode,7+(16+4)*(i-1),14*8,1,1,0,0,2,2)
		if(atfManager[i].inWorking)then
			rect(7+(16+4)*(i-1),15*8-6,16*(1-atf.tiDur/atf.durTime),5,6)
		elseif(atf.tiCD>0)then
			rect(7+(16+4)*(i-1),15*8-6,16*(1-atf.tiCD/(atf.cdTime-atf.durTime)),5,2)
		end
		print(keyC[i],7+20*i-20,15*8+8,15)
	end
end
end

uiKeyBar={}
function uiKeyBar:draw()
local key1=pl.key1
for i=1,key1 do
	spr(208,-3+10*i,15,14,1,0,0,1,1)
end
end

uiManager={uiStatusBar}

curLevel=0
function loadLevel(levelId)
sync()
curLevel=levelId
if(curLevel==0)then FullScreenDialog(1) return end
if(curLevel==4)then
	for i=1,3 do
		if(pl.cleared[4+i])then
			mset(193,58+i*8-8,255) mset(194,58+i*8-8,221) 
			mset(195,58+i*8-8,205) mset(196,58+i*8-8,255)
		end
	end
end
local lOff = {{0,0},{0,37},{2,68},{180,34}, {0,90},{94,0},{90,34}, {38,106},{38,90}, {120,0},{188,0},{108,40},{143,40}}
local MapSize = {{85,37},{90,28},{88,17},{30,64}, {38,41},{26,31},{19,35}, {62,25},{62,16},{68,34},{52,28},{36,38},{33,37}}
iMapManager.offx = lOff[levelId][1] iMapManager.offy = lOff[levelId][2]
for i=1,#mobManager do mobManager[i]=nil end
for i=1,#envManager do envManager[i]=nil end
table.insert(mobManager,pl)
pl.key1=0
for i=1,MapSize[levelId][1] do
	for j=1,MapSize[levelId][2] do
		local tx,ty=i+iMapManager.offx,j+iMapManager.offy
		local mtId=mget(tx,ty)
		if(mtId==240)then table.insert(mobManager,slime(i*8,j*8))
		elseif(mtId==241)then table.insert(mobManager,ranger(i*8,j*8))
		elseif(mtId==242)then table.insert(mobManager,staticRanger(i*8,j*8,{-1,0}))
		elseif(mtId==243)then table.insert(mobManager,staticRanger(i*8,j*8,{1,0}))
		elseif(mtId==244)then table.insert(mobManager,staticRanger(i*8,j*8,{0,-1}))
		elseif(mtId==245)then table.insert(mobManager,staticRanger(i*8,j*8,{0,1}))
		elseif(mtId==225)then table.insert(mobManager,bombMan(i*8,j*8))
		elseif(mtId==226)then table.insert(mobManager,bomb(i*8,j*8))
		elseif(mtId==227)then table.insert(mobManager,laserElite(i*8,j*8))
		elseif(mtId==228)then table.insert(mobManager,chargeElite(i*8,j*8))
		elseif(mtId==224)then	table.insert(envManager,apple(i*8,j*8))
		elseif(mtId==208)then	table.insert(envManager,keyItem(i*8,j*8,tx,ty))
		elseif(mtId==209)then	table.insert(mobManager,fence(i*8,j*8))
		elseif(mtId==144)then	table.insert(mobManager,weakRock(i*8,j*8))
		elseif(mtId==131)then	table.insert(mobManager,fireTentacle(i*8,j*8))
		elseif(mtId==132)then	table.insert(mobManager,iceTentacle(i*8,j*8))
		elseif(mtId==197)then	table.insert(envManager,portal(i*8,j*8,LoadMapCode(tx,ty),tx,ty))
    elseif(mtId==213)then	table.insert(envManager,talker(i*8,j*8,LoadMapCode(tx,ty)))
    elseif(mtId==190)then	torchFire(i*8,j*8-8)
		elseif(mtId==254)then	pl.x=i*8 pl.y=j*8
		elseif(mtId==229)then	Trinity:locate(i*8,j*8)
		end
	end
end
end

function gameOver()
pl.hp=50
pl.dead=false
loadLevel(curLevel)
end

atfManager={nil,nil,nil}
function atfManager:shiftAtf(index)
if(self[index])then	self[index]:shift()	end
end
function atfManager:useAtf(index)
if(self[index])then	self[index]:use() end
end

titleC={{167,168,169},{170,183,184,185,186,200,186,185,187}}
function drawMenu()
cls(0)
map(5*30,7*17,31,18,-30*8+(3*t/4)%(60*8),0,1,1)
map(5*30,7*17,31,18,-30*8+(3*t/4-30*8)%(60*8),0,1,1)
map(120,119,31,18,0,0,1)
for i=1,#titleC[1] do
  spr(titleC[1][i],10*8+i*16,4*8-4+(t+30)//60%2,1,2)
end
for i=1,#titleC[2] do
  spr(titleC[2][i],4*8+i*16,7*8-4+t//60%2,1,2)
end
  
print("o",81+math.sin(time()/100),84+(2-cs)*10,6)
print("v1.00c",200,100,15,false,1)
if cs==2 then print("start game",90,84,6) print("credits", 90, 94)
else print("start game",90,84) print("credits", 90, 94,6)end
end
function drawCdt()
cls(0) print("Credits",1,1,15,false,2)print("Program\n\n\t\t - RATTAR\n\n\t\t - Playground",1,20)
print("Visual Art\n\n\t\t - Hustree\n\n\t\t - M!", 1, 60)
print("Producer\n\n\t\t - GANAH",1,100)
print("Game Design\n\n\t\t - Roku\n\n\t\t - Timechaser\n\n\t\t - GANAH",90,20)
print("Sound Effect\n\n\t\t - Roku\n\n\t\t - Playground\n\n\t\t",90,76)
print("Music\n\n\t\t - Roku\n\n\t\t",180,20)
print("press A to exit",180,120,15,false,1,true)
end
mobManager={}
envManager={}
aEnvManager={}  

t=0 camera={x=0,y=0} cameraOffset={0,0}

mainManager={mobManager,atfManager,envManager,aEnvManager}
drawManager={{iMapManager},envManager,{pl},mobManager,aEnvManager,atfManager,uiManager,{Trinity}}

gs=0 cs=2 musicon=-1
cheat=0
function TIC()
t=t+1
if gs==0 then drawMenu()
	if musicon~=0 then music(2) musicon=0 end
	if btn(6) then cheat=cheat+1 if(cheat>60)then MAP_COLLIDE:remove(145) atfManager[1]=theGr atfManager[2]=theTM atfManager[3]=theKW gs=2 loadLevel(4) end else cheat=0 end
	if btn(0) then cs=2 end
	if btn(1) then cs=1 end
	if btnp(4) then 
		gs=cs
		if(gs==2)then
			loadLevel(curLevel)
		end
	end
elseif gs==1 then
	drawCdt()
	if btnp(4) then gs=0 end
else
	if musicon==0 then music() end 
	if(inbossBattle) then if(musicon~=1) then music(1) musicon=1 end
	else music() musicon=-1 end
	if(#uiManager<2)then
		for i=1,#mainManager do
			for j=1,#mainManager[i] do
				local obj=mainManager[i][j]
				if(obj)then obj:update() end
			end
		end
	end
	cls(0)
	for i=1,#drawManager do
		for j=1,#drawManager[i] do
			local obj=drawManager[i][j]
			if(obj)then	drawManager[i][j]:draw() end
		end
	end
end
end

-- <TILES>
-- 000:1111111111111111111111111111111111111111111111111111111111111111
-- 002:bbddededbdfffffedfefefedfefefefeefefefedfefefefeefefefedfefefefe
-- 003:edededbafffffdbaefefedbafefefdbaefefedbafefefdbaefefedbafefefdba
-- 004:1111111111111111111111111111111111a0a0a01a0a0a0aa0a0a0a00a0a0a0a
-- 005:a0a0a0a00a0a0a0aa0a0a0a00a0a0a0ad0a0a0a0db0a0a0adbb0a0a0dbbb0a0a
-- 006:abababffbabababfababababbabababaababababbabababaababababbabababa
-- 007:dfabababfabababaababababbabababaababababbabababaababababbabababa
-- 008:11111ddd111111dd111111dd111111dd111111dd111111dd111111dd111111dd
-- 009:ddd11111dd111111dd111111dd111111dd111111dd111111dd111111dd111111
-- 010:11111ddd1111111d1111111d1111111111111111111111111111111111111111
-- 011:ddd11111d1111111d11111111111111111111111111111111111111111111111
-- 012:11111ddd1111111d1111111d1111111111111111111111111111111111111111
-- 013:dddeedddddeeeddddddeeddddddeeddddddeeddddddeeddddddeedddddeeeedd
-- 014:ddeeeedddeeeeeeddeeddeeddddddeedddddeeeddddeeeddddeeeddddeeeeeed
-- 015:ddeeeedddeeddeeddeeddeedddddeeedddddeedddeeddeeddeeddeedddeeeedd
-- 016:4455544445554444555444445544444554444455444445554444555444455544
-- 017:fffefefff988899df888999df889998df899988df999889df998899dfddddddd
-- 018:fffefefbe98889bdfbb89b9df889998df89b988df999bd9df9988b9dfddddbdd
-- 019:ededededfffffffeefefefedfefefefeefefefedfefefeddefefeddbfefefdbb
-- 020:11111111111111111111111111111111a0a0a0110a0a0a01a0a0a0a00a0a0a0a
-- 021:a0a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0abaa0a0abba0a0abbba
-- 022:a0a0eeee0addddddaddddddd0dddddddddddddddddddddddddddddddbbbbbbbb
-- 023:eeeea0a0dddddd0addddddd0dddddddaddddddddddddddddddddddddbbbbbbbb
-- 024:111100a0110a0a0a10a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 025:a0a011110a0a0a11a0a0a0a10a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 026:a0a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 027:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 028:ddeeeedddeeddeeddeeddeeddeeddeeddeeddeeddeeddeeddeeddeedddeeeedd
-- 029:dddeeeedddeeeeeddeeedeedeeeddeedeedddeedeeeeeeeeeeeeeeeedddddeed
-- 030:deeeeeeddeeeeeeddeeddddddeeeeeedddeeeeeeddddddeeddddddeedeeeeeed
-- 031:ddeeeedddeeddeeddeeddeeddeeddddddeeeeeeddeeddeeddeeddeedddeeeedd
-- 032:4444555444455544445554444555444455544444554444455444445544444555
-- 033:1111111111111111111111111111111111111111111111111111111111111111
-- 034:edededbafffffdbaefefedbafefefdbaefefddbadddddbbabbbbbbaaaaaaaaaa
-- 035:ededededfffffffeefefefedfefefefeefefefedfefefefeefefefedfefefefe
-- 036:abddededabdffffeabdfefedabdefefeabdfefedabdefefeabdfefedabdefefe
-- 037:eeeeeeeedbeddddddbeddddddbeddddddbedddddaaaaaaaaaaaaaaaaaaaaaaaa
-- 038:eeeeeeeedddddddddfddd6bddfdddb5dddddddddaaaaaaaaaaaaaaaaaaaaaaaa
-- 039:eeeeeeeedddddddddddababdddd49badddddddddaaaaaaaaaaaaaaaaaaaaaaaa
-- 040:ababababbabababaababababbabababadddddddddddddddddddddddddddddddd
-- 041:ababababbabababaababababbabababaeddddddbeddddddbeddddddbeddddddb
-- 042:ababababbabababaababababbabababaababababbabababaababababbabababa
-- 043:ddddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaa
-- 044:11111111111111111111111111111111a0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 045:deeeeeeddeeeeeeddddddeeddddddeedddddeeddddddeedddddeeddddddeeddd
-- 046:ddeeeedddeeddeeddeeddeeddeeeeeeddeeeeeeddeeddeeddeeddeedddeeeedd
-- 047:ddeeeedddeeddeeddeeddeeddeeeeeedddeeeeeddddddeeddedddeedddeeeedd
-- 048:5544445554444555444455544445554444555444455544445554444555444455
-- 049:1111111111111111111111111111111111111111111111111111111111111111
-- 050:aaaaaaaaaabbbbbbabbdddddabddfefeabdfefedabdefefeabdfefedabdefefe
-- 051:ededededfffffffeefefefedfefefefeefefefeddefefefebdefefedbbdefefe
-- 052:ededededfffffffeefefefedfefefefeefefefedddddddddbbbbbbbbaaaaaaaa
-- 053:aaaaaaaabbbbbbbbddddddddfefefefeefefefedfefefefeefefefedfefefefe
-- 054:ddffffddfaeddeadeaeefeadeabbbbadeabbbbadeabbbbadeaaaaaaddddddddd
-- 055:eeeeeeeedddddddddabababddbababadddddddddaaaaaaaaaaaaaaaaaaaaaaaa
-- 056:eeeeeeeeddddddddddddddddddddddddddddddddddddddddddddddddbbbbbbbb
-- 057:dddddddddddddddddddddddddddddddddddddddddddddddddbdbdbdbbdbdbdbd
-- 058:ababababbabababaababababbabababaddeabdddddeabdddddeabdddddeabddd
-- 059:ddddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaa
-- 060:dbbbbbbadbbbbbbadbbbbbbadbbbbbbadbbbbbbadbbbbbbadbbbbbbadbbbbbba
-- 061:eddddddbeddddddbeddddddbeddddddbeddddddbeddddddbeddddddbeddddddb
-- 062:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 063:ddeabdddddeabdddddeabdddddeabdddddeabdddddeabdddddeabdddddeabddd
-- 064:4555444455544445554444555444455544445554444555444455544445554444
-- 065:abddededabdffffeabdfefedabdefefeabdfefedabbdddddaabbbbbbaaaaaaaa
-- 066:aaaaaaaabbbbbbaadddddbbafefeddbaefefedbafefefdbaefefedbafefefdba
-- 067:edededbbffffffdbefefefedfefefefeefefefedfefefefeefefefedfefefefe
-- 068:ebababbebabababbdbababa2babababadbababa2babababadbababa2babababa
-- 069:dbababa2babababadbababa2babababadbababa2babababadbababa2babababa
-- 070:111111111111111111111111aaa11111aaaa1111aaaaa1111aaaa11111aaa111
-- 071:11aaa11111aaa11111aaa11111aaa111a0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 072:dbbbbbbbdbbbbbbbdbbbbbbb1dbbbbbb1dbbbbbb11dbbbbb111aabbb11111aaa
-- 073:bbbbbbbdbbbbbbbdbbbbbbbdbbbbbbd1bbbbbbd1bbbbbd11bbbaa111aaa11111
-- 074:111111111111111111111111ffffffffeeeeeeeeddddddddbbbbbbbbbbbbbbbb
-- 075:1111111111111111f1111111efffffffdeeeeeeedddddddddddddddddddddddd
-- 076:11111111111111111111111ffffffffeeeeeeeeddddddddddddddddddddddddd
-- 077:111111111111111111111111ffffffffeeeeeeeedddddddddddddddddddddddd
-- 078:ddddddddffffffffeeeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 079:eeeeeeeeddddddddddddddddddddddddddddddddddddddddddddddddbbbbbbbb
-- 080:ddd4ddddffff4ffdf334333df344343df444434df445444df345543df334433d
-- 081:ddd4ddddff4ffffdf343333df334343df334443df344543df345543df334433d
-- 082:dd4dddddffff4ffdf333433df343343df334443df345444df345544df334443d
-- 083:dbadbabadbadbabadbadbabadbadbabadbadbabadbadbabadbadbabadbadbaba
-- 084:11aaa11111aaa11111aaa111ffffffffeeeeeeeeddddddddbbbbbbbbbbbbbbbb
-- 085:1111111111111111111aaaaa11aaaaaa11aaaaaa11aaaa1111aaa11111aaa111
-- 086:eeffffffeeefffffeeeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 087:defffeeddefffeeddefffeedffffeeedeeeeededddddddbdbbbbbbbdbbbbbbbe
-- 088:defffddddefffefddefffeeddefffeeddefffeeddefffeeddefffeeddefffeed
-- 089:defffeddfefffeddeefffeddeefffeddeefffeddeefffeddeefffeddeefffedd
-- 090:d55555ddd55555ddd55555ddd55555ddd55555ddd55555ddd55555ddd55555dd
-- 091:dddddefefffddefeeedbbefeeebbbefeeebbbefeeeabbefeeeeaaefeeeeeeefe
-- 092:dd111111dd111111ddf11111ddefffffdddeeeeedddddddddddddddddddddddd
-- 093:bbbbbbbbbabababaabababab1aaaaaaa11aaaaaa111111111111111111111111
-- 094:bbbbbbbbbabababaababababaaaaaaaaaaaaaaaa111111111111111111111111
-- 095:bbbbbbbbbabababaababababaaaaaaa1aaaaaa11111111111111111111111111
-- 096:effffffef555555ff55cc55ffccccccff55cc55ff555555ff555555feffffffe
-- 097:effffffef888888ff889988ff999999ff889988ff888888ff888888feffffffe
-- 098:1111111111111111111111111111111111111111111111dd1111ddbb11ddbbbb
-- 099:1111111111111111111111111111111111111111ddddddddbbbbbbbbaaaaaaaa
-- 100:1111111111111111111111111111111111111111dd111111bbdd1111bbbbdd11
-- 101:11aaa11111aaa11111aaa11111aaa11111aaa11111aaa11111aaa11111aaa111
-- 102:111ddddd11ffffff1efffeeedefffeeedefffeeddefffeeddefffeeddefffeed
-- 103:ddddd111fffffe11eefffed1eefffeddeefffeddeefffeddeefffeddeefffedd
-- 104:ddddddddffefffffefffffeefefffeddeffffeddfefffeddeffffeddfefffedd
-- 105:ddddddddffffeffdeffffefdeeffffeddefffefddeffffeddefffefddeffffed
-- 106:daeeeeadaadbbbaaed4444baeb3333baeb6666baeb8888a7aabbba77ea77777d
-- 107:defeeeeddefeddfddefebbdddefebbbddefebbbddefebbaddefeaaeddefeeeed
-- 108:111111dd111111dd11111fddfffffeddeeeeeddddddddddddddddddddddddddd
-- 109:ddddddddffffffffeeeeeeeeddddddddddddddddbbbbbbbb1bbbbbbb11bbbbbb
-- 110:deffffdddeefffffddeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 111:ddfffeddffffeeddeeeeedddddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 112:edededed4e4e4e4de4e4e4e4fefefefdefefefed4e4e4e4de4e4e4e4fefefefd
-- 113:e4ede4edff4fff4ee4efe4edfe4efe4ee4efe4edfe4efe4ee4efe4edfe4efe4e
-- 114:ddddddddbbbbbbbbbbbbbaaabbbbabbbbbbabbbbbbabbbbbaaaaaaaa11111111
-- 115:ddddddddbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaa11111111
-- 116:ddddddddbbbbbbbbaaabbbbbbbbabbbbbbbbabbbbbbbbabbaaaaaaaa11111111
-- 117:11aaa11111aaa11111aaaa1111aaaaaa11aaaaaa111aaaaa1111111111111111
-- 118:11aaa1111ddddd11abbbbba1abbbbba1abbbbba1abbbbba11aaaaa1111aaa111
-- 119:11aaa1111ddddd11abbbbba1aaaaaaa1abbbbba1abbbbba1aaaaaaa11abbba11
-- 120:aaaaaaaaaaaaaaaaaaaaaaaaddddddddeeeeeeedeeeeeeedeeeeeeedeeeeeeed
-- 121:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 122:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaabeaaaaaaaaaaaaaaaaaaaaa
-- 123:11dddddd1fffffffeeeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 124:dddddd11fffffff1eeeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 125:ddddddddffffffffeeeeeeeeddddddddddddddddbbbbbbbbbbbbbbb1bbbbbb11
-- 126:ffffddddfffffffdeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeed
-- 127:ddffffffffefffffeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeed
-- 128:ededededf4f4f4f44f4f4f4efefefefdefefefeff4f4f4e44f4f4f4dfefefefe
-- 129:ed4ded4df4fff4feef4fef4df4fef4feef4fef4df4fef4feef4fef4df4fef4fe
-- 130:11111111effc66feff4444fff434434ff444444ff443344fff4444ffeffffffe
-- 131:daeeeeadaadbbbaaed4444baeb4444baeb4444baeb4444a7aabbba77ea77777d
-- 132:daeeeeadaadbbbaaed9999baeb9999baeb9999baeb9999a7aabbba77ea77777d
-- 133:eeeeeeeeddddddddddddddddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaa
-- 134:dddddddabbbbbbadbbbbbaddbbbbadddbbbaddddbbadddddbaddddddabbbbbbb
-- 135:dedededdefefffffdefffeeeeeffeddddefeddddeefeddbbdefedbbbeefedbbb
-- 136:111defdd111defde111dffddffffeedeeeeeedddddddddbebbbbbbbdbbbbbbbe
-- 137:ddedededfffffefeeeefffeddddeffeeddddefedbbddefeebbbdefedbbbdefee
-- 138:ddeabdddddeabdddeeeabeeeddeabdddddeabdddddeabdddddeabdddddeabddd
-- 139:ddddddddddddddddeeeeeeeedddddddddddddddddddddddddddddddddddddddd
-- 140:ddeddbddddeddbddddeddbddddeddbddddeddbddddeddbddddeddbddddeddbdd
-- 141:eddddddbdeddddbdddeddbddddeddbddddeddbddddeddbdddeddddbdeddddddb
-- 142:dedededeefefefaafefefaaaefefeaadfefeaaaaefdfaaadfddbeaadefebbbbb
-- 143:dedededeaaafefeddaaafefeddaaefeddaaaaefeddaaafdeddaafbddbbbbbbfe
-- 144:dfdfdfdffadddaeddeadaddbeddaddabdedaddbbdbdaaadbbaadbdabebbbbbba
-- 145:eeeeeeee45454545535353533636363668686868828282822a2a2a2aeeeeeeee
-- 146:effffffeff5555fff55cc55ffccccccff55cc55ff555555ff555555feffffffe
-- 147:daeeeeadaadbbbaaed6666baeb6666baeb6666baeb6666a7aabbba77ea77777d
-- 148:daeeeeadaadbbbaaed5555baeb5555baeb5555baeb5555a7aabbba77ea77777d
-- 149:dddddddabbbbbba1bbbbba11bbbba111bbba1111bba11111aa11111111111111
-- 150:addddddd1abbbbbb11abbbbb111abbbb1111abbb11111abb111111aa11111111
-- 151:ddfed111edfed111ddffd111edeeffffdddeeeeeebdddddddbbbbbbbebbbbbbb
-- 152:dedddddeedddddddeedddddebeeeeeebbddddddbbbbbbbbbabbbbbbaeaaaaaae
-- 153:11aaa11111aaa11111aaa111aaaaaaaaaaaaaaaaaaaaaaaa11aaa11111aaa111
-- 154:11aaa11111aaa1111aaaa111aaaaa111aaaa1111aaa111111111111111111111
-- 155:bbbbbbbbbabababaababababaaaaaaaaaaaaaaaa11222111112a211111a2a111
-- 156:11aaa11111aaa11111aaaa1111aaaaaa11aaaaaa111aaaaa1111111111111111
-- 157:111111111111111111111111aaaaaaaaaaaaaaaaaaaaaaaa1111111111111111
-- 158:dedbbbbbefefbbbbfefefbbaefefefaafefefebbefefefbbfefefeabefefebba
-- 159:bbbbbbedbbbbbefebbabefedaaaefefebbbfefedbbbbfefeababefedbababefe
-- 160:effffffef444444ff5ffff5ff555555feff3fffeeef666feeef8ffeeeeef88fe
-- 161:eeeeeeeeeeea0eeeee4444eee4ff44cee4f44ccee444c4cee44c4cceeeccccee
-- 162:fffffffdfeeeeeedfeeeaeedfeeeaeedfeeaaaedfeeaaaedfeeeeeeddddddddd
-- 163:eeeeeeeeedaaaadbeabbbbabeab00babeabbbbabedaaaadbeddddddbbbbbbbbb
-- 164:e9eff99ee99ffe9ee9eff99ee99ffe9ee9eff99ee99ffe9ee9eff99ee99ffe9e
-- 165:e553355ee553355ee553355ee553355ee553355ee553355ee553355ee553355e
-- 166:eeeeeeee444444444444444455555555555555554444444444444444eeeeeeee
-- 167:5351535174747471474747417414147147111741741114714711174174111471
-- 168:1115311113574351747114744711114774111174474747477411117447111147
-- 169:1535351117474741147114741741114714711174174111471471147117474711
-- 170:5353535074111474471111477411147447474741741111114711111174111111
-- 171:8888888889889889889989988888888898898888899888888888888888888888
-- 172:8888888888888888889889888889989988888888888888888988988888998888
-- 173:111111111111111111111111fffffe11effffed1eefffeddeefffeddeefffedd
-- 174:defffeeeffffeeeeeeeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 175:ebbbbbbebbddddbbbddeeddbbdeffedbbdeffedbbddeeddbbbddddbbebbbbbbe
-- 176:00000000000f000000ff0000000f0000000f0000000f000000fff00000000000
-- 177:00000000000ff00000f00f0000f00f0000f00f0000f00f00000ff00000000000
-- 178:e66ff66ee66ff66ee66ff66ee66ff66ee66ff66ee66ff66ee66ff66ee66ff66e
-- 179:eeeeeeee6666666666666666ffffffffffffffff6666666666666666eeeeeeee
-- 180:eeeeeeee99999999e9e9e9e9ffffffffffffffff9e9e9e9e99999999eeeeeeee
-- 181:eeeeeeee555555555555555533333333333333335555555555555555eeeeeeee
-- 182:e445544ee445544ee445544ee445544ee445544ee445544ee445544ee445544e
-- 183:1351115314711174174111471474747417474747147111741741114714711174
-- 184:1311115114711471174117411471147111474711111471111117411111147111
-- 185:1353535154747471471111111474747111111147111111744747474774747471
-- 186:1113511111147111111741111114711111174111111471111117411111147111
-- 187:5353535374747474111741111114711111174111111471111117411111147111
-- 188:bdbdbdbddfdfdfddededededdedededdededededdedededdededededdedededd
-- 189:ddddddddfffffffdeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeed
-- 190:eeeeeeeeebdbdbdbedbdbdbdebabdbdbed0dbdbdebdbdbdbedadadbdbb0abbbb
-- 191:beeeeeeebebdbdbbbedbdbdbbebdbabbbedbd0dbbebdbdbbbedadadbbebda0bb
-- 192:0000000000000000003300000f33ff000f000330033ff3300330000000000000
-- 193:00000000000000000000330033ff330033000f000ff33f000003300000000000
-- 194:0000000000000000000000000004400000044000000000000000000000000000
-- 195:000000000000000000c0c0000c000c000000000000c00c000000c00000000000
-- 196:000000000a00a000000000a0b000000000000000000000000a0000a00000b000
-- 197:009990000988f90009f8890009f98111099881010998f1110099910000000100
-- 198:aaaaaaaaabbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadbaaaaaadd
-- 199:aaaaaaaabbbbbbbaaaaaaabaaaeeeebaaaedddbaaaedddbadaedddbabaedddba
-- 200:1135353117474741741111114711111174111111471111111474747111474741
-- 201:11111111ee111111bbee1111bbbbee11bbbbbbeebbbbbbbbbbbbbbbbaaaaaaaa
-- 202:3347477733747477334747773374747733474777337474773347477733747477
-- 203:7777777777777777777777777777777777777777777777775555555577777777
-- 204:7777777755555555777777777777777777777777777777777777777777777777
-- 205:7777775777777757777777577777775777777757777777577777775777777757
-- 206:e0e0adadebdb0aaaedbdd000ebdbd000edbda005ebda0000ed000000ebbbbbbb
-- 207:bada0b0baaa0dbdb000dbdbb000bdbdb500abdbb0000abdb000000bbbbbbbbbb
-- 208:effffffef555555ff5ffff5ff555555feff5fffeeef555feeef5ffeeeeef55fe
-- 209:222222222e2ef2f22f2fe2e22e2ef2f22fefe2d22ef2f2f22f2fe2e222222222
-- 210:0000000000000000000000000040004004540454453545355300530000000000
-- 211:0000000000000000000000000400040045404540535453543005303500000000
-- 212:00000000000000000000f0f0f0f08f808f8f989f989899989999999900000000
-- 213:ffffffff0000000f0f0f0f0f0000000ff00fffff0ff000000f00000000000000
-- 214:aababadbaabbaaddaababadbaabbaaddaababadbaabbaaddaababadbaaaaaaaa
-- 215:daedddbabaedddbadaedddbabaedddbadaedddbabaedddbadaebbbbaaaaaaaaa
-- 216:addddddddabbbbbbddabbbbbdddabbbbddddabbbdddddabbddddddabbbbbbbba
-- 217:11111111111111111111111111111111eeeeeeeebbbbbbbbbbbbbbbbaaaaaaaa
-- 218:3333333333333333474747477474747447474747747474747777777777777777
-- 219:44ededed4ffffffeefefefedfefefefeefefefedfefefefeefefefedfefefefe
-- 220:ededed44fffffff4efefefedfefefefeefefefedfefefefeefefefedfefefefe
-- 221:7577777775777777757777777577777775777777757777777577777775777777
-- 222:11111111eeeeeeeeddddeebbddeebbbbeebbbbbbbbbbbbbbbbbbbbbbaaaaaaaa
-- 223:ddddddddbbbbbbbddbdbdbddbdbdbdbddbdbdbddbdbdbdbddbdbdbddbdbdbdbd
-- 224:eeffffeeeffc66feff4444fff434434ff444444ff443344fff4444ffeffffffe
-- 225:eeeeeeeeeeea0eeeee3333eee3ff3111e373315ee3735111e3353551ee555111
-- 226:eeeeeeeeeeea0eeeee3333eee3ff335ee3f3355ee333535ee335355eee5555ee
-- 227:eeeeeeeeee5555eee55775cee5577111e555515ee555c111e5c5e15eeeeee111
-- 228:eeeeeeeeee4444eee44774cee4477111e444415ee444c111e4c4e15eeeeee111
-- 229:0000000000033000000330000006600000600600055664400550044000000000
-- 230:aaaaaaaaabbbbbbbabaaaaaaabeeeeaaabdddeaaabdddeaaabdddeadabdddeab
-- 231:aaaaaaaabbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabdaaaaaaddaaaaaa
-- 232:dddddddddbababaadabababadbababaadabababadbababaadabababaaaaaaaaa
-- 233:11111111111111ee1111eebb11eebbbbeebbbbbbbbbbbbbbbbbbbbbbaaaaaaaa
-- 234:4747474774747474474747477474747447474747747474744747474774747474
-- 235:ededededfffffffeefefefedfefefefeefefefedfefefefe4fefefed44fefefe
-- 236:ededededfffffffeefefefedfefefefeefefefedfefefefeefefefe4fefefe44
-- 237:ddddddddddbbbbdddbbbbbbdbaaaaaabdddddddddbbbbbbddbbbbbbdbaaaaaab
-- 238:ddddddddfffffffdf333333df333333df333333df333333df333333df333333d
-- 239:bdbdbdbdfbfbfbfbefefefedfefefefeefefefedfefefefeefefefedfefefefe
-- 240:eeeeeeeeeeffffeeef9898fef0898111f808814ff9a9a111faaaaaa1fafaf111
-- 241:00fffff00f555c3f0f575c3ff5575111f5c551cff3cf51110f3c53f100fff111
-- 242:00fffff00f555c3f0f575c3ff55756cff5c566cff3c666660f3c66f000fff600
-- 243:00fffff00f555c3f0f575c3ff55756cff5c5566ff3c666660f3c566000fff600
-- 244:00fffff00f555c3f0f575c3ff55756cff5c5666ff3c666660f3c56f000fff600
-- 245:00fffff00f555c3f0f575c3ff55756cff5c556cff3c666660f3c666000fff600
-- 246:abdddeadabdddeababdddeadabdddeababdddeadabdddeababbbbeadaaaaaaaa
-- 247:bdababaaddaabbaabdababaaddaabbaabdababaaddaabbaabdababaaaaaaaaaa
-- 248:eeeeeeeeedbdbdbbebdbdbdbedbdbdbbebdbdbdbedbdbdbbebdbdbdbbbbbbbbb
-- 249:11111111111111111111111111ffffff1effffeeeefffdddeefffbbbeefffbbb
-- 250:111111111111111111111111ffffee11efffeed1ddfffeddbbfffeddbbfffedd
-- 251:0000000000000000000e000000efe000000e000000000000000000f000000000
-- 252:000000d000000ded000000d0000d0000000e00000defed00000e0000000d0000
-- 253:22222222f2f2f2f2e2e2e2e2f2f2f2f2e2e2e2d2f2f2f2f2e2e2e2e222222222
-- 254:ede44ded44f44f4444e44f4444444444efe44fed44f44e4444e44f4444444444
-- 255:ededededfffffffeefefefedfefefefeefefefedfefefefeefefefedfefefefe
-- </TILES>

-- <SPRITES>
-- 000:66666ffc66cffccc6ffcccccfccccc5c6fcc7755fcc7bf7a6fa7fb7566f57755
-- 001:ff666666ccffc666ccccf666c5cccf66c775ccf67bf75f667fb7af665775fc66
-- 002:6666ffcc666fcccc6cfccccc66fccc5c6fcc577cfcc57bf76faa7fb76cf55775
-- 003:cff66666cccffc66cccccf66c5ccf6665577cf6657bf7cf6a7fb7f6655775f66
-- 004:6666666666666f6f6666fcfc666fcccc666ffccc66fccccc666fcccc666fcfc5
-- 005:ff66f666ccffcf66ccccfcf6ccccccf6ccccccf6ccc57f665c5775f6555575f6
-- 006:6666666f66666cfc6666cfcc666ffccc66fccccc666fcccc666cfcc5666fcccc
-- 007:ccfcfc66cccccfc6ccccccf6ccccccf6ccc57f665c5775f6555575f655555f66
-- 008:66666cff666fffcc66fccccc666fcccc66fccccc66cfcccc66f55ccc66f5cccc
-- 009:ffff6666ccccf666cccccf66ccccccf6c5ccccf6ccccccf6ccccc55fcccccc5f
-- 010:6666666666666cff666cffcc666fcccc666fcccc66fccccc666fcccc66f55ccc
-- 011:ff666666ccfff666cccccf66cccccf66ccccccf6c5ccccf6ccccccf6ccccc55f
-- 012:eeeeeeeeeeeeeeffeeeeffcceeefcccceefccccceefccc5cefccc55ceef5c575
-- 013:eeeeeeeeffeeeeeeccffeeeecc1cfeeeccc1cfeec5c1cfee551cccfe575c5fee
-- 014:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 015:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffeeeee
-- 016:66ce55cc666f7d556ff7ef7bf55bff7bf5ef777b6f77722266ff00ff6666ff66
-- 017:555af6665dffaf667f55fa667f5aaff6b7feaadf277feaad2ae7feaaf00f6fea
-- 018:666f555c66f77f556f55ff7b6f55ef7b66f7f7bb6f7ff22266f77aaf666f00f6
-- 019:c55ecfff5ff7ffda7fef7daa7ffd5adfa7bda5ff2a777ff6f00ff6666ff66666
-- 020:6666fccc66666fce66ffff7f6f77e57d66ff7edd6666f777666f00dd6666ffff
-- 021:55555f66d555f666ffbbf6667ff55f6677755f66daaaf666d77f66666f00f666
-- 022:6666ffcf66666f7f666ff7df66f77dff6f7dd55766f7755b666ff0776666f0ff
-- 023:f555fff6fb77baf67bbd5bf67bb75f667dbff666bdddf666fff00f66f66ff666
-- 024:af6ff5ccf5f6fffc6fa7eedd6fba7e7d6fbad7defbbaa7776ffb7fbb666ff6f0
-- 025:cccccff6fccfdf66ffddef66eed7eef6ffedd55f7777775fbff00ff60f6f6666
-- 026:66f5cccc6666faaa666fdeaa66feaaba6f55abff6f55f7776aff600f66666ff6
-- 027:cccccc5fccccff66ccfdf666fd775f66ffdde7f677777e7fffbbb7f66f00ff66
-- 028:eef55555eeefbe5ceefeff55eefe7fd1eef7ffddefeff71bfe777b1b0fffb1bf
-- 029:55555fee555bfeee15ffefeeddf1efeed11f7efebbb7ee7efbbb77fe0fbbbfee
-- 030:eeeecfffeeeefccceeefcccceeefcccceefccccceefccccceefccccceecffccc
-- 031:cccfceeeccccfeeeccccfeeecc1ccfeec111cfeeccc1cceecccc1fceccccf11e
-- 032:66666ffc66cffccc6ffcccccfccccc5c6fcc7755fcc7bf7a6fa7fb7566f57755
-- 033:ff66666fccffc6faccccffdac5cccdaac775daab7bf7aabf7fb550f6577a5f66
-- 034:6666666666666ffc66cffccc6ffcccccfccccc5c6fcc77c5fcc7bf7afca7fb75
-- 035:66666666ff666666ccff6666ccccf66655ccff665775cf667bf75cf67fb7af1f
-- 036:66666ffc66cffccccffcccccfccccc5cffcc77c5aac7bf7adae7fb75ddae7755
-- 037:ff666666ccffc666ccccf6665ccccf665775ccf67bf75fc67fb7ac665775ff66
-- 038:6666666666666ffc666ffccc66fccccc66fccc5c6fcc77556fc7bf7a6fa7fb75
-- 039:66666666ff666666ccffc666ccccf666c5cccf66c775ccf67bf75ccf7fb7acf6
-- 040:666666666666666666666666ff6666667ef66666b7ef6666b7ef6666bb7efcff
-- 041:66666666666666666666666666666666666666666666666666666666ffff6666
-- 042:66666666666666666666666666666666661661666666666166666666666666d6
-- 043:666666666666666666666666666666666666666616666666116666666f116666
-- 044:666666666666666666666666666666666666666666666666666666666666fcff
-- 045:6666666666666666666666666666ff66666feaf666feabf66feaabf6ffaabf66
-- 046:6666666666666666666666666666666666666666666666616666611166661116
-- 047:6666666666666666666666666666666666161666161666661666666666666666
-- 048:66ce555c666f7d5566f7ef7b6f5bff7bf5ef777b6ff77222667f22ff66f00f66
-- 049:55ffaf665dddf6667faf66667ffaf666b7ffaf66277eef662ae7f666f00f6666
-- 050:ccc57755ffce55cc6fff7dccf55bff7ff5ef77556f77725b66ffbaee66f0aeee
-- 051:5775fd1f555fa1f65daad1f6eefe1f66bff11f66ff11f666f11ff66611f00f66
-- 052:fddae55c6ffdad5c66f7a5ff6f5b55dff5ef777d6ff7722b667f22ff66f00f66
-- 053:c55f6666cdf766667fff6666ffbf6666dffdf666bd7e7f66fdb7ddf66f00ff66
-- 054:66f57755ffce555cf1fe7d5cf11fdd7ff51fff556f711fe566ff1ffe66f0011e
-- 055:5775cf66c55fccf6cdf7ff66ffb66666bbfd6666dd7e7666ddb7f666eddb6666
-- 056:fb7ecfcc6fbccccc66ffcccc66fccccc66cfcccc66f55ccc6f75cccc66f7f5cc
-- 057:ccccf666cccccff6cccccccfc5ccccf6ccccccf6ccccc55fcccccc5fcccccff6
-- 058:66666ecc6666ffcc6660cccc66fccccc66fccccc6fcccccc66ff55cc666ffccc
-- 059:fcf61166ccccf116cccccf16cccccf11cc5cccf1ccccccf1cccccc51ccccccc1
-- 060:666fcfcc66fccccc66ffcccc66fccccc66cfcccc66f55ccc66f5cccc666ff5cc
-- 061:ccccf666cccccff6cccccccfc5ccccf6ccccccf6ccccc55fcccccc5fcccccff6
-- 062:66611fcf666fcccc661fcccc661fcccc611ccc5c61fccccc115ccccc10cccccc
-- 063:cce66666ccff6666ccccc666ccccccf6ccccccf6cccccccfccc55ff6ccccff66
-- 064:6666666666666666666666666666666666666666666666666666666666666666
-- 065:6666666666666666666666666666666666666666666666666666666666666666
-- 066:afbaaf116faa1111f11111ff66e6666666666666666666666666666666666666
-- 067:1f666666f6666666666666666666666666666666666666666666666666666666
-- 068:6666666666666666666666666666666666666666666666666666666666666666
-- 069:6666666666666666666666666666666666666666666666666666666666666666
-- 070:66666e116666666e6666666e6666666666666666666666666666666666666666
-- 071:1efdb666111fbb66e61111666666666666666666666666666666666666666666
-- 072:66f7effc666feedd666f7fff66f7f77e6f777aa766ffaaaa666fddff66f00f66
-- 073:fccfdf66ffddef66eed7eef6ffed755f777eee5fbb7707f6ffbbf66666f00f66
-- 074:66fccccc66f0777c66f7dd776f7d7add6f77faaa66ffedaa66fdddff6f00ff66
-- 075:cccccf11cfccf111eed755f677ed55f6d77e7f66bbd7f606fffbbf66666f00f6
-- 076:6666f7fc666f7edd666f7fff66f7f77e6f777aa766ffaaaa666fddff66f00f66
-- 077:fccfdf66ffddef66eed7eef6ffed755f777eee5fbb7707f6ffbbf66666f00f66
-- 078:101fcccc11dfccfc111b7dee1e75de77e7bbe77d7bff7dbbfffbbfff6f00f666
-- 079:ccccccffc777055f77dd755fdda7d7f6aaaf77f6aadeff66ffdddf6666ff00f6
-- 080:666666666666666f66666cfc6666cfcc666ffccc66fccccc666fcccc666cfcc5
-- 081:ff6f6666ccfcfc66cccccfc6ccccccf6ccccccf6ccc57f665c5775f6555575ff
-- 082:6666666666666666666fff6666feaf666feabf66feabf666eabf6666aff66666
-- 083:666666666666666666666f6f6666fcfc666fcccc666ffccc66fccccc666fcccc
-- 084:66666666ff66f666ccffcf66ccccfcf6ccccccf6ccccccf6ccc57f665c5775f6
-- 085:66666666666666666666666666666666661ff66666fa1f66666fd1f66666fd1f
-- 086:666666666666666f66666cfc6666cfcc666ffccc66fccccc666fcccc666cfcc5
-- 087:ff6f6666ccfcfc66cccccfc6ccccccf6ccccccf6ccc57f665c5775f6555575ff
-- 088:666666666666666666666666666666666666666666666666f6666666af666666
-- 089:666666666666666666666f6f6666fcfc666fcccc666ffccc66fccccc666fcccc
-- 090:66666666ff66f666ccffcf66ccccfcf6ccccccf6ccccccf6ccc57f665c577566
-- 091:66666666666666666666666666666666666f16666666f1f666666fef66666e1f
-- 092:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 093:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffeeeee
-- 094:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeefefe
-- 095:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffeeeeeefffeeeee
-- 096:666fcccc666fffcf66f55aaa66f55ffe66f7dddd666f77006666fffd6666f00f
-- 097:55555ff5f555fef5f7bbefffe7bbff6677dbff66bbd7f666dd777666fffff006
-- 098:f666666656666666666666666666666666666666666666666666666666666666
-- 099:666fcfc566f55ccc66f55fce66ff7fff6f77f77e66f77fed666ff777666f00ff
-- 100:555575f65555cf66d55ceff6f77edeefe7bedf557abdff5add777fffffff00f6
-- 101:666ffe1f66feef116feffe11fddf111fe1111116111111f6f1111f666ffff666
-- 102:666fcccc666fffcf66f55aaa66f55ffe66f7dddd666f77006666fffd6666f00f
-- 103:55555f6df555f6faf7bbe5abe7bbf55f77dbfff6bbd7f666dd777666fffff006
-- 104:daf66666aaf66666baf66666faf666666f666666666666666666666666666666
-- 105:666fcfc566f55ccc66f55fce66ff7fff6f77f77e66f77fed666ff777666f00ff
-- 106:555575665555cf66d55ce5fff77ed5a1e7bedfaa7abdf61add777f61ffff00ff
-- 107:6666fe1f66f1be1f6f1de1f6fddf1f66ddd11f66f11ff66611f66666ff666666
-- 108:eeee4fffeeeef444eeff4cffef4f4444f44ccc44ef4c44ffeefcc44feecf444c
-- 109:44cf4eee44ccfeee444cf4ee4c14cfeef1114feef441cc4efff41fcefffcf11e
-- 110:eeefcfffeeeffcffeee44ffcee44f4fceffffc4ceffcccc4effcccc4eecffccc
-- 111:cccfceeecffffeeeccfc44eecc1c444ec414cfee4444ccee444c1fce444cf11e
-- 112:00000000000ff00000fddf000fdfbbf00fdbbaf000fbaf00000ff00000000000
-- 113:000000f00000ffef000feedf00feedf000fedf000fdff0000df0000000000000
-- 114:0000000000f6f0000f644f00f54434f0fc5544f0fcc44cf00fccff0000ff0000
-- 115:00000000000ff00000f88f000f8f99f00f8997f000f97f00000ff00000000000
-- 116:eeeffeeeefffffefff44c4fece4fffff44f444fffff4ff4f4ff4c11ff444f4fe
-- 117:eeeeeeeeeeffffefef44c4fece4ffceffceccc4ff4cf4c4fffc4c4fff4f4f4fe
-- 118:eeeeeeeeeefeeeeeee4eeefeeeeffeeefeeccceee4cf4c4fffc4c4fff4f4f4fe
-- 119:eeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff444444ff4f4f4fe
-- 120:eeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff444444fef4f4f4f
-- 125:0004000000004000000400000044040004444040044544400045540000044000
-- 126:0004000000400000004000000004040000044400004454000045540000044000
-- 127:0040000000004000000040000040040000044400004544400045544000044400
-- 128:11aaaaaa1a00f77fa0000ff0a0000000a0000000a0000000a0000ff0a000f55f
-- 129:abbbba110f7f7fa100f0f7fa0000f7fa00ffff7a0f77f0faf7777f0af7777f0a
-- 130:11aaaaaa1a000000a0000fffa000f5ffa00fff00a00f0000a0f5f000a00f0000
-- 131:abbbba11ff0fffa15ff55f5aff5555fa0f5555fa0ff55ffa000fff0a0000000a
-- 132:00aaaaaa0a000000a0000000a0000000a0000000a000000fa00000ffa0000ff4
-- 133:abbbba0000ffffa000feeefa0ffeeefaff4eeefaf444fffa444ff00a44ff000a
-- 134:00aaaaaa0a000000a0000000a0000000a0000000a000000fa00000ffa0000ffe
-- 135:abbbba0000ffffa000feeefa0ffeeefaffeeeefafeeefffaeeeff00aeeff000a
-- 136:11aaaaaa1a00ff00a00f33f0a00fccf0a00fccffa00fcccca0fccc33afccc3c3
-- 137:bbbbba1100ff00a10f33f00a0fccf00affccf00accccf00a33cccf0acc3cccfa
-- 138:11aaaaaa1a00ff00a00f88f0a00f77f0a00f77ffa00f7777a0f77788af777878
-- 139:abbbba1100ff00a10f88f00a0f77f00aff77f00a7777f00a88777f0a778777fa
-- 140:111111111111111111111111555111115333111153333155133315331111153f
-- 141:1111111111111111111111111111555111133351513333513513331135111111
-- 142:11111111111111111555111115333115153333531133115f1111115311111315
-- 143:11111111111111111111155555113335f3533335ff511331f351111155131111
-- 144:a00f5555a00f5555a00ff55fa0f5fff0a00f0000a0f5f0f01a0f0f5f11aaaaaa
-- 145:ff77f00af0ff000a0000000a0000000a0000000a0000000a000000a1aaaaaa11
-- 146:a0000000a0fff000aff77ff0af7777f0af7777ffa7f77ff71afff0ff11aaaaaa
-- 147:0000f00a000f7f0a0000f00a00fff00aff7f000afff0000a000000a1aaaaaa11
-- 148:a00fff44a0f44444af44444faf44444faf44444faf4444f0aaffff00aaaaaaaa
-- 149:4ff0000aff00000af000000a0000000a0000000a0000000a000000aaaaaaaaaa
-- 150:a00fff99a0f99999af99999faf99999faf99999faf9999f0aaffff00aaaaaaaa
-- 151:eff0000aff00000af000000a0000000a0000000a0000000a000000aaaaaaaaaa
-- 152:afcc3cc3afcc3cc3afcc3cccafccc3ccafcccc33afcccccc1affffff11aaaaaa
-- 153:ccc3ccfa33c3ccfaccc3ccfacc3cccfa33ccccfaccccccfaffffffa1aaaaaa11
-- 154:af778778af778778af778777af777877af777788af7777771affffff11aaaaaa
-- 155:777877fa887877fa777877fa778777fa887777fa777777faffffffa1aaaaaa11
-- 156:1111353311133155113311111133111111111111111115111111111111111111
-- 157:3531111151331111111331111313311111111111111111115111111111111111
-- 158:1111331111113311111111111111111111111151111111111111111111111111
-- 159:1113311113133111111111111111111111111111113111111111111111111111
-- 160:1111ffff111ffb3f11ffb33311fb333311fbcc3c11fe3c3311fe333311fe3eee
-- 161:ffff1111f3bff1113fbbff11333bbf11cc3bbf11cc3b3f1133333f11333eff11
-- 162:1111ffff111ffb3f11ffb33311fb333311fbcc3c11fe3c3311fe333311fe3eee
-- 163:ffff1111f3bff1113fbbff11333bbf11cc3bbf11cc3b3f1133333f11333eff11
-- 164:1111ffff111ffb3f11ffb33311fb333311fbc33c11fe3c3311fe333311fe3eee
-- 165:ffff1111f3bff1113fbbff11333bbf11333bbf11cc3b3f1133333f11333eff11
-- 166:eeeeeeeeeeeeeeeeeeeeeee3eeeee533eeee333feee333f7eee333f7eee533f7
-- 167:eeeeeeeeeeeeeeee333eeeee3335eeeeff333eee77f33eee77f33eee77f333ee
-- 168:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333eeee3333eee3333feee333f7
-- 169:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3353eeee33333eeeff333eee77f33eee
-- 170:eeeeeeeee33eeeeeee3eeeeeeee3e333eeee333feee333f5eee333f4ee3333f4
-- 171:eeeeeeeeeeeeee3e3eee33ee3333eeeeff333eee44f33eee44f33eee4cf333ee
-- 172:eeeeeeeeeeeeeeeeeeeeeee9eeeeee99eee9e999eeeee998eeeee998eee9e998
-- 173:eeeeeeeeeeeeeeee9ee9eeee999eeeee899e9eee899e9eee8899e9ee8899e9ee
-- 174:ededededfffffffeefefefe3fefefe33efefe335fefe3355ccec35cccefc35c5
-- 175:ededededfffffffeefefefed3efefefe33efefed533efefe5ccceccd5c3cfcfc
-- 176:11f3ecce111fe33e11fffeee1f00ffeef33000dd1f33000011ff000011f00000
-- 177:e3edf111eeedff11edff0f11dff000f1000033f100033f110000f11100000f11
-- 178:11f3ecce111fe33e1111feee1fff00eeff0000ddf33000001f33000011f00000
-- 179:e3edf111eeedf111edff1111d00fff11000000f1000033f100033f1100000f11
-- 180:11f3eccef11fe33e3ffffeeef300ffee330000ddfff00000111f0000111f0000
-- 181:e3edf111eeedff11edffff11dff00ff1000000f100000f1100003f11000000f1
-- 182:eee5333feee55353eeee5553eeeee5c5eeeeee5ceeeeeeeeeeeeeeeeeeeeeeee
-- 183:ff3333ee33335eee55353eeecc55eeeeccceeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 184:ee3333f7ee35333feee55533eeee5c55eeeeeecceeeeeeeeeeeeeeeeeeeeeeee
-- 185:77f333eeff3335ee33535cee55555eeecc55eeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 186:ee35333fee555533eee35533ee355555ee5ee55ceeeee5eeeeee5ceeeeeeeeee
-- 187:ff3335ee333355ee333533ee55c53eeeccec5eeeeeeeeceeeceee55eeeeeeeee
-- 188:eee9e998eee99998eeee9998eeeee999eee9e999eee99e99eeeeeee9eeeee9ee
-- 189:8899ee9e8899e9ee8899eeee8899e9ee899eeeee999e9eee9ee9eeeeeeeeeeee
-- 190:cdec35cccffc35c5ccecc5ccfefe3355efefe335fefefe33efefefe3fefefefe
-- 191:5ccceccd5c3cfcfc5c3cecec533efefe33efefed3efefefeefefefedfefefefe
-- 192:11111ff11111f55f111f5555111f553311f5553311f553c31f55c3331f5cc333
-- 193:1ff11111f55f11115555f11135555f1133555f11c33555f1335c55f1333cc5f1
-- 194:11111ff11111f55f111f5555111f553311f5553311f553c31f55c3331f5cc333
-- 195:1ff11111f55f11115555f11135555f1133555f11c33555f1335c55f1333cc5f1
-- 196:11111ff11111f55f111f5555111f553311f5553311f553c31f55c3c31f5cc333
-- 197:1ff11111f55f11115555f11135555f1133555f11c3355f11c35555f13335cf11
-- 198:eee4eeeeee4e4eeeeeee44eeeee44e44eee44444e444c44f4ecc44f7eeec44f7
-- 199:eeeeeeeeeeeee4eee4ee4eee444ee4ee4444eeeeff444ee477f44e4e77f4444e
-- 200:eeeeeeeeee4eeeeeeee4ee4eee4ee444eeee44444ee4444fe4e444f7e44444f7
-- 201:eeee4eeeeee4e4eeee44eeee44e44eee44444eeeff4c444e77f4cce477f4ceee
-- 202:eee4eeeeee4e4eeeeeee44eeeee44e44eee44444e444c44f4ecc44f7eeec44f7
-- 203:eeeeeeeeeeeee4eee4ee4eee444ee4ee4444eeeeff444ee477f44e4e77f4444e
-- 204:eeeeeee9eeeee9eeeeeeeee9eeeeee99eeeeee99eeeee999eeeee998eeeee998
-- 205:9eeeeeee999eeeee9999eeee999e9eee999eeeee8999eeee8899eeee8899eeee
-- 206:eeeeeee9eeeeee99eeeee9e9eeeee999eeee9999eeeee999eee9e998eee99998
-- 207:eeeeeeeee99eeeee9ee9eeee999e9eee999eeeee899eeeee8899eeee8899eeee
-- 208:1f55c3cc11f555331f55c7ff1f3f777ff3377c771fffcccc1111fccc11111f00
-- 209:333c555f335755cff7777cf177777f1177c777f1cccc73f1fffccf11f11f00f1
-- 210:1f55c3cc11f5553311ff557f1f3f7777f3377c771fffcccc11fccfff1f00f11f
-- 211:333c555f335755cfff77c55ff7777ccf77c77ff1cccc3f11cccff11100f11111
-- 212:1f5553cc11f5c3331f5cc7ff1f3f777ff3377c771fffcccc1111fccc1111100f
-- 213:335555f135575c5ff775ccf1777c7f1177c77ff1cccc3ff1fccfff11f00f1111
-- 214:ee4444f7e444444f4ee444444e44e444e44e44c4eeee44e4eeeee4eeeeeeeeee
-- 215:77f4c4eeff44ccee4444cceec4c44eee4ee44eee4e44eeeee4eeeeeeeeeeeeee
-- 216:ee4c44f7eecc444feecc4444eee44c4ceee44ee4eeee44e4eeeeee4eeeeeeeee
-- 217:77f444eeff44444e44444ee4444e44e44c44e44e4e44eeeeee4eeeeeeeeeeeee
-- 218:ee4444f7e444444f4ee444444e44e444e44e44c4eeee44e4eeeee4eeeeeeeeee
-- 219:77f4c4eeff44ccee4444cceec4c44eee4ee44eee4e44eeeee4eeeeeeeeeeeeee
-- 220:eeeee998eeeee998eee9e998eee9e999eeee9999eeee9e99eeee9ee9eeeee9ee
-- 221:8899eeee8899eeee8899eeee8899eeee999eeeee99eeeeee99eeeeeeeeeeeeee
-- 222:eeeee998eeeee998eeeee998eeeee998eeeee998eeeeee99eeeeeee9eeeee9e9
-- 223:8899eeee8899eeee8899eeee8899eeee899eeeee89e9eeee999eeeee99e9eeee
-- 224:eeeeeeeeeeffffeeef8989fef098980ff809808ffa9a9a9ffaaaaaaffafafafe
-- 225:eeeeeeeeeeffffeeef9898fef089890ff908909ffa8a8a8ffaaaaaafefafafaf
-- 226:eeeeeeeeeeeeeeeeeeffffeeefdadafef0adad0ffa0aa0affaaaaaaffafaffaf
-- 227:eeeeeeeeeeea0eeeee3333eee3ff335ee373375ee373575ee335355eee5555ee
-- 228:eeeeeeeeeeeeeeeeeeea0eeeee3333eee3ff335ee373375ee335355eee5555ee
-- 229:eeeeeeeeeeeeeeeeeeea0eeeee4444eee4ff44cee47447cee444c4ceeeccccee
-- 230:11111fff1111f33e111f3333111f3c3c111f3333111fd333111fdeee11feedce
-- 231:fff11111e3ef11113e3ef111c3eef111333eaf113ee3af11ee33af11eeeaf111
-- 232:11111fff1111f33e111f3333111f3c3c111f3333111fd333111fdeee11feedce
-- 233:fff11111e3ef11113e3ef111c3eef111333eaf113ee3af11ee33af11eeeaf111
-- 234:11111fff1111f33e111f3333111f3c3c111f3c33111fd333111fdeee11feedce
-- 235:fff11111e3ef11113e3ef111c3eef111c33eaf113ee3af11ee33af11eeeafff1
-- 236:1111111111144441114111441111141111114c44111444cc144c444f141c44f0
-- 237:111111114441111141411111cc4444114441141144c11141f4cc14410f444111
-- 238:1114441111441144141114441411cc4c114144441444c4cc44cc444f4c1144f0
-- 239:111111114114111144444411444cc4414444c4414c44c411f44444110f444411
-- 240:00fffff00f555c3f0f575c3ff55755cff5c55ccff3cf5c3f0f3c53f000ffff00
-- 241:0000000000fffff00f555c3f0f57553ff5555cf0f5c55ccff33c533f0fff0ff0
-- 242:00fffff00f555c4f0f545c4ff55455cff5c55ccff4cf5c4f0f4c54f000ffff00
-- 246:11fbeeee11f7eeee1f777eb71f77777711f37777111f77771111f777111f000f
-- 247:eeeb7f11ebb777f1bb7777f177777f1177773f117777f111f777f1110000f111
-- 248:11fbeeee11ffdeee1ff77de71f77777711777777111377771111f777111f000f
-- 249:eeebff11eeb77ff1eb7777f17777771177777f1177773111f777f1110000f111
-- 250:11fbeeee1f3bbeee1f777bb711f77777111f7777111f77771111f777111f000f
-- 251:eeeb73f1ebb777f1bb777ff17777ff117777f1117777f111f777f1110000f111
-- 252:144444f01144c44f1114cc441111444411411441114411111114111111144111
-- 253:0f444441fc4cc444444c1114cc4c14411c141411111141111111411111111111
-- 254:44c144f0144c144f11141c4c111411c411441111441111111111111111111111
-- 255:0f4c4441fc4c4414c44444114c11141411414144144111111111111111111111
-- </SPRITES>

-- <MAP>
-- 000:0000000000000000a1f4f4f4f4f4f4f4a1000000d5e5e5b9f50000000000000000000000000000000000000000000000000000000000000000000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e476000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c241000000000000000000000040c2c2c2c2c2410000000040c2c2c2c2c2c2c24100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:0000000000000000a1e3b0000000c0e3a1c2c2c241000056000000000040c2c2c2c2c2c2c2c2c2c2c2c2c241000000000000000000000000000000850101010101010101010101010101010101010101950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d3d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a10000000000000000000000a1f4f4f4f4f4a100000000a1f4f4f4f4f4f4f4a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:9fa4a4a4af000000a1e30000000000e3f4f4f4f4a1c2c274c2c2c2c2c2a1f4f4f4f4f4f4f4f4f4f4f4f4f4a1c2c2c2410000000000000000000000855353535353535353535353535353535353535353950000000000000000000000000000000000000000000000000000000000000000000000000000000000000055a1d3b0000000c0e3e3e3e3e3e3a5a5f3e3e3d3d3e3e3e3e3e3e3e3e3e3e3e3b00000000000c0e3d3a1c2c2c2c2c2c2c2c2c2c2c2a1d3e3e3e3d3a1c2c2c2c2a1d3d3e3e3e3e3d3a1c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c24100000000000000000000
-- 003:85fdfdfd95d9d967a1e3b4d4d4d4c4e3d3f3e3d3f4f4f4f4f4f4f4f4f4f4d3e3a5e3e3e3e3e3e3e3e3e3d3f4f4f4f4a1000000000000000000000085ffffffffffffffffffffffffffffffffffffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000056a1d30000000000e3c1e2e3e3e3a5a5f3f2e2d3d3e3e3e3e3e3e3e3e3e3e3e300000000000000e3d3d3f4f4f4f4f4f4f4f4f4f4f4f4d3e3e3e3d3f4f4f4f4a1a1d3d3e3e3e3e3d3a1a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a100000000000000000000
-- 004:85fd63fd95000000a173526273737352d3f3e3d3d3e3e3e3e3e3e3f3e3d3d3e3a5e3900000000080e3e3d3d3e3e3e3a1000000000000000000000085ffffffffffff63ffffffffffffffffffffffffff950000000000000000000000000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4760000000000000056a1d3b4d4d4d4c4e3e3e3e3e3e3a5a5f3e3e3d3d3e3e3e3e3e3e3e3e3e3e3e3b4d4d4d4d4d4c4e3d3d3e3b00000c0e3e3e3e3e3e3d3d3e3e3e3d3d3e3e3e3a1a1d3d3e3e3e3e3d3a1a1e3e3b00000000000c0e3e3b00000c0e3f3a5e3e3e3e3e3e3e3e3e3e3e3e3e3a1c2c2c2c2410000000000
-- 005:85fdfdfd95000055a1ffffff0dffffffd3f3e3d3d3e3e3e3e3e3e3f3e3d3d3e3a5e3c5d4d4d4d4c6e3e3d3d3e3e3e3a10000000000000000000000851fffffffffff17ffffffffffffffffffffffffff950000000000000000000000000085ff0effffffff0e4affffffffffffff630808080863950000000000000056d30e0effffffff890101010142ffffffffffff890d0e09ffffffffffffff4affffffffffffffffffd3e300000000e3e3e3e3e3e3d30effffff0ed3e3e3e3d3d3850eff0eff0e95d3d3e3e300000000000000e3e300000000e3f3a5e3c1c1d0c1d0e3e3e3e3e3e3e3d3f4f4f4f4a10000000000
-- 006:e6e4e4e4f6000056a1ffffffffffffff49ffffffd3e3e3e3e3e3e3f3e3d363496308080808086349634963d3e3e3e3a1e4e4e4e4e4e4e4e4e4e4e4f6ffffffffffff17ffffffffffffffffffffffffff950000000000000000000000000085ffffffffffffff4affffffffffffffff1fffffffff950000000000000057d30e0effffffff890101010142ffffffffffff890e0e09ffffffffffffff4affffffffffffffffff49e3b4d4d4c4e3e3e3e3e3e3d309ffffff09d3e3e3e3d3d385ff0eff0eff95d3d3e3e3b4d4d4d4d4d4c4e3e3b4d4d4c4e3f3a5e3e3e3e3e3e3e3e3e3e3e3e3e3d3e3e3e3e3a10000000000
-- 007:d5b9b9e5f5000056a1ffffffffffffff5affffffffff09ffffffffffffffff5affffffffffffff5aff5affffffffffa1ffffffffffffffffffffffffffffffff0fff17ffffffffffffff8989ffffffff950000000000000000000000005585ffffffffff1fff4affffffffffffffffffffffffff950000000000000000d3ffffff3effff895353535320ffffff1fffff890e0e89ffff1fffffffff4affffffffffff1effff5affffffffff09ffffffffffffffffffffffffffff63d3d385ffffffffff95d3d3ffffffffffffffffffffffffffffffffffffffffffffffffff11ff30010101d3e3e3e3e3a10000000000
-- 008:0056560000000056a1ffffffffffffff5affffffffff09ffffffffff0effff5affffffffffffff5aff5affff6e7effc3ffefffffffffffffffffffffffffffff0fff17ffffffffffffff8989ff4effff950000000000000000000000005685ffffffffffffff4affffffffffffffff1effff1fff49e4e47666e4e4e4e4d3ffffffffffff8943434333ffffffffffffff89898989891d1d1d8989894889898989ffffffffff5affffffffff09ffffffffffffffffffffffffffff17d3d36a6a6a6a6a6a38d3d3ffffffffffffff4effffffffffffbaffffffffffff3effffff11ff30010101d3e3e3e3e3a10000000000
-- 009:0056560000000056a1ffefffffffffff5affffffffff09ffff5d1b0effffff5affffffffffffff5aff5affff6f7fffc3ffffffffffffffffffffffffffffffffffff63ffffffffffffff8989ffffffff950000000000000000000000005685ffff0fffffffff4affffffffffffffffffffffffff5affff9585ffffffffffffffffffffff8901010142ffffffffffffffffffffffffffff30010101890effffffffffffffff5affffffffff09ffffffffffffffffffffffffffff179585ffffffffffffff09ffffffffffffffffffffffffffffffbaffffffffffffffffffff11ff34535353ff490effffa10000000000
-- 010:0077a90000000077a1ffffffffffffff5affffffffff09ffff1b1bff0effff5affffffffffffff49ff49ffffffffffc3ffffffffffffffffffffffffffffffffffffffffffffffffffff8989ff0dff0e950000000000000000000000005685ffffffffffffff4affffffffffffffffffffffffff5a6e7e9585efffffffffffffffffffff8901010142ffffffffffffff0fffffffffffff3001010189ffff1fffffffffffff5affffffffff09ffffffffbabaffffffffffff1eff179585ffffffffffff09ffffffffffffffffbaffffffffffffffbaffffffffffffffffffffffffffffffffff5aff6e7ec30000000000
-- 011:a445a4af00000056c3ffffffffffffff49ffffffffff09ffffffffffffffff49ffffff0effff86e4e4e4e4e4e4e4e4e4e4e4e4e4e49689ff8986e496ffffffffffffffffffffffff0fff898989898989950000000000000000000000005785ff09090909090948ffffffffffffffffffffffffff5a6f7f9585ffffffffffffffffffffff8953535320ffffffffffffffffffffffffffff34535353890e0fffffffffffffff49ffffffffff09ffffffffbabaffffffffffffffff639585ffffffff3eff0909ffffffffffffffbaffffeeeeffffffbaffffffffffffffffffffffffffffffffff5aff6f7fc3000000009f
-- 012:fdfdfd9500000057c3ffffffff86e4e4e4961d1d1d86e4e4e4e4e4e4e4e4e4e4e496ffffffff95e5e5e5e5e5e5e5e5e5e5e5e5e5e585ffffff95e585ffffffffffffffffffffffffffff498989898989e6e4e4e4e4e47600000000000000856a6a6a6a6a6a6a38898989898989890909090909095affff9585ffffffffffffffffff1eff89ffffffffffffffffffffff0fffffffffffffffffffff8948898989090909090986e4e4e4e4e496ffffffffffffffffffffff498989899585ffffffffffff090909ffffffffffffbaffeeeeeeffffffeeffffffeeeeffbaffffffffffffffffffff490effffc30000000085
-- 013:fdfdfd9500000000c3ffffffff95e5e5e585ffffff95e5e5e5e5e5e5e5e5e5e5e585ffff0eff95000000000000000000000000000085ffffffe6e4f6ffffffffff89ffffffffffffffff5affffffff09ffffffffffff950000000000000085ffffffffffffffff89010101010101423effffffff49e4e4f685ffffffffffffffffffffff89ffffffffffffffbababaffffffffffffffffffffffffff4affffffffffffffff95e5e5e5b9b985ffffffffffffffffffffff5affffff9585ffffffffffff09ff09ffffffffffffbaffeeeeeeffffffeeffffeeeeeeffbaffffff111111ffffff86e4e4e4e4c30000000085
-- 014:e4e4e4f600000000c3434343439500000085ffffff95000000000000000000000085ffffffff95000000000000000000000000000085ffffffffffffff0fffffff89ffffffffffffffff5affff0eff09ff0effff6e7e950000000000000085ffffffff0fffffff8953535353535320ffffffffff95e5e5f585ffffffffffffffffffffff89090909ffffffffffffffffffffffffbababaffffffffff4affffffffffffffff95000000565685ffffff4effffffffffffff5affffff9585ffffffffffffffff09ffffffffffffffffffffffffffffeeffffeeeeffffffffffffffffffffffff95e5e5e5e5f500000000e6
-- 015:e5e5e5f500000000c3010101019500000085ff0dff95000000000000000000000085ff0effff95000000000000000000000000000085ff4fffffffffffffffffff891fffffffffffffff5affffffff09ffffffff6f7f950000000000005585ffffffffffffffff89ffffffffffffffffff0fffffe6e4e47685ffffffffffffffffffffff09ffff09ffffffffffffffffffeeffffffffffffffffffff4affffffffff1e1fff95000000565685ffffffffffffffffffffff5aff6e7e9585efffffffffff09ff09ffffffffffffffffffffffffffeeeeeeffffffffffffffffffffffffffffff95000000000000000000d5
-- 016:0000000000000000c3010101019500000085ffffff95000000000000000000000085ffffffff950000000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e449e4e4e4e4e4e4e4e4e4e4e4f60000000000005685ffffffffffffffff89ffffffffffffffffffffffff090eff9585ffffffff89ff1effffffff09ffff09ffffffffffffffffffeeffffffffffffff4effff4affff0fffffffffff95000000565685ffffffffffffffffffffff49ff6f7f9585ffffffffffff090909eeeeeeeeeeeeeeeeeeeeeeeeeeee1feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6e4e4e4e4760000000000
-- 017:0000000000000000e6e4e4e4e4f6000000e6e4e4e4f60000000066e4e4e4e4e4e4f6ffff0effe6e4e4e4e4e4e47600000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e50000000000005685ffffffffffffffff89ffffffffffffffffffffffff090dff9585ffffffff89ffffffffffff09ff0e09ffffffffffffffffffeeffffffffffffffffffff4affffffffffffffff95000000565685ffffffffffffffffffff86e4e4e4e4f6e6e4e4e4e4e4e496ffffffffffffffffffffffffffffffeeeeeeffffffffffffffffffffffffffffffff09010101950000000000
-- 018:0000000000000000d5e5e5e5e5f5000000d5e5e5e5f50000000085ffffffffffff09ffffffff09ffffffffff63950000000000000000000000000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4760000000000005685ffffff86e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6000000565685ffffffffffffffffffff95e5b9e5e5b9e5e5e5e5e5e5e585ffffffffffffffffffffffffffffffffeeffffffffffffffffffffffffffffffffff09010e01950000000000
-- 019:000000000000000000000000000000000000000000000000000085ffffff0fffff09ffffffff09ffffff1fff17950066e4e4e4e4e4e4e4e4e4e4e4f663080808080808080808080808086339ffffffff09ffffffefff950000000000005685ffffff95e5e5e5e5e5b9e5b9e5e5e5e5e5e5e5e5e5e5e5e5f5d5e5e5e5e5e5e5e5e5b9b9e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5b9e5e5e5f5000000567785ffffffffffffffffffff95d999d9d999d966e4e4e4e4e4f6ffffffff4effffffffffeeeeeeeeffffeeffffeeeeeeffffffffffffffffffffffff09010e01950000000000
-- 020:000000000000000000000000000000000000000000000000000085ffffffffffff09ffffffff09ffffffffff17950085010142ffffffffffffffffffffffffffffffffffffffffffffffff2bffffffff09ffffffffff9500000000000056850909099500000000007700560000000000000000000000000000000000000000000056560066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4765600000000000000567785ffffffffffffffffffff95d999d9d9a90085ffffffffff09ffffffffffffffffffffffeeeeffffffeeffffeeeeffffffff111111ffffffffffff09010101950000000000
-- 021:000000000000000000000000000000000000000000000000000085ffffffffffff09ffffffff09ffffffff0d17950085010142ffffffff4effffffffffffffffffffffffffffffffffffff2bffffffff09ffffffffff950000000000007785ffffff65e4e4e4e4e4e4e4e4e4e4e4e4e4e4760000000000000000000000000000005656008563ff3effffffffffffff6308080808080808080808080863ffffff955600000000000000565685090909090909090909099500560000000085314343433309ffffffbababaffffffffffffffffffffbaffffffffffffffff11ffffffffff056386e4e4e4e4f60000000000
-- 022:00000000000000000000000000000000000000000000000000008589898989898989ffffffff89898989898963950085010142ffffffffffffffffffffffffffffffffffffffffffffffff2bffffffff86e4e4e4e4e4f60000000000007785ffffffba0505ffff1f0e89ffffffefffffff95d964000000000000000000000000005656008517ffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeffffffffff955600000000000000565785ffffffffffffffffffff95005600000000853001010142966325ffffffffffffffff111111ffffffbaffffffffffffffff11ffffffff05051795e5e5e5e5f50000000000
-- 023:000000000000000000000000000000000000000000000000000085ffffffffffff89ffffffff89ffffffffffff950085010142ffffffffffffffff09ffffffffffffffffffffffffffffff2bffffffffe6e4e4e4e4e4760000000000005685ffffffba0505ff0fff0e89ffffffffffffff950056000000000000000000000000005656008517ffffffffffffffffffffffffffffffffffffffffffff31434343955600000000000000560085ffffffff1effffffffff950056000000008530010d01428517252525ffffff3effffffffffffffffbaffffffffffffffffffffff05050505179500000000000000000000
-- 024:000000000000000000000000000000000000000000000000000085ffff0fffffff1dffffffff1dffffffff0eff950085010142ffffffffffffffff09ffffffffffffffff8989ffffffffff2bffffffff49ffffffffff950000000000005685ffffffba0505ffff0fff89ffffffffffffff950056000000000000000000000000005799d98517ffffffffffeeeeeeffffffffffffffffffff1111ffff3001010195a900000000000000560085ffffffffffffffffffff9500560000000085300101014285172525252525ffffffffffffffffffffffffffffffffffffffffff0505050505179500000000000000000000
-- 025:000000000000000000000000000000000000000000000000000085ffffffff0fff1dffffffff1dffffffff0eff95008589898909090989ffffffff09ffffffffffffffff8989ffffffffff2bffffffff5affffffffff950000000000005785ffffffba0505ffffffff89ffffffffffffff950056000000000000000000000000000056008517ffffff11ffeeeeeeffffffffffffffffffff1111ffff3001010195000000000000000077008589898989898989ffffff9500560000000085345353532085630808080863ffffffffffffffffffffffffffffffffffffffff630808080808639500000000000000000000
-- 026:000000000000000000000000000000000000000000000000000085ffffffffffff89ffffffff89ffffffffffff950085010142ffffff89ffffffffffffff4effffffffffffffffffffffff2bffffffff5affff6e7eff950000000000000085ffffffffffffffffffffffffffffffffffff95007700000000000000000066e4e4e4e4e4e4f617ffffff11ffffffffffffffffffffffffffff1111ffff3001010195d9d9d9d9d9d9d9d999d98589898989898989ffffff95005600000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f600000000000000000000
-- 027:00000000000000000000000000000000000000000000000000008589898989898989ffffffff8989898989898995008501014209ffff89ffffffffffffffffffffffffffffffffffffffff2bffffffff5affff6f7fff950000000000000085ffffffffffffffffffffffffffffffffffff95007700000000000000000085ffffffffff898917ffffff11ffffffffffbababababaffffffff1111ffffff485353e6e4e4e4e4e4e4e4e4e4e4f6ffffffffffffffffffff95005600000000d5e5e5e5e5e5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5e5e5e5e5b9b9e5e5e5e5e5b9e5e5e5e5e5e5e5f500000000000000000000
-- 028:000000000000000000000000000000000000000000000000000085ffffffffffff09ffffffff89ffffff3001019500850101890dffff89ffffffffffffffffffffffffffffffffffffffff39ffffffff49ffffffffff950000000000000085ffffffffffffffffffffffffffffffffffff95d9a900000000000000000085ffffff0eff898917eeeeff11ff4effffffbababababaffffffffffffffffff4affffffff09ffffffff09ffffffffffffffffffffffffffff9500560000000000000000000000000000c9d9d9d9d9d9d9d9d9d9d9d9d9d9d99999d9d9d9d9d9a9000000000000000000000000000000000000
-- 029:0000000000000000000000000000000000000000000000000000850dffffff0fff09ffffffff1d094eff300101950085010186e4e4e4e4e4e496ff86e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e496ffffff86e4e4e4e4e4f600000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6000000000000000000000085ff0d0effff898963eeeeff11ffffffffffffbabaffffffffffffffffffffff4affffffff09ff0e0eff09ffffffffffffffffffff1effffff95005600000000000000000000000000000000000000000000000000000000006756000000000000000000000000000000000000000000000000
-- 030:000000000000000000000000000000000000000000000000000085ffff0fffffff09ffffffff1d09ffff300101950085010195e5e5e5e5e5e585ff95e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e585ffffff95e5e5e5e5e5f500000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000000000000000085ffffffffffff09ffeeeeffffffffffffffffbabaffffffffffffffffffffff4affffffff09ff0e0eff09ffffff1effffff1effffffffff1e95d9a9000000000000000000000000000000000000000000000000000000009f4545a4af00000000000000000000000000000000000000000000
-- 031:000000000000000000000000000000000000000000000000000085ffffffffffff09ffffffff89ffffff3001019500850101e6e4e4e4e4e4e4f6ffe6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6ffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085ffffffffffff09ffffffffffffffffffffffffffffffffffffffffffffffff4affffffff09ffffffff09ffffffffffffffffffffffffffff95000000000000000000000000000000000000000000000000000000000000856363639500000000000000000000000000000000000000000000
-- 032:0000000000000000000000000000000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f600850101424effffffffffffffffffffffffffffff09ffffffffffffffffffffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6000000000000000000000000000000000000000000000000000000000000e6e4e4e4f600000000000000000000000000000000000000000000
-- 033:0000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5b9e5e5e5f50085010142ffffffffffffffffffffffffffffffff09ffffffffffffffffffffffff95000000000000000000000040c2c2c2c2c2c24100000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5b9b9e5e5e5e5e5e5e5e5e5e5e5b9b9e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000000000000000000000000000000000000000000000000000000d5e5e5e5f500000000000000000000000000000000000000000000
-- 034:0000000000000000000000000000000000000000000000000000000000000000000000000000000000560000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f60000000000000000000000a1e3e3e3e3e3e3a10000000000000000000000000000000000000000000000000000000000000000005656000000000000000000000067560000000000000000000000000000000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2410000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:0000000000000000000000000000000000000000000000000000000000000000000000000000000000560000000000d5e5b9b9b9e5e5e5e5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f50000000000000000000000a1e3e3e3e3e3e3a1d9640000000000000000000000000000000000000000000000000000000000000056560000000000000000000000566700000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1f4f4f4f4f4f4a10000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:0000000000000000000000000000000000000000000000000000000000000000000000000000000000560000000000000056565600000000000000005600000000000000000000000000000000000000000000000000000000000000a1e3e3e3e3e3e3a100560000000000000000000000000000000000000000000000000000000000000056560000000000000000000000565600000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1900000000080a10000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:000000000000000000000000000000000000000000000000000000000000000000000000000000000056000000000000005656569fa4a4a4af000000560040c2c2c2c2c2c2410000000000000040c2c2c2c2c2c24100000000000000a1e3e3e3e3e3e3a100560000000000000000000000000000000000000000000000000000000000000056560000000000000000000000565600000000000000000000000000000000000000000000000000000000000000000000000000000000000055a1c5d4d4d4d4c6a16400000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:000000000000000000000000000000000000000000000000000000000000000000000000000000004074c2c2c2410000007799a9856363639500004074c2a1f4f4f4f4f4f4a1c2c2410040c2c2a1f4f4f4f4f4f4a1c2c24100000000a1ffffefffffffa100560000000000000000000000000000000000000000000000000000000000000067560000000000000000000000565600000000000000000000000000000000000000000000000000000000000000000000000000000000000056a1726273737373a15600000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:00000000000000000000000000000000000000000000000000000000000000000000000000000000a1f4f4f4f4a100000077c9d985636363950055a1f4f4f4d3e3e3e3e3d3f4f4f4a100a1f4f4f4d3e3e3e3e3d3f4f4f4a100000000a1ffffffffffffa100560000000000000000000000000000000000000000000000000000000000000056670000000000000000000000565600000000000000000000000000000000000000000000000000000000000000000000000000000000000056a1ffffffffffffa15600000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:0000000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2a1d3e3e3d3a1c2c241560000e6e4e4e4f60056a1e3e3d3d3e3e3e3e3d3d3e3e3a100a1e3e3d3d3e3e3e3e3d3d3e3e3a100000000a1ffffffffffffa100560000000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c27474c2c2c2c2c2c2c2c2c2c2c27474c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2410000000000000000000077a1ffffffffffffa15600000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:0000000000000000000000000000000040c2c2c2c2c2c24100000000000000a1f4f4f4f4f4f4f4f4f4d3e3e3d3f4f4f4a1770000d5e5e5b9f50057a1e3e3d3feff0f0ffffed3e3e3a100a1e3e3d30eff0f0fff0ed3e3e3a100000000a1ffffffffffffa1005600000000000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a2f4f4f4f4f4f4f4f4f4f4f4f4f4a2f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a10000000000000000000057a1ffff5c1bffffa199d9d9d9d9d9d9d9640000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000040c2c2c2c2c2c2c2c2c2a1f4f4f4f4f4f4a1c2c2c2c2c2c2c2a1d3e3c8e3c8e3e3e3d3d3b8b8d3d3e3e3a199d9d9d9d9d999640040a1ffffffffffffffffffffffffa1c2a1ffffffffffffffffffffffffa100000000a1484b4b4b4b4ba1d999d9d9d96767d9d9d9d9d9a1e3e3e3d3e3b00000000000c0e3f3e3e3e3e3e3e3a2e3f3e3e3e3e3e3e3e3e3e3e3d3a2d3e3e3e3e3e3f3e3e3e3e3e3e3e3e3e3a5e3e3b0000000000000c0e3e3e3d3a140c2c2c2c2c2c2c2c2c2c2a1ffff1b0bffffa174c2c2c2c2c2c2c274c241000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000a1f4f4f4f4f4f4f4f4f4d3d3e3e3e3e3d3d3f4f4f4f4f4f4f4f4d3e3c8e3c8e3e3e3d30fffff0fd3e3e3a174c2c2c2c2c27474c2a1d3ffff3143434343434333ffffd3a1d3ffff3143434343434333ffffa1c2000000a1ffffffffffffa1005600000000000000000000a1e3e3e3d3e300000000000000e3f3e3e3e3e3e3e3a2e3f3e3e3e3e3e3e3e3e3e3e3d3a2d3e3e3e3e3e3f3e3e3e3e3c1c1f1e3e3a5e3e30000000000000000e3e3e3d3a1a1f4f4f4f4f4f4f4f4f4f4f4ffffdddcfffff4f4f4f4f4f4f4f4f4f4f4a1000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000a1d3f3e3e3e3e3e3e3e3d3d3e3e3e3e3d3d3c8b0000000c0e3d3d3e3c82ac849b8b8d3ffffffffd3b8b8d3f4f4f4f4f4f4f4f4f4d3d3ffff3002010101010142ffffd3d3d3ffff3001010101010142ffffd3a14140c2a1ffff0f0fffffa1c274c2c2c2c2410000000000a1e3e3e3d3e3b4d4d4d4d4d4c4e3f3e3e3e3e3e3e3a2e3f3e3e3e3e3e3e3e3e3e3e3d3a2d3e3e3e3e3e3f3e3e3e3e3e3e3e3e3e3a5e3e3b4d4d4d4d4d4d4c4e3e3e3d3a1a1d3b00000000000c0e3e3d3ffffdddcffffd3b000000000c0e3a5f3e3a1000000000000000000000000000000000000000000000000000000000000
-- 045:40c2c2c2c2c2a1d3f3e3e3e3c1e1e3e3d3d3b8b8b8b8d3d3c80000000000e3d3ffffffffff5affffffffffffffffffffd3d3d3e3e3e3e3e3e3e3d3d3ffff3001010101010142ffffd3d3d3ffff3001010101010142ffffd3d3a1a1f4f4ff0fffff0ffff4f4f4f4f4f4f4a10000000000a1ffffffffffffffffffffffffffff0505ffffffffa2ff5fffffffff050505ffffffffa20505ff0effffffff0505ffffffffffffff050505ffffffffffffff0e0505ffa1a1d300000000000000e3e3d3ffffdddcffffd3000000000000e3a5f3e3a1000000000000000000000000000000000000000000000000000000000000
-- 046:a1f4f4f4f4f4f4d3a8b854b8b8b854b8d3ffff30010101d3c8b4d4d4d4c4e3d3ffffffffff5affffffffffffffffffffd3d3d3e3e3e3e3c1f1e3d3ffffff3453240101235320ffffffd3ffffff3453240101235320ffffd3d3a1a1e3d3ffffffffffffd3e3e3e3e3e3e3a10000000000a1ffffffffffffffeeffffffffffff05ffffffffffa2ffffffffffffffffffffffffffa205ffffffffffffffffffffffffffeeffffffffffffffffffffffffffff0505a1a1d3b4d4d4d4d4d4c4e3e3d3ffffdddcffffd3b4d4d4d4d4c4e3a5f3e3a1000000000000000000000000000000000000000000000000000000000000
-- 047:a1e3e3e3e3e3c8ff3001540fff0f540142ffff30010101010142ffffffffffffffffffffff5affff31434343434333ffd3d3d349e3e3e3e3e3e3d3ffffffffff30010142ffffffff898989ffffffff30010142ffffffffffd3a1a1e3d3386a6a6a6a6ad3e3e3e3e3e3e3a10000000000a1ffffffffffffffeeffffffffffff05ffffffffffa2ffffffffffffffffffffffffffa2ffffffffffffffffffffff0fffffeeffffffffffffffffffffffffffffff05a1a1ffff63737373627363ffffffffdddcffff6373727373727363ffffffa1000000000000000000000000000000000000000000000000000000000000
-- 048:a1e3e3e3e3e3c8ff300192ffffff920142ffff30015492920142ffffffffffffffffffff70a2a2a2a2010101010142ffffff0f5aff6e7e89efffffffffffffff34535320ffffff89ffffff89ffffff34535320ffffffffffffa1a1e3d3ffffffffffffd3e3e3e3e3e3e3a10000000000a1ffffffffff2eff09ffffffffffffffffffffffffa2ffffffffa28989ffffffffffffa24333ffffffff090909091111ffffffffffffff1111111111ffffffffffffffa1a1ffffffffffffffffffffffffffdddcffffffffffffffffffffffffffa1000000000000000000000000000000000000000000000000000000000000
-- 049:a1b8b8b8b8b8c8ff3453ffffffff345320ffff3001540eff0142ffffff3143434333ffffd3a2a2d3d301ffff010142ffffffff5aff6f7f89ffffffffffffffffffff4effffffff89ff3eff89ffffffffff4effffffffffffffa1a1ffffffffffffffffffffffffffffffa10000000000a1ffffffffff0909ff0909ffffffffffa2ffbaffffa205ffffffa21e89ffffeeeeffffa20142ffffffff09ff4eff1111ffffffffffff0f11ffffff09ffffffffffffffa1c3ffff5c1bccccccccccccccccccefdccccccccccccccccccc5c1bffffc3000000000000000000000000000000000000000000000000000000000000
-- 050:a1ffffffffffffffffffffffffffffffffffff300154ff0d0142ffffff3001010142ffffd3a2a2d3d3010101010142ffffff0f5affffff89ffffffffffffffffffffffffffffff89ffffff89ffffffffffffffffffffffffa1a1a1ffffffffffffffffffffffffffffffa10000000000a1ffffffffff091fff1f09ffffffffffa2ffffffffc305ffffffa2ffffffffffffff05a20142ffffff2e090effff1111ff11111111ffff11ff1fff092effffffff0fffa1c3ffff1b1bbcbcbcbcbcbcbcbcbcdddcbcbcbcbcbcbcbcbcbc0b1bffffc3000000000000000000000000000000000000000000000000000000000000
-- 051:a1ffffffff5d1bffffffffffffffffffffffff3001540eff0142ffffff3001010142ffff0fa2a20ffe535324010142ffffff86e4e4e4e4e4e4e496ffffffffff86e4e496ffffff3189898933ffffff86e4e496495b5b5b49c3c3a1ffffffffffffffffffffffffffffffa10000000000a1ffeeeeff09ff0effffff09ffeeeeffa2ffffffffc3ffffffffa205ffffffffff8989a20142ffffffff0909111111111111ff0d1111111109090909ffffffffffffffa1c3ffffffffffffffffffffffffffdddcffffffffffffffffffffffffffc3000000000000000000000000000000000000000000000000000000000000
-- 052:a1ffffffff0b1bff314343434343434333ffff300192929201144343432201010142ffffffa2a2ff0effff30010142ffffff95b9e5e5e5e5e5e5e69609090986f6e5b9e696ffff3001010142ffff86f6b9e5e696ffffff86c3c3a1ffffffffffffffffffffffbabaffffa10000000000a1ffffffffff091fff1f09ffffffffffa2ffffffffc3ffbaffffa205ffeeeeffff891ea20142ff0fffffff11111111ffff11ffff11ffffffffffffffffffffffff3143a1c3e4e4e4e4e4e4e4e496ffffffffdddcffffffff86e4e4e4e4e4e4e4e4c3000000000000000000000000000000000000000000000000000000000000
-- 053:a1efffffffffffff300101010101010142ffff300101010101010101010101010142ffff0fa2a2ff0dffff30010142ffffff9556000000000000d58509090995f50056d585ffff3001010142ffff95f55600d585ffffff95e5f5a189898989898989ffffffffbaffffffa1a1a1a1a1a1a1ffffffffff0909ff0909ffffffffffa2ffffeeeec3ffffffffa205ffffffffffffffa20142ffffffffffffffffffffff113eff11ffffffffffffffffffffffff3001a1d5b9e5b9e5e5b9e5e585ffffffffdddcffffffff95e5e5b9e5e5e5b9e5f5000000000000000000000000000000000000000000000000000000000000
-- 054:a1ffffffffffffff3001bdffffffcd0142ffff345353535353535353535353535320ffffffa2a2ff0effff30010142ffffff95770000000000000085ff4eff950000560085ffff3001010142ffff950056000085ffffff950000a10d09ffffff3fffffffffffbaffffffd3e3e3e3e3e3d3ffffffff2effff09ffffffffffffffa205ffffffffffffff2fa2ffffffffffffffffa25320ffffffeeeeeeffffffff1111111111ffffffffff0fffffeeeeeeff3001a100c9d967d9d999d9d985ffffa2ffdddcffa2ffff95d9d999d9d9d9a90000000000000000000000000000000000000000000000000000000000000000
-- 055:c3ffffffffffffff3001beff0effce0142ffffffffffffffffffffffffffffffffffffff0fa2a20fffffff34535320ffffff95770000000000000085ffffff9500005666e7ffff3453535320fffff77656000085ffffff950000a10909ff3f1111ffff2effffbaffffffd3e3e3e3e3e3d3ffffffffffffffeeffffffffffffffc305ffffffffffffffffa28989ffffffffffffa2ffffffffffffffffffffff111effffff11ffffffffffffffffffffffff3001a100000077009f45af0085ffff35ffdddcff35ffff95009f45af0000000000000000000000000000000000000000000000000000000000000000000000
-- 056:c3ffffffffffffff300101010101010142ffffffffffffffffffffffffffffffffffffff70a2a260ffffffffffffffffffff95560000000000000085ff0eff95000057850effffffffffffffffff0e95a9000085ffffff950000a1ffffffff1111ffffff4fffbaffffffd3e3d2c1d2e3d3ffffffffffffffeeffffffffffffffc305ffffffff0fffffffa21e89ffffeeeeff05a205ffffffffffffffff2eff11ffffffffff11ffffffffffffffffffffff3001a100000077008563950085ffff35ffdddcff35ffff95008563950000000000000000000000000000000000000000000000000000000000000000000000
-- 057:c3e4e4e4e4e4e4e4e4e496535353535320ffffff44ffffffffff44ffffffffff86e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f65600000000000000850eff0e95000000e6e4e4e496ffffff86e4e4e4f600000085ff0eff950000a1ffffff3f1111ffffffffffbaffffffd3e3e3e3e3e3d3ffffffffffffffffffffffffffffffc30e4fffffffffffffffa2ffffffffffff0505c305ffffffffffffffff09091111ff0fffff111109090909ffffffffffff3001a1000000c9d9e6e4f60085fffa35ffdddcff35faff9500e6e4f60000000000000000000000000000000000000000000000000000000000000000000000
-- 058:d5e5e5e5e5e5e5b9e5e585ffffffffffffffffff54ffffffffff54ffffffffff95e5e5e5e5e5e5e5e5e5e5b9e5e5e5e5e5e5f55600000000000000e6e4e4e4f6000000d5e5e5e585ff0dff95e5e5e5f500000085ffffff950000a1ffffffffff2effffffffffffffff86e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e496ffffff86e4e4e4e4e4e4e4e4e4e4e4a2ffffffffffff8989c305ffffffff0fffffff09ffff11ffffffffff114effff092effffffffff3453a10000000000d5b9f50085e8f8a619191919a6e8f89500d5b9f50000000000000000000000000000000000000000000000000000000000000000000000
-- 059:00000000000000c9d9d985ffffffffffffffffff920fff0fff0f92ffffff0eff950000000000000000000057d9d9d9d9d9d9d9a900000000000000d5e5e5e5f500000000000000e6e4e4e4f60000000000000085ff0eff950000a1ffffff3f1111ffffffffffffff1e95e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e585ffffff95e5e5e5e5e5e5e5e5e5e5e5a2ffffeeeeffff891ec3ffffffffffffffffff09ff1f11ffffeeff1111ffff1f09ffffffffff0fffffa1000000000000c9d9d985e9f935ffdddcff35e9f995d9d9a9000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:00000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e496ffffff95000000000000000000000000000000000000000000000000000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6ffffff950000a1ffffff1111ffffbabaffffffff89e6e4e4e4e4e4e4e476000000000000000085ffffff950000000000000000000055a2ffffffffffffffffc3ffffffffffffffff2e09091111ffffeeffff1111111111ffffffffffffffffa100000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:00000000000000000000d5e5e5e5e5e5e5e5e5e5b9e5e5e5e5b9b9e5e6e4e4e4f60000000000000000000000000000000000000000000000000000856e7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeff0eff950000a1ffffffffffffffbaffffffffffffffffff2f2fffffff95000000000000000085ffffff950000000000000000000067c305ffffffffffffffc3ffffffffffffffffffffffffffffffeeffffff11111111ffffffffffffffffa100000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:00000000000000000000000000000000000000005600000000565600d5e5e5b9f50000000000000000000000000000000000000000000000000000856f7feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffff950000a1ffffffffffffffffffffffffffffffffffffffffffff95000000000000000085ffffff950000000000000000000056c305ffffffffffffffc3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc300000000000000000085ffffa2ffdddcffa2ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:0000000000000000000000000000000000000000c9d9d9d9d97767d9d9d9d9a9000000000000000000000000000000000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f60000a1ffffffffffffffffffffffffffbaffffff2f2fff0eff95000000000000000085ffffff950000000000000000000057c30505ffffffff6e7ec3efffffffffffffffffffffff0fffffffffffffffffffffffffffffffffff05c300000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f50000c3ffffffffffffffffffffffffffffffffff2effffffff95000000000000000085ffffff950000000000000000000000c3050505ffffff6f7fc3ffffffffffffffffffffffffffffffffffffffffffffffffffffffff050505c300000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c30909ffffffffffffffffffffffffffffff2f2fffffff95000000000000000085ffffff950000000000000000000000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4495b5b5b5b49e4e4e4e4e4e4e4e4e4e4e4c300000000000000000085fffa35ffdddcff35faff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c30e09ffffffffffffffffffffffffffffffffffffffff95000000000000000085ffffff950000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e585ffffffff95e5e5e5e5e5e5e5e5e5e5e5f500000000000000000085e8f8a619191919a6e8f895000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4495b5b5b49000000000000000085ffffff95000000000000000000000000000000000000000000000000000000000000000000000085ffffffff9500000000000000000000000000000000000000000085e9f935ffdddcff35e9f995000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 068:000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c24100000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e596ffffff95000000000000000085ffffff95000000000000000000000000000000000000000000000000000000000000000000000085ff0e0eff9500000000000000000000000000000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 069:0000000000000000000000000000000000000000000000000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a1000000000000000000000000000000000000000000000085ffffff950066e4e4e4e4e4e4f6ffffff95000000000000000000000000000000000000000000000000000000000000000000000085ffffffff9500000000000000000000000000000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 070:000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2a1d3e3e3e3e3e3f3b00000000000000000c0e3e3e3f3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a1c2c2c2410000000000000000000000000000000000000085ff6e7e950085efffffffffffffffffff95000000000000000000000000000000000000000000000000000000000000000000000085ff6e7eff9500000000000000000000000000000000000000000085fffaa2ffdddcffa2faff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 071:0000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d3e3e3e3e3e3f300000000000000000000e3c1d2f3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3e3e3e3a10000000000000000000000000000000000000085ff6f7f950085ffffffffffffffffffff95000000000000000000000000000000000000000000000000000000000000000000000085ff6f7fff9500000000000000000000000000000000000000000085e8f835ffdddcff35e8f895000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:0000a1e3e3e3e3b0000000c0e3e3e3e3e3e3e3e3e3e3e3e3f3e3e3e3e3e3d37373737373f3b4d4d4d4d4d4d4d4d4c4e3e3e3f3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3e3e3e3a10000000000000000000000000000000000000085ffffff950085ffffffffffffffffffff95000000000000000000000000000000000000000000000000000000000000000000000085ffffffff9500000000000000000000000000000000000000000085e9f935ffdddcff35e9f995000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 073:0000a1e3e3e3e30000000000e3e3e3e3e3e3e3e3e3e3e3e3f3e3e3e3e3e3fefefefefefefefefefefefefefefefefefefefe30010101010142ffffffff1fffffffff0effffffffffffffffffff1fffff110dffffffd3e3e3e3a100000000000000000000000000000000000000e6e4e4e4f600e6e4e4e4e4e4e4e4e4e4e4f60000000000000000000000000000000000000000000000000000000000000000000000e6e4e4e4e4f600000000000000000000000000000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 074:0000a162737373b4d4d4d4c4b8b838b848b838b8b8b8b8b8f3b8b8b8b8b8ffffffffffffffffffffbaffffffffffffffff1f34535353535320ffff0fffffffffffff11ffffffffeeeeffff0fffffffff11ffffffff49e3e3e3a100000000000000000000000000000000000000d5e5e5e5f500d5e5e5e5e5e5e5e5e5e5e5f50000000000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5f500000000000000000000000000000000000000000085ffffa619191919a6ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:0000a1fefefefefefefefefefefe6bfe4afe6bfefefefefefeffffffffffffffffffffffffffffffbaffff1fffffeeeeeeeeffffffffffffeeeeffff0fffffffffff11ffffffffeeeeffffffff0fffff1111ffffff5affffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:0000a1ffffffffffffffffffffff6bff4aff6bffffffffffffffffffffffffffffffffbaffff1fffbaffffffbabaeeeeee1fffffffffffffeeeeffffffffffffffff11ffffffffeeeeffff0fffffffff1111ffffff5aff6e7ea100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066e4e4e4e4e4e4e4e4f6ffdddcffe6e4e4e4e4e4e4e4e476000000000000000000000000000000000000000000000000000000000000000000
-- 077:0000a1efffffffffffffffffffff6bff4aff6bffffffffffffffbaffff1fffffffffffbaffffffffffffff1fbabaeeeeeeeeffffffffffffeeeeffffffeeeeffffff11ffffffffffffffffffffffffff1111ffffff5aff6f7fa1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066ea8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f65760000000000000000000000000000000000000000000000000000000000000000
-- 078:0000a1ffffffffffffffffffffff6bff4aff6bffffffffffffffbaffffffffffffffffbaffff1fffffffffffbabaeeeeee1fffffffffffffffffffffffeeeeffffff11ffff0fffffffffffffeeeeffff1111ffffff5affffffa10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066ea8f8f8f8f8f8f8f8f8f8e8f8f8f8f8e8f8f8f8f8f8f8f8f8f657600000000000000000000000000000000000000000000000000000000000000
-- 079:0000a1ffffffffffffff5d1bffff6bff4aff6bffffffffffffffffffffffffffffffffffffffffffffffffffbabaeeeeeeeeffffffffffff0fffffffffeeeeffffff11ff1fffff0fffffffffeeeeffff1111ffffffa1a1a1a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066ea8f8f8f8f8f8f8f8e8f8f8f8e5d0b8e8f8f8e8f8f8f8f8f8f8f8f6576000000000000000000000000000000000000000000000000000000000000
-- 080:0000c3ffffffffffffff0b0bffff6bff4aff6bffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeee1fffffffffffffffff0fffffffffffff1111ffff0fffffffffffffeeeeffff1111ffffffa1b1b1b1b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8f8f8f8e8e8e8e0b0b8e8e8e8f8f8f8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 081:0000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e496ffffffffff31434343434333ffffffffffffffffffffffffffffffff1fffffffffff11ffffffffff1fffffffffffffffff11ffffffffc3b1b1b1b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8f8f8e8e8f8f8f8f8f8f8f8e8e8f8f8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 082:0000d5e5e5e5e5e5e5e5e5e5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5b9e5e585ffffffffff30010101010142ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11ffffffffc3b1b1b1b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8e8e8f8f8f8f8e8e8e8e8f8f8f8e8e8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 083:00000000000000000000000000000000c9d9d9d9d9d9d9d9d9d9d9a90000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4c3e5e5e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8e8f8f8f8f8f8e8f8f8f8f8e8f8f8f8f8e8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 084:000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8e8f8f8f8f8f8e8f8e8e8e8e8f8e8f8f8f8f8e8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 085:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8e8f8f8f8f8f8f8e8f8e5e8e8e8f8e8f8f8f8f8f8e8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8e8f8f8f8f8f8f8f8e8f8e8e8e8e8f8e8f8f8f8f8f8f8e8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 087:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8e8f8f8f8f8f8f8e8f8e8e8e8e8f8e8f8f8f8f8f8e8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 088:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8e8f8f8f8f8f8f8e8f8f8f8f8e8f8f8f8f8f8e8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8e8f8f8f8f8f8f8e8e8e8e8f8f8f8f8f8e8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 090:00000000000000000000000000000000000000000000000000000040c2c2c24100000000000000000000000000000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e476000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8e8e8f8f8f8f8f8f8f8f8f8f8f8e8e8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 091:000000000000000000000000000000000000000000000000000000a1f4f4f4a100000000000066e4e4e4e449e449e4493eff0dba0effffeeeeffffffbabaff0e0effffffffeeeebababababababababababababaee1fff4eee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8f8f8e8e8f8f8f8f8f8f8f8e8e8f8f8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 092:000000000000000000000000000000000000000000000000000000a1e3e3e3a100000000000085ffffffff5aff5aff5aeeeeeeba0effeeeeeeeeeeffba1fffffffeeffffeeeeffba3eff1fff0dff0eff0eeeeebaeeffffeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8f8f8f8f8e8e8e8e8e8e8e8f8f8f8f8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 093:000000000000000000000000000000000000000000000000000000a1e3e3e3a100000000000085ff6e7eff5aff5aff5aeebababaffeeeeeeffeeeeeeba3eff0deeeeeeeeeeffffbaeeeeffffffffffeeeeeeffbaeeeeeeeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6968f8f8f8f8f8f8f8f8e8f8f8e8f8f8e8f8e8f8f8f8f8f8f8f8f8f86f6000000000000000000000000000000000000000000000000000000000000
-- 094:00000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2a1e3e3e3a100000000000085ff6f7fff5aff5aff5aeeffffbaffeeeebabaeeeeeebaeeeeeeeebaeeeeeebababaeeeeeeeeeeeeeeeeeeeeffbababababaee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e6968f8f8f8f8f8f8e8f8f8f8e8f8f8e8f8f8f8e8f8f8f8f8f8f86f6f5000000000000000000000000000000000000000000000000000000000000
-- 095:000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4ff0effa100000000000085434343435aff5aff5aeeeeeebaffeeeeffbaeeeeeebabababababaeeeeeeeeffbabababababababaffffeeeeeeeeeeeeeeee9500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e6968f8f8f8f8f8f8f8f8e8f8f8f8f8e8f8f8f8f8f8f8f8f86f6f500000000000000000000000000000000000000000000000000000000000000
-- 096:000000a1e3e3e3e3b0000000c0e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3ff1fffa100000000000085010101015aff5aff5affeeeeeeffeeff1fbaffeeeeeeffbaffffffffffeeeeeeffffffffbaffffffffffffffeeeeeeeeeeee950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6f50000000000000000000000000000000000000000000000000000000000000000
-- 097:000000a1e3e3e3e30000000000e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3eeeeeea100000000000085010e0e015aff5aff5affffeeffeeee4eeebaffffeeffffbabababaffffeeeeeeeeffffffbaffffffffffffffffffeeeeeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000000000000000000000000000000000000000000000000000000000000
-- 098:000000a1e3e3e3e3b4d4d4d4c4e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3bababaa100000000000085014343015aff5aff5affffffffbaeeeeeebaffffffffffffffffbaffffffffffffbabababaffffffffffffffffffeeeeeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 099:000000a1ffffffffffffffffffffffff638989ffffffffffffffffffffffffd3000000000000850101010149ff49ff49ffffffffbababababaffffffffffffffffbaffffffffffffbaffffffffffffffffffffffffffffeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 100:000000c3efffffffffffffffffffffff0f1789ffff314333ffffffffffffffd3000000000000e6e4e4e4e4e4e4e4e496ffffffffffffffffbaffffffffffffffffbaffffffffffffbaffffffffffffffffffffffffffffffee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 101:000000c3ffffffffffffffffffffffff0e1789ff0e300142ffffffffffffffd3000000000000d5e5e5e5e5e5e5e5e5e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e496ffffff86e4f6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 102:000000c3ffffffffffffffffffffffff0f17894343220142ffff8696ffffff95000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e585ffffff95e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 103:000000c3e4e4e4e4e4e4e4e496ffffff6389890101010142ffff9585ffffff9500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085ffefff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 104:000000d5e5e5e5e5e5e5e5e585ffffff8989890101010142ffff9585ffffff9500000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2410000000000000000000000000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 105:00000000000000000000000085ffffffffffff5353535320ffff9585ffffff95000000000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4a100000000000000000000000000000000000000000000000000000000e6e4e4e4f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 106:00000000000000000000000085ffffffffffffffffffffffffff9585ffffff95000000000000000000a1e3e3e3b000000000c0e3e3e3a1c2c2c2c2c2c2c2c2c2c2410000000000000000000000000000000000d5e5e5e5f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 107:00000000000000000000000085ffffffffffffffffffffffffff9585ffffff95000000000000000000d3e3e3e3000000000000e3e3e3f4f4f4f4f4f4f4f4f4f4f4a1000000000000000000000000000000000066e4e4e4760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 108:000000000000000000000000e6e4e4e4960fff0fff0f86e4e4e4f685ffffff95000000000000000000d3e3e3e3b4d4d4d4d4c4e3e3e3d3e3e3e3e3e3e3e3e3e3e3a1000000000000000000000000000000000085ff6e7e950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 109:000000000000000000000000d5e5e5e5e6e4e4e4e4e4f6e5e5e5f585ffffff95c2c2c2c2c24140c2c2d3630808080808080808080863d3e3e3e3e3e3e3e3e3e3e3c3000000000000000000000000000000000085ff6f7f950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 110:00000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6ffffff49e349e3e3e3d3d3e3e3d389ffffffffffffff4effffffd3e3e3e3e3e3e3e3e3e3e3c3000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 111:00000085ffffffffffffff4effffbaffffffffff090909ffffffffffffffff5aff5affffff9585ffffffffffffffffffffffffffffff891f1dffff0e0effff1d1fc3000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 112:00000085ffffffffffffffffffffbaffffffffff090909ffffffffffffffff5aff5aff6e7e9585efffffffffffffffffffffffffffff891d1dffff0dffffff1d1dc3e4e4e4e4e4e4e4e4e4e4e476000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 113:000000850e0d0effffffffffffffbaffffffffff090909ffffffffffffffff5aff5aff6f7f9585ffffffffffffffffffffffffffffff89ffffffffffffffffffff49ffffffffffffff89ffffff95000000000085ff0eff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 114:00000085bababababababababababaee86e4e4e4e4e4e496ffffffffffffff5aff5affffff9585ffffffffffffffffffffffffffffff63babababababababababa5affffffffffffff89ffffff95000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 115:00000085ffffeeeeeeeeeebaeeeeeeee95e5e5e5e5e5e585ffffff78e4e4e4e4e4e4e4e4e4f6e6e4e4e4966308080808080863ffffff17ffffff86e496ffffffff5affffffffffffff89ffffff95000000000085ff0eff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 116:40c2c285ffffffeeeeeeeebaeeeeeeee9500000000000085ffffff79a4a4a4a4a4a4a4a4a4da0000000085ffffffffffffff17ffffff17ffffff95e585ffffffff5affffffffffffff89ff0dff95000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 117:a1e3e385ffffffffeeeeeebaeeff0eee9500000000000085ffffff898989890f0f0f898989950000000085ffffffffffffff17ffffff17ff4eff950085ffffffff5affffffffffffff89ffffff95000000000085ff0eff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 118:a1e3e385ffffffffffeeeebaff4effee9500000000000085ffffffffffffffffffffffba89950000000085ffffffffffffff17ffffff17ffffff950085ffffff86e4e4e4e496ffffff89ffffff95000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055
-- 119:a1e389898989eeeeeeeeeebaeeff0eee9500000000000085ffffffffffffffffffffffba8995d9d9d9d985ffff63ff0e0eff17ffffff17ffffff950085ffffff95e5e5e5e585ffffff89ffffff950000000000495b5b5b490000000000000000000000000000000000000000000000000000000000000000b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000056
-- 120:a1e389898989eeeeffeeeebaeeeeeeee9500000000000085ffffffffffffffffffffffba1f95d9d9d9d985ffff17ffffffff17ffffff17ffffff950085ffffff950000000085ffffff89ffffffe6e4e4e4e4e4f6ffffffe6e476000000000000000000000000000000000000000000000000000000000000b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b11010101010101010101010101010101010101010bf1010101010101010cf1010bf101010101010101010101010101010101010101010bf1010101010000000000000000000000000000000000000000000000000000000000056
-- 121:a1ffffffffeeeeffffffeebaeeeeeeee95000000000000e6e4e4e4e4e4e4e496ffffffbaff95d9d9d9d985ffff17ffffffff17ffffff63ffffff950085ffffff950000000085ffffffffffffff89babababababababababa1f95000000000000000000000000000000000000000000000000000000000000b3b3b3b3b3b3273737373737373737373737373737373747b3b3b3b3b3b31010101010101010cf101010101010101010101010101010101010cf10cfcf1010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000056
-- 122:a1ffffffeeeebaffffffeebabababaee95000000000000d5e5e5e5e5e5e5e585ffffffba1f950000000085ffff630808080863ffffffffffffff950085ffffff950000000085ffffffffffffff89ff0f0fffffffffffffbaff95000000000000000000000000000000000000000000000000000000000000b3b3b3b3b35900000000000000000000000000000000000069b3b3b3b3b31010101010bf10101010101010101010101010101010101010101010cfbf101010cf1010101010bf1010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000056
-- 123:c3ffff0eeeeebaffffffeeeeeeeeeeeee6e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6ffffffbaff950000000085ffffffffffffffffffffffffffffffe6e4f6ffffffe6e4e4e4e4f6ffffffffffffff89ffffffffffffffffffba1f9500000000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000003510101010101010101010101010101010101010101010101010101010101010bf1010101010101010101010bf1010101010101010cf10101010101010000000000000000000000000000000000000000000000000000000000056
-- 124:c33eff0deeeebaffffffffffffffffffffffffffffffffffffbaffffffffffffffffffba1f950000000085ffffffffffffffffffffffffffffffffbaffffffff89ffffffff89ffffff89ffffff89ffffffffffffffffffbaff9500000000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000003510101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010bf10101010101010101010101010000000000000000000000000000000000000000000000000000000000057
-- 125:c3ffff0effeebaffffffffffffffffffffffffffffffffffffbaffffffffffffffffffba8995d9d9d9d9e6e4e4e4e4e4e4e4e4e4e4e496ffffffffbaffffffff89893eff8989ffffff89ffffffffffffffbaffffffffbaff1f950000000000000000000000000000000000000000000000000000000000003500000000000000000000000000000000000000000000000000000000351010101010cf10101010101010101010101010101010cf10101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 126:c3ffffffffeebaffffffffffffffffffffffffffffffffffffbaffffffffffffffffffba899500000000d5e5e5e5e5e5e5e5e5e5e5e585ffffffffbaffffffff89ffffffff89ffffff89ffffffffffffffbaffffffffbaffff95000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035101010101010101010101010bf1010101010101010101010101010101010101010101010101010101010cf10cf10101010cfbf101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 127:c3e4e4e4e496baffffffffffffffffffffffffffffffffffffba0fff0fff0fbababababa89950000000000000000000000000000000085ffffffffbaffffffff8989ffff8989ffffff89ff0f0fffffffffbaff0f0fffbaff1f95000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035101010cf101010101010101010101010101010bf10101010101010101010101010bf10101010101010101010101010cf10cfcf101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 128:d5e5e5e5e585babababababababababababababababababababababababababa86e4e4e4e4f60000000000000000000000000000000085ffffffffbaffffffff89ffffffff89ffffff89bababababababababababababaffff950000000000000000000000000000000000000000000000000000000000003500000000000000000000000000000000000000000000000000000000351010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010cf1010cf101010bf1010101010000000000000000000000000000000000000000000000000000000000000
-- 129:0000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6e5e5e5e5f500000000000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f600000000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000003510101010101010101010bf101010bf101010bf101010101010101010bf10101010101010101010101010101010101010101010cf1010101010101010000000000000000000000000000000000000000000000000000000000000
-- 130:0000000000d5e5e5e5e5e5e5e5b9e5e5e5e5e5e5e5b9b9e5e5e5e5e5e5b9e5e5f5000000000000000000000000000000000000000000d5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5e5b9b9e5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5f50000000000000000000000000000000000000000000000000000000000003500000000000000000000000000000000000000000000000000000000351010101010101010101010101010cf10cf10101010101010101010101010101010101010101010101010cf1010101010101010cf1010101010101010000000000000000000000000000000000000000000000000000000000000
-- 131:00000000000000000000000000c9d9d9d9d9d9d9d99999d9d9d9d9d9d9a90000000000000000000000000000000000000000000000000000000000c9d9d9d9d9d9d9d9d9d9d9d99999d9d9d9d9d9a9000000000000000000000000000000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000003510101010101010bf101010101010bfbf10101010bf1010101010101010101010cf101010101010101010101010101010bf1010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 132:000000000000000000000000000000000000000000675600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035101010101010101010101010bf10101010cf1010101010101010101010101010101010101010bf101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 133:00000000000000000000000000000000000000009f4545a4af000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000035b3b3b3b3b3b39c9d9d9d9d9d9d9d9d9d9d9d9d9d9d9eb3b3b3b3b3b3351010101010101010cf1010101010101010bf10101010bf1010101010101010101010101010101010101010101010101010101010101010cf10101010000000000000000000000000000000000000000000000000000000000000
-- 134:000000000000000000000000000000000000000085636363950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000deb3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3de101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 135:000000000000000040c2c2c2c2c2c2c241000000e6e4e4e4f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c999d9d9640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 003:ffffec94100000000000000369bcdeff
-- 004:0000ffffffffffffffffffffffff0000
-- 012:dddddddddddddddddddddddddddddddd
-- 013:01236deffffffffffffffeed64345420
-- 014:02131313120000000000000000000000
-- </WAVES>

-- <SFX>
-- 000:3fb09eb0dfa0eea0ffa0ff90ff80ff80ff80ff80ff70ff70ff70ff60ff60ff50ff50ff50ff40ff40ff30ff30ff30ff20ff20ff20ff10ff10ff00ff00600000000000
-- 001:2f032d2f3d1f5da77fb78fb7afc7bfc7cfd7dfd7efe7eff7eff7eff7fff7fff7fff7fff7fff7fff7fff7fff7fff7fff7fff7fff7fff7fff7fff7fff7207000000000
-- 002:0f0f1f0e2f0e2f0e3f0f3f014f026f026c027c017c008c008c009c00ac00ac00bc00bc00cc00cc00cc00cc00dc00ec00ec00ec00fc00fc00fc00fc0020700a00000a
-- 003:00b000b010b020b03000500070008000a000b000d000d000d000d000d000e000d000e000e000e000e000f000f000f000f000f000f000f000f000f000507000000000
-- 004:efe0dfe0dfe0cfe0cfe0bfe0bfe0afe09fe08fe07fe07fe06fe05fe05fe05fe05fe05fe06fe07fe08fe09fe0afe0bfe0cfe0dfe0dfe0efe0efe0ece0617000000000
-- 005:f0e0f0d0e0c0d0c0d0b0c0b0c0b0b0b0b0b0a0b090b090b080b070b070b070b070b070b070b080b080b090b0a0b0b0b0c0b0d0b0e0a0e0a0f090f060077000000000
-- 006:00703070707080709070a070a070b060b060c060c050d050d040d040e030e020e020f010f010f010f000f000f000f000f000f000f000f000f000f000007000000000
-- 007:b100a11091109120812081207130713071408140815091509160a160a160b170b170c170c180d190d190d1a0d1a0e1b0e1c0e1c0e1d0f1e0f1e0f1f0607000000000
-- 008:b1f0a1f091e081d081d081c071c071b071a081a081a09190a180a170b170b170b160c160c150c150d140d140e130e130e130e120f120f110f100f100407000000000
-- 009:90f0a0e0b0d0c0c0c0b0d0a0d090e080e070e060f060f050f040f040f030f020f020f020f010f010f010f000f000f000f000f000f000f000f000f000207000000000
-- 010:00f000f010e010e020d050c060b080a09090c090e090f090f090f090d090b0a080c070d050e030f010f000f010f030e050d080c0b0b0d0a0f090f090207000000000
-- 011:90009000f000f000f000900090009000f000f000f000900090009000f000f000f000f000f00090009000900090009000900090009000900090009000409000000000
-- 012:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000
-- 050:4fc07fc08fc0afc0dfc0efc0efc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0ffc0707000000000
-- 051:045004500450145014503450645074509450a450b450c450d450d450d450e450e450e450f450f450f450f450f450f450f450f450f450f450f450f450200000000000
-- 052:038003800380038003800380038003800380038013801380138023802380238033803380408040805080508060806080608070807080708080808080300000000000
-- 053:038003800380038003800380038013802380238023803380438043805380538063806380638063807380738073807380838083808380838083808380332000000000
-- 054:83808380838083808380938093809380a380a380a380b380b380b380c380c380c380d380d380d380e380e380e380e380f380f380f380f380f380f380000000000000
-- 060:030003000300030003000300030003000300030003400340034003401340134023403340434053406370737083709370a370b370d370e370f370f370324000000000
-- 061:030003000300030003000300030003000300030003700370037003700370037013701370137013701320132023202320232023202320232023202320320000000000
-- 062:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300202000000000
-- 063:12000200020002000200010011003100310051006100700080009000a000a000b100c100d100d100e100e200e200e200e200f100f100f100f100f100309000000000
-- </SFX>

-- <PATTERNS>
-- 000:b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827000000000000000000b00827b00827000000000000b00827000000000000000000b00827b00827000000000000b00827000000000000b00827
-- 001:b00837000000000000000000000000000000000000000000b00837000000000000000000000000b00837b00837000000600837000000000000000000000000000000000000000000600837000000000000000000000000600837600837000000400839000000000000000000000000000000000000000000b00837000000000000000000000000b00837b00837000000600837000000000000000000000000000000000000000000600837000000000000000000000000600837600837000000
-- 002:400847000000b00847000000400849000000800849000000b00845000000600847000000b00847000000f00847000000d00845000000800847000000d00847000000400849000000800845000000f00845000000800847000000b00847000000900845000000400847000000900847000000d00847000000400847000000b00847000000400847000000800847000000900845000000600847000000d00847000000400847000000b00847000000600847000000b00847000000f00847000000
-- 003:400857000000000000000000000000000000000000000000b00857000000000000000000000000000000000000000000400859000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00857b00857000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00857b00857000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00867
-- 004:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800857600857000000000000000000000000000000000000000000000000000000000000000000000000000000000000600857800857000000000000000000000000000000000000000000000000000000000000000000000000000000000000800867
-- 005:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400857400857000000000000000000000000000000000000000000000000000000000000000000000000000000000000400857600857000000000000000000000000000000000000000000000000000000000000000000000000000000000000400867
-- 006:000000000000000000b00867400857000000000000000000000000000000000000000000b00857000000000000000000000000000000000000000000400859000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00857b00857000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00867000000000000000000000000000000000000000000
-- 007:000000000000000000600867000000000000000000000000000000000000000000000000400857000000000000000000000000000000000000000000400857000000000000000000000000000000000000000000000000000000000000000000000000000000000000600857800857000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800867000000000000000000000000000000000000000000
-- 008:000000000000000000400867000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400857400857000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400867000000000000000000000000000000000000000000
-- 009:400847800847600847b00847000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:b70857000000000000000000000000000000000000000000b50857000000000000000000000000000000000000000000b30857000000000000000000000000000000000000000000b00857000000000000000000000000000000000000000000b00857000000000000000000b00857000000b00857000000b00857000000000000000000b00857000000b00857000000b00857000000000000000000b00857000000b00857000000b00857000000000000000000b00857000000b00857000000
-- 011:870857000000000000000000000000000000000000000000650857000000000000000000000000000000000000000000830857000000000000000000000000000000000000000000600857000000000000000000000000000000000000000000800857000000800857000000800857000000000000000000600857000000600857000000800857000000000000000000800857000000800857000000800857000000800857000000600857000000600857000000600857000000800857000000
-- 012:470857000000000000000000000000000000000000000000450857000000000000000000000000000000000000000000430857000000000000000000000000000000000000000000400857000000000000000000000000000000000000000000400857000000400857000000400857000000400857000000400857000000400857000000400857000000400857000000400857000000400857000000400857000000000000000000400857000000400857000000400857000000400857000000
-- 013:b00867000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00867000000000000000000000000000000000000000000b00867000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00867000000000000000000000000000000000000000000b00867000000000000000000000000000000000000000000b00867000000000000000000000000000000000000000000
-- 014:800867000000000000000000000000000000000000000000800867000000000000000000000000000000000000000000800867000000000000000000000000000000000000000000600867000000000000000000000000000000000000000000600867000000000000000000000000000000000000000000600867000000000000000000000000000000000000000000800867000000000000000000000000000000000000000000600867000000000000000000000000000000000000000000
-- 015:400867000000000000000000000000000000000000000000400867000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400867000000000000000000000000000000000000000000400867000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400867000000000000000000000000000000000000000000400867000000000000000000000000000000000000000000
-- </PATTERNS>

-- <TRACKS>
-- 000:a82300a823000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e0000
-- 001:641400d03b000d3ec01000c01800c01800c00d3ec00000000000000000000000000000000000000000000000000000002e0020
-- 002:0000c00000000000004556100000000000000000000000000000000000000000000000000000000000000000000000004c0000
-- </TRACKS>

-- <PALETTE>
-- 000:100c1ce234c6595971eeda6dc23830ce89408dc24414304885b6d271aaca4c5d6561717d994c408d9599a5aeaacad6ce
-- </PALETTE>

