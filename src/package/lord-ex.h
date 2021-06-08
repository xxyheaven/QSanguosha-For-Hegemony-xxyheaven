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

#ifndef _LORD_EX_H
#define _LORD_EX_H

#include "package.h"
#include "card.h"
#include "wrappedcard.h"
#include "skill.h"
#include "standard.h"
#include "generaloverview.h"

class PaiyiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE PaiyiCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class QuanjinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QuanjinCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void extraCost(Room *room, const CardUseStruct &card_use) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class ZaoyunCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ZaoyunCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class DiaoguiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE DiaoguiCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;

};

class FengyangSummon : public ArraySummonCard
{
    Q_OBJECT

public:
    Q_INVOKABLE FengyangSummon();
};

class LordEXPackage : public Package
{
    Q_OBJECT

public:
    LordEXPackage();
};



class ImperialEdict : public Treasure
{
    Q_OBJECT

public:
    Q_INVOKABLE ImperialEdict(Card::Suit suit, int number);

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class ImperialEdictAttachCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ImperialEdictAttachCard();

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class ImperialEdictTrickCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ImperialEdictTrickCard();

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class RuleTheWorld : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE RuleTheWorld(Card::Suit suit = Spade, int number = 12);

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class Conquering : public GlobalEffect
{
    Q_OBJECT

public:
    Q_INVOKABLE Conquering(Card::Suit suit = Diamond, int number = 1);

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class ConsolidateCountryGiveCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE ConsolidateCountryGiveCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class ConsolidateCountry : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE ConsolidateCountry(Card::Suit suit = Heart, int number = 1);

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
    virtual bool isAvailable(const Player *player) const;
};

class Chaos : public GlobalEffect
{
    Q_OBJECT

public:
    Q_INVOKABLE Chaos(Card::Suit suit = Club, int number = 12);

    virtual void onEffect(const CardEffectStruct &effect) const;
};

class LordEXCardPackage : public Package
{
    Q_OBJECT

public:
    LordEXCardPackage();
};

#endif // _LORD_EX_H

