/********************************************************************
    Copyright (c) 2013-2015 - Mogara

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
    *********************************************************************/

#ifndef _JIANGE_DEFENSE_PACKAGE_H
#define _JIANGE_DEFENSE_PACKAGE_H

#include "package.h"
#include "standard.h"

class JGKedingCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JGKedingCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JGJiaoxieCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JGJiaoxieCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class JiangeDefensePackage : public Package
{
    Q_OBJECT

public:
    JiangeDefensePackage();
};

#endif
