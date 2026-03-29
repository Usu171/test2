{ lib
, stdenv
, fetchFromGitLab
, fetchFromGitHub
, cmake
, python3
, gfortran
, gcc
, git
, mpi
, hdf5
, pkg-config
, pcmsolver
, blas
, lapack
}:

let
  pythonWithH5py = python3.withPackages (ps: with ps; [ h5py ]);



  exatensorSrc = fetchFromGitHub {
    owner = "RelMBdev";
    repo = "ExaTENSOR";
    rev = "1c363d63cbaa57b16a84b324d966af20796e3353";
    hash = "sha256-MQwnRUD0ZquUgSpGFXlAl3XThSLslBR1/eJ3/KAp91k=";
  };
in

stdenv.mkDerivation rec {
  pname = "dirac";
  version = "v26.0";

  src = fetchFromGitLab {
    owner = "dirac";
    repo = "dirac";
    rev = "v26.0";
    hash = "sha256-BZ03FjrsjxZnUZZUk05r7l7p3AmFv/s/3PpTH3+TKi8=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    git
  ];

  buildInputs = [
    gcc
    pythonWithH5py
    gfortran
    mpi
    hdf5
    pcmsolver
    blas
    lapack
  ];



  preConfigure = ''
    export MPI_HOME=${mpi.dev}
    echo "Using MPI_HOME=$MPI_HOME"

    mkdir -p external
    cp -r ${exatensorSrc} external/exatensor
    ls external
    chmod -R u+w external/exatensor
  '';

  configurePhase = ''
    runHook preConfigure
    mkdir -p build
    cd build
    cmake .. \
      -DENABLE_PCMSOLVER=ON \
      -DPCMSOLVER_ROOT=${pcmsolver} \
      -DENABLE_EXATENSOR=OFF\
      -DPYTHON_INTERPRETER=${pythonWithH5py}/bin/python
  '';

  buildPhase = ''
    make # -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    make install DESTDIR=$out
  '';

  meta = with lib; {
    description = "DIRAC is a relativistic ab initio electronic structure program";
    homepage = "https://gitlab.com/dirac/dirac";
    license = licenses.lgpl3Plus;
    maintainers = [ maintainers.usu171 ];
    platforms = platforms.linux;
  };
}
