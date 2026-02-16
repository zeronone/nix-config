{
  lib,
  stdenvNoCC,
  makeWrapper,
  jq,
  gnused,
  jdt-language-server,
  lombok,
  vscode-java-debug ? null,
  vscode-java-test ? null,
}:
let
  # Resolve extension share dirs (if provided)
  debugExt =
    if vscode-java-debug != null then
      "${vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug"
    else
      null;
  testExt =
    if vscode-java-test != null then
      "${vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test"
    else
      null;
in
stdenvNoCC.mkDerivation {
  pname = "jdtls-wrapped";
  version = jdt-language-server.version;

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    jdt-language-server
    lombok
    jq
    gnused
  ]
  ++ lib.optional (vscode-java-debug != null) vscode-java-debug
  ++ lib.optional (vscode-java-test != null) vscode-java-test;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/jdtls-wrapped

    # Symlink lombok.jar into our share dir
    ln -s ${lombok}/share/java/lombok.jar $out/share/jdtls-wrapped/lombok.jar

    # Symlink vscode extension server dirs if provided
    ${lib.optionalString (debugExt != null) ''
      ln -s ${debugExt}/server $out/share/jdtls-wrapped/java-debug-adapter
    ''}
    ${lib.optionalString (testExt != null) ''
      ln -s ${testExt}/server $out/share/jdtls-wrapped/java-test
    ''}

    # Install the launcher script
    install -Dm755 ${./jdtls-launcher.sh} $out/bin/jdtls-launcher

    # Wrap the launcher with required tools on PATH and env vars baked in
    wrapProgram $out/bin/jdtls-launcher \
      --set JDTLS_WRAPPED_SHARE "$out/share/jdtls-wrapped" \
      --set JDTLS_REAL "${jdt-language-server}/bin/jdtls" \
      --set LOMBOK_JAR "$out/share/jdtls-wrapped/lombok.jar" \
      --prefix PATH : "${
        lib.makeBinPath [
          jq
          gnused
        ]
      }"

    runHook postInstall
  '';

  meta = {
    description = "JDT Language Server wrapped with lombok, debug/test bundles, and .vscode/settings.json support";
    mainProgram = "jdtls-launcher";
  };
}
