import
  std/[unittest, os],
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

  test "buildSshCommand with cwd":
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls", "-la"], "/tmp")
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "cd /tmp && ls -la"]

  test "buildSshCommand with empty cwd uses no cd":
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls", "-la"], "")
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "ls -la"]

  test "buildSshCommand with cwd containing spaces":
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls"], "/my path/dir")
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "cd '/my path/dir' && ls"]

  test "buildSshCommand with cwd and all host options":
    let host = newHost("server", ip="10.0.0.1", port=2222, username="deploy")
    let cmd = buildSshCommand(host, @["make", "build"], "/home/deploy/project")
    check cmd == @["ssh", "-o", "BatchMode=yes", "-p", "2222", "deploy@10.0.0.1", "cd /home/deploy/project && make build"]

  test "buildSshCommand with env prefix":
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls", "-la"], envPrefix="env FOO=bar ")
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "env FOO=bar ls -la"]

  test "buildSshCommand with cwd and env prefix":
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls", "-la"], cwd="/tmp", envPrefix="env FOO=bar ")
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "cd /tmp && env FOO=bar ls -la"]

  test "buildSshCommand with empty env prefix":
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls", "-la"], envPrefix="")
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "ls -la"]

  test "buildSshCommand with NPSH_SSH_OPTS":
    putEnv("NPSH_SSH_OPTS", "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null")
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls"])
    check cmd[0] == "ssh"
    check cmd[1] == "-o"
    check cmd[2] == "BatchMode=yes"
    check "-o" in cmd[3..^1]
    check "StrictHostKeyChecking=no" in cmd
    check "UserKnownHostsFile=/dev/null" in cmd
    check cmd[^1] == "ls"
    delEnv("NPSH_SSH_OPTS")

  test "buildSshCommand without NPSH_SSH_OPTS":
    delEnv("NPSH_SSH_OPTS")
    let host = newHost("testhost")
    let cmd = buildSshCommand(host, @["ls"])
    check cmd == @["ssh", "-o", "BatchMode=yes", "testhost", "ls"]

  test "executeDryRun output format":
    let hosts = @["host1", "host2", "host3"]
    let command = @["ls", "-la"]
    let prefixOutput = true
    executeDryRun(hosts, command, prefixOutput, "/tmp")
