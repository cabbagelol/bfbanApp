/// 支持

import 'package:flutter/material.dart';

import 'package:flutter_plugin_elui/elui.dart';
import 'package:provider/provider.dart';

import 'package:bfban/utils/index.dart';
import 'package:bfban/constants/theme.dart';

class SupportPage extends StatefulWidget {
  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  Map theme = THEMELIST['none'];

  UrlUtil _urlUtil = new UrlUtil();

  @override
  void initState() {
    super.initState();
    this.onReadyTheme();
  }

  void onReadyTheme() async {
    /// 初始主题
    Map _theme = await ThemeUtil().ready(context);
    setState(() => theme = _theme);
  }

  /// 打开引导
  void _opEnGuide() {
    UrlUtil().opEnWebView('/guide');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text("支援"),
      ),
      body: ListView(
        children: <Widget>[
          EluiCellComponent(
            title: "引导",
            theme: EluiCellTheme(
              titleColor: theme["text"]["subtitle"],
              labelColor: theme["text"]["subtext1"],
              linkColor: theme["text"]["subtitle"],
              backgroundColor: theme['card']['color'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
            islink: true,
            onTap: () => this._opEnGuide(),
          ),
          EluiCellComponent(
            title: "反馈群 (612949946)",
            label: "和作者更加接近呢",
            theme: EluiCellTheme(
              titleColor: theme["text"]["subtitle"],
              labelColor: theme["text"]["subtext1"],
              linkColor: theme["text"]["subtitle"],
              backgroundColor: theme['card']['color'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
            islink: true,
            onTap: () => UrlUtil().onPeUrl("https://jq.qq.com/?_wv=1027&k=kXr9z9FE"),
          ),
          EluiCellComponent(
            title: "Github",
            label: "开源地址",
            theme: EluiCellTheme(
              titleColor: theme['text']['subtitle'],
              labelColor: theme['text']['secondary'],
              linkColor: theme["text"]["subtitle"],
              backgroundColor: theme['index_home']['card']['backgroundColor'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
            islink: true,
            onTap: () => _urlUtil.onPeUrl("https://github.com/BFBAN/bfban-app"),
          ),
          EluiCellComponent(
            title: "捐赠",
            label: "向BFBAN APP开发者捐赠人民币",
            theme: EluiCellTheme(
              titleColor: theme['text']['subtitle'],
              labelColor: theme['text']['secondary'],
              linkColor: theme["text"]["subtitle"],
              backgroundColor: theme['index_home']['card']['backgroundColor'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
            islink: true,
            onTap: () => _urlUtil.onPeUrl("https://cabbagelol.net/%e6%8d%90%e5%8a%a9/"),
          ),
          SizedBox(
            height: 20,
          ),
          EluiCellComponent(
            title: "内部",
            theme: EluiCellTheme(
              labelColor: theme['text']['secondary'],
              backgroundColor: Colors.transparent,
              linkColor: theme["text"]["subtitle"],
              titleColor: theme['text']['subtitle'] ?? Colors.white38,
            ),
          ),
          EluiCellComponent(
            title: "BFBAN WEB 接口",
            label: "app.bfban.com / bf.bamket.com",
            theme: EluiCellTheme(
              titleColor: theme['text']['subtitle'],
              labelColor: theme['text']['secondary'],
              linkColor: theme["text"]["subtitle"],
              backgroundColor: theme['index_home']['card']['backgroundColor'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
          ),
          EluiCellComponent(
            title: "第三方 (我们无法管控的数据)",
            theme: EluiCellTheme(
              labelColor: theme['text']['secondary'],
              backgroundColor: Colors.transparent,
              linkColor: theme["text"]["subtitle"],
              titleColor: theme['text']['subtitle'] ?? Colors.white38,
            ),
          ),
          EluiCellComponent(
            title: "TRN",
            label: "battlefieldtracker.com",
            theme: EluiCellTheme(
              titleColor: theme['text']['subtitle'],
              labelColor: theme['text']['secondary'],
              backgroundColor: theme['index_home']['card']['backgroundColor'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
          ),
          EluiCellComponent(
            title: "@Lv_Aini",
            label: "record.huiyi.sc.cn",
            theme: EluiCellTheme(
              titleColor: theme['text']['subtitle'],
              labelColor: theme['text']['secondary'],
              backgroundColor: theme['index_home']['card']['backgroundColor'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
          ),
          EluiCellComponent(
            title: "@Lv_Ainio",
            label: "api.tracker.gg",
            theme: EluiCellTheme(
              titleColor: theme['text']['subtitle'],
              labelColor: theme['text']['secondary'],
              backgroundColor: theme['index_home']['card']['backgroundColor'] ?? Color.fromRGBO(255, 255, 255, .07),
            ),
          ),
        ],
      ),
    );
  }
}
