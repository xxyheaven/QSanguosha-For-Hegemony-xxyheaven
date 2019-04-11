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

#include "choosehuashenskillbox.h"
#include "engine.h"
#include "button.h"
#include "skinbank.h"
#include "client.h"
#include "clientplayer.h"
#include "timedprogressbar.h"
#include "stylehelper.h"
#include "roomscene.h"

#include <QGraphicsSceneMouseEvent>
#include <QPropertyAnimation>
#include <QGraphicsProxyWidget>

static qreal initialOpacity = 0.8;
static int optionButtonHeight = 40;
static QSize generalButtonSize;

static const QString arrayString = "GameRule_AskForArraySummon";
static const QString generalShowStringHead = "GameRule_AskForGeneralShow";
static const QString headString = generalShowStringHead + "Head";
static const QString deputyString = generalShowStringHead + "Deputy";

const int ChooseHuashenSkillBox::top_dark_bar = 27;
const int ChooseHuashenSkillBox::m_topBlankWidth = 42;
const int ChooseHuashenSkillBox::bottom_blank_width = 25;
const int ChooseHuashenSkillBox::interval = 15;
const int ChooseHuashenSkillBox::m_leftBlankWidth = 37;

HuashenSkillButton::HuashenSkillButton(QGraphicsObject *parent, const QString &player, const QString &skillStr, const int width)
    : QGraphicsObject(parent),
    m_skillStr(skillStr), m_text(displayedTextOf(skillStr)),
    playerName(player), width(width)
{
    QString realSkill = skillStr;
    if (realSkill.contains("'")) // "sgs1'songwei"
        realSkill = realSkill.split("'").last();
    else if (realSkill.contains("->")) // "tieqi->sgs4&1"
        realSkill = realSkill.split("->").first();
    const Skill *skill = Sanguosha->getSkill(realSkill);
    if (skill)
        setToolTip(skill->getDescription());

    setAcceptedMouseButtons(Qt::LeftButton);
    setAcceptHoverEvents(true);
    setOpacity(initialOpacity);
}

QFont HuashenSkillButton::defaultFont()
{
    QFont font = StyleHelper::getFontByFileName("wqy-microhei.ttc");
    font.setPixelSize(Config.TinyFont.pixelSize());
    return font;
}

void HuashenSkillButton::paint(QPainter *painter, const QStyleOptionGraphicsItem *, QWidget *)
{
    painter->setRenderHint(QPainter::HighQualityAntialiasing);
    painter->save();
    painter->setBrush(Qt::black);
    painter->setPen(Sanguosha->getKingdomColor(Self->getGeneral()->getKingdom()));
    QRectF rect = boundingRect();
    painter->drawRoundedRect(rect, 5, 5);
    painter->restore();

    QString generalName = playerName;
    QPixmap pixmap = G_ROOM_SKIN.getGeneralPixmap(generalName, QSanRoomSkin::S_GENERAL_ICON_SIZE_TINY);
    pixmap = pixmap.scaledToHeight(optionButtonHeight, Qt::SmoothTransformation);
    QRect pixmapRect(QPoint(0, (rect.height() - pixmap.height()) / 2), pixmap.size());
    painter->setBrush(pixmap);
    painter->drawRoundedRect(pixmapRect, 5, 5);

    QRect textArea(optionButtonHeight, 0, width - optionButtonHeight,
        optionButtonHeight);

    G_COMMON_LAYOUT.optionButtonText.paintText(painter, textArea,
        Qt::AlignCenter,
        m_text);
}

QRectF HuashenSkillButton::boundingRect() const
{
    return QRectF(0, 0, width, optionButtonHeight);
}

void HuashenSkillButton::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    event->accept();
}

void HuashenSkillButton::mouseReleaseEvent(QGraphicsSceneMouseEvent *)
{
    emit clicked();
}

void HuashenSkillButton::hoverEnterEvent(QGraphicsSceneHoverEvent *)
{
    QPropertyAnimation *animation = new QPropertyAnimation(this, "opacity");
    animation->setEndValue(1.0);
    animation->setDuration(100);
    animation->start(QAbstractAnimation::DeleteWhenStopped);
    emit hovered(true);
}

void HuashenSkillButton::hoverLeaveEvent(QGraphicsSceneHoverEvent *)
{
    QPropertyAnimation *animation = new QPropertyAnimation(this, "opacity");
    animation->setEndValue(initialOpacity);
    animation->setDuration(100);
    animation->start(QAbstractAnimation::DeleteWhenStopped);
    emit hovered(false);
}

QString HuashenSkillButton::displayedTextOf(const QString &str)
{
    int time = 1;
    QString skillName = str;
    if (str.contains("*")) {
        time = str.split("*").last().toInt();
        skillName = str.split("*").first();
    }
    QString text = Sanguosha->translate(skillName);
    if (skillName.contains("->")) { // "tieqi->sgs4&1"
        QString realSkill = skillName.split("->").first(); // "tieqi"
        QString targetObj = skillName.split("->").last().split("&").first(); // "sgs4"
        QString targetName = ClientInstance->getPlayer(targetObj)->getFootnoteName();
        text = tr("%1 (use upon %2)").arg(Sanguosha->translate(realSkill))
            .arg(Sanguosha->translate(targetName));
    }
    if (skillName.contains("'")) {
        QString realSkill = skillName.split("'").last();
        QString targetName = ClientInstance->getPlayer(skillName.split("'").first())->getFootnoteName();
        text = tr("%1 (use upon %2)").arg(Sanguosha->translate(realSkill))
                .arg(Sanguosha->translate(targetName));
    }
    if (time > 1)
        //text += " " + tr("*") + time;
        text += QString(" %1 %2").arg(tr("*")).arg(time);

    return text;
}

bool HuashenSkillButton::isPreferentialSkillOf(const HuashenSkillButton *other) const
{
    if (this == other)
        return true;

    static QRegExp rx("([_A-Za-z]+)->sgs\\d+&\\d+");
    if (!rx.exactMatch(this->m_skillStr) || !rx.exactMatch(other->m_skillStr))
        return false;

    QString thisName = this->m_skillStr.split("->").first();
    int thisIndex = this->m_skillStr.split("&").last().toInt();
    QString otherName = other->m_skillStr.split("->").first();
    int otherIndex = other->m_skillStr.split("&").last().toInt();
    return thisName == otherName && thisIndex < otherIndex;
}

void HuashenSkillButton::needDisabled(bool disabled)
{
    if (disabled) {
        QPropertyAnimation *animation = new QPropertyAnimation(this, "opacity");
        animation->setEndValue(0.2);
        animation->setDuration(100);
        animation->start(QAbstractAnimation::DeleteWhenStopped);
    } else {
        QPropertyAnimation *animation = new QPropertyAnimation(this, "opacity");
        animation->setEndValue(initialOpacity);
        animation->setDuration(100);
        animation->start(QAbstractAnimation::DeleteWhenStopped);
    }
}

ChooseHuashenSkillBox::ChooseHuashenSkillBox()
    : optional(true), m_minimumWidth(0),
    cancel(new Button(tr("cancel"), 0.6))
{
    cancel->hide();
    cancel->setParentItem(this);
    cancel->setObjectName("cancel");
    connect(cancel, &Button::clicked, this, &ChooseHuashenSkillBox::reply);

    generalButtonSize = G_ROOM_SKIN.getGeneralPixmap("caocao", QSanRoomSkin::S_GENERAL_ICON_SIZE_LARGE).size() * 0.6;
}

int ChooseHuashenSkillBox::getGeneralNum() const
{
    if (options.isEmpty())
        return 0;

    int count = 0;
    if (options.contains(QString("%1:%2").arg(Self->objectName()).arg(headString)))
        ++count;
    if (options.contains(QString("%1:%2").arg(Self->objectName()).arg(deputyString)))
        ++count;

    return count;
}

void ChooseHuashenSkillBox::storeMinimumWidth()
{
    int width = 0;
    static QFontMetrics fontMetrics(HuashenSkillButton::defaultFont());
    foreach (const QString &option, options) {
        const QString skill = option.split(":").last();
        if (skill.startsWith(generalShowStringHead))
            continue;

        const int w = fontMetrics.width(HuashenSkillButton::displayedTextOf(skill));
        if (w > width)
            width = w;
    }
    m_minimumWidth = width + optionButtonHeight + 20;
}

QRectF ChooseHuashenSkillBox::boundingRect() const
{
    const int generalNum = getGeneralNum();
    int width = generalButtonSize.width();
    if (generalNum == 2)
        width += generalButtonSize.width() + interval;

    width = qMax(m_minimumWidth, width) + m_leftBlankWidth * 2;

    int height = m_topBlankWidth
        + (options.size() - generalNum) * optionButtonHeight
        + (options.size() - generalNum - 1) * interval
        + bottom_blank_width;

    if (ServerInfo.OperationTimeout != 0)
        height += 12;

    if (generalNum > 0)
        height += generalButtonSize.height() + interval;

    if (optional)
        height += cancel->boundingRect().height() + interval;

    return QRectF(0, 0, width, height);
}

void ChooseHuashenSkillBox::chooseOption(const QString &reason, const QStringList &options, const bool optional)
{
    this->options = options;
    this->optional = optional;
    title = Sanguosha->translate(reason);

    storeMinimumWidth();

    prepareGeometryChange();

    int width = generalButtonSize.width();
    int generalHeight = 0;

    width = qMax(width, m_minimumWidth);

    foreach (const QString &option, options) {
        QStringList pair = option.split(":");

        HuashenSkillButton *button = new HuashenSkillButton(this, pair.first(), pair.last(), width);
        button->setObjectName(option);
        optionButtons << button;
    }

    moveToCenter();
    show();

    int y = m_topBlankWidth;
    foreach (HuashenSkillButton *button, optionButtons) {
        QPointF pos;
        pos.setX(m_leftBlankWidth);
        pos.setY(y);

        button->setPos(pos);
        connect(button, &HuashenSkillButton::clicked, this, &ChooseHuashenSkillBox::reply);
        y += button->boundingRect().height() + interval;
    }


    if (optional) {
        cancel->setPos((boundingRect().width() - cancel->boundingRect().width()) / 2,
            y + generalHeight + interval);
        cancel->show();
    }
}

void ChooseHuashenSkillBox::clear()
{

    foreach(HuashenSkillButton *button, optionButtons)
        button->deleteLater();

    optionButtons.clear();

    cancel->hide();

    disappear();
}

void ChooseHuashenSkillBox::reply()
{
    clear();
    QString choice = sender()->objectName();
    if (choice.isEmpty()) {
        if (optional)
            choice = "cancel";
        else
            choice = options.first();
    }
    RoomSceneInstance->onHuashenSkillActivated(choice);
}
