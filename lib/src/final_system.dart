
import 'package:flutter_scope/flutter_scope.dart';
import 'package:love/love.dart';

/// `FinalSystem` is a configuration that creates a running system,
/// then expose its `States<State>` and `Observer<Event>`.
/// 
/// ```dart
/// 
/// System<CounterState, CounterEvent> createCounterSystem() { ... }
/// 
/// ...
/// 
/// FlutterScope(
///   configure: [
///     FinalSystem<CounterState, CounterEvent>(
///       equal: (scope) => createCounterSystem(),
///     ),
///   ],
///   child: Builder(
///     builder: (context) {
///       final myCounterStates = context.scope.getStates<CounterState>();
///       final myEventObserver = context.scope.get<Observer<CounterEvent>>();
///       return CounterPage(
///         counterStates: myCounterStates,
///         onIncreasePressed: () => myEventObserver.onData(Increment()),
///       );
///     },
///   ),
/// );
/// ```
/// 
/// Which simulates:
/// 
/// ```dart
/// void flutterScope() async {
/// 
///   // create a running system then exposes its states and event observer
///   final System<CounterState, CounterEvent> system = createCounterSystem();
///   final (states, eventObserver) = runSystemThenExposeStatesAndEventObserver(system);
///   
///   // resolve states and event observer in current scope
///   final States<CounterState> myCounterStates = states;
///   final Observer<CounterEvent> myEventObserver = eventObserver;
/// 
///   // notify user about state updates
///   final observation = myCounterStates.observe((count) {
///     print('You have pushed the button this many times: $count');
///   });
///   
///   // simulate user tap increase button asynchronously
///   await Future.delayed(const Duration(seconds: 3));
///   myEventObserver.onData(Increment());
///   
/// }
/// ```
///
class FinalSystem<State, Event> implements Configurable {

  FinalSystem({
    required Equal<System<State, Event>> equal,
    Object? statesName,
    Object? observerName,
    bool lazy = true,
  }): _equal = equal,
    _statesName = statesName,
    _observerName = observerName,
    _lazy = lazy;

  final Equal<System<State, Event>> _equal;
  final Object? _statesName;
  final Object? _observerName;
  final bool _lazy;

  @override
  FutureOr<void> configure(ConfigurableScope scope) {
    final Getter<_Store<State, Event>> getStore;
    final Getter<States<State>> getStates;
    if (_lazy) {
      late final store = _Store<State, Event>(
        _equal(scope)
      );
      late final states = States<State>.from(store);
      getStore = () => store;
      getStates = () => states;
    } else {
      final store = _Store<State, Event>(
        _equal(scope)
      );
      final states = States<State>.from(store);
      getStore = () => store;
      getStates = () => states;
    }
    scope
      ..expose<States<State>>(
        name: _statesName,
        expose: getStates,
      )
      ..expose<Observer<Event>>(
        name: _observerName,
        expose: getStore,
      )
      ..addDispose(() => getStore().dispose());
  }
}

class _Store<State, Event> implements Observable<State>, Observer<Event>, Disposable {

  _Store(this._system) {
    init();
  }

  final System<State, Event> _system;
  
  Replayer<State>? _replayer;
  Dispatch<Event>? _dispatch;
  Disposer? _disposer;

  bool _disposed = false;

  void init() {
    _replayer = Replayer<State>(bufferSize: 1);
    _disposer = _system.run(
      effect: (state, oldState, event, dispatch) {
        _replayer?.onData(state);
        _dispatch = dispatch;
      },
    );
  }
  
  @override
  Disposable observe(OnData<State> onData) {
    assert(!_disposed, 'Start observe a store which has been disposed.');
    return _replayer?.observe(onData) ?? Disposable.empty;
  }

  @override
  void onData(Event data) {
    _dispatch?.call(data);
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _disposer?.call();
    _disposer = null;
    _dispatch = null;
    _replayer?.dispose();
    _replayer = null;
  }
}