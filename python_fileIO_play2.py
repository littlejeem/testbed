#!/usr/bin/env python3

import os
import subprocess
# use copyfile2 from shutil package
from shutil import copy2
from os import path
from shlex import split
import sys
from pathlib import Path

data_folder = Path("/usr/local/bin/")
config_file = Path("config.con")
file_to_open = data_folder / config_file

print(sys.path)

if path.exists(file_to_open):
    print("config file found at:", file_to_open)
    import configparser
    cfg = configparser.RawConfigParser()
    cfg.read(file_to_open)       # Read file
    par=dict(cfg.items("Settings"))
    for p in par:
        par[p]=par[p].split("#",1)[0].strip() # To get rid of inline comments
        par[p]=par[p].strip('"')
    globals().update(par)  #Make them availible globally
    print ("Source folder is:", src_name)
    print ("Destination folder is:", dest_name)
    print ("Parent directory is:", parent_dir)
else:
    print("there was an issue locating the config file, are you sure the path:", file_to_open, "is correct?")
