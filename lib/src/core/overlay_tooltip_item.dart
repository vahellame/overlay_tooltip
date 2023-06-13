import 'package:flutter/material.dart';
import 'package:overlay_tooltip/src/constants/enums.dart';
import 'package:overlay_tooltip/src/impl.dart';
import 'package:overlay_tooltip/src/model/tooltip_widget_model.dart';

abstract class OverlayTooltipItemImpl extends StatefulWidget {

  const OverlayTooltipItemImpl(
      {required this.displayIndex, required this.child, required this.tooltip, required this.tooltipVerticalPosition, required this.tooltipHorizontalPosition, Key? key})
      : super(key: key);
  final Widget child;
  final Widget Function(TooltipController) tooltip;
  final TooltipVerticalPosition tooltipVerticalPosition;
  final TooltipHorizontalPosition tooltipHorizontalPosition;
  final int displayIndex;

  @override
  _OverlayTooltipItemImplState createState() => _OverlayTooltipItemImplState();
}

class _OverlayTooltipItemImplState extends State<OverlayTooltipItemImpl> {
  final GlobalKey widgetKey = GlobalKey();

  @override
  void didUpdateWidget(covariant OverlayTooltipItemImpl oldWidget) {
    _addToPlayableWidget();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _addToPlayableWidget();
    super.initState();
  }

  void _addToPlayableWidget() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        OverlayTooltipScaffold.of(context)?.addPlayableWidget(
            OverlayTooltipModel(
                child: widget.child,
                tooltip: widget.tooltip,
                widgetKey: widgetKey,
                vertPosition: widget.tooltipVerticalPosition,
                horPosition: widget.tooltipHorizontalPosition,
                displayIndex: widget.displayIndex));
      } catch (e) {
        print(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: widgetKey,
      color: Colors.transparent,
      child: widget.child,
    );
  }
}
