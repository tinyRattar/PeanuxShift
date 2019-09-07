-- title:  MadPhysicist
-- author: PEANUX Studio
-- desc:   I don't know. Maybe a Zelda-like game.
-- script: lua

-- predefine
CAMERA_OFF={15*8-4,8*8-4}
NEARBY4 = {{-1,0},{1,0},{0,-1},{0,1}}
FAKERANDOM8={4,2,7,5,1,8,3,6}

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
MAP_COLLIDE=set({4,20,23,26,27,38,39,40,41,42,44,54,55,58,60,61,62,63,75,76,77,78,79,93,94,95,110,111})
MAP_ENTER_DANGER=set({17,178,179})
MAP_ENTER_FREE=set({231,238})
MAP_REMAP_BLANK=set({208,224,240,241,144})
MAP_TOUCH=set({113,128,176,177})

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
player.hp = 50
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
--player.atkRect = {{player.x+player.w,player.y,10,16},{player.x-10,player.y,10,16}}
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
			-- todo: element attack
			local knockback=self.fwd
			-- todo: knockback check
			if(tar.canHit)then
				tar:onHit(damage(self.attack,0))
				if(tar.tiStun>0)then
					for i=1,10 do tar:move(knockback[1],knockback[2],true) end
				end
			end
		end
	end
end
function player:onHit(dmg)
	self.hp=self.hp-dmg.value
	if(self.hp<0)then self.hp=0 end
	--trace("player hp:"..self.hp)
	--todo: on hit
end
function player:hpUp(value)
	self.hp=self.hp+value
	if(self.hp>100)then self.hp=100 end
	--trace("player hp:"..self.hp)
	--todo: hp check
end
function player:getKey()
	self.key1=self.key1+1
end
function player:control()
	-- controller
	if(self.state~=-1) then
		if btn(0) then player:movec(0,-self.tmMul,true) player.fwd={0,-1} end
		if btn(1) then player:movec(0,self.tmMul,true) player.fwd={0,1} end
		if btn(2) then player:movec(-self.tmMul,0,true) player.fwd={-1,0} end
		if btn(3) then player:movec(self.tmMul,0,true) player.fwd={1,0} end
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
	camera.x = self.x-CAMERA_OFF[1]
	camera.y = self.y-CAMERA_OFF[2]
	local ox,oy=self.x,self.y
	if(self.tiStun>0)then
		self.state=0
		self.tiStun=self.tiStun-self.tmMul
	else
		player:control()
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
	local offX=0
	local offX_s=11
	local off_sy=0
	local sprFlip=(1-self.fwd[1])//2
	if(player.fwd[1]==-1) then offX=self.w-16 offX_s=-11	end
	if(player.fwd[2]==1) then offX_s=0 off_sy=12 elseif(player.fwd[2]==-1) then offX_s=0 off_sy=-11 end
	if(self.tiStun>0)then
		sprc(256,self.x+offX,self.y,1,1,sprFlip,0,2,2)
		self:drawStun()
	elseif(self.state==0) then
		sprc(256+t//(20/self.tmMul)%2 * 2,self.x+offX,self.y,1,1,sprFlip,0,2,2)
	elseif(self.state==1) then
		if self.ti1>=16 then sprc(260,self.x+offX,self.y,1,1,sprFlip,0,2,2)
		elseif self.ti1>=14 then sprc(262,self.x+offX,self.y,1,1,sprFlip,0,2,2)
		else sprc(264,self.x+offX,self.y,1,1,sprFlip,0,2,2)
		end

		if self.ti1>=16 then sprc(320,self.x+offX_s,self.y+off_sy,1,1,sprFlip,0,2,2)
		elseif self.ti1>=14 then sprc(322,self.x+offX_s,self.y+off_sy+1,1,1,sprFlip,0,2,2)
		else sprc(324,self.x+offX_s,self.y+off_sy+6,1,1,sprFlip,0,2,2)
		end
	end
end
function player:touch(tile)
	local tileId,tx,ty=tile[1],tile[2],tile[3]
	if(tileId==177)then
		if(mget(tx,ty)==177 and self.key1>0)then
			mset_4ca(tx,ty,178,177)
			self.key1=self.key1-1
		end
	elseif(tileId==176)then 
			if(mget(tx,ty)==176 and self.key1>0)then
				mset_4ca(tx,ty,179,176)
				self.key1=self.key1-1
			end
	elseif(tileId==113 or tileId==128)then
		self.tiStun=60
		shockActive((tx-iMapManager.offx)*8,(ty-iMapManager.offy)*8)
	end
end
function player:enter(tile)
	local tileId,tx,ty=tile[1],tile[2],tile[3]
	if(tileId==178)then
		mset_4ca(tx,ty,255,178)
	elseif(tileId==179)then
		mset_4ca(tx,ty,255,179)
	elseif(tileId==17)then
		self:onHit(damage(1))
	elseif(tileId==231)then
		loadLevel(curLevel+1)
	elseif(tileId==238)then
		self.onButter=true
	end
end
-- endregion

-- region ARTIFACT
-- region the Gravation
theGravition=artifact(60,15)
theGravition.range=10*8
theGravition.rangePow2=theGravition.range*theGravition.range
theGravition.force=5
theGravition.sprite=352
function theGravition:use()
	if(self:switchOn())then
		trace("the Gravition ON!")
	end
end
function theGravition:iPull(m,isReverse)
	local scale=m.pullMul
	if(isReverse)then scale=m.pushMul end
	if(scale<=0)then return end
	local ir=1
	if(isReverse)then ir=-1 end
	local dv=CenterDisVec(player,m)
	local mdis=dv[1]*dv[1]+dv[2]*dv[2]
	if(mdis>=self.rangePow2)then return end
	dv={dv[1]*ir,dv[2]*ir}
	dv=vecNormFake(dv,1)
	-- if(dv)
	-- local dvm=math.abs(dv[1])
	-- local dvmt=math.abs(dv[2])
	-- if(dvm<dvmt)then dvm=dvmt end
	-- if(dvm<1)then return end
	m:movec(theGravition.force*dv[1]*scale,theGravition.force*dv[2]*scale,true)
end
function theGravition:pull(isReverse)
	for i=1,#mobManager do
		local m=mobManager[i]
		if(m and m~=player)then
			self:iPull(m,isReverse)
		end
	end
	for i=1,#envManager do
		local e=envManager[i]
		if(e)then	self:iPull(e,isReverse) end
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
	self.sprite=384

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
theKelvinWand.sprite=356
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
	function m:death()
		-- todo: do something like score change
		-- or maybe dead mob is a mob as well?
		if(m.isDead)then return false end
		for i=1,#mobManager do
			if(mobManager[i]==self)then table.remove(mobManager,i) end
		end
		m.isDead=true
		shine(self.x,self.y)
		return true
		-- table.remove(mobManager,self)
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
		if(tileId==17)then
			self:death()
		end
	end
	function m:defaultMove()
		local dv=CenterDisVec(player,self)
		local dvn=vecNormFake(dv,1)
		local _tmMul=self.tmMul
		if(self.tmMul>0)then _tmMul=1 end
		self:movec(dvn[1]*self.ms*_tmMul,dvn[2]*self.ms*_tmMul)
		return dv,dvn
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

	return m
end

function slime(x,y)
	local s = mob(x,y,8,8,15,5*8)
	s.ms=0.5
	s.tiA=0
	s.fwd={-1,0}
	s.meleeRange=(16+8)//2+6
	s.attack=1
	s.waitMeleeCalc=false
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
		if(not self:defaultElem())then return end
		if(self.tiStun>0)then
			self.state=0
			self.tiStun=self.tiStun-self.tmMul
			return
		end
		if(self.sleep)then
			self:tryAwake()
			return
		end
		if(self.state==0)then
			local dv,dvn=self:defaultMove()
			if((math.max(math.abs(dv[1]),math.abs(dv[2])))<=self.meleeRange)then
				self.fwd=dvn
				--if(dv[1]<(self.w//2))then self.fwd[1]=0 end
				--if(dv[2]<(self.h//2))then self.fwd[2]=0 end
				self:startAttack()
			end
		elseif(self.state==1)then
			if(self.waitMeleeCalc and self.tiA>=35)then self:meleeCalc() self.waitMeleeCalc=fasle end
			self.tiA=self.tiA+self.tmMul
			if(self.tiA>=90)then self:defaultMove() end
			--if(self.tiA>=90)then end
			if(self.tiA>=120)then self.state=0 end
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
	function rg:startAttack(vecDirection)
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
		if(not self:defaultElem())then return end
		if(self.tiStun>0)then
			self.state=0
			self.tiStun=self.tiStun-self.tmMul
			return
		end
		if(self.sleep)then
			self:tryAwake()
			return
		end
		local sx=self.x+self.w//2
		local sy=self.y+self.h//2
		local tx=player.x+player.w//2
		local ty=player.y+player.h//2
		if(self.state==0)then
			if(MDistance({x=tx,y=ty},{x=sx,y=sy})<=self.range)then
				self:startAttack({tx-sx,ty-sy})
			end
		elseif(self.state==1)then
			if(self.waitShoot and self.tiA>=40)then self:shoot({tx-sx,ty-sy}) end
			self.tiA=self.tiA+self.tmMul
			if(self.tiA>=90)then self.state=0 end
		end
	end
	function rg:draw()
		if(self.tiStun>0)then
			sprc(496,self.x,self.y,0,1,0,0,1,1)
			self:drawStun()
		elseif(self.state==0)then
			sprc(496+t//(20/self.tmMul)%2 * 1,self.x,self.y,0,1,0,0,1,1)
		elseif(self.state==1) then
			if(self.tiA<30)then 
				sprc(498,self.x,self.y,0,1,0,0,1,1)
			elseif(self.tiA<60)then 
				sprc(496,self.x,self.y,0,1,0,0,1,1)
			else
				sprc(496+t//(20/self.tmMul)%2 * 1,self.x,self.y,0,1,0,0,1,1)
			end
		end
	end

	return rg
end

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

	function wr:update()
	end
	function wr:draw()
		sprc(144,self.x,self.y,0,1,0,0,1,1)
	end

	return wr
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

function keyItem(x,y)
	local k=item(x,y,8,8)

	function k:onTaken()
		player:getKey()
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
	tb.lifetime=60
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
	kb.speed=2
	kb.fwd=fwd or {1,0}

	function kb:update()
		self:defaultTic()
		if(self.tCollided)then self:remove() end
		if(self:hitCheck())then	self:remove()	end
	end
	function kb:draw()
		--pixc(self.x,self.y,4)
		local color=5
		if(self.elem==2)then color=9 end
		circc(self.x,self.y,2,color)
		circbc(self.x,self.y,3,15)
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

	function ef:remove()
		for i=1,#envManager do
			if(envManager[i]==self)then table.remove(envManager,i) end
		end
	end

	return ef
end

function shine(x,y)
	local sh = effect(x,y,0,0)
	sh.ti=0

	function sh:update()
		self.ti=self.ti+1
		if(self.ti>=60)then self:remove()end
	end
	function sh:draw()
		sprc(194+(self.ti//20),self.x,self.y,0,1,0,0,1,1)
	end

	table.insert(envManager,sh)
	return sh
end

function shockActive(x,y)
	local sa=effect(x,y,0,0)
	sa.ti=0

	function sa:update()
		self.ti=self.ti+1
		if(self.ti>=30)then self:remove()end
	end
	function sa:draw()
		local off=self.ti//10
		local color={15,5,3}
		rectbc(x-off,y-off,8+off*2,8+off*2,color[off+1])
	end
	table.insert(envManager,sa)
	return sa
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
-- endregion

-- region MANAGER
function redraw(tile,x,y)
	local outTile,flip,rotate=tile,0,0
	if(MAP_REMAP_BLANK:contains(tile))then
		outTile=255
	end
	return outTile,flip,rotate
end

iMapManager = {offx=0,offy=0}
-- function iMapManager:update() end
function iMapManager:draw()
	map(0+self.offx+camera.x//8,0+self.offy+camera.y//8,31,18,8*(camera.x//8)-camera.x,8*(camera.y//8)-camera.y,0,1,redraw)
end

uiStatusBar={hp=player.hp*2}
function uiStatusBar:draw()
	local tmp_=0
	rect(7,7+tmp_,200,7,15)
	if self.hp>player.hp*2 then 
		rect(9, 9+tmp_, self.hp, 3, 4)
		self.hp = self.hp-1/60*10  
	else
		self.hp=player.hp*2
	end
	rect(9,9+tmp_,player.hp*2,3,6)

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
	
	
	-- spr(atfManager[2].sprite+2*atfManager[2].mode,7+16+4,14*8,1,1,0,0,2,2)
	-- rect(7+16+4,15*8-6,16*(atfManager[2].tiCD/atfManager[2].cdTime),5,2)
	-- print("Y",7+16+4,15*8+8,15)
	
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
	local lOff = {{0,0},{0,17*2+2}}
	local MapSize = {{30*3,17*2+2},{30*3,17*2}}
	local playerPos = {{120,80},{30+0,120}}
	iMapManager.offx = lOff[levelId][1]
	iMapManager.offy = lOff[levelId][2]
	-- todo initMap
	for i=1,#mobManager do mobManager[i]=nil end
	for i=1,#envManager do envManager[i]=nil end
	player.x=playerPos[levelId][1]
	player.y=playerPos[levelId][2]
	table.insert(mobManager,player)
	for i=1,MapSize[levelId][1] do
		for j=1,MapSize[levelId][2] do
			local mtId=mget(i+iMapManager.offx,j+iMapManager.offy)
			if(mtId==240)then 
				table.insert(mobManager,slime(i*8,j*8))
			elseif(mtId==241)then 
				table.insert(mobManager,ranger(i*8,j*8))
			elseif(mtId==224)then
				table.insert(envManager,apple(i*8,j*8))
			elseif(mtId==208)then
				table.insert(envManager,keyItem(i*8,j*8))
			elseif(mtId==209)then
				table.insert(mobManager,fence(i*8,j*8))
			elseif(mtId==144)then
				table.insert(mobManager,weakRock(i*8,j*8))
			end
		end
	end
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
-- endregion

--playerManager={player}

--npcManager={}
--atfManager={theGravition, theGravition}

--table.insert(mobManager,player)
--table.insert(mobManager,slime(140,50))

t=0
camera={x=0,y=0}

mainManager = {mobManager,atfManager,envManager}
drawManager = {{iMapManager},envManager,{player},mobManager,atfManager,uiManager}

loadLevel(curLevel)

function TIC()
	-- update
	for i=1,#mainManager do
		for j=1,#mainManager[i] do
			local obj=mainManager[i][j]
			if(obj)then obj:update() end
		end
	end

  -- draw
  cls(0)
  for i=1,#drawManager do
    for j=1,#drawManager[i] do
			drawManager[i][j]:draw()
		end
	end
	
	t=t+1
	--trace("test"..a)
end

-- <TILES>
-- 001:98888899888889998888999888899988e8999888e9998888ee988888eeee8889
-- 002:eeee8899ee888999e8889998e889998888999888899988889998888899888889
-- 004:0000000000000000000000000000000000a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 005:a0a0a0a00a0a0a0aa0a0a0a00a0a0a0ad0a0a0a0db0a0a0adbb0a0a0dbbb0a0a
-- 006:addddddd0afffffda0aeeeed0a0aeeeda0a0aeed0a0a0aeda0a0a0ad0a0a0a0a
-- 007:ddddddd0ffffff0aeeeee0a0eeee0a0aeee0a0a0ee0a0a0ae0a0a0a00a0a0a0a
-- 008:00000ddd000000dd000000dd000000dd000000dd000000dd000000dd000000dd
-- 009:ddd00000dd000000dd000000dd000000dd000000dd000000dd000000dd000000
-- 010:00000ddd0000000d0000000d0000000000000000000000000000000000000000
-- 011:ddd00000d0000000d00000000000000000000000000000000000000000000000
-- 012:00000ddd0000000d0000000d0000000000000000000000000000000000000000
-- 013:dddeedddddeeeddddddeeddddddeeddddddeeddddddeeddddddeedddddeeeedd
-- 014:ddeeeedddeeeeeeddeeddeeddddddeedddddeeeddddeeeddddeeeddddeeeeeed
-- 015:ddeeeedddeeddeeddeeddeedddddeeedddddeedddeeddeeddeeddeedddeeeedd
-- 016:0004500000450000045000044500004550000450000045000004500000450000
-- 017:0045000404500045450004505000450000045000004500040450004545000450
-- 018:9888889988888999888899988889998888999888899988889998888899888889
-- 020:00000000000000000000000000000000a0a0a0000a0a0a00a0a0a0a00a0a0a0a
-- 021:a0a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0abaa0a0abba0a0abbba
-- 022:a0a0eeee0addddddaddddddd0dddddddddddddddddddddddddddddddbbbbbbbb
-- 023:eeeea0a0dddddd0addddddd0dddddddaddddddddddddddddddddddddbbbbbbbb
-- 024:000000a0000a0a0a00a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 025:a0a000000a0a0a00a0a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 026:a0a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 027:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 028:ddeeeedddeeddeeddeeddeeddeeddeeddeeddeeddeeddeeddeeddeedddeeeedd
-- 029:dddeeeedddeeeeeddeeedeedeeeddeedeedddeedeeeeeeeeeeeeeeeedddddeed
-- 030:deeeeeeddeeeeeeddeeddddddeeeeeedddeeeeeeddddddeeddddddeedeeeeeed
-- 031:ddeeeedddeeddeeddeeddeeddeeddddddeeeeeeddeeddeeddeeddeedddeeeedd
-- 037:eeeaeeeeeebebbeeeeeeaeeeeebbebeeeeeaeeeeeebebbeeeeeeaeeeeebbebee
-- 038:eeeeeeeedddddddddfddd6bddfdddb5dddddddddaaaaaaaaaaaaaaaaaaaaaaaa
-- 039:eeeeeeeedddddddddddababdddd49badddddddddaaaaaaaaaaaaaaaaaaaaaaaa
-- 040:ababababbabababaababababbabababadddddddddddddddddddddddddddddddd
-- 041:ababababbabababaababababbabababaeddddddbeddddddbeddddddbeddddddb
-- 042:ababababbabababaababababbabababaababababbabababaababababbabababa
-- 043:ddddddddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaa
-- 044:00000000000000000000000000000000a0a0a0a00a0a0a0aa0a0a0a00a0a0a0a
-- 045:deeeeeeddeeeeeeddddddeeddddddeedddddeeddddddeedddddeeddddddeeddd
-- 046:ddeeeedddeeddeeddeeddeeddeeeeeeddeeeeeeddeeddeeddeeddeedddeeeedd
-- 047:ddeeeedddeeddeeddeeddeeddeeeeeedddeeeeeddddddeeddedddeedddeeeedd
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
-- 072:dbbbbbbbdbbbbbbbdbbbbbbb0dbbbbbb0dbbbbbb00dbbbbb000aabbb00000aaa
-- 073:bbbbbbbdbbbbbbbdbbbbbbbdbbbbbbd0bbbbbbd0bbbbbd00bbbaa000aaa00000
-- 074:000000000000000000000000ffffffffeeeeeeeeddddddddbbbbbbbbbbbbbbbb
-- 075:0000000000000000f0000000efffffffdeeeeeeedddddddddddddddddddddddd
-- 076:00000000000000000000000ffffffffeeeeeeeeddddddddddddddddddddddddd
-- 077:000000000000000000000000ffffffffeeeeeeeedddddddddddddddddddddddd
-- 078:ddddddddffffffffeeeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 079:eeeeeeeeddddddddddddddddddddddddddddddddddddddddddddddddbbbbbbbb
-- 088:ddddddddffffffffeeeeeeffeeeeeefeeeeeeefeeeeeeefeeeeeeefeeeeeeefe
-- 089:ddddddddfffffffdeffeeeedeefeeeeddefeeeeddefeeeeddefeeeeddefeeeed
-- 090:dddddefefffddefeeedbbefeeebbbefeeebbbefeeeabbefeeeeaaefeeeeeeefe
-- 091:dddddefefffffefeeeeeeefeeeeeeefeeeeeeefeeeeeeefeeeeeeefeeeeeeefe
-- 092:dd000000dd000000ddf00000ddefffffdddeeeeedddddddddddddddddddddddd
-- 093:bbbbbbbbbabababaabababab0aaaaaaa00aaaaaa000000000000000000000000
-- 094:bbbbbbbbbabababaababababaaaaaaaaaaaaaaaa000000000000000000000000
-- 095:bbbbbbbbbabababaababababaaaaaaa0aaaaaa00000000000000000000000000
-- 098:eefffffeff5555fef55ccccff5c55ccff555ccaff55ccacffcccacafeffffffe
-- 099:dffffffdf555555ff5ffff5ff555555feff5fffdeef555fdeef5ffedeeef55fd
-- 106:defeeeeddefeddfddefebbdddefebbbddefebbbddefebbaddefeaaeddefeeeed
-- 107:defedddddefefffddefeeeeddefeeeeddefeeeeddefeeeeddefeeeeddefeeeed
-- 108:000000dd000000dd00000fddfffffeddeeeeeddddddddddddddddddddddddddd
-- 109:eeeeeeeeeddddddbeddddddbeddddddbeddddddbeddddddbeddddddbbbbbbbbb
-- 110:defddddddeefffffddeeeeeeddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 111:ddddddfeffffffeeeeeeeeedddddddddddddddddbbbbbbbbbbbbbbbbbbbbbbbb
-- 112:eeeeeeee4eee4eeee4e4e4e4ee4eee4e4eee4eeee4e4e4e4ee4eee4eeeeeeeee
-- 113:e4ee4eeeee4ee4eee4ee4eeeee4ee4eee4ee4eeeee4ee4eee4ee4eeeee4ee4ee
-- 114:eeeeeeeeeeeeeeeeeffffffef755557ff755557ff777777ffaaaaaafeffffffe
-- 115:eeeeeeeeeeffffeeef5555fef755557ff7cccc7ff777777ffaaaaaafeffffffe
-- 124:eeeefdabffffdbbabdbdbdabdbdbdbbabdbdbdabdbdbdbbabdbdbdbddbdbdbba
-- 125:badbfeeeabbdfeeebadbdfffabbdbdbdbadbdbdbabbdbdbddbdbdbdbabbdbdbd
-- 126:abbdbdbddbdbdbdbabbdbdbdbadbdbdbabbdbdbdbadbdfffabbdfeeebadbfeee
-- 127:dbdbdbbabdbdbdbddbdbdbbabdbdbdabdbdbdbbafffdbdabeeefdbbaeeeebdab
-- 128:eeeeeeeeee4eee4ee4e4e4e44eee4eeeee4eee4ee4e4e4e44eee4eeeeeeeeeee
-- 129:eee4ee4eee4ee4eeeee4ee4eee4ee4eeeee4ee4eee4ee4eeeee4ee4eee4ee4ee
-- 130:11111111effc66feff4444fff434434ff444444ff443344fff4444ffeffffffe
-- 131:eeeeeeeeddaaaadddabbbbadda4554add445544dd445544dd445544db445544b
-- 141:ddddddddfffffffdeeeeebdbeeeebdbdeeeedbdbeeeebdbdeeeedbdaeeeebdbb
-- 142:ddddddddfffffffddbbdbdbdbddbdbdbdabababaababababbabababaa0a0a0a0
-- 143:ddddddddfffffffdbdbeeeeddbdbeeedbdbdeeeddbdbeeedadbdeeedbadbeeed
-- 144:ddddddddfdddbddbbbdddbbabddbdbbabedbbbabbadbbabaebababaaeabaaabd
-- 145:11111111eeffffeeef4444fef044440ff404404ff444444ff444444ff4f4f4fe
-- 146:effffffeff5555fff55cc55ffccccccff55cc55ff555555ff555555feffffffe
-- 147:e445544ee445544ee445544ee445544ee445544ee445544ee445544ee445544e
-- 152:ccc5cccccc555c4cc5cc5cccc5ccccccccc5ccccccccc5ccc4cccccccccccccc
-- 157:dddddbdaffffdeddeeeedbbaeeeebdabeeeedbbaeeeebdabeeeedbbaeeeebdab
-- 159:abbdddddddedfffdabbdeeedbadbeeedabbdeeedbadbeeedabbdeeedbadbeeed
-- 160:eeeeeeeedd444444aad44444aaa55555aaa55555aa04444400444444eeeeeeee
-- 161:eeeeeeee444444dd44444daa55555aaa55555aaa444440aa44444400eeeeeeee
-- 162:fffffffdfeeeeeedfeeeaeedfeeeaeedfeeaaaedfeeaaaedfeeeeeeddddddddd
-- 163:eeeeeeeeedaaaadbeabbbbabeab00babeabbbbabedaaaadbeddddddbbbbbbbbb
-- 168:dcddcdddccfcfcccecceececcccccccdcec5cccdceccc5cceccccceceeeccced
-- 169:d55555ddd55555ddd55555ddd55555ddd55555ddd55555ddd55555ddd55555dd
-- 173:ddddbdabffffdbdaeeeebdabeeeedbdbeeeefdbdeeeeeffdeeeeeeedeeeeeeed
-- 174:a0a0a0a0babababaababababdbdbdbdbbdbdbdbdfffffffdeeeeeeedeeeeeeed
-- 175:adbdddddbadbfffdadbdeeeddbdbeeedbdbfeeedfffeeeedeeeeeeedeeeeeeed
-- 176:eeeeeeee444444444444444455555555555555554444444444444444eeeeeeee
-- 177:e445544ee445544ee445544ee445544ee445544ee445544ee445544ee445544e
-- 178:e668866ee668866ee668866ee668866ee668866ee668866ee668866ee668866e
-- 179:eeeeeeee666666666666666688888888888888886666666666666666eeeeeeee
-- 184:cdcdcdcdfcfcffcdece5ccedccecccecccc5cecdecccccedeecc5ccdcccecccc
-- 185:000000000000000000000000ffffff00eeeeeef0dddddefedddddefedddddefe
-- 190:bfffffeebddddfeebddddfeebddddeddbddddebbbddddebbbddddebbbddddebb
-- 191:eeeeeeeeeeeeeeeeeeeeeeeedddeeeeebbdeeeeebbdeeeeebbdddddebbdbbbde
-- 192:0000000000000000003300000f33ff000f000330033ff3300330000000000000
-- 193:00000000000000000000330033ff330033000f000ff33f000003300000000000
-- 194:0000000000000000000000000004400000044000000000000000000000000000
-- 195:000000000000000000c0c00000c00c000000000000c0cc000000000000000000
-- 196:000000000a00a000000000a00a00000000000000000000000a00a0a000000000
-- 200:ddddddddfffffffdeeeeeeedeeeeceedeeecceedeccc5cedeecccccdcccecccc
-- 201:00000000000000000000000000ffffff0feeeeeeefedddddefedddddefeddddd
-- 202:ddddddddfffffffdeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeeddddddddd
-- 206:bbbbbebbaaaaaabbaaaaaabbaaaaaabbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
-- 207:bbdbbbdebbdbbbdebbdbbbdebbdbbbdeaaabbbdeaaabbbdeaaaaaaaeaaaaaaae
-- 208:effffffef555555ff5ffff5ff555555feff5fffeeef555feeef5ffeeeeef55fe
-- 209:22222222e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e222222222
-- 215:353535355cccccc33c5353c55c3535c33c5353c55c3535c33cccccc553535353
-- 217:ddddddddeeeeeeeeffffffffeeeeeeeedddddddddddddddddddddddddddddddd
-- 218:efddddddeffffffdeffeeeedeeffffffdeeeeeeeddddddddbbbbbbbbabbbbbbb
-- 219:ddddddfefffffffeeeeeeffeffffffeeeeeeeeedddddddddbbbbbbbbbbbbbbbb
-- 222:ddddddddfffffffde3e3eeed33eee3ed3333e3ed3333333d3333333d3333333d
-- 223:ddddddddbbbbbbbddbdbdbddbdbdbdbddbdbdbddbdbdbdbddbdbdbddbdbdbdbd
-- 224:eeffffeeeffc66feff4444fff434434ff444444ff443344fff4444ffeffffffe
-- 230:aaaaaaaaabbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaadbaaaaaadd
-- 231:aaaaaaaabbbbbbbaaaaaaabaaaeeeebaaaedddbaaaedddbadaedddbabaedddba
-- 237:ddddddddfffffffdf333333df333333df3333e3df3333e3df3e3333df3ee333d
-- 238:ddddddddfffffffdf333333df333333df333333df333333df333333df333333d
-- 239:bdbdbdbdefefefedeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeed
-- 240:eeeeeeeeeeffffeeef4444fef0444777f404474ff4444777f4444447f4f4f777
-- 241:00fffff00f555c3f0f575c3ff5575777f5c557cff3cf57770f3c53f700fff777
-- 246:aababadbaabbaaddaababadbaabbaaddaababadbaabbaaddaababadbaaaaaaaa
-- 247:daedddbabaedddbadaedddbabaedddbadaedddbabaedddbadaebbbbaaaaaaaaa
-- 248:eeeeeeeeeddddddbeddddddbeddddddbeddddddbeddddddbeddddddbbbbbbbbb
-- 249:00000000000000000000000000ffffff0ffeeeeeefedddddefebbbbbefebbbbb
-- 250:000000000000000000000000ffffff00eeeeeff0dddddefebbbbbefebbbbbefe
-- 251:0000000000000000000e000000efe000000e000000000000000000f000000000
-- 252:000000d000000ded000000d0000d0000000e00000defed00000e0000000d0000
-- 254:ddddddddfffffffd3333333d3333e3ed33eee3ede3e3eeedeeeeeeedeeee33ed
-- 255:ddddddddfffffffdeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeedeeeeeeed
-- </TILES>

-- <SPRITES>
-- 000:111fffff1ffffcccfffccccc1fccccccfccccc5cffc57755fcc7997a1ff79975
-- 001:ffff1111ccfcf111cccfff11ccccfcf15ccccf115775ccf17997fff17997f111
-- 002:11ffffff1fcffcccfffccccc1fccccccffcccc5cfccc7755ffc7997afcf79975
-- 003:fff11111cfffff11cccffcf1cccccff15ccccf11577ccff17997fcf17997ff11
-- 004:11ffffff1fcffcccfffccccc1fccccccffcccc5cfccc7755ffc7997afcf79975
-- 005:fff11111cfffff11cccffcf1cccccff15ccccf11577ccff17997fcf17997ff11
-- 006:11ffffff1fcffcccfffccccc1fccccccffcccc5cfccc7755ffc7997afcf79975
-- 007:fff11111cfffff11cccffcf1cccccff15ccccf11577ccff17997fcf17997ff11
-- 008:11ffffff1fcffcccfffccccc1fccccccffcccc5cfccc7755ffc7997afcf79975
-- 009:fff11111cfffff11cccffcf1cccccff15ccccf11577ccff17997fcf17997ff11
-- 016:11f5775511fe555c1f55ee551f55eeeb1feeeebb1fffeaaa11fffaaf11faafff
-- 017:5775f111c55f11115eeeff11beeeff11bbee5f11aae55f11faaf1111fffff111
-- 018:1ff57755111f555c1ffeee551f5eeeeb1f55eebb1fffeaaa11faafff111fffff
-- 019:5775f111c55f11115eeeff11eee55f11bee55f11aaeeff11faaf1111ffaaf111
-- 020:1ff57755111f555c1ffeee551f5eeeeb1f55eebb1fffeaaa11ffaaff11faafff
-- 021:5775f111c5555f115ee55f11eeeeff11beefff11aaeeff11faaf1111ffaaf111
-- 022:1ff57755111f555c1ffeee551f5eeeeb1f55eebb1fffeaaa11ffaaff11faafff
-- 023:5775f111c55fff115eee55f1eeee55f1beefff11aaeeff11faaf1111ffaaf111
-- 024:1ff57755111f555c1ffeee551f5eeeeb1f55eebb1fffeaaa11ffaaff11faafff
-- 025:5775f111c55fff115eefff11eee55f11bee55f11aaeeff11faaf1111ffaaf111
-- 064:11111111111111111111111f111111ff1111fff9111f7f9f111f77ff111fb77f
-- 065:1fff1111ff9f1111f9ff11119ff11111ff111111f11111111111111111111111
-- 066:111111111111111111111111111111111111111111111111111111f111111f71
-- 067:1111111111111111111111111111111111111111111111111111111111111111
-- 068:111111111111111111111111111111111111111111f111111fbf111111fbfff1
-- 069:1111111111111111111111111111111111111111111111111111111111111111
-- 080:11fbfff11fbf111111f111111111111111111111111111111111111111111111
-- 081:1111111111111111111111111111111111111111111111111111111111111111
-- 082:11fff7ff1fbbb77911fff7ff11111f71111111f1111111111111111111111111
-- 083:fffffff19999999ffffffff11111111111111111111111111111111111111111
-- 084:111fb77f111f77ff111f7f9f1111fff9111111ff1111111f1111111111111111
-- 085:1111111111111111f1111111ff1111119ff11111f9ff1111ff9f11111fff1111
-- 096:11aaaaaa1a00f77fa0000ff0a0000000a0000000a0000000a0000ff0a000f55f
-- 097:abbbba110f7f7fa100f0f7fa0000f7fa00ffff7a0f77f0faf7777f0af7777f0a
-- 098:11aaaaaa1a000000a0000fffa000f5ffa00fff00a00f0000a0f5f000a00f0000
-- 099:abbbba11ff0fffa15ff55f5aff5555fa0f5555fa0ff55ffa000fff0a0000000a
-- 100:00aaaaaa0a000000a0000000a0000000a0000000a000000fa00000ffa0000ff4
-- 101:abbbba0000ffffa000feeefa0ffeeefaff4eeefaf444fffa444ff00a44ff000a
-- 102:00aaaaaa0a000000a0000000a0000000a0000000a000000fa00000ffa0000ffe
-- 103:abbbba0000ffffa000feeefa0ffeeefaffeeeefafeeefffaeeeff00aeeff000a
-- 112:a00f5555a00f5555a00ff55fa0f5fff0a00f0000a0f5f0f01a0f0f5f11aaaaaa
-- 113:ff77f00af0ff000a0000000a0000000a0000000a0000000a000000a1aaaaaa11
-- 114:a0000000a0fff000aff77ff0af7777f0af7777ffa7f77ff71afff0ff11aaaaaa
-- 115:0000f00a000f7f0a0000f00a00fff00aff7f000afff0000a000000a1aaaaaa11
-- 116:a00fff44a0f44444af44444faf44444faf44444faf4444f0aaffff00aaaaaaaa
-- 117:4ff0000aff00000af000000a0000000a0000000a0000000a000000aaaaaaaaaa
-- 118:a00fff99a0f99999af99999faf99999faf99999faf9999f0aaffff00aaaaaaaa
-- 119:eff0000aff00000af000000a0000000a0000000a0000000a000000aaaaaaaaaa
-- 128:11aaaaaa1a00ff00a00f33f0a00fccf0a00fccffa00fcccca0fccc33afccc3c3
-- 129:bbbbba1100ff00a10f33f00a0fccf00affccf00accccf00a33cccf0acc3cccfa
-- 130:11aaaaaa1a00ff00a00f88f0a00f77f0a00f77ffa00f7777a0f77788af777878
-- 131:abbbba1100ff00a10f88f00a0f77f00aff77f00a7777f00a88777f0a778777fa
-- 144:afcc3cc3afcc3cc3afcc3cccafccc3ccafcccc33afcccccc1affffff11aaaaaa
-- 145:ccc3ccfa33c3ccfaccc3ccfacc3cccfa33ccccfaccccccfaffffffa1aaaaaa11
-- 146:af778778af778778af778777af777877af777788af7777771affffff11aaaaaa
-- 147:777877fa887877fa777877fa778777fa887777fa777777faffffffa1aaaaaa11
-- 160:0004440000440044040004440400cc4c004044ff0444cf0044cc4f004c004f00
-- 161:000000004004000044444400444cc440f4c4c4400fc4c4000f4444000f444400
-- 162:000000000004444000400044000004000000444f00044cf0044c44f0040c44f0
-- 163:00000000444000004040000044444400ff40040000f0004000f4044000f44000
-- 176:44c044ff044c044400040c4c000400c400440000440000000000000000000000
-- 177:fc4c4440444c4404c44444004c00040400404044044000000000000000000000
-- 178:0444444f0044c4440004cc440000444400400440004400000004000000044000
-- 179:ffc44440444cc444444c0004cc4c04400c040400000040000000400000000000
-- 192:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee9eeeeee99eeeeee98eeeee9e8
-- 193:eeeeeeeeeeeeeeeee9eeeeee9eeeeeee99eeeeee899eeeeeee9eeeee8e9eeeee
-- 194:eeeeeee9eeeee9eeeeeeeee9eeeeee99eeeeee99eeeee999eeeee998eeeee998
-- 195:9eeeeeee999eeeee9999eeee999e9eee999eeeee8999eeee8899eeee8899eeee
-- 196:eeeeeee9eeeeee99eeeee9e9eeeee999eeee9999eeeee999eee9e998eee99998
-- 197:eeeeeeeee99eeeee9ee9eeee999e9eee999eeeee899eeeee8899eeee8899eeee
-- 204:eeeeeeeeeeeeffeeeeef0feeeeef00feeeef00ffeeef000feeef000feeef0000
-- 205:eeeeeeeeeeeeeeeeeeeeeeeeeeffffffef000000f000ff00f000ff0000000000
-- 206:eeeeeeeeeeeeeeeeeeeeeeeefffffffe000000fe0099000f0099000000000000
-- 207:eeeeeeeeeeefeeeeeef0feeeef00feeeef00feeef000feee0000feee0000feee
-- 208:eeeee9e8eeeee9e8eeeee9e8eeeee9eeeeeee9eeeeeeee9eeeeeeee9eeeeeeee
-- 209:8eeeeeee8e9eeeee8e9eeeee889eeeee99eeeeeeeeeeeeee99eeeeeeeeeeeeee
-- 210:eeeee998eeeee998eee9e998eee9e999eeee9999eeee9e99eeee9ee9eeeee9ee
-- 211:8899eeee8899eeee8899eeee8899eeee999eeeee99eeeeee99eeeeeeeeeeeeee
-- 212:eeeee998eeeee998eeeee998eeeee998eeeee998eeeeee99eeeeeee9eeeee9e9
-- 213:8899eeee8899eeee8899eeee8899eeee899eeeee89e9eeee999eeeee99e9eeee
-- 220:eeeff000eeeeff00eeeeeff0eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeeef0
-- 221:0000000000006600000066000000000000000000000044000000440000000000
-- 222:000000000055000000550000000000000000000000ff000000ff000000000000
-- 223:000feeee000feeee00feeeee0feeeeee0feeeeee0feeeeee0feeeeee0feeeeee
-- 224:eeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff444444ff4f4f4fe
-- 225:eeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff444444fef4f4f4f
-- 226:eeeeeeeeeeeeeeeeeeffffeeef4444fef044440ff404404ff444444ff4f4ff4f
-- 236:eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeeef0
-- 237:0400000000400000000404000000444000000444000000440000000400000000
-- 238:0000004000000400004040004444000044400000440000004000000000000000
-- 239:0feeeeee0feeeeee0feeeeee0feeeeee0feeeeee0feeeeee0feeeeee0feeeeee
-- 240:00fffff00f555c3f0f575c3ff55755cff5c55ccff3cf5c3f0f3c53f000ffff00
-- 241:0000000000fffff00f555c3f0f57553ff5555cf0f5c55ccff33c533f0fff0ff0
-- 242:00fffff00f555c4f0f545c4ff55455cff5c55ccff4cf5c4f0f4c54f000ffff00
-- 252:eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeeef0eeeeef00eeeeffff
-- 253:00000000000000000000000000000000000000000000000000000000ffffffff
-- 254:00000000000000000000000000000000000000000000000000000000ffffffff
-- 255:0feeeeee0feeeeee0feeeeee0feeeeee0feeeeee00feeeee000feeeefffffeee
-- </SPRITES>

-- <MAP>
-- 000:00000040c2c2c2c241000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:000081a161f4f471a191000000000000000000000000000000bf00000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:0000a161f4f4f4f471a10000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c241000000000000000000a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f471a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:0000a1d390bf0080d3a100000000a161f4f4f4f4f4d3838383838383838383838383838371a1000000000000000000a1e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3f3e3e3e3e3e3e3e3f3f3e3e3e3e3e3e3e3e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:0000a1d3c5d4d4c6d3a100000000a1e3e3e3e3e3d3d3e3e3e3e3e3e3e3e3e3e3e3e3e39ae3a1c2c2c2c2c2c2410000a1e3e3e3b00000000000000000c0e3e3e3e3e3f3e3e3e3e3e3e3e3f3f3e3e3e3b00000c0e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:0000a1d373737273d3a100000000a1e3b0bfc0e3d3d3e3b000000000000000cfc0e3e39ae3f4f4f4f4f4f471a10000a1e3e3e300000000000000000000e3c1d1e3e3f3e3e3e3e3e3e3e3f3f3e32ae30000cf00e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:0000a1ffffffffffffa100000000a1e3b4d4c4e3d33ae300bf0000000000000000c1d09aa2e3f3e3e3e3e3e3a10000a1e3e3e3b4d4d4d4d4d4d4d4d4c4e3e3e3e3e3f3e3e3e3e3e3e3e3f3f3e3e3e3b4d4d4c4e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:0000c3ff58ffff58ffc300000000a1e362737373d31be3b4d4d4d4d4d4d4d4d4c4e3e39aa2e3f3b00000c0e3a10000a1fefefefefefe6308080808080808080808080808080808080808080863fefefefefefefea10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:0000c3ffffffffffffc300000000a17efefffffeff1bfefefea226fffffffefefefefefe1de3f30000cf00e3a10000a1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa60b0b0ba5a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:0000c3ffffffffffffc300000000a1ffffeeeeeeff1bffffff9292ffffffffffffffffff1de3f3b4d4d4c4e3a10000a1ff0effff0effffffffffffffffffffffffffffffffffffffffffffffffffff1bffffffffa10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000084e4e4e4e4e4e49400000000a1ffffeeeeeeff1bffffffffffffffffffffffffffff1dfefefefefefefea10000a1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1bff6e7effa10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000d5e5e5e5e5f50000000000a1ffffeeeeeeffa237ffffffffffffffffffffffffff1dffffffff0effffa10000a1ffffff0dffffffffffffffffffffffffffffffffffffffffffffffffffffff1bff6f7fffc30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:0000000000000000000000000000c3ffffff0dffffc3a28282828282828292ffffffffff1dffffffffffffffa10000c3ff0effff0effffffffffffffffffffffffffffffffffffffffffffffffffff1bffffffffc30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:0000000000000000000000000000c3ffffffffffffc3a2ff6363ffffffffffffffffffffa237ffffffffffffa10000c3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa60b0b0ba5c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000000bf000000bf000000000000c3e4e4e4e4e4e4c3a2ff1717ffffffffffffffffffffc3929292ffffffffa10000c3ffffffffffff630808080808080808080863a1ffffffa1630808080863ffffffffffffffc30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:0000000000000000000000000000d5e5e5e5e5e5e5f5a2ff1717ffffffffffffffffffffc326ffffffffffffc30000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4a1ffffffa1e4e4e4e4e4e4e4e4e4e4e4e4e4c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:00030000000000000000000000000000bf0000000000c3ff1717ffffffffffffffffffffc3ff0effffffffffc30000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5a1ffffffa1e5e5e5e5e5e5e5e5e5e5e5e5e5e50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:0000000044540000000000000000004e5e002e3e0000c3ff6363ffffffffffffffffffffc3ffffffffffffffc3000000000000000000000000000000000000000000a1ffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 018:00000000000000000000004e00000000000000000000c3e4e4e4e4a2ffffffffa2e4e4e4c3e4e4e4e4e4e4e4c30000000000000000000000000000000000000040c2a1ffffffa1c2410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 019:00000000000000000000000000000000000000000000d5e5e5e5e5a2ffffffffa2e5e5e5e5e5e5e5e5e5e5e5f500000000000000000000000000000000000000a1f4f4fffffff4f4a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 020:c8c8c8c8c8c8c8c8c8c8c8c8000000000000000000000000000000a2ffffffffa2000000000040c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2c2a1e3a60b0b0ba5e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 021:009940c2c2c2c2c2c2c2c2c2410000000040c2c2c2c2c2c2c2c2c2a2ffffffffa2c2c2c2c2c2a1f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a2f4f4f4f4f4e3f4fffffff4e3a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c9
-- 022:0040a1f4f4f4f4f4f49af4f4a100000000a1f4f4f4f4f4f4f4f4f4d3ffffffffd3f4f4f4f4f4d3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a2e3e3e3e3e3e3a60b0b0ba5e3a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 023:40a1d3d3e3e3e3e3e39ac1e0a1c2c2c2c2a1e3f3e3b0000000c0e3d3ffffffffd3e3e3e3e3e3d3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3a2e3e3e3e3e3ffffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 024:a1d3d3d3e3e3e3e3e39ae3e3d3f4f4f4f4d3e3f3e30000000000e3d3ffffffff2ce33ae3c1f0d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4a2f4f4f4f4f4ffffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 025:a1d3d3d3e3e3e3e3e39ae3e3d3e3e3e3e3d3e3f3e3b4d4d4d4c4e3d3ffffffffd3f41bf4f4f4d30dfefefefefefefefefefefefefefefefefefefea211fefefefeffffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 026:a1d3ffffffffffffffffffffd3e3e3e3e3d3fffffffffffffffffffffffffffffefe1bfefefefeffffffffffffffffffffffffffffffffffff0fffa211ffff0fffffffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 027:a1ff111111111111ffffffffd3e3e3e3e3d3ffffffffffffffffffffffffffffffff1bffffffffffffffff0fff1111ffffffffffffffffffffffffa211ffffffffffffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 028:a1ff110effffff11ff0fffffffff09ff09ffffff1d1d1dffffffffffffffffffffff1bffffffffffffffffffff1111ffffffff0fffffffffffffffa211ffffffffffffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 029:a1ff11ffff0dff11ffffffffffffff0909ffffff1d0f1dffffffffffffffffffff70a1a1a1a160ffffffffffff1111ffffffff11111111ffffffffd311ffffffffa2ffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 030:a1ff11ffffffff11ffffffffffff090909ffffff1d1d1dffffffffffffffffffffa1b2b2b2b2a1ffffffffffff1111ffffffff11111111ffffffffd311ffffffffa2ffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 031:c3ff110effffff11ff0fffffffffff0909ffffffffffffffffffffff6308080863a1b1b1b1b1a1ffffffffffffffffffffffffffffffffffffffffd311ffffffffa2ffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 032:c3ff111111111111ffffff85e4e4e4e4e4e495ffffffffffffffffff1dffffffffc3b1b1b1b1c3ffffffffffffffffffffffffffffffffffffffffffffffffffffc3ffffffffffffc300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 033:c3e4ffffffffffffffffffb5e5e5e5e5e5e5b6ffffffffffffffffff1dff1f0effc3e5e5e5e5c3111111111111111111111111111111ffffffffffffff0fffffffc3ffffffffffffc300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9
-- 034:d5e5e4ffffffffffffffffb5000000000000b6ffffffffffffffffff1dffffffffc300000000c3111111111111111111111111111111ffffffffffffffffffffffc3ffffff0dffffc30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:0000d5e4e4e4e4e4e4e4e4e4000000000000e4e4e4e4e4e4e4e4e4e4e4e4e4e4f6c300000000c3e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4c3e4e4e4e4e4e4c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:000000d5e5e5e5e5e5e5e5f5000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f500000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2410000000000000040c2c2c2c2c2c2410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040c2c2a1d3e3e3e3e3d3a1c2c2410040c2c2a1d3f4f4f4f4d3a1c2c2410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:0000000000000000000000000000000000000000000000000000000000000000000000000000000040c2c2c2c24100000000000000000000000000a1e3e3d3d3e3e3e3e3d3d3e3e3a100a1e3e3d3d3e3e3e3e3d3d3e3e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:0000000000000000000000000000000000000000000000000000000000000040c2c2c2c2c2c2c2c2a1f4f4f4f4a1c2c24100000000000000000000a1e3e3d3d3e3e3e3e3d3d3e3e3a100a1e3e3d3d3e3e3e3e3d3d3e3e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:0000000000000000000000000000000040c2c2c2c2c2c24100000000000000a1f4f4f4f4f4f4f4f4f4d3e3e3d3f4f4f4a100000000000000000000a1e3e3d3b2ffff0effb2d3e3e3a100a1e3e3d3b2ffff0effb2d3e3e3a10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:00000000000040c2c2c2c2c2c2c2c2c2a1f4f4f4f4f4f4a1c2c2c2c2c2c2c2a1d3e3e3e3e3e3e3e3d3d3e3e3d3d3e3e3a100000000000000000040a1ffffffeeedeeeeeeeeffffffa1c2a1ffffffeeedeeeeeeeeffffffa10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000a1f4f4f4f4f4f4f4f4f4d3d3e3e3e3e3d3d3f4f4f4f4f4f4f4f4d3e3e32ae33ae3e3d3d3e3e3d3d3e3e3a1c2c2c2c2c2c2c2c2c2a1d3ffffffeeedeeeeeeeeffffffd3a1d3ffffffeeedeeeeeeeeffffffa1c200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000a1d3d3e3e3e3e3e3e3e3d3d3e3e3e3e3d3d3e3b0000000c0e3d3d3e3e3e3e31be3e3d3ff2affffd3e3e3d3d3d3e3e3e3e3e3e3e3d3d3ffffffd8e8e8e8e8f8ffffffd3d3d3ffffffd8e8e8e8e8f8fffffff4a1c2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:40c2c2c2c2c2a1d3d3e3e3e3c1e1e3e3d3d3e3e3e3e3d3d3e30000000000e3d3ffffffffff1bffffeeffffffffff0fffd3d3d3e3e3e3e3e3e3e3d3d3ffffffd911111111f9ffffffd3d3d3ffffffd911111111f9ffffffd3f4a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:a1f4f4f4f4f4f4d3d3e3e393e3e3e3e3d3ffff0dffffa2d3e3b4d4d4d4c4e3d3ffffffffff1bffffeeffffffff0fffffd3d3d3e3e3e32ae3e3e3d3d3ffffffdaf71111e7faffffffd3d3d3ffffffdaf71111e7faffffffd3d3a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:a1e3e3e3e3e3e3ffffffffa20fff0fd8e8f80fffff0fa2ffff0fff0fffd8e8f8ffffffffff1bffffefffffffff0fffffd3d3d3e3e3e3e3e3e3e3d3ffffffffffdaeaeafaffffffffffd3ffffffffffdaeaeafaffffffffd3d3a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:a1e3e3e3e3e3e3ffffffff92ff0fffd911f9ff0f0fff92ff0fff0fff0fd911f9ffffffa2a2a2a2a2a2deeeded8e8e8f8ffffffffffffffffffffffffffff0fffffeeeeffff0fffffffffffffff0fffffeeeeffff0fffffffd3a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:a1e3e3e3e3e3e3ff0fffffdeffffffd911f9ffffffffeeffffffffffffd911f9ffffffe3e3d3a2d3d3deeeded91111f9ffffffffffffffffffffffffff0f0f0fffeeeeff0f0f0fffffffffff0f0f0fffeeeeff0f0f0fffff0da1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:a1ebfbffffffffffffffffeeffffffd911f9ffffffffdeffffffffffffd911f9ffffffe3e3d3a2d3d3ffffffdaeaeafaffffffffffffffffffffffffffff0fffffefefffff0fffffd8e8f8ffff0fffffeeeeffff0fffffffffa1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:a1ecfcffffffffffffffffeeffffffd911f9ffffffffeeffffffffffffdaeafaffffffd8e8f8a20fffffffffffeeeeffff85a2a295ffffff85e495ffffffffff85e4e495ffffffd8c711d7f8ffffff85e4e495ffffffffffffc300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a19100000000000000000000000000000000000000000000000000000000000000000000
-- 052:a1ffffffffffffffffffffeeffffffd911f9ffffffffeeffffffffffffffdeffffffffd911f9a2ff0fffffffffeeeeffffb5a2a2a60b0b0ba5e5e6ffffffff85f6e5e5e695ffffd9111111f9ffff85f6e5e5e695ffffff85e4c3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1618383838383a183838383838383a1838383838371a100000000000000000000000000000000000000000000000000000000000000000000
-- 053:a1ffffffffffffffffffffefffffffdaeafaffffffffeeffffffffffffffeeffffffffd911f9a2ff0fffffffffeeeeffffb5a2a2b6ffffffb500d5e6e4e4e4f6f50000d5b6ffffdaf711e7faffffb5f50000d5e6e4e4e4f6e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1e3b00000c0f3a1f3b0000000c0f3a1f3b00000c0e3a100000000000000000000000000000000000000000000000000000000000000000000
-- 054:a1ffffffffffffffffffd8e8f8ffffffdeffffffffd8e8f8ffffffffffffdeffffffffd911f9a20fffffffffd8e8e8f8ffb5a2a2b6ffffffb50000d5e5e5e5f50000009cb6ffffffdaeafaffffffb59b000000d5e5e5e5f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1e323330000f3a1f30003130000f3a1f300435300e3a100000000000000000000000000000000000000000000000000000000000000000000
-- 055:c3ffffffffffffffffffd911f9ffffffeeffffffffd911f9ffffffffffffeeffffffffd911f9a2ffffd62affd91111f90fb5a2a2b6ffffffb500000000000000000000b6ffffffffffffffffffffffb500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1ffffffffffffa1ffffffffffffffa1ffffffffffffa100000000000000000000000000000000000000000000000000000000000000000000
-- 056:c3ffffffffffffff0fffd911f9ffffffdeffffffffd911f9ffffffffffd8e8f8ffffffdaeafaa2a2d6d6ffffdaeaeafaffb5a2a2b6ffffffb500000000000000000000b6ff0fffffffffffffff0fffb500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1ffffffffffffa1ffffffffffffffa1ffffffffffffa1c8000000000000000000000000000000000000000000000000000000000000000000
-- 057:c3e4e4e4e4e4e495ffffd911f9ffffffeeffffffffd911f9ffffffffffd911f9a292828282828282828282828282828282829292b6ffffffb500000000000000000000e6e4e4e495ff0fff85e4e4e4f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1ffffffffffffd3ffffffffffffffd3ffffffffffffa1c9000000000000000000000000000000000000000000000000000000000000000000
-- 058:d5e5e5e5e5e5e5b6ffffd911f9ff0fffa2ff0f0fffd911f90fff0fff0fd911f9a2d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d3d3b6ffffffb500000000000000000000d5e5e5e5b6ff0effb5e5e5e5f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a10c0d0d0d0d1c2c0c0d0d0d0d0d1c2c0c0d0d0d0d1ca1a9000000000000000000000000000000000000000000000000000000000000000000
-- 059:00000000000000b6ffffdaeafa0fff0fa30fffff0fdaeafaff0fff0fffd911f9a2d3f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d3d3b6ffffffb50000000000000000000000000000b60fff0fb50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1ffffffffffffd3ffffffffffffffd3ffffffffffffa1a9000000000000000000000000000000000000000000000000000000000000000000
-- 060:00000000000000e6e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e495daeafac30eff0eeeeeeeedeeeeeeeeeeeeeeeeeeeedeeeffffffffb50000000000000000000000000000e6e4e4e4f60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1ffffffffffffffffffffffffffffffffffffffffffa1a9000000000000000000000000000000000000000000000000000000000000000000
-- 061:00000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e6e4e4e4c3ff0effeeeeeeeeeeeedeeeeeeeeeeedeeeeeefffffffffb50000000000000000000000000000d5e5e5e5f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a1ffffffffffffffffff79ffff79ffffffffffffffffa1a9000000000000000000000000000000000000000000000000000000000000000000
-- 062:00000000000000000000000000000000000000000000000000000000d5e5e5e5c30eff0eeeeeeeeeeeeedeeeeeeeeeeedeeeeeefffffffffb5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a160ffffffffffffffffff0e1effffffffffffffff70a1a9000000000000000000000000000000000000000000000000000000000000000000
-- 063:0000000000000000000000000000000000000000000000000000000000000000b1e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050a1a1a1a1a1a160ffffff0f1fffff70a1a1a1a1a1a151a9000000000000000000000000000000000000000000000000000000000000000000
-- 064:0000000000000000000000000000000000000000000000000000000000000000d5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3c3b1b1b1b1b1c3ffffffffffffffc3b1b1b1b1b1c3c300000000000000000000000000000000000000000000000000000000000000000000
-- 065:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3c3b1b1b1b1b1c3ffffffffffffffc3b1b1b1b1b1c3c300000000000000000000000000000000000000000000000000000000000000000000
-- 066:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b3b2b2b2b2b2c3e4e4e4e4e4e4e4c3b2b2b2b2b2b39400000000000000000000000000000000000000000000000000000000000000000000
-- 069:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 070:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 071:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 072:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 073:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 074:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 075:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 076:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 077:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 078:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8fe4e4e4e4e4e48f8f8fe4e4e4e4e4e40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 079:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 080:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c8c80000008f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 081:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e38f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 082:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e3e38f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 083:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000000c0e3e3e3e3e3e3e3e3e3e3e3e3e3e3b00000000000c0e3e3e3e3e38f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 084:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3e3e3e3e3e3e3e3e3e3e3e3e3e300000000000000e3e3e3e3e38f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 085:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b4d4d4d4d4d4c4e3e3e3e3e3e3e3e3e3e3e3e3e3e3b4d4d4d4d4d4c4e3e3e3e3e38f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 086:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fdfdfdfdfffffffffdfdfdfdfdfdfdfdfdfdfdfdfdfdfd8bfdfdfdfd8afd8afdfd8f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 087:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffffffffdfdfdfdffffffffffffffffffff8b8aff8bff8b8a8a8b8b8a8f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 088:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffff8c8d8bff8a8a8d8a8b8b8c8a8b8a8f8f8f8f8f8f8f8f8f8f9797979797978f8f8f9797979797970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 089:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffffffffffdfdfdfdfffffffdfdfdfdfdfdfdfdfdfdfd8dfdfdfdfd8c8a8afdfd8f8f8f8f8f8f8f8f8f8fe4e4e4e4e4e48f8f8fe4e4e4e4e4e40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 090:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e48f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 091:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 092:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 093:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 094:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 095:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 096:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 097:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 098:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 099:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 100:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 120:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf00000000000000000000bf00000000000000000000000000000000000000000000bf0000000000000000000000000000000000000000000000000000000000000000000000
-- 121:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 122:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf000000000000000000000000000000000000000000000000000000cf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 123:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf0000000000000000cf00000000000000000000000000000000000000000000000000000000000000000000000000
-- 125:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 126:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 127:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cf000000000000000000000000000000bf00000000000000000000000000bf00000000000000000000000000cf000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 128:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf0000000000000000000000000000000000000000000000000000000000000000000000
-- 129:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 130:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 131:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf000000000000000000000000000000000000000000000000cf000000000000000000000000000000bf0000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 132:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 133:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cf00000000000000000000000000bf0000000000000000000000000000000000000000000000000000000000000000cf00000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:100c1ce234c6595971deca69c23830ce89408dc24414304885b6d271aaca5d65717d8d95994c409daaaac6d2cadeeed6
-- </PALETTE>

