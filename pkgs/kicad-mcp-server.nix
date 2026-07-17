# KiCad MCP server — Model Context Protocol server for KiCad PCB design.
#
# Builds https://github.com/Finerestaurant/kicad-mcp-python from source,
# substituting the Poetry-managed kicad-python path dependency with the
# nixpkgs python3Packages.kicad-python package.
#
# Runtime requirements:
#   - KiCad must be running with IPC enabled (Tools → External Plugin → Start Server)
#   - KICAD_CLI_PATH is set automatically to the kicad-cli from the kicad package
#   - PCB_PATHS must be set by the caller (comma-separated .kicad_pcb paths)

{
  lib,
  fetchFromGitHub,
  python3Packages,
  kicad,
  makeWrapper,
}:

python3Packages.buildPythonApplication {
  pname = "kicad-mcp-server";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "Finerestaurant";
    repo = "kicad-mcp-python";
    rev = "main";
    hash = "sha256-o4nHa4As/OIC1FWbbZZmzvmDe1xRvqEKhHT9TAd0ako=";
  };

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeBuildInputs = [ makeWrapper ];

  # Replace Poetry dependencies with nixpkgs equivalents.
  # The upstream pyproject.toml declares kicad-python as a path dependency
  # (Git submodule); we substitute the nixpkgs package instead.
  dependencies = with python3Packages; [
    kicad-python
    python-dotenv
    mcp
    cairosvg
  ];

  # Rewrite pyproject.toml from Poetry format to plain setuptools.
  # The upstream uses Poetry with kicad-python as a Git-submodule path
  # dependency; we substitute nixpkgs packages instead via the `dependencies`
  # attribute above, so we strip all Poetry-specific declarations.
  # Also add a packages declaration so setuptools discovers the
  # kicad_mcp_python package, and add a __main__.py so the server can be
  # launched via `python -m kicad_mcp_python`.
  postPatch = ''
    cat > pyproject.toml <<EOF
    [project]
    name = "kicad-mcp-server"
    version = "0.1.0"
    description = "MCP server for KiCad PCB design automation"
    requires-python = ">=3.10"
    dependencies = [
      "kicad-python",
      "python-dotenv>=1.0.0",
      "mcp>=1.9.3",
      "cairosvg>=2.7",
    ]

    [tool.setuptools.packages.find]
    include = ["kicad_mcp_python*"]

    [build-system]
    requires = ["setuptools"]
    build-backend = "setuptools.build_meta"
    EOF

    # Add a __main__.py so the server can be launched as a module.
    cat > kicad_mcp_python/__main__.py <<EOF
    from kicad_mcp_python.server import create_server

    if __name__ == "__main__":
        server = create_server()
        server.run(transport="stdio")
    EOF
  '';

  # No test suite shipped in the repo that runs without a live KiCad session.
  doCheck = false;

  # Create a bin/kicad-mcp-server wrapper that invokes the package's
  # __main__ entry point with the correct Python interpreter and the
  # kicad-cli path baked in. PCB_PATHS is left unset; set it per-project
  # in Zed's project settings or a project-local .env file.
  postInstall = ''
    mkdir -p $out/bin
    makeWrapper ${python3Packages.python}/bin/python $out/bin/kicad-mcp-server \
      --prefix PYTHONPATH : "$PYTHONPATH:$(echo "$out"/lib/python*/site-packages)" \
      --set KICAD_CLI_PATH ${kicad}/bin/kicad-cli \
      --add-flags -m \
      --add-flags kicad_mcp_python
  '';

  meta = {
    description = "MCP server for KiCad PCB design automation via the official IPC API";
    homepage = "https://github.com/Finerestaurant/kicad-mcp-python";
    license = lib.licenses.mit;
  };
}
