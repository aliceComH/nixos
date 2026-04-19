# Liga ~/.local/share (temas KDE, etc.) ao conteúdo versionado em local/share/.
{ repoRoot, config, ... }:

let
  link = rel: config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${rel}";
in
{
  xdg.dataFile = {
    "color-schemes".source = link "local/share/color-schemes";
    "org.kde.syntax-highlighting".source = link "local/share/org.kde.syntax-highlighting";
  };
}
