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
--shelie for lord_sunquan

differentsuit = function(selected, to_select)
    local sum = 0
	--if table.contains(selected, to_select) then return true end
    for _, id in ipairs(selected) do
        if sgs.Sanguosha:getCard(to_select):getSuit() == sgs.Sanguosha:getCard(id):getSuit() then
			return false
		end
	end
	return true
end

