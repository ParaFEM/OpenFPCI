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
echo "export WM_CC='gcc-5'"  >> etc/prefs.sh
echo "export WM_CXX='g++-5'"  >> etc/prefs.sh
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
sed -i 's|http://portal.nersc.gov/project/visit/third_party/libccmio-2.6.1.tar.gz|https://sourceforge.net/projects/foam-extend/files/ThirdParty/libccmio-2.6.1.tar.gz|' AllMake.stage3
sed -i 's|http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz|https://www.cp2k.org/static/downloads/parmetis-4.0.3.tar.gz|' AllMake.stage3

# Compile foam-extend
cd ~/foam/foam-extend-4.0
sed -i -e 's=rpmbuild --define=rpmbuild --define "_build_id_links none" --define=' ThirdParty/tools/makeThirdPartyFunctionsForRPM
sed -i -e 's/gcc/\$(WM_CC)/' wmake/rules/linux64Gcc/c
sed -i -e 's/g++/\$(WM_CXX)/' wmake/rules/linux64Gcc/c++
source etc/bashrc
./Allwmake.firstInstall > OpenFoam_Extend_40_log.txt 2>&1

# Create user directories
mkdir -p $WM_PROJECT_USER_DIR
mkdir -p $FOAM_RUN

# Install FSI module
cd $WM_PROJECT_USER_DIR
wget https://openfoamwiki.net/images/d/d6/Fsi_40.tar.gz
tar -xzf Fsi_40.tar.gz

# Fix RBFMeshMotionSolver
cd ./FluidSolidInteraction/src/fluidSolidInteraction/fluidSolvers/finiteVolume/RBFMeshMotionSolver/
sed -i '9 a #include <vector>' RBFMeshMotionSolver.C

# Compile FSI module
cd $WM_PROJECT_USER_DIR/FluidSolidInteraction/src
source ~/foam/foam-extend-4.0/etc/bashrc
./Allwmake > FSI_log.txt 2>&1
# Update include paths in options files
cd $WM_PROJECT_USER_DIR/FluidSolidInteraction
find run -name options | while read item; do
    sed -i -e 's=$(WM_PROJECT_DIR)/applications/solvers/FSI=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src=' $item
    sed -i -e 's=$(WM_THIRD_PARTY_DIR)/packages/eigen3=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src/ThirdParty/eigen3=' $item
done

# Install ParaFEM
cd ~
git clone https://github.com/ParaFEM/ParaFEM.git
cd ~/ParaFEM/parafem/build
sed -i 's|FC=/usr/bin/mpif90|FC=mpif90|' linuxdesktop.inc

cd ../include
mkdir bem_p

cd ../
source ~/foam/foam-extend-4.0/etc/bashrc
./make-parafem MACHINE=linuxdesktop > ParaFEM_log.txt 2>&1

echo 'export PATH=~/ParaFEM/parafem/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install OpenFPCI
cd ~

echo 'export PARAFEM_DIR=~/ParaFEM/parafem' >> ~/.bashrc
echo 'export FOAM_DIR=~/foam/foam-extend-4.0' >> ~/.bashrc
source ~/.bashrc

lib_path=$(find /usr/lib/gcc/x86_64-linux-gnu/ -name "libgfortran.so" | head -n 1)

# Create symlink if libgfortran is found
if [[ -n "$lib_path" ]]; then
    echo "Found libgfortran at: $lib_path"
    echo "Creating symlink in /usr/bin..."
    
    sudo ln -sf "$lib_path" /usr/bin/libgfortran.so

    echo "Symlink created: /usr/bin/libgfortran.so -> $lib_path"
else
    echo "libgfortran.so not found under /usr/lib/gcc/x86_64-linux-gnu/"
    exit 1
fi
cd ~/OpenFPCI/src
source ~/foam/foam-extend-4.0/etc/bashrc
./openfpci.sh

# Add alias for convenience
echo "alias fe40='source ~/foam/foam-extend-4.0/etc/bashrc'" >> ~/.bashrc

echo "Installation Done!"

