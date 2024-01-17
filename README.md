# OpenFPCI

OpenFPCI: Open source FOAM to ParaFEM Coupling Interface

## Motivation

The package allows the coupling of the finite element package ParaFEM to a computational fluid dynamics package OpenFOAM-Extend. The motivation behind this coupling, is to provide a framework for which users can model fluid structure interaction problems using high performance computing services.

## Description

This package consists of ParaFEM, OpenFOAM-Extend and FSI Library. OpenFPCI can couple the three through plugins. The OpenFPCI plugings compromise a series of Fortran subroutines, that used ParaFEM's highly parallel implementation, and a C++ wrapper. 

The repositories of the three software packages are as follows:

ParaFEM: https://sourceforge.net/projects/parafem/

OpenFOAM-Extend: https://openfoamwiki.net/index.php/Installation/Linux/foam-extend-4.0

FSI Library: https://openfoamwiki.net/index.php/Extend-bazaar/Toolkits/Fluid-structure\_interaction


## Project tree
The project tree presents the directories within OpenFPCI. Only the src/solidSolvers/paraFEM directory has been expanded, as these are the important files required to install and run OpenFPCI. The table below then provides a brief description of each of the directories in the project tree, in particular those within [src/solidSolvers/paraFEM](./src/solidSolvers/paraFEM)

 * [doc](./doc)
 * [README.md](./README.md)
 * [run](./run)
 * [src](./src)
   * [fluidSolvers](./src/fluidSolvers)
   * [openfpci.sh](./src/openfpci.sh)
   * [solidSolvers](./src/solidSolvers)
     * [paraFEM](./src/solidSolvers/paraFEM)
       * [fem_routines](./src/solidSolvers/paraFEM/fem_routines)
         * [parafeml.f90](./src/solidSolvers/paraFEM/fem_routines/parafeml.f90)
         * [parafemnl.f90](./src/solidSolvers/paraFEM/fem_routines/parafemnl.f90)
         * [parafemutils.f90](./src/solidSolvers/paraFEM/fem_routines/parafemutils.f90)
       * [largeStrain](./src/solidSolvers/paraFEM/largeStrain)
         * [femLargeStrain.C](./src/solidSolvers/paraFEM/largeStrain/femLargeStrain.C)
         * [femLargeStrain.H](./src/solidSolvers/paraFEM/largeStrain/femLargeStrain.H)
         * [femLargeStrainSolve.C](./src/solidSolvers/paraFEM/largeStrain/femLargeStrainSolve.C)
         * [updateForce.H](./src/solidSolvers/paraFEM/largeStrain/updateForce.H)
       * [smallStrain](./src/solidSolvers/paraFEM/smallStrain)
         * [femSmallStrain.C](./src/solidSolvers/paraFEM/smallStrain/femSmallStrain.C)
         * [femSmallStrain.H](./src/solidSolvers/paraFEM/smallStrain/femSmallStrain.H)
         * [femSmallStrainSolve.C](./src/solidSolvers/paraFEM/smallStrain/femSmallStrainSolve.C)
         * [updateForce.H](./src/solidSolvers/paraFEM/smallStrain/updateForce.H)
        
| Directory     | Purpose       |
| ------------- | ------------- |
| [doc](./doc)  | It contains the documentation for the current and previous version of OpenFPCI, created using robodoc. |
| [run](./run)  | It contains example test cases. |
| [HronTurek](./run/HronTurek)  | This is the validation test case, based of the Turek and Hron benchmark. |
| [src](./src)  | It contains two directories and a script. `SolidSolvers` contains the OpenFPCI files whilst `fluidSolvers` contains user implemented fluidSolvers for the FSI library. These are not required for OpenFPCI but add additional capabilites. |
| [openfpci.sh](./src/openfpci.sh)  | This is the installation script, that can be run to install OpenFPCI |
| [fem_routines](./src/solidSolvers/paraFEM/fem_routines)  | It contains the Fortran files that are used to solve specific engineering problems. The suffix `parafem` is followed by the files purpose. `parafeml.f90` is used to solve the deformation of a linear elastic material undergoing small strain. `parafemnl.90` is used to solve the deformation of a linear elastic material undergoing large strain and `parafemutil.f90` contains useful subroutines for debugging, I/O and adding external loads. |
| [largeStrain](./src/solidSolvers/paraFEM/largeStrain)  | It contains the C++ class files (.H and .C) that act as a wrapper around the `parafemnl.f90` Fortran file. |
| [smallStrain](./src/solidSolvers/paraFEM/smallStrain)  | It contains the C++ class files (.H and .C) that act as a wrapper around the `parafeml.f90` Fortran file. |

## Installation 

The OpenFPCI installation process now works with Docker. Installing from a Docker Image will simplify installation. Moreover, all operating environments have been configured.
### Install from Docker Image

#### Installation of Docker

Please follow the Docker Docs: https://docs.docker.com/get-docker/
If you install Docker on a Linux operating system, please also refer to the above link.

#### Windows Subsystem

Installation of WSL2 and Ubuntu Subsystem refer to: https://learn.microsoft.com/en-us/windows/wsl/about

The Windows subsystem can be installed via the Microsoft Store as Ubuntu 22.04 LTS. At the same time, Windows systems need to install WSL. To adjust the default to WSL2, please refer to this link: https://learn.microsoft.com/en-us/windows/wsl/install

#### Installation

1. Open Docker Desktop, refer to Settings > Resources > WSL integration > Enable integration with additional distros: Make sure this option is turned on and the Windows Subsystem that your installed is detected. (If you are running Docker Desktop on Linux System, please go to step 2.)
2. Open Windows Subsystem(Ubuntu)/ Linux Terminal. Run 'docker pull jacthyli/openfpci' in Terminals. To run a Docker Image in Docker Desktop, please refer to: https://docs.docker.com/guides/walkthroughs/run-hub-images/.
3. After Pulling is completed, users can see the image that has been pulled to the local in Docker Desktop. Users can run the command 'docker exec -it Docker_Name_or_ID /bin/bash' to interact the OpenFPCI in Terminal. Docker command line docs refer to: https://docs.docker.com/engine/reference/commandline/cli/

### Install from Source Code
Foam-Extend and ParaFEM must be downloaded and compiled prior to the installation of the OpenFPCI link. It is suggested that users follow the links provided above to install the relevent pacakges suitable for their systems. Once these packages have been compiled and installed the OpenFPCI can be downloaded using the following command: 
```
git clone https://github.com/SPHewitt/OpenFPCI
```

The third-party FSI library and OpenFPCI can be downloaded and compiled using the openfpci.sh script present in the src directory. The script assumes that both Foam-Extend and ParaFEM are installed with the system OpenMPI. The following command can be followed to install the software, where the paths should be replaced:

```
echo "export PARAFEM_DIR=path/to/parafem-code/parafem" >> ~/.bashrc
echo "export FOAM_DIR=path/to/foam/foam-extend-x.x" >> ~/.bashrc
. ~/.bashrc
cd OpenFPCI/src
./openfpci.sh
```

The software has been tested with Foam-Extend-4.0 and ParaFEM.5.0.3 on a linux desktop running Ubuntu 16.04. The code has further been tested to The Computational Shared Facility at Manchester, the SGI system in Leeds (Polaris), The XC30 Cray system in Ediburugh (Archer) and the Tianhe2 Machine in Guangzhou China.

The modules used on each of the systens is summarised below: 

### Linux Desktop

On a linux desktop the code uses openmpi-1.6.5 if another mpi package exists i.e. mpich the script will fail.  

Prerequisites:

* OpenMPI: Version 1.6.5 .
* GCC compilers: gcc 5.x .
* Ubuntu 16.04

### Manchester Computational Facility

The application has been tested with gnu/4.9.1 package and system openmpi version 1.6.5. The default compilers on the system are intel so these need to be swapped for the gnu compilers. 

```
module load mpi/gcc/openmpi/1.8-ib

module load compilers/gcc/4.9.0
```

### SGI - N8 Polaris (Leeds)

The application has been tested with gnu/4.9.1 package and system openmpi version 1.6.5. The default compilers on the system are intel so these need to be swapped for the gnu compilers.

```
module swap intel/"version" gnu/4.9.1

module load openmpi/1.6.5

```

### XC30 -  Archer (Edinburgh)

```
module swap PrgEnv-cray PrgEnv-gnu/5.1.29

module swap gcc/6.3.0 gcc/5.3.0

```

## Contact

For any assistance please contact sam.hewitt@manchester.ac.uk
