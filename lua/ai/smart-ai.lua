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

-- This is the Smart AI, and it should be loaded and run at the server side

-- "middleclass" is the Lua OOP library written by kikito
-- more information see: https://github.com/kikito/middleclass


-- initialize the random seed for later use
math.randomseed(os.time())

-- SmartAI is the base class for all other specialized AI classes
SmartAI = (require "middleclass").class("SmartAI")

AIversion = "QSanguosha AI 20220101 00:00(UTC+8)"

--- this function is only function that exposed to the host program
--- and it clones an AI instance by general name
-- @param player The ServerPlayer object that want to create the AI object
-- @return The AI object
function CloneAI(player)
	return SmartAI(player).lua_ai
end

sgs.ais =                   {}
sgs.ai_card_intention =     {}
sgs.ai_playerchosen_intention = {}
sgs.ai_Yiji_intention =     {}
sgs.ai_keep_value =         {}
sgs.ai_use_value =          {}
sgs.ai_use_priority =       {}
sgs.ai_suit_priority =      {}
sgs.ai_skill_invoke =       {}
sgs.ai_skill_suit =         {}
sgs.ai_skill_cardask =      {}
sgs.ai_skill_choice =       {}
sgs.ai_skill_askforag =     {}
sgs.ai_skill_askforyiji =   {}
sgs.ai_skill_pindian =      {}
sgs.ai_skill_playerchosen = {}
sgs.ai_skill_discard =      {}
sgs.ai_skill_movecards =    {}
sgs.ai_skill_transfercardchosen =    {}
sgs.ai_skill_exchange = 	{}
sgs.ai_cardshow =           {}
sgs.ai_nullification =      {}
sgs.ai_skill_cardchosen =   {}
sgs.ai_skill_cardschosen =   {}
sgs.ai_skill_use =          {}
sgs.ai_cardneed =           {}
sgs.ai_skill_use_func =     {}
sgs.ai_skills =             {}
sgs.ai_slash_weaponfilter = {}
sgs.ai_slash_prohibit =     {}
sgs.ai_trick_prohibit =     {}
sgs.ai_view_as =            {}
sgs.ai_cardsview =          {}
sgs.ai_cardsview_priority =    {}
sgs.dynamic_value =         {
	damage_card =           {},
	control_usecard =       {},
	control_card =          {},
	lucky_chance =          {},
	benefit =               {}
}
sgs.ai_choicemade_filter =  {
	cardUsed =              {},
	cardResponded =         {},
	skillInvoke =           {},
	skillChoice =           {},
	Nullification =         {},
	playerChosen =          {},
	cardChosen =            {},
	Yiji =                  {},
	viewCards =             {},
	guanxingViewCards =     {},
	pindian =               {}
}

sgs.card_lack =             {}
sgs.ai_need_damaged =       {}
sgs.ai_debug_func =         {}
sgs.ai_chat_func =          {}
sgs.ai_event_callback =     {}
sgs.ai_NeedPeach =          {}
sgs.shown_kingdom =         {
	wei = 0,
	shu = 0,
	wu = 0,
	qun = 0,
	careerist = 0
}
sgs.ai_damage_effect =      {}
sgs.ai_explicit =           {}
sgs.ai_loyalty =            {
	wei = {},
	shu = {},
	wu = {},
	qun = {},
	careerist = {}
}
sgs.RolesTable =            {
	"lord",
	"loyalist",
	"renegade",
	"rebel",
	"careerist"
}
sgs.KingdomsTable =         {
	"wei",
	"shu",
	"wu",
	"qun",
	"careerist"
}
sgs.current_mode_players = {
	wei = 0,
	shu = 0,
	wu = 0,
	qun = 0,
	careerist = 0
}
sgs.general_shown = {}
sgs.Slash_Natures = {
	Slash = sgs.DamageStruct_Normal,
	FireSlash = sgs.DamageStruct_Fire,
	ThunderSlash = sgs.DamageStruct_Thunder,
}
sgs.robot = {}
sgs.ai_guangxing = {}

for i = sgs.NonTrigger, sgs.NumOfEvents, 1 do
	sgs.ai_debug_func[i] = {}
	sgs.ai_chat_func[i] = {}
	sgs.ai_event_callback[i] = {}
end

function SetInitialTables()
	sgs.ai_type_name = {"SkillCard", "BasicCard", "TrickCard", "EquipCard"}
	sgs.priority_skill = 	"jianan|yiji|fangzhu|tuxi|luoshen|jixi|qice|jieyue|zaoyun|" ..
							"shouyue|paoxiao|jizhi|tieqi|liegong|jili|xuanhuo|tongdu|" ..
							"jiahe|xiaoji|guose|tianxiang|fanjian|buqu|xuanlue|diaodu|" ..
							"hongfa|jijiu|luanji|wansha|jianchu|qianhuan|yigui|fudi|yongsi|"..
							"paiyi|suzhi|shilu|huaiyi|chenglve|congcha|jinfa|lixia|"..
							"zhukou|jinghe|guowu|shenwei|wanggui|boyan|kuangcai|"..
							"miewu|guishu|sidi|danlao|wanglie|zhuidu"
	sgs.masochism_skill = "yiji|fankui|jieming|ganglie|fangzhu|hengjiang|jianxiong|qianhuan|zhiyu|jihun|fudi|" ..
						  "bushi|shicai|quanji|zhaoxin|fankui_simazhao|wanggui|sidi|shangshi|benyu"
	sgs.defense_skill = "qingguo|longdan|kongcheng|niepan|bazhen|kanpo|xiangle|tianxiang|liuli|qianxun|leiji|duanchang|beige|weimu|" ..
						"tuntian|shoucheng|yicheng|qianhuan|jizhao|wanwei|enyuan|buyi|keshou|qiuan|biluan|jiancai|aocai|" ..
						"xibing|zhente|qiao|shejian|yusui|deshao|yuanyu|mingzhe|jilei|shigong|dingke|shefu"
	sgs.usefull_skill = "tiandu|qiaobian|xingshang|xiaoguo|wusheng|guanxing|qicai|jizhi|kuanggu|lianhuan|huoshou|juxiang|shushen|zhiheng|keji|" ..
						"duoshi|xiaoji|hongyan|haoshi|guzheng|zhijian|shuangxiong|guidao|guicai|xiongyi|mashu|lirang|yizhi|shengxi|" ..
						"xunxun|wangxi|yingyang|hunshang|biyue"
	sgs.attack_skill = "paoxiao|duanliang|quhu|rende|tieqi|liegong|huoji|lieren|qixi|kurou|fanjian|guose|tianyi|dimeng|duanbing|fenxun|wushuang|" ..
						"lijian|luanji|kuangfu|huoshui|qingcheng|tiaoxin|shangyi|jiang|chuanxin"
	sgs.drawcard_skill = "yingzi_sunce|yingzi_zhouyu|haoshi|yingzi_flamemap|haoshi_flamemap|shelie|jieyue|congcha|zisui"
	sgs.force_slash_skill = "tieqi|tieqi_xh|liegong|liegong_xh|wushuang|jianchu|wushuang_lvlingqi|wanglie"--qianxi--感觉潜袭不太行,驳言都没算
	sgs.wizard_skill = 		"guicai|guidao|midao|tiandu|zhuwei|huanshi"
	sgs.wizard_harm_skill = "guicai|guidao|midao"
	sgs.lose_equip_skill = 	"xiaoji|xuanlue"
	sgs.need_kongcheng = 	"kongcheng"
	sgs.save_skill = 		"jijiu|yigui|buyi|aocai"
	sgs.exclusive_skill = 	"duanchang|buqu"
	sgs.throw_crossbow_skill = "fankui|ganglie|fankui_simazhao|qiao"
	sgs.drawpeach_skill =	"tuxi|qiaobian|elitegeneralflag|huaiyi|jinfa|daoshu|weimeng"
	sgs.recover_skill =		"rende|kuanggu|zaiqi|jieyin|shenzhi|buqu|buyi"
	sgs.Active_cardneed_skill =		"qiaobian|duanliang|rende|paoxiao|guose|qixi|jieyin|zhiheng|tianyi|duoshi|dimeng|luanji|shuangxiong|lirang|" ..
									"qice|jili|fengshix|zaoyun|huaiyi|shilu|baolie|lianpian|tongdu|juejue|duannian|jinghe|yanzheng|kuangcai|guishu"
	sgs.notActive_cardneed_skill =	"guicai|xiaoguo|kanpo|guidao|beige|jijiu|liuli|tianxiang|zhendu|qianhuan|keshou|fudi|shejian|huanshi"
	sgs.cardneed_skill =  	sgs.Active_cardneed_skill .. "|" .. sgs.notActive_cardneed_skill
	sgs.use_lion_skill =	"duanliang|guicai|guidao|lijian|qingcheng|zhiheng|qixi|fenxun|kurou|diaogui|quanji|jinfa|xishe"
	sgs.need_equip_skill = 	"shensu|huyuan|beige|qingcheng|xiaoji|xuanlue|diaodu|biluan|xishe"
	sgs.judge_reason =		"bazhen|EightDiagram|supply_shortage|indulgence|lightning|leiji|beige|tieqi|luoshen|ganglie|tuntian"

	sgs.rule_skill = "transfer|aozhan|companion|halfmaxhp|firstshow|careerman|showhead|showdeputy"

	sgs.Friend_All = 0
	sgs.Friend_Draw = 1
	sgs.Friend_Male = 2
	sgs.Friend_Female = 3
	sgs.Friend_Wounded = 4
	sgs.Friend_MaleWounded = 5
	sgs.Friend_FemaleWounded = 6
--[[
	sgs.general_value = {
						["cacao"] = 3, ["simayi"] = 4, ["xiahoudun"] = 2, ["zhangliao"] = 2.5, ["xuchu"] = 2, ["guojia"] = 5, ["zhenji"] = 4, ["xiahouyuan"] = 2.5, ["zhanghe"] = 3, ["xuhuang"] = 3, ["caoren"] = 2.5, ["dianwei"] = 3.5,
						["xunyu"] = 3.5, ["caopi"] = 4.5, ["yuejin"] = 2.5, ["dengai"] = 4, ["caohong"] = 2, ["lidian"] = 4, ["zangba"] = 2, ["xunyou"] = 3.5, ["bianhuanghou"] = 3,
						["yuji"] = 4.5, ["hetaihou"] = 2.5, ["zhangren"] = 3, ["zhangjiao"] = 3, ["dongzhuo"] = 3, ["liguo"] = 3.5, ["zuoci"] = 4, ["yuanshao"] = 4, ["yanliangwenchou"] = 3.5, ["jiaxu"] = 4, ["lvbu"] = 3, ["huatuo"] = 3.5,
						["diaochan"] = 3.5, ["kongrong"] = 3, ["caiwenji"] = 3, ["mateng"] = 4.5, ["jiling"] = 1.5, ["pangde"] = 2, ["panfeng"] = 1.5, ["zoushi"] = 1.5, ["tianfeng"] = 2.5, ["lord_zhangjiao"] = 5.5,
						["jiangwei"] = 3, ["jiangwanfeiyi"] = 2.5, ["madai"] = 2.5, ["mifuren"] = 2, ["masu"] = 4.5, ["shamoke"] = 3.5, ["zhangfei"] = 3.5, ["guanyu"] = 3, ["liubei"] = 2, ["zhaoyun"] = 2.5, ["machao"] = 2.5,
						["zhugeliang"] = 3.5, ["huangzhong"] = 2.5, ["pangtong"] = 3.8, ["wolong"] = 3, ["huangyueying"] = 4, ["weiyan"] = 2, ["liushan"] = 3, ["ganfuren"] = 1.5, ["menghuo"] = 2.5, ["zhurong"] = 3, ["lord_liubei"] = 5.5,
						["xusheng"] = 2.5, ["jiangqin"] = 2.5, ["chenwudongxi"] = 1, ["sunce"] = 2.5, ["lingtong"] = 3.5, ["lvfan"] = 4.5, ["sunquan"] = 4, ["luxun"] = 3, ["sunshangxiang"] = 4.5, ["sunjian"] = 3, ["xiaoqiao"] = 3,
						["taishici"] = 2.5, ["ganning"] = 2.5, ["daqiao"] = 3.5, ["huanggai"] = 3, ["lvmeng"] = 3, ["zhouyu"] = 3, ["lusu"] = 4, ["dingfeng"] = 2.5, ["zhoutai"] = 3, ["erzhang"] = 3, ["lord_sunquan"] = 5.5,
						["sujiang"] = 0, ["sujiangf"] = 0,
	}
	sgs.general_pair_value = {
						["caocao+lidian"] = 9, ["yuejin+caoren"] = 6, ["zhenji+guojia"] = 12, ["zhenji+simayi"] = 10, ["guojia+dengai"] = 10, ["guojia+xiahoudun"] = 9, ["zhenji+zhanghe"] = 8, ["lidian+zhangliao"] = 5.5,
						["zhanghe+lidian"] = 6, ["zhanghe+xuchu"] = 4, ["lidian+xuchu"] = 5.5,	--wei
						["liguo+zuoci"] = 9, ["yuanshao+yanliangwenchou"] = 8, ["jiaxu+huatuo"] = 8.5, ["huotuo+kongrong"] = 7, ["caiwenji+kongrong"] = 7, ["yuanshao+mateng"] = 9, ["yuanshao+tianfeng"] = 8.5,	--qun
						["zhangfei+huangyueying"] = 8.5, ["huangyueying+zhugeliang"] = 8.5, ["huangyueying+wolong"] = 8, ["liushan+huangyueying"] = 5.5,	--shu
						["sunshangxiang+xusheng"] = 8, ["sunshangxiang+luxun"] = 10, ["sunshangxiang+sunquan"] = 8.5, ["sunshangxiang+lvfan"] = 10, ["lingtong+lvfan"] = 8.5, ["sunshangxiang+lingtong"] = 9,
						["sunshangxiang+daqiao"] = 9, ["daqiao+erzhang"] = 8, ["sunjian+zhoutai"] = 7, ["taishici+sunce"] = 7, ["sunshangxiang+chenwudongxi"] = 6.5,	 --wu
	}
]]

	--Global_room:writeToConsole(debug.getinfo(1).source)--获取当前路径

	sgs.general_value = sgs.readGeneralValuefromtxt()
	assert(sgs.general_value)

	sgs.general_pair_value = sgs.readGeneralPairValuefromtxt()
	assert(sgs.general_pair_value)

	for _, p in sgs.qlist(Global_room:getAlivePlayers()) do
		if p:getState() == "robot" then table.insert(sgs.robot, p) end
		local kingdom = p:getKingdom()
		if kingdom == "god" then
			kingdom = "careerist"
		end
		if not table.contains(sgs.KingdomsTable, kingdom) then
			table.insert(sgs.KingdomsTable, kingdom)
		end
		sgs.ai_loyalty[kingdom] = {}
		sgs.shown_kingdom[p:getKingdom()] = 0
		sgs.ai_explicit[p:objectName()] = "unknown"
		sgs.general_shown[p:objectName()] = {}
		if string.len(p:getRole()) == 0 then
			Global_room:setPlayerProperty(p, "role", sgs.QVariant(p:getKingdom()))
		end
		if not table.contains(sgs.RolesTable, p:getRole()) then
			table.insert(sgs.RolesTable, kingdom)
		end
	end

	for _, p in sgs.qlist(Global_room:getAlivePlayers()) do
		local kingdom = p:getKingdom()
		for kingdom, v in pairs(sgs.ai_loyalty) do
			sgs.ai_loyalty[kingdom][p:objectName()] = 0
		end
	end

end

function SmartAI:initialize(player)
	self.player = player
	self.room = player:getRoom()
	self.role = player:getRole()
	self.lua_ai = sgs.LuaAI(player)
	self.lua_ai.callback = function(full_method_name, ...)
		--The __FUNCTION__ macro is defined as CLASS_NAME::SUBCLASS_NAME::FUNCTION_NAME
		--in MSVC, while in gcc only FUNCTION_NAME is in place.
		local method_name_start = 1
		while true do
			local found = string.find(full_method_name, "::", method_name_start)
			if found ~= nil then
				method_name_start = found + 2
			else
				break
			end
		end
		local method_name = string.sub(full_method_name, method_name_start)
		local method = self[method_name]
		if method then
			local success, result1, result2
			success, result1, result2 = pcall(method, self, ...)
			if not success then
				self.room:writeToConsole(result1)
				self.room:writeToConsole(method_name)
				self.room:writeToConsole(debug.traceback())
				self.room:outputEventStack()
			else
				return result1, result2
			end
		end
	end

	self.retain = 2
	self.keepValue = {}
	self.kept = {}
	self.keepdata = {}
	self.predictedRange = 1
	self.slashAvail = 1

	if not sgs.initialized then
		sgs.initialized = true
		sgs.ais = {}
		sgs.turncount = 0
		sgs.debugmode = true
		Global_room = self.room
		Global_room:writeToConsole(AIversion .. ", Powered by " .. _VERSION)

		SetInitialTables()
	end

	sgs.ais[player:objectName()] = self

	sgs.card_lack[player:objectName()] = {}
	sgs.card_lack[player:objectName()]["Slash"] = 0
	sgs.card_lack[player:objectName()]["Jink"] = 0
	sgs.card_lack[player:objectName()]["Peach"] = 0
	sgs.ai_NeedPeach[player:objectName()] = 0
	sgs.ai_guangxing[player:objectName()] = {}

	sgs.updateAlivePlayerRoles()
	self:updatePlayers(true, true)
	self:assignKeep(true)
end

function sgs.cloneCard(name, suit, number)
	suit = suit or sgs.Card_SuitToBeDecided
	number = number or -1
	local card = sgs.Sanguosha:cloneCard(name, suit, number)
	if not card then Global_room:writeToConsole(debug.traceback()) return end
	card:deleteLater()
	return card
end

function SmartAI:getTurnUse()
	local cards = {}
	for _ ,c in sgs.qlist(self.player:getHandcards()) do
		if c:isAvailable(self.player) then table.insert(cards, c) end
	end
	for _, id in sgs.qlist(self.player:getHandPile()) do
		local c = sgs.Sanguosha:getCard(id)
		if c:isAvailable(self.player) then table.insert(cards, c) end
	end

	local turnUse = {}
	local slash = sgs.cloneCard("slash")
	local slashAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
	self.slashAvail = slashAvail
	self.predictedRange = self.player:getAttackRange()
	self.slash_distance_limit = (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50)

	self.weaponUsed = false
	self:fillSkillCards(cards)

	if self.player:hasWeapon("Crossbow") or #self.player:property("extra_slash_specific_assignee"):toString():split("+") > 1 then
		slashAvail = 100
		self.slashAvail = slashAvail
	end
	local slashes = {}

	for _, card in ipairs(cards) do

		local next = false
		for _, c in ipairs(turnUse) do--减少同名牌重复检索
			if c:objectName() == card:objectName() and c:sameColorWith(card) then
				if card:isKindOf("Slash")  then
					table.insert(slashes, card)
				else
					table.insert(turnUse, card)
				end
				next = true
				break
			end
		end
		if next then
			continue
		end

		local dummy_use = { isDummy = true }
		--[[
		--attempt to call method 'getTypeId' (a nil value)
		if type(card) == "string" then--"."
			Global_room:writeToConsole("exist_"..card)
		end
		--]]
		local type = card:getTypeId()
		self["use" .. sgs.ai_type_name[type + 1]](self, card, dummy_use)
		--[[
		if card:getTypeId() == sgs.Card_TypeSkill then
			Global_room:writeToConsole("exist_"..card:toString())
		end
		--]]
		if dummy_use.card then
			if dummy_use.card:isKindOf("Slash") then
				if dummy_use.card:hasFlag("AIGlobal_KillOff") then table.insert(slashes, dummy_use.card) break end
				table.insert(slashes, dummy_use.card)
			else
				if self.player:hasFlag("InfinityAttackRange") or self.player:getMark("InfinityAttackRange") > 0 then
					self.predictedRange = 10000
				elseif dummy_use.card:isKindOf("Weapon") then
					if not sgs.weapon_range[card:getClassName()] then
						self.room:writeToConsole("weapon_range" .. card:getClassName())
					end
					self.predictedRange = sgs.weapon_range[card:getClassName()] or 1
					self.weaponUsed = true
				else
					self.predictedRange = 1
				end
				if dummy_use.card:objectName() == "Crossbow" then slashAvail = 100 self.slashAvail = slashAvail end
				table.insert(turnUse, dummy_use.card)
			end
			if self:getDynamicUsePriority(dummy_use.card) >= 10 then break end
		end
	end

	if slashAvail > 0 and #slashes > 0 then
		self:sortByUseValue(slashes)
		for i = 1, slashAvail do
			table.insert(turnUse, slashes[i])
		end
	end

	return turnUse
end

function SmartAI:activate(use)
	self:updatePlayers()
	self:assignKeep(true)
	self.toUse = self:getTurnUse()
	self:sortByDynamicUsePriority(self.toUse)
	for _, card in ipairs(self.toUse) do
		if not self.player:isCardLimited(card, card:getHandlingMethod())
			or (card:canRecast() and not self.player:isCardLimited(card, sgs.Card_MethodRecast)) then
			local type = card:getTypeId()

			self["use" .. sgs.ai_type_name[type + 1]](self, card, use)

			if use:isValid(nil) then
				self.toUse = nil
				return
			end
			if use.card and use.card:isKindOf("Slash") and (not use.to or use.to:isEmpty()) then
				self.toUse = nil
				return
			end
			if use.card then self:speak(use.card:getClassName(), self.player:isFemale()) end
		end
	end
	self.toUse = nil
end

function SmartAI:objectiveLevel(player)
	if not player then self.room:writeToConsole(debug.traceback()) return 0 end
	if self.player:objectName() == player:objectName() then return -2 end
	if self.player:isFriendWith(player) then return -2 end
	if self.room:alivePlayerCount() == 2 then return 5 end

	if player:getRole() == "careerist" and player:getActualGeneral1():getKingdom() == "careerist" then--野心家角色
		if self.player:getMark("GlobalBattleRoyalMode") > 0 then
			--Global_room:writeToConsole("鏖战野心家角色:" .. player:objectName())
			return 5
		end
		local focus_careerist = true
		for k, v in pairs(sgs.current_mode_players) do
			if k ~= "careerist" and v > 2 then
				focus_careerist = false
			end
		end
		if focus_careerist then
			--Global_room:writeToConsole("聚焦野心家角色:" .. player:objectName())
			return 5
		end
	end
	if sgs.isRoleExpose() then
		if self.lua_ai:isFriend(player) then return -2
		elseif self.lua_ai:isEnemy(player) then return 5
		elseif self.lua_ai:relationTo(player) == sgs.AI_Neutrality then
			if self.lua_ai:getEnemies():isEmpty() then return 4 else return 0 end
		else return 0 end
	end

	local self_kingdom = self.player:getKingdom()
	local player_kingdom_evaluate = self:evaluateKingdom(player)
	local player_kingdom_explicit = sgs.ai_explicit[player:objectName()]
	if player_kingdom_explicit == "unknown" then
		local mark = string.format("KnownBoth_%s_%s", self.player:objectName(), player:objectName())
		if player:getMark(mark) > 0 then
			player_kingdom_explicit = player:getRole() == "careerist" and "careerist" or player:getKingdom()
		end
	end

	local upperlimit = self.player:getLord() and 99 or math.floor(self.room:getPlayers():length() / 2)
	if (not sgs.isAnjiang(self.player) or sgs.shown_kingdom[self_kingdom] < upperlimit) and self.role ~= "careerist" and self_kingdom == player_kingdom_explicit then return -2 end
	if self:getKingdomCount() <= 2 then return 5 end

	local selfIsCareerist = self.role == "careerist" or (sgs.shown_kingdom[self_kingdom] >= upperlimit and not self.player:hasShownOneGeneral()) 
		or (self.player:getActualGeneral1():getKingdom() == "careerist" and not (self.player:hasShownGeneral1() and self.role ~= "careerist"))
		
	local gameProcess = sgs.gameProcess()
	if gameProcess == "===" then
		if player:getMark("KnownBothEnemy" .. self.player:objectName()) > 0 then return 5 end
		if not selfIsCareerist and sgs.shown_kingdom[self_kingdom] < upperlimit then
			if sgs.isAnjiang(player) and player_kingdom_explicit == "unknown" then
				if player_kingdom_evaluate == self_kingdom then return -1
				elseif string.find(player_kingdom_evaluate, self_kingdom) then return 0
				elseif player_kingdom_evaluate == "unknown" and player:getHp() <= 1 then return 0
				else
					return self:getOverflow() > 0 and 3.5 or 0
				end
			else
				return 5
			end
		elseif selfIsCareerist then
			return 5
		else
			return self:getOverflow() > 0 and 4 or 0
		end
	elseif string.find(gameProcess, ">") then
		local kingdom = gameProcess:split(">")[1]
		if string.find(gameProcess, ">>>>") then
			local longest = string.match(gameProcess, "%p+>")--最多的>
			if string.find(gameProcess, self_kingdom..longest) and not selfIsCareerist then
				if sgs.shown_kingdom[self_kingdom] < upperlimit and sgs.isAnjiang(player)
					and (player_kingdom_evaluate == self_kingdom or string.find(player_kingdom_evaluate, self_kingdom)) then return 0
				elseif player_kingdom_evaluate == "unknown" and sgs.turncount <= 0 then return 0
				else return 5
				end
			elseif selfIsCareerist and string.find(gameProcess, "careerist"..longest) then
				return 5
			else
				if string.find(gameProcess, player_kingdom_explicit..longest) then return 5
				elseif string.find(gameProcess, player_kingdom_evaluate..longest) then return 5
				elseif player_kingdom_evaluate == "unknown" then return -1
				elseif not string.find(player_kingdom_evaluate, kingdom) then return -1
				else return 0
				end
			end
		elseif string.find(gameProcess, ">>>") then
			if string.find(gameProcess, self_kingdom..">>>") and not selfIsCareerist then--self_kingdom == kingdom
				if sgs.shown_kingdom[self_kingdom] < upperlimit and sgs.isAnjiang(player)
					and (player_kingdom_evaluate == self_kingdom or string.find(player_kingdom_evaluate, self_kingdom)) then return 0
				elseif player_kingdom_evaluate == "unknown" and sgs.turncount <= 0 then return 0
				else return 5
				end
			elseif selfIsCareerist and string.find(gameProcess, "careerist>>") then
				return 5
			else
				if string.find(gameProcess, player_kingdom_explicit..">>>") then return 5--player_kingdom_explicit == kingdom
				elseif string.find(gameProcess, player_kingdom_evaluate..">>>") then return 5--player_kingdom_evaluate == kingdom
				elseif player_kingdom_evaluate == "unknown" then return 0
				elseif not string.find(player_kingdom_evaluate, kingdom) then return -1
				else return 3
				end
			end
		elseif string.find(gameProcess, ">>") then
			if string.find(gameProcess, self_kingdom..">>") and not selfIsCareerist then
				if sgs.shown_kingdom[self_kingdom] < upperlimit and sgs.isAnjiang(player) then
					if player_kingdom_evaluate == self_kingdom then return -1
					elseif string.find(player_kingdom_evaluate, self_kingdom) then return 0
					elseif player_kingdom_evaluate == "unknown" and sgs.turncount <= 0 then return 0
					end
				end
				return 5
			elseif selfIsCareerist and string.find(gameProcess, "careerist>") then
				return 5
			else
				if string.find(gameProcess, player_kingdom_explicit..">>") or string.find(gameProcess, player_kingdom_evaluate..">>") then return 5
				elseif not string.find(player_kingdom_evaluate, kingdom) then return 0
				elseif kingdom == "careerist" then return -1
				else return 3
				end
			end
		else
			if self_kingdom == kingdom and not selfIsCareerist then
				if sgs.shown_kingdom[self_kingdom] < upperlimit and sgs.isAnjiang(player) then
					if player_kingdom_evaluate == self_kingdom then return -1
					elseif string.find(player_kingdom_evaluate, self_kingdom) then return 0
					elseif player_kingdom_evaluate == "unknown" and sgs.turncount <= 0 then return 0
					end
				end
				return 5
			elseif selfIsCareerist and string.find(gameProcess, "careerist>") then
				return 5
			else
				local isWeakPlayer = player:getHp() == 1 and not player:hasShownSkill("duanchang") and self:isWeak(player)
										and (player:isKongcheng() or sgs.card_lack[player:objectName()] == 1 and player:getHandcardNum() <= 1)
										and (self:getReward(player) >= 2 or self.player:aliveCount() <= 4)--鏖战处理？
				if player_kingdom_explicit == kingdom or isWeakPlayer then return 5
				elseif player_kingdom_evaluate == kingdom then return 3
				elseif player_kingdom_explicit == "careerist" and string.find(gameProcess, "careerist>") then return 5
				elseif not string.find(player_kingdom_evaluate, kingdom) then return 0
				else return 1
				end
			end
		end
	end
end

function sgs.gameProcess(update)
	if not update and sgs.ai_process then return sgs.ai_process end

	local scenario = Global_room:getScenario()
	if scenario and scenario:objectName() == "jiange_defense" then return "wei>>>" end

	local value = {}
	local kingdoms = sgs.KingdomsTable
	for _, kingdom in ipairs(kingdoms) do
		value[kingdom] = 0
	end

	local anjiang = {}
	local players = Global_room:getAlivePlayers()
	local all_num = Global_room:getAllPlayers(true):length()
	local first_careerist = 0
	local second_careerist = 0
	for _, ap in sgs.qlist(players) do
		if table.contains(kingdoms, sgs.ai_explicit[ap:objectName()]) then
			local v = 0
			if ap:hasShownOneGeneral() then
				--[[旧化身，sgs.getDefense已重写
				local huashen = ap:hasShownSkill("huashen") and ap:getTag("Huashens"):toList():length() > 0
				v = sgs.getDynamicPlayerStrength(ap, huashen) + sgs.getChaofeng(ap) / 2]]
				v = 7 + sgs.getChaofeng(ap) / 2--7是否合适？
			else
				v = 6 + sgs.getChaofeng(ap) / 2--6是何意？
			end
			if sgs.ai_explicit[ap:objectName()] ~= "careerist" then--避免君主死后野心家大乱斗
				value[sgs.ai_explicit[ap:objectName()]] = value[sgs.ai_explicit[ap:objectName()]] + v
			else
				--(self.player:getActualGeneral1():getKingdom() == "careerist" and not (self.player:hasShownGeneral1() and self.role ~= "careerist"))
				if ap:hasShownGeneral1() and ap:getActualGeneral1():getKingdom() == "careerist" then
					if first_careerist == 0 then 
						first_careerist = v
					else
						if second_careerist == 0 then 
							first_careerist,second_careerist = math.max(first_careerist, v),math.min(first_careerist, v)
						else
							if v > first_careerist then
								first_careerist,second_careerist = v,first_careerist
							elseif v > second_careerist then
								second_careerist = v
							end
						end
					end
				elseif value["careerist"] then
					value["careerist"] = math.max(value["careerist"], v)
				end
			end
		else
			table.insert(anjiang, ap)
		end
	end

	local get_possible_kingdom = function(player)
		local max_value, max_kingdom = 0, {}
		for kingdom, v in pairs(sgs.ai_loyalty) do
			if not table.contains(sgs.KingdomsTable, kingdom) then continue end
			if sgs.ai_loyalty[kingdom][player:objectName()] > max_value then
				max_value = sgs.ai_loyalty[kingdom][player:objectName()]
			end
		end
		if max_value > 0 then
			for kingdom, v in pairs(sgs.ai_loyalty) do
				if not table.contains(sgs.KingdomsTable, kingdom) then continue end
				if sgs.ai_loyalty[kingdom][player:objectName()] == max_value then
					table.insert(max_kingdom, kingdom)
				end
			end
		end
		return #max_kingdom > 0 and table.concat(max_kingdom, "?") or "unknown"
	end

	local anjiang_copy = table.copyFrom(anjiang)
	for _, p in ipairs(anjiang) do
		local kingdom_evaluate = get_possible_kingdom(p)
		local possible_kingdoms = kingdom_evaluate:split("?")
		if #possible_kingdoms == 1 and kingdom_evaluate ~= "unknown" then
			value[kingdom_evaluate] = value[kingdom_evaluate] + 6 + sgs.getChaofeng(p) / 2
			table.removeOne(anjiang_copy, p)
		elseif #possible_kingdoms > 1 then
			local point = (6 + sgs.getChaofeng(p) / 2) / #possible_kingdoms
			if string.find(kingdom_evaluate, "wei") then
				value["wei"] = value["wei"] + point
			elseif string.find(kingdom_evaluate, "qun") then
				value["qun"] = value["qun"] + point
			elseif string.find(kingdom_evaluate, "shu") then
				value["shu"] = value["shu"] + point
			elseif string.find(kingdom_evaluate, "wu") then
				value["wu"] = value["wu"] + point
			elseif string.find(kingdom_evaluate, "careerist") then--队友藏野心家情况？
				--value["careerist"] = value["careerist"] + point
				--避免野心家大乱斗
				value["careerist"] = math.max(value["careerist"], point)
			end
			table.removeOne(anjiang_copy, p)
		end
	end
	--野心家最多算两次,避免野心家大乱斗
	if value["careerist"] then
		if value["careerist"] > first_careerist then
			first_careerist,second_careerist = value["careerist"],first_careerist
		elseif value["careerist"] > second_careerist then
			second_careerist = value["careerist"]
		end
		value["careerist"] = first_careerist + second_careerist
	end
	
	local cmp = function(a, b)
		return value[a] > value[b]
	end
	table.sort(kingdoms, cmp)

	if #anjiang_copy > 0 then
		local anjiang_num = #anjiang_copy
		local anjiang_value = 0
		for _, p in ipairs(anjiang) do
			anjiang_value = anjiang_value + 6 + sgs.getChaofeng(p) / 2
		end
		for i = 1, #kingdoms do
			local playerNum = players:first():getPlayerNumWithSameKingdom("AI", kingdoms[i])
			if Global_room:getLord(kingdoms[i]) then
				value[kingdoms[i]] = value[kingdoms[i]] + anjiang_value / anjiang_num / (#kingdoms - i + 1)
				anjiang_value = anjiang_value - anjiang_value / anjiang_num / (#kingdoms - i + 1)
				anjiang_num = anjiang_num - anjiang_num / (#kingdoms - i + 1)
			else
				value[kingdoms[i]] = value[kingdoms[i]] + math.min((math.floor(all_num / 2) - playerNum), anjiang_num / (#kingdoms + 1 - i)) * anjiang_value / anjiang_num
				anjiang_value = anjiang_value - math.min((math.floor(all_num / 2) - playerNum), anjiang_num / (#kingdoms + 1 - i)) * anjiang_value / anjiang_num
				anjiang_num = anjiang_num - math.min((math.floor(all_num / 2) - playerNum), anjiang_num / (#kingdoms + 1 - i))
			end
		end
	end

	table.sort(kingdoms, cmp)

	--旧
	--local sum_value1, sum_value2, sum_value3 = 0, 0, 0
	--for i = 2, #kingdoms do
	--	sum_value1 = sum_value1 + value[kingdoms[i]]
	--	if i < #kingdoms then sum_value2 = sum_value2 + value[kingdoms[i]] end
	--	if i < #kingdoms - 1 then sum_value3 = sum_value3 + value[kingdoms[i]] end
	--end

	--local process = "==="
	--if value[kingdoms[1]] >= sum_value1 and value[kingdoms[1]] > 0 then
	--	process = kingdoms[1] .. ">>>"
	--elseif value[kingdoms[1]] >= sum_value2 and value[kingdoms[1]] > 0 then
	--	process = kingdoms[1] .. ">>"
	--elseif value[kingdoms[1]] >= sum_value3 and value[kingdoms[1]] > 0 then
	--	process = kingdoms[1] .. ">"
	--end

	local process = ""
	for i = 1, #kingdoms-1 do
		if value[kingdoms[i]] > 0 then
			process = process .. kingdoms[i]
			local sum_value = 0
			for j = #kingdoms, i+1, -1 do
				if value[kingdoms[j]] > 0 then
					sum_value = sum_value + value[kingdoms[j]]
					if value[kingdoms[i]] > sum_value then
						process = process .. ">"
					end
				end
			end
			if sgs.turncount > 1 then--人数占优势怎么处理更好？如4 2 1 1; 5 3 1 1
				for j = #kingdoms, i+1, -1 do
					if value[kingdoms[j]] > 0 and value[kingdoms[i]] > value[kingdoms[j]] * 2 then
						process = process .. ">"
						break
					end
				end
				for j = #kingdoms, i+1, -1 do
					if value[kingdoms[j]] > 0 and value[kingdoms[i]] > value[kingdoms[j]] * 3.5 then
						process = process .. ">"
						break
					end
				end
			else--首轮人数占优势
				local max_num = players:first():getPlayerNumWithSameKingdom("AI", kingdoms[i])
				if max_num >= math.floor(players:length() / 2) then--若某势力不小于全场半数，且不是两势力对半
					for j = #kingdoms, i+1, -1 do
						local min_num = players:first():getPlayerNumWithSameKingdom("AI", kingdoms[j])
						if value[kingdoms[j]] > 0 and not min_num == max_num then
							process = process .. ">"
							break
						end
					end
					if not string.find(process, ">>>") then process = process .. ">" end--保底大优势
				end
			end
			process = process .. "|"
		end
	end
	process = process .. kingdoms[#kingdoms]
	if not string.find(process, ">") or (not string.find(process, ">>") and sgs.turncount <= 1) then
		process = "==="--第一回合或均势
	end

	sgs.ai_process = process
	return process
end

function sgs.getDynamicPlayerStrength(player, ishuashen)

	local g1, g2
	if not ishuashen then
		g1 = player:getGeneral()
		g2 = player:getGeneral2()
	else
		local huashens = player:getTag("Huashens"):toList()
		local names = {}
		for _, q in sgs.qlist(huashens) do
			table.insert(names, q:toString())
		end
		g1 = sgs.Sanguosha:getGeneral(names[1])
		g2 = sgs.Sanguosha:getGeneral(names[2])
	end

	local current_value = 0
	for name, value in pairs(sgs.general_pair_value) do
		if g1:objectName() .. "+" .. g2:objectName() == name or g2:objectName() .. "+" .. g1:objectName() == name then
			current_value = value
			break
		end
	end
	local oringin_g1 = 3
	local oringin_g2 = 3
	for name, value in pairs(sgs.general_value) do
		if g1:objectName() == name then oringin_g1 = value end
		if g2:objectName() == name then oringin_g2 = value end
	end

	if current_value == 0 then
		local oringin_g1 = 3
		local oringin_g2 = 3
		for name, value in pairs(sgs.general_value) do
			if g1:objectName() == name then oringin_g1 = value end
			if g2:objectName() == name then oringin_g2 = value end
		end
		current_value = oringin_g1 + oringin_g2
	end

	local hp_ajust = player:getMaxHp() - math.min(g1:getMaxHpHead(), g2:getMaxHpDeputy())
	if hp_ajust > 0 and not player:hasShownSkill("benghuai") then
		for i = 1, hp_ajust, 1 do
			current_value = current_value - 1
		end
	end

	if ishuashen then
		for _, skill in sgs.qlist(g1:getVisibleSkillList(true, player:inHeadSkills("huashen"))) do
			if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and player:getMark(skill:getLimitMark()) == 0 then
				current_value = current_value - 1
			end
		end
		for _, skill in sgs.qlist(g2:getVisibleSkillList(true, player:inHeadSkills("huashen"))) do
			if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and player:getMark(skill:getLimitMark()) == 0 then
				current_value = current_value - 1
			end
		end
	else
		for _, skill in sgs.qlist(g1:getVisibleSkillList(true, true)) do
			if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and player:getMark(skill:getLimitMark()) == 0 then
				current_value = current_value - 1
			end
		end
		for _, skill in sgs.qlist(g2:getVisibleSkillList(true, false)) do
			if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and player:getMark(skill:getLimitMark()) == 0 then
				current_value = current_value - 1
			end
		end
	end

	if g1:isCompanionWith(g2:objectName()) and player:getMark("CompanionEffect") == 0 then
		current_value = current_value - 0.5
	end
	if player:hasShownSkills(sgs.cardneed_skill) then
		if player:getHandcardNum() < 3 then
			current_value = current_value - 0.4
		elseif player:getHandcardNum() < 5 then
			current_value = current_value + 0.5
		end
	end
	if player:hasShownSkills(sgs.masochism_skill) then
		if player:getHp() < 2 then
			current_value = current_value - 0.3
		end
		for i = 1, player:getHp() - 3, 1 do
			current_value = current_value + 1
		end
		--[[
		for i = 1, getKnownCard(player, self.player, "Peach", true, "he"), 1 do
			current_value = current_value + 0.15
		end
		for i = 1, getKnownCard(player, self.player, "Analeptic", true, "he"), 1 do
			current_value = current_value + 0.1
		end
		--]]
	end
	if player:hasShownSkills(sgs.lose_equip_skill) then
		--if not player:hasEquip() and getKnownCard(player, self.player, "EquipCard", true, "h") < 2 then
		--	current_value = current_value - 0.3
		--end
		--for i = 1, getKnownCard(player, self.player, "EquipCard", true, "he") - 2, 1 do
		--	current_value = current_value + 0.15
		--end
		for i = 1, player:getEquips():length(), 1 do
			current_value = current_value + 0.15
		end
		for _, p in sgs.qlist(Global_room:getOtherPlayers(player)) do
			if p:isFriendWith(player) then
				if p:hasShownSkill("duoshi") then
					current_value = current_value + 0.4
				end
				if p:hasShownSkill("zhijian") then
					current_value = current_value + 0.3
				end
			end
		end
	end
	if player:hasShownSkills("qianhuan") then
		for _, p in sgs.qlist(Global_room:getAllPlayers()) do
			if p:isFriendWith(player) and p:hasShownSkills("jijiu") then
				current_value = current_value + 5
			end
			if p:isFriendWith(player) and not p:objectName() == player:objectName() then
				current_value = current_value + 3
			end
		end
	end
	if player:getLord() and player:getLord():isAlive() and not player:getLord():getPile("flame_map"):isEmpty() then
		current_value = current_value + 0.5 * player:getLord():getPile("flame_map"):length()
	end
	--[[
	if player:hasShownSkill("jizhi") then
		for i = 1, getKnownCard(player, self.player, "TrickCard", false, "he"), 1 do
			current_value = current_value + 0.1
		end
	end
	--]]
	return current_value
end

function SmartAI:evaluateKingdom(player, other)
	if not player then self.room:writeToConsole(debug.traceback()) return "unknown" end
	other = other or self.player
	if sgs.isRoleExpose() then
		return player:getRole() == "careerist" and "careerist" or player:getKingdom()
	end
	if sgs.ai_explicit[player:objectName()] ~= "unknown" then return sgs.ai_explicit[player:objectName()] end
	if player:getMark(string.format("KnownBoth_%s_%s", other:objectName(), player:objectName())) > 0 then
		local upperlimit = player:getLord() and 99 or math.floor( self.room:getPlayers():length() / 2)
		return sgs.shown_kingdom[player:getKingdom()] < upperlimit and player:getKingdom() or "careerist"
	end

	if player:getMark("KnownBothFriend" .. other:objectName()) > 0 then
		local upperlimit = self.player:getLord() and 99 or math.floor(self.room:getPlayers():length() / 2)
		return sgs.shown_kingdom[player:getKingdom()] < upperlimit and other:getKingdom() or "careerist"
	end

	local max_value, max_kingdom = 0, {}
	local KnownBothEnemy = player:getMark("KnownBothEnemy" .. other:objectName()) > 0
	for kingdom, v in pairs(sgs.ai_loyalty) do
		if not table.contains(sgs.KingdomsTable, kingdom) then continue end
		if KnownBothEnemy and kingdom == other:getKingdom() then continue end
		if sgs.ai_loyalty[kingdom][player:objectName()] > max_value then
			max_value = sgs.ai_loyalty[kingdom][player:objectName()]
		end
	end
	if max_value > 0 then
		for kingdom, v in pairs(sgs.ai_loyalty) do
			if not table.contains(sgs.KingdomsTable, kingdom) then continue end
			if sgs.ai_loyalty[kingdom][player:objectName()] == max_value then
				table.insert(max_kingdom, kingdom)
			end
		end
	end

	local wangping = sgs.findPlayerByShownSkillName("jianglve")--王平势力召唤
	if wangping and wangping:getKingdom() ~= "careerist" and wangping:getMark("@strategy") < 1 and not player:hasShownOneGeneral() then
		if #max_kingdom > 0 then
			table.removeOne(max_kingdom, wangping:getKingdom())
		else
			for _, k in ipairs(sgs.KingdomsTable) do
				if k ~= wangping:getKingdom() then
					table.insert(max_kingdom, k)
				end
			end
		end
	end

	return #max_kingdom > 0 and table.concat(max_kingdom, "?") or "unknown"
end

function sgs.isAnjiang(player, another)
	if not player:hasShownOneGeneral() and sgs.ai_explicit[player:objectName()] ~= "unknown" then
		Global_room:writeToConsole(sgs.Sanguosha:translate(player:getGeneralName()).. "/" .. sgs.Sanguosha:translate(player:getGeneral2Name())..":ai_explicit:"..sgs.ai_explicit[player:objectName()])
	end
	if sgs.ai_explicit[player:objectName()] == "unknown" and not player:hasShownOneGeneral() then return true end
	return false
end

sgs.ai_card_intention["general"] = function(to, level)
end

function sgs.updateIntention(from, to, intention, card)
	if not from or not to then Global_room:writeToConsole(debug.traceback()) end
	if not intention or type(intention) ~= "number" then Global_room:writeToConsole(debug.traceback()) end
	if intention > 0 then intention = 10 end
	if intention < 0 then intention = -10 end
	local sendLog, output_to
	if sgs.recorder:evaluateKingdom(from) == "careerist" or sgs.recorder:evaluateKingdom(to, from) == "careerist" then
	elseif from:objectName() == to:objectName() then
	else
		local to_kingdom = sgs.recorder:evaluateKingdom(to, from)
		local kingdoms = sgs.KingdomsTable
		if sgs.isAnjiang(from) and to_kingdom ~= "unknown" then
			to_kingdom = to_kingdom:split("?")
			if intention > 0 then
				sendLog = true
				sgs.outputKingdomValues(from, intention)
				for _, kingdom in ipairs(kingdoms) do
					if table.contains(to_kingdom, kingdom) then
						sgs.ai_loyalty[kingdom][from:objectName()] = sgs.ai_loyalty[kingdom][from:objectName()] - intention
					else
						sgs.ai_loyalty[kingdom][from:objectName()] = sgs.ai_loyalty[kingdom][from:objectName()] + intention
					end
				end
			elseif intention < 0 then
				sendLog = true
				sgs.outputKingdomValues(from, intention)
				local kingdom = to:getKingdom()
				if kingdom == "god" then
					kingdom = "careerist"
				end
				sgs.ai_loyalty[kingdom][from:objectName()] = sgs.ai_loyalty[kingdom][from:objectName()] - intention
			end
		elseif to:getMark(string.format("KnownBoth_%s_%s", from:objectName(), to:objectName())) > 0 and not (sgs.isAnjiang(from) and sgs.isAnjiang(to)) then
			if sgs.isAnjiang(from) then
				if intention > 0 then
					from:setMark("KnownBothEnemy" .. to:objectName(), 1)
					to:setMark("KnownBothEnemy" .. from:objectName(), 1)
				elseif intention < 0 then
					from:setMark("KnownBothFriend" .. to:objectName(), 1)
					to:setMark("KnownBothFriend" .. from:objectName(), 1)
				end
			else
				local from_kingdom = sgs.recorder:evaluateKingdom(from)
				if from_kingdom ~= "god" and from_kingdom ~= "careerist" and from_kingdom ~= "unknown" then
					sendLog = true
					output_to = true
					sgs.outputKingdomValues(to, intention)
					if intention > 0 then
						for _, kingdom in ipairs(kingdoms) do
							if kingdom ~= from_kingdom then
								sgs.ai_loyalty[kingdom][to:objectName()] = sgs.ai_loyalty[kingdom][to:objectName()] + intention
							else
								sgs.ai_loyalty[kingdom][to:objectName()] = sgs.ai_loyalty[kingdom][to:objectName()] - intention
							end
						end
					elseif intention < 0 then--知己知彼后,单方面对暗将示好的行为(比如合纵),只提高是同势力的可能性,不降低是其他势力的可能性
						local kingdom = from:getKingdom()
						sgs.ai_loyalty[kingdom][to:objectName()] = sgs.ai_loyalty[kingdom][to:objectName()] - intention
					end
				end
				--[[
				sendLog = true
				output_to = true
				sgs.outputKingdomValues(to, intention)
				for _, kingdom in ipairs(kingdoms) do
					if kingdom ~= from:getKingdom() then
						sgs.ai_loyalty[kingdom][to:objectName()] = sgs.ai_loyalty[kingdom][to:objectName()] + intention
					else
						sgs.ai_loyalty[kingdom][to:objectName()] = sgs.ai_loyalty[kingdom][to:objectName()] - intention
					end
				end
				--]]
			end
		end
	end

	for _, p in sgs.qlist(Global_room:getAllPlayers()) do
		sgs.ais[p:objectName()]:updatePlayers()
	end

	sgs.outputKingdomValues(output_to and to or from, sendLog and intention or 0, sendLog)
end

function sgs.outputKingdomValues(player, level, sendLog)
	local logType = 1
	local name1 =  player:getGeneralName()
	local name2 = player:getGeneral2Name()
	local name = name1 .. "/" .. name2
	if name == "anjiang/anjiang" then
		--name = "SEAT" .. player:getSeat()
		name = sgs.Sanguosha:translate(string.format("SEAT(%s)",player:getSeat()))
		logType = 2
	else
		name = sgs.Sanguosha:translate(name1).. "/" .. sgs.Sanguosha:translate(name2)
	end
	local msg = name
	if logType == 2 then
		--msg = msg .. " " .. level
		msg = msg .. " " .. level .. " 势力评估:"
		for _, kingdom in ipairs(sgs.KingdomsTable) do
			--msg = msg .. " " .. kingdom .. math.ceil(sgs.ai_loyalty[kingdom][player:objectName()])
			msg = msg .. " " .. sgs.Sanguosha:translate(kingdom) .. math.ceil(sgs.ai_loyalty[kingdom][player:objectName()])
		end
	end
	msg = msg .. " gP: " .. sgs.gameProcess() .. " "
	for _, kingdom in ipairs(sgs.KingdomsTable) do
		--msg = msg .. string.upper(string.sub(kingdom, 1, 1)) .. string.sub(kingdom, 2) .. sgs.current_mode_players[kingdom] .. " "
		msg = msg .. sgs.Sanguosha:translate(kingdom) .. sgs.current_mode_players[kingdom] .. " "
	end
	Global_room:writeToConsole(msg)

	--[[if sendLog then
		local log = sgs.LogMessage()
		log.type = "#AI_evaluateKingdom"
		log.arg = sgs.recorder:evaluateKingdom(player)
		log.from = player
		Global_room:sendLog(log)
	end]]
end

function SmartAI:updatePlayers(update, resetAI)
	if not resetAI and self.player:isDead() then return end
	if update ~= false then update = true end

	self.friends = {}
	self.enemies = {}
	self.friends_noself = {}

	sgs.updateAlivePlayerRoles()
	self.role = self.player:getRole()

	if update then
		sgs.gameProcess(true)
	end

	if sgs.isRoleExpose() then
		self.friends = {}
		self.friends_noself = {}
		local friends = sgs.QList2Table(self.lua_ai:getFriends())
		for i = 1, #friends, 1 do
			if friends[i]:isAlive() and friends[i]:objectName() ~= self.player:objectName() then
				table.insert(self.friends, friends[i])
				table.insert(self.friends_noself, friends[i])
			end
		end
		table.insert(self.friends, self.player)

		local enemies = sgs.QList2Table(self.lua_ai:getEnemies())
		for i = 1, #enemies, 1 do
			if enemies[i]:isDead() or enemies[i]:objectName() == self.player:objectName() then table.remove(enemies, i) end
		end
		self.enemies = enemies

		self.retain = 2
		self.harsh_retain = false
		if #self.enemies == 0 then
			local neutrality = {}
			for _, aplayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self.lua_ai:relationTo(aplayer) == sgs.AI_Neutrality and not aplayer:isDead() then table.insert(neutrality, aplayer) end
			end
			local objective_level = {}
			for _, p in ipairs(neutrality) do
				objective_level[p:objectName()] = self:objectiveLevel(p)
			end
			local function compare_func(a, b)
				return objective_level[a:objectName()] > objective_level[b:objectName()]
			end
			table.sort(neutrality, compare_func)
			table.insert(self.enemies, neutrality[1])
		end
		return
	end

	if not sgs.isAnjiang(self.player) then
		local updateNewKingdom = self.player:getRole() == "careerist" and sgs.ai_explicit[self.player:objectName()] ~= "careerist"
									or self.player:getRole() ~= "careerist" and sgs.ai_explicit[self.player:objectName()] ~= self.player:getKingdom()
		if updateNewKingdom then self:updatePlayerKingdom(self.player) end
	end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local level = self:objectiveLevel(player)
		if level < 0 then
			table.insert(self.friends_noself, player)
			table.insert(self.friends, player)
		elseif level > 0 then
			table.insert(self.enemies, player)
		end
	end
	table.insert(self.friends, self.player)
end

function SmartAI:updatePlayerKingdom(player, data)
	sgs.ai_explicit[player:objectName()] = player:getRole() == "careerist" and "careerist" or player:getKingdom()
	if data then
		local isHead = data:toBool()
		sgs.general_shown[player:objectName()][isHead and "head" or "deputy"] = true
	else
		sgs.general_shown[player:objectName()]["head"] = player:hasShownGeneral1()
		sgs.general_shown[player:objectName()]["deputy"] = player:hasShownGeneral2()
	end

	for _, k in ipairs(sgs.KingdomsTable) do
		if k == sgs.ai_explicit[player:objectName()] then sgs.ai_loyalty[k][player:objectName()] = 99
		else sgs.ai_loyalty[k][player:objectName()] = 0
		end
	end
	local all_shown = true
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if sgs.isAnjiang(p) then all_shown = false break end
	end

	if all_shown then
		sgs.KingdomsTable = {}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			--if p:getRole() == "careerist" then continue end
			local kingdom = p:getKingdom()
			if kingdom == "god" or p:getRole() == "careerist" then
				kingdom = "careerist"
			end
			if not table.contains(sgs.KingdomsTable, kingdom) then
				table.insert(sgs.KingdomsTable, kingdom)
			end
		end
	end

	for k, v in pairs(sgs.shown_kingdom) do
		sgs.shown_kingdom[k] = 0
	end

	for _, p in sgs.qlist(self.room:getPlayers()) do
		if sgs.ai_explicit[p:objectName()] ~= "unknown" then
			sgs.ai_explicit[p:objectName()] = p:getRole() == "careerist" and "careerist" or p:getKingdom()
		end
		if sgs.ai_explicit[p:objectName()] == "careerist" or sgs.ai_explicit[p:objectName()] == "unknown" then continue end
		sgs.shown_kingdom[sgs.ai_explicit[p:objectName()]] = sgs.shown_kingdom[sgs.ai_explicit[p:objectName()]] + 1
	end

	if data then
		for _, p in sgs.qlist(Global_room:getAllPlayers()) do
			sgs.ais[p:objectName()]:updatePlayers()
		end
	end
end

function sgs.getChaofeng(player)--嘲讽值
	if not player then return 0 end
	local hp = player:getHp()
	if player:hasShownSkill("benghuai") and player:getHp() > 4 then hp = 4 end
	--手牌和hp数值上限放开，是否合适？
	local defense = hp * 2 + math.min(player:getHandcardNum(), player:getMaxCards())
	--math.min(hp * 2 + player:getHandcardNum(), hp * 3)
	defense = defense + player:getHandPile():length()

	--装备相关
	local hasEightDiagram = player:hasArmorEffect("EightDiagram")
	--[[
	if player:getArmor() and player:getArmor():isKindOf("EightDiagram") then hasEightDiagram = true end
	local skill = sgs.Sanguosha:ViewHas(player, "EightDiagram", "armor")
	if skill and player:hasShownSkill(skill:objectName()) then hasEightDiagram = true end
	]]
	if player:getArmor() and player:hasArmorEffect(player:getArmor():objectName()) or hasEightDiagram then defense = defense + 2 end
	if hasEightDiagram then
		if player:hasShownSkills("tiandu|hongyan|leiji|zhuwei") then defense = defense + 2 end
	end
	if player:hasArmorEffect("RenwangShield") and player:hasShownSkill("jiang") then defense = defense + 1.5 end
	if player:getDefensiveHorse() then defense = defense + 0.5 end
	if player:hasTreasure("JadeSeal") then defense = defense + 2 end

	--ai-selector基础值
	local name1 =  player:getGeneralName()
	local name2 = player:getGeneral2Name()
	local pair = false
	for pairname, value in pairs(sgs.general_pair_value) do
		if (name1.. "+" .. name2 == pairname or name2 .. "+" .. name1 == pairname)
		and not player:isDuanchang(true) and not player:isDuanchang(false) then
			defense = defense + value*0.5
			pair = true
			break
		end
	end
	if not pair then
		if name1:match("sujiang") or player:isDuanchang(true) then
			defense = defense + 1
		elseif name1 == "anjiang" or not sgs.general_value[name1] then
			defense = defense + 2.5
		elseif sgs.general_value[name1] then
			defense = defense + sgs.general_value[name1]*0.5
		end
		if name2:match("sujiang") or player:isDuanchang(false) then
			defense = defense + 1
		elseif name2 == "anjiang" or not sgs.general_value[name2] then
			defense = defense + 2.5
		elseif sgs.general_value[name2] then
			defense = defense + sgs.general_value[name2]*0.5
		end
	end

	--君主和野心家
	if player:hasLordSkill("shouyue") then
		for _, p in sgs.qlist(Global_room:getAlivePlayers()) do
			if sgs.ai_explicit[p:objectName()] == "shu" then
				if p:hasShownSkill("xuanhuo") then defense = defense + 1.5 end
				if p:hasShownSkill("wusheng") then defense = defense + 1 end
				if p:hasShownSkill("paoxiao") then defense = defense + 1 end
				if p:hasShownSkill("longdan") then defense = defense + 1 end
				if p:hasShownSkill("liegong") then defense = defense + 0.5 end
				if p:hasShownSkill("tieqi") then defense = defense + 1 end
			end
		end
	end
	if player:hasLordSkill("hongfa") then
		local miheng = sgs.findPlayerByShownSkillName("kuangcai")
		local kuangcai_slash = false
		if miheng and sgs.ai_explicit[miheng:objectName()] == "qun" then
			kuangcai_slash = true
		end
		for _, p in sgs.qlist(Global_room:getAlivePlayers()) do
			if sgs.ai_explicit[p:objectName()] == "qun" then
				defense = defense + (kuangcai_slash and 1.8 or 1.2)
			end
		end
	end
	if player:hasLordSkill("jiahe") then
		defense = defense + player:getPile("flame_map"):length()
		for _, p in sgs.qlist(Global_room:getAlivePlayers()) do
			if sgs.ai_explicit[p:objectName()] == "wu" then
				if p:hasShownSkills(sgs.lose_equip_skill) then defense = defense + 1.5 end
				if p:hasShownSkill("diaodu") then defense = defense + 1.5 end
			end
		end
	end
	if player:hasLordSkill("jianan") then
		for _, p in sgs.qlist(Global_room:getAlivePlayers()) do
			if sgs.ai_explicit[p:objectName()] == "wei" then
				defense = defense + 0.5
				if p:hasShownSkills(sgs.masochism_skill) then defense = defense + 1 end
			end
		end
	end
	if player:getActualGeneral1():getKingdom() == "careerist" then--野心家角色调高多少合适？
		defense = defense + 12
	end

	--标记类技能，越多越强
	if player:hasShownSkill("buqu") then defense = defense + math.max(5 - player:getPile("scars"):length(), 0) end
	if player:hasShownSkill("tuntian") then
		defense = defense + player:getPile("field"):length() * (player:inHeadSkills("tuntian") and 1 or 0.5)
	end
	if player:hasShownSkill("qianhuan") then defense = defense + player:getPile("sorcery"):length() * 1.25 end
	if player:hasShownSkill("yigui") then
		local huashens = player:property("Huashens"):toString():split("+")
		defense = defense + #huashens
		--对于每个魂,出牌前嘲讽应该提高,出牌后嘲讽应该降低
	end
	if player:hasShownSkill("paiyi") then defense = defense + player:getPile("power_pile"):length() end
	if player:hasShownSkill("zisui") then defense = defense + player:getPile("&disloyalty"):length() end
	if player:hasShownSkill("xiongnve") then defense = defense + player:getMark("#massacre") end
	if player:hasShownSkill("sidi") then defense = defense + player:getPile("drive"):length() end

--[[原技能选择直接用ai-selector的值替代
	local m = sgs.masochism_skill:split("|")
	for _, masochism in ipairs(m) do
		if player:hasShownSkill(masochism) then
			local goodHp = player:getHp() > 1 or getCardsNum("Peach", player) >= 1 or getCardsNum("Analeptic", player) >= 1
							or HasBuquEffect(player) or HasNiepanEffect(player)
			if goodHp then defense = defense + 1 end
		end
	end

	if player:hasShownSkill("jieming") then defense = defense + 3 end
	if player:hasShownSkill("yiji") then defense = defense + 2 end
	if player:hasShownSkill("tuxi") then defense = defense + 0.5 end
	if player:hasShownSkill("luoshen") then defense = defense + 1 end
	if player:hasShownSkill("rende") and player:getHp() > 2 then defense = defense + 1 end
	if player:hasShownSkill("zaiqi") and player:getHp() > 1 then defense = defense + player:getLostHp() * 0.5 end
	if player:hasShownSkills("tieqi|liegong|kuanggu") then defense = defense + 0.5 end
	if player:hasShownSkill("xiangle") then defense = defense + 1 end
	if player:hasShownSkill("shushen") then defense = defense + 1 end
	if player:hasShownSkill("kongcheng") and player:isKongcheng() then defense = defense + 2 end
	if player:hasShownSkills("yinghun_sunjian|yinghun_sunce") and player:getLostHp() > 0 then defense = defense + player:getLostHp() - 0.5 end
	if player:hasShownSkill("tianxiang") then defense = defense + player:getHandcardNum() * 0.5 end
	if player:hasShownSkill("guzheng") then defense = defense + 1 end
	if player:hasShownSkill("dimeng") then defense = defense + 2 end
	if player:hasShownSkill("keji") then defense = defense + player:getHandcardNum() * 0.5 end
	if player:hasShownSkill("jieyin") and player:getHandcardNum() > 1 then defense = defense + 2 end
	if player:hasShownSkill("jijiu") then defense = defense + 2 end
	if player:hasShownSkill("lijian") then defense = defense + 0.5 end

	if player:hasShownSkills("qingguo+yiji|duoshi+xiaoji|jijiu+qianhuan|yiji+ganglie") then defense = defense + 2 end
	if player:hasShownSkills("yiji+qiaobian|xiaoji+zhiheng|buqu+yinghun_sunjian|luoshen+guicai") then defense = defense + 1.5 end
]]

	if not player:faceUp() then defense = defense - 3 end
	if player:containsTrick("indulgence") then defense = defense - 2 end
	if player:containsTrick("supply_shortage") then defense = defense - 1 end

	if Global_room:getCurrent() then
		defense = defense + (player:aliveCount() - (player:getSeat() - Global_room:getCurrent():getSeat()) % player:aliveCount()) / 4
	end

	return defense
end

function sgs.getValue(player)
	if not player then Global_room:writeToConsole(debug.traceback()) end
	return player:getHp() * 2 + player:getHandcardNum()
end

function SmartAI:assignKeep(start)
	self.keepValue = {}
	self.kept = {}

	if start then
		--[[
			通常的保留顺序
			peach-1 = 7
			peach-2 = 5.8 jink-1 = 5.2
			peach-3 = 4.5 AllianceFeast = 4.4 ConsolidateCountry = 4.3 JadeSeal = 4.2 LuminousPearl = 4.2
			analeptic-1 = 4.1 jink-2 = 4.0 BefriendAttacking-1 = 3.9 ExNihilo-1= 3.88 Conquering = 3.88
			HegNullification 3.82 nullification-1 = 3.8 thunderslash-1 = 3.66 fireslash-1 = 3.63
			slash-1 = 3.6 indulgence-1 = 3.5 RuleTheWorld = 3.5 SupplyShortage-1 = 3.48 Chaos = 3.47 snatch-1 = 3.46 Dismantlement-1 = 3.44 Duel-1 = 3.42 Drownning -3.40
				BurningCamps = 3.38 Collateral-1 = 3.36 ArcheryAttack-1 = 3.35 SavageAssault-1 = 3.34 FightTogether = 3.33 IronChain = 3.32 GodSalvation-1 = 3.30
				Fireattack-1 = 3.28  KnownBoth = 3.24 AwaitExhausted = 3.22 ThreatenEmperor = 3.2 peach-4 = 3.1
			analeptic-2 = 2.9 jink-3 = 2.7 ExNihilo-2 = 2.7 nullification-2 = 2.6 LureTiger = 2.5 thunderslash-2 = 2.46 fireslash-2 = 2.43 slash-2 = 2.4
			...
			Weapon-1 = 2.08 Armor-1 = 2.06 Treasure = 2.05 DefensiveHorse-1 = 2.04 OffensiveHorse-1 = 2
			...
			imperial_order = 0
			AmazingGrace-1 = -1 Lightning-1 = -2
		]]

		self.keepdata = {}
		for k, v in pairs(sgs.ai_keep_value) do
			self.keepdata[k] = v
		end

		for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			local skilltable = sgs[askill:objectName() .. "_keep_value"]
			if skilltable then
				for k, v in pairs(skilltable) do
					self.keepdata[k] = v
				end
			end
		end
	end

	if sgs.turncount <= 1 and #self.enemies == 0 then
		self.keepdata.Jink = 4.2
	end

	if not self:isWeak() or self.player:getHandcardNum() >= 4 then
		for _, friend in ipairs(self.friends_noself) do
			if self:willSkipDrawPhase(friend) or self:willSkipPlayPhase(friend) then
				self.keepdata.Nullification = 5.5
				break
			end
		end
	end

	if self:getOverflow(self.player, true) == 1 then
		self.keepdata.Analeptic = (self.keepdata.Jink or 5.2) + 0.1
		-- 特殊情况下还是要留闪，待补充...
	end

	if self.player:getMark("GlobalBattleRoyalMode") > 0 and self.player:getHp() == 1 then
		self.keepdata.Analeptic = (self.keepdata.Peach or 7) + 0.1--鏖战一血酒保留值设置最高
	end

	if not self:isWeak() then
		local needDamaged = false
		if not needDamaged and not sgs.isGoodTarget(self.player, self.friends, self) then needDamaged = true end
		if not needDamaged then
			for _, skill in sgs.qlist(self.player:getVisibleSkillList(true)) do
				local callback = sgs.ai_need_damaged[skill:objectName()]
				if type(callback) == "function" and callback(self, nil, self.player) then
					needDamaged = true
					break
				end
			end
		end
		if needDamaged then
			self.keepdata.ThunderSlash = 5.2
			self.keepdata.FireSlash = 5.1
			self.keepdata.Slash = 5
			self.keepdata.Jink = 4.5
		end
	end

	for _, card in sgs.qlist(self.player:getCards("he")) do
		self.keepValue[card:getEffectiveId()] = self:writeKeepValue(card)
	end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards, true)

	local resetCards = function(allcards)
		local result = {}
		for _, a in ipairs(allcards) do
			local found
			for _, b in ipairs(self.kept) do
				if a:getEffectiveId() == b:getEffectiveId() then
					found = true
					break
				end
			end
			if not found then table.insert(result, a) end
		end
		return result
	end

	for i = 1, self.player:getHandcardNum() do
		for _, card in ipairs(cards) do
			local v = self:getKeepValue(card, self.kept)
			self.keepValue[card:getEffectiveId()] = v
			self.keepdata[card:getClassName()] = v
			table.insert(self.kept, card)
			break
		end
		cards = resetCards(cards)
	end

end

function SmartAI:writeKeepValue(card)
	local maxvalue = self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	local mostvaluable_class = card:getClassName()
	for k, v in pairs(self.keepdata) do
		if isCard(k, card, self.player) and v > maxvalue then
			maxvalue = v
			mostvaluable_class = k
		end
	end
	local cardPlace = self.room:getCardPlace(card:getEffectiveId())
	if cardPlace == sgs.Player_PlaceEquip then
		if card:isKindOf("Armor") and self:needToThrowArmor() then return -10
		elseif self.player:hasSkills(sgs.lose_equip_skill) then
			if card:isKindOf("Crossbow") then
			elseif card:isKindOf("OffensiveHorse") then return -10
			elseif card:isKindOf("Weapon") then return -9.9
			elseif card:isKindOf("WoodenOx") then
				if self.player:getPile("wooden_ox"):isEmpty() then
					return -9.8
				end
			elseif card:isKindOf("DefensiveHorse") then return -9.7
			elseif (card:isKindOf("LuminousPearl") or card:isKindOf("JadeSeal") or card:isKindOf("Crossbow")) and self:isWeak() then return -9.6
			elseif self.player:getPhase() <= sgs.Player_Play then return -9.5--回合外别丢防具、玉玺、夜明珠
			end
		elseif self.player:hasSkills("bazhen|jgyizhong") and card:isKindOf("Armor") then return -8
		elseif self:needKongcheng() then return 5.0
		end
		local value = 0
		if card:isKindOf("Armor") then value = self:isWeak() and 5.2 or 3.2
		elseif card:isKindOf("DefensiveHorse") then value = self:isWeak() and 4.3 or 3.19
		elseif card:isKindOf("Weapon") then value = self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable() and 3.39 or 3.2
		elseif card:isKindOf("JadeSeal") and not self.player:hasSkill("yongsi") then value = 5
		elseif card:isKindOf("LuminousPearl") then value = (self.player:getPhase() == sgs.Player_Play and not self.player:hasUsed("ZhihengCard")) and 3.39 or 3.2
		elseif card:isKindOf("WoodenOx") then
			value = 3.19
			for _, id in sgs.qlist(self.player:getHandPile()) do
				local c = sgs.Sanguosha:getCard(id)
				value = value + (sgs.ai_keep_value[c:getClassName()] or 0)
			end
		else value = 3.19
		end
		if not card:isKindOf(mostvaluable_class) then
			value = value + maxvalue
		end
		return value
	elseif cardPlace == sgs.Player_PlaceHand then
		local value_suit, value_number, newvalue = 0, 0, 0
		local suit_string = card:getSuitString()
		local number = card:getNumber()
		local i = 0

		for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			if sgs[askill:objectName() .. "_suit_value"] then
				local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
				if v then
					i = i + 1
					value_suit = value_suit + v
				end
			end
		end
		if i > 0 then value_suit = value_suit / i end

		i = 0
		for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			if sgs[askill:objectName() .. "_number_value"] then
				local v = sgs[askill:objectName() .. "_number_value"][tostring(number)]
				if v then
					i = i + 1
					value_number = value_number + v
				end
			end
		end

		if i > 0 then value_number = value_number / i end
		newvalue = maxvalue + value_suit + value_number
		if not card:isKindOf(mostvaluable_class) then   newvalue = newvalue + 0.1 end
		newvalue = self:adjustKeepValue(card, newvalue)
		return newvalue
	else
		return self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	end
end

function SmartAI:getKeepValue(card, kept)
	local cardPlace = self.room:getCardPlace(card:getEffectiveId())
	local v = self.keepValue[card:getEffectiveId()] or self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	if not kept then
		if cardPlace ~= sgs.Player_PlaceHand and cardPlace ~= sgs.Player_PlaceEquip then
			v = self:adjustKeepValue(card, v)
		end
		return v
	end

	local maxvalue = self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	local mostvaluable_class = card:getClassName()
	for k, vk in pairs(self.keepdata) do
		if isCard(k, card, self.player) and vk > maxvalue then
			maxvalue = vk
			mostvaluable_class = k
		end
	end

	if cardPlace == sgs.Player_PlaceHand then
		local dec = 0
		for _, acard in ipairs(kept) do
			if isCard(mostvaluable_class, acard, self.player) then
				v = v - 1.2 - dec
				dec = dec + 0.1
			elseif acard:isKindOf("Slash") and card:isKindOf("Slash") then
				v = v - 1.2 - dec
				dec = dec + 0.1
			end
		end
	end
	return v
end

function SmartAI:adjustKeepValue(card, v)
	local suits = {"club", "spade", "diamond", "heart"}
	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		local callback = sgs.ai_suit_priority[askill:objectName()]
		if type(callback) == "function" then
			suits = callback(self, card):split("|")
			break
		elseif type(callback) == "string" then
			suits = callback:split("|")
			break
		end
	end
	table.insert(suits, "no_suit")

	if card:isKindOf("Slash") then
		if card:isRed() then v = v + 0.02 end
		if card:isKindOf("NatureSlash") then v = v + 0.03 end
		if self.player:hasSkill("jiang") and card:isRed() then v = v + 0.04 end
	end
	if card:isKindOf("HegNullification") then v = v + 0.02 end
	if card:isKindOf("ThreatenEmperor") then v = v + (self.player:isBigKingdomPlayer() and 3 or -3) end
	if self.player:getHandPile():contains(card:getEffectiveId()) then
		v = v - 0.1
	end

	local suits_value = {}
	for index,suit in ipairs(suits) do
		suits_value[suit] = index * 2
	end
	v = v + (suits_value[card:getSuitString()] or 0) / 100
	v = v + card:getNumber() / 500
	return v
end

function SmartAI:getUseValue(card)
	if not card then Global_room:writeToConsole(debug.traceback()) end
	local class_name = card:isKindOf("LuaSkillCard") and card:objectName() or card:getClassName()
	local v = sgs.ai_use_value[class_name] or 0

	if card:getTypeId() == sgs.Card_TypeSkill then
		return v
	elseif card:getTypeId() == sgs.Card_TypeEquip then
		if self.player:hasEquip(card) then
			if self.player:hasSkills(sgs.lose_equip_skill) then--使用保留值是否合适？
				if card:isKindOf("Crossbow") then
				elseif card:isKindOf("OffensiveHorse") then return -10
				elseif card:isKindOf("Weapon") then return -9.9
				elseif card:isKindOf("WoodenOx") then
					if self.player:getPile("wooden_ox"):isEmpty() then
						return -9.8
					end
				elseif card:isKindOf("DefensiveHorse") then return -9.7
				elseif card:isKindOf("LuminousPearl") or card:isKindOf("JadeSeal") then
					if self:isWeak() then
						return -9.6
					end
				elseif self.player:getPhase() <= sgs.Player_Play then return -9.5--回合外别丢防具、玉玺、夜明珠
				end
			end
			if card:isKindOf("Weapon") then
				for _, c in sgs.qlist(self.player:getHandcards()) do
					if c:isKindOf("Weapon") and self:evaluateWeapon(c) > self:evaluateWeapon(card) then
						return -10
					end
				end
				for _, id in sgs.qlist(self.player:getHandPile()) do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("Weapon") and self:evaluateWeapon(c) > self:evaluateWeapon(card) then
						return -10
					end
				end
			end
			if card:isKindOf("Armor") then
				if self:needToThrowArmor() then
					return -10
				end
				for _, c in sgs.qlist(self.player:getHandcards()) do
					if c:isKindOf("Armor") and self:evaluateArmor(c) > self:evaluateArmor(card) then
						return -10
					end
				end
				for _, id in sgs.qlist(self.player:getHandPile()) do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("Armor") and self:evaluateArmor(c) > self:evaluateArmor(card) then
						return -10
					end
				end
			end
			if card:isKindOf("OffensiveHorse") and self.player:getAttackRange() > 2 then return 5.5 end
			if card:isKindOf("DefensiveHorse") and self:hasEightDiagramEffect() then return 5.5 end
			if card:isKindOf("WoodenOx") then
				local value = 4
				for _, id in sgs.qlist(self.player:getHandPile()) do
					local c = sgs.Sanguosha:getCard(id)
					value = value + (self:getUseValue(c) or 0)--可否递归？
				end
				return value
			end
			return 9
		end
		if not self:getSameEquip(card) then v = 6.7 end
		if self.weaponUsed and card:isKindOf("Weapon") then v = 2 end
		if self.player:hasSkills("qiangxi") and card:isKindOf("Weapon") then v = 2 end
		if card:isKindOf("Crossbow") then v = v + self:getCardsNum("Slash") * 2 end
		if self.player:hasSkills("kurou|wusheng|kuanggu|luoshen|wangxi|quanji") and card:isKindOf("Crossbow") then return 9 end
		if self.player:hasSkills("bazhen|jgyizhong") and card:isKindOf("Armor") then v = 2 end

		local lvfan = sgs.findPlayerByShownSkillName("diaodu")
		if lvfan and self.player:isFriendWith(lvfan) then v = 6.7 end
		if self.player:hasSkills(sgs.lose_equip_skill) then return 10 end

	elseif card:getTypeId() == sgs.Card_TypeBasic then
		if card:isKindOf("Slash") then
			if self.player:hasFlag("TianyiSuccess") or self:hasHeavySlashDamage(self.player, card) then v = 8.7 end
			if self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable() and #self.enemies > 0 and self:getCardsNum("Slash") == 1 then
				v = v + 5
				if self.player:getMark("##luoyi") > 0 then v = v + 5 end
			end
			if self:hasCrossbowEffect() then v = v + 5 end-- +4 改为 +5
			if card:getSkillName() == "Spear" then v = v - 1 end
			if card:getSkillName() == "hongfa" then v = v + 2 end
		elseif card:isKindOf("Jink") then
			if self:getCardsNum("Jink") > 1 then v = v - 6 end
		elseif card:isKindOf("Peach") then
			if self.player:isWounded() then v = v + 6 end
		end
	elseif card:getTypeId() == sgs.Card_TypeTrick then
		if self.player:getPhase() <= sgs.Player_Play and not card:isKindOf("Nullification") and not card:isAvailable(self.player) then v = 0 end
		if self.player:getWeapon() and not self.player:hasSkills(sgs.lose_equip_skill) and card:isKindOf("Collateral") then v = 2 end
		if card:getSkillName() == "shuangxiong" then v = 6 end
		if card:isKindOf("Duel") then
			v = v + self:getCardsNum("Slash") * 2
			if self.player:getMark("##luoyi") > 0 then v = v + 5 end
		end
		if self.player:hasSkill("jizhi") then v = v + 4 end
		if card:isKindOf("HegNullification") then v = v + 2 end
		if card:isKindOf("AllianceFeast") and self.player:getLostHp() > 1 then v = v + 5 end
		if card:isKindOf("ThreatenEmperor") then v = v + (self.player:isBigKingdomPlayer() and 4 or -4) end
	end

	if self.player:hasSkills(sgs.need_kongcheng) then
		if self.player:getHandcardNum() == 1 and self.player:isLastHandCard(card) then v = 10 end--仅手牌，木牛的牌不算
	end

	if self.player:getHandPile():contains(card:getEffectiveId()) then
		v = v + 1
	end

	if card:getSkillName() == "tiandian" then v = v + 6 end
	if self.player:getPhase() == sgs.Player_Play then v = self:adjustUsePriority(card, v) end
	return v
end

function SmartAI:getUsePriority(card)
	local class_name = card:getClassName()
	local v = 0
	if card:isKindOf("EquipCard") then
		if self.player:hasSkills("kuanggu|kuanggu_xh") and (card:isKindOf("OffensiveHorse") or card:isKindOf("SixDragons"))
		and not self.player:getOffensiveHorse() then return 10 end--狂骨-1马
		if card:isKindOf("Armor") and not self.player:getArmor() then v = (sgs.ai_use_priority[class_name] or 0) + 5.2
		elseif card:isKindOf("Weapon") and not self.player:getWeapon() then v = (sgs.ai_use_priority[class_name] or 0) + 3
		elseif card:isKindOf("DefensiveHorse") and not self.player:getDefensiveHorse() then v = 5.8
		elseif card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then v = 5.5
		elseif card:isKindOf("SixDragons") and not (self.player:getDefensiveHorse() and self.player:getOffensiveHorse()) then v = 5.9
		elseif card:isKindOf("Treasure") and not self.player:getTreasure() then
			v = (sgs.ai_use_priority[class_name] or 6)
		end
		return v
	end

	v = sgs.ai_use_priority[class_name] or 0
	if class_name == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
		v = sgs.ai_use_priority[card:objectName()] or 0
	end
	return self:adjustUsePriority(card, v)
end

function SmartAI:adjustUsePriority(card, v)
	local suits = {"club", "spade", "diamond", "heart"}

	if card:getTypeId() == sgs.Card_TypeSkill then return v end
	if card:getTypeId() == sgs.Card_TypeEquip then return v end

	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		local callback = sgs.ai_suit_priority[askill:objectName()]
		if type(callback) == "function" then
			suits = callback(self, card):split("|")
			break
		elseif type(callback) == "string" then
			suits = callback:split("|")
			break
		end
	end

	table.insert(suits, "no_suit")
	if card:isKindOf("Slash") then
		if card:getSkillName() == "Spear" then v = v - 0.2 end
		if card:getSkillName() == "aozhan" then v = v - 0.1 end--鏖战，比丈八先
		if card:getSkillName() == "longdan" then v = v + 0.1 end--龙胆
		if card:getSkillName() == "hongfa" then v = v + 0.1 end
		if card:isRed() then
			v = v - 0.05
		end
		if card:isKindOf("NatureSlash") then
			if self.slashAvail == 1 then
				v = v + 0.05
				if card:isKindOf("FireSlash") then
					for _, enemy in ipairs(self.enemies) do
						if enemy:hasArmorEffect("Vine") or enemy:getMark("@gale") > 0 then v = v + 0.07 break end
					end
					if self.player:hasSkill("xinghuo") then
						v = v + 0.08
					end
				elseif card:isKindOf("ThunderSlash") then
					for _, enemy in ipairs(self.enemies) do
						if enemy:getMark("@fog") > 0 then v = v + 0.06 break end
					end
				end
			else v = v - 0.05
			end
		end
		if self.player:hasSkill("jiang") and card:isRed() then v = v + 0.21 end
		if self.slashAvail == 1 then
			v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card) * 0.1, 0.5)
			v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) * 0.05, 0.5)
		end
	end
	if card:isKindOf("Jink") then
		if card:getSkillName() == "aozhan" then v = v - 0.1 end--鏖战
		if card:getSkillName() == "longdan" then v = v + 0.1 end--龙胆，打出闪和万箭没办法分开
	end
	if card:isKindOf("HegNullification") then v = v - 0.1 end

	local noresponselist = card:getTag("NoResponse"):toStringList()--新增卡牌无法响应
	if noresponselist and #noresponselist > 0 then
		v = v + 0.25
	end
	if self:hasWenjiBuff(card) then--类似的求安卡？
		v = v - 0.4
	end

	if self.player:getHandPile():contains(card:getEffectiveId()) then
		v = v + 0.1
	end

	local suits_value = {}
	for index, suit in ipairs(suits) do
		suits_value[suit] = -index
	end
	v = v + (suits_value[card:getSuitString()] or 0) / 1000
	v = v + (13 - card:getNumber()) / 10000
	return v
end

function SmartAI:getDynamicUsePriority(card)
	if not card then return 0 end
	if card:hasFlag("AIGlobal_KillOff") then return 15 end

	if self.player:hasSkill("jili") and card:isKindOf("Weapon") then return self:shamokeUseWeaponPriority(card) end

	if card:isKindOf("Slash") then
		if self.player:getMark("GlobalPlayCardUsedTimes") == 0 then
			for _, p in ipairs(self.friends) do
				if p:hasShownSkill("yongjue") and self.player:isFriendWith(p) then return 9.5 end
			end
		end
	elseif card:isKindOf("AmazingGrace") then
		local zhugeliang = sgs.findPlayerByShownSkillName("kongcheng")
		if zhugeliang and self:isEnemy(zhugeliang) and zhugeliang:isKongcheng() then
			return math.max(sgs.ai_use_priority.Slash, sgs.ai_use_priority.Duel) + 0.1
		end
	elseif card:isKindOf("Peach") and self.player:hasSkill("kuanggu") then return 1.01
	elseif card:isKindOf("DelayedTrick") and #card:getSkillName() > 0 then
		return (sgs.ai_use_priority[card:getClassName()] or 0.01) - 0.01
	elseif card:isKindOf("Duel") then
		if self:hasCrossbowEffect()
			or self.player:canSlashWithoutCrossbow()
			or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.cloneCard("slash")) > 0
			or self.player:hasUsed("FenxunCard") then
			return sgs.ai_use_priority.Slash - 0.1
		end
	elseif card:isKindOf("AwaitExhausted") and self.player:hasSkills("zhiheng|guose|dimeng") then
		return 0
	end

	local value = self:getUsePriority(card) or 0
	if card:getTypeId() == sgs.Card_TypeEquip then
		if (self.player:hasSkills("xiaoji+qixi") or self.player:hasSkills("xuanlue+qixi"))
			and self:getSameEquip(card) and self:getSameEquip(card):isBlack() then
				return 3.3
		end
		if (self.player:hasSkills("xiaoji+guose") or self.player:hasSkills("xuanlue+guose"))
			and self:getSameEquip(card) and self:getSameEquip(card):getSuit() == sgs.Card_Diamond then
				return 0.4
		end
		local lvfan = sgs.findPlayerByShownSkillName("diaodu")--重复装备时应比烽火优先度20低
		if (lvfan and self.player:isFriendWith(lvfan)) or self.player:hasSkills(sgs.lose_equip_skill) then value = value + 6 end

		if card:isKindOf("Weapon") and self.player:getPhase() == sgs.Player_Play and #self.enemies > 0 then
			self:sort(self.enemies)
			local enemy = self.enemies[1]
			local v, inAttackRange = self:evaluateWeapon(card, self.player, enemy)
			v = v / 20
			value = value + string.format("%3.2f", v)
			if inAttackRange then value = value + 0.5 end
		end

		if card:isKindOf("JadeSeal") and self:getCard("FightTogether") then return 10 end
	end

	if card:isKindOf("AmazingGrace") then
		local dynamic_value = 10
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			dynamic_value = dynamic_value - 1
			if self:isEnemy(player) then dynamic_value = dynamic_value - ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
			else dynamic_value = dynamic_value + ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
			end
		end
		value = value + dynamic_value
	end
	if (card:isKindOf("ArcheryAttack") or card:isKindOf("LureTiger")) and self.player:hasSkill("luanji") then
		value = value + 5.5
	end
	if card:isKindOf("Duel") and self.player:hasSkill("shuangxiong") then
		value = value + 6.3
	end
	if card:isKindOf("WendaoCard") and self.player:hasShownSkills("wendao+hongfa") and not self.player:getPile("heavenly_army"):isEmpty()
		and self.player:getArmor() and self.player:getArmor():objectName() == "PeaceSpell" then
		value = value + 8
	end
	if self.player:hasShownSkill("suzhi") and self.player:getPhase() == sgs.Player_Play then
		local marks =  self.player:getMark("#suzhi")
		if marks < 3 and card:isKindOf("Slash") then
			value = value + math.exp(marks)
		end
		if card:isKindOf("Duel") and marks < 2 then
			value = value + math.exp(marks + 1)
		end
	end

	if self.player:hasSkill("jingce") and self.player:getPhase() == sgs.Player_Play
	and card:isKindOf("Peach") and self.player:getMark("jingce_record") == self.player:getHp() then
		return 10
	end
	if self.player:hasSkill("wanglie") then
		if self.player:getMark("GlobalPlayCardUsedTimes") == 0 and (card:isKindOf("Snatch") or card:isKindOf("SupplyShortage")) then
			return 10
		elseif card:isKindOf("Peach") then
			return 4
		elseif card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") or card:isKindOf("Duel") then
			return 1.5
		elseif card:isKindOf("Slash") then
			return 1
		elseif value < 8 and value > 0 then--其他的优先
			value = value + 2
		end
	end

	return value
end

function SmartAI:cardNeed(card)
	if not self.friends then self.room:writeToConsole(debug.traceback()) self.room:writeToConsole(sgs.turncount) return end
	local class_name = card:getClassName()
	local suit_string = card:getSuitString()
	local value
	if card:isKindOf("Peach") then
		self:sort(self.friends,"hp")
		if self.friends[1]:getHp() < 2 then return 10 end
		if (self.player:getHp() < 3 or self.player:getLostHp() > 1 and not self.player:hasSkill("buqu")) or self.player:hasSkills("kurou|benghuai") then return 14 end
		return self:getUseValue(card)
	end
	if self:isWeak() and card:isKindOf("Jink") and self:getCardsNum("Jink") < 1 then return 12 end

	local i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		if sgs[askill:objectName() .. "_keep_value"] then
			local v = sgs[askill:objectName() .. "_keep_value"][class_name]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end
	i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		if sgs[askill:objectName() .. "_suit_value"] then
			local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end

	if card:isKindOf("Slash") then
		if self:getCardsNum("Slash") == 0 then return 5.9
		else return 4 end
	end
	if card:isKindOf("Analeptic") then
		if self.player:getHp() < 2 then return 10 end
	end
	if card:isKindOf("Crossbow") and self.player:hasSkills("luoshen|kurou|wusheng|kuanggu|wangxi|quanji") then return 20 end
	if card:isKindOf("Axe") and self.player:hasSkill("luoyi") then return 15 end
	if card:isKindOf("Weapon") and (not self.player:getWeapon()) and (self:getCardsNum("Slash") > 1) then return 6 end
	if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
		if self:willSkipPlayPhase() or self:willSkipDrawPhase() then return 10 end
		for _, friend in ipairs(self.friends) do
			if self:willSkipPlayPhase(friend) or self:willSkipDrawPhase(friend) then return 9 end
		end
		return 6
	end
	if card:getTypeId() == sgs.Card_TypeTrick then
		return card:isAvailable(self.player) and self:getUseValue(card) or 0
	end
	return self:getUseValue(card)
end

function SmartAI:sortByKeepValue(cards, inverse, kept)
	local values = {}
	for _, card in ipairs(cards) do
		values[card:getId()] = self:getKeepValue(card)
	end

	local compare_func = function(a, b)
		local v1 = values[a:getId()]
		local v2 = values[b:getId()]

		if v1 ~= v2 then
			if inverse then return v1 > v2 end
			return v1 < v2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUseValue(cards, inverse)
	local values = {}
	for _, card in ipairs(cards) do
		values[card:getId()] = self:getUseValue(card)
	end

	local compare_func = function(a, b)
		local value1 = values[a:getId()]
		local value2 = values[b:getId()]

		if value1 ~= value2 then
			if not inverse then return value1 > value2 end
			return value1 < value2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUsePriority(cards)
	local values = {}
	for _, card in ipairs(cards) do
		values[card:getId()] = self:getUsePriority(card)
	end

	local compare_func = function(a, b)
		local value1 = values[a:getId()]
		local value2 = values[b:getId()]

		if value1 ~= value2 then
			return value1 > value2
		else
			return a:getNumber() > b:getNumber()
		end
	end
	table.sort(cards, compare_func)
end

function SmartAI:sortByDynamicUsePriority(cards)
	local values = {}
	for _, card in ipairs(cards) do
		values[card:getId()] = self:getDynamicUsePriority(card)
	end

	local compare_func = function(a,b)
		local value1 = values[a:getId()]
		local value2 = values[b:getId()]

		if value1 ~= value2 then
			return value1 > value2
		else
			return a and a:getTypeId() ~= sgs.Card_TypeSkill and not (b and b:getTypeId() ~= sgs.Card_TypeSkill)
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByCardNeed(cards, inverse)
	local values = {}
	for _, card in ipairs(cards) do
		values[card:getId()] = self:cardNeed(card)
	end

	local compare_func = function(a,b)
		local value1 = values[a:getId()]
		local value2 = values[b:getId()]

		if value1 ~= value2 then
			if inverse then return value1 > value2 end
			return value1 < value2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function sgs.findIntersectionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end

	local findings = {}
	for _, skill in ipairs(first) do
		for _, compare_skill in ipairs(second) do
			if skill == compare_skill and not table.contains(findings, skill) then table.insert(findings, skill) end
		end
	end
	return findings
end

function sgs.findUnionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end

	local findings = table.copyFrom(first)
	for _, skill in ipairs(second) do
		if not table.contains(findings, skill) then table.insert(findings, skill) end
	end

	return findings
end


function sgs.updateIntentions(from, tos, intention, card)
	for _, to in ipairs(tos) do
		sgs.updateIntention(from, to, intention, card)
	end
end

function SmartAI:isFriend(other, another)
	if not other then self.room:writeToConsole(debug.traceback()) return end
	if another then
		if other:isFriendWith(another) then return true end
		if sgs.ais[other:objectName()] then
			for _, p in ipairs(sgs.ais[other:objectName()].friends) do
				if p:objectName() == another:objectName() then return true end
			end
		end
		return false
	end
	if sgs.isRoleExpose() and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isFriend(other) end
	if self.player:objectName() == other:objectName() then return true end--'objectName' (a nil value)??
	--if self.player:isFriendWith(other) then return true end
	if self.player:willBeFriendWith(other) then return true end--未明置的队友双方
	local level = self:objectiveLevel(other)
	if level < 0 then return true
	elseif level == 0 then return nil end
	return false
end

function SmartAI:isEnemy(other, another)
	if not other then self.room:writeToConsole(debug.traceback()) return end
	if another then
		if sgs.ais[other:objectName()] then
			for _, p in ipairs(sgs.ais[other:objectName()].enemies) do
				if p:objectName() == another:objectName() then return true end
			end
		end
		return false
	end
	if sgs.isRoleExpose() and self.lua_ai:relationTo(other) ~= sgs.AI_Neutrality then return self.lua_ai:isEnemy(other) end
	if self.player:objectName() == other:objectName() then return false end
	local level = self:objectiveLevel(other)
	if level > 0 then return true
	elseif level == 0 then return nil end
	return false
end


function SmartAI:getFriendsNoself(player)
	player = player or self.player
	local friends_noself = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p, player) and p:objectName() ~= player:objectName() then table.insert(friends_noself, p) end
	end
	return friends_noself
end

function SmartAI:getFriends(player)
	player = player or self.player
	local friends = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p, player) then table.insert(friends, p) end
	end
	return friends
end

function SmartAI:getEnemies(player)
	local enemies = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(p, player) then table.insert(enemies, p) end
	end
	return enemies
end

-- compare functions
sgs.ai_compare_funcs = {
	value = function(a, b)
		return sgs.getValue(a) < sgs.getValue(b)
	end,

}

function SmartAI:sort(players, key, inverse)
	if type(players) ~= "table" then self.room:writeToConsole(debug.traceback()) end
	if #players == 0 then return end
	local func
	if not key or key == "defense" or key == "defenseSlash" then
		func = function(a, b)
			local c1 = sgs.getDefenseSlash(a, self)
			local c2 = sgs.getDefenseSlash(b, self)
			if c1 == c2 then
				if inverse then return sgs.getChaofeng(a) > sgs.getChaofeng(b) end
				return sgs.getChaofeng(a) < sgs.getChaofeng(b)
			else
				if inverse then return c1 > c2 end
				return c1 < c2
			end
		end
	elseif key == "hp" then
		func = function(a, b)
			local c1 = a:getHp()
			local c2 = b:getHp()
			if c1 == c2 then
				if inverse then return sgs.getDefenseSlash(a, self) > sgs.getDefenseSlash(b, self) end
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				if inverse then return c1 > c2 end
				return c1 < c2
			end
		end
	elseif key == "handcard" or key == "handcard_defense" then
		func = function(a, b)
			local c1 = a:getHandcardNum()
			local c2 = b:getHandcardNum()
			if c1 == c2 then
				if inverse then return sgs.getDefenseSlash(a, self) > sgs.getDefenseSlash(b, self) end
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				if inverse then return c1 > c2 end
				return c1 < c2
			end
		end
	elseif key == "equip_defense" then
		func = function(a, b)
			local c1 = a:getCards("e"):length()
			local c2 = b:getCards("e"):length()
			if c1 == c2 then
				if inverse then return sgs.getDefenseSlash(a, self) > sgs.getDefenseSlash(b, self) end
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				if inverse then return c1 > c2 end
				return c1 < c2
			end
		end
	elseif key == "chaofeng" then
		func = function(a, b)
			local c1 = sgs.getChaofeng(a)
			local c2 = sgs.getChaofeng(b)
			if c1 == c2 then
				if inverse then return sgs.getDefenseSlash(a, self) > sgs.getDefenseSlash(b, self) end
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				if inverse then return c1 > c2 end
				return c1 < c2
			end
		end
	elseif key == "round" then
		func = function(a, b)
			local c1 = self:playerGetRound(a)
			local c2 = self:playerGetRound(b)
			if c1 == c2 then
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				return c1 < c2
			end
		end
	else
		func = sgs.ai_compare_funcs[key]
		if inverse then
			self.room:writeToConsole("没有inverse参数")
			self.room:writeToConsole(debug.traceback())
		end
	end

	if not func then self.room:writeToConsole(debug.traceback()) return end

	local function _sort()
		table.sort(players, func)
	end

	if not pcall(_sort) then self.room:writeToConsole(debug.traceback()) end
end

function sgs.updateAlivePlayerRoles()
	for _, kingdom in ipairs(sgs.KingdomsTable) do
		sgs.current_mode_players[kingdom] = 0
	end
	sgs.robot = {}
	for _, aplayer in sgs.qlist(Global_room:getAllPlayers()) do
		if aplayer:getState() == "robot" then table.insert(sgs.robot, aplayer) end
		local kingdom = aplayer:getKingdom()
		if aplayer:getRole() == "careerist" or kingdom == "god" then
			kingdom = "careerist"
		end
		if not sgs.current_mode_players[kingdom] then sgs.current_mode_players[kingdom] = 0 end
		sgs.current_mode_players[kingdom] = sgs.current_mode_players[kingdom] + 1
	end
end

function getTrickIntention(trick_class, target)
	local intention = sgs.ai_card_intention[trick_class]
	if type(intention) == "number" then
		return intention
	elseif type(intention == "function") then
		if trick_class == "IronChain" then
			if target and target:isChained() then return -60 else return 60 end
		end
	end
	if trick_class == "Collateral" then return 0 end
	if trick_class == "AwaitExhausted" then return -10 end
	if trick_class == "BefriendAttacking" then return -10 end
	if sgs.dynamic_value.damage_card[trick_class] then
		return 70
	end
	if sgs.dynamic_value.benefit[trick_class] then
		return -40
	end
	if target then
		if trick_class == "Snatch" or trick_class == "Dismantlement" then
			local judgelist = target:getCards("j")
			if not judgelist or judgelist:isEmpty() then
				if not target:hasArmorEffect("SilverLion") or not target:isWounded() then
					return 80
				end
			end
		end
	end
	return 0
end


sgs.ai_choicemade_filter.Nullification.general = function(self, player, promptlist)
	local trick_class = promptlist[2]
	local target_objectName = promptlist[3]
	if string.find(trick_class, "Nullification") then
		if not sgs.nullification_source or not sgs.nullification_intention or type(sgs.nullification_intention) ~= "number" then
			self.room:writeToConsole(debug.traceback())
			return
		end
		sgs.nullification_level = sgs.nullification_level + 1
		if not sgs.isAnjiang(player) or not sgs.isAnjiang(sgs.nullification_source) then--大部分情况
			if sgs.nullification_level % 2 == 0 then
				sgs.updateIntention(player, sgs.nullification_source, sgs.nullification_intention)
			elseif sgs.nullification_level % 2 == 1 then
				sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
			end
		else--明将A顺暗将B,暗将B无懈,另一个暗将C反无懈,判定C跳A势力
			local helper_from = self.room:findPlayerbyobjectName(target_objectName)
			if helper_from and not sgs.isAnjiang(helper_from) then
				if sgs.nullification_level % 2 == 0 then
					sgs.updateIntention(player, helper_from, sgs.nullification_intention)
				elseif sgs.nullification_level % 2 == 1 then
					sgs.updateIntention(player, helper_from, -sgs.nullification_intention)
				end
			end
		end
	else
		sgs.nullification_source = self.room:findPlayerbyobjectName(target_objectName)
		sgs.nullification_level = 1
		sgs.nullification_intention = getTrickIntention(trick_class, sgs.nullification_source)
		if sgs.nullification_intention == 0 then
			Global_room:writeToConsole("getTrickIntention:0:"..trick_class)--Drowning,
		end
		if player:objectName() ~= target_objectName then
			sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
		end
	end
end

sgs.ai_choicemade_filter.playerChosen.general = function(self, from, promptlist)
	if from:objectName() == promptlist[3] then return end
	local reason = string.gsub(promptlist[2], "%-", "_")
	local nameslist = promptlist[3]:split("+")
	for _, to_name in ipairs(nameslist) do
		local to = self.room:findPlayerbyobjectName(to_name)
		local callback = sgs.ai_playerchosen_intention[reason]
		if callback then
			if type(callback) == "number" then
				sgs.updateIntention(from, to, sgs.ai_playerchosen_intention[reason])
			elseif type(callback) == "function" then
				callback(self, from, to)
			end
		end
	end
end

sgs.ai_choicemade_filter.viewCards.general = function(self, from, promptlist)
	local to = self.room:findPlayerbyobjectName(promptlist[#promptlist])
	if to and not to:isKongcheng() then
		local flag = string.format("%s_%s_%s", "visible", from:objectName(), to:objectName())
		for _, card in sgs.qlist(to:getHandcards()) do
			if not card:hasFlag("visible") then card:setFlags(flag) end
		end
	end
end

sgs.ai_choicemade_filter.guanxingViewCards.general = function(self, from, promptlist)
	local player = promptlist[2]
	local ids = promptlist[#promptlist]:split("+")
	local count = self.room:getTag("SwapPile"):toInt()
	if not sgs.ai_guangxing[player][count] then
		sgs.ai_guangxing[player][count] = {}
	end
	for _, id in ipairs(ids) do
		if string.len(id) == 0 then continue end
		if not table.contains(sgs.ai_guangxing[player][count], id) then
			table.insert(sgs.ai_guangxing[player][count], id)
		end
	end
end

sgs.ai_choicemade_filter.Yiji.general = function(self, f, promptlist)
	local from = self.room:findPlayerbyobjectName(promptlist[3])
	local to = self.room:findPlayerbyobjectName(promptlist[4])
	local reason = promptlist[2]
	local cards = {}
	local card_ids = promptlist[5]:split("+")
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(tonumber(id))
		table.insert(cards, card)
	end
	if from and to then
		local callback = sgs.ai_Yiji_intention[reason]
		if callback then
			if type(callback) == "number" and not (self:needKongcheng(to, true) and #cards == 1) then
				sgs.updateIntention(from, to, sgs.ai_Yiji_intention[reason])
			elseif type(callback) == "function" then
				callback(self, from, to, cards)
			end
		elseif not (self:needKongcheng(to, true) and #cards == 1) then
			sgs.updateIntention(from, to, -10)
		end
	end
end

function SmartAI:filterEvent(event, player, data)
	--self.room:writeToConsole("事件记录："..event)
	--self.room:outputEventStack()
	--self.room:throwEvent(event)
	if not sgs.recorder then
		sgs.recorder = self
	end
	if player:objectName() == self.player:objectName() then
		if sgs.debugmode and type(sgs.ai_debug_func[event]) == "table" then
			for _, callback in pairs(sgs.ai_debug_func[event]) do
				if type(callback) == "function" then callback(self, player, data) end
			end
		end
		if type(sgs.ai_chat_func[event]) == "table" and sgs.GetConfig("AIChat", false) and sgs.GetConfig("OriginAIDelay", 0) > 0 then
			for _, callback in pairs(sgs.ai_chat_func[event]) do
				if type(callback) == "function" then callback(self, player, data) end
			end
		end
		if type(sgs.ai_event_callback[event]) == "table" then
			for _, callback in pairs(sgs.ai_event_callback[event]) do
				if type(callback) == "function" then callback(self, player, data) end
			end
		end
	end

	-- if not sgs.DebugMode_Niepan and event == sgs.AskForPeaches and self.room:getCurrentDyingPlayer():objectName() == self.player:objectName() then endlessNiepan(self, data:toDying().who) end

	sgs.lastevent = event
	sgs.lasteventdata = data
	if event == sgs.ChoiceMade and (self == sgs.recorder or self.player:objectName() == sgs.recorder.player:objectName()) then
		local carduse = data:toCardUse()
		if carduse and carduse.card ~= nil then
			for _, callback in ipairs(sgs.ai_choicemade_filter.cardUsed) do
				if type(callback) == "function" then
					callback(self, player, carduse)
				end
			end
		elseif data:toString() then--cardChosen不再触发ChoiceMade阶段(2.3.40??)顺拆之类的AI身份判断已经无效了--(cardChosen:reason:card_id:from:to)
			local promptlist = data:toString():split(":")
			local callbacktable = sgs.ai_choicemade_filter[promptlist[1]]
			if callbacktable and type(callbacktable) == "table" then
				local index = 2
				if promptlist[1] == "cardResponded" then
					if promptlist[2]:match("jink") and not self:hasEightDiagramEffect(player) then
						sgs.card_lack[player:objectName()]["Jink"] = promptlist[#promptlist] == "_nil_" and 1 or 0
					elseif promptlist[2]:match("slash") then
						sgs.card_lack[player:objectName()]["Slash"] = promptlist[#promptlist] == "_nil_" and 1 or 0
					elseif promptlist[2]:match("peach") then
						sgs.card_lack[player:objectName()]["Peach"] = promptlist[#promptlist] == "_nil_" and 1 or 0
					end

					index = 3
				end
				local callback = callbacktable[promptlist[index]] or callbacktable.general
				if type(callback) == "function" then
					callback(self, player, promptlist)
				end
			end
		end
	elseif event == sgs.GameStart or event == sgs.EventPhaseStart or event == sgs.RemoveStateChanged then--event == sgs.CardFinished
		self:updatePlayers(self == sgs.recorder)
	elseif event == sgs.BuryVictim or event == sgs.HpChanged or event == sgs.MaxHpChanged then
		self:updatePlayers(self == sgs.recorder)
	end

	if event == sgs.GameStart and sgs.GetConfig("ViewNextPlayerDeputyGeneral", true) then--查看下家副将，不是每次游戏开始都会进入filterEvent？
		self.room:writeToConsole("查看下家的副将")
		sgs.viewNextPlayerDeputy()
	end

	if event == sgs.BuryVictim then
		if self == sgs.recorder then sgs.updateAlivePlayerRoles() end
	end

	if self.player:objectName() == player:objectName() and event == sgs.AskForPeaches then
		local dying = data:toDying()
		if self:isFriend(dying.who) and dying.who:getHp() < 1 then
			sgs.card_lack[player:objectName()]["Peach"] = 1
		end
	end
	if self.player:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_Play and event == sgs.CardsMoveOneTime then
		--local move = data:toMoveOneTime()
		local movelist = data:toList()--data改为了CardsMoveList(2.3.0)
		for _, move_data in sgs.qlist(movelist) do
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip) then
				self:assignKeep()
			-- elseif move.from and move.from:objectName() == player:objectName()   and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
				-- self:assignKeep()
			end
		end
	end

	if self ~= sgs.recorder then return end

	if event == sgs.GeneralShown then
		self:updatePlayerKingdom(player, data)
	elseif event == sgs.GeneralHidden then
		if player:getAI() then player:setSkillsPreshowed("hd", true) end
	elseif event == sgs.TargetChoosing then--选择目标时
	--elseif event == sgs.TargetConfirmed then--成为目标后(player为触发者,use.to:contains(player))
		local struct = data:toCardUse()
		local from = struct.from
		local card = struct.card
		local tos = sgs.QList2Table(struct.to)
		
		if from and from:objectName() == player:objectName() then
			local callback = sgs.ai_card_intention[card:getClassName()]
			if callback then
				if type(callback) == "function" then
					callback(self, card, from, tos)
				elseif type(callback) == "number" then
					sgs.updateIntentions(from, tos, callback, card)
				end
			end
			-- AI Chat
			speakTrigger(card, from, tos)
			if card:getClassName() == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
				local luacallback = sgs.ai_card_intention[card:objectName()]
				if luacallback then
					if type(luacallback) == "function" then
						luacallback(self, card, from, tos)
					elseif type(luacallback) == "number" then
						sgs.updateIntentions(from, tos, luacallback, card)
					end
				end
			end
		end

		if card:isKindOf("AOE") and self.player:objectName() == player:objectName() then
			for _, t in sgs.qlist(struct.to) do
				if t:hasShownSkills("fangzhu|jianxiong|qiuan") then sgs.ai_AOE_data = data break end
				if t:hasShownSkill("guidao") and t:hasShownSkill("leiji") and card:isKindOf("ArcheryAttack") then sgs.ai_AOE_data = data break end
			end
			if from and from:hasSkill("zhiman") then--马谡相关
				sgs.ai_AOE_data = data
			end
		end

	elseif event == sgs.PreDamageDone then
		local damage = data:toDamage()
		local clear = true
		if clear and damage.to:isChained() then
			for _, p in sgs.qlist(self.room:getOtherPlayers(damage.to)) do
				if p:isChained() and damage.nature ~= sgs.DamageStruct_Normal then
					clear = false
					break
				end
			end
		end
		if not clear then
			if damage.nature ~= sgs.DamageStruct_Normal and not damage.chain then
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					local added = 0
					if p:objectName() == damage.to:objectName() and p:isChained() and p:getHp() <= damage.damage then
						sgs.ai_NeedPeach[p:objectName()] = damage.damage + 1 - p:getHp()
					elseif p:objectName() ~= damage.to:objectName() and p:isChained() and self:damageIsEffective(p, damage.nature, damage.from) then
						if damage.nature == sgs.DamageStruct_Fire then
							added = p:hasArmorEffect("Vine") and added + 1 or added
							sgs.ai_NeedPeach[p:objectName()] = damage.damage + 1 + added - p:getHp()
						elseif damage.nature == sgs.DamageStruct_Thunder then
							sgs.ai_NeedPeach[p:objectName()] = damage.damage + 1 + added - p:getHp()
						end
					end
				end
			end
		else
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				sgs.ai_NeedPeach[p:objectName()] = 0
			end
		end
	elseif event == sgs.CardUsed then
		local struct = data:toCardUse()
		local card = struct.card
		local who
		if not struct.to:isEmpty() then who = struct.to:first() end

		if card:isKindOf("Snatch") or card:isKindOf("Dismantlement") then
			for _, p in sgs.qlist(struct.to) do
				for _, c in sgs.qlist(p:getCards("hej")) do
					self.room:setCardFlag(c, "-AIGlobal_SDCardChosen_"..card:objectName())
				end
			end
		end

		if card:isKindOf("AOE") and sgs.ai_AOE_data then
			sgs.ai_AOE_data = nil
		end

		if card:isKindOf("Collateral") then sgs.ai_collateral = false end

	elseif event == sgs.CardsMoveOneTime then
		--local move = data:toMoveOneTime()
		local movelist = data:toList()--data改为了CardsMoveList(2.3.0)
		local hand_visible = false
		for _, move_data in sgs.qlist(movelist) do
			local move = move_data:toMoveOneTime()
			local from = nil   -- convert move.from from const Player * to ServerPlayer *
			local to = nil   -- convert move.to to const Player * to ServerPlayer *
			if move.from then from = self.room:findPlayerbyobjectName(move.from:objectName(), true) end
			if move.to then to = self.room:findPlayerbyobjectName(move.to:objectName(), true) end
			local reason = move.reason
			local from_places = sgs.QList2Table(move.from_places)

			for i = 0, move.card_ids:length() - 1 do
				local place = move.from_places:at(i)
				local card_id = move.card_ids:at(i)
				local card = sgs.Sanguosha:getCard(card_id)

				if move.to_place == sgs.Player_PlaceHand and to and player:objectName() == to:objectName() then
					--self.room:writeToConsole("手牌可见事件记录")
					hand_visible = true
					if card:hasFlag("visible") then
						if isCard("Slash", card, player) then sgs.card_lack[player:objectName()]["Slash"] = 0 end
						if isCard("Jink", card, player) then sgs.card_lack[player:objectName()]["Jink"] = 0 end
						if isCard("Peach", card, player) then sgs.card_lack[player:objectName()]["Peach"] = 0 end
					else
						sgs.card_lack[player:objectName()]["Slash"] = 0
						sgs.card_lack[player:objectName()]["Jink"] = 0
						sgs.card_lack[player:objectName()]["Peach"] = 0
					end

					if place == sgs.Player_DrawPile then
						local count = self.room:getTag("SwapPile"):toInt()
						for _, p in sgs.qlist(self.room:getOtherPlayers(to)) do
							if sgs.ai_guangxing[p:objectName()][count] and table.contains(sgs.ai_guangxing[p:objectName()][count], tostring(card_id)) then
								table.removeOne(sgs.ai_guangxing[p:objectName()][count], card_id)
								local flag = string.format("%s_%s_%s", "visible", p:objectName(), to:objectName())
								self.room:setCardFlag(card_id, flag, p)
							end
						end
					end
				end

				if move.to_place == sgs.Player_PlaceHand and to and place ~= sgs.Player_DrawPile then
					if from and player:objectName() == from:objectName()
						and from:objectName() ~= to:objectName() and place == sgs.Player_PlaceHand and not card:hasFlag("visible") then
						local flag = string.format("%s_%s_%s", "visible", from:objectName(), to:objectName())
						Global_room:setCardFlag(card_id, flag, from)
					end
				end

				if player:hasFlag("AI_Playing") and player:hasShownSkill("leiji") and player:getPhase() == sgs.Player_Discard and isCard("Jink", card, player)
					and player:getHandcardNum() >= 2 and reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then sgs.card_lack[player:objectName()]["Jink"] = 2 end
			end
		end
		if hand_visible then self.room:writeToConsole("手牌可见事件记录") end
	elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Player then
		player:setFlags("AI_Playing")
		if player:getTag("AI_FireAttack_NoSuit"):toString() ~= "" then--火攻失败标记处理
			self.room:writeToConsole("回合结束火攻失败标记去除")
			player:removeTag("AI_FireAttack_NoSuit")
		end
	elseif event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_RoundStart then
			if not sgs.ai_setSkillsPreshowed then
				self:setSkillsPreshowed()
				sgs.ai_setSkillsPreshowed = true
			end
			if player:getAI() then player:setSkillsPreshowed("hd", true) end
			-- sgs.printFEList(player)
			-- sgs.debugFunc(player, 3)
		elseif player:getPhase() == sgs.Player_NotActive then
			if sgs.recorder.player:objectName() == player:objectName() then sgs.turncount = sgs.turncount + 1 end
		end
	end
end

function SmartAI:askForSuit(reason)
	if not reason then return sgs.ai_skill_suit.fanjian(self) end -- this line is kept for back-compatibility
	local callback = sgs.ai_skill_suit[reason]
	if type(callback) == "function" then
		if callback(self) then return callback(self) end
	end
	return math.random(0, 3)
end

function SmartAI:askForSkillInvoke(skill_name, data)
	skill_name = string.gsub(skill_name, "%-", "_")
	--[[
	if string.find(skill_name,"*") then
		--yiji*2
		--skill_name = skill_name:split("*")[1]
		skill_name = string.gsub(skill_name, "(%w+)(*%d)", "%1")
	end
	--]]
	local invoke = sgs.ai_skill_invoke[skill_name]
	if type(invoke) == "boolean" then
		return invoke
	elseif type(invoke) == "function" then
		if invoke(self, data) == true then
			return true
		else
			return false
		end
	else
		local skill = sgs.Sanguosha:getSkill(skill_name)
		if skill and skill:getFrequency() == sgs.Skill_Frequent then
			return true
		end
	end
	return nil
end

function SmartAI:askForChoice(skill_name, choices, data)
	local choice_table = {}
	for _,section in pairs(choices:split("|")) do
		table.insertTable(choice_table, section:split("+"))
	end
	local choice = sgs.ai_skill_choice[skill_name]
	if type(choice) == "string" then
		return choice
	elseif type(choice) == "function" then
		return choice(self, table.concat(choice_table, "+"), data)
	else
		if table.contains(choice_table, "cancel") then return "cancel" end
		if table.contains(choice_table, "no") then return "no" end
		for index, achoice in ipairs(choice_table) do
			if achoice == "benghuai" then table.remove(choice_table, index) break end
		end
		local r = math.random(1, #choice_table)
		return choice_table[r]
	end
end

function SmartAI:askForExchange(reason,pattern,max_num,min_num,expand_pile)
	min_num = min_num or 0
	local callback = sgs.ai_skill_exchange[reason]
	if type(callback) == "function" then
		local result = callback(self,pattern,max_num,min_num,expand_pile)
		--包括军令2(power)
		if type(result) == "number" then
			if result == -1 then--防止self:getCard("Peach")会拿到珠子导致游戏崩溃
				--askForExchange:reason:pattern:weimeng_giveback:
				Global_room:writeToConsole("askForExchange:reason:pattern:"..tostring(reason)..":"..tostring(pattern))
			else
				return {result}
			end
		elseif type(result) == "table" then
			if table.contains(result, -1) then--防止self:getCard("Peach")会拿到珠子导致游戏崩溃
				Global_room:writeToConsole("askForExchange:reason:pattern:"..tostring(reason)..":"..tostring(pattern))
			else
				return result
			end
		else
			assert(false,"the Exchange result should be a number or a table")
			Global_room:writeToConsole("askForExchange:reason:pattern:"..tostring(reason)..":"..tostring(pattern))
			Global_room:writeToConsole("askForExchange:result:"..tostring(result))
			return {}
		end
	end
	return {}
end

function SmartAI:askForDiscard(reason, discard_num, min_num, optional, include_equip)
	min_num = min_num or discard_num
	local exchange = self.player:hasFlag("Global_AIDiscardExchanging")
	local callback = sgs.ai_skill_discard[reason]
	self:assignKeep(true)
	local armor = self.player:getArmor()
	if type(callback) == "function" then
		local cb = callback(self, discard_num, min_num, optional, include_equip)
		if cb then
			if type(cb) == "number" and not self.player:isJilei(sgs.Sanguosha:getCard(cb)) then return { cb }
			elseif type(cb) == "table" then
				for _, card_id in ipairs(cb) do
					if not exchange and self.player:isJilei(sgs.Sanguosha:getCard(card_id)) then
						return {}
					end
				end
				return cb
			end
			return {}
		end
	elseif (optional and include_equip) then
		return (min_num == 1 and self:needToThrowArmor()) and {armor:getEffectiveId()} or {}
	end
	if min_num == 0 then Global_room:writeToConsole("askForDiscard不弃牌:"..tostring(reason)) end

	local flag = "h"
	if include_equip and not(self.player:getEquips():isEmpty() or self.player:isJilei(self.player:getEquips():first())) then flag = flag .. "e" end
	
	if self.player:hasShownSkill("xiaoji") and self.player:getPhase() == sgs.Player_NotActive 
		and discard_num == 1 and flag:match("e") and not self.player:containsTrick("supply_shortage") then
		if self.player:getEquips():length() ~= 1 then
			flag = "e"
		end
	end
	
	local change_hand = false
	if self:getLeastHandcardNum() > 0 and self.player:getHandcardNum() >= min_num and self:getLeastHandcardNum() > self.player:getHandcardNum() - min_num 
		and flag:match("h") and not(self.player:hasSkills(sgs.lose_equip_skill) or self:needToThrowArmor() or self:needKongcheng()) then--弃牌时,如果能刷手牌,不弃装备
		if self:getLeastHandcardNum() > min_num then--小心鸡肋……
			change_hand = true
		else
			local can_save_num = self.player:getHandcardNum() - min_num
			local dis_important_card = nil
			for _, card in sgs.qlist(self.player:getCards("h")) do
				if self:getKeepValue(card) >= 4.1 or self:getUseValue(card) >= 6 then
					if can_save_num > 0 then
						can_save_num = can_save_num - 1
					else
						dis_important_card = card
						break
					end
				end
			end
			if not dis_important_card then change_hand = true end
		end
	end
	
	local cards = self.player:getCards(flag)
	cards = sgs.QList2Table(cards)
	--1血被杀(守城气傲)弃酒留明光？
	local current = self.room:getCurrent()
	local saveByUse = (self.player:getPhase() <= sgs.Player_Play and not self.player:isSkipped(sgs.Player_Play))--再考虑座次判断，如队列下家、一路盟军
	if (self:getEnemyNumBySeat(self.player, current) < (self:isWeak() and 1 or 2))--and self.room:alivePlayerCount() > 3
	or (current:getFormation():contains(self.player) and self:playerGetRound(self.player, current) > 0)
	or (self:playerGetRound(self.player, current) < 4 and self.player:getHp() > 2) then--1v1的时候？
		saveByUse = true
	end
	if saveByUse then
		--Global_room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat())).."按使用价值弃牌")
		self:sortByUseValue(cards, true)
	elseif (self.player:hasSkill("lirang") and #self.friends_noself > 0 and self.player:willBeFriendWith(current)
		and self.player:objectName() ~= current:objectName() and current:getPhase() <= sgs.Player_Play and not current:isSkipped(sgs.Player_Play)) then
		self:sortByUseValue(cards)
		if discard_num == 1 then
			local acard, afriend = self:getCardNeedPlayer(cards, self.friends_noself)
			if acard and afriend then return {acard:getEffectiveId()} end
		end
	else
		self:sortByKeepValue(cards)
	end
	
	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num - 1
	end
	local temp_cards, to_dis_ids, to_save_ids, discardEquip, discardQiwu = cards,{},{},nil,nil
	
	if self.player:hasSkills(sgs.lose_equip_skill) then
		if self.player:hasSkill("xiaoji") and self.player:getPhase() == sgs.Player_NotActive then
			discardEquip = false
		end
		if self.player:hasSkill("xuanlue") then
			local promo = self:findPlayerToDiscard("he", false, sgs.Card_MethodDiscard, nil, false)
			if promo then
				discardEquip = false
			end
		end
	end
	
	if self.player:hasSkill("jgqiwu") then
		local arr1, arr2 = self:getWoundedFriend()
		--if #arr1 > 0 then discardQiwu = false end
		if #arr1 > 0 then
			if not (#arr1 == 1 and self.player:isWounded()) then
				discardQiwu = false
			end
		end
	end
	local best_equips = {}
	local hold_peacespell = false
	if include_equip then
		if self:needToThrowArmor() and armor:getEffectiveId() then
			--table.removeOne(temp_cards, armor)
			temp_cards = self:resetCards(temp_cards, armor)
			table.insert(to_dis_ids, armor:getEffectiveId())
			if armor:getSuit() == sgs.Card_Club and discardQiwu == false then discardQiwu = true end
			if not discardEquip then discardEquip = true end
			if discard_num == 1 then return to_dis_ids end
		end
		if flag:match("h") then
			for _, ecard in sgs.qlist(self.player:getCards("e")) do
				local equip_value = 0
				local best_equip = ecard
				if ecard:isKindOf("Weapon") then
					equip_value = self:evaluateWeapon(ecard)
				elseif ecard:isKindOf("Armor") then
					equip_value = self:evaluateArmor(ecard)
				else
					equip_value = self:getKeepValue(ecard)
				end
				for _, hcard in sgs.qlist(self.player:getCards("h")) do
					if not hcard:isKindOf("EquipCard") then continue end
					if hcard:isKindOf("Weapon") and self:evaluateWeapon(hcard) > equip_value then
						equip_value = self:evaluateWeapon(hcard)
						best_equip = hcard
					elseif hcard:isKindOf("Armor") and self:evaluateArmor(hcard) > equip_value then
						equip_value = self:evaluateArmor(hcard)
						best_equip = hcard
					elseif self:getSameEquip(hcard) and self:getSameEquip(hcard):toString() == ecard:toString() and self:getKeepValue(hcard) > equip_value then
						equip_value = self:getKeepValue(hcard)
						best_equip = hcard
					end
				end
				if best_equip:objectName() == "PeaceSpell" then hold_peacespell = true end
				table.insert(best_equips, best_equip)
			end
		end
	else
		--太平要术手牌价值
		local has_peacespell = false
		for _, card in ipairs(temp_cards) do
			if card:objectName() == "PeaceSpell" then has_peacespell = true break end
		end
		if has_peacespell and self.player:getPhase() <= sgs.Player_Discard and not self.player:isSkipped(sgs.Player_Discard)
			and not self.player:hasSkill("keji") then
			local PeaceSpell_loss = 0
			local lord_zhangjiao = sgs.findPlayerByShownSkillName("wendao")
			local erzhang = sgs.findPlayerByShownSkillName("guzheng")
			local PeaceSpell_MaxCards = self.player:getPlayerNumWithSameKingdom("AI")
			local need_extra_discard = 0
			local hand_card_num = self.player:getHandcardNum()
			local max_card_num = self.player:getMaxCards()
			--[[
			local armor = self.player:getArmor()
			if armor and armor:objectName() == "PeaceSpell"  then
				hand_card_num = hand_card_num + 2
				if self:getCardsNum("Peach") == 0 and self.player:getHp() > 1 then
					max_card_num = max_card_num - 1
				end
			end
			--]]
			if hand_card_num > max_card_num - PeaceSpell_MaxCards then
				if self.player:hasSkill("qiaobian") and hand_card_num-(max_card_num-PeaceSpell_MaxCards) > 0 then
					PeaceSpell_loss = 1
				else  
					if hand_card_num >= max_card_num then
						need_extra_discard = PeaceSpell_MaxCards
					elseif hand_card_num < max_card_num and hand_card_num >= max_card_num - PeaceSpell_MaxCards then
						need_extra_discard = hand_card_num - (max_card_num - PeaceSpell_MaxCards)
					end
				end
				if need_extra_discard > 1 then
					if erzhang and erzhang:isAlive() and not self.player:willBeFriendWith(erzhang) then
						PeaceSpell_loss = PeaceSpell_loss + (need_extra_discard - 1)*2
					else
						PeaceSpell_loss = PeaceSpell_loss + need_extra_discard
					end
				end
				if PeaceSpell_loss > PeaceSpell_MaxCards then hold_peacespell = true end
			end
		end
	end
	
	local can_diaodu = false
	local lvfan = sgs.findPlayerByShownSkillName("diaodu")
	if lvfan and self.player:isFriendWith(lvfan) and saveByUse then can_diaodu = true end--调度使用装备
	local function getCardSurplusValue(card,to_save_ids,to_dis_ids)
		local v,borderline = 0,0
		if discardEquip and in_equips and not self.player:isKongcheng() then return true end--尽量保存装备
		if saveByUse then
			v = self:getUseValue(card)
			borderline = sgs.ai_use_value.Peach
			if card:isKindOf("EquipCard") and not in_equips then
				if self.player:hasSkills(sgs.lose_equip_skill) then v = v + 2
				elseif can_diaodu then
					v = v + 4
				elseif self.player:hasSkill("zhijian") then
					local to_zhijian = false
					for _, friend in ipairs(self.friends_noself) do
						if not self:getSameEquip(card, friend) then
							to_zhijian = true
							break
						end
					end
					if to_zhijian then v = v + 4 end
				end
			end
		else
			v = self:getKeepValue(card)
			borderline = 4.1
		end
		if self.player:hasSkills(sgs.lose_equip_skill) and in_equips and discardEquip == false then v = v - 4 end
		--[[
		if discardQiwu and is_club and not table.contains(to_save_ids, card:getEffectiveId()) then 
			if in_equips then v = v + 2 else v = v + 1 end
		end
		if v <= 7 and discardQiwu == false and is_club then return false end
		--]]
		if v >= borderline then return true end
		if saveByUse and self:getOverflow() > 0 and in_equips and not self.player:isKongcheng() then return true end--尽量保存装备
		return false
	end
	if #temp_cards > 0 then
		for _, card in ipairs(temp_cards) do
			if exchange or not self.player:isJilei(card) then
				local in_equips = self.player:hasEquip(card)
				local is_club = (card:getSuit() == sgs.Card_Club)
				if (hold_peacespell and card:objectName() == "PeaceSpell")--弃牌阶段前考虑保留太平
					or (table.contains(best_equips, card) and discardEquip == false)--最有价值的装备
					or (in_equips and (discardEquip or change_hand))--保装备刷手牌,已经弃置装备(失去装备技能或者需要弃置防具)
					or getCardSurplusValue(card,to_save_ids,to_dis_ids)then
					table.insert(to_save_ids, card:getEffectiveId())
				else
					table.insert(to_dis_ids, card:getEffectiveId())
					if is_club and discardQiwu == false then discardQiwu = true end
					if in_equips and not discardEquip then discardEquip = true end
				end
			end
			if #to_dis_ids >= discard_num then break end--最多只能弃置discard_num
		end
	end
	if #to_dis_ids < min_num then--保底弃置最小数量min_num,贲育设置的discard_num为998……
		local temp_save = {}
		for _, card_id in ipairs(to_save_ids) do
			local card = sgs.Sanguosha:getEngineCard(card_id)
			table.insert(temp_save, card)
		end
		if self.player:getPhase() <= sgs.Player_Play and not self.player:isSkipped(sgs.Player_Play) then
			self:sortByUseValue(temp_save, true)
		else
			self:sortByKeepValue(temp_save)
		end
		for _, card in ipairs(temp_save) do
			table.insert(to_dis_ids, card:getEffectiveId())
			if #to_dis_ids >= min_num then break end
		end
	end

	return to_dis_ids
end

sgs.ai_skill_discard.gamerule = function(self, discard_num)
	local cards = sgs.QList2Table(self.player:getHandcards())
	if self.player:getMark("ThreatenEmperorExtraTurn") > 0 then--挟天子连续回合，失效？？
		Global_room:writeToConsole("挟天子连续回合弃牌："..sgs.Sanguosha:translate(self.player:getGeneralName()).."/"..sgs.Sanguosha:translate(self.player:getGeneral2Name()))
		self:sortByUseValue(cards,true)
	else
		self:sortByKeepValue(cards)
	end
	local to_discard = {}
	for _, card in ipairs(cards) do
		if not self.player:isCardLimited(card, sgs.Card_MethodDiscard, true) then
			table.insert(to_discard, card:getId())
		end
		if #to_discard >= discard_num or self.player:isKongcheng() then break end
	end

	return to_discard
end

function SmartAI:askForMoveCards(upcards, downcards, reason, pattern, min_num, max_num)
	local callback = sgs.ai_skill_movecards[reason]
	if type(callback) == "function" then
		local top, down = callback(self, upcards, downcards, min_num, max_num)
		local res1, res2 = {}, {}
		if top then
			if type(top) == "number" then res1 = {top}
			elseif type(top) == "table" then
				res1 = top
			end
		end
		if down then
			if type(down) == "number" then res2 = {down}
			elseif type(down) == "table" then
				res2 = down
			end
		end
		if #upcards + #downcards == #res1 + #res2 then
			return res1, res2
		end
	end
	return {}, {}
end

function SmartAI:askForTransferFieldCards(targets, reason, equipArea, judgingArea)
	local callback = sgs.ai_skill_transfercardchosen[reason]
	if type(callback) == "function" then
		local card = callback(self, targets, equipArea, judgingArea)
		if type(card) == "number" then return card
		elseif card then return card:getEffectiveId() end
	end
	return -1
end

--positive：为 true 时，本【无懈可击】使 trick 失效，否则本【无懈可击】使 trick 生效
function SmartAI:askForNullification(trick, from, to, positive)
	if self.player:isDead() then return nil end
	if trick:isKindOf("SavageAssault") and self:isFriend(to) and positive then
		local menghuo = sgs.findPlayerByShownSkillName("huoshou")
		if menghuo and self:isFriend(to, menghuo) and menghuo:hasShownSkill("zhiman") then return nil end
	end
	if from and self:isFriend(to, from) and self:isFriend(to) and positive and from:hasShownSkill("zhiman") then return nil end
	local nullcards = self.player:getCards("Nullification")
	local null_num = self:getCardsNum("Nullification")
	local null_card = self:getCardId("Nullification")
	local targets = sgs.SPlayerList()
	local delete = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. trick:toString()):toList()
	local names = {}
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
		delete:append(q:toPlayer())
		table.insert(names, q:toPlayer():screenName())
	end
	for _, p in sgs.qlist(delete) do
		if delete:indexOf(p) < delete:indexOf(to) then targets:removeOne(p) end
	end

	if null_num > 1 then
		for _, card in sgs.qlist(nullcards) do
			if not card:isKindOf("HegNullification") then
				null_card = card:toString()
				break
			end
		end
	end
	local keep
	if null_num == 1 then
		local only = true
		for _, p in ipairs(self.friends_noself) do
			if getKnownCard(p, self.player, "Nullification", nil, "he") > 0 then
				only = false
				break
			end
		end
		if only then
			for _, p in ipairs(self.friends) do
				if p:containsTrick("indulgence") and not p:hasShownSkills("guanxing|yizhi|shensu|qiaobian") and p:getHandcardNum() >= p:getHp() and not trick:isKindOf("Indulgence") then
					keep = true
					break
				end
			end
		end
	end

	if null_card then null_card = sgs.Card_Parse(null_card) else return nil end
	assert(null_card)
	if self.player:isLocked(null_card) then return nil end
	if (from and from:isDead()) or (to and to:isDead()) then return nil end

	local jgyueying = sgs.findPlayerByShownSkillName("jgjingmiao")
	if jgyueying and self:isEnemy(jgyueying) and self.player:getHp() == 1 then return nil end

	if trick:isKindOf("FireAttack") then
		if to:isKongcheng() or from:isKongcheng() then return nil end
		if self.player:objectName() == from:objectName() and self.player:getHandcardNum() == 1 and self.player:handCards():first() == null_card:getId() then return nil end
	end

	if ("snatch|dismantlement"):match(trick:objectName()) and to:isAllNude() then return nil end

	if from then
		if (trick:isKindOf("Duel") or trick:isKindOf("AOE")) and not self:damageIsEffective(to, sgs.DamageStruct_Normal, from) then return nil end
		if trick:isKindOf("FireAttack")
		and (not self:damageIsEffective(to, sgs.DamageStruct_Fire, from) or from:getHandcardNum() < 3 or (from:hasShownSkill("hongyan") and to:getHandcardNum() > 3)) then
			return nil
		end
		if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) and self:needDamagedEffects(to, from) and self:isFriend(to) then
			return nil
		end
	end

	if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) and self:needToLoseHp(to, from) and self:isFriend(to) then
		return nil
	end

	local callback = sgs.ai_nullification[trick:getClassName()]
	if type(callback) == "function" then
		local shouldUse, single = callback(self, trick, from, to, positive, keep)
		if self.room:getTag("NullifyingTimes"):toInt() > 0 then single = true end
		if shouldUse and not single then
			local heg_null_card = self:getCard("HegNullification")
			if heg_null_card then null_card = heg_null_card end
		end
		return shouldUse and null_card
	end
	if keep then																			--要为被乐的友方保留无懈
		if not (self:isFriend(to) and self:isWeak(to)) then return nil end
	end

	if positive then
		if from and from:objectName() == to:objectName() and self:isFriend(from) then
			return
		end

		if from and (trick:isKindOf("FireAttack") or trick:isKindOf("Duel")) and self:cantbeHurt(to, from) and self:isWeak(to) and self:isFriend(to) then
			return null_card
		end

		local isEnemyFrom = from and self:isEnemy(from)
		if isEnemyFrom and self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 and self.player:isLastHandCard(null_card) and trick:isKindOf("SingleTargetTrick") then
			return null_card
		elseif trick:isKindOf("ExNihilo") then
			if isEnemyFrom and self:evaluateKingdom(from) ~= "unknown" and (self:isWeak(from) or from:hasShownSkills(sgs.cardneed_skill)) then
				return null_card
			end
		elseif trick:isKindOf("Snatch") then
			if (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) and self:isFriend(to) and to:isNude() then return nil end
			if isEnemyFrom and self:isFriend(to, from) and to:getCards("j"):length() > 0 then
				return null_card
			elseif from and self:isFriend(from) and self:isFriend(to) then return nil
			elseif self:isFriend(to) then return null_card
			end
		elseif trick:isKindOf("Dismantlement") then
			if (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) and self:isFriend(to) and to:isNude() then return nil end
			if isEnemyFrom and self:isFriend(to, from) and to:getCards("j"):length() > 0 then
				return null_card
			end
			if from and self:isFriend(from) and self:isFriend(to) then return nil end
			if self:isFriend(to) then
				if self:getDangerousCard(to) or self:getValuableCard(to) then return null_card end
				if to:getHandcardNum() == 1 and not self:needKongcheng(to) then
					if (getKnownCard(to, self.player, "TrickCard", false) == 1 or getKnownCard(to, self.player, "EquipCard", false) == 1 or getKnownCard(to, self.player, "Slash", false) == 1) then
						return nil
					end
					return null_card
				end
			end
		elseif trick:isKindOf("IronChain") then
			if isEnemyFrom and self:isFriend(to) then
				local invoke
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					if p:hasArmorEffect("Vine") and (p:isChained() or targets:contains(p)) then
						invoke = true
					end
					if p:containsTrick("lightning") then
						local chainedfriends = {}
						for _, friend in ipairs(self.friends) do
							if friend:isChained() or targets:contains(friend) then
								table.insert(chainedfriends, friend)
							end
						end
						if #chainedfriends > 2 then invoke = true end
					end
				end
				if invoke then
					targets:removeOne(to)
					for _, p in sgs.qlist(targets) do
						if to:isFriendWith(p) then
							local heg_null_card = self:getCard("HegNullification")
							if heg_null_card then return heg_null_card end
						end
					end
				end
			return invoke and null_card end
		elseif trick:isKindOf("Duel") then
			if trick:getSkillName() == "lijian" then
				if self:isFriend(to) and (self:isWeak(to) or null_num > 1 or self:getOverflow() or not self:isWeak()) then return null_card end
				return
			end
			if isEnemyFrom and self:isFriend(to) then
				if self:isWeak(to) then return null_card
				elseif self.player:objectName() == to:objectName() then
					if self:getCardsNum("Slash") > getCardsNum("Slash", from, self.player) then return
					elseif self.player:hasSkills(sgs.masochism_skill) and
						(self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
						return nil
					elseif self:getCardsNum("Slash") == 0 then
						return null_card
					end
				end
			end
		elseif trick:isKindOf("FireAttack") then
			if to:isChained() and not(self:isFriend(from) and self:isEnemy(to)) then
				for _, p in sgs.qlist(self.room:getOtherPlayers(to)) do
					if p:isChained() and self:damageIsEffective(p, sgs.DamageStruct_Fire, from) and self:isFriend(p) and self:isWeak(p) then
						return null_card
					end
				end
			end
			if isEnemyFrom and self:isFriend(to) then
				if from:getHandcardNum() > 2 or self:isWeak(to) or to:hasArmorEffect("Vine") or to:getMark("@gale") > 0 then
					return null_card
				end
			end
		elseif trick:isKindOf("Indulgence") then
			if self:isFriend(to) and not to:isSkipped(sgs.Player_Play) then
				if to:hasShownSkills("guanxing|yizhi") and (Global_room:alivePlayerCount() > 4 or to:hasShownSkills("guanxing+yizhi")) then return nil end
				if to:getHp() - to:getHandcardNum() >= 2 then return nil end
				if to:hasShownSkill("tuxi") and to:getHp() > 2 then return nil end
				if to:hasShownSkill("qiaobian") and not to:isKongcheng() then return nil end
				if (to:containsTrick("supply_shortage") or self:willSkipDrawPhase(to)) and null_num <= 1 and self:getOverflow(to) < -1 then return nil end
				return null_card
			end
		elseif trick:isKindOf("SupplyShortage") then
			if self:isFriend(to) and not to:isSkipped(sgs.Player_Draw) then
				if to:hasShownSkills("guanxing|yizhi") and (Global_room:alivePlayerCount() > 4 or to:hasShownSkills("guanxing+yizhi")) then return nil end
				if to:hasShownSkills("guidao|tiandu") then return nil end
				if to:hasShownSkill("qiaobian") and not to:isKongcheng() then return nil end
				if (to:containsTrick("indulgence") or self:willSkipPlayPhase(to)) and null_num <= 1 and self:getOverflow(to) > 1 then return nil end
				return null_card
			end
		elseif trick:isKindOf("AmazingGrace") then
			if self:isEnemy(to) then
				local heg_null_card = self:getCard("HegNullification")
				if heg_null_card then
					local invoke = false
					for _, p in ipairs(self.enemies) do
						if targets:contains(p) and not p:objectName() == to:objectName() and p:isFriendWith(to) then
							invoke = true
							break
						end
					end
					local getvalue = 0
					if invoke then
						local ag_ids = self.room:getTag("AmazingGrace"):toStringList()
						for _, ag_id in ipairs(ag_ids) do
							local ag_card = sgs.Sanguosha:getCard(ag_id)
							if ag_card:isKindOf("Peach") then getvalue = getvalue + 1 end
							if ag_card:isKindOf("ExNihilo") then getvalue = getvalue + 1 end
							if ag_card:isKindOf("Snatch") then getvalue = getvalue + 1 end
							if ag_card:isKindOf("Analeptic") then getvalue = getvalue + 1 end
							if ag_card:isKindOf("Crossbow") then getvalue = getvalue + 1 end
						end
					end
					if getvalue > 1 then return heg_null_card end
				end
				local NP = self.room:nextPlayer(to)
				if self:isFriend(NP) then
					local ag_ids = self.room:getTag("AmazingGrace"):toStringList()
					local peach_num, exnihilo_num, snatch_num, analeptic_num, crossbow_num = 0, 0, 0, 0, 0
					for _, ag_id in ipairs(ag_ids) do
						local ag_card = sgs.Sanguosha:getCard(ag_id)
						if ag_card:isKindOf("Peach") then peach_num = peach_num + 1 end
						if ag_card:isKindOf("ExNihilo") then exnihilo_num = exnihilo_num + 1 end
						if ag_card:isKindOf("Snatch") then snatch_num = snatch_num + 1 end
						if ag_card:isKindOf("Analeptic") then analeptic_num = analeptic_num + 1 end
						if ag_card:isKindOf("Crossbow") then crossbow_num = crossbow_num + 1 end
					end
					if (peach_num == 1) or (peach_num > 0 and (self:isWeak(to) or self:getOverflow(NP) < 1)) then
						return null_card
					end
					if peach_num == 0 and not self:willSkipPlayPhase(NP) then
						if exnihilo_num > 0 then
							if NP:hasShownSkills("jizhi|rende|zhiheng") then return null_card end
						else
							for _, enemy in ipairs(self.enemies) do
								if snatch_num > 0 and to:distanceTo(enemy) == 1 and
									(self:willSkipPlayPhase(enemy, true) or self:willSkipDrawPhase(enemy, true)) then
									return null_card
								elseif analeptic_num > 0 and (enemy:hasWeapon("Axe") or getCardsNum("Axe", enemy, self.player) > 0) then
									return null_card
								elseif crossbow_num > 0 and getCardsNum("Slash", enemy, self.player) >= 3 then
									local slash = sgs.cloneCard("slash")
									for _, friend in ipairs(self.friends) do
										if enemy:distanceTo(friend) == 1 and self:slashIsEffective(slash, friend, enemy) then
											return null_card
										end
									end
								end
							end
						end
					end
				end
			end
		elseif trick:isKindOf("GodSalvation") then
			if self:isEnemy(to) and self:evaluateKingdom(to) ~= "unknown" and self:isWeak(to) then return null_card end
		end
	else
		if from and from:objectName() == self.player:objectName() then return end--不使自己的锦囊生效？

		if (trick:isKindOf("FireAttack") or trick:isKindOf("Duel")) and self:cantbeHurt(to, from) then
			if from and self:isEnemy(from) then return null_card end
		end
		--[[看不懂原版这一段，来源对自己使用锦囊，火攻自己样才能不打无懈？
		if from and from:objectName() == to:objectName() then
			if self:isFriend(from) then return null_card else return end
		end
		--]]
		if trick:isKindOf("Duel") then
			if trick:getSkillName() == "lijian" then
				if self:isEnemy(to) and (self:isWeak(to) or null_num > 1 or self:getOverflow() > 0 or not self:isWeak()) then return null_card end
				return
			end
			return from and self:isFriend(from) and not self:isFriend(to) and null_card
		elseif trick:isKindOf("GodSalvation") then
			if self:isFriend(to) and self:isWeak(to) then return null_card end
		elseif trick:isKindOf("AmazingGrace") then
			if self:isFriend(to) then return null_card end
		elseif not (trick:isKindOf("GlobalEffect") or trick:isKindOf("AOE")) then
			if from and self:isFriend(from) and not self:isFriend(to) then
				if ("snatch|dismantlement"):match(trick:objectName()) and to:isNude() then
				elseif trick:isKindOf("FireAttack") and to:isKongcheng() then
				else return null_card end
			end
		end
	end
end

function SmartAI:getCardRandomly(who, flags, disable_list)
	local cards = who:getCards(flags)
	if disable_list and #disable_list > 0 then
		for _, c in sgs.qlist(who:getCards(flags)) do
			if table.contains(disable_list, c:getEffectiveId()) then cards:removeOne(c) end
		end
	end
	if cards:isEmpty() then return end
	local r = math.random(0, cards:length() - 1)
	local card = cards:at(r)
	if who:hasArmorEffect("SilverLion") and cards:contains(who:getArmor()) then
		if self:isEnemy(who) and who:isWounded() and card == who:getArmor() then
			if r ~= (cards:length() - 1) then
				card = cards:at(r + 1)
			elseif r > 0 then
				card = cards:at(r - 1)
			end
		end
	end
	return card:getEffectiveId()
end

function SmartAI:askForCardChosen(who, flags, reason, method, disable_list)
	method = method or sgs.Card_MethodNone
	disable_list = disable_list or {}
	local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")]
	local card
	if type(cardchosen) == "function" then
		card = cardchosen(self, who, flags, method, disable_list)
		if type(card) == "number" then return card
		elseif card then return card:getEffectiveId() end
	elseif type(cardchosen) == "number" then
		sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")] = nil
		for _, acard in sgs.qlist(who:getCards(flags)) do
			if acard:getEffectiveId() == cardchosen then return cardchosen end
		end
	end

	--孙权、吴景取消装备移动判断；拆时有顺，先拆第二重要的卡未考虑；奇袭+旋风,奇袭标记了牌,旋风不拆标记的牌?(什么时候取消标记)
	local canOperate = function(card_id)--源码已经将无法method的牌放在disable_list中
		if table.contains(disable_list, card_id) then
			return false
		end
		local wujing = sgs.findPlayerByShownSkillName("fengyang")
		if wujing and wujing:inFormationRalation(who) and not self.player:isFriendWith(who)
		and self.room:getCardPlace(card_id) == sgs.Player_PlaceEquip
		and (method == sgs.Card_MethodGet or method == sgs.Card_MethodDiscard) then
			return false
		end
		if who:hasSkill("jubao") and method == sgs.Card_MethodGet
		and who:getTreasure() and who:getTreasure():getEffectiveId() == card_id then
			return false
		end
		return true
	end

	if ("snatch|dismantlement"):match(reason) then--给拆和顺用的,防止多次判断,CardUsed阶段移除flag
		local flag = "AIGlobal_SDCardChosen_" .. reason
		local to_choose
		for _, c in sgs.qlist(who:getCards(flags)) do
			if c:hasFlag(flag) then
				c:setFlags("-" .. flag)
				to_choose = c:getId()
				--Global_room:writeToConsole("AIGlobal_SDCardChosen_"..reason..":"..c:objectName())
				break
			end
		end
		if to_choose then 
			if canOperate(to_choose) then
				return to_choose
			else
				Global_room:writeToConsole("AIGlobal_SDCardChosen_"..reason.."(cantOperate):"..to_choose)
			end
		end
	end
	
	if self:isFriend(who) then
		if flags:match("j") and not (who:hasShownSkill("qiaobian") and who:getHandcardNum() > 0) then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if not canOperate(trick:getEffectiveId()) then continue end
				if trick:isKindOf("Lightning") then
					lightning = trick:getId()
				elseif trick:isKindOf("Indulgence") then
					indulgence = trick:getId()
				elseif not trick:isKindOf("Disaster") then
					supply_shortage = trick:getId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if flags:match("e") then
			if self:needToThrowArmor(who) and canOperate(who:getArmor():getEffectiveId()) then return who:getArmor():getEffectiveId() end
			if who:getArmor() and self:evaluateArmor(who:getArmor(), who) < -5 	and canOperate(who:getArmor():getEffectiveId()) then return who:getArmor():getEffectiveId() end
			if who:hasShownSkills(sgs.lose_equip_skill) and self:isWeak(who) then
				if who:getWeapon() and canOperate(who:getWeapon():getEffectiveId()) then
					return who:getWeapon():getEffectiveId()
				end
				if who:getOffensiveHorse() and canOperate(who:getOffensiveHorse():getEffectiveId()) then
					return who:getOffensiveHorse():getEffectiveId()
				end
			end
		end
		if flags:match("h") then
			if (self:needKongcheng(who) and not who:isKongcheng() and who:getHandcardNum() <= 2)
				or self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h", disable_list)
			end
			--
		end
	else
		if reason == "hengzheng" and self.player:getHp() <= 2 then
			local disable_copy = table.copyFrom(disable_list)
			local hasweapon
			local hasarmor
			local hasoffhorse
			local hasdefhorse
			for _, c in sgs.qlist(self.player:getCards("he")) do
				if c:isKindOf("Weapon") then hasweapon = true end
				if c:isKindOf("Armor") then hasarmor = true end
				if c:isKindOf("OffensiveHorse") then hasoffhorse = true end
				if c:isKindOf("DefensiveHorse") then hasdefhorse = true end
			end
			if hasweapon and who:getWeapon() then table.insert(disable_list, who:getWeapon():getEffectiveId()) end
			if hasarmor and who:getArmor() then table.insert(disable_list, who:getArmor():getEffectiveId()) end
			if hasoffhorse and who:getOffensiveHorse() then table.insert(disable_list, who:getOffensiveHorse():getEffectiveId()) end
			if hasdefhorse and who:getDefensiveHorse() then table.insert(disable_list, who:getDefensiveHorse():getEffectiveId()) end
			if #disable_list >= who:getEquips():length() + who:getHandcardNum() then
				disable_list = table.copyFrom(disable_copy)
			end
		end

		local dangerous = self:getDangerousCard(who)
		if flags:match("e") and dangerous and canOperate(dangerous) then return dangerous end
		if flags:match("e") and who:getTreasure() and (who:getPile("wooden_ox"):length() > 1 or who:hasTreasure("JadeSeal")) and canOperate(who:getTreasure():getId()) then
			return who:getTreasure():getId()
		end
		if flags:match("e") and who:getArmor() and who:getArmor():isKindOf("EightDiagram") and not self:needToThrowArmor(who) and canOperate(who:getArmor():getEffectiveId()) then
			return who:getArmor():getId()
		end
		if flags:match("e") and who:hasShownSkills("jijiu|beige|weimu|qingcheng") and not self:doNotDiscard(who, "e", false, 1, reason) then
			if who:getDefensiveHorse() and canOperate(who:getDefensiveHorse():getEffectiveId()) then
				return who:getDefensiveHorse():getEffectiveId()
			end
			if who:getArmor() and canOperate(who:getArmor():getEffectiveId()) then
				return who:getArmor():getEffectiveId()
			end
			if who:getOffensiveHorse() and (not who:hasShownSkill("jijiu") or who:getOffensiveHorse():isRed()) and canOperate(who:getOffensiveHorse():getEffectiveId()) then
				return who:getOffensiveHorse():getEffectiveId()
			end
			if who:getWeapon() and (not who:hasShownSkill("jijiu") or who:getWeapon():isRed()) and canOperate(who:getWeapon():getEffectiveId()) then
				return who:getWeapon():getEffectiveId()
			end
		end
		if flags:match("e") then
			local valuable = self:getValuableCard(who)
			if valuable and canOperate(valuable) then return valuable end
		end
		if flags:match("h") then
			if who:hasShownSkills("jijiu|qiaobian|jieyin|beige")
				and not who:isKongcheng() and who:getHandcardNum() <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h", disable_list)
			end
			if who:getHp() == 1 and not self:needKongcheng(who)
				and not who:isKongcheng() and who:getHandcardNum() <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h", disable_list)
			end
			local cards = sgs.QList2Table(who:getHandcards())
			if #cards <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				for _, cc in ipairs(cards) do
					if sgs.cardIsVisible(cc, who, self.player) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
						return self:getCardRandomly(who, "h", disable_list)
					end
				end
			end
		end

		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning
			for _, trick in sgs.qlist(tricks) do
				if not canOperate(trick:getEffectiveId()) then
					continue
				else
					if trick:isKindOf("Lightning") then
						lightning = trick:getId()
					end
				end
			end
			if self:hasWizard(self.enemies, true) and lightning then
				return lightning
			end
		end

		if flags:match("h") and not self:doNotDiscard(who, "h") then
			if (who:getHandcardNum() == 1 and sgs.getDefenseSlash(who, self) < 3 and who:getHp() <= 2) or who:hasShownSkills(sgs.cardneed_skill) then
				return self:getCardRandomly(who, "h", disable_list)
			end
		end

		if flags:match("e") and not self:doNotDiscard(who, "e") then
			if who:getTreasure() and canOperate(who:getTreasure():getEffectiveId()) then
				return who:getTreasure():getEffectiveId()
			end
			if who:getArmor() and not self:needToThrowArmor(who) and canOperate(who:getArmor():getEffectiveId()) then
				return who:getArmor():getEffectiveId()
			end
			if who:getDefensiveHorse() and canOperate(who:getDefensiveHorse():getEffectiveId()) then
				return who:getDefensiveHorse():getEffectiveId()
			end
			if who:getOffensiveHorse() and canOperate(who:getOffensiveHorse():getEffectiveId()) then
				return who:getOffensiveHorse():getEffectiveId()
			end
			if who:getWeapon() and canOperate(who:getWeapon():getEffectiveId()) then
				return who:getWeapon():getEffectiveId()
			end
		end

		if flags:match("h") then
			if (not who:isKongcheng() and who:getHandcardNum() <= 2) and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h", disable_list)
			end
		end
	end
	local cards = who:getCards(flags)

	for _, c in sgs.qlist(who:getCards(flags)) do
		if not canOperate(c:getEffectiveId()) then cards:removeOne(c) end
	end
	--明置的金money--handcard_visible--sgs.cardIsVisible(card, to, from)
	if cards:length() > 0 and not reason:match("dummy") then
		local r = math.random(1, cards:length())--The result of function askForCardChosen should be an integer!
		return cards:at(r-1):getEffectiveId()
	else
		return -1
	end
end

function SmartAI:askForCardsChosen(targets, flags, reason, min_num, max_num, disable_list)
	disable_list = disable_list or {}
	local cardchosen = sgs.ai_skill_cardschosen[string.gsub(reason, "%-", "_")]
	local card
	if type(cardchosen) == "function" then
		card = cardchosen(self, targets, flags, min_num, max_num, disable_list)
		if type(card) == "table" then return card
		elseif type(card) == "number" then 
			if card ~= -1 then return {card} end
			Global_room:writeToConsole("askForCardsChosen返回-1:"..reason)
		elseif card then return {card:getEffectiveId()} end
		Global_room:writeToConsole("askForCardsChosen返回nil:"..reason)
	end
	--部分旧AI使用ai_skill_cardchosen,例如除疠和聚宝等,暂时调用减少报错,但是最好还是创建新的ai_skill_cardschosen
	local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")]
	local method = sgs.Card_MethodNone
	--S_REASON_GOTCARD,S_REASON_GIVE
	if reason:match("snatch") then method = sgs.Card_MethodGet
	elseif reason:match("dismantlement") then method = sgs.Card_MethodDiscard end
	if type(cardchosen) == "function" then
		if type(targets) == "SPlayerList" and targets:length() == 1 then
			if min_num == 1 and max_num == 1 then--除疠,聚宝,鞬出
				card = cardchosen(self, targets:first(), flags, method, disable_list)
			end
		end
		--Global_room:writeToConsole("askForCardsChosen:card:"..type(card))
		if type(card) == "table" then return card
		elseif type(card) == "number" then 
			if card ~= -1 and self.player:objectName() ~= targets:first():objectName() then--强行调用AI
				local promptlist = {}
				table.insert(promptlist, "cardChosen")
				table.insert(promptlist, reason)
				table.insert(promptlist, tostring(card))
				table.insert(promptlist, self.player:objectName())
				table.insert(promptlist, targets:first():objectName())
				local callbacktable = sgs.ai_choicemade_filter[promptlist[1]]
				if callbacktable and type(callbacktable) == "table" then
					local callback = callbacktable[promptlist[2]]
					if type(callback) == "function" then
						callback(self, self.player, promptlist)
					end
				end
			end
			if card ~= -1 then return {card} end--鞬出等
			Global_room:writeToConsole("askForCardsChosen调用askForCardChosen返回-1:"..reason)
		elseif card then return {card:getEffectiveId()} end
		Global_room:writeToConsole("askForCardsChosen调用askForCardChosen返回nil:"..reason)
	end
	if type(targets) == "SPlayerList" and targets:length() == 1 then--无AI考虑调askForCardChosen
		if min_num == 1 and max_num == 1 then
			Global_room:writeToConsole("askForCardsChosen无AI,调用askForCardChosen:"..reason)--反馈,礼下,snatch,dismantlement
			if reason:match("fankui") then
				method = sgs.Card_MethodGet
			elseif reason:match("lixia") then
				method = sgs.Card_MethodDiscard
			end
			local card_id = self:askForCardChosen(targets:first(), flags, reason.."_None", method, disable_list)
			if card_id ~= -1 and self.player:objectName() ~= targets:first():objectName() then--强行调用AI
				local promptlist = {}
				table.insert(promptlist, "cardChosen")
				table.insert(promptlist, reason)
				table.insert(promptlist, tostring(card_id))
				table.insert(promptlist, self.player:objectName())
				table.insert(promptlist, targets:first():objectName())
				local callbacktable = sgs.ai_choicemade_filter[promptlist[1]]
				if callbacktable and type(callbacktable) == "table" then
					local callback = callbacktable[promptlist[2]]
					if type(callback) == "function" then
						callback(self, self.player, promptlist)
					end
				end
			end
			if card_id ~= -1 then return {card_id} end
		else
			Global_room:writeToConsole("askForCardsChosen无AI,调用askForCardChosen循环:"..reason)--危盟3,
			card = {}
			while #card < max_num do
				local card_id = self:askForCardChosen(targets:first(), flags, reason.."_None", method, disable_list)
				if card_id == -1 then break end
				if not table.contains(card, card_id) then table.insert(card, card_id) end
				if not table.contains(disable_list, card_id) then table.insert(disable_list, card_id) end
				if targets:first():getCards(flags):length() == #disable_list then break end--选完为止
			end
			if type(card) == "table" then return card end
		end
	end
	Global_room:writeToConsole("askForCardsChosen无AI:"..reason..":"..targets:length()..":"..min_num..":"..max_num)
	return {}
end

function sgs.ai_skill_cardask.nullfilter(self, data, pattern, target)
	if self.player:isDead() then return "." end
	local damage_nature = sgs.DamageStruct_Normal
	local effect
	if type(data) == "QVariant" or type(data) == "userdata" then
		effect = data:toSlashEffect()
		if effect and effect.slash then
			damage_nature = effect.nature
		end
	end
	if target and target:hasShownSkill("zhiman") and self.player:hasEquip() then
		if not self:isFriend(target) and not self:doNotDiscard(self.player, "e") then return end
	end
	if effect and self:hasHeavySlashDamage(target, effect.slash, self.player) then return end
	if not self:damageIsEffective(nil, damage_nature, target) then return "." end
	if effect and target and target:hasWeapon("IceSword") and self.player:getCardCount(true) > 1 then return end
	if self:needDamagedEffects(self.player, target) or self:needToLoseHp() then return "." end

	if self.player:hasSkill("tianxiang") then
		local dmgStr = {damage = 1, nature = damage_nature or sgs.DamageStruct_Normal}
		local willTianxiang = sgs.ai_skill_use["@@tianxiang"](self, dmgStr, sgs.Card_MethodDiscard)
		if willTianxiang ~= "." then return "." end
	end
end

function SmartAI:askForCard(pattern, prompt, data)
	local target, target2
	local parsedPrompt = prompt:split(":")
	local players
	if parsedPrompt[2] then
		local players = self.room:getPlayers()
		players = sgs.QList2Table(players)
		for _, player in ipairs(players) do
			if player:getGeneralName() == parsedPrompt[2] or player:objectName() == parsedPrompt[2] then target = player break end
		end
		if parsedPrompt[3] then
			for _, player in ipairs(players) do
				if player:getGeneralName() == parsedPrompt[3] or player:objectName() == parsedPrompt[3] then target2 = player break end
			end
		end
	end
	local arg, arg2 = parsedPrompt[4], parsedPrompt[5]
	--sgs.ai_skill_cardask["savage-assault-slash"],target=effect.from,return ".",return nil
	--sgs.ai_skill_cardask["slash-jink"],target=target,pattern="jink",return self:getCards("Jink")[1]
	--sgs.ai_skill_cardask["duel-slash"],return self:getCardId("Slash")
	--self:getCardId("Slash")(sgs.ai_cardsview_priority.aocai,return "@AocaiCard=.&aocai:slash",askForCard,sgs.ai_skill_cardask["@aocai-view"])
	local callback = sgs.ai_skill_cardask[parsedPrompt[1]]
	if type(callback) == "function" then
		local ret = callback(self, data, pattern, target, target2, arg, arg2)
		if ret then return ret end
	end
	
	if string.find(prompt,"@") then
		--local patterns = prompt:split(":")
		Global_room:writeToConsole("askForCard特殊技能:"..prompt)
	end
	
	if data and type(data) == "number" then return end
	local card
	--sgs.ai_skill_cardask["savage-assault-slash"],target=effect.from,return ".",return nil
	if pattern == "slash" then
		card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Slash") or "."
		if card == "." then sgs.card_lack[self.player:objectName()]["Slash"] = 1 end
	elseif pattern == "jink" then
		card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Jink") or "."
		if card == "." then sgs.card_lack[self.player:objectName()]["Jink"] = 1 end
	end
	if not card then
		Global_room:writeToConsole("askForCard无可用牌:"..pattern)
	end
	return card
end

function SmartAI:askForUseCard(pattern, prompt, method)
	local use_func = sgs.ai_skill_use[pattern]
	if use_func then
		return use_func(self, prompt, method) or "."
	elseif not string.find(pattern,"@@") then
		--if string.find(pattern,"%d") then--string.find(pattern,"#") or string.find(pattern,"|")
		local cards = sgs.QList2Table(self.player:getHandcards())
		--木牛等
		for _, id in sgs.qlist(self.player:getHandPile()) do
			table.insert(cards,sgs.Sanguosha:getCard(id))
		end
		local to_choose = {}
		for _,card in ipairs(cards)do
			if sgs.Sanguosha:matchExpPattern(pattern,self.player,card) and card:isAvailable(self.player) then
				local dummy_use = {isDummy = true}
				if not card:targetFixed() then dummy_use.to = sgs.SPlayerList() end
				self:useCardByClassName(card,dummy_use)
				if dummy_use.card then
					table.insert(to_choose,card)
				end
			end
		end
		if #to_choose >= 1 then
			self:sortByUseValue(to_choose)
			local c = to_choose[1]
			local dummy_use = {isDummy = true}
			if not c:targetFixed() then dummy_use.to = sgs.SPlayerList() end
			self:useCardByClassName(c,dummy_use)
			if dummy_use.card == nil then return "." end
			local str = c:toString()
			if not c:targetFixed() then
				local target_objectname = {}
				for _, p in sgs.qlist(dummy_use.to) do
					table.insert(target_objectname, p:objectName())
				end
				if #target_objectname > 0 then
					str = str .. "->" .. table.concat(target_objectname, "+")
				else return "." end
			end
			return str
		end
		if string.find(prompt,"@") then
			--local patterns = prompt:split(":")
			Global_room:writeToConsole("askForUseCard特殊用牌技能:"..prompt)
		else
			Global_room:writeToConsole("askForUseCard无可用牌:"..pattern)
		end
		return "."
	else
		Global_room:writeToConsole("askForUseCard无ai_skill_use:"..pattern)
		Global_room:writeToConsole("askForUseCard无ai_skill_use:"..prompt)
		return "."
	end
end

function SmartAI:askForAG(card_ids, refusable, reason)
	local cardchosen = sgs.ai_skill_askforag[string.gsub(reason, "%-", "_")]
	if type(cardchosen) == "function" then
		local card_id = cardchosen(self, card_ids)
		if card_id then return card_id end
	end

	local ids = card_ids
	local cards = {}
	for _, id in ipairs(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local have_one_Peach = false
	local NotOnlyOne_Peach = false
	for _, card in ipairs(cards) do--不抢队友的唯一桃
		if card:isKindOf("Peach") then
			if not have_one_Peach then
				have_one_Peach = card:getEffectiveId()
			else
				NotOnlyOne_Peach = true
			end
			if NotOnlyOne_Peach then break end
		end
	end
	local NP = self.player:getNextAlive()
	if NP and self:isFriend(NP) and self:isWeak() 
		and (have_one_Peach and not NotOnlyOne_Peach)
		and ((NP:hasShownSkill("keji") or (NP:hasShownSkill("qiaobian") and not NP:isKongcheng())) 
		or not NP:containsTrick("indulgence")) then
	else
		if have_one_Peach then 
			return have_one_Peach
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Indulgence") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
		if card:isKindOf("AOE") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
	end
	self:sortByCardNeed(cards, true)

	return cards[1]:getEffectiveId()
end

function SmartAI:askForCardShow(requestor, reason)
	local func = sgs.ai_cardshow[reason]
	if func then
		return func(self, requestor)
	else
		return self.player:getRandomHandCard()
	end
end

function sgs.ai_cardneed.bignumber(to, card, self)
	if not self:willSkipPlayPhase(to) and self:getUseValue(card) < 6 then
		return card:getNumber() > 10
	end
end

function sgs.ai_cardneed.equip(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:getTypeId() == sgs.Card_TypeEquip
	end
end

function sgs.ai_cardneed.weapon(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:isKindOf("Weapon")
	end
end

function SmartAI:getEnemyNumBySeat(from, to, target, include_neutral)
	target = target or from
	local players = sgs.QList2Table(self.room:getAllPlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local enemynum = 0
	for _, p in ipairs(players) do
		if  (self:isEnemy(target, p) or (include_neutral and not self:isFriend(target, p))) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
			enemynum = enemynum + 1
		end
	end
	return enemynum
end

function SmartAI:getFriendNumBySeat(from, to, target)
	target = target or from
	local players = sgs.QList2Table(self.room:getAllPlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local friendnum = 0
	for _, p in ipairs(players) do
		if self:isFriend(target, p) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
			friendnum = friendnum + 1
		end
	end
	return friendnum
end

function SmartAI:hasHeavySlashDamage(from, slash, to, getValue)
	from = from or self.room:getCurrent()
	if not slash or not slash:isKindOf("Slash") then
		slash = self.player:objectName() == from:objectName() and self:getCard("Slash") or sgs.cloneCard("slash")
	end
	to = to or self.player
	if not from or not to then self.room:writeToConsole(debug.traceback()) return false end
	local jiaren_zidan = sgs.findPlayerByShownSkillName("jgchiying")
	local jgchiying = (jiaren_zidan and jiaren_zidan:isFriendWith(to))
	if (to:hasArmorEffect("SilverLion") and not IgnoreArmor(from, to)) or jgchiying 
		or (to:hasShownSkill("gongqing") and from:getAttackRange(true) < 3)	or (to:hasShownSkill("qiuan") and to:getPile("letter"):length() <= 0) then
		if getValue then return 1
		else return false end
	end
	local dmg = 1
	local fireSlash = slash and (slash:isKindOf("FireSlash") or slash:objectName() == "slash" and from:hasWeapon("Fan"))
	local thunderSlash = slash and slash:isKindOf("ThunderSlash")

	if (slash and slash:hasFlag("drank")) then
		dmg = dmg + 1
	elseif from:getMark("drank") > 0 then
		dmg = dmg + from:getMark("drank")
	end
	if from:getMark("##luoyi") > 0 then dmg = dmg + 1 end
	if to:hasShownSkill("gongqing") and from:getAttackRange(true) > 3 then
		dmg = dmg + 1
	end
	if from:hasShownSkill("congjian") and from:getPhase() == sgs.Player_NotActive then
		dmg = dmg + 1
	end
	if to:hasShownSkill("congjian") and to:getPhase() == sgs.Player_NotActive then
		dmg = dmg + 1
	end
--[[
	if from:hasShownSkill("fengshix") then
		local data = sgs.QVariant()--技能触发需要构造data，注意self写法，invoke里缺信息，换写法
		data:setValue(to)
		if sgs.ai_skill_invoke.fengshix(sgs.ais[from:objectName()], data) then
			dmg = dmg + 1
		end
	end
]]
	if to:hasShownSkill("fengshix") or from:hasShownSkill("fengshix") then
		if from:getHandcardNum() > to:getHandcardNum() and (from:getHandcardNum() > 3 or self:isWeak(to)) then
			dmg = dmg + 1
		end
	end
	if from:hasShownSkill("suzhi") and from:getPhase() == sgs.Player_Play and from:getMark("#suzhi") < 3 then
		dmg = dmg + 1
	end
	if from:hasWeapon("GudingBlade") and slash and to:isKongcheng() then dmg = dmg + 1 end
	if to:getMark("@gale") > 0 and fireSlash then dmg = dmg + 1 end
	
	if to:hasArmorEffect("Vine") and not IgnoreArmor(from, to) and fireSlash then
		dmg = dmg + 1
	end
	
	if to:hasArmorEffect("Breastplate") and (dmg > to:getHp() or (to:getHp() > 1 and dmg == to:getHp())) then
		if getValue then return 1
		else return false end
	end
	
	if getValue then return dmg end
	return (dmg > 1)
end

function SmartAI:needKongcheng(player, keep, hengzheng_invoker)
	player = player or self.player
	if keep then return player:isKongcheng() and player:hasShownSkill("kongcheng") end
	if not self:hasLoseHandcardEffective(player) and not player:isKongcheng() then return true end
	if player:hasShownSkill("hengzheng") and sgs.ai_skill_invoke.hengzheng(sgs.ais[player:objectName()])
		and not player:getHp() == 1 and player:getHandcardNum() <= 1 then return true end
	if (player:getPhase() ~= sgs.Player_NotActive and player:hasShownSkills(sgs.Active_cardneed_skill))
	or (player:getPhase() == sgs.Player_NotActive and player:hasShownSkills(sgs.notActive_cardneed_skill)) then
		if player:getHandcardNum() > 1 then
			return false
		end
	end
	if not hengzheng_invoker then
		if player:hasShownSkill("hengzheng") and not player:getHp() == 1 then
			return self:SimpleGuixinInvoke(player)
		end
	end
	if player:hasSkills("jieming|zhiyu") and player:getPhase() == sgs.Player_Play and player:getHp() > 2 then
		return true--荀彧和荀攸回合内？和高体力
	end
	local zhoutai = sgs.findPlayerByShownSkillName("fenji")
	local fenji = (zhoutai and player:isFriendWith(zhoutai) and not self:isWeak(zhoutai))
	if fenji and player:getPhase() >= sgs.Player_Play and player:getPhase() < sgs.Player_Finish and player:getHandcardNum() <= 1 then
		return true
	end
	return player:hasShownSkills(sgs.need_kongcheng)
end

function SmartAI:SimpleGuixinInvoke(player)
	local friend, others = 0, 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if self:isFriend(p, player) then
			if p:getJudgingArea():length() > 0 or self:needToThrowArmor(p) then
				friend = friend + 1
			end
		else
			if not p:isNude() then
				others = others + 1
			end
		end
	end
	return others - friend > 2
end

function SmartAI:getLeastHandcardNum(player)
	player = player or self.player
	local least = 0
	local jwfy = sgs.findPlayerByShownSkillName("shoucheng")
	if least < 1 and jwfy and player:isFriendWith(jwfy) and player:getPhase() == sgs.Player_NotActive then
		least = 1
	end
	return least
end

function SmartAI:hasLoseHandcardEffective(player)
	player = player or self.player
	return player:getHandcardNum() > self:getLeastHandcardNum(player)
end

function SmartAI:getCardNeedPlayer(cards, friends_table, skillname)
	cards = cards or sgs.QList2Table(self.player:getHandcards())

	local cardtogivespecial = {}
	local keptslash = 0
	local friends = {}
	local cmpByAction = function(a,b)
		return a:getRoom():getFront(a, b):objectName() == a:objectName()
	end

	local cmpByNumber = function(a,b)
		return a:getNumber() > b:getNumber()
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and (self:needKongcheng(AssistTarget, true) or self:willSkipPlayPhase(AssistTarget) or AssistTarget:getHandcardNum() > 10) then
		AssistTarget = nil
	end

	local found
	local xunyu, huatuo
	local friends_table = friends_table or self.friends_noself
	for i = 1, #friends_table do
		local player = friends_table[i]
		local exclude = self:needKongcheng(player) or self:willSkipPlayPhase(player)
		if player:hasShownSkills("keji|qiaobian|shensu") or player:getHp() - player:getHandcardNum() >= 3
			or (player:isLord() and self:isWeak(player) and self:getEnemyNumBySeat(self.player, player) >= 1) then
			exclude = false
		end
		if self:objectiveLevel(player) <= -2 and not exclude then
			if AssistTarget and AssistTarget:objectName() == player:objectName() then AssistTarget = player end
			if player:hasShownSkill("jieming") then xunyu = player end
			if player:hasShownSkill("jijiu") then huatuo = player end
			table.insert(friends, player)
		end
	end
	if not found then AssistTarget = nil end

	if xunyu and huatuo and #cardtogivespecial == 0 and self.player:hasSkill("rende") and self.player:getPhase() == sgs.Player_Play then
		local no_distance = self.slash_distance_limit
		local redcardnum = 0
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, self.player) then
				if self.player:canSlash(xunyu, nil, not no_distance) and self:slashIsEffective(acard, xunyu) then
					keptslash = keptslash + 1
				end
				if keptslash > 0 then
					table.insert(cardtogivespecial, acard)
				end
			elseif isCard("Duel", acard, self.player) then
				table.insert(cardtogivespecial, acard)
			end
		end
		for _, hcard in ipairs(cardtogivespecial) do
			if hcard:isRed() then redcardnum = redcardnum + 1 end
		end
		if self.player:getHandcardNum() > #cardtogivespecial and redcardnum > 0 then
			for _, hcard in ipairs(cardtogivespecial) do
				if hcard:isRed() then return hcard, huatuo end
				return hcard, xunyu
			end
		end
	end

	local cardtogive = {}
	local keptjink = 0
	for _, acard in ipairs(cards) do
		if isCard("Jink", acard, self.player) and keptjink < 1 and not self.player:hasSkill("kongcheng") then
			keptjink = keptjink + 1
		elseif skillname ~= "WoodenOx" or not acard:isKindOf("Treasure") then
			table.insert(cardtogive, acard)
		end
	end

	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if self:isWeak(friend) and friend:getHandcardNum() < 3  then
			for _, hcard in ipairs(cards) do
				if isCard("Peach", hcard, friend) or (isCard("Jink", hcard, friend) and self:getEnemyNumBySeat(self.player,friend) > 0) or isCard("Analeptic", hcard, friend) then
					return hcard, friend
				end
			end
		end
	end

	if (skillname == "rende" and self.player:hasSkill("rende") and self.player:isWounded() and self.player:getMark("rende") < 2) and not self.player:hasSkill("kongcheng") then
		if (self.player:getHandcardNum() < 2 and self.player:getMark("rende") == 0 and self:getOverflow() <= 0) then return end
	end

	for _, friend in ipairs(friends) do
		if friend:getHp() <= 2 and friend:faceUp() then
			for _, hcard in ipairs(cards) do
				if (hcard:isKindOf("Armor") and not friend:getArmor() and not friend:hasShownSkills("bazhen|jgyizhong"))
					or (hcard:isKindOf("DefensiveHorse") and not friend:getDefensiveHorse()) then
					return hcard, friend
				end
			end
		end
	end

	self:sortByUseValue(cards, true)
	for _, friend in ipairs(friends) do
		if friend:hasShownSkills("jijiu|jieyin") and friend:getHandcardNum() < 4 then
			for _, hcard in ipairs(cards) do
				if (hcard:isRed() and friend:hasShownSkill("jijiu")) or friend:hasShownSkill("jieyin") then
					return hcard, friend
				end
			end
		end
	end

	for _, friend in ipairs(friends) do
		if friend:hasShownSkills("jizhi")  then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("TrickCard") then
					return hcard, friend
				end
			end
		end
	end

	for _, friend in ipairs(friends) do
		if friend:hasShownSkills("paoxiao") then--和后边sgs.ai_cardneed不是重复了？
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Slash") then
					return hcard, friend
				end
			end
		end
	end

	for _, friend in ipairs(friends) do
		if friend:hasShownSkills("jili")  then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Weapon") then
					return hcard, friend
				end
			end
		end
	end

	--Crossbow
	for _, friend in ipairs(friends) do
		if friend:hasShownSkills("longdan|wusheng|kuanggu|keji") and not self:hasCrossbowEffect(friend) and friend:getHandcardNum() >= 2 then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Crossbow") then
					return hcard, friend
				end
			end
		end
	end

	for _, friend in ipairs(friends) do
		if getKnownCard(friend, self.player, "Crossbow") > 0 or self:hasCrossbowEffect(friend) then
			for _, p in ipairs(self.enemies) do
				if sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= 1 then
					for _, hcard in ipairs(cards) do
						if isCard("Slash", hcard, friend) then
							return hcard, friend
						end
					end
				end
			end
		end
	end

	table.sort(friends, cmpByAction)

	for _, friend in ipairs(friends) do
		if friend:faceUp() then
			local can_slash = false
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= friend:getAttackRange() then
					can_slash = true
					break
				end
			end
			local flag = string.format("weapon_done_%s_%s",self.player:objectName(),friend:objectName())
			if not can_slash then
				for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
					if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) > friend:getAttackRange() then
						for _, hcard in ipairs(cardtogive) do
							if hcard:isKindOf("Weapon") and friend:distanceTo(p) <= friend:getAttackRange() + (sgs.weapon_range[hcard:getClassName()] or 0)
									and not friend:getWeapon() and not friend:hasFlag(flag) then
								self.room:setPlayerFlag(friend, flag)
								return hcard, friend
							end
							if hcard:isKindOf("OffensiveHorse") and friend:distanceTo(p) <= friend:getAttackRange() + 1
									and not friend:getOffensiveHorse() and not friend:hasFlag(flag) then
								self.room:setPlayerFlag(friend, flag)
								return hcard, friend
							end
						end
					end
				end
			end

		end
	end

	table.sort(cardtogive, cmpByNumber)

	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend, true) and friend:faceUp() then
			for _, hcard in ipairs(cardtogive) do
				for _, askill in sgs.qlist(friend:getVisibleSkillList(true)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback) == "function" and callback(friend, hcard, self) then
						return hcard, friend
					end
				end
			end
		end
	end

	if skillname ~= "WoodenOx" then
		self:sort(self.enemies, "defense")
		if #self.enemies > 0 and self.enemies[1]:isKongcheng() and self.enemies[1]:hasShownSkill("kongcheng") then
			for _, acard in ipairs(cardtogive) do
				if acard:isKindOf("Lightning") or acard:isKindOf("Collateral") or (acard:isKindOf("Slash") and self.player:getPhase() == sgs.Player_Play)
					or acard:isKindOf("OffensiveHorse") or acard:isKindOf("Weapon") or acard:isKindOf("AmazingGrace") then
					return acard, self.enemies[1]
				end
			end
		end
	end

	if AssistTarget then
		for _, hcard in ipairs(cardtogive) do
			return hcard, AssistTarget
		end
	end

	self:sort(friends, "defense")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) and not self:willSkipPlayPhase(friend) and friend:hasShownSkills(sgs.priority_skill) then
				if (self:getOverflow() > 0 or self.player:getHandcardNum() > 3) and friend:getHandcardNum() <= 3 then
					return hcard, friend
				end
			end
		end
	end

	local shoulduse = skillname == "rende" and self.player:isWounded() and self.player:hasSkill("rende") and self.player:getMark("rende") < 2

	if #cardtogive == 0 and shoulduse then cardtogive = cards end

	self:sort(friends, "handcard")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) then
				if friend:getHandcardNum() <= 3 and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse) then
					return hcard, friend
				end
			end
		end
	end


	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) or #friends == 1 then
				if self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse then
					return hcard, friend
				end
			end
		end
	end

	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends_table) do
			if (not self:needKongcheng(friend, true) or #friends_table == 1) and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse) then
				return hcard, friend
			end
		end
	end

end

function SmartAI:askForYiji(card_ids, reason)
	if reason then
		local callback = sgs.ai_skill_askforyiji[string.gsub(reason,"%-","_")]
		if type(callback) == "function" then
			local target, cardid = callback(self, card_ids)
			if target and cardid then return target, cardid end
		end
	end
	return nil, -1
end

function SmartAI:askForPindian(requestor, reason)
	local passive = { "lieren" }
	if self.player:objectName() == requestor:objectName() and not table.contains(passive, reason) then
		if self[reason .. "_card"] then
			return sgs.Sanguosha:getCard(self[reason .. "_card"])
		else
			self.room:writeToConsole("Pindian card for " .. reason .. " not found!!")
			return self:getMaxNumberCard(self.player):getId()
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local compare_func = function(a, b)
		return a:getNumber() < b:getNumber()
	end
	table.sort(cards, compare_func)
	local maxcard, mincard, minusecard
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then mincard = card break end
	end
	for _, card in ipairs(sgs.reverse(cards)) do
		if self:getUseValue(card) < 6 then maxcard = card break end
	end
	self:sortByUseValue(cards, true)
	minusecard = cards[1]
	maxcard = maxcard or minusecard
	mincard = mincard or minusecard

	local sameclass, c1 = true, nil
	for _, c2 in ipairs(cards) do
		if not c1 then c1 = c2
		elseif c1:getClassName() ~= c2:getClassName() then sameclass = false end
	end
	if sameclass then
		if self:isFriend(requestor) then return self:getMinNumberCard()
		else return self:getMaxNumberCard() end
	end

	local callback = sgs.ai_skill_pindian[reason]
	if type(callback) == "function" then
		local ret = callback(minusecard, self, requestor, maxcard, mincard)
		if ret then return ret end
	end
	if self:isFriend(requestor) then return mincard else return maxcard end
end

sgs.ai_skill_playerchosen.damage = function(self, targets)
	local targetlist = {}
	for _, p in sgs.qlist(targets) do
		if self:damageIsEffective(p, nil, self.player) then
			table.insert(targetlist, p)
		end
	end
	if #targetlist == 0 then
		for _, p in sgs.qlist(targets) do
			if not self:isFriend(p) then return p end
		end
		for _, p in sgs.qlist(targets) do
			if not self:isFriendWith(p) then return p end
		end
	end
	self:sort(targetlist, "hp")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) then return target end
	end
	for _, target in ipairs(targetlist) do--没有敌人选不是队友的
		if not self:isFriend(target) then return target end
	end
	for _, target in ipairs(targetlist) do
		if not self:isFriendWith(target) then return target end
	end
	return targets:first()--万一都是队友。。
end

function SmartAI:askForPlayersChosen(targets, reason, max_num, min_num)
	local playerchosen = sgs.ai_skill_playerchosen[string.gsub(reason, "%-", "_")]
	local returns = {}
	if type(playerchosen) == "function" then
		local result = playerchosen(self, targets, max_num, min_num)
		if type(result) == "ServerPlayer" then
			return {result}
		elseif type(result) == "ClientPlayer" then
			for _, p in sgs.qlist(self.room:getAllPlayers()) do
				if p:objectName() == result:objectName() then
					return {p}
				end
			end
		elseif type(result) == "table" then
			return result
		else
			return {}
		end
	end
	if string.find(reason,"command") then
		Global_room:writeToConsole("军令选择随机目标:"..reason)
		--未写AI的军令2
	else
		Global_room:writeToConsole("选择随机目标:"..reason)
		--未写AI的PlayersChosen
	end
	local copy = sgs.QList2Table(targets)
	while (#returns < min_num) do
		local r = math.random(1, #copy)
		table.insert(returns,copy[r])
		table.remove(copy,r)
	end
	return returns
end

function SmartAI:ableToSave(saver, dying)
	local current = self.room:getCurrent()
	if current and current:getPhase() ~= sgs.Player_NotActive and current:hasShownSkill("wansha")
		and current:objectName() ~= saver:objectName() and current:objectName() ~= dying:objectName() then
		return false
	end
	local peach = sgs.cloneCard("peach", sgs.Card_NoSuitRed, 0)
	if saver:isRemoved() then return false end
	if saver:isCardLimited(peach, sgs.Card_MethodUse, true) then return false end
	return true
end

function SmartAI:willUsePeachTo(dying)
	if not dying:canRecover() then return "." end--禁止回复
	local card_str
	local forbid = sgs.cloneCard("peach")
	if self.player:isLocked(forbid) or dying:isLocked(forbid) then return "." end
	if self.player:objectName() == dying:objectName() then
		local analeptic = sgs.cloneCard("analeptic")
		if not self.player:isLocked(analeptic) and self:getCardId("Analeptic") then return self:getCardId("Analeptic") end
		if self:getCardId("Peach") then return self:getCardId("Peach") end
	end

	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if type(damage) == "DamageStruct" and damage.to and damage.to:objectName() == dying:objectName() and damage.from
		and (damage.from:objectName() == self.player:objectName()
			or self.player:isFriendWith(damage.from)
			or self:evaluateKingdom(damage.from) == self.player:getKingdom())
		and (self.player:getKingdom() ~= sgs.ai_explicit[damage.to:objectName()] or self.role == "careerist") then
		if self.player:isFriendWith(damage.from) and self.player:isFriendWith(damage.to) then
			--军令1,驱虎
		else
			return "."
		end
	end
	if self:isFriend(dying) then
		if not self.player:isFriendWith(dying) and self:isWeak() then return "." end
		--考虑自己的ai_NeedPeach(自己被连环传导时放弃救队友),此时需要考虑涅槃等，即救队友然后自己涅槃
		if self:getCardsNum({"Peach", "Analeptic"}) <= sgs.ai_NeedPeach[self.player:objectName()]
			and not (HasBuquEffect(self.player) or HasNiepanEffect(self.player)) then return "." end
		if math.ceil(self:getAllPeachNum()) < 1 - dying:getHp() then return "." end

		if dying:objectName() ~= self.player:objectName() then
			local possible_peach = 0
			local possible_friend = 0
			for _, friend in ipairs(self.friends_noself) do
				if (self:getKnownNum(friend) == friend:getHandcardNum() and getCardsNum("Peach", friend, self.player) == 0)
					or (self:playerGetRound(friend) < self:playerGetRound(self.player)) then
				elseif sgs.card_lack[friend:objectName()]["Peach"] == 1 then
				elseif not self:ableToSave(friend, dying) then
				elseif friend:getHandcardNum() > 0 or getCardsNum("Peach", friend, self.player) > 0 then
					possible_friend = possible_friend + 1
					possible_peach = possible_peach + getCardsNum("Peach", friend, self.player)
				end
			end
			if possible_friend == 0 and self:getCardsNum("Peach") < 1 - dying:getHp() then
				return "."
			end
			local num = dying:getMark("@bless")
			if num > 0 and num + self:getCardsNum("Peach") + possible_peach <= dying:getMaxHp() then
				return "."
			end
		end

		if HasBuquEffect(dying) then return "." end
		if dying:hasFlag("Kurou_toDie") and (not dying:getWeapon() or dying:getWeapon():objectName() ~= "Crossbow") then return "." end

		if (self.player:objectName() == dying:objectName()) then
			card_str = self:getCardId("Analeptic")
			if not card_str then card_str = self:getCardId("Peach") end
		elseif self:doNotSave(dying) then return "."
		else
			card_str = self:getCardId("Peach")
		end
	end
	if not card_str then return nil end
	return card_str
end

function SmartAI:askForSinglePeach(dying)
	local card_str = self:willUsePeachTo(dying)
	if card_str and card_str ~= "." and dying:objectName() ~= self.player:objectName() then
		sgs.updateIntention(self.player, dying, -80)
	end
	return card_str or "."
end

function SmartAI:getOverflow(player, getMax)
	player = player or self.player
	local MaxCards = player:getMaxCards()
	if player:hasShownSkills("qiaobian|qiaobian_egf") and not player:hasFlag("AI_ConsideringQiaobianSkipDiscard") then
		MaxCards = math.max(self.player:getHandcardNum() - 1, MaxCards)
		player:setFlags("-AI_ConsideringQiaobianSkipDiscard")
	end
	if getMax then return MaxCards end
	return player:getHandcardNum() - MaxCards
end

function SmartAI:isWeak(player)
	player = player or self.player
	if player:isRemoved() then return false end
	if HasBuquEffect(player) then return false end
	if HasNiepanEffect(player) then return false end
	if player:hasShownSkill("kongcheng") and player:isKongcheng() and player:getHp() >= 2 then return false end
	if (player:getHp() <= 2 and player:getHandcardNum() <= 2) or player:getHp() <= 1 then return true end
	return false
end

function SmartAI:useCardByClassName(card, use)
	if not card then Global_room:writeToConsole(debug.traceback()) return end
	local class_name = card:getClassName()
	local use_func = self["useCard" .. class_name]

	if use_func then
		use_func(self, card, use)
	end
end

function SmartAI:hasWizard(players, onlyharm)
	local skill
	if onlyharm then skill = sgs.wizard_harm_skill else skill = sgs.wizard_skill end
	for _, player in ipairs(players) do
		if player:hasShownSkills(skill) then
			return true
		end
	end
end

function SmartAI:canRetrial(player, to_retrial, reason)
	player = player or self.player
	to_retrial = to_retrial or self.player
	if player:hasShownSkill("guidao") then
		local blackequipnum = 0
		for _, equip in sgs.qlist(player:getEquips()) do
			if equip:isBlack() then blackequipnum = blackequipnum + 1 end
		end
		if blackequipnum + player:getHandcardNum() > 0 then return true end
	end
	if player:hasShownSkill("guicai") and not player:isNude() then return true end
	if player:hasShownSkill("huanshi") and player:isFriendWith(to_retrial) and not player:isNude() then return true end
	if player:hasShownSkill("midao") and not player:getPile("rice"):isEmpty() then return true end
	--if player:hasShownSkill("jilve") and player:getHandcardNum() > 0 and player:getMark("@bear") > 0 then return true end
	return false
end

function SmartAI:getFinalRetrial(player, reason)
	local maxfriendseat = -1
	local maxenemyseat = -1
	local tmpfriend
	local tmpenemy
	local wizardf, wizarde
	player = player or self.room:getCurrent()
	for _, aplayer in ipairs(self.friends) do
		if aplayer:hasShownSkills(sgs.wizard_harm_skill.."|huanshi") and self:canRetrial(aplayer, player, reason) then
			tmpfriend = (aplayer:getSeat() - player:getSeat()) % (Global_room:alivePlayerCount())
			if tmpfriend > maxfriendseat then
				maxfriendseat = tmpfriend
				wizardf = aplayer
			end
		end
	end
	for _, aplayer in ipairs(self.enemies) do
		if aplayer:hasShownSkills(sgs.wizard_harm_skill.."|huanshi") and self:canRetrial(aplayer, player, reason) then
			tmpenemy = (aplayer:getSeat() - player:getSeat()) % (Global_room:alivePlayerCount())
			if tmpenemy > maxenemyseat then
				maxenemyseat = tmpenemy
				wizarde = aplayer
			end
		end
	end
	if maxfriendseat == -1 and maxenemyseat == -1 then return 0, nil
	elseif maxfriendseat > maxenemyseat then return 1, wizardf
	else return 2, wizarde end
end

--- Determine that the current judge is worthy retrial
-- @param judge The JudgeStruct that contains the judge information
-- @return True if it is needed to retrial
function SmartAI:needRetrial(judge)
	local reason = judge.reason
	local who = judge.who
	local can_tiandu = false
	if who:hasShownSkill("tiandu") then
		can_tiandu = true
	elseif who:hasShownSkill("zhuwei") and (judge.card:isKindOf("Slash") or judge.card:isKindOf("AOE") or judge.card:isKindOf("Duel")
		or judge.card:isKindOf("FireAttack") or judge.card:isKindOf("BurningCamps") or judge.card:isKindOf("Drowning"))then
		can_tiandu = true
	end
	if reason == "lightning" then
		if who:hasShownSkill("hongyan") then return false end

		if who:hasArmorEffect("SilverLion") and who:getHp() > 1 then return false end

		if who:hasArmorEffect("PeaceSpell") then return false end
		if who:hasShownSkill("yujia") then return false end

		if self:isFriend(who) then
			if who:isChained() and self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return false end
		else
			if who:isChained() and not self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return judge:isGood() end
		end
	elseif reason == "indulgence" then
		if who:isSkipped(sgs.Player_Draw) and who:isKongcheng() then
			if (who:hasShownSkill("kurou") and who:getHp() >= 3 and not who:isNude())
			or (who:getMark("@firstshow") + who:getMark("@careerist") > 0) then
				if self:isFriend(who) then
					return not judge:isGood()
				else
					return judge:isGood()
				end
			end
			return false
		end
		if self:isFriend(who) then
			local drawcardnum = self:imitateDrawNCards(who, who:getVisibleSkillList(true))
			if who:getHp() - who:getHandcardNum() >= drawcardnum and self:getOverflow() < 0 then return false end
			if who:hasShownSkill("tuxi") and who:getHp() > 2 and self:getOverflow() < 0 then return false end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	elseif reason == "supply_shortage" then
		if self:isFriend(who) then
			if who:hasShownSkills("guidao|tiandu|zhuwei") and self.player:objectName() ~= who:objectName() then
				if self.player:hasSkill("guidao") then
					return not judge:isGood()
				elseif self.player:getHandcardNum() < 3 then
					return false
				end
			end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	elseif reason == "luoshen" then
		local luoshen_list = who:getTag("luoshen"):toList() or sgs.VariantList()
		if self:isFriend(who) then
			local black_num = self:getSuitNum("black", false, self.player)
			local zhuwei_num = who:getMark("#ZhuweiBuff")
			if self.player:objectName() == who:objectName() then
				--[[
				if self.player:hasSkill("jilve") and self.player:getMark("@bear") < 3 
					and self.player:getCardCount(true):length() + luoshen_list:length() >= self.player:getMaxHp() then return false end
				--]]
				return not judge:isGood()
			else
				if who:getHandcardNum() + luoshen_list:length() - zhuwei_num > 10 then return false end
				if self:willSkipPlayPhase(who) then return false end
				if self:hasCrossbowEffect(who) or getKnownCard(who, self.player, "Crossbow", false) > 0 then return not judge:isGood() end
				if getKnownCard(who, self.player, "ThreatenEmperor", false) > 0 and who:isBigKingdomPlayer() then return false end
				if self.player:hasSkill("luoshen") and black_num <= 3 then return false end
				--if self.player:hasSkill("jilve") and self.player:getMark("@bear") <= 5 then return false end
				if luoshen_list:length() > 0 and self:getOverflow(who) + luoshen_list:length() > 1 and (self:getOverflow() <= 0 or self.player:faceUp())
					and who:getHandcardNum() + luoshen_list:length() > self.player:getHandcardNum() then return false end
			end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	elseif reason == "tuntian" then
		if self:isFriend(who) then
			if who:getPile("field"):length() > self.room:getAlivePlayers():length() then return false end
			if self.player:objectName() == who:objectName() and self:isWeak() and self.player:getHandcardNum() <= 3 then return false end
			return not judge:isGood() and not who:hasShownSkills("tiandu|zhuwei")
		else
			return judge:isGood()
		end
	elseif reason == "beige" then
		local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
		local from = nil
		if (damage.from and damage.from:isAlive()) then from = damage.from end
		--判红桃收益不大时
		local without_recover = ((not who:hasShownSkills(sgs.masochism_skill) and not self:isWeak(who) and (who:getLostHp() <= 1 or self:getOverflow(who) < 0)) or not who:canRecover())
		local tiandu_peach = (who:hasShownSkills("tiandu|zhuwei") and isCard("Peach", judge.card, who))
		if from then
			--判梅花弃牌不亏时
			local need_dis = (self:getOverflow(from) > 1 or self:needToThrowArmor(from) or self:doNotDiscard(from, "he", false, 2, reason))
			if self:isFriend(from) then
				--优先考虑翻面
				if judge.card:getSuit() == sgs.Card_Spade and self:toTurnOver(from, 0) then return true
				elseif judge.card:getSuit() ~= sgs.Card_Spade and not self:toTurnOver(from, 0) then return true end
				if self:isFriend(who) then
					if judge.card:isBlack() then
						return true
					elseif without_recover and judge.card:getSuit() == sgs.Card_Heart then
						return true
					end
				elseif self:isEnemy(who) then
					if need_dis and judge.card:getSuit() ~= sgs.Card_Club then return true end
					if tiandu_peach then return true end
					if not without_recover and judge.card:getSuit() ~= sgs.Card_Heart then return true end
				end
			elseif self:isEnemy(from) then
				if judge.card:getSuit() == sgs.Card_Spade and not self:toTurnOver(from, 0) then return true end
				if self:isFriend(who) then
					if need_dis and judge.card:getSuit() == sgs.Card_Club then return true end
					if without_recover and judge.card:getSuit() == sgs.Card_Heart then return true end
				elseif self:isEnemy(who) then
					if need_dis and judge.card:getSuit() == sgs.Card_Club then return true end
					if who:hasShownSkills(sgs.cardneed_skill) and judge.card:getSuit() == sgs.Card_Diamond then return true end
					if tiandu_peach then return true end
					if not without_recover and judge.card:getSuit() ~= sgs.Card_Heart then return true end
				end
			end
		else
			if self:isFriend(who) then
				if judge.card:isBlack() then
					return true
				elseif without_recover and judge.card:getSuit() == sgs.Card_Heart then
					return true
				end
			elseif self:isEnemy(who) then
				if not judge.card:isBlack() then return true end
			end
		end
	elseif reason == "leiji" and who:isChained() then
		--♥♣♦isGood
		if judge:isGood() == self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 2) then
			return true
		end
	elseif reason == "ganglie" then
		local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
		local from = nil
		if (damage.from and damage.from:isAlive()) then from = damage.from end
		if from then
			if not self:canAttack(from,who) and not (who:canDiscard(from, "he") and not self:doNotDiscard(from, "he")) then return false end
			--改判收益最明显的情况是判黑无装备可弃且手牌溢出,其次是血量危险时
			if (self:getOverflow(from) > 0 and self:doNotDiscard(from, "e")) or (self:isWeak(from) and self:canAttack(from,who)) then
				return ((judge.card:isRed() and self:isFriend(from))or(judge.card:isBlack() and self:isEnemy(from)))
			elseif not self:canAttack(from) then--其他情况,暂时只想到改无效的伤害
				return ((judge.card:isBlack() and self:isFriend(from))or(judge.card:isRed() and self:isEnemy(from)))
			end
		end
	end
	if self:isFriend(who) then
		return not judge:isGood()
	elseif self:isEnemy(who) then
		return judge:isGood()
	else
		return false
	end
end

--- Get the retrial cards with the lowest keep value
-- @param cards the table that contains all cards can use in retrial skill
-- @param judge the JudgeStruct that contains the judge information
-- @return the retrial card id or -1 if not found
function SmartAI:getRetrialCardId(cards, judge, self_card)
	if self_card == nil then self_card = true end
	local can_use = {}
	local reason = judge.reason
	local who = judge.who
	
	if self.player:getPhase() <= sgs.Player_Play and not self.player:isSkipped(sgs.Player_Play) then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end
	
	local best_use = {}
	for _, card in ipairs(cards) do
		local card_x = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
		local is_peach = self:isFriend(who) and who:hasShownSkills("tiandu|zhuwei") or isCard("Peach", card_x, self.player)
		local tiandu_peach = (who:hasShownSkills("tiandu|zhuwei") and isCard("Peach", judge.card, who))
		if who:hasShownSkill("hongyan") and card_x:getSuit() == sgs.Card_Spade then
			local str = card_x:getClassName() .. (":[%s:%s]=%d&"):format("heart", card_x:getNumber(), card_x:getEffectiveId())
			card_x = sgs.Card_Parse(str)
			assert(card_x)
		end

		if reason == "beige" then
			local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
			local from = nil
			if (damage.from and damage.from:isAlive()) then from = damage.from end
			local without_recover = ((not who:hasShownSkills(sgs.masochism_skill) and not self:isWeak(who) and (who:getLostHp() <= 1 or self:getOverflow(who) < 0)) or not who:canRecover())
			local spade_check,heart_check,club_check,diamond_check,need_retrial = true,true,true,true,false
			if judge.card:getSuit() ~= card_x:getSuit() then
				if from then
					local need_dis = (self:getOverflow(from) > 1 or self:needToThrowArmor(from) or self:doNotDiscard(from, "he", false, 2, reason))
					if self:isFriend(from) then
						if self:isFriend(who) then
							if card_x:getSuit() == sgs.Card_Spade and not self:toTurnOver(from, 0)then
								table.insert(best_use, card)
								continue
							elseif card_x:getSuit() == sgs.Card_Diamond and without_recover and not tiandu_peach then
								table.insert(best_use, card)
								continue
							end
							if judge.card:isBlack() and not card_x:isBlack() then
								table.insert(can_use, card)
							end
						elseif self:isEnemy(who) then
							if who:hasShownSkills("tiandu|zhuwei") and isCard("Peach", card_x, who) then continue end
							if card_x:getSuit() == sgs.Card_Spade and not self:toTurnOver(from, 0) then
								table.insert(best_use, card)
								continue
							elseif card_x:getSuit() == sgs.Card_Club and need_dis then
								table.insert(best_use, card)
								continue
							elseif card_x:getSuit() == sgs.Card_Heart and without_recover then
								table.insert(best_use, card)
								continue
							end
							if tiandu_peach then
								need_retrial = true
							end
							if self:toTurnOver(from, 0) then
								spade_check = card_x:getSuit() ~= sgs.Card_Spade
								if judge.card:getSuit() == sgs.Card_Spade then
									need_retrial = true
								end
							end
							if spade_check and heart_check and club_check and diamond_check and need_retrial then
								table.insert(can_use, card)
							end
						end
					elseif self:isEnemy(from) then
						if self:isFriend(who) then
							if not self:toTurnOver(from, 0) then
								spade_check = card_x:getSuit() ~= sgs.Card_Spade
								if judge.card:getSuit() == sgs.Card_Spade then
									need_retrial = true
								end
							end
							if need_dis then
								club_check = card_x:getSuit() ~= sgs.Card_Club
								if judge.card:getSuit() == sgs.Card_Club then
									need_retrial = true
								end
							end
							if without_recover then
								heart_check = card_x:getSuit() ~= sgs.Card_Heart
								if judge.card:getSuit() == sgs.Card_Heart and not tiandu_peach then
									need_retrial = true
								end
							end
							if spade_check and heart_check and club_check and diamond_check and need_retrial then
								table.insert(can_use, card)
							end
						elseif self:isEnemy(who) then
							if who:hasShownSkills("tiandu|zhuwei") and isCard("Peach", card_x, who) then continue end
							if without_recover and card_x:getSuit() == sgs.Card_Heart then
								table.insert(best_use, card)
								continue
							end
							if tiandu_peach then
								need_retrial = true
							end
							if not self:toTurnOver(from, 0) then
								spade_check = card_x:getSuit() ~= sgs.Card_Spade
								if judge.card:getSuit() == sgs.Card_Spade then
									need_retrial = true
								end
							end
							if need_dis then
								club_check = card_x:getSuit() ~= sgs.Card_Club
								if judge.card:getSuit() == sgs.Card_Club then
									need_retrial = true
								end
							end
							if without_recover then
								heart_check = card_x:getSuit() ~= sgs.Card_Heart
								if judge.card:getSuit() == sgs.Card_Heart then
									need_retrial = true
								end
							end
							if who:hasShownSkills(sgs.cardneed_skill) then
								diamond_check = card_x:getSuit() ~= sgs.Card_Diamond
								if judge.card:getSuit() == sgs.Card_Diamond then
									need_retrial = true
								end
							end
							if spade_check and heart_check and club_check and diamond_check and need_retrial then
								table.insert(can_use, card)
							end
						end
					end
				else
					if self:isFriend(who) then
						if judge.card:getSuit() ~= sgs.Card_Diamond then
							if card_x:getSuit() == sgs.Card_Diamond and not tiandu_peach and (without_recover or who:hasShownSkills(sgs.cardneed_skill))then
								table.insert(best_use, card)
								continue
							end
							if judge.card:isBlack() and not card_x:isBlack() then
								table.insert(can_use, card)
							end
						end
					elseif self:isEnemy(who) then
						if not judge.card:isBlack() and card_x:isBlack() then
							table.insert(can_use, card)
						end
					end
				end
			elseif self:isEnemy(who) and who:hasShownSkills("tiandu|zhuwei") and isCard("Peach", judge.card, who) and not isCard("Peach", card_x, self.player) then
				table.insert(can_use, card)
			end
		elseif reason == "ganglie" then
			local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
			local from = nil
			if (damage.from and damage.from:isAlive()) then from = damage.from end
			if not card_x:sameColorWith(judge.card) then
				if from then
					if (self:getOverflow(from) > 0 and self:doNotDiscard(from, "e")) or (self:isWeak(from) and self:canAttack(from,who)) then
						if (judge.card:isRed() and self:isFriend(from))or(judge.card:isBlack() and self:isEnemy(from) and not tiandu_peach) then
							table.insert(best_use, card)
						end
					elseif not self:canAttack(from) then
						if (judge.card:isBlack() and self:isFriend(from))or(judge.card:isRed() and self:isEnemy(from) and not tiandu_peach) then
							table.insert(best_use, card)
						end
					end
				end
			elseif self:isEnemy(who) and who:hasShownSkills("tiandu|zhuwei") and isCard("Peach", judge.card, who) and not isCard("Peach", card_x, self.player) then
				table.insert(can_use, card)
			end
		elseif self:isFriend(who) and judge:isGood(card_x)
				and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and is_peach) then
			table.insert(can_use, card)
		elseif self:isEnemy(who) and not judge:isGood(card_x)
				and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and is_peach) then
			table.insert(can_use, card)
		end
	end
	--为闪电留♠2~9,除非你是判定者且能回收判定
	if reason ~= "lightning" and not (self.player:objectName() == who:objectName() and (self.player:hasSkills("tiandu|zhuwei") or reason == "luoshen")) then
		for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
			if aplayer:containsTrick("lightning") then
				if #best_use > 0 then
					for i, card in ipairs(best_use) do
						if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
							table.remove(best_use, i)
							break
						end
					end
				end
				for i, card in ipairs(can_use) do
					if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
						table.remove(can_use, i)
						break
					end
				end
			end
		end
	end
	if #best_use > 0 then can_use = best_use end
	
	if next(can_use) then
		if self:needToThrowArmor() then
			for _, c in ipairs(can_use) do
				if c:getEffectiveId() == self.player:getArmor():getEffectiveId() then return c:getEffectiveId() end
			end
		end
		self:sortByKeepValue(can_use)
		return can_use[1]:getEffectiveId()
	else
		return -1
	end
end


function SmartAI:damageIsEffective(to, nature, from, card)
	local damageStruct = {}
	damageStruct.to = to or self.player
	damageStruct.from = from or self.room:getCurrent()
	damageStruct.nature = nature or sgs.DamageStruct_Normal
	damageStruct.card = card or nil
	return self:damageIsEffective_(damageStruct)
end

function SmartAI:damageIsEffective_(damageStruct)
	if type(damageStruct) ~= "table" and type(damageStruct) ~= "DamageStruct" and type(damageStruct) ~= "userdata" then self.room:writeToConsole(debug.traceback()) return false end
	if not damageStruct.to then self.room:writeToConsole(debug.traceback()) return false end
	local to = damageStruct.to
	local nature = damageStruct.nature or sgs.DamageStruct_Normal
	local damage = damageStruct.damage or 1
	local from = damageStruct.from

	if type(to) == "table" then self.room:writeToConsole(debug.traceback()) return false end

	if to:isRemoved() then return false end
	--[[
	if from and to:hasShownSkill("zhiman") and self:isFriendWith(to, from) then
		return false
	end
	--]]
	if from and from:hasSkill("xinghuo") and nature == sgs.DamageStruct_Fire then--xinghuo是预置加伤
		damage = damage + 1
	end
	if self:hasKnownSkill("mingshi", to) and from and not from:hasShownAllGenerals() then
		damage = damage - 1
	end
	if to:getMark("##xiongnve_avoid") > 0 then
		damage = damage - 1
	end
	
	if self:hasKnownSkill("yuanyu", to) and from and not from:inMyAttackRange(to) then 
		damage = damage - 1
	end
	
	local C_C = sgs.findPlayerByShownSkillName("qiyuan")
	if C_C and to:hasShownOneGeneral() and to:getKingdom() == C_C:getKingdom() 
		and C_C:getHp() >= to:getHp() and from and not from:isFriendWith(to) then
		if damage > 1 then damage = 1 end
		local Kingdom_nums = {}
		local kingdoms = sgs.KingdomsTable
		for _, kingdom in ipairs(kingdoms) do
			Kingdom_nums[kingdom] = 0
		end
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not p:hasShownOneGeneral() then continue end
			if table.contains(kingdoms, p:getKingdom()) then
				Kingdom_nums[p:getKingdom()] = Kingdom_nums[p:getKingdom()] + 1
			end
		end
		--p:getPlayerNumWithSameKingdom("AI"),to:getPlayerNumWithSameKingdom("AI")--空值函数
		local qiyuan_show = false
		for _, kingdom in ipairs(kingdoms) do
			if to:getKingdom() == kingdom then continue end
			if Kingdom_nums[kingdom] >= C_C:getPlayerNumWithSameKingdom("AI") then
				qiyuan_show = true
				break
			end
		end
		if qiyuan_show then
			if from:hasShownOneGeneral() and (to:getPlayerNumWithSameKingdom("AI") >= from:getPlayerNumWithSameKingdom("AI") or from:getMark("@bless") == 0) then
			else damage = damage - 1 end
		end
	end
	if damage < 1 then return false end

	--if self:hasKnownSkill("yuanyu", to) and from and not to:isAdjacentTo(from) then return false end

	if to:hasShownSkill("tianran") and from and damageStruct.card then
		if self:isFriend(to, from) then return false
		else
			local without_type = true
			if from:objectName() == self.player:objectName() then
				local type_name = {"BasicCard", "TrickCard", "EquipCard"}
				local types = type_name[damageStruct.card:getTypeId()]
				local cards = self.player:getCards("h")
				for _, c in sgs.qlist(cards) do
					if c:getEffectiveId() == damageStruct.card:getEffectiveId() then continue end
					if c:isKindOf(types) then without_type = false break end
				end
			else
				local un_type_name = {"^BasicCard", "^TrickCard", "^EquipCard"}
				local types = un_type_name[damageStruct.card:getTypeId()]
				if getKnownCard(from, self.player, types, false) < from:getHandcardNum() then without_type = false end
			end
			if without_type then return false end
        end
	end
	
	if to:hasShownSkill("yujia") and nature ~= sgs.DamageStruct_Normal then return false end
	
	if to:hasArmorEffect("PeaceSpell") and nature ~= sgs.DamageStruct_Normal then return false end
	if to:hasShownSkills("jgyuhuo_pangtong|jgyuhuo_zhuque") and nature == sgs.DamageStruct_Fire then return false end
	if to:getMark("@fog") > 0 and nature ~= sgs.DamageStruct_Thunder then return false end
	if to:hasArmorEffect("Breastplate") and (damage > to:getHp() or (to:getHp() > 1 and damage == to:getHp())) then return false end

	for _, callback in pairs(sgs.ai_damage_effect) do
		if type(callback) == "function" then
			local is_effective = callback(self, damageStruct)
			if not is_effective then return false end
		end
	end

	return true
end

function SmartAI:needDamagedEffects(to, from, isSlash)
	from = from or self.room:getCurrent()
	to = to or self.player

	if isSlash then
		if from:hasWeapon("IceSword") and to:getCardCount(true) > 1 and not self:isFriend(from, to) then
			return false
		end
	end

	if from:objectName() ~= to:objectName() and self:hasHeavySlashDamage(from, nil, to) then return false end

	if sgs.isGoodHp(to, self.player) then
		for _, askill in sgs.qlist(to:getVisibleSkillList(true)) do
			local callback = sgs.ai_need_damaged[askill:objectName()]
			if type(callback) == "function" and callback(self, from, to) then return true end
		end
	end
	return false
end

local function prohibitUseDirectly(card, player)--包含鏖战桃的情况
	if player:isCardLimited(card, card:getHandlingMethod()) then return true end
	if card:isKindOf("Peach") and player:hasFlag("Global_PreventPeach") then return true end
	return false
end

function HasRuleSkill(skill_name, player)
	local rule_skills = sgs.rule_skill:split("|")
	if table.contains(rule_skills, skill_name) then
		if skill_name == "aozhan" then
			return player:getMark("GlobalBattleRoyalMode") > 0
		elseif skill_name == "companion" then
			return player:getMark("@companion") > 0
		elseif skill_name == "halfmaxhp" then
			return player:getMark("@halfmaxhp") > 0
		elseif skill_name == "firstshow" then
			return player:getMark("@firstshow") > 0
		elseif skill_name == "careerman" then
			return player:getMark("@careerist") > 0
		else
			return true
		end
	end
	return false
end

local function getPlayerSkillList(player)
	local skills = sgs.QList2Table(player:getVisibleSkillList(true))
	local rule_skills = sgs.rule_skill:split("|")
	for _, name in ipairs(rule_skills) do
		local skill = sgs.Sanguosha:getSkill(name)
		if skill and HasRuleSkill(name, player) then
			table.insert(skills, skill)
		end
	end
	return skills
end

local function cardsView(self, class_name, player, cards)
	local returnList = {}
	for _, skill in ipairs(getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) or HasRuleSkill(askill, player) then
			local callback = sgs.ai_cardsview[askill]
			if type(callback) == "function" then
				local ret = callback(self, class_name, player, cards)
				if ret then
					if type(ret) == "table" then
						table.insertTable(returnList,ret)
					else
						table.insert(returnList,ret)
					end
				end
			end
		end
	end
	return returnList
end

local function cardsViewPriority(self, class_name, player,reason) --优先度最高的视为卡，除了会优先使用外几乎与cardsView没区别。
	local returnList = {}
	for _, skill in ipairs(getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) or HasRuleSkill(askill, player) then
			local callback = sgs.ai_cardsview_priority[askill]
			if type(callback) == "function" then
				local ret = callback(self, class_name, player,reason)
				if ret then
					if type(ret) == "table" then
						table.insertTable(returnList,ret)
					else
						table.insert(returnList,ret)
					end
				end
			end
		end
	end
	return returnList
end

local function getSkillViewCard(card, class_name, player, card_place)
	--防止isCardLimited响应卡死,
	--if player:isCardLimited(card, card:getHandlingMethod()) then return end
	for _, skill in ipairs(getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill)or HasRuleSkill(askill, player) then
			local callback = sgs.ai_view_as[askill]
			if type(callback) == "function" then
				--[[
				--qianxi,isCardLimited响应卡死
				local log = sgs.LogMessage()
				log.type = "#TheTest-point"
				log.from = self.player
				log.arg = "getSkillViewCard:function"
				player:getRoom():sendLog(log)
				--]]
				local skill_card_str = callback(card, player, card_place, class_name)
				if skill_card_str then
					local skill_card = sgs.Card_Parse(skill_card_str)
					assert(skill_card)
					--[[
					--(2.1.0版)方天没有addSubcard,返回skill_card_str会导致self:getCards("Slash")全是HalberdCard,取不到正常的Slash
					if skill_card:isKindOf("HalberdCard") and not player:isCardLimited(skill_card, skill_card:getHandlingMethod()) 
						and card and card:isKindOf("Slash") and class_name == "Slash" then return card:toString() end
					--]]
					if skill_card:isKindOf(class_name) and not player:isCardLimited(skill_card, skill_card:getHandlingMethod()) then return skill_card_str end
				end
			end
		end
	end
end

function isCard(class_name, card, player)
	if not player or not card then Global_room:writeToConsole(debug.traceback()) end
	if not card:isKindOf(class_name) then
		local place
		local id = card:getEffectiveId()
		if Global_room:getCardOwner(id) == nil or Global_room:getCardOwner(id):objectName() ~= player:objectName() then place = sgs.Player_PlaceHand
		else place = Global_room:getCardPlace(id) end
		if getSkillViewCard(card, class_name, player, place) then return true end
	else
		if not prohibitUseDirectly(card, player) then return true end
	end
	return false
end

function SmartAI:getMaxNumberCard(player, cards, observer)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	cards = cards or player:getHandcards()
	observer = observer or self.player

	local max_card, max_point = nil, 0
	for _, card in sgs.qlist(cards) do
		if (player:objectName() == self.player:objectName() and not self:isValuableCard(card)) or sgs.cardIsVisible(card, player, observer) then
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end
	if player:objectName() == self.player:objectName() and not max_card then
		for _, card in sgs.qlist(cards) do
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end

	if player:objectName() ~= self.player:objectName() then return max_card end

	if player:hasShownSkill("tianyi") and max_point > 0 then
		for _, card in sgs.qlist(cards) do
			if card:getNumber() == max_point and not isCard("Slash", card, player) then
				return card
			end
		end
	end

	return max_card
end

function SmartAI:getMinNumberCard(player, cards, observer)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	cards = cards or player:getHandcards()
	observer = observer or self.player

	local min_card, min_point = nil, 14
	for _, card in sgs.qlist(cards) do
		if player:objectName() == self.player:objectName() or sgs.cardIsVisible(card, player, observer) then
			local point = card:getNumber()
			if point < min_point then
				min_point = point
				min_card = card
			end
		end
	end

	return min_card
end

function SmartAI:getKnownNum(player, observer)
	player = player or self.player
	if not player then
		return self.player:getHandcardNum()
	else
		local cards = player:getHandcards()
		for _, id in sgs.qlist(player:getHandPile()) do
			cards:append(sgs.Sanguosha:getCard(id))
		end
		local known = 0
		for _, card in sgs.qlist(cards) do
			if sgs.cardIsVisible(card, player, observer) then
				known = known + 1
			end
		end
		return known
	end
end

function getKnownNum(player, observer)
	if not player then Global_room:writeToConsole(debug.traceback()) return end
	local cards = player:getHandcards()
	for _, id in sgs.qlist(player:getHandPile()) do
		cards:append(sgs.Sanguosha:getCard(id))
	end
	local known = 0
	for _, card in sgs.qlist(cards) do
		if sgs.cardIsVisible(card, player, observer) then
			known = known + 1
		end
	end
	return known
end

function getKnownCard(player, from, class_name, viewas, flags, return_table)
	if not player or (flags and type(flags) ~= "string") then Global_room:writeToConsole(debug.traceback()) return 0 end
	flags = flags or "h"
	player = Global_room:findPlayerbyobjectName(player:objectName())
	if not player then Global_room:writeToConsole(debug.traceback()) return 0 end
	local cards = player:getCards(flags)
	if flags:match("h") then
		for _, id in sgs.qlist(player:getHandPile()) do
			cards:append(sgs.Sanguosha:getCard(id))
		end
	end
	local suits = {["club"] = 1, ["spade"] = 1, ["diamond"] = 1, ["heart"] = 1}
	local known = {}
	for _, card in sgs.qlist(cards) do
		if sgs.cardIsVisible(card, player, from) then
			if (viewas and isCard(class_name, card, player)) or card:isKindOf(class_name)
				or (suits[class_name] and card:getSuitString() == class_name)
				or (class_name == "red" and card:isRed()) or (class_name == "black" and card:isBlack()) then
				table.insert(known, card)
			end
		end
	end
	if return_table then return known end
	return #known
end

function SmartAI:getCardId(class_name, acard)
	local cards
	if acard then cards = { acard }
	else
		cards = self.player:getCards("he")
		for _, key in sgs.list(self.player:getPileNames()) do
			for _, id in sgs.qlist(self.player:getPile(key)) do
				cards:append(sgs.Sanguosha:getCard(id))
			end
		end
		cards = sgs.QList2Table(cards)
	end

	local cardask
	local reason = sgs.Sanguosha:getCurrentCardUseReason()
	local response_use = (reason and reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
	cardask = class_name ~= "Slash" or response_use
	if cardask then
		if self.player:getPhase() == sgs.Player_Play then
			self:sortByUseValue(cards, true)
		else
			self:sortByKeepValue(cards)
		end
	end

	local cardsViewFirst = cardsViewPriority(self, class_name, self.player,"getCardId")
	if #cardsViewFirst > 0 then
		table.sort(cardsViewFirst,
		function(a,b)
			return self:getUsePriority(sgs.Card_Parse(a)) > self:getUsePriority(sgs.Card_Parse(b))
		end
		)
		for _, str in ipairs(cardsViewFirst) do
			local c = sgs.Card_Parse(str)
			assert(c)
			--if prohibitUseDirectly(c, self.player) then continue end
			return str
		end
		--return cardsViewFirst[1]
	end

	local viewArr, cardArr = {}, {}

	for _, card in ipairs(cards) do
		local card_place = self.room:getCardPlace(card:getEffectiveId())
		local isCard = card:isKindOf(class_name) and not prohibitUseDirectly(card, self.player)
						and (card_place ~= sgs.Player_PlaceSpecial or self.player:getHandPile():contains(card:getEffectiveId()))
		local viewas = getSkillViewCard(card, class_name, self.player, card_place)
		local viewascard
		if viewas then
			viewascard = sgs.Card_Parse(viewas)
			assert(viewascard)
			--if prohibitUseDirectly(viewascard, self.player) then viewas = false end
		end
		if viewas then
			if isCard and self:adjustUsePriority(card, 0) >= self:adjustUsePriority(viewascard, 0) then
				table.insert(cardArr, card)
			else
				table.insert(viewArr, viewascard)
			end
		elseif isCard then
			table.insert(cardArr, card)
		end
	end

	if not cardask then
		self:sortByUsePriority(viewArr)
		self:sortByUsePriority(cardArr)
	end

	if #viewArr > 0 or #cardArr > 0 then
		local viewas, cardid
		viewas = #viewArr > 0 and viewArr[1]:toString()
		cardid = #cardArr > 0 and cardArr[1]:toString()
		if cardid or viewas then return cardid or viewas end
	end
	
	local card_str = cardsView(self, class_name, self.player)
	if #card_str > 0 then
		for _, str in ipairs(card_str) do
			local c = sgs.Card_Parse(str)
			assert(c)
			--if prohibitUseDirectly(c, self.player, response_use) then continue end
			return str
		end
		--return cardsView[1]
	end
	--return "."会导致各种断言失败,以及濒死不出桃
	return nil
end

function SmartAI:getCard(class_name)
	local card_id = self:getCardId(class_name)
	if card_id then return sgs.Card_Parse(card_id) end
end

function SmartAI:getCards(class_name, flag)
	local room = self.room
	if flag and type(flag) ~= "string" then room:writeToConsole(debug.traceback()) return {} end

	local private_pile
	if not flag then private_pile = true end
	flag = flag or "he"
	local all_cards = self.player:getCards(flag)
	if private_pile then
		for _, key in sgs.list(self.player:getPileNames()) do
			for _, id in sgs.qlist(self.player:getPile(key)) do
				all_cards:append(sgs.Sanguosha:getCard(id))
			end
		end
	elseif flag:match("h") then
		for _, id in sgs.qlist(self.player:getHandPile()) do
			all_cards:append(sgs.Sanguosha:getCard(id))
		end
	end
	
	local reason = sgs.Sanguosha:getCurrentCardUseReason()
	local response_use = (reason and reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
	
	local cards, other = {}, {}
	local card_place, card_str

	local cardsViewFirst = cardsViewPriority(self, class_name, self.player,"getCards")
	if #cardsViewFirst > 0 then
		table.sort(cardsViewFirst,
		function(a,b)
			return self:getUsePriority(sgs.Card_Parse(a)) > self:getUsePriority(sgs.Card_Parse(b))
		end
		)
		for _, str in ipairs(cardsViewFirst) do
			local c = sgs.Card_Parse(str)
			assert(c)
			if prohibitUseDirectly(c, self.player) then continue end
			table.insert(cards, c)
		end
	end
	--sgs.ai_skill_cardask["slash-jink"](self:getCards("Jink"))
	for _, card in sgs.qlist(all_cards) do
		card_place = room:getCardPlace(card:getEffectiveId())

		if card:hasFlag("AI_Using") then
		elseif class_name == "." and card_place ~= sgs.Player_PlaceSpecial and not prohibitUseDirectly(card, self.player) then
			table.insert(cards, card)
		else
			local isCard = card:isKindOf(class_name) and not prohibitUseDirectly(card, self.player)
							and (card_place ~= sgs.Player_PlaceSpecial or self.player:getHandPile():contains(card:getEffectiveId()))
			local viewas = getSkillViewCard(card, class_name, self.player, card_place)
			local viewascard
			if viewas then
				viewascard = sgs.Card_Parse(viewas)
				assert(viewascard)
				if prohibitUseDirectly(viewascard, self.player) then viewas = false end
			end
			if viewas then
				if isCard and self:adjustUsePriority(card, 0) >= self:adjustUsePriority(viewascard, 0) then
					table.insert(cards, card)
				else
					table.insert(cards, viewascard)
				end
			elseif isCard then
				table.insert(cards, card)
			else
				table.insert(other, card)
			end
		end
	end

	card_str = cardsView(self, class_name, self.player, other)
	if #card_str > 0 then
		for _, str in ipairs(card_str) do
			local c = sgs.Card_Parse(str)
			assert(c)
			if prohibitUseDirectly(c, self.player) then continue end
			table.insert(cards, c)
		end
	end

	return cards
end

function getCardsNum(class_name, player, from)
	if not player then
		Global_room:writeToConsole(debug.traceback())
		return 0
	end

	local cards = sgs.QList2Table(player:getHandcards())
	for _, id in sgs.qlist(player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local num = 0
	local shownum = 0
	local redpeach = 0
	local redslash = 0
	local blackcard = 0
	local blacknull = 0
	local equipnull = 0
	local equipcard = 0
	local trickcard = 0
	local heartslash = 0
	local heartpeach = 0
	local spadenull = 0
	local spadewine = 0
	local spadecard = 0
	local diamondcard = 0
	local clubcard = 0
	local slashjink = 0
	local other = {}

	for _, card in ipairs(cards) do
		if sgs.cardIsVisible(card, player, from) then
			shownum = shownum + 1
			if isCard(class_name, card, player) then
				num = num + 1
			else
				table.insert(other, card)
			end
			if card:isKindOf("EquipCard") then
				equipcard = equipcard + 1
			end
			if card:isKindOf("TrickCard") then
				trickcard = trickcard + 1
			end
			if card:isKindOf("Slash") or card:isKindOf("Jink") then
				slashjink = slashjink + 1
			end
			if card:isRed() then
				if not card:isKindOf("Slash") then
					redslash = redslash + 1
				end
				if not card:isKindOf("Peach") then
					redpeach = redpeach + 1
				end
			end
			if card:isBlack() then
				blackcard = blackcard + 1
				if not card:isKindOf("Nullification") then
					blacknull = blacknull + 1
				end
			end
			if card:getSuit() == sgs.Card_Heart then
				if not card:isKindOf("Slash") then
					heartslash = heartslash + 1
				end
				if not card:isKindOf("Peach") then
					heartpeach = heartpeach + 1
				end
			end
			if card:getSuit() == sgs.Card_Spade then
				if not card:isKindOf("Nullification") then
					spadenull = spadenull + 1
				end
				if not card:isKindOf("Analeptic") then
					spadewine = spadewine + 1
				end
			end
			if card:getSuit() == sgs.Card_Diamond and not card:isKindOf("Slash") then
				diamondcard = diamondcard + 1
			end
			if card:getSuit() == sgs.Card_Club then
				clubcard = clubcard + 1
			end
		end
	end

	local ecards = player:getEquips()
	for _, card in sgs.qlist(ecards) do
		table.insert(other, card)
		equipcard = equipcard + 1
		if player:getHandcardNum() > player:getHp() then
			equipnull = equipnull + 1
		end
		if card:isRed() then
			redpeach = redpeach + 1
			redslash = redslash + 1
		end
		if card:getSuit() == sgs.Card_Heart then
			heartpeach = heartpeach + 1
		end
		if card:getSuit() == sgs.Card_Spade then
			spadecard = spadecard + 1
		end
		if card:getSuit() == sgs.Card_Diamond  then
			diamondcard = diamondcard + 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubcard = clubcard + 1
		end
	end
	num = num + #cardsViewPriority(sgs.ais[player:objectName()], class_name, player,"getCardsNum")
	num = num + #cardsView(sgs.ais[player:objectName()], class_name, player, other)

	if not from or player:objectName() ~= from:objectName() then
		if class_name == "Slash" then
			local slashnum
			if player:hasShownSkill("wusheng") then
				slashnum = redslash + num + (player:getHandcardNum() - shownum) * 0.69
			elseif player:hasShownSkill("longdan") then
				slashnum = slashjink + (player:getHandcardNum() - shownum) * 0.72
			else
				slashnum = num + (player:getHandcardNum() - shownum) * 0.35
			end
			if player:hasWeapon("Spear") then
				local slashnum2 = math.floor((player:getHandcardNum() - shownum) / 2) + num
				return math.max(slashnum, slashnum2)
			end
			return slashnum
		elseif class_name == "Jink" then
			if player:hasShownSkill("qingguo") then
				return blackcard + num + (player:getHandcardNum() - shownum) * 0.85
			elseif player:hasShownSkill("longdan") then
				return slashjink + (player:getHandcardNum() - shownum) * 0.72
			else
				return num + (player:getHandcardNum() - shownum) * 0.6
			end
		elseif class_name == "Peach" then
			if player:hasShownSkill("jijiu") and player:getPhase() == sgs.Player_NotActive then
				return num + redpeach + (player:getHandcardNum() - shownum) * 0.6
			else
				return num
			end
		elseif class_name == "Nullification" then
			if player:hasShownSkill("kanpo") then
				return num + blacknull + (player:getHandcardNum() - shownum) * 0.5
			else
				return num
			end
		end
	end
	return num
end

function SmartAI:getCardsNum(class_name, flag)
	local player = self.player
	local n = 0
	if type(class_name) == "table" then
		for _, each_class in ipairs(class_name) do
			n = n + self:getCardsNum(each_class, flag)
		end
		return n
	end
	n = #self:getCards(class_name, flag)

	return n
end

function SmartAI:getAllPeachNum(player)
	player = player or self.player
	local n = 0
	for _, friend in ipairs(self:getFriends(player)) do
		local num = self.player:objectName() == friend:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", friend, self.player)
		n = n + num
	end
	return n
end
function SmartAI:getRestCardsNum(class_name, yuji)
	yuji = yuji or self.player
	local ban = sgs.Sanguosha:getBanPackages()
	ban = table.concat(ban, "|")
	sgs.discard_pile = self.room:getDiscardPile()
	local totalnum = 0
	local discardnum = 0
	local knownnum = 0
	local card
	for i = 1, sgs.Sanguosha:getCardCount() do
		card = sgs.Sanguosha:getEngineCard(i-1)
		-- if card:isKindOf(class_name) and not ban:match(card:getPackage()) then totalnum = totalnum+1 end
		if card:isKindOf(class_name) then totalnum = totalnum + 1 end
	end
	for _, card_id in sgs.qlist(sgs.discard_pile) do
		card = sgs.Sanguosha:getEngineCard(card_id)
		if card:isKindOf(class_name) then discardnum = discardnum + 1 end
	end
	for _, player in sgs.qlist(self.room:getOtherPlayers(yuji)) do
		knownnum = knownnum + getKnownCard(player, self.player, class_name)
	end
	return totalnum - discardnum - knownnum
end

function SmartAI:hasSuit(suit_strings, include_equip, player)
	return self:getSuitNum(suit_strings, include_equip, player) > 0
end

function SmartAI:getSuitNum(suit_strings, include_equip, player)
	player = player or self.player
	local n = 0
	local flag = include_equip and "he" or "h"
	local allcards
	if player:objectName() == self.player:objectName() then
		allcards = sgs.QList2Table(player:getCards(flag))
		for _, id in sgs.qlist(player:getHandPile()) do
			table.insert(allcards, sgs.Sanguosha:getCard(id))
		end
	else
		allcards = include_equip and sgs.QList2Table(player:getEquips()) or {}
		local handcards = sgs.QList2Table(player:getHandcards())
		for _, id in sgs.qlist(player:getHandPile()) do
			table.insert(handcards, sgs.Sanguosha:getCard(id))
		end
		for i = 1, #handcards, 1 do
			if sgs.cardIsVisible(handcards[i], player, self.player) then
				table.insert(allcards, handcards[i])
			end
		end
	end
	for _, card in ipairs(allcards) do
		for _, suit_string in ipairs(suit_strings:split("|")) do
			if card:getSuitString() == suit_string
				or (suit_string == "black" and card:isBlack()) or (suit_string == "red" and card:isRed()) then
				n = n + 1
			end
		end
	end
	return n
end

function SmartAI:hasKnownSkill(skill_name, who)
	if not who then
		local skill = skill_name
		if type(skill_name) == "table" then
			skill = skill_name.name
		end
		local real_skill = sgs.Sanguosha:getSkill(skill)
		if real_skill and real_skill:isLordSkill() then
			return self.player:hasLordSkill(skill)
		else
			return self.player:hasSkill(skill)
		end
	else
		local skills = skill_name:split("|")
	    for _, sk in ipairs(skills) do
			local checkpoint = true
			for _, s in ipairs(sk:split("+")) do
				if who:objectName() == self.player:objectName() then
					checkpoint = self.player:hasSkill(s)
				else
					if not who:hasShownSkill(s) then checkpoint = false end
					if self.player:getTag("KnownBoth_" .. who:objectName()):toString() ~= "" then--知己知彼
						local names = self.player:getTag("KnownBoth_" .. who:objectName()):toString():split("+")
						if not who:hasShownGeneral1() and who:canShowGeneral("h") and names[1] ~= "anjiang" and not who:isDuanchang(true) and sgs.Sanguosha:getGeneral(names[1]):hasSkill(s) then checkpoint = true end
						if not who:hasShownGeneral2() and who:canShowGeneral("d") and names[2] ~= "anjiang" and not who:isDuanchang(false) and sgs.Sanguosha:getGeneral(names[2]):hasSkill(s) then checkpoint = true end
					end
					if sgs.general_shown[who:objectName()]["head"] and who:inHeadSkills(s) and who:canShowGeneral("h") and not who:isDuanchang(true) then--明置过被暗置的技能
						checkpoint = true
					end
					if sgs.general_shown[who:objectName()]["deputy"] and who:inDeputySkills(s) and who:canShowGeneral("d") and not who:isDuanchang(false) then
						checkpoint = true
					end
				end
			end
			if checkpoint then return true end
		end
	end
end

function SmartAI:hasKnownSkills(skill_names, player)
	player = player or self.player
	if type(player) == "table" then
		for _, p in ipairs(player) do
			if self:hasKnownSkill(skill_names, p) then return true end
		end
		return false
	end
	return self:hasKnownSkill(skill_names, player)
end

function SmartAI:fillSkillCards(cards)
	local i = 1
	while i <= #cards do
		if prohibitUseDirectly(cards[i], self.player) then
			table.remove(cards, i)
		else
			i = i + 1
		end
	end
	for _, skill in ipairs(sgs.ai_skills) do
		if self:hasKnownSkill(skill.name) or HasRuleSkill(skill.name, self.player) then--or (skill.name == "shuangxiong" and self.player:hasFlag("shuangxiong")) 
			local skill_card = skill.getTurnUseCard(self, #cards == 0)
			if skill_card then table.insert(cards, skill_card) end
		end
	end
end


function SmartAI:useSkillCard(card, use)
	local name
	if not card then self.room:writeToConsole(debug.traceback()) return end
	if card:isKindOf("LuaSkillCard") then
		name = "#" .. card:objectName()
	else
		name = card:getClassName()
	end
	if not use.isDummy and name ~= "TransferCard" and not HasRuleSkill(card:getSkillName(), self.player)
		and not self.player:hasSkill(card:getSkillName()) and not self.player:hasLordSkill(card:getSkillName()) then return end
	if sgs.ai_skill_use_func[name] then
		--Global_room:writeToConsole("Consider_using:"..name)
		sgs.ai_skill_use_func[name](card, use, self)
		--[[
		if use.card then
			Global_room:writeToConsole("useSkillCard:"..name)
		end
		--]]
		return
	end
end

function SmartAI:useBasicCard(card, use)
	if not card then Global_room:writeToConsole(debug.traceback()) return end
	--if self:needRende() then return end
	self:useCardByClassName(card, use)
end

function SmartAI:aoeIsEffective(card, to, source)
	local players = self.room:getAlivePlayers()
	players = sgs.QList2Table(players)
	source = source or self.room:getCurrent()

	if to:hasArmorEffect("Vine") then return false end
	if to:isLocked(card) then return false end
	if to:isRemoved() then return false end
	if card:isKindOf("SavageAssault") and to:hasShownSkills("huoshou|juxiang")  then
		return false
	end
	if to:hasShownSkill("weimu") and card:isBlack() then return false end
	if not self:trickIsEffective(card, to, source) or not self:damageIsEffective(to, nil, source) then
		return false
	end
	return true
end

function SmartAI:canAvoidAOE(card)
	if not self:aoeIsEffective(card, self.player) then return true end
	if card:isKindOf("SavageAssault") then
		if self:getCardsNum("Slash") > 0 then
			return true
		end
	end
	if card:isKindOf("ArcheryAttack") then
		if self:getCardsNum("Jink") > 0 or (self:hasEightDiagramEffect() and self.player:getHp() > 1) then
			return true
		end
	end
	return false
end

function SmartAI:getDistanceLimit(card, from)
	from = from or self.player
	if card:isKindOf("Snatch") or card:isKindOf("SupplyShortage") or card:isKindOf("Slash") then
		return 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, from, card)
	elseif card:isKindOf("Indulgence") or card:isKindOf("FireAttack") then
		return 999
	end
end

function SmartAI:exclude(players, card, from)
	from = from or self.player
	local excluded = {}
	local limit = self:getDistanceLimit(card, from)
	local range_fix = 0
	if card:isKindOf("Snatch") and card:getSkillName() == "jixi" then
		range_fix = range_fix + 1
	end
	if card:isKindOf("SupplyShortage") and (card:getSkillName() == "duanliang_egf" or card:getSkillName() == "duanliang") then
		limit = 2
		local duanliang_count = 0
		local can_duanliang = 0
		local cards = from:getCards("he")
		cards = sgs.QList2Table(cards)
		for _, id in sgs.qlist(from:getHandPile()) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
		for _,acard in ipairs(cards) do
			if acard:isBlack() and (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard")) and (self:getUseValue(acard) < sgs.ai_use_value.SupplyShortage) then
				duanliang_count = duanliang_count + 1
			end
		end
		for _, p in ipairs(players) do
			if self:trickIsEffective(card, p, from) and not p:containsTrick("supply_shortage")
			and (not limit or from:distanceTo(p) <= limit) and self:isEnemy(from, p) then
				can_duanliang = can_duanliang + 1
			end
		end
		if duanliang_count < 2 or can_duanliang == 0 then--为何correctCardTarget不会修正断粮的距离？
			limit = 999
		end
	end

	if type(players) ~= "table" then players = sgs.QList2Table(players) end

	if card:isVirtualCard() then
		for _, id in sgs.qlist(card:getSubcards()) do
			if from:getOffensiveHorse() and from:getOffensiveHorse():getEffectiveId() == id then range_fix = range_fix + 1 end
		end
	end

	for _, player in ipairs(players) do
		if --[[not sgs.Sanguosha:isProhibited(from, player, card) and]] (not card:isKindOf("TrickCard") or self:trickIsEffective(card, player, from))
			and (not limit or from:distanceTo(player, range_fix) <= limit) then
			table.insert(excluded, player)
		end
	end
	return excluded
end

function SmartAI:getJiemingDrawNum(player)
	local max_x = 0
	for _, friend in ipairs(self:getFriends(player)) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if x > max_x then
			max_x = x
		end
	end
	return max_x
end

function SmartAI:getAoeValue(card)
	local attacker = self.player
	local good, bad, isEffective_F, isEffective_E = 0, 0, 0, 0
	local LuanjiFriend = nil

	local current = self.room:getCurrent()
	local wansha = current:hasShownSkill("wansha")
	local peach_num = self:getCardsNum("Peach")
	local null_num = self:getCardsNum("Nullification")
	local punish
	local enemies, kills = 0, 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not self.player:isFriendWith(p) and self:evaluateKingdom(p) ~= self.player:getKingdom() then enemies = enemies + 1 end
		if self:isFriend(p) then
			if not wansha then peach_num = peach_num + getCardsNum("Peach", p, self.player) end
			null_num = null_num + getCardsNum("Nullification", p, self.player)
		else
			null_num = null_num - getCardsNum("Nullification", p, self.player)
		end
	end
	if card:isVirtualCard() and card:subcardsLength() > 0 then
		for _, subcardid in sgs.qlist(card:getSubcards()) do
			local subcard = sgs.Sanguosha:getCard(subcardid)
			if isCard("Peach", subcard, self.player) then peach_num = peach_num - 1 end
			if isCard("Nullification", subcard, self.player) then null_num = null_num - 1 end
		end
	end

	local zhiman = self.player:hasSkill("zhiman")
	local zhimanprevent
	if card:isKindOf("SavageAssault") then
		local menghuo = sgs.findPlayerByShownSkillName("huoshou")
		attacker = menghuo or attacker
		if self:isFriend(attacker) and menghuo and menghuo:hasSkill("zhiman") then zhiman = true end
		if not self:isFriend(attacker) and menghuo:hasSkill("zhiman") then zhimanprevent = true end
	end

	local function getAoeValueTo(to)
		local value, sj_num = 0, 0
		local noresponse = false
		local noresponselist = card:getTag("NoResponse"):toStringList()--新增卡牌无法响应
		if noresponselist and (table.contains(noresponselist,to:objectName()) or table.contains(noresponselist,"_ALL_PLAYERS")) then
			noresponse = true
		end
		if card:isKindOf("ArcheryAttack") then
			sj_num = getCardsNum("Jink", to, self.player)
			if self:aoeIsEffective(card, to, self.player) then
				local sameKingdom
				if self:isFriend(to) then
					isEffective_F = isEffective_F + 1
					if self.player:isFriendWith(to) or self:evaluateKingdom(to) == self.player:getKingdom() then sameKingdom = true end
				else
					isEffective_E = isEffective_E + 1
				end

				local jink = sgs.cloneCard("jink")
				local isLimited
				if card:isKindOf("ArcheryAttack") and to:isCardLimited(jink, sgs.Card_MethodResponse) then isLimited = true end
				if card:isKindOf("ArcheryAttack") and (sgs.card_lack[to:objectName()]["Jink"] == 1 or sj_num < 1 or isLimited or noresponse) then
					if self:isFriend(to) and not zhiman then value = -20 end
				else
					if self:isFriend(to) and not zhiman then value = -10 end
				end
				-- value = value + math.min(50, to:getHp() * 10)

				if self:needDamagedEffects(to, self.player) then value = value + 30 end
				if self:needToLoseHp(to, self.player) then value = value + 20 end

				if to:hasShownSkills("leiji") and (sj_num >= 1 or self:hasEightDiagramEffect(to)) and self:findLeijiTarget(to, 50, self.player) then
					value = value + 20
					if self:hasSuit("spade", true, to) then value = value + 50
					else value = value + to:getHandcardNum() * 10
					end
				elseif self:hasEightDiagramEffect(to) then
					value = value + 5
					if self:getFinalRetrial(to) == 2 then
						value = value - 10
					elseif self:getFinalRetrial(to) == 1 then
						value = value + 10
					end
				end

				if sj_num >= 1 and to:hasShownSkill("xiaoguo") then value = value - 4 end
				if to:getHp() == 1 then
					if sameKingdom then
						if not zhiman then
							if null_num > 0 then null_num = null_num - 1
							elseif getCardsNum("Analeptic", to, self.player) > 0 then
							elseif not wansha and peach_num > 0 then peach_num = peach_num - 1
							elseif wansha and (getCardsNum("Peach", to, self.player) > 0 or self:isFriend(current) and getCardsNum("Peach", to, self.player) > 0) then
							else
								if not punish then
									punish = true
									value = value - self.player:getCardCount(true) * 10
								end
								value = value - to:getCardCount(true) * 10
								LuanjiFriend = true
							end
						end
					else
						kills = kills + 1
						if wansha and (sgs.card_lack[to:objectName()]["Peach"] == 1 or getCardsNum("Peach", to, self.player) == 0) then
							value = value - self:getReward(to) * 10
						end
					end
				end

				if not sgs.isAnjiang(to) and to:isLord() then value = value - self.room:getLieges(to:getKingdom(), to):length() * 5 end

				if to:getHp() > 1 and to:hasShownSkill("jianxiong") then
					value = value + ((card:isVirtualCard() and card:subcardsLength() * 10) or 10)
				end

			else
				value = 0
				if to:hasShownSkill("juxiang") and not card:isVirtualCard() then value = value + 10 end
			end
		elseif card:isKindOf("SavageAssault") then
			sj_num = getCardsNum("Slash", to, self.player)
			if self:aoeIsEffective(card, to, self.player) then
				local sameKingdom
				if self:isFriend(to) then
					isEffective_F = isEffective_F + 1
					if self.player:isFriendWith(to) or self:evaluateKingdom(to) == self.player:getKingdom() then sameKingdom = true end
				else
					isEffective_E = isEffective_E + 1
				end

				local slash = sgs.cloneCard("slash")
				local isLimited
				if card:isKindOf("SavageAssault") and to:isCardLimited(slash, sgs.Card_MethodResponse) then isLimited = true end
				if card:isKindOf("SavageAssault") and (sgs.card_lack[to:objectName()]["Slash"] == 1 or sj_num < 1 or isLimited or noresponse) then
					if self:isFriend(to) then
						if zhimanprevent then
							value = - 30
						elseif not zhiman then
							value = - 20
						end
					else
						if zhimanprevent and self:isFriend(to, attacker) then
							value = - 30
						else
							value = - 20
						end
					end
				else
					if self:isFriend(to) then
						if zhimanprevent then
							value = - 20
						elseif not zhiman then
							value = - 10
						end
					else
						if zhimanprevent and self:isFriend(to, attacker) then
							value = - 20
						else
							value = - 10
						end
					end
				end
				-- value = value + math.min(50, to:getHp() * 10)
				if self:needDamagedEffects(to, self.player) then value = value + 30 end
				if self:needToLoseHp(to, self.player) then value = value + 20 end

				if sj_num >= 1 and to:hasShownSkill("xiaoguo") then value = value - 4 end

				if to:getHp() == 1 then
					if sameKingdom then
						if not zhiman then
							if null_num > 0 then null_num = null_num - 1
							elseif getCardsNum("Analeptic", to, self.player) > 0 then
							elseif not wansha and peach_num > 0 then peach_num = peach_num - 1
							elseif wansha and (getCardsNum("Peach", to, self.player) > 0 or self:isFriend(current) and getCardsNum("Peach", to, self.player) > 0) then
							else
								if not punish then
									punish = true
									value = value - self.player:getCardCount(true) * 10
								end
								value = value - to:getCardCount(true) * 10
							end
						end
					else
						if zhiman and self:isFriend(to) then
						elseif zhimanprevent and self:isFriend(to, attacker) then
						else
							kills = kills + 1
							if wansha and (sgs.card_lack[to:objectName()]["Peach"] == 1 or getCardsNum("Peach", to, self.player) == 0) then
								value = value - self:getReward(to) * 10
							end
						end
					end
				end

				if not sgs.isAnjiang(to) and to:isLord() then value = value - self.room:getLieges(to:getKingdom(), to):length() * 5 end

				if to:getHp() > 1 and to:hasShownSkill("jianxiong") then
					value = value + ((card:isVirtualCard() and card:subcardsLength() * 10) or 10)
				end

			else
				value = 0
				if to:hasShownSkill("juxiang") and not card:isVirtualCard() then value = value + 10 end
			end
		end
		return value
	end

	local luretiger_friends = {}--调虎离山移除
	local num_luretiger = self:getCardsNum("LureTiger")
	if num_luretiger > 0 then
		self:sort(self.friends_noself, "hp")
		for _, f in ipairs(self.friends_noself) do
			if #luretiger_friends < num_luretiger*2 then--简单点，不需要写LureTiger:targetFilter吧
				table.insert(luretiger_friends,f)
			end
		end
	end

	for _, p in sgs.qlist(self.room:getOtherPlayers(attacker)) do
		--if p:objectName() == self.player:objectName() then continue end
		if self:isFriend(p) and not table.contains(luretiger_friends,p) then
			good = good + getAoeValueTo(p)
			if zhiman then
				if attacker:canGetCard(p, "j") then
					good = good + 10
				elseif attacker:canGetCard(p, "e") and p:hasShownSkills(sgs.lose_equip_skill) then
					good = good + 10
				end
			end
		else
			bad = bad + getAoeValueTo(p)
			if zhimanprevent and self:isFriend(p, attacker) then
				if attacker:canGetCard(p, "j") then
					bad = bad + 10
				elseif attacker:canGetCard(p, "e") and p:hasShownSkills(sgs.lose_equip_skill) then
					bad = bad + 10
				end
			end
		end
		if self:aoeIsEffective(card, p, self.player) and self:cantbeHurt(p, attacker) then bad = bad + 250 end
		if kills == enemies then return 998 end
	end

	local xuyou = sgs.findPlayerByShownSkillName("chenglve")
	local aoedraw = xuyou and attacker:isFriendWith(xuyou)

	if isEffective_F == 0 and isEffective_E == 0 then
		if attacker:hasShownSkill("jizhi") or aoedraw then
			return 10
		else
			return -100
		end
	elseif isEffective_E == 0 then
		return -100
	end

	if attacker:hasShownSkills("jizhi|wangxi") or aoedraw or attacker:getActualGeneral1():getKingdom() == "careerist" then
		good = good + 10
	end
	if attacker:hasShownSkill("luanji") then 
		good = good + 5 * isEffective_E 
		Global_room:writeToConsole("乱击AOE价值:"..tostring(good)..":"..tostring(bad))
	end
	--[[
	--旧乱击
	if attacker:hasShownSkill("luanji") then
		if not LuanjiFriend then
			good = good + (isEffective_E*isEffective_E)
		else
			good = good + 5 * isEffective_E
		end
	end
	--]]
	return good - bad
end

function SmartAI:trickIsEffective(card, to, from)
	if not card then Global_room:writeToConsole(debug.traceback()) return end
	from = from or self.room:getCurrent()
	to = to or self.player
	--if sgs.Sanguosha:isProhibited(from, to, card) then return false end
	if to:isRemoved() then return false end

	if from then
		if from:hasShownSkill("zhiman") and self:isFriend(to, from) and (card:isKindOf("Duel") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault")) then return false end
		if from:hasShownSkill("zhiman") and self:isFriend(to, from) and (card:isKindOf("FireAttack") or card:isKindOf("BurningCamps")) and not self:isGoodChainTarget(to, from, sgs.DamageStruct_Fire) then
			return false
		end
		if card:isKindOf("SavageAssault") then
			local menghuo = sgs.findPlayerByShownSkillName("huoshou")
			if menghuo and self:isFriend(to, menghuo) and menghuo:hasShownSkill("zhiman") then return false end
		end
	end

	if not card:isKindOf("TrickCard") then self.room:writeToConsole(debug.traceback()) return end
	if to:hasShownSkill("hongyan") and card:isKindOf("Lightning") then return false end
	if to:hasShownSkill("qianxun") and card:isKindOf("Snatch") then return false end
	if to:hasShownSkill("qianxun") and card:isKindOf("Indulgence") then return false end
	if card:isKindOf("Indulgence") then
		if to:hasSkills("jgjiguan_qinglong|jgjiguan_baihu|jgjiguan_zhuque|jgjiguan_xuanwu") then return false end
		if to:hasSkills("jgjiguan_bian|jgjiguan_suanni|jgjiguan_chiwen|jgjiguan_yazi") then return false end
	end
	if self:hasKnownSkill("weimu", to) and card:isBlack() then
		if from:objectName() == to:objectName() and card:isKindOf("Disaster") then
		else
			return false
		end
	end
	if to:hasShownSkill("kongcheng") and to:isKongcheng() and card:isKindOf("Duel") then return false end

	if card:isKindOf("IronChain") and not to:canBeChainedBy(from) then return false end

	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireAttack") or card:isKindOf("BurningCamps") then nature = sgs.DamageStruct_Fire
	elseif card:isKindOf("Drowning") then nature = sgs.DamageStruct_Thunder end

	if (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("BurningCamps") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault"))
		and not self:damageIsEffective(to, nature, from, card) then return false end
		
	if to:hasShownSkill("danlao") then
		if card:isKindOf("BurningCamps") then
			local targets = to:getFormation()
			if targets:length() == 1 then return true end
			local target_length = 0
			for _, p in sgs.qlist(targets) do
				if p:hasArmorEffect("IronArmor") then continue end
				target_length = target_length + 1
			end
			if target_length > 1 then return false end
		elseif card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
			local targets = self.room:getOtherPlayers(from)
			if targets:length() == 1 then return true end
			local target_length = 0
			for _, p in sgs.qlist(targets) do
				if p:hasShownSkill("weimu") and card:isBlack() then continue end
				target_length = target_length + 1
			end
			if target_length > 1 then return false end
		end
	end
	
	if to:hasArmorEffect("IronArmor") and (card:isKindOf("FireAttack") or card:isKindOf("BurningCamps")) then return false end

	return true
end

function SmartAI:trickProhibit(card, to, from)
	if not card then Global_room:writeToConsole(debug.traceback()) return end
	from = from or self.room:getCurrent()
	to = to or self.player
	for _, callback in pairs(sgs.ai_trick_prohibit) do
		if type(callback) == "function" then
			if callback(self, card, to, from) then return false end
		end
	end
end

function SmartAI:useTrickCard(card, use)
	if not card then Global_room:writeToConsole(debug.traceback()) return end
	--if self:needRende() and not card:isKindOf("ExNihilo") then return end
	self:useCardByClassName(card, use)
end

sgs.weapon_range = {}

function SmartAI:hasEightDiagramEffect(player)
	player = player or self.player
	if self.player and player:objectName() == self.player:objectName() then
		return player:hasArmorEffect("EightDiagram")
	else
		if player:getArmor() and player:getArmor():isKindOf("EightDiagram") then return true end
		local skill = sgs.Sanguosha:ViewHas(player, "EightDiagram", "armor")
		if skill and self:hasKnownSkill(skill:objectName(), player) then return true end--八阵无法暗着发动，这样判断无意义
	end
end

function SmartAI:hasCrossbowEffect(player)
	player = player or self.player
	local xuanhuo_paoxiao = false
	if player:hasSkill("xuanhuoattach") and player:getPhase() == sgs.Player_Play and not player:hasUsed("XuanhuoAttachCard") then
		local zhangfei = sgs.findPlayerByShownSkillName("paoxiao")
		if not zhangfei and getCardsNum("Slash", player) > 0 then
			local yongjue_slash = 0
			if player:getMark("GlobalPlayCardUsedTimes") == 0 then
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					if p:hasShownSkill("yongjue") and player:isFriendWith(p) then
						yongjue_slash = 1
						break
					end
				end
			end
			if getCardsNum("Slash", player) + player:getSlashCount() + yongjue_slash >= 2 then
				xuanhuo_paoxiao = true--似乎能一定程度解决眩惑弃杀的问题？还有问题
			end
		end
	end
	return (player:hasWeapon("Crossbow") or player:hasShownSkills("paoxiao|paoxiao_xh|kuangcai|guiling")
		or xuanhuo_paoxiao or (player:hasShownSkill("baolie") and player:getHp() < 3))
end

sgs.ai_weapon_value = {}

function SmartAI:evaluateWeapon(card, player, target)
	player = player or self.player
	local deltaSelfThreat = 0
	local inAttackRange
	local currentRange
	local enemies = target and { target } or self:getEnemies(player)
	if not card then self.room:writeToConsole(debug.traceback()) return -1
	else
		currentRange = sgs.weapon_range[card:getClassName()] or 0
	end

	local callback = sgs.ai_weapon_value[card:objectName()]
	local callback2 = sgs.ai_slash_weaponfilter[card:objectName()]

	for _, enemy in ipairs(enemies) do
		if player:distanceTo(enemy) <= currentRange then
			inAttackRange = true
			local def = sgs.getDefenseSlash(enemy, self) / 2
			if def < 0 then def = 6 - def
			elseif def <= 1 then def = 6
			else def = 6 / def
			end
			deltaSelfThreat = deltaSelfThreat + def
			if type(callback) == "function" then deltaSelfThreat = deltaSelfThreat + (callback(self, enemy, player) or 0) end
			if type(callback2) == "function" and callback2(self, enemy, player) then deltaSelfThreat = deltaSelfThreat + 1 end
		end
	end


	if card:isKindOf("Crossbow") and not player:hasShownSkills("paoxiao|kuangcai") and inAttackRange then
		local slash_num = player:objectName() == self.player:objectName() and self:getCardsNum("Slash") or getCardsNum("Slash", player, self.player)
		local analeptic_num = player:objectName() == self.player:objectName() and self:getCardsNum("Analeptic") or getCardsNum("Analeptic", player, self.player)
		local peach_num = player:objectName() == self.player:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", player, self.player)

		deltaSelfThreat = deltaSelfThreat + slash_num * 3 - 2
		--if player:hasShownSkill("kurou") then deltaSelfThreat = deltaSelfThreat + peach_num + analeptic_num + self.player:getHp() end--苦肉修改
		if player:getActualGeneral1():getKingdom() == "careerist" then deltaSelfThreat = deltaSelfThreat + 10 end--野心家角色
		if player:getWeapon() and not self:hasCrossbowEffect(player) and not player:canSlashWithoutCrossbow() and slash_num > 0 then
			for _, enemy in ipairs(enemies) do
				if player:distanceTo(enemy) <= currentRange
					and (sgs.card_lack[enemy:objectName()]["Jink"] == 1 or slash_num >= enemy:getHp()) then
					deltaSelfThreat = deltaSelfThreat + 10
				end
			end
		end
	end

	if player:hasShownSkill("jijiu") and card:isRed() then deltaSelfThreat = deltaSelfThreat + 0.5 end
	if player:hasShownSkills("qixi|guidao") and card:isBlack() then deltaSelfThreat = deltaSelfThreat + 0.5 end

	return deltaSelfThreat, inAttackRange
end

sgs.ai_armor_value = {}

function SmartAI:evaluateArmor(card, player)
	player = player or self.player
	local ecard = card or player:getArmor()
	if not ecard then return 0 end

	local value = 0
	if player:hasShownSkill("jijiu") and ecard:isRed() then value = value + 0.5 end
	if player:hasShownSkills("qixi|guidao") and ecard:isBlack() then value = value + 0.5 end
	for _, askill in sgs.qlist(player:getVisibleSkillList()) do
		local callback = sgs.ai_armor_value[askill:objectName()]
		if type(callback) == "function" then
			return value + (callback(ecard, player, self) or 0)
		end
	end
	local callback = sgs.ai_armor_value[ecard:objectName()]
	if type(callback) == "function" then
		return value + (callback(player, self) or 0)
	end
	return value + 0.5
end

function SmartAI:getSameEquip(card, player)
	player = player or self.player
	if not card then return end
	local get_SixDragons = false--考虑getMoveCardorTarget移动六龙
	for _, c in sgs.qlist(player:getCards("e")) do
		if c:isKindOf("SixDragons") then
			get_SixDragons = c
			break
		end
	end
	if card:isKindOf("Weapon") then return player:getWeapon()
	elseif card:isKindOf("Armor") then return player:getArmor()
	elseif card:isKindOf("DefensiveHorse") then return (player:getDefensiveHorse() or get_SixDragons)
	elseif card:isKindOf("OffensiveHorse") then return (player:getOffensiveHorse() or get_SixDragons)
	elseif card:isKindOf("Treasure") then return player:getTreasure()
	elseif card:isKindOf("SixDragons") then return (player:getDefensiveHorse() or player:getOffensiveHorse())
	end
end

function SmartAI:useEquipCard(card, use)
	if not card then Global_room:writeToConsole(debug.traceback()) return end
	if prohibitUseDirectly(card, self.player) then return end
	--考虑太平要术的手牌上限价值
	local PeaceSpell_loss = 0
	local lord_zhangjiao = sgs.findPlayerByShownSkillName("wendao")
	local erzhang = sgs.findPlayerByShownSkillName("guzheng")
	local PeaceSpell_MaxCards = self.player:getPlayerNumWithSameKingdom("AI")
	local armor = self.player:getArmor()
	if armor and armor:objectName() == "PeaceSpell" and card:isKindOf("Armor")
		and not (lord_zhangjiao and self.player:isFriendWith(lord_zhangjiao)) then
		for _, friend in ipairs(self.friends) do
			local need_extra_discard = 0
			local hand_card_num = friend:getHandcardNum()
			local max_card_num = friend:getMaxCards()
			--if not self.player:willBeFriendWith(friend) then continue end
			if not friend:objectName() == self.player:objectName() then continue end--太平要术修改
			if friend:hasShownSkill("keji") then continue end
			if friend:objectName() == self.player:objectName() then
				hand_card_num = hand_card_num + 2
				if self:getCardsNum("Peach") == 0 and self.player:getHp() > 1 then
					max_card_num = max_card_num - 1
				end
			end
			if friend:hasShownSkill("qiaobian") and hand_card_num-(max_card_num-PeaceSpell_MaxCards)>0 then 
				PeaceSpell_loss = PeaceSpell_loss + 1
				continue
			end	
			if hand_card_num <= max_card_num - PeaceSpell_MaxCards then continue end
			if hand_card_num >= max_card_num then
				need_extra_discard = PeaceSpell_MaxCards
			elseif hand_card_num < max_card_num and hand_card_num >= max_card_num - PeaceSpell_MaxCards then
				need_extra_discard = hand_card_num - (max_card_num - PeaceSpell_MaxCards)
			end
			if need_extra_discard <= 1 then continue end
			if erzhang and erzhang:isAlive() and not self.player:willBeFriendWith(erzhang) then
				PeaceSpell_loss = PeaceSpell_loss + (need_extra_discard - 1)*2
			else
				PeaceSpell_loss = PeaceSpell_loss + need_extra_discard
			end
		end
		if PeaceSpell_loss > PeaceSpell_MaxCards then return end
	end
	local use_lose_equip_effect = false
	if self.player:hasSkills(sgs.lose_equip_skill) then
		if self.player:hasSkill("xiaoji") then
			use_lose_equip_effect = true
		end
		if self.player:hasSkill("xuanlue") then
			local promo = self:findPlayerToDiscard("he", false, sgs.Card_MethodDiscard, nil, false)
			if promo then
				use_lose_equip_effect = true
			end
		end
	end
	local lvfan = sgs.findPlayerByShownSkillName("diaodu")--有吕范则类似枭姬使用武器是否合适？可能得调整优先度。如何先使用装备区的技能卡
	if lvfan and self.player:isFriendWith(lvfan) then
		use_lose_equip_effect = true
	end
	if use_lose_equip_effect and self:evaluateArmor(card) > -5 then
		local armor = self.player:getArmor()
		if not self.player:hasSkill("xiaoji") and armor and armor:objectName() == "PeaceSpell" and card:isKindOf("Armor") then
			if self:getCardsNum("Peach") == 0 and self.player:getHp() == 2 then
				return
			end
		end
		local same = self:getSameEquip(card)
		if same then
			if (self.player:hasSkills("qixi|duanliang|duanliang_egf") and same:isBlack())
				or (self.player:hasSkills("guose") and same:getSuit() == sgs.Card_Diamond)
				then return end
		end
		if card:isKindOf("Crossbow") then
			for _, hcard in sgs.qlist(self.player:getCards("h")) do
				if hcard:isKindOf("Weapon") and not hcard:isKindOf("Crossbow") then
					use.card = hcard
					return
				end
			end
		end
		if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow") then
			local slash = self:getCards("Slash", "he")
			local notuse = {}
			for _, s in ipairs(slash) do
				if sgs.Sanguosha:getCard(s:getEffectiveId()):isKindOf("EquipCard") and self.room:getCardPlace(s:getEffectiveId()) == sgs.Player_PlaceHand then
					table.insert(notuse, s)
				end
			end
			table.removeTable(slash, notuse)
			if #slash > 0 then
				local d_use = {isDummy = true,to = sgs.SPlayerList()}
				for _, s in ipairs(slash) do
					self:useCardSlash(s, d_use)
					if d_use.card then
						return
					end
				end
			end
		end
		--考虑使用顺序，最后用价值最高的装备
		for _, hcard in sgs.qlist(self.player:getCards("h")) do
			if hcard:toString() == card:toString() then continue end
			if (card:isKindOf("Weapon") and hcard:isKindOf("Weapon") and self:evaluateWeapon(card) > self:evaluateWeapon(hcard))
				or (card:isKindOf("Armor") and hcard:isKindOf("Armor") and self:evaluateArmor(card) > self:evaluateArmor(hcard)) then
				use.card = hcard
				return
			end
		end
		--已有宝物按通常处理
		if not (card:isKindOf("Treasure") and self.player:getTreasure()) then
			use.card = card
		end
		return
	end
--[[太平效果修改
	if self.player:hasSkill(sgs.lose_equip_skill) and self:evaluateArmor(card) > -5 and #self.enemies > 1 then

		local armor = self.player:getArmor()
		if armor and armor:objectName() == "PeaceSpell" and card:isKindOf("Armor") then
			if (self:getAllPeachNum() == 0 and self.player:getHp() < 3) and not (self.player:getHp() < 2) then
				-- and self:getCardsNum("Analeptic") > 0
				return
			end
		end
		use.card = card
		return
	end
--]]
	if self.player:getHandcardNum() == 1 and self.player:isLastHandCard(card)--考虑空城时,避免使用木牛里的牌
		and self:needKongcheng() and self:evaluateArmor(card) > -5 then
		local armor = self.player:getArmor()
		if armor and armor:objectName() == "PeaceSpell" and card:isKindOf("Armor") then
			if self:getCardsNum("Peach") == 0 and self.player:getHp() == 2 then
				return
			end
		end
		use.card = card
		return
	end
	if self.player:hasSkill("jili") and card:isKindOf("Weapon") then--沙摩柯武器
		if self.player:getCardUsedTimes(".") + self.player:getCardRespondedTimes(".") + 2 == sgs.weapon_range[card:getClassName()] + sgs.Sanguosha:correctAttackRange(self.player,true,false) then
			Global_room:writeToConsole("沙摩柯武器装备:" .. card:getClassName())
			use.card = card
		end
	end

	if card:isKindOf("PeaceSpell") then
		local lord_zhangjiao = sgs.findPlayerByShownSkillName("wendao") --有君张角在其他人（体力为2/有防具）则不装备太平要术
		if lord_zhangjiao and lord_zhangjiao:isAlive() then
			if self.player:objectName() ~= lord_zhangjiao:objectName() and (not self.player:getHp() == 2 or self.player:getArmor()) then
				return
			end
		end
	end
	if card:isKindOf("DragonPhoenix") then
		local lord_liubei = sgs.findPlayerByShownSkillName("zhangwu") --有君刘备在（其他势力/已有武器）不装备龙凤剑
		if lord_liubei and lord_liubei:isAlive() then
			if not self.player:isFriendWith(lord_liubei) or (self.player:objectName() ~= lord_liubei:objectName() and self.player:getWeapon()) then
				return
			end
		end
	end
	if card:isKindOf("LuminousPearl") then
		local lord_sunquan = sgs.findPlayerByShownSkillName("jubao") --有君孙权在（其他势力/已有宝物）不装备夜明珠
		if lord_sunquan and lord_sunquan:isAlive() then
			if not self.player:isFriendWith(lord_sunquan) or (self.player:objectName() ~= lord_sunquan:objectName() and self.player:getTreasure()) then
				return
			end
		end
	end
	if card:isKindOf("SixDragons") then
		local lord_caocao = sgs.findPlayerByShownSkillName("zongyu") --有君曹操在（其他势力且曹操有马）不装备六龙
		if lord_caocao and lord_caocao:isAlive() then
			if (not self.player:isFriendWith(lord_caocao) and (lord_caocao:getDefensiveHorse() or lord_caocao:getOffensiveHorse())) then
				return
			end
		end
		if self.player:getDefensiveHorse() and self.player:getOffensiveHorse() then--两匹马比一匹好
			return
		end
	end
	if card:isKindOf("ImperialEdict") then--宝物诏书
		use.card = card
		return
	end
	local same = self:getSameEquip(card)
	local zzzh = sgs.findPlayerByShownSkillName("guzheng")
	local isfriend_zzzh, isenemy_zzzh = false, false
	if zzzh then
		if self:isFriend(zzzh) then isfriend_zzzh = true
		else isenemy_zzzh = true
		end
	end
	if same then
		if (self.player:hasSkill("rende") and self:findFriendsByType(sgs.Friend_Draw))
			or (self.player:hasSkills("qixi|duanliang|duanliang_egf") and (card:isBlack() or same:isBlack()))
			or (self.player:hasSkills("guose") and (card:getSuit() == sgs.Card_Diamond or same:getSuit() == sgs.Card_Diamond))
			or (self.player:hasSkill("jijiu") and (card:isRed() or same:isRed()))
			or (self.player:hasSkill("guidao") and same:isBlack() and card:isRed())
			or isfriend_zzzh
			then return end
	end
	local canUseSlash = self:getCardId("Slash") and self:slashIsAvailable(self.player)
	self:useCardByClassName(card, use)
	if use.card then return end
	if card:isKindOf("Weapon") then
		if same and self.player:hasSkill("qiangxi") and not self.player:hasUsed("QiangxiCard") then
			local dummy_use = { isDummy = true }
			self:useSkillCard(sgs.Card_Parse("@QiangxiCard=" .. same:getEffectiveId().. "&qiangxi"), dummy_use)
			if dummy_use.card and dummy_use.card:getSubcards():length() == 1 then return end
		end
		if self.player:hasSkill("rende") then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getWeapon() then return end
			end
		end
		if self.player:hasSkills("paoxiao|kuangcai") and card:isKindOf("Crossbow") then return end
		if not self:needKongcheng() and not self.player:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= 0 and not canUseSlash then return end
		--if (not use.to) and self.player:getWeapon() and not self.player:hasSkills(sgs.lose_equip_skill) then return end
		if self.player:hasSkill("zhiheng") and not self.player:hasUsed("ZhihengCard") and self.player:getWeapon() and not card:isKindOf("Crossbow") then return end
		if not self:needKongcheng() and self.player:getHandcardNum() <= self.player:getHp() - 2 then return end
		if not self.player:getWeapon() or self:evaluateWeapon(card) > self:evaluateWeapon(self.player:getWeapon()) then
			use.card = card
		end
	elseif card:isKindOf("Armor") then
		local lion = self:getCard("SilverLion")
		if lion and self.player:isWounded() and not self.player:hasArmorEffect("SilverLion") and not card:isKindOf("SilverLion")
			and not (self.player:hasSkills("bazhen|jgyizhong") and not self.player:getArmor()) then
			use.card = lion
			return
		end
		if self.player:hasSkill("rende") and self:evaluateArmor(card) < 4 then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getArmor() then return end
			end
		end
		if self.player:hasSkill("yujia") then use.card = card end
		if self:evaluateArmor(card) > self:evaluateArmor() or (isenemy_zzzh and self:getOverflow() > 1) then use.card = card end
		return
	elseif card:isKindOf("OffensiveHorse") then
		if self.player:hasSkill("rende") then
			for _,friend in ipairs(self.friends_noself) do
				if not friend:getOffensiveHorse() then return end
			end
			use.card = card
			return
		elseif self.player:hasSkill("zaoyun") then--新增zaoyun
			local dist_morethan2 = false
			for _,p in ipairs(self.enemies) do
				if self.player:distanceTo(p) > 2 then
					dist_morethan2 = true
				end
			end
			if not dist_morethan2 then
				return
			end
		else
			if not self.player:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= 0 and not (canUseSlash or self:getCardId("Snatch")) then
				return
			else
				if self.lua_ai:useCard(card) then
					use.card = card
					return
				end
			end
		end
	elseif card:isKindOf("DefensiveHorse") then
		local tiaoxin = true
		if self.player:hasSkill("tiaoxin") then
			local dummy_use = { isDummy = true, defHorse = true }
			self:useSkillCard(sgs.Card_Parse("@TiaoxinCard=.&tiaoxin"), dummy_use)
			if not dummy_use.card then tiaoxin = false end
		end
		if tiaoxin and self.lua_ai:useCard(card) then
			use.card = card
		end
	elseif card:isKindOf("Treasure") then
		if self.player:hasSkill("yongsi") and card:isKindOf("JadeSeal") then
			return
		end
		if self.player:getTreasure() and self.player:getTreasure():isKindOf("WoodenOx") then
			for _, skill in ipairs(sgs.ai_skills) do
				if skill.name == "WoodenOx" then
					local skill_card = skill.getTurnUseCard(self)
					if self.player:getPhase() == sgs.Player_Play and skill_card then--仅出牌阶段,防止回合外选择使用宝物时触发木牛转移
						use.card = skill_card
						return
					elseif self.player:getPile("wooden_ox"):length() > 1 and not card:isKindOf("JadeSeal") then
						return
					end
				end
			end
		end
		if self.player:getTreasure() and self.player:getTreasure():isKindOf("LuminousPearl") and not self.player:hasUsed("ZhihengCard") and not self.player:hasUsed("ZhihengLPCard") then
			local skill_card = sgs.Card_Parse("@ZhihengCard=.")
			if self.player:getPhase() == sgs.Player_Play and skill_card then--仅出牌阶段,防止回合外选择使用宝物时触发夜明珠制衡
				sgs.ai_skill_use_func["ZhihengCard"](skill_card, use, self)
				return
			end
		end
		if not self.player:getTreasure() then
			if #self.friends_noself > 0 then
				for _, hcard in sgs.qlist(self.player:getCards("h")) do
					if hcard:isKindOf("WoodenOx") and not hcard:toString() ~= card:toString() then
						use.card = hcard
						return
					end
				end
			end
			for _, hcard in sgs.qlist(self.player:getCards("h")) do
				if hcard:isKindOf("LuminousPearl") and not hcard:toString() ~= card:toString() then
					use.card = hcard
					return
				end
			end
		end
		if card:isKindOf("LuminousPearl") and (self:getOverflow() > 0 or not self.player:getTreasure() or not self.player:getTreasure():isKindOf("JadeSeal")) then
			local should_use = false
			for _, hcard in sgs.qlist(self.player:getCards("h")) do
				if hcard:isKindOf("Treasure") and not hcard:toString() ~= card:toString() then
					should_use = true
					break
				end
			end
			local lord_sunquan = sgs.findPlayerByShownSkillName("jubao")
			if should_use or not lord_sunquan or self:isFriend(lord_sunquan) then
				use.card = card
			end
		end
		if not self.player:getTreasure() or card:isKindOf("JadeSeal") then
			use.card = card
		end
	elseif self.lua_ai:useCard(card) then
		use.card = card
	end
end

function SmartAI:needRende()
	return (self.player:hasSkill("rende") and self.player:getMark("rende") < 2)
			and self.player:getLostHp() > 1 and self:findFriendsByType(sgs.Friend_Draw)
end

function SmartAI:needToLoseHp(to, from, isSlash, passive, recover)
	to = to or self.player
	if isSlash and from and from:hasWeapon("IceSword") and to:getCardCount(true) > 1 and not self:isFriend(from, to) then
		return false
	end
	if from and self:hasHeavySlashDamage(from, nil, to) then return false end
	local n = to:getMaxHp()
	local current = self.room:getCurrent()
	local players_num = self.room:alivePlayerCount()
	local round_enemy_num = 0
	if current and to:objectName() ~= current:objectName() then
		round_enemy_num = self:getEnemyNumBySeat(current, to, to)
	else
		round_enemy_num = players_num - #(self:getFriends(to))
	end
	if not passive then
		local lvlingqi = sgs.findPlayerByShownSkillName("shenwei")
		if lvlingqi and lvlingqi:isAlive() and to:isFriendWith(lvlingqi) and lvlingqi:getHp() >= 3 and to:getHp() > lvlingqi:getHp() then
			n = lvlingqi:getHp()
		elseif to:hasShownSkill("rende") and to:getMaxHp() > 2 and not self:willSkipPlayPhase(to) and self:findFriendsByType(sgs.Friend_Draw, to) then
			n = math.min(n, to:getMaxHp() - 1)
		--elseif to:hasShownSkills("yinghun_sunjian|yinghun_sunce") then
		elseif to:hasShownSkill("shangshi") and to:getMaxHp() > 2 and self:findFriendsByType(sgs.Friend_Draw, to) then
			n = math.min(n, to:getMaxHp() - 1)
		elseif to:hasShownSkill("hunshang") then
			n = 1
			if round_enemy_num > 0 then n = 2 end
		end
	end

	local xiangxiang = sgs.findPlayerByShownSkillName("jieyin")
	if xiangxiang and xiangxiang:isWounded() and self:isFriend(xiangxiang, to) and not to:isWounded() and to:isMale()
		and (xiangxiang:getPhase() == sgs.Player_Play and xiangxiang:getHandcardNum() >= 2 and not xiangxiang:hasUsed("JieyinCard")
			or self:getEnemyNumBySeat(self.room:getCurrent(), xiangxiang, self.player) <= 1) then
										   
		local need_jieyin = true
		if from and from:objectName() == xiangxiang:objectName() and xiangxiang:getHandcardNum() <= 2 then need_jieyin = false end
		--防止香香2手牌杀队友(3牌丈八杀队友怎么办……)
		local friends = self:getFriendsNoself(to)
		self:sort(friends, "hp")
		for _, friend in ipairs(friends) do
			if friend:objectName() == xiangxiang:objectName() then continue end
			if friend:isMale() and friend:isWounded() then need_jieyin = false end
		end
		if need_jieyin then n = math.min(n, to:getMaxHp() - 1) end
	end

	if to:hasShownSkill("hengzheng") and sgs.ai_skill_invoke.hengzheng(sgs.ais[to:objectName()]) and to:getHandcardNum() ~= 0
		and not self:willSkipPlayPhase(to) and not to:containsTrick("supply_shortage") then
		if (recover and to:getHp() == 1) or (not recover and to:getHp() == 2) then
			from = from or self.player
			local peach_num = to:objectName() == from:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", to, from)
			for _, friend in ipairs(self:getFriendsNoself(to)) do
				if to:isFriendWith(friend) and not self:isWeak(friend) then
					local friend_peach = self.player:objectName() == friend:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", friend, from)
					peach_num = peach_num + friend_peach
				end
			end
			if peach_num > 0 or to:hasShownSkills("duanchang|buqu") then
				return true
			end
		end
	end
	
	if to:hasShownSkill("jgkonghun") then
		local need_lose = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(to)) do
			if not to:isFriendWith(p) then
				need_lose = need_lose + 1
			end
		end
		if to:getHp() > 1 and to:getHp() - 1 == to:getMaxHp() - need_lose then
			return true
		end
	end
	
	if recover then return to:getHp() >= n end

	return to:getHp() > n
end

function IgnoreArmor(from, to)
	if not from or not to then Global_room:writeToConsole(debug.traceback()) return end
	if not to:getArmor() then return true end
	if not to:hasArmorEffect(to:getArmor():objectName()) or from:hasWeapon("QinggangSword") then
		return true
	end
	if from:hasShownSkill("guiling") then return true end
	if from:hasShownSkills("paoxiao|paoxiao_xh") then
		local lord_liubei = sgs.findPlayerByShownSkillName("shouyue")
		if lord_liubei and lord_liubei:isAlive() and from:isFriendWith(lord_liubei) then
			return true
		end
	end
	return false
end

function SmartAI:needToThrowArmor(player)
	player = player or self.player
	if not player:getArmor() or not player:hasArmorEffect(player:getArmor():objectName()) then return false end
	if player:hasShownSkill("bazhen") and not(player:getArmor():isKindOf("EightDiagram") or player:getArmor():isKindOf("RenwangShield") or player:getArmor():isKindOf("PeaceSpell")) then return true end
	if self:evaluateArmor(player:getArmor(), player) <= -2 then return true end
	if self.player:hasShownSkill("yujia") then return true end
	if player:hasArmorEffect("SilverLion") and player:isWounded() and player:canRecover() 
		and not self:needToLoseHp(player, nil, nil, true, true) then
		if self:isFriend(player) then
			if player:objectName() == self.player:objectName() then
				return true
			else
				return self:isWeak(player) and not player:hasShownSkills(sgs.use_lion_skill)
			end
		else
			return true
		end
	end
	if player:hasArmorEffect("PeaceSpell") then
		--防传导
		if player:isChained() and not self:isGoodChainTarget(player, self.player, sgs.DamageStruct_Thunder, 1) then return false end
		if self:needToLoseHp(player) then return true end
		--新增一血太平摸牌，空城？1牌？
		if player:getHp() == 1 and player:getHandcardNum() <= 2 and not self:needKongcheng(player) then
			if player:getPhase() == sgs.Player_NotActive and isCard("Peach", player:getArmor(), player) then--急救等
				return false
			elseif player:getPhase() < sgs.Player_Discard then
				local hand_card_num = player:getHandcardNum() + 2
				local PeaceSpell_MaxCards = player:getPlayerNumWithSameKingdom("AI")
				local max_card_num = player:getMaxCards() - PeaceSpell_MaxCards
				if hand_card_num-max_card_num>0 then return false end--因此弃牌
			end
			return true
		end
		if player:hasShownSkill("hongfa") and not player:containsTrick("indulgence") and not player:getPile("heavenly_army"):isEmpty() then
			local current = self.room:getCurrent()
			local players_num = self.room:alivePlayerCount()
			local round_num = self:playerGetRound(current, player)
			if player:objectName() ~= current:objectName() then
				round_num = self:playerGetRound(current, player)
			else
				round_num = players_num
			end
			if player:hasShownSkill("wendao") then
				if not player:hasUsed("WendaoCard") and self.room:getDrawPile():length() >= 5*round_num then--尽可能过牌
					return true
				elseif self.room:getDrawPile():length() < 5*round_num then--防止洗入摸牌堆
					return false
				end
			end
		end
	end
	
	if player:hasArmorEffect("Vine") then
		if self:needToLoseHp(player) or self:needDamagedEffects(player) then return true end
		local damage = self.room:getTag("CurrentDamageStruct")
		if damage.damage and not damage.chain and not damage.prevented and damage.nature == sgs.DamageStruct_Fire
			and damage.to:isChained() and player:isChained() then
			return true
		end
	end
	return false
end

function SmartAI:doNotDiscard(to, flags, conservative, n, cant_choose)
	if not to then Global_room:writeToConsole(debug.traceback()) return end
	n = n or 1
	flags = flags or "he"
	if to:isNude() then return true end
	if flags == "he" and to:isKongcheng() then flags = "e" end
	if flags == "he" and not to:hasEquip() then flags = "h" end
	conservative = conservative or (sgs.turncount <= 2 and self.room:alivePlayerCount() > 2)
	local enemies = self:getEnemies(to)
	if #enemies == 1 and enemies[1]:hasShownSkills("qianxun|weimu") and self.room:alivePlayerCount() == 2 then conservative = false end
	if to:hasShownSkill("tuntian") and to:getPhase() == sgs.Player_NotActive then
		if to:hasShownSkills("tiandu|zhuwei") and getCardsNum("Peach", to, self.player) + getCardsNum("Analeptic", to, self.player) <= 0 and n <= 1 then return true end
		if to:hasShownSkill("jixi") and (conservative or to:getPlayerNumWithSameKingdom("AI") > 1) and not self:isWeak(to) then return true end
	end
	if to:hasShownSkill("diancai") and self.player:getPhase() == sgs.Player_Play and to:getMaxHp() >= to:getHandcardNum()
		and n <= 1 and to:getMark("GlobalLoseCardCount") < to:getHp() and to:getMark("GlobalLoseCardCount") + n >= to:getHp() then 
		if to:getMaxHp() - to:getHandcardNum() >= ((flags == "h") and 1 or 2) then return true end
	end
	if cant_choose then
		if to:hasShownSkill("lirang") and #(self:getFriendsNoself(to)) > 0 and not self:isWeak(to) then return true end
		if self:needKongcheng(to) and to:getHandcardNum() <= n then return true end
		if self:getLeastHandcardNum(to) > n then return true end--弃n牌时,若不能弃到装备,等于让对方换牌
		if to:hasShownSkills(sgs.lose_equip_skill) and to:hasEquip() then return true end
		if self:needToThrowArmor(to) then return true end
		if to:hasArmorEffect("PeaceSpell") and to:getHp() == 1 then return true end
	else
		if flags:match("e") then
			if to:hasShownSkills("jieyin+xiaoji") and to:getDefensiveHorse() then return false end
			if to:hasShownSkills("jieyin+xiaoji") and to:getArmor() and not to:getArmor():isKindOf("SilverLion") then return false end
		end
		if flags == "h" or (flags == "he" and not to:hasEquip()) then
			if to:isKongcheng() or not self.player:canDiscard(to, "h") then return true end
			if not self:hasLoseHandcardEffective(to) then return true end
			if to:getHandcardNum() == 1 and self:needKongcheng(to) then return true end
			if to:getHandcardNum() == 1 and to:hasShownSkill("hengzheng") and to:getHp() ~= 1 then return true end
			if #self.friends > 1 and to:getHandcardNum() == 1 and to:hasShownSkill("sijian") then return false end
		elseif flags == "e" or (flags == "he" and to:isKongcheng()) then
			if not to:hasEquip() then return true end
			if to:hasShownSkills(sgs.lose_equip_skill) then return true end
			if to:getCardCount(true) == 1 and self:needToThrowArmor(to) then return true end
		end
		if flags == "he" and n == 2 then
			if not self.player:canDiscard(to, "e") then return true end
			if to:getCardCount(true) < 2 then return true end
			if not to:hasEquip() then
				if not self:hasLoseHandcardEffective(to) then return true end
				if to:getHandcardNum() <= 2 and self:needKongcheng(to) then return true end
			end
			if to:hasShownSkills(sgs.lose_equip_skill) and to:getHandcardNum() < 2 then return true end
			if to:getCardCount(true) <= 2 and self:needToThrowArmor(to) then return true end
		end
	end
	if flags == "he" and n > 2 then
		if not self.player:canDiscard(to, "e") then return true end
		if to:getCardCount(true) < n then return true end
	end
	return false
end

function SmartAI:findPlayerToDiscard(flags, include_self, method, players, return_table)
	local player_table = {}
--[[
	local isDiscard, isGet
	if not method or method == sgs.Card_MethodDiscard then isDiscard = true end
	if method and method == sgs.Card_MethodGet then isGet = true end
]]
	local friends, enemies = {}, {}
	flags = flags or "he"

	local canOperate = function(target, card_id)--注意card_id为字符串的重载
		local wujing = sgs.findPlayerByShownSkillName("fengyang")
		if wujing and wujing:inFormationRalation(target) and not self.player:isFriendWith(target) then
			if (type(card_id) == "number" and self.room:getCardPlace(card_id) == sgs.Player_PlaceEquip) or
			(type(card_id) == "string" and card_id == "e") then
				return false
			end
			if type(card_id) == "string" and card_id:match("e") then
				local str = ""
				if card_id:match("h") then
					str = str .. "h"
				end
				if card_id:match("j") then
					str = str .. "j"
				end
				if str ~= "" then
					card_id = str
				end
			end
		end
		if method and method == sgs.Card_MethodGet then
			if target:hasSkill("jubao") and type(card_id) == "number"
			and target:getTreasure() and target:getTreasure():getEffectiveId() == card_id then
				return false
			end
			return self.player:canGetCard(target, card_id)
		else
			return self.player:canDiscard(target, card_id)
		end
	end

	if not players then
		for _, p in ipairs(self.friends_noself) do
			if canOperate(p, flags) then
				table.insert(friends, p)
			end
		end
		if include_self then table.insert(friends, self.player) end
		for _, p in ipairs(self.enemies) do
			if canOperate(p, flags) then
				table.insert(enemies, p)
			end
		end
	else
		for _, player in sgs.qlist(players) do
			if self:isFriend(player) and canOperate(player, flags) and (include_self or player:objectName() ~= self.player:objectName()) then
				table.insert(friends, player)
			elseif self:isEnemy(player) and canOperate(player, flags) then
				table.insert(enemies, player)
			end
		end
	end

	self:sort(enemies, "defense")
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			local dangerous = self:getDangerousCard(enemy)
			if dangerous and canOperate(enemy, dangerous) then
				table.insert(player_table, enemy)
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:getArmor() and enemy:getArmor():isKindOf("EightDiagram") and not self:needToThrowArmor(enemy)
			and canOperate(enemy, enemy:getArmor():getEffectiveId()) then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("j") then
		for _, friend in ipairs(friends) do
			if canOperate(friend, "j") then
				if ((friend:containsTrick("indulgence") and not friend:hasShownSkills("keji")) or friend:containsTrick("supply_shortage"))
					and not (friend:hasShownSkill("qiaobian") and not friend:isKongcheng()) then
					table.insert(player_table, friend)
				end
			end
		end
		for _, friend in ipairs(friends) do
			if friend:containsTrick("lightning") and self:hasWizard(enemies, true) and canOperate(friend, "j") then
				table.insert(player_table, friend)
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("lightning") and self:hasWizard(enemies, true) and canOperate(enemy, "j") then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("e") then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) and canOperate(friend, friend:getArmor():getEffectiveId()) then
				table.insert(player_table, friend)
			end
		end
		for _, enemy in ipairs(enemies) do
			local valuable = self:getValuableCard(enemy)
			if valuable and canOperate(enemy, valuable) then
				table.insert(player_table, enemy)
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasShownSkills("jijiu|beige|weimu|qingcheng") and not self:doNotDiscard(enemy, "e") then
				if enemy:getDefensiveHorse()
					and canOperate(enemy, enemy:getDefensiveHorse():getEffectiveId()) then
					table.insert(player_table, enemy)
				end
				if enemy:getArmor() and not self:needToThrowArmor(enemy)
					and canOperate(enemy, enemy:getArmor():getEffectiveId()) then
					table.insert(player_table, enemy)
				end
				if enemy:getOffensiveHorse() and (not enemy:hasShownSkill("jijiu") or enemy:getOffensiveHorse():isRed())
					and canOperate(enemy, enemy:getOffensiveHorse():getEffectiveId()) then
					table.insert(player_table, enemy)
				end
				if enemy:getWeapon() and (not enemy:hasShownSkill("jijiu") or enemy:getWeapon():isRed())
					and canOperate(enemy, enemy:getWeapon():getEffectiveId()) then
					table.insert(player_table, enemy)
				end
			end
		end
	end

	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			local cards = sgs.QList2Table(enemy:getHandcards())
			if #cards <= 2 and not enemy:isKongcheng() and not (enemy:hasShownSkill("tuntian") and enemy:getPhase() == sgs.Player_NotActive) then
				for _, cc in ipairs(cards) do
					if sgs.cardIsVisible(cc, enemy, self.player) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic"))
						and canOperate(enemy, cc:getId()) then
						table.insert(player_table, enemy)
					end
				end
			end
		end
	end

	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if enemy:hasEquip() and not self:doNotDiscard(enemy, "e")
				and canOperate(enemy, "e") then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("h") then
		self:sort(enemies, "handcard")
		for _, enemy in ipairs(enemies) do
			if canOperate(enemy, "h") then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("h") then
		local zhugeliang = sgs.findPlayerByShownSkillName("kongcheng")
		if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, zhugeliang) > 0
			and zhugeliang:getHp() <= 2 and canOperate(zhugeliang, "h") then
			table.insert(player_table, zhugeliang)
		end
	end
	if return_table then return player_table
	else
		if #player_table == 0 then return nil else return player_table[1] end
	end
end

function SmartAI:findCardsToDiscard(flags, include_self, method, players, onebyone)
	local player_table = {}
	local isDiscard, isGet
	if not method or method == sgs.Card_MethodDiscard then isDiscard = true end
	if method and method == sgs.Card_MethodGet then isGet = true end
	local friends, enemies = {}, {}
	flags = flags or "he"
	if not players then
		for _, p in ipairs(self.friends_noself) do
			if isDiscard and not self.player:canDiscard(p, flags) then continue end
			if isGet and not self.player:canGetCard(p, flags) then continue end
			if self:isFriend(p) then
				table.insert(friends, p)
			end
		end
		if include_self then table.insert(friends, self.player) end
		for _, p in ipairs(self.enemies) do
			if isDiscard and not self.player:canDiscard(p, flags) then continue end
			if isGet and not self.player:canGetCard(p, flags) then continue end
			table.insert(enemies, p)
		end
	else
		for _, player in sgs.qlist(players) do
			if isDiscard and not self.player:canDiscard(player, flags) then continue end
			if isGet and not self.player:canGetCard(player, flags) then continue end
			if self:isFriend(player) and (include_self or player:objectName() ~= self.player:objectName()) then
				table.insert(friends, player)
			elseif self:isEnemy(player) then
				table.insert(enemies, player)
			end
		end
	end

	local check = function(ids, player)
		if not onebyone then return true end
		for _, id in ipairs(ids) do
			if self.room:getCardOwner(id):objectName() == player:objectName() then return false end
		end
		return true
	end

	self:sort(enemies, "defense")
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			local dangerous = self:getDangerousCard(enemy)
			if dangerous and ((isDiscard and self.player:canDiscard(enemy, dangerous)) or (isGet and self.player:canGetCard(enemy, dangerous))) then
				if check(player_table, enemy) then table.insert(player_table, dangerous) end
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:getArmor() and enemy:getArmor():isKindOf("EightDiagram") and not self:needToThrowArmor(enemy)
				and ((isDiscard and self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) or (isGet and self.player:canGetCard(enemy, enemy:getArmor():getEffectiveId()))) then
				if check(player_table, enemy) then table.insert(player_table, enemy:getArmor():getEffectiveId()) end
			end
		end
	end

	if flags:match("j") then
		for _, friend in ipairs(friends) do
			if (isDiscard and self.player:canDiscard(friend, "j")) or (isGet and self.player:canGetCard(friend, "j")) then
				if ((friend:containsTrick("indulgence") and not friend:hasShownSkills("keji")) or friend:containsTrick("supply_shortage"))
					and not (friend:hasShownSkill("qiaobian") and not friend:isKongcheng()) then
					for _, card in sgs.qlist(friend:getJudgingArea()) do
						if card:isKindOf("indulgence") and check(player_table, friend) then
							table.insert(player_table, card:getEffectiveId())
						end
						if card:isKindOf("supply_shortage") and check(player_table, friend) then
							table.insert(player_table, card:getEffectiveId())
						end
					end
				end
			end
		end
		for _, friend in ipairs(friends) do
			if friend:containsTrick("lightning") and self:hasWizard(enemies, true) and ((isDiscard and self.player:canDiscard(friend, "j")) or (isGet and self.player:canGetCard(friend, "j"))) then
				for _, card in sgs.qlist(friend:getJudgingArea()) do
					if card:isKindOf("lightning") and check(player_table, friend) then
						table.insert(player_table, card:getEffectiveId())
					end
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("lightning") and self:hasWizard(enemies, true) and ((isDiscard and self.player:canDiscard(enemy, "j")) or (isGet and self.player:canGetCard(enemy, "j"))) then
				for _, card in sgs.qlist(enemy:getJudgingArea()) do
					if card:isKindOf("lightning") and check(player_table, enemy) then
						table.insert(player_table, card:getEffectiveId())
					end
				end
			end
		end
	end

	if flags:match("e") then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) and ((isDiscard and self.player:canDiscard(friend, friend:getArmor():getEffectiveId())) or (isGet and self.player:canGetCard(friend, friend:getArmor():getEffectiveId()))) then
				if check(player_table, friend) then table.insert(player_table, friend:getArmor():getEffectiveId()) end
			end
		end
		for _, enemy in ipairs(enemies) do
			local valuable = self:getValuableCard(enemy)
			if valuable and ((isDiscard and self.player:canDiscard(enemy, valuable)) or (isGet and self.player:canGetCard(enemy, valuable))) then
				if check(player_table, enemy) then table.insert(player_table, valuable) end
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasShownSkills("jijiu|beige|weimu|qingcheng") and not self:doNotDiscard(enemy, "e") then
				if enemy:getDefensiveHorse()
					and ((isDiscard and self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) or (isGet and self.player:canGetCard(enemy, enemy:getDefensiveHorse():getEffectiveId()))) then
					if check(player_table, enemy) then table.insert(player_table, enemy:getDefensiveHorse():getEffectiveId()) end
				end
				if enemy:getArmor() and not self:needToThrowArmor(enemy)
					and ((isDiscard and self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) or (isGet and self.player:canGetCard(enemy, enemy:getArmor():getEffectiveId()))) then
					if check(player_table, enemy) then table.insert(player_table, enemy:getArmor():getEffectiveId()) end
				end
				if enemy:getOffensiveHorse() and (not enemy:hasShownSkill("jijiu") or enemy:getOffensiveHorse():isRed())
					and ((isDiscard and self.player:canDiscard(enemy, enemy:getOffensiveHorse():getEffectiveId())) or (isGet and self.player:canGetCard(enemy, enemy:getOffensiveHorse():getEffectiveId()))) then
					if check(player_table, enemy) then table.insert(player_table, enemy:getOffensiveHorse():getEffectiveId()) end
				end
				if enemy:getWeapon() and (not enemy:hasShownSkill("jijiu") or enemy:getWeapon():isRed())
					and ((isDiscard and self.player:canDiscard(enemy, enemy:getWeapon():getEffectiveId())) or (isGet and self.player:canGetCard(enemy, enemy:getWeapon():getEffectiveId()))) then
					if check(player_table, enemy) then table.insert(player_table, enemy:getOffensiveHorse():getEffectiveId()) end
				end
			end
		end
	end

	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			local cards = sgs.QList2Table(enemy:getHandcards())
			if #cards <= 2 and not enemy:isKongcheng() and not (enemy:hasShownSkill("tuntian") and enemy:getPhase() == sgs.Player_NotActive) then
				for _, cc in ipairs(cards) do
					if sgs.cardIsVisible(cc, enemy, self.player) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic"))
						and ((isDiscard and self.player:canDiscard(enemy, cc:getId())) or (isGet and self.player:canGetCard(enemy, cc:getId()))) then
						if check(player_table, enemy) then table.insert(player_table, cc:getEffectiveId()) end
					end
				end
			end
		end
	end

	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if enemy:hasEquip() and not self:doNotDiscard(enemy, "e")
				and ((isDiscard and self.player:canDiscard(enemy, "e")) or (isGet and self.player:canGetCard(enemy, "e"))) then
				for _, e in sgs.qlist(enemy:getEquips()) do
					if check(player_table, enemy) then table.insert(player_table, e:getEffectiveId()) end
				end
			end
		end
	end

	if flags:match("h") then
		self:sort(enemies, "handcard")
		for _, enemy in ipairs(enemies) do
			if ((isDiscard and self.player:canDiscard(enemy, "h")) or (isGet and self.player:canGetCard(enemy, "h"))) and not self:doNotDiscard(enemy, "h") then
				for _, id in sgs.qlist(enemy:handCards()) do
					if check(player_table, enemy) then table.insert(player_table, id) end
				end
			end
		end
	end

	if flags:match("h") then
		local zhugeliang = sgs.findPlayerByShownSkillName("kongcheng")
		if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, zhugeliang) > 0
			and zhugeliang:getHp() <= 2 and ((isDiscard and self.player:canDiscard(zhugeliang, "h")) or (isGet and self.player:canGetCard(zhugeliang, "h"))) then
			for _, id in sgs.qlist(zhugeliang:handCards()) do
				if check(player_table, zhugeliang) then table.insert(player_table, id) end
			end
		end
	end
	return player_table
end

function SmartAI:findPlayerToDraw(include_self, drawnum)
	drawnum = drawnum or 1
	local players = sgs.QList2Table(include_self and self.room:getAllPlayers() or self.room:getOtherPlayers(self.player))
	local friends = {}
	for _, player in ipairs(players) do
		if self:isFriend(player) and not (player:hasShownSkill("kongcheng") and player:isKongcheng() and drawnum <= 2) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return end

	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and (AssistTarget:getHandcardNum() < 10 or self.player:getHandcardNum() > AssistTarget:getHandcardNum()) then
		for _, friend in ipairs(friends) do
			if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if friend:hasShownSkills(sgs.cardneed_skill) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	self:sort(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) then
			return friend
		end
	end
	return nil
end

function SmartAI:dontRespondPeachInJudge(judge)
	if not judge or type(judge) ~= "JudgeStruct" then self.room:writeToConsole(debug.traceback()) return end
	local peach_num = self:getCardsNum("Peach")
	if peach_num == 0 then return false end
	if self:willSkipPlayPhase() and self:getCardsNum("Peach") > self:getOverflow(self.player, true) then return false end
	if judge.reason == "lightning" and self:isFriend(judge.who) then return false end

	local card = self:getCard("Peach")
	local dummy_use = { isDummy = true }
	self:useBasicCard(card, dummy_use)
	if dummy_use.card then return true end

	if peach_num <= self.player:getLostHp() then return true end

	if peach_num > self.player:getLostHp() then
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend) then return true end
		end
	end

	if (judge.reason == "EightDiagram" or judge.reason == "bazhen") and
		self:isFriend(judge.who) and (not self:isWeak(judge.who) or judge.who:hasShownSkills(sgs.masochism_skill)) then return true
	elseif judge.reason == "tieqi" then return true
	elseif judge.reason == "qianxi" then return true
	elseif judge.reason == "beige" then return true
	end

	return false
end



function SmartAI:AssistTarget()
	if sgs.ai_AssistTarget_off then return end
	local human_count, player = 0, nil
	if not sgs.ai_AssistTarget then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getState() ~= "robot" then
				human_count = human_count + 1
				player = p
			end
		end
		if human_count == 1 and player then
			sgs.ai_AssistTarget = player
		else
			sgs.ai_AssistTarget_off = true
		end
	end
	player = sgs.ai_AssistTarget
	if player and not player:getAI() and player:isAlive() and self:isFriend(player) and player:objectName() ~= self.player:objectName() then return player end
end

function SmartAI:findFriendsByType(prompt, player)
	player = player or self.player
	local friends = self:getFriendsNoself(player)
	if #friends < 1 then return false end
	if prompt == sgs.Friend_Draw then
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) then return true end
		end
	elseif prompt == sgs.Friend_Male then
		for _, friend in ipairs(friends) do
			if friend:isMale() then return true end
		end
	elseif prompt == sgs.Friend_MaleWounded then
		for _, friend in ipairs(friends) do
			if friend:isMale() and friend:isWounded() then return true end
		end
	elseif prompt == sgs.Friend_All then
		return true
	else
		Global_room:writeToConsole(debug.traceback())
		return
	end
	return false
end

function HasBuquEffect(player)
	return player:hasShownSkill("buqu") and player:getPile("scars"):length() <= 4
end

function SmartAI:getKingdomCount()
	local count = 0
	local k = {}
	for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
		if sgs.isAnjiang(ap) or not k[ap:getKingdom()] or ap:getRole() == "careerist" then
			k[ap:getKingdom()] = true
			count = count + 1
		end
	end
	return count
end

function SmartAI:doNotSave(player)
	if HasNiepanEffect(player) then return true end
	if player:hasFlag("AI_doNotSave") then return true end
	return false
end

function SmartAI:imitateDrawNCards(player, skills)
	if not player then self.room:writeToConsole(debug.traceback()) return 0 end
	if player:isSkipped(sgs.Player_Draw) then return 0 end
	skills = skills or player:getVisibleSkillList(true)
	local drawSkills = {}
	for _,skill in sgs.qlist(skills) do
		if player:hasShownSkill(skill:objectName()) then
			table.insert(drawSkills, skill:objectName())
		end
	end
	local count = 2
	if player:hasTreasure("JadeSeal") and player:hasShownOneGeneral() then count = count + 1 end
	if #drawSkills > 0 then
		for _,skillname in pairs(drawSkills) do
			if skillname == "shuangxiong" and sgs.ai_skill_invoke.shuangxiong(sgs.ais[player:objectName()]) then return 1
			elseif skillname == "shelie" and sgs.ai_skill_invoke.shelie(sgs.ais[player:objectName()]) then return 3.5
			--elseif skillname == "zaiqi" and sgs.ai_skill_invoke.zaiqi(sgs.ais[player:objectName()]) then return math.floor(player:getLostHp() * 3 / 4)
			elseif skillname == "yingzi_sunce" then count = count + 1
			elseif skillname == "yingzi_zhouyu" then count = count + 1
			elseif skillname == "yingzi_flamemap" then count = count + 1
			elseif skillname == "haoshi" and sgs.ai_skill_invoke.haoshi(sgs.ais[player:objectName()]) then count = count + 2
			elseif skillname == "haoshi_flamemap" and sgs.ai_skill_invoke.haoshi(sgs.ais[player:objectName()]) then count = count + 2
			elseif skillname == "jieyue" then count = count + player:getMark("JieyueExtraDraw")*3
			elseif skillname == "jieyue_egf" then count = count + player:getMark("JieyueExtraDraw")*3
			elseif skillname == "congcha" then
				local congcha_draw = true
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					if not p:hasShownOneGeneral() then
						congcha_draw = false
						break
					end
				end
				if congcha_draw then
					count = count + 2
				end
			elseif skillname == "zisui" then count = count + player:getPile("&disloyalty"):length() end
		end
	end
	return count
end

function SmartAI:willSkipPlayPhase(player, NotContains_Null)
	player = player or self.player

	if player:isSkipped(sgs.Player_Play) then return true end
	if player:hasFlag("willSkipPlayPhase") then return true end

	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				--local trick = sgs.cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				--if self:trickIsEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
				if self:trickIsEffective(hcard, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if player:containsTrick("indulgence") then
		if player:hasShownSkill("shensu") or (player:hasShownSkill("qiaobian") and not player:isKongcheng()) then return false end
		if player:hasShownSkills("guanxing+yizhi") or (player:hasShownSkills("guanxing|yizhi") and self.room:alivePlayerCount() >= 4) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		if (self:getFinalRetrial(player) == 1 and self:isFriend(player)) or (self:getFinalRetrial(player) == 2 and self:isEnemy(player)) then
			local _, wP = self:getFinalRetrial(player)
			if wP and wP:hasShownSkill("guicai") and getKnownCard(wP, self.player, "heart", true, "h") then
				return false
			end
		end
		return true
	end
	return false
end

function SmartAI:willSkipDrawPhase(player, NotContains_Null)
	player = player or self.player
	if player:isSkipped(sgs.Player_Draw) then return true end

	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = sgs.cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				if self:trickIsEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if player:containsTrick("supply_shortage") then
		if player:hasShownSkill("qiaobian") and not player:isKongcheng() then return false end
		if player:hasShownSkills("guanxing+yizhi") or (player:hasShownSkills("guanxing|yizhi") and self.room:alivePlayerCount() >= 4) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		if (self:getFinalRetrial(player) == 1 and self:isFriend(player)) or (self:getFinalRetrial(player) == 2 and self:isEnemy(player)) then
			local _, wP = self:getFinalRetrial(player)
			if wP and getKnownCard(wP, self.player, "club", true, "h") then
				return false
			end
		end
		return true
	end
	return false
end

function SmartAI:resetCards(cards, except)
	local result = {}
	for _, c in ipairs(cards) do
		if c:getEffectiveId() == except:getEffectiveId() then continue
		else table.insert(result, c) end
	end
	return result
end

function SmartAI:isValuableCard(card, player)
	player = player or self.player
	if (isCard("Peach", card, player) and getCardsNum("Peach", player, self.player) <= 2)
		or (self:isWeak(player) and (isCard("Analeptic", card, player) or isCard("AllianceFeast", card, player)))
		or (player:getPhase() ~= sgs.Player_Play
			and ((isCard("Nullification", card, player) and getCardsNum("Nullification", player, self.player) < 2 and player:hasShownSkill("jizhi"))
				or (isCard("Jink", card, player) and getCardsNum("Jink", player, self.player) < 2)))
		or (player:getPhase() == sgs.Player_Play  and not player:isLocked(card)
			and (isCard("ExNihilo", card, player) or isCard("BefriendAttacking", card, player) or isCard("AllianceFeast", card, player))) then
		return true
	end
	local dangerous = self:getDangerousCard(player)
	if dangerous and card:getEffectiveId() == dangerous then return true end
	local valuable = self:getValuableCard(player)
	if valuable and card:getEffectiveId() == valuable then return true end
end

function SmartAI:cantbeHurt(player, from, damageNum)
	from = from or self.player
	damageNum = damageNum or 1
	if not player then self.room:writeToConsole(debug.traceback()) return end
	
	if sgs.isAnjiang(player) then
		local gameProcess = sgs.gameProcess()
		local player_kingdom_explicit = sgs.ai_explicit[player:objectName()]--全局势力倾向
		local player_kingdom_evaluate = self:evaluateKingdom(player)--被一名角色确定或认为的势力(与倾向相同，没有倾向时参照知己知彼?)
		if sgs.isAnjiang(from) then
			--没有大优势国家时暗将不击杀暗将
			if not string.find(gameProcess, ">>") then return true end
			--队友没有大优势时,暗将不击杀没暴露的暗将
			if player_kingdom_explicit == "unknown" then
				if from:objectName() == self.player:objectName() then
					local longest = string.match(gameProcess, "%p+>")
					if string.find(gameProcess, self.player:getKingdom()..longest) then
					else return true end
				else return true end
			end
		else
			local fromIsCareerist = false
			local from_kingdom = from:getKingdom()
			local upperlimit = from:getLord() and 99 or math.floor(self.room:getPlayers():length() / 2)
			if from:objectName() == self.player:objectName() then
				fromIsCareerist = (self.role == "careerist" or (sgs.shown_kingdom[from_kingdom] >= upperlimit and not self.player:hasShownOneGeneral()) 
								or (self.player:getActualGeneral1():getKingdom() == "careerist" and not (self.player:hasShownGeneral1() and self.role ~= "careerist")))
			else
				fromIsCareerist = (sgs.ai_explicit[from:objectName()] == "careerist")
			end
			if not fromIsCareerist then
				--无君主大势力开团,皆杀
				if string.find(gameProcess, from_kingdom..">>>") and player_kingdom_explicit ~= from_kingdom and not from:getLord() then
				else
					--除野心家外,其他角色不击杀没暴露的角色
					if player_kingdom_explicit == "unknown" then return true end
					local longest = string.match(gameProcess, "%p+>")
					if string.find(gameProcess, player_kingdom_explicit..longest) then
					elseif string.find(gameProcess, player_kingdom_evaluate..longest) then
					else
						--不击杀小势力暗将角色
						return true
					end
				end
			end
		end
	end
	
	if player:hasShownSkill("duanchang") and not player:isLord() and #(self:getFriendsNoself(player)) > 0 and player:getHp() <= 1 then
		if self:isFriend(player,from) and not from:hasSkill("benghuai") then return true end--任何情况,别吃队友断肠
		if not (from:getMaxHp() > 3 and from:getArmor() and from:getDefensiveHorse()) then
			if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
		end
	end
	
	if player:hasShownSkill("niepan") and player:getMark("@nirvana") > 0 and not player:isLord()
		and #(self:getFriendsNoself(player)) > 0 and player:getHp() <= 1 and not from:willBeFriendWith(player) then
		local peach_num = getCardsNum("Peach", player, from)
		local hasUnsafeEnemie = false
		for _, enemie in ipairs(self:getFriendsNoself(player)) do
			if enemie:getHp() < 2 then
				hasUnsafeEnemie = true
				break
			end
		end
		if hasUnsafeEnemie and peach_num == 0 and player:getHandcardNum() < 3 then
			return true
		end
	end
	
	local C_C = sgs.findPlayerByShownSkillName("qiyuan")
	if C_C and C_C:isFriendWith(player) and C_C:getHp() >= player:getHp() and not from:isFriendWith(player) then
		if from:hasShownOneGeneral() then
			local from_kingdoms = from:getPlayerNumWithSameKingdom("AI")
			local player_kingdoms = player:getPlayerNumWithSameKingdom("AI")
			if from_kingdoms > player_kingdoms then 
				local bless = from:getMark("@bless")
				if bless == 0 and (from:getHp() < 2 or self:isWeak(from)) then
					local need_recover = from:getMaxHp() + 1
					local peach_num = self.player:objectName() == from:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", from, self.player)
					if need_recover > peach_num then
						return true
					end
				else return true end
			end
		end
	end
	
	if player:hasShownSkill("tianxiang") and (getKnownCard(player, self.player, "diamond|club", false) < player:getHandcardNum() 
	or (player:hasShownSkill("keshou") and player:getPlayerNumWithSameKingdom("AI") == 1 and self:getFinalRetrial(player, "keshou") ~= 1 and player:hasShownSkills("tiandu|zhuwei"))) then
		if player:hasFlag("tianxiang1used") and player:hasFlag("tianxiang2used") then return false end
		local peach_num = self.player:objectName() == from:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", from, self.player)
		local dyingfriend = 0
		for _, friend in ipairs(self:getFriends(from)) do
			if friend:getHp() < 2 and peach_num == 0 then
				dyingfriend = dyingfriend + 1
			end
		end
		if dyingfriend > 0 and player:getHandcardNum() > 0 then
			return true
		end
	end
	--附敌
	if player:hasShownSkill("fudi") and not player:isKongcheng() and not from:isFriendWith(player) then
		if damageNum > player:getHp() + getCardsNum("Peach", player, self.player) then return false end
		local x = player:getHp() - damageNum
		local targets = sgs.SPlayerList()
		for _, p in ipairs(self:getFriends(from)) do
			if not from:isFriendWith(p) or p:getHp() < x then
				continue
			end
			if p:getHp() > x then
				targets = sgs.SPlayerList()
			end
			x = p:getHp()
			targets:append(p)
		end
		if targets:isEmpty() then return false end
		local peach_num = (self.player:objectName() == from:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", from, self.player))
		for _, target in sgs.qlist(targets) do
			if self:isEnemy(target, player) and self:damageIsEffective(target, nil, player) then
				if targets:length() <= 1 and damageNum <= 1 then
					return true
				elseif not self:needDamagedEffects(target, player) and not self:needToLoseHp(target, player) then
        			if target:getHp() + peach_num - (player:hasShownSkill("congjian") and 1 or 2) < 1 then return true end
				end
			end
		end
	end
	if player:hasShownSkill("hengzheng") and player:getHandcardNum() ~= 0 and player:getHp() - damageNum == 1
		and from:getNextAlive():objectName() == player:objectName() then
		if sgs.ai_skill_invoke.hengzheng(sgs.ais[player:objectName()]) then return true end
	end
	return false
end

function SmartAI:getGuixinValue(player)
	if player:isAllNude() then return 0 end
	local card_id = self:askForCardChosen(player, "hej", "dummy")
	if self:isEnemy(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 0.8
					elseif self:hasWizard(self.friends, true) then return 0.4
					else return 0.5 * (#self.friends) / (#self.friends + #self.enemies) end
				else
					return -0.2
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0 end
				local value = 0
				if self:getDangerousCard(player) == card_id then value = 1.5
				elseif self:getValuableCard(player) == card_id then value = 1.1
				elseif i == 1 then value = 1
				elseif i == 2 then value = 0.8
				elseif i == 0 then value = 0.7
				elseif i == 3 then value = 0.5
				end
				if player:hasShownSkills(sgs.lose_equip_skill) or self:doNotDiscard(player, "e", true) then value = value - 0.2 end
				return value
			end
		end
		if self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0 end
		if not self:hasLoseHandcardEffective() then return 0.1
		else
			local index = player:hasShownSkills("jijiu|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|tianxiang|lijian") and 0.7 or 0.6
			local value = 0.2 + index / (player:getHandcardNum() + 1)
			if self:doNotDiscard(player, "h", true) then value = value - 0.1 end
			return value
		end
	elseif self:isFriend(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 1
					elseif self:hasWizard(self.friends, true) then return 0.8
					else return 0.4 * (#self.enemies) / (#self.friends + #self.enemies) end
				else
					return 1.5
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0.9 end
				local value = 0
				if i == 1 then value = 0.1
				elseif i == 2 then value = 0.2
				elseif i == 0 then value = 0.25
				elseif i == 3 then value = 0.25
				end
				if player:hasShownSkills(sgs.lose_equip_skill) then value = value + 0.1 end
				if player:hasShownSkill("tuntian") then value = value + 0.1 end
				return value
			end
		end
		if self:needKongcheng(player, true) and player:getHandcardNum() == 1 then return 0.5
		elseif self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0.3 end
		if not self:hasLoseHandcardEffective() then return 0.2
		else
			local index = player:hasShownSkills("jijiu|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|tianxiang|lijian") and 0.5 or 0.4
			local value = 0.2 - index / (player:getHandcardNum() + 1)
			if player:hasShownSkill("tuntian") then value = value + 0.1 end
			return value
		end
	end
	return 0.3
end

function SmartAI:setSkillsPreshowed()
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:getAI() then
			player:setSkillsPreshowed("hd", true)
		end
	end
end

function SmartAI:willShowForAttack()
	if sgs.isRoleExpose() then return true end
	if self.player:hasShownOneGeneral() or self.player:isLord() then return true end
	if self.room:alivePlayerCount() < 3 then return true end

	local notshown, shown, f, Wbf, e, eAtt, eMax = 0, 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self.player:willBeFriendWith(p) then
				Wbf = Wbf + 1
			elseif p:getPlayerNumWithSameKingdom("AI") > eMax then
				eMax = p:getPlayerNumWithSameKingdom("AI")
			end
			if self:evaluateKingdom(p) == self.player:getKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
	end

	local showRate = math.random() + f/20 + eAtt/10 + shown/20 + sgs.turncount/10

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end
	if firstShowReward and showRate > 0.9 then return true end
	
	if Wbf >= e or Wbf + 1 >= math.floor((shown + notshown)/2) or eMax >= math.floor((shown + notshown)/2) then 
		local cn = sgs.cardneed_skill:split("|")
		for _, skill in ipairs(cn) do
			if self.player:hasSkill(skill) then
				return true
			end
		end
	end
	
	if showRate < 0.9 then return false end
	if e < f or eAtt <= 0 then return false end

return true
end

function SmartAI:willShowForDefence()
	if sgs.isRoleExpose() then return true end
	if self.player:hasShownOneGeneral() or self.player:isLord() then return true end
	if self.room:alivePlayerCount() < 3 then return true end
	if self:isWeak() then return true end

	local notshown, shown, f, Wbf, e, eAtt, eMax = 0, 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self.player:willBeFriendWith(p) then
				Wbf = Wbf + 1
			elseif p:getPlayerNumWithSameKingdom("AI") > eMax then
				eMax = p:getPlayerNumWithSameKingdom("AI")
			end
			if self:evaluateKingdom(p) == self.player:getKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
	end
	local showRate = math.random() - e/10 - self.player:getHp()/10 + shown/20 + sgs.turncount/10

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end
	if firstShowReward and (showRate > 0.9 or self:isWeak()) then return true end
	
	if Wbf >= e or Wbf + 1 >= math.floor((shown + notshown)/2) or eMax >= math.floor((shown + notshown)/2) then  
		local cn = sgs.cardneed_skill:split("|")
		for _, skill in ipairs(cn) do
			if self.player:hasSkill(skill) then
				return true
			end
		end
	end
	
	if showRate < 0.8 then return false end
	if f < 2 or not self:isWeak() then return false end

	return true
end

function SmartAI:willShowForMasochism()
	if sgs.isRoleExpose() then return true end
	if self.player:hasShownOneGeneral() or self.player:isLord() then return true end
	if self.room:alivePlayerCount() < 3 then return true end

	local notshown, shown, f, Wbf, e, eAtt, eMax = 0, 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self.player:willBeFriendWith(p) then
				Wbf = Wbf + 1
			elseif p:getPlayerNumWithSameKingdom("AI") > eMax then
				eMax = p:getPlayerNumWithSameKingdom("AI")
			end
			if self:evaluateKingdom(p) == self.player:getKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
	end
	local showRate = math.random() - self.player:getHp()/10 + e/10 + shown/20 + sgs.turncount/10

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end
	if firstShowReward and showRate > 0.9 then return true end

	if Wbf >= e or Wbf + 1 >= math.floor((shown + notshown)/2) or eMax >= math.floor((shown + notshown)/2) then 
		local cn = sgs.cardneed_skill:split("|")
		for _, skill in ipairs(cn) do
			if self.player:hasSkill(skill) then
				return true
			end
		end
	end

	if showRate < 0.2 then return false end
	if self.player:getLostHp() == 0 and self:getCardsNum("Peach") > 0 and showRate < 0.2 then return false end

	return true
end

function SmartAI:getReward(player)
	if self.player:getRole() == "careerist"
	or (self.player:getActualGeneral1():getKingdom() == "careerist" and self.player:hasSkill("shilu")) then
		return 3
	end
	if not sgs.isAnjiang(player) and player:getRole() == "careerist" then return 1 end
	local x = 1
	--(Global_room:getOtherPlayers(player))Wrong arguments for overloaded function 'Room_getOtherPlayers'
	for _, p in sgs.qlist(player:getAliveSiblings()) do
		if p:isFriendWith(player) then x = x + 1 end
	end
	return x
end

function sgs.hasNullSkill(skill_name, player)
	if sgs.general_shown[player:objectName()]["head"] and player:inHeadSkills(skill_name) and not player:hasSkill(skill_name) then
	-- #player:disableShow(true) > 0 and not player:hasShownGeneral1()
		return true
	elseif sgs.general_shown[player:objectName()]["deputy"] and player:inDeputySkills(skill_name) and not player:hasSkill(skill_name) then
	--#player:disableShow(false) > 0 and not player:hasShownGeneral2()
		return true
	end
	return false
end

function SmartAI:isFriendWith(player)
	if self.role == "careerist" then return false end
	if self.player:isFriendWith(player) then return true end
	local kingdom = self.player:getKingdom()
	local p_kingdom = self:evaluateKingdom(player)
	if kingdom == p_kingdom then
		local kingdom_num = self.player:getPlayerNumWithSameKingdom("AI")
		if not self.player:hasShownOneGeneral() then kingdom_num = kingdom_num + 1 end
		if not player:hasShownOneGeneral() then kingdom_num = kingdom_num + 1 end
		if self.player:aliveCount() / 2 > kingdom_num or player:getLord() then return true end
	end

	return false
end

function sgs.PlayerList2SPlayerList(playerList)
	local splist = sgs.SPlayerList()
	for _, p in sgs.qlist(Global_room:getAlivePlayers()) do
		if playerList:contains(p) then splist:append(p) end
	end
	return splist
end

function sgs.findPlayerByShownSkillName(skill_name)
	local player = Global_room:findPlayerBySkillName(skill_name)
	if player and player:hasShownSkill(skill_name) then
		return player
	end
--[[for _, p in sgs.qlist(Global_room:getAllPlayers()) do
		if p:hasShownSkill(skill_name) then return p end
	end]]
end

function sgs.cardIsVisible(card, to, from)
	if not card or not to then Global_room:writeToConsole(debug.traceback()) end
	if from and to:objectName() == from:objectName() then return true end
	if card:hasFlag("visible") then return true end
	if from then
		local visibleFlag = string.format("visible_%s_%s", from:objectName(), to:objectName())
		if card:hasFlag(visibleFlag) then return true end
	end
	return false
end

function HasNiepanEffect(player)
	if player:hasShownSkill("niepan") and player:getMark("@nirvana") > 0 then return true end
	if player:hasShownSkill("jizhao") and player:getMark("@jizhao") > 0 then return true end
end

function sgs.isRoleExpose()
	--local mode = string.lower(Global_room:getMode())
	--if mode:find("0") then return false end
	--if Global_room:getMode() == "jiange_defense" then return true end
	if Global_room:getScenario() and Global_room:getScenario():exposeRoles() then return true end
	return false
end

dofile "lua/ai/debug-ai.lua"
dofile "lua/ai/standard_cards-ai.lua"
dofile "lua/ai/maneuvering-ai.lua"
dofile "lua/ai/chat-ai.lua"
dofile "lua/ai/guanxing-ai.lua"
dofile "lua/ai/standard-wei-ai.lua"
dofile "lua/ai/standard-shu-ai.lua"
dofile "lua/ai/standard-wu-ai.lua"
dofile "lua/ai/standard-qun-ai.lua"
dofile "lua/ai/basara-ai.lua"
dofile "lua/ai/jiange-defense-ai.lua"

local loaded = "standard|standard_cards|maneuvering"

local files = table.concat(sgs.GetFileNames("lua/ai"), " ")
local LUAExtensions = string.split(string.lower(sgs.GetConfig("LuaPackages", "")), "+")
local LUAExtensionFiles = table.concat(sgs.GetFileNames("extensions/ai"), " ")

for _, aextension in ipairs(sgs.Sanguosha:getExtensions()) do
	if table.contains(LUAExtensions, string.lower(aextension)) then
		if LUAExtensionFiles:match(string.lower(aextension)) then
			dofile("extensions/ai/" .. string.lower(aextension) .. "-ai.lua")
		end
	elseif not loaded:match(aextension) and files:match(string.lower(aextension)) then
		dofile("lua/ai/" .. string.lower(aextension) .. "-ai.lua")
	end

end
