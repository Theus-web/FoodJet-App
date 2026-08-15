const bcrypt = require("bcrypt");
const { db } = require("../config/database");

async function criarContaRestaurante() {
    try {
        // ==========================================
        // DADOS DA CONTA
        // ==========================================

        const nome = "Pizzaria do João";
        const email = "pizzaria@foodjet.com";
        const senha = "123456";

        // ID DO RESTAURANTE EXISTENTE
        const restauranteId = 1784400784535;

        // ==========================================
        // CARREGAR BANCO
        // ==========================================

        await db.read();

        if (!db.data) {
            db.data = {};
        }

        if (!db.data.usuarios) {
            db.data.usuarios = [];
        }

        if (!db.data.restaurantes) {
            db.data.restaurantes = [];
        }

        // ==========================================
        // VERIFICAR RESTAURANTE
        // ==========================================

        const restaurante =
            db.data.restaurantes.find(
                item =>
                    String(item.id) ===
                    String(restauranteId)
            );

        if (!restaurante) {
            console.log(
                "ERRO: Restaurante não encontrado."
            );

            console.log(
                "ID:",
                restauranteId
            );

            return;
        }

        console.log(
            "RESTAURANTE ENCONTRADO:",
            restaurante.nome
        );

        // ==========================================
        // VERIFICAR E-MAIL
        // ==========================================

        const emailNormalizado =
            email.trim().toLowerCase();

        const usuarioExistente =
            db.data.usuarios.find(
                usuario =>
                    usuario.email &&
                    usuario.email
                        .trim()
                        .toLowerCase() ===
                    emailNormalizado
            );

        if (usuarioExistente) {
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
            Date.now();

        // ==========================================
        // CRIPTOGRAFAR SENHA
        // ==========================================

        const senhaHash =
            await bcrypt.hash(
                senha,
                10
            );

        // ==========================================
        // CRIAR CONTA
        // ==========================================

        const novoUsuario = {
            id: novoUsuarioId,
            nome: nome,
            email: emailNormalizado,
            senha: senhaHash,
            tipo: "RESTAURANTE",
            restauranteId: restauranteId
        };

        // ==========================================
        // SALVAR
        // ==========================================

        db.data.usuarios.push(
            novoUsuario
        );

        await db.write();

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
            novoUsuario.id
        );

        console.log(
            "NOME:",
            novoUsuario.nome
        );

        console.log(
            "EMAIL:",
            novoUsuario.email
        );

        console.log(
            "SENHA:",
            senha
        );

        console.log(
            "TIPO:",
            novoUsuario.tipo
        );

        console.log(
            "RESTAURANTE ID:",
            novoUsuario.restauranteId
        );

        console.log(
            "=========================================="
        );

    } catch (erro) {

        console.error(
            "ERRO AO CRIAR CONTA RESTAURANTE:"
        );

        console.error(erro);
    }
}

// ==========================================
// EXECUTAR
// ==========================================

criarContaRestaurante();