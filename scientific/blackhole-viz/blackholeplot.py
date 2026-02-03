"""
Scientifically Accurate Black Hole Spacetime Visualizations
Based on General Relativity and Modern Understanding

This script implements visualizations grounded in the actual physics of black holes,
including proper coordinate systems, Penrose diagrams, and realistic representations
of spacetime geometry around Schwarzschild and Kerr black holes.

Key Physics Concepts:
- Event horizons are coordinate singularities, not physical ones
- Infalling objects appear frozen from outside but pass through normally
- The maximal extension reveals white holes and parallel universes (mathematical)
- Rotating black holes have ergospheres and ring singularities
- Traversable wormholes require exotic matter (likely impossible)

References:
- Schwarzschild (1916) - First exact solution
- Kruskal & Szekeres (1960) - Non-singular coordinates
- Penrose (1964) - Conformal diagrams
- Kerr (1963) - Rotating black hole solution
- Morris & Thorne (1988) - Traversable wormholes

Usage:
    python blackhole_accurate.py          # Generate all plots (saves to files)
    python blackhole_accurate.py --show   # Display plots interactively
"""

import argparse
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# Physical constants (geometrized units: G=M=c=1)
RS = 2.0  # Schwarzschild radius: r_s = 2GM/c²
R_ISCO = 6.0  # Innermost stable circular orbit (for non-rotating BH)


def plot_light_cone_tilting(save_path=None):
    """
    Light Cone Tilting Near Event Horizon

    Physics: In Schwarzschild coordinates, as you approach r=2M, the metric
    coefficient (1-2M/r) approaches zero. This causes light cones to "tilt"
    inward. At the horizon, the future light cone points entirely inward.
    Inside the horizon, even outgoing light rays move toward r=0.

    This demonstrates why nothing can escape once inside the event horizon.
    """
    fig, ax = plt.subplots(figsize=(12, 8))

    radii = [10, 6, 4, 3, 2.5, 2.1, 2.01]
    colors = plt.cm.plasma(np.linspace(0, 0.9, len(radii)))

    for i, r in enumerate(radii):
        if r > RS:
            tilt_factor = np.sqrt(1 - RS / r)
            t_base = (10 - r) * 2

            cone_half_angle = 1.0
            right_ray = cone_half_angle * tilt_factor
            left_ray = cone_half_angle / (tilt_factor + 0.1)

            t_range = np.linspace(0, 3, 20)
            ax.plot(
                r + right_ray * t_range,
                t_base + t_range,
                color=colors[i],
                linewidth=2,
                alpha=0.8,
            )
            ax.plot(
                r - left_ray * t_range,
                t_base + t_range,
                color=colors[i],
                linewidth=2,
                alpha=0.8,
            )

            if r in [10, 4, 2.5]:
                ax.text(
                    r,
                    t_base - 0.5,
                    f"r={r:.1f}M",
                    ha="center",
                    fontsize=9,
                    color=colors[i],
                )

    ax.axvline(
        RS, color="black", linewidth=3, linestyle="--", label="Event Horizon (r=2M)"
    )
    ax.fill_betweenx([0, 20], 0, RS, alpha=0.2, color="black")
    ax.axvline(0, color="red", linewidth=2, label="Singularity (r=0)")

    ax.set_xlabel("Radial Coordinate r (Schwarzschild)", fontsize=12)
    ax.set_ylabel("Time Coordinate t", fontsize=12)
    ax.set_title(
        "Light Cone Tilting Near a Black Hole\n"
        + "Notice how cones narrow and tilt inward approaching the horizon",
        fontsize=14,
        fontweight="bold",
    )
    ax.set_xlim(-0.5, 12)
    ax.set_ylim(0, 20)
    ax.legend(fontsize=11)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def plot_penrose_schwarzschild(save_path=None):
    """
    Penrose Diagram of Maximally Extended Schwarzschild Black Hole

    Physics: The maximal extension of the Schwarzschild solution reveals:
    - Region I: Our universe (exterior)
    - Region II: Black hole interior (future singularity)
    - Region III: Parallel universe (second exterior)
    - Region IV: White hole interior (past singularity)

    The Einstein-Rosen bridge connects the two universes at the moment
    where they share a common spacelike slice, but pinches off too quickly
    for any signal to traverse it.
    """
    fig, ax = plt.subplots(figsize=(10, 10))

    future_sing = np.array([[0, 4], [-2, 2], [2, 2], [0, 4]])
    past_sing = np.array([[0, -4], [-2, -2], [2, -2], [0, -4]])
    region_I = np.array([[2, 2], [4, 0], [2, -2], [0, 0], [2, 2]])
    region_III = np.array([[-2, 2], [-4, 0], [-2, -2], [0, 0], [-2, 2]])

    ax.fill(
        future_sing[:, 0],
        future_sing[:, 1],
        color="red",
        alpha=0.3,
        label="Future Singularity (r=0)",
    )
    ax.fill(
        past_sing[:, 0],
        past_sing[:, 1],
        color="orange",
        alpha=0.3,
        label="Past Singularity (r=0)",
    )
    ax.fill(
        region_I[:, 0],
        region_I[:, 1],
        color="lightblue",
        alpha=0.4,
        label="Region I (Our Universe)",
    )
    ax.fill(
        region_III[:, 0],
        region_III[:, 1],
        color="lightgreen",
        alpha=0.4,
        label="Region III (Parallel Universe)",
    )

    ax.plot([0, 2], [0, 2], "k-", linewidth=3, label="Event Horizon")
    ax.plot([0, -2], [0, 2], "k-", linewidth=3)
    ax.plot([0, 2], [0, -2], "k--", linewidth=3, label="White Hole Horizon")
    ax.plot([0, -2], [0, -2], "k--", linewidth=3)

    ax.plot([2, 4, 2], [2, 0, -2], "b-", linewidth=2)
    ax.plot([-2, -4, -2], [2, 0, -2], "g-", linewidth=2)
    ax.plot(future_sing[:, 0], future_sing[:, 1], "r-", linewidth=3)
    ax.plot(past_sing[:, 0], past_sing[:, 1], "orange", linewidth=3)

    ax.annotate(
        "",
        xy=(1, 3),
        xytext=(2, 1),
        arrowprops=dict(arrowstyle="->", lw=2, color="blue", alpha=0.7),
    )
    ax.annotate(
        "",
        xy=(0.5, 3),
        xytext=(2, 1),
        arrowprops=dict(arrowstyle="->", lw=2, color="blue", alpha=0.7),
    )
    ax.annotate(
        "",
        xy=(2, 1),
        xytext=(1, -1),
        arrowprops=dict(arrowstyle="->", lw=2, color="orange", alpha=0.7),
    )

    ax.plot(
        [-2, 2], [0, 0], "purple", linewidth=4, alpha=0.6, label="Einstein-Rosen Bridge"
    )
    ax.plot(0, 0, "o", color="purple", markersize=10)

    ax.text(
        2.5,
        0,
        "I\n(Our\nUniverse)",
        ha="center",
        va="center",
        fontsize=14,
        fontweight="bold",
    )
    ax.text(
        -2.5,
        0,
        "III\n(Parallel\nUniverse)",
        ha="center",
        va="center",
        fontsize=14,
        fontweight="bold",
    )
    ax.text(
        0,
        3,
        "II (Black Hole)",
        ha="center",
        va="center",
        fontsize=12,
        fontweight="bold",
        color="darkred",
    )
    ax.text(
        0,
        -3,
        "IV (White Hole)",
        ha="center",
        va="center",
        fontsize=12,
        fontweight="bold",
        color="darkorange",
    )

    ax.text(4.2, 0, "i⁰\n(spatial\ninfinity)", ha="left", va="center", fontsize=10)
    ax.text(-4.2, 0, "i⁰\n(spatial\ninfinity)", ha="right", va="center", fontsize=10)
    ax.text(0, 4.3, "r=0 (Future)", ha="center", va="bottom", fontsize=10)
    ax.text(0, -4.3, "r=0 (Past)", ha="center", va="top", fontsize=10)

    ax.set_xlim(-5, 5)
    ax.set_ylim(-5, 5)
    ax.set_aspect("equal")
    ax.set_xlabel("Space", fontsize=12)
    ax.set_ylabel("Time", fontsize=12)
    ax.set_title(
        "Penrose Diagram: Maximally Extended Schwarzschild Black Hole\n"
        + "Light rays always travel at 45° in this representation",
        fontsize=14,
        fontweight="bold",
    )
    ax.legend(loc="upper left", fontsize=9)
    ax.grid(True, alpha=0.3)

    note = (
        "Note: The wormhole (Einstein-Rosen bridge) at t=0 pinches off\n"
        "too quickly for anything to traverse it. White holes and parallel\n"
        "universes are mathematical artifacts of the eternal solution."
    )
    ax.text(
        0,
        -5.5,
        note,
        ha="center",
        fontsize=9,
        style="italic",
        bbox=dict(boxstyle="round", facecolor="wheat", alpha=0.5),
    )

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def plot_eddington_finkelstein(save_path=None):
    """
    Eddington-Finkelstein Diagram

    Physics: These coordinates (v, r) eliminate the coordinate singularity
    at the event horizon, allowing us to see that infalling light rays
    smoothly cross r=2M. Here v = t + r* where r* is the "tortoise coordinate"
    that stretches near the horizon.

    Key insight: From outside, you never see anything cross. But the
    infalling object experiences finite proper time to reach the singularity.
    """
    fig, ax = plt.subplots(figsize=(10, 8))

    v_vals = np.linspace(-10, 20, 15)
    for v in v_vals:
        r = np.linspace(RS, 10, 100)
        ax.plot([v] * len(r), r, "b-", alpha=0.5, linewidth=1.5)

    for r0 in np.linspace(RS + 0.1, 10, 12):
        r = np.linspace(r0, 10, 100)
        v = -10 + r + 2 * RS * np.log(np.abs(r / RS - 1))
        ax.plot(v, r, "r-", alpha=0.5, linewidth=1.5)

    ax.axhline(
        RS, color="black", linewidth=3, linestyle="--", label=f"Event Horizon (r={RS}M)"
    )
    ax.fill_between([-15, 25], 0, RS, alpha=0.2, color="black")

    v_observer = np.linspace(0, 15, 100)
    r_observer = 8 - 0.4 * v_observer
    r_observer = np.maximum(r_observer, 0.1)
    ax.plot(
        v_observer, r_observer, "g-", linewidth=3, label="Infalling Observer", alpha=0.8
    )

    ax.axhline(0, color="red", linewidth=2, label="Singularity (r=0)")

    ax.set_xlabel("Eddington-Finkelstein Time Coordinate (v)", fontsize=12)
    ax.set_ylabel("Radial Coordinate (r)", fontsize=12)
    ax.set_title(
        "Eddington-Finkelstein Diagram\n"
        + "Coordinates that are well-behaved at the horizon",
        fontsize=14,
        fontweight="bold",
    )
    ax.set_xlim(-15, 25)
    ax.set_ylim(-0.5, 11)
    ax.legend(fontsize=11)
    ax.grid(True, alpha=0.3)

    ax.text(
        20,
        9,
        "Blue: Ingoing light\n(falls through horizon)",
        fontsize=10,
        bbox=dict(boxstyle="round", facecolor="lightblue", alpha=0.7),
    )
    ax.text(
        -8,
        9,
        "Red: Outgoing light\n(escapes to infinity)",
        fontsize=10,
        bbox=dict(boxstyle="round", facecolor="lightcoral", alpha=0.7),
    )

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def plot_waterfall(save_path=None):
    """
    Waterfall Model (Gullstrand-Painlevé Coordinates)

    Physics: In GP coordinates, space itself flows inward at velocity:
    v(r) = -√(2M/r)

    At r=2M: v = -c (space flows inward at light speed)
    Inside r<2M: |v| > c (space flows faster than light)

    This explains why nothing can escape: you'd need to swim faster than
    the current, but the current exceeds c inside the horizon.
    """
    fig, ax = plt.subplots(figsize=(10, 10))

    x = np.linspace(-8, 8, 20)
    y = np.linspace(-8, 8, 20)
    X, Y = np.meshgrid(x, y)

    R = np.sqrt(X**2 + Y**2) + 0.01
    V_magnitude = -np.sqrt(RS / R)
    Vx = V_magnitude * (-X / R)
    Vy = V_magnitude * (-Y / R)

    mask = R > 0.3
    speed = np.sqrt(Vx**2 + Vy**2)

    quiv = ax.quiver(
        X[mask],
        Y[mask],
        Vx[mask],
        Vy[mask],
        speed[mask],
        cmap="plasma",
        scale=15,
        width=0.004,
        headwidth=4,
        headlength=5,
        alpha=0.8,
    )

    horizon = plt.Circle(
        (0, 0),
        RS,
        color="black",
        fill=False,
        linewidth=3,
        linestyle="--",
        label="Event Horizon",
    )
    ax.add_patch(horizon)
    horizon_fill = plt.Circle((0, 0), RS, color="black", alpha=0.2)
    ax.add_patch(horizon_fill)

    ax.plot(0, 0, "r*", markersize=20, label="Singularity")

    isco = plt.Circle(
        (0, 0),
        R_ISCO,
        color="blue",
        fill=False,
        linewidth=2,
        linestyle=":",
        label="ISCO (r=6M)",
    )
    ax.add_patch(isco)

    cbar = plt.colorbar(quiv, ax=ax, label="Inflow Speed (c=1)")
    cbar.ax.axhline(y=1.0, color="white", linewidth=2, linestyle="--")
    cbar.ax.text(
        0.5,
        1.05,
        "v=c at horizon",
        color="white",
        fontsize=9,
        transform=cbar.ax.transAxes,
    )

    ax.set_xlim(-9, 9)
    ax.set_ylim(-9, 9)
    ax.set_aspect("equal")
    ax.set_xlabel("x (Schwarzschild radii)", fontsize=12)
    ax.set_ylabel("y (Schwarzschild radii)", fontsize=12)
    ax.set_title(
        "Waterfall Model: Space Flowing Into Black Hole\n"
        + "Based on Gullstrand-Painlevé coordinates",
        fontsize=14,
        fontweight="bold",
    )
    ax.legend(loc="upper right", fontsize=11)
    ax.grid(True, alpha=0.3)

    note = "Space flows inward at v = √(2M/r)\nAt horizon: v = c\nInside horizon: v > c"
    ax.text(
        0,
        -10,
        note,
        ha="center",
        fontsize=10,
        bbox=dict(boxstyle="round", facecolor="lightblue", alpha=0.7),
    )

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def plot_kerr_structure(save_path=None):
    """
    Kerr Black Hole Structure (Rotating)

    Physics: A rotating black hole has:
    - Outer horizon r+ = M + √(M² - a²) where a = J/M is spin parameter
    - Inner horizon r- = M - √(M² - a²)
    - Ring singularity at r=0, θ=π/2 (not a point!)
    - Ergosphere: region where space is dragged faster than light
    - Frame dragging: space rotates with angular velocity ω(r)

    Unlike Schwarzschild, you can avoid the singularity by passing
    through the ring. The interior contains exotic regions with
    negative mass and closed timelike curves (likely unphysical).
    """
    fig, ax = plt.subplots(figsize=(12, 8), subplot_kw=dict(projection="polar"))

    a = 0.9  # Near-extremal rotation

    r_plus = 1 + np.sqrt(1 - a**2)
    r_minus = 1 - np.sqrt(1 - a**2)

    theta = np.linspace(0, 2 * np.pi, 200)
    r_ergo = 1 + np.sqrt(1 - a**2 * np.cos(theta) ** 2)

    ax.fill_between(
        theta,
        r_plus,
        r_ergo,
        alpha=0.3,
        color="orange",
        label="Ergosphere (space dragged > c)",
    )
    ax.fill_between(
        theta, r_minus, r_plus, alpha=0.4, color="gray", label="Between horizons"
    )
    ax.fill_between(
        theta, 0, r_minus, alpha=0.3, color="purple", label="Exotic interior"
    )

    ax.plot(
        theta,
        [r_plus] * len(theta),
        "k-",
        linewidth=3,
        label=f"Outer Horizon (r₊={r_plus:.2f}M)",
    )
    ax.plot(
        theta,
        [r_minus] * len(theta),
        "k--",
        linewidth=2,
        label=f"Inner Horizon (r₋={r_minus:.2f}M)",
    )
    ax.plot(theta, r_ergo, "orange", linewidth=2.5, label="Ergosphere boundary")

    equator_angles = [0, np.pi]
    for angle in equator_angles:
        ax.plot(
            [angle, angle],
            [0, 0.1],
            "r-",
            linewidth=6,
            label="Ring singularity" if angle == 0 else "",
        )

    ax.plot(
        [np.pi / 2, np.pi / 2],
        [0, r_ergo[len(theta) // 4]],
        "b--",
        linewidth=2,
        alpha=0.6,
        label="Rotation axis",
    )
    ax.arrow(
        np.pi / 2,
        r_ergo[len(theta) // 4] * 0.7,
        0,
        0.3,
        head_width=0.2,
        head_length=0.2,
        fc="blue",
        ec="blue",
        lw=2,
    )

    ax.set_ylim(0, r_ergo.max() * 1.2)
    ax.set_title(
        f"Kerr Black Hole Structure (a={a})\n"
        + "Rotating black hole with ergosphere and ring singularity",
        fontsize=14,
        fontweight="bold",
        pad=20,
    )
    ax.legend(loc="upper left", bbox_to_anchor=(1.15, 1.0), fontsize=10)

    note_text = (
        f"Spin parameter a = {a}\n"
        f"a=0: Schwarzschild (not rotating)\n"
        f"a=1: Extremal Kerr (maximum rotation)\n\n"
        f"Inside ergosphere: frame dragging\n"
        f"forces everything to rotate"
    )
    ax.text(
        1.15,
        0.3,
        note_text,
        transform=ax.transAxes,
        fontsize=9,
        verticalalignment="top",
        bbox=dict(boxstyle="round", facecolor="wheat", alpha=0.7),
    )

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def plot_penrose_kerr(save_path=None):
    """
    Penrose Diagram of Rotating (Kerr) Black Hole

    Physics: Unlike Schwarzschild, the Kerr solution has:
    - Ring singularity (not a spacelike surface but a timelike ring)
    - You can pass through the ring to reach exotic regions
    - "Negative mass" regions (anti-verse)
    - Infinite sequence of universes if maximally extended

    In practice, the inner horizon is unstable (mass inflation),
    so these exotic regions likely don't exist in nature.
    """
    fig, ax = plt.subplots(figsize=(11, 10))

    exterior = np.array([[2, 2], [4, 0], [2, -2], [0, 0]])
    ax.fill(
        exterior[:, 0],
        exterior[:, 1],
        color="lightblue",
        alpha=0.4,
        label="Exterior (Region I)",
    )

    bh_interior = np.array([[0, 0], [2, 2], [0, 3], [-2, 2]])
    ax.fill(
        bh_interior[:, 0],
        bh_interior[:, 1],
        color="gray",
        alpha=0.4,
        label="Black Hole Interior (II)",
    )

    exotic = np.array([[-2, 2], [0, 3], [2, 2], [0, 1]])
    ax.fill(
        exotic[:, 0],
        exotic[:, 1],
        color="purple",
        alpha=0.3,
        label="Exotic Interior (III)",
    )

    next_universe = np.array([[0, 3], [2, 5], [0, 4], [-2, 5]])
    ax.fill(
        next_universe[:, 0],
        next_universe[:, 1],
        color="lightgreen",
        alpha=0.4,
        label="Next Universe (IV)",
    )

    ax.plot([0, 2], [0, 2], "k-", linewidth=3, label="Outer Horizon (r₊)")
    ax.plot([0, -2], [0, 2], "k-", linewidth=3)
    ax.plot([0, 2], [1, 2], "k--", linewidth=2, label="Inner Horizon (r₋)")
    ax.plot([0, -2], [1, 2], "k--", linewidth=2)

    ring_y = np.linspace(2.5, 3.5, 50)
    ax.plot(
        [0] * len(ring_y),
        ring_y,
        "r-",
        linewidth=4,
        label="Ring Singularity (timelike!)",
    )
    ax.plot(0, 3, "ro", markersize=10)

    path = np.array([[1, 1.5], [0.5, 2.5], [0, 3], [0.5, 3.5], [1, 4.5]])
    ax.plot(
        path[:, 0],
        path[:, 1],
        "g-",
        linewidth=3,
        alpha=0.7,
        marker="o",
        markersize=6,
        label="Path through ring",
    )
    ax.annotate(
        "Pass through\nring singularity!",
        xy=(0, 3),
        xytext=(1, 3.5),
        fontsize=10,
        color="darkgreen",
        bbox=dict(boxstyle="round", facecolor="lightgreen", alpha=0.7),
        arrowprops=dict(arrowstyle="->", color="green", lw=2),
    )

    ax.plot([2, 4], [2, 0], "b-", linewidth=2)
    ax.plot([2, 4], [-2, 0], "b-", linewidth=2)

    ax.text(
        2.5, 0, "I\nExterior", ha="center", va="center", fontsize=12, fontweight="bold"
    )
    ax.text(
        0.3, 1.3, "II\nBH", ha="center", va="center", fontsize=11, fontweight="bold"
    )
    ax.text(
        0,
        2.2,
        "III",
        ha="center",
        va="center",
        fontsize=11,
        fontweight="bold",
        color="purple",
    )
    ax.text(
        0,
        4.5,
        "IV\nNew\nUniverse",
        ha="center",
        va="center",
        fontsize=11,
        fontweight="bold",
        color="darkgreen",
    )

    ax.set_xlim(-3, 5)
    ax.set_ylim(-3, 6)
    ax.set_aspect("equal")
    ax.set_xlabel("Space", fontsize=12)
    ax.set_ylabel("Time", fontsize=12)
    ax.set_title(
        "Penrose Diagram: Kerr (Rotating) Black Hole\n"
        + "Ring singularity allows passage to new universes",
        fontsize=14,
        fontweight="bold",
    )
    ax.legend(loc="upper left", fontsize=9)
    ax.grid(True, alpha=0.3)

    note = (
        "⚠ Warning: Inner horizon likely unstable (mass inflation).\n"
        "Exotic regions probably sealed off in realistic collapse.\n"
        "This is the maximally extended mathematical solution."
    )
    ax.text(
        0,
        -3.5,
        note,
        ha="center",
        fontsize=9,
        style="italic",
        bbox=dict(boxstyle="round", facecolor="yellow", alpha=0.6),
    )

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def plot_visual_infalling(save_path=None):
    """
    Visual Appearance of Objects Falling Into a Black Hole

    Physics: Due to gravitational time dilation, an external observer sees:
    1. Object appears to slow down as it approaches horizon
    2. Light gets increasingly redshifted (z → ∞)
    3. Object appears frozen at horizon, fading to black
    4. Last photon emitted just outside horizon is the last seen

    But for the infalling observer:
    - Proper time to horizon is finite
    - They cross smoothly with nothing special at horizon
    - They hit singularity in finite proper time
    """
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    t_observer = np.linspace(0, 100, 1000)
    r_apparent = RS + 8 * np.exp(-t_observer / 15)

    ax1.plot(t_observer, r_apparent, "b-", linewidth=3, label="Apparent position")
    ax1.axhline(
        RS,
        color="black",
        linewidth=2,
        linestyle="--",
        label="Event Horizon (never crossed from outside view)",
    )
    ax1.axhline(R_ISCO, color="gray", linewidth=1, linestyle=":", label="ISCO (r=6M)")

    ax1.fill_between(
        [50, 100], 0, 15, alpha=0.2, color="red", label="Object appears frozen"
    )

    ax1.set_xlabel("Observer Time t (far away)", fontsize=12)
    ax1.set_ylabel("Apparent Radial Position r", fontsize=12)
    ax1.set_title("What External Observer Sees", fontsize=13, fontweight="bold")
    ax1.set_ylim(0, 12)
    ax1.legend(fontsize=10)
    ax1.grid(True, alpha=0.3)

    ax1.annotate(
        "Slowing down",
        xy=(20, r_apparent[200]),
        xytext=(30, 8),
        fontsize=10,
        arrowprops=dict(arrowstyle="->", color="blue", lw=2),
    )
    ax1.annotate(
        "Frozen here\n(never see it cross)",
        xy=(80, RS + 0.2),
        xytext=(60, 4),
        fontsize=10,
        color="red",
        arrowprops=dict(arrowstyle="->", color="red", lw=2),
    )

    z = np.exp(t_observer / 15) - 1
    brightness = 1 / (1 + z) ** 4

    ax2_brightness = ax2.twinx()

    line1 = ax2.semilogy(t_observer, z + 1, "r-", linewidth=3, label="Redshift (1+z)")
    line2 = ax2_brightness.plot(
        t_observer, brightness, "orange", linewidth=3, label="Brightness"
    )

    ax2.set_xlabel("Observer Time t", fontsize=12)
    ax2.set_ylabel("Redshift (1+z) [log scale]", fontsize=12, color="red")
    ax2_brightness.set_ylabel("Relative Brightness", fontsize=12, color="orange")
    ax2.set_title("Redshift and Dimming", fontsize=13, fontweight="bold")
    ax2.set_ylim(1, 1e6)
    ax2_brightness.set_ylim(0, 1.1)
    ax2.grid(True, alpha=0.3)
    ax2.tick_params(axis="y", labelcolor="red")
    ax2_brightness.tick_params(axis="y", labelcolor="orange")

    lines = line1 + line2
    labels = [line.get_label() for line in lines]
    ax2.legend(lines, labels, loc="upper left", fontsize=10)

    note = (
        "Object appears to freeze and fade\n"
        "Infinite redshift at horizon\n"
        "Last photons increasingly delayed"
    )
    ax2.text(
        0.5,
        0.95,
        note,
        transform=ax2.transAxes,
        verticalalignment="top",
        fontsize=10,
        bbox=dict(boxstyle="round", facecolor="lightyellow", alpha=0.8),
    )

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def plot_geodesics(save_path=None):
    """
    Comparison of Geodesics: Timelike, Null, and Spacelike

    Physics: In curved spacetime, free-falling particles follow geodesics.
    - Timelike geodesics: massive particles (ds² < 0)
    - Null geodesics: light rays (ds² = 0)
    - Spacelike: forbidden for physical objects (ds² > 0)

    Near a black hole, all future-directed geodesics inside the
    horizon lead to the singularity.

    Note: Outgoing light rays only escape from well outside the horizon.
    """
    fig, ax = plt.subplots(figsize=(10, 8))

    for r0 in [10, 8, 6, 4, 3]:
        t = np.linspace(0, 40, 200)
        r = r0 * (1 - 0.02 * t) ** 2
        r = np.maximum(r, 0.1)
        valid = r > 0.1
        ax.plot(t[valid], r[valid], "b-", linewidth=2, alpha=0.7)

    for r0 in [10, 8, 6, 4]:
        t = np.linspace(0, 30, 200)
        r = r0 - 0.3 * t
        r = np.maximum(r, 0.1)
        valid = r > 0.1
        ax.plot(t[valid], r[valid], "y-", linewidth=2, alpha=0.8)

    for r0 in [3.0, 4.0, 6.0, 8.0]:
        r = np.linspace(r0, 10, 100)
        r_star = r + 2 * RS * np.log(np.abs(r / RS - 1))
        r0_star = r0 + 2 * RS * np.log(np.abs(r0 / RS - 1))
        t = r_star - r0_star
        t = t + (r0 - 3) * 5
        ax.plot(t, r, "r--", linewidth=2, alpha=0.7)

    for r_orbit in [R_ISCO, 8]:
        t = np.linspace(0, 40, 100)
        ax.plot(t, [r_orbit] * len(t), "g:", linewidth=2.5, alpha=0.8)

    ax.axhline(RS, color="black", linewidth=3, linestyle="--", label="Event Horizon")
    ax.fill_between([0, 40], 0, RS, alpha=0.2, color="black")
    ax.axhline(0, color="red", linewidth=2, label="Singularity")
    ax.axhline(
        R_ISCO, color="green", linewidth=1.5, linestyle=":", label="ISCO", alpha=0.7
    )

    ax.text(
        35,
        9,
        "Massive particles\n(timelike)",
        color="blue",
        fontsize=11,
        fontweight="bold",
    )
    ax.text(
        25, 5, "Light rays inward\n(null)", color="gold", fontsize=11, fontweight="bold"
    )
    ax.text(
        10, 4.5, "Light escaping\n(null)", color="red", fontsize=10, fontweight="bold"
    )
    ax.text(35, 6, "Circular\norbits", color="green", fontsize=10, fontweight="bold")

    note = (
        "NOTE: Outgoing light rays (red dashed) only\n"
        "originate from r>2M. Once inside the horizon,\n"
        "even light cannot escape!"
    )
    ax.text(
        20,
        1,
        note,
        fontsize=9,
        color="darkred",
        fontweight="bold",
        bbox=dict(boxstyle="round", facecolor="lightyellow", alpha=0.9),
    )

    ax.set_xlabel("Time (t)", fontsize=12)
    ax.set_ylabel("Radial Position (r)", fontsize=12)
    ax.set_title(
        "Geodesics Around a Black Hole\n"
        + "Different paths particles and light take in curved spacetime",
        fontsize=14,
        fontweight="bold",
    )
    ax.set_xlim(0, 40)
    ax.set_ylim(-0.5, 11)
    ax.legend(fontsize=11, loc="upper right")
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    if save_path:
        plt.savefig(save_path, dpi=150, bbox_inches="tight")
        print(f"  Saved: {save_path}")
    else:
        plt.show()
    plt.close()


def main():
    parser = argparse.ArgumentParser(
        description="Generate scientifically accurate black hole visualizations"
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Display plots interactively instead of saving to files",
    )
    args = parser.parse_args()

    print("=" * 70)
    print("  Scientifically Accurate Black Hole Visualizations")
    print("  Based on solutions to Einstein's field equations")
    print("=" * 70)

    plots = [
        ("01_light_cone_tilting.png", "Light Cone Tilting", plot_light_cone_tilting),
        (
            "02_penrose_schwarzschild.png",
            "Penrose Diagram (Schwarzschild)",
            plot_penrose_schwarzschild,
        ),
        (
            "03_eddington_finkelstein.png",
            "Eddington-Finkelstein Coordinates",
            plot_eddington_finkelstein,
        ),
        ("04_waterfall.png", "Waterfall Model", plot_waterfall),
        ("05_kerr_structure.png", "Kerr Black Hole Structure", plot_kerr_structure),
        ("06_penrose_kerr.png", "Penrose Diagram (Kerr)", plot_penrose_kerr),
        ("07_visual_infalling.png", "Visual Appearance of Infalling Objects", plot_visual_infalling),
        ("08_geodesics.png", "Geodesics Comparison", plot_geodesics),
    ]

    for filename, name, func in plots:
        print(f"\n[{plots.index((filename, name, func)) + 1}/8] {name}")
        if args.show:
            func(save_path=None)
        else:
            func(save_path=filename)

    print("\n" + "=" * 70)
    print("  All visualizations complete!")
    print("=" * 70)
    print("\nKey Physics Takeaways:")
    print("  1. Event horizons are coordinate singularities (mathematical artifact)")
    print("  2. Objects appear frozen to external observers but fall through normally")
    print("  3. Maximal extensions reveal white holes & parallel universes (math only)")
    print("  4. Rotating black holes have ergospheres and ring singularities")
    print("  5. Inner horizons likely unstable → exotic regions sealed off")
    print("  6. Traversable wormholes require exotic matter (probably impossible)")
    print("  7. Outgoing light only escapes from outside the horizon!")
    print()


if __name__ == "__main__":
    main()
