package com.stechengenharia.pdv_backend.pedido.dto;
import jakarta.validation.constraints.*;    
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;


@Data
@NoArgsConstructor
@AllArgsConstructor
public class CancelamentoPedidoRequestDTO {

    @NotNull(message = "O utilizador que cancela é obrigatório")
    public Integer idUsuarioCancelou;

    public String motivo;
}
