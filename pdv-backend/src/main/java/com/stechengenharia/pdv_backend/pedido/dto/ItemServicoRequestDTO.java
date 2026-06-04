package com.stechengenharia.pdv_backend.pedido.dto;
 
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
 
public class ItemServicoRequestDTO {
 
    @NotNull(message = "O serviço é obrigatório")
    public Integer idServico;
 
    @NotNull @Min(value = 1, message = "A quantidade mínima é 1")
    public Integer quantidade;
 
    // @NotNull(message = "O preço unitário é obrigatório")
    // public BigDecimal precoUnitario;
 
    public String observacoes;
}
 