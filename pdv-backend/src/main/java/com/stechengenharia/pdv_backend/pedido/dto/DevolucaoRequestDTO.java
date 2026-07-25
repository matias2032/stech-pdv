package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/**
 * Payload para POST /pedidos/{idPedido}/devolucao.
 * Cobre os 3 cenários: erro de preenchimento (itensDevolvidos vazio/nulo),
 * troca de produtos e devolução (itensDevolvidos preenchido).
 */
public class DevolucaoRequestDTO {

    @NotNull(message = "O id do documento (factura) de origem é obrigatório")
    public Integer idDocumentoOrigem;

    @NotBlank(message = "O motivo é obrigatório")
    public String motivo; // ERRO_PREENCHIMENTO | TROCA_PRODUTO | DEVOLUCAO | OUTRO

    @NotNull(message = "O id do utilizador é obrigatório")
    public Long idUsuario;

    public String codigoAt;

    /** Vazio/nulo = anulação total (ERRO_PREENCHIMENTO), sem mexer em stock. */
    @Valid
    public List<ItemDevolvidoDTO> itensDevolvidos;

    public String observacoes;
}