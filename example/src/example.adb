--
--  Copyright 2026 (C) Daniel King
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with Ada.Text_IO;

with Checker;
with Production_Rules; use Production_Rules;

procedure Example is
begin

   --  Call Check_Identifier_List against a valid sequence of tokens

   declare
      Pos              : Index_Type := 1;
      Valid_Ident_List : constant Terminal_Symbol_Vectors.Vector :=
        [Tok_Identifier, Tok_Comma, Tok_Identifier];
   begin
      Ada.Text_IO.Put ("Checking against the Valid_Ident_List sequence: ");
      Checker.Check_Identifier_List (Valid_Ident_List, Pos);
      Ada.Text_IO.Put_Line ("PASSED");
   exception
      when Checker.Syntax_Error =>
         Ada.Text_IO.Put_Line ("FAILED (raised unexpected Syntax_Error)");
   end;

   --  Call Check_Identifier_List against an invalid sequence of tokens

   declare
      Pos                : Index_Type := 1;
      Invalid_Ident_List : constant Terminal_Symbol_Vectors.Vector :=
        [Tok_Comma, Tok_Identifier, Tok_Comma, Tok_Identifier];
   begin
      Ada.Text_IO.Put ("Checking against the Valid_Ident_List sequence: ");
      Checker.Check_Identifier_List (Invalid_Ident_List, Pos);
      Ada.Text_IO.Put_Line ("FAILED (did not raise Syntax_Error)");
   exception
      when Checker.Syntax_Error =>
         Ada.Text_IO.Put_Line ("PASSED (raised expected Syntax_Error)");
   end;

end Example;
