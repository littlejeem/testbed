#!/usr/bin/env python3

import os
import subprocess
# use copyfile2 from shutil package
from shutil import copy2
from os import path
from shlex import split
import sys

#+------------------+
#+---Opening File---+
#+------------------+
print(sys.path)

config_file="config.py"
if path.exists(config_file):
    print("config file found at:", config_file)
    from config.py import src_name, dest_name, parent_dir
    #file = open(config_file, "r")
    #print(file.read())
    #print ("Name of the file: ", file.name)
    #print ("Closed or not : ", file.closed)
    #print ("Opening mode : ", file.mode)
    #print (config_file.src_name)
    #file.close()
else:
    print("there was an issue locating the config file, are you sure the path:", config_file, "is correct?")
