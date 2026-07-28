# Grammaticus

Grammaticus is a small library for expressing context-free grammar rules in
SPARK. It is intended to help with formally verifying language parsers written
in SPARK by aiding in the specification of the grammar rules that define which
sequences of terminal symbols the parser must accept and reject.

For example, the following [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form)
grammar that describes a comma-separated identifier list:

```
identifer_list_tail = { "," , identifier } ;
identifier_list     = identifier , identifier_list_tail ;
```

can be formally specified in SPARK with the following recursive expression
functions:
```ada

--  Rule function for identifier_list_tail:
function Match_Identifier_List_Tail (M : Match_Type) return Match_Type
is (declare
      Next_M : constant Match_Type :=
        Match_Terminal_Sequence (M, [Tok_Comma, Tok_Identifier]);
    begin
      (if not Next_M.Matched
       then M
       else Match_Identifier_List_Tail (Next_M)))
with
  Post               =>
    Is_Match_Monotonic (M, Match_Identifier_List_Tail'Result)
    and then M.Matched = Match_Identifier_List_Tail'Result.Matched
    and then
      not Match_Terminal_Sequence
            (Match_Identifier_List_Tail'Result,
             [Tok_Comma, Tok_Identifier])
            .Matched,
  Subprogram_Variant => (Decreases => Unmatched_Length (M));

--  Rule function for identifier_list:
function Match_Identifier_List (M : Match_Type) return Match_Type
is (Match_Identifier_List_Tail (Match_Terminal (M, Tok_Identifier)))
with Post => Is_Match_Progression (M, Match_Identifier_List'Result);
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