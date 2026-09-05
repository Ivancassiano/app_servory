/// Helpers de parsing compartilhados entre os mapeadores REST↔`Local*`
/// (`lib/features/*/data/*_mapper.dart`) e o `SyncEngine`. O objeto `data`
/// de `sync/pull` é byte-a-byte igual ao corpo de `GET /v1/<entidade>/{id}`
/// (o adapter de sync do backend chama o mesmo método de serviço do handler
/// REST), então um único mapeador serve para os dois caminhos.
library;

/// `null` quando ausente; caso contrário `DateTime.tryParse` (datas do
/// servidor são sempre ISO 8601 UTC).
DateTime? parseApiDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value as String);

/// Lê uma string opcional caindo para `''` quando ausente/nula — o padrão
/// para campos de texto não-mascaráveis (o servidor sempre manda a chave
/// quando há permissão de leitura).
String stringOr(Object? value, [String fallback = '']) =>
    (value as String?) ?? fallback;

/// Campos mascaráveis (sensíveis): a **ausência** da chave no JSON significa
/// "sem permissão de leitura", distinto de string vazia — mantém `null`.
String? maskable(Object? value) => value as String?;
