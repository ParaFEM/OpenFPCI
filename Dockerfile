# syntax=docker/dockerfile:1

# Build on top of the image that already contains your manually installed
# foam-extend, OpenFPCI/fsiFoam, ParaFEM and ThirdParty packages.
#
# Example:
# docker build \
#   --build-arg BASE_IMAGE=jacthyli/openfpci:Archer2 \
#   --build-arg IMAGE_USER=openfpci \
#   --build-arg OPENFPCI_HOME=/home/openfpci \
#   --build-arg USER_PROJECT=openfpci-4.0 \
#   -f dockerfile \
#   -t jacthyli/openfpci:Archer2_ENV .

ARG BASE_IMAGE=jacthyli/openfpci:Archer2
FROM ${BASE_IMAGE}

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG IMAGE_USER=openfpci
ARG OPENFPCI_HOME=/home/openfpci
ARG USER_PROJECT=openfpci-4.0
ARG FOAM_VERSION=4.0
ARG WM_OPTIONS=linux64GccDPOpt

# ---------------------------------------------------------------------------
# Core OpenFOAM / OpenFPCI locations
# ---------------------------------------------------------------------------
ENV OPENFPCI_IMAGE_USER=${IMAGE_USER}
ENV OPENFPCI_HOME=${OPENFPCI_HOME}
ENV FOAM_VERSION=${FOAM_VERSION}
ENV WM_OPTIONS=${WM_OPTIONS}

ENV MPI_BUFFER_SIZE=20000000

ENV FOAM_ROOT=${OPENFPCI_HOME}/foam
ENV WM_PROJECT=foam
ENV WM_PROJECT_VERSION=${FOAM_VERSION}
ENV WM_PROJECT_INST_DIR=${OPENFPCI_HOME}/foam
ENV WM_PROJECT_DIR=${OPENFPCI_HOME}/foam/foam-extend-${FOAM_VERSION}
ENV WM_PROJECT_USER_DIR=${OPENFPCI_HOME}/foam/${USER_PROJECT}
ENV FOAM_SITE_DIR=${OPENFPCI_HOME}/foam/site/${FOAM_VERSION}
ENV PARAFEM_ROOT=${OPENFPCI_HOME}/ParaFEM/parafem

ENV FOAM_APPBIN=${WM_PROJECT_DIR}/applications/bin/${WM_OPTIONS}
ENV FOAM_LIBBIN=${WM_PROJECT_DIR}/lib/${WM_OPTIONS}
ENV FOAM_USER_APPBIN=${WM_PROJECT_USER_DIR}/applications/bin/${WM_OPTIONS}
ENV FOAM_USER_LIBBIN=${WM_PROJECT_USER_DIR}/lib/${WM_OPTIONS}
ENV FOAM_SITE_APPBIN=${FOAM_SITE_DIR}/bin/${WM_OPTIONS}
ENV FOAM_SITE_LIBBIN=${FOAM_SITE_DIR}/lib/${WM_OPTIONS}

# ---------------------------------------------------------------------------
# Clean container PATH
#
# Windows / WSL paths from the development machine are deliberately excluded.
# The first directory is the user application directory that should contain
# the manually compiled fsiFoam executable.
# ---------------------------------------------------------------------------
ENV PATH=${FOAM_USER_APPBIN}:${FOAM_SITE_APPBIN}:${FOAM_APPBIN}:${WM_PROJECT_DIR}/wmake:${WM_PROJECT_DIR}/bin:${PARAFEM_ROOT}/bin:${WM_PROJECT_DIR}/ThirdParty/packages/hwloc-1.10.1/platforms/${WM_OPTIONS}/bin:${WM_PROJECT_DIR}/ThirdParty/PyFoamSiteScripts/bin:${WM_PROJECT_DIR}/ThirdParty/packages/PyFoam-0.6.4/platforms/noarch/bin:${WM_PROJECT_DIR}/ThirdParty/packages/scotch-6.0.4/platforms/${WM_OPTIONS}/bin:${WM_PROJECT_DIR}/ThirdParty/packages/mesquite-2.1.2/platforms/${WM_OPTIONS}/bin:${WM_PROJECT_DIR}/ThirdParty/packages/openmpi-1.8.8/platforms/${WM_OPTIONS}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ---------------------------------------------------------------------------
# OpenFPCI / foam-extend runtime libraries
#
# ARCHER2's Cray MPICH ABI and host libraries should still be added in the
# Slurm script. Do not bake ARCHER2 host-specific paths into this Docker image.
# ---------------------------------------------------------------------------
ENV LD_LIBRARY_PATH=${WM_PROJECT_DIR}/ThirdParty/packages/scotch-6.0.4/platforms/${WM_OPTIONS}/lib:${WM_PROJECT_DIR}/ThirdParty/packages/libccmio-2.6.1/platforms/${WM_OPTIONS}/lib:${WM_PROJECT_DIR}/ThirdParty/packages/ParMGridGen-1.0/platforms/${WM_OPTIONS}/lib:${WM_PROJECT_DIR}/ThirdParty/packages/parmetis-4.0.3/platforms/${WM_OPTIONS}/lib:${WM_PROJECT_DIR}/ThirdParty/packages/metis-5.1.0/platforms/${WM_OPTIONS}/lib:${WM_PROJECT_DIR}/ThirdParty/packages/mesquite-2.1.2/platforms/${WM_OPTIONS}/lib:${WM_PROJECT_DIR}/ThirdParty/packages/openmpi-1.8.8/platforms/${WM_OPTIONS}/lib:${FOAM_USER_LIBBIN}:${FOAM_SITE_LIBBIN}:${FOAM_LIBBIN}

# Avoid accidental OpenMP oversubscription for the current pure-MPI setup.
ENV OMP_NUM_THREADS=1

# ---------------------------------------------------------------------------
# Validate the existing installation and expose fsiFoam through /usr/local/bin.
# The build intentionally fails here when the executable is absent, which
# prevents creation of another image with a broken PATH.
# ---------------------------------------------------------------------------
RUN set -eux; \
    id "${IMAGE_USER}" >/dev/null; \
    test -d "${WM_PROJECT_DIR}"; \
    test -d "${WM_PROJECT_USER_DIR}"; \
    FSI_EXE="$(command -v fsiFoam || true)"; \
    if [[ -z "${FSI_EXE}" ]]; then \
        FSI_EXE="$(find \
            "${FOAM_USER_APPBIN}" \
            "${FOAM_SITE_APPBIN}" \
            "${FOAM_APPBIN}" \
            -maxdepth 1 \
            -type f \
            -name fsiFoam \
            -perm -u+x \
            -print -quit 2>/dev/null || true)"; \
    fi; \
    if [[ -z "${FSI_EXE}" ]]; then \
        echo "ERROR: fsiFoam was not found in the base image." >&2; \
        echo "Checked PATH=${PATH}" >&2; \
        exit 127; \
    fi; \
    echo "Using fsiFoam executable: ${FSI_EXE}"; \
    ln -sf "${FSI_EXE}" /usr/local/bin/fsiFoam; \
    command -v fsiFoam; \
    fsiFoam -help >/dev/null 2>&1 || true

# A small diagnostic command available inside Docker / Singularity.
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    'echo "OPENFPCI_HOME=$OPENFPCI_HOME"' \
    'echo "WM_PROJECT_DIR=$WM_PROJECT_DIR"' \
    'echo "WM_PROJECT_USER_DIR=$WM_PROJECT_USER_DIR"' \
    'echo "FOAM_USER_APPBIN=$FOAM_USER_APPBIN"' \
    'echo "FOAM_USER_LIBBIN=$FOAM_USER_LIBBIN"' \
    'echo "PATH=$PATH"' \
    'echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"' \
    'echo "fsiFoam=$(command -v fsiFoam || true)"' \
    > /usr/local/bin/openfpci-check \
    && chmod 0755 /usr/local/bin/openfpci-check

# Restore the non-root user used by the original image.
USER ${IMAGE_USER}

WORKDIR ${OPENFPCI_HOME}
CMD ["/bin/bash"]
