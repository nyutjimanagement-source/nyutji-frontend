import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff705d0d),
      surfaceTint: Color(0xff705d0d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xfffce186),
      onPrimaryContainer: Color(0xff554500),
      secondary: Color(0xff685e40),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xfff0e2bb),
      onSecondaryContainer: Color(0xff4f462a),
      tertiary: Color(0xff45664c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc6eccb),
      onTertiaryContainer: Color(0xff2e4e36),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffff8ef),
      onSurface: Color(0xff1e1b13),
      onSurfaceVariant: Color(0xff4b4639),
      outline: Color(0xff7d7767),
      outlineVariant: Color(0xffcec6b4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff343027),
      inversePrimary: Color(0xffdfc56d),
      primaryFixed: Color(0xfffce186),
      onPrimaryFixed: Color(0xff231b00),
      primaryFixedDim: Color(0xffdfc56d),
      onPrimaryFixedVariant: Color(0xff554500),
      secondaryFixed: Color(0xfff0e2bb),
      onSecondaryFixed: Color(0xff221b04),
      secondaryFixedDim: Color(0xffd3c6a1),
      onSecondaryFixedVariant: Color(0xff4f462a),
      tertiaryFixed: Color(0xffc6eccb),
      onTertiaryFixed: Color(0xff01210d),
      tertiaryFixedDim: Color(0xffabd0b0),
      onTertiaryFixedVariant: Color(0xff2e4e36),
      surfaceDim: Color(0xffe0d9cc),
      surfaceBright: Color(0xfffff8ef),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbf3e5),
      surfaceContainer: Color(0xfff5eddf),
      surfaceContainerHigh: Color(0xffefe7da),
      surfaceContainerHighest: Color(0xffe9e2d4),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff423500),
      surfaceTint: Color(0xff705d0d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff806b1d),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff3e361b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff776c4d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff1d3d26),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff53755a),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8ef),
      onSurface: Color(0xff141109),
      onSurfaceVariant: Color(0xff3a3629),
      outline: Color(0xff575244),
      outlineVariant: Color(0xff736d5e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff343027),
      inversePrimary: Color(0xffdfc56d),
      primaryFixed: Color(0xff806b1d),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff665301),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff776c4d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff5e5437),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff53755a),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff3b5c43),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffcdc6b9),
      surfaceBright: Color(0xfffff8ef),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffbf3e5),
      surfaceContainer: Color(0xffefe7da),
      surfaceContainerHigh: Color(0xffe3dccf),
      surfaceContainerHighest: Color(0xffd8d1c4),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff362b00),
      surfaceTint: Color(0xff705d0d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff584800),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff332c12),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff51492c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff12321d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff305038),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffff8ef),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff302c20),
      outlineVariant: Color(0xff4e493b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff343027),
      inversePrimary: Color(0xffdfc56d),
      primaryFixed: Color(0xff584800),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff3e3100),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff51492c),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff3a3218),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff305038),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff193923),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbfb8ab),
      surfaceBright: Color(0xfffff8ef),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff8f0e2),
      surfaceContainer: Color(0xffe9e2d4),
      surfaceContainerHigh: Color(0xffdbd4c6),
      surfaceContainerHighest: Color(0xffcdc6b9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffdfc56d),
      surfaceTint: Color(0xffdfc56d),
      onPrimary: Color(0xff3b2f00),
      primaryContainer: Color(0xff554500),
      onPrimaryContainer: Color(0xfffce186),
      secondary: Color(0xffd3c6a1),
      onSecondary: Color(0xff383016),
      secondaryContainer: Color(0xff4f462a),
      onSecondaryContainer: Color(0xfff0e2bb),
      tertiary: Color(0xffabd0b0),
      onTertiary: Color(0xff173721),
      tertiaryContainer: Color(0xff2e4e36),
      onTertiaryContainer: Color(0xffc6eccb),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff16130b),
      onSurface: Color(0xffe9e2d4),
      onSurfaceVariant: Color(0xffcec6b4),
      outline: Color(0xff979080),
      outlineVariant: Color(0xff4b4639),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e2d4),
      inversePrimary: Color(0xff705d0d),
      primaryFixed: Color(0xfffce186),
      onPrimaryFixed: Color(0xff231b00),
      primaryFixedDim: Color(0xffdfc56d),
      onPrimaryFixedVariant: Color(0xff554500),
      secondaryFixed: Color(0xfff0e2bb),
      onSecondaryFixed: Color(0xff221b04),
      secondaryFixedDim: Color(0xffd3c6a1),
      onSecondaryFixedVariant: Color(0xff4f462a),
      tertiaryFixed: Color(0xffc6eccb),
      onTertiaryFixed: Color(0xff01210d),
      tertiaryFixedDim: Color(0xffabd0b0),
      onTertiaryFixedVariant: Color(0xff2e4e36),
      surfaceDim: Color(0xff16130b),
      surfaceBright: Color(0xff3d392f),
      surfaceContainerLowest: Color(0xff100e07),
      surfaceContainerLow: Color(0xff1e1b13),
      surfaceContainer: Color(0xff221f17),
      surfaceContainerHigh: Color(0xff2d2a21),
      surfaceContainerHighest: Color(0xff38342b),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff6db81),
      surfaceTint: Color(0xffdfc56d),
      onPrimary: Color(0xff2f2500),
      primaryContainer: Color(0xffa68f3e),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffe9dcb6),
      onSecondary: Color(0xff2c250c),
      secondaryContainer: Color(0xff9c906e),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffc0e6c6),
      onTertiary: Color(0xff0b2c17),
      tertiaryContainer: Color(0xff76997d),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff16130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffe4dcc9),
      outline: Color(0xffb9b1a0),
      outlineVariant: Color(0xff979080),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e2d4),
      inversePrimary: Color(0xff574600),
      primaryFixed: Color(0xfffce186),
      onPrimaryFixed: Color(0xff161100),
      primaryFixedDim: Color(0xffdfc56d),
      onPrimaryFixedVariant: Color(0xff423500),
      secondaryFixed: Color(0xfff0e2bb),
      onSecondaryFixed: Color(0xff161100),
      secondaryFixedDim: Color(0xffd3c6a1),
      onSecondaryFixedVariant: Color(0xff3e361b),
      tertiaryFixed: Color(0xffc6eccb),
      onTertiaryFixed: Color(0xff001507),
      tertiaryFixedDim: Color(0xffabd0b0),
      onTertiaryFixedVariant: Color(0xff1d3d26),
      surfaceDim: Color(0xff16130b),
      surfaceBright: Color(0xff48443a),
      surfaceContainerLowest: Color(0xff090703),
      surfaceContainerLow: Color(0xff201d15),
      surfaceContainer: Color(0xff2b281f),
      surfaceContainerHigh: Color(0xff363229),
      surfaceContainerHighest: Color(0xff413d34),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffefc3),
      surfaceTint: Color(0xffdfc56d),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffdbc16a),
      onPrimaryContainer: Color(0xff100b00),
      secondary: Color(0xfffeefc8),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffcfc29d),
      onSecondaryContainer: Color(0xff100b00),
      tertiary: Color(0xffd4f9d9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffa7ccad),
      onTertiaryContainer: Color(0xff000f04),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff16130b),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff8efdc),
      outlineVariant: Color(0xffcac2b0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe9e2d4),
      inversePrimary: Color(0xff574600),
      primaryFixed: Color(0xfffce186),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffdfc56d),
      onPrimaryFixedVariant: Color(0xff161100),
      secondaryFixed: Color(0xfff0e2bb),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffd3c6a1),
      onSecondaryFixedVariant: Color(0xff161100),
      tertiaryFixed: Color(0xffc6eccb),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffabd0b0),
      onTertiaryFixedVariant: Color(0xff001507),
      surfaceDim: Color(0xff16130b),
      surfaceBright: Color(0xff545045),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff221f17),
      surfaceContainer: Color(0xff343027),
      surfaceContainerHigh: Color(0xff3f3b32),
      surfaceContainerHighest: Color(0xff4a463c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
