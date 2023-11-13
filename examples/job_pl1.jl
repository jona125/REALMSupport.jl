import Pkg
Pkg.activate("/storage1/fs1/holy/Active/jchang/.julia/dev/REALMSupport")

cd(ARGS[3])
z_stack = parse(Int64,ARGS[4])
include(ARGS[1])
files = readdir()
files = filter(x->occursin("_t.tif",x),files)
[rm(x) for x in files]
include(ARGS[2])
