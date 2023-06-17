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
--崔毛
sgs.ai_skill_use["@@zhengbi"] = function(self, prompt, method)
  if self.player:isKongcheng() then
    return "."
  end
  for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not self:isFriend(p) and not p:hasShownOneGeneral() then
			if self:getCardsNum("Slash") > 1 and (p:getHp() < 3 or self:getCardsNum("Halberd") > 0) then
        return "@ZhengbiCard=".. "->" .. p:objectName()
      end
		end
	end
  local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	self:sortByUseValue(handcards,true)
	local card
  local visibleflag--记录给出的手牌，盗书等技能需要
  for _, c in ipairs(handcards) do
    if c:getTypeId() == sgs.Card_TypeBasic then
      card = c
      break
    end
  end
  if not card then
    return "."
  end
  if card:isKindOf("Peach") then
    if self:getCardsNum("Peach") <= self.player:getLostHp()  then
      return "."
    end
    self:sort(self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
      if friend:getCardCount(true) > 1 and (friend:isWounded() or self:getOverflow() > 0) and friend:hasShownOneGeneral() then
        visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), friend:objectName())
        if not card:hasFlag("visible") then card:setFlags(visibleflag) end
        return "@ZhengbiCard=" .. card:getEffectiveId() .. "->" .. friend:objectName()
      end
    end
    return "."
  end
	self:sort(self.enemies, "handcard")
  for _, target in ipairs(self.enemies) do
    if not target:isKongcheng() and (target:getHandcardNum() < 3 or self:isWeak(target)) and target:hasShownOneGeneral() then
      if not (card:isKindOf("Analeptic") and target:hasEquip() and self:isWeak(target)) then
        visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
        if not card:hasFlag("visible") then card:setFlags(visibleflag) end
        return "@ZhengbiCard=" .. card:getEffectiveId() .. "->" .. target:objectName()
      end
    end
  end
  return "."
end

sgs.ai_skill_cardask["@zhengbi-give"] = function(self, data, pattern, target, target2)
  if not target or target:isDead() then return "." end
--[[保留值的函数应该能覆盖以下情况
  if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
  end
  if self.player:hasSkills(sgs.lose_equip_skill) and self.player:hasEquip() then
    local equip = self.player:getCards("e")
    equip = sgs.QList2Table(equip)
    self:sortByUseValue(equip, true)
    return "$" .. equip[1]:getEffectiveId()
  end
]]
  local allcards = self.player:getCards("he")
	allcards = sgs.QList2Table(allcards)
	self:sortByKeepValue(allcards)
  local visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())--标记可见
  if #allcards == 1 then
    if not allcards[1]:hasFlag("visible") then allcards[1]:setFlags(visibleflag) end
    return "$" .. allcards[1]:getEffectiveId()
  end
  if allcards[1]:getTypeId() ~= sgs.Card_TypeBasic then
    if not allcards[1]:hasFlag("visible") then allcards[1]:setFlags(visibleflag) end
    return "$" .. allcards[1]:getEffectiveId()
  elseif allcards[2]:getTypeId() ~= sgs.Card_TypeBasic then
    if not allcards[2]:hasFlag("visible") then allcards[2]:setFlags(visibleflag) end
    return "$" .. allcards[2]:getEffectiveId()
  else
    local give_cards = {}
    table.insert(give_cards, allcards[1]:getId())
    table.insert(give_cards, allcards[2]:getId())
    if not allcards[1]:hasFlag("visible") then allcards[1]:setFlags(visibleflag) end
    if not allcards[2]:hasFlag("visible") then allcards[2]:setFlags(visibleflag) end
    return "$" .. table.concat(give_cards, "+")
  end
end

local fengying_skill = {}
fengying_skill.name = "fengying"
table.insert(sgs.ai_skills, fengying_skill)
fengying_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@honor") < 1 or self.player:isKongcheng() then return end
  return sgs.Card_Parse("@FengyingCard=.&")
end

sgs.ai_skill_use_func.FengyingCard = function(card, use, self)
  local draw_count = 0
  for _, p in ipairs(self.friends) do
    if self.player:isFriendWith(p) then
      draw_count = draw_count + p:getMaxHp() - p:getHandcardNum()
    end
  end
  if draw_count > 3 or self.player:getHp() == 1 then
    if self.player:getHandcardNum() > 1 then
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
    end
    if self.player:getHandcardNum() == 1 then
      sgs.ai_use_priority.FengyingCard = 2
    end
    use.card = card--不弃牌使用挟天子更优的情况估计得在挟天子弃牌的ai里写，需要data判定card:getSkillName()才行
  end
end

sgs.ai_card_intention.FengyingCard = -80
sgs.ai_use_priority.FengyingCard = 0

--于禁
sgs.ai_skill_use["@@jieyue"] = function(self, prompt, method)
  if self.player:isKongcheng() then
    return "."
  end
  if self:willSkipDrawPhase()--手中最后一张牌是无懈？
  and not (self.player:hasSkill("qiaobian") and self.player:getHandcardNum() < 2)
  and not (self.player:hasSkill("elitegeneralflag") and self.player:getHandcardNum() < 3) then
    return "."
  end
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	self:sortByUseValue(handcards,true)
	local card = handcards[1]
  local visibleflag--记录给出的手牌，盗书等技能需要
  if self:isWeak() and isCard("Peach", card, self.player) then
    return "."
  end
  local targets = {}
  for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getSeemingKingdom() ~= "wei" then
			table.insert(targets, p)
		end
	end
  if #targets == 0 then
    return "."
  end
  self:sort(targets, "handcard")
  for _, p in ipairs(targets) do
    if self:isFriend(p) then
      visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), p:objectName())
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end
        return "@JieyueCard=" .. card:getEffectiveId() .. "->" .. p:objectName()
    end
  end
  if isCard("Peach", card, self.player) then
    return "."
  end
	self:sort(targets, "defense", true)
  for _, p in ipairs(targets) do
    if not self:isFriend(p) then
      visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), p:objectName())
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end
      return "@JieyueCard=" .. card:getEffectiveId() .. "->" .. p:objectName()
    end
  end
  return "."
end

sgs.ai_skill_choice.startcommand_jieyue = sgs.ai_skill_choice.startcommand_to

sgs.ai_skill_choice["docommand_jieyue"] = function(self, choices, data)
	local source = data:toPlayer()
	local index = self.player:getMark("command_index")
	local is_enemy = self:isEnemy(source)
	local is_friend = self:isFriend(source)
	if index == 1 then
		if not is_enemy and not is_friend then
			return "yes"
		end
		if is_friend and not self:isWeak(source) then
			for _, p in ipairs(self.enemies) do
				if p:getHp() == 1 and self:isWeak(p) and self:isEnemy(source, p) and self:canAttack(p,self.player) then
					return "yes"
				end
			end
		end
	end
	if index == 5 and not self.player:faceUp() then
		return "yes"
	end
	if is_enemy then
		if self:willSkipDrawPhase(source) or (self:willSkipPlayPhase(source) and self:getOverflow(source) > -1) then
			return "no"
		end
		if index == 1 then
			for _, p in ipairs(self.friends) do
				if p:getHp() <= 2 and self:isWeak(p) and self:canAttack(p,self.player) then
					return "no"
				end
			end
			return "yes"
		end
		if index == 2 then
			return "yes"
		end
		if index == 3 then
			if (self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty()) 
				or self:needToLoseHp() or not self:isWeak() then
				return "yes"
			end
		end
		if index == 4 then
			if self.player:getMark("command4_effect") > 0 then
				return "yes"
			end
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
			if not source:canSlash(self.player, nil, true) then
				return "yes"
			end
		end
		if index == 6 then
			if (self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3)
				or (self.player:hasSkill("lirang") and #self.friends_noself > 0) then
				return "yes"
			end
		end
	end
	return "no"
end
--伤害来源不同,合适的伤害目标也不同,实际并不能照搬(例如远域打自己)
sgs.ai_skill_playerchosen["command_jieyue"] = sgs.ai_skill_playerchosen.damage

sgs.ai_choicemade_filter.skillChoice["docommand_jieyue"] = function(self, player, promptlist)
	local yujin = self.room:getCurrent()
	local index = player:getMark("command_index")
	local choice = promptlist[#promptlist]
	--[[
	["#command1"] = "军令一：对你指定的角色造成1点伤害",
	["#command2"] = "军令二：摸一张牌，然后交给你两张牌",
	["#command3"] = "军令三：失去1点体力",
	["#command4"] = "军令四：本回合不能使用或打出手牌且所有非锁定技失效",
	["#command5"] = "军令五：叠置，本回合不能回复体力",
	["#command6"] = "军令六：选择一张手牌和一张装备区里的牌，弃置其余的牌",
	--]]
	if index == 1 and not self:needDamagedEffects(player, player) and not self:needToLoseHp(player) then
		if choice == "no" then
			if not (self:willSkipDrawPhase(yujin) or (self:willSkipPlayPhase(yujin) and self:getOverflow(yujin) > -1)) then
				sgs.updateIntention(player, yujin, -80)
			end
		elseif self:isWeak(player) and self:canAttack(player) and choice == "yes" then
			sgs.updateIntention(player, yujin, -40)
		elseif choice == "yes" then
			sgs.updateIntention(player, yujin, 80)
		end
	elseif index == 3 and not self:needToLoseHp(player) then
		if choice == "yes" then
			sgs.updateIntention(player, yujin, 80)
		elseif not self:isWeak(player) then
			if not (self:willSkipDrawPhase(yujin) or (self:willSkipPlayPhase(yujin) and self:getOverflow(yujin) > -1)) then
				sgs.updateIntention(player, yujin, -80)
			end
		end
	elseif index == 5 and self.player:faceUp() then
		if choice == "yes" then
			sgs.updateIntention(player, yujin, 40)
		end
	elseif choice == "yes" then
		sgs.updateIntention(player, yujin, 80)
	end
end

function sgs.ai_cardneed.jieyue(to, card)
	return to:isKongcheng()
end

--王平
local jianglve_skill = {}
jianglve_skill.name = "jianglve"
table.insert(sgs.ai_skills, jianglve_skill)
jianglve_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@strategy") < 1 then return end
	---[[--将略召唤效果没了
	local jianglve_value = 0
	local evaluate_value = 0
	local evaluate_friend = false
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if sgs.isAnjiang(p) then
			if self:evaluateKingdom(p) == "unknown" then
				evaluate_value = evaluate_value + 0.5
				evaluate_friend = true
			elseif self:isFriendWith(p) then
				evaluate_value = evaluate_value + 1
				if self:isWeak(p) then evaluate_value = evaluate_value + 1 end
			end
		elseif self.player:isFriendWith(p) then
			jianglve_value = jianglve_value + 1
			if self:isWeak(p) then jianglve_value = jianglve_value + 1 end
		end
	end
	if not evaluate_friend then return sgs.Card_Parse("@JianglveCard=.&jianglve") end--没有未明置的队友
	if jianglve_value >= 4 then return sgs.Card_Parse("@JianglveCard=.&jianglve") end--至少覆盖3人或者2人isWeak
	if jianglve_value < 3 and evaluate_value > 0 then return end--暂且等待队友明置
	--]]
	return sgs.Card_Parse("@JianglveCard=.&jianglve")
end

sgs.ai_skill_use_func.JianglveCard= function(card, use, self)
	use.card = card
end

sgs.ai_card_intention.JianglveCard = -120
sgs.ai_use_priority.JianglveCard = 9.15

sgs.ai_skill_choice["startcommand_jianglve"] = function(self, choices)
  Global_room:writeToConsole(choices)
  choices = choices:split("+")
  if table.contains(choices, "command5") then
    local faceup, not_faceup = 0, 0
    for _, friend in ipairs(self.friends_noself) do
      if self:isFriendWith(friend) then
        if friend:faceUp() then
          faceup = faceup + 1
        else
          not_faceup = not_faceup + 1
        end
      end
      if not_faceup > faceup and not_faceup > 1 then
        return "command5"
      end
    end
  end
  local commands = {"command1", "command2", "command4", "command3", "command6", "command5"}--索引大小代表优先级，注意不是原顺序
  local command_value1 = table.indexOf(commands,choices[1])
  local command_value2 = table.indexOf(commands,choices[2])
  local index = math.min(command_value1,command_value2)
  return commands[index]
end

sgs.ai_skill_choice["docommand_jianglve"] = function(self, choices, data)
  local source = data:toPlayer()
  local index = self.player:getMark("command_index")
  if self.player:getActualGeneral1():getKingdom() == "careerist" then
    return "yes"
  end
  if index == 4 then
    if self.player:getMark("command4_effect") > 0 then
      return "yes"
    end
    if self.player:hasSkill("xuanhuo") and not source:hasUsed("XuanhuoAttachCard") and source:getHandcardNum() > 5 then
      return "no"
    end
  end
  if index == 5 then
    if not self.player:faceUp() then
      return "yes"
    end
    return "no"
  end
  if index == 6 then
    if (self.player:getEquips():length() < 4
      and self.player:getHandcardNum() <= (self.player:hasSkills("xuanhuoattach|paoxiao") and 5 or 4))
    or (self:isWeak() and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0) then
      return "yes"
    end
    return "no"
  end
  return "yes"
end

sgs.ai_skill_playerchosen["command_jianglve"] = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_choice["jianglve"] = function(self, choices, data)--ai势力召唤
  choices = choices:split("+")
  if table.contains(choices,"show_head_general") and (self.player:inHeadSkills("jianxiong") or self.player:inHeadSkills("rende")
	or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("guidao"))--君主替换
    and sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1  then
    return "show_deputy_general"
  end
  if table.contains(choices,"show_both_generals") then
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
      return "show_deputy_general"
    end
    if wuhu_show_head then
      return "show_head_general"
    end
    return "show_both_generals"
  end
  if table.contains(choices,"show_deputy_general") then
    return "show_deputy_general"
  end
  if table.contains(choices,"show_head_general") then
    return "show_head_general"
  end
  return choices[1]
end

sgs.ai_choicemade_filter.skillChoice["jianglve"] = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if not player:hasShownOneGeneral() then
		local choice = promptlist[#promptlist]
		if choice == "cancel" and (player:canShowGeneral("h") or player:canShowGeneral("d")) then
			sgs.updateIntention(player, current, 80)
		end
	end
end

--法正
sgs.ai_skill_invoke.enyuan = function(self, data)
  local target = data:toPlayer()
  if target:objectName() == self.player:objectName() then--只考虑不恩怨自己掉血，其他正负面无法分辨
    return false
  end
  return true
end

sgs.ai_skill_exchange["_enyuan"] = function(self,pattern,max_num,min_num,expand_pile)
  --Global_room:writeToConsole("恩怨判断开始:"..tostring(pattern))
  --2.3.0恩怨自己必掉血……
  if self.player:isKongcheng() then
    return {}
  end
  if self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty() then--君张角
    return {}
  end
  local fazheng = sgs.findPlayerByShownSkillName("enyuan")
  local visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), fazheng:objectName())
  local cards = self.player:getHandcards() -- 获得所有手牌
  cards=sgs.QList2Table(cards) -- 将列表转换为表
  self:sortByUseValue(cards, true) -- 按使用价值从小到大排序
  if cards[1]:isKindOf("Peach") then
    if self:isFriend(fazheng) then
      if not cards[1]:hasFlag("visible") then cards[1]:setFlags(visibleflag) end
      return {cards[1]:getId()}
    end
    return {}
  end
  if not cards[1]:hasFlag("visible") then cards[1]:setFlags(visibleflag) end--记录已知牌
  return {cards[1]:getId()}
end

--从sgs.ai_skill_use.slash里复制的杀目标选择，似乎可以直接用SmartAI:useCardSlash的结果
local function getSlashtarget(self)
  local max_range = 0
  local horse_range = 0
  local current_range = self.player:getAttackRange()
  for _,card in sgs.qlist(self.player:getCards("he")) do
    if card:isKindOf("Weapon") and max_range < sgs.weapon_range[card:getClassName()] then
      max_range = sgs.weapon_range[card:getClassName()]--或许应该考虑最合适的那把武器距离，先去掉防止丢失目标
    end
  end
  if self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse() then
    horse_range = 1
  end
  --注意正负，距离增大是负修正 math.min(current_range - max_range, 0) self.player:canSlash(enemy, slash, true, range_fix)
  local range_fix = -horse_range
  if self:getCardsNum("Slash") == 0 then--想选武圣龙胆怎么办？
    self.room:writeToConsole("getSlashtarget:无杀")
    return nil end
	local slashes = self:getCards("Slash")
	self:sortByUseValue(slashes)
	self:sort(self.enemies, "defenseSlash")
	for _, slash in ipairs(slashes) do
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy)
				and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
				and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
				return enemy
			end
		end
	end
  self.need_liegong_distance = false
  local liubei = self.room:getLord(self.player:getKingdom())
  if liubei and liubei:hasLordSkill("shouyue") then
    local can_chooseliegong  = true
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
      if p:hasSkill("liegong") then
        can_chooseliegong = false
      end
    end
    if can_chooseliegong then
      for _, slash in ipairs(slashes) do--距离再修正1寻找敌人 self.player:canSlash(enemy_1, slash, true, range_fix-1)
        for _, enemy_1 in ipairs(self.enemies) do
          if self.player:canSlash(enemy_1, slash, true, -1) and not self:slashProhibit(slash, enemy_1)
            and self:slashIsEffective(slash, enemy_1) and sgs.isGoodTarget(enemy_1, self.enemies, self)
            and not (self.player:hasFlag("slashTargetFix") and not enemy_1:hasFlag("SlashAssignee")) then
              self.need_liegong_distance = true
            return enemy_1
          end
        end
      end
    end
  end
  self.room:writeToConsole("getSlashtarget:无目标")
  return nil
end

--是否发动眩惑，顺带小判定。可能得判断技能选择，再判断是否发动才不会有bug
local function shouldUseXuanhuo(self)
  local xuanhuoskill = {"wusheng", "paoxiao", "longdan", "tieqi", "liegong", "kuanggu"}
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    for _, skill in ipairs(xuanhuoskill) do
      if p:hasShownSkill(skill) then
        table.removeOne(xuanhuoskill,skill)
      end
    end
  end
  for _, skill in ipairs(xuanhuoskill) do
    if self.player:hasSkill(skill) then
      table.removeOne(xuanhuoskill,skill)
    end
  end
  if #xuanhuoskill == 0 then--不太常见的没有技能可选
    return false
  end
  local xuanhuochoices = table.concat(xuanhuoskill,"+")
  local choice = sgs.ai_skill_choice.xuanhuo(self, xuanhuochoices)
  self.room:writeToConsole("---眩惑预选技能:"..sgs.Sanguosha:translate(choice).."---")

  --如何去除没有连弩或咆哮却选武圣，牌少又断杀等情况
  if choice ~= "paoxiao" and not self:slashIsAvailable() and self:getOverflow() < 1 then
    return false
  end

  if self:getCardsNum("Slash") == 0 then
    if (choice == "wusheng" or choice == "longdan") and self:getOverflow() > 1 then
      self.need_xuanhuo_slash = true
      return true
    else
      self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑无转换杀技能")
      return false
    end
  end

  if self:getCardsNum("Slash") == 1 and (choice == "wusheng" or choice == "longdan") then
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑无进攻技能")
    return false
  end

  self.need_kuanggu_AOE = false
  --[[
  if not self.player:hasSkill("kuanggu") and table.contains(xuanhuoskill,"kuanggu") and self:getCardsNum("Slash") < 2 and
  (self:getCardsNum("SavageAssault") + self:getCardsNum("ArcheryAttack") > 0) and
  (self.player:getOffensiveHorse() or self.player:hasShownSkills("mashu_machao|mashu_madai")
  or self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()) then
    self.need_kuanggu_AOE = true
    self.player:speak("需要眩惑狂骨AOE")
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑狂骨AOE")
    return true
  end]]

  local target = getSlashtarget(self)
  if not self.player:hasSkill("liegong") and table.contains(xuanhuoskill,"liegong") and self.need_liegong_distance then
    local liubei = self.room:getLord(self.player:getKingdom())
    if liubei and liubei:hasLordSkill("shouyue") then
      self.player:speak("需要眩惑君刘备烈弓距离")
      self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑君刘备烈弓距离")
      return true
    else
      self.need_liegong_distance = false
    end
  end

  if not target then--无杀目标或无杀
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑无杀目标")
    return false
  end
  assert(target)

  if self.player:hasSkills("tieqi|liegong|qianxi")
  and (choice == "liegong" or (choice == "tieqi" and not target:hasShownSkill("tianxiang"))) then
    return false
  end

  if self.player:getMark("@strategy") >= 1 or self.player:getHandcardNum() > 4
   or (self.player:getHandcardNum() > 3 and self.player:hasEquip()) then--多余手牌需要弃置时？
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑符合条件")
    return true
  end
  return false
end

--真君主技眩惑
local xuanhuoattach_skill = {}
xuanhuoattach_skill.name = "xuanhuoattach"
table.insert(sgs.ai_skills, xuanhuoattach_skill)
xuanhuoattach_skill.getTurnUseCard = function(self, inclusive)
  if self.player:getHandcardNum() < 2 then return end--牌不足
  if not self.player:hasUsed("XuanhuoAttachCard") and shouldUseXuanhuo(self) then
    local cards = self.player:getHandcards()
	  cards = sgs.QList2Table(cards)
	  self:sortByUseValue(cards, true) -- 按使用价值从小到大排序
		return sgs.Card_Parse("@XuanhuoAttachCard=" .. cards[2]:getEffectiveId())--给牌弃牌可能把武器或杀给了，导致第二次丢失目标
	end
end

sgs.ai_skill_use_func.XuanhuoAttachCard= function(card, use, self)
  sgs.ai_use_priority.XuanhuoAttachCard = 5
  --self.room:writeToConsole("发动眩惑:"..self.player:objectName())
  --sgs.debugFunc(self.player, 2)
  self.player:speak("发动眩惑")
  if self.player:hasSkill("jizhi") then--使用锦囊后
    sgs.ai_use_priority.XuanhuoAttachCard = 2.8
  end
  if self.need_kuanggu_AOE then--使用AOE前
    sgs.ai_use_priority.XuanhuoAttachCard = 3.6
  end
  if self.player:hasSkill("jili") then--使用完武器后
    sgs.ai_use_priority.XuanhuoAttachCard = 6
  end
  for _, p in ipairs(self.friends) do
    if p:hasShownSkill("yongjue") and self.player:isFriendWith(p) then
      sgs.ai_use_priority.XuanhuoAttachCard = 9.6--勇决杀的优先调整到9.5
    end
  end
  if self.player:getMark("@strategy") >= 1 then--在王平限定技发动前
    sgs.ai_use_priority.XuanhuoAttachCard = sgs.ai_use_priority.JianglveCard + 0.1
  end
  if self.player:getActualGeneral1():getKingdom() == "careerist" then
    sgs.ai_use_priority.XuanhuoAttachCard = 20--野心家
  end
  --考虑配合仁德？
	use.card = card
end

sgs.ai_card_intention.XuanhuoAttachCard = -90

sgs.ai_skill_discard["xuanhuo_discard"] = function(self, discard_num, min_num, optional, include_equip)
	if self.player:getHandcardNum() < 2 then
		return {}
	else
    local cards = self.player:getCards("he")
	  cards = sgs.QList2Table(cards)
	  self:sortByUseValue(cards, true) -- 按使用价值从小到大排序
		return {cards[1]:getEffectiveId()}
	end
	return {}
end

sgs.ai_skill_choice.xuanhuo = function(self, choices)
  choices = choices:split("+")
  local xuanhuoskill = {"wusheng", "paoxiao", "longdan", "tieqi", "liegong", "kuanggu"}
  local has_wusheng = self.player:hasSkills("wusheng|wusheng_xh")
  local has_paoxiao = self.player:hasSkills("paoxiao|paoxiao_xh")
  local has_longdan = self.player:hasSkills("longdan|longdan_xh")
  local has_tieqi = self.player:hasSkills("tieqi|tieqi_xh")
  local has_liegong = self.player:hasSkills("liegong|liegong_xh")
  local has_kuanggu = self.player:hasSkills("kuanggu|kuanggu_xh")
  local has_qianxi = self.player:hasSkill("qianxi")
  local has_Crossbow = self:getCardsNum("Crossbow") > 0
  local has_baolie = self.player:hasSkill("baolie") and self.player:getHp() < 3--夏侯霸新技能豹烈

  local enough_pxslash = false
  if self:getCardsNum("Slash") > 0 then
    local yongjue_slash = 0
    if self.player:getMark("GlobalPlayCardUsedTimes") == 0 then--考虑没出牌时,有一张杀
      for _, p in ipairs(self.friends) do
        if p:hasShownSkill("yongjue") and self.player:isFriendWith(p) then
          yongjue_slash = 1
          break
        end
      end
    end
    if yongjue_slash + self.player:getSlashCount() + self:getCardsNum("Slash") >= 2 then--getCardsNum包含转化的杀
      enough_pxslash = true
    end
  end

--集中判断保证自己没有相应的技能和选项里有技能，避免每次都重复判断
  local can_paoxiao = false
  local can_wusheng = false
  local need_tieqi = false
  local can_tieqi = false
  local can_liegong = false
  local can_kuanggu = false
  local lord_longdan = false
  local can_longdan = false

  if self.need_liegong_distance then--需要眩惑君刘备烈弓距离
    self.need_liegong_distance = nil
    return "liegong"
  end
  if self.need_kuanggu_AOE then--需要眩惑狂骨AOE
    self.need_kuanggu_AOE = nil
    return "kuanggu"
  end

  if not has_longdan and table.contains(choices,"longdan") and self:getCardsNum("Jink") >= 1 then--龙胆可以杀队友进行回复或伤害，不需要target，虽然ai目前不会
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑可龙胆")
    can_longdan = true
  end

  --Func(self.player, 2)
  local target = getSlashtarget(self)--中间给牌弃牌，可能失去武器或杀导致无返回目标。好像还有目标找错的情况？
  if not target then
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑选择无杀目标或无杀！！")
    --assert(target)
    goto Pass_target--暂时无杀目标或无杀跳转至目标判定后，需要优化眩惑触发判断和弃牌给牌
  end
  Global_room:writeToConsole("眩惑杀目标:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))

  if not has_Crossbow and not has_paoxiao and not has_baolie and table.contains(choices,"paoxiao") and enough_pxslash and target then
	--有合适的目标才咆哮
	self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑可咆哮")
	can_paoxiao = true
  end
  if not has_wusheng and table.contains(choices,"wusheng") then
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑可武圣")
    can_wusheng = true
  end
  if not has_tieqi and table.contains(choices,"tieqi") then
    local skills_name = (sgs.masochism_skill .. "|" .. sgs.save_skill .. "|" .. sgs.defense_skill .. "|" .. sgs.wizard_skill):split("|")
	  for _, skill_name in ipairs(skills_name) do
		  local skill = sgs.Sanguosha:getSkill(skill_name)
		  if target:hasShownSkill(skill_name) and target:ownSkill(skill_name) and skill and skill:getFrequency() ~= sgs.Skill_Compulsory then
        self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑需要铁骑")
        need_tieqi = true--有需要铁骑的技能
        break
      end
	  end
  end
  if not has_tieqi and table.contains(choices,"tieqi") then
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑可铁骑")
    can_tieqi = true
  end
  if not has_liegong and table.contains(choices,"liegong") and target:getHp() >= self.player:getHp() then
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑可烈弓")
    can_liegong = true--符合烈弓发动条件
  end
  if not has_kuanggu and table.contains(choices,"kuanggu") and (self.player:hasShownSkills("mashu_machao|mashu_madai") or self.player:distanceTo(target) < 2
  or (self.player:distanceTo(target) == 2 and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse())) then
    self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑可狂骨")
    can_kuanggu = true--有马术或-1马或距离为1
  end
  if not has_longdan and table.contains(choices,"longdan") and self:getCardsNum("Jink") >= 1 then
    local liubei = self.room:getLord(self.player:getKingdom())
    if liubei and liubei:hasLordSkill("shouyue") then
      self.room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":眩惑君龙胆")
      lord_longdan = true--有君刘备
    end
  end

  if self.need_xuanhuo_slash then--需要眩惑转化杀
    self.need_xuanhuo_slash = nil
    if lord_longdan or can_longdan then
      return "longdan"
    end
    if can_wusheng then
      return "wusheng"
    end
  end

  --已有双技能的情况
  if has_kuanggu and (has_tieqi or has_liegong or has_qianxi) then--魏延和马超兄弟/黄忠
    if has_Crossbow then
      if can_wusheng then
        return "wusheng"
      elseif can_longdan then
        return "longdan"
      end
    elseif can_paoxiao then
      return "paoxiao"
    end
  end
  if (has_wusheng or has_longdan) and (has_paoxiao or has_Crossbow or has_baolie) then--关张和赵张
    if can_kuanggu then
      return "kuanggu"
    elseif need_tieqi then
      return "tieqi"
    elseif can_liegong then
      return "liegong"
    end
  end
  if has_kuanggu and (has_paoxiao or has_baolie) then--魏延和张飞
    if can_wusheng then
      return "wusheng"
    elseif lord_longdan then
      return "longdan"
    elseif need_tieqi then
      return "tieqi"
    elseif can_liegong then
      return "liegong"
    end
  end
  if (has_paoxiao or has_Crossbow or has_baolie) and (has_tieqi or has_liegong or has_qianxi) then--张飞/夏侯霸和马超兄弟/黄忠
    if can_kuanggu then
      return "kuanggu"
    elseif can_wusheng then
      return "wusheng"
    elseif can_longdan then
      return "longdan"
    end
  end
  if (has_wusheng or has_longdan) and (has_tieqi or has_liegong or has_qianxi) then--关/赵和马超兄弟/黄忠
    if has_Crossbow and can_kuanggu then
      return "kuanggu"
    elseif can_paoxiao then
      return "paoxiao"
    elseif can_kuanggu then
      return "kuanggu"
    end
  end
  if (has_wusheng or has_longdan) and has_kuanggu then--关/赵和魏延
    if has_Crossbow and need_tieqi then
      return "tieqi"
    elseif has_Crossbow and can_liegong then
      return "liegong"
    elseif has_Crossbow and can_tieqi then
      return "tieqi"
    elseif can_paoxiao then
      return "paoxiao"
    elseif need_tieqi then
      return "tieqi"
    elseif can_liegong then
      return "liegong"
    end
  end

  --单技能的情况
  if (has_tieqi or has_liegong or has_qianxi) then--马超兄弟/黄忠
    if has_Crossbow and can_kuanggu then
      return "kuanggu"
    elseif can_kuanggu and self.player:getHp() <=2 then
      return "kuanggu"
    elseif can_paoxiao then--咆哮
        return "paoxiao"
    elseif target:hasShownSkill("tianxiang") and need_tieqi then
        return "tieqi"
    elseif can_kuanggu then
        return "kuanggu"
    end
  end
  if(has_paoxiao or has_Crossbow or has_baolie) then--张飞、夏侯霸
    if enough_pxslash then
      if can_kuanggu then
        return "kuanggu"
      elseif need_tieqi then
        return "tieqi"
      elseif can_liegong then
        return "liegong"
      elseif can_tieqi then--烈弓再找不到目标
        return "tieqi"
      end
    elseif can_wusheng then
      return "wusheng"
    elseif can_longdan then
      return "longdan"
    end
  end
  if (has_wusheng or has_longdan) then--关/赵
    if has_Crossbow and can_kuanggu then
      return "kuanggu"
    elseif can_paoxiao then
      return "paoxiao"
    end
  end
  if has_kuanggu then--魏延
    if has_Crossbow and (self.player:distanceTo(target) < 2
    or (self.player:distanceTo(target) == 2 and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse())) then
      if can_wusheng then
        return "wusheng"
      elseif lord_longdan then
        return "longdan"
      end
    elseif can_paoxiao then--咆哮
      return "paoxiao"
    elseif self.player:getHp() <=2 then
      if need_tieqi then
        return "tieqi"
      elseif can_liegong then
        return "liegong"
      elseif can_tieqi then--烈弓再找不到目标
        return "tieqi"
      end
    end
  end

  --普通的技能选择顺序
  :: Pass_target ::
  if can_paoxiao and not (has_baolie or has_Crossbow) then--咆哮
    return "paoxiao"
  end
  if can_kuanggu and ((has_Crossbow and enough_pxslash) or (self.player:getHp() < 2 and sgs.getDefenseSlash(target, self) <= 2)) then
    return "kuanggu"
  end
  if need_tieqi then
    return "tieqi"
  end
  if can_liegong then
    return "liegong"
  end
  if can_tieqi then--烈弓再找不到目标
    return "tieqi"
  end
  if lord_longdan then
    return "longdan"
  end
  if can_kuanggu then
    return "kuanggu"
  end
  if can_wusheng then
    return "wusheng"
  end
  if can_longdan then
    return "longdan"
  end
  Global_room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat()))..":！！眩惑无可选技能！！")
  return choices[#choices]--一般是狂骨？没有目标选可以这个
end

--武圣
sgs.ai_view_as.wusheng_xh = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) and (player:getLord() and player:getLord():hasShownSkill("shouyue") or card:isRed()) and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:wusheng_xh[%s:%s]=%d&wusheng_xh"):format(suit, number, card_id)
	end
end

local wusheng_xh_skill = {}
wusheng_xh_skill.name = "wusheng_xh"
table.insert(sgs.ai_skills, wusheng_xh_skill)
wusheng_xh_skill.getTurnUseCard = function(self, inclusive)

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
			local card_str = ("slash:wusheng_xh[%s:%s]=%d&wusheng_xh"):format(suit, number, card_id)
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

sgs.ai_suit_priority.wusheng_xh = "club|spade|heart|diamond"

--咆哮
sgs.ai_skill_invoke.paoxiao_xh = true

--龙胆
local longdan_xh_skill = {}
longdan_xh_skill.name = "longdan_xh"
table.insert(sgs.ai_skills, longdan_xh_skill)
longdan_xh_skill.getTurnUseCard = function(self)
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
	local card_str = ("slash:longdan_xh[%s:%s]=%d&longdan_xh"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.longdan_xh = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
		if card:isKindOf("Jink") then
			return ("slash:longdan_xh[%s:%s]=%d&longdan_xh"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:longdan_xh[%s:%s]=%d&longdan_xh"):format(suit, number, card_id)
		end
	end
end

--铁骑
sgs.ai_skill_invoke.tieqi_xh = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return false end
	return true
end

sgs.ai_skill_choice.tieqi_xh = function(self, choices, data)
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

--烈弓
sgs.ai_skill_invoke.liegong_xh = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then
		self.liegong_tg = target
		return true
	end
	return false
	--return not self:isFriend(target)
end

sgs.ai_skill_choice.liegong_xh = sgs.ai_skill_choice.liegong

--狂骨
sgs.ai_skill_invoke.kuanggu_xh = function(self, data)
	return true
end

sgs.ai_skill_choice.kuanggu_xh = function(self, choices)
	if self.player:getHp() <= 2 or not self:slashIsAvailable() or self.player:getMark("GlobalBattleRoyalMode") > 0
  and self.player:canRecover() then
		return "recover"
	end
	return "draw"
end

sgs.kuanggu_xh_keep_value = {
	Crossbow = 6,
  SixDragons = 6,
	OffensiveHorse = 6
}

--吴国太
local ganlu_skill = {}
ganlu_skill.name = "ganlu"
table.insert(sgs.ai_skills, ganlu_skill)
ganlu_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("GanluCard") then
		return sgs.Card_Parse("@GanluCard=.&ganlu")
	end
end

sgs.ai_skill_use_func.GanluCard = function(card, use, self)
	local lost_hp = self.player:getLostHp()
	local target, min_friend, max_enemy

	local compare_func = function(a, b)
		return a:getEquips():length() > b:getEquips():length()
	end
	table.sort(self.enemies, compare_func)
	table.sort(self.friends, compare_func)

	self.friends = sgs.reverse(self.friends)

	for _, friend in ipairs(self.friends) do
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasShownSkills(sgs.lose_equip_skill) then
				local ee = enemy:getEquips():length()
				local fe = friend:getEquips():length()
				local value = self:evaluateArmor(enemy:getArmor(),friend) - self:evaluateArmor(friend:getArmor(),enemy)
					- self:evaluateArmor(friend:getArmor(),friend) + self:evaluateArmor(enemy:getArmor(),enemy)
				if math.abs(ee - fe) <= lost_hp and ee > 0 and (ee > fe or ee == fe and value>0) then
					if friend:hasShownSkills(sgs.lose_equip_skill) then
						use.card = card
						if use.to then
							use.to:append(friend)
							use.to:append(enemy)
						end
						return
					elseif not min_friend and not max_enemy then
						min_friend = friend
						max_enemy = enemy
					end
				end
			end
		end
	end
	if min_friend and max_enemy then
		use.card = card
		if use.to then
			use.to:append(min_friend)
			use.to:append(max_enemy)
		end
		return
	end

	target = nil
	for _, friend in ipairs(self.friends) do
		if self:needToThrowArmor(friend) or (friend:hasShownSkills(sgs.lose_equip_skill)	and not friend:getEquips():isEmpty()) then
				target = friend
				break
		end
	end
	if not target then return end
	for _,friend in ipairs(self.friends) do
		if friend:objectName() ~= target:objectName() and math.abs(friend:getEquips():length() - target:getEquips():length()) <= lost_hp then
			use.card = card
			if use.to then
				use.to:append(friend)
				use.to:append(target)
			end
			return
		end
	end
end

--sgs.ai_use_priority.GanluCard = sgs.ai_use_priority.Dismantlement + 0.1
--过拆之前不合适,联军回血导致不能甘露太恶心了,但是改成联军之前又会导致在没有联军的时候先奇袭……
sgs.ai_use_priority.GanluCard = sgs.ai_use_priority.AllianceFeast + 0.1
sgs.dynamic_value.control_card.GanluCard = true

sgs.ai_card_intention.GanluCard = function(self,card, from, to)
	local compare_func = function(a, b)
		return a:getEquips():length() < b:getEquips():length()
	end
	table.sort(to, compare_func)
	for i = 1, 2, 1 do
		if to[i]:hasArmorEffect("silver_lion") then
			sgs.updateIntention(from, to[i], -20)
			break
		end
	end
	if to[1]:getEquips():length() < to[2]:getEquips():length() then
		sgs.updateIntention(from, to[1], -80)
	end
end

sgs.ai_skill_invoke.buyi = true

sgs.ai_skill_choice.startcommand_buyi= sgs.ai_skill_choice.startcommand_to

sgs.ai_skill_choice["docommand_buyi"] = function(self, choices, data)
  local source = data:toPlayer()
  local index = self.player:getMark("command_index")
  local is_enemy = self:isEnemy(source)
  local is_friend = self:isFriend(source)
  local has_peach = false
  local count = 0
  for _, c in sgs.qlist(self.player:getHandcards()) do
    if isCard("Peach", c, self.player) then--有实体卡桃可回血
      has_peach = true
    end
    if c:isAvailable(self.player) then
      count = count + 1
    end
  end

  if index == 1 then
    if not is_enemy and not is_friend then
      return "yes"
    end
    if is_friend and not self:isWeak(source) then
      for _, p in ipairs(self.enemies) do
        if p:getHp() == 1 and self:isWeak(p) and self:isEnemy(source, p) then
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
  if index == 2 and not is_friend then
    return "yes"
  end
  if index == 3 and is_enemy and (self.player:getHp() > (has_peach and 1 or 2)
      or self.player:isRemoved() or (self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty())) then
    return "yes"
  end
  if index == 4 then
    if self.player:getMark("command4_effect") > 0 then
      return "yes"
    end
    if not is_friend and count < 3 then
      return "yes"
    end
  end
  if index == 5 then
    if not self.player:faceUp() then
      return "yes"
    end
    if self.player:hasSkill("jushou") and self.player:getPhase() <= sgs.Player_Finish then
      return "yes"
    end
  end
  if index == 6 and is_enemy and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 then
    return "yes"
  end
  return "no"
end

sgs.ai_skill_playerchosen["command_buyi"] = sgs.ai_skill_playerchosen.damage

--陆抗
sgs.ai_skill_invoke.keshou = function(self, data)
  local no_friend = true
  for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:isFriendWith(p) then
      no_friend = false
      break
    end
	end
  if self.player:getHp() < 3 or self.player:getHandcardNum() > 3 or no_friend or self.player:getMark("GlobalBattleRoyalMode") > 0 then
    return true
  end
  return false
end

sgs.ai_skill_cardask["@keshou"] = function(self, data, pattern, target, target2)
	if self.player:getHandcardNum() < 2 then--缺手牌
    return "."
  end

  if self.player:hasSkill("tianxiang")
  and not (self.player:hasFlag("tianxiang1used") and self.player:hasFlag("tianxiang2used")) then--配合小乔
    for _,card in sgs.qlist(self.player:getHandcards()) do
      if card:getSuit() == sgs.Card_Heart or (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade) then
        return "."
      end
    end
  end

  local damage = data:toDamage()
  if not self:damageIsEffective_(damage) then
    return "."
  end
  if damage.damage > 1 and self.player:hasArmorEffect("SilverLion") then--无视防具？
    return "."
  end

	if damage.damage == 1 and (self:needToLoseHp(self.player, damage.from, damage.card and damage.card:isKindOf("Slash"), true)
		or self:needDamagedEffects(self.player, damage.from,  damage.card and damage.card:isKindOf("Slash"))) then return "." end--提供结姻目标等
	if self.player:isChained() and damage.nature ~= sgs.DamageStruct_Normal and not damage.chain then
		--连环传导起点考虑不发动(例如火攻自己)
		if self:isGoodChainTarget(self.player, damage.from, damage.nature) and not (damage.from and self:isEnemy(damage.from)) then
			return "."
		end
	end

  local function canKeshouDiscard(card)
    if isCard("Peach", card, self.player) or (card:isKindOf("Analeptic") and self.player:getHp() == 1) then
      return false
    end
    return true
  end

  local cards = self.player:getHandcards() -- 获得所有手牌
  cards=sgs.QList2Table(cards) -- 将列表转换为表
  local keshou_cards = {}
  if self.player:getHandcardNum() == 2  then--两张手牌的情况
    if cards[1]:sameColorWith(cards[2]) and canKeshouDiscard(cards[1]) and canKeshouDiscard(cards[2]) then
      table.insert(keshou_cards, cards[1]:getId())
      table.insert(keshou_cards, cards[2]:getId())
      return "$" .. table.concat(keshou_cards, "+")
    end
  else--三张及以上手牌
    self:sortByKeepValue(cards) -- 按保留值排序
    if cards[1]:sameColorWith(cards[2]) and canKeshouDiscard(cards[1]) and canKeshouDiscard(cards[2]) then
      table.insert(keshou_cards, cards[1]:getId())
      table.insert(keshou_cards, cards[2]:getId())
      return "$" .. table.concat(keshou_cards, "+")
    elseif cards[1]:sameColorWith(cards[3]) and canKeshouDiscard(cards[1])and canKeshouDiscard(cards[3]) then
      table.insert(keshou_cards, cards[1]:getId())
      table.insert(keshou_cards, cards[3]:getId())
      return "$" .. table.concat(keshou_cards, "+")
    elseif cards[2]:sameColorWith(cards[3]) and canKeshouDiscard(cards[2]) and canKeshouDiscard(cards[3]) then
      table.insert(keshou_cards, cards[2]:getId())
      table.insert(keshou_cards, cards[3]:getId())
      return "$" .. table.concat(keshou_cards, "+")
    end
  end
  return "."
end
--蒋干回合防盗书0牌不应发动筑围
sgs.ai_skill_invoke.zhuwei= sgs.ai_skill_invoke.tiandu
--[[
sgs.ai_skill_invoke.zhuwei= function(self, data)
    if not self:willShowForDefence() then
		  return false
  	end
    return true
end
--]]
sgs.ai_skill_choice.zhuwei = function(self, choices, data)
  local target = self.room:getCurrent()
  if self:isFriend(target) then
    return "yes"
  else
    return "no"
  end
end

sgs.ai_slash_prohibit.zhuwei = sgs.ai_slash_prohibit.tiandu--考虑天香配合？

--张绣
sgs.ai_skill_playerchosen.fudi_damage = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_exchange.fudi= function(self,pattern,max_num,min_num,expand_pile)
    if not self:willShowForMasochism() or self.player:isKongcheng() then
        return {}
    end

    local cards = self.player:getHandcards() -- 获得所有手牌
    cards=sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    if cards[1]:isKindOf("Peach") then
        return {}
    end

	local from = self.player:getTag("FudiTarget"):toPlayer()
  local visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), from:objectName())

	local x = self.player:getHp()

	local targets = sgs.SPlayerList()

	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not from:isFriendWith(p) or p:getHp() < x then
			continue
		end
		if p:getHp() > x then--伤害无效也算血量目标
			targets = sgs.SPlayerList()
		end
		x = p:getHp()
		targets:append(p)
	end

	if targets:isEmpty() then return {} end

	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and self:damageIsEffective(target, nil, self.player) and not self:needDamagedEffects(target, self.player)
		and not self:needToLoseHp(target, self.player) then
        if not cards[1]:hasFlag("visible") then cards[1]:setFlags(visibleflag) end--记录已知牌
			return cards[1]:getId()
		end
	end
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) and self:damageIsEffective(target, nil, self.player)
		and (self:needDamagedEffects(target, self.player) or self:needToLoseHp(target, self.player, nil, true)) then
      if not cards[1]:hasFlag("visible") then cards[1]:setFlags(visibleflag) end--记录已知牌
			return cards[1]:getId()
		end
	end

  return {}
end

function sgs.ai_slash_prohibit.fudi(self, from, to)--杀禁止
	if self:isFriend(to, from) then return false end
	if to:isKongcheng() then return false end
  if to:getPhase() ~= sgs.Player_NotActive then return false end
  if from:getHp() >= 3 or (to:getHp() - from:getHp() > 1) then return false end
  if from:hasSkills("tieqi|tieqi_xh|yinbing") then return false end
  self:sort(self.friends_noself,"hp", true)
  for _, friend in ipairs(self.friends_noself) do
    if friend:getHp() > from:getHp() and from:isFriendWith(friend) and friend:isAlive() then
      if friend:getHp() >=3 or (friend:getHandcardNum() + friend:getHp() > 4) then
        return false
      end
    end
  end
	return (from:getHandcardNum() + from:getHp()) - math.min(to:getHp(), to:getHandcardNum()) < 4
end

sgs.ai_need_damaged.fudi = function(self, attacker, player)--主动卖血
	if not attacker or self:isFriend(attacker) then return end
  if self.player:getPhase() ~= sgs.Player_NotActive then
    return false
  end
	if self:isEnemy(attacker) and attacker:getHp() >= (self.player:getHp() - 1) and self:isWeak(attacker) and self:damageIsEffective(attacker, nil, self.player)
		and not (attacker:hasShownSkill("buqu")) and sgs.isGoodTarget(attacker, self:getEnemies(attacker), self) then
		return true
	end
	return false
end

function sgs.ai_cardneed.fudi(to, card, self)
	return to:isKongcheng() and not self:needKongcheng(to)
end

sgs.ai_skill_invoke.congjian = function(self, data)
  if self.player:getPhase() ~= sgs.Player_NotActive then
    return false
  end
  local target = data:toDamage().to
	return not self:isFriend(target)
end

--袁术
local weidi_skill = {}
weidi_skill.name = "weidi"
table.insert(sgs.ai_skills, weidi_skill)
weidi_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("WeidiCard") then
		return sgs.Card_Parse("@WeidiCard=.&weidi")
	end
	return nil
end

sgs.ai_skill_use_func["WeidiCard"] = function(card, use, self)
  local target
	local targets = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("WeidiHadDrawCards") and p:objectName() ~= self.player:objectName() then
			table.insert(targets, p)
		end
	end
	if #targets > 0 then
    self:sort(targets, "handcard", true)
    target = targets[1]
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.WeidiCard = 5

sgs.ai_skill_choice.startcommand_weidi = sgs.ai_skill_choice.startcommand_to

sgs.ai_skill_choice["docommand_weidi"] = function(self, choices, data)
  local source = data:toPlayer()
  local index = self.player:getMark("command_index")
  local is_enemy = self:isEnemy(source)
  local is_friend = self:isFriend(source)
  local has_peach = false
  local valuable_count = 0
  for _, c in sgs.qlist(self.player:getHandcards()) do
    if isCard("Peach", c, self.player) then--有实体卡桃可回血
      has_peach = true
    end
    if self:getUseValue(c) >= sgs.ai_use_value.Peach then
      valuable_count = valuable_count + 1
    end
  end

  if index == 1 then
    if not is_enemy then
      return "yes"
    end
    if is_enemy and has_peach then
      return "yes"
    end
  end
  if index == 2 then
    if not is_friend and self.player:getHandcardNum() < 2 then
      return "no"
    end
    return "yes"
  end
  if index == 3 and not is_friend and (has_peach or self.player:isRemoved()
      or (self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty())) then
    return "yes"
  end
  if index == 4 and self.player:getMark("command4_effect") > 0 then
    return "yes"
  end
  if index == 4 and not is_friend then
    if self:slashIsAvailable(source) and source:canSlash(self.player, nil, true)
    and self.player:getHp() == 1 and self:isWeak() then
      return "no"
    end
    if not has_peach and valuable_count < 3 then
      return "no"
    end
    return "yes"
  end
  if index == 5 then
    if not self.player:faceUp() then
      return "yes"
    end
    if is_enemy and valuable_count > 2 then
      return "yes"
    end
  end
  if index == 6 and is_enemy and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 then
    return "yes"
  end
  return "no"
end

sgs.ai_skill_playerchosen["command_weidi"] = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_exchange.weidi_give = function(self,pattern,max_num,min_num,expand_pile)
  local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("WeidiTarget") then
			to = p
			break
		end
	end
  local visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), to:objectName())
  local weidi_give = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
  if self.player:getCardCount(true) - max_num > 1 then--余下较多牌
    self:sortByUseValue(cards,true)
  else
    self:sortByKeepValue(cards)
  end

  local function weidi_insert(card)--判断并防止重复
    local c_id = card:getEffectiveId()
    if #weidi_give < max_num and not table.contains(weidi_give, c_id) then
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end--记录已知牌
      table.insert(weidi_give, c_id)
    end
  end

  if self:isFriend(to) then
    if self.player:getHp() > 1 and self:isWeak(to) and self:getCardsNum("Analeptic") > 0 then
      weidi_insert(self:getCard("Analeptic"))
    end
    if not self:isWeak() and self:isWeak(to) and self:getCardsNum("Peach") > 0 then
      weidi_insert(self:getCard("Peach"))
    end
    local c, friend = self:getCardNeedPlayer(cards, {to})
    if friend and friend:objectName() == to:objectName() then
      weidi_insert(c)
    end
    if self:getCardsNum("Jink") > 1 then
      weidi_insert(self:getCard("Jink"))
    end
    if self:getCardsNum("Slash") > 1 and not self:hasCrossbowEffect() then
      weidi_insert(self:getCard("Slash"))
    end
  end
  for _, c in ipairs(cards) do
    weidi_insert(c)
  end
	return weidi_give
end

sgs.ai_skill_invoke.yongsi = false--明牌负面效果

--君曹操
local huibian_skill = {}
huibian_skill.name = "huibian"
table.insert(sgs.ai_skills, huibian_skill)
huibian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("HuibianCard") then return end
	return sgs.Card_Parse("@HuibianCard=.&huibian")
end

sgs.ai_skill_use_func.HuibianCard = function(card, use, self)
	--Global_room:writeToConsole("使用挥鞭")
  local can_huibian = false
  local maixueskills = {"fangzhu","yiji","wangxi","bushi","shicai","zhiyu"}--不同卖血技能有优先顺序，是否可以用need_damage判断
  local drawcard_target, recover_target
  local targets = {}
  self:sort(self.friends, "hp")--从小到大排序
  for _, friend in ipairs(self.friends) do
    if friend:getSeemingKingdom() == "wei" then
      table.insert(targets,friend)
    end
    if friend:getSeemingKingdom() == "wei" and friend:isWounded() then
      can_huibian = true
    end
  end
  if #targets < 2 or not can_huibian then return end

  local xunyu = sgs.findPlayerByShownSkillName("jieming")
  if xunyu and xunyu:getSeemingKingdom() == "wei" then
    local jieming_dnum= self:getJiemingDrawNum(self.player)
    if jieming_dnum >= 3 then
      table.insert(maixueskills, 1, "jieming")--3牌以上放到首位
    elseif jieming_dnum == 2 then
      table.insert(maixueskills, 3, "jieming")--2牌放到3位
    elseif jieming_dnum == 1 then
      table.insert(maixueskills, 5, "jieming")--1牌放到5位
    end
  end
  local huaxin = sgs.findPlayerByShownSkillName("wanggui")
  if huaxin and huaxin:getSeemingKingdom() == "wei" and not huaxin:hasFlag("WangguiUsed") then
    local wanggui_dnum = 0
    if huaxin:hasShownAllGenerals() then
      wanggui_dnum = self.player:getPlayerNumWithSameKingdom("AI", "wei")
    else
      wanggui_dnum = -1
    end
    if wanggui_dnum == -1 then
      if #self.enemies > 0 then
        for _, p in ipairs(self.enemies) do
          if self:isWeak(p) then
            table.insert(maixueskills, 1, "wanggui")--虚弱打伤害放到首位
          end
        end
        table.insert(maixueskills, 5, "wanggui")
      end
    elseif wanggui_dnum >= 3 then
      table.insert(maixueskills, 1, "wanggui")
    elseif wanggui_dnum == 2 then
      table.insert(maixueskills, 3, "wanggui")
    elseif wanggui_dnum == 1 then
      table.insert(maixueskills, 5, "wanggui")
    end
  end

  if self.player:getHp() == 1 and self:isWeak() and self.player:canRecover() then--保君主
    recover_target = self.player
    table.removeOne(targets, self.player)
  end
  for _, p in ipairs(targets) do
    if self:isWeak(p) and p:canRecover() and not recover_target and p:hasShownSkills(sgs.priority_skill) then--先回复重要队友
      recover_target = p
      table.removeOne(targets,p)
      break
    end
  end

  if not recover_target then
    for _, p in ipairs(targets) do
      if self:isWeak(p) and p:canRecover() and not recover_target then
        recover_target = p
        table.removeOne(targets,p)
        break
      end
    end
  end

  if not recover_target then
    for _, p in ipairs(targets) do
      if p:canRecover() and not recover_target then
        recover_target = p
        table.removeOne(targets,p)
        break
      end
    end
  end

  for _, skill in ipairs(maixueskills) do--还可以细化条件，如放逐
    for _, p in ipairs(targets) do
      if p:hasShownSkill(skill) and not drawcard_target and not self:willSkipPlayPhase(p)
      and (p:getHp() > (targets[#targets]:getHp() > 3 and 2 or 1) or (self:getAllPeachNum() +  getKnownCard(p, self.player, "Analeptic", true, "he") > 1)) then
        drawcard_target = p
        table.removeOne(targets,p)
      end
    end
  end

  if not drawcard_target then
    if targets[#targets]:getHp() > 1 or (self:getAllPeachNum() +  getKnownCard(targets[#targets], self.player, "Analeptic", true, "he") > 1) then
      drawcard_target =  targets[#targets]
      table.removeOne(targets,targets[#targets])
    end
  end

  if drawcard_target and recover_target then
    --Global_room:writeToConsole("抽卡目标:"..sgs.Sanguosha:translate(drawcard_target:getGeneralName()).."/"..sgs.Sanguosha:translate(drawcard_target:getGeneral2Name()))
    --Global_room:writeToConsole("回血目标:"..sgs.Sanguosha:translate(recover_target:getGeneralName()).."/"..sgs.Sanguosha:translate(recover_target:getGeneral2Name()))
	  use.card = card
    if use.to then
      use.to:append(drawcard_target)
      use.to:append(recover_target)
    end
  end
end

sgs.ai_use_priority.HuibianCard = 5--优先度多少合适？

sgs.ai_skill_invoke.zongyu = true

--五子良将纛
local function shouldUseJiananByValue(self, name)
	local is_head = (self.player:getActualGeneral1Name() == name)
	local players_num = self.room:alivePlayerCount()
	local round_num,round_friend_num,round_enemy_num = 0,0,0
	if self.player:hasSkill("jianan") then
		round_num = players_num - 1
		round_friend_num = self.player:getPlayerNumWithSameKingdom("AI") - 1
		round_enemy_num = players_num - self.player:getPlayerNumWithSameKingdom("AI")
	else
		local lord_caocao = sgs.findPlayerByShownSkillName("jianan")
		round_num = self:playerGetRound(self.player, lord_caocao)
		round_enemy_num = self:getEnemyNumBySeat(self.player, lord_caocao)
		round_friend_num = self:getFriendNumBySeat(self.player, lord_caocao)
	end
	local v = 0
	--五子良将纛武将值:甄姬9,曹真9,郭淮7,许褚6
	if self.player:isDuanchang(is_head) or (is_head and not self.player:canShowGeneral("h")) or (not is_head and not self.player:canShowGeneral("d")) then
		v = - 1
	elseif sgs.general_value[name] and not (name == "zhenji") then
		if name == "caozhen" then
			if round_enemy_num == 0 then
				v = 2*(self.player:getPile("drive"):length())
			else
				v = 5 + math.max(self.player:getPile("drive"):length(),round_enemy_num)*2
			end
		elseif name == "dengai" then
			if self.player:hasSkill("jixi") then
				v = 4*(self.player:getPile("field"):length()) + round_enemy_num
			else
				v = 2*(self.player:getPile("field"):length()) + round_enemy_num
			end
		elseif name == "guohuai" then
			local drawcardnum = self:imitateDrawNCards(self.player, self.player:getVisibleSkillList(true))
			local to_use = drawcardnum/2
			local jingce_value = math.min(self.player:getLostHp(),self:getCardsNum("Peach"))
			for _,c in sgs.qlist(self.player:getCards("h")) do
				local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useCardByClassName(c,dummy_use)
				if dummy_use.card then
					to_use = to_use + 1
				end
			end
			if to_use < self.player:getHandcardNum() + drawcardnum then
				for _,skill in sgs.qlist(self.player:getVisibleSkillList(true)) do
					if skill:inherits("ViewAsSkill") or (skill:inherits("TriggerSkill") and not skill:canPreshow()) then
						to_use = to_use + 1
						if to_use >= self.player:getHandcardNum() + drawcardnum then break end
					end
				end
			end
			if to_use - self.player:getHp() >= 0 then
				if not self:isWeak() then
					jingce_value = (jingce_value + 1)/2
					Global_room:writeToConsole("多牌精策修正:"..tostring(jingce_value))
				elseif jingce_value == 0 then
					jingce_value = 0.8
					Global_room:writeToConsole("无桃精策修正:"..tostring(jingce_value))
				end
			else
				jingce_value = 1/self.player:getHp()
				Global_room:writeToConsole("少牌精策修正:"..tostring(jingce_value))
			end
			v = sgs.general_value[name]*jingce_value
			Global_room:writeToConsole("精策修正价值:"..tostring(v))
		elseif name == "xiahoudun" then--夏侯惇不值8
			if self:isWeak() then
				v = 2*round_enemy_num
			else
				v = 2*round_friend_num/math.max(round_num,1)
			end
		elseif name == "yujin" then
			v = - 1
		else
			v = sgs.general_value[name]
		end
	else
		if not sgs.general_value[name] then v = v + 4 end
		--司马凭什么价值8……
		local before_skill = "luoshen|jieyue"
		for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(name):getVisibleSkillList(true, is_head)) do
			if before_skill:match(skill:objectName()) then v = v - 1 continue end
			if sgs.priority_skill:match(skill:objectName()) then
				v = v + 3*(players_num-round_num)/players_num
			elseif sgs.Active_cardneed_skill:match(skill:objectName()) then
				v = v + 2
			elseif sgs.notActive_cardneed_skill:match(skill:objectName()) then
				v = v + 2*round_enemy_num/math.max(round_num,1)
			elseif sgs.masochism_skill:match(skill:objectName()) then
				if self:isWeak() then
					v = v + 2*round_enemy_num
				else
					v = v + 2*round_friend_num/math.max(round_num,1)
				end
			elseif sgs.defense_skill:match(skill:objectName()) then
				if self:isWeak() then
					v = v + 2*round_enemy_num
				else
					v = v + 2*round_enemy_num/math.max(round_num,1)
				end
			elseif skill:inherits("BattleArraySkill") then
				local NP = self.player:getNextAlive()
				local LP = self.player:getLastAlive()
				if NP:isFriendWith(LP) then
					if skill:objectName() == "fangyuan" and not self.player:isFriendWith(NP) then
						local slash = sgs.cloneCard("slash")
						if (self.player:canSlash(NP, slash, true) and self:slashIsEffective(slash, NP) and not self:slashProhibit(nil, NP))
							or (self.player:canSlash(LP, slash, true) and self:slashIsEffective(slash, LP) and not self:slashProhibit(nil, LP)) then
							--current:inSiegeRelation(self.player, self.player)
							v = v + 2
						end
					elseif self.player:isFriendWith(NP) then
						v = v + self.player:getFormation()
					end
				end
			elseif skill:inherits("ViewAsSkill") or (skill:inherits("TriggerSkill") and not skill:canPreshow()) then
				v = v + 2
			elseif skill:inherits("LuaViewAsSkill") or skill:inherits("LuaTriggerSkill") then
				v = v + 2
			else
				v = v + 1
			end
		end
	end
	Global_room:writeToConsole("五子良将纛武将值:"..sgs.Sanguosha:translate(name)..tostring(v))
	if v < (self.player:getHandcardNum() < 3 and 6 or 7) then
		return true
	end
	if not self.player:hasSkill("qiaobian") and self.player:containsTrick("indulgence")
		and self:getFinalRetrial() ~= 1 and self:getOverflow() > (v - 5) then
		--曹丕价值11,但是如果能跳乐多存6张应该也是值得的
		local jianan_skills = {"tuxi", "qiaobian", "xiaoguo", "jieyue", "duanliang"}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			for _, skill in ipairs(jianan_skills) do
				if p:hasShownSkill(skill) or p:hasShownSkill(skill .. "_egf") then
					table.removeOne(jianan_skills,skill)
				end
			end
		end
		if self.player:hasSkill("jieyue") then
			table.insert(jianan_skills ,"jieyue")
		end
		if #jianan_skills > 0 then
			local choice = sgs.ai_skill_choice.jianan_skill(self ,table.concat(jianan_skills,"+"))
			if choice == "qiaobian" then return true end
		end
	end
	--暗置求安函？
	return false
end

sgs.ai_skill_cardask["@elitegeneralflag"] = function(self, data, pattern, target, target2)
  local jianan_skills = {"tuxi", "qiaobian", "xiaoguo", "jieyue", "duanliang"}
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    for _, skill in ipairs(jianan_skills) do
      if p:hasShownSkill(skill) or p:hasShownSkill(skill .. "_egf") then
        table.removeOne(jianan_skills,skill)
      end
    end
  end
  if self.player:hasSkill("jieyue") then--和五子良将纛同一时机触发的技能，设置优先发动jieyue
	local jieyue_egf_use = false--于禁暗置时,其他队友先抢jieyue_egf的情况
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasShownSkill("jieyue_egf") then jieyue_egf_use = true break end
	end
	if not jieyue_egf_use then
		table.insert(jianan_skills ,"jieyue")
	end
  end
  if #jianan_skills == 0 and self.player:getMark("JieyueExtraDraw") < 1 then--没有技能可选，参考眩惑预选
	self.room:writeToConsole("五子良将纛没有可选的技能")
	return "."
  end
	local players_num = self.room:alivePlayerCount()
	local round_friend_num,round_enemy_num = 0,0
	if self.player:hasSkill("jianan") then
		round_friend_num = self.player:getPlayerNumWithSameKingdom("AI") - 1
		round_enemy_num = players_num - self.player:getPlayerNumWithSameKingdom("AI")
	else
		local lord_caocao = sgs.findPlayerByShownSkillName("jianan")
		round_friend_num = self:getFriendNumBySeat(self.player, lord_caocao)
		round_enemy_num = self:getEnemyNumBySeat(self.player, lord_caocao)
	end
  local choice = sgs.ai_skill_choice.jianan_skill(self ,table.concat(jianan_skills,"+"))
  self.room:writeToConsole("---五子良将纛预选技能:"..sgs.Sanguosha:translate(choice).."---")

  local allcards = sgs.QList2Table(self.player:getCards("he"))
  self:sortByUseValue(allcards, true)
  local discard = allcards[1]
  if self.player:getMark("JieyueExtraDraw") > 0 then
    if self.player:getCardCount(true) == 1 and isCard("Peach", allcards[1], self.player) and self:isWeak() then
      return "."
    end
    if #jianan_skills == 0 then
      if self.player:getCardCount(true) < 2
      or (isCard("Peach", allcards[2], self.player) and self:isWeak()) then
        return "."
      end
    end
    return discard:toString()
  end
  if (self.player:hasSkill(choice) and choice ~= "jieyue") then
    return "."
  end
  if self.player:isLord() and self.player:inHeadSkills("sidi") and not self.player:getPile("drive"):isEmpty() then
    return "."
  end
	if choice == "xiaoguo" then--骁果
		if self:isWeak() or self.player:getHandcardNum() < 3 or round_enemy_num <= 0 then return "." end
	end
	if (self.player:isLastHandCard(discard) and #allcards > 1) and (choice == "jieyue" 
		or (choice == "qiaobian" and (self.player:containsTrick("supply_shortage") or self.player:containsTrick("indulgence")))) then--最后一张手牌需要留做巧变节钺
		return allcards[2]:toString()
	end
  if self.player:hasSkills("qiaobian|qiaobian_egf") and choice == "tuxi" then
    return "."
  end
  if not isCard("Peach", discard, self.player) then
    local g1name = self.player:getActualGeneral1Name()
    local g2name = self.player:getActualGeneral2Name()
	if g1name == "yujin" or g2name == "yujin" then--
		if round_friend_num > 0 or self:getOverflow() > 0 then return discard:toString() end
	end
    if shouldUseJiananByValue(self, g1name) or shouldUseJiananByValue(self, g2name)
    or self.player:isDuanchang(true) or self.player:isDuanchang(false) then
      --self.room:writeToConsole("五子良将纛准备弃牌")
      return discard:toString()
    end
  end
	return "."
end
--有暗置武将牌时,不会触发jianan_hide
sgs.ai_skill_choice.jianan_hide = function(self, choices)
	--self.room:writeToConsole("五子良将纛暗置选项:"..choices)
	if self.player:hasSkill("jieyue") then
		if self.player:inHeadSkills("jieyue") then
			return "head"
		elseif self.player:inDeputySkills("jieyue") then
			return "deputy"
		end
	end

	local g1name = self.player:getActualGeneral1Name()
	local g2name = self.player:getActualGeneral2Name()
	local active_value = 5
	--副将曹丕大于3田主将邓艾……
	--[[
	“突袭”、“巧变”、“骁果”、“节钺”、“断粮”
	["zhangliao"] = 2.5
	["zhanghe"] = 3
	["yuejin"] = 2.5
	["xuhuang"] = 3
	--]]
	local v1 = sgs.general_value[g1name] or 5
	local v2 = sgs.general_value[g2name] or 5
	if self.player:isDuanchang(true) then
		v1 = 0
	end
	if self.player:isDuanchang(false) then
		v2 = 0
	end
	
	local active_v1,active_v2 = 0,0
	if self.player:hasShownSkills(sgs.Active_cardneed_skill) then
		local Acd = sgs.Active_cardneed_skill:split("|")
		for _, skill in ipairs(Acd) do
			if active_v1 >= 4 and active_v2 >= 4 then break end
			if not self.player:hasShownSkill(skill) then continue end
			if self.player:inHeadSkills(skill) then
				active_v1 = active_v1 + 2
			elseif self.player:inDeputySkills(skill) then
				active_v2 = active_v2 + 2
			end
		end
		v1 = v1 + active_v1
		v2 = v2 + active_v2
	elseif self.player:hasShownSkills(sgs.notActive_cardneed_skill) then
		local Ncd = sgs.notActive_cardneed_skill:split("|")
		for _, skill in ipairs(Ncd) do
			if active_v1 >= 2 and active_v2 >= 2 then break end
			if not self.player:hasShownSkill(skill) then continue end
			if self.player:inHeadSkills(skill) then
				active_v1 = active_v1 + 1
			elseif self.player:inDeputySkills(skill) then
				active_v2 = active_v2 + 1
			end
		end
		v1 = v1 + active_v1
		v2 = v2 + active_v2
	end
	if self.player:hasShownSkill("luoshen") then--甄姬值9-4
		if self.player:inHeadSkills("luoshen") and v2 >= 5 then--曹仁值5……
			v1 = v1 - 4
		elseif self.player:inDeputySkills("luoshen") and v1 >= 5 then
			v2 = v2 - 4
		end
	end
	if self.player:hasShownSkill("tuntian") then
		if self.player:inHeadSkills("tuntian") then
			v1 = v1 + self.player:getPile("field"):length()
		else
			v2 = v2 + self.player:getPile("field"):length() * 0.5
		end
	end
	if self.player:hasSkill("sidi") then
		if self.player:inHeadSkills("sidi") then
			v1 = v1 + self.player:getPile("drive"):length()
		else
			v2 = v2 + self.player:getPile("drive"):length()
		end
	end
	if shouldUseJiananByValue(self, g1name) and not shouldUseJiananByValue(self, g2name) then
		return "head"
	elseif shouldUseJiananByValue(self, g2name) and not shouldUseJiananByValue(self, g1name) then
		return "deputy"
	end
	--Global_room:writeToConsole("五子良将纛暗置:"..tostring(v1)..":"..tostring(v2))
	return v1 > v2 and "deputy" or "head"
end

sgs.ai_skill_choice.jianan_skill = function(self, skills)
	skills = skills:split("+")
	if (self.player:hasSkill("qiaobian") or self:willSkipDrawPhase()) and #skills > 1 then
    table.removeOne(skills, "tuxi")
  end
  if table.contains(skills, "tuxi") and self:findTuxiTarget() then--没牌时
    if self.player:isKongcheng() then
      return "tuxi"
    end
    if self.player:getMark("JieyueExtraDraw") > 0 and not (self:willSkipPlayPhase() and self:getOverflow() > 1) then--配合节钺
      return "tuxi"
    end
	end
  if table.contains(skills, "qiaobian") then--自己跳乐，为队友留跳乐，手牌较多时
    if self:willSkipPlayPhase() and self:getOverflow() > (self.player:getMark("JieyueExtraDraw") > 0 and 0 or 1) then--大于几合适？
      return "qiaobian"
    end
		if #skills > 1 then
      local lord_caocao = sgs.findPlayerByShownSkillName("jianan")
      for _, p in ipairs(self.friends_noself) do
        if self.player:isFriendWith(p) and self:playerGetRound(p, lord_caocao) > self:playerGetRound(self.player, lord_caocao)
        and ((self:willSkipPlayPhase(p) and self:getOverflow(p) > 1)
          or (self:getOverflow(p) > 3 and p:getHandcardNum() > self.player:getHandcardNum())) then
            table.removeOne(skills, "qiaobian")--考虑座次影响，经过曹操位置会重置选择
            break
        end
      end
    end
    local Nullification = false
		for _, p in ipairs(self.friends) do
			if getKnownCard(p, self.player, "Nullification") > 0 then
				Nullification = true
			end
		end
		local supply_shortage = (self.player:containsTrick("supply_shortage") and (not self:hasWizard(self.friends) or self:hasWizard(self.enemies, true)))
		local indulgence = (self.player:containsTrick("indulgence") and self:getFinalRetrial() ~= 1 and self:getOverflow() > -1)
		
		if (self:getOverflow() > (self.player:getMark("JieyueExtraDraw") > 0 and 2 or 4)--配合节钺(跳弃牌)
			--or (self:willSkipDrawPhase() and self.player:getMark("JieyueExtraDraw") > 0)--配合节钺(跳判定)
			--or (self:willSkipPlayPhase() and not self.player:isKongcheng()))--一般的被乐
			or (self.player:getCardCount(true) >= 2 and not self.player:isKongcheng() and not Nullification and (indulgence or supply_shortage)))
			and table.contains(skills, "qiaobian") then
			return "qiaobian"
		end
	end
	if table.contains(skills, "jieyue") and self.player:getCardCount(true) >= 2 then--能发动节钺时
		if sgs.ai_skill_use["@@jieyue"](self) ~= "." and not self:willSkipDrawPhase() then
			return "jieyue"
		elseif #skills > 1 then
			table.removeOne(skills, "jieyue")
		end
	end
  if table.contains(skills, "duanliang") then
    local duanliang_count = 0
    local kongcheng_enemy = 0
    local needcards_enemy = 0
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    for _, id in sgs.qlist(self.player:getHandPile()) do
      table.insert(cards, sgs.Sanguosha:getCard(id))
    end
    self:sortByUseValue(cards, true)
    for _,acard in ipairs(cards)  do
      if acard:isBlack() and (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard")) and (self:getUseValue(acard) < sgs.ai_use_value.SupplyShortage) then
        duanliang_count = duanliang_count + 1
      end
    end
    for _, p in ipairs(self.enemies) do
      if p:isKongcheng() then
        kongcheng_enemy = kongcheng_enemy + 1
      end
      if not p:isKongcheng() and p:getHandcardNum() < 3 then
        needcards_enemy = needcards_enemy + 1
      end
    end
    if duanliang_count > ((kongcheng_enemy > 0 or needcards_enemy > 1) and 0 or 1) then--数量多少合适？
      return "duanliang"
    end
    if duanliang_count == 0 and #skills > 1 then--预选时和选择时手牌不同怎么处理
      table.removeOne(skills, "duanliang")
    end
	end
  if table.contains(skills, "tuxi") and self:findTuxiTarget() then
    return "tuxi"
  end
  if self.player:hasShownAllGenerals() and table.contains(skills, "qiaobian") then--预选时去除巧变。处理预选手牌差异？
    local g1name = self.player:getActualGeneral1Name()
    local g2name = self.player:getActualGeneral2Name()
    if not shouldUseJiananByValue(self, g1name) and not shouldUseJiananByValue(self, g2name) then
      table.removeOne(skills, "qiaobian")
    end
    if #skills == 0 then--奇怪的预选处理，返回"null"用于预选？
      table.insert(skills, "xiaoguo")
    end
  end
  if self.player:getMaxCards() < 3 and #skills > 1 then
		table.removeOne(skills, "xiaoguo")
	end
  --没有合适的优先选突袭巧变？
	return skills[math.random(1, #skills)]
end

function sgs.ai_cardneed.elitegeneralflag(to, card)
	return to:isNude()
end

--突袭
sgs.ai_skill_playerchosen.tuxi_egf = sgs.ai_skill_playerchosen.tuxi

--巧变
sgs.ai_skill_discard.qiaobian_egf = sgs.ai_skill_discard.qiaobian

--骁果相同

--节钺
sgs.ai_skill_use["@@jieyue_egf"] = sgs.ai_skill_use["@@jieyue"]

--断粮
local duanliang_egf_skill = {}
duanliang_egf_skill.name = "duanliang_egf"
table.insert(sgs.ai_skills, duanliang_egf_skill)
duanliang_egf_skill.getTurnUseCard = function(self)
	if not self:willShowForAttack() then
		return nil
	end
  if self.player:hasFlag("DuanliangEGFCannot") then
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
	local card_str = ("supply_shortage:duanliang_egf[%s:%s]=%d%s"):format(suit, number, card_id, "&duanliang_egf")
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.duanliang_egf_suit_value = {
	spade = 3.9,
	club = 3.9
}
sgs.ai_suit_priority.duanliang_egf= "club|spade|diamond|heart"

--六龙骖驾
sgs.ai_use_priority.SixDragons = 2.70

--军令
--[[
  ["#command1"] = "军令一：对你指定的角色造成1点伤害",
	["#command2"] = "军令二：摸一张牌，然后交给你两张牌",
	["#command3"] = "军令三：失去1点体力",
	["#command4"] = "军令四：本回合不能使用或打出手牌且所有非锁定技失效",
	["#command5"] = "军令五：叠置，本回合不能回复体力",
	["#command6"] = "军令六：选择一张手牌和一张装备区里的牌，弃置其余的牌",
]]--
sgs.ai_skill_choice.startcommand_to = function(self, choices, data)--含目标的通用选择军令
  local target = data:toPlayer()
  Global_room:writeToConsole("选择军令:"..choices)
  choices = choices:split("+")
  if table.contains(choices, "command5") and not target:faceUp() then--特殊情况有优先顺序
    Global_room:writeToConsole("军令五的特殊情况")
    if self:isFriend(target) then
      return "command5"
    else
      for _, command in ipairs(choices) do
        if command ~= "command5" then
          return command
        end
      end
    end
  end
  if table.contains(choices, "command6") and target:getEquips():length() <= 1 and target:getHandcardNum() <= 1 then
    Global_room:writeToConsole("军令六的特殊情况")
    for _, command in ipairs(choices) do
      if command ~= "command6" then
        return command
      end
    end
  end
  if table.contains(choices, "command4") and target:getMark("command4_effect") > 0 then
    Global_room:writeToConsole("军令四的特殊情况")
    for _, command in ipairs(choices) do
      if command ~= "command4" then
        return command
      end
    end
  end
  if table.contains(choices, "command3") and (target:isRemoved() or (target:hasSkill("hongfa") and not target:getPile("heavenly_army"):isEmpty())) then
    Global_room:writeToConsole("军令三的特殊情况")
    for _, command in ipairs(choices) do
      if command ~= "command3" then
        return command
      end
    end
  end
  if self:isFriend(target) then
    local commands = {"command1", "command2", "command4", "command3", "command6", "command5"}--索引大小代表优先级，注意不是原顺序
    local command_value1 = table.indexOf(commands,choices[1])
    local command_value2 = table.indexOf(commands,choices[2])
    local index = math.min(command_value1,command_value2)
    return commands[index]
  else
    local commands = {"command2", "command3", "command4", "command1", "command6", "command5"}
    local command_value1 = table.indexOf(commands,choices[1])
    local command_value2 = table.indexOf(commands,choices[2])
    local index = math.max(command_value1,command_value2)
    return commands[index]
  end
end

sgs.ai_skill_choice.docommand_from = function(self, choices, data)
  local source = data:toPlayer()
  local index = self.player:getMark("command_index")
  return "no"
end

sgs.ai_skill_exchange.command = function(self,pattern,max_num,min_num,expand_pile)
  local card_give = {}
  local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("CommandSource") then
			to = p
			break
		end
	end
  local visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), to:objectName())

  local cards = self.player:getCards("he")
  cards = sgs.QList2Table(cards)
  local function card_insert(card)--判断并防止重复
    local c_id = card:getEffectiveId()
	--需要额外过滤,例如self:getCard("Slash")会拿到天兵,self:getCard("Peach")会拿到珠子等
    if #card_give < max_num and not table.contains(card_give, c_id) and table.contains(cards, c_id) then
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end--记录已知牌
      table.insert(card_give, c_id)
    end
  end
  if self.player:getPhase() <= sgs.Player_Play then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end
  if self:isFriend(to) then
    if self.player:getHp() > 1 and self:isWeak(to) and self:getCardsNum("Analeptic") > 0 then
      card_insert(self:getCard("Analeptic"))
    end
    if not self:isWeak() and self:isWeak(to) and self:getCardsNum("Peach") > 0 then
      card_insert(self:getCard("Peach"))
    end
    local c, friend = self:getCardNeedPlayer(cards, {to})
    if friend and friend:objectName() == to:objectName() then
      card_insert(c)
    end
    if self:getCardsNum("Jink") > 1 then
      card_insert(self:getCard("Jink"))
    end
    if self:getCardsNum("Slash") > 1 and not self:hasCrossbowEffect() then
      card_insert(self:getCard("Slash"))
    end
  end

  for _, c in ipairs(cards) do
    card_insert(c)
  end
	return card_give
end

sgs.ai_skill_cardask["@command-select"] = function(self, data, pattern, target, target2)
  local selected_h, selected_e
  if not self.player:isKongcheng() then
    local hcards = self.player:getCards("h")
    hcards = sgs.QList2Table(hcards)
    if self.player:getPhase() <= sgs.Player_Play then
      self:sortByUseValue(hcards)
    else
      self:sortByKeepValue(hcards, true)
    end
    selected_h = hcards[1]
  end
  if self.player:hasEquip() then
    local equips = sgs.QList2Table(self.player:getCards("e"))
    if self.player:getPhase() <= sgs.Player_Play then
      self:sortByUseValue(equips)
    else
      self:sortByKeepValue(equips, true)
    end
    selected_e = equips[1]
  end
  if selected_h and selected_e then
    local selected_cards = {}
    table.insert(selected_cards, selected_h:getId())
    table.insert(selected_cards, selected_e:getId())
    return "$" .. table.concat(selected_cards, "+")
  elseif selected_h then
    return "$" .. selected_h:getEffectiveId()
  elseif selected_e then
    return "$" .. selected_e:getEffectiveId()
  end
  return "."
end