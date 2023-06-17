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
--李典
sgs.ai_skill_invoke.xunxun = function(self, data)
	if not (self:willShowForDefence() or self:willShowForAttack()) then
		return false
	end
	return true
end

sgs.ai_skill_movecards.xunxun = function(self, upcards, downcards, min_num, max_num)
	local upcards_copy = table.copyFrom(upcards)
	local down = {}
	local id1 = self:askForAG(upcards_copy,false,"xunxun")
	down[1] = id1
	table.removeOne(upcards_copy,id1)
	local id2 = self:askForAG(upcards_copy,false,"xunxun")
	down[2] = id2
	table.removeOne(upcards_copy,id2)
	return upcards_copy,down
end

function sgs.ai_skill_invoke.wangxi(self, data)
	if not self:willShowForMasochism() then return false end
	local target = data:toPlayer()
	if not target then target = data:toDamage().from end
	if target then
		if self:isFriend(target) then
			if not self:needKongcheng(target) then return true end
		else
			if self.player:hasShownSkill("fankui") and target:isNude() then return true end--反馈拿回来
			--考虑骁果的时机
			if not (target:getPhase() ~= sgs.Player_NotActive and target:getPhase() <= sgs.Player_Play and (target:hasShownSkills(sgs.Active_cardneed_skill) or self:hasCrossbowEffect(target)))
				and not (target:getPhase() == sgs.Player_NotActive and target:hasShownSkills(sgs.notActive_cardneed_skill))
				or self:needKongcheng(target) then
				return true
			end
		end
	end
	return false
end


sgs.ai_choicemade_filter.skillInvoke.wangxi = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	local target = nil
	if damage.from and damage.from:objectName() == player:objectName() then
		target = damage.to
	elseif damage.to and damage.to:objectName() == player:objectName() then
		target = damage.from
	end
	if target and promptlist[3] == "yes" then
		if self:needKongcheng(target, true) then sgs.updateIntention(player, target, 10)
		elseif player:getState() == "robot" then sgs.updateIntention(player, target, -60)
		end
	end
end

function sgs.ai_cardneed.wangxi(to, card)
	return card:isKindOf("AOE") or card:isKindOf("Crossbow")
end

sgs.wangxi_keep_value = {
	Crossbow = 6,
	SavageAssault = 5.2,
	ArcheryAttack = 5.2
}

--臧霸
function sgs.ai_skill_invoke.hengjiang(self, data)
	if not self:willShowForMasochism() then return false end
	local target = data:toPlayer()
	if not target then target = data:toDamage().from end
	if not target then return end
	if self:isFriend(target) then
		return false
	else
		return true
	end
end

sgs.ai_choicemade_filter.skillInvoke.hengjiang = function(self, player, promptlist)
	if promptlist[3] == "yes" then
		local current = self.room:getCurrent()
		if current and current:getPhase() <= sgs.Player_Discard
			and not (current:hasShownSkill("keji") and not current:hasFlag("KejiSlashInPlayPhase")) and current:getHandcardNum() > current:getMaxCards() - 2 then
			sgs.updateIntention(player, current, 50)
		end
	end
end

--马岱
sgs.ai_skill_invoke.qianxi = function(self, data)
	if not self:willShowForAttack() then
		return false
	end
	return true
end

sgs.ai_skill_cardask["@qianxi-discard"] = function(self, data, pattern, target, target2)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	self.qianxi_isred = cards[1]:isRed()
	if cards[1]:isBlack() and #cards > 1 then
		if cards[2]:isRed() and not cards[2]:isKindOf("Peach") then
			self.qianxi_isred = cards[2]:isRed()
			return cards[2]:toString()
		end
	end
	return cards[1]:toString()--必须弃1
end
--qianxi_target
sgs.ai_skill_playerchosen.qianxi_target = function(self, targets)
	local enemies = {}
	local slash = self:getCard("Slash") or sgs.cloneCard("slash")

	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) and not target:isKongcheng() then
			table.insert(enemies, target)
		end
	end
	if #enemies == 0 then--敌人全空城也尽量不选队友
		for _, target in sgs.qlist(targets) do
			if not self:isFriend(target) then
				table.insert(enemies, target)
			end
		end
	end
	self:sort(enemies, "defenseSlash")

	if #enemies == 1 then
		Global_room:writeToConsole("潜袭唯一敌方")
		return enemies[1]
	else
		if not self.qianxi_isred then
			for _, enemy in ipairs(enemies) do
				if enemy:hasShownSkill("qingguo") and self:slashIsEffective(slash, enemy) then return enemy end
			end
			for _, enemy in ipairs(enemies) do
				if enemy:hasShownSkill("kanpo") then return enemy end
			end
		else
			for _, enemy in ipairs(enemies) do
				if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then return enemy end
			end
			for _, enemy in ipairs(enemies) do
				if getKnownCard(enemy, self.player, "Peach", true, "h") > 0 or enemy:hasShownSkill("jijiu") then return enemy end
			end
			for _, enemy in ipairs(enemies) do
				if getKnownCard(enemy, self.player, "Jink", false, "h") > 0 and self:slashIsEffective(slash, enemy) then return enemy end
			end
		end
		Global_room:writeToConsole("潜袭选择结束")
		return enemies[1]
	end
	Global_room:writeToConsole("潜袭视为杀目标")
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)--ai默认函数
end

sgs.ai_playerchosen_intention.qianxi = 60

function sgs.ai_cardneed.qianxi(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("Analeptic") or (card:isRed() and getKnownCard(to, self.player, "red", false) < 2)
end

--糜夫人
sgs.ai_skill_invoke.guixiu = true

local cunsi_skill = {}
cunsi_skill.name = "cunsi"
table.insert(sgs.ai_skills, cunsi_skill)
cunsi_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("@CunsiCard=.")
end

sgs.ai_skill_use_func.CunsiCard = function(card, use, self)

	local all_shown = true
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:hasShownOneGeneral() then
			all_shown = false
			break
		end
	end

	local to
	self:sort(self.friends_noself, "hp", true)
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasShownGeneral1() and sgs.ai_explicit[friend:objectName()] == self.player:getKingdom() and self.player:isWounded() then
			to = friend
			break
		end
	end
	if to then
		use.card = card
		if use.to then use.to:append(to) end
	end
	if use.card then return end

	if all_shown and #self.friends_noself == 0 and self.player:getLostHp() > 0 then
		use.card = card
		if use.to then use.to:append(self.player) end
	end
end

sgs.ai_use_priority.CunsiCard = 11

sgs.ai_skill_choice.yongjue = function(self)
	return "yes"
end

--孙策
sgs.ai_skill_invoke.jiang = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return false
	end
	return true
end

sgs.ai_cardneed.jiang = function(to, card, self)
	return isCard("Duel", card, to) or (isCard("Slash", card, to) and card:isRed())
end

sgs.ai_suit_priority.jiang = function(self, card)
	return (card:isKindOf("Slash") or card:isKindOf("Duel")) and "diamond|heart|club|spade" or "club|spade|diamond|heart"
end

--[[似乎源码没有data信息
sgs.ai_skill_invoke.yingyang = function(self, data)
	local pindian = data:toPindian()
	local f_num, t_num = pindian.from_number, pindian.to_number
	if math.abs(f_num - t_num) <= 3 then return true end
	return false
end
]]

sgs.ai_skill_invoke.yingyang = true

sgs.ai_skill_choice.yingyang = function(self, choices, data)
	local pindian = data:toPindian()
	local reason = pindian.reason
	local from, to = pindian.from, pindian.to
	local f_num, t_num = pindian.from_number, pindian.to_number
	local amFrom = self.player:objectName() == from:objectName()

	local table_pindian_friends = { "tianyi", "fenglve", "fenglvezongheng" }
	if reason == "quhu" then
		local xunyu = sgs.findPlayerByShownSkillName("jieming")
		if not amFrom and xunyu and self:isFriend(xunyu) then
			if self:getJiemingDrawNum(xunyu) >= 3 then return "jia3"
			elseif f_num > 8 then return "jian3"
			end
		end
		return "jia3"
	elseif table.contains(table_pindian_friends, reason) then
		return (not amFrom and self:isFriend(from)) and "jian3" or "jia3"
	else
		return "jia3"
	end
end

sgs.ai_skill_invoke.hunshang = true

sgs.ai_skill_invoke.yingzi_sunce = function(self, data)
	return true
end

sgs.ai_skill_choice.yinghun_sunce = sgs.ai_skill_choice.yinghun_sunjian
sgs.ai_skill_playerchosen.yinghun_sunce = sgs.ai_skill_playerchosen.yinghun_sunjian
sgs.ai_playerchosen_intention.yinghun_sunce = sgs.ai_playerchosen_intention.yinghun_sunjian
sgs.ai_choicemade_filter.skillChoice.yinghun_sunce = sgs.ai_choicemade_filter.skillChoice.yinghun_sunjian

--陈武＆董袭
local duanxie_skill = {}
duanxie_skill.name = "duanxie"
table.insert(sgs.ai_skills, duanxie_skill)
duanxie_skill.getTurnUseCard = function(self)

	if not self:willShowForAttack() then
		return
	end

	if self.player:hasUsed("DuanxieCard") then return end
	return sgs.Card_Parse("@DuanxieCard=.&duanxie")
end

sgs.ai_skill_use_func.DuanxieCard = function(card, use, self)
	self:sort(self.enemies, "defense")
	local num = math.max(1, self.player:getLostHp())
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isChained() and not self:needDamagedEffects(enemy) and not self:needToLoseHp(enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
			table.insert(targets, enemy)
			if #targets == num then
				break
			end
		end
	end
	if #targets == 0 then return end
	if not self:isWeak() or self.player:isChained() or #targets > 2 then
		use.card = card
		if use.to then
			for _, p in ipairs(targets) do
				use.to:append(p)
			end
		end
	end
end

sgs.ai_card_intention.DuanxieCard = 60
sgs.ai_use_priority.DuanxieCard = 0.5

sgs.ai_skill_invoke.fenming = function(self, data)
	local value, count = 0, 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if player:isChained() then
			count = count + 1
			if self:isFriend(player) then
				if self:needToThrowArmor(player) then
					value = value + 1
				elseif player:getHandcardNum() == 1 and self:needKongcheng(player) then
					value = value + 1
				elseif self.player:canDiscard(player, "he") then
					local dec = self:isWeak(player) and 1.2 or 0.8
					if player:objectName() == self.player:objectName() then dec = dec / 1.5 end
					if self:getOverflow(player) >= 0 then dec = dec / 1.5 end
					value = value - dec
				end
			elseif self:isEnemy(player) then
				if self.player:canDiscard(player, "he") then
					if self:doNotDiscard(player) then
						value = value - 0.8
					else
						local dec = self:isWeak(player) and 1.2 or 0.8
						if self:getValuableCard(player) or self:getDangerousCard(player) then dec = dec * 1.5 end
						value = value + dec
					end
				end
			else
				value = value + 0.5
			end
		end
	end
	return value / count >= 0.2
end

sgs.ai_skill_exchange.fenming = function(self)
	local result = self:askForDiscard("dummy_reason", 1, 1, false, true)
	if type(result) == "number" then return { result } end
	return result
end

--董卓
--[[
sgs.ai_skill_invoke.hengzheng = function(self, data)
	local value = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		value = value + self:getGuixinValue(player)
	end
	return value >= 1.3
end
--]]

sgs.ai_skill_invoke.hengzheng = function(self, data)
	local value = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isNude() and p:getJudgingArea():isEmpty() then continue end
		if self:isFriend(p) then
			local good = false
			if not p:getJudgingArea():isEmpty() then
				value = value + 1.5
				good = true
			end
			if self:needToThrowArmor(p) then
				value = value + 1.2
				good = true
			end
			if p:getEquips():length() > 0 and p:hasShownSkills(sgs.lose_equip_skill) then
				value = value + 1
				good = true
			end
			if p:hasShownSkill("tuntian") then
				value = value + 0.5
				good = true
			end
			if self:needKongcheng(p, false, true) and p:getHandcardNum() == 1 then
				value = value + 0.8
				good = true
			end
			if not good then
				value = value - 1
			end
		elseif self:isEnemy(p) then
			if p:isNude() then
				value = value - 1.5
			else
				if self:getDangerousCard(p) or self:getValuableCard(p) then
					value = value + 0.8
					if p:hasShownSkills(sgs.lose_equip_skill) then
						value = value - 1
					end
				elseif p:getEquips():isEmpty() then
					if self:needKongcheng(p, false, true) and p:getHandcardNum() == 1 then
						value = value - 0.8
					end
					if getKnownCard(p, self.player, "Peach", true, "h") > 0 or getKnownCard(p, self.player, "Analeptic", true, "h") > 0 then
						value = value + 2 / p:getHandcardNum()
					end
				elseif p:isKongcheng() then
					if p:getEquips():length() == 1 and self:needToThrowArmor(p) then
						value = value - 1
					end
					if p:hasShownSkills(sgs.lose_equip_skill) then
						value = value - 1
					end
				end
				if p:hasShownSkill("tuntian") then
					value = value - 0.5
				end
				value = value + 1
			end
		else
			value = value + 1
		end
	end
	if value > 2 then
		return true
	end
	return false
end

sgs.ai_skill_choice.benghuai = function(self, choices, data)
	for _, friend in ipairs(self.friends) do
		if friend:hasShownSkill("tianxiang") and (self.player:getHp() >= 3 or (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 and self.player:getHp() > 1)) then
			return "hp"
		end
	end
	if self.player:getMaxHp() >= self.player:getHp() + 2 then
		if self.player:getMaxHp() > 5 and (self.player:hasSkill("yinghun_sunjian") and self:findPlayerToDraw(false)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num + 1 end
			end
			if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() > 1) then return "hp" end
		end
		return "maxhp"
	else
		return "hp"
	end
end

--张任
sgs.ai_skill_invoke.chuanxin = function(self, data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) and damage.to:hasShownSkill("jianglve") and damage.to:inDeputySkills("jianglve") then
		return damage.to:getMark("@strategy") > 0
	end
	if not self:isFriend(damage.to) and damage.to:hasShownSkill("xiongsuan") and damage.to:inDeputySkills("xiongsuan") and damage.to:getMark("@fierce") == 0 then
		return false
	end
	if not self:isFriend(damage.to) and damage.to:hasShownSkill("niepan") and damage.to:inDeputySkills("niepan") then
		return damage.to:getMark("@nirvana") > 0
	end
	if not self:isFriend(damage.to) and damage.to:hasShownSkill("buqu") and damage.to:inDeputySkills("buqu") then
		return true
	end
	if not self:isFriend(damage.to) and damage.to:hasShownSkill("jiancai") and damage.to:inDeputySkills("jiancai") then
		return true
	end
	if not self:isFriend(damage.to) and damage.to:hasShownSkill("tianxiang") and damage.to:inDeputySkills("tianxiang") 
		and getKnownCard(damage.to, self.player, "diamond|club", false) < damage.to:getHandcardNum() then
		return true
	end
	if not self:isFriend(damage.to) then
		local peach_num = getCardsNum("Peach", damage.to, self.player) + getCardsNum("Analeptic", damage.to, self.player)
		if not self.player:hasSkill("wansha") then
			for _, enemy_f in ipairs(self:getFriendsNoself(damage.to)) do
				peach_num = peach_num + getCardsNum("Peach", enemy_f, self.player)
			end
		end
		
		if not self:hasHeavySlashDamage(self.player, damage.card, damage.to) and damage.damage <= 1 then
			if damage.to:getHp() - damage.damage + peach_num > 0 then return true end
			if not self:isWeak(damage.to) or not (damage.to:getHp() == 1 and not damage.to:getArmor()) then
				return true
			end
		else
			if damage.to:getHp() - damage.damage + peach_num > 1 then return true end
			return false
		end
	end
	--穿心崩坏？
	return false
end

sgs.ai_skill_choice.chuanxin = "discard"

sgs.ai_skill_cardask["@fengshi-discard"] = function(self, data, pattern, target, target2)
	--pattern = ".|.|.|equipped!"
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = self.player:getCards("e")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	return cards[1]:toString()--必须弃1
end

--君·张角
sgs.ai_skill_invoke.wuxin = true

local wendao_skill = {}
wendao_skill.name = "wendao"
table.insert(sgs.ai_skills, wendao_skill)
wendao_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("WendaoCard") then
		local invoke = "no"
		local discardpile = self.room:getDiscardPile()
		local owner = nil
		local peace_spell = nil--被禁止使用就别问道
		for _, i in sgs.qlist(discardpile) do
			if sgs.Sanguosha:getCard(i):objectName() == "PeaceSpell" then
				invoke = "di"
				peace_spell = sgs.Sanguosha:getCard(i)
				break
			end
		end
		if invoke == "no" then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:getArmor() and p:getArmor():objectName() == "PeaceSpell" then
					invoke = "eq"
					owner = p
					peace_spell = p:getArmor()
					break
				end
			end
		end
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		local cards_copy = {}
		for _, c in ipairs(cards) do
			table.insert(cards_copy, c)
		end
		if invoke ~= "no" and peace_spell then
			if invoke == "eq" then
				assert(owner)--
				if owner:hasArmorEffect("PeaceSpell") then
					if (owner:objectName() == self.player:objectName()) then
						if self.player:isCardLimited(peace_spell, sgs.Card_MethodUse) then return nil end--被限制装备时不发动
						if (not self.player:hasSkill("hongfa")) or (self.player:getPile("heavenly_army"):isEmpty()) then
							if self.player:getHp() == 2 and self:getCardsNum("Peach") == 0 then --太平效果修改
								return nil
							end
						end
					else
						if (self.player:isFriendWith(owner)) then
							if self.player:isCardLimited(peace_spell, sgs.Card_MethodUse) then return nil end--被限制装备时不发动
							if self:isWeak(owner) and owner:getHp() > 1 then 
								if not self:needToThrowArmor(owner) then return nil end
								if not self:needToLoseHp(owner, self.player) then return nil end
								if owner:isChained() then return nil end
							end
						else
							if self:needToLoseHp(owner, self.player) then return nil end
						end
					end
				end
			elseif self.player:isCardLimited(peace_spell, sgs.Card_MethodUse) then return nil end
			for _, c in ipairs(cards_copy) do
				if c:objectName() == "PeaceSpell" or not c:isRed() then								  
					table.removeOne(cards, c)
				else
					if isCard("Peach", c, self.player) then
						table.removeOne(cards, c)
					end
				end
			end
			if #cards == 0 then return nil end
			return sgs.Card_Parse("@WendaoCard=" .. cards[1]:getEffectiveId() .. "&wendao")
		else
			for _, c in ipairs(cards_copy) do
				if c:objectName() == "PeaceSpell" or not c:isRed() then
					table.removeOne(cards, c)
				else
					if c:isKindOf("Peach") and not (self.player:hasSkill("lirang") and #self.friends_noself > 0) then
						table.removeOne(cards, c)
					end
				end
			end
			if #cards == 0 then return end
			if self.player:hasSkill("lirang") and #self.friends_noself > 0 then
				local card, friend = self:getCardNeedPlayer(cards, self.friends_noself)
				if not card or not friend then return end
				if ((self.player:hasEquip(card) and self.player:hasSkills(sgs.lose_equip_skill))
					or (self:isWeak(friend) and not self:isWeak())) then
					return sgs.Card_Parse("@WendaoCard=" .. card:getEffectiveId() .. "&wendao")
				end
			else
				local erzhang = sgs.findPlayerByShownSkillName("guzheng")
				if self:getOverflow() > 1 and erzhang and erzhang:isAlive() and self:isEnemy(erzhang) then
					local to_save = 0
					local over_flow = 0
					for _, c in ipairs(cards_copy) do
						if self.player:hasEquip(c) then continue end
						local dummy_use
						if c:targetFixed() then
							dummy_use = { isDummy = true }
						else
							dummy_use = { isDummy = true, to = sgs.SPlayerList() }
						end
						self:useCardByClassName(c,dummy_use)
						if dummy_use.card then continue end
						to_save = to_save + 1
					end
					over_flow = math.max(to_save - self.player:getHandcardNum() + self:getOverflow(), 0)
					if over_flow > 1 then
						for _, c in ipairs(cards) do
							if c:isKindOf("Peach") or self.player:hasEquip(c) then continue end
							return sgs.Card_Parse("@WendaoCard=" .. c:getEffectiveId() .. "&wendao")
						end
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use_func.WendaoCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.WendaoCard = sgs.ai_use_priority.ZhihengCard

sgs.ai_skill_invoke.hongfa = true

local getHongfaCard = function(self,pile)
	for _, id in ipairs(pile) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("PeaceSpell") then
			return id
		elseif card:isKindOf("DragonPhoenix") then
			local lord = self.room:getLord("shu")
			if not lord or self:isFriend(lord) then
				return id
			end
		elseif card:isKindOf("LuminousPearl") then
			local lord = self.room:getLord("wu")
			if not lord or self:isFriend(lord) then
				return id
			end
		elseif card:isKindOf("SixDragons") then
			local lord = self.room:getLord("wei")
			if not lord or self:isFriend(lord) then
				return id
			end
		else
			return id
		end
	end
	if #pile > 0 then return pile[1] end
	return nil
end

local huangjinsymbol_skill = {}
huangjinsymbol_skill.name = "huangjinsymbol"
table.insert(sgs.ai_skills, huangjinsymbol_skill)
huangjinsymbol_skill.getTurnUseCard = function(self, inclusive)
	local zj = self.room:getLord("qun")
	if not zj or zj:getPile("heavenly_army"):isEmpty() or not self.player:willBeFriendWith(zj) then return end
	local ints = sgs.QList2Table(zj:getPile("heavenly_army"))

	local int = getHongfaCard(self,ints)
	if int then
		local card = sgs.Sanguosha:getCard(int)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		local card_str = string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end
end

sgs.ai_cardsview.huangjinsymbol = function(self, class_name, player)
	if class_name ~= "Slash" then return end
	local zj = player:getLord()
	if not zj or zj:getPile("heavenly_army"):isEmpty() or not self.player:willBeFriendWith(zj) then return end
	local ints = zj:getPile("heavenly_army")
	local card_str = {}
	local PeaceSpell, lord_equip
	for _, int in sgs.qlist(ints) do
		local card = sgs.Sanguosha:getCard(int)
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local id = card:getEffectiveId()
		if card:isKindOf("PeaceSpell") then
			PeaceSpell = string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, id)
		elseif card:isKindOf("DragonPhoenix") or card:isKindOf("LuminousPearl") or card:isKindOf("SixDragons") then
			lord_equip = string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, id)
		else
			table.insert(card_str, string.format("slash:huangjinsymbol[%s:%s]=%d&", suit, number, id))
		end
	end
	if PeaceSpell then table.insert(card_str, 1, PeaceSpell) end
	if lord_equip then table.insert(card_str, lord_equip) end
	return card_str
end

sgs.ai_skill_invoke.huangjinsymbol = true

sgs.ai_skill_exchange["huangjinsymbol"] = function(self,pattern,max_num,min_num,expand_pile)
	Global_room:writeToConsole("君角防止体力流失")
	local ints = sgs.QList2Table(self.player:getPile("heavenly_army"))
	local int = getHongfaCard(self,ints)
	if int then
		return {int}
	end
	return {}
end

--[[
sgs.ai_skill_exchange["hongfa2"] = function(self,pattern,max_num,min_num,expand_pile)
	if self.player:getRole() == "careerist" then return {} end
	local ints = sgs.QList2Table(self.player:getPile("heavenly_army"))
	local pn = self.player:getTag("HongfaTianbingData"):toPlayerNum()
	if pn.m_toCalculate ~= self.player:getKingdom() then return {} end
	if pn.m_reason == "wuxin" or "hongfa" == pn.m_reason then
		return ints
	elseif pn.m_reason == "PeaceSpell" then
		local current = self.room:getCurrent()
		local use_lirang = false
		if current:hasShownSkill("lirang") and not self:isWeak(current) then
			local friends = self:getFriendsNoself(current)
			for _, friend in ipairs(friends) do
				if self:isWeak(friend) or friend:hasShownSkills(sgs.cardneed_skill) then
					use_lirang = true
					break
				end
			end
		end
		if use_lirang then return {} end
		return ints
	elseif pn.m_reason == "DragonPhoenix" or pn.m_reason == "xiongyi" then
		return {}
	elseif pn.m_reason == "fight_together" then
		--@todo
		return {}
	elseif pn.m_reason == "IronArmor" then
		return {}
	else
		self.room:writeToConsole("@@hongfa2 " .. pn.m_reason .. " is empty!")
	end
	return {}
end
]]

--太平要术
sgs.ai_slash_prohibit.PeaceSpell = function(self, from, enemy, card)
	if from:hasShownSkill("zhiman") then return false end
	if enemy:hasArmorEffect("PeaceSpell") and card:isKindOf("NatureSlash")
	and not IgnoreArmor(from, enemy) and not from:hasWeapon("IceSword") then return true end
end

function sgs.ai_armor_value.PeaceSpell(player, self)
	if player:hasShownSkills("hongfa+wendao") then return 1000 end
--[[太平效果修改
	if getCardsNum("Peach", player, player) + getCardsNum("Analeptic", player, player) == 0 and player:getHp() == 1 then
		if player:hasArmorEffect("PeaceSpell") then return 99
		else return -99
		end
	end
]]
	--进攻缺牌需要摸2怎么写？条件：目标1血，能使用杀等。如果能知道上一个杀目标就好写了
	local v = 4.5
	for _, p in ipairs(self:getFriendsNoself(player)) do
		if player:isFriendWith(p) then
			v = v + 0.5
		end
	end
	if self:getOverflow(player) > 0 then
		v = v + 0.5
	end
	if player:getMark("GlobalBattleRoyalMode") > 0 and player:hasArmorEffect("PeaceSpell") and player:getHp() > 1 then--鏖战别失去体力
		v = v + 1.5
	end
	return v
end

sgs.ai_use_priority.PeaceSpell = 0.75

