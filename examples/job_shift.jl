import Pkg
Pkg.activate("/storage1/fs1/holy/Active/jchang/.julia/dev/REALMSupport")


cd(ARGS[2])
folder = ARGS[2]
include(ARGS[1])

