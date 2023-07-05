
import 'package:flutter_love_scope/flutter_love_scope.dart';
import 'package:test/test.dart';

void main() {

  test('FinalSystem expose states and observer', () async {

    final scope = await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => _createTestSystem(),
      ),
    ]);

    expect(scope.hasStates<String>(), true);
    expect(scope.has<Observer<String>>(), true);

  });

  test('FinalSystem expose states and observer with name', () async {

    final scope = await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => _createTestSystem(),
        statesName: 'states',
        observerName: 'observer',
      ),
    ]);

    expect(scope.hasStates<String>(), false);
    expect(scope.has<Observer<String>>(), false);
    expect(scope.hasStates<String>(name: 'states'), true);
    expect(scope.has<Observer<String>>(name: 'observer'), true);

  });

  test('FinalSystem states updates caused by dispatching event', () async {

    final recorded = <String>[];

    final scope = await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => _createTestSystem(),
      ),
    ]);

    final states = scope.getStates<String>();
    final observer = scope.get<Observer<String>>();

    final observation = states.observe(recorded.add);
    expect(recorded, [
      'a',
    ]);

    observer.onData('b');
    expect(recorded, [
      'a',
      'a|b',
    ]);

    observer.onData('c');
    expect(recorded,  [
      'a',
      'a|b',
      'a|b|c',
    ]);

    scope.dispose();
    observer.onData('d'); // event is ignored after scope been disposed
    expect(recorded,  [
      'a',
      'a|b',
      'a|b|c',
    ]);

    observation.dispose();

  });

  test('FinalSystem throw assert error when observing states after scope been disposed', () async {

    final scope = await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => _createTestSystem(),
      ),
    ]);

    final states = scope.getStates<String>();
    scope.dispose();

    expect(
      () {
        states.observe((_) {});
      },
      throwsA(
        isA<AssertionError>()
          .having(
            (error) => error.toString(),
            'description',
            contains('Start observe a store which has been disposed.'),
          ),
      ),
    );
    
  });

  test('FinalSystem run lazily when lazy is omitted', () async {

    int invokes = 0;

    final system = _createTestSystem()
      .onRun(effect: (initialState, dispatch) {
        invokes += 1;
        return null;
      });
    
    final scope = await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => system,
        // lazy: ..., // lazy is omitted
      ),
    ]);
    expect(invokes, 0);

    scope.getStates<String>();
    expect(invokes, 1);

  });

  test('FinalSystem run lazily when lazy is true', () async {

    int invokes = 0;

    final system = _createTestSystem()
      .onRun(effect: (initialState, dispatch) {
        invokes += 1;
        return null;
      });
    
    final scope = await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => system,
        lazy: true, // lazy is true
      ),
    ]);
    expect(invokes, 0);

    scope.getStates<String>();
    expect(invokes, 1);

  });

  test('FinalSystem run immediately when lazy is false', () async {

    int invokes = 0;

    final system = _createTestSystem()
      .onRun(effect: (initialState, dispatch) {
        invokes += 1;
        return null;
      });
    
    await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => system,
        lazy: false, // lazy is false
      ),
    ]);
    expect(invokes, 1);

  });

  test('FinalSystem test coverage', () async {

    final scope = await Scope.root([
      FinalSystem<String, String>(
        equal: (scope) => _createTestSystem(),
        lazy: false,
      ),
    ]);

    scope.getStates<String>();
    scope.get<Observer<String>>();

    // expect not throws error

  });
}

System<String, String> _createTestSystem({
  String initialState = 'a'
}) => System<String, String>
  .create(initialState: initialState)
  .add(reduce: (state, event) => '$state|$event');