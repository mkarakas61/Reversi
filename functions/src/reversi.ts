// Server-side Reversi rules — a TypeScript port of lib/game/reversi_game.dart,
// used to replay and validate an online game's move log (REV-49) so the
// end-of-game reward function (REV-50) never trusts a client-reported result.
// Keep the flip / pass / scoring logic in sync with the Dart engine.

/** A disc colour, matching the board codec used in Firestore ("b" / "w"). */
export type Disc = "b" | "w";
export type Cell = Disc | null;

/** 64 cells, row-major: index = row * 8 + col. */
export type Board = Cell[];

export const SIZE = 8;

/** One replayed placement: the cell and the colour of the side that moved. */
export interface ReplayMove {
  row: number;
  col: number;
  by: Disc;
}

export interface ReplayResult {
  /** True when every move was legal and made by the side whose turn it was. */
  valid: boolean;
  invalidReason?: string;
  /** True when, after the last move, neither side has a legal move. */
  naturallyOver: boolean;
  /** Final disc counts. */
  black: number;
  white: number;
  /** Winner by disc count, or null for a draw. Only meaningful if over. */
  winner: Disc | null;
  /** Discs captured by each colour across the whole game. */
  flippedBy: { b: number; w: number };
}

const DIRECTIONS: ReadonlyArray<readonly [number, number]> = [
  [-1, -1],
  [-1, 0],
  [-1, 1],
  [0, -1],
  [0, 1],
  [1, -1],
  [1, 0],
  [1, 1],
];

function opponentOf(player: Disc): Disc {
  return player === "b" ? "w" : "b";
}

function onBoard(row: number, col: number): boolean {
  return row >= 0 && row < SIZE && col >= 0 && col < SIZE;
}

/** The standard opening position. */
export function initialBoard(): Board {
  const board: Board = new Array<Cell>(SIZE * SIZE).fill(null);
  board[3 * SIZE + 3] = "w";
  board[3 * SIZE + 4] = "b";
  board[4 * SIZE + 3] = "b";
  board[4 * SIZE + 4] = "w";
  return board;
}

/**
 * Indices that would flip if [player] placed a disc at (row, col); empty when
 * the move is illegal (off board, occupied, or capturing nothing).
 */
export function flipsFor(
  board: Board,
  row: number,
  col: number,
  player: Disc
): number[] {
  if (!onBoard(row, col) || board[row * SIZE + col] !== null) return [];
  const opp = opponentOf(player);
  const flips: number[] = [];
  for (const [dr, dc] of DIRECTIONS) {
    const line: number[] = [];
    let r = row + dr;
    let c = col + dc;
    while (onBoard(r, c) && board[r * SIZE + c] === opp) {
      line.push(r * SIZE + c);
      r += dr;
      c += dc;
    }
    if (line.length > 0 && onBoard(r, c) && board[r * SIZE + c] === player) {
      flips.push(...line);
    }
  }
  return flips;
}

/** Whether [player] has at least one legal move on [board]. */
export function hasAnyMove(board: Board, player: Disc): boolean {
  for (let row = 0; row < SIZE; row++) {
    for (let col = 0; col < SIZE; col++) {
      if (flipsFor(board, row, col, player).length > 0) return true;
    }
  }
  return false;
}

/** Disc count for [player]. */
export function countDiscs(board: Board, player: Disc): number {
  let total = 0;
  for (const cell of board) {
    if (cell === player) total++;
  }
  return total;
}

function fail(
  board: Board,
  reason: string,
  flippedBy: { b: number; w: number }
): ReplayResult {
  return {
    valid: false,
    invalidReason: reason,
    naturallyOver: false,
    black: countDiscs(board, "b"),
    white: countDiscs(board, "w"),
    winner: null,
    flippedBy,
  };
}

/**
 * Replays [moves] from the opening position, validating that each is legal and
 * played by the side to move (honouring the pass rule). Returns the final score
 * and per-colour capture totals, or `valid: false` on the first illegal move.
 */
export function replay(moves: ReplayMove[]): ReplayResult {
  const board = initialBoard();
  let current: Disc = "b";
  const flippedBy = { b: 0, w: 0 };

  for (let i = 0; i < moves.length; i++) {
    const move = moves[i];
    if (move.by !== current) {
      return fail(board, `move ${i}: ${move.by} moved out of turn`, flippedBy);
    }
    const flips = flipsFor(board, move.row, move.col, current);
    if (flips.length === 0) {
      return fail(board, `move ${i}: illegal placement`, flippedBy);
    }

    board[move.row * SIZE + move.col] = current;
    for (const idx of flips) board[idx] = current;
    flippedBy[current] += flips.length;

    // Advance the turn, applying the forced-pass rule.
    const next = opponentOf(current);
    if (hasAnyMove(board, next)) {
      current = next;
    } else if (hasAnyMove(board, current)) {
      // Opponent has no reply and is skipped; the same player moves again.
    } else if (i !== moves.length - 1) {
      // Neither side can move (game over) yet the log continues — tampered.
      return fail(board, `move ${i}: play continued after game over`, flippedBy);
    }
  }

  const black = countDiscs(board, "b");
  const white = countDiscs(board, "w");
  const naturallyOver = !hasAnyMove(board, "b") && !hasAnyMove(board, "w");
  const winner: Disc | null =
    black === white ? null : black > white ? "b" : "w";
  return { valid: true, naturallyOver, black, white, winner, flippedBy };
}
