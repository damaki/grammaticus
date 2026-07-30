--
--  Copyright 2026 (C) Daniel King
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with SPARK.Big_Integers; use SPARK.Big_Integers;

with Grammar; use Grammar;

--  This package contains code that parses a sequence of terminal symbols
--  to check whether they match against the corresponding production rule.

package Checker
  with SPARK_Mode, Always_Terminates
is

   use Grammar.Terminal_Symbol_Vectors.Formal_Model;

   use all type Grammar.Terminal_Symbol_Vectors.Vector;

   Syntax_Error : exception;
   --  Raised if a production rule fails to match against the provided
   --  sequence of tokens.

   ---------------------------
   -- Check_Identifier_List --
   ---------------------------

   --  Check_Identifier_List parses a sequence of terminal symbols to match
   --  them against the identifier_list production rule (see package Grammar).

   procedure Check_Identifier_List
     (Symbols : Terminal_Symbol_Vectors.Vector; Pos : in out Index_Type)
   with
     Pre               => Last_Index (Symbols) < Index_Type'Last,

     --  If the procedure returns normally, then the sequence of symbols
     --  starting at `Pos` match against the identifier_list production rule.
     Post              =>
       (declare
          M : constant Formal_Spec.Base.Match_Type :=
            Formal_Spec.Match_Identifier_List
              (Formal_Spec.Base.Start_Match (Model (Symbols), Pos'Old));
        begin
        --  The symbols starting at `Pos'Old` matched against the
        --  identifier_list production rule.
          M.Matched

          --  If there are more unmatched symbols after those that matched
          --  against the production rule, then `Pos` now references the symbol
          --  after the last symbol in the match.
          --  Otherwise, if the production rule matched against all remaining
          --  symbols, then `Pos` references one past the end of `Symbols`.
          and then
            (if M.Matched_Count < Big (Length (Symbols))
             then Pos = Formal_Spec.Base.Next_Unmatched_Index (M)
             else Pos = Last_Index (Symbols) + 1)),

     --  If the procedure raised Syntax_Error, then the sequence of symbols
     --  starting at `Pos` did not match against the identifier_list
     --  production rule.
     Exceptional_Cases =>
       (Syntax_Error =>
          not Formal_Spec.Match_Identifier_List
                (Formal_Spec.Base.Start_Match (Model (Symbols), Pos'Old))
                .Matched);

end Checker;
