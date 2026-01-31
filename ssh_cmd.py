import paramiko
import sys

def ssh_command(host, user, password, command):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(host, username=user, password=password, timeout=30)
        stdin, stdout, stderr = client.exec_command(command)
        output = stdout.read().decode('utf-8')
        error = stderr.read().decode('utf-8')
        if error:
            print(f"STDERR: {error}", file=sys.stderr)
        print(output)
    finally:
        client.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ssh_cmd.py <command>")
        sys.exit(1)
    
    host = "192.168.1.25"
    user = "rofe"
    password = "@X#891ccc"
    command = sys.argv[1]
    
    ssh_command(host, user, password, command)
