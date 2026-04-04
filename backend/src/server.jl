# server.jl - HTTP API server

using HTTP
using JSON
using .Game

const PORT = 8080

const CORS_HEADERS = ["Content-Type" => "application/json",
                      "Access-Control-Allow-Origin" => "*",
                      "Access-Control-Allow-Methods" => "POST, OPTIONS",
                      "Access-Control-Allow-Headers" => "Content-Type"]

function board_from_array(raw_board)
    return [cell == "" ? EMPTY :
            cell == "X" ? PLAYER_X : PLAYER_O
            for cell in raw_board]
end

function board_to_array(board::Vector{Int})
    return [cell == EMPTY ? "" : (cell == PLAYER_X ? "X" : "O") for cell in board]
end

function player_from_string(s::String)
    s == "X" ? PLAYER_X : PLAYER_O
end

function winner_to_string(w::Int)
    w == PLAYER_X ? "X" : w == PLAYER_O ? "O" : ""
end

function handle_ai_move(req::HTTP.Request)
    if req.method == "OPTIONS"
        return HTTP.Response(200, CORS_HEADERS)
    end

    try
        body = JSON.parse(String(req.body))
        raw_board = body["board"]         # array of 9: "" | "X" | "O"
        ai_symbol  = body["aiPlayer"]     # "X" or "O"

        board = board_from_array(raw_board)
        ai_player = player_from_string(ai_symbol)

        # Safety check: only move if it's AI's turn and game isn't over
        if is_terminal(board)
            resp = Dict(
                "board"  => board_to_array(board),
                "winner" => winner_to_string(check_winner(board)),
                "draw"   => isempty(valid_moves(board)) && check_winner(board) == EMPTY,
                "move"   => nothing
            )
            return HTTP.Response(200, CORS_HEADERS, body=JSON.json(resp))
        end

        move = mcts_best_move(board, ai_player; iterations=1000)
        if move !== nothing
            board = apply_move(board, move, ai_player)
        end

        winner = check_winner(board)
        draw = isempty(valid_moves(board)) && winner == EMPTY

        resp = Dict(
            "board"  => board_to_array(board),
            "winner" => winner_to_string(winner),
            "draw"   => draw,
            "move"   => move  # 1-indexed position (1-9)
        )
        return HTTP.Response(200, CORS_HEADERS, body=JSON.json(resp))
    catch e
        @error "Error handling request" exception=e
        return HTTP.Response(500, CORS_HEADERS, body=JSON.json(Dict("error" => string(e))))
    end
end

function handle_check_state(req::HTTP.Request)
    if req.method == "OPTIONS"
        return HTTP.Response(200, CORS_HEADERS)
    end

    try
        body = JSON.parse(String(req.body))
        board = board_from_array(body["board"])

        winner = check_winner(board)
        draw = isempty(valid_moves(board)) && winner == EMPTY

        resp = Dict(
            "winner" => winner_to_string(winner),
            "draw"   => draw,
            "validMoves" => valid_moves(board)
        )
        return HTTP.Response(200, CORS_HEADERS, body=JSON.json(resp))
    catch e
        return HTTP.Response(500, CORS_HEADERS, body=JSON.json(Dict("error" => string(e))))
    end
end

function run_server()
    router = HTTP.Router()
    HTTP.register!(router, "POST", "/ai-move", handle_ai_move)
    HTTP.register!(router, "OPTIONS", "/ai-move", handle_ai_move)
    HTTP.register!(router, "POST", "/check-state", handle_check_state)
    HTTP.register!(router, "OPTIONS", "/check-state", handle_check_state)

    @info "Tic-Tac-Toe Julia backend starting on port $PORT"
    HTTP.serve(router, "0.0.0.0", PORT)
end
