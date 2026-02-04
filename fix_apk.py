#!/usr/bin/env python3
"""
Upload APK e atualiza banco de dados.
"""
import paramiko
import os

# Configurações
HOST = '192.168.1.25'
USERNAME = 'rofe'
PASSWORD = '@X#891ccc'
LOCAL_APK = r'build\app\outputs\flutter-apk\app-release.apk'
REMOTE_PUBLIC = '/var/www/winconnect/public/systems/winconnect_mobile.apk'

def main():
    print("=" * 50)
    print("🚀 UPLOAD APK + ATUALIZAÇÃO DO BANCO")
    print("=" * 50)
    
    # Verificar se APK existe
    if not os.path.exists(LOCAL_APK):
        print(f"❌ APK não encontrado: {LOCAL_APK}")
        return
    
    local_size = os.path.getsize(LOCAL_APK)
    print(f"📦 APK local: {local_size:,} bytes")
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        print(f"\n📡 Conectando ao servidor {HOST}...")
        ssh.connect(HOST, username=USERNAME, password=PASSWORD)
        print("✅ Conectado!")
        
        # Upload direto para pasta pública
        print(f"\n📤 Fazendo upload do APK diretamente...")
        sftp = ssh.open_sftp()
        sftp.put(LOCAL_APK, REMOTE_PUBLIC)
        sftp.close()
        print(f"✅ APK enviado para {REMOTE_PUBLIC}")
        
        # Verificar tamanho no servidor
        stdin, stdout, stderr = ssh.exec_command(f'ls -la {REMOTE_PUBLIC}')
        print(f"   {stdout.read().decode().strip()}")
        
        # Ajustar permissões
        ssh.exec_command(f'chmod 644 {REMOTE_PUBLIC}')
        print("✅ Permissões ajustadas!")
        
        # Desativar versão antiga (id 2) e manter apenas a nova (id 1)
        print("\n📝 Atualizando banco de dados...")
        cmd = '''cd /var/www/winconnect && php artisan tinker --execute="
// Desativar versão antiga
App\\Models\\AppVersion::where('id', 2)->update(['is_active' => false]);
// Verificar versão ativa
\\$v = App\\Models\\AppVersion::where('is_active', true)->first();
echo 'Versão ativa: ' . \\$v->version . ' (build ' . \\$v->build_number . ')';
"'''
        stdin, stdout, stderr = ssh.exec_command(cmd)
        print(f"   {stdout.read().decode().strip()}")
        
        print("\n" + "=" * 50)
        print("✅ CONCLUÍDO!")
        print("=" * 50)
        
    except Exception as e:
        print(f"❌ Erro: {e}")
    finally:
        ssh.close()

if __name__ == '__main__':
    main()
