///|
/// Black-box tests for SimpL — testing public API.
/// Run with: moon test

///|
test "parse atoms" {
  // Numbers
  inspect(@simpl.parse("42"), content="42")
  inspect(@simpl.parse("3.14"), content="3.14")
  inspect(@simpl.parse("-5"), content="-5")

  // Symbols
  inspect(@simpl.parse("hello"), content="hello")
  inspect(@simpl.parse("+"), content="+")

  // Strings
  inspect(@simpl.parse("\"hello world\""), content="\"hello world\"")
  inspect(@simpl.parse("\"a\\\"b\""), content="\"a\"b\"")

  // Booleans and nil
  inspect(@simpl.parse("#t"), content="#t")
  inspect(@simpl.parse("#f"), content="#f")
}

///|
test "parse lists" {
  inspect(@simpl.parse("()"), content="()")
  inspect(@simpl.parse("(1 2 3)"), content="(1 2 3)")
  inspect(@simpl.parse("(a . b)"), content="(a . b)")
  inspect(@simpl.parse("'(1 2 3)"), content="(quote (1 2 3))")
}

///|
test "parse nested lists" {
  inspect(@simpl.parse("(+ 1 (* 2 3))"), content="(+ 1 (* 2 3))")
  inspect(
    @simpl.parse("(define f (lambda (x) (+ x 1)))"),
    content="(define f (lambda (x) (+ x 1)))",
  )
}

///|
test "eval self-evaluating" {
  let env = @simpl.global_env()
  inspect(@simpl.eval(@simpl.parse("42"), env), content="42")
  inspect(@simpl.eval(@simpl.parse("\"hi\""), env), content="\"hi\"")
  inspect(@simpl.eval(@simpl.parse("#t"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("#f"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("()"), env), content="()")
}

///|
test "eval quote" {
  let env = @simpl.global_env()
  inspect(@simpl.eval(@simpl.parse("'hello"), env), content="hello")
  inspect(@simpl.eval(@simpl.parse("'(1 2 3)"), env), content="(1 2 3)")
  inspect(@simpl.eval(@simpl.parse("(quote hello)"), env), content="hello")
}

///|
test "eval arithmetic" {
  let env = @simpl.global_env()
  inspect(@simpl.eval(@simpl.parse("(+ 1 2)"), env), content="3")
  inspect(@simpl.eval(@simpl.parse("(+ 1 2 3 4)"), env), content="10")
  inspect(@simpl.eval(@simpl.parse("(- 10 3)"), env), content="7")
  inspect(@simpl.eval(@simpl.parse("(- 5)"), env), content="-5")
  inspect(@simpl.eval(@simpl.parse("(* 3 4)"), env), content="12")
  inspect(@simpl.eval(@simpl.parse("(* 2 3 4)"), env), content="24")
  inspect(@simpl.eval(@simpl.parse("(/ 10 2)"), env), content="5")
  inspect(@simpl.eval(@simpl.parse("(/ 10)"), env), content="0.1")
  // add1 / sub1
  inspect(@simpl.eval(@simpl.parse("(add1 0)"), env), content="1")
  inspect(@simpl.eval(@simpl.parse("(add1 41)"), env), content="42")
  inspect(@simpl.eval(@simpl.parse("(add1 -1)"), env), content="0")
  inspect(@simpl.eval(@simpl.parse("(sub1 1)"), env), content="0")
  inspect(@simpl.eval(@simpl.parse("(sub1 42)"), env), content="41")
  inspect(@simpl.eval(@simpl.parse("(sub1 0)"), env), content="-1")
  inspect(@simpl.eval(@simpl.parse("(sub1 3.5)"), env), content="2.5")
}

///|
test "eval comparison" {
  let env = @simpl.global_env()
  // = : chained equality
  inspect(@simpl.eval(@simpl.parse("(= 1 1)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(= 1 2)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(= 1 1 1)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(= 1 1 2)"), env), content="#f")
  // < : chained less-than
  inspect(@simpl.eval(@simpl.parse("(< 1 2)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(< 2 1)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(< 1 2 3)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(< 1 3 2)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(< 1 2 2)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(< 1 2 3 4 5)"), env), content="#t")
  // > : chained greater-than
  inspect(@simpl.eval(@simpl.parse("(> 1 2)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(> 2 1)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(> 3 2 1)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(> 3 1 2)"), env), content="#f")
  // <= : chained less-or-equal
  inspect(@simpl.eval(@simpl.parse("(<= 1 1)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(<= 1 1 2)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(<= 1 2 1)"), env), content="#f")
  // >= : chained greater-or-equal
  inspect(@simpl.eval(@simpl.parse("(>= 2 2)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(>= 3 3 1)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(>= 3 1 3)"), env), content="#f")
}

///|
test "eval if" {
  let env = @simpl.global_env()
  inspect(@simpl.eval(@simpl.parse("(if #t 1 2)"), env), content="1")
  inspect(@simpl.eval(@simpl.parse("(if #f 1 2)"), env), content="2")
  inspect(@simpl.eval(@simpl.parse("(if #t 42)"), env), content="42")
  inspect(@simpl.eval(@simpl.parse("(if #f 42)"), env), content="#<void>")
}

///|
test "eval define and variable lookup" {
  let env = @simpl.global_env()
  let _ = @simpl.eval(@simpl.parse("(define x 10)"), env)
  inspect(@simpl.eval(@simpl.parse("x"), env), content="10")
  let _ = @simpl.eval(@simpl.parse("(define y (+ x 5))"), env)
  inspect(@simpl.eval(@simpl.parse("y"), env), content="15")
}

///|
test "eval lambda and application" {
  let env = @simpl.global_env()
  let _ = @simpl.eval(@simpl.parse("(define square (lambda (x) (* x x)))"), env)
  inspect(@simpl.eval(@simpl.parse("(square 5)"), env), content="25")
  inspect(@simpl.eval(@simpl.parse("(square 3)"), env), content="9")
}

///|
test "eval function shorthand" {
  let env = @simpl.global_env()
  let _ = @simpl.eval(@simpl.parse("(define (cube x) (* x x x))"), env)
  inspect(@simpl.eval(@simpl.parse("(cube 3)"), env), content="27")
}

///|
test "eval lambda with multi-expression body" {
  let env = @simpl.global_env()
  // lambda body with multiple expressions
  let _ = @simpl.eval(
    @simpl.parse("(define f (lambda (x) (define y (+ x 1)) (* y 2)))"),
    env,
  )
  inspect(@simpl.eval(@simpl.parse("(f 3)"), env), content="8")
}

///|
test "eval define shorthand with multi-expression body" {
  let env = @simpl.global_env()
  let _ = @simpl.eval(
    @simpl.parse("(define (g x) (define y (- x 1)) (+ y 10))"),
    env,
  )
  inspect(@simpl.eval(@simpl.parse("(g 5)"), env), content="14")
}

///|
test "eval curried define" {
  let env = @simpl.global_env()
  // (define ((foo x) y) (- x y)) → ((foo 3) 2) = 1
  let _ = @simpl.eval(@simpl.parse("(define ((foo x) y) (- x y))"), env)
  inspect(@simpl.eval(@simpl.parse("((foo 3) 2)"), env), content="1")
}

///|
test "eval begin" {
  let env = @simpl.global_env()
  inspect(
    @simpl.eval(@simpl.parse("(begin (define a 1) (define b 2) (+ a b))"), env),
    content="3",
  )
}

///|
test "eval list operations" {
  let env = @simpl.global_env()
  inspect(@simpl.eval(@simpl.parse("(cons 1 '(2 3))"), env), content="(1 2 3)")
  inspect(@simpl.eval(@simpl.parse("(car '(1 2 3))"), env), content="1")
  inspect(@simpl.eval(@simpl.parse("(cdr '(1 2 3))"), env), content="(2 3)")
  inspect(@simpl.eval(@simpl.parse("(list 1 2 3)"), env), content="(1 2 3)")
  inspect(@simpl.eval(@simpl.parse("(null? '())"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(null? '(1))"), env), content="#f")
}

///|
test "eval type predicates" {
  let env = @simpl.global_env()
  inspect(@simpl.eval(@simpl.parse("(number? 42)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(number? #t)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(symbol? 'x)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(symbol? 42)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(pair? '(1))"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(pair? 1)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(bool? #t)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(bool? 1)"), env), content="#f")
}

///|
test "eval closure captures lexical scope" {
  let env = @simpl.global_env()
  // (define (make-adder n) (lambda (x) (+ x n)))
  let _ = @simpl.eval(
    @simpl.parse("(define (make-adder n) (lambda (x) (+ x n)))"),
    env,
  )
  let _ = @simpl.eval(@simpl.parse("(define add5 (make-adder 5))"), env)
  inspect(@simpl.eval(@simpl.parse("(add5 10)"), env), content="15")
  inspect(@simpl.eval(@simpl.parse("(add5 0)"), env), content="5")
}

///|
test "eval set!" {
  let env = @simpl.global_env()
  let _ = @simpl.eval(@simpl.parse("(define x 10)"), env)
  inspect(@simpl.eval(@simpl.parse("x"), env), content="10")
  let _ = @simpl.eval(@simpl.parse("(set! x 20)"), env)
  inspect(@simpl.eval(@simpl.parse("x"), env), content="20")
}

///|
test "eval not/and/or" {
  let env = @simpl.global_env()
  inspect(@simpl.eval(@simpl.parse("(not #t)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(not #f)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(not 0)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(and #t #t)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(and #t #f)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(or #f #f)"), env), content="#f")
  inspect(@simpl.eval(@simpl.parse("(or #f 42)"), env), content="42")
}

///|
test "parse with comments" {
  inspect(@simpl.parse("(+ 1 2) ; this is a comment"), content="(+ 1 2)")
}

///|
test "eval error: unbound variable" {
  let env = @simpl.global_env()
  let result = try? @simpl.eval(@simpl.parse("undefined_var"), env)
  match result {
    Err(@simpl.EvalError::UnboundVariable("undefined_var")) => ()
    _ => fail("Expected UnboundVariable error")
  }
}

///|
test "eval error: not callable" {
  let env = @simpl.global_env()
  let result = try? @simpl.eval(@simpl.parse("(42 1)"), env)
  match result {
    Err(@simpl.EvalError::NotCallable(_)) => ()
    _ => fail("Expected NotCallable error")
  }
}

///|
test "eval cond" {
  let env = @simpl.global_env()
  // Multi-branch
  inspect(
    @simpl.eval(@simpl.parse("(cond (#f 1) (#t 2) (#t 3))"), env),
    content="2",
  )
  // else clause
  inspect(
    @simpl.eval(@simpl.parse("(cond (#f 1) (else 42))"), env),
    content="42",
  )
  // No match → Void
  inspect(
    @simpl.eval(@simpl.parse("(cond (#f 1) (#f 2))"), env),
    content="#<void>",
  )
  // Body with multiple exprs
  inspect(
    @simpl.eval(@simpl.parse("(cond (#t (define x 5) x) (else 0))"), env),
    content="5",
  )
}

///|
test "eval let" {
  let env = @simpl.global_env()
  inspect(
    @simpl.eval(@simpl.parse("(let ((x 1) (y 2)) (+ x y))"), env),
    content="3",
  )
  // Bindings evaluated in outer env (not sequential)
  let _ = @simpl.eval(@simpl.parse("(define a 10)"), env)
  inspect(@simpl.eval(@simpl.parse("(let ((a 5) (b a)) b)"), env), content="10")
  // Body with multiple exprs
  inspect(
    @simpl.eval(@simpl.parse("(let ((x 7)) (define y (* x 2)) y)"), env),
    content="14",
  )
}

///|
test "eval and/or short-circuit" {
  let env = @simpl.global_env()
  // and short-circuits on #f
  inspect(@simpl.eval(@simpl.parse("(and #f 1)"), env), content="#f")
  // or short-circuits on truthy
  inspect(@simpl.eval(@simpl.parse("(or 1 2 3)"), env), content="1")
  // empty (and) and (or)
  inspect(@simpl.eval(@simpl.parse("(and)"), env), content="#t")
  inspect(@simpl.eval(@simpl.parse("(or)"), env), content="#f")
}
