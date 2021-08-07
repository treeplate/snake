import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

final Random random = Random();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SnakeWidget());
  }
}

class SnakeWidget extends StatefulWidget {
  @override
  _SnakeWidgetState createState() => _SnakeWidgetState();
}

class ColorGrid {
  ColorGrid(this.grid, this.width);
  final int width;
  List<Color> grid;
  int get height => grid.length ~/ width;
}

class Direction {
  Direction.w()
      : x = 0,
        y = -1;
  Direction.a()
      : x = -1,
        y = 0;
  Direction.s()
      : x = 0,
        y = 1;
  Direction.d()
      : x = 1,
        y = 0;
  final int x;
  final int y;
  operator ==(Object direction) =>
      direction is Direction && direction.x == x && direction.y == y;
  
  Offset toOffset() => Offset(x.toDouble(), y.toDouble());

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
}

class _SnakeWidgetState extends State<SnakeWidget> {
  _SnakeWidgetState() {
    Timer.periodic(
        Duration(
            milliseconds:
                (0.1 * Duration.millisecondsPerSecond).toInt()),
        onTimerEvent);
  }

  bool _handleKeyPress(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent && !ai) {
      print('Focus node ${node.debugLabel} got key event: ${event.logicalKey}');
      return (<String, bool Function()>{
                LogicalKeyboardKey.arrowUp.toString(): w,
                LogicalKeyboardKey.arrowLeft.toString(): a,
                LogicalKeyboardKey.arrowDown.toString(): s,
                LogicalKeyboardKey.arrowRight.toString(): d,
                LogicalKeyboardKey.space.toString(): () {
                  setState(() {
                    active = !active;
                  });
                  return true;
                }
              }[event.logicalKey.toString()] ??
              () => null)() ??
          false;
    }
    return false;
  }

  bool active = true;
  bool ai = true;
  int highScore = 0;

  void onTimerEvent(Timer timer) {
    if (ai) {
      if (applePos.dy < snakePos.dy && direction != Direction.w() && !(snakeSquares.toList()..remove(snakePos)).contains(snakePos + Direction.w().toOffset()))
        w();
      else if (applePos.dx < snakePos.dx && direction != Direction.a() && !(snakeSquares.toList()..remove(snakePos)).contains(snakePos + Direction.a().toOffset()))
        a();
      else if (applePos.dy > snakePos.dy && direction != Direction.s() && !(snakeSquares.toList()..remove(snakePos)).contains(snakePos + Direction.s().toOffset()))
        s();
      else if (applePos.dx > snakePos.dx && direction != Direction.d() && !(snakeSquares.toList()..remove(snakePos)).contains(snakePos + Direction.d().toOffset()))
        d();
      else
        print("Waiting...");
    }
    if (active) {
      setState(() {
        if (dirs.length > 0) {
          direction = dirs.first;
          dirs.removeAt(0);
        }
        snakePos += Offset(direction.x.toDouble(), direction.y.toDouble());
        if (snakePos.dx >= grid.width) {
          snakePos = Offset(0, snakePos.dy);
        }

        if (snakePos.dx < 0) {
          snakePos = Offset((grid.width - 1).toDouble(), snakePos.dy);
        }

        if (snakePos.dy < 0) {
          snakePos = Offset(snakePos.dx, (grid.height - 1).toDouble());
        }

        if (snakePos.dy >= grid.height) {
          snakePos = Offset(snakePos.dx, 0);
        }
        snakeSquares.add(snakePos);
        snakeSquares.removeAt(0);
        if ((snakeSquares.toList()..remove(snakePos)).contains(snakePos)) {
          highScore = max(snakeSquares.length - 1, highScore);
          direction = Direction.s();
          snakePos = Offset(0, 0);
          snakeSquares = [snakePos];
        }
        if (snakePos == applePos) {
          while (snakeSquares.contains(applePos)) {
            applePos = Offset(
                (random.nextDouble() * (grid.width - 1)).roundToDouble(),
                (random.nextDouble() * (grid.height - 1)).roundToDouble());
          }
          snakeSquares.add(snakePos);
        }

        //print("Ticking");
        updateGrid();
      });
    }
  }

  void updateGrid() {
    setState(() {
      grid.grid = List.filled(grid.grid.length, Colors.black);
      for (Offset pos in snakeSquares) {
        grid.grid[(pos.dy.round() * grid.width) + pos.dx.round()] =
            Colors.yellow;
      }
      grid.grid[(applePos.dy.round() * grid.width) + applePos.dx.round()] =
          Colors.red;
      grid.grid[(snakePos.dy.round() * grid.width) + snakePos.dx.round()] =
          null;
    });
  }

  bool w() {
    if (dirs.isEmpty ? direction != Direction.s() : dirs.last != Direction.s())
      dirs.add(Direction.w());
    return true;
  }

  bool a() {
    if (dirs.isEmpty ? direction != Direction.d() : dirs.last != Direction.d())
      dirs.add(Direction.a());
    return true;
  }

  bool s() {
    if (dirs.isEmpty ? direction != Direction.w() : dirs.last != Direction.w())
      dirs.add(Direction.s());
    return true;
  }

  bool d() {
    if (dirs.isEmpty ? direction != Direction.a() : dirs.last != Direction.a())
      dirs.add(Direction.d());
    return true;
  }

  List<Direction> dirs = [Direction.s()];
  Direction direction = Direction.s();
  Offset snakePos = Offset(0, 0);
  Offset applePos = Offset(1, 1);
  List<Offset> snakeSquares = [Offset(0, 0)];
  final ColorGrid grid = ColorGrid(List.filled(10 * 10, Colors.blue), 10);

  @override
  Widget build(BuildContext context) {
    updateGrid();
    final TextTheme textTheme = Theme.of(context).textTheme;
    return FocusScope(
      debugLabel: 'Scope',
      autofocus: true,
      child: DefaultTextStyle(
        style: textTheme.headline4,
        child: Focus(
          onKey: _handleKeyPress,
          debugLabel: 'Button',
          child: Builder(
            builder: (BuildContext context) {
              final FocusNode focusNode = Focus.of(context);
              final bool hasFocus = focusNode.hasFocus;
              return GestureDetector(
                onTap: () {
                  if (hasFocus) {
                    focusNode.unfocus();
                  } else {
                    focusNode.requestFocus();
                  }
                },
                child: hasFocus
                    ? Center(
                        child: SnakeGame(
                            grid,
                            active
                                ? "Space to pause\nHigh score: $highScore"
                                : "Paused: Space to unpause\nHigh score: $highScore"),
                      )
                    : Container(
                        color: Colors.white,
                        child: Center(child: Text("Tap screen to start")),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SnakeGame extends StatelessWidget {
  SnakeGame(this.grid, this.text) {
    n = n + 1;
  }
  static int n = 0;
  final String text;
  final ColorGrid grid;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
            "Snake\nWASD to turn\n$text\n\nScore: ${grid.grid.where((element) => element == Colors.yellow).length}"),
        GridDrawer(grid.grid, grid.width),
      ],
    );
  }
}

class GridDrawer extends StatelessWidget {
  GridDrawer(this.grid, this.width);
  final List<Color> grid;
  final int width;
  int get height => grid.length ~/ width;
  Widget build(BuildContext context) {
    //print("DRW");
    return CustomPaint(
      painter: GridPainter(
        width,
        height,
        grid,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter(this.width, this.height, this.grid);
  final int width;
  final int height;
  final List<Color> grid;
  bool shouldRepaint(CustomPainter _) => true;
  void paint(Canvas canvas, Size size) {
    //print("PNT");
    double size = 20;
    Size cellSize = Size(size, size);
    for (int y = 0; y < height; y += 1) {
      for (int x = 0; x < width; x += 1) {
        if (grid[x + y * width] != null) {
          if (grid[x + y * width] == Colors.red) {
            canvas.drawRect(
                Offset((x * cellSize.width), (y * cellSize.height)) & cellSize,
                Paint()..color = Colors.black);
            canvas.drawCircle(
              Offset((x * cellSize.width) + size / 2,
                  (y * cellSize.height) + size / 2),
              size / 2,
              Paint()..color = Colors.red,
            );
          } else
            canvas.drawRect(
                Offset((x * cellSize.width), (y * cellSize.height)) &
                    (grid[x + y * width] == Colors.black ? cellSize : cellSize),
                Paint()..color = grid[x + y * width]);
        } else {
          canvas.drawRect(
              Offset((x * cellSize.width), (y * cellSize.height)) & cellSize,
              Paint()..color = Colors.black);
          canvas.drawCircle(
            Offset((x * cellSize.width) + size / 2,
                (y * cellSize.height) + size / 2),
            size / 2,
            Paint()..color = Colors.yellow,
          );
        }
      }
    }
  }
}
