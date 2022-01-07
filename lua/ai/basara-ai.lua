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
	if self:needKongcheng(self.player, true) and self.player:getPhase() ~= sgs.Player_Play then return "cancel" end
	return "draw"
end

sgs.ai_skill_invoke["userdefine:changetolord"] = function(self)
	return math.random() < 0.8
end

sgs.ai_skill_choice.companion = function(self, choice, data)
	if ( self:isWeak() or self:needKongcheng(self.player, true) ) and string.find(choice, "recover") then return "recover"
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

		if string.find(choices, "sidi") then return "sidi" end--司敌放置牌
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
				return "shicai"
			end
		end
		if string.find(choices, "wanggui") and not self.player:hasShownAllGenerals() then--华韵打伤害或摸牌
			if #self.enemies > 0 then
				self:sort(self.enemies, "hp")
				for _, p in ipairs(self.enemies) do
					if self:isWeak(p) then
						Global_room:writeToConsole("望归优先")
						return "wanggui"
					end
				end
			end
		end
		if string.find(choices, "jieming") then return "jieming" end--先发动节命
		if string.find(choices, "zhiyu") then return "zhiyu" end--先发动智愚亮牌
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

		if string.find(choices, "anyong") then--暗涌后翻倍
			for _, name in ipairs(skillnames) do
				if name ~= "anyong" then
					return name
				end
			end
		end

		if string.find(choices, "luoshen") and string.find(choices, "guanxing") then return "guanxing" end
		if string.find(choices, "qianxi") and sgs.ai_skill_invoke.qianxi(sgs.ais[self.player:objectName()]) then return "qianxi" end
		if string.find(choices, "luoshen") then return "luoshen" end--洛神
		if string.find(choices, "jieyue") then return "jieyue" end--节钺
		if string.find(choices, "elitegeneralflag") then return "elitegeneralflag" end--五子良将纛可以暗求安函放掉血

		if string.find(choices, "wuxin") then return "wuxin" end--悟心
		if string.find(choices, "haoshi") then return "haoshi" end
		if string.find(choices, "zisui") then return "zisui" end--公孙渊摸牌，可能就配合和张辽会触发

		if string.find(choices, "tieqi") or string.find(choices, "liegong")--有_xh后缀也会find到
		or string.find(choices, "tieqi_xh") or string.find(choices, "liegong_xh")
		or string.find(choices, "jianchu") or string.find(choices, "wushuang") then
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
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") ~= 0) then
			canShowHead = false
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
			--local gameProcess = sgs.gameProcess():split(">>") self.player:getKingdom() == gameProcess[1]
			if string.find(sgs.gameProcess(), self.player:getKingdom() .. ">>") and (self.player:getLord() or sgs.shown_kingdom[self.player:getKingdom()] < self.player:aliveCount() / 2) then
				if canShowHead and showRate2 > 0.6 then return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate2 > 0.6 then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
	--end
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

sgs.ai_skill_invoke.GameRule_AskForArraySummon = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_invoke.SiegeSummon = true
sgs.ai_skill_invoke["SiegeSummon!"] = false

sgs.ai_skill_invoke.FormationSummon = true
sgs.ai_skill_invoke["FormationSummon!"] = false

--每回合明置
sgs.ai_skill_choice.GameRule_AskForGeneralShow = function(self, choices)

	local canShowHead = string.find(choices, "show_head_general")
	local canShowDeputy = string.find(choices, "show_deputy_general")

	local firstShow = ("luanji|niepan|bazhen|qianhuan|jianglve|jinghe"):split("|")
	local bothShow = ("luanji+shuangxiong|luanji+huoshui|guanxing+yizhi"):split("|")
	local followShow = ("qianhuan|duoshi|rende|cunsi|jieyin|xiongyi"):split("|")

	if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") == 1 and canShowHead then--君主
		if self.player:inHeadSkills("rende") or self.player:inHeadSkills("guidao")
			or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("jianxiong") then
				return "show_both_generals"
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
			canShowHead = false
		end
	end
	if self.player:inHeadSkills("baoling") then
		if (self.player:hasSkill("mingshi") and allshown >= (self.room:alivePlayerCount() - 1))
			or (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") == 0)
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") == 0) then
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

	if self.player:getMark("#congcha") > 0 then--聪察队友
		--Global_room:writeToConsole("聪察:有标记")
		local panjun = sgs.findPlayerByShownSkillName("congcha")
		if panjun and self.player:willBeFriendWith(panjun) then--暗置只能用willBeFriendWith
			--Global_room:writeToConsole("聪察:队友明置")
			return "show_both_generals"
		elseif panjun and self.player:getActualGeneral2():getKingdom() == panjun:getKingdom() and canShowDeputy then--野心家
			return "show_deputy_general"
		elseif self.player:getHp() == 1 and (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0) then
			--Global_room:writeToConsole("聪察:敌方不明置")
			return "cancel"
		end
	end

	if self.player:hasTreasure("JadeSeal") then
		if not self.player:hasShownOneGeneral() then
			if canShowHead then
				return "show_head_general"
			elseif canShowDeputy then
				return "show_deputy_general"
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
				if showRate2 > 0.6 then return "show_both_generals" end
			end
		end
	end

	return "cancel"
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
			Global_room:writeToConsole(np:objectName().."查看下家的副将:"..table.concat(names, "+"))
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
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak then
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
	local liuba = sgs.findPlayerByShownSkillName("tongdu")
	if liuba and self.player:isFriendWith(liuba) then
		can_tongdu = true
	end
	if (self.player:getHandcardNum() - self.player:getMaxCards()) > 1 + (can_tongdu and 3 or 0) then
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

	if self.player:getHandcardNum() <= 1 and self:slashIsAvailable() then
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
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak then
		--Global_room:writeToConsole("野心家标记回复")
		self.careerman_case = 3
		use.card = sgs.Card_Parse(card_str)
		return
	end
	if self.player:getHandcardNum() <= 1 and self:slashIsAvailable() then
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
	if (self.player:inHeadSkills("paoxiao") or self.player:inHeadSkills("kuangcai")) and self:getCardsNum("Slash") == 0 then
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
	if (self.player:inDeputySkills("paoxiao") or self.player:inDeputySkills("baolie") or self.player:inDeputySkills("kuangcai"))
	and self:getCardsNum("Slash") == 0 then
		return
	end
	if self:willShowForAttack() or self:willShowForDefence() then
		use.card = card
	end
end

sgs.ai_use_priority.ShowDeputyCard = 2