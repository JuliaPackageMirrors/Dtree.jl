using BinDeps

target = "libdtree.$(Libdl.dlext)"
vers = "1.0"

if !isfile(target)
    if OS_NAME == :Linux
        # TODO: clean this up to use Intel MPI if it's available
        # and Open MPI otherwise
        if gethostname()[1:4] == "cori"
            println("Compiling libdtree with Intel MPI...")
            run(`make`)
        else
            println("Compiling libdtree with OpenMPI...")
            run(`make OPENMPI=1`)
        end
    else
	error("Dtree is Linux-only right now")
    end
end

