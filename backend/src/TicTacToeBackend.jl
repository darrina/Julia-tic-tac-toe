module TicTacToeBackend

include("game.jl")
using .Game

include("mcts.jl")
include("server.jl")

end
