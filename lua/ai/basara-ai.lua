--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  Mogara
*********************************************************************]]
--[[旧珠联璧合等
sgs.ai_skill_choice.halfmaxhp = function(self, choice, data)
	if self.player:hasSkill("hengzheng") and self.player:getHp() == 1 and sgs.ai_skill_invoke.hengzheng(sgs.ais[self.player:objectName()]) then
		return "draw"
	end
	if self:needKongcheng(self.player, true) and self.player:getPhase() ~= sgs.Player_Play then return "cancel" end
	return "draw"
end

sgs.ai_skill_invoke["userdefine:changetolord"] = function(self)
	--local kingdom = self.player:getActualGeneral1():getKingdom()
	local lord_name = "lord_" .. self.player:getActualGeneral1():objectName()
	local lord_general = sgs.Sanguosha:getGeneral(lord_name)
	local general = self.player:getActualGeneral2()
	
	if general:hasSkill("jizhi") then return true end
	if general:hasSkill("beige") then return true end
	if general:hasSkill("shuangxiong") then return true end
	if general:hasSkill("luanji") then return true end
	if lord_general:hasSkill("shouyue") and general:hasSkill("longdan") then return true end
	return math.random() < 0.8
end

sgs.ai_skill_choice.companion = function(self, choice, data)
	if self.player:hasSkill("hengzheng") then
		local value = 0
		for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			value = value + self:getGuixinValue(target)
		end
		if value >= 1.3 then
			if (self.player:isKongcheng() or self.player:getHp() == 0) 
				and string.find(choice, "recover") then
				return "recover"
			elseif self.player:getHp() == 1 and string.find(choice, "draw") then
				return "draw"
			end
		end
	end
	
	if (self.player:getPhase() <= sgs.Player_Play and self.player:isSkipped(sgs.Player_Play))
		or (self.player:containsTrick("indulgence") and not self:hasWizard(self.friends)) then
		if string.find(choice, "recover") and not self.player:hasSkills("qiaobian|keji") then return "recover" end
	elseif (self.player:getPhase() <= sgs.Player_Play and not self.player:isSkipped(sgs.Player_Play)) then
		local taihou = sgs.findPlayerByShownSkillName("zhendu")
		if taihou and taihou:isAlive() and taihou:getHandcardNum() > 0 and not self.player:isFriendWith(taihou)
			and self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0
			and not hasNiepanEffect(self.player) and not hasBuquEffect(self.player) then
			if string.find(choice, "recover") then return "recover" end
		end
	end
	
	if (self.player:hasSkills(sgs.cardneed_skill) or self.player:hasSkills(sgs.recover_skill)
		or hasNiepanEffect(self.player) or hasBuquEffect(self.player))and string.find(choice, "draw") then
		return "draw"
	end
	
	if (self:isWeak() or self:needKongcheng(self.player, true)) and string.find(choice, "recover") then return "recover"
	else return "draw" end
end

sgs.ai_skill_choice.firstshow = function(self, choice, data)
	if self.room:getMode() == "jiange_defense" then return "cancel" end
	return "draw"
end
]]--

sgs.ai_skill_choice.heg_nullification = function(self, choice, data)
	local effect = data:toCardEffect()
	if effect.card:isKindOf("AOE") or effect.card:isKindOf("GlobalEffect") then
		if self:isFriendWith(effect.to) then return "all"
		elseif self:isFriend(effect.to) then return "single"
		elseif self:isEnemy(effect.to) then return "all"
		end
	end
	local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. effect.card:toString()):toList()
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
	end
	if effect.card:isKindOf("FightTogether") then
		local ed, no = 0,0
		for _, p in sgs.qlist(targets) do
			if p:objectName() ~= targets:at(0):objectName() and p:isChained() then
				ed = ed + 1
			end
			if p:objectName() ~= targets:at(0):objectName() and not p:isChained() then
				no = no + 1
			end
		end
		if targets:at(0):isChained() then
			if no > ed then return "single" end
		else
			if ed > no then return "single" end
		end
	end
	return "all"
end

sgs.ai_skill_choice["GameRule:TriggerOrder"] = function(self, choices, data)--技能触发顺序
	Global_room:writeToConsole("多技能触发选择:" .. choices)
	--Global_room:writeToConsole("多技能触发data:" .. data:type())--swig没有该方法
	--当锁定技和普通触发技同时触发选择时(从谏+制蛮)(恃才+节命),点击托管会跳过锁定技的效果(从谏伤害+1),即没有额外伤害
	local skillTrigger = false
	local skillnames = choices:split("+")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowHead")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowDeputy")
	if #skillnames > 1 then
		table.removeOne(skillnames, "cancel")
		skillTrigger = true
	end

	if skillTrigger then
		if string.find(choices, "keshou") and string.find(choices, "tianxiang") then--恪守、天香
			return "keshou"
		end

		if string.find(choices, "yuanyu") and string.find(choices, "tianxiang") then--远域、天香
			local dmgStr = {damage = 1, nature = damage_nature or sgs.DamageStruct_Normal}
			local willTianxiang = sgs.ai_skill_use["@@tianxiang"](self, dmgStr, sgs.Card_MethodDiscard)
			if willTianxiang ~= "." then return "tianxiang" end
			return "yuanyu"
		end

		if string.find(choices, "wanggui") and not self.player:hasShownAllGenerals() then--华韵打伤害或摸牌
			if #self.enemies > 0 then
				self:sort(self.enemies, "hp")
				local attack_priority = (self.player:getPlayerNumWithSameKingdom("AI") < (self:isWeak() and 2 or 3))
				for _, p in ipairs(self.enemies) do
					if self:isWeak(p) or (self:canAttack(p) and attack_priority) then
						Global_room:writeToConsole("望归优先")
						return "wanggui"
					end
				end
			end
		end

		if string.find(choices, "shangshi") then return "shangshi" end--伤势弃牌
		if string.find(choices, "sidi") then--司敌放置牌
			if string.find(choices, "ziliang") then
				local drive = self.player:getPile("drive"):length()
				if drive > 1 and drive <= 3 then
					return "ziliang"
				end
			end
			local damage = data:toDamage()
			if not (damage.to and damage.to:isNude()) then
				return "sidi" 
			end
		end
		if string.find(choices, "shicai") then--卖血技能先恃才弃牌
			local damage = data:toDamage()
			if damage.damage > 1 then
				if string.find(choices, "beige") then
					return "beige"
				end
				if string.find(choices, "qianhuan") then
					return "qianhuan"
				end
				if string.find(choices, "fudi") then
					return "fudi"
				end
				--新技能只弃2，考虑手牌质量与其他买血摸牌技能先后？
				return "shicai"
			end
		end
		
		if string.find(choices, "benyu") then
			local damage = data:toDamage()
			--local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
			if damage.from and (self:isFriend(damage.from) or not self:canAttack(damage.from)
				or not self:damageIsEffective(damage.from, sgs.DamageStruct_Normal, self.player)) then--贲育队友时先贲育
				return "benyu"
			elseif damage.from and self:isEnemy(damage.from) then
				if (self:canAttack(damage.from) and self:damageIsEffective(damage.from, sgs.DamageStruct_Normal, self.player)) and damage.from:getHandcardNum() <= 2 then--贲育能打伤害时
					if self.player:getHandcardNum() > damage.from:getHandcardNum() then--贲育牌多
						--如果贲育+节命能打伤害且摸2
						if string.find(choices, "jieming") and (self.player:getHandcardNum() + 1 - damage.from:getHandcardNum()) <= math.min(self.player:getMaxHp(), 5) - 2 then
							return "benyu"
						end
					end
					--牌不够暂不贲育
				elseif damage.from:getHandcardNum() > self.player:getHandcardNum() then--贲育不能打伤害时先贲育摸牌
					return "benyu"
				end
			end
		end
		if string.find(choices, "jieming") then return "jieming" end--先发动节命
		
		if string.find(choices, "zhiyu") then
			local from = data:toDamage().from
			if from and from:getHandcardNum() == 1 and from:getCardCount(true) == 1 and string.find(choices, "fankui") then--唯一手牌智愚反馈选择
				if self:isWeak() and self:getCardsNum("Peach") == 0 then return "zhiyu" end--一般反馈不到桃
				return "fankui"
			end
			return "zhiyu"--先发动智愚亮牌
		end
		if string.find(choices, "wangxi") and string.find(choices, "fankui") then
			local from = data:toDamage().from
			if from and from:isNude() then return "wangxi" end
		end
		if string.find(choices, "fankui") and string.find(choices, "ganglie") then return "fankui" end
		if string.find(choices, "wangxi") and string.find(choices, "ganglie") then return "wangxi" end
		if string.find(choices, "wangxi") and string.find(choices, "fangzhu") then return "fangzhu" end
		if string.find(choices, "yiji") then return "yiji" end

		if string.find(choices, "tiandu") then
			local judge = data:toJudge()
			if judge.card:isKindOf("Peach") or judge.card:isKindOf("Analeptic") then
				return "tiandu"
			end
		end

		if string.find(choices, "zhiman") then return "zhiman" end--造成伤害先考虑制蛮
		if string.find(choices, "chuanxin") then return "chuanxin" end
		
		--最后考虑暗涌
		if string.find(choices, "anyong") then--暗涌后翻倍
			for _, name in ipairs(skillnames) do
				if name ~= "anyong" then
					return name
				end
			end
		end

		if string.find(choices, "luoshen") and string.find(choices, "guanxing") then return "guanxing" end
		if string.find(choices, "qianxi") and sgs.ai_skill_invoke.qianxi(sgs.ais[self.player:objectName()]) then return "qianxi" end
		if string.find(choices, "luatianyi") then return "luatianyi" end
		if string.find(choices, "luoshen") then return "luoshen" end--洛神
		if string.find(choices, "jieyue") then return "jieyue" end--节钺
		if string.find(choices, "elitegeneralflag") then return "elitegeneralflag" end--五子良将纛可以暗求安函防掉血

		if string.find(choices, "wuxin") then return "wuxin" end--悟心
		if string.find(choices, "haoshi") then return "haoshi" end
		if string.find(choices, "zisui") then return "zisui" end--公孙渊摸牌，可能就配合和张辽会触发

		if table.contains(choices, "tieqi") and table.contains(choices, "liegong") then--能否和多目标杀区分？
			return "tieqi"
		end
		if table.contains(choices, "wanglie") and table.contains(choices, "liegong") then
			return "wanglie"
		end
		if table.contains(choices, "kuangfu") and table.contains(choices, "jianchu") then--先获得，详细判断？
			return "kuangfu"
		end
		if table.contains(choices, "jianchu") and table.contains(choices, "moukui") then
			return "jianchu"
		end
		if table.contains(choices, "kuangfu") and table.contains(choices, "moukui") then
			return "kuangfu"
		end

		if string.find(choices, "tieqi") or string.find(choices, "liegong")--有_xh等后缀也会find到
		or string.find(choices, "jianchu") or string.find(choices, "wushuang")
		or string.find(choices, "moukui") or string.find(choices, "DragonPhoenix") then
			Global_room:writeToConsole("杀类技能多目标选择:" .. skillnames[1])
			return skillnames[1]--杀类技能多目标选择
		end

--[[同时触发的函数不一定是askForSkillInvoke
		local except = {}
		for _, skillname in ipairs(skillnames) do
			local invoke = self:askForSkillInvoke(skillname, data)--data和invoke的data不一致？？
			if invoke == true then
				return skillname
			elseif invoke == false then
				table.insert(except, skillname)
			end
		end
		table.removeTable(skillnames, except)
]]
		if string.find(choices, "niepan") and string.find(choices, "jizhao") then
			local my_value = 0
			for _, card in sgs.qlist(self.player:getHandcards()) do
				if self.player:getPhase() <= sgs.Player_Play then
					my_value = my_value + self:getUseValue(card)
				else
					my_value = my_value + self:getKeepValue(card)
				end
			end
			for _, equip in sgs.qlist(self.player:getEquips()) do
				my_value = my_value + self:getKeepValue(equip)
			end
			local niepan_value = math.max(3 + self:getLeastHandcardNum() - my_value/4, 0)
			if self:needToThrowArmor() then niepan_value = niepan_value + 2 end
			if not self.player:faceUp() then niepan_value = niepan_value + 3 end
			local jizhao_value = math.max(self.player:getMaxHp()-self.player:getHandcardNum(), 0)
			local fazheng = sgs.findPlayerByShownSkillName("xuanhuo")
			if fazheng and self.player:isFriendWith(fazheng) and self.player:getPlayerNumWithSameKingdom("AI") > 1 then
				jizhao_value = jizhao_value - math.min(3, 2*(self.player:getPlayerNumWithSameKingdom("AI")-1))
			else
				for _, friend in ipairs(self.friends) do
					if not self.player:isFriendWith(friend) then continue end
					if friend:hasShownSkills("wusheng|paoxiao|longdan|tieqi|liegong") then
						jizhao_value= jizhao_value - 2
					end
				end
			end
			if jizhao_value >= niepan_value then return "jizhao" end
			return "niepan"
		end
		
		if string.find(choices, "lianpian") and string.find(choices, "jubao") then return "lianpian" end--先联翩(再聚宝)
		
		if string.find(choices, "mouduan") then
			if string.find(choices, "jubao") then return "jubao" end--先聚宝再谋断
			return "mouduan"
		end
		if string.find(choices, "fenming") then return "fenming" end--奋命
		if string.find(choices, "fenji") then--先奋激(再聚宝)
			if string.find(choices, "lianpian") and #self.friends_noself == 0 then return "lianpian" end--先联翩
			return "fenji"
		end
		
		if string.find(choices, "zhendu") and string.find(choices, "daming") then
			local current = self.room:getCurrent()
			if self:isWeak(current) and current:getHp() <= 1 then return "daming" end
			return "zhendu"--除非队友残血,否则鸩毒达命打一套(达命鸩毒骗闪暂不考虑)
		end
		
		if string.find(choices, "lirang") then return "lirang" end--先礼让,防止触发洗牌
		
		if #skillnames > 0 then return skillnames[math.random(1, #skillnames)] end
	end

	skillnames = choices:split("+")
	return skillnames[math.random(1, #skillnames)]
end

sgs.ai_skill_choice["GameRule:TurnStart"] = function(self, choices, data)--旧的亮将已失效
	--[[
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")
	local choice = sgs.ai_skill_choice["GameRule:TriggerOrder"](self, choices, data)]]
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")

	local firstShow = ("luanji|qianhuan"):split("|")
	local bothShow = ("luanji+shuangxiong|luanji+huoshui|huoji+jizhi|luoshen+fangzhu|guanxing+jizhi"):split("|")
	local followShow = ("qianhuan|duoshi|rende|cunsi|jieyin|xiongyi|shouyue|hongfa"):split("|")

	local notshown, shown, allshown, f, Wbf, e, eAtt, eMax = 0, 0, 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self.player:willBeFriendWith(p) then
				Wbf = Wbf + 1
			elseif p:getPlayerNumWithSameKingdom("AI") > eMax then
				eMax = p:getPlayerNumWithSameKingdom("AI")
			end
			if self:evaluateKingdom(p) == self.player:getKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
		if p:hasShownAllGenerals() then
			allshown = allshown + 1
		end
	end
	
	local show_position = self:getGeneralShowOrHide(self.player,(string.find(choices, "cancel") and true or false),true)
	if not show_position then return "cancel"
	elseif show_position:split("+")[1] == "head" then return "GameRule_AskForGeneralShowHead"
	elseif show_position:split("+")[1] == "deputy" then return "GameRule_AskForGeneralShowDeputy" end
	
	local showRate = math.random() + shown/20

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end

	if (firstShowReward or self:willShowForAttack()) and not self:willSkipPlayPhase() then
		for _, skill in ipairs(bothShow) do
			if self.player:hasSkills(skill) then
				if canShowHead and showRate > 0.7 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.7 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
	end

	if firstShowReward and not self:willSkipPlayPhase() then
		for _, skill in ipairs(firstShow) do
			if self.player:hasSkill(skill) and not self.player:hasShownOneGeneral() then
				if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.8 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.8 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
		if not self.player:hasShownOneGeneral() then
			if canShowHead and showRate > 0.9 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.9 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:inHeadSkills("baoling") then
		if (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") ~= 0)
		or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") ~= 0)
		or (self.player:hasSkill("yaowu") and not self.player:hasShownGeneral2()) then
			canShowHead = nil
		end
	end
	if self.player:inHeadSkills("baoling") then
		if (self.player:hasSkill("mingshi") and allshown >= (self.room:alivePlayerCount() - 1))
			or (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") == 0)
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") == 0) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			end
		end
	end

	if self.player:hasSkill("guixiu") and not self.player:hasShownSkill("guixiu") then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase() ) then
			if self.player:inHeadSkills("guixiu") and canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _,p in ipairs(self.friends) do
		if p:hasShownSkill("jieyin") then
			if canShowHead and self.player:getGeneral():isMale() then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and self.player:getGeneral():isFemale() and self.player:getGeneral2():isMale() then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("CompanionEffect") > 0 then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase()) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("HalfMaxHpLeft") > 0 then
		if self:isWeak() and self:willShowForDefence() then
			if canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate >0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:hasTreasure("JadeSeal") then
		if not self.player:hasShownOneGeneral() then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _, skill in ipairs(followShow) do
		if ((shown > 0 and e < notshown) or self.player:hasShownOneGeneral()) and self.player:hasSkill(skill) then
			if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end
	for _, skill in ipairs(followShow) do
		if not self.player:hasShownOneGeneral() then
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasShownSkill(skill) and p:getKingdom() == self.player:getKingdom() then
					if canShowHead and canShowDeputy and showRate > 0.2 then
						local cho = { "GameRule_AskForGeneralShowHead", "GameRule_AskForGeneralShowDeputy"}
						return cho[math.random(1, #cho)]
					elseif canShowHead and showRate > 0.2 then
						return "GameRule_AskForGeneralShowHead"
					elseif canShowDeputy and showRate > 0.2 then
						return "GameRule_AskForGeneralShowDeputy"
					end
				end
			end
		end
	end

	--if choice == "cancel" then
		local showRate2 = math.random()

		if canShowHead and showRate2 > 0.8 then
			if self.player:isDuanchang() then return "GameRule_AskForGeneralShowHead" end
			for _, p in ipairs(self.enemies) do
				if p:hasShownSkills("mingshi|huoshui") then return "GameRule_AskForGeneralShowHead" end
			end
		elseif canShowDeputy and showRate2 > 0.8 then
			if self.player:isDuanchang() then return "GameRule_AskForGeneralShowDeputy" end
			for _, p in ipairs(self.enemies) do
				if p:hasShownSkills("mingshi|huoshui") then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
		if not self.player:hasShownOneGeneral() then
			local taihou = sgs.findPlayerByShownSkillName("zhendu")--亮将防队友鸩毒或者求队友桃
			local zhendu = (taihou and taihou:isAlive() and taihou:getHandcardNum() > 0 and self.player:getHp() <= 1)
			local huangzu = sgs.findPlayerByShownSkillName("xishe")--亮将防队友袭射或者求队友桃
			local xishe = (huangzu and huangzu:isAlive() and self.player:getHp() <= huangzu:getEquips():length())
			if self:isWeak() and (zhendu or xishe)
				and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then
				if canShowDeputy then return "GameRule_AskForGeneralShowDeputy"
				elseif canShowHead then return "GameRule_AskForGeneralShowHead" end
			end
			--local gameProcess = sgs.gameProcess():split(">>") self.player:getKingdom() == gameProcess[1]
			if string.find(sgs.gameProcess(), self.player:getKingdom() .. ">>") and (self.player:getLord() or sgs.shown_kingdom[self.player:getKingdom()] < self.player:aliveCount() / 2) then
				if canShowHead and showRate2 > 0.6 then return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate2 > 0.6 then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
	--end
	if Wbf >= e or Wbf + 1 >= math.floor((shown + notshown)/2) or eMax >= math.floor((shown + notshown)/2) then--大优大劣亮将
		local cn = sgs.cardneed_skill:split("|")
		for _, skill in ipairs(cn) do
			if self.player:hasSkill(skill) then
				if canShowDeputy then return "GameRule_AskForGeneralShowDeputy"
				elseif canShowHead then return "GameRule_AskForGeneralShowHead" end
			end
		end
	end
	--return choice
	return  "cancel"
end

sgs.ai_skill_choice["armorskill"] = function(self, choice, data)
	local choices = choice:split("+")
	for _, name in ipairs(choices) do
		local skill_names = name:split(":")
		if #skill_names == 2 then
			if self:askForSkillInvoke(skill_names[2], data) then return name end
		end
	end
	return "cancel"
end
--[[
sgs.ai_skill_invoke.GameRule_AskForArraySummon = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end
--]]
sgs.ai_skill_choice.GameRule_AskForArraySummon = function(self, choices)
	local canShowHead = string.find(choices, "show_head_general")
	local canShowDeputy = string.find(choices, "show_deputy_general")
	local canShowBoth = string.find(choices, "show_both_generals")
	local choice = sgs.ai_skill_choice.GameRule_AskForGeneralShow(self, choices)
	if choice ~= "cancel" then return choice end
	return choices[1]
end

sgs.ai_skill_invoke.SiegeSummon = true
sgs.ai_skill_invoke["SiegeSummon!"] = false

sgs.ai_skill_invoke.FormationSummon = true
sgs.ai_skill_invoke["FormationSummon!"] = false

sgs.ai_choicemade_filter.skillInvoke["FormationSummon!"] = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current:hasSkill("jianan") and self:isWeak(current) and promptlist[#promptlist] == "no" then
		sgs.updateIntention(player, current, 80)
	end
end

function SmartAI:getGeneralShowOrHide(player,optional,isShow,isDisableShow)--isDisableShow本回合不能明置
	--目标(player),是否可取消(false/num),明置或暗置,不能明置
	player = player or self.player
	if optional and type(optional) ~= "number" then
		optional = 0
	end
	isShow = isShow or true
	if not isShow then
		local current = self.room:getCurrent()
		local huoshui = (current and current:hasShownSkill("huoshui") and player:objectName() ~= current:objectName())
		isDisableShow = isDisableShow or huoshui
	else isDisableShow = false end--没有本回合不能暗置武将的技能……
	local value,allshown_value,head_value,deputy_value,head_followShow,deputy_followShow = 0,0,0,0,0,0
	local xunchen = sgs.findPlayerByShownSkillName("anyong")--暗涌
	local fazheng = sgs.findPlayerByShownSkillName("xuanhuo")--炫惑
	local round_num = 0
	local players_num = self.room:alivePlayerCount()
	local round_friend_num = player:getPlayerNumWithSameKingdom("AI")
	local round_enemy_num = players_num - player:getPlayerNumWithSameKingdom("AI")
	
	if isShow then
		if player:hasShownAllGenerals() then return nil end
		local kongrong = sgs.findPlayerByShownSkillName("mingshi")--名士
		if kongrong then
			if self:isFriend(player,kongrong) then
				if (not player:hasShownGeneral1() and player:hasShownGeneral2())
					or (player:hasShownGeneral1() and not player:hasShownGeneral2()) then--不需要为了名士全暗置
					allshown_value = allshown_value - 2
				end
			elseif self:isEnemy(player,kongrong) then
				allshown_value = allshown_value + 2
			end
		end
		if xunchen and self:isEnemy(player,xunchen) then--防暗涌
			allshown_value = allshown_value + 2
		end
		local pengyang = sgs.findPlayerByShownSkillName("jinxian")--近陷
		if pengyang and pengyang:distanceTo(player) < 2 then--防近陷
			allshown_value = allshown_value + 2
		end
		if self:hasKnownSkill("deshao|zhenxi", player)then--德劭,震袭
			allshown_value = allshown_value + 2
		end
		if self.player:getPhase() == sgs.Player_RoundStart then
			--有暗置武将牌时,不会触发jianan_hide,所以要为了建安全亮
			local lord_caocao = sgs.findPlayerByShownSkillName("jianan")
			if lord_caocao and self.player:willBeFriendWith(lord_caocao) then
				allshown_value = allshown_value + 2
			end
		end
		local expose_intention = 0
		for kingdom, v in pairs(sgs.ai_loyalty) do
			if not table.contains(sgs.KingdomsTable, kingdom) then continue end
			if sgs.ai_loyalty[kingdom][player:objectName()] > expose_intention then
				expose_intention = sgs.ai_loyalty[kingdom][player:objectName()]
			end
		end
		local gameProcess = sgs.gameProcess()
		if player:objectName() == self.player:objectName() then
			if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1 and not self.player:hasShownGeneral1() then--已开启君主替换
				if self.player:inHeadSkills("rende") or self.player:inHeadSkills("guidao")
					or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("jianxiong") then
					if self.player:getPhase() == sgs.Player_RoundStart and self.player:canShowGeneral("h") then
						head_value = head_value + 6
						if self.player:inHeadSkills("jianxiong")  then
							allshown_value = allshown_value + 2
						end
					elseif self.player:getPhase() == sgs.Player_NotActive then
						head_value = head_value - 6
					end
				end
			end
			if self.player:getActualGeneral1():getKingdom() == "careerist" 
				and not self.player:hasShownGeneral1() and not self.player:getActualGeneral2():isDoubleKingdoms() then--野心家不亮主将,副将双势力除外
				local role = self.player:getRole()
				if role ~= "careerist" then
					if self:isWeak() then
						if self:getAllPeachNum() > 1 then
							head_value = head_value - 1
						else
							head_value = head_value + 2
						end
					else
						head_value = head_value - 4
					end
				else
					if self:isWeak() then
						head_value = head_value + 3
					else
						head_value = head_value - 1
					end
				end
			end
			if not self.room:getTag("TheFirstToShowRewarded"):toBool() and self.room:getScenario() == nil then--首亮奖励,藏不住的技能
				local firstShowSkills = "luanji|niepan|bazhen|jianglve|diaodu|huoshui|qianhuan|chenglve|jinghe|dangxian|wanglie|sidi|lixia"
				if self:isWeak() or self:hasKnownSkill(firstShowSkills, player) then
					value = value + 3
				end
			end
			--local bothShow = ("luanji+shuangxiong|luanji+huoshui|guanxing+yizhi"):split("|")
			local high_followShow = "xiongyi|qianhuan|jihun|chenglve|sidi|wanggui|jinghe|xuanhuo"
			local medium_followShow = "cunsi|dangxian|yuancong"
			local low_followShow = "wusheng|liegong|bazhen|huoshui|wanglie"
			local followShow = high_followShow .. "|" .. medium_followShow .. "|" .. low_followShow
			local followShowSkills = followShow:split("|")
			if self:hasKnownSkill(followShow, player) then
				for _, skill in ipairs(followShowSkills) do
					if player:inHeadSkills(skill) then
						if string.find(high_followShow, skill) then
							head_followShow = head_followShow + 3
						elseif string.find(medium_followShow, skill) then
							head_followShow = head_followShow + 2
						else
							head_followShow = head_followShow + 1
						end
						if head_followShow >= 4 then break end
					elseif player:inDeputySkills(skill) then
						if string.find(high_followShow, skill) then
							deputy_followShow = deputy_followShow + 3
						elseif string.find(medium_followShow, skill) then
							deputy_followShow = deputy_followShow + 2
						else
							deputy_followShow = deputy_followShow + 1
						end
						if deputy_followShow >= 4 then break end
					end
				end
			end
			if string.find(gameProcess, ">>>") or expose_intention > 0 then--开团或暴露
				if head_followShow > 0 or deputy_followShow > 0 then
					head_value = head_followShow + 4
					deputy_value = deputy_followShow + 4
				else
					local huaxin = sgs.findPlayerByShownSkillName("wanggui")--望归
					if (huaxin and player:isFriendWith(huaxin) and huaxin:hasShownAllGenerals()) then--亮将望归摸牌
						value = value + 2
					end
					local lvfan = sgs.findPlayerByShownSkillName("diaodu")--调度
					if (lvfan and player:isFriendWith(lvfan) and player_play_use)
						or (fazheng and player:isFriendWith(fazheng) and player_play_use) then
						value = value + 2
					end
					local mateng = sgs.findPlayerByShownSkillName("xiongyi")--雄异
					if mateng and mateng:getPhase() <= sgs.Player_Play and not self:willSkipPlayPhase(mateng) 
						and self:playerGetRound(mateng) > self:playerGetRound(player) then foreman_play_use = true end
					local nanhualaoxian = sgs.findPlayerByShownSkillName("jinghe")--经合
					if nanhualaoxian and nanhualaoxian:getPhase() <= sgs.Player_Play and not self:willSkipPlayPhase(nanhualaoxian) 
						and self:playerGetRound(nanhualaoxian) > self:playerGetRound(player) then foreman_play_use = true end
					if foreman_play_use then value = value + 2 end
				end
			end
			if self:hasKnownSkill("jinghe", player) and player:getHandcardNum() > 0 and not self:willSkipPlayPhase(player) then
				if self.player:inHeadSkills("jinghe") then
			  		head_value = head_value + 2
				else
					deputy_value = deputy_value + 2
				end
			end
			if self:hasKnownSkill("yongsi", player) and player:getPhase() <= sgs.Player_Draw and not player:hasTreasure("JadeSeal") then
				local jade_seal_owner = nil
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if p:objectName() ~= self.player:objectName() then
						if not p:hasShownOneGeneral() then continue end
						if p:hasTreasure("JadeSeal") then
							jade_seal_owner = p
						end
					end
				end
				if not jade_seal_owner then
					if self.player:inHeadSkills("yongsi") then
			  			head_value = head_value + 2
					else
						deputy_value = deputy_value + 2
					end
				end
			end
			if self:hasKnownSkill("bushi", player) and player:getPhase() <= sgs.Player_Start then
				local dis_num = math.max(self.room:getAlivePlayers():length() - player:getHp() - 2,0)
				if self.player:inHeadSkills("bushi") then
			  		head_value = head_value - dis_num
				else
					deputy_value = deputy_value - dis_num
				end
			end
			if self:isWeak() then
				local doubleMaxHp = self.player:getActualGeneral1():getMaxHpHead() + self.player:getActualGeneral2():getMaxHpDeputy()
				if self:willSkipPlayPhase() and self:getOverflow() > 1 and math.mod(doubleMaxHp, 2) > 0 then
					allshown_value = allshown_value + 2
				end
			end
			if self.player:getActualGeneral1():isCompanionWith(self.player:getActualGeneral2Name()) then
				for _, friend in ipairs(self.friends) do
					if self:isWeak(friend) then
						allshown_value = allshown_value + 3
						break
					end
				end
			end
			if fazheng and self.player:isFriendWith(fazheng) then--尽量不亮可炫惑的技能
				--每有一个可以发动炫惑的队友,各炫惑技能的亮将价值-1
				local other_num = fazheng:getPlayerNumWithSameKingdom("AI") - 1 
				local xuanhuo_priority = {"paoxiao", "tieqi", "kuanggu", "liegong", "wusheng", "longdan"}
				for _, skill in ipairs(xuanhuo_priority) do
					if self.player:hasSkill(skill) and not self.player:hasShownSkill(skill) then
						if self.player:inHeadSkills(skill) then
			  				head_value = head_value - other_num
							break
						else
							deputy_value = deputy_value - other_num
							break
						end
					end
				end
			end
			--结姻
			for _, friend in ipairs(self.friends) do
				if friend:hasShownSkill("jieyin") and (friend:isWounded() or self.player:isWounded()) then
					if not self.player:hasShownGeneral1() then
						if not self.player:hasShownGeneral2() then
							if self.player:getActualGeneral1():isMale() and self.player:getActualGeneral2():isMale() then
								value = value + 2
							elseif self.player:getActualGeneral1():isMale() then
								head_value = head_value + 2
							elseif self.player:getActualGeneral2():isMale() then
								deputy_value = deputy_value + 2
							end
						elseif not self.player:getActualGeneral2():isMale() and self.player:getActualGeneral1():isMale() then
							head_value = head_value + 2
						end
					end
				end
			end
			local diaochan = sgs.findPlayerByShownSkillName("lijian")--离间
			if diaochan then
				if self:isFriend(diaochan) and self:hasKnownSkill("wushuang", player) then
					for _, p in ipairs(self.enemies) do
						if p:isMale() then
							if not self.player:hasShownGeneral1() then
								if not self.player:hasShownGeneral2() then
									if self.player:getActualGeneral1():isMale() and self.player:getActualGeneral2():isMale() then
										value = value + 2
									elseif self.player:getActualGeneral1():isMale() then
										head_value = head_value + 2
									elseif self.player:getActualGeneral2():isMale() then
										deputy_value = deputy_value + 2
									end
								elseif not self.player:getActualGeneral2():isMale() and self.player:getActualGeneral1():isMale() then
									head_value = head_value + 2
								end
							end
							break
						end
					end
				elseif self:isEnemy(diaochan) then
					for _, friend in ipairs(self.friends_noself) do
						if friend:isMale() then
							if not self.player:hasShownGeneral1() then
								if not self.player:hasShownGeneral2() then
									if self.player:getActualGeneral1():isMale() and self.player:getActualGeneral2():isMale() then
										value = value - 2
									elseif self.player:getActualGeneral1():isMale() then
										head_value = head_value - 2
									elseif self.player:getActualGeneral2():isMale() then
										deputy_value = deputy_value - 2
									end
								elseif not self.player:getActualGeneral2():isMale() and self.player:getActualGeneral1():isMale() then
									head_value = head_value - 2
								end
							end
							break
						end
					end
				end
			end
		end
		if not player:hasShownGeneral1() and not player:hasShownGeneral2() then--全暗置(有可能已明置势力)
			if xunchen and self:isEnemy(player,xunchen) then--防暗涌
				allshown_value = allshown_value + 4
			end
		end
		if not player:hasShownOneGeneral() then--没有明置势力
			if round_friend_num >= math.floor(players_num / 2) then--半数开团
				value = value + 3
			end
			if expose_intention > 0 then--暴露程度
				value = value + 1
				--diaodu|qianhuan|chenglve|sidi|wanggui|yuancong
				if self:hasKnownSkill("wuku", player) then--miewu
					if self.player:inHeadSkills("wuku") then
			  			head_value = head_value + 2
					else
						deputy_value = deputy_value + 2
					end
				end
			end
			if player:hasTreasure("JadeSeal") and player:getPhase() <= sgs.Player_Draw then
				value = value + 2
			end
			local duyu = sgs.findPlayerByShownSkillName("miewu")--灭吴
			if duyu and duyu:getMark("#wuku") < 2 then--灭吴上装备
				if self:isFriend(player,duyu) and not player:isFriendWith(duyu) then
					value = value + 2
				elseif self:isEnemy(player,duyu) then 
					value = value - 2
				end
			end
			local liuqi = sgs.findPlayerByShownSkillName("wenji")--问计
			if liuqi and not self:isFriend(player,liuqi) then--防问计白嫖
				value = value + 1
			end
			local panjun = sgs.findPlayerByShownSkillName("congcha")--聪察
			if panjun and not player:isFriendWith(panjun) then--聪察流失体力有点伤
				value = value + 2
			end
			local shixie = sgs.findPlayerByShownSkillName("lixia")--礼下
			if shixie and player:isFriendWith(shixie) then--礼下让队友摸
				value = value - 2
			end
			local zhuling = sgs.findPlayerByShownSkillName("fangyuan")--方圆
			if zhuling and not player:isFriendWith(zhuling) and player:inSiegeRelation(player, zhuling) then--尽量不围攻方圆
				value = value - 2
			end
			if sgs.findPlayerByShownSkillName("yigui") then--亮势力防左慈
				local huashens = player:property("Huashens"):toString():split("+")
				value = value + 2*#huashens
			end
			local huangzu = sgs.findPlayerByShownSkillName("xishe")--亮势力防队友袭射
			if huangzu and self.player:getHp() <= huangzu:getEquips():length() and player:getPhase() <= sgs.Player_Start then
				if self:isFriend(player,huangzu) then
					value = value + 4
				else
					value = value + 2
				end
			end
			local hetaihou = sgs.findPlayerByShownSkillName("zhendu")--亮势力防队友鸩毒
			local player_play_use,foreman_play_use = false,false
			if player:getPhase() <= sgs.Player_Play and not self:willSkipPlayPhase(player) then player_play_use = true end
			if hetaihou and hetaihou:getHandcardNum() > 0 and player:getHp() <= 1 and player_play_use then
				if self:isFriend(player,hetaihou) then
					value = value + 4
				else
					value = value + 2
				end
			end
		end
		
		if self:hasKnownSkill("zhiwei", player) and not player:hasShownSkill("zhiwei") then--至微队友
			local can_zhiwei = false
			for _, friend in ipairs(self:getFriendsNoself(player)) do
				if player:isFriendWith(friend) and not self:isWeak(friend) then
					can_zhiwei = true
					break
				end
			end
			if can_zhiwei and player:inHeadSkills("zhiwei") then
				head_value = head_value + 2
			elseif can_zhiwei then
				deputy_value = deputy_value + 2
			elseif not can_zhiwei and player:inHeadSkills("zhiwei") then
				head_value = head_value - 2
			elseif not can_zhiwei then
				deputy_value = deputy_value - 2
			end
		end
		--不亮
		if player:inHeadSkills("baoling") then--暴凌限定技,触发后会失去技能
			--table.contains(player:getAcquiredSkills("deputy"), "benghuai")--变更副将甚至断肠都不会移除崩坏
			if player:hasShownSkill("baoling") and player:getPhase() <= sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then--已经于出牌阶段前明置且未跳过出牌
				deputy_value = deputy_value + 8
			else
				if (self:hasKnownSkill("luanwu", player) and player:getMark("@chaos") ~= 0)
					or (self:hasKnownSkill("xiongyi", player) and player:getMark("@arise") ~= 0) then
					head_value = head_value - 6
				elseif (self:hasKnownSkill("yaowu", player) and not player:hasShownSkill("yaowu") and player:getMark("@showoff") > 0) then--耀武
					head_value = head_value - 8
					deputy_value = deputy_value - 6
				elseif self:hasKnownSkill("shigong", player) and player:getMark("@handover") > 0 then
					head_value = head_value - 6
				elseif self:hasKnownSkill("miewu|yigui|jinghe|anyong", player) then 
					head_value = head_value - 6
					if self:isWeak(player) and player:getPhase() <= sgs.Player_Play then
						head_value = head_value + 2
					end
				elseif self:isWeak(player) and player:getPhase() <= sgs.Player_Play then
					head_value = head_value + 6
				elseif not self:isWeak(player) then
					if self:hasKnownSkill("yaowu", player) and player:getMark("@showoff") > 0 then--亮了会崩坏,不亮被打会资敌……
						head_value = head_value + 1
					else
						head_value = head_value - 4
					end
				end
			end
		elseif (self:hasKnownSkill("yaowu", player) and not player:hasShownSkill("yaowu") and player:getMark("@showoff") > 0) then--耀武
			if player:inHeadSkills("yaowu") then
				head_value = head_value - 4
			else
				deputy_value = deputy_value - 4
			end
		end
		if self:hasKnownSkill("quanjia", player) and not player:hasShownSkill("quanjia") and player:getMark("quanjiaUsed") == 0 then--劝驾
			local liubei = sgs.findPlayerByShownSkillName("rende")
			if liubei and self:isFriend(liubei) then
				deputy_value = deputy_value + 6
			elseif not string.find(gameProcess, player:getKingdom()..">>>") and player:getMark("Global_RoundCount") <= 1 then--不是大优势尽量不开团
				deputy_value = deputy_value - 4
			elseif string.find(gameProcess, player:getKingdom()..">>>") then
				deputy_value = deputy_value + 4
			end
		end
		if self:hasKnownSkill("shiyong", player) and not player:hasShownSkill("shiyong") then--恃勇
			if player:getMark("##yaowu") > 0 then
				if player:inHeadSkills("shiyong") then
					head_value = head_value - 4
				else
					deputy_value = deputy_value - 4
				end
			elseif self:isWeak(player) then--被迫亮
				if player:inHeadSkills("shiyong") then
					head_value = head_value + 2
				else
					deputy_value = deputy_value + 2
				end
			end
		end
		if self:hasKnownSkill("xushi", player) and not player:hasShownSkill("xushi") then--虚实
			if player:inHeadSkills("xushi") then
				head_value = head_value - 2
			else
				deputy_value = deputy_value - 2
			end
		end
	else--倾城(qingcheng)
		if current and isDisableShow then
			if player:objectName() ~= current:objectName() then
				round_num = self:playerGetRound(current, player)
				round_friend_num = self:getFriendNumBySeat(current, player, player)
				round_enemy_num = self:getEnemyNumBySeat(current, player, player)
			else
				round_num = players_num
				if player:getPhase() > sgs.Player_Play then
					round_num = round_num - 1
					round_friend_num = round_friend_num - 1
				end
			end
		end
		--名士(mingshi)暂不考虑
		--不值得为了离间和结姻暗置
		--不屈(buqu:scars)考虑正面收益与击杀收益
		if player:hasShownSkill("buqu") and player:getPile("scars"):length() > 0 then
			local scars_num = player:getPile("scars"):length()
			if self:isFriend(player) then
				local zoushi = sgs.findPlayerByShownSkillName("huoshui")--祸水
				if not (zoushi and self:isEnemy(player,zoushi) and self:playerGetRound(player) > self:playerGetRound(zoushi)) then
					local value_ratio = 1
					if self.player:isFriendWith(player) then
						value_ratio = 2
						if scars_num >= 5 then
							value_ratio = 3
						end
					end
					if player:inHeadSkills("buqu") then
						head_value = head_value + value_ratio*scars_num
					else
						deputy_value = deputy_value + value_ratio*scars_num
					end
				elseif scars_num < 5 then
					if player:inHeadSkills("buqu") then
						head_value = head_value - 4
					else
						deputy_value = deputy_value - 4
					end
				else
					if player:inHeadSkills("buqu") then
						head_value = head_value - 2
					else
						deputy_value = deputy_value - 2
					end
				end
			elseif self:isEnemy(player) then
				local value_ratio = -2
				if scars_num >= 5 then
					value_ratio = -3
				end
				if isDisableShow and player:getHp() == 1 and scars_num < 5 then--倾城不屈击杀……
					local slash = sgs.cloneCard("slash")
					if self.player:canSlash(player, slash, true) and self:slashIsEffective(slash, player)
						and sgs.isGoodTarget(player, self.enemies, self) and self:canHit(player, self.player) then
						if player:inHeadSkills("buqu") then
							head_value = head_value + (5 - scars_num)/2
						else
							deputy_value = deputy_value + (5 - scars_num)/2
						end
					end
				else
					if player:inHeadSkills("buqu") then
						head_value = head_value + value_ratio*scars_num
					else
						deputy_value = deputy_value + value_ratio*scars_num
					end
				end
			end
		end
		if self:isFriend(player) then--暗置队友
			if player:hasShownSkill("guixiu") then--闺秀
				if player:inHeadSkills("guixiu") then
					head_value = head_value + 4
				else
					deputy_value = deputy_value + 4
				end
			end
			if player:hasShownSkill("xushi") then--虚实
				if player:inHeadSkills("xushi") then
					head_value = head_value + 2
				else
					deputy_value = deputy_value + 2
				end
			end
			--至微(zhiwei:##zhiwei)
			if player:hasShownSkill("zhiwei") then--至微没有绑定角色
				--"#zhiwei-effect"
				local zhiwei_target = nil
				for _,p in sgs.qlist(self.room:getOtherPlayers(player)) do
					if p:getMark("##zhiwei") then
						zhiwei_target = p
						break
					end
				end
				if not zhiwei_target then
					local can_zhiwei = false
					for _, friend in ipairs(self:getFriendsNoself(player)) do
						if player:isFriendWith(friend) and not self:isWeak(friend) then
							can_zhiwei = true
							break
						end
					end
					if can_zhiwei and player:inHeadSkills("zhiwei") then
						head_value = head_value + 2
					elseif can_zhiwei then
						deputy_value = deputy_value + 2
					end
				end
			end
			if player:hasShownSkill("baoling") then--暴凌限定技,触发后会失去技能
				--sgs.Sanguosha:getGeneral(player:getGeneral2Name()):objectName() ~= "sujiang"
				head_value = head_value + 4
			end
			if player:hasShownSkill("shiyong") and player:getMark("@showoff") > 0 then
				if player:inHeadSkills("shiyong") then
					head_value = head_value + 4
				else
					deputy_value = deputy_value + 4
				end
			elseif (player:hasShownSkill("yaowu") and player:getMark("##yaowu") > 0) then
				if player:inHeadSkills("yaowu") then
					head_value = head_value + 4
				else
					deputy_value = deputy_value + 4
				end
			end
		elseif self:isEnemy(player) then--暗置敌方
			if xunchen and self.player:isFriendWith(xunchen) then--创造暗涌机会
				value = value + 4*round_friend_num/round_num
			end
			if player:hasShownSkill("wanggui") then--望归
				local friend_num = player:getPlayerNumWithSameKingdom("AI")
				if player:hasShownAllGenerals() and friend_num <= 2 then--暗置望归,防止造成伤害
					if player:inHeadSkills("wanggui") then
						head_value = head_value + 2
					else
						deputy_value = deputy_value + 2
					end
				else
					if player:inHeadSkills("wanggui") then--暗置另一个武将,防止摸牌
						deputy_value = deputy_value + 2
					else
						head_value = head_value + 2
					end
				end
			end
			if player:hasShownSkill("deshao") then--德劭
				if player:inHeadSkills("deshao") then--暗置另一个武将,防止弃牌
					deputy_value = deputy_value + 2
				else
					head_value = head_value + 2
				end
			end
			if player:hasShownSkill("zhiwei") then--至微绑定目标伤害牌多
				--"#zhiwei-effect"
				local zhiwei_target = nil
				for _,p in sgs.qlist(self.room:getOtherPlayers(player)) do
					if p:getMark("##zhiwei") then
						zhiwei_target = p
						break
					end
				end
				if zhiwei_target and (zhiwei_target:hasSkills("miewu|yigui") or zhiwei_target:getHandcardNum() >= 4) then
					if player:inHeadSkills("zhiwei") then
						head_value = head_value + 3*((round_num-round_friend_num)/players_num)
					elseif not can_zhiwei then
						deputy_value = deputy_value + 3*((round_num-round_friend_num)/players_num)
					end
				end
			end
			if player:hasShownSkill("xuanhuo") then--眩惑
				local friend_num = player:getPlayerNumWithSameKingdom("AI")
				if player:inHeadSkills("xuanhuo") then
					head_value = head_value + 4*(friend_num - 1)*round_enemy_num/round_num
				else
					deputy_value = deputy_value + 4*(friend_num - 1)*round_enemy_num/round_num
				end
			end
			if player:hasShownSkill("yongsi") and not player:hasTreasure("JadeSeal")
				and not self.player:isFriendWith(player) and self:getCardsNum("ThreatenEmperor") > 0 then--庸肆,开挟天子
				local kingdom_value = {}
				local kingdoms = sgs.KingdomsTable
				for _, kingdom in ipairs(kingdoms) do
					kingdom_value[kingdom] = 0
				end
				local jade_seal_owner = nil
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if p:objectName() ~= self.player:objectName() then
						if not p:hasShownOneGeneral() then continue end
						if p:hasTreasure("JadeSeal") then
							jade_seal_owner = p
						end
					end
					if p:getKingdom() ~= "careerist" and table.contains(kingdoms, p:getKingdom()) then--野心家不算(进残局加入野心家应该算的,但是暂时不知道怎么区分)
						kingdom_value[p:getKingdom()] = kingdom_value[p:getKingdom()] + 1
					end
				end
				if not jade_seal_owner then
					local the_big = 0
					for _, kingdom in ipairs(kingdoms) do
						if kingdom_value[kingdom] and kingdom_value[kingdom] > the_big then
							the_big = kingdom_value[kingdom]
						end
					end
					if table.contains(kingdoms, self.player:getKingdom()) and the_big == kingdom_value[self.player:getKingdom()] then
						local can_use = false
						local use_cards = self:getCards("ThreatenEmperor")
						for _, use_card in ipairs(use_cards) do
							if not self.player:isProhibited(self.player, use_card) then
								can_use = true
								break
							end
						end
						if can_use then
							if player:inHeadSkills("yongsi") then
								head_value = head_value + 4
							else
								deputy_value = deputy_value + 4
							end
						end
					end
				end
			end
			--各种标记类技能
			local dis_num,value_ratio = 0,0
			--屯田(tuntian:jixi:ziliang:field)
			if player:hasShownSkill("jixi") and player:getPile("field"):length() > 0 then
				dis_num = player:getPile("field"):length()
				value_ratio = 2
				head_value = head_value + value_ratio*dis_num
			elseif player:hasShownSkill("ziliang") and player:getPile("field"):length() > 0 then
				dis_num = player:getPile("field"):length()
				value_ratio = 1
				deputy_value = deputy_value + value_ratio*dis_num
			end
			--千幻(qianhuan:sorcery)
			if player:hasShownSkill("qianhuan") and player:getPile("sorcery"):length() > 0 then
				dis_num = player:getPile("sorcery"):length()
				value_ratio = 2
				if player:inHeadSkills("qianhuan") then
					head_value = head_value + value_ratio*dis_num
				else
					deputy_value = deputy_value + value_ratio*dis_num
				end
			end
			--司敌(sidi:drive)
			if player:hasShownSkill("sidi") and player:getPile("drive"):length() > 0 then
				dis_num = player:getPile("drive"):length()
				value_ratio = 2
				for _, friend in ipairs(self:getFriendsNoself(player)) do
					if player:isFriendWith(friend) and friend:isWounded() then
						value_ratio = 3
						break
					end
				end
				if player:inHeadSkills("sidi") then
					head_value = head_value + value_ratio*dis_num
				else
					deputy_value = deputy_value + value_ratio*dis_num
				end
			end
			--输粮(shuliang:food)
			
			--布施(bushi:#yishe)
			if player:hasShownSkill("bushi") and player:getMark("#yishe") > 0 then
				dis_num = player:getMark("#yishe")
				local yishe_friend = math.min(dis_num,#self:getFriendsNoself(player))
				if player:inHeadSkills("bushi") then
					head_value = head_value + yishe_friend*2 + dis_num - yishe_friend
				else
					deputy_value = deputy_value + yishe_friend*2 + dis_num - yishe_friend
				end
			end
			--米道(midao:rice)
			if player:hasShownSkill("midao") and player:getPile("rice"):length() > 0 then--没判定牌时,需要考虑防止制衡效果,暗置未必是收益
				dis_num = player:getPile("rice"):length()
				value_ratio = 1
				local has_judge = false
				for _,p in sgs.qlist(self.room:getAlivePlayers()) do
					if p:getCards("j"):length() > 0 then--言笑?
						has_judge = true
						break
					elseif p:hasSkills(sgs.judge_reason) then
						has_judge = true
						break
					end
				end
				if has_judge then
					value_ratio = 2
				elseif dis_num > 1 then
					value_ratio = 0.5
				else
					value_ratio = -1
				end
				deputy_value = deputy_value + value_ratio*dis_num
			end
			--量反,求安(liangfan,qiuan:letter)
			if player:hasShownSkill("qiuan") and player:getPile("letter"):length() > 0 then
				if player:inHeadSkills("qiuan") then
					head_value = head_value + 3
				else
					deputy_value = deputy_value + 3
				end
			end
			if player:hasShownSkill("liangfan") and player:getPile("letter"):length() > 0 then
				dis_num = player:getPile("letter"):length()
				local important_card = 0
				for _,id in sgs.qlist(player:getPile("letter"))do
					if sgs.ais[player:objectName()]:getKeepValue(card) >= 4.1 or sgs.ais[player:objectName()]:getUseValue(card) >= 6 then
						important_card = important_card + 1
					end
				end
				if player:inHeadSkills("liangfan") then
					head_value = head_value - dis_num - important_card
				else
					deputy_value = deputy_value - dis_num - important_card
				end
			end
			--权计(quanji:power_pile)
			if player:hasShownSkill("quanji") and player:getPile("power_pile"):length() > 0 then
				dis_num = player:getPile("sorcery"):length()
				if player:inHeadSkills("quanji") then
					head_value = head_value + 2*(dis_num - 1)+ math.min(dis_num,3)
				else
					deputy_value = deputy_value + 2*(dis_num - 1)+ math.min(dis_num,3)
				end
			end
			--恣睢(zisui:&disloyalty)
			if player:hasShownSkill("zisui") and player:getPile("&disloyalty"):length() > 0 then
				dis_num = player:getPile("&disloyalty"):length()
				value_ratio = 3
				if player:inHeadSkills("zisui") then
					head_value = head_value + value_ratio*dis_num
				else
					deputy_value = deputy_value + value_ratio*dis_num
				end
			end
			--灭吴(miewu:#wuku)
			if player:hasShownSkill("miewu") and player:getMark("#wuku") > 0 then
				dis_num = player:getMark("#wuku")
				value_ratio = 3
				if player:inHeadSkills("miewu") then
					head_value = head_value + value_ratio*dis_num
				else
					deputy_value = deputy_value + value_ratio*dis_num
				end
			end
			--凶虐(xiongnve:#massacre)
			if player:hasShownSkill("xiongnve") and player:getMark("#massacre") > 0 then
				dis_num = player:getMark("#massacre")
				value_ratio = 3
				if player:inHeadSkills("xiongnve") then
					head_value = head_value + value_ratio*dis_num
				else
					deputy_value = deputy_value + value_ratio*dis_num
				end
			end
			if player:hasShownSkill("yigui") then
				local huashens = player:property("Huashens"):toString():split("+")
				dis_num = #huashens
				value_ratio = 2
				if player:inHeadSkills("yigui") then
					head_value = head_value + value_ratio*dis_num
				else
					deputy_value = deputy_value + value_ratio*dis_num
				end
			end
			if isDisableShow then
				--荐才(jiancai)
				if player:hasShownSkill("jiancai") then
					local weak_enemy = false
					for _, friend in ipairs(self:getFriends(player)) do
						if player:isFriendWith(friend) and self:isWeak(friend) then
							if player:inHeadSkills("jiancai") then
								head_value = head_value + 3
							else
								deputy_value = deputy_value + 3
							end
							break
						end
					end
				end
				--涅槃(niepan)
				if (player:hasShownSkill("niepan") and player:getMark("@nirvana") > 0) and self:isWeak(player) then
					if player:inHeadSkills("niepan") then
						head_value = head_value + 3
					else
						deputy_value = deputy_value + 3
					end
				end
				--示恭(shigong)
				if (player:hasShownSkill("shigong") and player:getMark("@handover") > 0) and self:isWeak(player) then
					if player:inHeadSkills("shigong") then
						head_value = head_value + 3
					else
						deputy_value = deputy_value + 3
					end
				end
				--[[
				--不能明置isDisableShow
				--放逐(fangzhu)
				--行殇(xingshang),固政(guzheng)
				--yiji,jieming,jijiu,beige,fudi
				--kongcheng,bazhen,xiangle,liuli,tianxiang,leiji,mingshi,keshou,yuanyu
				--qingguo,longdan,qianxun,xiaoji,shoucheng,yicheng,jili,xuanlue,mingzhe
				--shushen,buyi,diancai
				--]]
				if self:isWeak(player) then
					for _, skill_name in ipairs((sgs.priority_skill):split("|")) do
						if not player:hasShownSkill(skill_name) then continue end
						local value_ratio = 0
						if string.find(sgs.masochism_skill,skill_name) then
							value_ratio = 2
						elseif string.find(sgs.defense_skill,skill_name) then
							value_ratio = 1
						end
						if player:inHeadSkills(skill_name) then
							head_value = head_value + value_ratio
						else
							deputy_value = deputy_value + value_ratio
						end
					end
				end
			end
		end
	end
	local show_position = {}
	if isShow then
		if player:objectName() == self.player:objectName() then--亮将最终加算
			if (head_value == deputy_value) and (head_value + value > 0 or not optional) then--亮将优先级
				if (self.player:canShowGeneral("h") and not self.player:hasShownGeneral1())
					and (self.player:canShowGeneral("d") and not self.player:hasShownGeneral2()) then
					if self.player:getKingdom() == "shu" then--炫惑亮将优先级
						local xuanhuo_priority = {"paoxiao", "tieqi", "kuanggu", "liegong", "wusheng", "longdan"}
						for _, skill in ipairs(xuanhuo_priority) do
							if self.player:hasSkill(skill) then
								if self.player:inHeadSkills(skill) then
			  						deputy_value = deputy_value + 1
									break
								else
									head_value = head_value + 1
									break
								end
							end
						end
					end
				end
			end
		end
		if (player:canShowGeneral("h") and not player:hasShownGeneral1())
			and (player:canShowGeneral("d") and not player:hasShownGeneral2()) then--双将亮将选择
			if head_value + allshown_value >= 0 and deputy_value + allshown_value >= 0 then
				value = value + allshown_value
			end
		elseif (player:canShowGeneral("h") and not player:hasShownGeneral1()) then--单将亮将考虑
			head_value = head_value + allshown_value
		elseif (player:canShowGeneral("d") and not player:hasShownGeneral2()) then--单将亮将考虑
			deputy_value = deputy_value + allshown_value
		end
		if optional then value = value + optional end
		local name = sgs.Sanguosha:translate(player:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(player:getActualGeneral2Name()).."("..sgs.Sanguosha:translate(string.format("SEAT(%s)",player:getSeat()))..")"
		Global_room:writeToConsole(name.."明置价值(主将修正,副将修正,全亮修正,额外修正):"..value.."("..head_value..","..deputy_value..","..allshown_value..","..tostring(optional)..")")
		if (player:canShowGeneral("h") and not player:hasShownGeneral1())
			and (player:canShowGeneral("d") and not player:hasShownGeneral2()) then--双将亮将选择
			if optional then--考虑不亮
				if math.max(head_value, deputy_value) + value < 0 then return nil end
				if math.max(head_value, deputy_value) + value == 0 and not (sgs.general_shown[player:objectName()]["head"]
					or sgs.general_shown[player:objectName()]["deputy"]) then return nil end
			end
			if head_value == math.max(head_value, deputy_value) then--考虑亮将
				if (head_value > 0 and deputy_value + value > 0) or deputy_value + allshown_value > 0 then--主将亮了一般不藏副将,除非只为了亮势力
					table.insert(show_position,"head")
					table.insert(show_position,"deputy")
				else
					table.insert(show_position,"head")--优先亮主将,除非主将需要藏
					if deputy_value + deputy_followShow > 0 then table.insert(show_position,"deputy") end
				end
			elseif deputy_value == math.max(head_value, deputy_value) then
				table.insert(show_position,"deputy")
				if head_value + allshown_value > 0 then table.insert(show_position,"head") end
			end
		elseif (player:canShowGeneral("h") and not player:hasShownGeneral1()) then--单将亮将考虑
			if optional then--考虑不亮
				if head_value + value < 0 then return nil end
				if head_value + value == 0 and not sgs.general_shown[player:objectName()]["head"] then return nil end
			end
			table.insert(show_position,"head")
		elseif (player:canShowGeneral("d") and not player:hasShownGeneral2()) then--单将亮将考虑
			if optional then--考虑不亮
				if deputy_value + value < 0 then return nil end
				if deputy_value + value == 0 and not sgs.general_shown[player:objectName()]["deputy"] then return nil end
			end
			table.insert(show_position,"deputy")
		else return nil end
	else
		if not player:hasShownOneGeneral() then return nil
		elseif player:hasShownAllGenerals() then
			if optional then--考虑不暗置
				if math.max(head_value, deputy_value) + value <= 0 then return nil end
			end
			if head_value == math.max(head_value, deputy_value) then--考虑暗置单将(目前只有单将)
				table.insert(show_position,"head")
				--if deputy_value > 0 then table.insert(show_position,"deputy") end
			elseif  deputy_value == math.max(head_value, deputy_value) then
				table.insert(show_position,"deputy")
				--if head_value > 0 then table.insert(show_position,"head") end
			end
		elseif player:hasShownGeneral1() then
			if optional then--考虑不暗置
				if head_value + value <= 0 then return nil end
			end
			table.insert(show_position,"head")
		elseif player:hasShownGeneral2() then
			if optional then--考虑不暗置
				if deputy_value + value <= 0 then return nil end
			end
			table.insert(show_position,"deputy")
		end
	end
	if next(show_position) then
		return table.concat(show_position, "+")
	else return nil end
end

--每回合明置
sgs.ai_skill_choice.GameRule_AskForGeneralShow = function(self, choices)

	local canShowHead = string.find(choices, "show_head_general")
	local canShowDeputy = string.find(choices, "show_deputy_general")
	local canCancel = string.find(choices, "cancel")
	
	--show_both_generals选项判断
	local firstShow = ("luanji|niepan|bazhen|jianglve|diaodu|huoshui|qianhuan|chenglve|jinghe|dangxian|wanglie|sidi"):split("|")
	local bothShow = ("luanji+shuangxiong|luanji+huoshui|guanxing+yizhi"):split("|")
	local followShow = ("wusheng|liegong|bazhen|cunsi|diaodu|xiongyi|huoshui|qianhuan|jihun|chenglve|dangxian|wanglie|sidi"):split("|")

	local show_position = self:getGeneralShowOrHide(self.player,(canCancel and true or false),true)
	if not show_position then return "cancel"
	elseif string.find(show_position, "+") then return "show_both_generals"
	elseif string.find(show_position, "head") then return "show_head_general"
	elseif string.find(show_position, "deputy") then return "show_deputy_general" end
	
	if sgs.GetConfig("EnableLordConvertion", true) and canShowHead then--已开启君主替换(布施不推荐君主双亮)
		if self.player:inHeadSkills("rende") or self.player:inHeadSkills("guidao")
			or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("jianxiong") then
			if self.player:getPhase() == sgs.Player_RoundStart and self.player:getMark("Global_RoundCount") == 1 then
				if canShowDeputy then
					return "show_both_generals"
				else
					return "show_head_general"
				end
			elseif self.player:hasShownOneGeneral() and canCancel then
				return "cancel"
			elseif canShowDeputy then--阵法召唤GameRule_AskForArraySummon调用
				return "show_deputy_general"
			end
		end
	end
	
	local lord_caocao = sgs.findPlayerByShownSkillName("jianan")
	if lord_caocao and self.player:willBeFriendWith(lord_caocao) then
		return "show_both_generals"
	end
	local lord_sunquan = sgs.findPlayerByShownSkillName("jiahe")
	if lord_sunquan and self.player:willBeFriendWith(lord_sunquan) and not lord_sunquan:getPile("flame_map"):isEmpty() then
		return "show_both_generals"
	end

	if self.player:hasSkills("deshao|zhenxi") then
		return "show_both_generals"
	end

	local notshown, shown, allshown, f, e, eAtt = 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self:evaluateKingdom(p) == self.player:getKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
		if p:hasShownAllGenerals() then
			allshown = allshown + 1
		end
	end

	local showRate = math.random() + shown/20

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end

	if (firstShowReward or self:willShowForAttack()) and not self:willSkipPlayPhase() then
		for _, skill in ipairs(bothShow) do
			if self.player:hasSkills(skill) then
				if showRate > 0.7 then
					return "show_both_generals"
				end
			end
		end
	end

	if firstShowReward and not self:willSkipPlayPhase() then
		for _, skill in ipairs(firstShow) do
			if self.player:hasSkill(skill) and not self.player:hasShownOneGeneral() then
				if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.8 then
					return "show_head_general"
				elseif canShowDeputy and showRate > 0.8 then
					return "show_deputy_general"
				end
			end
		end
		if not self.player:hasShownOneGeneral() then
			if showRate > 0.9 then
				return "show_both_generals"
			end
		end
	end

	if self.player:inHeadSkills("baoling") then
		if (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") ~= 0)
		or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") ~= 0) then
			canShowHead = nil
		end
		if (self.player:hasSkill("yaowu") and not self.player:hasShownGeneral2()) then
			return "cancel"
		end
	end
	if self.player:inHeadSkills("baoling") then
		if (self.player:hasSkill("mingshi") and allshown >= (self.room:alivePlayerCount() - 1))
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") == 0)
			or (self.player:hasSkill("yaowu") and self.player:getMark("##yaowu") > 0) then
			if canShowHead then
				return "show_head_general"
			end
		end
	end

	if self.player:hasSkill("guixiu") and not self.player:hasShownSkill("guixiu") then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase()) then
			if self.player:inHeadSkills("guixiu") and canShowHead then
				return "show_head_general"
			elseif canShowDeputy then
				return "show_deputy_general"
			end
		end
	end

	if self.player:hasSkill("yongsi") and not self.player:hasShownSkill("yongsi") then--袁术玉玺
		if self.player:inHeadSkills("yongsi") and canShowHead then
			return "show_head_general"
		elseif canShowDeputy then
			return "show_deputy_general"
		end
	end

	if self.player:hasSkill("xibing") and not self.player:hasShownSkill("xibing") then--息兵
		if self.player:inHeadSkills("xibing") and canShowHead then
			return "show_head_general"
		elseif canShowDeputy then
			return "show_deputy_general"
		end
	end

	for _,p in ipairs(self.friends) do
		if p:hasShownSkill("jieyin") then
			if canShowHead and self.player:getGeneral():isMale() then
				return "show_head_general"
			elseif canShowDeputy and self.player:getGeneral():isFemale() and self.player:getGeneral2():isMale() then
				return "show_deputy_general"
			end
		end
	end

	if self.player:getMark("CompanionEffect") > 0 then--标记修改
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3) or self:willShowForDefence() then
			return "show_both_generals"
		end
	end

	if self.player:getMark("HalfMaxHpLeft") > 0 then
		if self:isWeak() or self:willShowForDefence() then
			return "show_both_generals"
		end
	end

	if self.player:getActualGeneral1():getKingdom() == "careerist" then--野心家发技能相关，留着最后暴露野心？
		if lord_caocao and self.player:getActualGeneral2():getKingdom() == lord_caocao:getKingdom() then
			if canShowDeputy then
				return "show_deputy_general"
			end
			return "cancel"
		end
		local fazheng = sgs.findPlayerByShownSkillName("xuanhuo")
		if fazheng and self.player:getActualGeneral2():getKingdom() == fazheng:getKingdom() then
			if canShowDeputy then
				return "show_deputy_general"
			end
			return "cancel"
		end
		if lord_sunquan and self.player:getActualGeneral2():getKingdom() == lord_sunquan:getKingdom() then
			if canShowDeputy and not lord_sunquan:getPile("flame_map"):isEmpty() then
				return "show_deputy_general"
			end
			return "cancel"
		end
		local nanhualaoxian = sgs.findPlayerByShownSkillName("jinghe")
		if nanhualaoxian and self.player:getActualGeneral2():getKingdom() == nanhualaoxian:getKingdom() then
			if canShowDeputy then
				return "show_deputy_general"
			end
			return "cancel"
		end
		if self:isWeak() and self:willShowForDefence() then
			return "show_both_generals"
		end
	end

	if self.player:getMark("##congcha") > 0 then--聪察队友
		--Global_room:writeToConsole("聪察:有标记")
		local panjun = sgs.findPlayerByShownSkillName("congcha")
		if panjun then
			if self.player:willBeFriendWith(panjun) then--暗置只能用willBeFriendWith
				--Global_room:writeToConsole("聪察:队友明置")
				return "show_both_generals"
			elseif self.player:getActualGeneral2():getKingdom() == panjun:getKingdom() and canShowDeputy then--野心家
				return "show_deputy_general"
			elseif self.player:getHp() == 1 and (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0) then
				--Global_room:writeToConsole("聪察:敌方不明置")
				return "cancel"
			end
		end
	end

	if self.player:hasTreasure("JadeSeal") then
		if not self.player:hasShownOneGeneral() then
			if canShowDeputy then
				return "show_deputy_general"
			elseif canShowHead then
				return "show_head_general"
			end
		end
	end

	for _, skill in ipairs(followShow) do
		if ((shown > 0 and e < notshown) or self.player:hasShownOneGeneral()) and self.player:hasSkill(skill) then
			if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.6 then
				return "show_head_general"
			elseif canShowDeputy and showRate > 0.6 then
				return "show_deputy_general"
			end
		end
	end
	for _, skill in ipairs(followShow) do
		if not self.player:hasShownOneGeneral() then
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasShownSkill(skill) and p:getKingdom() == self.player:getKingdom() then
					if canShowHead and canShowDeputy and showRate > 0.2 then
						return "show_both_generals"
					elseif canShowHead and showRate > 0.2 then
						return "show_head_general"
					elseif canShowDeputy and showRate > 0.2 then
						return "show_deputy_general"
					end
				end
			end
		end
	end

	local showRate2 = math.random()

	if showRate2 > 0.8 then
		if self.player:isDuanchang() then return "show_both_generals" end
		for _, p in ipairs(self.enemies) do
			if p:hasShownSkills("mingshi|huoshui") then return "show_both_generals" end
		end

		if not self.player:hasShownOneGeneral() then
			--local gameProcess = sgs.gameProcess():split(">>") self.player:getKingdom() == gameProcess[1]
			if string.find(sgs.gameProcess(), self.player:getKingdom() .. ">>") and (self.player:getLord() or sgs.shown_kingdom[self.player:getKingdom()] < self.player:aliveCount() / 2) then
				if showRate2 > 0.6 and self.player:getPhase() == sgs.Player_RoundStart then return "show_both_generals" end
			end
		end
	end
	
	if string.find(choices, "cancel") then
		return "cancel"
	elseif canShowDeputy then
		return "show_deputy_general"
	elseif canShowHead then
		return "show_head_general"
	end
end

--变身君主
sgs.ai_skill_choice["changetolord"] = function(self, choices, data)
	Global_room:writeToConsole(self.player:objectName().. ":变身君主选择" .. choices)
	return "yes"
end

--查看下家的副将
function sgs.viewNextPlayerDeputy()
	if sgs.GetConfig("ViewNextPlayerDeputyGeneral", true) then
		for _, player in sgs.qlist(Global_room:getPlayers()) do
			local np = player:getNextAlive()
			np:setMark(("KnownBoth_%s_%s"):format(player:objectName(), np:objectName()), 1)
			local names = {}
			if player:getTag("KnownBoth_" .. np:objectName()):toString() ~= "" then
				names = player:getTag("KnownBoth_" .. np:objectName()):toString():split("+")
			else
				if np:hasShownGeneral1() then
					table.insert(names, np:getActualGeneral1Name())
				else
					table.insert(names, "anjiang")
				end
				if np:hasShownGeneral2() then
					table.insert(names, np:getActualGeneral2Name())
				else
					table.insert(names, "anjiang")
				end
			end
			names[2] = np:getActualGeneral2Name()
			player:setTag("KnownBoth_" .. np:objectName(), sgs.QVariant(table.concat(names, "+")))
			Global_room:writeToConsole(player:objectName().."查看下家的副将:"..table.concat(names, "+"))
			if not np:hasShownOneGeneral() then--不知道为什么AI观看了下家同势力暗将还优先打(查看下家副将的AI并不一定触发……)
				local general2 = sgs.Sanguosha:getGeneral(names[2])
				local kingdom = player:getKingdom()
				if general2:isDoubleKingdoms() then 
					local double_kingdoms = general2:getKingdoms()
					local intention = (table.contains(double_kingdoms, kingdom) and -30 or 80)
					sgs.updateIntention(np, player, intention)
				else
					local np_kingdom = general2:getKingdom()
					local intention = (kingdom == np_kingdom and -80 or 80)
					sgs.updateIntention(np, player, intention)
				end
			end
		end
	end
end

--鏖战桃
local aozhan_skill = {}
aozhan_skill.name = "aozhan"
table.insert(sgs.ai_skills, aozhan_skill)
aozhan_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local Peach
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Peach") then
			Peach = card
			break
		end
	end
	if not Peach then return nil end
	local suit = Peach:getSuitString()
	local number = Peach:getNumberString()
	local card_id = Peach:getEffectiveId()
	local card_str = ("slash:aozhan[%s:%s]=%d&"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.aozhan = function(card, player, card_place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
		if card:isKindOf("Peach") then
			if class_name == "Slash" then
				return ("slash:aozhan[%s:%s]=%d&"):format(suit, number, card_id)
			elseif class_name == "Jink" then
				return ("jink:aozhan[%s:%s]=%d&"):format(suit, number, card_id)
			end
		end
	end
end

sgs.aozhan_keep_value = {
	Peach = 7,
	Analeptic = 6--鏖战酒需要比闪高吗？
}

--珠联璧合标记
local companion_skill = {}
companion_skill.name = "companion"
table.insert(sgs.ai_skills, companion_skill)
companion_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@companion") < 1 then return end
	return sgs.Card_Parse("@CompanionCard=.&")
end

sgs.ai_skill_use_func.CompanionCard= function(card, use, self)
	--Global_room:writeToConsole("珠联璧合判断开始")
	local card_str = ("@CompanionCard=.&_companion")
	local nofreindweak = true
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			nofreindweak = false
		end
	end
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak and sgs.cloneCard("peach"):isAvailable(self.player) then
		--Global_room:writeToConsole("桃回复")
		use.card = sgs.Card_Parse(card_str)
		return
	end
--暂不考虑摸牌
--[[如何获取当前或上一张杀的目标？可参考野心家标记补牌
	情况1：能出杀，预测杀目标血量为1且无闪或手牌小于等于2
	情况2：敌方目标血量为1且自身或团队状态良好，有桃
]]--
end

sgs.ai_skill_choice["companion"] = function(self, choices)
	return "peach"
end

function sgs.ai_cardsview.companion(self, class_name, player, cards)
	if class_name == "Peach" then
		if player:getMark("@companion") > 0 and not player:hasFlag("Global_PreventPeach") then
			--Global_room:writeToConsole("珠联璧合标记救人")
			return "@CompanionCard=.&_companion"
		end
	end
end

sgs.ai_card_intention.CompanionCard = -140
sgs.ai_use_priority.CompanionCard= 0.1

--阴阳鱼标记
sgs.ai_skill_choice.halfmaxhp = function(self, choices)
	local can_tongdu = false
	local can_guzheng = false
	local liuba = sgs.findPlayerByShownSkillName("tongdu")
	if liuba and self.player:isFriendWith(liuba) then
		can_tongdu = true
	end
	local erzhang = sgs.findPlayerByShownSkillName("guzheng")
	if erzhang and self.player:isFriendWith(erzhang) then
		can_guzheng = true
		local jiaxu = sgs.findPlayerByShownSkillName("wansha")
		if jiaxu and self:isEnemy(jiaxu) and self.player:getHp() <= 2 and self:isWeak() and not self:isWeak(erzhang) then
		else return "no" end
	end
	if not self:isWeak() and #self.friends_noself > 0 and self.player:hasSkill("lirang") then
		--(self.player:hasShownSkill("zhiwei")--至微队友
		return "no"
	end
	if (self.player:getHandcardNum() - self.player:getMaxCards()) > (can_guzheng and 2 or 1) + (can_tongdu and 3 or 0) then
		return "yes"
	end
	return "no"
end

local halfmaxhp_skill = {}
halfmaxhp_skill.name = "halfmaxhp"
table.insert(sgs.ai_skills, halfmaxhp_skill)
halfmaxhp_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@halfmaxhp") < 1 then return end
	return sgs.Card_Parse("@HalfMaxHpCard=.&")
end

sgs.ai_skill_use_func.HalfMaxHpCard= function(card, use, self)
	--Global_room:writeToConsole("阴阳鱼摸牌判断开始")
	if self.player:isKongcheng() and self:isWeak() and not self:needKongcheng() and self.player:getMark("@firstshow") < 1 then
		use.card = card
		return
	end
	if self.player:hasSkill("dingke") and self.player:getMark("@halfmaxhp") > 1 then--技能定科
		use.card = card
		return
	end
	--暂不考虑找进攻牌
end

sgs.ai_use_priority.HalfMaxHpCard = 0

--先驱标记
local firstshow_skill = {}
firstshow_skill.name = "firstshow"
table.insert(sgs.ai_skills, firstshow_skill)
firstshow_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@firstshow") < 1 then return end
	return sgs.Card_Parse("@FirstShowCard=.&")
end

sgs.ai_skill_use_func.FirstShowCard= function(card, use, self)
	sgs.ai_use_priority.FirstShowCard = 0.1--挟天子之前
	--Global_room:writeToConsole("先驱判断开始")
	local target
	local not_shown = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not p:hasShownAllGenerals() then
			table.insert(not_shown, p)
		end
	end
	if #not_shown > 0 then
		for _, p in ipairs(not_shown) do
			if not self:isFriend(p) and not self:isEnemy(p) then
				target = p
				break
			end
		end
		if not target then
			for _, p in ipairs(not_shown) do
				if not p:hasShownOneGeneral() and self:isEnemy(p) then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in ipairs(not_shown) do
				if self:isFriend(p) and not p:hasShownGeneral1() then
					target = p
					break
				end
			end
		end
		if not target then
			target = not_shown[1]
		end
	end

	if (self.player:getHandcardNum() < 2 and self:slashIsAvailable())
	or (math.min(self.player:getMaxCards(), 4) - self.player:getHandcardNum() > 2) then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			local dummy_use = { isDummy = true }
			if c:isKindOf("BasicCard") then
				self:useBasicCard(c, dummy_use)
			elseif c:isKindOf("EquipCard") then
				self:useEquipCard(c, dummy_use)
			elseif c:isKindOf("TrickCard") then
				self:useTrickCard(c, dummy_use)
			end
			if dummy_use.card then
				return--先用光牌
			end
		end
		sgs.ai_use_priority.FirstShowCard = 2.4--杀之后
		use.card = card
		if target and use.to then
			use.to:append(target)
		end
		return
	end

	local freindisweak = false
	for _, friend in ipairs(self.friends) do
		if friend:getHp() == 1 and self:isWeak(friend) then
			freindisweak = true
			break
		end
	end
	if self.player:getHandcardNum() <= 2 and self:getCardsNum("Peach") == 0 and freindisweak then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			local dummy_use = { isDummy = true }
			if c:isKindOf("BasicCard") then
				self:useBasicCard(c, dummy_use)
			elseif c:isKindOf("EquipCard") then
				self:useEquipCard(c, dummy_use)
			elseif c:isKindOf("TrickCard") then
				self:useTrickCard(c, dummy_use)
			end
			if dummy_use.card then
				return--先用光牌
			end
		end
		sgs.ai_use_priority.FirstShowCard = 0.9--桃之后
		use.card = card
		if target and use.to then
			use.to:append(target)
		end
		return
	end
end

sgs.ai_skill_choice["firstshow_see"] = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "head_general") then
		return "head_general"
	end
	return choices[#choices]
end

sgs.ai_choicemade_filter.skillChoice.firstshow_see = function(self, from, promptlist)
	local choice = promptlist[#promptlist]
	for _, to in sgs.qlist(self.room:getOtherPlayers(from)) do
		if to:hasFlag("XianquTarget") then
			to:setMark(("KnownBoth_%s_%s"):format(from:objectName(), to:objectName()), 1)
			local names = {}
			if from:getTag("KnownBoth_" .. to:objectName()):toString() ~= "" then
				names = from:getTag("KnownBoth_" .. to:objectName()):toString():split("+")
			else
				if to:hasShownGeneral1() then
					table.insert(names, to:getActualGeneral1Name())
				else
					table.insert(names, "anjiang")
				end
				if to:hasShownGeneral2() then
					table.insert(names, to:getActualGeneral2Name())
				else
					table.insert(names, "anjiang")
				end
			end
			if choice == "head_general" then
				names[1] = to:getActualGeneral1Name()
			else
				names[2] = to:getActualGeneral2Name()
			end
			from:setTag("KnownBoth_" .. to:objectName(), sgs.QVariant(table.concat(names, "+")))
			Global_room:writeToConsole(from:objectName().."先驱查看暗将:"..table.concat(names, "+"))
			break
		end
	end
end

--野心家标记
local careerman_skill = {}
careerman_skill.name = "careerman"
table.insert(sgs.ai_skills, careerman_skill)
careerman_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@careerist") < 1 then return end
	--Global_room:writeToConsole("野心家标记生成")
	return sgs.Card_Parse("@CareermanCard=.&")
end

sgs.ai_skill_use_func.CareermanCard= function(card, use, self)
	sgs.ai_use_priority.CareermanCard = 0.1--挟天子之前
	self.careerman_case = 2--记录选择情况
	--Global_room:writeToConsole("野心家标记判断开始")
	local card_str = ("@CareermanCard=.&_careerman")
	local nofreindweak = true
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			nofreindweak = false
		end
	end
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak and sgs.cloneCard("peach"):isAvailable(self.player) then
		--Global_room:writeToConsole("野心家标记回复")
		self.careerman_case = 3
		use.card = sgs.Card_Parse(card_str)
		return
	end
	if self.player:getHandcardNum() <= 1 and self:slashIsAvailable()
	or (math.min(self.player:getMaxCards(), 4) - self.player:getHandcardNum() > 3) then
		local should_draw = false
		local dummy_slash = { isDummy = true, to = sgs.SPlayerList() }
		local slash = sgs.cloneCard("slash")
		self:useCardSlash(slash, dummy_slash)
		if use.card and use.to then
			for _, p in sgs.qlist(use.to) do
				if p:getHp() == 1 and self:isWeak(p) and sgs.getDefenseSlash(p, self) < 2 then
					should_draw = true
					break
				end
			end
		end
		if should_draw then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				local dummy_use = { isDummy = true }
				if c:isKindOf("BasicCard") then
					self:useBasicCard(c, dummy_use)
				elseif c:isKindOf("EquipCard") then
					self:useEquipCard(c, dummy_use)
				elseif c:isKindOf("TrickCard") then
					self:useTrickCard(c, dummy_use)
				end
				if dummy_use.card then
					return--先用光牌
				end
			end
			sgs.ai_use_priority.CareermanCard = 2.4--杀之后
			--Global_room:writeToConsole("野心家标记补牌")
			self.careerman_case = 4
			use.card = card
			return
		end
	end
	--暂时不考虑摸2牌
end

--[[
	all_choices << "draw1card" << "draw2cards" << "peach" << "firstshow";
	对应self.careerman_case 1 2 3 4 有必要可以加入table.indexOf判断
]]--

sgs.ai_skill_choice["careerman"] = function(self, choices)
	if self.careerman_case == 3 then
		return "peach"
	end
	if self.careerman_case == 4 then
		return "firstshow"
	end
	return "draw2cards"--默认情况case2
end

sgs.ai_skill_playerchosen["careerman"] = function(self, targets)
	local not_shown = sgs.QList2Table(targets)
	local target
	for _, p in ipairs(not_shown) do
		if not self:isFriend(p) and not self:isEnemy(p) then
			target = p
			break
		end
	end
	if not target then
		for _, p in ipairs(not_shown) do
			if not p:hasShownOneGeneral() and self:isEnemy(p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(not_shown) do
			if self:isFriend(p) and not p:hasShownGeneral1() then
				target = p
				break
			end
		end
	end
	if not target then
		target = not_shown[1]
	end
	return target
end

function sgs.ai_cardsview.careerman(self, class_name, player, cards)
	if class_name == "Peach" then
		if player:getMark("@careerist") > 0 and not player:hasFlag("Global_PreventPeach") then
			--Global_room:writeToConsole("野心家标记救人")
			return "@CareermanCard=.&_careerman"
		end
	end
end

sgs.ai_card_intention.CareermanCard = -140

--暴露野心
sgs.ai_skill_choice["GameRule:CareeristShow"]= function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "yes") then
		return "yes"
	end
	return "no"
end

--拉拢人心
sgs.ai_skill_choice["GameRule:CareeristSummon"]= function(self, choices)
	return "yes"
end

sgs.ai_skill_choice["GameRule:CareeristAdd"]= function(self, choices)
	return math.random(1, 3) > 1 and "no" or "yes"
end

--锁定技明置主将的武将牌
local showhead_skill = {}
showhead_skill.name = "showhead"
table.insert(sgs.ai_skills, showhead_skill)
showhead_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasShownGeneral1() and self.player:canShowGeneral("h") then
		local show_position = self:getGeneralShowOrHide(self.player,true,true)
		if not show_position or not string.find(show_position, "head") then return end
		local skills = sgs.QList2Table(self.player:getHeadSkillList(true,true,false))
		local canshow = false
		for _, skill in ipairs(skills) do
			if skill:getFrequency() == sgs.Skill_Compulsory then
				canshow = true
				break
			end
		end
		if canshow then
			return sgs.Card_Parse("@ShowHeadCard=.&")
		end
	end
end

sgs.ai_skill_use_func.ShowHeadCard= function(card, use, self)
	--Global_room:writeToConsole("明置主将的武将牌")
	sgs.ai_use_priority.ShowHeadCard = 2--优先度多少合适？
	if self.player:getActualGeneral1():getKingdom() == "careerist" and self.player:hasSkill("xuanhuoattach") and not self.player:hasUsed("XuanhuoAttachCard") then
		return
	end
	if (self.player:inHeadSkills("paoxiao")) and self:getCardsNum("Slash") == 0 then
		return
	end
	if self:willShowForAttack() or self:willShowForDefence() then
		if self.player:getActualGeneral1():getKingdom() == "careerist" then
			sgs.ai_use_priority.ShowHeadCard = 5.5
		end
		use.card = card
	end
end

--锁定技明置副将的武将牌
local showdeputy_skill = {}
showdeputy_skill.name = "showdeputy"
table.insert(sgs.ai_skills, showdeputy_skill)
showdeputy_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getGeneral2() and not self.player:hasShownGeneral2() and self.player:canShowGeneral("d") then
		local show_position = self:getGeneralShowOrHide(self.player,true,true)
		if not show_position or not string.find(show_position, "deputy") then return end
		local skills = sgs.QList2Table(self.player:getDeputySkillList(true,true,false))
		local canshow = false
		for _, skill in ipairs(skills) do
			if skill:getFrequency() == sgs.Skill_Compulsory then
				canshow = true
				break
			end
		end
		if canshow then
			return sgs.Card_Parse("@ShowDeputyCard=.&")
		end
	end
end

sgs.ai_skill_use_func.ShowDeputyCard= function(card, use, self)
	--Global_room:writeToConsole("明置副将的武将牌")
	if (self.player:inDeputySkills("paoxiao") or self.player:inDeputySkills("baolie"))
	and self:getCardsNum("Slash") == 0 then
		return
	end
	if self:willShowForAttack() or self:willShowForDefence() then
		use.card = card
	end
end

sgs.ai_use_priority.ShowDeputyCard = 2