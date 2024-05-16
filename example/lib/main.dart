import 'package:clever_stepper/clever_stepper.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> steps = ['Shape up', 'Waiting', 'In progress', 'Test'];
  int currentStep = 0;

  num completedStep = 0;
  void _incrementCounter() {
    print('current step is ${_stepController.currentStepIndex}');
    print(
        'current step state ${_stepController.getStepState(_stepController.currentStepIndex)}');

    _stepController.onStepContinue();
  }

  var _stepController = CleverStepController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: CleverStepper(
          currentStep: currentStep,
          controller: _stepController,
          onStepContinue: ({value}) {
            setState(() {
              currentStep++;
              completedStep++;
            });
            print('complete');
          },
          onStepCancel: ({value}) {
            setState(() {
              currentStep--;
              completedStep--;
            });
            print('cancel');
          },
          controlsBuilder: (ctx,
              {bool? isStepActive,
              dynamic Function({dynamic value})? onStepCancel,
              dynamic Function({dynamic value})? onStepContinue,
              int? stepIndex,
              CleverStepState? stepState}) {
                return const SizedBox();
              },
          steps: steps
              .map((e) => CleverStep(
                  title: Text(e),
                  state: steps.indexOf(e) <= completedStep
                      ? CleverStepState.complete
                      : CleverStepState.disabled,
                  content: ListTile(
                    title: Text(e),
                  )))
              .toList(),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
          SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              _stepController.onStepCancel();
            },
            tooltip: 'Decrement',
            child: const Icon(Icons.remove),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
