_: {
  config = {
    programs = {
      actionlint.enable = true;
      jsonfmt.enable = true;
      just.enable = true;
      # todo
      # mypy.enable = true;
      nixfmt.enable = true;
      ruff-check.enable = true;
      ruff-format.enable = true;
      statix.enable = true;
      taplo.enable = true;
      typos.enable = true;
      yamlfmt.enable = true;
    };
    settings.formatter.typos.excludes = [
      "*.avif"
      "*.bmp"
      "*.gif"
      "*.jpeg"
      "*.jpg"
      "*.png"
      "*.svg"
      "*.tiff"
      "*.webp"
      ".vscode/settings.json"
    ];
    projectRootFile = "flake.nix";
  };
}
