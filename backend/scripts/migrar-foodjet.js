const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");

// ============================================================
// CONFIGURAÇÃO
// ============================================================

if (!process.env.DATABASE_URL) {
    require("dotenv").config();
}

if (!process.env.DATABASE_URL) {
    throw new Error(
        "❌ DATABASE_URL não encontrada."
    );
}

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false,
    },
});

// ============================================================
// CAMINHO DO FOODJET.JSON
// ============================================================

const caminhoBanco = path.join(
    __dirname,
    "..",
    "foodjet.json"
);

// ============================================================
// LER JSON
// ============================================================

function carregarBancoJson() {

    if (!fs.existsSync(caminhoBanco)) {

        throw new Error(
            `❌ foodjet.json não encontrado em:\n${caminhoBanco}`
        );
    }

    const conteudo =
        fs.readFileSync(
            caminhoBanco,
            "utf8"
        );

    return JSON.parse(conteudo);
}

// ============================================================
// NORMALIZAR ID
// ============================================================

function idTexto(valor) {

    if (
        valor === undefined ||
        valor === null ||
        valor === ""
    ) {
        return null;
    }

    return String(valor);
}

// ============================================================
// NORMALIZAR DATA
// ============================================================

function dataOuNull(valor) {

    if (
        valor === undefined ||
        valor === null ||
        valor === ""
    ) {
        return null;
    }

    const data = new Date(valor);

    if (Number.isNaN(data.getTime())) {
        return null;
    }

    return data;
}

// ============================================================
// NORMALIZAR NÚMERO
// ============================================================

function numeroOuZero(valor) {

    if (
        valor === undefined ||
        valor === null ||
        valor === ""
    ) {
        return 0;
    }

    const numero = Number(valor);

    return Number.isFinite(numero)
        ? numero
        : 0;
}

// ============================================================
// NORMALIZAR JSONB
// ============================================================

function jsonb(valor, padrao = null) {

    if (
        valor === undefined ||
        valor === null
    ) {
        return padrao === null
            ? null
            : JSON.stringify(padrao);
    }

    // Se já for objeto/array, transforma explicitamente
    // em JSON para o PostgreSQL.
    if (
        typeof valor === "object"
    ) {
        return JSON.stringify(valor);
    }

    // Se for string, tenta descobrir se já é JSON.
    if (
        typeof valor === "string"
    ) {

        try {

            const convertido =
                JSON.parse(valor);

            return JSON.stringify(convertido);

        } catch (_) {

            // É uma string comum.
            // Também é válida como JSON string.
            return JSON.stringify(valor);
        }
    }

    return JSON.stringify(valor);
}

// ============================================================
// CRIAR TABELAS
// ============================================================

async function criarTabelas(client) {

    console.log("");
    console.log("============================================");
    console.log("🗄️ CRIANDO TABELAS POSTGRESQL");
    console.log("============================================");

    await client.query(`
        CREATE TABLE IF NOT EXISTS usuarios (
            id TEXT PRIMARY KEY,
            nome TEXT,
            email TEXT,
            senha TEXT,
            tipo TEXT,
            restaurante_id TEXT,
            telefone TEXT,
            cpf TEXT,
            endereco JSONB,
            criado_em TIMESTAMPTZ,
            atualizado_em TIMESTAMPTZ,
            dados JSONB NOT NULL DEFAULT '{}'::jsonb
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS restaurantes (
            id TEXT PRIMARY KEY,
            nome TEXT,
            cnpj TEXT,
            categoria TEXT,
            email TEXT,
            telefone TEXT,
            responsavel TEXT,
            cpf TEXT,
            endereco JSONB,
            pagamento JSONB,
            status TEXT,
            online BOOLEAN,
            aberto BOOLEAN,
            imagem TEXT,
            criado_em TIMESTAMPTZ,
            atualizado_em TIMESTAMPTZ,
            dados JSONB NOT NULL DEFAULT '{}'::jsonb
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS produtos (
            id TEXT PRIMARY KEY,
            restaurante_id TEXT,
            nome TEXT,
            descricao TEXT,
            preco NUMERIC(12,4),
            categoria TEXT,
            disponivel BOOLEAN,
            destaque BOOLEAN,
            imagem TEXT,
            criado_em TIMESTAMPTZ,
            dados JSONB NOT NULL DEFAULT '{}'::jsonb
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS pedidos (
            id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
            cliente_id TEXT,
            restaurante_id TEXT,
            itens JSONB NOT NULL DEFAULT '[]'::jsonb,
            endereco JSONB,
            pagamento TEXT,
            pagamento_status TEXT,
            status_pagamento TEXT,
            pagamento_aprovado BOOLEAN,
            subtotal NUMERIC(12,4),
            taxa_servico NUMERIC(12,4),
            taxa_entrega NUMERIC(12,4),
            total NUMERIC(12,4),
            precisa_troco BOOLEAN,
            troco_para NUMERIC(12,4),
            valor_troco NUMERIC(12,4),
            external_reference TEXT,
            referencia_pagamento TEXT,
            status TEXT,
            suporte JSONB,
            criado_em TIMESTAMPTZ,
            atualizado_em TIMESTAMPTZ,
            dados JSONB NOT NULL DEFAULT '{}'::jsonb
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS entregadores (
            id TEXT PRIMARY KEY,
            nome TEXT,
            email TEXT,
            telefone TEXT,
            cpf TEXT,
            status TEXT,
            online BOOLEAN,
            dados JSONB NOT NULL DEFAULT '{}'::jsonb
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS pagamentos (
            id TEXT PRIMARY KEY,
            pedido_id TEXT,
            status TEXT,
            valor NUMERIC(12,4),
            dados JSONB NOT NULL DEFAULT '{}'::jsonb,
            criado_em TIMESTAMPTZ
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS pagamentos_asaas (
            id TEXT PRIMARY KEY,
            pagamento_id TEXT,
            pedido_id TEXT,
            external_reference TEXT,
            status TEXT,
            valor NUMERIC(12,4),
            dados JSONB NOT NULL DEFAULT '{}'::jsonb,
            criado_em TIMESTAMPTZ,
            atualizado_em TIMESTAMPTZ
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS promocoes (
            id TEXT PRIMARY KEY,
            restaurante_id TEXT,
            produto_id TEXT,
            titulo TEXT,
            descricao TEXT,
            preco_original NUMERIC(12,4),
            preco_promocional NUMERIC(12,4),
            desconto NUMERIC(12,4),
            inicio TIMESTAMPTZ,
            fim TIMESTAMPTZ,
            ativa BOOLEAN,
            criado_em TIMESTAMPTZ,
            dados JSONB NOT NULL DEFAULT '{}'::jsonb
        );
    `);

    await client.query(`
        CREATE TABLE IF NOT EXISTS favoritos (
            id TEXT PRIMARY KEY,
            usuario_id TEXT,
            restaurante_id TEXT,
            nome TEXT,
            descricao TEXT,
            avaliacao TEXT,
            logo TEXT,
            dados JSONB NOT NULL DEFAULT '{}'::jsonb
        );
    `);

    console.log("✅ Tabelas criadas/verificadas.");
}

// ============================================================
// USUÁRIOS
// ============================================================

async function migrarUsuarios(client, dados) {

    const lista =
        Array.isArray(dados.usuarios)
            ? dados.usuarios
            : [];

    for (const usuario of lista) {

        const id = idTexto(usuario.id);

        if (!id) {
            console.log(
                "⚠️ Usuário ignorado: sem ID."
            );
            continue;
        }

        await client.query(
            `
            INSERT INTO usuarios (
                id,
                nome,
                email,
                senha,
                tipo,
                restaurante_id,
                telefone,
                cpf,
                endereco,
                criado_em,
                atualizado_em,
                dados
            )
            VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12
            )
            ON CONFLICT (id)
            DO UPDATE SET
                nome = EXCLUDED.nome,
                email = EXCLUDED.email,
                senha = EXCLUDED.senha,
                tipo = EXCLUDED.tipo,
                restaurante_id = EXCLUDED.restaurante_id,
                telefone = EXCLUDED.telefone,
                cpf = EXCLUDED.cpf,
                endereco = EXCLUDED.endereco,
                criado_em = EXCLUDED.criado_em,
                atualizado_em = EXCLUDED.atualizado_em,
                dados = EXCLUDED.dados
            `,
            [
                id,
                usuario.nome || null,
                usuario.email || null,
                usuario.senha || null,
                usuario.tipo || null,
                idTexto(usuario.restauranteId),
                usuario.telefone || null,
                usuario.cpf || null,
                jsonb(usuario.endereco),
                dataOuNull(usuario.criadoEm),
                dataOuNull(usuario.atualizadoEm),
                jsonb(usuario),
            ]
        );
    }

    console.log(
        `👥 Usuários migrados: ${lista.length}`
    );
}

// ============================================================
// RESTAURANTES
// ============================================================

async function migrarRestaurantes(client, dados) {

    const lista =
        Array.isArray(dados.restaurantes)
            ? dados.restaurantes
            : [];

    for (const restaurante of lista) {

        const id = idTexto(restaurante.id);

        if (!id) {
            continue;
        }

        await client.query(
            `
            INSERT INTO restaurantes (
                id,
                nome,
                cnpj,
                categoria,
                email,
                telefone,
                responsavel,
                cpf,
                endereco,
                pagamento,
                status,
                online,
                aberto,
                imagem,
                criado_em,
                atualizado_em,
                dados
            )
            VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
                $11,$12,$13,$14,$15,$16,$17
            )
            ON CONFLICT (id)
            DO UPDATE SET
                nome = EXCLUDED.nome,
                cnpj = EXCLUDED.cnpj,
                categoria = EXCLUDED.categoria,
                email = EXCLUDED.email,
                telefone = EXCLUDED.telefone,
                responsavel = EXCLUDED.responsavel,
                cpf = EXCLUDED.cpf,
                endereco = EXCLUDED.endereco,
                pagamento = EXCLUDED.pagamento,
                status = EXCLUDED.status,
                online = EXCLUDED.online,
                aberto = EXCLUDED.aberto,
                imagem = EXCLUDED.imagem,
                criado_em = EXCLUDED.criado_em,
                atualizado_em = EXCLUDED.atualizado_em,
                dados = EXCLUDED.dados
            `,
            [
                id,
                restaurante.nome || null,
                restaurante.cnpj || null,
                restaurante.categoria || null,
                restaurante.email || null,
                restaurante.telefone || null,
                restaurante.responsavel || null,
                restaurante.cpf || null,
                jsonb(restaurante.endereco),
jsonb(restaurante.pagamento),
                restaurante.status || null,
                Boolean(restaurante.online),
                Boolean(restaurante.aberto),
                restaurante.imagem || null,
                dataOuNull(restaurante.criadoEm),
                dataOuNull(restaurante.atualizadoEm),
                jsonb(restaurante),
            ]
        );
    }

    console.log(
        `🏪 Restaurantes migrados: ${lista.length}`
    );
}

// ============================================================
// PRODUTOS
// ============================================================

async function migrarProdutos(client, dados) {

    const lista =
        Array.isArray(dados.produtos)
            ? dados.produtos
            : [];

    for (const produto of lista) {

        const id = idTexto(produto.id);

        if (!id) {
            continue;
        }

        await client.query(
            `
            INSERT INTO produtos (
                id,
                restaurante_id,
                nome,
                descricao,
                preco,
                categoria,
                disponivel,
                destaque,
                imagem,
                criado_em,
                dados
            )
            VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11
            )
            ON CONFLICT (id)
            DO UPDATE SET
                restaurante_id = EXCLUDED.restaurante_id,
                nome = EXCLUDED.nome,
                descricao = EXCLUDED.descricao,
                preco = EXCLUDED.preco,
                categoria = EXCLUDED.categoria,
                disponivel = EXCLUDED.disponivel,
                destaque = EXCLUDED.destaque,
                imagem = EXCLUDED.imagem,
                criado_em = EXCLUDED.criado_em,
                dados = EXCLUDED.dados
            `,
            [
                id,
                idTexto(produto.restauranteId),
                produto.nome || null,
                produto.descricao || produto.descrição || null,
                numeroOuZero(produto.preco),
                produto.categoria || null,
                produto.disponivel !== false,
                Boolean(produto.destaque),
                produto.imagem || null,
                dataOuNull(
                    produto.criadoEm ||
                    produto.createdAt
                ),
                produto,
            ]
        );
    }

    console.log(
        `🍕 Produtos migrados: ${lista.length}`
    );
}

// ============================================================
// PEDIDOS
// ============================================================

async function migrarPedidos(client, dados) {

    const lista =
        Array.isArray(dados.pedidos)
            ? dados.pedidos
            : [];

    // --------------------------------------------------------
    // Descobrir maior ID existente
    // --------------------------------------------------------

    let maiorId = 0;

    for (const pedido of lista) {

        const numero =
            Number(pedido.id);

        if (
            Number.isSafeInteger(numero) &&
            numero > maiorId
        ) {
            maiorId = numero;
        }
    }

    for (const pedido of lista) {

        let id =
            Number(pedido.id);

        // ----------------------------------------------------
        // Pedido sem ID
        // ----------------------------------------------------

        if (
            !Number.isSafeInteger(id) ||
            id <= 0
        ) {

            maiorId++;

            id = maiorId;

            console.log(
                `⚠️ Pedido sem ID encontrado. ` +
                `Novo ID atribuído: ${id}`
            );
        }

        await client.query(
            `
            INSERT INTO pedidos (
                id,
                cliente_id,
                restaurante_id,
                itens,
                endereco,
                pagamento,
                pagamento_status,
                status_pagamento,
                pagamento_aprovado,
                subtotal,
                taxa_servico,
                taxa_entrega,
                total,
                precisa_troco,
                troco_para,
                valor_troco,
                external_reference,
                referencia_pagamento,
                status,
                suporte,
                criado_em,
                atualizado_em,
                dados
            )
            VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
                $11,$12,$13,$14,$15,$16,$17,$18,
                $19,$20,$21,$22,$23
            )
            ON CONFLICT (id)
            DO UPDATE SET
                cliente_id = EXCLUDED.cliente_id,
                restaurante_id = EXCLUDED.restaurante_id,
                itens = EXCLUDED.itens,
                endereco = EXCLUDED.endereco,
                pagamento = EXCLUDED.pagamento,
                pagamento_status = EXCLUDED.pagamento_status,
                status_pagamento = EXCLUDED.status_pagamento,
                pagamento_aprovado = EXCLUDED.pagamento_aprovado,
                subtotal = EXCLUDED.subtotal,
                taxa_servico = EXCLUDED.taxa_servico,
                taxa_entrega = EXCLUDED.taxa_entrega,
                total = EXCLUDED.total,
                precisa_troco = EXCLUDED.precisa_troco,
                troco_para = EXCLUDED.troco_para,
                valor_troco = EXCLUDED.valor_troco,
                external_reference = EXCLUDED.external_reference,
                referencia_pagamento = EXCLUDED.referencia_pagamento,
                status = EXCLUDED.status,
                suporte = EXCLUDED.suporte,
                criado_em = EXCLUDED.criado_em,
                atualizado_em = EXCLUDED.atualizado_em,
                dados = EXCLUDED.dados
            `,
            [
                id,
                idTexto(pedido.clienteId),
                idTexto(pedido.restauranteId),
                jsonb(
    Array.isArray(pedido.itens)
        ? pedido.itens
        : []
),

jsonb(pedido.endereco),
                pedido.pagamento || null,
                pedido.pagamentoStatus || null,
                pedido.statusPagamento || null,
                pedido.pagamentoAprovado === true,
                numeroOuZero(pedido.subtotal),
                numeroOuZero(pedido.taxaServico),
                numeroOuZero(pedido.taxaEntrega),
                numeroOuZero(pedido.total),
                pedido.precisaTroco === true,
                pedido.trocoPara !== undefined
                    ? numeroOuZero(pedido.trocoPara)
                    : null,
                pedido.valorTroco !== undefined
                    ? numeroOuZero(pedido.valorTroco)
                    : null,
                pedido.externalReference
                    ? String(pedido.externalReference)
                    : null,
                pedido.referenciaPagamento
                    ? String(pedido.referenciaPagamento)
                    : null,
                pedido.status || null,
                jsonb(pedido.suporte),
                dataOuNull(
                    pedido.criadoEm ||
                    pedido.createdAt ||
                    pedido.data
                ),
                dataOuNull(
                    pedido.atualizadoEm ||
                    pedido.updatedAt
                ),
                jsonb(pedido),
            ]
        );
    }

    // --------------------------------------------------------
    // Ajustar sequência
    // --------------------------------------------------------

    await client.query(`
        SELECT setval(
            pg_get_serial_sequence(
                'pedidos',
                'id'
            ),
            COALESCE(
                (SELECT MAX(id) FROM pedidos),
                1
            ),
            true
        )
    `);

    console.log(
        `📦 Pedidos migrados: ${lista.length}`
    );
}

// ============================================================
// ENTREGADORES
// ============================================================

async function migrarEntregadores(client, dados) {

    const lista =
        Array.isArray(dados.entregadores)
            ? dados.entregadores
            : [];

    for (const entregador of lista) {

        const id =
            idTexto(entregador.id);

        if (!id) {
            continue;
        }

        await client.query(
            `
            INSERT INTO entregadores (
                id,
                nome,
                email,
                telefone,
                cpf,
                status,
                online,
                dados
            )
            VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8
            )
            ON CONFLICT (id)
            DO UPDATE SET
                nome = EXCLUDED.nome,
                email = EXCLUDED.email,
                telefone = EXCLUDED.telefone,
                cpf = EXCLUDED.cpf,
                status = EXCLUDED.status,
                online = EXCLUDED.online,
                dados = EXCLUDED.dados
            `,
            [
                id,
                entregador.nome || null,
                entregador.email || null,
                entregador.telefone || null,
                entregador.cpf || null,
                entregador.status || null,
                Boolean(entregador.online),
                jsonb(entregador),
            ]
        );
    }

    console.log(
        `🏍️ Entregadores migrados: ${lista.length}`
    );
}

// ============================================================
// PAGAMENTOS
// ============================================================

async function migrarPagamentos(client, dados) {

    const lista =
        Array.isArray(dados.pagamentos)
            ? dados.pagamentos
            : [];

    for (let i = 0; i < lista.length; i++) {

        const pagamento = lista[i];

        const id =
            idTexto(
                pagamento.id ||
                pagamento.paymentId ||
                `legacy_${i + 1}`
            );

        await client.query(
            `
            INSERT INTO pagamentos (
                id,
                pedido_id,
                status,
                valor,
                dados,
                criado_em
            )
            VALUES (
                $1,$2,$3,$4,$5,$6
            )
            ON CONFLICT (id)
            DO UPDATE SET
                pedido_id = EXCLUDED.pedido_id,
                status = EXCLUDED.status,
                valor = EXCLUDED.valor,
                dados = EXCLUDED.dados,
                criado_em = EXCLUDED.criado_em
            `,
            [
                id,
                idTexto(
                    pagamento.pedidoId ||
                    pagamento.orderId
                ),
                pagamento.status || null,
                pagamento.valor !== undefined
                    ? numeroOuZero(pagamento.valor)
                    : null,
                jsonb(pagamento),
                dataOuNull(
                    pagamento.criadoEm ||
                    pagamento.createdAt
                ),
            ]
        );
    }

    console.log(
        `💳 Pagamentos migrados: ${lista.length}`
    );
}

// ============================================================
// PROMOÇÕES
// ============================================================

async function migrarPromocoes(client, dados) {

    const lista =
        Array.isArray(dados.promocoes)
            ? dados.promocoes
            : [];

    for (const promocao of lista) {

        const id =
            idTexto(promocao.id);

        if (!id) {
            continue;
        }

        await client.query(
            `
            INSERT INTO promocoes (
                id,
                restaurante_id,
                produto_id,
                titulo,
                descricao,
                preco_original,
                preco_promocional,
                desconto,
                inicio,
                fim,
                ativa,
                criado_em,
                dados
            )
            VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13
            )
            ON CONFLICT (id)
            DO UPDATE SET
                restaurante_id = EXCLUDED.restaurante_id,
                produto_id = EXCLUDED.produto_id,
                titulo = EXCLUDED.titulo,
                descricao = EXCLUDED.descricao,
                preco_original = EXCLUDED.preco_original,
                preco_promocional = EXCLUDED.preco_promocional,
                desconto = EXCLUDED.desconto,
                inicio = EXCLUDED.inicio,
                fim = EXCLUDED.fim,
                ativa = EXCLUDED.ativa,
                criado_em = EXCLUDED.criado_em,
                dados = EXCLUDED.dados
            `,
            [
                id,
                idTexto(promocao.restauranteId),
                idTexto(promocao.produtoId),
                promocao.titulo ||
                    promocao.nome ||
                    promocao.title ||
                    null,
                promocao.descricao ||
                    promocao.description ||
                    null,
                numeroOuZero(
                    promocao.precoOriginal
                ),
                numeroOuZero(
                    promocao.precoPromocional
                ),
                numeroOuZero(
                    promocao.desconto
                ),
                dataOuNull(promocao.inicio),
                dataOuNull(promocao.fim),
                promocao.ativa !== false,
                dataOuNull(
                    promocao.criadoEm ||
                    promocao.createdAt
                ),
                jsonb(promocao),
            ]
        );
    }

    console.log(
        `🎟️ Promoções migradas: ${lista.length}`
    );
}

// ============================================================
// FAVORITOS
// ============================================================

async function migrarFavoritos(client, dados) {

    const lista =
        Array.isArray(dados.favoritos)
            ? dados.favoritos
            : [];

    for (let i = 0; i < lista.length; i++) {

        const favorito = lista[i];

        const id =
            idTexto(
                favorito.id ||
                `legacy_favorito_${i + 1}`
            );

        await client.query(
            `
            INSERT INTO favoritos (
                id,
                usuario_id,
                restaurante_id,
                nome,
                descricao,
                avaliacao,
                logo,
                dados
            )
            VALUES (
                $1,$2,$3,$4,$5,$6,$7,$8
            )
            ON CONFLICT (id)
            DO UPDATE SET
                usuario_id = EXCLUDED.usuario_id,
                restaurante_id = EXCLUDED.restaurante_id,
                nome = EXCLUDED.nome,
                descricao = EXCLUDED.descricao,
                avaliacao = EXCLUDED.avaliacao,
                logo = EXCLUDED.logo,
                dados = EXCLUDED.dados
            `,
            [
                id,
                idTexto(favorito.usuarioId),
                idTexto(favorito.restauranteId),
                favorito.nome || null,
                favorito.descricao || null,
                favorito.avaliacao !== undefined
                    ? String(favorito.avaliacao)
                    : null,
                favorito.logo || null,
                jsonb(favorito),
            ]
        );
    }

    console.log(
        `❤️ Favoritos migrados: ${lista.length}`
    );
}

// ============================================================
// RESUMO
// ============================================================

async function mostrarResumo(client) {

    console.log("");
    console.log("============================================");
    console.log("📊 RESUMO POSTGRESQL");
    console.log("============================================");

    const tabelas = [
        ["usuarios", "👥"],
        ["restaurantes", "🏪"],
        ["produtos", "🍕"],
        ["pedidos", "📦"],
        ["entregadores", "🏍️"],
        ["pagamentos", "💳"],
        ["pagamentos_asaas", "💰"],
        ["promocoes", "🎟️"],
        ["favoritos", "❤️"],
    ];

    for (const [tabela, emoji] of tabelas) {

        const resultado =
            await client.query(
                `SELECT COUNT(*)::int AS total FROM ${tabela}`
            );

        console.log(
            `${emoji} ${tabela}:`,
            resultado.rows[0].total
        );
    }

    console.log("");
}

// ============================================================
// MIGRAÇÃO PRINCIPAL
// ============================================================

async function migrar() {

    const client =
        await pool.connect();

    try {

        console.log("");
        console.log("============================================");
        console.log("🚀 MIGRAÇÃO FOODJET");
        console.log("============================================");

        console.log(
            "📂 Arquivo:",
            caminhoBanco
        );

        const dados =
            carregarBancoJson();

        console.log("✅ foodjet.json carregado.");

        await client.query("BEGIN");

        await criarTabelas(client);

        await migrarUsuarios(
            client,
            dados
        );

        await migrarRestaurantes(
            client,
            dados
        );

        await migrarProdutos(
            client,
            dados
        );

        await migrarPedidos(
            client,
            dados
        );

        await migrarEntregadores(
            client,
            dados
        );

        await migrarPagamentos(
            client,
            dados
        );

        await migrarPromocoes(
            client,
            dados
        );

        await migrarFavoritos(
            client,
            dados
        );

        await client.query("COMMIT");

        await mostrarResumo(client);

        console.log(
            "============================================"
        );

        console.log(
            "🎉 MIGRAÇÃO CONCLUÍDA COM SUCESSO!"
        );

        console.log(
            "============================================"
        );

    } catch (error) {

        try {
            await client.query("ROLLBACK");
        } catch (_) {}

        console.error("");
        console.error(
            "❌ ERRO DURANTE A MIGRAÇÃO:"
        );

        console.error(error);

        process.exitCode = 1;

    } finally {

        client.release();

        await pool.end();
    }
}

// ============================================================
// EXECUTAR
// ============================================================

migrar();