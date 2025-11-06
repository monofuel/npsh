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
    echo "       npsh -a --test"
    echo "  hosts: comma-separated list of host names or node IDs (e.g., '0,1' or 'host1,host2')"
    echo "  options:"
    echo "    -a: run command on all configured hosts"
    echo "    -p, --prefix: prefix output with host names"
    echo "    -d, --dry-run: show what would be done without executing"
    echo "    --test: test SSH connectivity by running 'true' command"
    echo "  command: command to run on remote hosts (not required with --test)"
    quit(1)

  var hosts: seq[string]
  var hostArgIndex = -1

  # First pass: parse all options and find host argument
  var i = 0
  while i < args.len:
    if args[i].startsWith("-"):
      case args[i]
      of "-a":
        runOnAllHosts = true
      of "-d", "--dry-run":
        dryRun = true
      of "-p", "--prefix":
        prefixOutput = true
      of "--test":
        testMode = true
      else:
        echo "Unknown option: ", args[i]
        quit(1)
    else:
      # Found first non-option argument - this should be the hosts
      if hostArgIndex == -1:
        hostArgIndex = i
      # Keep processing in case there are more options after hosts
    i += 1

  # Load all hosts to resolve hostnames/node IDs
  let allHosts = loadConfig()

  # Handle host specification
  if runOnAllHosts:
    # Use all hosts
    hosts = allHosts.mapIt(it.hostname)
  else:
    # Expect host list as the identified host argument
    if hostArgIndex == -1:
      echo "Error: no hosts specified (use -a for all hosts)"
      quit(1)
    let hostSpecs = parseHosts(args[hostArgIndex])
    if hostSpecs.len == 0:
      echo "Error: no hosts specified"
      quit(1)
    # Resolve host specifications to actual hostnames
    hosts = resolveHosts(hostSpecs, allHosts)

  # Determine the command
  var command: seq[string]
  if testMode:
    # In test mode, use 'true' command
    command = @["true"]
  else:
    # Command starts after the host argument (if any)
    var commandStart = if hostArgIndex >= 0: hostArgIndex + 1 else: 0

    if commandStart >= args.len:
      echo "Error: no command specified"
      quit(1)
    command = args[commandStart..^1]

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