#include <cmath>
#include <fstream>
#include <iostream>
#include <vector>

// Simple Harmonic Oscillator Simulation
int main() {
  const int steps = 1000;
  const double dt = 0.05;
  double t = 0.0;
  double x = 1.0; // Initial pos
  double v = 0.0; // Initial vel

  std::cout << "Running Simulation (" << steps << " steps)..." << std::endl;

  std::ofstream file("data.csv");
  file << "t,x,v\n"; // Header

  for (int i = 0; i < steps; ++i) {
    file << t << "," << x << "," << v << "\n";

    // Symplectic Euler Integration
    v = v - x * dt;
    x = x + v * dt;
    t += dt;
  }

  file.close();
  std::cout << "Done. Data saved to data.csv" << std::endl;
  return 0;
}
