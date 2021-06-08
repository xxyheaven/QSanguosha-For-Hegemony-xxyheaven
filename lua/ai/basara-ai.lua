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
		local ed, no = 0
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


sgs.ai_skill_choice["GameRule:TriggerOrder"] = function(self, choices, data)
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
			for _,p in sgs.qlist(self.room:getOtherPlayers(player)) do
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

	local skillTrigger = false
	local skillnames = choices:split("+")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowHead")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowDeputy")
	table.removeOne(skillnames, "cancel")
	if #skillnames ~= 0 then
		skillTrigger = true
	end

	if skillTrigger then
		if string.find(choices, "jieming") then return "jieming" end
		if string.find(choices, "wangxi") and string.find(choices, "fankui") then 
			local from = data:toDamage().from
			if from and from:isNude() then return "wangxi" end
		end
		if table.contains(skillnames, "fankui") and table.contains(skillnames, "ganglie") then return "fankui" end
		if string.find(choices, "wangxi") and table.contains(skillnames, "ganglie") then return "ganglie" end
		if string.find(choices, "luoshen") and string.find(choices, "guanxing") then return "guanxing" end
		if string.find(choices, "wangxi") and string.find(choices, "fangzhu") then return "fangzhu" end
		if string.find(choices, "qianxi") and sgs.ai_skill_invoke.qianxi(sgs.ais[self.player:objectName()]) then return "qianxi" end

		if table.contains(skillnames, "tiandu") then
			local judge = data:toJudge()
			if judge.card:isKindOf("Peach") or judge.card:isKindOf("Analeptic") then
				return "tiandu"
			end
		end
		if table.contains(skillnames, "yiji") then return "yiji" end
		if table.contains(skillnames, "haoshi") then return "haoshi" end

		local except = {}
		for _, skillname in ipairs(skillnames) do
			local invoke = self:askForSkillInvoke(skillname, data)
			if invoke == true then
				return skillname
			elseif invoke == false then
				table.insert(except, skillname)
			end
		end
		if string.find(choices, "cancel") and not canShowHead and not canShowDeputy and not self.player:hasShownOneGeneral() then
			return "cancel"
		end
		table.removeTable(skillnames, except)

		if #skillnames > 0 then return skillnames[math.random(1, #skillnames)] end
	end

	return "cancel"
end

sgs.ai_skill_choice["GameRule:TurnStart"] = function(self, choices, data)
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")
	local choice = sgs.ai_skill_choice["GameRule:TriggerOrder"](self, choices, data)
	if choice == "cancel" then
		local showRate = math.random()

		if canShowHead and showRate > 0.8 then
			if self.player:isDuanchang() then return "GameRule_AskForGeneralShowHead" end
			for _, p in ipairs(self.enemies) do
				if p:hasShownSkills("mingshi|huoshui") then return "GameRule_AskForGeneralShowHead" end
			end
		elseif canShowDeputy and showRate > 0.8 then
			if self.player:isDuanchang() then return "GameRule_AskForGeneralShowDeputy" end
			for _, p in ipairs(self.enemies) do
				if p:hasShownSkills("mingshi|huoshui") then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
		if not self.player:hasShownOneGeneral() then
			local gameProcess = sgs.gameProcess():split(">>")
			if self.player:getKingdom() == gameProcess[1] and (self.player:getLord() or sgs.shown_kingdom[self.player:getKingdom()] < self.player:aliveCount() / 2) then
				if canShowHead and showRate > 0.6 then return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.6 then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
	end
	return choice
end

sgs.ai_skill_choice["armorskill"] = function(self, choice, data)
	local choices = choice:split("+")
	for _, name in ipairs(choices) do
		skill_names = name:split(":")
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

sgs.ai_skill_choice.GameRule_AskForGeneralShow = function(self, choices)

	local canShowHead = string.find(choices, "show_head_general")
	local canShowDeputy = string.find(choices, "show_deputy_general")

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

	for _,p in ipairs(self.friends) do
		if p:hasShownSkill("jieyin") then
			if canShowHead and self.player:getGeneral():isMale() then
				return "show_head_general"
			elseif canShowDeputy and self.player:getGeneral():isFemale() and self.player:getGeneral2():isMale() then
				return "show_deputy_general"
			end
		end
	end

	if self.player:getMark("CompanionEffect") > 0 then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase()) then
			return "show_both_generals"
		end
	end

	if self.player:getMark("HalfMaxHpLeft") > 0 then
		if self:isWeak() and self:willShowForDefence() then
			return "show_both_generals"
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
			for _,p in sgs.qlist(self.room:getOtherPlayers(player)) do
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
			local gameProcess = sgs.gameProcess():split(">>")
			if self.player:getKingdom() == gameProcess[1] and (self.player:getLord() or sgs.shown_kingdom[self.player:getKingdom()] < self.player:aliveCount() / 2) then
				if showRate2 > 0.6 then return "show_both_generals" end
			end
		end
	end

	return "cancel"
end

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
	Peach = 6,
}





sgs.ai_skill_choice.halfmaxhp = function(self, choices)
	if self.player:getHandcardNum() - self.player:getMaxCards() > 1 then
		return "yes"
	end
	return "no"
end





