--
--  Copyright 2026 (C) Daniel King
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Formal.Unbounded_Vectors;

with Grammaticus.Grammar_Matchers;

--  This package provides an example of using Grammaticus to formally specify
--  a language grammar.

package Grammar
  with SPARK_Mode, Always_Terminates
is

   --  Terminal_Symbol defines the set of terminal symbols that can appear in
   --  our grammar.
   --
   --  For the purposes of this example we define a grammar over a sequence of
   --  tokens, which we assume would be output by a lexer.

   type Terminal_Symbol is
     (Tok_As,                    --  keyword "as"

      Tok_Comma,                 --  symbol ","
      Tok_Forward_Slash,         --  symbol "/"
      Tok_Colon,                 --  symbol ":"
      Tok_Exclamation_Mark,      --  symbol "!"
      Tok_Percent,               --  symbol "%"
      Tok_Question_Mark,         --  symbol "?"
      Tok_Left_Paren,            --  symbol "("
      Tok_Right_Paren,           --  symbol ")"
      Tok_Less_Than,             --  symbol "<"
      Tok_Double_Less_Than,      --  symbol "<<"
      Tok_Greater_Than,          --  symbol ">"
      Tok_Double_Greater_Than,   --  symbol ">>"
      Tok_Less_Than_Or_Equal,    --  symbol "<="
      Tok_Greater_Than_Or_Equal, --  symbol ">="
      Tok_Double_Equal,          --  symbol "=="
      Tok_Not_Equal,             --  symbol "!="
      Tok_Double_Ampersand,      --  symbol "&&"
      Tok_Double_Vertical_Bar,   --  symbol "||"
      Tok_Ampersand,             --  symbol "&"
      Tok_Vertical_Bar,          --  symbol "|"
      Tok_Caret,                 --  symbol "^"
      Tok_Minus,                 --  symbol "-"
      Tok_Plus,                  --  symbol "+"
      Tok_Asterisk,              --  symbol "*"
      Tok_Tilde,                 --  symbol "~"

      Tok_Number,                --  numeric literal e.g. "123", "1.2", "0x1F3"
      Tok_Identifier);           --  identifier

   --  We use a SPARK container to hold a vector of terminal symbols.

   type Index_Type is new Positive;

   package Terminal_Symbol_Vectors is new
     SPARK.Containers.Formal.Unbounded_Vectors
       (Index_Type   => Index_Type,
        Element_Type => Terminal_Symbol);

   --  The Formal_Spec package contains the formal specification for our
   --  grammar.
   --
   --  The grammar is specified as various expression functions which define
   --  the sequence(s) of terminal symbols that match against the right hand
   --  side of a production rule.
   --
   --  For example, given the EBNF production rule:
   --
   --     example = identifier , "+" , number ;
   --
   --  We can formally specify this rule in SPARK by defining a function that
   --  matches against the sequence of symbols on the right hand side of the
   --  assignment:
   --
   --     function Match_Example (M : Match_Type) return Match_Type
   --     is (Match_Terminal_Sequence
   --           (M, [Tok_Identifier, Tok_Plus, Tok_Number]));
   --
   --  The function itself is named after the nonterminal symbol on the left
   --  side of the assignment in the production rule ("example" in this case).
   --  This function can then be reused when specifying other grammar rules
   --  that reference the nonterminal symbol "example".
   --
   --  The package is defined as ghost code since its definitions are intended
   --  for specification and verification only.

   package Formal_Spec
     with Ghost
   is

      package Base is new
        Grammaticus.Grammar_Matchers
          (Index_Type              => Index_Type,
           Terminal_Symbol         => Terminal_Symbol,
           Terminal_Symbol_Vectors => Terminal_Symbol_Vectors.Formal_Model.M);
      use Base;

      ---------------------
      -- identifier_list --
      ---------------------

      --  This production rule defines a comma-separated list of identifiers.
      --
      --  The EBNF description is:
      --
      --  identifier_list_tail = { "," , identifier } ;
      --  identifier_list      = identifier , identifier_list_tail ;
      --
      --  Splitting the rule into two parts makes it easier to express the
      --  repetition part using a recursive function.
      --
      --  We use the Generic_Repetition_Match function to help define
      --  the identifier_list_tail rule, since the rule is a repetition.

      function Match_Comma_Then_Identifier (M : Match_Type) return Match_Type
      is (Match_Terminal_Sequence (M, [Tok_Comma, Tok_Identifier]));

      function Match_Identifier_List_Tail is new
        Generic_Repetition_Match (Match_Comma_Then_Identifier);

      function Match_Identifier_List (M : Match_Type) return Match_Type
      is (Match_Identifier_List_Tail (Match_Terminal (M, Tok_Identifier)))
      with Post => Is_Match_Progression (M, Match_Identifier_List'Result);

      --=============--
      -- Expressions --
      --=============--

      --  The following rules describe a grammar for C-like expressions, with
      --  a Rust-style type cast operator (e.g. "x as typename").
      --
      --  Describing this grammar in SPARK involves mutually recursive
      --  functions. The top-level `expression` rule descends through the
      --  precedence layers until it reaches `primary_expression`, which can
      --  then recurse back to  the top-level `expression` rule via a
      --  parenthesised expression.
      --
      --  To prove termination of this mutual recursion, GNATprove requires a
      --  Subprogram_Variant. Most structural calls down the precedence layers
      --  do not consume terminal symbols, so the `Unmatched_Count` remains
      --  constant until a token is consumed or `primary_expression` is
      --  reached. We therefore use a lexicographic variant: the primary
      --  progress measure is `Unmatched_Count`, and the secondary measure is a
      --  static rank (decreasing with each downward call) to be able to prove
      --  that the descent through the rules always terminates.

      function Match_Expression (M : Match_Type) return Match_Type
      with
        Post               =>
          Is_Match_Progression (M, Match_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 22);

      ------------------------
      -- primary_expression --
      ------------------------

      --  primary_expression = identifier
      --                     | number
      --                     | "(" , expression , ")" ;

      function Match_Primary_Expression (M : Match_Type) return Match_Type
      is (if Unmatched_Length (M) = 0
          then No_Match
          else
            Match_Terminal (M, Tok_Identifier)
            or Match_Terminal (M, Tok_Number)
            or
              Match_Terminal
                (Match_Expression (Match_Terminal (M, Tok_Left_Paren)),
                 Tok_Right_Paren))
      with
        Post               =>
          Is_Match_Progression (M, Match_Primary_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 0);

      ----------------------
      -- unary_expression --
      ----------------------

      --  unary_expression = [ "+" | "-" | "!" | "~" ] , primary_expression ;

      function Match_Unary_Expression (M : Match_Type) return Match_Type
      is (declare
            M_Op : constant Match_Type :=
              Match_Any_Terminal
                (M, [Tok_Plus, Tok_Minus, Tok_Exclamation_Mark, Tok_Tilde]);
          begin
            Match_Primary_Expression (M_Op) or Match_Primary_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Unary_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 1);

      -------------------------------
      -- multiplicative_expression --
      -------------------------------

      --  multiplicative_operation = unary_expression
      --                           , ( "*" | "/" | "%" )
      --                           , unary_expression ;

      function Match_Multiplicative_Operation
        (M : Match_Type) return Match_Type
      is (Match_Unary_Expression
            (Match_Any_Terminal
               (Match_Unary_Expression (M),
                [Tok_Asterisk, Tok_Forward_Slash, Tok_Percent])))
      with
        Post               =>
          Is_Match_Progression (M, Match_Multiplicative_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 2);

      --  multiplicative_expression = multiplicative_operation
      --                            | unary_expression ;

      function Match_Multiplicative_Expression
        (M : Match_Type) return Match_Type
      is (Match_Multiplicative_Operation (M) or Match_Unary_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Multiplicative_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 3);

      -------------------------
      -- additive_expression --
      -------------------------

      --  additive_operation = multiplicative_expression
      --                     , ( "+" | "-" )
      --                     , multiplicative_expression ;

      function Match_Additive_Operation (M : Match_Type) return Match_Type
      is (Match_Multiplicative_Expression
            (Match_Any_Terminal
               (Match_Multiplicative_Expression (M), [Tok_Plus, Tok_Minus])))
      with
        Post               =>
          Is_Match_Progression (M, Match_Additive_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 4);

      --  additive_expression = additive_operation
      --                      | multiplicative_expression ;

      function Match_Additive_Expression (M : Match_Type) return Match_Type
      is (Match_Additive_Operation (M) or Match_Multiplicative_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Additive_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 5);

      ----------------------
      -- shift_expression --
      ----------------------

      --  shift_operation = additive_expression
      --                  , ( "<<" | ">>" )
      --                  , additive_expression ;

      function Match_Shift_Operation (M : Match_Type) return Match_Type
      is (Match_Additive_Expression
            (Match_Any_Terminal
               (Match_Additive_Expression (M),
                [Tok_Double_Less_Than, Tok_Double_Greater_Than])))
      with
        Post               =>
          Is_Match_Progression (M, Match_Shift_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 6);

      --  shift_expression = shift_operation | additive_expression ;

      function Match_Shift_Expression (M : Match_Type) return Match_Type
      is (Match_Shift_Operation (M) or Match_Additive_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Shift_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 7);

      ---------------------------
      -- relational_expression --
      ---------------------------

      --  relational_operation = shift_expression
      --                       , ( "<" | "<=" | ">" | ">=" )
      --                       , shift_expression ;

      function Match_Relational_Operation (M : Match_Type) return Match_Type
      is (Match_Shift_Expression
            (Match_Any_Terminal
               (Match_Shift_Expression (M),
                [Tok_Less_Than,
                 Tok_Double_Less_Than,
                 Tok_Greater_Than,
                 Tok_Double_Greater_Than])))
      with
        Post               =>
          Is_Match_Progression (M, Match_Relational_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 8);

      --  relational_expression = relational_operation | shift_expression ;

      function Match_Relational_Expression (M : Match_Type) return Match_Type
      is (Match_Relational_Operation (M) or Match_Shift_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Relational_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 9);

      -------------------------
      -- equality_expression --
      -------------------------

      --  equality_operation = relational_expression
      --                     , ( "==" | "!=" )
      --                     , relational_expression ;

      function Match_Equality_Operation (M : Match_Type) return Match_Type
      is (Match_Relational_Expression
            (Match_Any_Terminal
               (Match_Relational_Expression (M),
                [Tok_Double_Equal, Tok_Not_Equal])))
      with
        Post               =>
          Is_Match_Progression (M, Match_Equality_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 10);

      --  equality_expression = equality_operation | relational_expression ;

      function Match_Equality_Expression (M : Match_Type) return Match_Type
      is (Match_Equality_Operation (M) or Match_Relational_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Equality_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 11);

      ----------------------------
      -- bitwise_and_expression --
      ----------------------------

      --  bitwise_and_operation = equality_expression
      --                        , "&"
      --                        , equality_expression ;

      function Match_Bitwise_And_Operation (M : Match_Type) return Match_Type
      is (Match_Equality_Expression
            (Match_Terminal (Match_Equality_Expression (M), Tok_Ampersand)))
      with
        Post               =>
          Is_Match_Progression (M, Match_Bitwise_And_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 12);

      --  bitwise_and_expression = bitwise_and_operation
      --                         | equality_expression ;

      function Match_Bitwise_And_Expression (M : Match_Type) return Match_Type
      is (Match_Bitwise_And_Operation (M) or Match_Equality_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Bitwise_And_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 13);

      ---------------------------
      -- bitwise_or_expression --
      ---------------------------

      --  bitwise_or_operation = bitwise_and_expression
      --                       , "|"
      --                       , bitwise_and_expression ;

      function Match_Bitwise_Or_Operation (M : Match_Type) return Match_Type
      is (Match_Bitwise_And_Expression
            (Match_Terminal
               (Match_Bitwise_And_Expression (M), Tok_Vertical_Bar)))
      with
        Post               =>
          Is_Match_Progression (M, Match_Bitwise_Or_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 14);

      --  bitwise_or_expression = bitwise_or_operation
      --                        | bitwise_and_expression ;

      function Match_Bitwise_Or_Expression (M : Match_Type) return Match_Type
      is (Match_Bitwise_Or_Operation (M) or Match_Bitwise_And_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Bitwise_Or_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 15);

      ----------------------------
      -- bitwise_xor_expression --
      ----------------------------

      --  bitwise_xor_operation = bitwise_or_expression
      --                        , "^"
      --                        , bitwise_or_expression ;

      function Match_Bitwise_Xor_Operation (M : Match_Type) return Match_Type
      is (Match_Bitwise_Or_Expression
            (Match_Terminal (Match_Bitwise_Or_Expression (M), Tok_Caret)))
      with
        Post               =>
          Is_Match_Progression (M, Match_Bitwise_Xor_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 16);

      --  bitwise_xor_expression = bitwise_xor_operation
      --                         | bitwise_or_expression ;

      function Match_Bitwise_Xor_Expression (M : Match_Type) return Match_Type
      is (Match_Bitwise_Xor_Operation (M) or Match_Bitwise_Or_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Bitwise_Xor_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 17);

      ---------------------
      -- cast_expression --
      ---------------------

      --  cast_operation = bitwise_xor_expression , "as" , identifier ;

      function Match_Cast_Operation (M : Match_Type) return Match_Type
      is (Match_Terminal_Sequence
            (Match_Bitwise_Xor_Expression (M), [Tok_As, Tok_Identifier]))
      with
        Post               =>
          Is_Match_Progression (M, Match_Cast_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 18);

      --  cast_expression = cast_operation | bitwise_xor_expression ;

      function Match_Cast_Expression (M : Match_Type) return Match_Type
      is (Match_Cast_Operation (M) or Match_Bitwise_Xor_Expression (M))
      with
        Post               =>
          Is_Match_Progression (M, Match_Cast_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 19);

      ----------------------------
      -- conditional_expression --
      ----------------------------

      function Match_Conditional_Expression (M : Match_Type) return Match_Type
      with
        Post               =>
          Is_Match_Progression (M, Match_Conditional_Expression'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 21);

      --  conditional_operation = cast_expression
      --                        , "?"
      --                        , expression
      --                        , ":"
      --                        , conditional_expression ;

      function Match_Conditional_Operation (M : Match_Type) return Match_Type
      is (if Unmatched_Length (M) = 0
          then No_Match
          else
            Match_Conditional_Expression
              (Match_Terminal
                 (Match_Expression
                    (Match_Terminal
                       (Match_Cast_Expression (M), Tok_Question_Mark)),
                  Tok_Colon)))
      with
        Post               =>
          Is_Match_Progression (M, Match_Conditional_Operation'Result),
        Subprogram_Variant =>
          (Decreases => Unmatched_Length (M), Decreases => 20);

      --  conditional_expression = conditional_operation | cast_expression ;

      function Match_Conditional_Expression (M : Match_Type) return Match_Type
      is (Match_Conditional_Operation (M) or Match_Cast_Expression (M));

      ----------------
      -- expression --
      ----------------

      --  expression = conditional_expression | bitwise_xor_expression ;

      function Match_Expression (M : Match_Type) return Match_Type
      is (Match_Conditional_Expression (M)
          or Match_Bitwise_Xor_Expression (M));

   end Formal_Spec;

end Grammar;
