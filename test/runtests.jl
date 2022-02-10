using StructC14N
using Test

# Template is a NamedTuple
template = (xrange=NTuple{2, Number},
            yrange=NTuple{2, Number},
            title="Default string")

c = canonicalize(template, (xr=(1,2),))
@test c.xrange == (1, 2)
@test ismissing(c.yrange)
@test c.title == "Default string"

c = canonicalize(template, (xr=(1,2), yrange=(3, 4.), tit="Foo"))
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test c.title == "Foo"

#  ...input is a Tuple
@test_throws AssertionError canonicalize(template, ((1,2)))
c = canonicalize(template, ((1,2), (3, 4.), "Foo"))
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test c.title == "Foo"

#  ...inputs are given as keywords
c = canonicalize(template, xr=(1,2), yrange=(3, 4.), tit="Foo")
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test c.title == "Foo"



# Template is a structure definition
struct AStruct
    xrange::NTuple{2, Number}
    yrange::NTuple{2, Number}
    title::Union{Missing, String}
end

@test_throws MethodError canonicalize(AStruct, (xr=(1,2), tit="Foo"))

c = canonicalize(AStruct, (xr=(1,2), yrang=(3, 4.)))
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test ismissing(c.title)

c = canonicalize(AStruct, (xr=(1,2), yrang=(3, 4.), tit="Foo"))
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test c.title == "Foo"

#  ...input is a Tuple
@test_throws AssertionError canonicalize(AStruct, ((1,2)))
c = canonicalize(AStruct, ((1,2), (3, 4.), "Foo"))
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test c.title == "Foo"

#  ...inputs are given as keywords
c = canonicalize(AStruct, xr=(1,2), yrang=(3, 4.), tit="Foo")
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test c.title == "Foo"


# Template is a structure instance
template = AStruct((0,0), (0.,0.), missing)
c = canonicalize(template, (xr=(1,2),))
@test c.xrange == (1, 2)
@test c.yrange == (0., 0.)
@test ismissing(c.title)

c = canonicalize(template, (yr=(1,2), xr=(3.3, 4.4), tit="Foo"))
@test c.yrange == (1, 2)
@test c.xrange == (3.3, 4.4)
@test c.title == "Foo"

#  ...input is a Tuple
@test_throws AssertionError canonicalize(template, ((1,2)))
c = canonicalize(template, ((1,2), (3, 4.), "Foo"))
@test c.xrange == (1, 2)
@test c.yrange == (3, 4.)
@test c.title == "Foo"

#  ...inputs are given as keywords
c = canonicalize(template, yr=(1,2), xr=(3.3, 4.4), tit="Foo")
@test c.yrange == (1, 2)
@test c.xrange == (3.3, 4.4)
@test c.title == "Foo"



configtemplate = (optStr=String,
                  optInt=Int,
                  optFloat=Float64)

configentry = "aa, 1, 2"
c = canonicalize(configtemplate, (split(configentry, ",")...,))
@test c.optStr == "aa"
@test c.optInt == 1
@test c.optFloat == 2.0

configentry = "optFloat=20, optStr=\"aaa\", optInt=10"
c = canonicalize(configtemplate, eval(Meta.parse("($configentry)")))
@test c.optStr == "aaa"
@test c.optInt == 10
@test c.optFloat == 20.0


function myparse(input)
    if input == "ten"
        return 10
    end
    return 1
end
configentry = "optFloat=20, optStr=\"aaa\", optInt=\"ten\""
c = canonicalize(configtemplate, eval(Meta.parse("($configentry)")), Dict(:optInt=>myparse))
@test c.optStr == "aaa"
@test c.optInt == 10
@test c.optFloat == 20.0
