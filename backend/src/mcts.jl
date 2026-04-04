# mcts.jl - Monte Carlo Tree Search algorithm

using .Game: EMPTY, valid_moves, apply_move, check_winner, is_terminal, opponent

mutable struct MCTSNode
    board::Vector{Int}
    player::Int          # player whose turn it is to move
    move::Union{Int, Nothing}  # move that led to this node
    parent::Union{MCTSNode, Nothing}
    children::Vector{MCTSNode}
    wins::Float64
    visits::Int
    untried_moves::Vector{Int}
end

function MCTSNode(board::Vector{Int}, player::Int;
                  move=nothing, parent=nothing)
    return MCTSNode(
        board, player, move, parent,
        MCTSNode[], 0.0, 0,
        valid_moves(board)
    )
end

function uct_score(node::MCTSNode, parent_visits::Int, c::Float64=1.41)
    if node.visits == 0
        return Inf
    end
    return (node.wins / node.visits) +
           c * sqrt(log(parent_visits) / node.visits)
end

function select(node::MCTSNode)
    while !is_terminal(node.board)
        if !isempty(node.untried_moves)
            return expand(node)
        else
            node = best_child(node)
        end
    end
    return node
end

function expand(node::MCTSNode)
    move = popfirst!(node.untried_moves)
    new_board = apply_move(node.board, move, node.player)
    child = MCTSNode(new_board, opponent(node.player); move=move, parent=node)
    push!(node.children, child)
    return child
end

function best_child(node::MCTSNode)
    return argmax(c -> uct_score(c, node.visits), node.children)
end

function simulate(board::Vector{Int}, player::Int)
    current_board = copy(board)
    current_player = player
    while !is_terminal(current_board)
        moves = valid_moves(current_board)
        move = moves[rand(1:length(moves))]
        current_board = apply_move(current_board, move, current_player)
        current_player = opponent(current_player)
    end
    return check_winner(current_board)
end

function backpropagate(node::MCTSNode, winner::Int, ai_player::Int)
    current = node
    while current !== nothing
        current.visits += 1
        if winner == ai_player
            current.wins += 1.0
        elseif winner == EMPTY
            current.wins += 0.5
        end
        current = current.parent
    end
end

function mcts_best_move(board::Vector{Int}, ai_player::Int;
                        iterations::Int=1000)
    root = MCTSNode(board, ai_player)

    for _ in 1:iterations
        node = select(root)
        winner = simulate(node.board, node.player)
        backpropagate(node, winner, ai_player)
    end

    if isempty(root.children)
        moves = valid_moves(board)
        return isempty(moves) ? nothing : moves[1]
    end

    best = argmax(c -> c.visits, root.children)
    return best.move
end
