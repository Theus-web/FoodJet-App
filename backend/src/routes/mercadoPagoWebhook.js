// ============================================================
// EXTRAIR ASSINATURA DO MERCADO PAGO
// ============================================================

function extrairAssinatura(xSignature) {
  const resultado = {
    ts: null,
    v1: [],
  };

  if (!xSignature) {
    return resultado;
  }

  const partes = String(xSignature).split(",");

  for (const parte of partes) {
    const indice = parte.indexOf("=");

    if (indice === -1) {
      continue;
    }

    const chave = parte
      .substring(0, indice)
      .trim()
      .toLowerCase();

    const valor = parte
      .substring(indice + 1)
      .trim();

    if (chave === "ts" && !resultado.ts) {
      resultado.ts = valor;
    }

    if (chave === "v1" && valor) {
      resultado.v1.push(valor.toLowerCase());
    }
  }

  return resultado;
}


// ============================================================
// COMPARAR HASHES COM SEGURANÇA
// ============================================================

function compararHashes(hashCalculado, hashRecebido) {
  if (!hashCalculado || !hashRecebido) {
    return false;
  }

  const a = Buffer.from(
    String(hashCalculado).toLowerCase(),
    "utf8"
  );

  const b = Buffer.from(
    String(hashRecebido).toLowerCase(),
    "utf8"
  );

  if (a.length !== b.length) {
    return false;
  }

  return crypto.timingSafeEqual(a, b);
}


// ============================================================
// VALIDAÇÃO MANUAL HMAC
// ============================================================

function validarAssinaturaManual(req) {
  if (!WEBHOOK_SECRET) {
    console.error(
      "❌ MERCADOPAGO_WEBHOOK_SECRET NÃO CONFIGURADO"
    );

    return false;
  }

  const xSignature =
    req.headers["x-signature"];

  const xRequestId =
    req.headers["x-request-id"];

  // IMPORTANTE:
  // Para Orders, usamos o data.id recebido
  // na query string.
  const dataId =
    req.query?.["data.id"];

  console.log("========================================");
  console.log("🔐 VALIDAÇÃO MANUAL HMAC");
  console.log("========================================");

  console.log(
    "X-SIGNATURE:",
    xSignature
      ? "RECEBIDO"
      : "NÃO RECEBIDO"
  );

  console.log(
    "X-REQUEST-ID:",
    xRequestId
      ? "RECEBIDO"
      : "NÃO RECEBIDO"
  );

  console.log(
    "DATA.ID QUERY:",
    dataId || "NÃO RECEBIDO"
  );

  if (
    !xSignature ||
    !xRequestId ||
    !dataId
  ) {
    console.error(
      "❌ DADOS NECESSÁRIOS PARA ASSINATURA AUSENTES"
    );

    return false;
  }

  const {
    ts,
    v1,
  } = extrairAssinatura(
    xSignature
  );

  console.log(
    "TIMESTAMP:",
    ts || "NÃO ENCONTRADO"
  );

  console.log(
    "V1:",
    v1.length > 0
      ? `${v1.length} RECEBIDO(S)`
      : "NÃO RECEBIDO"
  );

  if (
    !ts ||
    v1.length === 0
  ) {
    console.error(
      "❌ TS OU V1 AUSENTE"
    );

    return false;
  }


  // ==========================================================
  // MANIFEST
  // ==========================================================

  const manifest =
    `id:${String(dataId)};` +
    `request-id:${String(xRequestId)};` +
    `ts:${String(ts)};`;

  console.log(
    "MANIFEST:",
    manifest
  );


  // ==========================================================
  // HMAC SHA256
  // ==========================================================

  const hashCalculado =
    crypto
      .createHmac(
        "sha256",
        WEBHOOK_SECRET
      )
      .update(
        manifest,
        "utf8"
      )
      .digest("hex");

  console.log(
    "HASH CALCULADO:",
    hashCalculado
  );


  // ==========================================================
  // COMPARAR TODOS OS V1
  // ==========================================================

  let assinaturaValida = false;

  for (
    const assinatura of v1
  ) {
    if (
      compararHashes(
        hashCalculado,
        assinatura
      )
    ) {
      assinaturaValida = true;
      break;
    }
  }


  if (!assinaturaValida) {
    console.error(
      "❌ ASSINATURA HMAC INVÁLIDA"
    );

    return false;
  }


  console.log(
    "========================================"
  );

  console.log(
    "✅ ASSINATURA HMAC VALIDADA"
  );

  console.log(
    "✅ WEBHOOK AUTÊNTICO"
  );

  console.log(
    "========================================"
  );

  return true;
}


// ============================================================
// VALIDAÇÃO DO WEBHOOK
// ============================================================

function validarAssinatura(req) {
  if (!WEBHOOK_SECRET) {
    console.error(
      "❌ WEBHOOK SECRET NÃO CONFIGURADO"
    );

    return false;
  }

  // ==========================================================
  // VALIDAÇÃO HMAC DIRETA
  // ==========================================================

  const manualValida =
    validarAssinaturaManual(
      req
    );

  if (manualValida) {
    return true;
  }

  console.error(
    "❌ VALIDAÇÃO HMAC DO WEBHOOK FALHOU"
  );

  return false;
}