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
--transfer
local transfer_skill = {}
transfer_skill.name = "transfer"
table.insert(sgs.ai_skills, transfer_skill)
transfer_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("TransferCard") then return end
	if self.player:hasShownSkill("hongyuan") and not self.player:hasUsed("HongyuanCard") then
		return sgs.Card_Parse("@HongyuanCard=.&hongyuan")
	end
	local hongyuan_card = nil
	if self.player:hasShownSkill("hongyuan") and self.hongyuan_card_id then--不太好的处理办法,因为反馈+昭心之后,合纵标识没了
		hongyuan_card = sgs.Sanguosha:getCard(self.hongyuan_card_id)
	end
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if c:isTransferable() or (hongyuan_card and hongyuan_card:getEffectiveId() == c:getEffectiveId()) then 
			return sgs.Card_Parse("@TransferCard=.")
		end
	end
end

sgs.ai_skill_use_func.TransferCard = function(transferCard, use, self)
	--Global_room:writeToConsole("合纵连横判断开始:" ..self.player:objectName())
	local friends_shown, friends_other = {}, {}
	local targets = sgs.PlayerList()
	for _, friend in ipairs(self.friends_noself) do
		if transferCard:targetFilter(targets, friend, self.player)  then
			if friend:hasShownOneGeneral() then
				table.insert(friends_shown, friend)
			else
				table.insert(friends_other, friend)
			end
		end
	end

	local cards = {}
	local oneJink = false
	local CanUseBurningCamps = {}
	local function getBurningCampsValue(player,burning_camps)
		player = player or self.player
		burning_camps = burning_camps or sgs.cloneCard("burning_camps")
		if not burning_camps:isKindOf("BurningCamps") or burning_camps:isAvailable(player) then return 0 end
		local value = 0
		local NextPlayer = player:getNextAlive()
		if not self:isFriend(NextPlayer) and (not NextPlayer:isChained() or self:isGoodChainTarget(NextPlayer, player, sgs.DamageStruct_Fire)) then
			local damage = {}
			damage.nature = sgs.DamageStruct_Fire
			damage.damage = 1
			damage.from = player
			damage.card = burning_camps
			local chained_transfer
			for _, target in sgs.qlist(NextPlayer:getFormation()) do
				damage.to = target
				if self:trickIsEffective(c, target, player) and self:damageIsEffective_(damage) then
					value = value + 1
					if target:isChained() and self:isGoodChainTarget_(damage) and not chained_transfer then
						value = value + 1
						chained_transfer = true
					end
				end
			end
		end
		return value
	end
	local hongyuan_card = nil
	if self.player:hasShownSkill("hongyuan") and self.hongyuan_card_id then
		hongyuan_card = sgs.Sanguosha:getCard(self.hongyuan_card_id)
	end
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if (c:isTransferable() or (hongyuan_card and hongyuan_card:getEffectiveId() == c:getEffectiveId()))
			and (not isCard("Peach", c, self.player) or #friends_shown > 0) then
			if not oneJink and isCard("Jink", c, self.player) then
				oneJink = true
				continue
			elseif self:hasCrossbowEffect() and c:isKindOf("Slash") then
				continue
			elseif self.player:isBigKingdomPlayer() and c:isKindOf("ThreatenEmperor") then
				continue
			elseif self:isWeak() and isCard("Peach", c, self.player) and c:isAvailable(self.player) and self.player:canRecover() then
				continue
			elseif c:isKindOf("BurningCamps") and c:isAvailable(self.player) then--优先考虑自己用火烧
				local value = getBurningCampsValue(self.player,c)
				if value > 0 then
					CanUseBurningCamps[c:getEffectiveId()] = value
				end
			elseif self.player:getMark("GlobalBattleRoyalMode") > 0
				and (isCard("Analeptic", c, self.player) or isCard("BurningCamps", c, self.player) or isCard("Breastplate", c, self.player)) then
				continue
			elseif c:getNumber() > 10 and self.player:hasSkills("tianyi|quhu|shuangren|lieren") then
				continue
			end
			table.insert(cards, c)
		end
	end
	local card_list = {}
	local target
	local card_str

	local has_TE = false
	local has_BC = false
	for _, card in ipairs(cards) do
		if card:isKindOf("ThreatenEmperor") then
			has_TE = true
		end
		if card:isKindOf("BurningCamps") then
			has_BC = true
		end
	end

	if has_TE or has_BC then
			local big_kingdoms = self.player:getBigKingdoms("AI")
			if self.player:isBigKingdomPlayer() then
				for _, card in ipairs(cards) do
					if card:isKindOf("ThreatenEmperor") then--大势力留下挟天子
						table.removeOne(cards, card)
						Global_room:writeToConsole("大势力留下挟天子")
					end
				end
				has_TE = false
			end
		if has_TE then--同时有火烧和挟天子时目标是否合适？
			--Global_room:writeToConsole("合纵连横判断挟天子:" ..self.player:objectName())
			local anjiang = 0
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if sgs.isAnjiang(p) then anjiang = anjiang + 1 end
			end
			local big_kingdom = #big_kingdoms > 0 and big_kingdoms[1]
			local maxNum = (big_kingdom and (big_kingdom:startsWith("sgs") and 99 or self.player:getPlayerNumWithSameKingdom("AI", big_kingdom)))
							or (anjiang == 0 and 99)
							or 0
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasShownOneGeneral() and transferCard:targetFilter(targets, p, self.player)
					and p:objectName() ~= big_kingdom and (not table.contains(big_kingdoms, p:getKingdom()) or p:getRole() == "careerist")
					and (maxNum == 99 or p:getPlayerNumWithSameKingdom("AI") + anjiang < maxNum) then
						target = p
						break
				end
			end
		elseif has_BC then
			--Global_room:writeToConsole("合纵连横判断火烧连营:" ..self.player:objectName())
			local gameProcess = sgs.gameProcess(true)
			if string.find(gameProcess, self.player:getKingdom() .. ">>>") then--必须要>个数多的在前，因为只会find第一个>
				for _, card in ipairs(cards) do
					if card:isKindOf("BurningCamps") then--大国？火烧联营不能给
						table.removeOne(cards, card)
						Global_room:writeToConsole(">>>大优势，火烧联营不能给")
					end
				end
			elseif string.find(gameProcess, self.player:getKingdom() .. ">>")  then
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if p:hasShownOneGeneral() and transferCard:targetFilter(targets, p, self.player) then
						local np = p:getNextAlive()
						if not self:isFriend(np) and (not np:isChained() or self:isGoodChainTarget(np, p, sgs.DamageStruct_Fire)) then
							target = p
							Global_room:writeToConsole(">>小优势")
							break
						end
					end
				end
			elseif string.find(gameProcess, self.player:getKingdom() .. ">") then
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					local np = p:getNextAlive()
					if transferCard:targetFilter(targets, p, self.player) and self:isFriend(p)--盟军下家是敌人
					--[[ or (p:hasShownOneGeneral() and self:willSkipPlayPhase(p))]]--
					and (not self:isFriend(np) or self:isGoodChainTarget(np, p, sgs.DamageStruct_Fire)) then
						target = p
						break
					end
				end
			end
		end
		if target and #cards > 0 then
			--Global_room:writeToConsole("合纵连横含重要卡牌对象:" .. target:objectName())
			for _, card in ipairs(cards) do
				local self_use = false
				for i,v in pairs(CanUseBurningCamps) do
					if card:getEffectiveId() ~= i then continue end
					local value = getBurningCampsValue(target,card)
					if v > value then
						self_use = true
						break
					end
				end
				if self_use then
					Global_room:writeToConsole("火烧联营自己用")
					continue
				end
				table.insert(card_list, card:getEffectiveId())
				if #card_list == 3 then
					break
				end
			end
			card_str = "@TransferCard=" .. table.concat(card_list, "+")
			use.card = sgs.Card_Parse(card_str)
			if use.to then use.to:append(target) end
			--Global_room:writeToConsole("合纵连横含重要卡牌:" .. card_str)
			return
		end
	end

	if #cards == 0 then return end
	for _, card in ipairs(cards) do
		table.insert(card_list, card:getEffectiveId())
		if #card_list == 3 then
			break
		end
	end
	card_str = "@TransferCard=" .. table.concat(card_list, "+")

	assert(sgs.Card_Parse(card_str))

	if #friends_shown > 0 then
		--Global_room:writeToConsole("有明置的友方")
		self:sortByUseValue(cards)
		if #friends_shown > 0 then
			local c, p = self:getCardNeedPlayer(cards, friends_shown, "transfer")
			if p then
				use.card = sgs.Card_Parse(card_str)
				if use.to then use.to:append(p) end
				--Global_room:writeToConsole("合纵连横卡牌对象:" .. p:objectName())
				--Global_room:writeToConsole("合纵连横卡牌:" .. card_str)
				return
			end
		end
	end

	if #friends_other > 0 then
		--Global_room:writeToConsole("有暗置的友方")
		local c, p = self:getCardNeedPlayer(cards, friends_other, "transfer")
		if p then
			use.card = sgs.Card_Parse(card_str)
			if use.to then use.to:append(p) end
			--Global_room:writeToConsole("合纵连横卡牌对象:" .. p:objectName())
			--Global_room:writeToConsole("合纵连横卡牌:" .. card_str)
			return
		end
	end
end

sgs.ai_use_priority.TransferCard = 3--合纵连横效果修改
sgs.ai_card_intention.TransferCard = -40

--Drowning
function SmartAI:useCardDrowning(card, use)
	if not card:isAvailable(self.player) then return end

	self:sort(self.enemies, "equip_defense")

	local players = sgs.PlayerList()
	for _, enemy in ipairs(self.enemies) do
		if card:targetFilter(players, enemy, self.player) and not players:contains(enemy) and enemy:hasEquip()
			and self:trickIsEffective(card, enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player, card) and self:canAttack(enemy)
			and not self:needDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy, self.player) and not self:needToThrowArmor(enemy)
			and not (enemy:hasArmorEffect("PeaceSpell") and (enemy:getHp() > 1 or self:needToLoseHp(enemy, self.player)))--太平考虑张鲁？
			and not (enemy:hasArmorEffect("Breastplate") and enemy:getHp() == 1) then
			local dangerous
			local chained = {}
			if enemy:isChained() then
				for _, p in sgs.qlist(self.room:getOtherPlayers(enemy)) do
					if not self:isGoodChainTarget(enemy, p, sgs.DamageStruct_Thunder) and self:damageIsEffective(p, sgs.DamageStruct_Thunder, self.player, card) and self:isFriend(p) then
						table.insert(chained, p)
						if self:isWeak(p) then dangerous = true end
					end
				end
			end
			if #chained >= 2 then dangerous = true end
			if not dangerous then
				players:append(enemy)
				if use.to then use.to:append(enemy) end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if card:targetFilter(players, friend, self.player) and not players:contains(friend) and friend:getEquips():length() == 1 and self:trickIsEffective(card, friend)
		and (self:needToThrowArmor(friend) or (friend:hasShownSkills(sgs.lose_equip_skill) and not friend:getArmor() and not friend:getTreasure())) then
			players:append(friend)
			if use.to then use.to:append(friend) end
		end
	end

	if not players:isEmpty() then
		use.card = card
		return
	end
end

sgs.ai_card_intention.Drowning = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		if not self:trickIsEffective(card, to, from) or not self:damageIsEffective(to, sgs.DamageStruct_Thunder, from, card)
			or self:needToThrowArmor(to) then
		else
			sgs.updateIntention(from, to, 80)
		end
	end
end

sgs.ai_skill_choice.drowning = function(self, choices, data)
	local effect = data:toCardEffect()
	local dangerous
	local chained = {}

	--@tudo制蛮
	if self:damageIsEffective(self.player, sgs.DamageStruct_Thunder, effect.from, effect.card) and self.player:isChained() then
		if self:isGoodChainTarget(self.player, effect.from, sgs.DamageStruct_Thunder) then return "damage" end
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not self:isGoodChainTarget(self.player, p, sgs.DamageStruct_Thunder) and self:damageIsEffective(p, sgs.DamageStruct_Thunder, effect.from, effect.card) and self:isFriend(p) then
				table.insert(chained, p)
				if self:isWeak(p) then dangerous = true end
			end
		end
	end
	if #chained > 0 then dangerous = true end

	if self.player:getArmor() and self:needToThrowArmor() and self.player:getEquips():length() == 1 then return "throw" end		
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Thunder, effect.from, effect.card) then return "damage" end

	if self.player:hasSkill("tianxiang") and getKnownCard(self.player, self.player, "heart", true, "h") > 0 then
		return "damage"
	end

	if dangerous and not self.player:hasArmorEffect("Breastplate") then return "throw" end--危险和多装备的详细判断？

	if (self:needToLoseHp(self.player, effect.from) or self:needDamagedEffects(self.player, effect.from)) and not dangerous then return "damage" end

	if self.player:hasTreasure("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then
		for _,id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):isKindOf("Peach") or (sgs.Sanguosha:getCard(id):isKindOf("Analeptic") and self.player:getHp() == 1) then
				return "damage"
			end
		end
	end
	if self.player:getHp() == 1 and not self.player:hasArmorEffect("Breastplate") then return "throw" end--有桃？

	if self.player:hasSkills(sgs.lose_equip_skill) and self.player:getEquips():length() == 1 then
		return "throw"
	end

	local value = 0
	for _, equip in sgs.qlist(self.player:getEquips()) do--值是否合适？
		if equip:isKindOf("Weapon") then value = value + (self:evaluateWeapon(equip) > 8 and 4 or 2)
		elseif equip:isKindOf("Armor") then
			value = value + self:evaluateArmor(equip)
			if self:needToThrowArmor() then value = value - 5
			elseif equip:isKindOf("Breastplate") and self.player:getHp() <= 1 then value = value + 99
			elseif equip:isKindOf("PeaceSpell") then value = value + 99
			end
		elseif equip:isKindOf("OffensiveHorse") then value = value + 2
		elseif equip:isKindOf("DefensiveHorse") then value = value + 3
		elseif equip:isKindOf("SixDragons") then value = value + 4.5
		elseif equip:isKindOf("Treasure") then
			if equip:isKindOf("WoodenOx") then
				value = value + 2
				for _,id in sgs.qlist(self.player:getPile("wooden_ox")) do
					local c = sgs.Sanguosha:getCard(id)
					value = value + (sgs.ai_keep_value[c:getClassName()] or 0)
				end
			else
				value = value + 4
			end
		end
	end
	if self.player:getHp() == 1 and not self.player:hasArmorEffect("Breastplate") then
		if value > 12 and (self:getAllPeachNum() > 0
			or (self.player:hasSkill("buqu") and self.player:getPile("scars"):length() <= 4)
			or (self.player:hasSkill("jizhao") and self.player:getMark("@jizhao") > 0)) then
				return "damage"
		else
			return "throw"
		end
	end
	if value < 7 then--值是否合适？
		return "throw"
	elseif value < 12 and self.player:getHp() == 2 then
		return "throw"
	else
		return "damage"
	end
end

sgs.ai_nullification.Drowning = function(self, card, from, to, positive, keep)
	if positive then
		if self:isFriend(to) then
			if self:needToThrowArmor(to) then return end
			if to:getEquips():length() >= 2 then return true, true end
		end
		if self.player:objectName() == to:objectName() then
			if self.player:hasTreasure("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then--水淹七军丢木马里的无懈怎么处理
				for _,id in sgs.qlist(self.player:getPile("wooden_ox")) do--无法判断丢牌是否合适，木马里有无懈就打
					if sgs.Sanguosha:getCard(id):isKindOf("Nullification") then
						return true, true
					end
				end
			end
		end
	else
		if not keep and self:isFriend(from) and (self:getOverflow() > 0 or self:getCardsNum("Nullification") > 1) then return true, true end
	end
end

sgs.ai_use_value.Drowning = 5.3
sgs.ai_use_priority.Drowning = sgs.ai_use_priority.Dismantlement + 0.05
sgs.ai_keep_value.Drowning = 3.4

--IronArmor
function sgs.ai_armor_value.IronArmor(player, self)
	if self:isWeak(player) then
		for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
			if p:hasShownSkill("huoji") and self:isEnemy(player, p) then
				return 3.5
			end
		end
	end
	local lp = player:getLastAlive()
	while (player:isFriendWith(lp) and lp:objectName() ~= player:objectName()) do--防止调虎离山上家是自己死循环
		lp = lp:getLastAlive()--找到队列的上家
	end
	if not self:isFriend(player,lp) and (lp:hasShownSkills("qice|yigui") or getKnownCard(lp, player, "BurningCamps") > 0) then--上家有奇策、役鬼,火烧
		return 4.5
	end
	for _, enemy in ipairs(self:getEnemies(player)) do
		if not self:isFriend(player,lp) and getKnownCard(enemy, player, "BurningCamps") > 0 then--敌方可能合纵连横火烧
			return 3.5
		end
	end
	return 2.5
end

sgs.ai_use_priority.IronArmor = 0.82

--BurningCamps
function SmartAI:useCardBurningCamps(card, use)
	if not card:isAvailable(self.player) then return end

	local NextPlayer = self.room:nextPlayer(self.player)
	local SelfisTarget = self:isFriendWith(NextPlayer)
	--if self:isFriendWith(NextPlayer) then return end

	local targets = NextPlayer:getFormation()
	if targets:isEmpty() then return end
	local shouldUse
	local value = 0
	for i = 0 , targets:length() - 1 do
		local target = self.room:findPlayerbyobjectName(targets:at(i):objectName())
		if not self:trickIsEffective(card, target, self.player) then
			continue
		end
		local damage = {}
		damage.from = self.player
		damage.to = target
		damage.card = card
		damage.nature = sgs.DamageStruct_Fire
		damage.damage = 1
		if self:damageIsEffective_(damage) then
			if SelfisTarget then
				local goodHp = target:getHp() > 1 or not self:isWeak(target)
					or getCardsNum("Peach", target, self.player) >= 1 or getCardsNum("Analeptic", target, self.player) >= 1
				if not goodHp then
					return
				elseif target:isChained() then
					if self:isGoodChainTarget_(damage) then
						value = value + 2
					else
						value = value - 3
					end
				elseif self:needToLoseHp(target, self.player) then
					value = value + 3
				elseif self:needDamagedEffects(target, self.player) and not self:isWeak(target) then
					value = value + 2
				else
					value = value - 2
				end
			else
				if target:isChained() and self:isGoodChainTarget_(damage) then
					shouldUse = true
				elseif self:objectiveLevel(target) > 3.5 then
					--self.player:speak("objectivelevel大于3.5")
					shouldUse = true
				else
					return
				end
			end
		end
	end
	if shouldUse or value > 0 then
		local chaincard = self:getCard("FightTogether")
		if chaincard and not chaincard:getEffectiveId() == card:getEffectiveId() then
			use.card = chaincard
			return
		end
		chaincard = self:getCard("IronChain")
		if chaincard and not chaincard:getEffectiveId() == card:getEffectiveId() and #self.enemies > 1 then
			local num = 0
			for _, p in ipairs(self.enemies) do
				if not p:isChained() and p:canBeChainedBy(self.player) then num = num + 1 end
			end
			if num > 1 then
				use.card = chaincard
				return
			end
		end
		use.card = card
	end
end

sgs.ai_nullification.BurningCamps = function(self, card, from, to, positive, keep)
	local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. card:toString()):toList()
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
	end
	if positive then
		if from:objectName() == self.player:objectName() then return false end
		local chained = {}
		local dangerous
		if self:damageIsEffective(to, sgs.DamageStruct_Fire, from, card) and to:isChained() then
			for _, p in sgs.qlist(self.room:getOtherPlayers(to)) do
				if not self:isGoodChainTarget(to, p, sgs.DamageStruct_Fire) and self:damageIsEffective(p, sgs.DamageStruct_Fire, from, card) and self:isFriend(p) then
					table.insert(chained, p)
					if self:isWeak(p) then dangerous = true end
				end
			end
		end
		if to:hasArmorEffect("Vine") and #chained > 0 then dangerous = true end
		local friends = {}
		if self:isFriend(to) then
			for _, p in sgs.qlist(targets) do
				if self:damageIsEffective(p, sgs.DamageStruct_Fire, from, card) then
					table.insert(friends, p)
					if self:isWeak(p) or p:hasArmorEffect("Vine") then dangerous = true end
				end
			end
		end
		if #chained + #friends > 2 or dangerous then return true, #friends <= 1 end
		if keep then return false end
		if self:isFriendWith(to) and self:isEnemy(from) then return true, #friends <= 1 end
	else
		if not self:isFriend(from) then return false end
		local chained = {}
		local dangerous
		local enemies = {}
		local good
		if self:damageIsEffective(to, sgs.DamageStruct_Fire, from, card) and to:isChained() then
			for _, p in sgs.qlist(self.room:getOtherPlayers(to)) do
				if not self:isGoodChainTarget(to, p, sgs.DamageStruct_Fire) and self:damageIsEffective(p, sgs.DamageStruct_Fire, from, card) and self:isFriend(p) then
					table.insert(chained, p)
					if self:isWeak(p) then dangerous = true end
				end
				if not self:isGoodChainTarget(to, p, sgs.DamageStruct_Fire) and self:damageIsEffective(p, sgs.DamageStruct_Fire, from, card) and self:isEnemy(p) then
					table.insert(enemies, p)
					if self:isWeak(p) then good = true end
				end
			end
		end
		if to:hasArmorEffect("Vine") and #chained > 0 then dangerous = true end
		if to:hasArmorEffect("Vine") and #enemies > 0 then good = true end
		local friends = {}
		if self:isFriend(to) then
			for _, p in sgs.qlist(targets) do
				if self:damageIsEffective(p, sgs.DamageStruct_Fire, from, card) then
					table.insert(friends, p)
					if self:isWeak(p) or p:hasArmorEffect("Vine") then dangerous = true end
				end
			end
		end
		if self:isEnemy(to) then
			for _, p in sgs.qlist(targets) do
				if self:damageIsEffective(p, sgs.DamageStruct_Fire, from, card) then
					if self:isWeak(p) or p:hasArmorEffect("Vine") then good = true end
				end
			end
		end
		if #chained + #friends > 2 or dangerous then return false end
		if keep then
			local nulltype = self.room:getTag("NullificatonType"):toBool()
			if nulltype and targets:length() > 1 then good = true end
			if good then keep = false end
		end
		if keep then return false end
		if self:isFriend(from) and self:isEnemy(to) then return true, true end
	end
	return
end

sgs.ai_use_value.BurningCamps = 7.1
sgs.ai_use_priority.BurningCamps = 4.7
sgs.ai_keep_value.BurningCamps = 3.38
sgs.ai_card_intention.BurningCamps = 120

--Breastplate
sgs.ai_skill_invoke.Breastplate = function(self, data)
	--没有装填data
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.to and damage.to:objectName() == self.player:objectName() and self.player:isChained() and damage.nature ~= sgs.DamageStruct_Normal and not damage.chain then
		--队友造成的非传导(传导起点)属性伤害,考虑不发动
		if self:isGoodChainTarget(self.player, damage.from, damage.nature) and not (damage.from and self:isEnemy(damage.from)) then
			return false
		end
	end
	return true
end

function sgs.ai_armor_value.Breastplate(player, self)
	if player:getHp() >= 3 then
		return 2
	else
		return 5.5
	end
end

sgs.ai_use_priority.Breastplate = 0.9

--LureTiger
function SmartAI:useCardLureTiger(LureTiger, use)
	sgs.ai_use_priority.LureTiger = 4.9
	if not LureTiger:isAvailable(self.player) then return end

	local players = sgs.PlayerList()

	local card = self:getCard("BurningCamps")
	if card and card:isAvailable(self.player) then
		local nextp = self.room:nextPlayer(self.player)
		local first
		while true do
			if LureTiger:targetFilter(players, nextp, self.player) and self:trickIsEffective(LureTiger, nextp, self.player) then
				if not first then
					if self:isEnemy(nextp) and self:trickIsEffective(card, nextp, self.player) then--火烧考虑明光铠和帷幕
						first = nextp
					else
						players:append(nextp)
					end
				else
					if not first:isFriendWith(nextp) then
						players:append(nextp)
					end
				end
				nextp = self.room:nextPlayer(nextp)
			else
				--调虎目标达到上限时,不满足targetFilter,仍然需要判断火烧first是否有益
				if players:length() >= 2 and not first and self:isEnemy(nextp) and self:trickIsEffective(card, nextp, self.player) then first = nextp end
				break
			end
		end
		if first and not players:isEmpty() then
			use.card = LureTiger
			if use.to then use.to = sgs.PlayerList2SPlayerList(players) end
			return
		end
	end

	players = sgs.PlayerList()

	card = self:getCard("ArcheryAttack")
	if card and card:isAvailable(self.player) and self:getAoeValue(card) > 0 and #self.friends_noself > 0 then
		self:sort(self.friends_noself, "hp")
		for _, friend in ipairs(self.friends_noself) do
			if self:isFriendWith(friend) and LureTiger:targetFilter(players, friend, self.player)
			and self:trickIsEffective(LureTiger, friend, self.player) and self:aoeIsEffective(card, friend, self.player) then
				players:append(friend)
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if LureTiger:targetFilter(players, friend, self.player) and not players:contains(friend)
			and self:trickIsEffective(LureTiger, friend, self.player) and self:aoeIsEffective(card, friend, self.player) then
				players:append(friend)
			end
		end
		if players:length() > 0 then
			sgs.ai_use_priority.LureTiger = sgs.ai_use_priority.ArcheryAttack + 0.2
			use.card = LureTiger
			if use.to then use.to = sgs.PlayerList2SPlayerList(players) end
			return
		end
	end

	players = sgs.PlayerList()

	card = self:getCard("SavageAssault")
	if card and card:isAvailable(self.player) and self:getAoeValue(card) > 0 and #self.friends_noself > 0 then
		self:sort(self.friends_noself, "hp")
		for _, friend in ipairs(self.friends_noself) do
			if self:isFriendWith(friend) and LureTiger:targetFilter(players, friend, self.player)
			and self:trickIsEffective(LureTiger, friend, self.player) and self:aoeIsEffective(card, friend, self.player) then
				players:append(friend)
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if LureTiger:targetFilter(players, friend, self.player) and not players:contains(friend)
			and self:trickIsEffective(LureTiger, friend, self.player) and self:aoeIsEffective(card, friend, self.player) then
				players:append(friend)
			end
		end
		if players:length() > 0 then
			sgs.ai_use_priority.LureTiger = sgs.ai_use_priority.SavageAssault + 0.2
			use.card = LureTiger
			if use.to then use.to = sgs.PlayerList2SPlayerList(players) end
			return
		end
	end

	players = sgs.PlayerList()

	card = self:getCard("Slash")
	if card and self:slashIsAvailable(self.player, card) then
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self.player:setFlags("slashNoDistanceLimit")
		self:useCardSlash(card, dummyuse)
		self.player:setFlags("-slashNoDistanceLimit")
		if dummyuse.card then
			local total_num = 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, LureTiger)
			local function getPlayersFromTo(one)
				local targets1 = sgs.PlayerList()
				local targets2 = sgs.PlayerList()
				local nextp = self.room:nextPlayer(self.player)
				while true do
					if LureTiger:targetFilter(targets1, nextp, self.player) and self:trickIsEffective(LureTiger, nextp, self.player) then
						if one:objectName() ~= nextp:objectName() then
							targets1:append(nextp)
						else
							break
						end
						nextp = self.room:nextPlayer(nextp)
					else
						targets1 = sgs.PlayerList()
						break
					end
				end
				nextp = self.room:nextPlayer(one)
				while true do
					if LureTiger:targetFilter(targets2, nextp, self.player) and self:trickIsEffective(LureTiger, nextp, self.player) then
						if self.player:objectName() ~= nextp:objectName() then
							targets2:append(nextp)
						else
							break
						end
						nextp = self.room:nextPlayer(nextp)
					else
						targets2 = sgs.PlayerList()
						break
					end
				end
				if targets1:length() > 0 and targets2:length() >= targets1:length() and targets1:length() <= total_num then
					return targets1
				elseif targets2:length() > 0 and targets1:length() >= targets2:length() and targets2:length() <= total_num then
					return targets2
				end
				return
			end

			for _, to in sgs.qlist(dummyuse.to) do
				if self.player:distanceTo(to) > self.player:getAttackRange() and self.player:distanceTo(to, -total_num) <= self.player:getAttackRange() then
					local sps = getPlayersFromTo(to)
					if sps then
						sgs.ai_use_priority.LureTiger = 3
						use.card = LureTiger
						if use.to then use.to = sgs.PlayerList2SPlayerList(sps) end
						return
					end
				end
			end
		end

	end

	players = sgs.PlayerList()

	card = self:getCard("GodSalvation")
	if card and card:isAvailable(self.player) and #self.enemies > 0 then
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if LureTiger:targetFilter(players, enemy, self.player) and self:trickIsEffective(LureTiger, enemy, self.player) then
				players:append(enemy)
			end
		end
		if players:length() > 0 then
			sgs.ai_use_priority.LureTiger = sgs.ai_use_priority.GodSalvation + 0.1
			use.card = LureTiger
			if use.to then use.to = sgs.PlayerList2SPlayerList(players) end
			return
		end
	end

	players = sgs.PlayerList()

	local can_slash, can_duel, can_fireattack = false,false,false
	local slash = self:getCard("Slash")
	if slash and self:slashIsAvailable(self.player, slash) then
		can_slash = true
	end
	local duel = self:getCard("Duel")
	if duel and duel:isAvailable(self.player) then
		can_duel = true
	end
	local fire_attack = self:getCard("FireAttack")
	if fire_attack and fire_attack:isAvailable(self.player) then
		can_fireattack = true
	end
	if (can_slash or can_duel or can_fireattack) and #self.enemies > 1 then--调离敌方队友防救人
		local enemys_copy = table.copyFrom(self.enemies)
		self:sort(enemys_copy, "hp")
		local to
		for _, p in ipairs(enemys_copy) do
			if p:getHp() == 1 and ((can_duel and self:trickIsEffective(duel, p, self.player)) or (can_fireattack and self:trickIsEffective(fire_attack, p, self.player))
				or (can_slash and self.player:canSlash(p, slash, true) and not self:slashProhibit(slash, p)
				and self:slashIsEffective(slash, p) and sgs.isGoodTarget(p, enemys_copy, self)
				and not (self.player:hasFlag("slashTargetFix") and not p:hasFlag("SlashAssignee")))) then
					to = p
					table.removeOne(enemys_copy, to)
					break
			end
		end
		if to then
			if can_slash and self:hasCrossbowEffect() and self:getCardsNum("Slash") > 2 then
				local slash_num = self:getCardsNum("Slash")
				for _, enemy in ipairs(enemys_copy) do
					if  (sgs.getDefenseSlash(enemy, self) <= 2 or (enemy:getHandcardNum() < 3 and enemy:getHp() <= slash_num))
						and self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, enemys_copy, self)
						and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
							slash_num = slash_num - enemy:getHp()
							table.removeOne(enemys_copy, enemy)
					end
				end
			end
			self:sort(enemys_copy, "handcard", true)
			if #enemys_copy > 0 then
				for _, enemy in ipairs(enemys_copy) do
					if LureTiger:targetFilter(players, enemy, self.player) and self:trickIsEffective(LureTiger, enemy, self.player)
					and enemy:objectName() ~= to:objectName() and enemy:isFriendWith(to) then
						players:append(enemy)
					end
				end
				local total_num = 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, LureTiger)
				if players:length() < total_num then
					for _, enemy in ipairs(enemys_copy) do
						if LureTiger:targetFilter(players, enemy, self.player) and self:trickIsEffective(LureTiger, enemy, self.player)
						and enemy:objectName() ~= to:objectName() and self:isFriend(enemy,to) then
							players:append(enemy)
						end
					end
				end
				if players:length() < total_num then
					for _, enemy in ipairs(enemys_copy) do
						if LureTiger:targetFilter(players, enemy, self.player) and self:trickIsEffective(LureTiger, enemy, self.player)
						and enemy:objectName() ~= to:objectName() then
							players:append(enemy)
						end
					end
				end
			end
			if players:length() > 0 then
				if can_slash or can_duel then
					sgs.ai_use_priority.LureTiger = sgs.ai_use_priority.Duel + 0.1
				end
				if can_fireattack then
					sgs.ai_use_priority.LureTiger = sgs.ai_use_priority.FireAttack + 0.1
				end
				use.card = LureTiger
				if use.to then use.to = sgs.PlayerList2SPlayerList(players) end
				return
			end
		end
	end

	players = sgs.PlayerList()
	card = self:getCard("AmazingGrace")
	if card and card:isAvailable(self.player) and #self.enemies > 0 then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if LureTiger:targetFilter(players, enemy, self.player) and self:trickIsEffective(LureTiger, enemy, self.player) then
				players:append(enemy)
			end
		end
		if players:length() > 0 then
			sgs.ai_use_priority.LureTiger = sgs.ai_use_priority.AmazingGrace + 0.1
			use.card = LureTiger
			if use.to then use.to = sgs.PlayerList2SPlayerList(players) end
			return
		end
	end

	players = sgs.PlayerList()
	local xuyou = sgs.findPlayerByShownSkillName("chenglve")
	local aoedraw = xuyou and self.player:isFriendWith(xuyou)

	if self.player:hasShownSkill("jizhi") or aoedraw then
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if LureTiger:targetFilter(players, player, self.player) and self:trickIsEffective(LureTiger, player, self.player) then
				players:append(player)
			end
		end
		if (self.player:hasShownSkill("jizhi") and players:length() > 0) or (aoedraw and players:length() > 1) then
			sgs.ai_use_priority.LureTiger = 0.4
			use.card = LureTiger
			if use.to then use.to = sgs.PlayerList2SPlayerList(players) end
			return
		end
	end
end

sgs.ai_nullification.LureTiger = function(self, card, from, to, positive)
--[[
	if positive then
		if self:isFriendWith(to) and self:isEnemy(from) then return true end
	else
		if self:isFriend(from) and self:isEnemy(to) then return true end
	end
	return
--]]
	return false
end

sgs.ai_use_value.LureTiger = 4.8
sgs.ai_use_priority.LureTiger = 4.9
sgs.ai_keep_value.LureTiger = 2.5

--FightTogether
function SmartAI:useCardFightTogether(card, use)
	local needTarget = (card:getSkillName() == "guhuo" or card:getSkillName() == "nosguhuo" or card:getSkillName() == "qice" 
		or card:getSkillName() == "yigui" or card:getSkillName() == "miewu" or card:getSkillName() == "tiandian" or card:getSkillName() == "xuanyan")
	if not card:isAvailable(self.player) then return end

	local bigs, smalls = {}, {}
	local IamBig, IamSmall = false, false
	local chained_num = 0
	--只连一个人且不能传导时考虑重铸
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isChained() then chained_num = chained_num + 1 end
		if p:isBigKingdomPlayer() then
			if p:objectName() == self.player:objectName() then IamBig = true end
			if self:trickIsEffective(card, p, self.player) then
				table.insert(bigs, p)
			end
		else
			if p:objectName() == self.player:objectName() then IamSmall = true end
			if self:trickIsEffective(card, p, self.player) and not (p:hasArmorEffect("IronArmor") and not p:isChained()) then
				table.insert(smalls, p)
			end
		end
	end

	local choices = {}
	if #bigs > 0 then table.insert(choices, "big") end
	if #bigs > 0 and #smalls > 0 then table.insert(choices, "small") end
	
	if #choices > 0 then
		local v_big, v_small = 0, 0
		local gameProcess = sgs.gameProcess(true)
		if table.contains(choices, "big") then
			for _, p in ipairs(bigs) do
				if self:isFriend(p) then
					if p:isChained() then
						v_big = v_big + 1
					else
						v_big = v_big - 1
						--2敌2己+4暗,理论上应连小势力而不是己方大势力
						if IamBig then 
							v_big = v_big - 1
						end
					end
				elseif self:isEnemy(p) then
					if p:isChained() or (p:hasShownSkill("danlao") and #bigs > 1) then
						v_big = v_big - 1
					else
						if (p:hasShownOneGeneral() and string.find(gameProcess, p:getKingdom() .. ">>"))
						or (IamSmall and string.find(gameProcess, self.player:getKingdom() .. ">>"))
						or self.player:hasSkill("fenming") then
							v_big = v_big + 2
						else
							v_big = v_big + 1
						end
					end
				else
					v_big = v_big + 0.5
				end
			end
		end
		if table.contains(choices, "small") then
			for _, p in ipairs(smalls) do
				if self:isFriend(p) then
					if p:isChained() then
						v_small = v_small + 1
					else
						v_small = v_small - 1
						if IamSmall then 
							v_big = v_big - 1
						end
					end
				elseif self:isEnemy(p) then
					if p:isChained() or (p:hasShownSkill("danlao") and #smalls > 1) then
						v_small = v_small - 1
					else
						if (p:hasShownOneGeneral() and string.find(gameProcess, p:getKingdom() .. ">>"))
						or (IamBig and string.find(gameProcess, self.player:getKingdom() .. ">>"))
						or self.player:hasSkill("fenming") then
							v_small = v_small + 2
						else
							v_small = v_small + 1
						end
					end
				else
					v_small = v_small + 0.5
				end
			end
		end
		local win = math.max(v_small, v_big)
		if win > 1 then
			--只连一个人且不能传导时考虑重铸
			if win == v_big and not (#bigs == 1 and chained_num == 0) then
				use.card = card
				if use.to and #bigs > 0 then use.to:append(bigs[1]) end
				return
			elseif win == v_small and not (#smalls == 1 and chained_num == 0) then
				use.card = card
				if use.to and #smalls > 0 then use.to:append(smalls[1]) end
				return
			end
		end
	end

	if not self.player:isCardLimited(card, sgs.Card_MethodRecast) and card:canRecast() and not needTarget then
		use.card = card
		return
	end
end

sgs.ai_nullification.FightTogether = function(self, card, from, to, positive, keep)
	local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. card:toString()):toList()
	for _, q in sgs.qlist(players) do
		if to:isFriendWith(q:toPlayer()) then
			targets:append(q:toPlayer())
		end
	end
	local ed, no = 0, 0
	if positive then
		if to:isChained() and not keep then
			if self:isEnemy(to) and to:hasShownSkills(sgs.cardneed_skill) then
				for _, p in sgs.qlist(targets) do
					if p:isChained() then ed = ed + 1 else no = no + 1 end
				end
				if ed > 2 and ed > no then
					if self.room:getTag("NullifyingTimes"):toInt() == 0 and self:getCard("HegNullification") then
						return true, false
					end
					if self.room:getTag("NullifyingTimes"):toInt() > 0 then
						return true, true
					end
				end
			end
		else
			if self:isFriendWith(to) then
				for _, p in sgs.qlist(targets) do
					if p:hasArmorEffect("Vine") then
						return true, false
					end
					if p:isChained() then
						ed = ed + 1
					elseif self:isWeak(p) then
						no = no + 1
					end
				end
				if no > 1 and no >= ed then
					if self.room:getTag("NullifyingTimes"):toInt() == 0 and self:getCard("HegNullification") then
						return true, false
					end
					if self.room:getTag("NullifyingTimes"):toInt() > 0 then
						return true, true
					end
				end
			end
		end
	else
		if not keep and self.room:getTag("NullifyingTimes"):toInt() > 0 and self.room:getTag("NullificatonType"):toBool()
		and self:isFriendWith(to) and to:isChained() then--对方国无懈时
			return true, true
		end
	end
end

sgs.ai_use_value.FightTogether = 5.5
sgs.ai_use_priority.FightTogether = 8.7
sgs.ai_keep_value.FightTogether = 3.33

--AllianceFeast
function SmartAI:useCardAllianceFeast(card, use)--效果修改，已重写
	if not card:isAvailable(self.player) then return end
	local hegnullcards = self.player:getCards("HegNullification")
	local effect_kingdoms = {}

	for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not self.player:isFriendWith(target) and target:hasShownOneGeneral() and self:trickIsEffective(card, target, self.player)
			and not(target:getRole() ~= "careerist" and table.contains(effect_kingdoms, target:getKingdom())) then
			if target:getRole() == "careerist" then
				table.insert(effect_kingdoms, target:objectName())
			else
				table.insert(effect_kingdoms, target:getKingdom())
			end
		end
	end
	if #effect_kingdoms == 0 then return end

	local max_v = 0
	local winner
	for _, kingdom in ipairs(effect_kingdoms) do
		local value = 0
		if kingdom:startsWith("sgs") then
			if self.player:hasShownSkill("weimu") and card:isBlack() then--灭吴帷幕
			elseif self.player:isWounded() then
				value = value + 1.5
			else
				value = value + 0.5
				if self.player:hasShownSkills(sgs.cardneed_skill) then value = value + 0.5 end
			end
			local target = self.room:findPlayerbyobjectName(kingdom)
			if self:isFriend(target) then
				value = value + 0.5
				if target:hasShownSkills(sgs.cardneed_skill) then value = value + 0.5 end
				if target:isChained() then value = value + 0.5 end
			elseif self:isEnemy(target) then
				value = value - 0.5
				if target:hasShownSkills(sgs.cardneed_skill) then value = value - 0.5 end
				if target:isChained() then value = value - 0.5 end
			end
		else
			local their_num = 0
			local self_value = 0
			local enemy_value = 0
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasShownOneGeneral() and p:getRole() ~= "careerist" and p:getKingdom() == kingdom then
					their_num = their_num + 1
					if self:isFriend(p) and self:trickIsEffective(card, p, self.player) then
						self_value = self_value + 0.5
						if p:hasShownSkills(sgs.cardneed_skill) then self_value = self_value + 0.5 end
						if p:isChained() then self_value = self_value + 0.5 end
					elseif self:isEnemy(p) and self:trickIsEffective(card, p, self.player) then
						enemy_value = enemy_value + 0.5
						if p:hasShownSkills(sgs.cardneed_skill) then enemy_value = enemy_value + 0.5 end
						if p:isChained() then enemy_value = enemy_value + 0.5 end
					end
				end
			end
			if their_num > self.player:getLostHp() then
				self_value = self_value + self.player:getLostHp() * 1.5
				self_value = self_value + (their_num - self.player:getLostHp())*(self.player:hasShownSkills(sgs.cardneed_skill) and 1 or 0.5)
			else
				self_value = self_value + their_num * 1.5
			end
			if self_value >= 3 and enemy_value > 2.5 and hegnullcards then
				enemy_value = enemy_value / 2
			end
			value = self_value - enemy_value
		end
		if value > max_v then
			winner = kingdom
			max_v = value
		end
	end

	if winner then
		local target
		if winner:startsWith("sgs") then
			target = self.room:findPlayerbyobjectName(winner)
		else
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasShownOneGeneral() and p:getRole() ~= "careerist" and p:getKingdom() == winner and self:trickIsEffective(card, p, self.player) then
					target = p
					break
				end
			end
		end
		if target then
			use.card = card
			if use.to then use.to:append(target) end
			return
		end
	end
end

sgs.ai_skill_choice["alliancefeast_draw"] = function(self, choices)
	choices = choices:split("+")
	--@alliancefeast-choose
	if self:needToLoseHp(self.player, nil, nil, nil, true) then return choices[1] end
	return choices[#choices]
end

sgs.ai_use_value.AllianceFeast = 9.5
sgs.ai_use_priority.AllianceFeast = 8.8
sgs.ai_keep_value.AllianceFeast = 4.4

sgs.ai_nullification.AllianceFeast = function(self, card, from, to, positive, keep)
	if not self:isFriend(to) and not self:isEnemy(to) then return end
	local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. card:toString()):toList()
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
	end
	local targets_t = sgs.QList2Table(targets)
	for _, p in sgs.qlist(targets) do
		if targets:indexOf(p) < targets:indexOf(to) then table.removeOne(targets_t, p) end
	end
	table.removeOne(targets_t, from)

	local hegnull = self:getCard("HegNullification") or (self.room:getTag("NullifyingTimes"):toInt() > 0 and self.room:getTag("NullificatonType"):toBool())
	local null_num = self:getCardsNum("Nullification")

	local from_value = 0
	if to:objectName() == from:objectName() then
		if targets:length() -1 > from:getLostHp() then
			from_value = from_value + from:getLostHp() * 1.5
			from_value = from_value + (targets:length() -1 - from:getLostHp())*(from:hasShownSkills(sgs.cardneed_skill) and 1 or 0.5)
		else
			from_value = from_value + (targets:length() -1) * 1.5
		end
		if (self:isFriend(to) and positive) or (self:isEnemy(to) and not positive) then
			from_value = -from_value
		end
		if from_value < 0 then return end
	end

	local value = 0
	local target
	if hegnull then
		for _, p in ipairs(targets_t) do
			if self:trickIsEffective(card, p, from) then
				value = value + 0.5
				if p:hasShownSkills(sgs.cardneed_skill) then value = value + 0.5 end
				if p:isChained() then value = value + 0.5 end
			end
		end
		if value > 2 then
			target = targets_t[1]
		end
	end
	if target and self:isEnemy(target) then
		if to:objectName() == from:objectName() then
			if null_num > 1 and from_value >= 2.5 then
				return true, true
			else
				return
			end
		else
			if (self:isFriend(to) and positive) or (self:isEnemy(to) and not positive) then
				value = -value
			end
			if value > 2 + (keep and 1 or 0) then
				return true, false
			end
		end
	end
	if to:objectName() == from:objectName() and from_value >= (keep and 3.5 or 2.5) then
		return true, true
	end
end

--ThreatenEmperor
function SmartAI:useCardThreatenEmperor(card, use)
	if not card:isAvailable(self.player) then return end
	if self.player:getMark("ThreatenEmperorExtraTurn") > 0 then--配合当先
		return
	end
	local cardPlace = self.room:getCardPlace(card:getEffectiveId())--修改后无法使用装备，考虑手牌区
	if self.player:getCardCount(false) < 1 + (cardPlace == sgs.Player_PlaceHand and 1 or 0) then return end
	if not self:trickIsEffective(card, self.player, self.player) then return end
	if self.player:hasSkill("shensu") and sgs.ai_skill_use["@@shensu3"](self) ~= "." then return end
	if self.player:hasSkills("qiaobian|qiaobian_egf") and (self.player:getHandcardNum() - self.player:getMaxCards() > 1) then return end
	--手牌上限不足,且不能额外获得牌
	if not self.player:hasSkills("qiaobian|qiaobian_egf") and self.player:getMaxCards() <= 0 then
		if self.player:hasSkills("biyue|guanyue") then
		elseif self.player:hasSkill("shengxi") and not self.player:hasFlag("ShengxiDamageInPlayPhase") then
		elseif self.player:hasSkill("qiluan") and self.player:getMark("qiluan") > 0 then
		elseif self.player:hasSkill("lianpian") and self.player:getMark("lianpian") > 0 then
		elseif self.player:hasSkill("tongdu") and self.player:getCardCount(false) > 1 then
		else return end
	end
	use.card = card
end
sgs.ai_use_value.ThreatenEmperor = 6
sgs.ai_use_priority.ThreatenEmperor = 0
sgs.ai_keep_value.ThreatenEmperor = 3.2

sgs.ai_nullification.ThreatenEmperor = function(self, card, from, to, positive, keep)
	if positive then
		if keep and self:isEnemy(from) then
			for _, p in ipairs(self.friends) do
				if from:canSlash(p, nil, true) and self:isWeak(p) then
					keep = false
				end
			end
		end
		if not keep and self:isEnemy(from) and not from:isKongcheng() then return true, true end
	else
		if self.player:objectName() == from:objectName() then
			local null_card = self:getCard("Nullification")
			if null_card and from:isLastHandCard(null_card) then
				return false
			end
		end
		if not keep and self:isFriend(from) and not from:isKongcheng() then return true, true end
	end
end

sgs.ai_skill_cardask["@threaten_emperor"] = function(self)
	if self.player:isKongcheng() then return "." end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards,true)
	if self.player:getHandcardNum() > 1 then
		for _, card in ipairs(cards) do
			if not card:isKindOf("threaten_emperor") then--如果可以连着挟天子
				return card:getEffectiveId()
			end
		end
	end
	return cards[1]:getEffectiveId()
end

--ImperialOrder
function SmartAI:useCardImperialOrder(card, use)
	if not card:isAvailable(self.player) then return end
	--赦令策略
	if self.player:hasSkills("wuku|xiongyi|jianglve") or (self:isWeak() and self.player:hasSkill("huibian")) then
		--势力召唤或自保
		use.card = card
	elseif self.role == "careerist" or self.player:getActualGeneral1():getKingdom() == "careerist" then
		--野心家降嘲讽
		use.card = card
	else
		local gameProcess = sgs.gameProcess()
		local self_kingdom = self.player:getKingdom()
		--大国大优势不开
		if string.find(gameProcess, self_kingdom..">>>") then return end
		--他国大优势开团
		if string.find(gameProcess, ">>>") then 
			use.card = card
		else
			local zuoci = sgs.findPlayerByShownSkillName("yigui")
			--local xunkan = sgs.findPlayerByShownSkillName("anyong")
			local duyu = sgs.findPlayerByShownSkillName("wuku")
			--左慈杜预
			if zuoci and self.player:isFriendWith(zuoci) then return end
			if duyu and self:isEnemy(duyu) then return end
			--吴尽量不开
			if string.find(gameProcess, self_kingdom..">>") and self_kingdom == "wu" then return end
			use.card = card
		end
	end
end
sgs.ai_use_value.ImperialOrder = 0
sgs.ai_use_priority.ImperialOrder = 9.2
sgs.ai_keep_value.ImperialOrder = 0

sgs.ai_nullification.ImperialOrder = function(self, card, from, to, positive)
	return false
end

sgs.ai_skill_cardask["@imperial_order-equip"] = function(self)
	local gameProcess = sgs.gameProcess()
	local self_kingdom = self.player:getKingdom()
	local upperlimit = self.player:getLord() and 99 or math.floor(self.room:getPlayers():length() / 2)
	local selfIsCareerist = self.role == "careerist" or (sgs.shown_kingdom[self_kingdom] >= upperlimit and not self.player:hasShownOneGeneral()) 
		or (self.player:getActualGeneral1():getKingdom() == "careerist" and not (self.player:hasShownGeneral1() and self.role ~= "careerist"))
	--势力首亮
	if sgs.shown_kingdom[self_kingdom] <= 0 then return "." end
	--开团与反开团
	if string.find(gameProcess, ">>>") and not selfIsCareerist then return "." end
	
	local current = self.room:getCurrent()
	if self.player:willBeFriendWith(current) and not current:hasShownSkill("huoshui") then
		if (current:hasShownSkill("luanji") and (self.player:getHp() + self:getCardsNum("Jink") <= 2 + math.ceil((current:getHandcardNum()-3)/2)))
			or (current:hasShownSkill("hongfa") and current:getPile("heavenly_army"):isEmpty())
			or current:hasShownSkill("xiongyi") then
			return "."
		end
		
		if self.player:getHp() <= 1 and not self.player:hasSkill("buqu") then
			local prevent_dying = 0
			local possible_peach = 0
			local peach = sgs.cloneCard("peach")
			local analeptic = sgs.cloneCard("analeptic")
			
			if not self.player:isLocked(peach) then prevent_dying = prevent_dying + self:getCardsNum("Peach") end
			if not self.player:isLocked(analeptic) then prevent_dying = prevent_dying + self:getCardsNum("Analeptic") end
			
			for _, friend in ipairs(self.friends_noself) do
				if self.player:willBeFriendWith(friend) then
					possible_peach = possible_peach + getCardsNum("Peach", friend, self.player)
				end
			end
			
			if prevent_dying == 0 or possible_peach > 0 then
				return "."
			end
		end
	end
	
	if self:needToThrowArmor() then
		return self.player:getArmor():getEffectiveId()
	end
	if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1 then--君主
		if self.player:inHeadSkills("rende") or self.player:inHeadSkills("guidao")
			or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("jianxiong") then
				return "."
		end
	end
	local discard
	local kingdom = self:evaluateKingdom(self.player)
	if kingdom == "unknown" then discard = true
	else
		kingdom = kingdom:split("?")
		discard = #kingdom / #sgs.KingdomsTable >= 0.5
	end
	if ((self.player:hasSkills(sgs.cardneed_skill) or self:isWeak()) and (self:willShowForAttack() or self:willShowForDefence()))
		or (self.player:hasSkills(sgs.masochism_skill) and self:willShowForMasochism()) then return "." end
	if self.player:getPhase() == sgs.Player_NotActive and discard then
		local cards = sgs.QList2Table(self.player:getCards("he"))
			for _, card in ipairs(cards) do
				if not self:willShowForAttack() and ((card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")) then
					return card:getEffectiveId()
				elseif not self:willShowForDefence() and ((card:isKindOf("Vine") and self.player:getHp() > 1) or card:isKindOf("DefensiveHorse")) then
					return card:getEffectiveId()
				end
			end
	end
	return "."
end

sgs.ai_skill_choice.imperial_order = function(self, choices, data)
	local callback = sgs.ai_skill_cardask["@imperial_order-equip"]
	if type(callback) == "function" then
		local ret = callback(self)
		if ret ~= "." then return "dis_equip" end
	end
	choices = choices:split("+")
	
	local show_position = self:getGeneralShowOrHide(self.player,((self:needToLoseHp() or self.player:isRemoved()) and 1 or 3),true)
	if not show_position then return "losehp"
	elseif show_position:split("+")[1] == "head" and table.contains(choices,"show_head") then return "show_head"
	elseif show_position:split("+")[1] == "deputy" and table.contains(choices,"show_deputy") then return "show_deputy"
	elseif string.find(show_position, "head") and table.contains(choices,"show_head") then return "show_head"
	elseif string.find(show_position, "deputy") and table.contains(choices,"show_deputy") then return "show_deputy" end
	
	if sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1 and table.contains(choices,"show_deputy") then--君主
		if self.player:inHeadSkills("rende") or self.player:inHeadSkills("guidao")
			or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("jianxiong") then
				--Global_room:writeToConsole("敕令君主")
				return "show_deputy"
		end
	end
	if self.player:getActualGeneral1():getKingdom() == "careerist" and table.contains(choices,"show_deputy") then--野心家角色
		--Global_room:writeToConsole("敕令野心家")
		return "show_deputy"
	end

	if self.player:getKingdom() == "shu" and table.contains(choices,"show_head") and table.contains(choices,"show_deputy") then
		local wuhu_show_head, wuhu_show_deputy = false,false
		local xuanhuo_priority = {"paoxiao", "tieqi", "kuanggu", "liegong", "wusheng", "longdan"}
		for _, skill in ipairs(xuanhuo_priority) do--有顺序优先度
		  if self.player:hasSkill(skill) then
			if self.player:inHeadSkills(skill) then
			  wuhu_show_deputy = true
			  break
			else
			  wuhu_show_head = true
			  break
			end
		  end
		end
		if wuhu_show_deputy then
		  return "show_deputy"
		end
		if wuhu_show_head then
		  return "show_head"
		end
		return "show_head"
	end

	if self.player:getPhase() ~= sgs.Player_NotActive then return math.random(2) > 1 and "show_head" or "show_deputy" end
	if self:needToLoseHp() then return "losehp" end
	if not self.player:isWounded() and self.player:getCardCount(true) > 6 then return "losehp" end
	return math.random(2) > 1 and "show_head" or "show_deputy"
end


--JadeSeal
sgs.ai_skill_use["@@JadeSeal!"] = function(self, prompt, method)
	local card = sgs.cloneCard("known_both")
	local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
	self:useCardKnownBoth(card, dummyuse)
	local tos = {}
	if dummyuse.card and not dummyuse.to:isEmpty() then
		for _, to in sgs.qlist(dummyuse.to) do
			table.insert(tos, to:objectName())
		end
		return "known_both:JadeSeal[no_suit:0]=.&->" .. table.concat(tos, "+")
	end
	self:sort(self.enemies, "handcard", true)
	local targets = sgs.PlayerList()
	for _, enemy in ipairs(self.enemies) do
		if self:getKnownNum(enemy, self.player) ~= enemy:getHandcardNum() and card:targetFilter(targets, enemy, self.player) and not targets:contains(enemy) then
			targets:append(enemy)
			table.insert(tos, enemy:objectName())
			self.knownboth_choice[enemy:objectName()] = "handcards"
		end
	end
	self:sort(self.friends_noself, "handcard", true)
	for _, friend in ipairs(self.friends_noself) do
		if self:getKnownNum(friend, self.player) ~= friend:getHandcardNum() and card:targetFilter(targets, friend, self.player) and not targets:contains(friend) then
			targets:append(friend)
			table.insert(tos, friend:objectName())
			self.knownboth_choice[friend:objectName()] = "handcards"
		end
	end

	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(players, "handcard", true)
	for _, player in ipairs(players) do
		if card:targetFilter(targets, player, self.player) and not targets:contains(player) then
			targets:append(player)
			table.insert(tos, player:objectName())
			self.knownboth_choice[player:objectName()] = "handcards"
		end
	end
	assert(#tos > 0)
	return "known_both:JadeSeal[no_suit:0]=.&->" .. table.concat(tos, "+")
end

sgs.ai_use_priority.JadeSeal = 5.6
sgs.ai_keep_value.JadeSeal = 4.2

--Halberd
sgs.ai_skill_use["@@Halberd"] = function(self, prompt)
	--过滤出所有能选择的角色
	local targets = {}
	local selected_targets = sgs.PlayerList()
	local halberdCard = sgs.Card_Parse("@HalberdCard=.")
	if not halberdCard then return "." end
	--取当前使用的杀
	local slash = sgs.Card_Parse(self.player:property("halberd_slash"):toString())
	--原始目标
	local halberd_slash_current_targets_names = self.player:property("halberd_slash_current_targets"):toString():split("+")
	local halberd_slash_current_targets = sgs.SPlayerList()
	local halberd_missed_target = false
	local yuji = sgs.findPlayerByShownSkillName("qianhuan")
	local enemy_qianhuan = false
	for _, name in ipairs(halberd_slash_current_targets_names) do
		local current_target = self.room:findPlayerbyobjectName(name)
		halberd_slash_current_targets:append(current_target)
		if not halberd_missed_target and not self:canHit(current_target, self.player) then
			halberd_missed_target = current_target
		end
		if yuji and yuji:isAlive() and yuji:getPile("sorcery"):length() > 0 and current_target:isFriendWith(yuji) and not self:isFriend(yuji) then
			enemy_qianhuan = true
		end
	end
	local halberd_first_target = halberd_slash_current_targets:first()
	local halberd_last_target = halberd_slash_current_targets:last()
	--halberd_prime_target
	local has_other_target = (halberd_slash_current_targets:length() > 1)--千幻
	local slash_halberd_skill = false--适合方天的技能,无视是否命中
	if self.player:hasShownSkills(sgs.force_slash_skill) or (self.player:hasShownSkills("paoxiao|paoxiao_xh|baolie") and self.player:getPhase() == sgs.Player_Play) then
		slash_halberd_skill = true
	end
	local jink_targets = sgs.SPlayerList()
	local first_target_name = sgs.Sanguosha:translate(halberd_first_target:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(halberd_first_target:getActualGeneral2Name()).."("..sgs.Sanguosha:translate(string.format("SEAT(%s)",halberd_first_target:getSeat()))..")"
	while true do
		local available_targets = sgs.SPlayerList()
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:slashProhibit(slash, p) then continue end
			if not self.player:canSlash(p, slash, true) then continue end
			if self:isEnemy(p) and not self:slashIsEffective(slash, p) then continue end--不出无效杀,除非火杀太平队友雷击
			local same_kingdoms = {}
			for _, enemy in ipairs(self.enemies) do
				if p:isFriendWith(enemy) then
					table.insert(same_kingdoms, enemy)
				end
			end
			if self:isEnemy(p) and not sgs.isGoodTarget(p, same_kingdoms, self) then continue end--slash_extra_targets
			if self:isFriend(p) and (self:hasHeavySlashDamage(self.player, slash, p) or not (self:needToLoseHp(p, self.player, true, true)
				or self:needDamagedEffects(p, self.player, true) or self:needLeiji(p, self.player))) then continue end--slash_extra_targets
			if halberdCard:targetFilter(selected_targets, p, self.player) and not jink_targets:contains(p) then
				available_targets:append(p)
			end
		end
		if available_targets:isEmpty() then break end
		local target = available_targets:first()
		--如果存在需要命中的原始敌方目标,方天杀不选择在该目标之前结算的无法命中的敌方目标
		local new_target_name = sgs.Sanguosha:translate(target:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(target:getActualGeneral2Name()).."("..sgs.Sanguosha:translate(string.format("SEAT(%s)",target:getSeat()))..")"
		if self:isEnemy(halberd_first_target) and self:playerGetRound(halberd_first_target) > self:playerGetRound(target) 
			and self:isEnemy(target) and not self:canHit(target, self.player) and not slash_halberd_skill then
			Global_room:writeToConsole("方天为命中:"..first_target_name..":移除目标:"..new_target_name)
			jink_targets:append(target)
			continue
		end
		--如果需要消耗一个敌方目标的闪,方天杀不选择在该目标之前结算的无法命中的敌方目标
		if halberd_missed_target and self:isEnemy(halberd_missed_target)and self:playerGetRound(halberd_missed_target) > self:playerGetRound(target)
			and self:isEnemy(target) and not self:canHit(target, self.player) and not slash_halberd_skill then
			local missed_target_name = sgs.Sanguosha:translate(halberd_missed_target:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(halberd_missed_target:getActualGeneral2Name()).."("..sgs.Sanguosha:translate(string.format("SEAT(%s)",halberd_missed_target:getSeat()))..")"
			Global_room:writeToConsole("方天耗闪目标:"..missed_target_name..":移除目标:"..new_target_name)
			jink_targets:append(target)
			continue
		end
		if not halberd_missed_target and not self:canHit(target, self.player) then halberd_missed_target = target end
		table.insert(targets, target:objectName())
		selected_targets:append(target)
	end
	--考虑能命中千幻时方天能闪的队友(暂只考虑后置位)
	if not has_other_target and #targets == 0 and enemy_qianhuan then
		local available_targets = sgs.SPlayerList()
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if halberdCard:targetFilter(selected_targets, p, self.player) and self:playerGetRound(p) > self:playerGetRound(halberd_first_target) then
				available_targets:append(p)
			end
		end
		if available_targets:isEmpty() then return "." end
		local add_targets = sgs.QList2Table(available_targets)
		self:sort(add_targets, "defenseSlash")
		add_targets = sgs.reverse(add_targets)
		for _, p in ipairs(add_targets) do
			if self:isFriend(p) and not self:canHit(p, self.player) then
				table.insert(targets, p:objectName())
				local missed_name = sgs.Sanguosha:translate(p:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(p:getActualGeneral2Name()).."("..sgs.Sanguosha:translate(string.format("SEAT(%s)",p:getSeat()))..")"
				Global_room:writeToConsole("方天千幻目标:"..first_target_name..":增加目标:"..missed_name)
				break
			end
		end
	end
	if #targets > 0 then
		return "@HalberdCard=.&->" .. table.concat(targets, "+")
	end
	--[[
	--旧方天
	if self.player:hasFlag("HalberdUse") and card and card:isKindOf("Slash") then
		local targets = {}
		local best_targets = {}
		if not use.to or use.to:isEmpty() then
			local assignee_target
			if self.player:hasFlag("slashTargetFix") then
				local assignee_targets = {}
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if p:hasFlag("SlashAssignee") then
						if not self.player:canSlash(p, card) or not canAppendTarget(p) then continue end
						if self.player:hasFlag("slashTargetFixToOne") then
							assignee_target = p
							break
						else
							table.insert(assignee_targets, p)
							assignee_target = p
						end
					end
				end
				if not assignee_target then return end
				if not self.player:hasFlag("slashTargetFixToOne") then
					if #assignee_targets > 1 then
						local best_target
						self:sort(assignee_targets, "defenseSlash")
						for _, friend in ipairs(assignee_targets) do
							if self:isFriend(friend) and not self:hasHeavySlashDamage(self.player, card, friend)
								and not self:slashProhibit(card, friend) and self:slashIsEffective(card, friend)
								and self:isPriorFriendOfSlash(friend, card, self.player)then
								best_target = friend
								break
							end
						end
						if not best_target then
							for _, enemy in ipairs(assignee_targets) do
								if self:isEnemy(enemy) and not self:slashProhibit(card, enemy) and self:slashIsEffective(card, enemy)
									and sgs.isGoodTarget(enemy, assignee_targets, self) then
									best_target = enemy
									break
								end
							end
						end
						if not best_target then
							for _, friend in ipairs(assignee_targets) do
								if self:isFriend(friend) and not self:hasHeavySlashDamage(self.player, card, friend)
									and not self:slashProhibit(card, friend) and self:slashIsEffective(card, friend)
									and (self:getDamagedEffects(friend, self.player, true) or self:needToLoseHp(friend, self.player, true))then
									best_target = friend
									break
								end
							end
						end
						if best_target then 
							assignee_target = best_target
						end
					end
				end
			end
			if assignee_target and self:isFriend(assignee_target) then
				self:sort(self.enemies, "round")
				--被借刀时,从当前回合角色开始结算
				--local need_hit
				--所以被敌人借刀时考虑优先杀该敌人,而不是考虑方天命中
				--self:canHit(enemy, self.player)
				--getCardsNum("Jink", enemy, self.player) > 0
			else
				self:sort(self.enemies, "defenseSlash")
			end
			local primary_target = (assignee_target and self:isEnemy(assignee_target))
			for _, enemy in ipairs(self.enemies) do
				if primary_target and self:playerGetRound(assignee_target) > self:playerGetRound(enemy) 
					and getCardsNum("Jink", enemy, self.player) > 0 then continue end
				if enemy:hasShownOneGeneral() or enemy:getRole() ~= "careerist" then continue end
				local eff = self:slashIsEffective(card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
				if self.player:canSlash(enemy, card) and not self:slashProhibit(nil, enemy) and eff and canAppendTarget(enemy) then
					table.insert(targets, enemy)
					if enemy:getHp() == 1 and self:canHit(enemy, self.player) then
						table.insert(best_targets, enemy)
					end
				end
			end
			local kingdoms = sgs.KingdomsTable
			for _, kingdom in ipairs(kingdoms) do
				for _, enemy in ipairs(self.enemies) do
					if primary_target and self:playerGetRound(assignee_target) > self:playerGetRound(enemy) 
						and getCardsNum("Jink", enemy, self.player) > 0 then continue end
					if not enemy:hasShownOneGeneral() or enemy:getRole() == "careerist" and enemy:getKingdom() ~= kingdom then continue end
					local eff = self:slashIsEffective(card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
					if self.player:canSlash(enemy, card) and not self:slashProhibit(nil, enemy) and eff and canAppendTarget(enemy) then
						table.insert(targets, enemy)
						if enemy:getHp() == 1 and self:canHit(enemy, self.player) then
							table.insert(best_targets, enemy)
						end
						break
					end
				end
			end
			if #targets == 0 then return end
			self:sort(targets, "round")
			self:sort(best_targets, "round")
			
			if assignee_target and self:isFriend(assignee_target) then
				if #best_targets > 0 then
					if not table.contains(best_targets, assignee_target) and canAppendTarget(assignee_target) then
						use.to:append(assignee_target)
					end
					for _, target in ipairs(best_targets) do
						if canAppendTarget(target) then
							use.to:append(target)
						end
					end
				elseif #targets > 0 and self:playerGetRound(assignee_target) > self:playerGetRound(targets[1]) then
					if not table.contains(targets, assignee_target) and canAppendTarget(assignee_target) then
						use.to:append(assignee_target)
					end
					for _, target in ipairs(targets) do
						if canAppendTarget(target) then
							use.to:append(target)
						end
					end
				end
			elseif assignee_target and not self:isFriend(assignee_target) then
				global_room:writeToConsole("Halberd_Enemie_not_Slash??")
			end
		else
			local halberd_missed_target = false
			local use_to = sgs.QList2Table(use.to)
			self:sort(use_to, "round")
			for _, p in ipairs(use_to) do
				if getCardsNum("Jink", p, self.player) > 0 then
					halberd_missed_target = p
					break
				end
			end
			self:sort(self.enemies, "defenseSlash")
			for _, enemy in ipairs(self.enemies) do
				if table.contains(use_to, enemy) then continue end
				if halberd_missed_target and self:isEnemy(halberd_missed_target)and self:playerGetRound(halberd_missed_target) > self:playerGetRound(enemy)
					and getCardsNum("Jink", enemy, self.player) > 0 then continue end
				if enemy:hasShownOneGeneral() or enemy:getRole() ~= "careerist" then continue end
				local eff = self:slashIsEffective(card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
				if self.player:canSlash(enemy, card) and not self:slashProhibit(nil, enemy) and eff and canAppendTarget(enemy) then
					table.insert(targets, enemy)
					if enemy:getHp() == 1 and self:canHit(enemy, self.player) then
						table.insert(best_targets, enemy)
					end
				end
			end
			local kingdoms = sgs.KingdomsTable
			for _, kingdom in ipairs(kingdoms) do
				for _, enemy in ipairs(self.enemies) do
					if table.contains(use_to, enemy) then continue end
					if halberd_missed_target and self:isEnemy(halberd_missed_target)and self:playerGetRound(halberd_missed_target) > self:playerGetRound(enemy)
						and getCardsNum("Jink", enemy, self.player) > 0 then continue end
					if not enemy:hasShownOneGeneral() or enemy:getRole() == "careerist" and enemy:getKingdom() ~= kingdom then continue end
					local eff = self:slashIsEffective(card, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
					if self.player:canSlash(enemy, card) and not self:slashProhibit(nil, enemy) and eff and canAppendTarget(enemy) then
						table.insert(targets, enemy)
						if enemy:getHp() == 1 and self:canHit(enemy, self.player) then
							table.insert(best_targets, enemy)
						end
						break
					end
				end
			end
			if #targets == 0 then return end
			self:sort(targets, "round")
			self:sort(best_targets, "round")
			if #best_targets > 0 then
				for _, target in ipairs(best_targets) do
					if canAppendTarget(target) then
						use.to:append(target)
					end
				end
			elseif #targets > 0 then
				for _, target in ipairs(targets) do
					if canAppendTarget(target) then
						use.to:append(target)
					end
				end
			end
		end
	end
	--]]
end

--[[
--(2.1.0版AI)getSkillViewCard返回的skill_card_str导致slashes全被转化为了HalberdCard(@HalberdCard[no_suit:-]=.&)
--]]
function sgs.ai_slash_weaponfilter.Halberd(self, to, player)
	return player:distanceTo(to) <= math.max(sgs.weapon_range.Halberd, player:getAttackRange())
		--and (sgs.card_lack[to:objectName()]["Jink"] == 1 or getCardsNum("Jink", to, self.player) < 1)
end

function sgs.ai_weapon_value.Halberd(self, enemy, player)
	if not enemy then return 0 end
	local halberd_targets = 0
	local current_range = (player:getWeapon() and sgs.weapon_range[player:getWeapon():getClassName()]) or 1
	local range_fix = current_range - 4
	for _, halberd_enemy in ipairs(self.enemies) do
		if halberd_enemy:hasShownOneGeneral() or halberd_enemy:getRole() ~= "careerist" then continue end
		if not player:canSlash(halberd_enemy, nil, true, range_fix) then continue end
		if self:playerGetRound(halberd_enemy) > self:playerGetRound(enemy) then
			halberd_targets = halberd_targets + 1
		elseif self:playerGetRound(halberd_enemy) < self:playerGetRound(enemy) and self:canHit(halberd_enemy, player) then
			halberd_targets = halberd_targets + 1
		end
	end
	local kingdoms = sgs.KingdomsTable
	for _, kingdom in ipairs(kingdoms) do
		for _, halberd_enemy in ipairs(self.enemies) do
			if not halberd_enemy:hasShownOneGeneral() or halberd_enemy:getRole() == "careerist" and halberd_enemy:getKingdom() ~= kingdom then continue end
			if not player:canSlash(halberd_enemy, nil, true, range_fix) then continue end
			if self:playerGetRound(halberd_enemy) > self:playerGetRound(enemy) then
				halberd_targets = halberd_targets + 1
				break
			elseif self:playerGetRound(halberd_enemy) < self:playerGetRound(enemy) and self:canHit(halberd_enemy, player) then
				halberd_targets = halberd_targets + 1
				break
			end
		end
	end
	if (self:canHit(enemy, player) and not player:hasWeapon("Axe")) or player:hasShownSkills(sgs.force_slash_skill .. "|" .."paoxiao|paoxiao_xh|baolie") then
		return math.max(4, (halberd_targets-1)*2)
	end
	if halberd_targets > 0 then return math.max(1.1, halberd_targets) end
	return 0
end

--WoodenOx
local wooden_ox_skill = {}
wooden_ox_skill.name = "WoodenOx"
table.insert(sgs.ai_skills, wooden_ox_skill)
wooden_ox_skill.getTurnUseCard = function(self)
	self.wooden_ox_assist = nil
	if self.player:getPile("wooden_ox"):length() >=5 then return end
	if self.player:hasUsed("WoodenOxCard") or self.player:isKongcheng() or not self.player:hasTreasure("WoodenOx") then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local card, friend = self:getCardNeedPlayer(cards, self.friends_noself, "WoodenOx")
	if card and friend and friend:objectName() ~= self.player:objectName()
	and (self:getOverflow() > 0 or self:isWeak(friend) or (self.player:hasSkills(sgs.lose_equip_skill) and self:isFriendWith(friend))) then
		self.wooden_ox_assist = friend
		return sgs.Card_Parse("@WoodenOxCard=" .. card:getEffectiveId())
	end
	if self:getOverflow() > 0 or (self:needKongcheng() and #cards == 1) then
		self.wooden_ox_assist = nil
		return sgs.Card_Parse("@WoodenOxCard=" .. cards[1]:getEffectiveId())
	end
end

sgs.ai_skill_use_func.WoodenOxCard = function(card, use, self)
	sgs.ai_use_priority.WoodenOxCard = 0
	if self.player:hasSkills(sgs.lose_equip_skill) then
		sgs.ai_use_priority.WoodenOxCard = 10
	end
	use.card = card
end

sgs.ai_skill_playerchosen.WoodenOx = function(self, targets)
	return self.wooden_ox_assist
end

sgs.ai_playerchosen_intention.WoodenOx = -10
sgs.ai_use_priority.WoodenOx = 5.8

--Blade
function sgs.ai_slash_weaponfilter.Blade(self, to, player)
	return player:distanceTo(to) <= math.max(sgs.weapon_range.Blade, player:getAttackRange()) and not to:hasShownAllGenerals()
		and (sgs.card_lack[to:objectName()]["Jink"] == 1 or getCardsNum("Jink", to, self.player) < 1)
end

function sgs.ai_weapon_value.Blade(self, enemy, player)
	if not enemy then
		return 0
	else
		local v = 0
		if not enemy:hasShownGeneral1() then v = v + 1 end
		if not enemy:hasShownGeneral2() then v = v + 1 end
		return v
	end
end
