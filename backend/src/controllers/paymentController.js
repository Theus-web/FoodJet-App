
const asaasService =
    require("../services/asaasService");

const {
    criarPix,
    criarCartao,
    criarDebito,
    consultarPagamento,
    obterQrCodePix,
} = asaasService;

const User =
    require("../models/user");

const Order =
    require("../models/order");


// ============================================================
// VALIDAR ASAAS SERVICE
// ============================================================

if (typeof criarPix !== "function") {
    throw new Error(
        "asaasService não exportou criarPix corretamente."
    );
}

if (typeof criarCartao !== "function") {
    throw new Error(
        "asaasService não exportou criarCartao corretamente."
    );
}

if (typeof criarDebito !== "function") {
    throw new Error(
        "asaasService não exportou criarDebito corretamente."
    );
}

if (typeof consultarPagamento !== "function") {
    throw new Error(
        "asaasService não exportou consultarPagamento corretamente."
    );
}

if (typeof obterQrCodePix !== "function") {
    throw new Error(
        "asaasService não exportou obterQrCodePix corretamente."
    );
}

console.log(
    "========================================"
);

console.log(
    "✅ ASAAS SERVICE CARREGADO"
);

console.log(
    "✅ criarPix:",
    typeof criarPix
);

console.log(
    "✅ criarCartao:",
    typeof criarCartao
);

console.log(
    "✅ criarDebito:",
    typeof criarDebito
);

console.log(
    "✅ consultarPagamento:",
    typeof consultarPagamento
);

console.log(
    "✅ obterQrCodePix:",
    typeof obterQrCodePix
);

console.log(
    "========================================"
);


// ============================================================
// BUSCAR USUÁRIO AUTENTICADO
// ============================================================

async function buscarUsuarioAutenticado(req) {

    const usuarioToken =
        req.usuario ||
        req.user ||
        null;

    if (!usuarioToken) {
        throw new Error(
            "Cliente não identificado. Faça login novamente."
        );
    }

    const usuarioId =
        usuarioToken.id ||
        usuarioToken.usuarioId ||
        usuarioToken.userId ||
        usuarioToken._id ||
        null;

    console.log(
        "🔐 ID DO USUÁRIO NO TOKEN:",
        usuarioId
    );

    if (
        usuarioId === undefined ||
        usuarioId === null ||
        String(usuarioId).trim() === ""
    ) {
        throw new Error(
            "Cliente não identificado. Faça login novamente."
        );
    }

    const usuario =
        await User.buscarPorId(usuarioId);

    if (!usuario) {
        throw new Error(
            "Cliente não identificado. Faça login novamente."
        );
    }

    console.log(
        "✅ CLIENTE AUTENTICADO:",
        usuario.id
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
// BUSCAR PEDIDO
// ============================================================

async function buscarPedidoObrigatorio(pedidoId) {

    if (
        pedidoId === undefined ||
        pedidoId === null ||
        String(pedidoId).trim() === ""
    ) {
        throw new Error(
            "Pedido não informado. Crie o pedido antes de gerar o pagamento."
        );
    }

    const idString =
        String(pedidoId).trim();

    console.log(
        "🔎 BUSCANDO PEDIDO:",
        idString
    );

    let pedido = null;

    // --------------------------------------------------------
    // PRIMEIRA TENTATIVA
    // --------------------------------------------------------

    try {

        pedido =
            await Order.buscarPorId(
                pedidoId
            );

    } catch (erro) {

        console.warn(
            "⚠️ Order.buscarPorId falhou:",
            erro?.message || erro
        );
    }

    if (pedido) {

        console.log(
            "✅ PEDIDO ENCONTRADO:",
            pedido.id
        );

        return pedido;
    }

    // --------------------------------------------------------
    // SEGUNDA TENTATIVA
    // --------------------------------------------------------

    try {

        const pedidos =
            await Order.listar();

        if (Array.isArray(pedidos)) {

            pedido =
                pedidos.find(
                    item =>
                        String(item.id).trim() ===
                        idString
                );
        }

    } catch (erro) {

        console.warn(
            "⚠️ ERRO LISTANDO PEDIDOS:",
            erro?.message || erro
        );
    }

    if (!pedido) {

        throw new Error(
            `Pedido ${idString} não encontrado no banco.`
        );
    }

    console.log(
        "✅ PEDIDO ENCONTRADO:",
        pedido.id
    );

    return pedido;
}


// ============================================================
// REFERÊNCIA ASAAS
// ============================================================

function obterReferencia(pedido) {

    if (
        !pedido ||
        pedido.id === undefined ||
        pedido.id === null
    ) {
        throw new Error(
            "Pedido inválido para gerar referência."
        );
    }

    return String(
        pedido.id
    ).trim();
}


// ============================================================
// VALIDAR VALOR
// ============================================================

function validarValor(valor) {

    const valorNumerico =
        Number(valor);

    if (
        !Number.isFinite(valorNumerico) ||
        valorNumerico <= 0
    ) {
        throw new Error(
            "Valor do pagamento inválido."
        );
    }

    return Number(
        valorNumerico.toFixed(2)
    );
}


// ============================================================
// VALIDAR DONO DO PEDIDO
// ============================================================
//
// Segurança importante:
//
// O usuário autenticado só pode pagar o próprio pedido.
// ============================================================

function validarClienteDoPedido(
    pedido,
    usuario
) {

    if (!pedido) {
        throw new Error(
            "Pedido não encontrado."
        );
    }

    if (!usuario) {
        throw new Error(
            "Cliente não autenticado."
        );
    }

    if (
        String(pedido.clienteId) !==
        String(usuario.id)
    ) {
        throw new Error(
            "Este pedido não pertence ao cliente autenticado."
        );
    }
}


// ============================================================
// PIX
// POST /pagamentos/pix
// ============================================================

async function gerarPix(req, res) {

    try {

        console.log("");
        console.log(
            "========================================"
        );
        console.log(
            "💚 POST /pagamentos/pix"
        );
        console.log(
            "========================================"
        );

        // ----------------------------------------------------
        // USUÁRIO
        // ----------------------------------------------------

        const usuario =
            await buscarUsuarioAutenticado(req);

        // ----------------------------------------------------
        // BODY
        // ----------------------------------------------------

        const body =
            req.body || {};

        const {
            valor,
            pedidoId,
        } = body;

        console.log(
            "🆔 PEDIDO ID:",
            pedidoId
        );

        // ----------------------------------------------------
        // PEDIDO
        // ----------------------------------------------------

        const pedido =
            await buscarPedidoObrigatorio(
                pedidoId
            );

        // ----------------------------------------------------
        // GARANTIR QUE O PEDIDO É DO CLIENTE
        // ----------------------------------------------------

        validarClienteDoPedido(
            pedido,
            usuario
        );

        // ----------------------------------------------------
        // REFERÊNCIA
        // ----------------------------------------------------

        const referencia =
            obterReferencia(pedido);

        // ----------------------------------------------------
        // VALOR
        // ----------------------------------------------------

        const valorFinal =
            validarValor(valor);

        // ----------------------------------------------------
        // CLIENTE
        // ----------------------------------------------------

        const dadosCliente =
            prepararDadosCliente(
                usuario,
                body
            );

        validarDadosCliente(
            dadosCliente
        );

        const {
            nomeCliente,
            email,
            telefoneCliente,
            documento,
        } = dadosCliente;

        console.log(
            "👤 CLIENTE:",
            usuario.id
        );

        console.log(
            "📧 EMAIL:",
            email
        );

        console.log(
            "🪪 DOCUMENTO:",
            documento
        );

        console.log(
            "💰 VALOR:",
            valorFinal
        );

        console.log(
            "🆔 PEDIDO:",
            pedido.id
        );

        console.log(
            "🔖 REFERÊNCIA:",
            referencia
        );

        // ----------------------------------------------------
        // CRIAR PIX ASAAS
        // ----------------------------------------------------

        console.log(
            "💚 CRIANDO PIX NO ASAAS..."
        );

        const pagamento =
            await criarPix({

                valor:
                    valorFinal,

                email,

                referencia,

                descricao:
                    `Pedido FoodJet #${referencia}`,

                nome:
                    String(nomeCliente).trim(),

                cpf:
                    documento,

                telefone:
                    telefoneCliente,

                usuarioId:
                    String(usuario.id),
            });

        const pagamentoId =
            pagamento?.id;

        if (!pagamentoId) {

            throw new Error(
                "O Asaas não retornou o ID da cobrança."
            );
        }

        console.log(
            "✅ PAGAMENTO PIX CRIADO:",
            pagamentoId
        );

        // ----------------------------------------------------
        // QR CODE
        // ----------------------------------------------------

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

        console.log(
            "✅ QR CODE PIX OBTIDO"
        );

        // ----------------------------------------------------
        // RESPOSTA
        // ----------------------------------------------------

        return res.status(201).json({

            sucesso: true,

            pagamentoId,

            paymentId:
                pagamentoId,

            pedidoId:
                pedido.id,

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

        console.error("");
        console.error(
            "========================================"
        );
        console.error(
            "❌ ERRO GERANDO PIX"
        );
        console.error(
            "========================================"
        );

        console.error(
            erro?.message ||
            erro
        );

        if (erro?.response?.data) {

            console.error(
                "ASAAS:",
                JSON.stringify(
                    erro.response.data,
                    null,
                    2
                )
            );
        }

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

            erro:
                mensagem,

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
        console.log(
            "========================================"
        );
        console.log(
            "💳 POST /pagamentos/cartao"
        );
        console.log(
            "========================================"
        );

        const usuario =
            await buscarUsuarioAutenticado(req);

        const body =
            req.body || {};

        const {
            valor,
            pedidoId,
        } = body;

        const pedido =
            await buscarPedidoObrigatorio(
                pedidoId
            );

        validarClienteDoPedido(
            pedido,
            usuario
        );

        const referencia =
            obterReferencia(pedido);

        const valorFinal =
            validarValor(valor);

        const dadosCliente =
            prepararDadosCliente(
                usuario,
                body
            );

        validarDadosCliente(
            dadosCliente
        );

        const {
            nomeCliente,
            email,
            telefoneCliente,
            documento,
        } = dadosCliente;

        const pagamento =
            await criarCartao({

                valor:
                    valorFinal,

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
                    String(usuario.id),
            });

        console.log(
            "✅ CARTÃO CRIADO:",
            pagamento?.id
        );

        return res.status(201).json({

            sucesso: true,

            pagamentoId:
                pagamento?.id,

            paymentId:
                pagamento?.id,

            pedidoId:
                pedido.id,

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
                "CREDIT_CARD",

            invoiceUrl:
                pagamento?.invoiceUrl ||
                "",
        });

    } catch (erro) {

        console.error(
            "❌ ERRO GERANDO CARTÃO:",
            erro?.message || erro
        );

        if (erro?.response?.data) {

            console.error(
                "ASAAS:",
                JSON.stringify(
                    erro.response.data,
                    null,
                    2
                )
            );
        }

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

            erro:
                mensagem,

            detalhe:
                erro?.response?.data
                    ?.errors ||
                null,
        });
    }
}


// ============================================================
// DÉBITO
// POST /pagamentos/debito
// ============================================================

async function gerarDebito(req, res) {

    try {

        console.log("");
        console.log(
            "========================================"
        );
        console.log(
            "💳 POST /pagamentos/debito"
        );
        console.log(
            "========================================"
        );

        const usuario =
            await buscarUsuarioAutenticado(req);

        const body =
            req.body || {};

        const {
            valor,
            pedidoId,
        } = body;

        const pedido =
            await buscarPedidoObrigatorio(
                pedidoId
            );

        validarClienteDoPedido(
            pedido,
            usuario
        );

        const referencia =
            obterReferencia(pedido);

        const valorFinal =
            validarValor(valor);

        const dadosCliente =
            prepararDadosCliente(
                usuario,
                body
            );

        validarDadosCliente(
            dadosCliente
        );

        const {
            nomeCliente,
            email,
            telefoneCliente,
            documento,
        } = dadosCliente;

        const pagamento =
            await criarDebito({

                valor:
                    valorFinal,

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
                    String(usuario.id),
            });

        console.log(
            "✅ DÉBITO CRIADO:",
            pagamento?.id
        );

        return res.status(201).json({

            sucesso: true,

            pagamentoId:
                pagamento?.id,

            paymentId:
                pagamento?.id,

            pedidoId:
                pedido.id,

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
                "DEBIT_CARD",

            invoiceUrl:
                pagamento?.invoiceUrl ||
                "",
        });

    } catch (erro) {

        console.error(
            "❌ ERRO GERANDO DÉBITO:",
            erro?.message || erro
        );

        if (erro?.response?.data) {

            console.error(
                "ASAAS:",
                JSON.stringify(
                    erro.response.data,
                    null,
                    2
                )
            );
        }

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

            erro:
                mensagem,

            detalhe:
                erro?.response?.data
                    ?.errors ||
                null,
        });
    }
}


// ============================================================
// CONSULTAR PAGAMENTO
// GET /pagamentos/:pagamentoId
// ============================================================

async function consultar(req, res) {

    try {

        const usuario =
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

        console.log(
            "🔎 CONSULTANDO PAGAMENTO:",
            pagamentoId
        );

        const pagamento =
            await consultarPagamento(
                pagamentoId
            );

        // ----------------------------------------------------
        // Se o pagamento possui referência, podemos tentar
        // conferir o pedido correspondente.
        // ----------------------------------------------------

        const externalReference =
            pagamento?.externalReference ||
            "";

        let pedido = null;

        if (externalReference) {

            try {

                pedido =
                    await Order.buscarPorId(
                        externalReference
                    );

            } catch (erro) {

                console.warn(
                    "⚠️ Não foi possível consultar pedido:",
                    erro?.message || erro
                );
            }
        }

        // ----------------------------------------------------
        // Segurança
        // ----------------------------------------------------

        if (
            pedido &&
            String(pedido.clienteId) !==
            String(usuario.id)
        ) {

            return res.status(403).json({

                sucesso: false,

                erro:
                    "Você não possui acesso a este pagamento.",
            });
        }

        return res.json({

            sucesso: true,

            pagamentoId:
                pagamento?.id ||
                pagamentoId,

            orderId:
                externalReference ||
                pagamento?.id ||
                pagamentoId,

            pedidoId:
                externalReference ||
                null,

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

            externalReference,

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
            erro?.message || erro
        );

        if (erro?.response?.data) {

            console.error(
                "ASAAS:",
                JSON.stringify(
                    erro.response.data,
                    null,
                    2
                )
            );
        }

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

