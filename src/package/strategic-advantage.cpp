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

#include "strategic-advantage.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "engine.h"
#include "client.h"
#include "roomthread.h"
#include "json.h"

Blade::Blade(Card::Suit suit, int number)
    : Weapon(suit, number, 3)
{
    setObjectName("Blade");
}

class BladeSkill : public WeaponSkill
{
public:
    BladeSkill() : WeaponSkill("Blade")
    {
        events << CardUsed << CardFinished;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->hasFlag("BladeEffect")) {
                foreach (ServerPlayer *p, use.to) {
                    room->removePlayerDisableShow(p, "Blade");
                }
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (triggerEvent == CardUsed && use.card->isKindOf("Slash") && WeaponSkill::triggerable(player))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        room->setEmotion(player, "weapon/blade");
        room->setCardFlag(use.card, "BladeEffect");
        foreach (ServerPlayer *p, use.to) {
            room->setPlayerDisableShow(p, "hd", "Blade"); // this effect should always make sense.
        }

        return false;
    }
};

Halberd::Halberd(Card::Suit suit, int number)
    : Weapon(suit, number, 4)
{
    setObjectName("Halberd");
}

 HalberdCard::HalberdCard()
 {
 }

 bool HalberdCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
 {
     const Card *slash = Card::Parse(Self->property("halberd_slash").toString());
     if (slash == NULL) return false;
     QStringList tos = Self->property("halberd_slash_current_targets").toString().split("+");

     foreach (const Player *t, targets) {
         if (to_select->isFriendWith(t))
             return false;
     }
     foreach (QString name, tos) {
         foreach(const Player *sib, Self->getAliveSiblings()) {
             if (sib->objectName() == name && to_select->isFriendWith(sib))
                 return false;
         }
     }

     return Self->canSlash(to_select, slash);
 }

 void HalberdCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
 {
     room->setEmotion(source, "weapon/halberd");
     QVariantList target_list;
     foreach (ServerPlayer *target, targets) {
         target_list << QVariant::fromValue(target);
     }

     source->tag["halberd_invoke"] = target_list;
 }

 class HalberdViewAsSkill : public ZeroCardViewAsSkill
 {
 public:
     HalberdViewAsSkill() : ZeroCardViewAsSkill("Halberd")
     {
         response_pattern = "@@Halberd";
     }

     virtual const Card *viewAs() const
     {
         return new HalberdCard;
     }
 };

class HalberdSkill : public WeaponSkill
{
public:
    HalberdSkill() : WeaponSkill("Halberd")
    {
        events << TargetChoosing;
        view_as_skill = new HalberdViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (WeaponSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash") && !use.card->hasFlag("slashDisableExtraTarget")) {
            bool no_distance_limit = false, has_target = false;
            if (use.card->hasFlag("slashNoDistanceLimit")){
                no_distance_limit = true;
                room->setPlayerFlag(player, "slashNoDistanceLimit");
            }
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                bool has_kingdom = false;
                foreach (ServerPlayer *t, use.to) {
                    if (t->isFriendWith(p)) {
                        has_kingdom = true;
                        break;
                    }
                }

                if (!has_kingdom && player->canSlash(p, use.card)) {
                    has_target = true;
                    break;
                }

                if (use.card->targetFilter(QList<const Player *>(), p, player)) {
                    has_target = true;
                    break;
                }
            }
            if (no_distance_limit)
                room->setPlayerFlag(player, "-slashNoDistanceLimit");
            if (has_target)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        bool no_distance_limit = false;
        if (use.card->hasFlag("slashNoDistanceLimit")){
            no_distance_limit = true;
            room->setPlayerFlag(player, "slashNoDistanceLimit");
        }

        QStringList tos;
        foreach(ServerPlayer *t, use.to)
            tos.append(t->objectName());
        room->setPlayerProperty(player, "halberd_slash", use.card->toString()); // for the client (UI)
        room->setPlayerProperty(player, "halberd_slash_current_targets", tos.join("+"));
        const Card *halberdskill = room->askForUseCard(player, "@@Halberd", "@halberd-use");
        room->setPlayerProperty(player, "halberd_slash", QString());
        room->setPlayerProperty(player, "halberd_slash_current_targets", QString());

        if (no_distance_limit)
            room->setPlayerFlag(player, "-slashNoDistanceLimit");

        if (halberdskill != NULL && player->tag.contains("halberd_invoke"))
            return true;

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *source, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QVariantList target_list = source->tag["halberd_invoke"].toList();
        source->tag.remove("halberd_invoke");
        foreach (QVariant x, target_list) {
            use.to.append(x.value<ServerPlayer *>());
        }
        room->sortByActionOrder(use.to);
        room->setCardFlag(use.card, "halberd_slash");
        data = QVariant::fromValue(use);
        return false;
    }
};

class HalberdTrigger : public WeaponSkill
{
public:
    HalberdTrigger() : WeaponSkill("Halberd-trigger")
    {
        events << SlashMissed << SlashEffected;
        global = true;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == SlashMissed) {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            if (effect.slash->hasFlag("halberd_slash"))
                effect.slash->setFlags("halberd_slash_missed");
        } else if (triggerEvent == SlashEffected) {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            if (effect.slash->hasFlag("halberd_slash_missed"))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        LogMessage log;
        log.type = "#HalberdNullified";
        log.from = effect.from;
        log.to << effect.to;
        log.arg = "Halberd";
        log.arg2 = effect.slash->objectName();
        room->sendLog(log);
        return true;
    }
};

Breastplate::Breastplate(Card::Suit suit, int number)
    : Armor(suit, number)
{
    setObjectName("Breastplate");
    transferable = true;
}

// class BreastplateViewAsSkill : public ZeroCardViewAsSkill
// {
// public:
//     BreastplateViewAsSkill() : ZeroCardViewAsSkill("Breastplate")
//     {
//     }
// 
//     virtual const Card *viewAs() const
//     {
//         TransferCard *card = new TransferCard;
//         card->addSubcard(Self->getArmor());
//         card->setSkillName("transfer");
//         return card;
//     }
// };

class BreastplateSkill : public ArmorSkill
{
public:
    BreastplateSkill() : ArmorSkill("Breastplate")
    {
        events << DamageInflicted;
        frequency = Compulsory;
        //view_as_skill = new BreastplateViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->ingoreArmor(player)) return QStringList();
        if (ArmorSkill::triggerable(player) && damage.damage >= player->getHp() && player->getArmor())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->askForSkillInvoke(this);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), objectName(), QString());
        room->moveCardTo(player->getArmor(), NULL, Player::DiscardPile, reason, true);
        DamageStruct damage = data.value<DamageStruct>();
        LogMessage log;
        log.type = "#Breastplate";
        log.from = player;
        if (damage.from)
            log.to << damage.from;
        log.arg = QString::number(damage.damage);
        if (damage.nature == DamageStruct::Normal)
            log.arg2 = "normal_nature";
        else if (damage.nature == DamageStruct::Fire)
            log.arg2 = "fire_nature";
        else if (damage.nature == DamageStruct::Thunder)
            log.arg2 = "thunder_nature";
        room->sendLog(log);
        return true;
    }
};

IronArmor::IronArmor(Card::Suit suit, int number)
    : Armor(suit, number)
{
    setObjectName("IronArmor");
}

class IronArmorSkill : public ArmorSkill
{
public:
    IronArmorSkill() : ArmorSkill("IronArmor")
    {
        events << TargetConfirming;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!ArmorSkill::triggerable(player)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card) return QStringList();
        if (use.from && use.from->ingoreArmor(player)) return QStringList();
        if (!use.to.contains(player) || player->getMark("Equips_of_Others_Nullified_to_You") > 0) return QStringList();
        if (use.card->isKindOf("FireAttack") || use.card->isKindOf("FireSlash") || use.card->isKindOf("BurningCamps"))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return ArmorSkill::cost(room, player, data);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        LogMessage log2;
        log2.type = "#IronArmor";
        log2.from = player;
        log2.arg = objectName();
        room->sendLog(log2);

        room->cancelTarget(use, player); // Room::cancelTarget(use, player);

        data = QVariant::fromValue(use);
        return false;
    }
};

WoodenOxCard::WoodenOxCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
    m_skillName = "WoodenOx";
}

void WoodenOxCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->addToPile("wooden_ox", subcards, false);

    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
        if (!p->getTreasure())
            targets << p;
    }
    if (targets.isEmpty())
        return;
    ServerPlayer *target = room->askForPlayerChosen(source, targets, "WoodenOx", "@wooden_ox-move", true);
    if (target) {
        const Card *treasure = source->getTreasure();
        if (treasure)
            room->moveCardTo(treasure, source, target, Player::PlaceEquip,
            CardMoveReason(CardMoveReason::S_REASON_TRANSFER,
            source->objectName(), "WoodenOx", QString()));
    }
}

class WoodenOxSkill : public OneCardViewAsSkill
{
public:
    WoodenOxSkill() : OneCardViewAsSkill("WoodenOx")
    {
        filter_pattern = ".|.|.|hand";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("WoodenOxCard") && player->getPile("wooden_ox").length() < 5;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        WoodenOxCard *card = new WoodenOxCard;
        card->addSubcard(originalCard);
        card->setSkillName("WoodenOx");
        return card;
    }
};

class WoodenOxTriggerSkill : public TreasureSkill
{
public:
    WoodenOxTriggerSkill() : TreasureSkill("WoodenOx_trigger")
    {
        events << PreCardsMoveOneTime;
        global = true;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const
    {
        return target != NULL && target->isAlive();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            for (int i = 0; i < move.card_ids.size(); i++) {
                const Card *card = Sanguosha->getEngineCard(move.card_ids[i]);
                if (card->objectName() == "WoodenOx") {
                    if (move.from_places[i] == Player::PlaceEquip) {
                        ServerPlayer *player = (ServerPlayer *)move.from;
                        if (!player || player->getPile("wooden_ox").isEmpty()) return false;
                        ServerPlayer *to = (ServerPlayer *)move.to;
                        if (to && move.to_place == Player::PlaceEquip) {
                            QList<ServerPlayer *> p_list;
                            p_list << to;
                            to->addToPile("wooden_ox", player->getPile("wooden_ox"), false, p_list);
                        } else if (move.to_place == Player::PlaceTable && move.reason.m_reason == CardMoveReason::S_REASON_SWAP) {
                            room->setTag("wooden_ox_temp", IntList2VariantList(player->getPile("wooden_ox")));
                            CardsMoveStruct move(player->getPile("wooden_ox"), NULL, Player::PlaceTable,
                                CardMoveReason(CardMoveReason::S_REASON_SWAP, player->objectName(), "WoodenOx", QString()));
                            room->moveCardsAtomic(move, false);
                        } else {
                            player->clearOnePrivatePile("wooden_ox");
                        }
                    } else if (move.from_places[i] == Player::PlaceTable) {
                        QVariantList record = room->getTag("wooden_ox_temp").toList();
                        QList<int> cardsToGet;
                        foreach (QVariant card_data, record) {
                            int card_id = card_data.toInt();
                            if (room->getCardPlace(card_id) == Player::PlaceTable)
                                cardsToGet << card_id;
                        }
                        if (cardsToGet.isEmpty()) return false;
                        ServerPlayer *to = (ServerPlayer *)move.to;
                        if (to && move.to_place == Player::PlaceEquip) {
                            QList<ServerPlayer *> p_list;
                            p_list << to;
                            to->addToPile("wooden_ox", cardsToGet, false, p_list,
                                          CardMoveReason(CardMoveReason::S_REASON_SWAP, to->objectName(), "WoodenOx", QString()));
                        } else {
                            DummyCard *dummy = new DummyCard(cardsToGet);
                            dummy->deleteLater();
                            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, QString());
                            room->throwCard(dummy, reason, NULL);
                        }
                    }
                    return false;
                }
            }
        }
        return false;
    }
};

WoodenOx::WoodenOx(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("WoodenOx");
}

void WoodenOx::onUninstall(ServerPlayer *player) const
{
    player->getRoom()->addPlayerHistory(player, "WoodenOxCard", 0);
    Treasure::onUninstall(player);
}

JadeSeal::JadeSeal(Card::Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("JadeSeal");
}

class JadeSealViewAsSkill : public ZeroCardViewAsSkill
{
public:
    JadeSealViewAsSkill() : ZeroCardViewAsSkill("JadeSeal")
    {
        response_pattern = "@@JadeSeal!";
    }

    virtual const Card *viewAs() const
    {
        KnownBoth *kb = new KnownBoth(Card::NoSuit, 0);
        kb->setSkillName("_"+objectName());
        return kb;
    }
};

class JadeSealSkill : public TreasureSkill
{
public:
    JadeSealSkill() : TreasureSkill("JadeSeal")
    {
        events << DrawNCards << EventPhaseStart;
        view_as_skill = new JadeSealViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TreasureSkill::triggerable(player) || !player->hasShownOneGeneral())
            return QStringList();
        if (triggerEvent == DrawNCards) {
            return QStringList(objectName());
        } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Play) {
            KnownBoth *kb = new KnownBoth(Card::NoSuit, 0);
            kb->setSkillName(objectName());
            kb->deleteLater();
            if (kb->isAvailable(player))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == DrawNCards) {
            if (player->hasShownSkill("yongsi") && player->getTreasure() == NULL) {
                room->sendCompulsoryTriggerLog(player, "yongsi");
                room->broadcastSkillInvoke("yongsi", 1, player);
                return true;
            }
        }
        room->sendCompulsoryTriggerLog(player, objectName());
        return true;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DrawNCards)
            data = data.toInt() + 1;
        else if (triggerEvent == EventPhaseStart) {
            KnownBoth *kb = new KnownBoth(Card::NoSuit, 0);
            kb->setSkillName("_"+objectName());
            QList<ServerPlayer *> targets;
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!player->isProhibited(p, kb) && (!p->isKongcheng() || !p->hasShownAllGenerals()))
                    targets << p;
            }
            if (targets.isEmpty()) {
                delete kb;
            } else if (!room->askForUseCard(player, "@@JadeSeal!", "@JadeSeal")) {
                ServerPlayer *target = targets.at(qrand() % targets.length());
                room->useCard(CardUseStruct(kb, player, target), false);
            }
        }
        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("KnownBoth") ? 0 : -1;
    }
};

void JadeSeal::onInstall(ServerPlayer *player) const
{
    Treasure::onInstall(player);
    JsonArray arg;
    arg << QSanProtocol::S_GAME_EVENT_UPDATE_ROLEBOX;
    player->getRoom()->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);
}

void JadeSeal::onUninstall(ServerPlayer *player) const
{
    Treasure::onUninstall(player);
    JsonArray arg;
    arg << QSanProtocol::S_GAME_EVENT_UPDATE_ROLEBOX;
    player->getRoom()->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);
}

Drowning::Drowning(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("drowning");
}

bool Drowning::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    if (targets.length() >= total_num)
        return false;

    return to_select->hasEquip() && to_select != Self;
}

void Drowning::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    if (!effect.to->getEquips().isEmpty()
        && room->askForChoice(effect.to, objectName(), "throw+damage", QVariant::fromValue(effect)) == "throw")
        effect.to->throwAllEquips();
    else
        room->damage(DamageStruct(this, effect.from->isAlive() ? effect.from : NULL, effect.to, 1, DamageStruct::Thunder));
}

QStringList Drowning::checkTargetModSkillShow(const CardUseStruct &use) const
{
    if (use.card == NULL)
        return QStringList();

    if (use.to.length() >= 2) {
        const ServerPlayer *from = use.from;
        QList<const Skill *> skills = from->getSkillList(false, false);
        QList<const TargetModSkill *> tarmods;

        foreach (const Skill *skill, skills) {
            if (from->hasSkill(skill) && skill->inherits("TargetModSkill")) {
                const TargetModSkill *tarmod = qobject_cast<const TargetModSkill *>(skill);
                tarmods << tarmod;
            }
        }

        if (tarmods.isEmpty())
            return QStringList();

        int n = use.to.length() - 1;
        QList<const TargetModSkill *> tarmods_copy = tarmods;

        foreach (const TargetModSkill *tarmod, tarmods_copy) {
            if (tarmod->getExtraTargetNum(from, use.card) == 0) {
                tarmods.removeOne(tarmod);
                continue;
            }

            const Skill *main_skill = Sanguosha->getMainSkill(tarmod->objectName());
            if (from->hasShownSkill(main_skill)) {
                tarmods.removeOne(tarmod);
                n -= tarmod->getExtraTargetNum(from, use.card);
            }
        }

        if (tarmods.isEmpty() || n <= 0)
            return QStringList();

        tarmods_copy = tarmods;

        QStringList shows;
        foreach (const TargetModSkill *tarmod, tarmods_copy) {
            const Skill *main_skill = Sanguosha->getMainSkill(tarmod->objectName());
            shows << main_skill->objectName();
        }
        return shows;
    }
    return QStringList();
}

BurningCamps::BurningCamps(Card::Suit suit, int number, bool is_transferable)
    : AOE(suit, number)
{
    setObjectName("burning_camps");
    transferable = is_transferable;
}

bool BurningCamps::isAvailable(const Player *player) const
{
    if (player->getNextAlive() == player) return false;
    bool canUse = false;
    QList<const Player *> players = player->getNextAlive()->getFormation();
    foreach (const Player *p, players) {
        if (player->isProhibited(p, this))
            continue;

        canUse = true;
        break;
    }

    return canUse && TrickCard::isAvailable(player);
}

void BurningCamps::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct new_use = card_use;
    if (card_use.to.isEmpty() && card_use.from->getNextAlive() != card_use.from) {
        QList<const Player *> targets = card_use.from->getNextAlive()->getFormation();
        foreach (const Player *player, targets) {
            const Skill *skill = room->isProhibited(card_use.from, player, this);
            ServerPlayer *splayer = room->findPlayer(player->objectName());
            if (skill) {
                if (!skill->isVisible())
                    skill = Sanguosha->getMainSkill(skill->objectName());
                if (skill->isVisible()) {
                    LogMessage log;
                    log.type = "#SkillAvoid";
                    log.from = splayer;
                    log.arg = skill->objectName();
                    log.arg2 = objectName();
                    room->sendLog(log);

                    room->broadcastSkillInvoke(skill->objectName());
                }
            } else
                new_use.to << splayer;
        }
    }

    TrickCard::onUse(room, new_use);
}

void BurningCamps::onEffect(const CardEffectStruct &effect) const
{
    effect.to->getRoom()->damage(DamageStruct(this, effect.from, effect.to, 1, DamageStruct::Fire));
}

LureTiger::LureTiger(Card::Suit suit, int number, bool is_transferable)
    : TrickCard(suit, number)
{
    setObjectName("lure_tiger");
    transferable = is_transferable;
}

QString LureTiger::getSubtype() const
{
    return "lure_tiger";
}

bool LureTiger::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 2 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    if (targets.length() >= total_num)
        return false;
    if (Self->isCardLimited(this, Card::MethodUse))
        return false;

    return to_select != Self;
}

//void LureTiger::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
//{
//    QStringList nullified_list = room->getTag("CardUseNullifiedList").toStringList();
//    bool all_nullified = nullified_list.contains("_ALL_TARGETS");
//    foreach (ServerPlayer *target, targets) {
//        CardEffectStruct effect;
//        effect.card = this;
//        effect.from = source;
//        effect.to = target;
//        effect.multiple = (targets.length() > 1);
//        effect.nullified = (all_nullified || nullified_list.contains(target->objectName()));

//        QVariantList players;
//        for (int i = targets.indexOf(target); i < targets.length(); i++) {
//            if (!nullified_list.contains(targets.at(i)->objectName()) && !all_nullified)
//                players.append(QVariant::fromValue(targets.at(i)));
//        }
//        room->setTag("targets" + this->toString(), QVariant::fromValue(players));

//        room->cardEffect(effect);
//    }

//    room->removeTag("targets" + this->toString());

//    source->drawCards(1, objectName());
//}

void LureTiger::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    room->setPlayerProperty(effect.to, "removed", true);
    effect.to->setFlags("LureTigerEffected");
}

QStringList LureTiger::checkTargetModSkillShow(const CardUseStruct &use) const
{
    if (use.card == NULL)
        return QStringList();

    if (use.to.length() >= 3) {
        const ServerPlayer *from = use.from;
        QList<const Skill *> skills = from->getSkillList(false, false);
        QList<const TargetModSkill *> tarmods;

        foreach (const Skill *skill, skills) {
            if (from->hasSkill(skill) && skill->inherits("TargetModSkill")) {
                const TargetModSkill *tarmod = qobject_cast<const TargetModSkill *>(skill);
                tarmods << tarmod;
            }
        }

        if (tarmods.isEmpty())
            return QStringList();

        int n = use.to.length() - 2;
        QList<const TargetModSkill *> tarmods_copy = tarmods;

        foreach (const TargetModSkill *tarmod, tarmods_copy) {
            if (tarmod->getExtraTargetNum(from, use.card) == 0) {
                tarmods.removeOne(tarmod);
                continue;
            }

            const Skill *main_skill = Sanguosha->getMainSkill(tarmod->objectName());
            if (from->hasShownSkill(main_skill)) {
                tarmods.removeOne(tarmod);
                n -= tarmod->getExtraTargetNum(from, use.card);
            }
        }

        if (tarmods.isEmpty() || n <= 0)
            return QStringList();

        tarmods_copy = tarmods;

        QStringList shows;
        foreach (const TargetModSkill *tarmod, tarmods_copy) {
            const Skill *main_skill = Sanguosha->getMainSkill(tarmod->objectName());
            shows << main_skill->objectName();
        }
        return shows;
    }
    return QStringList();
}

FightTogether::FightTogether(Card::Suit suit, int number)
    : GlobalEffect(suit, number)
{
    setObjectName("fight_together");
    can_recast = true;
    target_fixed = false;
}

bool FightTogether::targetFilter(const QList<const Player *> &targets, const Player *, const Player *Self) const
{
    QList<const Player *> all_players = Self->getAliveSiblings();
    all_players << Self;

    bool has_bigkingdoms = false;

    foreach (const Player *p, all_players) {
        if (p->isBigKingdomPlayer()) {
            has_bigkingdoms = true;
            break;
        }
    }

    return has_bigkingdoms && targets.isEmpty();
}

bool FightTogether::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    bool rec = (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) && can_recast;
    QList<int> sub;
    if (isVirtualCard())
        sub = subcards;
    else
        sub << getEffectiveId();
    foreach (int id, sub) {
        if (Self->getHandPile().contains(id)) {
            rec = false;
            break;
        }

    }

    if (rec && Self->isCardLimited(this, Card::MethodUse))
        return targets.length() == 0;

    if (targets.length() > 1)
        return false;

    return rec || targets.length() > 0;
}

bool FightTogether::isAvailable(const Player *player) const
{
    if (player->hasFlag("Global_FightTogetherFailed"))
        return false;
    bool rec = (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) && can_recast;
    QList<int> sub;
    if (isVirtualCard())
        sub = subcards;
    else
        sub << getEffectiveId();
    foreach (int id, sub) {
        if (player->getPile("wooden_ox").contains(id)) {
            rec = false;
            break;
        }
    }

    if (rec && !player->isCardLimited(this, Card::MethodRecast))
        return true;
    bool has_bigkingdoms = player->isBigKingdomPlayer();
    QList<const Player *> siblings = player->getAliveSiblings();
    foreach (const Player *p, siblings) {
        if (p->isBigKingdomPlayer()) {
            has_bigkingdoms = true;
            break;
        }
    }

    return has_bigkingdoms && GlobalEffect::isAvailable(player);
}

void FightTogether::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;

    if (card_use.to.isEmpty()) {
        LogMessage log;
        log.type = "#Card_Recast";
        log.from = card_use.from;
        log.card_str = card_use.card->toString();
        room->sendLog(log);

        if (this->getSkillName().isNull())
            card_use.from->broadcastSkillInvoke("@recast");
        else {
            room->setPlayerFlag(card_use.from, "HuanshenSkillChecking");
            room->notifySkillInvoked(card_use.from, this->getSkillName());
            room->broadcastSkillInvoke(this->getSkillName(), card_use.from);
            room->setPlayerFlag(card_use.from, "-HuanshenSkillChecking");
        }

        CardMoveReason reason(CardMoveReason::S_REASON_RECAST, card_use.from->objectName());
        reason.m_skillName = getSkillName();
        room->moveCardTo(this, card_use.from, NULL, Player::DiscardPile, reason, true);

        QString skill_name = card_use.card->showSkill();
        if (!skill_name.isNull())
            card_use.from->showSkill(skill_name, card_use.card->getSkillPosition());

        card_use.from->drawCards(1);
        room->addPlayerHistory(NULL, "pushPile");
        return;
    }
    ServerPlayer *target = card_use.to.first();


    QList<ServerPlayer *> targets, voids, all = room->getAllPlayers();
    if (!source->isCardLimited(this, handling_method)) {
        foreach (ServerPlayer *p, all) {
            if (p->isBigKingdomPlayer() == target->isBigKingdomPlayer()) {
                if (room->isProhibited(source, p, this))
                    voids << p;
                else
                    targets << p;
            }
        }
    }

    CardUseStruct use = card_use;

    use.to = targets;

    Q_ASSERT(!use.to.isEmpty());

    foreach (ServerPlayer *p, voids) {
        const Skill *skill = room->isProhibited(source, p, this);
        if (!skill->isVisible())
            skill = Sanguosha->getMainSkill(skill->objectName());
        if (skill->isVisible()) {
            LogMessage log;
            log.type = "#SkillAvoid";
            log.from = p;
            log.arg = skill->objectName();
            log.arg2 = objectName();
            room->sendLog(log);

            room->broadcastSkillInvoke(skill->objectName());
        }
    }

    TrickCard::onUse(room, use);
}

void FightTogether::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (!effect.to->isChained()) {
        if (effect.to->canBeChainedBy(effect.from)) {
            effect.to->setChained(true);
            room->setEmotion(effect.to, "chain");
            room->broadcastProperty(effect.to, "chained");
            room->getThread()->trigger(ChainStateChanged, room, effect.to);
        }
    } else
        effect.to->drawCards(1);
}

AllianceFeast::AllianceFeast(Card::Suit suit, int number)
    : TrickCard(suit, number)
{
    setObjectName("alliance_feast");
    target_fixed = false;
}

QString AllianceFeast::getSubtype() const
{
    return "alliance_feast";
}

bool AllianceFeast::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty()) return false;
    return to_select->hasShownOneGeneral() && !Self->isFriendWith(to_select);
}

void AllianceFeast::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    QList<ServerPlayer *> targets;
    if (!source->isProhibited(source, this))
        targets << source;
    if (card_use.to.length() == 1) {
        ServerPlayer *target = card_use.to.first();
        QList<ServerPlayer *> other_players = room->getOtherPlayers(source);
        foreach (ServerPlayer *player, other_players) {
            if (!target->isFriendWith(player))
                continue;
            const Skill *skill = room->isProhibited(source, player, this);
            if (skill) {
                if (!skill->isVisible())
                    skill = Sanguosha->getMainSkill(skill->objectName());
                if (skill->isVisible()) {
                    LogMessage log;
                    log.type = "#SkillAvoid";
                    log.from = player;
                    log.arg = skill->objectName();
                    log.arg2 = objectName();
                    room->sendLog(log);

                    room->broadcastSkillInvoke(skill->objectName());
                }
            } else
                targets << player;
        }
    } else
        targets = card_use.to;

    CardUseStruct use = card_use;
    use.to = targets;
    TrickCard::onUse(room, use);
}

void AllianceFeast::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QStringList nullified_list = room->getTag("CardUseNullifiedList").toStringList();
    bool all_nullified = nullified_list.contains("_ALL_TARGETS");

    foreach (ServerPlayer *target, targets) {
        CardEffectStruct effect;
        effect.card = this;
        effect.from = source;
        effect.to = target;
        effect.multiple = (targets.length() > 1);
        effect.nullified = (all_nullified || nullified_list.contains(target->objectName()));

        QVariantList players;
        for (int i = targets.indexOf(target); i < targets.length(); i++) {
            if (!nullified_list.contains(targets.at(i)->objectName()) && !all_nullified)
                players.append(QVariant::fromValue(targets.at(i)));
        }
        room->setTag("targets" + this->toString(), QVariant::fromValue(players));

        if (target == source) {
            int n = 0;
            ServerPlayer *enemy = targets.last();
            foreach (ServerPlayer *p, room->getOtherPlayers(source)) {
                if (enemy->isFriendWith(p))
                    ++n;
            }
            target->setMark(objectName(), n);
        }
        room->cardEffect(effect);

        target->setMark(objectName(), 0);
    }

    room->removeTag("targets" + this->toString());

}

void AllianceFeast::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    if (effect.to->getMark(objectName()) > 0) {
        int x = effect.to->getMark(objectName());
        int y = qMin(x, effect.to->getLostHp());

        if (y == 0) effect.to->drawCards(x, objectName());
        else {
            QStringList draw_num;
            for (int i = 0; i <= y; draw_num << QString::number(i++)) {

            }
            int num = room->askForChoice(effect.to, "alliancefeast_draw", draw_num.join("+"), QVariant(), "@alliancefeast-choose").toInt();

            if (x > num)
                effect.to->drawCards(x - num, objectName());

            if (num > 0 && effect.to->canRecover()) {
                RecoverStruct rec;
                rec.recover = num;
                rec.who = effect.to;
                room->recover(effect.to, rec);
            }
        }
    } else {
        effect.to->drawCards(1, objectName());
        if (effect.to->isChained()) {
            effect.to->setChained(false);
            room->setEmotion(effect.to, "chain");
            room->broadcastProperty(effect.to, "chained");
            room->getThread()->trigger(ChainStateChanged, room, effect.to);
        }
    }
}

bool AllianceFeast::isAvailable(const Player *player) const
{
    return player->hasShownOneGeneral() && !player->isProhibited(player, this) && TrickCard::isAvailable(player);
}

ThreatenEmperor::ThreatenEmperor(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("threaten_emperor");
    target_fixed = true;
    transferable = true;
}

void ThreatenEmperor::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    SingleTargetTrick::onUse(room, use);
}

bool ThreatenEmperor::isAvailable(const Player *player) const
{
    return player->isBigKingdomPlayer() && !player->isProhibited(player, this) && TrickCard::isAvailable(player);
}

void ThreatenEmperor::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->getPhase() == Player::Play)
        effect.from->setFlags("Global_PlayPhaseTerminated");
    effect.to->setMark("ThreatenEmperorExtraTurn", 1);
}

class ThreatenEmperorSkill : public TriggerSkill
{
public:
    ThreatenEmperorSkill() : TriggerSkill("threaten_emperor")
    {
        events << EventPhaseEnd << EventPhaseStart;
        global = true;
    }

    virtual int getPriority() const
    {
        return 1;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                room->setPlayerMark(p, "ThreatenEmperorExtraTurn", 0);
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList list;
        if (triggerEvent != EventPhaseEnd || player->getPhase() != Player::Discard) return list;
        foreach(ServerPlayer *p, room->getAllPlayers())
            if (p->getMark("ThreatenEmperorExtraTurn") > 0)
                list.insert(p, QStringList(objectName()));

        return list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        return room->askForCard(ask_who, ".", "@threaten_emperor", data);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        LogMessage l;
        l.type = "#Fangquan";
        l.to << ask_who;
        room->sendLog(l);

        ask_who->gainAnExtraTurn();
        return false;
    }
};

ImperialOrder::ImperialOrder(Suit suit, int number)
    : GlobalEffect(suit, number)
{
    setObjectName("imperial_order");
}

bool ImperialOrder::isAvailable(const Player *player) const
{
    bool invoke = !player->hasShownOneGeneral();
    if (!invoke) {
        foreach (const Player *p, player->getAliveSiblings()) {
            if (!p->hasShownOneGeneral() && !player->isProhibited(p, this)) {
                invoke = true;
                break;
            }
        }
    }
    return invoke && TrickCard::isAvailable(player);
}

void ImperialOrder::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    QList<ServerPlayer *> targets;
    if (card_use.to.isEmpty()) {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->hasShownOneGeneral())
                continue;
            const Skill *skill = room->isProhibited(source, p, this);
            if (skill) {
                if (!skill->isVisible())
                    skill = Sanguosha->getMainSkill(skill->objectName());
                if (skill && skill->isVisible()) {
                    LogMessage log;
                    log.type = "#SkillAvoid";
                    log.from = p;
                    log.arg = skill->objectName();
                    log.arg2 = objectName();
                    room->sendLog(log);

                    room->broadcastSkillInvoke(skill->objectName());
                }
                continue;
            }
            targets << p;
        }
    } else
        targets = card_use.to;

    CardUseStruct use = card_use;
    use.to = targets;
    Q_ASSERT(!use.to.isEmpty());
    TrickCard::onUse(room, use);
}

void ImperialOrder::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
   // if (room->askForCard(effect.to, "EquipCard", "@imperial_order-equip"))
   //     return;
    QStringList choices;

    if (!effect.to->hasShownGeneral1() && effect.to->disableShow(true).isEmpty())
        choices << "show_head";
    if (effect.to->getGeneral2() && !effect.to->hasShownGeneral2() && effect.to->disableShow(false).isEmpty())
        choices << "show_deputy";

    QList<int> to_discard = effect.to->forceToDiscard(1, "EquipCard", QString(), true);
    if (!to_discard.isEmpty())
        choices << "dis_equip";

    choices << "losehp";

    QString all_choices = "show_head+show_deputy+dis_equip+losehp";

    QString choice = room->askForChoice(effect.to, objectName(), choices.join("+"), QVariant(), "@imperial_order-choose", all_choices);
    if (choice.contains("show")) {
        effect.to->showGeneral(choice == "show_head");
        effect.to->drawCards(1, objectName());
    } else if (choice == "dis_equip"){
        if (!room->askForCard(effect.to, "EquipCard!", "@imperial_order-equip")) {
            const Card *card = Sanguosha->getCard(to_discard.first());
            CardMoveReason reason(CardMoveReason::S_REASON_THROW, effect.to->objectName());
            room->moveCardTo(card, effect.to, NULL, Player::DiscardPile, reason, true);
        }
    } else if (choice == "losehp"){
        room->loseHp(effect.to);
    }
}

StrategicAdvantagePackage::StrategicAdvantagePackage()
    : Package("strategic_advantage", Package::CardPack)
{
    QList<Card *> cards;

    cards
        // basics
        // -- spade
        << new Slash(Card::Spade, 4)
        << new Analeptic(Card::Spade, 6, true) // transfer
        << new Slash(Card::Spade, 7)
        << new Slash(Card::Spade, 8)
        << new ThunderSlash(Card::Spade, 9)
        << new ThunderSlash(Card::Spade, 10)
        << new ThunderSlash(Card::Spade, 11, true) // transfer
        // -- heart
        << new Jink(Card::Heart, 4)
        << new Jink(Card::Heart, 5)
        << new Jink(Card::Heart, 6, true) // transfer, from ol
        << new Jink(Card::Heart, 7)
        << new Peach(Card::Heart, 8)
        << new Peach(Card::Heart, 9)
        << new Slash(Card::Heart, 10)
        << new Slash(Card::Heart, 11)
        // -- club
        << new Slash(Card::Club, 4)
        << new ThunderSlash(Card::Club, 5, true) // transfer
        << new Slash(Card::Club, 6)
        << new Slash(Card::Club, 7)
        << new Slash(Card::Club, 8)
        << new Analeptic(Card::Club, 9)
        // -- diamond
        << new Peach(Card::Diamond, 2)
        << new Peach(Card::Diamond, 3, true) // transfer
        << new Jink(Card::Diamond, 6)
        << new Jink(Card::Diamond, 7)
        << new FireSlash(Card::Diamond, 8)
        << new FireSlash(Card::Diamond, 9)
        << new Jink(Card::Diamond, 13)

        // tricks
        // -- spade
        << new ThreatenEmperor(Card::Spade, 1) // transfer
        << new BurningCamps(Card::Spade, 3, true) // transfer
        << new FightTogether(Card::Spade, 12)
        << new Nullification(Card::Spade, 13)
        // -- heart
        << new AllianceFeast()
        << new LureTiger(Card::Heart, 2)
        << new BurningCamps(Card::Heart, 12, true) //transfer
        << new Drowning(Card::Heart, 13)
        // -- club
        << new ImperialOrder(Card::Club, 3)
        << new FightTogether(Card::Club, 10)
        << new BurningCamps(Card::Club, 11, true) //transfer
        << new Drowning(Card::Club, 12)
        << new HegNullification(Card::Club, 13)
        // -- diamond
        << new ThreatenEmperor(Card::Diamond, 1) // transfer
        << new ThreatenEmperor(Card::Diamond, 4) // transfer
        << new LureTiger(Card::Diamond, 10, true) // transfer
        << new HegNullification(Card::Diamond, 11)

        // equips
        << new IronArmor()
        << new Blade(Card::Spade, 5);
    Horse *horse = new OffensiveHorse(Card::Heart, 3, -1, true); // transfer
    horse->setObjectName("JingFan");
    cards
        << horse
        << new JadeSeal(Card::Club, 1)
        << new Breastplate() // transfer
        << new WoodenOx(Card::Diamond, 5)
        << new Halberd(Card::Diamond, 12);

    skills << new IronArmorSkill
        << new BladeSkill
        << new JadeSealSkill
        << new BreastplateSkill
        << new WoodenOxSkill << new WoodenOxTriggerSkill
        << new HalberdSkill << new HalberdTrigger
        << new ThreatenEmperorSkill;
    insertRelatedSkills("lure_tiger_effect", "#lure_tiger-prohibit");

    foreach(Card *card, cards)
        card->setParent(this);

    addMetaObject<WoodenOxCard>();
    addMetaObject<HalberdCard>();
}

ADD_PACKAGE(StrategicAdvantage)
