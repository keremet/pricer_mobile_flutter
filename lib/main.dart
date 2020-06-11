import 'package:flutter/material.dart';
import 'dart:async';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const String prop_login = "login";
const String prop_passwd = "passwd";
const String prop_buyer_login = "buyer_login";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ценовичок',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = "";
  String _login = "";
  String _buyerLogin = "";
  List<String> _scanList = List();
  int _selectedScanIdx = -1;

  static const String _prop_scanlist = "scanlist";

  _saveScanList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setStringList(_prop_scanlist, _scanList);
    });
  }

  Future scan() async {
    try {
      String qrCode = await BarcodeScanner.scan(flash:true);
      if( _scanList.indexOf(qrCode) >=0 )
      {
        setState(() {
          this._status = 'Чек есть в списке отсканированных';
        });
      }
      else
      {
        _scanList.add(qrCode);
        _saveScanList();
        setState(() {
          this._status = 'Чек отсканирован';
        });
      }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this._status = 'Нет прав на доступ к камере!';
        });
      } else {
        setState(() => this._status = 'Неизвестная ошибка: $e');
      }
    } on FormatException{
      //setState(() => this.barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      setState(() => this._status = 'Неизвестная ошибка: $e');
    }
  }

  _btnSendPressed() async {
    if( _scanList.length == 0 ) {
      setState(() { _status = 'Нет чеков для отправки'; });
      return;
    }

    if( _login.isEmpty ) {
      setState(() { _status = 'Введите логин в настройках'; });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String passwd = prefs.getString (prop_passwd);
    if( passwd == null || passwd.isEmpty ) {
      setState(() { _status = 'Введите пароль в настройках'; });
      return;
    }

    setState(() { _status = 'Ожидание ответа сервера'; });
    String codes = "";
    for( var qrCode in _scanList)
    {
      codes += qrCode + ';';
    }
    try {
      var response = await http.post("http://orv.org.ru/pricer/api/receipt/send.php?v=190615&login="+_login+"&passwd="+passwd+"&buyer_login="+_buyerLogin,
          body: codes);

      setState(() {
        if( 200 == response.statusCode ) {
          _status = response.body;
        } else {
          _status = "Код ответа ${response.statusCode}. " + response.body;
        }
      });
    } catch (error) {
      setState(() { _status = "Ошибка отправки " + error.toString(); });
    }
  }

  String getReadableScan(String s)
  {
    String out = "";
    List<String> list = s.split("&");
    for(var part in list) {
      if (part.startsWith("t=") && part.length >= 15) {
        out = part.substring(8, 10) + "." + part.substring(6, 8) + "." + part.substring(4, 6)
            + " " + part.substring(11, 13) + ":" + part.substring(13, 15);
        break;
      }
    }
    for(var part in list) {
      if (part.startsWith("s=") && part.length > 2) {
        out += " " + part.substring(2);
        break;
      }
    }
    return out;
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _buyerLogin = prefs.getString (prop_buyer_login) ?? "";
      _login = prefs.getString (prop_login) ?? "";
      _scanList = (prefs.getStringList(_prop_scanlist) ?? List());
    });
  }

  _deleteAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.remove(_prop_scanlist);
    });
  }

  @override
  Widget build(BuildContext context) {
    _loadSettings();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            Row(
                children: <Widget>[
                  RaisedButton(
                    onPressed:  () {
                      if(_selectedScanIdx == -1)
                      {
                        setState(() {
                          this._status = 'Не выбран чек для удаления';
                        });
                        return;
                      }
                      _scanList.removeAt(_selectedScanIdx);
                      _selectedScanIdx = -1;
                      _saveScanList();
                      setState(() {
                        this._status = 'Чек удален';
                      });
                    },
                    child: const Text('Удалить', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 15),
                  RaisedButton(
                    onPressed: _deleteAll,
                    child: const Text('Удалить все', style: TextStyle(fontSize: 15)),
                  ),
                  Expanded(
                      child: Center(
                          child: Text( _buyerLogin.isNotEmpty ? _buyerLogin : _login, style: TextStyle(fontSize: 15))
                      )
                  )
                ]
            ),
            Text(_status, textAlign: TextAlign.center,),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                    itemCount:_scanList.length,
                    shrinkWrap: true,
                    itemBuilder: (context, i){
                      return new ListTile(
                          selected: i == _selectedScanIdx,
                          title: new Text(getReadableScan(_scanList[i])),
                          subtitle: Text(_scanList[i]),
                          onTap: (){
                            setState(() => this._selectedScanIdx = i);
                          },
                      );
                    })
              ),
            ),
            Row(
                children: <Widget>[
                  RaisedButton(
                    onPressed: scan,
                    child: const Text('Сканировать', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 15),
                  RaisedButton(
                    onPressed: _btnSendPressed,
                    child: const Text('Отправить', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 15),
                  RaisedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsScreen()),
                      );
                    },
                    child: const Text('Настройки', style: TextStyle(fontSize: 15)),
                  ),
                ]
            ),
          ],
        ),
      ),
    );
  }
}
/////////////////////////////

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsState createState() => new _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  @override
  initState() {
    super.initState();
    _loadSettings();
  }

  var loginTxt = new TextEditingController();
  var passwdTxt = new TextEditingController();
  var buyerLoginTxt = new TextEditingController();

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loginTxt.text = (prefs.getString (prop_login) ?? "");
      passwdTxt.text = (prefs.getString (prop_passwd) ?? "");
      buyerLoginTxt.text = (prefs.getString (prop_buyer_login) ?? "");
    });
  }

  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(prop_login, loginTxt.text);
    prefs.setString(prop_passwd, passwdTxt.text);
    prefs.setString(prop_buyer_login, buyerLoginTxt.text);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Retrieve the text the that user has entered by using the
          // TextEditingController.
          content: Text("Настройки сохранены"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text('Настройки'),
        ),
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: loginTxt,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Логин',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwdTxt,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Пароль',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: buyerLoginTxt,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Логин покупателя',
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: RaisedButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    splashColor: Colors.blueGrey,
                    onPressed: () {
                      _saveSettings();
                    },
                    child: const Text('Сохранить')
                ),
              )
            ],
          ),
        ));
  }
}
