#include "BrandPlugin.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QFile>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>

#include "QGCLoggingCategory.h"

QGC_LOGGING_CATEGORY(BrandLog, "Brand.BrandPlugin")

Q_APPLICATION_STATIC(BrandPlugin, _brandPluginInstance);

QUrl BrandOverrideInterceptor::intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type)
{
    switch (type) {
    case QQmlAbstractUrlInterceptor::QmlFile:
    case QQmlAbstractUrlInterceptor::UrlString:
        if (url.scheme() == QStringLiteral("qrc")) {
            const QString overridePath = QStringLiteral("/Custom") + url.path();
            if (QFile::exists(QStringLiteral(":") + overridePath)) {
                qCDebug(BrandLog) << "Overriding resource:" << url.path();
                QUrl result;
                result.setScheme(QStringLiteral("qrc"));
                result.setPath(overridePath);
                return result;
            }
        }
        break;
    default:
        break;
    }
    return url;
}

BrandPlugin::BrandPlugin(QObject *parent)
    : QGCCorePlugin(parent)
{
    qCDebug(BrandLog) << this;

    // Chinese display name for the window title bar (QGC_APP_NAME stays ASCII
    // because exe/installer/QSettings names derive from it).
    QGuiApplication::setApplicationDisplayName(QStringLiteral("联涛智控地面站"));
}

QGCCorePlugin *BrandPlugin::instance()
{
    return _brandPluginInstance();
}

QQmlApplicationEngine *BrandPlugin::createQmlApplicationEngine(QObject *parent)
{
    _qmlEngine = QGCCorePlugin::createQmlApplicationEngine(parent);
    _urlInterceptor = new BrandOverrideInterceptor();
    _qmlEngine->addUrlInterceptor(_urlInterceptor);

    return _qmlEngine;
}

void BrandPlugin::destroyQmlApplicationEngine(QQmlApplicationEngine *qmlEngine)
{
    if (qmlEngine && (qmlEngine == _qmlEngine)) {
        qmlEngine->removeUrlInterceptor(_urlInterceptor);
        delete _urlInterceptor;
        _urlInterceptor = nullptr;
        _qmlEngine = nullptr;
    }

    QGCCorePlugin::destroyQmlApplicationEngine(qmlEngine);
}
