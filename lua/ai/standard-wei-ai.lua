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
--魏标准版

--曹操
sgs.ai_skill_invoke.jianxiong = function(self, data)
	if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1
	and not self.player:hasShownGeneral1() and self.player:inHeadSkills("jianxiong") and not self:isWeak() then--君主
		return false
	end
	if not self:willShowForMasochism() then return false end
	if self.get_AOE_subcard then self.get_AOE_subcard = nil return true end
	return not self:needKongcheng(self.player, true)
end

--司马懿
sgs.ai_skill_invoke.fankui = function(self, data)
	if not self:willShowForMasochism() then return false end
	local target = data:toDamage().from
	if not target then return end
	if sgs.ai_need_damaged.fankui(self, target, self.player) then return true end

	if self:isFriend(target) then
		if self:getOverflow(target) > 2 then return true end
		if self:doNotDiscard(target) then return true end
		return (target:hasShownSkills(sgs.lose_equip_skill) and not target:getEquips():isEmpty())
		  or (self:needToThrowArmor(target) and target:getArmor()) or self:doNotDiscard(target)
	end
	if self:isEnemy(target) then
		if self:doNotDiscard(target) then return false end
		return true
	end
	return true
end

sgs.ai_choicemade_filter.cardChosen.fankui = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from then
		local intention = 10
		local id = promptlist[3]
		local card = sgs.Sanguosha:getCard(id)
		local target = damage.from
		if self:needToThrowArmor(target) and self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("Armor") then
			intention = -intention
		elseif self:doNotDiscard(target) then intention = -intention
		elseif target:hasShownSkills(sgs.lose_equip_skill) and not target:getEquips():isEmpty() and
			self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("EquipCard") then
				intention = -intention
		elseif sgs.ai_need_damaged.fankui(self, target, player) then intention = 0
		elseif self:getOverflow(target) > 2 then intention = 0
		end
		sgs.updateIntention(player, target, intention)
	end
end

sgs.ai_skill_cardchosen.fankui = function(self, who, flags, method, disable_list)
	local suit = sgs.ai_need_damaged.fankui(self, who, self.player)
	if not suit then return nil end

	local cards = sgs.QList2Table(who:getEquips())
	local handcards = sgs.QList2Table(who:getHandcards())
	if #handcards==1 and handcards[1]:hasFlag("visible") then table.insert(cards,handcards[1]) end

	for i=1,#cards,1 do
		if (cards[i]:getSuit() == suit and suit ~= sgs.Card_Spade) or
			(cards[i]:getSuit() == suit and suit == sgs.Card_Spade and cards[i]:getNumber() >= 2 and cards[i]:getNumber()<=9) then
			return cards[i]
		end
	end
	return nil
end


sgs.ai_need_damaged.fankui = function (self, attacker, player)
	if not player:hasSkill("guicai+fankui") then return false end
	if not attacker then return end
	local need_retrial = function(target)
		local alive_num = self.room:alivePlayerCount()
		return alive_num + target:getSeat() % alive_num > self.room:getCurrent():getSeat()
				and target:getSeat() < alive_num + player:getSeat() % alive_num
	end
	local retrial_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}
	local attacker_card ={["spade"]=nil,["heart"]=nil,["club"]=nil}

	local handcards = sgs.QList2Table(player:getHandcards())
	for i=1,#handcards,1 do
		if handcards[i]:getSuit() == sgs.Card_Spade and handcards[i]:getNumber()>=2 and handcards[i]:getNumber()<=9 then
			retrial_card.spade = true
		end
		if handcards[i]:getSuit() == sgs.Card_Heart then
			retrial_card.heart = true
		end
		if handcards[i]:getSuit() == sgs.Card_Club then
			retrial_card.club = true
		end
	end

	local cards = sgs.QList2Table(attacker:getEquips())
	handcards = sgs.QList2Table(attacker:getHandcards())
	if #handcards==1 and handcards[1]:hasFlag("visible") then table.insert(cards,handcards[1]) end

	for i=1,#cards,1 do
		if cards[i]:getSuit() == sgs.Card_Spade and cards[i]:getNumber()>=2 and cards[i]:getNumber()<=9 then
			attacker_card.spade = sgs.Card_Spade
		end
		if cards[i]:getSuit() == sgs.Card_Heart then
			attacker_card.heart = sgs.Card_Heart
		end
		if cards[i]:getSuit() == sgs.Card_Club then
			attacker_card.club = sgs.Card_Club
		end
	end

	local players = self.room:getOtherPlayers(player)
	for _, aplayer in sgs.qlist(players) do
		if aplayer:containsTrick("lightning") and self:getFinalRetrial(aplayer) ==1 and need_retrial(aplayer) then
			if not retrial_card.spade and attacker_card.spade then return attacker_card.spade end
		end

		if self:isFriend(aplayer, player) and not aplayer:hasShownSkill("qiaobian") then

			if aplayer:containsTrick("indulgence") and self:getFinalRetrial(aplayer) == 1 and need_retrial(aplayer) and aplayer:getHandcardNum() >= aplayer:getHp() then
				if not retrial_card.heart and attacker_card.heart then return attacker_card.heart end
			end
		end
	end
	return false
end


sgs.ai_skill_cardask["@guicai-card"] = function(self, data)
	if not (self:willShowForAttack() or self:willShowForDefence()) then return "." end
	local judge = data:toJudge()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, 1, sgs.Sanguosha:getCard(id))
	end
	if self.player:hasSkill("luoshen") and self.player:hasTreasure("JadeSeal") and judge.reason ~= "lightning" then
		table.removeOne(cards,sgs.Sanguosha:getCard(self.player:getTreasure():getEffectiveId()))--洛神去掉玉玺
	end

	if self:needRetrial(judge) then
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end

	return "."
end

function sgs.ai_cardneed.guicai(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and not self.player:hasShownSkill("hongyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.guicai_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}

--夏侯惇
sgs.ai_skill_invoke.ganglie = function(self, data)
	if not self:willShowForMasochism() then return false end
	local mode = self.room:getMode()
	local damage = data:toDamage()
	if not damage.from then
		local zhangjiao = sgs.findPlayerByShownSkillName("guidao")
		return zhangjiao and self:isFriend(zhangjiao) and not zhangjiao:isNude()
	end
	return not self:isFriend(damage.from)-- and self:canAttack(damage.from)
end

sgs.ai_need_damaged.ganglie = function(self, attacker, player)
	if not attacker then return end
	if self:isEnemy(attacker) and attacker:getHp() + attacker:getHandcardNum() <= 3
		and not (attacker:hasShownSkills(sgs.need_kongcheng .. "|buqu") and attacker:getHandcardNum() > 1) and sgs.isGoodTarget(attacker, self:getEnemies(attacker), self) then
		return true
	end
	return false
end

local function ganglie_discard(self, discard_num, min_num, optional, include_equip, skillName)
	local xiahou = sgs.findPlayerByShownSkillName(skillName)
	if xiahou and (not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, xiahou) or self:needDamagedEffects(self.player, xiahou)) then return {} end
	if xiahou and self:needToLoseHp(self.player, xiahou) then return {} end
	local to_discard = {} --copy from V2
	local cards = sgs.QList2Table(self.player:getHandcards())
	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and self:getOverflow() <= 0 then return {} end
	self:sortByKeepValue(cards, true)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == 2 then break end
		end
	end
	if #to_discard < 2 then return {}
	else
		return to_discard
	end
end

sgs.ai_skill_discard.ganglie = function(self, discard_num, min_num, optional, include_equip)
	return ganglie_discard(self, discard_num, min_num, optional, include_equip, "ganglie")
end

function sgs.ai_slash_prohibit.ganglie(self, from, to)
	if self:isFriend(from, to) then return false end
	if from:hasShownSkills("tieqi|tieqi_xh|yinbing") then return false end
	return from:getHandcardNum() + from:getHp() < 4
end

sgs.ai_choicemade_filter.skillInvoke.ganglie = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			if not self:needDamagedEffects(damage.from, player) and not self:needToLoseHp(damage.from, player) then
				sgs.updateIntention(damage.to, damage.from, 40)
			end
		elseif self:canAttack(damage.from) then
			sgs.updateIntention(damage.to, damage.from, -40)
		end
	end
end

--张辽
function SmartAI:findTuxiTarget(max_num)
	local targets = {}
	max_num = max_num or 2--新突袭

	local add_player = function (player, isfriend)
		if player:isKongcheng() or player:objectName() == self.player:objectName() then return #targets end
		if #targets < max_num then
			if not table.contains(targets, player:objectName()) then
				table.insert(targets, player:objectName())
			end
		end
		if isfriend and isfriend == 1 then
			self.player:setFlags("tuxi_isfriend_"..player:objectName())
		end
		return #targets
	end

	local zhugeliang = sgs.findPlayerByShownSkillName("kongcheng")
	if zhugeliang and self:isFriend(zhugeliang) and sgs.ai_explicit[zhugeliang:objectName()] ~= "unknown" and zhugeliang:getHandcardNum() == 1
		and self:getEnemyNumBySeat(self.player,zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang, 1) == max_num then return targets end
		else
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and sgs.cardIsVisible(cards[1], zhugeliang, self.player) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang, 1) == max_num then return targets end
				end
			end
		end
	end

	self:sort(self.enemies, "handcard_defense")
	for _, enemy in ipairs(self.enemies) do
		local cards = sgs.QList2Table(enemy:getHandcards())
		for _, card in ipairs(cards) do
			if sgs.cardIsVisible(card, enemy, self.player) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
				if add_player(enemy) == max_num  then return targets end
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:hasShownSkills(sgs.notActive_cardneed_skill) then
			if add_player(enemy) == max_num then return targets end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:hasShownSkills(sgs.Active_cardneed_skill) then
			if add_player(enemy) == max_num then return targets end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local x = enemy:getHandcardNum()
		local good_target = true
		if x == 1 and self:needKongcheng(enemy) then good_target = false end
		if x >= 2 and enemy:hasShownSkill("tuntian") then good_target = false end
		if good_target and add_player(enemy) == max_num then return targets end
	end

	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not other:hasShownSkill("tuntian") and add_player(other) == max_num then
			return targets
		end
	end

	if #targets > 0 then--新突袭，配合于禁、公孙渊
		return targets
	end
end

--[[
sgs.ai_skill_use["@@tuxi"] = function(self, prompt)
	if not self:willShowForAttack() then
		return "."
	end
	if self.player:getTreasure() and self.player:getTreasure():isKindOf("JadeSeal") then return "." end
	local targets = self:findTuxiTarget()
	if type(targets) == "table" and #targets > 0 then
		return ("@TuxiCard=.&->" .. table.concat(targets, "+"))
	end
	return "."
end
]]

sgs.ai_skill_playerchosen.tuxi = function(self, targets, max_num, min_num)
	local tos = self:findTuxiTarget(max_num)
	if type(tos) == "table" and #tos > 0 then
		local result = {}
		for _,name in pairs(tos)do
			table.insert(result,self.room:findPlayerbyobjectName(name))
		end
		return result
	end
	return {}
end

--许褚
sgs.ai_skill_discard.luoyi = function(self, discard_num, min_num, optional, include_equip)
	if self.player:isSkipped(sgs.Player_Play) then return {} end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	local dueltarget = 0
	self:sort(self.enemies,"hp")
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") or (self.player:hasWeapon("Spear") and self.player:getCards("h"):length() > 0) then
			for _,enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card, true) and self:slashIsEffective(card, enemy) and self:objectiveLevel(enemy) > 3 and sgs.isGoodTarget(enemy, self.enemies, self) then
					if (not enemy:hasArmorEffect("SilverLion") or self.player:hasWeapon("QinggangSword")) and (getCardsNum("Jink", enemy) < 1
					or (self.player:hasWeapon("Axe") and self.player:getCardCount(true) > 3))
					or (self:getOverflow() > 1)
					then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if card:isKindOf("Duel") then
			for _, enemy in ipairs(self.enemies) do
				if self:getCardsNum("Slash") >= getCardsNum("Slash", enemy, self.player) and sgs.isGoodTarget(enemy, self.enemies, self)
				and not enemy:hasArmorEffect("SilverLion")
				and self:objectiveLevel(enemy) > 3 and self:damageIsEffective(enemy) then
					dueltarget = dueltarget + 1
				end
			end
		end
	end
	if (slashtarget+dueltarget) > 0 then
		--self:speak("luoyi")
		return self:askForDiscard("dummy_reason", discard_num, min_num, false, true)
	end
	return {}
end

function sgs.ai_cardneed.luoyi(to, card, self)
	local target
	local slash = sgs.cloneCard("slash")

	local cards = to:getHandcards()
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		if sgs.cardIsVisible(c, to, self.player) then
			if isCard("Slash", c, to) then
				need_slash = false
				break
			end
		end
	end

	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self:getEnemies(to)) do
		if to:canSlash(enemy) and not self:slashProhibit(slash ,enemy) and self:slashIsEffective(slash, enemy) and sgs.getDefenseSlash(enemy, self) <= 2 then
			target = enemy
			break
		end
	end

	if need_slash and target and isCard("Slash", card, to) then return true end
	return isCard("Duel",card, to) or card:isKindOf("Axe")
end

sgs.luoyi_keep_value = {
	Peach           = 6,
	Analeptic       = 5.8,
	Jink            = 5.2,
	Duel            = 5.5,
	FireSlash       = 5.6,
	Slash           = 5.4,
	ThunderSlash    = 5.5,
	Axe             = 5.9,
	Blade           = 4.6,
	Spear           = 4.9,
	Fan             = 4.8,
	KylinBow        = 4.7,
	Halberd         = 4.9,
	DefensiveHorse  = 4
}

--郭嘉
sgs.ai_skill_invoke.tiandu = function(self, data)
	if not self:willShowForAttack() then
		return false
	end
	local judge = data:toJudge()
	if judge.reason == "tuntian" and judge.card:getSuit() ~= sgs.Card_Heart then
		if judge.card:isKindOf("Peach") then
			return not (self:needKongcheng() and self.player:isKongcheng())
		end
		if judge.card:isKindOf("Analeptic") and self:isWeak() then return not (self:needKongcheng() and self.player:isKongcheng()) end
		return false
	end
	return not (self:needKongcheng() and self.player:isKongcheng())
end

function sgs.ai_slash_prohibit.tiandu(self, from, to)
	if self:canLiegong(to, from) then return false end
	if from:hasShownSkills("tieqi|tieqi_xh|jianchu") then return false end
	if self:isEnemy(to) and self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) and to:hasShownSkill("qingguo") then return true end
	if self:isEnemy(to) and self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) and #self.enemies > 1 then return true end
end

sgs.ai_skill_invoke.yiji = function(self)
	if not self:willShowForMasochism() then return false end
	if self.player:getHandcardNum() < 2 then return true end
	for _, friend in ipairs(self.friends) do
		if not self:needKongcheng(friend, true) then return true end
	end
end

sgs.ai_skill_askforyiji.yiji = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end

	if self.player:getHandcardNum() <= 2 then
		return nil, -1
	end

	local new_friends = {}
	for _, friend in ipairs(self.friends) do
		if not self:needKongcheng(friend, true) then table.insert(new_friends, friend) end
	end

	if #new_friends > 0 then
		local card, target = self:getCardNeedPlayer(cards, new_friends)
		if card and target then
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
			if not card:hasFlag("visible") then card:setFlags(flag) end--记录方便盗书，是否增加主动盗书配合？
			return target, card:getEffectiveId()
		end
		self:sort(new_friends, "defense")
		self:sortByKeepValue(cards, true)
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), new_friends[1]:objectName())
		if not cards[1]:hasFlag("visible") then cards[1]:setFlags(flag) end
		return new_friends[1], cards[1]:getEffectiveId()
	else
		return nil, -1
	end

end

sgs.ai_need_damaged.yiji = function (self, attacker, player)
	if not player:hasShownSkill("yiji") then return end
	local need_card = false
	local current = self.room:getCurrent()
	if self:hasCrossbowEffect(current) or current:hasShownSkill("paoxiao") or current:hasFlag("shuangxiong") then need_card = true end
	if current:hasShownSkills("jieyin|jijiu") and self:getOverflow(current) <= 0 then need_card = true end
	if self:isFriend(current, player) and need_card then return true end

	if #self.friends > 0 then
		self:sort(self.friends, "hp")
		if self.friends[1]:objectName() == player:objectName() and self:isWeak(player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end
		if #self.friends > 1 and self:isWeak(self.friends[2]) then return true end
	end

	return player:getHp() > 2 and sgs.turncount > 2 and #self.friends > 1
end

--甄姬
sgs.ai_view_as.qingguo = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isBlack() and (card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id)) then
		return ("jink:qingguo[%s:%s]=%d&qingguo"):format(suit, number, card_id)
	end
end

function sgs.ai_cardneed.qingguo(to, card)
	return to:getCards("h"):length() < 2 and card:isBlack()
end

sgs.ai_skill_invoke.luoshen = function(self, data)

	if not self:willShowForAttack() and not self:willShowForDefence() and not self.player:hasSkill("fangzhu") then
		return false
	end
	if self:willSkipPlayPhase() then
		local erzhang = sgs.findPlayerByShownSkillName("guzheng")
		if erzhang and self:isEnemy(erzhang) then return false end
	end
	return true
end

sgs.qingguo_suit_value = {
	spade = 4.1,
	club = 4.2
}

sgs.ai_suit_priority.qingguo= "diamond|heart|club|spade"

--夏侯渊
sgs.ai_skill_use["@@shensu1"] = function(self, prompt)

	if not self:willShowForAttack() then return "." end

	if self:getOverflow() <= 1 and self:getCardsNum("Peach") <= self.player:getHp() then
		return "."
	end

	if self.player:containsTrick("lightning") and self.player:getCards("j"):length() == 1
		and self:hasWizard(self.friends) and not self:hasWizard(self.enemies, true) then
		return "."
	end

	if not self.player:containsTrick("indulgence") and not self.player:containsTrick("supply_shortage") then
		if self.player:getTreasure() and self.player:getTreasure():isKindOf("JadeSeal") then return "." end
	end

	local slash = sgs.cloneCard("slash")
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(slash, dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")

	if dummy_use.card and not dummy_use.to:isEmpty() then
		for _, enemy in sgs.qlist(dummy_use.to) do
			if self:isEnemy(enemy) and sgs.getDefenseSlash(enemy, self) < 3 then
				if  enemy:getHp() <= 1 and (not self.player:inMyAttackRange(enemy) or self:getCardsNum("Slash") == 0 or self.player:containsTrick("indulgence")) then
					return "@ShensuCard=.->" .. enemy:objectName()
				end
				if enemy:getHp() <= 2 and self.player:inMyAttackRange(enemy) and self:getCardsNum("Slash") > 0 then
					return "@ShensuCard=.->" .. enemy:objectName()
				end
			end
		end
	end

	local Nullification = false
	for _, p in ipairs(self.friends) do
		if getKnownCard(p, self.player, "Nullification") > 0 then
			Nullification = true
		end
	end
	if self.player:containsTrick("indulgence") and (not self:hasWizard(self.friends) or self:hasWizard(self.enemies, true))
		and not Nullification then
		local target
		if dummy_use.card and not dummy_use.to:isEmpty() then
			for _, enemy in sgs.qlist(dummy_use.to) do
				local def = sgs.getDefenseSlash(enemy, self)
				if def < 3 or (not self:isWeak() and def < 5) then
					target = enemy
					break
				end
			end
		end
		if not target then
			local handcardsValue = 0
			local cards = sgs.QList2Table(self.player:getCards("h"))
			for _, c in ipairs(cards) do
				handcardsValue = handcardsValue + self:getUseValue(c)
			end
			if handcardsValue > 16 or self:getOverflow(self.player, true) > 1 or (handcardsValue > 6 and self:isWeak()) then
				if dummy_use.card and not dummy_use.to:isEmpty() then
					local targets =  sgs.QList2Table(dummy_use.to)
					self:sort(targets, "defenseSlash")
					target = targets[1]
				else
					local targets = sgs.PlayerList()
					for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
						if slash:targetFilter(targets, p, self.player) and not self:slashIsEffective(slash, p) then
							target = p
							break
						end
					end
				end
			end
		end
		if target then return "@ShensuCard=.->" .. target:objectName() end
	end
	return "."
end

local function getEquipType(card)
	if card:isKindOf("OffensiveHorse") then return 1 end
	if card:isKindOf("Weapon") then return 2 end
	if card:isKindOf("DefensiveHorse") then return 3 end
	if card:isKindOf("Armor") then return 4 end
	if card:isKindOf("Treasure") then return 5 end
	if card:isKindOf("SixDragons") then return 6 end
end

sgs.ai_skill_use["@@shensu2"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defenseSlash")

	if not self:willShowForAttack() or self:getOverflow() > 1 then
		return "."
	end

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local eCard
	local hasCard = { 0, 0, 0, 0, 0, 0 }

	if self:needToThrowArmor() and not self.player:isCardLimited(self.player:getArmor(), method) then
		eCard = self.player:getArmor()
	end

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") then
				hasCard[getEquipType(card)] = hasCard[getEquipType(card)] + 1
			end
		end

		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard")
			and (hasCard[getEquipType(card)] > 1
				or (hasCard[6] > 0 and (getEquipType(card) == 2 or getEquipType(card) == 3))) then
				eCard = card
				break
			end
		end

		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and getEquipType(card) < 3 and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not card:isKindOf("Armor") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
	end

	if not eCard then return "." end

	local effectslash, best_target, target, throw_weapon
	local defense = 6
	local weapon = self.player:getWeapon()
	if weapon and eCard:getId() == weapon:getId() and (eCard:isKindOf("Fan") or eCard:isKindOf("QinggangSword")) then throw_weapon = true end

	if self:getOverflow() > 0 and #self:getTurnUse() > 0 then return "." end

	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefenseSlash(enemy, self)
		local slash = sgs.cloneCard("slash")
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if not self.player:canSlash(enemy, slash, false) then
		elseif throw_weapon and enemy:hasArmorEffect("Vine") then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy, self.player) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
	end

	if best_target then return "@ShensuCard=" .. eCard:getEffectiveId() .. "->" .. best_target:objectName() end
	if target then return "@ShensuCard=" .. eCard:getEffectiveId() .. "->" .. target:objectName() end

	return "."
end

sgs.ai_cardneed.shensu = function(to, card, self)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", false) < 2
end

sgs.ai_skill_use["@@shensu3"] = function(self, prompt)
	if not self:willShowForAttack() and not self:willShowForDefence() then return "." end

	local Hp = self.player:getHp()
	local p_num = self:getCardsNum("Peach")
	local a_num = self:getCardsNum("Analeptic")
	if p_num + a_num == 0 and Hp <= 2 then--不考虑紫砂
		return "."
	end

	local over_num = self:getOverflow()
	if over_num <= 0 then return "." end

	local not_loss = false
	if over_num > 1 and self.player:getMark("@halfmaxhp") > 0 then
		over_num = over_num - 2
	end
	if over_num > 0 then
		local cards = self.player:getHandcards()
		cards=sgs.QList2Table(cards)
		self:sortByKeepValue(cards, true)
		for i = 1, over_num, 1 do
			if cards[i]:isKindOf("Peach") or (Hp == 1 and cards[i]:isKindOf("Analeptic")) then
				not_loss = true
				break
			end
		end
	end

	if (over_num > 2 and (Hp > 2 or (Hp == 1 and p_num + a_num > 1)))
	or (over_num > 3 and (Hp + p_num > 2 or (Hp == 1 and p_num + a_num > 0))) then
		not_loss = true
	end

	local slash = sgs.cloneCard("slash")
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(slash, dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")

	if dummy_use.card and not dummy_use.to:isEmpty() then
		local enemies = sgs.QList2Table(dummy_use.to)
		self:sort(enemies, "hp")
		for _, enemy in ipairs(enemies) do
			if self:isEnemy(enemy) and sgs.getDefenseSlash(enemy, self) < 3
			and enemy:getHp() <= 1 and self:isWeak(enemy) and Hp + p_num + a_num > 2 then
				return "@ShensuCard=.->" .. enemy:objectName()
			end
		end

		if not_loss then return "@ShensuCard=.->" .. enemies[1]:objectName() end
	end

	return "."
end

sgs.ai_card_intention.ShensuCard = sgs.ai_card_intention.Slash

sgs.shensu_keep_value = sgs.xiaoji_keep_value

--张郃
--[[参考身份的巧变，后边可加入防止移动的判断，要实现勇进给敌人还得加上to_friends, to_enemies
	function card_for_qiaobian(self, who, return_prompt, flag, to_friends, to_enemies)
	flag = flag or "ej"
	to_friends = to_friends or self.friends
	to_enemies = to_enemies or self.enemies

	复制身份的卡牌移动
function SmartAI:moveField(player, flag, froms, tos)
	player = player or self.player
	froms = froms or self.room:getAlivePlayers()
	tos = tos or self.room:getAlivePlayers()
	flag = flag or "ej"
	--optional = optional or false

	if type(froms) == "table" then
		local players = sgs.SPlayerList()
		for _, p in ipairs(froms) do
			players:append(p)
		end
		froms = players
	end
	if type(tos) == "table" then
		local players = sgs.SPlayerList()
		for _, p in ipairs(tos) do
			players:append(p)
		end
		tos = players
	end

	local from_friends, from_enemies, to_friends, to_enemies = {}, {}, {}, {}
	for _, p in sgs.qlist(froms) do
		if self:isFriend(p) then
			table.insert(from_friends, p)
		else
			table.insert(from_enemies, p)
		end
	end
	for _, p in sgs.qlist(tos) do
		if self:isFriend(p) then
			table.insert(to_friends, p)
		else
			table.insert(to_enemies, p)
		end
	end

	local from_friends_noself = {}
	for _, p in ipairs(from_friends) do
		if p:objectName() == player:objectName() then continue end
		table.insert(from_friends_noself, p)
	end

	self:sort(from_enemies, "defense")
	self:sort(from_friends, "defense")
	self:sort(from_friends_noself, "defense")

	if flag:match("j") then
		for _, friend in ipairs(from_friends) do
			if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") and card_for_qiaobian(self, friend, ".", flag, to_friends, to_enemies) then
				return friend, card_for_qiaobian(self, friend, "card", flag, to_friends, to_enemies), card_for_qiaobian(self, friend, "target", flag, to_friends, to_enemies)
			end
		end
		for _, enemy in ipairs(from_enemies) do
			if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and card_for_qiaobian(self, enemy, ".", flag, to_friends, to_enemies) then
				return enemy, card_for_qiaobian(self, enemy, "card", flag, to_friends, to_enemies), card_for_qiaobian(self, enemy, "target", flag, to_friends, to_enemies)
			end
		end
	end

	if flag:match("e") then
		for _, friend in ipairs(from_friends_noself) do
			if not friend:getCards("e"):isEmpty() and self:hasKnownSkills(sgs.lose_equip_skill, friend) and card_for_qiaobian(self, friend, ".", flag, to_friends, to_enemies) then
				return friend, card_for_qiaobian(self, friend, "card", flag, to_friends, to_enemies), card_for_qiaobian(self, friend, "target", flag, to_friends, to_enemies)
			end
		end
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if not self:hasKnownSkills(sgs.lose_equip_skill, enemy) and card_for_qiaobian(self, enemy, ".", flag, to_friends, to_enemies) then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			return targets[1], card_for_qiaobian(self, targets[1], "card", flag, to_friends, to_enemies), card_for_qiaobian(self, targets[1], "target", flag, to_friends, to_enemies)
		end
	end
	return nil
end
]]--

function SmartAI:getMoveCardorTarget(who, return_prompt, flag)--原巧变修改成通用函数
	flag = flag or "ej"
	local card, target
	if self:isFriend(who) then
		if flag:match("j") then
			local judges = who:getJudgingArea()
			if not judges:isEmpty() then
				for _, judge in sgs.qlist(judges) do
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and self:trickIsEffective(judge, enemy, self.player) then
							target = enemy
							break
						end
					end
					if not target then
						for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
							if not self:isFriend(enemy) and not enemy:containsTrick(judge:objectName()) and self:trickIsEffective(judge, enemy, self.player) then
								target = enemy
								break
							end
						end
					end
					if not target then
						for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
							if not self.player:isFriendWith(enemy) and not enemy:containsTrick(judge:objectName()) and self:trickIsEffective(judge, enemy, self.player) then
								target = enemy
								break
							end
						end
					end
					if target then break end
				end
			end
		end
		if flag:match("e") then
			local equips = who:getCards("e")
			if not target and not equips:isEmpty() and who:hasShownSkills(sgs.lose_equip_skill) then
				for _, equip in sgs.qlist(equips) do
					if equip:isKindOf("OffensiveHorse") then card = equip break
					elseif equip:isKindOf("Weapon") then card = equip break
					elseif equip:isKindOf("Treasure") then card = equip break
					elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
						card = equip
						break
					elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
						card = equip
						break
					end
				end

				if card then
					if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
						self:sort(self.friends, "defense")
					else
						self:sort(self.friends, "handcard", true)
					end
					for _, friend in ipairs(self.friends) do
						if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and friend:hasShownSkills(sgs.need_equip_skill) and self.player:isFriendWith(friend) then
							target = friend
							break
						end
					end
					if not target then
						for _, friend in ipairs(self.friends) do
							if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
							and self.player:isFriendWith(friend) then
								target = friend
								break
							end
						end
					end
					if not target then
						for _, friend in ipairs(self.friends) do
							if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
								and friend:hasShownSkills(sgs.need_equip_skill) then
									target = friend
									break
							end
						end
					end
					if not target then
						for _, friend in ipairs(self.friends) do
							if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
								target = friend
								break
							end
						end
					end
				end
			end
		end
	else
		if flag:match("e") then
			if not card  or not target then
				if not who:hasEquip() or who:hasShownSkills(sgs.lose_equip_skill) then return nil end
				local card_id = self:askForCardChosen(who, "e", "move")
				if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end
				if card then
					if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
						self:sort(self.friends, "defense")
					else
						self:sort(self.friends, "handcard", true)
					end
					for _, friend in ipairs(self.friends) do
						if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and friend:hasShownSkills(sgs.need_equip_skill) and self.player:isFriendWith(friend) then
							target = friend
							break
						end
					end
					if not target then
						for _, friend in ipairs(self.friends) do
							if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
							and self.player:isFriendWith(friend) then
								target = friend
								break
							end
						end
					end
					if not target then
						for _, friend in ipairs(self.friends) do
							if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
								and friend:hasShownSkills(sgs.need_equip_skill) then
									target = friend
									break
							end
						end
					end
					if not target then
						for _, friend in ipairs(self.friends) do
							if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
								target = friend
								break
							end
						end
					end
				end
			end
		end
		if flag:match("j") then
			--暂时不考虑移动敌人的判定牌，虽然可能有移动判定牌给更合适目标的情况
			--local judges = who:getJudgingArea()
		end
	end

	if return_prompt == "card" then return card
	elseif return_prompt == "target" then return target
	else
		return (card and target)
	end
end

sgs.ai_skill_cardchosen.qiaobian = function(self, who, flags, method, disable_list)
	if flags == "ej" then
		return self:getMoveCardorTarget(who, "card")
	end
end

sgs.ai_skill_discard.qiaobian = function(self, discard_num, min_num, optional, include_equip)
	local current_phase = self.player:getMark("qiaobianPhase")
	local to_discard = {}
	self:updatePlayers()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local stealer
	for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if ap:hasShownSkills("tuxi|tuxi_egf") and self:isEnemy(ap) then stealer = ap end
	end
	local card
	for i = 1, #cards, 1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			if stealer and self.player:getHandcardNum() <= 2 and self.player:getHp() > 2 and not stealer:containsTrick("supply_shortage") then
				card = cards[i]
				break
			end
			local to_discard_peach = true
			for _,fd in ipairs(self.friends) do
				if fd:getHp() <= 2 and not fd:hasShownSkill("niepan") then
					to_discard_peach = false
				end
			end
			if to_discard_peach then
				card = cards[i]
				break
			end
		else
			card = cards[i]
			break
		end
	end
	if not card then return {} end
	if not self:willShowForAttack() then
		return {}
	end
	table.insert(to_discard, card:getEffectiveId())

	if current_phase == sgs.Player_Judge and not self.player:isSkipped(sgs.Player_Judge) then
		if (self.player:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
			or (self.player:containsTrick("lightning") and #self.friends > #self.enemies) then
			return to_discard
		elseif self.player:containsTrick("supply_shortage") then
			if self.player:getHp() > self.player:getHandcardNum() then return to_discard end
			local targets = self:findTuxiTarget()
			if type(targets) == "table" and #targets == 2 then
				return to_discard
			end
		elseif self.player:containsTrick("indulgence") then
			if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return to_discard end
			for _, friend in ipairs(self.friends_noself) do
				if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
					return to_discard
				end
			end
		end
	elseif current_phase == sgs.Player_Draw and not self.player:isSkipped(sgs.Player_Draw) and not self.player:hasShownSkills("tuxi|tuxi_egf") then
		if self.player:getTreasure() and self.player:getTreasure():isKindOf("JadeSeal") then return {} end
		if self.player:getMark("JieyueExtraDraw") > 0 or self.player:hasSkill("zisui") then return {} end--新增配合于禁、公孙渊
		self.qiaobian_draw_targets = {}
		local targets = self:findTuxiTarget()
		if type(targets) == "table" and #targets == 2 then
			table.insert(self.qiaobian_draw_targets, targets[1])
			table.insert(self.qiaobian_draw_targets, targets[2])
			return to_discard
		end
		return {}
	elseif current_phase == sgs.Player_Play and not self.player:isSkipped(sgs.Player_Play) then
		self:sortByKeepValue(cards)
		table.remove(to_discard)
		table.insert(to_discard, cards[1]:getEffectiveId())

		self:sort(self.enemies, "defense")
		self:sort(self.friends, "defense")
		self:sort(self.friends_noself, "defense")

		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and self:getMoveCardorTarget(friend, ".") then
				return to_discard
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, ".") then
				return to_discard
			end
		end

		local top_value = 0
		for _, hcard in ipairs(cards) do
			if not hcard:isKindOf("Jink") then
				if self:getUseValue(hcard) > top_value then top_value = self:getUseValue(hcard) end
			end
		end
		if top_value >= 3.7 and #(self:getTurnUse()) > 0 then return {} end

		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(enemy, ".") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			return to_discard
		end
	elseif current_phase == sgs.Player_Discard and not self.player:isSkipped(sgs.Player_Discard) then
		self:sortByKeepValue(cards)
		self.player:setFlags("AI_ConsideringQiaobianSkipDiscard")
		if self:getOverflow() > 1 then
			return { cards[1]:getEffectiveId() }
		end
	end

	return {}
end

sgs.ai_skill_use["@@qiaobian_ask"] = function(self, prompt)
	self:updatePlayers()
	local QBCard = "@QiaobianAskCard=.&->"
	if prompt == "@qiaobian-2" then
		if #self.qiaobian_draw_targets == 2 then
			return QBCard .. table.concat(self.qiaobian_draw_targets, "+")
		end
		return "."
	end

	if prompt == "@qiaobian-3" then
		-- if self.player:getHandcardNum()-2 > self.player:getHp() then return "." end

		self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and self:getMoveCardorTarget(friend, ".") then
				return QBCard .. friend:objectName() .. "+" .. self:getMoveCardorTarget(friend, "target"):objectName()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, ".") then
				return QBCard .. friend:objectName() .. "+" .. self:getMoveCardorTarget(friend, "target"):objectName()
			end
		end

		local cards = sgs.QList2Table(self.player:getHandcards())
		local top_value = 0
		for _, hcard in ipairs(cards) do
			if not hcard:isKindOf("Jink") then
				if self:getUseValue(hcard) > top_value then
					top_value = self:getUseValue(hcard)
				end
			end
		end
		if top_value >= 3.7 and #(self:getTurnUse()) > 0 then return "." end

		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if self:getMoveCardorTarget(enemy, ".") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			return QBCard .. targets[#targets]:objectName() .. "+" .. self:getMoveCardorTarget(targets[#targets], "target"):objectName()
		end
	end

	return "."
end

function sgs.ai_cardneed.qiaobian(to, card)
	return to:getHandcardNum() <= 2
end

--徐晃
local duanliang_skill = {}
duanliang_skill.name = "duanliang"
table.insert(sgs.ai_skills, duanliang_skill)
duanliang_skill.getTurnUseCard = function(self)
	if not self:willShowForAttack() then
		return nil
	end
	if self.player:hasFlag("DuanliangCannot") then
		return nil
	end

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local card

	self:sortByUseValue(cards, true)

	for _,acard in ipairs(cards)  do
		if acard:isBlack() and (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard")) and (self:getUseValue(acard) < sgs.ai_use_value.SupplyShortage) then
			card = acard
			break
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("supply_shortage:duanliang[%s:%s]=%d%s"):format(suit, number, card_id, "&duanliang")
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_cardneed.duanliang = function(to, card, self)
	return card:isBlack() and card:getTypeId() ~= sgs.Card_TypeTrick and getKnownCard(to, self.player, "black", false) < 2
end

sgs.duanliang_suit_value = {
	spade = 3.9,
	club = 3.9
}
sgs.ai_suit_priority.duanliang= "club|spade|diamond|heart"

--曹仁
function sgs.ai_skill_invoke.jushou(self, data)
	if not self.player:faceUp() then return true end
	if not self:willShowForDefence() then return false end
	local to_count = sgs.SPlayerList()

	local all_players = self.room:getAlivePlayers()

	for _, p1 in sgs.qlist(all_players) do
		if p1:hasShownOneGeneral() then
			local add = true
			for _, p2 in sgs.qlist(to_count) do
				if p1:isFriendWith(p2) then
					add = false
					break
				end
			end
			if add then
				to_count:append(p1)
			end
		end
	end

	if to_count:length() < 3 or to_count:length() > 5 then
		--Global_room:writeToConsole("据守势力小于3或大于5")
		return true
	end

	for _, friend in ipairs(self.friends_noself) do
		if friend:hasShownSkill("fangzhu") and to_count:length() > 3 then
			--Global_room:writeToConsole("据守有放逐队友")
			return true
		end
	end

	return self:isWeak() or self.player:getMark("##xiongnve_avoid") > 0
end

--据守选择一张手牌中的能弃置的非装备牌或能使用的装备牌
sgs.ai_skill_cardask["@jushou"] = function(self, data)
	local equips, to_discard = {}, {}
	for _,to_select in sgs.qlist(self.player:getHandcards())do
        if to_select:getTypeId() == sgs.Card_TypeEquip then
			if to_select:isAvailable(self.player) then
				table.insert(equips, to_select)
			end
		else
			if not self.player:isJilei(to_select) then
				table.insert(to_discard, to_select)
			end
		end
    end
	--优先使用缺少的装备
	self:sortByUsePriority(equips)
	for _, card in ipairs(equips) do
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		if not self.player:getEquip(equip_index) then
			return "$" .. card:getId()
		end
	end
	--换成价值更高的装备（考虑武器和防具），同时记录不该扔的牌
	local _cards = {}
	for _, card in ipairs(equips) do
		if card:isKindOf("Weapon") then
			local weapon = self.player:getWeapon()
			if weapon then
				if self:evaluateWeapon(card) > self:evaluateWeapon(weapon) then
					return "$" .. card:getId()
				elseif self:evaluateWeapon(card) < self:evaluateWeapon(weapon) then
					table.insert(_cards, card)
				end
			end
		elseif card:isKindOf("Armor") then
			local armor = self.player:getArmor()
			if armor then
				if self:evaluateArmor(card) > self:evaluateArmor(armor) then
					return "$" .. card:getId()
				elseif self:evaluateArmor(card) < self:evaluateArmor(armor) then
					table.insert(_cards, card)
				end
			end
		end
	end

	local all_cards = to_discard
	for _, card in ipairs(equips) do
		if not table.contains(_cards, card) then
			table.insert(all_cards, card)
		end
	end
	self:sortByKeepValue(all_cards)
	if #all_cards > 0 then
		return "$" .. all_cards[1]:getId()
	end
	if #_cards > 0 then
		return "$" .. _cards[1]:getId()
	end
end

--典韦
local qiangxi_skill = {}
qiangxi_skill.name = "qiangxi"
table.insert(sgs.ai_skills, qiangxi_skill)
qiangxi_skill.getTurnUseCard = function(self)
	if not self:willShowForAttack() then return end
	if not self.player:hasUsed("QiangxiCard") then
		return sgs.Card_Parse("@QiangxiCard=.&qiangxi")
	end
end

sgs.ai_skill_use_func.QiangxiCard = function(QiangxiCard, use, self)--新技能不限制距离
	local num = 0
	local weapon
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			if num == 0 then
				weapon = card
			end
			num = num + 1
		end
	end
	self:sort(self.enemies, "hp")
	if weapon then
		local need_weapon = num < 2
		if need_weapon then--考虑攻击范围和留好武器，考虑杀的优先度？
			local e_weapon = self.player:getWeapon()
			local rangefix = 0
			if e_weapon and e_weapon:getClassName() ~= "Weapon" then
				rangefix = sgs.weapon_range[e_weapon:getClassName()] - self.player:getAttackRange(false)
			end
			local slash = sgs.cloneCard("slash")
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true, rangefix)
				and not self:slashProhibit(slash ,enemy) and self:slashIsEffective(slash, enemy) then
					need_weapon = false
					break
				end
			end
			if self:evaluateWeapon(weapon) > 8 then--值是否合适？
				need_weapon = true
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3
			and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
			and not self:needDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy) then
				if num > 1 or (self:isWeak(enemy) and (not need_weapon or enemy:getHp() == 1)) then
					use.card = sgs.Card_Parse("@QiangxiCard=" .. tostring(weapon:getId()) .. "&qiangxi")
					if use.to then
						use.to:append(enemy)
					end
					break
				end
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and self:isWeak(enemy)
			and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
			and not self:needDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy) then
				if self.player:getHp() > 2
				or (enemy:getHp() == 1 and (self.player:getHp() > 1 or self:getCardsNum({"Peach", "Analeptic"}) > 0)) then
					use.card = sgs.Card_Parse("@QiangxiCard=.&qiangxi")
					if use.to then
						use.to:append(enemy)
					end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.QiangxiCard = 2.5
sgs.ai_card_intention.QiangxiCard = 80
sgs.dynamic_value.damage_card.QiangxiCard = true
sgs.ai_cardneed.qiangxi = sgs.ai_cardneed.weapon
sgs.qiangxi_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}

--荀彧
local quhu_skill = {}
quhu_skill.name = "quhu"
table.insert(sgs.ai_skills, quhu_skill)
quhu_skill.getTurnUseCard = function(self)
	if self:willShowForAttack() and not self.player:hasUsed("QuhuCard") and not self.player:isKongcheng() then return sgs.Card_Parse("@QuhuCard=.&quhu") end
end

sgs.ai_skill_use_func.QuhuCard = function(QHCard, use, self)

	if #self.enemies == 0 then return end
	local max_card = self:getMaxNumberCard()
	local max_point = max_card:getNumber()
	if self.player:hasShownSkill("yingyang") then max_point = math.min(max_point + 3, 13) end
	self:sort(self.enemies, "handcard")

	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() > self.player:getHp() and not enemy:isKongcheng() then
			local enemy_max_card = self:getMaxNumberCard(enemy)
			local enemy_number = enemy_max_card and enemy_max_card:getNumber() or 0
			if enemy_max_card and enemy:hasShownSkill("yingyang") then enemy_number = math.min(enemy_number + 3, 13) end
			local allknown = false
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = true
			end
			if (enemy_max_card and max_point > enemy_number and allknown)
				or (enemy_max_card and max_point > enemy_number and not allknown and (max_point > 10 + (enemy:hasShownSkill("congjian") and 1 or 0)))
				or (not enemy_max_card and (max_point > 10 + (enemy:hasShownSkill("congjian") and 2 or 0))) then
				for _, enemy2 in ipairs(self.enemies) do
					if (enemy:objectName() ~= enemy2:objectName())
						and enemy:distanceTo(enemy2) <= enemy:getAttackRange() then
						self.quhu_card = max_card:getEffectiveId()
						use.card = QHCard
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end
	if not self.player:isWounded() or (self.player:getHp() == 1 and self:getCardsNum("Analeptic") > 0 and self.player:getHandcardNum() >= 2)
	  and self.player:hasShownSkill("jieming") then
		local use_quhu
		for _, friend in ipairs(self.friends) do
			if math.min(5, friend:getMaxHp()) - friend:getHandcardNum() >= 2 then
				self:sort(self.enemies, "handcard")
				if self.enemies[#self.enemies]:getHandcardNum() > 0 then use_quhu = true break end
			end
		end
		if use_quhu then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() and self.player:getHp() < enemy:getHp() and not enemy:hasShownSkill("congjian") then
					local cards = self.player:getHandcards()
					cards = sgs.QList2Table(cards)
					self:sortByUseValue(cards, true)
					self.quhu_card = cards[1]:getEffectiveId()
					use.card = QHCard
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_cardneed.quhu = sgs.ai_cardneed.bignumber
sgs.ai_skill_playerchosen.quhu = sgs.ai_skill_playerchosen.damage
sgs.ai_playerchosen_intention.quhu = 80

sgs.ai_card_intention.QuhuCard = 0
sgs.dynamic_value.control_card.QuhuCard = true

sgs.ai_skill_playerchosen.jieming = function(self, targets)
	if not self:willShowForMasochism() then return end
	local friends = {}
	local selected_target = self.player:getTag("jieming_target"):toStringList()

	for _, player in ipairs(self.friends) do
		if player:isAlive() and not table.contains(selected_target, player:objectName()) then
			table.insert(friends, player)
		end
	end
	self:sort(friends)

	local max_x = 0
	local target

	local CP = self.room:getCurrent()
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _, friend in ipairs(friends) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if self:hasCrossbowEffect(CP) then x = x + 1 end
		if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end

		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end

	return target
end

sgs.ai_need_damaged.jieming = function(self, attacker, player)
	return player:hasShownSkill("jieming") and self:getJiemingDrawNum(player) >= 3
end

sgs.ai_playerchosen_intention.jieming = function(self, from, to)
	if to:getHandcardNum() < math.min(5, to:getMaxHp()) then
		sgs.updateIntention(from, to, -80)
	end
end

--曹丕
sgs.ai_skill_invoke.xingshang = true

function SmartAI:toTurnOver(player, n, reason) -- @todo: param of toTurnOver
	if not player then Global_room:writeToConsole(debug.traceback()) return end
	n = n or 0
	if not player:faceUp() then return false end
	if reason and reason == "fangzhu" and player:getHp() == 1 and sgs.ai_AOE_data then
		local use = sgs.ai_AOE_data:toCardUse()
		if use.to:contains(player) and self:aoeIsEffective(use.card, player)
			and self:playerGetRound(player) > self:playerGetRound(self.player)
			and player:isKongcheng() then
			return false
		end
	end
	if n > 1 then
		if ( player:getPhase() ~= sgs.Player_NotActive and (player:hasShownSkills(sgs.Active_cardneed_skill) or self:hasCrossbowEffect(player)) )
		or ( player:getPhase() == sgs.Player_NotActive and player:hasShownSkills(sgs.notActive_cardneed_skill) ) then
		return false end
	end
	if not self:isFriend(player) and player:hasShownSkill("jushou") and player:getPhase() <= sgs.Player_Finish then
		return false
	end
	return true
end

sgs.ai_skill_playerchosen.fangzhu = function(self, targets)
	if not self:willShowForMasochism() then return {} end

	local function can_losehp(p)
		return not p:isRemoved() and (not p:hasSkill("hongfa") or p:getPile("heavenly_army"):isEmpty())
	end

	self:sort(self.friends_noself, "handcard")
	local target = nil
	local n = self.player:getLostHp()
	for _, friend in ipairs(self.friends_noself) do
		if not friend:faceUp() then
				target = friend
			break
		end
	end
	if not target then
		if n >= 3 then--配魏国2.5血将
			local caoren = sgs.findPlayerByShownSkillName("jushou")
			if caoren and self:isFriend(caoren) and caoren:faceUp() and caoren:getPhase() <= sgs.Player_Finish then
				target = caoren
			end
			if not target then
				self:sort(self.friends_noself, "hp")
				for _, friend in ipairs(self.friends_noself) do
					if self:isWeak(friend) and self:toTurnOver(friend, n, "fangzhu") then
						target = friend
						break
					end
				end
			end
			if not target then
				target = self:findPlayerToDraw(false, n)
			end
		else
			self:sort(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, n, "fangzhu") and enemy:hasShownSkills(sgs.priority_skill) and (can_losehp(enemy) or enemy:isNude()) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "fangzhu") and (can_losehp(enemy) or enemy:isNude()) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if not self:isFriendWith(p) and self:toTurnOver(p, n, "fangzhu") then
						target = p
				  		break
					end
				end
			end
			--[[
				if not target then
				for _, friend in ipairs(self.friends_noself) do--曹仁相关
					if friend:faceUp() and friend:hasShownSkill("jushou") and friend:getPhase() <= sgs.Player_Finish then
							target = friend
						break
					end
				end
			end
			]]--
		end
	end
	return target
end

sgs.ai_skill_discard["fangzhu_discard"] = function(self, discard_num, min_num, optional, include_equip)
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return {}
	end
	local caopi = sgs.findPlayerByShownSkillName("fangzhu")
	if self:isFriend(caopi) and caopi:getLostHp() > 2 then--翻队友的情况
		return {}
	end
	if not self.player:faceUp() or self.player:getCardCount(true) < min_num then
		return {}
	end
	if self.player:isRemoved() or (self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty()) then
		return self:askForDiscard("dummy_reason", discard_num, min_num, false, true)
	end
	if self.player:getMark("##xiongnve_avoid") > 0 then
		return {}
	end
	if self.player:hasSkill("jushou") and self.player:getPhase() <= sgs.Player_Finish then
		return {}
	end
	if self:isWeak() then
		return {}
	else
		return self:askForDiscard("dummy_reason", discard_num, min_num, false, true)
	end
	return {}
end

sgs.ai_playerchosen_intention.fangzhu = function(self, from, to)
	local intention = 80 / math.max(from:getLostHp(), 1)
	if not self:toTurnOver(to, from:getLostHp()) then intention = -intention end
	if from:getLostHp() < 3 then
		sgs.updateIntention(from, to, intention)
	else
		sgs.updateIntention(from, to, math.min(intention, -30))
	end
end

sgs.ai_need_damaged.fangzhu = function (self, attacker, player)
	if not player:hasShownSkill("fangzhu") then return end
	local enemies = self:getEnemies(player)
	if #enemies < 1 then return false end
	self:sort(enemies, "defense")
	for _, enemy in ipairs(enemies) do
		if player:getLostHp() < 1 and self:toTurnOver(enemy, player:getLostHp() + 1) then
			return true
		end
	end
	local friends = self:getFriendsNoself(player)
	for _, friend in ipairs(friends) do
		if not friend:faceUp() and (player:getHp() > 1
			or getCardsNum("Peach", player, (attacker or self.player)) > 0
			or getCardsNum("Analeptic", player, (attacker or self.player)) > 0) then
			return true
		end
	end
	self:sort(friends,"hp")
	for _, friend in ipairs(friends) do
		if not self:toTurnOver(friend, player:getLostHp() + 1) then return true end
	end
	return false
end

--乐进
sgs.ai_skill_cardask["@xiaoguo"] = function(self, data)
	if not self:willShowForAttack() then return "." end
	local currentplayer = self.room:getCurrent()

	if self.player:getMark("Global_TurnCount") < 2 and not self.player:hasShownOneGeneral() and self:getOverflow(self.player, false) < 1 then
		if not currentplayer:hasShownOneGeneral() then
			return "."
		end
	end

	local has_analeptic, has_slash, has_jink
	for _, acard in sgs.qlist(self.player:getHandcards()) do
		if acard:isKindOf("Analeptic") then has_analeptic = acard
		elseif acard:isKindOf("Slash") then has_slash = acard
		elseif acard:isKindOf("Jink") then has_jink = acard
		end
	end

	local card

	if has_slash then card = has_slash
	elseif has_jink then card = has_jink
	elseif has_analeptic then
		if (getCardsNum("EquipCard", currentplayer, self.player) == 0 and not self:isWeak()) or self:getCardsNum("Analeptic") > 1 then
			card = has_analeptic
		end
	end

	if not card then return "." end
	if self:isFriend(currentplayer) then
		if self:needToThrowArmor(currentplayer) then
			if card:isKindOf("Slash") or (card:isKindOf("Jink") and self:getCardsNum("Jink") > 1) then
				return "$" .. card:getEffectiveId()
			else return "."
			end
		end
	elseif self:isEnemy(currentplayer) then
		if not self:damageIsEffective(currentplayer) then return "." end
		if self:needDamagedEffects(currentplayer) or self:needToLoseHp(currentplayer, self.player) then return "." end
		if self:needToThrowArmor(currentplayer) then return "." end
		if currentplayer:getHp() > 2 and (currentplayer:getHandcardNum() > 2 or currentplayer:getCards("e"):length() > 1)then return "." end
		if currentplayer:getHp() > 1 and (currentplayer:getHandcardNum() > 3 or currentplayer:getCards("e"):length() > 2)then return "." end
		if currentplayer:hasShownSkills(sgs.lose_equip_skill) and currentplayer:hasEquip() then return "." end
		if currentplayer:hasShownSkill("mingshi")
			and (not self.player:hasShownOneGeneral() or (self.player:hasShownSkill("xiaoguo") and not self.player:hasShownAllGenerals()) )then return "." end
		return "$" .. card:getEffectiveId()
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@xiaoguo"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		local current = self.room:getCurrent()
		if not current then return end
		local intention = 10
		if current:hasShownSkills(sgs.lose_equip_skill) and current:hasEquip() then intention = 0 end
		if self:needToThrowArmor(current) then return end
		sgs.updateIntention(player, current, intention)
	end
end

sgs.ai_skill_cardask["@xiaoguo-discard"] = function(self, data)
	local yuejin = sgs.findPlayerByShownSkillName("xiaoguo")
	local player = self.player

	if self:needToThrowArmor() then
		return "$" .. player:getArmor():getEffectiveId()
	end
	if not self:damageIsEffective(player, sgs.DamageStruct_Normal, yuejin) then
		return "."
	end
	if self:needDamagedEffects(self.player, yuejin) then
		return "."
	end
	if self:needToLoseHp(player, yuejin) then
		return "."
	end

	local card_id
	if self.player:hasSkills(sgs.lose_equip_skill) then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getArmor() then card_id = player:getArmor():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		end
	end

	if not card_id then
		for _, card in sgs.qlist(player:getCards("h")) do
			if card:isKindOf("EquipCard") then
				card_id = card:getEffectiveId()
				break
			end
		end
	end

	if not card_id then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getTreasure() and not (player:getPile("wooden_ox"):length() > 1 or player:hasTreasure("JadeSeal")) then card_id = player:getTreasure():getId()
		elseif self:isWeak(player) and player:getArmor() then card_id = player:getArmor():getId()
		elseif self:isWeak(player) and player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		end
	end

	if not card_id then return "." else return "$" .. card_id end
end


sgs.ai_cardneed.xiaoguo = function(to, card)
	return getKnownCard(to, Global_room:getCurrent(), "BasicCard", true) == 0 and card:getTypeId() == sgs.Card_TypeBasic
end