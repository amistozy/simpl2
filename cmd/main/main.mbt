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
  println("Type :q or Ctrl+D to exit, :clear to clear, :h for help")
  repl(env)
}

///|
/// Clear the terminal screen using ANSI escape codes.
async fn clear_screen() -> Unit {
  @stdio.stdout.write("\u{001b}[2J\u{001b}[H")
}

///|
/// Load and evaluate a SimpL source file into the current environment.
async fn load_file(filename : String, env : @simpl.Env) -> Unit {
  try @fs.read_file(filename) catch {
    err => {
      println("Error reading file '\{filename}': \{@debug.to_string(err)}")
      repl(env)
    }
  } noraise {
    data =>
      try data.text() catch {
        err => {
          println("Error decoding file '\{filename}': \{@debug.to_string(err)}")
          repl(env)
        }
      } noraise {
        source =>
          try @simpl.parse_many(source) catch {
            err => {
              println("Parse error in '\{filename}': \{@debug.to_string(err)}")
              repl(env)
            }
          } noraise {
            exprs => eval_all(exprs, 0, filename, env)
          }
      }
  }
}

///|
/// Evaluate a list of expressions sequentially, reporting errors.
async fn eval_all(
  exprs : Array[@simpl.Value],
  idx : Int,
  filename : String,
  env : @simpl.Env,
) -> Unit {
  if idx >= exprs.length() {
    let n = exprs.length()
    println("Loaded '\{filename}' (\{n} expressions)")
    repl(env)
  } else {
    try @simpl.eval(exprs[idx], env) catch {
      err => {
        let pos = idx + 1
        println(
          "Eval error in '\{filename}' at expr \{pos}: \{@debug.to_string(err)}",
        )
        repl(env)
      }
    } noraise {
      val => {
        match val {
          @simpl.Value::Void => ()
          _ => println(@simpl.Value::display(val))
        }
        eval_all(exprs, idx + 1, filename, env)
      }
    }
  }
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
      } else if trimmed == ":clear" || trimmed == ":cls" {
        clear_screen()
        repl(env)
      } else if trimmed.has_prefix(":load ") {
        let filename = trimmed[6:].trim().to_owned()
        load_file(filename, env)
      } else if trimmed.has_prefix(":l ") {
        let filename = trimmed[3:].trim().to_owned()
        load_file(filename, env)
      } else if trimmed == ":l" || trimmed == ":load" {
        println("Usage: :load <filename>  or  :l <filename>")
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
      println("Parse error: \{@debug.to_string(err)}")
      repl(env)
    }
  } noraise {
    expr =>
      try @simpl.eval(expr, env) catch {
        @simpl.EvalError::UnboundVariable(name) => {
          println("Error: unbound variable '\{name}'")
          repl(env)
        }
        @simpl.EvalError::NotCallable(detail) => {
          println("Error: not callable — \{detail}")
          repl(env)
        }
        @simpl.EvalError::ArityMismatch(name, expect, got) => {
          println(
            "Error: arity mismatch — \{name} expects \{expect} arguments, got \{got}",
          )
          repl(env)
        }
        @simpl.EvalError::TypeMismatch(op, detail) => {
          println("Error: type mismatch in \{op} — \{detail}")
          repl(env)
        }
      } noraise {
        val => {
          match val {
            @simpl.Value::Void => ()
            _ => println(@simpl.Value::display(val))
          }
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
    #|  (and <expr> ...)               — short-circuit and
    #|  (or <expr> ...)                — short-circuit or
    #|  (set! <name> <value>)          — mutate a variable
    #|
    #|Built-in functions:
    #|  Arithmetic:  +  -  *  /
    #|  Comparison:  =  <  >  <=  >=
    #|  Lists:  cons  car  cdr  list  null?
    #|  Predicates:  number?  symbol?  string?  pair?  bool?
    #|  Logic:  not
    #|  Output:  display  newline
    #|
    #|Examples:
    #|  (+ 1 2)                => 3
    #|  (define x 10)          => ()   ; (no output in REPL)
    #|  (if (> x 5) 'big 'small) => big
    #|  (define (sq x) (* x x)) => ()   ; (no output in REPL)
    #|  (sq 5)                 => 25
    #|
    #|REPL commands:
    #|  :h, :help          — show this help
    #|  :q, :quit          — exit the REPL
    #|  :clear, :cls       — clear the screen
    #|  :l <file>, :load <file> — load and evaluate a SimpL file
    #|  ; comment          — line comments are supported
    #|,
  println(help_text)
}
