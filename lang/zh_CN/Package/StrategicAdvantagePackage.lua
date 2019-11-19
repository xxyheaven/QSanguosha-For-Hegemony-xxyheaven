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

-- translation for StrategicAdvantage Package

return {
	["strategic_advantage"] = "君临天下·势备篇",

	["transfer"] = "连横",

	["Blade"] = "青龙偃月刀",
	[":Blade"] = "装备牌·武器\n\n攻击范围：3\n技能：锁定技，当【杀】被使用时，若使用者为你，此牌的使用结算结束之前，若一名角色在此牌的目标列表里有对应的目标，其不能明置武将牌。",

	["Halberd"] = "方天画戟",
	[":Halberd"] = "装备牌·武器\n\n攻击范围：4\n技能：当【杀】选择目标后，若使用者为你，你可令不包括两名势力相同的角色在内且与这些目标对应的角色的势力均不同的任意数量的角色和任意数量的没有势力的角色也成为此【杀】的目标→当此【杀】被【闪】抵消后，你令此【杀】对所有目标均无效。",
	["halberd"] = "方天画戟",
	["#HalberdNullified"] = "由于【%arg】的效果，%from 对 %to 使用的【%arg2】无效",
	["@halberd-use"] = "是否发动【方天画戟】效果",

	["Breastplate"] = "护心镜",
	[":Breastplate"] = "装备牌·防具\n\n技能：当你受到伤害时，若伤害值不小于你的体力值，你可将装备区里的【护心镜】置入弃牌堆.你防止此伤害。",
	["#Breastplate"] = "%from 防止了 %to 对其造成的 %arg 点伤害[%arg2]",

	["IronArmor"] = "明光铠",
	[":IronArmor"] = "装备牌·防具\n\n技能：\n" ..
	                "1. 锁定技，当你成为【火烧连营】、【火攻】或火【杀】的目标时，你取消此目标。\n" ..
					"2. 锁定技，若你是小势力角色，你执行横置操作即你不执行任何操作。\n" ,
	["#IronArmor"] = "%from 的装备技能【%arg】被触发",


	["WoodenOx"] = "木牛流马",
	[":WoodenOx"] = "装备牌·宝物\n\n技能：\n" ..
					"1. 出牌阶段限一次，你可将一张手牌置入仓廪（称为“辎”）.你可将装备区里的【木牛流马】置入一名其他角色的装备区。\n" ..
					"2. 你能如手牌般使用或打出“辎”。\n" ..
					"3. 当你并非因交换而失去装备区里的【木牛流马】前，若目标区域不为其他角色的装备区，当你失去此牌后，你将所有“辎”置入弃牌堆。\n" ..
					"◆“辎”对你可见。\n◆此延时类效果于你的死亡流程中能被执行。",
	["@wooden_ox-move"] = "你可以将【木牛流马】移动至一名其他角色的装备区",
	["wooden_ox"] = "辎",
	["#WoodenOx"] = "%from 使用/打出了 %arg 张 %arg2 牌",

	["JadeSeal"] = "玉玺",
	[":JadeSeal"] = "装备牌·宝物\n\n技能：\n" ..
					"1. 锁定技，若你有势力，你的势力为大势力，除你的势力外的所有势力均为小势力。\n" ..
					"2. 锁定技，摸牌阶段，若你有处于明置状态的武将牌，你令额定摸牌数+1。\n" ..
					"3. 锁定技，出牌阶段开始时，若你有处于明置状态的武将牌，你使用无对应的实体牌的【知己知彼】。\n" ,
	["@JadeSeal"] = "你可以发动【玉玺】，视为你使用一张【知己知彼】",
	["~JadeSeal"] = "选择【知己知彼】的目标→点击确定",

	["drowning"] = "水淹七军",
	[":drowning"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名装备区里有牌的其他角色。\n作用效果：目标对应的角色选择：1.弃置装备区里的所有牌；2.受到你造成的1点雷电伤害。",
	["drowning:throw"] = "弃置装备区里的所有牌",
	["drowning:damage"] = "受到其造成的1点雷电伤害",

	["burning_camps"] = "火烧连营",
	[":burning_camps"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：你的下家和除其外与其处于同一队列的所有角色。\n作用效果：目标对应的角色受到你造成的1点火焰伤害。",

	["lure_tiger"] = "调虎离山",
	[":lure_tiger"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一至两名其他角色。\n作用效果：目标对应的角色于此回合内不计入距离和座次的计算且不能使用牌且不是牌的合法目标。\n执行动作：当此牌的使用结算结束后，你摸一张牌。",
	["lure_tiger_effect"] = "调虎离山",
	["#lure_tiger-prohibit"] = "调虎离山",

	["fight_together"] = "勠力同心",
	[":fight_together"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有大势力角色或所有小势力角色。\n作用效果：若目标对应的角色：不处于连环状态，其横置；处于连环状态，其摸一张牌。\n◆你能重铸【勠力同心】。",
	["@fight_together-choice"] = "戮力同心：请选择使用的目标或重铸",
	["fight_together:big"] = "大势力",
	["fight_together:small"] = "小势力",

	["alliance_feast"] = "联军盛宴",
	[":alliance_feast"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：有势力的你和除你的势力外的一个势力的所有角色。\n作用效果：若目标对应的角色：为你，你摸X张牌，回复（Y-X）点体力（Y为该势力的角色数）（X为你选择的自然数且不大于Y）；不为你，其摸一张牌，重置。",
	["@alliancefeast-choose"] = "联军盛宴：请选择回复体力的点数，剩余点数将用于摸牌",

	["threaten_emperor"] = "挟天子以令诸侯",
	[":threaten_emperor"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：为大势力角色的你。\n作用效果：目标对应的角色结束出牌阶段→当前回合的弃牌阶段结束时，其可弃置一张牌▷其获得一个额外回合。",
	["@threaten_emperor"] = "受到【挟天子以令诸侯】影响，你可以弃置一张牌，获得一个额外的回合",

	["imperial_order"] = "敕令",
	[":imperial_order"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有没有势力的角色。\n作用效果：目标对应的角色选择：1.明置一张武将牌，其摸一张牌；2.弃置一张装备牌；3.失去1点体力。\n\n※若此牌未因使用此效果而进入弃牌堆时，则改为将此牌移出游戏，然后于此回合结束时视为对所有未确定势力的角色使用此牌。",
	["@imperial_order-equip"] = "受到【敕令】的影响，你需要弃置一张装备牌，或点“取消”选择以下一项：<br />1. 明置一张武将牌，然后摸一张牌<br />2. 失去1点体力",
	["imperial_order:show"] = "明置武将",
	["imperial_order:losehp"] = "失去体力",
	["#RemoveImperialOrder"] = "【%arg】因使用其效果以外的原因进入弃牌堆，将被移出游戏",
	["#ImperialOrderEffect"] = "%from 的回合结束，【%arg】因被移出游戏生效",
}