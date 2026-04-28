## Common types, constants, and global variables for npsh.

import std/[os, strutils, sequtils]
import ./config

# Global CLI settings
var
  prefixOutput*: bool = false  ## Whether to prefix output with host names
  runOnAllHosts*: bool = false  ## Whether to run command on all configured hosts
  dryRun*: bool = false  ## Whether to perform a dry run (just show what would be done)
  testMode*: bool = false  ## Whether to run in test mode (execute 'true' command)
  useStdin*: bool = false  ## Whether to read from stdin and pipe to remote command
  workDir*: string = ""  ## Working directory for remote command execution
  envAll*: bool = false  ## Whether to forward all env vars to remote hosts
  noEnv*: bool = false  ## Whether to disable env var forwarding entirely

# Constants
const
  DefaultConfigPath* = getHomeDir() / ".npsh"
  TabWidth* = 8
  EnvBlacklist* = [
    "SSH_CLIENT", "SSH_CONNECTION", "SSH_TTY", "SSH_AUTH_SOCK", "SSH_AGENT_PID",
    "DISPLAY", "WINDOWID", "TERM_SESSION_ID",
    "XDG_RUNTIME_DIR", "XDG_SESSION_ID", "XDG_SEAT", "XDG_VTNR",
    "DBUS_SESSION_BUS_ADDRESS",
    "PATH", "LD_LIBRARY_PATH", "NIX_PATH",
  ]

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

proc buildEnvPrefix*(forwardAll: bool, vars: seq[string]): string =
  ## Build env var prefix string for remote command.
  var envMap: seq[(string, string)] = @[]

  if forwardAll:
    for key, val in envPairs():
      if key in EnvBlacklist or key.startsWith("NPSH_"):
        continue
      envMap.add((key, val))

  for v in vars:
    let eqPos = v.find('=')
    let key = if eqPos >= 0: v[0 ..< eqPos] else: v
    let val = if eqPos >= 0: v[eqPos + 1 .. ^1] else: getEnv(v)
    var found = false
    for i in 0 ..< envMap.len:
      if envMap[i][0] == key:
        envMap[i] = (key, val)
        found = true
        break
    if not found:
      envMap.add((key, val))

  if envMap.len == 0:
    return ""
  var parts: seq[string] = @[]
  for (key, val) in envMap:
    parts.add(quoteShell(key & "=" & val))
  return "env " & parts.join(" ") & " "
