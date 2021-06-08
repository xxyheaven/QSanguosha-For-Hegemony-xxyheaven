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

-- translations for Basara mode

return
{
	["Basara"] = "暗将",
	["#BasaraReveal"] = "%from 明置了武将，主将为 %arg，副将为 %arg2",
	["#BasaraConceal"] = "%from 暗置了武将，主将为 %arg，副将为 %arg2",
	["#BasaraRemove"] = "%from 移除了 %arg %arg2",
	["GameRule_AskForGeneralShow"] = "明置武将",
	["GameRule:TurnStart"] = "选择需要明置的武将",
	["@generalshow-choose"] = "请选择要明置的武将",
	["@generalshow-choose-lord"] = "请选择要明置的武将（仅本次明置主将可变身君主）",
	["show_head_general"] = "明置主将",
	["show_deputy_general"] = "明置副将",
	["show_both_generals"] = "全部明置",
	["Companions"] = "珠联璧合",
	["hidden_general"] = "暗将",
	["head_general"] = "主将",
	["deputy_general"] = "副将",
	["CompanionEffect"] = "珠联璧合",
	["@companion-choose"] = "珠联璧合发动，请选择要执行的效果",
	["#HalfMaxHpLeft"] = "%from 的武将牌上有单独的阴阳鱼，摸一张牌",
	["@showingreward-choose"] = "亮将奖励：请选择要执行的效果",
	["showingreward:recover"] = "回复体力",
	["showingreward:draw"] = "摸两张牌",
	["GameRule_AskForArraySummon"] = "阵法召唤",
	["#SummonType"] = "召唤阵列为 %arg",
	["summon_type_siege"] = "围攻",
	["summon_type_formation"] = "队列",
	["#SummonResult"] = "%from 选择了 %arg",
	["summon_success"] = "响应",
	["summon_failed"] = "不响应",
	["SiegeSummon"] = "响应围攻",
	["SiegeSummon!"] = "响应围攻",
	["FormationSummon"] = "响应队列",
	["FormationSummon!"] = "响应队列",
	["GameRule:TriggerOrder"] = "请选择先发动的技能",
	["trigger_none"] = "不发动",
	["anjiang"] = "暗将",
	["anjiang_head"] = "暗将（主）" ,
	["anjiang_deputy"] = "暗将（副）" ,
	["#BasaraGeneralChosen"] = "你选择的武将为 %arg",
	["#BasaraGeneralChosenDual"] = "你选择的武将为 %arg 和 %arg2",
	["Hegemony"] = "国战",
	["Roles"] = "身份",
	["~anjiang"] = "死不瞑目啊……",

	["@define:changetolord"] = "你可以选择更换为君主。" ,
	["#FirstShowReward"] = "%from 全场第一个亮将，选择摸两张牌或回复1点体力",
	["#ShowingRewardOfCareerist"] = "%from 亮将成为野心家，选择摸两张牌或回复1点体力",
	["#ShowingRewardOfKingdom"] = "%from 是 %arg势力 第一个亮将的角色，摸一张牌",
	
	["@changetolord"] = "是否将主将变更为对应的君主武将",
	["changetolord:yes"] = "变身君主",
	["changetolord:no"] = "取消",

	["GameRule_AskForGeneralShowHead"] = "明置主将" ,
	["GameRule_AskForGeneralShowDeputy"] = "明置副将" ,
	["armorskill"] = "选择要发动的技能",
	
	["$enterBattleRoyalMode"] = "游戏进入 <font color=\"red\"><b>鏖战模式</b></font>，所有的【<font color=\"yellow\"><b>桃</b></font>】"..
		"只能当普【<font color=\"yellow\"><b>杀</b></font>】或【<font color=\"yellow\"><b>闪</b></font>】使用或打出，不能用于回复体力",

	["aozhan"] = "鏖战",
	[":aozhan"] = "①你不能使用非转化的【桃】。②你可以将【桃】当普【杀】或【闪】使用或打出。",

	["companion"] = "珠联璧合",
	[":companion"] = "限定技，①出牌阶段，你可摸两张牌。②当你需要使用【桃】时，你可使用无对应的实体牌的【桃】。",
	["companion:peach"] = "视为使用桃",
	["companion:draw"] = "摸两张牌",

	["halfmaxhp"] = "阴阳鱼",
	[":halfmaxhp"] = "限定技，①出牌阶段，你可摸一张牌。②弃牌阶段弃牌时，你可令你的手牌上限于此回合内+2。",
	["@halfmaxhp-use"] = "是否弃置阴阳鱼标记，令你本回合的手牌上限+2",

	["firstshow"] = "先驱",
	[":firstshow"] = "限定技，出牌阶段，你可将手牌补至四张，然后可观看一名角色的一张暗置的武将牌。",
	["@firstshow-see"] = "先驱：请选择一名角色，观看其一张暗置武将牌",
	["firstshow_see"] = "先驱",
	["@firstshow-choose"] = "先驱：请选择观看的%dest的武将牌",
	
	["CompanionCard"] = "珠联璧合",
	[":CompanionCard"] = "标记牌\n\n使用方法Ⅰ：\n出牌阶段，你可弃1枚“珠联璧合”，摸两张牌。\n\n使用方法Ⅱ：\n当你需要使用【桃】时，你可弃1枚“珠联璧合”，你使用无对应的实体牌的【桃】。",
	
	["HalfMaxHpCard"] = "阴阳鱼",
	[":HalfMaxHpCard"] = "标记牌\n\n使用方法Ⅰ：\n出牌阶段，你可弃1枚“阴阳鱼”，摸一张牌。\n\n使用方法Ⅱ：\n弃牌阶段开始时，若你的手牌数大于你的手牌上限，你可弃1枚“阴阳鱼”，你的手牌上限于此回合内+2。",
	
	["FirstShowCard"] = "先驱",
	[":FirstShowCard"] = "标记牌\n\n出牌阶段，若你的手牌数小于4或场上有有暗置的武将牌的其他角色，你可弃1枚“先驱”，将手牌补至4张，观看一名其他角色的一张暗置的武将牌。",
	
	["careerman"] = "野心家",
	["CareermanCard"] = "野心家",
	[":CareermanCard"] = "标记牌\n\n使用方法Ⅰ：\n出牌阶段，你可弃1枚“野心家”，选择：1.摸两张牌；2.摸一张牌；3.将手牌补至四张，观看一名其他角色的一张暗置的武将牌。\n\n使用方法Ⅱ：\n当你需要使用【桃】时，你可弃1枚“野心家”，你使用无对应的实体牌的【桃】。\n\n使用方法Ⅲ：\n弃牌阶段开始时，若你的手牌数大于你的手牌上限，你可弃1枚“野心家”，你的手牌上限于此回合内+2。",
	["careerman:draw1card"] = "摸一张牌",
	["careerman:draw2cards"] = "摸两张牌",
	["careerman:peach"] = "视为使用【桃】",
	["careerman:firstshow"] = "将手牌补至四张，观看一张暗置武将牌",
	["@careerman-target"] = "野心家：选择一名角色发动“先驱”的效果",
	["@careerman-use"] = "是否弃置野心家标记，令你本回合的手牌上限+2",
	["@careerman-choose"] = "野心家发动，请选择要执行的效果",
	
	["canshowinplay"] = "出牌阶段可明置",
	
	["showhead"] = "亮将",
	[":showhead"] = "明置主将的武将牌。",
	
	["showdeputy"] = "亮将",
	[":showdeputy"] = "明置副将的武将牌。",

	["@careerist-show"] = "暴露野心：是否明置野心家武将",
	["GameRule:CareeristShow:yes"] = "明置主将",
	["GameRule:CareeristShow:no"] = "取消",
	
	["#GameRule_CareeristShow"] = "%from 暴露野心，明置主将",
	
	["@careerist-summon"] = "是否发动 拉拢人心",
	["GameRule:CareeristSummon:yes"] = "发动拉拢人心",
	["GameRule:CareeristSummon:no"] = "取消",

	["#GameRule_CareeristSummon"] = "%from 发动了“拉拢人心”",

	["@careerist-add"] = "是否加入 %src 的阵营",

	["#GameRule_CareeristAdd"] = "%from 响应，加入 %to 的阵营",
}
