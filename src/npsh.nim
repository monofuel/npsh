## Public interface to you library.

import
  std/[strutils, os],
  npsh/[common, config]
export
  common,
  config


proc main() =
  ## Main entry point for npsh command line tool.
  let args = commandLineParams()

  if args.len < 2:
    echo "Usage: npsh <hosts> [options] <command>"
    echo "  hosts: comma-separated list of host names"
    echo "  options:"
    echo "    -p, --prefix: prefix output with host names"
    echo "  command: command to run on remote hosts"
    quit(1)

  # First argument is always the host list
  let hosts = parseHosts(args[0])

  if hosts.len == 0:
    echo "Error: no hosts specified"
    quit(1)

  # Parse options and find where command starts
  var
    commandStart = 1
    i = 1

  while i < args.len:
    if args[i].startsWith("-"):
      case args[i]
      of "-p", "--prefix":
        prefixOutput = true
      else:
        echo "Unknown option: ", args[i]
        quit(1)
      commandStart = i + 1
    else:
      # Found first non-option argument, this is the start of the command
      break
    i += 1

  if commandStart >= args.len:
    echo "Error: no command specified"
    quit(1)

  let command = args[commandStart..^1]

  # TODO: Execute command on hosts
  echo "Would execute: ", command.join(" ")
  echo "On hosts: ", hosts.join(", ")
  echo "Prefix output: ", prefixOutput

when isMainModule:
  main()