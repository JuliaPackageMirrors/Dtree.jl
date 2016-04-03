module Dtree

using Base.Threads

export DtreeScheduler, dt_nnodes, dt_nodeid, initwork, getwork, runtree, cpu_pause

const libdtree = joinpath(dirname(@__FILE__), "..", "deps", "libdtree.so")

function __init__()
    ccall((:dtree_init, libdtree), Cint, (Cint, Ptr{Ptr{UInt8}}),
          length(ARGS), ARGS)
    global const dt_nnodes =
	    Int(ccall((:dtree_nnodes, libdtree), Cint, ()))
    global const dt_nodeid =
	    Int(ccall((:dtree_nodeid, libdtree), Cint, ())+1)
    atexit() do
        ccall((:dtree_shutdown, libdtree), Cint, ())
    end
end

type DtreeScheduler
    handle::Array{Ptr{Void}}

    function DtreeScheduler(fan_out::Int, num_work_items::Int64,
            can_parent::Bool, node_mul::Float64, first::Float64,
            rest::Float64, min_dist::Int)
        d = new([0])
        r = ccall((:dtree_create, libdtree), Cint, (Cint, Cint, Cint,
                  Cdouble, Cint, Ptr{Void}, Cdouble, Cdouble, Cshort,
                  Ptr{Void}), fan_out, num_work_items, can_parent, node_mul,
                  nthreads(), cfunction(threadid, Int64, ()),
                  first, rest, min_dist, pointer(d.handle))
        if r != 0
            error("construction failure")
        end
        finalizer(d, (x -> ccall((:dtree_destroy, libdtree),
                                 Void, (Ptr{Void},), d.handle[1])))
        d
    end
end

DtreeScheduler(num_work_items::Int64, first::Float64) =
    DtreeScheduler(2048, num_work_items, true, 1.0, first, 0.5, 1)
DtreeScheduler(num_work_items::Int64, first::Float64, min_distrib::Int) =
    DtreeScheduler(2048, num_work_items, true, 1.0, first, 0.5, min_distrib)

function initwork(dt::DtreeScheduler)
    w = [ 1, 1 ]::Array{Int64}
    wp1 = pointer(w, 1)
    wp2 = pointer(w, 2)
    gc_state = ccall(:jl_gc_safe_enter, Int8, ())
    r = ccall((:dtree_initwork, libdtree), Cint,
            (Ptr{Void}, Ptr{Int64}, Ptr{Int64}), dt.handle[1], wp1, wp2)
    ccall(:jl_gc_safe_leave, Void, (Int8,), gc_state)
    return r, (w[1]+1, w[2])
end

function getwork(dt::DtreeScheduler)
    w = [ 1, 1 ]::Array{Int64}
    wp1 = pointer(w, 1)
    wp2 = pointer(w, 2)
    gc_state = ccall(:jl_gc_safe_enter, Int8, ())
    r = ccall((:dtree_getwork, libdtree), Cint,
            (Ptr{Void}, Ptr{Int64}, Ptr{Int64}), dt.handle[1], wp1, wp2)
    ccall(:jl_gc_safe_leave, Void, (Int8,), gc_state)
    return r, (w[1]+1, w[2])
end

function runtree(dt::DtreeScheduler)
    r = 0
    gc_state = ccall(:jl_gc_safe_enter, Int8, ())
    r = ccall((:dtree_run, libdtree), Cint, (Ptr{Void},), dt.handle[1])
    ccall(:jl_gc_safe_leave, Void, (Int8,), gc_state)
    Bool(r > 0)
end

@inline cpu_pause() = ccall((:cpu_pause, libdtree), Void, ())

@inline rdtsc() = ccall((:rdtsc, libdtree), Culonglong, ())

end # module

