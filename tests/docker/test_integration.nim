import
  std/[unittest, osproc, strutils, sequtils, os]

const
  NpshPath = currentSourcePath().parentDir().parentDir().parentDir() / "src" / "npsh.nim"
  ConfigPath = currentSourcePath().parentDir() / "test_npsh_config"
  KeyPath = currentSourcePath().parentDir() / "id_ed25519"
  SshOpts = "-o IdentityFile=" & KeyPath &
            " -o StrictHostKeyChecking=no" &
            " -o UserKnownHostsFile=/dev/null" &
            " -o LogLevel=ERROR"

proc runNpsh(args: string, stdinData: string = ""): tuple[output: string, exitCode: int] =
  let cmd = "nim r --hints:off " & NpshPath & " " & args
  var env = ""
  env.add("NPSH_CONFIG=" & ConfigPath & " ")
  env.add("NPSH_SSH_OPTS=\"" & SshOpts & "\" ")
  let fullCmd = "env " & env & cmd
  if stdinData.len > 0:
    let pipedCmd = "echo " & quoteShell(stdinData) & " | " & fullCmd
    result = execCmdEx(pipedCmd)
  else:
    result = execCmdEx(fullCmd)

suite "Integration Tests":

  test "single host command execution":
    let (output, exitCode) = runNpsh("-C /root node0 echo hello")
    check exitCode == 0
    check "hello" in output

  test "multi-host parallel execution":
    let (output, exitCode) = runNpsh("-C /root -a hostname")
    check exitCode == 0
    check "node0" in output
    check "node1" in output
    check "node2" in output

  test "prefixed output alignment":
    let (output, exitCode) = runNpsh("-C /root -p -a echo test")
    check exitCode == 0
    let lines = output.strip().splitLines().filterIt(it.strip().len > 0)
    check lines.len == 3
    for line in lines:
      check "test" in line
    var prefixLens: seq[int] = @[]
    for line in lines:
      let testIdx = line.find("test")
      prefixLens.add(testIdx)
    for i in 1..<prefixLens.len:
      check prefixLens[0] == prefixLens[i]

  test "command exit code propagation":
    let (_, exitCode) = runNpsh("-C /root node0 false")
    check exitCode != 0

  test "multi-host mixed exit codes":
    let (_, exitCode) = runNpsh("""-C /root -a bash -c "if [ $(hostname) = node1 ]; then exit 1; fi" """)
    check exitCode != 0

  test "cwd preservation":
    let (output, exitCode) = runNpsh("-C /mnt/shared/testdir -a pwd")
    check exitCode == 0
    check "/mnt/shared/testdir" in output

  test "cwd nonexistent directory fails":
    let (_, exitCode) = runNpsh("-C /nonexistent/path/that/does/not/exist -a ls")
    check exitCode != 0

  test "env var forwarding explicit":
    let (output, exitCode) = runNpsh("-C /root -e TESTVAR=hello -a printenv TESTVAR")
    check exitCode == 0
    let lines = output.strip().splitLines().filterIt(it.strip().len > 0)
    var helloCount = 0
    for line in lines:
      if "hello" in line:
        helloCount += 1
    check helloCount == 3

  test "env var forwarding by name":
    putEnv("NPSH_INTEGRATION_TEST_VAR", "world42")
    let (output, exitCode) = runNpsh("-C /root -e NPSH_INTEGRATION_TEST_VAR -a printenv NPSH_INTEGRATION_TEST_VAR")
    delEnv("NPSH_INTEGRATION_TEST_VAR")
    check exitCode == 0
    check "world42" in output

  test "stdin piping single host":
    let (output, exitCode) = runNpsh("-C /root -i node0 cat", "hello from stdin")
    check exitCode == 0
    check "hello from stdin" in output

  test "large output no deadlock":
    let (output, exitCode) = runNpsh("-C /root node0 seq 1 2000")
    check exitCode == 0
    let lines = output.strip().splitLines().filterIt(it.strip().len > 0)
    check lines.len >= 1900

  test "dry run does not execute":
    let (output1, exitCode1) = runNpsh("-d -a echo dry_run_marker")
    check exitCode1 == 0
    check "DRY RUN" in output1

  test "node id addressing":
    let (output0, exitCode0) = runNpsh("-C /root 0 hostname")
    check exitCode0 == 0
    check "node0" in output0
    let (output1, exitCode1) = runNpsh("-C /root 1 hostname")
    check exitCode1 == 0
    check "node1" in output1
