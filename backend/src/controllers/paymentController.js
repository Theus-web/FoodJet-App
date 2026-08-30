
const {
    criarPix,
    criarCartao,
    criarDebito,
    consultarPagamento,
    obterQrCodePix,
} = require("../services/asaasService");

const User = require("../models/user");

const crypto = require("crypto");

// ============================================================
// REFERÊNCIA TEMPORÁRIA
// ============================================================

function gerarReferenciaTemporaria() {
    return `FOODJET-${Date.now()}-${crypto
        .randomBytes(4)
        .toString("hex")
        .toUpperCase()}`;
}


// ============================================================
// BUSCAR USUÁRIO AUTENTICADO
// ============================================================

async function buscarUsuarioAutenticado(req) {

    // Aceita os dois formatos usados pelo middleware
    const usuarioToken =
        req.usuario ||
        req.user ||
        null;

    console.log("");
    console.log("========================================");
    console.log("🔐 BUSCANDO CLIENTE AUTENTICADO");
    console.log("========================================");

    if (!usuarioToken) {

        console.error(
            "❌ NENHUM USUÁRIO ENCONTRADO NO REQUEST"
        );

        throw new Error(
            "Cliente não identificado. Faça login novamente."
        );
    }

    // Aceita diferentes nomes possíveis para o ID
    const usuarioId =
        usuarioToken.id ||
        usuarioToken.usuarioId ||
        usuarioToken.userId ||
        usuarioToken._id ||
        null;

    console.log(
        "👤 ID RECEBIDO DO TOKEN:",
        usuarioId
    );

    if (!usuarioId) {

        console.error(
            "❌ TOKEN NÃO POSSUI ID DO USUÁRIO:"
        );

        console.error(
            usuarioToken
        );

        throw new Error(
            "Cliente não identificado. Faça login novamente."
        );
    }

    // Busca o usuário real no banco
    const usuario =
        await User.buscarPorId(
            usuarioId
        );

    if (!usuario) {

        console.error(
            "❌ USUÁRIO NÃO ENCONTRADO NO BANCO:",
            usuarioId
        );

        throw new Error(
            "Cliente não identificado. Faça login novamente."
        );
    }

    console.log(
        "✅ CLIENTE ENCONTRADO"
    );

    console.log(
        "👤 ID:",
        usuario.id
    );

    console.log(
        "👤 NOME:",
        usuario.nome || "SEM NOME"
    );

    console.log(
        "📧 EMAIL:",
        usuario.email || "SEM EMAIL"
    );

    console.log(
        "📱 TELEFONE:",
        usuario.telefone ||
        usuario.celular ||
        "SEM TELEFONE"
    );

    console.log(
        "🪪 CPF:",
        usuario.cpf ||
        usuario.cpfCnpj ||
        "SEM CPF"
    );

    console.log(
        "========================================"
    );

    return usuario;
}

// ============================================================
// PREPARAR DADOS DO CLIENTE
// ============================================================

function prepararDadosCliente(usuario, body = {}) {

    const nomeCliente =
        usuario.nome ||
        body.nome ||
        "Cliente FoodJet";

    const email =
        usuario.email
            ? String(usuario.email)
                .trim()
                .toLowerCase()
            : "";

    const telefoneCliente =
        usuario.telefone ||
        usuario.celular ||
        body.telefone ||
        "";

    // ========================================================
    // CPF / CNPJ
    // ========================================================
    // Prioridade:
    // 1. usuario.cpf
    // 2. usuario.cpfCnpj
    // 3. body.cpf
    //
    // Assim o checkout não precisa pedir CPF novamente.
    // ========================================================

    const cpfCliente =
        usuario.cpf ||
        usuario.cpfCnpj ||
        body.cpf ||
        "";

    const documento =
        String(cpfCliente)
            .replace(/\D/g, "")
            .trim();

    return {
        nomeCliente,
        email,
        telefoneCliente,
        documento,
    };
}

// ============================================================
// VALIDAR DADOS DO CLIENTE
// ============================================================

function validarDadosCliente({
    email,
    documento,
}) {

    if (!email) {
        throw new Error(
            "E-mail do cliente não encontrado."
        );
    }

    if (!documento) {
        throw new Error(
            "CPF não cadastrado. Atualize seu cadastro antes de realizar o pagamento."
        );
    }

    if (
        documento.length !== 11 &&
        documento.length !== 14
    ) {
        throw new Error(
            "CPF ou CNPJ inválido."
        );
    }
}

// ============================================================
// GERAR REFERÊNCIA
// ============================================================

function obterReferencia(pedidoId) {

    if (
        pedidoId &&
        String(pedidoId).trim()
    ) {
        return String(
            pedidoId
        ).trim();
    }

    return gerarReferenciaTemporaria();
}

// ============================================================
// PIX
// POST /pagamentos/pix
// ============================================================

async function gerarPix(req, res) {

    try {

        console.log("");
        console.log("========================================");
        console.log("💚 POST /pagamentos/pix");
        console.log("========================================");

        const usuario =
            await buscarUsuarioAutenticado(req);

        const {
            valor,
            pedidoId,
        } = req.body || {};

        const valorNumerico =
            Number(valor);

        if (
            !Number.isFinite(valorNumerico) ||
            valorNumerico <= 0
        ) {
            return res.status(400).json({
                sucesso: false,
                erro:
                    "Valor do pagamento inválido.",
            });
        }

        const valorFinal =
            Number(
                valorNumerico.toFixed(2)
            );

        const {
            nomeCliente,
            email,
            telefoneCliente,
            documento,
        } =
            prepararDadosCliente(
                usuario,
                req.body
            );

        validarDadosCliente({
            email,
            documento,
        });

        const referencia =
            obterReferencia(pedidoId);

        console.log("👤 USUÁRIO:", usuario.id);
        console.log("📧 EMAIL:", email);
        console.log("👤 NOME:", nomeCliente);
        console.log("🪪 CPF:", documento);
        console.log("💰 VALOR:", valorFinal);

        const pagamento =
            await criarPix({

                valor:
                    valorFinal,

                email,

                referencia,

                descricao:
                    `Pedido FoodJet #${referencia}`,

                nome:
                    String(
                        nomeCliente
                    ).trim(),

                cpf:
                    documento,

                telefone:
                    telefoneCliente,

                usuarioId:
                    String(
                        usuario.id
                    ),
            });

        const pagamentoId =
            pagamento?.id;

        if (!pagamentoId) {
            throw new Error(
                "O Asaas não retornou o ID da cobrança."
            );
        }

        const pix =
            await obterQrCodePix(
                pagamentoId
            );

        if (
            !pix ||
            !pix.payload
        ) {
            throw new Error(
                "O Asaas criou a cobrança, mas não retornou o código PIX."
            );
        }

        return res.status(201).json({

            sucesso: true,

            pagamentoId,

            paymentId:
                pagamentoId,

            pedidoId:
                pedidoId || null,

            externalReference:
                pagamento?.externalReference ||
                referencia,

            status:
                pagamento?.status ||
                "PENDING",

            totalAmount:
                Number(
                    pagamento?.value ??
                    valorFinal
                ),

            billingType:
                pagamento?.billingType ||
                "PIX",

            pix: {

                qrCode:
                    pix.payload,

                qrCodeBase64:
                    pix.encodedImage ||
                    "",

                ticketUrl:
                    pix.ticketUrl ||
                    "",

                expiracao:
                    pix.expirationDate ||
                    "",
            },
        });

    } catch (erro) {

        console.error(
            "❌ ERRO GERANDO PIX:",
            erro
        );

        const status =
            erro?.response?.status >= 400 &&
            erro?.response?.status < 600
                ? erro.response.status
                : 500;

        const mensagem =
            erro?.response?.data
                ?.errors?.[0]
                ?.description ||
            erro?.message ||
            "Não foi possível gerar o PIX.";

        return res.status(status).json({

            sucesso: false,

            erro: mensagem,

            detalhe:
                erro?.response?.data
                    ?.errors ||
                null,
        });
    }
}

// ============================================================
// CARTÃO DE CRÉDITO
// POST /pagamentos/cartao
// ============================================================

async function gerarCartao(req, res) {

    try {

        console.log("");
        console.log("========================================");
        console.log("💳 POST /pagamentos/cartao");
        console.log("========================================");

        const usuario =
            await buscarUsuarioAutenticado(req);

        const {
            valor,
            pedidoId,
        } = req.body || {};

        const valorNumerico =
            Number(valor);

        if (
            !Number.isFinite(valorNumerico) ||
            valorNumerico <= 0
        ) {
            return res.status(400).json({
                sucesso: false,
                erro:
                    "Valor do pagamento inválido.",
            });
        }

        const {
            nomeCliente,
            email,
            telefoneCliente,
            documento,
        } =
            prepararDadosCliente(
                usuario,
                req.body
            );

        validarDadosCliente({
            email,
            documento,
        });

        const referencia =
            obterReferencia(pedidoId);

        console.log("👤 USUÁRIO:", usuario.id);
        console.log("📧 EMAIL:", email);
        console.log("👤 NOME:", nomeCliente);
        console.log("🪪 CPF:", documento);
        console.log("💳 TIPO: CRÉDITO");

        const pagamento =
            await criarCartao({

                valor:
                    Number(
                        valorNumerico.toFixed(2)
                    ),

                email,

                referencia,

                descricao:
                    `Pedido FoodJet #${referencia}`,

                nome:
                    nomeCliente,

                cpf:
                    documento,

                telefone:
                    telefoneCliente,

                usuarioId:
                    String(
                        usuario.id
                    ),
            });

        return res.status(201).json({

            sucesso: true,

            pagamentoId:
                pagamento?.id,

            paymentId:
                pagamento?.id,

            pedidoId:
                pedidoId || null,

            externalReference:
                pagamento?.externalReference ||
                referencia,

            status:
                pagamento?.status ||
                "PENDING",

            totalAmount:
                Number(
                    pagamento?.value ??
                    valorNumerico
                ),

            billingType:
                pagamento?.billingType ||
                "CREDIT_CARD",

            invoiceUrl:
                pagamento?.invoiceUrl ||
                "",
        });

    } catch (erro) {

        console.error(
            "❌ ERRO GERANDO CARTÃO:",
            erro
        );

        const status =
            erro?.response?.status >= 400 &&
            erro?.response?.status < 600
                ? erro.response.status
                : 500;

        const mensagem =
            erro?.response?.data
                ?.errors?.[0]
                ?.description ||
            erro?.message ||
            "Não foi possível gerar o pagamento com cartão.";

        return res.status(status).json({

            sucesso: false,

            erro: mensagem,

            detalhe:
                erro?.response?.data
                    ?.errors ||
                null,
        });
    }
}

// ============================================================
// CARTÃO DE DÉBITO
// POST /pagamentos/debito
// ============================================================

async function gerarDebito(req, res) {

    try {

        console.log("");
        console.log("========================================");
        console.log("💳 POST /pagamentos/debito");
        console.log("========================================");

        const usuario =
            await buscarUsuarioAutenticado(req);

        const {
            valor,
            pedidoId,
        } = req.body || {};

        const valorNumerico =
            Number(valor);

        if (
            !Number.isFinite(valorNumerico) ||
            valorNumerico <= 0
        ) {
            return res.status(400).json({
                sucesso: false,
                erro:
                    "Valor do pagamento inválido.",
            });
        }

        const {
            nomeCliente,
            email,
            telefoneCliente,
            documento,
        } =
            prepararDadosCliente(
                usuario,
                req.body
            );

        validarDadosCliente({
            email,
            documento,
        });

        const referencia =
            obterReferencia(pedidoId);

        console.log("👤 USUÁRIO:", usuario.id);
        console.log("📧 EMAIL:", email);
        console.log("👤 NOME:", nomeCliente);
        console.log("🪪 CPF:", documento);
        console.log("💳 TIPO: DÉBITO");

        const pagamento =
            await criarDebito({

                valor:
                    Number(
                        valorNumerico.toFixed(2)
                    ),

                email,

                referencia,

                descricao:
                    `Pedido FoodJet #${referencia}`,

                nome:
                    nomeCliente,

                cpf:
                    documento,

                telefone:
                    telefoneCliente,

                usuarioId:
                    String(
                        usuario.id
                    ),
            });

        return res.status(201).json({

            sucesso: true,

            pagamentoId:
                pagamento?.id,

            paymentId:
                pagamento?.id,

            pedidoId:
                pedidoId || null,

            externalReference:
                pagamento?.externalReference ||
                referencia,

            status:
                pagamento?.status ||
                "PENDING",

            totalAmount:
                Number(
                    pagamento?.value ??
                    valorNumerico
                ),

            billingType:
                pagamento?.billingType ||
                "DEBIT_CARD",

            invoiceUrl:
                pagamento?.invoiceUrl ||
                "",
        });

    } catch (erro) {

        console.error(
            "❌ ERRO GERANDO DÉBITO:",
            erro
        );

        const status =
            erro?.response?.status >= 400 &&
            erro?.response?.status < 600
                ? erro.response.status
                : 500;

        const mensagem =
            erro?.response?.data
                ?.errors?.[0]
                ?.description ||
            erro?.message ||
            "Não foi possível gerar o pagamento com débito.";

        return res.status(status).json({

            sucesso: false,

            erro: mensagem,

            detalhe:
                erro?.response?.data
                    ?.errors ||
                null,
        });
    }
}

// ============================================================
// CONSULTAR PAGAMENTO
// ============================================================

async function consultar(req, res) {

    try {

        await buscarUsuarioAutenticado(req);

        const pagamentoId =
            String(
                req.params.pagamentoId ||
                ""
            ).trim();

        if (!pagamentoId) {

            return res.status(400).json({

                sucesso: false,

                erro:
                    "ID do pagamento obrigatório.",
            });
        }

        const pagamento =
            await consultarPagamento(
                pagamentoId
            );

        return res.json({

            sucesso: true,

            pagamentoId:
                pagamento?.id ||
                pagamentoId,

            orderId:
                pagamento?.externalReference ||
                pagamento?.id ||
                pagamentoId,

            paymentId:
                pagamento?.id ||
                pagamentoId,

            status:
                pagamento?.status ||
                "",

            statusDetalhe:
                pagamento?.status ||
                "",

            totalAmount:
                pagamento?.value ??
                null,

            externalReference:
                pagamento?.externalReference ||
                "",

            billingType:
                pagamento?.billingType ||
                "PIX",

            invoiceUrl:
                pagamento?.invoiceUrl ||
                "",

            pix: {

                qrCode:
                    "",

                qrCodeBase64:
                    "",

                ticketUrl:
                    "",

                expiracao:
                    pagamento?.dueDate ||
                    "",
            },
        });

    } catch (erro) {

        console.error(
            "❌ ERRO CONSULTANDO PAGAMENTO:",
            erro
        );

        const status =
            erro?.response?.status >= 400 &&
            erro?.response?.status < 600
                ? erro.response.status
                : 500;

        const mensagem =
            erro?.response?.data
                ?.errors?.[0]
                ?.description ||
            erro?.message ||
            "Erro ao consultar pagamento.";

        return res.status(status).json({

            sucesso: false,

            erro:
                mensagem,
        });
    }
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

    gerarPix,

    gerarCartao,

    gerarDebito,

    consultar,

};

