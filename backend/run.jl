using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

include("src/TicTacToeBackend.jl")
using .TicTacToeBackend

TicTacToeBackend.run_server()
