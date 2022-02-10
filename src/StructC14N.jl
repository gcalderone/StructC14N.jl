module StructC14N

using DataStructures

export canonicalize

######################################################################
# Private functions
######################################################################

"""
  `findabbrv(v::Vector{Symbol})`

  Find all unique abbreviations of symbols in `v`.  Return a tuple of
  two `Vector{Symbol}`: the first contains all possible abbreviations;
  the second contains the corresponding non-abbreviated symbols.
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
    return OrderedDict(Pair.(outAbbrv[i], outLong[i]))
end


function myconvert(template, vv)
    if isa(template, Type)
        tt = template
    else
        tt = typeof(template)
    end

    if isa(tt, Union)
        tt = nonmissingtype(tt)
        @assert !isa(tt, Union) "The only supported unions are of the form Union{Missing, T}"
        ismissing(vv)  &&  (return missing)
    end

    if typeof(vv) <: AbstractString  &&  tt <: Number
        return convert(tt, Meta.parse(vv))
    end

    if typeof(vv) <: Number  &&  tt <: AbstractString
        return string(vv)
    end

    if length(methods(parse, (Type{tt}, typeof(vv)))) > 0
        return parse(tt, vv)
    end

    if length(methods(convert, (Type{tt}, typeof(vv)))) > 0
        return convert(tt, vv)
    end

    return tt(vv)
end


######################################################################
# Public functions
######################################################################


# Template is a NamedTuple
"""
  `canonicalize(template::NamedTuple, input::NamedTuple)`

  Canonicalize an input NamedTuple according to a NamedTuple template.
  Returns a NamedTuple.

  Default values must be specified in `template`.  To avoid specifying
  a default value the corresponding item must be a `Type` object, and
  its default value will be `missing` (unless overriden in `input`).

# Examples
```julia-repl
julia> template = (xrange=NTuple{2, Number},
                   yrange=NTuple{2, Number},
                   title="Default string");

julia> c = canonicalize(template, (xr=(1,2),))
(xrange = (1, 2), yrange = missing, title = "Default string")

julia> c = canonicalize(template, (xr=(1,2), yrange=(3, 4.), tit="Foo"))
(xrange = (1, 2), yrange = (3, 4.0), title = "Foo")
```
"""
function canonicalize(template::NamedTuple, input::NamedTuple, dconvert=Dict{Symbol, Function}())
    abbrv = findabbrv(collect(keys(template)))

    # Default values are explicitly provided in `template`.  If a slot
    # in `template` is a `Type` object the corresponding default value
    # is `missing`.
    output = OrderedDict{Symbol, Any}()
    for key in keys(template)
        val = deepcopy(getproperty(template, key))
        if isa(val, Type)
            output[key] = missing  # default value is missing
        else
            output[key] = val      # default value is copied from the template
        end
    end

    # Override with input values
    for key in keys(input)
        val = deepcopy(getproperty(input, key))
        @assert haskey(abbrv, key) "Unexpected key: $key"
        longkey = abbrv[key]
        if haskey(dconvert, longkey)
            output[longkey] = dconvert[longkey](val)
        else
            output[longkey] = myconvert(getproperty(template, longkey), val)
        end
    end
    return NamedTuple(output)
end


# Template is a structure definition
"""
  `canonicalize(template::DataType, input::NamedTuple)`

  Canonicalize an input NamedTuple according to a template in a
  structure definition.  Returns a structure instance.

  If `input` contains less values than required in the template an
  attempt will be made to create a structure with `missing` values.
  If this is forbidden by the structure definition an error is raised.

# Examples
```julia-repl
julia> struct AStruct
           xrange::NTuple{2, Number}
           yrange::NTuple{2, Number}
           title::Union{Missing, String}
       end

julia> canonicalize(AStruct, (xr=(1,2), yr=(3,4.)))
AStruct((1, 2), (3, 4.0), missing)

julia> canonicalize(AStruct, (xr=(1,2), yr=(3,4.), tit="Foo"))
AStruct((1, 2), (3, 4.0), "Foo")
```
"""
function canonicalize(template::DataType, input::NamedTuple, dconvert=Dict{Symbol, Function}())
    @assert isstructtype(template)
    abbrv = findabbrv(collect(fieldnames(template)))

    # Default value is `missing` for all fields
    output = OrderedDict{Symbol, Any}()
    for key in fieldnames(template)
        output[key] = missing
    end

    # Override with input values
    for key in keys(input)
        val = deepcopy(getproperty(input, key))
        @assert haskey(abbrv, key) "Unexpected key: $key"
        longkey = abbrv[key]
        if haskey(dconvert, longkey)
            output[longkey] = dconvert[longkey](val)
        else
            output[longkey] = myconvert(fieldtype(template, longkey), val)
        end
    end
    return template(collect(values(output))...)
end


# Template is a structure instance
"""
  `canonicalize(template, input::NamedTuple)`

  Canonicalize an input NamedTuple according to a template in a
  structure instance.  Returns a structure instance.

  All values in the template are taken as default values.

# Examples
```julia-repl
julia> struct AStruct
           xrange::NTuple{2, Number}
           yrange::NTuple{2, Number}
           title::Union{Missing, String}
       end

julia> template = AStruct((0,0), (0.,0.), missing);

julia> canonicalize(template, (xr=(1,2),))
AStruct((1, 2), (0.0, 0.0), missing)

julia> canonicalize(template, (yr=(1,2), xr=(3.3, 4.4), tit="Foo"))
AStruct((3.3, 4.4), (1, 2), "Foo")
```
"""
function canonicalize(instance, input::NamedTuple, dconvert=Dict{Symbol, Function}())
    template = typeof(instance)
    @assert isstructtype(template)
    abbrv = findabbrv(collect(fieldnames(template)))

    # Default values are copied from template
    output = OrderedDict{Symbol, Any}()
    for key in fieldnames(template)
        output[key] = deepcopy(getfield(instance, key))
    end

    # Override with input values
    for key in keys(input)
        val = deepcopy(getproperty(input, key))
        @assert haskey(abbrv, key) "Unexpected key: $key"
        longkey = abbrv[key]
        if haskey(dconvert, longkey)
            output[longkey] = dconvert[longkey](val)
        else
            output[longkey] = myconvert(fieldtype(template, longkey), val)
        end
    end
    return template(collect(values(output))...)
end



# Input is a Tuple: convert to a NamedTuple using template names and
# invoke previous methods
"""
  `canonicalize(template, input::Tuple)`

  Canonicalize an input tuple according to a template.  Returns a
  NamedTuple or a structure instance according to the type of
  `template`.  The input tuple must have same number of elements as
  the template.

# Examples
```julia-repl
julia> template = (xrange=NTuple{2,Number},
                   yrange=NTuple{2,Number},
                   title="Default string");

julia> canonicalize(template, ((1,2), (3, 4.), "Foo"))
(xrange = (1, 2), yrange = (3, 4.0), title = "Foo")

julia> struct AStruct
           xrange::NTuple{2, Number}
           yrange::NTuple{2, Number}
           title::Union{Missing, String}
       end;

julia> canonicalize(AStruct, ((1,2), (3, 4.), "Foo"))
AStruct((1, 2), (3, 4.0), "Foo")

julia> template = AStruct((0,0), (0.,0.), missing);

julia> canonicalize(template, ((1,2), (3, 4.), "Foo"))
AStruct((1, 2), (3, 4.0), "Foo")
```
"""
function canonicalize(template, input::Tuple, dconvert=Dict{Symbol, Function}())
    if isa(template, NamedTuple)
        @assert length(template) == length(input) "Input tuple must have same length as template"
        return canonicalize(template, NamedTuple{keys(template)}(input), dconvert)
    elseif isa(template, DataType)
        @assert isstructtype(template)
        @assert length(fieldnames(template)) == length(input) "Input tuple must have same number of fields as the template"
        return canonicalize(template, NamedTuple{fieldnames(template)}(input), dconvert)
    elseif isstructtype(typeof(template))
        @assert isstructtype(typeof(template))
        @assert length(fieldnames(typeof(template))) == length(input) "Input tuple must have same number of fields as the template"
        return canonicalize(template, NamedTuple{fieldnames(typeof(template))}(input), dconvert)
    end
    error("Template must be a NamedTuple, a structure definition or a structure instance")
end


# Inputs are given as keywords
"""
  `canonicalize(template, kwargs...)`

  Canonicalize the key/value pairs given as keywords according to the
  `template` structure or named tuple.
"""
function canonicalize(template, dconvert=Dict{Symbol, Function}(); kwargs...)
    return canonicalize(template, NamedTuple(kwargs), dconvert)
end

end # module
