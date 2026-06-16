// RegistarPagamentoCreditoRequestDTO.java
package com.stechengenharia.pdv_backend.pedido.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record RegistarPagamentoCreditoRequestDTO(
    @NotNull Long idUsuario,
    @NotNull Integer idTipoPagamento,
    @NotNull @DecimalMin("0.01") BigDecimal valorPago,
    Long idParcela,       // null = pagamento livre (sem parcela específica)
    String observacoes,
    String codigoAt       // para emissão do recibo
) {}