{
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "pwm-fan-controller-micropython";
  version = "0.2.0";

  src = ./.;

  installPhase = ''
    runHook preInstall
    install -D --mode=0644 --target-directory=$out/bin main.py
    runHook postInstall
  '';
}
