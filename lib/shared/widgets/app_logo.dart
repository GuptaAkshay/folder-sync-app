import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme.dart';

/// Size presets for the [AppLogo] widget.
enum AppLogoSize {
  /// Small — used in app bars and compact spaces (20px icon, 8px padding).
  small,

  /// Medium — used in hero/branding areas (48px icon, 20px padding).
  medium,
}

/// Reusable FolderSync brand logo.
///
/// Amber rounded-square background with a white sync_alt SVG icon.
/// Used in Welcome, Dashboard app bar, About screen, and splash.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = AppLogoSize.medium});

  final AppLogoSize size;

  /// Path to the SVG icon asset.
  static const String _iconAsset = 'assets/sync_alt.svg';

  @override
  Widget build(BuildContext context) {
    final (double iconSize, double padding, double radius) = switch (size) {
      AppLogoSize.small => (20.0, 8.0, AppTheme.radiusMd),
      AppLogoSize.medium => (48.0, 20.0, AppTheme.radiusXl),
    };

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SvgPicture.asset(
        _iconAsset,
        width: iconSize,
        height: iconSize,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
