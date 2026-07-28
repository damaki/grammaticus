--
--  Copyright 2026 (C) Daniel King
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Formal.Unbounded_Vectors;

with Grammaticus.Production_Rules_Base;

--  This package defines some example symbol types and production rules.

package Production_Rules
  with SPARK_Mode, Always_Terminates
is

   --  Terminal_Symbol defines the set of terminal symbols that can appear in
   --  our grammar.

   type Terminal_Symbol is
     (Tok_Comma,                 --  symbol ","
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

   --  The Rules package defines our production rules as ghost expression
   --  functions.
   --
   --  The rules match against a functional vector of terminal symbols.

   package Rules
     with Ghost
   is

      package Base is new
        Grammaticus.Production_Rules_Base
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
          --  The rule matches against zero or more symbols
          Is_Match_Monotonic (M, Match_Identifier_List_Tail'Result)
          and then M.Matched = Match_Identifier_List_Tail'Result.Matched

          --  The rule is greedy. All symbols that match the rule are consumed,
          --  so the next unmatched symbols after this rule are not a comma
          --  and identifier.
          and then
            not Match_Terminal_Sequence
                  (Match_Identifier_List_Tail'Result,
                   [Tok_Comma, Tok_Identifier])
                  .Matched,
        Subprogram_Variant => (Decreases => Unmatched_Length (M));

      function Match_Identifier_List (M : Match_Type) return Match_Type
      is (Match_Identifier_List_Tail (Match_Terminal (M, Tok_Identifier)))
      with Post => Is_Match_Progression (M, Match_Identifier_List'Result);

   end Rules;

end Production_Rules;
