import 'package:flutter/material.dart';
import 'package:flutter_love_scope/flutter_love_scope.dart';


typedef CounterState = int;

abstract class CounterEvent {}
class Increment implements CounterEvent {}
class Decrement implements CounterEvent {}

System<CounterState, CounterEvent> createCounterSystem() {
  return System<CounterState, CounterEvent>
    .create(initialState: 0)
    .on<Increment>(
      reduce: (state, event) => state + 1,
      effect: (state, event, dispatch) async {
        await Future<void>.delayed(const Duration(seconds: 3));
        dispatch(Decrement());
      },
    )
    .on<Decrement>(
      reduce: (state, event) => state - 1,
    )
    .log()
    .reactState(
      effect: (state, dispatch) {
        // ignore: avoid_print
        print('Simulate persistence save call with state: $state');
      },
    );
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterScope(
      configure: [
        FinalSystem<CounterState, CounterEvent>(
          equal: (scope) => createCounterSystem(),
        ),
      ],
      child: Builder(
        builder: (context) => CounterPage(
          title: 'Counter',
          counterStates: context.scope.getStates(),
          onIncreasePressed: () => context.scope.get<Observer<CounterEvent>>()
            .onData(Increment()),
        ),
      ),
    );
  }
}

class CounterPage extends StatelessWidget {

  const CounterPage({
    super.key,
    required this.title,
    required this.counterStates,
    required this.onIncreasePressed,
  });

  final String title;
  final States<CounterState> counterStates;
  final VoidCallback onIncreasePressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            StatesBuilder<CounterState>(
              states: counterStates,
              builder: (context, count, _) => Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onIncreasePressed,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}