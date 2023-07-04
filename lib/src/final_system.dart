
import 'package:flutter_scope/flutter_scope.dart';
import 'package:love/love.dart';

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