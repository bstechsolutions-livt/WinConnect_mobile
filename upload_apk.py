import paramiko
import os

# Configurações do servidor
HOST = '192.168.1.25'
USERNAME = 'rofe'
PASSWORD = '@X#891ccc'

# Caminho do APK local
LOCAL_APK = r'build\app\outputs\flutter-apk\app-release.apk'
REMOTE_HOME = '/home/rofe/winconnect_mobile.apk'
REMOTE_PUBLIC = '/var/www/winconnect/public/systems/winconnect_mobile.apk'

def main():
    print(f"🔌 Conectando ao servidor {HOST}...")
    
    # Criar cliente SSH
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(HOST, username=USERNAME, password=PASSWORD)
        print("✅ Conectado com sucesso!")
        
        # Criar cliente SFTP
        sftp = ssh.open_sftp()
        
        # Upload do APK
        print(f"📤 Fazendo upload do APK...")
        sftp.put(LOCAL_APK, REMOTE_HOME)
        print(f"✅ APK enviado para {REMOTE_HOME}")
        
        # Copiar para a pasta pública
        print(f"📂 Copiando para pasta pública...")
        stdin, stdout, stderr = ssh.exec_command(f'sudo cp {REMOTE_HOME} {REMOTE_PUBLIC}')
        stdout.read()  # Aguardar conclusão
        print(f"✅ APK copiado para {REMOTE_PUBLIC}")
        
        # Ajustar permissões
        stdin, stdout, stderr = ssh.exec_command(f'sudo chmod 644 {REMOTE_PUBLIC}')
        stdout.read()
        print("✅ Permissões ajustadas!")
        
        sftp.close()
        
    except Exception as e:
        print(f"❌ Erro: {e}")
    finally:
        ssh.close()
        print("🔌 Conexão encerrada")

if __name__ == '__main__':
    main()
