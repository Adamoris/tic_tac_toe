import 'auth_checker.dart';
import 'package:tic_tac_toe/screens/login.dart';
import 'package:tic_tac_toe/screens/register.dart';
import 'package:tic_tac_toe/screens/title.dart';
import 'package:tic_tac_toe/screens/matchmaking.dart';
import 'package:tic_tac_toe/screens/settings.dart';
import 'package:tic_tac_toe/screens/game.dart';

var screenRoutes = {
  '/': (context) => const AuthChecker(),
  '/loginScreen': (context) => LoginScreen(),
  '/registerScreen': (context) => const RegisterScreen(),
  '/titleScreen': (context) => const TitleScreen(),
  '/matchmakingScreen': (context) => MatchmakingScreen(),
  '/settingScreen': (context) => const SettingScreen(),
  '/gameScreen': (context) => GameScreen(),
};
