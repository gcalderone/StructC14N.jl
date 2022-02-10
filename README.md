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

This package exports the `canonicalize(template, input)` function allowing *canonicalization* of input values according to a *template*.  The template must be a structure definition (i.e. a `DataType`), a structure instance or a named tuple,  The input values may be given either as a named tuple, as a tuple, or as keywords.  A **characterizing feature** of `StructC14N` is that field names in input may be given in abbreviated forms, as long as the abbreviation is unambiguous among the template field names.  The output will be either a structure instance or a named tuple (depending on the type of `template`), whose values are copied (and converted, if necessary) from the inputs, or (if a field specification is missing) from the template default values.  A further argument of type `Dict{Symbol, Function}` may be given to `canonicalize` to specify the conversion functions to be used to populate output from input values.

The following table shows the beahviour details, which depends on the type of `template`:
| Template                   | Return type  | Default values | Relation between template field types and output types?     | Missing inputs for a field results in           |
|----------------------------|--------------| ---------------|-------------------------------------------------------------|-------------------------------------------------|
| A `NamedTuple` instance    | `NamedTuple` | Allowed        | Implicit (type of default values) or explicit (as a `Type`) | Default value or `missing` (1)                  |
| A `T` structure definition | `T` instance | Not allowed    | Identical to structure definition                           | `missing` if allowed by struct, otherwise error |
| A `T` structure instance   | `T` instance | Allowed        | Identical to structure definition                           | Default value                                   |

(1): Note that the output named tuple may contain `missing`s even if this is not allowed by the template.

Type `? canonicalize` in the REPL to read the documentation for individual methods, and the rest of this file for a few examples.



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
    kw = canonicalize(template; kwargs...)
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
