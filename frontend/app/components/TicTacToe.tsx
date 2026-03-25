"use client";

import { useState, useCallback } from "react";

type Cell = "X" | "O" | "";
type GameStatus = "selecting" | "playing" | "won" | "draw";

const BACKEND_URL =
  process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8080";

const WIN_LINES = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
  [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
  [0, 4, 8], [2, 4, 6],             // diagonals
];

function getWinLine(board: Cell[]): number[] | null {
  for (const line of WIN_LINES) {
    const [a, b, c] = line;
    if (board[a] && board[a] === board[b] && board[a] === board[c]) {
      return line;
    }
  }
  return null;
}

async function requestAiMove(
  currentBoard: Cell[],
  aiSymbol: "X" | "O"
): Promise<{
  newBoard: Cell[];
  win: Cell;
  draw: boolean;
  line: number[] | null;
}> {
  const res = await fetch(`${BACKEND_URL}/ai-move`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ board: currentBoard, aiPlayer: aiSymbol }),
  });

  if (!res.ok) throw new Error(`Backend error: ${res.status}`);

  const data = await res.json();
  const newBoard: Cell[] = data.board;
  const win: Cell = data.winner || "";
  const draw: boolean = data.draw;
  const line = win ? getWinLine(newBoard) : null;
  return { newBoard, win, draw, line };
}

export default function TicTacToe() {
  const [board, setBoard] = useState<Cell[]>(Array(9).fill(""));
  const [humanPlayer, setHumanPlayer] = useState<"X" | "O">("X");
  const [status, setStatus] = useState<GameStatus>("selecting");
  const [winner, setWinner] = useState<Cell>("");
  const [isAiThinking, setIsAiThinking] = useState(false);
  const [winLine, setWinLine] = useState<number[] | null>(null);
  const [currentTurn, setCurrentTurn] = useState<"X" | "O">("X");
  const [error, setError] = useState<string>("");

  const aiPlayer = humanPlayer === "X" ? "O" : "X";

  const resetGame = useCallback((selectedHuman?: "X" | "O") => {
    const player = selectedHuman ?? humanPlayer;
    setBoard(Array(9).fill(""));
    setWinner("");
    setWinLine(null);
    setError("");
    setCurrentTurn("X");

    if (player === "O") {
      // AI goes first as X
      setStatus("playing");
      setIsAiThinking(true);
      requestAiMove(Array(9).fill(""), "X").then(
        ({ newBoard, win, draw, line }) => {
          setBoard(newBoard);
          setIsAiThinking(false);
          if (win) {
            setWinner(win);
            setWinLine(line);
            setStatus("won");
          } else if (draw) {
            setStatus("draw");
          } else {
            setCurrentTurn("O");
          }
        }
      );
    } else {
      setStatus("playing");
      setCurrentTurn("X");
    }
  }, [humanPlayer]);

  async function handleCellClick(index: number) {
    if (
      status !== "playing" ||
      board[index] !== "" ||
      isAiThinking ||
      currentTurn !== humanPlayer
    )
      return;

    setError("");

    // Apply human move
    const newBoard = [...board] as Cell[];
    newBoard[index] = humanPlayer;
    setBoard(newBoard);

    // Check if human won
    const humanWinLine = getWinLine(newBoard);
    if (humanWinLine) {
      setWinner(humanPlayer);
      setWinLine(humanWinLine);
      setStatus("won");
      return;
    }

    // Check draw
    if (newBoard.every((c) => c !== "")) {
      setStatus("draw");
      return;
    }

    // AI's turn
    setIsAiThinking(true);
    setCurrentTurn(aiPlayer);

    try {
      const { newBoard: aiBoard, win, draw, line } = await requestAiMove(
        newBoard,
        aiPlayer
      );
      setBoard(aiBoard);
      setIsAiThinking(false);

      if (win) {
        setWinner(win);
        setWinLine(line);
        setStatus("won");
      } else if (draw) {
        setStatus("draw");
      } else {
        setCurrentTurn(humanPlayer);
      }
    } catch (e) {
      setIsAiThinking(false);
      setCurrentTurn(humanPlayer);
      setError(
        "Could not reach the Julia backend. Make sure it is running on port 8080."
      );
    }
  }

  function selectPlayer(player: "X" | "O") {
    setHumanPlayer(player);
    resetGame(player);
  }

  const statusText = () => {
    if (status === "selecting") return "Choose your symbol to start";
    if (status === "won") {
      return winner === humanPlayer
        ? "🎉 You win!"
        : "🤖 AI wins!";
    }
    if (status === "draw") return "🤝 It's a draw!";
    if (isAiThinking) return "🤔 AI is thinking…";
    return currentTurn === humanPlayer ? "Your turn" : "AI's turn";
  };

  return (
    <div className="flex flex-col items-center gap-8 w-full max-w-sm">
      {/* Title */}
      <div className="text-center">
        <h1 className="text-4xl font-bold text-indigo-700 dark:text-indigo-300">
          Tic-Tac-Toe
        </h1>
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
          Human vs AI (MCTS)
        </p>
      </div>

      {/* Player Selection */}
      <div className="flex gap-4">
        {(["X", "O"] as const).map((symbol) => (
          <button
            key={symbol}
            onClick={() => selectPlayer(symbol)}
            className={`w-20 h-16 rounded-xl text-2xl font-bold border-2 transition-all
              ${
                humanPlayer === symbol && status !== "selecting"
                  ? "bg-indigo-600 text-white border-indigo-600 shadow-lg scale-105"
                  : "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 border-gray-300 dark:border-gray-600 hover:border-indigo-400"
              }`}
          >
            {symbol}
          </button>
        ))}
      </div>
      <p className="text-xs text-gray-500 dark:text-gray-400 -mt-4">
        {status === "selecting"
          ? "Pick your symbol – X always goes first"
          : `You are playing as ${humanPlayer}  ·  AI plays as ${aiPlayer}`}
      </p>

      {/* Status */}
      <div
        className={`text-lg font-semibold transition-all
          ${status === "won" && winner === humanPlayer ? "text-green-600 dark:text-green-400" : ""}
          ${status === "won" && winner !== humanPlayer ? "text-red-500 dark:text-red-400" : ""}
          ${status === "draw" ? "text-yellow-600 dark:text-yellow-400" : ""}
          ${status === "playing" ? "text-indigo-700 dark:text-indigo-300" : ""}
          ${status === "selecting" ? "text-gray-500 dark:text-gray-400" : ""}
        `}
      >
        {statusText()}
      </div>

      {/* Board */}
      <div className="grid grid-cols-3 gap-3 bg-indigo-100 dark:bg-gray-700 p-3 rounded-2xl shadow-inner">
        {board.map((cell, i) => {
          const isWinCell = winLine?.includes(i);
          return (
            <button
              key={i}
              onClick={() => handleCellClick(i)}
              disabled={
                cell !== "" ||
                status !== "playing" ||
                isAiThinking ||
                currentTurn !== humanPlayer
              }
              className={`w-24 h-24 rounded-xl text-4xl font-bold transition-all
                flex items-center justify-center select-none
                ${isWinCell ? "bg-yellow-200 dark:bg-yellow-700 scale-105" : "bg-white dark:bg-gray-800"}
                ${
                  cell === ""
                    ? "hover:bg-indigo-50 dark:hover:bg-gray-600 cursor-pointer active:scale-95"
                    : "cursor-default"
                }
                ${cell === "X" ? "text-indigo-600 dark:text-indigo-300" : "text-rose-500 dark:text-rose-400"}
                shadow-md
              `}
            >
              {cell}
            </button>
          );
        })}
      </div>

      {/* Error */}
      {error && (
        <p className="text-sm text-red-500 text-center max-w-xs">{error}</p>
      )}

      {/* New Game button */}
      {status !== "selecting" && (
        <button
          onClick={() => resetGame()}
          className="px-6 py-2 rounded-full bg-indigo-600 text-white font-semibold hover:bg-indigo-700 active:scale-95 transition-all shadow"
        >
          New Game
        </button>
      )}
    </div>
  );
}
