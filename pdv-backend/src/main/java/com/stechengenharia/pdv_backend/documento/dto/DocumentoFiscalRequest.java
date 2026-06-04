package com.stechengenharia.pdv_backend.documento.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;  // ← adicionar
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;                            // ← adicionar

// ─── REQUEST ────────────────────────────────────────────────────────────────

public class DocumentoFiscalRequest {

    /**
     * Emitir um documento fiscal.
     * Reflecte os parâmetros da função PL/pgSQL emitir_documento_fiscal().
     */
    public record EmitirDocumentoRequest(

            @NotNull(message = "O id do pedido é obrigatório")
            Integer idPedido,

            @NotBlank(message = "O código do tipo de documento é obrigatório")
            @Size(max = 10)
            String codigoTipo,        // ex: "FAT", "COT", "REC", "NCO"

            @NotNull(message = "O id do utilizador é obrigatório")
            Long idUsuario,

            @NotBlank(message = "O código AT é obrigatório")
            @Size(max = 50)
            String codigoAt
    ) {}

    /**
     * Anular um documento já emitido.
     */
    public record AnularDocumentoRequest(

            @NotBlank(message = "O motivo da anulação é obrigatório")
            String motivoAnulacao
    ) {}


    public record EmitirDocumentoMultiplosRequest(

        @NotEmpty(message = "A lista de pedidos não pode estar vazia")
        List<@NotNull Integer> idsPedido,

        @NotBlank(message = "O código do tipo de documento é obrigatório")
        @Size(max = 10)
        String codigoTipo,

        @NotNull(message = "O id do utilizador é obrigatório")
        Long idUsuario,

        @NotBlank(message = "O código AT é obrigatório")
        @Size(max = 50)
        String codigoAt
) {}
}