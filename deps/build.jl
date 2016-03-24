using BinDeps

target = "libdtree.$(Libdl.dlext)"
vers = "1.0"

if !isfile(target)
    if OS_NAME == :Linux
	println("Compiling libdtree...")
	run(`make`)
    else
	error("Dtree is Linux-only right now")
    end
end

