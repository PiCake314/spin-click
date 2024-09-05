// ignore_for_file: non_constant_identifier_names

import 'dart:async';

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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> angle;
  final prefs = SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {"high_score_single", "high_score_timed"},
    )
  );

  // ================== VARIABLES ==================
  Color point_color = Colors.black;
  double begin = 0, end = 1;
  int score = 0;
  int? high_score;
  static const int START_MS = 1500;
  int ms = START_MS;

  bool wrong = false;
  bool time_out = false;
  bool is_timed = false;
  bool missed = false;


  bool show_multiplier = false;
  int continuous_hit = 0;
  static const Duration ANIMATION_DURATION = Duration(milliseconds: 250);
  static const List<AssetImage> MULTIPLIERS = [
    AssetImage("assets/pluses/1.png"),
    AssetImage("assets/pluses/2.png"),
    AssetImage("assets/pluses/3.png"),
    AssetImage("assets/pluses/4.png"),
    AssetImage("assets/pluses/5.png"),
  ];


  static const int TOTAL_SECONDS = 30;
  int timer_seconds = TOTAL_SECONDS;

  Timer? timer;

  // ================== FUNCTIONS ==================

  Future<void> initScore() async {
    final SharedPreferencesWithCache preferences = await prefs;
    if(preferences.getInt("high_score_single") == null)
      preferences.setInt("high_score_single", 0);

    if(preferences.getInt("high_score_timed") == null)
      preferences.setInt("high_score_timed", 0);

    setState(() => high_score = preferences.getInt("high_score_single")!); // starting in single mode
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

    controller.repeat();
  }


  double clockwizeDistance(final double a, final double b) => (b - a + 2*pi) % (2*pi);


  void reset(){
    wrong = false;
    time_out = false;
    missed = false;
    continuous_hit = 0;
    score = 0;
    begin = 0;
    end = 1;


    if(controller.duration!.inMilliseconds != START_MS){      
      ms = START_MS;

      controller.dispose();
      controller = AnimationController(
        duration: const Duration(milliseconds: START_MS),
        vsync: this,
      );

      // not calling changeSpeedTo because we want to reset the angles as well
      angle = Tween<double>(begin: BEGIN_POINT, end: END_POINT).animate(controller);
    }

    controller.reset();
    controller.repeat();
  }

  void newPointsLocation(){
    final Random rand = Random();
    begin = rand.nextDouble() * 2 * pi;
    end = .333 + begin + rand.nextDouble();
  }


   void changeSpeedTo(final Duration duration){
    controller.dispose();
    controller = AnimationController(
      duration: duration,
      vsync: this
    );
    angle = Tween<double>(begin: angle.value, end: angle.value + 2*pi).animate(controller);
    controller.repeat();
   }


  Future<void> singleShotHit() async {
    await AudioPlayer().play(AssetSource("sounds/score.mp3"));

    score += 1;
    if(score > high_score!){
      final SharedPreferencesWithCache preferences = await prefs;
      high_score  = (preferences.getInt("high_score_single") ?? 0) + 1;
      preferences.setInt("high_score_single", score);
    }

    setState(() {
      if(score != 0 && score % 5 == 0) changeSpeedTo(Duration(milliseconds: ms -= 50));

      newPointsLocation();
    });
  }


  Future<void> singleShotMissed() async {
    await AudioPlayer().play(AssetSource("sounds/wrong.mp3"));

    setState(() {
      controller.stop();
      wrong = true;
    });

    await Future.delayed(const Duration(milliseconds: 750));

    setState(reset);
  }


  Future<void> timedHit() async {
    if(score == 0) startTimer();

    await AudioPlayer().play(AssetSource("sounds/score.mp3"));

    if(missed) continuous_hit = 0;
    missed = false;

    if(continuous_hit < 5) ++continuous_hit;

    score += continuous_hit;
    showMultiplier();


    if(score > high_score!){
      final SharedPreferencesWithCache preferences = await prefs;
      high_score  = (preferences.getInt("high_score_timed") ?? 0) + 1;
      preferences.setInt("high_score_timed", score);
    }

    setState(() {
      // change the speed every 25 points by 50
      // points may increase by 1, 2, 3, 4, or 5 depending on the multiplier
      final int curr_speed = START_MS - (score ~/ 25) * 50;
      if(curr_speed != controller.duration!.inMilliseconds){
        ms = curr_speed;
        changeSpeedTo(Duration(milliseconds: ms));
      }


      newPointsLocation();
    });
  }


  Future<void> timedMissed() async {
    await AudioPlayer().play(AssetSource("sounds/wrong.mp3"));
    // continuous_hit = 0;
    missed = true;

    setState(() {
      point_color = Colors.red;
      controller.stop();
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      point_color = Colors.black;
      controller.repeat();
    });
  }


  void startTimer() => timer = Timer.periodic(
    const Duration(seconds: 1),
    (_){
      if(timer_seconds == 0) timeOut();
      else setState(() => --timer_seconds);
    },
  );


  Future<void> timeOut() async {
    await AudioPlayer().play(AssetSource("sounds/wrong.mp3"));

    setState(() {
      timer!.cancel();
      controller.stop();
      timer_seconds = TOTAL_SECONDS;
      time_out = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(reset);
  }


  Timer multiplier_timer = Timer(Duration.zero, () {});
  Future<void> showMultiplier() async {
    setState(() => show_multiplier = true);
    // await Future.delayed(const Duration(milliseconds: 1000));
    multiplier_timer.cancel();
    multiplier_timer = Timer(const Duration(seconds: 1), () => setState(() => show_multiplier = false));
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

          AnimatedOpacity(
            opacity: is_timed ? 1 : 0,
            duration: const Duration(milliseconds: 100),
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 150),
                child: Text(" ${timer_seconds}s",
                  style: TextStyle(
                    fontSize: 64,
                    fontFamily: GoogleFonts.handjet().fontFamily,
                  ),
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


          AnimatedPositioned(
            duration: ANIMATION_DURATION,
            curve: Curves.decelerate,
            top: size.height / 2 - (show_multiplier ? 80 : 40),
            left: size.width / 2 + 10,
            child: AnimatedOpacity(
              duration: ANIMATION_DURATION,
              // curve: Curves.bounceOut,
              opacity: show_multiplier ? 1 : 0,
              child: Image(
                image: MULTIPLIERS[continuous_hit <= 0 ? 0 : continuous_hit -1],
                width: 65,
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
                color: point_color,
              ),
              // size: size,
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


                  if(scored) await (is_timed ? timedHit() : singleShotHit());
                  else is_timed ? await timedMissed() : await singleShotMissed();
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
                onPressed: () async {
                  is_timed = !is_timed;

                  final SharedPreferencesWithCache preferences = await prefs;
                  high_score =
                  preferences.getInt(is_timed  ? "high_score_timed" : "high_score_single")!;

                  setState(() {
                    if(!is_timed){
                      if(timer != null) timer!.cancel();
                      timer_seconds = TOTAL_SECONDS;
                    }

                    reset();
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


          if(time_out) Container(color: Colors.blue.withOpacity(.3)),
          if(time_out)
            const Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.timer_off_outlined,
                color: Colors.blue,
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
  final Color color;

  Point({
    required this.angle,
    required this.radius,
    required this.center,
    required this.point_radius,
    required this.color
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
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

