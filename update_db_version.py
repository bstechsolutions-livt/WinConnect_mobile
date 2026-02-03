import paramiko

# Configurações do servidor
HOST = '192.168.1.25'
USERNAME = 'rofe'
PASSWORD = '@X#891ccc'

def main():
    print(f"🔌 Conectando ao servidor {HOST}...")
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(HOST, username=USERNAME, password=PASSWORD)
        print("✅ Conectado com sucesso!")
        
        # Atualizar versão no banco de dados via artisan tinker
        print("📝 Atualizando versão no banco de dados...")
        
        # Criar ou atualizar registro na tabela app_versions
        cmd = '''cd /var/www/winconnect && php artisan tinker --execute="
\\App\\Models\\AppVersion::updateOrCreate(
    ['platform' => 'android', 'client_id' => 'all'],
    [
        'version' => '2.1.4',
        'build_number' => 6,
        'download_url' => '/systems/winconnect_mobile.apk',
        'changelog' => 'Verificação automática de atualização desativada temporariamente',
        'is_active' => true,
        'force_update' => false,
        'released_at' => now()
    ]
);
echo 'Versão 2.1.4 (build 6) registrada com sucesso!';
"'''
        
        stdin, stdout, stderr = ssh.exec_command(cmd)
        output = stdout.read().decode()
        error = stderr.read().decode()
        
        if output:
            print(f"Output: {output}")
        if error and 'deprecated' not in error.lower():
            print(f"Error: {error}")
            
        print("✅ Versão atualizada!")
        
    except Exception as e:
        print(f"❌ Erro: {e}")
    finally:
        ssh.close()
        print("🔌 Conexão encerrada")

if __name__ == '__main__':
    main()
