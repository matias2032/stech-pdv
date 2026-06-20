package com.stechengenharia.pdv_backend.pedido.dto;
 

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;
 
public class PedidoRequestDTO {
 
    @NotNull(message = "O utilizador é obrigatório")
    public Integer idUsuario;
 
    @NotNull(message = "O tipo de pagamento é obrigatório")
    public Integer idTipoPagamento;
 
    public String pontoReferencia;
    public String observacoes;
 
    @Valid
    public List<ItemPedidoRequestDTO> itensProduto;
 
    @Valid
public List<ItemServicoRequestDTO> itensServico;

public Long idCliente;

public String nomeClienteSingular;

public String apelidoClienteSingular;
}