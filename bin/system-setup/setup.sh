#!/bin/bash

set -euo pipefail

./000_system_setup.sh
./001_install_desktop_environment.sh
./002_install_system_administration_utilities.sh
./003_install_greeter.sh
./004_install_notification_center.sh
./005_install_screen_capture_recording.sh
./006_install_virtualization.sh
./007_install_applications.sh
./008_install_developer_tooling.sh
./009_install_gaming_packages.sh
./010_install_themes.sh
./011_setup_services.sh
