#include "guhuobox.h"
#include "roomscene.h"
#include "engine.h"
#include "standard.h"
#include "clientplayer.h"
#include "skinbank.h"
#include "stylehelper.h"

#include <QGraphicsSceneMouseEvent>
#include <QPropertyAnimation>
#include <QGraphicsProxyWidget>
#include <QScrollBar>

static QSize cardButtonSize;

const int GuhuoBox::topBlankWidth = 38;
const int GuhuoBox::bottomBlankWidth = 15;
const int GuhuoBox::interval = 5;

const int GuhuoBox::titleWidth = 22;

GuhuoBox::GuhuoBox(const QString &skillname, const QString &flag, bool playonly) :
    m_vScrollBar(NULL), m_oldScrollValue(0)
{
    this->skill_name = skillname;
    this->flags = flag;
    this->play_only = playonly;
    title = QString("%1 %2").arg(Sanguosha->translate(skill_name)).arg(tr("Please choose:"));
    cardButtonSize = QSize(G_COMMON_LAYOUT.m_cardNormalWidth, G_COMMON_LAYOUT.m_cardNormalHeight);
}


QRectF GuhuoBox::boundingRect() const
{
    int count = qMax(maxcardcount, 2);
    int width = cardButtonSize.width() * count * scale / 10 + interval * 2;
    int defaultButtonHeight = cardButtonSize.height() * scale / 10;

    int height = topBlankWidth
        + maxrow * defaultButtonHeight + interval * (maxrow - 1)
        + titleWidth * maxrow + bottomBlankWidth;

    return QRectF(0, 0, width, height);
}

bool GuhuoBox::isButtonEnable(const QString &card_name) const
{
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (skill == NULL) return false;
    return skill->buttonEnabled(card_name);
}

bool GuhuoBox::isButtonVisible(const QString &card_name) const
{
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (skill == NULL) return false;
    return skill->buttonVisible(card_name);
}

static bool sortByKingdom(const QString &gen1, const QString &gen2)
{
    static QMap<QString, int> kingdom_priority_map;
    if (kingdom_priority_map.isEmpty()) {
        QStringList kingdoms = Sanguosha->getKingdoms();
        //kingdoms << "god";
        int i = 0;
        foreach (const QString &kingdom, kingdoms)
            kingdom_priority_map[kingdom] = i++;
    }
    const General *g1 = Sanguosha->getGeneral(gen1);
    const General *g2 = Sanguosha->getGeneral(gen2);

    if (g1 != NULL && g2 != NULL) {
        if (g1->isDoubleKingdoms() && !g2->isDoubleKingdoms())
            return false;
        if (!g1->isDoubleKingdoms() && g2->isDoubleKingdoms())
            return true;
        return kingdom_priority_map[g1->getKingdom()] < kingdom_priority_map[g2->getKingdom()];
    } else
        return false;

}

void GuhuoBox::popup()
{
    if (RoomSceneInstance->current_guhuo_box != NULL) {
        RoomSceneInstance->current_guhuo_box->clear();
    }
    //if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
        //RoomSceneInstance->getDasboard()->unselectAll();
        //RoomSceneInstance->getDasboard()->stopPending();
        //RoomSceneInstance->getDasboard()->disableAllCards();
    //}
    //if (play_only && Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_PLAY) {
        //emit onButtonClick();
        //return;
    //}

    RoomSceneInstance->getDasboard()->disableAllCards();

    RoomSceneInstance->current_guhuo_box = this;

    maxcardcount = 0;
    maxrow = 0;
    scale = 10;
    titles.clear();
    QStringList names1, names2, names3, names4;

    if (skill_name == "yigui") {
        Self->tag.remove("yigui_general");
        Title *newtitle = new Title(this, translate("huashencard"), IQSanComponentSkin::QSanSimpleTextFont::_m_fontBank.key(G_COMMON_LAYOUT.graphicsBoxTitleFont.m_fontFace), Config.TinyFont.pixelSize());
        newtitle->setParentItem(this);
        titles << newtitle;
        ++maxrow;
    }


    QList<Card *> cards = Sanguosha->getCards();
    if (flags.contains("b")) {
        foreach (const Card *card, cards) {
            if (card->isKindOf("BasicCard") && !names1.contains(card->objectName()) && isButtonVisible(card->objectName())
                && !ServerInfo.Extensions.contains("!" + card->getPackage())) {
                names1 << card->objectName();
            }
        }
        if (!names1.isEmpty()) {
            Title *newtitle = new Title(this, translate("BasicCard"), IQSanComponentSkin::QSanSimpleTextFont::_m_fontBank.key(G_COMMON_LAYOUT.graphicsBoxTitleFont.m_fontFace), Config.TinyFont.pixelSize());
            newtitle->setParentItem(this);
            titles << newtitle;
            maxcardcount = names1.length();
            ++maxrow;
        }
    }
    if (flags.contains("t")) {
        foreach (const Card *card, cards) {
            if (card->isNDTrick() && !ServerInfo.Extensions.contains("!" + card->getPackage())) {
                if (names2.contains(card->objectName()) || names3.contains(card->objectName()) || !isButtonVisible(card->objectName()))
                    continue;

                if (card->inherits("SingleTargetTrick"))
                    names2 << card->objectName();
                else
                    names3 << card->objectName();

            }
        }
        if (!names2.isEmpty()) {
            Title *newtitle = new Title(this, translate("SingleTargetTrick"), IQSanComponentSkin::QSanSimpleTextFont::_m_fontBank.key(G_COMMON_LAYOUT.graphicsBoxTitleFont.m_fontFace), Config.TinyFont.pixelSize());
            newtitle->setParentItem(this);
            titles << newtitle;
            maxcardcount = qMax(maxcardcount, names2.length());
            ++maxrow;
        }
        if (!names3.isEmpty()) {
            Title *newtitle = new Title(this, translate("MultiTarget"), IQSanComponentSkin::QSanSimpleTextFont::_m_fontBank.key(G_COMMON_LAYOUT.graphicsBoxTitleFont.m_fontFace), Config.TinyFont.pixelSize());
            newtitle->setParentItem(this);
            titles << newtitle;
            maxcardcount = qMax(maxcardcount, names3.length());
            ++maxrow;
        }
    }
    if (flags.contains("d")) {
        foreach (const Card *card, cards) {
            if (!card->isNDTrick() && card->isKindOf("TrickCard") && !names4.contains(card->objectName()) && isButtonVisible(card->objectName())
                && !ServerInfo.Extensions.contains("!" + card->getPackage())) {
                names4 << card->objectName();
            }
        }
        if (!names4.isEmpty()) {
            Title *newtitle = new Title(this, translate("DelayedTrick"), IQSanComponentSkin::QSanSimpleTextFont::_m_fontBank.key(G_COMMON_LAYOUT.graphicsBoxTitleFont.m_fontFace), Config.TinyFont.pixelSize());
            newtitle->setParentItem(this);
            titles << newtitle;
            maxcardcount = qMax(maxcardcount, names4.length());
            ++maxrow;
        }
    }

    if (maxcardcount == 0) {
        emit onButtonClick();
        return;
    }

    int buttonWidth = cardButtonSize.width() * scale / 10;
    int defaultButtonHeight = cardButtonSize.height() * scale / 10;

    moveToCenter();
    show();
    int x = 0;
    int y = 1;
    int app = 0;
    if (maxcardcount == 1)
        app = (buttonWidth + interval) / 2;

    for (int i = 0; i < titles.length(); ++i) {
        QPointF titlepos;
        titlepos.setX(interval + app);
        titlepos.setY(topBlankWidth + defaultButtonHeight * i + interval * i + titleWidth * i);
        titles.at(i)->setPos(titlepos);
    }

    if (skill_name == "yigui") {
        QStringList huashens = Self->tag["Huashens"].toStringList();

        qStableSort(huashens.begin(), huashens.end(), sortByKingdom);

        int skinCount = huashens.length();

        int huashens_x = interval + app;
        int huashens_y = topBlankWidth + titleWidth * y;
        int huashens_width = (cardButtonSize.width() * maxcardcount);

        if (skinCount > maxcardcount) {
            m_vScrollBar = new QScrollBar(Qt::Horizontal);
            m_vScrollBar->setStyleSheet(StyleHelper::styleSheetOfScrollBar());
            m_vScrollBar->setFocusPolicy(Qt::StrongFocus);
            connect(m_vScrollBar, &QScrollBar::valueChanged, this, &GuhuoBox::scrollBarValueChanged);

            m_vScrollBar->setMaximum((skinCount - maxcardcount) * buttonWidth);
            m_vScrollBar->setPageStep(buttonWidth);
            m_vScrollBar->setSingleStep(buttonWidth);

            QGraphicsProxyWidget *scrollBarWidget = new QGraphicsProxyWidget(this);
            scrollBarWidget->setWidget(m_vScrollBar);

            scrollBarWidget->setGeometry(QRectF(huashens_x, huashens_y + defaultButtonHeight, huashens_width, 10));
        }

        QGraphicsRectItem *dummyRectItem = new QGraphicsRectItem(QRectF(huashens_x, huashens_y,
            huashens_width, cardButtonSize.height()), this);
        dummyRectItem->setFlag(ItemHasNoContents);
        dummyRectItem->setFlag(ItemClipsChildrenToShape);

        foreach (QString huashen, huashens) {
            CardItem *cardItem = new CardItem(huashen);
            cardItem->setAutoBack(false);
            cardItem->setFlag(QGraphicsItem::ItemIsFocusable);
            cardItem->setFlag(QGraphicsItem::ItemIsMovable, false);
            connect(cardItem, &CardItem::clicked, this, &GuhuoBox::onGeneralItemClicked);
            cardItem->setParentItem(dummyRectItem);
            cardItem->resetTransform();
            cardItem->setOuterGlowEffectEnabled(true);

            QPointF apos;
            apos.setX(interval + x * buttonWidth + app);
            apos.setY(topBlankWidth + (defaultButtonHeight + interval) * (y - 1) + titleWidth * y);
            ++x;

            cardItem->setPos(apos);
            generalItems << cardItem;
        }
        ++y;
        x = 0;
    }

    if (!names1.isEmpty()) {
        foreach (const QString &cardname, names1) {
            QPointF apos;
            apos.setX(interval + x * buttonWidth + app);
            apos.setY(topBlankWidth + (defaultButtonHeight + interval) * (y - 1) + titleWidth * y);
            ++x;
            createCardItem(cardname, apos);
        }
        ++y;
        x = 0;
    }
    if (!names2.isEmpty()) {
        foreach (const QString &cardname, names2) {
            QPointF apos;
            apos.setX(interval + x * buttonWidth + app);
            apos.setY(topBlankWidth + (defaultButtonHeight + interval) * (y - 1) + titleWidth * y);
            ++x;
            createCardItem(cardname, apos);
        }
        ++y;
        x = 0;
    }
    if (!names3.isEmpty()) {
        foreach (const QString &cardname, names3) {
            QPointF apos;
            apos.setX(interval + x * buttonWidth + app);
            apos.setY(topBlankWidth + (defaultButtonHeight + interval) * (y - 1) + titleWidth * y);
            ++x;
            createCardItem(cardname, apos);
        }
        ++y;
        x = 0;
    }
    if (!names4.isEmpty()) {
        foreach (const QString &cardname, names4) {
            QPointF apos;
            apos.setX(interval + x * buttonWidth + app);
            apos.setY(topBlankWidth + (defaultButtonHeight + interval) * (y - 1) + titleWidth * y);
            ++x;
            createCardItem(cardname, apos);
        }
        ++y;
        x = 0;
    }
    updateCardItems();
}

void GuhuoBox::createCardItem(const QString &cardname, const QPointF &pos)
{
    const Card *card = Sanguosha->cloneCard(cardname, Card::NoSuit, 0);
    CardItem *cardItem = new CardItem(card);
    cardItem->setAutoBack(false);
    cardItem->setFlag(QGraphicsItem::ItemIsFocusable);
    cardItem->setFlag(QGraphicsItem::ItemIsMovable, false);

    connect(cardItem, &CardItem::clicked, this, &GuhuoBox::reply);

    cardItem->setParentItem(this);
    cardItem->resetTransform();
    cardItem->setOuterGlowEffectEnabled(true);
    cardItem->setPos(pos);

    buttons << cardItem;
}

void GuhuoBox::onGeneralItemClicked()
{
    CardItem *sender_item = qobject_cast<CardItem *>(sender());
    if (sender_item == NULL) return;

    foreach (CardItem *item, generalItems) {
        item->setChosen(item == sender_item);
        item->setOpacity((item == sender_item) ? 1 : 0.7);
    }
    Self->tag["yigui_general"] = sender_item->objectName();
    updateCardItems();
}

void GuhuoBox::updateCardItems()
{
    foreach(CardItem *cardItem, buttons) {
        bool card_enabled = isButtonEnable(cardItem->objectName());
        cardItem->setEnabled(card_enabled);
        cardItem->setOpacity(card_enabled ? 1 : 0.7);
    }
}

void GuhuoBox::reply()
{
    Self->tag.remove(skill_name);
    const QString &answer = sender()->objectName();
    Self->tag[skill_name] = answer;
    emit onButtonClick();
    clear();
}

void GuhuoBox::clear()
{
    RoomSceneInstance->current_guhuo_box = NULL;

//    if (sender() != NULL && Self->tag[skill_name] == sender()->objectName() && Sanguosha->getViewAsSkill(skill_name) != NULL)
//        RoomSceneInstance->getDasboard()->updatePending();
//    else if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
//        RoomSceneInstance->getDasboard()->stopPending();
//        RoomSceneInstance->getDasboard()->enableCards();
//        RoomSceneInstance->doCancelButton();
//    }

    if (!isVisible())
        return;

    foreach(CardItem *button, buttons)
        button->deleteLater();

    buttons.clear();

    foreach(CardItem *button, generalItems)
        button->deleteLater();

    generalItems.clear();

    foreach (Title *title, titles)
        title->deleteLater();

    titles.clear();

    disappear();
}

QString GuhuoBox::translate(const QString &option) const
{
    QString title = QString("%1:%2").arg(skill_name).arg(option);
    QString translated = Sanguosha->translate(title);
    if (translated == title)
        translated = Sanguosha->translate(option);
    return translated;
}

void GuhuoBox::wheelEvent(QGraphicsSceneWheelEvent *event)
{
    if (NULL != m_vScrollBar) {
        int deltaValue = event->delta();
        int scrollBarValue = m_vScrollBar->value();
        scrollBarValue += (-deltaValue / 120) * m_vScrollBar->pageStep();
        m_vScrollBar->setValue(scrollBarValue);
    }
}

void GuhuoBox::scrollBarValueChanged(int newValue)
{
    int diff = newValue - m_oldScrollValue;
    foreach (CardItem *button, generalItems)
        button->moveBy(-diff, 0);

    m_oldScrollValue = newValue;
}
