import paramiko
import sys

def ssh_upload_and_run(host, user, password, local_file, remote_file, command):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(host, username=user, password=password, timeout=30)
        
        # Upload file via SFTP
        sftp = client.open_sftp()
        sftp.put(local_file, remote_file)
        sftp.close()
        
        # Run command
        stdin, stdout, stderr = client.exec_command(command)
        output = stdout.read().decode('utf-8')
        error = stderr.read().decode('utf-8')
        if error:
            print(f"STDERR: {error}", file=sys.stderr)
        print(output)
    finally:
        client.close()

if __name__ == "__main__":
    host = "192.168.1.25"
    user = "rofe"
    password = "@X#891ccc"
    
    local_file = sys.argv[1]
    remote_file = sys.argv[2]
    command = sys.argv[3]
    
    ssh_upload_and_run(host, user, password, local_file, remote_file, command)
