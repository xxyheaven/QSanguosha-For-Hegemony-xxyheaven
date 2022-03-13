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

-- translation for StandardPackage

local t = {
	["standard_cards"] = "标准版",


	["slash"] = "普杀",
	[":slash"] = "基本牌\n\n使用时机：出牌阶段限一次。\n使用目标：你的攻击范围内的一名其他角色。\n作用效果：你对目标对应的角色造成1点普通伤害。",
	["slash-jink"] = "%src 使用了【杀】，请使用一张【闪】",
	["@multi-jink-start"] = "%src 使用了【杀】，你须连续使用 %arg 张【闪】",
	["@multi-jink"] = "%src 使用了【杀】，你须再使用 %arg 张【闪】",
	["@slash_extra_targets"] = "请选择此【杀】的额外目标",

	["fire_slash"] = "火杀",
	[":fire_slash"] ="基本牌\n\n使用时机：出牌阶段限一次。\n使用目标：你的攻击范围内的一名其他角色。\n作用效果：你对目标对应的角色造成1点火焰伤害。",

	["thunder_slash"] = "雷杀",
	[":thunder_slash"] = "基本牌\n\n使用时机：出牌阶段限一次。\n使用目标：你的攻击范围内的一名其他角色。\n作用效果：你对目标对应的角色造成1点雷电伤害。",

	["jink"] = "闪",
	[":jink"] = "基本牌\n\n使用时机：当【杀】对对应的角色为你的目标生效前。\n使用目标：此【杀】。\n作用效果：抵消此【杀】。",
	["#NoJink"] = "%from 不能使用【<font color=\"yellow\"><b>闪</b></font>】响应此【<font color=\"yellow\"><b>杀</b></font>】",

	["peach"] = "桃",
	[":peach"] = "基本牌\n\n使用方法Ⅰ：\n使用时机：出牌阶段。\n使用目标：已受伤的你。\n作用效果：目标对应的角色回复1点体力。"
	.."\n\n使用方法Ⅱ：\n使用时机：当一名角色处于濒死状态时。\n使用目标：该角色。\n作用效果：目标对应的角色回复1点体力。",

	["analeptic"] = "酒",
	[":analeptic"] = "基本牌\n\n使用方法Ⅰ：\n使用时机：出牌阶段。\n使用目标：于此回合内未使用过【酒】（使用方法①）的你。\n作用效果：目标对应的角色于此回合内使用的下一张【杀】的伤害值基数+1。"
	.."\n\n使用方法Ⅱ：\n使用时机：当你处于濒死状态时。\n使用目标：你。\n作用效果：目标对应的角色回复1点体力。",
	["#UnsetDrankEndOfTurn"] = "%from 的出牌阶段结束，【<font color=\"yellow\"><b>酒</b></font>】的效果消失",


	["Crossbow"] = "诸葛连弩",
	[":Crossbow"] = "装备牌·武器\n\n攻击范围：1\n技能：锁定技，你使用【杀】无次数限制。",

	["DoubleSword"] = "雌雄双股剑",
	[":DoubleSword"] = "装备牌·武器\n\n攻击范围：2\n技能：当【杀】指定目标后，若使用者为你且此目标对应的角色与你性别不同，你可令其选择：1.弃置一张手牌；2.令你摸一张牌。",
	["double-sword-card"] = "%src 发动了【雌雄双股剑】效果，你须弃置一张手牌，或令 %src 摸一张牌",

	["SixSwords"] = "吴六剑",
	[":SixSwords"] = "装备牌·武器\n\n攻击范围：2<br/>技能：锁定技，与你势力相同的其他角色的攻击范围+1。",

	["Triblade"] = "三尖两刃刀",
	[":Triblade"] = "装备牌·武器\n\n攻击范围：3<br/>技能：当你因执行你使用的【杀】的效果而对一名角色造成伤害后，你可弃置一张手牌并选择其距离为1的一名其他角色▶你对你以此法选择的角色造成1点普通伤害。",
	["tribladeskill"] = "三尖两刃刀",
	["@Triblade"] = "你可以发动【三尖两刃刀】的效果",
	["~Triblade"] = "选择一张牌→选择一名角色→点击确定",

	["QinggangSword"] = "青釭剑",
	[":QinggangSword"] = "装备牌·武器\n\n攻击范围：2\n技能：锁定技，当【杀】指定目标后，若使用者为你，你无视其防具。",

	["Spear"] = "丈八蛇矛",
	[":Spear"] = "装备牌·武器\n\n攻击范围：3\n技能：你可将两张手牌当【杀】使用或打出。",

	["Axe"] = "贯石斧",
	[":Axe"] = "装备牌·武器\n\n攻击范围：3\n技能：当你使用的【杀】被其中的一个目标对应的角色使用的【闪】抵消后，若其存活，你可弃置两张牌▶不会因此【闪】的抵消而不会生成“此【杀】对此目标生效时”和“此【杀】对此目标生效后”这两个时机。",
	["@Axe"] = "你可以弃置两张牌令此【杀】依然对其生效",
	["~Axe"] = "选择两张牌→点击确定",

	["KylinBow"] = "麒麟弓",
	[":KylinBow"] = "装备牌·武器\n\n攻击范围：5\n技能：当你因执行你使用的【杀】的效果而对一名角色造成伤害时，你可弃置其装备区里的一张坐骑牌。",
	["KylinBow:dhorse"] = "+1坐骑",
	["KylinBow:ohorse"] = "-1坐骑",
	["KylinBow:shorse"] = "六龙骖驾",

	["EightDiagram"] = "八卦阵",
	[":EightDiagram"] = "装备牌·防具\n\n技能：当你需要使用/打出【闪】时，你可判定。若结果为红色，你使用/打出无对应的实体牌的【闪】。",

	["RenwangShield"] = "仁王盾",
	[":RenwangShield"] = "装备牌·防具\n\n技能：锁定技，当黑色【杀】对目标的使用结算开始时，若此目标对应的角色为你，你令此【杀】对此目标无效。",

	["IceSword"] = "寒冰剑",
	[":IceSword"] = "装备牌·武器\n\n攻击范围：2\n技能：当你因执行你使用的【杀】的效果而对一名角色造成伤害时，若其有牌，你可防止此伤害.你依次弃置其两张牌。",

	["Fan"] = "朱雀羽扇",
	[":Fan"] = "装备牌·武器\n\n攻击范围：4\n技能：你可将一张普【杀】当火【杀】使用；你可将使用无对应实体牌的普【杀】改为使用无对应实体牌的火【杀】。",
	["fan"] = "朱雀羽扇",

	["SilverLion"] = "白银狮子",
	[":SilverLion"] = "装备牌·防具\n\n技能：\n" ..
	                "1. 锁定技，当你受到伤害时，若伤害值大于1，你将伤害值改为1。\n" ..
					"2. 锁定技，当你失去装备区里的【白银狮子】后，你回复1点体力。\n" ,
	["#SilverLion"] = "%from 的防具【<font color=\"yellow\"><b>白银狮子</b></font>】防止了 %arg 点伤害，减至 <font color=\"yellow\"><b>1</b></font> 点",

	["Vine"] = "藤甲",
	[":Vine"] ="装备牌·防具\n\n技能：\n" ..
	                "1. 锁定技，当【南蛮入侵】、【万箭齐发】或普【杀】对目标的使用结算开始时，若此目标对应的角色为你，你令此牌对此目标无效。\n" ..
					"2. 锁定技，当你受到火焰伤害时，你令此伤害+1。\n" ,
	["#VineDamage"] = "%from 的防具【<font color=\"yellow\"><b>藤甲</b></font>】效果被触发，火焰伤害由 %arg 点增加至 %arg2 点",

	["Horse"] = "坐骑",
	[":+1 horse"] = "装备牌·坐骑\n\n技能：锁定技，其他角色至你的距离+1。",
	["JueYing"] = "绝影",
	["DiLu"] = "的卢",
	["ZhuaHuangFeiDian"] = "爪黄飞电",
	[":-1 horse"] = "装备牌·坐骑\n\n技能：锁定技，你至其他角色的距离-1。",
	["ChiTu"] = "赤兔",
	["DaYuan"] = "大宛",
	["ZiXing"] = "紫骍",
	["JingFan"] = "惊帆",

	["amazing_grace"] = "五谷丰登",
	[":amazing_grace"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有角色。\n执行动作：当此牌的使用结算准备工作结束时，系统亮出牌堆顶的X张牌（X为此牌的目标对应的角色数）。当此牌的使用结算结束后.，你将处理区里的以此法亮出的牌置入弃牌堆。\n作用效果：目标对应的角色获得这些牌中的一张。",

	["god_salvation"] = "桃园结义",
	[":god_salvation"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有角色。\n作用效果：目标对应的角色回复1点体力。\n◆【桃园结义】对对应的角色未受伤的目标无效。",

	["savage_assault"] = "南蛮入侵",
	[":savage_assault"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有其他角色。\n作用效果：目标对应的角色需打出【杀】，否则受到你造成的1点普通伤害。",
	["savage-assault-slash"] = "%src 使用了【南蛮入侵】，请打出【杀】来响应",

	["archery_attack"] = "万箭齐发",
	[":archery_attack"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有其他角色。\n作用效果：目标对应的角色需打出【闪】，否则受到你造成的1点普通伤害。",
	["archery-attack-jink"] = "%src 使用了【万箭齐发】，请打出【闪】以响应",

	["collateral"] = "借刀杀人",
	[":collateral"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名装备区里有武器牌且攻击范围内有其使用【杀】的合法目标的其他角色An。" ..
					  "\n执行动作：你在选择对应的角色为An的目标的同时选择An攻击范围内的是An使用【杀】的合法目标的一名角色Bn；你在An也成为此【借刀杀人】的目标的同时选择An攻击范围内的是An使用【杀】的合法目标的一名角色Bn。" ..
					  "\n作用效果：目标对应的角色An需对Bn使用【杀】，否则将装备区里的武器牌交给你。（n为目标对应的角色的序号）。",
	["collateral-slash"] = "%dest 使用了【借刀杀人】，请对 %src 使用一张【杀】",
	["#CollateralSlash"] = "%from 选择了此【<font color=\"yellow\"><b>杀</b></font>】的目标 %to",

	["duel"] = "决斗",
	[":duel"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名其他角色。\n作用效果：由目标对应的角色开始，其与你轮流打出【杀】，直到其与你中的一名角色未打出【杀】。未打出【杀】的角色受到其与你中的另一名角色造成的1点普通伤害。",
	["duel-slash"] = "%src 对你【决斗】，你需要打出一张【杀】",

	["ex_nihilo"] = "无中生有",
	[":ex_nihilo"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：你。\n作用效果：目标对应的角色摸两张牌。",

	["snatch"] = "顺手牵羊",
	[":snatch"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：距离为1的一名区域里有牌的其他角色。\n作用效果：你获得目标对应的角色的区域里的一张牌。",

	["dismantlement"] = "过河拆桥",
	[":dismantlement"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名区域里有牌的其他角色。\n作用效果：你弃置目标对应的角色的区域里的一张牌。",

	["nullification"] = "无懈可击·普",
	[":nullification"] = "锦囊牌\n\n使用时机：当锦囊牌对目标生效前。\n使用目标：此牌。\n作用效果：抵消此牌。",

	["heg_nullification"] = "无懈可击·国",
	[":heg_nullification"] = "锦囊牌\n\n使用方法Ⅰ：\n使用时机：当锦囊牌对目标生效前。\n使用目标：此牌。\n作用效果：抵消此牌。"
	.."\n\n使用方法Ⅱ：\n使用时机：当锦囊牌对有对应的角色的目标生效前。\n使用目标：此牌。\n作用效果：抵消此牌。你令对对应的角色为与其势力相同的角色的目标结算的此牌不是【无懈可击】的合法目标→当此牌对对应的角色为这些角色中的一名的目标生效前，抵消此牌。",
	["@heg_nullification-choose"] = "无懈可击·国：请选择作用效果",
	["heg_nullification:single"] = "对单个使用（%to）",
	["heg_nullification:all"] = "对势力使用（%log势力）" ,

	["indulgence"] = "乐不思蜀",
	[":indulgence"] = "延时锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名其他角色。\n作用效果：目标对应的角色判定。若结果不为红桃，其跳过出牌阶段。",

	["lightning"] = "闪电",
	[":lightning"] = "延时锦囊牌\n\n使用时机：出牌阶段。\n使用目标：你。\n作用效果：目标对应的角色判定。若结果为黑桃2~9，其受到3点无来源的雷电伤害",

	["iron_chain"] = "铁索连环",
	[":iron_chain"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一至两名角色。\n作用效果：目标对应的角色选择一项：1.横置；2. 重置。\n◆你能重铸【铁索连环】。",

	["fire_attack"] = "火攻",
	[":fire_attack"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名有手牌的角色。\n作用效果：目标对应的角色展示一张手牌。你可弃置与此牌花色相同的一张手牌▷其受到你造成的1点火焰伤害。",
	["fire-attack-card"] = "您可以弃置一张与 %dest 所展示卡牌相同花色(%arg)的牌对 %dest 造成1点火焰伤害",
	["@fire-attack"] = "%src 展示的牌的花色为 %arg，请弃置一张与其相同花色的手牌",

	["supply_shortage"] = "兵粮寸断",
	[":supply_shortage"] = "延时锦囊牌\n\n使用时机：出牌阶段。\n使用目标：距离为1的一名其他角色。\n作用效果：目标对应的角色判定。若结果不为梅花，其跳过摸牌阶段。",

	["await_exhausted"] = "以逸待劳",
	[":await_exhausted"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：与你势力相同的所有角色。\n作用效果：目标对应的角色摸两张牌，弃置两张牌。",

	["known_both"] = "知己知彼",
	[":known_both"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名有手牌或暗置的武将牌的其他角色。\n作用效果：你选择：1.观看目标对应的角色的手牌；2.观看目标对应的角色的一张暗置的武将牌。\n◆你能重铸【知己知彼】。",
	["#KnownBothView"] = "%from 观看了 %to 的 %arg",
	["$KnownBothViewGeneral"] = "%from 观看了 %to 的 %arg，为 %arg2",
	["@known_both-choose"] = "知己知彼：请选择对%dest执行的操作",
	["known_both:head_general"] = "观看主将",
	["known_both:deputy_general"] = "观看副将",
	["known_both:handcards"] = "观看手牌",

	["befriend_attacking"] = "远交近攻",
	[":befriend_attacking"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：与你势力不同的一名角色。\n作用效果：目标对应的角色摸一张牌。你摸三张牌。",

}

local ohorses = { "ChiTu", "DaYuan", "ZiXing", "JingFan"}
local dhorses = { "ZhuaHuangFeiDian", "DiLu", "JueYing"}

for _, horse in ipairs(ohorses) do
	t[":" .. horse] = t[":-1 horse"]
end

for _, horse in ipairs(dhorses) do
	t[":" .. horse] = t[":+1 horse"]
end

return t