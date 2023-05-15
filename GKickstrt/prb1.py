def check_collisions(mapping, words):
    encodings = set()
    for word in words:
        encoding = ""
        for char in word:
            encoding += str(mapping[ord(char) - ord('A')])
        if encoding in encodings:
            return True
        encodings.add(encoding)
    return False

def solve_test_case(test_case):
    mapping = list(map(int, ''.join(test_case[0]).split()))
    num_words = int(test_case[1])
    words = test_case[2]
    
    collision = check_collisions(mapping, words)
    return "YES" if collision else "NO"

# Read input
num_test_cases = int(input())

# Process each test case
for case in range(1, num_test_cases + 1):
    mapping = list(input().strip())
    num_words = int(input())
    words = []
    for _ in range(num_words):
        words.append(input())
    
    test_case = (mapping, num_words, words)
    result = solve_test_case(test_case)
    
    print(f"Case #{case}: {result}")
