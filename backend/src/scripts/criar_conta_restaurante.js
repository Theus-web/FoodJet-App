const bcrypt = require("bcrypt");
const { pool } = require("../config/database");

async function criarContaRestaurante() {
    try {
        // ==========================================
        // DADOS DA CONTA
        // ==========================================

        const nome = "Pizzaria do João";
        const email = "pizzaria@foodjet.com";
        const senha = "123456";

        // ID DO RESTAURANTE EXISTENTE
        const restauranteId = "1784400784535";

        // ==========================================
        // VERIFICAR RESTAURANTE NO POSTGRESQL
        // ==========================================

        const restauranteResult = await pool.query(
            `
            SELECT
                id,
                nome
            FROM restaurantes
            WHERE id = $1
            LIMIT 1
            `,
            [restauranteId]
        );

        if (restauranteResult.rows.length === 0) {
            console.log(
                "ERRO: Restaurante não encontrado."
            );

            console.log(
                "ID:",
                restauranteId
            );

            return;
        }

        const restaurante =
            restauranteResult.rows[0];

        console.log(
            "RESTAURANTE ENCONTRADO:",
            restaurante.nome
        );

        // ==========================================
        // NORMALIZAR E-MAIL
        // ==========================================

        const emailNormalizado =
            email.trim().toLowerCase();

        // ==========================================
        // VERIFICAR E-MAIL NO POSTGRESQL
        // ==========================================

        const usuarioExistenteResult =
            await pool.query(
                `
                SELECT
                    id,
                    email,
                    tipo
                FROM usuarios
                WHERE LOWER(TRIM(email)) = $1
                LIMIT 1
                `,
                [emailNormalizado]
            );

        if (usuarioExistenteResult.rows.length > 0) {
            const usuarioExistente =
                usuarioExistenteResult.rows[0];

            console.log(
                "ERRO: E-mail já cadastrado."
            );

            console.log(
                "E-mail:",
                usuarioExistente.email
            );

            console.log(
                "Tipo:",
                usuarioExistente.tipo
            );

            return;
        }

        // ==========================================
        // GERAR ID
        // ==========================================

        const novoUsuarioId =
            String(Date.now());

        // ==========================================
        // CRIPTOGRAFAR SENHA
        // ==========================================

        const senhaHash =
            await bcrypt.hash(
                senha,
                10
            );

        // ==========================================
        // DADOS DO USUÁRIO
        // ==========================================

        const dadosUsuario = {
            id: novoUsuarioId,
            nome,
            email: emailNormalizado,
            tipo: "RESTAURANTE",
            restauranteId,
        };

        // ==========================================
        // CRIAR CONTA NO POSTGRESQL
        // ==========================================

        await pool.query(
            `
            INSERT INTO usuarios (
                id,
                nome,
                email,
                senha,
                tipo,
                restaurante_id,
                dados,
                criado_em,
                atualizado_em
            )
            VALUES (
                $1,
                $2,
                $3,
                $4,
                $5,
                $6,
                $7::jsonb,
                NOW(),
                NOW()
            )
            `,
            [
                novoUsuarioId,
                nome,
                emailNormalizado,
                senhaHash,
                "RESTAURANTE",
                restauranteId,
                JSON.stringify(dadosUsuario),
            ]
        );

        // ==========================================
        // RESULTADO
        // ==========================================

        console.log("");
        console.log(
            "=========================================="
        );

        console.log(
            "CONTA RESTAURANTE CRIADA COM SUCESSO!"
        );

        console.log(
            "=========================================="
        );

        console.log(
            "ID:",
            novoUsuarioId
        );

        console.log(
            "NOME:",
            nome
        );

        console.log(
            "EMAIL:",
            emailNormalizado
        );

        console.log(
            "SENHA:",
            senha
        );

        console.log(
            "TIPO:",
            "RESTAURANTE"
        );

        console.log(
            "RESTAURANTE ID:",
            restauranteId
        );

        console.log(
            "=========================================="
        );

    } catch (erro) {

        console.error(
            "ERRO AO CRIAR CONTA RESTAURANTE:"
        );

        console.error(erro);

    } finally {

        // ==========================================
        // ENCERRAR CONEXÃO
        // ==========================================

        await pool.end();

    }
}

// ==========================================
// EXECUTAR
// ==========================================

criarContaRestaurante();