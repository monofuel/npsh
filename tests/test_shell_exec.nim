import
  std/[unittest],
  npsh,
  npsh/config

suite "Shell Execution Tests":

  test "buildSshCommand with hostname only":
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls", "-la"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "ls -la"]

  test "buildSshCommand with username":
    let host = newHost("testhost", username="admin")
    let cmd = buildSshCommand(host, @["uptime"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "admin@testhost", "uptime"]

  test "buildSshCommand with custom port":
    let host = newHost("testhost", port=2222)
    let cmd = buildSshCommand(host, @["ps", "aux"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "-p", "2222", "testhost", "ps aux"]

  test "buildSshCommand with IP address":
    let host = newHost("web1", ip="192.168.1.100", port=22)
    let cmd = buildSshCommand(host, @["df", "-h"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "192.168.1.100", "df -h"]

  test "buildSshCommand with username, IP, and port":
    let host = newHost("db1", ip="10.0.0.50", port=2222, username="dba")
    let cmd = buildSshCommand(host, @["systemctl", "status", "mysql"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "-p", "2222", "dba@10.0.0.50", "systemctl status mysql"]

  test "buildSshCommand with all options":
    let host = newHost("complex", ip="192.168.100.200", port=8022, username="root", nodeId=5)
    let cmd = buildSshCommand(host, @["echo", "hello world"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "-p", "8022", "root@192.168.100.200", "echo hello world"]

  test "buildSshCommand with complex command":
    let host = newHost("server1")
    let cmd = buildSshCommand(host, @["bash", "-c", "echo 'multi word' && date"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "server1", "bash -c echo 'multi word' && date"]

  test "executeDryRun output format":
    # Capture stdout to test dry run output
    # Note: This test would need output capture, but for now we'll test the function signature
    let hosts = @["host1", "host2", "host3"]
    let command = @["ls", "-la"]
    let prefixOutput = true

    # executeDryRun just prints to stdout, so we can't easily test the output
    # But we can ensure it doesn't crash with valid inputs
    executeDryRun(hosts, command, prefixOutput)
