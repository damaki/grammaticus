# Grammaticus Example

This example demonstrates using Grammaticus to formally specify a grammar
in SPARK and then use it formally verify the correctness of a simple checker
that either accepts or rejects a sequence of input symbols based on the
production rule.

The example consists of the following files:
 * `src/grammar.ads` instantiates grammaticus and formalises several EBNF
   production rules in SPARK.
 * `src/validation.ads` demonstrates a method of validating the formal spec
   by checking that it correctly matches against the expected sequence(s) of
   terminal symbols.
 * `src/checker.ads` and `src/checker.adb` implements a simple parser that
   takes a sequence of terminal symbols as an input, and checks it against
   the production rule. It is formally verified to be correct against the
   formal specification (in `grammar.ads`).
 * `example.adb` implements a simple program to run the checker against a
   couple of inputs and print the results.

## Building and running

To build and run the example using [Alire](https://alire.ada.dev/):

```sh
alr run
```

## Running the proofs

```sh
alr exec -- gnatprove -P example.gpr --level=2 -j0
```