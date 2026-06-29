package com.stechengenharia.pdv_backend.pedido.dto;

import java.math.BigDecimal;

public class ItemPedidoResponseDTO {

    public Integer    idItemPedido;
    public Integer    idProduto;
    public String     nomeProduto;
    public Integer    quantidade;
    public BigDecimal precoUnitario;
    public BigDecimal subtotal;
    public Boolean    confirmadoCredito;
}