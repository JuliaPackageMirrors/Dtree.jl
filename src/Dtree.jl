module Dtree

#if VERSION > v"0.5.0-dev"
if isdefined(Base, :Threads)
    using Base.Threads
    enter_gc_safepoint() = ccall(:jl_gc_safe_enter, Int8, ())
    leave_gc_safepoint(gs) = ccall(:jl_gc_safe_leave, Void, (Int8,), gs)
else
    # Pre-Julia 0.5 there are no threads
    nthreads() = 1
    threadid() = 1
    enter_gc_safepoint() = 1
    leave_gc_safepoint(gs) = 1
end

export DtreeScheduler, dt_nnodes, dt_nodeid, initwork, getwork, runtree, cpu_pause

const fan_out = 2048
const drain_rate = 0.4

const libdtree = joinpath(Pkg.dir("Dtree"), "deps", "Dtree",
        "libdtree.$(Libdl.dlext)")

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
            can_parent::Bool, node_mul::Float64,
            first::Float64, rest::Float64, min_dist::Int)
        parents_work = nthreads()>1 ? 1 : 0
        cthrid = cfunction(threadid, Int64, ())
        d = new([0])
        p = [ 0 ]
        r = ccall((:dtree_create, libdtree), Cint, (Cint, Cint, Cint, Cint,
                  Cdouble, Cint, Ptr{Void}, Cdouble, Cdouble, Cshort,
                  Ptr{Void}, Ptr{Int64}), fan_out, num_work_items,
                  can_parent, parents_work, node_mul, nthreads(), cthrid,
                  first, rest, min_dist, pointer(d.handle), pointer(p, 1))
        if r != 0
            error("construction failure")
        end
        finalizer(d, (x -> ccall((:dtree_destroy, libdtree),
                                 Void, (Ptr{Void},), d.handle[1])))
        d, Bool(p[1])
    end
end

DtreeScheduler(num_work_items::Int64, first::Float64) =
    DtreeScheduler(fan_out, num_work_items, true, 1.0, first, drain_rate, 1)
DtreeScheduler(num_work_items::Int64, first::Float64, min_distrib::Int) =
    DtreeScheduler(fan_out, num_work_items, true, 1.0, first, drain_rate, min_distrib)

function initwork(dt::DtreeScheduler)
    w = [ 1, 1 ]::Array{Int64}
    wp1 = pointer(w, 1)
    wp2 = pointer(w, 2)
    gs = enter_gc_safepoint()
    r = ccall((:dtree_initwork, libdtree), Cint,
            (Ptr{Void}, Ptr{Int64}, Ptr{Int64}), dt.handle[1], wp1, wp2)
    leave_gc_safepoint(gs)
    return r, (w[1]+1, w[2])
end

function getwork(dt::DtreeScheduler)
    w = [ 1, 1 ]::Array{Int64}
    wp1 = pointer(w, 1)
    wp2 = pointer(w, 2)
    gs = enter_gc_safepoint()
    r = ccall((:dtree_getwork, libdtree), Cint,
            (Ptr{Void}, Ptr{Int64}, Ptr{Int64}), dt.handle[1], wp1, wp2)
    leave_gc_safepoint(gs)
    return r, (w[1]+1, w[2])
end

function runtree(dt::DtreeScheduler)
    r = 0
    gs = enter_gc_safepoint()
    r = ccall((:dtree_run, libdtree), Cint, (Ptr{Void},), dt.handle[1])
    leave_gc_safepoint(gs)
    Bool(r > 0)
end

@inline cpu_pause() = ccall((:cpu_pause, libdtree), Void, ())

@inline rdtsc() = ccall((:rdtsc, libdtree), Culonglong, ())

end # module

