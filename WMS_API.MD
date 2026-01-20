# API WMS TOTVS - Documentação Completa

API REST para integração com o sistema WMS TOTVS via aplicativo mobile (Flutter).

## Sumário

- [Visão Geral](#visão-geral)
- [Autenticação](#autenticação)
- [Fase 1 - Separação (Empilhadeira)](#fase-1---separação-empilhadeira)
- [Fase 2 - Conferência e Entrega (Auxiliar de Chão)](#fase-2---conferência-e-entrega-auxiliar-de-chão)
- [Códigos de Erro](#códigos-de-erro)
- [Permissões](#permissões)

---

## Visão Geral

O WMS opera em **duas fases**:

1. **Fase 1 (Separação)**: Operador de empilhadeira coleta produto no endereço de origem e coloca em um unitizador (palete/gaiola)
2. **Fase 2 (Conferência/Entrega)**: Auxiliar de chão confere os produtos e entrega no endereço de destino

### Fluxo de Status

```
OS Pendente (P) 
    → Fase 1: Iniciada → Bipou Endereço → Bipou Produto → Vinculou Unitizador → Finalizada
    → Fase 2: Conferida → Na Rota → Entregue (C)
```

### Base URL

```
https://seu-servidor.com/api/wms
```

### Headers Obrigatórios

```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

---

## Autenticação

### POST /api/login

Autentica o usuário e retorna o token de acesso.

**Request:**
```json
{
    "email": "operador@empresa.com",
    "password": "senha123",
    "device_name": "APP_WMS_ANDROID"
}
```

**Response (200):**
```json
{
    "token": "1|abc123...",
    "user": {
        "id": 1,
        "name": "João Silva",
        "email": "operador@empresa.com",
        "matricula": 12345
    }
}
```

### GET /api/user

Retorna dados do usuário autenticado.

**Response (200):**
```json
{
    "id": 1,
    "name": "João Silva",
    "email": "operador@empresa.com",
    "matricula": 12345,
    "permissions": ["wms.fase1", "wms.fase2"]
}
```

### POST /api/logout

Invalida o token atual.

---

## Fase 1 - Separação (Empilhadeira)

### Conceito: Operador Preso na Rua

Quando um operador inicia a primeira OS de uma rua, ele fica **vinculado àquela rua** até:
- Finalizar todas as OSs da rua, ou
- Ser liberado por um supervisor

Isso evita que operadores fiquem pulando de rua em rua.

---

### GET /fase1/ruas

Lista ruas com OSs pendentes para separação.

**Response (200):**
```json
{
    "ruas": [
        { "rua": "A", "qtd_os": 15 },
        { "rua": "B", "qtd_os": 8 },
        { "rua": "C", "qtd_os": 22 }
    ]
}
```

---

### GET /fase1/ruas/{rua}/os

Lista OSs de uma rua em ordem otimizada de rota.

**Parâmetros:**
- `rua` (path): Identificação da rua (ex: "A", "B", "01")

**Response (200):**
```json
{
    "rua": "A",
    "ordens": [
        {
            "numos": 123456,
            "ordem": 1,
            "codprod": 7890,
            "descricao": "PRODUTO XYZ",
            "endereco_origem": "A.01.02.03",
            "status": "P",
            "pode_executar": true
        },
        {
            "numos": 123457,
            "ordem": 2,
            "codprod": 7891,
            "descricao": "PRODUTO ABC",
            "endereco_origem": "A.01.02.05",
            "status": "P",
            "pode_executar": false
        }
    ],
    "os_em_andamento": null
}
```

---

### GET /fase1/minha-rua

Retorna informações sobre a rua atual do operador.

**Response (200) - Operador em uma rua:**
```json
{
    "em_rua": true,
    "rua": "A",
    "desde": "2026-01-19 08:30:00",
    "os_pendentes": 12,
    "proxima_os": {
        "numos": 123456,
        "codprod": 7890,
        "descricao": "PRODUTO XYZ",
        "qt": 10,
        "endereco_origem": "A.01.02.03"
    }
}
```

**Response (200) - Operador livre:**
```json
{
    "em_rua": false,
    "rua": null
}
```

---

### GET /fase1/operador/{matricula}/os-ativa

Verifica se um operador possui OS em andamento.

**Parâmetros:**
- `matricula` (path): Matrícula do operador no Winthor

**Response (200) - Com OS ativa:**
```json
{
    "ativa": true,
    "operador": {
        "matricula": 12345,
        "nome": "JOÃO SILVA",
        "funcao": "EMPILHADEIRISTA"
    },
    "os": {
        "numos": 123456,
        "status": "P",
        "endereco_bipado": true,
        "produto_bipado": true,
        "unitizador_vinculado": true,
        "codunitizador": "PAL001",
        "rua": "A",
        "codprod": 7890,
        "descricao": "PRODUTO XYZ",
        "qt": 10,
        "endereco_origem": {
            "codigo": 1234,
            "endereco": "A.01.02.03"
        },
        "endereco_destino": {
            "codigo": 5678,
            "endereco": "C.05.01.02"
        },
        "iniciada_em": "2026-01-19 08:45:00"
    }
}
```

**Response (200) - Sem OS ativa:**
```json
{
    "ativa": false,
    "os": null
}
```

---

### GET /fase1/os/{numos}

Retorna detalhes de uma OS específica.

**Parâmetros:**
- `numos` (path): Número da OS

**Response (200):**
```json
{
    "os": {
        "numos": 123456,
        "status": "P",
        "rua": "A",
        "qt": 10,
        "qt_conferida": null,
        "numpalete": null,
        "produto_bipado": false,
        "codunitizador": null
    },
    "produto": {
        "codprod": 7890,
        "codauxiliar": "7891234567890",
        "descricao": "PRODUTO XYZ 500ML",
        "unidade": "UN",
        "unidademaster": "CX",
        "qtunitcx": 12
    },
    "endereco_origem": {
        "codendereco": 1234,
        "endereco": "A.01.02.03",
        "rua": "A",
        "predio": 1,
        "nivel": 2,
        "apto": 3
    },
    "estoque_atual": 150
}
```

---

### POST /fase1/os/{numos}/iniciar

Inicia a execução de uma OS.

**Regras:**
- Operador não pode ter outra OS em andamento
- OS não pode estar bloqueada
- Se não for a próxima da fila, requer autorização de supervisor
- Se operador está em outra rua, retorna erro

**Request (normal):**
```json
{}
```

**Request (fora da ordem - requer autorização):**
```json
{
    "autorizador_matricula": 99999,
    "autorizador_senha": "senha_supervisor"
}
```

**Response (200):**
```json
{
    "message": "OS iniciada com sucesso.",
    "os": { ... },
    "rua": "A"
}
```

**Response (422) - Operador em outra rua:**
```json
{
    "message": "Você está alocado na Rua B. Finalize todas as OSs dessa rua ou peça liberação ao supervisor.",
    "rua_atual": "B",
    "rua_os": "A",
    "requer_liberacao": true
}
```

**Response (422) - Fora da ordem:**
```json
{
    "message": "Esta não é a próxima OS da rota. A próxima é a OS 123457.",
    "proxima_os": 123457,
    "requer_autorizacao": true
}
```

---

### POST /fase1/os/{numos}/bipar-endereco

Confirma chegada no endereço de origem (bipa etiqueta do endereço).

**Request:**
```json
{
    "codigo_endereco": "A.01.02.03"
}
```

**Response (200):**
```json
{
    "message": "Endereço de origem confirmado.",
    "endereco_validado": true
}
```

**Response (422):**
```json
{
    "message": "Código do endereço não confere com o endereço de origem da OS.",
    "esperado": {
        "codigo": "1234",
        "endereco": "A.01.02.03"
    }
}
```

---

### POST /fase1/os/{numos}/bipar

Bipa o produto (valida código de barras EAN).

**Request:**
```json
{
    "codigo_barras": "7891234567890"
}
```

**Response (200):**
```json
{
    "message": "Produto bipado com sucesso.",
    "produto_validado": true
}
```

**Response (422):**
```json
{
    "message": "Código de barras não confere com o produto da OS.",
    "esperado": "7891234567890"
}
```

---

### POST /fase1/os/{numos}/vincular-unitizador

Vincula um unitizador (palete/gaiola) à OS.

**Request:**
```json
{
    "codigo_barras_unitizador": "PAL001"
}
```

**Response (200):**
```json
{
    "message": "Unitizador vinculado com sucesso.",
    "unitizador": {
        "id": 1,
        "codigo": "PAL001",
        "codigo_barras": "PAL001",
        "status": "em_uso"
    }
}
```

---

### POST /fase1/os/{numos}/finalizar

Finaliza a Fase 1 da OS.

**Pré-requisitos:**
1. Endereço de origem bipado
2. Produto bipado
3. Unitizador vinculado
4. Quantidade EXATAMENTE igual à esperada

**Request:**
```json
{
    "qt_conferida": 10
}
```

**Response (200) - Há próxima OS na rua:**
```json
{
    "message": "Fase 1 finalizada com sucesso. Próxima OS disponível.",
    "tracking": {
        "fase1_fim": "2026-01-19 09:15:00",
        "qt_conferida": 10,
        "qt_esperada": 10
    },
    "rua_concluida": false,
    "proxima_os": {
        "numos": 123457,
        "codprod": 7891,
        "descricao": "PRODUTO ABC",
        "qt": 5,
        "endereco_origem": "A.01.02.05"
    }
}
```

**Response (200) - Rua concluída:**
```json
{
    "message": "Fase 1 finalizada com sucesso. Rua concluída! 🎉",
    "tracking": {
        "fase1_fim": "2026-01-19 09:15:00",
        "qt_conferida": 10,
        "qt_esperada": 10
    },
    "rua_concluida": true,
    "proxima_os": null
}
```

**Response (422) - Quantidade diferente:**
```json
{
    "message": "Não é permitido separar com quantidade diferente. Quantidade informada é menor que a esperada. Registre uma divergência se necessário.",
    "qt_conferida": 8,
    "qt_esperada": 10,
    "diferenca": 2,
    "tipo_erro": "menor",
    "deve_registrar_divergencia": true
}
```

---

### POST /fase1/os/{numos}/sair

Sai de uma OS em andamento (requer autorização de supervisor).

**Request:**
```json
{
    "autorizador_matricula": 99999,
    "autorizador_senha": "senha_supervisor"
}
```

**Response (200):**
```json
{
    "message": "Saída da OS autorizada com sucesso."
}
```

---

### POST /fase1/os/{numos}/bloquear

Bloqueia uma OS (quando operador não consegue executar).

**Request:**
```json
{
    "motivo": "Produto não encontrado no endereço"
}
```

**Response (200):**
```json
{
    "message": "OS bloqueada. Você pode iniciar outra OS.",
    "bloqueio": {
        "id": 123,
        "motivo": "Produto não encontrado no endereço"
    }
}
```

---

### POST /fase1/os/{numos}/divergencia

Registra uma divergência na OS (executa mas sinaliza problema).

**Request:**
```json
{
    "tipo": "quantidade_menor",
    "qt_encontrada": 8,
    "observacao": "Faltam 2 unidades no endereço"
}
```

**Tipos válidos:**
- `quantidade_menor`
- `quantidade_maior`
- `produto_errado`
- `nao_encontrado`
- `outro`

**Response (200):**
```json
{
    "message": "Divergência registrada. Continue a execução da OS.",
    "divergencia": {
        "id": 456,
        "tipo": "quantidade_menor",
        "tipo_label": "Quantidade Menor"
    }
}
```

---

### POST /fase1/liberar-rua

Libera um operador de uma rua (requer autorização de supervisor).

**Request:**
```json
{
    "matricula": 12345,
    "autorizador_matricula": 99999,
    "autorizador_senha": "senha_supervisor"
}
```

**Response (200):**
```json
{
    "message": "Operador liberado da Rua A com sucesso.",
    "rua_liberada": "A"
}
```

---

### GET /consulta-estoque/{codprod}

Consulta estoque de um produto em todos os endereços.

**Parâmetros:**
- `codprod` (path): Código do produto

**Response (200):**
```json
{
    "produto": {
        "codprod": 7890,
        "descricao": "PRODUTO XYZ"
    },
    "estoques": [
        {
            "rua": "A",
            "predio": 1,
            "nivel": null,
            "apto": 3,
            "endereco": "A.01.00.03",
            "qt": 150
        },
        {
            "rua": "B",
            "predio": 2,
            "nivel": null,
            "apto": 5,
            "endereco": "B.02.00.05",
            "qt": 80
        }
    ]
}
```

---

## Fase 2 - Conferência e Entrega (Auxiliar de Chão)

### GET /fase2/ruas

Lista ruas com OSs prontas para conferência (Fase 1 concluída).

**Response (200):**
```json
{
    "ruas": [
        { "rua": "A", "qtd_os": 5 },
        { "rua": "B", "qtd_os": 3 }
    ]
}
```

---

### GET /fase2/ruas/{rua}/unitizadores

Lista unitizadores disponíveis na rua para conferência.

**Response (200):**
```json
{
    "rua": "A",
    "unitizadores": [
        {
            "unitizador_id": 1,
            "codigo": "PAL001",
            "codigo_barras": "PAL001",
            "qtd_itens": 5,
            "qtd_conferidos": 2,
            "status": "EM_CONFERENCIA"
        },
        {
            "unitizador_id": 2,
            "codigo": "PAL002",
            "codigo_barras": "PAL002",
            "qtd_itens": 3,
            "qtd_conferidos": 0,
            "status": "AGUARDANDO"
        }
    ]
}
```

**Status possíveis:**
- `AGUARDANDO`: Nenhum item conferido
- `EM_CONFERENCIA`: Alguns itens conferidos
- `CONFERIDO`: Todos os itens conferidos

---

### POST /fase2/unitizador/bipar

Seleciona um unitizador para conferência (bipa código de barras).

**IMPORTANTE:** É obrigatório bipar o unitizador antes de conferir os itens. A bipagem é registrada no sistema.

**Request:**
```json
{
    "codigo_barras": "PAL001"
}
```

**Response (200):**
```json
{
    "message": "Unitizador selecionado.",
    "unitizador": {
        "id": 1,
        "codigo": "PAL001",
        "codigo_barras": "PAL001"
    },
    "itens": [
        {
            "numos": 123456,
            "codprod": 7890,
            "descricao": "PRODUTO XYZ",
            "codauxiliar": "7891234567890",
            "embalagem": "CX",
            "unidade": "UN",
            "qt": 10,
            "multiplo": 12,
            "conferido": false,
            "bloqueado": false,
            "tentativas": 0
        }
    ],
    "total_itens": 5,
    "total_conferidos": 0
}
```

---

### POST /fase2/os/{numos}/conferir-produto

Conferência cega: bipa produto e informa quantidade.

**Pré-requisito:** Unitizador deve ter sido bipado (POST /fase2/unitizador/bipar)

**Request:**
```json
{
    "codigo_barras": "7891234567890",
    "quantidade": 10
}
```

**Response (200):**
```json
{
    "message": "Produto conferido com sucesso! OS adicionada ao seu carrinho.",
    "conferido": true,
    "os": {
        "numos": 123456,
        "codprod": 7890,
        "descricao": "PRODUTO XYZ",
        "qt": 10,
        "multiplo": 12
    }
}
```

**Response (422) - Quantidade incorreta:**
```json
{
    "message": "Quantidade incorreta. Tente novamente.",
    "tentativas": 1,
    "tentativas_restantes": 2
}
```

**Response (422) - Bloqueado após máximo de tentativas:**
```json
{
    "message": "OS bloqueada após 3 tentativas incorretas.",
    "bloqueada": true,
    "tentativas": 3
}
```

**Response (422) - Unitizador não bipado:**
```json
{
    "message": "Bipe o unitizador antes de conferir os itens.",
    "requer_bipagem": true
}
```

---

### POST /fase2/os/{numos}/divergencia

Registra divergência na Fase 2 (quantidade errada no picking).

**Request:**
```json
{
    "tipo": "quantidade_menor",
    "qt_encontrada": 8,
    "observacao": "Faltam 2 unidades no palete"
}
```

**Tipos válidos:**
- `quantidade_menor`
- `quantidade_maior`
- `produto_errado`
- `nao_encontrado`
- `outro`

**Response (200):**
```json
{
    "message": "Divergência registrada com sucesso.",
    "divergencia": {
        "id": 456,
        "tipo": "quantidade_menor",
        "tipo_label": "Quantidade Menor",
        "qt_esperada": 10,
        "qt_encontrada": 8
    },
    "os": {
        "numos": 123456,
        "codprod": 7890,
        "descricao": "PRODUTO XYZ"
    }
}
```

**Notas:**
- A divergência é registrada mas NÃO bloqueia a OS
- O operador pode continuar conferindo outros itens
- Divergências ficam pendentes para análise do supervisor

---

### GET /fase2/meu-carrinho

Lista OSs conferidas pelo operador (carrinho de entrega).

**Response (200):**
```json
{
    "carrinho": [
        {
            "numos": 123456,
            "codprod": 7890,
            "descricao": "PRODUTO XYZ",
            "qt": 10,
            "endereco_destino": {
                "codendereco": 5678,
                "endereco": "C.05.01.02",
                "rua": "C",
                "predio": 5,
                "nivel": 1,
                "apto": 2
            }
        }
    ],
    "total_itens": 3,
    "pode_calcular_rota": true,
    "rota_calculada": false
}
```

---

### POST /fase2/calcular-rota

Calcula rota otimizada para entrega das OSs do carrinho.

**Request:**
```json
{}
```

**Response (200):**
```json
{
    "message": "Rota calculada com sucesso!",
    "total_itens": 3,
    "rota": [
        {
            "ordem": 1,
            "numos": 123456,
            "codprod": 7890,
            "descricao": "PRODUTO XYZ",
            "qt": 10,
            "endereco_destino": {
                "codendereco": 5678,
                "endereco": "C.05.01.02",
                "rua": "C",
                "predio": 5,
                "nivel": 1,
                "apto": 2
            },
            "entregue": false
        }
    ],
    "proxima_entrega": { ... }
}
```

---

### GET /fase2/proxima-entrega

Retorna a próxima entrega da rota calculada.

**Response (200):**
```json
{
    "proxima_entrega": {
        "ordem": 2,
        "numos": 123457,
        "codprod": 7891,
        "descricao": "PRODUTO ABC",
        "qt": 5,
        "endereco_destino": {
            "codendereco": 5679,
            "endereco": "C.05.02.01",
            "rua": "C",
            "predio": 5,
            "nivel": 2,
            "apto": 1
        },
        "entregue": false
    },
    "progresso": {
        "entregues": 1,
        "faltam": 2,
        "total": 3
    }
}
```

**Response (200) - Rota concluída:**
```json
{
    "message": "Todas as entregas foram realizadas! Parabéns!",
    "rota_concluida": true
}
```

---

### POST /fase2/os/{numos}/confirmar-entrega

Confirma entrega no endereço de destino e finaliza a OS.

**Fluxo otimizado:** Operador bipa endereço + bipa produto em sequência. A resposta já inclui a próxima entrega automaticamente (não precisa chamar GET /proxima-entrega).

**Request:**
```json
{
    "codigo_barras_endereco": "C.05.01.02",
    "codigo_barras_produto": "7891234567890"
}
```

**Response (200):**
```json
{
    "message": "Entrega confirmada! OS finalizada com sucesso.",
    "os": {
        "numos": 123456,
        "codprod": 7890,
        "descricao": "PRODUTO XYZ",
        "endereco": "C.05.01.02"
    },
    "proxima_entrega": { ... },
    "progresso": {
        "entregues": 1,
        "faltam": 2,
        "total": 3
    },
    "rota_concluida": false
}
```

**Response (200) - Última entrega:**
```json
{
    "message": "Entrega confirmada! OS finalizada com sucesso.",
    "os": {
        "numos": 123456,
        "codprod": 7890,
        "descricao": "PRODUTO XYZ",
        "endereco": "C.05.01.02"
    },
    "proxima_entrega": null,
    "progresso": {
        "entregues": 3,
        "faltam": 0,
        "total": 3
    },
    "rota_concluida": true
}
```

**Response (422) - Endereço incorreto:**
```json
{
    "message": "Endereço não confere. Verifique se está no local correto.",
    "endereco_esperado": "C.05.01.02"
}
```

**Response (422) - Produto incorreto:**
```json
{
    "message": "Produto não confere. Verifique se é o produto correto.",
    "produto_esperado": "PRODUTO XYZ"
}
```

---

## Códigos de Erro

| Código | Descrição |
|--------|-----------|
| 200 | Sucesso |
| 400 | Requisição inválida (parâmetros faltando ou inválidos) |
| 401 | Não autenticado (token inválido ou expirado) |
| 403 | Sem permissão para a operação |
| 404 | Recurso não encontrado |
| 422 | Erro de validação ou regra de negócio |
| 500 | Erro interno do servidor |

---

## Permissões

| Permissão | Descrição |
|-----------|-----------|
| `wms.fase1` | Acesso às operações da Fase 1 |
| `wms.fase2` | Acesso às operações da Fase 2 |
| `wms.os.autorizar-saida` | Autorizar saída de operador de uma OS |
| `wms.os.liberar-ordem` | Autorizar início de OS fora da ordem |
| `wms.os.liberar-rua` | Liberar operador de uma rua |
| `wms.operadores.view` | Visualizar operadores alocados (painel web) |

---

## Configurações do Sistema

Configurações gerenciadas via painel web (`WmsConfiguracao`):

| Chave | Descrição | Padrão |
|-------|-----------|--------|
| `tipoos_abastecimento` | Tipo de OS para filtrar | `null` |
| `tentativas_conferencia` | Máx. tentativas na conferência cega | `3` |

---

## Changelog

### v2.2.0 (2026-01-19)
- **BREAKING**: `POST /fase2/os/{numos}/confirmar-entrega` agora exige `codigo_barras_produto` além do `codigo_barras_endereco`
- Fluxo otimizado: bipa endereço + bipa produto em uma única chamada
- Response agora inclui `progresso` com contagem de entregas
- Não precisa mais chamar `GET /proxima-entrega` após cada entrega
- **NOVO**: `POST /fase2/os/{numos}/divergencia` para registrar divergência na Fase 2 (quantidade errada no picking)

### v2.1.0 (2026-01-19)
- Fase 2: Obrigatório bipar unitizador antes de conferir itens
- Salva `matricula_bipou` e `dt_bipagem` na tabela `unitizadores`
- `POST /fase2/os/{numos}/conferir-produto` retorna erro 422 se unitizador não foi bipado

### v2.0.0 (2026-01-19)
- **BREAKING**: Não é mais permitido separar com quantidade diferente na Fase 1
- Operador fica "preso na rua" até finalizar ou ser liberado
- Novo endpoint `GET /fase1/minha-rua`
- Novo endpoint `POST /fase1/liberar-rua`
- Response de `POST /fase1/finalizar` agora inclui `proxima_os` e `rua_concluida`
- Response de `POST /fase1/iniciar` agora inclui `rua`
