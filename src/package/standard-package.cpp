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

#include "standard-package.h"
#include "engine.h"
#include "exppattern.h"
#include "card.h"
#include "skill.h"
#include "standard-basics.h"
#include "json.h"

//Xusine: we can put some global skills in here,for example,the Global FakeMove.
//just for convenience.

class GlobalProhibit : public ProhibitSkill
{
public:
    GlobalProhibit() : ProhibitSkill("#global-prohibit")
    {
    }

    virtual bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (card->getTypeId() != Card::TypeSkill) {
            if (to->isRemoved()) return true;
            if (from && from->hasFlag("DisabledTargetOthers") && to != from) return true;
            if (card->isKindOf("DelayedTrick") && to->containsTrick(card->objectName())) return true;
        }

        return false;
    }
};

class NoDistanceTargetMod : public TargetModSkill
{
public:
    NoDistanceTargetMod() : TargetModSkill("#nodistance-target")
    {
        pattern = "^SkillCard";
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (card->hasFlag("Global_NoDistanceChecking"))
            return 1000;
        else
            return 0;
    }
};

class GlobalRecord : public TriggerSkill
{
public:
    GlobalRecord() : TriggerSkill("#global-record")
    {
        events << CardsMoveOneTime << Dying << Death << PreDamageDone << CardUsed << CardResponded << TargetChosen;
        global = true;
    }

    virtual bool triggerable(const ServerPlayer *) const
    {
        return false;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardsMoveOneTime) {
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();

                if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                    if (move.from == player && player->getPhase() == Player::Discard) {
                        for (int i = 0; i < move.card_ids.length(); ++i) {
                            if ((move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)) {
                                room->addPlayerMark(player, "GlobalRuleDisCardCount");
                            }
                        }
                    }
                    if (move.reason.m_playerId == player->objectName()) {
                        for (int i = 0; i < move.card_ids.length(); ++i) {
                            if ((move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)) {
                                room->addPlayerMark(player, "GlobalDisCardCount");
                            }
                        }
                    }
                }


                if (move.from == player && !(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip))) {
                    for (int i = 0; i < move.card_ids.length(); ++i) {
                        if ((move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)) {
                            room->addPlayerMark(player, "GlobalLoseCardCount");
                        }
                    }
                }
                if (player->getPhase() != Player::NotActive && move.to_place == Player::DiscardPile) {
                    foreach (int id, move.card_ids) {
                        if (Sanguosha->getCard(id)->isRed())
                            room->addPlayerMark(player, "GlobalZaiqiCount");
                    }

                }
            }

        } else if (triggerEvent == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who != player) return;
            ServerPlayer *killer = dying.damage ? dying.damage->from : NULL;
            ServerPlayer *current = room->getCurrent();

            if (killer && current && current->getPhase() != Player::NotActive)
                room->addPlayerMark(killer, "GlobalDyingCausedCount");

        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != player) return;
            ServerPlayer *killer = death.damage ? death.damage->from : NULL;
            ServerPlayer *current = room->getCurrent();

            if (killer && current && current->getPhase() != Player::NotActive)
                room->addPlayerMark(killer, "GlobalKilledCount");

        } else if (triggerEvent == PreDamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card) {
                QStringList damaged_tag = damage.card->tag["GlobalCardDamagedTag"].toStringList();
                damaged_tag << player->objectName();
                damage.card->setTag("GlobalCardDamagedTag", damaged_tag);
            }

            if (damage.from && (damage.from->distanceTo(player) == 0 || damage.from->distanceTo(player) == 1))
                damage.flags << "kuanggu";

            ServerPlayer *current = room->getCurrent();
            if (current && current->getPhase() != Player::NotActive) {
                if (damage.from) {
                    room->addPlayerMark(damage.from, "Global_DamagePiont_Round", damage.damage);


                    QStringList player_list = damage.from->property("Global_DamagePlayers_Phase").toString().split("+");
                    if (!player_list.contains(player->objectName())) {
                        player_list << player->objectName();
                        damage.flags << "zhidao";
                    }
                    room->setPlayerProperty(damage.from, "Global_DamagePlayers_Phase", player_list.join("+"));


                    if (damage.from->getMark("Global_DamageTimes_Phase") == 0)
                        damage.flags << "zhukou";

                    room->addPlayerMark(damage.from, "Global_DamageTimes_Phase");

                }

                room->addPlayerMark(player, "Global_InjuredPiont_Round", damage.damage);

                room->addPlayerMark(player, "Global_InjuredTimes_Phase");
            }

            data = QVariant::fromValue(damage);

        } else if (triggerEvent == CardUsed || triggerEvent == CardResponded) {
            //to record used/responded cards
            const Card *card = NULL;
            bool is_use = true;
            if (triggerEvent == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                card = use.card;
                if (card->getSkillName() == "duanliang") {
                    if (!use.to.isEmpty() && player->distanceTo(use.to.first()) > 2)
                        room->setPlayerFlag(player, "DuanliangCannot");
                }
                if (card->getSkillName() == "duanliang_egf") {
                    if (!use.to.isEmpty() && player->distanceTo(use.to.first()) > 2)
                        room->setPlayerFlag(player, "DuanliangEGFCannot");
                }

                if (card->isKindOf("Analeptic") && !card->hasFlag("UsedBySecondWay") && use.m_addHistory)
                    room->addPlayerMark(player, "AnalepticUsedTimes");


            } else {
                CardResponseStruct response = data.value<CardResponseStruct>();
                if (!response.m_isUse)
                   is_use = false;
                card = response.m_card;
            }
            if (card && card->getTypeId() != Card::TypeSkill) {




                ServerPlayer *current = room->getCurrent();

                if (current && current->getPhase() != Player::NotActive) {

                    if (is_use) {
                        if (player->getCardUsedTimes("Slash") == 1)
                            room->setCardFlag(card, "GlobalSecondSlash");
                    }

                    if (current->getPhase() == Player::Play) {

                        if (is_use) {
                            room->addPlayerMark(player, "GlobalPlayCardUsedTimes");
                            if (player->getMark("GlobalPlayCardUsedTimes") == 1)
                                room->setCardFlag(card, "GlobalFirstUsedCardinPlay");
                        }

                    }

                }




                QString tag1_name = is_use? "GameUsedCards": "GameRespondedCards";
                QString tag2_name = is_use? "RoundUsedCards": "RoundRespondedCards";
                QString tag3_name = is_use? "PhaseUsedCards": "PhaseRespondedCards";




                QVariantList card_list = player->tag[tag1_name].toList();
                card_list << QVariant::fromValue(card);
                player->tag[tag1_name] = card_list;
                if (current && current->getPhase() != Player::NotActive) {



                    QVariantList card_list = player->tag[tag2_name].toList();
                    card_list << QVariant::fromValue(card);
                    player->tag[tag2_name] = card_list;

                    if (current->getPhase() == Player::Play) {
                        QVariantList card_list = player->tag[tag3_name].toList();

                        if (is_use) {
                            bool xibing = true;
                            foreach (QVariant card_data, card_list) {
                                const Card *card = card_data.value<const Card *>();
                                if (card && card->isBlack() && (card->isNDTrick() || card->isKindOf("Slash"))) {
                                    xibing = false;
                                    break;
                                }
                            }
                            if (xibing && card->isBlack() && (card->isNDTrick() || card->isKindOf("Slash")))
                                room->setCardFlag(card, "GlobalXiBing");

                        }

                        card_list << QVariant::fromValue(card);
                        player->tag[tag3_name] = card_list;
                    }

                }
            }
        } else if (triggerEvent == TargetChosen) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card == NULL || use.card->getTypeId() == Card::TypeSkill) return;

            QStringList use_to_list;

            foreach (ServerPlayer *to, use.to)
                use_to_list << to->objectName();

            use.card->setTag("UseCardTarget", use_to_list);

            if (player->getPhase() != Player::NotActive) {

                QStringList assignee_list = player->property("usecard_targets").toString().split("+");

                foreach (ServerPlayer *to, use.to)
                    assignee_list << to->objectName();

                room->setPlayerProperty(player, "usecard_targets", assignee_list.join("+"));

                if (player->getPhase() == Player::Play) {
                    foreach (ServerPlayer *to, use.to) {
                        if (to != player) {
                            room->setPlayerFlag(player, "TunjiangDisabled");
                            break;
                        }
                    }
                }

            }
        }
    }
};


class GlobalClear : public TriggerSkill
{
public:
    GlobalClear() : TriggerSkill("#global-clear")
    {
        events << EventPhaseStart << EventPhaseChanging;
        global = true;
    }

    virtual bool triggerable(const ServerPlayer *) const
    {
        return false;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    room->setPlayerMark(p, "GlobalRuleDisCardCount", 0);
                    room->setPlayerMark(p, "GlobalDisCardCount", 0);
                    room->setPlayerMark(p, "GlobalDyingCausedCount", 0);
                    room->setPlayerMark(p, "GlobalKilledCount", 0);
                    room->setPlayerMark(p, "GlobalInjuredCount", 0);
                    room->setPlayerMark(p, "Global_MaxcardsIncrease", 0);
                    room->setPlayerMark(p, "Global_MaxcardsDecrease", 0);
                    p->tag.remove("RoundUsedCards");
                    p->tag.remove("RoundRespondedCards");
                    p->tag.remove("PhaseUsedCards");
                    p->tag.remove("PhaseRespondedCards");

                    room->setPlayerMark(p, "skill_invalidity", 0);
                    room->setPlayerMark(p, "skill_invalidity_head", 0);
                    room->setPlayerMark(p, "skill_invalidity_deputy", 0);
                    room->setPlayerProperty(p, "usecard_targets", QVariant());

                    room->setPlayerMark(p, "Global_DamagePiont_Round", 0);
                    room->setPlayerMark(p, "Global_InjuredPiont_Round", 0);

                    room->setPlayerMark(p, "AnalepticUsedTimes", 0);

                    room->setPlayerMark(p, "GlobalZaiqiCount", 0);


                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                room->setPlayerMark(p, "GlobalLoseCardCount", 0);
                room->setPlayerMark(p, "Global_InjuredTimes_Phase", 0);
                room->setPlayerMark(p, "Global_DamageTimes_Phase", 0);
                room->setPlayerProperty(p, "Global_DamagePlayers_Phase", QVariant());
                room->setPlayerMark(player, "GlobalPlayCardUsedTimes", 0);
            }
        }
    }
};

CompanionCard::CompanionCard()
{
    target_fixed = true;
    m_skillName = "companion";
}

void CompanionCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->removePlayerMark(card_use.from, "@companion");
}

void CompanionCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &) const
{
    Peach *peach = new Peach(Card::NoSuit, 0);
    peach->setSkillName("_companion");

    ServerPlayer *dying = room->getCurrentDyingPlayer();
    if (dying && dying->hasFlag("Global_Dying") && !player->isLocked(peach) && !player->isProhibited(dying, peach)) {
        room->useCard(CardUseStruct(peach, player, dying));
        return;
    }

    if (peach->isAvailable(player) && room->askForChoice(player, "companion", "peach+draw", QVariant(), "@companion-choose") == "peach")
        room->useCard(CardUseStruct(peach, player, player));
    else
        player->drawCards(2, "companion");
}

class Companion : public ZeroCardViewAsSkill
{
public:
    Companion() : ZeroCardViewAsSkill("companion")
    {
        frequency = Limited;
        limit_mark = "@companion";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@companion") > 0;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern.contains("peach") && !player->hasFlag("Global_PreventPeach") && player->getMark("@companion") > 0;
    }

    virtual const Card *viewAs() const
    {
        return new CompanionCard;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("Peach") ? 0 : -1;
    }
};

HalfMaxHpCard::HalfMaxHpCard()
{
    target_fixed = true;
    m_skillName = "halfmaxhp";
}

void HalfMaxHpCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->removePlayerMark(card_use.from, "@halfmaxhp");
}

void HalfMaxHpCard::use(Room *, ServerPlayer *player, QList<ServerPlayer *> &) const
{
    player->drawCards(1, "halfmaxhp");
}

class HalfMaxHp : public ZeroCardViewAsSkill
{
public:
    HalfMaxHp() : ZeroCardViewAsSkill("halfmaxhp")
    {
        frequency = Limited;
        limit_mark = "@halfmaxhp";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@halfmaxhp") > 0;
    }

    virtual const Card *viewAs() const
    {
        return new HalfMaxHpCard;
    }
};

class GlobalMaxCards : public MaxCardsSkill
{
public:
    GlobalMaxCards() : MaxCardsSkill("global-maxcards")
    {
    }

    virtual int getExtra(const Player *target) const
    {
        return target->getMark("Global_MaxcardsIncrease") - target->getMark("Global_MaxcardsDecrease");
    }
};

FirstShowCard::FirstShowCard()
{
    m_skillName = "firstshow";
}

bool FirstShowCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->hasShownAllGenerals() && to_select != Self;
}

bool FirstShowCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    foreach (const Player *p, Self->getAliveSiblings()) {
        if (!p->hasShownAllGenerals())
            return targets.length() == 1;
    }
    return targets.length() == 0;
}

void FirstShowCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->removePlayerMark(card_use.from, "@firstshow");
}

void FirstShowCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    player->fillHandCards(4, "firstshow");

    if (targets.isEmpty()) return;

    ServerPlayer *to = targets.first();

    QStringList choices;
    if (!to->hasShownGeneral1())
        choices << "head_general";
    if (to->getGeneral2() && !to->hasShownGeneral2())
        choices << "deputy_general";

    if (choices.isEmpty()) return;
    to->setFlags("XianquTarget");// For AI
    QString choice = room->askForChoice(player, "firstshow_see", choices.join("+"), QVariant::fromValue(to),
        "@firstshow-choose::"+to->objectName(), "head_general+deputy_general");
    to->setFlags("-XianquTarget");

    LogMessage log;
    log.type = "#KnownBothView";
    log.from = player;
    log.to << to;
    log.arg = choice;
    foreach (ServerPlayer *p, room->getOtherPlayers(player, true)) {
        room->doNotify(p, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
    }


    QStringList list = room->getTag(to->objectName()).toStringList();
    list.removeAt(choice == "head_general" ? 1 : 0);
    foreach (const QString &name, list) {
        LogMessage log;
        log.type = "$KnownBothViewGeneral";
        log.from = player;
        log.to << to;
        log.arg = name;
        log.arg2 = choice;
        room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
    }
    JsonArray arg;
    arg << "firstshow";
    arg << JsonUtils::toJsonArray(list);
    room->doNotify(player, QSanProtocol::S_COMMAND_VIEW_GENERALS, arg);

}

class FirstShow : public ZeroCardViewAsSkill
{
public:
    FirstShow() : ZeroCardViewAsSkill("firstshow")
    {
        frequency = Limited;
        limit_mark = "@firstshow";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark(limit_mark) > 0) {
            if (player->getHandcardNum() < 4) return true;
            foreach (const Player *p, player->getAliveSiblings()) {
                if (!p->hasShownAllGenerals())
                    return true;
            }
        }
        return false;
    }

    virtual const Card *viewAs() const
    {
        return new FirstShowCard;
    }
};

CareermanCard::CareermanCard()
{
    target_fixed = true;
    m_skillName = "careerman";
}

void CareermanCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->removePlayerMark(card_use.from, "@careerist");
}

void CareermanCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &) const
{
    Peach *peach = new Peach(Card::NoSuit, 0);
    peach->setSkillName("_careerman");

    ServerPlayer *dying = room->getCurrentDyingPlayer();
    if (dying && dying->hasFlag("Global_Dying") && !player->isLocked(peach) && !player->isProhibited(dying, peach)) {
        room->useCard(CardUseStruct(peach, player, dying));
        return;
    }

    QStringList choices, all_choices;
    all_choices << "draw1card" << "draw2cards" << "peach" << "firstshow";
    choices << "draw1card" << "draw2cards";
    if (peach->isAvailable(player))
        choices << "peach";
    if (player->getHandcardNum() < 4)
        choices << "firstshow";
    else {
        QList<ServerPlayer *> allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (!p->hasShownAllGenerals()) {
                choices << "firstshow";
                break;
            }
        }
    }

    QString choice = room->askForChoice(player, "careerman", choices.join("+"), QVariant(), "@careerman-choose", all_choices.join("+"));

    if (choice == "draw1card") {
        player->drawCards(1, "careerman");
    }
    if (choice == "draw2cards") {
        player->drawCards(2, "careerman");
    }
    if (choice == "peach") {
        room->useCard(CardUseStruct(peach, player, player));
    }
    if (choice == "firstshow") {
        QList<ServerPlayer *> targets, tos;

        QList<ServerPlayer *> allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (!p->hasShownAllGenerals()) {
                targets << p;
            }
        }

        if (!targets.isEmpty()) {
            ServerPlayer *victim = room->askForPlayerChosen(player, targets, "careerman", "@careerman-target");
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), victim->objectName());
            tos << victim;
        }

        FirstShowCard firstshow_card;
        firstshow_card.use(room, player, tos);
    }
}

class Careerman : public ZeroCardViewAsSkill
{
public:
    Careerman() : ZeroCardViewAsSkill("careerman")
    {
        frequency = Limited;
        limit_mark = "@careerist";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@careerist") > 0;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern.contains("peach") && !player->hasFlag("Global_PreventPeach") && player->getMark("@careerist") > 0;
    }

    virtual const Card *viewAs() const
    {
        return new CareermanCard;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("Peach") ? 0 : -1;
    }
};

ShowHeadCard::ShowHeadCard()
{
    target_fixed = true;
}

const Card *ShowHeadCard::validate(CardUseStruct &card_use) const
{
    card_use.from->showGeneral();
    return NULL;
}

ShowDeputyCard::ShowDeputyCard()
{
    target_fixed = true;
}

const Card *ShowDeputyCard::validate(CardUseStruct &card_use) const
{
    card_use.from->showGeneral(false);
    return NULL;
}

class ShowHead : public ZeroCardViewAsSkill
{
public:
    ShowHead() : ZeroCardViewAsSkill("showhead")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasShownGeneral1() && player->canShowGeneral("h");
    }

    virtual const Card *viewAs() const
    {
        return new ShowHeadCard;
    }
};

class ShowDeputy : public ZeroCardViewAsSkill
{
public:
    ShowDeputy() : ZeroCardViewAsSkill("showdeputy")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getGeneral2() && !player->hasShownGeneral2() && player->canShowGeneral("d");
    }

    virtual const Card *viewAs() const
    {
        return new ShowDeputyCard;
    }
};

StandardPackage::StandardPackage()
    : Package("standard")
{
    addWeiGenerals();
    addShuGenerals();
    addWuGenerals();
    addQunGenerals();

    addMetaObject<CompanionCard>();
    addMetaObject<HalfMaxHpCard>();
    addMetaObject<FirstShowCard>();
    addMetaObject<CareermanCard>();
    addMetaObject<ShowHeadCard>();
    addMetaObject<ShowDeputyCard>();

    skills << new GlobalProhibit << new NoDistanceTargetMod << new GlobalRecord << new GlobalClear
           << new Skill("aozhan") << new Companion << new HalfMaxHp << new GlobalMaxCards << new FirstShow << new Careerman
           << new ShowHead << new ShowDeputy;

    patterns["."] = new ExpPattern(".|.|.|hand");
    patterns[".S"] = new ExpPattern(".|spade|.|hand");
    patterns[".C"] = new ExpPattern(".|club|.|hand");
    patterns[".H"] = new ExpPattern(".|heart|.|hand");
    patterns[".D"] = new ExpPattern(".|diamond|.|hand");

    patterns[".black"] = new ExpPattern(".|black|.|hand");
    patterns[".red"] = new ExpPattern(".|red|.|hand");

    patterns[".."] = new ExpPattern(".");
    patterns["..S"] = new ExpPattern(".|spade");
    patterns["..C"] = new ExpPattern(".|club");
    patterns["..H"] = new ExpPattern(".|heart");
    patterns["..D"] = new ExpPattern(".|diamond");

    patterns[".Basic"] = new ExpPattern("BasicCard");
    patterns[".Trick"] = new ExpPattern("TrickCard");
    patterns[".Equip"] = new ExpPattern("EquipCard");

    patterns[".Weapon"] = new ExpPattern("Weapon");
    patterns["slash"] = new ExpPattern("Slash");
    patterns["jink"] = new ExpPattern("Jink");
    patterns["peach"] = new  ExpPattern("Peach");
    patterns["nullification"] = new ExpPattern("Nullification");
    patterns["peach+analeptic"] = new ExpPattern("Peach,Analeptic");
}

ADD_PACKAGE(Standard)


TestPackage::TestPackage()
: Package("test")
{
    new General(this, "sujiang", "god", 5, true, true);
    new General(this, "sujiangf", "god", 5, false, true);

    new General(this, "anjiang", "god", 5, true, true, true);
    new General(this, "anjiang_head", "god", 5, true, true, true);
    new General(this, "anjiang_deputy", "god", 5, true, true, true);

    // developers
    new General(this, "slob", "programmer", 9, true, true, true);
}

ADD_PACKAGE(Test)


StandardCardPackage::StandardCardPackage()
: Package("standard_cards", Package::CardPack)
{
    QList<Card *> cards;

    cards << basicCards() << equipCards() << trickCards();

    foreach (Card *card, cards)
        card->setParent(this);

    addEquipSkills();
}

ADD_PACKAGE(StandardCard)

