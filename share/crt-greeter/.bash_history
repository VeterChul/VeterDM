zsh
systemctl --user enable pipewire.service pipewire.socket
systemctl --user enable wireplumber.service
systemctl --user enable pipewire-pulse.service pipewire-pulse.socket
systemctl --user start pipewire.service pipewire.socket
systemctl --user start wireplumber.service
systemctl --user start pipewire-pulse.service pipewire-pulse.socket
systemctl --user status pipewire pipewire-pulse wireplumber
exit
# 5. Устанавливаем максимальную громкость на уровне ALSA
amixer sset Master 100% unmute 2>/dev/null || true
amixer sset PCM 100% unmute 2>/dev/null || true
sudo alsactl store 2>/dev/null || true
echo "Громкость установлена на максимум"
reboot
exit
26022011
