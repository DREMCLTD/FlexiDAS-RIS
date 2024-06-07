# -----------------------------------------------------------------------------
# Copyright (c) 2024, Lucid Vision Labs, Inc.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFT,lWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# -----------------------------------------------------------------------------

from pprint import pprint, PrettyPrinter
import json
import re

import arena_api
from arena_api.system import system

"""
Get DLL Version: Introduction
    The example introduces the arena api library functions to get the
    version of package, dll, and binaries.
"""
TAB1 = "  "
TAB2 = "    "
pp = PrettyPrinter()

def print_formatted_version_info(elem):

    if elem is not None:
        dict_str = json.dumps(elem, indent=2)
        lines = dict_str.splitlines(True)
        result_lines = []
        i = 0
        
        while i < len(lines):
            current_line = lines[i]

            # Handle arrays: combine lines until the closing bracket is found and format it
            if '[' in current_line:
                array_lines = [current_line.rstrip('\n')]
                while ']' not in array_lines[-1]:
                    i += 1
                    line = lines[i].rstrip('\n').strip() if ']' not in lines[i] else re.sub(r'\s*\]', r']',lines[i])
                    array_lines.append(line)
                current_line = ''.join(array_lines)

            result_lines.append(current_line)
            i += 1

        result_str = ''.join([TAB2 + line for line in result_lines])
        print(result_str)


def example_entry_point():

	# Get package version -----------------------------------------------------

	# Method 1
	print(f'{TAB1}arena_api.__version__ = {arena_api.__version__}')

	# Method 2
	#
	# the same can be obtained from 'version.py' module as well
	# Code:
	
	'''
	print(f'arena_api.version.__version__ = {arena_api.version.__version__}')
	'''

	# Get dll versions --------------------------------------------------------

	# Arena_api is a wrapper built on top of ArenaC library, so the package
	# uses 'ArenaCd_v140.dll' or libarenac.so. The ArenaC binary has different
	# versions for different platforms. Here is a way to know the minimum and
	# maximum version of ArenaC supported by the current package. This could
	# help in deciding whether to update arena_api or ArenaC.
	print(f'\n{TAB1}supported_dll_versions')
	print_formatted_version_info(arena_api.version.supported_dll_versions)

	# For the current platform, the key 'this_platform' key can be used
	print(f'\n{TAB1}supported_dll_versions for this platform')
	print_formatted_version_info(arena_api.version.supported_dll_versions['this_platform'])

	# Get loaded ArenaC and SaveC binaries versions ---------------------------

	print(f'\n{TAB1}loaded_binary_versions')
	print_formatted_version_info(arena_api.version.loaded_binary_versions)


if __name__ == '__main__':
	print('\nWARNING:\nTHIS EXAMPLE MIGHT CHANGE THE DEVICE(S) SETTINGS!')
	print('\nExample started\n')
	example_entry_point()
	print('\nExample finished successfully')
