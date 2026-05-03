import 'package:flutter/material.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HoverCard({super.key, required this.child, this.onTap});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          // Lifts the card slightly less (from -4.0 to -2.0) for a tighter feel
          transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
          decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                // --- ULTRA SUBTLE SHADOW ---
                                color: Colors.black.withOpacity(0.03), // Barely visible
                                blurRadius: 6,                         // Tighter blur
                                offset: const Offset(0, 2),            // Barely drops down
                              )
                            ]
                          : [],
                    ),
          child: widget.child,
        ),
      ),
    );
  }
}