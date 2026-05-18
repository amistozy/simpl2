///|
/// SimpL REPL — Read-Eval-Print Loop.
///
/// Interactive prompt for the SimpL teaching Lisp.
/// Type expressions and see them evaluated.

///|
/// Run the SimpL REPL.
async fn main {
  let env = @simpl.global_env()
  println("SimpL — A minimal Lisp for teaching")
  println("Type :q or press Ctrl+D to exit, :h for help")
  repl(env)
}

///|
/// The REPL loop: read, evaluate, print, repeat.
async fn repl(env : @simpl.Env) -> Unit {
  @stdio.stdout.write("simpl> ")
  match @stdio.stdin.read_until("\n") {
    None => {
      println("")
      println("Goodbye!")
    }
    Some(line) => {
      let trimmed = line.trim().to_owned()
      if trimmed == ":q" || trimmed == ":quit" {
        println("Goodbye!")
      } else if trimmed == "" {
        repl(env)
      } else if trimmed == ":h" || trimmed == ":help" {
        print_help()
        repl(env)
      } else {
        handle_input(trimmed, env)
      }
    }
  }
}

///|
/// Handle one line of SimpL input.
async fn handle_input(input : String, env : @simpl.Env) -> Unit {
  try @simpl.parse(input) catch {
    err => {
      println("Parse error: " + @debug.to_string(err))
      repl(env)
    }
  } noraise {
    expr =>
      try @simpl.eval(expr, env) catch {
        @simpl.EvalError::UnboundVariable(name) => {
          println("Error: unbound variable '" + name + "'")
          repl(env)
        }
        @simpl.EvalError::NotCallable(detail) => {
          println("Error: not callable — " + detail)
          repl(env)
        }
        @simpl.EvalError::ArityMismatch(name, expect, got) => {
          println(
            "Error: arity mismatch — " +
            name +
            " expects " +
            expect.to_string() +
            " arguments, got " +
            got.to_string(),
          )
          repl(env)
        }
        @simpl.EvalError::TypeMismatch(op, detail) => {
          println("Error: type mismatch in " + op + " — " + detail)
          repl(env)
        }
      } noraise {
        val => {
          println(@simpl.Value::display(val))
          repl(env)
        }
      }
  }
}

///|
/// Print help information.
fn print_help() -> Unit {
  let help_text =
    #|SimpL Help
    #|---------
    #|
    #|Special forms:
    #|  (quote <expr>)  or  '<expr>    — return expression unevaluated
    #|  (if <cond> <then> <else>)      — conditional evaluation
    #|  (lambda (<params>) <body>)     — create a function
    #|  (define <name> <value>)        — define a variable
    #|  (define (<name> <params>) <body>) — define a function (shorthand)
    #|  (begin <expr> ...)             — evaluate in sequence
    #|  (set! <name> <value>)          — mutate a variable
    #|
    #|Built-in functions:
    #|  Arithmetic:  +  -  *  /
    #|  Comparison:  =  <  >  <=  >=
    #|  Lists:  cons  car  cdr  list  null?
    #|  Predicates:  number?  symbol?  string?  pair?  bool?
    #|  Logic:  not  and  or
    #|  Output:  display  newline
    #|
    #|Examples:
    #|  (+ 1 2)                => 3
    #|  (define x 10)          => ()
    #|  (if (> x 5) 'big 'small) => big
    #|  (define (sq x) (* x x)) => ()
    #|  (sq 5)                 => 25
    #|
    #|REPL commands:
    #|  :h, :help   — show this help
    #|  :q, :quit   — exit the REPL
    #|  ; comment   — line comments are supported
    #|,
  println(help_text)
}
