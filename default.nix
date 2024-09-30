{ stdenv
}:
stdenv.mkDerivation {
  pname = "pwm-fan-controller-micropython";
  version = "0.2.0";

  src = ./.;

  nativeBuildInputs = [];

  installPhase = ''
    mkdir --parents $out/bin
    mv main.py $out/bin/main.py
  '';
}
