const Restaurant = require("../models/restaurant");

const fs = require("fs");
const path = require("path");
const multer = require("multer");

// ============================================================
// PASTAS
// ============================================================

const pastaUploads = path.join(
    process.cwd(),
    "uploads"
);

const pastaCapas = path.join(
    pastaUploads,
    "capas"
);

const pastaLogos = path.join(
    pastaUploads,
    "logos"
);

function criarPastas() {
    fs.mkdirSync(pastaUploads, {
        recursive: true,
    });

    fs.mkdirSync(pastaCapas, {
        recursive: true,
    });

    fs.mkdirSync(pastaLogos, {
        recursive: true,
    });
}

criarPastas();

console.log("========================================");
console.log("📁 PASTA UPLOADS:", pastaUploads);
console.log("📁 PASTA CAPAS:", pastaCapas);
console.log("📁 PASTA LOGOS:", pastaLogos);
console.log("========================================");

// ============================================================
// UTILITÁRIOS
// ============================================================

function limparId(id) {
    return String(id || "")
        .replace(/[^a-zA-Z0-9_-]/g, "_");
}

function normalizarCaminhoImagem(valor) {
    if (
        valor === null ||
        valor === undefined
    ) {
        return null;
    }

    const texto = String(valor).trim();

    if (!texto) {
        return null;
    }

    if (
        texto.startsWith("http://") ||
        texto.startsWith("https://") ||
        texto.startsWith("data:image/")
    ) {
        return texto;
    }

    if (texto.startsWith("/")) {
        return texto;
    }

    return `/${texto}`;
}

function removerArquivo(caminho) {
    try {
        if (!caminho) {
            return;
        }

        let caminhoLimpo = String(caminho).trim();

        if (
            caminhoLimpo.startsWith("http://") ||
            caminhoLimpo.startsWith("https://")
        ) {
            try {
                const url = new URL(caminhoLimpo);
                caminhoLimpo = url.pathname;
            } catch (_) {
                return;
            }
        }

        if (
            caminhoLimpo.startsWith("/uploads/")
        ) {
            caminhoLimpo = caminhoLimpo.substring(1);
        }

        if (
            !caminhoLimpo.startsWith("uploads/")
        ) {
            return;
        }

        const caminhoFisico = path.join(
            process.cwd(),
            caminhoLimpo
        );

        if (fs.existsSync(caminhoFisico)) {
            fs.unlinkSync(caminhoFisico);

            console.log(
                "🗑️ ARQUIVO REMOVIDO:",
                caminhoFisico
            );
        }
    } catch (erro) {
        console.error(
            "⚠️ ERRO AO REMOVER ARQUIVO:",
            erro.message
        );
    }
}

function removerArquivoCapa(caminho) {
    removerArquivo(caminho);
}

function removerArquivoLogo(caminho) {
    removerArquivo(caminho);
}

// ============================================================
// BASE64 DO LOGO
// ============================================================

function salvarLogoBase64(
    imagem,
    restauranteId
) {
    if (
        typeof imagem !== "string"
    ) {
        return null;
    }

    const valor = imagem.trim();

    if (
        !valor.startsWith("data:image/")
    ) {
        return null;
    }

    const match = valor.match(
        /^data:(image\/[a-zA-Z0-9.+-]+);base64,(.+)$/i
    );

    if (!match) {
        throw new Error(
            "Formato Base64 do logo inválido."
        );
    }

    const mime = match[1].toLowerCase();

    const base64 = match[2];

    let extensao;

    if (
        mime === "image/webp"
    ) {
        extensao = ".webp";
    } else if (
        mime === "image/png" ||
        mime === "image/x-png"
    ) {
        extensao = ".png";
    } else if (
        mime === "image/jpeg" ||
        mime === "image/jpg"
    ) {
        extensao = ".jpg";
    } else {
        throw new Error(
            "Formato de logo não permitido. Use JPG, PNG ou WEBP."
        );
    }

    const buffer = Buffer.from(
        base64,
        "base64"
    );

    if (!buffer.length) {
        throw new Error(
            "O arquivo do logo está vazio."
        );
    }

    if (
        buffer.length >
        5 * 1024 * 1024
    ) {
        throw new Error(
            "A imagem do logo deve ter no máximo 5 MB."
        );
    }

    criarPastas();

    const nomeArquivo =
        `logo_${limparId(restauranteId)}_${Date.now()}${extensao}`;

    const caminhoArquivo = path.join(
        pastaLogos,
        nomeArquivo
    );

    fs.writeFileSync(
        caminhoArquivo,
        buffer
    );

    console.log(
        "✅ LOGO BASE64 SALVO:",
        caminhoArquivo
    );

    return `/uploads/logos/${nomeArquivo}`;
}

// ============================================================
// MULTER - CAPA
// ============================================================

const storageCapa =
    multer.diskStorage({

        destination: (
            req,
            file,
            cb
        ) => {
            criarPastas();

            cb(
                null,
                pastaCapas
            );
        },

        filename: (
            req,
            file,
            cb
        ) => {

            let extensao =
                path.extname(
                    String(
                        file.originalname || ""
                    )
                ).toLowerCase();

            if (
                extensao === ".jpeg"
            ) {
                extensao = ".jpg";
            }

            if (
                ![
                    ".jpg",
                    ".png",
                    ".webp",
                ].includes(extensao)
            ) {
                extensao = ".jpg";
            }

            const nome =
                `capa_${limparId(req.params.id)}_${Date.now()}${extensao}`;

            cb(
                null,
                nome
            );
        },
    });

const uploadCapaMulter =
    multer({
        storage: storageCapa,

        limits: {
            fileSize:
                10 * 1024 * 1024,
        },

        fileFilter: (
            req,
            file,
            cb
        ) => {

            const mime =
                String(
                    file.mimetype || ""
                ).toLowerCase();

            const extensao =
                path.extname(
                    String(
                        file.originalname || ""
                    )
                ).toLowerCase();

            const mimePermitidos = [
                "image/jpeg",
                "image/jpg",
                "image/png",
                "image/webp",
                "image/x-png",
            ];

            const extensoesPermitidas = [
                ".jpg",
                ".jpeg",
                ".png",
                ".webp",
            ];

            if (
                mimePermitidos.includes(
                    mime
                ) ||
                extensoesPermitidas.includes(
                    extensao
                )
            ) {
                return cb(
                    null,
                    true
                );
            }

            return cb(
                new Error(
                    "Formato de capa não permitido. Use JPG, PNG ou WEBP."
                )
            );
        },
    });

// ============================================================
// MULTER - LOGO
// ============================================================

const storageLogo =
    multer.diskStorage({

        destination: (
            req,
            file,
            cb
        ) => {

            criarPastas();

            cb(
                null,
                pastaLogos
            );
        },

        filename: (
            req,
            file,
            cb
        ) => {

            let extensao =
                path.extname(
                    String(
                        file.originalname || ""
                    )
                ).toLowerCase();

            if (
                extensao === ".jpeg"
            ) {
                extensao = ".jpg";
            }

            if (
                ![
                    ".jpg",
                    ".png",
                    ".webp",
                ].includes(extensao)
            ) {
                extensao = ".jpg";
            }

            const nome =
                `logo_${limparId(req.params.id)}_${Date.now()}${extensao}`;

            cb(
                null,
                nome
            );
        },
    });

const uploadLogoMulter =
    multer({
        storage: storageLogo,

        limits: {
            fileSize:
                5 * 1024 * 1024,
        },

        fileFilter: (
            req,
            file,
            cb
        ) => {

            const mime =
                String(
                    file.mimetype || ""
                ).toLowerCase();

            const extensao =
                path.extname(
                    String(
                        file.originalname || ""
                    )
                ).toLowerCase();

            const mimePermitidos = [
                "image/jpeg",
                "image/jpg",
                "image/png",
                "image/webp",
                "image/x-png",
            ];

            const extensoesPermitidas = [
                ".jpg",
                ".jpeg",
                ".png",
                ".webp",
            ];

            if (
                mimePermitidos.includes(
                    mime
                ) ||
                extensoesPermitidas.includes(
                    extensao
                )
            ) {
                return cb(
                    null,
                    true
                );
            }

            return cb(
                new Error(
                    "Formato de logo não permitido. Use JPG, PNG ou WEBP."
                )
            );
        },
    });

// ============================================================
// CRIAR RESTAURANTE
// ============================================================

exports.create = async (
    req,
    res
) => {

    try {

        console.log(
            "========================================"
        );

        console.log(
            "🏪 CRIANDO RESTAURANTE"
        );

        console.log(
            "========================================"
        );

        const restaurante = {
            id:
                req.body.id ||
                `rest_${Date.now()}`,

            nome:
                req.body.nome ||
                "",

            categoria:
                req.body.categoria ||
                "",

            descricao:
                req.body.descricao ||
                "",

            telefone:
                req.body.telefone ||
                "",

            endereco:
                req.body.endereco ||
                "",

            numero:
                req.body.numero ||
                "",

            bairro:
                req.body.bairro ||
                "",

            cidade:
                req.body.cidade ||
                "",

            estado:
                req.body.estado ||
                "",

            cep:
                req.body.cep ||
                "",

            logo:
                null,

            capa:
                req.body.capa ||
                null,

            imagem:
                null,

            status:
                req.body.status ||
                "ABERTO",

            online:
                req.body.online !==
                undefined
                    ? req.body.online
                    : true,

            aberto:
                req.body.aberto !==
                undefined
                    ? req.body.aberto
                    : true,

            ativo:
                req.body.ativo !==
                undefined
                    ? req.body.ativo
                    : true,
        };

        // ----------------------------------------------------
        // LOGO BASE64
        // ----------------------------------------------------

        const imagemRecebida =
            req.body.logo ||
            req.body.imagem ||
            req.body.foto ||
            null;

        if (
            typeof imagemRecebida ===
                "string" &&
            imagemRecebida.startsWith(
                "data:image/"
            )
        ) {

            restaurante.logo =
                salvarLogoBase64(
                    imagemRecebida,
                    restaurante.id
                );

            restaurante.imagem =
                null;
        }

        // ----------------------------------------------------
        // SALVAR
        // ----------------------------------------------------

        const resultado =
            await Restaurant.criar(
                restaurante
            );

        console.log(
            "✅ RESTAURANTE CRIADO:",
            restaurante.id
        );

        return res.status(201).json(
            {
                sucesso: true,
                restaurante:
                    resultado ||
                    restaurante,
            }
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO CRIAR RESTAURANTE:",
            erro
        );

        return res.status(500).json(
            {
                sucesso: false,
                mensagem:
                    erro.message ||
                    "Erro ao criar restaurante.",
            }
        );
    }
};

// ============================================================
// LISTAR RESTAURANTES
// ============================================================

exports.list = async (
    req,
    res
) => {

    try {

        const restaurantes =
            await Restaurant.listar();

        const lista =
            Array.isArray(
                restaurantes
            )
                ? restaurantes
                : [];

        const resultado =
            lista.map(
                (restaurante) => {

                    const item = {
                        ...restaurante,
                    };

                    if (
                        item.logo
                    ) {
                        item.logo =
                            normalizarCaminhoImagem(
                                item.logo
                            );
                    }

                    if (
                        item.capa
                    ) {
                        item.capa =
                            normalizarCaminhoImagem(
                                item.capa
                            );
                    }

                    // Nunca devolver Base64 gigante
                    if (
                        typeof item.imagem ===
                            "string" &&
                        item.imagem.startsWith(
                            "data:image/"
                        )
                    ) {
                        item.imagem =
                            null;
                    }

                    return item;
                }
            );

        return res.json(
            resultado
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO LISTAR RESTAURANTES:",
            erro
        );

        return res.status(500).json(
            {
                sucesso: false,
                mensagem:
                    erro.message ||
                    "Erro ao listar restaurantes.",
            }
        );
    }
};

// ============================================================
// BUSCAR POR ID
// ============================================================

exports.getById = async (
    req,
    res
) => {

    try {

        const id =
            String(
                req.params.id || ""
            ).trim();

        console.log(
            "========================================"
        );

        console.log(
            "🔎 BUSCANDO RESTAURANTE"
        );

        console.log(
            "ID:",
            id
        );

        console.log(
            "========================================"
        );

        if (!id) {
            return res.status(400).json(
                {
                    sucesso: false,
                    mensagem:
                        "ID do restaurante não informado.",
                }
            );
        }

        const restaurante =
            await Restaurant.buscarPorId(
                id
            );

        if (!restaurante) {

            return res.status(404).json(
                {
                    sucesso: false,
                    mensagem:
                        "Restaurante não encontrado.",
                }
            );
        }

        const resultado = {
            ...restaurante,
        };

        // ----------------------------------------------------
        // LOGO
        // ----------------------------------------------------

        if (
            resultado.logo
        ) {

            resultado.logo =
                normalizarCaminhoImagem(
                    resultado.logo
                );
        }

        // ----------------------------------------------------
        // CAPA
        // ----------------------------------------------------

        if (
            resultado.capa
        ) {

            resultado.capa =
                normalizarCaminhoImagem(
                    resultado.capa
                );
        }

        // ----------------------------------------------------
        // NÃO ENVIAR BASE64 GIGANTE
        // ----------------------------------------------------

        if (
            typeof resultado.imagem ===
                "string" &&
            resultado.imagem.startsWith(
                "data:image/"
            )
        ) {

            resultado.imagem =
                null;
        }

        console.log(
            "📦 RESTAURANTE DEVOLVIDO:"
        );

        console.log(
            "ID:",
            resultado.id
        );

        console.log(
            "LOGO:",
            resultado.logo
        );

        console.log(
            "CAPA:",
            resultado.capa
        );

        return res.json(
            {
                sucesso: true,
                restaurante:
                    resultado,
            }
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO BUSCAR RESTAURANTE:",
            erro
        );

        return res.status(500).json(
            {
                sucesso: false,
                mensagem:
                    erro.message ||
                    "Erro ao buscar restaurante.",
            }
        );
    }
};

// ============================================================
// ATUALIZAR RESTAURANTE
// ============================================================

exports.update = async (
    req,
    res
) => {

    try {

        const id =
            String(
                req.params.id || ""
            ).trim();

        console.log(
            "========================================"
        );

        console.log(
            "⚙️ ATUALIZANDO RESTAURANTE"
        );

        console.log(
            "ID:",
            id
        );

        console.log(
            "========================================"
        );

        if (!id) {
            return res.status(400).json(
                {
                    sucesso: false,
                    mensagem:
                        "ID do restaurante não informado.",
                }
            );
        }

        const restauranteAtual =
            await Restaurant.buscarPorId(
                id
            );

        if (!restauranteAtual) {

            return res.status(404).json(
                {
                    sucesso: false,
                    mensagem:
                        "Restaurante não encontrado.",
                }
            );
        }

        const dados =
            {
                ...req.body,
            };

        // ----------------------------------------------------
        // LOGO BASE64
        // ----------------------------------------------------

        const imagemRecebida =
            dados.logo ||
            dados.imagem ||
            dados.foto ||
            null;

        if (
            typeof imagemRecebida ===
                "string" &&
            imagemRecebida.startsWith(
                "data:image/"
            )
        ) {

            console.log(
                "🖼️ LOGO BASE64 RECEBIDO"
            );

            const logoAntigo =
                restauranteAtual.logo ||
                restauranteAtual.imagem ||
                null;

            const novoLogo =
                salvarLogoBase64(
                    imagemRecebida,
                    id
                );

            dados.logo =
                novoLogo;

            dados.imagem =
                null;

            delete dados.foto;

            // ------------------------------------------------
            // ATUALIZAR BANCO
            // ------------------------------------------------

            const atualizado =
                await Restaurant.atualizar(
                    id,
                    dados
                );

            if (!atualizado) {

                removerArquivoLogo(
                    novoLogo
                );

                return res.status(500).json(
                    {
                        sucesso: false,
                        mensagem:
                            "Não foi possível atualizar o restaurante.",
                    }
                );
            }

            // ------------------------------------------------
            // REMOVER LOGO ANTIGO
            // ------------------------------------------------

            if (
                logoAntigo &&
                logoAntigo !== novoLogo
            ) {

                removerArquivoLogo(
                    logoAntigo
                );
            }

            console.log(
                "✅ NOVO LOGO:",
                novoLogo
            );

            if (
                global.io
            ) {

                global.io.emit(
                    "restaurante_atualizado",
                    atualizado
                );
            }

            return res.json(
                {
                    sucesso: true,
                    mensagem:
                        "Restaurante atualizado com sucesso.",
                    restaurante:
                        atualizado,
                    logo:
                        novoLogo,
                }
            );
        }

        // ----------------------------------------------------
        // LOGO NORMAL
        // ----------------------------------------------------

        if (
            dados.logo
        ) {

            dados.logo =
                normalizarCaminhoImagem(
                    dados.logo
                );
        }

        // ----------------------------------------------------
        // CAPA
        // ----------------------------------------------------

        if (
            dados.capa
        ) {

            dados.capa =
                normalizarCaminhoImagem(
                    dados.capa
                );
        }

        // ----------------------------------------------------
        // ATUALIZAR NORMAL
        // ----------------------------------------------------

        const atualizado =
            await Restaurant.atualizar(
                id,
                dados
            );

        if (!atualizado) {

            return res.status(500).json(
                {
                    sucesso: false,
                    mensagem:
                        "Não foi possível atualizar o restaurante.",
                }
            );
        }

        console.log(
            "✅ RESTAURANTE ATUALIZADO"
        );

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_atualizado",
                atualizado
            );
        }

        return res.json(
            {
                sucesso: true,
                mensagem:
                    "Restaurante atualizado com sucesso.",
                restaurante:
                    atualizado,
            }
        );

    } catch (erro) {

        console.error(
            "❌ ERRO AO ATUALIZAR RESTAURANTE:",
            erro
        );

        return res.status(500).json(
            {
                sucesso: false,
                mensagem:
                    erro.message ||
                    "Erro ao atualizar restaurante.",
            }
        );
    }
};

// ============================================================
// UPLOAD DA CAPA
// ============================================================

exports.uploadCapa = (
    req,
    res
) => {

    uploadCapaMulter.single(
        "capa"
    )(
        req,
        res,
        async (
            erro
        ) => {

            try {

                if (erro) {

                    console.error(
                        "❌ ERRO MULTER CAPA:",
                        erro
                    );

                    if (
                        erro.code ===
                        "LIMIT_FILE_SIZE"
                    ) {

                        return res.status(
                            400
                        ).json(
                            {
                                sucesso:
                                    false,
                                mensagem:
                                    "A capa deve ter no máximo 10 MB.",
                            }
                        );
                    }

                    return res.status(
                        400
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                erro.message ||
                                "Erro ao enviar capa.",
                        }
                    );
                }

                const id =
                    String(
                        req.params.id ||
                            ""
                    ).trim();

                if (!req.file) {

                    return res.status(
                        400
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                "Nenhuma capa foi enviada.",
                        }
                    );
                }

                console.log(
                    "========================================"
                );

                console.log(
                    "📤 UPLOAD DE CAPA"
                );

                console.log(
                    "ID:",
                    id
                );

                console.log(
                    "ARQUIVO:",
                    req.file.filename
                );

                console.log(
                    "CAMINHO:",
                    req.file.path
                );

                console.log(
                    "========================================"
                );

                const restaurante =
                    await Restaurant.buscarPorId(
                        id
                    );

                if (!restaurante) {

                    try {
                        fs.unlinkSync(
                            req.file.path
                        );
                    } catch (_) {}

                    return res.status(
                        404
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                "Restaurante não encontrado.",
                        }
                    );
                }

                const capaAntiga =
                    restaurante.capa ||
                    restaurante.capaUrl ||
                    null;

                const capaUrl =
                    `/uploads/capas/${req.file.filename}`;

                const atualizado =
                    await Restaurant.atualizar(
                        id,
                        {
                            capa:
                                capaUrl,
                        }
                    );

                if (!atualizado) {

                    removerArquivoCapa(
                        capaUrl
                    );

                    return res.status(
                        500
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                "Não foi possível salvar a capa.",
                        }
                    );
                }

                if (
                    capaAntiga &&
                    capaAntiga !== capaUrl
                ) {

                    removerArquivoCapa(
                        capaAntiga
                    );
                }

                console.log(
                    "✅ CAPA SALVA:",
                    capaUrl
                );

                if (
                    global.io
                ) {

                    global.io.emit(
                        "restaurante_atualizado",
                        atualizado
                    );
                }

                return res.json(
                    {
                        sucesso:
                            true,

                        mensagem:
                            "Capa enviada com sucesso.",

                        capa:
                            capaUrl,

                        restaurante:
                            atualizado,
                    }
                );

            } catch (erroInterno) {

                console.error(
                    "❌ ERRO NO UPLOAD DA CAPA:",
                    erroInterno
                );

                if (
                    req.file &&
                    req.file.path
                ) {

                    try {
                        fs.unlinkSync(
                            req.file.path
                        );
                    } catch (_) {}
                }

                return res.status(
                    500
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            erroInterno.message ||
                            "Erro ao enviar capa.",
                    }
                );
            }
        }
    );
};

// ============================================================
// REMOVER CAPA
// ============================================================

exports.deleteCapa =
    async (
        req,
        res
    ) => {

        try {

            const id =
                String(
                    req.params.id ||
                        ""
                ).trim();

            const restaurante =
                await Restaurant.buscarPorId(
                    id
                );

            if (!restaurante) {

                return res.status(
                    404
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            "Restaurante não encontrado.",
                    }
                );
            }

            const capaAntiga =
                restaurante.capa ||
                null;

            const atualizado =
                await Restaurant.atualizar(
                    id,
                    {
                        capa:
                            null,
                    }
                );

            if (!atualizado) {

                return res.status(
                    500
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            "Não foi possível remover a capa.",
                    }
                );
            }

            if (
                capaAntiga
            ) {

                removerArquivoCapa(
                    capaAntiga
                );
            }

            if (
                global.io
            ) {

                global.io.emit(
                    "restaurante_atualizado",
                    atualizado
                );
            }

            return res.json(
                {
                    sucesso:
                        true,
                    mensagem:
                        "Capa removida com sucesso.",
                    restaurante:
                        atualizado,
                }
            );

        } catch (erro) {

            console.error(
                "❌ ERRO AO REMOVER CAPA:",
                erro
            );

            return res.status(
                500
            ).json(
                {
                    sucesso:
                        false,
                    mensagem:
                        erro.message ||
                        "Erro ao remover capa.",
                }
            );
        }
    };

// ============================================================
// UPLOAD DO LOGO
// ============================================================

exports.uploadLogo = (
    req,
    res
) => {

    uploadLogoMulter.single(
        "logo"
    )(
        req,
        res,
        async (
            erro
        ) => {

            try {

                if (erro) {

                    console.error(
                        "❌ ERRO MULTER LOGO:",
                        erro
                    );

                    if (
                        erro.code ===
                        "LIMIT_FILE_SIZE"
                    ) {

                        return res.status(
                            400
                        ).json(
                            {
                                sucesso:
                                    false,
                                mensagem:
                                    "O logo deve ter no máximo 5 MB.",
                            }
                        );
                    }

                    return res.status(
                        400
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                erro.message ||
                                "Erro ao enviar logo.",
                        }
                    );
                }

                const id =
                    String(
                        req.params.id ||
                            ""
                    ).trim();

                if (!req.file) {

                    return res.status(
                        400
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                "Nenhum logo foi enviado.",
                        }
                    );
                }

                console.log(
                    "========================================"
                );

                console.log(
                    "📤 FOODJET - UPLOAD LOGO"
                );

                console.log(
                    "🏪 Restaurante:",
                    id
                );

                console.log(
                    "📁 Arquivo:",
                    req.file.filename
                );

                console.log(
                    "📁 Caminho:",
                    req.file.path
                );

                console.log(
                    "📦 Tamanho:",
                    req.file.size
                );

                console.log(
                    "========================================"
                );

                // --------------------------------------------
                // VERIFICAR RESTAURANTE
                // --------------------------------------------

                const restaurante =
                    await Restaurant.buscarPorId(
                        id
                    );

                if (!restaurante) {

                    try {
                        fs.unlinkSync(
                            req.file.path
                        );
                    } catch (_) {}

                    return res.status(
                        404
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                "Restaurante não encontrado.",
                        }
                    );
                }

                // --------------------------------------------
                // LOGO ANTIGO
                // --------------------------------------------

                const logoAntigo =
                    restaurante.logo ||
                    restaurante.logoUrl ||
                    restaurante.imagem ||
                    restaurante.foto ||
                    null;

                // --------------------------------------------
                // NOVO CAMINHO
                // --------------------------------------------

                const logoUrl =
                    `/uploads/logos/${req.file.filename}`;

                console.log(
                    "💾 SALVANDO NO BANCO:",
                    logoUrl
                );

                // --------------------------------------------
                // ATUALIZAR POSTGRESQL
                // --------------------------------------------

                const atualizado =
                    await Restaurant.atualizar(
                        id,
                        {
                            logo:
                                logoUrl,

                            imagem:
                                null,
                        }
                    );

                if (!atualizado) {

                    console.error(
                        "❌ BANCO NÃO FOI ATUALIZADO"
                    );

                    removerArquivoLogo(
                        logoUrl
                    );

                    return res.status(
                        500
                    ).json(
                        {
                            sucesso:
                                false,
                            mensagem:
                                "Não foi possível salvar o logo no banco.",
                        }
                    );
                }

                // --------------------------------------------
                // REMOVER LOGO ANTIGO
                // --------------------------------------------

                if (
                    logoAntigo &&
                    logoAntigo !== logoUrl
                ) {

                    removerArquivoLogo(
                        logoAntigo
                    );
                }

                console.log(
                    "========================================"
                );

                console.log(
                    "✅ LOGO SALVO COM SUCESSO"
                );

                console.log(
                    "URL:",
                    logoUrl
                );

                console.log(
                    "ARQUIVO FÍSICO:",
                    req.file.path
                );

                console.log(
                    "========================================"
                );

                // --------------------------------------------
                // SOCKET.IO
                // --------------------------------------------

                if (
                    global.io
                ) {

                    global.io.emit(
                        "restaurante_atualizado",
                        atualizado
                    );

                    console.log(
                        "📡 RESTAURANTE ATUALIZADO ENVIADO AOS CLIENTES"
                    );
                }

                return res.json(
                    {
                        sucesso:
                            true,

                        mensagem:
                            "Logo enviado com sucesso.",

                        logo:
                            logoUrl,

                        restaurante:
                            atualizado,
                    }
                );

            } catch (erroInterno) {

                console.error(
                    "❌ ERRO NO UPLOAD DO LOGO:",
                    erroInterno
                );

                if (
                    req.file &&
                    req.file.path
                ) {

                    try {
                        fs.unlinkSync(
                            req.file.path
                        );
                    } catch (_) {}
                }

                return res.status(
                    500
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            erroInterno.message ||
                            "Erro ao enviar logo.",
                    }
                );
            }
        }
    );
};

// ============================================================
// REMOVER LOGO
// ============================================================

exports.deleteLogo =
    async (
        req,
        res
    ) => {

        try {

            const id =
                String(
                    req.params.id ||
                        ""
                ).trim();

            console.log(
                "========================================"
            );

            console.log(
                "🗑️ REMOVENDO LOGO"
            );

            console.log(
                "ID:",
                id
            );

            console.log(
                "========================================"
            );

            const restaurante =
                await Restaurant.buscarPorId(
                    id
                );

            if (!restaurante) {

                return res.status(
                    404
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            "Restaurante não encontrado.",
                    }
                );
            }

            const logoAntigo =
                restaurante.logo ||
                restaurante.logoUrl ||
                restaurante.imagem ||
                restaurante.foto ||
                null;

            const atualizado =
                await Restaurant.atualizar(
                    id,
                    {
                        logo:
                            null,

                        imagem:
                            null,
                    }
                );

            if (!atualizado) {

                return res.status(
                    500
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            "Não foi possível remover o logo.",
                    }
                );
            }

            if (
                logoAntigo
            ) {

                removerArquivoLogo(
                    logoAntigo
                );
            }

            if (
                global.io
            ) {

                global.io.emit(
                    "restaurante_atualizado",
                    atualizado
                );
            }

            console.log(
                "✅ LOGO REMOVIDO"
            );

            return res.json(
                {
                    sucesso:
                        true,

                    mensagem:
                        "Logo removido com sucesso.",

                    restaurante:
                        atualizado,
                }
            );

        } catch (erro) {

            console.error(
                "❌ ERRO AO REMOVER LOGO:",
                erro
            );

            return res.status(
                500
            ).json(
                {
                    sucesso:
                        false,
                    mensagem:
                        erro.message ||
                        "Erro ao remover logo.",
                }
            );
        }
    };

// ============================================================
// EXCLUIR RESTAURANTE
// ============================================================

exports.delete =
    async (
        req,
        res
    ) => {

        try {

            const id =
                String(
                    req.params.id ||
                        ""
                ).trim();

            console.log(
                "========================================"
            );

            console.log(
                "🗑️ EXCLUINDO RESTAURANTE"
            );

            console.log(
                "ID:",
                id
            );

            console.log(
                "========================================"
            );

            const restaurante =
                await Restaurant.buscarPorId(
                    id
                );

            if (!restaurante) {

                return res.status(
                    404
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            "Restaurante não encontrado.",
                    }
                );
            }

            const logo =
                restaurante.logo ||
                restaurante.imagem ||
                null;

            const capa =
                restaurante.capa ||
                null;

            let resultado;

            if (
                typeof Restaurant.excluir ===
                "function"
            ) {

                resultado =
                    await Restaurant.excluir(
                        id
                    );

            } else if (
                typeof Restaurant.delete ===
                "function"
            ) {

                resultado =
                    await Restaurant.delete(
                        id
                    );

            } else if (
                typeof Restaurant.remover ===
                "function"
            ) {

                resultado =
                    await Restaurant.remover(
                        id
                    );

            } else {

                return res.status(
                    500
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            "O model Restaurant não possui método para excluir restaurante.",
                    }
                );
            }

            if (
                logo
            ) {

                removerArquivoLogo(
                    logo
                );
            }

            if (
                capa
            ) {

                removerArquivoCapa(
                    capa
                );
            }

            if (
                global.io
            ) {

                global.io.emit(
                    "restaurante_excluido",
                    {
                        id,
                    }
                );
            }

            return res.json(
                {
                    sucesso:
                        true,
                    mensagem:
                        "Restaurante excluído com sucesso.",
                    resultado,
                }
            );

        } catch (erro) {

            console.error(
                "❌ ERRO AO EXCLUIR RESTAURANTE:",
                erro
            );

            return res.status(
                500
            ).json(
                {
                    sucesso:
                        false,
                    mensagem:
                        erro.message ||
                        "Erro ao excluir restaurante.",
                }
            );
        }
    };

// ============================================================
// STATUS ONLINE / OFFLINE
// ============================================================

exports.updateStatus =
    async (
        req,
        res
    ) => {

        try {

            const id =
                String(
                    req.params.id ||
                        ""
                ).trim();

            const dados = {
                ...req.body,
            };

            if (
                dados.online !==
                undefined
            ) {

                dados.online =
                    dados.online ===
                        true ||
                    dados.online ===
                        "true" ||
                    dados.online ===
                        1 ||
                    dados.online ===
                        "1";
            }

            if (
                dados.aberto !==
                undefined
            ) {

                dados.aberto =
                    dados.aberto ===
                        true ||
                    dados.aberto ===
                        "true" ||
                    dados.aberto ===
                        1 ||
                    dados.aberto ===
                        "1";
            }

            if (
                dados.ativo !==
                undefined
            ) {

                dados.ativo =
                    dados.ativo ===
                        true ||
                    dados.ativo ===
                        "true" ||
                    dados.ativo ===
                        1 ||
                    dados.ativo ===
                        "1";
            }

            const atualizado =
                await Restaurant.atualizar(
                    id,
                    dados
                );

            if (!atualizado) {

                return res.status(
                    404
                ).json(
                    {
                        sucesso:
                            false,
                        mensagem:
                            "Restaurante não encontrado.",
                    }
                );
            }

            if (
                global.io
            ) {

                global.io.emit(
                    "restaurante_atualizado",
                    atualizado
                );
            }

            return res.json(
                {
                    sucesso:
                        true,
                    restaurante:
                        atualizado,
                }
            );

        } catch (erro) {

            console.error(
                "❌ ERRO AO ATUALIZAR STATUS:",
                erro
            );

            return res.status(
                500
            ).json(
                {
                    sucesso:
                        false,
                    mensagem:
                        erro.message ||
                        "Erro ao atualizar status.",
                }
            );
        }
    };