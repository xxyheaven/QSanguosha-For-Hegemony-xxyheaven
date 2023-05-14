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
	["power"] = "君临天下·权",
	["power_equip"] = "君临天下·权",

	["cuiyanmaojie"] = "崔琰＆毛玠",
	["&cuiyanmaojie"] = "崔琰毛玠",
	["#cuiyanmaojie"] = "日出月盛",
	["designer:cuiyanmaojie"] = "Virgopaladin（韩旭）",
	["illustrator:cuiyanmaojie"] = "兴游",
	["zhengbi"] = "征辟",
	[":zhengbi"] = "出牌阶段开始时，你可选择：1.选择一名没有势力的角色▶你于此回合内对其使用牌无距离关系的限制且对包括其在内的角色使用牌无次数限制；2.将一张基本牌交给一名有势力的角色▶若其有牌且牌数：为1，其将所有牌交给你；大于1，其将一张不是基本牌的牌或两张基本牌交给你。",
	["@zhengbi"] = "你可以发动“征辟”",
	["@zhengbi-give"] = "征辟：请选择交给%src的两张基本牌，或一张非基本牌",
	["fengying"] = "奉迎",
	[":fengying"] = "限定技，出牌阶段，你可对你使用对应的实体牌为你的所有手牌的【挟天子以令诸侯】（无目标的限制）→当此牌被使用时，你选择所有与你势力相同的角色。这些角色各将手牌补至X张（X为其体力上限）。",
	["#fengying-after"] = "奉迎[摸牌]",
	
	["yujin"] = "于禁",
	["#yujin"] = "讨暴坚垒",
	["designer:yujin"] = "Virgopaladin（韩旭）",
	["illustrator:yujin"] = "biou09",
	["jieyue"] = "节钺",
	[":jieyue"] = "准备阶段开始时，你可将一张手牌交给一名不为魏势力或没有势力的一名角色▶其选择是否执行军令。若其选择：是，你摸一张牌；否→摸牌阶段，你令额定摸牌数+3。",
	["@jieyue"] = "你可以发动“节钺”，请选择一张手牌交给一名不是是魏势力的角色",

	["wangping"] = "王平",
	["#wangping"] = "键闭剑门",
	["illustrator:wangping"] = "zoo",
	["jianglve"] = "将略",
	[":jianglve"] = "限定技，出牌阶段，你可选择军令▶与你势力相同的其他角色各选择是否执行此军令。你加1点体力上限，回复1点体力。所有选择是的角色各{加1点体力上限，回复1点体力}。你摸X张牌（X为以此法回复过体力的角色数）。",

	["fazheng"] = "法正",
	["#fazheng"] = "蜀汉的辅翼",
	["illustrator:fazheng"] = "黑白画谱",
	["enyuan"] = "恩怨",
	[":enyuan"] = "锁定技，①当你成为【桃】的目标后，若使用者不为你，其摸一张牌。②当你受到伤害后，你令来源选择：1.将一张手牌交给你；2.失去1点体力。",
	["@enyuan-give"] = "恩怨：请选择一张手牌交给%src，或点取消失去1点体力",
	["xuanhuo"] = "眩惑",
	[":xuanhuo"] = "与你势力相同的其他角色的出牌阶段限一次，其可将一张手牌交给你▶其弃置一张牌▷其选择下列技能中所有角色均没有的一个：“武圣”、“咆哮”、“龙胆”、“铁骑”、“烈弓”、“狂骨”。其于此回合结束或其明置有以此法选择的技能的武将牌之前拥有其以此法选择的技能。",
	["@xuanhuo-choose"] = "眩惑：请选择要获得的技能",
	["@xuanhuo-discard"] = "眩惑：请弃置一张牌",
	["xuanhuoattach"] = "眩惑",
	["&xuanhuoattach"] = "出牌阶段限一次，你可将一张手牌交给法正▶你弃置一张牌▷你选择下列技能中所有角色均没有的一个：“武圣”、“咆哮”、“龙胆”、“铁骑”、“烈弓”、“狂骨”。你于此回合结束或其明置有以此法选择的技能的武将牌之前拥有其以此法选择的技能。",

	["wusheng_xh"] = "武圣",
	["paoxiao_xh"] = "咆哮",
	["longdan_xh"] = "龙胆",
	["tieqi_xh"] = "铁骑",
	["liegong_xh"] = "烈弓",
	["kuanggu_xh"] = "狂骨",
	
	["kuanggu_xh:draw"] = "摸一张牌",
	["kuanggu_xh:recover"] = "回复体力",
	["liegong_xh:nojink"] = "不可被响应",
	["liegong_xh:adddamage"] = "伤害值基数+1",
	

	["wuguotai"] = "吴国太",
	["#wuguotai"] = "武烈皇后",
	["illustrator:wuguotai"] = "李秀森",
	["ganlu"] = "甘露",
	[":ganlu"] = "出牌阶段限一次，你可令两名装备区里的牌数不均为0且差不大于你已损失的体力值的角色交换装备区里的牌。",
	["#GanluSwap"] = "%from 令 %to 交换了装备区里的牌",
	["buyi"] = "补益",
	[":buyi"] = "当一名角色A因受到伤害而进入的濒死结算结束后，若A与你势力相同且存活且你于此回合内未发动过此技能，你可令来源B选择是否执行军令▶若B选择否，A回复1点体力。",

	["lukang"] = "陆抗",
	["#lukang"] = "孤柱扶厦",
	["illustrator:lukang"] = "王立雄",
	["keshou"] = "恪守",
	[":keshou"] = "当你受到伤害时，你可弃置两张颜色相同的牌▶伤害值-1。若没有与你势力相同的其他角色，你判定，若结果为红色，你摸一张牌。",
	["zhuwei"] = "筑围",
	[":zhuwei"] = "当你进行的判定结果确定后，若判定牌为包含使用者对目标对应的角色造成伤害的效果的牌，你可获得此牌▶你可令当前回合角色使用【杀】的次数上限于此回合内+1且其手牌上限于此回合内+1。",
	["@keshou"] = "是否发动“恪守”，弃置两张颜色相同的牌减少伤害",
	["@zhuwei-choose"] = "筑围：是否令%src使用【杀】的次数上限和手牌上限+1",
	["#ZhuweiBuff"] = "%from 令 %to 本回合使用【杀】的次数及手牌上限+1",

	["yuanshu"] = "袁术",
	["#yuanshu"] = "仲家帝",
	["illustrator:yuanshu"] = "YanBai",
	["weidi"] = "伪帝",
	[":weidi"] = "出牌阶段限一次，你可令一名于此回合内得到过牌堆里的牌的其他角色选择是否执行军令▶若其选择否，你获得其所有手牌，将等量的牌交给该角色。",
	["@weidi-return"] = "伪帝：请选择要交给%src的%arg张牌",
	["yongsi"] = "庸肆",
	[":yongsi"] = "锁定技，①若所有角色的装备区里均没有【玉玺】，你视为装备着【玉玺】。②当你成为【知己知彼】的目标后，你展示所有手牌。",

	["zhangxiu"] = "张绣",
	["#zhangxiu"] = "北地枪王",
	["designer:zhangxiu"] = "千幻",
	["illustrator:zhangxiu"] = "青岛磐蒲",
	["fudi"] = "附敌",
	[":fudi"] = "当你受到伤害后，你可以将一张手牌交给来源▶你对与其势力相同的所有角色中体力值最大且不小于你的体力值的一名角色造成1点普通伤害。",
	["congjian"] = "从谏",
	[":congjian"] = "锁定技，①当你于回合外造成伤害时，你令伤害值+1。②当你于回合内受到伤害时，你令伤害值+1。",
	["@fudi-give"] = "你可以发动“附敌”，将一张手牌交给伤害来源（%src）",
	["@fudi-damage"] = "附敌：请选择要对其造成伤害的角色",

	["#lord_caocao"] = "凤舞九霄",
	["lord_caocao"] = "君·曹操",
	["&lord_caocao"] = "曹操" ,
	["illustrator:lord_caocao"] = "波子",
	["jianan"] = "建安",
	[":jianan"] = "君主技，锁定技，你拥有\"五子良将纛\"。\n\n#\"五子良将纛\"\n" ..
					"一名魏势力角色的准备阶段开始时，其可弃置一张牌并选择一张暗置的武将牌或暗置两张明置的武将牌中的一张▶其选择下列技能中其他角色均没有的一个：“突袭”、“巧变”、“骁果”、“节钺”、“断粮”。其于你的下个回合开始之前拥有其以此法选择的技能且不能明置其选择的武将牌。",	
	["elitegeneralflag"] = "五子良将纛",
	[":elitegeneralflag"] = "一名魏势力角色的准备阶段开始时，其可弃置一张牌并选择一张暗置的武将牌或暗置两张明置的武将牌中的一张▶其选择下列技能中其他角色均没有的一个：“突袭”、“巧变”、“骁果”、“节钺”、“断粮”。其于你的下个回合开始之前拥有其以此法选择的技能且不能明置其选择的武将牌。",
	["@elitegeneralflag"] = "你可以发动“五子良将纛”，请弃置一张牌",
	["@jianan-hide"] = "五子良将纛：请选择要暗置的武将牌",
	["jianan_hide:head"] = "暗置主将",
	["jianan_hide:deputy"] = "暗置副将",
	["@jianan-skill"] = "五子良将纛：请选择获得的技能",
	["huibian"] = "挥鞭",
	[":huibian"] = "出牌阶段限一次，你可选择一名魏势力角色和另一名已受伤的魏势力角色并对前者造成1点普通伤害▶前者摸两张牌。后者回复1点体力。",
	["zongyu"] = "总御",
	[":zongyu"] = "①当【六龙骖驾】移至其他角色的装备区后，若你的装备区里有坐骑牌，你可交换你与其装备区里的所有坐骑牌。②当坐骑牌被使用时，若使用者为你且{其他角色的装备区或弃牌堆有【六龙骖驾】}，你可将【六龙骖驾】置入你的装备区。",
	["#ZongyuSwap"] = "%from 与 %to 交换了装备区里的坐骑牌",

	["SixDragons"] = "六龙骖驾",
	[":SixDragons"] = "装备牌·坐骑\n\n技能：\n" ..
					"1. 锁定技，你至其他角色的距离-1。\n" ..
					"2. 锁定技，其他角色至你的距离+1。\n" ,
	["horse"] = "坐骑",

	["tuxi_egf"] = "突袭",
	["qiaobian_egf"] = "巧变",
	["xiaoguo_egf"] = "骁果",
	["jieyue_egf"] = "节钺",
	["duanliang_egf"] = "断粮",

	["command"] = "军令",

	["@startcommand"] = "%arg：请选择一项军令<br>%arg2；<br>%arg3",
	["@startcommandto"] = "%arg：请选择一项军令，目标是%dest<br>%arg2；<br>%arg3",
	
	["command1"] = "军令一",
	["command2"] = "军令二",
	["command3"] = "军令三",
	["command4"] = "军令四",
	["command5"] = "军令五",
	["command6"] = "军令六",

	["#command1"] = "军令一：对你指定的角色造成1点伤害",
	["#command2"] = "军令二：摸一张牌，然后交给你两张牌",
	["#command3"] = "军令三：失去1点体力",
	["#command4"] = "军令四：本回合不能使用或打出手牌且所有非锁定技失效",
	["#command5"] = "军令五：叠置，本回合不能回复体力",
	["#command6"] = "军令六：选择一张手牌和一张装备区里的牌，弃置其余的牌",
	
	["#CommandChoice"] = "%from 选择了 %arg",
	
	["#commandselect_yes"] = "执行军令",
	["#commandselect_no"] = "不执行军令",

	["#CommandDamage"] = "%from 选择对 %to 造成伤害",
	
	["@command-damage"] = "军令：请选择伤害的目标",
	["@command-give"] = "军令：请选择两张牌交给%src",
	["@command-select"] = "军令：请选择要保留的一张手牌和一张装备",
	
	["@docommand"] = "%arg：请选择是否执行军令（发起者%src）<br>%arg2",
	["@docommand1"] = "%arg：请选择是否执行军令（发起者%src）<br>军令一：对%src指定的角色造成1点伤害",
	["@docommand2"] = "%arg：请选择是否执行军令（发起者%src）<br>军令二：摸一张牌，然后交给%src两张牌",

	["yes"] = "是",
	["no"] = "否",
	
	
	
	
	
	
	
	
	
	
}