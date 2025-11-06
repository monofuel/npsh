import
  std/[os, strutils]

type
  Host* = ref object
    ## Represents a host configuration for npsh.
    hostname*: string
    ip*: string
    port*: int
    username*: string

proc newHost*(hostname: string, ip = "", port = 22, username = ""): Host =
  ## Create a new Host configuration.
  Host(hostname: hostname, ip: ip, port: port, username: username)

proc parseHostLine*(line: string): Host =
  ## Parse a single line from the config file into a Host object.
  let parts = line.splitWhitespace()
  if parts.len == 0:
    return nil

  let hostname = parts[0]
  var ip = ""
  var port = 22
  var username = ""

  for part in parts[1..^1]:
    let kv = part.split('=', 1)
    if kv.len == 2:
      case kv[0]
      of "ip":
        ip = kv[1]
      of "port":
        port = parseInt(kv[1])
      of "username":
        username = kv[1]

  newHost(hostname, ip, port, username)

proc loadConfig*(configPath = ""): seq[Host] =
  ## Load configuration from file.
  ## Defaults to ~/.npsh if no path provided.
  let path = if configPath == "": getHomeDir() / ".npsh" else: configPath

  if not fileExists(path):
    return @[]

  var hosts: seq[Host] = @[]

  for line in lines(path):
    let trimmed = line.strip()
    if trimmed.len > 0 and not trimmed.startsWith('#'):
      let host = parseHostLine(trimmed)
      if host != nil:
        hosts.add(host)

  hosts
