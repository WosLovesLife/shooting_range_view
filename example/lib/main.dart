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
      theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> sort = ["Explore", "the", "world", "in", "all", 'its', 'diversity'];

  @override
  Widget build(BuildContext context) {
    final items = sort.map((e) => Item(false, data: e)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ShootingBoard(
        items: items,
        bulletBuilder: (context, item, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Opacity(opacity: animation.value != 0 ? 0 : 1, child: child);
            },
            child: _buildItem(context, item, animation),
          );
        },
        targetBuilder: _buildItem,
        transferBuilder: _buildItem,
        onBulletClick: (item) {
          print('bullet ${item.data}');
        },
        onTargetClick: (item) {
          print('target ${item.data}');
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildItem(context, item, animation) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8))),
        margin: const EdgeInsets.only(left: 2, right: 2, top: 2, bottom: 4),
        child: Padding(padding: const EdgeInsets.all(8.0), child: Text(item.data)),
      ),
    );
  }
}
