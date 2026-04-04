module TicTacToeBackend

include("game.jl")
include("mcts.jl")
include("server.jl")

using .Server: run_server
export run_server

end
