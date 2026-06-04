package com.stechengenharia.pdv_backend.produto.dto;

import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
public class ProdutoRequestDTO {
    private String nomeProduto;
    private String descricao;
    private BigDecimal preco;
    private Integer quantidadeEstoque;
    private BigDecimal precoPromocional;
    private List<Integer> categorias;
    private List<Integer> marcas;
     // IDs das categorias associadas
}