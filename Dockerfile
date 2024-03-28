FROM ubuntu:16.04
RUN apt-get -y update && apt-get -y install git-core \
			build-essential \
			binutils-dev \
			cmake \
			flex \
			zlib1g-dev \
			qt4-dev-tools \
			libqt4-dev \
			libncurses5-dev \
			libiberty-dev \
			libxt-dev \
			rpm \
			mercurial \
			graphviz \
			python \
			python-dev\
			wget \
			nano \ 
			gfortran
WORKDIR /home/user
RUN mkdir foam
WORKDIR /home/user/foam 
RUN git clone git://git.code.sf.net/p/foam-extend/foam-extend-4.0
WORKDIR /home/user/foam/foam-extend-4.0
SHELL ["/bin/bash", "-c"]
RUN echo export WM_THIRD_PARTY_USE_BISON_27=1  >> etc/prefs.sh
WORKDIR /home/user/foam/foam-extend-4.0 
RUN source etc/bashrc
# RUN fe40
WORKDIR /home/user/foam/foam-extend-4.0/ThirdParty/rpmBuild/SPECS
RUN sed -i '143s/--disable-mpi-f90/--enable-mpi-f90/' openmpi-1.8.8.spec && sed -i '143 a\        FC=gfortran \\' openmpi-1.8.8.spec
WORKDIR /home/user/foam/foam-extend-4.0/src/finiteVolume/finiteVolume/fvSchemes
RUN sed -i '382,394 s/^\(\s*\)\/\/ /\1/' fvSchemes.C
WORKDIR /home/user/foam/foam-extend-4.0/ThirdParty
RUN sed -i 's|http://portal.nersc.gov/project/visit/third_party/libccmio-2.6.1.tar.gz|https://sourceforge.net/projects/foam-extend/files/ThirdParty/libccmio-2.6.1.tar.gz|' AllMake.stage3
RUN sed -i 's|http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz|https://www.cp2k.org/static/downloads/parmetis-4.0.3.tar.gz|' AllMake.stage3
WORKDIR /home/user/foam/foam-extend-4.0
ENV PARAVIEW_SYSTEM=0
ENV HOME /home/user
RUN source /home/user/foam/foam-extend-4.0/etc/bashrc && ./Allwmake.firstInstall > OpenFoam_Extend_40_log.txt 2>&1 
RUN source /home/user/foam/foam-extend-4.0/etc/bashrc && mkdir -p $WM_PROJECT_USER_DIR && mkdir -p $FOAM_RUN
WORKDIR /home/user/foam/root-4.0
RUN wget https://openfoamwiki.net/images/d/d6/Fsi_40.tar.gz && tar -xzf Fsi_40.tar.gz
WORKDIR ./FluidSolidInteraction/src/fluidSolidInteraction/fluidSolvers/finiteVolume/RBFMeshMotionSolver/
RUN sed -i '9 a #include <vector>' RBFMeshMotionSolver.C
WORKDIR /home/user/foam/root-4.0/FluidSolidInteraction/src
RUN source /home/user/foam/foam-extend-4.0/etc/bashrc && ./Allwmake > FSI_log.txt 2>&1
WORKDIR /home/user/foam/root-4.0/FluidSolidInteraction
RUN find run -name options | while read item; do \
    sed -i -e 's=$(WM_PROJECT_DIR)/applications/solvers/FSI=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src=' $item && \
    sed -i -e 's=$(WM_THIRD_PARTY_DIR)/packages/eigen3=$(WM_PROJECT_USER_DIR)/FluidSolidInteraction/src/ThirdParty/eigen3=' $item; \
done
WORKDIR /home/user
RUN git clone https://github.com/ParaFEM/ParaFEM.git
WORKDIR /home/user/ParaFEM/parafem/build
RUN sed -i 's/FC=\/usr\/bin\/mpif90/FC=mpif90/' linuxdesktop.inc
WORKDIR /home/user/ParaFEM/parafem/include
RUN mkdir bem_p
WORKDIR /home/user/ParaFEM/parafem
RUN source /home/user/foam/foam-extend-4.0/etc/bashrc && ./make-parafem MACHINE=linuxdesktop > FSI_log.txt 2>&1 && echo "export PATH=~/ParaFEM/parafem/bin:$PATH" >> $HOME/.bashrc && source $HOME/.bashrc
WORKDIR /home/user
RUN git clone https://github.com/SPHewitt/OpenFPCI.git
ENV PARAFEM_DIR=/home/user/ParaFEM/parafem
ENV FOAM_DIR=/home/user/foam/foam-extend-4.0
WORKDIR /home/user/OpenFPCI/src
# RUN source /home/foam/foam-extend-4.0/etc/bashrc && ./openfpci.sh
WORKDIR /home/user
RUN echo "alias fe40='source /home/user/foam/foam-extend-4.0/etc/bashrc'" >> $HOME/.bashrc
