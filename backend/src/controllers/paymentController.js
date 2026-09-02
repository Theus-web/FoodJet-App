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
// BUSCAR PEDIDO
// ============================================================

async function buscarPedidoObrigatorio(pedidoId) {

    if (
        pedidoId === undefined ||
        pedidoId === null ||
        String(pedidoId).trim() === ""
    ) {
        throw new Error(
            "Pedido não informado."
        );
    }

    const idString =
        String(pedidoId).trim();

    console.log(
        "🔎 BUSCANDO PEDIDO:",
        idString
    );

    const pedido =
        await Order.buscarPorId(
            pedidoId
        );

    if (!pedido) {

        throw new Error(
            `Pedido ${idString} não encontrado no PostgreSQL.`
        );
    }

    console.log(
        "✅ PEDIDO ENCONTRADO:",
        pedido.id
    );

    return pedido;
}


// ============================================================
// CRIAR PEDIDO QUANDO O FLUTTER AINDA NÃO POSSUI PEDIDO ID
// ============================================================
//
// O checkout atual envia pedidoId: null.
//
// Nesse caso:
// Flutter
//   ↓
// /pagamentos/pix
//   ↓
// cria pedido no PostgreSQL
//   ↓
// recebe ID do pedido
//   ↓
// cria cobrança Asaas usando esse mesmo ID
//
// Assim o externalReference do Asaas fica igual ao pedido.
// ============================================================

async function criarPedidoSeNecessario(
    usuario,
    body
) {

    const pedidoId =
        body.pedidoId;

    // --------------------------------------------------------
    // JÁ EXISTE PEDIDO
    // --------------------------------------------------------

    if (
        pedidoId !== undefined &&
        pedidoId !== null &&
        String(pedidoId).trim() !== ""
    ) {

        const pedido =
            await buscarPedidoObrigatorio(
                pedidoId
            );

        return {
            pedido,
            criadoAgora: false,
        };
    }

    // --------------------------------------------------------
    // DADOS NECESSÁRIOS PARA CRIAR PEDIDO
    // --------------------------------------------------------

    const restauranteId =
        body.restauranteId ||
        body.restaurantId ||
        null;

    if (
        restauranteId === undefined ||
        restauranteId === null ||
        String(restauranteId).trim() === ""
    ) {
        throw new Error(
            "Restaurante não informado para criar o pedido."
        );
    }

    const itens =
        Array.isArray(body.itens)
            ? body.itens
            : [];

    if (itens.length === 0) {
        throw new Error(
            "Nenhum item foi informado no pedido."
        );
    }

    // --------------------------------------------------------
    // VALORES
    // --------------------------------------------------------

    const subtotal =
        validarValor(
            body.subtotal ??
            body.valor ??
            body.total
        );

    const taxaServico =
        Number(
            Number(
                body.taxaServico ?? 0
            ).toFixed(2)
        );

    const taxaEntrega =
        Number(
            Number(
                body.taxaEntrega ?? 0
            ).toFixed(2)
        );

    const totalInformado =
        body.total !== undefined &&
        body.total !== null
            ? Number(body.total)
            : subtotal + taxaServico + taxaEntrega;

    const total =
        validarValor(
            totalInformado
        );

    // --------------------------------------------------------
    // ENDEREÇO
    // --------------------------------------------------------

    const endereco =
        body.endereco ||
        null;

    // --------------------------------------------------------
    // PAGAMENTO
    // --------------------------------------------------------

    const pagamento =
        String(
            body.pagamento ||
            "PIX"
        ).toUpperCase();

    // --------------------------------------------------------
    // CRIAR PEDIDO
    // --------------------------------------------------------

    console.log("");
    console.log(
        "📦 PEDIDO AINDA NÃO EXISTE."
    );
    console.log(
        "📦 CRIANDO PEDIDO NO POSTGRESQL..."
    );

    const pedidoCriado =
        await Order.criar({

            clienteId:
                String(usuario.id),

            restauranteId:
                String(restauranteId),

            itens,

            endereco,

            pagamento,

            subtotal,

            taxaServico,

            taxaEntrega,

            total,

            precisaTroco:
                false,

            trocoPara:
                null,

            valorTroco:
                0,

            status:
                "AGUARDANDO_RESTAURANTE",

            pagamentoStatus:
                "PENDENTE",

            statusPagamento:
                "pending",

            pagamentoAprovado:
                false,
        });

    if (
        !pedidoCriado ||
        pedidoCriado.id === undefined ||
        pedidoCriado.id === null
    ) {
        throw new Error(
            "Não foi possível criar o pedido no PostgreSQL."
        );
    }

    console.log(
        "✅ PEDIDO CRIADO NO POSTGRESQL:",
        pedidoCriado.id
    );

    return {
        pedido: pedidoCriado,
        criadoAgora: true,
    };
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
// VALIDAR DONO DO PEDIDO
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
// ATUALIZAR PEDIDO COM PAGAMENTO ASAAS
// ============================================================

async function vincularPagamentoAoPedido(
    pedido,
    pagamento
) {

    const pagamentoId =
        pagamento?.id ||
        null;

    if (!pagamentoId) {
        return pedido;
    }

    console.log(
        "🔗 VINCULANDO ASAAS AO PEDIDO:",
        pedido.id
    );

    const dadosAtualizados = {

        pagamentoId:

            pagamentoId,

        paymentId:

            pagamentoId,

        asaasPaymentId:

            pagamentoId,

        externalReference:

            pagamento?.externalReference ||
            String(pedido.id),

        referenciaPagamento:

            pagamento?.externalReference ||
            String(pedido.id),

        pagamentoStatus:

            pagamento?.status ||
            "PENDING",

        statusPagamento:

            String(
                pagamento?.status ||
                "PENDING"
            ).toLowerCase(),

        pagamentoAprovado:

            false,
    };

    const pedidoAtualizado =
        await Order.atualizarDadosPedido(
            pedido.id,
            dadosAtualizados
        );

    console.log(
        "✅ PEDIDO VINCULADO AO PAGAMENTO ASAAS"
    );

    return pedidoAtualizado ||
        pedido;
}


// ============================================================
// PIX
// POST /pagamentos/pix
// ============================================================

async function gerarPix(req, res) {

    let pedido = null;

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
        } = body;

        console.log(
            "🆔 PEDIDO RECEBIDO:",
            body.pedidoId
        );

        // ----------------------------------------------------
        // PEDIDO
        // ----------------------------------------------------

        const resultadoPedido =
            await criarPedidoSeNecessario(
                usuario,
                body
            );

        pedido =
            resultadoPedido.pedido;

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
            validarValor(
                valor ??
                pedido.total
            );

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
        // VINCULAR ASAAS AO PEDIDO
        // ----------------------------------------------------

        pedido =
            await vincularPagamentoAoPedido(
                pedido,
                pagamento
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

        if (pedido) {

            console.error(
                "📦 PEDIDO ENVOLVIDO:",
                pedido.id
            );
        }

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

    let pedido = null;

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

        // ====================================================
        // USUÁRIO AUTENTICADO
        // ====================================================

        const usuario =
            await buscarUsuarioAutenticado(req);

        const body =
            req.body || {};

        const {
            valor,
        } = body;

        // ====================================================
        // PEDIDO
        // ====================================================

        const resultadoPedido =
            await criarPedidoSeNecessario(
                usuario,
                body
            );

        pedido =
            resultadoPedido.pedido;

        validarClienteDoPedido(
            pedido,
            usuario
        );

        // ====================================================
        // REFERÊNCIA
        // ====================================================

        const referencia =
            obterReferencia(pedido);

        // ====================================================
        // VALOR
        // ====================================================

        const valorFinal =
            validarValor(
                valor ??
                pedido.total
            );

        // ====================================================
        // CLIENTE
        // ====================================================

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

        // ====================================================
        // TELEFONE
        // ====================================================

        const telefone =
            String(
                telefoneCliente || ""
            )
                .replace(/\D/g, "")
                .trim();

        if (
            telefone.length < 10 ||
            telefone.length > 11
        ) {

            throw new Error(
                "Número de contato com DDD do titular do cartão é obrigatório."
            );
        }

        // ====================================================
        // ENDEREÇO
        // ====================================================

        const enderecoOriginal =
            body.endereco || {};

        const endereco = {

            cep:
                enderecoOriginal.cep ||
                enderecoOriginal.CEP ||
                enderecoOriginal.codigoPostal ||
                enderecoOriginal.postalCode ||
                "",

            numero:
                enderecoOriginal.numero ||
                enderecoOriginal.numeroEndereco ||
                enderecoOriginal.number ||
                enderecoOriginal.addressNumber ||
                "",

            complemento:
                enderecoOriginal.complemento ||
                enderecoOriginal.complement ||
                enderecoOriginal.addressComplement ||
                "",
        };

        // ====================================================
        // CEP
        // ====================================================

        const cep =
            String(
                endereco.cep || ""
            )
                .replace(/\D/g, "")
                .trim();

        if (cep.length !== 8) {

            throw new Error(
                "CEP do titular do cartão é obrigatório."
            );
        }

        // ====================================================
        // NÚMERO DO ENDEREÇO
        // ====================================================

        const numeroEndereco =
            String(
                endereco.numero || ""
            ).trim();

        if (!numeroEndereco) {

            throw new Error(
                "Número do endereço é obrigatório para pagamento com cartão."
            );
        }

        // ====================================================
        // CARTÃO
        // ====================================================

        const cartao =
            body.cartao || {};

        // ----------------------------------------------------
        // NÚMERO
        // ----------------------------------------------------

        const numero =
            String(
                cartao.numero || ""
            )
                .replace(/\D/g, "");

        if (
            numero.length < 13 ||
            numero.length > 19
        ) {

            throw new Error(
                "Número do cartão inválido."
            );
        }

        // ----------------------------------------------------
        // TITULAR
        // ----------------------------------------------------

        const nomeCartao =
            String(
                cartao.nome || ""
            ).trim();

        if (!nomeCartao) {

            throw new Error(
                "Nome do titular do cartão é obrigatório."
            );
        }

        // ----------------------------------------------------
        // VALIDADE
        // ----------------------------------------------------

        const validade =
            String(
                cartao.validade || ""
            )
                .replace(/\D/g, "");

        if (
            !/^\d{4}$/.test(
                validade
            )
        ) {

            throw new Error(
                "Validade do cartão inválida. Use MM/AA."
            );
        }

        const mes =
            Number(
                validade.substring(0, 2)
            );

        if (
            mes < 1 ||
            mes > 12
        ) {

            throw new Error(
                "Mês de validade do cartão inválido."
            );
        }

        const mesExpiracao =
            validade.substring(0, 2);

        const anoExpiracao =
            `20${validade.substring(2, 4)}`;

        // ----------------------------------------------------
        // CVV
        // ----------------------------------------------------

        const cvv =
            String(
                cartao.cvv || ""
            )
                .replace(/\D/g, "");

        if (
            cvv.length < 3 ||
            cvv.length > 4
        ) {

            throw new Error(
                "CVV do cartão inválido."
            );
        }

        // ====================================================
        // IP DO CLIENTE
        // ====================================================

        const forwardedFor =
            req.headers[
                "x-forwarded-for"
            ];

        const remoteIp =
            forwardedFor
                ? String(
                    forwardedFor
                )
                    .split(",")[0]
                    .trim()
                : String(
                    req.socket?.remoteAddress ||
                    ""
                ).trim();

        if (!remoteIp) {

            throw new Error(
                "Não foi possível identificar o IP do cliente."
            );
        }

        // ====================================================
        // LOG SEGURO
        // ====================================================

        console.log(
            "👤 CLIENTE:",
            usuario.id
        );

        console.log(
            "📧 EMAIL:",
            email
        );

        console.log(
            "📱 TELEFONE:",
            telefone
        );

        console.log(
            "🪪 DOCUMENTO:",
            documento
        );

        console.log(
            "📍 CEP:",
            cep
        );

        console.log(
            "🏠 NÚMERO:",
            numeroEndereco
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

        console.log(
            "💳 CARTÃO:",
            "DADOS RECEBIDOS"
        );

        // ====================================================
        // CRIAR PAGAMENTO ASAAS
        // ====================================================

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

                telefone,

                usuarioId:
                    String(usuario.id),

                // ==========================================
                // CARTÃO
                // ==========================================

                cartao: {

                    numero,

                    nome:
                        nomeCartao,

                    mesExpiracao,

                    anoExpiracao,

                    cvv,
                },

                // ==========================================
                // ENDEREÇO
                // ==========================================

                endereco: {

                    cep,

                    numero:
                        numeroEndereco,

                    complemento:
                        endereco.complemento,
                },

                // ==========================================
                // IP
                // ==========================================

                remoteIp,
            });

        // ====================================================
        // VALIDAR RESPOSTA ASAAS
        // ====================================================

        if (
            !pagamento?.id
        ) {

            throw new Error(
                "O Asaas não retornou o ID do pagamento com cartão."
            );
        }

        // ====================================================
        // VINCULAR PAGAMENTO AO PEDIDO
        // ====================================================

        pedido =
            await vincularPagamentoAoPedido(
                pedido,
                pagamento
            );

        // ====================================================
        // SUCESSO
        // ====================================================

        console.log("");
        console.log(
            "========================================"
        );

        console.log(
            "✅ CARTÃO CRIADO NO ASAAS"
        );

        console.log(
            "💳 PAGAMENTO:",
            pagamento.id
        );

        console.log(
            "📦 PEDIDO:",
            pedido.id
        );

        console.log(
            "📊 STATUS:",
            pagamento.status
        );

        console.log(
            "========================================"
        );

        return res.status(201).json({

            sucesso: true,

            pagamentoId:
                pagamento.id,

            paymentId:
                pagamento.id,

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

        console.error("");
        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO GERANDO CARTÃO"
        );

        console.error(
            "========================================"
        );

        console.error(
            "MENSAGEM:",
            erro?.message || erro
        );

        if (erro?.response?.data) {

            console.error(
                "ASAAS:"
            );

            console.error(
                JSON.stringify(
                    erro.response.data,
                    null,
                    2
                )
            );
        }

        if (pedido) {

            console.error(
                "📦 PEDIDO:",
                pedido.id
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

    let pedido = null;

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
        } = body;

        const resultadoPedido =
            await criarPedidoSeNecessario(
                usuario,
                body
            );

        pedido =
            resultadoPedido.pedido;

        validarClienteDoPedido(
            pedido,
            usuario
        );

        const referencia =
            obterReferencia(pedido);

        const valorFinal =
            validarValor(
                valor ??
                pedido.total
            );

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

        if (!pagamento?.id) {

            throw new Error(
                "O Asaas não retornou o ID do pagamento com débito."
            );
        }

        await vincularPagamentoAoPedido(
            pedido,
            pagamento
        );

        console.log(
            "✅ DÉBITO CRIADO:",
            pagamento.id
        );

        return res.status(201).json({

            sucesso: true,

            pagamentoId:
                pagamento.id,

            paymentId:
                pagamento.id,

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
        // SEGURANÇA
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