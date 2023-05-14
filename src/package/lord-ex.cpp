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
#include "standard-wei-generals.h"
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

    virtual int getPriority() const
    {
        return -2;
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
                if (target && target->isAlive() && player->isAlive() && player->canGetCard(target, "he")) {
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
        events << EventPhaseStart;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->isAlive() && player->getPhase() == Player::Start) {
            TriggerList skill_list;
            QList<ServerPlayer *> skill_owners = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *skill_owner, skill_owners) {
                if (skill_owner != player && !skill_owner->isNude() && skill_owner->getMark("#yishe") > 0)
                    skill_list.insert(skill_owner, QStringList(objectName()));
            }
            return skill_list;
        }

        return TriggerList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *skill_owner) const
    {
        QList<int> result = room->askForExchange(skill_owner, objectName(), 1, 0, "@bushi-give:"+ player->objectName());
        if (!result.isEmpty()) {
            LogMessage l;
            l.type = "#InvokeSkill";
            l.from = player;
            l.arg = objectName();
            room->sendLog(l);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, skill_owner->objectName(), player->objectName());
            room->broadcastSkillInvoke(objectName(), skill_owner);
            room->notifySkillInvoked(skill_owner, objectName());

            room->removePlayerMark(skill_owner, "#yishe");
            DummyCard dummy(result);
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, skill_owner->objectName(), player->objectName(), objectName(), QString());
            room->obtainCard(player, &dummy, reason, false);

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *skill_owner) const
    {
        skill_owner->drawCards(2, objectName());
        return false;
    }
};

class BushiCompulsory : public TriggerSkill
{
public:
    BushiCompulsory() : TriggerSkill("#bushi-compulsory")
    {
        events << EventPhaseStart << EventPhaseChanging << EventLoseSkill;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventLoseSkill && player && data.toString().split(":").first() == "bushi")
            room->setPlayerMark(player, "#yishe", 0);
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player == NULL || player->isDead() || !player->hasSkill("bushi")) return QStringList();

        if (triggerEvent == EventPhaseChanging && data.value<PhaseChangeStruct>().to == Player::NotActive)
            return QStringList(objectName());
        else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Start) {
            int x = room->alivePlayerCount() - player->getHp() - 2;
            if (player->getMark("#yishe") > 0 || (x > 0 && !player->isNude()))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill("bushi")) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, "bushi");
        } else {
            if (triggerEvent == EventPhaseChanging)
                invoke = player->askForSkillInvoke("bushi", "mark");
            else if (triggerEvent == EventPhaseStart) {
                int x = room->alivePlayerCount() - player->getHp() - 2;
                invoke = player->askForSkillInvoke("bushi", "discard:::" + QString::number(x));
            }
        }

        if (invoke) {
            if (player->ownSkill("bushi") && !player->hasShownSkill("bushi"))
                player->showGeneral(player->inHeadSkills("bushi"));

            if (player->hasShownSkill("bushi"))
                room->dropHuashenCardbySkillName(player, "bushi");

            room->broadcastSkillInvoke("bushi", player);

            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseChanging)
            room->addPlayerMark(player, "#yishe", player->getHp());
        if (triggerEvent == EventPhaseStart) {
            int x = room->alivePlayerCount() - player->getHp() - 2;
            if (x > 0)
                room->askForDiscard(player, "bushi_discard", x, x, false, true);
            room->setPlayerMark(player, "#yishe", 0);
        }
        return false;
    }
};

class MidaoViewAsSkill : public OneCardViewAsSkill
{
public:
    MidaoViewAsSkill() : OneCardViewAsSkill("midao")
    {
        expand_pile = "rice";
        filter_pattern = ".|.|.|rice";
        response_pattern = "@@midao";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        return originalCard;
    }
};

class Midao : public TriggerSkill
{
public:
    Midao() : TriggerSkill("midao")
    {
        events << EventPhaseStart << AskForRetrial;
        view_as_skill = new MidaoViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();

        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Finish && player->getPile("rice").isEmpty()) {
            return QStringList(objectName());
        } else if (triggerEvent == AskForRetrial && !player->getPile("rice").isEmpty()) {
            return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->askForSkillInvoke(this)) {
                room->broadcastSkillInvoke(objectName(), player);
                return true;
            }
        } else if (triggerEvent == AskForRetrial) {

            JudgeStruct *judge = data.value<JudgeStruct *>();

            QStringList prompt_list;
            prompt_list << "@midao-card" << judge->who->objectName()
                << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
            QString prompt = prompt_list.join(":");

            const Card *card = room->askForCard(player, "@@midao", prompt, data, Card::MethodResponse, judge->who, true);

            if (card) {

                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);

                LogMessage log2;
                log2.card_str = card->toString();
                log2.from = player;
                log2.type = QString("#%1_Resp").arg(card->getClassName());
                room->sendLog(log2);

                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName(), player);

                CardMoveReason reason(CardMoveReason::S_REASON_RESPONSE, player->objectName(), objectName(), QString());

                room->moveCardTo(card, NULL, Player::PlaceTable, reason);

                CardResponseStruct resp(card, judge->who, false);
                resp.m_isHandcard = false;
                resp.m_data = data;
                QVariant _data = QVariant::fromValue(resp);
                room->getThread()->trigger(CardResponded, room, player, _data);

                QStringList card_list = player->tag["midao_cards"].toStringList();
                card_list.append(card->toString());
                player->tag["midao_cards"] = card_list;

                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart) {
            player->drawCards(2, objectName());
            QList<int> result = room->askForExchange(player, "_midao", 2, 2, "@midao-push");
            player->addToPile("rice", result);

        } else if (triggerEvent == AskForRetrial) {
            QStringList card_list = player->tag["midao_cards"].toStringList();
            if (card_list.isEmpty()) return false;
            QString card_str = card_list.takeLast();
            player->tag["midao_cards"] = card_list;

            const Card *card = Card::Parse(card_str);
            if (card) {
                JudgeStruct *judge = data.value<JudgeStruct *>();
                room->retrial(card, player, judge, objectName(), true);
                judge->updateResult();
            }
        }
        return false;
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

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *target = use.to.first();
        player->tag["FengshixUsedata"] = data;
        bool invoke = player->askForSkillInvoke(this, QVariant::fromValue(target));
        player->tag.remove("FengshixUsedata");
        if (invoke) {
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
        if (use.card->getTypeId() != Card::TypeSkill && use.to.size() == 1) {
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

            QList<int> ints = room->askForExchange(target, "wenji_give", 1, 1, "@wenji-give:" + player->objectName());
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
                    record_list << QString::number(card_id + 1);
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

                target->setFlags("WenjiTarget");
                QList<int> ints = room->askForExchange(player, "wenji_giveback", 1, 1, "@wenji-give:" + target->objectName(), QString(), pattern);
                target->setFlags("-WenjiTarget");

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
                 if (player->handCards().contains(record.toInt()-1)) {
                     new_list << record;
                 }
             }

             room->setPlayerProperty(player, "wenji_record", new_list.join("+"));
         }
         if (triggerEvent == PreCardUsed) {
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card && use.card->getTypeId() != Card::TypeSkill && !player->property("wenji_record").toString().isEmpty()) {
                 QStringList record_list = player->property("wenji_record").toString().split("+");
                 foreach (QString record, record_list) {
                     int card_id = record.toInt() - 1;
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
            use.disresponsive_list << "_ALL_PLAYERS";
            data = QVariant::fromValue(use);
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
        if (!Sanguosha->matchExpPattern(pattern, from, card)) return 0;

        if (from->property("wenji_record").toString().isEmpty()) return 0;

        QStringList record_list = from->property("wenji_record").toString().split("+");
        foreach (QString record, record_list) {
            if (card->getSubcards().contains(record.toInt()-1) || card->hasFlag("Global_AvailabilityChecker")) {
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
            return to->getEquips().length();

        return 0;
    }
};

class Lixia : public TriggerSkill
{
public:
    Lixia() : TriggerSkill("lixia")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Start) return skill_list;
        QList<ServerPlayer *> shixies = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *shixie, shixies) {
            if (!player->inMyAttackRange(shixie) && !shixie->willBeFriendWith(player))
                skill_list.insert(shixie, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = false;
        if (ask_who->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(ask_who, objectName());
        } else
            invoke = ask_who->askForSkillInvoke(this);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), qrand()%2+1, ask_who);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        if (player->canDiscard(ask_who, "e") && room->askForChoice(player, "lixia_choose", "draw+discard", QVariant(), "@lixia-choose:" + ask_who->objectName()) == "discard") {
            CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, player->objectName(), ask_who->objectName(), objectName(), NULL);
            const Card *card = Sanguosha->getCard(room->askForCardChosen(player, ask_who, "e", objectName(), false, Card::MethodDiscard));
            room->broadcastSkillInvoke(objectName(), 3, ask_who);
            room->throwCard(card, reason, ask_who, player);
            room->loseHp(player);
        } else
            ask_who->drawCards(1, objectName());

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

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && !player->hasFlag((triggerEvent == Damage)? "Quanji1Used" : "Quanji2Used"))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            player->setFlags((triggerEvent == Damage)? "Quanji1Used" : "Quanji2Used");
            room->broadcastSkillInvoke(objectName(), player);
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

    if (!zhonghui->getPile("power_pile").isEmpty())
        target->drawCards(qMin(zhonghui->getPile("power_pile").length(), 7), objectName());

    if (target->getHandcardNum() > zhonghui->getHandcardNum())
        room->damage(DamageStruct("paiyi", zhonghui, target));
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
        return !player->getPile("power_pile").isEmpty() && !player->hasUsed("PaiyiCard");
    }

    virtual const Card *viewAs(const Card *c) const
    {
        PaiyiCard *py = new PaiyiCard;
        py->addSubcard(c);
        return py;
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
        if (x > 0 && x > source->getHandcardNum())
            source->drawCards(qMin(x - source->getHandcardNum(), 5), "quanjin");


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
    QList<ServerPlayer *> to_count, players, all_players = room->getAllPlayers(true);

    foreach (ServerPlayer *p, all_players) {
        if (!p->isRemoved() && p->isAlive())
            players << p;
    }

    LureTiger *trick = new LureTiger(getSuit(), getNumber());
    trick->addSubcard(this);
    trick->setShowSkill("diaogui");
    trick->setSkillName("diaogui");
    room->useCard(CardUseStruct(trick, card_use.from, card_use.to));

    foreach (ServerPlayer *p, all_players) {
        if ((p->isRemoved() || p->isDead()) && players.contains(p))
            to_count << p;
    }

    int x = 0;

    foreach (ServerPlayer *p, to_count) {
        Player *p1 = p->getNextAlive();
        Player *p2 = p->getLastAlive();

        if (p1 && p2 && p1 != p2 && p1->getFormation().contains(p2)) {
            if (card_use.from->isFriendWith(p1))
                x = qMax(x, p1->getFormation().length());
        }
    }

    if (x > 0)
        card_use.from->drawCards(x, "diaogui");
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
        events << BeforeCardsMove;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (BattleArraySkill::triggerable(player)) {
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if ((move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE)
                     || (move.to && move.to != move.from && move.to_place == Player::PlaceHand
                     && move.reason.m_reason != CardMoveReason::S_REASON_GIVE)) {
                    ServerPlayer *source = room->findPlayerbyobjectName(move.reason.m_playerId);
                    if (source != NULL && source->hasShownOneGeneral() && !player->isFriendWith(source)
                            && move.from && player->inFormationRalation((ServerPlayer *)move.from)) {
                        if (move.from_places.contains(Player::PlaceEquip))
                            return QStringList(objectName());
                    }
                }
            }
        }
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
            room->doBattleArrayAnimate(player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QVariantList move_datas = data.toList();
        QList<int> ids;
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if ((move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE)
                 || (move.to && move.to != move.from && move.to_place == Player::PlaceHand
                 && move.reason.m_reason != CardMoveReason::S_REASON_GIVE)) {
                ServerPlayer *source = room->findPlayerbyobjectName(move.reason.m_playerId);
                if (source != NULL && source->hasShownOneGeneral() && !player->isFriendWith(source)
                        && move.from && player->inFormationRalation((ServerPlayer *)move.from)) {
                    for (int i = 0; i < move.card_ids.length(); ++i) {
                        if (move.from_places.at(i) == Player::PlaceEquip) {
                            ids << move.card_ids.at(i);
                        }
                    }
                }
            }
        }
        data = room->changeMoveData(data, ids);
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
                 room->setPlayerMark(target, "##zhidao", 0);
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
        room->addPlayerMark(target, "##zhidao");

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
        if (player->getPhase() != Player::Play) return QStringList();
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
        events << CardFinished;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &ask_who) const
    {
        if (triggerEvent == CardFinished && player != NULL && player->isAlive()) {
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
            if (player->ownSkill(objectName()))
                player->removeGeneral(player->inHeadSkills(objectName()));
            return true;
        } else if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            Card *use_card = Sanguosha->cloneCard(use.card->objectName(), Card::NoSuit, 0);
            use_card->setSkillName("_jilix");
            QList<ServerPlayer *> targets;
            targets << player;
            room->useCard(CardUseStruct(use_card, use.from, targets), false);
        }
        return false;
    }
};

class JiliXDecrease : public TriggerSkill
{
public:
    JiliXDecrease() : TriggerSkill("#jilix-decrease")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual int getPriority() const
    {
        return -2;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (player && player->isAlive() && player->hasSkill("jilix") && player->getMark("Global_InjuredTimes_Phase") == 1)
            return QStringList("jilix");
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
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
    handling_method = Card::MethodNone;
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
        return !to_select->isEquipped() && selected.length() < x;
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

bool RuleTheWorld::targetRated(const Player *to_select, const Player *Self) const
{
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

        QString choice = room->askForChoice(p, objectName(), choices.join("+"), QVariant::fromValue(effect.to), QString(), allchoices.join("+"));

        if (choice.startsWith("slash")) {
            if (completeEffect ||room->askForDiscard(p, objectName(), 1, 1, true, false, "@rule_the_world-slash::"+effect.to->objectName())) {
                Slash *slash = new Slash(Card::NoSuit, 0);
                slash->setSkillName("_rule_the_world");
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

bool Conquering::targetRated(const Player *, const Player *) const
{
    return true;
}

bool Conquering::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const
{
    return targetRated(to_select, Self);
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
        if (effect.to->canSlash(p))
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

bool ConsolidateCountry::targetRated(const Player *, const Player *) const
{
    return true;
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
    QString choice = room->askForChoice(effect.from, objectName(), choices.join("+"), QVariant::fromValue(effect.to), QString(), allchoices.join("+"));
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

class Suzhi : public TriggerSkill
{
public:
    Suzhi() : TriggerSkill("suzhi")
    {
        events << DamageCaused << CardUsed << CardsMoveOneTime << EventPhaseChanging << EventPhaseStart;
        frequency = Skill::Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
         if (triggerEvent == EventPhaseStart) {
             if (player->getPhase() == Player::RoundStart) {
                 room->detachSkillFromPlayer(player, "fankui_simazhao");
             }
             if (player->getPhase() == Player::NotActive) {
                 QList<ServerPlayer *> allplayers = room->getAlivePlayers();
                 foreach (ServerPlayer *p, allplayers) {
                     room->setPlayerMark(p, "#suzhi", 0);
                 }
             }
         }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getMark("#suzhi") > 2 || player->getPhase() == Player::NotActive)
            return QStringList();
        if (triggerEvent == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && (damage.card->isKindOf("Slash") || damage.card->isKindOf("Duel"))
                    && damage.by_user && !damage.chain && !damage.transfer) {
                return QStringList(objectName());
            }
        } else if (triggerEvent == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() == Card::TypeTrick) {
                if (!use.card->isVirtualCard() || use.card->getSubcards().isEmpty())
                    return QStringList(objectName());
            }
        } else if (triggerEvent == CardsMoveOneTime) {
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from && move.from != player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip)) && move.to_place == Player::DiscardPile) {
                    if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                        if (player->canGetCard(move.from, "he"))
                            return QStringList(objectName());
                    }
                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            if (triggerEvent != EventPhaseChanging) {
                int n = qrand()%2+1;
                if (triggerEvent == CardUsed)
                    n+=2;
                if (triggerEvent == CardsMoveOneTime)
                    n+=4;
                room->broadcastSkillInvoke(objectName(), n, player);
                room->addPlayerMark(player, "#suzhi");
            }
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            damage.damage++;
            data = QVariant::fromValue(damage);
        } else if (triggerEvent == CardUsed)
            player->drawCards(1, objectName());
        else if (triggerEvent == CardsMoveOneTime) {
            QList<ServerPlayer *> targets;
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from && move.from != player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip)) && move.to_place == Player::DiscardPile) {
                    if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                        targets << (ServerPlayer *)move.from;
                    }
                }
            }
            foreach (ServerPlayer *p, targets) {
                if (player->canGetCard(p, "he")) {
                    int card_id = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodGet);
                    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                    room->obtainCard(player, Sanguosha->getCard(card_id), reason, false);
                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            room->acquireSkill(player, "fankui_simazhao", true, true);
        }
        return false;
    }
};

class SuzhiTarget : public TargetModSkill
{
public:
    SuzhiTarget() : TargetModSkill("#suzhi-target")
    {
        pattern = "TrickCard";
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasShownSkill("suzhi") && from->getMark("#suzhi") < 3 && from->getPhase() != Player::NotActive) {
            if (!card->isVirtualCard() || card->getSubcards().isEmpty())
                return 1000;
        }
        return 0;
    }
};

class Zhaoxin : public MasochismSkill
{
public:
    Zhaoxin() : MasochismSkill("zhaoxin")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && !player->isKongcheng())
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            room->showAllCards(player);
            return true;
        }

        return false;
    }

    virtual void onDamaged(ServerPlayer *first, const DamageStruct &) const
    {
        Room *room = first->getRoom();

        if (first->isDead() || first->isKongcheng()) return;

        QList<ServerPlayer *> targets, all_players = room->getAlivePlayers();

        foreach (ServerPlayer *p, all_players) {
            if (p->getHandcardNum() <= first->getHandcardNum() && p != first)
                targets << p;
        }

        if (targets.isEmpty()) return;

        ServerPlayer *second = room->askForPlayerChosen(first, targets, "zhaoxin-exchange", "@zhaoxin-exchange");

        foreach (ServerPlayer *p, all_players) {
            if (p != first && p != second)
                room->doNotify(p, QSanProtocol::S_COMMAND_EXCHANGE_KNOWN_CARDS,
                JsonArray() << first->objectName() << second->objectName());
        }

        QList<int> handcards1 = first->handCards(), handcards2 = second->handCards();

        CardMoveReason reason1(CardMoveReason::S_REASON_SWAP, first->objectName(), second->objectName(), objectName(), QString());
        CardMoveReason reason2(CardMoveReason::S_REASON_SWAP, first->objectName(), first->objectName(), objectName(), QString());
        CardMoveReason reason3(CardMoveReason::S_REASON_NATURAL_ENTER, QString());

        QList<CardsMoveStruct> move_to_table;
        CardsMoveStruct move1(handcards1, NULL, Player::PlaceTable, reason1);
        CardsMoveStruct move2(handcards2, NULL, Player::PlaceTable, reason2);
        move_to_table.push_back(move2);
        move_to_table.push_back(move1);
        if (!move_to_table.isEmpty()) {
            room->moveCardsAtomic(move_to_table, false);

            QList<CardsMoveStruct> back_move;

            handcards1 = room->getCardIdsOnTable(handcards1);
            handcards2 = room->getCardIdsOnTable(handcards2);

            QList<ServerPlayer *> others = room->getAllPlayers(true), players;
            others.removeOne(first);
            others.removeOne(second);
            players << first;
            players << second;

            if (!handcards2.isEmpty()) {
                if (first->isAlive()) {

                    LogMessage log;
                    log.type = "$MoveCard";
                    log.from = first;
                    log.to << second;
                    log.card_str = IntList2StringList(handcards2).join("+");
                    room->doBroadcastNotify(players, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

                    LogMessage log2;
                    log2.type = "#MoveNCards";
                    log2.from = first;
                    log2.to << second;
                    log2.arg = QString::number(handcards2.length());
                    room->doBroadcastNotify(others, QSanProtocol::S_COMMAND_LOG_SKILL, log2.toVariant());

                    CardsMoveStruct move3(handcards2, first, Player::PlaceHand, reason2);
                    back_move.push_back(move3);
                } else {
                    CardsMoveStruct move3(handcards2, NULL, Player::DiscardPile, reason3);
                    back_move.push_back(move3);
                }
            }
            if (!handcards1.isEmpty()) {
                if (second->isAlive()) {

                    LogMessage log;
                    log.type = "$MoveCard";
                    log.from = second;
                    log.to << first;
                    log.card_str = IntList2StringList(handcards1).join("+");
                    room->doBroadcastNotify(players, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

                    LogMessage log2;
                    log2.type = "#MoveNCards";
                    log2.from = second;
                    log2.to << first;
                    log2.arg = QString::number(handcards1.length());
                    room->doBroadcastNotify(others, QSanProtocol::S_COMMAND_LOG_SKILL, log2.toVariant());

                    CardsMoveStruct move3(handcards1, second, Player::PlaceHand, reason1);
                    back_move.push_back(move3);
                } else {
                    CardsMoveStruct move3(handcards1, NULL, Player::DiscardPile, reason3);
                    back_move.push_back(move3);
                }
            }

            if (!back_move.isEmpty())
                room->moveCardsAtomic(back_move, false);
        }


    }
};

class Shicai : public TriggerSkill
{
public:
    Shicai() : TriggerSkill("shicai")
    {
        events << Damaged;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.damage > 1 && player->forceToDiscard(1, false).isEmpty())
                return QStringList();
            return QStringList(objectName());
        }
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

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.damage > 1)
            room->askForDiscard(player, "shicai_discard", 2, 2, false, true);
        else
            player->drawCards(1, objectName());

        return false;
    }
};

class Chenglve : public TriggerSkill
{
public:
    Chenglve() : TriggerSkill("chenglve")
    {
        events << CardFinished;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        CardUseStruct use = data.value<CardUseStruct>();
        if (player == NULL || player->isDead()) return skill_list;
        if (use.card->getTypeId() != Card::TypeSkill && use.to.length() > 1) {
            QList<ServerPlayer *> xuyous = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *xuyou, xuyous) {
                if (player->isFriendWith(xuyou))
                    skill_list.insert(xuyou, QStringList(objectName()));
            }
        }

        return skill_list;
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *xuyou) const
    {
        if (xuyou->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, xuyou->objectName(), player->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *xuyou) const
    {
        player->drawCards(1, objectName());
        CardUseStruct use = data.value<CardUseStruct>();
        QStringList damage_record = use.card->tag["GlobalCardDamagedTag"].toStringList();

        if (damage_record.contains(xuyou->objectName())) {
            QList<ServerPlayer *> players = room->getAlivePlayers(), targets;
            foreach (ServerPlayer *p, players) {
                if (p->isFriendWith(xuyou) && p->getMark("@companion") + p->getMark("@halfmaxhp") + p->getMark("@firstshow") + p->getMark("@careerist") == 0 && p->hasShownAllGenerals())
                    targets << p;
            }
            if (!targets.isEmpty()) {
                ServerPlayer *target = room->askForPlayerChosen(xuyou, targets, "chenglve_mark", "@chenglve-mark", true);
                if (target) {
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, xuyou->objectName(), target->objectName());
                    room->addPlayerMark(target, "@halfmaxhp");
                }
            }
        }
        return false;
    }
};

class Baolie : public PhaseChangeSkill
{
public:
    Baolie() : PhaseChangeSkill("baolie")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Play && player->hasShownOneGeneral()) {
            QList<ServerPlayer *> players = room->getAlivePlayers();
            foreach (ServerPlayer *p, players) {
                if (p->hasShownOneGeneral() && !p->isFriendWith(player) && p->inMyAttackRange(player))
                    return QStringList(objectName());
            }
        }
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
        QList<ServerPlayer *> players = room->getAlivePlayers(), targets;
        room->sortByActionOrder(players);
        foreach (ServerPlayer *p, players) {
            if (p->hasShownOneGeneral() && !p->isFriendWith(player) && p->inMyAttackRange(player)) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                targets << p;
            }
        }
        foreach (ServerPlayer *p, targets) {
            if (player->isDead()) break;
            if (p->isDead()) continue;
            if (!p->canSlash(player) || !room->askForUseSlashTo(p, player, "@baolie-slash:" + player->objectName())) {
                if (player->canDiscard(p, "he")) {
                    room->throwCard(room->askForCardChosen(player, p, "he", "baolie", false, Card::MethodDiscard), p, player);
                }
            }
        }
        return false;
    }
};

class BaolieTargetMod : public TargetModSkill
{
public:
    BaolieTargetMod() : TargetModSkill("#baolie-target")
    {
        pattern = "Slash";
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *to) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card) || !from->hasShownSkill("baolie"))
            return 0;

        if (to && to->getHp() >= from->getHp())
            return 10000;

        return 0;
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *to) const
    {
        return getResidueNum(from, card, to);
    }

};

class AocaiVeiw : public OneCardViewAsSkill
{
public:
    AocaiVeiw() : OneCardViewAsSkill("aocai_view")
    {
        expand_pile = "#aocai",
        response_pattern = "@@aocai_view";
    }

    bool viewFilter(const Card *to_select) const
    {
        QStringList aocai = Self->property("aocai").toString().split("+");
        foreach (QString id, aocai) {
            bool ok;
            if (id.toInt(&ok) == to_select->getEffectiveId() && ok)
                return true;
        }
        return false;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        return originalCard;
    }
};

class AocaiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    AocaiViewAsSkill() : ZeroCardViewAsSkill("aocai")
    {
    }

    bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (player->getPhase() != Player::NotActive || player->hasFlag("Global_AocaiFailed")) return false;
        return pattern == "slash" || pattern == "jink" || pattern == "peach" || pattern.contains("analeptic");
    }

    const Card *viewAs() const
    {
        AocaiCard *aocai_card = new AocaiCard;
        aocai_card->setUserString(Sanguosha->currentRoomState()->getCurrentCardUsePattern());
        aocai_card->setShowSkill(objectName());
        return aocai_card;
    }
};

class Aocai : public TriggerSkill
{
public:
    Aocai() : TriggerSkill("aocai")
    {
        view_as_skill = new AocaiViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }


    static bool cheak(ServerPlayer *player, int id)
    {
        const Card *card = Sanguosha->getCard(id);

        if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE)
            return !player->isCardLimited(card, Card::MethodUse);
        else if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
            return !player->isCardLimited(card, Card::MethodResponse);

        return false;
    }

    static int view(Room *room, ServerPlayer *player, QList<int> &ids, QList<int> &enabled)
    {
        int result = -1;

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(ids).join("+");
        room->sendLog(log, player);

        player->broadcastSkillInvoke("aocai");
        room->notifySkillInvoked(player, "aocai");

        room->notifyMoveToPile(player, ids, "aocai", Player::PlaceTable, true, true);
        room->setPlayerProperty(player, "aocai", IntList2StringList(enabled).join("+"));
        const Card *card = room->askForCard(player, "@@aocai_view", "@aocai-view", QVariant(), Card::MethodNone);
        room->notifyMoveToPile(player, ids, "aocai", Player::PlaceTable, false, false);
        if (card == NULL)
            room->setPlayerFlag(player, "Global_AocaiFailed");
        else {
            result = card->getSubcards().first();
        }
        room->returnToTopDrawPile(ids);
        return result;
    }
};

AocaiCard::AocaiCard()
{
}

bool AocaiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool AocaiCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
        return true;

    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetFixed();
}

bool AocaiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetsFeasible(targets, Self);
}

const Card *AocaiCard::validateInResponse(ServerPlayer *user) const
{
    Room *room = user->getRoom();

    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = user;
    log.arg = "aocai";
    room->sendLog(log);

    if (user->ownSkill("aocai") && !user->hasShownSkill("aocai"))
        user->showGeneral(user->inHeadSkills("aocai"));

    if (user->hasShownSkill("huashen"))
        room->dropHuashenCardbySkillName(user, "aocai");

    QString card_names = toString().split(":").last();
    QStringList names = card_names.split("+");
    if (names.contains("slash")) names << "fire_slash" << "thunder_slash";

    QList<int> ids = room->getNCards(2, false), enabled;
    foreach (int id, ids) {
        if (Aocai::cheak(user, id) && names.contains(Sanguosha->getCard(id)->objectName()))
            enabled << id;
    }

    int id = Aocai::view(room, user, ids, enabled);
    return Sanguosha->getCard(id);
}

const Card *AocaiCard::validate(CardUseStruct &cardUse) const
{
    ServerPlayer *user = cardUse.from;
    Room *room = user->getRoom();

    LogMessage log;
    log.from = user;
    log.to = cardUse.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    if (user->ownSkill("aocai") && !user->hasShownSkill("aocai"))
        user->showGeneral(user->inHeadSkills("aocai"));

    if (user->hasShownSkill("huashen"))
        room->dropHuashenCardbySkillName(user, "aocai");

    QList<int> ids = room->getNCards(2, false);

    QString card_names = toString().split(":").last();
    QStringList names = card_names.split("+");
    if (names.contains("slash")) names << "fire_slash" << "thunder_slash";

    QList<int> enabled;
    foreach (int id, ids)
        if (Aocai::cheak(user, id) && names.contains(Sanguosha->getCard(id)->objectName()))
            enabled << id;

    int id = Aocai::view(room, user, ids, enabled);

    return Sanguosha->getCard(id);
}

DuwuCard::DuwuCard()
{
    mute = true;
    target_fixed = true;
}

void DuwuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    room->setPlayerMark(source, "@duwu", 0);
    room->broadcastSkillInvoke("duwu", source);
    room->doSuperLightbox("zhugeke", "duwu");

    CardUseStruct use = card_use;
    QList<ServerPlayer *> all_players = room->getAlivePlayers();

    foreach (ServerPlayer *p, all_players) {
        if (source->inMyAttackRange(p) && !source->willBeFriendWith(p))
            use.to << p;
    }

    SkillCard::onUse(room, use);
}

void DuwuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->setPlayerFlag(source, "DuwuUsing");
    int index = source->startCommand("duwu");

    foreach (ServerPlayer *p, targets) {
        if (source->isDead()) break;
        if (p->isAlive() && !p->doCommand("duwu", index, source)) {
            room->damage(DamageStruct("duwu", source, p));
            source->drawCards(1, objectName());
        }
    }
    QStringList list = source->property("duwu_targets").toString().split("+");
    foreach (QString player_name, list) {
        ServerPlayer *p = room->findPlayerbyobjectName(player_name);
        if (p && p->isAlive()) {
            room->loseHp(source);
            break;
        }
    }
    room->setPlayerProperty(source, "duwu_targets", QVariant());

    room->setPlayerFlag(source, "-DuwuUsing");

}

class DuwuViewAsSkill : public ZeroCardViewAsSkill
{
public:
    DuwuViewAsSkill() : ZeroCardViewAsSkill("duwu")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@duwu") > 0;
    }

    virtual const Card *viewAs() const
    {
        DuwuCard *card = new DuwuCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Duwu : public TriggerSkill
{
public:
    Duwu() : TriggerSkill("duwu")
    {
        frequency = Limited;
        limit_mark = "@duwu";
        view_as_skill = new DuwuViewAsSkill;
        events << Dying;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->hasFlag("DuwuUsing")) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who) {
                QStringList list = player->property("duwu_targets").toString().split("+");
                list << dying.who->objectName();
                room->setPlayerProperty(player, "duwu_targets", list.join("+"));
            }
        }

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

class ShiluViewAsSkill : public ViewAsSkill
{
public:
    ShiluViewAsSkill() : ViewAsSkill("shilu")
    {
        response_pattern = "@@shilu";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && selected.length() < Self->getGeneralPile("massacre").length();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        DummyCard *dummy = new DummyCard;
        dummy->addSubcards(cards);
        return dummy;
    }
};

class Shilu : public TriggerSkill
{
public:
    Shilu() : TriggerSkill("shilu")
    {
        events << Death << EventPhaseStart;
        view_as_skill = new ShiluViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)) {
            if (triggerEvent == Death) {
                DeathStruct death = data.value<DeathStruct>();
                if (!death.who->getGeneral()->objectName().contains("sujiang") || (death.who->getGeneral2() &&
                        !death.who->getGeneral2()->objectName().contains("sujiang")))
                return QStringList(objectName());
            } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Start) {
                if (!player->isNude() && !Self->getGeneralPile("massacre").isEmpty())
                    return QStringList(objectName());
            }

        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who && player->askForSkillInvoke(this, QVariant::fromValue(death.who))) {
                int n = qrand()%2+1;
                room->broadcastSkillInvoke(objectName(), n, player);
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), death.who->objectName());
                return true;
            }
        } else if (triggerEvent == EventPhaseStart) {
            int x = player->getGeneralPile("massacre").length();
            const Card *card = room->askForCard(player, "@@shilu", "@shilu:::"+QString::number(x), data, Card::MethodNone);
            if (card != NULL) {
                room->notifySkillInvoked(player, objectName());
                room->broadcastSkillInvoke(objectName(), 3, player);
                room->throwCard(card, player, NULL, objectName());
                QStringList n_list = player->tag["shilu_count"].toStringList();
                n_list.append(QString::number(card->subcardsLength()));
                player->tag["shilu_count"] = n_list;
                return true;
            }

        }

        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            ServerPlayer *target = death.who;

            int x = (death.damage && death.damage->from == player) ? 2:0;

            QStringList generals;
            if (!target->getGeneral()->objectName().contains("sujiang")) {
                QString name = target->getGeneral()->objectName();
                generals << name;
            }

            if (target->getGeneral2() && !target->getGeneral2()->objectName().contains("sujiang")) {
                QString name = target->getGeneral2()->objectName();
                generals << name;
            }

            if (x > 0) {
                QStringList available, all = Sanguosha->getLimitedGeneralNames();

                foreach (QString name, all) {
                    if (!name.startsWith("lord_") && !room->getUsedGeneral().contains(name)) {
                        const General *general = Sanguosha->getGeneral(name);
                        if (general && !general->isDoubleKingdoms() && general->getKingdom() != "careerist")
                        available << name;
                    }
                }

                if (!available.isEmpty()) {

                    qShuffle(available);

                    int n = qMin(x, available.length());
                    QStringList acquired = available.mid(0, n);

                    foreach (QString name, acquired) {
                        generals << name;
                    }

                }
            }

            player->addToGeneralPile("massacre", generals);

        } else if (triggerEvent == EventPhaseStart) {
            QStringList effect_list = player->tag["shilu_count"].toStringList();
            QString effect_name = effect_list.takeLast();
            player->tag["shilu_count"] = effect_list;
            int x = effect_name.toInt();
            if (x > 0)
                player->drawCards(x, objectName());
        }

        return false;
    }
};

class Xiongnve : public TriggerSkill
{
public:
    Xiongnve() : TriggerSkill("xiongnve")
    {
        events << EventPhaseStart << EventPhaseEnd << EventPhaseChanging;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::RoundStart)
            room->setPlayerMark(player, "##xiongnve_avoid", 0);
        else if (triggerEvent == EventPhaseChanging) {
            room->setPlayerProperty(player, "xiongnve_adddamage", QVariant());
            room->setPlayerProperty(player, "xiongnve_extraction", QVariant());
            room->setPlayerProperty(player, "xiongnve_nolimit", QVariant());
            room->setPlayerMark(player, "##xiongnve", 0);
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && !player->getGeneralPile("massacre").isEmpty() && player->getPhase() == Player::Play) {
            if (triggerEvent == EventPhaseEnd && player->getGeneralPile("massacre").length() < 2) return QStringList();
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->askForSkillInvoke(this, "attack")) {
                room->broadcastSkillInvoke(objectName(), 1, player);
                return true;
            }
        } else if (triggerEvent == EventPhaseEnd) {
            if (player->askForSkillInvoke(this, "defence")) {
                room->broadcastSkillInvoke(objectName(), 6, player);
                return true;
            }
        }

        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList huashens = player->getGeneralPile("massacre");

        if (triggerEvent == EventPhaseStart) {

            QString name = room->askForGeneral(player, huashens, QString(), true, "xiongnve_attack");

            LogMessage log;
            log.type = "#dropMassacreDetail";
            log.from = player;
            log.arg = name;
            room->sendLog(log);

            player->removeGeneralPile("massacre", name);

            const General *general = Sanguosha->getGeneral(name);
            if (general == NULL) return false;
            QStringList g_kingdoms = general->getKingdoms();

            QString choice = room->askForChoice(player, objectName(), "adddamage+extraction+nolimit", QVariant(), "@xiongnve-choice");
            if (choice == "adddamage") {
                foreach (QString kingdom, g_kingdoms) {
                    LogMessage log;
                    log.type = "#xiongnveAdddamage";
                    log.from = player;
                    log.arg = kingdom;
                    room->sendLog(log);
                }
                QStringList kingdoms = player->property("xiongnve_adddamage").toString().split("+");
                kingdoms << g_kingdoms;
                room->setPlayerProperty(player, "xiongnve_adddamage", kingdoms.join("+"));
            } else if (choice == "extraction") {
                foreach (QString kingdom, g_kingdoms) {
                    LogMessage log;
                    log.type = "#xiongnveExtraction";
                    log.from = player;
                    log.arg = kingdom;
                    room->sendLog(log);
                }
                QStringList kingdoms = player->property("xiongnve_extraction").toString().split("+");
                kingdoms << g_kingdoms;
                room->setPlayerProperty(player, "xiongnve_extraction", kingdoms.join("+"));
            } else if (choice == "nolimit") {
                foreach (QString kingdom, g_kingdoms) {
                    LogMessage log;
                    log.type = "#xiongnveNolimit";
                    log.from = player;
                    log.arg = kingdom;
                    room->sendLog(log);
                }
                QStringList kingdoms = player->property("xiongnve_nolimit").toString().split("+");
                kingdoms << g_kingdoms;
                room->setPlayerProperty(player, "xiongnve_nolimit", kingdoms.join("+"));
            }

            room->addPlayerMark(player, "##xiongnve");

        } else if (triggerEvent == EventPhaseEnd && huashens.length() > 1) {

            QString name = room->askForGeneral(player, huashens, QString(), true, "xiongnve_defence");
            LogMessage log;
            log.type = "#dropMassacreDetail";
            log.from = player;
            log.arg = name;
            room->sendLog(log);
            huashens.removeOne(name);

            player->removeGeneralPile("massacre", name);

            name = room->askForGeneral(player, huashens, QString(), true, "xiongnve_defence");
            log.arg = name;
            room->sendLog(log);
            huashens.removeOne(name);

            player->removeGeneralPile("massacre", name);

            room->addPlayerMark(player, "##xiongnve_avoid");
        }

        return false;
    }
};

class XiongnveEffect : public TriggerSkill
{
public:
    XiongnveEffect() : TriggerSkill("#xiongnve-effect")
    {
        events << DamageCaused << DamageInflicted;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (triggerEvent == DamageCaused) {
            if (damage.to && damage.to->isAlive() && damage.to->hasShownOneGeneral()) {
                QStringList kingdoms1 = player->property("xiongnve_adddamage").toString().split("+"),
                        kingdoms2 = player->property("xiongnve_extraction").toString().split("+");
                if ((kingdoms1.contains(damage.to->getSeemingKingdom())) ||
                        (kingdoms2.contains(damage.to->getSeemingKingdom()) && player->canGetCard(damage.to, "he")))
                    return QStringList(objectName());
            }
        } else if (triggerEvent == DamageInflicted) {
            if (damage.from && damage.from != player && player->getMark("##xiongnve_avoid") > 0)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (triggerEvent == DamageCaused) {
            QStringList kingdoms1 = player->property("xiongnve_adddamage").toString().split("+"),
                    kingdoms2 = player->property("xiongnve_extraction").toString().split("+");
            if (kingdoms1.contains(damage.to->getSeemingKingdom())) {
                room->broadcastSkillInvoke("xiongnve", qrand()%2+2, player);
                damage.damage++;
                data = QVariant::fromValue(damage);
            }

            if (kingdoms2.contains(damage.to->getSeemingKingdom()) && player->canGetCard(damage.to, "he")) {
                room->broadcastSkillInvoke("xiongnve", qrand()%2+4, player);
                int card_id = room->askForCardChosen(player, damage.to, "he", "xiongnve", false, Card::MethodGet);
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, Sanguosha->getCard(card_id), reason, false);
            }
        } if (triggerEvent == DamageInflicted) {
            room->broadcastSkillInvoke("xiongnve", 7, player);
            damage.damage--;
            data = QVariant::fromValue(damage);

            if (damage.damage <= 0)
                return true;
        }
        return false;
    }
};

class XiongnveTarget : public TargetModSkill
{
public:
    XiongnveTarget() : TargetModSkill("#xiongnve-target")
    {
        pattern = "^SkillCard";
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *to) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        QStringList kingdoms = from->property("xiongnve_nolimit").toString().split("+");

        if (to && to->hasShownOneGeneral() && kingdoms.contains(to->getSeemingKingdom()))
            return 1000;

        return 0;
    }
};



class Congcha : public TriggerSkill
{
public:
    Congcha() : TriggerSkill("congcha")
    {
        events << DrawNCards << EventPhaseStart;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::RoundStart) {
            player->tag.remove("congcha_targets");
            QList<ServerPlayer *> alls = room->getAlivePlayers();
            foreach (ServerPlayer *p1, alls) {
                bool remove_mark = true;
                foreach (ServerPlayer *p2, alls) {
                    QStringList list = p2->tag["congcha_targets"].toStringList();
                    if (list.contains(p1->objectName())) {
                        remove_mark = false;
                        break;
                    }
                }
                if (remove_mark)
                    room->setPlayerMark(p1, "##congcha", 0);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == DrawNCards) {
            QList<ServerPlayer *> allplayers = room->getAlivePlayers();
            foreach (ServerPlayer *p, allplayers) {
                if (!p->hasShownOneGeneral())
                    return QStringList();
            }
            return QStringList(objectName());
        } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Start) {
            QList<ServerPlayer *> allplayers = room->getOtherPlayers(player);
            foreach (ServerPlayer *p, allplayers) {
                if (!p->hasShownOneGeneral())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == DrawNCards) {
            if (player->askForSkillInvoke(this)) {
                room->broadcastSkillInvoke(objectName(), player);
                return true;
            }
        } else if (triggerEvent == EventPhaseStart) {
            QList<ServerPlayer *> to_choose, allplayers = room->getOtherPlayers(player);
            foreach (ServerPlayer *p, allplayers) {
                if (!p->hasShownOneGeneral())
                    to_choose << p;
            }
            if (to_choose.isEmpty()) return false;

            ServerPlayer *to = room->askForPlayerChosen(player, to_choose, objectName(), "@congcha-target", true, true);
            if (to != NULL) {
                room->broadcastSkillInvoke(objectName(), player);

                QStringList target_list = player->tag["congcha_vic"].toStringList();
                target_list.append(to->objectName());
                player->tag["congcha_vic"] = target_list;
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DrawNCards)
            data = data.toInt() + 2;
        else if (triggerEvent == EventPhaseStart) {
            QStringList target_list = player->tag["congcha_vic"].toStringList();
            QString target_name = target_list.takeLast();
            player->tag["congcha_vic"] = target_list;
            ServerPlayer *to = room->findPlayerbyobjectName(target_name);
            if (to && !to->hasShownOneGeneral()) {
                room->addPlayerMark(to, "##congcha");
                QStringList list = player->tag["congcha_targets"].toStringList();
                list << to->objectName();
                player->tag["congcha_targets"] = list;
            }
        }
        return false;
    }
};

class CongchaEffect : public TriggerSkill
{
public:
    CongchaEffect() : TriggerSkill("#congcha-effect")
    {
        events << GeneralShowed;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player->isDead()) return skill_list;
        QList<ServerPlayer *> owners = room->getAlivePlayers();
        foreach (ServerPlayer *owner, owners) {
            QStringList target_list = owner->tag["congcha_targets"].toStringList();
            if (target_list.contains(player->objectName()))
                skill_list.insert(owner, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *panjun) const
    {
        QStringList target_list = panjun->tag["congcha_targets"].toStringList();
        target_list.removeAll(player->objectName());
        panjun->tag["congcha_targets"] = target_list;

        bool remove_mark = true;
        QList<ServerPlayer *> alls = room->getAlivePlayers();
        foreach (ServerPlayer *p, alls) {
            QStringList list = p->tag["congcha_targets"].toStringList();
            if (list.contains(player->objectName())) {
                remove_mark = false;
                break;
            }
        }
        if (remove_mark)
            room->setPlayerMark(player, "##congcha", 0);

        if (panjun->isFriendWith(player)) {
            QList<ServerPlayer *> players;
            players << player << panjun;
            room->sortByActionOrder(players);
            foreach (ServerPlayer *p, players) {
                if (p->isAlive())
                    p->drawCards(2, "congcha");
            }

        } else
            room->loseHp(player);

        return false;
    }
};

class Gongqing : public TriggerSkill
{
public:
    Gongqing() : TriggerSkill("gongqing")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from->isAlive() && damage.from->getAttackRange() > 3)
                return QStringList(objectName());
        }
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

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->isAlive()) {
            int x = damage.from->getAttackRange();
            if (x > 3)
                damage.damage++;
            else if (x < 3)
                damage.damage = 1;
            data = QVariant::fromValue(damage);
        }

        return false;
    }
};

class GongqingDecrease : public TriggerSkill
{
public:
    GongqingDecrease() : TriggerSkill("#gongqing-decrease")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual int getPriority() const
    {
        return -2;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player && player->isAlive() && player->hasSkill("gongqing")) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from->isAlive() && damage.from->getAttackRange() < 3 && damage.damage > 1)
                return QStringList("gongqing");
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }
};

JinfaCard::JinfaCard()
{

}

bool JinfaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isNude();
}

void JinfaCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    QList<int> result = room->askForExchange(target, "_jinfa", 1, 0, "@jinfa-give:"+ source->objectName(), "", "EquipCard");
    if (result.isEmpty()) {
        if (source->canGetCard(target, "he")) {
            int card_id = room->askForCardChosen(source, target, "he", "jinfa", false, Card::MethodGet);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
            room->obtainCard(source, Sanguosha->getCard(card_id), reason, false);
        }
    } else {
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), source->objectName(), "jinfa", QString());
        reason.m_playerId = source->objectName();

        CardsMoveStruct give_move(result, source, Player::PlaceHand, reason);
        QVariant data = room->moveCardsSub(give_move, true);

        QVariantList move_datas = data.toList();

        bool is_spade = false;
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.to == source) {
                foreach (int id, move.card_ids) {
                    if (Sanguosha->getCard(id)->getSuit() == Card::Spade && room->getCardOwner(id) == source
                            && room->getCardPlace(id) == Player::PlaceHand) {
                        is_spade = true;
                        break;
                    }
                }
            }
        }

        if (is_spade && target->canSlash(source, false)) {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_jinfa");
            room->useCard(CardUseStruct(slash, target, source), false);
        }
    }
}

class Jinfa : public OneCardViewAsSkill
{
public:
    Jinfa() : OneCardViewAsSkill("jinfa")
    {
        filter_pattern = ".!";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        JinfaCard *skill_card = new JinfaCard;
        skill_card->addSubcard(originalCard);
        skill_card->setShowSkill(objectName());
        return skill_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JinfaCard");
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return (card->getTypeId() == Card::TypeSkill) ? -1 : 0;
    }
};

class Xishe : public TriggerSkill
{
public:
    Xishe() : TriggerSkill("xishe")
    {
        events << EventPhaseStart << Death;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.damage && death.damage->card && death.damage->card->getSkillName() == objectName() && death.damage->from == player) {

                room->setPlayerFlag(player, "xisheKilledPlayer");
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Start && player->isAlive()) {
            QList<ServerPlayer *> owners = room->findPlayersBySkillName(objectName());
            TriggerList skill_list;
            foreach (ServerPlayer *owner, owners)
                if (owner != player && owner->hasEquip())
                    skill_list.insert(owner, QStringList(objectName()));
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *huangzu) const
    {
        if (room->askForCard(huangzu, ".|.|.|equipped", "@xishe-slash:"+player->objectName(), data, Card::MethodDiscard, NULL, false, "xishe"))
            return true;
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *huangzu) const
    {
        do {
            if (huangzu->canSlash(player, false)) {
                Slash *slash = new Slash(Card::NoSuit, 0);
                slash->setSkillName("_xishe");
                if (player->getHp() < huangzu->getHp())
                    slash->setFlags("GlobalCardUseDisresponsive");
                room->useCard(CardUseStruct(slash, huangzu, player), false);
            }
        } while(huangzu->isAlive() && player->isAlive() && huangzu->hasEquip() &&
                room->askForCard(huangzu, ".|.|.|equipped", "@xishe-slash:"+player->objectName()));

        return false;
    }
};

class XisheTransform : public TriggerSkill
{
public:
    XisheTransform() : TriggerSkill("#xishe-transform")
    {
        events << EventPhaseChanging;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().to == Player::NotActive) {
            QList<ServerPlayer *> owners = room->getAlivePlayers();
            TriggerList skill_list;
            foreach (ServerPlayer *owner, owners)
                if (owner->hasFlag("xisheKilledPlayer") && owner->getMark("xishetransformUsed") == 0 && owner->canTransform())
                    skill_list.insert(owner, QStringList(objectName()));
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *huangzu) const
    {
        if (room->askForChoice(huangzu, "transform_xishe", "yes+no", QVariant(), "@transform-ask:::xishe") == "yes") {
            room->broadcastSkillInvoke("transform", huangzu->isMale());
            room->addPlayerMark(huangzu, "xishetransformUsed");
            room->transformDeputyGeneral(huangzu, QString(), false);
        }
        return false;
    }
};

HuaiyiCard::HuaiyiCard()
{
    target_fixed = true;
}

void HuaiyiCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->showAllCards(card_use.from);
}

void HuaiyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<int> blacks;
    QList<int> reds;
    foreach (const Card *c, source->getHandcards()) {
        if (source->isJilei(c)) continue;
        if (c->isRed())
            reds << c->getId();
        else
            blacks << c->getId();
    }

    if (reds.isEmpty() || blacks.isEmpty()) return;

    QString to_discard = room->askForChoice(source, "huaiyi", "black+red", QVariant(), "@huaiyi-choose");

    QList<int> *pile = NULL;
    if (to_discard == "black")
        pile = &blacks;
    else
        pile = &reds;

    int n = pile->length();

    DummyCard dm(*pile);
    room->throwCard(&dm, source);

    QList<ServerPlayer *> to_choose;
    foreach(ServerPlayer *p, room->getOtherPlayers(source)) {
        if (!p->isNude())
            to_choose << p;
    }

    if (to_choose.isEmpty()) return;

    QList<ServerPlayer *> choosees = room->askForPlayersChosen(source, to_choose, "huaiyi_snatch", 0, n, "@huaiyi-snatch:::"+QString::number(n));

    if (choosees.isEmpty()) return;

    room->sortByActionOrder(choosees);

    foreach (ServerPlayer *to, choosees) {
        if (source->isAlive() && to->isAlive() && !to->isNude()) {
            int card_id = room->askForCardChosen(source, to, "he", "huaiyi", false, Card::MethodNone);
            if (Sanguosha->getCard(card_id)->getTypeId() == Card::TypeEquip)
                source->addToPile("&disloyalty", card_id);
            else {
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
                room->obtainCard(source, Sanguosha->getCard(card_id), reason, false);
            }
        }
    }
}

class Huaiyi : public ZeroCardViewAsSkill
{
public:
    Huaiyi() : ZeroCardViewAsSkill("huaiyi")
    {

    }

    const Card *viewAs() const
    {
        HuaiyiCard *skill_card = new HuaiyiCard;
        skill_card->setShowSkill(objectName());
        return skill_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("HuaiyiCard");
    }
};

class Zisui : public TriggerSkill
{
public:
    Zisui() : TriggerSkill("zisui")
    {
        events << DrawNCards << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if ((triggerEvent == DrawNCards && !player->getPile("&disloyalty").isEmpty()) ||
                (triggerEvent == EventPhaseStart && player->getPhase() == Player::Finish
                 && player->getPile("&disloyalty").length() > player->getMaxHp())) {
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            if (triggerEvent == DrawNCards)
                room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DrawNCards)
            data = data.toInt() + player->getPile("&disloyalty").length();
        else if (triggerEvent == EventPhaseStart)
            room->killPlayer(player);
        return false;
    }
};

class Lianpian : public PhaseChangeSkill
{
public:
    Lianpian() : PhaseChangeSkill("lianpian")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Finish && player->getMark("GlobalDisCardCount") > player->getHp())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> to_choose, all_players = room->getAlivePlayers();
        foreach (ServerPlayer *p, all_players) {
            if (player->isFriendWith(p))
                to_choose << p;
        }
        if (to_choose.isEmpty()) return false;

        ServerPlayer *to = room->askForPlayerChosen(player, to_choose, objectName(), "@lianpian-target", true, true);
        if (to != NULL) {
            room->broadcastSkillInvoke(objectName(), player);

            QStringList target_list = player->tag["lianpian_target"].toStringList();
            target_list.append(to->objectName());
            player->tag["lianpian_target"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QStringList target_list = player->tag["lianpian_target"].toStringList();
        QString target_name = target_list.takeLast();
        player->tag["lianpian_target"] = target_list;
        ServerPlayer *to = room->findPlayerbyobjectName(target_name);

        if (to)
            to->fillHandCards(to->getMaxHp(), objectName());

        return false;
    }
};


class LianpianOther : public TriggerSkill
{
public:
    LianpianOther() : TriggerSkill("#lianpian-other")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::Finish && player->isAlive()) {
            QList<ServerPlayer *> owners = room->findPlayersBySkillName("lianpian");
            TriggerList skill_list;
            foreach (ServerPlayer *owner, owners)
                if (owner->hasShownSkill("lianpian") && player != owner && player->getMark("GlobalDisCardCount") > owner->getHp()
                        && (owner->isWounded() || player->canDiscard(owner, "he")))
                    skill_list.insert(owner, QStringList(objectName()));
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        QStringList choices;
        if (ask_who->isWounded()) choices << "recover";
        if (player->canDiscard(ask_who, "he")) choices << "discard";
        if (choices.isEmpty()) return false;
        choices << "cancel";
        QString all_choices = "recover+discard+cancel";


        QString choice = room->askForChoice(player, "lianpian", choices.join("+"), data, "@lianpian:" + ask_who->objectName(), all_choices);
        if (choice == "cancel") return false;

        LogMessage log;
        log.type = "#InvokeOthersSkill";
        log.from = player;
        log.to << ask_who;
        log.arg = "lianpian";
        room->sendLog(log);
        room->broadcastSkillInvoke("lianpian", ask_who);
        room->notifySkillInvoked(ask_who, "lianpian");
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());

        QStringList choice_list = ask_who->tag["lianpian_choice"].toStringList();
        choice_list.append(choice);
        ask_who->tag["lianpian_choice"] = choice_list;

        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        QStringList choice_list = ask_who->tag["lianpian_choice"].toStringList();
        QString choice = choice_list.takeLast();
        ask_who->tag["lianpian_choice"] = choice_list;
        if (choice == "recover") {
            RecoverStruct recover;
            recover.who = player;
            room->recover(ask_who, recover);
        } else if (choice == "discard" && player->canDiscard(ask_who, "he")) {
            int card_id = room->askForCardChosen(player, ask_who, "he", "lianpian", false, Card::MethodDiscard);
            room->throwCard(card_id, ask_who, player);
        }
        return false;
    }
};

class Tongdu : public PhaseChangeSkill
{
public:
    Tongdu() : PhaseChangeSkill("tongdu")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Finish && player->getMark("GlobalRuleDisCardCount") > 0)
            return QStringList(objectName());
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
        player->drawCards(qMin(player->getMark("GlobalRuleDisCardCount"), 3), objectName());
        return false;
    }
};

class TongduOther : public TriggerSkill
{
public:
    TongduOther() : TriggerSkill("#tongdu-other")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::Finish && player->getMark("GlobalRuleDisCardCount") > 0) {
            QList<ServerPlayer *> owners = room->findPlayersBySkillName("tongdu");
            TriggerList skill_list;
            foreach (ServerPlayer *owner, owners)
                if (owner->hasShownSkill("tongdu") && player->isFriendWith(owner) && player != owner)
                    skill_list.insert(owner, QStringList(objectName()));
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (room->askForChoice(player, "tongdu", "yes+no", data, "@tongdu:" + ask_who->objectName()) == "yes") {
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << ask_who;
            log.arg = "tongdu";
            room->sendLog(log);
            room->broadcastSkillInvoke("tongdu", ask_who);
            room->notifySkillInvoked(ask_who, "tongdu");
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(qMin(player->getMark("GlobalRuleDisCardCount"), 3), objectName());
        return false;
    }
};

QingyinCard::QingyinCard()
{
    mute = true;
    target_fixed = true;
}

void QingyinCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    room->setPlayerMark(source, "@qingyin", 0);
    room->broadcastSkillInvoke("qingyin", source);
    room->doSuperLightbox("liuba", "qingyin");

    CardUseStruct use = card_use;
    QList<ServerPlayer *> all_players = room->getAlivePlayers();

    foreach (ServerPlayer *p, all_players) {
        if (source->willBeFriendWith(p))
            use.to << p;
    }

    SkillCard::onUse(room, use);
}

void QingyinCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach (ServerPlayer *p, targets) {
        if (p->isAlive() && p->isWounded()) {
            RecoverStruct recover;
            recover.recover = p->getMaxHp()- p->getHp();
            recover.who = source;
            room->recover(p, recover);
        }
    }

    if (source->inHeadSkills("qingyin"))
        source->removeGeneral();
    else if (source->inDeputySkills("qingyin"))
        source->removeGeneral(false);
}

class Qingyin : public ZeroCardViewAsSkill
{
public:
    Qingyin() : ZeroCardViewAsSkill("qingyin")
    {

        frequency = Limited;
        limit_mark = "@qingyin";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark(limit_mark) > 0;
    }

    virtual const Card *viewAs() const
    {
        QingyinCard *card = new QingyinCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Juejue : public PhaseChangeSkill
{
public:
    Juejue() : PhaseChangeSkill("juejue")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Discard && player->getHp() > 0) return QStringList(objectName());
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
        room->loseHp(player);
        room->setPlayerFlag(player, "juejueInvoked");

        return false;
    }
};

class JuejueDiscard : public ViewAsSkill
{
public:
    JuejueDiscard() : ViewAsSkill("juejue_discard")
    {
        response_pattern = "@@juejue_discard";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !to_select->isEquipped() && selected.length() < Self->getMark("juejue_discard_count");
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != Self->getMark("juejue_discard_count")) return NULL;

        DummyCard *discard = new DummyCard;
        discard->addSubcards(cards);
        return discard;
    }
};

class JuejueEffect : public TriggerSkill
{
public:
    JuejueEffect() : TriggerSkill("#juejue-effect")
    {
        events << EventPhaseEnd;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (player->getPhase() == Player::Discard && player->hasFlag("juejueInvoked") && player->getMark("GlobalRuleDisCardCount") > 0)
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        int x = player->getMark("GlobalRuleDisCardCount");
        QList<ServerPlayer *> all_players = room->getOtherPlayers(player);
        foreach (ServerPlayer *p, all_players) {
            room->setPlayerMark(p, "juejue_discard_count", x);
            QString prompt = "@juejue-discard:"+player->objectName()+"::"+QString::number(x);
            const Card *card = room->askForCard(p, "@@juejue_discard", prompt, QVariant(), Card::MethodNone);
            room->setPlayerMark(p, "juejue_discard_count", 0);

            if (card) {
                CardMoveReason reason(CardMoveReason::S_REASON_PUT, p->objectName(), "juejue", QString());
                room->throwCard(card, reason, NULL);
            } else
                room->damage(DamageStruct("juejue", player, p));
        }

        return false;
    }
};

FangyuanSummon::FangyuanSummon()
    : ArraySummonCard("fangyuan")
{
    mute = true;
}

class Fangyuan : public BattleArraySkill
{
public:
    Fangyuan() : BattleArraySkill("fangyuan", HegemonyMode::Siege)
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (BattleArraySkill::triggerable(player) && player->getPhase() == Player::Finish) {
            QList<ServerPlayer *> all_players = room->getAlivePlayers();
            foreach (ServerPlayer *p, all_players) {
                if (p->inSiegeRelation(p, player) && player->canSlash(p, false))
                    return QStringList(objectName());
            }
        }
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> targets, all_players = room->getAlivePlayers();
        foreach (ServerPlayer *p, all_players) {
            if (p->inSiegeRelation(p, player) && player->canSlash(p, false))
                targets << p;
        }
        if (!targets.isEmpty()) {
            ServerPlayer *target = room->askForPlayerChosen(player, targets, "_fangyuan", "@fangyuan-slash");
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_fangyuan");
            room->useCard(CardUseStruct(slash, player, target), false);
        }
        return false;
    }
};

class FangyuanMaxCards : public MaxCardsSkill
{
public:
    FangyuanMaxCards() : MaxCardsSkill("#fangyuan-maxcards")
    {
    }

    virtual int getExtra(const Player *target) const
    {
        int x = 0;

        QList<const Player *> to_count, siblings = target->getAliveSiblings();

        if (!target->hasShownOneGeneral() || target->isRemoved() || siblings.length() < 3 || target->aliveCount(false) < 3) return 0;

        Player *p1 = target->getNextAlive();
        Player *p2 = target->getLastAlive();
        Player *p3 = target->getNextAlive(2);
        Player *p4 = target->getLastAlive(2);

        if (target->aliveCount(false) > 3) {

            if (p1 && p2 && p1->isFriendWith(p2) && !p1->isFriendWith(target)) {
                if (p1->hasShownSkill("fangyuan")) x--;
                if (p2->hasShownSkill("fangyuan")) x--;
            }

            if (p1 && p3 && target->isFriendWith(p3) && !target->isFriendWith(p1) && p1->hasShownOneGeneral()) {
                if (target->hasShownSkill("fangyuan") && !to_count.contains(target))
                    to_count << target;
                if (p3->hasShownSkill("fangyuan") && !to_count.contains(p3))
                    to_count << p3;
            }
            if (p2 && p4 && target->isFriendWith(p4) && !target->isFriendWith(p2) && p2->hasShownOneGeneral()) {
                if (target->hasShownSkill("fangyuan") && !to_count.contains(target))
                    to_count << target;
                if (p4->hasShownSkill("fangyuan") && !to_count.contains(p4))
                    to_count << p4;
            }
        }
        return to_count.length() + x;
    }
};

TonglingCard::TonglingCard()
{

}

bool TonglingCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *mutable_card = Sanguosha->getCard(getEffectiveId());
    if (targets.isEmpty() && to_select->objectName() != Self->property("tongling_usetarget").toString())
        return false;
    return mutable_card && mutable_card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, mutable_card, targets);
}

bool TonglingCard::targetFixed() const
{
    const Card *mutable_card = Sanguosha->getCard(getEffectiveId());
    return mutable_card && mutable_card->targetFixed();
}

bool TonglingCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    const Card *mutable_card = Sanguosha->getCard(getEffectiveId());
    return mutable_card && mutable_card->targetsFeasible(targets, Self);
}

void TonglingCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;

    const Card *tongling_card = Sanguosha->getCard(getEffectiveId());

    const Card *use_card = Card::Parse(tongling_card->toString());

    if (use_card->isAvailable(source)) {

        room->useCard(CardUseStruct(use_card, source, card_use.to), false);

        DamageStruct damage = source->tag["tongling-damage"].value<DamageStruct>();
        if (use_card->tag["GlobalCardDamagedTag"].isNull()) {

            if (damage.to && damage.card) {
                QList<int> table_cardids = room->getCardIdsOnTable(damage.card);
                if (table_cardids.length() == damage.card->subcardsLength())
                    damage.to->obtainCard(damage.card);
            }
        } else {
            if (damage.from && damage.from != source)
                damage.from->drawCards(2, "tongling");

            source->drawCards(2, "tongling");
        }
    }
}



class TonglingUseCard : public OneCardViewAsSkill
{
public:
    TonglingUseCard() : OneCardViewAsSkill("tongling_usecard")
    {
        response_pattern = "@@tongling_usecard";
        response_or_use = true;
    }

    virtual bool viewFilter(const Card *to_select) const
    {
        if (to_select->isAvailable(Self) && !to_select->isEquipped()) {
            QString target_name = Self->property("tongling_usetarget").toString();

            const Player *target = NULL;

            foreach (const Player *p, Self->getAliveSiblings()) {
                if (p->objectName() == target_name) {
                    target = p;
                    break;
                }
            }

            if (target == NULL || !to_select->targetRated(target, Self) || Self->isProhibited(target, to_select)) return false;
            if (to_select->targetFixed() && !to_select->isKindOf("AOE") && !to_select->isKindOf("GlobalEffect")) return false;
            return true;
        }
        return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        TonglingCard *tongling_card = new TonglingCard;
        tongling_card->addSubcard(originalCard->getId());
        return tongling_card;
    }
};

class Tongling : public TriggerSkill
{
public:
    Tongling() : TriggerSkill("tongling")
    {
        events << Damage << EventPhaseChanging;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging && data.value<PhaseChangeStruct>().from == Player::Play) {
            room->setPlayerFlag(player, "-tonglingUsed");
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent != Damage) return QStringList();
        if (!TriggerSkill::triggerable(player) || !player->hasShownOneGeneral()) return QStringList();
        if (player->getPhase() != Player::Play || player->hasFlag("tonglingUsed")) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->isAlive() && !player->isFriendWith(damage.to) && damage.to->hasShownOneGeneral()) {
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        QList<ServerPlayer *> to_choose, all_players = room->getAlivePlayers();
        foreach (ServerPlayer *p, all_players) {
            if (player->isFriendWith(p))
                to_choose << p;
        }
        if (to_choose.isEmpty()) return false;

        ServerPlayer *to = room->askForPlayerChosen(player, to_choose, objectName(),
                "@tongling-invoke::" + damage.to->objectName(), true, true);
        if (to != NULL) {
            room->broadcastSkillInvoke(objectName(), player);
            player->setFlags("tonglingUsed");

            QStringList target_list = player->tag["tongling_target"].toStringList();
            target_list.append(to->objectName());
            player->tag["tongling_target"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *source, QVariant &data, ServerPlayer *) const
    {
        QStringList target_list = source->tag["tongling_target"].toStringList();
        QString target_name = target_list.takeLast();
        source->tag["tongling_target"] = target_list;

        ServerPlayer *to = room->findPlayerbyobjectName(target_name);
        if (to) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to && damage.to->isAlive()) {
                room->setPlayerProperty(to, "tongling_usetarget", damage.to->objectName());
                to->tag["tongling-damage"] = data;
                room->askForUseCard(to, "@@tongling_usecard", "@tongling-usecard::" + damage.to->objectName(), -1, Card::MethodUse, false);

            }
        }
        return false;
    }
};

class Jinxian : public TriggerSkill
{
public:
    Jinxian() : TriggerSkill("jinxian")
    {

    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

class JinxianCompulsory : public TriggerSkill
{
public:
    JinxianCompulsory() : TriggerSkill("#jinxian-compulsory")
    {
        events << GeneralShowed;
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player->cheakSkillLocation("jinxian", data))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, "jinxian");
        room->broadcastSkillInvoke("jinxian", player);
        return true;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> targets, allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (player->distanceTo(p) == 0 || player->distanceTo(p) == 1) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                targets << p;
            }
        }
        room->sortByActionOrder(targets);
        foreach (ServerPlayer *p, targets) {
            if (p->isAlive()) {
                if (p->hasShownAllGenerals()) {

                    QStringList generals, allchoices;
                    allchoices << "head" << "deputy";
                    if (!p->getActualGeneral1Name().contains("sujiang") && !p->isLord())
                        generals << "head";

                    if (p->getGeneral2() != NULL && !p->getGeneral2Name().contains("sujiang"))
                        generals << "deputy";

                    if (generals.isEmpty()) continue;

                    QString choice = room->askForChoice(p, "jinxian_hide", generals.join("+"), QVariant(),
                                                        "@jinxian-hide", allchoices.join("+"));
                    bool head = (choice == "head");

                    p->hideGeneral(head);
                } else
                    room->askForDiscard(p, "jinxian_discard", 2, 2, false, true);
            }
        }

        return false;
    }
};

class Qiance : public TriggerSkill
{
public:
    Qiance() : TriggerSkill("qiance")
    {
        events << TargetChosen;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card != NULL && use.card->isNDTrick() && use.index == 0) {
            foreach (ServerPlayer *p, use.to) {
                if (p->isBigKingdomPlayer())
                    return QStringList(objectName());
            }
        }
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

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();

        foreach (ServerPlayer *p, use.to) {
            if (p->isBigKingdomPlayer())
                use.disresponsive_list << p->objectName();
        }

        data = QVariant::fromValue(use);
        return false;
    }
};

class QianceOther : public TriggerSkill
{
public:
    QianceOther() : TriggerSkill("#qiance-other")
    {
        events << TargetChosen;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card != NULL && use.card->isNDTrick() && use.index == 0) {
            foreach (ServerPlayer *p, use.to) {
                if (p->isBigKingdomPlayer()) {
                    QList<ServerPlayer *> xushus = room->findPlayersBySkillName("qiance");
                    foreach (ServerPlayer *xushu, xushus) {
                        if (xushu->hasShownSkill("qiance") && xushu != player && xushu->isFriendWith(player))
                            skill_list.insert(xushu, QStringList(objectName()));
                    }
                    return skill_list;
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (room->askForChoice(player, "qiance", "yes+no", data, "@qiance:" + ask_who->objectName()) == "yes") {
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << ask_who;
            log.arg = "qiance";
            room->sendLog(log);
            room->broadcastSkillInvoke("qiance", ask_who);
            room->notifySkillInvoked(ask_who, "qiance");

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        foreach (ServerPlayer *p, use.to) {
            if (p->isBigKingdomPlayer())
                use.disresponsive_list << p->objectName();
        }
        data = QVariant::fromValue(use);
        return false;
    }
};

class Jujian : public TriggerSkill
{
public:
    Jujian() : TriggerSkill("jujian")
    {
        events << Dying;
        relate_to_place = "deputy";
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who && dying.who->getHp() < 1 && dying.who->isFriendWith(player))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who && dying.who->isAlive() && player->askForSkillInvoke(this, QVariant::fromValue(dying.who))) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), dying.who->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who && dying.who->isAlive() && dying.who->getHp() < 1) {
            RecoverStruct recover;
            recover.recover = 1 - dying.who->getHp();
            recover.who = player;
            room->recover(dying.who, recover);
        }
        if (player->canTransform())
            room->transformDeputyGeneral(player);
        return false;
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

    General *zhanglu = new General(this, "zhanglu", "qun", 3);
    zhanglu->addSkill(new Bushi);
    zhanglu->addSkill(new BushiCompulsory);
    insertRelatedSkills("bushi", "#bushi-compulsory");
    zhanglu->addSkill(new Midao);
    zhanglu->addSkill(new DetachEffectSkill("midao", "rice"));
    insertRelatedSkills("midao", "#midao-clear");
    zhanglu->setSubordinateKingdom("wei");

    General *shixie = new General(this, "shixie", "wu", 3);
    shixie->addSkill(new Biluan);
    shixie->addSkill(new Lixia);
    shixie->setSubordinateKingdom("qun");

    General *tangzi = new General(this, "tangzi", "wei");
    tangzi->addSkill(new Xingzhao);
    tangzi->addSkill(new XingzhaoVH);
    insertRelatedSkills("xingzhao", "#xingzhao-viewhas");
    tangzi->addRelateSkill("xunxun_tangzi");
    tangzi->setSubordinateKingdom("wu");

    General *dongzhao = new General(this, "dongzhao", "wei", 3);
    dongzhao->addSkill(new Quanjin);
    dongzhao->addSkill(new Zaoyun);

    General *xushu = new General(this, "xushu", "shu");
    xushu->addSkill(new Qiance);
    xushu->addSkill(new QianceOther);
    xushu->addSkill(new Jujian);
    insertRelatedSkills("qiance", "#qiance-other");
    xushu->setDeputyMaxHpAdjustedValue(-1);
    xushu->addCompanion("wolong");
    xushu->addCompanion("zhaoyun");

    General *wujing = new General(this, "wujing", "wu");
    wujing->addSkill(new Diaogui);
    wujing->addSkill(new Fengyang);

    General *yanbaihu = new General(this, "yanbaihu", "qun");
    yanbaihu->addSkill(new Zhidao);
    yanbaihu->addSkill(new ZhidaoDamage);
    yanbaihu->addSkill(new ZhidaoProhibit);
    insertRelatedSkills("zhidao", 2, "#zhidao-damage", "#zhidao-prohibit");
    yanbaihu->addSkill(new JiliX);
    yanbaihu->addSkill(new JiliXDecrease);
    insertRelatedSkills("jilix", "#jilix-decrease");

    General *xiahouba = new General(this, "xiahouba", "shu");
    xiahouba->addSkill(new Baolie);
    xiahouba->addSkill(new BaolieTargetMod);
    insertRelatedSkills("baolie", "#baolie-target");
    xiahouba->setSubordinateKingdom("wei");
    xiahouba->addCompanion("jiangwei");

    General *panjun = new General(this, "panjun", "shu", 3);
    panjun->addSkill(new Congcha);
    panjun->addSkill(new CongchaEffect);
    insertRelatedSkills("congcha", "#congcha-effect");
    panjun->addSkill(new Gongqing);
    panjun->addSkill(new GongqingDecrease);
    insertRelatedSkills("gongqing", "#gongqing-decrease");
    panjun->setSubordinateKingdom("wu");

    General *pengyang = new General(this, "pengyang", "shu", 3);
    pengyang->setSubordinateKingdom("qun");
    pengyang->addSkill(new Tongling);
    pengyang->addSkill(new Jinxian);
    pengyang->addSkill(new JinxianCompulsory);
    insertRelatedSkills("jinxian", "#jinxian-compulsory");

    General *xuyou = new General(this, "xuyou", "qun", 3);
    xuyou->addSkill(new Chenglve);
    xuyou->addSkill(new Shicai);
    xuyou->setSubordinateKingdom("wei");

    General *sufei = new General(this, "sufei", "wu");
    sufei->setSubordinateKingdom("qun");
    sufei->addSkill(new Lianpian);
    sufei->addSkill(new LianpianOther);
    insertRelatedSkills("lianpian", "#lianpian-other");
    sufei->addCompanion("ganning");

    General *wenqin = new General(this, "wenqin", "wei");
    wenqin->addSkill(new Jinfa);
    wenqin->setSubordinateKingdom("wu");

    General *zhuling = new General(this, "zhuling", "wei");
    zhuling->addSkill(new Juejue);
    zhuling->addSkill(new JuejueEffect);
    insertRelatedSkills("juejue", "#juejue-effect");
    zhuling->addSkill(new Fangyuan);
    zhuling->addSkill(new FangyuanMaxCards);
    insertRelatedSkills("fangyuan", "#fangyuan-maxcards");

    General *liuba = new General(this, "liuba", "shu", 3);
    liuba->addSkill(new Tongdu);
    liuba->addSkill(new TongduOther);
    insertRelatedSkills("tongdu", "#tongdu-other");
    liuba->addSkill(new Qingyin);

    General *zhugeke = new General(this, "zhugeke", "wu", 3);
    zhugeke->addSkill(new Aocai);
    zhugeke->addSkill(new Duwu);
    zhugeke->addCompanion("dingfeng");

    General *huangzu = new General(this, "huangzu", "qun");
    huangzu->addSkill(new Xishe);
    huangzu->addSkill(new XisheTransform);
    insertRelatedSkills("xishe", "#xishe-transform");

    General *simazhao = new General(this, "simazhao", "careerist", 3);
    simazhao->addSkill(new Suzhi);
    simazhao->addSkill(new SuzhiTarget);
    insertRelatedSkills("suzhi", "#suzhi-target");
    simazhao->addSkill(new Zhaoxin);
    simazhao->addCompanion("simayi");
    simazhao->addRelateSkill("fankui_simazhao");

    General *zhonghui = new General(this, "zhonghui", "careerist");
    zhonghui->addSkill(new Quanji);
    zhonghui->addSkill(new QuanjiMaxCards);
    zhonghui->addSkill(new DetachEffectSkill("quanji", "power_pile"));
    zhonghui->addSkill(new Paiyi);
    insertRelatedSkills("quanji", 2, "#quanji-maxcards", "#quanji-clear");
    zhonghui->addCompanion("jiangwei");

    General *sunchen = new General(this, "sunchen", "careerist");
    sunchen->addSkill(new Shilu);
    sunchen->addSkill(new DetachEffectSkill("shilu", "massacre"));
    sunchen->addSkill(new Xiongnve);
    sunchen->addSkill(new XiongnveEffect);
    sunchen->addSkill(new XiongnveTarget);
    insertRelatedSkills("shilu", "#shilu-clear");
    insertRelatedSkills("xiongnve", 2, "#xiongnve-effect", "#xiongnve-target");

    General *gongsunyuan = new General(this, "gongsunyuan", "careerist");
    gongsunyuan->addSkill(new Huaiyi);
    sunchen->addSkill(new DetachEffectSkill("huaiyi", "&disloyalty"));
    gongsunyuan->addSkill(new Zisui);
    insertRelatedSkills("huaiyi", "#huaiyi-clear");

    addMetaObject<PaiyiCard>();
    addMetaObject<QuanjinCard>();
    addMetaObject<ZaoyunCard>();
    addMetaObject<DiaoguiCard>();
    addMetaObject<FengyangSummon>();
    addMetaObject<AocaiCard>();
    addMetaObject<DuwuCard>();
    addMetaObject<JinfaCard>();
    addMetaObject<HuaiyiCard>();

    addMetaObject<QingyinCard>();
    addMetaObject<FangyuanSummon>();
    addMetaObject<TonglingCard>();

    skills << new Xunxun("_tangzi") << new Fankui("_simazhao") << new AocaiVeiw << new JuejueDiscard << new TonglingUseCard;
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
