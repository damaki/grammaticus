--
--  Copyright 2026 (C) Daniel King
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
package body Checker
  with SPARK_Mode
is

   ---------------------------
   -- Check_Identifier_List --
   ---------------------------

   procedure Check_Identifier_List
     (Symbols : Terminal_Symbol_Vectors.Vector; Pos : in out Index_Type)
   is
      use type Rules.Base.Match_Type;

      M_Initial : constant Rules.Base.Match_Type :=
        Rules.Base.Start_Match (Model (Symbols), Pos)
      with Ghost;
      --  Holds the initial state of the parser before checking any
      --  symbols.

      M_Ident_List : constant Rules.Base.Match_Type :=
        Rules.Match_Identifier_List (M_Initial)
      with Ghost;
      --  Holds the result of calling Match_Identifier_List on the sequence
      --  of tokens starting at `Pos`.

      M : Rules.Base.Match_Type
      with Ghost;

   begin

      --  The production rule we are checking against is (repeated here for
      --  convenience, see package Production_Rules):
      --
      --    identifier_list = identifier , { "," , identifier } ;

      --  First, try to match against the first `identifier` symbol, which
      --  is the minimum required by the production rule.

      if Pos > Last_Index (Symbols)
        or else Element (Symbols, Pos) /= Tok_Identifier
      then
         raise Syntax_Error;
      end if;

      --  Now repeatedly check for the trailing { "," , identifier } part
      --  which may occur zero or more times.

      M := M_Initial;
      pragma Assert (M_Ident_List.Matched);

      loop
         pragma Loop_Variant (Increases => Pos);

         --  Pos remains in range of Symbols
         pragma Loop_Invariant (Pos <= Last_Index (Symbols));

         --  The symbol denoted by Pos is an identifier
         pragma Loop_Invariant (Element (Symbols, Pos) = Tok_Identifier);

         --  M remains valid during every loop iteration
         pragma Loop_Invariant (M.Matched);

         --  Pos always references the next symbol that hasn't been checked yet
         pragma Loop_Invariant (Pos = Rules.Base.Next_Unmatched_Index (M));

         --  The match in M has not yet fully matched against all symbols
         --  that match against the identifier_list production rule.
         pragma Loop_Invariant (M.Matched_Count <= M_Ident_List.Matched_Count);

         --  M is a partial match against the complete identifier_list
         --  production rule.
         pragma
           Loop_Invariant (M_Ident_List = Rules.Match_Identifier_List (M));

         --  Check whether the identifier list continues with another comma
         --  and identifier symbols.

         if Pos > Last_Index (Symbols) - 2
           or else Element (Symbols, Pos + 1) /= Tok_Comma
           or else Element (Symbols, Pos + 2) /= Tok_Identifier
         then
            --  There's no "," and identifier after the current identifier
            --  symbol, so the identifier list does not continue.
            exit;
         end if;

         --  We matched against a "," and identifier, so skip over to the next
         --  identifier and loop to check whether the identifier list
         --  continues further.

         Pos := Pos + 2;
         M :=
           Rules.Base.Match_Terminal_Sequence (M, [Tok_Identifier, Tok_Comma]);
      end loop;

      --  Pos currently points to the last identifier symbol in the identifier
      --  list. Advance by one so that it points to the next symbol after the
      --  identifier list.

      Pos := Pos + 1;

      --  Also consume the final identifier in the list to prove that we have
      --  now reached the end of the production rule.

      M := Rules.Base.Match_Terminal (M, Tok_Identifier);
      pragma Assert (M = M_Ident_List);
   end Check_Identifier_List;

end Checker;
