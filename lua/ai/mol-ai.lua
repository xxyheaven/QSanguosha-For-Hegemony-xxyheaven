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
--移动版专属

--杜预
sgs.ai_skill_invoke.wuku = true

local miewu_skill = {}
miewu_skill.name = "miewu"
table.insert(sgs.ai_skills, miewu_skill)
miewu_skill.getTurnUseCard = function(self)
	if self.player:getMark("#wuku") == 0 or self.player:hasFlag("MiewuUsed") or self.player:isNude() then
        return
    end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)
    local subcard = cards[1]:getEffectiveId()
    local str = "@MiewuCard=" .. subcard .. ":"
    local card_name

--[[{联军盛宴,火烧连营,桃园结义,南蛮入侵,万箭齐发,
	远交近攻,无中生有,决斗,顺手牵羊,过河拆桥,水淹七军,
	铁索连环,以逸待劳,五谷丰登,勠力同心,调虎离山,敕令,
	借刀杀人,知己知彼,火攻,挟天子以令诸侯}
]]--按锦囊价值排序
	local trickcards = {"alliance_feast","burning_camps","god_salvation","savage_assault","archery_attack",--群体锦囊
	"befriend_attacking","ex_nihilo","duel","snatch","dismantlement","drowning",--单体锦囊
	"iron_chain","await_exhausted","amazing_grace","fight_together","lure_tiger","imperial_order",--几乎不会用到的群体锦囊
	"collateral","known_both","fire_attack","threaten_emperor"}--几乎不会用到的单体锦囊
    local delaycards = {"indulgence","supply_shortage","lightning"}--延时锦囊：乐不思蜀，兵粮寸断，闪电
    local basiccards = {"slash","fire_slash","thunder_slash","peach","analeptic"}--基本牌：普杀，火杀，雷杀，桃，酒

    local can_use = {}
    local value = self:getUseValue(cards[1])
    for _, trick in ipairs(trickcards) do
        local clonecard = sgs.cloneCard(trick)
		local fixed_cards = {"ex_nihilo","threaten_emperor","await_exhausted"}
		if self.player:hasShownSkill("weimu") and cards[1]:isBlack() and table.contains(fixed_cards, trick) then continue end--贾诩不开黑无中
        if self:getUseValue(clonecard) > value then
            clonecard:addSubcard(subcard)
            clonecard:setCanRecast(false)
            local dummyuse = { isDummy = true }
            self:useCardByClassName(clonecard, dummyuse)
            if dummyuse.card then
                table.insert(can_use, trick)
            end
        end
    end
    for _, dtrick in ipairs(delaycards) do
        local clonecard = sgs.cloneCard(dtrick)
        if self:getUseValue(clonecard) > value then
            clonecard:addSubcard(subcard)
            clonecard:setCanRecast(false)
            local dummyuse = { isDummy = true }
            self:useCardByClassName(clonecard, dummyuse)
            if dummyuse.card then
                table.insert(can_use, dtrick)
            end
        end
    end
    for _, basic in ipairs(basiccards) do
        local clonecard = sgs.cloneCard(basic)
        if self:getUseValue(clonecard) > value then
            clonecard:addSubcard(subcard)
            clonecard:setCanRecast(false)
            local dummyuse = { isDummy = true }
            self:useCardByClassName(clonecard, dummyuse)
            if dummyuse.card then
                table.insert(can_use, basic)
            end
        end
    end

    if #can_use > 0 then
		local floors_index = math.random(1, #can_use)--随机一张牌当彩蛋
		if #can_use > 6 then
			floors_index = math.random(1, math.floor((#can_use)/2))
		end
		card_name = can_use[floors_index]
		sgs.ai_use_priority.MiewuCard = math.max(4, self:getDynamicUsePriority(sgs.cloneCard(card_name)))--4是否合适
        return sgs.Card_Parse(str .. card_name)
    end
end

sgs.ai_skill_use_func.MiewuCard = function(card, use, self)
	local userstring = card:toString()--card:getUserString()
	userstring = (userstring:split(":"))[3]
	local miewucard = sgs.cloneCard(userstring)
    miewucard:addSubcard(card:getSubcards():first())
    miewucard:setCanRecast(false)
    if self.player:isCardLimited(miewucard, sgs.Card_MethodUse) then
        return
    end
	self:useCardByClassName(miewucard, use)--确保能使用
	if use.card then
		Global_room:writeToConsole("灭吴卡使用:"..userstring)
		use.card = card
	end
end

function sgs.ai_cardsview.miewu(self, class_name, player, cards)
	if not player:hasShownSkill("miewu") then return end
	if player:getMark("#wuku") == 0 or player:hasFlag("MiewuUsed") or player:isNude() or player:isRemoved() then
        return
    end
    if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
    and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
        if player:getPhase() == sgs.Player_Play then
			return--为简化仅考虑响应时，实际上加强了ai
		end
    end
	if class_name == "Peach" or class_name == "Analeptic"
    or class_name == "Slash" or class_name == "Jink" or class_name == "Nullification" then
        if not cards then
			cards = {}
			for _, c in sgs.qlist(player:getCards("he")) do
				if sgs.cardIsVisible(c, player, self.player) and c:isKindOf(class_name) then
                else
                    table.insert(cards, c)
                end
			end
			for _, id in sgs.qlist(player:getHandPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if sgs.cardIsVisible(c, player, self.player) and c:isKindOf(class_name) then
                else
                    table.insert(cards, c)
                end
			end
		else--防止AI用天兵灭吴……
			local self_cards = {}
			for _, c in ipairs(cards) do
				local card_place = self.room:getCardPlace(c:getEffectiveId())
				if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(c:getEffectiveId())) then
					table.insert(self_cards, c)
				end
			end
			cards = self_cards
		end
        if #cards < 1 then return {} end
		--只有一个灭吴并且持牌充裕时,考虑保留
		if player:getMark("#wuku") == 1 and player:getCardCount(true) > 1 and (class_name == "Slash" or class_name == "Jink") then
			for _, c in ipairs(cards) do
				if c:isKindOf(class_name) then
					return {}
				end
			end
			--其他情况,尽量使用
		end
        --[[if player:getPhase() <= sgs.Player_Play then
            sgs.ais[player:objectName()]:sortByUseValue(cards, true)
        else

        end]]
        sgs.ais[player:objectName()]:sortByKeepValue(cards)

        local className2objectName = { Peach = "peach", Analeptic = "analeptic",
                     Slash = "slash", Jink = "jink", Nullification = "heg_nullification" }--优先国无懈
		local object_name = className2objectName[class_name]
        if class_name == "Slash" then
            local slash = {"slash","fire_slash","thunder_slash"}--随机属性杀
            object_name = slash[math.random(1, #slash)]
        end
        local clonecard = sgs.cloneCard(object_name)

        local function count_value(acard)
        --由于getUseValue会调用getCardsNum，会再次进入视为卡函数导致死循环。身份蛊惑在smart-ai里单独处理
        --[[if player:getPhase() <= sgs.Player_Play then
                return sgs.ais[player:objectName()]:getUseValue(acard)
            else

            end]]
            return sgs.ais[player:objectName()]:getKeepValue(acard)
        end

        local value = count_value(clonecard)
		local nullification_indulgence = (player:getPhase() == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Play)
			and class_name == "Nullification" and player:containsTrick("indulgence") and (player:getHandcardNum() > 3 or player:getHandcardNum() > player:getHp() - 1))
        ----可闪的酒杀应该闪而非保留桃(需要当前杀的data)
		for _, c in ipairs(cards) do--未考虑留桃留无懈等
            local card_value = count_value(c)
			if card_value < value or nullification_indulgence or(card_value <= 4.1 and player:getCardCount(true) == 1) then
                Global_room:writeToConsole("灭吴卡打出:"..object_name)
                return "@MiewuCard=" .. c:getEffectiveId() .. ":" .. object_name
            end
        end
	end
end

sgs.ai_view_as.miewu = function(card, player, card_place)--只为无懈自己的乐,因为ai_cardsview触发频率不够,经常2灭吴被乐弃一把高质量牌
	if not player:hasShownSkill("miewu") then return end
	if player:getMark("#wuku") == 0 or player:hasFlag("MiewuUsed") or player:isNude() or player:isRemoved() then
        return
    end
    if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
    and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
        if player:getPhase() == sgs.Player_Play then
			return--为简化仅考虑响应时，实际上加强了ai
		end
    end
	local nullification_indulgence = (player:getPhase() == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Play)
		and player:containsTrick("indulgence") and (player:getHandcardNum() > 3 or player:getHandcardNum() > player:getHp() - 1))
	if not nullification_indulgence then return end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) then
		if not card:isKindOf("Nullification") then
			return ("nullification:miewu[%s:%s]=%d%s"):format(suit, number, card_id, "&miewu")
		end
	end
end

function sgs.ai_cardneed.miewu(to, card, self)
	return to:isNude() and to:getMark("#wuku") > 0
end

--李丰
sgs.ai_skill_invoke.tunchu = function(self, data)
	if not (self:willShowForAttack() or self:willShowForDefence()) then return false end
	local target = 0
	local goodtarget = 0
	local slashnum = 0
	local needburst = 0

	for _, slash in ipairs(self:getCards("Slash")) do
		for _,enemy in ipairs(self.enemies) do
			if self:slashIsEffective(slash, enemy) then
				slashnum = slashnum + 1
				break
			end
		end
	end

	for _,enemy in ipairs(self.enemies) do
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
				goodtarget = goodtarget + 1
				break
			end
		end
	end

	for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) then
			target = target + 1
			break
		end
	end

	if slashnum > 1 or (slashnum > 0 and goodtarget > 0) then needburst = 1 end
	self:sort(self.enemies,"defenseSlash")
	local can_save_card_num = self.player:getMaxCards() - self.player:getHandcardNum()
	if target == 0 or can_save_card_num > 1 or self.player:isSkipped(sgs.Player_Play) then return true end
	--if self:needBear() then return true end

	for _,enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if self:slashProhibit(slash, enemy) then
		elseif eff and def < 8 and needburst > 0 then return false
		end
	end
	return true
end

sgs.ai_skill_exchange.tunchu_push = function(self, pattern, max_num, min_num, expand_pile)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	--self:sortByKeepValue(cards)
	local to_push = {}
	for _, c in ipairs(cards) do
		table.insert(to_push, c:getEffectiveId())
		if #to_push >= max_num then break end
	end
	return to_push
end

sgs.ai_skill_exchange.shuliang = function(self, pattern, max_num, min_num, expand_pile)
	--local target = self.room:getCurrent()
	local cards = self.player:getPile("food")
	return {cards[1]:getEffectiveId()}
end	

--凌操
sgs.ai_skill_invoke.dujin = function(self, data)
	if #self.friends_noself == 0 then return true end
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		local reward = true
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:hasShownOneGeneral() then
				reward = false
				break
			end
		end
		if reward then return true end
	end
	if math.ceil(self.player:getEquips():length() / 2) > 0 then
		return true
	end
	return false
end