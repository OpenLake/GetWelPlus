import 'package:flutter/src/material/theme_data.dart';

import 'light_theme.dart';
import 'dark_theme.dart';

class AppTheme {
  static ThemeData get light => LightTheme.theme;
  static ThemeData get dark => DarkTheme.theme;
}
