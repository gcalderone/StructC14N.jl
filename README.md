# StructC14N.jl

## Structure and named tuple canonicalization.

[![Build Status](https://travis-ci.org/gcalderone/StructC14N.jl.svg?branch=master)](https://travis-ci.org/gcalderone/StructC14N.jl)

## Installation

Install with:
```julia
]add StructC14N
```

## Introduction
________

This package exports the `canonicalize(template, input)` function allowing *canonicalization* of input values according to a *template*.  The template must be a structure definition (i.e. a `DataType`), a structure instance or a named tuple,  The input values may be given either as a named tuple, as a tuple, or as keywords.  A characterizing feature in `StructC14N` is that field names in input may be given in abbreviated forms, as long as the abbreviation is unambiguous among the template field names.  The output will be either a structure instance or a named tuple (depending on the type of `template`) whose values are copied from the inputs, or (if a field specification is missing) from the template default values.

Type `? canonicalize` in the REPL to see the documentation and examples for individual methods.


| Template               | Return type        | Default values | Types specification                                 | Missing inputs result in                         |
|------------------------|--------------------| ---------------|-----------------------------------------------------|--------------------------------------------------|
| `NamedTuple` instance  | `NamedTuple`       | Allowed        | As type of default value, or explicitly as a `Type` | Default value or `missing` (1)                   |
| A structure definition | Structure instance | Not allowed    | Explicitly in structure definition                  | `missing` if allowed by struct , otherwise error |
| A structure instance   | Structure instance | Allowed        | Explicitly in structure definition                  | Default value                                    |








The signature is as follows:
```julia
canonicalize(template, input)
```
`template` can be either a structure or a named tuple.  Return value has the same type as `template`.  `input` can be a structure, a named tuple or a tuple.  In the latter case the tuple must contains the same number of items as the `template`.


## Canonicalization rules:
- output keys are the same as in `template`;

- if `input` contains less items than `template`, the default values in `template` will be used to fill unspecified values;

- output default values are determined as follows:
  - if `template` is a named tuple and if one of its value is a Type `T`, the corresponding default value is `Missing`;
  - if `template` is not a named tuple, or if one of its value is of Type `T`, the corresponging default value is the value itself;

- output default values are overridden by values in `input` if a key in `input` is the same, or it is an unambiguous abbreviation, of one of the keys in `template`;

- output override occurs regardless of the order of items in `template` and `input`;

- if a key in `input` is not an abbreviation of the keys in `template`,  or if the abbreviation is ambiguous, an error is raised;

- values in output are deep copied from `input`, and converted to the appropriate type.  If conversion is not possible an error is raised.


## Examples

```julia
using StructC14N

# Create a template
template = (xrange=NTuple{2,Number},
            yrange=NTuple{2,Number},
            title="A string")

# Create input named tuple...
nt = (xr=(1,2), tit="Foo")

# Dump canonicalized version
dump(canonicalize(template, nt))
```

will result in
```julia
NamedTuple{(:xrange, :yrange, :title),Tuple{Tuple{Int64,Int64},Missing,String}}
  xrange: Tuple{Int64,Int64}
    1: Int64 1
    2: Int64 2
  yrange: Missing missing
  title: String "Foo"
```

One of the main use of `canonicalize` is to call functions using abbreviated keyword names (i.e. it can be used as a replacement for [AbbrvKW.jl](https://github.com/gcalderone/AbbrvKW.jl)).  Consider the following function:
``` julia
function Foo(; OptionalKW::Union{Missing,Bool}=missing, Keyword1::Int=1,
               AnotherKeyword::Float64=2.0, StillAnotherOne=3, KeyString::String="bar")
    @show OptionalKW
    @show Keyword1
    @show AnotherKeyword
    @show StillAnotherOne
    @show KeyString
end
```
The only way to use the keywords is to type their entire names,
resulting in very long code lines, i.e.:
``` julia
Foo(Keyword1=10, AnotherKeyword=20.0, StillAnotherOne=30, KeyString="baz")
```

By using `canonicalize` we may re-implement the function as follows
```julia
function Foo(; kwargs...)
    template = (; OptionalKW=Bool, Keyword1=1,
               AnotherKeyword=2.0, StillAnotherOne=3, KeyString="bar")
    kw = StructC14N.canonicalize(template; kwargs...)
    @show kw.OptionalKW
    @show kw.Keyword1
    @show kw.AnotherKeyword
    @show kw.StillAnotherOne
    @show kw.KeyString
end
```
And call it using abbreviated keyword names:
```julia
Foo(Keyw=10, A=20.0, S=30, KeyS="baz") # Much shorter, isn't it?
```

A wrong abbreviation or a wrong type will result in errors:
```julia
Foo(aa=1)
Foo(Keyw="abc")
```

Another common use of `StructC14N` is in parsing configuration files, e.g.:
```julia
configtemplate = (optStr=String,
                  optInt=Int,
                  optFloat=Float64)

# Parse a tuple
configentry = "aa, 1, 2"
c = canonicalize(configtemplate, (split(configentry, ",")...,))

# Parse a named tuple
configentry = "optFloat=20, optStr=\"aaa\", optInt=10"
c = canonicalize(configtemplate, eval(Meta.parse("($configentry)")))

# Use a custom conversion routine
function myparse(input)
  if input == "ten"
    return 10
  end
  return 1
end
configentry = "optFloat=20, optStr=\"aaa\", optInt=\"ten\""
c = canonicalize(configtemplate, eval(Meta.parse("($configentry)")), Dict(:optInt=>myparse))
```
