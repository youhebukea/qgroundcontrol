#pragma once

#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"

class QQmlApplicationEngine;

Q_DECLARE_LOGGING_CATEGORY(BrandLog)

/// Redirects qrc:///... resource requests to qrc:///Custom/... whenever a
/// matching override resource has been registered by the custom overlay.
class BrandOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    QUrl intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type) final;
};

/*===========================================================================*/

/// Minimal branding plugin: installs the resource override interceptor and
/// repoints QGC's outward-facing links at the vendor site.
class BrandPlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    explicit BrandPlugin(QObject *parent = nullptr);

    static QGCCorePlugin *instance();

    QQmlApplicationEngine *createQmlApplicationEngine(QObject *parent) final;
    void destroyQmlApplicationEngine(QQmlApplicationEngine *qmlEngine) final;

    /// "Where do I get a new version" link shown to the user. The stable
    /// version check itself stays disabled (the QGC_CUSTOM_BUILD default), so
    /// the app never contacts QGC's own update service.
    QString stableDownloadLocation() const final
    {
        return QStringLiteral("https://www.lintor.cn/download");
    }

private:
    QQmlApplicationEngine *_qmlEngine = nullptr;
    BrandOverrideInterceptor *_urlInterceptor = nullptr;
};
