enum SequenceResult {
  Next,
  Prev,
  Hold, // won't reset timer
  Repeat, // will reset timer
  Abort,
  Restart
}

enum SequencePlanStatus {
  Okay,
  Aborted,
  Done
}

/// @func SequencePlan([_context])
function SequencePlan(_context=undefined) constructor {
  
  context = _context;
  plan = []; // array of methods
  
  /// @func next(_func, [_times])
  static next = function(_func, _times = 1) {
    repeat (_times) {
      array_push(plan, [_func]);
    }
    
    return self;
  }
  
  /// @func connect(_func)
  static connect = function(_func) {
    if (array_length(plan) <= 0) {
      return next(_func);
    }
    
    array_push(array_last(plan), _func);
    
    return self;
  }
  
  /// @func wait(_steps)
  static wait = function(_steps) {
    return next(method({_steps}, function(_timer) {
      if (_timer >= _steps) {
        return SequenceResult.Next;
      }
      return SequenceResult.Hold;
    }));
  }
  
  /// @func handle(_handler)
  static handle = function(_handler) {
    if (array_length(plan) <= 0) {
      throw "Nothing to attach handler to.";
    }
    
    var _idx = array_length(plan) - 1;
    
    if (array_length(plan[_idx]) <= 0) {
      throw "Nothing to attach handler to.";
    }
    
    var _pos = array_length(plan[_idx]) - 1;
    
    plan[_idx][_pos] = compose(_handler, plan[_idx][_pos]);
    
    return self;
  }
  
  /// @func on(_result, _handler)
  static on = function(_result, _handler) {
    return handle(method({_result, _handler}, function(_actual) {
      if (_result == _actual) {
        return _handler(_actual);
      }
      return _actual;
    }));
  }
  
  /// @func execute([_dt])
  static execute = function(_dt=dt_real) {
    #region Check status
    if (!has_next()) {
      status = SequencePlanStatus.Done;
    }
    
    if (status != SequencePlanStatus.Okay) {
      return status;
    }
    #endregion
    
    var _func_arr = plan[plan_idx];
    
    var _i = 0;
    repeat (array_length(_func_arr)) {
      var _func = _func_arr[_i];
      
      #region Get result
      var _result = SequenceResult.Next;
      if (is_undefined(context)) {
        _result = _func(timer);
      } else {
        var _timer = timer;
        with (context) {
          _result = _func(_timer);
        }
      }
      #endregion
      
      // Only result of the host matters
      if (_i > 0) continue;
      
      #region ..and handle result
      switch (_result) {
        case undefined: // default
        case SequenceResult.Next:
          plan_idx++;
          timer = 0;
        break;
        
        case SequenceResult.Hold:
          timer += _dt;
        break;
        
        case SequenceResult.Prev:
          plan_idx--;
          timer = 0;
        break;
        
        case SequenceResult.Repeat:
          timer = 0;
        break;
        
        case SequenceResult.Abort:
          status = SequencePlanStatus.Aborted;
          exit;
        
        case SequenceResult.Restart:
          restart();
          exit;
      }
      #endregion
      
      ++_i;
    }
  }
  
  /// @func get_progress()
  static get_progress = function() {
    var _len = get_sequence_length();
    if (_len == 0) {
      throw "Can't call `get_progress` on an empty sequence.";
    }
    return plan_idx / _len;
  }
  
  /// @func get_sequence_length()
  static get_sequence_length = function() {
    return array_length(plan);
  }
  
  /// @func has_next()
  static has_next = function() {
    return (plan_idx >= 0 && plan_idx < get_sequence_length());
  }
  
  /// @func restart()
  static restart = function() {
    status = SequencePlanStatus.Okay;
    timer = 0;
    
    plan_idx = 0;
  }
  restart();
}
