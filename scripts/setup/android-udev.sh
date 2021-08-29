# https://stackoverflow.com/a/45006231/12470046
groupadd plugdev
sudo usermod -aG plugdev $USER
echo 'ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{ID_USB_INTERFACES}=="*:ff420?:*", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/99-android.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --verbose --action=add --subsystem-match=usb

