package com.stechengenharia.pdv_backend.pedido.dto;
 
import java.math.BigDecimal;
 
public class ItemServicoResponseDTO {
 
    public Integer    idItemServico;
    public Integer    idServico;
    public String     nomeServico;
    public Integer    quantidade;
    public BigDecimal precoUnitario;
    public BigDecimal subtotal;
    public String     observacoes;
}