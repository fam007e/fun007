# BuffonsNeedle

**Monte Carlo Simulation of Buffon's Needle Experiment**

A Python implementation of the classic Buffon's Needle probability experiment that estimates the value of π using Monte Carlo methods with seeded random number generators for reproducibility.

## Features

- 🎯 Monte Carlo π estimation via needle drop simulation
- 🔀 Multiple RNG support (PCG64, MT19937, Philox, SFC64)
- 📊 Convergence visualization with error analysis
- 🔁 Reproducible results with seed control

## Mathematical Background

Buffon's Needle: If a needle of length `L` is dropped on parallel lines spaced `D` apart, the probability of crossing is:

```
P = 2L / (πD)
```

Rearranging: `π ≈ 2L / (P × D)`

## Usage

```bash
python buffonrun.py
```

## Output

- Console: π estimates at various sample sizes, RNG comparisons
- Plot: Convergence graph showing how estimate approaches true π

## Requirements

```bash
pip install numpy matplotlib
```

## License

MIT License
