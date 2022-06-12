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

#include "gamerule.h"
#include "serverplayer.h"
#include "room.h"
#include "standard.h"
#include "engine.h"
#include "settings.h"
#include "json.h"
#include "roomthread.h"
#include <QFile>
#include <QTime>

class GameRule_AskForArraySummon : public TriggerSkill
{
public:
    GameRule_AskForArraySummon() : TriggerSkill("GameRule_AskForArraySummon")
    {
        events << EventPhaseStart;
        global = true;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        foreach (const Skill *skill, player->getVisibleSkillList()) {
            if (!skill->inherits("BattleArraySkill")) continue;
            const BattleArraySkill *baskill = qobject_cast<const BattleArraySkill *>(skill);
            if (!player->askForSkillInvoke(objectName())) return false;
            player->showGeneral(player->inHeadSkills(skill->objectName()));
            baskill->summonFriends(player);
            break;
        }
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (player->getPhase() != Player::Start) return QStringList();
        if (room->getAlivePlayers().length() < 4) return QStringList();
        foreach (const Skill *skill, player->getVisibleSkillList()) {
            if (!skill->inherits("BattleArraySkill")) continue;
            return (qobject_cast<const BattleArraySkill *>(skill)->getViewAsSkill()->isEnabledAtPlay(player)) ? QStringList(objectName()) : QStringList();
        }
        return QStringList();
    }
};

class GameRule_LordConvertion : public TriggerSkill
{
public:
    GameRule_LordConvertion() : TriggerSkill("GameRule_LordConvertion")
    {
        events << GameStart;
        global = true;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList trigger_map;

        if (!Config.value("EnableLordConvertion", true).toBool())
            return trigger_map;

        if (player == NULL) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getActualGeneral1() != NULL) {
                    QString lord = "lord_" + p->getActualGeneral1()->objectName();
                    bool check = true;
                    foreach (ServerPlayer *p2, room->getOtherPlayers(p)) {                                 //no duplicate lord
                        if (p != p2 && lord == "lord_" + p2->getActualGeneral1()->objectName()) {
                            check = false;
                            break;
                        }
                    }
                    const General *lord_general = Sanguosha->getGeneral(lord);
                    if (check && lord_general && !Sanguosha->getBanPackages().contains(lord_general->getPackage()))
                        trigger_map.insert(p, QStringList(objectName()));
                }
            }
        }

        return trigger_map;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        return ask_who->askForSkillInvoke("userdefine:changetolord", "GameStart");
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        ask_who->changeToLord();
        return false;
    }
};

GameRule::GameRule(QObject *parent)
    : TriggerSkill("game_rule")
{
    setParent(parent);

    events << GameStart << TurnStart
        << EventPhaseStart << EventPhaseProceeding << EventPhaseEnd << EventPhaseChanging
        << PreCardUsed << CardUsed << CardFinished << CardEffected
        << PostHpReduced
        << EventLoseSkill << EventAcquireSkill
        << AskForPeaches << AskForPeachesDone << BuryVictim
        << BeforeGameOverJudge << GameOverJudge
        << SlashHit << SlashEffected << SlashProceed
        << ConfirmDamage << DamageDone << DamageComplete
        << StartJudge << FinishRetrial << FinishJudge
        << ChoiceMade << GeneralShown << DFDebut
        << BeforeCardsMove << CardsMoveOneTime;

    QList<Skill *> list;
    //list << new GameRule_AskForArraySummon;
    //list << new GameRule_LordConvertion;

    QList<const Skill *> list_copy;
    foreach (Skill *s, list) {
        if (Sanguosha->getSkill(s->objectName())) {
            delete s;
        } else {
            list_copy << s;
        }
    }
    Sanguosha->addSkills(list_copy);
}

QStringList GameRule::triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &ask_who) const
{
    ask_who = NULL;
    return QStringList(objectName());
}

int GameRule::getPriority() const
{
    return 0;
}

void GameRule::onPhaseProceed(ServerPlayer *player) const
{
    Room *room = player->getRoom();
    switch (player->getPhase()) {
    case Player::PhaseNone: {
        Q_ASSERT(false);
    }
    case Player::RoundStart:{
        //ask for show general(s)
        bool change = (player->getMark("HaventShowGeneral") > 0 && player->getMark("Global_RoundCount") == 1);
        player->askForGeneralShow("GameRule_AskForGeneralShow", true, true, true, true, change);
        break;
    }
    case Player::Start: {
        break;
    }
    case Player::Judge: {
        QList<const Card *> tricks = player->getJudgingArea();
        while (!tricks.isEmpty() && player->isAlive()) {
            const Card *trick = tricks.takeLast();
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_MOVE, player->objectName(), trick->objectName(), QString());
            room->moveCardTo(trick, NULL, Player::PlaceTable, reason, true);
            bool on_effect = room->cardEffect(trick, NULL, player);
            if (!on_effect)
                trick->onNullified(player);
        }
        break;
    }
    case Player::Draw: {
        QVariant qnum;
        int num = 2+player->getMark("JieyueExtraDraw")*3;
        if (player->hasFlag("Global_FirstRound")) {
            room->setPlayerFlag(player, "-Global_FirstRound");
        }

        qnum = num;
        Q_ASSERT(room->getThread() != NULL);
        room->getThread()->trigger(DrawNCards, room, player, qnum);
        num = qnum.toInt();
        if (num > 0)
            player->drawCards(num);
        qnum = num;
        room->getThread()->trigger(AfterDrawNCards, room, player, qnum);
        break;
    }
    case Player::Play: {
        while (player->isAlive()) {
            CardUseStruct card_use;
            room->activate(player, card_use);
            if (card_use.card != NULL)
                room->useCard(card_use);
            else
                break;
        }
        break;
    }
    case Player::Discard: {
        if (player->getHandcardNum() > player->getMaxCards() && player->getMark("@halfmaxhp") > 0) {
            if (room->askForChoice(player, "halfmaxhp", "yes+no", QVariant(), "@halfmaxhp-use") == "yes") {
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = "halfmaxhp";
                room->sendLog(log);
                room->broadcastSkillInvoke("halfmaxhp", player);
                room->notifySkillInvoked(player, "halfmaxhp");
                room->removePlayerMark(player, "@halfmaxhp");
                room->addPlayerMark(player, "Global_MaxcardsIncrease", 2);
            }
        }
        if (player->getHandcardNum() > player->getMaxCards() && player->getMark("@careerist") > 0) {
            if (room->askForChoice(player, "careerman", "yes+no", QVariant(), "@careerman-use") == "yes") {
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = player;
                log.arg = "careerman";
                room->sendLog(log);
                room->broadcastSkillInvoke("careerman", player);
                room->notifySkillInvoked(player, "careerman");
                room->removePlayerMark(player, "@careerist");
                room->addPlayerMark(player, "Global_MaxcardsIncrease", 2);
            }
        }
        int discard_num = player->getHandcardNum() - player->getMaxCards();
        if (discard_num > 0)
            room->askForDiscard(player, "gamerule", discard_num, discard_num);
        break;
    }
    case Player::Finish: {
        break;
    }
    case Player::NotActive:{
        break;
    }
    }
}

bool GameRule::effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
{
    if (room->getTag("SkipGameRule").toBool()) {
        room->removeTag("SkipGameRule");
        return false;
    }

    // Handle global events
    if (player == NULL) {
        if (triggerEvent == GameStart) {
            if (QFile::exists("image/animate/gamestart.png"))
                room->doLightbox("$gamestart", 3500);

            if (Config.ViewNextPlayerDeputyGeneral && room->getMode() != "custom_scenario") {
                foreach (ServerPlayer *p1, room->getPlayers()) {
                    ServerPlayer *p2 = qobject_cast<ServerPlayer *>(p1->getNextAlive());
                    QStringList list = room->getTag(p2->objectName()).toStringList();
                    list.removeAt(0);
                    foreach (const QString &name, list) {
                        LogMessage log;
                        log.type = "$KnownBothViewGeneral";
                        log.from = p1;
                        log.to << p2;
                        log.arg = name;
                        log.arg2 = "deputy_general";
                        room->doNotify(p1, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
                    }
                    JsonArray arg;
                    arg << "view_next_player_deputy_general";
                    arg << JsonUtils::toJsonArray(list);
                    room->doNotify(p1, QSanProtocol::S_COMMAND_VIEW_GENERALS, arg);
                }
            }
            room->getThread()->delay(3000);

            foreach (ServerPlayer *player, room->getPlayers()) {
                Q_ASSERT(player->getGeneral() != NULL);
                /*
                if (player->getGeneral()->getKingdom() == "god" && player->getGeneralName() != "anjiang") {
                QString new_kingdom = room->askForKingdom(player);
                room->setPlayerProperty(player, "kingdom", new_kingdom);

                LogMessage log;
                log.type = "#ChooseKingdom";
                log.from = player;
                log.arg = new_kingdom;
                room->sendLog(log);
                }
                */
                foreach (const Skill *skill, player->getVisibleSkillList()) {
                    if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || player->hasLordSkill(skill->objectName()))) {
                        JsonArray arg;
                        arg << player->objectName();
                        arg << skill->getLimitMark();
                        arg << 1;
                        room->doNotify(player, QSanProtocol::S_COMMAND_SET_MARK, arg);
                        player->setMark(skill->getLimitMark(), 1);
                    }
                }
            }
            room->setTag("FirstRound", true);
            if (room->getMode() != "custom_scenario")
                room->drawCards(room->getPlayers(), 4, QString());
            if (Config.LuckCardLimitation > 0)
                room->askForLuckCard();
        }
        return false;
    }

    switch (triggerEvent) {
    case TurnStart: {
        player = room->getCurrent();
        if (room->getTag("FirstRound").toBool()) {
            room->setTag("FirstRound", false);
            room->setPlayerFlag(player, "Global_FirstRound");
        }

        LogMessage log;
        log.type = "$AppendSeparator";
        room->sendLog(log);
        room->addPlayerMark(player, "Global_TurnCount");

        JsonArray update_handcards_array;
        foreach (ServerPlayer *p, room->getPlayers()) {
            JsonArray _current;
            _current << p->objectName();
            _current << p->getHandcardNum();
            update_handcards_array << _current;
        }
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_HANDCARD_NUM, update_handcards_array);

        if (Config.BattleRoyalMode && !room->getTag("BattleRoyalMode").toBool()) {
            int player_count = Sanguosha->getPlayerCount(room->getMode()), alive_count = room->alivePlayerCount();
            QList<ServerPlayer *> alive_players = room->getAlivePlayers();
            if (alive_count < (player_count > 7 ? 5 : 4)) {
                bool enterBattleRoyalMode = true;

                for (int i = 0; i < alive_count-1; i++) {
                    ServerPlayer *p1 = alive_players.at(i);
                    if (!p1->hasShownOneGeneral()) continue;
                    for (int j = i+1; j < alive_count; j++) {
                        ServerPlayer *p2 = alive_players.at(j);
                        if (!p2->hasShownOneGeneral()) continue;
                        if (p1->isFriendWith(p2)) {
                            enterBattleRoyalMode = false;
                            break;
                        }
                    }
                    if (!enterBattleRoyalMode) break;
                }

                if (enterBattleRoyalMode)
                    room->enterBattleRoyalMode();
            }

        }

        if (!player->faceUp()) {
            room->setPlayerFlag(player, "-Global_FirstRound");
            player->turnOver();
#ifndef QT_NO_DEBUG
            if (player->isAlive() && !player->getAI() && player->askForSkillInvoke("userdefine:playNormally")) {
                room->addPlayerMark(player, "Global_RoundCount");
                player->play();
            }
#endif
        } else if (player->isAlive()) {
            room->addPlayerMark(player, "Global_RoundCount");
            player->play();
        }

        break;
    }
    case EventPhaseStart: {
        if (player->getPhase() == Player::NotActive) {
            QList<ServerPlayer *> all_players = room->getAllPlayers(true);
            foreach (ServerPlayer * p, all_players) {
                room->setPlayerFlag(p, ".");
                if (p->getMark("drank") > 0) {
                    LogMessage log;
                    log.type = "#UnsetDrankEndOfTurn";
                    log.from = p;
                    room->sendLog(log);

                    room->setPlayerMark(p, "drank", 0);
                }
                room->clearPlayerCardLimitation(p, true);

                if (p->isRemoved())
                    room->setPlayerProperty(p, "removed", false);

                //clear skills
                QVariantList turn_skills = room->getTag("TurnSkillsFor"+p->objectName()).toList();
                room->removeTag("TurnSkillsFor"+p->objectName());
                QStringList detachList;
                foreach (QVariant skill_data, turn_skills) {
                    QString skill_name = skill_data.toString();
                    if (Sanguosha->getSkill(skill_name) && p->hasSkill(skill_name, true))
                        detachList.append("-" + skill_name);
                }
                if (!detachList.isEmpty())
                    room->handleAcquireDetachSkills(p, detachList);
            }
        }
        break;
    }
    case EventPhaseProceeding: {
        onPhaseProceed(player);
        break;
    }
    case EventPhaseEnd: {
        if (player->getPhase() == Player::Play)
            room->addPlayerHistory(player, ".");
        if (player->getPhase() == Player::Finish) {
            room->addPlayerHistory(player, "Analeptic", 0);     //clear Analeptic
            foreach (ServerPlayer *p, room->getAllPlayers())
                room->setPlayerMark(p, "multi_kill_count", 0);
        }
        break;
    }
    case EventPhaseChanging: {
        room->addPlayerHistory(NULL, "pushPile");
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::NotActive) {
            if (room->getTag("ImperialOrderInvoke").toBool()) {
                room->setTag("ImperialOrderInvoke", false);
                LogMessage log;
                log.type = "#ImperialOrderEffect";
                log.from = player;
                log.arg = "imperial_order";
                room->sendLog(log);
                const Card *io = room->getTag("ImperialOrderCard").value<const Card *>();
                if (io) {
                    foreach (ServerPlayer *p, room->getAllPlayers()) {
                        if (!p->hasShownOneGeneral()) {
                            CardEffectStruct effect;
                            effect.card = io;
                            effect.from = NULL;
                            effect.to = p;
                            effect.multiple = false;
                            io->onEffect(effect);
                        }
                    }
                    Card *ic = NULL;
                    Package *package = PackageAdder::packages()["LordEXCard"];
                    if (package) {
                        QList<Card *> all_cards = package->findChildren<Card *>();
                        foreach (Card *card, all_cards) {
                            if (card->objectName() =="ImperialEdict" && !room->canFindCardPlace(card->getEffectiveId())) {
                                ic = card;
                                break;
                            }
                        }
                    }
                    if (ic != NULL) {
                        LogMessage log;
                        log.type = "$AddCard";
                        log.card_str = QString::number(ic->getEffectiveId());
                        room->sendLog(log);

                        room->setCardMapping(ic->getEffectiveId(), NULL, Player::PlaceTable);
                        room->moveCardTo(ic, NULL, Player::DrawPileBottom, true);
                    }
                }
            }
        } else if (change.to == Player::Play) {
            room->addPlayerHistory(player, ".");
        } else if (change.to == Player::Start) {
            room->addPlayerHistory(player, "Analeptic", 0);         //clear Analeptic
        }
        break;
    }
    case PreCardUsed: {
        if (data.canConvert<CardUseStruct>()) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            room->setPlayerFlag(card_use.from, "HuanshenSkillChecking");
            if (card_use.from->hasFlag("Global_ForbidSurrender")) {
                card_use.from->setFlags("-Global_ForbidSurrender");
                room->doNotify(card_use.from, QSanProtocol::S_COMMAND_ENABLE_SURRENDER, true);
            }

            QStringList system_skills;
            system_skills << "companion" << "halfmaxhp" << "firstshow" << "showhead" << "showdeputy" << "transfer" << "careerman";

            if (card_use.card->getTypeId() != Card::TypeEquip)
                card_use.from->broadcastSkillInvoke(card_use.card);
            if (!card_use.card->getSkillName().isNull() && card_use.card->getSkillName(true) == card_use.card->getSkillName(false)
                && card_use.m_isOwnerUse && (card_use.from->hasSkill(card_use.card->getSkillName()) || system_skills.contains(card_use.card->getSkillName())))
                room->notifySkillInvoked(card_use.from, card_use.card->getSkillName());
            room->setPlayerFlag(card_use.from, "-HuanshenSkillChecking");
        }
        break;
    }
    case CardUsed: {
        if (data.canConvert<CardUseStruct>()) {
            CardUseStruct card_use = data.value<CardUseStruct>();
            RoomThread *thread = room->getThread();

            if (card_use.card->hasPreAction())
                card_use.card->doPreAction(room, card_use);

            QList<ServerPlayer *> targets = card_use.to;

            if (card_use.from && !targets.isEmpty()) {
                thread->trigger(TargetChoosing, room, card_use.from, data);
                card_use = data.value<CardUseStruct>();
                targets = card_use.to;
                QList<ServerPlayer *> targets_copy = targets;
                foreach (ServerPlayer *to, targets_copy) {
                    if (targets.contains(to)) {
                        thread->trigger(TargetConfirming, room, to, data);
                        CardUseStruct new_use = data.value<CardUseStruct>();
                        targets = new_use.to;
                        if (targets.isEmpty()) break;
                    }
                }
            }
            card_use = data.value<CardUseStruct>();

            try {
                QVariantList jink_list_backup;
                if (card_use.card->isKindOf("Slash")) {
                    jink_list_backup = card_use.from->tag["Jink_" + card_use.card->toString()].toList();
                    QVariantList jink_list;
                    for (int i = 0; i < card_use.to.length(); i++)
                        jink_list.append(QVariant(1));
                    card_use.from->tag["Jink_" + card_use.card->toString()] = QVariant::fromValue(jink_list);
                }
                if (card_use.from && !card_use.to.isEmpty()) {
                    thread->trigger(TargetChosen, room, card_use.from, data);
                    foreach(ServerPlayer *p, room->getAllPlayers())
                        thread->trigger(TargetConfirmed, room, p, data);
                }
                card_use = data.value<CardUseStruct>();
                room->setTag("CardUseNullifiedList", QVariant::fromValue(card_use.nullified_list));
                card_use.card->use(room, card_use.from, card_use.to);
                if (!jink_list_backup.isEmpty())
                    card_use.from->tag["Jink_" + card_use.card->toString()] = QVariant::fromValue(jink_list_backup);
            }
            catch (TriggerEvent triggerEvent) {
                if (triggerEvent == TurnBroken || triggerEvent == StageChange)
                    card_use.from->tag.remove("Jink_" + card_use.card->toString());
                throw triggerEvent;
            }
        }

        break;
    }
    case CardFinished: {
        CardUseStruct use = data.value<CardUseStruct>();
        room->clearCardFlag(use.card);

        if (use.card->isNDTrick())
            room->removeTag(use.card->toString() + "HegNullificationTargets");

        foreach(ServerPlayer *p, room->getAlivePlayers())
            room->doNotify(p, QSanProtocol::S_COMMAND_NULLIFICATION_ASKED, QString("."));
        if (use.card->isKindOf("Slash"))
            use.from->tag.remove("Jink_" + use.card->toString());

        break;
    }
    case EventAcquireSkill:
    case EventLoseSkill: {
        QString skill_name = data.toString().split(":").first();
        const Skill *skill = Sanguosha->getSkill(skill_name);

        if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty()
                && !player->ownSkill(skill_name)) {
            room->setPlayerMark(player, skill->getLimitMark(), 0);
        }

        bool refilter = skill->inherits("FilterSkill");

        if (!refilter && skill->inherits("TriggerSkill")) {
            const TriggerSkill *trigger = qobject_cast<const TriggerSkill *>(skill);
            const ViewAsSkill *vsskill = trigger->getViewAsSkill();
            if (vsskill && vsskill->inherits("FilterSkill"))
                refilter = true;
        }

        if (refilter)
            room->filterCards(player, player->getCards("he"), triggerEvent == EventLoseSkill);

        break;
    }
    case PostHpReduced: {
        if (player->getHp() > 0 || player->hasFlag("Global_Dying")) // newest GameRule -- a player cannot enter dying when it is dying.
            break;
        if (data.canConvert<DamageStruct>()) {
            DamageStruct damage = data.value<DamageStruct>();
            room->enterDying(player, &damage);
        } else
            room->enterDying(player, NULL);

        break;
    }
    case AskForPeaches: {
        DyingStruct dying = data.value<DyingStruct>();
        const Card *peach = NULL;

        ServerPlayer *jiaxu = room->getCurrent();
        if (jiaxu->hasShownSkill("wansha") && jiaxu->isAlive() && jiaxu->getPhase() != Player::NotActive) {
            if (player != dying.who && player != jiaxu)
                break;
        }

        const Card *cheak_peach = Sanguosha->cloneCard("peach", Card::NoSuit, 0);

        if (player->isProhibited(dying.who, cheak_peach) || player->isLocked(cheak_peach)) break;

        while (dying.who->getHp() <= 0) {
            peach = NULL;
            if (dying.who->isAlive())
                peach = room->askForSinglePeach(player, dying.who);
            if (peach == NULL)
                break;
            //room->useCard(CardUseStruct(peach, player, dying.who), false);
        }

        break;
    }
    case AskForPeachesDone: {
        if (player->getHp() <= 0 && player->isAlive()) {
#ifndef QT_NO_DEBUG
            if (!player->getAI() && player->askForSkillInvoke("userdefine:revive")) {
                room->setPlayerProperty(player, "hp", player->getMaxHp());
                break;
            }
#endif
            DyingStruct dying = data.value<DyingStruct>();
            room->killPlayer(player, dying.damage);
        }

        break;
    }
    case ConfirmDamage: {
//        DamageStruct damage = data.value<DamageStruct>();
//        if (damage.card && damage.to->getMark("SlashIsDrank") > 0) {
//            LogMessage log;
//            log.type = "#AnalepticBuff";
//            log.from = damage.from;
//            log.to << damage.to;
//            log.arg = QString::number(damage.damage);

//            damage.damage += damage.to->getMark("SlashIsDrank");
//            damage.to->setMark("SlashIsDrank", 0);

//            log.arg2 = QString::number(damage.damage);

//            room->sendLog(log);

//            data = QVariant::fromValue(damage);
//        }

        break;
    }
    case DamageDone: {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && !damage.from->isAlive())
            damage.from = NULL;
        data = QVariant::fromValue(damage);
        room->sendDamageLog(damage);

        room->applyDamage(player, damage);
        if (damage.nature != DamageStruct::Normal && player->isChained()) {
            room->setPlayerProperty(player, "chained", false);
            if (!damage.chain) {
                int n = room->getTag("is_chained").toInt();
                n++;
                room->setTag("is_chained", n);
            }
        }
        room->getThread()->trigger(PostHpReduced, room, player, data);

        break;
    }
    case DamageComplete: {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.prevented) break;
        if (room->getTag("is_chained").toInt() > 0) {
            if (damage.nature != DamageStruct::Normal && !damage.chain) {
                // iron chain effect
                int n = room->getTag("is_chained").toInt();
                n--;
                room->setTag("is_chained", n);
                QList<ServerPlayer *> chained_players;
                if (room->getCurrent()->isDead())
                    chained_players = room->getOtherPlayers(room->getCurrent());
                else
                    chained_players = room->getAllPlayers();
                foreach (ServerPlayer *chained_player, chained_players) {
                    if (chained_player->isChained()) {
                        room->getThread()->delay();
                        LogMessage log;
                        log.type = "#IronChainDamage";
                        log.from = chained_player;
                        room->sendLog(log);

                        DamageStruct chain_damage = damage;
                        chain_damage.to = chained_player;
                        chain_damage.chain = true;
                        chain_damage.transfer = false;
                        chain_damage.transfer_reason = QString();
                        chain_damage.flags.clear();

                        room->damage(chain_damage);
                    }
                }
            }
        }
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->hasFlag("Global_DFDebut")) {
                p->setFlags("-Global_DFDebut");
                room->getThread()->trigger(DFDebut, room, p);
            }
        }
        break;
    }
    case CardEffected: {
        if (data.canConvert<CardEffectStruct>()) {
            CardEffectStruct effect = data.value<CardEffectStruct>();
            if (!effect.card->isKindOf("Slash") && effect.nullified) {
                LogMessage log;
                log.type = "#CardNullified";
                log.from = effect.to;
                log.arg = effect.card->objectName();
                room->sendLog(log);

                return true;
            } else if (effect.card->getTypeId() == Card::TypeTrick && room->isCanceled(effect)) {
                effect.to->setFlags("Global_NonSkillNullify");
                return true;
            }
            QVariant _effect = QVariant::fromValue(effect);
            room->getThread()->trigger(CardEffectConfirmed, room, effect.to, _effect);
            if (effect.to->isAlive() || effect.card->isKindOf("Slash"))
                effect.card->onEffect(effect);
        }

        break;
    }
    case SlashEffected: {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        if (effect.nullified) {
            LogMessage log;
            log.type = "#CardNullified";
            log.from = effect.to;
            log.arg = effect.slash->objectName();
            room->sendLog(log);

            return true;
        }

        if (effect.jink_num > 0)
            room->getThread()->trigger(SlashProceed, room, effect.from, data);
        else
            room->slashResult(effect, NULL);
        break;
    }
    case SlashProceed: {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        QString slasher = effect.from->objectName();
        if (!effect.to->isAlive())
            break;
        if (effect.jink_num == 1) {
            const Card *jink = room->askForCard(effect.to, "jink", "slash-jink:" + slasher, data, Card::MethodUse, effect.from);
            room->slashResult(effect, room->isJinkEffected(effect.to, jink) ? jink : NULL);
        } else {
            const Card *asked_jink = NULL;
            for (int i = effect.jink_num; i > 0; i--) {
                QString prompt = QString("@multi-jink%1:%2::%3").arg(i == effect.jink_num ? "-start" : QString())
                    .arg(slasher).arg(i);
                asked_jink = room->askForCard(effect.to, "jink", prompt, data, Card::MethodUse, effect.from);
                if (!room->isJinkEffected(effect.to, asked_jink)) {
                    room->slashResult(effect, NULL);
                    return false;
                }
            }
            room->slashResult(effect, asked_jink);
        }

        break;
    }
    case SlashHit: {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        int x = effect.slash->tag["addcardinality"].toInt() + effect.drank + 1;
        QStringList AddDamage_List = effect.slash->tag["AddDamage_List"].toStringList();
        foreach (QString name, AddDamage_List) {
            if (name == effect.to->objectName()) x++;
        }
        room->damage(DamageStruct(effect.slash, effect.from, effect.to, x, effect.nature));

        break;
    }
    case BeforeGameOverJudge: {
        if (!player->hasShownGeneral1())
            player->showGeneral(true, false, false);
        if (!player->hasShownGeneral2())
            player->showGeneral(false, false, false);
        break;
    }
    case GameOverJudge: {

        QString winner = getWinner(player);
        if (!winner.isNull()) {
            room->gameOver(winner);
            return true;
        }

        break;
    }
    case BuryVictim: {
        DeathStruct death = data.value<DeathStruct>();
        player->bury();

        if (room->getTag("SkipNormalDeathProcess").toBool())
            return false;

        ServerPlayer *killer = death.damage ? death.damage->from : NULL;
        if (killer) {
            room->setPlayerMark(killer, "multi_kill_count", killer->getMark("multi_kill_count") + 1);
            int kill_count = killer->getMark("multi_kill_count");
            if (kill_count > 1 && kill_count < 8)
                room->setEmotion(killer, QString("multi_kill%1").arg(QString::number(kill_count)), false, 4000);
            else if (kill_count > 7)
                room->setEmotion(killer, "zylove", false, 4000);

            if (!killer->hasShownSkill("juejue") || !killer->isFriendWith(player))
                rewardAndPunish(killer, player);
        }

        if (player->getGeneral()->isLord() && player == data.value<DeathStruct>().who) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player, true)) {
                if (p->getKingdom() == player->getKingdom()) {
                    if (p->hasShownOneGeneral()) {
                        room->setPlayerProperty(p, "role", "careerist");
                    } else {
                        //p->setRole("careerist");
                        room->notifyProperty(p, p, "role", "careerist");
                    }
                }
            }
        }


        break;
    }
    case StartJudge: {
        int card_id = room->drawCard();

        JudgeStruct *judge_struct = data.value<JudgeStruct *>();
        judge_struct->card = Sanguosha->getCard(card_id);

        LogMessage log;
        log.type = "$InitialJudge";
        log.from = judge_struct->who;
        log.card_str = QString::number(judge_struct->card->getEffectiveId());
        room->sendLog(log);

        room->moveCardTo(judge_struct->card, NULL, judge_struct->who, Player::PlaceJudge,
            CardMoveReason(CardMoveReason::S_REASON_JUDGE, judge_struct->who->objectName(), QString(), QString(), judge_struct->reason), true);
        judge_struct->updateResult();
        break;
    }
    case FinishRetrial: {
        JudgeStruct *judge = data.value<JudgeStruct *>();

        LogMessage log;
        log.type = "$JudgeResult";
        log.from = player;
        log.card_str = QString::number(judge->card->getEffectiveId());
        room->sendLog(log);

        if(!judge->patterns.isEmpty()) {
            foreach (QString _pattern, judge->patterns) {
                if (ExpPattern(_pattern).match(player, judge->card)) {
                    judge->pattern = _pattern;
                    break;
                }
            }
        }

        if (judge->play_animation) {
            room->sendJudgeResult(judge);
            room->getThread()->delay(Config.S_JUDGE_LONG_DELAY);
        }

        break;
    }
    case FinishJudge: {
        JudgeStruct *judge = data.value<JudgeStruct *>();

        if (room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge) {
            if ((judge->reason != "luoshen") || judge->isBad()) { //special rule of luoshen
                CardMoveReason reason(CardMoveReason::S_REASON_JUDGEDONE, judge->who->objectName(), QString(), judge->reason);
                room->moveCardTo(judge->card, judge->who, NULL, Player::DiscardPile, reason, true);
            }
        }

        break;
    }
    case ChoiceMade: {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            foreach (const QString &flag, p->getFlagList()) {
                if (flag.startsWith("Global_") && flag.endsWith("Failed"))
                    room->setPlayerFlag(p, "-" + flag);
            }
        }
        break;
    }
    case GeneralShown: {
        if (!room->getTag("GlobalCareeristShow").toBool()) {
            QString winner = getWinner(player);
            if (!winner.isNull()) {
                room->gameOver(winner); // if all hasShownGenreal, and they are all friend, game over.
                return true;
            }
        }
        if (player->isAlive() && player->hasShownAllGenerals()) {
            if (player->getMark("CompanionEffect") > 0) {
                room->removePlayerMark(player, "CompanionEffect");
                room->addPlayerMark(player, "@companion");
            }
            if (player->getMark("HalfMaxHpLeft") > 0) {
                room->removePlayerMark(player, "HalfMaxHpLeft");
                room->addPlayerMark(player, "@halfmaxhp");
            }
        }
        if (player->isAlive() && data.toBool() && player->getMark("HaventShowGeneral") > 0) {
            room->removePlayerMark(player, "HaventShowGeneral");
            if (player->getGeneral()->getKingdom() == "careerist")
                room->addPlayerMark(player, "@careerist");
        }
        if (player->isAlive() && !data.toBool() && player->getMark("HaventShowGeneral2") > 0)
            room->removePlayerMark(player, "HaventShowGeneral2");

        if (Config.RewardTheFirstShowingPlayer && room->getScenario() == NULL) {
            if (room->getTag("TheFirstToShowRewarded").isNull()) {
                room->setTag("TheFirstToShowRewarded", true);
                room->addPlayerMark(player, "@firstshow");
            }
        }
        break;
    }
    case DFDebut: {

        break;
    }
    case BeforeCardsMove: {

        break;
    }
    case CardsMoveOneTime: {

        break;
    }
    default:
        break;
    }

    return false;
}

void GameRule::rewardAndPunish(ServerPlayer *killer, ServerPlayer *victim) const
{
    if (killer->isDead() || !killer->hasShownOneGeneral()) return;

    Q_ASSERT(killer->getRoom() != NULL);
    Room *room = killer->getRoom();

    if (!killer->isFriendWith(victim)) {
        if (killer->getRole() == "careerist")
            killer->drawCards(3);
        else {
            int n = 1;
            foreach (ServerPlayer *p, room->getOtherPlayers(victim)) {
                if (victim->isFriendWith(p))
                    ++n;
            }
            killer->drawCards(n);
        }
    } else
        killer->throwAllHandCardsAndEquips();
}

QString GameRule::getWinner(ServerPlayer *victim) const
{
    Room *room = victim->getRoom();
    QStringList winners;
    QList<ServerPlayer *> players = room->getAlivePlayers();
    room->sortByActionOrder(players);
    ServerPlayer *win_player = players.first();
    if (players.length() == 1) {

        if (!win_player->hasShownGeneral1())
            win_player->showGeneral(true, false, false);
        if (!win_player->hasShownGeneral2())
            win_player->showGeneral(false, false, false);

        foreach (ServerPlayer *p, room->getPlayers()) {
            if (win_player->isFriendWith(p))
                winners << p->objectName();
        }
    } else {
        bool has_diff_kingdoms = false;
        foreach (ServerPlayer *p, players) {
            foreach (ServerPlayer *p2, players) {
                if (p->hasShownOneGeneral() && p2->hasShownOneGeneral() && !p->isFriendWith(p2)) {
                    has_diff_kingdoms = true;
                    break;// if both shown but not friend, hehe.
                }
                if ((p->hasShownOneGeneral() && !p2->hasShownOneGeneral() && !p2->willBeFriendWith(p))
                    || (!p->hasShownOneGeneral() && p2->hasShownOneGeneral() && !p->willBeFriendWith(p2))) {
                    has_diff_kingdoms = true;
                    break;// if either shown but not friend, hehe.
                }
                if (!p->hasShownOneGeneral() && !p2->hasShownOneGeneral()) {
                    if (p->getActualGeneral1()->getKingdom() != p2->getActualGeneral1()->getKingdom()) {
                        has_diff_kingdoms = true;
                        break;  // if neither shown and not friend, hehe.
                    }
                }
            }
            if (has_diff_kingdoms)
                break;
        }
        if (!has_diff_kingdoms) { // judge careerist
            QMap<QString, int> kingdoms;
            QSet<QString> lords;
            foreach(ServerPlayer *p, room->getPlayers())
                if (p->isLord() || p->getActualGeneral1()->isLord())
                    if (p->isAlive())
                        lords << p->getActualGeneral1()->getKingdom();
            foreach (ServerPlayer *p, room->getPlayers()) {
                QString kingdom;
                if (p->hasShownOneGeneral())
                    kingdom = p->getKingdom();
                else if (!lords.isEmpty())
                    return QString(); // if hasLord() and there are someone haven't shown its kingdom, it means this one could kill
                // the lord to become careerist.
                else
                    kingdom = p->getActualGeneral1()->getKingdom();
                if (lords.contains(kingdom)) continue;
                if (room->getLord(kingdom, true) && room->getLord(kingdom, true)->isDead())
                    kingdoms[kingdom] += 10;
                else
                    kingdoms[kingdom] ++;
                if (p->isAlive() && !p->hasShownOneGeneral() && kingdoms[kingdom] > room->getPlayers().length() / 2) {
                    has_diff_kingdoms = true;
                    break;  //has careerist, hehe
                }
            }
        }

        if (has_diff_kingdoms) return QString();    //if has enemy, hehe

        //careerist rule

        QList<ServerPlayer *> careerists;

        bool careerist_rule = false;
        foreach (ServerPlayer *p, players) {
            if (!p->hasShownGeneral1() && p->getSeemingKingdom() != "careerist" && p->getActualGeneral1()->getKingdom() == "careerist") {
                careerist_rule = true;
                break;
            }
        }

        if (careerist_rule) {
            foreach (ServerPlayer *p, players) {
                if (p->hasShownGeneral1() || p->getSeemingKingdom() == "careerist") continue;
                if (p->getActualGeneral1()->getKingdom() == "careerist") {
                    if (room->askForChoice(p, "GameRule:CareeristShow", "yes+no", QVariant(), "@careerist-show") == "yes") {

                        LogMessage log;
                        log.type = "#GameRule_CareeristShow";
                        log.from = p;
                        room->sendLog(log);

                        room->setTag("GlobalCareeristShow", true);
                        p->showGeneral();
                        room->setTag("GlobalCareeristShow", false);

                        careerists << p;
                    }
                } else
                    room->askForChoice(p, "GameRule:CareeristShow", "no", QVariant(), "@careerist-show", "yes+no");
            }
        }

        if (room->alivePlayerCount() > 2) {
            foreach (ServerPlayer *p, careerists) {
                QList<ServerPlayer *> to_ask;

                foreach (ServerPlayer *p2, players) {
                    if (p2->isLord()) continue;
                    if (p2->hasShownGeneral1() && p2->getGeneral()->getKingdom() == "careerist") continue;
                    if (p2->property("CareeristFriend").toString().isEmpty())
                        to_ask << p2;
                }

                if (to_ask.isEmpty()) break;

                if (room->askForChoice(p, "GameRule:CareeristSummon", "yes+no", QVariant(), "@careerist-summon") == "yes") {

                    LogMessage log;
                    log.type = "#GameRule_CareeristSummon";
                    log.from = p;
                    room->sendLog(log);

                     foreach (ServerPlayer *p2, to_ask) {
                         if (room->askForChoice(p2, "GameRule:CareeristAdd", "yes+no", QVariant(), "@careerist-add:" + p->objectName()) == "yes") {
                             room->setPlayerMark(p2, "@"+p->getGeneral()->objectName(), 1);
                             room->removePlayerMark(p, "@careerist");

                             LogMessage log;
                             log.type = "#GameRule_CareeristAdd";
                             log.from = p2;
                             log.to << p;
                             room->sendLog(log);

                             room->setPlayerProperty(p, "CareeristFriend", p2->objectName());
                             room->setPlayerProperty(p2, "CareeristFriend", p->objectName());

                             room->setPlayerProperty(p2, "role", "careerist");
                             room->getThread()->trigger(DFDebut, room, p2);

                             p2->fillHandCards(4);

                             room->recover(p2, RecoverStruct());

                             break;
                         }

                     }
                }
            }
        }

        if (!careerists.isEmpty()) return QString();

        foreach (ServerPlayer *p, players) {
            if (p->hasShownGeneral1() || p->getSeemingKingdom() == "careerist") continue;
            if (p->getActualGeneral1()->getKingdom() == "careerist") {
                careerists << p;
            }
        }

        // if run here, all are friend.

        foreach (ServerPlayer *p, players) {
            if (!p->hasShownGeneral1())
                p->showGeneral(true, false, false); // dont trigger event
            if (!p->hasShownGeneral2())
                p->showGeneral(false, false, false);
            if (win_player->getRole() == "careerist" && !careerists.contains(p))
                win_player = p;
        }

        if (careerists.length() == room->alivePlayerCount()) return "."; //if all careerists, hehe

        foreach (ServerPlayer *p, room->getPlayers()) {
            if (win_player->isFriendWith(p))
                winners << p->objectName();
        }

    }

    return winners.join("+");
}
