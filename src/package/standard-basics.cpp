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

#include "standard-basics.h"
#include "standard-package.h"
#include "engine.h"

Slash::Slash(Suit suit, int number) : BasicCard(suit, number)
{
    setObjectName("slash");
    nature = DamageStruct::Normal;
}

DamageStruct::Nature Slash::getNature() const
{
    return nature;
}

void Slash::setNature(DamageStruct::Nature nature)
{
    this->nature = nature;
}

bool Slash::IsAvailable(const Player *player, const Card *slash, bool considerSpecificAssignee)
{
    Slash *newslash = new Slash(Card::NoSuit, 0);
    newslash->setFlags("Global_AvailabilityChecker");
    newslash->deleteLater();
#define THIS_SLASH (slash == NULL ? newslash : slash)
    if (player->isCardLimited(THIS_SLASH, Card::MethodUse))
        return false;

    if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY
            || Sanguosha->getCurrentCardUsePattern() == "@@rende_basic") {
        QList<int> ids;
        if (slash) {
            if (slash->isVirtualCard()) {
                if (slash->subcardsLength() > 0)
                    ids = slash->getSubcards();
            } else {
                ids << slash->getEffectiveId();
            }
        }
        bool has_weapon = player->hasWeapon("Crossbow") && ids.contains(player->getWeapon()->getEffectiveId());
        if ((!has_weapon && player->hasWeapon("Crossbow")) || player->canSlashWithoutCrossbow(THIS_SLASH))
            return true;

        int used = player->getSlashCount();
        int valid = 1 + Sanguosha->correctCardTarget(TargetModSkill::Residue, player, THIS_SLASH, NULL);
        if (used < valid) return true;

        if (considerSpecificAssignee) {
            QList<const Player *> all_players = player->getAliveSiblings();
            foreach (const Player *p, all_players) {
                if (used < 1 + Sanguosha->correctCardTarget(TargetModSkill::Residue, player, THIS_SLASH, p))
                    return true;
            }
        }
        return false;
    } else {
        return true;
    }
#undef THIS_SLASH
}

bool Slash::IsSpecificAssignee(const Player *player, const Player *from, const Card *slash)
{
    if (from->hasFlag("slashTargetFix") && player->hasFlag("SlashAssignee"))
        return true;
    else if (from->getPhase() == Player::Play && Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY
        && !Slash::IsAvailable(from, slash, false)) {
        return from->getSlashCount() < 1 + Sanguosha->correctCardTarget(TargetModSkill::Residue, from, slash, player);
    }
    return false;
}


bool Slash::isAvailable(const Player *player) const
{
    return IsAvailable(player, this) && BasicCard::isAvailable(player);
}

QString Slash::getSubtype() const
{
    return "attack_card";
}

void Slash::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    ServerPlayer *player = use.from;

    if (player->hasFlag("slashTargetFix")) {
        room->setPlayerFlag(player, "-slashTargetFix");
        room->setPlayerFlag(player, "-slashTargetFixToOne");
        foreach (ServerPlayer *target, room->getAlivePlayers())
            if (target->hasFlag("SlashAssignee"))
                room->setPlayerFlag(target, "-SlashAssignee");
    }

    if (player->hasFlag("slashNoDistanceLimit")) {
        room->setPlayerFlag(player, "-slashNoDistanceLimit");
        room->setCardFlag(this, "slashNoDistanceLimit");
    }
    if (player->hasFlag("slashDisableExtraTarget")) {
        room->setPlayerFlag(player, "-slashDisableExtraTarget");
        room->setCardFlag(this, "slashDisableExtraTarget");
    }

    // for Paoxiao and Crossbow
    if (player->getPhase() == Player::Play && player->hasFlag("Global_MoreSlashInOneTurn")) {
        if (player->hasShownSkill("paoxiao")) {
            player->setFlags("-Global_MoreSlashInOneTurn");
            room->sendCompulsoryTriggerLog(player, "paoxiao");
            room->broadcastSkillInvoke("paoxiao", player);
        } else if (player->hasShownSkill("paoxiao_xh")) {
            player->setFlags("-Global_MoreSlashInOneTurn");
            room->sendCompulsoryTriggerLog(player, "paoxiao_xh");
            room->broadcastSkillInvoke("paoxiao_xh", player);
        } else if (player->hasWeapon("Crossbow")) {
            player->setFlags("-Global_MoreSlashInOneTurn");
            room->sendCompulsoryTriggerLog(player, "Crossbow");
            room->setEmotion(player, "weapon/crossbow");
        }
    }

    if (use.card->isVirtualCard()) {
        if (use.card->getSkillName() == "Spear")
            room->setEmotion(player, "weapon/spear");
    }

    room->setCardEmotion(player, this);

    if (use.from->getMark("drank") > 0) {
        room->setCardFlag(use.card, "drank");
        setTag("drank", use.from->getMark("drank"));
        room->setPlayerMark(use.from, "drank", 0);
    }

    BasicCard::onUse(room, use);
}

void Slash::onEffect(const CardEffectStruct &card_effect) const
{
    SlashEffectStruct effect;
    effect.from = card_effect.from;
    effect.nature = nature;
    effect.slash = this;

    effect.to = card_effect.to;
    effect.drank = this->tag["drank"].toInt();
    effect.nullified = card_effect.nullified;

    QVariantList jink_list = effect.from->tag["Jink_" + toString()].toList();

    int x = jink_list.takeFirst().toInt();

    if (card_effect.disresponsive)
        x = 0;

    effect.jink_num = x;

    if (jink_list.isEmpty())
        effect.from->tag.remove("Jink_" + toString());
    else
        effect.from->tag["Jink_" + toString()] = QVariant::fromValue(jink_list);

    effect.from->getRoom()->slashEffect(effect);
}

bool Slash::targetRated(const Player *to_select, const Player *Self) const
{
    bool distance_limit = ((1 + Sanguosha->correctCardTarget(TargetModSkill::DistanceLimit, Self, this, to_select)) < 500);
    if (Self->hasFlag("slashNoDistanceLimit"))
        distance_limit = false;

    int rangefix = 0;
    if (Self->getWeapon() && subcards.contains(Self->getWeapon()->getId())) {
        const Weapon *weapon = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
        rangefix += weapon->getRange() - Self->getAttackRange(false);
    }

    if (Self->getOffensiveHorse() && subcards.contains(Self->getOffensiveHorse()->getId()))
        rangefix += 1;

    if (Self->getSpecialHorse() && subcards.contains(Self->getSpecialHorse()->getId()))
        rangefix += 1;

    return Self->canSlash(to_select, this, distance_limit, rangefix);
}

bool Slash::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int slash_targets = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this, to_select);

    if (!targetRated(to_select, Self)) return false;
    if (targets.isEmpty()) {
        QList<const Player *> all_players = Self->getSiblings();
        all_players.append(Self);
        foreach (const Player *p, all_players) {
            if (Slash::IsSpecificAssignee(p, Self, this)) {
                return Slash::IsSpecificAssignee(to_select, Self, this);
            }
        }
    }

    return targets.length() < slash_targets;
}

NatureSlash::NatureSlash(Suit suit, int number, DamageStruct::Nature nature)
    : Slash(suit, number)
{
    this->nature = nature;
}

bool NatureSlash::match(const QString &pattern) const
{
    QStringList patterns = pattern.split("+");
    if (patterns.contains("slash"))
        return true;
    else
        return Slash::match(pattern);
}

ThunderSlash::ThunderSlash(Suit suit, int number, bool is_transferable)
    : NatureSlash(suit, number, DamageStruct::Thunder)
{
    setObjectName("thunder_slash");
    transferable = is_transferable;
}

FireSlash::FireSlash(Suit suit, int number)
    : NatureSlash(suit, number, DamageStruct::Fire)
{
    setObjectName("fire_slash");
}

Jink::Jink(Suit suit, int number, bool is_transferable) : BasicCard(suit, number)
{
    setObjectName("jink");
    target_fixed = true;
    transferable = is_transferable;
}

QString Jink::getSubtype() const
{
    return "defense_card";
}

bool Jink::isAvailable(const Player *) const
{
    return false;
}

Peach::Peach(Suit suit, int number, bool is_transferable) : BasicCard(suit, number)
{
    setObjectName("peach");
    target_fixed = true;
    transferable = is_transferable;
}

QString Peach::getSubtype() const
{
    return "recover_card";
}

bool Peach::targetRated(const Player *to_select, const Player *) const
{
    return !hasFlag("UsedBySecondWay") && to_select->isWounded();
}

void Peach::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    room->setCardEmotion(use.from, this);
    BasicCard::onUse(room, use);
}

void Peach::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    // recover hp
    RecoverStruct recover;
    recover.card = this;
    recover.who = effect.from;
    room->recover(effect.to, recover);
}

bool Peach::isAvailable(const Player *player) const
{
    return player->isWounded() && !player->isProhibited(player, this) && BasicCard::isAvailable(player);
}

Analeptic::Analeptic(Card::Suit suit, int number, bool is_transferable)
    : BasicCard(suit, number)
{
    setObjectName("analeptic");
    target_fixed = true;
    transferable = is_transferable;
}

QString Analeptic::getSubtype() const
{
    return "buff_card";
}

bool Analeptic::targetRated(const Player *, const Player *) const
{
    return !hasFlag("UsedBySecondWay");
}

bool Analeptic::IsAvailable(const Player *player, const Card *analeptic)
{
    Analeptic *newanal = new Analeptic(Card::NoSuit, 0);
    newanal->setFlags("Global_AvailabilityChecker");
    newanal->deleteLater();
#define THIS_ANAL (analeptic == NULL ? newanal : analeptic)
    if (player->isCardLimited(THIS_ANAL, Card::MethodUse) || player->isProhibited(player, THIS_ANAL))
        return false;

    return player->getMark("AnalepticUsedTimes") <= Sanguosha->correctCardTarget(TargetModSkill::Residue, player, THIS_ANAL, player);
#undef THIS_ANAL
}

bool Analeptic::isAvailable(const Player *player) const
{
    return IsAvailable(player, this) && BasicCard::isAvailable(player);
}

void Analeptic::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    room->setCardEmotion(use.from, this);
    BasicCard::onUse(room, use);
}

void Analeptic::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    if (hasFlag("UsedBySecondWay")) {
        // recover hp
        RecoverStruct recover;
        recover.card = this;
        recover.who = effect.from;
        room->recover(effect.to, recover);
    } else {
        room->addPlayerMark(effect.to, "drank");
    }
}

QList<Card *> StandardCardPackage::basicCards()
{
    QList<Card *> cards;


    cards
        << new Slash(Card::Spade, 5)
        << new Slash(Card::Spade, 7)
        << new Slash(Card::Spade, 8)
        << new Slash(Card::Spade, 8)
        << new Slash(Card::Spade, 9)
        << new Slash(Card::Spade, 10)
        << new Slash(Card::Spade, 11)

        << new Slash(Card::Club, 2)
        << new Slash(Card::Club, 3)
        << new Slash(Card::Club, 4)
        << new Slash(Card::Club, 5)
        << new Slash(Card::Club, 8)
        << new Slash(Card::Club, 9)
        << new Slash(Card::Club, 10)
        << new Slash(Card::Club, 11)
        << new Slash(Card::Club, 11)

        << new Slash(Card::Heart, 10)
        << new Slash(Card::Heart, 12)

        << new Slash(Card::Diamond, 10)
        << new Slash(Card::Diamond, 11)
        << new Slash(Card::Diamond, 12)

        << new FireSlash(Card::Heart, 4)

        << new FireSlash(Card::Diamond, 4)
        << new FireSlash(Card::Diamond, 5)

        << new ThunderSlash(Card::Spade, 6)
        << new ThunderSlash(Card::Spade, 7)

        << new ThunderSlash(Card::Club, 6)
        << new ThunderSlash(Card::Club, 7)
        << new ThunderSlash(Card::Club, 8)

        << new Jink(Card::Heart, 2)
        << new Jink(Card::Heart, 11)
        << new Jink(Card::Heart, 13)

        << new Jink(Card::Diamond, 2)
        << new Jink(Card::Diamond, 3)
        << new Jink(Card::Diamond, 6)
        << new Jink(Card::Diamond, 7)
        << new Jink(Card::Diamond, 7)
        << new Jink(Card::Diamond, 8)
        << new Jink(Card::Diamond, 8)
        << new Jink(Card::Diamond, 9)
        << new Jink(Card::Diamond, 10)
        << new Jink(Card::Diamond, 11)
        << new Jink(Card::Diamond, 13)

        << new Peach(Card::Heart, 4)
        << new Peach(Card::Heart, 6)
        << new Peach(Card::Heart, 7)
        << new Peach(Card::Heart, 8)
        << new Peach(Card::Heart, 9)
        << new Peach(Card::Heart, 10)
        << new Peach(Card::Heart, 12)

        << new Peach(Card::Diamond, 2)

        << new Analeptic(Card::Spade, 9)

        << new Analeptic(Card::Club, 9)

        << new Analeptic(Card::Diamond, 9);

    return cards;
}
