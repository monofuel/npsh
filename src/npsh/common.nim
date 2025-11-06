## Common types, constants, and global variables for npsh.

import std/[os, strutils, sequtils]
import ./config

# Global CLI settings
var
  prefixOutput*: bool = false  ## Whether to prefix output with host names
  runOnAllHosts*: bool = false  ## Whether to run command on all configured hosts
  dryRun*: bool = false  ## Whether to perform a dry run (just show what would be done)

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

proc resolveHosts*(hostSpecs: seq[string], allHosts: seq[Host]): seq[string] =
  ## Resolve host specifications (hostnames or node IDs) to hostnames.
  result = @[]

  for spec in hostSpecs:
    var found = false
    try:
      # Try to parse as node ID
      let nodeId = parseInt(spec)
      for host in allHosts:
        if host.nodeId == nodeId:
          result.add(host.hostname)
          found = true
          break
    except ValueError:
      # Treat as hostname
      for host in allHosts:
        if host.hostname == spec:
          result.add(host.hostname)
          found = true
          break

    if not found:
      if spec[0].isDigit():
        raise newException(ValueError, "Node ID not found: " & spec)
      else:
        raise newException(ValueError, "Host not found: " & spec)
