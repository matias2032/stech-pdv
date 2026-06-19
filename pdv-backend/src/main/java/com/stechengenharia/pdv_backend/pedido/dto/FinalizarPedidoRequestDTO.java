package com.stechengenharia.pdv_backend.pedido.dto;


import java.math.BigDecimal;



public class FinalizarPedidoRequestDTO {
    public Integer    idTipoPagamento;
    public BigDecimal valorPago;
    public String     observacoes;

    // Cliente — apenas um dos grupos deve vir preenchido
    public Long   idCliente;               // empresa cadastrada
public String nomeClienteSingular;
public String apelidoClienteSingular;
}