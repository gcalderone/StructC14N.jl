# StructC14N.jl

## Canonicalize structures and named tuples according to a user provided template.

[![Build Status](https://travis-ci.org/gcalderone/StructC14N.jl.svg?branch=master)](https://travis-ci.org/gcalderone/StructC14N.jl)
[![Coverage Status](https://coveralls.io/repos/github/gcalderone/StructC14N.jl/badge.svg?branch=master)](https://coveralls.io/github/gcalderone/StructC14N.jl?branch=master)
[![codecov](https://codecov.io/gh/gcalderone/StructC14N.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/gcalderone/StructC14N.jl)


This package exports the `canonicalize` function which allows
*canonicalization* of structures and named tuples according to a
*template* structure or named tuple

The signature is as follows:
```
canonicalize(template, input)
```
`template` can be either a structure or a named tuple.  `input` can be a structure, a named tuple or a tuple.  In the latter case the tuple must contains the same number of items as the `template`

Type `? canonicalize` in the REPL to see the documentation for individual methods.

Canonicalization rules are as follows:
- output keys are the same as those in `template`;

- if `input` contains less items than `template`, the default values
  in `template` will be used to fill unspecified keys;

- output default values are determined as follows:
  - if `template` is a named tuple and if one of its value is a Type `T`, the
    corresponding default value is `Missing`;
  - if `template` is not a named tuple, or if one of its value is of Type `T`, the
    corresponging default value is the value itself;
	
- output default values are overridden by values in `input` if a key
  in `input` is the same, or it is an unambiguous abbreviation, of one
  of the keys in `template`;

- output override occurs regardless of the order of items in
  `template` and `input`;

- if a key in `input` is not an abbreviation of the keys in `template`,
  or if the abbreviation is ambiguous, an error is raised;

- values in output are deep copied from `input`, and converted to the
  appropriate type.
