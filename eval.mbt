///|
/// SimpL Evaluator — the heart of the interpreter.
///
/// Evaluates an S-expression in a given lexical environment.
/// Supports special forms: quote, if, lambda, define, begin, set!.

///|
/// Create an empty environment.
pub fn Env::new() -> Env {
  { bindings: {}, parent: None }
}

///|
/// Look up a variable by name in the environment chain.
/// Returns the bound value or raises UnboundVariable.
pub fn Env::lookup(self : Env, name : String) -> Value raise EvalError {
  match self.bindings.get(name) {
    Some(v) => v
    None =>
      match self.parent {
        Some(p) => p.lookup(name)
        None => raise EvalError::UnboundVariable(name)
      }
  }
}

///|
/// Define (or shadow) a variable in the current frame.
pub fn Env::bind(self : Env, name : String, value : Value) -> Unit {
  self.bindings[name] = value
}

///|
/// Mutate an existing variable binding.
/// Searches up the environment chain; raises if not found.
pub fn Env::set(
  self : Env,
  name : String,
  value : Value,
) -> Unit raise EvalError {
  if self.bindings.contains(name) {
    self.bindings[name] = value
  } else {
    match self.parent {
      Some(p) => p.set(name, value)
      None => raise EvalError::UnboundVariable(name)
    }
  }
}

///|
/// Extend an environment with new bindings for a lambda application.
/// params: list of symbols (or a single symbol for variadic).
/// args: array of already-evaluated argument values.
pub fn Env::extend(
  parent : Env,
  params : Value,
  args : Array[Value],
) -> Env raise EvalError {
  fn go(
    params : Value,
    idx : Int,
    bindings : Map[String, Value],
  ) -> Map[String, Value] raise EvalError {
    match params {
      Nil => {
        if idx != args.length() {
          raise EvalError::ArityMismatch("<lambda>", idx, args.length())
        }
        bindings
      }
      Pair(Sym(name), rest) => {
        if idx >= args.length() {
          raise EvalError::ArityMismatch("<lambda>", idx, args.length())
        }
        bindings[name] = args[idx]
        go(rest, idx + 1, bindings)
      }
      Sym(name) => {
        // Variadic: bind remaining args as a list
        let rest_args : Array[Value] = []
        for j in idx..<args.length() {
          rest_args.push(args[j])
        }
        bindings[name] = list_from_array(rest_args)
        bindings
      }
      _ => raise EvalError::TypeMismatch("lambda params", params.display())
    }
  }
  { bindings: go(params, 0, {}), parent: Some(parent) }
}

///|
/// Create the global environment with all built-in procedures.
pub fn global_env() -> Env {
  let env = Env::new()
  register_builtins(env)
  env
}

///|
/// Evaluate a sequence of expressions; return the last value.
fn eval_sequence(exprs : Value, env : Env) -> Value raise EvalError {
  match exprs {
    Nil => Nil
    Pair(expr, Nil) => eval(expr, env)
    Pair(expr, rest) => {
      let _ = eval(expr, env)
      eval_sequence(rest, env)
    }
    _ => raise EvalError::TypeMismatch("begin", exprs.display())
  }
}

///|
/// Evaluate all arguments in a list.
fn eval_args(args : Value, env : Env) -> Array[Value] raise EvalError {
  fn go(v : Value, acc : Array[Value]) -> Array[Value] raise EvalError {
    match v {
      Nil => acc
      Pair(car, cdr) => {
        acc.push(eval(car, env))
        go(cdr, acc)
      }
      _ => raise EvalError::TypeMismatch("arguments", v.display())
    }
  }
  go(args, [])
}

///|
/// Apply a function value to evaluated arguments.
fn apply(fn_val : Value, args : Array[Value]) -> Value raise EvalError {
  match fn_val {
    BuiltinProc(_, f) => f(args)
    Closure(params, body, closure_env) => {
      let new_env = Env::extend(closure_env, params, args)
      eval(body, new_env)
    }
    _ => raise EvalError::NotCallable(fn_val.display())
  }
}

///|
/// Evaluate an S-expression in an environment.
///
/// Self-evaluating forms: Num, Str, Bool, Nil, Closure, BuiltinProc.
/// Symbol: looked up in the environment.
/// Special forms are matched by structure (quote, if, lambda, define, begin, set!).
/// Any other Pair is treated as function application.
pub fn eval(expr : Value, env : Env) -> Value raise EvalError {
  match expr {
    // Self-evaluating forms
    Num(_) | Str(_) | Bool(_) | Nil | Void => expr
    Closure(_, _, _) | BuiltinProc(_, _) => expr

    // Symbol lookup
    Sym(name) => env.lookup(name)

    // (quote <expr>)
    Pair(Sym("quote"), Pair(arg, Nil)) => arg

    // (if <cond> <then> <else>)
    Pair(Sym("if"), Pair(cond, Pair(then_expr, Pair(else_expr, Nil)))) =>
      if is_truthy(eval(cond, env)) {
        eval(then_expr, env)
      } else {
        eval(else_expr, env)
      }
    // (if <cond> <then>)  — no else clause, returns Void
    Pair(Sym("if"), Pair(cond, Pair(then_expr, Nil))) =>
      if is_truthy(eval(cond, env)) {
        eval(then_expr, env)
      } else {
        Void
      }

    // (lambda (<params>) <body>)
    Pair(Sym("lambda"), Pair(params, Pair(body, Nil))) =>
      Closure(params, body, env)

    // (define <name> <value>)
    Pair(Sym("define"), Pair(Sym(name), Pair(val_expr, Nil))) => {
      let val = eval(val_expr, env)
      env.bind(name, val)
      Void
    }
    // (define (<name> <params>...) <body>)  — function shorthand
    Pair(Sym("define"), Pair(Pair(Sym(name), params), Pair(body_expr, Nil))) => {
      let lambda_val = Closure(params, body_expr, env)
      env.bind(name, lambda_val)
      Void
    }

    // (begin <expr>...)
    Pair(Sym("begin"), rest) => eval_sequence(rest, env)

    // (set! <name> <value>)
    Pair(Sym("set!"), Pair(Sym(name), Pair(val_expr, Nil))) => {
      let val = eval(val_expr, env)
      env.set(name, val)
      Void
    }

    // Function application: (fn arg1 arg2 ...)
    Pair(fn_expr, args) => {
      let fn_val = eval(fn_expr, env)
      let evaled_args = eval_args(args, env)
      apply(fn_val, evaled_args)
    }

    // All Pair cases handled above — this line is unreachable
  }
}
