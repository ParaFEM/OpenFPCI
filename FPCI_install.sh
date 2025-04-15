#!/bin/bash
set -e

# 更新并安装依赖
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
    qt4-dev-tools \
    libqt4-dev \
    libiberty-dev \
    wget \
    nano \
    gnuplot \
    gnuplot-qt \
    gnuplot-data


# 设置目录
mkdir -p ~/foam
cd ~/foam

# 克隆 foam-extend
git clone git://git.code.sf.net/p/foam-extend/foam-extend-4.0
cd foam-extend-4.0

# 设置环境变量
echo 'export WM_THIRD_PARTY_USE_BISON_27=1' >> etc/prefs.sh
echo "export WM_CC='gcc-5'"  >> etc/prefs.sh
echo "export WM_CXX='g++-5'"  >> etc/prefs.sh
echo "export PARAVIEW_SYSTEM=0" >> etc/prefs.sh
# 修改 openmpi spec 文件以启用 fortran
cd ThirdParty/rpmBuild/SPECS
sed -i '143s/--disable-mpi-f90/--enable-mpi-f90/' openmpi-1.8.8.spec
sed -i '143 a\        FC=gfortran \\' openmpi-1.8.8.spec

# 修改 fvSchemes.C 文件
cd ~/foam/foam-extend-4.0/src/finiteVolume/finiteVolume/fvSchemes
sed -i '382,394 s/^\(\s*\)\/\/ /\1/' fvSchemes.C

# 修复第三方库的下载地址
cd ~/foam/foam-extend-4.0/ThirdParty
sed -i 's|http://portal.nersc.gov/project/visit/third_party/libccmio-2.6.1.tar.gz|https://sourceforge.net/projects/foam-extend/files/ThirdParty/libccmio-2.6.1.tar.gz|' AllMake.stage3
sed -i 's|http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz|https://www.cp2k.org/static/downloads/parmetis-4.0.3.tar.gz|' AllMake.stage3

# 编译 foam-extend
cd ~/foam/foam-extend-4.0
sed -i -e 's=rpmbuild --define=rpmbuild --define "_build_id_links none" --define=' ThirdParty/tools/makeThirdPartyFunctionsForRPM
sed -i -e 's/gcc/\$(WM_CC)/' wmake/rules/linux64Gcc/c
sed -i -e 's/g++/\$(WM_CXX)/' wmake/rules/linux64Gcc/c++
source etc/bashrc
./Allwmake.firstInstall > OpenFoam_Extend_40_log.txt 2>&1

# 设置用户目录
mkdir -p $WM_PROJECT_USER_DIR
mkdir -p $FOAM_RUN

# 安装 FSI 模块
cd $WM_PROJECT_USER_DIR
wget https://openfoamwiki.net/images/d/d6/Fsi_40.tar.gz
tar -xzf Fsi_40.tar.gz

# 修复 RBFMeshMotionSolver
cd ./FluidSolidInteraction/src/fluidSolidInteraction/fluidSolvers/finiteVolume/RBFMeshMotionSolver/
sed -i '9 a #include <vector>' RBFMeshMotionSolver.C

# 编译 FSI 模块
cd $WM_PROJECT_USER_DIR/FluidSolidInteraction/src
source ~/foam/foam-extend-4.0/etc/bashrc
./Allwmake > FSI_log.txt 2>&1

# 修改 options 文件引用路径
cd $WM_PROJECT_USER_DIR/FluidSolidInteraction
find run -name options | while read item; do
    sed -i -e 's=$(WM_PROJECT_DIR)/applications/solvers/FSI=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src=' $item
    sed -i -e 's=$(WM_THIRD_PARTY_DIR)/packages/eigen3=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src/ThirdParty/eigen3=' $item
done

# 安装 ParaFEM
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

# 安装 OpenFPCI
cd ~
git clone https://github.com/SPHewitt/OpenFPCI.git

export PARAFEM_DIR=~/ParaFEM/parafem
export FOAM_DIR=~/foam/foam-extend-4.0

cd ~/OpenFPCI/src
source ~/foam/foam-extend-4.0/etc/bashrc
./openfpci.sh

# 添加别名
echo "alias fe40='source ~/foam/foam-extend-4.0/etc/bashrc'" >> ~/.bashrc

echo "Installation Done!"

