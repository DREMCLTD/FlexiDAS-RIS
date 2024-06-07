
######################################################################

SKIP THIS IF YOU ARE INSTALLING arena_api ON A 
MACHINE WITH INTERNET CONNECTION

######################################################################

On an internet connected machine these dependencies should be
installed form the internet automatically when arena_api wheel
is installed. 

Theses whl files are for installing arena_api dependencies on
devices with no internet connection.

You will only need to install one whl file from each package.
The whl file name shows if particular whl is compatible with your 
platform.

Whl name follows this pattern:
    <package_name>-<package_version>-<python_interpreter_version>-<abi_tag>-<platform>


To install a package:
    - cd to the package directory
    - run ``pip install <whl_filename>``