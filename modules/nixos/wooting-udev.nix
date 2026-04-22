# Acesso ao teclado Wooting sem root (Wootility / firmware).
# O TAG+=uaccess sozinho nem sempre resulta em ACL (hidraw ficava crw------- root).
# MODE/GROUP garantem leitura/escrita para utilizadores no grupo "users" (padrão NixOS).
{ ... }:

{
  services.udev.extraRules = ''
    # Wooting One Legacy
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess", MODE="0660", GROUP="users"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="03eb", ATTR{idProduct}=="ff01", TAG+="uaccess", MODE="0660", GROUP="users"

    # Wooting One update mode
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess", MODE="0660", GROUP="users"

    # Wooting Two Legacy
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess", MODE="0660", GROUP="users"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="03eb", ATTR{idProduct}=="ff02", TAG+="uaccess", MODE="0660", GROUP="users"

    # Wooting Two update mode
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess", MODE="0660", GROUP="users"

    # Genérico (UwU, Two HE, 60HE+, …) — idVendor 31e3, ex. idProduct 1512 no UwU RGB
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31e3", TAG+="uaccess", MODE="0660", GROUP="users"
    SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="31e3", TAG+="uaccess", MODE="0660", GROUP="users"
  '';
}
