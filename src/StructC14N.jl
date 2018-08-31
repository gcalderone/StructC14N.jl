module StructC14N

export canonicalize

import Base.convert


"""
`convert(NamedTuple, str)`

Convert a structure `str` into a named tuple.
"""
function convert(::Type{NamedTuple}, str)
    @assert isstructtype(typeof(str))
    k = fieldnames.(typeof(str))
    return NamedTuple{k}(getfield.(Ref(str), k))
end


"""
`findabbrv(v::Vector{Symbol})`

Find all unique abbreviations of symbols in `v`.  Return a tuple of
two `Vector{Symbol}`: the first contains all possible abbreviations;
the second contains the corresponding un-abbreviated symbol
"""
function findabbrv(symLong::Vector{Symbol})
    @assert length(symLong) >= 1
    symStr = String.(symLong)

    outAbbrv = Vector{Symbol}()
    outLong  = Vector{Symbol}()

    # Max length of string representation of keywords
    maxLen = maximum(length.(symStr))

    # Identify all abbreviations
    for len in 1:maxLen
        for i in 1:length(symStr)
            s = symStr[i]
            if length(s) >= len
                s = s[1:len]
                push!(outAbbrv, Symbol(s))
                push!(outLong , symLong[i])
            end
        end
    end

    # Identify unique abbreviations
    for sym in outAbbrv
        i = findall(outAbbrv .== sym)
        count = length(i)
        if count > 1
            deleteat!(outAbbrv, i)
            deleteat!(outLong , i)
        end
    end
    @assert length(unique(outLong)) == length(symLong) "Input symbols have ambiguous abbreviations"
    i = sortperm(outAbbrv)
    return (outAbbrv[i], outLong[i])
end



"""
`defaultvalues(template::NamedTuple)`

Return a `Vector{Any}` with default values of a `NamedTuple`.  Each
element in the output vector is `Missing` if the corresponding element
in the tuple is a `Type`, otherwise it is the value itself.
"""
function defaultvalues(template::NamedTuple)
    tmp = collect(values(template))
    default = Vector{Any}(undef, length(tmp))
    for i in 1:length(tmp)
        if isa(tmp[i], Type)
            default[i] = missing
        else
            default[i] = deepcopy(tmp[i])
        end
    end
    return default
end



"""
`canonicalize(template::NamedTuple, input::NamedTuple)`

Canonicalize the `input` named tuple according to `template`, and
return the "canonicalized" named tuple.

Canonicalization rules are as follows:
- output keys are the same as in `template`;
- if `input` contains less items than `template`, the default values
  in `template` will be used to fill unspecified values;
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
  appropriate type.  If conversion is not possible an error is raised.
"""
function canonicalize(template::NamedTuple, input::NamedTuple)
    outval = defaultvalues(template)
    (abbrv, long) = findabbrv(collect(keys(template)))
    
    for i in 1:length(input)
        key = keys(input)[i]
        j = findall(key .== abbrv)
        if length(j) == 0
            error("Unexpected key: " * String(key))
        end
        @assert length(j) == 1
        j = j[1]
        k = findall(long[j] .== keys(template))
        @assert length(k) == 1
        k = k[1]
        if isa(template[k], Type)
            outval[k] = convert(template[k], input[i])
        else
            outval[k] = convert(typeof(template[k]), input[i])
        end
    end
    return NamedTuple{keys(template)}(tuple(outval...))
end


"""
`canonicalize(template::NamedTuple, input::NamedTuple)`

Canonicalize the `input` tuple according to `template`, and
return the "canonicalized" named tuple.

If `input`is an empty tuple the output values are the default values
for `template`.  Otherwise the `input` tuple must have the same number
of elements in `template`.
"""
function canonicalize(template::NamedTuple, input::Tuple)
    outval = defaultvalues(template)
    if length(input) > 0
        @assert length(outval) == length(input)
        for i in 1:length(input)
            if isa(template[i], Type)
                outval[i] = convert(template[i], input[i])
            else
                outval[i] = convert(typeof(template[i]), input[i])
            end
        end
    end
    return NamedTuple{keys(template)}(tuple(outval...))
end


"""
`canonicalize(template::NamedTuple)`

Return the a named tuple with the default values for `template`.
"""
canonicalize(template::NamedTuple) = canonicalize(template, ())


"""
`canonicalize(template::NamedTuple, input)`

Canonicalize the `input` structure according to `template`, and
return the "canonicalized" named tuple.
"""
canonicalize(template::NamedTuple, str) = canonicalize(template, convert(NamedTuple, str))


"""
`canonicalize(template, input::NamedTuple)`

Canonicalize the `input` named tuple according to the `template` structure, and
return the "canonicalized" structure.
"""
function canonicalize(template, input::NamedTuple)
    out = canonicalize(convert(NamedTuple, template), input)
    return typeof(template)(out...)
end


"""
`canonicalize(template, input::Tuple)`

Canonicalize the `input` tuple according to the `template` structure, and
return the "canonicalized" structure.

If `input`is an empty tuple the output values are the default values
for `template`.  Otherwise the `input` tuple must have the same number
of elements in `template`.
"""
function canonicalize(template, input::Tuple)
    out = canonicalize(convert(NamedTuple, template), input)
    return typeof(template)(out...)
end



"""
`canonicalize(template, kwargs...)`

Canonicalize the key/value pairs given as keywords according to the
`template` structure or named tuple.
"""
function canonicalize(template; kwargs...)
    a = collect(kwargs)
    k = getindex.(a, 1)
    v = getindex.(a, 2)
    nt = NamedTuple{tuple(k...)}(tuple(v...))
    return canonicalize(template, nt)
end


end # module
