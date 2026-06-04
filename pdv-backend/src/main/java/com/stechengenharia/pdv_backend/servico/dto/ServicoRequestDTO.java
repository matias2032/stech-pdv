package com.stechengenharia.pdv_backend.servico.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

/**
 * Payload para criar ou actualizar um serviço.
 * Mesmo DTO serve para POST (criar) e PUT (actualizar) —
 * o campo ativo é ignorado nestas operações; use o endpoint de toggle.
 */
public class ServicoRequestDTO {

    @NotBlank(message = "O nome do serviço é obrigatório")
    @Size(max = 150, message = "O nome do serviço não pode exceder 150 caracteres")
    public String nomeServico;

    public String descricao;

    @NotNull(message = "O preço unitário é obrigatório")
    @DecimalMin(value = "0.00", message = "O preço unitário não pode ser negativo")
    @Digits(integer = 10, fraction = 2, message = "Formato inválido para preço unitário")
    public BigDecimal precoUnitario;

    @NotBlank(message = "A unidade é obrigatória")
    @Size(max = 50, message = "A unidade não pode exceder 50 caracteres")
    public String unidade; // "página", "folha", "unidade"
}