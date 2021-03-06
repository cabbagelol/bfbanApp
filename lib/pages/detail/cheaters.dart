/// 举报信息详情

import 'dart:convert';
import 'dart:async';

import 'package:bfban/constants/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluro/fluro.dart';
import 'package:flutter_plugin_elui/elui.dart';
import 'package:provider/provider.dart';

import 'package:bfban/constants/api.dart';
import 'package:bfban/router/router.dart';
import 'package:bfban/utils/index.dart';
import 'package:bfban/widgets/index.dart';

class CheatersPage extends StatefulWidget {
  /// BFBAN举报iD
  final id;

  CheatersPage({
    this.id = "",
  });

  @override
  _CheatersPageState createState() => _CheatersPageState();
}

class _CheatersPageState extends State<CheatersPage> with SingleTickerProviderStateMixin {
  ScrollController _scrollController = new ScrollController();

  Map theme = THEMELIST['none'];

  /// 作弊者结果
  Map cheatersInfo = Map();

  /// 作弊者基本信息
  /// 从[cheatersInfo]取的结果，方便取
  Map cheatersInfoUser = Map();

  /// 异步
  Future futureBuilder;

  /// TAB导航控制器
  TabController _tabController;

  /// 导航下标
  int _tabControllerIndex = 0;

  int _ClistLenght = 0;

  /// 导航个体
  List<Tab> cheatersTabs = <Tab>[];

  /// 作弊行为
  static Map cheatingTpyes = Config.cheatingTpyes;

  /// 进度状态
  final List<dynamic> startusIng = Config.startusIng;

  static Map _login = {};

  /// 曾用名按钮状态 or 列表状态
  Map userNameList = {
    "buttonLoad": false,
    "listLoad": false,
  };

  /// 举报记录
  Widget cheatersRecordWidgetList = Container();

  @override
  void initState() {
    super.initState();
    this.ready();
    this.onReadyTheme();
  }

  void onReadyTheme() async {
    /// 初始主题
    Map _theme = await ThemeUtil().ready(context);
    setState(() => theme = _theme);
  }

  void ready() async {
    _login = jsonDecode(await Storage.get('com.bfban.login') ?? '{}');
    _tabController = TabController(vsync: this, length: cheatersTabs.length)
      ..addListener(() {
        setState(() {
          _tabControllerIndex = _tabController.index;
        });
      });
    futureBuilder = this._getCheatersInfo();
  }

  /// 获取bfban用户信息
  Future _getCheatersInfo() async {
    Response result = await Http.request(
      'api/cheaters/${widget.id}',
      method: Http.GET,
    );

    if (result.data["error"] == 0) {
      setState(() {
        cheatersInfo = result.data ?? new Map();
        cheatersInfoUser = result.data["data"]["cheater"].length > 0 ? result.data["data"]["cheater"][0] : {};
      });

      /// 取最新ID查询
      if (result.data["data"]["origins"].length > 0) {
//        this._getTrackerCheatersInfo(result.data["data"]["origins"][0]["cheaterGameName"], result.data["data"]["games"]);
      }

      this._getUserInfo();
      return cheatersInfo;
    } else {
      EluiMessageComponent.error(context)(child: Text("获取失败, 结果: " + (result.data["error"] ?? '-1') + result.data.toString()));
    }
  }

  /// 评论刷新事件
  Future<Null> _onRefresh() async {
    await Future.delayed(Duration(seconds: 1), () async {
      await this._getCheatersInfo();

      return true;
    });
  }

  /// 获取游戏类型
  String _getGames(List games) {
    String t = "";
    games.forEach((element) {
      t += "${element["game"].toString().toUpperCase()} ";
    });
    return t;
  }

  /// 评论内回复
  void _onReplySucceed(value) async {
    if (value == null) {
      return;
    }
    this._scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  /// 赞同决议
  /// data举报者信息 R单条评论
  void _setConfirm(context, data, R) async {
    Response result = await Http.request(
      'api/cheaters/confirm',
      data: Map.from({
        "userVerifyCheaterId": data["id"],
        "cheatMethods": R["cheatMethods"],
        "userId": R["userId"], //_login["userId"]
        "originUserId": data["originUserId"],
      }),
      method: Http.POST,
    );

    if (result.data["error"] == 0) {
      EluiMessageComponent.success(context)(
        child: Text("提交成功"),
      );

      await this._getCheatersInfo();
    } else {
      EluiMessageComponent.error(context)(
        child: Text("提交失败"),
      );
    }
  }

  /// 请求更新用户名称列表
  void _seUpdateUserNameList() async {
    if (userNameList['buttonLoad']) {
      return;
    }

    if (cheatersInfoUser["originUserId"] == "" || cheatersInfoUser["originUserId"] == null) {
      EluiMessageComponent.error(context)(
        child: Text("无法识别ID"),
      );
      return;
    }

    if (_login == null) {
      EluiMessageComponent.error(context)(
        child: Text("请先登录BFBAN"),
      );
      return;
    }

    setState(() {
      userNameList["buttonLoad"] = true;
    });

    Response result = await Http.request(
      'api/cheaters/updateCheaterInfo',
      data: {
        "originUserId": cheatersInfoUser["originUserId"],
      },
      method: Http.POST,
    );

    if (result.data["error"] == 0) {
      this._getCheatersInfo();
    } else {
      EluiMessageComponent.error(context)(
        child: Text("请求异常请联系开发者"),
      );
    }

    setState(() {
      userNameList["buttonLoad"] = false;
    });
  }

  /// 管理员裁判
  dynamic _onAdminEdit(String uid) {
    if (_login == null) {
      EluiMessageComponent.error(context)(
        child: Text("请先登录BFBAN"),
      );
      return null;
    }

    if (_login["userPrivilege"] != 'admin') {
      EluiMessageComponent.error(context)(
        child: Text("该账户非管理员身份"),
      );
      return null;
    }

    Routes.router.navigateTo(context, '/edit/manage/$uid', transition: TransitionType.cupertino).then((value) {
      if (value != null) {
        this._getCheatersInfo();
        this._scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return true;
  }

  /// 用户回复
  dynamic _setReply(num Type) {
    if (_login.containsKey("userPrivilege")) {
      return () {
        /// 补充（追加）回复
        /// 取第一条举报信息下的userId
        String content = jsonEncode({
          "type": Type ?? 0,
          "id": cheatersInfoUser["id"],
          "originUserId": cheatersInfoUser["originUserId"],
          "foo": cheatersInfo["data"]["reports"][0]["username"],
        });

        Routes.router.navigateTo(context, '/reply/$content', transition: TransitionType.cupertino).then((value) {
          if (value != null) {
            this._getCheatersInfo();
            this._scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      };
    }

    return null;
  }

  /// 补充举报用户信息
  dynamic _onReport() {
    if (_login.containsKey("userPrivilege")) {
      return () {
        Routes.router
            .navigateTo(
          context,
          '/edit/${jsonEncode({
            "originId": cheatersInfoUser["originId"],
          })}',
          transition: TransitionType.cupertinoFullScreenDialog,
        )
            .then((value) {
          if (value != null) {
            this._getCheatersInfo();
            this._scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      };
    }

    return null;
  }

  /// 审核人员判决
  dynamic onAdminSentence() {
    if (['admin', 'super'].contains(_login["userPrivilege"])) {
      return () {
        this._onAdminEdit(cheatersInfo["data"]["cheater"][0]["originUserId"]);
      };
    }
    return null;
  }

  /// 获取用户BFBAN中举报数据
  /// Map cheatersInfo, cheatersInfoUser, startusIng
  void _getUserInfo() {
    List<Widget> list = [];

    /// 数据
    Map _data = cheatersInfo["data"];

    /// 所有用户回复信息
    List _allReply = new List();

    /// 回答0,举报1,审核2,赞同。审核员3
    [
      {0: 'replies', 1: 0},
      {0: 'reports', 1: 1},
      {0: 'verifies', 1: 2},
      {0: 'confirms', 1: 3},
    ].forEach((Map i) {
      String name = i[0];
      int index = i[1];
      if (_data.containsKey(name)) {
        _data[name].forEach((item) {
          item["SystemType"] = index;
          _allReply.add(item);
        });
      }
    });

    /// 排序时间帖子
    /// 序列化时间
    _allReply.sort((time, timeing) =>
        new Date().getTurnTheTimestamp(time["createDatetime"])["millisecondsSinceEpoch"] -
        new Date().getTurnTheTimestamp(timeing["createDatetime"])["millisecondsSinceEpoch"]);

    _allReply.asMap().keys.forEach(
      (i) {
        /// 作弊类型 若干
        List<Widget> _cheatMethods = new List();

        _allReply[i]['cheatMethods'].toString().split(",").forEach((i) {
          _cheatMethods.add(EluiTagComponent(
            value: cheatingTpyes[i] ?? '未知行为',
            textStyle: TextStyle(
              fontSize: 9,
              color: Colors.white,
            ),
            size: EluiTagSize.no2,
            color: EluiTagColor.warning,
          ));
        });

        switch (_allReply[i]["SystemType"].toString()) {
          case "0":
            list.add(
              CheatUserCheaters(
                i: _allReply[i],
                index: i += 1,
                cheatMethods: _cheatMethods,
                cheatersInfo: cheatersInfo,
                cheatersInfoUser: cheatersInfoUser,
                onReplySucceed: _onReplySucceed,
              ),
            );
            break;
          case "1":
            list.add(
              CheatReports(
                i: _allReply[i],
                index: i += 1,
                cheatMethods: _cheatMethods,
                cheatersInfo: cheatersInfo,
                cheatersInfoUser: cheatersInfoUser,
                onReplySucceed: _onReplySucceed,
              ),
            );
            break;
          case "2":
            list.add(
              CheatVerifies(
                i: _allReply[i],
                index: i += 1,
                cheatMethods: _cheatMethods,
                cheatersInfo: cheatersInfo,
                cheatersInfoUser: cheatersInfoUser,
                login: _login,
                onConfirm: () => _setConfirm(context, cheatersInfoUser, _allReply[i - 1]),
                onReplySucceed: _onReplySucceed,
              ),
            );
            break;
          case "3":
            list.add(
              CheatConfirms(
                i: _allReply[i],
                index: i += 1,
                cheatMethods: _cheatMethods,
                cheatersInfo: cheatersInfo,
                cheatersInfoUser: cheatersInfoUser,
                onReplySucceed: _onReplySucceed,
              ),
            );
            break;
        }
      },
    );

    setState(() {
      _ClistLenght = list.length;

      cheatersRecordWidgetList = Column(
        children: list,
      );
    });
  }

  /// 查看图片
  void _onEnImgInfo(context) {
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (BuildContext context) {
        return PhotoViewSimpleScreen(
          imageUrl: cheatersInfoUser["avatarLink"],
          imageProvider: NetworkImage(cheatersInfoUser["avatarLink"]),
          heroTag: 'simple',
        );
      },
    ));
  }

  /// 曾经使用过的名称
  static Widget _getUsedname(theme, cheatersInfo) {
    List<DataRow> list = [];

    cheatersInfo["data"]["origins"].asMap().keys.forEach((index) {
      var i = cheatersInfo["data"]["origins"][index];

      list.add(
        new DataRow(
          cells: [
            DataCell(
              Wrap(
                spacing: 5,
                children: [
                  Visibility(
                    visible: index >= cheatersInfo["data"]["origins"].length - 1,
                    child: EluiTagComponent(
                      size: EluiTagSize.no2,
                      theme: EluiTagtheme(
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      ),
                      value: "最新",
                    ),
                  ),
                  SelectableText(
                    i["cheaterGameName"],
                    style: TextStyle(
                      color: theme['text']['subtitle'] ?? Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                new Date().getFriendlyDescriptionTime(i["createDatetime"]),
                style: TextStyle(
                  color: theme['text']['subtitle'] ?? Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    });

    return Container(
      color: theme['card']['color'] ?? Colors.black12,
      child: DataTable(
        sortAscending: true,
        sortColumnIndex: 0,
        columns: [
          DataColumn(
            label: Text(
              "游戏id",
              style: TextStyle(
                color: theme['text']['subtitle'] ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              "获取时间",
              style: TextStyle(
                color: theme['text']['subtitle'] ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        rows: list,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    cheatersTabs = <Tab>[
      Tab(text: '举报信息'),
      Tab(
        child: Wrap(
          spacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("审核记录"),
            EluiTagComponent(
              value: "$_ClistLenght",
              size: EluiTagSize.no2,
              theme: EluiTagtheme(
                textColor: _tabControllerIndex == 1 ? Colors.black : theme["detail_cheaters_tabs_label"]["textColor"],
                backgroundColor: _tabControllerIndex == 1 ? theme["detail_cheaters_tabs_label"]["backgroundColor"] : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    ];

    return FutureBuilder(
      future: this.futureBuilder,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        /// 数据未加载完成时
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Opacity(
                    opacity: 0.8,
                    child: textLoad(
                      value: "BFBAN",
                      fontSize: 30,
                    ),
                  ),
                  Text(
                    "Legion of BAN Coalition",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white38,
                    ),
                  )
                ],
              ),
            ),
          );
        }

        /// 数据完成加载
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: theme['appBar']['flexibleSpace'],
            title: TabBar(
              labelStyle: TextStyle(fontSize: 15),
              controller: _tabController,
              labelPadding: EdgeInsets.only(left: 0, right: 0),
              tabs: cheatersTabs,
            ),
            elevation: 0,
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.open_in_new,
                ),
                onPressed: () {
                  Share().text(
                    title: '联BFBAN分享',
                    text: '走过路过，不要错过咯~ 快乐围观 ${cheatersInfoUser["originId"]} 在联BAN举报信息',
                    linkUrl: 'https://bfban.com/#/cheaters/${cheatersInfoUser["originUserId"]}',
                    chooserTitle: '联BFBAN分享',
                  );
                  Clipboard.setData(
                    ClipboardData(
                      text: 'https://bfban.com/#/cheaters/${cheatersInfoUser["originUserId"]}',
                    ),
                  );
                },
              ),
            ],
            centerTitle: true,
          ),

          /// 内容
          body: DefaultTabController(
            length: cheatersTabs.length,
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      /// S 举报信息
                      ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () => _onEnImgInfo(context),
                            child: Container(
                              margin: EdgeInsets.only(top: 140, right: 10, left: 10, bottom: 50),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Stack(
                                    children: [
                                      Container(
                                        color: Colors.white,
                                        // child: EluiImgComponent(
                                        //   src: cheatersInfoUser["avatarLink"],
                                        //   width: 150,
                                        //   height: 150,
                                        // ),
                                        child: Image.network(
                                          cheatersInfoUser["avatarLink"],
                                          width: 150,
                                          height: 150,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: EdgeInsets.only(top: 40, left: 40, right: 5, bottom: 5),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.transparent,
                                                Colors.transparent,
                                                Colors.black87,
                                              ],
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.search,
                                            color: Colors.white70,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            color: theme['card']['color'] ?? Colors.black12,
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            padding: EdgeInsets.all(10),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 1,
                                  child: Row(
                                    children: <Widget>[
                                      GestureDetector(
                                        child: Icon(
                                          Icons.code,
                                          color: theme['text']['subtitle'] ?? Colors.white,
                                        ),
                                        onTap: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: cheatersInfoUser["originId"],
                                            ),
                                          );
                                          EluiMessageComponent.success(context)(
                                            child: Text("复制成功"),
                                          );
                                        },
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),

                                      /// 用户名称
                                      Expanded(
                                        flex: 1,
                                        child: SelectableText(
                                          cheatersInfoUser["originId"].toString(),
                                          style: TextStyle(
                                            color: theme['text']['subtitle'] ?? Colors.white,
                                            fontSize: 20,
                                            shadows: <Shadow>[
                                              Shadow(
                                                color: Colors.black12,
                                                offset: Offset(1, 2),
                                              )
                                            ],
                                          ),
                                          showCursor: true,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),

                                      /// 最终状态
                                      Container(
                                        padding: EdgeInsets.only(
                                          left: 5,
                                          right: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: startusIng[int.parse(cheatersInfoUser["status"] = "0")]["c"],
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(2),
                                          ),
                                        ),
                                        child: Text(
                                          startusIng[int.parse(cheatersInfoUser["status"] ?? 0)]["s"].toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: startusIng[int.parse(cheatersInfoUser["status"] ?? 0)]["tc"],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            color: theme['card']['color'] ?? Colors.black12,
                            margin: EdgeInsets.only(
                              top: 20,
                              left: 10,
                              right: 10,
                            ),
                            padding: EdgeInsets.only(
                              top: 10,
                              bottom: 10,
                              left: 10,
                              right: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                Container(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        cheatersInfoUser != null
                                            ? new Date().getFriendlyDescriptionTime(cheatersInfoUser["createDatetime"])
                                            : "",
                                        style: TextStyle(
                                          color: theme['text']['subtitle'] ?? Colors.white,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        "第一次举报时间",
                                        style: TextStyle(
                                          color: theme['text']['secondary'] ?? Colors.white54,
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        cheatersInfoUser != null
                                            ? new Date().getFriendlyDescriptionTime(cheatersInfoUser["updateDatetime"])
                                            : "",
                                        style: TextStyle(
                                          color: theme['text']['subtitle'] ?? Colors.white,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        "最后更新",
                                        style: TextStyle(
                                          color: theme['text']['secondary'] ?? Colors.white54,
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            color: theme['card']['color'] ?? Colors.black12,
                            margin: EdgeInsets.only(
                              left: 10,
                              right: 10,
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        cheatersInfoUser != null ? cheatersInfoUser["n"].toString() + "/次" : "",
                                        style: TextStyle(
                                          color: theme['text']['subtitle'] ?? Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "围观",
                                        style: TextStyle(
                                          color: theme['text']['secondary'] ?? Colors.white54,
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                    left: 7,
                                    right: 7,
                                  ),
                                  height: 30,
                                  width: 1,
                                  color: Theme.of(context).dividerColor ?? theme['hr']['secondary'] ?? Colors.white12,
                                ),
                                Container(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        (cheatersInfo["data"]["reports"].length + cheatersInfo["data"]["verifies"].length).toString() +
                                            "/条",
                                        //cheatersInfo["data"]["verifies"]
                                        style: TextStyle(
                                          color: theme['text']['subtitle'] ?? Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "回复",
                                        style: TextStyle(
                                          color: theme['text']['secondary'] ?? Colors.white54,
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                    left: 7,
                                    right: 7,
                                  ),
                                  height: 30,
                                  width: 1,
                                  color: Theme.of(context).dividerColor ?? theme['hr']['secondary'] ?? Colors.white12,
                                ),
                                Container(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        cheatersInfo["data"] != null ? this._getGames(cheatersInfo["data"]["games"]) : "",
                                        style: TextStyle(
                                          color: theme['text']['subtitle'] ?? Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "被举报游戏",
                                        style: TextStyle(
                                          color: theme['text']['secondary'] ?? Colors.white54,
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                    left: 7,
                                    right: 7,
                                  ),
                                  height: 30,
                                  width: 1,
                                  color: Theme.of(context).dividerColor ?? theme['hr']['secondary'] ?? Colors.white12,
                                ),
                                Container(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        "PC",
                                        style: TextStyle(
                                          color: theme['text']['subtitle'] ?? Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "游玩平台",
                                        style: TextStyle(
                                          color: theme['text']['secondary'] ?? Colors.white54,
                                          fontSize: 12,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 10, right: 10, top: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: cheatersInfo["data"]["games"].map<Widget>((i) {
                                var bf = [
                                  {
                                    "f": "bf1,bfv",
                                    "n": "battlefieldtracker",
                                    "url": "https://battlefieldtracker.com/bf1/profile/pc/${cheatersInfoUser["originId"]}"
                                  },
                                  {
                                    "f": "bf1",
                                    "n": "bf1stats",
                                    "url": "http://bf1stats.com/pc/${cheatersInfoUser["originId"]}",
                                  },
                                  {
                                    "f": "bf1,bfv",
                                    "n": "247fairplay",
                                    "url": "https://www.247fairplay.com/CheatDetector/${cheatersInfoUser["originId"]}",
                                  },
                                ];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: bf.map<Widget>((e) {
                                    return Visibility(
                                      visible: e["f"].indexOf(i["game"]) >= 0,
                                      child: GestureDetector(
                                        onTap: () => UrlUtil().onPeUrl(e["url"]),
                                        child: Container(
                                          color: theme['card']['color'] ?? Colors.white,
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Wrap(
                                            spacing: 5,
                                            children: [
                                              Icon(Icons.insert_link, size: 16, color: theme['text']['subtitle']),
                                              Text(
                                                e["n"],
                                                style: TextStyle(
                                                  color: theme['text']['secondary'] ?? Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              left: 10,
                              right: 10,
                              top: 20,
                            ),
                            child: Align(
                              child: FlatButton.icon(
                                color: theme['text']['subtext3'] ?? Colors.black12,
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.refresh,
                                  size: 25,
                                  color: theme['text']['subtitle'] ?? Colors.white,
                                ),
                                textTheme: ButtonTextTheme.primary,
                                label: Text(
                                  userNameList['buttonLoad'] ? "刷新中" : "刷新",
                                  style: TextStyle(
                                    color: theme['text']['subtitle'] ?? Colors.white,
                                  ),
                                ),
                                onPressed: () => this._seUpdateUserNameList(),
                              ),
                              alignment: Alignment.centerRight,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              left: 10,
                              right: 10,
                              bottom: 10,
                            ),
                            child: userNameList['listLoad']
                                ? EluiVacancyComponent(
                                    title: "-",
                                  )
                                : _getUsedname(theme, snapshot.data),
                            margin: EdgeInsets.only(
                              top: 10,
                            ),
                          ),
                        ],
                      ),

                      /// E 举报信息

                      /// S 审核记录
                      RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: Theme.of(context).floatingActionButtonTheme.focusColor ??
                            theme['index_home']['buttonEdit']['textColor'] ??
                            Colors.black,
                        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor ??
                            theme['index_home']['buttonEdit']['backgroundColor'] ??
                            Colors.yellow,
                        child: ListView(
                          controller: _scrollController,
                          children: <Widget>[
                            Container(
                              width: double.maxFinite,
                              height: 1,
                              child: Stack(
                                overflow: Overflow.visible,
                                children: [
                                  Positioned(
                                    top: -150,
                                    left: 0,
                                    right: 0,
                                    child: Text(
                                      "别看啦,真没有了 /(ㄒoㄒ)/~~",
                                      style: TextStyle(color: Colors.white38),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                ],
                              ),
                            ),

                            /// S记录
                            cheatersRecordWidgetList,

                            /// E记录
                          ],
                        ),
                      ),

                      /// E 审核记录
                    ],
                  ),
                ),

                /// E 主体框架
              ],
            ),
          ),

          /// 底栏
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  width: 1.0,
                  color: Colors.black12,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 50,
            child: IndexedStack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: FlatButton(
                        color: Color(0xff111b2b),
                        textColor: Colors.white,
                        disabledColor: Colors.black12,
                        disabledTextColor: Colors.black54,
                        child: Text(
                          "补充证据",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        onPressed: _onReport(),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: FlatButton(
                        color: Color(0xff111b2b),
                        textColor: Colors.white,
                        disabledColor: Colors.black12,
                        disabledTextColor: Colors.black54,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          children: <Widget>[
                            Icon(
                              Icons.message,
                              color: Colors.orangeAccent,
                            ),
                            Text(
                              "回复",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        onPressed: _setReply(0),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        left: 7,
                        right: 7,
                      ),
                      height: 20,
                      width: 1,
                      color: Colors.black12,
                    ),
                    FlatButton(
                      color: Colors.red,
                      textColor: Colors.white,
                      disabledColor: Colors.black12,
                      disabledTextColor: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "判决",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "管理员选项",
                            style: TextStyle(
                              fontSize: 9,
                            ),
                          )
                        ],
                      ),
                      onPressed: onAdminSentence(),
                    ),
                  ],
                ),
              ],
              index: _tabControllerIndex,
            ),
          ),
        );
      },
    );
  }
}

/// WG九宫格
class detailCellCard extends StatelessWidget {
  final text;
  final value;

  detailCellCard({
    this.text = "",
    this.value = "",
  });

  @override
  Widget build(BuildContext context) {
    throw Column(
      children: <Widget>[
        Text(
          text ?? "",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        )
      ],
    );
  }
}

/// WG单元格
class detailCheatersCard extends StatelessWidget {
  final value;
  final cont;
  final type;
  final onTap;
  final fontSize;

  detailCheatersCard({
    this.value,
    this.cont,
    this.type = '0',
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        color: type == '0' ? Color.fromRGBO(0, 0, 0, .3) : Color.fromRGBO(255, 255, 255, .07),
        padding: EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize ?? 20,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$cont',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, .6),
                    fontSize: 13,
                  ),
                )
              ],
            )
          ],
        ),
      ),
      onTap: onTap != null ? onTap : null,
    );
  }
}
