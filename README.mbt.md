# SimpL — A Minimal Lisp for Teaching

SimpL（极简 Lisp）是一个面向教学的 Lisp 方言。**极简**和**教育**是其核心理念：用约 1000 行 MoonBit 代码实现一个完整的解释器，包含词法作用域、闭包和高阶函数。

## 快速开始

```bash
# 进入 REPL
moon run cmd/main

# 运行测试
moon test --target native
```

## REPL 示例

Arithmetic
```
(+ 1 2 3)       => 6
(- 10 3 2)      => 5
(* 2 3 4)       => 24
(/ 100 2 5)     => 10
```

Variables and functions
```
(define x 10)
(define (square n) (* n n))
(square x)       => 100
```

Closures (lexical scoping)
```
(define (make-adder n) (lambda (x) (+ x n)))
(define add5 (make-adder 5))
(add5 10)        => 15
```

Conditionals
```
(define (abs n) (if (< n 0) (- n) n))
(abs -42)        => 42
```

Lists
```
(car '(1 2 3))   => 1
(cdr '(1 2 3))   => (2 3)
(cons 1 '(2 3))  => (1 2 3)
(list 1 2 3)     => (1 2 3)
```


## 语言特性

### 特殊形式
| 形式 | 说明 |
|------|------|
| `(quote <expr>)` 或 `'<expr>` | 返回表达式本身（不求值） |
| `(if <cond> <then> <else>)` | 条件求值 |
| `(lambda (<params>) <body>)` | 创建匿名函数（闭包） |
| `(define <name> <value>)` | 定义变量 |
| `(define (<name> <params>) <body>)` | 定义函数（简写） |
| `(begin <expr> ...)` | 顺序求值，返回最后一个 |
| `(set! <name> <value>)` | 修改变量值 |

### 内置函数
| 分类 | 函数 |
|------|------|
| 算术 | `+` `-` `*` `/` |
| 比较 | `=` `<` `>` `<=` `>=` |
| 列表 | `cons` `car` `cdr` `list` `null?` |
| 类型判断 | `number?` `symbol?` `string?` `pair?` `bool?` |
| 逻辑 | `not` `and` `or` |
| 输出 | `display` `newline` |

## 项目结构

```
simpl/
├── types.mbt        # 核心类型：Value, Env, 错误类型
├── reader.mbt       # S-表达式解析器
├── builtins.mbt     # 内置函数
├── eval.mbt         # 求值器（含环境操作）
├── simpl_test.mbt   # 黑盒测试
└── cmd/main/
    └── main.mbt     # REPL 入口（异步 IO）
```

## 设计决策

- **单一类型** `Value` 同时表示代码和数据（同像性）
- **词法作用域**：`Env` 是链式 Map，`Closure` 捕获定义时的环境
- **所有数值均为 Double**：简化实现，适合教学
- **递归下降解析器**：手写，无外部解析库依赖
- **函数是一等公民**：闭包和内置过程都是 `Value`

## 许可证

Apache-2.0
