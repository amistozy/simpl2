# SimpL — A Minimal Lisp for Teaching

SimpL（极简 Lisp）是一个面向教学的解释型 Lisp 方言，用 MoonBit 实现。**极简**和**教学**是其核心理念。

### 核心特性

- **词法作用域** — 闭包捕获定义时的环境
- **同像性** — 代码即数据，单一 `Value` 类型表达一切
- **一等函数** — `lambda` 和内置过程都是 `Value`
- **特殊形式** — `quote` `if` `cond` `lambda` `define` `let` `let*` `named let` `begin` `and` `or` `set!` `when` `unless`
- **内置函数** — 算术、比较、列表、类型判断、输出
- **递归下降解析器** — 手写，零外部解析依赖

## 快速开始

```bash
moon run cmd/main              # 进入 REPL
moon test --target native      # 运行测试
```

## REPL 命令

| 命令 | 说明 |
|------|------|
| `:h`, `:help` | 显示帮助 |
| `:q`, `:quit` | 退出 |
| `:clear`, `:cls` | 清屏 |
| `:l <file>`, `:load <file>` | 加载并求值 SimpL 源文件 |
| `; comment` | 行注释 |

## 语言参考

### 数据类型

| 类型 | 字面量示例 | 显示 |
|------|-----------|------|
| Number | `42` `3.14` `-5` | `42` |
| Symbol | `hello` `+` `x` | `hello` |
| String | `"hello world"` `"a\"b"` | `"hello world"` |
| Boolean | `#t` `#f` | `#t` |
| Void | define/set!/when 等返回值 | `#<void>` |
| Nil | `()` 空列表 | `()` |
| Pair | `(1 2 3)` `(a . b)` | `(1 2 3)` |

### 特殊形式

```scheme
(quote <expr>)        ; 返回表达式不求值
'<expr>               ; quote 的语法糖

(if <cond> <then> <else>)  ; 必须三参数，无 else 分支用 when/unless

(cond (<test> <expr> ...) ...         ; 多分支条件，找到第一个 truthy 子句
      (else <expr> ...))              ; else 始终匹配

(lambda (<params>) <body> ...)   ; body 支持多表达式

(define <name> <value>)
(define (<name> <params>) <body> ...)      ; 函数简写
(define ((<name> <params>) <params>) ...)  ; curried 简写（CVT 解糖）

(let ((<var> <val>) ...) <body> ...)   ; 局部绑定，val 在外部环境求值（非顺序）
(let* ((<var> <val>) ...) <body> ...)  ; 顺序绑定，val 在新环境中求值，支持互递归
(let <proc-id> ((<arg> <init>) ...) <body> ...)  ; named let：递归函数 + 立即调用

(begin <expr> ...)    ; 顺序求值，返回最后一个

(and <expr> ...)      ; 短路求值：遇 #f 停止；空 (and) → #t
(or <expr> ...)       ; 短路求值：遇真值停止；空 (or) → #f

(set! <name> <value>) ; 修改已有变量

(when <test> <body> ...)    ; test 为真时执行 body，否则返回 #<void>
(unless <test> <body> ...)  ; test 为假时执行 body，否则返回 #<void>
```

### 内置函数

| 分类 | 函数 |
|------|------|
| 算术 | `+` `-` `*` `/` `add1` `sub1` |
| 比较 | `=` `<` `>` `<=` `>=` （均支持链式多参数） |
| 数值判断 | `zero?` `positive?` `negative?` |
| 列表 | `cons` `car` `cdr` `list` `null?` |
| 类型判断 | `number?` `symbol?` `string?` `pair?` `bool?` |
| 逻辑 | `not` |
| 输出 | `display` `newline` |

## 示例

### 算术与比较

```scheme
(+ 1 2 3)               ; => 6
(- 10 3)                ; => 7
(- 5)                   ; => -5
(* 2 3 4)               ; => 24
(/ 10 2)                ; => 5
(/ 10)                  ; => 0.1

(add1 41)               ; => 42
(sub1 42)               ; => 41
(zero? 0)               ; => #t
(positive? 5)           ; => #t
(negative? -3)          ; => #t

;; 链式比较（支持多参数）
(= 1 1 1)               ; => #t
(< 1 2 3 4 5)           ; => #t
(> 5 4 3)               ; => #t
(<= 1 1 2)              ; => #t
(>= 3 2 2)              ; => #t
```

### 条件分支

```scheme
(if (< 3 5) 'less 'greater)    ; => less

(when (positive? 5)
  (display "positive!"))        ; 打印 positive!，返回 #<void>

(unless (positive? -5)
  (display "not positive"))      ; 打印 not positive，返回 #<void>

(cond
  ((< x 0) 'negative)
  ((> x 0) 'positive)
  (else 'zero))
```

### 列表操作

```scheme
(cons 1 '(2 3))         ; => (1 2 3)
(car '(1 2 3))          ; => 1
(cdr '(1 2 3))          ; => (2 3)
(list 1 2 3)            ; => (1 2 3)
(null? '())             ; => #t
```

### 逻辑与短路

```scheme
(not #t)                ; => #f
(and #t 42)             ; => 42
(and #f (display "x"))  ; => #f，不打印（短路！）
(or #f #f 7)            ; => 7
(or 1 2 3)              ; => 1（短路！）
```

### 变量与函数

```scheme
(define x 10)
(define (square n) (* n n))
(square x)              ; => 100

(define (abs n)
  (if (< n 0) (- n) n))
(abs -42)               ; => 42
```

### 闭包与词法作用域

```scheme
(define (make-adder n)
  (lambda (x) (+ x n)))
(define add5 (make-adder 5))
(add5 10)               ; => 15

;; curried 定义
(define ((foo x) y) (- x y))
((foo 3) 2)             ; => 1
```

### 局部绑定

```scheme
;; let：所有 val 在外部环境求值（非顺序）
(define a 10)
(let ((a 5) (b a)) b)              ; => 10

;; let*：顺序求值，后面可看到前面
(let* ((x 1) (y (+ x 1))) (list y x))     ; => (2 1)

;; let* 支持互递归
(let* ((is-even? (lambda (n) (or (zero? n) (is-odd? (sub1 n)))))
       (is-odd?  (lambda (n) (and (not (zero? n)) (is-even? (sub1 n))))))
  (is-odd? 11))          ; => #t
```

### Named Let（迭代与递归）

```scheme
;; 阶乘
(let fac ((n 10))
  (if (zero? n) 1 (* n (fac (sub1 n)))))
; => 3628800

;; 循环累加
(let loop ((i 0) (acc 0))
  (if (< i 5) (loop (add1 i) (+ acc i)) acc))
; => 10
```

### 多表达式 body

```scheme
(define (f x)
  (define y (+ x 1))
  (* y 2))
(f 3)                   ; => 8

(begin
  (define a 1)
  (define b 2)
  (+ a b))              ; => 3
```

## 项目结构

```
simpl/
├── types.mbt          # Value / Env / 错误类型
├── reader.mbt         # S-表达式解析器
├── builtins.mbt       # 内置函数
├── eval.mbt           # 求值器与环境操作
├── simpl.mbt          # 库入口
├── simpl_test.mbt     # 黑盒测试
├── editors/vscode/    # VS Code 语法高亮扩展
└── cmd/main/
    └── main.mbt       # 异步 REPL
```

## 设计决策

- **所有数值为 Double** — 简化类型系统，适合教学
- **Void 与 Nil 分离** — Void 表示"无值"（副作用操作的返回值），Nil 专用于空列表
- **`if` 必须三参数** — 无 else 的场景用 `when` 或 `unless`，语义更清晰
- **`'expr` 语法糖** — 解析期展开为 `(quote expr)`
- **`(define (f args) body)` 简写** — 通过 CVT（Curried-define Value Transformer）解糖为 `(define f (lambda args body))`
- **`and`/`or` 是特殊形式** — 非内置函数，参数在调用前不求值，实现真正的短路求值
- **链式比较** — `=` `<` `>` `<=` `>=` 均支持多参数，如 `(< 1 2 3)` 等价于 `(and (< 1 2) (< 2 3))`
- **`=` 只接受数字** — 非数字参数会报 TypeMismatch 错误

## 许可证

Apache-2.0
