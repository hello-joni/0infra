{ pkgs, ... }: {
  home.packages =
    builtins.attrValues (
      builtins.mapAttrs (
        name: _type:
        let
          cmd = pkgs.lib.strings.removeSuffix ".sh" name;
        in
        pkgs.writeShellScriptBin cmd (builtins.readFile (./scripts + "/${name}"))
      ) (builtins.readDir ./scripts)
    );
}
