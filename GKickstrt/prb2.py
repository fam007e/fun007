def install_lightbulbs(M, R, street_lights):
    count = 0
    i = 0

    while i < len(street_lights):
        # Find the right-most street light that can be covered by the current lightbulb
        j = i
        while j < len(street_lights) and street_lights[j] - street_lights[i] <= R:
            j += 1

        # If the right-most street light is not covered, move to the previous one
        j -= 1

        # If no street light is covered by the current lightbulb, it is impossible to illuminate the whole freeway
        if street_lights[j] - street_lights[i] <= R:
            return "IMPOSSIBLE"

        # Install a lightbulb at the current street light
        count += 1

        # Move to the next uncovered street light
        i = j + 1

    return count


# Read input
T = int(input())

# Process each test case
for case in range(1, T + 1):
    M, R, N = map(int, input().split())
    street_lights = list(map(int, input().split()))

    # Solve the test case
    result = install_lightbulbs(M, R, street_lights)

    # Print the result
    print(f"Case #{case}: {result}")
