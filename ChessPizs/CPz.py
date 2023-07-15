def generate_possible_moves(piece, start_row, start_col):
    moves = []

    # Convert column index to alphabetical label
    columns = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
    start_col_label = columns[start_col]

    # Check for each piece type
    if piece == "rook":
        # Horizontal moves
        for col in columns:
            if col != start_col_label:
                moves.append((start_row, col))
        
        # Vertical moves
        for row in range(1, 9):
            if row != start_row:
                moves.append((row, start_col_label))
        
    elif piece == "bishop":
        # Diagonal moves
        for i in range(1, 8):
            if start_row + i < 9 and start_col + i < 8:
                moves.append((start_row + i, columns[start_col + i]))
            if start_row - i > 0 and start_col + i < 8:
                moves.append((start_row - i, columns[start_col + i]))
            if start_row + i < 9 and start_col - i >= 0:
                moves.append((start_row + i, columns[start_col - i]))
            if start_row - i > 0 and start_col - i >= 0:
                moves.append((start_row - i, columns[start_col - i]))
    
    elif piece == "knight":
        # Knight moves
        offsets = [(2, 1), (1, 2), (-1, 2), (-2, 1), (-2, -1), (-1, -2), (1, -2), (2, -1)]
        for offset in offsets:
            new_row = start_row + offset[0]
            new_col = start_col + offset[1]
            if 1 <= new_row < 9 and 0 <= new_col < 8:
                moves.append((new_row, columns[new_col]))
    
    # Add more elif statements for other piece types (e.g., queen, king, etc.)

    return moves

rook = "rook"
start_col = 1  # column index
print(generate_possible_moves(rook, 1, start_col))
