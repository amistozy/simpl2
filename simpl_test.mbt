///|
/// Black-box tests for SimpL — testing public API.
/// Run with: moon test
using @simpl {parse, eval, global_env, type EvalError}

///|
test "parse atoms" {
  // Numbers
  inspect(parse("42"), content="42")
  inspect(parse("3.14"), content="3.14")
  inspect(parse("-5"), content="-5")

  // Symbols
  inspect(parse("hello"), content="hello")
  inspect(parse("+"), content="+")

  // Strings
  inspect(parse("\"hello world\""), content="\"hello world\"")
  inspect(parse("\"a\\\"b\""), content="\"a\"b\"")

  // Booleans and nil
  inspect(parse("#t"), content="#t")
  inspect(parse("#f"), content="#f")
}

///|
test "parse lists" {
  inspect(parse("()"), content="()")
  inspect(parse("(1 2 3)"), content="(1 2 3)")
  inspect(parse("(a . b)"), content="(a . b)")
  inspect(parse("'(1 2 3)"), content="(quote (1 2 3))")
}

///|
test "parse nested lists" {
  inspect(parse("(+ 1 (* 2 3))"), content="(+ 1 (* 2 3))")
  inspect(
    parse("(define f (lambda (x) (+ x 1)))"),
    content="(define f (lambda (x) (+ x 1)))",
  )
}

///|
test "eval self-evaluating" {
  let env = global_env()
  inspect(eval(parse("42"), env), content="42")
  inspect(eval(parse("\"hi\""), env), content="\"hi\"")
  inspect(eval(parse("#t"), env), content="#t")
  inspect(eval(parse("#f"), env), content="#f")
  inspect(eval(parse("()"), env), content="()")
}

///|
test "eval quote" {
  let env = global_env()
  inspect(eval(parse("'hello"), env), content="hello")
  inspect(eval(parse("'(1 2 3)"), env), content="(1 2 3)")
  inspect(eval(parse("(quote hello)"), env), content="hello")
}

///|
test "eval arithmetic" {
  let env = global_env()
  inspect(eval(parse("(+ 1 2)"), env), content="3")
  inspect(eval(parse("(+ 1 2 3 4)"), env), content="10")
  inspect(eval(parse("(- 10 3)"), env), content="7")
  inspect(eval(parse("(- 5)"), env), content="-5")
  inspect(eval(parse("(* 3 4)"), env), content="12")
  inspect(eval(parse("(* 2 3 4)"), env), content="24")
  inspect(eval(parse("(/ 10 2)"), env), content="5")
  inspect(eval(parse("(/ 10)"), env), content="0.1")
  // add1 / sub1
  inspect(eval(parse("(add1 0)"), env), content="1")
  inspect(eval(parse("(add1 41)"), env), content="42")
  inspect(eval(parse("(add1 -1)"), env), content="0")
  inspect(eval(parse("(sub1 1)"), env), content="0")
  inspect(eval(parse("(sub1 42)"), env), content="41")
  inspect(eval(parse("(sub1 0)"), env), content="-1")
  inspect(eval(parse("(sub1 3.5)"), env), content="2.5")
  // zero?
  inspect(eval(parse("(zero? 0)"), env), content="#t")
  inspect(eval(parse("(zero? 1)"), env), content="#f")
  inspect(eval(parse("(zero? -1)"), env), content="#f")
  inspect(eval(parse("(zero? 0.0)"), env), content="#t")
  // positive? / negative?
  inspect(eval(parse("(positive? 1)"), env), content="#t")
  inspect(eval(parse("(positive? 0)"), env), content="#f")
  inspect(eval(parse("(positive? -1)"), env), content="#f")
  inspect(eval(parse("(negative? -1)"), env), content="#t")
  inspect(eval(parse("(negative? 0)"), env), content="#f")
  inspect(eval(parse("(negative? 1)"), env), content="#f")
}

///|
test "eval comparison" {
  let env = global_env()
  // = : chained equality
  inspect(eval(parse("(= 1 1)"), env), content="#t")
  inspect(eval(parse("(= 1 2)"), env), content="#f")
  inspect(eval(parse("(= 1 1 1)"), env), content="#t")
  inspect(eval(parse("(= 1 1 2)"), env), content="#f")
  // < : chained less-than
  inspect(eval(parse("(< 1 2)"), env), content="#t")
  inspect(eval(parse("(< 2 1)"), env), content="#f")
  inspect(eval(parse("(< 1 2 3)"), env), content="#t")
  inspect(eval(parse("(< 1 3 2)"), env), content="#f")
  inspect(eval(parse("(< 1 2 2)"), env), content="#f")
  inspect(eval(parse("(< 1 2 3 4 5)"), env), content="#t")
  // > : chained greater-than
  inspect(eval(parse("(> 1 2)"), env), content="#f")
  inspect(eval(parse("(> 2 1)"), env), content="#t")
  inspect(eval(parse("(> 3 2 1)"), env), content="#t")
  inspect(eval(parse("(> 3 1 2)"), env), content="#f")
  // <= : chained less-or-equal
  inspect(eval(parse("(<= 1 1)"), env), content="#t")
  inspect(eval(parse("(<= 1 1 2)"), env), content="#t")
  inspect(eval(parse("(<= 1 2 1)"), env), content="#f")
  // >= : chained greater-or-equal
  inspect(eval(parse("(>= 2 2)"), env), content="#t")
  inspect(eval(parse("(>= 3 3 1)"), env), content="#t")
  inspect(eval(parse("(>= 3 1 3)"), env), content="#f")
}

///|
test "eval if" {
  let env = global_env()
  inspect(eval(parse("(if #t 1 2)"), env), content="1")
  inspect(eval(parse("(if #f 1 2)"), env), content="2")
}

///|
test "eval when/unless" {
  let env = global_env()
  // when truthy executes body
  inspect(eval(parse("(when #t 42)"), env), content="42")
  // when falsy returns Void
  inspect(eval(parse("(when #f 42)"), env), content="#<void>")
  // when with multi-expression body
  inspect(eval(parse("(when #t (define x 5) x)"), env), content="5")
  // unless falsy executes body
  inspect(eval(parse("(unless #f 42)"), env), content="42")
  // unless truthy returns Void
  inspect(eval(parse("(unless #t 42)"), env), content="#<void>")
  // unless with multi-expression body
  inspect(eval(parse("(unless #f (define x 7) x)"), env), content="7")
}

///|
test "eval define and variable lookup" {
  let env = global_env()
  let _ = eval(parse("(define x 10)"), env)
  inspect(eval(parse("x"), env), content="10")
  let _ = eval(parse("(define y (+ x 5))"), env)
  inspect(eval(parse("y"), env), content="15")
}

///|
test "eval lambda and application" {
  let env = global_env()
  let _ = eval(parse("(define square (lambda (x) (* x x)))"), env)
  inspect(eval(parse("(square 5)"), env), content="25")
  inspect(eval(parse("(square 3)"), env), content="9")
}

///|
test "eval function shorthand" {
  let env = global_env()
  let _ = eval(parse("(define (cube x) (* x x x))"), env)
  inspect(eval(parse("(cube 3)"), env), content="27")
}

///|
test "eval lambda with multi-expression body" {
  let env = global_env()
  // lambda body with multiple expressions
  let _ = eval(parse("(define f (lambda (x) (define y (+ x 1)) (* y 2)))"), env)
  inspect(eval(parse("(f 3)"), env), content="8")
}

///|
test "eval define shorthand with multi-expression body" {
  let env = global_env()
  let _ = eval(parse("(define (g x) (define y (- x 1)) (+ y 10))"), env)
  inspect(eval(parse("(g 5)"), env), content="14")
}

///|
test "eval curried define" {
  let env = global_env()
  // (define ((foo x) y) (- x y)) → ((foo 3) 2) = 1
  let _ = eval(parse("(define ((foo x) y) (- x y))"), env)
  inspect(eval(parse("((foo 3) 2)"), env), content="1")
}

///|
test "eval begin" {
  let env = global_env()
  inspect(
    eval(parse("(begin (define a 1) (define b 2) (+ a b))"), env),
    content="3",
  )
}

///|
test "eval list operations" {
  let env = global_env()
  inspect(eval(parse("(cons 1 '(2 3))"), env), content="(1 2 3)")
  inspect(eval(parse("(car '(1 2 3))"), env), content="1")
  inspect(eval(parse("(cdr '(1 2 3))"), env), content="(2 3)")
  inspect(eval(parse("(list 1 2 3)"), env), content="(1 2 3)")
  inspect(eval(parse("(null? '())"), env), content="#t")
  inspect(eval(parse("(null? '(1))"), env), content="#f")
}

///|
test "eval type predicates" {
  let env = global_env()
  inspect(eval(parse("(number? 42)"), env), content="#t")
  inspect(eval(parse("(number? #t)"), env), content="#f")
  inspect(eval(parse("(symbol? 'x)"), env), content="#t")
  inspect(eval(parse("(symbol? 42)"), env), content="#f")
  inspect(eval(parse("(pair? '(1))"), env), content="#t")
  inspect(eval(parse("(pair? 1)"), env), content="#f")
  inspect(eval(parse("(bool? #t)"), env), content="#t")
  inspect(eval(parse("(bool? 1)"), env), content="#f")
}

///|
test "eval closure captures lexical scope" {
  let env = global_env()
  // (define (make-adder n) (lambda (x) (+ x n)))
  let _ = eval(parse("(define (make-adder n) (lambda (x) (+ x n)))"), env)
  let _ = eval(parse("(define add5 (make-adder 5))"), env)
  inspect(eval(parse("(add5 10)"), env), content="15")
  inspect(eval(parse("(add5 0)"), env), content="5")
}

///|
test "eval set!" {
  let env = global_env()
  let _ = eval(parse("(define x 10)"), env)
  inspect(eval(parse("x"), env), content="10")
  let _ = eval(parse("(set! x 20)"), env)
  inspect(eval(parse("x"), env), content="20")
}

///|
test "eval not/and/or" {
  let env = global_env()
  inspect(eval(parse("(not #t)"), env), content="#f")
  inspect(eval(parse("(not #f)"), env), content="#t")
  inspect(eval(parse("(not 0)"), env), content="#f")
  inspect(eval(parse("(and #t #t)"), env), content="#t")
  inspect(eval(parse("(and #t #f)"), env), content="#f")
  inspect(eval(parse("(or #f #f)"), env), content="#f")
  inspect(eval(parse("(or #f 42)"), env), content="42")
}

///|
test "parse with comments" {
  inspect(parse("(+ 1 2) ; this is a comment"), content="(+ 1 2)")
}

///|
test "eval error: unbound variable" {
  let env = global_env()
  let result = try? eval(parse("undefined_var"), env)
  match result {
    Err(EvalError::UnboundVariable("undefined_var")) => ()
    _ => fail("Expected UnboundVariable error")
  }
}

///|
test "eval error: not callable" {
  let env = global_env()
  let result = try? eval(parse("(42 1)"), env)
  match result {
    Err(EvalError::NotCallable(_)) => ()
    _ => fail("Expected NotCallable error")
  }
}

///|
test "eval cond" {
  let env = global_env()
  // Multi-branch
  inspect(eval(parse("(cond (#f 1) (#t 2) (#t 3))"), env), content="2")
  // else clause
  inspect(eval(parse("(cond (#f 1) (else 42))"), env), content="42")
  // No match → Void
  inspect(eval(parse("(cond (#f 1) (#f 2))"), env), content="#<void>")
  // Body with multiple exprs
  inspect(eval(parse("(cond (#t (define x 5) x) (else 0))"), env), content="5")
}

///|
test "eval let" {
  let env = global_env()
  inspect(eval(parse("(let ((x 1) (y 2)) (+ x y))"), env), content="3")
  // Bindings evaluated in outer env (not sequential)
  let _ = eval(parse("(define a 10)"), env)
  inspect(eval(parse("(let ((a 5) (b a)) b)"), env), content="10")
  // Body with multiple exprs
  inspect(eval(parse("(let ((x 7)) (define y (* x 2)) y)"), env), content="14")
}

///|
test "eval let*" {
  let env = global_env()
  // Sequential bindings
  inspect(eval(parse("(let* ((x 1) (y 2)) (+ x y))"), env), content="3")
  // Later bindings see earlier ones
  inspect(
    eval(parse("(let* ((x 1) (y (+ x 1))) (list y x))"), env),
    content="(2 1)",
  )
  // Body with multiple exprs
  inspect(eval(parse("(let* ((x 7)) (define y (* x 2)) y)"), env), content="14")
  // Mutual recursion
  let program =
    #|(let* ((is-even? (lambda (n)
    #|                    (or (zero? n)
    #|                        (is-odd? (sub1 n)))))
    #|       (is-odd? (lambda (n)
    #|                  (and (not (zero? n))
    #|                       (is-even? (sub1 n))))))
    #|  (is-odd? 11))
  inspect(eval(parse(program), env), content="#t")
}

///|
test "eval named let" {
  let env = global_env()
  // Factorial
  let fac_prog =
    #|(let fac ((n 10))
    #|  (if (zero? n) 1 (* n (fac (sub1 n)))))
  inspect(eval(parse(fac_prog), env), content="3628800")
  // Loop-style iteration
  let loop_prog =
    #|(let loop ((i 0) (acc 0))
    #|  (if (< i 5) (loop (add1 i) (+ acc i)) acc))
  inspect(eval(parse(loop_prog), env), content="10")
}

///|
test "eval and/or short-circuit" {
  let env = global_env()
  // and short-circuits on #f
  inspect(eval(parse("(and #f 1)"), env), content="#f")
  // or short-circuits on truthy
  inspect(eval(parse("(or 1 2 3)"), env), content="1")
  // empty (and) and (or)
  inspect(eval(parse("(and)"), env), content="#t")
  inspect(eval(parse("(or)"), env), content="#f")
}
