with SPARK.Big_Integers; use SPARK.Big_Integers;

with Grammar;

--  This package demonstrates a way of validating our grammar's formal
--  specification by checking them against various test cases.
--
--  Each test case is expressed as an assertion using `pragma Assert`.
--  The test cases are verified either statically running GNATprove on this
--  package to prove each assertion always passes, or at run-time by building
--  this package with assertions enabled (e.g. via `alr build --validation`)

package Validation
  with Ghost, SPARK_Mode, Always_Terminates
is
   use Grammar;
   use Grammar.Formal_Spec;
   use Grammar.Formal_Spec.Base;

   --  case for an empty sequence
   --  expected result: no match

   pragma Assert (not Match_Identifier_List (Start_Match ([])).Matched);

   --  case for a single identifier symbol
   --  expected result: match all symbols

   pragma
     Assert
       (declare
          M : constant Match_Type :=
            Match_Identifier_List (Start_Match ([Tok_Identifier]));
        begin
          M.Matched and then Unmatched_Length (M) = 0);

   --  case for a valid identifier list with two identifiers
   --  expected result: match all symbols

   pragma
     Assert
       (declare
          M : constant Match_Type :=
            Match_Identifier_List
              (Start_Match ([Tok_Identifier, Tok_Comma, Tok_Identifier]));
        begin
          M.Matched and then Unmatched_Length (M) = 0);

   --  case for a valid identifier list with three identifiers
   --  expected result: match all symbols

   pragma
     Assert
       (declare
          M : constant Match_Type :=
            Match_Identifier_List
              (Start_Match
                 ([Tok_Identifier,
                   Tok_Comma,
                   Tok_Identifier,
                   Tok_Comma,
                   Tok_Identifier]));
        begin
          M.Matched and then Unmatched_Length (M) = 0);

   --  case for a valid identifier list with two identifiers and a trailing
   --  comma.
   --  expected result: match all symbols, except the trailing comma

   pragma
     Assert
       (declare
          M : constant Match_Type :=
            Match_Identifier_List
              (Start_Match
                 ([Tok_Identifier, Tok_Comma, Tok_Identifier, Tok_Comma]));
        begin
          M.Matched and then Unmatched_Length (M) = 1);

   --  case for a valid identifier list with three identifiers and a trailing
   --  comma.
   --  expected result: match all symbols, except the trailing comma

   pragma
     Assert
       (declare
          M : constant Match_Type :=
            Match_Identifier_List
              (Start_Match
                 ([Tok_Identifier,
                   Tok_Comma,
                   Tok_Identifier,
                   Tok_Comma,
                   Tok_Identifier,
                   Tok_Comma]));
        begin
          M.Matched and then Unmatched_Length (M) = 1);

   --  case for an identifier list that starts with a leading comma
   --  expected result: no match

   pragma
     Assert
       (declare
          M : constant Match_Type :=
            Match_Identifier_List
              (Start_Match
                 ([Tok_Comma, Tok_Identifier, Tok_Comma, Tok_Identifier]));
        begin
          not M.Matched);

end Validation;
