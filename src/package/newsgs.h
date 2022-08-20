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

class DaoshuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE DaoshuCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class JingheCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JingheCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void extraCost(Room *room, const CardUseStruct &card_use) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class HuoqiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE HuoqiCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class XianshouCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XianshouCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class FenglveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FenglveCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class FenglveZonghengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FenglveZonghengCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class ZhuangrongCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZhuangrongCard();

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class MingfaCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MingfaCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class MingfaZonghengCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MingfaZonghengCard();

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

class NewSGSPackage : public Package
{
    Q_OBJECT

public:
    NewSGSPackage();
};

ADD_PACKAGE(NewSGS)

#endif // NEWSGS

