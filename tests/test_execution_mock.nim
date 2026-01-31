import
  std/[unittest],
  npsh,
  npsh/config

suite "Execution Logic Tests":

  # These tests validate the coordination logic that doesn't require actual SSH execution

  test "executeOnHosts stdin validation multiple hosts should fail":
    let hosts = @[newHost("host1"), newHost("host2")]
    let command = @["cat"]
    let stdinData = "test input"
    let exitCode = executeOnHosts(hosts, command, false, stdinData)
    check exitCode == 1  # Should fail due to stdin restriction

  test "executeOnHosts streamStdin validation multiple hosts should fail":
    let hosts = @[newHost("host1"), newHost("host2")]
    let command = @["cat"]
    let exitCode = executeOnHosts(hosts, command, false, streamStdin=true)
    check exitCode == 1  # Should fail due to stdin restriction

  test "executeOnHosts empty host list":
    let hosts: seq[Host] = @[]
    let command = @["true"]
    let exitCode = executeOnHosts(hosts, command, false)
    check exitCode == 0  # Should succeed with no hosts

  # Note: Tests that require actual SSH execution are omitted as they would need
  # complex mocking or a test SSH server. The core logic (command building,
  # host resolution, argument parsing, output formatting) is tested elsewhere.
  # monofuel note: maybe we could use docker or something to setup ssh hosts to test against?
