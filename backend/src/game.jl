# game.jl - Core Tic-Tac-Toe game logic

module Game

const EMPTY = 0
const PLAYER_X = 1
const PLAYER_O = 2

# Board is a 9-element vector (row-major, indices 1-9)
# Index mapping:
#  1 | 2 | 3
# ---+---+---
#  4 | 5 | 6
# ---+---+---
#  7 | 8 | 9

const WIN_LINES = [
    (1,2,3), (4,5,6), (7,8,9),  # rows
    (1,4,7), (2,5,8), (3,6,9),  # cols
    (1,5,9), (3,5,7),            # diagonals
]

function new_board()
    return zeros(Int, 9)
end

function valid_moves(board::Vector{Int})
    return [i for i in 1:9 if board[i] == EMPTY]
end

function apply_move(board::Vector{Int}, pos::Int, player::Int)
    new_b = copy(board)
    new_b[pos] = player
    return new_b
end

function check_winner(board::Vector{Int})
    for (a, b, c) in WIN_LINES
        if board[a] != EMPTY && board[a] == board[b] == board[c]
            return board[a]
        end
    end
    return EMPTY
end

function is_terminal(board::Vector{Int})
    return check_winner(board) != EMPTY || isempty(valid_moves(board))
end

function opponent(player::Int)
    return player == PLAYER_X ? PLAYER_O : PLAYER_X
end

export EMPTY, PLAYER_X, PLAYER_O, WIN_LINES,
       new_board, valid_moves, apply_move, check_winner, is_terminal, opponent

end # module Game
