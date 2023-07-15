import numpy as np






def generate_possible_moves(piece, piece_color, start_row, start_col, own_team, opponent_team):
    """
    Generates possible positions a chess piece can move based on its starting position.

    Args:
        piece (str): The type of chess piece (e.g., "rook", "bishop", "knight", "queen", "king", "pawn").
        piece_color (str): The color of the piece ("white" or "black").
        start_row (int): The starting row of the piece (1 to 8).
        start_col (str): The starting column of the piece (A to H).
        own_team (list): List of positions occupied by the pieces of the same team.
        opponent_team (list): List of positions occupied by the pieces of the opponent's team.

    Returns:
        list: List of possible positions the piece can move to.

    """

    # Convert column index to alphabetical label
    columns = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
    start_col_label = columns.index(start_col)

    # Initialize the list of possible moves
    moves = []

    # Check for each piece type
    if piece == "rook":
        # Rook movement implementation goes here...
        moves = []

        # Horizontal moves
        for col in columns:
            if col != start_col_label:
                new_position = (start_row, col)
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                        break
                    moves.append(new_position)

        # Vertical moves
        for row in range(1, 9):
            if row != start_row:
                new_position = (row, start_col_label)
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                        break
                    moves.append(new_position)

    elif piece == "bishop":
        # Bishop movement implementation goes here...
        moves = []

        # Diagonal moves
        directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        for direction in directions:
            d_row, d_col = direction
            new_row = start_row + d_row
            new_col = start_col + d_col
            while 1 <= new_row <= 8 and 0 <= new_col < 8:
                new_position = (new_row, columns[new_col])
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                        break
                    moves.append(new_position)
                    if new_position in opponent_team:
                        break
                else:
                    break
                new_row += d_row
                new_col += d_col

    elif piece == "knight":
        # Knight movement implementation goes here...
        moves = []

        # Knight moves
        offsets = [(2, 1), (1, 2), (-1, 2), (-2, 1), (-2, -1), (-1, -2), (1, -2), (2, -1)]
        for offset in offsets:
            d_row, d_col = offset
            new_row = start_row + d_row
            new_col_index = start_col + d_col
            if 1 <= new_row <= 8 and 0 <= new_col_index < 8:
                new_col_label = columns[new_col_index]
                new_position = (new_row, new_col_label)
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                    else:
                        moves.append(new_position)

    elif piece == "queen":
        # Queen movement implementation goes here...
        moves = []

        # Diagonal moves
        directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        for direction in directions:
            d_row, d_col = direction
            new_row = start_row + d_row
            new_col = start_col + d_col
            while 1 <= new_row <= 8 and 0 <= new_col < 8:
                new_position = (new_row, columns[new_col])
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                        break
                    moves.append(new_position)
                else:
                    break
                new_row += d_row
                new_col += d_col

        # Horizontal moves
        for col in columns:
            if col != start_col_label:
                new_position = (start_row, col)
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                        break
                    moves.append(new_position)

        # Vertical moves
        for row in range(1, 9):
            if row != start_row:
                new_position = (row, start_col_label)
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                        break
                    moves.append(new_position)

    elif piece == "king":
        # King movement implementation goes here...
        moves = []

        # King moves
        offsets = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        for offset in offsets:
            d_row, d_col = offset
            new_row = start_row + d_row
            new_col_index = start_col + d_col
            if 1 <= new_row <= 8 and 0 <= new_col_index < 8:
                new_col_label = columns[new_col_index]
                new_position = (new_row, new_col_label)
                if new_position not in own_team:
                    if new_position in opponent_team:
                        moves.append(new_position)
                    else:
                        moves.append(new_position)

    elif piece == "pawn":
        # Pawn movement implementation goes here...
        moves = []

        # Determine the direction of movement based on the pawn's color
        if piece_color == "white":
            direction = 1  # Pawns move forward by increasing the row index
        else:
            direction = -1  # Pawns move forward by decreasing the row index

        # Check for the forward movement
        new_row = start_row + direction
        new_position = (new_row, start_col_label)
        if new_position not in own_team and new_position not in opponent_team:
            moves.append(new_position)

        # Check for the initial double-step forward movement
        if (
            (piece_color == "white" and start_row == 2)
            or (piece_color == "black" and start_row == 7)
        ):
            new_row = start_row + 2 * direction
            new_position = (new_row, start_col_label)
            if new_position not in own_team and new_position not in opponent_team:
                moves.append(new_position)

        # Check for capturing diagonally
        diagonal_offsets = [-1, 1]  # Diagonal column offsets
        for offset in diagonal_offsets:
            new_col_index = start_col_label + offset
            if 0 <= new_col_index < 8:
                new_col_label = columns[new_col_index]
                new_position = (start_row + direction, new_col_label)
                if new_position in opponent_team:
                    moves.append(new_position)

    return moves
