import pathlib
import subprocess
import lldb

rustc_sysroot = subprocess.getoutput('rustc --print sysroot')
rustlib_etc = pathlib.Path(rustc_sysroot) / 'lib' / 'rustlib' / 'etc'

lldb.debugger.HandleCommand(f'command script import "{rustlib_etc / "lldb_lookup.py"}"')
lldb.debugger.HandleCommand(f'command source -s 0 "{rustlib_etc / "lldb_commands"}"')
