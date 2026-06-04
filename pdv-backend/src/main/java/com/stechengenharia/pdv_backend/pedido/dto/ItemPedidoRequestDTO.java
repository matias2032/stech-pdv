package com.stechengenharia.pdv_backend.pedido.dto;
 
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
 
public class ItemPedidoRequestDTO {
 
    @NotNull(message = "O produto é obrigatório")
    public Integer idProduto;
 
    @NotNull @Min(value = 1, message = "A quantidade mínima é 1")
    public Integer quantidade;
}