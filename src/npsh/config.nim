import
  std/[os, strutils, tables, algorithm]

type
  Host* = ref object
    ## Represents a host configuration for npsh.
    hostname*: string
    ip*: string
    port*: int
    username*: string
    nodeId*: int

proc newHost*(hostname: string, ip = "", port = 22, username = "", nodeId = -1): Host =
  ## Create a new Host configuration.
  Host(hostname: hostname, ip: ip, port: port, username: username, nodeId: nodeId)

proc parseHostLine*(line: string): Host =
  ## Parse a single line from the config file into a Host object.
  let parts = line.splitWhitespace()
  if parts.len == 0:
    return nil

  let hostname = parts[0]
  var ip = ""
  var port = 22
  var username = ""
  var nodeId = -1

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
      of "node":
        nodeId = parseInt(kv[1])

  newHost(hostname, ip, port, username, nodeId)

proc assignNodeIds*(hosts: var seq[Host]) =
  ## Assign sequential node IDs to hosts that don't have explicit node IDs.
  ## Explicit node IDs take precedence.
  var takenIds = initTable[int, bool]()
  var nextId = 0

  # First pass: collect explicitly assigned node IDs
  for host in hosts:
    if host.nodeId >= 0:
      takenIds[host.nodeId] = true

  # Second pass: assign sequential IDs to hosts without explicit IDs
  for host in hosts.mitems:
    if host.nodeId < 0:
      while takenIds.hasKey(nextId):
        nextId += 1
      host.nodeId = nextId
      takenIds[nextId] = true
      nextId += 1

proc loadConfig*(configPath = ""): seq[Host] =
  ## Load configuration from file.
  ## Defaults to ~/.npsh if no path provided.
  let path = if configPath == "": getHomeDir() / ".npsh" else: configPath

  if not fileExists(path):
    raise newException(IOError, "Config file not found: " & path)

  var hosts: seq[Host] = @[]

  for line in lines(path):
    let trimmed = line.strip()
    if trimmed.len > 0 and not trimmed.startsWith('#'):
      let host = parseHostLine(trimmed)
      if host != nil:
        hosts.add(host)

  # Assign node IDs and sort
  assignNodeIds(hosts)
  hosts.sort(proc (a, b: Host): int = cmp(a.nodeId, b.nodeId))

  hosts
