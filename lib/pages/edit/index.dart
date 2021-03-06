/// 举报页面

import 'dart:core';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fluro/fluro.dart';
import 'package:flutter_plugin_elui/elui.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:bfban/router/router.dart';
import 'package:bfban/utils/index.dart';
import 'package:bfban/constants/api.dart';
import 'package:bfban/constants/theme.dart';
import 'package:bfban/widgets/index.dart';
import 'package:bfban/widgets/edit/ImageRadioController.dart';
import 'package:bfban/widgets/edit/gameTypeRadio.dart';
import 'package:bfban/widgets/detail/cheatersCardTypes.dart' show detailApi;

class editPage extends StatefulWidget {
  final data;

  editPage({
    this.data,
  });

  @override
  _editPageState createState() => _editPageState();
}

class _editPageState extends State<editPage> {
  Map theme = THEMELIST['none'];

  ImageRadioController controller;

  int gameTypeIndex = 1;

  List reportInfoCheatMethods = new List();

  bool reportInfoUserNameIsBool = false;

  bool reportInfoUserNameLoad = false;

  List games = [
    {
      "img": "assets/images/edit/battlefield-1-logo.png",
      "value": "bf1",
    },
    {
      "img": "assets/images/edit/battlefield-v-png-logo.png",
      "value": "bfv",
    },
  ];

  Map<String, dynamic> reportInfo = {
    "originId": "",
    "gameName": "",
    "cheatMethods": "",
    "description": "",
    "bilibiliLink": "",
  };

  Map videoInfo = {
    "value": "",
    "videoIndex": 0,
    "links": [
      {
        "value": 0,
        "s": "https://www.bilibili.com/video/",
        "content": "原地址",
        "placeholder": "http(s)://",
      },
      {
        "value": 1,
        "S": "",
        "content": "BiliBili",
        "placeholder": "AV/BV",
      },
    ],
  };

  List images = [
    "https://file03.16sucai.com/2016/10/1100/16sucai_p20161017095_34f.JPG",
    "https://file03.16sucai.com/2016/10/1100/16sucai_p20161017095_34f.JPG",
    "https://file03.16sucai.com/2016/10/1100/16sucai_p20161017095_34f.JPG",
  ];

  List _cheatingTpyes = new List();

  String valueCaptcha = "";

  String CaotchaCookie = "";

  static Map<String, bool> valueCaptchaState = {
    "load": false,
    "first": false,
  };

  @override
  void initState() {
    super.initState();

    controller = new ImageRadioController();

    setState(() {
      reportInfo["gameName"] = games[0]["value"];
      reportInfo["originId"] = jsonDecode(widget.data)["originId"];
      Config.cheatingTpyes.forEach((key, value) {
        _cheatingTpyes.add({
          "name": value,
          "value": key,
          "select": false,
        });
      });
    });

    this.onReadyTheme();
  }

  void onReadyTheme() async {
    /// 初始主题
    Map _theme = await ThemeUtil().ready(context);
    setState(() => theme = _theme);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// 更新验证码
  void _getCaptcha() async {
    var t = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      valueCaptchaState = {
        "load": true,
        "first": true,
      };
    });

    Response<dynamic> result = await Http.request(
      'api/captcha?r=${t}',
      method: Http.GET,
    );

    result.headers['set-cookie'].forEach((i) {
      CaotchaCookie += i + ';';
    });

    setState(() {
      valueCaptcha = result.data;
      valueCaptchaState["load"] = false;
    });
  }

  /// 验证用户是否存在
  dynamic _getIsUser() async {
    setState(() {
      reportInfoUserNameLoad = true;
    });

    if (reportInfo["originId"] == "" || reportInfo["originId"].toString().length <= 0) {
      EluiMessageComponent.warning(context)(
        child: Text("举报这ID不存在,请检查用户ID是否填写正确"),
      );
      setState(() {
        reportInfoUserNameLoad = false;
      });
      return;
    }

    Response result = await Http.request(
      'api/checkGameIdExist',
      headers: {'Cookie': this.CaotchaCookie},
      data: {
        "id": reportInfo["originId"],
      },
      method: Http.POST,
    );

    /// 提交预判
    /// 这里返回的结构不一样，否则程序异常抛出错误
    if (result.data["error"] == -2) {
      EluiMessageComponent.warning(context)(
        child: Text("身份过期"),
      );
      return 1;
    }

    if (!result.data["idExist"]) {
      EluiMessageComponent.warning(context)(
        child: Text("举报这ID不存在,请检查用户ID是否填写正确"),
      );
      return 1;
    }

    var data = result.data;

    setState(() {
      reportInfo["avatarLink"] = data["avatarLink"];
      reportInfo["originPersonaId"] = data["originPersonaId"];
      reportInfo["originUserId"] = data["originUserId"];

      /// 更改检测状态
      reportInfoUserNameIsBool = true;
      reportInfoUserNameLoad = false;
    });

    return 0;
  }

  /// 提交前验证
  bool _onVerification() {
    if (reportInfo["cheatMethods"] == "") {
      EluiMessageComponent.warning(context)(
        child: Text("至少选择一个作弊方式"),
      );
      return false;
    }

    if (reportInfo["description"] == "") {
      EluiMessageComponent.warning(context)(
        child: Text("至少填写描述内容, 有力的证据"),
      );
      return false;
    }

    if (reportInfo["bilibiliLink"] == "") {
      EluiMessageComponent.warning(context)(
        child: Text("填写有效的举报视频"),
      );
      return false;
    }

    return true;
  }

  /// 提交举报
  void _onCheaters() async {
    num _is;
    String _token = jsonDecode(await Storage.get("com.bfban.token"));

    /// 是否检测过。 避免重复检测
    if (!reportInfoUserNameIsBool) {
      _is = await this._getIsUser();

      if (_is == 1) {
        return;
      }
    }

    if (!this._onVerification()) {
      return;
    }

    Response<dynamic> result = await Http.request(
      'api/cheaters/',
      headers: {
        "token": _token,
      },
      parame: reportInfo,
      method: Http.GET,
    );

    if (result.data["error"] > 0) {
      EluiMessageComponent.warning(context)(
        child: Text("至少填写描述内容, 有力的证据"),
      );
    } else if (result.data["error"] == 0) {
      EluiMessageComponent.success(context)(
        child: Text("发布成功"),
      );
      UrlUtil().opEnPage(context, "/edit/publishResultsPage");
    }
  }

  /// 修改举报游戏类型
  void _setGamesIndex(num index) {
    setState(() {
      gameTypeIndex = index;

      reportInfo["gameName"] = games[gameTypeIndex]["value"];
    });
  }

  /// 复选举报游戏作弊行为
  List<Widget> _setCheckboxIndex(Map theme) {
    List<Widget> list = new List();
    String _value = "";
    num _valueIndex = 0;

    _cheatingTpyes.forEach((element) {
      list.add(
        gameTypeRadio(
          theme,
          index: element["select"],
          child: Text(
            element["name"],
            style: TextStyle(
              fontSize: 14,
              color: element["select"] ? theme['text']['subtitle'] : theme['text']['subtext1'] ?? Colors.white,
            ),
          ),
          onTap: () {
            setState(() {
              element["select"] = element["select"] != true;

              if (element["select"]) {
                reportInfoCheatMethods.add(element["value"]);
              } else {
                reportInfoCheatMethods.remove(element["value"]);
              }

              reportInfoCheatMethods.forEach((element) {
                _value += element + (_valueIndex >= reportInfoCheatMethods.length - 1 ? "" : ",");
                _valueIndex += 1;
              });

              reportInfo["cheatMethods"] = _value;
            });
          },
        ),
      );
    });

    return list;
  }

  /// 打开编辑页面
  void _opEnRichEdit() async {
    dynamic data = jsonEncode({
      "html": Uri.encodeComponent(reportInfo["description"]),
    });

    Routes.router.navigateTo(context, '/richedit/$data', transition: TransitionType.cupertino).then((data) {
      /// 按下确认储存富文本编写的内容
      if (data["code"] == 1) {
        setState(() {
          reportInfo["description"] = data["html"];
        });
      }
    });
  }

  /// 提交
  void _onSubmit() {
    if (!this._onVerification()) {
      return;
    }

    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          backgroundColor: Colors.white,
          children: <Widget>[
            new SimpleDialogOption(
              child: Column(
                children: <Widget>[
                  Text('\u53d1\u5e03'),
                  Text(
                    '\u5c06\u4e3e\u62a5\u0049\u0044\u53d1\u5e03\u5230\u0042\u0046\u0042\u0041\u004e\u4e0a',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              onPressed: () {
                if (reportInfo["captcha"] == "") {
                  EluiMessageComponent.warning(context)(
                    child: Text("请填写验证码"),
                  );
                  return;
                }

                this._onCheaters();
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Column(
                children: <Widget>[
                  Text('草稿箱'),
                  Text(
                    '储存到草稿箱,不会被发布',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              onPressed: () async {
                List _drafts = jsonDecode(await Storage.get("drafts"));
                reportInfo["date"] = DateTime.now().millisecondsSinceEpoch;
                if (_drafts.length >= 0) {
                  List.generate(_drafts.length, (index) {
                    if (reportInfo["originId"] == _drafts[index]["originId"]) {
                      _drafts.removeAt(index);
                    }
                  });
                }
                _drafts.add(reportInfo);
                Storage.set(
                  "drafts",
                  value: jsonEncode(_drafts ?? []),
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          "\u4e3e\u62a5\u4f5c\u5f0a",
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.done),
            onPressed: () => _onSubmit(),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          EluiCellComponent(
            title: "草稿箱",
            label: "副本",
            isBotton: true,
            theme: EluiCellTheme(
                backgroundColor: theme['card']['color'] ?? Colors.transparent,
                titleColor: theme['text']['subtitle'] ?? Colors.white,
                labelColor: theme['text']['subtext1']),
            cont: Icon(
              Icons.inbox,
              color: theme['text']['subtitle'] ?? Colors.white,
              size: 24,
            ),
            onTap: () {
              Routes.router.navigateTo(context, '/drafts', transition: TransitionType.cupertino).then((value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  reportInfo = value;
                });
              });
            },
          ),
          SizedBox(
            height: 10,
          ),

          /// S 游戏

          EluiCellComponent(
            title: "游戏",
            theme: EluiCellTheme(
              backgroundColor: theme['card']['color'] ?? Color(0xff111b2b),
              titleColor: theme['text']['subtitle'] ?? Colors.white,
              labelColor: theme['text']['subtext1'],
            ),
            cont: ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Container(
                color: theme['card']['secondary'] ?? Colors.black38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List<dynamic>.from(Config.game["type"]).asMap().keys.map((index) {
                    return Expanded(
                      flex: 1,
                      child: gameTypeRadio(
                        theme,
                        index: gameTypeIndex == index,
                        child: Image.asset(
                          Config.game["type"][index]["img"]["file"],
                          height: 18,
                        ),
                        onTap: () => this._setGamesIndex(index),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          /// E 游戏

          SizedBox(
            height: 10,
          ),

          /// S 游戏ID
          Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              bottom: 5,
              right: 20,
            ),
            color: theme['card']['color'] ?? Color(0xff111b2b),
            child: Column(
              children: <Widget>[
                Text(
                  reportInfo["originId"] == "" ? "USER ID" : "" + reportInfo["originId"].toString(),
                  style: TextStyle(
                    color: reportInfo["originId"] == ""
                        ? theme['text']['subtext3'] ?? Colors.white12
                        : theme['text']['subtitle'] ?? Colors.white,
                    fontSize: 30,
//                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
                Offstage(
                  offstage: reportInfo["originId"].toString().length > 0,
                  child: Wrap(
                    spacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.warning,
                        color: Colors.yellow,
                        size: 15,
                      ),
                      Text(
                        "请填写作弊者人名称",
                        style: TextStyle(
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    reportInfoUserNameLoad ? "检查用户是否存在..." : (reportInfoUserNameIsBool ? "已通过检查" : "检查用户id是否举报正确"),
                    style: TextStyle(
                      color: reportInfoUserNameIsBool ? Colors.lightGreen : theme['text']['subtext3'] ?? Colors.white12,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: theme['card']['color'] ?? Color(0xff111b2b),
            child: EluiInputComponent(
              title: "游戏ID",
              value: reportInfo["originId"],
              theme: EluiInputTheme(
                textStyle: TextStyle(
                  color: theme['text']['subtitle'] ?? Colors.white,
                ),
              ),
              placeholder: "输入作弊玩家游戏ID",
              onChange: (data) {
                setState(() {
                  reportInfo["originId"] = data["value"];
                });
              },
            ),
          ),

          /// E 游戏ID

          SizedBox(
            height: 10,
          ),

          /// S 作弊方式
          EluiCellComponent(
            title: "作弊方式",
            theme: EluiCellTheme(
              backgroundColor: theme['card']['color'] ?? Colors.transparent,
              titleColor: theme['text']['subtitle'] ?? Colors.white,
              labelColor: theme['text']['subtext1'],
            ),
            cont: Offstage(
              offstage: reportInfo["cheatMethods"].toString().length > 0,
              child: Wrap(
                spacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.warning,
                    color: Colors.yellow,
                    size: 15,
                  ),
                  Text(
                    "请至少选择一下举报行为",
                    style: TextStyle(
                      color: Colors.yellow,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: theme['card']['color'],
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: this._setCheckboxIndex(theme),
            ),
          ),

          /// E 作弊方式

          SizedBox(
            height: 10,
          ),

          /// S 视频链接
          Container(
            color: theme['card']['color'],
            child: EluiInputComponent(
              title: "视频链接",
              theme: EluiInputTheme(
                textStyle: TextStyle(
                  color: theme['text']['subtitle'] ?? Colors.white,
                ),
              ),
              onChange: (data) {
                reportInfo["bilibiliLink"] = data["value"];
              },
              placeholder: videoInfo["links"][videoInfo["videoIndex"]]["placeholder"],
              right: Row(
                children: <Widget>[
                  DropdownButton(
                    dropdownColor: theme['card']['prominent'] ?? Colors.black,
                    style: TextStyle(color: theme['text']['subtitle'] ?? Colors.white),
                    onChanged: (index) {
                      setState(() {
                        videoInfo["videoIndex"] = index;
                      });
                    },
                    value: this.videoInfo["videoIndex"],
                    items: this.videoInfo["links"].map<DropdownMenuItem>((value) {
                      return DropdownMenuItem(
                        value: value["value"],
                        child: Text(
                          value["content"],
                          style: TextStyle(
                            color: theme['text']['subtitle'] ?? Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Icon(
                    Icons.info,
                    color: theme['text']['subtext3'] ?? Colors.white12,
                  ),
                ],
              ),
            ),
          ),

          /// E 视频链接

          SizedBox(
            height: 10,
          ),

          /// S 理由
          EluiCellComponent(
            theme: EluiCellTheme(
              titleColor: theme['text']['subtitle'],
              backgroundColor: theme['card']['color'] ?? Colors.transparent,
            ),
            title: "理由",
            cont: Offstage(
              offstage: reportInfo["description"].toString().length > 0,
              child: Wrap(
                spacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.warning,
                    color: Colors.yellow,
                    size: 15,
                  ),
                  Text(
                    "请填写有力证据的举报内容",
                    style: TextStyle(
                      color: Colors.yellow,
                    ),
                  ),
                ],
              ),
            ),
          ),

          GestureDetector(
            child: Container(
              constraints: BoxConstraints(
                minHeight: 150,
                maxHeight: 280,
              ),
              color: Colors.white,
              padding: EdgeInsets.zero,
              child: Stack(
                children: <Widget>[
                  Html(
                    data: (reportInfo["description"] == null || reportInfo["description"] == "") ? "" : reportInfo["description"],
                    style: detailApi.styleHtml(context),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black54],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      color: Color.fromRGBO(0, 0, 0, 0.2),
                      child: Center(
                        child: Wrap(
                          spacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 20,
                            ),
                            Text(
                              reportInfo["description"].toString().length <= 0 ? "填写理由" : "编辑",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => _opEnRichEdit(),
          ),

          /// E 理由

          SizedBox(
            height: 10,
          ),

          /// S 验证码
          Container(
            color: theme['card']['color'] ?? Color(0xff111b2b),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
            ),
            child: EluiInputComponent(
              title: "验证码",
              Internalstyle: true,
              theme: EluiInputTheme(
                textStyle: TextStyle(
                  color: theme['text']['subtitle'] ?? Colors.white,
                ),
              ),
              onChange: (data) {
                setState(() {
                  reportInfo["captcha"] = data["value"];
                });
              },
              right: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                  ),
                  margin: EdgeInsets.only(
                    left: 10,
                    bottom: 10,
                    top: 10,
                  ),
                  width: 80,
                  height: 40,
                  child: valueCaptchaState["load"]
                      ? ELuiLoadComponent(
                          type: 'line',
                          color: Colors.black,
                          size: 19,
                          lineWidth: 2,
                        )
                      : valueCaptchaState["first"]
                          ? new SvgPicture.string(
                              valueCaptcha,
                            )
                          : Center(
                              child: Text(
                                "获取验证码",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                ),
                onTap: () => this._getCaptcha(),
              ),
              maxLenght: 4,
              placeholder: "输入验证码",
            ),
          ),

          /// E 验证码
        ],
      ),
    );
  }
}
