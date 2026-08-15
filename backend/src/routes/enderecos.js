```javascript
const express = require("express");

const router = express.Router();

const autenticar = require("../middlewares/authMiddleware");
const User = require("../models/user");


// ==================================================
// LISTAR ENDEREÇOS DO USUÁRIO
// GET /api/enderecos
// ==================================================

router.get("/", autenticar, async (req, res) => {

    try {

        const usuario =
            await User.buscarPorId(
                req.usuario.id
            );

        if (!usuario) {
            return res.status(404).json({
                erro: "Usuário não encontrado"
            });
        }

        return res.status(200).json({
            enderecos:
                usuario.enderecos || []
        });

    } catch (error) {

        console.error(
            "ERRO AO BUSCAR ENDEREÇOS:",
            error
        );

        return res.status(500).json({
            erro: "Erro interno"
        });
    }
});


// ==================================================
// ADICIONAR NOVO ENDEREÇO
// POST /api/enderecos
// ==================================================

router.post("/", autenticar, async (req, res) => {

    try {

        const {
            apelido,
            cep,
            logradouro,
            numero,
            complemento,
            bairro,
            cidade,
            estado,
            referencia
        } = req.body;


        // ================================
        // VALIDAÇÃO
        // ================================

        if (
            !cep ||
            !logradouro ||
            !numero ||
            !bairro ||
            !cidade ||
            !estado
        ) {

            return res.status(400).json({
                erro:
                    "CEP, endereço, número, bairro, cidade e estado são obrigatórios"
            });

        }


        // ================================
        // BUSCAR USUÁRIO
        // ================================

        const usuario =
            await User.buscarPorId(
                req.usuario.id
            );

        if (!usuario) {

            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });

        }


        // ================================
        // GARANTIR LISTA
        // ================================

        const enderecos =
            usuario.enderecos || [];


        // ================================
        // VERIFICAR SE É PRIMEIRO ENDEREÇO
        // ================================

        const primeiroEndereco =
            enderecos.length === 0;


        // ================================
        // CRIAR ENDEREÇO
        // ================================

        const novoEndereco = {

            id: Date.now(),

            apelido:
                apelido ||
                "Meu endereço",

            cep:
                cep
                    .toString()
                    .replace(/\D/g, ""),

            logradouro,

            numero,

            complemento:
                complemento || "",

            bairro,

            cidade,

            estado,

            referencia:
                referencia || "",

            principal:
                primeiroEndereco,

            criadoEm:
                new Date().toISOString()
        };


        // ================================
        // ADICIONAR ENDEREÇO
        // ================================

        enderecos.push(
            novoEndereco
        );


        // ================================
        // SALVAR
        // ================================

        const atualizado =
            await User.atualizarEnderecos(
                req.usuario.id,
                enderecos
            );


        if (!atualizado) {

            return res.status(500).json({
                erro:
                    "Não foi possível salvar o endereço"
            });

        }


        return res.status(201).json({

            mensagem:
                "Endereço adicionado com sucesso",

            endereco:
                novoEndereco

        });

    } catch (error) {

        console.error(
            "ERRO AO ADICIONAR ENDEREÇO:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno"
        });
    }
});


// ==================================================
// EDITAR ENDEREÇO
// PUT /api/enderecos/:id
// ==================================================

router.put("/:id", autenticar, async (req, res) => {

    try {

        const id =
            Number(req.params.id);

        const usuario =
            await User.buscarPorId(
                req.usuario.id
            );

        if (!usuario) {

            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });

        }


        const enderecos =
            usuario.enderecos || [];


        const index =
            enderecos.findIndex(
                endereco =>
                    endereco.id === id
            );


        if (index === -1) {

            return res.status(404).json({
                erro:
                    "Endereço não encontrado"
            });

        }


        // ================================
        // ATUALIZAR SOMENTE CAMPOS ENVIADOS
        // ================================

        const dados =
            req.body;


        if (dados.apelido !== undefined) {
            enderecos[index].apelido =
                dados.apelido;
        }

        if (dados.cep !== undefined) {
            enderecos[index].cep =
                dados.cep
                    .toString()
                    .replace(/\D/g, "");
        }

        if (dados.logradouro !== undefined) {
            enderecos[index].logradouro =
                dados.logradouro;
        }

        if (dados.numero !== undefined) {
            enderecos[index].numero =
                dados.numero;
        }

        if (dados.complemento !== undefined) {
            enderecos[index].complemento =
                dados.complemento;
        }

        if (dados.bairro !== undefined) {
            enderecos[index].bairro =
                dados.bairro;
        }

        if (dados.cidade !== undefined) {
            enderecos[index].cidade =
                dados.cidade;
        }

        if (dados.estado !== undefined) {
            enderecos[index].estado =
                dados.estado;
        }

        if (dados.referencia !== undefined) {
            enderecos[index].referencia =
                dados.referencia;
        }


        await User.atualizarEnderecos(
            req.usuario.id,
            enderecos
        );


        return res.status(200).json({

            mensagem:
                "Endereço atualizado com sucesso",

            endereco:
                enderecos[index]

        });

    } catch (error) {

        console.error(
            "ERRO AO EDITAR ENDEREÇO:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno"
        });
    }
});


// ==================================================
// EXCLUIR ENDEREÇO
// DELETE /api/enderecos/:id
// ==================================================

router.delete("/:id", autenticar, async (req, res) => {

    try {

        const id =
            Number(req.params.id);

        const usuario =
            await User.buscarPorId(
                req.usuario.id
            );

        if (!usuario) {

            return res.status(404).json({
                erro:
                    "Usuário não encontrado"
            });

        }


        let enderecos =
            usuario.enderecos || [];


        const endereco =
            enderecos.find(
                item =>
                    item.id === id
            );


        if (!endereco) {

            return res.status(404).json({
                erro:
                    "Endereço não encontrado"
            });

        }


        enderecos =
            enderecos.filter(
                item =>
                    item.id !== id
            );


        // ================================
        // SE EXCLUIU O PRINCIPAL,
        // DEFINE OUTRO COMO PRINCIPAL
        // ================================

        if (
            endereco.principal &&
            enderecos.length > 0
        ) {

            enderecos[0].principal =
                true;

        }


        await User.atualizarEnderecos(
            req.usuario.id,
            enderecos
        );


        return res.status(200).json({

            mensagem:
                "Endereço excluído com sucesso",

            enderecos

        });

    } catch (error) {

        console.error(
            "ERRO AO EXCLUIR ENDEREÇO:",
            error
        );

        return res.status(500).json({
            erro:
                "Erro interno"
        });
    }
});


// ==================================================
// DEFINIR ENDEREÇO PRINCIPAL
// PUT /api/enderecos/:id/principal
// ==================================================

router.put(
    "/:id/principal",
    autenticar,
    async (req, res) => {

        try {

            const id =
                Number(req.params.id);

            const usuario =
                await User.buscarPorId(
                    req.usuario.id
                );

            if (!usuario) {

                return res.status(404).json({
                    erro:
                        "Usuário não encontrado"
                });

            }


            const enderecos =
                usuario.enderecos || [];


            const existe =
                enderecos.some(
                    endereco =>
                        endereco.id === id
                );


            if (!existe) {

                return res.status(404).json({
                    erro:
                        "Endereço não encontrado"
                });

            }


            // ================================
            // ALTERAR PRINCIPAL
            // ================================

            enderecos.forEach(
                endereco => {

                    endereco.principal =
                        endereco.id === id;

                }
            );


            await User.atualizarEnderecos(
                req.usuario.id,
                enderecos
            );


            return res.status(200).json({

                mensagem:
                    "Endereço principal atualizado",

                enderecos

            });

        } catch (error) {

            console.error(
                "ERRO AO DEFINIR ENDEREÇO PRINCIPAL:",
                error
            );

            return res.status(500).json({
                erro:
                    "Erro interno"
            });
        }
    }
);


module.exports = router;
```
