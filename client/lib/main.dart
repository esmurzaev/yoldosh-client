import 'package:flutter/material.dart';

import 'common/configs.dart';
import 'common/route.dart';
import 'common/themes.dart';
import 'model/app.dart';
import 'ui/home/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppModel.load();
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    AppModel.setState = () => setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MaterialApp(
        // showPerformanceOverlay: true,
        debugShowCheckedModeBanner: false,
        title: Configs.appTitle,
        theme: AppModel.theme,
        darkTheme: CustomTheme.darkTheme,
        onGenerateRoute: Router.generateRoute,
        // initialRoute: Router.home,
        home: HomeScreen(),
      ),
    );
  }
}
