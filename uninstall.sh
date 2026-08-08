#!/bin/bash
systemctl --user disable --now cosmic-watch.service
rm ~/.config/systemd/user/cosmic-watch.service
rm -r ~/.local/bin/SystemWallColor
