-- title:  MadPhysicist
-- author: PEANUX Studio
-- desc:   I don't know. Maybe a Zelda-like game.
-- script: lua

-- predefine
CAMERA_OFF={15*8-4,8*8-4}
NEARBY4 = {{-1,0},{1,0},{0,-1},{0,1}}
FAKERANDOM8={4,2,7,5,1,8,3,6}
NEXTLEVEL={2,3,4,nil,4,4,4}

-- predefine set
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
local tmpAdd={4,20,68,69,131,132,148,144,17,83}
for i=1,#tmpAdd do
	table.insert(listTmp,tmpAdd[i])
end
MAP_COLLIDE=set(listTmp)
MAP_ENTER_DANGER=set({3,16,19,32,33,34,35,36,48,49,50,51,52,53,64,65,66,67,178,179,182,166,164,180})
MAP_ENTER_FREE=set({231,238,171,80,238})
MAP_REMAP_BLANK=set({208,224,225,226,227,228,240,241,242,243,244,245,144,197,213,176,177})
MAP_TOUCH=set({17,113,128,165,181})
MAP_WATER=set({171})
MAP_BUTTER=set({238})
MAP_LAVA=set({3,16,19,32,33,34,35,36,48,49,50,51,52,53,64,65,66,67})

-- region TXT
TEXTS={gameover={"YOU DEID!"},
	{"What the fck, you are a fantasy physical boy. ",
"Welcome to Super.Hyper.Incredible.Fhysical.Tower. ",
"REMEMBER to use physical artifact and your ",
"physical caliber."}
}
-- endregion

-- region base class
function damage(iValue, iElem)
	dmg={
		value=iValue,
		elem=iElem or 0
	}
	return dmg
end

function entity(x,y,w,h)
	local ety = {
		x=x,
		y=y,
		w=w,
		h=h,
		noEntityCollide=false,
		noMapCollide=false,
		pullMul=1,
		pushMul=1,
		tmMul=1, --time machine multi

		tCollided=false,
		tMoved=false
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
			else
				self.x=self.x-dx
			end
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
		--todo: calc touch
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
	function ety:touch()
	end
	function ety:enter()
	end
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
-- endregion

-- region PLAYER
-- _player
player=entity(32,60,16,16)
player.fwd = {1,0}
player.hp=50
player.maxHp=100
player.attack = 5
player.state = 0
player.ti1 = 0
player.key1=0
player.tiStun=0
player.lastBtn5=0
player.lastBtn6=0
player.lastBtn7=0
player.onButter=false
player.lastMove={0,0}
player.onFireTile=false
player.onFireTic=0
function player:atkRect()
	local p=self
	local ar=10
	local ox=0
	local oy=0
	if(p.fwd[1]==1)then
		res={p.x+p.w,p.y,10,16}
	elseif(self.fwd[1]==-1)then
		res={p.x-ar,p.y,10,16}
	elseif(self.fwd[2]==1)then
		res={p.x,p.y+p.h,16,10}
	elseif(self.fwd[2]==-1)then
		res={p.x,p.y-ar,16,10}
	end
	return res
end
function player:startAttack()
	if(self.state==0) then
		self.state=1
		self.ti1=30
		self.willAtk=true
	end
end
function player:meleeCalc()
	local ar = self:atkRect()
	hitList = boxOverlapCast(ar)
	for i=1,#hitList do
		local tar=hitList[i]
		if(tar~=self and tar.canHit) then
			local knockback=self.fwd
			-- todo: knockback check
			if(tar.canHit)then
				tar:onHit(damage(self.attack,0))
				if(tar.tiStun>0 or tar.canKnockBack)then
					for i=1,10 do tar:move(knockback[1],knockback[2],true) end
				end
			end
		end
	end
end
function player:onHit(dmg)
	if(dmg.value<0)then 
		self:hpUp(-dmg.value)
	else
		self.hp=self.hp-dmg.value
		if(self.hp<0)then self.hp=0 player.dead=true GameOverDialog() end
	end
end
function player:hpUp(value)
	self.hp=self.hp+value
	if(self.hp>100)then self.hp=100 end
	starDust(self.x+4,self.y,12,16,6,6,15,5)
	if(inbossBattle and self.hp>=self.maxHp) then player.dead=true GameOverDialog() end
end
function player:getKey()
	self.key1=self.key1+1
end
function player:control()
	-- controller
	local dx,dy=0,0
	if(self.state~=-1) then
		if btn(0) then dy=-1 player.fwd={0,-1} end
		if btn(1) then dy=1 player.fwd={0,1} end
		if btn(2) then dx=-1 player.fwd={-1,0} end
		if btn(3) then dx=1 player.fwd={1,0} end
	end
	if(dx==0 and dy==0)then
		player:move(0,0,true)
	else
		player:movec(dx*self.tmMul,dy*self.tmMul,true)
	end

	if btn(4) then player:startAttack() end
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
function player:update()
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
		player:control()
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
function player:draw()
	if(player.dead)then sprc(268,self.x,self.y,6,1,sprFlip,0,2,2) return end
	local sprFlip=(1-self.fwd[1])//2
	local sprite=260
	if(player.fwd[2]==1) then sprite=256 elseif(player.fwd[2]==-1) then sprite=264 end
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
			sprite=296
			drawX=2
			drawY=3
			offY=-8
		end
		if self.ti1>=20 then sprc(sprite,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
		elseif self.ti1>=15 then sprc(sprite+drawX,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
		elseif self.ti1>=5 then sprc(sprite+drawX*2,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
		else sprc(sprite+drawX*3,self.x+offX,self.y+offY,6,1,sprFlip,0,drawX,drawY)
		end
	end
end
function player:touch(tile)
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
function player:enter(tile)
	local tileId,tx,ty=tile[1],tile[2],tile[3]
	if(tileId==178)then
		mset_4ca(tx,ty,255,178)
	elseif(tileId==179)then
		mset_4ca(tx,ty,255,179)
	elseif(MAP_LAVA:contains(tileId))then
		self:onHit(damage(1))
	elseif(tileId==231)then
		loadLevel(NEXTLEVEL[curLevel])
		-- if(curLevel<5)then
		--   loadLevel(curLevel+1)
		-- else
		-- 	loadLevel(4)
		-- end
	elseif(tileId==238)then
		self.onButter=true
	elseif(tileId==80)then
		self.onFireTile=true
	elseif(tileId==182 or tileId==166)then
		self.willKnockWithDmg=true
	elseif(tileId==180 or tileId==164)then
		self.willKnockWithDmg=true
	end
end
-- endregion

-- region ARTIFACT
-- region the Gravation
theGravition=artifact(60,15)
theGravition.range=10*8
theGravition.rangePow2=theGravition.range*theGravition.range
theGravition.force=5
theGravition.sprite=384
function theGravition:use()
	if(self:switchOn())then
		trace("the Gravition ON!")
	end
end
function theGravition:pull(isReverse)
	for i=1,#mobManager do
		local m=mobManager[i]
		if(m and m~=player)then
			--self:iPull(m,isReverse)
			iPull(player,m,isReverse,self.force,self.rangePow2)
		end
	end
	for i=1,#envManager do
		local e=envManager[i]
		if(e)then	iPull(player,e,isReverse,self.force,self.rangePow2) end
	end
end
function theGravition:push()
	self:pull(true)
end
function theGravition:update()
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
function theGravition:draw()
	if(self.inWorking)then
		local rscale=self.tiDur/15
		if(self.mode==0)then rscale=1-rscale end
		if(rscale>1)then rscale=0 end
		local cp=CenterPoint(player)
		circbc(cp[1],cp[2],self.range*rscale,1)
		circbc(cp[1],cp[2],self.range*rscale-1,15)
	end
end
-- endregion

theTimeMachine=artifact(180,150)
function theTimeMachine:init()
	self.range=10*8
	self.rangePow2=theTimeMachine.range*theTimeMachine.range
	self.speedUpMul=2
	self.speedDownMul=2
	self.effectedObject={}
	self.rClock={}
	self.hHandPos={}
	self.mHandPos={}
	self.sprite=392

	for i=1,48 do
		--local r=
		local cos=math.cos(i*3.14/24)
		local sin=math.sin(i*3.14/24)
		self.hHandPos[i]={sin*3*8,-cos*3*8}
		self.mHandPos[i]={sin*4*8,-cos*4*8}
	end
end
theTimeMachine:init()
function theTimeMachine:use()
	if(self:switchOn())then
		trace("the TimeMachine ON!")
		if(self.mode==0)then
			player.tmMul=2
			table.insert(self.effectedObject,player)
		else
			for i=1,#mobManager do
				local m=mobManager[i]
				if(m and m~=player and m.tmMul~=0)then
					local dv=CenterDisVec(player,m)
					local mdis=dv[1]*dv[1]+dv[2]*dv[2]
					if(mdis<self.rangePow2)then m.tmMul=0.5 table.insert(self.effectedObject,m) end
				end
			end
		end
	end
end
function theTimeMachine:onTimeOut()
	for i=1,#theTimeMachine.effectedObject do
		local obj=theTimeMachine.effectedObject[i]
		if(obj)then	
			obj.tmMul=1 
			theTimeMachine.effectedObject[i]=nil
		end
	end
end
function theTimeMachine:update()
	if(self.inWorking)then
		self.tiDur=self.tiDur+1
		if(self.tiDur>self.durTime)then self:onTimeOut() self:switchOff() end
	end
	if(self.tiCD>0)then self.tiCD=self.tiCD-1 end
end
function theTimeMachine:draw()
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
			local cp=CenterPoint(player)
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
					pixc(obj.x+pt,obj.y,c1) 
					pixc(obj.x+obj.w-pt,obj.y+obj.h-1,c1)
				else 
					pixc(obj.x+obj.w-1,obj.y+pt-obj.w,c1)
					pixc(obj.x,obj.y+obj.h-pt+obj.w,c1) 
				end
			end
		end
	end
end

theKelvinWand=artifact(60,30)
theKelvinWand.sprite=388
function theKelvinWand:use()
	self:switchOn()
end
function theKelvinWand:cast()
	local elem=1
	if(self.mode==1)then elem=2 end
	local cp=CenterPoint(player)
	table.insert(envManager,KelvinBullet(cp[1],cp[2],player.fwd,1,elem))
end
function theKelvinWand:update()
	if(self.inWorking)then
		if(self.tiDur==0) then self:cast() end
		self.tiDur=self.tiDur+1
		if(self.tiDur>self.durTime)then self:switchOff() end
	end
	if(self.tiCD>0)then self.tiCD=self.tiCD-1 end
end
function theKelvinWand:draw()
end
-- endregion

-- region MOB
-- _mob
function mob(x,y,w,h,hp,alertR)
	local m=entity(x,y,w,h)
	m.hp=hp
	m.maxHp=hp
	m.state=0
	m.sleep=true
	m.alertRange=alertR or 0
	m.ms=1
	m.rawMs=m.ms
	m.dmgStunTresh=0
	m.stunTime=30
	m.stunTime_shockTile=120
	m.tiStun=0
	m.canHit=true
	m.isDead=false
	m.tiFire=0
	m.tiIce=0
	function m:onHit(dmg,noStun)
		if(self.canHit)then 
			self.sleep=false
			self.hp=self.hp-dmg.value
			trace("mob hp"..self.hp)
			if(not noStun and dmg.value>self.dmgStunTresh)then self.tiStun=self.stunTime end
			if(dmg.elem==1)then self.tiFire=150 elseif(dmg.elem==2)then self.tiIce=30 end
			if(self.hp<=0)then self:death() end
			return true
		end
		return false
		-- todo: element attack
	end
	function m:onDeath()
	end
	function m:death()
		self:onDeath()
		-- todo: do something like score change
		if(m.isDead)then return false end
		for i=1,#mobManager do
			if(mobManager[i]==self)then table.remove(mobManager,i) end
		end
		m.isDead=true
		shine(self.x,self.y,self.w//8)
		return true
	end
	function m:tryAwake()
		local d=MDistance(self,player)
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
		if(MAP_LAVA:contains(tileId))then
			self:death()
		elseif(tileId==80)then
			self.onFireTile=true
			--if(t%20==0)then self:onHit(damage(1))end
			--todo: default buff calc to avoid multi tile hit per tic
		elseif(tileId==182 or tileId==166)then
			self:death()
		end
	end
	function m:defaultMove(needDis)
		local dv=CenterDisVec(player,self)
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
			self.tiStun=self.tiStun-self.tmMul
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
-- region _NORMAL MOB
function slime(x,y)
	local s = mob(x,y,8,8,15,5*8)
	s.ms=0.5
	s.tiA=0
	s.fwd={-1,0}
	s.meleeRange=(16+8)//2+6
	s.attack=1
	s.waitMeleeCalc=false
	s.tA1=35 --attack calc
	s.tA2=90 --keep idle
	s.tA3=120 --return move
	function s:startAttack()
		self.state=1
		self.tiA=0
		self.waitMeleeCalc=true
	end
	function s:meleeCalc()
		local atkBox={x=self.x+8*self.fwd[1],y=self.y+8*self.fwd[2],w=8,h=8}
		if(iEntityCollision(player,atkBox))then player:onHit(damage(self.attack)) end
	end

	function s:update()
		if(not self:defaultUpdate())then return end
		if(self.state==0)then
			local dv,dvn=self:defaultMove()
			if((math.max(math.abs(dv[1]),math.abs(dv[2])))<=self.meleeRange)then
				self.fwd=dvn
				self:startAttack()
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
	rg.ms=0
	rg.tiA=0
	rg.attack=5
	rg.range=10*8
	rg.waitShoot=false
	rg.tA1=30 --attack
	rg.tA2=60 --keep no anim
	rg.tA3=90 --idle anim
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
		--todo:shoot
	end
	function rg:update()
		if(not self:defaultUpdate())then return end
		-- self:defaultTileCalc()
		-- if(not self:defaultElem())then return end
		-- if(self.tiStun>0)then
		-- 	self.state=0
		-- 	self.tiStun=self.tiStun-self.tmMul
		-- 	return
		-- end
		-- if(self.sleep)then
		-- 	self:tryAwake()
		-- 	return
		-- end
		local sx=self.x+self.w//2
		local sy=self.y+self.h//2
		local tx=player.x+player.w//2
		local ty=player.y+player.h//2
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
				sprc(496+t//(20/self.tmMul)%2 * 1,self.x,self.y,0,1,0,0,1,1)
			end
		end
		self:drawElem()
	end

	return rg
end

function staticRanger(x,y,fwd)
	local srg=ranger(x,y)
	srg.fwd=fwd
	srg.sleep=false
	srg.pullMul=0
	srg.pushMul=0
	srg.tA1=5
	srg.tA2=15
	srg.tA3=15
	srg.dmgStunTresh=999
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
	bm.hp=5
	bm.alertRange=8*8
	bm.ms=2
	bm.tA1=15 -- explode time
	bm.tA2=300
	bm.tA3=300
	bm.fwd={-1,0}
	bm.meleeRange=(16+8)//2+1
	bm.attack=5
	bm.stunTime=1
	bm.canKnockBack=true

	function bm:startAttack()
		self.canKnockBack=false
		self.state=1
		self.tiA=0
		self.waitMeleeCalc=true
	end
	function bm:meleeCalc()
		local atkBox={x=self.x-8,y=self.y-8,w=24,h=24}
		hitList = boxOverlapCast(atkBox)
		for i=1,#hitList do
			local tar=hitList[i]
			if(tar~=self and tar.canHit) then
				tar:onHit(damage(self.attack*5,0))
			elseif(tar==player)then
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
			--self.hp=self.hp-dmg.value
			--if(not noStun and dmg.value>self.dmgStunTresh)then self.tiStun=0 end
			if(dmg.elem==1)then 
				self.tiFire=150
				trace("fire")
				if(self.state==0)then	self:startAttack() end
			elseif(dmg.elem==2)then 
				self.tiIce=30
			end
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
			if(self.tiA<60)then 
				sprc(485,self.x,self.y,14,1,0,0,1,1)
			else
				sprc(483,self.x,self.y,14,1,0,0,1,1)
			end
		end
		self:drawElem()
	end

	return bm
end

function bomb(x,y)
	local bb=bombMan(x,y)
	bb.tmMul=0
	bb.alertRange=0
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
			sprc(161,self.x,self.y,14,1,0,0,1,1)
		elseif(self.state==1) then
			if(self.tiA<60)then 
				sprc(116,self.x,self.y,14,1,0,0,1,1)
			else
				sprc(116,self.x,self.y,14,1,0,0,1,1)
			end
		end
		self:drawElem()
	end

	return bb
end
-- endregion

-- region _ELITE
function chargeElite(x,y)
	local ce = mob(x,y,16,16,200,10*8)
	ce.ms=0.5
	ce.chargeMs=3
	ce.tiA=0
	ce.fwd={-1,0}
	ce.meleeRange=(16+16)//2+8*4
	ce.attack=10
	ce.waitMeleeHit=false
	ce.dmgStunTresh=10
	ce.tA1=20 --start charge
	ce.tA2=20+40 --in charging
	ce.tA3=20+40+90 --charge finish -> rest
	ce.tA4=20+40+90+60 --return move
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
		if(iEntityCollision(player,atkBox))then 
			player:onHit(damage(self.attack))
			self:forceStop()
			player:movec(self.fwd[1]*4,self.fwd[2]*4,true)
			player.tiStun=30
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
			--if(self.tiA>=90)then end
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
	local le = mob(x,y,16,16,100,10*8)
	le.ms=0.5
	le.tiA=0
	le.fwd={-1,0}
	le.meleeRange=(16+16)//2+8
	le.laserRange=(16+16)//2+120
	le.meleeAttack=5
	le.laserAttack=10
	le.waitAttackCalc=false
	le.pullMul=0.5
	le.pushMul=0.5
	le.dmgStunTresh=10
	le.tA1=40 --hold->up
	le.tA2=55 --up->down
	le.tA3=60 --down->calc
	le.tA4=90 --keep idle
	le.tA5=120 --return move
	le.tAl1=60 --hold->emit(calc)
	le.tAl2=90 --emit->emit finish
	le.tAl3=120 --return move
	function le:startMeleeAttack()
		self.state=1
		self.tiA=0
		self.waitAttackCalc=true
	end
	function le:startLaserAttack()
		self.state=2
		self.tiA=0
		self.waitAttackCalc=true
	end
	function le:meleeCalc()
		local atkBox={x=self.x-16,y=self.y-16,w=48,h=48}
		hitList = boxOverlapCast(atkBox)
		for i=1,#hitList do
			local tar=hitList[i]
			if(tar==player) then
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
			if(PointInEntity({lx,ly},player,2))then
				player:onHit(damage(self.laserAttack,0))
				break
			end
		end
	end
	function le:leMove()
		local dv=CenterDisVec(player,self)
		local dvn=vecNormFake(dv,1)
		local _tmMul=self.tmMul
		if(self.tmMul<=0)then _tmMul=1 end
		local distance=(math.max(math.abs(dv[1]),math.abs(dv[2])))
		if(distance<=(self.meleeRange))then
			self:movec(-dvn[1]*self.ms*_tmMul,-dvn[2]*self.ms*_tmMul)
		elseif(distance>(self.laserRange-6*8))then
			self:movec(dvn[1]*self.ms*_tmMul,dvn[2]*self.ms*_tmMul)
		end
		--self:movec(dvn[1]*self.ms*_tmMul,dvn[2]*self.ms*_tmMul)
		return dv,dvn,distance
	end
	function le:update()
		if(not self:defaultUpdate())then return end
		if(self.state==0)then
			local dv,dvn,distance=self:leMove()
			if(distance<=self.meleeRange)then
				--self.fwd=dvn
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
				--linec(sx,sy,sx+self.fwd[1]*240,sy+self.fwd[2]*240,8) end
			else
				sprc(422+t//(20/self.tmMul)%2 * 2,self.x,self.y,14,1,0,0,2,2)
			end
		end
		self:drawElem()
		if(self.hp<self.maxHp)then self:drawHp() end
	end
	return le
end
-- endregion

-- region _BOSS
-- region Trinity
Trinity={}
function Trinity:init(x,y)
	self.hp=1000
	self.uiHp=1000
	self.maxHp=1000
	self.stackDmg=0
	self.tarDmg=100
	self.x=x
	self.y=y
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

	self.active=true
end
function Trinity:onHit(dmg)
	self.hp=self.hp-dmg.value
	self.stackDmg=self.stackDmg+dmg.value
	if(self.stackDmg>=self.tarDmg)then self.stackDmg=self.stackDmg-self.tarDmg player:onHit(damage(25)) end
	if(self.hp<=0)then self:death() end
end
function Trinity:death()
	self.nt.death()
	self.gl.death()
	self.kl.death()
	self.active=false
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
--Trinity:init()
-- endregion


function Newton(x,y)
	local nt=mob(x,y,16,16,300,0)
	nt.maxHp=nt.hp
	nt.dmgStunTresh=150
	nt.stunTime=900
	nt.ms=0.75
	nt.tiA=0
	nt.fwd={-1,0}
	nt.leaveRange=5*8
	nt.apprRange=6*8
	nt.meleeRange=10*8+4
	nt.attack=1
	nt.waitAttackCalc=false
	nt.force=1
	nt.pullMul=0
	nt.pushMul=0
	-- nt.tmMul=0
	-- nt.tRMC=60 --random move change
	-- nt.randFwd={0,0}
	nt.mem=0
	nt.mem1=0
	nt.mem2=0
	nt.tA1={60,90,120,120}
	nt.tA2={60,70,120,210}
	nt.tA3={120,150,210,330}

	function nt:onHit(dmg,noStun)
		Trinity:onHit(dmg)
		if(self.canHit)then
			self.sleep=false
			self.hp=self.hp-dmg.value
			if(self.maxHp-self.hp>self.dmgStunTresh)then self.tiStun=self.stunTime end
			if(self.tiStun>0)then self.maxHp=self.hp end
			if(dmg.elem==1)then self.tiFire=150 elseif(dmg.elem==2)then self.tiIce=30 end
			--if(self.hp<=0)then self:death() end
			return true
		end
		return false
	end
	function nt:startAttack(index)
		self.state=index
		self.tiA=0
		self.waitAttackCalc=true
		self.mem=index
		--starDust(x,y,w,h,num,color,tLife,tGenInter)
		if(index==2)then 
			self.mem1=self.mem1+1 starDust(self.x,self.y,16,16,10,1,15,5)
		elseif(index==3)then 
			starDust(self.x,self.y,16,16,40,15,15,5)
		else
			starDust(self.x,self.y,16,16,10,6,15,5)
		end
	end
	function nt:pull(isReverse)
		iPull(self,player,isReverse,self.force*0.5)
		for i=1,#envManager do
			local e=envManager[i]
			if(e)then	
				iPull(self,e,isReverse,self.force)
				if(not isReverse)then
					local vec=CenterDisVec(self,e)
					if(math.abs(vec[1])+math.abs(vec[2])<=4)then e:remove() end
				end
			end
		end
	end
	function nt:emitApple(fwd)
		local cp=CenterPoint(self)
		local ax,ay=cp[1]-4+fwd[1]*8,cp[2]-4+fwd[2]*8
		local ap=apple(ax,ay)
		table.insert(envManager,ap)
		dust(ax,ay,5,{5,3,3,3},2)
	end
	function nt:iMove(noMove)
		local dv=CenterDisVec(player,self)
		local dvn=vecNormFake(dv,1)
		local _tmMul=self.tmMul
		if(self.tmMul<=0)then _tmMul=1 end
		local distance=(math.max(math.abs(dv[1]),math.abs(dv[2])))
		if(noMove)then return dv,dvn,distance end
		if(distance<=(self.leaveRange))then
			self:movec(-dvn[1]*self.ms*_tmMul,-dvn[2]*self.ms*_tmMul)
		elseif(distance>(self.apprRange))then
			self:movec(dvn[1]*self.ms*_tmMul,dvn[2]*self.ms*_tmMul)
		else
			-- if(t%self.tRMC==0)then
			-- 	local fx=-1+2*math.random()
			-- 	local fy=-1+2*math.random()
			-- 	self.randFwd=vecNormFake({fx*2,fy*2},1)
			-- 	trace(self.randFwd[1])
			-- 	trace(self.randFwd[2])
			-- end
			-- self:movec(self.randFwd[1]*self.ms*_tmMul,self.randFwd[2]*self.ms*_tmMul)
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
					self.mem1=0
					self.mem2=0
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
			sprc(448,self.x,self.y,14,1,0,0,2,2)
			self:drawStun()
		elseif(self.state==0)then
			sprc(sprite,self.x,self.y,14,1,0,0,2,2)
		elseif(self.state==1) then
			if(self.tiA<self.tA1[1])then
				sprc(452,self.x,self.y,14,1,0,0,2,2)
			else
				sprc(sprite,self.x,self.y,14,1,0,0,2,2)
			end
		elseif(self.state==2) then
			local scale=(self.tiA-self.tA2[2])/(self.tA2[3]-self.tA2[2])
			if(self.tiA<self.tA2[1])then
				sprc(452,self.x,self.y-16*((self.tiA)/(self.tA2[1])),14,1,0,0,2,2)
			elseif(self.tiA<self.tA2[2])then
				sprc(452,self.x,self.y-16*(1-scale),14,1,0,0,2,2)
			elseif(self.tiA<self.tA2[3])then
				sprc(448,self.x,self.y,14,1,0,0,2,2)
			else
				sprc(sprite,self.x,self.y,14,1,0,0,2,2)
			end
			if(self.tiA>self.tA2[2] and self.tiA<self.tA2[3])then
				circbc(self.x+8,self.y+8,240*scale,1)
				circbc(self.x+8,self.y+8,240*scale-1,14)
				circbc(self.x+8,self.y+8,240*scale-2,15)
			end
		elseif(self.state==3) then
			local scale=(self.tiA-self.tA3[2])/(self.tA3[3]-self.tA3[2])
			if(self.tiA<self.tA3[1])then
				sprc(452,self.x,self.y,14,1,0,0,2,2)
			elseif(self.tiA<self.tA3[2])then
				sprc(452,self.x,self.y,14,1,0,0,2,2)
			elseif(self.tiA<self.tA3[3])then
				sprc(448,self.x,self.y,14,1,0,0,2,2)
			else
				sprc(sprite,self.x,self.y,14,1,0,0,2,2)
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
	gl.hp=400
	gl.maxHp=400
	gl.dmgStunTresh=200
	gl.stunTime=900
	gl.ms=1
	gl.meleeAttack=-10
	gl.meleeRange=4*8
	gl.pullMul=0.5
	gl.pushMul=0.5
	gl.tmMul=0
	gl.tA1={60,90,150,210}

	function gl:startAttack(index)
		self.state=index
		self.tiA=0
		self.waitAttackCalc=true
		self.mem=index
		--starDust(x,y,w,h,num,color,tLife,tGenInter)
		starDust(self.x,self.y,16,16,15,2,15,5)
	end
	function gl:ballCalc()
		local atkBox={x=self.x+16*self.fwd[1],y=self.y+16*self.fwd[2],w=24,h=24}
		hitList = boxOverlapCast(atkBox)
		for i=1,#hitList do
			local tar=hitList[i]
			if(tar==player) then
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
			--if(self.tiA<self.tA1[1])then _t=self.tmMul end
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
	kl.hp=200
	kl.maxHp=200
	kl.dmgStunTresh=100
	kl.stunTime=900
	kl.leaveRange=3*8
	kl.apprRange=6*8
	kl.ms=0.5
	kl.meleeAttack=10
	kl.pullMul=0.5
	kl.pushMul=0.5
	kl.tmMul=0
	kl.tA1={60,90,150,450}

	function kl:startAttack(index)
		self.state=index
		self.tiA=0
		self.waitAttackCalc=true
		self.mem=index
		starDust(self.x,self.y,16,16,10,8,15,5)
	end
	function kl:castIceBall()
		table.insert(mobManager,KelvinIceBall(self.x,self.y))
	end
	function kl:update()
		local _t=1
		self.tiIce=0
		self.tiFire=0
		if(not self:defaultUpdate())then return end
		if(self.state==0)then
			local dv,dvn,dis=self:iMove()
			if(dis<=self.apprRange)then
				self:startAttack(1)
				--self.fwd=dvn
			end
		elseif(self.state==1)then
			if(self.tiA>=self.tA1[1] and self.waitAttackCalc)then
				self.waitAttackCalc=false
				self:castIceBall()
			end
			--if(self.tiA<self.tA1[1])then _t=self.tmMul end
			self.tiA=self.tiA+_t
			if(self.tiA>=self.tA1[3])then self:iMove() end
			if(self.tiA>=self.tA1[4])then self.state=0 end
		end
	end
	function kl:draw()
		local _t=1
		local sprite=486+t//(20/_t)%2 * 2
		if(self.tiStun>0)then
			sprc(486,self.x,self.y,1,1,0,0,2,2)
			self:drawStun()
		elseif(self.state==0)then
			sprc(sprite,self.x,self.y,1,1,0,0,2,2)
		elseif(self.state==1) then
			if(self.tiA<self.tA1[1])then
				--rectbc(self.x+16*self.fwd[1],self.y+16*self.fwd[2],24,24,3+t//2%3)
				--sprc(368,self.x+16*self.fwd[1],self.y+16*self.fwd[2]-(1-(self.tiA/self.tA1[1]))*80,0,3,0,0,1,1)
				sprc(490,self.x,self.y,1,1,0,0,2,2)
			else
				sprc(sprite,self.x,self.y,1,1,0,0,2,2)
			end
		end
		self:drawElem()
	end
	return kl
end

function KelvinIceBall(x,y)
	local km=bombMan(x,y)
	km.hp=2
	km.h=16
	km.w=16
	km.tiLife=300
	km.noEntityCollide=true
	km.noMapCollide=true
	km.ms=0.25
	km.meleeRange=12
	km.attack=-10
	km.pullMul=0.5
	km.pushMul=0.5
	km.tmMul=0
	km.sleep=false

	function km:meleeCalc()
		local atkBox={x=self.x-8,y=self.y-8,w=32,h=32}
		hitList = boxOverlapCast(atkBox)
		for i=1,#hitList do
			local tar=hitList[i]
			if(tar==player)then
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
		-- warning update in draw
		if(self.tiLife<=0)then self:meleeCalc() end
		self.tiLife=self.tiLife-1
		--
		sprc(371,self.x,self.y,0,2,0,0,1,1)
		if(self.state==1 and self.tiA<self.tA1)then
			rectbc(self.x-8,self.y-8,32,32,8)
		end
		self:drawElem()
	end

	return km
end

-- endregion

-- region FakeMob
function fence(x,y)
	local fe=mob(x,y,8,8,-1,-1)
	fe.pullMul=0
	fe.pushMul=0
	fe.tmMul=0
	fe.canHit=false

	function fe:update()
	end
	function fe:draw()
	end

	return fe
end

function weakRock(x,y)
	local wr=mob(x,y,8,8,1,-1)
	wr.pullMul=0
	wr.pushMul=0
	wr.tmMul=0

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
	ft.noEntityCollide=true
	ft.pullMul=0
	ft.pushMul=0
	ft.tmMul=0
	ft.rawChangeTime=1
	ft.tiC=0
	ft.sprite=182
	ft.horSprite=166

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
		trace(self)
		self.tailx=self.x//8
		self.taily=self.y//8
		for i=1,#NEARBY4 do
			local tfwd=NEARBY4[i]
			local tileId=mget(iMapManager.offx+self.x//8+tfwd[1],iMapManager.offy+self.y//8+tfwd[2])
			trace(tileId)
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
			trace("Tentacle has no fwd. put tile "..self.sprite.." around it.")
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
	it.tiC=0
	it.sprite=164
	it.horSprite=180

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

-- endregion

-- endregion

-- region ITEM
function item(x,y,w,h)
	local it = entity(x,y,w,h)
	it.noEntityCollide=true

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
		player:hpUp(5)
		-- todo:play something
		self:remove()
	end

	function app:update()
		if(iEntityTrigger(player,self))then self:onTaken() end
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
		player:getKey()
		mset(self.tx,self.ty,255)
		-- todo:play something
		self:remove()
	end

	function k:update()
		if(iEntityTrigger(player,self))then self:onTaken() end
	end
	function k:draw()
		sprc(208,self.x,self.y,14,1,0,0,1,1)
	end

	return k
end

function portal(x,y,code)
	local p=item(x,y,16,16)
	p.code=code

	function p:onTaken()
		loadLevel(self.code+5)
	end
	function p:update()
		if(iEntityTrigger(player,self))then self:onTaken() end
	end
	function p:draw()
		local s=460+t//10%3 * 2
		if(t//10%3==2)then s=428 end
		sprc(s,self.x,self.y-t//30%2 * 2,14,1,0,0,2,2)
	end

	return p
end
-- endregion

-- region BULLET
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
			if(iEntityTrigger(player,self))then return self:hit(player) end
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
		--pixc(self.x,self.y,4)
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
		--pixc(self.x,self.y,4)
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
				--if(inbossBattle)then mset_4ca_set(tx,ty,255,MAP_BUTTER) else
				mset_4ca_set(tx,ty,80,MAP_BUTTER) 
				--end
				self:remove()
			end
		elseif(self.elem==2)then
			if(MAP_WATER:contains(tileId))then
				--if(inbossBattle)then mset_4ca_set(tx,ty,255,MAP_WATER) else
				mset_4ca_set(tx,ty,17,MAP_WATER) 
				--end
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
-- endregion

-- region EFFECT
function effect(x,y,w,h)
	local ef = entity(x,y,w,h)
	ef.noEntityCollide=true
	ef.noMapCollide=true
	ef.pullMul=0
	ef.pushMul=0
	ef.after=false

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
		if(self.ti>5)then
			color=5
		elseif(self.ti>10)then
			color=12
		elseif(self.ti>15)then
			color=0
		end
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
		if(self.ti>5)then
			color=self.c[2]
		elseif(self.ti>10)then
			color=self.c[3]
		elseif(self.ti>15)then
			color=self.c[4]
		end
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
	st.ti=0
	st.color=color
	st.tLife=tLife
	st.maxDis=maxDis
	st.after=true
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
	--ds.maxTime=ds.num*ds.tGenInter

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

function shockScreen(magnitude,times,changeX)
	local ss=effect(0,0,0,0)
	ss.ti=0
	ss.mag=magnitude
	ss.times=times
	ss.maxTime=times*magnitude*4
	ss.increase=true
	ss.curMag=0
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
		
-- endregion

-- region TOOL
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


function mset_4ca(x,y,mid,smid) --4-connected area
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
	-- local b={x=box[1],y=box[2],w=box[3],h=box[4]}
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
	--trace(ety.noMapCollide)
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
-- endregion

-- region DIALOG
function dialog(index,noAutoActive)
	local dl={}
	if(not noAutoActive)then dl.txts=TEXTS[index] end
	
	function dl:afterRemove()
	end
	function dl:remove()
		for i=1,#uiManager do
			if(uiManager[i]==self)then table.remove(uiManager,i) end
		end
		self:afterRemove()
	end
	-- function dl:update()
	-- 	if(btn(4))then trace("btn") self:remove() end
	-- end
	function dl:draw()
		if(btn(4))then self:remove() end
		rectb(2*8-1,12*8-1,26*8+2,4*8+4+2,15)
		rect(2*8,12*8,26*8,4*8+4,0)
		for i=1,#dl.txts do
			print(dl.txts[i],2*8+4,12*8-4+i*8,15,1,1,true)
		end
	end

	if(not noAutoActive)then table.insert(uiManager,dl) end
	return dl
end

function GameOverDialog()
	local gd=dialog(0)
	gd.txts=TEXTS.gameover

	function gd:afterRemove()
		gameOver()
	end
	table.insert(uiManager,gd)
end

function LoadMapCode(tx,ty)
	local code=0
	local is={0,0,0}
	if(mget(tx+1,ty)==176)then code=code+4 end
	if(mget(tx,ty+1)==176)then code=code+2 end
	if(mget(tx+1,ty+1)==176)then code=code+1 end
	return code
end
	
-- endregion

-- region MANAGER
function redraw(tile,x,y)
	local outTile,flip,rotate=tile,0,0
	if(MAP_REMAP_BLANK:contains(tile))then
		outTile=255
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
	end
	return outTile,flip,rotate
end

iMapManager={offx=0,offy=0}
-- function iMapManager:update() end
function iMapManager:draw()
	--map(cell_x,cell_y,cell_w,cell_h,x,y,alpha_color,scale,remap)
	map(5*30,7*17,31,18,-30*8+(3*t)%(60*8),0,1,1)
	map(5*30,7*17,31,18,-30*8+(3*t-30*8)%(60*8),0,1,1)
	--map(5*30+60*(t//2%60),7*17,31,18,0,0,1,1)
	map(0+self.offx+camera.x//8,0+self.offy+camera.y//8,31,18,8*(camera.x//8)-camera.x,8*(camera.y//8)-camera.y,1,1,redraw)
end

uiStatusBar={hp=player.hp}
function uiStatusBar:draw()
	local tmp_=0
	rect(7,7+tmp_,100+4,7,15)
	if self.hp>player.hp then 
		rect(9, 9+tmp_, self.hp, 3, 4)
		self.hp = self.hp-1/60*10  
	else
		self.hp=player.hp
	end
	rect(9,9+tmp_,player.hp,3,6)

	local key1=player.key1
	for i=1,key1 do
		spr(208,-3+10*i,15,14,1,0,0,1,1)
	end

	for i=1,3 do
		local atf=atfManager[i]
		spr(atf.sprite+2*atf.mode,7+(16+4)*(i-1),14*8,1,1,0,0,2,2)
		if(atfManager[i].inWorking)then
			rect(7+(16+4)*(i-1),15*8-6,16*(1-atf.tiDur/atf.durTime),5,6)
		elseif(atf.tiCD>0)then
			rect(7+(16+4)*(i-1),15*8-6,16*(1-atf.tiCD/(atf.cdTime-atf.durTime)),5,2)
		end
	end
	print("X",7,15*8+8,15)
	print("Y",7+16+4,15*8+8,15)
	print("B",7+20*2,15*8+8,15)
end

uiKeyBar={}
function uiKeyBar:draw()
	local key1=player.key1
	for i=1,key1 do
		spr(208,-3+10*i,15,14,1,0,0,1,1)
	end
end

uiManager={uiStatusBar}

curLevel=1
function loadLevel(levelId)
	sync()
	curLevel=levelId
	local lOff = {{0,0},{0,17*2+2},{0,17*4},{30*6,17*2}, {0,17*5},{30*3-15,0},{30*3,17*2}}
	local MapSize = {{30*2+15,17*2+2},{30*3,17*2-2},{30*3,17},{30*1,17*3}, {30*3,17*3},{30*5+15,17*2},{30*3,17*2+4}}
	local playerPos = {{120,80},{30+0,120},{56,80},{112,120}, {64,120},{5*8,23*8},{6*8,-3*8}}
	--local playerPos = {{20,80},{30+0,120}}
	iMapManager.offx = lOff[levelId][1]
	iMapManager.offy = lOff[levelId][2]
	-- todo initMap
	for i=1,#mobManager do mobManager[i]=nil end
	for i=1,#envManager do envManager[i]=nil end
	player.x=playerPos[levelId][1]
	player.y=playerPos[levelId][2]
	player:update() --reset camera
	table.insert(mobManager,player)
	if(curLevel==1)then dialog(1) end
	for i=1,MapSize[levelId][1] do
		for j=1,MapSize[levelId][2] do
			local tx,ty=i+iMapManager.offx,j+iMapManager.offy
			local mtId=mget(tx,ty)
			if(mtId==240)then 
				table.insert(mobManager,slime(i*8,j*8))
			elseif(mtId==241)then 
				table.insert(mobManager,ranger(i*8,j*8))
			elseif(mtId==242)then 
				table.insert(mobManager,staticRanger(i*8,j*8,{-1,0}))
			elseif(mtId==243)then 
				table.insert(mobManager,staticRanger(i*8,j*8,{1,0}))
			elseif(mtId==244)then 
				table.insert(mobManager,staticRanger(i*8,j*8,{0,-1}))
			elseif(mtId==245)then 
				table.insert(mobManager,staticRanger(i*8,j*8,{0,1}))
			elseif(mtId==225)then 
				table.insert(mobManager,bombMan(i*8,j*8))
			elseif(mtId==226)then 
				table.insert(mobManager,bomb(i*8,j*8))
			elseif(mtId==227)then 
				table.insert(mobManager,laserElite(i*8,j*8))
			elseif(mtId==228)then 
				table.insert(mobManager,chargeElite(i*8,j*8))
			elseif(mtId==224)then
				table.insert(envManager,apple(i*8,j*8))
			elseif(mtId==208)then
				table.insert(envManager,keyItem(i*8,j*8,tx,ty))
			elseif(mtId==209)then
				table.insert(mobManager,fence(i*8,j*8))
			elseif(mtId==144)then
				table.insert(mobManager,weakRock(i*8,j*8))
			elseif(mtId==131)then
				table.insert(mobManager,fireTentacle(i*8,j*8))
			elseif(mtId==132)then
				table.insert(mobManager,iceTentacle(i*8,j*8))
			elseif(mtId==197)then
				table.insert(envManager,portal(i*8,j*8,LoadMapCode(tx,ty)))
			elseif(mtId==229)then
				Trinity:init(i*8,j*8)
			end
		end
	end
end

function gameOver()
	player.hp=50
	player.dead=false
	loadLevel(curLevel)
	-- if(curLevel<=3)then
	-- 	loadLevel(curLevel)
	-- elseif(curLevel>=4)then
	-- 	loadLevel(5)
	-- end
end

atfManager={theGravition,theTimeMachine,theKelvinWand}
function atfManager:shiftAtf(index)
	self[index]:shift()
end
function atfManager:useAtf(index)
	self[index]:use()
end
mobManager={}
envManager={}
aEnvManager={} --after
-- endregion


t=0
camera={x=0,y=0}
cameraOffset={0,0}

mainManager = {mobManager,atfManager,envManager,aEnvManager}
drawManager = {{iMapManager},envManager,{player},mobManager,aEnvManager,atfManager,uiManager,{Trinity}}

loadLevel(curLevel)

function TIC()
	if(#uiManager<2)then
		-- update
		for i=1,#mainManager do
			for j=1,#mainManager[i] do
				local obj=mainManager[i][j]
				if(obj)then obj:update() end
			end
		end
	end

  -- draw
  cls(0)
  for i=1,#drawManager do
		for j=1,#drawManager[i] do
			local obj=drawManager[i][j]
			if(obj)then	drawManager[i][j]:draw() end
		end
	end
	
	t=t+1
	--trace("test"..a)
end

-- <TILES>
-- 000:1111111111111111111111111111111111111111111111111111111111111111
-- 002:bffefefbeb88b9bdfbbb9b9df8b99b8df89b9bbdf9b9bbbbbbb88bbbfbdddbdd
-- 003:44555abb455544ab5554444a554444555444455544445555aaaaaaaabbbbbbbb
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
-- 016:4445554444555444455544445554444555444455544445554444555444455544
-- 017:fffefefff988899df888999df889998df899988df999889df998899dfddddddd
-- 018:fffefefbe98889bdfbb89b9df889998df89b988df999bd9df9988b9dfddddbdd
-- 019:bbbbbbbbaaaaaaaa55554444555444455544445554444555a4445554ba455544
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
-- 032:bbbbbbbbbbaaaaaabaa55444ba554444ba544445ba444455ba444555ba445554
-- 033:bbbbbbbbaaaaaaaa455544445554444555444455544445554444555444455544
-- 034:bbbbbbbbaaaaaabb55544aab554444ab544445ab444455ab444555ab445554ab
-- 035:ba555544ba555444ba554444ba544445ba444455ba444555ba445554ba555544
-- 036:445555ab455544ab555444ab554444ab544444ab444444ab444455ab444555ab
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
-- 048:ba455544ba555444ba554444ba544445ba444455baa44555bbaaaaaabbbbbbbb
-- 049:445554444555444455544445554444555444455544445554aaaaaaaabbbbbbbb
-- 050:455544ab555444ab554444ab544445ab444455ab44455aabaaaaaabbbbbbbbbb
-- 051:bbbbbbbbaaaaaaaa55444445544444554444455544445554aaaaaaaabbbbbbbb
-- 052:bbbbb444aaaaa44455444445544444554444455544445554aaaaaaaabbbbbbbb
-- 053:555bbbbb5554444455444445544444554444455544445555aaaaaaaabbbbbbbb
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
-- 064:4445554444555444455544445554444555444455544445554444555a444555ab
-- 065:444555444455544445554444555444455544445554444555a4445554ba455544
-- 066:dba55544ba555444a55544445554444555444455544445554444555444455544
-- 067:44455abd445554ab4555444a5554444555444455544445554444555444455544
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
-- 114:ddddddddbbbbbbbbbbbbbaaabbbbabbbbbbabbbbbbabbbbbaaaaaaaaa1111111
-- 115:ddddddddbbbbbbbbaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaa11111111
-- 116:ddddddddbbbbbbbbaaabbbbbbbbabbbbbbbbabbbbbbbbabbaaaaaaaa1111111a
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
-- 134:ddddddddbbbbbbbbbbbbbaaabbbbabbbbbbabbbbbbabbbbbaaaaaaaaa1111111
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
-- 148:daeeeeadaadbbbaaed5555baeb5555baeb5555baeb5555a7aabbba77ea77777d
-- 149:dddddddabbbbbba1bbbbba11bbbba111bbba1111bba11111aa11111111111111
-- 150:addddddd1abbbbbb11abbbbb111abbbb1111abbb11111abb111111aa11111111
-- 151:ddfed000edfed000ddffd000edeeffffdddeeeeeebdddddddbbbbbbbebbbbbbb
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
-- 198:bfffffeebddddfeebddddfeebddddeddbddddebbbddddebbbddddebbbddddebb
-- 199:eeeeeeeeeeeeeeefeeeeeeefdddeeeefbbdeeeefbbdeeeefbbdddddfbbdbbbdf
-- 200:1135353117474741741111114711111174111111471111111474747111474741
-- 201:11111111eeeeeeeebbeeddddbbbbeeddbbbbbbeebbbbbbbbbbbbbbbbaaaaaaaa
-- 202:3347477733747477334747773374747733474777337474773347477733747477
-- 203:7777777777777777777777777777777777777777777777775555555577777777
-- 204:7777777755555555777777777777777777777777777777777777777777777777
-- 205:7777775777777757777777577777775777777757777777577777775777777757
-- 206:e0e0adadebdb0aaaedbdd000ebdbd000edbda005ebda0000ed000000ebbbbbbb
-- 207:bada0b0baaa0dbdb000dbdbb000bdbdb500abdbb0000abdb000000bbbbbbbbbb
-- 208:effffffef555555ff5ffff5ff555555feff5fffeeef555feeef5ffeeeeef55fe
-- 209:22222222e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e222222222
-- 210:0000000000000000000000000040004004540454453545355300530000000000
-- 211:0000000000000000000000000400040045404540535453543005303500000000
-- 212:00000000000000000000f0f0f0f08f808f8f989f989899989999999900000000
-- 213:ffffffff0000000f0f0f0f0f0000000ff00fffff0ff000000f00000000000000
-- 214:bbbbbebbaaaaaabbaaaaaabbaaaaaabbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 215:bbdbbbdfbbdbbbdfbbdbbbdfbbdbbbdfaaabbbdfaaabbbdfaaaaaaafaaaaaaaf
-- 216:0000000022222222222222222222222200000000022220200000000000000000
-- 217:11111111eeeeeeeeddddddddddddddddeeeeeeeebbbbbbbbbbbbbbbbaaaaaaaa
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
-- 230:aaaaaaaaabbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadbaaaaaadd
-- 231:aaaaaaaabbbbbbbaaaaaaabaaaeeeebaaaedddbaaaedddbadaedddbabaedddba
-- 232:dddddddddbababaadabababadbababaadabababadbababaadabababaaaaaaaaa
-- 233:11111111eeeeeeeeddddeebbddeebbbbeebbbbbbbbbbbbbbbbbbbbbbaaaaaaaa
-- 234:4747474774747474474747477474747447474747747474744747474774747474
-- 235:ededededfffffffeefefefedfefefefeefefefedfefefefe4fefefed44fefefe
-- 236:ededededfffffffeefefefedfefefefeefefefedfefefefeefefefe4fefefe44
-- 238:ddddddddfffffffdf333333df333333df333333df333333df333333df333333d
-- 239:bdbdbdbdfbfbfbfbefefefedfefefefeefefefedfefefefeefefefedfefefefe
-- 240:eeeeeeeeeeffffeeef4444fef0444111f404414ff4444111f4444441f4f4f111
-- 241:00fffff00f555c3f0f575c3ff5575111f5c551cff3cf51110f3c53f100fff111
-- 242:00fffff00f555c3f0f575c3ff55756cff5c566cff3c666660f3c66f000fff600
-- 243:00fffff00f555c3f0f575c3ff55756cff5c5566ff3c666660f3c566000fff600
-- 244:00fffff00f555c3f0f575c3ff55756cff5c5666ff3c666660f3c56f000fff600
-- 245:00fffff00f555c3f0f575c3ff55756cff5c556cff3c666660f3c666000fff600
-- 246:aababadbaabbaaddaababadbaabbaaddaababadbaabbaaddaababadbaaaaaaaa
-- 247:daedddbabaedddbadaedddbabaedddbadaedddbabaedddbadaebbbbaaaaaaaaa
-- 248:eeeeeeeeedbdbdbbebdbdbdbedbdbdbbebdbdbdbedbdbdbbebdbdbdbbbbbbbbb
-- 249:11111111111111111111111111ffffff1effffeeeefffdddeefffbbbeefffbbb
-- 250:111111111111111111111111ffffee11efffeed1ddfffeddbbfffeddbbfffedd
-- 251:0000000000000000000e000000efe000000e000000000000000000f000000000
-- 252:000000d000000ded000000d0000d0000000e00000defed00000e0000000d0000
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
-- 012:00000000000000ff0000ffcc000fcccc00fccccc00fccc5c0fccc55c00f5c575
-- 013:00000000ff000000ccff0000cc1cf000ccc1cf00c5c1cf00551cccf0575c5f00
-- 015:00000000000000000000000000000000000000000000000000000000fff00000
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
-- 028:00f55555000fbe5c00feff5500fe7fd100f7ffdd0feff71bfe777b1b0fffb1bf
-- 029:55555f00555bf00015ffef00ddf1ef00d11f7ef0bbb7ee70fbbb77f00fbbbf00
-- 030:0000cfff0000fccc000fcccc000fcccc00fccccc00fccccc00fccccc00cffccc
-- 031:cccfc000ccccf000ccccf000cc1ccf00c111cf00ccc1cc00cccc1fc0ccccf110
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
-- 093:00000000000000000000000000000000000000000000000000000000fff00000
-- 094:000000000000000000000000000000000000000000000000000000000000f0f0
-- 095:000000000000000000000000000000000000000000000000ff000000fff00000
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
-- 108:00004fff0000f44400ff4cff0f4f4444f44ccc440f4c44ff00fcc44f00cf444c
-- 109:44cf400044ccf000444cf4004c14cf00f1114f00f441cc40fff41fc0fffcf110
-- 110:000fcfff000ffcff00044ffc0044f4fc0ffffc4c0ffcccc40ffcccc400cffccc
-- 111:cccfc000cffff000ccfc4400cc1c4440c414cf004444cc00444c1fc0444cf110
-- 112:00000000000ff00000fddf000fdfbbf00fdbbaf000fbaf00000ff00000000000
-- 113:000000f00000ffef000feedf00feedf000fedf000fdff0000df0000000000000
-- 114:0000000000f6f0000f644f00f54434f0fc5544f0fcc44cf00fccff0000ff0000
-- 115:00000000000ff00000f88f000f8f99f00f8997f000f97f00000ff00000000000
-- 116:000ff0000fffff0fff44c4f0c04fffff44f444fffff4ff4f4ff4c11ff444f4f0
-- 117:0000000000ffff0f0f44c4f0c04ffc0ffc0ccc4ff4cf4c4fffc4c4fff4f4f4f0
-- 118:0000000000f00000004000f0000ff000f00ccc0004cf4c4fffc4c4fff4f4f4f0
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
-- 160:1111ffff111ffb3f11ffb33311fb333311fbcc3c11fe3c3311fe333311fe3eee
-- 161:ffff1111f3bff1113fbbff11333bbf11cc3bbf11cc3b3f1133333f11333eff11
-- 162:1111ffff111ffb3f11ffb33311fb333311fbcc3c11fe3c3311fe333311fe3eee
-- 163:ffff1111f3bff1113fbbff11333bbf11cc3bbf11cc3b3f1133333f11333eff11
-- 164:1111ffff111ffb3f11ffb33311fb333311fbc33c11fe3c3311fe333311fe3eee
-- 165:ffff1111f3bff1113fbbff11333bbf11333bbf11cc3b3f1133333f11333eff11
-- 166:eeeeeeeeeeeeeeeeee5eeeeeeeeee555eeee555feee555f7eee555f7ee5555f7
-- 167:eeeeeeeee5eeeeee5eee5eee5555eeeeff555eee77f55eee77f55eee77f555ee
-- 168:eeeeeeeeeeeeeeeeeee3eeeeeeeeeeeeeeeee555eeee555feee555f7eee555f7
-- 169:eeeeeeeeeeeeeeeee5eeeeee5eeee3ee5555eeeeff555eee77f55eee77f55eee
-- 170:eeeeeeeeeeeeeeeeee4eeeeeeeeee555eeee555feee555f4eee555f4ee5555f4
-- 171:eeeeeeeee4eeeeee5eee4eee5555eeeeff555eee44f55eee44f55eee44f555ee
-- 172:eeeeeeeeeeeeeeeeeeeeeee9eeeeee99eee9e999eeeee998eeeee998eee9e998
-- 173:eeeeeeeeeeeeeeee9ee9eeee999eeeee899e9eee899e9eee8899e9ee8899e9ee
-- 176:11f3ecce111fe33e11fffeee1f00ffeef33000dd1f33000011ff000011f00000
-- 177:e3edf111eeedff11edff0f11dff000f1000033f100033f110000f11100000f11
-- 178:11f3ecce111fe33e1111feee1fff00eeff0000ddf33000001f33000011f00000
-- 179:e3edf111eeedf111edff1111d00fff11000000f1000033f100033f1100000f11
-- 180:11f3eccef11fe33e3ffffeeef300ffee330000ddfff00000111f0000111f0000
-- 181:e3edf111eeedff11edffff11dff00ff1000000f100000f1100003f11000000f1
-- 182:ee55555feee55555eee5e555ee55e555ee5e55c5eeee55e5eeeee5eeeeeeeeee
-- 183:ff555cee5555ccee555555eec5c55eee5ee55eee5e55eeeee5eeeeeeeeeeeeee
-- 184:ee5555f7ee55555feee55555ee55e555ee3e55c5eeee55e5eeeee5eeeeeeeeee
-- 185:77f555eeff555cee5555cceec5c55eee5ee55eee5e55eeeee3eeeeeeeeeeeeee
-- 186:ee55555feee55555eee5e555ee55e555ee4e55c5eeee55e5eeeee5eeeeeeeeee
-- 187:ff555cee5555ccee555555eec5c55eee5ee55eee5e55eeeee4eeeeeeeeeeeeee
-- 188:eee9e998eee99998eeee9998eeeee999eee9e999eee99e99eeeeeee9eeeee9ee
-- 189:8899ee9e8899e9ee8899eeee8899e9ee899eeeee999e9eee9ee9eeeeeeeeeeee
-- 192:eeeeeffeeeeef55feeef5555eeef5533eef55533eef553c3ef55c333ef5cc333
-- 193:effeeeeef55feeee5555feee35555fee33555feec33555fe335c55fe333cc5fe
-- 194:eeeeeffeeeeef55feeef5555eeef5533eef55533eef553c3ef55c333ef5cc333
-- 195:effeeeeef55feeee5555feee35555fee33555feec33555fe335c55fe333cc5fe
-- 196:eeeeeffeeeeef55feeef5555eeef5533eef55533eef553c3ef55c3c3ef5cc333
-- 197:effeeeeef55feeee5555feee35555fee33555feec3355feec35555fe3335cfee
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
-- 208:ef55c3cceef55533ef55c7ffef3f777ff3377c77efffcccceeeefccceeeeef00
-- 209:333c555f335755cff7777cfe77777fee77c777fecccc73fefffccfeefeef00fe
-- 210:ef55c3cceef55533eeff557fef3f7777f3377c77efffcccceefccfffef00feef
-- 211:333c555f335755cfff77c55ff7777ccf77c77ffecccc3feecccffeee00feeeee
-- 212:ef5553cceef5c333ef5cc7ffef3f777ff3377c77efffcccceeeefccceeeee00f
-- 213:335555fe35575c5ff775ccfe777c7fee77c77ffecccc3ffefccfffeef00feeee
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
-- 224:eeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff444444ff4f4f4fe
-- 225:eeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff444444fef4f4f4f
-- 226:eeeeeeeeeeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff4f4ff4f
-- 227:eeeeeeeeeeea0eeeee3333eee3ff335ee373375ee373575ee335355eee5555ee
-- 228:eeeeeeeeeeeeeeeeeeea0eeeee3333eee3ff335ee373375ee335355eee5555ee
-- 229:eeeeeeeeeeeeeeeeeeea0eeeee4444eee4ff44cee47447cee444c4ceeeccccee
-- 230:11111fff1111f33e111f3333111f3c3c111f3333111fd333111fdeee11feedce
-- 231:fff11111e3ef11113e3ef111c3eef111333eaf113ee3af11ee33af11eeeaf111
-- 232:11111fff1111f33e111f3333111f3c3c111f3333111fd333111fdeee11feedce
-- 233:fff11111e3ef11113e3ef111c3eef111333eaf113ee3af11ee33af11eeeaf111
-- 234:11111fff1111f33e111f3333111f3c3c111f3c33111fd333111fdeee11feedce
-- 235:fff11111e3ef11113e3ef111c3eef111c33eaf113ee3af11ee33af11eeeafff1
-- 236:000000000004444000400044000004000000444f00044cf0044c44f0040c44f0
-- 237:00000000444000004040000044444400ff40040000f0004000f4044000f44000
-- 238:0004440000440044040004440400cc4c004044ff0444cf0044cc4f004c004f00
-- 239:000000004004000044444400444cc440f4c4c4400fc4c4000f4444000f444400
-- 240:00fffff00f555c3f0f575c3ff55755cff5c55ccff3cf5c3f0f3c53f000ffff00
-- 241:0000000000fffff00f555c3f0f57553ff5555cf0f5c55ccff33c533f0fff0ff0
-- 242:00fffff00f555c4f0f545c4ff55455cff5c55ccff4cf5c4f0f4c54f000ffff00
-- 246:11fbeeee11f7eeee1f777eb71f77777711f37777111f77771111f777111f000f
-- 247:eeeb7f11ebb777f1bb7777f177777f1177773f117777f111f777f1110000f111
-- 248:11fbeeee11ffdeee1ff77de71f77777711777777111377771111f777111f000f
-- 249:eeebff11eeb77ff1eb7777f17777771177777f1177773111f777f1110000f111
-- 250:11fbeeee1f3bbeee1f777bb711f77777111f7777111f77771111f777111f000f
-- 251:eeeb73f1ebb777f1bb777ff17777ff117777f1117777f111f777f1110000f111
-- 252:0444444f0044c4440004cc440000444400400440004400000004000000044000
-- 253:ffc44440444cc444444c0004cc4c04400c040400000040000000400000000000
-- 254:44c044ff044c044400040c4c000400c400440000440000000000000000000000
-- 255:fc4c4440444c4404c44444004c00040400404044044000000000000000000000
-- </SPRITES>

-- <MAP>
-- 000:00000040c2c2c2c2410000000000000000000000d5b9e5e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056000056000000000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2410000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c241000000000000000000000040c2c2c2c2c24100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:000081a1f4f4f4f4a1910000000000000000000000560000000000000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c274c2c274c2c2c2c2c2c2c2c2410000a1e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a100000000000000a1d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d3d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a10000000000000000000000a1f4f4f4f4f4a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:0000a1f4f4f4f4f4f4a10000000040c2c2c2c2c2c274c2c2c2c2c2c2c2c2c2c2c2c2c2c2c241000000000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f471a10000a1e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a100000000000000a1d3b0000000c0e3e3e3e3e3e3e3a5a5f3e3e3d3d3e3e3e3e3e3e3e3e3e3e3e3e3b00000c0e3e3e3d3a1c2c2c2c2c2c2c2c2c2c2c2a1d3e3e3e3d3a1c2c2c2c241000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c241000000000000000000000000000000000000
-- 003:0000a1d390000080d3a100000000a1f4f4f4f4f4f4f48383838383838383838383838383f4a1000000000000000000a1e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3f3e3e3e3e3e3e3e3f3f3e3e3e3e3e3e3e3e3a10000a1e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a100000000000000a1d30000000000e3c1c1e3e3e3e3a5a5f3c1e2d3d3e3e3e3e3e3e3e3e3e3e3e3e300000000e3e3e3d3d3f4f4f4f4f4f4f4f4f4f4f4f4d3e3e3e3d3f4f4f4f4a1a10000000000a1a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a1000000000000000000000000000000000000
-- 004:0000a1d3c5d4d4c6d3a100000000a1e3e3e3e3e3d3d3e3e3e3e3e3e3e3e3e3e3e3e3e3a5e3a1c2c2c2c2c2c2410000a1e3e3e3b00000000000000000c0e3e3e3e3e3f3e3e3e3e3e3e3e3f3f3e3e3e3b00000c0e3a10000a1e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a100000000000000a1d3b4d4d4d4c4e3e3e3e3e3e3e3a5a5f3e3e3d3d3e3e3e3e3e3e3e3e3e3e3e3e3b4d4d4c4e3e3e3d3d3e3b00000c0e3e3e3e3e3e3d3d3e3e3e3d3d3e3e3e3a1a1e4e4e4e4e4a1a1e3e3e3e3b00000000000c0e3e3b00000c0e3f3a5e3e3e3e3e3e3e3e3e3e3e3e3e3a1c2c2c2c2c2c2c2c2c2410000000000000000
-- 005:0000a1d373737273d3a100000055a1e3b000c0e3d3d3e3b00000000000000000c0e3e3a5e3f4f4f4f4f4f471a10000a1e3e3e300000000000000000000e3c1d1e3e3f3e3e3e3e3e3e3e3f3f3e32ae300000000e3a10000a10effffffff0e48ffffffffffffff630808080863d300000000000000d3ff0e0effffffff8902121222ffffffffffffff890d0e09ffffffffffffff4affffffffffffffffffd3e300000000e3e3e3e3e3e3d30effffff0ed3e3e3e3d3d30eff0eff0ed3d3e3e3e3e300000000000000e3e300000000e3f3a5e3c1c1d0c1d0e3e3e3e3e3e3e3d3f4f4f4f4f4f4f4f4f4a10000000000000000
-- 006:0000a1ffffffffffffa100000056a1e3b4d4c4e3d3d3e300000000000000000000c1d0a5a2e3f3e3e3e3e3e3a10000a1e3e3e3b4d4d4d4d4d4d4d4d4c4e3e3e3e3e3f3e3e3e3e3e3e3e3f3f3e3e3e3b4d4d4c4e3a10000a1ffffffffffff4affffffffffffffff1fffffffffd300000000000000d3ff0e0effffffff8903131323ffffffffffffff890e0e09ffffffffffffff4affffffffffffffffff49e3b4d4d4c4e3e3e3e3e3e3d309ffffff09d3e3e3e3d3d3ff0eff0effd3d3e3e3e3e3b4d4d4d4d4d4c4e3e3b4d4d4c4e3f3a5e3e3e3e3e3e3e3e3e3e3e3e3e3d3e3e3e3e3e3e3e3e3e3a10000000000000000
-- 007:0000c3ffffffffffffc300000056a17362737373d349e3b4d4d4d4d4d4d4d4d4c4e3e3a5a2e3f3b00000c0e3a10055a1fefefefefefe6308080808080808080808080808080808080808080863fefefefefefefea10000d3ff0fffff1fff4affffffffffffffffffffffffffd300000000000000d3ffffffff3effff89ffffff1fffffffff1fffff890e0e89ffff1fffffffff4affffffffffff1effff5affffffffff09ffffffffffffffffffffffffffff63d3d3ffffffffffd3d3ffffffffffffffffffffffffffffffffffffffffffffffffffffff11ffff010101d3e3e3e3e3e3e3e3e3e3a10000000000000000
-- 008:0000c3ff06ffff06ffc300000056a1fefefefefffe5afefe890dfefe0909fefefefefefed3e3f300000000e3a10067a1ffffffffffffffffff4effffffffffffffffffffffffffffffffffffffffff495b5b5b49a10000d3ffffffffffff4affffffffffffffff1effff1fff49e4e4e43ae4e4e4d3ffffffffffffff891d1d1d1d1d1d1d1d1d1d1d8989891d1d1d1d1d1d1d1d481d1d1d1dffffffffff5affffffffff09ffffffffffffffffffffffffffff17d3d3386a6a6a38d3d3ffffffffffffffffff4effffffffffffbaffffffffffff3effffff11ffff010101d3e3e3e3e3e3e3e3e3e3a10000000000000000
-- 009:0000c3ffffffffffffc300000067a1ffffffffffff5affff8989ffff0909ffffffffffffd3e3f3b4d4d4c4e3a10067a1ff0effff0effffffffffffffffffffffffffffffffffffffffffffffffffff5affffffffa10000d3ff0fffff0fff4affffffffffffffffffffffffff5affffff2bffffffffffffffffffffff89021222ffffffffffffffffffffffffffffffff021222890e0fffffffffffffff5affffffffff09ffffffffffffffffffffffffffff17ffffffffffffff09ffffffffffffffffffffffffffffffffffbaffffffffffffffffffff11ffffffffffff4909ff09ff0effffffa10000000000000000
-- 010:000084e4e4e4e4e4e49400000056a1ffffffffffff5affffffffffff0909ffffffffffff1dfefefefefefefea10056a1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5aff6e7effa10000d3ffffffffffff4affffffffffffffffff1effffff5affffff2bffffffffffffffffffffff89031323ffffffffffffffff0fffffffffffffff031323890fff1fffffffffffff5affffffffff09ffffffffbabaffffffffffff1eff17ffff3effffff09ffffffffffffffffffbaffffffffffffffffbaffffffffffffffffffffffffffffffffff5a09ff09ffff6e7effc30000000000000000
-- 011:000000d5b9b9e5e5f50000000077a1ffffffffffff49ffffffffffff0909ffffffffffff1dffffffff0effffa10067a1ffffff0dffffff4effffffffffffffffffffffffffffffffffffffffffffff5aff6f7fffc30066f609090909090948ffffffffffffffffffffffffff5affffff2bffffffffffffffffffffff89ffffffffffffffffffffffff0fffffffffffffffffff890e0fffffffffffffff5affffffffff09ffffffffbabaffffffffffffffff6349ffffffffff0909ffffffffffffffffbaffffffeeeeffffffbaffffffffffffffffffffffffffffffffff5a090e09ffff6f7fffc30000000000000000
-- 012:0000000067560000000000000077c3ffffffffffffffffffffffffff0909ffffffffffff1dffffffffffffffa10056c3ff0effff0effffffffffffffffffffffffffffffffffffffffffffffffffff5affffffffc30085386a6a6a6a6a6a381d1d1d1d1d1d1d0909090909095affffff2bffffffffffffffffff1eff89ffffffffffffffffffffff0fffffffffffffffffffff8948898989090909090986e4e4e4e4e496ffffffffffffffffffffffffffffff5affffffffff090909ffffffffffffffbaffffeeeeeeffffffffffffffeeeeffbaffffffffffffffffffff4909ff09ff0effffffc30000000000000000
-- 013:0000009f4545a4af000000000057c36e7effffff86e4e4e4e4e4e4e4e4e4e498ffffffffa2ffffffffffffffa10057c3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff495b5b5b49c30085ffffffffffffffff1d031313131323ffffffffffff3ae4e4e43affffff89ffffff1effffff89ffffffffffffffbababaffffffffffffffffffffffffff4affffffffffffffff95e5e5e5e5e585ffffffffffffffffffffffffffffff5affffffffff09ff09ffffffffffffffbaffffeeeeeeffffffffffffeeeeeeffbaffffff111111ffffff86e4e4e4e4e4e4e4e4e4f60000000000000000
-- 014:0000008563636395000000000000c36f7fffffff95009fa4a4a4a4a4a4a4a488ffffffffa2898989ffffffffa10000c3ffffffffffff630808080808080808080863a1ffffffa1630808080863ffffffffffffffc30085ffffffff0fffffff1dffffffffffffffffffffffff95e5e5e585ffffff89ffffffffffffff89090909ffffffffffffffffffffffffbababaffffffffff4affff0fffffffffff95000000000085ffffffffffffffffffffffffffffff5affffffffffffff09ffffffffffffffffffffffffffffff1dff1dffeeeeffffffffffffffffffffffff95e5e5e5e5e5e5e5e5e5f50000000000000000
-- 015:000000e6e4e4e4f6000000000000c3e4e4e4e4e4f60085021222fefefefefefeff4effffa2fefefeffffffffc30000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4a1ffffffa1e4e4e4e4e4e4e4e4e4e4e4e4e4c30085ffffffffffffffff1dffffffffffffff0fff0fffffe6e47600e6e4e4e4c3ffffffffffffff09ffff09ffffffffffffffffffeeffffffffffffffffffff4affffffffff1e1fff95000000000085ffffffffffffffffffffffffffffff5affffffffff09ff09ffffffffffffffffffffffffffff1dff1dff1dffffffffffffffffffffffffffff95000000000000000000000000000000000000
-- 016:000000d5e5e5e5f5000000000000d5e5e5b9e5e5f50085320142ffffffffffffffffffffc3ff0effffffffffc30000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5a1ffffffa1e5e5b9b9e5e5e5e5e5e5e5b9e5f50085ffffff0fffffffff1dffffff3effffffffffffffff090e9500d5e5e5e5c3ffff1effffffff09ffff09ffffffffffffffffffeeffffffffffffff4effff4affff0fffffffffff95000000000085ffffffffffffffffffffffffffffff49ffffffffff090909eeeeeeeeeeeeeeeeeeeeeeeeeeffff1d1f1dffffeeeeeeeeeeeeeeeeeeeeeeeeeee6e4e4e4e4e4e4e4e4e4760000000000000000
-- 017:0000000000000000000000000000000000c9d9d9d96785031323ffffffffffffffffffffc3ffffffffffffffc3000000000000000000000000000000000000000000a1ffffffa1000056c9d9d9d9d9d967d9a900000085ffffffffffffffff1dffffffffffffffffffffffff090d950000000000c3ffffffffffffff09ff0e09ffffffffffffffffffeeffffffffffffffffffff4affffffffffffffff95000000000085ffffffffffffffffffff86e4e4e4e4e4e4e4e4e4e4e4e496ffffffffffffffffffffffffffff1dff1dff1dffffffffffffffffffffffffffffffff09ff090212121222950000000000000000
-- 018:00000000000000000000000000000000000000000000e6e4e4e4e496ffffffff86e4e4e4c3e4e4e4e4e4e4e4c30000000000000000000000000000000000000040c2a1ffffffa1c2415600000000000000000000000085ffffff86e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f60000000000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6000000000085ffffffffffffffffffff95e5e5e5e5e5e5e5e5e5e5e5e585ffffffffffffffffffffffffffffff1dff1dffffffffffffffffffffffffffffffffff090e0932ff0aff42950000000000000000
-- 019:00000000000000000000000000000000000000000000d5e5e5e5b985ffffffff95e5b9e5e5e5e5e5e5e5e5e5f500000000000000000000000000000000000000a1f4f4fffffff4f4a17700000000000000000000000085ffffff95e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f50000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000085ffffffffffffffffffff9500000000000066e4e4e4e4e4a6ffffffff4effffffffffeeeeeeeeffffffffffeeeeeeffffffffffffffffffffffffff090e0932ffffff42950000000000000000
-- 020:00000000000000000000000000000000000000000000000000007785ffffffff95007700000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2a1d3495b5b5b49d3a17700000000000000000000000085ffffff9500000000000000000000000000000000000000000000000000000000000000000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4760000000000000000000085ffffffffffffffffffff95000000000000850dffffffff2bffffffffffffffffffffffeeeeffffffffffffeeeeffffffff111111ffffffffffffff09ff090333333323950000000000000000
-- 021:000040c2c2c2c2c2c2c2c2c2410000000081a1a1a1a1a1a1a1a1a1a1ffffffffa1a1a1a1a1a1a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a2f4f4f4f4f4d3d3ffffffd3d3a15600000000000000000000000085050505950000000000000000000000000000000000000000000000000000000000000000008563ff3effffffffffffff6308080808080808080808080863ffffff9500000000000000000000850909090909090909090995000000000000850effffffff2bffffffbababaffffffffffffffffffffbaffffffffffffffff11ffffffffff056386e4e4e4e4e4e4e4e4e4f60000000000000000
-- 022:0040a1f4f4f4f4f4f4f4f4f4a100000000a1f4f4f4f4f4f4f4f4f4d3ffffffffd3f4f4f4f4f4d3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a2e3e3e3f3d3d3d3ffffffd3d3a1560000000066e4e4e4e4e4e4e4f6050505950000000000000000000000000000000000000000000000000000000000000000008517ffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeffffffffff950000000000000000000085ffffffffffffffffffff95000000000000e6e4e4e4e4e4a66325ffffffffffffffff111111ffffffbaffffffffffffffff11ffffffff05051795e5e5e5e5e5e5e5e5e5f50000000000000000
-- 023:40a1d3d3e3e3e3e3e3a5e3e3a1c2c2c2c2a1e3f3e3b0000000c0e3d3ffffffffd3e3e3e3e3e3d3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a2e3e3e3f3d3fefefffffffefea1560000000085ffffffff890effffffffff95000040c2c2c2c2c2c24100000000000000000000000000000000000000000000008517ffffffffffffffffffffffffffffffffffffffffffffffffffff950000000000000000000085ffffffff1effffffffff95000000000000d5e5e5e5e5e58517252525ffffff3effffffffffffffffbaffffffffffffffffffffff050505051795000000000000000000000000000000000000
-- 024:a1d3d3d3e3e3c1e0e3a5e3e3d3f4f4f4f4d3e3f3e30000000000e3d3ffffffffd3e3e3e3c1f0d3b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8a2b8b8b8a8d3ffffffffffffffa1770000000085ffffffff89ffffffffffff950000a1e3e3e3e3e3e3a100000000000000000000000000000000000000000000008517ffffffffffeeeeeeffffffffffffffffffffbabaffffff021222950000000000000000000085ffffffffffffffffffff9500000000000000000000000085172525252525ffffffffffffffffffffffffffffffffffffffffff05050505051795000000000000000000000000000000000000
-- 025:a1d3d3d3b8b8b8b8b8a5b8b8d3e3e3e3e3d3e3f3e3b4d4d4d4c4e3d3ffffffffd3b849b8b8b8d3fffefefefefefefefefefefefefefefefefefefea21222fefefeffffffffffffffa1770000000085ffffffff89ff0fffffffff950000a1e3e3e3e3e3e3a100000000000000000000000000000000000000000000008517ffffff11ffeeeeeeffffffffffffffffffffbabaffffff32014295000000000000000000008589898989898989ffffff9500000000000000000000000085630808080863ffffffffffffffffffffffffffffffffffffffff6308080808086395000000000000000000000000000000000000
-- 026:a1d3fefefefefefefefefefed3e3e3e3e3d3fefefefefefefefefefefffffffffefe5afefefefeffffffffffffffffffffffffffffffffffff0fffa20142ff0fffffffffffffffffa1560000000085ffffffff89ffffffffffff950000a1e3e3e3e3e3e3a10000000000000000000000000000000066e4e4e4e4e4e4f617ffffff11ffffffffffffffffffffffffffffbabaffffff03132395000000000000000000008589898989898989ffffff95000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6000000000000000000000000000000000000
-- 027:a1fe021212121222ffffffffd3b8b8b8b8d3ffffffffffffffffffffffffffffffff5affffffffffffffff0fff6363ffffffffffffffffffffffffa20142ffffffffffffffffffffa1a90000000085ffffffffffffffffffffff950000a1e3e3e3e3e3e3a10000000000000000000000000000000085ffffffffff898917ffffff11ffffffffffbababababaffffffffbabaffffff48ffffe6e4e4e4e4e4e4e4e4e4e4f6ffffffffffffffffffff95000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000000000000000000000000000000
-- 028:a1ff32bd0effcd42ff0ffffffefe09fe09feffffffffffffffffffffffffffffffff5affffffffffffffffffff1717ffffffff0fffffffffffffffa20142ffffffffffffffffffffa10000000000856e7effffffffffffffffff950000a16e7effffffffa10000000000000000000000000000000085ffffff0eff898917eeeeff11ff4effffffbababababaffffffffffffffffff4affffffff09ffffffff09ffffffffff1effffffffffffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 029:a1ff32ffffff0d42ffffffffffffff0909ffffffff0fffffffffffffffffffffff70a2a2a2a260ffffffffffff1717ffffffff63080863ffffffffd30142ffffffa2ffffffffffffa10000000000856f7fffffffffffffffffff950000a16f7fffffffffa10000000000000000000000000000000085ff0d0effff893a63eeeeff11ffffffffffffbabaffffffffffffffffffffff4affffffff09ff0e0eff09ffffffffffffffffffff1effffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 030:a1ff32ffffffff42ffffffffffff090909ffffffffffffffffffffffffffffffffa2b2b2b2b2a2ffffffffffff6363ffffffff63080863ffffffffd30142ffffffa2ffffffffffffa10000000000e6e4e4e4e4e4e4e4e4e4e4e4f60000a1ffffffffffffa1d9d9d9d9d9d90000000000000000000085ffffffffffff2bffeeeeffffffffffffffffbabaffffffffffffffffffffff4affffffff09ff0e0eff09ffffff1effffff1effffffffff1e950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:c3ff32be0effce42ff0fffffffffff0909ffffffffffffffffffffff6308080863a2b1b1b1b1a2ffffffffffffffffffffffffffffffffffffffffd31323ffffffa2ffffffffffffa10000000000e5e5e5e5e5e5e5e5e5e5e5e5e50000a1ffffffffffffa1d964000000000000000000000000000085ffffffffffff2bffffffffffffffffffffffffffffffffffffffffffffffff4affffffff09ffffffff09ffffffffffffffffffffffffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:c3ff035333334323ffffff86e4e4e4e4e4e496ffffffffffffffffff1dffffffffc3b1b1b1b1c3ffffffffffffffffffffffffffffffffffffffffffffffffffffc3ffffffffffffc30000000000000000000000000000000000000000a1ffffffffffffa100560000000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:c3e496ffffffffffffffff95e5e5e5e5e5e585ffffffffffffffffff1dff1f0effc3b9e5e5e5c3021212121212121212121212121222ffffffffffffff0fffffffc3ffffffffffffc30000000000000000000000000000000000000000a1ffffffffffffa100560000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:d5e585ffffffffffffffff95d9d96767d9d985ffffffffffffffffff1dffffffffc356000000c3031313131313131313131313131323ffffffffffffffffffffffc3ffffff0dffffc30000000000000000000000000000000000000000a1ffffffffffffa100560000000000000000000000000000000000000000000000675600000000000000000000000000000000000000675600000000000000000000000000000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2410000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:0000e6e4e4e4e4e4e4e4e4e4000000000000e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6c3a9000000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4c3e4e4e4e4e4e4c30000000000000000000000000000000000000000a1ffffffffffffa1005600000000000000000000000000000000000000000000005667000000000000000000000000000000000000005667000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1f4f4f4f4f4f4a10000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:0000d5e5e5e5e5e5e5e5e5f5000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f500000000d5e5e5b9e5e5e5e5b9e5e5b9b9b9e5e5e5e5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5e5e50000000000000000000000000000000000000000a1484b4b4b4b48a1005600000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c27474c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c27474c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2410000000000000000000000000000a1900000000080a10000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:000000000000000000000000000000000000000000000000000000000000000000000000000000000056000000005600005656569fa4a4a4af000000560040c2c2c2c2c2c2410000000000000040c2c2c2c2c2c2410000000000000000a1ffffffffffffa10056000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a2f4f4f4f4f4f4f4f4f4f4f4f4f4a2f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a10000000000000000000000000055a1c5d4d4d4d4c6a16400000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:000000000000000000000000000000000000000000000000000000000000000000000000000000004074c2c2c24157d9d97799a9856363639500004074c2a1f4f4f4f4f4f4a1c2c2410040c2c2a1f4f4f4f4f4f4a1c2c2410000000000a1ffffffffffffa1d999d9d9d96767d9a1e3e3e3d3e3b00000000000c0e3f3e3e3e3e3e3e3a2e3f3e3e3e3e3e3e3e3e3e3e3d3a2d3e3e3e3e3e3f3e3e3e3e3e3e3e3e3e3a5e3e3b0000000000000c0e3e3e3d3a10000000000000000000000000056a1726273737373a15600000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:00000000000000000000000000000000000000000000000000000000000000000000000000000000a1f4f4f4f4a100000077c9d985636363950055a1f4f4f4d3e3e3e3e3d3f4f4f4a100a1f4f4f4d3e3e3e3e3d3f4f4f4a10000000000a1ffffffffffffa10056000000000000a1e3e3e3d3e300000000000000e3f3e3e3e3e3e3e3a2e3f3e3e3e3e3e3e3e3e3e3e3d3a2d3e3e3e3e3e3f3e3e3e3e3c1c1f1e3e3a5e3e30000000000000000e3e3e3d3a10000000000000000000000000056a1ffffffffffffa15600000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:0000000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2a1d3e3e3d3a1c2c241560000e6e4e4e4f60056a1e3e3d3d3e3e3e3e3d3d3e3e3a100a1e3e3d3d3e3e3e3e3d3d3e3e3a100000040c2a1ffff0f0fffffa1c274c2c2c2c24100a1e3e3e3d3e3b4d4d4d4d4d4c4e3f3e348e3e3e3e3a2e3f3e3e3e3e3e3e3e3e3e3e3d3a2d3e3e3e3e3e3f3e3e3e3e3e3e3e3e3e3a5e3e3b4d4d4d4d4d4d4c4e3e3e3d3a10000000000000000000000000077a1ffffffffffffa15600000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:0000000000000000000000000000000040c2c2c2c2c2c24100000000000000a1f4f4f4f4f4f4f4f4f4d3e3e3d3f4f4f4a1770000d5e5e5b9f50057a1e3e3d3fe0f0f0f0ffed3e3e3a100a1e3e3d3fe0f0f0f0ffed3e3e3a1000000a1f4f4ff0fffff0ffff4f4f4f4f4f4f4a100a1ffffffffffffffffffffffffffffff4affffffffa2ff2fffffffff050505ffffffffa20505ff0effffffff0505ffffffffffffff050505ffffffffffffff0e0505ffa10000000000000000000000000057a1ffff5c1bffffa199d9d9d9d9d9d9d9640000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000040c2c2c2c2c2c2c2c2c2a1f4f4f4f4f4f4a1c2c2c2c2c2c2c2a1d3e3c8e3c8e3e3e3d3d3b8b8d3d3e3e3a199d9d9d9d9d999640040a1ffffffffffffffffffffffffa1c2a1ffffffffffffffffffffffffa1000000a1e3d3ffffffffffffd3e3e3e3e3e3e3a100a1ffffffffffffffeeffffffffffffff4affffffffa2ffffffffffffffffffffffffffa205ffffffffffffffffffffffffffeeffffffffffffffffffffffffffff0505a100000040c2c2c2c2c2c2c2c2c2c2a1ffff1b0bffffa174c2c2c2c2c2c2c274c241000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000a1f4f4f4f4f4f4f4f4f4d3d3e3e3e3e3d3d3f4f4f4f4f4f4f4f4d3e3c8e3c8e3e3e3d30fffff0fd3e3e3a174c2c2c2c2c27474c2a1d3ffffffffffffffffffffffffd3a1d3ffffffffffffffffffffffffa1c20000a1e3d3386a6a6a6a38d3e3e3e3e3e3e3a100a1ffffffffffffffeeffffffffffffff4affffffffa2ffffffffffffffffffffffffffa2ffffffffffffffffffffff0fffffeeffffffffffffffffffffffffffffff05a1000000a1f4f4f4f4f4f4f4f4f4f4f4ffffdddcfffff4f4f4f4f4f4f4f4f4f4f4a1000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000a1d3f3e3e3e3e3e3e3e3d3d3e3e3e3e3d3d3c8b0000000c0e3d3d3e3c82ac849b8b8d3ff0f0fffd3b8b8d3f4f4f4f4f4f4f4f4f4d3d3ffffff021212121222ffffffd3d3d3ffffff021212121222ffffffd3a14100a1e3d3ffffffffffffd3e3e3e3e3e3e3a100a1ffffffffffffffffffffffffffffff4affffffffa2ffffffffa28989ffffffffffffa2ffffffffffff0909090911ffffffffffffffff1111111111ffffffffffffffa1000000a1d3b00000000000c0e3e3d3ffffdddcffffd3b000000000c0e3a5f3e3a1000000000000000000000000000000000000000000000000000000000000
-- 045:40c2c2c2c2c2a1d3f3e3e3e3c1e1e3e3d3d3b8b8b8b8d3d3c80000000000e3d3ffffffffff5affffffffffffffffffffd3d3d3e3e3e3e3e3e3e3d3d3ffffff031314041323ffffffd3d3d3ffffff031314041323ffffffd3d3a100a1ffffffffffffffffffffffffffffffa100a1ffffffffff0909090909ffffffffffa2ffbaffffa205ffffffa21e89ffffeeeeffffa21222ffffffff09ffffff11ffffffffffffff0f11ffffff09ffffffffffffffa1000000a1d300000000000000e3e3d3ffffdddcffffd3000000000000e3a5f3e3a1000000000000000000000000000000000000000000000000000000000000
-- 046:a1f4f4f4f4f4f4d3a8b854b8b8b854b8d3ffffffffffffd3c8b4d4d4d4c4e3d3ffffffffff5affffffffffffffffffffd3d3d3e3e3e3e3c1f1e3d3ffffffffffff3242ffffffffffffd3ffffffffffff3242ffffffffffd3d3a100a1ffffffffffffffffffffffffffffffa100a1ffeeeeeeff091fff1f09ffffffffffa2ffffffffc305ffffffa2ffffffffffffff05a20142ffffff2e091effff11ffffffffffffffff11ff1fff092effffffff0fffa1000000a1d3b4d4d4d4d4d4c4e3e3d3ffffdddcffffd3b4d4d4d4d4c4e3a5f3e3a1000000000000000000000000000000000000000000000000000000000000
-- 047:a1e3e3e3e3e3c8ffff32540f0f0f5442ffffffff0212121222ffffffffffffffffffffffff5affffffffffffffffffffd3d3d3e32ae349e3e3e3d3ffffffffffff0323ffffffffffff1fffffffffffff0323ffffffffffffd3a100a1ffffffffffffffffffffffffffffffa100a1ffffffffff090e0dff09ffeeeeeeffa2ffffffffc3ffffffffa205ffffffffff8989a20142ffffffff090911111111111111111111111109090909ffffffffffffffa1000000a1ffff63737373627363ffffffffdddcffff6373727373727363ffffffa1000000000000000000000000000000000000000000000000000000000000
-- 048:a1e3e3e3e3e3c8ffff0392ffffff9223ffffffff3254929242ffffffffffffffffffffff70a2a2a2a202121222ffffffffffff0fffff5affffffffffffffffffff0f0fffffffffff1f1f1fffffffffff0f0fffffffffffffffa100a1ffffffffffffffffffffffbababaffa100a1ffffffffff091fff1f09ffffffffffa2ffffffffc3ffbaffffa205ffeeeeffff891ea20142ff0fffffffffffffffffff11ff0d11ffffffffffffffffffffffffffffa1000000a1ffffffffffffffffffffffffffdddcffffffffffffffffffffffffffa1000000000000000000000000000000000000000000000000000000000000
-- 049:a1b8b8b8b8b8c8ffffffffffffffffffffffffff32540eff42ffffffffffffffffffffffd3a2a2d3d332ffff42ffffffffffff0fffff5affffffffffffffffff0f0f0f0fffffffffff1fffffffffff0f0f0f0fffffffffffffa100a189898989898989ffffffffbaffffffa1a1a1ffffffffff0909090909ffffffffffa2ffffeeeec3ffffffffa205ffffffffffffffa21323ffffffffffffffffffffff11ffff11ffffffffffffffffffffffff0212a1000000c3ffff5c1bccccccccccccccccccdddccccccccccccccccccc5c1bffffc3000000000000000000000000000000000000000000000000000000000000
-- 050:a1ffffffffffffffffffffffffffffffffffffff3254ff0d42ffffffffff021222ffffffd3a2a2d3d3033333303122ffffffff0fffff5affffffffffffffffff0f0f0f0fffffffff021222ffffffffff0f0fffffffffffffa1a100a10d09ffffff2fffffffffffbaffffffd3e3d3ffffffffffffffffffffffffffffffa205ffffffffffffff2fa2ffffffffffffffffa2ffffffffffeeeeeeffffff111111111111ffffffffff0fffffeeeeeeff3201a1000000c3ffff1b1bbcbcbcbcbcbcbcbcbcdddcbcbcbcbcbcbcbcbcbc0b1bffffc3000000000000000000000000000000000000000000000000000000000000
-- 051:a1ffffffffffffffffffffffffffffffffffffff32540eff42ffffffffff32ff42ffffff0fa2a20ffeffffffff3242ffffff86e4e4e4e4e4e4e496ffffffffffff0f0fffffffff0224013422ffffff86e4e496495b5b5b49c3c300a10909ff2f1111ffff2effffbaffffffd3e3d3ffffffffffffffeeffffffffffffffa205ffffffffffffffffa28989ffffffffffffa2ffffffffffffffffffffff111effffff11ffffffffffffffffffffffff3201a1000000c3ffffffffffffffffffffffffffdddcffffffffffffffffffffffffffc3000000000000000000000000000000000000000000000000000000000000
-- 052:a1ffffffffffffffffffffffffffffffffffffff3292929242ffffffffff32ff42ffffff0fa2a2ff0effffffff3242ffffff95b9e5e5e5e5e5e5e6e4e4e4e4e4e4e4e4e496ffff3201010142ffff86f6b9e5e696ffffff86c3c300a1ffffffff1111ffffff2fffbaffffffd3e3d3ffffffffffffffeeffffffffffffffa205ffffffff0fffffffa21e89ffffeeeeff05a205ffffffffffffffff2eff11ffffffff1111ffffffffffffffffffffff3201a1000000c3e4e4e4e4e4e4e4e496ffffffffdddcffffffff86e4e4e4e4e4e4e4e4c3000000000000000000000000000000000000000000000000000000000000
-- 053:a1ffffffffffffffff0212121212121222ffffff03333333133333333333133323ffffff0fa2a2ff0dffffffff3242ffffff9556000000000000d5e5e5e5e5e5e5e5b9e585ffff0314010423ffff95f55600d585ffffff95e5f500a1ffffff2f1111ffffffffffbaffffffd3e3d3ffffffffffffffffffffffffffffffa20e2fffffffffffffffa2ffffffffffff0505c305ffffffffffffffff09091111ff0fffff111109090909ffffffffffff0313a1000000d5b9e5b9e5e5b9e5e585ffffffffdddcffffffff95e5e5b9e5e5e5b9e5f5000000000000000000000000000000000000000000000000000000000000
-- 054:a1ffffffffffffffff32bdffffffffcd42ffffffffffffffffffffffffffffffffffffff0fa2a2ff0effffffff0323ffffff95770000000000000000000000000000560085ffffff031323ffffff950056000085ffffff95000000a1ffffffffff2effffffffffffffffff86e4e4e4e4e4e4e4e4e4e4e496ffffffffffa2e4e4e4e4e4e4e4e4e4a2ffffffffffff8989c305ffffffff0fffffff09ffff11ffffffffff114eff1f092effffffffffffffa100000000c9d967d9d999d9d985ffffa2ffdddcffa2ffff95d9d999d9d9d9a90000000000000000000000000000000000000000000000000000000000000000
-- 055:c36e7effffffffffff32beff0effffce42ffffffffffffffffffffffffffffffffffffff0fa2a20fffffffffffffffffffff957700000000000000000000000000005666e7fffffffffffffffffff77656000085ffffff95000000a1ffffff2f1111ffffffffffffff1eff95000000000000000000000085495b5b5b49a2e5e5e5e5e5e5e5e5e5a2ffffeeeeffff891ec3ffffffffffffffffff09ff1f11ffffeeffff11ffff0f09ffffffffff0fffffa100000000000077009f45af0085ffff35ffdddcff35ffff95009f45af0000000000000000000000000000000000000000000000000000000000000000000000
-- 056:c36f7fffffffffffff0353333333334323ffffffffffffffffffffffffffffffffffffff70a2a2a2ffffffffffffffffffff95560000000000000000000000000000c985ffffffffffffffffffffff95a9000085ffffff95000000a1ffffff1111ffffffffffffbaffffffe6e4e4e4e4e4e4e4e4e4e4e4f6ffffffffffa2000000000000000000a2ffffffffffffffff49ffffffffffffffff2e09091111ffffeeffff1111111111ffffffffffffffffa100000000000077008563950085ffff35ffdddcff35ffff95008563950000000000000000000000000000000000000000000000000000000000000000000000
-- 057:c3e4e4e4e4e4e4e4e4e496ffffffffffffffffff44ffffffffff44ffffffffff708282828282828282828282828282828282a256000000000000000000000000000000e6e4e4e496ff0eff86e4e4e4f600000085ffffff95000000a1ffffffffffffffffffffffffffffffffffffffffffffffffbaffff2fffffffffffa2000000000000000000c305ffffffffffffff5affffffffffffffffffffffffffffffeeffffffffffffffffffffffffffffffa1000000000000c9d9e6e4f60085fffa35ffdddcff35faff9500e6e4f60000000000000000000000000000000000000000000000000000000000000000000000
-- 058:d5e5e5e5e5e5e5b9e5e585ffffffffffffffffff54ff0fff0fff54ffffffffffa2f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d356000000000000000000000000000000d5e5e5e5850e0d0e95e5e5e5f500000085ffffff95000000a1ffffffffffffffffffffffffffffffffffbaffffffffffffba2effffffffffffffa2000000000000000000c305ffffffffff0dff5affffffffffffffffffffffffffffffffffffffffffffffffffffffffffff05c30000000000000000d5b9f50085e8f8a619191919a6e8f89500d5b9f50000000000000000000000000000000000000000000000000000000000000000000000
-- 059:00000000000000c9d9d985ffffffffffffffffff920fff0fff0f92ffffff0effa2b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8d3a900000000000000000000000000000000000000e6e4e4e4f60000000000000085ffffff95000000a1ffffffffffffffffffffffffffffffffffffffff2effffffffffff2fffffffffffa2000000000000000000c30505ffffffffffff5affffffffffffffffffffffff0fffffffffffffffffffffffffffffffffff05c3000000000000000000c9d9d985e9f935ffdddcff35e9f995d9d9a9000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:00000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e496ffffffc3ffffff0eff0effffffffffffffffffffffd3a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a475ffffff95000000c3ffffffffffffffffffffffffffffffffffffffffffbaffffffffffffffffffffffc3000000000000000000c3050505ffffffffff5affffffffffffffffffffffffffffffffffffffffffffffffffffffff050505c300000000000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:00000000000000000000d5e5e5e5e5e5e5e5e5e5b9e5e5e5e5b9b9e5e6e4e4e4c36e7effff0effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff95000000c30909ffffffffffffffffffffffffffffffffffffffffffffffffff2fffffffffffc3000000000000000000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4495b5b5b5b49e4e4e4e4e4e4e4e4e4e4e4c300000000000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:00000000000000000000000000000000000000005600000000565600d5e5e5e5c36f7fff0eff0effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff95000000c30e09ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc3000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e585ffffffff95e5e5e5e5e5e5e5e5e5e5e5f500000000000000000000000085ffffa2ffdddcffa2ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:0000000000000000000000000000000000000000c9d9d9d9d97767d9d9d9d9d9b1e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6000000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4c300000000000000000000000000000000000000000000000066e4e4e4e4e4760066f6ffffffffe6760066e4e4e4e4e47600000000000000000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:0000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000000000000000000000000000000000000000000850212121222e6e4f6ffffffffffffe6e4f6ffffffffff9500000000000000000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008532ffffff42ffffffffffffffffffffff09ffff0effff9500000000000000000000000000000085fffa35ffdddcff35faff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008532ff0aff42ffffffffffffffffffffff09ff0eff0eff9500000000000000000000000000000085e8f8a619191919a6e8f895000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008532ffffff4286e4e496ffffffff86e4e496ffff0effff9500000000000000000000000000000085e9f935ffdddcff35e9f995000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 068:000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085033333332395e5e585ff6e7eff95e5e585ffffffffff9500000000000000000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 069:0000000000000000000000000000000000000000000000000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6e4e4e4e4e4f6000085ff6f7fff950000e6e4e4e4e4e4f600000000000000000000000000000085ffffffffdddcffffffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 070:000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2a1d3e3e3e3e3e3f3b00000000000000000c0e3e3e3f3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a1c2c2c241000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5f5000085ffffffff950000d5e5e5e5e5e5f500000000000000000000000000000085fffaa2ffdddcffa2faff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 071:0000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d3e3e3e3e3e3f300000000000000000000e3c1d2f3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3e3e3e3a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6e4e4e4e4f600000000000000000000000000000000000000000000000085e8f835ffdddcff35e8f895000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:0000a1e3e3e3e3b0000000c0e3e3e3e3e3e3e3e3e3e3e3e3f3e3e3e3e3e3d37373737373f3b4d4d4d4d4d4d4d4d4c4e3e3e3f3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3e3e3e3a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5f500000000000000000000000000000000000000000000000085e9f935ffdddcff35e9f995000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 073:0000a1e3e3e3e30000000000e3e3e3e3e3e3e3e3e3e3e3e3f3e3e3e3e3e3fefefefefefefefefefefefefefefefefefefefefe0212121222ffffffffff1fffffffff0effffffffffffffffffff1fffff111111ffffd3e3e3e3a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 074:0000a162737373b4d4d4d4c4b8b838b848b838b848b8b8b8f3b8b8b8b8b8ffffffffffffffffffffffffffffffffffff1fffff0313131323ffffff0fffffffffffff11ffffffffeeeeffff0fffffffff1111ffffffd349e3e3a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085ffffa619191919a6ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:0000a1fefefefefefefefefefefe6bfe4afe6bfe4afefefefeffffffffffffffffffffffffffffffbaffffffffffeeeeeeffffffffffffffeeeeffff0fffffffffff11ffffffffeeeeffffffff0fffff1111ffffffff5affffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085ffff35ffdddcff35ffff95000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:0000a1ffffffffffffffffffffff6bff4aff6bff4affffffffffff09ffffffffffffffffffffffffbaffff1fffbaeeee1fffffffffffffffeeeeffffffffffffffff11ffffffffeeeeffff0fffffffff1111ffffffff5a6e7ea100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066e4e4e4e4e4e4e4e4f6ffdddcffe6e4e4e4e4e4e4e4e476000000000000000000000000000000000000000000000000000000000000000000
-- 077:0000a1ffffffffffffffffffffff6bff4aff6bff4affffffffffba09ff1fffffffffffbaffff1fffbaffffffbabaeeeeeeffffffffffffffeeeeffffffeeeeffffff11ffffffffffffffffffffffffff1111ffffffff5a6f7fa1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066ea8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f65760000000000000000000000000000000000000000000000000000000000000000
-- 078:0000a1ffffffffffffffffffffff6bff4aff6bff4affffffffffbaffffffffffffffffbaffffffffffffff1fbabaeeee1fffffffffffffffffffffffffeeeeffffff11ffff0fffffffffffffeeeeffff1111ffffffff5affffa10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066ea8f8f8febfb8f8f8f8f8e8f8f8f8f8e8f8f8f8febfb8f8f8f657600000000000000000000000000000000000000000000000000000000000000
-- 079:0000a16e7effffffffffffffffff6bff4aff6bff4affffffffffffffffffffffffffffbaffff1fffffffffffffbaeeeeffffffffffffffff0fffffffffeeeeffffff11ff1fffff0fffffffffeeeeffff1111ffffffa1a1a1a1a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066ea8f8f8f8fecfc8f8e8f8f8f8e8f8f8e8f8f8e8f8fecfc8f8f8f8f6576000000000000000000000000000000000000000000000000000000000000
-- 080:0000c36f7fffffffffffffffffff6bff4aff6bff4affffffffffffffffffffffffffffffffffffffffffffffffffeeff1fffffffffffffffffff0fffffffffffffff11ffff0fffffffffffffeeeeffff1111ffffffa1b1b1b1b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8febfb8f8f8f8f8f8e8f8f8e8f8f8e8f8e8f8f8f8f8f8febfb8f8f95000000000000000000000000000000000000000000000000000000000000
-- 081:0000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e496ffffffffffffffffffffffffffffffffffffffffffffffffffffffff1fffffffffffff11ffffffff1fffffffffffffffff1111ffffffc3b1b1b1b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8fecfc8f8f8f8f8e8e8f8f8f8f8f8f8f8e8e8f8f8f8f8fecfc8f8f95000000000000000000000000000000000000000000000000000000000000
-- 082:0000d5e5e5e5e5e5e5e5e5e5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5b9e5e585ffffffffffff0212121222ffffffffffffffffffffffffffffffffffffffffffffffff11ffffffffffffffffffffffffff11110dffffc3b1b1b1b1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8e8e8f8f8f8f8e8e8e8e8f8f8f8e8e8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 083:00000000000000000000000000000000c9d9d9d9d9d9d9d9d9d9d9a90000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4c3e5e5e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8e8f8f8f8f8f8e8f8f8f8f8e8f8f8f8f8e8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 084:000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8e8f8f8f8f8f8e8f8e8e8e8e8f8e8f8f8f8f8e8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 085:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8e8f8f8f8f8f8f8e8f8e8e8e8e8f8e8f8f8f8f8f8e8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8e8f8f8f8f8f8f8f8e8f8e8e8e8e8f8e8f8f8f8f8f8f8e8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 087:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8e8f8f8f8f8f8f8e8f8e8e8e8e8f8e8f8f8f8f8f8e8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 088:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8e8f8f8f8f8f8f8e8f8f8f8f8e8f8f8f8f8f8e8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8e8f8f8f8f8f8f8e8e8e8e8f8f8f8f8f8e8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 090:00000000000000000000000000000000000000000000000000000040c2c2c24100000000000000000000000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e476000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8febfb8f8f8e8e8f8f8f8f8f8f8f8f8f8f8f8e8e8f8f8febfb8f8f95000000000000000000000000000000000000000000000000000000000000
-- 091:000000000000000000000000000000000000000000000000000000a1e3e3e3a100000066e4e4e4e4e4494949f63effee0dba0effffeeeeeeffffffffbabaff0e0effffffffeeeebababababababababababababaeeffff4eee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8fecfc8f8f8f8f8e8e8f8f8f8f8f8f8f8e8e8f8f8f8f8fecfc8f8f95000000000000000000000000000000000000000000000000000000000000
-- 092:000000000000000000000000000000000000000000000000000000a1e3e3e3a100000085ffffffffff5a5a5aeeeeeeeeeeba0effeeeeeeeeeeeeffffbaffffffffeeffffeeeeffba3eff0dffffff0eff0eeeeebaeeffffeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000858f8f8f8f8f8f8f8f8f8f8e8e8e8e8e8e8e8f8f8f8f8f8f8f8f8f8f8f95000000000000000000000000000000000000000000000000000000000000
-- 093:000000000000000000000000000000000000000000000000000000a1e3e3e3a100000085ff6e7effff5a5a5aeebababababaffeeeeeeffeeeeeeeebaba3eff0deeeeeeeeeeffffbaeeeeffffffffffeeeeeeffbaeeeeeeeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e6968f8f8f8f8f8f8f8f8e8f8f8e8f8f8e8f8e8f8f8f8f8f8f8f8f8f86f6000000000000000000000000000000000000000000000000000000000000
-- 094:00000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2a1e3e3e3a100000085ff6f7fffff5a5a5aeeeeffffbabaffeeeebababaeeeeeebaeeeeeeeeeebaeeeeeebababaeeeeeeeeeeeeeeeeeeeeffbababababaee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e6968f8f8febfb8f8e8f8f8f8e8f8f8e8f8f8f8e8febfb8f8f8f86f6f5000000000000000000000000000000000000000000000000000000000000
-- 095:000000a1e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3ff0effa100000085ffffffffff5a5a5affeeeeeeffffffeeeeffffbaeeeeeebababababababaeeeeeeeeffbabababababababaffffeeeeeeeeeeeeeeee9500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e6968f8fecfc8f8f8f8f8e8f8f8f8f8e8f8f8f8fecfc8f8f86f6f500000000000000000000000000000000000000000000000000000000000000
-- 096:000000a1e3e3e3e3b0000000c0e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3ff1fffa10000008502121222ff5a5a5affffeeeeeeeeffeeffffffbaffeeeeeeffffbaffffffffffeeeeeeffffffffbaffffffffffffffeeeeeeeeeeee950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6f50000000000000000000000000000000000000000000000000000000000000000
-- 097:000000a1e3e3e3e30000000000e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3eeeeeea10000008532ffff42ff5a5a5affffffffffeeeeee4eeeffbaffffeeffffffbabababaffffeeeeeeeeffffffbaffffffffffffffffffeeeeeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000000000000000000000000000000000000000000000000000000000000
-- 098:000000a1e3e3e3e3b4d4d4d4c4e3e3e3e3e3e3e3e3e3e3e3e3e3e3d3bababaa10000008532ff0a42ff5a5a5affffffffffeebaeeeeeebabaffffffffffffffffffbaffffffffffffbabababaffffffffffffffffffeeeeeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 099:000000a1ffffffffffffffffffffffff630889ffffffffffffffffffffffffd30000008503333323ff5a5a5affffffffffeebababababaffffffffffffffffffffbaffffffffffffbaffffffffffffffffffffffffffffeeee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 100:000000c3ff6e7effffffffffffffffff0f1789ffffffffffffffffffffffffd3000000e6e4e4e4e4e449494996ffffffffffffffffffbaffffffffffffffffffffbaffffffffffffbaffffffffffffffffffffffffffffffee95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 101:000000c3ff6f7fffffffffffffffffff0e1789ffffff0222ffffffffffffffd3000000d5e5e5e5e5e5e5e5e5e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e43a5b5b5b3ae4f6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 102:000000c3ffffffffffffffffffffffff0f1789ff0eff3242ffff8696ffffff95000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e585ffffff95e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3000000000000000000000000000000000000000000000000000000000000
-- 103:000000c3e4e4e4e4e4e4e4e496ffffff6308890212122442ffff9585ffffff9500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1b1000000000000000000000000000000000000000000000000000000000000
-- 104:000000d5e5e5e5e5e5e5e5e585ffffff8989890313131323ffff9585ffffff9500000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2410000000000000000000000000000000000000000000000000000000085ff0eff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3b2b2b2b2b2273737373737373737373737373737373747b3b3b3b3b3b3000000000000000000000000000000000000000000000000000000000000
-- 105:00000000000000000000000085ffffffffffffffffffffffffff9585ffffff95000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a10000000000000000000000000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b2b2b2b2b25900000000000000000000000000000000000069b2b2b2b2b2000000000000000000000000000000000000000000000000000000000000
-- 106:00000000000000000000000085ffffffffffffffffffffffffff9585ffffff95000000000000a1e3e3e3b000000000000000c0e3e3e3a1c2c2c2c2c2c2c2c2c2c241000000000000000000000000000000000085ff0eff9500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003500000000000000007a8a9a00aa7b8b9bab8cab9bbb0000000000000035000000000000000000000000000000000000000000000000000000000000
-- 107:00000000000000000000000085ffffffffffffffffffffffffff9585ffffff95000000000000d3e3e3e3000000000000000000e3e3e3f4f4f4f4f4f4f4f4f4f4f4a1000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 108:000000000000000000000000e6e4e4e4960fff0fff0f86e4e4e4f685ffffff95000000000000d3e3e3e3b4d4d4d4d4d4d4d4c4e3e3e3d3e3e3e3e3e3e3e3e3e3e3a1000000000000000000000000000000000085ff0eff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 109:000000000000000000000000d5e5e5e5e6e4e4e4e4e4f6e5e5e5f585ffffff95c2c2c2c2c2c2d3630808080808080808080808080863d3e3e3e3e3e3e3e3e3e3e3c3000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 110:00000066e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6ffffff95e349e3e349e3d389ffffffffffff4effffffffffffffd3e3e3e3e3e3e3e3e3e3e3c3000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 111:00000085ffffffffffffff4effffbaffffffffff090909ffffffffffffffffffff5affff5affffffffffffffffffffffffffffffffff891f1dffff0e0effff1d1fc3000000000000000000000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 112:00000085ffffffffffffffffffffbaffffffffff090909ffffffffffffffffffff5affff5affffffffffffffffffffffffffffffffff891d1dffff0dffffff1d1dc3e4e4e4e4e4e4e47600000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 113:000000850e0d0effffffffffffffbaffffffffff090909ffffffffffffffffffff5affff5affffffffffffffffffffffffffffffffff89ffffffffffffffffffff49ffffffffffffff9500000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 114:00000085bababababababababababaee86e4e4e4e4e4e496ffffffffffffffffff5affff5affffffffffffffffffffffffffffffffff63babababababababababa5affffffffffffff9500000000000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 115:00000085ffffeeeeeeeeeebaeeeeeeee95e5e5e5e5e5e585ffffff78e4e4e4e4e4e4e4e4e4e4e4e4e4e4966308080808080863ffffff17ffffff86e496ffffffff5affffffffffffffe6e4e4e476000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000350000000000000000000000000000000000000000000000000000000035000000000000000000000000000000000000000000000000000000000000
-- 116:40c2c285ffffffeeeeeeeebaeeeeeeee9500000000000085ffffff79a4a4a4a4a4a4a4a4a4a4a4a4da0085ffffffffffffff17ffffff17ffffff95e585ffffffff5affffffffffffff89ff0dff95000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000353636363636460000000000000000000000000000000026363636363635000000000000000000000000000000000000000000000000000000000000
-- 117:a1e3e385ffffffffeeeeeebaeeff0eee9500000000000085ffffff898989890f0f0f0f0f89898989950085ffffffffffffff17ffffff17ffffff950085ffffffff5affffffffffffff89ffffff95000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3b3b3b3b3b3b39c9d9d9d9d9d9d9d9d9d9d9d9d9d9d9eb3b3b3b3b3b3b3000000000000000000000000000000000000000000000000000000000000
-- 118:a1e3e385ffffffffffeeeebaff4effee9500000000000085ffffffffffffffffffffffffffffba89950085ffffffffffffff17ffffff17ffffff950085ffffff86e4e4e4e496ffffff89ffffff95000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3000000000000000000000000000000000000000000000000000000000055
-- 119:a1e389898989eeeeeeeeeebaeeff0eee9500000000000085ffffffffffffffffffffffffffffba8995d985ffff63ff0e0eff17ffffff17ffffff950085ffffff95e5e5e5e585ffffff89ffffff95000000000085ffffff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000056
-- 120:a1e389898989eeeeffeeeebaeeeeeeee9500000000000085ffffffffffffffffffffffffffffba0f95d985ffff17ffffffff17ffffff17ffffff950085ffffff950000000085ffffff89ffffffe6e4e4e4e4e4f6ffffffe6e4760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010101010101010101010101010bf101010101010101010101010101010101010101010101010101010101010101010bf1010101010000000000000000000000000000000000000000000000000000000000056
-- 121:a1ffffffffeeeeffffffeebaeeeeeeee95000000000000e4e4e4e4e4e4e4e4e496ffffffffffba0f95d985ffff17ffffffff17ffffff63ffffff950085ffffff950000000085ffffffffffffff89babababababababababa1f950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010cf101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000056
-- 122:a1ffffffeeeebaffffffeebabababaee95000000000000d5e5e5e5e5e5e5e5e585ffffffffffba0f950085ffff630808080863ffffffffffffff950085ffffffe6e4e4e4e4f6ffffffffffffff89ff0f0fffffffffffffbaff950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010bf101010101010101010101010101010101010101010101010101010cf1010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000056
-- 123:c3ffff0eeeeebaffffffeeeeeeeeeeeee6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6ffffffffffba0f950085ffffffffffffffffffffffffffffffe6e4f6ffffff1d1d1d1d1d1dffffffffffffff89ffffffffffffffffffba1f9500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101010101010101010101010101010101010101010101010101010101010101010bf1010101010101010cf10101010101010000000000000000000000000000000000000000000000000000000000056
-- 124:c33eff0deeeebaffffffffffffffffffffffffffffffffffffffbaffffffffffeeffffffffffba0f950085ffffffffffffffffffffffffffffffffbaffffffff1dffffffff1dffffff89ffffff89ffffffffffffffffffbaff95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000057
-- 125:c3ffffffffeebaffffffffffffffffffffffffffffffffffffffbaffffffffffeeffffffffffba8995d9e6e4e4e4e4e4e4e4e4e4e4e496ffffffffbaffffffff1dff3effff1dffffff89ffffffffffffffbaffffffffbaff1f9500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101010101010101010101010cf10101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 126:c3ffffffffeebaffffffffffffffffffffffffffffffffffffffbaffffffffffeeffffffffffba899500d5e5e5e5e5e5e5e5e5e5e5e585ffffffffbaffffffff1dffffffff1dffffff89ffffffffffffffbaffffffffbaffff95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010bf1010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 127:c3e4e4e4e496baffffffffffffffffffffffffffffffffffffffba0f0f0f0f0fbababababababa89950000000000000000000000000085ffffffffbaffffffff1dffffffff1dffffff89ff0f0fffffffffbaff0f0fffbaff1f95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010cf101010101010101010101010101010bf10101010101010101010101010bf10101010101010101010101010cf101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 128:d5e5e5e5e585babababababababababababababababababababababababababa86e4e4e4e4e4e4e4f60000000000000000000000000085ffffffffbaffffffff1d1d1d1d1d1dffffff89ffbabababababababababababaffff95000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010bf1010101010000000000000000000000000000000000000000000000000000000000000
-- 129:0000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6e5e5e5e5e5e5e5f500000000000000000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101010101010101010101010101010101010bf10101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 130:0000000000d5e5e5e5e5e5e5e5b9e5e5e5e5e5e5e5b9b9e5e5e5e5e5e5b9e5e5f5000000000000000000000000000000000000000000d5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5e5b9b9e5e5e5e5e5b9e5e5e5e5e5e5e5e5e5e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010cf1010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 131:00000000000000000000000000c9d9d9d9d9d9d9d99999d9d9d9d9d9d9a90000000000000000000000000000000000000000000000000000000000c9d9d9d9d9d9d9d9d9d9d9d99999d9d9d9d9d9a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010bf101010101010101010101010101010101010101010101010cf101010101010101010101010101010bf1010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 132:0000000000000000000000000000000000000000006756000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000567700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010101010101010101010101010101010101010101010101010101010101010bf101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 133:00000000000000000000000000000000000000009f4545a4af00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000567700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010cf10101010101010101010101010bf1010101010101010101010101010101010101010101010101010101010101010cf10101010000000000000000000000000000000000000000000000000000000000000
-- 134:000000000000000000000000000000000000000085636363950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- 135:0000000000000000000000000000000000000000e6e4e4e4f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c999d9d9640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
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
-- </SFX>

-- <PALETTE>
-- 000:100c1ce234c6595971deca69c23830ce89408dc24414304885b6d271aaca5d65717d8d95994c409daaaac6d2cadeeed6
-- </PALETTE>

