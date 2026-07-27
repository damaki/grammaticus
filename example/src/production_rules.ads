--
--  Copyright 2026 (C) Daniel King
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Formal.Unbounded_Vectors;

with Grammaticus.Production_Rules_Base;

--  This package defines some example symbol types and production rules.

package Production_Rules with SPARK_Mode, Always_Terminates is

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
      --     identifier_list = identifier , { "," , identifier } ;

      function Match_Identifier_List (M : Match_Type) return Match_Type
      is (if Unmatched_Length (M) = 0
          then No_Match
          else
            Match_Identifier_List
              (Match_Terminal_Sequence (M, [Tok_Identifier, Tok_Comma]))
            or Match_Terminal (M, Tok_Identifier))
      with
        Ghost,
        Post               =>
          Is_Match_Progression (M, Match_Identifier_List'Result),
        Subprogram_Variant => (Decreases => Unmatched_Length (M));

   end Rules;

end Production_Rules;
