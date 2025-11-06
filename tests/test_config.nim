import
  std/[unittest],
  npsh

suite "Config Tests":
  test "load config from example_npsh":
    let hosts = loadConfig("tests/example_npsh")

    check hosts.len == 2

    # Check first host (high-steel, node 0)
    check hosts[0].hostname == "high-steel"
    check hosts[0].ip == "10.11.2.14"
    check hosts[0].port == 22
    check hosts[0].username == ""
    check hosts[0].nodeId == 0

    # Check second host (solution-nine, node 1)
    check hosts[1].hostname == "solution-nine"
    check hosts[1].ip == "10.11.2.16"
    check hosts[1].port == 22
    check hosts[1].username == ""
    check hosts[1].nodeId == 1

  test "parse host line with all fields":
    let host = parseHostLine("test-host ip=192.168.1.1 port=2222 username=admin node=5")

    check host.hostname == "test-host"
    check host.ip == "192.168.1.1"
    check host.port == 2222
    check host.username == "admin"
    check host.nodeId == 5

  test "parse host line with minimal fields":
    let host = parseHostLine("simple-host")

    check host.hostname == "simple-host"
    check host.ip == ""
    check host.port == 22
    check host.username == ""
    check host.nodeId == -1

  test "parse host line with port only":
    let host = parseHostLine("host-with-port port=8080")

    check host.hostname == "host-with-port"
    check host.ip == ""
    check host.port == 8080
    check host.username == ""
    check host.nodeId == -1

  test "parse host line with username only":
    let host = parseHostLine("host-with-user username=testuser")

    check host.hostname == "host-with-user"
    check host.ip == ""
    check host.port == 22
    check host.username == "testuser"
    check host.nodeId == -1