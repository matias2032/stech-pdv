package com.stechengenharia.pdv_backend.pedido.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT)
public class PedidoJaFaturadoException extends RuntimeException {
    public PedidoJaFaturadoException(Integer idPedido) {
        super("O pedido " + idPedido + " já tem factura emitida. Utilize o fluxo de "
                + "Nota de Crédito (POST /pedidos/{id}/devolucao) em vez de cancelar directamente.");
    }
}