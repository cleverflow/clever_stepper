# CleverStepper
Modified version of Stepper from material library with extra juices. Maintained by [CleverFlow](https://cleverflowhq.com).

### How's it different from Stepper from Material?
The `controlsBuilder()` in Material's Stepper doesn't have the context of the step for which the builder is called. Because of this, it's not possible to customize the controls depending of the `step` or it's status. `CleverStepper` solves that. 
 
## Installing
Run `flutter pub add clever_stepper`. This will as `clever_stepper` as a dependency in your `pubspec.yaml`.

## Usage
Apart from the regular niceties of [Stepper](https://api.flutter.dev/flutter/material/Stepper-class.html) widget from the Material.dart class, this package provides three extra params in the `controlsBuilder()` override. These are as follows:

> *Note*: `controlsBuilder()` is called for each step.

|    Property            |Type                          |Description                         |
|----------------|-------------------------------|-----------------------------|
|`stepIndex`| int        |Step's index        |
|`stepState`          |CleverStepState           |CleverStepState for the step           |
|`isStepActive`          |bool|Whether or not the step is active.|

