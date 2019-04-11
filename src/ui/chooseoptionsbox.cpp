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

#include "chooseoptionsbox.h"
#include "button.h"
#include "engine.h"
#include "qsanbutton.h"
#include "client.h"
#include "clientstruct.h"
#include "roomscene.h"
#include "stylehelper.h"

#include <QGraphicsProxyWidget>

ChooseOptionsBox::ChooseOptionsBox()
{
}

QRectF ChooseOptionsBox::boundingRect() const
{
    int n = options.length();
    int allbuttonswidth = 0;
    foreach (const QString &card_name, options) {
        int buttonwidth = getButtonWidth(card_name);
        allbuttonswidth += buttonwidth;
    }
    return QRectF(0, 0, (allbuttonswidth + (n+1)*interval), defaultButtonHeight);
}

void ChooseOptionsBox::chooseOption(const QStringList &options, const QStringList &all_options)
{
    //repaint background
    this->options = all_options;
    prepareGeometryChange();

    foreach (const QString &choice, all_options) {
        QSanButton *button = new QSanButton(this, getButtonWidth(choice), translate(choice));
        button->setObjectName(choice);
        button->setEnabled(options.contains(choice));
        buttons << button;

        QString original_tooltip = QString(":%1").arg(title);
        QString tooltip = Sanguosha->translate(original_tooltip);
        if (tooltip == original_tooltip) {
            original_tooltip = QString(":%1").arg(choice);
            tooltip = Sanguosha->translate(original_tooltip);
        }
        connect(button, &QSanButton::clicked, this, &ChooseOptionsBox::reply);
        if (tooltip != original_tooltip)
            button->setToolTip(tooltip);
    }

    RoomSceneInstance->updateTable();
    setFlag(QGraphicsItem::ItemIsMovable, false);
    show();
    int x = interval;

    //foreach (const QString &card_name, all_options) {
    for (int i = 0; i < buttons.length(); ++i) {
        QSanButton *button = buttons.at(i);
        QPointF apos;
        apos.setX(x);
        x += (interval + getButtonWidth(button->objectName()));
        apos.setY(0);
        button->setPos(apos);
    }
}

void ChooseOptionsBox::reply()
{
    QString choice = sender()->objectName();
    if (choice.isEmpty())
        choice = options.first();
    ClientInstance->onPlayerMakeChoice(choice);
}

int ChooseOptionsBox::getButtonWidth(const QString &card_name) const
{
    QFontMetrics fontMetrics(Button::defaultFont());
    int width = fontMetrics.width(translate(card_name));
    // Otherwise it would look compact
    width += 30;
    return width;
}

QString ChooseOptionsBox::translate(const QString &option) const
{
    QStringList choices = option.split("%");
    QString choice_ = choices.at(0);

    QString title = QString("%1:%2").arg(skillName).arg(choice_);
    QString text = Sanguosha->translate(title);
    if (text == title)
        text = Sanguosha->translate(choice_);

    foreach (const QString &element, choices) {
        if (element.startsWith("from:")) {
            QStringList froms = element.split(":");
            if (!froms.at(1).isEmpty()) {
                QString from = ClientInstance->getPlayerName(froms.at(1));
                text.replace("%from", from);
            }
        } else if (element.startsWith("to:")) {
            QStringList tos = element.split(":");
            QStringList to_list;
            for (int i = 1; i < tos.length(); i++)
                to_list << ClientInstance->getPlayerName(tos.at(i));
            QString to = to_list.join(", ");
            text.replace("%to", to);
        } else if (element.startsWith("log:")) {
            QStringList logs = element.split(":");
            if (!logs.at(1).isEmpty()) {
                QString log = logs.at(1);
                text.replace("%log", log);
            }
        }
    }
    return text;
}

void ChooseOptionsBox::clear()
{
    foreach (QSanButton *button, buttons)
        button->deleteLater();

    buttons.clear();

    disappear();
}
