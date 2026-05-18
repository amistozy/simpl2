///|
/// SimpL — A minimal Lisp dialect for teaching.
///
/// Core types: Value (s-expressions), Env (lexical environment), and error types.

///|
/// Error raised during parsing.
pub(all) suberror ParseError {
  UnexpectedEof(pos~ : Int)
  UnexpectedChar(char~ : Char, pos~ : Int)
  InvalidEscape(char~ : Char, pos~ : Int)
} derive(Debug, Eq)

///|
/// Error raised during evaluation.
pub(all) suberror EvalError {
  UnboundVariable(String)
  NotCallable(String)
  ArityMismatch(String, Int, Int)
  TypeMismatch(String, String)
} derive(Debug, Eq)

///|
/// Lexical environment: a chain of variable bindings.
/// Each frame contains a Map from variable name to Value,
/// with an optional parent frame for lexical scoping.
pub(all) struct Env {
  bindings : Map[String, Value]
  parent : Env?
}

///|
/// The core S-expression / value type for SimpL.
/// Represents both code and data — SimpL is homoiconic.
pub(all) enum Value {
  /// Floating-point number (all numbers are Double).
  Num(Double)
  /// Symbol / identifier.
  Sym(String)
  /// String literal.
  Str(String)
  /// Boolean literal (#t or #f).
  Bool(Bool)
  /// The empty list, also used as "nil".
  Nil
  /// A cons cell: car and cdr.
  Pair(Value, Value)
  /// A user-defined closure: (params body captured-env).
  Closure(Value, Value, Env)
  /// A built-in procedure: (name native-function).
  BuiltinProc(String, (Array[Value]) -> Value raise EvalError)
}

///|
/// Check whether a value is truthy in SimpL.
/// Only #f is false; everything else is true.
pub fn is_truthy(v : Value) -> Bool {
  match v {
    Bool(false) => false
    _ => true
  }
}

///|
/// Build a proper list from an Array of Values.
pub fn list_from_array(arr : Array[Value]) -> Value {
  fn go(idx : Int) -> Value {
    if idx >= arr.length() {
      Nil
    } else {
      Pair(arr[idx], go(idx + 1))
    }
  }
  go(0)
}

///|
/// Convert a Value into its readable string representation.
pub fn Value::display(self : Value) -> String {
  match self {
    Num(n) => number_to_string(n)
    Sym(s) => s
    Str(s) => "\"" + s + "\""
    Bool(true) => "#t"
    Bool(false) => "#f"
    Nil => "()"
    Pair(_, _) => "(" + self.pair_string() + ")"
    Closure(_, _, _) => "#<closure>"
    BuiltinProc(name, _) => "#<builtin:" + name + ">"
  }
}

///|
/// Implement Show for Value (for inspect in tests).
pub impl Show for Value with to_string(self) -> String {
  self.display()
}

///|
/// Format a number: drop trailing ".0" for integers.
fn number_to_string(n : Double) -> String {
  if n - n.floor() == 0.0 && !n.is_inf() && !n.is_nan() {
    n.to_int().to_string()
  } else {
    n.to_string()
  }
}

///|
/// Inner helper: print the elements inside a pair chain.
fn Value::pair_string(self : Value) -> String {
  match self {
    Nil => ""
    Pair(car, cdr) =>
      match cdr {
        Nil => car.to_string()
        Pair(_, _) => car.to_string() + " " + cdr.pair_string()
        _ => car.to_string() + " . " + cdr.to_string()
      }
    _ => ""
  }
}
