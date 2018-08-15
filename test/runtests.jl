using NormalizeStructures
using Test

template = (xrange=NTuple{2,Number},
            yrange=NTuple{2,Number},
            title="A string")

c = normalize(template,
              (xr=(1,2), tit="Foo"))

@test c.xrange == (1, 2)
@test ismissing(c.yrange)
@test c.title == "Foo"


c = normalize(template,
              ((1,2), (3.3, 4.4), "Foo"))

@test c.xrange == (1, 2)
@test c.yrange == (3.3, 4.4)
@test c.title == "Foo"


c = normalize(template,
              xr=(21,22), tit="Bar")
@test c.xrange == (21, 22)
@test ismissing(c.yrange)
@test c.title == "Bar"


mutable struct AStruct
    xrange::NTuple{2, Number}
    yrange::NTuple{2, Number}
    title::String
end

template = AStruct((0,0), (0., 0.), "A string")

c = normalize(template,
              (xr=(1,2), tit="Foo"))

@test c.xrange == (1, 2)
@test c.yrange == (0., 0.)
@test c.title == "Foo"

c = normalize(template,
              ((1,2), (3.3, 4.4), "Foo"))

@test c.xrange == (1, 2)
@test c.yrange == (3.3, 4.4)
@test c.title == "Foo"

c = normalize(template,
              ((11,12), (13.3, 14.4), "Foo"))
@test c.xrange == (11, 12)
@test c.yrange == (13.3, 14.4)
@test c.title == "Foo"


c = normalize(template,
              xr=(21,22), tit="Bar")
@test c.xrange == (21, 22)
@test c.yrange == (0., 0.)
@test c.title == "Bar"
