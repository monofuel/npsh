## Public interface to you library.

import
  std/[strutils, os, sequtils],
  npsh/[common, config]
export
  common,
  config


proc main() =
  ## Main entry point for npsh command line tool.
  let args = commandLineParams()

  if args.len < 1:
    echo "Usage: npsh [hosts] [options] <command>"
    echo "       npsh -a [options] <command>"
    echo "  hosts: comma-separated list of host names or node IDs (e.g., '0,1' or 'host1,host2')"
    echo "  options:"
    echo "    -a: run command on all configured hosts"
    echo "    -p, --prefix: prefix output with host names"
    echo "    -d, --dry-run: show what would be done without executing"
    echo "  command: command to run on remote hosts"
    quit(1)

  var hosts: seq[string]
  var commandStart = 0

  # First pass: parse options that don't require arguments
  var i = 0
  while i < args.len:
    if args[i].startsWith("-"):
      case args[i]
      of "-a":
        runOnAllHosts = true
        commandStart = i + 1
      of "-d", "--dry-run":
        dryRun = true
        commandStart = i + 1
      of "-p", "--prefix":
        prefixOutput = true
        commandStart = i + 1
      else:
        echo "Unknown option: ", args[i]
        quit(1)
    else:
      # Found first non-option argument
      break
    i += 1

  # Load all hosts to resolve hostnames/node IDs
  let allHosts = loadConfig()

  # Handle host specification
  if runOnAllHosts:
    # Use all hosts
    hosts = allHosts.mapIt(it.hostname)
  else:
    # Expect host list as first non-option argument
    if i >= args.len:
      echo "Error: no hosts specified (use -a for all hosts)"
      quit(1)
    let hostSpecs = parseHosts(args[i])
    if hostSpecs.len == 0:
      echo "Error: no hosts specified"
      quit(1)
    # Resolve host specifications to actual hostnames
    hosts = resolveHosts(hostSpecs, allHosts)
    commandStart = i + 1

  # Everything after commandStart is the command
  if commandStart >= args.len:
    echo "Error: no command specified"
    quit(1)

  let command = args[commandStart..^1]

  # Execute or show dry run
  if dryRun:
    echo "DRY RUN - Would execute: ", command.join(" ")
    echo "DRY RUN - On hosts: ", hosts.join(", ")
    echo "DRY RUN - Prefix output: ", prefixOutput
  else:
    # TODO: Execute command on hosts
    echo "Would execute: ", command.join(" ")
    echo "On hosts: ", hosts.join(", ")
    echo "Prefix output: ", prefixOutput

when isMainModule:
  main()