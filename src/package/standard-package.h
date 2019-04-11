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

#ifndef _STANDARD_PACKAGE_H
#define _STANDARD_PACKAGE_H

#include "package.h"
#include "card.h"
#include "skill.h"

class StandardPackage : public Package {
    Q_OBJECT

public:
    StandardPackage();
    void addWeiGenerals();
    void addShuGenerals();
    void addWuGenerals();
    void addQunGenerals();
};

class CompanionCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE CompanionCard();
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class HalfMaxHpCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HalfMaxHpCard();
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class FirstShowCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FirstShowCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class ShowHeadCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ShowHeadCard();

    const Card *validate(CardUseStruct &card_use) const;
};

class ShowDeputyCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ShowDeputyCard();

    const Card *validate(CardUseStruct &card_use) const;
};

class TestPackage : public Package {
    Q_OBJECT

public:
    TestPackage();
};

class StandardCardPackage : public Package {
    Q_OBJECT

public:
    StandardCardPackage();

    QList<Card *> basicCards();
    QList<Card *> equipCards();
    void addEquipSkills();
    QList<Card *> trickCards();
};

#endif
