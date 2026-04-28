import
  std/[osproc, streams, strutils, threadpool, locks],
  ./config, ./common

var outputLock: Lock

proc buildSshCommand*(host: Host, command: seq[string], cwd: string = "", envPrefix: string = ""): seq[string] =
  ## Build SSH command with proper options and remote command.
  var cmd = @["ssh", "-o", "BatchMode=yes"]

  if host.port != 22:
    cmd.add("-p")
    cmd.add($host.port)

  let targetHost = if host.ip.len > 0: host.ip else: host.hostname
  if host.username.len > 0:
    cmd.add(host.username & "@" & targetHost)
  else:
    cmd.add(targetHost)

  let remoteCmd = envPrefix & command.join(" ")
  if cwd.len > 0:
    cmd.add("cd " & quoteShell(cwd) & " && " & remoteCmd)
  else:
    cmd.add(remoteCmd)

  return cmd

proc streamExecuteOnHost*(host: Host, command: seq[string], stdinData: string = "", prefix: string = "", streamStdin: bool = false, cwd: string = "", envPrefix: string = ""): int =
  ## Execute command on a single host via SSH with streaming output.
  let sshCmd = buildSshCommand(host, command, cwd, envPrefix)

  try:
    let process = startProcess(sshCmd[0], args = sshCmd[1..^1],
                              options = {poUsePath, poStdErrToStdOut})
    let outputStream = process.outputStream

    if stdinData.len > 0:
      process.inputStream.write(stdinData)
      process.inputStream.close()
    elif streamStdin:
      type StdinThreadData = ref object
        inputStream: Stream

      proc stdinThreadProc(data: StdinThreadData) {.thread.} =
        try:
          var stdinLine: string
          while stdin.readLine(stdinLine):
            data.inputStream.writeLine(stdinLine)
          data.inputStream.close()
        except OSError:
          try:
            data.inputStream.close()
          except:
            discard

      var threadData = StdinThreadData(inputStream: process.inputStream)
      var stdinThread: Thread[StdinThreadData]
      createThread(stdinThread, stdinThreadProc, threadData)

    var outputLine: string
    while outputStream.readLine(outputLine):
      let wholeLine = if prefix.len > 0: prefix & outputLine & "\n"
                      else: outputLine & "\n"
      withLock outputLock:
        stdout.write(wholeLine)
        stdout.flushFile()

    let exitCode = process.waitForExit()
    process.close()

    return exitCode
  except OSError:
    let errorMsg = "SSH connection failed: " & getCurrentExceptionMsg()
    let wholeLine = if prefix.len > 0: prefix & errorMsg & "\n"
                    else: errorMsg & "\n"
    withLock outputLock:
      stderr.write(wholeLine)
      stderr.flushFile()
    return -1

proc executeOnHosts*(hosts: seq[Host], command: seq[string], prefixOutput: bool, stdinData: string = "", streamStdin: bool = false, cwd: string = "", envPrefix: string = ""): int =
  ## Execute command on multiple hosts concurrently with streaming output.
  ## Returns: 0 if all commands succeeded, 1 if any command failed

  # Validate single host when stdin is provided
  if (stdinData.len > 0 or streamStdin) and hosts.len > 1:
    var hostNames: seq[string] = @[]
    for host in hosts:
      hostNames.add(host.hostname)
    echo "Error: stdin mode (-i) only supports single host. Specified: ", hosts.len, " hosts (", hostNames.join(", "), "). Multiple host stdin support coming in future version."
    return 1

  var maxHostLen = 0
  for host in hosts:
    maxHostLen = max(maxHostLen, host.hostname.len)

  initLock(outputLock)
  var flows: seq[FlowVar[int]] = @[]

  for host in hosts:
    let prefix = if prefixOutput: formatHostPrefix(host.hostname, maxHostLen) else: ""
    let hostCopy = host
    let commandCopy = command
    let stdinDataCopy = stdinData
    let prefixCopy = prefix
    let streamStdinCopy = streamStdin
    let cwdCopy = cwd
    let envPrefixCopy = envPrefix

    flows.add(spawn streamExecuteOnHost(hostCopy, commandCopy, stdinDataCopy, prefixCopy, streamStdinCopy, cwdCopy, envPrefixCopy))

  var overallExitCode = 0
  for flow in flows:
    let exitCode = ^flow
    if exitCode != 0:
      overallExitCode = 1

  deinitLock(outputLock)
  return overallExitCode

proc executeDryRun*(hosts: seq[string], command: seq[string], prefixOutput: bool, cwd: string = "", envPrefix: string = "") =
  ## Show what would be executed in dry run mode.
  echo "DRY RUN - Would execute: ", command.join(" ")
  echo "DRY RUN - On hosts: ", hosts.join(", ")
  echo "DRY RUN - Working directory: ", cwd
  if envPrefix.len > 0:
    echo "DRY RUN - Env prefix: ", envPrefix
  echo "DRY RUN - Prefix output: ", prefixOutput
