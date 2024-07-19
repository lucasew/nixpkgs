# Temporarily avoid dependency on dotnetbuildhelpers to avoid rebuilding many times while working on it

{ lib, stdenv, gitMinimal, fetchFromGitHub, mono, pkg-config, dotnetbuildhelpers, autoconf, automake, which, gitUpdater, buildDotnetModule, dotnetCorePackages, writeShellScriptBin, callPackage, dos2unix }:

let
  noop = writeShellScriptBin "noop" ''
    echo noop: "$@" >&2
  '';

in

buildDotnetModule rec {
  pname = "fsharp";
  version = "12.8.0";

  src = fetchFromGitHub {
    owner = "dotnet";
    repo = "fsharp";
    rev = "v${version}";
    fetchSubmodules = true;
    deepClone = true;
    leaveDotGit = true;
    hash = "sha256-dSucTf9FrH0Om4zA85YcMSrWxFevrdGwgQKm68cBdRU=";
  };

  projectFile = "FSharp.sln";

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  nugetDeps = ./deps.nix;

  postPatch = ''
    # dos2unix ../**/*.bsl
    # dos2unix tests/**/*.bsl $HOME/.nuget/**/*.bsl
    patchShebangs ./build.sh ./eng/*.sh
    # mkdir -p .dotnet
    # echo true > .dotnet/dotnet-install.sh
    # ln -s $(which dotnet) .dotnet/dotnet

    # mkdir -p artifacts/source-build/self/src/.dotnet
    # ln -s $(which dotnet) artifacts/source-build/self/src/.dotnet/dotnet
    # echo true > artifacts/source-build/self/src/.dotnet/dotnet-install.sh

    # git config --global core.autocrlf true # this is causing some errors
    # git config --global advice.detachedHead false

    # export "_InitializeDotNetCli=$(realpath $(which dotnet)/../..)"
    echo env
    env
    # exit 1

    # substituteInPlace eng/build.sh \
    #   --replace-warn '. "$scriptroot/common/tools.sh"' ""

    substituteInPlace eng/common/tools.sh \
      --replace-warn wget ${lib.getExe noop}
  '';

  preBuild = ''
    # for proj in fslex fsyacc; do
    #   find -type f -name $proj.dll
    #   dotnet build buildtools/$proj/$proj.fsproj
    #   mkdir -p artifacts/Bootstrap/$proj
    #   ln -s artifacts/obj/$proj/**/$proj.dll artifacts/Bootstrap/$proj
    # done
    git add -A

    mkdir -p .dotnet
    ln -s $(which dotnet) .dotnet/dotnet
    echo true > .dotnet/dotnet-install.sh

    {
      echo '('
      echo 'cd $destDir'
      echo 'echo chegou em $destDir'
      echo 'pwd'
      echo 'mkdir -p .dotnet'
      echo 'ln -s $(which dotnet) .dotnet/dotnet'
      echo 'echo true > .dotnet/dotnet-install.sh'
      echo ')'
    } >> $HOME/.nuget/packages/microsoft.dotnet.arcade.sdk/8.0.0-beta.23463.1/tools/SourceBuild/git-clone-to-dir.sh

    patchShebangs $HOME/.nuget/packages/microsoft.dotnet.arcade.sdk/8.0.0-beta.23463.1/tools/SourceBuild/git-clone-to-dir.sh
    cat $HOME/.nuget/packages/microsoft.dotnet.arcade.sdk/8.0.0-beta.23463.1/tools/SourceBuild/git-clone-to-dir.sh
    # ln -sf ${lib.getExe noop} $HOME/.nuget/packages/microsoft.dotnet.arcade.sdk/8.0.0-beta.23463.1/tools/SourceBuild/git-clone-to-dir.sh
    # mkdir -p artifacts/source-build/self
    # ln -s $(realpath .) artifacts/source-build/self/src

    echo chegou aqui
    ./build.sh --restore /p:ArcadeBuildFromSource=true --bootstrap 
    # ./build.sh
    # dotnet publish $(pwd)/proto.proj /restore /p:Configuration=Proto /p:ArcadeBuildFromSource=true
  '';

  nativeBuildInputs = [
    pkg-config
    # autoconf
    # automake
    noop
    gitMinimal
    dos2unix
    # fsharpBootstrap
  ];
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

  passthru = {
    updateScript = gitUpdater {
      rev-prefix = "v";
      ignoredVersions = ["beta"];
    };
  };

  meta = {
    description = "Functional CLI language";
    homepage = "https://fsharp.org/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ thoughtpolice raskin ];
    platforms = with lib.platforms; unix;
  };
}
