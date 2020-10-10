import 'package:flutter/material.dart';
import 'package:yoldosh/ui/car/car.dart';
import 'package:yoldosh/ui/info/info.dart';
import 'package:yoldosh/ui/process/process.dart';
// import 'package:yoldosh/ui/home_screen.dart';

class Router {
  const Router._();

  // static const String home = '/';
  static const String process = '/process';
  static const String car = '/car';
  static const String info = '/info';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case process:
        return ProcessScreenRoute();
        break;
      case car:
        return MaterialPageRoute(builder: (_) => CarDescriptionScreen());
        break;
      case info:
        return MaterialPageRoute(builder: (_) => InfoScreen());
        break;
      // case home:
      // return MaterialPageRoute(builder: (_) => HomeScreen());
      // break;
      default:
        return MaterialPageRoute(
            builder: (_) => Material(child: Center(child: Text('No route defined for ${settings.name}'))));
    }
  }
}

/*
class Routes {
  Routes._();

  static const String home = '/home';
  static const String info = '/info';
  static const String car = '/car';

  static final routes = <String, WidgetBuilder>{
    home: (BuildContext context) => HomeScreen(),
    info: (BuildContext context) => InfoScreen(),
    car: (BuildContext context) => CarDescriptionScreen(),
  };
}
*/
