#!/usr/bin/env python3
#
#
print("Importing modules")
# importing os module
import os
# use copyfile2 from shutil package
from shutil import copy2

print("setting functions")
#define functions
def check_dest():
    # Print the name of the OS
    print(os.name)
#Check for item existence and type
    print("Item exists:" + str(path.exists(dest_path)))
    print("Item is a file: " + str(path.isfile(dest_path)))
    print("Item is a directory: " + str(path.isdir(dest_path)))

print("setting variables")
# set directory variables
# variables dont need a special charachter like $ to use them
src_name = "mysourcefolder"
print("src_name =", src_name)
dest_name = "sasquatch"
print("dir_name =", dest_name)
parent_dir = "/tmp"
print("parent_dir =", parent_dir)


# record source/dest path from constituent variables
src_path = os.path.join(parent_dir, src_name)
print("joined source path would be", src_path)
dest_path = os.path.join(parent_dir, dest_name)
print("joined destination path would be", dest_path)

if __name__ == "__check_dest__":
    check_dest()


#create the destination path
print("Oh shit here we go... creating dest_path", dest_path)

#try:
#    os.mkdir(dest_path)
#except OSError as error:
#    print(error)
#    exit

os.mkdir(dest_path)


#copy folder
print("copying from src_path: %s to dest_path: %s" %(src_path,dest_path))
copy2(src_path, dest_path)
