///|
/// SimpL Reader — recursive-descent S-expression parser.
///
/// Parses a string into a Value (s-expression). The grammar:
///   expr  = atom | list | quote
///   atom  = number | symbol | string | bool | nil
///   list  = '(' expr* ')'
///   quote = '\'' expr

///|
/// Check if a character (as UInt16 from string indexing) is whitespace.
fn is_ws(ch : UInt16) -> Bool {
  ch is ' ' || ch is '\n' || ch is '\t' || ch is '\r'
}

///|
/// Check if a character (as UInt16 from string indexing) is a delimiter.
fn is_delimiter(ch : UInt16) -> Bool {
  ch is ' ' ||
  ch is '\n' ||
  ch is '\t' ||
  ch is '\r' ||
  ch is '(' ||
  ch is ')' ||
  ch is '\'' ||
  ch is '"' ||
  ch is ';'
}

///|
/// Skip whitespace characters; return the first non-ws position.
fn skip_ws(input : String, pos : Int) -> Int {
  for i = pos; i < input.length(); i = i + 1 {
    if !is_ws(input[i]) {
      break i
    }
  } nobreak {
    input.length()
  }
}

///|
/// Parse a single S-expression from `input` starting at `pos`.
/// Returns the parsed Value and the new position.
fn parse_expr(input : String, pos : Int) -> (Value, Int) raise ParseError {
  let pos = skip_ws(input, pos)
  if pos >= input.length() {
    raise ParseError::UnexpectedEof(pos~)
  }
  match input[pos] {
    '(' => parse_list(input, pos + 1)
    ')' => raise ParseError::UnexpectedChar(char=')', pos~)
    '\'' => {
      let (quoted, pos) = parse_expr(input, pos + 1)
      (Pair(Sym("quote"), Pair(quoted, Nil)), pos)
    }
    '"' => parse_string(input, pos)
    '#' => parse_hash_token(input, pos)
    ';' => {
      // Line comment: skip to end of line, then parse next expr
      let pos = skip_line(input, pos + 1)
      parse_expr(input, pos)
    }
    _ => parse_atom(input, pos)
  }
}

///|
/// Skip to end of line (for comments).
fn skip_line(input : String, pos : Int) -> Int {
  for i = pos; i < input.length(); i = i + 1 {
    if input[i] is '\n' {
      break i + 1
    }
  } nobreak {
    input.length()
  }
}

///|
/// Parse a list: '(' expr* ')'.
/// Returns a proper list (chain of Pair ending in Nil).
fn parse_list(input : String, pos : Int) -> (Value, Int) raise ParseError {
  let pos = skip_ws(input, pos)
  if pos >= input.length() {
    raise ParseError::UnexpectedEof(pos~)
  }
  if input[pos] is ')' {
    // Empty list
    (Nil, pos + 1)
  } else {
    let (car, pos) = parse_expr(input, pos)
    let (cdr, pos) = parse_list_tail(input, pos)
    (Pair(car, cdr), pos)
  }
}

///|
/// Parse the tail of a list after the first element.
/// Handles dotted pair notation: (a . b) → Pair(a, b).
fn parse_list_tail(input : String, pos : Int) -> (Value, Int) raise ParseError {
  let pos = skip_ws(input, pos)
  if pos >= input.length() {
    raise ParseError::UnexpectedEof(pos~)
  }
  match input[pos] {
    ')' => (Nil, pos + 1)
    '.' => {
      // Dotted pair: (a . b)
      let pos = skip_ws(input, pos + 1)
      let (val, pos) = parse_expr(input, pos)
      let pos = skip_ws(input, pos)
      if pos >= input.length() || !(input[pos] is ')') {
        let ch = if pos < input.length() { '?' } else { ' ' }
        raise ParseError::UnexpectedChar(char=ch, pos~)
      }
      (val, pos + 1)
    }
    _ => {
      let (car, pos) = parse_expr(input, pos)
      let (cdr, pos) = parse_list_tail(input, pos)
      (Pair(car, cdr), pos)
    }
  }
}

///|
/// Parse an atom: number or symbol.
fn parse_atom(input : String, pos : Int) -> (Value, Int) {
  let end = for i = pos; i < input.length(); i = i + 1 {
    if is_delimiter(input[i]) {
      break i
    }
  } nobreak {
    input.length()
  }
  let token = input[pos:end].to_owned()
  try @strconv.from_str(token) catch {
    _ => (Sym(token), end)
  } noraise {
    n => (Num(n), end)
  }
}

///|
/// Parse a string literal: "hello world".
/// Supports basic escapes: \\n \\t \\\\ \\".
fn parse_string(input : String, pos : Int) -> (Value, Int) raise ParseError {
  fn go(i : Int, buf : StringBuilder) -> (Value, Int) raise ParseError {
    if i >= input.length() {
      raise ParseError::UnexpectedEof(pos~)
    }
    match input.get_char(i) {
      None => raise ParseError::UnexpectedEof(pos~)
      Some('"') => (Str(buf.to_string()), i + 1)
      Some('\\') => {
        if i + 1 >= input.length() {
          raise ParseError::UnexpectedEof(pos=i)
        }
        match input.get_char(i + 1) {
          None => raise ParseError::UnexpectedEof(pos=i)
          Some('n') => {
            buf.write_char('\n')
            go(i + 2, buf)
          }
          Some('t') => {
            buf.write_char('\t')
            go(i + 2, buf)
          }
          Some('\\') => {
            buf.write_char('\\')
            go(i + 2, buf)
          }
          Some('"') => {
            buf.write_char('"')
            go(i + 2, buf)
          }
          Some(ch) => raise ParseError::InvalidEscape(char=ch, pos=i + 1)
        }
      }
      Some(ch) => {
        buf.write_char(ch)
        go(i + 1, buf)
      }
    }
  }
  go(pos + 1, StringBuilder::new())
}

///|
/// Parse #t, #f, or other #-prefixed tokens.
fn parse_hash_token(input : String, pos : Int) -> (Value, Int) {
  let end = for i = pos + 1; i < input.length(); i = i + 1 {
    if is_delimiter(input[i]) {
      break i
    }
  } nobreak {
    input.length()
  }
  let token = input[pos + 1:end].to_owned()
  match token {
    "t" => (Bool(true), end)
    "f" => (Bool(false), end)
    _ => (Sym("#" + token), end)
  }
}

///|
/// Parse a complete SimpL program string.
/// Returns a single s-expression. Trailing comments are ignored.
pub fn parse(input : String) -> Value raise ParseError {
  let (expr, pos) = parse_expr(input, 0)
  let pos = skip_trailing(input, pos)
  if pos < input.length() {
    raise ParseError::UnexpectedChar(
      char=input.get_char(pos).unwrap_or('?'),
      pos~,
    )
  }
  expr
}

///|
/// Skip whitespace and comments at the end of input.
fn skip_trailing(input : String, pos : Int) -> Int {
  let pos = skip_ws(input, pos)
  if pos < input.length() && input[pos] is ';' {
    skip_trailing(input, skip_line(input, pos + 1))
  } else {
    pos
  }
}

///|
/// Parse zero or more s-expressions from a string.
/// Useful for REPL input which may contain multiple expressions.
pub fn parse_many(input : String) -> Array[Value] raise ParseError {
  fn go(pos : Int, acc : Array[Value]) -> Array[Value] raise ParseError {
    let pos = skip_ws(input, pos)
    if pos >= input.length() {
      acc
    } else {
      let (expr, pos) = parse_expr(input, pos)
      acc.push(expr)
      go(pos, acc)
    }
  }
  go(0, [])
}
