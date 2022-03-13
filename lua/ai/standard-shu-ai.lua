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
--刘备
function SmartAI:shouldUseRende()
	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0 or self.player:hasSkill("paoxiao") ) and self:getCardsNum("Slash") > 0     then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2
									and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			local inPaoxiaoAttackRange =  self.player:distanceTo(enemy) <= self.player:getAttackRange() and self.player:hasSkill("paoxiao")
			if (inAttackRange or inPaoxiaoAttackRange) and sgs.isGoodTarget(enemy, self.enemies, self) then
				local slashes = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashes) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return false end
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:canSlash(self.player) and not self:slashProhibit(nil, self.player, enemy)
			and self:hasCrossbowEffect(enemy) and getCardsNum("Slash", enemy) > 1 and self:getOverflow() <= 0 then
			return false
		end
	end
	for _, player in ipairs(self.friends_noself) do
		if (player:hasShownSkill("haoshi") and not player:containsTrick("supply_shortage")) or player:hasShownSkill("jijiu") then
			return true
		end
	end

	local giveNum = self.player:getMark("rende")
	local keepNum = self.player:getHandcardNum() - 2 + giveNum
	if self.player:hasSkill("kongcheng") and keepNum <= 2 then--有空城时手牌少时
		return true
	elseif keepNum < 0 and self.player:getMark("@firstshow") + self.player:getMark("@careerist") == 0 then--没有空城手牌少时
		return false
	end

	if self:getOverflow() > 0 then
		return true
	end
	if self.player:getHandcardNum() > keepNum  then
		return true
	end
	if giveNum > 0 and giveNum < 2 and (2 - giveNum) >=  (self.player:getHandcardNum() - keepNum) then
		return true
	end

	return false
end

local rende_skill = {}
rende_skill.name = "rende"
table.insert(sgs.ai_skills, rende_skill)
rende_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end

	if self:shouldUseRende() then
		return sgs.Card_Parse("@RendeCard=.&rende")
	end
end

sgs.ai_skill_use_func.RendeCard = function(rdcard, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)

	for i = 1, #cards do
		local card, friend = self:getCardNeedPlayer(cards, nil, "rende")
		if card and friend then
			cards = self:resetCards(cards, card)
		else
			break
		end
		if self.player:getHandcardNum() < 3 and self.player:hasSkill("kongcheng") then
			for _, p in ipairs(self.friends_noself) do
				friend = p
			end
		end

		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end

		if card:isAvailable(self.player) and (card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			local cardtype = card:getTypeId()
			self["use" .. sgs.ai_type_name[cardtype + 1] .. "Card"](self, card, dummy_use)
			if dummy_use.card and dummy_use.to:length() > 0 then
				if card:isKindOf("Slash") or card:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then continue
					elseif t1:getHp() == 1 or sgs.card_lack[t1:objectName()]["Jink"] == 1
							or t1:isCardLimited(sgs.cloneCard("jink"), sgs.Card_MethodResponse) then continue
					end
				elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then hasDelayedTrick = true break end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then continue end
		end

		use.card = sgs.Card_Parse("@RendeCard=" .. card:getId() .. "&rende")
		if use.to then use.to:append(friend) return end
	end

end

sgs.ai_use_value.RendeCard = 8.5
sgs.ai_use_priority.RendeCard = 8.2

sgs.ai_card_intention.RendeCard = function(self, card, from, tos)
	local to = tos[1]
	local intention = -70
	sgs.updateIntention(from, to, intention)
end

sgs.dynamic_value.benefit.RendeCard = true

sgs.ai_skill_choice["rende_basic"] = function(self, choices)--暂时简单处理
	Global_room:writeToConsole("仁德选择:"..self.player:objectName().." :"..choices)
	choices = choices:split("+")
	if table.contains(choices, "peach") and self.player:getHp() < 3 then
		return "peach"
	end
	if table.contains(choices, "fire_slash") or table.contains(choices, "thunder_slash") or table.contains(choices, "slash") then
		self.rende_slashtarget = nil
		local clone_slashes = {}
		if table.contains(choices, "fire_slash") then
			local fslash = sgs.cloneCard("fire_slash")
			table.insert(clone_slashes,fslash)
		end
		if table.contains(choices, "thunder_slash") then
			local tslash = sgs.cloneCard("thunder_slash")
			table.insert(clone_slashes,tslash)
		end
		if table.contains(choices, "slash") then
			local nslash = sgs.cloneCard("slash")
			table.insert(clone_slashes,nslash)
		end
		if self.enemies then
			self:sort(self.enemies, "defenseSlash")
			for _, slash in ipairs(clone_slashes) do
				for _, enemy in ipairs(self.enemies) do
					if self:isWeak(enemy) and self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
						and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
							self.rende_slashtarget = enemy
							return slash:objectName()
					end
				end
			end
		end
	end
	if table.contains(choices, "analeptic") and self:getCardsNum("Slash") > 0 then
		local slashes = self:getCards("Slash")
		self:sortByUseValue(slashes)
		if self.enemies then
			self:sort(self.enemies, "defenseSlash")
			for _, slash in ipairs(slashes) do
				for _, enemy in ipairs(self.enemies) do
					if self:isWeak(enemy) and not self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
						and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
							local use = { to = sgs.SPlayerList() }
							use.card = slash
							use.to:append(enemy)
							if self:shouldUseAnaleptic(enemy, use) then
								return "analeptic"
							end
					end
				end
			end
		end
	end
	if table.contains(choices, "peach") then--找不到杀目标
		return "peach"
	end
	return choices[1]
end

sgs.ai_skill_use["@@rende_slash"] = function(self, prompt, method)
	local card_name = prompt:split(":")[4]
	Global_room:writeToConsole("仁德杀:"..prompt.." 杀:"..card_name)
	if not card_name or not self.rende_slashtarget then return "." end
	local card = sgs.cloneCard(card_name)
	card:setSkillName("_rende")
	local str = card:toString()
	str = str .. "->" .. self.rende_slashtarget:objectName()
	self.rende_slashtarget = nil
	return str
end

--复制身份未修改
--[[
local tenyearrende_skill = {}
tenyearrende_skill.name = "tenyearrende"
table.insert(sgs.ai_skills, tenyearrende_skill)
tenyearrende_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	return sgs.Card_Parse("@TenyearRendeCard=.")
end

sgs.ai_skill_use_func.TenyearRendeCard = function(card, use, self)
    local others = self.room:getOtherPlayers(self.player)
    local friends, enemies, unknowns = {}, {}, {}
    local arrange = {}
    arrange["count"] = 0
    for _,p in sgs.qlist(others) do
        if p:getMark("tenyearrendetarget-PlayClear") <= 0 then
            arrange[p:objectName()] = {}
            if self:isFriend(p) then
                table.insert(friends, p)
            elseif self:isEnemy(p) then
                table.insert(enemies, p)
            else
                table.insert(unknowns, p)
            end
        end
    end
    local new_friends = {}
    for _,friend in ipairs(friends) do
        local exclude = false
        if self:needKongcheng(friend, true) or self:willSkipPlayPhase(friend) then
            exclude = true
            if self:hasKnownSkills("keji|qiaobian|shensu", friend) then
                exclude = false
            elseif friend:getHp() - friend:getHandcardNum() >= 3 then
                exclude = false
            elseif friend:isLord() and self:isWeak(friend) and self:getEnemyNumBySeat(self.player, friend) >= 1 then
                exclude = false
            end
        end
        if not exclude and not hasManjuanEffect(friend) and self:objectiveLevel(friend) <= -2 then
            table.insert(new_friends, friend)
        end
    end
    friends = new_friends
    local overflow = self:getOverflow()
    if overflow <= 0 and #friends == 0 then
        return 
    end
    local handcards = self.player:getHandcards()
    handcards = sgs.QList2Table(handcards)
    self:sortByUseValue(handcards)
    while true do
        if #handcards == 0 then
            break
        end
        local target, to_give, group = OlRendeArrange(self, handcards, friends, enemies, unknowns, arrange, false)
        if target and to_give and group then
            table.insert(arrange[target:objectName()], to_give)
            arrange["count"] = arrange["count"] + 1
            handcards = self:resetCards(handcards, to_give)
        else
            break
        end
    end
    local max_count, max_name = 0, nil
    for name, cards in pairs(arrange) do
        if type(cards) == "table" then
            local count = #cards
            if count > max_count then
                max_count = count
                max_name = name
            end
        end
    end
    if max_count == 0 or not max_name then
        return 
    end
    local max_target = nil
    for _,p in sgs.qlist(others) do
        if p:objectName() == max_name then
            max_target = p
            break
        end
    end
    if max_target and type(arrange[max_name]) == "table" and #arrange[max_name] > 0 then
        local to_use = {}
        for _,c in ipairs(arrange[max_name]) do
            table.insert(to_use, c:getEffectiveId())
        end
        local card_str = "@TenyearRendeCard="..table.concat(to_use, "+")
        local acard = sgs.Card_Parse(card_str)
        assert(acard)
        use.card = acard
        if use.to then
            use.to:append(max_target)
        end
    end
end
]]--

--关羽
sgs.ai_view_as.wusheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) and (player:getLord() and player:getLord():hasShownSkill("shouyue") or card:isRed()) and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:wusheng[%s:%s]=%d&wusheng"):format(suit, number, card_id)
	end
end

local wusheng_skill = {}
wusheng_skill.name = "wusheng"
table.insert(sgs.ai_skills, wusheng_skill)
wusheng_skill.getTurnUseCard = function(self, inclusive)

	self:sort(self.enemies, "defense")
	local useAll = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao|paoxiao_xh") or (self.player:hasSkill("baolie") and self.player:getHp() < 3) then disCrossbow = true end

	local hecards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		hecards:prepend(sgs.Sanguosha:getCard(id))
	end
	local cards = {}
	for _, card in sgs.qlist(hecards) do
		if (self.player:getLord() and self.player:getLord():hasShownSkill("shouyue") or card:isRed())
			and (not card:isKindOf("Slash") or card:isKindOf("NatureSlash"))
			and ((not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)) or useAll)
			and not isCard("BefriendAttacking", card, self.player) and not isCard("AllianceFeast", card, self.player)
			and (not isCard("Crossbow", card, self.player) or disCrossbow ) then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local card_str = ("slash:wusheng[%s:%s]=%d&wusheng"):format(suit, number, card_id)
			local slash = sgs.Card_Parse(card_str)
			assert(slash)
			if self:slashIsAvailable(self.player, slash) then
				table.insert(cards, slash)
			end
		end
	end

	if #cards == 0 then return end

	self:sortByUsePriority(cards)
	return cards[1]
end

function sgs.ai_cardneed.wusheng(to, card)
	return (to:getHandcardNum() < 3 and card:isRed()) or card:isKindOf("Crossbow")
end

sgs.ai_suit_priority.wusheng = "club|spade|diamond|heart"

--张飞
sgs.ai_skill_invoke.paoxiao = function(self, data)
	--[[if not self:willShowForAttack() and not self.player:hasSkills("wusheng|kuanggu") then return false end]]--
	return true
end

function sgs.ai_cardneed.paoxiao(to, card, self)
	local cards = to:getHandcards()
	for _, id in sgs.qlist(to:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		if sgs.cardIsVisible(c, to, self.player) then
			if c:isKindOf("Weapon") and not c:isKindOf("Crossbow") then
				has_weapon=true
			end
			if c:isKindOf("Slash") then slash_num = slash_num +1 end
		end
	end
	local now_weapon = to:getWeapon()
	local need_weapon = true
	local slash = sgs.cloneCard("slash")
	for _, enemy in ipairs(self:getEnemies(to)) do
		if to:canSlash(enemy) and not self:slashProhibit(slash ,enemy) and self:slashIsEffective(slash, enemy) then
			need_weapon = false
			break
		end
	end

	if need_weapon then
		return card:isKindOf("Weapon") and sgs.weapon_range[card:getClassName()] > (now_weapon and sgs.weapon_range[now_weapon:getClassName()] or 1)
	else
		return to:hasWeapon("Spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")) or card:isKindOf("Halberd")
	end
end

sgs.paoxiao_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7,
	BefriendAttacking = 5
}

--诸葛亮
sgs.ai_skill_invoke.kongcheng = true

sgs.ai_skill_invoke.guanxing = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() and self.player:getJudgingArea():isEmpty() then
		return false
	end
	return true
end

--赵云
local longdan_skill = {}
longdan_skill.name = "longdan"
table.insert(sgs.ai_skills, longdan_skill)
longdan_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local jink_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:longdan[%s:%s]=%d&longdan"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.longdan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
		if card:isKindOf("Jink") then
			return ("slash:longdan[%s:%s]=%d&longdan"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:longdan[%s:%s]=%d&longdan"):format(suit, number, card_id)
		end
	end
end

sgs.ai_skill_playerchosen["longdan_damage"] = function(self, targets)
	local target = sgs.ai_skill_playerchosen.damage(self, targets)
	if self:isFriend(target) then
		return {}
	end
	return target
end


sgs.ai_skill_playerchosen["longdan_recover"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _,p in ipairs(targets) do
		if self:isFriendWith(p) then
			return p
		end
	end
	for _,p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return {}
end

sgs.longdan_keep_value = {
	Jink = 5.2,
	FireSlash = 5.21,
	Slash = 5.2,
	ThunderSlash = 5.22,
	ExNihilo = 4.3
}

--马超
sgs.ai_skill_invoke.tieqi = function(self, data)
	if not self:willShowForAttack() and not self.player:hasSkills("kuanggu|paoxiao") then return false end

	local target = data:toPlayer()
	if self:isFriend(target) then return false end

	return true
end

sgs.ai_skill_choice.tieqi = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return "deputy_general" end

	if target:hasShownOneGeneral() then
		if (target:hasShownGeneral1()) and not (target:getGeneral2() and target:hasShownGeneral2()) then
			return "head_general"
		end
		if not (target:hasShownGeneral1()) and (target:getGeneral2() and target:hasShownGeneral2()) then
			return "deputy_general"
		end
		if (target:hasShownGeneral1()) and (target:getGeneral2() and target:hasShownGeneral2()) then
			if target:getMark("skill_invalidity_deputy") > 0 then
				return "head_general"
			end
			if target:getMark("skill_invalidity_head") > 0 then
				return "deputy_general"
			end
			local skills_name = (sgs.masochism_skill .. "|" .. sgs.save_skill .. "|" .. sgs.defense_skill .. "|"
					.. sgs.wizard_skill):split("|")
					--[[ .. "|" .. sgs.usefull_skill]]--更新技能名单
			for _, skill_name in ipairs(skills_name) do
				local skill = sgs.Sanguosha:getSkill(skill_name)
				if target:inHeadSkills(skill_name) and target:ownSkill(skill_name) and skill and skill:getFrequency() ~= sgs.Skill_Compulsory then
					return "head_general"
				end
			end
			return "deputy_general"
		end
	end
	return "deputy_general"
end

sgs.ai_skill_cardask["@tieji-discard"] = function(self, data, pattern, target, target2, arg, arg2)
	--Global_room:writeToConsole("铁骑判定弃牌")
	if not arg or self.player:isKongcheng() or self.player:isCardLimited(sgs.cloneCard("jink"), sgs.Card_MethodResponse) then
		return "."
	end
	local discard
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasTreasure("WoodenOx") and self.player:getTreasure():getSuitString() == arg and not self.player:getPile("wooden_ox"):isEmpty() then
		for _,id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):isKindOf("Peach") or (sgs.Sanguosha:getCard(id):isKindOf("Analeptic") and self.player:getHp() == 1) then
				table.removeOne(cards,self.player:getTreasure())
				break
			end
		end
	end
	if self:needToThrowArmor() and self.player:getArmor():getSuitString() == arg then
		discard = self.player:getArmor()
	end
	if not discard then
		for _,c in ipairs(cards) do
			if c:getSuitString() == arg and not discard and not (c:isKindOf("Peach") or (self.player:getHp() == 1 and c:isKindOf("Analeptic"))) then
				if (not c:isKindOf("Jink") and self:getCardsNum("Jink") > 0) or (c:isKindOf("Jink") and self:getCardsNum("Jink") > 1) then
					discard = c
				end
				if not c:isKindOf("EightDiagram") and self.player:getArmor() and self.player:getArmor():isKindOf("EightDiagram") then
					discard = c
				end
				if self.player:hasSkill("bazhen") then
					discard = c
				end
			end
		end
	end
	if discard then
		return "$" .. discard:getEffectiveId()
	end
	return "."
end

function sgs.ai_cardneed.tieqi(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("Analeptic")
end

--黄月英
sgs.ai_skill_invoke.jizhi = function(self, data)
	if not ( self:willShowForAttack() or self:willShowForDefence() or self:getCardsNum("TrickCard") > 1 ) then return false end
	return true
end

function sgs.ai_cardneed.jizhi(to, card)
	return card:getTypeId() == sgs.Card_TypeTrick
end

sgs.jizhi_keep_value = {
	Peach       = 6,
	Analeptic   = 5.9,
	Jink        = 5.8,
	ExNihilo    = 5.7,
	Snatch      = 5.7,
	Dismantlement = 5.6,
	IronChain   = 5.5,
	SavageAssault = 5.4,
	Duel        = 5.3,
	ArcheryAttack = 5.2,
	AmazingGrace = 4.8,
	GodSalvation = 4.8,
	Collateral  = 4.9,
	FireAttack  = 4.9,
	AwaitExhausted = 5.3,
	BefriendAttacking = 5.8,
	FightTogether = 5.6,
	Drowning = 5,
	BurningCamps = 5.6,
	AllianceFeast = 6
}

--黄忠
sgs.ai_skill_invoke.liegong = function(self, data)
	if not self:willShowForAttack() and not self.player:hasSkills("kuanggu|paoxiao") then return false end
	local target = data:toPlayer()
	return not self:isFriend(target)
end

function SmartAI:canLiegong(to, from)
	from = from or self.room:getCurrent()
	to = to or self.player
	if not from then return false end
	--[[and from:getPhase() == sgs.Player_Play ]]
	if from:hasSkills("liegong|liegong_xh") and (to:getHandcardNum() >= from:getHp() or to:getHandcardNum() <= from:getAttackRange()) then return true end
	return false
end

function sgs.ai_cardneed.liegong(to, card, self)
	local has_weapon = to:getWeapon() and sgs.weapon_range[to:getWeapon():getClassName()] >=3
	if not has_weapon then
		return card:isKindOf("Slash") or card:isKindOf("Analeptic")
	else
		return card:isKindOf("Weapon") and sgs.weapon_range[card:getClassName()] >=3
	end
end

--魏延
sgs.ai_skill_invoke.kuanggu = function(self, data)
	if not self:willShowForAttack() and not self.player:hasSkills("tieqi|paoxiao|liegong|qianxi")  then
		return false
	end
	return true
end

function sgs.ai_cardneed.kuanggu(to, card, self)
	if (card:isKindOf("OffensiveHorse") or card:isKindOf("SixDragons"))
	and not (to:getOffensiveHorse() or getKnownCard(to, self.player, "OffensiveHorse", false) > 0) then
		return true
	end
	if card:isKindOf("Crossbow") then
		return true
	end
	if self:hasCrossbowEffect(to) and isCard("Slash", card, to) then
		return true
	end
end

sgs.ai_skill_choice.kuanggu = function(self, choices)
	if self.player:getHp() <= 2 or not self:slashIsAvailable() or self.player:getMark("GlobalBattleRoyalMode") > 0 then
		return "recover"
	end
	return "draw"
end

sgs.kuanggu_keep_value = {
	Crossbow = 6,
	SixDragons = 6,
	OffensiveHorse = 6
}

--庞统
local lianhuan_skill = {}
lianhuan_skill.name = "lianhuan"
table.insert(sgs.ai_skills, lianhuan_skill)
lianhuan_skill.getTurnUseCard = function(self)

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local card
	self:sortByUseValue(cards, true)

	local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
	if slash then
		local dummy_use = { isDummy = true }
		self:useBasicCard(slash, dummy_use)
		if not dummy_use.card then slash = nil end
	end

	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Club and not (self.player:hasSkill("jizhi") and acard:isKindOf("IronChain"))then
			local shouldUse = true
			if self:getUseValue(acard) > sgs.ai_use_value.IronChain and acard:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(acard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if acard:getTypeId() == sgs.Card_TypeEquip then
				local dummy_use = { isDummy = true }
				self:useEquipCard(acard, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse and (not slash or slash:getEffectiveId() ~= acard:getEffectiveId()) then
				card = acard
				break
			end
		end
	end

	if not self:willShowForAttack() then
		return nil
	end
	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("iron_chain:lianhuan[club:%s]=%d%s"):format(number, card_id, "&lianhuan")
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_cardneed.lianhuan = function(to, card)
	return card:getSuit() == sgs.Card_Club and to:getHandcardNum() <= 2
end

sgs.ai_skill_invoke.niepan = function(self, data)
	if self.player:getMark("command5_effect") > 0 then
		return false
	end
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()
	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

sgs.ai_suit_priority.lianhuan= "club|diamond|heart|spade"

--卧龙·诸葛亮
local huoji_skill = {}
huoji_skill.name = "huoji"
table.insert(sgs.ai_skills, huoji_skill)
huoji_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards, true)

	for _,acard in ipairs(cards) do
		local fireValue = sgs.ai_use_value.FireAttack
		if self.player:hasSkill("jizhi") and acard:isKindOf("TrickCard") then
			fireValue = fireValue - 4
		end
		if acard:isRed() and not isCard("Peach", acard, self.player) and not acard:isKindOf("FireAttack")
		and (self:getUseValue(acard) < fireValue or self:getOverflow() > 0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = { isDummy = true , to = sgs.SPlayerList() }
				self:useBasicCard(acard, dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then keep = true break end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack + 0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end

	if not self:willShowForAttack() then
		return nil
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("fire_attack:huoji[%s:%s]=%d%s"):format(suit, number, card_id, "&huoji")
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_cardneed.huoji = function(to, card, self)
	return to:getHandcardNum() > 2 and card:isRed()
end

sgs.ai_suit_priority.huoji= "club|spade|diamond|heart"


sgs.ai_view_as.kanpo = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
		if card:isBlack() and not card:isKindOf("HegNullification") and not (player:hasSkill("jizhi") and card:isKindOf("Nullification")) then
			return ("nullification:kanpo[%s:%s]=%d%s"):format(suit, number, card_id, "&kanpo")
		end
	end
end

sgs.ai_cardneed.kanpo = function(to, card, self)
	return card:isBlack()
end

sgs.ai_suit_priority.kanpo= "diamond|heart|club|spade"

sgs.kanpo_suit_value = {
	spade = 3.9,
	club = 3.9
}

sgs.ai_skill_invoke.bazhen = function(self, data)
	if ((not self:willShowForDefence() and self:getCardsNum("Jink") > 1)
	or (not self:willShowForMasochism() and self:getCardsNum("Jink") == 0))
	then
			return false
	end
	return sgs.ai_skill_invoke.EightDiagram(self, data)
end

function sgs.ai_armor_value.bazhen(card)
	if not card then return 4 end
end

--刘禅
sgs.ai_skill_invoke.xiangle = function(self, data)
	local use = data:toCardUse()
	return not self:needToLoseHp(self.player, use.from, true)
end

sgs.ai_skill_cardask["@xiangle-discard"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then return "." end
	local has_peach, has_analeptic, has_slash, has_jink
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") then has_peach = card
		elseif card:isKindOf("Analeptic") then has_analeptic = card
		elseif card:isKindOf("Slash") then has_slash = card
		elseif card:isKindOf("Jink") then has_jink = card
		end
	end

	if has_slash then return "$" .. has_slash:getEffectiveId()
	elseif has_jink then return "$" .. has_jink:getEffectiveId()
	elseif has_analeptic or has_peach then
		if getCardsNum("Jink", target, self.player) == 0 and self.player:getMark("drank") > 0 and self:getAllPeachNum(target) == 0 then
			if has_analeptic then return "$" .. has_analeptic:getEffectiveId()
			else return "$" .. has_peach:getEffectiveId()
			end
		end
	else return "."
	end
end

function sgs.ai_slash_prohibit.xiangle(self, from, to, card)
	if self:isFriend(to, from) then return false end
	local slash_num, analeptic_num, jink_num
	if from:objectName() == self.player:objectName() then
		slash_num = self:getCardsNum("Slash")
		analeptic_num = self:getCardsNum("Analeptic")
		jink_num = self:getCardsNum("Jink")
	else
		slash_num = getCardsNum("Slash", from, self.player)
		analeptic_num = getCardsNum("Analeptic", from, self.player)
		jink_num = getCardsNum("Jink", from, self.player)
	end
	if card then
		if card:isVirtualCard() then
			slash_num = slash_num - card:getSubcards():length()
		else
			slash_num = slash_num - 1
		end
	end

	if self.player:getHandcardNum() == 2 then
		local needkongcheng = self:needKongcheng()
		if needkongcheng then return slash_num + analeptic_num + jink_num < 2 end
	end
	return slash_num + analeptic_num + math.max(jink_num - 1, 0) < 2
end

sgs.ai_skill_invoke.fangquan = function(self, data)
	if self.player:hasFlag("fangquanInvoked") then--已经发动过放权，配合当先
		return false
	end
	self.fangquan_card_str = nil
	self.fangquan_target = nil
	if #self.friends == 1 then
		return false
	end
	local limit = self.player:getMaxCards()
	if self.player:isKongcheng() then return false end
	if self:getCardsNum("Peach") >= limit - 2 and self.player:isWounded() then return false end

	-- First we'll judge whether it's worth skipping the Play Phase
	local cards = sgs.QList2Table(self.player:getHandcards())
	local shouldUse, range_fix = 0, 0
	local hasCrossbow, slashTo = false, false
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") and self:getUseValue(card) > 3.69 then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				shouldUse = shouldUse +  1
				if card:isKindOf("ExNihilo") or card:isKindOf("BefriendAttacking") or card:isKindOf("AllianceFeast") then
					shouldUse = shouldUse +  1
				end
			end
		end
		if card:isKindOf("Weapon") then
			local new_range = sgs.weapon_range[card:getClassName()]
			local current_range = self.player:getAttackRange()
			range_fix = math.min(current_range - new_range, 0)
		end
		if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix - 1 end
		if card:isKindOf("DefensiveHorse") or card:isKindOf("Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink") == 0) then shouldUse = shouldUse + 1 end
		if card:isKindOf("Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
	end


	local slashes = self:getCards("Slash")
	for _, enemy in ipairs(self.enemies) do
		for _, slash in ipairs(slashes) do
			if hasCrossbow and self:getCardsNum("Slash") > 1 and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) then
				shouldUse = shouldUse + 2
				hasCrossbow = false
				break
			elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) and getCardsNum("Jink", enemy, self.player) < 1 then
				shouldUse = shouldUse + 1
				slashTo = true
			end
		end
	end
	if self.player:hasSkill("shengxi") then
		shouldUse = shouldUse -  1
	end
	local liuba = sgs.findPlayerByShownSkillName("tongdu")
	if liuba and self.player:isFriendWith(liuba) then
		shouldUse = shouldUse -  1
	end
	if self.player:hasSkill("dangxian") then--当先
		shouldUse = shouldUse -  1
	end
	if shouldUse >= 2 then return false end

	-- Then we need to find the card to be discarded
	local to_discard = nil
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and self:getOverflow() <= 0 then return false end
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			to_discard = card:getEffectiveId()
			break
		end
	end
	if to_discard == nil then return false end

	-- At last we try to find the target
	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		self.fangquan_target = AssistTarget
		self.fangquan_card_str = "@FangquanCard=" .. to_discard .. "&fangquan->" .. AssistTarget:objectName()
		return true
	end

	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, target in ipairs(self.friends_noself) do--怎样优化一下目标？
		if target:hasShownSkills("zhiheng|" .. sgs.priority_skill .. "|shensu") and (not self:willSkipPlayPhase(target) or target:hasShownSkill("shensu")) then
			self.fangquan_target = target
			self.fangquan_card_str = "@FangquanCard=" .. to_discard .. "&fangquan->" .. target:objectName()
			return true
		end
	end
	return false
end

sgs.ai_skill_use["@@fangquan_ask"] = function(self, prompt)
	local fangquan_card = sgs.Card_Parse(self.fangquan_card_str)
	local in_handcard = true
	for _, id in sgs.qlist(fangquan_card:getSubcards()) do
		if not self.player:handCards():contains(id) then
			in_handcard = false
			break
		end
	end
	if in_handcard then return self.fangquan_card_str end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	if self.fangquan_target then
		for i = #cards, 1, -1 do
			local card = cards[i]
			if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
				return "@FangquanCard=" .. card:getEffectiveId() .. "&fangquan->" .. self.fangquan_target:objectName()
			end
		end
	end
end

sgs.ai_card_intention.FangquanCard = -120

--孟获
sgs.ai_skill_invoke.zaiqi = function(self, data)
	local lostHp = 2
	if self.player:hasSkill("rende") and #self.friends_noself > 0 and not self:willSkipPlayPhase() then lostHp = 3 end
	return self.player:getLostHp() >= lostHp
end

--祝融
sgs.ai_skill_invoke.juxiang = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() then
		return false
	end
	return true
end

sgs.ai_cardneed.lieren = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		if sgs.cardIsVisible(c, to, self.player) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	else
		return isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0
	end
end

sgs.ai_skill_invoke.lieren = function(self, data)
	local damage = data:toDamage()
	if not damage.to then return end
	if not self:isEnemy(damage.to) then return false end

	if self.player:getHandcardNum() == 1 then
		if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return true end
		local card = self.player:getHandcards():first()
		if card:isKindOf("Jink") or card:isKindOf("Peach") then return end
	end

	if (self.player:getHandcardNum() >= self.player:getHp() or self:getMaxNumberCard():getNumber() > 10
		or (self:needKongcheng() and self.player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective())
		and not self:doNotDiscard(damage.to, "h", true) and not (self.player:getHandcardNum() == 1 and self:doNotDiscard(damage.to, "e", true)) then
			return true
	end
	if self:doNotDiscard(damage.to, "he", true, 2) then return false end
	return false
end

function sgs.ai_skill_pindian.lieren(minusecard, self, requestor)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if requestor:objectName() == self.player:objectName() then
		return cards[1]:getId()
	end
	return self:getMaxNumberCard(self.player):getId()
end

--甘夫人
sgs.ai_skill_invoke.shushen = true

sgs.ai_skill_playerchosen.shushen = function(self, targets)
	if #self.friends_noself == 0 then return nil end
	return self:findPlayerToDraw(false, 1)
end

sgs.ai_card_intention.ShushenCard = -80

sgs.ai_skill_invoke.shenzhi = function(self, data)
	if self:getCardsNum("AllianceFeast") > 0 then return false end
	if self:getCardsNum("Peach") > 0 and self.player:getMark("GlobalBattleRoyalMode") == 0 then return false end
	if self.player:hasSkill("rende") and #self.friends_noself > 0
		and (self.player:getHp() > 1 or self.player:getHandcardNum() > 1) then
			return false
	end
	if self.player:getHandcardNum() >= 5 then return false end
	if self.player:getHandcardNum() == 3 and self.player:getHp() == 1 then return true end
	if self.player:getHandcardNum() >= 3 and not self:willSkipPlayPhase() then return false end
	if self.player:getHandcardNum() >= self.player:getHp() and self.player:isWounded() then return true end
	return false
end

function sgs.ai_cardneed.shenzhi(to, card)
	return to:getHandcardNum() < to:getHp()
end

sgs.ai_skill_invoke.huoshou = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() then
		return false
	end
	return true
end
