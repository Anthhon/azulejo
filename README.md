# Azulejo

Linguagem esotérica de propósito específico para criação de **pixel art e arte digital**.  
Arquivos Azulejo têm extensão `.azlj`. O tradutor gera código Lua executável via **LÖVE2D**.

---

## Propósito

Grafite é uma linguagem de domínio específico (DSL) declarativa para desenho em grade de pixels.  
Cada programa descreve uma cena visual usando comandos de desenho simples. Não é Turing-completa 
e nem precisa ser.

---

## Extensão

| Arquivo | Descrição |
|---------|-----------|
| `.azlj` | Código-fonte |
| `main.lua` | Saída gerada pelo tradutor (roda em LÖVE2D) |

---

## Tipos Suportados

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `int` | Inteiro positivo | `16`, `255` |
| `coord` | Par de coordenadas `x,y` | `2,4` |
| `size` | Dimensão `LxA` | `16x16` |
| `color` | RGB em hex | `#FF0000` |
| `label` | Nome de bloco/sprite | `@rosto` |

---

## Comandos

### Canvas

```
size LARGURAxALTURA
```
Define o tamanho do canvas em pixels. **Obrigatório, deve ser o primeiro comando.**

```
background #RRGGBB
```
Preenche o fundo com cor sólida. Padrão: `#000000`.

---

### Cor

```
color #RRGGBB
```
Define cor ativa para os próximos comandos de desenho.

---

### Primitivas de Desenho

```
pixel x,y
```
Desenha pixel único em `x,y`.

```
line x1,y1 x2,y2
```
Linha de `(x1,y1)` até `(x2,y2)`.

```
rect x1,y1 x2,y2
```
Retângulo vazio com canto superior-esquerdo `(x1,y1)` e inferior-direito `(x2,y2)`.

```
fill x1,y1 x2,y2
```
Retângulo preenchido.

```
circle x,y r
```
Círculo com centro `(x,y)` e raio `r`.

---

### Repetição

(NÃO IMPLEMENTADO)

```
repeat N:
  <comandos>
end
```
Executa bloco `N` vezes. Variável implícita `$i` (começa em 0).

```
repeat N with dx,dy:
  <comandos>
end
```

Repete `N` vezes deslocando origem em `dx,dy` a cada iteração.  
Útil para padrões e grades.

---

### Blocos (Sprites)

(NÃO IMPLEMENTADO)

```
sprite @nome:
  <comandos>
end
```

Define sprite reutilizável nomeado.

```
stamp @nome x,y
```

Desenha sprite `@nome` com origem em `(x,y)`.

---

### Comentários

```
-- comentário de linha
```

---

## Exemplo Mínimo

```grf
-- hello.azlj
size 16x16
background #1a1a2e

color #e94560
fill 4,4 12,12

color #ffffff
pixel 6,7
pixel 10,7
line 6,10 10,10
```

---

## Estrutura do Projeto

```
azulejo/
├── README.md
├── translator/
├── examples/ # Códigos de exemplo
│   ├── hello.grf           # Hello World (smiley face)
│   ├── cervejas.grf        # 99 garrafas de cerveja
│   └── bandeira.grf        # programa livre
└── output/
    └── main.lua            # saída gerada (não editar)
```

---

## Como Executar

### Dependências

- Python 3.8+ (tradutor)
- [LÖVE2D 11.x](https://love2d.org/)

### Passo a passo

```bash
# 1. Traduzir arquivo .grf para Lua
python translator/translator.py examples/hello.grf

# 2. Executar com LÖVE2D (output sempre em output/main.lua)
love output/
```

> No Windows: `love.exe output/`  
> No macOS: `/Applications/love.app/Contents/MacOS/love output/`

---

## Erros Comuns

| Erro | Causa |
|------|-------|
| `size não definido` | Faltou comando `size` como primeira linha |
| `cor inválida` | Hex malformado — use exatamente `#RRGGBB` |
| `coord fora do canvas` | Coordenada maior que tamanho definido em `size` |
| `sprite não declarado` | `stamp` chamado antes de `sprite @nome:` |

---

## Limitações Atuais (v1.0)

- Sem variáveis nomeadas pelo usuário
- Sem operações aritméticas explícitas
- Sem entrada de usuário (linguagem declarativa pura)
- Canvas estático — sem animação

---

*Grafite — desenhe com palavras.*
