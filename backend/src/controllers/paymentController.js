
const crypto = require("crypto");

const asaasService =
    require("../services/asaasService");

const {
    criarPix,
    criarCartao,
    criarDebito,
    consultarPagamento,
    obterQrCodePix,
    consultarStatusConta,
} = asaasService;

const User =
    require("../models/user");

const Order =
    require("../models/order");

const {
    pool,
} = require("../config/database");


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

console.log("========================================");
console.log("✅ ASAAS SERVICE CARREGADO");
console.log("========================================");


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

    return usuario;
}

// ============================================================
// STATUS DA CONTA ASAAS
// TEMPORÁRIO - REMOVER APÓS O TESTE
// ============================================================

async function statusContaAsaas(req, res) {

    try {

        const dados = await consultarStatusConta();

        const aprovado =
            String(dados.general || "").toUpperCase() === "APPROVED";

        return res.json({
            sucesso: true,

            aprovado,

            mensagem: aprovado
                ? "Conta Asaas aprovada."
                : "Conta Asaas ainda não está aprovada para todos os recursos.",

            status: {
                commercialInfo: dados.commercialInfo || null,
                bankAccountInfo: dados.bankAccountInfo || null,
                documentation: dados.documentation || null,
                general: dados.general || null,
            },
        });

    } catch (error) {

        return res.status(
            error.response?.status || 500
        ).json({

            sucesso: false,

            mensagem:
                error.response?.data?.errors?.[0]?.description ||
                error.message ||
                "Não foi possível consultar o status da conta Asaas.",
        });
    }
}

// ============================================================
// ENDEREÇO DE COBRANÇA DO CLIENTE
// IMPORTANTE:
// NÃO usa body.endereco.
// Busca exclusivamente os dados retornados pelo PostgreSQL.
// ============================================================

function obterEnderecoCobrancaDoUsuario(usuario) {

    if (!usuario) {
        throw new Error(
            "Cliente não identificado."
        );
    }

    let enderecoInterno = {};

    // --------------------------------------------------------
    // Caso endereco venha como objeto
    // --------------------------------------------------------

    if (
        usuario.endereco &&
        typeof usuario.endereco === "object" &&
        !Array.isArray(usuario.endereco)
    ) {
        enderecoInterno = usuario.endereco;
    }

    // --------------------------------------------------------
    // Caso endereco venha como JSON salvo no banco
    // --------------------------------------------------------

    else if (
        usuario.endereco &&
        typeof usuario.endereco === "string"
    ) {

        try {

            const enderecoConvertido =
                JSON.parse(usuario.endereco);

            if (
                enderecoConvertido &&
                typeof enderecoConvertido === "object"
            ) {
                enderecoInterno =
                    enderecoConvertido;
            }

        } catch (erro) {

            // Se não for JSON, simplesmente ignora.
            enderecoInterno = {};
        }
    }

    // --------------------------------------------------------
    // Junta dados do usuário + endereço interno
    // --------------------------------------------------------

    const origem = {
        ...usuario,
        ...enderecoInterno,
    };

    // --------------------------------------------------------
    // CEP
    // --------------------------------------------------------

    const cep =
        origem.cep ||
        origem.CEP ||
        origem.codigoPostal ||
        origem.codigo_postal ||
        origem.postalCode ||
        origem.cepCodigo ||
        origem.cep_codigo_postal ||
        origem.enderecoCep ||
        origem.endereco_cep ||
        "";

    // --------------------------------------------------------
    // NÚMERO
    // --------------------------------------------------------

    const numero =
        origem.numero ||
        origem.numeroEndereco ||
        origem.numero_endereco ||
        origem.number ||
        origem.addressNumber ||
        origem.address_number ||
        "";

    // --------------------------------------------------------
    // COMPLEMENTO
    // --------------------------------------------------------

    const complemento =
        origem.complemento ||
        origem.complement ||
        origem.addressComplement ||
        origem.address_complement ||
        origem.enderecoComplemento ||
        origem.endereco_complemento ||
        "";

    return {

        cep:
            String(cep || "")
                .replace(/\D/g, "")
                .trim(),

        numero:
            String(numero || "")
                .trim(),

        complemento:
            String(complemento || "")
                .trim(),
    };
}





// ============================================================
// DADOS DO CLIENTE — SEM CONFIAR NO FLUTTER
// Busca os dados do usuário diretamente do PostgreSQL
// ============================================================

function prepararDadosCliente(usuario) {

    if (!usuario) {
        throw new Error(
            "Cliente não identificado. Faça login novamente."
        );
    }

    const nomeCliente =
        usuario.nome ||
        usuario.nomeCompleto ||
        usuario.nome_completo ||
        "";

    const email =
        usuario.email
            ? String(usuario.email)
                .trim()
                .toLowerCase()
            : "";

    const telefoneCliente =
        usuario.telefone ||
        usuario.celular ||
        usuario.phone ||
        usuario.mobilePhone ||
        usuario.telefoneCelular ||
        usuario.telefone_celular ||
        "";

    const cpfCliente =
        usuario.cpf ||
        usuario.cpfCnpj ||
        usuario.cpf_cnpj ||
        usuario.documento ||
        usuario.document ||
        "";

    const documento =
        String(cpfCliente || "")
            .replace(/\D/g, "")
            .trim();

    return {
        nomeCliente: String(nomeCliente).trim(),

        email: String(email).trim().toLowerCase(),

        telefoneCliente:
            String(telefoneCliente)
                .replace(/\D/g, "")
                .trim(),

        documento,
    };
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

    const pedido =
        await Order.buscarPorId(
            pedidoId
        );

    if (!pedido) {
        throw new Error(
            `Pedido ${String(pedidoId).trim()} não encontrado no PostgreSQL.`
        );
    }

    return pedido;
}


// ============================================================
// CRIAR PEDIDO QUANDO NÃO EXISTE
// ============================================================
//
// Mantido para PIX / débito / outros fluxos existentes.
//
// IMPORTANTE:
// O CARTÃO NÃO USA ESTA FUNÇÃO.
// ============================================================

async function criarPedidoSeNecessario(
    usuario,
    body
) {

    const pedidoId =
        body.pedidoId;

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
            : subtotal +
              taxaServico +
              taxaEntrega;

    const total =
        validarValor(
            totalInformado
        );

    const endereco =
        body.endereco ||
        null;

    const pagamento =
        String(
            body.pagamento ||
            body.formaPagamento ||
            "PIX"
        ).toUpperCase();

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

    return {
        pedido: pedidoCriado,
        criadoAgora: true,
    };
}


// ============================================================
// REFERÊNCIA ASAAS DE PEDIDO EXISTENTE
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
// ATUALIZAR PEDIDO COM ASAAS
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

    const dadosAtualizados = {

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

    return await Order.atualizarDadosPedido(
        pedido.id,
        dadosAtualizados
    );
}


// ============================================================
// GERAR REFERÊNCIA TEMPORÁRIA DO CHECKOUT
// ============================================================

function gerarReferenciaCheckout(usuarioId) {

    const agora =
        Date.now();

    const aleatorio =
        crypto.randomInt(
            10000,
            99999
        );

    return (
        `FOODJET-CHK-${usuarioId}-${agora}-${aleatorio}`
    );
}


// ============================================================
// CRIAR SNAPSHOT DO CHECKOUT
// ============================================================
//
// NÃO salva cartão.
// NÃO salva CVV.
// NÃO salva número do cartão.
// ============================================================

function prepararCheckoutCartao(
    usuario,
    body,
    valorFinal
) {

    const restauranteId =
        body.restauranteId ||
        body.restaurantId ||
        null;

    if (
        restauranteId === null ||
        String(restauranteId).trim() === ""
    ) {
        throw new Error(
            "Restaurante não informado."
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

    const subtotal =
        validarValor(
            body.subtotal ??
            valorFinal
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

    const total =
        validarValor(
            body.total ??
            valorFinal
        );

    const endereco =
        body.endereco ||
        {};

    const pagamento =
        String(
            body.pagamento ||
            "CREDITO"
        ).toUpperCase();

    return {

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

        checkoutCriadoEm:
            new Date().toISOString(),
    };
}


// ============================================================
// SALVAR CHECKOUT PENDENTE
// ============================================================
//
// O pedido ainda NÃO existe em "pedidos".
// ============================================================

async function salvarCheckoutPendente({
    referencia,
    usuario,
    checkout,
}) {

    const dados =
        {

            tipo:
                "CHECKOUT_CARTAO",

            checkout,

            externalReference:
                referencia,

            clienteId:
                String(usuario.id),

            atualizadoEm:
                new Date().toISOString(),

        };

    const existente =
        await pool.query(
            `
            SELECT
                id,
                pagamento_id
            FROM pagamentos_asaas
            WHERE external_reference = $1
            ORDER BY criado_em DESC
            LIMIT 1
            `,
            [
                referencia,
            ]
        );

    if (
        existente.rows.length > 0
    ) {

        await pool.query(
            `
            UPDATE pagamentos_asaas
            SET
                dados = $1,
                atualizado_em = NOW()
            WHERE id = $2
            `,
            [
                dados,
                existente.rows[0].id,
            ]
        );

        return existente.rows[0].id;
    }

    const idTemporario =
        `CHK-${crypto.randomUUID()}`;

    await pool.query(
        `
        INSERT INTO pagamentos_asaas (
            id,
            pagamento_id,
            pedido_id,
            external_reference,
            status,
            valor,
            dados,
            criado_em,
            atualizado_em
        )
        VALUES (
            $1,
            $2,
            NULL,
            $3,
            'PENDING',
            $4,
            $5,
            NOW(),
            NOW()
        )
        `,
        [
            idTemporario,

            idTemporario,

            referencia,

            checkout.total,

            dados,
        ]
    );

    console.log(
        "💾 CHECKOUT DE CARTÃO SALVO:",
        referencia
    );

    return idTemporario;
}


// ============================================================
// ATUALIZAR CHECKOUT COM PAGAMENTO ASAAS
// ============================================================

async function vincularCheckoutAoPagamento(
    referencia,
    pagamento
) {

    const pagamentoId =
        String(
            pagamento?.id ||
            ""
        ).trim();

    if (!pagamentoId) {
        throw new Error(
            "Pagamento Asaas sem ID."
        );
    }

    const resultado =
        await pool.query(
            `
            SELECT
                id,
                pedido_id,
                dados
            FROM pagamentos_asaas
            WHERE
                external_reference = $1
            ORDER BY criado_em DESC
            LIMIT 1
            `,
            [
                referencia,
            ]
        );

    const dadosPagamento = {

        tipo:
            "CHECKOUT_CARTAO",

        checkout:
            parseDados(
                resultado.rows[0]?.dados
            ).checkout || null,

        pagamentoId,

        paymentId:
            pagamentoId,

        externalReference:
            referencia,

        statusAsaas:
            pagamento?.status ||
            "PENDING",

        statusPagamento:
            String(
                pagamento?.status ||
                "PENDING"
            ).toLowerCase(),

        valor:
            Number(
                pagamento?.value || 0
            ),

        atualizadoEm:
            new Date().toISOString(),

        asaas:
            pagamento,
    };

    if (
        resultado.rows.length > 0
    ) {

        await pool.query(
            `
            UPDATE pagamentos_asaas
            SET
                pagamento_id = $1,
                external_reference = $2,
                status = $3,
                valor = $4,
                dados = $5,
                atualizado_em = NOW()
            WHERE id = $6
            `,
            [
                pagamentoId,

                referencia,

                pagamento?.status ||
                    "PENDING",

                Number(
                    pagamento?.value || 0
                ),

                dadosPagamento,

                resultado.rows[0].id,
            ]
        );

        return;
    }

    await pool.query(
        `
        INSERT INTO pagamentos_asaas (
            id,
            pagamento_id,
            pedido_id,
            external_reference,
            status,
            valor,
            dados,
            criado_em,
            atualizado_em
        )
        VALUES (
            $1,
            $2,
            NULL,
            $3,
            $4,
            $5,
            $6,
            NOW(),
            NOW()
        )
        `,
        [
            pagamentoId,

            pagamentoId,

            referencia,

            pagamento?.status ||
                "PENDING",

            Number(
                pagamento?.value || 0
            ),

            dadosPagamento,
        ]
    );
}


// ============================================================
// PARSE DADOS
// ============================================================

function parseDados(valor) {

    if (!valor) {
        return {};
    }

    if (
        typeof valor === "object"
    ) {
        return valor;
    }

    try {
        return JSON.parse(valor);
    } catch {
        return {};
    }
}


// ============================================================
// PIX
// AGORA O PEDIDO SÓ É CRIADO PELO WEBHOOK ASAAS
// ============================================================

async function gerarPix(req, res) {

    try {

        console.log("");
        console.log("========================================");
        console.log("🟧 FOODJET - GERAR PIX");
        console.log("🟧 MODO: PAGAMENTO PRIMEIRO / PEDIDO DEPOIS");
        console.log("========================================");

        const usuario =
            await buscarUsuarioAutenticado(req);

        const body =
            req.body || {};

        // ====================================================
        // IMPORTANTE:
        //
        // NUNCA chamar Order.criar() neste fluxo.
        // O pedido somente será criado pelo webhook do Asaas
        // depois que o PIX for efetivamente aprovado/recebido.
        // ====================================================

        const referencia =
            gerarReferenciaCheckout(
                usuario.id
            );

        console.log(
            "🔖 REFERÊNCIA CHECKOUT:",
            referencia
        );

        const restauranteId =
            body.restauranteId ||
            body.restaurantId ||
            null;

        if (
            restauranteId === null ||
            String(restauranteId).trim() === ""
        ) {
            throw new Error(
                "Restaurante não informado."
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

        const valorFinal =
            validarValor(
                body.valor ??
                body.total
            );

        const subtotal =
            validarValor(
                body.subtotal ??
                valorFinal
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

        const dadosCliente =
            prepararDadosCliente(
                usuario,
                body
            );

        validarDadosCliente(
            dadosCliente
        );

        // ====================================================
        // CHECKOUT PIX
        // ====================================================
        //
        // Fica em pagamentos_asaas.dados.
        //
        // NÃO existe registro em pedidos.
        // ====================================================

        const checkout = {

            clienteId:
                String(usuario.id),

            restauranteId:
                String(restauranteId),

            itens,

            endereco:
                body.endereco || {},

            pagamento:
                "PIX",

            subtotal,

            taxaServico,

            taxaEntrega,

            total:
                valorFinal,

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

            checkoutCriadoEm:
                new Date().toISOString(),

        };

        // ====================================================
        // SALVAR CHECKOUT
        // ====================================================

        await salvarCheckoutPendente({

            referencia,

            usuario,

            checkout,

        });

        console.log(
            "💾 CHECKOUT PIX SALVO:",
            referencia
        );

        console.log(
            "📦 PEDIDO: NÃO CRIADO"
        );

        // ====================================================
        // CRIAR COBRANÇA ASAAS
        // ====================================================

        const pagamento =
            await criarPix({

                valor:
                    valorFinal,

                email:
                    dadosCliente.email,

                referencia,

                descricao:
                    `Pagamento FoodJet PIX ${referencia}`,

                nome:
                    dadosCliente.nomeCliente,

                cpf:
                    dadosCliente.documento,

                telefone:
                    dadosCliente.telefoneCliente,

                usuarioId:
                    String(usuario.id),

            });

        if (!pagamento?.id) {
            throw new Error(
                "O Asaas não retornou o ID da cobrança PIX."
            );
        }

        console.log(
            "💰 COBRANÇA PIX ASAAS:",
            pagamento.id
        );

        // ====================================================
        // VINCULAR ASAAS AO CHECKOUT
        // ====================================================

        await vincularCheckoutAoPagamento(
            referencia,
            pagamento
        );

        // ====================================================
        // OBTER QR CODE
        // ====================================================

        const pix =
            await obterQrCodePix(
                pagamento.id
            );

        if (
            !pix ||
            !pix.payload
        ) {
            throw new Error(
                "O Asaas criou a cobrança, mas não retornou o QR Code PIX."
            );
        }

        console.log(
            "📱 QR CODE PIX GERADO"
        );

        console.log(
            "📦 PEDIDO CONTINUA INEXISTENTE ATÉ O WEBHOOK."
        );

        return res.status(201).json({

            sucesso:
                true,

            pagamentoId:
                pagamento.id,

            paymentId:
                pagamento.id,

            // IMPORTANTE:
            // ainda não existe pedido.
            pedidoId:
                null,

            orderId:
                null,

            externalReference:
                pagamento.externalReference ||
                referencia,

            status:
                pagamento.status ||
                "PENDING",

            totalAmount:
                Number(
                    pagamento.value ??
                    valorFinal
                ),

            billingType:
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
        console.error("========================================");
        console.error("❌ ERRO GERANDO PIX");
        console.error("========================================");

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

            sucesso:
                false,

            erro:
                mensagem,

        });
    }
}



// ============================================================
// GERAR PAGAMENTO COM CARTÃO
// ============================================================

async function gerarCartao(req, res) {

    try {

        console.log("");
        console.log("==============================================");
        console.log("💳 FOODJET - PAGAMENTO COM CARTÃO");
        console.log("==============================================");

        // ====================================================
        // 1. CLIENTE AUTENTICADO PELO JWT
        // ====================================================

        const usuario =
            await buscarUsuarioAutenticado(req);

        console.log(
            "👤 CLIENTE:",
            usuario.id
        );

        // ====================================================
        // 2. BODY
        // ====================================================

        const body =
            req.body || {};

        // ====================================================
        // 3. VALOR
        // ====================================================

        const valorInformado =
            body.valor !== undefined &&
            body.valor !== null
                ? Number(body.valor)
                : Number(body.total);

        if (
            !Number.isFinite(valorInformado) ||
            valorInformado <= 0
        ) {
            return res.status(400).json({
                sucesso: false,
                erro: "Valor do pagamento inválido.",
            });
        }

        const valorFinal =
            Number(valorInformado.toFixed(2));

        // ====================================================
        // 4. DADOS DO CLIENTE
        //    TODOS VÊM DO POSTGRESQL
        // ====================================================

        const {
            nomeCliente,
            email,
            telefoneCliente,
            documento,
        } =
            prepararDadosCliente(usuario);

        console.log("👤 NOME:", nomeCliente);
        console.log("📧 E-MAIL:", email);
        console.log("📱 TELEFONE:", telefoneCliente);
        console.log(
            "📄 DOCUMENTO:",
            documento ? "OK" : "NÃO ENCONTRADO"
        );

        // ====================================================
        // 5. VALIDAR DADOS DO CLIENTE
        // ====================================================

        validarDadosCliente({
            email,
            documento,
        });

        if (!telefoneCliente) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Telefone não cadastrado. Atualize seu cadastro antes de realizar o pagamento.",
            });
        }

        if (
            telefoneCliente.length < 10 ||
            telefoneCliente.length > 11
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Telefone cadastrado inválido.",
            });
        }

        // ====================================================
        // 6. ENDEREÇO DE COBRANÇA
        //
        // ATENÇÃO:
        // NÃO USA body.endereco.
        //
        // O endereço usado pelo ASAAS vem do PostgreSQL.
        // ====================================================

        const endereco =
            obterEnderecoCobrancaDoUsuario(
                usuario
            );

        const cep =
            String(endereco.cep || "")
                .replace(/\D/g, "")
                .trim();

        const numeroEndereco =
            String(endereco.numero || "")
                .trim();

        const complemento =
            String(endereco.complemento || "")
                .trim();

        console.log("🏠 ENDEREÇO ASAAS");
        console.log("📮 CEP:", cep);
        console.log("🔢 NÚMERO:", numeroEndereco);
        console.log(
            "🏢 COMPLEMENTO:",
            complemento || "NÃO INFORMADO"
        );

        // ====================================================
        // 7. VALIDAR CEP
        // ====================================================

        if (cep.length !== 8) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "CEP não cadastrado ou inválido. Atualize seu endereço antes de realizar o pagamento.",
            });
        }

        // ====================================================
        // 8. VALIDAR NÚMERO
        // ====================================================

        if (!numeroEndereco) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Número do endereço não cadastrado. Atualize seu endereço antes de realizar o pagamento.",
            });
        }

        // ====================================================
        // 9. DADOS DO CARTÃO
        //
        // Estes são os ÚNICOS dados que continuam vindo
        // do Flutter.
        // ====================================================

        const cartao =
            body.cartao || {};

        const numero =
            String(
                cartao.numero ||
                cartao.number ||
                ""
            )
                .replace(/\D/g, "")
                .trim();

        const nomeCartao =
            String(
                cartao.nome ||
                cartao.nomeCartao ||
                cartao.holderName ||
                ""
            )
                .trim();

        const validade =
            String(
                cartao.validade ||
                cartao.expiry ||
                ""
            )
                .replace(/\D/g, "")
                .trim();

        const cvv =
            String(
                cartao.cvv ||
                cartao.ccv ||
                ""
            )
                .replace(/\D/g, "")
                .trim();

        // ====================================================
        // 10. VALIDAR NÚMERO DO CARTÃO
        // ====================================================

        if (
            numero.length < 13 ||
            numero.length > 19
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Número do cartão inválido.",
            });
        }

        // ====================================================
        // 11. VALIDAR NOME DO CARTÃO
        // ====================================================

        if (!nomeCartao) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Informe o nome impresso no cartão.",
            });
        }

        // ====================================================
        // 12. VALIDAR VALIDADE
        // Aceita MMYY ou MM/YY
        // ====================================================

        if (validade.length !== 4) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Validade do cartão inválida.",
            });
        }

        const mesExpiracao =
            validade.substring(0, 2);

        const anoExpiracao =
            validade.substring(2, 4);

        const mesNumero =
            Number(mesExpiracao);

        if (
            mesNumero < 1 ||
            mesNumero > 12
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Mês de validade do cartão inválido.",
            });
        }

        // ====================================================
        // 13. CVV
        // ====================================================

        if (
            cvv.length < 3 ||
            cvv.length > 4
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "CVV inválido.",
            });
        }

        // ====================================================
        // 14. IP DO CLIENTE
        // ====================================================

        const remoteIp =
            req.headers["x-forwarded-for"]
                ?.split(",")[0]
                ?.trim() ||
            req.socket?.remoteAddress ||
            req.ip ||
            null;

        // ====================================================
        // 15. REFERÊNCIA TEMPORÁRIA
        //
        // O PEDIDO AINDA NÃO É CRIADO AQUI.
        // O pagamento é criado primeiro.
        // ====================================================

        const checkout =
            await prepararCheckoutCartao(
                usuario,
                body,
                valorFinal
            );

        const referencia =
            String(
                checkout.referencia ||
                checkout.externalReference ||
                checkout.id ||
                `FOODJET-${Date.now()}`
            );

        console.log(
            "🔖 REFERÊNCIA:",
            referencia
        );

        // ====================================================
        // 16. CRIAR REGISTRO TEMPORÁRIO DO PAGAMENTO
        // ====================================================

        try {

            await pool.query(
                `
                INSERT INTO pagamentos_asaas
                (
                    referencia,
                    usuario_id,
                    status,
                    valor,
                    metodo
                )
                VALUES
                ($1, $2, $3, $4, $5)
                ON CONFLICT (referencia)
                DO UPDATE SET
                    usuario_id = EXCLUDED.usuario_id,
                    status = EXCLUDED.status,
                    valor = EXCLUDED.valor,
                    metodo = EXCLUDED.metodo
                `,
                [
                    referencia,
                    usuario.id,
                    "PENDING",
                    valorFinal,
                    "CREDIT_CARD",
                ]
            );

        } catch (erroBanco) {

            console.log(
                "⚠️ Não foi possível registrar pagamento temporário:",
                erroBanco.message
            );

            // Não interrompe o pagamento caso sua tabela
            // possua estrutura diferente.
        }

        // ====================================================
        // 17. CRIAR PAGAMENTO NO ASAAS
        // ====================================================

        console.log(
            "💳 Enviando pagamento para ASAAS..."
        );

        const pagamento =
            await criarCartao({

                valor: valorFinal,

                // Dados vindos do PostgreSQL
                email,

                referencia,

                descricao:
                    `Pagamento FoodJet ${referencia}`,

                nome:
                    nomeCliente,

                cpf:
                    documento,

                telefone:
                    telefoneCliente,

                usuarioId:
                    String(usuario.id),

                // Dados do cartão
                cartao: {

                    numero,

                    nome:
                        nomeCartao,

                    mesExpiracao,

                    anoExpiracao,

                    cvv,
                },

                // ENDEREÇO VINDO DO POSTGRESQL
                endereco: {

                    cep,

                    numero:
                        numeroEndereco,

                    complemento,
                },

                remoteIp,
            });

        // ====================================================
        // 18. VINCULAR ASAAS AO CHECKOUT
        // ====================================================

        await vincularCheckoutAoPagamento(
            referencia,
            pagamento
        );

        console.log(
            "✅ PAGAMENTO ASAAS CRIADO"
        );

        console.log(
            "🆔 ASAAS:",
            pagamento.id
        );

        console.log(
            "📊 STATUS:",
            pagamento.status
        );

        // ====================================================
        // 19. RESPOSTA
        //
        // pedidoId continua null porque o pedido só será
        // criado depois da confirmação do pagamento.
        // ====================================================

        return res.status(200).json({

            sucesso: true,

            pagamentoId:
                pagamento.id,

            id:
                pagamento.id,

            pedidoId:
                null,

            status:
                pagamento.status,

            statusPagamento:
                pagamento.status,

            metodo:
                "CREDIT_CARD",

            valor:
                valorFinal,

            mensagem:
                "Pagamento com cartão enviado para processamento.",
        });

    } catch (erro) {

        console.error("");
        console.error(
            "❌ ERRO AO PROCESSAR CARTÃO"
        );

        console.error(
            erro?.response?.data ||
            erro?.message ||
            erro
        );

        return res.status(
            erro?.response?.status || 500
        ).json({

            sucesso: false,

            erro:
                erro?.response?.data?.errors?.[0]?.description ||
                erro?.response?.data?.message ||
                erro?.message ||
                "Erro ao processar pagamento com cartão.",
        });
    }
}




// ============================================================
// DÉBITO
// ============================================================
//
// Mantido como estava.
// ============================================================

async function gerarDebito(req, res) {

    let pedido = null;

    try {

        const usuario =
            await buscarUsuarioAutenticado(req);

        const body =
            req.body || {};

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
                body.valor ??
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

        const pagamento =
            await criarDebito({

                valor:
                    valorFinal,

                email:
                    dadosCliente.email,

                referencia,

                descricao:
                    `Pedido FoodJet #${referencia}`,

                nome:
                    dadosCliente.nomeCliente,

                cpf:
                    dadosCliente.documento,

                telefone:
                    dadosCliente.telefoneCliente,

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

        return res.status(201).json({

            sucesso: true,

            pagamentoId:
                pagamento.id,

            paymentId:
                pagamento.id,

            pedidoId:
                pedido.id,

            externalReference:
                pagamento.externalReference ||
                referencia,

            status:
                pagamento.status ||
                "PENDING",

            totalAmount:
                Number(
                    pagamento.value ??
                    valorFinal
                ),

            billingType:
                pagamento.billingType ||
                "DEBIT_CARD",

            invoiceUrl:
                pagamento.invoiceUrl ||
                "",
        });

    } catch (erro) {

        console.error(
            "❌ ERRO GERANDO DÉBITO:",
            erro?.message || erro
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

            erro:
                mensagem,
        });
    }
}


// ============================================================
// CONSULTAR PAGAMENTO
// ============================================================
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

        const pagamento =
            await consultarPagamento(
                pagamentoId
            );

        const externalReference =
            String(
                pagamento?.externalReference ||
                ""
            ).trim();

        // ====================================================
        // BUSCAR REGISTRO LOCAL DO PAGAMENTO
        // ====================================================

        let registroPagamento = null;

        const registro =
            await pool.query(
                `
                SELECT
                    id,
                    pedido_id,
                    dados
                FROM pagamentos_asaas
                WHERE
                    pagamento_id = $1
                    OR external_reference = $2
                ORDER BY
                    CASE
                        WHEN pagamento_id = $1 THEN 0
                        ELSE 1
                    END,
                    criado_em DESC
                LIMIT 1
                `,
                [
                    pagamentoId,
                    externalReference,
                ]
            );

        if (
            registro.rows.length > 0
        ) {

            registroPagamento =
                registro.rows[0];

        }

        let pedidoId =
            registroPagamento?.pedido_id ||
            null;

        // ====================================================
        // SE PAGAMENTO FOI APROVADO
        // ====================================================
        //
        // O webhook normalmente já terá criado o pedido.
        //
        // Se o polling chegar primeiro, o webhook pode ainda
        // não ter criado. Nesse caso, o webhook deve finalizar.
        //
        // Para não duplicar pedidos, aqui não criamos
        // diretamente. Apenas aguardamos o processamento do
        // webhook.
        // ====================================================

        let pedido = null;

        if (pedidoId) {

            pedido =
                await Order.buscarPorId(
                    pedidoId
                );

        } else if (externalReference) {

            // -----------------------------------------------
            // Fluxo antigo: referência numérica
            // -----------------------------------------------

            if (
                /^\d+$/.test(
                    externalReference
                )
            ) {

                try {

                    pedido =
                        await Order.buscarPorId(
                            externalReference
                        );

                } catch {
                    pedido = null;
                }

            }

        }

        // ====================================================
        // SEGURANÇA
        // ====================================================

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

        // ====================================================
        // RETORNO
        // ====================================================

        return res.json({

            sucesso: true,

            pagamentoId:
                pagamento?.id ||
                pagamentoId,

            orderId:
                pedido?.id ||
                null,

            pedidoId:
                pedido?.id ||
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

            pedidoCriado:
                !!pedido,

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

    statusContaAsaas,   

};

