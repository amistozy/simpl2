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
  let mut sum : Double = 0.0
  for i = 0; i < args.length(); i = i + 1 {
    sum = sum + expect_num("+", args[i])
  }
  Num(sum)
}

///|
fn builtin_sub(args : Array[Value]) -> Value raise EvalError {
  check_min_arity("-", 1, args.length())
  if args.length() == 1 {
    Num(-expect_num("-", args[0]))
  } else {
    let mut result = expect_num("-", args[0])
    for i = 1; i < args.length(); i = i + 1 {
      result = result - expect_num("-", args[i])
    }
    Num(result)
  }
}

///|
fn builtin_mul(args : Array[Value]) -> Value raise EvalError {
  let mut product : Double = 1.0
  for i = 0; i < args.length(); i = i + 1 {
    product = product * expect_num("*", args[i])
  }
  Num(product)
}

///|
fn builtin_div(args : Array[Value]) -> Value raise EvalError {
  check_min_arity("/", 1, args.length())
  if args.length() == 1 {
    Num(1.0 / expect_num("/", args[0]))
  } else {
    let mut result = expect_num("/", args[0])
    for i = 1; i < args.length(); i = i + 1 {
      result = result / expect_num("/", args[i])
    }
    Num(result)
  }
}

///|
/// ------------------ Comparison ------------------

///|
fn builtin_eq(args : Array[Value]) -> Value raise EvalError {
  check_min_arity("=", 2, args.length())
  for i = 0; i < args.length() - 1; i = i + 1 {
    if !num_eq(args[i], args[i + 1]) {
      return Bool(false)
    }
  }
  Bool(true)
}

///|
fn num_eq(a : Value, b : Value) -> Bool {
  match (a, b) {
    (Num(x), Num(y)) => x == y
    _ => false
  }
}

///|
fn builtin_lt(args : Array[Value]) -> Value raise EvalError {
  check_arity("<", 2, args.length())
  let x = expect_num("<", args[0])
  let y = expect_num("<", args[1])
  Bool(x < y)
}

///|
fn builtin_gt(args : Array[Value]) -> Value raise EvalError {
  check_arity(">", 2, args.length())
  let x = expect_num(">", args[0])
  let y = expect_num(">", args[1])
  Bool(x > y)
}

///|
fn builtin_le(args : Array[Value]) -> Value raise EvalError {
  check_arity("<=", 2, args.length())
  let x = expect_num("<=", args[0])
  let y = expect_num("<=", args[1])
  Bool(x <= y)
}

///|
fn builtin_ge(args : Array[Value]) -> Value raise EvalError {
  check_arity(">=", 2, args.length())
  let x = expect_num(">=", args[0])
  let y = expect_num(">=", args[1])
  Bool(x >= y)
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
  Nil
}

///|
fn builtin_newline(args : Array[Value]) -> Value raise EvalError {
  check_arity("newline", 0, args.length())
  println("")
  Nil
}

///|
/// ------------------ Logic ------------------

///|
fn builtin_not(args : Array[Value]) -> Value raise EvalError {
  check_arity("not", 1, args.length())
  Bool(!is_truthy(args[0]))
}

///|
#warnings("-unused_error_type")
fn builtin_and(args : Array[Value]) -> Value raise EvalError {
  for i = 0; i < args.length(); i = i + 1 {
    if !is_truthy(args[i]) {
      return Bool(false)
    }
  }
  if args.length() == 0 {
    Bool(true)
  } else {
    args[args.length() - 1]
  }
}

///|
#warnings("-unused_error_type")
fn builtin_or(args : Array[Value]) -> Value raise EvalError {
  for i = 0; i < args.length(); i = i + 1 {
    if is_truthy(args[i]) {
      return args[i]
    }
  }
  Bool(false)
}

///|
/// Register all built-in procedures into an environment.
pub fn register_builtins(env : Env) -> Unit {
  env.bind("+", BuiltinProc("+", builtin_add))
  env.bind("-", BuiltinProc("-", builtin_sub))
  env.bind("*", BuiltinProc("*", builtin_mul))
  env.bind("/", BuiltinProc("/", builtin_div))
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
  env.bind("and", BuiltinProc("and", builtin_and))
  env.bind("or", BuiltinProc("or", builtin_or))
  // Predefined constants
  env.bind("#t", Bool(true))
  env.bind("#f", Bool(false))
  env.bind("nil", Nil)
}
