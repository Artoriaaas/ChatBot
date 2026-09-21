import 'package:flutter/material.dart';

class VerticalDragHandle extends StatefulWidget {
  final VoidCallback? onDragStart;
  final ValueChanged<double>? onDragUpdate;
  final VoidCallback? onDragEnd;

  const VerticalDragHandle({
    super.key,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<VerticalDragHandle> createState() => _VerticalDragHandleState();
}

class _VerticalDragHandleState extends State<VerticalDragHandle> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => widget.onDragStart?.call(),
        onHorizontalDragUpdate: (details) => widget.onDragUpdate?.call(details.delta.dx),
        onHorizontalDragEnd: (_) => widget.onDragEnd?.call(),
        child: Container(
          width: 8.0,
          alignment: Alignment.center,
          child: Container(
            width: _isHovering ? 2.0 : 1.0,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
    );
  }
}
