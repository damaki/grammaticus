--
--  Copyright 2026 (C) Daniel King
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with SPARK.Containers.Functional.Vectors;
with SPARK.Big_Integers;

generic
   type Index_Type is range <>;
   type Terminal_Symbol (<>) is private;

   with package Terminal_Symbol_Vectors is new
     SPARK.Containers.Functional.Vectors
       (Index_Type   => Index_Type,
        Element_Type => Terminal_Symbol,
        others       => <>);

package Grammaticus.Grammar_Matchers with Ghost, SPARK_Mode, Always_Terminates
is

   use type SPARK.Big_Integers.Big_Integer;
   use all type Terminal_Symbol_Vectors.Sequence;

   function Big
     (J : Terminal_Symbol_Vectors.Extended_Index)
      return SPARK.Big_Integers.Big_Integer
   renames Terminal_Symbol_Vectors.Big;

   function Of_Big
     (J : SPARK.Big_Integers.Big_Integer)
      return Terminal_Symbol_Vectors.Extended_Index
   renames Terminal_Symbol_Vectors.Of_Big;

   ----------------
   -- Match_Type --
   ----------------

   --  Grammar matchers (expressed as ghost functions in SPARK) return
   --  Match_Type to express whether or not a sequence of terminal symbols
   --  matches against the required grammar. The Match_Type object holds the
   --  sequence of symbols being compared, and how many of the symbols have
   --  matched against rules.
   --
   --  Match functions also take a Match_Type as input, which allows them to be
   --  chained to express complex grammars. If one matcher in the chain fails
   --  to match against a symbol sequence (expressed by setting `Matched` to
   --  `False`), then the failure propagates through the other rules.

   type Match_Type (Matched : Boolean := False) is record
      case Matched is
         when True =>
            Symbols : Terminal_Symbol_Vectors.Sequence;
            --  The sequence of terminal symbols being matched against

            Matched_Count : SPARK.Big_Integers.Big_Natural;
            --  The number of symbols in `Symbols` that have matched against
            --  the production rule.

         when False =>
            null;
      end case;
   end record
   with Predicate => (if Matched then Matched_Count <= Length (Symbols));

   No_Match : constant Match_Type := Match_Type'(Matched => False);

   function "or" (Left, Right : Match_Type) return Match_Type
   is (if Left.Matched then Left else Right);
   --  Chooses either Left or Right.
   --
   --  This is useful for expressing EBNF alternatives that have the form
   --  "Left | Right" in a grammar.

   function "-" (Left, Right : Match_Type) return Match_Type
   is (if Right.Matched then No_Match else Left);
   --  Returns the Left match, provided that Right is not a match.
   --
   --  This is useful for expressing EBNF exceptions that have the form
   --  "Left - Right" in a grammar.

   function Unmatched_Length
     (M : Match_Type) return SPARK.Big_Integers.Big_Natural
   is (if not M.Matched then 0 else Length (M.Symbols) - M.Matched_Count);
   --  Get the number of Unmatched terminal symbols in `M`.

   function Next_Unmatched_Index (M : Match_Type) return Index_Type
   is (Terminal_Symbol_Vectors.First + Of_Big (M.Matched_Count))
   with Pre => Unmatched_Length (M) > 0;
   --  Get the index of the next unmatched terminal symbol in `M.Symbols`

   function Next_Unmatched_Terminal (M : Match_Type) return Terminal_Symbol
   is (Get (M.Symbols, Next_Unmatched_Index (M)))
   with Pre => Unmatched_Length (M) > 0;
   --  Get the next unmatched terminal symbol in `M`.

   function Is_Match_Progression (Left, Right : Match_Type) return Boolean
   is (if Right.Matched
       then
         Left.Matched
         and then Right.Symbols = Left.Symbols
         and then Right.Matched_Count > Left.Matched_Count);
   --  Returns True if Right has matched at least one more symbol than in Left,
   --  or Right is No_Match.

   function Is_Match_Monotonic (Left, Right : Match_Type) return Boolean
   is (if Right.Matched
       then
         Left.Matched
         and then Right.Symbols = Left.Symbols
         and then Right.Matched_Count >= Left.Matched_Count);
   --  Returns True if Right has matched zero or more symbols more than in Left
   --  or Right is No_Match.

   function Start_Match
     (Symbols : Terminal_Symbol_Vectors.Sequence) return Match_Type
   is (Match_Type'(Matched => True, Symbols => Symbols, Matched_Count => 0));
   --  Create a `Match_Type` object where all symbols are initially unmatched

   function Start_Match
     (Symbols : Terminal_Symbol_Vectors.Sequence; First_Unmatched : Index_Type)
      return Match_Type
   is (if First_Unmatched <= Last (Symbols)
       then
         Match_Type'
           (Matched       => True,
            Symbols       => Symbols,
            Matched_Count => Big (First_Unmatched - Index_Type'First))
       else No_Match);

   function Consume
     (M : Match_Type; N : SPARK.Big_Integers.Big_Positive) return Match_Type
   is ((M with delta Matched_Count => M.Matched_Count + N))
   with
     Pre  => N <= Unmatched_Length (M),
     Post => Is_Match_Progression (M, Consume'Result);
   --  Consumes the next N symbols in M.

   ------------------------------
   -- Terminal Symbol Matching --
   ------------------------------

   --  These functions compare the next unmatched terminal symbol(s) to check
   --  for a specific set of terminal symbols, or sequence of terminal symbols.

   function Match_Terminal
     (M : Match_Type; Expected : Terminal_Symbol) return Match_Type
   is (if Unmatched_Length (M) = 0
         or else Get (M.Symbols, Next_Unmatched_Index (M)) /= Expected
       then No_Match
       else
         Match_Type'
           (Matched       => True,
            Symbols       => M.Symbols,
            Matched_Count => M.Matched_Count + 1))
   with Post => Is_Match_Progression (M, Match_Terminal'Result);
   --  Returns a valid match if the next unmatched terminal symbol in `M` is
   --  equal to `Expected`.

   function Match_Any_Terminal
     (M : Match_Type; Expected : Terminal_Symbol_Vectors.Sequence)
      return Match_Type
   is (if Unmatched_Length (M) = 0
         or else
           (for all T of Expected =>
              Get (M.Symbols, Next_Unmatched_Index (M)) /= T)
       then No_Match
       else
         Match_Type'
           (Matched       => True,
            Symbols       => M.Symbols,
            Matched_Count => M.Matched_Count + 1))
   with
     Pre  => Length (Expected) > 0,
     Post => Is_Match_Progression (M, Match_Any_Terminal'Result);
   --  Returns a valid match if the next unmatched terminal symbol in `M` is
   --  equal to one of the symbols in `Expected`.

   function Match_Terminal_Sequence
     (M : Match_Type; Expected : Terminal_Symbol_Vectors.Sequence)
      return Match_Type
   is (if Length (Expected) > Unmatched_Length (M)
         or else
           (for some I in Expected =>
              Get (Expected, I)
              /= Get (M.Symbols, Next_Unmatched_Index (M) + (I - 1)))
       then No_Match
       else
         Match_Type'
           (Matched       => True,
            Symbols       => M.Symbols,
            Matched_Count => M.Matched_Count + Length (Expected)))
   with
     Pre  => Length (Expected) > 0,
     Post => Is_Match_Progression (M, Match_Terminal_Sequence'Result);
   --  Returns a valid match if the next sequence of unmatched terminal symbols
   --  in `M` is equal to `Expected`.

   ------------------------
   -- Repetition Helpers --
   ------------------------

   --  Generic_Repetition_Match is a helper function for matching against
   --  grammar that uses repetition. I.e. for production rules that are in the
   --  form:
   --
   --  rule = { match_one } ;

   generic
      with function Match_One (M : Match_Type) return Match_Type;
   function Generic_Repetition_Match (M : Match_Type) return Match_Type
   with
     Post               =>
       --  Recursive definition
       Generic_Repetition_Match'Result
       = (declare
            Next_M : constant Match_Type := Match_One (M);
          begin
            (if not Next_M.Matched
             then M
             else Generic_Repetition_Match (Next_M)))

       --  The match consumes zero or more symbols
       and then Is_Match_Monotonic (M, Generic_Repetition_Match'Result)
       and then Generic_Repetition_Match'Result.Matched = M.Matched

       --  The match is greedy; it consumes all symbol sequences that match
       --  the Match_One rule, so the next unmatched symbols after this rule
       --  do not match the Match_One rule.
       and then not Match_One (Generic_Repetition_Match'Result).Matched,

     Subprogram_Variant => (Decreases => Unmatched_Length (M));

   function Generic_Repetition_Match (M : Match_Type) return Match_Type
   is (declare
         Next_M : constant Match_Type := Match_One (M);
       begin
         (if not Next_M.Matched
          then M
          else Generic_Repetition_Match (Next_M)));

   -----------------------
   -- Lookahead Helpers --
   -----------------------

   function Match_Lookahead (M1, M2 : Match_Type) return Match_Type
   is (if M2.Matched then M1 else No_Match)
   with
     Pre  => Is_Match_Progression (M1, M2),
     Post => Is_Match_Monotonic (M1, Match_Lookahead'Result);
   --  Helper function for looking ahead.
   --
   --  Give a match `M2` that is a progression of `M1`, if `M2` is a valid
   --  match, then `M1` is returned. Otherwise, if `M2` is not a valid match,
   --  then `No_Match` is returned.
   --
   --  This allows expressing lookahead grammar rules, where M2 is the
   --  lookahead part.
   --
   --  For example, using `&` as the lookahead operator in this EBNF variant
   --  grammar:
   --
   --     example = "a" &"b" ;
   --
   --  This expresses a match against "a" when it is followed by a "b".
   --  This can be expressed using this function as:
   --
   --     Match_Lookahead
   --       (M1 => Match_Terminal (M, 'a'),
   --        M2 => Match_Terminal (Match_Terminal (M, 'a'), 'b'))

end Grammaticus.Grammar_Matchers;
