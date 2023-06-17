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
--君临天下·EX

--孟达
sgs.ai_skill_invoke.qiuan = function(self, data)
	local damage = data:toDamage()
	if damage.card:isKindOf("AOE") then--优先于奸雄
		if self.get_AOE_subcard then
			self.get_AOE_subcard = nil
			return not self.player:hasSkill("jianxiong")
		end
		if damage.card:subcardsLength() == 1 then
			local card = sgs.Sanguosha:getEngineCard(damage.card:getEffectiveId())
			if card:isKindOf("AOE") then
				local dummy_use = {isDummy = true}
				if not card:targetFixed() then dummy_use.to = sgs.SPlayerList() end
				self:useCardByClassName(card, dummy_use)
				if dummy_use.card then
					return true
				end
			end
		else
			return true
		end
	end
	if not self:willShowForDefence() then
		return false
	end
	if self.player:hasSkills(sgs.masochism_skill) and self.player:getHp() > 1 and damage.damage < 2 then--详细判断，如节命、望归
		return false
	end
	if self.player:hasSkill("wangxi") and damage.from and self:isFriend(damage.from) and damage.damage < 2 then
		return false
	end
	return true
end

sgs.ai_skill_invoke.liangfan = true

sgs.ai_skill_choice.liangfan = function(self, choices, data)
  local damage = data:toDamage()
  if self.player:isFriendWith(damage.to) and damage.to:getHandcardNum() < 3 then
    return "no"
  end
	return "yes"
end

--唐咨
sgs.ai_skill_invoke.xingzhao = function(self, data)
	if not self:willShowForAttack() then
    return false
  end
	return true
end

sgs.ai_skill_invoke.xunxun_tangzi = true

sgs.ai_skill_movecards.xunxun_tangzi = function(self, upcards, downcards, min_num, max_num)
	local upcards_copy = table.copyFrom(upcards)
	local down = {}
	local id1 = self:askForAG(upcards_copy,false,"xunxun_tangzi")
	down[1] = id1
	table.removeOne(upcards_copy,id1)
	local id2 = self:askForAG(upcards_copy,false,"xunxun_tangzi")
	down[2] = id2
	table.removeOne(upcards_copy,id2)
	return upcards_copy,down
end

--张鲁
sgs.ai_skill_invoke.bushi = function(self, data)
	if self.player:getPhase() == sgs.Player_Start then return false end
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return false
	end
	return true
end
sgs.ai_skill_exchange.bushi = function(self,pattern,max_num,min_num,expand_pile)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local current = self.room:getCurrent()
	if self:isFriend(current) then
		self:sortByUseValue(cards, true)
		local card, friend = self:getCardNeedPlayer(cards, {current})
		if card and friend then return card:getEffectiveId() end
		return cards[1]:getEffectiveId()
	elseif not self:isEnemy(current) then
		self:sortByKeepValue(cards)
		return cards[1]:getEffectiveId()
	end
	return {}
end

sgs.ai_skill_invoke.midao = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return false
	end
	if not self.player:hasShownOneGeneral() and self.player:isNude() then return false end
	return true
end

sgs.ai_skill_exchange._midao = function(self,pattern,max_num,min_num,expand_pile)
	local discards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local need_spade,need_club,need_heart = false,false,false
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") then
				need_spade = true
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				need_club = true
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				need_heart = true
			end
		end
	end
	for _, card in ipairs(cards) do
		if need_spade and (card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9) then
			if #discards < 2 then
				table.insert(discards, card:getEffectiveId())
			end
			need_spade = false
		elseif need_club and card:getSuit() == sgs.Card_Club then
			if #discards < 2 then
				table.insert(discards, card:getEffectiveId())
			end
			need_club = false
		elseif need_heart and card:getSuit() == sgs.Card_Heart then
			if #discards < 2 then
				table.insert(discards, card:getEffectiveId())
			end
			need_heart = false
		end
	end
	if #discards < 2 then
		local card_ids = self:askForDiscard("dummy_reason", 2-#discards, 2-#discards, false, true)
		for _, card_id in ipairs(card_ids) do
			table.insert(discards, card_id)
		end
	end
	return discards
end

sgs.ai_skill_cardask["@midao-card"] = function(self, data)
	--@midao-card:sgs7:midao:indulgence:99
	local judge = data:toJudge()
	local who = judge.who
	
	local rices = self.player:getPile("rice")
	if rices:isEmpty() then return "." end
	
	local cards = {}
	for _,id in sgs.qlist(rices)do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
	end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:getUseValue(judge.card) >= 6 or self:getKeepValue(judge.card) >= 4.1 then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) >= 6 or self:getKeepValue(judge.card) >= 4.1 then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end
	return "."
end

--[[
sgs.ai_skill_invoke.bushi = function(self, data)
	if not self:willShowForMasochism() then
    return false
  end
  local damage = data:toDamage()
	return damage.to:objectName() == self.player:objectName()
end

sgs.ai_skill_playerchosen.bushi = function(self, targets)
  targets = sgs.QList2Table(targets)
  self:sort(targets, "handcard")
	return targets[1]
end

sgs.ai_skill_invoke.midao = function(self, data)
	if self:willShowForAttack() then
		local use = data:toCardUse()
		--local use = self.player:getTag("MidaoUseData"):toCardUse()
		if use.card and use.card:isKindOf("BasicCard") and not use.card:isKindOf("Slash") then
			--Global_room:writeToConsole("米道无效卡:"..use.card:objectName())
			return false
		end
		return true
	end
	return false
end

sgs.ai_skill_suit.midao= function(self)
  local use = self.player:getTag("MidaoUseData"):toCardUse()
  local card = use.card
  local targets = sgs.QList2Table(use.to)
  local suit = math.random(0, 3)
  if card:isKindOf("Slash") then--杀激昂和仁王盾
    for _,p in ipairs(targets) do
      if p:hasShownSkills("jiang") then
        suit = math.random(0, 1)
      end
    end
    for _,p in ipairs(targets) do
      if p:hasArmorEffect("RenwangShield") then
        suit = math.random(2, 3)
      end
    end
  end
  if card:isKindOf("TrickCard") then--锦囊帷幕
    for _,p in ipairs(targets) do
      if p:hasShownSkills("weimu") and self:isFriend(p) then
        suit = math.random(0, 1)
      end
      if p:hasShownSkills("weimu") and not self:isFriend(p) then
        suit = math.random(2, 3)
      end
    end
  end
  if (card:isKindOf("Slash") or card:isNDTrick()) then--息兵
    for _,p in ipairs(targets) do
      if p:hasShownSkills("xibing") and (self:isFriend(p) or use.to:length() > 1) then
        suit = math.random(0, 1)
      end
      if p:hasShownSkills("xibing") and not self:isFriend(p) and use.to:length() == 1 then
        suit = math.random(2, 3)
      end
    end
  end
  if card:isKindOf("BasicCard") or card:isNDTrick() then--贞特
    for _,p in ipairs(targets) do
      if p:hasShownSkills("zhente") and not p:setFlags("ZhenteUsed") and self:isFriend(p) then
        suit = math.random(0, 1)
      end
      if p:hasShownSkills("zhente") and not p:setFlags("ZhenteUsed") and not self:isFriend(p) then
        suit = math.random(2, 3)
      end
    end
  end
  for _,p in ipairs(targets) do--玉碎
    if p:hasShownSkills("yusui") and not self:isFriend(p) then
      suit = math.random(2, 3)
    end
  end

	return suit
end

sgs.ai_skill_choice.midao = function(self, choices, data)
  local use = self.player:getTag("MidaoUseData"):toCardUse()
  local card = use.card
  local from = use.from
  local targets = sgs.QList2Table(use.to)
  local fire_value, thunder_value, normal_value = 0,0,0
  for _,p in ipairs(targets) do
    if self:damageIsEffective(p, sgs.DamageStruct_Normal, from) then
      normal_value = normal_value + (self:isFriend(p) and -1 or 1)-- exp and x or y 和 exp ? x : y 等价
    end
    if self:damageIsEffective(p, sgs.DamageStruct_Fire, from) then
      fire_value = fire_value + (self:isFriend(p) and -1 or 1)
    end
    if self:damageIsEffective(p, sgs.DamageStruct_Thunder, from) then
      thunder_value = thunder_value + (self:isFriend(p) and -1 or 1)
    end
    if p:hasArmorEffect("Vine") then
      fire_value = fire_value + (self:isFriend(p) and -2 or 2)
    end
    if p:hasArmorEffect("IronArmor") and card:isKindOf("Slash") then
      fire_value = fire_value + (self:isFriend(p) and 2 or -2)
    end
    if p:isChained() then
      fire_value = fire_value + (self:isFriend(p) and -0.5 or 0.5)--考虑全场的连环角色！
      thunder_value = thunder_value + (self:isFriend(p) and -0.5 or 0.5)
    end
  end
  Global_room:writeToConsole("米道火:"..fire_value.." 雷:"..thunder_value.." 普通:"..normal_value)
  if from:hasShownSkill("xinghuo") then fire_value = 2*fire_value end--兴火
  if thunder_value >= fire_value and thunder_value >= normal_value then--优先雷防明光铠，是否应该把普放第一？
    return "thunder"
  end
  if normal_value >= fire_value and normal_value >= thunder_value then
    return "normal"
  end
  if fire_value >= normal_value and fire_value >= thunder_value then
    return "fire"
  end
  return "normal"
end

sgs.ai_skill_exchange["midao"] = function(self,pattern,max_num,min_num,expand_pile)
  if self:getOverflow() < 2 or self.player:isKongcheng() then
    return {}
  end
  local use = self.player:getTag("MidaoUseData"):toCardUse()
  local card = use.card
  local targets = sgs.QList2Table(use.to)--可以细化对目标效果不好时改属性？
  if card:isKindOf("Analeptic") and self:getCardsNum("Slash") > 0 and self:slashIsAvailable() then--酒有杀不给
    return {}
  end
  local zhanglu = sgs.findPlayerByShownSkillName("midao")
  if self:isFriend(zhanglu) and self:isWeak(zhanglu) then
    if self.player:getHp() > 1 and self:getCardsNum("Analeptic") > 0 then
      return self:getCard("Analeptic"):getEffectiveId()
    end
    if not self:isWeak() and self:getCardsNum("Peach") > 1 then
      return self:getCard("Peach"):getEffectiveId()
    end
    if self:getCardsNum("Jink") > 1 then
      return self:getCard("Jink"):getEffectiveId()
    end
  end
  local cards = self.player:getCards("h")-- 获得所有手牌
  cards=sgs.QList2Table(cards) -- 将列表转换为表
  self:sortByUseValue(cards,true)
  return cards[1]:getEffectiveId()
end
--]]
--糜芳＆傅士仁
sgs.ai_skill_invoke.fengshix = function(self, data)
	if not self:willShowForAttack() then
		return false
	end
	local target = data:toPlayer()
	if not target or self:isFriend(target) then
		return false
	end
	local use = self.player:getTag("FengshixUsedata"):toCardUse()
	local card = use.card--更多的非伤害锦囊的情况？现在空城也可触发无需担心
	self.fengshix_discard = nil
	if (card:isKindOf("FireAttack") or card:isKindOf("Dismantlement") or card:isKindOf("Snatch")) and target:getCardCount(true) == 1 then
		return false
	end
	if card:isKindOf("Drowning") and target:getEquips():length() == 1 then
		self.fengshix_discard = target:getEquips():first():getEffectiveId()
		return true
	end
	if self.player:getHandcardNum() > 3 or self:isWeak(target) then
		return true
	end
	return false
end

sgs.ai_skill_choice.fengshix = function(self, choices, data)
  self.fengshix_discard = nil
  local use = data:toCardUse()
  if use.card:isKindOf("FireAttack") and use.to:length() == 1 and use.to:first():getCardCount(true) == 1 then
    return "no"
  end
  if use.to:length() == 1 and self:isEnemy(use.to:first()) and (self.player:getHandcardNum() > 3 or self:isWeak(use.to:first())) then
    return "yes"
  end
	return "no"
end

sgs.ai_skill_cardchosen.fengshix = function(self, who, flags, method, disable_list)
  if who:objectName() == self.player:objectName() and self.fengshix_discard then--自己被水淹七军缺信息
    return self.fengshix_discard
  end
  return self:askForCardChosen(who, flags, "fengshix_dismantlement", method, disable_list)
end

sgs.ai_cardneed.fengshix = function(to, card, self)
	return to:getHandcardNum() < 3
end

--刘琦
sgs.ai_skill_playerchosen.wenji = function(self, targets)
  local target
  targets = sgs.QList2Table(targets)
  self:sort(targets, "handcard")
  for _, p in ipairs(targets) do
    if sgs.isAnjiang(p) then
      target = p
    end
  end
  local weak_enemy = false
  for _, enemy in ipairs(self.enemies) do
    if self:isWeak(enemy) then
      weak_enemy = true
      break
    end
  end
  if not target and weak_enemy then
    self:sort(targets, "handcard", true)
    for _, p in ipairs(targets) do
      if self.player:isFriendWith(p) and (getKnownCard(p, self.player, "Slash")--进攻
         + getKnownCard(p, self.player, "AOE") + getKnownCard(p, self.player, "Duel") > 0) then
        target = p
      end
    end
    if not target then
      for _, p in ipairs(targets) do
        if self.player:isFriendWith(p) and p:getHandcardNum() > 2 then
          target = p
        end
      end
    end
  end
  if not target then
	for _, p in ipairs(targets) do
		if self.player:isFriendWith(p) and (self:needToThrowArmor(p)
			or (p:getHandcardNum() == 1 and self:needKongcheng())
			or (p:hasSkills(sgs.lose_equip_skill) and not p:getEquips():isEmpty())) then
			target = p
			break
		elseif self:isFriend(p) and self:needToThrowArmor(p) then--拿队友防具，屯江无法主动触发所以暂无配合
			target = p
		end
	end
  end
  local give_peach = false
  if not self.player:isNude() then
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards,true)
    if cards[1]:isKindOf("Peach") then
      give_peach = true
    end
  end
  self:sort(targets, "handcard")
  if not target and not give_peach then--敌人，不给桃
    for _, p in ipairs(targets) do
      if not self.player:isFriendWith(p) and not self:doNotDiscard(p, "he", true, 1, "wenji") then--不问计屯田
        target = p
      end
    end
  end
  if target then
    return target
  end
	return {}--没有合适目标不发动
end

sgs.ai_skill_exchange["wenji_give"] = function(self,pattern,max_num,min_num,expand_pile)
	local liuqi = sgs.findPlayerByShownSkillName("wenji")
	--不能使用self:getCard("Slash"),防止问计给弘法杀
	if self:isFriendWith(liuqi) then--队友：杀、duel、AOE
		if self:getCardsNum("AOE") > 0 then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if liuqi:isCardLimited(card, sgs.Card_MethodUse) then continue end
				if isCard("SavageAssault", card, liuqi) and self:getAoeValue(card) > 0 then
					return card:getEffectiveId()
				elseif isCard("ArcheryAttack", card, liuqi) and self:getAoeValue(card) > 0 then
					return card:getEffectiveId()
				end
			end
		end
		if self:getCardsNum("Slash") > 0 then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if liuqi:isCardLimited(card, sgs.Card_MethodUse) then continue end
				if isCard("Slash", card, liuqi) then
					return card:getEffectiveId()
				end
			end
		end
		if self:getCardsNum("Duel") > 0 then
			for _, card in sgs.qlist(self.player:getCards("he")) do
				if liuqi:isCardLimited(card, sgs.Card_MethodUse) then continue end
				if isCard("Duel", card, liuqi) then
					return card:getEffectiveId()
				end
			end
		end
	end
	if self:needToThrowArmor() then
		return self.player:getArmor():getEffectiveId()
	end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end

sgs.ai_skill_exchange["wenji_giveback"] = function(self,pattern,max_num,min_num,expand_pile)
	local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("WenjiTarget") then
			to = p
			break
		end
	end
	--QString pattern = QString("^%1").arg(card_id);
	--local id = tonumber(string.match(pattern, "(%d+)"))
	--Global_room:writeToConsole(pattern.."|"..id)
	--不能使用self:getCard("Slash"),防止问计给弘法杀
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	if self:isFriend(to) and self:isWeak(to) then
		if self.player:getHp() > 1 and self:getCardsNum("Analeptic") > 0 then
			for _, card in ipairs(cards) do
				if liuqi:isCardLimited(card, sgs.Card_MethodUse) then continue end
				if isCard("Analeptic", card, liuqi) then
					return card:getEffectiveId()
				end
			end
		end
		if not self:isWeak() and self:getCardsNum("Peach") > 1 then
			for _, card in ipairs(cards) do
				if liuqi:isCardLimited(card, sgs.Card_MethodUse) then continue end
				if isCard("Peach", card, liuqi) then
					return card:getEffectiveId()
				end
			end
		end
		if self:getCardsNum("Jink") > 1 then
			for _, card in ipairs(cards) do
				if liuqi:isCardLimited(card, sgs.Card_MethodUse) then continue end
				if isCard("Jink", card, liuqi) then
					return card:getEffectiveId()
				end
			end
		end
	end
	for _, c in ipairs(cards) do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) then--已有pattern匹配函数
			return c:getEffectiveId()
		end
	end
end

function SmartAI:hasWenjiBuff(card)
	if self.player:hasSkill("wenji") then
    local record_ids = self.player:property("wenji_record"):toString():split("+")
    for _, id in sgs.qlist(card:getSubcards()) do
      if table.contains(record_ids, tostring(id)) then
        return true
      end
    end
    if table.contains(record_ids, tostring(card:getEffectiveId())) then
      return true
    end
  end
	return false
end

sgs.ai_skill_invoke.tunjiang = true

--士燮
sgs.ai_skill_invoke.lixia = true

sgs.ai_skill_choice.lixia = function(self, choices, data)
  local shixie = sgs.findPlayerByShownSkillName("lixia")
  --[[if not shixie then
    return "no"
  end
  if self.player:objectName() ~= shixie:objectName() and self:isFriend(shixie) then
    if self:needToThrowArmor(shixie) or ((shixie:hasSkills(sgs.lose_equip_skill) and self:isWeak(shixie)--弃装备技能且不丢防具、宝物，马呢？
      and (shixie:getEquips():length() - (shixie:getArmor() and 1 or 0) - (shixie:getTreasure() and 1 or 0)) > 0)) then
      return "yes"
    end
  end]]
  if self:isEnemy(shixie) then
    local canslash_shixie = false
    for _, p in ipairs(self.friends) do
      if p:canSlash(shixie, nil, true) then
        canslash_shixie = true
        break
      end
    end
    if self.player:getHp() > 2 and (not canslash_shixie
      or (shixie:hasTreasure("WoodenOx") and shixie:getPile("wooden_ox"):length() > 1)) then
      return "discard"
    end
  end
	return "draw"
end

--[[
sgs.ai_skill_choice["lixia_effect"]= function(self, choices, data)
  choices = choices:split("+")
  local shixie = sgs.findPlayerByShownSkillName("lixia")
  local shixie_draw
  for _, choice in ipairs(choices) do
    if choice:match("draw") then
      shixie_draw = choice
      break
    end
  end
  if shixie and self:isFriend(shixie) then
    return shixie_draw
  end
  if self:needToLoseHp() then
    return "losehp"
  end
  if self:getOverflow() > 2 then--还可以优化条件？
    return "discard"
  end
	return shixie_draw
end
]]

--董昭
local quanjin_skill = {}
quanjin_skill.name = "quanjin"
table.insert(sgs.ai_skills, quanjin_skill)
quanjin_skill.getTurnUseCard = function(self, inclusive)
  if self.player:isKongcheng() then return end
  if not self.player:hasUsed("QuanjinCard") then
    local can_quanjin = false
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
      if p:getMark("Global_InjuredTimes_Phase") > 0 and p:objectName() ~= self.player:objectName() then
        can_quanjin = true
      end
    end
    if can_quanjin then
      return sgs.Card_Parse("@QuanjinCard=.&quanjin")
    end
  end
end

sgs.ai_skill_use_func.QuanjinCard= function(qjcard, use, self)
  sgs.ai_use_priority.QuanjinCard = 2.4
  if self.player:hasSkill("daoshu") then
    sgs.ai_use_priority.QuanjinCard = 2.95--盗书之前
  end
  local target
  local my_hnum = self.player:getHandcardNum()
  local maxcard_num,maxhurt_num= 0,0
  local maxcard_hurt
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    local card_num = p:getHandcardNum()
    if card_num > maxcard_num then
      maxcard_num = card_num
    end
    if p:getMark("Global_InjuredTimes_Phase") > 0 and p:objectName() ~= self.player:objectName() then
      if card_num > maxhurt_num  then
        maxhurt_num = card_num
        maxcard_hurt = p
      end
    end
  end

  for _,c in sgs.qlist(self.player:getCards("h")) do
    local dummy_use = { isDummy = true }
    if c:isKindOf("BasicCard") then--参考怀异的，其他类型牌是否需要写？
        self:useBasicCard(c, dummy_use)
    end
  end
  local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValue(handcards)
	local card = handcards[1]
  local card_str = "@QuanjinCard=" .. card:getEffectiveId() .."&quanjin"

  local weak_friend
  self:sort(self.friends_noself, "hp")
  for _, friend in ipairs(self.friends_noself) do
    if friend:getMark("Global_InjuredTimes_Phase") > 0 then
      weak_friend = friend
      break
    end
  end

  if card:isKindOf("Peach") or (maxcard_num >= maxhurt_num)--桃或者牌最多的不是受伤的
  or (my_hnum > 2 and my_hnum >= maxcard_num)--自己手牌最多发牌
  or (maxcard_num >= my_hnum + 2)--能摸3张
  or (weak_friend and weak_friend:getHandcardNum() + 1 >= maxhurt_num) then--队友的牌数比受伤的不少于1
    if weak_friend then
      target = weak_friend
    end
  end
  if not target and not card:isKindOf("Peach") and (my_hnum < maxcard_num or my_hnum == maxhurt_num) then
    target = maxcard_hurt
  end

  if target then
    use.card =  sgs.Card_Parse(card_str)
		if use.to then
			use.to:append(target)
      local visibleflag--记录给出的手牌，盗书等技能需要
      visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end
			Global_room:writeToConsole("使用劝进目标:"..target:objectName().." 其手牌数:"..target:getHandcardNum())
		end
	end
end

sgs.ai_skill_choice.startcommand_quanjin = sgs.ai_skill_choice.startcommand_to

sgs.ai_skill_choice["docommand_quanjin"] = function(self, choices, data)
  local source = data:toPlayer()
  local index = self.player:getMark("command_index")
  local is_enemy = self:isEnemy(source)
  local is_friend = self:isFriend(source)
  local source_hnum = source:getHandcardNum()
  local maxcard_num = source_hnum
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    local card_num = p:getHandcardNum()
    if card_num > maxcard_num then
      maxcard_num = card_num
    end
  end
  local draw_num = maxcard_num - source_hnum

  if index == 1 then
    if not is_enemy and not is_friend then
      return "yes"
    end
    if is_friend then
      if draw_num <= 1 then
        return "yes"
      end
      if draw_num == 2 and not self:isWeak(source) then
        for _, p in ipairs(self.enemies) do
          if self:isWeak(p) and self:isEnemy(source, p) then
            return "yes"
          end
        end
      end
    end
    if is_enemy and draw_num > 3 then
      for _, p in ipairs(self.friends) do
        if self:isWeak(p) and self:isEnemy(source, p) then
          return "no"
        end
      end
      return "yes"
    end
  end
  if index == 2 then
    if is_friend and draw_num < 2 then
      return "yes"
    end
    if is_enemy and draw_num > 1 then
      return "yes"
    end
  end
  if index == 5 then
    if not self.player:faceUp() then
      return "yes"
    end
    if is_enemy and draw_num > 4 and math.random(1, 2) > 1 then
      return "yes"
    end
    if self.player:hasSkill("jushou") and self.player:getPhase() <= sgs.Player_Finish then
      return "yes"
    end
  end
  if is_enemy then
    if index == 3 then
      if draw_num > 3 and not self:isWeak() then
        return "yes"
      end
      if self.player:isRemoved() or (self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty()) then
        return "yes"
      end
    end
    if index == 4 then
      if draw_num > 1 and not source:canSlash(self.player, nil, true) then
        return "yes"
      end
      if self.player:getMark("command4_effect") > 0 then
        return "yes"
      end
    end
    if index == 6 and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 and draw_num > 1 then
      return "yes"
    end
  end
  return "no"
end

sgs.ai_skill_playerchosen["command_quanjin"] = sgs.ai_skill_playerchosen.damage

local zaoyun_skill = {}
zaoyun_skill.name = "zaoyun"
table.insert(sgs.ai_skills, zaoyun_skill)
zaoyun_skill.getTurnUseCard = function(self, inclusive)
  if self.player:isKongcheng() then return end
  if not self.player:hasUsed("ZaoyunCard") and self.player:hasShownOneGeneral() then
    --self.player:speak("zaoyun技能卡:"..self.player:objectName())
    return sgs.Card_Parse("@ZaoyunCard=.&zaoyun")
  end
end

sgs.ai_skill_use_func.ZaoyunCard= function(card, use, self)
  sgs.ai_use_priority.ZaoyunCard = 2.65--杀之前，怎么配合一技能先后？
  if self.player:hasSkill("daoshu") then
    sgs.ai_use_priority.QuanjinCard = 2.97--盗书之前
  end

  for _,c in sgs.qlist(self.player:getCards("h")) do
    local dummy_use = {
        isDummy = true,
    }
    if c:isKindOf("Peach") then--先吃桃
       self:useBasicCard(c, dummy_use)
    end
  end
  local target
  self:sort(self.enemies, "hp")
  for _, p in ipairs(self.enemies) do
    if p:hasShownOneGeneral() and not self.player:isFriendWith(p) and self:damageIsEffective(p, nil, self.player)
    and not self:needDamagedEffects(p, self.player) and not self:needToLoseHp(p, self.player)
    and self.player:distanceTo(p) > 1 and self.player:getHandcardNum() + 1 >= self.player:distanceTo(p) then
      local nearest = 6
      if p:getHp() == 1 and self:isWeak(p) and self.player:getHandcardNum() > 3 then
        sgs.ai_use_priority.ZaoyunCard = 3.4--AOE后，手牌充裕
        target = p
        break
      end
      if not self:isFriend(p) and self:isWeak(p) and self.player:distanceTo(p) <= nearest then
        nearest = self.player:distanceTo(p)
        target = p--技能优先度较低，应该其他牌差不多已出完，攻击最近的虚弱玩家
      end
    end
  end
  if not target then
    for _, p in ipairs(self.enemies) do
      if p:hasShownOneGeneral() and not self.player:isFriendWith(p) and self:damageIsEffective(p, nil, self.player)
      and not self:needDamagedEffects(p, self.player) and not self:needToLoseHp(p, self.player)
      and self.player:distanceTo(p) == 2 and self.player:getHandcardNum() > 1 then
        target = p--没有血少的则攻击距离2的
      end
    end
  end
  if target then
  	local card_list = {}
    local need_num = self.player:distanceTo(target) - 1
    local handcards = self.player:getCards("h")
    handcards = sgs.QList2Table(handcards)
    self:sortByUseValue(handcards, true)
    for _,c in ipairs(handcards) do
      if not (isCard("Peach", c, self.player)) then
        table.insert(card_list, c:getEffectiveId())
      end
      if #card_list == need_num then
        break
      end
    end
    if #card_list == need_num then
      local card_str = ("@ZaoyunCard=" .. table.concat(card_list, "+") .."&zaoyun")
      use.card =  sgs.Card_Parse(card_str)
      assert(use.card)
		  if use.to then
			  use.to:append(target)
			  Global_room:writeToConsole("使用凿运目标:"..target:objectName().." 其距离:"..self.player:distanceTo(target))
		  end
   end
	end
end

--徐庶
sgs.ai_skill_invoke.pozhen = function(self, data)
  local target = data:toPlayer()
  local has_attack_skill = target:hasSkills("luanji|shuangxiong")
  if not self:isFriend(target) and (self:getOverflow(target) > 1 or target:getHandcardNum() > 4) then
    local weak_count = 0
    for _, p in ipairs(self.friends) do
      if (target:canSlash(p, nil, true) or has_attack_skill) and self:isWeak(p) then
        weak_count = weak_count + 1
        if weak_count > 1 then
          return true
        end
      end
      if (target:canSlash(p, nil, true) or has_attack_skill) and p:getHp() == 1 then
        return true
      end
    end
  end
  if self:isEnemy(target) and self.player:getHp() == 1 then
      for _, p in ipairs(self.friends) do
        if (target:canSlash(p, nil, true) or has_attack_skill) and self:isWeak(p) then
          return true
        end
      end
  end
	return false
end

sgs.ai_skill_choice["pozhen-discard"] = function(self, choices, data)
  local target = self.room:getCurrent()
  local np = target:getNextAlive()
  local lp = target:getLastAlive()
  if self:isFriend(np) and self:isFriend(lp) then
    return "no"
  end
  return "yes"
end

sgs.ai_skill_invoke.jiancai = function(self, data)
  local prompt = data:toString():split(":")
  if prompt[1] == "transform" then
    --Global_room:writeToConsole("荐才:变更时的备选武将数+2")
    return true
  end
  if prompt[1] == "damage" then
    local target = self.room:findPlayerbyobjectName(prompt[2])
    local damageStruct = self.player:getTag("JiancaiDamagedata"):toDamage()
    if self:getAllPeachNum() + damageStruct.to:getHp() >= damageStruct.damage - 1  then
      return true
    end
  end
	return false
end

--吴景
local diaogui_skill = {}
diaogui_skill.name = "diaogui"
table.insert(sgs.ai_skills, diaogui_skill)
diaogui_skill.getTurnUseCard = function(self)
  if self.player:hasUsed("DiaoguiCard") then return end
  if self:getCardsNum("EquipCard") == 0 then return end

  local equipcard
  if self:needToThrowArmor() then
		equipcard = self.player:getArmor()
  end
  if not equipcard and self.player:hasSkills(sgs.lose_equip_skill) and self.player:hasEquip()  then
    local equip = self.player:getCards("e")
    equip = sgs.QList2Table(equip)
    self:sortByUseValue(equip, true)
    equipcard = equip[1]
  end
  if not equipcard then
    local cards = self.player:getCards("he")
    for _, id in sgs.qlist(self.player:getHandPile()) do
      cards:prepend(sgs.Sanguosha:getCard(id))
    end
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
      if c:isKindOf("EquipCard") then
        equipcard = c
        break
      end
    end
  end
  if equipcard then
    return sgs.Card_Parse("@DiaoguiCard=" .. equipcard:getEffectiveId())
  end
end

sgs.ai_skill_use_func.DiaoguiCard = function(card, use, self)
--[[
	foreach (ServerPlayer *p, to_count) {
		Player *p1 = p->getNextAlive();
		Player *p2 = p->getLastAlive();

		if (p1 && p2 && p1 != p2 && p1->getFormation().contains(p2)) {
			if (card_use.from->isFriendWith(p1))
				x = qMax(x, p1->getFormation().length());
		}
	}
	self.player:getNextAlive():getFormation()
	enemy:getFormation():contains(self.player)
]]--主动形成队列怎么判定？
	local lure_targets = sgs.PlayerList()
	local clone_tiger = sgs.cloneCard("lure_tiger", card:getSuit(), card:getNumber())
	if self.player:isCardLimited(clone_tiger, sgs.Card_MethodUse) then
		return
	end
	local current_formation = self.player:getFormation()
	function formationFirst(formation)--自身队列起始角色
		if formation:length() == 1 then return formation:first() end
		local begin_f = formation:first()
		local LP = begin_f:getLastAlive()
		while formation:contains(LP) do
			begin_f = LP
			LP = begin_f:getLastAlive()
		end
		return begin_f
	end
	function formationLast(formation)--自身队列末尾角色
		if formation:length() == 1 then return formation:last() end
		local ending_f = formation:last()
		local NP = ending_f:getNextAlive()
		while formation:contains(NP) do
			ending_f = NP
			NP = ending_f:getNextAlive()
		end
		return ending_f
	end
	local lure_draw = 0
	local residue = self.player:aliveCount() - current_formation:length()
	local max_formation = sgs.PlayerList()
	for _, afriend in ipairs(self.friends) do
		if not self.player:isFriendWith(afriend) then continue end
		if max_formation:contains(afriend) then continue end
		max_formation:append(afriend)
	end
	local max_num = max_formation:length()
	--Global_room:writeToConsole("调归调虎最大摸牌数:"..tostring(max_num))
	if max_num >= 2 then
		local count = 0
		local invest = false
		local last_draw = 0
		local last_players = sgs.PlayerList()--targetFilter不能用SPlayerList
		local begin_f = formationFirst(current_formation)--自身队列起始角色,不能使用current_formation:first(),因为没有排序,必然是自己
		local LP = begin_f:getLastAlive(1,true)--考虑调虎上家
		while not current_formation:contains(LP) do
			local name = LP:getActualGeneral1Name() .. "/" .. LP:getActualGeneral2Name()
			--Global_room:writeToConsole("当前调归考虑:"..name)
			if not self.player:isFriendWith(LP) then
				if clone_tiger:targetFilter(last_players, LP, self.player) and self:trickIsEffective(clone_tiger, LP, self.player) then
					--Global_room:writeToConsole("调归尝试增加:"..name)
					last_players:append(LP)
					invest = true--先加入预选,标记,用于之后判断是否有摸牌收益
					LP = LP:getLastAlive(1,true)
					count = count + 1
				elseif invest then--达到目标上限或被无效目标卡住时,反推取消无收益目标
					local NP_invalid = LP:getNextAlive(1,true)
					while not self.player:isFriendWith(NP_invalid) do
						local return_name = NP_invalid:getActualGeneral1Name() .. "/" .. NP_invalid:getActualGeneral2Name()
						--Global_room:writeToConsole("调归减少无效目标:"..return_name)
						if not self.player:isFriendWith(NP_invalid) and last_players:contains(NP_invalid) then
							last_players:removeOne(NP_invalid)
							NP_invalid = NP_invalid:getNextAlive(1,true)
							if current_formation:contains(NP_invalid) then
								LP = begin_f:getLastAlive(1,true)
								invest = false
								break
							end
						else
							invest = false
							break
						end
					end
					break
				else--保留有收益目标,跳出循环
					break
				end
			elseif self.player:isFriendWith(LP) then
				--Global_room:writeToConsole("调归确定收益:"..name..":"..tostring(last_draw)..":"..tostring(LP:getFormation():length())..":"..tostring(self.player:getFormation():length()))
				last_draw = last_draw + LP:getFormation():length() + self.player:getFormation():length()
				count = count + LP:getFormation():length()
				invest = false--确定能摸牌,移除标记
				if residue - count < 3 then break end--根据剩余角色数判断不存在调虎后仍然不在队列的队友
				LP = formationFirst(LP:getFormation()):getLastAlive(1,true)--调虎上一个目标后形成的新队列起始
			end
		end
		Global_room:writeToConsole("调归上家:"..tostring(last_players:length())..":"..tostring(last_draw))
		local count = 0
		local invest = false
		local next_draw = 0
		local next_players = sgs.PlayerList()--targetFilter不能用SPlayerList
		local ending_f = formationLast(current_formation)--自身队列末尾角色
		local NP = ending_f:getNextAlive(1,true)--考虑调虎下家
		while not current_formation:contains(NP) do
			local name = NP:getActualGeneral1Name() .. "/" .. NP:getActualGeneral2Name()
			--Global_room:writeToConsole("当前调归考虑:"..name)
			if not self.player:isFriendWith(NP) then
				if clone_tiger:targetFilter(next_players, NP, self.player) and self:trickIsEffective(clone_tiger, NP, self.player) then
					--Global_room:writeToConsole("调归尝试增加:"..name)
					next_players:append(NP)
					invest = true
					NP = NP:getNextAlive(1,true)
					count = count + 1
				elseif invest then--达到目标上限或被无效目标卡住时,反推取消无收益目标
					local LP_invalid = NP:getLastAlive(1,true)
					while not self.player:isFriendWith(LP_invalid) do
						local return_name = LP_invalid:getActualGeneral1Name() .. "/" .. LP_invalid:getActualGeneral2Name()
						--Global_room:writeToConsole("调归减少无效目标:"..return_name)
						if not self.player:isFriendWith(LP_invalid) and next_players:contains(LP_invalid) then
							next_players:removeOne(LP_invalid)
							LP_invalid = LP_invalid:getLastAlive(1,true)
							if current_formation:contains(LP_invalid) then
								NP = ending_f:getNextAlive(1,true)
								invest = false
								break
							end
						else
							invest = false
							break
						end
					end
					break
				else--保留有收益目标,跳出循环
					break
				end
			elseif self.player:isFriendWith(NP) then
				--Global_room:writeToConsole("调归确定收益:"..name..":"..tostring(next_draw)..":"..tostring(NP:getFormation():length())..":"..tostring(self.player:getFormation():length()))
				next_draw = next_draw + NP:getFormation():length() + self.player:getFormation():length()
				count = count + NP:getFormation():length()
				invest = false
				if residue - count < 3 then break end
				NP = formationLast(NP:getFormation()):getNextAlive(1,true)--调虎上一个目标后形成的新队列末尾
			end
		end
		Global_room:writeToConsole("调归下家:"..tostring(next_players:length())..":"..tostring(next_draw))
		if max_num == last_draw or next_players:isEmpty() then
			lure_draw = last_draw
			for _, p in sgs.qlist(last_players) do
				lure_targets:append(p)
			end
		elseif max_num == next_draw or last_players:isEmpty() then
			lure_draw = next_draw
			for _, p in sgs.qlist(next_players) do
				lure_targets:append(p)
			end
		else
			--退掉末端(Last)添加首端(Next),重新判断收益
			local max_draw = last_draw
			local new_lure_targets = sgs.PlayerList()
			for _, p in sgs.qlist(last_players) do
				new_lure_targets:append(p)
			end
			local i = 0
			while true do
				new_lure_targets:removeAt(0)
				new_lure_targets:append(next_players:at(i))
				i = i + 1
				local new_formation = sgs.PlayerList()--新队列
				for _, afriend in sgs.qlist(max_formation) do
					if new_formation:contains(afriend) then continue end
					for _, e in sgs.qlist(new_lure_targets) do
						if afriend:isAdjacentTo(e) and not new_formation:contains(afriend) then
							for _, p in sgs.qlist(afriend:getFormation()) do
								if not new_formation:contains(p) then
									new_formation:append(p)
								end
							end
						end
					end
				end
				if new_formation:length() > max_draw then
					max_draw = new_formation:length()
					lure_targets = sgs.PlayerList()
					for _, p in sgs.qlist(new_lure_targets) do
						lure_targets:append(p)
					end
					lure_draw = new_formation:length()
					if new_formation:length() == max_num then break end
				end
				if new_lure_targets:first() == next_players:first() then break end
			end
		end
	end
	--调归至少摸2
	if lure_draw > 2 and not lure_targets:isEmpty() then
		use.card = card
		if use.to then
			Global_room:writeToConsole("调归多摸:"..tostring(lure_draw))
			use.to = sgs.PlayerList2SPlayerList(lure_targets)
		end
	else
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardLureTiger(clone_tiger, dummyuse)
		if not dummyuse.to:isEmpty() then
			use.card = card
			if use.to then
				use.to = dummyuse.to
			end
		elseif lure_draw == 2 and not lure_targets:isEmpty() then
			use.card = card
			if use.to then
				Global_room:writeToConsole("调归摸:"..tostring(lure_draw))
				use.to = sgs.PlayerList2SPlayerList(lure_targets)
			end
		end
	end
end
--[[--调归测试
	Global_room:writeToConsole("lure_test")
	local target = R:askForPlayerChosen(P, R:getOtherPlayers(P), "TheTest")
	local lure_targets = sgs.PlayerList()
	local clone_tiger = sgs.cloneCard("lure_tiger", sgs.Card_NoSuit, 0)
	local current_formation = target:getFormation()
	function formationFirst(formation)--自身队列起始角色
		if formation:length() == 1 then return formation:first() end
		local begin_f = formation:first()
		local LP = begin_f:getLastAlive()
		while formation:contains(LP) do
			begin_f = LP
			LP = begin_f:getLastAlive()
		end
		return begin_f
	end
	function formationLast(formation)--自身队列末尾角色
		if formation:length() == 1 then return formation:last() end
		local ending_f = formation:last()
		local NP = ending_f:getNextAlive()
		while formation:contains(NP) do
			ending_f = NP
			NP = ending_f:getNextAlive()
		end
		return ending_f
	end
	local lure_draw = 0
	local residue = target:aliveCount() - current_formation:length()
	local max_formation = sgs.PlayerList()
	
	for _,afriend in sgs.qlist(R:getAlivePlayers()) do
		if not target:isFriendWith(afriend) then continue end
		if max_formation:contains(afriend) then continue end
		max_formation:append(afriend)
	end
	local max_num = max_formation:length()
	Global_room:writeToConsole("max_num:"..tostring(max_num))
	if max_num >= 2 then
		--比较极端的情况(1-1-0--2-)表示(10人局无君主最多4队友,有君主超过4队友的碾压局暂不考虑)如果能单方向调虎2目标摸3牌仍然不会少摸牌
		local count = 0
		local invest = false
		local last_draw = 0
		local last_players = sgs.PlayerList()--targetFilter不能用SPlayerList
		local begin_f = formationFirst(current_formation)--自身队列起始角色
		local LP = begin_f:getLastAlive(1,true)--考虑调虎上家
		while not current_formation:contains(LP) do
			local name = LP:getActualGeneral1Name() .. "/" .. LP:getActualGeneral2Name()
			Global_room:writeToConsole("current_consider:"..name)
			if not target:isFriendWith(LP) then
				--if clone_tiger:targetFilter(last_players, LP, target) and self:trickIsEffective(clone_tiger, LP, target) then
				if clone_tiger:targetFilter(last_players, LP, target) and not target:isProhibited(LP, clone_tiger, last_players) then
					Global_room:writeToConsole("current_lure:"..name)
					last_players:append(LP)
					invest = true
					LP = LP:getLastAlive(1,true)
					count = count + 1
				elseif invest then--达到目标上限或被无效目标卡住时,反推取消无收益目标
					local NP_invalid = LP:getNextAlive(1,true)
					while not target:isFriendWith(NP_invalid) do
						local return_name = NP_invalid:getActualGeneral1Name() .. "/" .. NP_invalid:getActualGeneral2Name()
						Global_room:writeToConsole("consider_return:"..return_name)
						if not target:isFriendWith(NP_invalid) and last_players:contains(NP_invalid) then
							last_players:removeOne(NP_invalid)
							NP_invalid = NP_invalid:getNextAlive(1,true)
							if current_formation:contains(NP_invalid) then
								LP = begin_f:getLastAlive(1,true)
								invest = false
								break
							end
						else
							invest = false
							break
						end
					end
					break
				else--保留有收益目标,跳出循环
					break
				end
			elseif target:isFriendWith(LP) then
				Global_room:writeToConsole("current_add:"..name..":"..tostring(last_draw)..":"..tostring(LP:getFormation():length())..":"..tostring(target:getFormation():length()))
				last_draw = last_draw + LP:getFormation():length() + target:getFormation():length()
				count = count + LP:getFormation():length()
				invest = false
				if residue - count < 3 then break end--根据剩余角色数判断不存在调虎后仍然不在队列的队友
				LP = formationFirst(LP:getFormation()):getLastAlive(1,true)--调虎上一个目标后形成的新队列起始
			end
		end
		Global_room:writeToConsole("lure_last:"..tostring(last_players:length())..":"..tostring(last_draw))
		local count = 0
		local invest = false
		local next_draw = 0
		local next_players = sgs.PlayerList()--targetFilter不能用SPlayerList
		local ending_f = formationLast(current_formation)--自身队列末尾角色
		local NP = ending_f:getNextAlive(1,true)--考虑调虎下家
		while not current_formation:contains(NP) do
			local name = NP:getActualGeneral1Name() .. "/" .. NP:getActualGeneral2Name()
			Global_room:writeToConsole("current_consider:"..name)
			if not target:isFriendWith(NP) then
				--if clone_tiger:targetFilter(next_players, NP, target) and self:trickIsEffective(clone_tiger, NP, target) then
				if clone_tiger:targetFilter(next_players, NP, target) and not target:isProhibited(NP, clone_tiger, next_players) then
					Global_room:writeToConsole("current_lure:"..name)
					next_players:append(NP)
					invest = true
					NP = NP:getNextAlive(1,true)
					count = count + 1
				elseif invest then--达到目标上限或被无效目标卡住时,反推取消无收益目标
					local LP_invalid = NP:getLastAlive(1,true)
					while not target:isFriendWith(LP_invalid) do
						local return_name = LP_invalid:getActualGeneral1Name() .. "/" .. LP_invalid:getActualGeneral2Name()
						Global_room:writeToConsole("consider_return:"..return_name)
						if not target:isFriendWith(LP_invalid) and next_players:contains(LP_invalid) then
							next_players:removeOne(LP_invalid)
							LP_invalid = LP_invalid:getLastAlive(1,true)
							if current_formation:contains(LP_invalid) then
								NP = ending_f:getNextAlive(1,true)
								invest = false
								break
							end
						else
							invest = false
							break
						end
					end
					break
				else--保留有收益目标,跳出循环
					break
				end
			elseif target:isFriendWith(NP) then
				Global_room:writeToConsole("current_add:"..name..":"..tostring(next_draw)..":"..tostring(NP:getFormation():length())..":"..tostring(target:getFormation():length()))
				next_draw = next_draw + NP:getFormation():length() + target:getFormation():length()
				count = count + NP:getFormation():length()
				invest = false
				if residue - count < 3 then break end
				NP = formationLast(NP:getFormation()):getNextAlive(1,true)--调虎上一个目标后形成的新队列末尾
			end
		end
		Global_room:writeToConsole("lure_next:"..tostring(next_players:length())..":"..tostring(next_draw))
		if max_num == last_draw or next_players:isEmpty() then
			lure_draw = last_draw
			for _, p in sgs.qlist(last_players) do
				lure_targets:append(p)
			end
		elseif max_num == next_draw or last_players:isEmpty() then
			lure_draw = next_draw
			for _, p in sgs.qlist(next_players) do
				lure_targets:append(p)
			end
		else
			--退掉末端(Last)添加首端(Next),重新判断收益
			local max_draw = last_draw
			local new_lure_targets = sgs.PlayerList()
			for _, p in sgs.qlist(last_players) do
				new_lure_targets:append(p)
			end
			local i = 0
			while true do
				new_lure_targets:removeAt(0)
				new_lure_targets:append(next_players:at(i))
				i = i + 1
				local new_formation = sgs.PlayerList()
				for _, afriend in sgs.qlist(max_formation) do
					if new_formation:contains(afriend) then continue end
					for _, e in sgs.qlist(new_lure_targets) do
						if afriend:isAdjacentTo(e) and not new_formation:contains(afriend) then
							for _, p in sgs.qlist(afriend:getFormation()) do
								if not new_formation:contains(p) then
									new_formation:append(p)
								end
							end
						end
					end
				end
				if new_formation:length() > max_draw then
					max_draw = new_formation:length()
					lure_targets = sgs.PlayerList()
					for _, p in sgs.qlist(new_lure_targets) do
						lure_targets:append(p)
					end
					lure_draw = new_formation:length()
					if new_formation:length() == max_num then break end
				end
				if new_lure_targets:first() == next_players:first() then break end
			end
		end
	end
	Global_room:writeToConsole("lure_draw:"..tostring(lure_draw))
	for _, p in sgs.qlist(lure_targets) do
		Global_room:writeToConsole("lure_targets:"..sgs.Sanguosha:translate(p:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(p:getActualGeneral2Name()).."("..sgs.Sanguosha:translate(string.format("SEAT(%s)",p:getSeat()))..")")
	end
--]]
sgs.ai_use_priority.DiaoguiCard = sgs.ai_use_priority.LureTiger - 0.05--先用普通的掉虎

sgs.ai_skill_invoke.fengyang = true

--严白虎
sgs.ai_skill_invoke.zhidao = function(self, data)
	if not self:willShowForDefence() or not self:willShowForAttack() then
    return false
  end
  if (self:getCardsNum("AmazingGrace") + self:getCardsNum("GodSalvation") +  self:getCardsNum("AwaitExhausted") +
  self:getCardsNum("SavageAssault") + self:getCardsNum("ArcheryAttack") > 0) then
    return false
  end
  --判断杀目标距离
  local max_range = 0
  local horse_range = 0
  local current_range = self.player:getAttackRange()
  for _,card in sgs.qlist(self.player:getCards("he")) do
    if card:isKindOf("Weapon") and max_range < sgs.weapon_range[card:getClassName()] then
      max_range = sgs.weapon_range[card:getClassName()]
    end
  end
  if self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse() then
    horse_range = 1
  end
  local range_fix = math.min(current_range - max_range, 0) - horse_range
  if self:getCardsNum("Slash") == 0 then return false end
	local slashes = self:getCards("Slash")
	self:sortByUseValue(slashes)
	self:sort(self.enemies, "defenseSlash")
	for _, slash in ipairs(slashes) do
		for _, enemy in ipairs(self.enemies) do
			if self:isWeak(enemy) and not self.player:canSlash(enemy, slash, true, range_fix) and not self:slashProhibit(slash, enemy)
				and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
				and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen.zhidao = function(self, targets)
  if self:getCardsNum("AmazingGrace") > 0 or self:getCardsNum("GodSalvation") > 0  or self:getCardsNum("AwaitExhausted") > 0 then
    for _,p in sgs.qlist(targets) do
      if self:isFriendWith(p) then
        return p
      end
    end
    for _,p in sgs.qlist(targets) do
      if self:isFriend(p) then
        return p
      end
    end
  end
	return sgs.ai_skill_playerchosen.damage(self, targets)
end

sgs.ai_skill_invoke.jilix = function(self, data)
  local prompt = data:toString()
  if prompt == "damage" then
    return true
  else
    local prompt_list = prompt:split(":")
    if prompt_list[2] == self.player:objectName() or prompt_list[4]:match("peach") or prompt_list[4]:match("befriend_attacking") then
      return true
    end
  end
	return false
end

--钟会
sgs.ai_skill_invoke.quanji = function(self, data)
	if not self:willShowForMasochism() and not self:willShowForAttack() then
    return false
  end
	return true
end

sgs.ai_skill_exchange._quanji = function(self,pattern,max_num,min_num,expand_pile)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
  if self.player:getPhase() <= sgs.Player_Play then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end
  for _, c in ipairs(cards) do--藏君主装备
    if c:isKindOf("LuminousPearl") then
      local lord = self.room:getLord("wu")
      if lord and self:isEnemy(lord) then
        return c:getEffectiveId()
      end
    elseif c:isKindOf("DragonPhoenix") then
      local lord = self.room:getLord("shu")
      if lord and self:isEnemy(lord) then
        return c:getEffectiveId()
      end
    elseif c:isKindOf("PeaceSpell") then
      local lord = self.room:getLord("qun")
      if lord and self:isEnemy(lord) then
        return c:getEffectiveId()
      end
    elseif c:isKindOf("SixDragons") then
      local lord = self.room:getLord("wei")
      if lord and self:isEnemy(lord) then
        return c:getEffectiveId()
      end
    end
  end
  if #cards > 1 and cards[1]:isKindOf("Crossbow")--别放连弩
  and not ((isCard("Peach", cards[2], self.player) or cards[2]:isKindOf("Analeptic")) and self.player:getHp() == 1) then
    return cards[2]:getEffectiveId()
  end
	return cards[1]:getEffectiveId()
end

local paiyi_skill = {}
paiyi_skill.name = "paiyi"
table.insert(sgs.ai_skills, paiyi_skill)
paiyi_skill.getTurnUseCard = function(self)
  if self.player:getPile("power_pile"):length() > 0 and not self.player:hasUsed("PaiyiCard") then
		return sgs.Card_Parse("@PaiyiCard=" .. self.player:getPile("power_pile"):first())
	end
	--[[if self.player:getPile("power_pile"):length() > 0 then--self.player:usedTimes("PaiyiCard") < 2
    if self.player:getHandcardNum() < 2
    or self.player:getHandcardNum() + (self:isWeak() and 1 or 2) < self.player:getMaxCards() then
      return sgs.Card_Parse("@PaiyiCard=" .. self.player:getPile("power_pile"):first())
    end
	end]]
	return nil
end

sgs.ai_skill_use_func.PaiyiCard = function(card, use, self)
  sgs.ai_use_priority.PaiyiCard = 2.4
	local target
  if self.player:getPile("power_pile"):length() > 3 then--技能修改
    self:sort(self.friends, "defense")
	  for _, friend in ipairs(self.friends) do
		  if friend:getHandcardNum() < 2 and not self:needKongcheng(friend, true) and self.player:isFriendWith(friend) then
			  target = friend
        break
		  end
	  end
	  if not target then
		  target = self.player
	  end
  else--4权以下，排异打伤害优先度多少合适？
 	  self:sort(self.enemies, "hp")
	  if not target then
		  for _, enemy in ipairs(self.enemies) do
			  if enemy:getHp() == 1 and self:isWeak(enemy)
				and not enemy:hasShownSkills(sgs.masochism_skill)
        and not enemy:hasShownSkill("jijiu")
				and self:damageIsEffective(enemy, nil, self.player) and not self:cantbeHurt(enemy)
				and not (self:needDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy))
				and enemy:getHandcardNum() + self.player:getPile("power_pile"):length() - 1 > self.player:getHandcardNum() then
				  target = enemy
          break
			  end
	    end
    end
  end
  if self.player:getPile("power_pile"):length() > 7 then
    sgs.ai_use_priority.PaiyiCard = 10
  end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_card_intention.PaiyiCard = function(self, card, from, tos)
	local to = tos[1]
	if to:objectName() == from:objectName() then return end
	if from:isFriendWith(to) then
    sgs.updateIntention(from, to, -60)
	else
		sgs.updateIntention(from, to, 60)
	end
end

sgs.paiyi_keep_value = {
	Crossbow = 6
}

function sgs.ai_cardneed.paiyi(to, card, self)
  return card:isKindOf("Crossbow")
end

--司马昭
sgs.ai_skill_invoke.suzhi = function(self, data)
	return self:willShowForAttack()
end

function sgs.ai_cardneed.suzhi(to, card, self)
	return card:isKindOf("Axe") or isCard("Duel",card, to)
end

sgs.ai_skill_invoke.fankui_simazhao = function(self, data)
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

sgs.ai_skill_invoke.zhaoxin = function(self, data)
  if not self:willShowForDefence() or not self:willShowForMasochism() then
    return false
  end
  local my_hnum = self.player:getHandcardNum()
  local targets = {}
  self.zhaoxin_target = nil
  for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
    if not p:isKongcheng() and p:getHandcardNum() <= my_hnum then
      table.insert(targets, p)
    end
  end
  if #targets == 0 then
    return false
  end
  self:sort(targets, "handcard", true)

  local my_value = 0
  for _, card in sgs.qlist(self.player:getHandcards()) do
    if self.player:getPhase() <= sgs.Player_Play then
      my_value = my_value + self:getUseValue(card)
    else
      my_value = my_value + self:getKeepValue(card)
    end
  end

  local same_card_target, one_less_target
  local same_card_value, one_less_value = 0, 0
  local mark_peach_num = self.player:getMark("@companion") + self.player:getMark("@careerist")--包含标记桃
  local need_peach = (self.player:getHp() > 1 and self:getCardsNum("Peach") < 1 + mark_peach_num)
        or (self.player:getHp() == 1 and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < 1 + mark_peach_num)

  for _, p in ipairs(targets) do
    local known = 0
    local value = 0
    local p_hnum = p:getHandcardNum()
    for _, card in sgs.qlist(p:getHandcards()) do
      if sgs.cardIsVisible(card, p, self.player) then
        known = known + 1
        if self.player:getPhase() <= sgs.Player_Play then
          value = value + self:getUseValue(card)
        else
          value = value + self:getKeepValue(card)
        end
        if isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player) then
          if need_peach and self:isWeak() then
            Global_room:writeToConsole("昭心找桃")
            self.zhaoxin_target = p
            return true
          end
        end
      end
    end
    local extra_value = self:getLeastHandcardNum()*4
	if value + extra_value > my_value then
		Global_room:writeToConsole("昭心换好牌")
		self.zhaoxin_target = p
		return true
	end
	if p_hnum == my_hnum and not (known == p_hnum and value + extra_value < my_value) and value + extra_value >= same_card_value then
		same_card_value = value + extra_value
		same_card_target = p
	end
	if p_hnum + 1 == my_hnum and not (known == p_hnum and value + extra_value < my_value) and value + extra_value >= one_less_value then
		one_less_value = value + extra_value
		one_less_target = p
	end
  end
  if need_peach and same_card_target then
    Global_room:writeToConsole("昭心换等量牌")
    self.zhaoxin_target = same_card_target
    return true
  end
  if need_peach and self.player:isWounded() and one_less_target then
    Global_room:writeToConsole("昭心换-1牌")
    self.zhaoxin_target = one_less_target
    return true
  end
	return false
end

sgs.ai_skill_playerchosen["zhaoxin_exchange"] = function(self, targets)
  targets = sgs.QList2Table(targets)
  if self.zhaoxin_target then-- and table.contains(targets ,self.zhaoxin_target)
    Global_room:writeToConsole("昭心目标:"..sgs.Sanguosha:translate(self.zhaoxin_target:getGeneralName()).."/"..sgs.Sanguosha:translate(self.zhaoxin_target:getGeneral2Name()))
    return self.zhaoxin_target
  end
  self:sort(targets, "handcard", true)
	return targets[1]
end

--孙綝
sgs.ai_skill_invoke.shilu = true

sgs.ai_skill_cardask["@shilu"] = function(self, data, pattern, target, target2, arg, arg2)
  local diascard_num = tonumber(arg)
  local unpreferedCards = {}--制衡，配合xiongnve_attack换杀

  local function addcard(card)
    if #unpreferedCards < diascard_num and not card:canRecast() and not table.contains(unpreferedCards, card:getId()) then
      if self.player:hasSkills(sgs.lose_equip_skill) then
        for _, id in ipairs(unpreferedCards) do
          if self.room:getCardPlace(id) == sgs.Player_PlaceEquip then
            return
          end
        end
      end
      if card:isKindOf("WoodenOx") and not self.player:getPile("wooden_ox"):isEmpty() then
        return
      end
      table.insert(unpreferedCards, card:getId())
    end
  end

  if self:needToThrowArmor() then
    addcard(self.player:getArmor())
  end

  local xiongnve_nolimit = false
  self.xiongnve_choice = nil
  local name = sgs.ai_skill_choice.xiongnve_attack(self, self.player:property("massacre_pile"):toString())
  if name and self.xiongnve_choice == "nolimit" then
    self.xiongnve_choice = nil
    xiongnve_nolimit = true
  end
  local has_Crossbow = self:getCardsNum("Crossbow") > 0
	if xiongnve_nolimit or (#self.enemies > 0 and (has_Crossbow or self:hasCrossbowEffect()) and self.player:getCardCount(true) >= 4) then
		local allcards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(allcards, true)
		for _, acard in ipairs(allcards) do
			if not isCard("Peach", acard, self.player) and not isCard("Slash", acard, self.player)
			and not isCard("BefriendAttacking", acard, self.player) and not isCard("AllianceFeast", acard, self.player)
			and (self.player:getOffensiveHorse() or acard:isKindOf("OffensiveHorse") or not has_Crossbow)
			and not acard:isKindOf("Crossbow") and not self.player:isJilei(acard)
			then--由于是回合开始，其他有用的牌处理？如火烧、顺等
				addcard(acard)
			end
		end
  end

  if self.player:getHp() < 3 then--复制的制衡，未详细修过
		local use_slash, keep_jink, keep_analeptic  = false, false, false
		local keep_weapon
		local allcards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(allcards, true)
		for _, acard in ipairs(allcards) do
			if not isCard("Peach", acard, self.player) and not isCard("ExNihilo", acard, self.player)
			and not isCard("BefriendAttacking", acard, self.player) and not isCard("AllianceFeast", acard, self.player) then
				local shouldUse = true
				if isCard("Slash", acard, self.player) and not use_slash then
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(acard, dummy_use)
					if dummy_use.card then
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if acard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { isDummy = true }
					self:useTrickCard(acard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if acard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(acard) and not(self.player:getTreasure() or acard:isKindOf("Treasure")) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(acard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and acard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(acard) and acard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(acard) and acard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if isCard("Jink", acard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", acard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then addcard(acard) end
			end
		end
	end

	if #unpreferedCards == 0 then--复制的制衡，未详细修过
		local use_slash_num = 0
    local hcards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(hcards, true)
		for _, card in ipairs(hcards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then addcard(card) end
			end
		end

		local jink_num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then jink_num = jink_num + 1 end
		if jink_num > 0 then
			for _, card in ipairs(hcards) do
				if card:isKindOf("Jink") and jink_num > 0 then
					addcard(card)
					jink_num = jink_num - 1
				end
			end
		end
		for _, card in ipairs(hcards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				addcard(card)
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if not dummy_use.card then addcard(card) end
			end
		end
  end

  if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
    addcard(self.player:getWeapon())
  end
  if self.player:getOffensiveHorse() and self.player:getWeapon() then
    addcard(self.player:getOffensiveHorse())
  end

  if #unpreferedCards == 0 then
    return "."
  end
  return "$" .. table.concat(unpreferedCards, "+")
end

sgs.ai_skill_invoke.xiongnve = function(self, data)
  if data:toString() == "attack" then
    self.xiongnve_choice = nil
    local name = sgs.ai_skill_choice.xiongnve_attack(self, self.player:property("massacre_pile"):toString())
    if name and self.xiongnve_choice then
      Global_room:writeToConsole("凶虐进攻选择:"..name.."|"..self.xiongnve_choice)
      return true
    end
  end
  if data:toString() == "defence"  then
    if self.player:getMark("ThreatenEmperorExtraTurn") > 0 then--连续回合
      return false
    end
    if self.player:getMark("##xiongnve_avoid") > 0 then
      return false
    end
    if self:isWeak() or self.player:getHp() < 2 then
      return true
    end
    if not self.player:faceUp() then--翻面两回合效果
      return true
    end
    local useless_num = 0
    local generals = self.player:property("massacre_pile"):toString():split("+")
    local xiongnve_kingdom = {["wei"] = {}, ["shu"] = {}, ["wu"] = {}, ["qun"] = {}, ["careerist"] = {}, ["double"] = {}}
    for _, name in ipairs(generals) do
      local general = sgs.Sanguosha:getGeneral(name)
      if not general:isDoubleKingdoms() then
        table.insert(xiongnve_kingdom[general:getKingdom()],name)
      else
        table.insert(xiongnve_kingdom["double"],name)
      end
    end
    local kingdoms = {wei = 0, shu = 0, wu = 0, qun = 0, careerist = 0}--计算势力的人数，正是敌人，负是队友
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
      if p:hasShownOneGeneral() then--非暗将
        local p_kingdom = p:getKingdom()
        if p_kingdom == "god" then
          p_kingdom = "careerist"
        end
        kingdoms[p_kingdom] = kingdoms[p_kingdom] + (self:isFriend(p) and -1 or 1)
      end
    end
    for key, value in pairs(kingdoms) do
      if value == 0 and #xiongnve_kingdom[key] > 0 then
        useless_num = useless_num + #xiongnve_kingdom[key]
      end
      if value > 0 and #xiongnve_kingdom[key] > math.min(value*2, 5) then
        useless_num = useless_num + #xiongnve_kingdom[key] - value
      end
    end
    for _, name in ipairs(xiongnve_kingdom["double"]) do
      local general = sgs.Sanguosha:getGeneral(name)
      local double_kingdoms = general:getKingdoms()
      if kingdoms[double_kingdoms[1]] == 0 and kingdoms[double_kingdoms[2]] == 0 then
        useless_num = useless_num + 1
      end
    end
    if useless_num > 1 and (self.player:getLostHp() > 1 or self.player:getHp() < 3) then
      return true
    end
    if useless_num > (self.player:isWounded() and 4 or 6) then
      return true
    end
  end
	return false
end

sgs.ai_skill_choice.xiongnve_attack = function(self, generals)
  generals = generals:split("+")
  local xiongnve_kingdom = {["wei"] = {}, ["shu"] = {}, ["wu"] = {}, ["qun"] = {}, ["careerist"] = {}, ["double"] = {}}
	for _, name in ipairs(generals) do
		local general = sgs.Sanguosha:getGeneral(name)
		if not general:isDoubleKingdoms() then
			table.insert(xiongnve_kingdom[general:getKingdom()],name)
		else
			table.insert(xiongnve_kingdom["double"],name)
		end
	end
  local kingdoms = {wei = 0, shu = 0, wu = 0, qun = 0, careerist = 0}--计算势力的人数，正是敌人，负是队友
  local kingdom_players = {wei = {}, shu = {}, wu = {}, qun = {}, careerist = {}}--各国家成员
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:isRemoved() and p:hasShownOneGeneral() then--非暗将和掉虎
			local p_kingdom = p:getKingdom()
			if p_kingdom == "god" then
				p_kingdom = "careerist"
			end
			kingdoms[p_kingdom] = kingdoms[p_kingdom] + (self:isFriend(p) and -1 or 1)
      table.insert(kingdom_players[p_kingdom], p)
		end
	end
  local function double_first(kingodm)
    for _, name in ipairs(xiongnve_kingdom["double"]) do
      local general = sgs.Sanguosha:getGeneral(name)
			local double_kingdoms = general:getKingdoms()
      if kingdoms[double_kingdoms[1]] >= 0 and kingdoms[double_kingdoms[2]] >= 0
      and (double_kingdoms[1] == kingodm or double_kingdoms[2] == kingodm) then
        return name
      end
    end
    if #xiongnve_kingdom[kingodm] > 0 then
      return xiongnve_kingdom[kingodm][1]
    end
    return nil
  end

  if self:getCardsNum("Slash") > 1 then
    local max_slash_kingdom
    local slash_enemy
    local e_num = 0
    local slash = sgs.cloneCard("slash")
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
      if self.player:canSlash(enemy) and not self:slashProhibit(slash ,enemy) and self:slashIsEffective(slash, enemy) then
        local enemy_kingdom = enemy:getKingdom()
        if enemy_kingdom == "god" then
          enemy_kingdom = "careerist"
        end
        if kingdoms[enemy_kingdom] > e_num and double_first(enemy_kingdom) then
          max_slash_kingdom = enemy_kingdom
          slash_enemy = enemy
          e_num = kingdoms[enemy_kingdom]
        end
      end
    end
    if max_slash_kingdom then
      if self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0 then--self.player:hasSkills(sgs.force_slash_skill)
        self.xiongnve_choice = "adddamage"
      else
        self.xiongnve_choice = "nolimit"
      end
      return double_first(max_slash_kingdom)
    end
  end
	if self:getCardsNum("AOE") > 0 then
    local max_aoe_kingdom
    local e_num = 0
    local aoe = self:getCard("SavageAssault")
    if aoe and self:getAoeValue(aoe) > 0 then
      for _, enemy in ipairs(self.enemies) do
        if self:aoeIsEffective(aoe, enemy, self.player) then
          local enemy_kingdom = enemy:getKingdom()
          if enemy_kingdom == "god" then
            enemy_kingdom = "careerist"
          end
          if kingdoms[enemy_kingdom] > e_num and double_first(enemy_kingdom) then
            max_aoe_kingdom = enemy_kingdom
            e_num = kingdoms[enemy_kingdom]
          end
        end
      end
    end
    if max_aoe_kingdom then
      self.xiongnve_choice = "adddamage"
      return double_first(max_aoe_kingdom)
    end
    aoe = self:getCard("ArcheryAttack")
    if aoe and self:getAoeValue(aoe) > 0 then
      for _, enemy in ipairs(self.enemies) do
        if self:aoeIsEffective(aoe, enemy, self.player) then
          local enemy_kingdom = enemy:getKingdom()
          if enemy_kingdom == "god" then
            enemy_kingdom = "careerist"
          end
          if kingdoms[enemy_kingdom] > e_num and double_first(enemy_kingdom) then
            max_aoe_kingdom = enemy_kingdom
            e_num = kingdoms[enemy_kingdom]
          end
        end
      end
    end
    if max_aoe_kingdom then
      self.xiongnve_choice = "adddamage"
      return double_first(max_aoe_kingdom)
    end
  end
  local burningcamps = self:getCard("BurningCamps")
	if burningcamps and burningcamps:isAvailable(self.player) then
    local np_kingdom = self.player:getNextAlive():getKingdom()
	if np_kingdom == "god" then np_kingdom = "careerist" end
    if #xiongnve_kingdom[np_kingdom] > 0 then
      local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useCardBurningCamps(burningcamps, dummyuse)
			if dummyuse.card then
				self.xiongnve_choice = "adddamage"
				return xiongnve_kingdom[np_kingdom][1]
			end
    end
  end
  local duel = self:getCard("Duel")
  if duel and duel:isAvailable(self.player) then
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardDuel(duel, dummyuse)
		if not dummyuse.to:isEmpty() then
			local duel_t = dummyuse.to:first()
			if duel_t:getHp() == 1 and self:isWeak(duel_t) and #xiongnve_kingdom[duel_t:getKingdom()] > 0 then
				self.xiongnve_choice = "adddamage"
				return #xiongnve_kingdom[duel_t:getKingdom()][1]
			end
		end
	end
  return generals[math.random(1,#generals)]
end

sgs.ai_skill_choice.xiongnve = function(self, choices, data)
  choices = choices:split("+")
--"adddamage+extraction+nolimit"
  if self.xiongnve_choice then
    return self.xiongnve_choice
  end
  return choices[1]
end

sgs.ai_skill_choice.xiongnve_defence = function(self, generals)
  generals = generals:split("+")
  local xiongnve_kingdom = {["wei"] = {}, ["shu"] = {}, ["wu"] = {}, ["qun"] = {}, ["careerist"] = {}, ["double"] = {}}
	for _, name in ipairs(generals) do
		local general = sgs.Sanguosha:getGeneral(name)
		if not general:isDoubleKingdoms() then
			table.insert(xiongnve_kingdom[general:getKingdom()],name)
		else
			table.insert(xiongnve_kingdom["double"],name)
		end
	end
  local kingdoms = {wei = 0, shu = 0, wu = 0, qun = 0, careerist = 0}--计算势力的人数，正是敌人，负是队友
  for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
    if p:hasShownOneGeneral() then--非暗将
      local p_kingdom = p:getKingdom()
      if p_kingdom == "god" then
        p_kingdom = "careerist"
      end
      kingdoms[p_kingdom] = kingdoms[p_kingdom] + (self:isFriend(p) and -1 or 1)
    end
  end
  for key, value in pairs(kingdoms) do
    if value == 0 and #xiongnve_kingdom[key] > 0 then
      return xiongnve_kingdom[key][1]
    end
  end
  for key, value in pairs(kingdoms) do
    if value > 0 and #xiongnve_kingdom[key] > math.min(value*2, 5) then
      return xiongnve_kingdom[key][1]
    end
  end
  for key, value in pairs(kingdoms) do
    if value < 0 and #xiongnve_kingdom[key] > 0 then
      return xiongnve_kingdom[key][1]
    end
  end
  local kingdom
  local vtable_num = 10
  for key, value in pairs(kingdoms) do
    if #xiongnve_kingdom[key] > 0 and math.abs(value) < vtable_num then
      vtable_num = math.abs(value)
      kingdom = key
    end
  end
  if kingdom then
    --Global_room:writeToConsole("凶虐减伤选择:"..key)
    return xiongnve_kingdom[kingdom][1]
  end
  if #xiongnve_kingdom["double"] > 0 then
    for _, name in ipairs(xiongnve_kingdom["double"]) do
      local general = sgs.Sanguosha:getGeneral(name)
      local double_kingdoms = general:getKingdoms()
      if kingdoms[double_kingdoms[1]] == 0 and kingdoms[double_kingdoms[2]] == 0 then
        return name
      end
    end
    for _, name in ipairs(xiongnve_kingdom["double"]) do
      local general = sgs.Sanguosha:getGeneral(name)
      local double_kingdoms = general:getKingdoms()
      if kingdoms[double_kingdoms[1]] <= 0 and kingdoms[double_kingdoms[2]] <= 0 then
        return name
      end
    end
    return xiongnve_kingdom["double"][1]
  end

	return generals[math.random(1,#generals)]
end

function sgs.ai_cardneed.xiongnve(to, card, self)
	return card:isKindOf("Halberd")
end

--公孙渊
local huaiyi_skill = {
  name = "huaiyi",
  getTurnUseCard = function(self, inclusive)
      if self.player:hasUsed("HuaiyiCard") or self.player:isKongcheng() then
        return nil
      end
      if self.player:getPile("&disloyalty"):length() == self.player:getMaxHp() then
        return nil
      end
      if self.player:getPile("&disloyalty"):length() + 1 == self.player:getMaxHp() and math.random(1, 5) > 3 then
        return nil
      end
      local handcards = self.player:getHandcards()
      local red, black = false, false
      for _,c in sgs.qlist(handcards) do
          if c:isRed() and not red then
              red = true
              if black then
                break
              end
          elseif c:isBlack() and not black then
              black = true
              if red then
                break
              end
          end
      end
      if red and black then
        return sgs.Card_Parse("@HuaiyiCard=.&huaiyi")
      end
  end,
}
table.insert(sgs.ai_skills, huaiyi_skill)

sgs.ai_skill_use_func["HuaiyiCard"] = function(card, use, self)
  self.huaiyi_choice = nil
  local handcards = self.player:getHandcards()
  local reds, blacks = {}, {}
  local red_value, black_value = 0, 0
  for _,c in sgs.qlist(handcards) do
      local dummy_use = { isDummy = true }
      if c:isKindOf("Peach") then
        self:useBasicCard(c, dummy_use)
      elseif c:isKindOf("Snatch") then
          self:useTrickCard(c, dummy_use)
  --[[
      elseif c:isKindOf("EquipCard") and not self:getSameEquip(c) then
          self:useEquipCard(c, dummy_use)
      ]]
      end
      if dummy_use.card then
        return --It seems that self.player should use this card first.
      end
      if c:isRed() then
        red_value = red_value + self:getUseValue(c)
        table.insert(reds, c)
      else
        black_value = black_value + self:getUseValue(c)
        table.insert(blacks, c)
      end
  end

  local targets = self:findPlayerToDiscard("he", false, sgs.Card_MethodGet, nil, true)
  local n_reds, n_blacks, n_targets = #reds, #blacks, #targets
  if n_targets == 0 then
    return
  end
  if n_reds > n_targets and n_blacks > n_targets then
    local min_num = math.min(n_reds, n_blacks)
    if self:getOverflow() - min_num + n_targets < 0 then
      return
    end
  end

  if n_reds > n_targets and n_blacks > n_targets then
    self.huaiyi_choice = n_reds < n_blacks and "red" or "black"
  elseif n_reds > n_targets and math.abs(n_blacks - n_targets) < 2 then
    self.huaiyi_choice = "black"
  elseif n_blacks > n_targets and math.abs(n_reds - n_targets) < 2 then
    self.huaiyi_choice = "red"
  elseif self.player:getLostHp() < 2 then
    self.huaiyi_choice = n_reds > n_blacks and "red" or "black"
  else
    self.huaiyi_choice = red_value < black_value and "red" or "black"
  end
  use.card = card
end

sgs.ai_use_priority.HuaiyiCard = 4.2

sgs.ai_skill_choice["huaiyi"] = function(self, choices, data)
  if self.huaiyi_choice then
    return self.huaiyi_choice
  end
  choices = choices:split("+")
  return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen["huaiyi_snatch"] = function(self, targets, max_num, min_num)
  --Global_room:writeToConsole("怀异最大目标:"..max_num)
  local result = {}
  local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "handcard")
  for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and target:hasShownSkills(sgs.cardneed_skill)
    and #result < max_num and not table.contains(result, target) then
      table.insert(result, target)
    end
	end
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and #result < max_num and not table.contains(result, target) then
      table.insert(result, target)
    end
	end
  for _, target in ipairs(targetlist) do
		if not self.player:isFriendWith(target) and #result < max_num and not table.contains(result, target) then
      table.insert(result, target)
    end
	end
  Global_room:writeToConsole("怀异预定目标数:"..#result)
  return result
end

sgs.ai_skill_cardchosen.huaiyi = function(self, who, flags, method, disable_list)
  local flag_str
  if self.player:getPile("&disloyalty"):length() + 1 == self.player:getMaxHp() then
    flag_str = "h"
  elseif self.player:getPile("&disloyalty"):length() + 2 == self.player:getMaxHp() and math.random(1, 5) > 2  then
    flag_str = "h"
  elseif math.random(1, 5) > 4 then
    flag_str = "h"
  else
    flag_str = "he"
  end
  if flag_str == "he" then--藏君主装备
    for _, equip in sgs.qlist(who:getEquips()) do
      if equip:isKindOf("LuminousPearl") then
        local lord = self.room:getLord("wu")
        if lord and self:isEnemy(lord) then
          return equip:getEffectiveId()
        end
      elseif equip:isKindOf("DragonPhoenix") then
        local lord = self.room:getLord("shu")
        if lord and self:isEnemy(lord) then
          return equip:getEffectiveId()
        end
      elseif equip:isKindOf("PeaceSpell") then
        local lord = self.room:getLord("qun")
        if lord and self:isEnemy(lord) then
          return equip:getEffectiveId()
        end
      elseif equip:isKindOf("SixDragons") then
        local lord = self.room:getLord("wei")
        if lord and self:isEnemy(lord) then
          return equip:getEffectiveId()
        end
      end
    end
  end
	return self:askForCardChosen(who, flag_str, "huaiyi_snatch", method, disable_list)
end

sgs.ai_skill_invoke.zisui = true

--许攸
sgs.ai_skill_invoke.shicai = function(self, data)
  local damage = data:toDamage()
	return damage.damage < 2
end

sgs.ai_skill_invoke.chenglve = true

sgs.ai_skill_playerchosen.chenglve_mark = function(self, targets)
  local target_list = sgs.QList2Table(targets)
  self:sort(target_list, "hp")
	for _,p in ipairs(target_list) do
		if self:getOverflow(p) > 1 then
				return p
		end
	end
  self:sort(target_list, "handcard", true)
	return target_list[1]
end

--夏侯霸
sgs.ai_skill_invoke.baolie = function(self, data)
	if not self:willShowForAttack() then
    return false
  end
  --非常粗糙的条件？
	return self:getCardsNum("Slash") > 2 or self:getCardsNum("Jink") > 1
end

function sgs.ai_cardneed.baolie(to, card, self)
  if to:getHp() <= 2 then
    return card:isKindOf("Slash") or card:isKindOf("Analeptic") or to:hasWeapon("Spear")
  end
	return card:isKindOf("Halberd")--方天画戟
end

--潘濬
sgs.ai_skill_invoke.congcha = true

sgs.ai_skill_playerchosen.congcha = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_invoke.gongqing = function(self, data)
  local damage = data:toDamage()
  if not damage.from or damage.from:getAttackRange() > 3 then
    return false
  end
  if damage.from:getAttackRange() < 3 and damage.damage > 1 then
    return true
  end
	return false
end

--文钦
local jinfa_skill = {}
jinfa_skill.name = "jinfa"
table.insert(sgs.ai_skills, jinfa_skill)
jinfa_skill.getTurnUseCard = function(self)
  if self.player:hasUsed("JinfaCard") then return end
  if self.player:isNude() then return end

  local equipcard
  if self:needToThrowArmor() then
		equipcard = self.player:getArmor()
  end
  if not equipcard and self.player:hasSkills(sgs.lose_equip_skill) and self.player:hasEquip() then
    local equip = self.player:getCards("e")
    equip = sgs.QList2Table(equip)
    self:sortByUseValue(equip, true)
    equipcard = equip[1]
  end
  if equipcard then
    return sgs.Card_Parse("@JinfaCard=" .. equipcard:getEffectiveId() .."&jinfa")
  end

  local cards = self.player:getCards("he")
  cards = sgs.QList2Table(cards)
  self:sortByUseValue(cards, true)
  return sgs.Card_Parse("@JinfaCard=" .. cards[1]:getEffectiveId() .."&jinfa")
end

sgs.ai_skill_use_func.JinfaCard = function(card, use, self)
  local target
  for _, friend in ipairs(self.friends_noself) do
    if self:needToThrowArmor(friend) then
      target = friend
    end
  end
  if not target then
    for _, friend in ipairs(self.friends_noself) do
      if friend:hasSkills(sgs.lose_equip_skill) and (friend:getWeapon() or friend:getOffensiveHorse()) and self:isWeak(friend) then
        target = friend
      end
    end
  end
  if not target then
    local targets = self:findPlayerToDiscard("he", false, sgs.Card_MethodGet, nil, true)
    self:sort(targets, "hp")
    for _, p in ipairs(targets) do
      if not self:isFriend(p) then
        target = p
        break
      end
    end
  end
	if target then
    use.card = card
		if use.to then
			use.to:append(target)
    end
  end
end

sgs.ai_use_priority.JinfaCard = 4.2--顺之后

sgs.ai_card_intention.JinfaCard = function(self, card, from, tos)
	local to = tos[1]
	if to:objectName() == from:objectName() then return end
	if self:isFriend(to) then
    sgs.updateIntention(from, to, -60)
	else
		sgs.updateIntention(from, to, 60)
	end
end

sgs.ai_skill_exchange["_jinfa"] = function(self,pattern,max_num,min_num,expand_pile)
  if self:getCardsNum("EquipCard") == 0 then
    return {}
  end
  local wenqin = sgs.findPlayerByShownSkillName("jinfa")
  if self:isFriend(wenqin) then
    return {}
  end
  local equipcard
  if self:needToThrowArmor() then
		equipcard = self.player:getArmor()
  end
  if not equipcard and self.player:hasSkills(sgs.lose_equip_skill) and self.player:hasEquip() then
    local equip = self.player:getCards("e")
    equip = sgs.QList2Table(equip)
    self:sortByUseValue(equip, true)
    equipcard = equip[1]
  end
  if not equipcard then
    local cards = self.player:getCards("he")-- 获得所有牌
    cards=sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    if not self:isFriend(wenqin) then
      for _, c in ipairs(cards) do
        if c:isKindOf("EquipCard") and c:getSuit() == sgs.Card_Spade then
          equipcard = c
          break
        end
      end
    end
    if not equipcard and cards[1]:isKindOf("EquipCard") then
      equipcard = cards[1]
    end
  end
  if equipcard then
    return equipcard:getEffectiveId()
  end
  return {}
end

--彭羕
sgs.ai_skill_invoke.tongling = true

sgs.ai_skill_playerchosen.tongling = function(self, targets, data)
	--type(data)="number"
	--Global_room:writeToConsole("tongling:"..tostring(type(data))..":"..tostring(data))
	--tongling:1
	--player->tag["tongling-damage"] = data;
	
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard", true)
	
	local damage = self.player:getTag("tongling-damage"):toDamage()
	local target = damage.to
	local friend = nil
	--杀,决斗,AOE,火烧,火攻
	for _, p in ipairs(targets) do
		if target and not self:canAttack(target,p) then continue end
		if p:objectName() ~= self.player:objectName() then
			local slash = sgs.cloneCard("slash")
			if getCardsNum("Slash", p, self.player) > 0 and self:slashIsEffective(slash, target)
				and p:canSlash(target, nil, true) and not self:slashProhibit(nil, target) and self:canHit(target, p) then 
				friend = p 
				break
			end
			if getCardsNum("Duel", p, self.player) > 0 then
			elseif getCardsNum("ArcheryAttack", p, self.player) > 0 then
			elseif getCardsNum("SavageAssault", p, self.player) > 0 then
			elseif getCardsNum("BurningCamps", p, self.player) > 0 then
			elseif getCardsNum("FireAttack", p, self.player) > 0 then
			end
		else
			local slashes = self:getCards("Slash")
			for _, slash in ipairs(slashes) do
				if self:slashIsEffective(slash, target) and p:canSlash(target, slash, true) and not self:slashProhibit(slash, target) and self:canHit(target, p) then 
					friend = p 
					break
				end
			end
			if friend then break end
			if self:getCardsNum({"Duel", "ArcheryAttack", "SavageAssault", "BurningCamps", "FireAttack"}) > 0 then 
				friend = p 
				break
			end
		end
	end
	--[[
	local duel = sgs.cloneCard("duel")
	local dummy_use = { isDummy = true }
	self:useTrickCard(duel, dummy_use)
	if dummy_use.card then end
	--]]
	if friend then return friend end
	return nil
end

sgs.ai_skill_use["@@tongling_usecard"] = function(self, data, method)
	--@tongling-usecard::sgs2
	if type(data) ~= "string" then return "." end
	local prompt = tostring(data):split(":")
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() == prompt[3] then
			target = p
			break
		end
	end
	Global_room:writeToConsole("通令目标:"..sgs.Sanguosha:translate(string.format("SEAT(%s)",target:getSeat())))
	--local target = self.player:getTag("tongling-damage"):toDamage().to
	if target and self:damageIsEffective(target, nil, self.player) then
		local cards = self.player:getCards("h")
		for _, id in sgs.qlist(self.player:getHandPile()) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards)

		for _, card in ipairs(cards) do
			--杀,决斗,AOE,火烧,火攻
			if self.player:isProhibited(target, card) then continue end
			if not card:targetFilter(sgs.PlayerList(), target, self.player) then continue end--targetFixed
			local dummy_use = { isDummy = true, current_targets = {}}--local dummy_use = { isDummy = true, to = sgs.SPlayerList()}
			table.insert(dummy_use.current_targets, target:objectName())
			if not card:targetFixed() then
				dummy_use.to = sgs.SPlayerList()
				--dummy_use.to:append(target)
			end
			if card:isKindOf("Slash") then
			elseif card:isKindOf("Duel") then
			elseif card:isKindOf("FireAttack") then
			elseif card:isKindOf("SavageAssault") then
				if self:getAoeValue(card) <= 0 or getCardsNum("Slash", target, self.player) > 0 then continue end
			elseif card:isKindOf("ArcheryAttack") then
				if self:getAoeValue(card) <= 0 or getCardsNum("Jink", target, self.player) > 0 or self:hasEightDiagramEffect(target) then continue end
			elseif card:isKindOf("BurningCamps") then
				local next_targets = self.room:nextPlayer(self.player):getFormation()
				if not next_targets:contains(target) then continue end
			else continue end
			local type = card:getTypeId()
			self["use" .. sgs.ai_type_name[type + 1]](self, card, dummy_use)
			if dummy_use.card and not card:isKindOf("Analeptic") then--详细考虑？
				Global_room:writeToConsole("通令考虑牌:"..card:objectName())
				if not card:targetFixed() then
					if dummy_use.to and not dummy_use.to:isEmpty() and dummy_use.to:contains(target) then
						local target_objectname = {}
						for _, p in sgs.qlist(dummy_use.to) do
							table.insert(target_objectname, p:objectName())
						end
						return card:toString() .."->" .. table.concat(target_objectname, "+")
					else
						Global_room:writeToConsole("通令不想选原目标:"..card:objectName())
						return "."
					end
				end
				return card:toString()--"@YuancongUseCard=".. card:getEffectiveId()--正确写法？？
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.jinxian = function(self, data)
	local value = 0
	for _, p in sgs.qlist(self.player:getAliveSiblings()) do
		if p:hasShownAllGenerals() or self.player:distanceTo(p) >= 2 then continue end
		if self:doNotDiscard(p, "he") then
			if self:isFriend(p) then 
				value = value + 1
			else
				value = value - 2
			end
		else
			if self:isFriend(p) then 
				value = value - math.min(p:getCardCount(true), 2)
			else
				value = value + math.min(p:getCardCount(true), 2)
			end
		end
	end
	return value > 0
end
sgs.ai_skill_choice.jinxian_hide = function(self, choices, data)
	choices = choices:split("+")
	local value = 0
	if #choices == 1 then return choices[1] end
	if self.player:hasSkill("jinxian") then
		for _, p in sgs.qlist(self.player:getAliveSiblings()) do
			if p:hasShownAllGenerals() or self.player:distanceTo(p) >= 2 then continue end
			if self:doNotDiscard(p, "he") then
				if self:isFriend(p) then 
					value = value + 1
				else
					value = value - 2
				end
			else
				if self:isFriend(p) then 
					value = value - math.min(p:getCardCount(true), 2)
				else
					value = value + math.min(p:getCardCount(true), 2)
				end
			end
		end
		--有价值时,考虑连续触发
		if value >= 0 and table.contains(choices, "head") and self.player:inHeadSkills("jinxian") then return "head" end
		if value >= 0 and table.contains(choices, "deputy") and self.player:inDeputySkills("jinxian") then return "deputy" end
		if value < -1 and table.contains(choices, "head") and self.player:inDeputySkills("jinxian") then return "head" end
		if value < -1 and table.contains(choices, "deputy") and self.player:inHeadSkills("jinxian") then return "deputy" end
	end
	--役鬼不屈等技能,暗置选择……
	return choices[1]
end

--[[
sgs.ai_skill_cardask["@daming"] = function(self, data, pattern, target, target2)
  local friend = self.room:getCurrent()
	local cards = self.player:getCards("h")
  cards=sgs.QList2Table(cards)
  self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and
    ((not card:isKindOf("BefriendAttacking") and not card:isKindOf("AllianceFeast"))
      or self:isWeak(friend) or self.player:hasSkill("lirang")) then
			  return card:toString()
		end
	end
	return "."
end

--ai铁索连环是defence筛选，是否考虑尽可能多摸牌？
sgs.ai_skill_playerchosen["daming_chain"] = function(self, targets)
  local target_list = sgs.QList2Table(targets)
  self:sort(target_list, "hp")
	for _,p in ipairs(target_list) do
		if not self:isFriend(p) then
				return p
		end
	end
  target_list = sgs.reverse(target_list)
	return target_list[1]
end

sgs.ai_skill_choice.daming = function(self, choices, data)
  choices = choices:split("+")
  local friend = self.room:getCurrent()
  if friend:getHp() > 2 and table.contains(choices, "slash") then
    if table.contains(choices, "peach") then
      local target = sgs.ai_skill_playerchosen["daming_slash"](self, self.room:getOtherPlayers(self.player))
      local tslash = sgs.cloneCard("thunder_slash")
      if self:isFriend(target) or self:slashProhibit(tslash ,target) then--检测用杀是否合适
        return "peach"
      end
    end
    return "slash"
  end
  if table.contains(choices, "peach") then
    return "peach"
  end
  return choices[1]
end

sgs.ai_skill_playerchosen["daming_slash"] = function(self, targets)--复制的zero_card_as_slash，改为雷杀
  local tslash = sgs.cloneCard("thunder_slash")
  local targetlist = sgs.QList2Table(targets)
	local arrBestHp, canAvoidSlash, forbidden = {}, {}, {}
	self:sort(targetlist, "defenseSlash")

	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and not self:slashProhibit(tslash ,target) and sgs.isGoodTarget(target, targetlist, self) then
			if self:slashIsEffective(tslash, target) then
				if self:needDamagedEffects(target, self.player, true) or self:needLeiji(target, self.player) then
					table.insert(forbidden, target)
				elseif self:needToLoseHp(target, self.player, true, true) then
					table.insert(arrBestHp, target)
				else
					return target
				end
			else
				table.insert(canAvoidSlash, target)
			end
		end
	end
	for i=#targetlist, 1, -1 do
		local target = targetlist[i]
		if not self:slashProhibit(tslash, target) then
			if self:slashIsEffective(tslash, target) then
				if self:isFriend(target) and (self:needToLoseHp(target, self.player, true, true)
					or self:needDamagedEffects(target, self.player, true) or self:needLeiji(target, self.player)) then
						return target
				end
			else
				table.insert(canAvoidSlash, target)
			end
		end
	end

	if #canAvoidSlash > 0 then return canAvoidSlash[1] end
	if #arrBestHp > 0 then return arrBestHp[1] end

	targetlist = sgs.reverse(targetlist)
	for _, target in ipairs(targetlist) do
		if target:objectName() ~= self.player:objectName() and not self:isFriend(target) and not table.contains(forbidden, target) then
			return target
		end
	end

	return targetlist[1]
end

function sgs.ai_cardneed.daming(to, card, self)
	return card:getTypeId() == sgs.Card_TypeTrick and self:getUseValue(card) < sgs.ai_use_value.Peach
end

sgs.ai_skill_invoke.xiaoni = function(self, data)
	if not self:willShowForAttack() then
    return false
  end
  local use = data:toCardUse()
	return use.from:objectName() == self.player:objectName()
end

sgs.daming_keep_value = {
	Peach       = 6,
	Analeptic   = 5.6,
	Jink        = 5.7,
	ExNihilo    = 5.7,
	Snatch      = 5.7,
	Dismantlement = 5.6,
	IronChain   = 5.5,
	SavageAssault = 5.4,
	Duel        = 5.3,
	ArcheryAttack = 5.2,
	AmazingGrace = 4.5,
	GodSalvation = 4.5,
	Collateral  = 4.5,
	FireAttack  = 4.6,
	AwaitExhausted = 5,
	BefriendAttacking = 5.8,
	FightTogether = 5.6,
	BurningCamps = 5.6,
	AllianceFeast = 6,
  LureTiger = 4.5,
  KnownBoth = 4.6,
  Indulgence = 5.6,
  SupplyShortage = 5.3,
}
--]]
--苏飞
sgs.ai_skill_playerchosen.lianpian = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in ipairs(targets) do
		if p:getHandcardNum() < p:getMaxHp() then
			return p
		end
	end
	return nil
end

sgs.ai_skill_choice.lianpian = function(self, choices, data)
  local sufei = sgs.findPlayerByShownSkillName("lianpian")
  if self:isFriend(sufei) then
    return "recover"
  else
    return "discard"
  end
	return "cancel"
end

--诸葛恪
function sgs.ai_cardsview_priority.aocai(self, class_name, player)
  if self.player:objectName() ~= player:objectName() or not player:hasSkill("aocai") then return end
	if player:hasFlag("Global_AocaiFailed") or player:getPhase() ~= sgs.Player_NotActive then return end
  if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
  or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
    if class_name == "Slash" or class_name == "Jink" then
      local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
      if pattern and pattern == "slash" or pattern == "jink" then
        local card = "@AocaiCard=.&aocai:" .. pattern
        Global_room:writeToConsole("傲才响应:" .. card)
        return card
      end
    end
  end
	if class_name == "Peach" or class_name == "Analeptic" then
		local dying = self.room:getCurrentDyingPlayer()
        if dying and dying:objectName() == player:objectName() then
            return "@AocaiCard=.&aocai:peach+analeptic"
        else
            local user_string
            if class_name == "Analeptic" then user_string = "analeptic" else user_string = "peach" end
            return "@AocaiCard=.&aocai:" .. user_string
        end
	end
end

sgs.ai_use_priority.AocaiCard = 20

sgs.ai_skill_cardask["@aocai-view"] = function(self, data, pattern, target, target2)
	--Global_room:writeToConsole("进入傲才:" .. self.player:objectName())
	if self.player:property("aocai"):toString() == "" then
		Global_room:writeToConsole("傲才结果:.")
		return "."
	end
	local aocai_list = self.player:property("aocai"):toString():split("+")
	for _, id in ipairs(aocai_list) do
    local num_id = tonumber(id)
		Global_room:writeToConsole("傲才结果:" .. num_id)
    return "$" .. num_id
  end
end

local duwu_skill = {}
duwu_skill.name = "duwu"
table.insert(sgs.ai_skills, duwu_skill)
duwu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@duwu") < 1 then return end
  return sgs.Card_Parse("@DuwuCard=.&duwu")
end

sgs.ai_skill_use_func.DuwuCard= function(card, use, self)
  local num_nofriednwith, num_enermy = 0 ,0
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    if self.player:inMyAttackRange(p) and self:damageIsEffective(p, nil, self.player) then
      if not self.player:isFriendWith(p) then
        num_nofriednwith = num_nofriednwith + 1
      end
      if not self:isFriend(p) then
        num_enermy = num_enermy + 1
      end
    end
  end
  if ((self.player:getWeapon() and sgs.weapon_range[self.player:getWeapon():getClassName()] > 2) or num_enermy > 2)
  and (self.player:getMark("Global_TurnCount") > 1 or string.find(sgs.gameProcess(), ">>>")) then--防止开局就使用
    use.card = card
  end
	if self.player:getHp() == 1 and num_nofriednwith > 1 then
    use.card = card
  end
end

sgs.ai_card_intention.DuwuCard = 80
sgs.ai_use_priority.DuwuCard= 3.6

sgs.ai_skill_choice["startcommand_duwu"] = function(self, choices)
  Global_room:writeToConsole(choices)
  choices = choices:split("+")
  local commands = {"command2", "command3", "command4", "command1", "command6", "command5"}--索引大小代表优先级，注意不是原顺序
  local command_value1 = table.indexOf(commands,choices[1])
  local command_value2 = table.indexOf(commands,choices[2])
  local index = math.max(command_value1,command_value2)
  --Global_room:writeToConsole("choice:".. choices[index])
  return commands[index]
end

sgs.ai_skill_choice["docommand_duwu"] = function(self, choices, data)
  local source = data:toPlayer()
  local index = self.player:getMark("command_index")
  local is_enemy = self:isEnemy(source)
  local is_friend = self:isFriend(source)

  if index == 1 then
    if not is_enemy and not is_friend then
      return "yes"
    end
    if is_friend and not self:isWeak() then
      for _, p in ipairs(self.enemies) do
        if self:isWeak(p) and self:isEnemy(source, p) then
          return "yes"
        end
      end
    end
    if is_enemy then
      for _, p in ipairs(self.friends) do
        if self:isWeak(p) and self:isEnemy(source, p) then
          return "no"
        end
      end
      return "yes"
    end
  end
  if index == 2 then
    return "yes"
  end
  if index == 3 and is_enemy then
    return "yes"
  end
  if index == 4 then
    if self.player:getMark("command4_effect") > 0 then
      return "yes"
    end
    if not is_friend and self:slashIsAvailable(source) then
      local has_peach = false
      for _, c in sgs.qlist(self.player:getHandcards()) do
        if isCard("Peach", c, self.player) then--有实体卡桃可回血
          has_peach = true
        end
      end
      if has_peach then
        for _, p in ipairs(self.friends) do
          if p:getHp() == 1 and self:isWeak(p) and source:canSlash(self.player, nil, true) then
            return "no"
          end
        end
      end
    end
    return "yes"
  end
  if index == 5 and not self.player:faceUp() then
    return "yes"
  end
  if index == 6 and is_enemy and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 then
    return "yes"
  end
  return "no"
end

sgs.ai_skill_playerchosen["command_duwu"] = sgs.ai_skill_playerchosen.damage

function sgs.ai_cardneed.duwu(to, card, self)
	return card:isKindOf("Weapon") and sgs.weapon_range[card:getClassName()] >=3
end

--黄祖
sgs.ai_skill_cardask["@xishe-slash"] = function(self, data, pattern, target, target2)
  if not self.player:hasEquip() or not target or target:isDead() then
    return "."
  end
  if not self:slashIsEffective(sgs.cloneCard("slash"), target, self.player) then
		return "."
	end
  if not self:isFriend(target) then
    if self.player:hasSkill("kuangfu") and self.player:getHp() > target:getHp() and target:hasEquip() then--配合潘凤
      local card_id
      if self.player:getWeapon() and target:getWeapon() then
        card_id = self.player:getWeapon():getId()
      elseif self.player:getOffensiveHorse() and target:getOffensiveHorse() then
        card_id = self.player:getOffensiveHorse():getId()
      elseif self.player:getArmor() and target:getArmor() then
        card_id = self.player:getArmor():getId()
      elseif self.player:getDefensiveHorse() and target:getDefensiveHorse() then
        card_id = self.player:getDefensiveHorse():getId()
      elseif self.player:getTreasure() and target:getTreasure() then
        card_id = self.player:getTreasure():getEffectiveId()
      end
      if card_id then return "$" .. card_id end
    end
    if (self.player:getHp() > target:getHp() or self:isWeak()) and self:needToThrowArmor() then
      return "$" .. self.player:getArmor():getEffectiveId()
    end
    local equipcards = self.player:getCards("e")
    equipcards = sgs.QList2Table(equipcards)
    if (target:getHp() == 1 and self:isWeak(target)) or (self.player:getHp() > target:getHp() and (target:getHp() < 3 or self:getCardsNum("EquipCard") > 2)) then
      if self:needToThrowArmor() then
        return "$" .. self.player:getArmor():getEffectiveId()
      end
      self:sortByKeepValue(equipcards)
      return "$" .. equipcards[1]:getEffectiveId()
    end
  end
	return "."
end

sgs.ai_skill_choice["transform_xishe"] = function(self, choices)
	Global_room:writeToConsole("袭射变更选择")
	local importantsklii = {"congjian", "jijiu", "qianhuan", "yigui", "shicai", "jinghe"}--还有哪些？
	local skills = sgs.QList2Table(self.player:getDeputySkillList(true,true,false))
	for _, skill in ipairs(skills) do
		if table.contains(importantsklii, skill:objectName()) then--重要技能
			return "no"
		end
		if skill:getFrequency() == sgs.Skill_Limited and not (skill:getLimitMark() ~= "" and self.player:getMark(skill:getLimitMark()) == 0) then--限定技未发动
			return "no"
		end
	end
  --[[
	choices = choices:split("+")
	return choices[math.random(1,#choices)]
  ]]
  return "yes"
end

sgs.ai_cardneed.xishe = sgs.ai_cardneed.equip

--刘巴
sgs.ai_skill_invoke.tongdu = true

sgs.ai_skill_choice.tongdu = "yes"

local qingyin_skill = {}
qingyin_skill.name = "qingyin"
table.insert(sgs.ai_skills, qingyin_skill)
qingyin_skill.getTurnUseCard = function(self)
	if self.player:getMark("@qingyin") < 1 or self:getAllPeachNum() > 3 then return end
	--Global_room:writeToConsole("进入刘巴技能:" .. self.player:objectName())
	local count = 0
	for _, friend in ipairs(self.friends) do
		if self.player:isFriendWith(friend) and friend:canRecover() then
			if self:isWeak(friend) and friend:getLostHp() > 1 and friend:getHandcardNum() < 2 then
				count = count + 1
			end
		end
	end
	--Global_room:writeToConsole("计数:"..count)
	if count > 1 or (self.player:getHp() == 1 and self:isWeak() and self:getAllPeachNum() < 1) then
		return sgs.Card_Parse("@QingyinCard=.&qingyin")
	end
end

sgs.ai_skill_use_func.QingyinCard = function(card, use, self)
  --Global_room:writeToConsole("使用刘巴技能")
	use.card = card
end

sgs.ai_card_intention.QingyinCard = -80
sgs.ai_use_priority.QingyinCard = 1--桃之前

--朱灵
sgs.ai_skill_invoke.juejue = function(self, data)--暂不考虑紫砂
	if not self:willShowForAttack() then
    return false
  end
  local friend_weak = 0
  local enemy_weak = 0
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    if self:isFriend(p) and self:isWeak(p) then
      friend_weak = friend_weak + 1
    end
    if not self:isFriend(p) and self:isWeak(p) then
      enemy_weak = enemy_weak + 1
    end
  end
  if self:getOverflow() > (self.player:getMark("@halfmaxhp") < 1 and 1 or 3) and self.player:getHp() > 1 then
    if enemy_weak > 2 or enemy_weak > friend_weak  then
      return true
    end
    if (self.player:getHp() > 2 or self.player:hasSkill("wangxi")) and self:getCardsNum("Peach") > 0 and (#self.enemies > 2 or #self.enemies > #self.friends) then
      return true
    end
  end
	return false
end

sgs.ai_skill_cardask["@juejue-discard"] = function(self, data, pattern, target, target2)
  local dis_num = self.player:getMark("juejue_discard_count")
	if self.player:getHandcardNum() < dis_num then--缺手牌
    return "."
  end
  local current = self.room:getCurrent()--万一绝决过程中朱灵死了，是否会空值？
  if not self:damageIsEffective(self.player, nil, current) or self:needDamagedEffects(self.player, current) or self:needToLoseHp(self.player, current) then
    return "."
  end
  if self.player:getHp() > 2 or self:getCardsNum("Peach") > 0
  or (self.player:getHp() == 1 and self:getCardsNum("Analeptic") > 0)
  or (dis_num > 3 and not self:isWeak()) then
    return "."
  end
  local cards = self.player:getHandcards() -- 获得所有手牌
  cards=sgs.QList2Table(cards) -- 将列表转换为表
  local discards = {}
  self:sortByKeepValue(cards) -- 按保留值排序
  for _, c in ipairs(cards) do
    table.insert(discards, c:getId())
    if #discards == dis_num then
      return "$" .. table.concat(discards, "+")
    end
  end
  return "."
end

sgs.ai_skill_invoke.fangyuan = true

sgs.ai_skill_playerchosen["_fangyuan"] = function(self, targets)
  if self:isFriend(targets:first()) then
    return {}
  end
  return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

--诏书
sgs.ai_use_priority.ImperialEdict = 9
sgs.ai_keep_value.ImperialEdict = 4

local imperialedicttrick_skill = {}
imperialedicttrick_skill.name = "imperialedicttrick"
table.insert(sgs.ai_skills, imperialedicttrick_skill)
imperialedicttrick_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("ImperialEdictTrickCard") then
		return
	end
  local suits = {}
  for _, id in sgs.qlist(self.player:getPile("ImperialEdict")) do
    local card = sgs.Sanguosha:getCard(id)
    if not card:isKindOf("ImperialEdict") then
      local suit = card:getSuitString()
      if not table.contains(suits, suit) then
        table.insert(suits, suit)
      end
    end
  end
  if #suits == 4 then
    return sgs.Card_Parse("@ImperialEdictTrickCard=.&")
  end
end

sgs.ai_skill_use_func.ImperialEdictTrickCard = function(card, use, self)
  use.card = card
end

sgs.ai_use_priority.ImperialEdictTrickCard = 2

local imperialedictattach_skill = {}
imperialedictattach_skill.name = "imperialedictattach"
table.insert(sgs.ai_skills, imperialedictattach_skill)
imperialedictattach_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("ImperialEdictAttachCard") then
		return sgs.Card_Parse("@ImperialEdictAttachCard=.&")
	end
end

sgs.ai_skill_use_func.ImperialEdictAttachCard = function(card, use, self)
  sgs.ai_use_priority.ImperialEdictAttachCard = 0.2
  local attach_cards = {}
  local attach_num = 1
  if not self.player:isBigKingdomPlayer() then
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
      if p:isBigKingdomPlayer() then
        attach_num = 2
        break
      end
    end
  end
  local suits = {"heart", "diamond", "spade", "club"}
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    if not p:getPile("ImperialEdict"):isEmpty() and self.player:isFriendWith(p) then
      for _,id in sgs.qlist(p:getPile("ImperialEdict")) do
        local c = sgs.Sanguosha:getCard(id)
        if not c:isKindOf("ImperialEdict") then
          table.removeOne(suits, c:getSuitString())
        end
      end
    end
  end
  if #suits == 0 then
    return
  end
  local hcards = sgs.QList2Table(self.player:getHandcards())
  self:sortByUseValue(hcards, true)
--[[self:sortByKeepValue(hcards)
  for _, hc in ipairs(hcards) do
    local dummy_use = { isDummy = true }
    if hc:isKindOf("BasicCard") then
      self:useBasicCard(hc, dummy_use)
    elseif hc:isKindOf("EquipCard") then
      self:useEquipCard(hc, dummy_use)
    elseif hc:isKindOf("TrickCard") then
      self:useTrickCard(hc, dummy_use)
    end
    if dummy_use.card then
      return--先用光牌
    end
  end]]
  local limit = self:getOverflow(self.player, true)
  local peach_num = self:getCardsNum("Peach")
  local analeptic_num = self:getCardsNum("Analeptic")
  local jink_num = self:getCardsNum("Jink")

  local function can_attach(hcard)
    if peach_num + analeptic_num + jink_num <= limit and limit < 3
    and (isCard("Peach", hcard, self.player) or isCard("Analeptic", hcard, self.player) or isCard("Jink", hcard, self.player)) then
      return false
    end
    return true
  end

  for _, hc in ipairs(hcards) do
    if table.contains(suits, hc:getSuitString()) and #attach_cards < attach_num and can_attach(hc) then
      local dummyuse = { isDummy = true }
      self:useCardByClassName(hc, dummyuse)
      if not dummyuse.card then
        table.removeOne(suits, hc:getSuitString())
        table.insert(attach_cards, hc:getEffectiveId())
      end
    end
  end
  if #attach_cards > 0 then
    if #suits == #attach_cards and not self.player:getPile("ImperialEdict"):isEmpty() then--自己回合可以获取锦囊
      sgs.ai_use_priority.ImperialEdictAttachCard = 5
    end
    use.card = sgs.Card_Parse("@ImperialEdictAttachCard=" .. table.concat(attach_cards, "+"))
  end
end

sgs.ai_skill_choice["trick_show"] = function(self, choices)
	choices = choices:split("+")
	return choices[math.random(1, #choices-1)]--不取消
end

--号令天下
function SmartAI:useCardRuleTheWorld(card, use)
  if #self.enemies == 0 then return end
  local min_hp = 99
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    if p:getHp() < min_hp then
      min_hp = p:getHp()
    end
  end
  self:sort(self.enemies, "hp")
  for _, enemy in ipairs(self.enemies) do
    if enemy:getHp() > min_hp and self:trickIsEffective(card, enemy) and enemy:hasShownSkills(sgs.priority_skill)
    and self:slashIsEffective(sgs.cloneCard("slash"), enemy) then
      use.card = card
      if use.to then use.to:append(enemy) end
      return
    end
  end
  for _, enemy in ipairs(self.enemies) do
    if enemy:getHp() > min_hp and self:trickIsEffective(card, enemy) and self:slashIsEffective(sgs.cloneCard("slash"), enemy) then
      use.card = card
      if use.to then use.to:append(enemy) end
      return
    end
  end
  for _, enemy in ipairs(self.enemies) do
    if enemy:getHp() > min_hp and self:trickIsEffective(card, enemy) then--考虑敌友方人数和杀禁止、买血？
      use.card = card
      if use.to then use.to:append(enemy) end
      return
    end
  end
end

sgs.ai_use_priority.RuleTheWorld = 4.5
sgs.ai_keep_value.RuleTheWorld = 3.5
sgs.ai_use_value.RuleTheWorld = 9
sgs.ai_card_intention.Chaos = 150

sgs.ai_skill_choice["rule_the_world"] = function(self, choices, data)
  Global_room:writeToConsole("号令天下选择:" .. choices)
  choices = choices:split("+")
--[[
    choice1.startsWith("slash")
    choice2.startsWith("discard")
  ]]
  local target = data:toPlayer()
  if self:isFriend(target) then
    return "cancel"
  elseif not self:needLeiji(target, self.player) and not self:needDamagedEffects(target, self.player, true) 
		and self:slashIsEffective(sgs.cloneCard("slash"), target, self.player) and not self.player:isKongcheng() then
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    if not self:isWeak() or not (isCard("Peach", cards[1], self.player)
      or (isCard("Analeptic", cards[1], self.player) and self.player:getHp() == 1)) then
        Global_room:writeToConsole("号令天下杀")
        for _, choice in ipairs(choices) do
          if choice:startsWith("slash") then
            return choice
          end
        end
    end
  else
    for _, choice in ipairs(choices) do
      if choice:startsWith("discard") then
        return choice
      end
    end
  end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_discard["rule_the_world"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("dummy_reason", 1, 1, false, false)
end

sgs.ai_nullification.RuleTheWorld = function(self, card, from, to, positive, keep)
  if #(self:getEnemies(to)) > (to:getHp() > 2 and 2 or 1) then
    keep = false
  end
  if keep then return false end
	if positive then
		if self:isFriend(to) then return true, true end
	else
		if self:isEnemy(to) then return true, true end
	end
end

--克复中原
function SmartAI:useCardConquering(card, use)
  use.card = card
  if use.to then
    for _, friend in ipairs(self.friends) do
      use.to:append(friend)
    end
  end
end

sgs.ai_use_priority.Conquering = 9.25
sgs.ai_keep_value.Conquering = 3.88
sgs.ai_use_value.Conquering = 9
sgs.ai_card_intention.Conquering = -80

sgs.ai_skill_playerchosen["conquering_slash"] = function(self, targets)
  local target = sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
	if self:isFriend(target) or not self:slashIsEffective(sgs.cloneCard("slash"), target) then
  --缺势力锦囊使用者和使用卡信息hasFlag("CompleteEffect")，无法判断势力加成。蜀加成杀基数+1，暂不考虑队友
		return {}
	elseif self:needLeiji(target, self.player) or not self:slashIsEffective(sgs.cloneCard("slash"), target, self.player) then
		return {}
	end
  return target
end

sgs.ai_nullification.Conquering = function(self, card, from, to, positive, keep)
  local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. card:toString()):toList()
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
	end
  if card:hasFlag("CompleteEffect") then
    local num = 0
    for _, p in sgs.qlist(targets) do
      if p:getSeemingKingdom() == "shu" then
        num = num + 1
      end
    end
    if num > 1 then
      keep = false
    end
  end
  if keep then return false end
	if positive then
		if self:isEnemy(to) then
      local num = 0
      for _, p in sgs.qlist(targets) do
        if p:isFriendWith(to) then
          num = num + 1
        end
      end
      if num > 1 then
        if self.room:getTag("NullifyingTimes"):toInt() == 0 and self:getCard("HegNullification") then
          return true, false
        end
        if self.room:getTag("NullifyingTimes"):toInt() > 0 then
          return true, true
        end
      end
    end
	else
		if self:isFriendWith(to)
    and self.room:getTag("NullifyingTimes"):toInt() > 0 and self.room:getTag("NullificatonType"):toBool() then
      local num = 0
      for _, p in sgs.qlist(targets) do
        if p:isFriendWith(to) then
          num = num + 1
        end
      end
      if num > 1 then
        return true, true
      end
    end
	end
end

--固国安邦
function SmartAI:useCardConsolidateCountry(card, use)
  if not card:isAvailable(self.player) then return end
  use.card = card
end

sgs.ai_use_priority.ConsolidateCountry = 9.25
sgs.ai_keep_value.ConsolidateCountry = 4.3
sgs.ai_use_value.ConsolidateCountry = 10

sgs.ai_skill_exchange["consolidate_country"] = function(self,pattern,max_num,min_num,expand_pile)
  local discards = {}
  local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
  local discardEquip = false
  for _, c in ipairs(cards) do
    if #discards < min_num and sgs.Sanguosha:matchExpPattern(pattern,self.player,c) then--至少弃6，只考虑最小值
      if discardEquip and self.room:getCardPlace(c:getEffectiveId()) == sgs.Player_PlaceEquip then
      else
        table.insert(discards, c:getEffectiveId())
      end
      if self.player:hasSkills(sgs.lose_equip_skill) and not discardEquip--装备技能处理
      and self.room:getCardPlace(c:getEffectiveId()) == sgs.Player_PlaceEquip then
				discardEquip = true
			end
    end
  end
  return discards
end

sgs.ai_skill_use["@@consolidatecountrygive"] = function(self, prompt, method)
  local targets = {}
  for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:isFriendWith(p) then
			table.insert(targets, p)
		end
	end
  self:sort(targets, "handcard")

	local givecards = {}
  local str_ids = self.player:property("consolidate_country_cards"):toString():split("+")
  for _, str_id in ipairs(str_ids) do
    table.insert(givecards, sgs.Sanguosha:getCard(tonumber(str_id)))
  end
	self:sortByKeepValue(givecards,true)--暂不考虑cardneed配合

  for _, p in ipairs(targets) do
    local card_ids = {}
    local max_num = 2
    local temp_str = p:property("consolidate_country_arrange"):toString()
    if temp_str ~= "" then
      max_num = max_num - #(temp_str:split("+"))
    end
    if max_num > 0 then
      for _, c in ipairs(givecards) do
        if #card_ids < max_num then
          table.insert(card_ids, c:getEffectiveId())
        end
      end
      if #card_ids > 0 then
        return "@ConsolidateCountryGiveCard=" .. table.concat(card_ids, "+") .. "->" .. p:objectName()
      end
    end
  end
  return "."
end

sgs.ai_nullification.ConsolidateCountry = function(self, card, from, to, positive, keep)
  if card:hasFlag("CompleteEffect") then
    for _, p in ipairs(self:getFriends(from)) do
      if from:isFriendWith(p) then
        keep = false
        break
      end
    end
  end
	if keep then return false end
	if positive then
		if self:isEnemy(from) and (self:isWeak(from) or from:hasShownSkills(sgs.cardneed_skill)) then
			return true, true
		end
	else
		if self:isFriend(from) then return true, true end
	end
end

--文和乱武
function SmartAI:useCardChaos(card, use)
  for _, p in ipairs(self.enemies) do
    if not p:isKongcheng() then
      use.card = card
    end
  end
end

sgs.ai_use_priority.Chaos = 7
sgs.ai_keep_value.Chaos = 3.47
sgs.ai_use_value.Chaos = 9
sgs.ai_card_intention.Chaos = 80

sgs.ai_skill_choice.chaos = function(self, choices, data)
  Global_room:writeToConsole("文和乱武选择:" .. choices)
  choices = choices:split("+")
--[[
    QString choice1 = QString("letdiscard%to:%1").arg(effect.to->objectName());
    QString choice2 = QString("discard%to:%1").arg(effect.to->objectName());
  ]]
  local target = data:toPlayer()
  if self:isFriend(target) then
    for _, choice in ipairs(choices) do
      if choice:startsWith("discard") then
        return choice
      end
    end
  end
--[[判断我选择弃和让对方弃更优？按类型划分牌比较最有价值的牌和两类最小值之和大小；群势力加成


    ]]
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_cardask["@chaos-select"] = function(self, data, pattern, target, target2)
  if self.player:isKongcheng() then
    return "."
  end
  local selected_1, selected_2
  local hcards = self.player:getCards("h")
  hcards = sgs.QList2Table(hcards)
  if self.player:getPhase() <= sgs.Player_Play then
    self:sortByUseValue(hcards)
  else
    self:sortByKeepValue(hcards, true)
  end
  for _, c in ipairs(hcards) do
    if not self.player:isJilei(c) then
      selected_1 = c
      break
    end
  end
  if selected_1 then
    for _, c in ipairs(hcards) do
      if c:getTypeId() ~= selected_1:getTypeId() and not self.player:isJilei(c) then
        selected_2 = c
        break
      end
    end
  end
  if selected_1 and selected_2 then
    local selected_cards = {}
    table.insert(selected_cards, selected_1:getId())
    table.insert(selected_cards, selected_2:getId())
    return "$" .. table.concat(selected_cards, "+")
  elseif selected_1 then
    return "$" .. selected_1:getEffectiveId()
  elseif selected_2 then
    return "$" .. selected_2:getEffectiveId()
  end
  return "."
end

sgs.ai_nullification.Chaos = function(self, card, from, to, positive, keep)
  local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. card:toString()):toList()
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
	end
  local null_card = self:getCard("Nullification")
  if null_card and not self.player:isKongcheng() then
    local hcards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(hcards, true)
    --[[未完成，无懈可能被弃时选择


    ]]
  end
  if keep then return false end
	if positive then
		if self:isFriendWith(to)then
      local num = 0
      for _, p in sgs.qlist(targets) do
        if p:isFriendWith(to) then
          num = num + 1
        end
      end
      if num > 1 then
        if self.room:getTag("NullifyingTimes"):toInt() == 0 and self:getCard("HegNullification") then
          return true, false
        end
        if self.room:getTag("NullifyingTimes"):toInt() > 0 then
          return true, true
        end
      end
    end
	else
		if self:isEnemy(to)
    and self.room:getTag("NullifyingTimes"):toInt() > 0 and self.room:getTag("NullificatonType"):toBool() then
      local num = 0
      for _, p in sgs.qlist(targets) do
        if p:isFriendWith(to) then
          num = num + 1
        end
      end
      if num > 1 then
        return true, true
      end
    end
	end
end