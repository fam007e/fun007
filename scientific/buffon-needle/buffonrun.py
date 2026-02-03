"""
Buffon's Needle Monte Carlo Simulation.

This module implements the classic Buffon's Needle experiment using Monte Carlo
methods with seeded random number generators for reproducibility.
"""

import numpy as np
import matplotlib.pyplot as plt
from numpy.random import Generator, PCG64, MT19937, Philox, SFC64


def buffon_needle_monte_carlo(
    num_samples=100000, needle_length=1.0, line_spacing=1.0, seed=42, rng_type="PCG64"
):
    """
    Monte Carlo simulation of Buffon's Needle experiment with seeded RNG.

    Parameters:
    - num_samples: number of Monte Carlo samples (needle drops)
    - needle_length: length of the needle (L)
    - line_spacing: distance between parallel lines (D)
    - seed: seed value for reproducibility
    - rng_type: type of random number generator
                ('PCG64', 'MT19937', 'Philox', 'SFC64')

    Returns:
    - crossings: number of times needle crosses a line
    - probability: estimated probability of crossing
    - pi_estimate: estimated value of π
    """

    # Initialize the random number generator with seed
    if rng_type == "PCG64":
        bit_generator = PCG64(seed)  # Default, fast and high-quality
    elif rng_type == "MT19937":
        bit_generator = MT19937(seed)  # Mersenne Twister (classic)
    elif rng_type == "Philox":
        bit_generator = Philox(seed)  # Counter-based, good for parallel
    elif rng_type == "SFC64":
        bit_generator = SFC64(seed)  # Very fast
    else:
        raise ValueError(f"Unknown RNG type: {rng_type}")

    rng = Generator(bit_generator)

    # Monte Carlo simulation: generate random samples
    # Sample 1: Position of needle center (uniform distribution)
    center_y = rng.uniform(0, line_spacing / 2, size=num_samples)

    # Sample 2: Angle of needle orientation (uniform distribution)
    angles = rng.uniform(0, np.pi, size=num_samples)

    # Vectorized crossing condition check
    # Needle crosses if: center_y <= (needle_length/2) * sin(angle)
    crosses = center_y <= (needle_length / 2) * np.sin(angles)

    # Count crossings
    num_crossings = np.sum(crosses)

    # Calculate probability (Monte Carlo estimate)
    cross_probability = num_crossings / num_samples

    # Estimate π using the formula: P = 2L / (πD)
    # Rearranging: π ≈ 2L / (P * D)
    if cross_probability > 0:
        estimated_pi = (2 * needle_length) / (cross_probability * line_spacing)
    else:
        estimated_pi = None

    return num_crossings, cross_probability, estimated_pi


def convergence_analysis(max_samples=1000000, seed=42, rng_type="PCG64"):
    """
    Analyze how the π estimate converges as we increase number of drops.

    Parameters:
    - max_samples: maximum number of samples to generate
    - seed: random seed for reproducibility
    - rng_type: type of random number generator

    Returns:
    - sample_counts: array of sample counts
    - pi_estimates: array of π estimates at each count
    """
    # Initialize RNG
    if rng_type == "PCG64":
        bit_generator = PCG64(seed)
    elif rng_type == "MT19937":
        bit_generator = MT19937(seed)
    elif rng_type == "Philox":
        bit_generator = Philox(seed)
    elif rng_type == "SFC64":
        bit_generator = SFC64(seed)
    else:
        bit_generator = PCG64(seed)

    rng = Generator(bit_generator)

    # Generate all samples at once
    center_y = rng.uniform(0, 0.5, size=max_samples)
    angles = rng.uniform(0, np.pi, size=max_samples)
    crosses = center_y <= 0.5 * np.sin(angles)

    # Calculate cumulative estimates
    sample_counts = np.arange(1, max_samples + 1)
    cumulative_crossings = np.cumsum(crosses)
    cumulative_probability = cumulative_crossings / sample_counts

    # Avoid division by zero
    cumulative_probability[cumulative_probability == 0] = np.nan
    pi_estimates = 2 / cumulative_probability

    return sample_counts, pi_estimates


def visualize_convergence(max_samples=100000, seed=42):
    """
    Visualize how the Monte Carlo estimate converges to π.

    Parameters:
    - max_samples: maximum number of samples to analyze
    - seed: random seed for reproducibility
    """
    sample_counts, pi_estimates = convergence_analysis(max_samples, seed)

    _, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))

    # Plot 1: Convergence to π
    ax1.plot(
        sample_counts,
        pi_estimates,
        linewidth=0.5,
        alpha=0.7,
        label="Monte Carlo estimate",
    )
    ax1.axhline(
        y=np.pi, color="red", linestyle="--", linewidth=2, label=f"True π = {np.pi:.6f}"
    )
    ax1.fill_between(
        sample_counts,
        np.pi - 0.1,
        np.pi + 0.1,
        alpha=0.2,
        color="red",
        label="±0.1 error band",
    )
    ax1.set_xscale("log")
    ax1.set_xlabel("Number of needle drops (log scale)", fontsize=12)
    ax1.set_ylabel("Estimated value of π", fontsize=12)
    ax1.set_title(
        "Buffon's Needle: Monte Carlo Convergence to π", fontsize=14, fontweight="bold"
    )
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim([2.5, 4.0])

    # Plot 2: Error over time
    errors = np.abs(pi_estimates - np.pi)
    ax2.plot(sample_counts, errors, linewidth=0.5, alpha=0.7, color="orange")
    ax2.set_xscale("log")
    ax2.set_yscale("log")
    ax2.set_xlabel("Number of needle drops (log scale)", fontsize=12)
    ax2.set_ylabel("Absolute error |estimate - π|", fontsize=12)
    ax2.set_title(
        "Convergence Error (decreases as ~1/√n)", fontsize=14, fontweight="bold"
    )
    ax2.grid(True, alpha=0.3, which="both")

    plt.tight_layout()
    plt.show()


def compare_rng_types(num_samples=100000, seed=42):
    """
    Compare different RNG types to show reproducibility.

    Parameters:
    - num_samples: number of samples for each RNG type
    - seed: random seed for reproducibility
    """
    rng_types = ["PCG64", "MT19937", "Philox", "SFC64"]

    print("\n" + "=" * 70)
    print("COMPARING DIFFERENT RANDOM NUMBER GENERATORS")
    print("=" * 70)

    for rng_type in rng_types:
        num_crossings, cross_prob, estimated_pi = buffon_needle_monte_carlo(
            num_samples=num_samples, seed=seed, rng_type=rng_type
        )

        print(f"\nRNG Type: {rng_type}")
        print(f"  Seed: {seed}")
        print(f"  Drops: {num_samples:,}")
        print(f"  Crossings: {num_crossings:,}")
        print(f"  Probability: {cross_prob:.6f}")
        print(f"  Estimated π: {estimated_pi:.6f}")
        print(f"  Error: {abs(estimated_pi - np.pi):.6f}")

    # Show reproducibility - run same config twice
    print("\n" + "=" * 70)
    print("TESTING REPRODUCIBILITY (Same seed should give same results)")
    print("=" * 70)

    for run in range(1, 3):
        _, _, estimated_pi = buffon_needle_monte_carlo(
            num_samples=10000, seed=42, rng_type="PCG64"
        )
        print(f"\nRun {run} (seed=42, PCG64):")
        print(f"  Estimated π: {estimated_pi:.10f}")


def main():
    """Main execution function."""
    print("=" * 70)
    print("BUFFON'S NEEDLE - MONTE CARLO SIMULATION WITH SEEDED RNG")
    print("=" * 70)

    # Single simulation with seed
    print("\n1. Running Monte Carlo simulation with seed=42...")
    result_crossings, result_prob, result_pi = buffon_needle_monte_carlo(
        num_samples=1000000, seed=42, rng_type="PCG64"
    )

    print("\nResults:")
    print("  Number of drops: 1,000,000")
    print(f"  Crossings: {result_crossings:,}")
    print(f"  Probability: {result_prob:.6f} (theoretical: {2 / np.pi:.6f})")
    print(f"  Estimated π: {result_pi:.8f}")
    print(f"  Actual π: {np.pi:.8f}")
    print(f"  Error: {abs(result_pi - np.pi):.8f}")
    print(f"  Relative error: {abs(result_pi - np.pi) / np.pi * 100:.4f}%")

    # Compare different sample sizes
    print("\n" + "=" * 70)
    print("2. Monte Carlo convergence with increasing samples...")
    print("=" * 70)

    for samples in [100, 1000, 10000, 100000, 1000000]:
        _, _, est_pi = buffon_needle_monte_carlo(
            num_samples=samples, seed=123, rng_type="PCG64"
        )
        error = abs(est_pi - np.pi)
        print(f"\n  {samples:>7,} drops → π ≈ {est_pi:.6f} (error: {error:.6f})")

    # Compare RNG types
    compare_rng_types(num_samples=100000, seed=42)

    # Visualize convergence
    print("\n" + "=" * 70)
    print("3. Generating convergence visualization...")
    print("=" * 70)
    visualize_convergence(max_samples=100000, seed=42)


if __name__ == "__main__":
    main()
