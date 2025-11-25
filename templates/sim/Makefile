# ─── SCIENTIFIC MAKEFILE ──────────────────────────────────────────────
# Automatically detects .cpp or .f90 files and builds the executable
# ──────────────────────────────────────────────────────────────────────

PROGRAM = simulation
CXX = g++
FC = gfortran
CXXFLAGS = -O3 -march=native -Wall -std=c++17
FFLAGS = -O3 -march=native -Wall -fdefault-real-8

# Source detection
SRC_CPP = $(wildcard *.cpp)
SRC_F90 = $(wildcard *.f90)
OBJ = $(SRC_CPP:.cpp=.o) $(SRC_F90:.f90=.o)

# Targets
all: $(PROGRAM)

$(PROGRAM): $(OBJ)
	@echo "Linking $(PROGRAM)..."
	@if [ -n "$(SRC_CPP)" ]; then $(CXX) -o $@ $^ -lgfortran; else $(FC) -o $@ $^; fi

%.o: %.cpp
	@echo "Compiling C++: $<"
	@$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.f90
	@echo "Compiling Fortran: $<"
	@$(FC) $(FFLAGS) -c $< -o $@

run: $(PROGRAM)
	@./$(PROGRAM)

clean:
	rm -f $(OBJ) $(PROGRAM) *.mod

.PHONY: all clean run
