## Common types, constants, and global variables for npsh.

import std/[os, strutils, sequtils]

# Global CLI settings
var
  prefixOutput*: bool = false  ## Whether to prefix output with host names

# Constants
const
  DefaultConfigPath* = getHomeDir() / ".npsh"
  TabWidth* = 8

proc parseHosts*(hostsStr: string): seq[string] =
  ## Parse comma-separated host list.
  if hostsStr.len == 0:
    result = @[]
  else:
    result = hostsStr.split(',').mapIt(it.strip())

proc formatHostPrefix*(hostname: string, maxHostLen: int): string =
  ## Format hostname prefix with proper alignment.
  hostname & " ".repeat(maxHostLen - hostname.len + TabWidth)
