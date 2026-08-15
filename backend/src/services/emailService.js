require("dotenv").config();

const nodemailer = require("nodemailer");

// ============================================================
// SERVIÇO DE EMAIL - FOODJET
// ============================================================

console.log("");
console.log("==========================================");
console.log("📧 FOODJET - SERVIÇO DE EMAIL");
console.log("==========================================");

const EMAIL_USER =
    String(process.env.EMAIL_USER || "")
        .trim()
        .toLowerCase();

const EMAIL_PASS =
    String(process.env.EMAIL_PASS || "")
        .trim();

console.log(
    "📧 EMAIL_USER:",
    EMAIL_USER || "❌ NÃO CONFIGURADO"
);

console.log(
    "🔑 EMAIL_PASS:",
    EMAIL_PASS
        ? "✅ CONFIGURADO"
        : "❌ NÃO CONFIGURADO"
);

// ============================================================
// VALIDAR CONFIGURAÇÃO
// ============================================================

if (!EMAIL_USER || !EMAIL_PASS) {

    console.error("");
    console.error(
        "❌ CONFIGURAÇÃO DE EMAIL INCOMPLETA"
    );

    console.error(
        "Configure EMAIL_USER e EMAIL_PASS no arquivo .env"
    );

    console.error("");

}

// ============================================================
// TRANSPORTER GMAIL
// ============================================================

const transporter = nodemailer.createTransport({

    service: "gmail",

    auth: {

        user: EMAIL_USER,

        pass: EMAIL_PASS

    }

});

// ============================================================
// TESTAR CONEXÃO
// ============================================================

async function testarEmail() {

    try {

        if (!EMAIL_USER || !EMAIL_PASS) {

            console.error(
                "❌ Gmail não configurado."
            );

            return false;

        }

        await transporter.verify();

        console.log("");
        console.log(
            "=========================================="
        );

        console.log(
            "✅ CONEXÃO COM GMAIL FUNCIONANDO!"
        );

        console.log(
            "📧 Conta:",
            EMAIL_USER
        );

        console.log(
            "=========================================="
        );

        console.log("");

        return true;

    } catch (error) {

        console.error("");
        console.error(
            "=========================================="
        );

        console.error(
            "❌ ERRO NA CONEXÃO COM GMAIL"
        );

        console.error(
            "Mensagem:",
            error.message
        );

        console.error(
            "=========================================="
        );

        console.error("");

        return false;
    }
}

// ============================================================
// TESTAR AO CARREGAR
// ============================================================

testarEmail();

// ============================================================
// ENVIAR CÓDIGO DE RECUPERAÇÃO
// ============================================================

async function enviarCodigoRecuperacao(
    email,
    codigo
) {

    try {

        console.log("");
        console.log(
            "=========================================="
        );

        console.log(
            "📨 INICIANDO ENVIO DE RECUPERAÇÃO"
        );

        console.log(
            "📬 Destinatário:",
            email
        );

        console.log(
            "🔐 Código:",
            codigo
        );

        console.log(
            "📧 Remetente:",
            EMAIL_USER
        );

        console.log(
            "=========================================="
        );

        // ====================================================
        // VALIDAR CONFIGURAÇÃO
        // ====================================================

        if (!EMAIL_USER || !EMAIL_PASS) {

            throw new Error(
                "EMAIL_USER ou EMAIL_PASS não configurado no .env"
            );

        }

        // ====================================================
        // VALIDAR DESTINATÁRIO
        // ====================================================

        const destinatario =
            String(email || "")
                .trim()
                .toLowerCase();

        if (!destinatario) {

            throw new Error(
                "Email do destinatário não informado"
            );

        }

        // ====================================================
        // VALIDAR CÓDIGO
        // ====================================================

        const codigoNormalizado =
            String(codigo || "")
                .trim();

        if (!codigoNormalizado) {

            throw new Error(
                "Código de recuperação não informado"
            );

        }

        // ====================================================
        // ENVIAR EMAIL
        // ====================================================

        const resultado =
            await transporter.sendMail({

                from:
                    `"FoodJet" <${EMAIL_USER}>`,

                to:
                    destinatario,

                subject:
                    "Código de recuperação da sua conta FoodJet",

                text:
                    `Seu código de recuperação da conta FoodJet é: ${codigoNormalizado}. Este código é válido por 10 minutos.`,

                html: `

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<meta name="viewport"
      content="width=device-width, initial-scale=1.0">

<title>Recuperação FoodJet</title>

</head>

<body style="
    margin:0;
    padding:0;
    background:#f5f5f5;
    font-family:Arial,Helvetica,sans-serif;
">

<div style="
    max-width:600px;
    margin:30px auto;
    background:#ffffff;
    border-radius:20px;
    padding:30px;
    box-sizing:border-box;
">

    <h1 style="
        color:#F97316;
        margin:0 0 10px 0;
    ">
        🚀 FoodJet
    </h1>

    <h2 style="
        color:#222222;
    ">
        Recuperação de senha
    </h2>

    <p style="
        color:#444444;
        font-size:16px;
        line-height:1.6;
    ">
        Recebemos uma solicitação para
        recuperar a senha da sua conta FoodJet.
    </p>

    <p style="
        color:#444444;
        font-size:16px;
    ">
        Seu código de recuperação é:
    </p>

    <div style="
        background:#F97316;
        color:#ffffff;
        font-size:36px;
        font-weight:bold;
        text-align:center;
        padding:20px;
        border-radius:15px;
        letter-spacing:8px;
        margin:25px 0;
    ">

        ${codigoNormalizado}

    </div>

    <p style="
        color:#444444;
        font-size:15px;
        line-height:1.6;
    ">
        Digite esse código no aplicativo
        FoodJet para continuar.
    </p>

    <p style="
        color:#777777;
        font-size:14px;
        line-height:1.6;
    ">
        Este código é válido por 10 minutos.
    </p>

    <p style="
        color:#777777;
        font-size:14px;
        line-height:1.6;
    ">
        Se você não solicitou a recuperação
        da senha, ignore este email.
    </p>

    <hr style="
        border:none;
        border-top:1px solid #eeeeee;
        margin:30px 0;
    ">

    <p style="
        color:#999999;
        font-size:12px;
    ">
        FoodJet - Sistema de Delivery
    </p>

</div>

</body>

</html>

                `
            });

        // ====================================================
        // SUCESSO
        // ====================================================

        console.log("");
        console.log(
            "=========================================="
        );

        console.log(
            "✅ EMAIL ENVIADO COM SUCESSO!"
        );

        console.log(
            "📧 Destinatário:",
            destinatario
        );

        console.log(
            "🆔 Message ID:",
            resultado.messageId
        );

        console.log(
            "=========================================="
        );

        console.log("");

        return resultado;

    } catch (error) {

        console.error("");
        console.error(
            "=========================================="
        );

        console.error(
            "❌ ERRO AO ENVIAR EMAIL"
        );

        console.error(
            "📧 Destinatário:",
            email
        );

        console.error(
            "🔐 Código:",
            codigo
        );

        console.error(
            "❌ Mensagem:",
            error.message
        );

        console.error(
            "❌ Código do erro:",
            error.code || "N/A"
        );

        console.error(
            "=========================================="
        );

        console.error("");

        throw error;
    }
}

// ============================================================
// EXPORTAR
// ============================================================

module.exports = {

    enviarCodigoRecuperacao,

    testarEmail

};