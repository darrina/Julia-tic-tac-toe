# Julia Tic-Tac-Toe

A Tic-Tac-Toe game where a human can challenge an AI as either X's or O's.

- **Frontend**: [Next.js](https://nextjs.org/) (TypeScript + Tailwind CSS)
- **Backend**: [Julia](https://julialang.org/) HTTP game engine with an **MCTS** (Monte Carlo Tree Search) AI

## Screenshot

![Tic-Tac-Toe vs AI](https://github.com/user-attachments/assets/7f617271-bc12-4deb-a6c0-d8501afb32ba)

## Project Structure

```
.
├── backend/          # Julia game engine
│   ├── Project.toml
│   ├── run.jl
│   ├── src/
│   │   ├── TicTacToeBackend.jl
│   │   ├── game.jl     # game logic (board, win detection)
│   │   ├── mcts.jl     # Monte Carlo Tree Search AI
│   │   └── server.jl   # HTTP API server (port 8080)
│   └── test/
│       └── runtests.jl
└── frontend/         # Next.js application (port 3000)
    ├── app/
    │   ├── components/
    │   │   └── TicTacToe.tsx
    │   ├── layout.tsx
    │   └── page.tsx
    └── ...
```

## How to Run

### 1. Start the Julia backend

```bash
cd backend
julia run.jl
```

The API will be available at `http://localhost:8080`.

### 2. Start the Next.js frontend

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Gameplay

1. Click **X** or **O** to choose your symbol (X always goes first).
2. Click any empty cell to place your move.
3. The Julia AI responds using MCTS (1000 iterations) to choose its move.
4. Win lines are highlighted in yellow; result is shown above the board.
5. Click **New Game** to start again.

## API Endpoints

### `POST /ai-move`

Request the AI to make a move given the current board state.

**Request body:**
```json
{
  "board": ["X", "", "O", "", "X", "", "", "", ""],
  "aiPlayer": "O"
}
```

**Response:**
```json
{
  "board": ["X", "", "O", "", "X", "", "", "O", ""],
  "winner": "",
  "draw": false,
  "move": 8
}
```

### `POST /check-state`

Check the current winner/draw state without making a move.

**Request body:**
```json
{ "board": ["X", "X", "X", "O", "O", "", "", "", ""] }
```

**Response:**
```json
{ "winner": "X", "draw": false, "validMoves": [] }
```

## Running Tests

```bash
cd backend
julia --project=. test/runtests.jl
```
