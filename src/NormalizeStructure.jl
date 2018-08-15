module NormalizeStructure

export normalize

import StatsBase.countmap
import Base.convert


function convert(::Type{NamedTuple}, str)
    @assert isstructtype(typeof(str))
    k = fieldnames.(typeof(str))
    return NamedTuple{k}(getfield.(Ref(str), k))
end

function findAbbrv(symLong::Vector{Symbol})
    @assert length(symLong) >= 1
    symStr = String.(symLong)

    outLong  = Vector{Symbol}()
    outAbbrv = Vector{Symbol}()

    # Max length of string representation of keywords
    maxLen = maximum(length.(symStr))

    # Identify all abbreviations
    for len in 1:maxLen
        for i in 1:length(symStr)
            s = symStr[i]
            if length(s) >= len
                s = s[1:len]
                push!(outLong , symLong[i])
                push!(outAbbrv, Symbol(s))
            end
        end
    end

    # Identify unique abbreviations
    for (sym, count) in countmap(outAbbrv)
        if count > 1
            i = findall(outAbbrv .== sym)
            @assert length(i) > 1
            deleteat!(outLong , i)
            deleteat!(outAbbrv, i)
        end
    end
    @assert length(unique(outLong)) == length(symLong) "Input symbols have ambiguous abbreviations"
    i = sortperm(outAbbrv)
    return (outAbbrv[i], outLong[i])
end


function defaultValues(template::NamedTuple)
    tmp = deepcopy(collect(values(template)))
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


function normalize(template::NamedTuple, input::NamedTuple)
    outval = defaultValues(template)

    (abbrv, long) = findAbbrv(collect(keys(template)))
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


function normalize(template::NamedTuple, input::Tuple)
    outval = defaultValues(template)
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

normalize(template::NamedTuple) = normalize(template, ())
normalize(template::NamedTuple, str) = normalize(template, convert(NamedTuple, str))


function normalize(template, input::NamedTuple)
    out = normalize(convert(NamedTuple, template), input)
    return typeof(template)(out...)
end

function normalize(template, input::Tuple)
    out = normalize(convert(NamedTuple, template), input)
    return typeof(template)(out...)
end

function normalize(template; kwargs...)
    a = collect(kwargs)
    k = getindex.(a, 1)
    v = getindex.(a, 2)
    nt = NamedTuple{tuple(k...)}(tuple(v...))
    return normalize(template, nt)
end


end # module
