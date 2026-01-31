# Acesso ao Servidor da API WMS

## Informações de Acesso

### Servidor Rofe (WinConnect API)
- **Host**: 192.168.1.25
- **Usuário SSH**: rofe
- **Senha**: @X#891ccc
- **Caminho do projeto**: /var/www/winconnect/
- **Framework**: Laravel (PHP)

### Conexão SSH
```bash
ssh rofe@192.168.1.25
```

### Navegar para o projeto
```bash
cd /var/www/winconnect/
```

### Arquivos Importantes
- **Controlador Fase 1**: `app/Http/Controllers/Api/WMS/Fase1Controller.php`
- **Rotas API**: `routes/api.php`
- **Configurações**: `config/`
- **Logs**: `storage/logs/laravel.log`

### Comandos Úteis

```bash
# Ver logs em tempo real
tail -f /var/www/winconnect/storage/logs/laravel.log

# Limpar cache do Laravel
cd /var/www/winconnect && php artisan cache:clear

# Limpar cache de configuração
cd /var/www/winconnect && php artisan config:clear

# Reiniciar filas (se houver)
cd /var/www/winconnect && php artisan queue:restart
```

---

## Endpoints Principais da API

Consultar arquivo `WMS_API.MD` para documentação completa dos endpoints.

### Endpoint com problema atual
- **POST /wms/fase1/os/{numos}/finalizar**
  - Problema: Retornando `rua_concluida: true` quando ainda há OSs pendentes na rua

---

## Notas

_Servidor configurado com CloudPanel._
