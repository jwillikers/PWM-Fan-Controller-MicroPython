_: [
  (_self: super: {
    # Build MicroPython for the rp2-pico
    micropython = super.micropython.overrideAttrs (prevAttrs: {
      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
        super.cmake
        super.gcc-arm-embedded
      ];
      dontUseCmakeConfigure = true;
      doCheck = false;
      makeFlags = [
        "-C"
        "ports/rp2"
      ];
      installPhase = ''
        runHook preInstall
        mkdir --parents $out/bin
        install -Dm755 ports/rp2/build-RPI_PICO/firmware.uf2 $out/bin/RPI_PICO.uf2
        runHook postInstall
      '';
    });
  })
]
