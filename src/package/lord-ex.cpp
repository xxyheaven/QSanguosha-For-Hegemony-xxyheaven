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

#include "lord-ex.h"
#include "skill.h"
#include "strategic-advantage.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "momentum.h"
#include "client.h"
#include "engine.h"
#include "structs.h"
#include "gamerule.h"
#include "settings.h"
#include "roomthread.h"
#include "json.h"


class Qiuan : public TriggerSkill
{
public:
    Qiuan() : TriggerSkill("qiuan")
    {
        events << DamageInflicted;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPile("letter").isEmpty()) {
            DamageStruct damage = data.value<DamageStruct>();
            const Card *card = damage.card;
            if (card && room->isAllOnPlace(damage.card, Player::PlaceTable))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        player->addToPile("letter", damage.card);

        return true;
    }
};

class Liangfan : public PhaseChangeSkill
{
public:
    Liangfan() : PhaseChangeSkill("liangfan")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Start && !player->getPile("letter").isEmpty()) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;

    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<int> ids = player->getPile("letter");

        DummyCard *dummy = new DummyCard(ids);
        CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, player->objectName(), objectName(), QString());
        room->obtainCard(player, dummy, reason);
        delete dummy;

        room->loseHp(player);

        QVariantList liangfan_ids = player->tag["liangfanRecord"].toList();
        foreach (int card_id, ids) {
            if (player->handCards().contains(card_id))
                liangfan_ids << card_id;

        }
        player->tag["liangfanRecord"] = liangfan_ids;

        return false;
    }
};

class LiangfanEffect : public TriggerSkill
{
public:
    LiangfanEffect() : TriggerSkill("#liangfan-effect")
    {
        events << Damage << CardsMoveOneTime << EventPhaseStart << PreCardUsed;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
         if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
             player->tag.remove("liangfanRecord");
         }
         if (triggerEvent == CardsMoveOneTime) {
             QVariantList liangfan_ids = player->tag["liangfanRecord"].toList();
             QVariantList new_ids;
             foreach (QVariant card_data, liangfan_ids) {
                 int card_id = card_data.toInt();
                 if (player->handCards().contains(card_id))
                     new_ids << card_id;
             }
             player->tag["liangfanRecord"] = new_ids;
         }
         if (triggerEvent == PreCardUsed) {
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card && use.card->getTypeId() != Card::TypeSkill) {

                 QVariantList liangfan_ids = player->tag["liangfanRecord"].toList();
                 foreach (QVariant card_data, liangfan_ids) {
                     int card_id = card_data.toInt();
                     if (use.card->getSubcards().contains(card_id)) {
                         room->setCardFlag(use.card, "liangfanEffect");
                         break;
                     }

                 }

             }
         }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->hasFlag("liangfanEffect") && !damage.chain && !damage.transfer && damage.by_user) {
                ServerPlayer *target = damage.to;
                if (target && player->canGetCard(target, "he")) {
                    return QStringList(objectName());
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = damage.to;

        if (target && player->canGetCard(target, "he") && room->askForChoice(player, "liangfan", "yes+no", QVariant(), "@liangfan::" + target->objectName()) == "yes") {
            LogMessage log;
            log.type = "#LiangfanEffect";
            log.from = player;
            log.to << target;
            log.arg = "liangfan";
            room->sendLog(log);
            int card_id = room->askForCardChosen(player, target, "he", "liangfan", false, Card::MethodGet);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, Sanguosha->getCard(card_id), reason, false);
        }

        return false;
    }
};

class Xingzhao : public TriggerSkill
{
public:
    Xingzhao() : TriggerSkill("xingzhao")
    {
        events << Damaged << EventPhaseStart << CardsMoveOneTime;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == Damaged && getWoundedKingdoms(room) > 1) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from->isAlive() && damage.from->getHandcardNum() != player->getHandcardNum()) return QStringList(objectName());
        }
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Discard && getWoundedKingdoms(room) > 2) {
            return QStringList(objectName());
        }
        if (triggerEvent == CardsMoveOneTime && getWoundedKingdoms(room) > 3) {
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from == player && move.from_places.contains(Player::PlaceEquip)) {
                    return QStringList(objectName());
                }
            }
            return QStringList();
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else {

            invoke = player->askForSkillInvoke(this, data);
        }

        if (invoke) {
            int n = qrand()%2+1;
            if (triggerEvent == EventPhaseStart)
                n+=2;
            if (triggerEvent == CardsMoveOneTime) {
                n+=4;
            }
            room->broadcastSkillInvoke(objectName(), n, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            ServerPlayer *from = damage.from;
            if (from->getHandcardNum() < player->getHandcardNum())
                from->drawCards(1, objectName());
            if (from->getHandcardNum() > player->getHandcardNum())
                player->drawCards(1, objectName());
        }
        if (triggerEvent == CardsMoveOneTime)
            player->drawCards(1, objectName());
        else if (triggerEvent == EventPhaseStart)
            room->addPlayerMark(player, "Global_MaxcardsIncrease", 4);
        return false;
    }

private:
    static int getWoundedKingdoms(Room *room)
    {
        QList<ServerPlayer *> to_count, players = room->getAlivePlayers();

        foreach (ServerPlayer *p, players) {
            if (p->isWounded() && p->hasShownOneGeneral()) {
                bool record = true;
                foreach (ServerPlayer *p2, to_count) {
                    if (p->isFriendWith(p2)) {
                        record = false;
                        break;
                    }
                }
                if (record)
                    to_count << p;

            }

        }

        return to_count.length();
    }
};


class XingzhaoVH : public ViewHasSkill
{
public:
    XingzhaoVH() : ViewHasSkill("#xingzhao-viewhas")
    {

    }

    virtual bool ViewHas(const Player *player, const QString &skill_name, const QString &flag) const
    {
        if (flag == "skill" && skill_name == "xunxun_tangzi" && player->isAlive() && player->hasShownSkill("xingzhao")) {

            QList<const Player *> sibs = player->getAliveSiblings();
            sibs << player;
            foreach(const Player *sib, sibs) {
                if (sib->hasShownOneGeneral() && sib->isWounded())
                    return true;
            }
        }
        return false;
    }
};

class Bushi : public TriggerSkill
{
public:
    Bushi() : TriggerSkill("bushi")
    {
        events << Damage << Damaged;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();

        if (triggerEvent == Damage) {
            ServerPlayer *target = damage.to;
            if (target == NULL || target == player || target->isDead() || target->hasFlag("Global_DFDebut")) return QStringList();
            QList<ServerPlayer *> all_players = room->getAlivePlayers();
            bool cheak = false;
            foreach (ServerPlayer *p, all_players) {
                if (p->isFriendWith(target))
                    cheak = true;
            }
            if (cheak)
                return QStringList(objectName());
        } else {
            QStringList trigger_list;
            for (int i = 1; i <= damage.damage; i++)
                trigger_list << objectName();
            return trigger_list;
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player;
        if (triggerEvent == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            target = damage.to;
        }
        if (target == NULL) return false;

        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            int x = 4;
            if (target->hasShownOneGeneral()) {
                QStringList kingdoms;
                kingdoms << "wei" << "shu" << "wu";
                if (kingdoms.contains(target->getKingdom()))
                    x = kingdoms.indexOf(target->getKingdom()) + 1;
            }
            room->broadcastSkillInvoke(objectName(), x);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player;
        if (triggerEvent == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            target = damage.to;
        }
        if (target == NULL) return false;
        QList<ServerPlayer *> all = room->getAlivePlayers(), targets;
        foreach (ServerPlayer *p, all) {
            if (p->isFriendWith(target))
                targets << p;
        }

        ServerPlayer *to = room->askForPlayerChosen(player, targets, objectName(), "bushi-invoke");

        to->drawCards(1, objectName());

        return false;
    }
};

class Midao : public TriggerSkill
{
public:
    Midao() : TriggerSkill("midao")
    {
        events << EventPhaseChanging << ConfirmDamage << TargetChoosing;
    }

    virtual void record(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            player->setFlags("-MidaoUsed");
        } else if (triggerEvent == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card) {
                QStringList natures;
                natures << "normal" << "fire" << "thunder";
                QString nature_name = damage.card->tag["DamageNature"].toString();
                if (natures.contains(nature_name)) {
                    damage.nature = (DamageStruct::Nature) natures.indexOf(nature_name);
                    data = QVariant::fromValue(damage);
                }


            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent != TargetChoosing) return QStringList();
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Play || player->hasFlag("MidaoUsed"))
            return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if ((use.card->getTypeId() == Card::TypeBasic || isDamageTrick(use.card)) && use.card->subcardsLength() > 0)
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            player->setFlags("MidaoUsed");
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *owner) const
    {
        CardUseStruct use = data.value<CardUseStruct>();

        Card::Suit suit = room->askForSuit(owner, "midao");

        QStringList natures;
        natures << "normal" << "fire" << "thunder";

        QString nature = room->askForChoice(owner, "midao", natures.join("+"), QVariant(), "@midao-nature::" + player->objectName()+":"+use.card->objectName());

        QString name = use.card->objectName();
        QString _name = name;

        if (use.card->isKindOf("Slash")) {
            QStringList names;
            names << "slash" << "fire_slash" << "thunder_slash";
            name = names.at(natures.indexOf(nature));
        }

        Card *new_card = Sanguosha->cloneCard(name);
        new_card->copyFrom(use.card);
        new_card->setSuit(suit);

        if (!use.card->isKindOf("Slash"))
            new_card->setTag("DamageNature", nature);

        use.card = new_card;

        LogMessage log;
        log.type = "#MidaoSuit";
        log.from = player;
        log.arg = _name;
        log.arg2 = use.card->getSuitString();
        room->sendLog(log);

        LogMessage log2;
        log2.type = "#MidaoNature";
        log2.from = player;
        log2.arg = _name;
        log2.arg2 = "midao:"+nature;
        room->sendLog(log2);

        data = QVariant::fromValue(use);
        return false;
    }

private:
    static bool isDamageTrick(const Card *card)
    {
        return card->isKindOf("SavageAssault") || card->isKindOf("ArcheryAttack") || card->isKindOf("Duel")
                || card->isKindOf("FireAttack") || card->isKindOf("BurningCamps") || card->isKindOf("Drowning");
    }
};

class MidaoOther : public TriggerSkill
{
public:
    MidaoOther() : TriggerSkill("#midao-other")
    {
        events << TargetChoosing;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Play || player->hasFlag("MidaoUsed") || player->isKongcheng()) return skill_list;
        CardUseStruct use = data.value<CardUseStruct>();
        if ((use.card->getTypeId() == Card::TypeBasic || isDamageTrick(use.card)) && use.card->subcardsLength() > 0) {
            QList<ServerPlayer *> zhanglus = room->findPlayersBySkillName("midao");
            foreach (ServerPlayer *zhanglu, zhanglus) {
                if (player->isFriendWith(zhanglu) && zhanglu != player && zhanglu->hasShownSkill("midao"))
                    skill_list.insert(zhanglu, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *owner) const
    {
        QList<int> ints = room->askForExchange(player, "midao", 1, 0, "@midao:" + owner->objectName(), QString(), ".|.|.|hand");

        if (ints.isEmpty()) return false;

        LogMessage log;
        log.type = "#InvokeOthersSkill";
        log.from = player;
        log.to << owner;
        log.arg = "midao";
        room->sendLog(log);
        room->broadcastSkillInvoke("midao", owner);
        room->notifySkillInvoked(owner, "midao");

        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), owner->objectName());
        player->setFlags("MidaoUsed");

        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), owner->objectName(), objectName(), QString());
        reason.m_playerId = owner->objectName();
        room->moveCardTo(Sanguosha->getCard(ints.first()), owner, Player::PlaceHand, reason);

        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *owner) const
    {
        CardUseStruct use = data.value<CardUseStruct>();

        Card::Suit suit = room->askForSuit(owner, "midao");

        QStringList natures;
        natures << "normal" << "fire" << "thunder";

        QString nature = room->askForChoice(owner, "midao", natures.join("+"), QVariant(), "@midao-nature::" + player->objectName()+":"+use.card->objectName());

        QString name = use.card->objectName();
        QString _name = name;

        if (use.card->isKindOf("Slash")) {
            QStringList names;
            names << "slash" << "fire_slash" << "thunder_slash";
            name = names.at(natures.indexOf(nature));
        }

        Card *new_card = Sanguosha->cloneCard(name);
        new_card->copyFrom(use.card);
        new_card->setSuit(suit);

        if (!use.card->isKindOf("Slash"))
            new_card->setTag("DamageNature", nature);

        use.card = new_card;

        LogMessage log;
        log.type = "#MidaoSuit";
        log.from = player;
        log.arg = _name;
        log.arg2 = use.card->getSuitString();
        room->sendLog(log);

        LogMessage log2;
        log2.type = "#MidaoNature";
        log2.from = player;
        log2.arg = _name;
        log2.arg2 = "midao:"+nature;
        room->sendLog(log2);

        data = QVariant::fromValue(use);
        return false;
    }

private:
    static bool isDamageTrick(const Card *card)
    {
        return card->isKindOf("SavageAssault") || card->isKindOf("ArcheryAttack") || card->isKindOf("Duel")
                || card->isKindOf("FireAttack") || card->isKindOf("BurningCamps") || card->isKindOf("Drowning");
    }
};

class FengshiX : public TriggerSkill
{
public:
    FengshiX() : TriggerSkill("fengshix")
    {
        events << TargetChosen << ConfirmDamage;
    }

    virtual void record(TriggerEvent triggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        if (triggerEvent == ConfirmDamage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->hasFlag("FengshiXEffect")) {
                damage.damage++;
                data = QVariant::fromValue(damage);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent != TargetChosen || !TriggerSkill::triggerable(player)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() != Card::TypeSkill && use.to.size() == 1) {
            ServerPlayer *target = use.to.first();
            if (player->getHandcardNum() > target->getHandcardNum() && !target->isNude())
                return QStringList(objectName());

        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *target = use.to.first();
        if (player->askForSkillInvoke(this, QVariant::fromValue(target))) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());

            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() != Card::TypeSkill && use.to.size() == 1) {
            ServerPlayer *target = use.to.first();

            QList<ServerPlayer *> players;
            players << player << target;
            room->sortByActionOrder(players);

            foreach (ServerPlayer *p, players) {

                if (player->isAlive() && p->isAlive() && player->canDiscard(p, "he")) {
                    int card_id = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard);
                    room->throwCard(card_id, p, player);
                }
            }

            room->setCardFlag(use.card, "FengshiXEffect");
        }

        return false;
    }
};

class FengshiXOther : public TriggerSkill
{
public:
    FengshiXOther() : TriggerSkill("#fengshix-other")
    {
        events << TargetConfirmed;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player == NULL || player->isDead() || !player->hasShownSkill("fengshix")) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() != Card::TypeSkill && use.to.size() == 1 && use.to.contains(player)) {
            if (use.from && use.from->isAlive() && use.from->getHandcardNum() > player->getHandcardNum() && !player->isNude())
                return QStringList(objectName());

        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (room->askForChoice(use.from, "fengshix", "yes+no", data, "@fengshix:" + player->objectName()) == "yes") {
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = use.from;
            log.to << player;
            log.arg = "fengshix";
            room->sendLog(log);
            room->broadcastSkillInvoke("fengshix", player);
            room->notifySkillInvoked(player, "fengshix");
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), use.from->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *source = use.from;

        QList<ServerPlayer *> players;
        players << source << player;
        room->sortByActionOrder(players);

        foreach (ServerPlayer *p, players) {
            if (player->isAlive() && p->isAlive() && player->canDiscard(p, "he")) {
                int card_id = room->askForCardChosen(player, p, "he", "fengshix", false, Card::MethodDiscard);
                room->throwCard(card_id, p, player);
            }
        }

        room->setCardFlag(use.card, "FengshiXEffect");

        return false;
    }
};

class Wenji : public PhaseChangeSkill
{
public:
    Wenji() : PhaseChangeSkill("wenji")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Play) {
            QList<ServerPlayer *> players = room->getOtherPlayers(player);
            foreach (ServerPlayer *p, players) {
                if (!p->isNude())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isNude())
                targets << p;
        }
        ServerPlayer *victim;
        if ((victim = room->askForPlayerChosen(player, targets, objectName(), "@wenji", true, true)) != NULL) {
            room->broadcastSkillInvoke(objectName(), player);

            QStringList target_list = player->tag["wenji_target"].toStringList();
            target_list.append(victim->objectName());
            player->tag["wenji_target"] = target_list;

            return true;
        }
        return false;

    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QStringList target_list = player->tag["wenji_target"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        player->tag["wenji_target"] = target_list;

        ServerPlayer *target = room->findPlayerbyobjectName(target_name);
        if (target != NULL && !player->isNude()) {

            QList<int> ints = room->askForExchange(target, "_wenji", 1, 1, "@wenji-give:" + player->objectName());
            int card_id = -1;
            if (ints.isEmpty()) {
                card_id = target->getCards("he").first()->getEffectiveId();
            } else
                card_id = ints.first();

            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), objectName(), QString());
            reason.m_playerId = player->objectName();
            room->moveCardTo(Sanguosha->getCard(card_id), player, Player::PlaceHand, reason, true);

            if (player->isFriendWith(target) || !target->hasShownOneGeneral()) {

                if (player->handCards().contains(card_id)) {
                    QStringList record_list = player->property("wenji_record").toString().split("+");
                    record_list << QString::number(card_id);
                    room->setPlayerProperty(player, "wenji_record", record_list.join("+"));
                }
            } else {
                int give_back = -1;
                QList<int> to_give = player->handCards();
                to_give.removeOne(card_id);
                if (to_give.isEmpty()) {
                    if (player->hasEquip())
                        give_back = player->getEquips().first()->getEffectiveId();
                } else {
                    give_back = to_give.first();
                }

                if (give_back == -1) return false;

                QString pattern = QString("^%1").arg(card_id);

                QList<int> ints = room->askForExchange(player, "_wenji", 1, 1, "@wenji-give:" + target->objectName(), QString(), pattern);
                int card_id = -1;
                if (ints.isEmpty()) {
                    card_id = give_back;
                } else
                    card_id = ints.first();

                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), objectName(), QString());
                reason.m_playerId = target->objectName();
                room->moveCardTo(Sanguosha->getCard(card_id), target, Player::PlaceHand, reason, true);

            }
        }

        return false;
    }
};

class WenjiEffect : public TriggerSkill
{
public:
    WenjiEffect() : TriggerSkill("#wenji-effect")
    {
        events << CardUsed << CardsMoveOneTime << EventPhaseStart << PreCardUsed;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
         if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
             room->setPlayerProperty(player, "wenji_record", QVariant());
         }
         if (triggerEvent == CardsMoveOneTime) {
             QStringList new_list, record_list = player->property("wenji_record").toString().split("+");

             foreach (QString record, record_list) {
                 if (player->handCards().contains(record.toInt())) {
                     new_list << record;
                 }
             }

             room->setPlayerProperty(player, "wenji_record", new_list.join("+"));
         }
         if (triggerEvent == PreCardUsed) {
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card && use.card->getTypeId() != Card::TypeSkill && !player->property("wenji_record").isNull()) {
                 QStringList record_list = player->property("wenji_record").toString().split("+");
                 foreach (QString record, record_list) {
                     int card_id = record.toInt();
                     if (use.card->getSubcards().contains(card_id)) {
                         room->setCardFlag(use.card, "wenjiEffect");
                     }

                 }

             }
         }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player == NULL || player->isDead() || triggerEvent != CardUsed) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card && (use.card->isKindOf("Slash") || use.card->isNDTrick()) && use.card->hasFlag("wenjiEffect")) {
            return QStringList(objectName());

        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card) {
            LogMessage log;
            log.type = "#WenjiEffect";
            log.from = player;
            log.arg = "wenji";
            log.arg2 = use.card->objectName();
            room->sendLog(log);

            QStringList NoResponseTag = use.card->tag["NoResponse"].toStringList();
            NoResponseTag << "_ALL_PLAYERS",
            use.card->setTag("NoResponse", NoResponseTag);
        }
        return false;
    }
};

class WenjiTargetMod : public TargetModSkill
{
public:
    WenjiTargetMod() : TargetModSkill("#wenji-target")
    {
        pattern = "^SkillCard";
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card)|| from->property("wenji_record").toString().isEmpty())
            return 0;

        QStringList record_list = from->property("wenji_record").toString().split("+");
        foreach (QString record, record_list) {
            if (card->getSubcards().contains(record.toInt()) || card->hasFlag("Global_AvailabilityChecker")) {
                return 1000;
            }
        }


        return 0;
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *to) const
    {
        return getResidueNum(from, card, to);
    }

};


class Tunjiang : public PhaseChangeSkill
{
public:
    Tunjiang() : PhaseChangeSkill("tunjiang")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player) || player->hasFlag("TunjiangDisabled")) return QStringList();
        if (player->getPhase() == Player::Finish && player->getCardUsedTimes(".|play") > 0) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> to_count, players = room->getAlivePlayers();
        foreach (ServerPlayer *p, players) {
            if (!p->hasShownOneGeneral()) continue;
            bool no_friend = true;
            foreach (ServerPlayer *p2, to_count) {
                if (p2->isFriendWith(p)) {
                    no_friend = false;
                    break;
                }
            }
            if (no_friend)
                to_count << p;
        }

        int x = to_count.length();

        player->drawCards(x, objectName());

        return false;
    }
};

class Biluan : public DistanceSkill
{
public:
    Biluan() : DistanceSkill("biluan")
    {
    }

    virtual int getCorrect(const Player *, const Player *to) const
    {
        if (to->hasShownSkill(objectName()))
            return qMax(to->getEquips().length(), 1);
        else
            return 0;
    }
};

class Lixia : public PhaseChangeSkill
{
public:
    Lixia() : PhaseChangeSkill("lixia")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *) const
    {
        return false;
    }
};

class LixiaOther : public PhaseChangeSkill
{
public:
    LixiaOther() : PhaseChangeSkill("#lixia-other")
    {
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || !player->hasShownOneGeneral() || player->getPhase() != Player::Start) return skill_list;
        QList<ServerPlayer *> shixies = room->findPlayersBySkillName("lixia");
        foreach (ServerPlayer *shixie, shixies) {
            if (!player->isFriendWith(shixie) && shixie->hasEquip() && shixie->hasShownSkill("lixia"))
                skill_list.insert(shixie, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *owner) const
    {
        if (room->askForChoice(player, "lixia", "yes+no", QVariant(), "@lixia:" + owner->objectName()) == "yes") {
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << owner;
            log.arg = "lixia";
            room->sendLog(log);
            room->broadcastSkillInvoke("lixia", owner);
            room->notifySkillInvoked(owner, "lixia");

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *shixie) const
    {
        if (!player->canDiscard(shixie, "e")) return false;

        int card_id = room->askForCardChosen(player, shixie, "e", "lixia", false, Card::MethodDiscard);
        room->throwCard(card_id, shixie, player);

        QStringList choices;
        choices << "draw%from:"+ shixie->objectName() << "losehp";
        QStringList all_choices = choices;
        all_choices << "discard";
        if (player->forceToDiscard(2, true, true).length() > 1)
            choices << "discard";

        QString choice = room->askForChoice(player, "lixia", choices.join("+"), QVariant(), "@lixia-choose:" + shixie->objectName(), all_choices.join("+"));

        if (choice.contains("draw"))
            shixie->drawCards(2, "lixia");
        if (choice == "losehp")
            room->loseHp(player);
        if (choice == "discard")
            room->askForDiscard(player, "lixia", 2, 2, false, true);
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *) const
    {
        return false;
    }
};

class Quanji : public TriggerSkill
{
public:
    Quanji() : TriggerSkill("quanji")
    {
        events << Damage << Damaged;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.by_user || damage.chain || damage.transfer) return QStringList();
            QStringList use_to_list = damage.card->tag["UseCardTarget"].toStringList();

            if (use_to_list.length() != 1) return QStringList();

        }
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            int n = qrand()%2+1;
            if (triggerEvent == Damaged)
                n+=2;
            room->broadcastSkillInvoke(objectName(), n, player);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(1, objectName());

        if (player->isNude()) return false;

        int id = player->getCards("he").first()->getEffectiveId();

        QList<int> result = room->askForExchange(player, "_quanji", 1, 1, "@quanji-push");

        if (!result.isEmpty()) id = result.first();

        player->addToPile("power_pile", id);

        return false;
    }
};

class QuanjiMaxCards : public MaxCardsSkill
{
public:
    QuanjiMaxCards() : MaxCardsSkill("#quanji-maxcards")
    {
    }

    virtual int getExtra(const Player *target) const
    {
        if (target->hasShownSkill("quanji"))
            return target->getPile("power_pile").length();
        return 0;
    }
};

PaiyiCard::PaiyiCard()
{
    will_throw = true;
    handling_method = Card::MethodNone;
}

bool PaiyiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void PaiyiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *zhonghui = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = zhonghui->getRoom();

    int x = zhonghui->getPile("power_pile").length();

    if (x > 0)
        target->drawCards(x, objectName());

    if (target->getHandcardNum() >= zhonghui->getHandcardNum()) {
        room->damage(DamageStruct("paiyi", zhonghui, target));
        room->setPlayerFlag(zhonghui, "PaiyiDisabled");
    }
}

class Paiyi : public OneCardViewAsSkill
{
public:
    Paiyi() : OneCardViewAsSkill("paiyi")
    {
        expand_pile = "power_pile";
        filter_pattern = ".|.|.|power_pile";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->getPile("power_pile").isEmpty() && !player->hasFlag("PaiyiDisabled");
    }

    virtual const Card *viewAs(const Card *c) const
    {
        PaiyiCard *py = new PaiyiCard;
        py->addSubcard(c);
        return py;
    }
};

class Zhuhai : public TriggerSkill
{
public:
    Zhuhai() : TriggerSkill("zhuhai")
    {
        events << EventPhaseStart << ChoiceMade;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        //for notify skill
        if (triggerEvent == ChoiceMade && data.canConvert<CardUseStruct>()) {
            if (player->hasFlag("ZhuhaiSlash")) {
                player->setFlags("-ZhuhaiSlash");

                player->broadcastSkillInvoke(objectName());
                room->notifySkillInvoked(player, objectName());

                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);

                if (player->ownSkill(objectName()) && !player->hasShownSkill(objectName()))
                    player->showGeneral(player->inHeadSkills(objectName()));

                if (player->hasShownSkill("huashen"))
                    room->dropHuashenCardbySkillName(player, objectName());
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart) {
            TriggerList skill_list;
            if (player == NULL || player->isDead() || player->getMark("Global_DamagePiont_Round") == 0
                    || player->getPhase() != Player::Finish) return skill_list;
            QList<ServerPlayer *> xushus = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *xushu, xushus) {
                if (xushu != player && xushu->hasShownSkill(objectName()) && xushu->canSlash(player, false))
                    skill_list.insert(xushu, QStringList(objectName()));
            }
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *owner) const
    {
        owner->setFlags("ZhuhaiSlash");
        if (!room->askForUseSlashTo(owner, player, "@zhuhai:" + player->objectName(), false))
             owner->setFlags("-ZhuhaiSlash");
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }
};

class Pozhen : public TriggerSkill
{
public:
    Pozhen() : TriggerSkill("pozhen")
    {
        events << EventPhaseStart;
        frequency = Limited;
        limit_mark = "@pozhen";
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->getPhase() == Player::NotActive) {
            room->removePlayerTip(player, "#pozhen");
        }
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Start) return skill_list;
        QList<ServerPlayer *> xushus = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *xushu, xushus) {
            if (xushu != player && xushu->getMark(limit_mark) > 0)
                skill_list.insert(xushu, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *xushu) const
    {
        if (xushu->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->broadcastSkillInvoke(objectName(), xushu);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, xushu->objectName(), player->objectName());
            room->doSuperLightbox("xushu", objectName());
            room->setPlayerMark(xushu, limit_mark, 0);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *xushu) const
    {
        room->addPlayerTip(player, "#pozhen");
        room->setPlayerCardLimitation(player, "use,response,recast", ".|.|.|hand", true);
        QList<ServerPlayer *> all_players = room->getOtherPlayers(xushu), targets, alls = room->getAlivePlayers();
        bool can_discard = false;
        foreach (ServerPlayer *p, all_players) {

            bool inSiegeRelation = false;
            foreach (ServerPlayer *p2, alls) {
                if (player->inSiegeRelation(p, p2)) {
                    inSiegeRelation = true;
                    break;
                }
            }

            if (player->inFormationRalation(p) || inSiegeRelation) {
                targets << p;
                if (xushu->canDiscard(p, "he"))
                    can_discard = true;
            }
        }
        if (can_discard && room->askForChoice(xushu, "pozhen-discard", "yes+no", QVariant(), "@pozhen-discard::"+player->objectName()) == "yes") {
            foreach (ServerPlayer *p, targets) {
                if (xushu->canDiscard(p, "he")) {
                    room->throwCard(room->askForCardChosen(xushu, p, "he", objectName(), false, Card::MethodDiscard), p, xushu);
                }
            }
        }
        return false;
    }
};

class Jiancai : public TriggerSkill
{
public:
    Jiancai() : TriggerSkill("jiancai")
    {
        events << DamageInflicted << GeneralTransforming;
        relate_to_place = "deputy";
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (triggerEvent == DamageInflicted) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.damage < player->getHp()) return skill_list;
        }

        QList<ServerPlayer *> xushus = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *xushu, xushus) {
            if (xushu->isFriendWith(player))
                skill_list.insert(xushu, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *xushu) const
    {
        QString prompt = "transform:";
        if (triggerEvent == DamageInflicted)
            prompt = "damage:";
        prompt = prompt + player->objectName();
        if (xushu->askForSkillInvoke(this, prompt)) {
            room->broadcastSkillInvoke(objectName(), xushu);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, xushu->objectName(), player->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *xushu) const
    {
        if (triggerEvent == DamageInflicted) {
            if (xushu->canTransform())
                room->transformDeputyGeneral(xushu);
            return true;
        } else if (triggerEvent == GeneralTransforming) {
            data = data.toInt() + 2;
        }
        return false;
    }
};

QuanjinCard::QuanjinCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool QuanjinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getMark("Global_InjuredTimes_Phase") > 0;
}

void QuanjinCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *target = card_use.to.first();
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, card_use.from->objectName(), target->objectName(), "rende", QString());
    room->obtainCard(target, this, reason, false);
}

void QuanjinCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    if (source->askCommandto("quanjin", target))
        source->drawCards(1, "quanjin");
    else {
        int x = 0;
        QList<ServerPlayer *> all_players = room->getAlivePlayers();
        foreach (ServerPlayer *p, all_players) {
            x = qMax(x, p->getHandcardNum());
        }
        if (x > 0)
            source->drawCards(qMin(x, 5), "quanjin");

    }
}

class Quanjin : public OneCardViewAsSkill
{
public:
    Quanjin() : OneCardViewAsSkill("quanjin")
    {
        filter_pattern = ".|.|.|hand";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QuanjinCard");
    }

    virtual const Card *viewAs(const Card *c) const
    {
        QuanjinCard *skillcard = new QuanjinCard;
        skillcard->addSubcard(c);
        skillcard->setShowSkill(objectName());
        return skillcard;
    }
};

ZaoyunCard::ZaoyunCard()
{
    will_throw = true;
}

bool ZaoyunCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !Self->isFriendWith(to_select) && to_select->hasShownOneGeneral()
            && Self->distanceTo(to_select)-1 == subcardsLength();
}

void ZaoyunCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    QStringList target_list = source->tag["zaoyun_target"].toStringList();
    target_list.append(target->objectName());
    source->tag["zaoyun_target"] = target_list;

    room->setFixedDistance(source, target, 1);

    room->damage(DamageStruct("zaoyun", source, target));
}

class ZaoyunViewAsSkill : public ViewAsSkill
{
public:
    ZaoyunViewAsSkill() : ViewAsSkill("zaoyun")
    {

    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        ZaoyunCard *skillcard = new ZaoyunCard;
        skillcard->addSubcards(cards);
        skillcard->setShowSkill(objectName());
        return skillcard;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZaoyunCard") && player->hasShownOneGeneral();
    }
};

class Zaoyun : public TriggerSkill
{
public:
    Zaoyun() : TriggerSkill("zaoyun")
    {
        events << EventPhaseStart;
        view_as_skill = new ZaoyunViewAsSkill;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
         if (player->getPhase() != Player::NotActive) return;
         QStringList target_list = player->tag["zaoyun_target"].toStringList();
         player->tag.remove("zaoyun_target");

         foreach (QString name, target_list) {
             ServerPlayer *target = room->findPlayerbyobjectName(name, true);
             if (target)
                 room->setFixedDistance(player, target, -1);
         }

    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

DiaoguiCard::DiaoguiCard()
{
    will_throw = false;
}

bool DiaoguiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    LureTiger *trick = new LureTiger(getSuit(), getNumber());
    trick->addSubcard(this);
    trick->setSkillName("diaogui");
    return trick->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, trick, targets);
}

void DiaoguiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    int x1 = card_use.from->getFormation().length();

    LureTiger *trick = new LureTiger(getSuit(), getNumber());
    trick->addSubcard(this);
    trick->setShowSkill("diaogui");
    trick->setSkillName("diaogui");
    room->useCard(CardUseStruct(trick, card_use.from, card_use.to));

    if (card_use.from->isDead()) return;

    int x2 = card_use.from->getFormation().length();

    if (x1 == 1 && x2 > 1)
        card_use.from->drawCards(x2, "diaogui");
}

class Diaogui : public OneCardViewAsSkill
{
public:
    Diaogui() : OneCardViewAsSkill("diaogui")
    {
        response_or_use = true;
    }

    virtual bool viewFilter(const Card *to_select) const
    {
        if (to_select->getTypeId() != Card::TypeEquip) return false;
        LureTiger *trick = new LureTiger(to_select->getSuit(), to_select->getNumber());
        trick->addSubcard(to_select);
        trick->setSkillName("diaogui");
        return trick->isAvailable(Self);
    }

    virtual const Card *viewAs(const Card *c) const
    {
        DiaoguiCard *skillcard = new DiaoguiCard;
        skillcard->addSubcard(c);
        return skillcard;
    }
    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DiaoguiCard");
    }
};

FengyangSummon::FengyangSummon()
    : ArraySummonCard("fengyang")
{
    mute = true;
}

class Fengyang : public BattleArraySkill
{
public:
    Fengyang() : BattleArraySkill("fengyang", HegemonyMode::Formation)
    {

    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

class FengyangCardFixed : public FixCardSkill
{
public:
    FengyangCardFixed() : FixCardSkill("#fengyang-fixcard")
    {

    }
    virtual bool isCardFixed(const Player *from, const Player *to, const QString &flags, Card::HandlingMethod method) const
    {
        if (from->hasShownOneGeneral() && !from->isFriendWith(to)
                && (method == Card::MethodGet || method == Card::MethodDiscard) && flags.contains("e")) {
            QList<const Player *> all_players = to->getFormation();
            foreach (const Player *p, all_players) {
                if (p->hasShownSkill("fengyang")) {
                    return true;
                }
            }

        }

        return false;
    }
};


class Zhidao : public PhaseChangeSkill
{
public:
    Zhidao() : PhaseChangeSkill("zhidao")
    {
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
         if (player->getPhase() != Player::NotActive) return;
         QStringList target_list = player->property("zhidao_targets").toString().split("+");

         foreach (QString name, target_list) {
             ServerPlayer *target = room->findPlayerbyobjectName(name, true);
             if (target) {
                 room->removePlayerTip(target, "#zhidao");
                 room->setFixedDistance(player, target, -1);
             }
         }

         room->setPlayerProperty(player, "zhidao_targets", QVariant());

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Play) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->setPlayerFlag(player, "ZhidaoInvoked");

        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@zhidao-target");

        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());

        QStringList assignee_list = player->property("zhidao_targets").toString().split("+");
        assignee_list << target->objectName();
        room->setPlayerProperty(player, "zhidao_targets", assignee_list.join("+"));

        room->setFixedDistance(player, target, 1);
        room->addPlayerTip(target, "#zhidao");

        return false;
    }
};

class ZhidaoDamage : public TriggerSkill
{
public:
    ZhidaoDamage() : TriggerSkill("#zhidao-damage")
    {
        events << Damage;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.flags.contains("zhidao")) return QStringList();
        ServerPlayer *target = damage.to;
        QStringList target_list = player->property("zhidao_targets").toString().split("+");
        if (target && target_list.contains(target->objectName()) && player->canGetCard(target, "hej"))
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = damage.to;

        if (target && player->canGetCard(target, "hej")) {
            LogMessage log;
            log.type = "#ZhidaoEffect";
            log.from = player;
            log.to << target;
            log.arg = "zhidao";
            room->sendLog(log);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());

            int card_id = room->askForCardChosen(player, target, "hej", "zhidao", false, Card::MethodGet);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, Sanguosha->getCard(card_id), reason, false);
        }

        return false;
    }
};

class ZhidaoProhibit : public ProhibitSkill
{
public:
    ZhidaoProhibit() : ProhibitSkill("#zhidao-prohibit")
    {
    }

    virtual bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (from && to && from->hasFlag("ZhidaoInvoked") && card->getTypeId() != Card::TypeSkill) {
            QStringList assignee_list = from->property("zhidao_targets").toString().split("+");

            return from != to && !assignee_list.contains(to->objectName());
        }
        return false;
    }
};

class JiliX : public TriggerSkill
{
public:
    JiliX() : TriggerSkill("jilix")
    {
        events << DamageInflicted << CardFinished;
        relate_to_place = "deputy";
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &ask_who) const
    {
        if (triggerEvent == DamageInflicted && TriggerSkill::triggerable(player) && player->getMark("Global_InjuredTimes_Phase") == 1)
            return QStringList(objectName());
        else if (triggerEvent == CardFinished && player != NULL && player->isAlive()) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isRed() && (use.card->isNDTrick() || use.card->getTypeId() == Card::TypeBasic)
                    && !use.card->isKindOf("AllianceFeast") && use.to.size() == 1) {
                ServerPlayer *target = use.to.first();
                if (TriggerSkill::triggerable(target)) {
                    ask_who = target;
                    return QStringList(objectName());
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *player) const
    {
        QString prompt = "damage";
        if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            prompt = "target:"+use.from->objectName()+"::"+use.card->objectName();
        }
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, prompt);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *player) const
    {
        if (triggerEvent == DamageInflicted) {
            player->removeGeneral(false);
            return true;
        } else if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            Card *use_card = Sanguosha->cloneCard(use.card->objectName(), Card::NoSuit, 0);
            use_card->setSkillName("_jilix");
            QList<ServerPlayer *> targets;
            targets << player;
            room->useCard(CardUseStruct(use_card, use.from, targets));
        }
        return false;
    }
};

ImperialEdict::ImperialEdict(Card::Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("ImperialEdict");
}

void ImperialEdict::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const
{
    if (room->getCardPlace(getEffectiveId()) != Player::PlaceTable || targets.isEmpty()) return;

    ServerPlayer *target = targets.first();

    if (target->isDead()) return;

    target->addToPile("ImperialEdict", getEffectiveId());
}

ImperialEdictTrickCard::ImperialEdictTrickCard()
{
    target_fixed = true;
}

void ImperialEdictTrickCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, player, data);

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = player;
    log.arg = "ImperialEdict";
    room->sendLog(log);

    thread->trigger(CardUsed, room, player, data);
    thread->trigger(CardFinished, room, player, data);
}

void ImperialEdictTrickCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> pile = source->getPile("ImperialEdict"), to_throw;

    foreach (int id, pile) {
        if (!Sanguosha->getCard(id)->isKindOf("ImperialEdict"))
            to_throw << id;
    }

    DummyCard dummy(to_throw);
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, source->objectName());
    room->throwCard(&dummy, reason, NULL);

    if (source->isDead()) return;

    QStringList card_names;
    card_names << "RuleTheWorld" << "Conquering" << "ConsolidateCountry" << "Chaos";

    Package *package = PackageAdder::packages()["LordEXCard"];
    if (package) {
        QList<Card *> all_cards = package->findChildren<Card *>();
        QList<int> tricks;
        foreach (Card *card, all_cards) {
            if (!room->canFindCardPlace(card->getEffectiveId()) && card_names.contains(card->getClassName()))
                tricks << card->getEffectiveId();
        }
        if (tricks.isEmpty()) return;
        qShuffle(tricks);

        int id = tricks.first();

        LogMessage log;
        log.type = "$TakeAG";
        log.from = source;
        log.card_str = QString::number(id);
        room->sendLog(log);

        room->setCardMapping(id, NULL, Player::PlaceWuGu);
        source->obtainCard(Sanguosha->getCard(id));

    }
}

class ImperialEdictTrick : public ZeroCardViewAsSkill
{
public:
    ImperialEdictTrick() : ZeroCardViewAsSkill("imperialedicttrick")
    {
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        if (player->hasUsed("ImperialEdictTrickCard")) return false;
       QList<int> cards = player->getPile("ImperialEdict");

       QStringList suits;
       foreach (int id, cards) {
           const Card *card = Sanguosha->getCard(id);
           if (card->isKindOf("ImperialEdict")) continue;
           QString suit = card->getSuitString();
           if (!suits.contains(suit))
            suits << suit;
       }

       return suits.length() == 4;
    }

    virtual const Card *viewAs() const
    {
        return new ImperialEdictTrickCard;
    }

};

ImperialEdictAttachCard::ImperialEdictAttachCard()
{
    target_fixed = true;
}

void ImperialEdictAttachCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *player = card_use.from;

    ServerPlayer *lord = NULL;
    QList<ServerPlayer *> all_players = room->getAlivePlayers();
    foreach (ServerPlayer *p, all_players) {
        if (!p->getPile("ImperialEdict").isEmpty()) {
            lord = p;
            break;
        }
    }
    if (lord == NULL) return;

    CardUseStruct new_use = card_use;
    new_use.to << lord;

    QVariant data = QVariant::fromValue(new_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, player, data);

    LogMessage log;
    log.type = "#InvokeOthersSkill";
    log.from = player;
    log.to << lord;
    log.arg = "ImperialEdict";
    room->sendLog(log);
    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), lord->objectName());

    thread->trigger(CardUsed, room, player, data);
    thread->trigger(CardFinished, room, player, data);
}

void ImperialEdictAttachCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->addToPile("ImperialEdict", getSubcards(), true);
}

class ImperialEdictAttach : public ViewAsSkill
{
public:
    ImperialEdictAttach() : ViewAsSkill("imperialedictattach")
    {
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
       if (player->hasUsed("ImperialEdictAttachCard")) return false;
       if (!player->getPile("ImperialEdict").isEmpty()) return true;
       foreach (const Player *lord, player->getAliveSiblings()) {
           if (!lord->getPile("ImperialEdict").isEmpty() && player->isFriendWith(lord))
               return true;
       }
       return false;
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        int x = 1;
        if (!Self->isBigKingdomPlayer()) {
            foreach (const Player *p, Self->getAliveSiblings()) {
                if (p->isBigKingdomPlayer()) {
                    x++;
                    break;
                }
            }
        }
        return !Self->isJilei(to_select) && !to_select->isEquipped() && selected.length() < x;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;

        ImperialEdictAttachCard *rende_card = new ImperialEdictAttachCard;
        rende_card->addSubcards(cards);
        return rende_card;
    }

};

class ImperialEdictSkill : public TriggerSkill
{
public:
    ImperialEdictSkill() : TriggerSkill("ImperialEdict")
    {
        events << CardsMoveOneTime << GeneralShown << GeneralHidden << Death << DFDebut;
        global = true;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *, QVariant &) const
    {
        doImperialEdictAttach(room);
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

private:
    static void doImperialEdictAttach(Room *room)
    {
        QMap<ServerPlayer *, bool> xuanhuo_map;
        QList<ServerPlayer *> players = room->getAlivePlayers(), fazhengs;
        foreach(ServerPlayer *p, players) {
            if (!p->getPile("ImperialEdict").isEmpty())
                fazhengs << p;
        }
        foreach(ServerPlayer *p, players) {
            bool will_attach = false;
            foreach(ServerPlayer *fazheng, fazhengs) {
                if (fazheng->isFriendWith(p)) {
                    will_attach = true;
                    break;
                }
            }
            xuanhuo_map.insert(p, will_attach);
        }
        foreach (ServerPlayer *p, xuanhuo_map.keys()) {
            bool will_attach = xuanhuo_map.value(p, false);
            if (will_attach == p->getAcquiredSkills().contains("imperialedictattach")) continue;

            if (will_attach)
                room->attachSkillToPlayer(p, "imperialedictattach");
            else
                room->detachSkillFromPlayer(p, "imperialedictattach");

        }

        foreach(ServerPlayer *p, players) {
            if (p->getPile("ImperialEdict").isEmpty() && p->getAcquiredSkills().contains("imperialedicttrick"))
                room->detachSkillFromPlayer(p, "imperialedicttrick");
            if (!p->getPile("ImperialEdict").isEmpty() && !p->getAcquiredSkills().contains("imperialedicttrick"))
                room->attachSkillToPlayer(p, "imperialedicttrick");
        }
    }
};

RuleTheWorld::RuleTheWorld(Card::Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("rule_the_world");
    target_fixed = false;
}

bool RuleTheWorld::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty()) return false;
    int x = Self->getHp();
    QList<const Player *> players = Self->getAliveSiblings();
    foreach (const Player *p, players) {
        x = qMin(x, p->getHp());
    }
    return to_select->getHp() > x;
}

void RuleTheWorld::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    QList<ServerPlayer *> players = room->getOtherPlayers(effect.to);

    foreach (ServerPlayer *p, players) {
        if (effect.to->isDead()) break;
        if (p->isDead()) continue;

        bool completeEffect = hasFlag("CompleteEffect") && p->getSeemingKingdom() == "wei";

        QStringList choices, allchoices;

        QString choice1 = QString("slash%to:%1").arg(effect.to->objectName());
        QString choice2 = QString("discard%to:%1").arg(effect.to->objectName());
        if (completeEffect) {
            choice1 = choice1 + "%log: ";
            choice2 = choice2 + "%log:rule_the_world_getcard";
            if (p->canGetCard(effect.to, "he"))
                choices << choice2;
        } else {
            choice1 = choice1 + "%log:rule_the_world_slash";
            choice2 = choice2 + "%log:rule_the_world_discard";
            if (p->canDiscard(effect.to, "he"))
                choices << choice2;
        }

        if (p->canSlash(effect.to, false))
            choices << choice1;

        if (choices.isEmpty()) continue;

        choices << "cancel";
        allchoices << choice1 << choice2 << "cancel";

        QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant(), QString(), allchoices.join("+"));

        if (choice.startsWith("slash")) {
            if (completeEffect ||room->askForDiscard(p, objectName(), 1, 1, true, false, "@rule_the_world-slash::"+effect.to->objectName())) {
                Slash *slash = new Slash(Card::NoSuit, 0);
                slash->setSkillName("_conquering");
                room->useCard(CardUseStruct(slash, p, effect.to), false);
            }
        }
        if (choice.startsWith("discard")) {
            if (completeEffect && p->canGetCard(effect.to, "he")) {
                int card_id = room->askForCardChosen(p, effect.to, "he", objectName(), false, Card::MethodGet);
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, p->objectName());
                room->obtainCard(p, Sanguosha->getCard(card_id), reason, false);
            } else if (!completeEffect && p->canDiscard(effect.to, "he")) {
                int card_id = room->askForCardChosen(p, effect.to, "he", objectName(), false, Card::MethodDiscard);
                room->throwCard(card_id, effect.to, p);
            }
        }
    }
}

Conquering::Conquering(Suit suit, int number)
    : GlobalEffect(suit, number)
{
    setObjectName("conquering");
    target_fixed = false;
}

bool Conquering::targetFilter(const QList<const Player *> &, const Player *, const Player *) const
{
    return true;
}

void Conquering::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;


    Card::onUse(room, use);
}

void Conquering::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    if (effect.to->isDead()) return;

    bool completeEffect = hasFlag("CompleteEffect") && effect.to->getSeemingKingdom() == "shu";

    QList<ServerPlayer *> targets, allplayers = room->getAlivePlayers();
    foreach (ServerPlayer *p, allplayers) {
        if (effect.to->canSlash(p, NULL, false))
            targets << p;
    }
    if (!targets.isEmpty()) {

        ServerPlayer *target = room->askForPlayerChosen(effect.to, targets, "conquering-slash", "@conquering-slash", true);
        if (target) {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_conquering");
            if (completeEffect)
                slash->setTag("addcardinality", 1);

            room->useCard(CardUseStruct(slash, effect.to, target), false);

            return;
        }
    }

    effect.to->drawCards(completeEffect ? 2 : 1, objectName());
}

ConsolidateCountryGiveCard::ConsolidateCountryGiveCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool ConsolidateCountryGiveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.isEmpty() && Self->isFriendWith(to_select) && to_select != Self) {

        QString str = to_select->property("consolidate_country_arrange").toString();

        QStringList arrange_list;

        if (!str.isEmpty())
            arrange_list = str.split("+");

        return arrange_list.length() + subcardsLength() < 3;
    }
    return false;
}

void ConsolidateCountryGiveCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *target = card_use.to.first();

    QString str = target->property("consolidate_country_arrange").toString();

    QStringList arrange_list;

    if (!str.isEmpty())
        arrange_list = str.split("+");

    arrange_list << IntList2StringList(getSubcards());

    room->setPlayerProperty(target, "consolidate_country_arrange", arrange_list.join("+"));

}

class ConsolidateCountryGive : public ViewAsSkill
{
public:
    ConsolidateCountryGive() : ViewAsSkill("consolidatecountrygive")
    {
        response_pattern = "@@consolidatecountrygive";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QStringList card_list = Self->property("consolidate_country_cards").toString().split("+");
        return selected.length() < 2 && card_list.contains(QString::number(to_select->getEffectiveId()));
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        ConsolidateCountryGiveCard *Lirang_card = new ConsolidateCountryGiveCard;
        Lirang_card->addSubcards(cards);
        return Lirang_card;
    }
};

ConsolidateCountry::ConsolidateCountry(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("consolidate_country");
    target_fixed = true;
}

void ConsolidateCountry::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    SingleTargetTrick::onUse(room, use);
}

bool ConsolidateCountry::isAvailable(const Player *player) const
{
    return !player->isProhibited(player, this) && TrickCard::isAvailable(player);
}

void ConsolidateCountry::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    effect.to->drawCards(8, objectName());
    if (effect.to->isDead() || effect.to->isKongcheng()) return;

    QList<int> all_cards = effect.to->forceToDiscard(998, false);
    QList<int> to_thrown = effect.to->forceToDiscard(6, false);

    if (to_thrown.isEmpty()) return;


    if (all_cards.length() > to_thrown.length()) {

        QList<int> result = room->askForExchange(effect.to, objectName(), 998, to_thrown.length(),
                "@consolidate_country-discard", QString(), IntList2StringList(all_cards).join(","));

        if (!result.isEmpty())
            to_thrown = result;
    }

    QList<CardsMoveStruct> moves;

    if (hasFlag("CompleteEffect") && effect.to->getSeemingKingdom() == "wu") {
        while (!to_thrown.isEmpty()) {

            QList<ServerPlayer *> all_players = room->getOtherPlayers(effect.to);

            bool cant_give = true;
            foreach (ServerPlayer *p, all_players) {
                if (effect.to->isFriendWith(p)) {
                    if (p->property("consolidate_country_arrange").toString().split("+").length() < 2) {
                        cant_give = false;
                        break;
                    }

                }
            }
            if (cant_give) break;

            room->setPlayerProperty(effect.to, "consolidate_country_cards", IntList2StringList(to_thrown).join("+"));
            const Card *to_give = room->askForUseCard(effect.to, "@@consolidatecountrygive", "@consolidate_country-give");
            room->setPlayerProperty(effect.to, "consolidate_country_cards", QVariant());
            if (to_give == NULL) break;
            foreach (int id, to_give->getSubcards()) {
                to_thrown.removeOne(id);
            }
        }

        QList<ServerPlayer *> alls = room->getAlivePlayers();
        foreach (ServerPlayer *p, alls) {

            QString str = p->property("consolidate_country_arrange").toString();
            room->setPlayerProperty(p, "consolidate_country_arrange", QVariant());
            if (str.isEmpty()) continue;
            QStringList arrange_list = str.split("+");

            QList<int> to_arrange;
            foreach (QString id_str, arrange_list) {
                int id = id_str.toInt();
                to_arrange << id;
            }
            if (!to_arrange.isEmpty()) {
                CardsMoveStruct move(to_arrange, p, Player::PlaceHand,
                    CardMoveReason(CardMoveReason::S_REASON_GIVE, effect.to->objectName(), p->objectName(), objectName(), QString()));
                moves << move;
            }
        }
    }

    if (!to_thrown.isEmpty()) {
        CardsMoveStruct move(to_thrown, NULL, Player::DiscardPile,
            CardMoveReason(CardMoveReason::S_REASON_THROW, effect.to->objectName(), objectName(), QString()));
        moves << move;
    }

    room->moveCardsAtomic(moves, false);
}

Chaos::Chaos(Suit suit, int number)
    : GlobalEffect(suit, number)
{
    setObjectName("chaos");
}

void Chaos::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    if (effect.to->isDead() || effect.to->isKongcheng()) return;

    room->showAllCards(effect.to);

    if (effect.from->isDead()) return;

    QStringList choices, allchoices;

    QString choice1 = QString("letdiscard%to:%1").arg(effect.to->objectName());
    QString choice2 = QString("discard%to:%1").arg(effect.to->objectName());

    QList<const Card *> handcard = effect.to->getHandcards();

    choices << choice1;

    if (effect.from->canDiscard(effect.to, "h"))
        choices << choice2;

    allchoices << choice1 << choice2;

    room->fillAG(effect.to->handCards(), effect.from);
    QString choice = room->askForChoice(effect.from, objectName(), choices.join("+"), QVariant(), QString(), allchoices.join("+"));
    room->clearAG(effect.from);

    if (choice == choice1) {
        QList<int> to_discard;

        foreach (const Card *card, handcard) {
            if (effect.to->isJilei(card)) continue;
            bool append = true;
            foreach (int id, to_discard) {
                if (Sanguosha->getCard(id)->getTypeId() == card->getTypeId()) {
                    append = false;
                    break;
                }
            }
            if (append)
                to_discard << card->getEffectiveId();
            if (to_discard.length() > 1) break;
        }
        if (!to_discard.isEmpty()) {

            if (to_discard.length() < effect.to->getHandcardNum()) {
                const Card *card = room->askForCard(effect.to, "@@chaosselect!", "@chaos-select", QVariant(), Card::MethodNone);
                if (card != NULL)
                    to_discard = card->getSubcards();
            }

            DummyCard *dummy = new DummyCard(to_discard);
            CardMoveReason mreason(CardMoveReason::S_REASON_THROW, effect.to->objectName(), QString(), objectName(), QString());
            room->throwCard(dummy, mreason, effect.to);
            delete dummy;
        }
    }

    if (choice == choice2 && effect.from->canDiscard(effect.to, "h")) {
        int card_id = room->askForCardChosen(effect.from, effect.to, "h", objectName(), true, Card::MethodDiscard);
        room->throwCard(card_id, effect.to, effect.from);
    }

    if (hasFlag("CompleteEffect") && effect.to->getSeemingKingdom() == "qun" && effect.to->isKongcheng())
        effect.to->fillHandCards(effect.to->getHp(), objectName());
}

class ChaosSelect : public ViewAsSkill
{
public:
    ChaosSelect() : ViewAsSkill("chaosselect")
    {
        response_pattern = "@@chaosselect!";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() > 1 || Self->isJilei(to_select) || to_select->isEquipped()) return false;

        foreach (const Card *card, selected) {
            if (card->getTypeId() == to_select->getTypeId()) return false;
        }

        return true;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        if (cards.length() == 1) {
            const Card *to_select = cards.first();
            QList<const Card *> cards = Self->getHandcards();
            foreach (const Card *card, cards) {
                if (!Self->isJilei(card) && card->getTypeId() != to_select->getTypeId())
                    return NULL;
            }
        }

        DummyCard *dummy = new DummyCard;
        dummy->addSubcards(cards);
        return dummy;
    }
};

LordEXPackage::LordEXPackage()
    : Package("lord_ex")
{
    General *mengda = new General(this, "mengda", "wei");
    mengda->addSkill(new Qiuan);
    mengda->addSkill(new DetachEffectSkill("qiuan", "letter"));
    insertRelatedSkills("qiuan", "#qiuan-clear");
    mengda->addSkill(new Liangfan);
    mengda->addSkill(new LiangfanEffect);
    insertRelatedSkills("liangfan", "#liangfan-effect");
    mengda->setSubordinateKingdom("shu");

    General *tangzi = new General(this, "tangzi", "wei");
    tangzi->addSkill(new Xingzhao);
    tangzi->addSkill(new XingzhaoVH);
    insertRelatedSkills("xingzhao", "#xingzhao-viewhas");
    tangzi->addRelateSkill("xunxun_tangzi");
    tangzi->setSubordinateKingdom("wu");

    General *zhanglu = new General(this, "zhanglu", "qun", 3);
    zhanglu->addSkill(new Bushi);
    zhanglu->addSkill(new Midao);
    zhanglu->addSkill(new MidaoOther);
    insertRelatedSkills("midao", "#midao-other");
    zhanglu->setSubordinateKingdom("wei");

    General *mifangfushiren = new General(this, "mifangfushiren", "shu");
    mifangfushiren->addSkill(new FengshiX);
    mifangfushiren->addSkill(new FengshiXOther);
    insertRelatedSkills("fengshix", "#fengshix-other");
    mifangfushiren->setSubordinateKingdom("wu");

    General *liuqi = new General(this, "liuqi", "qun", 3);
    liuqi->addSkill(new Wenji);
    liuqi->addSkill(new WenjiEffect);
    liuqi->addSkill(new WenjiTargetMod);
    insertRelatedSkills("wenji", 2, "#wenji-effect", "#wenji-target");
    liuqi->addSkill(new Tunjiang);
    liuqi->setSubordinateKingdom("shu");

    General *shixie = new General(this, "shixie", "wu", 3);
    shixie->addSkill(new Biluan);
    shixie->addSkill(new Lixia);
    shixie->addSkill(new LixiaOther);
    insertRelatedSkills("lixia", "#lixia-other");
    shixie->setSubordinateKingdom("qun");

    General *zhonghui = new General(this, "zhonghui", "careerist");
    zhonghui->addSkill(new Quanji);
    zhonghui->addSkill(new QuanjiMaxCards);
    zhonghui->addSkill(new DetachEffectSkill("quanji", "power_pile"));
    zhonghui->addSkill(new Paiyi);
    insertRelatedSkills("quanji", 2, "#quanji-maxcards", "#quanji-clear");
    zhonghui->addCompanion("jiangwei");
    zhonghui->addCompanion("dengai");

    General *dongzhao = new General(this, "dongzhao", "wei", 3);
    dongzhao->addSkill(new Quanjin);
    dongzhao->addSkill(new Zaoyun);

    General *xushu = new General(this, "xushu", "shu");
    xushu->addSkill(new Zhuhai);
    xushu->addSkill(new Pozhen);
    xushu->addSkill(new Jiancai);
    xushu->setDeputyMaxHpAdjustedValue(-1);
    xushu->addCompanion("wolong");
    xushu->addCompanion("zhaoyun");

    General *wujing = new General(this, "wujing", "wu");
    wujing->addSkill(new Diaogui);
    wujing->addSkill(new Fengyang);
    wujing->addSkill(new FengyangCardFixed);
    insertRelatedSkills("fengyang", "#fengyang-fixcard");

    General *yanbaihu = new General(this, "yanbaihu", "qun");
    yanbaihu->setDeputyMaxHpAdjustedValue(-1);
    yanbaihu->addSkill(new Zhidao);
    yanbaihu->addSkill(new ZhidaoDamage);
    yanbaihu->addSkill(new ZhidaoProhibit);
    insertRelatedSkills("zhidao", 2, "#zhidao-damage", "#zhidao-prohibit");
    yanbaihu->addSkill(new JiliX);

    addMetaObject<PaiyiCard>();
    addMetaObject<QuanjinCard>();
    addMetaObject<ZaoyunCard>();
    addMetaObject<DiaoguiCard>();
    addMetaObject<FengyangSummon>();

    skills << new Xunxun("_tangzi");
}

ADD_PACKAGE(LordEX)

LordEXCardPackage::LordEXCardPackage() : Package("lord_ex_card", CardPack)
{
    QList<Card *> cards;

    cards
        << new ImperialEdict(Card::Club, 3)
        << new RuleTheWorld()
        << new Conquering()
        << new ConsolidateCountry()
        << new Chaos();;

    foreach(Card *card, cards)
        card->setParent(this);

    addMetaObject<ConsolidateCountryGiveCard>();
    addMetaObject<ImperialEdictAttachCard>();
    addMetaObject<ImperialEdictTrickCard>();

    skills << new ImperialEdictSkill << new ImperialEdictAttach << new ImperialEdictTrick << new ConsolidateCountryGive << new ChaosSelect;
}

ADD_PACKAGE(LordEXCard)
