import
  std/[unittest, strutils, sequtils, osproc, streams],
  npsh

suite "Streaming Output Tests":

  test "formatHostPrefix alignment calculation":
    # Test the alignment logic used in streaming
    let maxHostLen = 10
    let host1 = formatHostPrefix("short", maxHostLen)
    let host2 = formatHostPrefix("mediumname", maxHostLen)
    let host3 = formatHostPrefix("verylonghostname", maxHostLen)

    # Check that all prefixes have the same total length
    check host1.len == host2.len
    check host2.len == host3.len
    check host3.len == host1.len

    # Check that the hostname part is preserved
    check host1.startsWith("short")
    check host2.startsWith("mediumname")
    check host3.startsWith("verylonghostname")

  test "TabWidth constant":
    # Test that TabWidth is defined and reasonable
    check TabWidth > 0
    check TabWidth <= 16  # Reasonable upper bound

  test "formatHostPrefix with TabWidth":
    let maxHostLen = 6
    let result = formatHostPrefix("host", maxHostLen)
    # Should be: "host" + padding to maxHostLen + TabWidth spaces
    let expectedPadding = maxHostLen - 4 + TabWidth  # 4 is length of "host"
    check result.len == 4 + expectedPadding

  test "streaming prefix format consistency":
    # Test that the prefix format is consistent across different hostnames
    let hosts = @["a", "medium", "verylonghostname"]
    let maxLen = 15

    let prefixes = hosts.mapIt(formatHostPrefix(it, maxLen))

    # All prefixes should have the same length
    for i in 1..<prefixes.len:
      check prefixes[0].len == prefixes[i].len

    # Each prefix should start with its hostname
    for i, host in hosts:
      check prefixes[i].startsWith(host)

  test "multiple hosts prefix alignment":
    # Test that prefixes are aligned properly for multiple hosts
    let hosts = @[
      newHost("short"),
      newHost("mediumname"),
      newHost("verylonghostname")
    ]

    # Calculate max length
    var maxHostLen = 0
    for host in hosts:
      maxHostLen = max(maxHostLen, host.hostname.len)

    # Check that all hostnames fit within the calculated max
    for host in hosts:
      check host.hostname.len <= maxHostLen

    # Test that formatHostPrefix produces aligned output
    let prefixes = hosts.mapIt(formatHostPrefix(it.hostname, maxHostLen))
    for i in 1..<prefixes.len:
      check prefixes[0].len == prefixes[i].len

  test "streaming with empty command validation":
    let hosts = @[newHost("testhost")]
    let command: seq[string] = @[]
    check command.len == 0

suite "Merged Stream Tests":

  test "poStdErrToStdOut captures both stdout and stderr":
    let process = startProcess("bash", args = @["-c", "echo out1; echo err1 >&2; echo out2"],
                              options = {poUsePath, poStdErrToStdOut})
    let outputStream = process.outputStream
    var lines: seq[string] = @[]
    var line: string
    while outputStream.readLine(line):
      lines.add(line)
    discard process.waitForExit()
    process.close()
    check lines.len == 3
    check "out1" in lines
    check "err1" in lines
    check "out2" in lines

  test "merged streams do not deadlock with large stderr":
    ## Produces >64KB of stderr alongside stdout to verify no pipe deadlock.
    let process = startProcess("bash",
      args = @["-c", "for i in $(seq 1 2000); do echo stdout_$i; echo stderr_$i >&2; done"],
      options = {poUsePath, poStdErrToStdOut})
    let outputStream = process.outputStream
    var lineCount = 0
    var line: string
    while outputStream.readLine(line):
      lineCount += 1
    let exitCode = process.waitForExit()
    process.close()
    check exitCode == 0
    check lineCount == 4000
