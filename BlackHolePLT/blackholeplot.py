"""
Central Optimized Python Script for Visualizing Black Hole Spacetime Diagrams and Metrics

This script integrates multiple visualizations of spacetime concepts from general relativity,
focusing on black holes as described in solutions to Einstein's field equations, such as the
Schwarzschild and Kerr metrics. The visualizations include 2D spacetime diagrams, light cones,
waterfall models of infalling space, 3D embeddings of spatial curvature, and projections of
higher-dimensional structures like wormholes.

Scientific Context:
Einstein's general theory of relativity describes gravity as the curvature of spacetime induced
by mass-energy. The Schwarzschild metric represents the spacetime geometry exterior to a static,
spherically symmetric, non-rotating mass, revealing features like event horizons and singularities.
Light cones illustrate causal structure, defining regions accessible at subluminal speeds.
In curved spacetime, these cones tilt, leading to phenomena like gravitational time dilation and
the apparent freezing of infalling objects at the event horizon from an external observer's perspective.

The script is modularized into functions for each visualization, promoting code reuse and optimization.
NumPy is used for efficient array operations, and Matplotlib for plotting. Animations employ FuncAnimation
for dynamic representations. Parameters like the Schwarzschild radius (Rs = 2GM/c², normalized to 2)
are shared to maintain consistency.

Usage:
- Run the script to generate and display all plots sequentially.
- Figures can be saved by uncommenting plt.savefig() calls.
- For resource optimization, close figures after viewing (plt.close()).

Dependencies: numpy, matplotlib (included in the environment).
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.animation import FuncAnimation

# Shared parameters for consistency across visualizations
RS = 2.0  # Schwarzschild radius (2GM/c², normalized units where G=M=c=1)
R_MAX = 10.0  # Maximum radial extent for plots
T_MAX = 20.0  # Maximum time extent
N_POINTS = 100  # Number of points for discretization (optimized for performance)


def plot_2d_light_cone_flat():
    """
    2D Light Cone in Flat (Minkowski) Spacetime

    Scientific Explanation:
    In special relativity, the light cone delineates the causal structure of spacetime. For an event
    at the origin (t=0, x=0), the future light cone bounds all timelike and null trajectories that
    can be influenced by the event, while the past light cone bounds those that can influence it.
    With units where c=1, light rays propagate at 45-degree angles. This diagram uses one spatial
    dimension (x) and time (t), illustrating the invariance of the spacetime interval ds² = -dt² + dx².

    The plot shows future (blue) and past (red dashed) cones, emphasizing that no causal influence
    can extend beyond these boundaries without superluminal travel, which is forbidden.
    """
    t = np.linspace(0, T_MAX, N_POINTS)
    x_pos = t  # Right-moving light ray
    x_neg = -t  # Left-moving light ray
    t_past = np.linspace(-T_MAX, 0, N_POINTS)
    x_past_pos = -t_past
    x_past_neg = t_past

    fig, ax = plt.subplots(figsize=(8, 8))
    ax.plot(x_pos, t, "b-", label="Future Light Ray")
    ax.plot(x_neg, t, "b-")
    ax.plot(x_past_pos, t_past, "r--", label="Past Light Ray")
    ax.plot(x_past_neg, t_past, "r--")
    ax.axhline(0, color="black", lw=0.5)
    ax.axvline(0, color="black", lw=0.5)
    ax.set_xlabel("Spatial Dimension (x)")
    ax.set_ylabel("Time Dimension (t)")
    ax.set_title("2D Light Cone in Flat Spacetime")
    ax.legend()
    ax.grid(True)
    ax.set_xlim(-R_MAX, R_MAX)
    ax.set_ylim(-T_MAX, T_MAX)
    ax.set_aspect("equal")
    plt.show()
    # plt.savefig('flat_light_cone.png')  # Uncomment to save


def plot_2d_schwarzschild_diagram():
    """
    2D Spacetime Diagram for Schwarzschild Black Hole (Null Geodesics)

    Scientific Explanation:
    In Schwarzschild coordinates, the metric is ds² = -(1 - Rs/r) dt² + (1 - Rs/r)^{-1} dr² + r² dΩ².
    This plot illustrates radial null geodesics (light paths). Ingoing light rays follow trajectories
    that cross the event horizon at r=Rs, while outgoing rays asymptote to the horizon as t → ∞,
    reflecting the coordinate singularity and the external observer's perception of time dilation.
    The logarithmic scaling captures the infinite redshift and apparent freezing of infalling objects.

    This visualization highlights the breakdown of Schwarzschild coordinates at r=Rs, necessitating
    alternative charts (e.g., Kruskal-Szekeres) for a complete description.
    """
    r_ingoing = np.linspace(R_MAX, RS, N_POINTS)
    t_ingoing = -5 * np.log(
        (r_ingoing - RS) / (R_MAX - RS) + 1e-10
    )  # Avoid log(0), asymptote

    r_outgoing = np.linspace(
        RS + 0.01, R_MAX, N_POINTS
    )  # Small offset to avoid division by zero
    t_outgoing = 5 * np.log((r_outgoing - RS) / 0.01)

    fig, ax = plt.subplots(figsize=(8, 8))
    ax.plot(t_ingoing, r_ingoing, "b-", label="Ingoing Light Ray")
    ax.plot(t_outgoing, r_outgoing, "r--", label="Outgoing Light Ray (Asymptotic)")
    ax.axhline(RS, color="black", label="Event Horizon (r=Rs)")
    ax.set_xlabel("Time (t)")
    ax.set_ylabel("Radial Distance (r)")
    ax.set_title("2D Schwarzschild Spacetime Diagram")
    ax.legend()
    ax.grid(True)
    ax.set_ylim(0, R_MAX + 1)
    ax.set_xlim(-T_MAX, T_MAX)
    plt.show()
    # plt.savefig('schwarzschild_diagram.png')


def plot_2d_waterfall_model():
    """
    2D Waterfall Model of Space Inflow into a Black Hole

    Scientific Explanation:
    This analogy represents spacetime as a fluid flowing inward toward the singularity, akin to a
    waterfall. In the river model of black holes, the velocity of space increases as 1/sqrt(r),
    exceeding c at r=Rs, explaining why nothing escapes. The vector field plots the radial inflow
    velocity Ur = -sqrt(Rs/r), derived from the Gullstrand-Painlevé coordinates, which regularize
    the metric across the horizon.

    This 2D projection (in Cartesian coordinates) visualizes the irrotational flow, emphasizing
    the inevitability of crossing the horizon for infalling observers.
    """
    x = np.linspace(-R_MAX, R_MAX, 20)
    y = np.linspace(-R_MAX, R_MAX, 20)
    X, Y = np.meshgrid(x, y)
    r = np.sqrt(X**2 + Y**2) + 1e-6  # Avoid zero
    Ur = -np.sqrt(RS / r)  # Inward radial velocity (Gullstrand-Painlevé inspired)
    Ux = Ur * (X / r)
    Uy = Ur * (Y / r)

    fig, ax = plt.subplots(figsize=(8, 8))
    ax.quiver(X, Y, Ux, Uy, color="b", scale=10)
    ax.axvline(0, color="black", lw=2, label="Singularity")
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    ax.set_title("2D Waterfall Model: Spacetime Inflow")
    ax.legend()
    ax.grid(True)
    plt.show()
    # plt.savefig('waterfall_model.png')


def plot_3d_schwarzschild_embedding():
    """
    3D Embedding Diagram of Schwarzschild Spatial Curvature (Flamm's Paraboloid)

    Scientific Explanation:
    To visualize the intrinsic curvature of a spatial slice (constant t, θ=π/2) in Schwarzschild
    geometry, we embed it isometrically into 3D Euclidean space. The surface satisfies dz/dr = sqrt(Rs/(r - Rs)),
    resulting in z = sqrt(8 Rs (r - Rs)) for the height. This paraboloid-like funnel illustrates
    increasing Gaussian curvature as r → Rs, where the throat represents the Einstein-Rosen bridge
    in the maximal extension.

    The plot is rotationally symmetric, highlighting the wormhole topology in the extended metric.
    """
    r = np.linspace(RS + 0.01, R_MAX, N_POINTS)
    theta = np.linspace(0, 2 * np.pi, N_POINTS)
    R, Theta = np.meshgrid(r, theta)
    Z = np.sqrt(8 * RS * (R - RS))  # Flamm's embedding height
    X = R * np.cos(Theta)
    Y = R * np.sin(Theta)

    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection="3d")
    ax.plot_surface(X, Y, Z, cmap="viridis", alpha=0.8)
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Embedded Height (Curvature)")
    ax.set_title("3D Embedding of Schwarzschild Curvature (Flamm's Paraboloid)")
    plt.show()
    # plt.savefig('schwarzschild_embedding.png')


def plot_3d_light_cone():
    """
    3D Projection of Light Cone in 1+2 Dimensional Spacetime

    Scientific Explanation:
    Extending the 2D light cone to 1 time + 2 space dimensions, the cone becomes a hypersurface
    satisfying x² + y² = t² (c=1). This represents the null boundary in Minkowski space, projecting
    the 4D structure into 3D for visualization. In curved spacetime analogs, such cones tilt inward
    near masses, but here it serves as a baseline for flat space causality.

    The surface illustrates the expanding wavefront of light from an event, bounding the causal future.
    """
    t = np.linspace(0, T_MAX / 2, N_POINTS // 2)  # Reduced for performance
    theta = np.linspace(0, 2 * np.pi, N_POINTS // 2)
    T, Theta = np.meshgrid(t, theta)
    X = T * np.cos(Theta)
    Y = T * np.sin(Theta)
    Z = T  # Time as z-axis

    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection="3d")
    ax.plot_surface(X, Y, Z, cmap="coolwarm", alpha=0.7)
    ax.set_xlabel("X")
    ax.set_ylabel("Y")
    ax.set_zlabel("Time (t)")
    ax.set_title("3D Light Cone Projection")
    plt.show()
    # plt.savefig('3d_light_cone.png')


def animate_4d_wormhole_projection():
    """
    Animated 3D Projection of 4D Einstein-Rosen Bridge (Wormhole)
    Now with automatic saving as MP4 (recommended) or GIF.
    """
    theta = np.linspace(0, 2 * np.pi, 80)
    phi = np.linspace(0, np.pi, 60)
    Theta, Phi = np.meshgrid(theta, phi)

    fig = plt.figure(figsize=(10, 8))
    ax = fig.add_subplot(111, projection="3d")
    ax.set_xlim(-2.5, 2.5)
    ax.set_ylim(-2.5, 2.5)
    ax.set_zlim(-3, 3)

    def update(frame):
        ax.cla()
        t = frame * 0.15  # slower → smoother
        throat = 0.8 + 0.7 * np.sin(t)  # realistic pinching
        X = throat * np.sin(Phi) * np.cos(Theta)
        Y = throat * np.sin(Phi) * np.sin(Theta)
        Z = 2.0 * np.cos(Phi) + 0.5 * np.cos(t)  # separates the two universes nicely

        ax.plot_surface(
            X, Y, Z, cmap="plasma", alpha=0.9, linewidth=0, antialiased=True
        )
        ax.set_title(f"Einstein-Rosen Bridge (Wormhole) – t = {t:.2f}", fontsize=14)
        ax.axis("off")  # cleaner look

    ani = FuncAnimation(fig, update, frames=120, interval=80, repeat=True)

    # ────── SAVE THE ANIMATION (choose ONE of the three lines below) ──────

    # 1. Best quality + small file (RECOMMENDED)
    ani.save(
        "einstein_rosen_bridge.mp4", writer="ffmpeg", fps=25, dpi=200, bitrate=3000
    )

    # 2. If you really want a GIF (larger file, but works everywhere)
    # ani.save('einstein_rosen_bridge.gif', writer='ffmpeg', fps=20)

    # 3. Pure-Python fallback (no ffmpeg needed, but slower and lower quality)
    # ani.save('einstein_rosen_bridge_pillow.gif', writer='pillow', fps=20)

    print("Animation saved successfully!")
    plt.show()


# Main execution: Generate all visualizations sequentially
if __name__ == "__main__":
    plot_2d_light_cone_flat()
    plot_2d_schwarzschild_diagram()
    plot_2d_waterfall_model()
    plot_3d_schwarzschild_embedding()
    plot_3d_light_cone()
    animate_4d_wormhole_projection()
