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
	if not self:willShowForDefence() then
    return false
  end
  local damage = data:toDamage()
  if damage.card:isKindOf("AOE") and not self.player:hasSkill("jianxiong") then
    return true
  end
  if self.player:hasSkills(sgs.masochism_skill) and self.player:getHp() > 1 and not damage.damage > 1 then
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

--[[
  用默认的
  askForCardChosen(player, target, "he", "liangfan", false, Card::MethodGet);
]]

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
	if not self:willShowForDefence() then
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
    return true
  end
	return false
end

sgs.ai_skill_suit.midao= function(self)--无法获知使用的卡牌信息
	return math.random(0, 3)
end

sgs.ai_skill_choice.midao = function(self, choices, data)
  choices = choices:split("+")
  if table.contains(choices,"fire") then
    return "fire"
  end
  if table.contains(choices,"thunder") then
    return "thunder"
  end
  if table.contains(choices,"normal") then
    return "normal"
  end
  return choices[1]
end

sgs.ai_skill_exchange["midao"] = function(self,pattern,max_num,min_num,expand_pile)
  if self:getOverflow() < 2 or self.player:isKongcheng() then
    return {}
  end
  local cards = self.player:getCards("h")-- 获得所有手牌
  cards=sgs.QList2Table(cards) -- 将列表转换为表
  self:sortByUseValue(cards)
  return cards[1]:getEffectiveId()
end

--糜芳＆傅士仁
sgs.ai_skill_invoke.fengshix = function(self, data)
	if not self:willShowForAttack() then
    return false
  end
  local target = data:toPlayer()
  if not target or self:isFriend(target) then
    return false
  end
  if self.player:getHandcardNum() > target:getHandcardNum() and not target:isNude() then
    if self.player:getHandcardNum() > 3 or self:isWeak(target) then
      return true
    end
  end
	return false
end

--sgs.ai_skill_cardchosen.fengshix 默认ai是顺拆的策略，暂时不细化

sgs.ai_skill_choice.fengshix = function(self, choices, data)
  local use = data:toCardUse()
  if use.to:length() == 1 and not self:isFriend(use.to:first()) and (self.player:getHandcardNum() > 3 or self:isWeak(use.to:first())) then
    return "yes"
  end
	return "no"
end

--刘琦
sgs.ai_skill_playerchosen.wenji = sgs.ai_skill_playerchosen.damage

--[[
  wenji有空再详细写，wenji_give和wenji_giveback
  askForExchange(target, "_wenji", 1, 1, "@wenji-give:" + player->objectName());
]]--

sgs.ai_skill_invoke.tunjiang = true

--士燮
--[[
sgs.ai_skill_choice.lixia = function(self, choices, data)
  local shixie = self.room:findPlayerBySkillName("lixia")
  if shixie and self.isFriend(shixie) and shixie:needToThrowArmor() then
    return "yes"
  end
  if use.to:length() == 1 and not self:isFriend(use.to:first()) and (self.player:getHandcardNum() > 3 or self:isWeak(use.to:first())) then
    return "yes"
  end
	return "no"
end

sgs.ai_skill_choice[#lixia-other] = function(self, choices, data)
  local shixie = self.room:findPlayerBySkillName("lixia")
  if shixie and self.isFriend(shixie) and shixie:needToThrowArmor() then
    return "yes"
  end
  if use.to:length() == 1 and not self:isFriend(use.to:first()) and (self.player:getHandcardNum() > 3 or self:isWeak(use.to:first())) then
    return "yes"
  end
	return "no"
end
]]--两个选择重名

--董昭
local quanjin_skill = {}
quanjin_skill.name = "quanjin"
table.insert(sgs.ai_skills, quanjin_skill)
quanjin_skill.getTurnUseCard = function(self, inclusive)
  if self.player:getHandcardNum() == 0 then return end
  if not self.player:hasUsed("QuanjinCard") then
    local can_quanjin = false
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
      if p:getMark("Global_InjuredTimes_Phase") > 0 then
        can_quanjin = true
      end
    end
    if can_quanjin then
      return sgs.Card_Parse("@QuanjinCard=.&quanjin")
    end
  end
  return
end

sgs.ai_skill_use_func.QuanjinCard= function(card, use, self)
  sgs.ai_use_priority.QuanjinCard = 2.4
  local target
  local maxcard_num,maxhurt_num= 0,0
  local maxcard_hurt
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    local card_num = p:getHandcardNum()
    if card_num > maxcard_num then
      maxcard_num = card_num
    end
    if p:getMark("Global_InjuredTimes_Phase") > 0  then
      if card_num > maxhurt_num  then
        maxhurt_num = card_num
        maxcard_hurt = p
      end
    end
  end

  for _,c in sgs.qlist(self.player:getCards("h")) do
    local dummy_use = {
        isDummy = true,
    }
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
    if friend:getMark("Global_InjuredTimes_Phase") > 0  then
      weak_friend = friend
      break
    end
  end

  if card:isKindOf("Peach") or (maxcard_num >= maxhurt_num)--桃或者牌最多的不是受伤的
  or (self.player:getHandcardNum() >= maxcard_num + 2 and self.player:getHandcardNum() > 2)--自己手牌最多发牌
  or (maxcard_num >= self.player:getHandcardNum() + 3)--能摸3张
  or (weak_friend and weak_friend:getHandcardNum() + 1 >= maxhurt_num) then--队友的牌数比受伤的不少于1
    if weak_friend then
      target = weak_friend
    end
  end
  if not target and not card:isKindOf("Peach") then
    target = maxcard_hurt
  end

  if target then
    use.card =  sgs.Card_Parse(card_str)
		if use.to then
			use.to:append(target)
      local visibleflag--记录给出的手牌，盗书等技能需要
      visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end
			global_room:writeToConsole("使用劝进目标:"..target:objectName().." 其手牌数:"..target:getHandcardNum())
		end
	end
  
  if self.player:hasSkill("daoshu") then
    sgs.ai_use_priority.QuanjinCard = 2.95--盗书之前
  end
  return
end

sgs.ai_skill_choice["startcommand_quanjin"] = function(self, choices)
  self.player:speak(choices)
  choices = choices:split("+")
  local commands = {"command1", "command2", "command4", "command3", "command6", "command5"}--索引大小代表优先级，注意不是原顺序
  local command_value1 = table.indexOf(commands,choices[1])
  local command_value2 = table.indexOf(commands,choices[2])
  self.jieyue_index = math.max(command_value1,command_value2)--需要一些额外的标记？
  --global_room:writeToConsole("choice:".. choices[self.jieyue_index])
  return commands[self.jieyue_index]
end

sgs.ai_skill_choice["docommand_quanjin"] = function(self, choices, data)
  --target->setFlags("JieyueTarget");有标记可使用
  --[[if self.jieyue_index <= 4 then
    return "yes"
  end
  if self.jieyue_index == 5 then
    if self.player:getCards("he"):length() < 4 then
      return "yes"
    elseif self.player:getHp() < 3 and self:getCardsNum("Peach") == 0 and self.player:getCards("he"):length() < 6 then
      return "yes"
    else
      return "no"
    end
  end
  if self.jieyue_index == 6 then
    if not self.player:faceUp() then
      return "yes"
    elseif self.player:getHp() < 3 and self:getCardsNum("Peach") == 0 and self.player:getHandcardNum() < 3
    and math.random(1, 100) / 100 >= 50  then
      return "yes"
    else
      return "no"
    end
  end]]--
  return "no"
end

local zaoyun_skill = {}
zaoyun_skill.name = "zaoyun"
table.insert(sgs.ai_skills, zaoyun_skill)
zaoyun_skill.getTurnUseCard = function(self, inclusive)
  if self.player:getHandcardNum() == 0 then return end
  if not self.player:hasUsed("ZaoyunCard") and self.player:hasShownOneGeneral() then
    --self.player:speak("zaoyun技能卡:"..self.player:objectName())
    return sgs.Card_Parse("@ZaoyunCard=.&zaoyun")
  end
  return
end

sgs.ai_skill_use_func.ZaoyunCard= function(card, use, self)
  sgs.ai_use_priority.ZaoyunCard = 2.65--杀之前，怎么配合一技能先后？

  for _,c in sgs.qlist(self.player:getCards("h")) do
    local dummy_use = {
        isDummy = true,
    }
    if c:isKindOf("Peach") then--先吃桃
       self:useBasicCard(c, dummy_use)
    end
  end
  --self.player:speak("zaoyun函数:"..self.player:objectName())
  local target
  self:sort(self.enemies, "hp")
  for _, p in ipairs(self.enemies) do
    if p:hasShownOneGeneral() and not self.player:isFriendWith(p) and self.player:distanceTo(p) > 1 and self.player:getHandcardNum() + 1 >= self.player:distanceTo(p) then
      local nearest = 6
      if p:getHp() == 1 and self.player:getHandcardNum() > 3 then
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
      if p:hasShownOneGeneral() and not self.player:isFriendWith(p) and self.player:distanceTo(p) == 2 and self.player:getHandcardNum() > 1 then
        target = p--没有血少的则攻击距离2的
      end
    end
  end
  --assert(target)
  if target then
    --self.player:speak("zaoyun目标:"..target:objectName())
  	local card_list = {}
    local need_num = self.player:distanceTo(target) - 1
    local handcards = self.player:getCards("h")
    handcards = sgs.QList2Table(handcards)
    self:sortByKeepValue(handcards)
    for _,c in ipairs(handcards) do
      if not c:isKindOf("Peach")  then
        table.insert(card_list, c:getEffectiveId())
      end
      if #card_list == need_num then
        break
      end
    end
    assert(#card_list)
    if #card_list == need_num then
      local card_str = ("@ZaoyunCard=" .. table.concat(card_list, "+") .."&zaoyun")
      use.card =  sgs.Card_Parse(card_str)
      assert(use.card)
		  if use.to then
			  use.to:append(target)
			  global_room:writeToConsole("使用凿运目标:"..target:objectName().." 其距离:"..self.player:distanceTo(target))
		  end
   end
	end
  return
end

--徐庶
sgs.ai_skill_invoke.pozhen = function(self, data)
  local target = data:toPlayer()
  if not self:isFriend(target) then
    if self:getOverflow(target)> 2 or (self.player:getHp() == 1 and self:getAllPeachNum() < 1) then
      for _, p in ipairs(self.friends) do
        if target:canSlash(p, nil, true) and self:isWeak(p) then
          return true
        end
      end
    end
  end
	return fasle
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
    return true
  end
  if prompt[1] == "damage" then--无法知道伤害大小信息
    local target = prompt[2]
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
      if p:objectName() == target and self.player:isFriendWith(p) then
        return true
      end
    end
  end
	return fasle
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
  return
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

	local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
  self:useCardLureTiger(sgs.cloneCard("lure_tiger"), dummyuse)
	if not dummyuse.to:isEmpty() then
    use.card = card
		if use.to then
			use.to =  dummyuse.to
    end
  end
end

sgs.ai_use_priority.DiaoguiCard = sgs.ai_use_priority.LureTiger

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
	local slashes = self:getCards("Slash")
  if not slashes then return false end
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
    if prompt_list[2] == self.player:objectName() or prompt_list[4]:match("Peach") or prompt_list[4]:match("BefriendAttacking") then
      return true
    end
  end
	return false
end

--钟会
sgs.ai_skill_invoke.quanji = function(self, data)
	if not self:willShowForDefence() or not self:willShowForAttack() then
    return false
  end
	return true
end

sgs.ai_skill_exchange._quanji = function(self,pattern,max_num,min_num,expand_pile)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
  if #cards > 1 and cards[1]:isKindOf("Crossbow")--别放连弩
  and not ((cards[2]:isKindOf("Peach") or cards[2]:isKindOf("Analeptic")) and self.player:getHp() == 1) then
    return cards[2]:getEffectiveId()
  end
	return cards[1]:getEffectiveId()
end

local paiyi_skill = {}
paiyi_skill.name = "paiyi"
table.insert(sgs.ai_skills, paiyi_skill)
paiyi_skill.getTurnUseCard = function(self)
	if (self.player:getPile("power_pile"):length() > 1 and not self.player:hasUsed("PaiyiCard")) then
		return sgs.Card_Parse("@PaiyiCard=" .. self.player:getPile("power_pile"):first())
	end
	return nil
end

sgs.ai_skill_use_func.PaiyiCard = function(card, use, self)
	local target
  if self.player:getPile("power_pile"):length() > 3 then
    self:sort(self.friends, "defense")
	  for _, friend in ipairs(self.friends) do
		  if friend:getHandcardNum() < 2 and not self:needKongcheng(friend, true) and self.player:isFriendWith(freiend) then
			  target = friend
        break
		  end
	  end
	  if not target then
		  target = self.player
	  end
  else--4权以下
 	  self:sort(self.enemies, "hp")
	  if not target then
		  for _, enemy in ipairs(self.enemies) do
			  if self:isWeak(enemy)
				and not self:hasSkills(sgs.masochism_skill, enemy)
				and self:damageIsEffective(enemy, nil, self.player)
				and not (self:getDamagedEffects(enemy, self.player) or self:needToLoseHp(enemy))
				and enemy:getHandcardNum() + self.player:getPile("power_pile"):length() - 1 > self.player:getHandcardNum() then
				  target = enemy
          break
			  end
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

sgs.ai_card_intention.PaiyiCard = function(self, card, from, tos)
	local to = tos[1]
	if to:objectName() == from:objectName() then return end
	if from:isFriendWith(to) then
    sgs.updateIntention(from, to, -60)
	else
		sgs.updateIntention(from, to, 60)
	end
end

sgs.ai_use_priority.PaiyiCard = 2.4

sgs.paiyi_keep_value = {
	Crossbow = 6
}

function sgs.ai_cardneed.paiyi(to, card, self)
	if card:isKindOf("Crossbow") then
		return true
	end
end

--司马昭
sgs.ai_skill_invoke.suzhi = function(self, data)
	return self:willShowForAttack()
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
  if not self:willShowForDefence() then
    return false
  end
--昭心的触发条件给怎么写？现在主要是找桃
  local same_card_num = false
  local one_less_num = false
  local known_peach = false
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    if (getKnownCard(p, self.player, "Peach", false, "h") > 0) and p:getHandcardNum() <= self.player:getHandcardNum() then
      known_peach = true
    end
    if p:getHandcardNum() == self.player:getHandcardNum() then
      same_card_num = true
    end
    if (p:getHandcardNum() + 1 == self.player:getHandcardNum()) and not p:isKongcheng() then
      one_less_num = true
    end
  end
  if self:getCardsNum("Peach") == 0 and same_card_num then
    return true
  end
  if self:getCardsNum("Peach") == 0 and self.player:lostHp() == 1 and one_less_num then
    return true
  end
  if self:getCardsNum("Peach") == 0 and self.isWeak() and known_peach then
    return true
  end
	return false
end

sgs.ai_skill_playerchosen["zhaoxin-exchange"] = function(self, targets)
  targets = sgs.QList2Table(targets)
  self:sort(targets, "handcard", true)
  for _, p in ipairs(targets) do
    if getKnownCard(p, self.player, "Peach", false, "h") > 0 and self:isWeak() then
      return p
    end
  end
	return targets[1]
end

--孙綝
sgs.ai_skill_invoke.shilu = true

--公孙渊
local huaiyi_skill = {
  name = "huaiyi",
  getTurnUseCard = function(self, inclusive)
      if self.player:hasUsed("HuaiyiCard") or self.player:isKongcheng() then
          return nil
      end
      if self.player:getPile("disloyalty"):length() == self.player:getMaxHp() then
          return nil
      end
      if self.player:getPile("disloyalty"):length() + 1 == self.player:getMaxHp() and math.random(1, 5) > 4 then
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
  local handcards = self.player:getHandcards()
  local reds, blacks = {}, {}
  for _,c in sgs.qlist(handcards) do
      local dummy_use = {
          isDummy = true,
      }
      if c:isKindOf("BasicCard") then
          self:useBasicCard(c, dummy_use)
      elseif c:isKindOf("EquipCard") then
          self:useEquipCard(c, dummy_use)
      elseif c:isKindOf("TrickCard") then
          self:useTrickCard(c, dummy_use)
      end
      if dummy_use.card then
          return --It seems that self.player should use this card first.
      end
      if c:isRed() then
          table.insert(reds, c)
      else
          table.insert(blacks, c)
      end
  end
  
  local targets = self:findPlayerToDiscard("he", false, sgs.Card_MethodGet, nil, true)
  local n_reds, n_blacks, n_targets = #reds, #blacks, #targets
  if n_targets == 0 then
      return
  elseif n_reds - n_targets >= 2 and n_blacks - n_targets >= 2 and handcards:length() - n_targets >= 5 then
      return
  end
  --[[------------------
      Haven't finished.
  ]]--------------------
  use.card = card
end

sgs.ai_skill_choice["huaiyi"] = function(self, choices, data)
  local handcards = self.player:getHandcards()
  local reds, blacks = {}, {}
  local red_value, black_value = 0, 0
  for _,c in sgs.qlist(handcards) do
      if c:isRed() then
        red_value = red_value + self:getUseValue(c)
        table.insert(reds, c)
      else
        black_value = black_value + self:getUseValue(c)
        table.insert(blacks, c)
      end
  end
  if red_value < black_value then
      return "red"
  else
      return "black"
  end
end

sgs.ai_skill_playerchosen.huaiyi = function(self, targets, max_num, min_num)
  --global_room:writeToConsole("怀异最大目标:"..max_num)
  local result = {}
  local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "handcard")
  --global_room:writeToConsole("怀异可选目标数:"..#targetlist)
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and #result < max_num then
      table.insert(result, target)
    end
	end
  for _, target in ipairs(targetlist) do
		if not self.player:isFriendWith(target) and #result < max_num then
      table.insert(result, target)
    end
	end
  global_room:writeToConsole("怀异预定目标数:"..#result)
  return result
end

sgs.ai_skill_cardchosen.huaiyi = function(self, who, flags)
  local flag_str
  if self.player:getPile("disloyalty"):length() + 1 == self.player:getMaxHp() then
    flag_str = "h"
  elseif  self.player:getPile("disloyalty"):length() + 2 == self.player:getMaxHp() and math.random(1, 5) > 2  then
    flag_str = "h"
  elseif math.random(1, 5) > 3 then
    flag_str = "h"
  else
    flag_str = "he"
  end
	return self:askForCardChosen(who, flag_str, "dummyreason", sgs.Card_MethodDiscard)
end

sgs.ai_skill_invoke.zisui = true

--许攸
sgs.ai_skill_invoke.shicai = function(self, data)
	--[[if not self:willShowForDefence() then
    return false
  end]]--
  local damage = data:toDamage()
	return damage.damage < 2
end

sgs.ai_skill_invoke.chenglve = true

sgs.ai_skill_playerchosen.chenglve = function(self, targets)
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
	return self:getCardsNum("Slash") > 2 or self:getCardsNum("Jink") > 2
end

--潘濬
sgs.ai_skill_invoke.congcha = true

sgs.ai_skill_playerchosen.congcha = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_invoke.gongqing = function(self, data)
	if not self:willShowForDefence() then
    return false
  end
  local damage = data:toDamage()
  if not damage.from or damage.from:getAttackRange() > 3 then
    return false
  end
  if damage.from:getAttackRange() < 3 and damage.damage > 2 then
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
    if not target and friend:hasSkills(sgs.lose_equip_skill) and freiend:hasEquip() then
      target = friend
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
    local wenqin = sgs.findPlayerByShownSkillName("jinfa")
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
sgs.ai_skill_cardask["@daming"] = function(self, data, pattern, target, target2)
	local cards = self.player:getCards("h")
  cards=sgs.QList2Table(cards)
  self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			return card:toString()
		end
	end
	return "."
end

--ai铁索连环是defence筛选
sgs.ai_skill_playerchosen["_daming"] = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_choice.daming = function(self, choices, data)
  local freiend = self.room:getCurrent()
  if freiend:getHp() > 2 then
    return "slash"
  end
	return "peach"
end

--sgs.ai_skill_playerchosen["_daming"] = sgs.ai_skill_playerchosen.damage 两次选择reson一样？daming_chain和daming_slash

sgs.ai_skill_invoke.xiaoni = function(self, data)
	if not self:willShowForAttack() then
    return false
  end
  local use = data:toCardUse()
	return use.from:objectName() == self.player:objectName()
end

--苏飞
sgs.ai_skill_playerchosen.lianpian = function(self, targets)
  targets = sgs.QList2Table(targets)
  self:sort(targets, "handcard")
	return targets[1]
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

--sgs.ai_skill_cardchosen.lianpian 默认ai是顺拆的策略，不用写了吧

--诸葛恪
function sgs.ai_cardsview.aocai(self, class_name, player)
	if player:hasFlag("Global_AocaiFailed") or player:getPhase() ~= sgs.Player_NotActive then return end
--[[
  if not (pattern == "slash" or pattern == "jink" or pattern == "peach" or pattern:match("analeptic")) then
    return
  end
]]
  if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
  or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
    local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
    local card = "@AocaiCard=.&aocai:" .. pattern
    --global_room:writeToConsole("傲才需求响应:" .. card)
    if class_name == "Slash" then
      global_room:writeToConsole("傲才需求响应:" .. card)
      return "@AocaiCard=.&aocai:slash"
    end
    if class_name == "Jink" then
      global_room:writeToConsole("傲才需求响应:" .. card)
      return "@AocaiCard=.&aocai:jink"
    end
	elseif (class_name == "Peach" and player:getMark("Global_PreventPeach") == 0) or class_name == "Analeptic" then
		local dying = self.room:getCurrentDyingPlayer()
		if dying and dying:objectName() == player:objectName() then
			local user_string = "peach+analeptic"
			if player:getMark("Global_PreventPeach") > 0 then
        user_string = "analeptic"
      end
			return "@AocaiCard=.&aocai:" .. user_string
		else
			local user_string
			if class_name == "Analeptic" then
        user_string = "analeptic"
      else
        user_string = "peach"
      end
			return "@AocaiCard=.&aocai:" .. user_string
		end
	end
end

sgs.ai_skill_cardask["@aocai-view"] = function(self, data, pattern, target, target2)
  global_room:writeToConsole("进入傲才:" .. self.player:objectName())
  if self.player:hasFlag("Global_AocaiFailed") or self.player:getPhase() ~= sgs.Player_NotActive then
    return "."
  end
  local aocai_id = self.player:property("aocai"):toString():split("+")
  if #aocai_id == 0 then
    return "."
  end
  --[[if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
  or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
    for _, id in ipairs(aocai_id) do
      if sgs.Sanguosha:getCard(id):objectName() ==  sgs.Sanguosha:getCurrentCardUsePattern()
      or sgs.Sanguosha:getCurrentCardUsePattern():match(sgs.Sanguosha:getCard(id):objectName()) then
        return "$" .. id
      end
    end
  end
	return "."]]
  return "$" .. aocai_id[1]
end

--如果是使用杀的话，还要选目标

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
    if self.player:distanceTo(p) <= self.player:getAttackRange() and self:damageIsEffective(p, nil, self.player) then
      if not self.player:isFriendWith(p) then
        num_nofriednwith = num_nofriednwith + 1
      end
      if not self:isFriend(p) then
        num_enermy = num_enermy + 1
      end
    end
  end
  if ((self.player:getWeapon() and sgs.weapon_range[self.player:getWeapon():getClassName()] > 2) or num_enermy > 2)
  and self.player:getMark("Global_TurnCount") > 1 then--防止开局就使用
    use.card = card
  end
	if self.player:getHp() == 1 and num_nofriednwith > 1 then
    use.card = card
  end
end

sgs.ai_card_intention.DuwuCard = 80
sgs.ai_use_priority.DuwuCard= 3.6

sgs.ai_skill_choice["startcommand_duwu"] = function(self, choices)
  self.player:speak(choices)
  choices = choices:split("+")
  local commands = {"command2", "command3", "command4", "command1", "command6", "command5"}--索引大小代表优先级，注意不是原顺序
  local command_value1 = table.indexOf(commands,choices[1])
  local command_value2 = table.indexOf(commands,choices[2])
  self.duwu_index = math.max(command_value1,command_value2)--需要一些额外的标记？
  --global_room:writeToConsole("choice:".. choices[self.duwu_index])
  return commands[self.duwu_index]
end

sgs.ai_skill_choice["docommand_duwu"] = function(self, choices)
  --[[if self.duwu_index <= 4 then
    return "yes"
  end
  if self.duwu_index == 5 then
    if self.player:getCards("he"):length() < 4 then
      return "yes"
    elseif self.player:getHp() < 3 and self:getCardsNum("Peach") == 0 and self.player:getCards("he"):length() < 6 then
      return "yes"
    else
      return "no"
    end
  end
  if self.duwu_index == 6 then
    if not self.player:faceUp() then
      return "yes"
    elseif self.player:getHp() < 3 and self:getCardsNum("Peach") == 0 and self.player:getHandcardNum() < 3
    and math.random(1, 100) / 100 >= 50  then
      return "yes"
    else
      return "no"
    end
  end]]--
  return "yes"
end

sgs.ai_skill_playerchosen["command_duwu"] = sgs.ai_skill_playerchosen.damage

--黄祖
sgs.ai_skill_cardask["@xishe-slash"] = function(self, data, pattern, target, target2)
  if not self.player:hasEquip() or not target or target:isDead() then
    return "."
  end
  if not self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then
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
    if target:getHp() == 1 or (self.player:getHp() > target:getHp() and (target:getHp() < 3 or self:getCardsNum("EquipCard") > 2)) then
      if self:needToThrowArmor() then
        return "$" .. self.player:getArmor():getEffectiveId()
      end
      self:sortByKeepValue(equipcards)
      return "$" .. equipcards[1]:getEffectiveId()
    end
  end
	return "."
end

--刘巴
sgs.ai_skill_invoke.tongdu = true

sgs.ai_skill_choice.tongdu = "yes"

local qingyin_skill = {}
qingyin_skill.name = "qingyin"
table.insert(sgs.ai_skills, qingyin_skill)
qingyin_skill.getTurnUseCard = function(self)
	if self.player:getMark("@qingyin") < 1 then return end
  --global_room:writeToConsole("进入刘巴技能:" .. self.player:objectName())
  local count = 0
	for _, friend in ipairs(self.friends) do
		if self.player:isFriendWith(friend) and (friend:getHp() <= 1 or (friend:getHp() <= 2 and friend:getHandcardNum() < 2)) then
      count = count + 1
		end
	end
  --global_room:writeToConsole("计数:"..count)
  if count > 1 or (self.player:getHp() == 1 and self:getAllPeachNum() < 1) then
  	return sgs.Card_Parse("@QingyinCard=.&qingyin")
  end
end

sgs.ai_skill_use_func.QingyinCard = function(card, use, self)
  --global_room:writeToConsole("使用刘巴技能")
	use.card = card
end

sgs.ai_card_intention.QingyinCard = -80
sgs.ai_use_priority.QingyinCard = 0

--朱灵
sgs.ai_skill_invoke.juejue = function(self, data)
	if not self:willShowForAttack() then
    return false
  end
  local freiend_weak = 0
  local enemy_weak = 0
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    if self:isFriend(p) and self:isWeak(p) then
      freiend_weak = freiend_weak + 1
    end
    if not self:isFriend(p) and self:isWeak(p) then
      enemy_weak = enemy_weak + 1
    end
  end
  if self:getOverflow() > 1 and self.player:getHp() > 1 then
    if enemy_weak > 2 or enemy_weak > freiend_weak  then
      return true
    end
    if self.player:getHp() > 2 and self:getCardsNum("Peach") > 0 and (#self.enemies > 2 or #self.enemies > #self.friends) then
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
  if self.player:getHp() > 2 or self:getCardsNum("Peach") > 0 or (self.player:getHp() == 1 and self:getCardsNum("Analeptic") > 0) then
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

sgs.ai_skill_playerchosen["_fangyuan"]= sgs.ai_skill_playerchosen.damage