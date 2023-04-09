{ stdenv
, fetchFromGitHub
, nix-update-script
, lib
}:

stdenv.mkDerivation {
  pname = "unarc";
  version = "unstable-2020.06.05";

  NIX_CFLAGS_COMPILE = [
  "-Wno-unused-result"
  "-Wno-format-security"  
  "-Wno-write-strings" 
  ];

  src = fetchFromGitHub {
    owner = "xredor";
    repo = "unarc";
    sha256 = "sha256-ysOei44P3K+aA+h73DuHlgwTKqQx/Xq8z+DefB6Qhcs=";
    rev = "adc333d6cdd76d72da254cc80d766fbbcc683c95";
  };

  installPhase = ''
    mkdir -p $out/bin
    install -m755 unarc $out/bin
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Unpacker for ArC archives that is used in some installers with .bin suffix.";
    maintainers = [ lib.maintainers.lucasew ];
    license = lib.licenses.unfree;  # unspecified
  };
}
