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

#ifndef NEWSGS
#define NEWSGS

#include "package.h"
#include "card.h"
#include "wrappedcard.h"
#include "skill.h"
#include "standard.h"
#include "generaloverview.h"

class BoyanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE BoyanCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class BoyanZonghengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE BoyanZonghengCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class WeimengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE WeimengCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class WeimengZonghengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE WeimengZonghengCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};




class ManoeuvrePackage : public Package
{
    Q_OBJECT

public:
    ManoeuvrePackage();
};

ADD_PACKAGE(Manoeuvre)

#endif // NEWSGS

