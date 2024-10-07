#!/usr/bin/zsh

# Check if the destination is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <destination>"
    exit 1
fi

# Extract destination from the command-line argument
destination="$1"

# Define the range of MTU sizes to test
min_mtu=1400
max_mtu=1500
step=1

# Function to perform ping test for a specific MTU size
ping_with_mtu() {
    mtu=$1
    ping -M do -c 4 -s $((mtu - 28)) -W 1 -q $destination >/dev/null
    result=$?
    return $result
}

# Iterate over the range of MTU sizes and perform ping tests
optimized_mtu=0
for (( mtu = min_mtu; mtu <= max_mtu; mtu += step )); do
    ping_with_mtu $mtu
    if [ $? -ne 0 ]; then
        optimized_mtu=$((mtu - step))
        break
    fi
done

# Only display the optimized MTU size once it's found
echo $optimized_mtu

