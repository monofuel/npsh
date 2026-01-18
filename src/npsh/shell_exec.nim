import
  std/[osproc, streams, strutils],
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

proc executeOnHost*(host: Host, command: seq[string], stdinData: string = ""): tuple[output: string, exitCode: int] =
  ## Execute command on a single host via SSH.
  ## Returns (output, exitCode) tuple.
  let sshCmd = buildSshCommand(host, command)

  try:
    let process = startProcess(sshCmd[0], args = sshCmd[1..^1],
                              options = {poUsePath, poStdErrToStdOut})
    let outputStream = process.outputStream

    # Write stdin data if provided
    if stdinData.len > 0:
      process.inputStream.write(stdinData)
      process.inputStream.close()

    let output = outputStream.readAll()
    let exitCode = process.waitForExit()
    process.close()

    return (output.strip(), exitCode)
  except OSError:
    return ("SSH connection failed: " & getCurrentExceptionMsg(), -1)

proc executeOnHosts*(hosts: seq[Host], command: seq[string], prefixOutput: bool, stdinData: string = "") =
  ## Execute command on multiple hosts, handling output formatting.
  ## stdinData: Data to pipe to the remote command's stdin (only works with single host)

  # Validate single host when stdin is provided
  if stdinData.len > 0 and hosts.len > 1:
    var hostNames: seq[string] = @[]
    for host in hosts:
      hostNames.add(host.hostname)
    echo "Error: stdin mode (-i) only supports single host. Specified: ", hosts.len, " hosts (", hostNames.join(", "), "). Multiple host stdin support coming in future version."
    quit(1)

  var maxHostLen = 0
  for host in hosts:
    maxHostLen = max(maxHostLen, host.hostname.len)

  for host in hosts:
    let (output, exitCode) = executeOnHost(host, command, stdinData)

    if exitCode == 0:
      if prefixOutput:
        # Prefix each line of output
        let lines = output.splitLines()
        let prefix = formatHostPrefix(host.hostname, maxHostLen)
        for line in lines:
          echo prefix, line
      else:
        echo output
    else:
      if prefixOutput:
        let prefix = formatHostPrefix(host.hostname, maxHostLen)
        echo prefix, "ERROR (", exitCode, "): ", output.strip()
      else:
        echo "ERROR on ", host.hostname, " (", exitCode, "): ", output.strip()

proc executeDryRun*(hosts: seq[string], command: seq[string], prefixOutput: bool) =
  ## Show what would be executed in dry run mode.
  echo "DRY RUN - Would execute: ", command.join(" ")
  echo "DRY RUN - On hosts: ", hosts.join(", ")
  echo "DRY RUN - Prefix output: ", prefixOutput
