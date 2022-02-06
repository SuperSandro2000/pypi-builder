with (import <nixpkgs> { });

mkShellNoCC {
  buildInputs = with python3Packages; [
    twine
  ];
}
