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
    table.removeOne(trickcards, self.player:property("guishuprohibit"):toString())
    if trickcards[1] == "known_both" and self:getUseValue(spadecards[1]) > sgs.ai_use_value.KnownBoth then
        return--#spadecards < 2 每回合不重置
    end
    Global_room:writeToConsole("鬼术卡类型:"..trickcards[1])
    return sgs.Card_Parse("@GuishuCard=" ..  spadecards[1]:getEffectiveId() .. ":" .. trickcards[1])
end

sgs.ai_skill_use_func.GuishuCard = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
    local guishucard = sgs.cloneCard(userstring, card:getSuit(), card:getNumber())
    guishucard:setCanRecast(false)
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
sgs.ai_skill_exchange.sidi = function(self,pattern,max_num,min_num,expand_pile)
if expand_pile and expand_pile == "drive" then--askForExchange无法区分暂时处理
    self.sidi_recover = nil
    self.sidi_skill = nil
    self.sidi_cardtype = nil
    local current = self.room:getCurrent()
    if self:isFriend(current) then
        self:sort(self.friends, "hp")--从小到大排序
        for _, friend in ipairs(self.friends) do
            if friend:getSeemingKingdom() == "wei" and friend:getHp() == 1 then
                self.sidi_recover = true
                return self.player:getPile("drive"):first()
            end
        end
    end
    if self:isEnemy(current) then
    --禁卡
        if not self:willSkipPlayPhase(current) then
            if getCardsNum("TrickCard", current, self.player) > (current:hasShownSkill("jizhi") and 1 or 2)
            or (current:hasShownSkills("guose|luanji|guishu") and current:getHandcardNum() > 1)
            or (current:hasShownSkill("jixi") and current:getPile("field"):length() > 1)
            or (current:hasShownSkill("qice")) then
                self.sidi_cardtype = "TrickCard"
            end
            if current:hasShownSkills("diaodu+xiaoji|diaodu+xuanlue") then
                self.sidi_cardtype = "EquipCard"
            end
            if (current:getHp() == 1 and self:isWeak(current) and current:getMark("GlobalBattleRoyalMode") == 0)
            or ((self:hasCrossbowEffect(current) or current:hasShownSkills(sgs.force_slash_skill))
                    and getCardsNum("Slash", current, self.player) >= 1) then
                self.sidi_cardtype = "BasicCard"
            end
            for _, friend in ipairs(self.friends) do
                if current:canSlash(friend, nil, true) and sgs.getDefenseSlash(friend, self) <= 2 then
                    self.sidi_cardtype = "BasicCard"
                    break
                end
            end
        end
    --技能
        local sidi_firstskills = --注意有优先顺序
                "suzhi|yigui|jinghe|miewu|jieyue|jili|tongdu|chuli|wansha|zaoyun|jinfa|yingzi_zhouyu|zhukou|boyan"
        for _, skill in ipairs(sidi_firstskills:split("|")) do
            if current:hasShownSkill(skill) then
                self.sidi_skill = skill
                break
            end
        end
        if current:hasShownSkills(sgs.lose_equip_skill.."|diaodu") and (not self.sidi_cardtype or self.sidi_cardtype ~= "EquipCard") then
            
        end
        if current:hasShownSkills("luanji|guose|jixi|qice|guishu") and (not self.sidi_cardtype or self.sidi_cardtype ~= "TrickCard") then
            
        end
        if current:hasShownSkills("paoxiao|kuanggu|kuangcai") and (not self.sidi_cardtype or self.sidi_cardtype ~= "BasicCard") then
            
        end
        if current:hasShownSkill("hongfa") and current:getPile("heavenly_army"):isEmpty()
        and self.player:getPlayerNumWithSameKingdom("AI", "qun") > 1 then
            self.sidi_skill = "hongfa"
        end
        if current:hasShownSkill("jiahe") and not current:getPile("flame_map"):isEmpty() then
            self.sidi_skill = "jiahe"
        end
        if current:hasShownSkill("zisui") and current:getPile("disloyalty"):length() > 2 then
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
        if friend:getSeemingKingdom() == "wei" and friend:isWounded() then
            table.insert(weis, friend)
        end
    end
    if #weis > 0 then
        local allweak = true
        for _, p in ipairs(weis) do
            if p:getHp() > 2 then
                allweak = false
            end
        end
        if allweak then
            self.sidi_recover = true
        end
    end
    local sidi_max = (self.sidi_recover and 1 or 0) + (self.sidi_skill and 1 or 0) + (self.sidi_cardtype and 1 or 0)
    sidi_max = math.min(sidi_max, self.player:getPile("drive"):length(), max_num)
    local discards = {}
    for _, id in sgs.qlist(self.player:getPile("drive")) do
        if #discards < sidi_max then
            table.insert(discards, id)
        end
    end
    return discards
else
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    if self.player:getPhase() <= sgs.Player_Play then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end
    if self:isRecoverPeach(cards[1]) or (cards[1]:isKindOf("Analeptic") and self.player:getHp() == 1) then
        return {}
    end
    return cards[1]:getEffectiveId()
end
end

--askForExchange(ask_who, objectName(), 3, 0, "@sidi-remove::"+player->objectName(), "drive");

sgs.ai_skill_choice["sidi_choice"] = function(self, choices, data)
    --"cardlimit" << "skilllimit" << "recover"
    --Global_room:writeToConsole("司敌选择:" .. choices)
    choices = choices:split("+")
    if self.sidi_cardtype and table.contains(choices, "cardlimit") then
        return "cardlimit"
    end
    if self.sidi_skill and table.contains(choices, "skilllimit") then
        return "skilllimit"
    end
    if self.sidi_recover and table.contains(choices, "recover") then
        Global_room:writeToConsole("司敌恢复")
        return "recover"
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen["sidi_recover"] = function(self, targets)
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
