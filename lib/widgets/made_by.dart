import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:neumorphic_calculator/utils/const.dart';
import 'package:url_launcher/url_launcher.dart';

class MadeBy extends StatelessWidget {
  const MadeBy({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white : Colors.black,
        );
    final githubIconPath = isDark ? AppConst.githubLight : AppConst.githubDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '@2024 Neumorphic Calculator',
              style: contentTextStyle?.copyWith(color: Colors.grey),
            ),
            Text(
              'Made with ❤️ by Mohammed Ragheb',
              style: contentTextStyle,
            ),
          ],
        ),
        IconButton(
          onPressed: () async {
            try {
              await launchUrl(Uri.parse(AppConst.githubLink));
            } catch (_) {}
          },
          icon: Lottie.asset(
            githubIconPath,
            width: 50,
            height: 50,
          ),
        )
      ],
    );
  }
}
