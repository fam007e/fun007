import lattice_visualization_module as lat

def get_user_input():
    lattice = input("Enter lattice type (bcc/fcc): ").strip().lower()
    slip_plane = list(map(int, input("Enter slip plane coordinates (e.g., 1 1 1): ").split()))
    slip_direction = list(map(int, input("Enter slip direction coordinates (e.g., 1 -1 0): ").split()))
    stress = list(map(int, input("Enter stress coordinates (e.g., 1 2 3): ").split()))
    return lattice, slip_plane, slip_direction, stress

def main():
    lattice, slip_plane, slip_direction, stress = get_user_input()

    lat.plot_lattice(lattice)
    lat.plot_plane(slip_plane, 'green', label='Slip Plane')
    lat.plot_vector(slip_direction, 'purple', label='Slip Direction')
    lat.plot_vector(stress, 'black', label='Stress')
    lat.calculate_schmid_factor(slip_plane, slip_direction, stress) # plane, direction, force

    ax = lat.ax
    ax.legend()
    lat.show()

if __name__ == "__main__":
    main()
