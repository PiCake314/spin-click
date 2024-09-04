// ignore_for_file: non_constant_identifier_names

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MaterialApp(
      title: "Spin Click!",
      debugShowCheckedModeBanner: false,
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

class _MyHomePageState extends State<MyHomePage>  with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> angle;
  final prefs = SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {"high_score"},
    )
  );


  double begin = 0, end = 1;
  int score = 0;
  int? high_score;
  int ms = 1500;

  bool wrong = false;
  bool is_timed = false;


  Future<void> initScore() async {
    final SharedPreferencesWithCache preferences = await prefs;
    setState(() {
      high_score  = preferences.getInt('high_score') ?? 0;
    });
  }


  static const double BEGIN_POINT = 3*pi/2;
  static const double END_POINT = 3*pi/2 + 2*pi;

  @override
  void initState() {
    super.initState();
    initScore();

    controller = AnimationController(
      duration: Duration(milliseconds: ms),
      vsync: this,
    );
    angle = Tween<double>(begin: BEGIN_POINT, end: END_POINT).animate(controller);
    // controller.value = 3*pi/2; // couldn't get it to work

    controller.repeat();
  }

  double clockwizeDistance(final double a, final double b) => (b - a + 2*pi) % (2*pi);

   void changeSpeedTo(final Duration duration){
    controller.dispose();
    controller = AnimationController(
      duration: duration,
      vsync: this
    );
    angle = Tween<double>(begin: angle.value, end: angle.value + 2*pi).animate(controller);
    controller.repeat();
   }



  Future<void> AddPoint() async {

    await AudioPlayer().play(AssetSource("sounds/score.mp3"));

    score += 1;

    if(score > high_score!){
      final SharedPreferencesWithCache preferences = await prefs;
      high_score  = (preferences.getInt('high_score') ?? 0) + 1;
      preferences.setInt('high_score', score);
    }

    setState(() {
    // if(score == 5){
    //   // changeSpeedTo(const Duration(milliseconds: 1000));
    // }

      final Random rand = Random();
      begin = rand.nextDouble() * 2 * pi;
      end = .333 + begin + rand.nextDouble();
    });
  }


  Future<void> missed() async {
    await AudioPlayer().play(AssetSource("sounds/wrong.mp3"));

    setState(() {
      controller.stop();
      wrong = true;
    });

    await Future.delayed(const Duration(milliseconds: 750));

    setState((){
      wrong = false;
      score = 0;
      begin = 0;
      end = 1;

      controller.reset();
      controller.repeat();
    });
  }


  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final double radius = size.width * 0.8 / 2;
    final (double, double) center = (size.width / 2, size.height / 2);

    const double POINT_RADIUS = 7.5;
    const double LIMIT_RADIUS = 20;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Text("High: ${high_score ?? '~'}",
                style: TextStyle(
                  fontFamily: GoogleFonts.handjet().fontFamily,
                  fontSize: 64,
                ),
              ),
            ),
          ),

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

            AnimatedOpacity(
              opacity: is_timed ? 1 : 0,
              duration: const Duration(milliseconds: 100),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 150),
                  child: Text("00s",
                    style: TextStyle(
                      fontSize: 64,
                      fontFamily: GoogleFonts.handjet().fontFamily,
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            left: size.width / 2 + radius * cos(begin) - LIMIT_RADIUS / 2,
            top: size.height / 2 + radius * sin(begin) - LIMIT_RADIUS / 2,
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
            top: size.height / 2 + radius * sin(end) - LIMIT_RADIUS / 2,
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

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ElevatedButton(
                child: const Icon(Icons.tag_sharp),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                onPressed: () async {
                  const double LEEWAY = .333;
                  final double fake_begin = (begin - LEEWAY + 2*pi) % (2*pi);

                  // bool scored = ((angle_value) >= begin) && angle_value <= end;
                  final bool scored =
                    clockwizeDistance(fake_begin, angle.value) <= clockwizeDistance(fake_begin, end);

                  // score = 0;
                  // high_score = 0;
                  // final SharedPreferencesWithCache preferences = await prefs;
                  // preferences.setInt('high_score', 0);

                  if(scored) await AddPoint();
                  else       await missed();
                },
              ),
            ),
          ),

        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 75, left: 6),
            child: ElevatedButton(
              child: is_timed ? const Icon(Icons.timer_sharp, size: 46) : const Icon(Icons.sports_score_sharp, size: 46),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                splashFactory: NoSplash.splashFactory,
                minimumSize: const Size(64, 64),
              ),
              onPressed: () {
                setState(() {
                  is_timed = !is_timed;
                });
              },
            ),
          ),
        ),

        if(wrong) Container(color: Colors.red.withOpacity(.3)),

        if(wrong)
          const Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.close_sharp,
              color: Colors.red,
              size: 360,
            ),
          ),
        ],
      ),
    );
  }
}



class Point extends CustomPainter {
  final double angle;
  final (double, double) center;
  final double radius;
  final double point_radius;

  Point({
    required this.angle,
    required this.radius,
    required this.center,
    required this.point_radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final Offset point_center = Offset(
        size.width / 2 + radius * cos(angle),
        size.height / 2 + radius * sin(angle)
      );

    canvas.drawCircle(point_center, point_radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

