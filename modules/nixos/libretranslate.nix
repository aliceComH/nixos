{ config, pkgs, lib, ... }:

{
  # Utiliza o backend do Docker (já ativo no sistema da Alice) para subir o LibreTranslate.
  virtualisation.oci-containers = {
    backend = "docker";
    containers.libretranslate = {
      image = "libretranslate/libretranslate:latest";
      ports = [ "5000:5000" ];
      environment = {
        # O LibreTranslate baixa os modelos de idioma no primeiro uso. 
        # Restringimos a inglês e português para acelerar o processo.
        LT_LOAD_ONLY = "en,pb";
      };
      extraOptions = [ "--pull=missing" ];
    };
  };
}
