using Base.Threads
using Dtree

cpu_hz = 1e9

@inline rdtsc() = ccall((:rdtsc, :libdtree), Culonglong, ())
@inline cpupause() = ccall((:cpupause, :libdtree), Void, ())
@inline secs2hz(s) = s * cpu_hz
@inline tputs(tid,s) = ccall(:puts, Cint, (Cstring,), string(tid, "> ", s))

function threadfun(dt, ni, ci, li, ilock, rundt, dura)
    tid = threadid()
    if rundt && tid == 1
        while runtree(dt)
            cpupause()
        end
    else
        while ni > 0
            lock!(ilock)
            if li == 0
                unlock!(ilock)
                break
            end
            if ci == li
                ni, (ci, li) = getwork(dt)
                unlock!(ilock)
                continue
            end
            item = ci
            ci = ci + 1
            unlock!(ilock)

            # wait dura[item] seconds
        end
    end
end

function bench(nwi, meani, stddevi, first_distrib, rest_distrib, min_distrib, fan_out = 1024)
    # create the tree
    dt = DtreeScheduler(fan_out, nwi, true, 1.0, first_distrib, rest_distrib, min_distrib)

    # system/run information
    num_nodes = nnodes(dt)
    node_id = nodeid(dt)
    r = rdtsc()
    sleep(1)
    global cpu_hz = rdtsc()-r

    # ---
    if node_id == 1
        println("dtreebench -- ", num_nodes, " nodes")
        println("  system clock speed is ", cpu_hz/1e9, " GHz")
    end

    # roughly how many work items will each node will handle?
    each, r = divrem(nwi, num_nodes)
    if r > 0
        each = each + 1
    end

    # ---
    if node_id == 1
        println("  ", nwi, " work items, ~", each, " per node")
    end

    # generate random numbers for work item durations
    dura = Float64[]
    mn = repmat([meani-0.5*stddevi, meani+0.5*stddevi], ceil(Int, num_nodes/2))
    mt = MersenneTwister(7777777)
    for i = 1:num_nodes
        r = randn(mt)*stddevi*0.25+mn[i]
        append!(dura, max(randn(mt, each)*stddevi+r, zero(Float64)))
    end

    # ---
    if node_id == 1
        println("  initializing...")
    end

    # get the initial allocation
    ilock = SpinLock()
    ni, (ci, li) = initwork(dt)

    # ---
    if node_id == 1
        println("  ...done.")
        println("  starting threads...")
    end

    # start threads and run 
    tfargs = Core.svec(dt, ni, ci, li, ilock, runtree(dt)>0, dura)
    ccall(:jl_threading_run, Void, (Any, Any), threadfun, tfargs)

    # ---
    if node_id == 1
        println("  ...done.")
        println("complete")
    end
    dt = ()
end

#bench(1310720, 0.5, 0.125, 0.2, 0.5, nthreads())

