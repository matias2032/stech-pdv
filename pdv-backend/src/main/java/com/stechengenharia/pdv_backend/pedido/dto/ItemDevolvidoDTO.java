package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public class ItemDevolvidoDTO {

    // Exactamente um dos dois deve vir preenchido
    public Integer idItemPedido;    // item de produto
    public Integer idItemServico;   // item de serviço

    @NotNull @Min(value = 1, message = "A quantidade devolvida mínima é 1")
    public Integer quantidade;
}