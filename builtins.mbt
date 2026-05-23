///|
/// SimpL Built-in Procedures.
///
/// All builtins take an Array of already-evaluated arguments
/// and return a Value, possibly raising EvalError.

///|
fn check_arity(name : String, expect : Int, got : Int) -> Unit raise EvalError {
  if expect != got {
    raise EvalError::ArityMismatch(name, expect, got)
  }
}

///|
fn check_min_arity(name : String, min : Int, got : Int) -> Unit raise EvalError {
  if got < min {
    raise EvalError::ArityMismatch(name, min, got)
  }
}

///|
/// Expect a numeric argument; raise TypeMismatch otherwise.
fn expect_num(name : String, v : Value) -> Double raise EvalError {
  match v {
    Num(n) => n
    _ => raise EvalError::TypeMismatch(name, v.display())
  }
}

///|
/// ------------------ Arithmetic ------------------

///|
fn builtin_add(args : Array[Value]) -> Value raise EvalError {
  Num(args.fold(init=0.0, (sum, v) => sum + expect_num("+", v)))
}

///|
fn builtin_sub(args : Array[Value]) -> Value raise EvalError {
  match args {
    [x] => Num(-expect_num("-", x))
    [x, .. rest] =>
      Num(
        rest.fold(init=expect_num("-", x), (acc, v) => acc - expect_num("-", v)),
      )
    _ => raise EvalError::ArityMismatch("-", 1, args.length())
  }
}

///|
fn builtin_mul(args : Array[Value]) -> Value raise EvalError {
  Num(args.fold(init=1.0, (product, v) => product * expect_num("*", v)))
}

///|
fn builtin_div(args : Array[Value]) -> Value raise EvalError {
  match args {
    [x] => Num(1.0 / expect_num("/", x))
    [x, .. rest] =>
      Num(
        rest.fold(init=expect_num("/", x), (acc, v) => acc / expect_num("/", v)),
      )
    _ => raise EvalError::ArityMismatch("/", 1, args.length())
  }
}

///|
fn builtin_add1(args : Array[Value]) -> Value raise EvalError {
  check_arity("add1", 1, args.length())
  Num(expect_num("add1", args[0]) + 1.0)
}

///|
fn builtin_sub1(args : Array[Value]) -> Value raise EvalError {
  check_arity("sub1", 1, args.length())
  Num(expect_num("sub1", args[0]) - 1.0)
}

///|
fn builtin_zero_p(args : Array[Value]) -> Value raise EvalError {
  check_arity("zero?", 1, args.length())
  Bool(expect_num("zero?", args[0]) == 0.0)
}

///|
/// ------------------ Comparison ------------------

///|
fn builtin_eq(args : Array[Value]) -> Value raise EvalError {
  check_min_arity("=", 2, args.length())
  for i in 0..<(args.length() - 1) {
    let x = expect_num("=", args[i])
    let y = expect_num("=", args[i + 1])
    if x != y {
      return Bool(false)
    }
  }
  Bool(true)
}

///|
fn builtin_lt(args : Array[Value]) -> Value raise EvalError {
  check_min_arity("<", 2, args.length())
  for i in 0..<(args.length() - 1) {
    let x = expect_num("<", args[i])
    let y = expect_num("<", args[i + 1])
    if x >= y {
      return Bool(false)
    }
  }
  Bool(true)
}

///|
fn builtin_gt(args : Array[Value]) -> Value raise EvalError {
  check_min_arity(">", 2, args.length())
  for i in 0..<(args.length() - 1) {
    let x = expect_num(">", args[i])
    let y = expect_num(">", args[i + 1])
    if x <= y {
      return Bool(false)
    }
  }
  Bool(true)
}

///|
fn builtin_le(args : Array[Value]) -> Value raise EvalError {
  check_min_arity("<=", 2, args.length())
  for i in 0..<(args.length() - 1) {
    let x = expect_num("<=", args[i])
    let y = expect_num("<=", args[i + 1])
    if x > y {
      return Bool(false)
    }
  }
  Bool(true)
}

///|
fn builtin_ge(args : Array[Value]) -> Value raise EvalError {
  check_min_arity(">=", 2, args.length())
  for i in 0..<(args.length() - 1) {
    let x = expect_num(">=", args[i])
    let y = expect_num(">=", args[i + 1])
    if x < y {
      return Bool(false)
    }
  }
  Bool(true)
}

///|
/// ------------------ List Operations ------------------

///|
fn builtin_cons(args : Array[Value]) -> Value raise EvalError {
  check_arity("cons", 2, args.length())
  Pair(args[0], args[1])
}

///|
fn builtin_car(args : Array[Value]) -> Value raise EvalError {
  check_arity("car", 1, args.length())
  match args[0] {
    Pair(car, _) => car
    _ => raise EvalError::TypeMismatch("car", args[0].display())
  }
}

///|
fn builtin_cdr(args : Array[Value]) -> Value raise EvalError {
  check_arity("cdr", 1, args.length())
  match args[0] {
    Pair(_, cdr) => cdr
    _ => raise EvalError::TypeMismatch("cdr", args[0].display())
  }
}

///|
#warnings("-unused_error_type")
fn builtin_list(args : Array[Value]) -> Value raise EvalError {
  list_from_array(args)
}

///|
fn builtin_is_null(args : Array[Value]) -> Value raise EvalError {
  check_arity("null?", 1, args.length())
  match args[0] {
    Nil => Bool(true)
    _ => Bool(false)
  }
}

///|
/// ------------------ Type Predicates ------------------

///|
fn builtin_is_number(args : Array[Value]) -> Value raise EvalError {
  check_arity("number?", 1, args.length())
  match args[0] {
    Num(_) => Bool(true)
    _ => Bool(false)
  }
}

///|
fn builtin_is_symbol(args : Array[Value]) -> Value raise EvalError {
  check_arity("symbol?", 1, args.length())
  match args[0] {
    Sym(_) => Bool(true)
    _ => Bool(false)
  }
}

///|
fn builtin_is_string(args : Array[Value]) -> Value raise EvalError {
  check_arity("string?", 1, args.length())
  match args[0] {
    Str(_) => Bool(true)
    _ => Bool(false)
  }
}

///|
fn builtin_is_pair(args : Array[Value]) -> Value raise EvalError {
  check_arity("pair?", 1, args.length())
  match args[0] {
    Pair(_, _) => Bool(true)
    _ => Bool(false)
  }
}

///|
fn builtin_is_bool(args : Array[Value]) -> Value raise EvalError {
  check_arity("bool?", 1, args.length())
  match args[0] {
    Bool(_) => Bool(true)
    _ => Bool(false)
  }
}

///|
/// ------------------ Output ------------------

///|
fn builtin_display(args : Array[Value]) -> Value raise EvalError {
  check_arity("display", 1, args.length())
  match args[0] {
    Str(s) => println(s)
    _ => println(args[0].display())
  }
  Void
}

///|
fn builtin_newline(args : Array[Value]) -> Value raise EvalError {
  check_arity("newline", 0, args.length())
  println("")
  Void
}

///|
/// ------------------ Logic ------------------

///|
fn builtin_not(args : Array[Value]) -> Value raise EvalError {
  check_arity("not", 1, args.length())
  Bool(!is_truthy(args[0]))
}

///|
/// Register all built-in procedures into an environment.
pub fn register_builtins(env : Env) -> Unit {
  env.bind("+", BuiltinProc("+", builtin_add))
  env.bind("-", BuiltinProc("-", builtin_sub))
  env.bind("*", BuiltinProc("*", builtin_mul))
  env.bind("/", BuiltinProc("/", builtin_div))
  env.bind("add1", BuiltinProc("add1", builtin_add1))
  env.bind("sub1", BuiltinProc("sub1", builtin_sub1))
  env.bind("zero?", BuiltinProc("zero?", builtin_zero_p))
  env.bind("=", BuiltinProc("=", builtin_eq))
  env.bind("<", BuiltinProc("<", builtin_lt))
  env.bind(">", BuiltinProc(">", builtin_gt))
  env.bind("<=", BuiltinProc("<=", builtin_le))
  env.bind(">=", BuiltinProc(">=", builtin_ge))
  env.bind("cons", BuiltinProc("cons", builtin_cons))
  env.bind("car", BuiltinProc("car", builtin_car))
  env.bind("cdr", BuiltinProc("cdr", builtin_cdr))
  env.bind("list", BuiltinProc("list", builtin_list))
  env.bind("null?", BuiltinProc("null?", builtin_is_null))
  env.bind("number?", BuiltinProc("number?", builtin_is_number))
  env.bind("symbol?", BuiltinProc("symbol?", builtin_is_symbol))
  env.bind("string?", BuiltinProc("string?", builtin_is_string))
  env.bind("pair?", BuiltinProc("pair?", builtin_is_pair))
  env.bind("bool?", BuiltinProc("bool?", builtin_is_bool))
  env.bind("display", BuiltinProc("display", builtin_display))
  env.bind("newline", BuiltinProc("newline", builtin_newline))
  env.bind("not", BuiltinProc("not", builtin_not))
  // Predefined constants
  env.bind("#t", Bool(true))
  env.bind("#f", Bool(false))
  env.bind("nil", Nil)
}
