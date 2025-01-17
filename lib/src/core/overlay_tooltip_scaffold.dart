import 'dart:math';

import 'package:flutter/material.dart';
import 'package:overlay_tooltip/src/constants/enums.dart';
import 'package:overlay_tooltip/src/constants/extensions.dart';
import 'package:overlay_tooltip/src/impl.dart';
import 'package:overlay_tooltip/src/model/tooltip_widget_model.dart';

abstract class OverlayTooltipScaffoldImpl extends StatefulWidget {

  OverlayTooltipScaffoldImpl({
    required this.controller, required this.builder, required this.overlayColor, required this.startWhen, required this.tooltipAnimationDuration, required this.tooltipAnimationCurve, Key? key,
    this.preferredOverlay,
  }) : super(key: key) {
    if (startWhen != null) controller.setStartWhen(startWhen!);
  }
  final TooltipController controller;
  final Future<bool> Function(int instantiatedWidgetLength)? startWhen;
  final Widget Function(BuildContext context) builder;
  final Color overlayColor;
  final Duration tooltipAnimationDuration;
  final Curve tooltipAnimationCurve;
  final Widget? preferredOverlay;

  @override
  State<OverlayTooltipScaffoldImpl> createState() => OverlayTooltipScaffoldImplState();
}

class OverlayTooltipScaffoldImplState extends State<OverlayTooltipScaffoldImpl> {
  void addPlayableWidget(OverlayTooltipModel model) {
    widget.controller.addPlayableWidget(model);
  }

  TooltipController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: Builder(builder: (context) {
            return widget.builder(context);
          })),
          StreamBuilder<OverlayTooltipModel?>(
            stream: widget.controller.widgetsPlayStream,
            builder: (context, snapshot) {
              return snapshot.data == null || snapshot.data!.widgetKey.globalPaintBounds == null
                  ? const SizedBox.shrink()
                  : Positioned.fill(
                      child: Stack(
                        children: [
                          widget.preferredOverlay ??
                              Container(
                                height: double.infinity,
                                width: double.infinity,
                                color: widget.overlayColor,
                              ),
                          TweenAnimationBuilder(
                            key: ValueKey(snapshot.data!.displayIndex),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: widget.tooltipAnimationDuration,
                            curve: widget.tooltipAnimationCurve,
                            builder: (_, val, child) {
                              val = min(val, 1);
                              val = max(val, 0);
                              return Opacity(
                                opacity: val,
                                child: child,
                              );
                            },
                            child: _TooltipLayout(
                              model: snapshot.data!,
                              controller: widget.controller,
                            ),
                          ),
                        ],
                      ),
                    );
            },
          )
        ],
      ),
    );
  }
}

class _TooltipLayout extends StatelessWidget {

  const _TooltipLayout({required this.model, required this.controller, Key? key}) : super(key: key);
  final OverlayTooltipModel model;
  final TooltipController controller;

  @override
  Widget build(BuildContext context) {
    late Offset topLeft;
    late Offset bottomRight;
    if (model.widgetKey.globalPaintBounds != null) {
      topLeft = model.widgetKey.globalPaintBounds!.topLeft;
      bottomRight = model.widgetKey.globalPaintBounds!.bottomRight;
    } else {
      topLeft = Offset.zero;
      bottomRight = Offset.zero;
    }

    return LayoutBuilder(
      builder: (context, size) {
        if (topLeft.dx < 0) {
          bottomRight = Offset(bottomRight.dx + (0 - topLeft.dx), bottomRight.dy);
          topLeft = Offset(0, topLeft.dy);
        }

        if (bottomRight.dx > size.maxWidth) {
          topLeft = Offset(topLeft.dx - (bottomRight.dx - size.maxWidth), topLeft.dy);
          bottomRight = Offset(size.maxWidth, bottomRight.dy);
        }

        if (topLeft.dy < 0) {
          bottomRight = Offset(bottomRight.dx, bottomRight.dy + (0 - topLeft.dy));
          topLeft = Offset(topLeft.dx, 0);
        }

        if (bottomRight.dy > size.maxHeight) {
          topLeft = Offset(topLeft.dx, topLeft.dy - (bottomRight.dy - size.maxHeight));
          bottomRight = Offset(bottomRight.dx, size.maxHeight);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: topLeft.dy,
              left: topLeft.dx,
              bottom: size.maxHeight - bottomRight.dy,
              right: size.maxWidth - bottomRight.dx,
              child: model.child,
            ),
            _buildToolTip(topLeft, bottomRight, size)
          ],
        );
      },
    );
  }

  Widget _buildToolTip(Offset topLeft, Offset bottomRight, BoxConstraints size) {
    bool isTop = model.vertPosition == TooltipVerticalPosition.top;

    bool alignLeft = topLeft.dx <= (size.maxWidth - bottomRight.dx);

    final calculatedLeft = alignLeft ? topLeft.dx : null;
    final calculatedRight = alignLeft ? null : size.maxWidth - bottomRight.dx;
    final calculatedTop = isTop ? null : bottomRight.dy;
    final calculatedBottom = isTop ? (size.maxHeight - topLeft.dy) : null;
    return (model.horPosition == TooltipHorizontalPosition.withWidget)
        ? Positioned(
            top: calculatedTop,
            left: calculatedLeft,
            right: calculatedRight,
            bottom: calculatedBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                model.tooltip(controller),
              ],
            ),
          )
        : Positioned(
            top: calculatedTop,
            left: 0,
            right: 0,
            bottom: calculatedBottom,
            child: model.horPosition == TooltipHorizontalPosition.center
                ? Center(
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      model.tooltip(controller),
                    ],
                  ))
                : Align(
                    alignment: model.horPosition == TooltipHorizontalPosition.right
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        model.tooltip(controller),
                      ],
                    ),
                  ),
          );
  }
}
