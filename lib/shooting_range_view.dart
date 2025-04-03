import 'dart:async';

import 'package:flutter/material.dart';

class Item<T> {
  bool selected;
  int? order;
  T data;

  Item(this.selected, {this.order, required this.data});
}

class _Bullet {
  final Item data;
  final GlobalKey key;
  final AnimationController anim;

  _Bullet(this.data, this.key, this.anim);
}

class _Trajectory {
  final Item data;
  final AnimationController anim;
  final RectTween shootingTween;
  final GlobalKey from;
  final GlobalKey to;

  _Trajectory(this.data, this.anim, this.shootingTween, {required this.from, required this.to});
}

class _TargetModel extends ValueNotifier<List<_Bullet>> {
  _TargetModel(List<_Bullet> value) : super(value);

  @override
  void dispose() {
    value.forEach((e) {
      e.anim.dispose();
    });
    super.dispose();
  }

  void addItem(_Bullet data) {
    value.add(data);
    notifyListeners();
  }

  bool removeItem(_Bullet data) {
    data.anim.dispose();
    final flag = value.remove(data);
    notifyListeners();
    return flag;
  }
}

class _TrajectoryModel extends ValueNotifier<List<_Trajectory>> {
  _TrajectoryModel(List<_Trajectory> value) : super(value);

  @override
  void dispose() {
    value.forEach((e) {
      e.anim.dispose();
    });
    super.dispose();
  }

  void addItem(_Trajectory data) {
    value.add(data);
    notifyListeners();
  }

  bool removeItem(_Trajectory data) {
    data.anim.dispose();
    return value.remove(data);
  }
}

const Duration _kAnimDuration = const Duration(milliseconds: 260);
const Duration _kWaitRebuildDelay = const Duration(milliseconds: 150);

typedef Widget BulletWidgetBuilder(BuildContext context, Item item, Animation<double> animation);
typedef void BulletClickCallback(Item item);

class ShootingBoard extends StatefulWidget {
  final List<Item> items;
  final BulletWidgetBuilder targetBuilder;
  final BulletWidgetBuilder bulletBuilder;
  final BulletWidgetBuilder transferBuilder;
  final BulletClickCallback onBulletClick;
  final BulletClickCallback onTargetClick;

  const ShootingBoard({
    super.key,
    required this.items,
    required this.targetBuilder,
    required this.bulletBuilder,
    required this.transferBuilder,
    required this.onBulletClick,
    required this.onTargetClick,
  });

  @override
  _ShootingBoardState createState() => _ShootingBoardState();
}

class _ShootingBoardState extends State<ShootingBoard> with TickerProviderStateMixin {
  GlobalKey _rootKey = GlobalKey();
  _TargetModel _targetModel = _TargetModel([]);
  List<_Bullet> _bullets = [];
  _TrajectoryModel _trajectoryModel = _TrajectoryModel([]);

  @override
  void initState() {
    super.initState();

    final targets = <_Bullet>[];
    widget.items.forEach((e) {
      if (e.selected) {
        targets.add(_Bullet(e, GlobalKey(), AnimationController(vsync: this, duration: _kAnimDuration)));
      }
      _bullets.add(_Bullet(e, GlobalKey(), AnimationController(vsync: this, duration: _kAnimDuration)));
    });
    _targetModel.value = targets;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          key: _rootKey,
          constraints: BoxConstraints(minHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    constraints: BoxConstraints(minHeight: 200),
                    alignment: Alignment.topLeft,
                    child: ProviderWidget(
                      model: _targetModel,
                      builder: (context, model, child) {
                        return Wrap(alignment: WrapAlignment.start, children: _buildTargets());
                      }, child: Container(),
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        List<Widget> children = [];
                        for (int i = 0; i < (constraints.maxHeight / 56).floor(); i++) {
                          children.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 55.0),
                              child: Divider(height: 2, thickness: 1.5, color: Theme.of(context).disabledColor),
                            ),
                          );
                        }
                        return Column(mainAxisSize: MainAxisSize.min, children: children);
                      },
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.bottomLeft,
                constraints: BoxConstraints(minHeight: 200),
                child: Wrap(alignment: WrapAlignment.start, children: _buildBullets()),
              ),
            ],
          ),
        ),
        ProviderWidget(
          model: _trajectoryModel,
          builder: (context, model, child) {
            return Positioned.fill(
              child: Stack(
                children:
                    (model as _TrajectoryModel).value.where((e) => e.anim.isAnimating).map((e) {
                      return AnimatedBuilder(
                        animation: e.anim,
                        builder: (context, child) {
                          if (e.anim.isCompleted || e.anim.isDismissed) {
                            return SizedBox.shrink();
                          }
                          final curve = CurvedAnimation(parent: e.anim, curve: Curves.fastOutSlowIn);
                          Rect rect;
                          if (e.anim.status == AnimationStatus.forward) {
                            try {
                              final t = RectTween(begin: _getRect(e.from), end: _getRect(e.to));
                              rect = curve.drive<Rect>(t as Animatable<Rect>).value;
                            } catch (exe, s) {
                              FlutterError.reportError(
                                FlutterErrorDetails(exception: exe, stack: s, library: runtimeType.toString()),
                              );
                              rect = e.shootingTween.animate(curve).value??Rect.zero;
                            }
                          } else {
                            rect = e.shootingTween.animate(curve).value??Rect.zero;
                          }
                          return Positioned.fromRect(rect: rect, child: child!);
                        },
                        child: widget.transferBuilder(context, e.data, e.anim),
                      );
                    }).toList(),
              ),
            );
          }, child: Container(),
        ),
      ],
    );
  }

  List<Widget> _buildTargets() {
    return _targetModel.value.map((target) {
      Widget child = _Tap(
        child: AnimatedBuilder(
          animation: target.anim,
          builder: (context, child) {
            return Opacity(opacity: target.anim.value, child: child);
          },
          child: widget.targetBuilder(context, target.data, target.anim),
        ),
        onTap: () async {
          if (target.anim.isAnimating || target.anim.isDismissed) return;
          final bullet = _bullets.firstWhere((e) => e.data == target.data);
          final traA = AnimationController(vsync: this, duration: _kAnimDuration);
          final traT = RectTween(begin: _getRect(bullet.key), end: _getRect(target.key));
          final tra = _Trajectory(target.data, traA, traT, from: bullet.key, to: target.key);
          _trajectoryModel.addItem(tra);
          traA.reverse(from: traA.upperBound);
          target.anim.reverse(from: target.anim.upperBound);

          late AnimationStatusListener statusListener;
          statusListener = (status) {
            if (target.anim.isDismissed) {
              target.anim.removeStatusListener(statusListener);
              _targetModel.removeItem(target);
              bullet.anim.value = bullet.anim.lowerBound;
            }
          };
          target.anim.addStatusListener(statusListener);

          widget.onTargetClick(target.data);
        },
      );

      return AnimatedBuilder(
        key: target.key,
        animation: target.anim,
        builder: (context, child) {
          if (target.anim.status == AnimationStatus.reverse) {
            return SizeTransition(
              sizeFactor: target.anim,
              axis: Axis.horizontal,
              child: Opacity(opacity: 0, child: child),
            );
          }
          return child!;
        },
        child: child,
      );
    }).toList();
  }

  List<Widget> _buildBullets() {
    return _bullets.map((_Bullet bullet) {
      return _Tap(
        key: bullet.key,
        child: widget.bulletBuilder(context, bullet.data, bullet.anim),
        onTap: () async {
          if (bullet.anim.isAnimating || bullet.anim.isCompleted) return;
          final targetAnim = AnimationController(vsync: this, duration: _kAnimDuration);
          final target = _Bullet(bullet.data, GlobalKey(), targetAnim);
          // 先重构布局得到最新的目标位置
          _targetModel.addItem(target);

          // 等待重构布局
          await Future.delayed(_kWaitRebuildDelay);

          bullet.anim.forward();
          final traA = AnimationController(vsync: this, duration: _kAnimDuration);
          final traT = RectTween(begin: _getRect(bullet.key), end: _getRect(target.key));
          final tra = _Trajectory(bullet.data, traA, traT, from: bullet.key, to: target.key);
          _trajectoryModel.addItem(tra);
          traA.forward();
          late AnimationStatusListener statusListener;
          statusListener = (status) {
            if (traA.isCompleted) {
              traA.removeStatusListener(statusListener);
              targetAnim.value = targetAnim.upperBound;
            }
          };
          traA.addStatusListener(statusListener);

          widget.onBulletClick(bullet.data);
        },
      );
    }).toList();
  }

  Rect _getRect(GlobalKey key) {
    RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    Offset? toLocation = renderBox?.localToGlobal(Offset.zero, ancestor: _rootKey.currentContext?.findRenderObject());
    final toSize = renderBox?.paintBounds;
    return Rect.fromLTWH(toLocation?.dx??0, toLocation?.dy??0, toSize?.width??0, toSize?.height??0);
  }
}

class _Tap extends StatelessWidget {
  final Widget child;
  final GestureTapCallback onTap;

  const _Tap({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: child,
      onTap: onTap,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}

typedef ProviderWidgetBuilder<T>(BuildContext context, T model, Widget child);

class ProviderWidget<E> extends StatefulWidget {
  final E model;
  final ProviderWidgetBuilder<Object> builder;
  final Widget child;

  const ProviderWidget({super.key, required this.model, required this.builder, required this.child});

  @override
  _ProviderWidgetState createState() => _ProviderWidgetState();
}

class _ProviderWidgetState extends State<ProviderWidget> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelChanged);
    super.dispose();
  }

  void _onModelChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.model, widget.child);
  }
}
