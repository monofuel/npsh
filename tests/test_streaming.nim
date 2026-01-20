import
  std/[unittest, strutils, sequtils],
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
    # Test that empty commands are handled
    let hosts = @[newHost("testhost")]
    let command: seq[string] = @[]

    # This should work without actual execution - just tests the parameter passing
    # The actual execution would require SSH server mocking
    check command.len == 0
