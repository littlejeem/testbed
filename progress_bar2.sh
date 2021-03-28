#!/bin/bash
#
progress_bar () {
  echo "THIS MAY TAKE A WHILE, PLEASE BE PATIENT WHILE ______ IS RUNNING..."
  printf "["
  # While process is running...
  while kill -0 $PID 2> /dev/null; do
      printf  "▓"
      sleep 1
  done
  printf "] done!"
  echo ""
}
#
sleep 45 & PID=$! #simulate a long process
progress_bar
