import 'package:flutter/material.dart';

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
