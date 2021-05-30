with (import <nixpkgs> { });
mkShell {
  buildInputs = with python3Packages; [
    twine
  ];
}
