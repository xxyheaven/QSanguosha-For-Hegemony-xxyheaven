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
--海外版专属

--卑弥呼
local guishu_skill = {}
guishu_skill.name = "guishu"
table.insert(sgs.ai_skills, guishu_skill)
guishu_skill.getTurnUseCard = function(self)
    local spadecards = {}
    local cards = self.player:getHandcards()
    for _, id in sgs.qlist(self.player:getHandPile()) do
        cards:prepend(sgs.Sanguosha:getCard(id))
    end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade then
            table.insert(spadecards, card)
        end
    end
    if #spadecards == 0 then
        return
    end
    local trickcards = {"befriend_attacking","known_both"}--有优先顺序
    local index = 3 - self.player:getMark("GuishuCardState")
    if index == 3 then--初始状态
        index = 1
    end
    if trickcards[index] == "known_both" and self:getUseValue(spadecards[1]) > sgs.ai_use_value.KnownBoth then
        return--#spadecards < 2 每回合不重置
    end
    --Global_room:writeToConsole("鬼术卡类型:"..trickcards[index])
    return sgs.Card_Parse("@GuishuCard=" ..  spadecards[1]:getEffectiveId() .. ":" .. trickcards[index])
end

sgs.ai_skill_use_func.GuishuCard = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
    local guishucard = sgs.cloneCard(userstring, card:getSuit(), card:getNumber())
    guishucard:setCanRecast(false)
    if self.player:isCardLimited(guishucard, sgs.Card_MethodUse) then
        return
    end
    self:useCardByClassName(guishucard, use)--确保能使用
    if use.card then--and use.to and not use.to:isEmpty() 如果有use.to会使用虚拟牌，为何？
		Global_room:writeToConsole("鬼术卡使用:"..userstring)
		use.card = card
	end
end

sgs.ai_use_priority.GuishuCard = sgs.ai_use_priority.BefriendAttacking + 0.1
sgs.ai_use_value.GuishuCard = sgs.ai_use_value.BefriendAttacking

sgs.guishu_suit_value = {
	spade = 3.9
}

sgs.ai_skill_invoke.yuanyu = true

--曹真
sgs.ai_skill_invoke.sidi = function(self, data)
    if not self:willShowForDefence() then
        return false
    end
    local target = data:toPlayer()
    if not self:isFriend(target) then
        return true
    end
    local num = 0
    for _, card in sgs.qlist(target:getHandcards()) do
		if not sgs.cardIsVisible(card, target, self.player)
        or not (isCard("Peach", card, self.player) or (card:isKindOf("Analeptic") and target:getHp() == 1)) then
			num = num + 1
		end
	end
    if self:needToThrowArmor(target) then
        num = num + 1
    end
    if target:getWeapon() and target:getOffensiveHorse() then
        num = num + 1
    end
    if num == 0 then
        return false
    end
    return true
end

sgs.ai_skill_exchange.sidi = function(self,pattern,max_num,min_num,expand_pile)
    self.sidi_recover = nil
    self.sidi_skill = nil
    self.sidi_cardtype = nil

    local drivecards = {}
    local drivetypes = {}
    for _, id in sgs.qlist(self.player:getPile(expand_pile)) do--"drive"
        local card = sgs.Sanguosha:getCard(id)
        table.insert(drivecards, card)
        table.insert(drivetypes, sgs.ai_type_name[card:getTypeId() + 1])
    end

    local current = self.room:getCurrent()
    if self:isFriend(current) then
        self:sort(self.friends, "hp")--从小到大排序
        for _, friend in ipairs(self.friends) do
            if self.player:isFriendWith(friend) and friend:getHp() == 1 then
                self.sidi_recover = true
                for _, c in ipairs(drivecards) do
                    if sgs.ai_type_name[c:getTypeId() + 1] == "EquipCard" then
                        return c:getId()
                    end
                end
                return drivecards[1]:getId()
            end
        end
    end
    if self:isEnemy(current) and (not self:willSkipPlayPhase(current) or self.player:getPile("drive"):length() > 2) then
--禁卡
        if getCardsNum("TrickCard", current, self.player) > (current:hasShownSkill("jizhi") and 1 or 2)
        or (current:hasShownSkills("guose|luanji|guishu") and current:getHandcardNum() > 1)
        or (current:hasShownSkill("jixi") and current:getPile("field"):length() > 1)
        or (current:hasShownSkills("qice|yigui")) then
            if table.contains(drivetypes, "TrickCard") then
                self.sidi_cardtype = "TrickCard"
            end
        end
        if current:hasShownSkills("diaodu+xiaoji|diaodu+xuanlue") then
            if table.contains(drivetypes, "EquipCard") then
                self.sidi_cardtype = "EquipCard"
            end
        end
        if (current:getHp() == 1 and self:isWeak(current) and current:getMark("GlobalBattleRoyalMode") == 0)
        or ((self:hasCrossbowEffect(current) or current:hasShownSkills(sgs.force_slash_skill))
                and getCardsNum("Slash", current, self.player) >= 1) then
            if table.contains(drivetypes, "BasicCard") then
                self.sidi_cardtype = "BasicCard"
            end
        end
        for _, friend in ipairs(self.friends) do
            if current:canSlash(friend, nil, true) and sgs.getDefenseSlash(friend, self) <= 2 then
                if table.contains(drivetypes, "BasicCard") then
                    self.sidi_cardtype = "BasicCard"
                end
                break
            end
        end
--技能
        local function findskill(skills)
            for _, skill in ipairs(skills:split("|")) do
                if current:hasShownSkill(skill) then
                    return skill
                end
            end
            return nil
        end
        local sidi_firstskills =--注意有优先顺序
                "suzhi|jinghe|miewu|jieyue|jili|tongdu|chuli|wansha|zaoyun|jinfa|yingzi_zhouyu|zhukou|boyan"
        self.sidi_skill = findskill(sidi_firstskills)
        if current:hasShownSkills(sgs.lose_equip_skill.."|diaodu") and (not self.sidi_cardtype or self.sidi_cardtype ~= "EquipCard") then
            
        end
        if current:hasShownSkills("luanji|guose|jixi|qice|yigui|guishu") and (not self.sidi_cardtype or self.sidi_cardtype ~= "TrickCard") then
            self.sidi_skill = findskill("luanji|guose|jixi|qice|yigui|guishu")
        end
        if current:hasShownSkills("paoxiao|kuanggu|kuangcai") and (not self.sidi_cardtype or self.sidi_cardtype ~= "BasicCard") then
            self.sidi_skill = findskill("paoxiao|kuanggu|kuangcai")
        end
        if current:hasShownSkill("hongfa") and current:getPile("heavenly_army"):isEmpty()
        and self.player:getPlayerNumWithSameKingdom("AI", "qun") > 1 then
            self.sidi_skill = "hongfa"
        end
        if current:hasShownSkill("jiahe") and not current:getPile("flame_map"):isEmpty() then
            self.sidi_skill = "jiahe"
        end
        if current:hasShownSkill("zisui") and current:getPile("&disloyalty"):length() > 2 then
            self.sidi_skill = "zisui"
        end
        if current:hasShownSkill("xiongnve") and current:getMark("#massacre") > (self:isWeak(current) and 1 or 3) then
            self.sidi_skill = "xiongnve"
        end
        if current:hasShownSkill("paiyi") and current:getPile("power_pile"):length() > 3 then
            self.sidi_skill = "paiyi"
        end
    end
--回复
    local weis = {}
    for _, friend in ipairs(self.friends) do
        if self.player:isFriendWith(friend) and friend:canRecover() then
            table.insert(weis, friend)
        end
    end
    if #weis > 0 then
        local allweak = true
        for _, p in ipairs(weis) do
            if p:getHp() > 2 then--not self:isWeak(p)
                allweak = false
            end
        end
        if allweak or self.player:getMark("GlobalBattleRoyalMode") > 0 then
            self.sidi_recover = true
        end
    end

    local sidi_max = (self.sidi_recover and 1 or 0) + (self.sidi_skill and 1 or 0) + (self.sidi_cardtype and 1 or 0)
    sidi_max = math.min(sidi_max, #drivecards, max_num)
    local discards = {}
    if self.sidi_cardtype then
        for _, c in ipairs(drivecards) do
            if sgs.ai_type_name[c:getTypeId() + 1] == self.sidi_cardtype then
                table.insert(discards, c:getId())
                break
            end
        end
    else
        for _, c in ipairs(drivecards) do
            if sgs.ai_type_name[c:getTypeId() + 1] ~= "BasicCard" and #discards < sidi_max then
                table.insert(discards, c:getId())
            end
        end
    end
    for _, c in ipairs(drivecards) do
        if #discards < sidi_max and not table.contains(discards, c:getId()) then
            table.insert(discards, c:getId())
        end
    end
    return discards
end

sgs.ai_skill_exchange.sidi_put = function(self,pattern,max_num,min_num,expand_pile)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    if self.player:getPhase() <= sgs.Player_Play then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end
    if isCard("Peach", cards[1], self.player) or (cards[1]:isKindOf("Analeptic") and self.player:getHp() == 1) then
        return {}
    end
    if sgs.Sanguosha:matchExpPattern(pattern,self.player,cards[1]) then--只考虑cards[1]？
        return cards[1]:getEffectiveId()
    end
    return {}
end

sgs.ai_skill_choice["sidi_choice"] = function(self, choices, data)
    --"cardlimit" << "skilllimit" << "recover"
    --Global_room:writeToConsole("司敌选择:" .. choices)
    choices = choices:split("+")
    if self.player:getMark("GlobalBattleRoyalMode") > 0 and self.sidi_recover and table.contains(choices, "recover") then
        return "recover"
    end
    if self.sidi_cardtype and table.contains(choices, "cardlimit") then
        return "cardlimit"
    end
    if self.sidi_skill and table.contains(choices, "skilllimit") then
        return "skilllimit"
    end
    if self.sidi_recover and table.contains(choices, "recover") then
        return "recover"
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen["sidi_recover"] = function(self, targets)
    Global_room:writeToConsole("司敌恢复")
    targets = sgs.QList2Table(targets)
    if self:isFriend(targets[1]) then
        self:sort(targets, "hp")
        return targets[1]
    else
        self:sort(targets, "hp", true)
        for _, p in ipairs(targets) do
            if not p:hasShownSkills(sgs.priority_skill) and p:getHp() > 1 then
                return p
            end
        end
        return targets[1]
    end
end

sgs.ai_skill_choice["sidi_skill"] = function(self, choices, data)
    Global_room:writeToConsole("司敌禁用技能选择:" .. choices)
    choices = choices:split("+")
    if self.sidi_skill and table.contains(choices, self.sidi_skill) then
        Global_room:writeToConsole("司敌禁用技能:"..sgs.Sanguosha:translate(self.sidi_skill))
        return self.sidi_skill
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_skill_choice["sidi_cardtype"] = function(self, choices, data)
    --"BasicCard+EquipCard+TrickCard"
    --Global_room:writeToConsole("司敌禁用牌类型选择:" .. choices)
    choices = choices:split("+")
    if self.sidi_cardtype and table.contains(choices, self.sidi_cardtype) then
        Global_room:writeToConsole("司敌禁用牌类型:"..sgs.Sanguosha:translate(self.sidi_cardtype))
        return self.sidi_cardtype
    end
    return choices[math.random(1, #choices)]
end

function sgs.ai_cardneed.sidi(to, card, self)
	return to:getHandcardNum() < 2
end

sgs.ai_need_damaged.sidi = function (self, attacker, player)

end

--廖化
sgs.ai_skill_invoke.dangxian = true

--诸葛瑾
sgs.ai_skill_cardask["@huanshi-card"] = function(self, data)
	if not (self:willShowForAttack() or self:willShowForDefence()) then return "." end
	local judge = data:toJudge()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, 1, sgs.Sanguosha:getCard(id))
	end

	if self:needRetrial(judge) then
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end
	return "."
end

function sgs.ai_cardneed.huanshi(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 and to:isFriendWith(player) and self:isFriend(player) then
			if player:containsTrick("lightning") then
				return not (card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9)
			end
			if self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.huanshi_suit_value = {
	heart = 3.9,
	club = 2.7
}

local hongyuan_skill = {}
hongyuan_skill.name = "hongyuan"
table.insert(sgs.ai_skills, hongyuan_skill)
hongyuan_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:hasUsed("HongyuanCard") then return end
	return sgs.Card_Parse("@HongyuanCard=.&hongyuan")
--[[使用ViewAsSkill的写法
    local Skill = sgs.Sanguosha:getViewAsSkill("hongyuan")
    if Skill:isEnabledAtPlay(self.player) then
        local hcards = sgs.QList2Table(self.player:getHandcards())
        self:sortByUseValue(hcards, true)
        local cards = sgs.CardList()
        for _, c in ipairs(hcards) do
            if Skill:viewFilter(cards, c) then
                cards:append(c)
            end
        end
        if cards:length() > 0 then
            local hycard = Skill:viewAs(cards)
            Global_room:writeToConsole("弘援合纵:"..hycard:toString())
            return hycard
        end
    end
]]
end

sgs.ai_skill_use_func.HongyuanCard = function(hycard, use, self)
	local targets = sgs.PlayerList()
    local friends = {}
    for _, p in ipairs(self.friends_noself) do
		if hycard:targetFilter(targets, p, self.player)  then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
        local cards = sgs.QList2Table(self.player:getHandcards())
	    self:sortByUseValue(cards, true)
		local card, friend = self:getCardNeedPlayer(cards, friends, "hongyuan")
		if card and friend then
            use.card = sgs.Card_Parse("@HongyuanCard=" .. card:getId() .. "&hongyuan")
            --if use.to then use.to:append(friend) end
            --Global_room:writeToConsole("弘援合纵目标:"..sgs.Sanguosha:translate(friend:getGeneralName()).."/"..sgs.Sanguosha:translate(friend:getGeneral2Name()))
            return
		end
	end
end

sgs.ai_use_priority.HongyuanCard = 3.1
sgs.ai_card_intention.HongyuanCard = -40

sgs.ai_skill_playerchosen.hongyuan = function(self, targets)
	targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, p in ipairs(targets) do
        if p:getHandcardNum() < self.player:getHandcardNum() then
            return p
        end
    end
	return {}
end

sgs.ai_skill_invoke.mingzhe = true

--全琮
sgs.ai_skill_playerchosen.qinzhong = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if p:hasShownSkill("hunshang") and self.player:getHp() == 1 then
            return p
        end
    end

    local function g2value(player)
        local g2name = player:getActualGeneral2Name()
        return sgs.general_value[g2name] or 0
    end

    local myg2_value = g2value(self.player)
    self:sort(targets, "hp")
    for _, p in ipairs(targets) do
        if self.player:getHp() >= p:getHp() and myg2_value < g2value(p) then
            return p
        end
    end
    return {}
end

sgs.ai_skill_use["@@zhaofu1"] = function(self, prompt, method)
    if not self:willShowForAttack() then return "." end

    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)

    local card
    for _, acard in ipairs(cards) do
		if not self:isValuableCard(acard) then
			card = acard
            break
		end
	end

    local targets = {}
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        table.insert(targets, p)
    end

    local compare_func = function(a, b)
		return (a:getHandcardNum() + math.min(1.5, a:getHp() / 2))
            > (b:getHandcardNum() + math.min(1.5, b:getHp() / 2))
	end
    table.sort(targets, compare_func)

    local target
    for _, p in ipairs(targets) do
        if not self:willSkipPlayPhase(p) and p:getMark("#reward") < 2 then
            target = p
            break
        end
    end

    if card and target then
        return "@ZhaofuCard=" .. card:getEffectiveId() .. "->" .. target:objectName()
    end
    return "."
end

sgs.ai_skill_invoke.zhaofu = function(self, data)
    local prompt_list = data:toString():split(":")
    local card_name = prompt_list[4]
    Global_room:writeToConsole("招附targetFixed:"..card_name)
    if card_name:match("analeptic") then
        return false
    end
    local clonecard = sgs.cloneCard(card_name)
    local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
    self:useCardByClassName(clonecard, dummyuse)
    if dummyuse.card then
        return true
    end
    return false
end

sgs.ai_skill_use["@@zhaofu2"] = function(self, prompt, method)
    local card_name = prompt:split(":")[4]
    Global_room:writeToConsole("招附手选目标:"..card_name)
    local clonecard = sgs.cloneCard(card_name)
    if self:getUseValue(clonecard) >= 5.2--更优化的值，多个赏标记时考虑杀等缺使用者信息getMark("#reward") > 0
    or card_name == "duel"
    or (self.player:getMark("GlobalBattleRoyalMode") > 0 and (card_name == "slash" or card_name == "fire_slash"or card_name == "thunder_slash")) then
        local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
        self:useCardByClassName(clonecard, dummyuse)
        if dummyuse.card and not dummyuse.to:isEmpty() then
            local target_objectname = {}
            for _, p in sgs.qlist(dummyuse.to) do
                table.insert(target_objectname, p:objectName())
            end
            return "@ZhaofuVSCard=.&->" .. table.concat(target_objectname, "+")
        end
    end
    return "."
end

--郭淮
sgs.ai_skill_playerchosen.jingce = sgs.ai_skill_playerchosen.damage--选择目标怎样合适？

sgs.ai_skill_choice.startcommand_jingce = sgs.ai_skill_choice.startcommand_to

sgs.ai_skill_choice["docommand_jingce"] = function(self, choices, data)
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
        if p:getHp() == 1 and self:isWeak(p) and self:isEnemy(source, p) then
          return "yes"
        end
      end
    end
  end
  if index == 5 and not self.player:faceUp() then
    return "yes"
  end
  if is_enemy then
    if index == 2 then
      return "yes"
    end
    if index == 3 and self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty() then
      return "yes"
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
    if index == 6 and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 then
      return "yes"
    end
  end
  return "no"
end

sgs.ai_skill_playerchosen["command_jingce"] = sgs.ai_skill_playerchosen.damage

--杨修
sgs.ai_skill_invoke.danlao = function(self, data)
	local use = data:toCardUse()
    local ucard = use.card
	if ucard:isKindOf("GodSalvation") and self.player:canRecover() then
		return false
    elseif ucard:isKindOf("AmazingGrace") and self:playerGetRound(self.player) < self.room:alivePlayerCount()/2 then
		return false
	elseif ucard:isKindOf("IronChain") and self.player:isChained() then
        return false
    elseif ucard:isKindOf("AwaitExhausted") and self.player:getHandcardNum() > 2
      and self:getCardsNum({"Peach", "Jink"}) == 0 then
        return false
    elseif ucard:isKindOf("AllianceFeast") and use.from == self.player then
        return false
    elseif ucard:isKindOf("Conquering") then
        return false
    elseif ucard:isKindOf("ExNihilo") or ucard:isKindOf("BefriendAttacking") then
        return false
    elseif self:isFriend(use.from) and (ucard:isKindOf("Snatch") or ucard:isKindOf("Dismantlement")) then
        return false
	else
		return true
	end
end

sgs.ai_skill_invoke.jilei = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.from)
end

sgs.ai_skill_choice.jilei = function(self, choices, data)
	local dfrom = data:toDamage().from
    local b_limited = dfrom:getMark("##jilei+BasicCard") > 0
    local t_limited = dfrom:getMark("##jilei+TrickCard") > 0
    local e_limited = dfrom:getMark("##jilei+EquipCard") > 0
    if b_limited and t_limited then
        return "EquipCard"
    elseif b_limited and e_limited then
        return "TrickCard"
    elseif t_limited and e_limited then
        return "BasicCard"
    end
    if self:slashIsAvailable(dfrom) and not b_limited then
        for _, p in ipairs(self.friends) do
            if dfrom:inMyAttackRange(p) then
                return "BasicCard"
            end
        end
    end
    if dfrom:getHp() < 2 and getCardsNum("Peach", dfrom, self.player) > 0 and not b_limited then
		return "BasicCard"
	else
		return "TrickCard"
	end
end

--祖茂
sgs.ai_skill_exchange["yinbingx"] = function(self,pattern,max_num,min_num,expand_pile)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)

    local result = {}
    local m_num = math.max(self:getCardsNum("Jink") + 0.5 * self:getCardsNum("Slash"), 1)--可承受的数量
    local discardEquip = false
    for _, c in ipairs(cards) do
        if discardEquip and self.room:getCardPlace(c:getEffectiveId()) == sgs.Player_PlaceEquip then
        elseif not c:isKindOf("BasicCard") and self:getKeepValue(c) < 2.5 then--详细考虑？
            table.insert(result, c:getEffectiveId())
            if self.player:hasSkills(sgs.lose_equip_skill) and self.room:getCardPlace(c:getEffectiveId()) == sgs.Player_PlaceEquip then
                discardEquip = true
            end
        end
        if #result == m_num then
            break
        end
    end
    return result
end

sgs.ai_skill_invoke.yinbingx = false

sgs.ai_skill_invoke.juedi = true

sgs.ai_skill_choice.juedi = function(self, choices, data)
    local draw_num = self.player:getMaxHp() - self.player:getHandcardNum()
    local can_give,weak_friend = false,false
    self:sort(self.friends_noself, "hp")
    for _, p in ipairs(self.friends_noself) do
        if self.player:getHp() >= p:getHp() then--考虑盟友和队友？
            if self:isWeak(p) then
                weak_friend = true
            end
            can_give = true
        end
    end
    if weak_friend and not self:isWeak() then
        return "give"
    end
    if can_give and self.player:getPile("kerchief"):length() * 2 >= draw_num then
        return "give"
    end
    if draw_num > 1  then
        return "self"
    elseif can_give then
        return "give"
    end
	return "self"
end

sgs.ai_skill_playerchosen.juedi = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "hp")
    for _, p in ipairs(targets) do
        if self.player:isFriendWith(p) then--canRecover?
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
            return p
        end
    end
    return targets[#targets]
end

--伏完
sgs.ai_skill_invoke.moukui = function(self, data)
    if not self:willShowForAttack() then return false end
	local target = data:toPlayer()
	if self:isFriend(target) then
        return self:needToThrowArmor(target)
    end
    return true
end

sgs.ai_skill_choice.moukui = function(self, choices, data)
	local target = data:toPlayer()
    Global_room:writeToConsole("谋溃目标防御值：" ..sgs.getDefenseSlash(target, self))
    if not self:isFriend(target) and self:getDangerousCard(target) then
        return "discard"
    end
    if self:isFriend(target) and self:needToThrowArmor(target) then
        return "discard"
    end
	if (self:isEnemy(target) and self:doNotDiscard(target)) or sgs.getDefenseSlash(target, self) < 2 then
		return "draw"
	end
	return "discard"
end

--陈到
sgs.ai_skill_invoke.wanglie = function(self, data)
	local ucard = data:toCardUse().card
    local num = 0
    for _, c in ipairs(self:getTurnUse()) do
        if not c:isKindOf("SkillCard") then--转化成普通卡的技能卡？
            num = num + 1
        end
    end
    if num == 0 then--需要配合调整出牌优先度
        return true
    end
    if ucard:isKindOf("Slash") and ucard:hasFlag("drank")
    and (self:getOverflow() <= 1 or num <= 1) then
        return true
    end
    return false
end

--田豫
sgs.ai_skill_invoke.zhenxi = function(self, data)
	local target = data:toPlayer()
    return not self:isFriend(target)
end

sgs.ai_skill_choice.zhenxi = function(self, choices, data)
	local target = data:toPlayer()
    if self:doNotDiscard(target) then
        return "usecard"
    end

    local need_i = self:getOverflow(target) >= 0 and not target:containsTrick("indulgence")
                and self:trickIsEffective(sgs.cloneCard("indulgence", sgs.Card_Diamond), target, self.player)
    local need_s = target:getHandcardNum() <= 2 and not target:containsTrick("supply_shortage")
                and self:trickIsEffective(sgs.cloneCard("supply_shortage", sgs.Card_Club), target, self.player)

    local cards = self.player:getCards("he")
    for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    for _, acard in ipairs(cards) do
		if not acard:isKindOf("TrickCard") and not self:isValuableCard(acard)
        and ((need_i and acard:getSuit() == sgs.Card_Diamond) or (need_s and acard:getSuit() == sgs.Card_Club)) then
			self.zhenxi_card = acard
            return "usecard"
		end
	end

	return "discard"
end

sgs.ai_skill_choice.zhenxi_discard = function(self, choices, data)--无目标data
    return "yes"
end

sgs.ai_skill_use["@@zhenxi_trick"] = function(self, prompt, method)
    local target
    local target_name = self.player:property("zhenxi_target"):toString()
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:objectName() == target_name then
            target = p
            break
        end
    end

    local card = self.zhenxi_card or nil
    self.zhenxi_card = nil

    if not card then
        local cards = self.player:getCards("he")
        for _, id in sgs.qlist(self.player:getHandPile()) do
            cards:prepend(sgs.Sanguosha:getCard(id))
        end
        cards = sgs.QList2Table(cards)
        self:sortByUseValue(cards, true)

        local need_i = self:getOverflow(target) >= 0 and not target:containsTrick("indulgence")
                and self:trickIsEffective(sgs.cloneCard("indulgence", sgs.Card_Diamond), target, self.player)
        local need_s = target:getHandcardNum() <= 2 and not target:containsTrick("supply_shortage")
                and self:trickIsEffective(sgs.cloneCard("supply_shortage", sgs.Card_Club), target, self.player)

        for _, acard in ipairs(cards) do
            if not acard:isKindOf("TrickCard") and not self:isValuableCard(acard)
            and ((need_i and acard:getSuit() == sgs.Card_Diamond) or (need_s and acard:getSuit() == sgs.Card_Club)) then
                card = acard
                break
            end
        end
    end

    if card and target then
        local suit = card:getSuitString()
        local number = card:getNumberString()
        local card_id = card:getEffectiveId()
        local card_str
        if suit == "diamond" then
            card_str = ("indulgence:_zhenxi[diamond:%s]=%d&"):format(number, card_id)
        elseif suit == "club" then
            card_str = ("supply_shortage:_zhenxi[club:%s]=%d&"):format(number, card_id)
        end
        return card_str .. "->" .. target_name
    end
    return "."
end

sgs.ai_skill_invoke.jiansu = true

sgs.ai_skill_use["@@jiansu"] = function(self, prompt, method)
    local money_cards = {}
    local str_ids = self.player:property("jiansu_record"):toString():split("+")
    for _, str_id in ipairs(str_ids) do
      table.insert(money_cards, sgs.Sanguosha:getCard(tonumber(str_id)))
    end
    self:sortByUseValue(money_cards, true)

    local value,num = 0,0
    for _, c in ipairs(money_cards) do
        local cvalue = self:getUseValue(c)
        if value + cvalue < 10 then--参考受伤时桃的值，考虑无用牌？
        --and not isCard("Peach", c, self.player) and not isCard("AllianceFeast", c, self.player)
            value = value + cvalue
            num = num + 1
        end
    end
    self:sort(self.friends, "hp")
    for _, p in ipairs(self.friends) do
        if p:getHp() <= num and self.player:isFriendWith(p) and p:canRecover() then
            local discards = {}
            for i = 1, p:getHp(), 1 do
                table.insert(discards, money_cards[i]:getEffectiveId())
            end
            return "@JiansuCard=" .. table.concat(discards, "+") .. "->" .. p:objectName()
        end
    end
    for _, p in ipairs(self.friends) do
        if p:getHp() <= num and self:isFriend(p) and self:isWeak(p) and p:canRecover() then
            local discards = {}
            for i = 1, p:getHp(), 1 do
                table.insert(discards, money_cards[i]:getEffectiveId())
            end
            return "@JiansuCard=" .. table.concat(discards, "+") .. "->" .. p:objectName()
        end
    end
    return "."
end

--马良
local mumeng_skill = {}
mumeng_skill.name = "mumeng"
table.insert(sgs.ai_skills, mumeng_skill)
mumeng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:usedTimes("ViewAsSkill_mumengCard") > 0 then return end
    local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)

    local b_card, f_card
    for _,c in ipairs(cards) do
        if c:getSuit() == sgs.Card_Heart and not isCard("Peach", c, self.player)--桃详细考虑？
        and not c:isKindOf("BefriendAttacking") and self:getUseValue(c) < sgs.ai_use_value.BefriendAttacking then
            b_card = c
            break
        end
    end
    for _,c in ipairs(cards) do
        if c:getSuit() == sgs.Card_Heart and not isCard("Peach", c, self.player)
        and not c:isKindOf("FightTogether") and self:getUseValue(c) < sgs.ai_use_value.FightTogether then
            f_card = c
            break
        end
    end
    if b_card then--暂不考虑戮力同心"fight_together"
        local suit = b_card:getSuitString()
        local number = b_card:getNumberString()
        local card_id = b_card:getEffectiveId()
        local card_str = ("befriend_attacking:mumeng[%s:%s]=%d&mumeng"):format(suit, number, card_id)
        local skillcard = sgs.Card_Parse(card_str)

        assert(skillcard)
        return skillcard
    end
end

sgs.ai_cardneed.mumeng = function(to, card, self)
	return card:getSuit() == sgs.Card_Heart
end

sgs.mumeng_suit_value = { heart = 3.9 }

sgs.ai_skill_invoke.naman = true

sgs.ai_skill_playerchosen["naman_target"] = function(self, targets)
    local use = self.player:getTag("NamanUsedata"):toCardUse()
    assert(use)
    local card = use.card
    local from = use.from
    local is_friend = self:isFriend(from)
    local tos = sgs.QList2Table(use.to)
    local targetlist = sgs.QList2Table(targets)

    if card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
        self:sort(tos, "hp")
        for _, p in ipairs(tos) do
            if self.player:isFriendWith(p) and self:aoeIsEffective(card, p, from) then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if self.player:isFriendWith(p) and self:aoeIsEffective(card, p, from) then
                return p
            end
        end
    elseif card:isKindOf("GodSalvation") then
        self:sort(tos, "hp")
        for _, p in ipairs(tos) do
            if self:isEnemy(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
    elseif card:isKindOf("AmazingGrace") then
        self:sort(tos, "handcard")
        for _, p in ipairs(tos) do
            if self:isEnemy(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
    elseif card:isKindOf("AwaitExhausted") then
        if is_friend then
            return {}
        else
            return targetlist[1]
        end
    elseif card:isKindOf("IronChain") then
        self:sort(tos, "defenseSlash")
        for _, p in ipairs(tos) do
            if self:isFriend(p) and self:trickIsEffective(card, p, from) and p:isChained() then
                return p
            end
        end
        self:sort(targetlist, "defenseSlash")
        for _, p in ipairs(targetlist) do
            if not table.contains(tos, p) and not self:isFriend(p) and self:trickIsEffective(card, p, from) and not p:isChained() then
                return p
            end
        end
    elseif card:isKindOf("FightTogether") then
        self:sort(tos, "defenseSlash")
        for _, p in ipairs(tos) do
            if self:isFriend(p) and self:trickIsEffective(card, p, from) and not p:isChained() then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p) and self:trickIsEffective(card, p, from) and p:isChained() then
                return p
            end
        end
    end

    if is_friend then--调虎离山、联军等等，考虑使用和目标敌我，太复杂。暂时简单考虑
        for _, p in ipairs(targetlist) do
            if not table.contains(tos, p)
            and ((card:isKindOf("TrickCard") and self:trickIsEffective(card, p, from))
                or (card:isKindOf("Slash") and self:slashIsEffective(card, p, from))) then
                    return p
            end
        end
    else
        for _, p in ipairs(tos) do
            if self:isEnemy(p)
            and ((card:isKindOf("TrickCard") and self:trickIsEffective(card, p, from))
                or (card:isKindOf("Slash") and self:slashIsEffective(card, p, from))) then
                    return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p)
            and ((card:isKindOf("TrickCard") and self:trickIsEffective(card, p, from))
                or (card:isKindOf("Slash") and self:slashIsEffective(card, p, from))) then
                    return p
            end
        end
    end
    return {}
end

--华雄
sgs.ai_skill_invoke.yaowu = true

sgs.ai_skill_invoke.shiyong = function(self, data)
    if self.player:inHeadSkills("baoling") and not self.player:hasShownGeneral2() then
        return false
    end
    return math.random(0,1) > 0
end

--张春华
sgs.ai_skill_playerchosen["guojue_damage"] = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_invoke.guojue = function(self, data)
	local target = data:toPlayer()
    return not self:isFriend(target)
end

sgs.ai_skill_use["@@shangshi"] = function(self, prompt, method)

    local discard = {}
    local give = {}
    local cards = self.player:getCards("h")

	cards = sgs.QList2Table(cards)
    if self.player:getPhase() <= sgs.Player_Play then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end

    for _, card in ipairs(cards) do
            Global_room:writeToConsole("伤逝弃牌")
            return "@ShangshiCard=".. card:getEffectiveId()
    end
    return "."
end

--刘夫人
sgs.ai_skill_invoke.zhuidu = function(self, data)
	local target = data:toPlayer()
    return not self:isFriend(target)
end

sgs.ai_skill_discard.zhuidu_discard = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummy_reason", 1, 1, false, true)--暂时不详细考虑
end

sgs.ai_skill_choice.zhuidu_choice = function(self, choices, data)
    local damage = data:toDamage()
    if not self:damageIsEffective_(damage) then
        return "damage"
    end
    local card = damage.card
    local original_num = damage.damage
    local from = damage.from
    local target = damage.to
    if target:hasArmorEffect("SilverLion") and (not card or not card:isKindOf("Slash") or not IgnoreArmor(from, target)) then
        return "damage"
    end
    if target:hasShownSkill("gongqing") and from:getAttackRange() < 3 then
        return "damage"
    end
    --暂时不详细考虑-1伤害
    return "throw"
end

sgs.ai_skill_invoke.shigong = function(self, data)
    if not self.player:canRecover() then
		return false
	end
	return self:getCardsNum({"Peach", "Analeptic"}) + self.player:getHp() < 1
end

sgs.ai_skill_choice.shigong_skill = function(self, choices, data)
    Global_room:writeToConsole("示恭技能:"..choices)
    choices = choices:split("+")
    for _, skill in ipairs(choices) do
        if string.find(sgs.priority_skill, skill) then
            return skill
        end
    end
    return choices[math.random(1,#choices)]--暂时不考虑详细配合，"cancel"的情况？
end

--伊籍
sgs.ai_skill_playerchosen.dingke = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, p in ipairs(targets) do
        if p:getPhase() == sgs.Player_NotActive and self.player:isFriendWith(p) and not self:needKongcheng(p) then
            if self.player:hasSkill("shengxi") or self.player:getHandcardNum() > 2
            or (self:needKongcheng() and self.player:getHandcardNum() <= 2)
            or (not self:isWeak() and p:getHandcardNum() < 2) then
                return p
            end
        end
    end
    local current = self.room:getCurrent()
    if not self:isFriend(current) and table.contains(targets, current) then
        return current
    end
    return {}
end

sgs.ai_skill_exchange["dingke_give"] = function(self,pattern,max_num,min_num,expand_pile)
    --缺少目标信息，无法详细判断
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    return cards[1]:getEffectiveId()
end

sgs.ai_skill_invoke.jiyuan = function(self, data)
	local target = data:toPlayer()
    return self:isFriend(target)
end

--张翼
sgs.ai_skill_invoke.kangrui = function(self, data)
    Global_room:writeToConsole("亢锐"..data:toString())
	local prompt = data:toString():split(":")
    local friend = self.room:findPlayerbyobjectName(prompt[2])
	local target = self.room:findPlayerbyobjectName(prompt[3])
    local damagecard = {"slash","fire_slash","thunder_slash","burning_camps","savage_assault","archery_attack","duel"}
    local lowvaluecard = {"collateral","known_both","fire_attack","lure_tiger","imperial_order","iron_chain"}--"snatch","dismantlement","drowning",
    if self:isWeak(target) and table.contains(damagecard, prompt[4]) then
        return false
    end
    if friend:getMaxHp() - friend:getHandcardNum() > (table.contains(lowvaluecard, prompt[4]) and 1 or 2) then--根据牌价值考虑摸2?
        return true
    end
    if self:isEnemy(target) and self:isWeak(target) then
        if target:hasArmorEffect("SilverLion") or (target:hasShownSkill("gongqing") and friend:getAttackRange() < 3) then
            return false
        end
		local damage = {}
		damage.to = target
		damage.from = friend
		damage.damage = 2
		if not self:damageIsEffective_(damage) then
            return false
        end
        local need_slashnum = getCardsNum("Slash", target, self.player) + 1
        if target:hasSkills("wushuang|wushuang_lvlingqi") then
            need_slashnum = need_slashnum * 2
        end
        if getCardsNum("Slash", friend, self.player) > need_slashnum then
            return true
        end
    end
    return false
end

sgs.ai_skill_choice.kangrui = function(self, choices, data)
    if string.find(choices, "useduel") then
        local target = data:toPlayer()
        if target:hasArmorEffect("SilverLion") or (target:hasShownSkill("gongqing") and self.player:getAttackRange() < 3) then
            return "fillhandcards"
        end
		local damage = {}
		damage.to = target
		damage.from = self.player
		damage.damage = 2
		if not self:damageIsEffective_(damage) then
            return "fillhandcards"
        end
        local need_slashnum = getCardsNum("Slash", target, self.player) + 1
        if target:hasSkills("wushuang|wushuang_lvlingqi") then
            need_slashnum = need_slashnum * 2
        end
        if self:getCardsNum("Slash") > need_slashnum  then
            Global_room:writeToConsole("亢锐被决斗")
            return "useduel"
        end
    end
    return "fillhandcards"
end

--程普
sgs.ai_skill_invoke.huxun = true

sgs.ai_skill_choice.huxun = function(self, choices, data)
    choices = choices:split("+")
    if table.contains(choices, "gainmaxhp") then
        return "gainmaxhp"
    else--暂不考虑更需要移动乐等
        return "movecard"
    end
end

sgs.ai_skill_playerchosen.huxun = function(self, _targets, max_num, min_num)

	self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and self:getMoveCardorTarget(friend, ".", "e") then
				return {friend, self:getMoveCardorTarget(friend, "target", "e")}
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, ".", "e") then
				return {friend, self:getMoveCardorTarget(friend, "target", "e")}
			end
		end

		local targets = {}
		for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
			if not self.player:isFriendWith(enemy) and self:getMoveCardorTarget(enemy, "." ,"e") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			return {targets[#targets], self:getMoveCardorTarget(targets[#targets], "target", "e")}
		end

		if self.player:hasEquip() and self.player:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(self.player, ".", "e") then
			return {self.player, self:getMoveCardorTarget(self.player, "target" ,"e")}
		end

		local friends = {}--没有敌人则简单转移队友装备
		for _, friend in ipairs(self.friends) do
			if self:getMoveCardorTarget(friend, "." ,"e") then
				table.insert(friends, friend)
			end
		end

		if #friends > 0 then
			self:sort(friends, "hp", true)
			return {friends[#friends], self:getMoveCardorTarget(friends[#friends], "target", "e")}
		end

	return {}
end

sgs.ai_skill_transfercardchosen.huxun = function(self, targets, equipArea, judgingArea)
	return self:getMoveCardorTarget(targets:first(), "card", "e")
end

sgs.ai_skill_exchange["yuancong_give"] = function(self,pattern,max_num,min_num,expand_pile)
    local num = self:getOverflow()
    if num > 0 then
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        return cards[num]:getEffectiveId()
    end
    local chengpu = sgs.findPlayerByShownSkillName("yuancong")
    if chengpu then
        if self.player:getHp() > 1 and self:getCardsNum("Analeptic") > 0 then
            return self:getCard("Analeptic"):getEffectiveId()
          end
        if not self:isWeak() and self:getCardsNum("Peach") > 1 then
            return self:getCard("Peach"):getEffectiveId()
        end
        local c, friend = self:getCardNeedPlayer(sgs.QList2Table(self.player:getCards("he")), {chengpu})
        if friend and friend:objectName() == chengpu:objectName() then
            return c:getEffectiveId()
        end
        if self:getCardsNum("Slash") > 0 then
            return self:getCard("Slash"):getEffectiveId()
        end
        --考虑详细锦囊等？
    end
    return {}
end

sgs.ai_skill_use["@@yuancong_usecard"] = function(self, prompt, method)
    local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)

    for _, card in ipairs(cards) do
        local dummyuse = { isDummy = true }
        if not card:targetFixed() then
            dummyuse.to = sgs.SPlayerList()
        end
        local type = card:getTypeId()
        self["use" .. sgs.ai_type_name[type + 1]](self, card, dummyuse)

        Global_room:writeToConsole("元从dummyuse:"..card:objectName())
        if dummyuse.card and not card:isKindOf("Analeptic") then--详细考虑？
            Global_room:writeToConsole("元从使用牌")
            if not card:targetFixed() then
                if dummyuse.to and not dummyuse.to:isEmpty() then
                    local target_objectname = {}
                    for _, p in sgs.qlist(dummyuse.to) do
                        table.insert(target_objectname, p:objectName())
                    end
                    return card:toString() .."->" .. table.concat(target_objectname, "+")
                else
                    return "."
                end
            end
            return card:toString()--"@YuancongUseCard=".. card:getEffectiveId()--正确写法？？
        end
    end
    return "."
end

--程昱
local shefu_skill = {}
shefu_skill.name = "shefu"
table.insert(sgs.ai_skills, shefu_skill)
shefu_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("ShefuCard") then return end
    if self.player:isKongcheng() then return end

    local index = self:getOverflow()
    if index > 0 or self.player:getHandcardNum() > 2 then
        local cards = self.player:getHandcards()
        cards = sgs.QList2Table(cards)
        self:sortByUseValue(cards, true)
        if index > 1 then
            return sgs.Card_Parse("@ShefuCard=" .. cards[index]:getEffectiveId() .."&shefu")
            --for i = index, 1, -1 do--考虑已有的伏兵？
            --end
        else
            return sgs.Card_Parse("@ShefuCard=" .. cards[1]:getEffectiveId() .."&shefu")
        end
    end
end

sgs.ai_skill_use_func.ShefuCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.ShefuCard = 0.3

sgs.ai_skill_exchange.shefu = function(self,pattern,max_num,min_num,expand_pile)
    local use = self.player:getTag("ShefuUsedata"):toCardUse()
    local response = self.player:getTag("ShefuUsedata"):toCardResponse()

    if response then
        Global_room:writeToConsole("设伏response")
        local card = response.m_card
        local who = response.m_who
        if card and who and self:isEnemy(who) and (card:isKindOf("Nullification") or card:isKindOf("Jink")) then
            for _, id in sgs.qlist(self.player:getPile(expand_pile)) do--"ambush"
                local c = sgs.Sanguosha:getCard(id)
                if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) then
                    return c:getEffectiveId()
                end
            end
        end
    end
    if use then
        Global_room:writeToConsole("设伏use")
        local card = use.card
        local from = use.from
        local to = use.to
        if card and from and self:isEnemy(from) then--考虑详细的card类型和to目标状态？
            for _, id in sgs.qlist(self.player:getPile(expand_pile)) do--"ambush"
                local c = sgs.Sanguosha:getCard(id)
                if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) then
                    return c:getEffectiveId()
                end
            end
        end
    end
    return {}
end

sgs.ai_skill_exchange["shefu_remove"] = function(self,pattern,max_num,min_num,expand_pile)
    local result = {}
    local ambushcards = {}
    for _, id in sgs.qlist(self.player:getPile(expand_pile)) do
        local card = sgs.Sanguosha:getCard(id)
        table.insert(ambushcards, card)
    end
    self:sortByUseValue(ambushcards, true)
    for _, c in ipairs(ambushcards) do
        if c:getTypeId() == sgs.Card_TypeEquip then
            table.insert(result, c)
        end
        if #result == min_num then
            return result
        end
    end
    for _, c in ipairs(ambushcards) do
        if c:getTypeId() == sgs.Card_TypeTrick then
            table.insert(result, c)
        end
        if #result == min_num then
            return result
        end
    end
    for _, c in ipairs(ambushcards) do
        table.insert(result, c)
        if #result == min_num then
            return result
        end
    end
end

sgs.ai_skill_invoke.benyu = function(self, data)
	if not self:willShowForMasochism() then return false end
    --local target = data:toPlayer()
	return true
end

sgs.ai_skill_choice.benyu = function(self, choices, data)
    local target = data:toPlayer()
    if target and not self:isFriend(target) then
        if self.player:getHandcardNum() >= 5 then
            Global_room:writeToConsole("贲育弃牌1:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
            return "discard"
        end
        if target:getHandcardNum() > 5 then
            local difference = target:getHandcardNum() - self.player:getHandcardNum()
            if (difference > 2 and self:slashIsAvailable(target)) or not self:isWeak() or self:getCardsNum({"Peach", "Analeptic"}) > 0 then
                Global_room:writeToConsole("贲育弃牌2:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
                return "discard"
            end
        end
    end
    return "draw"
end

sgs.ai_skill_discard.benyu_damage = function(self, discard_num, min_num, optional, include_equip)
    --缺来源信息
    return {}
end