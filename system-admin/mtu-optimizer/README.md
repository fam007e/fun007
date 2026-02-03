# MTU_size_optimiser

**Network MTU Optimizer**

A shell script to determine the optimal Maximum Transmission Unit (MTU) size for your network connection by testing packet fragmentation.

## What is MTU?

MTU is the maximum packet size that can be transmitted without fragmentation. Setting the correct MTU improves network throughput and reduces latency.

## Usage

```bash
./mtu_optimizer.sh <destination>
```

### Example

```bash
./mtu_optimizer.sh google.com
# Output: 1472
```

## How It Works

1. Tests MTU sizes from 1400 to 1500 bytes
2. Uses `ping -M do` (don't fragment) to detect fragmentation
3. Returns the largest working MTU size

## Apply the Result

```bash
# Linux
sudo ip link set dev eth0 mtu <optimized_mtu>
```

## Requirements

- Linux/macOS with `ping` supporting `-M do` flag
- Zsh shell

## License

MIT License
