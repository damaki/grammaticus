# Grammaticus

Grammaticus is a small library for expressing context-free grammar rules in
SPARK. It is intended to help with formally verifying language parsers written
in SPARK by aiding in the specification of the grammar rules that define which
sequences of terminal symbols the parser must accept and reject.

For example, the following [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form)
grammar that describes a comma-separated identifier list:

```
identifier_list = identifier , { "," , identifier } ;
```

can be formally specified in SPARK with the following recursive expression
function:
```ada
function Match_Identifier_List (M : Match_Type) return Match_Type
is (if Unmatched_Length (M) = 0
    then No_Match
    else
      Match_Identifier_List
        (Match_Terminal_Sequence (M, [Tok_Identifier, Tok_Comma]))
      or Match_Terminal (M, Tok_Identifier))
with Subprogram_Variant => (Decreases => Unmatched_Length (M));
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