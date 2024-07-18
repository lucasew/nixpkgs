# Temporarily avoid dependency on dotnetbuildhelpers to avoid rebuilding many times while working on it

{ lib, stdenv, fetchFromGitHub, mono, pkg-config, dotnetbuildhelpers, autoconf, automake, which, gitUpdater, buildDotnetModule, dotnetCorePackages, writeShellScriptBin, callPackage }:

let
  noop = writeShellScriptBin "noop" ''
    echo noop: "$@" >&2
  '';

  fsharpBootstrap = callPackage ./bootstrap.nix {};
in

buildDotnetModule rec {
  pname = "fsharp";
  version = "12.8.0";

  src = fetchFromGitHub {
    owner = "dotnet";
    repo = "fsharp";
    rev = "v${version}";
    sha256 = "sha256-vpntjsh9iIziJgRmXHfxDDC/C9sfU2ssuFdnBh2qgIw=";
  };

  projectFile = "FSharp.sln";

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  nugetDeps = ./deps.nix;

  postPatch = ''
    patchShebangs ./build.sh ./eng/*.sh
    mkdir -p .dotnet
    echo true > .dotnet/dotnet-install.sh
    ln -s $(which dotnet) .dotnet/dotnet
    # export "_InitializeDotNetCli=$(realpath $(which dotnet)/../..)"
    # env
    # exit 1

    # substituteInPlace eng/build.sh \
    #   --replace-warn '. "$scriptroot/common/tools.sh"' ""

    # substituteInPlace eng/common/tools.sh \
    #   --replace-warn wget ${lib.getExe noop}
  '';

  preBuild = ''
    for proj in fslex fsyacc; do
      find -type f -name $proj.dll
      dotnet build buildtools/$proj/$proj.fsproj
      mkdir -p artifacts/Bootstrap/$proj
      ln -s artifacts/obj/$proj/**/$proj.dll artifacts/Bootstrap/$proj
    done
    echo chegou aqui
    ./build.sh --bootstrap --restore
    # ./build.sh
    # dotnet publish $(pwd)/proto.proj /restore /p:Configuration=Proto /p:ArcadeBuildFromSource=true
  '';

  nativeBuildInputs = [ pkg-config autoconf automake noop fsharpBootstrap ];
  buildInputs = [ mono dotnetbuildhelpers which ];

  # configurePhase = ''
  #   sed -i '988d' src/FSharpSource.targets
  #   substituteInPlace ./autogen.sh --replace "/usr/bin/env sh" "${stdenv.shell}"
  #   ./autogen.sh --prefix $out
  # '';

  # # Make sure the executables use the right mono binary,
  # # and set up some symlinks for backwards compatibility.
  # postInstall = ''
  #   substituteInPlace $out/bin/fsharpc --replace " mono " " ${mono}/bin/mono "
  #   substituteInPlace $out/bin/fsharpi --replace " mono " " ${mono}/bin/mono "
  #   substituteInPlace $out/bin/fsharpiAnyCpu --replace " mono " " ${mono}/bin/mono "
  #   ln -s $out/bin/fsharpc $out/bin/fsc
  #   ln -s $out/bin/fsharpi $out/bin/fsi
  #   for dll in "$out/lib/mono/4.5"/FSharp*.dll
  #   do
  #     create-pkg-config-for-dll.sh "$out/lib/pkgconfig" "$dll"
  #   done
  # '';

  # To fix this error when running:
  # The file "/nix/store/path/whatever.exe" is an not a valid CIL image
  dontStrip = true;

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
    ignoredVersions = ["beta"];
  };

  meta = {
    description = "Functional CLI language";
    homepage = "https://fsharp.org/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ thoughtpolice raskin ];
    platforms = with lib.platforms; unix;
  };
}
