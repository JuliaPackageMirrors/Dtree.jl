#!/usr/bin/env julia

using Base.Threads
using Dtree

const cpu_hz = 2.3e9
const libdtree = joinpath(dirname(@__FILE__), "..", "deps", "libdtree.so")

@inline rdtsc() = ccall((:rdtsc, libdtree), Culonglong, ())
@inline cpu_pause() = ccall((:cpu_pause, libdtree), Void, ())
@inline secs2cpuhz(s) = s * cpu_hz::Float64

@inline function ntputs(nid,tid,s)
    #if nid == 1
        ccall(:puts, Cint, (Cstring,), string("[", nid, "]<", tid, "> ", s))
    #end
    return
end

function threadfun(dt, ni, ci, li, ilock, rundt, dura)
    tid = threadid()
    if rundt && tid == 1
        ntputs(dt_nodeid, tid, "running tree")
        while runtree(dt)
            cpu_pause()
        end
    else
        ntputs(dt_nodeid, tid, string("begin, ", ni[], " items, ", length(dura), " available delays"))
        while ni[] > 0
            lock!(ilock)
            if li[] == 0
                ntputs(dt_nodeid, tid, string("out of work"))
                unlock!(ilock)
                break
            end
            if ci[] == li[]
                ntputs(dt_nodeid, tid, string("work consumed (last was ", li[], "); requesting more"))
                ni[], (ci[], li[]) = getwork(dt)
                ntputs(dt_nodeid, tid, string("got ", ni[], " work items (", ci[], " to ", li[], ")"))
                unlock!(ilock)
                continue
            end
            item = ci[]
            ci[] = ci[] + 1
            unlock!(ilock)

            # wait dura[item] seconds
            ticks = secs2cpuhz(dura[item])
            #ntputs(dt_nodeid, tid, string("item ", item, ", ", ticks, " ticks"))
            startts = rdtsc()
            while rdtsc() - startts < ticks
                cpu_pause()
            end
        end
    end
end

function bench(nwi, meani, stddevi, first_distrib, rest_distrib, min_distrib, fan_out = 1024)
    # create the tree
    dt, is_parent = DtreeScheduler(fan_out, nwi, true, 1.0, first_distrib, rest_distrib, min_distrib)

    # ---
    if dt_nodeid == 1
        println("dtreebench -- ", dt_nnodes, " nodes")
        println("  system clock speed is ", cpu_hz, " GHz")
    end

    # roughly how many work items will each node will handle?
    each, r = divrem(nwi, dt_nnodes)
    if r > 0
        each = each + 1
    end

    # ---
    if dt_nodeid == 1
        println("  ", nwi, " work items, ~", each, " per node")
    end

    # generate random numbers for work item durations
    dura = Float64[]
    mn = repmat([meani-0.5*stddevi, meani+0.5*stddevi], ceil(Int, dt_nnodes/2))
    mt = MersenneTwister(7777777)
    for i = 1:dt_nnodes
        r = randn(mt)*stddevi*0.25+mn[i]
        append!(dura, max(randn(mt, each)*stddevi+r, zero(Float64)))
    end

    # ---
    if dt_nodeid == 1
        println("  initializing...")
    end

    # get the initial allocation
    ilock = SpinLock()
    ni, (ci, li) = initwork(dt)

    # ---
    if dt_nodeid == 1
        println("  ...done.")
        println(string("  [0001] has ", ci, " through ", li))
        println("  starting threads...")
    end

    # start threads and run 
    tfargs = Core.svec(threadfun, dt, Ref(ni), Ref(ci), Ref(li), ilock, runtree(dt), dura)
    ccall(:jl_threading_run, Void, (Any,), tfargs)

    # ---
    if dt_nodeid == 1
        println("  ...done.")
        println("complete")
    end
    tic()
    finalize(dt)
    toc()
end

#bench(80, 0.5, 0.125, 0.2, 0.5, nthreads())
bench(100, 0.5, 0.125, 0.5, 0.5, nthreads())

