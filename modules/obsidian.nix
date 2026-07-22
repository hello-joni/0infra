{
  programs.obsidian = {
    enable = true;

    # Vault lives at ~/0obsidian. Kept separate from the Flatpak Obsidian's vault
    # so the two installations do not share state.
    vaults."0obsidian" = {
      enable = true;
      target = "0obsidian";
    };
  };
}
