import
  std/[osproc, streams, strutils, threadpool],
  ./config, ./common

proc buildSshCommand*(host: Host, command: seq[string]): seq[string] =
  ## Build SSH command with proper options and remote command.
  var cmd = @["ssh", "-o", "BatchMode=yes"]

  # Add host connection details
  let targetHost = if host.ip.len > 0: host.ip else: host.hostname
  if host.username.len > 0:
    cmd.add(host.username & "@" & targetHost)
  else:
    cmd.add(targetHost)

  if host.port != 22:
    cmd.add("-p")
    cmd.add($host.port)

  # Add the remote command
  cmd.add(command.join(" "))

  return cmd

proc streamExecuteOnHost*(host: Host, command: seq[string], stdinData: string = "", prefix: string = ""): int =
  ## Execute command on a single host via SSH with streaming output.
  ## Returns exit code (0 for success, non-zero for failure).
  ## prefix: string to prepend to each line of output (for host identification)
  let sshCmd = buildSshCommand(host, command)

  try:
    let process = startProcess(sshCmd[0], args = sshCmd[1..^1],
                              options = {poUsePath})
    let outputStream = process.outputStream
    let errorStream = process.errorStream

    # Write stdin data if provided
    if stdinData.len > 0:
      process.inputStream.write(stdinData)
      process.inputStream.close()

    # Stream stdout line by line
    var outputLine: string
    while outputStream.readLine(outputLine):
      if prefix.len > 0:
        stdout.write(prefix)
      stdout.writeLine(outputLine)

    # Stream stderr line by line
    var errorLine: string
    while errorStream.readLine(errorLine):
      if prefix.len > 0:
        stderr.write(prefix)
      stderr.writeLine(errorLine)

    let exitCode = process.waitForExit()
    process.close()

    return exitCode
  except OSError:
    let errorMsg = "SSH connection failed: " & getCurrentExceptionMsg()
    if prefix.len > 0:
      stderr.write(prefix)
    stderr.writeLine(errorMsg)
    return -1

proc executeOnHosts*(hosts: seq[Host], command: seq[string], prefixOutput: bool, stdinData: string = ""): int =
  ## Execute command on multiple hosts concurrently with streaming output.
  ## stdinData: Data to pipe to the remote command's stdin (only works with single host)
  ## Returns: 0 if all commands succeeded, 1 if any command failed

  # Validate single host when stdin is provided
  if stdinData.len > 0 and hosts.len > 1:
    var hostNames: seq[string] = @[]
    for host in hosts:
      hostNames.add(host.hostname)
    echo "Error: stdin mode (-i) only supports single host. Specified: ", hosts.len, " hosts (", hostNames.join(", "), "). Multiple host stdin support coming in future version."
    return 1

  var maxHostLen = 0
  for host in hosts:
    maxHostLen = max(maxHostLen, host.hostname.len)

  # Spawn concurrent execution using threadpool
  var flows: seq[FlowVar[int]] = @[]

  for host in hosts:
    let prefix = if prefixOutput: formatHostPrefix(host.hostname, maxHostLen) else: ""
    let hostCopy = host # Capture host by value
    let commandCopy = command # Capture command by value
    let stdinDataCopy = stdinData # Capture stdin data by value
    let prefixCopy = prefix # Capture prefix by value

    flows.add(spawn streamExecuteOnHost(hostCopy, commandCopy, stdinDataCopy, prefixCopy))

  # Wait for all executions to complete and collect exit codes
  var overallExitCode = 0
  for flow in flows:
    let exitCode = ^flow
    if exitCode != 0:
      overallExitCode = 1

  return overallExitCode

proc executeDryRun*(hosts: seq[string], command: seq[string], prefixOutput: bool) =
  ## Show what would be executed in dry run mode.
  echo "DRY RUN - Would execute: ", command.join(" ")
  echo "DRY RUN - On hosts: ", hosts.join(", ")
  echo "DRY RUN - Prefix output: ", prefixOutput
