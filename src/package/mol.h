/********************************************************************
    Copyright (c) 2013-2015 - Mogara

    This file is part of QSanguosha-Hegemony.

    This game is free software; you can redistribute it and/or
    modify it under the terms of the MOL General Public License as
    published by the Free Software Foundation; either version 3.0
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    See the LICENSE file for more details.

    Mogara
    *********************************************************************/

#ifndef _MOL_H
#define _MOL_H

#include "package.h"
#include "card.h"
#include "wrappedcard.h"
#include "skill.h"
#include "standard.h"
#include "generaloverview.h"



class MiewuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MiewuCard();

    virtual bool targetFixed() const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual const Card *validate(CardUseStruct &card_use) const;
    virtual const Card *validateInResponse(ServerPlayer *user) const;
    virtual void validateAfter(CardUseStruct &cardUse) const;
    virtual void validateInResponseAfter(ServerPlayer *user) const;
};



class GuishuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE GuishuCard();

    virtual bool targetFixed() const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class HongyuanCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HongyuanCard();
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    virtual void extraCost(Room *room, const CardUseStruct &card_use) const;
};

class ZhaofuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhaofuCard();

    virtual void onEffect(const CardEffectStruct &effect) const;
};

class ZhaofuVSCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhaofuVSCard();

    virtual bool targetFixed() const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class JiansuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JiansuCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class ShangshiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ShangshiCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void extraCost(Room *room, const CardUseStruct &card_use) const;
};

class HuxunMoveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HuxunMoveCard();

    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &use) const;
};

class ShefuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ShefuCard();

    virtual void extraCost(Room *room, const CardUseStruct &card_use) const;
};




class MOLPackage : public Package
{
    Q_OBJECT

public:
    MOLPackage();
};

ADD_PACKAGE(MOL)

class OverseasPackage : public Package
{
    Q_OBJECT

public:
    OverseasPackage();
};

ADD_PACKAGE(Overseas)

#endif // _MOL_H

