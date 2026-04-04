using Test

# Include game logic directly (no HTTP needed for unit tests)
include("../src/game.jl")
using .Game: EMPTY, PLAYER_X, PLAYER_O, new_board, valid_moves, apply_move, check_winner, is_terminal, opponent
include("../src/mcts.jl")

@testset "Game Logic" begin
    @testset "new_board" begin
        b = new_board()
        @test length(b) == 9
        @test all(b .== EMPTY)
    end

    @testset "valid_moves" begin
        b = new_board()
        @test valid_moves(b) == collect(1:9)

        b2 = apply_move(b, 5, PLAYER_X)
        @test 5 ∉ valid_moves(b2)
        @test length(valid_moves(b2)) == 8
    end

    @testset "check_winner - row" begin
        b = new_board()
        b = apply_move(b, 1, PLAYER_X)
        b = apply_move(b, 2, PLAYER_X)
        b = apply_move(b, 3, PLAYER_X)
        @test check_winner(b) == PLAYER_X
    end

    @testset "check_winner - column" begin
        b = new_board()
        b = apply_move(b, 1, PLAYER_O)
        b = apply_move(b, 4, PLAYER_O)
        b = apply_move(b, 7, PLAYER_O)
        @test check_winner(b) == PLAYER_O
    end

    @testset "check_winner - diagonal" begin
        b = new_board()
        b = apply_move(b, 1, PLAYER_X)
        b = apply_move(b, 5, PLAYER_X)
        b = apply_move(b, 9, PLAYER_X)
        @test check_winner(b) == PLAYER_X
    end

    @testset "check_winner - no winner" begin
        b = new_board()
        @test check_winner(b) == EMPTY
    end

    @testset "is_terminal - draw" begin
        # X O X / X X O / O X O -> draw
        b = [PLAYER_X, PLAYER_O, PLAYER_X,
             PLAYER_X, PLAYER_X, PLAYER_O,
             PLAYER_O, PLAYER_X, PLAYER_O]
        @test is_terminal(b)
        @test check_winner(b) == EMPTY
    end

    @testset "opponent" begin
        @test opponent(PLAYER_X) == PLAYER_O
        @test opponent(PLAYER_O) == PLAYER_X
    end
end

@testset "MCTS" begin
    @testset "mcts picks winning move" begin
        # X can win immediately at position 7 (completing column 1,4,7).
        # O can win at position 8 (completing column 2,5,8).
        # X O _
        # X O _
        # _ _ _
        b = [PLAYER_X, PLAYER_O, EMPTY,
             PLAYER_X, PLAYER_O, EMPTY,
             EMPTY,    EMPTY,    EMPTY]
        move = mcts_best_move(b, PLAYER_X; iterations=500)
        # X should choose the winning move (7) rather than any other move
        @test move == 7
    end

    @testset "mcts blocks opponent win" begin
        # O can win at position 3 (row 1), X can win at position 6 (row 2)
        # O O _
        # X X _
        # _ _ _
        # X should prefer winning (pos 6) over just blocking (pos 3)
        b = [PLAYER_O, PLAYER_O, EMPTY,
             PLAYER_X, PLAYER_X, EMPTY,
             EMPTY,    EMPTY,    EMPTY]
        move = mcts_best_move(b, PLAYER_X; iterations=500)
        # Either win (6) or block (3) is acceptable; winning is preferred
        @test move in (3, 6)
    end

    @testset "mcts returns valid move on empty board" begin
        b = new_board()
        move = mcts_best_move(b, PLAYER_X; iterations=200)
        @test move in 1:9
    end

    @testset "mcts returns nothing on full board" begin
        b = [PLAYER_X, PLAYER_O, PLAYER_X,
             PLAYER_X, PLAYER_X, PLAYER_O,
             PLAYER_O, PLAYER_X, PLAYER_O]
        move = mcts_best_move(b, PLAYER_X; iterations=100)
        @test move === nothing
    end
end

println("All tests passed!")
