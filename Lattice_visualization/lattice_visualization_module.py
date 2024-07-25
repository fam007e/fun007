import numpy as np
import matplotlib.pyplot as plt
import arrow3d_patch as arrow3d

fig = plt.figure()
ax = fig.add_subplot(projection='3d')
ax.set_aspect('equal')
ax.set_xlim([-1, 1])
ax.set_ylim([-1, 1])
ax.set_zlim([-1, 1])
ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.set_zlabel('Z')
ax.set_xticks([-1, 0, 1])
ax.set_yticks([-1, 0, 1])
ax.set_zticks([-1, 0, 1])

def plot_cube(ax, x_vertices, y_vertices, z_vertices):
    for i in range(4):
        for j in range(i+1, 4):
            ax.plot([x_vertices[i], x_vertices[j]], [y_vertices[i], y_vertices[j]], [z_vertices[i], z_vertices[j]], marker='o', c='blue', markersize=20)
            ax.plot([x_vertices[i+4], x_vertices[j+4]], [y_vertices[i+4], y_vertices[j+4]], [z_vertices[i+4], z_vertices[j+4]], marker='o', c='blue', markersize=20)
            ax.plot([x_vertices[i], x_vertices[i+4]], [y_vertices[i], y_vertices[i+4]], [z_vertices[i], z_vertices[i+4]], marker='o', c='blue', markersize=20)
    for i in [0, 4]:
        ax.plot([x_vertices[i], x_vertices[i+3]], [y_vertices[i], y_vertices[i+3]], [z_vertices[i], z_vertices[i+3]], marker='o', c='blue', markersize=20)

def plot_bcc(fig=fig, ax=ax):
    x_vertices = np.array([1, 1, 1, 1, 0, 0, 0, 0])
    y_vertices = np.array([0, 1, 1, 0, 0, 1, 1, 0])
    z_vertices = np.array([0, 0, 1, 1, 0, 0, 1, 1])
    plot_cube(ax, x_vertices, y_vertices, z_vertices)
    ax.scatter([0.5], [0.5], [0.5], marker='o', c='red', s=400)

def plot_fcc(fig=fig, ax=ax):
    x_vertices = np.array([1, 1, 1, 1, 0, 0, 0, 0])
    y_vertices = np.array([0, 1, 1, 0, 0, 1, 1, 0])
    z_vertices = np.array([0, 0, 1, 1, 0, 0, 1, 1])
    plot_cube(ax, x_vertices, y_vertices, z_vertices)
    x_fc = np.array([1, 0.5, 0.5, 0.5, 0.5, 0])
    y_fc = np.array([0.5, 0.5, 1, 0.5, 0, 0.5])
    z_fc = np.array([0.5, 0, 0.5, 1, 0.5, 0.5])
    ax.scatter(x_fc, y_fc, z_fc, marker='o', c='red', s=400)

def plot_lattice(lat):
    if lat == 'bcc':
        plot_bcc()
    elif lat == 'fcc':
        plot_fcc()
    else:
        print('Undefined lattice')

def plot_plane(plane, color, step=0.25, fig=fig, ax=ax, label=None):
    a, b, c = plane
    ax.arrow3D(0, 0, 0, a, b, c, mutation_scale=20, ec=color, fc=color)
    x_range = np.arange(0 if a >= 0 else -1, 1 + step, step)
    y_range = np.arange(0 if b >= 0 else -1, 1 + step, step)
    X, Y = np.meshgrid(x_range, y_range)
    Z = (1 - X/a - Y/b) * c
    Z[Z > 1] = np.nan
    ax.plot_surface(X, Y, Z, alpha=0.5, label=label)

def plot_vector(vector, color, fig=fig, ax=ax, label=None):
    a, b, c = vector
    ax.arrow3D(0, 0, 0, a, b, c, mutation_scale=20, ec=color, fc=color)
    if label:
        ax.text(a, b, c, label, color=color)

def calculate_schmid_factor(plane_normal, slip_direction, stress, fig=fig, ax=ax):
    schmid_factor = np.abs(np.dot(stress, plane_normal) * np.dot(stress, slip_direction) /
                           (np.linalg.norm(stress) ** 2 * np.linalg.norm(slip_direction) * np.linalg.norm(plane_normal)))
    ax.set_title(f'Schmid factor = {np.round(schmid_factor, 3)}')

def show():
    plt.legend()
    plt.show()
