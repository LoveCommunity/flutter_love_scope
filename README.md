# flutter_love_scope

[![Build Status](https://github.com/LoveCommunity/flutter_love_scope/workflows/Tests/badge.svg)](https://github.com/LoveCommunity/flutter_love_scope/actions/workflows/tests.yml)
[![Coverage Status](https://img.shields.io/codecov/c/github/LoveCommunity/flutter_love_scope/main.svg)](https://codecov.io/gh/LoveCommunity/flutter_love_scope)
[![Pub](https://img.shields.io/pub/v/flutter_love_scope)](https://pub.dev/packages/flutter_love_scope)

`flutter_love_scope` provide flutter widgets for supporting solution base on [flutter_scope] and [love].

## Prerequisite

Since `flutter_love_scope` has knowledge dependencies of [flutter_scope] and [love]. It's good practice to learn them before using `flutter_love_scope`. Here are documentation sites:
  * [flutter_scope]
  * [love]

## Overview

`flutter_love_scope` included and re-exported package [flutter_scope] and [love]. 

`flutter_love_scope` also provide a configurable `FinalSystem` for integrating
`System` with flutter.


## FinalSystem

`FinalSystem` is a configuration that creates a running system,
then expose its `States<State>` and `Observer<Event>`.

```dart
System<CounterState, CounterEvent> createCounterSystem() { ... }

...

FlutterScope(
  configure: [
    FinalSystem<CounterState, CounterEvent>(
      equal: (scope) => createCounterSystem(),
    ),
  ],
  child: Builder(
    builder: (context) {
      final myCounterStates = context.scope.getStates<CounterState>();
      final myEventObserver = context.scope.get<Observer<CounterEvent>>();
      return CounterPage(
        counterStates: myCounterStates,
        onIncreasePressed: () => myEventObserver.onData(Increment()),
      );
    },
  ),
);
```

Which simulates:

```dart
void flutterScope() async {

  // create a running system then exposes its states and event observer
  final System<CounterState, CounterEvent> system = createCounterSystem();
  final (states, eventObserver) = runSystemThenExposeStatesAndEventObserver(system);
  
  // resolve states and event observer in current scope
  final States<CounterState> myCounterStates = states;
  final Observer<CounterEvent> myEventObserver = eventObserver;

  // notify user about state updates
  final observation = myCounterStates.observe((count) {
    print('You have pushed the button this many times: $count');
  });
  
  // simulate user tap increase button asynchronously
  await Future.delayed(const Duration(seconds: 3));
  myEventObserver.onData(Increment());
  
}
```


## License

The MIT License (MIT)

[flutter_scope]:https://pub.dev/packages/flutter_scope
[love]:https://pub.dev/packages/love