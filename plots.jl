using DataFrames, MixedModels

sleepstudy =  MixedModels.dataset(:sleepstudy);

using VegaLite

# this works nicely, but only if I don't also do a transformation
sleepstudy |> @vlplot(
    #transform=[{regression=:reaction, on=:days}],
    wrap=:subj,
    columns=3,
    x=:days,y=:reaction,
    mark=:point,
)

using Gadfly

## attempt 1

import Base.Iterators: partition

function partition_facets(facets, n)
    parts = Vector.(collect(partition(facets, n)))

    len = length(first(parts))
    empty = Gadfly.context()

    while length(last(parts)) < length(first(parts))
        push!(last(parts), empty)
    end
    parts
end


facets = map(collect(groupby(sleepstudy, :subj))) do df
    pp = plot(df,
        x=:days,
        y=:reaction,
        Guide.title(first(df.subj)),
        Geom.point,
        layer(Stat.smooth(method=:lm), Geom.line)
    )
    pp
end

ncols = 4

rows = map(partition_facets(facets, ncols)) do rr
    hstack(rr);
end

p = vstack(rows...)

##


## attempt 2
ncols = 4
groups = DataFrame(subj = unique(sleepstudy.subj))
groups.col = rem.(0:nrow(groups)-1, ncols)
groups.row = div.(0:nrow(groups)-1, ncols)

dat = leftjoin(sleepstudy, groups, on=:subj)

plot(dat,
    x=:days,
    y=:reaction,
    xgroup=:row,
    ygroup=:col,
    Geom.subplot_grid(Geom.point,
                     layer(Stat.smooth(method=:lm), Geom.line),
    ),
    Guide.xlabel("Days"),
    Guide.ylabel("Reaction time (ms)"),
    Scale.xgroup(),
    Scale.ygroup(),
)