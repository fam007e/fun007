# Lattice Visualization

This package provides tools for visualizing lattice structures and calculating Schmid factors using Python. It includes modules for plotting Body-Centered Cubic (BCC) and Face-Centered Cubic (FCC) lattices, visualizing planes and vectors, and computing Schmid factors.

## Features

- **3D Visualization**: Plot `BCC` and `FCC` lattices, and visualize `slip-planes` and `slip-directions`.
- **Custom Annotations**: Annotate 3D plots with custom text.
- **3D Arrows**: Draw 3D arrows for vectors and planes.
- **Schmid Factor Calculation**: Compute the `Schmid-factor` for given `slip-planes`, `slip-directions`, and `stress-vectors`.

## Prerequisites

- **Python 3.x**: Ensure you have Python 3 installed on your system.
- **Dependencies**: `numpy` and `matplotlib`.

## Installation

You can install the package and its dependencies using `pip`. Navigate to the directory containing `setup.py` and run:

```sh
pip install .
```

## Usage

- Clone or download the repository to your local machine.

- Install the package using `pip` as described above.

- Run the visualization script:
  ```sh
  lattice_visualizer
  ```
- Follow the prompts to enter lattice `type`, `slip-plane`, `slip-direction`, and `stress- coordinates`.

### Example

```sh
$ lattice_visualizer
Enter lattice type (bcc/fcc): bcc
Enter slip plane coordinates (e.g., 1 1 1): 1 1 1
Enter slip direction coordinates (e.g., 1 -1 0): 1 -1 0
Enter stress coordinates (e.g., 1 2 3): 1 2 3
```
This will generate a 3D plot of the specified `lattice`, `slip-plane`, `slip-direction`, and `stress`, and calculate the `Schmid-factor`.

## License
This project is licensed under the [LICENSE](../LICENSE).
