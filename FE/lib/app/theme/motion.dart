import 'package:flutter/widgets.dart';

class Motion {
  Motion._();
  
  // Durations
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const panel = Duration(milliseconds: 220);
  static const theme = Duration(milliseconds: 220);
  static const hover = Duration(milliseconds: 100);
  static const tab = Duration(milliseconds: 150);
  static const message = Duration(milliseconds: 160);
  static const toast = Duration(milliseconds: 160);
  static const dialog = Duration(milliseconds: 180);
  
  // Curves
  static const curve = Curves.easeOutCubic;
  static const curveIn = Curves.easeInCubic;
  
  // Helper to check reduced motion
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  // Returns Duration.zero if reduced motion is enabled
  static Duration resolve(BuildContext context, Duration duration) {
    return shouldReduceMotion(context) ? Duration.zero : duration;
  }
}
