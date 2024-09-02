import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Spin Click!",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> angle;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    angle = Tween<double>(begin: 0, end: 2 * pi).animate(controller)
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          controller.repeat();
        }
      });

    controller.forward();
  }

  double begin = 0, end = 1;

  int score = 0;
  late int high_score

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final double radius = size.width * 0.8 / 2;
    (double, double) center = (size.width / 2, size.height / 2);

    const double POINT_RADIUS = 7.5;
    const double LIMIT_RADIUS = 20;

    return Scaffold(
        body: Column(
      children: [
        Text("High: $"),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: radius * 2 + 3.14,
                  height: radius * 2 + 3.14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 3.14,
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.center,
                child: Text(score.toString(),
                  style: TextStyle(
                    fontSize: 64,
                    fontFamily: GoogleFonts.handjet().fontFamily,
                  ),
                ),
              ),

              Positioned(
                left: size.width / 2 + radius * cos(begin) - LIMIT_RADIUS / 2,
                top: size.height / 2 + radius * sin(begin) - LIMIT_RADIUS / 2 - 55,
                child: Container(
                  width: LIMIT_RADIUS,
                  height: LIMIT_RADIUS,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              ),
              Positioned(
                left: size.width / 2 + radius * cos(end) - LIMIT_RADIUS / 2,
                top: size.height / 2 + radius * sin(end) - LIMIT_RADIUS / 2 - 55,
                child: Container(
                  width: LIMIT_RADIUS,
                  height: LIMIT_RADIUS,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: angle,
                builder: (context, child) => CustomPaint(
                  painter: Point(
                    angle: angle.value,
                    center: center,
                    radius: radius,
                    point_radius: POINT_RADIUS,
                  ),
                  // size: MediaQuery.of(context).size,
                  size: size,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: ElevatedButton(
            child: const Icon(Icons.tag_sharp),
            style: ElevatedButton.styleFrom(
              // backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            ),
            onPressed: () async {
              final Random rand = Random();
              // await player.resume();
              final AudioPlayer player = AudioPlayer();
              bool scored = angle.value >= begin && angle.value <= end;

              if(scored)
                await player.play(AssetSource("sounds/score.mp3"));
              else
                await player.play(AssetSource("sounds/wrong.mp3"));

              setState(() {
                score += scored ? 1 : 0;

                begin = rand.nextDouble() * 2 * pi;
                end = .333 + begin + rand.nextDouble();
              });
            },
          ),
        ),
      ],
    ));
  }
}



class Point extends CustomPainter {
  final double angle;
  final (double, double) center;
  final double radius;
  final double point_radius; // ignore: non_constant_identifier_names

  Point({
    required this.angle,
    required this.radius,
    required this.center,
    required this.point_radius, // ignore: non_constant_identifier_names
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // ignore: non_constant_identifier_names
    final Offset point_center = Offset(size.width / 2 + radius * cos(angle),
        size.height / 2 + radius * sin(angle));

    canvas.drawCircle(point_center, point_radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
