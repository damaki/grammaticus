# Grammaticus

Grammaticus is a small library for expressing context-free grammar rules in
SPARK. It is intended to help with formally verifying language parsers written
in SPARK by aiding in the specification of the grammar rules that define which
sequences of terminal symbols the parser must accept and reject.

For example, the following [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form)
production rule:

```
example = number , "+" , number ;
```

can be formally specified in SPARK with the following expression function:
```ada

function Match_Example (M : Match_Type) return Match_Type
is (Match_Terminal_Sequence (M, [Tok_Number, Tok_Plus, Tok_Number]))
with Post => Is_Match_Progression (M, Match_Example'Result);
```

These formal specifications in SPARK can then be used to prove that a parser
correctly accepts all symbol sequences that match the rule, and correctly
rejects all symbol sequences that do not match the rule. See the `example`
directory for an example of a full specification using Grammaticus and a
checker implementation that is formally verified to correctly accept or reject
inputs against the SPARK formal specification.

## License

Apache-2.0 WITH LLVM-exception

## Examples

See the example directory for an example of using Grammaticus.

## Tutorial: Express EBNF Grammar in SPARK

This section provides a brief tutorial on how to express various EBNF grammars
in SPARK using Grammaticus.

### Terminology

The following terminology is used in this library:
* _Terminal symbols_ are symbol that can appear in the formal language defined
  by a formal grammar. Depending on the level at which the grammar is defined,
  a terminal symbol in Ada/SPARK could refer to a `Character` (for grammars
  defined over text), or other types such as a `Token_Kind` enumeration when
  defining a grammar over sequences of tokens output from a lexer.
* _Nonterminal symbols_ are symbols that are replaced by groups of terminal
  symbols according to production rules.
* A _production rule_ is a rewrite rule that specifies how a nonterminal symbol
  can be replaced by sequence of other symbols.

### Matching Single Terminal Symbols

Use the `Match_Terminal` function to express production rules (or parts thereof)
that expect a specific terminal symbol. For example:

EBNF:
```
example_1 = "?" ;
```

SPARK:
```ada
function Match_Example_1 (M : Match_Type) return Match_Type
is (Match_Terminal (M, Tok_Question_Mark));
```

### Matching Sequences of Terminal Symbols

Use the `Match_Terminal_Sequence` function to express production rules that
expect a specific sequence of terminal symbols. For example:

EBNF:
```
example_2 = number , "+" , number ;
```

SPARK:
```ada
function Match_Example_2 (M : Match_Type) return Match_Type
is (Match_Terminal_Sequence (M, [Tok_Number, Tok_Plus, Tok_Number]));
```

### Matching Alternatives for Terminal Symbols

Use the `Match_Any_Terminal` function when you have a rule (or a part thereof)
that selects between two or more possible terminal symbols. For example:

EBNF:
```
example_3 = "+" | "-" | "*" | "/";
```

SPARK:
```ada
function Match_Example_3 (M : Match_Type) return Match_Type
is (Match_Any_Terminal
      (M, [Tok_Plus, Tok_Minus, Tok_Asterisk, Tok_Forward_Slash]));
```

This could also be equivalently expressed using `Match_Terminal` and the `"or"`
operator, but is usually less convenient and likely less efficient in proof:

```ada
function Match_Example_3 (M : Match_Type) return Match_Type
is (Match_Terminal (M, Tok_Plus)
    or Match_Terminal (M, Tok_Minus)
    or Match_Terminal (M, Tok_Asterisk)
    or Match_Terminal (M, Tok_Forward_Slash));
```

### Matching Alternatives for Nonterminal Symbols

If you want to express alternatives between other rules, then use the `"or"`
operator. For example:

EBNF:
```
example_4 = example_1 | example_2 | example_3 ;
```

SPARK:
```ada
function Match_Example_4 (M : Match_Type) return Match_Type
is (Match_Example_1 (M)
    or Match_Example_2 (M)
    or Match_Example_3 (M))
with Post => Is_Match_Progression (Match_Example_4'Result);
```

### Matching Optional Symbols

Optional rules can be expressed using the `Match_X (M) or M` pattern.
This will try to match against `Match_X (M)`, and if that fails then fall
back to the returning the input `M` unchanged.

EBNF:
```
example_5 = [ example_2 ] ;
```

SPARK:
```ada
function Match_Example_5 (M : Match_Type) return Match_Type
is (Match_Example_2 (M) or M)
with Post => Is_Match_Monotonic (Match_Example_5'Result);
```

### Handling Exceptional Cases

Use the `"-"` operator to express EBNF exceptional cases:

EBNF:
```
example_6 = example_3 - "-" ;
```

SPARK:
```ada
function Match_Example_6 (M : Match_Type) return Match_Type
is (Match_Example_3 (M) - Match_Terminal (M, Tok_Minus))
with Post => Is_Match_Progression (Match_Example_6'Result);
```

### Matching Sequences of Nonterminal Symbols

Production rules expressed in SPARK can be chained together (returning the
return value of one rule function as the input to another) to express
sequences of nonterminal symbols. For example:

EBNF:
```
example_7 = example_1, example_2, example_3 ;
```

SPARK:
```ada
function Match_Example_7 (M : Match_Type) return Match_Type
is (Match_Example_3 (Match_Example_2 (Match_Example_1 (M))))
with Post => Is_Match_Progression (Match_Example_7'Result);
```