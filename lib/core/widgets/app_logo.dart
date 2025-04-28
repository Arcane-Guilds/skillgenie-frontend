import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final double? width;
  final Color? color;

  const AppLogo({
    super.key,
    required this.height,
    this.width,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      // Check if the SVG asset exists
      future: _checkAssetExists('assets/images/logo.svg'),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          // SVG asset exists, use it
          return SvgPicture.asset(
            'assets/images/logo.svg',
            height: height,
            width: width,
            // Use color property directly for older flutter_svg versions
            color: color,
          );
        } else {
          // Fallback to styled text logo if SVG not available
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: height,
                width: width ?? height,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'SG',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: height * 0.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // Helper method to check if an asset exists
  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      // This will throw an error if the asset doesn't exist
      await DefaultAssetBundle.of(AppLogo.globalKey.currentContext!).load(assetPath);
      return true;
    } catch (e) {
      // Asset doesn't exist, use fallback
      return false;
    }
  }

  // Global key for accessing the current context
  static final GlobalKey<NavigatorState> globalKey = GlobalKey<NavigatorState>();
}