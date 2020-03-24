# PooledArrays utils

function pool(v)
    s = refarray(v)
    pv = PooledArray(s)
    map(pv) do el
        refvalue(v, el)
    end
end

pool(v::PooledVector) = v

pool(v::AbstractVector{<:Integer}) = v

# ranking

jointable(ts) = jointable(ts, foldl(merge, ts))

function jointable(ts, ::NamedTuple{names}) where names
    vals = map(names) do name
        vcat((get(table, name, Union{}[]) for table in ts)...)
    end
    NamedTuple{names}(vals)
end

rankdict(d) = Dict(val => i for (i, val) in enumerate(uniquesorted(vec(d))))

function rankdicts(ts)
    piter = map(first, Iterators.flatten(Base.Generator(pairs, ts)))
    tables = jointable(piter)
    return map(rankdict, tables)
end

# tabular utils

wrapif(v::T, ::Type{T}) where {T} = fill(v)
wrapif(v, ::Type) = v

addnames(::NamedTuple{names}, args...) where {names} = NamedTuple{names}(args)
addnames(m::MixedTuple, args...) = addnames(m.kwargs, args...)

function aos(m::MixedTuple)
    res = MixedTuple.(tuple.(m.args...), addnames.(Ref(m), m.kwargs...))
    return wrapif(res, MixedTuple)
end
function aos(n::NamedTuple)
    res = addnames.(Ref(n), n...)
    return wrapif(res, NamedTuple)
end

function mapcols(f, t)
    cols = columns(t)
    itr = (name => f(getcolumn(cols, name)) for name in columnnames(cols))
    return OrderedDict{Symbol, AbstractVector}(itr)
end
coldict(t) = mapcols(identity, t)
coldict(t, idxs) = mapcols(v -> view(v, idxs), t)

function keepvectors(t::NamedTuple{names}) where names
    f, ls = first(t), NamedTuple{tail(names)}(t)
    ff = f isa AbstractVector ? NamedTuple{(first(names),)}((f,)) : NamedTuple()
    return merge(ff, keepvectors(ls))
end
keepvectors(::NamedTuple{()}) = NamedTuple()

