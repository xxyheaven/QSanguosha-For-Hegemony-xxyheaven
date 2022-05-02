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
	-- 吴势力
	["#sunquan"] = "年轻的贤君",
	["sunquan"] = "孙权",
	["zhiheng"] = "制衡",
	[":zhiheng"] = "出牌阶段限一次，你可弃置至多X张牌（X为你的体力上限）▶你摸等量的牌。",

	["#ganning"] = "锦帆游侠",
	["ganning"] = "甘宁",
	["qixi"] = "奇袭",
	[":qixi"] = "你可将一张黑色牌当【过河拆桥】使用。",

	["#lvmeng"] = "白衣渡江",
	["illustrator:lvmeng"] = "樱花闪乱",
	["lvmeng"] = "吕蒙",
	["keji"] = "克己",
	[":keji"] = "锁定技，弃牌阶段开始时，若你于出牌阶段内未使用过有颜色的牌或于出牌阶段内使用过的所有的牌的颜色均相同，你的手牌上限于此回合内+4。",
	["mouduan"] = "谋断",
	[":mouduan"] = "结束阶段开始时，若你于出牌阶段内使用过四种花色或三种类别的牌，你可将一名角色的判定/装备区里的一张牌置入另一名角色的判定/装备区。",
	["@mouduan-move"] = "谋断：你可以移动场上的一张牌",

	["#huanggai"] = "轻身为国",
	["illustrator:huanggai"] = "G.G.G.",
	["huanggai"] = "黄盖",
	["kurou"] = "苦肉",
	[":kurou"] = "出牌阶段限一次，你可弃置一张牌▶你失去1点体力。你摸三张牌。你于此回合内使用【杀】的次数上限+1。",

	["#zhouyu"] = "大都督",
	["zhouyu"] = "周瑜",
	["illustrator:zhouyu"] = "绘聚艺堂",
	["yingzi_zhouyu"] = "英姿",
	[":yingzi"] = "锁定技，①摸牌阶段，你令额定摸牌数+1。②你的手牌上限为X（X为你的体力上限）。",
	["fanjian"] = "反间",
	[":fanjian"] = "出牌阶段限一次，你可展示一张手牌▶你将此牌交给一名角色。其选择：1.展示所有手牌，弃置与你以此法展示的牌花色相同的所有牌；2.失去1点体力。",
	["fanjian_show:prompt"] = "反间：点确定展示手牌并弃置所有%arg牌，点取消失去1点体力",
	
	["#daqiao"] = "矜持之花",
	["daqiao"] = "大乔",
	["guose"] = "国色",
	[":guose"] = "你可将一张方块牌当【乐不思蜀】使用。",
	["liuli"] = "流离",
	[":liuli"] = "当你成为【杀】的目标时，你可弃置一张牌并选择你的攻击范围内的一名是此【杀】的合法目标且与此牌的目标列表中的所有角色均无对应的关系的角色（距离关系限制规则对此次合法性检测不产生影响）▶此【杀】转移给该角色。",
	["~liuli"] = "选择一张牌→选择一名其他角色→点击确定",
	["@liuli"] = "%src 对你使用【杀】，你可以弃置一张牌发动“流离”",

	["#luxun"] = "擎天之柱",
	["luxun"] = "陆逊",
	["qianxun"] = "谦逊",
	["qianxun-cancel"] = "谦逊",
	[":qianxun"] = "锁定技，①当你成为【顺手牵羊】的目标时，你取消此目标。②当【乐不思蜀】对应的实体牌移至你的判定区前，你将此牌置入弃牌堆。",
	["duoshi"] = "度势",
	[":duoshi"] = "每阶段限四次，你可将一张红色手牌当【以逸待劳】使用。",

	["#sunshangxiang"] = "弓腰姬",
	["sunshangxiang"] = "孙尚香",
	["jieyin"] = "结姻",
	[":jieyin"] = "出牌阶段限一次，你可弃置两张手牌并选择一名已受伤的其他男性角色▶你与其各回复1点体力。",
	["xiaoji"] = "枭姬",
	["xiaojidraw"] = "枭姬",
	[":xiaoji"] = "当你失去装备区里的牌后，若当前回合角色：为你，你摸一张牌；不为你，你摸三张牌。",

	["#sunjian"] = "武烈帝",
	["sunjian"] = "孙坚",
	["illustrator:sunjian"] = "LiuHeng",
	["yinghun_sunjian"] = "英魂",
	[":yinghun"] = "准备阶段开始时，你可选择一名其他角色▶你选择：1.{其摸X张牌。其弃置一张牌。}；2. {其摸一张牌。其弃置X张牌。}。（X为你已损失的体力值）",
	["yinghun-invoke"] = "你可以发动“英魂”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["#yinghun_sunjian"] = "英魂 对 %to",
	["yinghun_sunjian:d1tx"] = "令其摸 1 张牌，然后弃置 %log 张牌",
	["yinghun_sunjian:dxt1"] = "令其摸 %log 张牌，然后弃置 1 张牌",

	["#xiaoqiao"] = "矫情之花",
	["xiaoqiao"] = "小乔",
	["illustrator:xiaoqiao"] = "绘聚艺堂",
	["hongyan"] = "红颜",
	[":hongyan"] = "锁定技，①你的黑桃牌或你的黑桃判定牌的花色视为红桃。②若你的装备区里有红色牌，你的手牌上限+1。",
	["tianxiang"] = "天香",
	[":tianxiang"] = "当你受到伤害时，若你于当前回合内发动此技能的次数小于2，你可弃置一张红桃手牌并选择一名其他角色▶你防止此伤害，选择于当前回合内未选择过的一项："..
		"1.令来源对其造成1点普通伤害▷其摸X张牌（X=min{其已损失的体力值,5}）；2.令其失去1点体力▷若牌堆/弃牌堆里有你以此法弃置的牌，其获得牌堆/弃牌堆里的你以此法弃置的牌。",
	["@tianxiang-card"] = "你可以弃置一张红桃牌对一名其他角色发动“天香”",
	["@tianxiang-choose"] = "天香：请选择令%dest受到伤害并摸牌，或令%dest失去体力并获得【%arg】",
	["tianxiang:damage"] = "令 %from 对 %to 造成1点伤害",
	["tianxiang:losehp"] = "令 %to 失去1体力并获得卡牌【%log】",

	["#taishici"] = "笃烈之士",
	["taishici"] = "太史慈",
	["illustrator:taishici"] = "Tuu.",
	["tianyi"] = "天义",
	[":tianyi"] = "出牌阶段限一次，你可与一名角色拼点。若你：赢，你于此回合内使用【杀】的次数上限和额定目标数上限均+1且使用【杀】无距离关系的限制；未赢，你于此回合内不能使用【杀】。",

	["#zhoutai"] = "历战之躯",
	["zhoutai"] = "周泰",
	["illustrator:zhoutai"] = "Thinking",
	["buqu"] = "不屈",
	[":buqu"] = "锁定技，当你处于濒死状态时，你将牌堆顶的一张牌置于武将牌上（称为“创”）。若：没有与此“创”点数相同的其他“创”，你将体力回复至1点；有与此“创”点数相同的其他“创”，你将此“创”置入弃牌堆。",
	["scars"] = "创",
	["#BuquDuplicate"] = "%from 发动“<font color=\"yellow\"><b>不屈</b></font>”失败，其“创”中有 %arg 组重复点数",
	["#BuquDuplicateGroup"] = "第 %arg 组重复点数为 %arg2",
	["$BuquDuplicateItem"] = "重复“创”: %card",
	["$BuquRemove"] = "%from 移除了“创”：%card",
	["fenji"] = "奋激",
	[":fenji"] = "一名角色的结束阶段开始时，若其没有手牌，你可令其摸两张牌，你失去1点体力。",

	["#lusu"] = "独断的外交家",
	["lusu"] = "鲁肃",
	["illustrator:lusu"] = "LiuHeng",
	["haoshi"] = "好施",
	[":haoshi"] = "摸牌阶段，你可令额定摸牌数+2▶摸牌阶段结束时，若你的手牌数大于5，你将一半的手牌交给一名手牌数最小的其他角色。",
	["#haoshi-give"] = "好施[给牌]",
	["@haoshi-give"] = "好施：选择%arg张手牌交给一名角色",
	["dimeng"] = "缔盟",
	[":dimeng"] = "出牌阶段限一次，你可选择两名其他角色并弃置X张牌（X为这两名角色手牌数的差），令这两名角色交换手牌。",
	["#Dimeng"] = "%from (原来 %arg 手牌) 与 %to (原来 %arg2 手牌) 交换了手牌",

	["#erzhang"] = "经天纬地",
	["erzhang"] = "张昭＆张纮",
	["&erzhang"] = "张昭张纮",
	["illustrator:erzhang"] = "废柴男",
	["zhijian"] = "直谏",
	[":zhijian"] = "出牌阶段，你可将手牌区里的一张装备牌置入一名其他角色的装备区▶你摸一张牌。",
	["guzheng"] = "固政",
	[":guzheng"] = "其他角色的弃牌阶段结束时，你可将弃牌堆里的一张曾是其于此阶段内弃置过的其手牌的牌交给该角色▶你可获得弃牌堆里的所有曾是于此阶段内因弃置而移至弃牌堆的牌的牌。",
	["$ZhijianEquip"] = "%from 被装备了 %card",
	["@guzheng"] = "你可以发动“固政”，令 %src 获得其弃置的牌中一张牌" ,
	["@guzheng-obtain"] = "固政：是否获得弃牌堆里的其余于此阶段内弃置的牌",
	["#guzheng"] = "固政",
	["#guzhengOther"] = "固政",

	["#dingfeng"] = "清侧重臣",
	["dingfeng"] = "丁奉",
	["illustrator:dingfeng"] = "魔鬼鱼",
	["duanbing"] = "短兵",
	[":duanbing"] = "当【杀】选择目标后，若使用者为你，你可令一名距离为1的角色也成为此【杀】的目标。",
	["duanbing-invoke"] = "是否使用“短兵”，选择一名距离1的角色为杀的目标",
	["fenxun"] = "奋迅",
	[":fenxun"] = "出牌阶段限一次，你可弃置一张牌并选择一名其他角色▶你至其的距离于此回合内视为1。",

}

