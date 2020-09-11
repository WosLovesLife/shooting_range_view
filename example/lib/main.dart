import 'package:flutter/material.dart';
import 'package:shooting_range_view/shooting_range_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> sort = [
    "",
    "",
    "",
    ""
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ShootingBoard(
        items: null,
        targetBuilder: null,
        bulletBuilder: null,
        transferBuilder: null,
        onBulletClick: null,
        onTargetClick: null,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
