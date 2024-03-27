library clever_stepper;
import 'dart:math';
import 'package:flutter/material.dart';

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

// TODO(dragostis): Missing functionality:
//   * mobile horizontal mode with adding/removing steps
//   * alternative labeling
//   * stepper feedback in the case of high-latency interactions

/// The state of a [CleverStep] which is used to control the style of the circle and
/// text.
///
/// See also:
///
///  * [CleverStep]
enum CleverStepState {
  /// A step that displays its index in its circle.
  indexed,

  /// A step that displays a pencil icon in its circle.
  editing,

  /// A step that displays a tick icon in its circle.
  complete,

  /// A step that is disabled and does not to react to taps.
  disabled,

  /// A step that is currently having an error. e.g. the user has submitted wrong
  /// input.
  error,
}

/// Defines the [CleverStepper]'s main axis.
enum CleverStepperType {
  /// A vertical layout of the steps with their content in-between the titles.
  vertical,

  /// A horizontal layout of the steps with their content below the titles.
  horizontal,
}

const TextStyle _kStepStyle = TextStyle(
  fontSize: 12.0,
  color: Colors.white,
);
const Color _kErrorLight = Colors.red;
final Color _kErrorDark = Colors.red.shade400;
const Color _kCircleActiveLight = Colors.white;
const Color _kCircleActiveDark = Colors.black87;
const Color _kDisabledLight = Colors.black38;
const Color _kDisabledDark = Colors.white38;
const double _kStepSize = 24.0;
const double _kTriangleHeight =
    _kStepSize * 0.866025; // Triangle height. sqrt(3.0) / 2.0

/// A material step used in [CleverStepper]. The step can have a title and subtitle,
/// an icon within its circle, some content and a state that governs its
/// styling.
///
/// See also:
///
///  * [CleverStepper]
///  * <https://material.io/archive/guidelines/components/steppers.html>
@immutable
class CleverStep {
  final Widget? trailing;

  /// Creates a step for a [CleverStepper].
  ///
  /// The [title], [content], and [state] arguments must not be null.
  const CleverStep({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.content,
    this.state = CleverStepState.indexed,
    this.isActive = false,
  });

  /// The title of the step that typically describes it.
  final Widget title;

  /// The subtitle of the step that appears below the title and has a smaller
  /// font size. It typically gives more details that complement the title.
  ///
  /// If null, the subtitle is not shown.
  final Widget? subtitle;

  /// The content of the step that appears below the [title] and [subtitle].
  ///
  /// Below the content, every step has a 'continue' and 'cancel' button.
  final Widget content;

  /// The state of the step which determines the styling of its components.dart
  /// and whether steps are interactive.
  final CleverStepState state;

  /// Whether or not the step is active. The flag only influences styling.
  final bool isActive;
}

/// A material stepper widget that displays progress through a sequence of
/// steps. Steppers are particularly useful in the case of forms where one step
/// requires the completion of another one, or where multiple steps need to be
/// completed in order to submit the whole form.
///
/// The widget is a flexible wrapper. A parent class should pass [currentStep]
/// to this widget based on some logic triggered by the three callbacks that it
/// provides.
///
/// {@tool sample --template=stateful_widget_scaffold_center}
///
/// ```dart
/// int _index = 0;
///
/// @override
/// Widget build(BuildContext context) {
///   return CleverStepper(
///     currentStep: _index,
///     onStepCancel: () {
///       if (_index > 0) {
///         setState(() { _index -= 1; });
///       }
///     },
///     onStepContinue: () {
///       if (_index <= 0) {
///         setState(() { _index += 1; });
///       }
///     },
///     onStepTapped: (int index) {
///       setState(() { _index = index; });
///     },
///     steps: <Step>[
///       Step(
///         title: const Text('Step 1 title'),
///         content: Container(
///           alignment: Alignment.centerLeft,
///           child: const Text('Content for Step 1')
///         ),
///       ),
///       const Step(
///         title: Text('Step 2 title'),
///         content: Text('Content for Step 2'),
///       ),
///     ],
///   );
/// }
/// ```
///
/// {@end-tool}
///
/// See also:
///
///  * [Step]
///  * <https://material.io/archive/guidelines/components/steppers.html>
class CleverStepper extends StatefulWidget {
  /// Creates a stepper from a list of steps.
  ///
  /// This widget is not meant to be rebuilt with a different list of steps
  /// unless a key is provided in order to distinguish the old stepper from the
  /// new one.
  ///
  /// The [steps], [type], and [currentStep] arguments must not be null.
  const CleverStepper({
    Key? key,
    required this.steps,
    this.physics,
    this.type = CleverStepperType.vertical,
    this.currentStep = 0,
    this.onStepTapped,
    this.onStepLongPressed,
    this.onStepContinue,
    this.onStepCancel,
    this.controlsBuilder,
    this.activeCircleColor = Colors.green,
    this.controller,
    this.stepColor,
    this.stepIcon,
    this.stepIconBuilder,
    this.stepBuilder,
  })  : assert(0 <= currentStep && currentStep < steps.length),
        assert(stepIcon == null || stepIconBuilder == null,
            'Cannot provide both stepIcon and stepIconBuilder'),
        super(key: key);

  /// builder for wrapping the [CleverStep] widget.
  final Widget Function(BuildContext context, int index, Widget child)?
      stepBuilder;

  /// The color of step circle.
  final Color? Function(CleverStepState state)? stepColor;

  /// The icon of step circle (only for completed and editing).
  final IconData? Function(CleverStepState state)? stepIcon;

  /// function to build the step icon, it can be used to give it a widget instead
  /// of an icon.
  final Widget Function(CleverStepState state, Color color, int index)?
      stepIconBuilder;

  /// The steps of the stepper whose titles, subtitles, icons always get shown.
  ///
  /// The length of [steps] must not change.
  final List<CleverStep> steps;

  /// How the stepper's scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to
  /// animate after the user stops dragging the scroll view.
  ///
  /// If the stepper is contained within another scrollable it
  /// can be helpful to set this property to [ClampingScrollPhysics].
  final ScrollPhysics? physics;

  /// The type of stepper that determines the layout. In the case of
  /// [CleverStepperType.horizontal], the content of the current step is displayed
  /// underneath as opposed to the [CleverStepperType.vertical] case where it is
  /// displayed in-between.
  final CleverStepperType type;

  /// The index into [steps] of the current step whose content is displayed.
  final int currentStep;

  /// The callback called when a step is tapped, with its index passed as
  /// an argument.
  final ValueChanged<int>? onStepTapped;

  /// The callback called when a step is long pressed, with its index passed as
  /// an argument.
  final ValueChanged<int>? onStepLongPressed;

  /// The callback called when the 'continue' button is tapped.
  ///
  /// If null, the 'continue' button will be disabled.
  final Function({dynamic value})? onStepContinue;

  /// The callback called when the 'cancel' button is tapped.
  ///
  /// If null, the 'cancel' button will be disabled.
  final Function({dynamic value})? onStepCancel;

  /// The callback for creating custom controls.
  ///
  /// If null, the default controls from the current theme will be used.
  ///
  /// This callback which takes in a context and two functions: [onStepContinue]
  /// and [onStepCancel]. These can be used to control the stepper.
  /// For example, keeping track of the [currentStep] within the callback can
  /// change the text of the continue or cancel button depending on which step users are at.
  ///
  /// {@tool dartpad --template=stateless_widget_scaffold}
  /// Creates a stepper control with custom buttons.
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return CleverStepper(
  ///     controlsBuilder:
  ///       (BuildContext context, { VoidCallback? onStepContinue, VoidCallback? onStepCancel }) {
  ///          return Row(
  ///            children: <Widget>[
  ///              TextButton(
  ///                onPressed: onStepContinue,
  ///                child: const Text('NEXT'),
  ///              ),
  ///              TextButton(
  ///                onPressed: onStepCancel,
  ///                child: const Text('CANCEL'),
  ///              ),
  ///            ],
  ///          );
  ///       },
  ///     steps: const <Step>[
  ///       Step(
  ///         title: Text('A'),
  ///         content: SizedBox(
  ///           width: 100.0,
  ///           height: 100.0,
  ///         ),
  ///       ),
  ///       Step(
  ///         title: Text('B'),
  ///         content: SizedBox(
  ///           width: 100.0,
  ///           height: 100.0,
  ///         ),
  ///       ),
  ///     ],
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final CleverControlsWidgetBuilder? controlsBuilder;

  final Color activeCircleColor;

  final CleverStepController? controller;

  @override
  State<CleverStepper> createState() => _StepperState();
}

class _StepperState extends State<CleverStepper> with TickerProviderStateMixin {
  late List<GlobalKey> _keys;
  final Map<int, CleverStepState> _oldStates = <int, CleverStepState>{};

  @override
  void initState() {
    super.initState();
    _keys = List<GlobalKey>.generate(
      widget.steps.length,
      (int i) => GlobalKey(),
    );
    widget.controller?._bindState(this);
    for (int i = 0; i < widget.steps.length; i += 1) {
      _oldStates[i] = widget.steps[i].state;
    }
  }

  @override
  void didUpdateWidget(CleverStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.steps.length != oldWidget.steps.length) {
      // Update _oldStates for existing steps
      for (int i = 0; i < min(widget.steps.length, oldWidget.steps.length); i++) {
        _oldStates[i] = oldWidget.steps[i].state;
      }
      
      // Update _oldStates for newly added steps
      for (int i = oldWidget.steps.length; i < widget.steps.length; i++) {
        _oldStates[i] = widget.steps[i].state;
      }
    } else {
      // Update _oldStates for existing steps
      for (int i = 0; i < oldWidget.steps.length; i++) {
        _oldStates[i] = oldWidget.steps[i].state;
      }
    }
}


  // @override
  // void didUpdateWidget(CleverStepper oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   assert(widget.steps.length == oldWidget.steps.length);

  //   for (int i = 0; i < oldWidget.steps.length; i += 1) {
  //     _oldStates[i] = oldWidget.steps[i].state;
  //   }
  // }

  bool _isFirst(int index) {
    return index == 0;
  }

  bool _isLast(int index) {
    return widget.steps.length - 1 == index;
  }

  bool _isCurrent(int index) {
    return widget.currentStep == index;
  }

  bool _isDark() {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Widget _buildLine(bool visible) {
    return Container(
      width: visible ? 1.0 : 0.0,
      height: 16.0,
      color: Colors.grey.shade400,
    );
  }

  Widget _buildCircleChild(int index, bool oldState) {
    final CleverStepState state =
        oldState ? _oldStates[index]! : widget.steps[index].state;
    final bool isDarkActive = _isDark() && widget.steps[index].isActive;
    switch (state) {
      case CleverStepState.indexed:
      case CleverStepState.disabled:
        return widget.stepIconBuilder?.call(
                state,
                (isDarkActive
                        ? _kStepStyle.copyWith(color: Colors.black87)
                        : _kStepStyle)
                    .color!,
                index) ??
            Text(
              '${index + 1}',
              style: isDarkActive
                  ? _kStepStyle.copyWith(color: Colors.black87)
                  : _kStepStyle,
            );
      case CleverStepState.editing:
        return widget.stepIconBuilder?.call(
                state,
                isDarkActive ? _kCircleActiveDark : _kCircleActiveLight,
                index) ??
            Icon(
              widget.stepIcon?.call(state) ?? Icons.edit,
              color: isDarkActive ? _kCircleActiveDark : _kCircleActiveLight,
              size: 18.0,
            );
      case CleverStepState.complete:
        return widget.stepIconBuilder?.call(
                state,
                isDarkActive ? _kCircleActiveDark : _kCircleActiveLight,
                index) ??
            Icon(
              widget.stepIcon?.call(state) ?? Icons.check,
              color: isDarkActive ? _kCircleActiveDark : _kCircleActiveLight,
              size: 18.0,
            );
      case CleverStepState.error:
        return widget.stepIconBuilder?.call(state, _kStepStyle.color!, index) ??
            Text('!', style: _kStepStyle);
    }
  }

  Color _circleColor(int index) {
    // TODO: Support different styles based on brightness [_isDark()]
    final stepColor = widget.stepColor?.call(widget.steps[index].state);
    if (stepColor != null) {
      return stepColor;
    }
    if (widget.steps[index].isActive) {
      return widget.activeCircleColor;
    } else if (widget.steps[index].state == CleverStepState.complete) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildCircle(int index, bool oldState) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: _kStepSize,
      height: _kStepSize,
      child: AnimatedContainer(
        curve: Curves.fastOutSlowIn,
        duration: kThemeAnimationDuration,
        decoration: BoxDecoration(
          color: _circleColor(index),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: _buildCircleChild(index,
              oldState && widget.steps[index].state == CleverStepState.error),
        ),
      ),
    );
  }

  Widget _buildTriangle(int index, bool oldState) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: _kStepSize,
      height: _kStepSize,
      child: Center(
        child: SizedBox(
          width: _kStepSize,
          height: _kTriangleHeight,
          // Height of 24dp-long-sided equilateral triangle.
          child: CustomPaint(
            painter: _TrianglePainter(
              color: _isDark() ? _kErrorDark : _kErrorLight,
            ),
            child: Align(
              alignment: const Alignment(0.0, 0.8),
              // 0.8 looks better than the geometrical 0.33.
              child: _buildCircleChild(
                  index,
                  oldState &&
                      widget.steps[index].state != CleverStepState.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index) {
    if (widget.steps[index].state != _oldStates[index]) {
      return AnimatedCrossFade(
        firstChild: _buildCircle(index, true),
        secondChild: _buildTriangle(index, true),
        firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
        secondCurve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
        sizeCurve: Curves.fastOutSlowIn,
        crossFadeState: widget.steps[index].state == CleverStepState.error
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: kThemeAnimationDuration,
      );
    } else {
      if (widget.steps[index].state != CleverStepState.error) {
        return _buildCircle(index, false);
      } else {
        return _buildTriangle(index, false);
      }
    }
  }

  Widget _buildVerticalControls({required int index}) {
    if (widget.controlsBuilder != null) {
      return widget.controlsBuilder!(context,
          stepIndex: index,
          stepState: widget.steps[index].state,
          isStepActive: widget.steps[index].isActive,
          onStepContinue: widget.onStepContinue,
          onStepCancel: widget.onStepCancel);
    }

    final Color cancelColor;
    switch (Theme.of(context).brightness) {
      case Brightness.light:
        cancelColor = Colors.black54;
        break;
      case Brightness.dark:
        cancelColor = Colors.white70;
        break;
    }

    final ThemeData themeData = Theme.of(context);
    final ColorScheme colorScheme = themeData.colorScheme;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    const OutlinedBorder buttonShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)));
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 16.0);

    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(height: 48.0),
        child: Row(
          // The Material spec no longer includes a Stepper widget. The continue
          // and cancel button styles have been configured to match the original
          // version of this widget.
          children: <Widget>[
            TextButton(
              onPressed: () => widget.onStepContinue,
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return states.contains(MaterialState.disabled)
                      ? null
                      : (_isDark()
                          ? colorScheme.onSurface
                          : colorScheme.onPrimary);
                }),
                backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return _isDark() || states.contains(MaterialState.disabled)
                      ? null
                      : colorScheme.primary;
                }),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    buttonPadding),
                shape: MaterialStateProperty.all<OutlinedBorder>(buttonShape),
              ),
              child: Text(localizations.continueButtonLabel),
            ),
            Container(
              margin: const EdgeInsetsDirectional.only(start: 8.0),
              child: TextButton(
                onPressed: () => widget.onStepCancel,
                style: TextButton.styleFrom(
                  foregroundColor: cancelColor,
                  padding: buttonPadding,
                  shape: buttonShape,
                ),
                child: Text(localizations.cancelButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _titleStyle(int index) {
    final ThemeData themeData = Theme.of(context);
    final TextTheme textTheme = themeData.textTheme;

    switch (widget.steps[index].state) {
      case CleverStepState.indexed:
      case CleverStepState.editing:
      case CleverStepState.complete:
        return textTheme.bodyText1!;
      case CleverStepState.disabled:
        return textTheme.bodyText1!.copyWith(
          color: _isDark() ? _kDisabledDark : _kDisabledLight,
        );
      case CleverStepState.error:
        return textTheme.bodyText1!.copyWith(
          color: _isDark() ? _kErrorDark : _kErrorLight,
        );
    }
  }

  TextStyle _subtitleStyle(int index) {
    final ThemeData themeData = Theme.of(context);
    final TextTheme textTheme = themeData.textTheme;

    switch (widget.steps[index].state) {
      case CleverStepState.indexed:
      case CleverStepState.editing:
      case CleverStepState.complete:
        return textTheme.caption!;
      case CleverStepState.disabled:
        return textTheme.caption!.copyWith(
          color: _isDark() ? _kDisabledDark : _kDisabledLight,
        );
      case CleverStepState.error:
        return textTheme.caption!.copyWith(
          color: _isDark() ? _kErrorDark : _kErrorLight,
        );
    }
  }

  Widget _buildHeaderText(int index) {
    return ListTile(
      title: AnimatedDefaultTextStyle(
        style: _titleStyle(index),
        duration: kThemeAnimationDuration,
        curve: Curves.fastOutSlowIn,
        child: widget.steps[index].title,
      ),
      subtitle: (widget.steps[index].subtitle != null)
          ? Container(
              margin: const EdgeInsets.only(top: 2.0),
              child: AnimatedDefaultTextStyle(
                style: _subtitleStyle(index),
                duration: kThemeAnimationDuration,
                curve: Curves.fastOutSlowIn,
                child: widget.steps[index].subtitle!,
              ))
          : const SizedBox.shrink(),
      trailing: (widget.steps[index].subtitle != null)
          ? widget.steps[index].trailing!
          : const SizedBox.shrink(),
    );
  }

  Widget _buildVerticalHeader(int index) {
    return Container(
      margin: const EdgeInsets.only(left: 24.0),
      child: Row(
        children: <Widget>[
          Column(
            children: <Widget>[
              // Line parts are always added in order for the ink splash to
              // flood the tips of the connector lines.
              _buildLine(!_isFirst(index)),
              _buildIcon(index),
              _buildLine(!_isLast(index)),
            ],
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsetsDirectional.only(start: 12.0),
              child: _buildHeaderText(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBody(int index) {
    return AnimatedCrossFade(
      firstChild: Container(height: 0.0),
      secondChild: Container(
        margin: const EdgeInsetsDirectional.only(
          start: 16.0,
          end: 16.0,
        ),
        child: Column(
          children: <Widget>[
            widget.steps[index].content,
          ],
        ),
      ),
      firstCurve: const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
      secondCurve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
      sizeCurve: Curves.fastOutSlowIn,
      crossFadeState: _isCurrent(index)
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: kThemeAnimationDuration,
    );
  }

  Widget _buildVertical() {
    var activeStepContent = _buildVerticalBody(widget.currentStep);

    var stepList = ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: <Widget>[
        for (int i = 0; i < widget.steps.length; i += 1)
          widget.stepBuilder?.call(context, i, _buildStep(i)) ?? _buildStep(i),
      ],
    );
    return Column(
      children: [stepList, activeStepContent],
    );
  }

  Column _buildStep(int i) {
    return Column(
      key: _keys[i],
      children: <Widget>[
        InkWell(
          onLongPress: widget.steps[i].state != CleverStepState.disabled
              ? () {
                  // In the vertical case we need to scroll to the newly tapped
                  // step.
                  Scrollable.ensureVisible(
                    _keys[i].currentContext!,
                    curve: Curves.fastOutSlowIn,
                    duration: kThemeAnimationDuration,
                  );

                  widget.onStepLongPressed?.call(i);
                }
              : null,
          onTap: widget.steps[i].state != CleverStepState.disabled
              ? () {
                  // In the vertical case we need to scroll to the newly tapped
                  // step.
                  Scrollable.ensureVisible(
                    _keys[i].currentContext!,
                    curve: Curves.fastOutSlowIn,
                    duration: kThemeAnimationDuration,
                  );

                  widget.onStepTapped?.call(i);
                }
              : null,
          canRequestFocus: widget.steps[i].state != CleverStepState.disabled,
          child: _buildVerticalHeader(i),
        ),
        if (i == widget.currentStep)
          Transform.scale(
            scale: 0.8,
            child: _buildVerticalControls(index: widget.currentStep),
          ),
      ],
    );
  }

  Widget _buildHorizontal() {
    final List<Widget> children = <Widget>[
      for (int i = 0; i < widget.steps.length; i += 1) ...<Widget>[
        InkResponse(
          onTap: widget.steps[i].state != CleverStepState.disabled
              ? () {
                  widget.onStepTapped?.call(i);
                }
              : null,
          onLongPress: widget.steps[i].state != CleverStepState.disabled
              ? () {
                  widget.onStepLongPressed?.call(i);
                }
              : null,
          canRequestFocus: widget.steps[i].state != CleverStepState.disabled,
          child: Row(
            children: <Widget>[
              SizedBox(
                height: 72.0,
                child: Center(
                  child: _buildIcon(i),
                ),
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 12.0),
                child: _buildHeaderText(i),
              ),
            ],
          ),
        ),
        if (!_isLast(i))
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              height: 1.0,
              color: Colors.grey.shade400,
            ),
          ),
      ],
    ];

    return Column(
      children: <Widget>[
        Material(
          elevation: 2.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: children,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            physics: widget.physics,
            padding: const EdgeInsets.all(24.0),
            children: <Widget>[
              AnimatedSize(
                curve: Curves.fastOutSlowIn,
                duration: kThemeAnimationDuration,
                child: widget.steps[widget.currentStep].content,
              ),
              _buildVerticalControls(index: widget.currentStep),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    assert(() {
      if (context.findAncestorWidgetOfExactType<CleverStepper>() != null) {
        throw FlutterError(
          'Steppers must not be nested.\n'
          'The material specification advises that one should avoid embedding '
          'steppers within steppers. '
          'https://material.io/archive/guidelines/components.dart/steppers.html#steppers-usage',
        );
      }
      return true;
    }());
    switch (widget.type) {
      case CleverStepperType.vertical:
        return _buildVertical();
      case CleverStepperType.horizontal:
        return _buildHorizontal();
    }
  }
}

// Paints a triangle whose base is the bottom of the bounding rectangle and its
// top vertex the middle of its top.
class _TrianglePainter extends CustomPainter {
  _TrianglePainter({
    required this.color,
  });

  final Color color;

  @override
  bool hitTest(Offset point) => true; // Hitting the rectangle is fine enough.

  @override
  bool shouldRepaint(_TrianglePainter oldPainter) {
    return oldPainter.color != color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double base = size.width;
    final double halfBase = size.width / 2.0;
    final double height = size.height;
    final List<Offset> points = <Offset>[
      Offset(0.0, height),
      Offset(base, height),
      Offset(halfBase, 0.0),
    ];

    canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()..color = color,
    );
  }
}

/// A builder that creates a widget given the two callbacks `onStepContinue` and
/// `onStepCancel` and gives `stepIndex`, `stepState`, and `isStepActive`.
///
/// Used by [CleverStepper.controlsBuilder].
///
/// See also:
///
///  * [WidgetBuilder], which is similar but only takes a [BuildContext].
typedef CleverControlsWidgetBuilder = Widget Function(BuildContext context,
    {int stepIndex,
    CleverStepState stepState,
    bool isStepActive,
    Function({dynamic value})? onStepContinue,
    Function({dynamic value})? onStepCancel});

/// controller that can call onStepContinue() and onStepCancel() outside of the controls widget
class CleverStepController {
  _StepperState? _stepperState;

  void _bindState(_StepperState state) {
    _stepperState = state;
  }

  void dispose() {
    _stepperState = null;
  }

  bool get isMounted {
    return _stepperState?.mounted == true;
  }

  void onStepContinue({dynamic value}) {
    _stepperState?.widget.onStepContinue?.call(value: value);
  }

  void onStepCancel({dynamic value}) {
    _stepperState?.widget.onStepCancel?.call(value: value);
  }

  int get currentStepIndex => _stepperState!.widget.currentStep;

  CleverStepState getStepState(int index) {
    return _stepperState!.widget.steps[index].state;
  }
}
