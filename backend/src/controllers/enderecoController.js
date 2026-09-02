
const User = require("../models/user");

// ==========================================
// GERAR ID DO ENDEREÇO
// ==========================================

function gerarId() {
    return Date.now();
}


// ==========================================
// LISTAR ENDEREÇOS DO USUÁRIO
// ==========================================

exports.listarEnderecos = async (req, res) => {
    try {
        const usuario = await User.buscarPorId(req.usuario.id);

        if (!usuario) {
            return res.status(404).json({
                erro: "Usuário não encontrado"
            });
        }

        return res.status(200).json({
            enderecos: usuario.enderecos || []
        });

    } catch (error) {
        console.error(
            "ERRO AO LISTAR ENDEREÇOS:",
            error
        );

        return res.status(500).json({
            erro: "Erro interno"
        });
    }
};


// ==========================================
// ADICIONAR ENDEREÇO
// ==========================================

exports.adicionarEndereco = async (req, res) => {
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

        // ==================================
        // VALIDAÇÃO
        // ==================================

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

        const usuario =
            await User.buscarPorId(req.usuario.id);

        if (!usuario) {
            return res.status(404).json({
                erro: "Usuário não encontrado"
            });
        }

        // ==================================
        // GARANTE ARRAY
        // ==================================

        if (!usuario.enderecos) {
            usuario.enderecos = [];
        }

        // ==================================
        // VERIFICA SE É O PRIMEIRO
        // ==================================

        const principal =
            usuario.enderecos.length === 0;

        // ==================================
        // CRIA ENDEREÇO
        // ==================================

        const endereco = {
            id: gerarId(),
            apelido:
                apelido ||
                "Meu endereço",

            cep:
                cep.trim(),

            logradouro:
                logradouro.trim(),

            numero:
                numero.trim(),

            complemento:
                complemento
                    ? complemento.trim()
                    : "",

            bairro:
                bairro.trim(),

            cidade:
                cidade.trim(),

            estado:
                estado.trim()
                    .toUpperCase(),

            referencia:
                referencia
                    ? referencia.trim()
                    : "",

            principal
        };

        usuario.enderecos.push(endereco);

        await User.atualizarEnderecos(
            usuario.id,
            usuario.enderecos
        );

        return res.status(201).json({
            mensagem:
                "Endereço adicionado com sucesso",

            endereco
        });

    } catch (error) {
        console.error(
            "ERRO AO ADICIONAR ENDEREÇO:",
            error
        );

        return res.status(500).json({
            erro: "Erro interno"
        });
    }
};


// ==========================================
// EDITAR ENDEREÇO
// ==========================================

exports.editarEndereco = async (req, res) => {
    try {
        const enderecoId =
            Number(req.params.id);

        const usuario =
            await User.buscarPorId(req.usuario.id);

        if (!usuario) {
            return res.status(404).json({
                erro: "Usuário não encontrado"
            });
        }

        const enderecos =
            usuario.enderecos || [];

        const index =
            enderecos.findIndex(
                endereco =>
                    endereco.id === enderecoId
            );

        if (index === -1) {
            return res.status(404).json({
                erro: "Endereço não encontrado"
            });
        }

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

        enderecos[index] = {
            ...enderecos[index],

            apelido:
                apelido ||
                enderecos[index].apelido,

            cep:
                cep ||
                enderecos[index].cep,

            logradouro:
                logradouro ||
                enderecos[index].logradouro,

            numero:
                numero ||
                enderecos[index].numero,

            complemento:
                complemento ?? 
                enderecos[index].complemento,

            bairro:
                bairro ||
                enderecos[index].bairro,

            cidade:
                cidade ||
                enderecos[index].cidade,

            estado:
                estado ||
                enderecos[index].estado,

            referencia:
                referencia ??
                enderecos[index].referencia
        };

        await User.atualizarEnderecos(
            usuario.id,
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
            erro: "Erro interno"
        });
    }
};


// ==========================================
// EXCLUIR ENDEREÇO
// ==========================================

exports.excluirEndereco = async (req, res) => {
    try {
        const enderecoId =
            Number(req.params.id);

        const usuario =
            await User.buscarPorId(req.usuario.id);

        if (!usuario) {
            return res.status(404).json({
                erro: "Usuário não encontrado"
            });
        }

        let enderecos =
            usuario.enderecos || [];

        const endereco =
            enderecos.find(
                item =>
                    item.id === enderecoId
            );

        if (!endereco) {
            return res.status(404).json({
                erro: "Endereço não encontrado"
            });
        }

        enderecos =
            enderecos.filter(
                item =>
                    item.id !== enderecoId
            );

        // ==================================
        // SE EXCLUIU O PRINCIPAL
        // DEFINE OUTRO COMO PRINCIPAL
        // ==================================

        if (
            endereco.principal &&
            enderecos.length > 0
        ) {
            enderecos[0].principal = true;
        }

        await User.atualizarEnderecos(
            usuario.id,
            enderecos
        );

        return res.status(200).json({
            mensagem:
                "Endereço excluído com sucesso"
        });

    } catch (error) {
        console.error(
            "ERRO AO EXCLUIR ENDEREÇO:",
            error
        );

        return res.status(500).json({
            erro: "Erro interno"
        });
    }
};


// ==========================================
// DEFINIR ENDEREÇO PRINCIPAL
// ==========================================

exports.definirPrincipal = async (req, res) => {
    try {
        const enderecoId =
            Number(req.params.id);

        const usuario =
            await User.buscarPorId(req.usuario.id);

        if (!usuario) {
            return res.status(404).json({
                erro: "Usuário não encontrado"
            });
        }

        const enderecos =
            usuario.enderecos || [];

        const enderecoExiste =
            enderecos.some(
                endereco =>
                    endereco.id === enderecoId
            );

        if (!enderecoExiste) {
            return res.status(404).json({
                erro: "Endereço não encontrado"
            });
        }

        const novosEnderecos =
            enderecos.map(
                endereco => ({
                    ...endereco,

                    principal:
                        endereco.id ===
                        enderecoId
                })
            );

        await User.atualizarEnderecos(
            usuario.id,
            novosEnderecos
        );

        return res.status(200).json({
            mensagem:
                "Endereço principal atualizado",

            enderecos:
                novosEnderecos
        });

    } catch (error) {
        console.error(
            "ERRO AO DEFINIR ENDEREÇO PRINCIPAL:",
            error
        );

        return res.status(500).json({
            erro: "Erro interno"
        });
    }
};

