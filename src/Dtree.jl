module Dtree

export Dtree, initwork, getwork, run

ccall((:dtree_init, :libdtree), Cint, (Cint, Ptr{Array{Cchar}}),
      length(ARGS), pointer_from_objref(ARGS))

type Dtree
    handle::Array{Ptr{Void}}
    function Dtree(fan_out::Int, num_work_items::Int64, can_parent::Bool,
                   node_mul::Float64, first::Float64, rest::Float64,
                   min_distrib::Int)
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

function Dtree(num_work_items::Int64, first::Float64)
    Dtree(2048, num_work_items, true, 1.0, first, 0.5, 1)
end

function Dtree(num_work_items::Int64, first::Float64, min_distrib::Int)
    Dtree(2048, num_work_items, true, 1.0, first, 0.5, min_distrib)
end

function initwork(dt::Dtree)
    w = [ 0, 0 ]::Array{Int64}
    r = ccall((:dtree_initwork, :libdtree), Cint, (Ptr{Int64}, Ptr{Int64}),
              pointer(w, 1), pointer(w, 2))
    return r, (w[1], w[2])
end

function getwork(dt::Dtree)
    w = [ 0, 0 ]::Array{Int64}
    r = ccall((:dtree_getwork, :libdtree), Cint, (Ptr{Int64}, Ptr{Int64}),
              pointer(w, 1), pointer(w, 2))
    return r, (w[1], w[2])
end

function run(dt::Dtree)
    ccall((:dtree_run, :libdtree), Cint, ())
end

end # module

