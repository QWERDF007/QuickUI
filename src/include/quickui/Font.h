#pragma once

#include "Def.h"
#include "Export.h"
#include "Singleton.h"

#include <QFont>

namespace quickui {

class QUICKUI_EXPORT QuiFont : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(QuiFont)
    QT_QML_SINGLETON(QuiFont)
    Q_PROPERTY_AUTO(QFont, Caption)
    Q_PROPERTY_AUTO(QFont, Body)
    Q_PROPERTY_AUTO(QFont, BodyStrong)
    Q_PROPERTY_AUTO(QFont, Subtitle)
    Q_PROPERTY_AUTO(QFont, Title)
    Q_PROPERTY_AUTO(QFont, TitleLarge)
    Q_PROPERTY_AUTO(QFont, Display)
private:
    explicit QuiFont(QObject *parent = nullptr);
    ~QuiFont();
};

} // namespace quickui
