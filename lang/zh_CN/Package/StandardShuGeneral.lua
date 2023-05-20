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

-- translation for Standard General Package

return {
	-- 蜀势力
	["#liubei"] = "乱世的枭雄",
	["liubei"] = "刘备",
	["illustrator:liubei"] = "木美人",
	["rende"] = "仁德",
	[":rende"] = "出牌阶段，你可将至少一张手牌交给一名角色▶你于此阶段内不能再次对这些角色发动此技能。若你于此阶段内因执行此技能的消耗而交给其他角色的手牌数大于1且于此次发动此技能之前于此阶段内因执行此技能的消耗而交给其他角色的手牌数小于2，你可使用无对应的实体牌的基本牌。",
	["@rende-basic"] = "仁德：选择要使用的基本牌",
	["rende_basic"] = "仁德",
	
	["#guanyu"] = "威震华夏",
	["illustrator:guanyu"] = "凡果",
	["guanyu"] = "关羽",
	["wusheng"] = "武圣",
	[":wusheng"] = "①当你需要使用/打出普【杀】时，你可使用/打出对应的实体牌为你的一张红色牌的普【杀】。②你使用对应的实体牌为一张方块牌的【杀】无距离关系的限制。",

	["#zhangfei"] = "万夫不当",
	["illustrator:zhangfei"] = "宋其金",
	["zhangfei"] = "张飞",
	["paoxiao"] = "咆哮",
	[":paoxiao"] = "锁定技，①你使用【杀】无次数限制。②当【杀】被使用时，若使用者为你且你于此回合内使用过两张【杀】，你摸一张牌。",
	["#PaoxiaoDraw"] = "%from 发动了“%arg”效果，摸一张牌",
	["#PaoxiaoTarget"] = "%from 发动了“%arg”效果，无视 %to 的防具",

	["#zhugeliang"] = "迟暮的丞相",
	["zhugeliang"] = "诸葛亮",
	["illustrator:zhugeliang"] = "木美人",
	["guanxing"] = "观星",
	[":guanxing"] = "准备阶段开始时，你可将牌堆顶的X张牌（X为角色数且至多为5}）扣置入处理区（对你可见）.你将其中任意数量的牌置于牌堆顶，将其余的牌置于牌堆底。",
	["kongcheng"] = "空城",
	[":kongcheng"] = "锁定技，①当你成为【杀】或【决斗】的目标时，若你没有手牌，你取消此目标。②当牌于你的回合外因交给而移至你的手牌区前，若你没有手牌，你将此次移动的目标区域改为你的武将牌上（均称为“琴”）。③摸牌阶段开始时，你获得所有“琴”。",
	["#GuanxingResult"] = "%from 的“<font color=\"yellow\"><b>观星</b></font>”结果：%arg 上 %arg2 下",
	["$GuanxingTop"] = "置于牌堆顶的牌：%card",
	["$GuanxingBottom"] = "置于牌堆底的牌：%card",
	["zither"] = "琴",

	["#zhaoyun"] = "虎威将军",
	["illustrator:zhaoyun"] = "DH",
	["zhaoyun"] = "赵云",
	["longdan"] = "龙胆",
	[":longdan"] = "①你可以将【闪】当普【杀】使用或打出→当此【杀】被一名角色使用的【闪】抵消后，你可对另一名角色造成1点普通伤害。②你可以将【杀】当【闪】使用或打出→当一名角色使用的【杀】被此【闪】抵消后，你可令另一名其他角色回复1点体力。",

	["longdan-damage"] = "是否发动“龙胆”，对另一名角色造成1点伤害",
	["longdan-recover"] = "是否发动“龙胆”，令一名其他角色回复1点体力",
	["#longdan-slash"] = "龙胆[杀]",
	["#longdan-jink"] = "龙胆[闪]",
	["#longdan-draw"] = "龙胆[摸牌]",
	["#LongdanDamage"] = "%from 发动了“%arg”效果，对 %to 造成1点伤害",
	["#LongdanRecover"] = "%from 发动了“%arg”效果，令 %to 回复1点体力",
	["#LongdanDraw"] = "%from 的“%arg<font color=\"yellow\"><b>（五虎将大旗）</b></font>”效果，摸一张牌",
	
	["#machao"] = "一骑当千",
	["machao"] = "马超",
	["illustrator:machao"] = "KayaK&木美人&张帅",
	["mashu_machao"] = "马术",
	[":mashu"] = "锁定技，你至其他角色的距离-1。",
	["tieqi"] = "铁骑",
	[":tieqi"] = "当【杀】指定目标后，若使用者为你，你可判定▶你选择此目标对应的角色的一张处于明置状态的武将牌。此牌的所有未带有“锁定技”标签的武将技能于当前回合内无效。其选择：1.弃置与结果花色相同的一张牌；2.令此【杀】于对此目标进行的使用结算中不是其使用【闪】的合法目标。",
	
	["@tieji-discard"] = "铁骑：请弃置一张%arg花色的牌，否则你不能使用【闪】响应此【杀】",
	["#TieqiHeadSkills"] = "%from 发动“%arg”，令%to 的主将的所有非锁定技无效",
	["#TieqiDeputySkills"] = "%from 发动“%arg”，令%to 的副将的所有非锁定技无效",
	["#TieqiAllSkills"] = "%from 发动“%arg”，令%to 的所有非锁定技无效",
	
	
	["#huangyueying"] = "归隐的杰女",
	["huangyueying"] = "黄月英",
	["illustrator:huangyueying"] = "木美人",
	["jizhi"] = "集智",
	[":jizhi"] = "当你使用非转化的普通锦囊牌时，你可摸一张牌。",
	["qicai"] = "奇才",
	[":qicai"] = "锁定技，你使用锦囊牌无距离限制。",

	["#huangzhong"] = "老当益壮",
	["illustrator:huangzhong"] = "凡果",
	["huangzhong"] = "黄忠",
	["liegong"] = "烈弓",
	[":liegong"] = "①你对手牌数不大于你的角色使用【杀】无距离关系的限制。②当【杀】指定目标后，若使用者为你且此目标对应的角色的体力值不小于你，"..
		"你可选择：1.令此【杀】于对此目标进行的使用结算中不是其使用【闪】的合法目标；2.令此【杀】于对此目标进行的使用结算中的伤害值基数+1。",
	["@liegong-choice"] = "烈弓：选择【杀】对%dest的效果",
	["liegong:nojink"] = "不可被响应",
	["liegong:adddamage"] = "伤害值基数+1",

	["#weiyan"] = "嗜血的独狼",
	["weiyan"] = "魏延",
	["illustrator:weiyan"] = "瞌瞌一休",
	["kuanggu"] = "狂骨",
	[":kuanggu"] = "当你对一名角色造成1点伤害后，若你至其的距离于其因受到此伤害而扣减体力前小于2，你可选择：1.回复1点体力；2.摸一张牌。",
	["kuanggu:draw"] = "摸一张牌",
	["kuanggu:recover"] = "回复体力",

	["#pangtong"] = "凤雏",
	["pangtong"] = "庞统",
	["lianhuan"] = "连环",
	[":lianhuan"] = "①你可将一张梅花手牌当【铁索连环】使用。②你能重铸梅花手牌。",
	["niepan"] = "涅槃",
	[":niepan"] = "限定技，当你处于濒死状态时，你可弃置你区域里的所有牌，复原，摸三张牌，将体力回复至3点。",
	["@nirvana"] = "涅槃",

	["#wolong"] = "卧龙",
	["wolong"] = "卧龙·诸葛亮",
	["&wolong"] = "诸葛亮",
	["illustrator:wolong"] = "绘聚艺堂",
	["bazhen"] = "八阵",
	[":bazhen"] = "锁定技，若你的装备区里没有防具牌，你视为装备着【八卦阵】。",
	["huoji"] = "火计",
	[":huoji"] = "你可将一张红色手牌当【火攻】使用。",
	["kanpo"] = "看破",
	[":kanpo"] = "你可将一张黑色手牌当【无懈可击】使用。",

	["#liushan"] = "无为的真命主",
	["liushan"] = "刘禅",
	["illustrator:liushan"] = "LiuHeng",
	["xiangle"] = "享乐",
	[":xiangle"] = "锁定技，当你成为【杀】的目标后，你令使用者选择：1.弃置一张基本牌；2.此【杀】对此目标无效。",
	["@xiangle-discard"] = "享乐：请弃置一张基本牌，否则该【杀】对 %src 无效",
	["fangquan"] = "放权",
	[":fangquan"] = "出牌阶段开始前，你可跳过此阶段▶此回合结束前，你可弃置一张手牌并选择一名其他角色.其获得一个额外回合。",
	["@fangquan-discard"] = "放权：你可以弃置一张手牌并令一名角色获得一个额外回合",
	["~fangquan"] = "选择一张手牌→选择一名其他角色→点击确定",
	["#Fangquan"] = "%to 将获得一个额外的回合",

	["#menghuo"] = "南蛮王",
	["menghuo"] = "孟获",
	["illustrator:menghuo"] = "废柴男",
	["huoshou"] = "祸首",
	[":huoshou"] = "锁定技，①当【南蛮入侵】对目标的使用结算开始时，你令此【南蛮入侵】对此目标无效。②当【南蛮入侵】指定第一个目标后，若使用者不为你，你代替其成为渠道为此牌的伤害的来源。",
	["#sa_avoid_huoshou"] = "祸首（无效南蛮入侵）" ,
	["zaiqi"] = "再起",
	[":zaiqi"] = "弃牌阶段结束时，你可选择至多X名与你势力相同的角色（X为弃牌堆里于此回合内移至弃牌堆的红色牌数）▶这些角色各选择：1.令你回复1点体力；2.摸一张牌。",
	["#HuoshouTransfer"] = "%from 的“%arg2”被触发，【<font color=\"yellow\"><b>南蛮入侵</b></font>】的伤害来源改为 %from",
	["@zaiqi-target"] = "是否使用“再起”，选择至多%arg名与你势力相同的角色",
	["@zaiqi-choice"] = "再起：选择摸一张牌或令%src回复体力",
	["zaiqi:drawcard"] = "摸一张牌",
	["zaiqi:recover"] = "回复体力",

	["#zhurong"] = "野性的女王",
	["zhurong"] = "祝融",
	["illustrator:zhurong"] = "废柴男",
	["juxiang"] = "巨象",
	[":juxiang"] = "锁定技，①当【南蛮入侵】对你的使用结算开始时，你令此【南蛮入侵】对你无效。②当【南蛮入侵】使用结算结束后，若使用者不为你，你获得此【南蛮入侵】对应的所有实体牌。",
	["#sa_avoid_juxiang"] = "巨象（无效南蛮入侵）" ,
	["lieren"] = "烈刃",
	[":lieren"] = "当你使用【杀】对目标角色造成伤害后，你可以与其拼点，若你赢，你获得其一张牌。",

	["#ganfuren"] = "昭烈皇后",
	["ganfuren"] = "甘夫人",
	["illustrator:ganfuren"] = "琛·美弟奇",
	["shushen"] = "淑慎",
	[":shushen"] = "当你回复1点体力后，你可令一名其他角色摸一张牌。",
	["shushen-invoke"] = "是否使用“淑慎”，令一名其他角色摸一张牌",
	["shenzhi"] = "神智",
	[":shenzhi"] = "准备阶段开始时，你可弃置所有手牌▶若你以此法弃置的手牌数不小于你的体力值，你回复1点体力。",
}