{ python3Packages
, stdenv
, lib

# , withSystemd ? true
}:

python3Packages.buildPythonApplication rec {
  pname = "pydemo";
  version = "0.0.1";

  format = "pyproject";

  src = ./src;

  nativeBuildInputs = with python3Packages; [
    setuptools
  ];

  # propagatedBuildInputs = with python3Packages; [ ];
}
