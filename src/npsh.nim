## Public interface to you library.

import
  std/[strutils, os, sequtils],
  npsh/[common, config, shell_exec]
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
    echo ""
    echo "Examples:"
    echo "  npsh 0 ls -la                    # Run 'ls -la' on node 0"
    echo "  npsh high-steel,solution-nine uptime  # Run 'uptime' on specific hosts"
    echo "  npsh -a -p df -h                 # Run 'df -h' on all hosts with prefixed output"
    echo "  npsh -a --test                   # Test SSH connectivity to all hosts"
    echo "  npsh 0,1 -d ls                   # Dry run: show what would be executed"
    echo "  echo 'script' | npsh mjolnir -i bash -s  # Pipe script to bash on single host"
    echo ""
    echo "Arguments:"
    echo "  hosts: comma-separated list of host names or node IDs (e.g., '0,1' or 'host1,host2')"
    echo "  options:"
    echo "    -a: run command on all configured hosts"
    echo "    -p, --prefix: prefix output with host names"
    echo "    -d, --dry-run: show what would be done without executing"
    echo "    -i, --stdin: read from stdin and pipe to remote command (single host only)"
    echo "    --test: test SSH connectivity by running 'true' command"
    echo "  command: command to run on remote hosts (not required with --test)"
    echo ""
    echo "Use 'npsh -h' for more help."
    quit(1)

  var hosts: seq[string]
  var hostArgIndex = -1
  var commandArgs: seq[string]

  # First pass: parse all options and collect non-option arguments
  var i = 0
  var collectingCommand = false
  while i < args.len:
    if args[i].startsWith("-") and not collectingCommand:
      case args[i]
      of "-a":
        runOnAllHosts = true
      of "-d", "--dry-run":
        dryRun = true
      of "-h", "--help":
        echo "Usage: npsh [hosts] [options] <command>"
        echo "       npsh -a [options] <command>"
        echo "       npsh -a --test"
        echo ""
        echo "Examples:"
        echo "  npsh 0 ls -la                    # Run 'ls -la' on node 0"
        echo "  npsh high-steel,solution-nine uptime  # Run 'uptime' on specific hosts"
        echo "  npsh -a -p df -h                 # Run 'df -h' on all hosts with prefixed output"
        echo "  npsh -a --test                   # Test SSH connectivity to all hosts"
        echo "  npsh 0,1 -d ls                   # Dry run: show what would be executed"
        echo "  echo 'script' | npsh mjolnir -i bash -s  # Pipe script to bash on single host"
        echo ""
        echo "Arguments:"
        echo "  hosts: comma-separated list of host names or node IDs (e.g., '0,1' or 'host1,host2')"
        echo "  options:"
        echo "    -a: run command on all configured hosts"
        echo "    -p, --prefix: prefix output with host names"
        echo "    -d, --dry-run: show what would be done without executing"
        echo "    -i, --stdin: read from stdin and pipe to remote command (single host only)"
        echo "    --test: test SSH connectivity by running 'true' command"
        echo "    -h, --help: show this help message"
        echo "  command: command to run on remote hosts (not required with --test)"
        quit(0)
      of "-p", "--prefix":
        prefixOutput = true
      of "-i", "--stdin":
        useStdin = true
      of "--test":
        testMode = true
      else:
        echo "Unknown option: ", args[i]
        quit(1)
    else:
      # Non-option argument or we're collecting command args
      if hostArgIndex == -1 and not runOnAllHosts and not collectingCommand:
        # First non-option argument is hosts
        hostArgIndex = i
      else:
        # Additional arguments are part of the command
        commandArgs.add(args[i])
        collectingCommand = true
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
    if commandArgs.len == 0:
      echo "Error: no command specified"
      quit(1)
    command = commandArgs

  # Read stdin data if stdin flag is set
  var stdinData = ""
  if useStdin:
    try:
      stdinData = stdin.readAll()
    except OSError:
      echo "Error: Failed to read from stdin: ", getCurrentExceptionMsg()
      quit(1)

  # Execute command
  if dryRun:
    executeDryRun(hosts, command, prefixOutput)
    if useStdin:
      echo "DRY RUN - Would pipe stdin data to remote command (", stdinData.len, " bytes)"
  else:
    # Convert hostnames back to Host objects for execution
    var hostObjects: seq[Host] = @[]
    for hostname in hosts:
      # Find the host object by hostname
      var found = false
      for host in allHosts:
        if host.hostname == hostname:
          hostObjects.add(host)
          found = true
          break
      if not found:
        echo "Error: Host '", hostname, "' not found in configuration"
        quit(1)

    executeOnHosts(hostObjects, command, prefixOutput, stdinData)

when isMainModule:
  main()
