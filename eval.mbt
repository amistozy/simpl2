///|
/// SimpL Evaluator — the heart of the interpreter.
///
/// Evaluates an S-expression in a given lexical environment.
/// Supports special forms: quote, if, cond, lambda, define, let, begin, and, or, set!.

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
/// Short-circuit `and`: evaluate exprs left-to-right,
/// return the first falsy value, or the last value if all are truthy.
/// Empty `(and)` returns #t.
fn eval_and_rest(exprs : Value, env : Env) -> Value raise EvalError {
  match exprs {
    Nil => Bool(true)
    Pair(expr, Nil) => eval(expr, env)
    Pair(expr, rest) => {
      let val = eval(expr, env)
      if !is_truthy(val) {
        val
      } else {
        eval_and_rest(rest, env)
      }
    }
    _ => raise EvalError::TypeMismatch("and", exprs.display())
  }
}

///|
/// Short-circuit `or`: evaluate exprs left-to-right,
/// return the first truthy value, or #f if none are truthy.
/// Empty `(or)` returns #f.
fn eval_or_rest(exprs : Value, env : Env) -> Value raise EvalError {
  match exprs {
    Nil => Bool(false)
    Pair(expr, Nil) => eval(expr, env)
    Pair(expr, rest) => {
      let val = eval(expr, env)
      if is_truthy(val) {
        val
      } else {
        eval_or_rest(rest, env)
      }
    }
    _ => raise EvalError::TypeMismatch("or", exprs.display())
  }
}

///|
/// CVT (Curried-define Value Transformer): transform (head params) body
/// into (name, nested-lambda). See Racket's CVT meta-function.
///
/// (CVT id params body)       = (id . (lambda params body))
/// (CVT (h . ps) params body) = (CVT h ps (lambda params body))
fn cvt(
  head : Value,
  params : Value,
  body : Value,
) -> (String, Value) raise EvalError {
  match head {
    Sym(name) => (name, Pair(Sym("lambda"), Pair(params, body)))
    Pair(inner_head, inner_params) => {
      let inner_lambda = Pair(Sym("lambda"), Pair(params, body))
      cvt(inner_head, inner_params, Pair(inner_lambda, Nil))
    }
    _ => raise EvalError::TypeMismatch("define head", head.display())
  }
}

///|
/// Evaluate `cond` clauses. Each clause is (test expr ...).
/// `else` as test is always truthy. No matching clause returns Void.
fn eval_cond(clauses : Value, env : Env) -> Value raise EvalError {
  match clauses {
    Nil => Void
    Pair(Pair(Sym("else"), body), _) => eval_sequence(body, env)
    Pair(Pair(cond_test, cond_body), rest) =>
      if is_truthy(eval(cond_test, env)) {
        eval_sequence(cond_body, env)
      } else {
        eval_cond(rest, env)
      }
    _ => raise EvalError::TypeMismatch("cond", clauses.display())
  }
}

///|
/// Evaluate `let` bindings in the outer env, mutating new_env.
fn eval_let_bindings(
  bindings : Value,
  env : Env,
  new_env : Env,
) -> Unit raise EvalError {
  match bindings {
    Nil => ()
    Pair(Pair(Sym(name), Pair(val_expr, Nil)), rest) => {
      new_env.bind(name, eval(val_expr, env))
      eval_let_bindings(rest, env, new_env)
    }
    _ => raise EvalError::TypeMismatch("let bindings", bindings.display())
  }
}

///|
/// Evaluate `let*` bindings sequentially in the new env (letrec-style).
/// Each val is evaluated in the new env, so later bindings can see
/// earlier ones and closures can reference each other for mutual recursion.
fn eval_let_star_bindings(
  bindings : Value,
  new_env : Env,
) -> Unit raise EvalError {
  match bindings {
    Nil => ()
    Pair(Pair(Sym(name), Pair(val_expr, Nil)), rest) => {
      new_env.bind(name, eval(val_expr, new_env))
      eval_let_star_bindings(rest, new_env)
    }
    _ => raise EvalError::TypeMismatch("let* bindings", bindings.display())
  }
}

///|
/// Split named-let bindings into (params, init-exprs).
/// ((arg1 init1) (arg2 init2) ...) → ([arg1 arg2 ...], [init1 init2 ...])
fn split_named_let_bindings(bindings : Value) -> (Value, Value) raise EvalError {
  fn go(
    v : Value,
    params_acc : Array[Value],
    inits_acc : Array[Value],
  ) -> (Value, Value) raise EvalError {
    match v {
      Nil => (list_from_array(params_acc), list_from_array(inits_acc))
      Pair(Pair(Sym(arg), Pair(init, Nil)), rest) => {
        params_acc.push(Sym(arg))
        inits_acc.push(init)
        go(rest, params_acc, inits_acc)
      }
      _ =>
        raise EvalError::TypeMismatch("named let bindings", bindings.display())
    }
  }
  go(bindings, [], [])
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
/// Special forms are matched by structure (quote, if, cond, lambda, define, let, begin, and, or, set!).
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

    // (cond (test expr ...) ...)  — multi-branch conditional
    Pair(Sym("cond"), clauses) => eval_cond(clauses, env)

    // (lambda (<params>) <body> ...)
    Pair(Sym("lambda"), Pair(params, body)) =>
      Closure(params, Pair(Sym("begin"), body), env)

    // (define <name> <value>)
    Pair(Sym("define"), Pair(Sym(name), Pair(val_expr, Nil))) => {
      let val = eval(val_expr, env)
      env.bind(name, val)
      Void
    }
    // (define (<name> <params>...) <body> ...)  — CVT → nested lambdas
    Pair(Sym("define"), Pair(Pair(head, params), body)) => {
      let (name, lambda_expr) = cvt(head, params, body)
      env.bind(name, eval(lambda_expr, env))
      Void
    }

    // (let proc-id ((arg init) ...) body ...)  — named let
    // → ((let* ((proc-id (lambda (arg ...) body ...))) proc-id) init ...)
    Pair(Sym("let"), Pair(Sym(proc_id), Pair(bindings, body))) => {
      let (params, init_exprs) = split_named_let_bindings(bindings)
      let lambda_expr = Pair(Sym("lambda"), Pair(params, body))
      let let_star_binding = Pair(Sym(proc_id), Pair(lambda_expr, Nil))
      let let_star_bindings = Pair(let_star_binding, Nil)
      let let_star_body = Sym(proc_id)
      let let_star = Pair(
        Sym("let*"),
        Pair(let_star_bindings, Pair(let_star_body, Nil)),
      )
      let call = Pair(let_star, init_exprs)
      eval(call, env)
    }

    // (let ((var val) ...) body ...)  — local bindings
    Pair(Sym("let"), Pair(bindings, body)) => {
      let new_env = { bindings: {}, parent: Some(env) }
      eval_let_bindings(bindings, env, new_env)
      eval_sequence(body, new_env)
    }

    // (let* ((var val) ...) body ...)  — sequential / letrec-style
    Pair(Sym("let*"), Pair(bindings, body)) => {
      let new_env = { bindings: {}, parent: Some(env) }
      eval_let_star_bindings(bindings, new_env)
      eval_sequence(body, new_env)
    }

    // (begin <expr>...)
    Pair(Sym("begin"), rest) => eval_sequence(rest, env)

    // (and expr ...) — short-circuit; empty (and) → #t
    Pair(Sym("and"), rest) => eval_and_rest(rest, env)

    // (or expr ...) — short-circuit; empty (or) → #f
    Pair(Sym("or"), rest) => eval_or_rest(rest, env)

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
