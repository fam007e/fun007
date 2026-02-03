# PI

**High-Performance Parallel π Estimation**

A multi-processed Monte Carlo simulation that estimates the value of π using Python's `multiprocessing` module for parallel computation across CPU cores.

## How It Works

Uses the inscribed circle method:
1. Generate random (x, y) points in a unit square
2. Count points falling inside the unit circle (x² + y² ≤ 1)
3. Ratio × 4 ≈ π

## Usage

```bash
python PI.py
```

You will be prompted for:
- Number of CPU cores to use
- Total number of iterations (e.g., `1e6` for 1 million)

## Example

```
Number of cores for simulations: 4
Number of iterations: 1000000
Estimated Pi: 3.141624
Time taken: 0.856 seconds
```

## Requirements

- Python 3.x (uses built-in `multiprocessing`, `random`, `math`)

## License

MIT License
