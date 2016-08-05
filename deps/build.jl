target = "Dtree/libdtree.$(Libdl.dlext)"
vers = "0.0.1"

if !isfile(target)
    @static if is_linux()
        LibGit2.clone("https://github.com/kpamnany/Dtree", "Dtree")
        println("Compiling libdtree...")
        run(`make -C Dtree`)
    else
	error("Dtree is Linux-only right now")
    end
end

