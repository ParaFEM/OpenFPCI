#!/bin/bash
set -e

# Update and install dependencies
sudo apt-get update && sudo apt-get install -y \
    git-core \
    build-essential \
    binutils-dev \
    cmake \
    flex \
    bear \
    zlib1g-dev \
    libncurses5-dev \
    libreadline-dev \
    openmpi-bin \
    libopenmpi-dev \
    libxt-dev \
    rpm \
    mercurial \
    graphviz \
    python \
    python-dev \
    python3 \
    python3-dev \
    gcc-5 \
    g++-5 \
    gfortran \
    libiberty-dev \
    wget \
    nano \
    tcsh \
    gnuplot \
    gnuplot-qt \
    gnuplot-data


# Set working directory
mkdir -p ~/foam
cd ~/foam

# Clone foam-extend
git clone git://git.code.sf.net/p/foam-extend/foam-extend-4.0
cd foam-extend-4.0

# Set environment variables
echo 'export WM_THIRD_PARTY_USE_BISON_27=1' >> etc/prefs.sh
echo "export WM_CC='gcc-5'" >> etc/prefs.sh
echo "export WM_CXX='g++-5'" >> etc/prefs.sh
echo "export PARAVIEW_SYSTEM=0" >> etc/prefs.sh

# Modify OpenMPI spec file to enable Fortran support
cd ThirdParty/rpmBuild/SPECS
sed -i '143s/--disable-mpi-f90/--enable-mpi-f90/' openmpi-1.8.8.spec
sed -i '143 a\        FC=gfortran \\' openmpi-1.8.8.spec

# Uncomment lines in fvSchemes.C
cd ~/foam/foam-extend-4.0/src/finiteVolume/finiteVolume/fvSchemes
sed -i '382,394 s/^\(\s*\)\/\/ /\1/' fvSchemes.C

# Fix download URLs for third-party libraries
cd ~/foam/foam-extend-4.0/ThirdParty
sed -i \
    's|http://portal.nersc.gov/project/visit/third_party/libccmio-2.6.1.tar.gz|https://sourceforge.net/projects/foam-extend/files/ThirdParty/libccmio-2.6.1.tar.gz|' \
    AllMake.stage3

sed -i \
    's|http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz|https://www.cp2k.org/static/downloads/parmetis-4.0.3.tar.gz|' \
    AllMake.stage3

# Compile foam-extend
cd ~/foam/foam-extend-4.0

sed -i -e \
    's=rpmbuild --define=rpmbuild --define "_build_id_links none" --define=' \
    ThirdParty/tools/makeThirdPartyFunctionsForRPM

sed -i -e 's/gcc/\$(WM_CC)/' wmake/rules/linux64Gcc/c
sed -i -e 's/g++/\$(WM_CXX)/' wmake/rules/linux64Gcc/c++

source etc/bashrc

./Allwmake.firstInstall > OpenFoam_Extend_40_log.txt 2>&1


###############################################################################
# Modify fvMesh.C to support restart fields in region directories
###############################################################################

# Reload the foam-extend environment to ensure WM_PROJECT_DIR is available
source ~/foam/foam-extend-4.0/etc/bashrc

FVMESH_FILE="$WM_PROJECT_DIR/src/finiteVolume/fvMesh/fvMesh.C"

if [ ! -f "$FVMESH_FILE" ]; then
    echo "Error: fvMesh.C was not found:"
    echo "$FVMESH_FILE"
    exit 1
fi

echo "Modifying restart field paths in:"
echo "$FVMESH_FILE"

# Keep one backup of the original source file
if [ ! -f "${FVMESH_FILE}.original" ]; then
    cp "$FVMESH_FILE" "${FVMESH_FILE}.original"
fi

# Modify the V0 path
sed -i \
    's|isFile(time().timePath()/"V0")|isFile(time().timePath()/this->dbDir()/"V0")|g' \
    "$FVMESH_FILE"

# Modify the meshPhi path
sed -i \
    's|isFile(time().timePath()/"meshPhi")|isFile(time().timePath()/this->dbDir()/"meshPhi")|g' \
    "$FVMESH_FILE"

# Check that both changes are present
if ! grep -Fq \
    'isFile(time().timePath()/this->dbDir()/"V0")' \
    "$FVMESH_FILE"; then
    echo "Error: Failed to modify the V0 path in fvMesh.C"
    exit 1
fi

if ! grep -Fq \
    'isFile(time().timePath()/this->dbDir()/"meshPhi")' \
    "$FVMESH_FILE"; then
    echo "Error: Failed to modify the meshPhi path in fvMesh.C"
    exit 1
fi

echo "fvMesh.C was modified successfully."

# Recompile the finiteVolume library
cd "$WM_PROJECT_DIR/src/finiteVolume"

echo "Cleaning the finiteVolume library..."
wclean

echo "Recompiling the finiteVolume library..."
wmake libso > finiteVolume_recompile_log.txt 2>&1

echo "finiteVolume library was recompiled successfully."


###############################################################################
# Continue installing FSI and ParaFEM
###############################################################################

# Create user directories
mkdir -p "$WM_PROJECT_USER_DIR"
mkdir -p "$FOAM_RUN"

# Install FSI module
cd "$WM_PROJECT_USER_DIR"
wget https://openfoamwiki.net/images/d/d6/Fsi_40.tar.gz
tar -xzf Fsi_40.tar.gz

# Fix RBFMeshMotionSolver
cd ./FluidSolidInteraction/src/fluidSolidInteraction/fluidSolvers/finiteVolume/RBFMeshMotionSolver/
sed -i '9 a #include <vector>' RBFMeshMotionSolver.C

# GGI changed to AABB master and slave mapping method
sed -i 's/ggiInterpolation::BB_OCTREE/ggiInterpolation::AABB/' \
"$(find "$WM_PROJECT_USER_DIR/FluidSolidInteraction/src" -name fluidSolidInterface.C | head -n 1)"

# Compile FSI module
cd "$WM_PROJECT_USER_DIR/FluidSolidInteraction/src"
source ~/foam/foam-extend-4.0/etc/bashrc
./Allwmake > FSI_log.txt 2>&1

# Update include paths in options files
cd "$WM_PROJECT_USER_DIR/FluidSolidInteraction"

find run -name options | while read -r item; do
    sed -i \
        -e 's=$(WM_PROJECT_DIR)/applications/solvers/FSI=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src=' \
        "$item"

    sed -i \
        -e 's=$(WM_THIRD_PARTY_DIR)/packages/eigen3=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src/ThirdParty/eigen3=' \
        "$item"
done

# Install ParaFEM
cd ~
git clone https://github.com/ParaFEM/ParaFEM.git

cd ~/ParaFEM/parafem/build
sed -i 's|FC=/usr/bin/mpif90|FC=mpif90|' linuxdesktop.inc

cd ../include
mkdir -p bem_p

cd ../
source ~/foam/foam-extend-4.0/etc/bashrc
./make-parafem MACHINE=linuxdesktop > ParaFEM_log.txt 2>&1

echo 'export PATH=~/ParaFEM/parafem/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install OpenFPCI
cd ~

export PARAFEM_DIR=~/ParaFEM/parafem
export FOAM_DIR=~/foam/foam-extend-4.0

echo 'export PARAFEM_DIR=~/ParaFEM/parafem' >> ~/.bashrc
echo 'export FOAM_DIR=~/foam/foam-extend-4.0' >> ~/.bashrc

source ~/.bashrc

sudo ln -sf \
    /lib/x86_64-linux-gnu/libgfortran.so.5.0.0 \
    /lib/x86_64-linux-gnu/libgfortran.so

cd ~/OpenFPCI/src
source ~/foam/foam-extend-4.0/etc/bashrc
./openfpci.sh

# Add alias for convenience
echo "alias fe40='source ~/foam/foam-extend-4.0/etc/bashrc'" >> ~/.bashrc

echo "Installation Done!"
