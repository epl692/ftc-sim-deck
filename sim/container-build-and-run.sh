#!/bin/bash
# Runs INSIDE the container (working dir /sim = virtual_robot_ftc). Compiles the simulator and launches it.
set -euo pipefail

FX_MODULES=javafx.controls,javafx.fxml,javafx.swing
rm -rf out
mkdir out

echo "==> Compiling"
find Controller/src TeamCode/src -name '*.java' > /tmp/sources.txt
javac -nowarn -d out --module-path "$FX_PATH" --add-modules "$FX_MODULES" -cp "lib/*" @/tmp/sources.txt

echo "==> Copying resources"
(cd Controller/src && find . -type f ! -name '*.java' -exec cp --parents {} ../../out/ \;)
(cd TeamCode/src && find . -type f ! -name '*.java' -exec cp --parents {} ../../out/ \;)

echo "==> Launching"
exec java -Djava.library.path=/usr/lib/x86_64-linux-gnu/jni --module-path "$FX_PATH" --add-modules "$FX_MODULES" \
  -cp "out:lib/*" virtual_robot.controller.VirtualRobotApplication
