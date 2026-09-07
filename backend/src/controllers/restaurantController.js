const Restaurant = require("../models/restaurant");

const fs = require("fs");
const path = require("path");
const multer = require("multer");

// ==================================================
// PASTAS DE IMAGENS
// ==================================================

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

// ==================================================
// CRIAR PASTAS
// ==================================================

if (!fs.existsSync(pastaUploads)) {
    fs.mkdirSync(
        pastaUploads,
        {
            recursive: true
        }
    );
}

if (!fs.existsSync(pastaCapas)) {
    fs.mkdirSync(
        pastaCapas,
        {
            recursive: true
        }
    );
}

if (!fs.existsSync(pastaLogos)) {
    fs.mkdirSync(
        pastaLogos,
        {
            recursive: true
        }
    );
}

console.log("========================================");
console.log("📁 PASTAS DE IMAGENS");
console.log("UPLOADS:", pastaUploads);
console.log("CAPAS:", pastaCapas);
console.log("LOGOS:", pastaLogos);
console.log("========================================");

// ==================================================
// AUXILIAR - LIMPAR ID
// ==================================================

function limparId(id) {
    return String(
        id || "restaurante"
    ).replace(
        /[^a-zA-Z0-9_-]/g,
        ""
    );
}

// ==================================================
// AUXILIAR - REMOVER ARQUIVO DE CAPA
// ==================================================

function removerArquivoCapa(capa) {

    if (
        !capa ||
        typeof capa !== "string"
    ) {
        return;
    }

    if (
        !capa.startsWith(
            "/uploads/capas/"
        )
    ) {
        return;
    }

    const nomeArquivo =
        path.basename(capa);

    const arquivo =
        path.join(
            pastaCapas,
            nomeArquivo
        );

    try {

        if (
            fs.existsSync(
                arquivo
            )
        ) {

            fs.unlinkSync(
                arquivo
            );

            console.log(
                "🗑️ Arquivo de capa removido:",
                nomeArquivo
            );
        }

    } catch (error) {

        console.warn(
            "⚠️ Não foi possível remover capa:",
            error.message
        );
    }
}

// ==================================================
// AUXILIAR - REMOVER ARQUIVO DE LOGO
// ==================================================

function removerArquivoLogo(logo) {

    if (
        !logo ||
        typeof logo !== "string"
    ) {
        return;
    }

    if (
        !logo.startsWith(
            "/uploads/logos/"
        )
    ) {
        return;
    }

    const nomeArquivo =
        path.basename(logo);

    const arquivo =
        path.join(
            pastaLogos,
            nomeArquivo
        );

    try {

        if (
            fs.existsSync(
                arquivo
            )
        ) {

            fs.unlinkSync(
                arquivo
            );

            console.log(
                "🗑️ Arquivo de logo removido:",
                nomeArquivo
            );
        }

    } catch (error) {

        console.warn(
            "⚠️ Não foi possível remover logo:",
            error.message
        );
    }
}

// ==================================================
// SALVAR LOGO BASE64
// ==================================================

function salvarLogoBase64(
    imagem,
    restauranteId
) {

    if (
        typeof imagem !== "string"
    ) {
        return null;
    }

    const valor =
        imagem.trim();

    if (
        !valor.startsWith(
            "data:image/"
        )
    ) {
        return null;
    }

    // ==================================================
    // SEPARAR CABEÇALHO E BASE64
    // ==================================================

    const partes =
        valor.split(",");

    if (
        partes.length !== 2
    ) {
        throw new Error(
            "Imagem do logo Base64 inválida."
        );
    }

    const cabecalho =
        partes[0];

    const base64 =
        partes[1];

    if (
        !base64 ||
        base64.trim() === ""
    ) {
        throw new Error(
            "Conteúdo Base64 do logo vazio."
        );
    }

    // ==================================================
    // IDENTIFICAR MIME
    // ==================================================

    const mimeMatch =
        cabecalho.match(
            /^data:(image\/[a-zA-Z0-9.+-]+);base64$/i
        );

    if (
        !mimeMatch
    ) {
        throw new Error(
            "Formato Base64 do logo inválido."
        );
    }

    const mime =
        mimeMatch[1].toLowerCase();

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

    // ==================================================
    // DECODIFICAR BASE64
    // ==================================================

    let buffer;

    try {

        buffer =
            Buffer.from(
                base64,
                "base64"
            );

    } catch (error) {

        throw new Error(
            "Não foi possível decodificar o logo."
        );
    }

    // ==================================================
    // VALIDAR TAMANHO
    // ==================================================

    if (
        buffer.length >
        5 * 1024 * 1024
    ) {
        throw new Error(
            "A imagem do logo deve ter no máximo 5 MB."
        );
    }

    if (
        buffer.length === 0
    ) {
        throw new Error(
            "O arquivo do logo está vazio."
        );
    }

    // ==================================================
    // NOME DO ARQUIVO
    // ==================================================

    const idLimpo =
        limparId(
            restauranteId
        );

    const nomeArquivo =
        `logo_${idLimpo}_${Date.now()}${extensao}`;

    const caminhoArquivo =
        path.join(
            pastaLogos,
            nomeArquivo
        );

    // ==================================================
    // SALVAR ARQUIVO
    // ==================================================

    fs.writeFileSync(
        caminhoArquivo,
        buffer
    );

    console.log(
        "========================================"
    );

    console.log(
        "🖼️ LOGO BASE64 CONVERTIDO"
    );

    console.log(
        "📁 Arquivo:",
        nomeArquivo
    );

    console.log(
        "📦 MIME:",
        mime
    );

    console.log(
        "📏 Tamanho:",
        buffer.length,
        "bytes"
    );

    console.log(
        "📍 Caminho:",
        `/uploads/logos/${nomeArquivo}`
    );

    console.log(
        "💾 Arquivo existe:",
        fs.existsSync(caminhoArquivo)
    );

    console.log(
        "========================================"
    );

    return `/uploads/logos/${nomeArquivo}`;
}

// ==================================================
// MIGRAR LOGO BASE64 ANTIGO
// ==================================================

async function migrarLogoBase64(
    restaurante
) {

    if (
        !restaurante
    ) {
        return restaurante;
    }

    let imagem =
        restaurante.imagem;

    // ==================================================
    // PROCURAR DENTRO DO JSONB
    // ==================================================

    if (
        !imagem &&
        restaurante.dados &&
        typeof restaurante.dados === "object"
    ) {

        imagem =
            restaurante.dados.imagem;
    }

    if (
        typeof imagem !== "string"
    ) {
        return restaurante;
    }

    imagem =
        imagem.trim();

    if (
        !imagem.startsWith(
            "data:image/"
        )
    ) {
        return restaurante;
    }

    console.log(
        "========================================"
    );

    console.log(
        "🔄 LOGO ANTIGO BASE64 ENCONTRADO"
    );

    console.log(
        "RESTAURANTE:",
        restaurante.id
    );

    console.log(
        "📦 Convertendo Base64 para arquivo..."
    );

    console.log(
        "========================================"
    );

    try {

        const logoUrl =
            salvarLogoBase64(
                imagem,
                restaurante.id
            );

        if (
            !logoUrl
        ) {
            return restaurante;
        }

        const logoAntigo =
            restaurante.logo;

        const atualizado =
            await Restaurant.atualizar(
                restaurante.id,
                {
                    logo: logoUrl,
                    imagem: null
                }
            );

        if (
            atualizado
        ) {

            if (
                logoAntigo &&
                logoAntigo !== logoUrl
            ) {
                removerArquivoLogo(
                    logoAntigo
                );
            }

            console.log(
                "✅ LOGO ANTIGO MIGRADO PARA:",
                logoUrl
            );

            return atualizado;
        }

    } catch (error) {

        console.error(
            "❌ ERRO AO MIGRAR LOGO BASE64:",
            error.message
        );
    }

    return restaurante;
}

// ==================================================
// MULTER - CAPA
// ==================================================

const storageCapa =
    multer.diskStorage({

        destination: (
            req,
            file,
            cb
        ) => {

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

            const restauranteId =
                limparId(
                    req.params.id
                );

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
                    ".webp"
                ].includes(
                    extensao
                )
            ) {
                extensao = ".jpg";
            }

            const nomeArquivo =
                `capa_${restauranteId}_${Date.now()}${extensao}`;

            console.log(
                "📁 Nome final da capa:",
                nomeArquivo
            );

            cb(
                null,
                nomeArquivo
            );
        }
    });

// ==================================================
// MULTER - LOGO
// ==================================================

const storageLogo =
    multer.diskStorage({

        destination: (
            req,
            file,
            cb
        ) => {

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

            const restauranteId =
                limparId(
                    req.params.id
                );

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
                    ".webp"
                ].includes(
                    extensao
                )
            ) {
                extensao = ".jpg";
            }

            const nomeArquivo =
                `logo_${restauranteId}_${Date.now()}${extensao}`;

            console.log(
                "📁 Nome final da logo:",
                nomeArquivo
            );

            cb(
                null,
                nomeArquivo
            );
        }
    });

// ==================================================
// FILTRO DE IMAGEM
// ==================================================

function filtroImagem(
    req,
    file,
    cb
) {

    const tiposPermitidos = [
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "image/x-png"
    ];

    const extensoesPermitidas = [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ];

    const mime =
        String(
            file.mimetype || ""
        )
            .trim()
            .toLowerCase();

    const nomeArquivo =
        String(
            file.originalname || ""
        )
            .trim()
            .toLowerCase();

    const extensao =
        path.extname(
            nomeArquivo
        );

    const mimePermitido =
        tiposPermitidos.includes(
            mime
        );

    const extensaoPermitida =
        extensoesPermitidas.includes(
            extensao
        );

    if (
        mimePermitido ||
        extensaoPermitida
    ) {

        cb(
            null,
            true
        );

        return;
    }

    cb(
        new Error(
            "Formato de imagem não permitido. Use JPG, PNG ou WEBP."
        )
    );
}

// ==================================================
// MULTER CAPA
// ==================================================

const uploadCapaMulter =
    multer({

        storage:
            storageCapa,

        limits: {
            fileSize:
                5 * 1024 * 1024
        },

        fileFilter:
            filtroImagem
    });

// ==================================================
// MULTER LOGO
// ==================================================

const uploadLogoMulter =
    multer({

        storage:
            storageLogo,

        limits: {
            fileSize:
                5 * 1024 * 1024
        },

        fileFilter:
            filtroImagem
    });

// ==================================================
// UPLOAD DA CAPA
// POST /api/restaurants/:id/capa
// ==================================================

exports.uploadCapa = [

    (
        req,
        res,
        next
    ) => {

        uploadCapaMulter.single(
            "capa"
        )(
            req,
            res,
            (
                error
            ) => {

                if (
                    !error
                ) {

                    console.log(
                        "✅ MULTER CAPA FINALIZADO"
                    );

                    return next();
                }

                console.error(
                    "❌ ERRO DO MULTER CAPA:",
                    error.message
                );

                if (
                    error.code ===
                    "LIMIT_FILE_SIZE"
                ) {

                    return res.status(400).json({
                        sucesso: false,
                        erro:
                            "A imagem da capa deve ter no máximo 5 MB."
                    });
                }

                return res.status(400).json({
                    sucesso: false,
                    erro:
                        error.message ||
                        "Erro ao processar a imagem da capa."
                });
            }
        );
    },

    async (
        req,
        res
    ) => {

        let capaUrl = null;

        try {

            const {
                id
            } = req.params;

            if (
                !id ||
                String(id).trim() === ""
            ) {

                return res.status(400).json({
                    sucesso: false,
                    erro:
                        "ID do restaurante é obrigatório"
                });
            }

            if (
                !req.file
            ) {

                return res.status(400).json({
                    sucesso: false,
                    erro:
                        "Nenhuma imagem de capa foi enviada"
                });
            }

            console.log(
                "========================================"
            );

            console.log(
                "🖼️ FOODJET - UPLOAD DE CAPA"
            );

            console.log(
                "RESTAURANTE:",
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
                "ARQUIVO EXISTE:",
                fs.existsSync(
                    req.file.path
                )
            );

            console.log(
                "========================================"
            );

            const restaurante =
                await Restaurant.buscarPorId(
                    id
                );

            if (
                !restaurante
            ) {

                removerArquivoCapa(
                    `/uploads/capas/${req.file.filename}`
                );

                return res.status(404).json({
                    sucesso: false,
                    erro:
                        "Restaurante não encontrado"
                });
            }

            const capaAntiga =
                restaurante.capa;

            capaUrl =
                `/uploads/capas/${req.file.filename}`;

            const restauranteAtualizado =
                await Restaurant.atualizar(
                    id,
                    {
                        capa:
                            capaUrl
                    }
                );

            if (
                !restauranteAtualizado
            ) {

                removerArquivoCapa(
                    capaUrl
                );

                return res.status(404).json({
                    sucesso: false,
                    erro:
                        "Restaurante não encontrado"
                });
            }

            if (
                capaAntiga &&
                capaAntiga !== capaUrl
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
                    restauranteAtualizado
                );
            }

            return res.status(200).json({
                sucesso: true,
                mensagem:
                    "Capa do restaurante enviada com sucesso",
                capa:
                    capaUrl,
                restaurante:
                    restauranteAtualizado
            });

        } catch (error) {

            console.error(
                "❌ ERRO AO ENVIAR CAPA:",
                error
            );

            if (
                req.file
            ) {

                removerArquivoCapa(
                    capaUrl ||
                    `/uploads/capas/${req.file.filename}`
                );
            }

            if (
                !res.headersSent
            ) {

                return res.status(500).json({
                    sucesso: false,
                    erro:
                        error.message ||
                        "Erro ao enviar capa"
                });
            }
        }
    }
];

// ==================================================
// REMOVER CAPA
// DELETE /api/restaurants/:id/capa
// ==================================================

exports.deleteCapa = async (
    req,
    res
) => {

    try {

        const {
            id
        } = req.params;

        const restaurante =
            await Restaurant.buscarPorId(
                id
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        const capaAntiga =
            restaurante.capa;

        const restauranteAtualizado =
            await Restaurant.atualizar(
                id,
                {
                    capa: null
                }
            );

        if (
            !restauranteAtualizado
        ) {

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
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
                restauranteAtualizado
            );
        }

        return res.json({
            sucesso: true,
            mensagem:
                "Capa removida com sucesso",
            capa: null,
            restaurante:
                restauranteAtualizado
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO REMOVER CAPA:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao remover capa",
            detalhe:
                error.message
        });
    }
};

// ==================================================
// UPLOAD DA LOGO
// POST /api/restaurants/:id/logo
// ==================================================

exports.uploadLogo = [

    (
        req,
        res,
        next
    ) => {

        uploadLogoMulter.single(
            "logo"
        )(
            req,
            res,
            (
                error
            ) => {

                if (
                    !error
                ) {

                    console.log(
                        "✅ MULTER LOGO FINALIZADO"
                    );

                    return next();
                }

                console.error(
                    "❌ ERRO DO MULTER LOGO:",
                    error.message
                );

                if (
                    error.code ===
                    "LIMIT_FILE_SIZE"
                ) {

                    return res.status(400).json({
                        sucesso: false,
                        erro:
                            "A imagem da logo deve ter no máximo 5 MB."
                    });
                }

                return res.status(400).json({
                    sucesso: false,
                    erro:
                        error.message ||
                        "Erro ao processar a imagem da logo."
                });
            }
        );
    },

    async (
        req,
        res
    ) => {

        let logoUrl = null;

        try {

            const {
                id
            } = req.params;

            if (
                !id ||
                String(id).trim() === ""
            ) {

                return res.status(400).json({
                    sucesso: false,
                    erro:
                        "ID do restaurante é obrigatório"
                });
            }

            if (
                !req.file
            ) {

                return res.status(400).json({
                    sucesso: false,
                    erro:
                        "Nenhuma imagem de logo foi enviada"
                });
            }

            console.log(
                "========================================"
            );

            console.log(
                "🟠 FOODJET - UPLOAD DE LOGO"
            );

            console.log(
                "RESTAURANTE:",
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
                "ARQUIVO EXISTE:",
                fs.existsSync(
                    req.file.path
                )
            );

            console.log(
                "========================================"
            );

            const restaurante =
                await Restaurant.buscarPorId(
                    id
                );

            if (
                !restaurante
            ) {

                removerArquivoLogo(
                    `/uploads/logos/${req.file.filename}`
                );

                return res.status(404).json({
                    sucesso: false,
                    erro:
                        "Restaurante não encontrado"
                });
            }

            const logoAntiga =
                restaurante.logo;

            logoUrl =
                `/uploads/logos/${req.file.filename}`;

            console.log(
                "💾 SALVANDO LOGO NO POSTGRESQL:"
            );

            console.log(
                logoUrl
            );

            const restauranteAtualizado =
                await Restaurant.atualizar(
                    id,
                    {
                        logo:
                            logoUrl,
                        imagem:
                            null
                    }
                );

            if (
                !restauranteAtualizado
            ) {

                removerArquivoLogo(
                    logoUrl
                );

                return res.status(404).json({
                    sucesso: false,
                    erro:
                        "Restaurante não encontrado"
                });
            }

            if (
                logoAntiga &&
                logoAntiga !== logoUrl
            ) {

                removerArquivoLogo(
                    logoAntiga
                );
            }

            console.log(
                "========================================"
            );

            console.log(
                "✅ LOGO SALVA COM SUCESSO"
            );

            console.log(
                "LOGO:",
                logoUrl
            );

            console.log(
                "ARQUIVO EXISTE:",
                fs.existsSync(
                    path.join(
                        pastaLogos,
                        req.file.filename
                    )
                )
            );

            console.log(
                "========================================"
            );

            if (
                global.io
            ) {

                global.io.emit(
                    "restaurante_atualizado",
                    restauranteAtualizado
                );
            }

            return res.status(200).json({
                sucesso: true,
                mensagem:
                    "Logo do restaurante enviada com sucesso",
                logo:
                    logoUrl,
                restaurante:
                    restauranteAtualizado
            });

        } catch (error) {

            console.error(
                "❌ ERRO AO ENVIAR LOGO:",
                error
            );

            if (
                logoUrl
            ) {

                removerArquivoLogo(
                    logoUrl
                );
            }

            if (
                !res.headersSent
            ) {

                return res.status(500).json({
                    sucesso: false,
                    erro:
                        error.message ||
                        "Erro ao enviar logo",
                    detalhe:
                        error.message
                });
            }
        }
    }
];

// ==================================================
// REMOVER LOGO
// DELETE /api/restaurants/:id/logo
// ==================================================

exports.deleteLogo = async (
    req,
    res
) => {

    try {

        const {
            id
        } = req.params;

        console.log(
            "========================================"
        );

        console.log(
            "🗑️ FOODJET - REMOVER LOGO"
        );

        console.log(
            "RESTAURANTE:",
            id
        );

        console.log(
            "========================================"
        );

        const restaurante =
            await Restaurant.buscarPorId(
                id
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        const logoAntiga =
            restaurante.logo;

        const restauranteAtualizado =
            await Restaurant.atualizar(
                id,
                {
                    logo: null,
                    imagem: null
                }
            );

        if (
            !restauranteAtualizado
        ) {

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        if (
            logoAntiga
        ) {

            removerArquivoLogo(
                logoAntiga
            );
        }

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_atualizado",
                restauranteAtualizado
            );
        }

        return res.json({
            sucesso: true,
            mensagem:
                "Logo removida com sucesso",
            logo: null,
            restaurante:
                restauranteAtualizado
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO REMOVER LOGO:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao remover logo",
            detalhe:
                error.message
        });
    }
};

// ==================================================
// CRIAR RESTAURANTE
// ==================================================

exports.create = async (
    req,
    res
) => {

    try {

        const restaurante = {

            id:
                Date.now(),

            nome:
                req.body.nome || "",

            categoria:
                req.body.categoria || "",

            descricao:
                req.body.descricao || "",

            telefone:
                req.body.telefone || "",

            endereco:
                req.body.endereco || "",

            taxaEntrega:
                Number(
                    req.body.taxaEntrega
                ) || 0,

            tempoEntrega:
                req.body.tempoEntrega || "",

            capa:
                req.body.capa || null,

            logo:
                req.body.logo || null,

            status:
                "ABERTO",

            online:
                true,

            aberto:
                true,

            aceitarAutomatico:
                req.body.aceitarAutomatico !== false,

            criadoEm:
                new Date().toISOString()
        };

        // ==================================================
        // LOGO BASE64 NO CREATE
        // ==================================================

        if (
            typeof req.body.imagem === "string" &&
            req.body.imagem.startsWith(
                "data:image/"
            )
        ) {

            const logoUrl =
                salvarLogoBase64(
                    req.body.imagem,
                    restaurante.id
                );

            restaurante.logo =
                logoUrl;

            restaurante.imagem =
                null;
        }

        await Restaurant.criar(
            restaurante
        );

        return res.status(201).json({
            sucesso: true,
            mensagem:
                "Restaurante cadastrado com sucesso",
            restaurante
        });

    } catch (error) {

        console.error(
            "ERRO CREATE RESTAURANTE:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao cadastrar restaurante",
            detalhe:
                error.message
        });
    }
};

// ==================================================
// LISTAR RESTAURANTES
// ==================================================

exports.list = async (
    req,
    res
) => {

    try {

        let lista =
            await Restaurant.listar();

        if (
            !Array.isArray(lista)
        ) {
            lista = [];
        }

        // ==================================================
        // MIGRAR LOGOS ANTIGOS
        // ==================================================

        for (
            let i = 0;
            i < lista.length;
            i++
        ) {

            try {

                lista[i] =
                    await migrarLogoBase64(
                        lista[i]
                    );

            } catch (error) {

                console.error(
                    "⚠️ Erro ao migrar logo:",
                    error.message
                );
            }
        }

        // ==================================================
        // PROMOÇÕES
        // ==================================================

        let promocoes = [];

        try {

            const Promotion =
                require(
                    "../models/promotion"
                );

            promocoes =
                await Promotion.listar();

            if (
                !Array.isArray(
                    promocoes
                )
            ) {
                promocoes = [];
            }

        } catch (error) {

            console.log(
                "ℹ️ Sem promoções carregadas:",
                error.message
            );

            promocoes = [];
        }

        const agora =
            new Date();

        lista =
            lista.map(
                (
                    restaurante
                ) => {

                    let prioridade = 0;
                    let destaque = false;
                    let tipoDestaque = null;
                    let promocao = null;

                    const promocaoEncontrada =
                        promocoes.find(
                            (
                                p
                            ) =>
                                String(
                                    p.restauranteId
                                ) ===
                                String(
                                    restaurante.id
                                ) &&
                                p.ativa === true
                        );

                    if (
                        promocaoEncontrada
                    ) {

                        let valida = true;

                        if (
                            promocaoEncontrada.expiraEm
                        ) {

                            const validade =
                                new Date(
                                    promocaoEncontrada.expiraEm
                                );

                            if (
                                Number.isNaN(
                                    validade.getTime()
                                )
                            ) {

                                valida = false;

                            } else if (
                                validade <= agora
                            ) {

                                valida = false;
                            }
                        }

                        if (
                            valida
                        ) {

                            promocao =
                                promocaoEncontrada;

                            destaque =
                                true;

                            tipoDestaque =
                                promocaoEncontrada.tipo;

                            if (
                                tipoDestaque ===
                                "TOP1"
                            ) {

                                prioridade = 3;

                            } else if (
                                tipoDestaque ===
                                "DESTAQUE"
                            ) {

                                prioridade = 2;

                            } else if (
                                tipoDestaque ===
                                "IMPULSO"
                            ) {

                                prioridade = 1;
                            }
                        }
                    }

                    return {

                        ...restaurante,

                        promocao,

                        destaque,

                        tipoDestaque,

                        prioridade,

                        selo:
                            destaque
                                ? "Patrocinado FoodJet"
                                : null
                    };
                }
            );

        lista.sort(
            (
                a,
                b
            ) =>
                b.prioridade -
                a.prioridade
        );

        return res.json(
            lista
        );

    } catch (error) {

        console.error(
            "ERRO LISTAR RESTAURANTES:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro ao listar restaurantes",
            detalhe:
                error.message
        });
    }
};

// ==================================================
// BUSCAR RESTAURANTE POR ID
// ==================================================

exports.getById = async (
    req,
    res
) => {

    try {

        let restaurante =
            await Restaurant.buscarPorId(
                req.params.id
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({
                sucesso: false,
                mensagem:
                    "Restaurante não encontrado."
            });
        }

        // ==================================================
        // MIGRAR BASE64 ANTIGO
        // ==================================================

        restaurante =
            await migrarLogoBase64(
                restaurante
            );

        const resposta = {
            ...restaurante
        };

        // ==================================================
        // JSONB DADOS
        // ==================================================

        let dadosInternos =
            restaurante.dados;

        if (
            typeof dadosInternos === "string"
        ) {

            try {

                dadosInternos =
                    JSON.parse(
                        dadosInternos
                    );

            } catch (error) {

                dadosInternos = null;
            }
        }

        if (
            dadosInternos &&
            typeof dadosInternos === "object"
        ) {

            if (
                !resposta.logo &&
                dadosInternos.logo
            ) {

                resposta.logo =
                    dadosInternos.logo;
            }

            if (
                !resposta.capa &&
                dadosInternos.capa
            ) {

                resposta.capa =
                    dadosInternos.capa;
            }
        }

        // ==================================================
        // NORMALIZAR LOGO
        // ==================================================

        if (
            resposta.logo &&
            typeof resposta.logo === "string"
        ) {

            const logo =
                resposta.logo.trim();

            if (
                logo.startsWith(
                    "/uploads/"
                )
            ) {

                resposta.logo =
                    logo;

            } else if (
                logo.startsWith(
                    "http://"
                ) ||
                logo.startsWith(
                    "https://"
                )
            ) {

                resposta.logo =
                    logo;

            } else {

                resposta.logo =
                    `/uploads/logos/${logo}`;
            }
        }

        // ==================================================
        // NORMALIZAR CAPA
        // ==================================================

        if (
            resposta.capa &&
            typeof resposta.capa === "string"
        ) {

            const capa =
                resposta.capa.trim();

            if (
                capa.startsWith(
                    "/uploads/"
                )
            ) {

                resposta.capa =
                    capa;

            } else if (
                capa.startsWith(
                    "http://"
                ) ||
                capa.startsWith(
                    "https://"
                )
            ) {

                resposta.capa =
                    capa;

            } else {

                resposta.capa =
                    `/uploads/capas/${capa}`;
            }
        }

        // ==================================================
        // NUNCA DEVOLVER BASE64
        // ==================================================

        if (
            typeof resposta.imagem === "string" &&
            resposta.imagem.startsWith(
                "data:image/"
            )
        ) {

            resposta.imagem =
                null;
        }

        if (
            resposta.logo &&
            typeof resposta.logo === "string" &&
            resposta.logo.startsWith(
                "data:image/"
            )
        ) {

            resposta.logo =
                null;
        }

        console.log(
            "========================================"
        );

        console.log(
            "🏪 RESTAURANTE"
        );

        console.log(
            "ID:",
            resposta.id
        );

        console.log(
            "NOME:",
            resposta.nome
        );

        console.log(
            "LOGO:",
            resposta.logo
        );

        console.log(
            "CAPA:",
            resposta.capa
        );

        console.log(
            "========================================"
        );

        return res.json({
            sucesso: true,
            restaurante:
                resposta
        });

    } catch (error) {

        console.error(
            "ERRO GET RESTAURANTE:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            mensagem:
                "Erro ao buscar restaurante.",
            detalhe:
                error.message
        });
    }
};

// ==================================================
// ATUALIZAR RESTAURANTE
// PUT /api/restaurants/:id
// ==================================================

exports.update = async (
    req,
    res
) => {

    let logoNovo = null;

    try {

        const {
            id
        } = req.params;

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "ID do restaurante é obrigatório"
            });
        }

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

        // ==================================================
        // BUSCAR ATUAL
        // ==================================================

        const restauranteAtual =
            await Restaurant.buscarPorId(
                id
            );

        if (
            !restauranteAtual
        ) {

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        // ==================================================
        // COPIAR BODY
        // ==================================================

        const dados = {
            ...req.body
        };

        // ==================================================
        // LOG SEGURO
        // ==================================================

        const dadosLog = {
            ...dados
        };

        if (
            typeof dadosLog.imagem === "string" &&
            dadosLog.imagem.startsWith(
                "data:image/"
            )
        ) {

            dadosLog.imagem =
                `[BASE64 REMOVIDO - ${dadosLog.imagem.length} caracteres]`;
        }

        if (
            typeof dadosLog.logo === "string" &&
            dadosLog.logo.startsWith(
                "data:image/"
            )
        ) {

            dadosLog.logo =
                `[BASE64 REMOVIDO - ${dadosLog.logo.length} caracteres]`;
        }

        console.log(
            "DADOS:",
            dadosLog
        );

        // ==================================================
        // VERIFICAR LOGO
        // ==================================================

        const imagemRecebida =
            typeof dados.imagem === "string"
                ? dados.imagem.trim()
                : "";

        const logoRecebido =
            typeof dados.logo === "string"
                ? dados.logo.trim()
                : "";

        let logoBase64 = null;

        if (
            imagemRecebida.startsWith(
                "data:image/"
            )
        ) {

            logoBase64 =
                imagemRecebida;

            console.log(
                "🖼️ LOGO RECEBIDO NO CAMPO: imagem"
            );

        } else if (
            logoRecebido.startsWith(
                "data:image/"
            )
        ) {

            logoBase64 =
                logoRecebido;

            console.log(
                "🖼️ LOGO RECEBIDO NO CAMPO: logo"
            );
        }

        // ==================================================
        // CONVERTER BASE64
        // ==================================================

        if (
            logoBase64
        ) {

            console.log(
                "🔄 Convertendo logo Base64..."
            );

            logoNovo =
                salvarLogoBase64(
                    logoBase64,
                    id
                );

            dados.logo =
                logoNovo;

            dados.imagem =
                null;

            console.log(
                "✅ LOGO SALVO EM:",
                logoNovo
            );

            console.log(
                "🚫 Base64 NÃO será salvo"
            );

        } else {

            // ==================================================
            // IMAGEM JÁ É CAMINHO
            // ==================================================

            if (
                imagemRecebida
            ) {

                if (
                    imagemRecebida.startsWith(
                        "/uploads/logos/"
                    ) ||
                    imagemRecebida.startsWith(
                        "http://"
                    ) ||
                    imagemRecebida.startsWith(
                        "https://"
                    )
                ) {

                    dados.logo =
                        imagemRecebida;

                    dados.imagem =
                        null;
                }
            }
        }

        // ==================================================
        // ATUALIZAR POSTGRESQL
        // ==================================================

        const restaurante =
            await Restaurant.atualizar(
                id,
                dados
            );

        if (
            !restaurante
        ) {

            if (
                logoNovo
            ) {

                removerArquivoLogo(
                    logoNovo
                );
            }

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        // ==================================================
        // REMOVER LOGO ANTIGA
        // ==================================================

        if (
            logoNovo
        ) {

            let logoAntigo =
                restauranteAtual.logo;

            if (
                !logoAntigo &&
                restauranteAtual.dados &&
                typeof restauranteAtual.dados === "object"
            ) {

                logoAntigo =
                    restauranteAtual.dados.logo;
            }

            if (
                logoAntigo &&
                logoAntigo !== logoNovo
            ) {

                removerArquivoLogo(
                    logoAntigo
                );
            }
        }

        // ==================================================
        // RESPOSTA
        // ==================================================

        const resposta = {
            ...restaurante
        };

        if (
            resposta.logo &&
            typeof resposta.logo === "string" &&
            resposta.logo.startsWith(
                "data:image/"
            )
        ) {

            resposta.logo =
                logoNovo;
        }

        if (
            resposta.imagem &&
            typeof resposta.imagem === "string" &&
            resposta.imagem.startsWith(
                "data:image/"
            )
        ) {

            resposta.imagem =
                null;
        }

        console.log(
            "========================================"
        );

        console.log(
            "✅ RESTAURANTE ATUALIZADO"
        );

        console.log(
            "ID:",
            id
        );

        console.log(
            "LOGO:",
            resposta.logo
        );

        console.log(
            "CAPA:",
            resposta.capa
        );

        console.log(
            "========================================"
        );

        // ==================================================
        // SOCKET.IO
        // ==================================================

        try {

            if (
                global.io
            ) {

                global.io.emit(
                    "restaurante_atualizado",
                    resposta
                );

                console.log(
                    "📡 RESTAURANTE ATUALIZADO ENVIADO AOS CLIENTES"
                );
            }

        } catch (socketError) {

            console.error(
                "⚠️ Erro Socket.IO:",
                socketError.message
            );
        }

        return res.json({
            sucesso: true,
            mensagem:
                "Restaurante atualizado com sucesso",
            restaurante:
                resposta
        });

    } catch (error) {

        console.error(
            "========================================"
        );

        console.error(
            "❌ ERRO AO ATUALIZAR RESTAURANTE"
        );

        console.error(
            error
        );

        console.error(
            "========================================"
        );

        if (
            logoNovo
        ) {

            removerArquivoLogo(
                logoNovo
            );
        }

        return res.status(500).json({
            sucesso: false,
            erro:
                error.message ||
                "Erro ao atualizar restaurante",
            detalhe:
                error.message
        });
    }
};

// ==================================================
// EXCLUIR RESTAURANTE
// DELETE /api/restaurants/:id
// ==================================================

exports.delete = async (
    req,
    res
) => {

    try {

        const {
            id
        } = req.params;

        const restaurante =
            await Restaurant.buscarPorId(
                id
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        const capa =
            restaurante.capa;

        const logo =
            restaurante.logo;

        const resultado =
            await Restaurant.excluir(
                id
            );

        if (
            !resultado ||
            resultado.sucesso !== true
        ) {

            return res.status(500).json({
                sucesso: false,
                erro:
                    "Não foi possível excluir a conta do restaurante"
            });
        }

        // ==================================================
        // REMOVER CAPA
        // ==================================================

        if (
            capa
        ) {

            removerArquivoCapa(
                capa
            );
        }

        // ==================================================
        // REMOVER LOGO
        // ==================================================

        if (
            logo
        ) {

            removerArquivoLogo(
                logo
            );
        }

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_excluido",
                {
                    restauranteId:
                        String(id)
                }
            );
        }

        return res.status(200).json({
            sucesso: true,
            mensagem:
                "Conta e dados vinculados ao restaurante foram excluídos com sucesso",
            restauranteId:
                String(id),
            removidos:
                resultado.removidos
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO EXCLUIR RESTAURANTE:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro:
                "Erro interno ao excluir a conta do restaurante",
            detalhe:
                error.message
        });
    }
};

// ==================================================
// ONLINE / OFFLINE
// PUT /api/restaurants/:id/status
// ==================================================

exports.updateStatus = async (
    req,
    res
) => {

    try {

        const {
            id
        } = req.params;

        if (
            !id ||
            String(id).trim() === ""
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "ID do restaurante é obrigatório"
            });
        }

        const dados = {};

        if (
            req.body.online !== undefined
        ) {

            dados.online =
                req.body.online === true ||
                req.body.online === "true";
        }

        if (
            req.body.aberto !== undefined
        ) {

            dados.aberto =
                req.body.aberto === true ||
                req.body.aberto === "true";
        }

        if (
            req.body.status !== undefined
        ) {

            dados.status =
                req.body.status;
        }

        if (
            Object.keys(
                dados
            ).length === 0
        ) {

            return res.status(400).json({
                sucesso: false,
                erro:
                    "Nenhum status foi informado"
            });
        }

        const restaurante =
            await Restaurant.atualizar(
                id,
                dados
            );

        if (
            !restaurante
        ) {

            return res.status(404).json({
                sucesso: false,
                erro:
                    "Restaurante não encontrado"
            });
        }

        if (
            global.io
        ) {

            global.io.emit(
                "restaurante_atualizado",
                restaurante
            );
        }

        return res.json({
            sucesso: true,
            mensagem:
                "Status do restaurante atualizado com sucesso",
            restaurante
        });

    } catch (error) {

        console.error(
            "❌ ERRO AO ALTERAR STATUS:",
            error
        );

        return res.status(500).json({
            sucesso: false,
            erro:
                "Erro ao alterar status do restaurante",
            detalhe:
                error.message
        });
    }
};