module Dtree

export DtreeScheduler, initwork, getwork, nnodes, nodeid, runtree

type DtreeScheduler
    handle::Array{Ptr{Void}}
    function DtreeScheduler(fan_out::Int, num_work_items::Int64,
            can_parent::Bool, node_mul::Float64, first::Float64,
            rest::Float64, min_distrib::Int)
        d = new([0])
        r = ccall((:dtree_create, :libdtree), Cint, (Cint, Cint, Cint,
                  Cdouble, Cdouble, Cdouble, Cshort, Ptr{Void}), fan_out,
                  num_work_items, can_parent, node_mul, first, rest,
                  min_distrib, pointer(d.handle))
        if r != 0
            error("construction failure")
        end
        finalizer(d, (x -> ccall((:dtree_destroy, :libdtree),
                                 Void, (Ptr{Void},), d.handle[1])))
        d
    end
end

DtreeScheduler(num_work_items::Int64, first::Float64) =
    DtreeScheduler(2048, num_work_items, true, 1.0, first, 0.5, 1)
DtreeScheduler(num_work_items::Int64, first::Float64, min_distrib::Int) =
    DtreeScheduler(2048, num_work_items, true, 1.0, first, 0.5, min_distrib)

function __init__()
    ccall((:dtree_init, :libdtree), Cint, (Cint, Ptr{Array{Cchar}}),
          length(ARGS), pointer_from_objref(ARGS))
end

function initwork(dt::DtreeScheduler)
    w = [ 0, 0 ]::Array{Int64}
    r = ccall((:dtree_initwork, :libdtree), Cint,
            (Ptr{Void}, Ptr{Int64}, Ptr{Int64}), dt.handle[1],
            pointer(w, 1), pointer(w, 2))
    return r, (w[1], w[2])
end

function getwork(dt::DtreeScheduler)
    w = [ 0, 0 ]::Array{Int64}
    r = ccall((:dtree_getwork, :libdtree), Cint,
            (Ptr{Void}, Ptr{Int64}, Ptr{Int64}), dt.handle[1],
            pointer(w, 1), pointer(w, 2))
    return r, (w[1], w[2])
end

nnodes(dt::DtreeScheduler) = Int(ccall((:dtree_nnodes, :libdtree), Cint, (Ptr{Void},), dt.handle[1]))
nodeid(dt::DtreeScheduler) = Int(ccall((:dtree_nodeid, :libdtree), Cint, (Ptr{Void},), dt.handle[1])+1)
runtree(dt::DtreeScheduler) = ccall((:dtree_run, :libdtree), Cint, (Ptr{Void},), dt.handle[1])

end # module

