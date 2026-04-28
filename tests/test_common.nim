import
  std/[unittest, strutils, os],
  npsh,
  npsh/config

suite "Common Functions Tests":

  test "parseHosts with single host":
    let result = parseHosts("web1")
    check result == @["web1"]

  test "parseHosts with multiple hosts":
    let result = parseHosts("web1,web2,web3")
    check result == @["web1", "web2", "web3"]

  test "parseHosts with whitespace":
    let result = parseHosts("  web1  ,  web2  ,  web3  ")
    check result == @["web1", "web2", "web3"]

  test "parseHosts with empty string":
    let result = parseHosts("")
    check result.len == 0

  test "parseHosts with single comma":
    let result = parseHosts(",")
    check result == @["", ""]

  test "formatHostPrefix with short hostname":
    # maxHostLen = 8 (longest hostname), hostname = "host1" (5 chars)
    # Result: "host1" + (8 - 5 + TabWidth) spaces
    let result = formatHostPrefix("host1", 8)
    check result == "host1" & " ".repeat(3 + TabWidth)

  test "formatHostPrefix with exact length":
    # maxHostLen = 8, hostname = "myhost12" (8 chars)
    # Result: "myhost12" + (8 - 8 + TabWidth) spaces
    let result = formatHostPrefix("myhost12", 8)
    check result == "myhost12" & " ".repeat(TabWidth)

  test "formatHostPrefix with empty hostname":
    let result = formatHostPrefix("", 8)
    check result == "" & " ".repeat(8 + TabWidth)

  test "resolveHosts by hostname":
    let hosts = @[
      newHost("web1", nodeId=0),
      newHost("web2", nodeId=1),
      newHost("db1", nodeId=2)
    ]
    let result = resolveHosts(@["web1"], hosts)
    check result == @["web1"]

  test "resolveHosts by node ID":
    let hosts = @[
      newHost("web1", nodeId=0),
      newHost("web2", nodeId=1),
      newHost("db1", nodeId=2)
    ]
    let result = resolveHosts(@["1"], hosts)
    check result == @["web2"]

  test "resolveHosts mixed specs":
    let hosts = @[
      newHost("web1", nodeId=0),
      newHost("web2", nodeId=1),
      newHost("db1", nodeId=2)
    ]
    let result = resolveHosts(@["web1", "2"], hosts)
    check result == @["web1", "db1"]

  test "resolveHosts multiple hostnames":
    let hosts = @[
      newHost("web1", nodeId=0),
      newHost("web2", nodeId=1),
      newHost("db1", nodeId=2)
    ]
    let result = resolveHosts(@["web1", "db1"], hosts)
    check result == @["web1", "db1"]

  test "resolveHosts empty list":
    let hosts = @[
      newHost("web1", nodeId=0)
    ]
    let result = resolveHosts(@[], hosts)
    check result.len == 0

  test "resolveHosts invalid hostname":
    let hosts = @[
      newHost("web1", nodeId=0),
      newHost("web2", nodeId=1)
    ]
    expect(ValueError):
      discard resolveHosts(@["nonexistent"], hosts)

  test "resolveHosts invalid node ID":
    let hosts = @[
      newHost("web1", nodeId=0),
      newHost("web2", nodeId=1)
    ]
    expect(ValueError):
      discard resolveHosts(@["5"], hosts)

suite "buildEnvPrefix Tests":

  test "no env vars returns empty":
    let result = buildEnvPrefix(false, @[])
    check result == ""

  test "single explicit var":
    let result = buildEnvPrefix(false, @["FOO=bar"])
    check result == "env FOO=bar "

  test "multiple explicit vars":
    let result = buildEnvPrefix(false, @["FOO=bar", "BAZ=qux"])
    check result == "env FOO=bar BAZ=qux "

  test "forward var by name from environment":
    putEnv("NPSH_TEST_VAR", "hello")
    let result = buildEnvPrefix(false, @["NPSH_TEST_VAR"])
    check "NPSH_TEST_VAR=hello" in result
    delEnv("NPSH_TEST_VAR")

  test "env-all forwards current environment":
    putEnv("NPSH_TEST_ENVALL", "testval")
    let result = buildEnvPrefix(true, @[])
    check result.len > 0
    check result.startsWith("env ")
    # NPSH_ vars are blacklisted
    check "NPSH_TEST_ENVALL" notin result
    delEnv("NPSH_TEST_ENVALL")

  test "env-all excludes blacklisted vars":
    putEnv("SSH_CLIENT", "test_value")
    putEnv("DISPLAY", "test_value")
    let result = buildEnvPrefix(true, @[])
    check " SSH_CLIENT=" notin result
    check " DISPLAY=" notin result
    check "SSH_CLIENT=test_value" notin result
    check "DISPLAY=test_value" notin result
    delEnv("SSH_CLIENT")
    delEnv("DISPLAY")

  test "env-all with explicit override":
    let result = buildEnvPrefix(true, @["HOME=/override"])
    check "HOME=/override" in result
    # HOME should only appear once
    var homeCount = 0
    for part in result.split(' '):
      if "HOME=" in part:
        homeCount += 1
    check homeCount == 1

  test "value with spaces is quoted":
    let result = buildEnvPrefix(false, @["MSG=hello world"])
    check result == "env 'MSG=hello world' "
