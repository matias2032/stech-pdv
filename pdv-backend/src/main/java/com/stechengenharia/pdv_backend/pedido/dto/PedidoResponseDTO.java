package com.stechengenharia.pdv_backend.pedido.dto;
 
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.List;
 import java.time.LocalDate;
import java.time.OffsetDateTime;
public class PedidoResponseDTO {
 
    public Integer       idPedido;
    public String        referencia;
    public Integer       idUsuario;
    public Integer       idTipoPagamento;
    public String        statusPedido;
    public BigDecimal    total;
    public BigDecimal    valorPago;
    public BigDecimal    troco;
    public String        pontoReferencia;
    public String        observacoes;
    public LocalDateTime dataPedido;
    public LocalDateTime dataFinalizacao;
 public Long          idCliente;  
    public List<ItemPedidoResponseDTO>  itensProduto;
    public List<ItemServicoResponseDTO> itensServico;
    // Em PedidoResponseDTO.java
public String nomeClienteSingular;
public String apelidoClienteSingular;

public String         tipoVenda;
public String         modalidadeCredito;
public String         statusPagamento;
public Integer        idDocumentoFacturaCredito;
public OffsetDateTime dataAberturaCredito;
public LocalDate       dataVencimentoCredito;
public OffsetDateTime dataLiquidacaoCredito;
public String         observacoesCredito;
public BigDecimal     saldoDevedorCredito;
}
 