# QGroundControl 品牌定制指南（联涛智控 LINTOR GCS）

本目录是一个**可直接构建的白标（white-label）定制示例**：把 QGroundControl 改造成虚构公司
"联涛智控（LINTOR）" 的自有产品 **LINTOR GCS**，涵盖应用名称、公司信息、版权、
包名、全平台图标、工具栏/地图 Logo、帮助页支持链接、安装包外观与 Android 桌面图标。

> **为什么不要直接改源码？** QGC 官方提供 `custom/` 覆盖目录机制（见
> `docs/en/qgc-dev-guide/custom_build/custom_build.md` 与 `custom-example/` 官方示例）：
> 所有品牌定制集中在一个独立目录里，`git pull` 升级上游时零冲突。本示例正是基于该机制。

> **编译与发布**：日常一键发布直接运行 `custom\tools\release.bat`（增量约 3-10 分钟）。
> 完整的修改清单、环境搭建、CPM 依赖缓存复用（`D:\qgc\cpm-cache`，一次下载永久离线）与
> 常见问题，见 **[docs/编译与发布指南.md](docs/编译与发布指南.md)**。

---

## 1. 定制机制原理（三层）

```text
┌─ 第 1 层：CMake 变量覆盖 ──────────────────────────────────────────────
│  源码根目录存在 custom/ 时，根 CMakeLists.txt（第 60-73 行）自动：
│    · 置 QGC_CUSTOM_BUILD=ON
│    · 在 project() 之前先 include custom/cmake/CustomOverrides.cmake
│  因此本目录可以用 CACHE FORCE 覆盖 cmake/CustomOptions.cmake 里的全部默认值：
│    应用名 / 公司名 / 域名 / 版权 / 描述 / 包名 / 各平台图标与安装图素材路径
├─ 第 2 层：品牌插件（QGCCorePlugin 子类）──────────────────────────────
│  src/CMakeLists.txt（第 203-227 行）在 QGC_CUSTOM_BUILD 下把 custom/src 编进主程序，
│  宏 CUSTOMHEADER/CUSTOMCLASS 让 QGCCorePlugin::instance() 换成我们的 BrandPlugin。
│  BrandPlugin 通过 QQmlEngine::addUrlInterceptor 注册资源拦截器：
│  任何 qrc:/xxx 加载，只要存在 qrc:/Custom/xxx 覆盖资源，就改用覆盖版。
└─ 第 3 层：资源覆盖 ───────────────────────────────────────────────────
   custom/CMakeLists.txt 用 qt_add_resources 注册覆盖资源：
     · /Custom/res/QGCLogoFull.svg   → 替换工具栏/菜单/地图上的 QGC Logo
     · /Custom/qml/.../HelpSettings.qml → 整页替换"帮助"设置页
     · /res/qgroundcontrol.ico       → 直接同路径注册，替换窗口图标
       （窗口图标在 C++ 中直接读取，不走拦截器，必须同路径覆盖）
```

## 2. 目录结构

```text
custom/
├── README.md                          ← 本文档
├── CMakeLists.txt                     ← 资源覆盖注册 + 插件源码接线
├── brand/
│   ├── lintor-logo-source.jpg         ← 厂家提供的 Logo 原图
│   └── lintor-wordmark-*.png          ← 提取出的透明字标（中间产物，可复核）
├── cmake/
│   └── CustomOverrides.cmake          ← 品牌变量覆盖（应用名/公司/图标路径）
├── src/
│   ├── BrandPlugin.h / .cc            ← 品牌插件：资源拦截器 + 下载链接 + 中文窗口名
│   └── HelpSettings.qml               ← "帮助"页覆盖（公司支持渠道）
├── res/
│   ├── images/
│   │   ├── LintorLogoFull.svg         ← 主 Logo：白色圆角徽章（替换 QGCLogoFull.svg）
│   │   └── LintorLogoWhite.svg        ← 深底用白色版（替换 QGCLogoWhite.svg）
│   └── icons/
│       ├── lintor.ico                 ← Windows exe/窗口/安装器图标
│       ├── lintor.icns                ← macOS 应用图标
│       ├── lintor-256.png             ← Linux AppImage 256px 图标
│       └── LintorAppIcon.svg          ← Linux AppImage 矢量图标
├── deploy/windows/
│   └── installheader.bmp              ← NSIS 安装器头部横幅（150×57）
├── android/res/drawable-*/icon.png    ← Android 启动器图标（6 个密度）
├── docs/
│   └── 编译与发布指南.md               ← 修改清单/环境搭建/缓存复用/发布流程
└── tools/
    ├── generate_lintor_assets.py      ← 从 brand/ 原图一键重生成全套素材
    └── release.bat                    ← 一键编译发布（增量 3-10 分钟）
```

## 3. 快速开始

```bash
# 1. 把本目录放到源码根目录（目录名必须是 custom，或 configure 时
#    传 -DQGC_CUSTOM_DIR=<你的目录名>）
# 2. 干净构建（QGC 会打印 "QGC: Custom build directory detected: custom"）
just configure
just build

# 3. 验证品牌生效
#    · 启动程序：窗口标题为 LINTOR-GCS（联涛智控地面站），任务栏图标为LINTOR Logo
#    · 工具栏左上角显示LINTOR Logo
#    · 应用设置 → 帮助：显示联涛智控的支持链接
#    · Windows 上右键 exe → 属性：产品名/版权为公司信息
```

打安装包（以 Windows 为例，其它平台同理）：

```bash
just build                       # 先完成构建
cmake --build build --target qgc-package   # 生成 NSIS 安装器（含自定义图标与头部横幅）
```

## 4. 品牌变量明细（custom/cmake/CustomOverrides.cmake）

| 变量 | 本示例取值 | 影响范围（源码位置） |
| --- | --- | --- |
| `QGC_APP_NAME` | `LINTOR-GCS` | CMake 工程名与 **exe 文件名**（CMakeLists.txt:121,353）、窗口标题/QSettings（src/QGCApplication.cc:95）、安装包文件名、Android 应用显示名 |
| `QGC_ORG_NAME` | `LINTOR` | QSettings 组织名（QGCApplication.cc:97）、exe 属性"公司名"（cmake/platform/Windows.cmake:34）、NSIS 注册表键与卸载目录（CreateCPackNSIS.cmake:80,155）、安装器厂商（CreateCPackCommon.cmake:12） |
| `QGC_ORG_DOMAIN` | `lintor.cn` | QSettings 域（QGCApplication.cc:98）、工程 HOMEPAGE_URL（CMakeLists.txt:124） |
| `QGC_APP_COPYRIGHT` | `Copyright (c) 2026 ...` | exe 版权属性（Windows.cmake:37）、macOS Info.plist 的 NSHumanReadableCopyright |
| `QGC_APP_DESCRIPTION` | `LINTOR Ground Control Station` | 工程 DESCRIPTION（CMakeLists.txt:123） |
| `QGC_PACKAGE_NAME` | `cn.lintor.gcs` | Linux 桌面文件名、macOS Bundle ID（QGCApplication.cc:96 / CustomOptions.cmake:156） |
| `QGC_ANDROID_PACKAGE_NAME` | `cn.lintor.gcs` | Android 包名/应用 ID（cmake/platform/Android.cmake:97），**必须显式覆盖**（它在覆盖文件加载前就由默认包名初始化） |
| `QGC_MACOS_ICON_PATH` 等 5 个图标路径 | 指向本目录文件 | 各平台图标/安装图（存在才覆盖，未覆盖的平台保持原样） |

版本号不需要改：`cmake/modules/Git.cmake` 从 **git tag** 自动提取（`git tag v1.2.3`）。

> ⚠️ `QGC_APP_NAME` 请保持 **ASCII 且不含空格**——exe 名、NSIS 文件名、注册表键、
> QSettings 文件名都由它派生。界面内的显示名如需更友好的写法，见第 8 节进阶定制。

## 5. 资源覆盖详解（把任何图表/图片/页面换成自己的）

两种覆盖方式，取决于资源在源码中的加载路径：

**方式 A：拦截器覆盖（QML 中引用的资源）** —— 注册到 `/Custom` 前缀，
`QT_RESOURCE_ALIAS` 必须与原资源路径**逐字一致**：

| 覆盖文件 | 替换目标 | 原资源的使用位置 |
| --- | --- | --- |
| `res/images/LintorLogoFull.svg` | `/res/QGCLogoFull.svg` | 飞行/规划工具栏 Logo（src/Toolbar/FlyViewToolBar.qml:81、PlanViewToolBar.qml:40）、主窗口菜单（src/MainWindow/MainWindow.qml:476）、地图上本站位置指示（src/FlightMap/FlightMap.qml:251、src/GeoMap/GeoMap.qml:580） |
| `res/images/LintorLogoWhite.svg` | `/res/QGCLogoWhite.svg` | "应用设置"页图标（src/AutoPilotPlugins/../SettingsPages.json:8）、视图下拉按钮（src/Toolbar/SelectViewDropdown.qml:98） |
| `src/HelpSettings.qml` | `/qml/QGroundControl/AppSettings/HelpSettings.qml` | 应用设置 → 帮助页整页（页面清单见 src/AppSettings/pages/SettingsPages.json:100） |

**方式 B：同路径直接覆盖（C++ 代码直接读取的资源）** —— 窗口图标在
`src/QGCApplication.cc:313` 以 `":/res/qgroundcontrol.ico"` 直接读取，不经过 QML
拦截器，因此必须在 `/res` 前缀下以同名 alias 注册（Qt 资源系统后注册者生效）。

**替换成真实素材的规格：**

| 文件 | 规格 | 备注 |
| --- | --- | --- |
| Logo SVG ×2 | 方形 viewBox（72×72 即可），矢量路径（不要用 `<text>` 文本元素） | 设计师从 AI/Figma 导出 SVG；深浅两个版本 |
| `lintor.ico` | 至少含 16/32/48/256 四档 | `magick logo.png -define icon:auto-resize=16,32,48,256 lintor.ico` |
| `lintor.icns` | 16/32/128/256（建议再加 512） | `png2icns`、`iconutil`（macOS）或在线工具 |
| `lintor-256.png` / `LintorAppIcon.svg` | 256×256 / 任意方形矢量 | AppImage 桌面图标 |
| `installheader.bmp` | **150×57** 24 位 BMP | NSIS 安装器头部横幅 |
| Android `icon.png` ×6 | 36/48/72/96/144/192（ldpi→xxxhdpi） | 放入 `custom/android/res/drawable-<dpi>/` |

当前全套素材即由脚本从 `brand/lintor-logo-source.jpg` 一键生成（抠透明底、行分割、
品牌蓝重上色、ICO/ICNS/BMP/Android 全尺寸输出）。更换 Logo 时，只需替换该原图后重跑：

```bash
python custom/tools/generate_lintor_assets.py
```

## 6. 已自动获得的"去 QGC 化"行为

进入定制构建后，QGCCorePlugin 的默认行为即改变（src/API/QGCCorePlugin.h:145-159）：

- **不再连接 QGC 官方版本检查服务**（`stableVersionCheckFileUrl()` 返回空）；
- `BrandPlugin` 把"获取新版本"链接（`stableDownloadLocation()`）指向了
  `https://www.lintor.cn/download`——改成你自己的发布页。

## 7. 各平台安装包品牌效果

| 平台 | 产物 | 已定制内容 |
| --- | --- | --- |
| Windows | `LINTOR-GCS-installer-AMD64.exe`（NSIS） | exe 图标/属性（产品名、公司、版权）、安装器图标与头部横幅、注册表键与安装目录归公司名下 |
| macOS | `LINTOR-GCS.dmg` | Bundle ID `cn.lintor.gcs`、应用图标 icns、Info.plist 名称/版权 |
| Linux | AppImage / DEB / RPM | 桌面图标（PNG+SVG）、桌面入口、厂商字段 |
| Android | APK/AAB | 包名、应用显示名（派生自包名变量）、启动器图标（6 密度） |

## 8. 进阶定制（本示例未展开，机制已具备）

- **全局配色**：在 `BrandPlugin` 里重写 `paletteOverride(...)`（参考
  `custom-example/src/CustomPlugin.cc` 中 100+ 行完整配色示例）。
- **隐藏设置页 / 界面元素**：重写 `adjustSettingMetaData(...)` 隐藏个别设置项，
  `QGCOptions`/`QGCFlyViewOptions` 控制仪表盘、多机列表等；定制构建默认运行在
  "普通模式"，连点飞行按钮 5 次进入"高级模式"可放开全部界面。
- **锁定单一固件**：`QGC_DISABLE_APM_PLUGIN_FACTORY` / `QGC_DISABLE_PX4_PLUGIN_FACTORY`。
- **替换任意 QML 页面**：与 `HelpSettings.qml` 同法——把目标 QML 加入
  `qt_add_resources` 并设置别名即可，包括飞行仪表等复杂组件
  （完整示例见 `custom-example/`：自定义仪表、任务类型、固件插件等）。
- **地图 GCS 航向箭头**：`/res/QGCLogoArrow.svg` 同样可按方式 A 覆盖。

## 9. 许可证与合规（对外发布前必读）

QGC 采用 **Apache-2.0 / GPL-3.0 双许可**（仓库根目录 `LICENSE-APACHE`、`LICENSE-GPL`）。
作为公司产品对外发布时：

1. **选择 Apache-2.0 路径**：允许商用、修改、闭源分发，但需要——
   - 在发行物中**保留 Apache-2.0 许可证文本与原版权声明**（随安装包附 LICENSE 副本，或在"关于/帮助"中链接）；
   - **声明修改**：Apache-2.0 §4(b) 要求显著标注你修改了上游文件（在文档或 NOTICE 中说明即可）。
   - 若选择 GPL-3.0 路径，则整个衍生作品必须开源——商业闭源场景请避免。
2. **保留出处**：本示例的 `HelpSettings.qml` 已保留 "Based on QGroundControl" 链接，
   建议保留（既是义务的最稳妥履行方式，也便于用户追溯上游）。
3. **商标**：QGroundControl 名称与 Logo 是上游项目的商标。本示例替换了全部品牌元素，
   正好避免商标侵权；同时请勿在宣传中暗示获得 QGC 官方认证或背书。
4. 以上为工程实践指引，不构成法律意见，正式发布前请交由法务复核。

## 10. 升级与维护

```bash
git pull upstream master    # 拉取上游更新
just configure && just build
```

- `custom/` 目录外的源码零修改，升级即常规合并；
- **例外**：方式 A 覆盖的 QML（目前仅 `HelpSettings.qml`）是上游源码的副本，升级后
  需对照上游 `src/AppSettings/HelpSettings.qml` 的变更同步你的副本；
- 上游若重命名/移动了被覆盖的资源（见第 5 节表中的路径），需同步更新
  `QT_RESOURCE_ALIAS`；升级后建议对照第 5 节表格逐项 grep 核实路径。

## 11. FAQ

**Q：改名后老用户的设置没了？**
A：QSettings 存储路径由"组织名 + 应用名"决定（`%APPDATA%/LINTOR/LINTOR-GCS.ini`）。
作为新产品这通常是期望行为（全新干净的设置空间）。确实需要继承旧 QGC 设置的话，
可在 `BrandPlugin` 构造函数中手动迁移旧 ini。

**Q：窗口标题能显示成带空格的中文名吗（如"联涛智控地面站"）？**
A：可以，但不要改 `QGC_APP_NAME`（它派生 exe/安装包/注册表名）。应在 `BrandPlugin`
中调用 `QCoreApplication::setApplicationDisplayName()`，并给界面文案提供中文翻译。

**Q：构建时没走定制？**
A：确认目录名为 `custom` 且位于源码根目录；configure 输出应包含
`QGC: Custom build directory detected: custom` 与
`QGC: Adding Brand (custom overlay) plugin`。改过 CMake 后需重新 configure。

**Q：替换的 Logo 没生效？**
A：三个检查点——`QT_RESOURCE_ALIAS` 与原路径逐字一致；文件确实存在于
`/Custom/...` 资源前缀下；重新 configure + 全量重编（资源有缓存）。

**Q：如何把"每日构建"字样去掉？**
A：`QGC_STABLE_BUILD=ON`（稳定版构建，应用名不再附加 " Daily" 后缀，见 QGCApplication.cc:90）。
